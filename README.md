# CarDecalB7 – Secure Vault App

See [`secure_vault/`](./secure_vault/) for the full Flutter project.

---

# 🔐 תיקייה נעולה – Secure Vault

> אפליקציית Flutter מאובטחת לשמירת קבצים מוצפנים מקומית במכשיר.

---

## תיאור

**Secure Vault** היא אפליקציית מובייל (Flutter – Android ו-iOS) שמאפשרת למשתמש לאחסן קבצים פרטיים (תמונות, סרטונים, מסמכים) בצורה מוצפנת לחלוטין על המכשיר, ללא כל שרת חיצוני. הגישה לקבצים מותנית באימות משתמש (PIN ו/או ביומטרי).

---

## ארכיטקטורה

```
secure_vault/
├── lib/
│   ├── main.dart                        # נקודת כניסה + הזרקת תלויות
│   ├── app.dart                         # MaterialApp + RTL + security overlay
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart       # קבועי אפליקציה (routes, names)
│   │   │   └── security_constants.dart  # קבועי אבטחה (PBKDF2 iterations, etc.)
│   │   ├── errors/app_exceptions.dart   # היררכיית חריגות
│   │   └── utils/file_utils.dart        # עזר: גודל קובץ, MIME, תאריך
│   ├── data/
│   │   ├── models/
│   │   │   ├── vault_file.dart          # מודל מטא-דאטה לקובץ מוצפן
│   │   │   └── vault_category.dart      # קטגוריות (תמונות, סרטונים...)
│   │   ├── services/
│   │   │   ├── encryption_service.dart  # AES-256-CBC + PBKDF2 + HMAC
│   │   │   ├── biometric_service.dart   # local_auth wrapper
│   │   │   ├── secure_storage_service.dart # flutter_secure_storage wrapper
│   │   │   ├── database_service.dart    # SQLite – מטא-דאטה בלבד
│   │   │   └── auto_lock_service.dart   # טיימר נעילה אוטומטית
│   │   └── repositories/
│   │       ├── auth_repository.dart     # לוגיקת אימות + ניהול מפתחות
│   │       └── vault_repository.dart    # ייבוא/ייצוא/מחיקת קבצים
│   ├── providers/
│   │   ├── auth_provider.dart           # מצב אימות + lifecycle observer
│   │   ├── vault_provider.dart          # מצב רשימת קבצים
│   │   └── settings_provider.dart       # הגדרות משתמש
│   └── presentation/
│       ├── theme/app_theme.dart         # עיצוב כהה + זהב
│       ├── screens/                     # splash, auth, vault, settings
│       └── widgets/                     # PIN pad, FileTile, CategoryChip...
├── android/
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml          # הרשאות, allowBackup=false
│   │   ├── kotlin/.../MainActivity.kt   # FLAG_SECURE (מניעת צילום מסך)
│   │   └── res/xml/data_extraction_rules.xml  # חסימת גיבוי
│   └── app/proguard-rules.pro
└── ios/Runner/
    ├── Info.plist                       # NSFaceIDUsageDescription
    └── AppDelegate.swift                # Security overlay ב-background
```

---

## מנגנון אבטחה

### הצפנת קבצים

```
PIN  ──PBKDF2-HMAC-SHA256──▶  masterKey (64 bytes)
                               ├── [0:32]  AES-256 encryption key
                               └── [32:64] HMAC-SHA256 integrity key

קובץ מוצפן על הדיסק:
[ 16B IV ] [ 32B HMAC-SHA256 ] [ ciphertext (AES-256-CBC) ]
```

- **PBKDF2** עם **100,000 איטרציות** – מאט התקפות brute-force
- **AES-256-CBC** – הצפנה חזקה לכל קובץ
- **HMAC-SHA256** (Encrypt-then-MAC) – מגן מפני padding-oracle ופגיעה בשלמות
- **IV אקראי** לכל קובץ – מגן מפני ניתוח דפוסים
- **PBKDF2 רץ ב-isolate** נפרד – לא חוסם את ה-UI

### מנגנוני הגנה

| מנגנון | Android | iOS |
|--------|---------|-----|
| מניעת צילום מסך | `FLAG_SECURE` | Security overlay |
| הסתרה ב-task switcher | `FLAG_SECURE` | Security overlay |
| נעילה על רקע | `AppLifecycleObserver` | `AppLifecycleObserver` |
| נעילה אוטומטית | Timer (ברירת מחדל: 2 דק') | Timer |
| חסימה אחרי ניסיונות שגויים | 5 ניסיונות → 5 דק' | 5 ניסיונות → 5 דק' |
| גיבוי מוגן | `allowBackup=false` | Keychain no-backup |

> **⚠️ מגבלות:**  
> - מכשיר עם root/jailbreak עוקף את ה-sandbox.  
> - PIN חזק (6+ ספרות) מומלץ בחום.

---

## התקנה

```bash
cd secure_vault
flutter pub get
flutter run

# ייצור:
flutter build apk --release   # Android
flutter build ipa --release   # iOS (נדרש Mac)
```

### Android
- `minSdkVersion 23` (Android 6.0+) – נדרש לביומטרי
- ב-`android/app/build.gradle` הגדר `applicationId` ייחודי

### iOS
- פתח `ios/Runner.xcworkspace` ב-Xcode
- הגדר Bundle Identifier + Team

---

## טכנולוגיות

| חבילה | תפקיד |
|-------|--------|
| `flutter_secure_storage` | Keychain/Keystore |
| `encrypt` + `crypto` | AES-256-CBC + PBKDF2 + HMAC |
| `local_auth` | Biometric / Face ID |
| `file_picker` | בחירת קבצים |
| `sqflite` | מטא-דאטה |
| `provider` | State management |

---

## רישיון

MIT License