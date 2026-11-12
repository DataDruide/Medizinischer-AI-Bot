# Medi – Gesundheitsassistent

Eine schlanke Flutter-Chat-App mit lokaler Antwortgenerierung über Ollama und
öffentlicher openFDA-Suche für Arzneimittel-Kennzeichnungen. Die KI benötigt
keinen Cloudanbieter und keinen API-Schlüssel; openFDA kann Nutzungslimits
anwenden.

Die Oberfläche verwendet die lokal gebündelte Schrift Nunito Sans. Ihre
SIL-OFL-Lizenz liegt unter `assets/fonts/OFL.txt`; die Schrift benötigt keine
Netzwerkverbindung.

Beim Start zeigt `flutter_native_splash` den nativen Marken-Splash auf iOS und
Android; danach führt eine kurze Animation zum verpflichtenden Gesundheits-
Check. Für Chatantworten werden die Angaben an den lokal konfigurierten
Ollama-Dienst gesendet. Passende Medikamentensuchbegriffe können zusätzlich an
openFDA übertragen werden. Medi gibt allgemeine Orientierung, keine Diagnose
oder individuelle Therapieempfehlung.

## Starten

```sh
cp .env.example .env
flutter pub get
dart run flutter_native_splash:create
ollama pull qwen2.5:3b
flutter run
```

Ollama muss während der Nutzung laufen (`ollama serve`). Die App verwendet
standardmäßig `qwen2.5:3b`. Modell und Basis-URL können über `.env` als
Startwerte gesetzt werden; `--dart-define` überschreibt diese Startwerte.
Profilbezogene Änderungen in den Einstellungen haben anschließend Vorrang und
werden verschlüsselt gespeichert. Android-Emulatoren erreichen den Host über
`10.0.2.2`, iOS-Simulator und Web über `127.0.0.1`. Ein anderes Modell oder
eine andere Ollama-Adresse lässt sich beim Start setzen:

```sh
flutter run --dart-define=OLLAMA_MODEL=qwen2.5:3b \
  --dart-define=OLLAMA_BASE_URL=http://127.0.0.1:11434
```

Auf echten Geräten muss die Ollama-Adresse auf einen erreichbaren Server im
vertrauenswürdigen lokalen Netzwerk zeigen. Ollama sollte nicht ungeschützt
ins öffentliche Internet freigegeben werden.

Die optionale Integrationstest-Anfrage an das lokal laufende Modell startest du
mit:

```sh
RUN_OLLAMA_INTEGRATION_TESTS=1 flutter test test/ollama_chat_live_test.dart
```

Alternativ ist `main.dart` im Projektstamm ein Einstiegspunkt, der an
`lib/main.dart` weiterleitet.

## Funktionen und Grenzen

- Spracheingabe über die Erkennung des Geräts bzw. Browsers
- Profilbezogene Einstellungen für Darstellung, Spracheingabe, Ollama und
  openFDA
- Sichtbare Fortschritts-, Erfolgs- und Fehlermeldungen für wichtige Vorgänge
- Kontextbezogene, generative Antworten durch das lokal laufende Ollama-Modell
- Beim Chatstart analysiert Ollama alle sieben Fragebogenpunkte und gibt zu
  jedem eine eigene unverbindliche Orientierung
- Begrenzte und geprüfte Chateingaben; Fragebogenangaben werden als Kontext
  verwendet, nicht als Diagnosegrundlage
- Dynamische Suche nach Medikamentennamen in openFDA
- Chatverlauf mit Anwendungsgebieten und Warnhinweisen aus der Kennzeichnung
- Mehrere getrennte lokale Profile mit 6- bis 12-stelliger PIN
- Verschlüsselte dauerhafte Speicherung von Fragebogen, Chatverlauf,
  KI-Antworten und openFDA-Cache; keine Cloud-Synchronisierung
- openFDA-Cache je Profil: offline wird ein gespeicherter Treffer als
  möglicherweise veraltet markiert; ohne Cache erscheint ein Hinweis zum
  manuellen Wiederholen. Anfragen werden nicht automatisch nachgesendet.
- Bei nicht erreichbarem Ollama bleiben der Chat und die Fehlermeldung im
  Profil erhalten; eine Anfrage kann manuell erneut gesendet werden.
- Nur passende Medikamentensuchbegriffe werden an openFDA gesendet; alle
  Chatnachrichten und Fragebogenangaben werden an den konfigurierten
  Ollama-Server übertragen
- Die FDA-Kennzeichnungen sind überwiegend englischsprachig und beziehen sich
  auf die dort erfassten Produkte; sie sind keine personalisierte Beratung,
  Diagnose oder Therapieempfehlung
- Das Modell kann Fehler machen. Antworten sind allgemeine Information, keine
  Diagnose oder Therapieempfehlung. Bei akuten Warnzeichen sofort 112 rufen.
- Keine Anbindung an Patientenakten, Apple Health oder Health Connect

Die Spracheingabe hängt von Plattform und Browser ab. Android und iOS fragen
beim ersten Verwenden die Mikrofon- und Spracherkennungsberechtigung an.

## Dynamisches App-Icon

Nach sieben Tagen ohne Öffnen wechselt Android das Launcher-Icon bestmöglich
zum traurigen Medi-Icon. iOS versucht den Wechsel über Background App Refresh;
das Betriebssystem garantiert den Ausführungszeitpunkt nicht. Beim nächsten
Öffnen wird auf beiden Plattformen wieder das normale Icon gesetzt. Im Web
wird beim nächsten Laden kurz das traurige Favicon angezeigt und nach dem
ersten App-Frame zurückgesetzt. Das Icon einer bereits installierten Web-App
kann der Browser nicht zuverlässig im Hintergrund ändern.

## Profile und Offline-Nutzung

Beim Start wählst du ein Profil oder legst ein neues an. Gesundheits-Check,
Chatverlauf, KI-Antworten und Medikamenten-Cache werden je Profil lokal mit
AES-256-GCM verschlüsselt; der Schlüssel wird aus der Profil-PIN abgeleitet.
Der Profilname und die nötigen Verschlüsselungs-Metadaten bleiben für die
Profilwahl unverschlüsselt. Die Daten bleiben auf dem jeweiligen Gerät bzw. im
jeweiligen Browser-Speicher und werden nicht zwischen Geräten synchronisiert.
Wenn du eine PIN vergisst, kann das Profil nicht wiederhergestellt werden;
Profile lassen sich in der Profilübersicht dauerhaft löschen.

Ollama kann ohne Internet antworten, wenn der konfigurierte Ollama-Dienst
erreichbar ist und das Modell bereits installiert ist. Ist der Dienst nicht
verfügbar, wird die Fehlermeldung im Verlauf gespeichert; es gibt keine
automatische Warteschlange. openFDA benötigt eine Internetverbindung. Bei
einem Ausfall zeigt Medi nach Möglichkeit den gespeicherten Treffer deutlich
als Cache an; andernfalls kannst du die Suche später manuell erneut senden.
