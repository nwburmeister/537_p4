
_userRR:     file format elf32-i386


Disassembly of section .text:

00000000 <roundRobin>:
#include "proc.h"
#include "pstat.h"

int status;

void roundRobin(int timeslice, int iterations, char *job, int jobcount){
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	53                   	push   %ebx
   4:	83 ec 08             	sub    $0x8,%esp
   7:	8b 5d 14             	mov    0x14(%ebp),%ebx

  //  struct pstat *pstat;

    char **ptr = &job;
    printf(1, "%s\n", job);
   a:	ff 75 10             	pushl  0x10(%ebp)
   d:	68 b8 06 00 00       	push   $0x6b8
  12:	6a 01                	push   $0x1
  14:	e8 e4 03 00 00       	call   3fd <printf>
    int pid = fork();
  19:	e8 7d 02 00 00       	call   29b <fork>
    //getpinfo(pstat);
    if (pid < 0){
  1e:	83 c4 10             	add    $0x10,%esp
  21:	85 c0                	test   %eax,%eax
  23:	78 22                	js     47 <roundRobin+0x47>
        // TODO PRINT ERROR MESSAGE
        exit();
    } else if (pid == 0){
  25:	85 c0                	test   %eax,%eax
  27:	74 23                	je     4c <roundRobin+0x4c>
        exec(job, ptr);

    } else if (pid > 0){
        //wait();
    }
    printf(1, "%s\n", "Sleeping!");
  29:	83 ec 04             	sub    $0x4,%esp
  2c:	68 c6 06 00 00       	push   $0x6c6
  31:	68 b8 06 00 00       	push   $0x6b8
  36:	6a 01                	push   $0x1
  38:	e8 c0 03 00 00       	call   3fd <printf>
    //sleep(1000);
    for (int i = 0; i < jobcount; i++) {
  3d:	83 c4 10             	add    $0x10,%esp
  40:	b8 00 00 00 00       	mov    $0x0,%eax
  45:	eb 30                	jmp    77 <roundRobin+0x77>
        exit();
  47:	e8 57 02 00 00       	call   2a3 <exit>
        printf(1, "%s\n", "Executing");
  4c:	83 ec 04             	sub    $0x4,%esp
  4f:	68 bc 06 00 00       	push   $0x6bc
  54:	68 b8 06 00 00       	push   $0x6b8
  59:	6a 01                	push   $0x1
  5b:	e8 9d 03 00 00       	call   3fd <printf>
        exec(job, ptr);
  60:	83 c4 08             	add    $0x8,%esp
  63:	8d 45 10             	lea    0x10(%ebp),%eax
  66:	50                   	push   %eax
  67:	ff 75 10             	pushl  0x10(%ebp)
  6a:	e8 6c 02 00 00       	call   2db <exec>
  6f:	83 c4 10             	add    $0x10,%esp
  72:	eb b5                	jmp    29 <roundRobin+0x29>
    for (int i = 0; i < jobcount; i++) {
  74:	83 c0 01             	add    $0x1,%eax
  77:	39 d8                	cmp    %ebx,%eax
  79:	7c f9                	jl     74 <roundRobin+0x74>

    }


}
  7b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  7e:	c9                   	leave  
  7f:	c3                   	ret    

00000080 <main>:

int main(int argc, char *argv[]) {
  80:	8d 4c 24 04          	lea    0x4(%esp),%ecx
  84:	83 e4 f0             	and    $0xfffffff0,%esp
  87:	ff 71 fc             	pushl  -0x4(%ecx)
  8a:	55                   	push   %ebp
  8b:	89 e5                	mov    %esp,%ebp
  8d:	57                   	push   %edi
  8e:	56                   	push   %esi
  8f:	53                   	push   %ebx
  90:	51                   	push   %ecx
  91:	83 ec 18             	sub    $0x18,%esp
  94:	8b 59 04             	mov    0x4(%ecx),%ebx
    if(argc != 5) {
  97:	83 39 05             	cmpl   $0x5,(%ecx)
  9a:	74 05                	je     a1 <main+0x21>
        // TODO: print error message
        exit();
  9c:	e8 02 02 00 00       	call   2a3 <exit>
    }

    int timeslice = atoi(argv[1]);
  a1:	83 ec 0c             	sub    $0xc,%esp
  a4:	ff 73 04             	pushl  0x4(%ebx)
  a7:	e8 99 01 00 00       	call   245 <atoi>
  ac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    int iterations = atoi(argv[2]);
  af:	83 c4 04             	add    $0x4,%esp
  b2:	ff 73 08             	pushl  0x8(%ebx)
  b5:	e8 8b 01 00 00       	call   245 <atoi>
  ba:	89 c7                	mov    %eax,%edi
    char *job = malloc(sizeof(char) * (strlen(argv[3]) + 1));
  bc:	83 c4 04             	add    $0x4,%esp
  bf:	ff 73 0c             	pushl  0xc(%ebx)
  c2:	e8 93 00 00 00       	call   15a <strlen>
  c7:	83 c0 01             	add    $0x1,%eax
  ca:	89 04 24             	mov    %eax,(%esp)
  cd:	e8 54 05 00 00       	call   626 <malloc>
  d2:	89 c6                	mov    %eax,%esi
    strcpy(job, argv[3]);
  d4:	83 c4 08             	add    $0x8,%esp
  d7:	ff 73 0c             	pushl  0xc(%ebx)
  da:	50                   	push   %eax
  db:	e8 36 00 00 00       	call   116 <strcpy>
    int jobcount = atoi(argv[4]);
  e0:	83 c4 04             	add    $0x4,%esp
  e3:	ff 73 10             	pushl  0x10(%ebx)
  e6:	e8 5a 01 00 00       	call   245 <atoi>
  eb:	89 c3                	mov    %eax,%ebx
    int ppid = getpid();
  ed:	e8 31 02 00 00       	call   323 <getpid>

    setpri(ppid, 3);
  f2:	83 c4 08             	add    $0x8,%esp
  f5:	6a 03                	push   $0x3
  f7:	50                   	push   %eax
  f8:	e8 46 02 00 00       	call   343 <setpri>
    roundRobin(timeslice, iterations, job, jobcount);
  fd:	53                   	push   %ebx
  fe:	56                   	push   %esi
  ff:	57                   	push   %edi
 100:	ff 75 e4             	pushl  -0x1c(%ebp)
 103:	e8 f8 fe ff ff       	call   0 <roundRobin>
    free(job);
 108:	83 c4 14             	add    $0x14,%esp
 10b:	56                   	push   %esi
 10c:	e8 55 04 00 00       	call   566 <free>
    exit();
 111:	e8 8d 01 00 00       	call   2a3 <exit>

00000116 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, const char *t)
{
 116:	55                   	push   %ebp
 117:	89 e5                	mov    %esp,%ebp
 119:	53                   	push   %ebx
 11a:	8b 45 08             	mov    0x8(%ebp),%eax
 11d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 120:	89 c2                	mov    %eax,%edx
 122:	0f b6 19             	movzbl (%ecx),%ebx
 125:	88 1a                	mov    %bl,(%edx)
 127:	8d 52 01             	lea    0x1(%edx),%edx
 12a:	8d 49 01             	lea    0x1(%ecx),%ecx
 12d:	84 db                	test   %bl,%bl
 12f:	75 f1                	jne    122 <strcpy+0xc>
    ;
  return os;
}
 131:	5b                   	pop    %ebx
 132:	5d                   	pop    %ebp
 133:	c3                   	ret    

00000134 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 134:	55                   	push   %ebp
 135:	89 e5                	mov    %esp,%ebp
 137:	8b 4d 08             	mov    0x8(%ebp),%ecx
 13a:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
 13d:	eb 06                	jmp    145 <strcmp+0x11>
    p++, q++;
 13f:	83 c1 01             	add    $0x1,%ecx
 142:	83 c2 01             	add    $0x1,%edx
  while(*p && *p == *q)
 145:	0f b6 01             	movzbl (%ecx),%eax
 148:	84 c0                	test   %al,%al
 14a:	74 04                	je     150 <strcmp+0x1c>
 14c:	3a 02                	cmp    (%edx),%al
 14e:	74 ef                	je     13f <strcmp+0xb>
  return (uchar)*p - (uchar)*q;
 150:	0f b6 c0             	movzbl %al,%eax
 153:	0f b6 12             	movzbl (%edx),%edx
 156:	29 d0                	sub    %edx,%eax
}
 158:	5d                   	pop    %ebp
 159:	c3                   	ret    

