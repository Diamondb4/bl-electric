fx_version 'cerulean'
game 'gta5'

description 'bl-electric'
version '1.0.0'

shared_script {
    '@ox_lib/init.lua',
    'config.lua',
    '@qbx_core/modules/lib.lua'
}

server_scripts {
    'server/*',
    'sv_config.lua',
}

client_scripts {
    'client/*'
}

escrow_ignore {
    'config.lua',
    'sv_config.lua',
    'shared/*'
}

lua54 'yes'
use_fxv2_oal 'yes'


