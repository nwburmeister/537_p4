
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


    char **ptr = &job;
    struct pstat *pstat = malloc(sizeof(struct pstat));
   c:	68 00 0c 00 00       	push   $0xc00
  11:	e8 82 06 00 00       	call   698 <malloc>
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
  22:	e8 ee 02 00 00       	call   315 <exit>
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
  33:	e8 8d 03 00 00       	call   3c5 <fork2>
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
  4d:	e8 fb 02 00 00       	call   34d <exec>
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
//                int pri = getpri(pstat->pid[j]);
                setpri(pstat->pid[j], 3);
  70:	83 ec 08             	sub    $0x8,%esp
  73:	6a 03                	push   $0x3
  75:	ff b4 9e 00 01 00 00 	pushl  0x100(%esi,%ebx,4)
  7c:	e8 34 03 00 00       	call   3b5 <setpri>
  81:	83 c4 10             	add    $0x10,%esp
  84:	eb d8                	jmp    5e <roundRobin+0x5e>
            }
        }

        sleep(timeslice);
  86:	83 ec 0c             	sub    $0xc,%esp
  89:	ff 75 08             	pushl  0x8(%ebp)
  8c:	e8 14 03 00 00       	call   3a5 <sleep>
    for (int i = 0; i < iterations; i++){
  91:	83 c7 01             	add    $0x1,%edi
  94:	83 c4 10             	add    $0x10,%esp
  97:	3b 7d 0c             	cmp    0xc(%ebp),%edi
  9a:	7d 13                	jge    af <roundRobin+0xaf>
        getpinfo(pstat);
  9c:	83 ec 0c             	sub    $0xc,%esp
  9f:	56                   	push   %esi
  a0:	e8 28 03 00 00       	call   3cd <getpinfo>
        for(int j = 0; j < NPROC; j++) {
  a5:	83 c4 10             	add    $0x10,%esp
  a8:	bb 00 00 00 00       	mov    $0x0,%ebx
  ad:	eb b2                	jmp    61 <roundRobin+0x61>
    }




    getpinfo(pstat);
  af:	83 ec 0c             	sub    $0xc,%esp
  b2:	56                   	push   %esi
  b3:	e8 15 03 00 00       	call   3cd <getpinfo>
    for (int i = 0; i < NPROC; i++) {
  b8:	83 c4 10             	add    $0x10,%esp
  bb:	bb 00 00 00 00       	mov    $0x0,%ebx
  c0:	eb 15                	jmp    d7 <roundRobin+0xd7>
        for (int k = 0; k < 4; k++){
  c2:	83 c0 01             	add    $0x1,%eax
  c5:	83 f8 03             	cmp    $0x3,%eax
  c8:	7e f8                	jle    c2 <roundRobin+0xc2>
            // printf(1, "IS IN-USE %d XV6_SCHEDULER\t \t level %d ticks used %d\n", pstat->inuse[i], k, pstat->ticks[i][k]);
            // printf(1, "XV6_SCHEDULER\t \t level %d ticks used %d\n", k, pstat->ticks[i][k]);
        }
        if (pstat->state[i] == ZOMBIE) {
  ca:	83 bc 9e 00 03 00 00 	cmpl   $0x5,0x300(%esi,%ebx,4)
  d1:	05 
  d2:	74 0f                	je     e3 <roundRobin+0xe3>
    for (int i = 0; i < NPROC; i++) {
  d4:	83 c3 01             	add    $0x1,%ebx
  d7:	83 fb 3f             	cmp    $0x3f,%ebx
  da:	7f 20                	jg     fc <roundRobin+0xfc>
        for (int k = 0; k < 4; k++){
  dc:	b8 00 00 00 00       	mov    $0x0,%eax
  e1:	eb e2                	jmp    c5 <roundRobin+0xc5>
            //printf(1, "%s\n", "entered");
            wait();
  e3:	e8 35 02 00 00       	call   31d <wait>
            kill(pstat->pid[i]);
  e8:	83 ec 0c             	sub    $0xc,%esp
  eb:	ff b4 9e 00 01 00 00 	pushl  0x100(%esi,%ebx,4)
  f2:	e8 4e 02 00 00       	call   345 <kill>
  f7:	83 c4 10             	add    $0x10,%esp
  fa:	eb d8                	jmp    d4 <roundRobin+0xd4>
        }
    }


}
  fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
  ff:	5b                   	pop    %ebx
 100:	5e                   	pop    %esi
 101:	5f                   	pop    %edi
 102:	5d                   	pop    %ebp
 103:	c3                   	ret    

00000104 <main>:

int main(int argc, char *argv[]) {
 104:	8d 4c 24 04          	lea    0x4(%esp),%ecx
 108:	83 e4 f0             	and    $0xfffffff0,%esp
 10b:	ff 71 fc             	pushl  -0x4(%ecx)
 10e:	55                   	push   %ebp
 10f:	89 e5                	mov    %esp,%ebp
 111:	57                   	push   %edi
 112:	56                   	push   %esi
 113:	53                   	push   %ebx
 114:	51                   	push   %ecx
 115:	83 ec 18             	sub    $0x18,%esp
 118:	8b 59 04             	mov    0x4(%ecx),%ebx
    if(argc != 5) {
 11b:	83 39 05             	cmpl   $0x5,(%ecx)
 11e:	74 05                	je     125 <main+0x21>
        // TODO: print error message
        exit();
 120:	e8 f0 01 00 00       	call   315 <exit>
    }

    int timeslice = atoi(argv[1]);
 125:	83 ec 0c             	sub    $0xc,%esp
 128:	ff 73 04             	pushl  0x4(%ebx)
 12b:	e8 87 01 00 00       	call   2b7 <atoi>
 130:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    int iterations = atoi(argv[2]);
 133:	83 c4 04             	add    $0x4,%esp
 136:	ff 73 08             	pushl  0x8(%ebx)
 139:	e8 79 01 00 00       	call   2b7 <atoi>
 13e:	89 c7                	mov    %eax,%edi
    char *job = malloc(sizeof(char) * (strlen(argv[3]) + 1));
 140:	83 c4 04             	add    $0x4,%esp
 143:	ff 73 0c             	pushl  0xc(%ebx)
 146:	e8 81 00 00 00       	call   1cc <strlen>
 14b:	83 c0 01             	add    $0x1,%eax
 14e:	89 04 24             	mov    %eax,(%esp)
 151:	e8 42 05 00 00       	call   698 <malloc>
 156:	89 c6                	mov    %eax,%esi
    strcpy(job, argv[3]);
 158:	83 c4 08             	add    $0x8,%esp
 15b:	ff 73 0c             	pushl  0xc(%ebx)
 15e:	50                   	push   %eax
 15f:	e8 24 00 00 00       	call   188 <strcpy>
    int jobcount = atoi(argv[4]);
 164:	83 c4 04             	add    $0x4,%esp
 167:	ff 73 10             	pushl  0x10(%ebx)
 16a:	e8 48 01 00 00       	call   2b7 <atoi>

    roundRobin(timeslice, iterations, job, jobcount);
 16f:	50                   	push   %eax
 170:	56                   	push   %esi
 171:	57                   	push   %edi
 172:	ff 75 e4             	pushl  -0x1c(%ebp)
 175:	e8 86 fe ff ff       	call   0 <roundRobin>
    free(job);
 17a:	83 c4 14             	add    $0x14,%esp
 17d:	56                   	push   %esi
 17e:	e8 55 04 00 00       	call   5d8 <free>
    exit();
 183:	e8 8d 01 00 00       	call   315 <exit>

00000188 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, const char *t)
{
 188:	55                   	push   %ebp
 189:	89 e5                	mov    %esp,%ebp
 18b:	53                   	push   %ebx
 18c:	8b 45 08             	mov    0x8(%ebp),%eax
 18f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 192:	89 c2                	mov    %eax,%edx
 194:	0f b6 19             	movzbl (%ecx),%ebx
 197:	88 1a                	mov    %bl,(%edx)
 199:	8d 52 01             	lea    0x1(%edx),%edx
 19c:	8d 49 01             	lea    0x1(%ecx),%ecx
 19f:	84 db                	test   %bl,%bl
 1a1:	75 f1                	jne    194 <strcpy+0xc>
    ;
  return os;
}
 1a3:	5b                   	pop    %ebx
 1a4:	5d                   	pop    %ebp
 1a5:	c3                   	ret    

000001a6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1a6:	55                   	push   %ebp
 1a7:	89 e5                	mov    %esp,%ebp
 1a9:	8b 4d 08             	mov    0x8(%ebp),%ecx
 1ac:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
 1af:	eb 06                	jmp    1b7 <strcmp+0x11>
    p++, q++;
 1b1:	83 c1 01             	add    $0x1,%ecx
 1b4:	83 c2 01             	add    $0x1,%edx
  while(*p && *p == *q)
 1b7:	0f b6 01             	movzbl (%ecx),%eax
 1ba:	84 c0                	test   %al,%al
 1bc:	74 04                	je     1c2 <strcmp+0x1c>
 1be:	3a 02                	cmp    (%edx),%al
 1c0:	74 ef                	je     1b1 <strcmp+0xb>
  return (uchar)*p - (uchar)*q;
 1c2:	0f b6 c0             	movzbl %al,%eax
 1c5:	0f b6 12             	movzbl (%edx),%edx
 1c8:	29 d0                	sub    %edx,%eax
}
 1ca:	5d                   	pop    %ebp
 1cb:	c3                   	ret    

000001cc <strlen>:

uint
strlen(const char *s)
{
 1cc:	55                   	push   %ebp
 1cd:	89 e5                	mov    %esp,%ebp
 1cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
 1d2:	ba 00 00 00 00       	mov    $0x0,%edx
 1d7:	eb 03                	jmp    1dc <strlen+0x10>
 1d9:	83 c2 01             	add    $0x1,%edx
 1dc:	89 d0                	mov    %edx,%eax
 1de:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
 1e2:	75 f5                	jne    1d9 <strlen+0xd>
    ;
  return n;
}
 1e4:	5d                   	pop    %ebp
 1e5:	c3                   	ret    

000001e6 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1e6:	55                   	push   %ebp
 1e7:	89 e5                	mov    %esp,%ebp
 1e9:	57                   	push   %edi
 1ea:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
 1ed:	89 d7                	mov    %edx,%edi
 1ef:	8b 4d 10             	mov    0x10(%ebp),%ecx
 1f2:	8b 45 0c             	mov    0xc(%ebp),%eax
 1f5:	fc                   	cld    
 1f6:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
 1f8:	89 d0                	mov    %edx,%eax
 1fa:	5f                   	pop    %edi
 1fb:	5d                   	pop    %ebp
 1fc:	c3                   	ret    

000001fd <strchr>:

char*
strchr(const char *s, char c)
{
 1fd:	55                   	push   %ebp
 1fe:	89 e5                	mov    %esp,%ebp
 200:	8b 45 08             	mov    0x8(%ebp),%eax
 203:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 207:	0f b6 10             	movzbl (%eax),%edx
 20a:	84 d2                	test   %dl,%dl
 20c:	74 09                	je     217 <strchr+0x1a>
    if(*s == c)
 20e:	38 ca                	cmp    %cl,%dl
 210:	74 0a                	je     21c <strchr+0x1f>
  for(; *s; s++)
 212:	83 c0 01             	add    $0x1,%eax
 215:	eb f0                	jmp    207 <strchr+0xa>
      return (char*)s;
  return 0;
 217:	b8 00 00 00 00       	mov    $0x0,%eax
}
 21c:	5d                   	pop    %ebp
 21d:	c3                   	ret    

0000021e <gets>:

char*
gets(char *buf, int max)
{
 21e:	55                   	push   %ebp
 21f:	89 e5                	mov    %esp,%ebp
 221:	57                   	push   %edi
 222:	56                   	push   %esi
 223:	53                   	push   %ebx
 224:	83 ec 1c             	sub    $0x1c,%esp
 227:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 22a:	bb 00 00 00 00       	mov    $0x0,%ebx
 22f:	8d 73 01             	lea    0x1(%ebx),%esi
 232:	3b 75 0c             	cmp    0xc(%ebp),%esi
 235:	7d 2e                	jge    265 <gets+0x47>
    cc = read(0, &c, 1);
 237:	83 ec 04             	sub    $0x4,%esp
 23a:	6a 01                	push   $0x1
 23c:	8d 45 e7             	lea    -0x19(%ebp),%eax
 23f:	50                   	push   %eax
 240:	6a 00                	push   $0x0
 242:	e8 e6 00 00 00       	call   32d <read>
    if(cc < 1)
 247:	83 c4 10             	add    $0x10,%esp
 24a:	85 c0                	test   %eax,%eax
 24c:	7e 17                	jle    265 <gets+0x47>
      break;
    buf[i++] = c;
 24e:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 252:	88 04 1f             	mov    %al,(%edi,%ebx,1)
    if(c == '\n' || c == '\r')
 255:	3c 0a                	cmp    $0xa,%al
 257:	0f 94 c2             	sete   %dl
 25a:	3c 0d                	cmp    $0xd,%al
 25c:	0f 94 c0             	sete   %al
    buf[i++] = c;
 25f:	89 f3                	mov    %esi,%ebx
    if(c == '\n' || c == '\r')
 261:	08 c2                	or     %al,%dl
 263:	74 ca                	je     22f <gets+0x11>
      break;
  }
  buf[i] = '\0';
 265:	c6 04 1f 00          	movb   $0x0,(%edi,%ebx,1)
  return buf;
}
 269:	89 f8                	mov    %edi,%eax
 26b:	8d 65 f4             	lea    -0xc(%ebp),%esp
 26e:	5b                   	pop    %ebx
 26f:	5e                   	pop    %esi
 270:	5f                   	pop    %edi
 271:	5d                   	pop    %ebp
 272:	c3                   	ret    