0000015a <strlen>:

uint
strlen(const char *s)
{
 15a:	55                   	push   %ebp
 15b:	89 e5                	mov    %esp,%ebp
 15d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
 160:	ba 00 00 00 00       	mov    $0x0,%edx
 165:	eb 03                	jmp    16a <strlen+0x10>
 167:	83 c2 01             	add    $0x1,%edx
 16a:	89 d0                	mov    %edx,%eax
 16c:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
 170:	75 f5                	jne    167 <strlen+0xd>
    ;
  return n;
}
 172:	5d                   	pop    %ebp
 173:	c3                   	ret    

00000174 <memset>:

void*
memset(void *dst, int c, uint n)
{
 174:	55                   	push   %ebp
 175:	89 e5                	mov    %esp,%ebp
 177:	57                   	push   %edi
 178:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
 17b:	89 d7                	mov    %edx,%edi
 17d:	8b 4d 10             	mov    0x10(%ebp),%ecx
 180:	8b 45 0c             	mov    0xc(%ebp),%eax
 183:	fc                   	cld    
 184:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
 186:	89 d0                	mov    %edx,%eax
 188:	5f                   	pop    %edi
 189:	5d                   	pop    %ebp
 18a:	c3                   	ret    

0000018b <strchr>:

char*
strchr(const char *s, char c)
{
 18b:	55                   	push   %ebp
 18c:	89 e5                	mov    %esp,%ebp
 18e:	8b 45 08             	mov    0x8(%ebp),%eax
 191:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 195:	0f b6 10             	movzbl (%eax),%edx
 198:	84 d2                	test   %dl,%dl
 19a:	74 09                	je     1a5 <strchr+0x1a>
    if(*s == c)
 19c:	38 ca                	cmp    %cl,%dl
 19e:	74 0a                	je     1aa <strchr+0x1f>
  for(; *s; s++)
 1a0:	83 c0 01             	add    $0x1,%eax
 1a3:	eb f0                	jmp    195 <strchr+0xa>
      return (char*)s;
  return 0;
 1a5:	b8 00 00 00 00       	mov    $0x0,%eax
}
 1aa:	5d                   	pop    %ebp
 1ab:	c3                   	ret    

000001ac <gets>:

char*
gets(char *buf, int max)
{
 1ac:	55                   	push   %ebp
 1ad:	89 e5                	mov    %esp,%ebp
 1af:	57                   	push   %edi
 1b0:	56                   	push   %esi
 1b1:	53                   	push   %ebx
 1b2:	83 ec 1c             	sub    $0x1c,%esp
 1b5:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1b8:	bb 00 00 00 00       	mov    $0x0,%ebx
 1bd:	8d 73 01             	lea    0x1(%ebx),%esi
 1c0:	3b 75 0c             	cmp    0xc(%ebp),%esi
 1c3:	7d 2e                	jge    1f3 <gets+0x47>
    cc = read(0, &c, 1);
 1c5:	83 ec 04             	sub    $0x4,%esp
 1c8:	6a 01                	push   $0x1
 1ca:	8d 45 e7             	lea    -0x19(%ebp),%eax
 1cd:	50                   	push   %eax
 1ce:	6a 00                	push   $0x0
 1d0:	e8 e6 00 00 00       	call   2bb <read>
    if(cc < 1)
 1d5:	83 c4 10             	add    $0x10,%esp
 1d8:	85 c0                	test   %eax,%eax
 1da:	7e 17                	jle    1f3 <gets+0x47>
      break;
    buf[i++] = c;
 1dc:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 1e0:	88 04 1f             	mov    %al,(%edi,%ebx,1)
    if(c == '\n' || c == '\r')
 1e3:	3c 0a                	cmp    $0xa,%al
 1e5:	0f 94 c2             	sete   %dl
 1e8:	3c 0d                	cmp    $0xd,%al
 1ea:	0f 94 c0             	sete   %al
    buf[i++] = c;
 1ed:	89 f3                	mov    %esi,%ebx
    if(c == '\n' || c == '\r')
 1ef:	08 c2                	or     %al,%dl
 1f1:	74 ca                	je     1bd <gets+0x11>
      break;
  }
  buf[i] = '\0';
 1f3:	c6 04 1f 00          	movb   $0x0,(%edi,%ebx,1)
  return buf;
}
 1f7:	89 f8                	mov    %edi,%eax
 1f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
 1fc:	5b                   	pop    %ebx
 1fd:	5e                   	pop    %esi
 1fe:	5f                   	pop    %edi
 1ff:	5d                   	pop    %ebp
 200:	c3                   	ret    

