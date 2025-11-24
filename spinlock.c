// Mutual exclusion spin locks.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "x86.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
  lk->name = name;
  lk->locked = 0;
  lk->cpu = 0;
}

// Acquire the lock.
// Loops (spins) until the lock is acquired. Holding a lock for a long time 
// may cause other CPUs to waste time spinning to acquire it.
//
// Memory ordering notes: The x86's processor-ordering memory model matches
// spinlocks well. For the pattern:
//   CPU0: A; release(lk);
//   CPU1: acquire(lk); B;
// We need: (1) all reads in B see writes in A, and (2) reads in A don't see
// writes in B. The x86 guarantees writes in A reach memory before the write
// of lk->locked=0 in release(), and CPU1 observes the unlock only after
// observing earlier writes. So reads in B see effects of A.
//
// For condition (2), the Intel spec requires a serialization instruction in
// release() to prevent reads in A from moving after the unlock. No existing
// Intel SMP processor actually reorders reads after writes, but the spec 
// allows it, so future processors might need explicit barriers.
void
acquire(struct spinlock *lk)
{
  pushcli(); // disable interrupts to avoid deadlock.
  if(holding(lk))
    panic("acquire");

  // The xchg is atomic.
  while(xchg(&lk->locked, 1) != 0)
    ;

  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that the critical section's memory
  // references happen after the lock is acquired. (see above)
  __sync_synchronize();

  // Record info about lock acquisition for debugging.
  lk->cpu = mycpu();
  getcallerpcs(&lk, lk->pcs);
}

// Release the lock.
void
release(struct spinlock *lk)
{
  if(!holding(lk))
    panic("release");

  lk->pcs[0] = 0;
  lk->cpu = 0;

  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that all the stores in the critical
  // section are visible to other cores before the lock is released.
  // Both the C compiler and the hardware may re-order loads and
  // stores; __sync_synchronize() tells them both not to.
  __sync_synchronize();

  // Release the lock, equivalent to lk->locked = 0.
  // This code can't use a C assignment, since it might
  // not be atomic. A real OS would use C atomics here.
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );

  popcli();
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
    pcs[i] = 0;
}

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
  int r;
  pushcli();
  r = lock->locked && lock->cpu == mycpu();
  popcli();
  return r;
}

// Pushcli/popcli are like cli/sti except that they are matched:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
  int eflags;

  eflags = readeflags();
  // WARN: Must call cli() BEFORE accessing mycpu()->ncli. If interrupts are 
  // enabled, we could read mycpu(), get rescheduled to a different CPU, then 
  // incorrectly increment the old CPU's ncli counter. By disabling interrupts 
  // first, we guarantee we stay on the same CPU for the entire critical section.
  //
  // NOTE: There is a harmless race condition here. If interrupts are enabled,
  // readeflags() can execute, then the process can be preempted and rescheduled
  // on another CPU (possibly with interrupts disabled). When it resumes, it will
  // record the OLD CPU's interrupt state (enabled). This doesn't matter because
  // if it was safe to run with interrupts enabled before the context switch, it's
  // still safe (and arguably more correct) to run with them enabled afterward.
  cli();
  if(mycpu()->ncli == 0)
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
}

void
popcli(void)
{
  if(readeflags()&FL_IF)
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
    sti();
}

