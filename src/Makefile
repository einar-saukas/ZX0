CC = owcc
CFLAGS  = -ox -ob -ol+ -onatx -oh -zp8 -fp6 -g0 -Ot -oe -ot -Wall -xc -s -finline-functions -finline-intrinsics -finline-math -floop-optimize -frerun-optimizer -fno-stack-check -march=i386 -mtune=i686
RM = del
EXTENSION = .exe

all: zx0 dzx0

zx0: zx0.c optimize.c compress.c memory.c zx0.h
	$(CC) $(CFLAGS) -o zx0$(EXTENSION) zx0.c optimize.c compress.c memory.c

dzx0: dzx0.c
	$(CC) $(CFLAGS) -o dzx0$(EXTENSION) dzx0.c

clean:
	$(RM) *.obj
