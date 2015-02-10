pdb: src/*.lua
	lua merge.lua src main.lua > pdb
	chmod +x pdb

clean:
	rm -f pdb
