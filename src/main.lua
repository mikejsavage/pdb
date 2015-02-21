local lfs = require( "lfs" )
local symmetric = require( "symmetric" )

local actions = require( "actions" )
local paths = require( "paths" )

function io.readfile( path )
	local file, err = io.open( path, "r" )
	if not file then
		return nil, err
	end

	local contents, err = file:read( "*all" )
	file:close()
	return contents, err
end

function io.writefile( path, contents )
	local file, err = io.open( path, "w" )
	if not file then
		return nil, err
	end

	local ok, err = file:write( contents )
	if not ok then
		file:close()
		return nil, err
	end

	local ok, err = file:close()
	if not ok then
		return nil, err
	end

	return true
end

table.unpack = table.unpack or unpack

local default_length = 32
local default_pattern = "[%w%p ]"

local function eprintf( form, ... )
	io.stderr:write( form:format( ... ) .. "\n" )
end

local help =
	"Usage: " .. arg[ 0 ] .. " <command>\n"
	.. "where <command> is one of the following:\n"
	.. "\n"
	.. "init          - create a new key\n"
	.. "add <name>    - prompt you to enter a password for <name>\n"
	.. "get <name>    - print the password stored under <name>\n"
	.. "delete <name> - delete the password stored under <name>\n"
	.. "list          - list stored passwords\n"
	.. "gen <name> [length] [pattern] - generate a password for <name>\n"
	.. "[pattern] is a Lua pattern. Some examples:\n"
	.. "    gen test       - 32 characters, alphanumeric/puntuation/spaces\n"
	.. "    gen test 16    - 16 characters, alphanumeric/puntuation/spaces\n"
	.. "    gen test 10 %d - 10 characters, numbers only\n"
	.. "    gen test \"%l \" - 32 characters, lowercase/spaces"

local function load_key()
	local key, err = io.readfile( paths.key )
	if not key then
		eprintf( "Unable to read key file: %s", err )
		eprintf( "You might need to create it with `pdb init`." )
		return os.exit( 1 )
	end

	return key
end

local function write_new_key()
	local key = symmetric.key()

	local ok, err = io.writefile( paths.key, key )
	if not ok then
		eprintf( "Unable to open key file for writing: %s", err )
		return os.exit( 1 )
	end

	return key
end

local commands = {
	add = {
		args = 1,
		syntax = "<name>",
	},
	get = {
		args = 1,
	},
	delete = {
		args = 1,
		syntax = "<name>",
	},
	list = {
		args = 0,
	},
	gen = {
		args = 3,
		syntax = "<name> [length] [pattern]",
	},
}

local cmd = arg[ 1 ]
table.remove( arg, 1 )

if not cmd then
	print( help )
	
	return os.exit( 0 )
end

if cmd == "init" then
	if io.open( paths.key, "r" ) then
		eprintf( "Your key file already exists. Remove it and run init again if you're sure about this." )
		return os.exit( 1 )
	end

	lfs.mkdir( dir )
	lfs.mkdir( paths.db )

	local key = write_new_key()
	write_db( { }, key )

	return os.exit( 0 )
end

local key = load_key()

if cmd == "gen" and #arg > 0 then
	local length
	local pattern

	if #arg == 1 then
		length = default_length
		pattern = default_pattern
	elseif #arg == 3 then
		length = tonumber( arg[ 2 ] )
		pattern = "[" .. arg[ 3 ] .. "]"
	else
		length = tonumber( arg[ 2 ] ) or default_length
		pattern = tonumber( arg[ 2 ] ) and default_pattern or arg[ 2 ]
	end

	arg[ 2 ] = length
	arg[ 3 ] = pattern
end

if not actions[ cmd ] then
	eprintf( "%s", help )
	return os.exit( 1 )
end

if commands[ cmd ].args > 0 then
	if arg[ 1 ]:find( "/" ) then
		eprintf( "Password name can't contain slashes." )
		return os.exit( 1 )
	end

	arg[ 1 ] = paths.db .. arg[ 1 ]
end

if commands[ cmd ].args ~= #arg then
	eprintf( "Usage: %s %s %s", arg[ 0 ], cmd, commands[ cmd ].syntax or "" )
	return os.exit( 1 )
end

local err = actions[ cmd ]( key, table.unpack( arg ) )

if err then
	eprintf( "%s", err )
	return os.exit( 1 )
end