00000273 <stat>:

int
stat(const char *n, struct stat *st)
{
 273:	55                   	push   %ebp
 274:	89 e5                	mov    %esp,%ebp
 276:	56                   	push   %esi
 277:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 278:	83 ec 08             	sub    $0x8,%esp
 27b:	6a 00                	push   $0x0
 27d:	ff 75 08             	pushl  0x8(%ebp)
 280:	e8 d0 00 00 00       	call   355 <open>
  if(fd < 0)
 285:	83 c4 10             	add    $0x10,%esp
 288:	85 c0                	test   %eax,%eax
 28a:	78 24                	js     2b0 <stat+0x3d>
 28c:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 28e:	83 ec 08             	sub    $0x8,%esp
 291:	ff 75 0c             	pushl  0xc(%ebp)
 294:	50                   	push   %eax
 295:	e8 d3 00 00 00       	call   36d <fstat>
 29a:	89 c6                	mov    %eax,%esi
  close(fd);
 29c:	89 1c 24             	mov    %ebx,(%esp)
 29f:	e8 99 00 00 00       	call   33d <close>
  return r;
 2a4:	83 c4 10             	add    $0x10,%esp
}
 2a7:	89 f0                	mov    %esi,%eax
 2a9:	8d 65 f8             	lea    -0x8(%ebp),%esp
 2ac:	5b                   	pop    %ebx
 2ad:	5e                   	pop    %esi
 2ae:	5d                   	pop    %ebp
 2af:	c3                   	ret    
    return -1;
 2b0:	be ff ff ff ff       	mov    $0xffffffff,%esi
 2b5:	eb f0                	jmp    2a7 <stat+0x34>

