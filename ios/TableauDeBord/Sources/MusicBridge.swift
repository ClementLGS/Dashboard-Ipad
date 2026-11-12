import Foundation
import MediaPlayer
import AVFoundation
import UIKit

/// Apple Music via le lecteur système de l'iPad (appli Musique) : aucun compte développeur payant nécessaire.
/// Actions : state (arg = clé de pochette déjà connue), pp, next, prev, playlists, play (arg = id de playlist).
/// Réponse : JSON (texte) ou erreur (texte). Tout s'exécute sur le fil principal.
final class MusicBridge {
    private var artCache: [UInt64: String] = [:]
    private var notifying = false

    private var player: MPMusicPlayerController { MPMusicPlayerController.systemMusicPlayer }

    private static func statusName(_ s: MPMediaLibraryAuthorizationStatus) -> String {
        switch s {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "notDetermined"
        @unknown default: return "unknown"
        }
    }

    private static func json(_ o: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(o),
              let d = try? JSONSerialization.data(withJSONObject: o),
              let s = String(data: d, encoding: .utf8) else { return "{}" }
        return s
    }

    /// done(corps, erreur) : erreur vide = succès. Appelé sur le fil principal.
    func handle(action: String, arg: String, done: @escaping (String, String) -> Void) {
        DispatchQueue.main.async {
            let st = MPMediaLibrary.authorizationStatus()
            if st == .notDetermined {
                MPMediaLibrary.requestAuthorization { _ in
                    DispatchQueue.main.async { self.run(action: action, arg: arg, done: done) }
                }
                return
            }
            self.run(action: action, arg: arg, done: done)
        }
    }

    private func run(action: String, arg: String, done: @escaping (String, String) -> Void) {
        let auth = MPMediaLibrary.authorizationStatus()
        if auth != .authorized {
            done(MusicBridge.json(["auth": MusicBridge.statusName(auth)]), "")
            return
        }
        // Sans cet appel, l'état du lecteur système peut rester figé (ancien état renvoyé après une commande).
        if !notifying { player.beginGeneratingPlaybackNotifications(); notifying = true }
        switch action {
        case "state":
            done(MusicBridge.json(stateDict(knownArt: arg)), "")
        case "pp":
            let was = player.playbackState == .playing
            if was { player.pause() } else { player.play() }
            settle(after: 0.7, done: done) { [weak self] o in
                guard let self = self else { return }
                o["changed"] = (self.player.playbackState == .playing) != was
            }
        case "next":
            let before = player.nowPlayingItem?.persistentID
            player.skipToNextItem()
            settle(after: 0.9, done: done) { [weak self] o in
                o["changed"] = self?.player.nowPlayingItem?.persistentID != before
            }
        case "prev":
            let before = player.nowPlayingItem?.persistentID
            if player.currentPlaybackTime > 3 { player.skipToBeginning() } else { player.skipToPreviousItem() }
            settle(after: 0.9, done: done) { [weak self] o in
                // Retour au début du même morceau : compte comme un effet.
                o["changed"] = (self?.player.nowPlayingItem?.persistentID != before) || ((self?.player.currentPlaybackTime ?? 99) < 2)
            }
        case "playlists":
            done(playlistsJson(), "")
        case "play":
            playPlaylist(id: arg, done: done)
        default:
            done("", "action inconnue : \(action)")
        }
    }

    /// Laisse au lecteur le temps de changer d'état, puis renvoie l'état réel et si la commande a eu un effet.
    private func settle(after delay: Double, done: @escaping (String, String) -> Void, extra: @escaping (inout [String: Any]) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            var o = self.stateDict(knownArt: "")
            extra(&o)
            done(MusicBridge.json(o), "")
        }
    }

    private func stateDict(knownArt: String) -> [String: Any] {
        var o: [String: Any] = ["auth": "authorized", "playing": player.playbackState == .playing]
        if let item = player.nowPlayingItem {
            o["title"] = item.title ?? ""
            o["artist"] = item.artist ?? ""
            o["album"] = item.albumTitle ?? ""
            let key = String(item.persistentID)
            o["artKey"] = key
            if key != knownArt { o["art"] = artwork(item) }
        }
        let outs = AVAudioSession.sharedInstance().currentRoute.outputs
        if let out = outs.first {
            o["route"] = out.portName
            o["routeType"] = out.portType.rawValue
        }
        return o
    }

    /// Pochette (JPEG en base64), gardée en mémoire par morceau.
    private func artwork(_ item: MPMediaItem) -> String {
        let key = item.persistentID
        if let c = artCache[key] { return c }
        var s = ""
        if let img = item.artwork?.image(at: CGSize(width: 300, height: 300)),
           let data = img.jpegData(compressionQuality: 0.7) {
            s = "data:image/jpeg;base64," + data.base64EncodedString()
        }
        if artCache.count > 20 { artCache.removeAll() }
        artCache[key] = s
        return s
    }

    private func playlistsJson() -> String {
        var list: [[String: Any]] = []
        let cols = MPMediaQuery.playlists().collections ?? []
        for c in cols {
            guard let p = c as? MPMediaPlaylist else { continue }
            let name = p.name ?? ""
            if name.isEmpty { continue }
            list.append(["id": String(p.persistentID), "name": name, "n": p.count])
        }
        list.sort { (($0["name"] as? String) ?? "").localizedCaseInsensitiveCompare(($1["name"] as? String) ?? "") == .orderedAscending }
        if list.count > 100 { list = Array(list.prefix(100)) }
        return MusicBridge.json(["auth": "authorized", "playlists": list])
    }

    private func playPlaylist(id: String, done: @escaping (String, String) -> Void) {
        guard let pid = UInt64(id) else { done("", "identifiant de playlist invalide"); return }
        let q = MPMediaQuery.playlists()
        q.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: pid), forProperty: MPMediaPlaylistPropertyPersistentID))
        guard let col = q.collections?.first else { done("", "playlist introuvable"); return }
        player.setQueue(with: col)
        player.prepareToPlay { [weak self] err in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let e = err {
                    done("", "lecture impossible : \(e.localizedDescription)")
                    return
                }
                self.player.play()
                self.settle(after: 0.9, done: done) { [weak self] o in
                    o["changed"] = self?.player.playbackState == .playing
                }
            }
        }
    }
}
