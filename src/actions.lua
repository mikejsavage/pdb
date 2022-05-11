local symmetric = require( "symmetric" )
local arc4 = require( "arc4random" )

local paths = require( "paths" )

local _M = { }

function _M.get( key, path )
	local ciphertext = io.readfile( path )
	if not ciphertext then
		return "No such password."
	end

	local password, err = symmetric.decrypt( ciphertext, key )
	if not password then
		return err
	end

	print( password )
end

function _M.add( key, path )
	if io.readfile( path ) then
		return "That password is already in the DB."
	end

	io.stdout:write( "Enter a password: " )
	io.stdout:flush()

	local password = assert( io.stdin:read( "*l" ) ) -- TODO
	local ciphertext = symmetric.encrypt( password, key )

	local _, err = io.writefile( path, ciphertext )
	return err
end

function _M.delete( _, path )
	local ok, err = os.remove( path )
	return err
end

function _M.list()
	local names = { }
	for file in lfs.dir( paths.db ) do
		if file ~= "." and file ~= ".." and not file:match( "^%.git" ) then
			table.insert( names, file )
		end
	end
	table.sort( names )

	print( table.concat( names, "\n" ) )
end

function _M.gen( key, path, length, pattern )
	if io.readfile( path ) then
		return "That password is already in the DB."
	end

	local allowed_chars = { }
	for i = 0, 255 do
		if string.char( i ):match( pattern ) then
			table.insert( allowed_chars, string.char( i ) )
		end
	end
	if #allowed_chars == 0 then
		return "Nothing matches given pattern."
	end

	local password = ""
	for i = 1, length do
		local c = allowed_chars[ arc4.random( 1, #allowed_chars ) ]
		password = password .. c
	end
	local ciphertext = symmetric.encrypt( password, key )

	local _, err = io.writefile( path, ciphertext )
	return err
end

return _M
