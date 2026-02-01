# Running EchoRead

This guide covers how to run EchoRead on various platforms and devices.

## 📱 iPad Simulator

### Method 1: Using the Helper Script (Fastest)
We have included a script to quickly package and install the app on a booted simulator.

1.  **Open Simulator**: Launch the Simulator app and boot your desired iPad device.
2.  **Open Terminal**: Navigate to the project directory.
3.  **Run the script**:
    ```bash
    ./package_ipad.sh
    ```
4.  The app will be installed and should launch automatically.

### Method 2: Using Xcode
1.  Open the project folder in **Xcode** (or run `xed .`).
2.  Select the **EchoRead** scheme in the top toolbar.
3.  Choose an **iPad Simulator** (e.g., "iPad Pro 13-inch") as the destination.
4.  Press **Cmd + R** or click the **Run** button.

---

## 📲 Physical iPad Device

Running on a physical device requires a valid **Apple Developer Signing Certificate**.

### Prerequisites
1.  **Apple ID**: You need a free Apple ID.
2.  **Xcode**: Installed on your Mac.
3.  **Cable**: Connect your iPad to your Mac via USB/Cable.

### Steps
1.  **Open Project**: Open the folder in Xcode.
2.  **Select Target**:
    *   In the Project Navigator (left sidebar), click the top-level project icon.
    *   Under "Targets", select `EchoRead`.
3.  **Configure Signing**:
    *   Go to the **"Signing & Capabilities"** tab.
    *   **Team**: Select your personal team (or "Add an Account..." to log in with your Apple ID).
    *   **Bundle Identifier**: Change `com.local.EchoRead` to something unique (e.g., `com.yourname.EchoRead`) if prompted.
4.  **Run**:
    *   Unlock your iPad and trust the computer if prompted.
    *   Select your connected **iPad** as the destination in the top toolbar.
    *   Press **Cmd + R**.

### Troubleshooting Physical Device
*   **"Untrusted Developer"**: On your iPad, go to **Settings > General > VPN & Device Management**, tap your Apple ID profile, and trust the app.
*   **"Enable Developer Mode"**: on iOS 16+, go to **Settings > Privacy & Security > Developer Mode** and enable it.

---

## 💻 macOS

### Method 1: Xcode
1.  Select **My Mac** in the Xcode destination selector.
2.  Press **Cmd + R**.

### Method 2: Command Line / Bundle Script
To create a standalone macOS app:
```bash
./bundle_app.sh
```
This creates `EchoRead.app` in the project directory, which you can double-click to run.
