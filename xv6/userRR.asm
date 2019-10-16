
_userRR:     file format elf32-i386


Disassembly of section .text:

00000000 <roundRobin>:
#include "param.h"
#include "mmu.h"
#include "proc.h"
#include "pstat.h"

void roundRobin(int timeslice, int iterations, char *job, int jobcount){
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	56                   	push   %esi
   4:	53                   	push   %ebx
   5:	8b 75 14             	mov    0x14(%ebp),%esi

  //  struct pstat *pstat;

    char **ptr = &job;

    for (int i = 0; i < jobcount; i++) {
   8:	bb 00 00 00 00       	mov    $0x0,%ebx
   d:	eb 08                	jmp    17 <roundRobin+0x17>
        int pid = fork2(3);
        //getpinfo(pstat);
        if (pid < 0){
            // TODO PRINT ERROR MESSAGE
            exit();
   f:	e8 48 02 00 00       	call   25c <exit>
    for (int i = 0; i < jobcount; i++) {
  14:	83 c3 01             	add    $0x1,%ebx
  17:	39 f3                	cmp    %esi,%ebx
  19:	7d 29                	jge    44 <roundRobin+0x44>
        int pid = fork2(3);
  1b:	83 ec 0c             	sub    $0xc,%esp
  1e:	6a 03                	push   $0x3
  20:	e8 e7 02 00 00       	call   30c <fork2>
        if (pid < 0){
  25:	83 c4 10             	add    $0x10,%esp
  28:	85 c0                	test   %eax,%eax
  2a:	78 e3                	js     f <roundRobin+0xf>
        } else if (pid == 0){
  2c:	85 c0                	test   %eax,%eax
  2e:	75 e4                	jne    14 <roundRobin+0x14>
            exec(job, ptr);
  30:	83 ec 08             	sub    $0x8,%esp
  33:	8d 45 10             	lea    0x10(%ebp),%eax
  36:	50                   	push   %eax
  37:	ff 75 10             	pushl  0x10(%ebp)
  3a:	e8 55 02 00 00       	call   294 <exec>
  3f:	83 c4 10             	add    $0x10,%esp
  42:	eb d0                	jmp    14 <roundRobin+0x14>

        }
    }
}
  44:	8d 65 f8             	lea    -0x8(%ebp),%esp
  47:	5b                   	pop    %ebx
  48:	5e                   	pop    %esi
  49:	5d                   	pop    %ebp
  4a:	c3                   	ret    

0000004b <main>:

int main(int argc, char *argv[]) {
  4b:	8d 4c 24 04          	lea    0x4(%esp),%ecx
  4f:	83 e4 f0             	and    $0xfffffff0,%esp
  52:	ff 71 fc             	pushl  -0x4(%ecx)
  55:	55                   	push   %ebp
  56:	89 e5                	mov    %esp,%ebp
  58:	57                   	push   %edi
  59:	56                   	push   %esi
  5a:	53                   	push   %ebx
  5b:	51                   	push   %ecx
  5c:	83 ec 18             	sub    $0x18,%esp
  5f:	8b 59 04             	mov    0x4(%ecx),%ebx
    if(argc != 5) {
  62:	83 39 05             	cmpl   $0x5,(%ecx)
  65:	74 05                	je     6c <main+0x21>
        // TODO: print error message
        exit();
  67:	e8 f0 01 00 00       	call   25c <exit>
    }

    int timeslice = atoi(argv[1]);
  6c:	83 ec 0c             	sub    $0xc,%esp
  6f:	ff 73 04             	pushl  0x4(%ebx)
  72:	e8 87 01 00 00       	call   1fe <atoi>
  77:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    int iterations = atoi(argv[2]);
  7a:	83 c4 04             	add    $0x4,%esp
  7d:	ff 73 08             	pushl  0x8(%ebx)
  80:	e8 79 01 00 00       	call   1fe <atoi>
  85:	89 c7                	mov    %eax,%edi
    char *job = malloc(sizeof(char) * (strlen(argv[3]) + 1));
  87:	83 c4 04             	add    $0x4,%esp
  8a:	ff 73 0c             	pushl  0xc(%ebx)
  8d:	e8 81 00 00 00       	call   113 <strlen>
  92:	83 c0 01             	add    $0x1,%eax
  95:	89 04 24             	mov    %eax,(%esp)
  98:	e8 42 05 00 00       	call   5df <malloc>
  9d:	89 c6                	mov    %eax,%esi
    strcpy(job, argv[3]);
  9f:	83 c4 08             	add    $0x8,%esp
  a2:	ff 73 0c             	pushl  0xc(%ebx)
  a5:	50                   	push   %eax
  a6:	e8 24 00 00 00       	call   cf <strcpy>
    int jobcount = atoi(argv[4]);
  ab:	83 c4 04             	add    $0x4,%esp
  ae:	ff 73 10             	pushl  0x10(%ebx)
  b1:	e8 48 01 00 00       	call   1fe <atoi>

    roundRobin(timeslice, iterations, job, jobcount);
  b6:	50                   	push   %eax
  b7:	56                   	push   %esi
  b8:	57                   	push   %edi
  b9:	ff 75 e4             	pushl  -0x1c(%ebp)
  bc:	e8 3f ff ff ff       	call   0 <roundRobin>
    free(job);
  c1:	83 c4 14             	add    $0x14,%esp
  c4:	56                   	push   %esi
  c5:	e8 55 04 00 00       	call   51f <free>
    exit();
  ca:	e8 8d 01 00 00       	call   25c <exit>

000000cf <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, const char *t)
{
  cf:	55                   	push   %ebp
  d0:	89 e5                	mov    %esp,%ebp
  d2:	53                   	push   %ebx
  d3:	8b 45 08             	mov    0x8(%ebp),%eax
  d6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  d9:	89 c2                	mov    %eax,%edx
  db:	0f b6 19             	movzbl (%ecx),%ebx
  de:	88 1a                	mov    %bl,(%edx)
  e0:	8d 52 01             	lea    0x1(%edx),%edx
  e3:	8d 49 01             	lea    0x1(%ecx),%ecx
  e6:	84 db                	test   %bl,%bl
  e8:	75 f1                	jne    db <strcpy+0xc>
    ;
  return os;
}
  ea:	5b                   	pop    %ebx
  eb:	5d                   	pop    %ebp
  ec:	c3                   	ret    

000000ed <strcmp>:

int
strcmp(const char *p, const char *q)
{
  ed:	55                   	push   %ebp
  ee:	89 e5                	mov    %esp,%ebp
  f0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  f3:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
  f6:	eb 06                	jmp    fe <strcmp+0x11>
    p++, q++;
  f8:	83 c1 01             	add    $0x1,%ecx
  fb:	83 c2 01             	add    $0x1,%edx
  while(*p && *p == *q)
  fe:	0f b6 01             	movzbl (%ecx),%eax
 101:	84 c0                	test   %al,%al
 103:	74 04                	je     109 <strcmp+0x1c>
 105:	3a 02                	cmp    (%edx),%al
 107:	74 ef                	je     f8 <strcmp+0xb>
  return (uchar)*p - (uchar)*q;
 109:	0f b6 c0             	movzbl %al,%eax
 10c:	0f b6 12             	movzbl (%edx),%edx
 10f:	29 d0                	sub    %edx,%eax
}
 111:	5d                   	pop    %ebp
 112:	c3                   	ret    

00000113 <strlen>:

uint
strlen(const char *s)
{
 113:	55                   	push   %ebp
 114:	89 e5                	mov    %esp,%ebp
 116:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
 119:	ba 00 00 00 00       	mov    $0x0,%edx
 11e:	eb 03                	jmp    123 <strlen+0x10>
 120:	83 c2 01             	add    $0x1,%edx
 123:	89 d0                	mov    %edx,%eax
 125:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
 129:	75 f5                	jne    120 <strlen+0xd>
    ;
  return n;
}
 12b:	5d                   	pop    %ebp
 12c:	c3                   	ret    

0000012d <memset>:

void*
memset(void *dst, int c, uint n)
{
 12d:	55                   	push   %ebp
 12e:	89 e5                	mov    %esp,%ebp
 130:	57                   	push   %edi
 131:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
 134:	89 d7                	mov    %edx,%edi
 136:	8b 4d 10             	mov    0x10(%ebp),%ecx
 139:	8b 45 0c             	mov    0xc(%ebp),%eax
 13c:	fc                   	cld    
 13d:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
 13f:	89 d0                	mov    %edx,%eax
 141:	5f                   	pop    %edi
 142:	5d                   	pop    %ebp
 143:	c3                   	ret    

00000144 <strchr>:

char*
strchr(const char *s, char c)
{
 144:	55                   	push   %ebp
 145:	89 e5                	mov    %esp,%ebp
 147:	8b 45 08             	mov    0x8(%ebp),%eax
 14a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 14e:	0f b6 10             	movzbl (%eax),%edx
 151:	84 d2                	test   %dl,%dl
 153:	74 09                	je     15e <strchr+0x1a>
    if(*s == c)
 155:	38 ca                	cmp    %cl,%dl
 157:	74 0a                	je     163 <strchr+0x1f>
  for(; *s; s++)
 159:	83 c0 01             	add    $0x1,%eax
 15c:	eb f0                	jmp    14e <strchr+0xa>
      return (char*)s;
  return 0;
 15e:	b8 00 00 00 00       	mov    $0x0,%eax
}
 163:	5d                   	pop    %ebp
 164:	c3                   	ret    

00000165 <gets>:

char*
gets(char *buf, int max)
{
 165:	55                   	push   %ebp
 166:	89 e5                	mov    %esp,%ebp
 168:	57                   	push   %edi
 169:	56                   	push   %esi
 16a:	53                   	push   %ebx
 16b:	83 ec 1c             	sub    $0x1c,%esp
 16e:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 171:	bb 00 00 00 00       	mov    $0x0,%ebx
 176:	8d 73 01             	lea    0x1(%ebx),%esi
 179:	3b 75 0c             	cmp    0xc(%ebp),%esi
 17c:	7d 2e                	jge    1ac <gets+0x47>
    cc = read(0, &c, 1);
 17e:	83 ec 04             	sub    $0x4,%esp
 181:	6a 01                	push   $0x1
 183:	8d 45 e7             	lea    -0x19(%ebp),%eax
 186:	50                   	push   %eax
 187:	6a 00                	push   $0x0
 189:	e8 e6 00 00 00       	call   274 <read>
    if(cc < 1)
 18e:	83 c4 10             	add    $0x10,%esp
 191:	85 c0                	test   %eax,%eax
 193:	7e 17                	jle    1ac <gets+0x47>
      break;
    buf[i++] = c;
 195:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 199:	88 04 1f             	mov    %al,(%edi,%ebx,1)
    if(c == '\n' || c == '\r')
 19c:	3c 0a                	cmp    $0xa,%al
 19e:	0f 94 c2             	sete   %dl
 1a1:	3c 0d                	cmp    $0xd,%al
 1a3:	0f 94 c0             	sete   %al
    buf[i++] = c;
 1a6:	89 f3                	mov    %esi,%ebx
    if(c == '\n' || c == '\r')
 1a8:	08 c2                	or     %al,%dl
 1aa:	74 ca                	je     176 <gets+0x11>
      break;
  }
  buf[i] = '\0';
 1ac:	c6 04 1f 00          	movb   $0x0,(%edi,%ebx,1)
  return buf;
}
 1b0:	89 f8                	mov    %edi,%eax
 1b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
 1b5:	5b                   	pop    %ebx
 1b6:	5e                   	pop    %esi
 1b7:	5f                   	pop    %edi
 1b8:	5d                   	pop    %ebp
 1b9:	c3                   	ret    

000001ba <stat>:

int
stat(const char *n, struct stat *st)
{
 1ba:	55                   	push   %ebp
 1bb:	89 e5                	mov    %esp,%ebp
 1bd:	56                   	push   %esi
 1be:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1bf:	83 ec 08             	sub    $0x8,%esp
 1c2:	6a 00                	push   $0x0
 1c4:	ff 75 08             	pushl  0x8(%ebp)
 1c7:	e8 d0 00 00 00       	call   29c <open>
  if(fd < 0)
 1cc:	83 c4 10             	add    $0x10,%esp
 1cf:	85 c0                	test   %eax,%eax
 1d1:	78 24                	js     1f7 <stat+0x3d>
 1d3:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 1d5:	83 ec 08             	sub    $0x8,%esp
 1d8:	ff 75 0c             	pushl  0xc(%ebp)
 1db:	50                   	push   %eax
 1dc:	e8 d3 00 00 00       	call   2b4 <fstat>
 1e1:	89 c6                	mov    %eax,%esi
  close(fd);
 1e3:	89 1c 24             	mov    %ebx,(%esp)
 1e6:	e8 99 00 00 00       	call   284 <close>
  return r;
 1eb:	83 c4 10             	add    $0x10,%esp
}
 1ee:	89 f0                	mov    %esi,%eax
 1f0:	8d 65 f8             	lea    -0x8(%ebp),%esp
 1f3:	5b                   	pop    %ebx
 1f4:	5e                   	pop    %esi
 1f5:	5d                   	pop    %ebp
 1f6:	c3                   	ret    
    return -1;
 1f7:	be ff ff ff ff       	mov    $0xffffffff,%esi
 1fc:	eb f0                	jmp    1ee <stat+0x34>

000001fe <atoi>:

int
atoi(const char *s)
{
 1fe:	55                   	push   %ebp
 1ff:	89 e5                	mov    %esp,%ebp
 201:	53                   	push   %ebx
 202:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  n = 0;
 205:	b8 00 00 00 00       	mov    $0x0,%eax
  while('0' <= *s && *s <= '9')
 20a:	eb 10                	jmp    21c <atoi+0x1e>
    n = n*10 + *s++ - '0';
 20c:	8d 1c 80             	lea    (%eax,%eax,4),%ebx
 20f:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
 212:	83 c1 01             	add    $0x1,%ecx
 215:	0f be d2             	movsbl %dl,%edx
 218:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
  while('0' <= *s && *s <= '9')
 21c:	0f b6 11             	movzbl (%ecx),%edx
 21f:	8d 5a d0             	lea    -0x30(%edx),%ebx
 222:	80 fb 09             	cmp    $0x9,%bl
 225:	76 e5                	jbe    20c <atoi+0xe>
  return n;
}
 227:	5b                   	pop    %ebx
 228:	5d                   	pop    %ebp
 229:	c3                   	ret    

0000022a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 22a:	55                   	push   %ebp
 22b:	89 e5                	mov    %esp,%ebp
 22d:	56                   	push   %esi
 22e:	53                   	push   %ebx
 22f:	8b 45 08             	mov    0x8(%ebp),%eax
 232:	8b 5d 0c             	mov    0xc(%ebp),%ebx
 235:	8b 55 10             	mov    0x10(%ebp),%edx
  char *dst;
  const char *src;

  dst = vdst;
 238:	89 c1                	mov    %eax,%ecx
  src = vsrc;
  while(n-- > 0)
 23a:	eb 0d                	jmp    249 <memmove+0x1f>
    *dst++ = *src++;
 23c:	0f b6 13             	movzbl (%ebx),%edx
 23f:	88 11                	mov    %dl,(%ecx)
 241:	8d 5b 01             	lea    0x1(%ebx),%ebx
 244:	8d 49 01             	lea    0x1(%ecx),%ecx
  while(n-- > 0)
 247:	89 f2                	mov    %esi,%edx
 249:	8d 72 ff             	lea    -0x1(%edx),%esi
 24c:	85 d2                	test   %edx,%edx
 24e:	7f ec                	jg     23c <memmove+0x12>
  return vdst;
}
 250:	5b                   	pop    %ebx
 251:	5e                   	pop    %esi
 252:	5d                   	pop    %ebp
 253:	c3                   	ret    

00000254 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 254:	b8 01 00 00 00       	mov    $0x1,%eax
 259:	cd 40                	int    $0x40
 25b:	c3                   	ret    

0000025c <exit>:
SYSCALL(exit)
 25c:	b8 02 00 00 00       	mov    $0x2,%eax
 261:	cd 40                	int    $0x40
 263:	c3                   	ret    

00000264 <wait>:
SYSCALL(wait)
 264:	b8 03 00 00 00       	mov    $0x3,%eax
 269:	cd 40                	int    $0x40
 26b:	c3                   	ret    

0000026c <pipe>:
SYSCALL(pipe)
 26c:	b8 04 00 00 00       	mov    $0x4,%eax
 271:	cd 40                	int    $0x40
 273:	c3                   	ret    

00000274 <read>:
SYSCALL(read)
 274:	b8 05 00 00 00       	mov    $0x5,%eax
 279:	cd 40                	int    $0x40
 27b:	c3                   	ret    

0000027c <write>:
SYSCALL(write)
 27c:	b8 10 00 00 00       	mov    $0x10,%eax
 281:	cd 40                	int    $0x40
 283:	c3                   	ret    

00000284 <close>:
SYSCALL(close)
 284:	b8 15 00 00 00       	mov    $0x15,%eax
 289:	cd 40                	int    $0x40
 28b:	c3                   	ret    

0000028c <kill>:
SYSCALL(kill)
 28c:	b8 06 00 00 00       	mov    $0x6,%eax
 291:	cd 40                	int    $0x40
 293:	c3                   	ret    

00000294 <exec>:
SYSCALL(exec)
 294:	b8 07 00 00 00       	mov    $0x7,%eax
 299:	cd 40                	int    $0x40
 29b:	c3                   	ret    

0000029c <open>:
SYSCALL(open)
 29c:	b8 0f 00 00 00       	mov    $0xf,%eax
 2a1:	cd 40                	int    $0x40
 2a3:	c3                   	ret    

000002a4 <mknod>:
SYSCALL(mknod)
 2a4:	b8 11 00 00 00       	mov    $0x11,%eax
 2a9:	cd 40                	int    $0x40
 2ab:	c3                   	ret    

000002ac <unlink>:
SYSCALL(unlink)
 2ac:	b8 12 00 00 00       	mov    $0x12,%eax
 2b1:	cd 40                	int    $0x40
 2b3:	c3                   	ret    

000002b4 <fstat>:
SYSCALL(fstat)
 2b4:	b8 08 00 00 00       	mov    $0x8,%eax
 2b9:	cd 40                	int    $0x40
 2bb:	c3                   	ret    

000002bc <link>:
SYSCALL(link)
 2bc:	b8 13 00 00 00       	mov    $0x13,%eax
 2c1:	cd 40                	int    $0x40
 2c3:	c3                   	ret    

000002c4 <mkdir>:
SYSCALL(mkdir)
 2c4:	b8 14 00 00 00       	mov    $0x14,%eax
 2c9:	cd 40                	int    $0x40
 2cb:	c3                   	ret    

000002cc <chdir>:
SYSCALL(chdir)
 2cc:	b8 09 00 00 00       	mov    $0x9,%eax
 2d1:	cd 40                	int    $0x40
 2d3:	c3                   	ret    

000002d4 <dup>:
SYSCALL(dup)
 2d4:	b8 0a 00 00 00       	mov    $0xa,%eax
 2d9:	cd 40                	int    $0x40
 2db:	c3                   	ret    

000002dc <getpid>:
SYSCALL(getpid)
 2dc:	b8 0b 00 00 00       	mov    $0xb,%eax
 2e1:	cd 40                	int    $0x40
 2e3:	c3                   	ret    

000002e4 <sbrk>:
SYSCALL(sbrk)
 2e4:	b8 0c 00 00 00       	mov    $0xc,%eax
 2e9:	cd 40                	int    $0x40
 2eb:	c3                   	ret    

000002ec <sleep>:
SYSCALL(sleep)
 2ec:	b8 0d 00 00 00       	mov    $0xd,%eax
 2f1:	cd 40                	int    $0x40
 2f3:	c3                   	ret    

000002f4 <uptime>:
SYSCALL(uptime)
 2f4:	b8 0e 00 00 00       	mov    $0xe,%eax
 2f9:	cd 40                	int    $0x40
 2fb:	c3                   	ret    

000002fc <setpri>:
// adding sys calls
SYSCALL(setpri)
 2fc:	b8 16 00 00 00       	mov    $0x16,%eax
 301:	cd 40                	int    $0x40
 303:	c3                   	ret    

00000304 <getpri>:
SYSCALL(getpri)
 304:	b8 17 00 00 00       	mov    $0x17,%eax
 309:	cd 40                	int    $0x40
 30b:	c3                   	ret    

0000030c <fork2>:
SYSCALL(fork2)
 30c:	b8 18 00 00 00       	mov    $0x18,%eax
 311:	cd 40                	int    $0x40
 313:	c3                   	ret    

00000314 <getpinfo>:
SYSCALL(getpinfo)
 314:	b8 19 00 00 00       	mov    $0x19,%eax
 319:	cd 40                	int    $0x40
 31b:	c3                   	ret    

0000031c <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 31c:	55                   	push   %ebp
 31d:	89 e5                	mov    %esp,%ebp
 31f:	83 ec 1c             	sub    $0x1c,%esp
 322:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 325:	6a 01                	push   $0x1
 327:	8d 55 f4             	lea    -0xc(%ebp),%edx
 32a:	52                   	push   %edx
 32b:	50                   	push   %eax
 32c:	e8 4b ff ff ff       	call   27c <write>
}
 331:	83 c4 10             	add    $0x10,%esp
 334:	c9                   	leave  
 335:	c3                   	ret    

