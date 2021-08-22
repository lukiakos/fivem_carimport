fx_version 'adamant'
game 'common'

name 'sacra_carimport'
description 'Sacra Car autóimport script'
author 'alukas'
version '0.1'

server_scripts {
	'@async/async.lua',
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
    'config.lua',
    'server/main.lua'
}

client_scripts { 
    '@mysql-async/lib/MySQL.lua',
    'config.lua',
    'client/main.lua'
}