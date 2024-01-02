#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    int fd = open(argv[1],O_RDWR);
    if (fd < 0) {
        fprintf(stderr, "open %s failed\n",argv[1]);
        return 0;
    }

    char buf[512];
    int n = read(fd, buf, sizeof(buf));

    if (n > 510) {
        fprintf(stderr, "boot block too large: %d bytes (max 510)\n", n);
        return 0;
    }

    for (size_t i=n; i<510; i++)
        buf[i] = 0;
    buf[510] = 0x55;
    buf[511] = 0xAA;

    int r = lseek(fd,0,SEEK_SET);
    if (r < 0) {
        fprintf(stderr, "seek failed\n");
        return 0;
    }

    if (write(fd,buf,sizeof(buf)) != sizeof(buf)) {
        fprintf(stderr, "write failed\n");
        return 0;
    }

    close(fd);
    return 0;
}