00000201 <stat>:

int
stat(const char *n, struct stat *st)
{
 201:	55                   	push   %ebp
 202:	89 e5                	mov    %esp,%ebp
 204:	56                   	push   %esi
 205:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 206:	83 ec 08             	sub    $0x8,%esp
 209:	6a 00                	push   $0x0
 20b:	ff 75 08             	pushl  0x8(%ebp)
 20e:	e8 d0 00 00 00       	call   2e3 <open>
  if(fd < 0)
 213:	83 c4 10             	add    $0x10,%esp
 216:	85 c0                	test   %eax,%eax
 218:	78 24                	js     23e <stat+0x3d>
 21a:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 21c:	83 ec 08             	sub    $0x8,%esp
 21f:	ff 75 0c             	pushl  0xc(%ebp)
 222:	50                   	push   %eax
 223:	e8 d3 00 00 00       	call   2fb <fstat>
 228:	89 c6                	mov    %eax,%esi
  close(fd);
 22a:	89 1c 24             	mov    %ebx,(%esp)
 22d:	e8 99 00 00 00       	call   2cb <close>
  return r;
 232:	83 c4 10             	add    $0x10,%esp
}
 235:	89 f0                	mov    %esi,%eax
 237:	8d 65 f8             	lea    -0x8(%ebp),%esp
 23a:	5b                   	pop    %ebx
 23b:	5e                   	pop    %esi
 23c:	5d                   	pop    %ebp
 23d:	c3                   	ret    
    return -1;
 23e:	be ff ff ff ff       	mov    $0xffffffff,%esi
 243:	eb f0                	jmp    235 <stat+0x34>

00000245 <atoi>:

