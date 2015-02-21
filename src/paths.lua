local _M = { }

local path = os.getenv( "HOME" ) .. "/.pdb/"

_M.path = path
_M.db = path .. "passwords/"
_M.key = path .. "key2"

return _M
