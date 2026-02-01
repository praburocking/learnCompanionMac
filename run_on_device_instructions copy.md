# How to Run EchoRead on a Physical iPad

Running on a physical device requires a valid **Apple Developer Signing Certificate**. Since no signing identities were found on your Mac, you must use Xcode to handle the signing process (this is free).

## Steps

1.  **Connect your iPad** to your Mac via USB/Cable.
2.  **Unlock your iPad** and trust the computer if prompted.
3.  The project will open in Xcode automatically (or run `xed .` in terminal).

### In Xcode:

1.  **Select the "EchoRead" target**:
    *   In the left sidebar (Project Navigator), click on the blue icon at the top (the Package/Project root).
    *   In the main view, under "Targets", select `EchoRead`.

2.  **Configure Signing**:
    *   Click on the **"Signing & Capabilities"** tab.
    *   **Team**: Select your personal team (or "Add an Account..." to log in with your Apple ID).
    *   **Bundle Identifier**: It is currently `com.local.EchoRead`. You might need to change this to something unique (e.g., `com.yourname.EchoRead`) if Xcode complains.

3.  **Run the App**:
    *   In the top toolbar, select your connected **iPad** as the destination (instead of a Simulator).
    *   Click the **Run** (Play) button or press `Cmd + R`.

### Troubleshooting
*   **"Untrusted Developer"**: On your iPad, go to **Settings > General > VPN & Device Management**, tap your Apple ID, and trust the app.
*   **"Enable Developer Mode"**: On iOS 16+, you may need to enable Developer Mode in **Settings > Privacy & Security > Developer Mode**.

---
*Once you have successfully run the app once via Xcode, a valid provisioning profile will be created, and we might be able to automate future builds.*