int
atoi(const char *s)
{
 245:	55                   	push   %ebp
 246:	89 e5                	mov    %esp,%ebp
 248:	53                   	push   %ebx
 249:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  n = 0;
 24c:	b8 00 00 00 00       	mov    $0x0,%eax
  while('0' <= *s && *s <= '9')
 251:	eb 10                	jmp    263 <atoi+0x1e>
    n = n*10 + *s++ - '0';
 253:	8d 1c 80             	lea    (%eax,%eax,4),%ebx
 256:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
 259:	83 c1 01             	add    $0x1,%ecx
 25c:	0f be d2             	movsbl %dl,%edx
 25f:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
  while('0' <= *s && *s <= '9')
 263:	0f b6 11             	movzbl (%ecx),%edx
 266:	8d 5a d0             	lea    -0x30(%edx),%ebx
 269:	80 fb 09             	cmp    $0x9,%bl
 26c:	76 e5                	jbe    253 <atoi+0xe>
  return n;
}
 26e:	5b                   	pop    %ebx
 26f:	5d                   	pop    %ebp
 270:	c3                   	ret    

00000271 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 271:	55                   	push   %ebp
 272:	89 e5                	mov    %esp,%ebp
 274:	56                   	push   %esi
 275:	53                   	push   %ebx
 276:	8b 45 08             	mov    0x8(%ebp),%eax
 279:	8b 5d 0c             	mov    0xc(%ebp),%ebx
 27c:	8b 55 10             	mov    0x10(%ebp),%edx
  char *dst;
  const char *src;

  dst = vdst;
 27f:	89 c1                	mov    %eax,%ecx
  src = vsrc;
  while(n-- > 0)
 281:	eb 0d                	jmp    290 <memmove+0x1f>
    *dst++ = *src++;
 283:	0f b6 13             	movzbl (%ebx),%edx
 286:	88 11                	mov    %dl,(%ecx)
 288:	8d 5b 01             	lea    0x1(%ebx),%ebx
 28b:	8d 49 01             	lea    0x1(%ecx),%ecx
  while(n-- > 0)
 28e:	89 f2                	mov    %esi,%edx
 290:	8d 72 ff             	lea    -0x1(%edx),%esi
 293:	85 d2                	test   %edx,%edx
 295:	7f ec                	jg     283 <memmove+0x12>
  return vdst;
}
 297:	5b                   	pop    %ebx
 298:	5e                   	pop    %esi
 299:	5d                   	pop    %ebp
 29a:	c3                   	ret    

0000029b <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 29b:	b8 01 00 00 00       	mov    $0x1,%eax
 2a0:	cd 40                	int    $0x40
 2a2:	c3                   	ret    

000002a3 <exit>:
SYSCALL(exit)
 2a3:	b8 02 00 00 00       	mov    $0x2,%eax
 2a8:	cd 40                	int    $0x40
 2aa:	c3                   	ret    

000002ab <wait>:
SYSCALL(wait)
 2ab:	b8 03 00 00 00       	mov    $0x3,%eax
 2b0:	cd 40                	int    $0x40
 2b2:	c3                   	ret    

000002b3 <pipe>:
SYSCALL(pipe)
 2b3:	b8 04 00 00 00       	mov    $0x4,%eax
 2b8:	cd 40                	int    $0x40
 2ba:	c3                   	ret    

000002bb <read>:
SYSCALL(read)
 2bb:	b8 05 00 00 00       	mov    $0x5,%eax
 2c0:	cd 40                	int    $0x40
 2c2:	c3                   	ret    

000002c3 <write>:
SYSCALL(write)
 2c3:	b8 10 00 00 00       	mov    $0x10,%eax
 2c8:	cd 40                	int    $0x40
 2ca:	c3                   	ret    

000002cb <close>:
SYSCALL(close)
 2cb:	b8 15 00 00 00       	mov    $0x15,%eax
 2d0:	cd 40                	int    $0x40
 2d2:	c3                   	ret    

000002d3 <kill>:
SYSCALL(kill)
 2d3:	b8 06 00 00 00       	mov    $0x6,%eax
 2d8:	cd 40                	int    $0x40
 2da:	c3                   	ret    

000002db <exec>:
SYSCALL(exec)
 2db:	b8 07 00 00 00       	mov    $0x7,%eax
 2e0:	cd 40                	int    $0x40
 2e2:	c3                   	ret    

000002e3 <open>:
SYSCALL(open)
 2e3:	b8 0f 00 00 00       	mov    $0xf,%eax
 2e8:	cd 40                	int    $0x40
 2ea:	c3                   	ret    

000002eb <mknod>:
SYSCALL(mknod)
 2eb:	b8 11 00 00 00       	mov    $0x11,%eax
 2f0:	cd 40                	int    $0x40
 2f2:	c3                   	ret    

000002f3 <unlink>:
SYSCALL(unlink)
 2f3:	b8 12 00 00 00       	mov    $0x12,%eax
 2f8:	cd 40                	int    $0x40
 2fa:	c3                   	ret    

000002fb <fstat>:
SYSCALL(fstat)
 2fb:	b8 08 00 00 00       	mov    $0x8,%eax
 300:	cd 40                	int    $0x40
 302:	c3                   	ret    

00000303 <link>:
SYSCALL(link)
 303:	b8 13 00 00 00       	mov    $0x13,%eax
 308:	cd 40                	int    $0x40
 30a:	c3                   	ret    