00000336 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 336:	55                   	push   %ebp
 337:	89 e5                	mov    %esp,%ebp
 339:	57                   	push   %edi
 33a:	56                   	push   %esi
 33b:	53                   	push   %ebx
 33c:	83 ec 2c             	sub    $0x2c,%esp
 33f:	89 c7                	mov    %eax,%edi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 341:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 345:	0f 95 c3             	setne  %bl
 348:	89 d0                	mov    %edx,%eax
 34a:	c1 e8 1f             	shr    $0x1f,%eax
 34d:	84 c3                	test   %al,%bl
 34f:	74 10                	je     361 <printint+0x2b>
    neg = 1;
    x = -xx;
 351:	f7 da                	neg    %edx
    neg = 1;
 353:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 35a:	be 00 00 00 00       	mov    $0x0,%esi
 35f:	eb 0b                	jmp    36c <printint+0x36>
  neg = 0;
 361:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 368:	eb f0                	jmp    35a <printint+0x24>
  do{
    buf[i++] = digits[x % base];
 36a:	89 c6                	mov    %eax,%esi
 36c:	89 d0                	mov    %edx,%eax
 36e:	ba 00 00 00 00       	mov    $0x0,%edx
 373:	f7 f1                	div    %ecx
 375:	89 c3                	mov    %eax,%ebx
 377:	8d 46 01             	lea    0x1(%esi),%eax
 37a:	0f b6 92 78 06 00 00 	movzbl 0x678(%edx),%edx
 381:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
 385:	89 da                	mov    %ebx,%edx
 387:	85 db                	test   %ebx,%ebx
 389:	75 df                	jne    36a <printint+0x34>
 38b:	89 c3                	mov    %eax,%ebx
  if(neg)
 38d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 391:	74 16                	je     3a9 <printint+0x73>
    buf[i++] = '-';
 393:	c6 44 05 d8 2d       	movb   $0x2d,-0x28(%ebp,%eax,1)
 398:	8d 5e 02             	lea    0x2(%esi),%ebx
 39b:	eb 0c                	jmp    3a9 <printint+0x73>

  while(--i >= 0)
    putc(fd, buf[i]);
 39d:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 3a2:	89 f8                	mov    %edi,%eax
 3a4:	e8 73 ff ff ff       	call   31c <putc>
  while(--i >= 0)
 3a9:	83 eb 01             	sub    $0x1,%ebx
 3ac:	79 ef                	jns    39d <printint+0x67>
}
 3ae:	83 c4 2c             	add    $0x2c,%esp
 3b1:	5b                   	pop    %ebx
 3b2:	5e                   	pop    %esi
 3b3:	5f                   	pop    %edi
 3b4:	5d                   	pop    %ebp
 3b5:	c3                   	ret    

