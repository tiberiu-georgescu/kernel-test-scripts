CC=gcc
CFLAGS=-I.

SDIR=src
ODIR=obj

SOURCES := $(wildcard $(SDIR)/*.c)
OBJECTS := $(patsubst $(SDIR)/%.c, $(ODIR)/%.o, $(SOURCES))
PROGS := $(patsubst $(SDIR)/%.c, %, $(SOURCES))

all: $(PROGS)

%: $(ODIR)/%.o
	$(CC) $< -o $@

$(ODIR)/%.o: $(SDIR)/%.c
	$(CC) -c $< -o $@ $(CFLAGS)

test_nested: $(PROGS)
	scp $(PROGS) root@10.53.111.6:~/test

.PHONY: clean

clean:
	rm -f $(PROGS) $(OBJECTS) *~ core
