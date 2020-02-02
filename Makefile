%:
	nixops modify -d $(MAKECMDGOALS) systems/$(MAKECMDGOALS).nix
	nixops deploy -d $(MAKECMDGOALS)