000003b6 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, const char *fmt, ...)
{
 3b6:	55                   	push   %ebp
 3b7:	89 e5                	mov    %esp,%ebp
 3b9:	57                   	push   %edi
 3ba:	56                   	push   %esi
 3bb:	53                   	push   %ebx
 3bc:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 3bf:	8d 45 10             	lea    0x10(%ebp),%eax
 3c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 3c5:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 3ca:	bb 00 00 00 00       	mov    $0x0,%ebx
 3cf:	eb 14                	jmp    3e5 <printf+0x2f>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 3d1:	89 fa                	mov    %edi,%edx
 3d3:	8b 45 08             	mov    0x8(%ebp),%eax
 3d6:	e8 41 ff ff ff       	call   31c <putc>
 3db:	eb 05                	jmp    3e2 <printf+0x2c>
      }
    } else if(state == '%'){
 3dd:	83 fe 25             	cmp    $0x25,%esi
 3e0:	74 25                	je     407 <printf+0x51>
  for(i = 0; fmt[i]; i++){
 3e2:	83 c3 01             	add    $0x1,%ebx
 3e5:	8b 45 0c             	mov    0xc(%ebp),%eax
 3e8:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 3ec:	84 c0                	test   %al,%al
 3ee:	0f 84 23 01 00 00    	je     517 <printf+0x161>
    c = fmt[i] & 0xff;
 3f4:	0f be f8             	movsbl %al,%edi
 3f7:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 3fa:	85 f6                	test   %esi,%esi
 3fc:	75 df                	jne    3dd <printf+0x27>
      if(c == '%'){
 3fe:	83 f8 25             	cmp    $0x25,%eax
 401:	75 ce                	jne    3d1 <printf+0x1b>
        state = '%';
 403:	89 c6                	mov    %eax,%esi
 405:	eb db                	jmp    3e2 <printf+0x2c>
      if(c == 'd'){
 407:	83 f8 64             	cmp    $0x64,%eax
 40a:	74 49                	je     455 <printf+0x9f>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 40c:	83 f8 78             	cmp    $0x78,%eax
 40f:	0f 94 c1             	sete   %cl
 412:	83 f8 70             	cmp    $0x70,%eax
 415:	0f 94 c2             	sete   %dl
 418:	08 d1                	or     %dl,%cl
 41a:	75 63                	jne    47f <printf+0xc9>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 41c:	83 f8 73             	cmp    $0x73,%eax
 41f:	0f 84 84 00 00 00    	je     4a9 <printf+0xf3>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 425:	83 f8 63             	cmp    $0x63,%eax
 428:	0f 84 b7 00 00 00    	je     4e5 <printf+0x12f>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 42e:	83 f8 25             	cmp    $0x25,%eax
 431:	0f 84 cc 00 00 00    	je     503 <printf+0x14d>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 437:	ba 25 00 00 00       	mov    $0x25,%edx
 43c:	8b 45 08             	mov    0x8(%ebp),%eax
 43f:	e8 d8 fe ff ff       	call   31c <putc>
        putc(fd, c);
 444:	89 fa                	mov    %edi,%edx
 446:	8b 45 08             	mov    0x8(%ebp),%eax
 449:	e8 ce fe ff ff       	call   31c <putc>
      }
      state = 0;
 44e:	be 00 00 00 00       	mov    $0x0,%esi
 453:	eb 8d                	jmp    3e2 <printf+0x2c>
        printint(fd, *ap, 10, 1);
 455:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 458:	8b 17                	mov    (%edi),%edx
 45a:	83 ec 0c             	sub    $0xc,%esp
 45d:	6a 01                	push   $0x1
 45f:	b9 0a 00 00 00       	mov    $0xa,%ecx
 464:	8b 45 08             	mov    0x8(%ebp),%eax
 467:	e8 ca fe ff ff       	call   336 <printint>
        ap++;
 46c:	83 c7 04             	add    $0x4,%edi
 46f:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 472:	83 c4 10             	add    $0x10,%esp
      state = 0;
 475:	be 00 00 00 00       	mov    $0x0,%esi
 47a:	e9 63 ff ff ff       	jmp    3e2 <printf+0x2c>
        printint(fd, *ap, 16, 0);
 47f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 482:	8b 17                	mov    (%edi),%edx
 484:	83 ec 0c             	sub    $0xc,%esp
 487:	6a 00                	push   $0x0
 489:	b9 10 00 00 00       	mov    $0x10,%ecx
 48e:	8b 45 08             	mov    0x8(%ebp),%eax
 491:	e8 a0 fe ff ff       	call   336 <printint>
        ap++;
 496:	83 c7 04             	add    $0x4,%edi
 499:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 49c:	83 c4 10             	add    $0x10,%esp
      state = 0;
 49f:	be 00 00 00 00       	mov    $0x0,%esi
 4a4:	e9 39 ff ff ff       	jmp    3e2 <printf+0x2c>
        s = (char*)*ap;
 4a9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 4ac:	8b 30                	mov    (%eax),%esi
        ap++;
 4ae:	83 c0 04             	add    $0x4,%eax
 4b1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 4b4:	85 f6                	test   %esi,%esi
 4b6:	75 28                	jne    4e0 <printf+0x12a>
          s = "(null)";
 4b8:	be 70 06 00 00       	mov    $0x670,%esi
 4bd:	8b 7d 08             	mov    0x8(%ebp),%edi
 4c0:	eb 0d                	jmp    4cf <printf+0x119>
          putc(fd, *s);
 4c2:	0f be d2             	movsbl %dl,%edx
 4c5:	89 f8                	mov    %edi,%eax
 4c7:	e8 50 fe ff ff       	call   31c <putc>
          s++;
 4cc:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 4cf:	0f b6 16             	movzbl (%esi),%edx
 4d2:	84 d2                	test   %dl,%dl
 4d4:	75 ec                	jne    4c2 <printf+0x10c>
      state = 0;
 4d6:	be 00 00 00 00       	mov    $0x0,%esi
 4db:	e9 02 ff ff ff       	jmp    3e2 <printf+0x2c>
 4e0:	8b 7d 08             	mov    0x8(%ebp),%edi
 4e3:	eb ea                	jmp    4cf <printf+0x119>
        putc(fd, *ap);
 4e5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 4e8:	0f be 17             	movsbl (%edi),%edx
 4eb:	8b 45 08             	mov    0x8(%ebp),%eax
 4ee:	e8 29 fe ff ff       	call   31c <putc>
        ap++;
 4f3:	83 c7 04             	add    $0x4,%edi
 4f6:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 4f9:	be 00 00 00 00       	mov    $0x0,%esi
 4fe:	e9 df fe ff ff       	jmp    3e2 <printf+0x2c>
        putc(fd, c);
 503:	89 fa                	mov    %edi,%edx
 505:	8b 45 08             	mov    0x8(%ebp),%eax
 508:	e8 0f fe ff ff       	call   31c <putc>
      state = 0;
 50d:	be 00 00 00 00       	mov    $0x0,%esi
 512:	e9 cb fe ff ff       	jmp    3e2 <printf+0x2c>
    }
  }
}
 517:	8d 65 f4             	lea    -0xc(%ebp),%esp
 51a:	5b                   	pop    %ebx
 51b:	5e                   	pop    %esi
 51c:	5f                   	pop    %edi
 51d:	5d                   	pop    %ebp
 51e:	c3                   	ret    

