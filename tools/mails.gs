/**
 * Tableau de bord : aperçu des mails (expéditeur, objet, heure et début du message).
 * À installer une seule fois dans ton compte Google :
 *  1. script.google.com > Nouveau projet > colle tout ce fichier dans Code.gs
 *  2. remplace TOKEN ci-dessous par un code long et secret de ton choix (lettres et chiffres)
 *  3. Déployer > Nouveau déploiement > type « Application Web »
 *       Exécuter en tant que : Moi    |    Qui a accès : Tout le monde
 *  4. autorise l'accès à Gmail quand Google le demande
 *  5. copie l'URL de l'application web, ajoute  ?k=TON_CODE  à la fin
 *  6. sur l'iPad : Réglages > « Lien du script Mails » > colle l'URL complète
 * Sans le bon code, le script ne répond rien. Ne partage jamais l'URL complète.
 * Si tu modifies ce script plus tard : Déployer > Gérer les déploiements > crayon > Version « Nouvelle version » > Déployer.
 */
var TOKEN = "REMPLACE-PAR-UN-CODE-LONG-ET-SECRET";
var MAX = 10;                                   // mails affichés
var BODY_MAX = 1200;                            // caractères du message renvoyés
var TZ = "Europe/Paris";
var QUERY = "in:inbox is:unread -category:promotions -category:social -category:forums newer_than:3d";

function doGet(e) {
  if (TOKEN.indexOf("REMPLACE") === 0) { return out({ error: "code secret non défini dans le script" }); }
  if (!e || !e.parameter || e.parameter.k !== TOKEN) { return out({ error: "non autorisé" }); }
  var threads = GmailApp.search(QUERY, 0, 50), mails = [], today = Utilities.formatDate(new Date(), TZ, "yyyyMMdd");
  for (var i = 0; i < threads.length && mails.length < MAX; i++) {
    var msgs = threads[i].getMessages(), m = msgs[msgs.length - 1], d = m.getDate();
    var from = String(m.getFrom() || "").replace(/<[^>]*>/g, "").replace(/"/g, "").replace(/^\s+|\s+$/g, "") || String(m.getFrom());
    mails.push({
      from: from.slice(0, 40),
      subject: String(m.getSubject() || "(sans objet)").slice(0, 90),
      body: clean(m.getPlainBody()),
      time: Utilities.formatDate(d, TZ, Utilities.formatDate(d, TZ, "yyyyMMdd") === today ? "HH:mm" : "dd/MM HH:mm")
    });
  }
  return out({ updated: Utilities.formatDate(new Date(), TZ, "HH:mm"), unread: threads.length, mails: mails });
}

function clean(txt) {
  return String(txt || "").replace(/https?:\/\/\S+/g, "[lien]").replace(/\r/g, "").replace(/[ \t]+/g, " ").replace(/\n[ ]+/g, "\n").replace(/\n{3,}/g, "\n\n").replace(/^\s+|\s+$/g, "").slice(0, BODY_MAX);
}

function out(o) { return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON); }