000002b7 <atoi>:

int
atoi(const char *s)
{
 2b7:	55                   	push   %ebp
 2b8:	89 e5                	mov    %esp,%ebp
 2ba:	53                   	push   %ebx
 2bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  n = 0;
 2be:	b8 00 00 00 00       	mov    $0x0,%eax
  while('0' <= *s && *s <= '9')
 2c3:	eb 10                	jmp    2d5 <atoi+0x1e>
    n = n*10 + *s++ - '0';
 2c5:	8d 1c 80             	lea    (%eax,%eax,4),%ebx
 2c8:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
 2cb:	83 c1 01             	add    $0x1,%ecx
 2ce:	0f be d2             	movsbl %dl,%edx
 2d1:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
  while('0' <= *s && *s <= '9')
 2d5:	0f b6 11             	movzbl (%ecx),%edx
 2d8:	8d 5a d0             	lea    -0x30(%edx),%ebx
 2db:	80 fb 09             	cmp    $0x9,%bl
 2de:	76 e5                	jbe    2c5 <atoi+0xe>
  return n;
}
 2e0:	5b                   	pop    %ebx
 2e1:	5d                   	pop    %ebp
 2e2:	c3                   	ret    

000002e3 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2e3:	55                   	push   %ebp
 2e4:	89 e5                	mov    %esp,%ebp
 2e6:	56                   	push   %esi
 2e7:	53                   	push   %ebx
 2e8:	8b 45 08             	mov    0x8(%ebp),%eax
 2eb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
 2ee:	8b 55 10             	mov    0x10(%ebp),%edx
  char *dst;
  const char *src;

  dst = vdst;
 2f1:	89 c1                	mov    %eax,%ecx
  src = vsrc;
  while(n-- > 0)
 2f3:	eb 0d                	jmp    302 <memmove+0x1f>
    *dst++ = *src++;
 2f5:	0f b6 13             	movzbl (%ebx),%edx
 2f8:	88 11                	mov    %dl,(%ecx)
 2fa:	8d 5b 01             	lea    0x1(%ebx),%ebx
 2fd:	8d 49 01             	lea    0x1(%ecx),%ecx
  while(n-- > 0)
 300:	89 f2                	mov    %esi,%edx
 302:	8d 72 ff             	lea    -0x1(%edx),%esi
 305:	85 d2                	test   %edx,%edx
 307:	7f ec                	jg     2f5 <memmove+0x12>
  return vdst;
}
 309:	5b                   	pop    %ebx
 30a:	5e                   	pop    %esi
 30b:	5d                   	pop    %ebp
 30c:	c3                   	ret    

