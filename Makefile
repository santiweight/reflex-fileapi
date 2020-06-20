example:
	nix-build example.nix -A ghcjs.reflex-fileapi -o result-reflex-fileapi
	$(BROWSER) ./result-reflex-fileapi/bin/reflex-fileapi-exe.jsexe/index.html
