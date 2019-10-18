
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
   6:	83 ec 0c             	sub    $0xc,%esp
   9:	8b 75 08             	mov    0x8(%ebp),%esi
   c:	8b 7d 14             	mov    0x14(%ebp),%edi
  //  struct pstat *pstat;


    char **ptr = &job;
    struct pstat *pstat = 0;
    int jcount = 0;
   f:	bb 00 00 00 00       	mov    $0x0,%ebx

    while ( jcount < jobcount ) {
  14:	eb 08                	jmp    1e <roundRobin+0x1e>
        int pid = fork2(2);
        if (pid < 0) {
            exit();
  16:	e8 07 03 00 00       	call   322 <exit>
        } else if (pid == 0) {
            exec(job, ptr);
        } else if (pid > 0) {
            // getpinfo(pstat);
        }
        jcount++;
  1b:	83 c3 01             	add    $0x1,%ebx
    while ( jcount < jobcount ) {
  1e:	39 fb                	cmp    %edi,%ebx
  20:	7d 29                	jge    4b <roundRobin+0x4b>
        int pid = fork2(2);
  22:	83 ec 0c             	sub    $0xc,%esp
  25:	6a 02                	push   $0x2
  27:	e8 a6 03 00 00       	call   3d2 <fork2>
        if (pid < 0) {
  2c:	83 c4 10             	add    $0x10,%esp
  2f:	85 c0                	test   %eax,%eax
  31:	78 e3                	js     16 <roundRobin+0x16>
        } else if (pid == 0) {
  33:	85 c0                	test   %eax,%eax
  35:	75 e4                	jne    1b <roundRobin+0x1b>
            exec(job, ptr);
  37:	83 ec 08             	sub    $0x8,%esp
  3a:	8d 45 10             	lea    0x10(%ebp),%eax
  3d:	50                   	push   %eax
  3e:	ff 75 10             	pushl  0x10(%ebp)
  41:	e8 14 03 00 00       	call   35a <exec>
  46:	83 c4 10             	add    $0x10,%esp
  49:	eb d0                	jmp    1b <roundRobin+0x1b>
    }

    for (int i = 0; i < iterations; i++){
  4b:	bf 00 00 00 00       	mov    $0x0,%edi
  50:	eb 37                	jmp    89 <roundRobin+0x89>
        getpinfo(pstat);
        for(int j = 0; j < NPROC; j++) {
  52:	83 c3 01             	add    $0x1,%ebx
  55:	83 fb 3f             	cmp    $0x3f,%ebx
  58:	7f 20                	jg     7a <roundRobin+0x7a>
            if (pstat->priority[j] == 2) {
  5a:	83 3c 9d 00 02 00 00 	cmpl   $0x2,0x200(,%ebx,4)
  61:	02 
  62:	75 ee                	jne    52 <roundRobin+0x52>
                setpri(pstat->pid[j], 3);
  64:	83 ec 08             	sub    $0x8,%esp
  67:	6a 03                	push   $0x3
  69:	ff 34 9d 00 01 00 00 	pushl  0x100(,%ebx,4)
  70:	e8 4d 03 00 00       	call   3c2 <setpri>
  75:	83 c4 10             	add    $0x10,%esp
  78:	eb d8                	jmp    52 <roundRobin+0x52>
            }
        }
        //printf(1, "%s\n", "iteration loop");
        sleep(timeslice);
  7a:	83 ec 0c             	sub    $0xc,%esp
  7d:	56                   	push   %esi
  7e:	e8 2f 03 00 00       	call   3b2 <sleep>
    for (int i = 0; i < iterations; i++){
  83:	83 c7 01             	add    $0x1,%edi
  86:	83 c4 10             	add    $0x10,%esp
  89:	3b 7d 0c             	cmp    0xc(%ebp),%edi
  8c:	7d 14                	jge    a2 <roundRobin+0xa2>
        getpinfo(pstat);
  8e:	83 ec 0c             	sub    $0xc,%esp
  91:	6a 00                	push   $0x0
  93:	e8 42 03 00 00       	call   3da <getpinfo>
        for(int j = 0; j < NPROC; j++) {
  98:	83 c4 10             	add    $0x10,%esp
  9b:	bb 00 00 00 00       	mov    $0x0,%ebx
  a0:	eb b3                	jmp    55 <roundRobin+0x55>
    }
    printf(1, "%s\n\n\n", "FINAL");
  a2:	83 ec 04             	sub    $0x4,%esp
  a5:	68 34 07 00 00       	push   $0x734
  aa:	68 3a 07 00 00       	push   $0x73a
  af:	6a 01                	push   $0x1
  b1:	e8 c6 03 00 00       	call   47c <printf>
    getpinfo(pstat);
  b6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  bd:	e8 18 03 00 00       	call   3da <getpinfo>
    for (int i = 0; i < NPROC; i++) {
  c2:	83 c4 10             	add    $0x10,%esp
  c5:	bb 00 00 00 00       	mov    $0x0,%ebx
  ca:	eb 15                	jmp    e1 <roundRobin+0xe1>
        //printf(1, "%d\n", (*pstat).state[i]);
        if (pstat->state[i] == 5) {
            printf(1, "%s\n", "here");
        }
        kill(pstat->pid[i]);
  cc:	83 ec 0c             	sub    $0xc,%esp
  cf:	ff 34 9d 00 01 00 00 	pushl  0x100(,%ebx,4)
  d6:	e8 77 02 00 00       	call   352 <kill>
    for (int i = 0; i < NPROC; i++) {
  db:	83 c3 01             	add    $0x1,%ebx
  de:	83 c4 10             	add    $0x10,%esp
  e1:	83 fb 3f             	cmp    $0x3f,%ebx
  e4:	7f 23                	jg     109 <roundRobin+0x109>
        if (pstat->state[i] == 5) {
  e6:	83 3c 9d 00 03 00 00 	cmpl   $0x5,0x300(,%ebx,4)
  ed:	05 
  ee:	75 dc                	jne    cc <roundRobin+0xcc>
            printf(1, "%s\n", "here");
  f0:	83 ec 04             	sub    $0x4,%esp
  f3:	68 40 07 00 00       	push   $0x740
  f8:	68 45 07 00 00       	push   $0x745
  fd:	6a 01                	push   $0x1
  ff:	e8 78 03 00 00       	call   47c <printf>
 104:	83 c4 10             	add    $0x10,%esp
 107:	eb c3                	jmp    cc <roundRobin+0xcc>
    }


}
 109:	8d 65 f4             	lea    -0xc(%ebp),%esp
 10c:	5b                   	pop    %ebx
 10d:	5e                   	pop    %esi
 10e:	5f                   	pop    %edi
 10f:	5d                   	pop    %ebp
 110:	c3                   	ret    

00000111 <main>:

int main(int argc, char *argv[]) {
 111:	8d 4c 24 04          	lea    0x4(%esp),%ecx
 115:	83 e4 f0             	and    $0xfffffff0,%esp
 118:	ff 71 fc             	pushl  -0x4(%ecx)
 11b:	55                   	push   %ebp
 11c:	89 e5                	mov    %esp,%ebp
 11e:	57                   	push   %edi
 11f:	56                   	push   %esi
 120:	53                   	push   %ebx
 121:	51                   	push   %ecx
 122:	83 ec 18             	sub    $0x18,%esp
 125:	8b 59 04             	mov    0x4(%ecx),%ebx
    if(argc != 5) {
 128:	83 39 05             	cmpl   $0x5,(%ecx)
 12b:	74 05                	je     132 <main+0x21>
        // TODO: print error message
        exit();
 12d:	e8 f0 01 00 00       	call   322 <exit>
    }

    int timeslice = atoi(argv[1]);
 132:	83 ec 0c             	sub    $0xc,%esp
 135:	ff 73 04             	pushl  0x4(%ebx)
 138:	e8 87 01 00 00       	call   2c4 <atoi>
 13d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    int iterations = atoi(argv[2]);
 140:	83 c4 04             	add    $0x4,%esp
 143:	ff 73 08             	pushl  0x8(%ebx)
 146:	e8 79 01 00 00       	call   2c4 <atoi>
 14b:	89 c7                	mov    %eax,%edi
    char *job = malloc(sizeof(char) * (strlen(argv[3]) + 1));
 14d:	83 c4 04             	add    $0x4,%esp
 150:	ff 73 0c             	pushl  0xc(%ebx)
 153:	e8 81 00 00 00       	call   1d9 <strlen>
 158:	83 c0 01             	add    $0x1,%eax
 15b:	89 04 24             	mov    %eax,(%esp)
 15e:	e8 42 05 00 00       	call   6a5 <malloc>
 163:	89 c6                	mov    %eax,%esi
    strcpy(job, argv[3]);
 165:	83 c4 08             	add    $0x8,%esp
 168:	ff 73 0c             	pushl  0xc(%ebx)
 16b:	50                   	push   %eax
 16c:	e8 24 00 00 00       	call   195 <strcpy>
    int jobcount = atoi(argv[4]);
 171:	83 c4 04             	add    $0x4,%esp
 174:	ff 73 10             	pushl  0x10(%ebx)
 177:	e8 48 01 00 00       	call   2c4 <atoi>
    //int ppid = getpid();

    //setpri(ppid, 3);
    roundRobin(timeslice, iterations, job, jobcount);
 17c:	50                   	push   %eax
 17d:	56                   	push   %esi
 17e:	57                   	push   %edi
 17f:	ff 75 e4             	pushl  -0x1c(%ebp)
 182:	e8 79 fe ff ff       	call   0 <roundRobin>
    free(job);
 187:	83 c4 14             	add    $0x14,%esp
 18a:	56                   	push   %esi
 18b:	e8 55 04 00 00       	call   5e5 <free>
    exit();
 190:	e8 8d 01 00 00       	call   322 <exit>

00000195 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, const char *t)
{
 195:	55                   	push   %ebp
 196:	89 e5                	mov    %esp,%ebp
 198:	53                   	push   %ebx
 199:	8b 45 08             	mov    0x8(%ebp),%eax
 19c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 19f:	89 c2                	mov    %eax,%edx
 1a1:	0f b6 19             	movzbl (%ecx),%ebx
 1a4:	88 1a                	mov    %bl,(%edx)
 1a6:	8d 52 01             	lea    0x1(%edx),%edx
 1a9:	8d 49 01             	lea    0x1(%ecx),%ecx
 1ac:	84 db                	test   %bl,%bl
 1ae:	75 f1                	jne    1a1 <strcpy+0xc>
    ;
  return os;
}
 1b0:	5b                   	pop    %ebx
 1b1:	5d                   	pop    %ebp
 1b2:	c3                   	ret    

000001b3 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1b3:	55                   	push   %ebp
 1b4:	89 e5                	mov    %esp,%ebp
 1b6:	8b 4d 08             	mov    0x8(%ebp),%ecx
 1b9:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
 1bc:	eb 06                	jmp    1c4 <strcmp+0x11>
    p++, q++;
 1be:	83 c1 01             	add    $0x1,%ecx
 1c1:	83 c2 01             	add    $0x1,%edx
  while(*p && *p == *q)
 1c4:	0f b6 01             	movzbl (%ecx),%eax
 1c7:	84 c0                	test   %al,%al
 1c9:	74 04                	je     1cf <strcmp+0x1c>
 1cb:	3a 02                	cmp    (%edx),%al
 1cd:	74 ef                	je     1be <strcmp+0xb>
  return (uchar)*p - (uchar)*q;
 1cf:	0f b6 c0             	movzbl %al,%eax
 1d2:	0f b6 12             	movzbl (%edx),%edx
 1d5:	29 d0                	sub    %edx,%eax
}
 1d7:	5d                   	pop    %ebp
 1d8:	c3                   	ret    

000001d9 <strlen>:

uint
strlen(const char *s)
{
 1d9:	55                   	push   %ebp
 1da:	89 e5                	mov    %esp,%ebp
 1dc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
 1df:	ba 00 00 00 00       	mov    $0x0,%edx
 1e4:	eb 03                	jmp    1e9 <strlen+0x10>
 1e6:	83 c2 01             	add    $0x1,%edx
 1e9:	89 d0                	mov    %edx,%eax
 1eb:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
 1ef:	75 f5                	jne    1e6 <strlen+0xd>
    ;
  return n;
}
 1f1:	5d                   	pop    %ebp
 1f2:	c3                   	ret    

000001f3 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1f3:	55                   	push   %ebp
 1f4:	89 e5                	mov    %esp,%ebp
 1f6:	57                   	push   %edi
 1f7:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
 1fa:	89 d7                	mov    %edx,%edi
 1fc:	8b 4d 10             	mov    0x10(%ebp),%ecx
 1ff:	8b 45 0c             	mov    0xc(%ebp),%eax
 202:	fc                   	cld    
 203:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
 205:	89 d0                	mov    %edx,%eax
 207:	5f                   	pop    %edi
 208:	5d                   	pop    %ebp
 209:	c3                   	ret    

0000020a <strchr>:

char*
strchr(const char *s, char c)
{
 20a:	55                   	push   %ebp
 20b:	89 e5                	mov    %esp,%ebp
 20d:	8b 45 08             	mov    0x8(%ebp),%eax
 210:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 214:	0f b6 10             	movzbl (%eax),%edx
 217:	84 d2                	test   %dl,%dl
 219:	74 09                	je     224 <strchr+0x1a>
    if(*s == c)
 21b:	38 ca                	cmp    %cl,%dl
 21d:	74 0a                	je     229 <strchr+0x1f>
  for(; *s; s++)
 21f:	83 c0 01             	add    $0x1,%eax
 222:	eb f0                	jmp    214 <strchr+0xa>
      return (char*)s;
  return 0;
 224:	b8 00 00 00 00       	mov    $0x0,%eax
}
 229:	5d                   	pop    %ebp
 22a:	c3                   	ret    

0000022b <gets>:

char*
gets(char *buf, int max)
{
 22b:	55                   	push   %ebp
 22c:	89 e5                	mov    %esp,%ebp
 22e:	57                   	push   %edi
 22f:	56                   	push   %esi
 230:	53                   	push   %ebx
 231:	83 ec 1c             	sub    $0x1c,%esp
 234:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 237:	bb 00 00 00 00       	mov    $0x0,%ebx
 23c:	8d 73 01             	lea    0x1(%ebx),%esi
 23f:	3b 75 0c             	cmp    0xc(%ebp),%esi
 242:	7d 2e                	jge    272 <gets+0x47>
    cc = read(0, &c, 1);
 244:	83 ec 04             	sub    $0x4,%esp
 247:	6a 01                	push   $0x1
 249:	8d 45 e7             	lea    -0x19(%ebp),%eax
 24c:	50                   	push   %eax
 24d:	6a 00                	push   $0x0
 24f:	e8 e6 00 00 00       	call   33a <read>
    if(cc < 1)
 254:	83 c4 10             	add    $0x10,%esp
 257:	85 c0                	test   %eax,%eax
 259:	7e 17                	jle    272 <gets+0x47>
      break;
    buf[i++] = c;
 25b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 25f:	88 04 1f             	mov    %al,(%edi,%ebx,1)
    if(c == '\n' || c == '\r')
 262:	3c 0a                	cmp    $0xa,%al
 264:	0f 94 c2             	sete   %dl
 267:	3c 0d                	cmp    $0xd,%al
 269:	0f 94 c0             	sete   %al
    buf[i++] = c;
 26c:	89 f3                	mov    %esi,%ebx
    if(c == '\n' || c == '\r')
 26e:	08 c2                	or     %al,%dl
 270:	74 ca                	je     23c <gets+0x11>
      break;
  }
  buf[i] = '\0';
 272:	c6 04 1f 00          	movb   $0x0,(%edi,%ebx,1)
  return buf;
}
 276:	89 f8                	mov    %edi,%eax
 278:	8d 65 f4             	lea    -0xc(%ebp),%esp
 27b:	5b                   	pop    %ebx
 27c:	5e                   	pop    %esi
 27d:	5f                   	pop    %edi
 27e:	5d                   	pop    %ebp
 27f:	c3                   	ret    

00000280 <stat>:

int
stat(const char *n, struct stat *st)
{
 280:	55                   	push   %ebp
 281:	89 e5                	mov    %esp,%ebp
 283:	56                   	push   %esi
 284:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 285:	83 ec 08             	sub    $0x8,%esp
 288:	6a 00                	push   $0x0
 28a:	ff 75 08             	pushl  0x8(%ebp)
 28d:	e8 d0 00 00 00       	call   362 <open>
  if(fd < 0)
 292:	83 c4 10             	add    $0x10,%esp
 295:	85 c0                	test   %eax,%eax
 297:	78 24                	js     2bd <stat+0x3d>
 299:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 29b:	83 ec 08             	sub    $0x8,%esp
 29e:	ff 75 0c             	pushl  0xc(%ebp)
 2a1:	50                   	push   %eax
 2a2:	e8 d3 00 00 00       	call   37a <fstat>
 2a7:	89 c6                	mov    %eax,%esi
  close(fd);
 2a9:	89 1c 24             	mov    %ebx,(%esp)
 2ac:	e8 99 00 00 00       	call   34a <close>
  return r;
 2b1:	83 c4 10             	add    $0x10,%esp
}
 2b4:	89 f0                	mov    %esi,%eax
 2b6:	8d 65 f8             	lea    -0x8(%ebp),%esp
 2b9:	5b                   	pop    %ebx
 2ba:	5e                   	pop    %esi
 2bb:	5d                   	pop    %ebp
 2bc:	c3                   	ret    
    return -1;
 2bd:	be ff ff ff ff       	mov    $0xffffffff,%esi
 2c2:	eb f0                	jmp    2b4 <stat+0x34>

000002c4 <atoi>:

int
atoi(const char *s)
{
 2c4:	55                   	push   %ebp
 2c5:	89 e5                	mov    %esp,%ebp
 2c7:	53                   	push   %ebx
 2c8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  n = 0;
 2cb:	b8 00 00 00 00       	mov    $0x0,%eax
  while('0' <= *s && *s <= '9')
 2d0:	eb 10                	jmp    2e2 <atoi+0x1e>
    n = n*10 + *s++ - '0';
 2d2:	8d 1c 80             	lea    (%eax,%eax,4),%ebx
 2d5:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
 2d8:	83 c1 01             	add    $0x1,%ecx
 2db:	0f be d2             	movsbl %dl,%edx
 2de:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
  while('0' <= *s && *s <= '9')
 2e2:	0f b6 11             	movzbl (%ecx),%edx
 2e5:	8d 5a d0             	lea    -0x30(%edx),%ebx
 2e8:	80 fb 09             	cmp    $0x9,%bl
 2eb:	76 e5                	jbe    2d2 <atoi+0xe>
  return n;
}
 2ed:	5b                   	pop    %ebx
 2ee:	5d                   	pop    %ebp
 2ef:	c3                   	ret    

000002f0 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2f0:	55                   	push   %ebp
 2f1:	89 e5                	mov    %esp,%ebp
 2f3:	56                   	push   %esi
 2f4:	53                   	push   %ebx
 2f5:	8b 45 08             	mov    0x8(%ebp),%eax
 2f8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
 2fb:	8b 55 10             	mov    0x10(%ebp),%edx
  char *dst;
  const char *src;

  dst = vdst;
 2fe:	89 c1                	mov    %eax,%ecx
  src = vsrc;
  while(n-- > 0)
 300:	eb 0d                	jmp    30f <memmove+0x1f>
    *dst++ = *src++;
 302:	0f b6 13             	movzbl (%ebx),%edx
 305:	88 11                	mov    %dl,(%ecx)
 307:	8d 5b 01             	lea    0x1(%ebx),%ebx
 30a:	8d 49 01             	lea    0x1(%ecx),%ecx
  while(n-- > 0)
 30d:	89 f2                	mov    %esi,%edx
 30f:	8d 72 ff             	lea    -0x1(%edx),%esi
 312:	85 d2                	test   %edx,%edx
 314:	7f ec                	jg     302 <memmove+0x12>
  return vdst;
}
 316:	5b                   	pop    %ebx
 317:	5e                   	pop    %esi
 318:	5d                   	pop    %ebp
 319:	c3                   	ret    

0000031a <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 31a:	b8 01 00 00 00       	mov    $0x1,%eax
 31f:	cd 40                	int    $0x40
 321:	c3                   	ret    

00000322 <exit>:
SYSCALL(exit)
 322:	b8 02 00 00 00       	mov    $0x2,%eax
 327:	cd 40                	int    $0x40
 329:	c3                   	ret    

0000032a <wait>:
SYSCALL(wait)
 32a:	b8 03 00 00 00       	mov    $0x3,%eax
 32f:	cd 40                	int    $0x40
 331:	c3                   	ret    

00000332 <pipe>:
SYSCALL(pipe)
 332:	b8 04 00 00 00       	mov    $0x4,%eax
 337:	cd 40                	int    $0x40
 339:	c3                   	ret    

0000033a <read>:
SYSCALL(read)
 33a:	b8 05 00 00 00       	mov    $0x5,%eax
 33f:	cd 40                	int    $0x40
 341:	c3                   	ret    

00000342 <write>:
SYSCALL(write)
 342:	b8 10 00 00 00       	mov    $0x10,%eax
 347:	cd 40                	int    $0x40
 349:	c3                   	ret    

0000034a <close>:
SYSCALL(close)
 34a:	b8 15 00 00 00       	mov    $0x15,%eax
 34f:	cd 40                	int    $0x40
 351:	c3                   	ret    

00000352 <kill>:
SYSCALL(kill)
 352:	b8 06 00 00 00       	mov    $0x6,%eax
 357:	cd 40                	int    $0x40
 359:	c3                   	ret    

0000035a <exec>:
SYSCALL(exec)
 35a:	b8 07 00 00 00       	mov    $0x7,%eax
 35f:	cd 40                	int    $0x40
 361:	c3                   	ret    

00000362 <open>:
SYSCALL(open)
 362:	b8 0f 00 00 00       	mov    $0xf,%eax
 367:	cd 40                	int    $0x40
 369:	c3                   	ret    

0000036a <mknod>:
SYSCALL(mknod)
 36a:	b8 11 00 00 00       	mov    $0x11,%eax
 36f:	cd 40                	int    $0x40
 371:	c3                   	ret    

00000372 <unlink>:
SYSCALL(unlink)
 372:	b8 12 00 00 00       	mov    $0x12,%eax
 377:	cd 40                	int    $0x40
 379:	c3                   	ret    

0000037a <fstat>:
SYSCALL(fstat)
 37a:	b8 08 00 00 00       	mov    $0x8,%eax
 37f:	cd 40                	int    $0x40
 381:	c3                   	ret    

00000382 <link>:
SYSCALL(link)
 382:	b8 13 00 00 00       	mov    $0x13,%eax
 387:	cd 40                	int    $0x40
 389:	c3                   	ret    

0000038a <mkdir>:
SYSCALL(mkdir)
 38a:	b8 14 00 00 00       	mov    $0x14,%eax
 38f:	cd 40                	int    $0x40
 391:	c3                   	ret    

00000392 <chdir>:
SYSCALL(chdir)
 392:	b8 09 00 00 00       	mov    $0x9,%eax
 397:	cd 40                	int    $0x40
 399:	c3                   	ret    

0000039a <dup>:
SYSCALL(dup)
 39a:	b8 0a 00 00 00       	mov    $0xa,%eax
 39f:	cd 40                	int    $0x40
 3a1:	c3                   	ret    

000003a2 <getpid>:
SYSCALL(getpid)
 3a2:	b8 0b 00 00 00       	mov    $0xb,%eax
 3a7:	cd 40                	int    $0x40
 3a9:	c3                   	ret    

000003aa <sbrk>:
SYSCALL(sbrk)
 3aa:	b8 0c 00 00 00       	mov    $0xc,%eax
 3af:	cd 40                	int    $0x40
 3b1:	c3                   	ret    

000003b2 <sleep>:
SYSCALL(sleep)
 3b2:	b8 0d 00 00 00       	mov    $0xd,%eax
 3b7:	cd 40                	int    $0x40
 3b9:	c3                   	ret    

000003ba <uptime>:
SYSCALL(uptime)
 3ba:	b8 0e 00 00 00       	mov    $0xe,%eax
 3bf:	cd 40                	int    $0x40
 3c1:	c3                   	ret    

000003c2 <setpri>:
// adding sys calls
SYSCALL(setpri)
 3c2:	b8 16 00 00 00       	mov    $0x16,%eax
 3c7:	cd 40                	int    $0x40
 3c9:	c3                   	ret    

000003ca <getpri>:
SYSCALL(getpri)
 3ca:	b8 17 00 00 00       	mov    $0x17,%eax
 3cf:	cd 40                	int    $0x40
 3d1:	c3                   	ret    

000003d2 <fork2>:
SYSCALL(fork2)
 3d2:	b8 18 00 00 00       	mov    $0x18,%eax
 3d7:	cd 40                	int    $0x40
 3d9:	c3                   	ret    

000003da <getpinfo>:
SYSCALL(getpinfo)
 3da:	b8 19 00 00 00       	mov    $0x19,%eax
 3df:	cd 40                	int    $0x40
 3e1:	c3                   	ret    

000003e2 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 3e2:	55                   	push   %ebp
 3e3:	89 e5                	mov    %esp,%ebp
 3e5:	83 ec 1c             	sub    $0x1c,%esp
 3e8:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 3eb:	6a 01                	push   $0x1
 3ed:	8d 55 f4             	lea    -0xc(%ebp),%edx
 3f0:	52                   	push   %edx
 3f1:	50                   	push   %eax
 3f2:	e8 4b ff ff ff       	call   342 <write>
}
 3f7:	83 c4 10             	add    $0x10,%esp
 3fa:	c9                   	leave  
 3fb:	c3                   	ret    

000003fc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3fc:	55                   	push   %ebp
 3fd:	89 e5                	mov    %esp,%ebp
 3ff:	57                   	push   %edi
 400:	56                   	push   %esi
 401:	53                   	push   %ebx
 402:	83 ec 2c             	sub    $0x2c,%esp
 405:	89 c7                	mov    %eax,%edi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 407:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 40b:	0f 95 c3             	setne  %bl
 40e:	89 d0                	mov    %edx,%eax
 410:	c1 e8 1f             	shr    $0x1f,%eax
 413:	84 c3                	test   %al,%bl
 415:	74 10                	je     427 <printint+0x2b>
    neg = 1;
    x = -xx;
 417:	f7 da                	neg    %edx
    neg = 1;
 419:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 420:	be 00 00 00 00       	mov    $0x0,%esi
 425:	eb 0b                	jmp    432 <printint+0x36>
  neg = 0;
 427:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 42e:	eb f0                	jmp    420 <printint+0x24>
  do{
    buf[i++] = digits[x % base];
 430:	89 c6                	mov    %eax,%esi
 432:	89 d0                	mov    %edx,%eax
 434:	ba 00 00 00 00       	mov    $0x0,%edx
 439:	f7 f1                	div    %ecx
 43b:	89 c3                	mov    %eax,%ebx
 43d:	8d 46 01             	lea    0x1(%esi),%eax
 440:	0f b6 92 50 07 00 00 	movzbl 0x750(%edx),%edx
 447:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
 44b:	89 da                	mov    %ebx,%edx
 44d:	85 db                	test   %ebx,%ebx
 44f:	75 df                	jne    430 <printint+0x34>
 451:	89 c3                	mov    %eax,%ebx
  if(neg)
 453:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 457:	74 16                	je     46f <printint+0x73>
    buf[i++] = '-';
 459:	c6 44 05 d8 2d       	movb   $0x2d,-0x28(%ebp,%eax,1)
 45e:	8d 5e 02             	lea    0x2(%esi),%ebx
 461:	eb 0c                	jmp    46f <printint+0x73>

  while(--i >= 0)
    putc(fd, buf[i]);
 463:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 468:	89 f8                	mov    %edi,%eax
 46a:	e8 73 ff ff ff       	call   3e2 <putc>
  while(--i >= 0)
 46f:	83 eb 01             	sub    $0x1,%ebx
 472:	79 ef                	jns    463 <printint+0x67>
}
 474:	83 c4 2c             	add    $0x2c,%esp
 477:	5b                   	pop    %ebx
 478:	5e                   	pop    %esi
 479:	5f                   	pop    %edi
 47a:	5d                   	pop    %ebp
 47b:	c3                   	ret    

0000047c <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, const char *fmt, ...)
{
 47c:	55                   	push   %ebp
 47d:	89 e5                	mov    %esp,%ebp
 47f:	57                   	push   %edi
 480:	56                   	push   %esi
 481:	53                   	push   %ebx
 482:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 485:	8d 45 10             	lea    0x10(%ebp),%eax
 488:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 48b:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 490:	bb 00 00 00 00       	mov    $0x0,%ebx
 495:	eb 14                	jmp    4ab <printf+0x2f>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 497:	89 fa                	mov    %edi,%edx
 499:	8b 45 08             	mov    0x8(%ebp),%eax
 49c:	e8 41 ff ff ff       	call   3e2 <putc>
 4a1:	eb 05                	jmp    4a8 <printf+0x2c>
      }
    } else if(state == '%'){
 4a3:	83 fe 25             	cmp    $0x25,%esi
 4a6:	74 25                	je     4cd <printf+0x51>
  for(i = 0; fmt[i]; i++){
 4a8:	83 c3 01             	add    $0x1,%ebx
 4ab:	8b 45 0c             	mov    0xc(%ebp),%eax
 4ae:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 4b2:	84 c0                	test   %al,%al
 4b4:	0f 84 23 01 00 00    	je     5dd <printf+0x161>
    c = fmt[i] & 0xff;
 4ba:	0f be f8             	movsbl %al,%edi
 4bd:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 4c0:	85 f6                	test   %esi,%esi
 4c2:	75 df                	jne    4a3 <printf+0x27>
      if(c == '%'){
 4c4:	83 f8 25             	cmp    $0x25,%eax
 4c7:	75 ce                	jne    497 <printf+0x1b>
        state = '%';
 4c9:	89 c6                	mov    %eax,%esi
 4cb:	eb db                	jmp    4a8 <printf+0x2c>
      if(c == 'd'){
 4cd:	83 f8 64             	cmp    $0x64,%eax
 4d0:	74 49                	je     51b <printf+0x9f>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 4d2:	83 f8 78             	cmp    $0x78,%eax
 4d5:	0f 94 c1             	sete   %cl
 4d8:	83 f8 70             	cmp    $0x70,%eax
 4db:	0f 94 c2             	sete   %dl
 4de:	08 d1                	or     %dl,%cl
 4e0:	75 63                	jne    545 <printf+0xc9>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 4e2:	83 f8 73             	cmp    $0x73,%eax
 4e5:	0f 84 84 00 00 00    	je     56f <printf+0xf3>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4eb:	83 f8 63             	cmp    $0x63,%eax
 4ee:	0f 84 b7 00 00 00    	je     5ab <printf+0x12f>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 4f4:	83 f8 25             	cmp    $0x25,%eax
 4f7:	0f 84 cc 00 00 00    	je     5c9 <printf+0x14d>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4fd:	ba 25 00 00 00       	mov    $0x25,%edx
 502:	8b 45 08             	mov    0x8(%ebp),%eax
 505:	e8 d8 fe ff ff       	call   3e2 <putc>
        putc(fd, c);
 50a:	89 fa                	mov    %edi,%edx
 50c:	8b 45 08             	mov    0x8(%ebp),%eax
 50f:	e8 ce fe ff ff       	call   3e2 <putc>
      }
      state = 0;
 514:	be 00 00 00 00       	mov    $0x0,%esi
 519:	eb 8d                	jmp    4a8 <printf+0x2c>
        printint(fd, *ap, 10, 1);
 51b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 51e:	8b 17                	mov    (%edi),%edx
 520:	83 ec 0c             	sub    $0xc,%esp
 523:	6a 01                	push   $0x1
 525:	b9 0a 00 00 00       	mov    $0xa,%ecx
 52a:	8b 45 08             	mov    0x8(%ebp),%eax
 52d:	e8 ca fe ff ff       	call   3fc <printint>
        ap++;
 532:	83 c7 04             	add    $0x4,%edi
 535:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 538:	83 c4 10             	add    $0x10,%esp
      state = 0;
 53b:	be 00 00 00 00       	mov    $0x0,%esi
 540:	e9 63 ff ff ff       	jmp    4a8 <printf+0x2c>
        printint(fd, *ap, 16, 0);
 545:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 548:	8b 17                	mov    (%edi),%edx
 54a:	83 ec 0c             	sub    $0xc,%esp
 54d:	6a 00                	push   $0x0
 54f:	b9 10 00 00 00       	mov    $0x10,%ecx
 554:	8b 45 08             	mov    0x8(%ebp),%eax
 557:	e8 a0 fe ff ff       	call   3fc <printint>
        ap++;
 55c:	83 c7 04             	add    $0x4,%edi
 55f:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 562:	83 c4 10             	add    $0x10,%esp
      state = 0;
 565:	be 00 00 00 00       	mov    $0x0,%esi
 56a:	e9 39 ff ff ff       	jmp    4a8 <printf+0x2c>
        s = (char*)*ap;
 56f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 572:	8b 30                	mov    (%eax),%esi
        ap++;
 574:	83 c0 04             	add    $0x4,%eax
 577:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 57a:	85 f6                	test   %esi,%esi
 57c:	75 28                	jne    5a6 <printf+0x12a>
          s = "(null)";
 57e:	be 49 07 00 00       	mov    $0x749,%esi
 583:	8b 7d 08             	mov    0x8(%ebp),%edi
 586:	eb 0d                	jmp    595 <printf+0x119>
          putc(fd, *s);
 588:	0f be d2             	movsbl %dl,%edx
 58b:	89 f8                	mov    %edi,%eax
 58d:	e8 50 fe ff ff       	call   3e2 <putc>
          s++;
 592:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 595:	0f b6 16             	movzbl (%esi),%edx
 598:	84 d2                	test   %dl,%dl
 59a:	75 ec                	jne    588 <printf+0x10c>
      state = 0;
 59c:	be 00 00 00 00       	mov    $0x0,%esi
 5a1:	e9 02 ff ff ff       	jmp    4a8 <printf+0x2c>
 5a6:	8b 7d 08             	mov    0x8(%ebp),%edi
 5a9:	eb ea                	jmp    595 <printf+0x119>
        putc(fd, *ap);
 5ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 5ae:	0f be 17             	movsbl (%edi),%edx
 5b1:	8b 45 08             	mov    0x8(%ebp),%eax
 5b4:	e8 29 fe ff ff       	call   3e2 <putc>
        ap++;
 5b9:	83 c7 04             	add    $0x4,%edi
 5bc:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 5bf:	be 00 00 00 00       	mov    $0x0,%esi
 5c4:	e9 df fe ff ff       	jmp    4a8 <printf+0x2c>
        putc(fd, c);
 5c9:	89 fa                	mov    %edi,%edx
 5cb:	8b 45 08             	mov    0x8(%ebp),%eax
 5ce:	e8 0f fe ff ff       	call   3e2 <putc>
      state = 0;
 5d3:	be 00 00 00 00       	mov    $0x0,%esi
 5d8:	e9 cb fe ff ff       	jmp    4a8 <printf+0x2c>
    }
  }
}
 5dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
 5e0:	5b                   	pop    %ebx
 5e1:	5e                   	pop    %esi
 5e2:	5f                   	pop    %edi
 5e3:	5d                   	pop    %ebp
 5e4:	c3                   	ret    

