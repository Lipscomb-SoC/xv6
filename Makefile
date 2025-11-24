MAKEFLAGS += --no-builtin-rules
CFLAGS = -m32 -static -Og -g -MD -DXV6
CFLAGS += -Wall -Werror -Wno-infinite-recursion
CFLAGS += -fno-pic -fno-pie -fno-builtin -fno-stack-protector -fno-strict-aliasing -fno-omit-frame-pointer -fno-asynchronous-unwind-tables
LDFLAGS += -m elf_i386

## ld 2.42 (Ubuntu 24) is more picky about security, we must disable some warnings
ifeq "$(shell if [ `ld -v|cut -d. -f2` -ge 42 ]; then echo true; fi)" "true"
LDFLAGS += --no-warn-execstack --no-warn-rwx-segments
endif

all: fs.img xv6.img

.PRECIOUS: %.o
-include *.d

%.o: %.c
	gcc $(CFLAGS) -c $<

%.o: %.S
	gcc $(CFLAGS) -c $<

## OS disk image

xv6.img: bootblock kernel
	dd if=/dev/zero of=xv6.img count=10000
	dd if=bootblock of=xv6.img conv=notrunc
	dd if=kernel of=xv6.img seek=1 conv=notrunc

bootblock: bootasm.S bootmain.c signbb
	gcc $(CFLAGS) -O -nostdinc -I. -c bootmain.c
	gcc $(CFLAGS) -nostdinc -I. -c bootasm.S
	ld $(LDFLAGS) -N -e start -Ttext 0x7C00 -o bootblock.o bootasm.o bootmain.o
	objcopy -S -O binary -j .text bootblock.o bootblock
	./signbb bootblock

entryother: entryother.S
	gcc $(CFLAGS) -nostdinc -I. -c entryother.S
	ld $(LDFLAGS) -N -e start -Ttext 0x7000 -o bootblockother.o entryother.o
	objcopy -S -O binary -j .text bootblockother.o entryother

initcode: initcode.S
	gcc $(CFLAGS) -nostdinc -I. -c initcode.S
	ld $(LDFLAGS) -N -e start -Ttext 0 -o initcode.out initcode.o
	objcopy -S -O binary initcode.out initcode

signbb: signbb.c
	gcc -Werror -Wall -o $@ $<

vectors.S: vectors.py
	python3 vectors.py > vectors.S

OBJS = \
	bio.o\
	console.o\
	exec.o\
	file.o\
	fs.o\
	ide.o\
	ioapic.o\
	kalloc.o\
	kbd.o\
	lapic.o\
	log.o\
	main.o\
	mp.o\
	picirq.o\
	pipe.o\
	proc.o\
	sleeplock.o\
	spinlock.o\
	string.o\
	swtch.o\
	syscall.o\
	sysfile.o\
	sysproc.o\
	trapasm.o\
	trap.o\
	uart.o\
	vectors.o\
	vm.o\

kernel: $(OBJS) entry.o entryother initcode kernel.ld
	ld $(LDFLAGS) -T kernel.ld -o kernel entry.o $(OBJS) -b binary initcode entryother

## user-space library

userlib.a: ulib.o usys.o printf.o umalloc.o
	ar cr $@ $^

## user-space programs

UPROGS=\
	_cat\
	_echo\
	_forktest\
	_grep\
	_init\
	_kill\
	_ln\
	_ls\
	_mkdir\
	_rm\
	_sh\
	_usertests\
	_wc\
	_zombie

_%: %.o userlib.a
	ld $(LDFLAGS) -T user.ld -n -o $@ $^

## file system disk image

fs.img: mkfs README $(UPROGS)
	./mkfs fs.img README $(UPROGS)

mkfs: mkfs.c fs.h
	gcc -Werror -Wall -o $@ $<

## clean up the junk

clean: 
	rm -f *.o *.d *.a *.zip *.img _* *.gch vectors.S bootblock entryother initcode initcode.out kernel signbb mkfs

## submission

submission: 
	make -s clean
	zip -9qjX xv6.zip *

## emulate and debug

QEMU = qemu-system-i386
QEMUOPTS = -nographic -drive file=fs.img,index=1,media=disk,format=raw -drive file=xv6.img,index=0,media=disk,format=raw -smp 2 -m 512 -net none

qemu: fs.img xv6.img
	$(QEMU) $(QEMUOPTS)

qemu-gdb: fs.img xv6.img .gdbinit
	@echo "*** Now run 'gdb'."
	$(QEMU) $(QEMUOPTS) -S -gdb tcp::27777