0000051f <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 51f:	55                   	push   %ebp
 520:	89 e5                	mov    %esp,%ebp
 522:	57                   	push   %edi
 523:	56                   	push   %esi
 524:	53                   	push   %ebx
 525:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 528:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 52b:	a1 44 09 00 00       	mov    0x944,%eax
 530:	eb 02                	jmp    534 <free+0x15>
 532:	89 d0                	mov    %edx,%eax
 534:	39 c8                	cmp    %ecx,%eax
 536:	73 04                	jae    53c <free+0x1d>
 538:	39 08                	cmp    %ecx,(%eax)
 53a:	77 12                	ja     54e <free+0x2f>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 53c:	8b 10                	mov    (%eax),%edx
 53e:	39 c2                	cmp    %eax,%edx
 540:	77 f0                	ja     532 <free+0x13>
 542:	39 c8                	cmp    %ecx,%eax
 544:	72 08                	jb     54e <free+0x2f>
 546:	39 ca                	cmp    %ecx,%edx
 548:	77 04                	ja     54e <free+0x2f>
 54a:	89 d0                	mov    %edx,%eax
 54c:	eb e6                	jmp    534 <free+0x15>
      break;
  if(bp + bp->s.size == p->s.ptr){
 54e:	8b 73 fc             	mov    -0x4(%ebx),%esi
 551:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 554:	8b 10                	mov    (%eax),%edx
 556:	39 d7                	cmp    %edx,%edi
 558:	74 19                	je     573 <free+0x54>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 55a:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 55d:	8b 50 04             	mov    0x4(%eax),%edx
 560:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 563:	39 ce                	cmp    %ecx,%esi
 565:	74 1b                	je     582 <free+0x63>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 567:	89 08                	mov    %ecx,(%eax)
  freep = p;
 569:	a3 44 09 00 00       	mov    %eax,0x944
}
 56e:	5b                   	pop    %ebx
 56f:	5e                   	pop    %esi
 570:	5f                   	pop    %edi
 571:	5d                   	pop    %ebp
 572:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 573:	03 72 04             	add    0x4(%edx),%esi
 576:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 579:	8b 10                	mov    (%eax),%edx
 57b:	8b 12                	mov    (%edx),%edx
 57d:	89 53 f8             	mov    %edx,-0x8(%ebx)
 580:	eb db                	jmp    55d <free+0x3e>
    p->s.size += bp->s.size;
 582:	03 53 fc             	add    -0x4(%ebx),%edx
 585:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 588:	8b 53 f8             	mov    -0x8(%ebx),%edx
 58b:	89 10                	mov    %edx,(%eax)
 58d:	eb da                	jmp    569 <free+0x4a>

