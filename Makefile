# On Max OS X (or others?) try one of these settings:
# TOOLPREFIX = i386-jos-elf-
# TOOLPREFIX = i386-elf-
TOOLPREFIX = 

QEMU = qemu-system-i386
CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)gas
AR = $(TOOLPREFIX)ar
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
CFLAGS = -static -Og -Wall -MD -g -m32 -Werror -DXV6 -no-pie
CFLAGS += -fno-pic -fno-builtin -fno-strict-aliasing -fno-stack-protector -fno-omit-frame-pointer -fno-pie 
ASFLAGS = -m32 -gdwarf-2 -Wa,-divide
LDFLAGS += -m elf_i386

.PRECIOUS: %.o
-include *.d

## OS disk image (primary target)

xv6.img: bootblock kernel
	dd if=/dev/zero of=xv6.img count=10000
	dd if=bootblock of=xv6.img conv=notrunc
	dd if=kernel of=xv6.img seek=1 conv=notrunc

bootblock: bootasm.S bootmain.c
	$(CC) $(CFLAGS) -fno-pic -O -nostdinc -I. -c bootmain.c
	$(CC) $(CFLAGS) -fno-pic -nostdinc -I. -c bootasm.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o bootblock.o bootasm.o bootmain.o
	$(OBJCOPY) -S -O binary -j .text bootblock.o bootblock
	./sign.pl bootblock

entryother: entryother.S
	$(CC) $(CFLAGS) -fno-pic -nostdinc -I. -c entryother.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7000 -o bootblockother.o entryother.o
	$(OBJCOPY) -S -O binary -j .text bootblockother.o entryother

initcode: initcode.S
	$(CC) $(CFLAGS) -nostdinc -I. -c initcode.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0 -o initcode.out initcode.o
	$(OBJCOPY) -S -O binary initcode.out initcode

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
	$(LD) $(LDFLAGS) -T kernel.ld -o kernel entry.o $(OBJS) -b binary initcode entryother

## user-space library

vectors.S: vectors.pl
	./vectors.pl > vectors.S

userlib.a: ulib.o usys.o printf.o umalloc.o
	$(AR) cr $@ $^

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
	_zombie\

_%: %.o userlib.a
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o $@ $^

## file system disk image

fs.img: mkfs README $(UPROGS)
	./mkfs fs.img README $(UPROGS)

mkfs: mkfs.c fs.h
	gcc -Werror -Wall -o mkfs mkfs.c

## clean up the junk

clean: 
	rm -f *.o *.d *.a *.zip *.img _* vectors.S bootblock entryother initcode initcode.out kernel mkfs .gdbinit

## submission

submission: 
	make -s clean
	zip -9qjX xv6.zip *

## emulate and debug

QEMUOPTS = -nographic -drive file=fs.img,index=1,media=disk,format=raw -drive file=xv6.img,index=0,media=disk,format=raw -smp 2 -m 512 -net none

qemu: fs.img xv6.img
	$(QEMU) $(QEMUOPTS)

.gdbinit: .gdbinit.tmpl
	sed "s/localhost:1234/localhost:27777/" < $^ > $@

qemu-gdb: fs.img xv6.img .gdbinit
	@echo "*** Now run 'gdb'."
	$(QEMU) $(QEMUOPTS) -S -gdb tcp::27777
