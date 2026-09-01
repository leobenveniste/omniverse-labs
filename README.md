<p align="center">
  <img src="assets/branding/omniverse_labs_logo.png" alt="Omniverse Labs Logo" width="130" />
</p>

<h1 align="center">Omniverse Labs 🚀</h1>

<p align="center">
  <strong>Automated Flutter & Android Mobile Apps Hub</strong><br>
  Built for rapid app scaffolding, local testing, release signing, and automated Google Play Console deployment.
</p>

---

## 📂 Project Structure

```
Omniverse Labs/
├── apps\                      # All individual Flutter mobile applications
├── scripts\                   # Automation & CLI management scripts
│   ├── app-manager.ps1        # Central orchestrator (create, run, build, test, deploy)
│   ├── generate-keystore.ps1  # Automated release keystore & signing config
│   └── setup-env.ps1          # Environment validator & SDK diagnostics
├── templates\                 # Fastlane & GitHub Actions CI/CD templates
│   ├── fastlane\              # Appfile and Fastfile for Google Play upload
│   └── ci\                    # GitHub Actions build & deploy workflow
├── keystores\                 # Secure local release keystores (gitignored)
├── .gitignore
└── README.md
```

---

## ⚡ Quick Start & Common Commands

All commands can be run directly via `.\scripts\app-manager.ps1`:

### 1. Diagnostics & Environment Check
Verify Android SDK, ADB, connected physical devices, and Flutter toolchain:
```powershell
.\scripts\app-manager.ps1 doctor
```

### 2. Scaffold a New Android App
Creates a new Flutter app with pre-configured Android release signing and keystore generation:
```powershell
.\scripts\app-manager.ps1 create -Name my_awesome_app -Org com.omniverselabs
```

### 3. List All Apps & Status
View all apps in the workspace, version numbers, signing config, and build statuses:
```powershell
.\scripts\app-manager.ps1 list
```

### 4. Local Testing & Hot Reload
Launch the app on a connected physical Android device, emulator, or Chrome:
```powershell
.\scripts\app-manager.ps1 run -App my_awesome_app
```

Or target a specific device:
```powershell
.\scripts\app-manager.ps1 run -App my_awesome_app -Device <device_id>
```

### 5. Run Automated Tests
Execute the unit and widget test suite:
```powershell
.\scripts\app-manager.ps1 test -App my_awesome_app
```

### 6. Build Release App Bundle (.aab) for Google Play
Compile a signed, production-ready Android App Bundle:
```powershell
.\scripts\app-manager.ps1 build -App my_awesome_app -Target aab -Config release
```
*Output location:* `apps/my_awesome_app/build/app/outputs/bundle/release/app-release.aab`

### 7. Build Standalone APK (.apk)
Compile a standalone signed APK for direct testing / sideloading:
```powershell
.\scripts\app-manager.ps1 build -App my_awesome_app -Target apk -Config release
```
*Output location:* `apps/my_awesome_app/build/app/outputs/flutter-apk/app-release.apk`

### 8. Sideload Directly to Device via ADB
Install the built APK onto your connected device in one step:
```powershell
.\scripts\app-manager.ps1 install -App my_awesome_app
```

---

## 🚀 Google Play Console Deployment

### Prerequisites:
1. **Google Play Console Developer Account**.
2. **Google Cloud Service Account Key**:
   - Create a Service Account with Google Play Developer permissions in Google Cloud Console.
   - Download the key as `service_account.json` and save it to `c:\Projects\Mobile Apps\service_account.json` (it is gitignored).

### Publish via CLI:
```powershell
.\scripts\app-manager.ps1 deploy-playstore -App my_awesome_app -Track internal
```
Supported tracks: `internal`, `alpha`, `beta`, `production`.

---

## 🔒 Security Best Practices
- Keystores (`*.jks`), passwords (`key.properties`), and Google Play credentials (`service_account.json`) are automatically gitignored by `.gitignore`.
- Keep backups of the `keystores/` folder in a secure password manager or encrypted vault.
