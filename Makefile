%:
	nixops modify -d $(MAKECMDGOALS) systems/$(MAKECMDGOALS).nix
	nixops deploy -d $(MAKECMDGOALS)
ifeq ($(MAKECMDGOALS),temeraire)
	systemctl --user start libvirt-import.service
endif
