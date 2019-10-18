
_userRR:     file format elf32-i386


Disassembly of section .text:

00000000 <roundRobin>:
#include "proc.h"
#include "pstat.h"

int status;

void roundRobin(int timeslice, int iterations, char *job, int jobcount){
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	57                   	push   %edi
   4:	56                   	push   %esi
   5:	53                   	push   %ebx
   6:	83 ec 18             	sub    $0x18,%esp
   9:	8b 7d 14             	mov    0x14(%ebp),%edi

  //  struct pstat *pstat;


    char **ptr = &job;
    struct pstat *pstat = malloc(sizeof(struct pstat));
   c:	68 00 0c 00 00       	push   $0xc00
  11:	e8 73 06 00 00       	call   689 <malloc>
  16:	89 c6                	mov    %eax,%esi
    int jcount = 0;

    while ( jcount < jobcount ) {
  18:	83 c4 10             	add    $0x10,%esp
    int jcount = 0;
  1b:	bb 00 00 00 00       	mov    $0x0,%ebx
    while ( jcount < jobcount ) {
  20:	eb 08                	jmp    2a <roundRobin+0x2a>
        int pid = fork2(2);
        if (pid < 0) {
            exit();
  22:	e8 df 02 00 00       	call   306 <exit>
        } else if (pid == 0) {
            exec(job, ptr);
        } else if (pid > 0) {
            // getpinfo(pstat);
        }
        jcount++;
  27:	83 c3 01             	add    $0x1,%ebx
    while ( jcount < jobcount ) {
  2a:	39 fb                	cmp    %edi,%ebx
  2c:	7d 29                	jge    57 <roundRobin+0x57>
        int pid = fork2(2);
  2e:	83 ec 0c             	sub    $0xc,%esp
  31:	6a 02                	push   $0x2
  33:	e8 7e 03 00 00       	call   3b6 <fork2>
        if (pid < 0) {
  38:	83 c4 10             	add    $0x10,%esp
  3b:	85 c0                	test   %eax,%eax
  3d:	78 e3                	js     22 <roundRobin+0x22>
        } else if (pid == 0) {
  3f:	85 c0                	test   %eax,%eax
  41:	75 e4                	jne    27 <roundRobin+0x27>
            exec(job, ptr);
  43:	83 ec 08             	sub    $0x8,%esp
  46:	8d 45 10             	lea    0x10(%ebp),%eax
  49:	50                   	push   %eax
  4a:	ff 75 10             	pushl  0x10(%ebp)
  4d:	e8 ec 02 00 00       	call   33e <exec>
  52:	83 c4 10             	add    $0x10,%esp
  55:	eb d0                	jmp    27 <roundRobin+0x27>
    }

    for (int i = 0; i < iterations; i++){
  57:	bf 00 00 00 00       	mov    $0x0,%edi
  5c:	eb 39                	jmp    97 <roundRobin+0x97>
        getpinfo(pstat);
        for(int j = 0; j < NPROC; j++) {
  5e:	83 c3 01             	add    $0x1,%ebx
  61:	83 fb 3f             	cmp    $0x3f,%ebx
  64:	7f 20                	jg     86 <roundRobin+0x86>
            if (pstat->priority[j] == 2) {
  66:	83 bc 9e 00 02 00 00 	cmpl   $0x2,0x200(%esi,%ebx,4)
  6d:	02 
  6e:	75 ee                	jne    5e <roundRobin+0x5e>
                setpri(pstat->pid[j], 3);
  70:	83 ec 08             	sub    $0x8,%esp
  73:	6a 03                	push   $0x3
  75:	ff b4 9e 00 01 00 00 	pushl  0x100(%esi,%ebx,4)
  7c:	e8 25 03 00 00       	call   3a6 <setpri>
  81:	83 c4 10             	add    $0x10,%esp
  84:	eb d8                	jmp    5e <roundRobin+0x5e>
            }
        }

        sleep(timeslice);
  86:	83 ec 0c             	sub    $0xc,%esp
  89:	ff 75 08             	pushl  0x8(%ebp)
  8c:	e8 05 03 00 00       	call   396 <sleep>
    for (int i = 0; i < iterations; i++){
  91:	83 c7 01             	add    $0x1,%edi
  94:	83 c4 10             	add    $0x10,%esp
  97:	3b 7d 0c             	cmp    0xc(%ebp),%edi
  9a:	7d 13                	jge    af <roundRobin+0xaf>
        getpinfo(pstat);
  9c:	83 ec 0c             	sub    $0xc,%esp
  9f:	56                   	push   %esi
  a0:	e8 19 03 00 00       	call   3be <getpinfo>
        for(int j = 0; j < NPROC; j++) {
  a5:	83 c4 10             	add    $0x10,%esp
  a8:	bb 00 00 00 00       	mov    $0x0,%ebx
  ad:	eb b2                	jmp    61 <roundRobin+0x61>
    }

    getpinfo(pstat);
  af:	83 ec 0c             	sub    $0xc,%esp
  b2:	56                   	push   %esi
  b3:	e8 06 03 00 00       	call   3be <getpinfo>
    for (int i = 0; i < NPROC; i++) {
  b8:	83 c4 10             	add    $0x10,%esp
  bb:	bb 00 00 00 00       	mov    $0x0,%ebx
  c0:	eb 03                	jmp    c5 <roundRobin+0xc5>
  c2:	83 c3 01             	add    $0x1,%ebx
  c5:	83 fb 3f             	cmp    $0x3f,%ebx
  c8:	7f 23                	jg     ed <roundRobin+0xed>
        if (pstat->state[i] == ZOMBIE) {
  ca:	83 bc 9e 00 03 00 00 	cmpl   $0x5,0x300(%esi,%ebx,4)
  d1:	05 
  d2:	75 ee                	jne    c2 <roundRobin+0xc2>
            //printf(1, "%s\n", "entered");
            wait();
  d4:	e8 35 02 00 00       	call   30e <wait>
            kill(pstat->pid[i]);
  d9:	83 ec 0c             	sub    $0xc,%esp
  dc:	ff b4 9e 00 01 00 00 	pushl  0x100(%esi,%ebx,4)
  e3:	e8 4e 02 00 00       	call   336 <kill>
  e8:	83 c4 10             	add    $0x10,%esp
  eb:	eb d5                	jmp    c2 <roundRobin+0xc2>
        }
    }


}
  ed:	8d 65 f4             	lea    -0xc(%ebp),%esp
  f0:	5b                   	pop    %ebx
  f1:	5e                   	pop    %esi
  f2:	5f                   	pop    %edi
  f3:	5d                   	pop    %ebp
  f4:	c3                   	ret    

000000f5 <main>:

int main(int argc, char *argv[]) {
  f5:	8d 4c 24 04          	lea    0x4(%esp),%ecx
  f9:	83 e4 f0             	and    $0xfffffff0,%esp
  fc:	ff 71 fc             	pushl  -0x4(%ecx)
  ff:	55                   	push   %ebp
 100:	89 e5                	mov    %esp,%ebp
 102:	57                   	push   %edi
 103:	56                   	push   %esi
 104:	53                   	push   %ebx
 105:	51                   	push   %ecx
 106:	83 ec 18             	sub    $0x18,%esp
 109:	8b 59 04             	mov    0x4(%ecx),%ebx
    if(argc != 5) {
 10c:	83 39 05             	cmpl   $0x5,(%ecx)
 10f:	74 05                	je     116 <main+0x21>
        // TODO: print error message
        exit();
 111:	e8 f0 01 00 00       	call   306 <exit>
    }

    int timeslice = atoi(argv[1]);
 116:	83 ec 0c             	sub    $0xc,%esp
 119:	ff 73 04             	pushl  0x4(%ebx)
 11c:	e8 87 01 00 00       	call   2a8 <atoi>
 121:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    int iterations = atoi(argv[2]);
 124:	83 c4 04             	add    $0x4,%esp
 127:	ff 73 08             	pushl  0x8(%ebx)
 12a:	e8 79 01 00 00       	call   2a8 <atoi>
 12f:	89 c7                	mov    %eax,%edi
    char *job = malloc(sizeof(char) * (strlen(argv[3]) + 1));
 131:	83 c4 04             	add    $0x4,%esp
 134:	ff 73 0c             	pushl  0xc(%ebx)
 137:	e8 81 00 00 00       	call   1bd <strlen>
 13c:	83 c0 01             	add    $0x1,%eax
 13f:	89 04 24             	mov    %eax,(%esp)
 142:	e8 42 05 00 00       	call   689 <malloc>
 147:	89 c6                	mov    %eax,%esi
    strcpy(job, argv[3]);
 149:	83 c4 08             	add    $0x8,%esp
 14c:	ff 73 0c             	pushl  0xc(%ebx)
 14f:	50                   	push   %eax
 150:	e8 24 00 00 00       	call   179 <strcpy>
    int jobcount = atoi(argv[4]);
 155:	83 c4 04             	add    $0x4,%esp
 158:	ff 73 10             	pushl  0x10(%ebx)
 15b:	e8 48 01 00 00       	call   2a8 <atoi>

    roundRobin(timeslice, iterations, job, jobcount);
 160:	50                   	push   %eax
 161:	56                   	push   %esi
 162:	57                   	push   %edi
 163:	ff 75 e4             	pushl  -0x1c(%ebp)
 166:	e8 95 fe ff ff       	call   0 <roundRobin>
    free(job);
 16b:	83 c4 14             	add    $0x14,%esp
 16e:	56                   	push   %esi
 16f:	e8 55 04 00 00       	call   5c9 <free>
    exit();
 174:	e8 8d 01 00 00       	call   306 <exit>

00000179 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, const char *t)
{
 179:	55                   	push   %ebp
 17a:	89 e5                	mov    %esp,%ebp
 17c:	53                   	push   %ebx
 17d:	8b 45 08             	mov    0x8(%ebp),%eax
 180:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 183:	89 c2                	mov    %eax,%edx
 185:	0f b6 19             	movzbl (%ecx),%ebx
 188:	88 1a                	mov    %bl,(%edx)
 18a:	8d 52 01             	lea    0x1(%edx),%edx
 18d:	8d 49 01             	lea    0x1(%ecx),%ecx
 190:	84 db                	test   %bl,%bl
 192:	75 f1                	jne    185 <strcpy+0xc>
    ;
  return os;
}
 194:	5b                   	pop    %ebx
 195:	5d                   	pop    %ebp
 196:	c3                   	ret    

00000197 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 197:	55                   	push   %ebp
 198:	89 e5                	mov    %esp,%ebp
 19a:	8b 4d 08             	mov    0x8(%ebp),%ecx
 19d:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
 1a0:	eb 06                	jmp    1a8 <strcmp+0x11>
    p++, q++;
 1a2:	83 c1 01             	add    $0x1,%ecx
 1a5:	83 c2 01             	add    $0x1,%edx
  while(*p && *p == *q)
 1a8:	0f b6 01             	movzbl (%ecx),%eax
 1ab:	84 c0                	test   %al,%al
 1ad:	74 04                	je     1b3 <strcmp+0x1c>
 1af:	3a 02                	cmp    (%edx),%al
 1b1:	74 ef                	je     1a2 <strcmp+0xb>
  return (uchar)*p - (uchar)*q;
 1b3:	0f b6 c0             	movzbl %al,%eax
 1b6:	0f b6 12             	movzbl (%edx),%edx
 1b9:	29 d0                	sub    %edx,%eax
}
 1bb:	5d                   	pop    %ebp
 1bc:	c3                   	ret    

000001bd <strlen>:

uint
strlen(const char *s)
{
 1bd:	55                   	push   %ebp
 1be:	89 e5                	mov    %esp,%ebp
 1c0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
 1c3:	ba 00 00 00 00       	mov    $0x0,%edx
 1c8:	eb 03                	jmp    1cd <strlen+0x10>
 1ca:	83 c2 01             	add    $0x1,%edx
 1cd:	89 d0                	mov    %edx,%eax
 1cf:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
 1d3:	75 f5                	jne    1ca <strlen+0xd>
    ;
  return n;
}
 1d5:	5d                   	pop    %ebp
 1d6:	c3                   	ret    

000001d7 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1d7:	55                   	push   %ebp
 1d8:	89 e5                	mov    %esp,%ebp
 1da:	57                   	push   %edi
 1db:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
 1de:	89 d7                	mov    %edx,%edi
 1e0:	8b 4d 10             	mov    0x10(%ebp),%ecx
 1e3:	8b 45 0c             	mov    0xc(%ebp),%eax
 1e6:	fc                   	cld    
 1e7:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
 1e9:	89 d0                	mov    %edx,%eax
 1eb:	5f                   	pop    %edi
 1ec:	5d                   	pop    %ebp
 1ed:	c3                   	ret    

000001ee <strchr>:

char*
strchr(const char *s, char c)
{
 1ee:	55                   	push   %ebp
 1ef:	89 e5                	mov    %esp,%ebp
 1f1:	8b 45 08             	mov    0x8(%ebp),%eax
 1f4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 1f8:	0f b6 10             	movzbl (%eax),%edx
 1fb:	84 d2                	test   %dl,%dl
 1fd:	74 09                	je     208 <strchr+0x1a>
    if(*s == c)
 1ff:	38 ca                	cmp    %cl,%dl
 201:	74 0a                	je     20d <strchr+0x1f>
  for(; *s; s++)
 203:	83 c0 01             	add    $0x1,%eax
 206:	eb f0                	jmp    1f8 <strchr+0xa>
      return (char*)s;
  return 0;
 208:	b8 00 00 00 00       	mov    $0x0,%eax
}
 20d:	5d                   	pop    %ebp
 20e:	c3                   	ret    

0000020f <gets>:

char*
gets(char *buf, int max)
{
 20f:	55                   	push   %ebp
 210:	89 e5                	mov    %esp,%ebp
 212:	57                   	push   %edi
 213:	56                   	push   %esi
 214:	53                   	push   %ebx
 215:	83 ec 1c             	sub    $0x1c,%esp
 218:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 21b:	bb 00 00 00 00       	mov    $0x0,%ebx
 220:	8d 73 01             	lea    0x1(%ebx),%esi
 223:	3b 75 0c             	cmp    0xc(%ebp),%esi
 226:	7d 2e                	jge    256 <gets+0x47>
    cc = read(0, &c, 1);
 228:	83 ec 04             	sub    $0x4,%esp
 22b:	6a 01                	push   $0x1
 22d:	8d 45 e7             	lea    -0x19(%ebp),%eax
 230:	50                   	push   %eax
 231:	6a 00                	push   $0x0
 233:	e8 e6 00 00 00       	call   31e <read>
    if(cc < 1)
 238:	83 c4 10             	add    $0x10,%esp
 23b:	85 c0                	test   %eax,%eax
 23d:	7e 17                	jle    256 <gets+0x47>
      break;
    buf[i++] = c;
 23f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 243:	88 04 1f             	mov    %al,(%edi,%ebx,1)
    if(c == '\n' || c == '\r')
 246:	3c 0a                	cmp    $0xa,%al
 248:	0f 94 c2             	sete   %dl
 24b:	3c 0d                	cmp    $0xd,%al
 24d:	0f 94 c0             	sete   %al
    buf[i++] = c;
 250:	89 f3                	mov    %esi,%ebx
    if(c == '\n' || c == '\r')
 252:	08 c2                	or     %al,%dl
 254:	74 ca                	je     220 <gets+0x11>
      break;
  }
  buf[i] = '\0';
 256:	c6 04 1f 00          	movb   $0x0,(%edi,%ebx,1)
  return buf;
}
 25a:	89 f8                	mov    %edi,%eax
 25c:	8d 65 f4             	lea    -0xc(%ebp),%esp
 25f:	5b                   	pop    %ebx
 260:	5e                   	pop    %esi
 261:	5f                   	pop    %edi
 262:	5d                   	pop    %ebp
 263:	c3                   	ret    

00000264 <stat>:

int
stat(const char *n, struct stat *st)
{
 264:	55                   	push   %ebp
 265:	89 e5                	mov    %esp,%ebp
 267:	56                   	push   %esi
 268:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 269:	83 ec 08             	sub    $0x8,%esp
 26c:	6a 00                	push   $0x0
 26e:	ff 75 08             	pushl  0x8(%ebp)
 271:	e8 d0 00 00 00       	call   346 <open>
  if(fd < 0)
 276:	83 c4 10             	add    $0x10,%esp
 279:	85 c0                	test   %eax,%eax
 27b:	78 24                	js     2a1 <stat+0x3d>
 27d:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 27f:	83 ec 08             	sub    $0x8,%esp
 282:	ff 75 0c             	pushl  0xc(%ebp)
 285:	50                   	push   %eax
 286:	e8 d3 00 00 00       	call   35e <fstat>
 28b:	89 c6                	mov    %eax,%esi
  close(fd);
 28d:	89 1c 24             	mov    %ebx,(%esp)
 290:	e8 99 00 00 00       	call   32e <close>
  return r;
 295:	83 c4 10             	add    $0x10,%esp
}
 298:	89 f0                	mov    %esi,%eax
 29a:	8d 65 f8             	lea    -0x8(%ebp),%esp
 29d:	5b                   	pop    %ebx
 29e:	5e                   	pop    %esi
 29f:	5d                   	pop    %ebp
 2a0:	c3                   	ret    
    return -1;
 2a1:	be ff ff ff ff       	mov    $0xffffffff,%esi
 2a6:	eb f0                	jmp    298 <stat+0x34>

000002a8 <atoi>:

int
atoi(const char *s)
{
 2a8:	55                   	push   %ebp
 2a9:	89 e5                	mov    %esp,%ebp
 2ab:	53                   	push   %ebx
 2ac:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  n = 0;
 2af:	b8 00 00 00 00       	mov    $0x0,%eax
  while('0' <= *s && *s <= '9')
 2b4:	eb 10                	jmp    2c6 <atoi+0x1e>
    n = n*10 + *s++ - '0';
 2b6:	8d 1c 80             	lea    (%eax,%eax,4),%ebx
 2b9:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
 2bc:	83 c1 01             	add    $0x1,%ecx
 2bf:	0f be d2             	movsbl %dl,%edx
 2c2:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
  while('0' <= *s && *s <= '9')
 2c6:	0f b6 11             	movzbl (%ecx),%edx
 2c9:	8d 5a d0             	lea    -0x30(%edx),%ebx
 2cc:	80 fb 09             	cmp    $0x9,%bl
 2cf:	76 e5                	jbe    2b6 <atoi+0xe>
  return n;
}
 2d1:	5b                   	pop    %ebx
 2d2:	5d                   	pop    %ebp
 2d3:	c3                   	ret    

000002d4 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2d4:	55                   	push   %ebp
 2d5:	89 e5                	mov    %esp,%ebp
 2d7:	56                   	push   %esi
 2d8:	53                   	push   %ebx
 2d9:	8b 45 08             	mov    0x8(%ebp),%eax
 2dc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
 2df:	8b 55 10             	mov    0x10(%ebp),%edx
  char *dst;
  const char *src;

  dst = vdst;
 2e2:	89 c1                	mov    %eax,%ecx
  src = vsrc;
  while(n-- > 0)
 2e4:	eb 0d                	jmp    2f3 <memmove+0x1f>
    *dst++ = *src++;
 2e6:	0f b6 13             	movzbl (%ebx),%edx
 2e9:	88 11                	mov    %dl,(%ecx)
 2eb:	8d 5b 01             	lea    0x1(%ebx),%ebx
 2ee:	8d 49 01             	lea    0x1(%ecx),%ecx
  while(n-- > 0)
 2f1:	89 f2                	mov    %esi,%edx
 2f3:	8d 72 ff             	lea    -0x1(%edx),%esi
 2f6:	85 d2                	test   %edx,%edx
 2f8:	7f ec                	jg     2e6 <memmove+0x12>
  return vdst;
}
 2fa:	5b                   	pop    %ebx
 2fb:	5e                   	pop    %esi
 2fc:	5d                   	pop    %ebp
 2fd:	c3                   	ret    

000002fe <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 2fe:	b8 01 00 00 00       	mov    $0x1,%eax
 303:	cd 40                	int    $0x40
 305:	c3                   	ret    

00000306 <exit>:
SYSCALL(exit)
 306:	b8 02 00 00 00       	mov    $0x2,%eax
 30b:	cd 40                	int    $0x40
 30d:	c3                   	ret    

0000030e <wait>:
SYSCALL(wait)
 30e:	b8 03 00 00 00       	mov    $0x3,%eax
 313:	cd 40                	int    $0x40
 315:	c3                   	ret    

00000316 <pipe>:
SYSCALL(pipe)
 316:	b8 04 00 00 00       	mov    $0x4,%eax
 31b:	cd 40                	int    $0x40
 31d:	c3                   	ret    

0000031e <read>:
SYSCALL(read)
 31e:	b8 05 00 00 00       	mov    $0x5,%eax
 323:	cd 40                	int    $0x40
 325:	c3                   	ret    

00000326 <write>:
SYSCALL(write)
 326:	b8 10 00 00 00       	mov    $0x10,%eax
 32b:	cd 40                	int    $0x40
 32d:	c3                   	ret    

0000032e <close>:
SYSCALL(close)
 32e:	b8 15 00 00 00       	mov    $0x15,%eax
 333:	cd 40                	int    $0x40
 335:	c3                   	ret    

00000336 <kill>:
SYSCALL(kill)
 336:	b8 06 00 00 00       	mov    $0x6,%eax
 33b:	cd 40                	int    $0x40
 33d:	c3                   	ret    

0000033e <exec>:
SYSCALL(exec)
 33e:	b8 07 00 00 00       	mov    $0x7,%eax
 343:	cd 40                	int    $0x40
 345:	c3                   	ret    

00000346 <open>:
SYSCALL(open)
 346:	b8 0f 00 00 00       	mov    $0xf,%eax
 34b:	cd 40                	int    $0x40
 34d:	c3                   	ret    

0000034e <mknod>:
SYSCALL(mknod)
 34e:	b8 11 00 00 00       	mov    $0x11,%eax
 353:	cd 40                	int    $0x40
 355:	c3                   	ret    

00000356 <unlink>:
SYSCALL(unlink)
 356:	b8 12 00 00 00       	mov    $0x12,%eax
 35b:	cd 40                	int    $0x40
 35d:	c3                   	ret    

0000035e <fstat>:
SYSCALL(fstat)
 35e:	b8 08 00 00 00       	mov    $0x8,%eax
 363:	cd 40                	int    $0x40
 365:	c3                   	ret    

00000366 <link>:
SYSCALL(link)
 366:	b8 13 00 00 00       	mov    $0x13,%eax
 36b:	cd 40                	int    $0x40
 36d:	c3                   	ret    

0000036e <mkdir>:
SYSCALL(mkdir)
 36e:	b8 14 00 00 00       	mov    $0x14,%eax
 373:	cd 40                	int    $0x40
 375:	c3                   	ret    

00000376 <chdir>:
SYSCALL(chdir)
 376:	b8 09 00 00 00       	mov    $0x9,%eax
 37b:	cd 40                	int    $0x40
 37d:	c3                   	ret    

0000037e <dup>:
SYSCALL(dup)
 37e:	b8 0a 00 00 00       	mov    $0xa,%eax
 383:	cd 40                	int    $0x40
 385:	c3                   	ret    

00000386 <getpid>:
SYSCALL(getpid)
 386:	b8 0b 00 00 00       	mov    $0xb,%eax
 38b:	cd 40                	int    $0x40
 38d:	c3                   	ret    

0000038e <sbrk>:
SYSCALL(sbrk)
 38e:	b8 0c 00 00 00       	mov    $0xc,%eax
 393:	cd 40                	int    $0x40
 395:	c3                   	ret    

00000396 <sleep>:
SYSCALL(sleep)
 396:	b8 0d 00 00 00       	mov    $0xd,%eax
 39b:	cd 40                	int    $0x40
 39d:	c3                   	ret    

0000039e <uptime>:
SYSCALL(uptime)
 39e:	b8 0e 00 00 00       	mov    $0xe,%eax
 3a3:	cd 40                	int    $0x40
 3a5:	c3                   	ret    

000003a6 <setpri>:
// adding sys calls
SYSCALL(setpri)
 3a6:	b8 16 00 00 00       	mov    $0x16,%eax
 3ab:	cd 40                	int    $0x40
 3ad:	c3                   	ret    

000003ae <getpri>:
SYSCALL(getpri)
 3ae:	b8 17 00 00 00       	mov    $0x17,%eax
 3b3:	cd 40                	int    $0x40
 3b5:	c3                   	ret    

000003b6 <fork2>:
SYSCALL(fork2)
 3b6:	b8 18 00 00 00       	mov    $0x18,%eax
 3bb:	cd 40                	int    $0x40
 3bd:	c3                   	ret    

000003be <getpinfo>:
SYSCALL(getpinfo)
 3be:	b8 19 00 00 00       	mov    $0x19,%eax
 3c3:	cd 40                	int    $0x40
 3c5:	c3                   	ret    

000003c6 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 3c6:	55                   	push   %ebp
 3c7:	89 e5                	mov    %esp,%ebp
 3c9:	83 ec 1c             	sub    $0x1c,%esp
 3cc:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 3cf:	6a 01                	push   $0x1
 3d1:	8d 55 f4             	lea    -0xc(%ebp),%edx
 3d4:	52                   	push   %edx
 3d5:	50                   	push   %eax
 3d6:	e8 4b ff ff ff       	call   326 <write>
}
 3db:	83 c4 10             	add    $0x10,%esp
 3de:	c9                   	leave  
 3df:	c3                   	ret    

000003e0 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3e0:	55                   	push   %ebp
 3e1:	89 e5                	mov    %esp,%ebp
 3e3:	57                   	push   %edi
 3e4:	56                   	push   %esi
 3e5:	53                   	push   %ebx
 3e6:	83 ec 2c             	sub    $0x2c,%esp
 3e9:	89 c7                	mov    %eax,%edi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3eb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 3ef:	0f 95 c3             	setne  %bl
 3f2:	89 d0                	mov    %edx,%eax
 3f4:	c1 e8 1f             	shr    $0x1f,%eax
 3f7:	84 c3                	test   %al,%bl
 3f9:	74 10                	je     40b <printint+0x2b>
    neg = 1;
    x = -xx;
 3fb:	f7 da                	neg    %edx
    neg = 1;
 3fd:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 404:	be 00 00 00 00       	mov    $0x0,%esi
 409:	eb 0b                	jmp    416 <printint+0x36>
  neg = 0;
 40b:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 412:	eb f0                	jmp    404 <printint+0x24>
  do{
    buf[i++] = digits[x % base];
 414:	89 c6                	mov    %eax,%esi
 416:	89 d0                	mov    %edx,%eax
 418:	ba 00 00 00 00       	mov    $0x0,%edx
 41d:	f7 f1                	div    %ecx
 41f:	89 c3                	mov    %eax,%ebx
 421:	8d 46 01             	lea    0x1(%esi),%eax
 424:	0f b6 92 20 07 00 00 	movzbl 0x720(%edx),%edx
 42b:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
 42f:	89 da                	mov    %ebx,%edx
 431:	85 db                	test   %ebx,%ebx
 433:	75 df                	jne    414 <printint+0x34>
 435:	89 c3                	mov    %eax,%ebx
  if(neg)
 437:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 43b:	74 16                	je     453 <printint+0x73>
    buf[i++] = '-';
 43d:	c6 44 05 d8 2d       	movb   $0x2d,-0x28(%ebp,%eax,1)
 442:	8d 5e 02             	lea    0x2(%esi),%ebx
 445:	eb 0c                	jmp    453 <printint+0x73>

  while(--i >= 0)
    putc(fd, buf[i]);
 447:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 44c:	89 f8                	mov    %edi,%eax
 44e:	e8 73 ff ff ff       	call   3c6 <putc>
  while(--i >= 0)
 453:	83 eb 01             	sub    $0x1,%ebx
 456:	79 ef                	jns    447 <printint+0x67>
}
 458:	83 c4 2c             	add    $0x2c,%esp
 45b:	5b                   	pop    %ebx
 45c:	5e                   	pop    %esi
 45d:	5f                   	pop    %edi
 45e:	5d                   	pop    %ebp
 45f:	c3                   	ret    

00000460 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, const char *fmt, ...)
{
 460:	55                   	push   %ebp
 461:	89 e5                	mov    %esp,%ebp
 463:	57                   	push   %edi
 464:	56                   	push   %esi
 465:	53                   	push   %ebx
 466:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 469:	8d 45 10             	lea    0x10(%ebp),%eax
 46c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 46f:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 474:	bb 00 00 00 00       	mov    $0x0,%ebx
 479:	eb 14                	jmp    48f <printf+0x2f>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 47b:	89 fa                	mov    %edi,%edx
 47d:	8b 45 08             	mov    0x8(%ebp),%eax
 480:	e8 41 ff ff ff       	call   3c6 <putc>
 485:	eb 05                	jmp    48c <printf+0x2c>
      }
    } else if(state == '%'){
 487:	83 fe 25             	cmp    $0x25,%esi
 48a:	74 25                	je     4b1 <printf+0x51>
  for(i = 0; fmt[i]; i++){
 48c:	83 c3 01             	add    $0x1,%ebx
 48f:	8b 45 0c             	mov    0xc(%ebp),%eax
 492:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 496:	84 c0                	test   %al,%al
 498:	0f 84 23 01 00 00    	je     5c1 <printf+0x161>
    c = fmt[i] & 0xff;
 49e:	0f be f8             	movsbl %al,%edi
 4a1:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 4a4:	85 f6                	test   %esi,%esi
 4a6:	75 df                	jne    487 <printf+0x27>
      if(c == '%'){
 4a8:	83 f8 25             	cmp    $0x25,%eax
 4ab:	75 ce                	jne    47b <printf+0x1b>
        state = '%';
 4ad:	89 c6                	mov    %eax,%esi
 4af:	eb db                	jmp    48c <printf+0x2c>
      if(c == 'd'){
 4b1:	83 f8 64             	cmp    $0x64,%eax
 4b4:	74 49                	je     4ff <printf+0x9f>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 4b6:	83 f8 78             	cmp    $0x78,%eax
 4b9:	0f 94 c1             	sete   %cl
 4bc:	83 f8 70             	cmp    $0x70,%eax
 4bf:	0f 94 c2             	sete   %dl
 4c2:	08 d1                	or     %dl,%cl
 4c4:	75 63                	jne    529 <printf+0xc9>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 4c6:	83 f8 73             	cmp    $0x73,%eax
 4c9:	0f 84 84 00 00 00    	je     553 <printf+0xf3>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4cf:	83 f8 63             	cmp    $0x63,%eax
 4d2:	0f 84 b7 00 00 00    	je     58f <printf+0x12f>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 4d8:	83 f8 25             	cmp    $0x25,%eax
 4db:	0f 84 cc 00 00 00    	je     5ad <printf+0x14d>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4e1:	ba 25 00 00 00       	mov    $0x25,%edx
 4e6:	8b 45 08             	mov    0x8(%ebp),%eax
 4e9:	e8 d8 fe ff ff       	call   3c6 <putc>
        putc(fd, c);
 4ee:	89 fa                	mov    %edi,%edx
 4f0:	8b 45 08             	mov    0x8(%ebp),%eax
 4f3:	e8 ce fe ff ff       	call   3c6 <putc>
      }
      state = 0;
 4f8:	be 00 00 00 00       	mov    $0x0,%esi
 4fd:	eb 8d                	jmp    48c <printf+0x2c>
        printint(fd, *ap, 10, 1);
 4ff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 502:	8b 17                	mov    (%edi),%edx
 504:	83 ec 0c             	sub    $0xc,%esp
 507:	6a 01                	push   $0x1
 509:	b9 0a 00 00 00       	mov    $0xa,%ecx
 50e:	8b 45 08             	mov    0x8(%ebp),%eax
 511:	e8 ca fe ff ff       	call   3e0 <printint>
        ap++;
 516:	83 c7 04             	add    $0x4,%edi
 519:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 51c:	83 c4 10             	add    $0x10,%esp
      state = 0;
 51f:	be 00 00 00 00       	mov    $0x0,%esi
 524:	e9 63 ff ff ff       	jmp    48c <printf+0x2c>
        printint(fd, *ap, 16, 0);
 529:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 52c:	8b 17                	mov    (%edi),%edx
 52e:	83 ec 0c             	sub    $0xc,%esp
 531:	6a 00                	push   $0x0
 533:	b9 10 00 00 00       	mov    $0x10,%ecx
 538:	8b 45 08             	mov    0x8(%ebp),%eax
 53b:	e8 a0 fe ff ff       	call   3e0 <printint>
        ap++;
 540:	83 c7 04             	add    $0x4,%edi
 543:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 546:	83 c4 10             	add    $0x10,%esp
      state = 0;
 549:	be 00 00 00 00       	mov    $0x0,%esi
 54e:	e9 39 ff ff ff       	jmp    48c <printf+0x2c>
        s = (char*)*ap;
 553:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 556:	8b 30                	mov    (%eax),%esi
        ap++;
 558:	83 c0 04             	add    $0x4,%eax
 55b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 55e:	85 f6                	test   %esi,%esi
 560:	75 28                	jne    58a <printf+0x12a>
          s = "(null)";
 562:	be 18 07 00 00       	mov    $0x718,%esi
 567:	8b 7d 08             	mov    0x8(%ebp),%edi
 56a:	eb 0d                	jmp    579 <printf+0x119>
          putc(fd, *s);
 56c:	0f be d2             	movsbl %dl,%edx
 56f:	89 f8                	mov    %edi,%eax
 571:	e8 50 fe ff ff       	call   3c6 <putc>
          s++;
 576:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 579:	0f b6 16             	movzbl (%esi),%edx
 57c:	84 d2                	test   %dl,%dl
 57e:	75 ec                	jne    56c <printf+0x10c>
      state = 0;
 580:	be 00 00 00 00       	mov    $0x0,%esi
 585:	e9 02 ff ff ff       	jmp    48c <printf+0x2c>
 58a:	8b 7d 08             	mov    0x8(%ebp),%edi
 58d:	eb ea                	jmp    579 <printf+0x119>
        putc(fd, *ap);
 58f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 592:	0f be 17             	movsbl (%edi),%edx
 595:	8b 45 08             	mov    0x8(%ebp),%eax
 598:	e8 29 fe ff ff       	call   3c6 <putc>
        ap++;
 59d:	83 c7 04             	add    $0x4,%edi
 5a0:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 5a3:	be 00 00 00 00       	mov    $0x0,%esi
 5a8:	e9 df fe ff ff       	jmp    48c <printf+0x2c>
        putc(fd, c);
 5ad:	89 fa                	mov    %edi,%edx
 5af:	8b 45 08             	mov    0x8(%ebp),%eax
 5b2:	e8 0f fe ff ff       	call   3c6 <putc>
      state = 0;
 5b7:	be 00 00 00 00       	mov    $0x0,%esi
 5bc:	e9 cb fe ff ff       	jmp    48c <printf+0x2c>
    }
  }
}
 5c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
 5c4:	5b                   	pop    %ebx
 5c5:	5e                   	pop    %esi
 5c6:	5f                   	pop    %edi
 5c7:	5d                   	pop    %ebp
 5c8:	c3                   	ret    