0000030b <mkdir>:
SYSCALL(mkdir)
 30b:	b8 14 00 00 00       	mov    $0x14,%eax
 310:	cd 40                	int    $0x40
 312:	c3                   	ret    

00000313 <chdir>:
SYSCALL(chdir)
 313:	b8 09 00 00 00       	mov    $0x9,%eax
 318:	cd 40                	int    $0x40
 31a:	c3                   	ret    

0000031b <dup>:
SYSCALL(dup)
 31b:	b8 0a 00 00 00       	mov    $0xa,%eax
 320:	cd 40                	int    $0x40
 322:	c3                   	ret    

00000323 <getpid>:
SYSCALL(getpid)
 323:	b8 0b 00 00 00       	mov    $0xb,%eax
 328:	cd 40                	int    $0x40
 32a:	c3                   	ret    

0000032b <sbrk>:
SYSCALL(sbrk)
 32b:	b8 0c 00 00 00       	mov    $0xc,%eax
 330:	cd 40                	int    $0x40
 332:	c3                   	ret    

00000333 <sleep>:
SYSCALL(sleep)
 333:	b8 0d 00 00 00       	mov    $0xd,%eax
 338:	cd 40                	int    $0x40
 33a:	c3                   	ret    

0000033b <uptime>:
SYSCALL(uptime)
 33b:	b8 0e 00 00 00       	mov    $0xe,%eax
 340:	cd 40                	int    $0x40
 342:	c3                   	ret    

00000343 <setpri>:
// adding sys calls
SYSCALL(setpri)
 343:	b8 16 00 00 00       	mov    $0x16,%eax
 348:	cd 40                	int    $0x40
 34a:	c3                   	ret    

0000034b <getpri>:
SYSCALL(getpri)
 34b:	b8 17 00 00 00       	mov    $0x17,%eax
 350:	cd 40                	int    $0x40
 352:	c3                   	ret    

00000353 <fork2>:
SYSCALL(fork2)
 353:	b8 18 00 00 00       	mov    $0x18,%eax
 358:	cd 40                	int    $0x40
 35a:	c3                   	ret    

0000035b <getpinfo>:
SYSCALL(getpinfo)
 35b:	b8 19 00 00 00       	mov    $0x19,%eax
 360:	cd 40                	int    $0x40
 362:	c3                   	ret    

00000363 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 363:	55                   	push   %ebp
 364:	89 e5                	mov    %esp,%ebp
 366:	83 ec 1c             	sub    $0x1c,%esp
 369:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 36c:	6a 01                	push   $0x1
 36e:	8d 55 f4             	lea    -0xc(%ebp),%edx
 371:	52                   	push   %edx
 372:	50                   	push   %eax
 373:	e8 4b ff ff ff       	call   2c3 <write>
}
 378:	83 c4 10             	add    $0x10,%esp
 37b:	c9                   	leave  
 37c:	c3                   	ret    

0000037d <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 37d:	55                   	push   %ebp
 37e:	89 e5                	mov    %esp,%ebp
 380:	57                   	push   %edi
 381:	56                   	push   %esi
 382:	53                   	push   %ebx
 383:	83 ec 2c             	sub    $0x2c,%esp
 386:	89 c7                	mov    %eax,%edi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 388:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 38c:	0f 95 c3             	setne  %bl
 38f:	89 d0                	mov    %edx,%eax
 391:	c1 e8 1f             	shr    $0x1f,%eax
 394:	84 c3                	test   %al,%bl
 396:	74 10                	je     3a8 <printint+0x2b>
    neg = 1;
    x = -xx;
 398:	f7 da                	neg    %edx
    neg = 1;
 39a:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 3a1:	be 00 00 00 00       	mov    $0x0,%esi
 3a6:	eb 0b                	jmp    3b3 <printint+0x36>
  neg = 0;
 3a8:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 3af:	eb f0                	jmp    3a1 <printint+0x24>
  do{
    buf[i++] = digits[x % base];
 3b1:	89 c6                	mov    %eax,%esi
 3b3:	89 d0                	mov    %edx,%eax
 3b5:	ba 00 00 00 00       	mov    $0x0,%edx
 3ba:	f7 f1                	div    %ecx
 3bc:	89 c3                	mov    %eax,%ebx
 3be:	8d 46 01             	lea    0x1(%esi),%eax
 3c1:	0f b6 92 d8 06 00 00 	movzbl 0x6d8(%edx),%edx
 3c8:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
 3cc:	89 da                	mov    %ebx,%edx
 3ce:	85 db                	test   %ebx,%ebx
 3d0:	75 df                	jne    3b1 <printint+0x34>
 3d2:	89 c3                	mov    %eax,%ebx
  if(neg)
 3d4:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 3d8:	74 16                	je     3f0 <printint+0x73>
    buf[i++] = '-';
 3da:	c6 44 05 d8 2d       	movb   $0x2d,-0x28(%ebp,%eax,1)
 3df:	8d 5e 02             	lea    0x2(%esi),%ebx
 3e2:	eb 0c                	jmp    3f0 <printint+0x73>

  while(--i >= 0)
    putc(fd, buf[i]);
 3e4:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 3e9:	89 f8                	mov    %edi,%eax
 3eb:	e8 73 ff ff ff       	call   363 <putc>
  while(--i >= 0)
 3f0:	83 eb 01             	sub    $0x1,%ebx
 3f3:	79 ef                	jns    3e4 <printint+0x67>
}
 3f5:	83 c4 2c             	add    $0x2c,%esp
 3f8:	5b                   	pop    %ebx
 3f9:	5e                   	pop    %esi
 3fa:	5f                   	pop    %edi
 3fb:	5d                   	pop    %ebp
 3fc:	c3                   	ret    