000005e5 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 5e5:	55                   	push   %ebp
 5e6:	89 e5                	mov    %esp,%ebp
 5e8:	57                   	push   %edi
 5e9:	56                   	push   %esi
 5ea:	53                   	push   %ebx
 5eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 5ee:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 5f1:	a1 24 0a 00 00       	mov    0xa24,%eax
 5f6:	eb 02                	jmp    5fa <free+0x15>
 5f8:	89 d0                	mov    %edx,%eax
 5fa:	39 c8                	cmp    %ecx,%eax
 5fc:	73 04                	jae    602 <free+0x1d>
 5fe:	39 08                	cmp    %ecx,(%eax)
 600:	77 12                	ja     614 <free+0x2f>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 602:	8b 10                	mov    (%eax),%edx
 604:	39 c2                	cmp    %eax,%edx
 606:	77 f0                	ja     5f8 <free+0x13>
 608:	39 c8                	cmp    %ecx,%eax
 60a:	72 08                	jb     614 <free+0x2f>
 60c:	39 ca                	cmp    %ecx,%edx
 60e:	77 04                	ja     614 <free+0x2f>
 610:	89 d0                	mov    %edx,%eax
 612:	eb e6                	jmp    5fa <free+0x15>
      break;
  if(bp + bp->s.size == p->s.ptr){
 614:	8b 73 fc             	mov    -0x4(%ebx),%esi
 617:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 61a:	8b 10                	mov    (%eax),%edx
 61c:	39 d7                	cmp    %edx,%edi
 61e:	74 19                	je     639 <free+0x54>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 620:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 623:	8b 50 04             	mov    0x4(%eax),%edx
 626:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 629:	39 ce                	cmp    %ecx,%esi
 62b:	74 1b                	je     648 <free+0x63>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 62d:	89 08                	mov    %ecx,(%eax)
  freep = p;
 62f:	a3 24 0a 00 00       	mov    %eax,0xa24
}
 634:	5b                   	pop    %ebx
 635:	5e                   	pop    %esi
 636:	5f                   	pop    %edi
 637:	5d                   	pop    %ebp
 638:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 639:	03 72 04             	add    0x4(%edx),%esi
 63c:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 63f:	8b 10                	mov    (%eax),%edx
 641:	8b 12                	mov    (%edx),%edx
 643:	89 53 f8             	mov    %edx,-0x8(%ebx)
 646:	eb db                	jmp    623 <free+0x3e>
    p->s.size += bp->s.size;
 648:	03 53 fc             	add    -0x4(%ebx),%edx
 64b:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 64e:	8b 53 f8             	mov    -0x8(%ebx),%edx
 651:	89 10                	mov    %edx,(%eax)
 653:	eb da                	jmp    62f <free+0x4a>

