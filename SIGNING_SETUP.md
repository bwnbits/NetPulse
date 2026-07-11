# NetPulse — Code Signing & Notarization Setup

This gets `NetPulse` signed as **bwnbits** and notarized by Apple, so anyone
downloading it from GitHub sees a clean "Developer: [Your Name]" prompt
instead of a Gatekeeper block — fully automated on every tagged release.

## 1. One-time Apple setup

Good news — your project's `.pbxproj` already has a Team ID attached:
**`K3Q4A829B2`**. That's already filled into `ExportOptions.plist` below.

⚠️ One thing to confirm: Xcode assigns a Team ID even to **free, non-paid**
("Personal Team") Apple IDs — those can sign for local development/testing,
but **cannot** create a "Developer ID Application" certificate, which is
required for distributing outside the App Store without Gatekeeper warnings.
Check this in Xcode → Settings → Accounts → select your Apple ID → if you see
"Developer ID Application" as an available certificate type to create, you're
enrolled in the paid program. If you only see "Apple Development" / "Apple
Distribution" (App Store only), you'll still need to enroll:

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/) ($99/yr) — this upgrades your existing Team ID, no need to create a new one.
2. In Xcode → Settings → Accounts → your Apple ID → **Manage Certificates** →
   **+** → **Developer ID Application**. This creates your signing certificate.
3. Your Team ID stays `K3Q4A829B2` — no change needed once enrolled.
4. Create an **app-specific password** for notarization:
   [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security →
   App-Specific Passwords → generate one, name it e.g. `netpulse-notarize`.

## 2. Export your signing certificate as a .p12

In **Keychain Access**:
1. Find your "Developer ID Application: [Your Name] (TEAMID)" certificate
   (under the **login** keychain, **My Certificates**).
2. Right-click → **Export** → save as `DeveloperID.p12`, set a strong password
   (you'll need this password again in step 3).
3. Convert it to base64 so it can be stored as a GitHub secret:

   ```bash
   base64 -i DeveloperID.p12 | pbcopy
   ```

   This copies the base64 text to your clipboard.

## 3. Add GitHub Actions secrets

In your repo: **Settings → Secrets and variables → Actions → New repository secret**.
Add each of these:

| Secret name                       | Value                                                        |
|------------------------------------|---------------------------------------------------------------|
| `DEVELOPER_ID_CERT_P12_BASE64`     | The base64 text from step 2 (paste from clipboard)             |
| `DEVELOPER_ID_CERT_PASSWORD`       | The password you set when exporting the .p12                   |
| `KEYCHAIN_PASSWORD`                | Any new password — just used to protect the temporary CI keychain |
| `APPLE_ID`                         | Your Apple ID email                                             |
| `APPLE_TEAM_ID`                    | Your Team ID from step 1.3                                      |
| `APPLE_APP_SPECIFIC_PASSWORD`      | The app-specific password from step 1.4                         |

## 4. Update `ExportOptions.plist`

Replace `YOUR_TEAM_ID` in `ExportOptions.plist` with your real Team ID.
Commit both `ExportOptions.plist` and `.github/workflows/release.yml` to the
root of your repo (next to your `.xcodeproj`).

## 5. Cut a release

```bash
git tag v1.0.1
git push origin v1.0.1
```

That's it — GitHub Actions will:
1. Build & archive NetPulse
2. Sign it with your Developer ID
3. Notarize it with Apple
4. Staple the notarization ticket
5. Attach the signed, notarized `.zip` to a new GitHub Release automatically

Anyone who downloads that zip from your Releases page and opens `NetPulse.app`
will see it's signed by you — no more "unidentified developer" warning.

## Notes

- The workflow runs on `macos-14` GitHub-hosted runners — no cost for public
  repos, and included minutes for private ones.
- If notarization fails, check the log with:
  ```bash
  xcrun notarytool log <submission-id> --apple-id you@email.com --team-id TEAMID --password APP_SPECIFIC_PASSWORD
  ```
- You can still test builds locally without any of this — this setup only
  matters for the version you actually distribute to others.