000003fd <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, const char *fmt, ...)
{
 3fd:	55                   	push   %ebp
 3fe:	89 e5                	mov    %esp,%ebp
 400:	57                   	push   %edi
 401:	56                   	push   %esi
 402:	53                   	push   %ebx
 403:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 406:	8d 45 10             	lea    0x10(%ebp),%eax
 409:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 40c:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 411:	bb 00 00 00 00       	mov    $0x0,%ebx
 416:	eb 14                	jmp    42c <printf+0x2f>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 418:	89 fa                	mov    %edi,%edx
 41a:	8b 45 08             	mov    0x8(%ebp),%eax
 41d:	e8 41 ff ff ff       	call   363 <putc>
 422:	eb 05                	jmp    429 <printf+0x2c>
      }
    } else if(state == '%'){
 424:	83 fe 25             	cmp    $0x25,%esi
 427:	74 25                	je     44e <printf+0x51>
  for(i = 0; fmt[i]; i++){
 429:	83 c3 01             	add    $0x1,%ebx
 42c:	8b 45 0c             	mov    0xc(%ebp),%eax
 42f:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 433:	84 c0                	test   %al,%al
 435:	0f 84 23 01 00 00    	je     55e <printf+0x161>
    c = fmt[i] & 0xff;
 43b:	0f be f8             	movsbl %al,%edi
 43e:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 441:	85 f6                	test   %esi,%esi
 443:	75 df                	jne    424 <printf+0x27>
      if(c == '%'){
 445:	83 f8 25             	cmp    $0x25,%eax
 448:	75 ce                	jne    418 <printf+0x1b>
        state = '%';
 44a:	89 c6                	mov    %eax,%esi
 44c:	eb db                	jmp    429 <printf+0x2c>
      if(c == 'd'){
 44e:	83 f8 64             	cmp    $0x64,%eax
 451:	74 49                	je     49c <printf+0x9f>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 453:	83 f8 78             	cmp    $0x78,%eax
 456:	0f 94 c1             	sete   %cl
 459:	83 f8 70             	cmp    $0x70,%eax
 45c:	0f 94 c2             	sete   %dl
 45f:	08 d1                	or     %dl,%cl
 461:	75 63                	jne    4c6 <printf+0xc9>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 463:	83 f8 73             	cmp    $0x73,%eax
 466:	0f 84 84 00 00 00    	je     4f0 <printf+0xf3>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 46c:	83 f8 63             	cmp    $0x63,%eax
 46f:	0f 84 b7 00 00 00    	je     52c <printf+0x12f>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 475:	83 f8 25             	cmp    $0x25,%eax
 478:	0f 84 cc 00 00 00    	je     54a <printf+0x14d>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 47e:	ba 25 00 00 00       	mov    $0x25,%edx
 483:	8b 45 08             	mov    0x8(%ebp),%eax
 486:	e8 d8 fe ff ff       	call   363 <putc>
        putc(fd, c);
 48b:	89 fa                	mov    %edi,%edx
 48d:	8b 45 08             	mov    0x8(%ebp),%eax
 490:	e8 ce fe ff ff       	call   363 <putc>
      }
      state = 0;
 495:	be 00 00 00 00       	mov    $0x0,%esi
 49a:	eb 8d                	jmp    429 <printf+0x2c>
        printint(fd, *ap, 10, 1);
 49c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 49f:	8b 17                	mov    (%edi),%edx
 4a1:	83 ec 0c             	sub    $0xc,%esp
 4a4:	6a 01                	push   $0x1
 4a6:	b9 0a 00 00 00       	mov    $0xa,%ecx
 4ab:	8b 45 08             	mov    0x8(%ebp),%eax
 4ae:	e8 ca fe ff ff       	call   37d <printint>
        ap++;
 4b3:	83 c7 04             	add    $0x4,%edi
 4b6:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 4b9:	83 c4 10             	add    $0x10,%esp
      state = 0;
 4bc:	be 00 00 00 00       	mov    $0x0,%esi
 4c1:	e9 63 ff ff ff       	jmp    429 <printf+0x2c>
        printint(fd, *ap, 16, 0);
 4c6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 4c9:	8b 17                	mov    (%edi),%edx
 4cb:	83 ec 0c             	sub    $0xc,%esp
 4ce:	6a 00                	push   $0x0
 4d0:	b9 10 00 00 00       	mov    $0x10,%ecx
 4d5:	8b 45 08             	mov    0x8(%ebp),%eax
 4d8:	e8 a0 fe ff ff       	call   37d <printint>
        ap++;
 4dd:	83 c7 04             	add    $0x4,%edi
 4e0:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 4e3:	83 c4 10             	add    $0x10,%esp
      state = 0;
 4e6:	be 00 00 00 00       	mov    $0x0,%esi
 4eb:	e9 39 ff ff ff       	jmp    429 <printf+0x2c>
        s = (char*)*ap;
 4f0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 4f3:	8b 30                	mov    (%eax),%esi
        ap++;
 4f5:	83 c0 04             	add    $0x4,%eax
 4f8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 4fb:	85 f6                	test   %esi,%esi
 4fd:	75 28                	jne    527 <printf+0x12a>
          s = "(null)";
 4ff:	be d0 06 00 00       	mov    $0x6d0,%esi
 504:	8b 7d 08             	mov    0x8(%ebp),%edi
 507:	eb 0d                	jmp    516 <printf+0x119>
          putc(fd, *s);
 509:	0f be d2             	movsbl %dl,%edx
 50c:	89 f8                	mov    %edi,%eax
 50e:	e8 50 fe ff ff       	call   363 <putc>
          s++;
 513:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 516:	0f b6 16             	movzbl (%esi),%edx
 519:	84 d2                	test   %dl,%dl
 51b:	75 ec                	jne    509 <printf+0x10c>
      state = 0;
 51d:	be 00 00 00 00       	mov    $0x0,%esi
 522:	e9 02 ff ff ff       	jmp    429 <printf+0x2c>
 527:	8b 7d 08             	mov    0x8(%ebp),%edi
 52a:	eb ea                	jmp    516 <printf+0x119>
        putc(fd, *ap);
 52c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 52f:	0f be 17             	movsbl (%edi),%edx
 532:	8b 45 08             	mov    0x8(%ebp),%eax
 535:	e8 29 fe ff ff       	call   363 <putc>
        ap++;
 53a:	83 c7 04             	add    $0x4,%edi
 53d:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 540:	be 00 00 00 00       	mov    $0x0,%esi
 545:	e9 df fe ff ff       	jmp    429 <printf+0x2c>
        putc(fd, c);
 54a:	89 fa                	mov    %edi,%edx
 54c:	8b 45 08             	mov    0x8(%ebp),%eax
 54f:	e8 0f fe ff ff       	call   363 <putc>
      state = 0;
 554:	be 00 00 00 00       	mov    $0x0,%esi
 559:	e9 cb fe ff ff       	jmp    429 <printf+0x2c>
    }
  }
}
 55e:	8d 65 f4             	lea    -0xc(%ebp),%esp
 561:	5b                   	pop    %ebx
 562:	5e                   	pop    %esi
 563:	5f                   	pop    %edi
 564:	5d                   	pop    %ebp
 565:	c3                   	ret    