00000655 <morecore>:

static Header*
morecore(uint nu)
{
 655:	55                   	push   %ebp
 656:	89 e5                	mov    %esp,%ebp
 658:	53                   	push   %ebx
 659:	83 ec 04             	sub    $0x4,%esp
 65c:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 65e:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 663:	77 05                	ja     66a <morecore+0x15>
    nu = 4096;
 665:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 66a:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 671:	83 ec 0c             	sub    $0xc,%esp
 674:	50                   	push   %eax
 675:	e8 30 fd ff ff       	call   3aa <sbrk>
  if(p == (char*)-1)
 67a:	83 c4 10             	add    $0x10,%esp
 67d:	83 f8 ff             	cmp    $0xffffffff,%eax
 680:	74 1c                	je     69e <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 682:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 685:	83 c0 08             	add    $0x8,%eax
 688:	83 ec 0c             	sub    $0xc,%esp
 68b:	50                   	push   %eax
 68c:	e8 54 ff ff ff       	call   5e5 <free>
  return freep;
 691:	a1 24 0a 00 00       	mov    0xa24,%eax
 696:	83 c4 10             	add    $0x10,%esp
}
 699:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 69c:	c9                   	leave  
 69d:	c3                   	ret    
    return 0;
 69e:	b8 00 00 00 00       	mov    $0x0,%eax
 6a3:	eb f4                	jmp    699 <morecore+0x44>

