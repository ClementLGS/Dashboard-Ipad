# Dashboard-Ipad

Tableau de bord (clim Airzone, lumières, météo, agenda, musique) pour l'**iPad mini 4 (iPadOS 15)**.
C'est la même interface web que la version Android, dans une appli iOS (WKWebView) qui fournit le pont `window.Native` en Swift.

- `index.html` : l'interface (copie de la version 3.15 de `dash-mini-4`, branche `test` ; elle est livrée dans l'appli à chaque compilation).
- `ios/` : l'appli (Swift, XcodeGen). Notice complète, installation et réglages : [`ios/LISEZ-MOI.md`](ios/LISEZ-MOI.md).
- `.github/workflows/ios.yml` : compile sur GitHub Actions (macOS) et publie l'IPA non signé (artefact `TableauDeBord-iPad-unsigned-ipa`) ; à signer avec ton identifiant Apple via Sideloadly.

L'appli Android (Samsung Galaxy Tab 4) reste dans le dépôt `dash-mini-4`.
