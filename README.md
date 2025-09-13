# brave-portable

Portable Brave browser configuration with debloating features and custom Chrome++ settings.

## Features

- **Portable**: No installation required - run directly from any folder
- **Debloated**: Brave Shields, Rewards, Wallet, VPN, and other Brave-specific features disabled
- **Chrome++ Enhanced**: Includes Chrome++ for additional customization options
- **Privacy Focused**: Pre-configured settings optimized for privacy and performance
- **Custom Extensions**: Managed extension configuration for optimal user experience

## Installation

1. Download the latest release ZIP file
2. Extract to your desired location
3. Run `Brave_Portable/Brave/brave.exe`

## Updates

To update while preserving your settings:
1. Run `Brave_Portable/Brave/update.bat`
2. Your custom configurations and Chrome++ settings will be preserved

## Important Notes

### Widevine DRM Support

**⚠️ Widevine cannot be pre-enabled or bundled; users must enable it manually in Brave's extension settings after launch.**

To enable Widevine for DRM content (Netflix, Amazon Prime, etc.):
1. Launch Brave Portable
2. Go to `brave://settings/extensions`
3. Find "Widevine Content Decryption Module"
4. Click "Enable" if available
5. Restart the browser if prompted

## Configuration Files

- `chrome++.ini` - Chrome++ configuration settings
- `debloat.reg` - Registry settings to disable Brave-specific features
- `update.bat` - Update script that preserves user settings

## License

This project packages and configures existing software:
- Brave Browser (Mozilla Public License 2.0)
- Chrome++ (MIT License)

No warranty is provided. Use at your own risk.