0000030d <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 30d:	b8 01 00 00 00       	mov    $0x1,%eax
 312:	cd 40                	int    $0x40
 314:	c3                   	ret    

00000315 <exit>:
SYSCALL(exit)
 315:	b8 02 00 00 00       	mov    $0x2,%eax
 31a:	cd 40                	int    $0x40
 31c:	c3                   	ret    

0000031d <wait>:
SYSCALL(wait)
 31d:	b8 03 00 00 00       	mov    $0x3,%eax
 322:	cd 40                	int    $0x40
 324:	c3                   	ret    

00000325 <pipe>:
SYSCALL(pipe)
 325:	b8 04 00 00 00       	mov    $0x4,%eax
 32a:	cd 40                	int    $0x40
 32c:	c3                   	ret    

0000032d <read>:
SYSCALL(read)
 32d:	b8 05 00 00 00       	mov    $0x5,%eax
 332:	cd 40                	int    $0x40
 334:	c3                   	ret    

00000335 <write>:
SYSCALL(write)
 335:	b8 10 00 00 00       	mov    $0x10,%eax
 33a:	cd 40                	int    $0x40
 33c:	c3                   	ret    

0000033d <close>:
SYSCALL(close)
 33d:	b8 15 00 00 00       	mov    $0x15,%eax
 342:	cd 40                	int    $0x40
 344:	c3                   	ret    

00000345 <kill>:
SYSCALL(kill)
 345:	b8 06 00 00 00       	mov    $0x6,%eax
 34a:	cd 40                	int    $0x40
 34c:	c3                   	ret    

0000034d <exec>:
SYSCALL(exec)
 34d:	b8 07 00 00 00       	mov    $0x7,%eax
 352:	cd 40                	int    $0x40
 354:	c3                   	ret    

00000355 <open>:
SYSCALL(open)
 355:	b8 0f 00 00 00       	mov    $0xf,%eax
 35a:	cd 40                	int    $0x40
 35c:	c3                   	ret    

0000035d <mknod>:
SYSCALL(mknod)
 35d:	b8 11 00 00 00       	mov    $0x11,%eax
 362:	cd 40                	int    $0x40
 364:	c3                   	ret    

00000365 <unlink>:
SYSCALL(unlink)
 365:	b8 12 00 00 00       	mov    $0x12,%eax
 36a:	cd 40                	int    $0x40
 36c:	c3                   	ret    

