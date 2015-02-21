local lfs = require( "lfs" )
local symmetric = require( "symmetric" )
local json = require( "cjson" )

local dir = os.getenv( "HOME" ) .. "/.pdb/"
local paths = {
	old_db = dir .. "db2",
	key = dir .. "key2",
	new_db = dir .. "passwords/",
}

lfs.mkdir( paths.new_db )

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
	local file, err = io.open( paths.old_db, "r" )
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

local key = load_key()
local db = load_db( key )

for k, v in pairs( db ) do
	local file = io.open( paths.new_db .. k, "w" )
	file:write( symmetric.encrypt( v, key ) )
	file:close()
end