000005c9 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 5c9:	55                   	push   %ebp
 5ca:	89 e5                	mov    %esp,%ebp
 5cc:	57                   	push   %edi
 5cd:	56                   	push   %esi
 5ce:	53                   	push   %ebx
 5cf:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 5d2:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 5d5:	a1 f0 09 00 00       	mov    0x9f0,%eax
 5da:	eb 02                	jmp    5de <free+0x15>
 5dc:	89 d0                	mov    %edx,%eax
 5de:	39 c8                	cmp    %ecx,%eax
 5e0:	73 04                	jae    5e6 <free+0x1d>
 5e2:	39 08                	cmp    %ecx,(%eax)
 5e4:	77 12                	ja     5f8 <free+0x2f>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 5e6:	8b 10                	mov    (%eax),%edx
 5e8:	39 c2                	cmp    %eax,%edx
 5ea:	77 f0                	ja     5dc <free+0x13>
 5ec:	39 c8                	cmp    %ecx,%eax
 5ee:	72 08                	jb     5f8 <free+0x2f>
 5f0:	39 ca                	cmp    %ecx,%edx
 5f2:	77 04                	ja     5f8 <free+0x2f>
 5f4:	89 d0                	mov    %edx,%eax
 5f6:	eb e6                	jmp    5de <free+0x15>
      break;
  if(bp + bp->s.size == p->s.ptr){
 5f8:	8b 73 fc             	mov    -0x4(%ebx),%esi
 5fb:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 5fe:	8b 10                	mov    (%eax),%edx
 600:	39 d7                	cmp    %edx,%edi
 602:	74 19                	je     61d <free+0x54>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 604:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 607:	8b 50 04             	mov    0x4(%eax),%edx
 60a:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 60d:	39 ce                	cmp    %ecx,%esi
 60f:	74 1b                	je     62c <free+0x63>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 611:	89 08                	mov    %ecx,(%eax)
  freep = p;
 613:	a3 f0 09 00 00       	mov    %eax,0x9f0
}
 618:	5b                   	pop    %ebx
 619:	5e                   	pop    %esi
 61a:	5f                   	pop    %edi
 61b:	5d                   	pop    %ebp
 61c:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 61d:	03 72 04             	add    0x4(%edx),%esi
 620:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 623:	8b 10                	mov    (%eax),%edx
 625:	8b 12                	mov    (%edx),%edx
 627:	89 53 f8             	mov    %edx,-0x8(%ebx)
 62a:	eb db                	jmp    607 <free+0x3e>
    p->s.size += bp->s.size;
 62c:	03 53 fc             	add    -0x4(%ebx),%edx
 62f:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 632:	8b 53 f8             	mov    -0x8(%ebx),%edx
 635:	89 10                	mov    %edx,(%eax)
 637:	eb da                	jmp    613 <free+0x4a>

