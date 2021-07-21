#define _GNU_SOURCE
#include <unistd.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <linux/memfd.h>
#include <sys/syscall.h>
#include <errno.h>
#include <fcntl.h>

#define PAGES_PER_VADDR 256

int error_check(unsigned long flags, int fd);
int set_options(int argc, char **argv, unsigned long *flags, int *fd,
		int *pages_per_vaddr, bool *wait_forever);

int main(int argc, char **argv) {
  int fd = -1;
  unsigned long flags = 0;
  size_t pagesize = getpagesize();
  pid_t pid = getpid();
  char* vaddr = NULL;
  int pages_per_vaddr = PAGES_PER_VADDR;
  bool wait_forever = false;
  int ret = 0;

  ret = set_options(argc, argv, &flags, &fd, &pages_per_vaddr, &wait_forever);
  if (ret != 0) {
    return ret;
  }
  ret = error_check(flags, fd);
  if (ret != 0) {
    return ret;
  }

  printf("System page size: %zu bytes\n", pagesize);
  printf("Pages per vaddr = %d\n", pages_per_vaddr);
  printf("Own pid: %d\n", pid);
  printf("File Descriptor: %d\n", fd);

  vaddr = mmap(NULL, pagesize * pages_per_vaddr, PROT_READ | PROT_WRITE,
                               flags, fd, 0);
  size_t i;
  for (i = 0; i < pages_per_vaddr; i++) {
    if (i != 5) {
      vaddr[i * pagesize] = i;
    }
  }

  printf("Virtual Address: 0x%lx\n", (unsigned long)vaddr);

  if (wait_forever > 0) {
    for (;;) pause();
  } else {
    getchar();
  }
  munmap(vaddr, pagesize * pages_per_vaddr);
}

int set_options(int argc, char **argv, unsigned long *flags, int *fd,
		int *pages_per_vaddr, bool *wait_forever) {
  int option;
  size_t pagesize = getpagesize();

  while ((option = getopt(argc, argv, "apsmf:c:t")) != -1) {
    switch (option) {
      case 'a':
        *flags |= MAP_ANONYMOUS;
        break;
      case 's':
        *flags |= MAP_SHARED;
        break;
      case 'p':
        *flags |= MAP_PRIVATE;
        break;
      case 'm':
        *fd = syscall(SYS_memfd_create, "tibi_memfd", MFD_ALLOW_SEALING);
	if (*fd == -1) {
          perror("memfd failed to create fd");
          goto error;
	}
        break;
      case 'f':
        *fd = open(optarg, O_RDWR);
	if (*fd == -1) {
	  fprintf(stderr, "%s not found\n", optarg);
          goto error;
	}
        break;
      case 'c':
        *pages_per_vaddr = atoi(optarg);
        break;
      case 't':
        *wait_forever = true;
        break;
    }
  }

  if (*fd != -1) {
    ftruncate(*fd, pagesize * (*pages_per_vaddr));
  }

  return 0;

error:
  return -1;
}

int error_check(unsigned long flags, int fd) {
  if (flags & MAP_ANONYMOUS && fd != -1) {
    fprintf(stderr, "Not possible for fd=%d on an annonymous mapping\n", fd);
    return -1;
  }

  printf("Pages are");
  if (fd == -1 && flags & MAP_ANONYMOUS) {
    printf(" ANONYMOUS");
  } else if (fd == -1) {
    perror("Please specify the -a flag if you want your page anonymous.\n");
    goto error;
  } else if (flags & MAP_ANONYMOUS) {
    perror("Anonymous pages do not have fd!!\n"
        "Please either remove -a or -m and -f\n");
    goto error;
  }
  if (flags & MAP_SHARED) {
    printf(" SHARED");
  } else if (flags & MAP_PRIVATE) {
    printf(" PRIVATE");
  } else {
    perror("Flags NOT Attributed!\n"
        "Please specify either -p for MAP_PRIVATE or -s for MAP_SHARED\n");
    goto error;
  }
  printf("\n");

  return 0;

error:
  return -1;
}

// 1. Create two pages using mmap
/*
 * testarea = mmap(NULL, pagesize, PROT_READ | PROT_WRITE, MAP_PRIVATE |
 *                                     MAP_ANONYMOUS, -1, 0);
 */
// 2. Write stuff to one of the pages, leave the other one untouched
// 3. Demo the pagemap interface in action (extract individul bits/parts)
//  3.1. Demo with C program
//  3.2. Demo with dd utility (man dd)
// 4. Patch (fs/proc/task_mmu.c):pagemap_read function & print something useful
//  4.1. Print offset when called
//  4.2. Think of sth else
// 5. Test this in Nested AHV
//
// * Bits 0-54  page frame number (PFN) if present
// * Bits 0-4   swap type if swapped
// * Bits 5-54  swap offset if swapped
// * Bit  55    pte is soft-dirty (see Documentation/admin-guide/mm/soft-dirty.rst)
// * Bit  56    page exclusively mapped
// * Bits 57-60 zero
// * Bit  61    page is file-page or shared-anon
// * Bit  62    page swapped
// * Bit  63    page present
