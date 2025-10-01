# EZ-HUD

A modern, feature-rich HUD system for FiveM servers with full Qbox framework compatibility and advanced underwater diving support.

## 📸 Screenshots

![EZ-HUD Interface](https://cdn.discordapp.com/attachments/1388894940955807754/1422892794434949191/Screenshot_2025-10-01_144603.png?ex=68de53ae&is=68dd022e&hm=ed4b2f9dd791e88d47af2c9001c488b7bd84b618ddace27283f8dfa7d518ebb5&)

*Modern HUD interface showing vehicle status, weapon HUD, minimap, and status indicators*

## ✨ Features

### 🎨 **Modern UI Design**
- Clean, responsive interface with smooth animations
- Customizable color schemes and themes
- FontAwesome icon integration
- Green-themed weapon HUD with glow effects

### 🚗 **Vehicle HUD**
- Real-time speedometer (MPH/KMH support)
- Fuel level indicator with multiple fuel system compatibility
- Engine health and status monitoring
- Compass and direction display
- Seatbelt detection and warnings

### 🏊‍♂️ **Advanced Diving System**
- **QBX Divegear Integration**: Full compatibility with [qbx_divegear](https://github.com/Qbox-project/qbx_divegear)
- **Smart Oxygen Detection**: Automatically switches between stamina and oxygen underwater
- **Diving Equipment Support**: Enhanced oxygen capacity with proper diving gear
- **Health Management**: Realistic drowning mechanics with configurable damage

### 🔫 **Weapon HUD**
- Circular weapon display with 50+ weapon support
- Real-time ammo tracking and low ammo warnings
- Weapon type categorization (Pistol, SMG, Rifle, etc.)
- Clean, borderless design

### 📊 **Status Indicators**
- Health, armor, hunger, thirst monitoring
- Stress system with visual effects
- Stamina tracking with underwater breath integration
- Voice chat range indicators

### 🗺️ **Minimap Enhancement**
- Always-on minimap option
- Fixed zoom levels to prevent jumping/glitching
- Custom minimap support with troubleshooting
- Walking mode compatibility

## 🔧 Dependencies

### Required
- [ox_lib](https://github.com/overextended/ox_lib) - Core library functions
- [qbx_core](https://github.com/Qbox-project/qbx_core) - Qbox framework (primary)
- [ox_inventory](https://github.com/overextended/ox_inventory) - For diving gear detection

### Optional
- [qbx_divegear](https://github.com/Qbox-project/qbx_divegear) - Enhanced diving mechanics
- [pma-voice](https://github.com/AvarianKnight/pma-voice) - Voice chat features
- Various fuel systems: x-fuel, LegacyFuel, ps-fuel, ox_fuel, okokGasStation

### Compatibility
- **Primary**: Qbox Framework
- **Legacy**: QBCore (backward compatibility maintained)

## 🚀 Installation

1. **Download** the resource and extract to your `resources` folder
2. **Install Dependencies**: Ensure `ox_lib`, `qbx_core`, and `ox_inventory` are installed
3. **Add to server.cfg**:
   ```
   ensure ox_lib
   ensure qbx_core
   ensure ox_inventory
   ensure ez-hud
   ```
4. **Optional**: Install `qbx_divegear` for enhanced diving features
5. **Restart** your server

## ⚙️ Configuration

### Basic Settings
```lua
Config.useMPH = true                    -- Use MPH instead of KMH
Config.minimapAlwaysOn = true          -- Keep minimap always visible
Config.fuel = 'xfuel'                  -- Fuel system compatibility
Config.debug = false                   -- Enable debug mode
```

### Diving System
```lua
Config.enableOxygenDamage = true       -- Enable drowning mechanics
Config.enableQbxDivegear = true        -- QBX divegear integration
Config.oxygenWarningThreshold = 15     -- Health damage threshold (%)
Config.qbxDivegearItem = 'diving_gear' -- Diving gear item name
```

### Weapon HUD
```lua
Config.useWeaponHUD = true             -- Enable weapon display
Config.weaponUpdateInterval = 100      -- Update frequency (ms)
```

### Stress & Stamina
```lua
Config.useStamina = true               -- Enable stamina tracking
Config.staminaColorNormal = "#00ff41"  -- Normal stamina color
Config.staminaColorLow = "#ff6b35"     -- Low stamina warning color
```

## 🏊‍♂️ Diving System Details

### Without Diving Gear
- **Oxygen Capacity**: 25 seconds
- **Health Warning**: Starts at 15% oxygen (1 HP/update)
- **Critical Damage**: At 0% oxygen (3 HP/update)

### With Basic Diving Gear
- **Oxygen Capacity**: 120 seconds
- **Health Damage**: Only when oxygen reaches 0% (2 HP/update)

### With QBX Divegear
- **Oxygen Capacity**: 2000 seconds (matches qbx_divegear)
- **Smart Detection**: Automatically detects `diving_gear` inventory item
- **Health Damage**: Only when equipment oxygen is completely depleted
- **Full Integration**: Syncs with qbx_divegear's oxygen management system

## 🔫 Weapon Support

Supports 50+ weapons including:
- **Pistols**: Combat Pistol, AP Pistol, SNS Pistol, etc.
- **SMGs**: Micro SMG, SMG, Combat PDW, etc.
- **Rifles**: Assault Rifle, Carbine Rifle, Advanced Rifle, etc.
- **Shotguns**: Pump Shotgun, Sawed-Off, Combat Shotgun, etc.
- **Snipers**: Sniper Rifle, Heavy Sniper, Marksman Rifle, etc.
- **Heavy**: RPG, Minigun, Combat MG, etc.

## 🐛 Debug Commands

- `/hud-debug` - Toggle debug mode
- `/hud-stress [amount]` - Set stress level (0-100)
- `/hud-reload` - Reload HUD configuration

## 🔄 Framework Migration

This resource has been fully converted from QBCore to Qbox framework:
- **Player Data**: Uses `QBX.PlayerData` instead of `QBCore.Functions.GetPlayerData()`
- **Events**: Qbox event handlers with QBCore compatibility
- **Exports**: Updated to use Qbox core exports
- **Performance**: Optimized for Qbox's enhanced performance

## 📝 Changelog

### Latest Updates
- ✅ Full QBX Divegear integration
- ✅ Enhanced weapon HUD with green theme
- ✅ Removed weapon ammo circle borders
- ✅ Smart underwater breath detection
- ✅ Configurable drowning mechanics
- ✅ Improved minimap stability

## 🆘 Support & Troubleshooting

### Common Issues
1. **Minimap Glitching**: Set `Config.fixMinimapZoom = true`
2. **Fuel Not Showing**: Check fuel system configuration
3. **Diving Gear Not Detected**: Ensure qbx_divegear and ox_inventory are running
4. **Performance Issues**: Adjust update intervals in config

### Debug Mode
Enable `Config.debug = true` for detailed console logging of all HUD systems.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Credits

- **Original**: Majestic HUD
- **Qbox Conversion**: Enhanced for Qbox Framework compatibility
- **Diving Integration**: QBX Divegear compatibility layer
- **UI Enhancements**: Modern weapon HUD and underwater systems

- Original framework compatibility
- Modern UI design
- Qbox integration by EZ Development

## License

This project is licensed under the MIT License.