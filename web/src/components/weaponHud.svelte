<script lang="ts">
    import { fade, fly } from 'svelte/transition';
    import { ReceiveEvent } from '@utils/eventsHandlers';

    let visible: boolean = false;
    let weapon: number = 0;
    let ammo: number = 0;
    let totalAmmo: number = 0;
    let weaponHash: number = 0;

    // Map weapon hashes to display names (using string keys for compatibility)
    const weaponNames: {[key: string]: string} = {
        "453432689": "Pistol", // WEAPON_PISTOL
        "1593441988": "Combat Pistol", // WEAPON_COMBATPISTOL  
        "-1074790547": "Assault Rifle", // WEAPON_ASSAULTRIFLE
        "-2084633992": "Carbine Rifle", // WEAPON_CARBINERIFLE
        "-1357824103": "Advanced Rifle", // WEAPON_ADVANCEDRIFLE
        "736523883": "SMG", // WEAPON_SMG
        "171789620": "PDW", // WEAPON_PDW
        "487013001": "Pump Shotgun", // WEAPON_PUMPSHOTGUN
        "2017895192": "Sawed-Off Shotgun", // WEAPON_SAWNOFFSHOTGUN  
        "100416529": "Sniper Rifle", // WEAPON_SNIPERRIFLE
        "205991906": "Heavy Sniper", // WEAPON_HEAVYSNIPER
        "2132975508": "Bullpup Rifle", // WEAPON_BULLPUPRIFLE
        "-1716589765": "Pistol .50", // WEAPON_PISTOL50
        "-1076751822": "SNS Pistol", // WEAPON_SNSPISTOL
        "-771403250": "Heavy Pistol", // WEAPON_HEAVYPISTOL
        "2144741730": "Gusenberg Sweeper", // WEAPON_GUSENBERG
        "-1834847097": "Special Carbine", // WEAPON_SPECIALCARBINE
        "-2066285827": "Bullpup Shotgun", // WEAPON_BULLPUPSHOTGUN
        "1649403952": "Compact Rifle", // WEAPON_COMPACTRIFLE
        "-1654528753": "Bullpup Rifle Mk II", // WEAPON_BULLPUPRIFLE2
        "961495388": "Assault Shotgun", // WEAPON_ASSAULTSHOTGUN
        "-494615257": "Assault SMG", // WEAPON_ASSAULTSMG
        "-1121678507": "Mini SMG", // WEAPON_MINISMG
        "-619010992": "Machine Pistol", // WEAPON_MACHINEPISTOL
        "177293209": "Heavy Shotgun", // WEAPON_HEAVYSHOTGUN
        "-952879014": "Marksman Rifle", // WEAPON_MARKSMANRIFLE
        "1785463520": "Marksman Pistol", // WEAPON_MARKSMANPISTOL
        "-1660422300": "MG", // WEAPON_MG
        "2138347493": "RPG", // WEAPON_RPG
        "1119849093": "Minigun", // WEAPON_MINIGUN
        "-1813897027": "Grenade Launcher", // WEAPON_GRENADELAUNCHER
        "741814745": "Sticky Bomb", // WEAPON_STICKYBOMB
        "-37975472": "Smoke Grenade", // WEAPON_SMOKEGRENADE
        "-1600701090": "BZ Gas", // WEAPON_BZGAS
        "615608432": "Molotov", // WEAPON_MOLOTOV
        "101631238": "Fire Extinguisher", // WEAPON_FIREEXTINGUISHER
        "883325847": "Petrol Can", // WEAPON_PETROLCAN
        "1141786504": "Golf Club", // WEAPON_GOLFCLUB
        "-1716189206": "Knife", // WEAPON_KNIFE
        "1317494643": "Nightstick", // WEAPON_NIGHTSTICK
        "-1786099057": "Hammer", // WEAPON_HAMMER
        "-581044007": "Machete", // WEAPON_MACHETE
        "-1951375401": "Flashlight", // WEAPON_FLASHLIGHT
        "-102323637": "Crowbar", // WEAPON_CROWBAR
        "-1716189206": "Dagger", // WEAPON_DAGGER (corrected hash)
        "-102973651": "Hatchet", // WEAPON_HATCHET
        "-656458692": "Knuckle Duster", // WEAPON_KNUCKLE
        "-1239161099": "Switchblade", // WEAPON_SWITCHBLADE
        "-2067956739": "Pool Cue", // WEAPON_POOLCUE
        "28811031": "Parachute", // WEAPON_PARACHUTE
    };

    function getWeaponName(hash: number): string {
        return weaponNames[hash.toString()] || "Unknown Weapon";
    }

    function isLowAmmo(currentAmmo: number): boolean {
        return currentAmmo <= 5; // Consider low ammo when 5 or fewer rounds
    }

    function getWeaponType(hash: number): string {
        const pistols = ["453432689", "1593441988", "-1716589765", "-1076751822", "-771403250", "1785463520", "-619010992"];
        const rifles = ["-1074790547", "-2084633992", "-1357824103", "2132975508", "-1834847097", "1649403952", "-1654528753"];
        const smgs = ["736523883", "171789620", "-494615257", "-1121678507"];
        const shotguns = ["487013001", "2017895192", "-2066285827", "961495388", "177293209"];
        const snipers = ["100416529", "205991906", "-952879014"];
        
        const hashStr = hash.toString();
        
        if (pistols.includes(hashStr)) return "pistol";
        if (rifles.includes(hashStr)) return "rifle";
        if (smgs.includes(hashStr)) return "smg";
        if (shotguns.includes(hashStr)) return "shotgun";
        if (snipers.includes(hashStr)) return "sniper";
        
        return "other";
    }

    function getWeaponIcon(hash: number): string {
        const weaponType = getWeaponType(hash);
        
        switch (weaponType) {
            case "pistol": return "fa-gun";
            case "rifle": return "fa-rifle";
            case "smg": return "fa-gun-squirt";
            case "shotgun": return "fa-shotgun";
            case "sniper": return "fa-crosshairs";
            default: return "fa-gun";
        }
    }

    ReceiveEvent('updateWeapon', (data: {
        showing: boolean, 
        weapon: number, 
        ammo: number, 
        totalAmmo: number, 
        weaponHash: number
    }): void => {
        visible = data.showing;
        weapon = data.weapon;
        ammo = data.ammo;
        totalAmmo = data.totalAmmo;
        weaponHash = data.weaponHash;
    });
