An encrypted password store with dmenu integration.


Security
--------

pdb uses lua-symmetric, which uses libsodium's secretbox to secure your
passwords. It also uses lua-arc4random, which uses `arc4random` pulled
from LibreSSL for generating passwords.

It prompts you for your password when you are adding it rather than
passing it as a command line argument so people can't grab it from `ps`,
but it doesn't disable console echoing so someone looking over your
shoulder can obviously see what you type.


Requirements
------------

[arc4]: https://github.com/mikejsavage/lua-arc4random
[symmetric]: https://github.com/mikejsavage/lua-symmetric

lua, [lua-arc4random][arc4], [lua-symmetric][symmetric], lua-cjson  
Additionally: xdotool, dmenu for pdbmenu


Upgrading
---------

As of 10th Feb 2015 (commit `22ef6c142d`), pdb uses a new database
format. I have included a utility to update an existing password
database, which you can run with `lua update-old-db.lua`. Note that it
also generates a new secret key.


Usage
-----

pdb requires you to put a shared secret on each computer you want to
use the database on, but the database itself can be given to entities
you don't trust (Dropbox, etc) without revealing your passwords.

Initialise the database on one of your machines with `pdb init`. You can
then start playing with it (`pdb add`, `pdb list`, etc. run `pdb` by
itself for a full list).

An example session:

	$ pdb init
	Initialized empty password db in /home/mike/.pdb/
	You should chmod 600 /home/mike/.pdb/key2
	$ pdb add test 
	Enter a password for test: fdsa
	$ pdb gen test2
	$ pdb list 
	test
	test2
	$ pdb get test
	fdsa
	$ pdb get test2
	)"QI p!8j.c9g!yQ:d8Dc9XdHKWqKz\"

pdbmenu pipes `pdb list` to dmenu along with any command line arguments
you gave it, and then `pdb get`s the password you chose and types it for
you.
