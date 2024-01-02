#include "syscall.h"
#include "traps.h"

.global fork
fork:
    movl $SYS_fork,%eax
    int $T_SYSCALL
    ret

.global exit
exit:
    movl $SYS_exit,%eax
    int $T_SYSCALL
    ret

.global wait
wait:
    movl $SYS_wait,%eax
    int $T_SYSCALL
    ret

.global pipe
pipe:
    movl $SYS_pipe,%eax
    int $T_SYSCALL
    ret

.global read
read:
    movl $SYS_read,%eax
    int $T_SYSCALL
    ret

.global write
write:
    movl $SYS_write,%eax
    int $T_SYSCALL
    ret

.global close
close:
    movl $SYS_close,%eax
    int $T_SYSCALL
    ret

.global kill
kill:
    movl $SYS_kill,%eax
    int $T_SYSCALL
    ret

.global exec
exec:
    movl $SYS_exec,%eax
    int $T_SYSCALL
    ret

.global open
open:
    movl $SYS_open,%eax
    int $T_SYSCALL
    ret

.global mknod
mknod:
    movl $SYS_mknod,%eax
    int $T_SYSCALL
    ret

.global unlink
unlink:
    movl $SYS_unlink,%eax
    int $T_SYSCALL
    ret

.global fstat
fstat:
    movl $SYS_fstat,%eax
    int $T_SYSCALL
    ret

.global link
link:
    movl $SYS_link,%eax
    int $T_SYSCALL
    ret

.global mkdir
mkdir:
    movl $SYS_mkdir,%eax
    int $T_SYSCALL
    ret

.global chdir
chdir:
    movl $SYS_chdir,%eax
    int $T_SYSCALL
    ret

.global dup
dup:
    movl $SYS_dup,%eax
    int $T_SYSCALL
    ret

.global getpid
getpid:
    movl $SYS_getpid,%eax
    int $T_SYSCALL
    ret

.global sbrk
sbrk:
    movl $SYS_sbrk,%eax
    int $T_SYSCALL
    ret

.global sleep
sleep:
    movl $SYS_sleep,%eax
    int $T_SYSCALL
    ret

.global uptime
uptime:
    movl $SYS_uptime,%eax
    int $T_SYSCALL
    ret