00000566 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 566:	55                   	push   %ebp
 567:	89 e5                	mov    %esp,%ebp
 569:	57                   	push   %edi
 56a:	56                   	push   %esi
 56b:	53                   	push   %ebx
 56c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 56f:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 572:	a1 a0 09 00 00       	mov    0x9a0,%eax
 577:	eb 02                	jmp    57b <free+0x15>
 579:	89 d0                	mov    %edx,%eax
 57b:	39 c8                	cmp    %ecx,%eax
 57d:	73 04                	jae    583 <free+0x1d>
 57f:	39 08                	cmp    %ecx,(%eax)
 581:	77 12                	ja     595 <free+0x2f>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 583:	8b 10                	mov    (%eax),%edx
 585:	39 c2                	cmp    %eax,%edx
 587:	77 f0                	ja     579 <free+0x13>
 589:	39 c8                	cmp    %ecx,%eax
 58b:	72 08                	jb     595 <free+0x2f>
 58d:	39 ca                	cmp    %ecx,%edx
 58f:	77 04                	ja     595 <free+0x2f>
 591:	89 d0                	mov    %edx,%eax
 593:	eb e6                	jmp    57b <free+0x15>
      break;
  if(bp + bp->s.size == p->s.ptr){
 595:	8b 73 fc             	mov    -0x4(%ebx),%esi
 598:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 59b:	8b 10                	mov    (%eax),%edx
 59d:	39 d7                	cmp    %edx,%edi
 59f:	74 19                	je     5ba <free+0x54>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 5a1:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 5a4:	8b 50 04             	mov    0x4(%eax),%edx
 5a7:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 5aa:	39 ce                	cmp    %ecx,%esi
 5ac:	74 1b                	je     5c9 <free+0x63>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 5ae:	89 08                	mov    %ecx,(%eax)
  freep = p;
 5b0:	a3 a0 09 00 00       	mov    %eax,0x9a0
}
 5b5:	5b                   	pop    %ebx
 5b6:	5e                   	pop    %esi
 5b7:	5f                   	pop    %edi
 5b8:	5d                   	pop    %ebp
 5b9:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 5ba:	03 72 04             	add    0x4(%edx),%esi
 5bd:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 5c0:	8b 10                	mov    (%eax),%edx
 5c2:	8b 12                	mov    (%edx),%edx
 5c4:	89 53 f8             	mov    %edx,-0x8(%ebx)
 5c7:	eb db                	jmp    5a4 <free+0x3e>
    p->s.size += bp->s.size;
 5c9:	03 53 fc             	add    -0x4(%ebx),%edx
 5cc:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 5cf:	8b 53 f8             	mov    -0x8(%ebx),%edx
 5d2:	89 10                	mov    %edx,(%eax)
 5d4:	eb da                	jmp    5b0 <free+0x4a>

