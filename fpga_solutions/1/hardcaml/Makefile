INSTALL_ARGS := $(if $(PREFIX),--prefix $(PREFIX),)

default:
	dune build

install:
	dune install $(INSTALL_ARGS)

uninstall:
	dune uninstall $(INSTALL_ARGS)

reinstall: uninstall install

clean:
	dune clean

### Added Make Commands ################################
rtl:
	bin/generate.exe range-finder

sim:
	rm -f /tmp/test_coprocessor_ml_Simple_test__optionally_saving_waveforms_to_disk.*
	dune build bin/generate.exe @runtest

hardcaml-waveform:
	hardcaml-waveform-viewer show /tmp/test_coprocessor_ml_Simple_test__optionally_saving_waveforms_to_disk.hardcamlwaveform

gtkwave:
	gtkwave /tmp/test_coprocessor_ml_Simple_test__optionally_saving_waveforms_to_disk.vcd

.PHONY: default install uninstall reinstall clean
