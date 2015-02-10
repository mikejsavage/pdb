local lfs = require( "lfs" )
local symmetric = require( "symmetric" )
local json = require( "cjson.safe" )

local actions = require( "actions" )

table.unpack = table.unpack or unpack

local default_length = 32
local default_pattern = "[%w%p ]"

local help =
	"Usage: " .. arg[ 0 ] .. " <command>\n"
	.. "where <command> is one of the following:\n"
	.. "\n"
	.. "init          - create a new key file and empty database\n"
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

local dir = os.getenv( "HOME" ) .. "/.pdb/"
local paths = { db = dir .. "db2", key = dir .. "key2" }

local function load_key()
	local file, err = io.open( paths.key, "r" )
	if not file then
		io.stderr:write( "Unable to open key file: " .. err .. "\n" )
		io.stderr:write( "You might need to create it with `pdb init`.\n" )
		return os.exit( 1 )
	end

	local key = assert( file:read( "*all" ) ) -- TODO
	file:close()

	return key
end

local function load_db( key )
	local file, err = io.open( paths.db, "r" )
	if not file then
		io.stderr:write( "Unable to open DB: " .. err .. "\n" )
		io.stderr:write( "You might need to create it with `pdb init`.\n" )
		return os.exit( 1 )
	end

	local ciphertext = assert( file:read( "*all" ) ) -- TODO
	local plaintext = symmetric.decrypt( ciphertext, key )
	if not plaintext then
		io.stderr:write( "DB does not decrypt with the given key.\n" )
		return os.exit( 1 )
	end

	local db = json.decode( plaintext )
	if not db then
		io.stderr:write( "DB does not appear to be in JSON format.\n" )
		return os.exit( 1 )
	end
	
	return db
end

-- TODO: write to db2 and os.rename
local function write_db( db, key )
	local plaintext = assert( json.encode( db ) )
	local ciphertext = symmetric.encrypt( plaintext, key )

	local file, err = io.open( paths.db, "w" )
	if not file then
		io.stderr:write( "Could not open DB for writing: " .. err .. "\n" )
		return os.exit( 1 )
	end

	file:write( ciphertext )
	-- TODO
	local ok = assert( file:close() )
end

local function write_new_key()
	local key = symmetric.key()

	local file, err = io.open( paths.key, "w" )
	if not file then
		io.stderr:write( "Unable to open key file for writing: " .. err .. "\n" )
		return os.exit( 1 )
	end

	assert( file:write( key ) )
	assert( file:close() )

	return key
end

-- real code starts here

local commands = {
	add = {
		args = 1,
		syntax = "<name>",
		rewrite = true,
	},
	get = {
		args = 1,
		syntax = "<name>",
	},
	delete = {
		args = 1,
		syntax = "<name>",
		rewrite = true,
	},
	list = {
		args = 0,
	},
	touch = {
		args = 0,
		rewrite = true,
	},
	gen = {
		args = 3,
		syntax = "<name> [length] [pattern]",
		rewrite = true,
	},
}

local cmd = arg[ 1 ]
table.remove( arg, 1 )

if not cmd then
	print( help )
	
	return os.exit( 0 )
end

if cmd == "init" then
	local file_key = io.open( paths.key, "r" )
	local file_db = io.open( paths.db, "r" )

	if file_key or file_db then
		io.stderr:write( "Your key file/DB already exists. Remove them and run init again if you're sure about this.\n" )
		return os.exit( 1 )
	end

	lfs.mkdir( dir )

	local key = write_new_key()
	write_db( { }, key )

	return os.exit( 0 )
end

local key = load_key()
local db = load_db( key )

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
	io.stderr:write( help .. "\n" )
	return os.exit( 1 )
end

if commands[ cmd ].args ~= #arg then
	io.stderr:write( "Usage: " .. arg[ 0 ] .. " " .. cmd .. " " .. ( commands[ cmd ].syntax or "" ) .. "\n" )
	return os.exit( 1 )
end

local err = actions[ cmd ]( db, table.unpack( arg ) )

if err then
	io.stderr:write( err .. "\n" )
	return os.exit( 1 )
end

if commands[ cmd ] then
	write_db( db, key )
end
