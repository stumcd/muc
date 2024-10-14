# Rationale

### Potential issues and impact to upgrade workflow

#### Bootstrap Token is missing
Without a Bootstrap Token, the MDM Server managing this device cannot authorise an upgrade or update that requires a reboot. Without this, you can't push the upgrade from the MDM server. 
Use secure token, bootstrap token and volume ownership in deployments [Apple Platform Deployment documentation](https://support.apple.com/en-au/guide/deployment/dep24dbdcf9e/web)

#### Hardware not compatible with macOS Sonoma
macOS Sonoma is compatible with these computers: [Apple documentation](https://support.apple.com/en-au/105113)

#### Not enough free space
macOS Sonoma requires 23 GB of free space. Krypted: [Free Space Required for Modern macOS Upgrades](https://krypted.com/mac-os-x/free-space-required-for-modern-macos-upgrades/)

#### 'Macintosh HD' not found 
There is no volume present named 'Macintosh HD'.

#### 'Recovery' not found 
There is no volume present named 'Recovery'.