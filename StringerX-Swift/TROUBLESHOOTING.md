# Troubleshooting Network Issues

## "A server with the specified hostname could not be found"

This error typically occurs due to missing network entitlements in macOS apps.

### Solution 1: Add Entitlements File (Required)

1. In Xcode, **add the entitlements file** to your project:
   - File → Add Files to "StringerX"
   - Select `StringerX.entitlements`
   - Ensure it's added to the StringerX target

2. **Configure the target** to use the entitlements:
   - Select the project in the navigator
   - Select the StringerX target
   - Go to **Signing & Capabilities** tab
   - The entitlements file should be listed under "Entitlements File"
   - If not, manually set it: Build Settings → Code Signing Entitlements → `StringerX/StringerX.entitlements`

3. **Verify the capabilities** are enabled:
   - In Signing & Capabilities tab
   - You should see: **App Sandbox** enabled
   - Under App Sandbox, **Outgoing Connections (Client)** should be checked

### Solution 2: Disable App Sandbox (Alternative - Less Secure)

If you don't need sandboxing:

1. Go to Signing & Capabilities tab
2. Click the **"-"** button next to App Sandbox to remove it
3. Delete or modify the entitlements file to remove the sandbox key

**Note:** This is less secure and not recommended for App Store distribution.

### Solution 3: Check Build Settings

Verify in Build Settings:
- **Code Signing Entitlements** is set to `StringerX/StringerX.entitlements`
- **Enable Hardened Runtime** is set appropriately
- **Code Signing Identity** is set to "Sign to Run Locally" (for development)

### Debugging Steps

If the issue persists, add debug logging to see the actual error:

1. Open `Networking/FeverAPIClient.swift`
2. In the `request` method, add logging before the URLSession call:

```swift
// Add this before: let (data, response) = try await session.data(from: url)
print("🌐 Attempting to fetch: \(url.absoluteString)")
```

3. In the catch block for `decodingError`, add:

```swift
case .decodingError(let error):
    print("🔴 Decoding error: \(error)")
    return "Failed to decode response: \(error.localizedDescription)"
```

4. In `AccountService.swift`, add logging in the `login` method:

```swift
print("🔐 Attempting login to: \(url)")
print("🔑 API key (first 8 chars): \(String(token.prefix(8)))...")
```

### Testing the Fix

After adding entitlements:

1. **Clean build folder**: Product → Clean Build Folder (Shift+Cmd+K)
2. **Rebuild**: Product → Build (Cmd+B)
3. **Run**: Product → Run (Cmd+R)
4. Try logging in again

### Additional Network Checks

1. **Verify the URL format** in Settings:
   - Should be: `https://feed.wwwjfy.net` (with trailing slash is optional)
   - NOT: `https://feed.wwwjfy.net/fever/` (don't include the fever path)

2. **Test the API manually** with curl:
   ```bash
   # Test basic connectivity
   curl https://feed.wwwjfy.net/fever/

   # Should return something like: {"api_version":3,"auth":0}
   ```

3. **Check if HTTP redirect is needed**:
   Some servers redirect HTTP to HTTPS. If your server does this, make sure you're entering `https://` in the URL field.

### Known Working Configuration

For reference, here's a working setup:

**Entitlements (StringerX.entitlements):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
</dict>
</plist>
```

**Info.plist (already included):**
```xml
<key>NSAppTransportSecurity</key>
<dict>
	<key>NSAllowsArbitraryLoads</key>
	<true/>
</dict>
```

**Signing & Capabilities:**
- App Sandbox: ✓ Enabled
  - Outgoing Connections (Client): ✓ Checked
  - User Selected File (Read/Write): ✓ Checked

### Still Not Working?

If you're still getting the error after adding entitlements:

1. **Check Console.app** for additional error messages:
   - Open Console.app
   - Filter for "StringerX"
   - Look for URLSession or NSURLConnection errors

2. **Try with a different URL** to isolate the issue:
   - Try a public test API
   - If that works, the issue is specific to your server configuration

3. **Verify DNS resolution** in your app:
   Add this test code temporarily in `AccountService.login`:
   ```swift
   // Test DNS resolution
   let host = baseURL.host ?? "unknown"
   print("🔍 Resolving host: \(host)")
   ```

4. **Check for VPN/Firewall interference**:
   - Temporarily disable any VPN
   - Check macOS Firewall settings (System Settings → Network → Firewall)

### Quick Fix Checklist

- [ ] Added `StringerX.entitlements` to Xcode project
- [ ] Set Code Signing Entitlements in Build Settings
- [ ] Enabled App Sandbox with Outgoing Connections
- [ ] Clean build folder and rebuild
- [ ] Verified URL doesn't include `/fever/` path
- [ ] Tested server is reachable via curl/browser
- [ ] Checked Console.app for additional errors

---

**Common Mistake:** Forgetting to add the entitlements file to the target. Make sure when you drag the `.entitlements` file into Xcode, the target checkbox is checked!
