// Physical memory allocator, intended to allocate memory for user 
// processes, kernel stacks, page table pages, and pipe buffers. 
// Allocates 4096-byte pages.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "spinlock.h"

extern char end[]; // first address after kernel loaded from ELF file
                   // defined by the kernel linker script in kernel.ld

struct {
  struct spinlock lock;
  int use_lock;
  char *freelist;
} kmem;

static void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
    kfree(p);
}

// Initialization happens in two phases.
// 1. main() calls kinit1() while still using entrypgdir to place just
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
  initlock(&kmem.lock, "kmem");
  kmem.use_lock = 0;
  freerange(vstart, vend);
}

void
kinit2(void *vstart, void *vend)
{
  freerange(vstart, vend);
  kmem.use_lock = 1;
}

// Free the page of physical memory pointed at by v, which normally should 
// have been returned by a call to kalloc(). (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);

  if(kmem.use_lock)
    acquire(&kmem.lock);
  *(char **)v = kmem.freelist;
  kmem.freelist = v;
  if(kmem.use_lock)
    release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory. Returns a pointer that 
// the kernel can use. Returns 0 if a page is not available.
char*
kalloc(void)
{
  if(kmem.use_lock)
    acquire(&kmem.lock);
  char *r = kmem.freelist;
  if(r)
    kmem.freelist = *(char **)r;
  if(kmem.use_lock)
    release(&kmem.lock);
  return r;
}

// Return the number of free pages available.
int kpages()
{
  if(kmem.use_lock)
    acquire(&kmem.lock);
  char *r = kmem.freelist;
  int pages = 0;
  while(r) {
    r = *(char **)r;
    pages++;
  }
  if(kmem.use_lock)
    release(&kmem.lock);
  return pages;
}