000006a5 <malloc>:

void*
malloc(uint nbytes)
{
 6a5:	55                   	push   %ebp
 6a6:	89 e5                	mov    %esp,%ebp
 6a8:	53                   	push   %ebx
 6a9:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6ac:	8b 45 08             	mov    0x8(%ebp),%eax
 6af:	8d 58 07             	lea    0x7(%eax),%ebx
 6b2:	c1 eb 03             	shr    $0x3,%ebx
 6b5:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 6b8:	8b 0d 24 0a 00 00    	mov    0xa24,%ecx
 6be:	85 c9                	test   %ecx,%ecx
 6c0:	74 04                	je     6c6 <malloc+0x21>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 6c2:	8b 01                	mov    (%ecx),%eax
 6c4:	eb 4d                	jmp    713 <malloc+0x6e>
    base.s.ptr = freep = prevp = &base;
 6c6:	c7 05 24 0a 00 00 28 	movl   $0xa28,0xa24
 6cd:	0a 00 00 
 6d0:	c7 05 28 0a 00 00 28 	movl   $0xa28,0xa28
 6d7:	0a 00 00 
    base.s.size = 0;
 6da:	c7 05 2c 0a 00 00 00 	movl   $0x0,0xa2c
 6e1:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 6e4:	b9 28 0a 00 00       	mov    $0xa28,%ecx
 6e9:	eb d7                	jmp    6c2 <malloc+0x1d>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 6eb:	39 da                	cmp    %ebx,%edx
 6ed:	74 1a                	je     709 <malloc+0x64>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 6ef:	29 da                	sub    %ebx,%edx
 6f1:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 6f4:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 6f7:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 6fa:	89 0d 24 0a 00 00    	mov    %ecx,0xa24
      return (void*)(p + 1);
 700:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 703:	83 c4 04             	add    $0x4,%esp
 706:	5b                   	pop    %ebx
 707:	5d                   	pop    %ebp
 708:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 709:	8b 10                	mov    (%eax),%edx
 70b:	89 11                	mov    %edx,(%ecx)
 70d:	eb eb                	jmp    6fa <malloc+0x55>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 70f:	89 c1                	mov    %eax,%ecx
 711:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 713:	8b 50 04             	mov    0x4(%eax),%edx
 716:	39 da                	cmp    %ebx,%edx
 718:	73 d1                	jae    6eb <malloc+0x46>
    if(p == freep)
 71a:	39 05 24 0a 00 00    	cmp    %eax,0xa24
 720:	75 ed                	jne    70f <malloc+0x6a>
      if((p = morecore(nunits)) == 0)
 722:	89 d8                	mov    %ebx,%eax
 724:	e8 2c ff ff ff       	call   655 <morecore>
 729:	85 c0                	test   %eax,%eax
 72b:	75 e2                	jne    70f <malloc+0x6a>
        return 0;
 72d:	b8 00 00 00 00       	mov    $0x0,%eax
 732:	eb cf                	jmp    703 <malloc+0x5e>
