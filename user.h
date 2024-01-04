struct stat;

// system calls
int fork(void);
int exec(char*, char**);
int exit(void) __attribute__((noreturn));
int wait(void);
int kill(int);
int getpid(void);
int sleep(int);
char* sbrk(int);

int open(const char*, int);
int read(int, void*, int);
int write(int, const void*, int);
int close(int);
int pipe(int*);
int dup(int);

int fstat(int fd, struct stat*);
int mknod(const char*, short, short);
int link(const char*, const char*);
int unlink(const char*);
int mkdir(const char*);
int chdir(const char*);

int uptime(void);

// ulib.c
int stat(const char*, struct stat*);
char* strcpy(char*, const char*);
void *memmove(void*, const void*, int);
char* strchr(const char*, char c);
int strcmp(const char*, const char*);
void printf(int, const char*, ...);
char* gets(int, char*, int max);
uint strlen(const char*);
void* memset(void*, int, uint);
void* malloc(uint);
void free(void*);
int atoi(const char*);