000005d6 <morecore>:

static Header*
morecore(uint nu)
{
 5d6:	55                   	push   %ebp
 5d7:	89 e5                	mov    %esp,%ebp
 5d9:	53                   	push   %ebx
 5da:	83 ec 04             	sub    $0x4,%esp
 5dd:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 5df:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 5e4:	77 05                	ja     5eb <morecore+0x15>
    nu = 4096;
 5e6:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 5eb:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 5f2:	83 ec 0c             	sub    $0xc,%esp
 5f5:	50                   	push   %eax
 5f6:	e8 30 fd ff ff       	call   32b <sbrk>
  if(p == (char*)-1)
 5fb:	83 c4 10             	add    $0x10,%esp
 5fe:	83 f8 ff             	cmp    $0xffffffff,%eax
 601:	74 1c                	je     61f <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 603:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 606:	83 c0 08             	add    $0x8,%eax
 609:	83 ec 0c             	sub    $0xc,%esp
 60c:	50                   	push   %eax
 60d:	e8 54 ff ff ff       	call   566 <free>
  return freep;
 612:	a1 a0 09 00 00       	mov    0x9a0,%eax
 617:	83 c4 10             	add    $0x10,%esp
}
 61a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 61d:	c9                   	leave  
 61e:	c3                   	ret    
    return 0;
 61f:	b8 00 00 00 00       	mov    $0x0,%eax
 624:	eb f4                	jmp    61a <morecore+0x44>

00000626 <malloc>:

void*
malloc(uint nbytes)
{
 626:	55                   	push   %ebp
 627:	89 e5                	mov    %esp,%ebp
 629:	53                   	push   %ebx
 62a:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 62d:	8b 45 08             	mov    0x8(%ebp),%eax
 630:	8d 58 07             	lea    0x7(%eax),%ebx
 633:	c1 eb 03             	shr    $0x3,%ebx
 636:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 639:	8b 0d a0 09 00 00    	mov    0x9a0,%ecx
 63f:	85 c9                	test   %ecx,%ecx
 641:	74 04                	je     647 <malloc+0x21>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 643:	8b 01                	mov    (%ecx),%eax
 645:	eb 4d                	jmp    694 <malloc+0x6e>
    base.s.ptr = freep = prevp = &base;
 647:	c7 05 a0 09 00 00 a4 	movl   $0x9a4,0x9a0
 64e:	09 00 00 
 651:	c7 05 a4 09 00 00 a4 	movl   $0x9a4,0x9a4
 658:	09 00 00 
    base.s.size = 0;
 65b:	c7 05 a8 09 00 00 00 	movl   $0x0,0x9a8
 662:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 665:	b9 a4 09 00 00       	mov    $0x9a4,%ecx
 66a:	eb d7                	jmp    643 <malloc+0x1d>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 66c:	39 da                	cmp    %ebx,%edx
 66e:	74 1a                	je     68a <malloc+0x64>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 670:	29 da                	sub    %ebx,%edx
 672:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 675:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 678:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 67b:	89 0d a0 09 00 00    	mov    %ecx,0x9a0
      return (void*)(p + 1);
 681:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 684:	83 c4 04             	add    $0x4,%esp
 687:	5b                   	pop    %ebx
 688:	5d                   	pop    %ebp
 689:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 68a:	8b 10                	mov    (%eax),%edx
 68c:	89 11                	mov    %edx,(%ecx)
 68e:	eb eb                	jmp    67b <malloc+0x55>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 690:	89 c1                	mov    %eax,%ecx
 692:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 694:	8b 50 04             	mov    0x4(%eax),%edx
 697:	39 da                	cmp    %ebx,%edx
 699:	73 d1                	jae    66c <malloc+0x46>
    if(p == freep)
 69b:	39 05 a0 09 00 00    	cmp    %eax,0x9a0
 6a1:	75 ed                	jne    690 <malloc+0x6a>
      if((p = morecore(nunits)) == 0)
 6a3:	89 d8                	mov    %ebx,%eax
 6a5:	e8 2c ff ff ff       	call   5d6 <morecore>
 6aa:	85 c0                	test   %eax,%eax
 6ac:	75 e2                	jne    690 <malloc+0x6a>
        return 0;
 6ae:	b8 00 00 00 00       	mov    $0x0,%eax
 6b3:	eb cf                	jmp    684 <malloc+0x5e>