0000036d <fstat>:
SYSCALL(fstat)
 36d:	b8 08 00 00 00       	mov    $0x8,%eax
 372:	cd 40                	int    $0x40
 374:	c3                   	ret    

00000375 <link>:
SYSCALL(link)
 375:	b8 13 00 00 00       	mov    $0x13,%eax
 37a:	cd 40                	int    $0x40
 37c:	c3                   	ret    

0000037d <mkdir>:
SYSCALL(mkdir)
 37d:	b8 14 00 00 00       	mov    $0x14,%eax
 382:	cd 40                	int    $0x40
 384:	c3                   	ret    

00000385 <chdir>:
SYSCALL(chdir)
 385:	b8 09 00 00 00       	mov    $0x9,%eax
 38a:	cd 40                	int    $0x40
 38c:	c3                   	ret    

0000038d <dup>:
SYSCALL(dup)
 38d:	b8 0a 00 00 00       	mov    $0xa,%eax
 392:	cd 40                	int    $0x40
 394:	c3                   	ret    

00000395 <getpid>:
SYSCALL(getpid)
 395:	b8 0b 00 00 00       	mov    $0xb,%eax
 39a:	cd 40                	int    $0x40
 39c:	c3                   	ret    

0000039d <sbrk>:
SYSCALL(sbrk)
 39d:	b8 0c 00 00 00       	mov    $0xc,%eax
 3a2:	cd 40                	int    $0x40
 3a4:	c3                   	ret    

000003a5 <sleep>:
SYSCALL(sleep)
 3a5:	b8 0d 00 00 00       	mov    $0xd,%eax
 3aa:	cd 40                	int    $0x40
 3ac:	c3                   	ret    

000003ad <uptime>:
SYSCALL(uptime)
 3ad:	b8 0e 00 00 00       	mov    $0xe,%eax
 3b2:	cd 40                	int    $0x40
 3b4:	c3                   	ret    

000003b5 <setpri>:
// adding sys calls
SYSCALL(setpri)
 3b5:	b8 16 00 00 00       	mov    $0x16,%eax
 3ba:	cd 40                	int    $0x40
 3bc:	c3                   	ret    

000003bd <getpri>:
SYSCALL(getpri)
 3bd:	b8 17 00 00 00       	mov    $0x17,%eax
 3c2:	cd 40                	int    $0x40
 3c4:	c3                   	ret    

000003c5 <fork2>:
SYSCALL(fork2)
 3c5:	b8 18 00 00 00       	mov    $0x18,%eax
 3ca:	cd 40                	int    $0x40
 3cc:	c3                   	ret    

000003cd <getpinfo>:
SYSCALL(getpinfo)
 3cd:	b8 19 00 00 00       	mov    $0x19,%eax
 3d2:	cd 40                	int    $0x40
 3d4:	c3                   	ret    

000003d5 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 3d5:	55                   	push   %ebp
 3d6:	89 e5                	mov    %esp,%ebp
 3d8:	83 ec 1c             	sub    $0x1c,%esp
 3db:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 3de:	6a 01                	push   $0x1
 3e0:	8d 55 f4             	lea    -0xc(%ebp),%edx
 3e3:	52                   	push   %edx
 3e4:	50                   	push   %eax
 3e5:	e8 4b ff ff ff       	call   335 <write>
}
 3ea:	83 c4 10             	add    $0x10,%esp
 3ed:	c9                   	leave  
 3ee:	c3                   	ret    

000003ef <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3ef:	55                   	push   %ebp
 3f0:	89 e5                	mov    %esp,%ebp
 3f2:	57                   	push   %edi
 3f3:	56                   	push   %esi
 3f4:	53                   	push   %ebx
 3f5:	83 ec 2c             	sub    $0x2c,%esp
 3f8:	89 c7                	mov    %eax,%edi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3fa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 3fe:	0f 95 c3             	setne  %bl
 401:	89 d0                	mov    %edx,%eax
 403:	c1 e8 1f             	shr    $0x1f,%eax
 406:	84 c3                	test   %al,%bl
 408:	74 10                	je     41a <printint+0x2b>
    neg = 1;
    x = -xx;
 40a:	f7 da                	neg    %edx
    neg = 1;
 40c:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 413:	be 00 00 00 00       	mov    $0x0,%esi
 418:	eb 0b                	jmp    425 <printint+0x36>
  neg = 0;
 41a:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 421:	eb f0                	jmp    413 <printint+0x24>
  do{
    buf[i++] = digits[x % base];
 423:	89 c6                	mov    %eax,%esi
 425:	89 d0                	mov    %edx,%eax
 427:	ba 00 00 00 00       	mov    $0x0,%edx
 42c:	f7 f1                	div    %ecx
 42e:	89 c3                	mov    %eax,%ebx
 430:	8d 46 01             	lea    0x1(%esi),%eax
 433:	0f b6 92 30 07 00 00 	movzbl 0x730(%edx),%edx
 43a:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
 43e:	89 da                	mov    %ebx,%edx
 440:	85 db                	test   %ebx,%ebx
 442:	75 df                	jne    423 <printint+0x34>
 444:	89 c3                	mov    %eax,%ebx
  if(neg)
 446:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 44a:	74 16                	je     462 <printint+0x73>
    buf[i++] = '-';
 44c:	c6 44 05 d8 2d       	movb   $0x2d,-0x28(%ebp,%eax,1)
 451:	8d 5e 02             	lea    0x2(%esi),%ebx
 454:	eb 0c                	jmp    462 <printint+0x73>

  while(--i >= 0)
    putc(fd, buf[i]);
 456:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 45b:	89 f8                	mov    %edi,%eax
 45d:	e8 73 ff ff ff       	call   3d5 <putc>
  while(--i >= 0)
 462:	83 eb 01             	sub    $0x1,%ebx
 465:	79 ef                	jns    456 <printint+0x67>
}
 467:	83 c4 2c             	add    $0x2c,%esp
 46a:	5b                   	pop    %ebx
 46b:	5e                   	pop    %esi
 46c:	5f                   	pop    %edi
 46d:	5d                   	pop    %ebp
 46e:	c3                   	ret    

