fx_version 'cerulean'
game "gta5"

name 'ez-hud'
description 'EZ-HUD - Modern HUD System with Qbox Framework, QBX Divegear Integration & Advanced Weapon HUD'
author 'EZ-HUD Team'
version '2.1.0'
lua54 'yes'

repository 'https://github.com/your-repo/ez-hud'

ui_page 'build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/playerdata.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

client_script 'client.lua'

files {
    'build/**',
}

dependency '/assetpacks'
