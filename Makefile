FPC = fpc

FPCFLAGS = -B -Sh -Mobjfpc -vnlw -O2 -Xs -XX 

TARGETS = tcx_files_extractor

.PHONY: all clean

all: $(TARGETS)

%: %.pas 
	$(FPC) $(FPCFLAGS) $<
	rm -f *.o *.ppu

clean:
	rm -f *.o *.ppu $(TARGETS)