0000046f <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, const char *fmt, ...)
{
 46f:	55                   	push   %ebp
 470:	89 e5                	mov    %esp,%ebp
 472:	57                   	push   %edi
 473:	56                   	push   %esi
 474:	53                   	push   %ebx
 475:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 478:	8d 45 10             	lea    0x10(%ebp),%eax
 47b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 47e:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 483:	bb 00 00 00 00       	mov    $0x0,%ebx
 488:	eb 14                	jmp    49e <printf+0x2f>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 48a:	89 fa                	mov    %edi,%edx
 48c:	8b 45 08             	mov    0x8(%ebp),%eax
 48f:	e8 41 ff ff ff       	call   3d5 <putc>
 494:	eb 05                	jmp    49b <printf+0x2c>
      }
    } else if(state == '%'){
 496:	83 fe 25             	cmp    $0x25,%esi
 499:	74 25                	je     4c0 <printf+0x51>
  for(i = 0; fmt[i]; i++){
 49b:	83 c3 01             	add    $0x1,%ebx
 49e:	8b 45 0c             	mov    0xc(%ebp),%eax
 4a1:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 4a5:	84 c0                	test   %al,%al
 4a7:	0f 84 23 01 00 00    	je     5d0 <printf+0x161>
    c = fmt[i] & 0xff;
 4ad:	0f be f8             	movsbl %al,%edi
 4b0:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 4b3:	85 f6                	test   %esi,%esi
 4b5:	75 df                	jne    496 <printf+0x27>
      if(c == '%'){
 4b7:	83 f8 25             	cmp    $0x25,%eax
 4ba:	75 ce                	jne    48a <printf+0x1b>
        state = '%';
 4bc:	89 c6                	mov    %eax,%esi
 4be:	eb db                	jmp    49b <printf+0x2c>
      if(c == 'd'){
 4c0:	83 f8 64             	cmp    $0x64,%eax
 4c3:	74 49                	je     50e <printf+0x9f>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 4c5:	83 f8 78             	cmp    $0x78,%eax
 4c8:	0f 94 c1             	sete   %cl
 4cb:	83 f8 70             	cmp    $0x70,%eax
 4ce:	0f 94 c2             	sete   %dl
 4d1:	08 d1                	or     %dl,%cl
 4d3:	75 63                	jne    538 <printf+0xc9>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 4d5:	83 f8 73             	cmp    $0x73,%eax
 4d8:	0f 84 84 00 00 00    	je     562 <printf+0xf3>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4de:	83 f8 63             	cmp    $0x63,%eax
 4e1:	0f 84 b7 00 00 00    	je     59e <printf+0x12f>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 4e7:	83 f8 25             	cmp    $0x25,%eax
 4ea:	0f 84 cc 00 00 00    	je     5bc <printf+0x14d>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4f0:	ba 25 00 00 00       	mov    $0x25,%edx
 4f5:	8b 45 08             	mov    0x8(%ebp),%eax
 4f8:	e8 d8 fe ff ff       	call   3d5 <putc>
        putc(fd, c);
 4fd:	89 fa                	mov    %edi,%edx
 4ff:	8b 45 08             	mov    0x8(%ebp),%eax
 502:	e8 ce fe ff ff       	call   3d5 <putc>
      }
      state = 0;
 507:	be 00 00 00 00       	mov    $0x0,%esi
 50c:	eb 8d                	jmp    49b <printf+0x2c>
        printint(fd, *ap, 10, 1);
 50e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 511:	8b 17                	mov    (%edi),%edx
 513:	83 ec 0c             	sub    $0xc,%esp
 516:	6a 01                	push   $0x1
 518:	b9 0a 00 00 00       	mov    $0xa,%ecx
 51d:	8b 45 08             	mov    0x8(%ebp),%eax
 520:	e8 ca fe ff ff       	call   3ef <printint>
        ap++;
 525:	83 c7 04             	add    $0x4,%edi
 528:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 52b:	83 c4 10             	add    $0x10,%esp
      state = 0;
 52e:	be 00 00 00 00       	mov    $0x0,%esi
 533:	e9 63 ff ff ff       	jmp    49b <printf+0x2c>
        printint(fd, *ap, 16, 0);
 538:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 53b:	8b 17                	mov    (%edi),%edx
 53d:	83 ec 0c             	sub    $0xc,%esp
 540:	6a 00                	push   $0x0
 542:	b9 10 00 00 00       	mov    $0x10,%ecx
 547:	8b 45 08             	mov    0x8(%ebp),%eax
 54a:	e8 a0 fe ff ff       	call   3ef <printint>
        ap++;
 54f:	83 c7 04             	add    $0x4,%edi
 552:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 555:	83 c4 10             	add    $0x10,%esp
      state = 0;
 558:	be 00 00 00 00       	mov    $0x0,%esi
 55d:	e9 39 ff ff ff       	jmp    49b <printf+0x2c>
        s = (char*)*ap;
 562:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 565:	8b 30                	mov    (%eax),%esi
        ap++;
 567:	83 c0 04             	add    $0x4,%eax
 56a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 56d:	85 f6                	test   %esi,%esi
 56f:	75 28                	jne    599 <printf+0x12a>
          s = "(null)";
 571:	be 28 07 00 00       	mov    $0x728,%esi
 576:	8b 7d 08             	mov    0x8(%ebp),%edi
 579:	eb 0d                	jmp    588 <printf+0x119>
          putc(fd, *s);
 57b:	0f be d2             	movsbl %dl,%edx
 57e:	89 f8                	mov    %edi,%eax
 580:	e8 50 fe ff ff       	call   3d5 <putc>
          s++;
 585:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 588:	0f b6 16             	movzbl (%esi),%edx
 58b:	84 d2                	test   %dl,%dl
 58d:	75 ec                	jne    57b <printf+0x10c>
      state = 0;
 58f:	be 00 00 00 00       	mov    $0x0,%esi
 594:	e9 02 ff ff ff       	jmp    49b <printf+0x2c>
 599:	8b 7d 08             	mov    0x8(%ebp),%edi
 59c:	eb ea                	jmp    588 <printf+0x119>
        putc(fd, *ap);
 59e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 5a1:	0f be 17             	movsbl (%edi),%edx
 5a4:	8b 45 08             	mov    0x8(%ebp),%eax
 5a7:	e8 29 fe ff ff       	call   3d5 <putc>
        ap++;
 5ac:	83 c7 04             	add    $0x4,%edi
 5af:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 5b2:	be 00 00 00 00       	mov    $0x0,%esi
 5b7:	e9 df fe ff ff       	jmp    49b <printf+0x2c>
        putc(fd, c);
 5bc:	89 fa                	mov    %edi,%edx
 5be:	8b 45 08             	mov    0x8(%ebp),%eax
 5c1:	e8 0f fe ff ff       	call   3d5 <putc>
      state = 0;
 5c6:	be 00 00 00 00       	mov    $0x0,%esi
 5cb:	e9 cb fe ff ff       	jmp    49b <printf+0x2c>
    }
  }
}
 5d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
 5d3:	5b                   	pop    %ebx
 5d4:	5e                   	pop    %esi
 5d5:	5f                   	pop    %edi
 5d6:	5d                   	pop    %ebp
 5d7:	c3                   	ret    

