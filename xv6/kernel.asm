
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 90 10 00       	mov    $0x109000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc c0 b5 10 80       	mov    $0x8010b5c0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 64 2a 10 80       	mov    $0x80102a64,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	57                   	push   %edi
80100038:	56                   	push   %esi
80100039:	53                   	push   %ebx
8010003a:	83 ec 18             	sub    $0x18,%esp
8010003d:	89 c6                	mov    %eax,%esi
8010003f:	89 d7                	mov    %edx,%edi
  struct buf *b;

  acquire(&bcache.lock);
80100041:	68 c0 b5 10 80       	push   $0x8010b5c0
80100046:	e8 b7 40 00 00       	call   80104102 <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 10 fd 10 80    	mov    0x8010fd10,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
8010005f:	74 30                	je     80100091 <bget+0x5d>
    if(b->dev == dev && b->blockno == blockno){
80100061:	39 73 04             	cmp    %esi,0x4(%ebx)
80100064:	75 f0                	jne    80100056 <bget+0x22>
80100066:	39 7b 08             	cmp    %edi,0x8(%ebx)
80100069:	75 eb                	jne    80100056 <bget+0x22>
      b->refcnt++;
8010006b:	8b 43 4c             	mov    0x4c(%ebx),%eax
8010006e:	83 c0 01             	add    $0x1,%eax
80100071:	89 43 4c             	mov    %eax,0x4c(%ebx)
      release(&bcache.lock);
80100074:	83 ec 0c             	sub    $0xc,%esp
80100077:	68 c0 b5 10 80       	push   $0x8010b5c0
8010007c:	e8 e6 40 00 00       	call   80104167 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 62 3e 00 00       	call   80103eee <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 0c fd 10 80    	mov    0x8010fd0c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
801000a2:	74 43                	je     801000e7 <bget+0xb3>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
801000a4:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801000a8:	75 ef                	jne    80100099 <bget+0x65>
801000aa:	f6 03 04             	testb  $0x4,(%ebx)
801000ad:	75 ea                	jne    80100099 <bget+0x65>
      b->dev = dev;
801000af:	89 73 04             	mov    %esi,0x4(%ebx)
      b->blockno = blockno;
801000b2:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = 0;
801000b5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
      b->refcnt = 1;
801000bb:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
      release(&bcache.lock);
801000c2:	83 ec 0c             	sub    $0xc,%esp
801000c5:	68 c0 b5 10 80       	push   $0x8010b5c0
801000ca:	e8 98 40 00 00       	call   80104167 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 14 3e 00 00       	call   80103eee <acquiresleep>
      return b;
801000da:	83 c4 10             	add    $0x10,%esp
    }
  }
  panic("bget: no buffers");
}
801000dd:	89 d8                	mov    %ebx,%eax
801000df:	8d 65 f4             	lea    -0xc(%ebp),%esp
801000e2:	5b                   	pop    %ebx
801000e3:	5e                   	pop    %esi
801000e4:	5f                   	pop    %edi
801000e5:	5d                   	pop    %ebp
801000e6:	c3                   	ret    
  panic("bget: no buffers");
801000e7:	83 ec 0c             	sub    $0xc,%esp
801000ea:	68 40 6a 10 80       	push   $0x80106a40
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 51 6a 10 80       	push   $0x80106a51
80100100:	68 c0 b5 10 80       	push   $0x8010b5c0
80100105:	e8 bc 3e 00 00       	call   80103fc6 <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 0c fd 10 80 bc 	movl   $0x8010fcbc,0x8010fd0c
80100111:	fc 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 10 fd 10 80 bc 	movl   $0x8010fcbc,0x8010fd10
8010011b:	fc 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb f4 b5 10 80       	mov    $0x8010b5f4,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 bc fc 10 80 	movl   $0x8010fcbc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 58 6a 10 80       	push   $0x80106a58
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 73 3d 00 00       	call   80103ebb <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 10 fd 10 80    	mov    %ebx,0x8010fd10
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
80100165:	72 c1                	jb     80100128 <binit+0x34>
}
80100167:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010016a:	c9                   	leave  
8010016b:	c3                   	ret    

8010016c <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
8010016c:	55                   	push   %ebp
8010016d:	89 e5                	mov    %esp,%ebp
8010016f:	53                   	push   %ebx
80100170:	83 ec 04             	sub    $0x4,%esp
  struct buf *b;

  b = bget(dev, blockno);
80100173:	8b 55 0c             	mov    0xc(%ebp),%edx
80100176:	8b 45 08             	mov    0x8(%ebp),%eax
80100179:	e8 b6 fe ff ff       	call   80100034 <bget>
8010017e:	89 c3                	mov    %eax,%ebx
  if((b->flags & B_VALID) == 0) {
80100180:	f6 00 02             	testb  $0x2,(%eax)
80100183:	74 07                	je     8010018c <bread+0x20>
    iderw(b);
  }
  return b;
}
80100185:	89 d8                	mov    %ebx,%eax
80100187:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010018a:	c9                   	leave  
8010018b:	c3                   	ret    
    iderw(b);
8010018c:	83 ec 0c             	sub    $0xc,%esp
8010018f:	50                   	push   %eax
80100190:	e8 77 1c 00 00       	call   80101e0c <iderw>
80100195:	83 c4 10             	add    $0x10,%esp
  return b;
80100198:	eb eb                	jmp    80100185 <bread+0x19>

8010019a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
8010019a:	55                   	push   %ebp
8010019b:	89 e5                	mov    %esp,%ebp
8010019d:	53                   	push   %ebx
8010019e:	83 ec 10             	sub    $0x10,%esp
801001a1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001a4:	8d 43 0c             	lea    0xc(%ebx),%eax
801001a7:	50                   	push   %eax
801001a8:	e8 cb 3d 00 00       	call   80103f78 <holdingsleep>
801001ad:	83 c4 10             	add    $0x10,%esp
801001b0:	85 c0                	test   %eax,%eax
801001b2:	74 14                	je     801001c8 <bwrite+0x2e>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001b4:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001b7:	83 ec 0c             	sub    $0xc,%esp
801001ba:	53                   	push   %ebx
801001bb:	e8 4c 1c 00 00       	call   80101e0c <iderw>
}
801001c0:	83 c4 10             	add    $0x10,%esp
801001c3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001c6:	c9                   	leave  
801001c7:	c3                   	ret    
    panic("bwrite");
801001c8:	83 ec 0c             	sub    $0xc,%esp
801001cb:	68 5f 6a 10 80       	push   $0x80106a5f
801001d0:	e8 73 01 00 00       	call   80100348 <panic>

801001d5 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
801001d5:	55                   	push   %ebp
801001d6:	89 e5                	mov    %esp,%ebp
801001d8:	56                   	push   %esi
801001d9:	53                   	push   %ebx
801001da:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001dd:	8d 73 0c             	lea    0xc(%ebx),%esi
801001e0:	83 ec 0c             	sub    $0xc,%esp
801001e3:	56                   	push   %esi
801001e4:	e8 8f 3d 00 00       	call   80103f78 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 44 3d 00 00       	call   80103f3d <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100200:	e8 fd 3e 00 00       	call   80104102 <acquire>
  b->refcnt--;
80100205:	8b 43 4c             	mov    0x4c(%ebx),%eax
80100208:	83 e8 01             	sub    $0x1,%eax
8010020b:	89 43 4c             	mov    %eax,0x4c(%ebx)
  if (b->refcnt == 0) {
8010020e:	83 c4 10             	add    $0x10,%esp
80100211:	85 c0                	test   %eax,%eax
80100213:	75 2f                	jne    80100244 <brelse+0x6f>
    // no one is waiting for it.
    b->next->prev = b->prev;
80100215:	8b 43 54             	mov    0x54(%ebx),%eax
80100218:	8b 53 50             	mov    0x50(%ebx),%edx
8010021b:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
8010021e:	8b 43 50             	mov    0x50(%ebx),%eax
80100221:	8b 53 54             	mov    0x54(%ebx),%edx
80100224:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
80100227:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 bc fc 10 80 	movl   $0x8010fcbc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 10 fd 10 80    	mov    %ebx,0x8010fd10
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 c0 b5 10 80       	push   $0x8010b5c0
8010024c:	e8 16 3f 00 00       	call   80104167 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 66 6a 10 80       	push   $0x80106a66
80100263:	e8 e0 00 00 00       	call   80100348 <panic>

80100268 <consoleread>:
  }
}

int
consoleread(struct inode *ip, char *dst, int n)
{
80100268:	55                   	push   %ebp
80100269:	89 e5                	mov    %esp,%ebp
8010026b:	57                   	push   %edi
8010026c:	56                   	push   %esi
8010026d:	53                   	push   %ebx
8010026e:	83 ec 28             	sub    $0x28,%esp
80100271:	8b 7d 08             	mov    0x8(%ebp),%edi
80100274:	8b 75 0c             	mov    0xc(%ebp),%esi
80100277:	8b 5d 10             	mov    0x10(%ebp),%ebx
  uint target;
  int c;

  iunlock(ip);
8010027a:	57                   	push   %edi
8010027b:	e8 c3 13 00 00       	call   80101643 <iunlock>
  target = n;
80100280:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100283:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
8010028a:	e8 73 3e 00 00       	call   80104102 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 a0 ff 10 80       	mov    0x8010ffa0,%eax
8010029f:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 85 2f 00 00       	call   80103231 <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 a5 10 80       	push   $0x8010a520
801002ba:	68 a0 ff 10 80       	push   $0x8010ffa0
801002bf:	e8 ea 32 00 00       	call   801035ae <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 91 3e 00 00       	call   80104167 <release>
        ilock(ip);
801002d6:	89 3c 24             	mov    %edi,(%esp)
801002d9:	e8 a3 12 00 00       	call   80101581 <ilock>
        return -1;
801002de:	83 c4 10             	add    $0x10,%esp
801002e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&cons.lock);
  ilock(ip);

  return target - n;
}
801002e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801002e9:	5b                   	pop    %ebx
801002ea:	5e                   	pop    %esi
801002eb:	5f                   	pop    %edi
801002ec:	5d                   	pop    %ebp
801002ed:	c3                   	ret    
    c = input.buf[input.r++ % INPUT_BUF];
801002ee:	8d 50 01             	lea    0x1(%eax),%edx
801002f1:	89 15 a0 ff 10 80    	mov    %edx,0x8010ffa0
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a 20 ff 10 80 	movzbl -0x7fef00e0(%edx),%ecx
80100303:	0f be d1             	movsbl %cl,%edx
    if(c == C('D')){  // EOF
80100306:	83 fa 04             	cmp    $0x4,%edx
80100309:	74 14                	je     8010031f <consoleread+0xb7>
    *dst++ = c;
8010030b:	8d 46 01             	lea    0x1(%esi),%eax
8010030e:	88 0e                	mov    %cl,(%esi)
    --n;
80100310:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
80100313:	83 fa 0a             	cmp    $0xa,%edx
80100316:	74 11                	je     80100329 <consoleread+0xc1>
    *dst++ = c;
80100318:	89 c6                	mov    %eax,%esi
8010031a:	e9 73 ff ff ff       	jmp    80100292 <consoleread+0x2a>
      if(n < target){
8010031f:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
80100322:	73 05                	jae    80100329 <consoleread+0xc1>
        input.r--;
80100324:	a3 a0 ff 10 80       	mov    %eax,0x8010ffa0
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 a5 10 80       	push   $0x8010a520
80100331:	e8 31 3e 00 00       	call   80104167 <release>
  ilock(ip);
80100336:	89 3c 24             	mov    %edi,(%esp)
80100339:	e8 43 12 00 00       	call   80101581 <ilock>
  return target - n;
8010033e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100341:	29 d8                	sub    %ebx,%eax
80100343:	83 c4 10             	add    $0x10,%esp
80100346:	eb 9e                	jmp    801002e6 <consoleread+0x7e>

80100348 <panic>:
{
80100348:	55                   	push   %ebp
80100349:	89 e5                	mov    %esp,%ebp
8010034b:	53                   	push   %ebx
8010034c:	83 ec 34             	sub    $0x34,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
8010034f:	fa                   	cli    
  cons.locking = 0;
80100350:	c7 05 54 a5 10 80 00 	movl   $0x0,0x8010a554
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 1f 20 00 00       	call   8010237e <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 6d 6a 10 80       	push   $0x80106a6d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 87 74 10 80 	movl   $0x80107487,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 4d 3c 00 00       	call   80103fe1 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 81 6a 10 80       	push   $0x80106a81
801003aa:	e8 5c 02 00 00       	call   8010060b <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 a5 10 80 01 	movl   $0x1,0x8010a558
801003c1:	00 00 00 
801003c4:	eb fe                	jmp    801003c4 <panic+0x7c>

801003c6 <cgaputc>:
{
801003c6:	55                   	push   %ebp
801003c7:	89 e5                	mov    %esp,%ebp
801003c9:	57                   	push   %edi
801003ca:	56                   	push   %esi
801003cb:	53                   	push   %ebx
801003cc:	83 ec 0c             	sub    $0xc,%esp
801003cf:	89 c6                	mov    %eax,%esi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003d1:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
801003d6:	b8 0e 00 00 00       	mov    $0xe,%eax
801003db:	89 ca                	mov    %ecx,%edx
801003dd:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003de:	bb d5 03 00 00       	mov    $0x3d5,%ebx
801003e3:	89 da                	mov    %ebx,%edx
801003e5:	ec                   	in     (%dx),%al
  pos = inb(CRTPORT+1) << 8;
801003e6:	0f b6 f8             	movzbl %al,%edi
801003e9:	c1 e7 08             	shl    $0x8,%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003ec:	b8 0f 00 00 00       	mov    $0xf,%eax
801003f1:	89 ca                	mov    %ecx,%edx
801003f3:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003f4:	89 da                	mov    %ebx,%edx
801003f6:	ec                   	in     (%dx),%al
  pos |= inb(CRTPORT+1);
801003f7:	0f b6 c8             	movzbl %al,%ecx
801003fa:	09 f9                	or     %edi,%ecx
  if(c == '\n')
801003fc:	83 fe 0a             	cmp    $0xa,%esi
801003ff:	74 6a                	je     8010046b <cgaputc+0xa5>
  else if(c == BACKSPACE){
80100401:	81 fe 00 01 00 00    	cmp    $0x100,%esi
80100407:	0f 84 81 00 00 00    	je     8010048e <cgaputc+0xc8>
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010040d:	89 f0                	mov    %esi,%eax
8010040f:	0f b6 f0             	movzbl %al,%esi
80100412:	8d 59 01             	lea    0x1(%ecx),%ebx
80100415:	66 81 ce 00 07       	or     $0x700,%si
8010041a:	66 89 b4 09 00 80 0b 	mov    %si,-0x7ff48000(%ecx,%ecx,1)
80100421:	80 
  if(pos < 0 || pos > 25*80)
80100422:	81 fb d0 07 00 00    	cmp    $0x7d0,%ebx
80100428:	77 71                	ja     8010049b <cgaputc+0xd5>
  if((pos/80) >= 24){  // Scroll up.
8010042a:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
80100430:	7f 76                	jg     801004a8 <cgaputc+0xe2>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100432:	be d4 03 00 00       	mov    $0x3d4,%esi
80100437:	b8 0e 00 00 00       	mov    $0xe,%eax
8010043c:	89 f2                	mov    %esi,%edx
8010043e:	ee                   	out    %al,(%dx)
  outb(CRTPORT+1, pos>>8);
8010043f:	89 d8                	mov    %ebx,%eax
80100441:	c1 f8 08             	sar    $0x8,%eax
80100444:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
80100449:	89 ca                	mov    %ecx,%edx
8010044b:	ee                   	out    %al,(%dx)
8010044c:	b8 0f 00 00 00       	mov    $0xf,%eax
80100451:	89 f2                	mov    %esi,%edx
80100453:	ee                   	out    %al,(%dx)
80100454:	89 d8                	mov    %ebx,%eax
80100456:	89 ca                	mov    %ecx,%edx
80100458:	ee                   	out    %al,(%dx)
  crt[pos] = ' ' | 0x0700;
80100459:	66 c7 84 1b 00 80 0b 	movw   $0x720,-0x7ff48000(%ebx,%ebx,1)
80100460:	80 20 07 
}
80100463:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100466:	5b                   	pop    %ebx
80100467:	5e                   	pop    %esi
80100468:	5f                   	pop    %edi
80100469:	5d                   	pop    %ebp
8010046a:	c3                   	ret    
    pos += 80 - pos%80;
8010046b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100470:	89 c8                	mov    %ecx,%eax
80100472:	f7 ea                	imul   %edx
80100474:	c1 fa 05             	sar    $0x5,%edx
80100477:	8d 14 92             	lea    (%edx,%edx,4),%edx
8010047a:	89 d0                	mov    %edx,%eax
8010047c:	c1 e0 04             	shl    $0x4,%eax
8010047f:	89 ca                	mov    %ecx,%edx
80100481:	29 c2                	sub    %eax,%edx
80100483:	bb 50 00 00 00       	mov    $0x50,%ebx
80100488:	29 d3                	sub    %edx,%ebx
8010048a:	01 cb                	add    %ecx,%ebx
8010048c:	eb 94                	jmp    80100422 <cgaputc+0x5c>
    if(pos > 0) --pos;
8010048e:	85 c9                	test   %ecx,%ecx
80100490:	7e 05                	jle    80100497 <cgaputc+0xd1>
80100492:	8d 59 ff             	lea    -0x1(%ecx),%ebx
80100495:	eb 8b                	jmp    80100422 <cgaputc+0x5c>
  pos |= inb(CRTPORT+1);
80100497:	89 cb                	mov    %ecx,%ebx
80100499:	eb 87                	jmp    80100422 <cgaputc+0x5c>
    panic("pos under/overflow");
8010049b:	83 ec 0c             	sub    $0xc,%esp
8010049e:	68 85 6a 10 80       	push   $0x80106a85
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 6a 3d 00 00       	call   80104229 <memmove>
    pos -= 80;
801004bf:	83 eb 50             	sub    $0x50,%ebx
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801004c2:	b8 80 07 00 00       	mov    $0x780,%eax
801004c7:	29 d8                	sub    %ebx,%eax
801004c9:	8d 94 1b 00 80 0b 80 	lea    -0x7ff48000(%ebx,%ebx,1),%edx
801004d0:	83 c4 0c             	add    $0xc,%esp
801004d3:	01 c0                	add    %eax,%eax
801004d5:	50                   	push   %eax
801004d6:	6a 00                	push   $0x0
801004d8:	52                   	push   %edx
801004d9:	e8 d0 3c 00 00       	call   801041ae <memset>
801004de:	83 c4 10             	add    $0x10,%esp
801004e1:	e9 4c ff ff ff       	jmp    80100432 <cgaputc+0x6c>

801004e6 <consputc>:
  if(panicked){
801004e6:	83 3d 58 a5 10 80 00 	cmpl   $0x0,0x8010a558
801004ed:	74 03                	je     801004f2 <consputc+0xc>
  asm volatile("cli");
801004ef:	fa                   	cli    
801004f0:	eb fe                	jmp    801004f0 <consputc+0xa>
{
801004f2:	55                   	push   %ebp
801004f3:	89 e5                	mov    %esp,%ebp
801004f5:	53                   	push   %ebx
801004f6:	83 ec 04             	sub    $0x4,%esp
801004f9:	89 c3                	mov    %eax,%ebx
  if(c == BACKSPACE){
801004fb:	3d 00 01 00 00       	cmp    $0x100,%eax
80100500:	74 18                	je     8010051a <consputc+0x34>
    uartputc(c);
80100502:	83 ec 0c             	sub    $0xc,%esp
80100505:	50                   	push   %eax
80100506:	e8 22 51 00 00       	call   8010562d <uartputc>
8010050b:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
8010050e:	89 d8                	mov    %ebx,%eax
80100510:	e8 b1 fe ff ff       	call   801003c6 <cgaputc>
}
80100515:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100518:	c9                   	leave  
80100519:	c3                   	ret    
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010051a:	83 ec 0c             	sub    $0xc,%esp
8010051d:	6a 08                	push   $0x8
8010051f:	e8 09 51 00 00       	call   8010562d <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 fd 50 00 00       	call   8010562d <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 f1 50 00 00       	call   8010562d <uartputc>
8010053c:	83 c4 10             	add    $0x10,%esp
8010053f:	eb cd                	jmp    8010050e <consputc+0x28>

80100541 <printint>:
{
80100541:	55                   	push   %ebp
80100542:	89 e5                	mov    %esp,%ebp
80100544:	57                   	push   %edi
80100545:	56                   	push   %esi
80100546:	53                   	push   %ebx
80100547:	83 ec 1c             	sub    $0x1c,%esp
8010054a:	89 d7                	mov    %edx,%edi
  if(sign && (sign = xx < 0))
8010054c:	85 c9                	test   %ecx,%ecx
8010054e:	74 09                	je     80100559 <printint+0x18>
80100550:	89 c1                	mov    %eax,%ecx
80100552:	c1 e9 1f             	shr    $0x1f,%ecx
80100555:	85 c0                	test   %eax,%eax
80100557:	78 09                	js     80100562 <printint+0x21>
    x = xx;
80100559:	89 c2                	mov    %eax,%edx
  i = 0;
8010055b:	be 00 00 00 00       	mov    $0x0,%esi
80100560:	eb 08                	jmp    8010056a <printint+0x29>
    x = -xx;
80100562:	f7 d8                	neg    %eax
80100564:	89 c2                	mov    %eax,%edx
80100566:	eb f3                	jmp    8010055b <printint+0x1a>
    buf[i++] = digits[x % base];
80100568:	89 de                	mov    %ebx,%esi
8010056a:	89 d0                	mov    %edx,%eax
8010056c:	ba 00 00 00 00       	mov    $0x0,%edx
80100571:	f7 f7                	div    %edi
80100573:	8d 5e 01             	lea    0x1(%esi),%ebx
80100576:	0f b6 92 b0 6a 10 80 	movzbl -0x7fef9550(%edx),%edx
8010057d:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
80100581:	89 c2                	mov    %eax,%edx
80100583:	85 c0                	test   %eax,%eax
80100585:	75 e1                	jne    80100568 <printint+0x27>
  if(sign)
80100587:	85 c9                	test   %ecx,%ecx
80100589:	74 14                	je     8010059f <printint+0x5e>
    buf[i++] = '-';
8010058b:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
80100590:	8d 5e 02             	lea    0x2(%esi),%ebx
80100593:	eb 0a                	jmp    8010059f <printint+0x5e>
    consputc(buf[i]);
80100595:	0f be 44 1d d8       	movsbl -0x28(%ebp,%ebx,1),%eax
8010059a:	e8 47 ff ff ff       	call   801004e6 <consputc>
  while(--i >= 0)
8010059f:	83 eb 01             	sub    $0x1,%ebx
801005a2:	79 f1                	jns    80100595 <printint+0x54>
}
801005a4:	83 c4 1c             	add    $0x1c,%esp
801005a7:	5b                   	pop    %ebx
801005a8:	5e                   	pop    %esi
801005a9:	5f                   	pop    %edi
801005aa:	5d                   	pop    %ebp
801005ab:	c3                   	ret    

801005ac <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
801005ac:	55                   	push   %ebp
801005ad:	89 e5                	mov    %esp,%ebp
801005af:	57                   	push   %edi
801005b0:	56                   	push   %esi
801005b1:	53                   	push   %ebx
801005b2:	83 ec 18             	sub    $0x18,%esp
801005b5:	8b 7d 0c             	mov    0xc(%ebp),%edi
801005b8:	8b 75 10             	mov    0x10(%ebp),%esi
  int i;

  iunlock(ip);
801005bb:	ff 75 08             	pushl  0x8(%ebp)
801005be:	e8 80 10 00 00       	call   80101643 <iunlock>
  acquire(&cons.lock);
801005c3:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
801005ca:	e8 33 3b 00 00       	call   80104102 <acquire>
  for(i = 0; i < n; i++)
801005cf:	83 c4 10             	add    $0x10,%esp
801005d2:	bb 00 00 00 00       	mov    $0x0,%ebx
801005d7:	eb 0c                	jmp    801005e5 <consolewrite+0x39>
    consputc(buf[i] & 0xff);
801005d9:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
801005dd:	e8 04 ff ff ff       	call   801004e6 <consputc>
  for(i = 0; i < n; i++)
801005e2:	83 c3 01             	add    $0x1,%ebx
801005e5:	39 f3                	cmp    %esi,%ebx
801005e7:	7c f0                	jl     801005d9 <consolewrite+0x2d>
  release(&cons.lock);
801005e9:	83 ec 0c             	sub    $0xc,%esp
801005ec:	68 20 a5 10 80       	push   $0x8010a520
801005f1:	e8 71 3b 00 00       	call   80104167 <release>
  ilock(ip);
801005f6:	83 c4 04             	add    $0x4,%esp
801005f9:	ff 75 08             	pushl  0x8(%ebp)
801005fc:	e8 80 0f 00 00       	call   80101581 <ilock>

  return n;
}
80100601:	89 f0                	mov    %esi,%eax
80100603:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100606:	5b                   	pop    %ebx
80100607:	5e                   	pop    %esi
80100608:	5f                   	pop    %edi
80100609:	5d                   	pop    %ebp
8010060a:	c3                   	ret    

8010060b <cprintf>:
{
8010060b:	55                   	push   %ebp
8010060c:	89 e5                	mov    %esp,%ebp
8010060e:	57                   	push   %edi
8010060f:	56                   	push   %esi
80100610:	53                   	push   %ebx
80100611:	83 ec 1c             	sub    $0x1c,%esp
  locking = cons.locking;
80100614:	a1 54 a5 10 80       	mov    0x8010a554,%eax
80100619:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  if(locking)
8010061c:	85 c0                	test   %eax,%eax
8010061e:	75 10                	jne    80100630 <cprintf+0x25>
  if (fmt == 0)
80100620:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80100624:	74 1c                	je     80100642 <cprintf+0x37>
  argp = (uint*)(void*)(&fmt + 1);
80100626:	8d 7d 0c             	lea    0xc(%ebp),%edi
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100629:	bb 00 00 00 00       	mov    $0x0,%ebx
8010062e:	eb 27                	jmp    80100657 <cprintf+0x4c>
    acquire(&cons.lock);
80100630:	83 ec 0c             	sub    $0xc,%esp
80100633:	68 20 a5 10 80       	push   $0x8010a520
80100638:	e8 c5 3a 00 00       	call   80104102 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 9f 6a 10 80       	push   $0x80106a9f
8010064a:	e8 f9 fc ff ff       	call   80100348 <panic>
      consputc(c);
8010064f:	e8 92 fe ff ff       	call   801004e6 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100654:	83 c3 01             	add    $0x1,%ebx
80100657:	8b 55 08             	mov    0x8(%ebp),%edx
8010065a:	0f b6 04 1a          	movzbl (%edx,%ebx,1),%eax
8010065e:	85 c0                	test   %eax,%eax
80100660:	0f 84 b8 00 00 00    	je     8010071e <cprintf+0x113>
    if(c != '%'){
80100666:	83 f8 25             	cmp    $0x25,%eax
80100669:	75 e4                	jne    8010064f <cprintf+0x44>
    c = fmt[++i] & 0xff;
8010066b:	83 c3 01             	add    $0x1,%ebx
8010066e:	0f b6 34 1a          	movzbl (%edx,%ebx,1),%esi
    if(c == 0)
80100672:	85 f6                	test   %esi,%esi
80100674:	0f 84 a4 00 00 00    	je     8010071e <cprintf+0x113>
    switch(c){
8010067a:	83 fe 70             	cmp    $0x70,%esi
8010067d:	74 48                	je     801006c7 <cprintf+0xbc>
8010067f:	83 fe 70             	cmp    $0x70,%esi
80100682:	7f 26                	jg     801006aa <cprintf+0x9f>
80100684:	83 fe 25             	cmp    $0x25,%esi
80100687:	0f 84 82 00 00 00    	je     8010070f <cprintf+0x104>
8010068d:	83 fe 64             	cmp    $0x64,%esi
80100690:	75 22                	jne    801006b4 <cprintf+0xa9>
      printint(*argp++, 10, 1);
80100692:	8d 77 04             	lea    0x4(%edi),%esi
80100695:	8b 07                	mov    (%edi),%eax
80100697:	b9 01 00 00 00       	mov    $0x1,%ecx
8010069c:	ba 0a 00 00 00       	mov    $0xa,%edx
801006a1:	e8 9b fe ff ff       	call   80100541 <printint>
801006a6:	89 f7                	mov    %esi,%edi
      break;
801006a8:	eb aa                	jmp    80100654 <cprintf+0x49>
    switch(c){
801006aa:	83 fe 73             	cmp    $0x73,%esi
801006ad:	74 33                	je     801006e2 <cprintf+0xd7>
801006af:	83 fe 78             	cmp    $0x78,%esi
801006b2:	74 13                	je     801006c7 <cprintf+0xbc>
      consputc('%');
801006b4:	b8 25 00 00 00       	mov    $0x25,%eax
801006b9:	e8 28 fe ff ff       	call   801004e6 <consputc>
      consputc(c);
801006be:	89 f0                	mov    %esi,%eax
801006c0:	e8 21 fe ff ff       	call   801004e6 <consputc>
      break;
801006c5:	eb 8d                	jmp    80100654 <cprintf+0x49>
      printint(*argp++, 16, 0);
801006c7:	8d 77 04             	lea    0x4(%edi),%esi
801006ca:	8b 07                	mov    (%edi),%eax
801006cc:	b9 00 00 00 00       	mov    $0x0,%ecx
801006d1:	ba 10 00 00 00       	mov    $0x10,%edx
801006d6:	e8 66 fe ff ff       	call   80100541 <printint>
801006db:	89 f7                	mov    %esi,%edi
      break;
801006dd:	e9 72 ff ff ff       	jmp    80100654 <cprintf+0x49>
      if((s = (char*)*argp++) == 0)
801006e2:	8d 47 04             	lea    0x4(%edi),%eax
801006e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
801006e8:	8b 37                	mov    (%edi),%esi
801006ea:	85 f6                	test   %esi,%esi
801006ec:	75 12                	jne    80100700 <cprintf+0xf5>
        s = "(null)";
801006ee:	be 98 6a 10 80       	mov    $0x80106a98,%esi
801006f3:	eb 0b                	jmp    80100700 <cprintf+0xf5>
        consputc(*s);
801006f5:	0f be c0             	movsbl %al,%eax
801006f8:	e8 e9 fd ff ff       	call   801004e6 <consputc>
      for(; *s; s++)
801006fd:	83 c6 01             	add    $0x1,%esi
80100700:	0f b6 06             	movzbl (%esi),%eax
80100703:	84 c0                	test   %al,%al
80100705:	75 ee                	jne    801006f5 <cprintf+0xea>
      if((s = (char*)*argp++) == 0)
80100707:	8b 7d e0             	mov    -0x20(%ebp),%edi
8010070a:	e9 45 ff ff ff       	jmp    80100654 <cprintf+0x49>
      consputc('%');
8010070f:	b8 25 00 00 00       	mov    $0x25,%eax
80100714:	e8 cd fd ff ff       	call   801004e6 <consputc>
      break;
80100719:	e9 36 ff ff ff       	jmp    80100654 <cprintf+0x49>
  if(locking)
8010071e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100722:	75 08                	jne    8010072c <cprintf+0x121>
}
80100724:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100727:	5b                   	pop    %ebx
80100728:	5e                   	pop    %esi
80100729:	5f                   	pop    %edi
8010072a:	5d                   	pop    %ebp
8010072b:	c3                   	ret    
    release(&cons.lock);
8010072c:	83 ec 0c             	sub    $0xc,%esp
8010072f:	68 20 a5 10 80       	push   $0x8010a520
80100734:	e8 2e 3a 00 00       	call   80104167 <release>
80100739:	83 c4 10             	add    $0x10,%esp
}
8010073c:	eb e6                	jmp    80100724 <cprintf+0x119>

8010073e <consoleintr>:
{
8010073e:	55                   	push   %ebp
8010073f:	89 e5                	mov    %esp,%ebp
80100741:	57                   	push   %edi
80100742:	56                   	push   %esi
80100743:	53                   	push   %ebx
80100744:	83 ec 18             	sub    $0x18,%esp
80100747:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&cons.lock);
8010074a:	68 20 a5 10 80       	push   $0x8010a520
8010074f:	e8 ae 39 00 00       	call   80104102 <acquire>
  while((c = getc()) >= 0){
80100754:	83 c4 10             	add    $0x10,%esp
  int c, doprocdump = 0;
80100757:	be 00 00 00 00       	mov    $0x0,%esi
  while((c = getc()) >= 0){
8010075c:	e9 c5 00 00 00       	jmp    80100826 <consoleintr+0xe8>
    switch(c){
80100761:	83 ff 08             	cmp    $0x8,%edi
80100764:	0f 84 e0 00 00 00    	je     8010084a <consoleintr+0x10c>
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010076a:	85 ff                	test   %edi,%edi
8010076c:	0f 84 b4 00 00 00    	je     80100826 <consoleintr+0xe8>
80100772:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 a0 ff 10 80    	sub    0x8010ffa0,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 a8 ff 10 80    	mov    %edx,0x8010ffa8
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 20 ff 10 80    	mov    %cl,-0x7fef00e0(%eax)
        consputc(c);
801007a5:	89 f8                	mov    %edi,%eax
801007a7:	e8 3a fd ff ff       	call   801004e6 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801007ac:	83 ff 0a             	cmp    $0xa,%edi
801007af:	0f 94 c2             	sete   %dl
801007b2:	83 ff 04             	cmp    $0x4,%edi
801007b5:	0f 94 c0             	sete   %al
801007b8:	08 c2                	or     %al,%dl
801007ba:	75 10                	jne    801007cc <consoleintr+0x8e>
801007bc:	a1 a0 ff 10 80       	mov    0x8010ffa0,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 a8 ff 10 80    	cmp    %eax,0x8010ffa8
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
801007d1:	a3 a4 ff 10 80       	mov    %eax,0x8010ffa4
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 a0 ff 10 80       	push   $0x8010ffa0
801007de:	e8 33 2f 00 00       	call   80103716 <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 a8 ff 10 80       	mov    %eax,0x8010ffa8
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
801007fc:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba 20 ff 10 80 0a 	cmpb   $0xa,-0x7fef00e0(%edx)
80100813:	75 d3                	jne    801007e8 <consoleintr+0xaa>
80100815:	eb 0f                	jmp    80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100817:	bf 0a 00 00 00       	mov    $0xa,%edi
8010081c:	e9 70 ff ff ff       	jmp    80100791 <consoleintr+0x53>
      doprocdump = 1;
80100821:	be 01 00 00 00       	mov    $0x1,%esi
  while((c = getc()) >= 0){
80100826:	ff d3                	call   *%ebx
80100828:	89 c7                	mov    %eax,%edi
8010082a:	85 c0                	test   %eax,%eax
8010082c:	78 3d                	js     8010086b <consoleintr+0x12d>
    switch(c){
8010082e:	83 ff 10             	cmp    $0x10,%edi
80100831:	74 ee                	je     80100821 <consoleintr+0xe3>
80100833:	83 ff 10             	cmp    $0x10,%edi
80100836:	0f 8e 25 ff ff ff    	jle    80100761 <consoleintr+0x23>
8010083c:	83 ff 15             	cmp    $0x15,%edi
8010083f:	74 b6                	je     801007f7 <consoleintr+0xb9>
80100841:	83 ff 7f             	cmp    $0x7f,%edi
80100844:	0f 85 20 ff ff ff    	jne    8010076a <consoleintr+0x2c>
      if(input.e != input.w){
8010084a:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
8010084f:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 a8 ff 10 80       	mov    %eax,0x8010ffa8
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 a5 10 80       	push   $0x8010a520
80100873:	e8 ef 38 00 00       	call   80104167 <release>
  if(doprocdump) {
80100878:	83 c4 10             	add    $0x10,%esp
8010087b:	85 f6                	test   %esi,%esi
8010087d:	75 08                	jne    80100887 <consoleintr+0x149>
}
8010087f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100882:	5b                   	pop    %ebx
80100883:	5e                   	pop    %esi
80100884:	5f                   	pop    %edi
80100885:	5d                   	pop    %ebp
80100886:	c3                   	ret    
    procdump();  // now call procdump() wo. cons.lock held
80100887:	e8 29 2f 00 00       	call   801037b5 <procdump>
}
8010088c:	eb f1                	jmp    8010087f <consoleintr+0x141>

8010088e <consoleinit>:

void
consoleinit(void)
{
8010088e:	55                   	push   %ebp
8010088f:	89 e5                	mov    %esp,%ebp
80100891:	83 ec 10             	sub    $0x10,%esp
  initlock(&cons.lock, "console");
80100894:	68 a8 6a 10 80       	push   $0x80106aa8
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 23 37 00 00       	call   80103fc6 <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 6c 09 11 80 ac 	movl   $0x801005ac,0x8011096c
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 68 09 11 80 68 	movl   $0x80100268,0x80110968
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 a5 10 80 01 	movl   $0x1,0x8010a554
801008be:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
801008c1:	83 c4 08             	add    $0x8,%esp
801008c4:	6a 00                	push   $0x0
801008c6:	6a 01                	push   $0x1
801008c8:	e8 b1 16 00 00       	call   80101f7e <ioapicenable>
}
801008cd:	83 c4 10             	add    $0x10,%esp
801008d0:	c9                   	leave  
801008d1:	c3                   	ret    

801008d2 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
801008d2:	55                   	push   %ebp
801008d3:	89 e5                	mov    %esp,%ebp
801008d5:	57                   	push   %edi
801008d6:	56                   	push   %esi
801008d7:	53                   	push   %ebx
801008d8:	81 ec 0c 01 00 00    	sub    $0x10c,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
801008de:	e8 4e 29 00 00       	call   80103231 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 c0 1e 00 00       	call   801027ae <begin_op>

  if((ip = namei(path)) == 0){
801008ee:	83 ec 0c             	sub    $0xc,%esp
801008f1:	ff 75 08             	pushl  0x8(%ebp)
801008f4:	e8 e8 12 00 00       	call   80101be1 <namei>
801008f9:	83 c4 10             	add    $0x10,%esp
801008fc:	85 c0                	test   %eax,%eax
801008fe:	74 4a                	je     8010094a <exec+0x78>
80100900:	89 c3                	mov    %eax,%ebx
    end_op();
    cprintf("exec: fail\n");
    return -1;
  }
  ilock(ip);
80100902:	83 ec 0c             	sub    $0xc,%esp
80100905:	50                   	push   %eax
80100906:	e8 76 0c 00 00       	call   80101581 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
8010090b:	6a 34                	push   $0x34
8010090d:	6a 00                	push   $0x0
8010090f:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100915:	50                   	push   %eax
80100916:	53                   	push   %ebx
80100917:	e8 57 0e 00 00       	call   80101773 <readi>
8010091c:	83 c4 20             	add    $0x20,%esp
8010091f:	83 f8 34             	cmp    $0x34,%eax
80100922:	74 42                	je     80100966 <exec+0x94>
  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
80100924:	85 db                	test   %ebx,%ebx
80100926:	0f 84 dd 02 00 00    	je     80100c09 <exec+0x337>
    iunlockput(ip);
8010092c:	83 ec 0c             	sub    $0xc,%esp
8010092f:	53                   	push   %ebx
80100930:	e8 f3 0d 00 00       	call   80101728 <iunlockput>
    end_op();
80100935:	e8 ee 1e 00 00       	call   80102828 <end_op>
8010093a:	83 c4 10             	add    $0x10,%esp
  }
  return -1;
8010093d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100942:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100945:	5b                   	pop    %ebx
80100946:	5e                   	pop    %esi
80100947:	5f                   	pop    %edi
80100948:	5d                   	pop    %ebp
80100949:	c3                   	ret    
    end_op();
8010094a:	e8 d9 1e 00 00       	call   80102828 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 c1 6a 10 80       	push   $0x80106ac1
80100957:	e8 af fc ff ff       	call   8010060b <cprintf>
    return -1;
8010095c:	83 c4 10             	add    $0x10,%esp
8010095f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100964:	eb dc                	jmp    80100942 <exec+0x70>
  if(elf.magic != ELF_MAGIC)
80100966:	81 bd 24 ff ff ff 7f 	cmpl   $0x464c457f,-0xdc(%ebp)
8010096d:	45 4c 46 
80100970:	75 b2                	jne    80100924 <exec+0x52>
  if((pgdir = setupkvm()) == 0)
80100972:	e8 76 5e 00 00       	call   801067ed <setupkvm>
80100977:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)
8010097d:	85 c0                	test   %eax,%eax
8010097f:	0f 84 06 01 00 00    	je     80100a8b <exec+0x1b9>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100985:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
  sz = 0;
8010098b:	bf 00 00 00 00       	mov    $0x0,%edi
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100990:	be 00 00 00 00       	mov    $0x0,%esi
80100995:	eb 0c                	jmp    801009a3 <exec+0xd1>
80100997:	83 c6 01             	add    $0x1,%esi
8010099a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
801009a0:	83 c0 20             	add    $0x20,%eax
801009a3:	0f b7 95 50 ff ff ff 	movzwl -0xb0(%ebp),%edx
801009aa:	39 f2                	cmp    %esi,%edx
801009ac:	0f 8e 98 00 00 00    	jle    80100a4a <exec+0x178>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801009b2:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
801009b8:	6a 20                	push   $0x20
801009ba:	50                   	push   %eax
801009bb:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
801009c1:	50                   	push   %eax
801009c2:	53                   	push   %ebx
801009c3:	e8 ab 0d 00 00       	call   80101773 <readi>
801009c8:	83 c4 10             	add    $0x10,%esp
801009cb:	83 f8 20             	cmp    $0x20,%eax
801009ce:	0f 85 b7 00 00 00    	jne    80100a8b <exec+0x1b9>
    if(ph.type != ELF_PROG_LOAD)
801009d4:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
801009db:	75 ba                	jne    80100997 <exec+0xc5>
    if(ph.memsz < ph.filesz)
801009dd:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
801009e3:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
801009e9:	0f 82 9c 00 00 00    	jb     80100a8b <exec+0x1b9>
    if(ph.vaddr + ph.memsz < ph.vaddr)
801009ef:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
801009f5:	0f 82 90 00 00 00    	jb     80100a8b <exec+0x1b9>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
801009fb:	83 ec 04             	sub    $0x4,%esp
801009fe:	50                   	push   %eax
801009ff:	57                   	push   %edi
80100a00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a06:	e8 88 5c 00 00       	call   80106693 <allocuvm>
80100a0b:	89 c7                	mov    %eax,%edi
80100a0d:	83 c4 10             	add    $0x10,%esp
80100a10:	85 c0                	test   %eax,%eax
80100a12:	74 77                	je     80100a8b <exec+0x1b9>
    if(ph.vaddr % PGSIZE != 0)
80100a14:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a1a:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a1f:	75 6a                	jne    80100a8b <exec+0x1b9>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a21:	83 ec 0c             	sub    $0xc,%esp
80100a24:	ff b5 14 ff ff ff    	pushl  -0xec(%ebp)
80100a2a:	ff b5 08 ff ff ff    	pushl  -0xf8(%ebp)
80100a30:	53                   	push   %ebx
80100a31:	50                   	push   %eax
80100a32:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a38:	e8 24 5b 00 00       	call   80106561 <loaduvm>
80100a3d:	83 c4 20             	add    $0x20,%esp
80100a40:	85 c0                	test   %eax,%eax
80100a42:	0f 89 4f ff ff ff    	jns    80100997 <exec+0xc5>
 bad:
80100a48:	eb 41                	jmp    80100a8b <exec+0x1b9>
  iunlockput(ip);
80100a4a:	83 ec 0c             	sub    $0xc,%esp
80100a4d:	53                   	push   %ebx
80100a4e:	e8 d5 0c 00 00       	call   80101728 <iunlockput>
  end_op();
80100a53:	e8 d0 1d 00 00       	call   80102828 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 1a 5c 00 00       	call   80106693 <allocuvm>
80100a79:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
80100a7f:	83 c4 10             	add    $0x10,%esp
80100a82:	85 c0                	test   %eax,%eax
80100a84:	75 24                	jne    80100aaa <exec+0x1d8>
  ip = 0;
80100a86:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100a8b:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100a91:	85 c0                	test   %eax,%eax
80100a93:	0f 84 8b fe ff ff    	je     80100924 <exec+0x52>
    freevm(pgdir);
80100a99:	83 ec 0c             	sub    $0xc,%esp
80100a9c:	50                   	push   %eax
80100a9d:	e8 db 5c 00 00       	call   8010677d <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 b1 5d 00 00       	call   80106872 <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100ac1:	83 c4 10             	add    $0x10,%esp
80100ac4:	bb 00 00 00 00       	mov    $0x0,%ebx
80100ac9:	8b 45 0c             	mov    0xc(%ebp),%eax
80100acc:	8d 34 98             	lea    (%eax,%ebx,4),%esi
80100acf:	8b 06                	mov    (%esi),%eax
80100ad1:	85 c0                	test   %eax,%eax
80100ad3:	74 4d                	je     80100b22 <exec+0x250>
    if(argc >= MAXARG)
80100ad5:	83 fb 1f             	cmp    $0x1f,%ebx
80100ad8:	0f 87 0d 01 00 00    	ja     80100beb <exec+0x319>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100ade:	83 ec 0c             	sub    $0xc,%esp
80100ae1:	50                   	push   %eax
80100ae2:	e8 69 38 00 00       	call   80104350 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 57 38 00 00       	call   80104350 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 b5 5e 00 00       	call   801069c0 <copyout>
80100b0b:	83 c4 20             	add    $0x20,%esp
80100b0e:	85 c0                	test   %eax,%eax
80100b10:	0f 88 df 00 00 00    	js     80100bf5 <exec+0x323>
    ustack[3+argc] = sp;
80100b16:	89 bc 9d 64 ff ff ff 	mov    %edi,-0x9c(%ebp,%ebx,4)
  for(argc = 0; argv[argc]; argc++) {
80100b1d:	83 c3 01             	add    $0x1,%ebx
80100b20:	eb a7                	jmp    80100ac9 <exec+0x1f7>
  ustack[3+argc] = 0;
80100b22:	c7 84 9d 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%ebx,4)
80100b29:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b2d:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b34:	ff ff ff 
  ustack[1] = argc;
80100b37:	89 9d 5c ff ff ff    	mov    %ebx,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b3d:	8d 04 9d 04 00 00 00 	lea    0x4(,%ebx,4),%eax
80100b44:	89 f9                	mov    %edi,%ecx
80100b46:	29 c1                	sub    %eax,%ecx
80100b48:	89 8d 60 ff ff ff    	mov    %ecx,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100b4e:	8d 04 9d 10 00 00 00 	lea    0x10(,%ebx,4),%eax
80100b55:	29 c7                	sub    %eax,%edi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100b57:	50                   	push   %eax
80100b58:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100b5e:	50                   	push   %eax
80100b5f:	57                   	push   %edi
80100b60:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b66:	e8 55 5e 00 00       	call   801069c0 <copyout>
80100b6b:	83 c4 10             	add    $0x10,%esp
80100b6e:	85 c0                	test   %eax,%eax
80100b70:	0f 88 89 00 00 00    	js     80100bff <exec+0x32d>
  for(last=s=path; *s; s++)
80100b76:	8b 55 08             	mov    0x8(%ebp),%edx
80100b79:	89 d0                	mov    %edx,%eax
80100b7b:	eb 03                	jmp    80100b80 <exec+0x2ae>
80100b7d:	83 c0 01             	add    $0x1,%eax
80100b80:	0f b6 08             	movzbl (%eax),%ecx
80100b83:	84 c9                	test   %cl,%cl
80100b85:	74 0a                	je     80100b91 <exec+0x2bf>
    if(*s == '/')
80100b87:	80 f9 2f             	cmp    $0x2f,%cl
80100b8a:	75 f1                	jne    80100b7d <exec+0x2ab>
      last = s+1;
80100b8c:	8d 50 01             	lea    0x1(%eax),%edx
80100b8f:	eb ec                	jmp    80100b7d <exec+0x2ab>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100b91:	8b b5 f4 fe ff ff    	mov    -0x10c(%ebp),%esi
80100b97:	89 f0                	mov    %esi,%eax
80100b99:	83 c0 6c             	add    $0x6c,%eax
80100b9c:	83 ec 04             	sub    $0x4,%esp
80100b9f:	6a 10                	push   $0x10
80100ba1:	52                   	push   %edx
80100ba2:	50                   	push   %eax
80100ba3:	e8 6d 37 00 00       	call   80104315 <safestrcpy>
  oldpgdir = curproc->pgdir;
80100ba8:	8b 5e 04             	mov    0x4(%esi),%ebx
  curproc->pgdir = pgdir;
80100bab:	8b 8d ec fe ff ff    	mov    -0x114(%ebp),%ecx
80100bb1:	89 4e 04             	mov    %ecx,0x4(%esi)
  curproc->sz = sz;
80100bb4:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100bba:	89 0e                	mov    %ecx,(%esi)
  curproc->tf->eip = elf.entry;  // main
80100bbc:	8b 46 18             	mov    0x18(%esi),%eax
80100bbf:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100bc5:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100bc8:	8b 46 18             	mov    0x18(%esi),%eax
80100bcb:	89 78 44             	mov    %edi,0x44(%eax)
  switchuvm(curproc);
80100bce:	89 34 24             	mov    %esi,(%esp)
80100bd1:	e8 0a 58 00 00       	call   801063e0 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 9f 5b 00 00       	call   8010677d <freevm>
  return 0;
80100bde:	83 c4 10             	add    $0x10,%esp
80100be1:	b8 00 00 00 00       	mov    $0x0,%eax
80100be6:	e9 57 fd ff ff       	jmp    80100942 <exec+0x70>
  ip = 0;
80100beb:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bf0:	e9 96 fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bf5:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bfa:	e9 8c fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bff:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c04:	e9 82 fe ff ff       	jmp    80100a8b <exec+0x1b9>
  return -1;
80100c09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c0e:	e9 2f fd ff ff       	jmp    80100942 <exec+0x70>

80100c13 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c13:	55                   	push   %ebp
80100c14:	89 e5                	mov    %esp,%ebp
80100c16:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c19:	68 cd 6a 10 80       	push   $0x80106acd
80100c1e:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c23:	e8 9e 33 00 00       	call   80103fc6 <initlock>
}
80100c28:	83 c4 10             	add    $0x10,%esp
80100c2b:	c9                   	leave  
80100c2c:	c3                   	ret    

80100c2d <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c2d:	55                   	push   %ebp
80100c2e:	89 e5                	mov    %esp,%ebp
80100c30:	53                   	push   %ebx
80100c31:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c34:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c39:	e8 c4 34 00 00       	call   80104102 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c3e:	83 c4 10             	add    $0x10,%esp
80100c41:	bb f4 ff 10 80       	mov    $0x8010fff4,%ebx
80100c46:	81 fb 54 09 11 80    	cmp    $0x80110954,%ebx
80100c4c:	73 29                	jae    80100c77 <filealloc+0x4a>
    if(f->ref == 0){
80100c4e:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100c52:	74 05                	je     80100c59 <filealloc+0x2c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c54:	83 c3 18             	add    $0x18,%ebx
80100c57:	eb ed                	jmp    80100c46 <filealloc+0x19>
      f->ref = 1;
80100c59:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100c60:	83 ec 0c             	sub    $0xc,%esp
80100c63:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c68:	e8 fa 34 00 00       	call   80104167 <release>
      return f;
80100c6d:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100c70:	89 d8                	mov    %ebx,%eax
80100c72:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100c75:	c9                   	leave  
80100c76:	c3                   	ret    
  release(&ftable.lock);
80100c77:	83 ec 0c             	sub    $0xc,%esp
80100c7a:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c7f:	e8 e3 34 00 00       	call   80104167 <release>
  return 0;
80100c84:	83 c4 10             	add    $0x10,%esp
80100c87:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c8c:	eb e2                	jmp    80100c70 <filealloc+0x43>

80100c8e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100c8e:	55                   	push   %ebp
80100c8f:	89 e5                	mov    %esp,%ebp
80100c91:	53                   	push   %ebx
80100c92:	83 ec 10             	sub    $0x10,%esp
80100c95:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100c98:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c9d:	e8 60 34 00 00       	call   80104102 <acquire>
  if(f->ref < 1)
80100ca2:	8b 43 04             	mov    0x4(%ebx),%eax
80100ca5:	83 c4 10             	add    $0x10,%esp
80100ca8:	85 c0                	test   %eax,%eax
80100caa:	7e 1a                	jle    80100cc6 <filedup+0x38>
    panic("filedup");
  f->ref++;
80100cac:	83 c0 01             	add    $0x1,%eax
80100caf:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100cb2:	83 ec 0c             	sub    $0xc,%esp
80100cb5:	68 c0 ff 10 80       	push   $0x8010ffc0
80100cba:	e8 a8 34 00 00       	call   80104167 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 d4 6a 10 80       	push   $0x80106ad4
80100cce:	e8 75 f6 ff ff       	call   80100348 <panic>

80100cd3 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100cd3:	55                   	push   %ebp
80100cd4:	89 e5                	mov    %esp,%ebp
80100cd6:	53                   	push   %ebx
80100cd7:	83 ec 30             	sub    $0x30,%esp
80100cda:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100cdd:	68 c0 ff 10 80       	push   $0x8010ffc0
80100ce2:	e8 1b 34 00 00       	call   80104102 <acquire>
  if(f->ref < 1)
80100ce7:	8b 43 04             	mov    0x4(%ebx),%eax
80100cea:	83 c4 10             	add    $0x10,%esp
80100ced:	85 c0                	test   %eax,%eax
80100cef:	7e 1f                	jle    80100d10 <fileclose+0x3d>
    panic("fileclose");
  if(--f->ref > 0){
80100cf1:	83 e8 01             	sub    $0x1,%eax
80100cf4:	89 43 04             	mov    %eax,0x4(%ebx)
80100cf7:	85 c0                	test   %eax,%eax
80100cf9:	7e 22                	jle    80100d1d <fileclose+0x4a>
    release(&ftable.lock);
80100cfb:	83 ec 0c             	sub    $0xc,%esp
80100cfe:	68 c0 ff 10 80       	push   $0x8010ffc0
80100d03:	e8 5f 34 00 00       	call   80104167 <release>
    return;
80100d08:	83 c4 10             	add    $0x10,%esp
  else if(ff.type == FD_INODE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
80100d0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d0e:	c9                   	leave  
80100d0f:	c3                   	ret    
    panic("fileclose");
80100d10:	83 ec 0c             	sub    $0xc,%esp
80100d13:	68 dc 6a 10 80       	push   $0x80106adc
80100d18:	e8 2b f6 ff ff       	call   80100348 <panic>
  ff = *f;
80100d1d:	8b 03                	mov    (%ebx),%eax
80100d1f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d22:	8b 43 08             	mov    0x8(%ebx),%eax
80100d25:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d28:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d2b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d2e:	8b 43 10             	mov    0x10(%ebx),%eax
80100d31:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d34:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d3b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d41:	83 ec 0c             	sub    $0xc,%esp
80100d44:	68 c0 ff 10 80       	push   $0x8010ffc0
80100d49:	e8 19 34 00 00       	call   80104167 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 4b 1a 00 00       	call   801027ae <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 b5 1a 00 00       	call   80102828 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 9a 20 00 00       	call   80102e22 <pipeclose>
80100d88:	83 c4 10             	add    $0x10,%esp
80100d8b:	e9 7b ff ff ff       	jmp    80100d0b <fileclose+0x38>

80100d90 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100d90:	55                   	push   %ebp
80100d91:	89 e5                	mov    %esp,%ebp
80100d93:	53                   	push   %ebx
80100d94:	83 ec 04             	sub    $0x4,%esp
80100d97:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100d9a:	83 3b 02             	cmpl   $0x2,(%ebx)
80100d9d:	75 31                	jne    80100dd0 <filestat+0x40>
    ilock(f->ip);
80100d9f:	83 ec 0c             	sub    $0xc,%esp
80100da2:	ff 73 10             	pushl  0x10(%ebx)
80100da5:	e8 d7 07 00 00       	call   80101581 <ilock>
    stati(f->ip, st);
80100daa:	83 c4 08             	add    $0x8,%esp
80100dad:	ff 75 0c             	pushl  0xc(%ebp)
80100db0:	ff 73 10             	pushl  0x10(%ebx)
80100db3:	e8 90 09 00 00       	call   80101748 <stati>
    iunlock(f->ip);
80100db8:	83 c4 04             	add    $0x4,%esp
80100dbb:	ff 73 10             	pushl  0x10(%ebx)
80100dbe:	e8 80 08 00 00       	call   80101643 <iunlock>
    return 0;
80100dc3:	83 c4 10             	add    $0x10,%esp
80100dc6:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100dcb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100dce:	c9                   	leave  
80100dcf:	c3                   	ret    
  return -1;
80100dd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100dd5:	eb f4                	jmp    80100dcb <filestat+0x3b>

80100dd7 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100dd7:	55                   	push   %ebp
80100dd8:	89 e5                	mov    %esp,%ebp
80100dda:	56                   	push   %esi
80100ddb:	53                   	push   %ebx
80100ddc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100ddf:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100de3:	74 70                	je     80100e55 <fileread+0x7e>
    return -1;
  if(f->type == FD_PIPE)
80100de5:	8b 03                	mov    (%ebx),%eax
80100de7:	83 f8 01             	cmp    $0x1,%eax
80100dea:	74 44                	je     80100e30 <fileread+0x59>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100dec:	83 f8 02             	cmp    $0x2,%eax
80100def:	75 57                	jne    80100e48 <fileread+0x71>
    ilock(f->ip);
80100df1:	83 ec 0c             	sub    $0xc,%esp
80100df4:	ff 73 10             	pushl  0x10(%ebx)
80100df7:	e8 85 07 00 00       	call   80101581 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100dfc:	ff 75 10             	pushl  0x10(%ebp)
80100dff:	ff 73 14             	pushl  0x14(%ebx)
80100e02:	ff 75 0c             	pushl  0xc(%ebp)
80100e05:	ff 73 10             	pushl  0x10(%ebx)
80100e08:	e8 66 09 00 00       	call   80101773 <readi>
80100e0d:	89 c6                	mov    %eax,%esi
80100e0f:	83 c4 20             	add    $0x20,%esp
80100e12:	85 c0                	test   %eax,%eax
80100e14:	7e 03                	jle    80100e19 <fileread+0x42>
      f->off += r;
80100e16:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e19:	83 ec 0c             	sub    $0xc,%esp
80100e1c:	ff 73 10             	pushl  0x10(%ebx)
80100e1f:	e8 1f 08 00 00       	call   80101643 <iunlock>
    return r;
80100e24:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e27:	89 f0                	mov    %esi,%eax
80100e29:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e2c:	5b                   	pop    %ebx
80100e2d:	5e                   	pop    %esi
80100e2e:	5d                   	pop    %ebp
80100e2f:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e30:	83 ec 04             	sub    $0x4,%esp
80100e33:	ff 75 10             	pushl  0x10(%ebp)
80100e36:	ff 75 0c             	pushl  0xc(%ebp)
80100e39:	ff 73 0c             	pushl  0xc(%ebx)
80100e3c:	e8 39 21 00 00       	call   80102f7a <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 e6 6a 10 80       	push   $0x80106ae6
80100e50:	e8 f3 f4 ff ff       	call   80100348 <panic>
    return -1;
80100e55:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100e5a:	eb cb                	jmp    80100e27 <fileread+0x50>

80100e5c <filewrite>:

// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100e5c:	55                   	push   %ebp
80100e5d:	89 e5                	mov    %esp,%ebp
80100e5f:	57                   	push   %edi
80100e60:	56                   	push   %esi
80100e61:	53                   	push   %ebx
80100e62:	83 ec 1c             	sub    $0x1c,%esp
80100e65:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->writable == 0)
80100e68:	80 7b 09 00          	cmpb   $0x0,0x9(%ebx)
80100e6c:	0f 84 c5 00 00 00    	je     80100f37 <filewrite+0xdb>
    return -1;
  if(f->type == FD_PIPE)
80100e72:	8b 03                	mov    (%ebx),%eax
80100e74:	83 f8 01             	cmp    $0x1,%eax
80100e77:	74 10                	je     80100e89 <filewrite+0x2d>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e79:	83 f8 02             	cmp    $0x2,%eax
80100e7c:	0f 85 a8 00 00 00    	jne    80100f2a <filewrite+0xce>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100e82:	bf 00 00 00 00       	mov    $0x0,%edi
80100e87:	eb 67                	jmp    80100ef0 <filewrite+0x94>
    return pipewrite(f->pipe, addr, n);
80100e89:	83 ec 04             	sub    $0x4,%esp
80100e8c:	ff 75 10             	pushl  0x10(%ebp)
80100e8f:	ff 75 0c             	pushl  0xc(%ebp)
80100e92:	ff 73 0c             	pushl  0xc(%ebx)
80100e95:	e8 14 20 00 00       	call   80102eae <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 07 19 00 00       	call   801027ae <begin_op>
      ilock(f->ip);
80100ea7:	83 ec 0c             	sub    $0xc,%esp
80100eaa:	ff 73 10             	pushl  0x10(%ebx)
80100ead:	e8 cf 06 00 00       	call   80101581 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100eb2:	89 f8                	mov    %edi,%eax
80100eb4:	03 45 0c             	add    0xc(%ebp),%eax
80100eb7:	ff 75 e4             	pushl  -0x1c(%ebp)
80100eba:	ff 73 14             	pushl  0x14(%ebx)
80100ebd:	50                   	push   %eax
80100ebe:	ff 73 10             	pushl  0x10(%ebx)
80100ec1:	e8 aa 09 00 00       	call   80101870 <writei>
80100ec6:	89 c6                	mov    %eax,%esi
80100ec8:	83 c4 20             	add    $0x20,%esp
80100ecb:	85 c0                	test   %eax,%eax
80100ecd:	7e 03                	jle    80100ed2 <filewrite+0x76>
        f->off += r;
80100ecf:	01 43 14             	add    %eax,0x14(%ebx)
      iunlock(f->ip);
80100ed2:	83 ec 0c             	sub    $0xc,%esp
80100ed5:	ff 73 10             	pushl  0x10(%ebx)
80100ed8:	e8 66 07 00 00       	call   80101643 <iunlock>
      end_op();
80100edd:	e8 46 19 00 00       	call   80102828 <end_op>

      if(r < 0)
80100ee2:	83 c4 10             	add    $0x10,%esp
80100ee5:	85 f6                	test   %esi,%esi
80100ee7:	78 31                	js     80100f1a <filewrite+0xbe>
        break;
      if(r != n1)
80100ee9:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
80100eec:	75 1f                	jne    80100f0d <filewrite+0xb1>
        panic("short filewrite");
      i += r;
80100eee:	01 f7                	add    %esi,%edi
    while(i < n){
80100ef0:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100ef3:	7d 25                	jge    80100f1a <filewrite+0xbe>
      int n1 = n - i;
80100ef5:	8b 45 10             	mov    0x10(%ebp),%eax
80100ef8:	29 f8                	sub    %edi,%eax
80100efa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100efd:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f02:	7e 9e                	jle    80100ea2 <filewrite+0x46>
        n1 = max;
80100f04:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f0b:	eb 95                	jmp    80100ea2 <filewrite+0x46>
        panic("short filewrite");
80100f0d:	83 ec 0c             	sub    $0xc,%esp
80100f10:	68 ef 6a 10 80       	push   $0x80106aef
80100f15:	e8 2e f4 ff ff       	call   80100348 <panic>
    }
    return i == n ? n : -1;
80100f1a:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f1d:	75 1f                	jne    80100f3e <filewrite+0xe2>
80100f1f:	8b 45 10             	mov    0x10(%ebp),%eax
  }
  panic("filewrite");
}
80100f22:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f25:	5b                   	pop    %ebx
80100f26:	5e                   	pop    %esi
80100f27:	5f                   	pop    %edi
80100f28:	5d                   	pop    %ebp
80100f29:	c3                   	ret    
  panic("filewrite");
80100f2a:	83 ec 0c             	sub    $0xc,%esp
80100f2d:	68 f5 6a 10 80       	push   $0x80106af5
80100f32:	e8 11 f4 ff ff       	call   80100348 <panic>
    return -1;
80100f37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f3c:	eb e4                	jmp    80100f22 <filewrite+0xc6>
    return i == n ? n : -1;
80100f3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f43:	eb dd                	jmp    80100f22 <filewrite+0xc6>

80100f45 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100f45:	55                   	push   %ebp
80100f46:	89 e5                	mov    %esp,%ebp
80100f48:	57                   	push   %edi
80100f49:	56                   	push   %esi
80100f4a:	53                   	push   %ebx
80100f4b:	83 ec 0c             	sub    $0xc,%esp
80100f4e:	89 d7                	mov    %edx,%edi
  char *s;
  int len;

  while(*path == '/')
80100f50:	eb 03                	jmp    80100f55 <skipelem+0x10>
    path++;
80100f52:	83 c0 01             	add    $0x1,%eax
  while(*path == '/')
80100f55:	0f b6 10             	movzbl (%eax),%edx
80100f58:	80 fa 2f             	cmp    $0x2f,%dl
80100f5b:	74 f5                	je     80100f52 <skipelem+0xd>
  if(*path == 0)
80100f5d:	84 d2                	test   %dl,%dl
80100f5f:	74 59                	je     80100fba <skipelem+0x75>
80100f61:	89 c3                	mov    %eax,%ebx
80100f63:	eb 03                	jmp    80100f68 <skipelem+0x23>
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
    path++;
80100f65:	83 c3 01             	add    $0x1,%ebx
  while(*path != '/' && *path != 0)
80100f68:	0f b6 13             	movzbl (%ebx),%edx
80100f6b:	80 fa 2f             	cmp    $0x2f,%dl
80100f6e:	0f 95 c1             	setne  %cl
80100f71:	84 d2                	test   %dl,%dl
80100f73:	0f 95 c2             	setne  %dl
80100f76:	84 d1                	test   %dl,%cl
80100f78:	75 eb                	jne    80100f65 <skipelem+0x20>
  len = path - s;
80100f7a:	89 de                	mov    %ebx,%esi
80100f7c:	29 c6                	sub    %eax,%esi
  if(len >= DIRSIZ)
80100f7e:	83 fe 0d             	cmp    $0xd,%esi
80100f81:	7e 11                	jle    80100f94 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100f83:	83 ec 04             	sub    $0x4,%esp
80100f86:	6a 0e                	push   $0xe
80100f88:	50                   	push   %eax
80100f89:	57                   	push   %edi
80100f8a:	e8 9a 32 00 00       	call   80104229 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 8a 32 00 00       	call   80104229 <memmove>
    name[len] = 0;
80100f9f:	c6 04 37 00          	movb   $0x0,(%edi,%esi,1)
80100fa3:	83 c4 10             	add    $0x10,%esp
80100fa6:	eb 03                	jmp    80100fab <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80100fa8:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80100fab:	80 3b 2f             	cmpb   $0x2f,(%ebx)
80100fae:	74 f8                	je     80100fa8 <skipelem+0x63>
  return path;
}
80100fb0:	89 d8                	mov    %ebx,%eax
80100fb2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fb5:	5b                   	pop    %ebx
80100fb6:	5e                   	pop    %esi
80100fb7:	5f                   	pop    %edi
80100fb8:	5d                   	pop    %ebp
80100fb9:	c3                   	ret    
    return 0;
80100fba:	bb 00 00 00 00       	mov    $0x0,%ebx
80100fbf:	eb ef                	jmp    80100fb0 <skipelem+0x6b>

80100fc1 <bzero>:
{
80100fc1:	55                   	push   %ebp
80100fc2:	89 e5                	mov    %esp,%ebp
80100fc4:	53                   	push   %ebx
80100fc5:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80100fc8:	52                   	push   %edx
80100fc9:	50                   	push   %eax
80100fca:	e8 9d f1 ff ff       	call   8010016c <bread>
80100fcf:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
80100fd1:	8d 40 5c             	lea    0x5c(%eax),%eax
80100fd4:	83 c4 0c             	add    $0xc,%esp
80100fd7:	68 00 02 00 00       	push   $0x200
80100fdc:	6a 00                	push   $0x0
80100fde:	50                   	push   %eax
80100fdf:	e8 ca 31 00 00       	call   801041ae <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 eb 18 00 00       	call   801028d7 <log_write>
  brelse(bp);
80100fec:	89 1c 24             	mov    %ebx,(%esp)
80100fef:	e8 e1 f1 ff ff       	call   801001d5 <brelse>
}
80100ff4:	83 c4 10             	add    $0x10,%esp
80100ff7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ffa:	c9                   	leave  
80100ffb:	c3                   	ret    

80100ffc <balloc>:
{
80100ffc:	55                   	push   %ebp
80100ffd:	89 e5                	mov    %esp,%ebp
80100fff:	57                   	push   %edi
80101000:	56                   	push   %esi
80101001:	53                   	push   %ebx
80101002:	83 ec 1c             	sub    $0x1c,%esp
80101005:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101008:	be 00 00 00 00       	mov    $0x0,%esi
8010100d:	eb 14                	jmp    80101023 <balloc+0x27>
    brelse(bp);
8010100f:	83 ec 0c             	sub    $0xc,%esp
80101012:	ff 75 e4             	pushl  -0x1c(%ebp)
80101015:	e8 bb f1 ff ff       	call   801001d5 <brelse>
  for(b = 0; b < sb.size; b += BPB){
8010101a:	81 c6 00 10 00 00    	add    $0x1000,%esi
80101020:	83 c4 10             	add    $0x10,%esp
80101023:	39 35 c0 09 11 80    	cmp    %esi,0x801109c0
80101029:	76 75                	jbe    801010a0 <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
8010102b:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
80101031:	85 f6                	test   %esi,%esi
80101033:	0f 49 c6             	cmovns %esi,%eax
80101036:	c1 f8 0c             	sar    $0xc,%eax
80101039:	03 05 d8 09 11 80    	add    0x801109d8,%eax
8010103f:	83 ec 08             	sub    $0x8,%esp
80101042:	50                   	push   %eax
80101043:	ff 75 d8             	pushl  -0x28(%ebp)
80101046:	e8 21 f1 ff ff       	call   8010016c <bread>
8010104b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010104e:	83 c4 10             	add    $0x10,%esp
80101051:	b8 00 00 00 00       	mov    $0x0,%eax
80101056:	3d ff 0f 00 00       	cmp    $0xfff,%eax
8010105b:	7f b2                	jg     8010100f <balloc+0x13>
8010105d:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
80101060:	89 5d e0             	mov    %ebx,-0x20(%ebp)
80101063:	3b 1d c0 09 11 80    	cmp    0x801109c0,%ebx
80101069:	73 a4                	jae    8010100f <balloc+0x13>
      m = 1 << (bi % 8);
8010106b:	99                   	cltd   
8010106c:	c1 ea 1d             	shr    $0x1d,%edx
8010106f:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80101072:	83 e1 07             	and    $0x7,%ecx
80101075:	29 d1                	sub    %edx,%ecx
80101077:	ba 01 00 00 00       	mov    $0x1,%edx
8010107c:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010107e:	8d 48 07             	lea    0x7(%eax),%ecx
80101081:	85 c0                	test   %eax,%eax
80101083:	0f 49 c8             	cmovns %eax,%ecx
80101086:	c1 f9 03             	sar    $0x3,%ecx
80101089:	89 4d dc             	mov    %ecx,-0x24(%ebp)
8010108c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010108f:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
80101094:	0f b6 f9             	movzbl %cl,%edi
80101097:	85 d7                	test   %edx,%edi
80101099:	74 12                	je     801010ad <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010109b:	83 c0 01             	add    $0x1,%eax
8010109e:	eb b6                	jmp    80101056 <balloc+0x5a>
  panic("balloc: out of blocks");
801010a0:	83 ec 0c             	sub    $0xc,%esp
801010a3:	68 ff 6a 10 80       	push   $0x80106aff
801010a8:	e8 9b f2 ff ff       	call   80100348 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
801010ad:	09 ca                	or     %ecx,%edx
801010af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801010b2:	8b 75 dc             	mov    -0x24(%ebp),%esi
801010b5:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
801010b9:	83 ec 0c             	sub    $0xc,%esp
801010bc:	89 c6                	mov    %eax,%esi
801010be:	50                   	push   %eax
801010bf:	e8 13 18 00 00       	call   801028d7 <log_write>
        brelse(bp);
801010c4:	89 34 24             	mov    %esi,(%esp)
801010c7:	e8 09 f1 ff ff       	call   801001d5 <brelse>
        bzero(dev, b + bi);
801010cc:	89 da                	mov    %ebx,%edx
801010ce:	8b 45 d8             	mov    -0x28(%ebp),%eax
801010d1:	e8 eb fe ff ff       	call   80100fc1 <bzero>
}
801010d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010d9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801010dc:	5b                   	pop    %ebx
801010dd:	5e                   	pop    %esi
801010de:	5f                   	pop    %edi
801010df:	5d                   	pop    %ebp
801010e0:	c3                   	ret    

801010e1 <bmap>:
{
801010e1:	55                   	push   %ebp
801010e2:	89 e5                	mov    %esp,%ebp
801010e4:	57                   	push   %edi
801010e5:	56                   	push   %esi
801010e6:	53                   	push   %ebx
801010e7:	83 ec 1c             	sub    $0x1c,%esp
801010ea:	89 c6                	mov    %eax,%esi
801010ec:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
801010ee:	83 fa 0b             	cmp    $0xb,%edx
801010f1:	77 17                	ja     8010110a <bmap+0x29>
    if((addr = ip->addrs[bn]) == 0)
801010f3:	8b 5c 90 5c          	mov    0x5c(%eax,%edx,4),%ebx
801010f7:	85 db                	test   %ebx,%ebx
801010f9:	75 4a                	jne    80101145 <bmap+0x64>
      ip->addrs[bn] = addr = balloc(ip->dev);
801010fb:	8b 00                	mov    (%eax),%eax
801010fd:	e8 fa fe ff ff       	call   80100ffc <balloc>
80101102:	89 c3                	mov    %eax,%ebx
80101104:	89 44 be 5c          	mov    %eax,0x5c(%esi,%edi,4)
80101108:	eb 3b                	jmp    80101145 <bmap+0x64>
  bn -= NDIRECT;
8010110a:	8d 5a f4             	lea    -0xc(%edx),%ebx
  if(bn < NINDIRECT){
8010110d:	83 fb 7f             	cmp    $0x7f,%ebx
80101110:	77 68                	ja     8010117a <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
80101112:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101118:	85 c0                	test   %eax,%eax
8010111a:	74 33                	je     8010114f <bmap+0x6e>
    bp = bread(ip->dev, addr);
8010111c:	83 ec 08             	sub    $0x8,%esp
8010111f:	50                   	push   %eax
80101120:	ff 36                	pushl  (%esi)
80101122:	e8 45 f0 ff ff       	call   8010016c <bread>
80101127:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101129:	8d 44 98 5c          	lea    0x5c(%eax,%ebx,4),%eax
8010112d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101130:	8b 18                	mov    (%eax),%ebx
80101132:	83 c4 10             	add    $0x10,%esp
80101135:	85 db                	test   %ebx,%ebx
80101137:	74 25                	je     8010115e <bmap+0x7d>
    brelse(bp);
80101139:	83 ec 0c             	sub    $0xc,%esp
8010113c:	57                   	push   %edi
8010113d:	e8 93 f0 ff ff       	call   801001d5 <brelse>
    return addr;
80101142:	83 c4 10             	add    $0x10,%esp
}
80101145:	89 d8                	mov    %ebx,%eax
80101147:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010114a:	5b                   	pop    %ebx
8010114b:	5e                   	pop    %esi
8010114c:	5f                   	pop    %edi
8010114d:	5d                   	pop    %ebp
8010114e:	c3                   	ret    
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
8010114f:	8b 06                	mov    (%esi),%eax
80101151:	e8 a6 fe ff ff       	call   80100ffc <balloc>
80101156:	89 86 8c 00 00 00    	mov    %eax,0x8c(%esi)
8010115c:	eb be                	jmp    8010111c <bmap+0x3b>
      a[bn] = addr = balloc(ip->dev);
8010115e:	8b 06                	mov    (%esi),%eax
80101160:	e8 97 fe ff ff       	call   80100ffc <balloc>
80101165:	89 c3                	mov    %eax,%ebx
80101167:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010116a:	89 18                	mov    %ebx,(%eax)
      log_write(bp);
8010116c:	83 ec 0c             	sub    $0xc,%esp
8010116f:	57                   	push   %edi
80101170:	e8 62 17 00 00       	call   801028d7 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 15 6b 10 80       	push   $0x80106b15
80101182:	e8 c1 f1 ff ff       	call   80100348 <panic>

80101187 <iget>:
{
80101187:	55                   	push   %ebp
80101188:	89 e5                	mov    %esp,%ebp
8010118a:	57                   	push   %edi
8010118b:	56                   	push   %esi
8010118c:	53                   	push   %ebx
8010118d:	83 ec 28             	sub    $0x28,%esp
80101190:	89 c7                	mov    %eax,%edi
80101192:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
80101195:	68 e0 09 11 80       	push   $0x801109e0
8010119a:	e8 63 2f 00 00       	call   80104102 <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010119f:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011a2:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011a7:	bb 14 0a 11 80       	mov    $0x80110a14,%ebx
801011ac:	eb 0a                	jmp    801011b8 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ae:	85 f6                	test   %esi,%esi
801011b0:	74 3b                	je     801011ed <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b2:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011b8:	81 fb 34 26 11 80    	cmp    $0x80112634,%ebx
801011be:	73 35                	jae    801011f5 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801011c0:	8b 43 08             	mov    0x8(%ebx),%eax
801011c3:	85 c0                	test   %eax,%eax
801011c5:	7e e7                	jle    801011ae <iget+0x27>
801011c7:	39 3b                	cmp    %edi,(%ebx)
801011c9:	75 e3                	jne    801011ae <iget+0x27>
801011cb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801011ce:	39 4b 04             	cmp    %ecx,0x4(%ebx)
801011d1:	75 db                	jne    801011ae <iget+0x27>
      ip->ref++;
801011d3:	83 c0 01             	add    $0x1,%eax
801011d6:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
801011d9:	83 ec 0c             	sub    $0xc,%esp
801011dc:	68 e0 09 11 80       	push   $0x801109e0
801011e1:	e8 81 2f 00 00       	call   80104167 <release>
      return ip;
801011e6:	83 c4 10             	add    $0x10,%esp
801011e9:	89 de                	mov    %ebx,%esi
801011eb:	eb 32                	jmp    8010121f <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ed:	85 c0                	test   %eax,%eax
801011ef:	75 c1                	jne    801011b2 <iget+0x2b>
      empty = ip;
801011f1:	89 de                	mov    %ebx,%esi
801011f3:	eb bd                	jmp    801011b2 <iget+0x2b>
  if(empty == 0)
801011f5:	85 f6                	test   %esi,%esi
801011f7:	74 30                	je     80101229 <iget+0xa2>
  ip->dev = dev;
801011f9:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
801011fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011fe:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
80101201:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101208:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010120f:	83 ec 0c             	sub    $0xc,%esp
80101212:	68 e0 09 11 80       	push   $0x801109e0
80101217:	e8 4b 2f 00 00       	call   80104167 <release>
  return ip;
8010121c:	83 c4 10             	add    $0x10,%esp
}
8010121f:	89 f0                	mov    %esi,%eax
80101221:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101224:	5b                   	pop    %ebx
80101225:	5e                   	pop    %esi
80101226:	5f                   	pop    %edi
80101227:	5d                   	pop    %ebp
80101228:	c3                   	ret    
    panic("iget: no inodes");
80101229:	83 ec 0c             	sub    $0xc,%esp
8010122c:	68 28 6b 10 80       	push   $0x80106b28
80101231:	e8 12 f1 ff ff       	call   80100348 <panic>

80101236 <readsb>:
{
80101236:	55                   	push   %ebp
80101237:	89 e5                	mov    %esp,%ebp
80101239:	53                   	push   %ebx
8010123a:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
8010123d:	6a 01                	push   $0x1
8010123f:	ff 75 08             	pushl  0x8(%ebp)
80101242:	e8 25 ef ff ff       	call   8010016c <bread>
80101247:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
80101249:	8d 40 5c             	lea    0x5c(%eax),%eax
8010124c:	83 c4 0c             	add    $0xc,%esp
8010124f:	6a 1c                	push   $0x1c
80101251:	50                   	push   %eax
80101252:	ff 75 0c             	pushl  0xc(%ebp)
80101255:	e8 cf 2f 00 00       	call   80104229 <memmove>
  brelse(bp);
8010125a:	89 1c 24             	mov    %ebx,(%esp)
8010125d:	e8 73 ef ff ff       	call   801001d5 <brelse>
}
80101262:	83 c4 10             	add    $0x10,%esp
80101265:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101268:	c9                   	leave  
80101269:	c3                   	ret    

8010126a <bfree>:
{
8010126a:	55                   	push   %ebp
8010126b:	89 e5                	mov    %esp,%ebp
8010126d:	56                   	push   %esi
8010126e:	53                   	push   %ebx
8010126f:	89 c6                	mov    %eax,%esi
80101271:	89 d3                	mov    %edx,%ebx
  readsb(dev, &sb);
80101273:	83 ec 08             	sub    $0x8,%esp
80101276:	68 c0 09 11 80       	push   $0x801109c0
8010127b:	50                   	push   %eax
8010127c:	e8 b5 ff ff ff       	call   80101236 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101281:	89 d8                	mov    %ebx,%eax
80101283:	c1 e8 0c             	shr    $0xc,%eax
80101286:	03 05 d8 09 11 80    	add    0x801109d8,%eax
8010128c:	83 c4 08             	add    $0x8,%esp
8010128f:	50                   	push   %eax
80101290:	56                   	push   %esi
80101291:	e8 d6 ee ff ff       	call   8010016c <bread>
80101296:	89 c6                	mov    %eax,%esi
  m = 1 << (bi % 8);
80101298:	89 d9                	mov    %ebx,%ecx
8010129a:	83 e1 07             	and    $0x7,%ecx
8010129d:	b8 01 00 00 00       	mov    $0x1,%eax
801012a2:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
801012a4:	83 c4 10             	add    $0x10,%esp
801012a7:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801012ad:	c1 fb 03             	sar    $0x3,%ebx
801012b0:	0f b6 54 1e 5c       	movzbl 0x5c(%esi,%ebx,1),%edx
801012b5:	0f b6 ca             	movzbl %dl,%ecx
801012b8:	85 c1                	test   %eax,%ecx
801012ba:	74 23                	je     801012df <bfree+0x75>
  bp->data[bi/8] &= ~m;
801012bc:	f7 d0                	not    %eax
801012be:	21 d0                	and    %edx,%eax
801012c0:	88 44 1e 5c          	mov    %al,0x5c(%esi,%ebx,1)
  log_write(bp);
801012c4:	83 ec 0c             	sub    $0xc,%esp
801012c7:	56                   	push   %esi
801012c8:	e8 0a 16 00 00       	call   801028d7 <log_write>
  brelse(bp);
801012cd:	89 34 24             	mov    %esi,(%esp)
801012d0:	e8 00 ef ff ff       	call   801001d5 <brelse>
}
801012d5:	83 c4 10             	add    $0x10,%esp
801012d8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801012db:	5b                   	pop    %ebx
801012dc:	5e                   	pop    %esi
801012dd:	5d                   	pop    %ebp
801012de:	c3                   	ret    
    panic("freeing free block");
801012df:	83 ec 0c             	sub    $0xc,%esp
801012e2:	68 38 6b 10 80       	push   $0x80106b38
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 4b 6b 10 80       	push   $0x80106b4b
801012f8:	68 e0 09 11 80       	push   $0x801109e0
801012fd:	e8 c4 2c 00 00       	call   80103fc6 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 52 6b 10 80       	push   $0x80106b52
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 20 0a 11 80       	add    $0x80110a20,%eax
80101321:	50                   	push   %eax
80101322:	e8 94 2b 00 00       	call   80103ebb <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101327:	83 c3 01             	add    $0x1,%ebx
8010132a:	83 c4 10             	add    $0x10,%esp
8010132d:	83 fb 31             	cmp    $0x31,%ebx
80101330:	7e da                	jle    8010130c <iinit+0x20>
  readsb(dev, &sb);
80101332:	83 ec 08             	sub    $0x8,%esp
80101335:	68 c0 09 11 80       	push   $0x801109c0
8010133a:	ff 75 08             	pushl  0x8(%ebp)
8010133d:	e8 f4 fe ff ff       	call   80101236 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101342:	ff 35 d8 09 11 80    	pushl  0x801109d8
80101348:	ff 35 d4 09 11 80    	pushl  0x801109d4
8010134e:	ff 35 d0 09 11 80    	pushl  0x801109d0
80101354:	ff 35 cc 09 11 80    	pushl  0x801109cc
8010135a:	ff 35 c8 09 11 80    	pushl  0x801109c8
80101360:	ff 35 c4 09 11 80    	pushl  0x801109c4
80101366:	ff 35 c0 09 11 80    	pushl  0x801109c0
8010136c:	68 b8 6b 10 80       	push   $0x80106bb8
80101371:	e8 95 f2 ff ff       	call   8010060b <cprintf>
}
80101376:	83 c4 30             	add    $0x30,%esp
80101379:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010137c:	c9                   	leave  
8010137d:	c3                   	ret    

8010137e <ialloc>:
{
8010137e:	55                   	push   %ebp
8010137f:	89 e5                	mov    %esp,%ebp
80101381:	57                   	push   %edi
80101382:	56                   	push   %esi
80101383:	53                   	push   %ebx
80101384:	83 ec 1c             	sub    $0x1c,%esp
80101387:	8b 45 0c             	mov    0xc(%ebp),%eax
8010138a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
8010138d:	bb 01 00 00 00       	mov    $0x1,%ebx
80101392:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
80101395:	39 1d c8 09 11 80    	cmp    %ebx,0x801109c8
8010139b:	76 3f                	jbe    801013dc <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
8010139d:	89 d8                	mov    %ebx,%eax
8010139f:	c1 e8 03             	shr    $0x3,%eax
801013a2:	03 05 d4 09 11 80    	add    0x801109d4,%eax
801013a8:	83 ec 08             	sub    $0x8,%esp
801013ab:	50                   	push   %eax
801013ac:	ff 75 08             	pushl  0x8(%ebp)
801013af:	e8 b8 ed ff ff       	call   8010016c <bread>
801013b4:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
801013b6:	89 d8                	mov    %ebx,%eax
801013b8:	83 e0 07             	and    $0x7,%eax
801013bb:	c1 e0 06             	shl    $0x6,%eax
801013be:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
801013c2:	83 c4 10             	add    $0x10,%esp
801013c5:	66 83 3f 00          	cmpw   $0x0,(%edi)
801013c9:	74 1e                	je     801013e9 <ialloc+0x6b>
    brelse(bp);
801013cb:	83 ec 0c             	sub    $0xc,%esp
801013ce:	56                   	push   %esi
801013cf:	e8 01 ee ff ff       	call   801001d5 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
801013d4:	83 c3 01             	add    $0x1,%ebx
801013d7:	83 c4 10             	add    $0x10,%esp
801013da:	eb b6                	jmp    80101392 <ialloc+0x14>
  panic("ialloc: no inodes");
801013dc:	83 ec 0c             	sub    $0xc,%esp
801013df:	68 58 6b 10 80       	push   $0x80106b58
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 b8 2d 00 00       	call   801041ae <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 d2 14 00 00       	call   801028d7 <log_write>
      brelse(bp);
80101405:	89 34 24             	mov    %esi,(%esp)
80101408:	e8 c8 ed ff ff       	call   801001d5 <brelse>
      return iget(dev, inum);
8010140d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101410:	8b 45 08             	mov    0x8(%ebp),%eax
80101413:	e8 6f fd ff ff       	call   80101187 <iget>
}
80101418:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010141b:	5b                   	pop    %ebx
8010141c:	5e                   	pop    %esi
8010141d:	5f                   	pop    %edi
8010141e:	5d                   	pop    %ebp
8010141f:	c3                   	ret    

80101420 <iupdate>:
{
80101420:	55                   	push   %ebp
80101421:	89 e5                	mov    %esp,%ebp
80101423:	56                   	push   %esi
80101424:	53                   	push   %ebx
80101425:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101428:	8b 43 04             	mov    0x4(%ebx),%eax
8010142b:	c1 e8 03             	shr    $0x3,%eax
8010142e:	03 05 d4 09 11 80    	add    0x801109d4,%eax
80101434:	83 ec 08             	sub    $0x8,%esp
80101437:	50                   	push   %eax
80101438:	ff 33                	pushl  (%ebx)
8010143a:	e8 2d ed ff ff       	call   8010016c <bread>
8010143f:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101441:	8b 43 04             	mov    0x4(%ebx),%eax
80101444:	83 e0 07             	and    $0x7,%eax
80101447:	c1 e0 06             	shl    $0x6,%eax
8010144a:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
8010144e:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
80101452:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101455:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
80101459:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010145d:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
80101461:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101465:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
80101469:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010146d:	8b 53 58             	mov    0x58(%ebx),%edx
80101470:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101473:	83 c3 5c             	add    $0x5c,%ebx
80101476:	83 c0 0c             	add    $0xc,%eax
80101479:	83 c4 0c             	add    $0xc,%esp
8010147c:	6a 34                	push   $0x34
8010147e:	53                   	push   %ebx
8010147f:	50                   	push   %eax
80101480:	e8 a4 2d 00 00       	call   80104229 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 4a 14 00 00       	call   801028d7 <log_write>
  brelse(bp);
8010148d:	89 34 24             	mov    %esi,(%esp)
80101490:	e8 40 ed ff ff       	call   801001d5 <brelse>
}
80101495:	83 c4 10             	add    $0x10,%esp
80101498:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010149b:	5b                   	pop    %ebx
8010149c:	5e                   	pop    %esi
8010149d:	5d                   	pop    %ebp
8010149e:	c3                   	ret    

8010149f <itrunc>:
{
8010149f:	55                   	push   %ebp
801014a0:	89 e5                	mov    %esp,%ebp
801014a2:	57                   	push   %edi
801014a3:	56                   	push   %esi
801014a4:	53                   	push   %ebx
801014a5:	83 ec 1c             	sub    $0x1c,%esp
801014a8:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
801014aa:	bb 00 00 00 00       	mov    $0x0,%ebx
801014af:	eb 03                	jmp    801014b4 <itrunc+0x15>
801014b1:	83 c3 01             	add    $0x1,%ebx
801014b4:	83 fb 0b             	cmp    $0xb,%ebx
801014b7:	7f 19                	jg     801014d2 <itrunc+0x33>
    if(ip->addrs[i]){
801014b9:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
801014bd:	85 d2                	test   %edx,%edx
801014bf:	74 f0                	je     801014b1 <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
801014c1:	8b 06                	mov    (%esi),%eax
801014c3:	e8 a2 fd ff ff       	call   8010126a <bfree>
      ip->addrs[i] = 0;
801014c8:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
801014cf:	00 
801014d0:	eb df                	jmp    801014b1 <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
801014d2:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
801014d8:	85 c0                	test   %eax,%eax
801014da:	75 1b                	jne    801014f7 <itrunc+0x58>
  ip->size = 0;
801014dc:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
801014e3:	83 ec 0c             	sub    $0xc,%esp
801014e6:	56                   	push   %esi
801014e7:	e8 34 ff ff ff       	call   80101420 <iupdate>
}
801014ec:	83 c4 10             	add    $0x10,%esp
801014ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
801014f2:	5b                   	pop    %ebx
801014f3:	5e                   	pop    %esi
801014f4:	5f                   	pop    %edi
801014f5:	5d                   	pop    %ebp
801014f6:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801014f7:	83 ec 08             	sub    $0x8,%esp
801014fa:	50                   	push   %eax
801014fb:	ff 36                	pushl  (%esi)
801014fd:	e8 6a ec ff ff       	call   8010016c <bread>
80101502:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101505:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
80101508:	83 c4 10             	add    $0x10,%esp
8010150b:	bb 00 00 00 00       	mov    $0x0,%ebx
80101510:	eb 03                	jmp    80101515 <itrunc+0x76>
80101512:	83 c3 01             	add    $0x1,%ebx
80101515:	83 fb 7f             	cmp    $0x7f,%ebx
80101518:	77 10                	ja     8010152a <itrunc+0x8b>
      if(a[j])
8010151a:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
8010151d:	85 d2                	test   %edx,%edx
8010151f:	74 f1                	je     80101512 <itrunc+0x73>
        bfree(ip->dev, a[j]);
80101521:	8b 06                	mov    (%esi),%eax
80101523:	e8 42 fd ff ff       	call   8010126a <bfree>
80101528:	eb e8                	jmp    80101512 <itrunc+0x73>
    brelse(bp);
8010152a:	83 ec 0c             	sub    $0xc,%esp
8010152d:	ff 75 e4             	pushl  -0x1c(%ebp)
80101530:	e8 a0 ec ff ff       	call   801001d5 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101535:	8b 06                	mov    (%esi),%eax
80101537:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
8010153d:	e8 28 fd ff ff       	call   8010126a <bfree>
    ip->addrs[NDIRECT] = 0;
80101542:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
80101549:	00 00 00 
8010154c:	83 c4 10             	add    $0x10,%esp
8010154f:	eb 8b                	jmp    801014dc <itrunc+0x3d>

80101551 <idup>:
{
80101551:	55                   	push   %ebp
80101552:	89 e5                	mov    %esp,%ebp
80101554:	53                   	push   %ebx
80101555:	83 ec 10             	sub    $0x10,%esp
80101558:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
8010155b:	68 e0 09 11 80       	push   $0x801109e0
80101560:	e8 9d 2b 00 00       	call   80104102 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101575:	e8 ed 2b 00 00       	call   80104167 <release>
}
8010157a:	89 d8                	mov    %ebx,%eax
8010157c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010157f:	c9                   	leave  
80101580:	c3                   	ret    

80101581 <ilock>:
{
80101581:	55                   	push   %ebp
80101582:	89 e5                	mov    %esp,%ebp
80101584:	56                   	push   %esi
80101585:	53                   	push   %ebx
80101586:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101589:	85 db                	test   %ebx,%ebx
8010158b:	74 22                	je     801015af <ilock+0x2e>
8010158d:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101591:	7e 1c                	jle    801015af <ilock+0x2e>
  acquiresleep(&ip->lock);
80101593:	83 ec 0c             	sub    $0xc,%esp
80101596:	8d 43 0c             	lea    0xc(%ebx),%eax
80101599:	50                   	push   %eax
8010159a:	e8 4f 29 00 00       	call   80103eee <acquiresleep>
  if(ip->valid == 0){
8010159f:	83 c4 10             	add    $0x10,%esp
801015a2:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801015a6:	74 14                	je     801015bc <ilock+0x3b>
}
801015a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801015ab:	5b                   	pop    %ebx
801015ac:	5e                   	pop    %esi
801015ad:	5d                   	pop    %ebp
801015ae:	c3                   	ret    
    panic("ilock");
801015af:	83 ec 0c             	sub    $0xc,%esp
801015b2:	68 6a 6b 10 80       	push   $0x80106b6a
801015b7:	e8 8c ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015bc:	8b 43 04             	mov    0x4(%ebx),%eax
801015bf:	c1 e8 03             	shr    $0x3,%eax
801015c2:	03 05 d4 09 11 80    	add    0x801109d4,%eax
801015c8:	83 ec 08             	sub    $0x8,%esp
801015cb:	50                   	push   %eax
801015cc:	ff 33                	pushl  (%ebx)
801015ce:	e8 99 eb ff ff       	call   8010016c <bread>
801015d3:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801015d5:	8b 43 04             	mov    0x4(%ebx),%eax
801015d8:	83 e0 07             	and    $0x7,%eax
801015db:	c1 e0 06             	shl    $0x6,%eax
801015de:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
801015e2:	0f b7 10             	movzwl (%eax),%edx
801015e5:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
801015e9:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801015ed:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
801015f1:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801015f5:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
801015f9:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801015fd:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
80101601:	8b 50 08             	mov    0x8(%eax),%edx
80101604:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101607:	83 c0 0c             	add    $0xc,%eax
8010160a:	8d 53 5c             	lea    0x5c(%ebx),%edx
8010160d:	83 c4 0c             	add    $0xc,%esp
80101610:	6a 34                	push   $0x34
80101612:	50                   	push   %eax
80101613:	52                   	push   %edx
80101614:	e8 10 2c 00 00       	call   80104229 <memmove>
    brelse(bp);
80101619:	89 34 24             	mov    %esi,(%esp)
8010161c:	e8 b4 eb ff ff       	call   801001d5 <brelse>
    ip->valid = 1;
80101621:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
80101628:	83 c4 10             	add    $0x10,%esp
8010162b:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
80101630:	0f 85 72 ff ff ff    	jne    801015a8 <ilock+0x27>
      panic("ilock: no type");
80101636:	83 ec 0c             	sub    $0xc,%esp
80101639:	68 70 6b 10 80       	push   $0x80106b70
8010163e:	e8 05 ed ff ff       	call   80100348 <panic>

80101643 <iunlock>:
{
80101643:	55                   	push   %ebp
80101644:	89 e5                	mov    %esp,%ebp
80101646:	56                   	push   %esi
80101647:	53                   	push   %ebx
80101648:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
8010164b:	85 db                	test   %ebx,%ebx
8010164d:	74 2c                	je     8010167b <iunlock+0x38>
8010164f:	8d 73 0c             	lea    0xc(%ebx),%esi
80101652:	83 ec 0c             	sub    $0xc,%esp
80101655:	56                   	push   %esi
80101656:	e8 1d 29 00 00       	call   80103f78 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 cc 28 00 00       	call   80103f3d <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 7f 6b 10 80       	push   $0x80106b7f
80101683:	e8 c0 ec ff ff       	call   80100348 <panic>

80101688 <iput>:
{
80101688:	55                   	push   %ebp
80101689:	89 e5                	mov    %esp,%ebp
8010168b:	57                   	push   %edi
8010168c:	56                   	push   %esi
8010168d:	53                   	push   %ebx
8010168e:	83 ec 18             	sub    $0x18,%esp
80101691:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
80101694:	8d 73 0c             	lea    0xc(%ebx),%esi
80101697:	56                   	push   %esi
80101698:	e8 51 28 00 00       	call   80103eee <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 87 28 00 00       	call   80103f3d <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016bd:	e8 40 2a 00 00       	call   80104102 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016d2:	e8 90 2a 00 00       	call   80104167 <release>
}
801016d7:	83 c4 10             	add    $0x10,%esp
801016da:	8d 65 f4             	lea    -0xc(%ebp),%esp
801016dd:	5b                   	pop    %ebx
801016de:	5e                   	pop    %esi
801016df:	5f                   	pop    %edi
801016e0:	5d                   	pop    %ebp
801016e1:	c3                   	ret    
    acquire(&icache.lock);
801016e2:	83 ec 0c             	sub    $0xc,%esp
801016e5:	68 e0 09 11 80       	push   $0x801109e0
801016ea:	e8 13 2a 00 00       	call   80104102 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016f9:	e8 69 2a 00 00       	call   80104167 <release>
    if(r == 1){
801016fe:	83 c4 10             	add    $0x10,%esp
80101701:	83 ff 01             	cmp    $0x1,%edi
80101704:	75 a7                	jne    801016ad <iput+0x25>
      itrunc(ip);
80101706:	89 d8                	mov    %ebx,%eax
80101708:	e8 92 fd ff ff       	call   8010149f <itrunc>
      ip->type = 0;
8010170d:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
80101713:	83 ec 0c             	sub    $0xc,%esp
80101716:	53                   	push   %ebx
80101717:	e8 04 fd ff ff       	call   80101420 <iupdate>
      ip->valid = 0;
8010171c:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
80101723:	83 c4 10             	add    $0x10,%esp
80101726:	eb 85                	jmp    801016ad <iput+0x25>

80101728 <iunlockput>:
{
80101728:	55                   	push   %ebp
80101729:	89 e5                	mov    %esp,%ebp
8010172b:	53                   	push   %ebx
8010172c:	83 ec 10             	sub    $0x10,%esp
8010172f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
80101732:	53                   	push   %ebx
80101733:	e8 0b ff ff ff       	call   80101643 <iunlock>
  iput(ip);
80101738:	89 1c 24             	mov    %ebx,(%esp)
8010173b:	e8 48 ff ff ff       	call   80101688 <iput>
}
80101740:	83 c4 10             	add    $0x10,%esp
80101743:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101746:	c9                   	leave  
80101747:	c3                   	ret    

80101748 <stati>:
{
80101748:	55                   	push   %ebp
80101749:	89 e5                	mov    %esp,%ebp
8010174b:	8b 55 08             	mov    0x8(%ebp),%edx
8010174e:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
80101751:	8b 0a                	mov    (%edx),%ecx
80101753:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
80101756:	8b 4a 04             	mov    0x4(%edx),%ecx
80101759:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
8010175c:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
80101760:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
80101763:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101767:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
8010176b:	8b 52 58             	mov    0x58(%edx),%edx
8010176e:	89 50 10             	mov    %edx,0x10(%eax)
}
80101771:	5d                   	pop    %ebp
80101772:	c3                   	ret    

80101773 <readi>:
{
80101773:	55                   	push   %ebp
80101774:	89 e5                	mov    %esp,%ebp
80101776:	57                   	push   %edi
80101777:	56                   	push   %esi
80101778:	53                   	push   %ebx
80101779:	83 ec 1c             	sub    $0x1c,%esp
8010177c:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(ip->type == T_DEV){
8010177f:	8b 45 08             	mov    0x8(%ebp),%eax
80101782:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101787:	74 2c                	je     801017b5 <readi+0x42>
  if(off > ip->size || off + n < off)
80101789:	8b 45 08             	mov    0x8(%ebp),%eax
8010178c:	8b 40 58             	mov    0x58(%eax),%eax
8010178f:	39 f8                	cmp    %edi,%eax
80101791:	0f 82 cb 00 00 00    	jb     80101862 <readi+0xef>
80101797:	89 fa                	mov    %edi,%edx
80101799:	03 55 14             	add    0x14(%ebp),%edx
8010179c:	0f 82 c7 00 00 00    	jb     80101869 <readi+0xf6>
  if(off + n > ip->size)
801017a2:	39 d0                	cmp    %edx,%eax
801017a4:	73 05                	jae    801017ab <readi+0x38>
    n = ip->size - off;
801017a6:	29 f8                	sub    %edi,%eax
801017a8:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801017ab:	be 00 00 00 00       	mov    $0x0,%esi
801017b0:	e9 8f 00 00 00       	jmp    80101844 <readi+0xd1>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801017b5:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801017b9:	66 83 f8 09          	cmp    $0x9,%ax
801017bd:	0f 87 91 00 00 00    	ja     80101854 <readi+0xe1>
801017c3:	98                   	cwtl   
801017c4:	8b 04 c5 60 09 11 80 	mov    -0x7feef6a0(,%eax,8),%eax
801017cb:	85 c0                	test   %eax,%eax
801017cd:	0f 84 88 00 00 00    	je     8010185b <readi+0xe8>
    return devsw[ip->major].read(ip, dst, n);
801017d3:	83 ec 04             	sub    $0x4,%esp
801017d6:	ff 75 14             	pushl  0x14(%ebp)
801017d9:	ff 75 0c             	pushl  0xc(%ebp)
801017dc:	ff 75 08             	pushl  0x8(%ebp)
801017df:	ff d0                	call   *%eax
801017e1:	83 c4 10             	add    $0x10,%esp
801017e4:	eb 66                	jmp    8010184c <readi+0xd9>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801017e6:	89 fa                	mov    %edi,%edx
801017e8:	c1 ea 09             	shr    $0x9,%edx
801017eb:	8b 45 08             	mov    0x8(%ebp),%eax
801017ee:	e8 ee f8 ff ff       	call   801010e1 <bmap>
801017f3:	83 ec 08             	sub    $0x8,%esp
801017f6:	50                   	push   %eax
801017f7:	8b 45 08             	mov    0x8(%ebp),%eax
801017fa:	ff 30                	pushl  (%eax)
801017fc:	e8 6b e9 ff ff       	call   8010016c <bread>
80101801:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
80101803:	89 f8                	mov    %edi,%eax
80101805:	25 ff 01 00 00       	and    $0x1ff,%eax
8010180a:	bb 00 02 00 00       	mov    $0x200,%ebx
8010180f:	29 c3                	sub    %eax,%ebx
80101811:	8b 55 14             	mov    0x14(%ebp),%edx
80101814:	29 f2                	sub    %esi,%edx
80101816:	83 c4 0c             	add    $0xc,%esp
80101819:	39 d3                	cmp    %edx,%ebx
8010181b:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
8010181e:	53                   	push   %ebx
8010181f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
80101822:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
80101826:	50                   	push   %eax
80101827:	ff 75 0c             	pushl  0xc(%ebp)
8010182a:	e8 fa 29 00 00       	call   80104229 <memmove>
    brelse(bp);
8010182f:	83 c4 04             	add    $0x4,%esp
80101832:	ff 75 e4             	pushl  -0x1c(%ebp)
80101835:	e8 9b e9 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010183a:	01 de                	add    %ebx,%esi
8010183c:	01 df                	add    %ebx,%edi
8010183e:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101841:	83 c4 10             	add    $0x10,%esp
80101844:	39 75 14             	cmp    %esi,0x14(%ebp)
80101847:	77 9d                	ja     801017e6 <readi+0x73>
  return n;
80101849:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010184c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010184f:	5b                   	pop    %ebx
80101850:	5e                   	pop    %esi
80101851:	5f                   	pop    %edi
80101852:	5d                   	pop    %ebp
80101853:	c3                   	ret    
      return -1;
80101854:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101859:	eb f1                	jmp    8010184c <readi+0xd9>
8010185b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101860:	eb ea                	jmp    8010184c <readi+0xd9>
    return -1;
80101862:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101867:	eb e3                	jmp    8010184c <readi+0xd9>
80101869:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010186e:	eb dc                	jmp    8010184c <readi+0xd9>

80101870 <writei>:
{
80101870:	55                   	push   %ebp
80101871:	89 e5                	mov    %esp,%ebp
80101873:	57                   	push   %edi
80101874:	56                   	push   %esi
80101875:	53                   	push   %ebx
80101876:	83 ec 0c             	sub    $0xc,%esp
  if(ip->type == T_DEV){
80101879:	8b 45 08             	mov    0x8(%ebp),%eax
8010187c:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101881:	74 2f                	je     801018b2 <writei+0x42>
  if(off > ip->size || off + n < off)
80101883:	8b 45 08             	mov    0x8(%ebp),%eax
80101886:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101889:	39 48 58             	cmp    %ecx,0x58(%eax)
8010188c:	0f 82 f4 00 00 00    	jb     80101986 <writei+0x116>
80101892:	89 c8                	mov    %ecx,%eax
80101894:	03 45 14             	add    0x14(%ebp),%eax
80101897:	0f 82 f0 00 00 00    	jb     8010198d <writei+0x11d>
  if(off + n > MAXFILE*BSIZE)
8010189d:	3d 00 18 01 00       	cmp    $0x11800,%eax
801018a2:	0f 87 ec 00 00 00    	ja     80101994 <writei+0x124>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801018a8:	be 00 00 00 00       	mov    $0x0,%esi
801018ad:	e9 94 00 00 00       	jmp    80101946 <writei+0xd6>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801018b2:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801018b6:	66 83 f8 09          	cmp    $0x9,%ax
801018ba:	0f 87 b8 00 00 00    	ja     80101978 <writei+0x108>
801018c0:	98                   	cwtl   
801018c1:	8b 04 c5 64 09 11 80 	mov    -0x7feef69c(,%eax,8),%eax
801018c8:	85 c0                	test   %eax,%eax
801018ca:	0f 84 af 00 00 00    	je     8010197f <writei+0x10f>
    return devsw[ip->major].write(ip, src, n);
801018d0:	83 ec 04             	sub    $0x4,%esp
801018d3:	ff 75 14             	pushl  0x14(%ebp)
801018d6:	ff 75 0c             	pushl  0xc(%ebp)
801018d9:	ff 75 08             	pushl  0x8(%ebp)
801018dc:	ff d0                	call   *%eax
801018de:	83 c4 10             	add    $0x10,%esp
801018e1:	eb 7c                	jmp    8010195f <writei+0xef>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801018e3:	8b 55 10             	mov    0x10(%ebp),%edx
801018e6:	c1 ea 09             	shr    $0x9,%edx
801018e9:	8b 45 08             	mov    0x8(%ebp),%eax
801018ec:	e8 f0 f7 ff ff       	call   801010e1 <bmap>
801018f1:	83 ec 08             	sub    $0x8,%esp
801018f4:	50                   	push   %eax
801018f5:	8b 45 08             	mov    0x8(%ebp),%eax
801018f8:	ff 30                	pushl  (%eax)
801018fa:	e8 6d e8 ff ff       	call   8010016c <bread>
801018ff:	89 c7                	mov    %eax,%edi
    m = min(n - tot, BSIZE - off%BSIZE);
80101901:	8b 45 10             	mov    0x10(%ebp),%eax
80101904:	25 ff 01 00 00       	and    $0x1ff,%eax
80101909:	bb 00 02 00 00       	mov    $0x200,%ebx
8010190e:	29 c3                	sub    %eax,%ebx
80101910:	8b 55 14             	mov    0x14(%ebp),%edx
80101913:	29 f2                	sub    %esi,%edx
80101915:	83 c4 0c             	add    $0xc,%esp
80101918:	39 d3                	cmp    %edx,%ebx
8010191a:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
8010191d:	53                   	push   %ebx
8010191e:	ff 75 0c             	pushl  0xc(%ebp)
80101921:	8d 44 07 5c          	lea    0x5c(%edi,%eax,1),%eax
80101925:	50                   	push   %eax
80101926:	e8 fe 28 00 00       	call   80104229 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 a4 0f 00 00       	call   801028d7 <log_write>
    brelse(bp);
80101933:	89 3c 24             	mov    %edi,(%esp)
80101936:	e8 9a e8 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010193b:	01 de                	add    %ebx,%esi
8010193d:	01 5d 10             	add    %ebx,0x10(%ebp)
80101940:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101943:	83 c4 10             	add    $0x10,%esp
80101946:	3b 75 14             	cmp    0x14(%ebp),%esi
80101949:	72 98                	jb     801018e3 <writei+0x73>
  if(n > 0 && off > ip->size){
8010194b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010194f:	74 0b                	je     8010195c <writei+0xec>
80101951:	8b 45 08             	mov    0x8(%ebp),%eax
80101954:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101957:	39 48 58             	cmp    %ecx,0x58(%eax)
8010195a:	72 0b                	jb     80101967 <writei+0xf7>
  return n;
8010195c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010195f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101962:	5b                   	pop    %ebx
80101963:	5e                   	pop    %esi
80101964:	5f                   	pop    %edi
80101965:	5d                   	pop    %ebp
80101966:	c3                   	ret    
    ip->size = off;
80101967:	89 48 58             	mov    %ecx,0x58(%eax)
    iupdate(ip);
8010196a:	83 ec 0c             	sub    $0xc,%esp
8010196d:	50                   	push   %eax
8010196e:	e8 ad fa ff ff       	call   80101420 <iupdate>
80101973:	83 c4 10             	add    $0x10,%esp
80101976:	eb e4                	jmp    8010195c <writei+0xec>
      return -1;
80101978:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010197d:	eb e0                	jmp    8010195f <writei+0xef>
8010197f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101984:	eb d9                	jmp    8010195f <writei+0xef>
    return -1;
80101986:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010198b:	eb d2                	jmp    8010195f <writei+0xef>
8010198d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101992:	eb cb                	jmp    8010195f <writei+0xef>
    return -1;
80101994:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101999:	eb c4                	jmp    8010195f <writei+0xef>

8010199b <namecmp>:
{
8010199b:	55                   	push   %ebp
8010199c:	89 e5                	mov    %esp,%ebp
8010199e:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
801019a1:	6a 0e                	push   $0xe
801019a3:	ff 75 0c             	pushl  0xc(%ebp)
801019a6:	ff 75 08             	pushl  0x8(%ebp)
801019a9:	e8 e2 28 00 00       	call   80104290 <strncmp>
}
801019ae:	c9                   	leave  
801019af:	c3                   	ret    

801019b0 <dirlookup>:
{
801019b0:	55                   	push   %ebp
801019b1:	89 e5                	mov    %esp,%ebp
801019b3:	57                   	push   %edi
801019b4:	56                   	push   %esi
801019b5:	53                   	push   %ebx
801019b6:	83 ec 1c             	sub    $0x1c,%esp
801019b9:	8b 75 08             	mov    0x8(%ebp),%esi
801019bc:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
801019bf:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801019c4:	75 07                	jne    801019cd <dirlookup+0x1d>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019c6:	bb 00 00 00 00       	mov    $0x0,%ebx
801019cb:	eb 1d                	jmp    801019ea <dirlookup+0x3a>
    panic("dirlookup not DIR");
801019cd:	83 ec 0c             	sub    $0xc,%esp
801019d0:	68 87 6b 10 80       	push   $0x80106b87
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 99 6b 10 80       	push   $0x80106b99
801019e2:	e8 61 e9 ff ff       	call   80100348 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019e7:	83 c3 10             	add    $0x10,%ebx
801019ea:	39 5e 58             	cmp    %ebx,0x58(%esi)
801019ed:	76 48                	jbe    80101a37 <dirlookup+0x87>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801019ef:	6a 10                	push   $0x10
801019f1:	53                   	push   %ebx
801019f2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801019f5:	50                   	push   %eax
801019f6:	56                   	push   %esi
801019f7:	e8 77 fd ff ff       	call   80101773 <readi>
801019fc:	83 c4 10             	add    $0x10,%esp
801019ff:	83 f8 10             	cmp    $0x10,%eax
80101a02:	75 d6                	jne    801019da <dirlookup+0x2a>
    if(de.inum == 0)
80101a04:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101a09:	74 dc                	je     801019e7 <dirlookup+0x37>
    if(namecmp(name, de.name) == 0){
80101a0b:	83 ec 08             	sub    $0x8,%esp
80101a0e:	8d 45 da             	lea    -0x26(%ebp),%eax
80101a11:	50                   	push   %eax
80101a12:	57                   	push   %edi
80101a13:	e8 83 ff ff ff       	call   8010199b <namecmp>
80101a18:	83 c4 10             	add    $0x10,%esp
80101a1b:	85 c0                	test   %eax,%eax
80101a1d:	75 c8                	jne    801019e7 <dirlookup+0x37>
      if(poff)
80101a1f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101a23:	74 05                	je     80101a2a <dirlookup+0x7a>
        *poff = off;
80101a25:	8b 45 10             	mov    0x10(%ebp),%eax
80101a28:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101a2a:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101a2e:	8b 06                	mov    (%esi),%eax
80101a30:	e8 52 f7 ff ff       	call   80101187 <iget>
80101a35:	eb 05                	jmp    80101a3c <dirlookup+0x8c>
  return 0;
80101a37:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101a3c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a3f:	5b                   	pop    %ebx
80101a40:	5e                   	pop    %esi
80101a41:	5f                   	pop    %edi
80101a42:	5d                   	pop    %ebp
80101a43:	c3                   	ret    

80101a44 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101a44:	55                   	push   %ebp
80101a45:	89 e5                	mov    %esp,%ebp
80101a47:	57                   	push   %edi
80101a48:	56                   	push   %esi
80101a49:	53                   	push   %ebx
80101a4a:	83 ec 1c             	sub    $0x1c,%esp
80101a4d:	89 c6                	mov    %eax,%esi
80101a4f:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101a52:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101a55:	80 38 2f             	cmpb   $0x2f,(%eax)
80101a58:	74 17                	je     80101a71 <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101a5a:	e8 d2 17 00 00       	call   80103231 <myproc>
80101a5f:	83 ec 0c             	sub    $0xc,%esp
80101a62:	ff 70 68             	pushl  0x68(%eax)
80101a65:	e8 e7 fa ff ff       	call   80101551 <idup>
80101a6a:	89 c3                	mov    %eax,%ebx
80101a6c:	83 c4 10             	add    $0x10,%esp
80101a6f:	eb 53                	jmp    80101ac4 <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101a71:	ba 01 00 00 00       	mov    $0x1,%edx
80101a76:	b8 01 00 00 00       	mov    $0x1,%eax
80101a7b:	e8 07 f7 ff ff       	call   80101187 <iget>
80101a80:	89 c3                	mov    %eax,%ebx
80101a82:	eb 40                	jmp    80101ac4 <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101a84:	83 ec 0c             	sub    $0xc,%esp
80101a87:	53                   	push   %ebx
80101a88:	e8 9b fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101a8d:	83 c4 10             	add    $0x10,%esp
80101a90:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101a95:	89 d8                	mov    %ebx,%eax
80101a97:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a9a:	5b                   	pop    %ebx
80101a9b:	5e                   	pop    %esi
80101a9c:	5f                   	pop    %edi
80101a9d:	5d                   	pop    %ebp
80101a9e:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101a9f:	83 ec 04             	sub    $0x4,%esp
80101aa2:	6a 00                	push   $0x0
80101aa4:	ff 75 e4             	pushl  -0x1c(%ebp)
80101aa7:	53                   	push   %ebx
80101aa8:	e8 03 ff ff ff       	call   801019b0 <dirlookup>
80101aad:	89 c7                	mov    %eax,%edi
80101aaf:	83 c4 10             	add    $0x10,%esp
80101ab2:	85 c0                	test   %eax,%eax
80101ab4:	74 4a                	je     80101b00 <namex+0xbc>
    iunlockput(ip);
80101ab6:	83 ec 0c             	sub    $0xc,%esp
80101ab9:	53                   	push   %ebx
80101aba:	e8 69 fc ff ff       	call   80101728 <iunlockput>
    ip = next;
80101abf:	83 c4 10             	add    $0x10,%esp
80101ac2:	89 fb                	mov    %edi,%ebx
  while((path = skipelem(path, name)) != 0){
80101ac4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101ac7:	89 f0                	mov    %esi,%eax
80101ac9:	e8 77 f4 ff ff       	call   80100f45 <skipelem>
80101ace:	89 c6                	mov    %eax,%esi
80101ad0:	85 c0                	test   %eax,%eax
80101ad2:	74 3c                	je     80101b10 <namex+0xcc>
    ilock(ip);
80101ad4:	83 ec 0c             	sub    $0xc,%esp
80101ad7:	53                   	push   %ebx
80101ad8:	e8 a4 fa ff ff       	call   80101581 <ilock>
    if(ip->type != T_DIR){
80101add:	83 c4 10             	add    $0x10,%esp
80101ae0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80101ae5:	75 9d                	jne    80101a84 <namex+0x40>
    if(nameiparent && *path == '\0'){
80101ae7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101aeb:	74 b2                	je     80101a9f <namex+0x5b>
80101aed:	80 3e 00             	cmpb   $0x0,(%esi)
80101af0:	75 ad                	jne    80101a9f <namex+0x5b>
      iunlock(ip);
80101af2:	83 ec 0c             	sub    $0xc,%esp
80101af5:	53                   	push   %ebx
80101af6:	e8 48 fb ff ff       	call   80101643 <iunlock>
      return ip;
80101afb:	83 c4 10             	add    $0x10,%esp
80101afe:	eb 95                	jmp    80101a95 <namex+0x51>
      iunlockput(ip);
80101b00:	83 ec 0c             	sub    $0xc,%esp
80101b03:	53                   	push   %ebx
80101b04:	e8 1f fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101b09:	83 c4 10             	add    $0x10,%esp
80101b0c:	89 fb                	mov    %edi,%ebx
80101b0e:	eb 85                	jmp    80101a95 <namex+0x51>
  if(nameiparent){
80101b10:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b14:	0f 84 7b ff ff ff    	je     80101a95 <namex+0x51>
    iput(ip);
80101b1a:	83 ec 0c             	sub    $0xc,%esp
80101b1d:	53                   	push   %ebx
80101b1e:	e8 65 fb ff ff       	call   80101688 <iput>
    return 0;
80101b23:	83 c4 10             	add    $0x10,%esp
80101b26:	bb 00 00 00 00       	mov    $0x0,%ebx
80101b2b:	e9 65 ff ff ff       	jmp    80101a95 <namex+0x51>

80101b30 <dirlink>:
{
80101b30:	55                   	push   %ebp
80101b31:	89 e5                	mov    %esp,%ebp
80101b33:	57                   	push   %edi
80101b34:	56                   	push   %esi
80101b35:	53                   	push   %ebx
80101b36:	83 ec 20             	sub    $0x20,%esp
80101b39:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101b3c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101b3f:	6a 00                	push   $0x0
80101b41:	57                   	push   %edi
80101b42:	53                   	push   %ebx
80101b43:	e8 68 fe ff ff       	call   801019b0 <dirlookup>
80101b48:	83 c4 10             	add    $0x10,%esp
80101b4b:	85 c0                	test   %eax,%eax
80101b4d:	75 2d                	jne    80101b7c <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b4f:	b8 00 00 00 00       	mov    $0x0,%eax
80101b54:	89 c6                	mov    %eax,%esi
80101b56:	39 43 58             	cmp    %eax,0x58(%ebx)
80101b59:	76 41                	jbe    80101b9c <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101b5b:	6a 10                	push   $0x10
80101b5d:	50                   	push   %eax
80101b5e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101b61:	50                   	push   %eax
80101b62:	53                   	push   %ebx
80101b63:	e8 0b fc ff ff       	call   80101773 <readi>
80101b68:	83 c4 10             	add    $0x10,%esp
80101b6b:	83 f8 10             	cmp    $0x10,%eax
80101b6e:	75 1f                	jne    80101b8f <dirlink+0x5f>
    if(de.inum == 0)
80101b70:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101b75:	74 25                	je     80101b9c <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b77:	8d 46 10             	lea    0x10(%esi),%eax
80101b7a:	eb d8                	jmp    80101b54 <dirlink+0x24>
    iput(ip);
80101b7c:	83 ec 0c             	sub    $0xc,%esp
80101b7f:	50                   	push   %eax
80101b80:	e8 03 fb ff ff       	call   80101688 <iput>
    return -1;
80101b85:	83 c4 10             	add    $0x10,%esp
80101b88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101b8d:	eb 3d                	jmp    80101bcc <dirlink+0x9c>
      panic("dirlink read");
80101b8f:	83 ec 0c             	sub    $0xc,%esp
80101b92:	68 a8 6b 10 80       	push   $0x80106ba8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 1f 27 00 00       	call   801042cd <strncpy>
  de.inum = inum;
80101bae:	8b 45 10             	mov    0x10(%ebp),%eax
80101bb1:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101bb5:	6a 10                	push   $0x10
80101bb7:	56                   	push   %esi
80101bb8:	57                   	push   %edi
80101bb9:	53                   	push   %ebx
80101bba:	e8 b1 fc ff ff       	call   80101870 <writei>
80101bbf:	83 c4 20             	add    $0x20,%esp
80101bc2:	83 f8 10             	cmp    $0x10,%eax
80101bc5:	75 0d                	jne    80101bd4 <dirlink+0xa4>
  return 0;
80101bc7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101bcc:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101bcf:	5b                   	pop    %ebx
80101bd0:	5e                   	pop    %esi
80101bd1:	5f                   	pop    %edi
80101bd2:	5d                   	pop    %ebp
80101bd3:	c3                   	ret    
    panic("dirlink");
80101bd4:	83 ec 0c             	sub    $0xc,%esp
80101bd7:	68 80 72 10 80       	push   $0x80107280
80101bdc:	e8 67 e7 ff ff       	call   80100348 <panic>

80101be1 <namei>:

struct inode*
namei(char *path)
{
80101be1:	55                   	push   %ebp
80101be2:	89 e5                	mov    %esp,%ebp
80101be4:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101be7:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101bea:	ba 00 00 00 00       	mov    $0x0,%edx
80101bef:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf2:	e8 4d fe ff ff       	call   80101a44 <namex>
}
80101bf7:	c9                   	leave  
80101bf8:	c3                   	ret    

80101bf9 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101bf9:	55                   	push   %ebp
80101bfa:	89 e5                	mov    %esp,%ebp
80101bfc:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101bff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101c02:	ba 01 00 00 00       	mov    $0x1,%edx
80101c07:	8b 45 08             	mov    0x8(%ebp),%eax
80101c0a:	e8 35 fe ff ff       	call   80101a44 <namex>
}
80101c0f:	c9                   	leave  
80101c10:	c3                   	ret    

80101c11 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101c11:	55                   	push   %ebp
80101c12:	89 e5                	mov    %esp,%ebp
80101c14:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101c16:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101c1b:	ec                   	in     (%dx),%al
80101c1c:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101c1e:	83 e0 c0             	and    $0xffffffc0,%eax
80101c21:	3c 40                	cmp    $0x40,%al
80101c23:	75 f1                	jne    80101c16 <idewait+0x5>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101c25:	85 c9                	test   %ecx,%ecx
80101c27:	74 0c                	je     80101c35 <idewait+0x24>
80101c29:	f6 c2 21             	test   $0x21,%dl
80101c2c:	75 0e                	jne    80101c3c <idewait+0x2b>
    return -1;
  return 0;
80101c2e:	b8 00 00 00 00       	mov    $0x0,%eax
80101c33:	eb 05                	jmp    80101c3a <idewait+0x29>
80101c35:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c3a:	5d                   	pop    %ebp
80101c3b:	c3                   	ret    
    return -1;
80101c3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c41:	eb f7                	jmp    80101c3a <idewait+0x29>

80101c43 <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101c43:	55                   	push   %ebp
80101c44:	89 e5                	mov    %esp,%ebp
80101c46:	56                   	push   %esi
80101c47:	53                   	push   %ebx
  if(b == 0)
80101c48:	85 c0                	test   %eax,%eax
80101c4a:	74 7d                	je     80101cc9 <idestart+0x86>
80101c4c:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101c4e:	8b 58 08             	mov    0x8(%eax),%ebx
80101c51:	81 fb e7 03 00 00    	cmp    $0x3e7,%ebx
80101c57:	77 7d                	ja     80101cd6 <idestart+0x93>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101c59:	b8 00 00 00 00       	mov    $0x0,%eax
80101c5e:	e8 ae ff ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101c63:	b8 00 00 00 00       	mov    $0x0,%eax
80101c68:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101c6d:	ee                   	out    %al,(%dx)
80101c6e:	b8 01 00 00 00       	mov    $0x1,%eax
80101c73:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101c78:	ee                   	out    %al,(%dx)
80101c79:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101c7e:	89 d8                	mov    %ebx,%eax
80101c80:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101c81:	89 d8                	mov    %ebx,%eax
80101c83:	c1 f8 08             	sar    $0x8,%eax
80101c86:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101c8b:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101c8c:	89 d8                	mov    %ebx,%eax
80101c8e:	c1 f8 10             	sar    $0x10,%eax
80101c91:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101c96:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101c97:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101c9b:	c1 e0 04             	shl    $0x4,%eax
80101c9e:	83 e0 10             	and    $0x10,%eax
80101ca1:	c1 fb 18             	sar    $0x18,%ebx
80101ca4:	83 e3 0f             	and    $0xf,%ebx
80101ca7:	09 d8                	or     %ebx,%eax
80101ca9:	83 c8 e0             	or     $0xffffffe0,%eax
80101cac:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101cb1:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101cb2:	f6 06 04             	testb  $0x4,(%esi)
80101cb5:	75 2c                	jne    80101ce3 <idestart+0xa0>
80101cb7:	b8 20 00 00 00       	mov    $0x20,%eax
80101cbc:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101cc1:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101cc2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101cc5:	5b                   	pop    %ebx
80101cc6:	5e                   	pop    %esi
80101cc7:	5d                   	pop    %ebp
80101cc8:	c3                   	ret    
    panic("idestart");
80101cc9:	83 ec 0c             	sub    $0xc,%esp
80101ccc:	68 0b 6c 10 80       	push   $0x80106c0b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 14 6c 10 80       	push   $0x80106c14
80101cde:	e8 65 e6 ff ff       	call   80100348 <panic>
80101ce3:	b8 30 00 00 00       	mov    $0x30,%eax
80101ce8:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ced:	ee                   	out    %al,(%dx)
    outsl(0x1f0, b->data, BSIZE/4);
80101cee:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101cf1:	b9 80 00 00 00       	mov    $0x80,%ecx
80101cf6:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101cfb:	fc                   	cld    
80101cfc:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80101cfe:	eb c2                	jmp    80101cc2 <idestart+0x7f>

80101d00 <ideinit>:
{
80101d00:	55                   	push   %ebp
80101d01:	89 e5                	mov    %esp,%ebp
80101d03:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101d06:	68 26 6c 10 80       	push   $0x80106c26
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 b1 22 00 00       	call   80103fc6 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 00 2d 11 80       	mov    0x80112d00,%eax
80101d1d:	83 e8 01             	sub    $0x1,%eax
80101d20:	50                   	push   %eax
80101d21:	6a 0e                	push   $0xe
80101d23:	e8 56 02 00 00       	call   80101f7e <ioapicenable>
  idewait(0);
80101d28:	b8 00 00 00 00       	mov    $0x0,%eax
80101d2d:	e8 df fe ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d32:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101d37:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d3c:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101d3d:	83 c4 10             	add    $0x10,%esp
80101d40:	b9 00 00 00 00       	mov    $0x0,%ecx
80101d45:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101d4b:	7f 19                	jg     80101d66 <ideinit+0x66>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101d4d:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d52:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101d53:	84 c0                	test   %al,%al
80101d55:	75 05                	jne    80101d5c <ideinit+0x5c>
  for(i=0; i<1000; i++){
80101d57:	83 c1 01             	add    $0x1,%ecx
80101d5a:	eb e9                	jmp    80101d45 <ideinit+0x45>
      havedisk1 = 1;
80101d5c:	c7 05 60 a5 10 80 01 	movl   $0x1,0x8010a560
80101d63:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d66:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101d6b:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d70:	ee                   	out    %al,(%dx)
}
80101d71:	c9                   	leave  
80101d72:	c3                   	ret    

80101d73 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101d73:	55                   	push   %ebp
80101d74:	89 e5                	mov    %esp,%ebp
80101d76:	57                   	push   %edi
80101d77:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101d78:	83 ec 0c             	sub    $0xc,%esp
80101d7b:	68 80 a5 10 80       	push   $0x8010a580
80101d80:	e8 7d 23 00 00       	call   80104102 <acquire>

  if((b = idequeue) == 0){
80101d85:	8b 1d 64 a5 10 80    	mov    0x8010a564,%ebx
80101d8b:	83 c4 10             	add    $0x10,%esp
80101d8e:	85 db                	test   %ebx,%ebx
80101d90:	74 48                	je     80101dda <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d92:	8b 43 58             	mov    0x58(%ebx),%eax
80101d95:	a3 64 a5 10 80       	mov    %eax,0x8010a564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101d9a:	f6 03 04             	testb  $0x4,(%ebx)
80101d9d:	74 4d                	je     80101dec <ideintr+0x79>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101d9f:	8b 03                	mov    (%ebx),%eax
80101da1:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101da4:	83 e0 fb             	and    $0xfffffffb,%eax
80101da7:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101da9:	83 ec 0c             	sub    $0xc,%esp
80101dac:	53                   	push   %ebx
80101dad:	e8 64 19 00 00       	call   80103716 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101db2:	a1 64 a5 10 80       	mov    0x8010a564,%eax
80101db7:	83 c4 10             	add    $0x10,%esp
80101dba:	85 c0                	test   %eax,%eax
80101dbc:	74 05                	je     80101dc3 <ideintr+0x50>
    idestart(idequeue);
80101dbe:	e8 80 fe ff ff       	call   80101c43 <idestart>

  release(&idelock);
80101dc3:	83 ec 0c             	sub    $0xc,%esp
80101dc6:	68 80 a5 10 80       	push   $0x8010a580
80101dcb:	e8 97 23 00 00       	call   80104167 <release>
80101dd0:	83 c4 10             	add    $0x10,%esp
}
80101dd3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101dd6:	5b                   	pop    %ebx
80101dd7:	5f                   	pop    %edi
80101dd8:	5d                   	pop    %ebp
80101dd9:	c3                   	ret    
    release(&idelock);
80101dda:	83 ec 0c             	sub    $0xc,%esp
80101ddd:	68 80 a5 10 80       	push   $0x8010a580
80101de2:	e8 80 23 00 00       	call   80104167 <release>
    return;
80101de7:	83 c4 10             	add    $0x10,%esp
80101dea:	eb e7                	jmp    80101dd3 <ideintr+0x60>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101dec:	b8 01 00 00 00       	mov    $0x1,%eax
80101df1:	e8 1b fe ff ff       	call   80101c11 <idewait>
80101df6:	85 c0                	test   %eax,%eax
80101df8:	78 a5                	js     80101d9f <ideintr+0x2c>
    insl(0x1f0, b->data, BSIZE/4);
80101dfa:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101dfd:	b9 80 00 00 00       	mov    $0x80,%ecx
80101e02:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101e07:	fc                   	cld    
80101e08:	f3 6d                	rep insl (%dx),%es:(%edi)
80101e0a:	eb 93                	jmp    80101d9f <ideintr+0x2c>

80101e0c <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101e0c:	55                   	push   %ebp
80101e0d:	89 e5                	mov    %esp,%ebp
80101e0f:	53                   	push   %ebx
80101e10:	83 ec 10             	sub    $0x10,%esp
80101e13:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101e16:	8d 43 0c             	lea    0xc(%ebx),%eax
80101e19:	50                   	push   %eax
80101e1a:	e8 59 21 00 00       	call   80103f78 <holdingsleep>
80101e1f:	83 c4 10             	add    $0x10,%esp
80101e22:	85 c0                	test   %eax,%eax
80101e24:	74 37                	je     80101e5d <iderw+0x51>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101e26:	8b 03                	mov    (%ebx),%eax
80101e28:	83 e0 06             	and    $0x6,%eax
80101e2b:	83 f8 02             	cmp    $0x2,%eax
80101e2e:	74 3a                	je     80101e6a <iderw+0x5e>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101e30:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101e34:	74 09                	je     80101e3f <iderw+0x33>
80101e36:	83 3d 60 a5 10 80 00 	cmpl   $0x0,0x8010a560
80101e3d:	74 38                	je     80101e77 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e3f:	83 ec 0c             	sub    $0xc,%esp
80101e42:	68 80 a5 10 80       	push   $0x8010a580
80101e47:	e8 b6 22 00 00       	call   80104102 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 2a 6c 10 80       	push   $0x80106c2a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 40 6c 10 80       	push   $0x80106c40
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 55 6c 10 80       	push   $0x80106c55
80101e7f:	e8 c4 e4 ff ff       	call   80100348 <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e84:	8d 50 58             	lea    0x58(%eax),%edx
80101e87:	8b 02                	mov    (%edx),%eax
80101e89:	85 c0                	test   %eax,%eax
80101e8b:	75 f7                	jne    80101e84 <iderw+0x78>
    ;
  *pp = b;
80101e8d:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101e8f:	39 1d 64 a5 10 80    	cmp    %ebx,0x8010a564
80101e95:	75 1a                	jne    80101eb1 <iderw+0xa5>
    idestart(b);
80101e97:	89 d8                	mov    %ebx,%eax
80101e99:	e8 a5 fd ff ff       	call   80101c43 <idestart>
80101e9e:	eb 11                	jmp    80101eb1 <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101ea0:	83 ec 08             	sub    $0x8,%esp
80101ea3:	68 80 a5 10 80       	push   $0x8010a580
80101ea8:	53                   	push   %ebx
80101ea9:	e8 00 17 00 00       	call   801035ae <sleep>
80101eae:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101eb1:	8b 03                	mov    (%ebx),%eax
80101eb3:	83 e0 06             	and    $0x6,%eax
80101eb6:	83 f8 02             	cmp    $0x2,%eax
80101eb9:	75 e5                	jne    80101ea0 <iderw+0x94>
  }


  release(&idelock);
80101ebb:	83 ec 0c             	sub    $0xc,%esp
80101ebe:	68 80 a5 10 80       	push   $0x8010a580
80101ec3:	e8 9f 22 00 00       	call   80104167 <release>
}
80101ec8:	83 c4 10             	add    $0x10,%esp
80101ecb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101ece:	c9                   	leave  
80101ecf:	c3                   	ret    

80101ed0 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80101ed0:	55                   	push   %ebp
80101ed1:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ed3:	8b 15 34 26 11 80    	mov    0x80112634,%edx
80101ed9:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101edb:	a1 34 26 11 80       	mov    0x80112634,%eax
80101ee0:	8b 40 10             	mov    0x10(%eax),%eax
}
80101ee3:	5d                   	pop    %ebp
80101ee4:	c3                   	ret    

80101ee5 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80101ee5:	55                   	push   %ebp
80101ee6:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ee8:	8b 0d 34 26 11 80    	mov    0x80112634,%ecx
80101eee:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101ef0:	a1 34 26 11 80       	mov    0x80112634,%eax
80101ef5:	89 50 10             	mov    %edx,0x10(%eax)
}
80101ef8:	5d                   	pop    %ebp
80101ef9:	c3                   	ret    

80101efa <ioapicinit>:

void
ioapicinit(void)
{
80101efa:	55                   	push   %ebp
80101efb:	89 e5                	mov    %esp,%ebp
80101efd:	57                   	push   %edi
80101efe:	56                   	push   %esi
80101eff:	53                   	push   %ebx
80101f00:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101f03:	c7 05 34 26 11 80 00 	movl   $0xfec00000,0x80112634
80101f0a:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101f0d:	b8 01 00 00 00       	mov    $0x1,%eax
80101f12:	e8 b9 ff ff ff       	call   80101ed0 <ioapicread>
80101f17:	c1 e8 10             	shr    $0x10,%eax
80101f1a:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101f1d:	b8 00 00 00 00       	mov    $0x0,%eax
80101f22:	e8 a9 ff ff ff       	call   80101ed0 <ioapicread>
80101f27:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101f2a:	0f b6 15 60 27 11 80 	movzbl 0x80112760,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 74 6c 10 80       	push   $0x80106c74
80101f44:	e8 c2 e6 ff ff       	call   8010060b <cprintf>
80101f49:	83 c4 10             	add    $0x10,%esp
80101f4c:	eb e7                	jmp    80101f35 <ioapicinit+0x3b>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101f4e:	8d 53 20             	lea    0x20(%ebx),%edx
80101f51:	81 ca 00 00 01 00    	or     $0x10000,%edx
80101f57:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80101f5b:	89 f0                	mov    %esi,%eax
80101f5d:	e8 83 ff ff ff       	call   80101ee5 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80101f62:	8d 46 01             	lea    0x1(%esi),%eax
80101f65:	ba 00 00 00 00       	mov    $0x0,%edx
80101f6a:	e8 76 ff ff ff       	call   80101ee5 <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80101f6f:	83 c3 01             	add    $0x1,%ebx
80101f72:	39 fb                	cmp    %edi,%ebx
80101f74:	7e d8                	jle    80101f4e <ioapicinit+0x54>
  }
}
80101f76:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101f79:	5b                   	pop    %ebx
80101f7a:	5e                   	pop    %esi
80101f7b:	5f                   	pop    %edi
80101f7c:	5d                   	pop    %ebp
80101f7d:	c3                   	ret    

80101f7e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80101f7e:	55                   	push   %ebp
80101f7f:	89 e5                	mov    %esp,%ebp
80101f81:	53                   	push   %ebx
80101f82:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80101f85:	8d 50 20             	lea    0x20(%eax),%edx
80101f88:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
80101f8c:	89 d8                	mov    %ebx,%eax
80101f8e:	e8 52 ff ff ff       	call   80101ee5 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80101f93:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f96:	c1 e2 18             	shl    $0x18,%edx
80101f99:	8d 43 01             	lea    0x1(%ebx),%eax
80101f9c:	e8 44 ff ff ff       	call   80101ee5 <ioapicwrite>
}
80101fa1:	5b                   	pop    %ebx
80101fa2:	5d                   	pop    %ebp
80101fa3:	c3                   	ret    

80101fa4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80101fa4:	55                   	push   %ebp
80101fa5:	89 e5                	mov    %esp,%ebp
80101fa7:	53                   	push   %ebx
80101fa8:	83 ec 04             	sub    $0x4,%esp
80101fab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fae:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fb4:	75 4c                	jne    80102002 <kfree+0x5e>
80101fb6:	81 fb c8 6b 11 80    	cmp    $0x80116bc8,%ebx
80101fbc:	72 44                	jb     80102002 <kfree+0x5e>
80101fbe:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fc4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fc9:	77 37                	ja     80102002 <kfree+0x5e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fcb:	83 ec 04             	sub    $0x4,%esp
80101fce:	68 00 10 00 00       	push   $0x1000
80101fd3:	6a 01                	push   $0x1
80101fd5:	53                   	push   %ebx
80101fd6:	e8 d3 21 00 00       	call   801041ae <memset>

  if(kmem.use_lock)
80101fdb:	83 c4 10             	add    $0x10,%esp
80101fde:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80101fe5:	75 28                	jne    8010200f <kfree+0x6b>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
80101fe7:	a1 78 26 11 80       	mov    0x80112678,%eax
80101fec:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80101fee:	89 1d 78 26 11 80    	mov    %ebx,0x80112678
  if(kmem.use_lock)
80101ff4:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80101ffb:	75 24                	jne    80102021 <kfree+0x7d>
    release(&kmem.lock);
}
80101ffd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102000:	c9                   	leave  
80102001:	c3                   	ret    
    panic("kfree");
80102002:	83 ec 0c             	sub    $0xc,%esp
80102005:	68 a6 6c 10 80       	push   $0x80106ca6
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 40 26 11 80       	push   $0x80112640
80102017:	e8 e6 20 00 00       	call   80104102 <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 40 26 11 80       	push   $0x80112640
80102029:	e8 39 21 00 00       	call   80104167 <release>
8010202e:	83 c4 10             	add    $0x10,%esp
}
80102031:	eb ca                	jmp    80101ffd <kfree+0x59>

80102033 <freerange>:
{
80102033:	55                   	push   %ebp
80102034:	89 e5                	mov    %esp,%ebp
80102036:	56                   	push   %esi
80102037:	53                   	push   %ebx
80102038:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
8010203b:	8b 45 08             	mov    0x8(%ebp),%eax
8010203e:	05 ff 0f 00 00       	add    $0xfff,%eax
80102043:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102048:	eb 0e                	jmp    80102058 <freerange+0x25>
    kfree(p);
8010204a:	83 ec 0c             	sub    $0xc,%esp
8010204d:	50                   	push   %eax
8010204e:	e8 51 ff ff ff       	call   80101fa4 <kfree>
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102053:	83 c4 10             	add    $0x10,%esp
80102056:	89 f0                	mov    %esi,%eax
80102058:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010205e:	39 de                	cmp    %ebx,%esi
80102060:	76 e8                	jbe    8010204a <freerange+0x17>
}
80102062:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102065:	5b                   	pop    %ebx
80102066:	5e                   	pop    %esi
80102067:	5d                   	pop    %ebp
80102068:	c3                   	ret    

80102069 <kinit1>:
{
80102069:	55                   	push   %ebp
8010206a:	89 e5                	mov    %esp,%ebp
8010206c:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
8010206f:	68 ac 6c 10 80       	push   $0x80106cac
80102074:	68 40 26 11 80       	push   $0x80112640
80102079:	e8 48 1f 00 00       	call   80103fc6 <initlock>
  kmem.use_lock = 0;
8010207e:	c7 05 74 26 11 80 00 	movl   $0x0,0x80112674
80102085:	00 00 00 
  freerange(vstart, vend);
80102088:	83 c4 08             	add    $0x8,%esp
8010208b:	ff 75 0c             	pushl  0xc(%ebp)
8010208e:	ff 75 08             	pushl  0x8(%ebp)
80102091:	e8 9d ff ff ff       	call   80102033 <freerange>
}
80102096:	83 c4 10             	add    $0x10,%esp
80102099:	c9                   	leave  
8010209a:	c3                   	ret    

8010209b <kinit2>:
{
8010209b:	55                   	push   %ebp
8010209c:	89 e5                	mov    %esp,%ebp
8010209e:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
801020a1:	ff 75 0c             	pushl  0xc(%ebp)
801020a4:	ff 75 08             	pushl  0x8(%ebp)
801020a7:	e8 87 ff ff ff       	call   80102033 <freerange>
  kmem.use_lock = 1;
801020ac:	c7 05 74 26 11 80 01 	movl   $0x1,0x80112674
801020b3:	00 00 00 
}
801020b6:	83 c4 10             	add    $0x10,%esp
801020b9:	c9                   	leave  
801020ba:	c3                   	ret    

801020bb <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801020bb:	55                   	push   %ebp
801020bc:	89 e5                	mov    %esp,%ebp
801020be:	53                   	push   %ebx
801020bf:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
801020c2:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020c9:	75 21                	jne    801020ec <kalloc+0x31>
    acquire(&kmem.lock);
  r = kmem.freelist;
801020cb:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx
  if(r)
801020d1:	85 db                	test   %ebx,%ebx
801020d3:	74 07                	je     801020dc <kalloc+0x21>
    kmem.freelist = r->next;
801020d5:	8b 03                	mov    (%ebx),%eax
801020d7:	a3 78 26 11 80       	mov    %eax,0x80112678
  if(kmem.use_lock)
801020dc:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020e3:	75 19                	jne    801020fe <kalloc+0x43>
    release(&kmem.lock);
  return (char*)r;
}
801020e5:	89 d8                	mov    %ebx,%eax
801020e7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020ea:	c9                   	leave  
801020eb:	c3                   	ret    
    acquire(&kmem.lock);
801020ec:	83 ec 0c             	sub    $0xc,%esp
801020ef:	68 40 26 11 80       	push   $0x80112640
801020f4:	e8 09 20 00 00       	call   80104102 <acquire>
801020f9:	83 c4 10             	add    $0x10,%esp
801020fc:	eb cd                	jmp    801020cb <kalloc+0x10>
    release(&kmem.lock);
801020fe:	83 ec 0c             	sub    $0xc,%esp
80102101:	68 40 26 11 80       	push   $0x80112640
80102106:	e8 5c 20 00 00       	call   80104167 <release>
8010210b:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
8010210e:	eb d5                	jmp    801020e5 <kalloc+0x2a>

80102110 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102110:	55                   	push   %ebp
80102111:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102113:	ba 64 00 00 00       	mov    $0x64,%edx
80102118:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
80102119:	a8 01                	test   $0x1,%al
8010211b:	0f 84 b5 00 00 00    	je     801021d6 <kbdgetc+0xc6>
80102121:	ba 60 00 00 00       	mov    $0x60,%edx
80102126:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102127:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
8010212a:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
80102130:	74 5c                	je     8010218e <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102132:	84 c0                	test   %al,%al
80102134:	78 66                	js     8010219c <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102136:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
8010213c:	f6 c1 40             	test   $0x40,%cl
8010213f:	74 0f                	je     80102150 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102141:	83 c8 80             	or     $0xffffff80,%eax
80102144:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102147:	83 e1 bf             	and    $0xffffffbf,%ecx
8010214a:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
80102150:	0f b6 8a e0 6d 10 80 	movzbl -0x7fef9220(%edx),%ecx
80102157:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
8010215d:	0f b6 82 e0 6c 10 80 	movzbl -0x7fef9320(%edx),%eax
80102164:	31 c1                	xor    %eax,%ecx
80102166:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
8010216c:	89 c8                	mov    %ecx,%eax
8010216e:	83 e0 03             	and    $0x3,%eax
80102171:	8b 04 85 c0 6c 10 80 	mov    -0x7fef9340(,%eax,4),%eax
80102178:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
8010217c:	f6 c1 08             	test   $0x8,%cl
8010217f:	74 19                	je     8010219a <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
80102181:	8d 50 9f             	lea    -0x61(%eax),%edx
80102184:	83 fa 19             	cmp    $0x19,%edx
80102187:	77 40                	ja     801021c9 <kbdgetc+0xb9>
      c += 'A' - 'a';
80102189:	83 e8 20             	sub    $0x20,%eax
8010218c:	eb 0c                	jmp    8010219a <kbdgetc+0x8a>
    shift |= E0ESC;
8010218e:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
80102195:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
8010219a:	5d                   	pop    %ebp
8010219b:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
8010219c:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
801021a2:	f6 c1 40             	test   $0x40,%cl
801021a5:	75 05                	jne    801021ac <kbdgetc+0x9c>
801021a7:	89 c2                	mov    %eax,%edx
801021a9:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801021ac:	0f b6 82 e0 6d 10 80 	movzbl -0x7fef9220(%edx),%eax
801021b3:	83 c8 40             	or     $0x40,%eax
801021b6:	0f b6 c0             	movzbl %al,%eax
801021b9:	f7 d0                	not    %eax
801021bb:	21 c8                	and    %ecx,%eax
801021bd:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
801021c2:	b8 00 00 00 00       	mov    $0x0,%eax
801021c7:	eb d1                	jmp    8010219a <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
801021c9:	8d 50 bf             	lea    -0x41(%eax),%edx
801021cc:	83 fa 19             	cmp    $0x19,%edx
801021cf:	77 c9                	ja     8010219a <kbdgetc+0x8a>
      c += 'a' - 'A';
801021d1:	83 c0 20             	add    $0x20,%eax
  return c;
801021d4:	eb c4                	jmp    8010219a <kbdgetc+0x8a>
    return -1;
801021d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021db:	eb bd                	jmp    8010219a <kbdgetc+0x8a>

801021dd <kbdintr>:

void
kbdintr(void)
{
801021dd:	55                   	push   %ebp
801021de:	89 e5                	mov    %esp,%ebp
801021e0:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801021e3:	68 10 21 10 80       	push   $0x80102110
801021e8:	e8 51 e5 ff ff       	call   8010073e <consoleintr>
}
801021ed:	83 c4 10             	add    $0x10,%esp
801021f0:	c9                   	leave  
801021f1:	c3                   	ret    

801021f2 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801021f2:	55                   	push   %ebp
801021f3:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801021f5:	8b 0d 7c 26 11 80    	mov    0x8011267c,%ecx
801021fb:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801021fe:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
80102200:	a1 7c 26 11 80       	mov    0x8011267c,%eax
80102205:	8b 40 20             	mov    0x20(%eax),%eax
}
80102208:	5d                   	pop    %ebp
80102209:	c3                   	ret    

8010220a <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
8010220a:	55                   	push   %ebp
8010220b:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010220d:	ba 70 00 00 00       	mov    $0x70,%edx
80102212:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102213:	ba 71 00 00 00       	mov    $0x71,%edx
80102218:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
80102219:	0f b6 c0             	movzbl %al,%eax
}
8010221c:	5d                   	pop    %ebp
8010221d:	c3                   	ret    

8010221e <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
8010221e:	55                   	push   %ebp
8010221f:	89 e5                	mov    %esp,%ebp
80102221:	53                   	push   %ebx
80102222:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
80102224:	b8 00 00 00 00       	mov    $0x0,%eax
80102229:	e8 dc ff ff ff       	call   8010220a <cmos_read>
8010222e:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102230:	b8 02 00 00 00       	mov    $0x2,%eax
80102235:	e8 d0 ff ff ff       	call   8010220a <cmos_read>
8010223a:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010223d:	b8 04 00 00 00       	mov    $0x4,%eax
80102242:	e8 c3 ff ff ff       	call   8010220a <cmos_read>
80102247:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
8010224a:	b8 07 00 00 00       	mov    $0x7,%eax
8010224f:	e8 b6 ff ff ff       	call   8010220a <cmos_read>
80102254:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102257:	b8 08 00 00 00       	mov    $0x8,%eax
8010225c:	e8 a9 ff ff ff       	call   8010220a <cmos_read>
80102261:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102264:	b8 09 00 00 00       	mov    $0x9,%eax
80102269:	e8 9c ff ff ff       	call   8010220a <cmos_read>
8010226e:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102271:	5b                   	pop    %ebx
80102272:	5d                   	pop    %ebp
80102273:	c3                   	ret    

80102274 <lapicinit>:
  if(!lapic)
80102274:	83 3d 7c 26 11 80 00 	cmpl   $0x0,0x8011267c
8010227b:	0f 84 fb 00 00 00    	je     8010237c <lapicinit+0x108>
{
80102281:	55                   	push   %ebp
80102282:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102284:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102289:	b8 3c 00 00 00       	mov    $0x3c,%eax
8010228e:	e8 5f ff ff ff       	call   801021f2 <lapicw>
  lapicw(TDCR, X1);
80102293:	ba 0b 00 00 00       	mov    $0xb,%edx
80102298:	b8 f8 00 00 00       	mov    $0xf8,%eax
8010229d:	e8 50 ff ff ff       	call   801021f2 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801022a2:	ba 20 00 02 00       	mov    $0x20020,%edx
801022a7:	b8 c8 00 00 00       	mov    $0xc8,%eax
801022ac:	e8 41 ff ff ff       	call   801021f2 <lapicw>
  lapicw(TICR, 10000000);
801022b1:	ba 80 96 98 00       	mov    $0x989680,%edx
801022b6:	b8 e0 00 00 00       	mov    $0xe0,%eax
801022bb:	e8 32 ff ff ff       	call   801021f2 <lapicw>
  lapicw(LINT0, MASKED);
801022c0:	ba 00 00 01 00       	mov    $0x10000,%edx
801022c5:	b8 d4 00 00 00       	mov    $0xd4,%eax
801022ca:	e8 23 ff ff ff       	call   801021f2 <lapicw>
  lapicw(LINT1, MASKED);
801022cf:	ba 00 00 01 00       	mov    $0x10000,%edx
801022d4:	b8 d8 00 00 00       	mov    $0xd8,%eax
801022d9:	e8 14 ff ff ff       	call   801021f2 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801022de:	a1 7c 26 11 80       	mov    0x8011267c,%eax
801022e3:	8b 40 30             	mov    0x30(%eax),%eax
801022e6:	c1 e8 10             	shr    $0x10,%eax
801022e9:	3c 03                	cmp    $0x3,%al
801022eb:	77 7b                	ja     80102368 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801022ed:	ba 33 00 00 00       	mov    $0x33,%edx
801022f2:	b8 dc 00 00 00       	mov    $0xdc,%eax
801022f7:	e8 f6 fe ff ff       	call   801021f2 <lapicw>
  lapicw(ESR, 0);
801022fc:	ba 00 00 00 00       	mov    $0x0,%edx
80102301:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102306:	e8 e7 fe ff ff       	call   801021f2 <lapicw>
  lapicw(ESR, 0);
8010230b:	ba 00 00 00 00       	mov    $0x0,%edx
80102310:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102315:	e8 d8 fe ff ff       	call   801021f2 <lapicw>
  lapicw(EOI, 0);
8010231a:	ba 00 00 00 00       	mov    $0x0,%edx
8010231f:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102324:	e8 c9 fe ff ff       	call   801021f2 <lapicw>
  lapicw(ICRHI, 0);
80102329:	ba 00 00 00 00       	mov    $0x0,%edx
8010232e:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102333:	e8 ba fe ff ff       	call   801021f2 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102338:	ba 00 85 08 00       	mov    $0x88500,%edx
8010233d:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102342:	e8 ab fe ff ff       	call   801021f2 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102347:	a1 7c 26 11 80       	mov    0x8011267c,%eax
8010234c:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
80102352:	f6 c4 10             	test   $0x10,%ah
80102355:	75 f0                	jne    80102347 <lapicinit+0xd3>
  lapicw(TPR, 0);
80102357:	ba 00 00 00 00       	mov    $0x0,%edx
8010235c:	b8 20 00 00 00       	mov    $0x20,%eax
80102361:	e8 8c fe ff ff       	call   801021f2 <lapicw>
}
80102366:	5d                   	pop    %ebp
80102367:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102368:	ba 00 00 01 00       	mov    $0x10000,%edx
8010236d:	b8 d0 00 00 00       	mov    $0xd0,%eax
80102372:	e8 7b fe ff ff       	call   801021f2 <lapicw>
80102377:	e9 71 ff ff ff       	jmp    801022ed <lapicinit+0x79>
8010237c:	f3 c3                	repz ret 

8010237e <lapicid>:
{
8010237e:	55                   	push   %ebp
8010237f:	89 e5                	mov    %esp,%ebp
  if (!lapic)
80102381:	a1 7c 26 11 80       	mov    0x8011267c,%eax
80102386:	85 c0                	test   %eax,%eax
80102388:	74 08                	je     80102392 <lapicid+0x14>
  return lapic[ID] >> 24;
8010238a:	8b 40 20             	mov    0x20(%eax),%eax
8010238d:	c1 e8 18             	shr    $0x18,%eax
}
80102390:	5d                   	pop    %ebp
80102391:	c3                   	ret    
    return 0;
80102392:	b8 00 00 00 00       	mov    $0x0,%eax
80102397:	eb f7                	jmp    80102390 <lapicid+0x12>

80102399 <lapiceoi>:
  if(lapic)
80102399:	83 3d 7c 26 11 80 00 	cmpl   $0x0,0x8011267c
801023a0:	74 14                	je     801023b6 <lapiceoi+0x1d>
{
801023a2:	55                   	push   %ebp
801023a3:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801023a5:	ba 00 00 00 00       	mov    $0x0,%edx
801023aa:	b8 2c 00 00 00       	mov    $0x2c,%eax
801023af:	e8 3e fe ff ff       	call   801021f2 <lapicw>
}
801023b4:	5d                   	pop    %ebp
801023b5:	c3                   	ret    
801023b6:	f3 c3                	repz ret 

801023b8 <microdelay>:
{
801023b8:	55                   	push   %ebp
801023b9:	89 e5                	mov    %esp,%ebp
}
801023bb:	5d                   	pop    %ebp
801023bc:	c3                   	ret    

801023bd <lapicstartap>:
{
801023bd:	55                   	push   %ebp
801023be:	89 e5                	mov    %esp,%ebp
801023c0:	57                   	push   %edi
801023c1:	56                   	push   %esi
801023c2:	53                   	push   %ebx
801023c3:	8b 75 08             	mov    0x8(%ebp),%esi
801023c6:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801023c9:	b8 0f 00 00 00       	mov    $0xf,%eax
801023ce:	ba 70 00 00 00       	mov    $0x70,%edx
801023d3:	ee                   	out    %al,(%dx)
801023d4:	b8 0a 00 00 00       	mov    $0xa,%eax
801023d9:	ba 71 00 00 00       	mov    $0x71,%edx
801023de:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801023df:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801023e6:	00 00 
  wrv[1] = addr >> 4;
801023e8:	89 f8                	mov    %edi,%eax
801023ea:	c1 e8 04             	shr    $0x4,%eax
801023ed:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801023f3:	c1 e6 18             	shl    $0x18,%esi
801023f6:	89 f2                	mov    %esi,%edx
801023f8:	b8 c4 00 00 00       	mov    $0xc4,%eax
801023fd:	e8 f0 fd ff ff       	call   801021f2 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102402:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102407:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010240c:	e8 e1 fd ff ff       	call   801021f2 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102411:	ba 00 85 00 00       	mov    $0x8500,%edx
80102416:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010241b:	e8 d2 fd ff ff       	call   801021f2 <lapicw>
  for(i = 0; i < 2; i++){
80102420:	bb 00 00 00 00       	mov    $0x0,%ebx
80102425:	eb 21                	jmp    80102448 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102427:	89 f2                	mov    %esi,%edx
80102429:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010242e:	e8 bf fd ff ff       	call   801021f2 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102433:	89 fa                	mov    %edi,%edx
80102435:	c1 ea 0c             	shr    $0xc,%edx
80102438:	80 ce 06             	or     $0x6,%dh
8010243b:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102440:	e8 ad fd ff ff       	call   801021f2 <lapicw>
  for(i = 0; i < 2; i++){
80102445:	83 c3 01             	add    $0x1,%ebx
80102448:	83 fb 01             	cmp    $0x1,%ebx
8010244b:	7e da                	jle    80102427 <lapicstartap+0x6a>
}
8010244d:	5b                   	pop    %ebx
8010244e:	5e                   	pop    %esi
8010244f:	5f                   	pop    %edi
80102450:	5d                   	pop    %ebp
80102451:	c3                   	ret    

80102452 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80102452:	55                   	push   %ebp
80102453:	89 e5                	mov    %esp,%ebp
80102455:	57                   	push   %edi
80102456:	56                   	push   %esi
80102457:	53                   	push   %ebx
80102458:	83 ec 3c             	sub    $0x3c,%esp
8010245b:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010245e:	b8 0b 00 00 00       	mov    $0xb,%eax
80102463:	e8 a2 fd ff ff       	call   8010220a <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102468:	83 e0 04             	and    $0x4,%eax
8010246b:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
8010246d:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102470:	e8 a9 fd ff ff       	call   8010221e <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102475:	b8 0a 00 00 00       	mov    $0xa,%eax
8010247a:	e8 8b fd ff ff       	call   8010220a <cmos_read>
8010247f:	a8 80                	test   $0x80,%al
80102481:	75 ea                	jne    8010246d <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
80102483:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102486:	89 d8                	mov    %ebx,%eax
80102488:	e8 91 fd ff ff       	call   8010221e <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
8010248d:	83 ec 04             	sub    $0x4,%esp
80102490:	6a 18                	push   $0x18
80102492:	53                   	push   %ebx
80102493:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102496:	50                   	push   %eax
80102497:	e8 58 1d 00 00       	call   801041f4 <memcmp>
8010249c:	83 c4 10             	add    $0x10,%esp
8010249f:	85 c0                	test   %eax,%eax
801024a1:	75 ca                	jne    8010246d <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801024a3:	85 ff                	test   %edi,%edi
801024a5:	0f 85 84 00 00 00    	jne    8010252f <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801024ab:	8b 55 d0             	mov    -0x30(%ebp),%edx
801024ae:	89 d0                	mov    %edx,%eax
801024b0:	c1 e8 04             	shr    $0x4,%eax
801024b3:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801024b6:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801024b9:	83 e2 0f             	and    $0xf,%edx
801024bc:	01 d0                	add    %edx,%eax
801024be:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801024c1:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801024c4:	89 d0                	mov    %edx,%eax
801024c6:	c1 e8 04             	shr    $0x4,%eax
801024c9:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801024cc:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801024cf:	83 e2 0f             	and    $0xf,%edx
801024d2:	01 d0                	add    %edx,%eax
801024d4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801024d7:	8b 55 d8             	mov    -0x28(%ebp),%edx
801024da:	89 d0                	mov    %edx,%eax
801024dc:	c1 e8 04             	shr    $0x4,%eax
801024df:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801024e2:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801024e5:	83 e2 0f             	and    $0xf,%edx
801024e8:	01 d0                	add    %edx,%eax
801024ea:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
801024ed:	8b 55 dc             	mov    -0x24(%ebp),%edx
801024f0:	89 d0                	mov    %edx,%eax
801024f2:	c1 e8 04             	shr    $0x4,%eax
801024f5:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801024f8:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801024fb:	83 e2 0f             	and    $0xf,%edx
801024fe:	01 d0                	add    %edx,%eax
80102500:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102503:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102506:	89 d0                	mov    %edx,%eax
80102508:	c1 e8 04             	shr    $0x4,%eax
8010250b:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010250e:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102511:	83 e2 0f             	and    $0xf,%edx
80102514:	01 d0                	add    %edx,%eax
80102516:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
80102519:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010251c:	89 d0                	mov    %edx,%eax
8010251e:	c1 e8 04             	shr    $0x4,%eax
80102521:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102524:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102527:	83 e2 0f             	and    $0xf,%edx
8010252a:	01 d0                	add    %edx,%eax
8010252c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010252f:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102532:	89 06                	mov    %eax,(%esi)
80102534:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102537:	89 46 04             	mov    %eax,0x4(%esi)
8010253a:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010253d:	89 46 08             	mov    %eax,0x8(%esi)
80102540:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102543:	89 46 0c             	mov    %eax,0xc(%esi)
80102546:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102549:	89 46 10             	mov    %eax,0x10(%esi)
8010254c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010254f:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
80102552:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102559:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010255c:	5b                   	pop    %ebx
8010255d:	5e                   	pop    %esi
8010255e:	5f                   	pop    %edi
8010255f:	5d                   	pop    %ebp
80102560:	c3                   	ret    

80102561 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80102561:	55                   	push   %ebp
80102562:	89 e5                	mov    %esp,%ebp
80102564:	53                   	push   %ebx
80102565:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102568:	ff 35 b4 26 11 80    	pushl  0x801126b4
8010256e:	ff 35 c4 26 11 80    	pushl  0x801126c4
80102574:	e8 f3 db ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102579:	8b 58 5c             	mov    0x5c(%eax),%ebx
8010257c:	89 1d c8 26 11 80    	mov    %ebx,0x801126c8
  for (i = 0; i < log.lh.n; i++) {
80102582:	83 c4 10             	add    $0x10,%esp
80102585:	ba 00 00 00 00       	mov    $0x0,%edx
8010258a:	eb 0e                	jmp    8010259a <read_head+0x39>
    log.lh.block[i] = lh->block[i];
8010258c:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
80102590:	89 0c 95 cc 26 11 80 	mov    %ecx,-0x7feed934(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102597:	83 c2 01             	add    $0x1,%edx
8010259a:	39 d3                	cmp    %edx,%ebx
8010259c:	7f ee                	jg     8010258c <read_head+0x2b>
  }
  brelse(buf);
8010259e:	83 ec 0c             	sub    $0xc,%esp
801025a1:	50                   	push   %eax
801025a2:	e8 2e dc ff ff       	call   801001d5 <brelse>
}
801025a7:	83 c4 10             	add    $0x10,%esp
801025aa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801025ad:	c9                   	leave  
801025ae:	c3                   	ret    

801025af <install_trans>:
{
801025af:	55                   	push   %ebp
801025b0:	89 e5                	mov    %esp,%ebp
801025b2:	57                   	push   %edi
801025b3:	56                   	push   %esi
801025b4:	53                   	push   %ebx
801025b5:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801025b8:	bb 00 00 00 00       	mov    $0x0,%ebx
801025bd:	eb 66                	jmp    80102625 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801025bf:	89 d8                	mov    %ebx,%eax
801025c1:	03 05 b4 26 11 80    	add    0x801126b4,%eax
801025c7:	83 c0 01             	add    $0x1,%eax
801025ca:	83 ec 08             	sub    $0x8,%esp
801025cd:	50                   	push   %eax
801025ce:	ff 35 c4 26 11 80    	pushl  0x801126c4
801025d4:	e8 93 db ff ff       	call   8010016c <bread>
801025d9:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801025db:	83 c4 08             	add    $0x8,%esp
801025de:	ff 34 9d cc 26 11 80 	pushl  -0x7feed934(,%ebx,4)
801025e5:	ff 35 c4 26 11 80    	pushl  0x801126c4
801025eb:	e8 7c db ff ff       	call   8010016c <bread>
801025f0:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801025f2:	8d 57 5c             	lea    0x5c(%edi),%edx
801025f5:	8d 40 5c             	lea    0x5c(%eax),%eax
801025f8:	83 c4 0c             	add    $0xc,%esp
801025fb:	68 00 02 00 00       	push   $0x200
80102600:	52                   	push   %edx
80102601:	50                   	push   %eax
80102602:	e8 22 1c 00 00       	call   80104229 <memmove>
    bwrite(dbuf);  // write dst to disk
80102607:	89 34 24             	mov    %esi,(%esp)
8010260a:	e8 8b db ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
8010260f:	89 3c 24             	mov    %edi,(%esp)
80102612:	e8 be db ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102617:	89 34 24             	mov    %esi,(%esp)
8010261a:	e8 b6 db ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010261f:	83 c3 01             	add    $0x1,%ebx
80102622:	83 c4 10             	add    $0x10,%esp
80102625:	39 1d c8 26 11 80    	cmp    %ebx,0x801126c8
8010262b:	7f 92                	jg     801025bf <install_trans+0x10>
}
8010262d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102630:	5b                   	pop    %ebx
80102631:	5e                   	pop    %esi
80102632:	5f                   	pop    %edi
80102633:	5d                   	pop    %ebp
80102634:	c3                   	ret    

80102635 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102635:	55                   	push   %ebp
80102636:	89 e5                	mov    %esp,%ebp
80102638:	53                   	push   %ebx
80102639:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010263c:	ff 35 b4 26 11 80    	pushl  0x801126b4
80102642:	ff 35 c4 26 11 80    	pushl  0x801126c4
80102648:	e8 1f db ff ff       	call   8010016c <bread>
8010264d:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
8010264f:	8b 0d c8 26 11 80    	mov    0x801126c8,%ecx
80102655:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102658:	83 c4 10             	add    $0x10,%esp
8010265b:	b8 00 00 00 00       	mov    $0x0,%eax
80102660:	eb 0e                	jmp    80102670 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
80102662:	8b 14 85 cc 26 11 80 	mov    -0x7feed934(,%eax,4),%edx
80102669:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
8010266d:	83 c0 01             	add    $0x1,%eax
80102670:	39 c1                	cmp    %eax,%ecx
80102672:	7f ee                	jg     80102662 <write_head+0x2d>
  }
  bwrite(buf);
80102674:	83 ec 0c             	sub    $0xc,%esp
80102677:	53                   	push   %ebx
80102678:	e8 1d db ff ff       	call   8010019a <bwrite>
  brelse(buf);
8010267d:	89 1c 24             	mov    %ebx,(%esp)
80102680:	e8 50 db ff ff       	call   801001d5 <brelse>
}
80102685:	83 c4 10             	add    $0x10,%esp
80102688:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010268b:	c9                   	leave  
8010268c:	c3                   	ret    

8010268d <recover_from_log>:

static void
recover_from_log(void)
{
8010268d:	55                   	push   %ebp
8010268e:	89 e5                	mov    %esp,%ebp
80102690:	83 ec 08             	sub    $0x8,%esp
  read_head();
80102693:	e8 c9 fe ff ff       	call   80102561 <read_head>
  install_trans(); // if committed, copy from log to disk
80102698:	e8 12 ff ff ff       	call   801025af <install_trans>
  log.lh.n = 0;
8010269d:	c7 05 c8 26 11 80 00 	movl   $0x0,0x801126c8
801026a4:	00 00 00 
  write_head(); // clear the log
801026a7:	e8 89 ff ff ff       	call   80102635 <write_head>
}
801026ac:	c9                   	leave  
801026ad:	c3                   	ret    

801026ae <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801026ae:	55                   	push   %ebp
801026af:	89 e5                	mov    %esp,%ebp
801026b1:	57                   	push   %edi
801026b2:	56                   	push   %esi
801026b3:	53                   	push   %ebx
801026b4:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801026b7:	bb 00 00 00 00       	mov    $0x0,%ebx
801026bc:	eb 66                	jmp    80102724 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801026be:	89 d8                	mov    %ebx,%eax
801026c0:	03 05 b4 26 11 80    	add    0x801126b4,%eax
801026c6:	83 c0 01             	add    $0x1,%eax
801026c9:	83 ec 08             	sub    $0x8,%esp
801026cc:	50                   	push   %eax
801026cd:	ff 35 c4 26 11 80    	pushl  0x801126c4
801026d3:	e8 94 da ff ff       	call   8010016c <bread>
801026d8:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801026da:	83 c4 08             	add    $0x8,%esp
801026dd:	ff 34 9d cc 26 11 80 	pushl  -0x7feed934(,%ebx,4)
801026e4:	ff 35 c4 26 11 80    	pushl  0x801126c4
801026ea:	e8 7d da ff ff       	call   8010016c <bread>
801026ef:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
801026f1:	8d 50 5c             	lea    0x5c(%eax),%edx
801026f4:	8d 46 5c             	lea    0x5c(%esi),%eax
801026f7:	83 c4 0c             	add    $0xc,%esp
801026fa:	68 00 02 00 00       	push   $0x200
801026ff:	52                   	push   %edx
80102700:	50                   	push   %eax
80102701:	e8 23 1b 00 00       	call   80104229 <memmove>
    bwrite(to);  // write the log
80102706:	89 34 24             	mov    %esi,(%esp)
80102709:	e8 8c da ff ff       	call   8010019a <bwrite>
    brelse(from);
8010270e:	89 3c 24             	mov    %edi,(%esp)
80102711:	e8 bf da ff ff       	call   801001d5 <brelse>
    brelse(to);
80102716:	89 34 24             	mov    %esi,(%esp)
80102719:	e8 b7 da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010271e:	83 c3 01             	add    $0x1,%ebx
80102721:	83 c4 10             	add    $0x10,%esp
80102724:	39 1d c8 26 11 80    	cmp    %ebx,0x801126c8
8010272a:	7f 92                	jg     801026be <write_log+0x10>
  }
}
8010272c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010272f:	5b                   	pop    %ebx
80102730:	5e                   	pop    %esi
80102731:	5f                   	pop    %edi
80102732:	5d                   	pop    %ebp
80102733:	c3                   	ret    

80102734 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102734:	83 3d c8 26 11 80 00 	cmpl   $0x0,0x801126c8
8010273b:	7e 26                	jle    80102763 <commit+0x2f>
{
8010273d:	55                   	push   %ebp
8010273e:	89 e5                	mov    %esp,%ebp
80102740:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102743:	e8 66 ff ff ff       	call   801026ae <write_log>
    write_head();    // Write header to disk -- the real commit
80102748:	e8 e8 fe ff ff       	call   80102635 <write_head>
    install_trans(); // Now install writes to home locations
8010274d:	e8 5d fe ff ff       	call   801025af <install_trans>
    log.lh.n = 0;
80102752:	c7 05 c8 26 11 80 00 	movl   $0x0,0x801126c8
80102759:	00 00 00 
    write_head();    // Erase the transaction from the log
8010275c:	e8 d4 fe ff ff       	call   80102635 <write_head>
  }
}
80102761:	c9                   	leave  
80102762:	c3                   	ret    
80102763:	f3 c3                	repz ret 

80102765 <initlog>:
{
80102765:	55                   	push   %ebp
80102766:	89 e5                	mov    %esp,%ebp
80102768:	53                   	push   %ebx
80102769:	83 ec 2c             	sub    $0x2c,%esp
8010276c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
8010276f:	68 e0 6e 10 80       	push   $0x80106ee0
80102774:	68 80 26 11 80       	push   $0x80112680
80102779:	e8 48 18 00 00       	call   80103fc6 <initlock>
  readsb(dev, &sb);
8010277e:	83 c4 08             	add    $0x8,%esp
80102781:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102784:	50                   	push   %eax
80102785:	53                   	push   %ebx
80102786:	e8 ab ea ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
8010278b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010278e:	a3 b4 26 11 80       	mov    %eax,0x801126b4
  log.size = sb.nlog;
80102793:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102796:	a3 b8 26 11 80       	mov    %eax,0x801126b8
  log.dev = dev;
8010279b:	89 1d c4 26 11 80    	mov    %ebx,0x801126c4
  recover_from_log();
801027a1:	e8 e7 fe ff ff       	call   8010268d <recover_from_log>
}
801027a6:	83 c4 10             	add    $0x10,%esp
801027a9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801027ac:	c9                   	leave  
801027ad:	c3                   	ret    

801027ae <begin_op>:
{
801027ae:	55                   	push   %ebp
801027af:	89 e5                	mov    %esp,%ebp
801027b1:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
801027b4:	68 80 26 11 80       	push   $0x80112680
801027b9:	e8 44 19 00 00       	call   80104102 <acquire>
801027be:	83 c4 10             	add    $0x10,%esp
801027c1:	eb 15                	jmp    801027d8 <begin_op+0x2a>
      sleep(&log, &log.lock);
801027c3:	83 ec 08             	sub    $0x8,%esp
801027c6:	68 80 26 11 80       	push   $0x80112680
801027cb:	68 80 26 11 80       	push   $0x80112680
801027d0:	e8 d9 0d 00 00       	call   801035ae <sleep>
801027d5:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
801027d8:	83 3d c0 26 11 80 00 	cmpl   $0x0,0x801126c0
801027df:	75 e2                	jne    801027c3 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
801027e1:	a1 bc 26 11 80       	mov    0x801126bc,%eax
801027e6:	83 c0 01             	add    $0x1,%eax
801027e9:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027ec:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
801027ef:	03 15 c8 26 11 80    	add    0x801126c8,%edx
801027f5:	83 fa 1e             	cmp    $0x1e,%edx
801027f8:	7e 17                	jle    80102811 <begin_op+0x63>
      sleep(&log, &log.lock);
801027fa:	83 ec 08             	sub    $0x8,%esp
801027fd:	68 80 26 11 80       	push   $0x80112680
80102802:	68 80 26 11 80       	push   $0x80112680
80102807:	e8 a2 0d 00 00       	call   801035ae <sleep>
8010280c:	83 c4 10             	add    $0x10,%esp
8010280f:	eb c7                	jmp    801027d8 <begin_op+0x2a>
      log.outstanding += 1;
80102811:	a3 bc 26 11 80       	mov    %eax,0x801126bc
      release(&log.lock);
80102816:	83 ec 0c             	sub    $0xc,%esp
80102819:	68 80 26 11 80       	push   $0x80112680
8010281e:	e8 44 19 00 00       	call   80104167 <release>
}
80102823:	83 c4 10             	add    $0x10,%esp
80102826:	c9                   	leave  
80102827:	c3                   	ret    

80102828 <end_op>:
{
80102828:	55                   	push   %ebp
80102829:	89 e5                	mov    %esp,%ebp
8010282b:	53                   	push   %ebx
8010282c:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
8010282f:	68 80 26 11 80       	push   $0x80112680
80102834:	e8 c9 18 00 00       	call   80104102 <acquire>
  log.outstanding -= 1;
80102839:	a1 bc 26 11 80       	mov    0x801126bc,%eax
8010283e:	83 e8 01             	sub    $0x1,%eax
80102841:	a3 bc 26 11 80       	mov    %eax,0x801126bc
  if(log.committing)
80102846:	8b 1d c0 26 11 80    	mov    0x801126c0,%ebx
8010284c:	83 c4 10             	add    $0x10,%esp
8010284f:	85 db                	test   %ebx,%ebx
80102851:	75 2c                	jne    8010287f <end_op+0x57>
  if(log.outstanding == 0){
80102853:	85 c0                	test   %eax,%eax
80102855:	75 35                	jne    8010288c <end_op+0x64>
    log.committing = 1;
80102857:	c7 05 c0 26 11 80 01 	movl   $0x1,0x801126c0
8010285e:	00 00 00 
    do_commit = 1;
80102861:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102866:	83 ec 0c             	sub    $0xc,%esp
80102869:	68 80 26 11 80       	push   $0x80112680
8010286e:	e8 f4 18 00 00       	call   80104167 <release>
  if(do_commit){
80102873:	83 c4 10             	add    $0x10,%esp
80102876:	85 db                	test   %ebx,%ebx
80102878:	75 24                	jne    8010289e <end_op+0x76>
}
8010287a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010287d:	c9                   	leave  
8010287e:	c3                   	ret    
    panic("log.committing");
8010287f:	83 ec 0c             	sub    $0xc,%esp
80102882:	68 e4 6e 10 80       	push   $0x80106ee4
80102887:	e8 bc da ff ff       	call   80100348 <panic>
    wakeup(&log);
8010288c:	83 ec 0c             	sub    $0xc,%esp
8010288f:	68 80 26 11 80       	push   $0x80112680
80102894:	e8 7d 0e 00 00       	call   80103716 <wakeup>
80102899:	83 c4 10             	add    $0x10,%esp
8010289c:	eb c8                	jmp    80102866 <end_op+0x3e>
    commit();
8010289e:	e8 91 fe ff ff       	call   80102734 <commit>
    acquire(&log.lock);
801028a3:	83 ec 0c             	sub    $0xc,%esp
801028a6:	68 80 26 11 80       	push   $0x80112680
801028ab:	e8 52 18 00 00       	call   80104102 <acquire>
    log.committing = 0;
801028b0:	c7 05 c0 26 11 80 00 	movl   $0x0,0x801126c0
801028b7:	00 00 00 
    wakeup(&log);
801028ba:	c7 04 24 80 26 11 80 	movl   $0x80112680,(%esp)
801028c1:	e8 50 0e 00 00       	call   80103716 <wakeup>
    release(&log.lock);
801028c6:	c7 04 24 80 26 11 80 	movl   $0x80112680,(%esp)
801028cd:	e8 95 18 00 00       	call   80104167 <release>
801028d2:	83 c4 10             	add    $0x10,%esp
}
801028d5:	eb a3                	jmp    8010287a <end_op+0x52>

801028d7 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801028d7:	55                   	push   %ebp
801028d8:	89 e5                	mov    %esp,%ebp
801028da:	53                   	push   %ebx
801028db:	83 ec 04             	sub    $0x4,%esp
801028de:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801028e1:	8b 15 c8 26 11 80    	mov    0x801126c8,%edx
801028e7:	83 fa 1d             	cmp    $0x1d,%edx
801028ea:	7f 45                	jg     80102931 <log_write+0x5a>
801028ec:	a1 b8 26 11 80       	mov    0x801126b8,%eax
801028f1:	83 e8 01             	sub    $0x1,%eax
801028f4:	39 c2                	cmp    %eax,%edx
801028f6:	7d 39                	jge    80102931 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
801028f8:	83 3d bc 26 11 80 00 	cmpl   $0x0,0x801126bc
801028ff:	7e 3d                	jle    8010293e <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102901:	83 ec 0c             	sub    $0xc,%esp
80102904:	68 80 26 11 80       	push   $0x80112680
80102909:	e8 f4 17 00 00       	call   80104102 <acquire>
  for (i = 0; i < log.lh.n; i++) {
8010290e:	83 c4 10             	add    $0x10,%esp
80102911:	b8 00 00 00 00       	mov    $0x0,%eax
80102916:	8b 15 c8 26 11 80    	mov    0x801126c8,%edx
8010291c:	39 c2                	cmp    %eax,%edx
8010291e:	7e 2b                	jle    8010294b <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102920:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102923:	39 0c 85 cc 26 11 80 	cmp    %ecx,-0x7feed934(,%eax,4)
8010292a:	74 1f                	je     8010294b <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
8010292c:	83 c0 01             	add    $0x1,%eax
8010292f:	eb e5                	jmp    80102916 <log_write+0x3f>
    panic("too big a transaction");
80102931:	83 ec 0c             	sub    $0xc,%esp
80102934:	68 f3 6e 10 80       	push   $0x80106ef3
80102939:	e8 0a da ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
8010293e:	83 ec 0c             	sub    $0xc,%esp
80102941:	68 09 6f 10 80       	push   $0x80106f09
80102946:	e8 fd d9 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
8010294b:	8b 4b 08             	mov    0x8(%ebx),%ecx
8010294e:	89 0c 85 cc 26 11 80 	mov    %ecx,-0x7feed934(,%eax,4)
  if (i == log.lh.n)
80102955:	39 c2                	cmp    %eax,%edx
80102957:	74 18                	je     80102971 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102959:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
8010295c:	83 ec 0c             	sub    $0xc,%esp
8010295f:	68 80 26 11 80       	push   $0x80112680
80102964:	e8 fe 17 00 00       	call   80104167 <release>
}
80102969:	83 c4 10             	add    $0x10,%esp
8010296c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010296f:	c9                   	leave  
80102970:	c3                   	ret    
    log.lh.n++;
80102971:	83 c2 01             	add    $0x1,%edx
80102974:	89 15 c8 26 11 80    	mov    %edx,0x801126c8
8010297a:	eb dd                	jmp    80102959 <log_write+0x82>

8010297c <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
8010297c:	55                   	push   %ebp
8010297d:	89 e5                	mov    %esp,%ebp
8010297f:	53                   	push   %ebx
80102980:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102983:	68 8a 00 00 00       	push   $0x8a
80102988:	68 8c a4 10 80       	push   $0x8010a48c
8010298d:	68 00 70 00 80       	push   $0x80007000
80102992:	e8 92 18 00 00       	call   80104229 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102997:	83 c4 10             	add    $0x10,%esp
8010299a:	bb 80 27 11 80       	mov    $0x80112780,%ebx
8010299f:	eb 06                	jmp    801029a7 <startothers+0x2b>
801029a1:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
801029a7:	69 05 00 2d 11 80 b0 	imul   $0xb0,0x80112d00,%eax
801029ae:	00 00 00 
801029b1:	05 80 27 11 80       	add    $0x80112780,%eax
801029b6:	39 d8                	cmp    %ebx,%eax
801029b8:	76 4c                	jbe    80102a06 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
801029ba:	e8 fb 07 00 00       	call   801031ba <mycpu>
801029bf:	39 d8                	cmp    %ebx,%eax
801029c1:	74 de                	je     801029a1 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801029c3:	e8 f3 f6 ff ff       	call   801020bb <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
801029c8:	05 00 10 00 00       	add    $0x1000,%eax
801029cd:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
801029d2:	c7 05 f8 6f 00 80 4a 	movl   $0x80102a4a,0x80006ff8
801029d9:	2a 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
801029dc:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
801029e3:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
801029e6:	83 ec 08             	sub    $0x8,%esp
801029e9:	68 00 70 00 00       	push   $0x7000
801029ee:	0f b6 03             	movzbl (%ebx),%eax
801029f1:	50                   	push   %eax
801029f2:	e8 c6 f9 ff ff       	call   801023bd <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801029f7:	83 c4 10             	add    $0x10,%esp
801029fa:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102a00:	85 c0                	test   %eax,%eax
80102a02:	74 f6                	je     801029fa <startothers+0x7e>
80102a04:	eb 9b                	jmp    801029a1 <startothers+0x25>
      ;
  }
}
80102a06:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a09:	c9                   	leave  
80102a0a:	c3                   	ret    

80102a0b <mpmain>:
{
80102a0b:	55                   	push   %ebp
80102a0c:	89 e5                	mov    %esp,%ebp
80102a0e:	53                   	push   %ebx
80102a0f:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102a12:	e8 ff 07 00 00       	call   80103216 <cpuid>
80102a17:	89 c3                	mov    %eax,%ebx
80102a19:	e8 f8 07 00 00       	call   80103216 <cpuid>
80102a1e:	83 ec 04             	sub    $0x4,%esp
80102a21:	53                   	push   %ebx
80102a22:	50                   	push   %eax
80102a23:	68 24 6f 10 80       	push   $0x80106f24
80102a28:	e8 de db ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102a2d:	e8 93 29 00 00       	call   801053c5 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102a32:	e8 83 07 00 00       	call   801031ba <mycpu>
80102a37:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102a39:	b8 01 00 00 00       	mov    $0x1,%eax
80102a3e:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102a45:	e8 58 0f 00 00       	call   801039a2 <scheduler>

80102a4a <mpenter>:
{
80102a4a:	55                   	push   %ebp
80102a4b:	89 e5                	mov    %esp,%ebp
80102a4d:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102a50:	e8 79 39 00 00       	call   801063ce <switchkvm>
  seginit();
80102a55:	e8 28 38 00 00       	call   80106282 <seginit>
  lapicinit();
80102a5a:	e8 15 f8 ff ff       	call   80102274 <lapicinit>
  mpmain();
80102a5f:	e8 a7 ff ff ff       	call   80102a0b <mpmain>

80102a64 <main>:
{
80102a64:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102a68:	83 e4 f0             	and    $0xfffffff0,%esp
80102a6b:	ff 71 fc             	pushl  -0x4(%ecx)
80102a6e:	55                   	push   %ebp
80102a6f:	89 e5                	mov    %esp,%ebp
80102a71:	51                   	push   %ecx
80102a72:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102a75:	68 00 00 40 80       	push   $0x80400000
80102a7a:	68 c8 6b 11 80       	push   $0x80116bc8
80102a7f:	e8 e5 f5 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102a84:	e8 d2 3d 00 00       	call   8010685b <kvmalloc>
  mpinit();        // detect other processors
80102a89:	e8 c9 01 00 00       	call   80102c57 <mpinit>
  lapicinit();     // interrupt controller
80102a8e:	e8 e1 f7 ff ff       	call   80102274 <lapicinit>
  seginit();       // segment descriptors
80102a93:	e8 ea 37 00 00       	call   80106282 <seginit>
  picinit();       // disable pic
80102a98:	e8 82 02 00 00       	call   80102d1f <picinit>
  ioapicinit();    // another interrupt controller
80102a9d:	e8 58 f4 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102aa2:	e8 e7 dd ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102aa7:	e8 c7 2b 00 00       	call   80105673 <uartinit>
  pinit();         // process table
80102aac:	e8 ef 06 00 00       	call   801031a0 <pinit>
  tvinit();        // trap vectors
80102ab1:	e8 5e 28 00 00       	call   80105314 <tvinit>
  binit();         // buffer cache
80102ab6:	e8 39 d6 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102abb:	e8 53 e1 ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102ac0:	e8 3b f2 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102ac5:	e8 b2 fe ff ff       	call   8010297c <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102aca:	83 c4 08             	add    $0x8,%esp
80102acd:	68 00 00 00 8e       	push   $0x8e000000
80102ad2:	68 00 00 40 80       	push   $0x80400000
80102ad7:	e8 bf f5 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102adc:	e8 74 07 00 00       	call   80103255 <userinit>
  mpmain();        // finish this processor's setup
80102ae1:	e8 25 ff ff ff       	call   80102a0b <mpmain>

80102ae6 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102ae6:	55                   	push   %ebp
80102ae7:	89 e5                	mov    %esp,%ebp
80102ae9:	56                   	push   %esi
80102aea:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102aeb:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102af0:	b9 00 00 00 00       	mov    $0x0,%ecx
80102af5:	eb 09                	jmp    80102b00 <sum+0x1a>
    sum += addr[i];
80102af7:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102afb:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102afd:	83 c1 01             	add    $0x1,%ecx
80102b00:	39 d1                	cmp    %edx,%ecx
80102b02:	7c f3                	jl     80102af7 <sum+0x11>
  return sum;
}
80102b04:	89 d8                	mov    %ebx,%eax
80102b06:	5b                   	pop    %ebx
80102b07:	5e                   	pop    %esi
80102b08:	5d                   	pop    %ebp
80102b09:	c3                   	ret    

80102b0a <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102b0a:	55                   	push   %ebp
80102b0b:	89 e5                	mov    %esp,%ebp
80102b0d:	56                   	push   %esi
80102b0e:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102b0f:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102b15:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102b17:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102b19:	eb 03                	jmp    80102b1e <mpsearch1+0x14>
80102b1b:	83 c3 10             	add    $0x10,%ebx
80102b1e:	39 f3                	cmp    %esi,%ebx
80102b20:	73 29                	jae    80102b4b <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102b22:	83 ec 04             	sub    $0x4,%esp
80102b25:	6a 04                	push   $0x4
80102b27:	68 38 6f 10 80       	push   $0x80106f38
80102b2c:	53                   	push   %ebx
80102b2d:	e8 c2 16 00 00       	call   801041f4 <memcmp>
80102b32:	83 c4 10             	add    $0x10,%esp
80102b35:	85 c0                	test   %eax,%eax
80102b37:	75 e2                	jne    80102b1b <mpsearch1+0x11>
80102b39:	ba 10 00 00 00       	mov    $0x10,%edx
80102b3e:	89 d8                	mov    %ebx,%eax
80102b40:	e8 a1 ff ff ff       	call   80102ae6 <sum>
80102b45:	84 c0                	test   %al,%al
80102b47:	75 d2                	jne    80102b1b <mpsearch1+0x11>
80102b49:	eb 05                	jmp    80102b50 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102b4b:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102b50:	89 d8                	mov    %ebx,%eax
80102b52:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102b55:	5b                   	pop    %ebx
80102b56:	5e                   	pop    %esi
80102b57:	5d                   	pop    %ebp
80102b58:	c3                   	ret    

80102b59 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102b59:	55                   	push   %ebp
80102b5a:	89 e5                	mov    %esp,%ebp
80102b5c:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102b5f:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102b66:	c1 e0 08             	shl    $0x8,%eax
80102b69:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102b70:	09 d0                	or     %edx,%eax
80102b72:	c1 e0 04             	shl    $0x4,%eax
80102b75:	85 c0                	test   %eax,%eax
80102b77:	74 1f                	je     80102b98 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102b79:	ba 00 04 00 00       	mov    $0x400,%edx
80102b7e:	e8 87 ff ff ff       	call   80102b0a <mpsearch1>
80102b83:	85 c0                	test   %eax,%eax
80102b85:	75 0f                	jne    80102b96 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102b87:	ba 00 00 01 00       	mov    $0x10000,%edx
80102b8c:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102b91:	e8 74 ff ff ff       	call   80102b0a <mpsearch1>
}
80102b96:	c9                   	leave  
80102b97:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102b98:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102b9f:	c1 e0 08             	shl    $0x8,%eax
80102ba2:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102ba9:	09 d0                	or     %edx,%eax
80102bab:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102bae:	2d 00 04 00 00       	sub    $0x400,%eax
80102bb3:	ba 00 04 00 00       	mov    $0x400,%edx
80102bb8:	e8 4d ff ff ff       	call   80102b0a <mpsearch1>
80102bbd:	85 c0                	test   %eax,%eax
80102bbf:	75 d5                	jne    80102b96 <mpsearch+0x3d>
80102bc1:	eb c4                	jmp    80102b87 <mpsearch+0x2e>

80102bc3 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102bc3:	55                   	push   %ebp
80102bc4:	89 e5                	mov    %esp,%ebp
80102bc6:	57                   	push   %edi
80102bc7:	56                   	push   %esi
80102bc8:	53                   	push   %ebx
80102bc9:	83 ec 1c             	sub    $0x1c,%esp
80102bcc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102bcf:	e8 85 ff ff ff       	call   80102b59 <mpsearch>
80102bd4:	85 c0                	test   %eax,%eax
80102bd6:	74 5c                	je     80102c34 <mpconfig+0x71>
80102bd8:	89 c7                	mov    %eax,%edi
80102bda:	8b 58 04             	mov    0x4(%eax),%ebx
80102bdd:	85 db                	test   %ebx,%ebx
80102bdf:	74 5a                	je     80102c3b <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102be1:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102be7:	83 ec 04             	sub    $0x4,%esp
80102bea:	6a 04                	push   $0x4
80102bec:	68 3d 6f 10 80       	push   $0x80106f3d
80102bf1:	56                   	push   %esi
80102bf2:	e8 fd 15 00 00       	call   801041f4 <memcmp>
80102bf7:	83 c4 10             	add    $0x10,%esp
80102bfa:	85 c0                	test   %eax,%eax
80102bfc:	75 44                	jne    80102c42 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102bfe:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102c05:	3c 01                	cmp    $0x1,%al
80102c07:	0f 95 c2             	setne  %dl
80102c0a:	3c 04                	cmp    $0x4,%al
80102c0c:	0f 95 c0             	setne  %al
80102c0f:	84 c2                	test   %al,%dl
80102c11:	75 36                	jne    80102c49 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102c13:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102c1a:	89 f0                	mov    %esi,%eax
80102c1c:	e8 c5 fe ff ff       	call   80102ae6 <sum>
80102c21:	84 c0                	test   %al,%al
80102c23:	75 2b                	jne    80102c50 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102c25:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102c28:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102c2a:	89 f0                	mov    %esi,%eax
80102c2c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102c2f:	5b                   	pop    %ebx
80102c30:	5e                   	pop    %esi
80102c31:	5f                   	pop    %edi
80102c32:	5d                   	pop    %ebp
80102c33:	c3                   	ret    
    return 0;
80102c34:	be 00 00 00 00       	mov    $0x0,%esi
80102c39:	eb ef                	jmp    80102c2a <mpconfig+0x67>
80102c3b:	be 00 00 00 00       	mov    $0x0,%esi
80102c40:	eb e8                	jmp    80102c2a <mpconfig+0x67>
    return 0;
80102c42:	be 00 00 00 00       	mov    $0x0,%esi
80102c47:	eb e1                	jmp    80102c2a <mpconfig+0x67>
    return 0;
80102c49:	be 00 00 00 00       	mov    $0x0,%esi
80102c4e:	eb da                	jmp    80102c2a <mpconfig+0x67>
    return 0;
80102c50:	be 00 00 00 00       	mov    $0x0,%esi
80102c55:	eb d3                	jmp    80102c2a <mpconfig+0x67>

80102c57 <mpinit>:

void
mpinit(void)
{
80102c57:	55                   	push   %ebp
80102c58:	89 e5                	mov    %esp,%ebp
80102c5a:	57                   	push   %edi
80102c5b:	56                   	push   %esi
80102c5c:	53                   	push   %ebx
80102c5d:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102c60:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102c63:	e8 5b ff ff ff       	call   80102bc3 <mpconfig>
80102c68:	85 c0                	test   %eax,%eax
80102c6a:	74 19                	je     80102c85 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102c6c:	8b 50 24             	mov    0x24(%eax),%edx
80102c6f:	89 15 7c 26 11 80    	mov    %edx,0x8011267c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102c75:	8d 50 2c             	lea    0x2c(%eax),%edx
80102c78:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102c7c:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102c7e:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102c83:	eb 34                	jmp    80102cb9 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102c85:	83 ec 0c             	sub    $0xc,%esp
80102c88:	68 42 6f 10 80       	push   $0x80106f42
80102c8d:	e8 b6 d6 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102c92:	8b 35 00 2d 11 80    	mov    0x80112d00,%esi
80102c98:	83 fe 07             	cmp    $0x7,%esi
80102c9b:	7f 19                	jg     80102cb6 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102c9d:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102ca1:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102ca7:	88 87 80 27 11 80    	mov    %al,-0x7feed880(%edi)
        ncpu++;
80102cad:	83 c6 01             	add    $0x1,%esi
80102cb0:	89 35 00 2d 11 80    	mov    %esi,0x80112d00
      }
      p += sizeof(struct mpproc);
80102cb6:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102cb9:	39 ca                	cmp    %ecx,%edx
80102cbb:	73 2b                	jae    80102ce8 <mpinit+0x91>
    switch(*p){
80102cbd:	0f b6 02             	movzbl (%edx),%eax
80102cc0:	3c 04                	cmp    $0x4,%al
80102cc2:	77 1d                	ja     80102ce1 <mpinit+0x8a>
80102cc4:	0f b6 c0             	movzbl %al,%eax
80102cc7:	ff 24 85 7c 6f 10 80 	jmp    *-0x7fef9084(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102cce:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102cd2:	a2 60 27 11 80       	mov    %al,0x80112760
      p += sizeof(struct mpioapic);
80102cd7:	83 c2 08             	add    $0x8,%edx
      continue;
80102cda:	eb dd                	jmp    80102cb9 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102cdc:	83 c2 08             	add    $0x8,%edx
      continue;
80102cdf:	eb d8                	jmp    80102cb9 <mpinit+0x62>
    default:
      ismp = 0;
80102ce1:	bb 00 00 00 00       	mov    $0x0,%ebx
80102ce6:	eb d1                	jmp    80102cb9 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102ce8:	85 db                	test   %ebx,%ebx
80102cea:	74 26                	je     80102d12 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102cec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102cef:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102cf3:	74 15                	je     80102d0a <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102cf5:	b8 70 00 00 00       	mov    $0x70,%eax
80102cfa:	ba 22 00 00 00       	mov    $0x22,%edx
80102cff:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102d00:	ba 23 00 00 00       	mov    $0x23,%edx
80102d05:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102d06:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d09:	ee                   	out    %al,(%dx)
  }
}
80102d0a:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d0d:	5b                   	pop    %ebx
80102d0e:	5e                   	pop    %esi
80102d0f:	5f                   	pop    %edi
80102d10:	5d                   	pop    %ebp
80102d11:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102d12:	83 ec 0c             	sub    $0xc,%esp
80102d15:	68 5c 6f 10 80       	push   $0x80106f5c
80102d1a:	e8 29 d6 ff ff       	call   80100348 <panic>

80102d1f <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102d1f:	55                   	push   %ebp
80102d20:	89 e5                	mov    %esp,%ebp
80102d22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d27:	ba 21 00 00 00       	mov    $0x21,%edx
80102d2c:	ee                   	out    %al,(%dx)
80102d2d:	ba a1 00 00 00       	mov    $0xa1,%edx
80102d32:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102d33:	5d                   	pop    %ebp
80102d34:	c3                   	ret    

80102d35 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102d35:	55                   	push   %ebp
80102d36:	89 e5                	mov    %esp,%ebp
80102d38:	57                   	push   %edi
80102d39:	56                   	push   %esi
80102d3a:	53                   	push   %ebx
80102d3b:	83 ec 0c             	sub    $0xc,%esp
80102d3e:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102d41:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102d44:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102d4a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102d50:	e8 d8 de ff ff       	call   80100c2d <filealloc>
80102d55:	89 03                	mov    %eax,(%ebx)
80102d57:	85 c0                	test   %eax,%eax
80102d59:	74 16                	je     80102d71 <pipealloc+0x3c>
80102d5b:	e8 cd de ff ff       	call   80100c2d <filealloc>
80102d60:	89 06                	mov    %eax,(%esi)
80102d62:	85 c0                	test   %eax,%eax
80102d64:	74 0b                	je     80102d71 <pipealloc+0x3c>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102d66:	e8 50 f3 ff ff       	call   801020bb <kalloc>
80102d6b:	89 c7                	mov    %eax,%edi
80102d6d:	85 c0                	test   %eax,%eax
80102d6f:	75 35                	jne    80102da6 <pipealloc+0x71>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102d71:	8b 03                	mov    (%ebx),%eax
80102d73:	85 c0                	test   %eax,%eax
80102d75:	74 0c                	je     80102d83 <pipealloc+0x4e>
    fileclose(*f0);
80102d77:	83 ec 0c             	sub    $0xc,%esp
80102d7a:	50                   	push   %eax
80102d7b:	e8 53 df ff ff       	call   80100cd3 <fileclose>
80102d80:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102d83:	8b 06                	mov    (%esi),%eax
80102d85:	85 c0                	test   %eax,%eax
80102d87:	0f 84 8b 00 00 00    	je     80102e18 <pipealloc+0xe3>
    fileclose(*f1);
80102d8d:	83 ec 0c             	sub    $0xc,%esp
80102d90:	50                   	push   %eax
80102d91:	e8 3d df ff ff       	call   80100cd3 <fileclose>
80102d96:	83 c4 10             	add    $0x10,%esp
  return -1;
80102d99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102d9e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102da1:	5b                   	pop    %ebx
80102da2:	5e                   	pop    %esi
80102da3:	5f                   	pop    %edi
80102da4:	5d                   	pop    %ebp
80102da5:	c3                   	ret    
  p->readopen = 1;
80102da6:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102dad:	00 00 00 
  p->writeopen = 1;
80102db0:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102db7:	00 00 00 
  p->nwrite = 0;
80102dba:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102dc1:	00 00 00 
  p->nread = 0;
80102dc4:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102dcb:	00 00 00 
  initlock(&p->lock, "pipe");
80102dce:	83 ec 08             	sub    $0x8,%esp
80102dd1:	68 90 6f 10 80       	push   $0x80106f90
80102dd6:	50                   	push   %eax
80102dd7:	e8 ea 11 00 00       	call   80103fc6 <initlock>
  (*f0)->type = FD_PIPE;
80102ddc:	8b 03                	mov    (%ebx),%eax
80102dde:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102de4:	8b 03                	mov    (%ebx),%eax
80102de6:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102dea:	8b 03                	mov    (%ebx),%eax
80102dec:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102df0:	8b 03                	mov    (%ebx),%eax
80102df2:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102df5:	8b 06                	mov    (%esi),%eax
80102df7:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102dfd:	8b 06                	mov    (%esi),%eax
80102dff:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102e03:	8b 06                	mov    (%esi),%eax
80102e05:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102e09:	8b 06                	mov    (%esi),%eax
80102e0b:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102e0e:	83 c4 10             	add    $0x10,%esp
80102e11:	b8 00 00 00 00       	mov    $0x0,%eax
80102e16:	eb 86                	jmp    80102d9e <pipealloc+0x69>
  return -1;
80102e18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e1d:	e9 7c ff ff ff       	jmp    80102d9e <pipealloc+0x69>

80102e22 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102e22:	55                   	push   %ebp
80102e23:	89 e5                	mov    %esp,%ebp
80102e25:	53                   	push   %ebx
80102e26:	83 ec 10             	sub    $0x10,%esp
80102e29:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102e2c:	53                   	push   %ebx
80102e2d:	e8 d0 12 00 00       	call   80104102 <acquire>
  if(writable){
80102e32:	83 c4 10             	add    $0x10,%esp
80102e35:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102e39:	74 3f                	je     80102e7a <pipeclose+0x58>
    p->writeopen = 0;
80102e3b:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102e42:	00 00 00 
    wakeup(&p->nread);
80102e45:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102e4b:	83 ec 0c             	sub    $0xc,%esp
80102e4e:	50                   	push   %eax
80102e4f:	e8 c2 08 00 00       	call   80103716 <wakeup>
80102e54:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102e57:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102e5e:	75 09                	jne    80102e69 <pipeclose+0x47>
80102e60:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102e67:	74 2f                	je     80102e98 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102e69:	83 ec 0c             	sub    $0xc,%esp
80102e6c:	53                   	push   %ebx
80102e6d:	e8 f5 12 00 00       	call   80104167 <release>
80102e72:	83 c4 10             	add    $0x10,%esp
}
80102e75:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102e78:	c9                   	leave  
80102e79:	c3                   	ret    
    p->readopen = 0;
80102e7a:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102e81:	00 00 00 
    wakeup(&p->nwrite);
80102e84:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102e8a:	83 ec 0c             	sub    $0xc,%esp
80102e8d:	50                   	push   %eax
80102e8e:	e8 83 08 00 00       	call   80103716 <wakeup>
80102e93:	83 c4 10             	add    $0x10,%esp
80102e96:	eb bf                	jmp    80102e57 <pipeclose+0x35>
    release(&p->lock);
80102e98:	83 ec 0c             	sub    $0xc,%esp
80102e9b:	53                   	push   %ebx
80102e9c:	e8 c6 12 00 00       	call   80104167 <release>
    kfree((char*)p);
80102ea1:	89 1c 24             	mov    %ebx,(%esp)
80102ea4:	e8 fb f0 ff ff       	call   80101fa4 <kfree>
80102ea9:	83 c4 10             	add    $0x10,%esp
80102eac:	eb c7                	jmp    80102e75 <pipeclose+0x53>

80102eae <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102eae:	55                   	push   %ebp
80102eaf:	89 e5                	mov    %esp,%ebp
80102eb1:	57                   	push   %edi
80102eb2:	56                   	push   %esi
80102eb3:	53                   	push   %ebx
80102eb4:	83 ec 18             	sub    $0x18,%esp
80102eb7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102eba:	89 de                	mov    %ebx,%esi
80102ebc:	53                   	push   %ebx
80102ebd:	e8 40 12 00 00       	call   80104102 <acquire>
  for(i = 0; i < n; i++){
80102ec2:	83 c4 10             	add    $0x10,%esp
80102ec5:	bf 00 00 00 00       	mov    $0x0,%edi
80102eca:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102ecd:	0f 8d 88 00 00 00    	jge    80102f5b <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80102ed3:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80102ed9:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102edf:	05 00 02 00 00       	add    $0x200,%eax
80102ee4:	39 c2                	cmp    %eax,%edx
80102ee6:	75 51                	jne    80102f39 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80102ee8:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102eef:	74 2f                	je     80102f20 <pipewrite+0x72>
80102ef1:	e8 3b 03 00 00       	call   80103231 <myproc>
80102ef6:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102efa:	75 24                	jne    80102f20 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80102efc:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f02:	83 ec 0c             	sub    $0xc,%esp
80102f05:	50                   	push   %eax
80102f06:	e8 0b 08 00 00       	call   80103716 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80102f0b:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f11:	83 c4 08             	add    $0x8,%esp
80102f14:	56                   	push   %esi
80102f15:	50                   	push   %eax
80102f16:	e8 93 06 00 00       	call   801035ae <sleep>
80102f1b:	83 c4 10             	add    $0x10,%esp
80102f1e:	eb b3                	jmp    80102ed3 <pipewrite+0x25>
        release(&p->lock);
80102f20:	83 ec 0c             	sub    $0xc,%esp
80102f23:	53                   	push   %ebx
80102f24:	e8 3e 12 00 00       	call   80104167 <release>
        return -1;
80102f29:	83 c4 10             	add    $0x10,%esp
80102f2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80102f31:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f34:	5b                   	pop    %ebx
80102f35:	5e                   	pop    %esi
80102f36:	5f                   	pop    %edi
80102f37:	5d                   	pop    %ebp
80102f38:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80102f39:	8d 42 01             	lea    0x1(%edx),%eax
80102f3c:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80102f42:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102f48:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f4b:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80102f4f:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80102f53:	83 c7 01             	add    $0x1,%edi
80102f56:	e9 6f ff ff ff       	jmp    80102eca <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80102f5b:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f61:	83 ec 0c             	sub    $0xc,%esp
80102f64:	50                   	push   %eax
80102f65:	e8 ac 07 00 00       	call   80103716 <wakeup>
  release(&p->lock);
80102f6a:	89 1c 24             	mov    %ebx,(%esp)
80102f6d:	e8 f5 11 00 00       	call   80104167 <release>
  return n;
80102f72:	83 c4 10             	add    $0x10,%esp
80102f75:	8b 45 10             	mov    0x10(%ebp),%eax
80102f78:	eb b7                	jmp    80102f31 <pipewrite+0x83>

80102f7a <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80102f7a:	55                   	push   %ebp
80102f7b:	89 e5                	mov    %esp,%ebp
80102f7d:	57                   	push   %edi
80102f7e:	56                   	push   %esi
80102f7f:	53                   	push   %ebx
80102f80:	83 ec 18             	sub    $0x18,%esp
80102f83:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102f86:	89 df                	mov    %ebx,%edi
80102f88:	53                   	push   %ebx
80102f89:	e8 74 11 00 00       	call   80104102 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80102f8e:	83 c4 10             	add    $0x10,%esp
80102f91:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80102f97:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80102f9d:	75 3d                	jne    80102fdc <piperead+0x62>
80102f9f:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
80102fa5:	85 f6                	test   %esi,%esi
80102fa7:	74 38                	je     80102fe1 <piperead+0x67>
    if(myproc()->killed){
80102fa9:	e8 83 02 00 00       	call   80103231 <myproc>
80102fae:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102fb2:	75 15                	jne    80102fc9 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80102fb4:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102fba:	83 ec 08             	sub    $0x8,%esp
80102fbd:	57                   	push   %edi
80102fbe:	50                   	push   %eax
80102fbf:	e8 ea 05 00 00       	call   801035ae <sleep>
80102fc4:	83 c4 10             	add    $0x10,%esp
80102fc7:	eb c8                	jmp    80102f91 <piperead+0x17>
      release(&p->lock);
80102fc9:	83 ec 0c             	sub    $0xc,%esp
80102fcc:	53                   	push   %ebx
80102fcd:	e8 95 11 00 00       	call   80104167 <release>
      return -1;
80102fd2:	83 c4 10             	add    $0x10,%esp
80102fd5:	be ff ff ff ff       	mov    $0xffffffff,%esi
80102fda:	eb 50                	jmp    8010302c <piperead+0xb2>
80102fdc:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80102fe1:	3b 75 10             	cmp    0x10(%ebp),%esi
80102fe4:	7d 2c                	jge    80103012 <piperead+0x98>
    if(p->nread == p->nwrite)
80102fe6:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102fec:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80102ff2:	74 1e                	je     80103012 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80102ff4:	8d 50 01             	lea    0x1(%eax),%edx
80102ff7:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80102ffd:	25 ff 01 00 00       	and    $0x1ff,%eax
80103002:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80103007:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010300a:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010300d:	83 c6 01             	add    $0x1,%esi
80103010:	eb cf                	jmp    80102fe1 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103012:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103018:	83 ec 0c             	sub    $0xc,%esp
8010301b:	50                   	push   %eax
8010301c:	e8 f5 06 00 00       	call   80103716 <wakeup>
  release(&p->lock);
80103021:	89 1c 24             	mov    %ebx,(%esp)
80103024:	e8 3e 11 00 00       	call   80104167 <release>
  return i;
80103029:	83 c4 10             	add    $0x10,%esp
}
8010302c:	89 f0                	mov    %esi,%eax
8010302e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103031:	5b                   	pop    %ebx
80103032:	5e                   	pop    %esi
80103033:	5f                   	pop    %edi
80103034:	5d                   	pop    %ebp
80103035:	c3                   	ret    

80103036 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103036:	55                   	push   %ebp
80103037:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103039:	ba 74 2d 11 80       	mov    $0x80112d74,%edx
8010303e:	eb 06                	jmp    80103046 <wakeup1+0x10>
80103040:	81 c2 a8 00 00 00    	add    $0xa8,%edx
80103046:	81 fa 74 57 11 80    	cmp    $0x80115774,%edx
8010304c:	73 14                	jae    80103062 <wakeup1+0x2c>
    if(p->state == SLEEPING && p->chan == chan)
8010304e:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
80103052:	75 ec                	jne    80103040 <wakeup1+0xa>
80103054:	39 42 20             	cmp    %eax,0x20(%edx)
80103057:	75 e7                	jne    80103040 <wakeup1+0xa>
      p->state = RUNNABLE;
80103059:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
80103060:	eb de                	jmp    80103040 <wakeup1+0xa>
}
80103062:	5d                   	pop    %ebp
80103063:	c3                   	ret    

80103064 <allocproc>:
{
80103064:	55                   	push   %ebp
80103065:	89 e5                	mov    %esp,%ebp
80103067:	53                   	push   %ebx
80103068:	83 ec 10             	sub    $0x10,%esp
    acquire(&ptable.lock);
8010306b:	68 40 2d 11 80       	push   $0x80112d40
80103070:	e8 8d 10 00 00       	call   80104102 <acquire>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103075:	83 c4 10             	add    $0x10,%esp
80103078:	bb 74 2d 11 80       	mov    $0x80112d74,%ebx
8010307d:	81 fb 74 57 11 80    	cmp    $0x80115774,%ebx
80103083:	73 0e                	jae    80103093 <allocproc+0x2f>
        if (p->state == UNUSED)
80103085:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103089:	74 22                	je     801030ad <allocproc+0x49>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010308b:	81 c3 a8 00 00 00    	add    $0xa8,%ebx
80103091:	eb ea                	jmp    8010307d <allocproc+0x19>
    release(&ptable.lock);
80103093:	83 ec 0c             	sub    $0xc,%esp
80103096:	68 40 2d 11 80       	push   $0x80112d40
8010309b:	e8 c7 10 00 00       	call   80104167 <release>
    return 0;
801030a0:	83 c4 10             	add    $0x10,%esp
801030a3:	bb 00 00 00 00       	mov    $0x0,%ebx
801030a8:	e9 9b 00 00 00       	jmp    80103148 <allocproc+0xe4>
        p->state = EMBRYO;
801030ad:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
        p->pid = nextpid++;
801030b4:	a1 04 a0 10 80       	mov    0x8010a004,%eax
801030b9:	8d 50 01             	lea    0x1(%eax),%edx
801030bc:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
801030c2:	89 43 10             	mov    %eax,0x10(%ebx)
        p->agg_ticks[0] = 0;
801030c5:	c7 83 88 00 00 00 00 	movl   $0x0,0x88(%ebx)
801030cc:	00 00 00 
        p->agg_ticks[1] = 0;
801030cf:	c7 83 8c 00 00 00 00 	movl   $0x0,0x8c(%ebx)
801030d6:	00 00 00 
        p->agg_ticks[2] = 0;
801030d9:	c7 83 90 00 00 00 00 	movl   $0x0,0x90(%ebx)
801030e0:	00 00 00 
        p->agg_ticks[3] = 0;
801030e3:	c7 83 94 00 00 00 00 	movl   $0x0,0x94(%ebx)
801030ea:	00 00 00 
        p->ticks = 0;
801030ed:	c7 83 84 00 00 00 00 	movl   $0x0,0x84(%ebx)
801030f4:	00 00 00 
        release(&ptable.lock);
801030f7:	83 ec 0c             	sub    $0xc,%esp
801030fa:	68 40 2d 11 80       	push   $0x80112d40
801030ff:	e8 63 10 00 00       	call   80104167 <release>
        if ((p->kstack = kalloc()) == 0) {
80103104:	e8 b2 ef ff ff       	call   801020bb <kalloc>
80103109:	89 43 08             	mov    %eax,0x8(%ebx)
8010310c:	83 c4 10             	add    $0x10,%esp
8010310f:	85 c0                	test   %eax,%eax
80103111:	74 3c                	je     8010314f <allocproc+0xeb>
        sp -= sizeof *p->tf;
80103113:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
        p->tf = (struct trapframe *) sp;
80103119:	89 53 18             	mov    %edx,0x18(%ebx)
        *(uint *) sp = (uint) trapret;
8010311c:	c7 80 b0 0f 00 00 09 	movl   $0x80105309,0xfb0(%eax)
80103123:	53 10 80 
        sp -= sizeof *p->context;
80103126:	05 9c 0f 00 00       	add    $0xf9c,%eax
        p->context = (struct context *) sp;
8010312b:	89 43 1c             	mov    %eax,0x1c(%ebx)
        memset(p->context, 0, sizeof *p->context);
8010312e:	83 ec 04             	sub    $0x4,%esp
80103131:	6a 14                	push   $0x14
80103133:	6a 00                	push   $0x0
80103135:	50                   	push   %eax
80103136:	e8 73 10 00 00       	call   801041ae <memset>
        p->context->eip = (uint) forkret;
8010313b:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010313e:	c7 40 10 5d 31 10 80 	movl   $0x8010315d,0x10(%eax)
  return p;
80103145:	83 c4 10             	add    $0x10,%esp
}
80103148:	89 d8                	mov    %ebx,%eax
8010314a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010314d:	c9                   	leave  
8010314e:	c3                   	ret    
            p->state = UNUSED;
8010314f:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
            return 0;
80103156:	bb 00 00 00 00       	mov    $0x0,%ebx
8010315b:	eb eb                	jmp    80103148 <allocproc+0xe4>

8010315d <forkret>:
{
8010315d:	55                   	push   %ebp
8010315e:	89 e5                	mov    %esp,%ebp
80103160:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103163:	68 40 2d 11 80       	push   $0x80112d40
80103168:	e8 fa 0f 00 00       	call   80104167 <release>
  if (first) {
8010316d:	83 c4 10             	add    $0x10,%esp
80103170:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
80103177:	75 02                	jne    8010317b <forkret+0x1e>
}
80103179:	c9                   	leave  
8010317a:	c3                   	ret    
    first = 0;
8010317b:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
80103182:	00 00 00 
    iinit(ROOTDEV);
80103185:	83 ec 0c             	sub    $0xc,%esp
80103188:	6a 01                	push   $0x1
8010318a:	e8 5d e1 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
8010318f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103196:	e8 ca f5 ff ff       	call   80102765 <initlog>
8010319b:	83 c4 10             	add    $0x10,%esp
}
8010319e:	eb d9                	jmp    80103179 <forkret+0x1c>

801031a0 <pinit>:
{
801031a0:	55                   	push   %ebp
801031a1:	89 e5                	mov    %esp,%ebp
801031a3:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801031a6:	68 95 6f 10 80       	push   $0x80106f95
801031ab:	68 40 2d 11 80       	push   $0x80112d40
801031b0:	e8 11 0e 00 00       	call   80103fc6 <initlock>
}
801031b5:	83 c4 10             	add    $0x10,%esp
801031b8:	c9                   	leave  
801031b9:	c3                   	ret    

801031ba <mycpu>:
{
801031ba:	55                   	push   %ebp
801031bb:	89 e5                	mov    %esp,%ebp
801031bd:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801031c0:	9c                   	pushf  
801031c1:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801031c2:	f6 c4 02             	test   $0x2,%ah
801031c5:	75 28                	jne    801031ef <mycpu+0x35>
  apicid = lapicid();
801031c7:	e8 b2 f1 ff ff       	call   8010237e <lapicid>
  for (i = 0; i < ncpu; ++i) {
801031cc:	ba 00 00 00 00       	mov    $0x0,%edx
801031d1:	39 15 00 2d 11 80    	cmp    %edx,0x80112d00
801031d7:	7e 23                	jle    801031fc <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801031d9:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801031df:	0f b6 89 80 27 11 80 	movzbl -0x7feed880(%ecx),%ecx
801031e6:	39 c1                	cmp    %eax,%ecx
801031e8:	74 1f                	je     80103209 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
801031ea:	83 c2 01             	add    $0x1,%edx
801031ed:	eb e2                	jmp    801031d1 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801031ef:	83 ec 0c             	sub    $0xc,%esp
801031f2:	68 f0 70 10 80       	push   $0x801070f0
801031f7:	e8 4c d1 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801031fc:	83 ec 0c             	sub    $0xc,%esp
801031ff:	68 9c 6f 10 80       	push   $0x80106f9c
80103204:	e8 3f d1 ff ff       	call   80100348 <panic>
      return &cpus[i];
80103209:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
8010320f:	05 80 27 11 80       	add    $0x80112780,%eax
}
80103214:	c9                   	leave  
80103215:	c3                   	ret    

80103216 <cpuid>:
cpuid() {
80103216:	55                   	push   %ebp
80103217:	89 e5                	mov    %esp,%ebp
80103219:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
8010321c:	e8 99 ff ff ff       	call   801031ba <mycpu>
80103221:	2d 80 27 11 80       	sub    $0x80112780,%eax
80103226:	c1 f8 04             	sar    $0x4,%eax
80103229:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010322f:	c9                   	leave  
80103230:	c3                   	ret    

80103231 <myproc>:
myproc(void) {
80103231:	55                   	push   %ebp
80103232:	89 e5                	mov    %esp,%ebp
80103234:	53                   	push   %ebx
80103235:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103238:	e8 e8 0d 00 00       	call   80104025 <pushcli>
  c = mycpu();
8010323d:	e8 78 ff ff ff       	call   801031ba <mycpu>
  p = c->proc;
80103242:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103248:	e8 15 0e 00 00       	call   80104062 <popcli>
}
8010324d:	89 d8                	mov    %ebx,%eax
8010324f:	83 c4 04             	add    $0x4,%esp
80103252:	5b                   	pop    %ebx
80103253:	5d                   	pop    %ebp
80103254:	c3                   	ret    

80103255 <userinit>:
{
80103255:	55                   	push   %ebp
80103256:	89 e5                	mov    %esp,%ebp
80103258:	53                   	push   %ebx
80103259:	83 ec 04             	sub    $0x4,%esp
    p = allocproc();
8010325c:	e8 03 fe ff ff       	call   80103064 <allocproc>
80103261:	89 c3                	mov    %eax,%ebx
    initproc = p;
80103263:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
    if ((p->pgdir = setupkvm()) == 0)
80103268:	e8 80 35 00 00       	call   801067ed <setupkvm>
8010326d:	89 43 04             	mov    %eax,0x4(%ebx)
80103270:	85 c0                	test   %eax,%eax
80103272:	0f 84 d5 00 00 00    	je     8010334d <userinit+0xf8>
    inituvm(p->pgdir, _binary_initcode_start, (int) _binary_initcode_size);
80103278:	83 ec 04             	sub    $0x4,%esp
8010327b:	68 2c 00 00 00       	push   $0x2c
80103280:	68 60 a4 10 80       	push   $0x8010a460
80103285:	50                   	push   %eax
80103286:	e8 6d 32 00 00       	call   801064f8 <inituvm>
    p->sz = PGSIZE;
8010328b:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
    memset(p->tf, 0, sizeof(*p->tf));
80103291:	83 c4 0c             	add    $0xc,%esp
80103294:	6a 4c                	push   $0x4c
80103296:	6a 00                	push   $0x0
80103298:	ff 73 18             	pushl  0x18(%ebx)
8010329b:	e8 0e 0f 00 00       	call   801041ae <memset>
    p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801032a0:	8b 43 18             	mov    0x18(%ebx),%eax
801032a3:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
    p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801032a9:	8b 43 18             	mov    0x18(%ebx),%eax
801032ac:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
    p->tf->es = p->tf->ds;
801032b2:	8b 43 18             	mov    0x18(%ebx),%eax
801032b5:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801032b9:	66 89 50 28          	mov    %dx,0x28(%eax)
    p->tf->ss = p->tf->ds;
801032bd:	8b 43 18             	mov    0x18(%ebx),%eax
801032c0:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801032c4:	66 89 50 48          	mov    %dx,0x48(%eax)
    p->tf->eflags = FL_IF;
801032c8:	8b 43 18             	mov    0x18(%ebx),%eax
801032cb:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
    p->tf->esp = PGSIZE;
801032d2:	8b 43 18             	mov    0x18(%ebx),%eax
801032d5:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
    p->tf->eip = 0;  // beginning of initcode.S
801032dc:	8b 43 18             	mov    0x18(%ebx),%eax
801032df:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
    safestrcpy(p->name, "initcode", sizeof(p->name));
801032e6:	8d 43 6c             	lea    0x6c(%ebx),%eax
801032e9:	83 c4 0c             	add    $0xc,%esp
801032ec:	6a 10                	push   $0x10
801032ee:	68 c5 6f 10 80       	push   $0x80106fc5
801032f3:	50                   	push   %eax
801032f4:	e8 1c 10 00 00       	call   80104315 <safestrcpy>
    p->cwd = namei("/");
801032f9:	c7 04 24 ce 6f 10 80 	movl   $0x80106fce,(%esp)
80103300:	e8 dc e8 ff ff       	call   80101be1 <namei>
80103305:	89 43 68             	mov    %eax,0x68(%ebx)
    acquire(&ptable.lock);
80103308:	c7 04 24 40 2d 11 80 	movl   $0x80112d40,(%esp)
8010330f:	e8 ee 0d 00 00       	call   80104102 <acquire>
    p->state = RUNNABLE;
80103314:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
    p->priority = 3;
8010331b:	c7 43 7c 03 00 00 00 	movl   $0x3,0x7c(%ebx)
    if (priorityQueue[p->priority].head == NULL && priorityQueue[p->priority].tail == NULL) {
80103322:	83 c4 10             	add    $0x10,%esp
80103325:	83 3d 38 2d 11 80 00 	cmpl   $0x0,0x80112d38
8010332c:	74 2c                	je     8010335a <userinit+0x105>
    p->next = NULL;
8010332e:	c7 83 80 00 00 00 00 	movl   $0x0,0x80(%ebx)
80103335:	00 00 00 
    release(&ptable.lock);
80103338:	83 ec 0c             	sub    $0xc,%esp
8010333b:	68 40 2d 11 80       	push   $0x80112d40
80103340:	e8 22 0e 00 00       	call   80104167 <release>
}
80103345:	83 c4 10             	add    $0x10,%esp
80103348:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010334b:	c9                   	leave  
8010334c:	c3                   	ret    
        panic("userinit: out of memory?");
8010334d:	83 ec 0c             	sub    $0xc,%esp
80103350:	68 ac 6f 10 80       	push   $0x80106fac
80103355:	e8 ee cf ff ff       	call   80100348 <panic>
    if (priorityQueue[p->priority].head == NULL && priorityQueue[p->priority].tail == NULL) {
8010335a:	83 3d 3c 2d 11 80 00 	cmpl   $0x0,0x80112d3c
80103361:	75 cb                	jne    8010332e <userinit+0xd9>
        p->ticks = 0;
80103363:	c7 83 84 00 00 00 00 	movl   $0x0,0x84(%ebx)
8010336a:	00 00 00 
        p->agg_ticks[0] = 0;
8010336d:	c7 83 88 00 00 00 00 	movl   $0x0,0x88(%ebx)
80103374:	00 00 00 
        p->agg_ticks[1] = 0;
80103377:	c7 83 8c 00 00 00 00 	movl   $0x0,0x8c(%ebx)
8010337e:	00 00 00 
        p->agg_ticks[2] = 0;
80103381:	c7 83 90 00 00 00 00 	movl   $0x0,0x90(%ebx)
80103388:	00 00 00 
        p->agg_ticks[3] = 0;
8010338b:	c7 83 94 00 00 00 00 	movl   $0x0,0x94(%ebx)
80103392:	00 00 00 
        priorityQueue[p->priority].head = p;
80103395:	89 1d 38 2d 11 80    	mov    %ebx,0x80112d38
        priorityQueue[p->priority].tail = p;
8010339b:	89 1d 3c 2d 11 80    	mov    %ebx,0x80112d3c
801033a1:	eb 8b                	jmp    8010332e <userinit+0xd9>

801033a3 <growproc>:
{
801033a3:	55                   	push   %ebp
801033a4:	89 e5                	mov    %esp,%ebp
801033a6:	56                   	push   %esi
801033a7:	53                   	push   %ebx
801033a8:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
801033ab:	e8 81 fe ff ff       	call   80103231 <myproc>
801033b0:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
801033b2:	8b 00                	mov    (%eax),%eax
  if(n > 0){
801033b4:	85 f6                	test   %esi,%esi
801033b6:	7f 21                	jg     801033d9 <growproc+0x36>
  } else if(n < 0){
801033b8:	85 f6                	test   %esi,%esi
801033ba:	79 33                	jns    801033ef <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
801033bc:	83 ec 04             	sub    $0x4,%esp
801033bf:	01 c6                	add    %eax,%esi
801033c1:	56                   	push   %esi
801033c2:	50                   	push   %eax
801033c3:	ff 73 04             	pushl  0x4(%ebx)
801033c6:	e8 36 32 00 00       	call   80106601 <deallocuvm>
801033cb:	83 c4 10             	add    $0x10,%esp
801033ce:	85 c0                	test   %eax,%eax
801033d0:	75 1d                	jne    801033ef <growproc+0x4c>
      return -1;
801033d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801033d7:	eb 29                	jmp    80103402 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
801033d9:	83 ec 04             	sub    $0x4,%esp
801033dc:	01 c6                	add    %eax,%esi
801033de:	56                   	push   %esi
801033df:	50                   	push   %eax
801033e0:	ff 73 04             	pushl  0x4(%ebx)
801033e3:	e8 ab 32 00 00       	call   80106693 <allocuvm>
801033e8:	83 c4 10             	add    $0x10,%esp
801033eb:	85 c0                	test   %eax,%eax
801033ed:	74 1a                	je     80103409 <growproc+0x66>
  curproc->sz = sz;
801033ef:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801033f1:	83 ec 0c             	sub    $0xc,%esp
801033f4:	53                   	push   %ebx
801033f5:	e8 e6 2f 00 00       	call   801063e0 <switchuvm>
  return 0;
801033fa:	83 c4 10             	add    $0x10,%esp
801033fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103402:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103405:	5b                   	pop    %ebx
80103406:	5e                   	pop    %esi
80103407:	5d                   	pop    %ebp
80103408:	c3                   	ret    
      return -1;
80103409:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010340e:	eb f2                	jmp    80103402 <growproc+0x5f>

80103410 <sched>:
{
80103410:	55                   	push   %ebp
80103411:	89 e5                	mov    %esp,%ebp
80103413:	56                   	push   %esi
80103414:	53                   	push   %ebx
  struct proc *p = myproc();
80103415:	e8 17 fe ff ff       	call   80103231 <myproc>
8010341a:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
8010341c:	83 ec 0c             	sub    $0xc,%esp
8010341f:	68 40 2d 11 80       	push   $0x80112d40
80103424:	e8 99 0c 00 00       	call   801040c2 <holding>
80103429:	83 c4 10             	add    $0x10,%esp
8010342c:	85 c0                	test   %eax,%eax
8010342e:	74 4f                	je     8010347f <sched+0x6f>
  if(mycpu()->ncli != 1)
80103430:	e8 85 fd ff ff       	call   801031ba <mycpu>
80103435:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
8010343c:	75 4e                	jne    8010348c <sched+0x7c>
  if(p->state == RUNNING)
8010343e:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103442:	74 55                	je     80103499 <sched+0x89>
80103444:	9c                   	pushf  
80103445:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103446:	f6 c4 02             	test   $0x2,%ah
80103449:	75 5b                	jne    801034a6 <sched+0x96>
  intena = mycpu()->intena;
8010344b:	e8 6a fd ff ff       	call   801031ba <mycpu>
80103450:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103456:	e8 5f fd ff ff       	call   801031ba <mycpu>
8010345b:	83 ec 08             	sub    $0x8,%esp
8010345e:	ff 70 04             	pushl  0x4(%eax)
80103461:	83 c3 1c             	add    $0x1c,%ebx
80103464:	53                   	push   %ebx
80103465:	e8 fe 0e 00 00       	call   80104368 <swtch>
  mycpu()->intena = intena;
8010346a:	e8 4b fd ff ff       	call   801031ba <mycpu>
8010346f:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
80103475:	83 c4 10             	add    $0x10,%esp
80103478:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010347b:	5b                   	pop    %ebx
8010347c:	5e                   	pop    %esi
8010347d:	5d                   	pop    %ebp
8010347e:	c3                   	ret    
    panic("sched ptable.lock");
8010347f:	83 ec 0c             	sub    $0xc,%esp
80103482:	68 d0 6f 10 80       	push   $0x80106fd0
80103487:	e8 bc ce ff ff       	call   80100348 <panic>
    panic("sched locks");
8010348c:	83 ec 0c             	sub    $0xc,%esp
8010348f:	68 e2 6f 10 80       	push   $0x80106fe2
80103494:	e8 af ce ff ff       	call   80100348 <panic>
    panic("sched running");
80103499:	83 ec 0c             	sub    $0xc,%esp
8010349c:	68 ee 6f 10 80       	push   $0x80106fee
801034a1:	e8 a2 ce ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801034a6:	83 ec 0c             	sub    $0xc,%esp
801034a9:	68 fc 6f 10 80       	push   $0x80106ffc
801034ae:	e8 95 ce ff ff       	call   80100348 <panic>

801034b3 <exit>:
{
801034b3:	55                   	push   %ebp
801034b4:	89 e5                	mov    %esp,%ebp
801034b6:	56                   	push   %esi
801034b7:	53                   	push   %ebx
  struct proc *curproc = myproc();
801034b8:	e8 74 fd ff ff       	call   80103231 <myproc>
  if(curproc == initproc)
801034bd:	39 05 b8 a5 10 80    	cmp    %eax,0x8010a5b8
801034c3:	74 09                	je     801034ce <exit+0x1b>
801034c5:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
801034c7:	bb 00 00 00 00       	mov    $0x0,%ebx
801034cc:	eb 10                	jmp    801034de <exit+0x2b>
    panic("init exiting");
801034ce:	83 ec 0c             	sub    $0xc,%esp
801034d1:	68 10 70 10 80       	push   $0x80107010
801034d6:	e8 6d ce ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
801034db:	83 c3 01             	add    $0x1,%ebx
801034de:	83 fb 0f             	cmp    $0xf,%ebx
801034e1:	7f 1e                	jg     80103501 <exit+0x4e>
    if(curproc->ofile[fd]){
801034e3:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801034e7:	85 c0                	test   %eax,%eax
801034e9:	74 f0                	je     801034db <exit+0x28>
      fileclose(curproc->ofile[fd]);
801034eb:	83 ec 0c             	sub    $0xc,%esp
801034ee:	50                   	push   %eax
801034ef:	e8 df d7 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
801034f4:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
801034fb:	00 
801034fc:	83 c4 10             	add    $0x10,%esp
801034ff:	eb da                	jmp    801034db <exit+0x28>
  begin_op();
80103501:	e8 a8 f2 ff ff       	call   801027ae <begin_op>
  iput(curproc->cwd);
80103506:	83 ec 0c             	sub    $0xc,%esp
80103509:	ff 76 68             	pushl  0x68(%esi)
8010350c:	e8 77 e1 ff ff       	call   80101688 <iput>
  end_op();
80103511:	e8 12 f3 ff ff       	call   80102828 <end_op>
  curproc->cwd = 0;
80103516:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
8010351d:	c7 04 24 40 2d 11 80 	movl   $0x80112d40,(%esp)
80103524:	e8 d9 0b 00 00       	call   80104102 <acquire>
  wakeup1(curproc->parent);
80103529:	8b 46 14             	mov    0x14(%esi),%eax
8010352c:	e8 05 fb ff ff       	call   80103036 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103531:	83 c4 10             	add    $0x10,%esp
80103534:	bb 74 2d 11 80       	mov    $0x80112d74,%ebx
80103539:	eb 06                	jmp    80103541 <exit+0x8e>
8010353b:	81 c3 a8 00 00 00    	add    $0xa8,%ebx
80103541:	81 fb 74 57 11 80    	cmp    $0x80115774,%ebx
80103547:	73 1a                	jae    80103563 <exit+0xb0>
    if(p->parent == curproc){
80103549:	39 73 14             	cmp    %esi,0x14(%ebx)
8010354c:	75 ed                	jne    8010353b <exit+0x88>
      p->parent = initproc;
8010354e:	a1 b8 a5 10 80       	mov    0x8010a5b8,%eax
80103553:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103556:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010355a:	75 df                	jne    8010353b <exit+0x88>
        wakeup1(initproc);
8010355c:	e8 d5 fa ff ff       	call   80103036 <wakeup1>
80103561:	eb d8                	jmp    8010353b <exit+0x88>
  curproc->state = ZOMBIE;
80103563:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
8010356a:	e8 a1 fe ff ff       	call   80103410 <sched>
  panic("zombie exit");
8010356f:	83 ec 0c             	sub    $0xc,%esp
80103572:	68 1d 70 10 80       	push   $0x8010701d
80103577:	e8 cc cd ff ff       	call   80100348 <panic>

8010357c <yield>:
{
8010357c:	55                   	push   %ebp
8010357d:	89 e5                	mov    %esp,%ebp
8010357f:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80103582:	68 40 2d 11 80       	push   $0x80112d40
80103587:	e8 76 0b 00 00       	call   80104102 <acquire>
  myproc()->state = RUNNABLE;
8010358c:	e8 a0 fc ff ff       	call   80103231 <myproc>
80103591:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103598:	e8 73 fe ff ff       	call   80103410 <sched>
  release(&ptable.lock);
8010359d:	c7 04 24 40 2d 11 80 	movl   $0x80112d40,(%esp)
801035a4:	e8 be 0b 00 00       	call   80104167 <release>
}
801035a9:	83 c4 10             	add    $0x10,%esp
801035ac:	c9                   	leave  
801035ad:	c3                   	ret    

801035ae <sleep>:
{
801035ae:	55                   	push   %ebp
801035af:	89 e5                	mov    %esp,%ebp
801035b1:	56                   	push   %esi
801035b2:	53                   	push   %ebx
801035b3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801035b6:	e8 76 fc ff ff       	call   80103231 <myproc>
  if(p == 0)
801035bb:	85 c0                	test   %eax,%eax
801035bd:	74 66                	je     80103625 <sleep+0x77>
801035bf:	89 c6                	mov    %eax,%esi
  if(lk == 0)
801035c1:	85 db                	test   %ebx,%ebx
801035c3:	74 6d                	je     80103632 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
801035c5:	81 fb 40 2d 11 80    	cmp    $0x80112d40,%ebx
801035cb:	74 18                	je     801035e5 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
801035cd:	83 ec 0c             	sub    $0xc,%esp
801035d0:	68 40 2d 11 80       	push   $0x80112d40
801035d5:	e8 28 0b 00 00       	call   80104102 <acquire>
    release(lk);
801035da:	89 1c 24             	mov    %ebx,(%esp)
801035dd:	e8 85 0b 00 00       	call   80104167 <release>
801035e2:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
801035e5:	8b 45 08             	mov    0x8(%ebp),%eax
801035e8:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
801035eb:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
801035f2:	e8 19 fe ff ff       	call   80103410 <sched>
  p->chan = 0;
801035f7:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
801035fe:	81 fb 40 2d 11 80    	cmp    $0x80112d40,%ebx
80103604:	74 18                	je     8010361e <sleep+0x70>
    release(&ptable.lock);
80103606:	83 ec 0c             	sub    $0xc,%esp
80103609:	68 40 2d 11 80       	push   $0x80112d40
8010360e:	e8 54 0b 00 00       	call   80104167 <release>
    acquire(lk);
80103613:	89 1c 24             	mov    %ebx,(%esp)
80103616:	e8 e7 0a 00 00       	call   80104102 <acquire>
8010361b:	83 c4 10             	add    $0x10,%esp
}
8010361e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103621:	5b                   	pop    %ebx
80103622:	5e                   	pop    %esi
80103623:	5d                   	pop    %ebp
80103624:	c3                   	ret    
    panic("sleep");
80103625:	83 ec 0c             	sub    $0xc,%esp
80103628:	68 29 70 10 80       	push   $0x80107029
8010362d:	e8 16 cd ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103632:	83 ec 0c             	sub    $0xc,%esp
80103635:	68 2f 70 10 80       	push   $0x8010702f
8010363a:	e8 09 cd ff ff       	call   80100348 <panic>

8010363f <wait>:
{
8010363f:	55                   	push   %ebp
80103640:	89 e5                	mov    %esp,%ebp
80103642:	56                   	push   %esi
80103643:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103644:	e8 e8 fb ff ff       	call   80103231 <myproc>
80103649:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
8010364b:	83 ec 0c             	sub    $0xc,%esp
8010364e:	68 40 2d 11 80       	push   $0x80112d40
80103653:	e8 aa 0a 00 00       	call   80104102 <acquire>
80103658:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
8010365b:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103660:	bb 74 2d 11 80       	mov    $0x80112d74,%ebx
80103665:	eb 5e                	jmp    801036c5 <wait+0x86>
        pid = p->pid;
80103667:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
8010366a:	83 ec 0c             	sub    $0xc,%esp
8010366d:	ff 73 08             	pushl  0x8(%ebx)
80103670:	e8 2f e9 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
80103675:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
8010367c:	83 c4 04             	add    $0x4,%esp
8010367f:	ff 73 04             	pushl  0x4(%ebx)
80103682:	e8 f6 30 00 00       	call   8010677d <freevm>
        p->pid = 0;
80103687:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
8010368e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103695:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103699:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801036a0:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801036a7:	c7 04 24 40 2d 11 80 	movl   $0x80112d40,(%esp)
801036ae:	e8 b4 0a 00 00       	call   80104167 <release>
        return pid;
801036b3:	83 c4 10             	add    $0x10,%esp
}
801036b6:	89 f0                	mov    %esi,%eax
801036b8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801036bb:	5b                   	pop    %ebx
801036bc:	5e                   	pop    %esi
801036bd:	5d                   	pop    %ebp
801036be:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801036bf:	81 c3 a8 00 00 00    	add    $0xa8,%ebx
801036c5:	81 fb 74 57 11 80    	cmp    $0x80115774,%ebx
801036cb:	73 12                	jae    801036df <wait+0xa0>
      if(p->parent != curproc)
801036cd:	39 73 14             	cmp    %esi,0x14(%ebx)
801036d0:	75 ed                	jne    801036bf <wait+0x80>
      if(p->state == ZOMBIE){
801036d2:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801036d6:	74 8f                	je     80103667 <wait+0x28>
      havekids = 1;
801036d8:	b8 01 00 00 00       	mov    $0x1,%eax
801036dd:	eb e0                	jmp    801036bf <wait+0x80>
    if(!havekids || curproc->killed){
801036df:	85 c0                	test   %eax,%eax
801036e1:	74 06                	je     801036e9 <wait+0xaa>
801036e3:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
801036e7:	74 17                	je     80103700 <wait+0xc1>
      release(&ptable.lock);
801036e9:	83 ec 0c             	sub    $0xc,%esp
801036ec:	68 40 2d 11 80       	push   $0x80112d40
801036f1:	e8 71 0a 00 00       	call   80104167 <release>
      return -1;
801036f6:	83 c4 10             	add    $0x10,%esp
801036f9:	be ff ff ff ff       	mov    $0xffffffff,%esi
801036fe:	eb b6                	jmp    801036b6 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103700:	83 ec 08             	sub    $0x8,%esp
80103703:	68 40 2d 11 80       	push   $0x80112d40
80103708:	56                   	push   %esi
80103709:	e8 a0 fe ff ff       	call   801035ae <sleep>
    havekids = 0;
8010370e:	83 c4 10             	add    $0x10,%esp
80103711:	e9 45 ff ff ff       	jmp    8010365b <wait+0x1c>

80103716 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103716:	55                   	push   %ebp
80103717:	89 e5                	mov    %esp,%ebp
80103719:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
8010371c:	68 40 2d 11 80       	push   $0x80112d40
80103721:	e8 dc 09 00 00       	call   80104102 <acquire>
  wakeup1(chan);
80103726:	8b 45 08             	mov    0x8(%ebp),%eax
80103729:	e8 08 f9 ff ff       	call   80103036 <wakeup1>
  release(&ptable.lock);
8010372e:	c7 04 24 40 2d 11 80 	movl   $0x80112d40,(%esp)
80103735:	e8 2d 0a 00 00       	call   80104167 <release>
}
8010373a:	83 c4 10             	add    $0x10,%esp
8010373d:	c9                   	leave  
8010373e:	c3                   	ret    

8010373f <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
8010373f:	55                   	push   %ebp
80103740:	89 e5                	mov    %esp,%ebp
80103742:	53                   	push   %ebx
80103743:	83 ec 10             	sub    $0x10,%esp
80103746:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103749:	68 40 2d 11 80       	push   $0x80112d40
8010374e:	e8 af 09 00 00       	call   80104102 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103753:	83 c4 10             	add    $0x10,%esp
80103756:	b8 74 2d 11 80       	mov    $0x80112d74,%eax
8010375b:	3d 74 57 11 80       	cmp    $0x80115774,%eax
80103760:	73 3c                	jae    8010379e <kill+0x5f>
    if(p->pid == pid){
80103762:	39 58 10             	cmp    %ebx,0x10(%eax)
80103765:	74 07                	je     8010376e <kill+0x2f>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103767:	05 a8 00 00 00       	add    $0xa8,%eax
8010376c:	eb ed                	jmp    8010375b <kill+0x1c>
      p->killed = 1;
8010376e:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103775:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103779:	74 1a                	je     80103795 <kill+0x56>
        p->state = RUNNABLE;
      release(&ptable.lock);
8010377b:	83 ec 0c             	sub    $0xc,%esp
8010377e:	68 40 2d 11 80       	push   $0x80112d40
80103783:	e8 df 09 00 00       	call   80104167 <release>
      return 0;
80103788:	83 c4 10             	add    $0x10,%esp
8010378b:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103790:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103793:	c9                   	leave  
80103794:	c3                   	ret    
        p->state = RUNNABLE;
80103795:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
8010379c:	eb dd                	jmp    8010377b <kill+0x3c>
  release(&ptable.lock);
8010379e:	83 ec 0c             	sub    $0xc,%esp
801037a1:	68 40 2d 11 80       	push   $0x80112d40
801037a6:	e8 bc 09 00 00       	call   80104167 <release>
  return -1;
801037ab:	83 c4 10             	add    $0x10,%esp
801037ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801037b3:	eb db                	jmp    80103790 <kill+0x51>

801037b5 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801037b5:	55                   	push   %ebp
801037b6:	89 e5                	mov    %esp,%ebp
801037b8:	56                   	push   %esi
801037b9:	53                   	push   %ebx
801037ba:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037bd:	bb 74 2d 11 80       	mov    $0x80112d74,%ebx
801037c2:	eb 36                	jmp    801037fa <procdump+0x45>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
801037c4:	b8 40 70 10 80       	mov    $0x80107040,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
801037c9:	8d 53 6c             	lea    0x6c(%ebx),%edx
801037cc:	52                   	push   %edx
801037cd:	50                   	push   %eax
801037ce:	ff 73 10             	pushl  0x10(%ebx)
801037d1:	68 44 70 10 80       	push   $0x80107044
801037d6:	e8 30 ce ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
801037db:	83 c4 10             	add    $0x10,%esp
801037de:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
801037e2:	74 3c                	je     80103820 <procdump+0x6b>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801037e4:	83 ec 0c             	sub    $0xc,%esp
801037e7:	68 87 74 10 80       	push   $0x80107487
801037ec:	e8 1a ce ff ff       	call   8010060b <cprintf>
801037f1:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037f4:	81 c3 a8 00 00 00    	add    $0xa8,%ebx
801037fa:	81 fb 74 57 11 80    	cmp    $0x80115774,%ebx
80103800:	73 61                	jae    80103863 <procdump+0xae>
    if(p->state == UNUSED)
80103802:	8b 43 0c             	mov    0xc(%ebx),%eax
80103805:	85 c0                	test   %eax,%eax
80103807:	74 eb                	je     801037f4 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103809:	83 f8 05             	cmp    $0x5,%eax
8010380c:	77 b6                	ja     801037c4 <procdump+0xf>
8010380e:	8b 04 85 6c 71 10 80 	mov    -0x7fef8e94(,%eax,4),%eax
80103815:	85 c0                	test   %eax,%eax
80103817:	75 b0                	jne    801037c9 <procdump+0x14>
      state = "???";
80103819:	b8 40 70 10 80       	mov    $0x80107040,%eax
8010381e:	eb a9                	jmp    801037c9 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103820:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103823:	8b 40 0c             	mov    0xc(%eax),%eax
80103826:	83 c0 08             	add    $0x8,%eax
80103829:	83 ec 08             	sub    $0x8,%esp
8010382c:	8d 55 d0             	lea    -0x30(%ebp),%edx
8010382f:	52                   	push   %edx
80103830:	50                   	push   %eax
80103831:	e8 ab 07 00 00       	call   80103fe1 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103836:	83 c4 10             	add    $0x10,%esp
80103839:	be 00 00 00 00       	mov    $0x0,%esi
8010383e:	eb 14                	jmp    80103854 <procdump+0x9f>
        cprintf(" %p", pc[i]);
80103840:	83 ec 08             	sub    $0x8,%esp
80103843:	50                   	push   %eax
80103844:	68 81 6a 10 80       	push   $0x80106a81
80103849:	e8 bd cd ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
8010384e:	83 c6 01             	add    $0x1,%esi
80103851:	83 c4 10             	add    $0x10,%esp
80103854:	83 fe 09             	cmp    $0x9,%esi
80103857:	7f 8b                	jg     801037e4 <procdump+0x2f>
80103859:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
8010385d:	85 c0                	test   %eax,%eax
8010385f:	75 df                	jne    80103840 <procdump+0x8b>
80103861:	eb 81                	jmp    801037e4 <procdump+0x2f>
  }
}
80103863:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103866:	5b                   	pop    %ebx
80103867:	5e                   	pop    %esi
80103868:	5d                   	pop    %ebp
80103869:	c3                   	ret    

8010386a <setpri>:

// This sets the priority of the specified PID to pri
// return -1 if pri or PID are invalid
int
setpri(int PID, int pri){
8010386a:	55                   	push   %ebp
8010386b:	89 e5                	mov    %esp,%ebp
8010386d:	56                   	push   %esi
8010386e:	53                   	push   %ebx
8010386f:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103872:	8b 75 0c             	mov    0xc(%ebp),%esi

    if (pri < 0 || pri > 3) {
80103875:	83 fe 03             	cmp    $0x3,%esi
80103878:	76 0c                	jbe    80103886 <setpri+0x1c>
        position++;
    }

    release(&ptable.lock);
    return -1;
}
8010387a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010387f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103882:	5b                   	pop    %ebx
80103883:	5e                   	pop    %esi
80103884:	5d                   	pop    %ebp
80103885:	c3                   	ret    
    acquire(&ptable.lock);
80103886:	83 ec 0c             	sub    $0xc,%esp
80103889:	68 40 2d 11 80       	push   $0x80112d40
8010388e:	e8 6f 08 00 00       	call   80104102 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103893:	83 c4 10             	add    $0x10,%esp
    int position = 0;
80103896:	ba 00 00 00 00       	mov    $0x0,%edx
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010389b:	b8 74 2d 11 80       	mov    $0x80112d74,%eax
801038a0:	eb 08                	jmp    801038aa <setpri+0x40>
        position++;
801038a2:	83 c2 01             	add    $0x1,%edx
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038a5:	05 a8 00 00 00       	add    $0xa8,%eax
801038aa:	3d 74 57 11 80       	cmp    $0x80115774,%eax
801038af:	73 26                	jae    801038d7 <setpri+0x6d>
        if( p->pid == PID ){
801038b1:	39 58 10             	cmp    %ebx,0x10(%eax)
801038b4:	75 ec                	jne    801038a2 <setpri+0x38>
            p->priority = pri;
801038b6:	89 70 7c             	mov    %esi,0x7c(%eax)
            ptable.inuse[position] = 1;
801038b9:	c7 04 95 74 57 11 80 	movl   $0x1,-0x7feea88c(,%edx,4)
801038c0:	01 00 00 00 
            ptable.pid[position] = p->pid;
801038c4:	8b 48 10             	mov    0x10(%eax),%ecx
801038c7:	89 0c 95 74 58 11 80 	mov    %ecx,-0x7feea78c(,%edx,4)
            ptable.priority[position] = pri;
801038ce:	89 34 95 74 59 11 80 	mov    %esi,-0x7feea68c(,%edx,4)
801038d5:	eb cb                	jmp    801038a2 <setpri+0x38>
    release(&ptable.lock);
801038d7:	83 ec 0c             	sub    $0xc,%esp
801038da:	68 40 2d 11 80       	push   $0x80112d40
801038df:	e8 83 08 00 00       	call   80104167 <release>
    return -1;
801038e4:	83 c4 10             	add    $0x10,%esp
801038e7:	eb 91                	jmp    8010387a <setpri+0x10>

801038e9 <getpri>:

// returns the current priority of the specified PID.
// If the PID is not valid, it returns -1
int
getpri(int PID){
801038e9:	55                   	push   %ebp
801038ea:	89 e5                	mov    %esp,%ebp
801038ec:	56                   	push   %esi
801038ed:	53                   	push   %ebx
801038ee:	8b 75 08             	mov    0x8(%ebp),%esi
    struct proc *p;
    acquire(&ptable.lock);
801038f1:	83 ec 0c             	sub    $0xc,%esp
801038f4:	68 40 2d 11 80       	push   $0x80112d40
801038f9:	e8 04 08 00 00       	call   80104102 <acquire>

    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
801038fe:	83 c4 10             	add    $0x10,%esp
80103901:	bb 74 2d 11 80       	mov    $0x80112d74,%ebx
80103906:	81 fb 74 57 11 80    	cmp    $0x80115774,%ebx
8010390c:	73 27                	jae    80103935 <getpri+0x4c>
        if (p->pid == PID) {
8010390e:	39 73 10             	cmp    %esi,0x10(%ebx)
80103911:	74 08                	je     8010391b <getpri+0x32>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
80103913:	81 c3 a8 00 00 00    	add    $0xa8,%ebx
80103919:	eb eb                	jmp    80103906 <getpri+0x1d>
            release(&ptable.lock);
8010391b:	83 ec 0c             	sub    $0xc,%esp
8010391e:	68 40 2d 11 80       	push   $0x80112d40
80103923:	e8 3f 08 00 00       	call   80104167 <release>
            return p->priority;
80103928:	8b 43 7c             	mov    0x7c(%ebx),%eax
8010392b:	83 c4 10             	add    $0x10,%esp
        }
    }
    release(&ptable.lock);
    return -1;
}
8010392e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103931:	5b                   	pop    %ebx
80103932:	5e                   	pop    %esi
80103933:	5d                   	pop    %ebp
80103934:	c3                   	ret    
    release(&ptable.lock);
80103935:	83 ec 0c             	sub    $0xc,%esp
80103938:	68 40 2d 11 80       	push   $0x80112d40
8010393d:	e8 25 08 00 00       	call   80104167 <release>
    return -1;
80103942:	83 c4 10             	add    $0x10,%esp
80103945:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010394a:	eb e2                	jmp    8010392e <getpri+0x45>

8010394c <printQueue>:
    release(&ptable.lock);
    printQueue();
    return pid;
}

void printQueue() {
8010394c:	55                   	push   %ebp
8010394d:	89 e5                	mov    %esp,%ebp
8010394f:	56                   	push   %esi
80103950:	53                   	push   %ebx
    // helper method for printing the current pqueue
    struct proc *p;

    for (int i = 0; i < 4; i++){
80103951:	be 00 00 00 00       	mov    $0x0,%esi
80103956:	eb 35                	jmp    8010398d <printQueue+0x41>
        for (p = priorityQueue[i].head; p != NULL;){
            cprintf("PID: %d Proc: %p  Next: %p Head: %p Tail: %p\n", p->pid, p, p->next, priorityQueue[i].head, priorityQueue[i].tail);
80103958:	83 ec 08             	sub    $0x8,%esp
8010395b:	ff 34 f5 24 2d 11 80 	pushl  -0x7feed2dc(,%esi,8)
80103962:	ff 34 f5 20 2d 11 80 	pushl  -0x7feed2e0(,%esi,8)
80103969:	ff b3 80 00 00 00    	pushl  0x80(%ebx)
8010396f:	53                   	push   %ebx
80103970:	ff 73 10             	pushl  0x10(%ebx)
80103973:	68 18 71 10 80       	push   $0x80107118
80103978:	e8 8e cc ff ff       	call   8010060b <cprintf>
//            cprintf("%d\n", p->pid);
            p = p->next;
8010397d:	8b 9b 80 00 00 00    	mov    0x80(%ebx),%ebx
80103983:	83 c4 20             	add    $0x20,%esp
        for (p = priorityQueue[i].head; p != NULL;){
80103986:	85 db                	test   %ebx,%ebx
80103988:	75 ce                	jne    80103958 <printQueue+0xc>
    for (int i = 0; i < 4; i++){
8010398a:	83 c6 01             	add    $0x1,%esi
8010398d:	83 fe 03             	cmp    $0x3,%esi
80103990:	7f 09                	jg     8010399b <printQueue+0x4f>
        for (p = priorityQueue[i].head; p != NULL;){
80103992:	8b 1c f5 20 2d 11 80 	mov    -0x7feed2e0(,%esi,8),%ebx
80103999:	eb eb                	jmp    80103986 <printQueue+0x3a>
        }
    }
}
8010399b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010399e:	5b                   	pop    %ebx
8010399f:	5e                   	pop    %esi
801039a0:	5d                   	pop    %ebp
801039a1:	c3                   	ret    

801039a2 <scheduler>:
{
801039a2:	55                   	push   %ebp
801039a3:	89 e5                	mov    %esp,%ebp
801039a5:	57                   	push   %edi
801039a6:	56                   	push   %esi
801039a7:	53                   	push   %ebx
801039a8:	83 ec 1c             	sub    $0x1c,%esp
    struct cpu *c = mycpu();
801039ab:	e8 0a f8 ff ff       	call   801031ba <mycpu>
801039b0:	89 45 e0             	mov    %eax,-0x20(%ebp)
    c->proc = 0;
801039b3:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801039ba:	00 00 00 
801039bd:	e9 62 02 00 00       	jmp    80103c24 <scheduler+0x282>
                    c->proc = p;
801039c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801039c5:	89 98 ac 00 00 00    	mov    %ebx,0xac(%eax)
                    switchuvm(p);
801039cb:	83 ec 0c             	sub    $0xc,%esp
801039ce:	53                   	push   %ebx
801039cf:	e8 0c 2a 00 00       	call   801063e0 <switchuvm>
                    p->state = RUNNING;
801039d4:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
                    swtch(&(c->scheduler), p->context);
801039db:	83 c4 08             	add    $0x8,%esp
801039de:	ff 73 1c             	pushl  0x1c(%ebx)
801039e1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801039e4:	83 c0 04             	add    $0x4,%eax
801039e7:	50                   	push   %eax
801039e8:	e8 7b 09 00 00       	call   80104368 <swtch>
                    switchkvm();
801039ed:	e8 dc 29 00 00       	call   801063ce <switchkvm>
                    p->ticks++;
801039f2:	8b 83 84 00 00 00    	mov    0x84(%ebx),%eax
801039f8:	83 c0 01             	add    $0x1,%eax
801039fb:	89 83 84 00 00 00    	mov    %eax,0x84(%ebx)
                    p->agg_ticks[priority]++;
80103a01:	8d 4e 20             	lea    0x20(%esi),%ecx
80103a04:	8b 54 8b 08          	mov    0x8(%ebx,%ecx,4),%edx
80103a08:	83 c2 01             	add    $0x1,%edx
80103a0b:	89 54 8b 08          	mov    %edx,0x8(%ebx,%ecx,4)
                    cprintf("PID: %d PRIOR: %d Total Ticks: %d\n", p->pid, p->priority, p->ticks);
80103a0f:	50                   	push   %eax
80103a10:	ff 73 7c             	pushl  0x7c(%ebx)
80103a13:	ff 73 10             	pushl  0x10(%ebx)
80103a16:	68 48 71 10 80       	push   $0x80107148
80103a1b:	e8 eb cb ff ff       	call   8010060b <cprintf>
                    if (p->ticks >= timeslices[priority] && priority == 3){
80103a20:	83 c4 20             	add    $0x20,%esp
80103a23:	8b 04 b5 08 a0 10 80 	mov    -0x7fef5ff8(,%esi,4),%eax
80103a2a:	39 83 84 00 00 00    	cmp    %eax,0x84(%ebx)
80103a30:	7c 05                	jl     80103a37 <scheduler+0x95>
80103a32:	83 fe 03             	cmp    $0x3,%esi
80103a35:	74 2b                	je     80103a62 <scheduler+0xc0>
                    c->proc = 0;
80103a37:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103a3a:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80103a41:	00 00 00 
        for (i = 3; i >= 0; i--) {
80103a44:	83 ef 01             	sub    $0x1,%edi
80103a47:	85 ff                	test   %edi,%edi
80103a49:	0f 88 c5 01 00 00    	js     80103c14 <scheduler+0x272>
            for (p = priorityQueue[i].head; p != NULL;) {
80103a4f:	8b 1c fd 20 2d 11 80 	mov    -0x7feed2e0(,%edi,8),%ebx
            struct proc *prevProc = NULL;
80103a56:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
            for (p = priorityQueue[i].head; p != NULL;) {
80103a5d:	e9 63 01 00 00       	jmp    80103bc5 <scheduler+0x223>
                        if (priorityQueue[i].head == priorityQueue[i].tail) {
80103a62:	8b 04 fd 20 2d 11 80 	mov    -0x7feed2e0(,%edi,8),%eax
80103a69:	3b 04 fd 24 2d 11 80 	cmp    -0x7feed2dc(,%edi,8),%eax
80103a70:	74 74                	je     80103ae6 <scheduler+0x144>
                        } else if (priorityQueue[i].head == p) {
80103a72:	39 d8                	cmp    %ebx,%eax
80103a74:	0f 84 83 00 00 00    	je     80103afd <scheduler+0x15b>
                            prevProc->next = p->next;
80103a7a:	8b 83 80 00 00 00    	mov    0x80(%ebx),%eax
80103a80:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103a83:	89 81 80 00 00 00    	mov    %eax,0x80(%ecx)
                            if (priorityQueue[priority].tail == p) {
80103a89:	39 1c f5 24 2d 11 80 	cmp    %ebx,-0x7feed2dc(,%esi,8)
80103a90:	0f 84 8e 00 00 00    	je     80103b24 <scheduler+0x182>
                        if (priorityQueue[priority].head == NULL && priorityQueue[priority].tail == NULL){
80103a96:	83 3c f5 20 2d 11 80 	cmpl   $0x0,-0x7feed2e0(,%esi,8)
80103a9d:	00 
80103a9e:	0f 84 a6 00 00 00    	je     80103b4a <scheduler+0x1a8>
                            priorityQueue[priority].tail->next = p;
80103aa4:	8b 04 f5 24 2d 11 80 	mov    -0x7feed2dc(,%esi,8),%eax
80103aab:	89 98 80 00 00 00    	mov    %ebx,0x80(%eax)
                            priorityQueue[priority].tail = p;
80103ab1:	89 1c f5 24 2d 11 80 	mov    %ebx,-0x7feed2dc(,%esi,8)
                            cprintf("%s\n", "HERE6");
80103ab8:	83 ec 08             	sub    $0x8,%esp
80103abb:	68 69 70 10 80       	push   $0x80107069
80103ac0:	68 53 70 10 80       	push   $0x80107053
80103ac5:	e8 41 cb ff ff       	call   8010060b <cprintf>
80103aca:	83 c4 10             	add    $0x10,%esp
                        p->ticks = 0;
80103acd:	c7 83 84 00 00 00 00 	movl   $0x0,0x84(%ebx)
80103ad4:	00 00 00 
                        p->next = NULL;
80103ad7:	c7 83 80 00 00 00 00 	movl   $0x0,0x80(%ebx)
80103ade:	00 00 00 
80103ae1:	e9 51 ff ff ff       	jmp    80103a37 <scheduler+0x95>
                            cprintf("%s\n", "HERE1");
80103ae6:	83 ec 08             	sub    $0x8,%esp
80103ae9:	68 4d 70 10 80       	push   $0x8010704d
80103aee:	68 53 70 10 80       	push   $0x80107053
80103af3:	e8 13 cb ff ff       	call   8010060b <cprintf>
80103af8:	83 c4 10             	add    $0x10,%esp
80103afb:	eb 99                	jmp    80103a96 <scheduler+0xf4>
                            priorityQueue[i].head = p->next;
80103afd:	8b 83 80 00 00 00    	mov    0x80(%ebx),%eax
80103b03:	89 04 fd 20 2d 11 80 	mov    %eax,-0x7feed2e0(,%edi,8)
                            cprintf("%s\n", "HERE2");
80103b0a:	83 ec 08             	sub    $0x8,%esp
80103b0d:	68 57 70 10 80       	push   $0x80107057
80103b12:	68 53 70 10 80       	push   $0x80107053
80103b17:	e8 ef ca ff ff       	call   8010060b <cprintf>
80103b1c:	83 c4 10             	add    $0x10,%esp
80103b1f:	e9 72 ff ff ff       	jmp    80103a96 <scheduler+0xf4>
                                priorityQueue[priority].tail = prevProc;
80103b24:	89 0c f5 24 2d 11 80 	mov    %ecx,-0x7feed2dc(,%esi,8)
                                cprintf("%s\n", "HERE3");
80103b2b:	83 ec 08             	sub    $0x8,%esp
80103b2e:	68 5d 70 10 80       	push   $0x8010705d
80103b33:	68 53 70 10 80       	push   $0x80107053
80103b38:	e8 ce ca ff ff       	call   8010060b <cprintf>
                                printQueue();
80103b3d:	e8 0a fe ff ff       	call   8010394c <printQueue>
80103b42:	83 c4 10             	add    $0x10,%esp
80103b45:	e9 4c ff ff ff       	jmp    80103a96 <scheduler+0xf4>
                        if (priorityQueue[priority].head == NULL && priorityQueue[priority].tail == NULL){
80103b4a:	83 3c f5 24 2d 11 80 	cmpl   $0x0,-0x7feed2dc(,%esi,8)
80103b51:	00 
80103b52:	0f 85 4c ff ff ff    	jne    80103aa4 <scheduler+0x102>
                            priorityQueue[priority].head = p;
80103b58:	89 1c f5 20 2d 11 80 	mov    %ebx,-0x7feed2e0(,%esi,8)
                            priorityQueue[priority].tail = p;
80103b5f:	89 1c f5 24 2d 11 80 	mov    %ebx,-0x7feed2dc(,%esi,8)
                            cprintf("%s\n", "HERE5");
80103b66:	83 ec 08             	sub    $0x8,%esp
80103b69:	68 63 70 10 80       	push   $0x80107063
80103b6e:	68 53 70 10 80       	push   $0x80107053
80103b73:	e8 93 ca ff ff       	call   8010060b <cprintf>
80103b78:	83 c4 10             	add    $0x10,%esp
80103b7b:	e9 4d ff ff ff       	jmp    80103acd <scheduler+0x12b>
                        priorityQueue[i].head = NULL;
80103b80:	c7 04 fd 20 2d 11 80 	movl   $0x0,-0x7feed2e0(,%edi,8)
80103b87:	00 00 00 00 
                        priorityQueue[i].tail = NULL;
80103b8b:	c7 04 fd 24 2d 11 80 	movl   $0x0,-0x7feed2dc(,%edi,8)
80103b92:	00 00 00 00 
                        break;
80103b96:	e9 a9 fe ff ff       	jmp    80103a44 <scheduler+0xa2>
                       priorityQueue[i].head = priorityQueue[i].head->next;
80103b9b:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80103ba1:	89 04 fd 20 2d 11 80 	mov    %eax,-0x7feed2e0(,%edi,8)
                       p = p->next;
80103ba8:	8b 9b 80 00 00 00    	mov    0x80(%ebx),%ebx
80103bae:	eb 15                	jmp    80103bc5 <scheduler+0x223>
                            priorityQueue[priority].tail = prevProc;
80103bb0:	89 14 f5 24 2d 11 80 	mov    %edx,-0x7feed2dc(,%esi,8)
                            break;
80103bb7:	e9 88 fe ff ff       	jmp    80103a44 <scheduler+0xa2>
                    prevProc = p;
80103bbc:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
                    p = p->next;
80103bbf:	8b 9b 80 00 00 00    	mov    0x80(%ebx),%ebx
            for (p = priorityQueue[i].head; p != NULL;) {
80103bc5:	85 db                	test   %ebx,%ebx
80103bc7:	0f 84 77 fe ff ff    	je     80103a44 <scheduler+0xa2>
                int priority = p->priority;
80103bcd:	8b 73 7c             	mov    0x7c(%ebx),%esi
                if (p->state == RUNNABLE) {
80103bd0:	8b 43 0c             	mov    0xc(%ebx),%eax
80103bd3:	83 f8 03             	cmp    $0x3,%eax
80103bd6:	0f 84 e6 fd ff ff    	je     801039c2 <scheduler+0x20>
                } else if (p->state == UNUSED){
80103bdc:	85 c0                	test   %eax,%eax
80103bde:	75 dc                	jne    80103bbc <scheduler+0x21a>
                    if (priorityQueue[i].head == priorityQueue[i].tail) {
80103be0:	8b 04 fd 20 2d 11 80 	mov    -0x7feed2e0(,%edi,8),%eax
80103be7:	3b 04 fd 24 2d 11 80 	cmp    -0x7feed2dc(,%edi,8),%eax
80103bee:	74 90                	je     80103b80 <scheduler+0x1de>
                    } else if (p == priorityQueue[i].head){
80103bf0:	39 d8                	cmp    %ebx,%eax
80103bf2:	74 a7                	je     80103b9b <scheduler+0x1f9>
                        prevProc->next = p->next;
80103bf4:	8b 83 80 00 00 00    	mov    0x80(%ebx),%eax
80103bfa:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103bfd:	89 82 80 00 00 00    	mov    %eax,0x80(%edx)
                        if (priorityQueue[priority].tail == p) {
80103c03:	39 1c f5 24 2d 11 80 	cmp    %ebx,-0x7feed2dc(,%esi,8)
80103c0a:	74 a4                	je     80103bb0 <scheduler+0x20e>
                        p = p->next;
80103c0c:	8b 9b 80 00 00 00    	mov    0x80(%ebx),%ebx
80103c12:	eb b1                	jmp    80103bc5 <scheduler+0x223>
    release(&ptable.lock);
80103c14:	83 ec 0c             	sub    $0xc,%esp
80103c17:	68 40 2d 11 80       	push   $0x80112d40
80103c1c:	e8 46 05 00 00       	call   80104167 <release>
    for (;;) {
80103c21:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
80103c24:	fb                   	sti    
        acquire(&ptable.lock);
80103c25:	83 ec 0c             	sub    $0xc,%esp
80103c28:	68 40 2d 11 80       	push   $0x80112d40
80103c2d:	e8 d0 04 00 00       	call   80104102 <acquire>
        for (i = 3; i >= 0; i--) {
80103c32:	83 c4 10             	add    $0x10,%esp
80103c35:	bf 03 00 00 00       	mov    $0x3,%edi
80103c3a:	e9 08 fe ff ff       	jmp    80103a47 <scheduler+0xa5>

80103c3f <fork2>:
fork2(int pri){
80103c3f:	55                   	push   %ebp
80103c40:	89 e5                	mov    %esp,%ebp
80103c42:	57                   	push   %edi
80103c43:	56                   	push   %esi
80103c44:	53                   	push   %ebx
80103c45:	83 ec 1c             	sub    $0x1c,%esp
    if (pri < 0 || pri > 3) {
80103c48:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
80103c4c:	76 0d                	jbe    80103c5b <fork2+0x1c>
        if (pri == -1){
80103c4e:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
80103c52:	75 63                	jne    80103cb7 <fork2+0x78>
            pri = 3;
80103c54:	c7 45 08 03 00 00 00 	movl   $0x3,0x8(%ebp)
    struct proc *curproc = myproc();
80103c5b:	e8 d1 f5 ff ff       	call   80103231 <myproc>
80103c60:	89 c3                	mov    %eax,%ebx
    if((np = allocproc()) == 0){
80103c62:	e8 fd f3 ff ff       	call   80103064 <allocproc>
80103c67:	89 c7                	mov    %eax,%edi
80103c69:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80103c6c:	85 c0                	test   %eax,%eax
80103c6e:	0f 84 b5 01 00 00    	je     80103e29 <fork2+0x1ea>
    if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
80103c74:	83 ec 08             	sub    $0x8,%esp
80103c77:	ff 33                	pushl  (%ebx)
80103c79:	ff 73 04             	pushl  0x4(%ebx)
80103c7c:	e8 1d 2c 00 00       	call   8010689e <copyuvm>
80103c81:	89 47 04             	mov    %eax,0x4(%edi)
80103c84:	83 c4 10             	add    $0x10,%esp
80103c87:	85 c0                	test   %eax,%eax
80103c89:	74 31                	je     80103cbc <fork2+0x7d>
    np->sz = curproc->sz;
80103c8b:	8b 03                	mov    (%ebx),%eax
80103c8d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103c90:	89 07                	mov    %eax,(%edi)
    np->parent = curproc;
80103c92:	89 f8                	mov    %edi,%eax
80103c94:	89 5f 14             	mov    %ebx,0x14(%edi)
    *np->tf = *curproc->tf;
80103c97:	8b 73 18             	mov    0x18(%ebx),%esi
80103c9a:	8b 7f 18             	mov    0x18(%edi),%edi
80103c9d:	b9 13 00 00 00       	mov    $0x13,%ecx
80103ca2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
    np->tf->eax = 0;
80103ca4:	89 c7                	mov    %eax,%edi
80103ca6:	8b 40 18             	mov    0x18(%eax),%eax
80103ca9:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
    for(i = 0; i < NOFILE; i++)
80103cb0:	be 00 00 00 00       	mov    $0x0,%esi
80103cb5:	eb 31                	jmp    80103ce8 <fork2+0xa9>
            exit();
80103cb7:	e8 f7 f7 ff ff       	call   801034b3 <exit>
        kfree(np->kstack);
80103cbc:	83 ec 0c             	sub    $0xc,%esp
80103cbf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103cc2:	ff 73 08             	pushl  0x8(%ebx)
80103cc5:	e8 da e2 ff ff       	call   80101fa4 <kfree>
        np->kstack = 0;
80103cca:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        np->state = UNUSED;
80103cd1:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        return -1;
80103cd8:	83 c4 10             	add    $0x10,%esp
80103cdb:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103ce0:	e9 fe 00 00 00       	jmp    80103de3 <fork2+0x1a4>
    for(i = 0; i < NOFILE; i++)
80103ce5:	83 c6 01             	add    $0x1,%esi
80103ce8:	83 fe 0f             	cmp    $0xf,%esi
80103ceb:	7f 1a                	jg     80103d07 <fork2+0xc8>
        if(curproc->ofile[i])
80103ced:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103cf1:	85 c0                	test   %eax,%eax
80103cf3:	74 f0                	je     80103ce5 <fork2+0xa6>
            np->ofile[i] = filedup(curproc->ofile[i]);
80103cf5:	83 ec 0c             	sub    $0xc,%esp
80103cf8:	50                   	push   %eax
80103cf9:	e8 90 cf ff ff       	call   80100c8e <filedup>
80103cfe:	89 44 b7 28          	mov    %eax,0x28(%edi,%esi,4)
80103d02:	83 c4 10             	add    $0x10,%esp
80103d05:	eb de                	jmp    80103ce5 <fork2+0xa6>
    np->cwd = idup(curproc->cwd);
80103d07:	83 ec 0c             	sub    $0xc,%esp
80103d0a:	ff 73 68             	pushl  0x68(%ebx)
80103d0d:	e8 3f d8 ff ff       	call   80101551 <idup>
80103d12:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103d15:	89 47 68             	mov    %eax,0x68(%edi)
    safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103d18:	83 c3 6c             	add    $0x6c,%ebx
80103d1b:	8d 47 6c             	lea    0x6c(%edi),%eax
80103d1e:	83 c4 0c             	add    $0xc,%esp
80103d21:	6a 10                	push   $0x10
80103d23:	53                   	push   %ebx
80103d24:	50                   	push   %eax
80103d25:	e8 eb 05 00 00       	call   80104315 <safestrcpy>
    pid = np->pid;
80103d2a:	8b 5f 10             	mov    0x10(%edi),%ebx
    cprintf("%s\n", "trying to add to queue");
80103d2d:	83 c4 08             	add    $0x8,%esp
80103d30:	68 6f 70 10 80       	push   $0x8010706f
80103d35:	68 53 70 10 80       	push   $0x80107053
80103d3a:	e8 cc c8 ff ff       	call   8010060b <cprintf>
    if (priorityQueue[pri].head == NULL && priorityQueue[pri].tail == NULL) {
80103d3f:	83 c4 10             	add    $0x10,%esp
80103d42:	8b 45 08             	mov    0x8(%ebp),%eax
80103d45:	83 3c c5 20 2d 11 80 	cmpl   $0x0,-0x7feed2e0(,%eax,8)
80103d4c:	00 
80103d4d:	0f 84 9a 00 00 00    	je     80103ded <fork2+0x1ae>
        cprintf("%s\n", "procs in queue");
80103d53:	83 ec 08             	sub    $0x8,%esp
80103d56:	68 9a 70 10 80       	push   $0x8010709a
80103d5b:	68 53 70 10 80       	push   $0x80107053
80103d60:	e8 a6 c8 ff ff       	call   8010060b <cprintf>
        priorityQueue[pri].tail->next = np;
80103d65:	8b 45 08             	mov    0x8(%ebp),%eax
80103d68:	8b 04 c5 24 2d 11 80 	mov    -0x7feed2dc(,%eax,8),%eax
80103d6f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103d72:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
        priorityQueue[pri].tail = np;
80103d78:	8b 45 08             	mov    0x8(%ebp),%eax
80103d7b:	89 14 c5 24 2d 11 80 	mov    %edx,-0x7feed2dc(,%eax,8)
80103d82:	83 c4 10             	add    $0x10,%esp
    cprintf("ADDED head: %p  tail: %p\n", priorityQueue[pri].head, priorityQueue[pri].tail);
80103d85:	83 ec 04             	sub    $0x4,%esp
80103d88:	8b 45 08             	mov    0x8(%ebp),%eax
80103d8b:	ff 34 c5 24 2d 11 80 	pushl  -0x7feed2dc(,%eax,8)
80103d92:	ff 34 c5 20 2d 11 80 	pushl  -0x7feed2e0(,%eax,8)
80103d99:	68 a9 70 10 80       	push   $0x801070a9
80103d9e:	e8 68 c8 ff ff       	call   8010060b <cprintf>
    np->next = NULL;
80103da3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103da6:	c7 87 80 00 00 00 00 	movl   $0x0,0x80(%edi)
80103dad:	00 00 00 
    setpri(pid, pri);
80103db0:	83 c4 08             	add    $0x8,%esp
80103db3:	ff 75 08             	pushl  0x8(%ebp)
80103db6:	53                   	push   %ebx
80103db7:	e8 ae fa ff ff       	call   8010386a <setpri>
    acquire(&ptable.lock);
80103dbc:	c7 04 24 40 2d 11 80 	movl   $0x80112d40,(%esp)
80103dc3:	e8 3a 03 00 00       	call   80104102 <acquire>
    np->state = RUNNABLE;
80103dc8:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
    release(&ptable.lock);
80103dcf:	c7 04 24 40 2d 11 80 	movl   $0x80112d40,(%esp)
80103dd6:	e8 8c 03 00 00       	call   80104167 <release>
    printQueue();
80103ddb:	e8 6c fb ff ff       	call   8010394c <printQueue>
    return pid;
80103de0:	83 c4 10             	add    $0x10,%esp
}
80103de3:	89 d8                	mov    %ebx,%eax
80103de5:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103de8:	5b                   	pop    %ebx
80103de9:	5e                   	pop    %esi
80103dea:	5f                   	pop    %edi
80103deb:	5d                   	pop    %ebp
80103dec:	c3                   	ret    
    if (priorityQueue[pri].head == NULL && priorityQueue[pri].tail == NULL) {
80103ded:	83 3c c5 24 2d 11 80 	cmpl   $0x0,-0x7feed2dc(,%eax,8)
80103df4:	00 
80103df5:	0f 85 58 ff ff ff    	jne    80103d53 <fork2+0x114>
        cprintf("%s\n", "added queue on null");
80103dfb:	83 ec 08             	sub    $0x8,%esp
80103dfe:	68 86 70 10 80       	push   $0x80107086
80103e03:	68 53 70 10 80       	push   $0x80107053
80103e08:	e8 fe c7 ff ff       	call   8010060b <cprintf>
        priorityQueue[pri].head = np;
80103e0d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103e10:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103e13:	89 04 cd 20 2d 11 80 	mov    %eax,-0x7feed2e0(,%ecx,8)
        priorityQueue[pri].tail = np;
80103e1a:	89 04 cd 24 2d 11 80 	mov    %eax,-0x7feed2dc(,%ecx,8)
80103e21:	83 c4 10             	add    $0x10,%esp
80103e24:	e9 5c ff ff ff       	jmp    80103d85 <fork2+0x146>
        return -1;
80103e29:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103e2e:	eb b3                	jmp    80103de3 <fork2+0x1a4>

80103e30 <fork>:
{
80103e30:	55                   	push   %ebp
80103e31:	89 e5                	mov    %esp,%ebp
80103e33:	83 ec 14             	sub    $0x14,%esp
  int pid = fork2(-1);
80103e36:	6a ff                	push   $0xffffffff
80103e38:	e8 02 fe ff ff       	call   80103c3f <fork2>
}
80103e3d:	c9                   	leave  
80103e3e:	c3                   	ret    

80103e3f <getpinfo>:

// returns 0 on success and -1 on failure
int
getpinfo(struct pstat *pstat){
80103e3f:	55                   	push   %ebp
80103e40:	89 e5                	mov    %esp,%ebp
80103e42:	53                   	push   %ebx
80103e43:	83 ec 10             	sub    $0x10,%esp
80103e46:	8b 5d 08             	mov    0x8(%ebp),%ebx

    acquire(&ptable.lock);
80103e49:	68 40 2d 11 80       	push   $0x80112d40
80103e4e:	e8 af 02 00 00       	call   80104102 <acquire>

    for (int i = 0; i < NPROC; i++){
        pstat->inuse[i] = ptable.inuse[i];
80103e53:	a1 74 57 11 80       	mov    0x80115774,%eax
80103e58:	89 03                	mov    %eax,(%ebx)
        pstat->pid[i] = ptable.pid[i];
80103e5a:	a1 74 58 11 80       	mov    0x80115874,%eax
80103e5f:	89 83 00 01 00 00    	mov    %eax,0x100(%ebx)
        pstat->priority[i] = ptable.priority[i];
80103e65:	a1 74 59 11 80       	mov    0x80115974,%eax
80103e6a:	89 83 00 02 00 00    	mov    %eax,0x200(%ebx)
        pstat->state[i] = ptable.state[i];
80103e70:	a1 74 5a 11 80       	mov    0x80115a74,%eax
80103e75:	89 83 00 03 00 00    	mov    %eax,0x300(%ebx)
        for (int j = 0; j < 4; i++) {
80103e7b:	83 c4 10             	add    $0x10,%esp
80103e7e:	b8 00 00 00 00       	mov    $0x0,%eax
            pstat->ticks[i][j] = ptable.ticks[i][j];
80103e83:	8d 90 e3 02 00 00    	lea    0x2e3(%eax),%edx
80103e89:	c1 e2 04             	shl    $0x4,%edx
80103e8c:	8b 8a 44 2d 11 80    	mov    -0x7feed2bc(%edx),%ecx
80103e92:	8d 50 40             	lea    0x40(%eax),%edx
80103e95:	c1 e2 04             	shl    $0x4,%edx
80103e98:	89 0c 13             	mov    %ecx,(%ebx,%edx,1)
            pstat->qtail[i][j] = ptable.qtail[i][j];
80103e9b:	8d 90 23 03 00 00    	lea    0x323(%eax),%edx
80103ea1:	c1 e2 04             	shl    $0x4,%edx
80103ea4:	8b 8a 44 2d 11 80    	mov    -0x7feed2bc(%edx),%ecx
80103eaa:	8d 90 80 00 00 00    	lea    0x80(%eax),%edx
80103eb0:	c1 e2 04             	shl    $0x4,%edx
80103eb3:	89 0c 13             	mov    %ecx,(%ebx,%edx,1)
        for (int j = 0; j < 4; i++) {
80103eb6:	83 c0 01             	add    $0x1,%eax
80103eb9:	eb c8                	jmp    80103e83 <getpinfo+0x44>

80103ebb <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103ebb:	55                   	push   %ebp
80103ebc:	89 e5                	mov    %esp,%ebp
80103ebe:	53                   	push   %ebx
80103ebf:	83 ec 0c             	sub    $0xc,%esp
80103ec2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103ec5:	68 84 71 10 80       	push   $0x80107184
80103eca:	8d 43 04             	lea    0x4(%ebx),%eax
80103ecd:	50                   	push   %eax
80103ece:	e8 f3 00 00 00       	call   80103fc6 <initlock>
  lk->name = name;
80103ed3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ed6:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103ed9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103edf:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103ee6:	83 c4 10             	add    $0x10,%esp
80103ee9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103eec:	c9                   	leave  
80103eed:	c3                   	ret    

80103eee <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103eee:	55                   	push   %ebp
80103eef:	89 e5                	mov    %esp,%ebp
80103ef1:	56                   	push   %esi
80103ef2:	53                   	push   %ebx
80103ef3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103ef6:	8d 73 04             	lea    0x4(%ebx),%esi
80103ef9:	83 ec 0c             	sub    $0xc,%esp
80103efc:	56                   	push   %esi
80103efd:	e8 00 02 00 00       	call   80104102 <acquire>
  while (lk->locked) {
80103f02:	83 c4 10             	add    $0x10,%esp
80103f05:	eb 0d                	jmp    80103f14 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103f07:	83 ec 08             	sub    $0x8,%esp
80103f0a:	56                   	push   %esi
80103f0b:	53                   	push   %ebx
80103f0c:	e8 9d f6 ff ff       	call   801035ae <sleep>
80103f11:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103f14:	83 3b 00             	cmpl   $0x0,(%ebx)
80103f17:	75 ee                	jne    80103f07 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103f19:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103f1f:	e8 0d f3 ff ff       	call   80103231 <myproc>
80103f24:	8b 40 10             	mov    0x10(%eax),%eax
80103f27:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103f2a:	83 ec 0c             	sub    $0xc,%esp
80103f2d:	56                   	push   %esi
80103f2e:	e8 34 02 00 00       	call   80104167 <release>
}
80103f33:	83 c4 10             	add    $0x10,%esp
80103f36:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103f39:	5b                   	pop    %ebx
80103f3a:	5e                   	pop    %esi
80103f3b:	5d                   	pop    %ebp
80103f3c:	c3                   	ret    

80103f3d <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103f3d:	55                   	push   %ebp
80103f3e:	89 e5                	mov    %esp,%ebp
80103f40:	56                   	push   %esi
80103f41:	53                   	push   %ebx
80103f42:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103f45:	8d 73 04             	lea    0x4(%ebx),%esi
80103f48:	83 ec 0c             	sub    $0xc,%esp
80103f4b:	56                   	push   %esi
80103f4c:	e8 b1 01 00 00       	call   80104102 <acquire>
  lk->locked = 0;
80103f51:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103f57:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103f5e:	89 1c 24             	mov    %ebx,(%esp)
80103f61:	e8 b0 f7 ff ff       	call   80103716 <wakeup>
  release(&lk->lk);
80103f66:	89 34 24             	mov    %esi,(%esp)
80103f69:	e8 f9 01 00 00       	call   80104167 <release>
}
80103f6e:	83 c4 10             	add    $0x10,%esp
80103f71:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103f74:	5b                   	pop    %ebx
80103f75:	5e                   	pop    %esi
80103f76:	5d                   	pop    %ebp
80103f77:	c3                   	ret    

80103f78 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103f78:	55                   	push   %ebp
80103f79:	89 e5                	mov    %esp,%ebp
80103f7b:	56                   	push   %esi
80103f7c:	53                   	push   %ebx
80103f7d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103f80:	8d 73 04             	lea    0x4(%ebx),%esi
80103f83:	83 ec 0c             	sub    $0xc,%esp
80103f86:	56                   	push   %esi
80103f87:	e8 76 01 00 00       	call   80104102 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103f8c:	83 c4 10             	add    $0x10,%esp
80103f8f:	83 3b 00             	cmpl   $0x0,(%ebx)
80103f92:	75 17                	jne    80103fab <holdingsleep+0x33>
80103f94:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103f99:	83 ec 0c             	sub    $0xc,%esp
80103f9c:	56                   	push   %esi
80103f9d:	e8 c5 01 00 00       	call   80104167 <release>
  return r;
}
80103fa2:	89 d8                	mov    %ebx,%eax
80103fa4:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103fa7:	5b                   	pop    %ebx
80103fa8:	5e                   	pop    %esi
80103fa9:	5d                   	pop    %ebp
80103faa:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103fab:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103fae:	e8 7e f2 ff ff       	call   80103231 <myproc>
80103fb3:	3b 58 10             	cmp    0x10(%eax),%ebx
80103fb6:	74 07                	je     80103fbf <holdingsleep+0x47>
80103fb8:	bb 00 00 00 00       	mov    $0x0,%ebx
80103fbd:	eb da                	jmp    80103f99 <holdingsleep+0x21>
80103fbf:	bb 01 00 00 00       	mov    $0x1,%ebx
80103fc4:	eb d3                	jmp    80103f99 <holdingsleep+0x21>

80103fc6 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103fc6:	55                   	push   %ebp
80103fc7:	89 e5                	mov    %esp,%ebp
80103fc9:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103fcc:	8b 55 0c             	mov    0xc(%ebp),%edx
80103fcf:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103fd2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103fd8:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103fdf:	5d                   	pop    %ebp
80103fe0:	c3                   	ret    

80103fe1 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103fe1:	55                   	push   %ebp
80103fe2:	89 e5                	mov    %esp,%ebp
80103fe4:	53                   	push   %ebx
80103fe5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103fe8:	8b 45 08             	mov    0x8(%ebp),%eax
80103feb:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103fee:	b8 00 00 00 00       	mov    $0x0,%eax
80103ff3:	83 f8 09             	cmp    $0x9,%eax
80103ff6:	7f 25                	jg     8010401d <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103ff8:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103ffe:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80104004:	77 17                	ja     8010401d <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104006:	8b 5a 04             	mov    0x4(%edx),%ebx
80104009:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
8010400c:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
8010400e:	83 c0 01             	add    $0x1,%eax
80104011:	eb e0                	jmp    80103ff3 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80104013:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
8010401a:	83 c0 01             	add    $0x1,%eax
8010401d:	83 f8 09             	cmp    $0x9,%eax
80104020:	7e f1                	jle    80104013 <getcallerpcs+0x32>
}
80104022:	5b                   	pop    %ebx
80104023:	5d                   	pop    %ebp
80104024:	c3                   	ret    

80104025 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80104025:	55                   	push   %ebp
80104026:	89 e5                	mov    %esp,%ebp
80104028:	53                   	push   %ebx
80104029:	83 ec 04             	sub    $0x4,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010402c:	9c                   	pushf  
8010402d:	5b                   	pop    %ebx
  asm volatile("cli");
8010402e:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
8010402f:	e8 86 f1 ff ff       	call   801031ba <mycpu>
80104034:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
8010403b:	74 12                	je     8010404f <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
8010403d:	e8 78 f1 ff ff       	call   801031ba <mycpu>
80104042:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80104049:	83 c4 04             	add    $0x4,%esp
8010404c:	5b                   	pop    %ebx
8010404d:	5d                   	pop    %ebp
8010404e:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
8010404f:	e8 66 f1 ff ff       	call   801031ba <mycpu>
80104054:	81 e3 00 02 00 00    	and    $0x200,%ebx
8010405a:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80104060:	eb db                	jmp    8010403d <pushcli+0x18>

80104062 <popcli>:

void
popcli(void)
{
80104062:	55                   	push   %ebp
80104063:	89 e5                	mov    %esp,%ebp
80104065:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104068:	9c                   	pushf  
80104069:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010406a:	f6 c4 02             	test   $0x2,%ah
8010406d:	75 28                	jne    80104097 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
8010406f:	e8 46 f1 ff ff       	call   801031ba <mycpu>
80104074:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
8010407a:	8d 51 ff             	lea    -0x1(%ecx),%edx
8010407d:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80104083:	85 d2                	test   %edx,%edx
80104085:	78 1d                	js     801040a4 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80104087:	e8 2e f1 ff ff       	call   801031ba <mycpu>
8010408c:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80104093:	74 1c                	je     801040b1 <popcli+0x4f>
    sti();
}
80104095:	c9                   	leave  
80104096:	c3                   	ret    
    panic("popcli - interruptible");
80104097:	83 ec 0c             	sub    $0xc,%esp
8010409a:	68 8f 71 10 80       	push   $0x8010718f
8010409f:	e8 a4 c2 ff ff       	call   80100348 <panic>
    panic("popcli");
801040a4:	83 ec 0c             	sub    $0xc,%esp
801040a7:	68 a6 71 10 80       	push   $0x801071a6
801040ac:	e8 97 c2 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
801040b1:	e8 04 f1 ff ff       	call   801031ba <mycpu>
801040b6:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
801040bd:	74 d6                	je     80104095 <popcli+0x33>
  asm volatile("sti");
801040bf:	fb                   	sti    
}
801040c0:	eb d3                	jmp    80104095 <popcli+0x33>

801040c2 <holding>:
{
801040c2:	55                   	push   %ebp
801040c3:	89 e5                	mov    %esp,%ebp
801040c5:	53                   	push   %ebx
801040c6:	83 ec 04             	sub    $0x4,%esp
801040c9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
801040cc:	e8 54 ff ff ff       	call   80104025 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
801040d1:	83 3b 00             	cmpl   $0x0,(%ebx)
801040d4:	75 12                	jne    801040e8 <holding+0x26>
801040d6:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
801040db:	e8 82 ff ff ff       	call   80104062 <popcli>
}
801040e0:	89 d8                	mov    %ebx,%eax
801040e2:	83 c4 04             	add    $0x4,%esp
801040e5:	5b                   	pop    %ebx
801040e6:	5d                   	pop    %ebp
801040e7:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
801040e8:	8b 5b 08             	mov    0x8(%ebx),%ebx
801040eb:	e8 ca f0 ff ff       	call   801031ba <mycpu>
801040f0:	39 c3                	cmp    %eax,%ebx
801040f2:	74 07                	je     801040fb <holding+0x39>
801040f4:	bb 00 00 00 00       	mov    $0x0,%ebx
801040f9:	eb e0                	jmp    801040db <holding+0x19>
801040fb:	bb 01 00 00 00       	mov    $0x1,%ebx
80104100:	eb d9                	jmp    801040db <holding+0x19>

80104102 <acquire>:
{
80104102:	55                   	push   %ebp
80104103:	89 e5                	mov    %esp,%ebp
80104105:	53                   	push   %ebx
80104106:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104109:	e8 17 ff ff ff       	call   80104025 <pushcli>
  if(holding(lk))
8010410e:	83 ec 0c             	sub    $0xc,%esp
80104111:	ff 75 08             	pushl  0x8(%ebp)
80104114:	e8 a9 ff ff ff       	call   801040c2 <holding>
80104119:	83 c4 10             	add    $0x10,%esp
8010411c:	85 c0                	test   %eax,%eax
8010411e:	75 3a                	jne    8010415a <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80104120:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80104123:	b8 01 00 00 00       	mov    $0x1,%eax
80104128:	f0 87 02             	lock xchg %eax,(%edx)
8010412b:	85 c0                	test   %eax,%eax
8010412d:	75 f1                	jne    80104120 <acquire+0x1e>
  __sync_synchronize();
8010412f:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80104134:	8b 5d 08             	mov    0x8(%ebp),%ebx
80104137:	e8 7e f0 ff ff       	call   801031ba <mycpu>
8010413c:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
8010413f:	8b 45 08             	mov    0x8(%ebp),%eax
80104142:	83 c0 0c             	add    $0xc,%eax
80104145:	83 ec 08             	sub    $0x8,%esp
80104148:	50                   	push   %eax
80104149:	8d 45 08             	lea    0x8(%ebp),%eax
8010414c:	50                   	push   %eax
8010414d:	e8 8f fe ff ff       	call   80103fe1 <getcallerpcs>
}
80104152:	83 c4 10             	add    $0x10,%esp
80104155:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104158:	c9                   	leave  
80104159:	c3                   	ret    
    panic("acquire");
8010415a:	83 ec 0c             	sub    $0xc,%esp
8010415d:	68 ad 71 10 80       	push   $0x801071ad
80104162:	e8 e1 c1 ff ff       	call   80100348 <panic>

80104167 <release>:
{
80104167:	55                   	push   %ebp
80104168:	89 e5                	mov    %esp,%ebp
8010416a:	53                   	push   %ebx
8010416b:	83 ec 10             	sub    $0x10,%esp
8010416e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80104171:	53                   	push   %ebx
80104172:	e8 4b ff ff ff       	call   801040c2 <holding>
80104177:	83 c4 10             	add    $0x10,%esp
8010417a:	85 c0                	test   %eax,%eax
8010417c:	74 23                	je     801041a1 <release+0x3a>
  lk->pcs[0] = 0;
8010417e:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80104185:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
8010418c:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80104191:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80104197:	e8 c6 fe ff ff       	call   80104062 <popcli>
}
8010419c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010419f:	c9                   	leave  
801041a0:	c3                   	ret    
    panic("release");
801041a1:	83 ec 0c             	sub    $0xc,%esp
801041a4:	68 b5 71 10 80       	push   $0x801071b5
801041a9:	e8 9a c1 ff ff       	call   80100348 <panic>

801041ae <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801041ae:	55                   	push   %ebp
801041af:	89 e5                	mov    %esp,%ebp
801041b1:	57                   	push   %edi
801041b2:	53                   	push   %ebx
801041b3:	8b 55 08             	mov    0x8(%ebp),%edx
801041b6:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
801041b9:	f6 c2 03             	test   $0x3,%dl
801041bc:	75 05                	jne    801041c3 <memset+0x15>
801041be:	f6 c1 03             	test   $0x3,%cl
801041c1:	74 0e                	je     801041d1 <memset+0x23>
  asm volatile("cld; rep stosb" :
801041c3:	89 d7                	mov    %edx,%edi
801041c5:	8b 45 0c             	mov    0xc(%ebp),%eax
801041c8:	fc                   	cld    
801041c9:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
801041cb:	89 d0                	mov    %edx,%eax
801041cd:	5b                   	pop    %ebx
801041ce:	5f                   	pop    %edi
801041cf:	5d                   	pop    %ebp
801041d0:	c3                   	ret    
    c &= 0xFF;
801041d1:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801041d5:	c1 e9 02             	shr    $0x2,%ecx
801041d8:	89 f8                	mov    %edi,%eax
801041da:	c1 e0 18             	shl    $0x18,%eax
801041dd:	89 fb                	mov    %edi,%ebx
801041df:	c1 e3 10             	shl    $0x10,%ebx
801041e2:	09 d8                	or     %ebx,%eax
801041e4:	89 fb                	mov    %edi,%ebx
801041e6:	c1 e3 08             	shl    $0x8,%ebx
801041e9:	09 d8                	or     %ebx,%eax
801041eb:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
801041ed:	89 d7                	mov    %edx,%edi
801041ef:	fc                   	cld    
801041f0:	f3 ab                	rep stos %eax,%es:(%edi)
801041f2:	eb d7                	jmp    801041cb <memset+0x1d>

801041f4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801041f4:	55                   	push   %ebp
801041f5:	89 e5                	mov    %esp,%ebp
801041f7:	56                   	push   %esi
801041f8:	53                   	push   %ebx
801041f9:	8b 4d 08             	mov    0x8(%ebp),%ecx
801041fc:	8b 55 0c             	mov    0xc(%ebp),%edx
801041ff:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80104202:	8d 70 ff             	lea    -0x1(%eax),%esi
80104205:	85 c0                	test   %eax,%eax
80104207:	74 1c                	je     80104225 <memcmp+0x31>
    if(*s1 != *s2)
80104209:	0f b6 01             	movzbl (%ecx),%eax
8010420c:	0f b6 1a             	movzbl (%edx),%ebx
8010420f:	38 d8                	cmp    %bl,%al
80104211:	75 0a                	jne    8010421d <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80104213:	83 c1 01             	add    $0x1,%ecx
80104216:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80104219:	89 f0                	mov    %esi,%eax
8010421b:	eb e5                	jmp    80104202 <memcmp+0xe>
      return *s1 - *s2;
8010421d:	0f b6 c0             	movzbl %al,%eax
80104220:	0f b6 db             	movzbl %bl,%ebx
80104223:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80104225:	5b                   	pop    %ebx
80104226:	5e                   	pop    %esi
80104227:	5d                   	pop    %ebp
80104228:	c3                   	ret    

80104229 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80104229:	55                   	push   %ebp
8010422a:	89 e5                	mov    %esp,%ebp
8010422c:	56                   	push   %esi
8010422d:	53                   	push   %ebx
8010422e:	8b 45 08             	mov    0x8(%ebp),%eax
80104231:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80104234:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80104237:	39 c1                	cmp    %eax,%ecx
80104239:	73 3a                	jae    80104275 <memmove+0x4c>
8010423b:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
8010423e:	39 c3                	cmp    %eax,%ebx
80104240:	76 37                	jbe    80104279 <memmove+0x50>
    s += n;
    d += n;
80104242:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80104245:	eb 0d                	jmp    80104254 <memmove+0x2b>
      *--d = *--s;
80104247:	83 eb 01             	sub    $0x1,%ebx
8010424a:	83 e9 01             	sub    $0x1,%ecx
8010424d:	0f b6 13             	movzbl (%ebx),%edx
80104250:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80104252:	89 f2                	mov    %esi,%edx
80104254:	8d 72 ff             	lea    -0x1(%edx),%esi
80104257:	85 d2                	test   %edx,%edx
80104259:	75 ec                	jne    80104247 <memmove+0x1e>
8010425b:	eb 14                	jmp    80104271 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
8010425d:	0f b6 11             	movzbl (%ecx),%edx
80104260:	88 13                	mov    %dl,(%ebx)
80104262:	8d 5b 01             	lea    0x1(%ebx),%ebx
80104265:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80104268:	89 f2                	mov    %esi,%edx
8010426a:	8d 72 ff             	lea    -0x1(%edx),%esi
8010426d:	85 d2                	test   %edx,%edx
8010426f:	75 ec                	jne    8010425d <memmove+0x34>

  return dst;
}
80104271:	5b                   	pop    %ebx
80104272:	5e                   	pop    %esi
80104273:	5d                   	pop    %ebp
80104274:	c3                   	ret    
80104275:	89 c3                	mov    %eax,%ebx
80104277:	eb f1                	jmp    8010426a <memmove+0x41>
80104279:	89 c3                	mov    %eax,%ebx
8010427b:	eb ed                	jmp    8010426a <memmove+0x41>

8010427d <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
8010427d:	55                   	push   %ebp
8010427e:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80104280:	ff 75 10             	pushl  0x10(%ebp)
80104283:	ff 75 0c             	pushl  0xc(%ebp)
80104286:	ff 75 08             	pushl  0x8(%ebp)
80104289:	e8 9b ff ff ff       	call   80104229 <memmove>
}
8010428e:	c9                   	leave  
8010428f:	c3                   	ret    

80104290 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80104290:	55                   	push   %ebp
80104291:	89 e5                	mov    %esp,%ebp
80104293:	53                   	push   %ebx
80104294:	8b 55 08             	mov    0x8(%ebp),%edx
80104297:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010429a:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
8010429d:	eb 09                	jmp    801042a8 <strncmp+0x18>
    n--, p++, q++;
8010429f:	83 e8 01             	sub    $0x1,%eax
801042a2:	83 c2 01             	add    $0x1,%edx
801042a5:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
801042a8:	85 c0                	test   %eax,%eax
801042aa:	74 0b                	je     801042b7 <strncmp+0x27>
801042ac:	0f b6 1a             	movzbl (%edx),%ebx
801042af:	84 db                	test   %bl,%bl
801042b1:	74 04                	je     801042b7 <strncmp+0x27>
801042b3:	3a 19                	cmp    (%ecx),%bl
801042b5:	74 e8                	je     8010429f <strncmp+0xf>
  if(n == 0)
801042b7:	85 c0                	test   %eax,%eax
801042b9:	74 0b                	je     801042c6 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
801042bb:	0f b6 02             	movzbl (%edx),%eax
801042be:	0f b6 11             	movzbl (%ecx),%edx
801042c1:	29 d0                	sub    %edx,%eax
}
801042c3:	5b                   	pop    %ebx
801042c4:	5d                   	pop    %ebp
801042c5:	c3                   	ret    
    return 0;
801042c6:	b8 00 00 00 00       	mov    $0x0,%eax
801042cb:	eb f6                	jmp    801042c3 <strncmp+0x33>

801042cd <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801042cd:	55                   	push   %ebp
801042ce:	89 e5                	mov    %esp,%ebp
801042d0:	57                   	push   %edi
801042d1:	56                   	push   %esi
801042d2:	53                   	push   %ebx
801042d3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801042d6:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
801042d9:	8b 45 08             	mov    0x8(%ebp),%eax
801042dc:	eb 04                	jmp    801042e2 <strncpy+0x15>
801042de:	89 fb                	mov    %edi,%ebx
801042e0:	89 f0                	mov    %esi,%eax
801042e2:	8d 51 ff             	lea    -0x1(%ecx),%edx
801042e5:	85 c9                	test   %ecx,%ecx
801042e7:	7e 1d                	jle    80104306 <strncpy+0x39>
801042e9:	8d 7b 01             	lea    0x1(%ebx),%edi
801042ec:	8d 70 01             	lea    0x1(%eax),%esi
801042ef:	0f b6 1b             	movzbl (%ebx),%ebx
801042f2:	88 18                	mov    %bl,(%eax)
801042f4:	89 d1                	mov    %edx,%ecx
801042f6:	84 db                	test   %bl,%bl
801042f8:	75 e4                	jne    801042de <strncpy+0x11>
801042fa:	89 f0                	mov    %esi,%eax
801042fc:	eb 08                	jmp    80104306 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
801042fe:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80104301:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80104303:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80104306:	8d 4a ff             	lea    -0x1(%edx),%ecx
80104309:	85 d2                	test   %edx,%edx
8010430b:	7f f1                	jg     801042fe <strncpy+0x31>
  return os;
}
8010430d:	8b 45 08             	mov    0x8(%ebp),%eax
80104310:	5b                   	pop    %ebx
80104311:	5e                   	pop    %esi
80104312:	5f                   	pop    %edi
80104313:	5d                   	pop    %ebp
80104314:	c3                   	ret    

80104315 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80104315:	55                   	push   %ebp
80104316:	89 e5                	mov    %esp,%ebp
80104318:	57                   	push   %edi
80104319:	56                   	push   %esi
8010431a:	53                   	push   %ebx
8010431b:	8b 45 08             	mov    0x8(%ebp),%eax
8010431e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80104321:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80104324:	85 d2                	test   %edx,%edx
80104326:	7e 23                	jle    8010434b <safestrcpy+0x36>
80104328:	89 c1                	mov    %eax,%ecx
8010432a:	eb 04                	jmp    80104330 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
8010432c:	89 fb                	mov    %edi,%ebx
8010432e:	89 f1                	mov    %esi,%ecx
80104330:	83 ea 01             	sub    $0x1,%edx
80104333:	85 d2                	test   %edx,%edx
80104335:	7e 11                	jle    80104348 <safestrcpy+0x33>
80104337:	8d 7b 01             	lea    0x1(%ebx),%edi
8010433a:	8d 71 01             	lea    0x1(%ecx),%esi
8010433d:	0f b6 1b             	movzbl (%ebx),%ebx
80104340:	88 19                	mov    %bl,(%ecx)
80104342:	84 db                	test   %bl,%bl
80104344:	75 e6                	jne    8010432c <safestrcpy+0x17>
80104346:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80104348:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
8010434b:	5b                   	pop    %ebx
8010434c:	5e                   	pop    %esi
8010434d:	5f                   	pop    %edi
8010434e:	5d                   	pop    %ebp
8010434f:	c3                   	ret    

80104350 <strlen>:

int
strlen(const char *s)
{
80104350:	55                   	push   %ebp
80104351:	89 e5                	mov    %esp,%ebp
80104353:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80104356:	b8 00 00 00 00       	mov    $0x0,%eax
8010435b:	eb 03                	jmp    80104360 <strlen+0x10>
8010435d:	83 c0 01             	add    $0x1,%eax
80104360:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80104364:	75 f7                	jne    8010435d <strlen+0xd>
    ;
  return n;
}
80104366:	5d                   	pop    %ebp
80104367:	c3                   	ret    

80104368 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80104368:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
8010436c:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80104370:	55                   	push   %ebp
  pushl %ebx
80104371:	53                   	push   %ebx
  pushl %esi
80104372:	56                   	push   %esi
  pushl %edi
80104373:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80104374:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80104376:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80104378:	5f                   	pop    %edi
  popl %esi
80104379:	5e                   	pop    %esi
  popl %ebx
8010437a:	5b                   	pop    %ebx
  popl %ebp
8010437b:	5d                   	pop    %ebp
  ret
8010437c:	c3                   	ret    

8010437d <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
8010437d:	55                   	push   %ebp
8010437e:	89 e5                	mov    %esp,%ebp
80104380:	53                   	push   %ebx
80104381:	83 ec 04             	sub    $0x4,%esp
80104384:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80104387:	e8 a5 ee ff ff       	call   80103231 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
8010438c:	8b 00                	mov    (%eax),%eax
8010438e:	39 d8                	cmp    %ebx,%eax
80104390:	76 19                	jbe    801043ab <fetchint+0x2e>
80104392:	8d 53 04             	lea    0x4(%ebx),%edx
80104395:	39 d0                	cmp    %edx,%eax
80104397:	72 19                	jb     801043b2 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80104399:	8b 13                	mov    (%ebx),%edx
8010439b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010439e:	89 10                	mov    %edx,(%eax)
  return 0;
801043a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801043a5:	83 c4 04             	add    $0x4,%esp
801043a8:	5b                   	pop    %ebx
801043a9:	5d                   	pop    %ebp
801043aa:	c3                   	ret    
    return -1;
801043ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043b0:	eb f3                	jmp    801043a5 <fetchint+0x28>
801043b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043b7:	eb ec                	jmp    801043a5 <fetchint+0x28>

801043b9 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801043b9:	55                   	push   %ebp
801043ba:	89 e5                	mov    %esp,%ebp
801043bc:	53                   	push   %ebx
801043bd:	83 ec 04             	sub    $0x4,%esp
801043c0:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
801043c3:	e8 69 ee ff ff       	call   80103231 <myproc>

  if(addr >= curproc->sz)
801043c8:	39 18                	cmp    %ebx,(%eax)
801043ca:	76 26                	jbe    801043f2 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
801043cc:	8b 55 0c             	mov    0xc(%ebp),%edx
801043cf:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
801043d1:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
801043d3:	89 d8                	mov    %ebx,%eax
801043d5:	39 d0                	cmp    %edx,%eax
801043d7:	73 0e                	jae    801043e7 <fetchstr+0x2e>
    if(*s == 0)
801043d9:	80 38 00             	cmpb   $0x0,(%eax)
801043dc:	74 05                	je     801043e3 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
801043de:	83 c0 01             	add    $0x1,%eax
801043e1:	eb f2                	jmp    801043d5 <fetchstr+0x1c>
      return s - *pp;
801043e3:	29 d8                	sub    %ebx,%eax
801043e5:	eb 05                	jmp    801043ec <fetchstr+0x33>
  }
  return -1;
801043e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801043ec:	83 c4 04             	add    $0x4,%esp
801043ef:	5b                   	pop    %ebx
801043f0:	5d                   	pop    %ebp
801043f1:	c3                   	ret    
    return -1;
801043f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043f7:	eb f3                	jmp    801043ec <fetchstr+0x33>

801043f9 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801043f9:	55                   	push   %ebp
801043fa:	89 e5                	mov    %esp,%ebp
801043fc:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801043ff:	e8 2d ee ff ff       	call   80103231 <myproc>
80104404:	8b 50 18             	mov    0x18(%eax),%edx
80104407:	8b 45 08             	mov    0x8(%ebp),%eax
8010440a:	c1 e0 02             	shl    $0x2,%eax
8010440d:	03 42 44             	add    0x44(%edx),%eax
80104410:	83 ec 08             	sub    $0x8,%esp
80104413:	ff 75 0c             	pushl  0xc(%ebp)
80104416:	83 c0 04             	add    $0x4,%eax
80104419:	50                   	push   %eax
8010441a:	e8 5e ff ff ff       	call   8010437d <fetchint>
}
8010441f:	c9                   	leave  
80104420:	c3                   	ret    

80104421 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80104421:	55                   	push   %ebp
80104422:	89 e5                	mov    %esp,%ebp
80104424:	56                   	push   %esi
80104425:	53                   	push   %ebx
80104426:	83 ec 10             	sub    $0x10,%esp
80104429:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
8010442c:	e8 00 ee ff ff       	call   80103231 <myproc>
80104431:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80104433:	83 ec 08             	sub    $0x8,%esp
80104436:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104439:	50                   	push   %eax
8010443a:	ff 75 08             	pushl  0x8(%ebp)
8010443d:	e8 b7 ff ff ff       	call   801043f9 <argint>
80104442:	83 c4 10             	add    $0x10,%esp
80104445:	85 c0                	test   %eax,%eax
80104447:	78 24                	js     8010446d <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104449:	85 db                	test   %ebx,%ebx
8010444b:	78 27                	js     80104474 <argptr+0x53>
8010444d:	8b 16                	mov    (%esi),%edx
8010444f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104452:	39 c2                	cmp    %eax,%edx
80104454:	76 25                	jbe    8010447b <argptr+0x5a>
80104456:	01 c3                	add    %eax,%ebx
80104458:	39 da                	cmp    %ebx,%edx
8010445a:	72 26                	jb     80104482 <argptr+0x61>
    return -1;
  *pp = (char*)i;
8010445c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010445f:	89 02                	mov    %eax,(%edx)
  return 0;
80104461:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104466:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104469:	5b                   	pop    %ebx
8010446a:	5e                   	pop    %esi
8010446b:	5d                   	pop    %ebp
8010446c:	c3                   	ret    
    return -1;
8010446d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104472:	eb f2                	jmp    80104466 <argptr+0x45>
    return -1;
80104474:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104479:	eb eb                	jmp    80104466 <argptr+0x45>
8010447b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104480:	eb e4                	jmp    80104466 <argptr+0x45>
80104482:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104487:	eb dd                	jmp    80104466 <argptr+0x45>

80104489 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104489:	55                   	push   %ebp
8010448a:	89 e5                	mov    %esp,%ebp
8010448c:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010448f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104492:	50                   	push   %eax
80104493:	ff 75 08             	pushl  0x8(%ebp)
80104496:	e8 5e ff ff ff       	call   801043f9 <argint>
8010449b:	83 c4 10             	add    $0x10,%esp
8010449e:	85 c0                	test   %eax,%eax
801044a0:	78 13                	js     801044b5 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
801044a2:	83 ec 08             	sub    $0x8,%esp
801044a5:	ff 75 0c             	pushl  0xc(%ebp)
801044a8:	ff 75 f4             	pushl  -0xc(%ebp)
801044ab:	e8 09 ff ff ff       	call   801043b9 <fetchstr>
801044b0:	83 c4 10             	add    $0x10,%esp
}
801044b3:	c9                   	leave  
801044b4:	c3                   	ret    
    return -1;
801044b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044ba:	eb f7                	jmp    801044b3 <argstr+0x2a>

801044bc <syscall>:
[SYS_getpinfo] sys_getpinfo,
};

void
syscall(void)
{
801044bc:	55                   	push   %ebp
801044bd:	89 e5                	mov    %esp,%ebp
801044bf:	53                   	push   %ebx
801044c0:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
801044c3:	e8 69 ed ff ff       	call   80103231 <myproc>
801044c8:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
801044ca:	8b 40 18             	mov    0x18(%eax),%eax
801044cd:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801044d0:	8d 50 ff             	lea    -0x1(%eax),%edx
801044d3:	83 fa 18             	cmp    $0x18,%edx
801044d6:	77 18                	ja     801044f0 <syscall+0x34>
801044d8:	8b 14 85 e0 71 10 80 	mov    -0x7fef8e20(,%eax,4),%edx
801044df:	85 d2                	test   %edx,%edx
801044e1:	74 0d                	je     801044f0 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801044e3:	ff d2                	call   *%edx
801044e5:	8b 53 18             	mov    0x18(%ebx),%edx
801044e8:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
801044eb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801044ee:	c9                   	leave  
801044ef:	c3                   	ret    
            curproc->pid, curproc->name, num);
801044f0:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801044f3:	50                   	push   %eax
801044f4:	52                   	push   %edx
801044f5:	ff 73 10             	pushl  0x10(%ebx)
801044f8:	68 bd 71 10 80       	push   $0x801071bd
801044fd:	e8 09 c1 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80104502:	8b 43 18             	mov    0x18(%ebx),%eax
80104505:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
8010450c:	83 c4 10             	add    $0x10,%esp
}
8010450f:	eb da                	jmp    801044eb <syscall+0x2f>

80104511 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80104511:	55                   	push   %ebp
80104512:	89 e5                	mov    %esp,%ebp
80104514:	56                   	push   %esi
80104515:	53                   	push   %ebx
80104516:	83 ec 18             	sub    $0x18,%esp
80104519:	89 d6                	mov    %edx,%esi
8010451b:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010451d:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104520:	52                   	push   %edx
80104521:	50                   	push   %eax
80104522:	e8 d2 fe ff ff       	call   801043f9 <argint>
80104527:	83 c4 10             	add    $0x10,%esp
8010452a:	85 c0                	test   %eax,%eax
8010452c:	78 2e                	js     8010455c <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
8010452e:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80104532:	77 2f                	ja     80104563 <argfd+0x52>
80104534:	e8 f8 ec ff ff       	call   80103231 <myproc>
80104539:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010453c:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
80104540:	85 c0                	test   %eax,%eax
80104542:	74 26                	je     8010456a <argfd+0x59>
    return -1;
  if(pfd)
80104544:	85 f6                	test   %esi,%esi
80104546:	74 02                	je     8010454a <argfd+0x39>
    *pfd = fd;
80104548:	89 16                	mov    %edx,(%esi)
  if(pf)
8010454a:	85 db                	test   %ebx,%ebx
8010454c:	74 23                	je     80104571 <argfd+0x60>
    *pf = f;
8010454e:	89 03                	mov    %eax,(%ebx)
  return 0;
80104550:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104555:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104558:	5b                   	pop    %ebx
80104559:	5e                   	pop    %esi
8010455a:	5d                   	pop    %ebp
8010455b:	c3                   	ret    
    return -1;
8010455c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104561:	eb f2                	jmp    80104555 <argfd+0x44>
    return -1;
80104563:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104568:	eb eb                	jmp    80104555 <argfd+0x44>
8010456a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010456f:	eb e4                	jmp    80104555 <argfd+0x44>
  return 0;
80104571:	b8 00 00 00 00       	mov    $0x0,%eax
80104576:	eb dd                	jmp    80104555 <argfd+0x44>

80104578 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104578:	55                   	push   %ebp
80104579:	89 e5                	mov    %esp,%ebp
8010457b:	53                   	push   %ebx
8010457c:	83 ec 04             	sub    $0x4,%esp
8010457f:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
80104581:	e8 ab ec ff ff       	call   80103231 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104586:	ba 00 00 00 00       	mov    $0x0,%edx
8010458b:	83 fa 0f             	cmp    $0xf,%edx
8010458e:	7f 18                	jg     801045a8 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
80104590:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104595:	74 05                	je     8010459c <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104597:	83 c2 01             	add    $0x1,%edx
8010459a:	eb ef                	jmp    8010458b <fdalloc+0x13>
      curproc->ofile[fd] = f;
8010459c:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
801045a0:	89 d0                	mov    %edx,%eax
801045a2:	83 c4 04             	add    $0x4,%esp
801045a5:	5b                   	pop    %ebx
801045a6:	5d                   	pop    %ebp
801045a7:	c3                   	ret    
  return -1;
801045a8:	ba ff ff ff ff       	mov    $0xffffffff,%edx
801045ad:	eb f1                	jmp    801045a0 <fdalloc+0x28>

801045af <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801045af:	55                   	push   %ebp
801045b0:	89 e5                	mov    %esp,%ebp
801045b2:	56                   	push   %esi
801045b3:	53                   	push   %ebx
801045b4:	83 ec 10             	sub    $0x10,%esp
801045b7:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801045b9:	b8 20 00 00 00       	mov    $0x20,%eax
801045be:	89 c6                	mov    %eax,%esi
801045c0:	39 43 58             	cmp    %eax,0x58(%ebx)
801045c3:	76 2e                	jbe    801045f3 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801045c5:	6a 10                	push   $0x10
801045c7:	50                   	push   %eax
801045c8:	8d 45 e8             	lea    -0x18(%ebp),%eax
801045cb:	50                   	push   %eax
801045cc:	53                   	push   %ebx
801045cd:	e8 a1 d1 ff ff       	call   80101773 <readi>
801045d2:	83 c4 10             	add    $0x10,%esp
801045d5:	83 f8 10             	cmp    $0x10,%eax
801045d8:	75 0c                	jne    801045e6 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801045da:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801045df:	75 1e                	jne    801045ff <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801045e1:	8d 46 10             	lea    0x10(%esi),%eax
801045e4:	eb d8                	jmp    801045be <isdirempty+0xf>
      panic("isdirempty: readi");
801045e6:	83 ec 0c             	sub    $0xc,%esp
801045e9:	68 48 72 10 80       	push   $0x80107248
801045ee:	e8 55 bd ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801045f3:	b8 01 00 00 00       	mov    $0x1,%eax
}
801045f8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801045fb:	5b                   	pop    %ebx
801045fc:	5e                   	pop    %esi
801045fd:	5d                   	pop    %ebp
801045fe:	c3                   	ret    
      return 0;
801045ff:	b8 00 00 00 00       	mov    $0x0,%eax
80104604:	eb f2                	jmp    801045f8 <isdirempty+0x49>

80104606 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104606:	55                   	push   %ebp
80104607:	89 e5                	mov    %esp,%ebp
80104609:	57                   	push   %edi
8010460a:	56                   	push   %esi
8010460b:	53                   	push   %ebx
8010460c:	83 ec 44             	sub    $0x44,%esp
8010460f:	89 55 c4             	mov    %edx,-0x3c(%ebp)
80104612:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104615:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104618:	8d 55 d6             	lea    -0x2a(%ebp),%edx
8010461b:	52                   	push   %edx
8010461c:	50                   	push   %eax
8010461d:	e8 d7 d5 ff ff       	call   80101bf9 <nameiparent>
80104622:	89 c6                	mov    %eax,%esi
80104624:	83 c4 10             	add    $0x10,%esp
80104627:	85 c0                	test   %eax,%eax
80104629:	0f 84 3a 01 00 00    	je     80104769 <create+0x163>
    return 0;
  ilock(dp);
8010462f:	83 ec 0c             	sub    $0xc,%esp
80104632:	50                   	push   %eax
80104633:	e8 49 cf ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104638:	83 c4 0c             	add    $0xc,%esp
8010463b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010463e:	50                   	push   %eax
8010463f:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104642:	50                   	push   %eax
80104643:	56                   	push   %esi
80104644:	e8 67 d3 ff ff       	call   801019b0 <dirlookup>
80104649:	89 c3                	mov    %eax,%ebx
8010464b:	83 c4 10             	add    $0x10,%esp
8010464e:	85 c0                	test   %eax,%eax
80104650:	74 3f                	je     80104691 <create+0x8b>
    iunlockput(dp);
80104652:	83 ec 0c             	sub    $0xc,%esp
80104655:	56                   	push   %esi
80104656:	e8 cd d0 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
8010465b:	89 1c 24             	mov    %ebx,(%esp)
8010465e:	e8 1e cf ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80104663:	83 c4 10             	add    $0x10,%esp
80104666:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
8010466b:	75 11                	jne    8010467e <create+0x78>
8010466d:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104672:	75 0a                	jne    8010467e <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104674:	89 d8                	mov    %ebx,%eax
80104676:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104679:	5b                   	pop    %ebx
8010467a:	5e                   	pop    %esi
8010467b:	5f                   	pop    %edi
8010467c:	5d                   	pop    %ebp
8010467d:	c3                   	ret    
    iunlockput(ip);
8010467e:	83 ec 0c             	sub    $0xc,%esp
80104681:	53                   	push   %ebx
80104682:	e8 a1 d0 ff ff       	call   80101728 <iunlockput>
    return 0;
80104687:	83 c4 10             	add    $0x10,%esp
8010468a:	bb 00 00 00 00       	mov    $0x0,%ebx
8010468f:	eb e3                	jmp    80104674 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
80104691:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104695:	83 ec 08             	sub    $0x8,%esp
80104698:	50                   	push   %eax
80104699:	ff 36                	pushl  (%esi)
8010469b:	e8 de cc ff ff       	call   8010137e <ialloc>
801046a0:	89 c3                	mov    %eax,%ebx
801046a2:	83 c4 10             	add    $0x10,%esp
801046a5:	85 c0                	test   %eax,%eax
801046a7:	74 55                	je     801046fe <create+0xf8>
  ilock(ip);
801046a9:	83 ec 0c             	sub    $0xc,%esp
801046ac:	50                   	push   %eax
801046ad:	e8 cf ce ff ff       	call   80101581 <ilock>
  ip->major = major;
801046b2:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
801046b6:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
801046ba:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
801046be:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
801046c4:	89 1c 24             	mov    %ebx,(%esp)
801046c7:	e8 54 cd ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801046cc:	83 c4 10             	add    $0x10,%esp
801046cf:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801046d4:	74 35                	je     8010470b <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801046d6:	83 ec 04             	sub    $0x4,%esp
801046d9:	ff 73 04             	pushl  0x4(%ebx)
801046dc:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801046df:	50                   	push   %eax
801046e0:	56                   	push   %esi
801046e1:	e8 4a d4 ff ff       	call   80101b30 <dirlink>
801046e6:	83 c4 10             	add    $0x10,%esp
801046e9:	85 c0                	test   %eax,%eax
801046eb:	78 6f                	js     8010475c <create+0x156>
  iunlockput(dp);
801046ed:	83 ec 0c             	sub    $0xc,%esp
801046f0:	56                   	push   %esi
801046f1:	e8 32 d0 ff ff       	call   80101728 <iunlockput>
  return ip;
801046f6:	83 c4 10             	add    $0x10,%esp
801046f9:	e9 76 ff ff ff       	jmp    80104674 <create+0x6e>
    panic("create: ialloc");
801046fe:	83 ec 0c             	sub    $0xc,%esp
80104701:	68 5a 72 10 80       	push   $0x8010725a
80104706:	e8 3d bc ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
8010470b:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010470f:	83 c0 01             	add    $0x1,%eax
80104712:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104716:	83 ec 0c             	sub    $0xc,%esp
80104719:	56                   	push   %esi
8010471a:	e8 01 cd ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010471f:	83 c4 0c             	add    $0xc,%esp
80104722:	ff 73 04             	pushl  0x4(%ebx)
80104725:	68 6a 72 10 80       	push   $0x8010726a
8010472a:	53                   	push   %ebx
8010472b:	e8 00 d4 ff ff       	call   80101b30 <dirlink>
80104730:	83 c4 10             	add    $0x10,%esp
80104733:	85 c0                	test   %eax,%eax
80104735:	78 18                	js     8010474f <create+0x149>
80104737:	83 ec 04             	sub    $0x4,%esp
8010473a:	ff 76 04             	pushl  0x4(%esi)
8010473d:	68 69 72 10 80       	push   $0x80107269
80104742:	53                   	push   %ebx
80104743:	e8 e8 d3 ff ff       	call   80101b30 <dirlink>
80104748:	83 c4 10             	add    $0x10,%esp
8010474b:	85 c0                	test   %eax,%eax
8010474d:	79 87                	jns    801046d6 <create+0xd0>
      panic("create dots");
8010474f:	83 ec 0c             	sub    $0xc,%esp
80104752:	68 6c 72 10 80       	push   $0x8010726c
80104757:	e8 ec bb ff ff       	call   80100348 <panic>
    panic("create: dirlink");
8010475c:	83 ec 0c             	sub    $0xc,%esp
8010475f:	68 78 72 10 80       	push   $0x80107278
80104764:	e8 df bb ff ff       	call   80100348 <panic>
    return 0;
80104769:	89 c3                	mov    %eax,%ebx
8010476b:	e9 04 ff ff ff       	jmp    80104674 <create+0x6e>

80104770 <sys_dup>:
{
80104770:	55                   	push   %ebp
80104771:	89 e5                	mov    %esp,%ebp
80104773:	53                   	push   %ebx
80104774:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104777:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010477a:	ba 00 00 00 00       	mov    $0x0,%edx
8010477f:	b8 00 00 00 00       	mov    $0x0,%eax
80104784:	e8 88 fd ff ff       	call   80104511 <argfd>
80104789:	85 c0                	test   %eax,%eax
8010478b:	78 23                	js     801047b0 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
8010478d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104790:	e8 e3 fd ff ff       	call   80104578 <fdalloc>
80104795:	89 c3                	mov    %eax,%ebx
80104797:	85 c0                	test   %eax,%eax
80104799:	78 1c                	js     801047b7 <sys_dup+0x47>
  filedup(f);
8010479b:	83 ec 0c             	sub    $0xc,%esp
8010479e:	ff 75 f4             	pushl  -0xc(%ebp)
801047a1:	e8 e8 c4 ff ff       	call   80100c8e <filedup>
  return fd;
801047a6:	83 c4 10             	add    $0x10,%esp
}
801047a9:	89 d8                	mov    %ebx,%eax
801047ab:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801047ae:	c9                   	leave  
801047af:	c3                   	ret    
    return -1;
801047b0:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801047b5:	eb f2                	jmp    801047a9 <sys_dup+0x39>
    return -1;
801047b7:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801047bc:	eb eb                	jmp    801047a9 <sys_dup+0x39>

801047be <sys_read>:
{
801047be:	55                   	push   %ebp
801047bf:	89 e5                	mov    %esp,%ebp
801047c1:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801047c4:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801047c7:	ba 00 00 00 00       	mov    $0x0,%edx
801047cc:	b8 00 00 00 00       	mov    $0x0,%eax
801047d1:	e8 3b fd ff ff       	call   80104511 <argfd>
801047d6:	85 c0                	test   %eax,%eax
801047d8:	78 43                	js     8010481d <sys_read+0x5f>
801047da:	83 ec 08             	sub    $0x8,%esp
801047dd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801047e0:	50                   	push   %eax
801047e1:	6a 02                	push   $0x2
801047e3:	e8 11 fc ff ff       	call   801043f9 <argint>
801047e8:	83 c4 10             	add    $0x10,%esp
801047eb:	85 c0                	test   %eax,%eax
801047ed:	78 35                	js     80104824 <sys_read+0x66>
801047ef:	83 ec 04             	sub    $0x4,%esp
801047f2:	ff 75 f0             	pushl  -0x10(%ebp)
801047f5:	8d 45 ec             	lea    -0x14(%ebp),%eax
801047f8:	50                   	push   %eax
801047f9:	6a 01                	push   $0x1
801047fb:	e8 21 fc ff ff       	call   80104421 <argptr>
80104800:	83 c4 10             	add    $0x10,%esp
80104803:	85 c0                	test   %eax,%eax
80104805:	78 24                	js     8010482b <sys_read+0x6d>
  return fileread(f, p, n);
80104807:	83 ec 04             	sub    $0x4,%esp
8010480a:	ff 75 f0             	pushl  -0x10(%ebp)
8010480d:	ff 75 ec             	pushl  -0x14(%ebp)
80104810:	ff 75 f4             	pushl  -0xc(%ebp)
80104813:	e8 bf c5 ff ff       	call   80100dd7 <fileread>
80104818:	83 c4 10             	add    $0x10,%esp
}
8010481b:	c9                   	leave  
8010481c:	c3                   	ret    
    return -1;
8010481d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104822:	eb f7                	jmp    8010481b <sys_read+0x5d>
80104824:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104829:	eb f0                	jmp    8010481b <sys_read+0x5d>
8010482b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104830:	eb e9                	jmp    8010481b <sys_read+0x5d>

80104832 <sys_write>:
{
80104832:	55                   	push   %ebp
80104833:	89 e5                	mov    %esp,%ebp
80104835:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104838:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010483b:	ba 00 00 00 00       	mov    $0x0,%edx
80104840:	b8 00 00 00 00       	mov    $0x0,%eax
80104845:	e8 c7 fc ff ff       	call   80104511 <argfd>
8010484a:	85 c0                	test   %eax,%eax
8010484c:	78 43                	js     80104891 <sys_write+0x5f>
8010484e:	83 ec 08             	sub    $0x8,%esp
80104851:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104854:	50                   	push   %eax
80104855:	6a 02                	push   $0x2
80104857:	e8 9d fb ff ff       	call   801043f9 <argint>
8010485c:	83 c4 10             	add    $0x10,%esp
8010485f:	85 c0                	test   %eax,%eax
80104861:	78 35                	js     80104898 <sys_write+0x66>
80104863:	83 ec 04             	sub    $0x4,%esp
80104866:	ff 75 f0             	pushl  -0x10(%ebp)
80104869:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010486c:	50                   	push   %eax
8010486d:	6a 01                	push   $0x1
8010486f:	e8 ad fb ff ff       	call   80104421 <argptr>
80104874:	83 c4 10             	add    $0x10,%esp
80104877:	85 c0                	test   %eax,%eax
80104879:	78 24                	js     8010489f <sys_write+0x6d>
  return filewrite(f, p, n);
8010487b:	83 ec 04             	sub    $0x4,%esp
8010487e:	ff 75 f0             	pushl  -0x10(%ebp)
80104881:	ff 75 ec             	pushl  -0x14(%ebp)
80104884:	ff 75 f4             	pushl  -0xc(%ebp)
80104887:	e8 d0 c5 ff ff       	call   80100e5c <filewrite>
8010488c:	83 c4 10             	add    $0x10,%esp
}
8010488f:	c9                   	leave  
80104890:	c3                   	ret    
    return -1;
80104891:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104896:	eb f7                	jmp    8010488f <sys_write+0x5d>
80104898:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010489d:	eb f0                	jmp    8010488f <sys_write+0x5d>
8010489f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048a4:	eb e9                	jmp    8010488f <sys_write+0x5d>

801048a6 <sys_close>:
{
801048a6:	55                   	push   %ebp
801048a7:	89 e5                	mov    %esp,%ebp
801048a9:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
801048ac:	8d 4d f0             	lea    -0x10(%ebp),%ecx
801048af:	8d 55 f4             	lea    -0xc(%ebp),%edx
801048b2:	b8 00 00 00 00       	mov    $0x0,%eax
801048b7:	e8 55 fc ff ff       	call   80104511 <argfd>
801048bc:	85 c0                	test   %eax,%eax
801048be:	78 25                	js     801048e5 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
801048c0:	e8 6c e9 ff ff       	call   80103231 <myproc>
801048c5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048c8:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
801048cf:	00 
  fileclose(f);
801048d0:	83 ec 0c             	sub    $0xc,%esp
801048d3:	ff 75 f0             	pushl  -0x10(%ebp)
801048d6:	e8 f8 c3 ff ff       	call   80100cd3 <fileclose>
  return 0;
801048db:	83 c4 10             	add    $0x10,%esp
801048de:	b8 00 00 00 00       	mov    $0x0,%eax
}
801048e3:	c9                   	leave  
801048e4:	c3                   	ret    
    return -1;
801048e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048ea:	eb f7                	jmp    801048e3 <sys_close+0x3d>

801048ec <sys_fstat>:
{
801048ec:	55                   	push   %ebp
801048ed:	89 e5                	mov    %esp,%ebp
801048ef:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801048f2:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801048f5:	ba 00 00 00 00       	mov    $0x0,%edx
801048fa:	b8 00 00 00 00       	mov    $0x0,%eax
801048ff:	e8 0d fc ff ff       	call   80104511 <argfd>
80104904:	85 c0                	test   %eax,%eax
80104906:	78 2a                	js     80104932 <sys_fstat+0x46>
80104908:	83 ec 04             	sub    $0x4,%esp
8010490b:	6a 14                	push   $0x14
8010490d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104910:	50                   	push   %eax
80104911:	6a 01                	push   $0x1
80104913:	e8 09 fb ff ff       	call   80104421 <argptr>
80104918:	83 c4 10             	add    $0x10,%esp
8010491b:	85 c0                	test   %eax,%eax
8010491d:	78 1a                	js     80104939 <sys_fstat+0x4d>
  return filestat(f, st);
8010491f:	83 ec 08             	sub    $0x8,%esp
80104922:	ff 75 f0             	pushl  -0x10(%ebp)
80104925:	ff 75 f4             	pushl  -0xc(%ebp)
80104928:	e8 63 c4 ff ff       	call   80100d90 <filestat>
8010492d:	83 c4 10             	add    $0x10,%esp
}
80104930:	c9                   	leave  
80104931:	c3                   	ret    
    return -1;
80104932:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104937:	eb f7                	jmp    80104930 <sys_fstat+0x44>
80104939:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010493e:	eb f0                	jmp    80104930 <sys_fstat+0x44>

80104940 <sys_link>:
{
80104940:	55                   	push   %ebp
80104941:	89 e5                	mov    %esp,%ebp
80104943:	56                   	push   %esi
80104944:	53                   	push   %ebx
80104945:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104948:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010494b:	50                   	push   %eax
8010494c:	6a 00                	push   $0x0
8010494e:	e8 36 fb ff ff       	call   80104489 <argstr>
80104953:	83 c4 10             	add    $0x10,%esp
80104956:	85 c0                	test   %eax,%eax
80104958:	0f 88 32 01 00 00    	js     80104a90 <sys_link+0x150>
8010495e:	83 ec 08             	sub    $0x8,%esp
80104961:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104964:	50                   	push   %eax
80104965:	6a 01                	push   $0x1
80104967:	e8 1d fb ff ff       	call   80104489 <argstr>
8010496c:	83 c4 10             	add    $0x10,%esp
8010496f:	85 c0                	test   %eax,%eax
80104971:	0f 88 20 01 00 00    	js     80104a97 <sys_link+0x157>
  begin_op();
80104977:	e8 32 de ff ff       	call   801027ae <begin_op>
  if((ip = namei(old)) == 0){
8010497c:	83 ec 0c             	sub    $0xc,%esp
8010497f:	ff 75 e0             	pushl  -0x20(%ebp)
80104982:	e8 5a d2 ff ff       	call   80101be1 <namei>
80104987:	89 c3                	mov    %eax,%ebx
80104989:	83 c4 10             	add    $0x10,%esp
8010498c:	85 c0                	test   %eax,%eax
8010498e:	0f 84 99 00 00 00    	je     80104a2d <sys_link+0xed>
  ilock(ip);
80104994:	83 ec 0c             	sub    $0xc,%esp
80104997:	50                   	push   %eax
80104998:	e8 e4 cb ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
8010499d:	83 c4 10             	add    $0x10,%esp
801049a0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801049a5:	0f 84 8e 00 00 00    	je     80104a39 <sys_link+0xf9>
  ip->nlink++;
801049ab:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801049af:	83 c0 01             	add    $0x1,%eax
801049b2:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801049b6:	83 ec 0c             	sub    $0xc,%esp
801049b9:	53                   	push   %ebx
801049ba:	e8 61 ca ff ff       	call   80101420 <iupdate>
  iunlock(ip);
801049bf:	89 1c 24             	mov    %ebx,(%esp)
801049c2:	e8 7c cc ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801049c7:	83 c4 08             	add    $0x8,%esp
801049ca:	8d 45 ea             	lea    -0x16(%ebp),%eax
801049cd:	50                   	push   %eax
801049ce:	ff 75 e4             	pushl  -0x1c(%ebp)
801049d1:	e8 23 d2 ff ff       	call   80101bf9 <nameiparent>
801049d6:	89 c6                	mov    %eax,%esi
801049d8:	83 c4 10             	add    $0x10,%esp
801049db:	85 c0                	test   %eax,%eax
801049dd:	74 7e                	je     80104a5d <sys_link+0x11d>
  ilock(dp);
801049df:	83 ec 0c             	sub    $0xc,%esp
801049e2:	50                   	push   %eax
801049e3:	e8 99 cb ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801049e8:	83 c4 10             	add    $0x10,%esp
801049eb:	8b 03                	mov    (%ebx),%eax
801049ed:	39 06                	cmp    %eax,(%esi)
801049ef:	75 60                	jne    80104a51 <sys_link+0x111>
801049f1:	83 ec 04             	sub    $0x4,%esp
801049f4:	ff 73 04             	pushl  0x4(%ebx)
801049f7:	8d 45 ea             	lea    -0x16(%ebp),%eax
801049fa:	50                   	push   %eax
801049fb:	56                   	push   %esi
801049fc:	e8 2f d1 ff ff       	call   80101b30 <dirlink>
80104a01:	83 c4 10             	add    $0x10,%esp
80104a04:	85 c0                	test   %eax,%eax
80104a06:	78 49                	js     80104a51 <sys_link+0x111>
  iunlockput(dp);
80104a08:	83 ec 0c             	sub    $0xc,%esp
80104a0b:	56                   	push   %esi
80104a0c:	e8 17 cd ff ff       	call   80101728 <iunlockput>
  iput(ip);
80104a11:	89 1c 24             	mov    %ebx,(%esp)
80104a14:	e8 6f cc ff ff       	call   80101688 <iput>
  end_op();
80104a19:	e8 0a de ff ff       	call   80102828 <end_op>
  return 0;
80104a1e:	83 c4 10             	add    $0x10,%esp
80104a21:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a26:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104a29:	5b                   	pop    %ebx
80104a2a:	5e                   	pop    %esi
80104a2b:	5d                   	pop    %ebp
80104a2c:	c3                   	ret    
    end_op();
80104a2d:	e8 f6 dd ff ff       	call   80102828 <end_op>
    return -1;
80104a32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a37:	eb ed                	jmp    80104a26 <sys_link+0xe6>
    iunlockput(ip);
80104a39:	83 ec 0c             	sub    $0xc,%esp
80104a3c:	53                   	push   %ebx
80104a3d:	e8 e6 cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104a42:	e8 e1 dd ff ff       	call   80102828 <end_op>
    return -1;
80104a47:	83 c4 10             	add    $0x10,%esp
80104a4a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a4f:	eb d5                	jmp    80104a26 <sys_link+0xe6>
    iunlockput(dp);
80104a51:	83 ec 0c             	sub    $0xc,%esp
80104a54:	56                   	push   %esi
80104a55:	e8 ce cc ff ff       	call   80101728 <iunlockput>
    goto bad;
80104a5a:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104a5d:	83 ec 0c             	sub    $0xc,%esp
80104a60:	53                   	push   %ebx
80104a61:	e8 1b cb ff ff       	call   80101581 <ilock>
  ip->nlink--;
80104a66:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104a6a:	83 e8 01             	sub    $0x1,%eax
80104a6d:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104a71:	89 1c 24             	mov    %ebx,(%esp)
80104a74:	e8 a7 c9 ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104a79:	89 1c 24             	mov    %ebx,(%esp)
80104a7c:	e8 a7 cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104a81:	e8 a2 dd ff ff       	call   80102828 <end_op>
  return -1;
80104a86:	83 c4 10             	add    $0x10,%esp
80104a89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a8e:	eb 96                	jmp    80104a26 <sys_link+0xe6>
    return -1;
80104a90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a95:	eb 8f                	jmp    80104a26 <sys_link+0xe6>
80104a97:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a9c:	eb 88                	jmp    80104a26 <sys_link+0xe6>

80104a9e <sys_unlink>:
{
80104a9e:	55                   	push   %ebp
80104a9f:	89 e5                	mov    %esp,%ebp
80104aa1:	57                   	push   %edi
80104aa2:	56                   	push   %esi
80104aa3:	53                   	push   %ebx
80104aa4:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104aa7:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104aaa:	50                   	push   %eax
80104aab:	6a 00                	push   $0x0
80104aad:	e8 d7 f9 ff ff       	call   80104489 <argstr>
80104ab2:	83 c4 10             	add    $0x10,%esp
80104ab5:	85 c0                	test   %eax,%eax
80104ab7:	0f 88 83 01 00 00    	js     80104c40 <sys_unlink+0x1a2>
  begin_op();
80104abd:	e8 ec dc ff ff       	call   801027ae <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104ac2:	83 ec 08             	sub    $0x8,%esp
80104ac5:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104ac8:	50                   	push   %eax
80104ac9:	ff 75 c4             	pushl  -0x3c(%ebp)
80104acc:	e8 28 d1 ff ff       	call   80101bf9 <nameiparent>
80104ad1:	89 c6                	mov    %eax,%esi
80104ad3:	83 c4 10             	add    $0x10,%esp
80104ad6:	85 c0                	test   %eax,%eax
80104ad8:	0f 84 ed 00 00 00    	je     80104bcb <sys_unlink+0x12d>
  ilock(dp);
80104ade:	83 ec 0c             	sub    $0xc,%esp
80104ae1:	50                   	push   %eax
80104ae2:	e8 9a ca ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104ae7:	83 c4 08             	add    $0x8,%esp
80104aea:	68 6a 72 10 80       	push   $0x8010726a
80104aef:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104af2:	50                   	push   %eax
80104af3:	e8 a3 ce ff ff       	call   8010199b <namecmp>
80104af8:	83 c4 10             	add    $0x10,%esp
80104afb:	85 c0                	test   %eax,%eax
80104afd:	0f 84 fc 00 00 00    	je     80104bff <sys_unlink+0x161>
80104b03:	83 ec 08             	sub    $0x8,%esp
80104b06:	68 69 72 10 80       	push   $0x80107269
80104b0b:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104b0e:	50                   	push   %eax
80104b0f:	e8 87 ce ff ff       	call   8010199b <namecmp>
80104b14:	83 c4 10             	add    $0x10,%esp
80104b17:	85 c0                	test   %eax,%eax
80104b19:	0f 84 e0 00 00 00    	je     80104bff <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104b1f:	83 ec 04             	sub    $0x4,%esp
80104b22:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104b25:	50                   	push   %eax
80104b26:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104b29:	50                   	push   %eax
80104b2a:	56                   	push   %esi
80104b2b:	e8 80 ce ff ff       	call   801019b0 <dirlookup>
80104b30:	89 c3                	mov    %eax,%ebx
80104b32:	83 c4 10             	add    $0x10,%esp
80104b35:	85 c0                	test   %eax,%eax
80104b37:	0f 84 c2 00 00 00    	je     80104bff <sys_unlink+0x161>
  ilock(ip);
80104b3d:	83 ec 0c             	sub    $0xc,%esp
80104b40:	50                   	push   %eax
80104b41:	e8 3b ca ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
80104b46:	83 c4 10             	add    $0x10,%esp
80104b49:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104b4e:	0f 8e 83 00 00 00    	jle    80104bd7 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104b54:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104b59:	0f 84 85 00 00 00    	je     80104be4 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104b5f:	83 ec 04             	sub    $0x4,%esp
80104b62:	6a 10                	push   $0x10
80104b64:	6a 00                	push   $0x0
80104b66:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104b69:	57                   	push   %edi
80104b6a:	e8 3f f6 ff ff       	call   801041ae <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104b6f:	6a 10                	push   $0x10
80104b71:	ff 75 c0             	pushl  -0x40(%ebp)
80104b74:	57                   	push   %edi
80104b75:	56                   	push   %esi
80104b76:	e8 f5 cc ff ff       	call   80101870 <writei>
80104b7b:	83 c4 20             	add    $0x20,%esp
80104b7e:	83 f8 10             	cmp    $0x10,%eax
80104b81:	0f 85 90 00 00 00    	jne    80104c17 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104b87:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104b8c:	0f 84 92 00 00 00    	je     80104c24 <sys_unlink+0x186>
  iunlockput(dp);
80104b92:	83 ec 0c             	sub    $0xc,%esp
80104b95:	56                   	push   %esi
80104b96:	e8 8d cb ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
80104b9b:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104b9f:	83 e8 01             	sub    $0x1,%eax
80104ba2:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104ba6:	89 1c 24             	mov    %ebx,(%esp)
80104ba9:	e8 72 c8 ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104bae:	89 1c 24             	mov    %ebx,(%esp)
80104bb1:	e8 72 cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104bb6:	e8 6d dc ff ff       	call   80102828 <end_op>
  return 0;
80104bbb:	83 c4 10             	add    $0x10,%esp
80104bbe:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104bc3:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104bc6:	5b                   	pop    %ebx
80104bc7:	5e                   	pop    %esi
80104bc8:	5f                   	pop    %edi
80104bc9:	5d                   	pop    %ebp
80104bca:	c3                   	ret    
    end_op();
80104bcb:	e8 58 dc ff ff       	call   80102828 <end_op>
    return -1;
80104bd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bd5:	eb ec                	jmp    80104bc3 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104bd7:	83 ec 0c             	sub    $0xc,%esp
80104bda:	68 88 72 10 80       	push   $0x80107288
80104bdf:	e8 64 b7 ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104be4:	89 d8                	mov    %ebx,%eax
80104be6:	e8 c4 f9 ff ff       	call   801045af <isdirempty>
80104beb:	85 c0                	test   %eax,%eax
80104bed:	0f 85 6c ff ff ff    	jne    80104b5f <sys_unlink+0xc1>
    iunlockput(ip);
80104bf3:	83 ec 0c             	sub    $0xc,%esp
80104bf6:	53                   	push   %ebx
80104bf7:	e8 2c cb ff ff       	call   80101728 <iunlockput>
    goto bad;
80104bfc:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104bff:	83 ec 0c             	sub    $0xc,%esp
80104c02:	56                   	push   %esi
80104c03:	e8 20 cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104c08:	e8 1b dc ff ff       	call   80102828 <end_op>
  return -1;
80104c0d:	83 c4 10             	add    $0x10,%esp
80104c10:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c15:	eb ac                	jmp    80104bc3 <sys_unlink+0x125>
    panic("unlink: writei");
80104c17:	83 ec 0c             	sub    $0xc,%esp
80104c1a:	68 9a 72 10 80       	push   $0x8010729a
80104c1f:	e8 24 b7 ff ff       	call   80100348 <panic>
    dp->nlink--;
80104c24:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104c28:	83 e8 01             	sub    $0x1,%eax
80104c2b:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104c2f:	83 ec 0c             	sub    $0xc,%esp
80104c32:	56                   	push   %esi
80104c33:	e8 e8 c7 ff ff       	call   80101420 <iupdate>
80104c38:	83 c4 10             	add    $0x10,%esp
80104c3b:	e9 52 ff ff ff       	jmp    80104b92 <sys_unlink+0xf4>
    return -1;
80104c40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c45:	e9 79 ff ff ff       	jmp    80104bc3 <sys_unlink+0x125>

80104c4a <sys_open>:

int
sys_open(void)
{
80104c4a:	55                   	push   %ebp
80104c4b:	89 e5                	mov    %esp,%ebp
80104c4d:	57                   	push   %edi
80104c4e:	56                   	push   %esi
80104c4f:	53                   	push   %ebx
80104c50:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104c53:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104c56:	50                   	push   %eax
80104c57:	6a 00                	push   $0x0
80104c59:	e8 2b f8 ff ff       	call   80104489 <argstr>
80104c5e:	83 c4 10             	add    $0x10,%esp
80104c61:	85 c0                	test   %eax,%eax
80104c63:	0f 88 30 01 00 00    	js     80104d99 <sys_open+0x14f>
80104c69:	83 ec 08             	sub    $0x8,%esp
80104c6c:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104c6f:	50                   	push   %eax
80104c70:	6a 01                	push   $0x1
80104c72:	e8 82 f7 ff ff       	call   801043f9 <argint>
80104c77:	83 c4 10             	add    $0x10,%esp
80104c7a:	85 c0                	test   %eax,%eax
80104c7c:	0f 88 21 01 00 00    	js     80104da3 <sys_open+0x159>
    return -1;

  begin_op();
80104c82:	e8 27 db ff ff       	call   801027ae <begin_op>

  if(omode & O_CREATE){
80104c87:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104c8b:	0f 84 84 00 00 00    	je     80104d15 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104c91:	83 ec 0c             	sub    $0xc,%esp
80104c94:	6a 00                	push   $0x0
80104c96:	b9 00 00 00 00       	mov    $0x0,%ecx
80104c9b:	ba 02 00 00 00       	mov    $0x2,%edx
80104ca0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104ca3:	e8 5e f9 ff ff       	call   80104606 <create>
80104ca8:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104caa:	83 c4 10             	add    $0x10,%esp
80104cad:	85 c0                	test   %eax,%eax
80104caf:	74 58                	je     80104d09 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104cb1:	e8 77 bf ff ff       	call   80100c2d <filealloc>
80104cb6:	89 c3                	mov    %eax,%ebx
80104cb8:	85 c0                	test   %eax,%eax
80104cba:	0f 84 ae 00 00 00    	je     80104d6e <sys_open+0x124>
80104cc0:	e8 b3 f8 ff ff       	call   80104578 <fdalloc>
80104cc5:	89 c7                	mov    %eax,%edi
80104cc7:	85 c0                	test   %eax,%eax
80104cc9:	0f 88 9f 00 00 00    	js     80104d6e <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104ccf:	83 ec 0c             	sub    $0xc,%esp
80104cd2:	56                   	push   %esi
80104cd3:	e8 6b c9 ff ff       	call   80101643 <iunlock>
  end_op();
80104cd8:	e8 4b db ff ff       	call   80102828 <end_op>

  f->type = FD_INODE;
80104cdd:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104ce3:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104ce6:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104ced:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104cf0:	83 c4 10             	add    $0x10,%esp
80104cf3:	a8 01                	test   $0x1,%al
80104cf5:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104cf9:	a8 03                	test   $0x3,%al
80104cfb:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104cff:	89 f8                	mov    %edi,%eax
80104d01:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104d04:	5b                   	pop    %ebx
80104d05:	5e                   	pop    %esi
80104d06:	5f                   	pop    %edi
80104d07:	5d                   	pop    %ebp
80104d08:	c3                   	ret    
      end_op();
80104d09:	e8 1a db ff ff       	call   80102828 <end_op>
      return -1;
80104d0e:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d13:	eb ea                	jmp    80104cff <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104d15:	83 ec 0c             	sub    $0xc,%esp
80104d18:	ff 75 e4             	pushl  -0x1c(%ebp)
80104d1b:	e8 c1 ce ff ff       	call   80101be1 <namei>
80104d20:	89 c6                	mov    %eax,%esi
80104d22:	83 c4 10             	add    $0x10,%esp
80104d25:	85 c0                	test   %eax,%eax
80104d27:	74 39                	je     80104d62 <sys_open+0x118>
    ilock(ip);
80104d29:	83 ec 0c             	sub    $0xc,%esp
80104d2c:	50                   	push   %eax
80104d2d:	e8 4f c8 ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104d32:	83 c4 10             	add    $0x10,%esp
80104d35:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104d3a:	0f 85 71 ff ff ff    	jne    80104cb1 <sys_open+0x67>
80104d40:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104d44:	0f 84 67 ff ff ff    	je     80104cb1 <sys_open+0x67>
      iunlockput(ip);
80104d4a:	83 ec 0c             	sub    $0xc,%esp
80104d4d:	56                   	push   %esi
80104d4e:	e8 d5 c9 ff ff       	call   80101728 <iunlockput>
      end_op();
80104d53:	e8 d0 da ff ff       	call   80102828 <end_op>
      return -1;
80104d58:	83 c4 10             	add    $0x10,%esp
80104d5b:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d60:	eb 9d                	jmp    80104cff <sys_open+0xb5>
      end_op();
80104d62:	e8 c1 da ff ff       	call   80102828 <end_op>
      return -1;
80104d67:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d6c:	eb 91                	jmp    80104cff <sys_open+0xb5>
    if(f)
80104d6e:	85 db                	test   %ebx,%ebx
80104d70:	74 0c                	je     80104d7e <sys_open+0x134>
      fileclose(f);
80104d72:	83 ec 0c             	sub    $0xc,%esp
80104d75:	53                   	push   %ebx
80104d76:	e8 58 bf ff ff       	call   80100cd3 <fileclose>
80104d7b:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104d7e:	83 ec 0c             	sub    $0xc,%esp
80104d81:	56                   	push   %esi
80104d82:	e8 a1 c9 ff ff       	call   80101728 <iunlockput>
    end_op();
80104d87:	e8 9c da ff ff       	call   80102828 <end_op>
    return -1;
80104d8c:	83 c4 10             	add    $0x10,%esp
80104d8f:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d94:	e9 66 ff ff ff       	jmp    80104cff <sys_open+0xb5>
    return -1;
80104d99:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d9e:	e9 5c ff ff ff       	jmp    80104cff <sys_open+0xb5>
80104da3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104da8:	e9 52 ff ff ff       	jmp    80104cff <sys_open+0xb5>

80104dad <sys_mkdir>:

int
sys_mkdir(void)
{
80104dad:	55                   	push   %ebp
80104dae:	89 e5                	mov    %esp,%ebp
80104db0:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104db3:	e8 f6 d9 ff ff       	call   801027ae <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104db8:	83 ec 08             	sub    $0x8,%esp
80104dbb:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dbe:	50                   	push   %eax
80104dbf:	6a 00                	push   $0x0
80104dc1:	e8 c3 f6 ff ff       	call   80104489 <argstr>
80104dc6:	83 c4 10             	add    $0x10,%esp
80104dc9:	85 c0                	test   %eax,%eax
80104dcb:	78 36                	js     80104e03 <sys_mkdir+0x56>
80104dcd:	83 ec 0c             	sub    $0xc,%esp
80104dd0:	6a 00                	push   $0x0
80104dd2:	b9 00 00 00 00       	mov    $0x0,%ecx
80104dd7:	ba 01 00 00 00       	mov    $0x1,%edx
80104ddc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ddf:	e8 22 f8 ff ff       	call   80104606 <create>
80104de4:	83 c4 10             	add    $0x10,%esp
80104de7:	85 c0                	test   %eax,%eax
80104de9:	74 18                	je     80104e03 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104deb:	83 ec 0c             	sub    $0xc,%esp
80104dee:	50                   	push   %eax
80104def:	e8 34 c9 ff ff       	call   80101728 <iunlockput>
  end_op();
80104df4:	e8 2f da ff ff       	call   80102828 <end_op>
  return 0;
80104df9:	83 c4 10             	add    $0x10,%esp
80104dfc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e01:	c9                   	leave  
80104e02:	c3                   	ret    
    end_op();
80104e03:	e8 20 da ff ff       	call   80102828 <end_op>
    return -1;
80104e08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e0d:	eb f2                	jmp    80104e01 <sys_mkdir+0x54>

80104e0f <sys_mknod>:

int
sys_mknod(void)
{
80104e0f:	55                   	push   %ebp
80104e10:	89 e5                	mov    %esp,%ebp
80104e12:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104e15:	e8 94 d9 ff ff       	call   801027ae <begin_op>
  if((argstr(0, &path)) < 0 ||
80104e1a:	83 ec 08             	sub    $0x8,%esp
80104e1d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e20:	50                   	push   %eax
80104e21:	6a 00                	push   $0x0
80104e23:	e8 61 f6 ff ff       	call   80104489 <argstr>
80104e28:	83 c4 10             	add    $0x10,%esp
80104e2b:	85 c0                	test   %eax,%eax
80104e2d:	78 62                	js     80104e91 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104e2f:	83 ec 08             	sub    $0x8,%esp
80104e32:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104e35:	50                   	push   %eax
80104e36:	6a 01                	push   $0x1
80104e38:	e8 bc f5 ff ff       	call   801043f9 <argint>
  if((argstr(0, &path)) < 0 ||
80104e3d:	83 c4 10             	add    $0x10,%esp
80104e40:	85 c0                	test   %eax,%eax
80104e42:	78 4d                	js     80104e91 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104e44:	83 ec 08             	sub    $0x8,%esp
80104e47:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104e4a:	50                   	push   %eax
80104e4b:	6a 02                	push   $0x2
80104e4d:	e8 a7 f5 ff ff       	call   801043f9 <argint>
     argint(1, &major) < 0 ||
80104e52:	83 c4 10             	add    $0x10,%esp
80104e55:	85 c0                	test   %eax,%eax
80104e57:	78 38                	js     80104e91 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104e59:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104e5d:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104e61:	83 ec 0c             	sub    $0xc,%esp
80104e64:	50                   	push   %eax
80104e65:	ba 03 00 00 00       	mov    $0x3,%edx
80104e6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e6d:	e8 94 f7 ff ff       	call   80104606 <create>
80104e72:	83 c4 10             	add    $0x10,%esp
80104e75:	85 c0                	test   %eax,%eax
80104e77:	74 18                	je     80104e91 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104e79:	83 ec 0c             	sub    $0xc,%esp
80104e7c:	50                   	push   %eax
80104e7d:	e8 a6 c8 ff ff       	call   80101728 <iunlockput>
  end_op();
80104e82:	e8 a1 d9 ff ff       	call   80102828 <end_op>
  return 0;
80104e87:	83 c4 10             	add    $0x10,%esp
80104e8a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e8f:	c9                   	leave  
80104e90:	c3                   	ret    
    end_op();
80104e91:	e8 92 d9 ff ff       	call   80102828 <end_op>
    return -1;
80104e96:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e9b:	eb f2                	jmp    80104e8f <sys_mknod+0x80>

80104e9d <sys_chdir>:

int
sys_chdir(void)
{
80104e9d:	55                   	push   %ebp
80104e9e:	89 e5                	mov    %esp,%ebp
80104ea0:	56                   	push   %esi
80104ea1:	53                   	push   %ebx
80104ea2:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104ea5:	e8 87 e3 ff ff       	call   80103231 <myproc>
80104eaa:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104eac:	e8 fd d8 ff ff       	call   801027ae <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104eb1:	83 ec 08             	sub    $0x8,%esp
80104eb4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104eb7:	50                   	push   %eax
80104eb8:	6a 00                	push   $0x0
80104eba:	e8 ca f5 ff ff       	call   80104489 <argstr>
80104ebf:	83 c4 10             	add    $0x10,%esp
80104ec2:	85 c0                	test   %eax,%eax
80104ec4:	78 52                	js     80104f18 <sys_chdir+0x7b>
80104ec6:	83 ec 0c             	sub    $0xc,%esp
80104ec9:	ff 75 f4             	pushl  -0xc(%ebp)
80104ecc:	e8 10 cd ff ff       	call   80101be1 <namei>
80104ed1:	89 c3                	mov    %eax,%ebx
80104ed3:	83 c4 10             	add    $0x10,%esp
80104ed6:	85 c0                	test   %eax,%eax
80104ed8:	74 3e                	je     80104f18 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104eda:	83 ec 0c             	sub    $0xc,%esp
80104edd:	50                   	push   %eax
80104ede:	e8 9e c6 ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104ee3:	83 c4 10             	add    $0x10,%esp
80104ee6:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104eeb:	75 37                	jne    80104f24 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104eed:	83 ec 0c             	sub    $0xc,%esp
80104ef0:	53                   	push   %ebx
80104ef1:	e8 4d c7 ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104ef6:	83 c4 04             	add    $0x4,%esp
80104ef9:	ff 76 68             	pushl  0x68(%esi)
80104efc:	e8 87 c7 ff ff       	call   80101688 <iput>
  end_op();
80104f01:	e8 22 d9 ff ff       	call   80102828 <end_op>
  curproc->cwd = ip;
80104f06:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104f09:	83 c4 10             	add    $0x10,%esp
80104f0c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f11:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104f14:	5b                   	pop    %ebx
80104f15:	5e                   	pop    %esi
80104f16:	5d                   	pop    %ebp
80104f17:	c3                   	ret    
    end_op();
80104f18:	e8 0b d9 ff ff       	call   80102828 <end_op>
    return -1;
80104f1d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f22:	eb ed                	jmp    80104f11 <sys_chdir+0x74>
    iunlockput(ip);
80104f24:	83 ec 0c             	sub    $0xc,%esp
80104f27:	53                   	push   %ebx
80104f28:	e8 fb c7 ff ff       	call   80101728 <iunlockput>
    end_op();
80104f2d:	e8 f6 d8 ff ff       	call   80102828 <end_op>
    return -1;
80104f32:	83 c4 10             	add    $0x10,%esp
80104f35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f3a:	eb d5                	jmp    80104f11 <sys_chdir+0x74>

80104f3c <sys_exec>:

int
sys_exec(void)
{
80104f3c:	55                   	push   %ebp
80104f3d:	89 e5                	mov    %esp,%ebp
80104f3f:	53                   	push   %ebx
80104f40:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104f46:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f49:	50                   	push   %eax
80104f4a:	6a 00                	push   $0x0
80104f4c:	e8 38 f5 ff ff       	call   80104489 <argstr>
80104f51:	83 c4 10             	add    $0x10,%esp
80104f54:	85 c0                	test   %eax,%eax
80104f56:	0f 88 a8 00 00 00    	js     80105004 <sys_exec+0xc8>
80104f5c:	83 ec 08             	sub    $0x8,%esp
80104f5f:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104f65:	50                   	push   %eax
80104f66:	6a 01                	push   $0x1
80104f68:	e8 8c f4 ff ff       	call   801043f9 <argint>
80104f6d:	83 c4 10             	add    $0x10,%esp
80104f70:	85 c0                	test   %eax,%eax
80104f72:	0f 88 93 00 00 00    	js     8010500b <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104f78:	83 ec 04             	sub    $0x4,%esp
80104f7b:	68 80 00 00 00       	push   $0x80
80104f80:	6a 00                	push   $0x0
80104f82:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104f88:	50                   	push   %eax
80104f89:	e8 20 f2 ff ff       	call   801041ae <memset>
80104f8e:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104f91:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104f96:	83 fb 1f             	cmp    $0x1f,%ebx
80104f99:	77 77                	ja     80105012 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104f9b:	83 ec 08             	sub    $0x8,%esp
80104f9e:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104fa4:	50                   	push   %eax
80104fa5:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104fab:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104fae:	50                   	push   %eax
80104faf:	e8 c9 f3 ff ff       	call   8010437d <fetchint>
80104fb4:	83 c4 10             	add    $0x10,%esp
80104fb7:	85 c0                	test   %eax,%eax
80104fb9:	78 5e                	js     80105019 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104fbb:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104fc1:	85 c0                	test   %eax,%eax
80104fc3:	74 1d                	je     80104fe2 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104fc5:	83 ec 08             	sub    $0x8,%esp
80104fc8:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104fcf:	52                   	push   %edx
80104fd0:	50                   	push   %eax
80104fd1:	e8 e3 f3 ff ff       	call   801043b9 <fetchstr>
80104fd6:	83 c4 10             	add    $0x10,%esp
80104fd9:	85 c0                	test   %eax,%eax
80104fdb:	78 46                	js     80105023 <sys_exec+0xe7>
  for(i=0;; i++){
80104fdd:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104fe0:	eb b4                	jmp    80104f96 <sys_exec+0x5a>
      argv[i] = 0;
80104fe2:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104fe9:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104fed:	83 ec 08             	sub    $0x8,%esp
80104ff0:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104ff6:	50                   	push   %eax
80104ff7:	ff 75 f4             	pushl  -0xc(%ebp)
80104ffa:	e8 d3 b8 ff ff       	call   801008d2 <exec>
80104fff:	83 c4 10             	add    $0x10,%esp
80105002:	eb 1a                	jmp    8010501e <sys_exec+0xe2>
    return -1;
80105004:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105009:	eb 13                	jmp    8010501e <sys_exec+0xe2>
8010500b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105010:	eb 0c                	jmp    8010501e <sys_exec+0xe2>
      return -1;
80105012:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105017:	eb 05                	jmp    8010501e <sys_exec+0xe2>
      return -1;
80105019:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010501e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105021:	c9                   	leave  
80105022:	c3                   	ret    
      return -1;
80105023:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105028:	eb f4                	jmp    8010501e <sys_exec+0xe2>

8010502a <sys_pipe>:

int
sys_pipe(void)
{
8010502a:	55                   	push   %ebp
8010502b:	89 e5                	mov    %esp,%ebp
8010502d:	53                   	push   %ebx
8010502e:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80105031:	6a 08                	push   $0x8
80105033:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105036:	50                   	push   %eax
80105037:	6a 00                	push   $0x0
80105039:	e8 e3 f3 ff ff       	call   80104421 <argptr>
8010503e:	83 c4 10             	add    $0x10,%esp
80105041:	85 c0                	test   %eax,%eax
80105043:	78 77                	js     801050bc <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80105045:	83 ec 08             	sub    $0x8,%esp
80105048:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010504b:	50                   	push   %eax
8010504c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010504f:	50                   	push   %eax
80105050:	e8 e0 dc ff ff       	call   80102d35 <pipealloc>
80105055:	83 c4 10             	add    $0x10,%esp
80105058:	85 c0                	test   %eax,%eax
8010505a:	78 67                	js     801050c3 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
8010505c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010505f:	e8 14 f5 ff ff       	call   80104578 <fdalloc>
80105064:	89 c3                	mov    %eax,%ebx
80105066:	85 c0                	test   %eax,%eax
80105068:	78 21                	js     8010508b <sys_pipe+0x61>
8010506a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010506d:	e8 06 f5 ff ff       	call   80104578 <fdalloc>
80105072:	85 c0                	test   %eax,%eax
80105074:	78 15                	js     8010508b <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80105076:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105079:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
8010507b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010507e:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80105081:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105086:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105089:	c9                   	leave  
8010508a:	c3                   	ret    
    if(fd0 >= 0)
8010508b:	85 db                	test   %ebx,%ebx
8010508d:	78 0d                	js     8010509c <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
8010508f:	e8 9d e1 ff ff       	call   80103231 <myproc>
80105094:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
8010509b:	00 
    fileclose(rf);
8010509c:	83 ec 0c             	sub    $0xc,%esp
8010509f:	ff 75 f0             	pushl  -0x10(%ebp)
801050a2:	e8 2c bc ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
801050a7:	83 c4 04             	add    $0x4,%esp
801050aa:	ff 75 ec             	pushl  -0x14(%ebp)
801050ad:	e8 21 bc ff ff       	call   80100cd3 <fileclose>
    return -1;
801050b2:	83 c4 10             	add    $0x10,%esp
801050b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050ba:	eb ca                	jmp    80105086 <sys_pipe+0x5c>
    return -1;
801050bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050c1:	eb c3                	jmp    80105086 <sys_pipe+0x5c>
    return -1;
801050c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050c8:	eb bc                	jmp    80105086 <sys_pipe+0x5c>

801050ca <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801050ca:	55                   	push   %ebp
801050cb:	89 e5                	mov    %esp,%ebp
801050cd:	83 ec 08             	sub    $0x8,%esp
  return fork();
801050d0:	e8 5b ed ff ff       	call   80103e30 <fork>
}
801050d5:	c9                   	leave  
801050d6:	c3                   	ret    

801050d7 <sys_exit>:

int
sys_exit(void)
{
801050d7:	55                   	push   %ebp
801050d8:	89 e5                	mov    %esp,%ebp
801050da:	83 ec 08             	sub    $0x8,%esp
  exit();
801050dd:	e8 d1 e3 ff ff       	call   801034b3 <exit>
  return 0;  // not reached
}
801050e2:	b8 00 00 00 00       	mov    $0x0,%eax
801050e7:	c9                   	leave  
801050e8:	c3                   	ret    

801050e9 <sys_wait>:

int
sys_wait(void)
{
801050e9:	55                   	push   %ebp
801050ea:	89 e5                	mov    %esp,%ebp
801050ec:	83 ec 08             	sub    $0x8,%esp
  return wait();
801050ef:	e8 4b e5 ff ff       	call   8010363f <wait>
}
801050f4:	c9                   	leave  
801050f5:	c3                   	ret    

801050f6 <sys_kill>:

int
sys_kill(void)
{
801050f6:	55                   	push   %ebp
801050f7:	89 e5                	mov    %esp,%ebp
801050f9:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
801050fc:	8d 45 f4             	lea    -0xc(%ebp),%eax
801050ff:	50                   	push   %eax
80105100:	6a 00                	push   $0x0
80105102:	e8 f2 f2 ff ff       	call   801043f9 <argint>
80105107:	83 c4 10             	add    $0x10,%esp
8010510a:	85 c0                	test   %eax,%eax
8010510c:	78 10                	js     8010511e <sys_kill+0x28>
    return -1;
  return kill(pid);
8010510e:	83 ec 0c             	sub    $0xc,%esp
80105111:	ff 75 f4             	pushl  -0xc(%ebp)
80105114:	e8 26 e6 ff ff       	call   8010373f <kill>
80105119:	83 c4 10             	add    $0x10,%esp
}
8010511c:	c9                   	leave  
8010511d:	c3                   	ret    
    return -1;
8010511e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105123:	eb f7                	jmp    8010511c <sys_kill+0x26>

80105125 <sys_getpid>:

int
sys_getpid(void)
{
80105125:	55                   	push   %ebp
80105126:	89 e5                	mov    %esp,%ebp
80105128:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
8010512b:	e8 01 e1 ff ff       	call   80103231 <myproc>
80105130:	8b 40 10             	mov    0x10(%eax),%eax
}
80105133:	c9                   	leave  
80105134:	c3                   	ret    

80105135 <sys_sbrk>:

int
sys_sbrk(void)
{
80105135:	55                   	push   %ebp
80105136:	89 e5                	mov    %esp,%ebp
80105138:	53                   	push   %ebx
80105139:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
8010513c:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010513f:	50                   	push   %eax
80105140:	6a 00                	push   $0x0
80105142:	e8 b2 f2 ff ff       	call   801043f9 <argint>
80105147:	83 c4 10             	add    $0x10,%esp
8010514a:	85 c0                	test   %eax,%eax
8010514c:	78 27                	js     80105175 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
8010514e:	e8 de e0 ff ff       	call   80103231 <myproc>
80105153:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80105155:	83 ec 0c             	sub    $0xc,%esp
80105158:	ff 75 f4             	pushl  -0xc(%ebp)
8010515b:	e8 43 e2 ff ff       	call   801033a3 <growproc>
80105160:	83 c4 10             	add    $0x10,%esp
80105163:	85 c0                	test   %eax,%eax
80105165:	78 07                	js     8010516e <sys_sbrk+0x39>
    return -1;
  return addr;
}
80105167:	89 d8                	mov    %ebx,%eax
80105169:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010516c:	c9                   	leave  
8010516d:	c3                   	ret    
    return -1;
8010516e:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80105173:	eb f2                	jmp    80105167 <sys_sbrk+0x32>
    return -1;
80105175:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010517a:	eb eb                	jmp    80105167 <sys_sbrk+0x32>

8010517c <sys_sleep>:

int
sys_sleep(void)
{
8010517c:	55                   	push   %ebp
8010517d:	89 e5                	mov    %esp,%ebp
8010517f:	53                   	push   %ebx
80105180:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80105183:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105186:	50                   	push   %eax
80105187:	6a 00                	push   $0x0
80105189:	e8 6b f2 ff ff       	call   801043f9 <argint>
8010518e:	83 c4 10             	add    $0x10,%esp
80105191:	85 c0                	test   %eax,%eax
80105193:	78 75                	js     8010520a <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80105195:	83 ec 0c             	sub    $0xc,%esp
80105198:	68 80 63 11 80       	push   $0x80116380
8010519d:	e8 60 ef ff ff       	call   80104102 <acquire>
  ticks0 = ticks;
801051a2:	8b 1d c0 6b 11 80    	mov    0x80116bc0,%ebx
  while(ticks - ticks0 < n){
801051a8:	83 c4 10             	add    $0x10,%esp
801051ab:	a1 c0 6b 11 80       	mov    0x80116bc0,%eax
801051b0:	29 d8                	sub    %ebx,%eax
801051b2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801051b5:	73 39                	jae    801051f0 <sys_sleep+0x74>
    if(myproc()->killed){
801051b7:	e8 75 e0 ff ff       	call   80103231 <myproc>
801051bc:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801051c0:	75 17                	jne    801051d9 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
801051c2:	83 ec 08             	sub    $0x8,%esp
801051c5:	68 80 63 11 80       	push   $0x80116380
801051ca:	68 c0 6b 11 80       	push   $0x80116bc0
801051cf:	e8 da e3 ff ff       	call   801035ae <sleep>
801051d4:	83 c4 10             	add    $0x10,%esp
801051d7:	eb d2                	jmp    801051ab <sys_sleep+0x2f>
      release(&tickslock);
801051d9:	83 ec 0c             	sub    $0xc,%esp
801051dc:	68 80 63 11 80       	push   $0x80116380
801051e1:	e8 81 ef ff ff       	call   80104167 <release>
      return -1;
801051e6:	83 c4 10             	add    $0x10,%esp
801051e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051ee:	eb 15                	jmp    80105205 <sys_sleep+0x89>
  }
  release(&tickslock);
801051f0:	83 ec 0c             	sub    $0xc,%esp
801051f3:	68 80 63 11 80       	push   $0x80116380
801051f8:	e8 6a ef ff ff       	call   80104167 <release>
  return 0;
801051fd:	83 c4 10             	add    $0x10,%esp
80105200:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105205:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105208:	c9                   	leave  
80105209:	c3                   	ret    
    return -1;
8010520a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010520f:	eb f4                	jmp    80105205 <sys_sleep+0x89>

80105211 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80105211:	55                   	push   %ebp
80105212:	89 e5                	mov    %esp,%ebp
80105214:	53                   	push   %ebx
80105215:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80105218:	68 80 63 11 80       	push   $0x80116380
8010521d:	e8 e0 ee ff ff       	call   80104102 <acquire>
  xticks = ticks;
80105222:	8b 1d c0 6b 11 80    	mov    0x80116bc0,%ebx
  release(&tickslock);
80105228:	c7 04 24 80 63 11 80 	movl   $0x80116380,(%esp)
8010522f:	e8 33 ef ff ff       	call   80104167 <release>
  return xticks;
}
80105234:	89 d8                	mov    %ebx,%eax
80105236:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105239:	c9                   	leave  
8010523a:	c3                   	ret    

8010523b <sys_setpri>:


// This sets the priority of the specified PID to pri
// return -1 if pri or PID are invalid
int
sys_setpri(void){
8010523b:	55                   	push   %ebp
8010523c:	89 e5                	mov    %esp,%ebp
8010523e:	83 ec 20             	sub    $0x20,%esp
    int PID;
    int pri;

    if(argint(0, &PID) < 0 || argint(1, &pri) < 0){
80105241:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105244:	50                   	push   %eax
80105245:	6a 00                	push   $0x0
80105247:	e8 ad f1 ff ff       	call   801043f9 <argint>
8010524c:	83 c4 10             	add    $0x10,%esp
8010524f:	85 c0                	test   %eax,%eax
80105251:	78 28                	js     8010527b <sys_setpri+0x40>
80105253:	83 ec 08             	sub    $0x8,%esp
80105256:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105259:	50                   	push   %eax
8010525a:	6a 01                	push   $0x1
8010525c:	e8 98 f1 ff ff       	call   801043f9 <argint>
80105261:	83 c4 10             	add    $0x10,%esp
80105264:	85 c0                	test   %eax,%eax
80105266:	78 1a                	js     80105282 <sys_setpri+0x47>
        return -1;
    }

    int rc = setpri(PID, pri);
80105268:	83 ec 08             	sub    $0x8,%esp
8010526b:	ff 75 f0             	pushl  -0x10(%ebp)
8010526e:	ff 75 f4             	pushl  -0xc(%ebp)
80105271:	e8 f4 e5 ff ff       	call   8010386a <setpri>
    return rc;
80105276:	83 c4 10             	add    $0x10,%esp
}
80105279:	c9                   	leave  
8010527a:	c3                   	ret    
        return -1;
8010527b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105280:	eb f7                	jmp    80105279 <sys_setpri+0x3e>
80105282:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105287:	eb f0                	jmp    80105279 <sys_setpri+0x3e>

80105289 <sys_getpri>:

// returns the current priority of the specified PID.  If the PID is not valid, it returns -1
int
sys_getpri(void){
80105289:	55                   	push   %ebp
8010528a:	89 e5                	mov    %esp,%ebp
8010528c:	83 ec 20             	sub    $0x20,%esp
    int PID;

    if(argint(0, &PID) < 0){
8010528f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105292:	50                   	push   %eax
80105293:	6a 00                	push   $0x0
80105295:	e8 5f f1 ff ff       	call   801043f9 <argint>
8010529a:	83 c4 10             	add    $0x10,%esp
8010529d:	85 c0                	test   %eax,%eax
8010529f:	78 10                	js     801052b1 <sys_getpri+0x28>
        return -1;
    }

    int rc = getpri(PID);
801052a1:	83 ec 0c             	sub    $0xc,%esp
801052a4:	ff 75 f4             	pushl  -0xc(%ebp)
801052a7:	e8 3d e6 ff ff       	call   801038e9 <getpri>
    return rc;
801052ac:	83 c4 10             	add    $0x10,%esp
}
801052af:	c9                   	leave  
801052b0:	c3                   	ret    
        return -1;
801052b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052b6:	eb f7                	jmp    801052af <sys_getpri+0x26>

801052b8 <sys_fork2>:

//
int
sys_fork2(void){
801052b8:	55                   	push   %ebp
801052b9:	89 e5                	mov    %esp,%ebp
801052bb:	83 ec 20             	sub    $0x20,%esp

    int pri;

    if(argint(0, &pri) < 0){
801052be:	8d 45 f4             	lea    -0xc(%ebp),%eax
801052c1:	50                   	push   %eax
801052c2:	6a 00                	push   $0x0
801052c4:	e8 30 f1 ff ff       	call   801043f9 <argint>
801052c9:	83 c4 10             	add    $0x10,%esp
801052cc:	85 c0                	test   %eax,%eax
801052ce:	78 10                	js     801052e0 <sys_fork2+0x28>
        return -1;
    }

    int rc = fork2(pri);
801052d0:	83 ec 0c             	sub    $0xc,%esp
801052d3:	ff 75 f4             	pushl  -0xc(%ebp)
801052d6:	e8 64 e9 ff ff       	call   80103c3f <fork2>
    return rc;
801052db:	83 c4 10             	add    $0x10,%esp
}
801052de:	c9                   	leave  
801052df:	c3                   	ret    
        return -1;
801052e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052e5:	eb f7                	jmp    801052de <sys_fork2+0x26>

801052e7 <sys_getpinfo>:

// returns 0 on success and -1 on failure
int
sys_getpinfo(void){
801052e7:	55                   	push   %ebp
801052e8:	89 e5                	mov    %esp,%ebp
//    }
//
//    int rc = getpinfo(ptr);
//    return rc;
    return -1;
}
801052ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052ef:	5d                   	pop    %ebp
801052f0:	c3                   	ret    

801052f1 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801052f1:	1e                   	push   %ds
  pushl %es
801052f2:	06                   	push   %es
  pushl %fs
801052f3:	0f a0                	push   %fs
  pushl %gs
801052f5:	0f a8                	push   %gs
  pushal
801052f7:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
801052f8:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801052fc:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801052fe:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80105300:	54                   	push   %esp
  call trap
80105301:	e8 e3 00 00 00       	call   801053e9 <trap>
  addl $4, %esp
80105306:	83 c4 04             	add    $0x4,%esp

80105309 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80105309:	61                   	popa   
  popl %gs
8010530a:	0f a9                	pop    %gs
  popl %fs
8010530c:	0f a1                	pop    %fs
  popl %es
8010530e:	07                   	pop    %es
  popl %ds
8010530f:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80105310:	83 c4 08             	add    $0x8,%esp
  iret
80105313:	cf                   	iret   

80105314 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80105314:	55                   	push   %ebp
80105315:	89 e5                	mov    %esp,%ebp
80105317:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
8010531a:	b8 00 00 00 00       	mov    $0x0,%eax
8010531f:	eb 4a                	jmp    8010536b <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80105321:	8b 0c 85 18 a0 10 80 	mov    -0x7fef5fe8(,%eax,4),%ecx
80105328:	66 89 0c c5 c0 63 11 	mov    %cx,-0x7fee9c40(,%eax,8)
8010532f:	80 
80105330:	66 c7 04 c5 c2 63 11 	movw   $0x8,-0x7fee9c3e(,%eax,8)
80105337:	80 08 00 
8010533a:	c6 04 c5 c4 63 11 80 	movb   $0x0,-0x7fee9c3c(,%eax,8)
80105341:	00 
80105342:	0f b6 14 c5 c5 63 11 	movzbl -0x7fee9c3b(,%eax,8),%edx
80105349:	80 
8010534a:	83 e2 f0             	and    $0xfffffff0,%edx
8010534d:	83 ca 0e             	or     $0xe,%edx
80105350:	83 e2 8f             	and    $0xffffff8f,%edx
80105353:	83 ca 80             	or     $0xffffff80,%edx
80105356:	88 14 c5 c5 63 11 80 	mov    %dl,-0x7fee9c3b(,%eax,8)
8010535d:	c1 e9 10             	shr    $0x10,%ecx
80105360:	66 89 0c c5 c6 63 11 	mov    %cx,-0x7fee9c3a(,%eax,8)
80105367:	80 
  for(i = 0; i < 256; i++)
80105368:	83 c0 01             	add    $0x1,%eax
8010536b:	3d ff 00 00 00       	cmp    $0xff,%eax
80105370:	7e af                	jle    80105321 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80105372:	8b 15 18 a1 10 80    	mov    0x8010a118,%edx
80105378:	66 89 15 c0 65 11 80 	mov    %dx,0x801165c0
8010537f:	66 c7 05 c2 65 11 80 	movw   $0x8,0x801165c2
80105386:	08 00 
80105388:	c6 05 c4 65 11 80 00 	movb   $0x0,0x801165c4
8010538f:	0f b6 05 c5 65 11 80 	movzbl 0x801165c5,%eax
80105396:	83 c8 0f             	or     $0xf,%eax
80105399:	83 e0 ef             	and    $0xffffffef,%eax
8010539c:	83 c8 e0             	or     $0xffffffe0,%eax
8010539f:	a2 c5 65 11 80       	mov    %al,0x801165c5
801053a4:	c1 ea 10             	shr    $0x10,%edx
801053a7:	66 89 15 c6 65 11 80 	mov    %dx,0x801165c6

  initlock(&tickslock, "time");
801053ae:	83 ec 08             	sub    $0x8,%esp
801053b1:	68 a9 72 10 80       	push   $0x801072a9
801053b6:	68 80 63 11 80       	push   $0x80116380
801053bb:	e8 06 ec ff ff       	call   80103fc6 <initlock>
}
801053c0:	83 c4 10             	add    $0x10,%esp
801053c3:	c9                   	leave  
801053c4:	c3                   	ret    

801053c5 <idtinit>:

void
idtinit(void)
{
801053c5:	55                   	push   %ebp
801053c6:	89 e5                	mov    %esp,%ebp
801053c8:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
801053cb:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
801053d1:	b8 c0 63 11 80       	mov    $0x801163c0,%eax
801053d6:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801053da:	c1 e8 10             	shr    $0x10,%eax
801053dd:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
801053e1:	8d 45 fa             	lea    -0x6(%ebp),%eax
801053e4:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
801053e7:	c9                   	leave  
801053e8:	c3                   	ret    

801053e9 <trap>:

void
trap(struct trapframe *tf)
{
801053e9:	55                   	push   %ebp
801053ea:	89 e5                	mov    %esp,%ebp
801053ec:	57                   	push   %edi
801053ed:	56                   	push   %esi
801053ee:	53                   	push   %ebx
801053ef:	83 ec 1c             	sub    $0x1c,%esp
801053f2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
801053f5:	8b 43 30             	mov    0x30(%ebx),%eax
801053f8:	83 f8 40             	cmp    $0x40,%eax
801053fb:	74 13                	je     80105410 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
801053fd:	83 e8 20             	sub    $0x20,%eax
80105400:	83 f8 1f             	cmp    $0x1f,%eax
80105403:	0f 87 3a 01 00 00    	ja     80105543 <trap+0x15a>
80105409:	ff 24 85 50 73 10 80 	jmp    *-0x7fef8cb0(,%eax,4)
    if(myproc()->killed)
80105410:	e8 1c de ff ff       	call   80103231 <myproc>
80105415:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105419:	75 1f                	jne    8010543a <trap+0x51>
    myproc()->tf = tf;
8010541b:	e8 11 de ff ff       	call   80103231 <myproc>
80105420:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80105423:	e8 94 f0 ff ff       	call   801044bc <syscall>
    if(myproc()->killed)
80105428:	e8 04 de ff ff       	call   80103231 <myproc>
8010542d:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105431:	74 7e                	je     801054b1 <trap+0xc8>
      exit();
80105433:	e8 7b e0 ff ff       	call   801034b3 <exit>
80105438:	eb 77                	jmp    801054b1 <trap+0xc8>
      exit();
8010543a:	e8 74 e0 ff ff       	call   801034b3 <exit>
8010543f:	eb da                	jmp    8010541b <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80105441:	e8 d0 dd ff ff       	call   80103216 <cpuid>
80105446:	85 c0                	test   %eax,%eax
80105448:	74 6f                	je     801054b9 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
8010544a:	e8 4a cf ff ff       	call   80102399 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010544f:	e8 dd dd ff ff       	call   80103231 <myproc>
80105454:	85 c0                	test   %eax,%eax
80105456:	74 1c                	je     80105474 <trap+0x8b>
80105458:	e8 d4 dd ff ff       	call   80103231 <myproc>
8010545d:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105461:	74 11                	je     80105474 <trap+0x8b>
80105463:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105467:	83 e0 03             	and    $0x3,%eax
8010546a:	66 83 f8 03          	cmp    $0x3,%ax
8010546e:	0f 84 62 01 00 00    	je     801055d6 <trap+0x1ed>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.

  // TODO: MIGHT NEED TO ADD MORE CONDITIONS TO IF STATEMENT
  if(myproc() && myproc()->state == RUNNING &&
80105474:	e8 b8 dd ff ff       	call   80103231 <myproc>
80105479:	85 c0                	test   %eax,%eax
8010547b:	74 0f                	je     8010548c <trap+0xa3>
8010547d:	e8 af dd ff ff       	call   80103231 <myproc>
80105482:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105486:	0f 84 54 01 00 00    	je     801055e0 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010548c:	e8 a0 dd ff ff       	call   80103231 <myproc>
80105491:	85 c0                	test   %eax,%eax
80105493:	74 1c                	je     801054b1 <trap+0xc8>
80105495:	e8 97 dd ff ff       	call   80103231 <myproc>
8010549a:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010549e:	74 11                	je     801054b1 <trap+0xc8>
801054a0:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801054a4:	83 e0 03             	and    $0x3,%eax
801054a7:	66 83 f8 03          	cmp    $0x3,%ax
801054ab:	0f 84 43 01 00 00    	je     801055f4 <trap+0x20b>
    exit();
}
801054b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801054b4:	5b                   	pop    %ebx
801054b5:	5e                   	pop    %esi
801054b6:	5f                   	pop    %edi
801054b7:	5d                   	pop    %ebp
801054b8:	c3                   	ret    
      acquire(&tickslock);
801054b9:	83 ec 0c             	sub    $0xc,%esp
801054bc:	68 80 63 11 80       	push   $0x80116380
801054c1:	e8 3c ec ff ff       	call   80104102 <acquire>
      ticks++;
801054c6:	83 05 c0 6b 11 80 01 	addl   $0x1,0x80116bc0
      wakeup(&ticks);
801054cd:	c7 04 24 c0 6b 11 80 	movl   $0x80116bc0,(%esp)
801054d4:	e8 3d e2 ff ff       	call   80103716 <wakeup>
      release(&tickslock);
801054d9:	c7 04 24 80 63 11 80 	movl   $0x80116380,(%esp)
801054e0:	e8 82 ec ff ff       	call   80104167 <release>
801054e5:	83 c4 10             	add    $0x10,%esp
801054e8:	e9 5d ff ff ff       	jmp    8010544a <trap+0x61>
    ideintr();
801054ed:	e8 81 c8 ff ff       	call   80101d73 <ideintr>
    lapiceoi();
801054f2:	e8 a2 ce ff ff       	call   80102399 <lapiceoi>
    break;
801054f7:	e9 53 ff ff ff       	jmp    8010544f <trap+0x66>
    kbdintr();
801054fc:	e8 dc cc ff ff       	call   801021dd <kbdintr>
    lapiceoi();
80105501:	e8 93 ce ff ff       	call   80102399 <lapiceoi>
    break;
80105506:	e9 44 ff ff ff       	jmp    8010544f <trap+0x66>
    uartintr();
8010550b:	e8 05 02 00 00       	call   80105715 <uartintr>
    lapiceoi();
80105510:	e8 84 ce ff ff       	call   80102399 <lapiceoi>
    break;
80105515:	e9 35 ff ff ff       	jmp    8010544f <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010551a:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
8010551d:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105521:	e8 f0 dc ff ff       	call   80103216 <cpuid>
80105526:	57                   	push   %edi
80105527:	0f b7 f6             	movzwl %si,%esi
8010552a:	56                   	push   %esi
8010552b:	50                   	push   %eax
8010552c:	68 b4 72 10 80       	push   $0x801072b4
80105531:	e8 d5 b0 ff ff       	call   8010060b <cprintf>
    lapiceoi();
80105536:	e8 5e ce ff ff       	call   80102399 <lapiceoi>
    break;
8010553b:	83 c4 10             	add    $0x10,%esp
8010553e:	e9 0c ff ff ff       	jmp    8010544f <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105543:	e8 e9 dc ff ff       	call   80103231 <myproc>
80105548:	85 c0                	test   %eax,%eax
8010554a:	74 5f                	je     801055ab <trap+0x1c2>
8010554c:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105550:	74 59                	je     801055ab <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105552:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105555:	8b 43 38             	mov    0x38(%ebx),%eax
80105558:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010555b:	e8 b6 dc ff ff       	call   80103216 <cpuid>
80105560:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105563:	8b 53 34             	mov    0x34(%ebx),%edx
80105566:	89 55 dc             	mov    %edx,-0x24(%ebp)
80105569:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
8010556c:	e8 c0 dc ff ff       	call   80103231 <myproc>
80105571:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105574:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105577:	e8 b5 dc ff ff       	call   80103231 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010557c:	57                   	push   %edi
8010557d:	ff 75 e4             	pushl  -0x1c(%ebp)
80105580:	ff 75 e0             	pushl  -0x20(%ebp)
80105583:	ff 75 dc             	pushl  -0x24(%ebp)
80105586:	56                   	push   %esi
80105587:	ff 75 d8             	pushl  -0x28(%ebp)
8010558a:	ff 70 10             	pushl  0x10(%eax)
8010558d:	68 0c 73 10 80       	push   $0x8010730c
80105592:	e8 74 b0 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105597:	83 c4 20             	add    $0x20,%esp
8010559a:	e8 92 dc ff ff       	call   80103231 <myproc>
8010559f:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801055a6:	e9 a4 fe ff ff       	jmp    8010544f <trap+0x66>
801055ab:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801055ae:	8b 73 38             	mov    0x38(%ebx),%esi
801055b1:	e8 60 dc ff ff       	call   80103216 <cpuid>
801055b6:	83 ec 0c             	sub    $0xc,%esp
801055b9:	57                   	push   %edi
801055ba:	56                   	push   %esi
801055bb:	50                   	push   %eax
801055bc:	ff 73 30             	pushl  0x30(%ebx)
801055bf:	68 d8 72 10 80       	push   $0x801072d8
801055c4:	e8 42 b0 ff ff       	call   8010060b <cprintf>
      panic("trap");
801055c9:	83 c4 14             	add    $0x14,%esp
801055cc:	68 ae 72 10 80       	push   $0x801072ae
801055d1:	e8 72 ad ff ff       	call   80100348 <panic>
    exit();
801055d6:	e8 d8 de ff ff       	call   801034b3 <exit>
801055db:	e9 94 fe ff ff       	jmp    80105474 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
801055e0:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801055e4:	0f 85 a2 fe ff ff    	jne    8010548c <trap+0xa3>
    yield();
801055ea:	e8 8d df ff ff       	call   8010357c <yield>
801055ef:	e9 98 fe ff ff       	jmp    8010548c <trap+0xa3>
    exit();
801055f4:	e8 ba de ff ff       	call   801034b3 <exit>
801055f9:	e9 b3 fe ff ff       	jmp    801054b1 <trap+0xc8>

801055fe <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801055fe:	55                   	push   %ebp
801055ff:	89 e5                	mov    %esp,%ebp
  if(!uart)
80105601:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105608:	74 15                	je     8010561f <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010560a:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010560f:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
80105610:	a8 01                	test   $0x1,%al
80105612:	74 12                	je     80105626 <uartgetc+0x28>
80105614:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105619:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
8010561a:	0f b6 c0             	movzbl %al,%eax
}
8010561d:	5d                   	pop    %ebp
8010561e:	c3                   	ret    
    return -1;
8010561f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105624:	eb f7                	jmp    8010561d <uartgetc+0x1f>
    return -1;
80105626:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010562b:	eb f0                	jmp    8010561d <uartgetc+0x1f>

8010562d <uartputc>:
  if(!uart)
8010562d:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105634:	74 3b                	je     80105671 <uartputc+0x44>
{
80105636:	55                   	push   %ebp
80105637:	89 e5                	mov    %esp,%ebp
80105639:	53                   	push   %ebx
8010563a:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010563d:	bb 00 00 00 00       	mov    $0x0,%ebx
80105642:	eb 10                	jmp    80105654 <uartputc+0x27>
    microdelay(10);
80105644:	83 ec 0c             	sub    $0xc,%esp
80105647:	6a 0a                	push   $0xa
80105649:	e8 6a cd ff ff       	call   801023b8 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010564e:	83 c3 01             	add    $0x1,%ebx
80105651:	83 c4 10             	add    $0x10,%esp
80105654:	83 fb 7f             	cmp    $0x7f,%ebx
80105657:	7f 0a                	jg     80105663 <uartputc+0x36>
80105659:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010565e:	ec                   	in     (%dx),%al
8010565f:	a8 20                	test   $0x20,%al
80105661:	74 e1                	je     80105644 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105663:	8b 45 08             	mov    0x8(%ebp),%eax
80105666:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010566b:	ee                   	out    %al,(%dx)
}
8010566c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010566f:	c9                   	leave  
80105670:	c3                   	ret    
80105671:	f3 c3                	repz ret 

80105673 <uartinit>:
{
80105673:	55                   	push   %ebp
80105674:	89 e5                	mov    %esp,%ebp
80105676:	56                   	push   %esi
80105677:	53                   	push   %ebx
80105678:	b9 00 00 00 00       	mov    $0x0,%ecx
8010567d:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105682:	89 c8                	mov    %ecx,%eax
80105684:	ee                   	out    %al,(%dx)
80105685:	be fb 03 00 00       	mov    $0x3fb,%esi
8010568a:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010568f:	89 f2                	mov    %esi,%edx
80105691:	ee                   	out    %al,(%dx)
80105692:	b8 0c 00 00 00       	mov    $0xc,%eax
80105697:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010569c:	ee                   	out    %al,(%dx)
8010569d:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801056a2:	89 c8                	mov    %ecx,%eax
801056a4:	89 da                	mov    %ebx,%edx
801056a6:	ee                   	out    %al,(%dx)
801056a7:	b8 03 00 00 00       	mov    $0x3,%eax
801056ac:	89 f2                	mov    %esi,%edx
801056ae:	ee                   	out    %al,(%dx)
801056af:	ba fc 03 00 00       	mov    $0x3fc,%edx
801056b4:	89 c8                	mov    %ecx,%eax
801056b6:	ee                   	out    %al,(%dx)
801056b7:	b8 01 00 00 00       	mov    $0x1,%eax
801056bc:	89 da                	mov    %ebx,%edx
801056be:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801056bf:	ba fd 03 00 00       	mov    $0x3fd,%edx
801056c4:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801056c5:	3c ff                	cmp    $0xff,%al
801056c7:	74 45                	je     8010570e <uartinit+0x9b>
  uart = 1;
801056c9:	c7 05 bc a5 10 80 01 	movl   $0x1,0x8010a5bc
801056d0:	00 00 00 
801056d3:	ba fa 03 00 00       	mov    $0x3fa,%edx
801056d8:	ec                   	in     (%dx),%al
801056d9:	ba f8 03 00 00       	mov    $0x3f8,%edx
801056de:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801056df:	83 ec 08             	sub    $0x8,%esp
801056e2:	6a 00                	push   $0x0
801056e4:	6a 04                	push   $0x4
801056e6:	e8 93 c8 ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801056eb:	83 c4 10             	add    $0x10,%esp
801056ee:	bb d0 73 10 80       	mov    $0x801073d0,%ebx
801056f3:	eb 12                	jmp    80105707 <uartinit+0x94>
    uartputc(*p);
801056f5:	83 ec 0c             	sub    $0xc,%esp
801056f8:	0f be c0             	movsbl %al,%eax
801056fb:	50                   	push   %eax
801056fc:	e8 2c ff ff ff       	call   8010562d <uartputc>
  for(p="xv6...\n"; *p; p++)
80105701:	83 c3 01             	add    $0x1,%ebx
80105704:	83 c4 10             	add    $0x10,%esp
80105707:	0f b6 03             	movzbl (%ebx),%eax
8010570a:	84 c0                	test   %al,%al
8010570c:	75 e7                	jne    801056f5 <uartinit+0x82>
}
8010570e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80105711:	5b                   	pop    %ebx
80105712:	5e                   	pop    %esi
80105713:	5d                   	pop    %ebp
80105714:	c3                   	ret    

80105715 <uartintr>:

void
uartintr(void)
{
80105715:	55                   	push   %ebp
80105716:	89 e5                	mov    %esp,%ebp
80105718:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
8010571b:	68 fe 55 10 80       	push   $0x801055fe
80105720:	e8 19 b0 ff ff       	call   8010073e <consoleintr>
}
80105725:	83 c4 10             	add    $0x10,%esp
80105728:	c9                   	leave  
80105729:	c3                   	ret    

8010572a <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
8010572a:	6a 00                	push   $0x0
  pushl $0
8010572c:	6a 00                	push   $0x0
  jmp alltraps
8010572e:	e9 be fb ff ff       	jmp    801052f1 <alltraps>

80105733 <vector1>:
.globl vector1
vector1:
  pushl $0
80105733:	6a 00                	push   $0x0
  pushl $1
80105735:	6a 01                	push   $0x1
  jmp alltraps
80105737:	e9 b5 fb ff ff       	jmp    801052f1 <alltraps>

8010573c <vector2>:
.globl vector2
vector2:
  pushl $0
8010573c:	6a 00                	push   $0x0
  pushl $2
8010573e:	6a 02                	push   $0x2
  jmp alltraps
80105740:	e9 ac fb ff ff       	jmp    801052f1 <alltraps>

80105745 <vector3>:
.globl vector3
vector3:
  pushl $0
80105745:	6a 00                	push   $0x0
  pushl $3
80105747:	6a 03                	push   $0x3
  jmp alltraps
80105749:	e9 a3 fb ff ff       	jmp    801052f1 <alltraps>

8010574e <vector4>:
.globl vector4
vector4:
  pushl $0
8010574e:	6a 00                	push   $0x0
  pushl $4
80105750:	6a 04                	push   $0x4
  jmp alltraps
80105752:	e9 9a fb ff ff       	jmp    801052f1 <alltraps>

80105757 <vector5>:
.globl vector5
vector5:
  pushl $0
80105757:	6a 00                	push   $0x0
  pushl $5
80105759:	6a 05                	push   $0x5
  jmp alltraps
8010575b:	e9 91 fb ff ff       	jmp    801052f1 <alltraps>

80105760 <vector6>:
.globl vector6
vector6:
  pushl $0
80105760:	6a 00                	push   $0x0
  pushl $6
80105762:	6a 06                	push   $0x6
  jmp alltraps
80105764:	e9 88 fb ff ff       	jmp    801052f1 <alltraps>

80105769 <vector7>:
.globl vector7
vector7:
  pushl $0
80105769:	6a 00                	push   $0x0
  pushl $7
8010576b:	6a 07                	push   $0x7
  jmp alltraps
8010576d:	e9 7f fb ff ff       	jmp    801052f1 <alltraps>

80105772 <vector8>:
.globl vector8
vector8:
  pushl $8
80105772:	6a 08                	push   $0x8
  jmp alltraps
80105774:	e9 78 fb ff ff       	jmp    801052f1 <alltraps>

80105779 <vector9>:
.globl vector9
vector9:
  pushl $0
80105779:	6a 00                	push   $0x0
  pushl $9
8010577b:	6a 09                	push   $0x9
  jmp alltraps
8010577d:	e9 6f fb ff ff       	jmp    801052f1 <alltraps>

80105782 <vector10>:
.globl vector10
vector10:
  pushl $10
80105782:	6a 0a                	push   $0xa
  jmp alltraps
80105784:	e9 68 fb ff ff       	jmp    801052f1 <alltraps>

80105789 <vector11>:
.globl vector11
vector11:
  pushl $11
80105789:	6a 0b                	push   $0xb
  jmp alltraps
8010578b:	e9 61 fb ff ff       	jmp    801052f1 <alltraps>

80105790 <vector12>:
.globl vector12
vector12:
  pushl $12
80105790:	6a 0c                	push   $0xc
  jmp alltraps
80105792:	e9 5a fb ff ff       	jmp    801052f1 <alltraps>

80105797 <vector13>:
.globl vector13
vector13:
  pushl $13
80105797:	6a 0d                	push   $0xd
  jmp alltraps
80105799:	e9 53 fb ff ff       	jmp    801052f1 <alltraps>

8010579e <vector14>:
.globl vector14
vector14:
  pushl $14
8010579e:	6a 0e                	push   $0xe
  jmp alltraps
801057a0:	e9 4c fb ff ff       	jmp    801052f1 <alltraps>

801057a5 <vector15>:
.globl vector15
vector15:
  pushl $0
801057a5:	6a 00                	push   $0x0
  pushl $15
801057a7:	6a 0f                	push   $0xf
  jmp alltraps
801057a9:	e9 43 fb ff ff       	jmp    801052f1 <alltraps>

801057ae <vector16>:
.globl vector16
vector16:
  pushl $0
801057ae:	6a 00                	push   $0x0
  pushl $16
801057b0:	6a 10                	push   $0x10
  jmp alltraps
801057b2:	e9 3a fb ff ff       	jmp    801052f1 <alltraps>

801057b7 <vector17>:
.globl vector17
vector17:
  pushl $17
801057b7:	6a 11                	push   $0x11
  jmp alltraps
801057b9:	e9 33 fb ff ff       	jmp    801052f1 <alltraps>

801057be <vector18>:
.globl vector18
vector18:
  pushl $0
801057be:	6a 00                	push   $0x0
  pushl $18
801057c0:	6a 12                	push   $0x12
  jmp alltraps
801057c2:	e9 2a fb ff ff       	jmp    801052f1 <alltraps>

801057c7 <vector19>:
.globl vector19
vector19:
  pushl $0
801057c7:	6a 00                	push   $0x0
  pushl $19
801057c9:	6a 13                	push   $0x13
  jmp alltraps
801057cb:	e9 21 fb ff ff       	jmp    801052f1 <alltraps>

801057d0 <vector20>:
.globl vector20
vector20:
  pushl $0
801057d0:	6a 00                	push   $0x0
  pushl $20
801057d2:	6a 14                	push   $0x14
  jmp alltraps
801057d4:	e9 18 fb ff ff       	jmp    801052f1 <alltraps>

801057d9 <vector21>:
.globl vector21
vector21:
  pushl $0
801057d9:	6a 00                	push   $0x0
  pushl $21
801057db:	6a 15                	push   $0x15
  jmp alltraps
801057dd:	e9 0f fb ff ff       	jmp    801052f1 <alltraps>

801057e2 <vector22>:
.globl vector22
vector22:
  pushl $0
801057e2:	6a 00                	push   $0x0
  pushl $22
801057e4:	6a 16                	push   $0x16
  jmp alltraps
801057e6:	e9 06 fb ff ff       	jmp    801052f1 <alltraps>

801057eb <vector23>:
.globl vector23
vector23:
  pushl $0
801057eb:	6a 00                	push   $0x0
  pushl $23
801057ed:	6a 17                	push   $0x17
  jmp alltraps
801057ef:	e9 fd fa ff ff       	jmp    801052f1 <alltraps>

801057f4 <vector24>:
.globl vector24
vector24:
  pushl $0
801057f4:	6a 00                	push   $0x0
  pushl $24
801057f6:	6a 18                	push   $0x18
  jmp alltraps
801057f8:	e9 f4 fa ff ff       	jmp    801052f1 <alltraps>

801057fd <vector25>:
.globl vector25
vector25:
  pushl $0
801057fd:	6a 00                	push   $0x0
  pushl $25
801057ff:	6a 19                	push   $0x19
  jmp alltraps
80105801:	e9 eb fa ff ff       	jmp    801052f1 <alltraps>

80105806 <vector26>:
.globl vector26
vector26:
  pushl $0
80105806:	6a 00                	push   $0x0
  pushl $26
80105808:	6a 1a                	push   $0x1a
  jmp alltraps
8010580a:	e9 e2 fa ff ff       	jmp    801052f1 <alltraps>

8010580f <vector27>:
.globl vector27
vector27:
  pushl $0
8010580f:	6a 00                	push   $0x0
  pushl $27
80105811:	6a 1b                	push   $0x1b
  jmp alltraps
80105813:	e9 d9 fa ff ff       	jmp    801052f1 <alltraps>

80105818 <vector28>:
.globl vector28
vector28:
  pushl $0
80105818:	6a 00                	push   $0x0
  pushl $28
8010581a:	6a 1c                	push   $0x1c
  jmp alltraps
8010581c:	e9 d0 fa ff ff       	jmp    801052f1 <alltraps>

80105821 <vector29>:
.globl vector29
vector29:
  pushl $0
80105821:	6a 00                	push   $0x0
  pushl $29
80105823:	6a 1d                	push   $0x1d
  jmp alltraps
80105825:	e9 c7 fa ff ff       	jmp    801052f1 <alltraps>

8010582a <vector30>:
.globl vector30
vector30:
  pushl $0
8010582a:	6a 00                	push   $0x0
  pushl $30
8010582c:	6a 1e                	push   $0x1e
  jmp alltraps
8010582e:	e9 be fa ff ff       	jmp    801052f1 <alltraps>

80105833 <vector31>:
.globl vector31
vector31:
  pushl $0
80105833:	6a 00                	push   $0x0
  pushl $31
80105835:	6a 1f                	push   $0x1f
  jmp alltraps
80105837:	e9 b5 fa ff ff       	jmp    801052f1 <alltraps>

8010583c <vector32>:
.globl vector32
vector32:
  pushl $0
8010583c:	6a 00                	push   $0x0
  pushl $32
8010583e:	6a 20                	push   $0x20
  jmp alltraps
80105840:	e9 ac fa ff ff       	jmp    801052f1 <alltraps>

80105845 <vector33>:
.globl vector33
vector33:
  pushl $0
80105845:	6a 00                	push   $0x0
  pushl $33
80105847:	6a 21                	push   $0x21
  jmp alltraps
80105849:	e9 a3 fa ff ff       	jmp    801052f1 <alltraps>

8010584e <vector34>:
.globl vector34
vector34:
  pushl $0
8010584e:	6a 00                	push   $0x0
  pushl $34
80105850:	6a 22                	push   $0x22
  jmp alltraps
80105852:	e9 9a fa ff ff       	jmp    801052f1 <alltraps>

80105857 <vector35>:
.globl vector35
vector35:
  pushl $0
80105857:	6a 00                	push   $0x0
  pushl $35
80105859:	6a 23                	push   $0x23
  jmp alltraps
8010585b:	e9 91 fa ff ff       	jmp    801052f1 <alltraps>

80105860 <vector36>:
.globl vector36
vector36:
  pushl $0
80105860:	6a 00                	push   $0x0
  pushl $36
80105862:	6a 24                	push   $0x24
  jmp alltraps
80105864:	e9 88 fa ff ff       	jmp    801052f1 <alltraps>

80105869 <vector37>:
.globl vector37
vector37:
  pushl $0
80105869:	6a 00                	push   $0x0
  pushl $37
8010586b:	6a 25                	push   $0x25
  jmp alltraps
8010586d:	e9 7f fa ff ff       	jmp    801052f1 <alltraps>

80105872 <vector38>:
.globl vector38
vector38:
  pushl $0
80105872:	6a 00                	push   $0x0
  pushl $38
80105874:	6a 26                	push   $0x26
  jmp alltraps
80105876:	e9 76 fa ff ff       	jmp    801052f1 <alltraps>

8010587b <vector39>:
.globl vector39
vector39:
  pushl $0
8010587b:	6a 00                	push   $0x0
  pushl $39
8010587d:	6a 27                	push   $0x27
  jmp alltraps
8010587f:	e9 6d fa ff ff       	jmp    801052f1 <alltraps>

80105884 <vector40>:
.globl vector40
vector40:
  pushl $0
80105884:	6a 00                	push   $0x0
  pushl $40
80105886:	6a 28                	push   $0x28
  jmp alltraps
80105888:	e9 64 fa ff ff       	jmp    801052f1 <alltraps>

8010588d <vector41>:
.globl vector41
vector41:
  pushl $0
8010588d:	6a 00                	push   $0x0
  pushl $41
8010588f:	6a 29                	push   $0x29
  jmp alltraps
80105891:	e9 5b fa ff ff       	jmp    801052f1 <alltraps>

80105896 <vector42>:
.globl vector42
vector42:
  pushl $0
80105896:	6a 00                	push   $0x0
  pushl $42
80105898:	6a 2a                	push   $0x2a
  jmp alltraps
8010589a:	e9 52 fa ff ff       	jmp    801052f1 <alltraps>

8010589f <vector43>:
.globl vector43
vector43:
  pushl $0
8010589f:	6a 00                	push   $0x0
  pushl $43
801058a1:	6a 2b                	push   $0x2b
  jmp alltraps
801058a3:	e9 49 fa ff ff       	jmp    801052f1 <alltraps>

801058a8 <vector44>:
.globl vector44
vector44:
  pushl $0
801058a8:	6a 00                	push   $0x0
  pushl $44
801058aa:	6a 2c                	push   $0x2c
  jmp alltraps
801058ac:	e9 40 fa ff ff       	jmp    801052f1 <alltraps>

801058b1 <vector45>:
.globl vector45
vector45:
  pushl $0
801058b1:	6a 00                	push   $0x0
  pushl $45
801058b3:	6a 2d                	push   $0x2d
  jmp alltraps
801058b5:	e9 37 fa ff ff       	jmp    801052f1 <alltraps>

801058ba <vector46>:
.globl vector46
vector46:
  pushl $0
801058ba:	6a 00                	push   $0x0
  pushl $46
801058bc:	6a 2e                	push   $0x2e
  jmp alltraps
801058be:	e9 2e fa ff ff       	jmp    801052f1 <alltraps>

801058c3 <vector47>:
.globl vector47
vector47:
  pushl $0
801058c3:	6a 00                	push   $0x0
  pushl $47
801058c5:	6a 2f                	push   $0x2f
  jmp alltraps
801058c7:	e9 25 fa ff ff       	jmp    801052f1 <alltraps>

801058cc <vector48>:
.globl vector48
vector48:
  pushl $0
801058cc:	6a 00                	push   $0x0
  pushl $48
801058ce:	6a 30                	push   $0x30
  jmp alltraps
801058d0:	e9 1c fa ff ff       	jmp    801052f1 <alltraps>

801058d5 <vector49>:
.globl vector49
vector49:
  pushl $0
801058d5:	6a 00                	push   $0x0
  pushl $49
801058d7:	6a 31                	push   $0x31
  jmp alltraps
801058d9:	e9 13 fa ff ff       	jmp    801052f1 <alltraps>

801058de <vector50>:
.globl vector50
vector50:
  pushl $0
801058de:	6a 00                	push   $0x0
  pushl $50
801058e0:	6a 32                	push   $0x32
  jmp alltraps
801058e2:	e9 0a fa ff ff       	jmp    801052f1 <alltraps>

801058e7 <vector51>:
.globl vector51
vector51:
  pushl $0
801058e7:	6a 00                	push   $0x0
  pushl $51
801058e9:	6a 33                	push   $0x33
  jmp alltraps
801058eb:	e9 01 fa ff ff       	jmp    801052f1 <alltraps>

801058f0 <vector52>:
.globl vector52
vector52:
  pushl $0
801058f0:	6a 00                	push   $0x0
  pushl $52
801058f2:	6a 34                	push   $0x34
  jmp alltraps
801058f4:	e9 f8 f9 ff ff       	jmp    801052f1 <alltraps>

801058f9 <vector53>:
.globl vector53
vector53:
  pushl $0
801058f9:	6a 00                	push   $0x0
  pushl $53
801058fb:	6a 35                	push   $0x35
  jmp alltraps
801058fd:	e9 ef f9 ff ff       	jmp    801052f1 <alltraps>

80105902 <vector54>:
.globl vector54
vector54:
  pushl $0
80105902:	6a 00                	push   $0x0
  pushl $54
80105904:	6a 36                	push   $0x36
  jmp alltraps
80105906:	e9 e6 f9 ff ff       	jmp    801052f1 <alltraps>

8010590b <vector55>:
.globl vector55
vector55:
  pushl $0
8010590b:	6a 00                	push   $0x0
  pushl $55
8010590d:	6a 37                	push   $0x37
  jmp alltraps
8010590f:	e9 dd f9 ff ff       	jmp    801052f1 <alltraps>

80105914 <vector56>:
.globl vector56
vector56:
  pushl $0
80105914:	6a 00                	push   $0x0
  pushl $56
80105916:	6a 38                	push   $0x38
  jmp alltraps
80105918:	e9 d4 f9 ff ff       	jmp    801052f1 <alltraps>

8010591d <vector57>:
.globl vector57
vector57:
  pushl $0
8010591d:	6a 00                	push   $0x0
  pushl $57
8010591f:	6a 39                	push   $0x39
  jmp alltraps
80105921:	e9 cb f9 ff ff       	jmp    801052f1 <alltraps>

80105926 <vector58>:
.globl vector58
vector58:
  pushl $0
80105926:	6a 00                	push   $0x0
  pushl $58
80105928:	6a 3a                	push   $0x3a
  jmp alltraps
8010592a:	e9 c2 f9 ff ff       	jmp    801052f1 <alltraps>

8010592f <vector59>:
.globl vector59
vector59:
  pushl $0
8010592f:	6a 00                	push   $0x0
  pushl $59
80105931:	6a 3b                	push   $0x3b
  jmp alltraps
80105933:	e9 b9 f9 ff ff       	jmp    801052f1 <alltraps>

80105938 <vector60>:
.globl vector60
vector60:
  pushl $0
80105938:	6a 00                	push   $0x0
  pushl $60
8010593a:	6a 3c                	push   $0x3c
  jmp alltraps
8010593c:	e9 b0 f9 ff ff       	jmp    801052f1 <alltraps>

80105941 <vector61>:
.globl vector61
vector61:
  pushl $0
80105941:	6a 00                	push   $0x0
  pushl $61
80105943:	6a 3d                	push   $0x3d
  jmp alltraps
80105945:	e9 a7 f9 ff ff       	jmp    801052f1 <alltraps>

8010594a <vector62>:
.globl vector62
vector62:
  pushl $0
8010594a:	6a 00                	push   $0x0
  pushl $62
8010594c:	6a 3e                	push   $0x3e
  jmp alltraps
8010594e:	e9 9e f9 ff ff       	jmp    801052f1 <alltraps>

80105953 <vector63>:
.globl vector63
vector63:
  pushl $0
80105953:	6a 00                	push   $0x0
  pushl $63
80105955:	6a 3f                	push   $0x3f
  jmp alltraps
80105957:	e9 95 f9 ff ff       	jmp    801052f1 <alltraps>

8010595c <vector64>:
.globl vector64
vector64:
  pushl $0
8010595c:	6a 00                	push   $0x0
  pushl $64
8010595e:	6a 40                	push   $0x40
  jmp alltraps
80105960:	e9 8c f9 ff ff       	jmp    801052f1 <alltraps>

80105965 <vector65>:
.globl vector65
vector65:
  pushl $0
80105965:	6a 00                	push   $0x0
  pushl $65
80105967:	6a 41                	push   $0x41
  jmp alltraps
80105969:	e9 83 f9 ff ff       	jmp    801052f1 <alltraps>

8010596e <vector66>:
.globl vector66
vector66:
  pushl $0
8010596e:	6a 00                	push   $0x0
  pushl $66
80105970:	6a 42                	push   $0x42
  jmp alltraps
80105972:	e9 7a f9 ff ff       	jmp    801052f1 <alltraps>

80105977 <vector67>:
.globl vector67
vector67:
  pushl $0
80105977:	6a 00                	push   $0x0
  pushl $67
80105979:	6a 43                	push   $0x43
  jmp alltraps
8010597b:	e9 71 f9 ff ff       	jmp    801052f1 <alltraps>

80105980 <vector68>:
.globl vector68
vector68:
  pushl $0
80105980:	6a 00                	push   $0x0
  pushl $68
80105982:	6a 44                	push   $0x44
  jmp alltraps
80105984:	e9 68 f9 ff ff       	jmp    801052f1 <alltraps>

80105989 <vector69>:
.globl vector69
vector69:
  pushl $0
80105989:	6a 00                	push   $0x0
  pushl $69
8010598b:	6a 45                	push   $0x45
  jmp alltraps
8010598d:	e9 5f f9 ff ff       	jmp    801052f1 <alltraps>

80105992 <vector70>:
.globl vector70
vector70:
  pushl $0
80105992:	6a 00                	push   $0x0
  pushl $70
80105994:	6a 46                	push   $0x46
  jmp alltraps
80105996:	e9 56 f9 ff ff       	jmp    801052f1 <alltraps>

8010599b <vector71>:
.globl vector71
vector71:
  pushl $0
8010599b:	6a 00                	push   $0x0
  pushl $71
8010599d:	6a 47                	push   $0x47
  jmp alltraps
8010599f:	e9 4d f9 ff ff       	jmp    801052f1 <alltraps>

801059a4 <vector72>:
.globl vector72
vector72:
  pushl $0
801059a4:	6a 00                	push   $0x0
  pushl $72
801059a6:	6a 48                	push   $0x48
  jmp alltraps
801059a8:	e9 44 f9 ff ff       	jmp    801052f1 <alltraps>

801059ad <vector73>:
.globl vector73
vector73:
  pushl $0
801059ad:	6a 00                	push   $0x0
  pushl $73
801059af:	6a 49                	push   $0x49
  jmp alltraps
801059b1:	e9 3b f9 ff ff       	jmp    801052f1 <alltraps>

801059b6 <vector74>:
.globl vector74
vector74:
  pushl $0
801059b6:	6a 00                	push   $0x0
  pushl $74
801059b8:	6a 4a                	push   $0x4a
  jmp alltraps
801059ba:	e9 32 f9 ff ff       	jmp    801052f1 <alltraps>

801059bf <vector75>:
.globl vector75
vector75:
  pushl $0
801059bf:	6a 00                	push   $0x0
  pushl $75
801059c1:	6a 4b                	push   $0x4b
  jmp alltraps
801059c3:	e9 29 f9 ff ff       	jmp    801052f1 <alltraps>

801059c8 <vector76>:
.globl vector76
vector76:
  pushl $0
801059c8:	6a 00                	push   $0x0
  pushl $76
801059ca:	6a 4c                	push   $0x4c
  jmp alltraps
801059cc:	e9 20 f9 ff ff       	jmp    801052f1 <alltraps>

801059d1 <vector77>:
.globl vector77
vector77:
  pushl $0
801059d1:	6a 00                	push   $0x0
  pushl $77
801059d3:	6a 4d                	push   $0x4d
  jmp alltraps
801059d5:	e9 17 f9 ff ff       	jmp    801052f1 <alltraps>

801059da <vector78>:
.globl vector78
vector78:
  pushl $0
801059da:	6a 00                	push   $0x0
  pushl $78
801059dc:	6a 4e                	push   $0x4e
  jmp alltraps
801059de:	e9 0e f9 ff ff       	jmp    801052f1 <alltraps>

801059e3 <vector79>:
.globl vector79
vector79:
  pushl $0
801059e3:	6a 00                	push   $0x0
  pushl $79
801059e5:	6a 4f                	push   $0x4f
  jmp alltraps
801059e7:	e9 05 f9 ff ff       	jmp    801052f1 <alltraps>

801059ec <vector80>:
.globl vector80
vector80:
  pushl $0
801059ec:	6a 00                	push   $0x0
  pushl $80
801059ee:	6a 50                	push   $0x50
  jmp alltraps
801059f0:	e9 fc f8 ff ff       	jmp    801052f1 <alltraps>

801059f5 <vector81>:
.globl vector81
vector81:
  pushl $0
801059f5:	6a 00                	push   $0x0
  pushl $81
801059f7:	6a 51                	push   $0x51
  jmp alltraps
801059f9:	e9 f3 f8 ff ff       	jmp    801052f1 <alltraps>

801059fe <vector82>:
.globl vector82
vector82:
  pushl $0
801059fe:	6a 00                	push   $0x0
  pushl $82
80105a00:	6a 52                	push   $0x52
  jmp alltraps
80105a02:	e9 ea f8 ff ff       	jmp    801052f1 <alltraps>

80105a07 <vector83>:
.globl vector83
vector83:
  pushl $0
80105a07:	6a 00                	push   $0x0
  pushl $83
80105a09:	6a 53                	push   $0x53
  jmp alltraps
80105a0b:	e9 e1 f8 ff ff       	jmp    801052f1 <alltraps>

80105a10 <vector84>:
.globl vector84
vector84:
  pushl $0
80105a10:	6a 00                	push   $0x0
  pushl $84
80105a12:	6a 54                	push   $0x54
  jmp alltraps
80105a14:	e9 d8 f8 ff ff       	jmp    801052f1 <alltraps>

80105a19 <vector85>:
.globl vector85
vector85:
  pushl $0
80105a19:	6a 00                	push   $0x0
  pushl $85
80105a1b:	6a 55                	push   $0x55
  jmp alltraps
80105a1d:	e9 cf f8 ff ff       	jmp    801052f1 <alltraps>

80105a22 <vector86>:
.globl vector86
vector86:
  pushl $0
80105a22:	6a 00                	push   $0x0
  pushl $86
80105a24:	6a 56                	push   $0x56
  jmp alltraps
80105a26:	e9 c6 f8 ff ff       	jmp    801052f1 <alltraps>

80105a2b <vector87>:
.globl vector87
vector87:
  pushl $0
80105a2b:	6a 00                	push   $0x0
  pushl $87
80105a2d:	6a 57                	push   $0x57
  jmp alltraps
80105a2f:	e9 bd f8 ff ff       	jmp    801052f1 <alltraps>

80105a34 <vector88>:
.globl vector88
vector88:
  pushl $0
80105a34:	6a 00                	push   $0x0
  pushl $88
80105a36:	6a 58                	push   $0x58
  jmp alltraps
80105a38:	e9 b4 f8 ff ff       	jmp    801052f1 <alltraps>

80105a3d <vector89>:
.globl vector89
vector89:
  pushl $0
80105a3d:	6a 00                	push   $0x0
  pushl $89
80105a3f:	6a 59                	push   $0x59
  jmp alltraps
80105a41:	e9 ab f8 ff ff       	jmp    801052f1 <alltraps>

80105a46 <vector90>:
.globl vector90
vector90:
  pushl $0
80105a46:	6a 00                	push   $0x0
  pushl $90
80105a48:	6a 5a                	push   $0x5a
  jmp alltraps
80105a4a:	e9 a2 f8 ff ff       	jmp    801052f1 <alltraps>

80105a4f <vector91>:
.globl vector91
vector91:
  pushl $0
80105a4f:	6a 00                	push   $0x0
  pushl $91
80105a51:	6a 5b                	push   $0x5b
  jmp alltraps
80105a53:	e9 99 f8 ff ff       	jmp    801052f1 <alltraps>

80105a58 <vector92>:
.globl vector92
vector92:
  pushl $0
80105a58:	6a 00                	push   $0x0
  pushl $92
80105a5a:	6a 5c                	push   $0x5c
  jmp alltraps
80105a5c:	e9 90 f8 ff ff       	jmp    801052f1 <alltraps>

80105a61 <vector93>:
.globl vector93
vector93:
  pushl $0
80105a61:	6a 00                	push   $0x0
  pushl $93
80105a63:	6a 5d                	push   $0x5d
  jmp alltraps
80105a65:	e9 87 f8 ff ff       	jmp    801052f1 <alltraps>

80105a6a <vector94>:
.globl vector94
vector94:
  pushl $0
80105a6a:	6a 00                	push   $0x0
  pushl $94
80105a6c:	6a 5e                	push   $0x5e
  jmp alltraps
80105a6e:	e9 7e f8 ff ff       	jmp    801052f1 <alltraps>

80105a73 <vector95>:
.globl vector95
vector95:
  pushl $0
80105a73:	6a 00                	push   $0x0
  pushl $95
80105a75:	6a 5f                	push   $0x5f
  jmp alltraps
80105a77:	e9 75 f8 ff ff       	jmp    801052f1 <alltraps>

80105a7c <vector96>:
.globl vector96
vector96:
  pushl $0
80105a7c:	6a 00                	push   $0x0
  pushl $96
80105a7e:	6a 60                	push   $0x60
  jmp alltraps
80105a80:	e9 6c f8 ff ff       	jmp    801052f1 <alltraps>

80105a85 <vector97>:
.globl vector97
vector97:
  pushl $0
80105a85:	6a 00                	push   $0x0
  pushl $97
80105a87:	6a 61                	push   $0x61
  jmp alltraps
80105a89:	e9 63 f8 ff ff       	jmp    801052f1 <alltraps>

80105a8e <vector98>:
.globl vector98
vector98:
  pushl $0
80105a8e:	6a 00                	push   $0x0
  pushl $98
80105a90:	6a 62                	push   $0x62
  jmp alltraps
80105a92:	e9 5a f8 ff ff       	jmp    801052f1 <alltraps>

80105a97 <vector99>:
.globl vector99
vector99:
  pushl $0
80105a97:	6a 00                	push   $0x0
  pushl $99
80105a99:	6a 63                	push   $0x63
  jmp alltraps
80105a9b:	e9 51 f8 ff ff       	jmp    801052f1 <alltraps>

80105aa0 <vector100>:
.globl vector100
vector100:
  pushl $0
80105aa0:	6a 00                	push   $0x0
  pushl $100
80105aa2:	6a 64                	push   $0x64
  jmp alltraps
80105aa4:	e9 48 f8 ff ff       	jmp    801052f1 <alltraps>

80105aa9 <vector101>:
.globl vector101
vector101:
  pushl $0
80105aa9:	6a 00                	push   $0x0
  pushl $101
80105aab:	6a 65                	push   $0x65
  jmp alltraps
80105aad:	e9 3f f8 ff ff       	jmp    801052f1 <alltraps>

80105ab2 <vector102>:
.globl vector102
vector102:
  pushl $0
80105ab2:	6a 00                	push   $0x0
  pushl $102
80105ab4:	6a 66                	push   $0x66
  jmp alltraps
80105ab6:	e9 36 f8 ff ff       	jmp    801052f1 <alltraps>

80105abb <vector103>:
.globl vector103
vector103:
  pushl $0
80105abb:	6a 00                	push   $0x0
  pushl $103
80105abd:	6a 67                	push   $0x67
  jmp alltraps
80105abf:	e9 2d f8 ff ff       	jmp    801052f1 <alltraps>

80105ac4 <vector104>:
.globl vector104
vector104:
  pushl $0
80105ac4:	6a 00                	push   $0x0
  pushl $104
80105ac6:	6a 68                	push   $0x68
  jmp alltraps
80105ac8:	e9 24 f8 ff ff       	jmp    801052f1 <alltraps>

80105acd <vector105>:
.globl vector105
vector105:
  pushl $0
80105acd:	6a 00                	push   $0x0
  pushl $105
80105acf:	6a 69                	push   $0x69
  jmp alltraps
80105ad1:	e9 1b f8 ff ff       	jmp    801052f1 <alltraps>

80105ad6 <vector106>:
.globl vector106
vector106:
  pushl $0
80105ad6:	6a 00                	push   $0x0
  pushl $106
80105ad8:	6a 6a                	push   $0x6a
  jmp alltraps
80105ada:	e9 12 f8 ff ff       	jmp    801052f1 <alltraps>

80105adf <vector107>:
.globl vector107
vector107:
  pushl $0
80105adf:	6a 00                	push   $0x0
  pushl $107
80105ae1:	6a 6b                	push   $0x6b
  jmp alltraps
80105ae3:	e9 09 f8 ff ff       	jmp    801052f1 <alltraps>

80105ae8 <vector108>:
.globl vector108
vector108:
  pushl $0
80105ae8:	6a 00                	push   $0x0
  pushl $108
80105aea:	6a 6c                	push   $0x6c
  jmp alltraps
80105aec:	e9 00 f8 ff ff       	jmp    801052f1 <alltraps>

80105af1 <vector109>:
.globl vector109
vector109:
  pushl $0
80105af1:	6a 00                	push   $0x0
  pushl $109
80105af3:	6a 6d                	push   $0x6d
  jmp alltraps
80105af5:	e9 f7 f7 ff ff       	jmp    801052f1 <alltraps>

80105afa <vector110>:
.globl vector110
vector110:
  pushl $0
80105afa:	6a 00                	push   $0x0
  pushl $110
80105afc:	6a 6e                	push   $0x6e
  jmp alltraps
80105afe:	e9 ee f7 ff ff       	jmp    801052f1 <alltraps>

80105b03 <vector111>:
.globl vector111
vector111:
  pushl $0
80105b03:	6a 00                	push   $0x0
  pushl $111
80105b05:	6a 6f                	push   $0x6f
  jmp alltraps
80105b07:	e9 e5 f7 ff ff       	jmp    801052f1 <alltraps>

80105b0c <vector112>:
.globl vector112
vector112:
  pushl $0
80105b0c:	6a 00                	push   $0x0
  pushl $112
80105b0e:	6a 70                	push   $0x70
  jmp alltraps
80105b10:	e9 dc f7 ff ff       	jmp    801052f1 <alltraps>

80105b15 <vector113>:
.globl vector113
vector113:
  pushl $0
80105b15:	6a 00                	push   $0x0
  pushl $113
80105b17:	6a 71                	push   $0x71
  jmp alltraps
80105b19:	e9 d3 f7 ff ff       	jmp    801052f1 <alltraps>

80105b1e <vector114>:
.globl vector114
vector114:
  pushl $0
80105b1e:	6a 00                	push   $0x0
  pushl $114
80105b20:	6a 72                	push   $0x72
  jmp alltraps
80105b22:	e9 ca f7 ff ff       	jmp    801052f1 <alltraps>

80105b27 <vector115>:
.globl vector115
vector115:
  pushl $0
80105b27:	6a 00                	push   $0x0
  pushl $115
80105b29:	6a 73                	push   $0x73
  jmp alltraps
80105b2b:	e9 c1 f7 ff ff       	jmp    801052f1 <alltraps>

80105b30 <vector116>:
.globl vector116
vector116:
  pushl $0
80105b30:	6a 00                	push   $0x0
  pushl $116
80105b32:	6a 74                	push   $0x74
  jmp alltraps
80105b34:	e9 b8 f7 ff ff       	jmp    801052f1 <alltraps>

80105b39 <vector117>:
.globl vector117
vector117:
  pushl $0
80105b39:	6a 00                	push   $0x0
  pushl $117
80105b3b:	6a 75                	push   $0x75
  jmp alltraps
80105b3d:	e9 af f7 ff ff       	jmp    801052f1 <alltraps>

80105b42 <vector118>:
.globl vector118
vector118:
  pushl $0
80105b42:	6a 00                	push   $0x0
  pushl $118
80105b44:	6a 76                	push   $0x76
  jmp alltraps
80105b46:	e9 a6 f7 ff ff       	jmp    801052f1 <alltraps>

80105b4b <vector119>:
.globl vector119
vector119:
  pushl $0
80105b4b:	6a 00                	push   $0x0
  pushl $119
80105b4d:	6a 77                	push   $0x77
  jmp alltraps
80105b4f:	e9 9d f7 ff ff       	jmp    801052f1 <alltraps>

80105b54 <vector120>:
.globl vector120
vector120:
  pushl $0
80105b54:	6a 00                	push   $0x0
  pushl $120
80105b56:	6a 78                	push   $0x78
  jmp alltraps
80105b58:	e9 94 f7 ff ff       	jmp    801052f1 <alltraps>

80105b5d <vector121>:
.globl vector121
vector121:
  pushl $0
80105b5d:	6a 00                	push   $0x0
  pushl $121
80105b5f:	6a 79                	push   $0x79
  jmp alltraps
80105b61:	e9 8b f7 ff ff       	jmp    801052f1 <alltraps>

80105b66 <vector122>:
.globl vector122
vector122:
  pushl $0
80105b66:	6a 00                	push   $0x0
  pushl $122
80105b68:	6a 7a                	push   $0x7a
  jmp alltraps
80105b6a:	e9 82 f7 ff ff       	jmp    801052f1 <alltraps>

80105b6f <vector123>:
.globl vector123
vector123:
  pushl $0
80105b6f:	6a 00                	push   $0x0
  pushl $123
80105b71:	6a 7b                	push   $0x7b
  jmp alltraps
80105b73:	e9 79 f7 ff ff       	jmp    801052f1 <alltraps>

80105b78 <vector124>:
.globl vector124
vector124:
  pushl $0
80105b78:	6a 00                	push   $0x0
  pushl $124
80105b7a:	6a 7c                	push   $0x7c
  jmp alltraps
80105b7c:	e9 70 f7 ff ff       	jmp    801052f1 <alltraps>

80105b81 <vector125>:
.globl vector125
vector125:
  pushl $0
80105b81:	6a 00                	push   $0x0
  pushl $125
80105b83:	6a 7d                	push   $0x7d
  jmp alltraps
80105b85:	e9 67 f7 ff ff       	jmp    801052f1 <alltraps>

80105b8a <vector126>:
.globl vector126
vector126:
  pushl $0
80105b8a:	6a 00                	push   $0x0
  pushl $126
80105b8c:	6a 7e                	push   $0x7e
  jmp alltraps
80105b8e:	e9 5e f7 ff ff       	jmp    801052f1 <alltraps>

80105b93 <vector127>:
.globl vector127
vector127:
  pushl $0
80105b93:	6a 00                	push   $0x0
  pushl $127
80105b95:	6a 7f                	push   $0x7f
  jmp alltraps
80105b97:	e9 55 f7 ff ff       	jmp    801052f1 <alltraps>

80105b9c <vector128>:
.globl vector128
vector128:
  pushl $0
80105b9c:	6a 00                	push   $0x0
  pushl $128
80105b9e:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105ba3:	e9 49 f7 ff ff       	jmp    801052f1 <alltraps>

80105ba8 <vector129>:
.globl vector129
vector129:
  pushl $0
80105ba8:	6a 00                	push   $0x0
  pushl $129
80105baa:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80105baf:	e9 3d f7 ff ff       	jmp    801052f1 <alltraps>

80105bb4 <vector130>:
.globl vector130
vector130:
  pushl $0
80105bb4:	6a 00                	push   $0x0
  pushl $130
80105bb6:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105bbb:	e9 31 f7 ff ff       	jmp    801052f1 <alltraps>

80105bc0 <vector131>:
.globl vector131
vector131:
  pushl $0
80105bc0:	6a 00                	push   $0x0
  pushl $131
80105bc2:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105bc7:	e9 25 f7 ff ff       	jmp    801052f1 <alltraps>

80105bcc <vector132>:
.globl vector132
vector132:
  pushl $0
80105bcc:	6a 00                	push   $0x0
  pushl $132
80105bce:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105bd3:	e9 19 f7 ff ff       	jmp    801052f1 <alltraps>

80105bd8 <vector133>:
.globl vector133
vector133:
  pushl $0
80105bd8:	6a 00                	push   $0x0
  pushl $133
80105bda:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105bdf:	e9 0d f7 ff ff       	jmp    801052f1 <alltraps>

80105be4 <vector134>:
.globl vector134
vector134:
  pushl $0
80105be4:	6a 00                	push   $0x0
  pushl $134
80105be6:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105beb:	e9 01 f7 ff ff       	jmp    801052f1 <alltraps>

80105bf0 <vector135>:
.globl vector135
vector135:
  pushl $0
80105bf0:	6a 00                	push   $0x0
  pushl $135
80105bf2:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105bf7:	e9 f5 f6 ff ff       	jmp    801052f1 <alltraps>

80105bfc <vector136>:
.globl vector136
vector136:
  pushl $0
80105bfc:	6a 00                	push   $0x0
  pushl $136
80105bfe:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105c03:	e9 e9 f6 ff ff       	jmp    801052f1 <alltraps>

80105c08 <vector137>:
.globl vector137
vector137:
  pushl $0
80105c08:	6a 00                	push   $0x0
  pushl $137
80105c0a:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105c0f:	e9 dd f6 ff ff       	jmp    801052f1 <alltraps>

80105c14 <vector138>:
.globl vector138
vector138:
  pushl $0
80105c14:	6a 00                	push   $0x0
  pushl $138
80105c16:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105c1b:	e9 d1 f6 ff ff       	jmp    801052f1 <alltraps>

80105c20 <vector139>:
.globl vector139
vector139:
  pushl $0
80105c20:	6a 00                	push   $0x0
  pushl $139
80105c22:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105c27:	e9 c5 f6 ff ff       	jmp    801052f1 <alltraps>

80105c2c <vector140>:
.globl vector140
vector140:
  pushl $0
80105c2c:	6a 00                	push   $0x0
  pushl $140
80105c2e:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105c33:	e9 b9 f6 ff ff       	jmp    801052f1 <alltraps>

80105c38 <vector141>:
.globl vector141
vector141:
  pushl $0
80105c38:	6a 00                	push   $0x0
  pushl $141
80105c3a:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105c3f:	e9 ad f6 ff ff       	jmp    801052f1 <alltraps>

80105c44 <vector142>:
.globl vector142
vector142:
  pushl $0
80105c44:	6a 00                	push   $0x0
  pushl $142
80105c46:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105c4b:	e9 a1 f6 ff ff       	jmp    801052f1 <alltraps>

80105c50 <vector143>:
.globl vector143
vector143:
  pushl $0
80105c50:	6a 00                	push   $0x0
  pushl $143
80105c52:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105c57:	e9 95 f6 ff ff       	jmp    801052f1 <alltraps>

80105c5c <vector144>:
.globl vector144
vector144:
  pushl $0
80105c5c:	6a 00                	push   $0x0
  pushl $144
80105c5e:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105c63:	e9 89 f6 ff ff       	jmp    801052f1 <alltraps>

80105c68 <vector145>:
.globl vector145
vector145:
  pushl $0
80105c68:	6a 00                	push   $0x0
  pushl $145
80105c6a:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105c6f:	e9 7d f6 ff ff       	jmp    801052f1 <alltraps>

80105c74 <vector146>:
.globl vector146
vector146:
  pushl $0
80105c74:	6a 00                	push   $0x0
  pushl $146
80105c76:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105c7b:	e9 71 f6 ff ff       	jmp    801052f1 <alltraps>

80105c80 <vector147>:
.globl vector147
vector147:
  pushl $0
80105c80:	6a 00                	push   $0x0
  pushl $147
80105c82:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105c87:	e9 65 f6 ff ff       	jmp    801052f1 <alltraps>

80105c8c <vector148>:
.globl vector148
vector148:
  pushl $0
80105c8c:	6a 00                	push   $0x0
  pushl $148
80105c8e:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105c93:	e9 59 f6 ff ff       	jmp    801052f1 <alltraps>

80105c98 <vector149>:
.globl vector149
vector149:
  pushl $0
80105c98:	6a 00                	push   $0x0
  pushl $149
80105c9a:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105c9f:	e9 4d f6 ff ff       	jmp    801052f1 <alltraps>

80105ca4 <vector150>:
.globl vector150
vector150:
  pushl $0
80105ca4:	6a 00                	push   $0x0
  pushl $150
80105ca6:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105cab:	e9 41 f6 ff ff       	jmp    801052f1 <alltraps>

80105cb0 <vector151>:
.globl vector151
vector151:
  pushl $0
80105cb0:	6a 00                	push   $0x0
  pushl $151
80105cb2:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105cb7:	e9 35 f6 ff ff       	jmp    801052f1 <alltraps>

80105cbc <vector152>:
.globl vector152
vector152:
  pushl $0
80105cbc:	6a 00                	push   $0x0
  pushl $152
80105cbe:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105cc3:	e9 29 f6 ff ff       	jmp    801052f1 <alltraps>

80105cc8 <vector153>:
.globl vector153
vector153:
  pushl $0
80105cc8:	6a 00                	push   $0x0
  pushl $153
80105cca:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105ccf:	e9 1d f6 ff ff       	jmp    801052f1 <alltraps>

80105cd4 <vector154>:
.globl vector154
vector154:
  pushl $0
80105cd4:	6a 00                	push   $0x0
  pushl $154
80105cd6:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105cdb:	e9 11 f6 ff ff       	jmp    801052f1 <alltraps>

80105ce0 <vector155>:
.globl vector155
vector155:
  pushl $0
80105ce0:	6a 00                	push   $0x0
  pushl $155
80105ce2:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105ce7:	e9 05 f6 ff ff       	jmp    801052f1 <alltraps>

80105cec <vector156>:
.globl vector156
vector156:
  pushl $0
80105cec:	6a 00                	push   $0x0
  pushl $156
80105cee:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105cf3:	e9 f9 f5 ff ff       	jmp    801052f1 <alltraps>

80105cf8 <vector157>:
.globl vector157
vector157:
  pushl $0
80105cf8:	6a 00                	push   $0x0
  pushl $157
80105cfa:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105cff:	e9 ed f5 ff ff       	jmp    801052f1 <alltraps>

80105d04 <vector158>:
.globl vector158
vector158:
  pushl $0
80105d04:	6a 00                	push   $0x0
  pushl $158
80105d06:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105d0b:	e9 e1 f5 ff ff       	jmp    801052f1 <alltraps>

80105d10 <vector159>:
.globl vector159
vector159:
  pushl $0
80105d10:	6a 00                	push   $0x0
  pushl $159
80105d12:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105d17:	e9 d5 f5 ff ff       	jmp    801052f1 <alltraps>

80105d1c <vector160>:
.globl vector160
vector160:
  pushl $0
80105d1c:	6a 00                	push   $0x0
  pushl $160
80105d1e:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105d23:	e9 c9 f5 ff ff       	jmp    801052f1 <alltraps>

80105d28 <vector161>:
.globl vector161
vector161:
  pushl $0
80105d28:	6a 00                	push   $0x0
  pushl $161
80105d2a:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105d2f:	e9 bd f5 ff ff       	jmp    801052f1 <alltraps>

80105d34 <vector162>:
.globl vector162
vector162:
  pushl $0
80105d34:	6a 00                	push   $0x0
  pushl $162
80105d36:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105d3b:	e9 b1 f5 ff ff       	jmp    801052f1 <alltraps>

80105d40 <vector163>:
.globl vector163
vector163:
  pushl $0
80105d40:	6a 00                	push   $0x0
  pushl $163
80105d42:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105d47:	e9 a5 f5 ff ff       	jmp    801052f1 <alltraps>

80105d4c <vector164>:
.globl vector164
vector164:
  pushl $0
80105d4c:	6a 00                	push   $0x0
  pushl $164
80105d4e:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105d53:	e9 99 f5 ff ff       	jmp    801052f1 <alltraps>

80105d58 <vector165>:
.globl vector165
vector165:
  pushl $0
80105d58:	6a 00                	push   $0x0
  pushl $165
80105d5a:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105d5f:	e9 8d f5 ff ff       	jmp    801052f1 <alltraps>

80105d64 <vector166>:
.globl vector166
vector166:
  pushl $0
80105d64:	6a 00                	push   $0x0
  pushl $166
80105d66:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105d6b:	e9 81 f5 ff ff       	jmp    801052f1 <alltraps>

80105d70 <vector167>:
.globl vector167
vector167:
  pushl $0
80105d70:	6a 00                	push   $0x0
  pushl $167
80105d72:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105d77:	e9 75 f5 ff ff       	jmp    801052f1 <alltraps>

80105d7c <vector168>:
.globl vector168
vector168:
  pushl $0
80105d7c:	6a 00                	push   $0x0
  pushl $168
80105d7e:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105d83:	e9 69 f5 ff ff       	jmp    801052f1 <alltraps>

80105d88 <vector169>:
.globl vector169
vector169:
  pushl $0
80105d88:	6a 00                	push   $0x0
  pushl $169
80105d8a:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105d8f:	e9 5d f5 ff ff       	jmp    801052f1 <alltraps>

80105d94 <vector170>:
.globl vector170
vector170:
  pushl $0
80105d94:	6a 00                	push   $0x0
  pushl $170
80105d96:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105d9b:	e9 51 f5 ff ff       	jmp    801052f1 <alltraps>

80105da0 <vector171>:
.globl vector171
vector171:
  pushl $0
80105da0:	6a 00                	push   $0x0
  pushl $171
80105da2:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105da7:	e9 45 f5 ff ff       	jmp    801052f1 <alltraps>

80105dac <vector172>:
.globl vector172
vector172:
  pushl $0
80105dac:	6a 00                	push   $0x0
  pushl $172
80105dae:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105db3:	e9 39 f5 ff ff       	jmp    801052f1 <alltraps>

80105db8 <vector173>:
.globl vector173
vector173:
  pushl $0
80105db8:	6a 00                	push   $0x0
  pushl $173
80105dba:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105dbf:	e9 2d f5 ff ff       	jmp    801052f1 <alltraps>

80105dc4 <vector174>:
.globl vector174
vector174:
  pushl $0
80105dc4:	6a 00                	push   $0x0
  pushl $174
80105dc6:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105dcb:	e9 21 f5 ff ff       	jmp    801052f1 <alltraps>

80105dd0 <vector175>:
.globl vector175
vector175:
  pushl $0
80105dd0:	6a 00                	push   $0x0
  pushl $175
80105dd2:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105dd7:	e9 15 f5 ff ff       	jmp    801052f1 <alltraps>

80105ddc <vector176>:
.globl vector176
vector176:
  pushl $0
80105ddc:	6a 00                	push   $0x0
  pushl $176
80105dde:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105de3:	e9 09 f5 ff ff       	jmp    801052f1 <alltraps>

80105de8 <vector177>:
.globl vector177
vector177:
  pushl $0
80105de8:	6a 00                	push   $0x0
  pushl $177
80105dea:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105def:	e9 fd f4 ff ff       	jmp    801052f1 <alltraps>

80105df4 <vector178>:
.globl vector178
vector178:
  pushl $0
80105df4:	6a 00                	push   $0x0
  pushl $178
80105df6:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105dfb:	e9 f1 f4 ff ff       	jmp    801052f1 <alltraps>

80105e00 <vector179>:
.globl vector179
vector179:
  pushl $0
80105e00:	6a 00                	push   $0x0
  pushl $179
80105e02:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105e07:	e9 e5 f4 ff ff       	jmp    801052f1 <alltraps>

80105e0c <vector180>:
.globl vector180
vector180:
  pushl $0
80105e0c:	6a 00                	push   $0x0
  pushl $180
80105e0e:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105e13:	e9 d9 f4 ff ff       	jmp    801052f1 <alltraps>

80105e18 <vector181>:
.globl vector181
vector181:
  pushl $0
80105e18:	6a 00                	push   $0x0
  pushl $181
80105e1a:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105e1f:	e9 cd f4 ff ff       	jmp    801052f1 <alltraps>

80105e24 <vector182>:
.globl vector182
vector182:
  pushl $0
80105e24:	6a 00                	push   $0x0
  pushl $182
80105e26:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105e2b:	e9 c1 f4 ff ff       	jmp    801052f1 <alltraps>

80105e30 <vector183>:
.globl vector183
vector183:
  pushl $0
80105e30:	6a 00                	push   $0x0
  pushl $183
80105e32:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105e37:	e9 b5 f4 ff ff       	jmp    801052f1 <alltraps>

80105e3c <vector184>:
.globl vector184
vector184:
  pushl $0
80105e3c:	6a 00                	push   $0x0
  pushl $184
80105e3e:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105e43:	e9 a9 f4 ff ff       	jmp    801052f1 <alltraps>

80105e48 <vector185>:
.globl vector185
vector185:
  pushl $0
80105e48:	6a 00                	push   $0x0
  pushl $185
80105e4a:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105e4f:	e9 9d f4 ff ff       	jmp    801052f1 <alltraps>

80105e54 <vector186>:
.globl vector186
vector186:
  pushl $0
80105e54:	6a 00                	push   $0x0
  pushl $186
80105e56:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105e5b:	e9 91 f4 ff ff       	jmp    801052f1 <alltraps>

80105e60 <vector187>:
.globl vector187
vector187:
  pushl $0
80105e60:	6a 00                	push   $0x0
  pushl $187
80105e62:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105e67:	e9 85 f4 ff ff       	jmp    801052f1 <alltraps>

80105e6c <vector188>:
.globl vector188
vector188:
  pushl $0
80105e6c:	6a 00                	push   $0x0
  pushl $188
80105e6e:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105e73:	e9 79 f4 ff ff       	jmp    801052f1 <alltraps>

80105e78 <vector189>:
.globl vector189
vector189:
  pushl $0
80105e78:	6a 00                	push   $0x0
  pushl $189
80105e7a:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105e7f:	e9 6d f4 ff ff       	jmp    801052f1 <alltraps>

80105e84 <vector190>:
.globl vector190
vector190:
  pushl $0
80105e84:	6a 00                	push   $0x0
  pushl $190
80105e86:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105e8b:	e9 61 f4 ff ff       	jmp    801052f1 <alltraps>

80105e90 <vector191>:
.globl vector191
vector191:
  pushl $0
80105e90:	6a 00                	push   $0x0
  pushl $191
80105e92:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105e97:	e9 55 f4 ff ff       	jmp    801052f1 <alltraps>

80105e9c <vector192>:
.globl vector192
vector192:
  pushl $0
80105e9c:	6a 00                	push   $0x0
  pushl $192
80105e9e:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105ea3:	e9 49 f4 ff ff       	jmp    801052f1 <alltraps>

80105ea8 <vector193>:
.globl vector193
vector193:
  pushl $0
80105ea8:	6a 00                	push   $0x0
  pushl $193
80105eaa:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105eaf:	e9 3d f4 ff ff       	jmp    801052f1 <alltraps>

80105eb4 <vector194>:
.globl vector194
vector194:
  pushl $0
80105eb4:	6a 00                	push   $0x0
  pushl $194
80105eb6:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105ebb:	e9 31 f4 ff ff       	jmp    801052f1 <alltraps>

80105ec0 <vector195>:
.globl vector195
vector195:
  pushl $0
80105ec0:	6a 00                	push   $0x0
  pushl $195
80105ec2:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105ec7:	e9 25 f4 ff ff       	jmp    801052f1 <alltraps>

80105ecc <vector196>:
.globl vector196
vector196:
  pushl $0
80105ecc:	6a 00                	push   $0x0
  pushl $196
80105ece:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105ed3:	e9 19 f4 ff ff       	jmp    801052f1 <alltraps>

80105ed8 <vector197>:
.globl vector197
vector197:
  pushl $0
80105ed8:	6a 00                	push   $0x0
  pushl $197
80105eda:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105edf:	e9 0d f4 ff ff       	jmp    801052f1 <alltraps>

80105ee4 <vector198>:
.globl vector198
vector198:
  pushl $0
80105ee4:	6a 00                	push   $0x0
  pushl $198
80105ee6:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105eeb:	e9 01 f4 ff ff       	jmp    801052f1 <alltraps>

80105ef0 <vector199>:
.globl vector199
vector199:
  pushl $0
80105ef0:	6a 00                	push   $0x0
  pushl $199
80105ef2:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105ef7:	e9 f5 f3 ff ff       	jmp    801052f1 <alltraps>

80105efc <vector200>:
.globl vector200
vector200:
  pushl $0
80105efc:	6a 00                	push   $0x0
  pushl $200
80105efe:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105f03:	e9 e9 f3 ff ff       	jmp    801052f1 <alltraps>

80105f08 <vector201>:
.globl vector201
vector201:
  pushl $0
80105f08:	6a 00                	push   $0x0
  pushl $201
80105f0a:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105f0f:	e9 dd f3 ff ff       	jmp    801052f1 <alltraps>

80105f14 <vector202>:
.globl vector202
vector202:
  pushl $0
80105f14:	6a 00                	push   $0x0
  pushl $202
80105f16:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105f1b:	e9 d1 f3 ff ff       	jmp    801052f1 <alltraps>

80105f20 <vector203>:
.globl vector203
vector203:
  pushl $0
80105f20:	6a 00                	push   $0x0
  pushl $203
80105f22:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105f27:	e9 c5 f3 ff ff       	jmp    801052f1 <alltraps>

80105f2c <vector204>:
.globl vector204
vector204:
  pushl $0
80105f2c:	6a 00                	push   $0x0
  pushl $204
80105f2e:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105f33:	e9 b9 f3 ff ff       	jmp    801052f1 <alltraps>

80105f38 <vector205>:
.globl vector205
vector205:
  pushl $0
80105f38:	6a 00                	push   $0x0
  pushl $205
80105f3a:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105f3f:	e9 ad f3 ff ff       	jmp    801052f1 <alltraps>

80105f44 <vector206>:
.globl vector206
vector206:
  pushl $0
80105f44:	6a 00                	push   $0x0
  pushl $206
80105f46:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105f4b:	e9 a1 f3 ff ff       	jmp    801052f1 <alltraps>

80105f50 <vector207>:
.globl vector207
vector207:
  pushl $0
80105f50:	6a 00                	push   $0x0
  pushl $207
80105f52:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105f57:	e9 95 f3 ff ff       	jmp    801052f1 <alltraps>

80105f5c <vector208>:
.globl vector208
vector208:
  pushl $0
80105f5c:	6a 00                	push   $0x0
  pushl $208
80105f5e:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105f63:	e9 89 f3 ff ff       	jmp    801052f1 <alltraps>

80105f68 <vector209>:
.globl vector209
vector209:
  pushl $0
80105f68:	6a 00                	push   $0x0
  pushl $209
80105f6a:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105f6f:	e9 7d f3 ff ff       	jmp    801052f1 <alltraps>

80105f74 <vector210>:
.globl vector210
vector210:
  pushl $0
80105f74:	6a 00                	push   $0x0
  pushl $210
80105f76:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105f7b:	e9 71 f3 ff ff       	jmp    801052f1 <alltraps>

80105f80 <vector211>:
.globl vector211
vector211:
  pushl $0
80105f80:	6a 00                	push   $0x0
  pushl $211
80105f82:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105f87:	e9 65 f3 ff ff       	jmp    801052f1 <alltraps>

80105f8c <vector212>:
.globl vector212
vector212:
  pushl $0
80105f8c:	6a 00                	push   $0x0
  pushl $212
80105f8e:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105f93:	e9 59 f3 ff ff       	jmp    801052f1 <alltraps>

80105f98 <vector213>:
.globl vector213
vector213:
  pushl $0
80105f98:	6a 00                	push   $0x0
  pushl $213
80105f9a:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105f9f:	e9 4d f3 ff ff       	jmp    801052f1 <alltraps>

80105fa4 <vector214>:
.globl vector214
vector214:
  pushl $0
80105fa4:	6a 00                	push   $0x0
  pushl $214
80105fa6:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105fab:	e9 41 f3 ff ff       	jmp    801052f1 <alltraps>

80105fb0 <vector215>:
.globl vector215
vector215:
  pushl $0
80105fb0:	6a 00                	push   $0x0
  pushl $215
80105fb2:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105fb7:	e9 35 f3 ff ff       	jmp    801052f1 <alltraps>

80105fbc <vector216>:
.globl vector216
vector216:
  pushl $0
80105fbc:	6a 00                	push   $0x0
  pushl $216
80105fbe:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105fc3:	e9 29 f3 ff ff       	jmp    801052f1 <alltraps>

80105fc8 <vector217>:
.globl vector217
vector217:
  pushl $0
80105fc8:	6a 00                	push   $0x0
  pushl $217
80105fca:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105fcf:	e9 1d f3 ff ff       	jmp    801052f1 <alltraps>

80105fd4 <vector218>:
.globl vector218
vector218:
  pushl $0
80105fd4:	6a 00                	push   $0x0
  pushl $218
80105fd6:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105fdb:	e9 11 f3 ff ff       	jmp    801052f1 <alltraps>

80105fe0 <vector219>:
.globl vector219
vector219:
  pushl $0
80105fe0:	6a 00                	push   $0x0
  pushl $219
80105fe2:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105fe7:	e9 05 f3 ff ff       	jmp    801052f1 <alltraps>

80105fec <vector220>:
.globl vector220
vector220:
  pushl $0
80105fec:	6a 00                	push   $0x0
  pushl $220
80105fee:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105ff3:	e9 f9 f2 ff ff       	jmp    801052f1 <alltraps>

80105ff8 <vector221>:
.globl vector221
vector221:
  pushl $0
80105ff8:	6a 00                	push   $0x0
  pushl $221
80105ffa:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105fff:	e9 ed f2 ff ff       	jmp    801052f1 <alltraps>

80106004 <vector222>:
.globl vector222
vector222:
  pushl $0
80106004:	6a 00                	push   $0x0
  pushl $222
80106006:	68 de 00 00 00       	push   $0xde
  jmp alltraps
8010600b:	e9 e1 f2 ff ff       	jmp    801052f1 <alltraps>

80106010 <vector223>:
.globl vector223
vector223:
  pushl $0
80106010:	6a 00                	push   $0x0
  pushl $223
80106012:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80106017:	e9 d5 f2 ff ff       	jmp    801052f1 <alltraps>

8010601c <vector224>:
.globl vector224
vector224:
  pushl $0
8010601c:	6a 00                	push   $0x0
  pushl $224
8010601e:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80106023:	e9 c9 f2 ff ff       	jmp    801052f1 <alltraps>

80106028 <vector225>:
.globl vector225
vector225:
  pushl $0
80106028:	6a 00                	push   $0x0
  pushl $225
8010602a:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
8010602f:	e9 bd f2 ff ff       	jmp    801052f1 <alltraps>

80106034 <vector226>:
.globl vector226
vector226:
  pushl $0
80106034:	6a 00                	push   $0x0
  pushl $226
80106036:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
8010603b:	e9 b1 f2 ff ff       	jmp    801052f1 <alltraps>

80106040 <vector227>:
.globl vector227
vector227:
  pushl $0
80106040:	6a 00                	push   $0x0
  pushl $227
80106042:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80106047:	e9 a5 f2 ff ff       	jmp    801052f1 <alltraps>

8010604c <vector228>:
.globl vector228
vector228:
  pushl $0
8010604c:	6a 00                	push   $0x0
  pushl $228
8010604e:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80106053:	e9 99 f2 ff ff       	jmp    801052f1 <alltraps>

80106058 <vector229>:
.globl vector229
vector229:
  pushl $0
80106058:	6a 00                	push   $0x0
  pushl $229
8010605a:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
8010605f:	e9 8d f2 ff ff       	jmp    801052f1 <alltraps>

80106064 <vector230>:
.globl vector230
vector230:
  pushl $0
80106064:	6a 00                	push   $0x0
  pushl $230
80106066:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
8010606b:	e9 81 f2 ff ff       	jmp    801052f1 <alltraps>

80106070 <vector231>:
.globl vector231
vector231:
  pushl $0
80106070:	6a 00                	push   $0x0
  pushl $231
80106072:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80106077:	e9 75 f2 ff ff       	jmp    801052f1 <alltraps>

8010607c <vector232>:
.globl vector232
vector232:
  pushl $0
8010607c:	6a 00                	push   $0x0
  pushl $232
8010607e:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80106083:	e9 69 f2 ff ff       	jmp    801052f1 <alltraps>

80106088 <vector233>:
.globl vector233
vector233:
  pushl $0
80106088:	6a 00                	push   $0x0
  pushl $233
8010608a:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
8010608f:	e9 5d f2 ff ff       	jmp    801052f1 <alltraps>

80106094 <vector234>:
.globl vector234
vector234:
  pushl $0
80106094:	6a 00                	push   $0x0
  pushl $234
80106096:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010609b:	e9 51 f2 ff ff       	jmp    801052f1 <alltraps>

801060a0 <vector235>:
.globl vector235
vector235:
  pushl $0
801060a0:	6a 00                	push   $0x0
  pushl $235
801060a2:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801060a7:	e9 45 f2 ff ff       	jmp    801052f1 <alltraps>

801060ac <vector236>:
.globl vector236
vector236:
  pushl $0
801060ac:	6a 00                	push   $0x0
  pushl $236
801060ae:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801060b3:	e9 39 f2 ff ff       	jmp    801052f1 <alltraps>

801060b8 <vector237>:
.globl vector237
vector237:
  pushl $0
801060b8:	6a 00                	push   $0x0
  pushl $237
801060ba:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801060bf:	e9 2d f2 ff ff       	jmp    801052f1 <alltraps>

801060c4 <vector238>:
.globl vector238
vector238:
  pushl $0
801060c4:	6a 00                	push   $0x0
  pushl $238
801060c6:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801060cb:	e9 21 f2 ff ff       	jmp    801052f1 <alltraps>

801060d0 <vector239>:
.globl vector239
vector239:
  pushl $0
801060d0:	6a 00                	push   $0x0
  pushl $239
801060d2:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801060d7:	e9 15 f2 ff ff       	jmp    801052f1 <alltraps>

801060dc <vector240>:
.globl vector240
vector240:
  pushl $0
801060dc:	6a 00                	push   $0x0
  pushl $240
801060de:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801060e3:	e9 09 f2 ff ff       	jmp    801052f1 <alltraps>

801060e8 <vector241>:
.globl vector241
vector241:
  pushl $0
801060e8:	6a 00                	push   $0x0
  pushl $241
801060ea:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801060ef:	e9 fd f1 ff ff       	jmp    801052f1 <alltraps>

801060f4 <vector242>:
.globl vector242
vector242:
  pushl $0
801060f4:	6a 00                	push   $0x0
  pushl $242
801060f6:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801060fb:	e9 f1 f1 ff ff       	jmp    801052f1 <alltraps>

80106100 <vector243>:
.globl vector243
vector243:
  pushl $0
80106100:	6a 00                	push   $0x0
  pushl $243
80106102:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80106107:	e9 e5 f1 ff ff       	jmp    801052f1 <alltraps>

8010610c <vector244>:
.globl vector244
vector244:
  pushl $0
8010610c:	6a 00                	push   $0x0
  pushl $244
8010610e:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80106113:	e9 d9 f1 ff ff       	jmp    801052f1 <alltraps>

80106118 <vector245>:
.globl vector245
vector245:
  pushl $0
80106118:	6a 00                	push   $0x0
  pushl $245
8010611a:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
8010611f:	e9 cd f1 ff ff       	jmp    801052f1 <alltraps>

80106124 <vector246>:
.globl vector246
vector246:
  pushl $0
80106124:	6a 00                	push   $0x0
  pushl $246
80106126:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
8010612b:	e9 c1 f1 ff ff       	jmp    801052f1 <alltraps>

80106130 <vector247>:
.globl vector247
vector247:
  pushl $0
80106130:	6a 00                	push   $0x0
  pushl $247
80106132:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80106137:	e9 b5 f1 ff ff       	jmp    801052f1 <alltraps>

8010613c <vector248>:
.globl vector248
vector248:
  pushl $0
8010613c:	6a 00                	push   $0x0
  pushl $248
8010613e:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80106143:	e9 a9 f1 ff ff       	jmp    801052f1 <alltraps>

80106148 <vector249>:
.globl vector249
vector249:
  pushl $0
80106148:	6a 00                	push   $0x0
  pushl $249
8010614a:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
8010614f:	e9 9d f1 ff ff       	jmp    801052f1 <alltraps>

80106154 <vector250>:
.globl vector250
vector250:
  pushl $0
80106154:	6a 00                	push   $0x0
  pushl $250
80106156:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
8010615b:	e9 91 f1 ff ff       	jmp    801052f1 <alltraps>

80106160 <vector251>:
.globl vector251
vector251:
  pushl $0
80106160:	6a 00                	push   $0x0
  pushl $251
80106162:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80106167:	e9 85 f1 ff ff       	jmp    801052f1 <alltraps>

8010616c <vector252>:
.globl vector252
vector252:
  pushl $0
8010616c:	6a 00                	push   $0x0
  pushl $252
8010616e:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80106173:	e9 79 f1 ff ff       	jmp    801052f1 <alltraps>

80106178 <vector253>:
.globl vector253
vector253:
  pushl $0
80106178:	6a 00                	push   $0x0
  pushl $253
8010617a:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
8010617f:	e9 6d f1 ff ff       	jmp    801052f1 <alltraps>

80106184 <vector254>:
.globl vector254
vector254:
  pushl $0
80106184:	6a 00                	push   $0x0
  pushl $254
80106186:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010618b:	e9 61 f1 ff ff       	jmp    801052f1 <alltraps>

80106190 <vector255>:
.globl vector255
vector255:
  pushl $0
80106190:	6a 00                	push   $0x0
  pushl $255
80106192:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80106197:	e9 55 f1 ff ff       	jmp    801052f1 <alltraps>

8010619c <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010619c:	55                   	push   %ebp
8010619d:	89 e5                	mov    %esp,%ebp
8010619f:	57                   	push   %edi
801061a0:	56                   	push   %esi
801061a1:	53                   	push   %ebx
801061a2:	83 ec 0c             	sub    $0xc,%esp
801061a5:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
801061a7:	c1 ea 16             	shr    $0x16,%edx
801061aa:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
801061ad:	8b 1f                	mov    (%edi),%ebx
801061af:	f6 c3 01             	test   $0x1,%bl
801061b2:	74 22                	je     801061d6 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
801061b4:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
801061ba:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
801061c0:	c1 ee 0c             	shr    $0xc,%esi
801061c3:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
801061c9:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
801061cc:	89 d8                	mov    %ebx,%eax
801061ce:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061d1:	5b                   	pop    %ebx
801061d2:	5e                   	pop    %esi
801061d3:	5f                   	pop    %edi
801061d4:	5d                   	pop    %ebp
801061d5:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801061d6:	85 c9                	test   %ecx,%ecx
801061d8:	74 2b                	je     80106205 <walkpgdir+0x69>
801061da:	e8 dc be ff ff       	call   801020bb <kalloc>
801061df:	89 c3                	mov    %eax,%ebx
801061e1:	85 c0                	test   %eax,%eax
801061e3:	74 e7                	je     801061cc <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
801061e5:	83 ec 04             	sub    $0x4,%esp
801061e8:	68 00 10 00 00       	push   $0x1000
801061ed:	6a 00                	push   $0x0
801061ef:	50                   	push   %eax
801061f0:	e8 b9 df ff ff       	call   801041ae <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
801061f5:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801061fb:	83 c8 07             	or     $0x7,%eax
801061fe:	89 07                	mov    %eax,(%edi)
80106200:	83 c4 10             	add    $0x10,%esp
80106203:	eb bb                	jmp    801061c0 <walkpgdir+0x24>
      return 0;
80106205:	bb 00 00 00 00       	mov    $0x0,%ebx
8010620a:	eb c0                	jmp    801061cc <walkpgdir+0x30>

8010620c <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010620c:	55                   	push   %ebp
8010620d:	89 e5                	mov    %esp,%ebp
8010620f:	57                   	push   %edi
80106210:	56                   	push   %esi
80106211:	53                   	push   %ebx
80106212:	83 ec 1c             	sub    $0x1c,%esp
80106215:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106218:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
8010621b:	89 d3                	mov    %edx,%ebx
8010621d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80106223:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80106227:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010622d:	b9 01 00 00 00       	mov    $0x1,%ecx
80106232:	89 da                	mov    %ebx,%edx
80106234:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106237:	e8 60 ff ff ff       	call   8010619c <walkpgdir>
8010623c:	85 c0                	test   %eax,%eax
8010623e:	74 2e                	je     8010626e <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80106240:	f6 00 01             	testb  $0x1,(%eax)
80106243:	75 1c                	jne    80106261 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80106245:	89 f2                	mov    %esi,%edx
80106247:	0b 55 0c             	or     0xc(%ebp),%edx
8010624a:	83 ca 01             	or     $0x1,%edx
8010624d:	89 10                	mov    %edx,(%eax)
    if(a == last)
8010624f:	39 fb                	cmp    %edi,%ebx
80106251:	74 28                	je     8010627b <mappages+0x6f>
      break;
    a += PGSIZE;
80106253:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80106259:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010625f:	eb cc                	jmp    8010622d <mappages+0x21>
      panic("remap");
80106261:	83 ec 0c             	sub    $0xc,%esp
80106264:	68 d8 73 10 80       	push   $0x801073d8
80106269:	e8 da a0 ff ff       	call   80100348 <panic>
      return -1;
8010626e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80106273:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106276:	5b                   	pop    %ebx
80106277:	5e                   	pop    %esi
80106278:	5f                   	pop    %edi
80106279:	5d                   	pop    %ebp
8010627a:	c3                   	ret    
  return 0;
8010627b:	b8 00 00 00 00       	mov    $0x0,%eax
80106280:	eb f1                	jmp    80106273 <mappages+0x67>

80106282 <seginit>:
{
80106282:	55                   	push   %ebp
80106283:	89 e5                	mov    %esp,%ebp
80106285:	53                   	push   %ebx
80106286:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80106289:	e8 88 cf ff ff       	call   80103216 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010628e:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80106294:	66 c7 80 f8 27 11 80 	movw   $0xffff,-0x7feed808(%eax)
8010629b:	ff ff 
8010629d:	66 c7 80 fa 27 11 80 	movw   $0x0,-0x7feed806(%eax)
801062a4:	00 00 
801062a6:	c6 80 fc 27 11 80 00 	movb   $0x0,-0x7feed804(%eax)
801062ad:	0f b6 88 fd 27 11 80 	movzbl -0x7feed803(%eax),%ecx
801062b4:	83 e1 f0             	and    $0xfffffff0,%ecx
801062b7:	83 c9 1a             	or     $0x1a,%ecx
801062ba:	83 e1 9f             	and    $0xffffff9f,%ecx
801062bd:	83 c9 80             	or     $0xffffff80,%ecx
801062c0:	88 88 fd 27 11 80    	mov    %cl,-0x7feed803(%eax)
801062c6:	0f b6 88 fe 27 11 80 	movzbl -0x7feed802(%eax),%ecx
801062cd:	83 c9 0f             	or     $0xf,%ecx
801062d0:	83 e1 cf             	and    $0xffffffcf,%ecx
801062d3:	83 c9 c0             	or     $0xffffffc0,%ecx
801062d6:	88 88 fe 27 11 80    	mov    %cl,-0x7feed802(%eax)
801062dc:	c6 80 ff 27 11 80 00 	movb   $0x0,-0x7feed801(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801062e3:	66 c7 80 00 28 11 80 	movw   $0xffff,-0x7feed800(%eax)
801062ea:	ff ff 
801062ec:	66 c7 80 02 28 11 80 	movw   $0x0,-0x7feed7fe(%eax)
801062f3:	00 00 
801062f5:	c6 80 04 28 11 80 00 	movb   $0x0,-0x7feed7fc(%eax)
801062fc:	0f b6 88 05 28 11 80 	movzbl -0x7feed7fb(%eax),%ecx
80106303:	83 e1 f0             	and    $0xfffffff0,%ecx
80106306:	83 c9 12             	or     $0x12,%ecx
80106309:	83 e1 9f             	and    $0xffffff9f,%ecx
8010630c:	83 c9 80             	or     $0xffffff80,%ecx
8010630f:	88 88 05 28 11 80    	mov    %cl,-0x7feed7fb(%eax)
80106315:	0f b6 88 06 28 11 80 	movzbl -0x7feed7fa(%eax),%ecx
8010631c:	83 c9 0f             	or     $0xf,%ecx
8010631f:	83 e1 cf             	and    $0xffffffcf,%ecx
80106322:	83 c9 c0             	or     $0xffffffc0,%ecx
80106325:	88 88 06 28 11 80    	mov    %cl,-0x7feed7fa(%eax)
8010632b:	c6 80 07 28 11 80 00 	movb   $0x0,-0x7feed7f9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80106332:	66 c7 80 08 28 11 80 	movw   $0xffff,-0x7feed7f8(%eax)
80106339:	ff ff 
8010633b:	66 c7 80 0a 28 11 80 	movw   $0x0,-0x7feed7f6(%eax)
80106342:	00 00 
80106344:	c6 80 0c 28 11 80 00 	movb   $0x0,-0x7feed7f4(%eax)
8010634b:	c6 80 0d 28 11 80 fa 	movb   $0xfa,-0x7feed7f3(%eax)
80106352:	0f b6 88 0e 28 11 80 	movzbl -0x7feed7f2(%eax),%ecx
80106359:	83 c9 0f             	or     $0xf,%ecx
8010635c:	83 e1 cf             	and    $0xffffffcf,%ecx
8010635f:	83 c9 c0             	or     $0xffffffc0,%ecx
80106362:	88 88 0e 28 11 80    	mov    %cl,-0x7feed7f2(%eax)
80106368:	c6 80 0f 28 11 80 00 	movb   $0x0,-0x7feed7f1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010636f:	66 c7 80 10 28 11 80 	movw   $0xffff,-0x7feed7f0(%eax)
80106376:	ff ff 
80106378:	66 c7 80 12 28 11 80 	movw   $0x0,-0x7feed7ee(%eax)
8010637f:	00 00 
80106381:	c6 80 14 28 11 80 00 	movb   $0x0,-0x7feed7ec(%eax)
80106388:	c6 80 15 28 11 80 f2 	movb   $0xf2,-0x7feed7eb(%eax)
8010638f:	0f b6 88 16 28 11 80 	movzbl -0x7feed7ea(%eax),%ecx
80106396:	83 c9 0f             	or     $0xf,%ecx
80106399:	83 e1 cf             	and    $0xffffffcf,%ecx
8010639c:	83 c9 c0             	or     $0xffffffc0,%ecx
8010639f:	88 88 16 28 11 80    	mov    %cl,-0x7feed7ea(%eax)
801063a5:	c6 80 17 28 11 80 00 	movb   $0x0,-0x7feed7e9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
801063ac:	05 f0 27 11 80       	add    $0x801127f0,%eax
  pd[0] = size-1;
801063b1:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
801063b7:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
801063bb:	c1 e8 10             	shr    $0x10,%eax
801063be:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
801063c2:	8d 45 f2             	lea    -0xe(%ebp),%eax
801063c5:	0f 01 10             	lgdtl  (%eax)
}
801063c8:	83 c4 14             	add    $0x14,%esp
801063cb:	5b                   	pop    %ebx
801063cc:	5d                   	pop    %ebp
801063cd:	c3                   	ret    

801063ce <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801063ce:	55                   	push   %ebp
801063cf:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
801063d1:	a1 c4 6b 11 80       	mov    0x80116bc4,%eax
801063d6:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
801063db:	0f 22 d8             	mov    %eax,%cr3
}
801063de:	5d                   	pop    %ebp
801063df:	c3                   	ret    

801063e0 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801063e0:	55                   	push   %ebp
801063e1:	89 e5                	mov    %esp,%ebp
801063e3:	57                   	push   %edi
801063e4:	56                   	push   %esi
801063e5:	53                   	push   %ebx
801063e6:	83 ec 1c             	sub    $0x1c,%esp
801063e9:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
801063ec:	85 f6                	test   %esi,%esi
801063ee:	0f 84 dd 00 00 00    	je     801064d1 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
801063f4:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
801063f8:	0f 84 e0 00 00 00    	je     801064de <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
801063fe:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80106402:	0f 84 e3 00 00 00    	je     801064eb <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80106408:	e8 18 dc ff ff       	call   80104025 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
8010640d:	e8 a8 cd ff ff       	call   801031ba <mycpu>
80106412:	89 c3                	mov    %eax,%ebx
80106414:	e8 a1 cd ff ff       	call   801031ba <mycpu>
80106419:	8d 78 08             	lea    0x8(%eax),%edi
8010641c:	e8 99 cd ff ff       	call   801031ba <mycpu>
80106421:	83 c0 08             	add    $0x8,%eax
80106424:	c1 e8 10             	shr    $0x10,%eax
80106427:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010642a:	e8 8b cd ff ff       	call   801031ba <mycpu>
8010642f:	83 c0 08             	add    $0x8,%eax
80106432:	c1 e8 18             	shr    $0x18,%eax
80106435:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
8010643c:	67 00 
8010643e:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80106445:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80106449:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
8010644f:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80106456:	83 e2 f0             	and    $0xfffffff0,%edx
80106459:	83 ca 19             	or     $0x19,%edx
8010645c:	83 e2 9f             	and    $0xffffff9f,%edx
8010645f:	83 ca 80             	or     $0xffffff80,%edx
80106462:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80106468:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
8010646f:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80106475:	e8 40 cd ff ff       	call   801031ba <mycpu>
8010647a:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106481:	83 e2 ef             	and    $0xffffffef,%edx
80106484:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
8010648a:	e8 2b cd ff ff       	call   801031ba <mycpu>
8010648f:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106495:	8b 5e 08             	mov    0x8(%esi),%ebx
80106498:	e8 1d cd ff ff       	call   801031ba <mycpu>
8010649d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801064a3:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
801064a6:	e8 0f cd ff ff       	call   801031ba <mycpu>
801064ab:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
801064b1:	b8 28 00 00 00       	mov    $0x28,%eax
801064b6:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
801064b9:	8b 46 04             	mov    0x4(%esi),%eax
801064bc:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
801064c1:	0f 22 d8             	mov    %eax,%cr3
  popcli();
801064c4:	e8 99 db ff ff       	call   80104062 <popcli>
}
801064c9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064cc:	5b                   	pop    %ebx
801064cd:	5e                   	pop    %esi
801064ce:	5f                   	pop    %edi
801064cf:	5d                   	pop    %ebp
801064d0:	c3                   	ret    
    panic("switchuvm: no process");
801064d1:	83 ec 0c             	sub    $0xc,%esp
801064d4:	68 de 73 10 80       	push   $0x801073de
801064d9:	e8 6a 9e ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
801064de:	83 ec 0c             	sub    $0xc,%esp
801064e1:	68 f4 73 10 80       	push   $0x801073f4
801064e6:	e8 5d 9e ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
801064eb:	83 ec 0c             	sub    $0xc,%esp
801064ee:	68 09 74 10 80       	push   $0x80107409
801064f3:	e8 50 9e ff ff       	call   80100348 <panic>

801064f8 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801064f8:	55                   	push   %ebp
801064f9:	89 e5                	mov    %esp,%ebp
801064fb:	56                   	push   %esi
801064fc:	53                   	push   %ebx
801064fd:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
80106500:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106506:	77 4c                	ja     80106554 <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
80106508:	e8 ae bb ff ff       	call   801020bb <kalloc>
8010650d:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
8010650f:	83 ec 04             	sub    $0x4,%esp
80106512:	68 00 10 00 00       	push   $0x1000
80106517:	6a 00                	push   $0x0
80106519:	50                   	push   %eax
8010651a:	e8 8f dc ff ff       	call   801041ae <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
8010651f:	83 c4 08             	add    $0x8,%esp
80106522:	6a 06                	push   $0x6
80106524:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010652a:	50                   	push   %eax
8010652b:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106530:	ba 00 00 00 00       	mov    $0x0,%edx
80106535:	8b 45 08             	mov    0x8(%ebp),%eax
80106538:	e8 cf fc ff ff       	call   8010620c <mappages>
  memmove(mem, init, sz);
8010653d:	83 c4 0c             	add    $0xc,%esp
80106540:	56                   	push   %esi
80106541:	ff 75 0c             	pushl  0xc(%ebp)
80106544:	53                   	push   %ebx
80106545:	e8 df dc ff ff       	call   80104229 <memmove>
}
8010654a:	83 c4 10             	add    $0x10,%esp
8010654d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106550:	5b                   	pop    %ebx
80106551:	5e                   	pop    %esi
80106552:	5d                   	pop    %ebp
80106553:	c3                   	ret    
    panic("inituvm: more than a page");
80106554:	83 ec 0c             	sub    $0xc,%esp
80106557:	68 1d 74 10 80       	push   $0x8010741d
8010655c:	e8 e7 9d ff ff       	call   80100348 <panic>

80106561 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106561:	55                   	push   %ebp
80106562:	89 e5                	mov    %esp,%ebp
80106564:	57                   	push   %edi
80106565:	56                   	push   %esi
80106566:	53                   	push   %ebx
80106567:	83 ec 0c             	sub    $0xc,%esp
8010656a:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010656d:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106574:	75 07                	jne    8010657d <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80106576:	bb 00 00 00 00       	mov    $0x0,%ebx
8010657b:	eb 3c                	jmp    801065b9 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
8010657d:	83 ec 0c             	sub    $0xc,%esp
80106580:	68 d8 74 10 80       	push   $0x801074d8
80106585:	e8 be 9d ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
8010658a:	83 ec 0c             	sub    $0xc,%esp
8010658d:	68 37 74 10 80       	push   $0x80107437
80106592:	e8 b1 9d ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106597:	05 00 00 00 80       	add    $0x80000000,%eax
8010659c:	56                   	push   %esi
8010659d:	89 da                	mov    %ebx,%edx
8010659f:	03 55 14             	add    0x14(%ebp),%edx
801065a2:	52                   	push   %edx
801065a3:	50                   	push   %eax
801065a4:	ff 75 10             	pushl  0x10(%ebp)
801065a7:	e8 c7 b1 ff ff       	call   80101773 <readi>
801065ac:	83 c4 10             	add    $0x10,%esp
801065af:	39 f0                	cmp    %esi,%eax
801065b1:	75 47                	jne    801065fa <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
801065b3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801065b9:	39 fb                	cmp    %edi,%ebx
801065bb:	73 30                	jae    801065ed <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801065bd:	89 da                	mov    %ebx,%edx
801065bf:	03 55 0c             	add    0xc(%ebp),%edx
801065c2:	b9 00 00 00 00       	mov    $0x0,%ecx
801065c7:	8b 45 08             	mov    0x8(%ebp),%eax
801065ca:	e8 cd fb ff ff       	call   8010619c <walkpgdir>
801065cf:	85 c0                	test   %eax,%eax
801065d1:	74 b7                	je     8010658a <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
801065d3:	8b 00                	mov    (%eax),%eax
801065d5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801065da:	89 fe                	mov    %edi,%esi
801065dc:	29 de                	sub    %ebx,%esi
801065de:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801065e4:	76 b1                	jbe    80106597 <loaduvm+0x36>
      n = PGSIZE;
801065e6:	be 00 10 00 00       	mov    $0x1000,%esi
801065eb:	eb aa                	jmp    80106597 <loaduvm+0x36>
      return -1;
  }
  return 0;
801065ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
801065f5:	5b                   	pop    %ebx
801065f6:	5e                   	pop    %esi
801065f7:	5f                   	pop    %edi
801065f8:	5d                   	pop    %ebp
801065f9:	c3                   	ret    
      return -1;
801065fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065ff:	eb f1                	jmp    801065f2 <loaduvm+0x91>

80106601 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80106601:	55                   	push   %ebp
80106602:	89 e5                	mov    %esp,%ebp
80106604:	57                   	push   %edi
80106605:	56                   	push   %esi
80106606:	53                   	push   %ebx
80106607:	83 ec 0c             	sub    $0xc,%esp
8010660a:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010660d:	39 7d 10             	cmp    %edi,0x10(%ebp)
80106610:	73 11                	jae    80106623 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
80106612:	8b 45 10             	mov    0x10(%ebp),%eax
80106615:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010661b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106621:	eb 19                	jmp    8010663c <deallocuvm+0x3b>
    return oldsz;
80106623:	89 f8                	mov    %edi,%eax
80106625:	eb 64                	jmp    8010668b <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106627:	c1 eb 16             	shr    $0x16,%ebx
8010662a:	83 c3 01             	add    $0x1,%ebx
8010662d:	c1 e3 16             	shl    $0x16,%ebx
80106630:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106636:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010663c:	39 fb                	cmp    %edi,%ebx
8010663e:	73 48                	jae    80106688 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106640:	b9 00 00 00 00       	mov    $0x0,%ecx
80106645:	89 da                	mov    %ebx,%edx
80106647:	8b 45 08             	mov    0x8(%ebp),%eax
8010664a:	e8 4d fb ff ff       	call   8010619c <walkpgdir>
8010664f:	89 c6                	mov    %eax,%esi
    if(!pte)
80106651:	85 c0                	test   %eax,%eax
80106653:	74 d2                	je     80106627 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106655:	8b 00                	mov    (%eax),%eax
80106657:	a8 01                	test   $0x1,%al
80106659:	74 db                	je     80106636 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
8010665b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106660:	74 19                	je     8010667b <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106662:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106667:	83 ec 0c             	sub    $0xc,%esp
8010666a:	50                   	push   %eax
8010666b:	e8 34 b9 ff ff       	call   80101fa4 <kfree>
      *pte = 0;
80106670:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106676:	83 c4 10             	add    $0x10,%esp
80106679:	eb bb                	jmp    80106636 <deallocuvm+0x35>
        panic("kfree");
8010667b:	83 ec 0c             	sub    $0xc,%esp
8010667e:	68 a6 6c 10 80       	push   $0x80106ca6
80106683:	e8 c0 9c ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106688:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010668b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010668e:	5b                   	pop    %ebx
8010668f:	5e                   	pop    %esi
80106690:	5f                   	pop    %edi
80106691:	5d                   	pop    %ebp
80106692:	c3                   	ret    

80106693 <allocuvm>:
{
80106693:	55                   	push   %ebp
80106694:	89 e5                	mov    %esp,%ebp
80106696:	57                   	push   %edi
80106697:	56                   	push   %esi
80106698:	53                   	push   %ebx
80106699:	83 ec 1c             	sub    $0x1c,%esp
8010669c:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
8010669f:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801066a2:	85 ff                	test   %edi,%edi
801066a4:	0f 88 c1 00 00 00    	js     8010676b <allocuvm+0xd8>
  if(newsz < oldsz)
801066aa:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801066ad:	72 5c                	jb     8010670b <allocuvm+0x78>
  a = PGROUNDUP(oldsz);
801066af:	8b 45 0c             	mov    0xc(%ebp),%eax
801066b2:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801066b8:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
801066be:	39 fb                	cmp    %edi,%ebx
801066c0:	0f 83 ac 00 00 00    	jae    80106772 <allocuvm+0xdf>
    mem = kalloc();
801066c6:	e8 f0 b9 ff ff       	call   801020bb <kalloc>
801066cb:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801066cd:	85 c0                	test   %eax,%eax
801066cf:	74 42                	je     80106713 <allocuvm+0x80>
    memset(mem, 0, PGSIZE);
801066d1:	83 ec 04             	sub    $0x4,%esp
801066d4:	68 00 10 00 00       	push   $0x1000
801066d9:	6a 00                	push   $0x0
801066db:	50                   	push   %eax
801066dc:	e8 cd da ff ff       	call   801041ae <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801066e1:	83 c4 08             	add    $0x8,%esp
801066e4:	6a 06                	push   $0x6
801066e6:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801066ec:	50                   	push   %eax
801066ed:	b9 00 10 00 00       	mov    $0x1000,%ecx
801066f2:	89 da                	mov    %ebx,%edx
801066f4:	8b 45 08             	mov    0x8(%ebp),%eax
801066f7:	e8 10 fb ff ff       	call   8010620c <mappages>
801066fc:	83 c4 10             	add    $0x10,%esp
801066ff:	85 c0                	test   %eax,%eax
80106701:	78 38                	js     8010673b <allocuvm+0xa8>
  for(; a < newsz; a += PGSIZE){
80106703:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106709:	eb b3                	jmp    801066be <allocuvm+0x2b>
    return oldsz;
8010670b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010670e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106711:	eb 5f                	jmp    80106772 <allocuvm+0xdf>
      cprintf("allocuvm out of memory\n");
80106713:	83 ec 0c             	sub    $0xc,%esp
80106716:	68 55 74 10 80       	push   $0x80107455
8010671b:	e8 eb 9e ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106720:	83 c4 0c             	add    $0xc,%esp
80106723:	ff 75 0c             	pushl  0xc(%ebp)
80106726:	57                   	push   %edi
80106727:	ff 75 08             	pushl  0x8(%ebp)
8010672a:	e8 d2 fe ff ff       	call   80106601 <deallocuvm>
      return 0;
8010672f:	83 c4 10             	add    $0x10,%esp
80106732:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106739:	eb 37                	jmp    80106772 <allocuvm+0xdf>
      cprintf("allocuvm out of memory (2)\n");
8010673b:	83 ec 0c             	sub    $0xc,%esp
8010673e:	68 6d 74 10 80       	push   $0x8010746d
80106743:	e8 c3 9e ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106748:	83 c4 0c             	add    $0xc,%esp
8010674b:	ff 75 0c             	pushl  0xc(%ebp)
8010674e:	57                   	push   %edi
8010674f:	ff 75 08             	pushl  0x8(%ebp)
80106752:	e8 aa fe ff ff       	call   80106601 <deallocuvm>
      kfree(mem);
80106757:	89 34 24             	mov    %esi,(%esp)
8010675a:	e8 45 b8 ff ff       	call   80101fa4 <kfree>
      return 0;
8010675f:	83 c4 10             	add    $0x10,%esp
80106762:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106769:	eb 07                	jmp    80106772 <allocuvm+0xdf>
    return 0;
8010676b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106772:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106775:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106778:	5b                   	pop    %ebx
80106779:	5e                   	pop    %esi
8010677a:	5f                   	pop    %edi
8010677b:	5d                   	pop    %ebp
8010677c:	c3                   	ret    

8010677d <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010677d:	55                   	push   %ebp
8010677e:	89 e5                	mov    %esp,%ebp
80106780:	56                   	push   %esi
80106781:	53                   	push   %ebx
80106782:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
80106785:	85 f6                	test   %esi,%esi
80106787:	74 1a                	je     801067a3 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
80106789:	83 ec 04             	sub    $0x4,%esp
8010678c:	6a 00                	push   $0x0
8010678e:	68 00 00 00 80       	push   $0x80000000
80106793:	56                   	push   %esi
80106794:	e8 68 fe ff ff       	call   80106601 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80106799:	83 c4 10             	add    $0x10,%esp
8010679c:	bb 00 00 00 00       	mov    $0x0,%ebx
801067a1:	eb 10                	jmp    801067b3 <freevm+0x36>
    panic("freevm: no pgdir");
801067a3:	83 ec 0c             	sub    $0xc,%esp
801067a6:	68 89 74 10 80       	push   $0x80107489
801067ab:	e8 98 9b ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
801067b0:	83 c3 01             	add    $0x1,%ebx
801067b3:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
801067b9:	77 1f                	ja     801067da <freevm+0x5d>
    if(pgdir[i] & PTE_P){
801067bb:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
801067be:	a8 01                	test   $0x1,%al
801067c0:	74 ee                	je     801067b0 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801067c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801067c7:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801067cc:	83 ec 0c             	sub    $0xc,%esp
801067cf:	50                   	push   %eax
801067d0:	e8 cf b7 ff ff       	call   80101fa4 <kfree>
801067d5:	83 c4 10             	add    $0x10,%esp
801067d8:	eb d6                	jmp    801067b0 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801067da:	83 ec 0c             	sub    $0xc,%esp
801067dd:	56                   	push   %esi
801067de:	e8 c1 b7 ff ff       	call   80101fa4 <kfree>
}
801067e3:	83 c4 10             	add    $0x10,%esp
801067e6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801067e9:	5b                   	pop    %ebx
801067ea:	5e                   	pop    %esi
801067eb:	5d                   	pop    %ebp
801067ec:	c3                   	ret    

801067ed <setupkvm>:
{
801067ed:	55                   	push   %ebp
801067ee:	89 e5                	mov    %esp,%ebp
801067f0:	56                   	push   %esi
801067f1:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
801067f2:	e8 c4 b8 ff ff       	call   801020bb <kalloc>
801067f7:	89 c6                	mov    %eax,%esi
801067f9:	85 c0                	test   %eax,%eax
801067fb:	74 55                	je     80106852 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
801067fd:	83 ec 04             	sub    $0x4,%esp
80106800:	68 00 10 00 00       	push   $0x1000
80106805:	6a 00                	push   $0x0
80106807:	50                   	push   %eax
80106808:	e8 a1 d9 ff ff       	call   801041ae <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010680d:	83 c4 10             	add    $0x10,%esp
80106810:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
80106815:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
8010681b:	73 35                	jae    80106852 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
8010681d:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80106820:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106823:	29 c1                	sub    %eax,%ecx
80106825:	83 ec 08             	sub    $0x8,%esp
80106828:	ff 73 0c             	pushl  0xc(%ebx)
8010682b:	50                   	push   %eax
8010682c:	8b 13                	mov    (%ebx),%edx
8010682e:	89 f0                	mov    %esi,%eax
80106830:	e8 d7 f9 ff ff       	call   8010620c <mappages>
80106835:	83 c4 10             	add    $0x10,%esp
80106838:	85 c0                	test   %eax,%eax
8010683a:	78 05                	js     80106841 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010683c:	83 c3 10             	add    $0x10,%ebx
8010683f:	eb d4                	jmp    80106815 <setupkvm+0x28>
      freevm(pgdir);
80106841:	83 ec 0c             	sub    $0xc,%esp
80106844:	56                   	push   %esi
80106845:	e8 33 ff ff ff       	call   8010677d <freevm>
      return 0;
8010684a:	83 c4 10             	add    $0x10,%esp
8010684d:	be 00 00 00 00       	mov    $0x0,%esi
}
80106852:	89 f0                	mov    %esi,%eax
80106854:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106857:	5b                   	pop    %ebx
80106858:	5e                   	pop    %esi
80106859:	5d                   	pop    %ebp
8010685a:	c3                   	ret    

8010685b <kvmalloc>:
{
8010685b:	55                   	push   %ebp
8010685c:	89 e5                	mov    %esp,%ebp
8010685e:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106861:	e8 87 ff ff ff       	call   801067ed <setupkvm>
80106866:	a3 c4 6b 11 80       	mov    %eax,0x80116bc4
  switchkvm();
8010686b:	e8 5e fb ff ff       	call   801063ce <switchkvm>
}
80106870:	c9                   	leave  
80106871:	c3                   	ret    

80106872 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106872:	55                   	push   %ebp
80106873:	89 e5                	mov    %esp,%ebp
80106875:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106878:	b9 00 00 00 00       	mov    $0x0,%ecx
8010687d:	8b 55 0c             	mov    0xc(%ebp),%edx
80106880:	8b 45 08             	mov    0x8(%ebp),%eax
80106883:	e8 14 f9 ff ff       	call   8010619c <walkpgdir>
  if(pte == 0)
80106888:	85 c0                	test   %eax,%eax
8010688a:	74 05                	je     80106891 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010688c:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
8010688f:	c9                   	leave  
80106890:	c3                   	ret    
    panic("clearpteu");
80106891:	83 ec 0c             	sub    $0xc,%esp
80106894:	68 9a 74 10 80       	push   $0x8010749a
80106899:	e8 aa 9a ff ff       	call   80100348 <panic>

8010689e <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010689e:	55                   	push   %ebp
8010689f:	89 e5                	mov    %esp,%ebp
801068a1:	57                   	push   %edi
801068a2:	56                   	push   %esi
801068a3:	53                   	push   %ebx
801068a4:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801068a7:	e8 41 ff ff ff       	call   801067ed <setupkvm>
801068ac:	89 45 dc             	mov    %eax,-0x24(%ebp)
801068af:	85 c0                	test   %eax,%eax
801068b1:	0f 84 c4 00 00 00    	je     8010697b <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801068b7:	bf 00 00 00 00       	mov    $0x0,%edi
801068bc:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801068bf:	0f 83 b6 00 00 00    	jae    8010697b <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801068c5:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801068c8:	b9 00 00 00 00       	mov    $0x0,%ecx
801068cd:	89 fa                	mov    %edi,%edx
801068cf:	8b 45 08             	mov    0x8(%ebp),%eax
801068d2:	e8 c5 f8 ff ff       	call   8010619c <walkpgdir>
801068d7:	85 c0                	test   %eax,%eax
801068d9:	74 65                	je     80106940 <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801068db:	8b 00                	mov    (%eax),%eax
801068dd:	a8 01                	test   $0x1,%al
801068df:	74 6c                	je     8010694d <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801068e1:	89 c6                	mov    %eax,%esi
801068e3:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
801068e9:	25 ff 0f 00 00       	and    $0xfff,%eax
801068ee:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
801068f1:	e8 c5 b7 ff ff       	call   801020bb <kalloc>
801068f6:	89 c3                	mov    %eax,%ebx
801068f8:	85 c0                	test   %eax,%eax
801068fa:	74 6a                	je     80106966 <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801068fc:	81 c6 00 00 00 80    	add    $0x80000000,%esi
80106902:	83 ec 04             	sub    $0x4,%esp
80106905:	68 00 10 00 00       	push   $0x1000
8010690a:	56                   	push   %esi
8010690b:	50                   	push   %eax
8010690c:	e8 18 d9 ff ff       	call   80104229 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
80106911:	83 c4 08             	add    $0x8,%esp
80106914:	ff 75 e0             	pushl  -0x20(%ebp)
80106917:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010691d:	50                   	push   %eax
8010691e:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106923:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106926:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106929:	e8 de f8 ff ff       	call   8010620c <mappages>
8010692e:	83 c4 10             	add    $0x10,%esp
80106931:	85 c0                	test   %eax,%eax
80106933:	78 25                	js     8010695a <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
80106935:	81 c7 00 10 00 00    	add    $0x1000,%edi
8010693b:	e9 7c ff ff ff       	jmp    801068bc <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
80106940:	83 ec 0c             	sub    $0xc,%esp
80106943:	68 a4 74 10 80       	push   $0x801074a4
80106948:	e8 fb 99 ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
8010694d:	83 ec 0c             	sub    $0xc,%esp
80106950:	68 be 74 10 80       	push   $0x801074be
80106955:	e8 ee 99 ff ff       	call   80100348 <panic>
      kfree(mem);
8010695a:	83 ec 0c             	sub    $0xc,%esp
8010695d:	53                   	push   %ebx
8010695e:	e8 41 b6 ff ff       	call   80101fa4 <kfree>
      goto bad;
80106963:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106966:	83 ec 0c             	sub    $0xc,%esp
80106969:	ff 75 dc             	pushl  -0x24(%ebp)
8010696c:	e8 0c fe ff ff       	call   8010677d <freevm>
  return 0;
80106971:	83 c4 10             	add    $0x10,%esp
80106974:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
8010697b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010697e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106981:	5b                   	pop    %ebx
80106982:	5e                   	pop    %esi
80106983:	5f                   	pop    %edi
80106984:	5d                   	pop    %ebp
80106985:	c3                   	ret    

80106986 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106986:	55                   	push   %ebp
80106987:	89 e5                	mov    %esp,%ebp
80106989:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010698c:	b9 00 00 00 00       	mov    $0x0,%ecx
80106991:	8b 55 0c             	mov    0xc(%ebp),%edx
80106994:	8b 45 08             	mov    0x8(%ebp),%eax
80106997:	e8 00 f8 ff ff       	call   8010619c <walkpgdir>
  if((*pte & PTE_P) == 0)
8010699c:	8b 00                	mov    (%eax),%eax
8010699e:	a8 01                	test   $0x1,%al
801069a0:	74 10                	je     801069b2 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
801069a2:	a8 04                	test   $0x4,%al
801069a4:	74 13                	je     801069b9 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801069a6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801069ab:	05 00 00 00 80       	add    $0x80000000,%eax
}
801069b0:	c9                   	leave  
801069b1:	c3                   	ret    
    return 0;
801069b2:	b8 00 00 00 00       	mov    $0x0,%eax
801069b7:	eb f7                	jmp    801069b0 <uva2ka+0x2a>
    return 0;
801069b9:	b8 00 00 00 00       	mov    $0x0,%eax
801069be:	eb f0                	jmp    801069b0 <uva2ka+0x2a>

801069c0 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801069c0:	55                   	push   %ebp
801069c1:	89 e5                	mov    %esp,%ebp
801069c3:	57                   	push   %edi
801069c4:	56                   	push   %esi
801069c5:	53                   	push   %ebx
801069c6:	83 ec 0c             	sub    $0xc,%esp
801069c9:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801069cc:	eb 25                	jmp    801069f3 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801069ce:	8b 55 0c             	mov    0xc(%ebp),%edx
801069d1:	29 f2                	sub    %esi,%edx
801069d3:	01 d0                	add    %edx,%eax
801069d5:	83 ec 04             	sub    $0x4,%esp
801069d8:	53                   	push   %ebx
801069d9:	ff 75 10             	pushl  0x10(%ebp)
801069dc:	50                   	push   %eax
801069dd:	e8 47 d8 ff ff       	call   80104229 <memmove>
    len -= n;
801069e2:	29 df                	sub    %ebx,%edi
    buf += n;
801069e4:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801069e7:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801069ed:	89 45 0c             	mov    %eax,0xc(%ebp)
801069f0:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801069f3:	85 ff                	test   %edi,%edi
801069f5:	74 2f                	je     80106a26 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801069f7:	8b 75 0c             	mov    0xc(%ebp),%esi
801069fa:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
80106a00:	83 ec 08             	sub    $0x8,%esp
80106a03:	56                   	push   %esi
80106a04:	ff 75 08             	pushl  0x8(%ebp)
80106a07:	e8 7a ff ff ff       	call   80106986 <uva2ka>
    if(pa0 == 0)
80106a0c:	83 c4 10             	add    $0x10,%esp
80106a0f:	85 c0                	test   %eax,%eax
80106a11:	74 20                	je     80106a33 <copyout+0x73>
    n = PGSIZE - (va - va0);
80106a13:	89 f3                	mov    %esi,%ebx
80106a15:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106a18:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106a1e:	39 df                	cmp    %ebx,%edi
80106a20:	73 ac                	jae    801069ce <copyout+0xe>
      n = len;
80106a22:	89 fb                	mov    %edi,%ebx
80106a24:	eb a8                	jmp    801069ce <copyout+0xe>
  }
  return 0;
80106a26:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a2b:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106a2e:	5b                   	pop    %ebx
80106a2f:	5e                   	pop    %esi
80106a30:	5f                   	pop    %edi
80106a31:	5d                   	pop    %ebp
80106a32:	c3                   	ret    
      return -1;
80106a33:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a38:	eb f1                	jmp    80106a2b <copyout+0x6b>
