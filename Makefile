FPC = fpc

FPCFLAGS = -B -Sh -Mobjfpc -vnlw -O2 -Xs -XX -Fu/usr/share/lazarus/4.6.0/components/lazutils/lib/x86_64-linux

TARGETS = tcx_files_extractor

.PHONY: all clean

all: $(TARGETS)

%: %.pas 
	$(FPC) $(FPCFLAGS) $<
	rm -f *.o *.ppu

clean:
	rm -f *.o *.ppu $(TARGETS)
