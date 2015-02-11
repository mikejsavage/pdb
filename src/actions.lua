local arc4 = require( "arc4random" )

local _M = { }

function _M.get( db, name )
	if not db[ name ] then
		return "No such password."
	end

	io.stdout:write( db[ name ] .. "\n" )
end

function _M.add( db, name )
	if db[ name ] then
		return "That password is already in the DB."
	end

	io.stdout:write( "Enter a password for " .. name .. ": " )
	io.stdout:flush()

	local password = assert( io.stdin:read( "*l" ) ) -- TODO

	db[ name ] = password
end

function _M.delete( db, name )
	if not db[ name ] then
		return "No such password."
	end

	db[ name ] = nil
end

function _M.list( db )
	local names = { }

	for name in pairs( db ) do
		table.insert( names, name )
	end
	table.sort( names )

	for _, name in ipairs( names ) do
		print( name )
	end
end

function _M.touch( db )
end

function _M.gen( db, name, length, pattern )
	if db[ name ] then
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

	db[ name ] = password
end

return _M
