//
//  patcher.c
//  Rootifier
//
//  Created by Nick Chan on 2024/11/30.
//

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <limits.h>

static uint32_t patch_mem(char* mem, size_t size) {
    char pathbuf[PATH_MAX];
    char* p = mem;
    uint32_t count = 0;
    
    while (p < (mem + size)) {
        char* curse = memmem(p, size - (p - mem), "/var/jb", 7);
        if (!curse) break;
        
        count++;

        strlcpy(pathbuf, curse, PATH_MAX);
        size_t curse_size = strlen(pathbuf);
        strlcpy(curse, &pathbuf[7], curse_size + 1);
        printf("%s -> %s @ %p\n", pathbuf, curse, curse);
        
        
        p += (curse_size + 1);
    }
    
    return count;
}

int patcher(const char* path) {
    printf("Input file: %s\n", path);

    int fd = open(path, O_RDWR);
    
    if (fd < 0) {
        printf("failed to open file %s: %d (%s)\n", path, errno, strerror(errno));
        return -1;
    }
    
    struct stat st;
    if (stat(path, &st) < 0) {
        printf("failed to stat file %s: %d (%s)\n", path, errno, strerror(errno));
        close(fd);
        return -1;
    }
    
    char* file = mmap(NULL, st.st_size, PROT_READ | PROT_WRITE, MAP_FILE | MAP_SHARED, fd, 0);
    
    if (file == MAP_FAILED) {
        printf("failed to map file %s: %d (%s)\n", path, errno, strerror(errno));
        close(fd);
        return -1;
    }
    
    uint32_t count = 0, c;
    
    while ((c = patch_mem(file, st.st_size)))
        count += c;
    
    printf("mitigated %u curses\n", count);
    
    munmap(file, st.st_size);
    close(fd);
    
    return 0;
}
