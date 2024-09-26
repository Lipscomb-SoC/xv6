MAKEFLAGS += --no-builtin-rules
CFLAGS = -static -Og -Wall -MD -g -m32 -Werror -DXV6 -no-pie
CFLAGS += -fno-pic -fno-builtin -fno-strict-aliasing -fno-stack-protector -fno-omit-frame-pointer -fno-pie 
LDFLAGS += -m elf_i386

all: fs.img xv6.img

.PRECIOUS: %.o
-include *.d

%.o: %.c
	gcc $(CFLAGS) -c $<

%.o: %.S
	gcc $(CFLAGS) -c $<

## OS disk image (primary target)

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
# TODO separate OS from user programs (use directories)

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
	_layout\
	_cpu\
	_mem\
	_batch\

_%: %.o userlib.a
	ld $(LDFLAGS) -N -e main -Ttext 0 -o $@ $^

## file system disk image

fs.img: mkfs README $(UPROGS)
	./mkfs fs.img README batch.txt $(UPROGS)

mkfs: mkfs.c fs.h
	gcc -Werror -Wall -o $@ $<

## clean up the junk

clean: 
	rm -f *.o *.d *.a *.zip *.img _* *.gch vectors.S bootblock entryother initcode initcode.out kernel signbb mkfs .gdbinit

## submission

submission: 
	make -s clean
	zip -9qjX xv6.zip *

## emulate and debug

QEMU = qemu-system-i386
QEMUOPTS = -nographic -drive file=fs.img,index=1,media=disk,format=raw -drive file=xv6.img,index=0,media=disk,format=raw -smp 2 -m 512 -net none

qemu: fs.img xv6.img
	$(QEMU) $(QEMUOPTS)

.gdbinit: .gdbinit.tmpl
	sed "s/localhost:1234/localhost:27777/" < $< > $@

qemu-gdb: fs.img xv6.img .gdbinit
	@echo "*** Now run 'gdb'."
	$(QEMU) $(QEMUOPTS) -S -gdb tcp::27777
