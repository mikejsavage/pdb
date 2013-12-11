An encrypted password store with dmenu integration.


Security
--------

It uses AES-256 in CTR mode to encrypt your database, which is fine and
generates your 256 bit secret key from `/dev/random` and IVs from
urandom, which is also fine.

It prompts you for your password when you are adding it rather than
passing it as a command line argument so people can't grab it from `ps`,
but it doesn't disable console echoing so someone looking over your
shoulder will be able to read your passwords.


Requirements
------------

lua, luafilesystem, luacrypto, lua-cjson for pdb
xdotool, dmenu for pdbmenu


Usage
-----

pdb requires you to put a shared secret on each computer you want to
use the database on, but the database itself can be given to entities
you don't trust (Dropbox, etc) without revealing your passwords.

You need to generate a private key for encrypting your password database
with `pdb genkey`. This should be copied manually between computers you
want to keep the database on and not given to anyone else.

Initialise the database on one of your machines with `pdb init`. You can
then start playing with it (`pdb add`, `pdb list`, etc. type `pdb` by
itself for a full list).

An example session:

	$ pdb genkey
	Generating your private key. Go do something else while we gather entropy.
	>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	Done! You should chmod 700 ~/.pdb/key
	$ pdb init 
	Database initialised.
	$ pdb add test 
	Enter a password for test: fdsa
	$ pdb list 
	test
	$ pdb get test 
	fdsa

pdbmenu pipes `pdb list` to dmenu along with any command line arguments
you gave it, and then `pdb get`s the password you chose and types it for
you.