</script>

{#if visible}
    <div class="weaponHud" transition:fly={{ x: 200, duration: 300 }}>
        <div class="ammoContainer">
            <div class="ammoCircle">
                <div class="ammoDisplay" class:lowAmmo={isLowAmmo(ammo)}>
                    <span class="clipAmmo">{ammo}</span>
                    <div class="ammoSeparator"></div>
                    <span class="reserveAmmo">{totalAmmo}</span>
                </div>
            </div>
        </div>
        <div class="weaponIconContainer" data-weapon-type={getWeaponType(weaponHash)}>
            <i class="fa-solid {getWeaponIcon(weaponHash)} weaponIcon"></i>
            <div class="weaponName">{getWeaponName(weaponHash)}</div>
        </div>
    </div>
{/if}

<style>
    .weaponHud {
        position: absolute;
        bottom: 12vh;
        right: 2vh;
        display: flex;
        align-items: center;
        gap: 10px;
        font-family: 'Bebas Neue', sans-serif;
    }

    .ammoContainer {
        position: relative;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .ammoCircle {
        width: 60px;
        height: 60px;
        border-radius: 50%;
        background: rgba(0, 0, 0, 0.9);
        display: flex;
        align-items: center;
        justify-content: center;
        backdrop-filter: blur(8px);
    }

    .ammoDisplay {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        text-align: center;
    }

    .clipAmmo {
        color: #00ff41;
        font-size: 20px;
        font-weight: bold;
        line-height: 1;
        text-shadow: 0 0 8px rgba(0, 255, 65, 0.8);
    }

    .ammoSeparator {
        width: 15px;
        height: 1px;
        background: rgba(0, 255, 65, 0.6);
        margin: 1px 0;
    }

    .reserveAmmo {
        color: rgba(0, 255, 65, 0.8);
        font-size: 12px;
        font-weight: bold;
        line-height: 1;
        text-shadow: 0 0 4px rgba(0, 255, 65, 0.6);
    }

    .weaponIconContainer {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 5px;
    }

    .weaponIcon {
        color: #00ff41;
        font-size: 24px;
        text-shadow: 0 0 8px rgba(0, 255, 65, 0.8);
        filter: drop-shadow(0 0 8px rgba(0, 255, 65, 0.4));
    }

    .weaponName {
        color: rgba(0, 255, 65, 0.9);
        font-size: 11px;
        font-weight: bold;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        text-align: center;
        text-shadow: 0 0 4px rgba(0, 255, 65, 0.6);
        max-width: 80px;
        word-wrap: break-word;
    }

    /* Low ammo warning */
    .ammoDisplay.lowAmmo .clipAmmo {
        color: #ff0000;
        animation: lowAmmoFlash 1s ease-in-out infinite alternate;
    }



    @keyframes lowAmmoFlash {
        0% { 
            opacity: 1;
            text-shadow: 0 0 8px rgba(255, 0, 0, 0.8);
        }
        100% { 
            opacity: 0.7;
            text-shadow: 0 0 15px rgba(255, 0, 0, 1);
        }
    }

    /* Responsive adjustments */
    @media (max-width: 1920px) {
        .weaponHud {
            bottom: 11vh;
            right: 1.8vh;
        }
        
        .ammoCircle {
            width: 55px;
            height: 55px;
        }
        
        .clipAmmo {
            font-size: 18px;
        }
    }

    @media (max-width: 1366px) {
        .weaponHud {
            bottom: 10vh;
            right: 1.5vh;
        }
        
        .ammoCircle {
            width: 50px;
            height: 50px;
        }
        
        .clipAmmo {
            font-size: 16px;
        }
        
        .reserveAmmo {
            font-size: 10px;
        }
        
        .weaponIcon {
            font-size: 20px;
        }
        
        .weaponName {
            font-size: 10px;
        }
    }


</style>