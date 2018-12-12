
der INVALID_TIMESTAMP weist darauf hin, dass die Timestamps in der MongoDB und im Content Repository nicht übereinstimmen.

Die User-Changes-Webapp ist ein Content Repository Listener. Die Webapp lauscht beim Content Server auf Content Events und speichert deren Timestamps in der MongoDB. Diese Events werden unter anderem vom Studio User ausgelöst, z.B. beim Editieren von Content, beim Check-In, Löschen von Content, usw.

Beim ersten Aufsetzen des CMS Systems startet die User-Changes-Webapp mit leeren MongoDB Collections und fängt an, auf Repository Events zu lauschen. Beim Neustarten der User-Changes-Webapp versucht die Webapp sich beim Content Server als Listener zu registrieren mit dem letzten Timestamp, den sie in der MongoDB gespeichert hat. Falls dieser Timestamp in der ChangeLog Tabelle vom Content Server nicht gefunden wird, schmeißt das Content Repository einen Fehler und die User-Changes-Webapp fährt nicht hoch.

Wurden Änderungen am Content Server vorgenommen, durch die der Timestamp im ChangeLog überschrieben wurde? Wenn dem so sein sollte, können Sie die Collection properties der MongoDB Datenbank blueprint_internal_models löschen und die User-Changes-Webapp neustarten.
