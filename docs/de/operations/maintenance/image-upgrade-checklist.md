---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# 📋 Checkliste: ERNI-KI Docker-Image-Upgrade

Diese Checkliste definiert den Prozess zur Aktualisierung von Container-Images
ohne Rückfall auf instabile `latest` Tags.

1. **Release-Auswahl**
   - Finden Sie einen stabilen semantischen Tag oder SHA256 Digest (in allen
     Fällen – `docker pull IMAGE@digest`).
   - Speichern Sie den Link zum Changelog/Release, wo die Änderungen beschrieben
     sind.

2. **Repository-Aktualisierung**
   - Ersetzen Sie in `compose.yml` und `compose.yml.example` den Tag durch den
     gewählten.
   - Aktualisieren Sie die Dokumentation (Service-Inventory, Monitoring-Guide,
     Architecture usw.), damit die Tags mit der Konfiguration übereinstimmen.
   - Wenn das Image Docker Secrets/Entrypoint verwendet, stellen Sie sicher,
     dass die Anweisungen in `docs/` ebenfalls aktualisiert sind.

3. **Testen**
   - `docker compose pull SERVICE && docker compose up -d SERVICE` (oder
     `--no-deps`).
   - Überprüfen Sie Healthchecks und wichtige Endpunkte:

     ```bash
     docker compose ps SERVICE
     docker compose logs SERVICE --tail=50
     ```

   - Für Exporter: `curl -s http://localhost:<port>/metrics | head`.

4. **Watchtower**
   - Stellen Sie sicher, dass für Dienste mit automatischer Aktualisierung
     (`watchtower.enable=true`) der neue Tag angegeben ist. Watchtower übernimmt
     diesen beim nächsten Zyklus.
   - Für kritische Dienste (Nginx, DB) bleibt die automatische Aktualisierung
     deaktiviert.

5. **Release-Dokumentation**
   - Listen Sie in `CHANGELOG.md`/Release-Notes die aktualisierten Images auf.
   - Fügen Sie bei Bedarf Anweisungen zum Rollback (vorheriger Digest) hinzu.

6. **Validierung**
   - Führen Sie `docker compose config` aus und stellen Sie sicher, dass das
     Ergebnis nur gepinnte Tags enthält.
   - Führen Sie `rg ':latest'` aus – im Repository sollten keine Erwähnungen von
     Container-Images mit diesem Tag verbleiben.

Die Einhaltung der Checkliste garantiert, dass Watchtower keine inkompatiblen
Releases zieht und vereinfacht Rollbacks bei Problemen mit Updates.
