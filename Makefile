
BYTE_COMPILE = emacs -Q --batch -f batch-byte-compile
ELS = init.el early-init.el
ELCS = $(ELS:.el=.elc)

all: build

.el.elc:
	-echo "compile:" $<
	$(BYTE_COMPILE) $<

%.elc: %.el
	-echo "compile:" $<
	$(BYTE_COMPILE) $<

.PHONY: build
build: $(ELCS)

.PHONY: clean
clean:
	rm -f $(ELCS) *~