000005d8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 5d8:	55                   	push   %ebp
 5d9:	89 e5                	mov    %esp,%ebp
 5db:	57                   	push   %edi
 5dc:	56                   	push   %esi
 5dd:	53                   	push   %ebx
 5de:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 5e1:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 5e4:	a1 00 0a 00 00       	mov    0xa00,%eax
 5e9:	eb 02                	jmp    5ed <free+0x15>
 5eb:	89 d0                	mov    %edx,%eax
 5ed:	39 c8                	cmp    %ecx,%eax
 5ef:	73 04                	jae    5f5 <free+0x1d>
 5f1:	39 08                	cmp    %ecx,(%eax)
 5f3:	77 12                	ja     607 <free+0x2f>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 5f5:	8b 10                	mov    (%eax),%edx
 5f7:	39 c2                	cmp    %eax,%edx
 5f9:	77 f0                	ja     5eb <free+0x13>
 5fb:	39 c8                	cmp    %ecx,%eax
 5fd:	72 08                	jb     607 <free+0x2f>
 5ff:	39 ca                	cmp    %ecx,%edx
 601:	77 04                	ja     607 <free+0x2f>
 603:	89 d0                	mov    %edx,%eax
 605:	eb e6                	jmp    5ed <free+0x15>
      break;
  if(bp + bp->s.size == p->s.ptr){
 607:	8b 73 fc             	mov    -0x4(%ebx),%esi
 60a:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 60d:	8b 10                	mov    (%eax),%edx
 60f:	39 d7                	cmp    %edx,%edi
 611:	74 19                	je     62c <free+0x54>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 613:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 616:	8b 50 04             	mov    0x4(%eax),%edx
 619:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 61c:	39 ce                	cmp    %ecx,%esi
 61e:	74 1b                	je     63b <free+0x63>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 620:	89 08                	mov    %ecx,(%eax)
  freep = p;
 622:	a3 00 0a 00 00       	mov    %eax,0xa00
}
 627:	5b                   	pop    %ebx
 628:	5e                   	pop    %esi
 629:	5f                   	pop    %edi
 62a:	5d                   	pop    %ebp
 62b:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 62c:	03 72 04             	add    0x4(%edx),%esi
 62f:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 632:	8b 10                	mov    (%eax),%edx
 634:	8b 12                	mov    (%edx),%edx
 636:	89 53 f8             	mov    %edx,-0x8(%ebx)
 639:	eb db                	jmp    616 <free+0x3e>
    p->s.size += bp->s.size;
 63b:	03 53 fc             	add    -0x4(%ebx),%edx
 63e:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 641:	8b 53 f8             	mov    -0x8(%ebx),%edx
 644:	89 10                	mov    %edx,(%eax)
 646:	eb da                	jmp    622 <free+0x4a>

