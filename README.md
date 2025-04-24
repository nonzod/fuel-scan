# fuel_scan

Evviva

## Configurazione

flutter pub run build_runner build --delete-conflicting-outputs

### Chiavi API
1. Copia `assets/config/keys.json.example` in `assets/config/keys.json`
2. Sostituisci il valore di `google_maps_api_key` con la tua chiave API di Google Maps
3. Prima di compilare l'app:
   - Esegui `dart scripts/plist_backup.dart backup` per fare un backup di Info.plist
   - Esegui `dart scripts/pre_build.dart` per aggiornare le chiavi API
4. Dopo il commit:
   - Esegui `dart scripts/plist_backup.dart restore` per ripristinare Info.plist