0000058f <morecore>:

static Header*
morecore(uint nu)
{
 58f:	55                   	push   %ebp
 590:	89 e5                	mov    %esp,%ebp
 592:	53                   	push   %ebx
 593:	83 ec 04             	sub    $0x4,%esp
 596:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 598:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 59d:	77 05                	ja     5a4 <morecore+0x15>
    nu = 4096;
 59f:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 5a4:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 5ab:	83 ec 0c             	sub    $0xc,%esp
 5ae:	50                   	push   %eax
 5af:	e8 30 fd ff ff       	call   2e4 <sbrk>
  if(p == (char*)-1)
 5b4:	83 c4 10             	add    $0x10,%esp
 5b7:	83 f8 ff             	cmp    $0xffffffff,%eax
 5ba:	74 1c                	je     5d8 <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 5bc:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 5bf:	83 c0 08             	add    $0x8,%eax
 5c2:	83 ec 0c             	sub    $0xc,%esp
 5c5:	50                   	push   %eax
 5c6:	e8 54 ff ff ff       	call   51f <free>
  return freep;
 5cb:	a1 44 09 00 00       	mov    0x944,%eax
 5d0:	83 c4 10             	add    $0x10,%esp
}
 5d3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 5d6:	c9                   	leave  
 5d7:	c3                   	ret    
    return 0;
 5d8:	b8 00 00 00 00       	mov    $0x0,%eax
 5dd:	eb f4                	jmp    5d3 <morecore+0x44>