00000639 <morecore>:

static Header*
morecore(uint nu)
{
 639:	55                   	push   %ebp
 63a:	89 e5                	mov    %esp,%ebp
 63c:	53                   	push   %ebx
 63d:	83 ec 04             	sub    $0x4,%esp
 640:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 642:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 647:	77 05                	ja     64e <morecore+0x15>
    nu = 4096;
 649:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 64e:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 655:	83 ec 0c             	sub    $0xc,%esp
 658:	50                   	push   %eax
 659:	e8 30 fd ff ff       	call   38e <sbrk>
  if(p == (char*)-1)
 65e:	83 c4 10             	add    $0x10,%esp
 661:	83 f8 ff             	cmp    $0xffffffff,%eax
 664:	74 1c                	je     682 <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 666:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 669:	83 c0 08             	add    $0x8,%eax
 66c:	83 ec 0c             	sub    $0xc,%esp
 66f:	50                   	push   %eax
 670:	e8 54 ff ff ff       	call   5c9 <free>
  return freep;
 675:	a1 f0 09 00 00       	mov    0x9f0,%eax
 67a:	83 c4 10             	add    $0x10,%esp
}
 67d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 680:	c9                   	leave  
 681:	c3                   	ret    
    return 0;
 682:	b8 00 00 00 00       	mov    $0x0,%eax
 687:	eb f4                	jmp    67d <morecore+0x44>

