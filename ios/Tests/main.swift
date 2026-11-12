import Foundation

// Test de l'import automatique des réglages (SettingsImport.swift, le même code que l'appli).
var failed = false
func check(_ name: String, _ ok: Bool) { print((ok ? "OK      " : "ECHEC   ") + name); if !ok { failed = true } }
check("sha256 de « abc »", SettingsImport.sha256Hex(Data("abc".utf8)) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")

// --- import automatique des réglages (SettingsImport.swift) ---
let base: [String: Any] = ["airzone": "ancien:3000", "zone": "2", "lat": "44.8"]
let r1 = SettingsImport.apply(ical: "# lien\r\nhttps://exemple.test/a.ics?x=1\r\n", tuya: "id=AAA\nSecret = S=3\n# x\nregion=eu\nbidule=1\n",
                              reglages: "airzone=192.168.1.9:3000\r\nzone=\nlat = 44.9\nlum=\nzonne=3\n", to: base)
check("reglages.txt remplace une valeur", (r1.cfg["airzone"] as? String) == "192.168.1.9:3000" && (r1.cfg["lat"] as? String) == "44.9")
check("valeur vide ne remplace rien", (r1.cfg["zone"] as? String) == "2" && r1.cfg["lum"] == nil)
check("ical.txt : 1re ligne utile, CRLF géré", (r1.cfg["ical"] as? String) == "https://exemple.test/a.ics?x=1")
check("tuya.txt : correspondance des noms, « = » dans la valeur", (r1.cfg["tyid"] as? String) == "AAA" && (r1.cfg["tysecret"] as? String) == "S=3" && (r1.cfg["tyregion"] as? String) == "eu")
check("clés inconnues signalées", r1.message.contains("ignoré") && r1.message.contains("bidule") && r1.message.contains("zonne"))
check("nombre de réglages modifiés", r1.changed == 6)
let r2 = SettingsImport.apply(ical: nil, tuya: nil, reglages: "airzone=192.168.1.9:3000\n", to: r1.cfg)
check("deuxième import identique : rien à changer", r2.changed == 0 && r2.message.hasPrefix("Réglages déjà à jour"))
let r3 = SettingsImport.apply(ical: nil, tuya: nil, reglages: "n'importe quoi\n", to: base)
check("fichier sans ligne valide", r3.changed == 0 && r3.message.hasPrefix("Fichier de réglages lu"))
check("empreinte change avec le contenu", SettingsImport.digest(ical: nil, tuya: nil, reglages: "a=1") != SettingsImport.digest(ical: nil, tuya: nil, reglages: "a=2"))

// --- mises à jour de l'interface sans signature (Ota.swift) ---
func page(_ v: Int, _ a: Int, local: Bool = true, size: Int = 30000) -> String {
    return "<!--TDBV:\(v) TDBA:\(a)-->" + (local ? "window.LOCAL" : "") + String(repeating: "x", count: size)
}
let ok1 = page(3152, 211)
let vjOk = "{\"ui\":3152,\"uisha\":\"" + SettingsImport.sha256Hex(Data(ok1.utf8)) + "\"}"
check("interface valide acceptée (avec empreinte)", Ota.problem(html: ok1, versionJson: vjOk) == nil)
check("interface valide acceptée (sans version.json)", Ota.problem(html: ok1, versionJson: "") == nil)
check("empreinte fausse refusée (fichier abîmé)", Ota.problem(html: ok1 + "x", versionJson: vjOk)?.contains("version.json") == true)
check("pas de window.LOCAL refusée", Ota.problem(html: page(3152, 211, local: false), versionJson: "") != nil)
check("fichier trop petit refusé", Ota.problem(html: page(3152, 211, size: 100), versionJson: "") != nil)
check("sans numéro de version refusé", Ota.problem(html: "window.LOCAL" + String(repeating: "x", count: 30000), versionJson: "") != nil)
check("interface qui exige un pont plus récent refusée", Ota.problem(html: page(3152, Ota.bridgeLevel + 1), versionJson: "")?.contains("pont plus récent") == true)
check("marqueur TDBV lu", Ota.mark(ok1, "TDBV") == 3152 && Ota.mark(ok1, "TDBA") == 211 && Ota.mark("rien", "TDBV") == -1)

// --- version.json du dépôt = index.html du dépôt (sinon l'iPad refuserait la mise à jour : empreinte différente) ---
let argv = CommandLine.arguments
if argv.count >= 3, let vjText = try? String(contentsOfFile: argv[1], encoding: .utf8), let htmlData = try? Data(contentsOf: URL(fileURLWithPath: argv[2])),
   let o = try? JSONSerialization.jsonObject(with: Data(vjText.utf8)) as? [String: Any], let want = o["uisha"] as? String {
    if SettingsImport.sha256Hex(htmlData) == want.lowercased() { print("OK      version.json correspond à index.html") }
    else { print("::warning::version.json ne correspond pas à index.html : lance python3 tools/version.py avant de pousser, sinon l'iPad refusera la mise à jour") }
}
exit(failed ? 1 : 0)
