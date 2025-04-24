# fuel_scan

Un'app per trovare i distributori di carburante più convenienti utilizzando i dati Open Data del MISE.

## Configurazione

### Ambiente di sviluppo
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Chiavi API
1. Copia `assets/config/keys.json.example` in `assets/config/keys.json`
2. Sostituisci il valore di `google_maps_api_key` con la tua chiave API di Google Maps
3. Sostituisci i valori di `admob_android_app_id` e `admob_ios_app_id` con i tuoi ID di app AdMob
4. Prima di compilare l'app:
   - Esegui `dart scripts/plist_backup.dart backup` per fare un backup di Info.plist
   - Esegui `dart scripts/pre_build.dart` per aggiornare le chiavi API
5. Dopo il commit:
   - Esegui `dart scripts/plist_backup.dart restore` per ripristinare Info.plist

### Generazione rapida di keys.json per AdMob
Per aggiungere rapidamente le chiavi AdMob:
```bash
dart scripts/generate_admob_keys.dart [android_app_id] [ios_app_id]
```

### Pubblicità
L'app utilizza Google AdMob per mostrare pubblicità:
- Banner nella parte inferiore delle schermate principali
- Annunci interstiziali mostrati occasionalmente quando si naviga tra le schermate
- Versione premium senza pubblicità disponibile come acquisto in-app

### Versione Premium
La versione premium offre:
- Nessuna pubblicità
- Interfaccia pulita e senza distrazioni
- Supporto allo sviluppo dell'app

Per testare la versione premium, usa la schermata Premium accessibile dall'icona nella barra superiore.