000005df <malloc>:

void*
malloc(uint nbytes)
{
 5df:	55                   	push   %ebp
 5e0:	89 e5                	mov    %esp,%ebp
 5e2:	53                   	push   %ebx
 5e3:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 5e6:	8b 45 08             	mov    0x8(%ebp),%eax
 5e9:	8d 58 07             	lea    0x7(%eax),%ebx
 5ec:	c1 eb 03             	shr    $0x3,%ebx
 5ef:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 5f2:	8b 0d 44 09 00 00    	mov    0x944,%ecx
 5f8:	85 c9                	test   %ecx,%ecx
 5fa:	74 04                	je     600 <malloc+0x21>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 5fc:	8b 01                	mov    (%ecx),%eax
 5fe:	eb 4d                	jmp    64d <malloc+0x6e>
    base.s.ptr = freep = prevp = &base;
 600:	c7 05 44 09 00 00 48 	movl   $0x948,0x944
 607:	09 00 00 
 60a:	c7 05 48 09 00 00 48 	movl   $0x948,0x948
 611:	09 00 00 
    base.s.size = 0;
 614:	c7 05 4c 09 00 00 00 	movl   $0x0,0x94c
 61b:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 61e:	b9 48 09 00 00       	mov    $0x948,%ecx
 623:	eb d7                	jmp    5fc <malloc+0x1d>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 625:	39 da                	cmp    %ebx,%edx
 627:	74 1a                	je     643 <malloc+0x64>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 629:	29 da                	sub    %ebx,%edx
 62b:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 62e:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 631:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 634:	89 0d 44 09 00 00    	mov    %ecx,0x944
      return (void*)(p + 1);
 63a:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 63d:	83 c4 04             	add    $0x4,%esp
 640:	5b                   	pop    %ebx
 641:	5d                   	pop    %ebp
 642:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 643:	8b 10                	mov    (%eax),%edx
 645:	89 11                	mov    %edx,(%ecx)
 647:	eb eb                	jmp    634 <malloc+0x55>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 649:	89 c1                	mov    %eax,%ecx
 64b:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 64d:	8b 50 04             	mov    0x4(%eax),%edx
 650:	39 da                	cmp    %ebx,%edx
 652:	73 d1                	jae    625 <malloc+0x46>
    if(p == freep)
 654:	39 05 44 09 00 00    	cmp    %eax,0x944
 65a:	75 ed                	jne    649 <malloc+0x6a>
      if((p = morecore(nunits)) == 0)
 65c:	89 d8                	mov    %ebx,%eax
 65e:	e8 2c ff ff ff       	call   58f <morecore>
 663:	85 c0                	test   %eax,%eax
 665:	75 e2                	jne    649 <malloc+0x6a>
        return 0;
 667:	b8 00 00 00 00       	mov    $0x0,%eax
 66c:	eb cf                	jmp    63d <malloc+0x5e>
