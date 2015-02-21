local crypto = require( "crypto" )
local symmetric = require( "symmetric" )
local json = require( "cjson" )

local Cipher = "aes-256-ctr"
local Hash = "sha256"
local HMAC = "sha256"

local KeyLength = 32
local IVLength = 16
local HMACLength = 32

local SplitCipherTextPattern = "^(" .. string.rep( ".", IVLength ) .. ")(.+)(" .. string.rep( ".", HMACLength ) .. ")$"

local dir = os.getenv( "HOME" ) .. "/.pdb/"
local paths = {
	old_db = dir .. "db",
	old_key = dir .. "key",
	new_db = dir .. "db2",
	new_key = dir .. "key2",
}

function io.readable( path )
	local file = io.open( path, "r" )

	if file then
		file:close()
		return true
	end

	return false
end

local function load_old_key()
	local file = assert( io.open( paths.old_key, "r" ) )

	local key = file:read( "*all" )
	assert( key:len() == KeyLength, "bad key file" )

	assert( file:close() )

	return key
end

local function load_old_db( key )
	local file = assert( io.open( paths.old_db, "r" ) )

	local contents = assert( file:read( "*all" ) )
	assert( file:close() )

	local iv, c, hmac = contents:match( SplitCipherTextPattern ) 
	assert( iv, "Corrupt DB" )

	local key2 = crypto.digest( Hash, key )
	assert( hmac == crypto.hmac.digest( HMAC, c, key2, true ), "Corrupt DB" )

	local m = crypto.decrypt( Cipher, c, key, iv )

	return assert( json.decode( m ) )
end

local function write_new_key()
	local key = symmetric.key()

	local file, err = io.open( paths.new_key, "w" )
	if not file then
		io.stderr:write( "Unable to open key file for writing: " .. err .. "\n" )
		return os.exit( 1 )
	end

	assert( file:write( key ) )
	assert( file:close() )

	return key
end

local function write_db( db, key )
	local plaintext = assert( json.encode( db ) )
	local ciphertext = symmetric.encrypt( plaintext, key )

	local file, err = io.open( paths.new_db, "w" )
	if not file then
		io.stderr:write( "Could not open DB for writing: " .. err .. "\n" )
		return os.exit( 1 )
	end

	file:write( ciphertext )
	local ok = assert( file:close() )
end

if io.readable( paths.new_key ) or io.readable( paths.new_db ) then
	io.stderr:write( "You already have a key/DB in the new format!\n" )
	return os.exit( 1 )
end

local db = load_old_db( load_old_key() )

local key = write_new_key()
write_db( db, key )