00000648 <morecore>:

static Header*
morecore(uint nu)
{
 648:	55                   	push   %ebp
 649:	89 e5                	mov    %esp,%ebp
 64b:	53                   	push   %ebx
 64c:	83 ec 04             	sub    $0x4,%esp
 64f:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 651:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 656:	77 05                	ja     65d <morecore+0x15>
    nu = 4096;
 658:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 65d:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 664:	83 ec 0c             	sub    $0xc,%esp
 667:	50                   	push   %eax
 668:	e8 30 fd ff ff       	call   39d <sbrk>
  if(p == (char*)-1)
 66d:	83 c4 10             	add    $0x10,%esp
 670:	83 f8 ff             	cmp    $0xffffffff,%eax
 673:	74 1c                	je     691 <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 675:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 678:	83 c0 08             	add    $0x8,%eax
 67b:	83 ec 0c             	sub    $0xc,%esp
 67e:	50                   	push   %eax
 67f:	e8 54 ff ff ff       	call   5d8 <free>
  return freep;
 684:	a1 00 0a 00 00       	mov    0xa00,%eax
 689:	83 c4 10             	add    $0x10,%esp
}
 68c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 68f:	c9                   	leave  
 690:	c3                   	ret    
    return 0;
 691:	b8 00 00 00 00       	mov    $0x0,%eax
 696:	eb f4                	jmp    68c <morecore+0x44>

00000698 <malloc>:

void*
malloc(uint nbytes)
{
 698:	55                   	push   %ebp
 699:	89 e5                	mov    %esp,%ebp
 69b:	53                   	push   %ebx
 69c:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 69f:	8b 45 08             	mov    0x8(%ebp),%eax
 6a2:	8d 58 07             	lea    0x7(%eax),%ebx
 6a5:	c1 eb 03             	shr    $0x3,%ebx
 6a8:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 6ab:	8b 0d 00 0a 00 00    	mov    0xa00,%ecx
 6b1:	85 c9                	test   %ecx,%ecx
 6b3:	74 04                	je     6b9 <malloc+0x21>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 6b5:	8b 01                	mov    (%ecx),%eax
 6b7:	eb 4d                	jmp    706 <malloc+0x6e>
    base.s.ptr = freep = prevp = &base;
 6b9:	c7 05 00 0a 00 00 04 	movl   $0xa04,0xa00
 6c0:	0a 00 00 
 6c3:	c7 05 04 0a 00 00 04 	movl   $0xa04,0xa04
 6ca:	0a 00 00 
    base.s.size = 0;
 6cd:	c7 05 08 0a 00 00 00 	movl   $0x0,0xa08
 6d4:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 6d7:	b9 04 0a 00 00       	mov    $0xa04,%ecx
 6dc:	eb d7                	jmp    6b5 <malloc+0x1d>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 6de:	39 da                	cmp    %ebx,%edx
 6e0:	74 1a                	je     6fc <malloc+0x64>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 6e2:	29 da                	sub    %ebx,%edx
 6e4:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 6e7:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 6ea:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 6ed:	89 0d 00 0a 00 00    	mov    %ecx,0xa00
      return (void*)(p + 1);
 6f3:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 6f6:	83 c4 04             	add    $0x4,%esp
 6f9:	5b                   	pop    %ebx
 6fa:	5d                   	pop    %ebp
 6fb:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 6fc:	8b 10                	mov    (%eax),%edx
 6fe:	89 11                	mov    %edx,(%ecx)
 700:	eb eb                	jmp    6ed <malloc+0x55>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 702:	89 c1                	mov    %eax,%ecx
 704:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 706:	8b 50 04             	mov    0x4(%eax),%edx
 709:	39 da                	cmp    %ebx,%edx
 70b:	73 d1                	jae    6de <malloc+0x46>
    if(p == freep)
 70d:	39 05 00 0a 00 00    	cmp    %eax,0xa00
 713:	75 ed                	jne    702 <malloc+0x6a>
      if((p = morecore(nunits)) == 0)
 715:	89 d8                	mov    %ebx,%eax
 717:	e8 2c ff ff ff       	call   648 <morecore>
 71c:	85 c0                	test   %eax,%eax
 71e:	75 e2                	jne    702 <malloc+0x6a>
        return 0;
 720:	b8 00 00 00 00       	mov    $0x0,%eax
 725:	eb cf                	jmp    6f6 <malloc+0x5e>
