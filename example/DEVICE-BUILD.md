# Dev client on a physical iPhone, built locally

This is how to build the example dev client for a real iPhone on this Mac and run Metro over Tailscale.

## What is on disk

| Item | Where | Notes |
| --- | --- | --- |
| EAS project | `app.json` (`extra.eas.projectId`, `owner`) | `@lucaskniight/expo-scroll-edge-effect-example` |
| Build profile | `eas.json` (`development`) | dev client, internal (ad hoc) distribution, `credentialsSource: local` |
| Signing cert | `credentials/ios/dist-cert.p12` | iPhone Distribution, team J53N6D4ML3, expires 2027-07-03 |
| Profile | `credentials/ios/profile.mobileprovision` | Ad hoc, 7 registered devices, expires 2027-07-03 |
| Cert password | `credentials.json` | git-ignored together with `credentials/` |

The cert and profile are shared with your other EAS apps. If a new phone is added, run `eas device:create`, then `eas credentials -p ios` and download again.

## One-time Mac setup

1. `eas login` (already done).
2. Apple WWDR G3 intermediate certificate in the login keychain. Without it the signing identity shows as not valid. Install it with:

```sh
curl -sSLo /tmp/AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
security add-certificates -k ~/Library/Keychains/login.keychain-db /tmp/AppleWWDRCAG3.cer
```

3. `brew install fastlane` (already installed).
4. Enable HTTPS certificates for the tailnet at https://login.tailscale.com/admin/dns. Without this, `tailscale serve` hangs and the phone cannot install over the air.

## Fetch credentials again

```sh
eas credentials -p ios
# Apple login: yes (cached session)  ->  credentials.json  ->  Download credentials from EAS to credentials.json
```

## Build the IPA locally

```sh
eas build --local --platform ios --profile development --non-interactive --output dist/example-dev.ipa
```

## Install on the phone over Tailscale

```sh
scripts/host-ipa.sh dist/example-dev.ipa
```

The GUI Tailscale app cannot serve a folder, so the script starts a local `python3 -m http.server` on port 8765 and proxies to it with `tailscale serve --bg`. Run it from a normal terminal, not a sandboxed shell. The first HTTPS request can take up to a minute while Let's Encrypt issues the certificate.

Open the printed `https://<mac>.ts.net/` URL on the phone (Tailscale must be on) and tap Install. Stop hosting with `pkill -f 'http.server 8765'` and `tailscale serve reset`.

## Run Metro over Tailscale

```sh
bun run start:tailscale
```

Then open the dev client on the phone and enter `http://<tailscale ip>:8081`, or scan the QR code the CLI prints.

iOS App Transport Security blocks plain HTTP to a Tailscale IP (100.x is not a local network). `app.json` sets `NSAllowsArbitraryLoads` under `ios.infoPlist` so the dev client can load Metro. If you see "requires the use of a secure connection", the installed build is missing that key. Rebuild the IPA.

## Automatic discovery on the phone

The dev client's "searching for development servers" uses Bonjour on the local Wi-Fi, which does not cross Tailscale. The remote path is Expo dev sessions. `expo start` registers the Metro URL with Expo when the CLI is logged in (`bun x expo whoami` should print `lucaskniight`). In the dev client, open the account tab and sign in to the same Expo account. The server then appears under Development servers and one tap opens it. If it does not show, restart Metro. The CLI only registers on start, and the session expires when Metro is stopped for a while.