00000689 <malloc>:

void*
malloc(uint nbytes)
{
 689:	55                   	push   %ebp
 68a:	89 e5                	mov    %esp,%ebp
 68c:	53                   	push   %ebx
 68d:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 690:	8b 45 08             	mov    0x8(%ebp),%eax
 693:	8d 58 07             	lea    0x7(%eax),%ebx
 696:	c1 eb 03             	shr    $0x3,%ebx
 699:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 69c:	8b 0d f0 09 00 00    	mov    0x9f0,%ecx
 6a2:	85 c9                	test   %ecx,%ecx
 6a4:	74 04                	je     6aa <malloc+0x21>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 6a6:	8b 01                	mov    (%ecx),%eax
 6a8:	eb 4d                	jmp    6f7 <malloc+0x6e>
    base.s.ptr = freep = prevp = &base;
 6aa:	c7 05 f0 09 00 00 f4 	movl   $0x9f4,0x9f0
 6b1:	09 00 00 
 6b4:	c7 05 f4 09 00 00 f4 	movl   $0x9f4,0x9f4
 6bb:	09 00 00 
    base.s.size = 0;
 6be:	c7 05 f8 09 00 00 00 	movl   $0x0,0x9f8
 6c5:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 6c8:	b9 f4 09 00 00       	mov    $0x9f4,%ecx
 6cd:	eb d7                	jmp    6a6 <malloc+0x1d>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 6cf:	39 da                	cmp    %ebx,%edx
 6d1:	74 1a                	je     6ed <malloc+0x64>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 6d3:	29 da                	sub    %ebx,%edx
 6d5:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 6d8:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 6db:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 6de:	89 0d f0 09 00 00    	mov    %ecx,0x9f0
      return (void*)(p + 1);
 6e4:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 6e7:	83 c4 04             	add    $0x4,%esp
 6ea:	5b                   	pop    %ebx
 6eb:	5d                   	pop    %ebp
 6ec:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 6ed:	8b 10                	mov    (%eax),%edx
 6ef:	89 11                	mov    %edx,(%ecx)
 6f1:	eb eb                	jmp    6de <malloc+0x55>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 6f3:	89 c1                	mov    %eax,%ecx
 6f5:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 6f7:	8b 50 04             	mov    0x4(%eax),%edx
 6fa:	39 da                	cmp    %ebx,%edx
 6fc:	73 d1                	jae    6cf <malloc+0x46>
    if(p == freep)
 6fe:	39 05 f0 09 00 00    	cmp    %eax,0x9f0
 704:	75 ed                	jne    6f3 <malloc+0x6a>
      if((p = morecore(nunits)) == 0)
 706:	89 d8                	mov    %ebx,%eax
 708:	e8 2c ff ff ff       	call   639 <morecore>
 70d:	85 c0                	test   %eax,%eax
 70f:	75 e2                	jne    6f3 <malloc+0x6a>
        return 0;
 711:	b8 00 00 00 00       	mov    $0x0,%eax
 716:	eb cf                	jmp    6e7 <malloc+0x5e>
