#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <libproc.h>

#ifndef PROC_PIDARCHINFO
#define PROC_PIDARCHINFO 19
struct proc_archinfo { uint32_t p_cputype, p_cpusubtype; };
#endif

static const char* get_arch(uint32_t t, uint32_t s) {
    if (t == 16777228) return (s & 0xff) == 2 ? "arm64e" : "arm64";
    return t == 16777223 ? "x86_64" : "unknown";
}

static void patch(uint8_t *d, size_t s) {
    uint32_t m = *(uint32_t*)d;
    if (m == MH_MAGIC_64) {
        struct mach_header_64 *h = (struct mach_header_64*)d;
        if (h->cputype == 16777228 && (h->cpusubtype & 0xff) == 2) {
            h->cpusubtype = 0;
            struct load_command *lc = (struct load_command*)(d + sizeof(*h));
            for (uint32_t i=0; i<h->ncmds; i++) {
                if (lc->cmd == LC_SEGMENT_64) {
                    struct segment_command_64 *seg = (struct segment_command_64*)lc;
                    if (seg->initprot & 4) { // VM_PROT_EXECUTE
                        for (size_t j=0; j < seg->filesize - 3; j += 4) {
                            uint32_t *p = (uint32_t*)(d + seg->fileoff + j);
                            if ((*p & 0xfffff000) == 0xd5032000) *p = 0xd503201f;
                        }
                    }
                }
                lc = (struct load_command*)((uint8_t*)lc + lc->cmdsize);
            }
        }
    } else if (m == FAT_MAGIC || m == FAT_CIGAM) {
        struct fat_header *fh = (struct fat_header*)d;
        uint32_t n = (m == FAT_CIGAM) ? __builtin_bswap32(fh->nfat_arch) : fh->nfat_arch;
        struct fat_arch *as = (struct fat_arch*)(d + 8);
        for (uint32_t i=0; i<n; i++) {
            uint32_t off = (m == FAT_CIGAM) ? __builtin_bswap32(as[i].offset) : as[i].offset;
            uint32_t t = (m == FAT_CIGAM) ? __builtin_bswap32(as[i].cputype) : as[i].cputype;
            uint32_t sbt = (m == FAT_CIGAM) ? __builtin_bswap32(as[i].cpusubtype) : as[i].cpusubtype;
            if (t == 16777228 && (sbt & 0xff) == 2) {
                patch(d + off, s - off);
                as[i].cpusubtype = (m == FAT_CIGAM) ? __builtin_bswap32(0) : 0;
            }
        }
    }
}

int main(int argc, char **argv) {
    int c, pid = 0;
    while ((c = getopt(argc, argv, "p:")) != -1) {
        if (c == 'p') { pid = atoi(optarg); break; }
    }
    if (pid) {
        struct proc_archinfo a; char p[1024]; if (proc_pidinfo(pid, 19, 0, &a, sizeof(a)) <= 0) return 1;
        proc_pidpath(pid, p, 1024); printf("[*] PID %d (%s): %s\n", pid, p, get_arch(a.p_cputype, a.p_cpusubtype));
        return 0;
    }
    if (optind >= argc) return printf("Usage: %s <bin> [out]\n", argv[0]), 0;
    int fd = open(argv[optind], O_RDONLY); struct stat st; fstat(fd, &st);
    uint8_t *d = mmap(0, st.st_size, PROT_READ|PROT_WRITE, MAP_PRIVATE, fd, 0); close(fd);
    patch(d, st.st_size);
    int o = open(argc > optind+1 ? argv[optind+1] : "patched", O_WRONLY|O_CREAT|O_TRUNC, 0755);
    write(o, d, st.st_size); close(o); munmap(d, st.st_size); return 0;
}