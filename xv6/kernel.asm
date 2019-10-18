
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
80100046:	e8 6f 40 00 00       	call   801040ba <acquire>

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
8010007c:	e8 9e 40 00 00       	call   8010411f <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 1a 3e 00 00       	call   80103ea6 <acquiresleep>
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
801000ca:	e8 50 40 00 00       	call   8010411f <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 cc 3d 00 00       	call   80103ea6 <acquiresleep>
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
801000ea:	68 20 6a 10 80       	push   $0x80106a20
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 31 6a 10 80       	push   $0x80106a31
80100100:	68 c0 b5 10 80       	push   $0x8010b5c0
80100105:	e8 74 3e 00 00       	call   80103f7e <initlock>
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
8010013a:	68 38 6a 10 80       	push   $0x80106a38
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 2b 3d 00 00       	call   80103e73 <initsleeplock>
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
801001a8:	e8 83 3d 00 00       	call   80103f30 <holdingsleep>
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
801001cb:	68 3f 6a 10 80       	push   $0x80106a3f
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
801001e4:	e8 47 3d 00 00       	call   80103f30 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 fc 3c 00 00       	call   80103ef5 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100200:	e8 b5 3e 00 00       	call   801040ba <acquire>
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
8010024c:	e8 ce 3e 00 00       	call   8010411f <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 46 6a 10 80       	push   $0x80106a46
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
8010028a:	e8 2b 3e 00 00       	call   801040ba <acquire>
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
801002bf:	e8 c3 34 00 00       	call   80103787 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 49 3e 00 00       	call   8010411f <release>
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
80100331:	e8 e9 3d 00 00       	call   8010411f <release>
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
80100363:	68 4d 6a 10 80       	push   $0x80106a4d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 42 70 10 80 	movl   $0x80107042,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 05 3c 00 00       	call   80103f99 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 61 6a 10 80       	push   $0x80106a61
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
8010049e:	68 65 6a 10 80       	push   $0x80106a65
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 22 3d 00 00       	call   801041e1 <memmove>
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
801004d9:	e8 88 3c 00 00       	call   80104166 <memset>
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
80100506:	e8 01 51 00 00       	call   8010560c <uartputc>
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
8010051f:	e8 e8 50 00 00       	call   8010560c <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 dc 50 00 00       	call   8010560c <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 d0 50 00 00       	call   8010560c <uartputc>
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
80100576:	0f b6 92 90 6a 10 80 	movzbl -0x7fef9570(%edx),%edx
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
801005ca:	e8 eb 3a 00 00       	call   801040ba <acquire>
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
801005f1:	e8 29 3b 00 00       	call   8010411f <release>
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
80100638:	e8 7d 3a 00 00       	call   801040ba <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 7f 6a 10 80       	push   $0x80106a7f
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
801006ee:	be 78 6a 10 80       	mov    $0x80106a78,%esi
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
80100734:	e8 e6 39 00 00       	call   8010411f <release>
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
8010074f:	e8 66 39 00 00       	call   801040ba <acquire>
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
801007de:	e8 0c 31 00 00       	call   801038ef <wakeup>
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
80100873:	e8 a7 38 00 00       	call   8010411f <release>
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
80100887:	e8 02 31 00 00       	call   8010398e <procdump>
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
80100894:	68 88 6a 10 80       	push   $0x80106a88
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 db 36 00 00       	call   80103f7e <initlock>

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
80100952:	68 a1 6a 10 80       	push   $0x80106aa1
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
80100972:	e8 55 5e 00 00       	call   801067cc <setupkvm>
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
80100a06:	e8 67 5c 00 00       	call   80106672 <allocuvm>
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
80100a38:	e8 03 5b 00 00       	call   80106540 <loaduvm>
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
80100a74:	e8 f9 5b 00 00       	call   80106672 <allocuvm>
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
80100a9d:	e8 ba 5c 00 00       	call   8010675c <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 90 5d 00 00       	call   80106851 <clearpteu>
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
80100ae2:	e8 21 38 00 00       	call   80104308 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 0f 38 00 00       	call   80104308 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 94 5e 00 00       	call   8010699f <copyout>
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
80100b66:	e8 34 5e 00 00       	call   8010699f <copyout>
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
80100ba3:	e8 25 37 00 00       	call   801042cd <safestrcpy>
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
80100bd1:	e8 e9 57 00 00       	call   801063bf <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 7e 5b 00 00       	call   8010675c <freevm>
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
80100c19:	68 ad 6a 10 80       	push   $0x80106aad
80100c1e:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c23:	e8 56 33 00 00       	call   80103f7e <initlock>
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
80100c39:	e8 7c 34 00 00       	call   801040ba <acquire>
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
80100c68:	e8 b2 34 00 00       	call   8010411f <release>
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
80100c7f:	e8 9b 34 00 00       	call   8010411f <release>
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
80100c9d:	e8 18 34 00 00       	call   801040ba <acquire>
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
80100cba:	e8 60 34 00 00       	call   8010411f <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 b4 6a 10 80       	push   $0x80106ab4
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
80100ce2:	e8 d3 33 00 00       	call   801040ba <acquire>
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
80100d03:	e8 17 34 00 00       	call   8010411f <release>
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
80100d13:	68 bc 6a 10 80       	push   $0x80106abc
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
80100d49:	e8 d1 33 00 00       	call   8010411f <release>
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
80100e4b:	68 c6 6a 10 80       	push   $0x80106ac6
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
80100f10:	68 cf 6a 10 80       	push   $0x80106acf
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
80100f2d:	68 d5 6a 10 80       	push   $0x80106ad5
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
80100f8a:	e8 52 32 00 00       	call   801041e1 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 42 32 00 00       	call   801041e1 <memmove>
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
80100fdf:	e8 82 31 00 00       	call   80104166 <memset>
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
801010a3:	68 df 6a 10 80       	push   $0x80106adf
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
8010117d:	68 f5 6a 10 80       	push   $0x80106af5
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
8010119a:	e8 1b 2f 00 00       	call   801040ba <acquire>
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
801011e1:	e8 39 2f 00 00       	call   8010411f <release>
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
80101217:	e8 03 2f 00 00       	call   8010411f <release>
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
8010122c:	68 08 6b 10 80       	push   $0x80106b08
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
80101255:	e8 87 2f 00 00       	call   801041e1 <memmove>
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
801012e2:	68 18 6b 10 80       	push   $0x80106b18
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 2b 6b 10 80       	push   $0x80106b2b
801012f8:	68 e0 09 11 80       	push   $0x801109e0
801012fd:	e8 7c 2c 00 00       	call   80103f7e <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 32 6b 10 80       	push   $0x80106b32
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 20 0a 11 80       	add    $0x80110a20,%eax
80101321:	50                   	push   %eax
80101322:	e8 4c 2b 00 00       	call   80103e73 <initsleeplock>
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
8010136c:	68 98 6b 10 80       	push   $0x80106b98
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
801013df:	68 38 6b 10 80       	push   $0x80106b38
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 70 2d 00 00       	call   80104166 <memset>
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
80101480:	e8 5c 2d 00 00       	call   801041e1 <memmove>
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
80101560:	e8 55 2b 00 00       	call   801040ba <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101575:	e8 a5 2b 00 00       	call   8010411f <release>
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
8010159a:	e8 07 29 00 00       	call   80103ea6 <acquiresleep>
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
801015b2:	68 4a 6b 10 80       	push   $0x80106b4a
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
80101614:	e8 c8 2b 00 00       	call   801041e1 <memmove>
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
80101639:	68 50 6b 10 80       	push   $0x80106b50
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
80101656:	e8 d5 28 00 00       	call   80103f30 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 84 28 00 00       	call   80103ef5 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 5f 6b 10 80       	push   $0x80106b5f
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
80101698:	e8 09 28 00 00       	call   80103ea6 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 3f 28 00 00       	call   80103ef5 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016bd:	e8 f8 29 00 00       	call   801040ba <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016d2:	e8 48 2a 00 00       	call   8010411f <release>
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
801016ea:	e8 cb 29 00 00       	call   801040ba <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016f9:	e8 21 2a 00 00       	call   8010411f <release>
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
8010182a:	e8 b2 29 00 00       	call   801041e1 <memmove>
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
80101926:	e8 b6 28 00 00       	call   801041e1 <memmove>
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
801019a9:	e8 9a 28 00 00       	call   80104248 <strncmp>
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
801019d0:	68 67 6b 10 80       	push   $0x80106b67
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 79 6b 10 80       	push   $0x80106b79
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
80101b92:	68 88 6b 10 80       	push   $0x80106b88
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 d7 26 00 00       	call   80104285 <strncpy>
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
80101bd7:	68 c0 71 10 80       	push   $0x801071c0
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
80101ccc:	68 eb 6b 10 80       	push   $0x80106beb
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 f4 6b 10 80       	push   $0x80106bf4
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
80101d06:	68 06 6c 10 80       	push   $0x80106c06
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 69 22 00 00       	call   80103f7e <initlock>
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
80101d80:	e8 35 23 00 00       	call   801040ba <acquire>

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
80101dad:	e8 3d 1b 00 00       	call   801038ef <wakeup>

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
80101dcb:	e8 4f 23 00 00       	call   8010411f <release>
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
80101de2:	e8 38 23 00 00       	call   8010411f <release>
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
80101e1a:	e8 11 21 00 00       	call   80103f30 <holdingsleep>
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
80101e47:	e8 6e 22 00 00       	call   801040ba <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 0a 6c 10 80       	push   $0x80106c0a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 20 6c 10 80       	push   $0x80106c20
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 35 6c 10 80       	push   $0x80106c35
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
80101ea9:	e8 d9 18 00 00       	call   80103787 <sleep>
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
80101ec3:	e8 57 22 00 00       	call   8010411f <release>
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
80101f3f:	68 54 6c 10 80       	push   $0x80106c54
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
80101fd6:	e8 8b 21 00 00       	call   80104166 <memset>

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
80102005:	68 86 6c 10 80       	push   $0x80106c86
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 40 26 11 80       	push   $0x80112640
80102017:	e8 9e 20 00 00       	call   801040ba <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 40 26 11 80       	push   $0x80112640
80102029:	e8 f1 20 00 00       	call   8010411f <release>
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
8010206f:	68 8c 6c 10 80       	push   $0x80106c8c
80102074:	68 40 26 11 80       	push   $0x80112640
80102079:	e8 00 1f 00 00       	call   80103f7e <initlock>
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
801020f4:	e8 c1 1f 00 00       	call   801040ba <acquire>
801020f9:	83 c4 10             	add    $0x10,%esp
801020fc:	eb cd                	jmp    801020cb <kalloc+0x10>
    release(&kmem.lock);
801020fe:	83 ec 0c             	sub    $0xc,%esp
80102101:	68 40 26 11 80       	push   $0x80112640
80102106:	e8 14 20 00 00       	call   8010411f <release>
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
80102150:	0f b6 8a c0 6d 10 80 	movzbl -0x7fef9240(%edx),%ecx
80102157:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
8010215d:	0f b6 82 c0 6c 10 80 	movzbl -0x7fef9340(%edx),%eax
80102164:	31 c1                	xor    %eax,%ecx
80102166:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
8010216c:	89 c8                	mov    %ecx,%eax
8010216e:	83 e0 03             	and    $0x3,%eax
80102171:	8b 04 85 a0 6c 10 80 	mov    -0x7fef9360(,%eax,4),%eax
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
801021ac:	0f b6 82 c0 6d 10 80 	movzbl -0x7fef9240(%edx),%eax
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
80102497:	e8 10 1d 00 00       	call   801041ac <memcmp>
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
80102602:	e8 da 1b 00 00       	call   801041e1 <memmove>
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
80102701:	e8 db 1a 00 00       	call   801041e1 <memmove>
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
8010276f:	68 c0 6e 10 80       	push   $0x80106ec0
80102774:	68 80 26 11 80       	push   $0x80112680
80102779:	e8 00 18 00 00       	call   80103f7e <initlock>
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
801027b9:	e8 fc 18 00 00       	call   801040ba <acquire>
801027be:	83 c4 10             	add    $0x10,%esp
801027c1:	eb 15                	jmp    801027d8 <begin_op+0x2a>
      sleep(&log, &log.lock);
801027c3:	83 ec 08             	sub    $0x8,%esp
801027c6:	68 80 26 11 80       	push   $0x80112680
801027cb:	68 80 26 11 80       	push   $0x80112680
801027d0:	e8 b2 0f 00 00       	call   80103787 <sleep>
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
80102807:	e8 7b 0f 00 00       	call   80103787 <sleep>
8010280c:	83 c4 10             	add    $0x10,%esp
8010280f:	eb c7                	jmp    801027d8 <begin_op+0x2a>
      log.outstanding += 1;
80102811:	a3 bc 26 11 80       	mov    %eax,0x801126bc
      release(&log.lock);
80102816:	83 ec 0c             	sub    $0xc,%esp
80102819:	68 80 26 11 80       	push   $0x80112680
8010281e:	e8 fc 18 00 00       	call   8010411f <release>
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
80102834:	e8 81 18 00 00       	call   801040ba <acquire>
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
8010286e:	e8 ac 18 00 00       	call   8010411f <release>
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
80102882:	68 c4 6e 10 80       	push   $0x80106ec4
80102887:	e8 bc da ff ff       	call   80100348 <panic>
    wakeup(&log);
8010288c:	83 ec 0c             	sub    $0xc,%esp
8010288f:	68 80 26 11 80       	push   $0x80112680
80102894:	e8 56 10 00 00       	call   801038ef <wakeup>
80102899:	83 c4 10             	add    $0x10,%esp
8010289c:	eb c8                	jmp    80102866 <end_op+0x3e>
    commit();
8010289e:	e8 91 fe ff ff       	call   80102734 <commit>
    acquire(&log.lock);
801028a3:	83 ec 0c             	sub    $0xc,%esp
801028a6:	68 80 26 11 80       	push   $0x80112680
801028ab:	e8 0a 18 00 00       	call   801040ba <acquire>
    log.committing = 0;
801028b0:	c7 05 c0 26 11 80 00 	movl   $0x0,0x801126c0
801028b7:	00 00 00 
    wakeup(&log);
801028ba:	c7 04 24 80 26 11 80 	movl   $0x80112680,(%esp)
801028c1:	e8 29 10 00 00       	call   801038ef <wakeup>
    release(&log.lock);
801028c6:	c7 04 24 80 26 11 80 	movl   $0x80112680,(%esp)
801028cd:	e8 4d 18 00 00       	call   8010411f <release>
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
80102909:	e8 ac 17 00 00       	call   801040ba <acquire>
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
80102934:	68 d3 6e 10 80       	push   $0x80106ed3
80102939:	e8 0a da ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
8010293e:	83 ec 0c             	sub    $0xc,%esp
80102941:	68 e9 6e 10 80       	push   $0x80106ee9
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
80102964:	e8 b6 17 00 00       	call   8010411f <release>
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
80102992:	e8 4a 18 00 00       	call   801041e1 <memmove>

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
80102a23:	68 04 6f 10 80       	push   $0x80106f04
80102a28:	e8 de db ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102a2d:	e8 72 29 00 00       	call   801053a4 <idtinit>
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
80102a45:	e8 c6 09 00 00       	call   80103410 <scheduler>

80102a4a <mpenter>:
{
80102a4a:	55                   	push   %ebp
80102a4b:	89 e5                	mov    %esp,%ebp
80102a4d:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102a50:	e8 58 39 00 00       	call   801063ad <switchkvm>
  seginit();
80102a55:	e8 07 38 00 00       	call   80106261 <seginit>
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
80102a84:	e8 b1 3d 00 00       	call   8010683a <kvmalloc>
  mpinit();        // detect other processors
80102a89:	e8 c9 01 00 00       	call   80102c57 <mpinit>
  lapicinit();     // interrupt controller
80102a8e:	e8 e1 f7 ff ff       	call   80102274 <lapicinit>
  seginit();       // segment descriptors
80102a93:	e8 c9 37 00 00       	call   80106261 <seginit>
  picinit();       // disable pic
80102a98:	e8 82 02 00 00       	call   80102d1f <picinit>
  ioapicinit();    // another interrupt controller
80102a9d:	e8 58 f4 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102aa2:	e8 e7 dd ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102aa7:	e8 a6 2b 00 00       	call   80105652 <uartinit>
  pinit();         // process table
80102aac:	e8 ef 06 00 00       	call   801031a0 <pinit>
  tvinit();        // trap vectors
80102ab1:	e8 3d 28 00 00       	call   801052f3 <tvinit>
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
80102b27:	68 18 6f 10 80       	push   $0x80106f18
80102b2c:	53                   	push   %ebx
80102b2d:	e8 7a 16 00 00       	call   801041ac <memcmp>
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
80102bec:	68 1d 6f 10 80       	push   $0x80106f1d
80102bf1:	56                   	push   %esi
80102bf2:	e8 b5 15 00 00       	call   801041ac <memcmp>
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
80102c88:	68 22 6f 10 80       	push   $0x80106f22
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
80102cc7:	ff 24 85 5c 6f 10 80 	jmp    *-0x7fef90a4(,%eax,4)
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
80102d15:	68 3c 6f 10 80       	push   $0x80106f3c
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
80102dd1:	68 70 6f 10 80       	push   $0x80106f70
80102dd6:	50                   	push   %eax
80102dd7:	e8 a2 11 00 00       	call   80103f7e <initlock>
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
80102e2d:	e8 88 12 00 00       	call   801040ba <acquire>
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
80102e4f:	e8 9b 0a 00 00       	call   801038ef <wakeup>
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
80102e6d:	e8 ad 12 00 00       	call   8010411f <release>
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
80102e8e:	e8 5c 0a 00 00       	call   801038ef <wakeup>
80102e93:	83 c4 10             	add    $0x10,%esp
80102e96:	eb bf                	jmp    80102e57 <pipeclose+0x35>
    release(&p->lock);
80102e98:	83 ec 0c             	sub    $0xc,%esp
80102e9b:	53                   	push   %ebx
80102e9c:	e8 7e 12 00 00       	call   8010411f <release>
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
80102ebd:	e8 f8 11 00 00       	call   801040ba <acquire>
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
80102f06:	e8 e4 09 00 00       	call   801038ef <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80102f0b:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f11:	83 c4 08             	add    $0x8,%esp
80102f14:	56                   	push   %esi
80102f15:	50                   	push   %eax
80102f16:	e8 6c 08 00 00       	call   80103787 <sleep>
80102f1b:	83 c4 10             	add    $0x10,%esp
80102f1e:	eb b3                	jmp    80102ed3 <pipewrite+0x25>
        release(&p->lock);
80102f20:	83 ec 0c             	sub    $0xc,%esp
80102f23:	53                   	push   %ebx
80102f24:	e8 f6 11 00 00       	call   8010411f <release>
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
80102f65:	e8 85 09 00 00       	call   801038ef <wakeup>
  release(&p->lock);
80102f6a:	89 1c 24             	mov    %ebx,(%esp)
80102f6d:	e8 ad 11 00 00       	call   8010411f <release>
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
80102f89:	e8 2c 11 00 00       	call   801040ba <acquire>
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
80102fbf:	e8 c3 07 00 00       	call   80103787 <sleep>
80102fc4:	83 c4 10             	add    $0x10,%esp
80102fc7:	eb c8                	jmp    80102f91 <piperead+0x17>
      release(&p->lock);
80102fc9:	83 ec 0c             	sub    $0xc,%esp
80102fcc:	53                   	push   %ebx
80102fcd:	e8 4d 11 00 00       	call   8010411f <release>
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
8010301c:	e8 ce 08 00 00       	call   801038ef <wakeup>
  release(&p->lock);
80103021:	89 1c 24             	mov    %ebx,(%esp)
80103024:	e8 f6 10 00 00       	call   8010411f <release>
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
80103039:	ba 74 39 11 80       	mov    $0x80113974,%edx
8010303e:	eb 06                	jmp    80103046 <wakeup1+0x10>
80103040:	81 c2 a8 00 00 00    	add    $0xa8,%edx
80103046:	81 fa 74 63 11 80    	cmp    $0x80116374,%edx
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
8010306b:	68 40 39 11 80       	push   $0x80113940
80103070:	e8 45 10 00 00       	call   801040ba <acquire>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103075:	83 c4 10             	add    $0x10,%esp
80103078:	bb 74 39 11 80       	mov    $0x80113974,%ebx
8010307d:	81 fb 74 63 11 80    	cmp    $0x80116374,%ebx
80103083:	73 0e                	jae    80103093 <allocproc+0x2f>
        if (p->state == UNUSED)
80103085:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103089:	74 22                	je     801030ad <allocproc+0x49>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010308b:	81 c3 a8 00 00 00    	add    $0xa8,%ebx
80103091:	eb ea                	jmp    8010307d <allocproc+0x19>
    release(&ptable.lock);
80103093:	83 ec 0c             	sub    $0xc,%esp
80103096:	68 40 39 11 80       	push   $0x80113940
8010309b:	e8 7f 10 00 00       	call   8010411f <release>
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
801030fa:	68 40 39 11 80       	push   $0x80113940
801030ff:	e8 1b 10 00 00       	call   8010411f <release>
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
8010311c:	c7 80 b0 0f 00 00 e8 	movl   $0x801052e8,0xfb0(%eax)
80103123:	52 10 80 
        sp -= sizeof *p->context;
80103126:	05 9c 0f 00 00       	add    $0xf9c,%eax
        p->context = (struct context *) sp;
8010312b:	89 43 1c             	mov    %eax,0x1c(%ebx)
        memset(p->context, 0, sizeof *p->context);
8010312e:	83 ec 04             	sub    $0x4,%esp
80103131:	6a 14                	push   $0x14
80103133:	6a 00                	push   $0x0
80103135:	50                   	push   %eax
80103136:	e8 2b 10 00 00       	call   80104166 <memset>
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
80103163:	68 40 39 11 80       	push   $0x80113940
80103168:	e8 b2 0f 00 00       	call   8010411f <release>
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
801031a6:	68 75 6f 10 80       	push   $0x80106f75
801031ab:	68 40 39 11 80       	push   $0x80113940
801031b0:	e8 c9 0d 00 00       	call   80103f7e <initlock>
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
801031f2:	68 80 70 10 80       	push   $0x80107080
801031f7:	e8 4c d1 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801031fc:	83 ec 0c             	sub    $0xc,%esp
801031ff:	68 7c 6f 10 80       	push   $0x80106f7c
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
80103238:	e8 a0 0d 00 00       	call   80103fdd <pushcli>
  c = mycpu();
8010323d:	e8 78 ff ff ff       	call   801031ba <mycpu>
  p = c->proc;
80103242:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103248:	e8 cd 0d 00 00       	call   8010401a <popcli>
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
80103268:	e8 5f 35 00 00       	call   801067cc <setupkvm>
8010326d:	89 43 04             	mov    %eax,0x4(%ebx)
80103270:	85 c0                	test   %eax,%eax
80103272:	0f 84 d5 00 00 00    	je     8010334d <userinit+0xf8>
    inituvm(p->pgdir, _binary_initcode_start, (int) _binary_initcode_size);
80103278:	83 ec 04             	sub    $0x4,%esp
8010327b:	68 2c 00 00 00       	push   $0x2c
80103280:	68 60 a4 10 80       	push   $0x8010a460
80103285:	50                   	push   %eax
80103286:	e8 4c 32 00 00       	call   801064d7 <inituvm>
    p->sz = PGSIZE;
8010328b:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
    memset(p->tf, 0, sizeof(*p->tf));
80103291:	83 c4 0c             	add    $0xc,%esp
80103294:	6a 4c                	push   $0x4c
80103296:	6a 00                	push   $0x0
80103298:	ff 73 18             	pushl  0x18(%ebx)
8010329b:	e8 c6 0e 00 00       	call   80104166 <memset>
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
801032ee:	68 a5 6f 10 80       	push   $0x80106fa5
801032f3:	50                   	push   %eax
801032f4:	e8 d4 0f 00 00       	call   801042cd <safestrcpy>
    p->cwd = namei("/");
801032f9:	c7 04 24 ae 6f 10 80 	movl   $0x80106fae,(%esp)
80103300:	e8 dc e8 ff ff       	call   80101be1 <namei>
80103305:	89 43 68             	mov    %eax,0x68(%ebx)
    acquire(&ptable.lock);
80103308:	c7 04 24 40 39 11 80 	movl   $0x80113940,(%esp)
8010330f:	e8 a6 0d 00 00       	call   801040ba <acquire>
    p->state = RUNNABLE;
80103314:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
    p->priority = 3;
8010331b:	c7 43 7c 03 00 00 00 	movl   $0x3,0x7c(%ebx)
    if (priorityQueue[p->priority].head == NULL && priorityQueue[p->priority].tail == NULL) {
80103322:	83 c4 10             	add    $0x10,%esp
80103325:	83 3d 38 39 11 80 00 	cmpl   $0x0,0x80113938
8010332c:	74 2c                	je     8010335a <userinit+0x105>
    p->next = NULL;
8010332e:	c7 83 80 00 00 00 00 	movl   $0x0,0x80(%ebx)
80103335:	00 00 00 
    release(&ptable.lock);
80103338:	83 ec 0c             	sub    $0xc,%esp
8010333b:	68 40 39 11 80       	push   $0x80113940
80103340:	e8 da 0d 00 00       	call   8010411f <release>
}
80103345:	83 c4 10             	add    $0x10,%esp
80103348:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010334b:	c9                   	leave  
8010334c:	c3                   	ret    
        panic("userinit: out of memory?");
8010334d:	83 ec 0c             	sub    $0xc,%esp
80103350:	68 8c 6f 10 80       	push   $0x80106f8c
80103355:	e8 ee cf ff ff       	call   80100348 <panic>
    if (priorityQueue[p->priority].head == NULL && priorityQueue[p->priority].tail == NULL) {
8010335a:	83 3d 3c 39 11 80 00 	cmpl   $0x0,0x8011393c
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
80103395:	89 1d 38 39 11 80    	mov    %ebx,0x80113938
        priorityQueue[p->priority].tail = p;
8010339b:	89 1d 3c 39 11 80    	mov    %ebx,0x8011393c
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
801033c6:	e8 15 32 00 00       	call   801065e0 <deallocuvm>
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
801033e3:	e8 8a 32 00 00       	call   80106672 <allocuvm>
801033e8:	83 c4 10             	add    $0x10,%esp
801033eb:	85 c0                	test   %eax,%eax
801033ed:	74 1a                	je     80103409 <growproc+0x66>
  curproc->sz = sz;
801033ef:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801033f1:	83 ec 0c             	sub    $0xc,%esp
801033f4:	53                   	push   %ebx
801033f5:	e8 c5 2f 00 00       	call   801063bf <switchuvm>
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

80103410 <scheduler>:
{
80103410:	55                   	push   %ebp
80103411:	89 e5                	mov    %esp,%ebp
80103413:	57                   	push   %edi
80103414:	56                   	push   %esi
80103415:	53                   	push   %ebx
80103416:	83 ec 1c             	sub    $0x1c,%esp
    struct cpu *c = mycpu();
80103419:	e8 9c fd ff ff       	call   801031ba <mycpu>
8010341e:	89 45 e0             	mov    %eax,-0x20(%ebp)
    c->proc = 0;
80103421:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80103428:	00 00 00 
8010342b:	e9 9e 01 00 00       	jmp    801035ce <scheduler+0x1be>
                    c->proc = p;
80103430:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103433:	89 98 ac 00 00 00    	mov    %ebx,0xac(%eax)
                    switchuvm(p);
80103439:	83 ec 0c             	sub    $0xc,%esp
8010343c:	53                   	push   %ebx
8010343d:	e8 7d 2f 00 00       	call   801063bf <switchuvm>
                    p->state = RUNNING;
80103442:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
                    swtch(&(c->scheduler), p->context);
80103449:	83 c4 08             	add    $0x8,%esp
8010344c:	ff 73 1c             	pushl  0x1c(%ebx)
8010344f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103452:	83 c0 04             	add    $0x4,%eax
80103455:	50                   	push   %eax
80103456:	e8 c5 0e 00 00       	call   80104320 <swtch>
                    switchkvm();
8010345b:	e8 4d 2f 00 00       	call   801063ad <switchkvm>
                    p->ticks++;
80103460:	8b 83 84 00 00 00    	mov    0x84(%ebx),%eax
80103466:	83 c0 01             	add    $0x1,%eax
80103469:	89 83 84 00 00 00    	mov    %eax,0x84(%ebx)
                    p->agg_ticks[priority]++;
8010346f:	8d 4e 20             	lea    0x20(%esi),%ecx
80103472:	8b 54 8b 08          	mov    0x8(%ebx,%ecx,4),%edx
80103476:	83 c2 01             	add    $0x1,%edx
80103479:	89 54 8b 08          	mov    %edx,0x8(%ebx,%ecx,4)
                    if (p->ticks >= timeslices[priority] && priority == 3) {
8010347d:	83 c4 10             	add    $0x10,%esp
80103480:	3b 04 b5 08 a0 10 80 	cmp    -0x7fef5ff8(,%esi,4),%eax
80103487:	7c 05                	jl     8010348e <scheduler+0x7e>
80103489:	83 fe 03             	cmp    $0x3,%esi
8010348c:	74 2b                	je     801034b9 <scheduler+0xa9>
                    c->proc = 0;
8010348e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103491:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80103498:	00 00 00 
        for (i = 3; i >= 0; i--) {
8010349b:	83 ef 01             	sub    $0x1,%edi
8010349e:	85 ff                	test   %edi,%edi
801034a0:	0f 88 18 01 00 00    	js     801035be <scheduler+0x1ae>
            for (p = priorityQueue[i].head; p != NULL;) {
801034a6:	8b 1c fd 20 39 11 80 	mov    -0x7feec6e0(,%edi,8),%ebx
            struct proc *prevProc = NULL;
801034ad:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
            for (p = priorityQueue[i].head; p != NULL;) {
801034b4:	e9 b6 00 00 00       	jmp    8010356f <scheduler+0x15f>
                        if (priorityQueue[i].head == priorityQueue[i].tail) {
801034b9:	8b 04 fd 20 39 11 80 	mov    -0x7feec6e0(,%edi,8),%eax
801034c0:	3b 04 fd 24 39 11 80 	cmp    -0x7feec6dc(,%edi,8),%eax
801034c7:	74 1c                	je     801034e5 <scheduler+0xd5>
                        } else if (priorityQueue[i].head == p) {
801034c9:	39 d8                	cmp    %ebx,%eax
801034cb:	74 45                	je     80103512 <scheduler+0x102>
                            prevProc->next = p->next;
801034cd:	8b 83 80 00 00 00    	mov    0x80(%ebx),%eax
801034d3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801034d6:	89 81 80 00 00 00    	mov    %eax,0x80(%ecx)
                            if (priorityQueue[priority].tail == p) {
801034dc:	39 1c f5 24 39 11 80 	cmp    %ebx,-0x7feec6dc(,%esi,8)
801034e3:	74 3c                	je     80103521 <scheduler+0x111>
                        priorityQueue[priority].tail->next = p;
801034e5:	8b 04 f5 24 39 11 80 	mov    -0x7feec6dc(,%esi,8),%eax
801034ec:	89 98 80 00 00 00    	mov    %ebx,0x80(%eax)
                        priorityQueue[priority].tail = p;
801034f2:	89 1c f5 24 39 11 80 	mov    %ebx,-0x7feec6dc(,%esi,8)
                        p->ticks = 0;
801034f9:	c7 83 84 00 00 00 00 	movl   $0x0,0x84(%ebx)
80103500:	00 00 00 
                        p->next = NULL;
80103503:	c7 83 80 00 00 00 00 	movl   $0x0,0x80(%ebx)
8010350a:	00 00 00 
8010350d:	e9 7c ff ff ff       	jmp    8010348e <scheduler+0x7e>
                            priorityQueue[i].head = p->next;
80103512:	8b 83 80 00 00 00    	mov    0x80(%ebx),%eax
80103518:	89 04 fd 20 39 11 80 	mov    %eax,-0x7feec6e0(,%edi,8)
8010351f:	eb c4                	jmp    801034e5 <scheduler+0xd5>
                                priorityQueue[priority].tail = prevProc;
80103521:	89 0c f5 24 39 11 80 	mov    %ecx,-0x7feec6dc(,%esi,8)
80103528:	eb bb                	jmp    801034e5 <scheduler+0xd5>
                        priorityQueue[i].head = NULL;
8010352a:	c7 04 fd 20 39 11 80 	movl   $0x0,-0x7feec6e0(,%edi,8)
80103531:	00 00 00 00 
                        priorityQueue[i].tail = NULL;
80103535:	c7 04 fd 24 39 11 80 	movl   $0x0,-0x7feec6dc(,%edi,8)
8010353c:	00 00 00 00 
                        break;
80103540:	e9 56 ff ff ff       	jmp    8010349b <scheduler+0x8b>
                       priorityQueue[i].head = priorityQueue[i].head->next;
80103545:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
8010354b:	89 04 fd 20 39 11 80 	mov    %eax,-0x7feec6e0(,%edi,8)
                       p = p->next;
80103552:	8b 9b 80 00 00 00    	mov    0x80(%ebx),%ebx
80103558:	eb 15                	jmp    8010356f <scheduler+0x15f>
                            priorityQueue[priority].tail = prevProc;
8010355a:	89 14 f5 24 39 11 80 	mov    %edx,-0x7feec6dc(,%esi,8)
                            break;
80103561:	e9 35 ff ff ff       	jmp    8010349b <scheduler+0x8b>
                    prevProc = p;
80103566:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
                    p = p->next;
80103569:	8b 9b 80 00 00 00    	mov    0x80(%ebx),%ebx
            for (p = priorityQueue[i].head; p != NULL;) {
8010356f:	85 db                	test   %ebx,%ebx
80103571:	0f 84 24 ff ff ff    	je     8010349b <scheduler+0x8b>
                int priority = p->priority;
80103577:	8b 73 7c             	mov    0x7c(%ebx),%esi
                if (p->state == RUNNABLE) {
8010357a:	8b 43 0c             	mov    0xc(%ebx),%eax
8010357d:	83 f8 03             	cmp    $0x3,%eax
80103580:	0f 84 aa fe ff ff    	je     80103430 <scheduler+0x20>
                } else if (p->state == UNUSED){
80103586:	85 c0                	test   %eax,%eax
80103588:	75 dc                	jne    80103566 <scheduler+0x156>
                    if (priorityQueue[i].head == priorityQueue[i].tail) {
8010358a:	8b 04 fd 20 39 11 80 	mov    -0x7feec6e0(,%edi,8),%eax
80103591:	3b 04 fd 24 39 11 80 	cmp    -0x7feec6dc(,%edi,8),%eax
80103598:	74 90                	je     8010352a <scheduler+0x11a>
                    } else if (p == priorityQueue[i].head){
8010359a:	39 d8                	cmp    %ebx,%eax
8010359c:	74 a7                	je     80103545 <scheduler+0x135>
                        prevProc->next = p->next;
8010359e:	8b 83 80 00 00 00    	mov    0x80(%ebx),%eax
801035a4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801035a7:	89 82 80 00 00 00    	mov    %eax,0x80(%edx)
                        if (priorityQueue[priority].tail == p) {
801035ad:	39 1c f5 24 39 11 80 	cmp    %ebx,-0x7feec6dc(,%esi,8)
801035b4:	74 a4                	je     8010355a <scheduler+0x14a>
                        p = p->next;
801035b6:	8b 9b 80 00 00 00    	mov    0x80(%ebx),%ebx
801035bc:	eb b1                	jmp    8010356f <scheduler+0x15f>
    release(&ptable.lock);
801035be:	83 ec 0c             	sub    $0xc,%esp
801035c1:	68 40 39 11 80       	push   $0x80113940
801035c6:	e8 54 0b 00 00       	call   8010411f <release>
    for (;;) {
801035cb:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
801035ce:	fb                   	sti    
        acquire(&ptable.lock);
801035cf:	83 ec 0c             	sub    $0xc,%esp
801035d2:	68 40 39 11 80       	push   $0x80113940
801035d7:	e8 de 0a 00 00       	call   801040ba <acquire>
        for (i = 3; i >= 0; i--) {
801035dc:	83 c4 10             	add    $0x10,%esp
801035df:	bf 03 00 00 00       	mov    $0x3,%edi
801035e4:	e9 b5 fe ff ff       	jmp    8010349e <scheduler+0x8e>

801035e9 <sched>:
{
801035e9:	55                   	push   %ebp
801035ea:	89 e5                	mov    %esp,%ebp
801035ec:	56                   	push   %esi
801035ed:	53                   	push   %ebx
  struct proc *p = myproc();
801035ee:	e8 3e fc ff ff       	call   80103231 <myproc>
801035f3:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
801035f5:	83 ec 0c             	sub    $0xc,%esp
801035f8:	68 40 39 11 80       	push   $0x80113940
801035fd:	e8 78 0a 00 00       	call   8010407a <holding>
80103602:	83 c4 10             	add    $0x10,%esp
80103605:	85 c0                	test   %eax,%eax
80103607:	74 4f                	je     80103658 <sched+0x6f>
  if(mycpu()->ncli != 1)
80103609:	e8 ac fb ff ff       	call   801031ba <mycpu>
8010360e:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103615:	75 4e                	jne    80103665 <sched+0x7c>
  if(p->state == RUNNING)
80103617:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
8010361b:	74 55                	je     80103672 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010361d:	9c                   	pushf  
8010361e:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010361f:	f6 c4 02             	test   $0x2,%ah
80103622:	75 5b                	jne    8010367f <sched+0x96>
  intena = mycpu()->intena;
80103624:	e8 91 fb ff ff       	call   801031ba <mycpu>
80103629:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
8010362f:	e8 86 fb ff ff       	call   801031ba <mycpu>
80103634:	83 ec 08             	sub    $0x8,%esp
80103637:	ff 70 04             	pushl  0x4(%eax)
8010363a:	83 c3 1c             	add    $0x1c,%ebx
8010363d:	53                   	push   %ebx
8010363e:	e8 dd 0c 00 00       	call   80104320 <swtch>
  mycpu()->intena = intena;
80103643:	e8 72 fb ff ff       	call   801031ba <mycpu>
80103648:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
8010364e:	83 c4 10             	add    $0x10,%esp
80103651:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103654:	5b                   	pop    %ebx
80103655:	5e                   	pop    %esi
80103656:	5d                   	pop    %ebp
80103657:	c3                   	ret    
    panic("sched ptable.lock");
80103658:	83 ec 0c             	sub    $0xc,%esp
8010365b:	68 b0 6f 10 80       	push   $0x80106fb0
80103660:	e8 e3 cc ff ff       	call   80100348 <panic>
    panic("sched locks");
80103665:	83 ec 0c             	sub    $0xc,%esp
80103668:	68 c2 6f 10 80       	push   $0x80106fc2
8010366d:	e8 d6 cc ff ff       	call   80100348 <panic>
    panic("sched running");
80103672:	83 ec 0c             	sub    $0xc,%esp
80103675:	68 ce 6f 10 80       	push   $0x80106fce
8010367a:	e8 c9 cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
8010367f:	83 ec 0c             	sub    $0xc,%esp
80103682:	68 dc 6f 10 80       	push   $0x80106fdc
80103687:	e8 bc cc ff ff       	call   80100348 <panic>

8010368c <exit>:
{
8010368c:	55                   	push   %ebp
8010368d:	89 e5                	mov    %esp,%ebp
8010368f:	56                   	push   %esi
80103690:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103691:	e8 9b fb ff ff       	call   80103231 <myproc>
  if(curproc == initproc)
80103696:	39 05 b8 a5 10 80    	cmp    %eax,0x8010a5b8
8010369c:	74 09                	je     801036a7 <exit+0x1b>
8010369e:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
801036a0:	bb 00 00 00 00       	mov    $0x0,%ebx
801036a5:	eb 10                	jmp    801036b7 <exit+0x2b>
    panic("init exiting");
801036a7:	83 ec 0c             	sub    $0xc,%esp
801036aa:	68 f0 6f 10 80       	push   $0x80106ff0
801036af:	e8 94 cc ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
801036b4:	83 c3 01             	add    $0x1,%ebx
801036b7:	83 fb 0f             	cmp    $0xf,%ebx
801036ba:	7f 1e                	jg     801036da <exit+0x4e>
    if(curproc->ofile[fd]){
801036bc:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801036c0:	85 c0                	test   %eax,%eax
801036c2:	74 f0                	je     801036b4 <exit+0x28>
      fileclose(curproc->ofile[fd]);
801036c4:	83 ec 0c             	sub    $0xc,%esp
801036c7:	50                   	push   %eax
801036c8:	e8 06 d6 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
801036cd:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
801036d4:	00 
801036d5:	83 c4 10             	add    $0x10,%esp
801036d8:	eb da                	jmp    801036b4 <exit+0x28>
  begin_op();
801036da:	e8 cf f0 ff ff       	call   801027ae <begin_op>
  iput(curproc->cwd);
801036df:	83 ec 0c             	sub    $0xc,%esp
801036e2:	ff 76 68             	pushl  0x68(%esi)
801036e5:	e8 9e df ff ff       	call   80101688 <iput>
  end_op();
801036ea:	e8 39 f1 ff ff       	call   80102828 <end_op>
  curproc->cwd = 0;
801036ef:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
801036f6:	c7 04 24 40 39 11 80 	movl   $0x80113940,(%esp)
801036fd:	e8 b8 09 00 00       	call   801040ba <acquire>
  wakeup1(curproc->parent);
80103702:	8b 46 14             	mov    0x14(%esi),%eax
80103705:	e8 2c f9 ff ff       	call   80103036 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010370a:	83 c4 10             	add    $0x10,%esp
8010370d:	bb 74 39 11 80       	mov    $0x80113974,%ebx
80103712:	eb 06                	jmp    8010371a <exit+0x8e>
80103714:	81 c3 a8 00 00 00    	add    $0xa8,%ebx
8010371a:	81 fb 74 63 11 80    	cmp    $0x80116374,%ebx
80103720:	73 1a                	jae    8010373c <exit+0xb0>
    if(p->parent == curproc){
80103722:	39 73 14             	cmp    %esi,0x14(%ebx)
80103725:	75 ed                	jne    80103714 <exit+0x88>
      p->parent = initproc;
80103727:	a1 b8 a5 10 80       	mov    0x8010a5b8,%eax
8010372c:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
8010372f:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103733:	75 df                	jne    80103714 <exit+0x88>
        wakeup1(initproc);
80103735:	e8 fc f8 ff ff       	call   80103036 <wakeup1>
8010373a:	eb d8                	jmp    80103714 <exit+0x88>
  curproc->state = ZOMBIE;
8010373c:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
80103743:	e8 a1 fe ff ff       	call   801035e9 <sched>
  panic("zombie exit");
80103748:	83 ec 0c             	sub    $0xc,%esp
8010374b:	68 fd 6f 10 80       	push   $0x80106ffd
80103750:	e8 f3 cb ff ff       	call   80100348 <panic>

80103755 <yield>:
{
80103755:	55                   	push   %ebp
80103756:	89 e5                	mov    %esp,%ebp
80103758:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
8010375b:	68 40 39 11 80       	push   $0x80113940
80103760:	e8 55 09 00 00       	call   801040ba <acquire>
  myproc()->state = RUNNABLE;
80103765:	e8 c7 fa ff ff       	call   80103231 <myproc>
8010376a:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103771:	e8 73 fe ff ff       	call   801035e9 <sched>
  release(&ptable.lock);
80103776:	c7 04 24 40 39 11 80 	movl   $0x80113940,(%esp)
8010377d:	e8 9d 09 00 00       	call   8010411f <release>
}
80103782:	83 c4 10             	add    $0x10,%esp
80103785:	c9                   	leave  
80103786:	c3                   	ret    

80103787 <sleep>:
{
80103787:	55                   	push   %ebp
80103788:	89 e5                	mov    %esp,%ebp
8010378a:	56                   	push   %esi
8010378b:	53                   	push   %ebx
8010378c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
8010378f:	e8 9d fa ff ff       	call   80103231 <myproc>
  if(p == 0)
80103794:	85 c0                	test   %eax,%eax
80103796:	74 66                	je     801037fe <sleep+0x77>
80103798:	89 c6                	mov    %eax,%esi
  if(lk == 0)
8010379a:	85 db                	test   %ebx,%ebx
8010379c:	74 6d                	je     8010380b <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
8010379e:	81 fb 40 39 11 80    	cmp    $0x80113940,%ebx
801037a4:	74 18                	je     801037be <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
801037a6:	83 ec 0c             	sub    $0xc,%esp
801037a9:	68 40 39 11 80       	push   $0x80113940
801037ae:	e8 07 09 00 00       	call   801040ba <acquire>
    release(lk);
801037b3:	89 1c 24             	mov    %ebx,(%esp)
801037b6:	e8 64 09 00 00       	call   8010411f <release>
801037bb:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
801037be:	8b 45 08             	mov    0x8(%ebp),%eax
801037c1:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
801037c4:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
801037cb:	e8 19 fe ff ff       	call   801035e9 <sched>
  p->chan = 0;
801037d0:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
801037d7:	81 fb 40 39 11 80    	cmp    $0x80113940,%ebx
801037dd:	74 18                	je     801037f7 <sleep+0x70>
    release(&ptable.lock);
801037df:	83 ec 0c             	sub    $0xc,%esp
801037e2:	68 40 39 11 80       	push   $0x80113940
801037e7:	e8 33 09 00 00       	call   8010411f <release>
    acquire(lk);
801037ec:	89 1c 24             	mov    %ebx,(%esp)
801037ef:	e8 c6 08 00 00       	call   801040ba <acquire>
801037f4:	83 c4 10             	add    $0x10,%esp
}
801037f7:	8d 65 f8             	lea    -0x8(%ebp),%esp
801037fa:	5b                   	pop    %ebx
801037fb:	5e                   	pop    %esi
801037fc:	5d                   	pop    %ebp
801037fd:	c3                   	ret    
    panic("sleep");
801037fe:	83 ec 0c             	sub    $0xc,%esp
80103801:	68 09 70 10 80       	push   $0x80107009
80103806:	e8 3d cb ff ff       	call   80100348 <panic>
    panic("sleep without lk");
8010380b:	83 ec 0c             	sub    $0xc,%esp
8010380e:	68 0f 70 10 80       	push   $0x8010700f
80103813:	e8 30 cb ff ff       	call   80100348 <panic>

80103818 <wait>:
{
80103818:	55                   	push   %ebp
80103819:	89 e5                	mov    %esp,%ebp
8010381b:	56                   	push   %esi
8010381c:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010381d:	e8 0f fa ff ff       	call   80103231 <myproc>
80103822:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103824:	83 ec 0c             	sub    $0xc,%esp
80103827:	68 40 39 11 80       	push   $0x80113940
8010382c:	e8 89 08 00 00       	call   801040ba <acquire>
80103831:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103834:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103839:	bb 74 39 11 80       	mov    $0x80113974,%ebx
8010383e:	eb 5e                	jmp    8010389e <wait+0x86>
        pid = p->pid;
80103840:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103843:	83 ec 0c             	sub    $0xc,%esp
80103846:	ff 73 08             	pushl  0x8(%ebx)
80103849:	e8 56 e7 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
8010384e:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103855:	83 c4 04             	add    $0x4,%esp
80103858:	ff 73 04             	pushl  0x4(%ebx)
8010385b:	e8 fc 2e 00 00       	call   8010675c <freevm>
        p->pid = 0;
80103860:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103867:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
8010386e:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103872:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103879:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103880:	c7 04 24 40 39 11 80 	movl   $0x80113940,(%esp)
80103887:	e8 93 08 00 00       	call   8010411f <release>
        return pid;
8010388c:	83 c4 10             	add    $0x10,%esp
}
8010388f:	89 f0                	mov    %esi,%eax
80103891:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103894:	5b                   	pop    %ebx
80103895:	5e                   	pop    %esi
80103896:	5d                   	pop    %ebp
80103897:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103898:	81 c3 a8 00 00 00    	add    $0xa8,%ebx
8010389e:	81 fb 74 63 11 80    	cmp    $0x80116374,%ebx
801038a4:	73 12                	jae    801038b8 <wait+0xa0>
      if(p->parent != curproc)
801038a6:	39 73 14             	cmp    %esi,0x14(%ebx)
801038a9:	75 ed                	jne    80103898 <wait+0x80>
      if(p->state == ZOMBIE){
801038ab:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801038af:	74 8f                	je     80103840 <wait+0x28>
      havekids = 1;
801038b1:	b8 01 00 00 00       	mov    $0x1,%eax
801038b6:	eb e0                	jmp    80103898 <wait+0x80>
    if(!havekids || curproc->killed){
801038b8:	85 c0                	test   %eax,%eax
801038ba:	74 06                	je     801038c2 <wait+0xaa>
801038bc:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
801038c0:	74 17                	je     801038d9 <wait+0xc1>
      release(&ptable.lock);
801038c2:	83 ec 0c             	sub    $0xc,%esp
801038c5:	68 40 39 11 80       	push   $0x80113940
801038ca:	e8 50 08 00 00       	call   8010411f <release>
      return -1;
801038cf:	83 c4 10             	add    $0x10,%esp
801038d2:	be ff ff ff ff       	mov    $0xffffffff,%esi
801038d7:	eb b6                	jmp    8010388f <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
801038d9:	83 ec 08             	sub    $0x8,%esp
801038dc:	68 40 39 11 80       	push   $0x80113940
801038e1:	56                   	push   %esi
801038e2:	e8 a0 fe ff ff       	call   80103787 <sleep>
    havekids = 0;
801038e7:	83 c4 10             	add    $0x10,%esp
801038ea:	e9 45 ff ff ff       	jmp    80103834 <wait+0x1c>

801038ef <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
801038ef:	55                   	push   %ebp
801038f0:	89 e5                	mov    %esp,%ebp
801038f2:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
801038f5:	68 40 39 11 80       	push   $0x80113940
801038fa:	e8 bb 07 00 00       	call   801040ba <acquire>
  wakeup1(chan);
801038ff:	8b 45 08             	mov    0x8(%ebp),%eax
80103902:	e8 2f f7 ff ff       	call   80103036 <wakeup1>
  release(&ptable.lock);
80103907:	c7 04 24 40 39 11 80 	movl   $0x80113940,(%esp)
8010390e:	e8 0c 08 00 00       	call   8010411f <release>
}
80103913:	83 c4 10             	add    $0x10,%esp
80103916:	c9                   	leave  
80103917:	c3                   	ret    

80103918 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103918:	55                   	push   %ebp
80103919:	89 e5                	mov    %esp,%ebp
8010391b:	53                   	push   %ebx
8010391c:	83 ec 10             	sub    $0x10,%esp
8010391f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103922:	68 40 39 11 80       	push   $0x80113940
80103927:	e8 8e 07 00 00       	call   801040ba <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010392c:	83 c4 10             	add    $0x10,%esp
8010392f:	b8 74 39 11 80       	mov    $0x80113974,%eax
80103934:	3d 74 63 11 80       	cmp    $0x80116374,%eax
80103939:	73 3c                	jae    80103977 <kill+0x5f>
    if(p->pid == pid){
8010393b:	39 58 10             	cmp    %ebx,0x10(%eax)
8010393e:	74 07                	je     80103947 <kill+0x2f>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103940:	05 a8 00 00 00       	add    $0xa8,%eax
80103945:	eb ed                	jmp    80103934 <kill+0x1c>
      p->killed = 1;
80103947:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
8010394e:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103952:	74 1a                	je     8010396e <kill+0x56>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103954:	83 ec 0c             	sub    $0xc,%esp
80103957:	68 40 39 11 80       	push   $0x80113940
8010395c:	e8 be 07 00 00       	call   8010411f <release>
      return 0;
80103961:	83 c4 10             	add    $0x10,%esp
80103964:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103969:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010396c:	c9                   	leave  
8010396d:	c3                   	ret    
        p->state = RUNNABLE;
8010396e:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103975:	eb dd                	jmp    80103954 <kill+0x3c>
  release(&ptable.lock);
80103977:	83 ec 0c             	sub    $0xc,%esp
8010397a:	68 40 39 11 80       	push   $0x80113940
8010397f:	e8 9b 07 00 00       	call   8010411f <release>
  return -1;
80103984:	83 c4 10             	add    $0x10,%esp
80103987:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010398c:	eb db                	jmp    80103969 <kill+0x51>

8010398e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
8010398e:	55                   	push   %ebp
8010398f:	89 e5                	mov    %esp,%ebp
80103991:	56                   	push   %esi
80103992:	53                   	push   %ebx
80103993:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103996:	bb 74 39 11 80       	mov    $0x80113974,%ebx
8010399b:	eb 36                	jmp    801039d3 <procdump+0x45>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
8010399d:	b8 20 70 10 80       	mov    $0x80107020,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
801039a2:	8d 53 6c             	lea    0x6c(%ebx),%edx
801039a5:	52                   	push   %edx
801039a6:	50                   	push   %eax
801039a7:	ff 73 10             	pushl  0x10(%ebx)
801039aa:	68 24 70 10 80       	push   $0x80107024
801039af:	e8 57 cc ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
801039b4:	83 c4 10             	add    $0x10,%esp
801039b7:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
801039bb:	74 3c                	je     801039f9 <procdump+0x6b>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801039bd:	83 ec 0c             	sub    $0xc,%esp
801039c0:	68 42 70 10 80       	push   $0x80107042
801039c5:	e8 41 cc ff ff       	call   8010060b <cprintf>
801039ca:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039cd:	81 c3 a8 00 00 00    	add    $0xa8,%ebx
801039d3:	81 fb 74 63 11 80    	cmp    $0x80116374,%ebx
801039d9:	73 61                	jae    80103a3c <procdump+0xae>
    if(p->state == UNUSED)
801039db:	8b 43 0c             	mov    0xc(%ebx),%eax
801039de:	85 c0                	test   %eax,%eax
801039e0:	74 eb                	je     801039cd <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801039e2:	83 f8 05             	cmp    $0x5,%eax
801039e5:	77 b6                	ja     8010399d <procdump+0xf>
801039e7:	8b 04 85 a8 70 10 80 	mov    -0x7fef8f58(,%eax,4),%eax
801039ee:	85 c0                	test   %eax,%eax
801039f0:	75 b0                	jne    801039a2 <procdump+0x14>
      state = "???";
801039f2:	b8 20 70 10 80       	mov    $0x80107020,%eax
801039f7:	eb a9                	jmp    801039a2 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
801039f9:	8b 43 1c             	mov    0x1c(%ebx),%eax
801039fc:	8b 40 0c             	mov    0xc(%eax),%eax
801039ff:	83 c0 08             	add    $0x8,%eax
80103a02:	83 ec 08             	sub    $0x8,%esp
80103a05:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103a08:	52                   	push   %edx
80103a09:	50                   	push   %eax
80103a0a:	e8 8a 05 00 00       	call   80103f99 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a0f:	83 c4 10             	add    $0x10,%esp
80103a12:	be 00 00 00 00       	mov    $0x0,%esi
80103a17:	eb 14                	jmp    80103a2d <procdump+0x9f>
        cprintf(" %p", pc[i]);
80103a19:	83 ec 08             	sub    $0x8,%esp
80103a1c:	50                   	push   %eax
80103a1d:	68 61 6a 10 80       	push   $0x80106a61
80103a22:	e8 e4 cb ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a27:	83 c6 01             	add    $0x1,%esi
80103a2a:	83 c4 10             	add    $0x10,%esp
80103a2d:	83 fe 09             	cmp    $0x9,%esi
80103a30:	7f 8b                	jg     801039bd <procdump+0x2f>
80103a32:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103a36:	85 c0                	test   %eax,%eax
80103a38:	75 df                	jne    80103a19 <procdump+0x8b>
80103a3a:	eb 81                	jmp    801039bd <procdump+0x2f>
  }
}
80103a3c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a3f:	5b                   	pop    %ebx
80103a40:	5e                   	pop    %esi
80103a41:	5d                   	pop    %ebp
80103a42:	c3                   	ret    

80103a43 <setpri>:

// This sets the priority of the specified PID to pri
// return -1 if pri or PID are invalid
int
setpri(int PID, int pri){
80103a43:	55                   	push   %ebp
80103a44:	89 e5                	mov    %esp,%ebp
80103a46:	57                   	push   %edi
80103a47:	56                   	push   %esi
80103a48:	53                   	push   %ebx
80103a49:	83 ec 0c             	sub    $0xc,%esp
80103a4c:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103a4f:	8b 75 0c             	mov    0xc(%ebp),%esi

    if (pri < 0 || pri > 3) {
80103a52:	83 fe 03             	cmp    $0x3,%esi
80103a55:	0f 87 e3 00 00 00    	ja     80103b3e <setpri+0xfb>
        return -1;
    }
    acquire(&ptable.lock);
80103a5b:	83 ec 0c             	sub    $0xc,%esp
80103a5e:	68 40 39 11 80       	push   $0x80113940
80103a63:	e8 52 06 00 00       	call   801040ba <acquire>
    struct proc *p;

    for (int i = 3; i >= 0; i--){
80103a68:	83 c4 10             	add    $0x10,%esp
80103a6b:	b9 03 00 00 00       	mov    $0x3,%ecx
80103a70:	85 c9                	test   %ecx,%ecx
80103a72:	0f 88 af 00 00 00    	js     80103b27 <setpri+0xe4>
        struct proc *prevProc = NULL;
        for (p = priorityQueue[i].head; p != NULL;) {
80103a78:	8b 3c cd 20 39 11 80 	mov    -0x7feec6e0(,%ecx,8),%edi
80103a7f:	89 f8                	mov    %edi,%eax
        struct proc *prevProc = NULL;
80103a81:	ba 00 00 00 00       	mov    $0x0,%edx
        for (p = priorityQueue[i].head; p != NULL;) {
80103a86:	85 c0                	test   %eax,%eax
80103a88:	0f 84 91 00 00 00    	je     80103b1f <setpri+0xdc>

            if( p->pid == PID ){
80103a8e:	39 58 10             	cmp    %ebx,0x10(%eax)
80103a91:	74 0a                	je     80103a9d <setpri+0x5a>
                priorityQueue[pri].tail = p;
                p->next = NULL;
                release(&ptable.lock);
                return 0;
            }
            prevProc = p;
80103a93:	89 c2                	mov    %eax,%edx
            p = p->next;
80103a95:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80103a9b:	eb e9                	jmp    80103a86 <setpri+0x43>
                if (p->priority == pri){
80103a9d:	39 70 7c             	cmp    %esi,0x7c(%eax)
80103aa0:	0f 84 9f 00 00 00    	je     80103b45 <setpri+0x102>
                p->priority = pri;
80103aa6:	89 70 7c             	mov    %esi,0x7c(%eax)
                if (p == priorityQueue[i].head) {
80103aa9:	39 f8                	cmp    %edi,%eax
80103aab:	74 50                	je     80103afd <setpri+0xba>
                } else if (p == priorityQueue[i].tail) {
80103aad:	39 04 cd 24 39 11 80 	cmp    %eax,-0x7feec6dc(,%ecx,8)
80103ab4:	74 56                	je     80103b0c <setpri+0xc9>
                    prevProc->next = p->next;
80103ab6:	8b 88 80 00 00 00    	mov    0x80(%eax),%ecx
80103abc:	89 8a 80 00 00 00    	mov    %ecx,0x80(%edx)
                priorityQueue[pri].tail->next = p;
80103ac2:	8b 14 f5 24 39 11 80 	mov    -0x7feec6dc(,%esi,8),%edx
80103ac9:	89 82 80 00 00 00    	mov    %eax,0x80(%edx)
                priorityQueue[pri].tail = p;
80103acf:	89 04 f5 24 39 11 80 	mov    %eax,-0x7feec6dc(,%esi,8)
                p->next = NULL;
80103ad6:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80103add:	00 00 00 
                release(&ptable.lock);
80103ae0:	83 ec 0c             	sub    $0xc,%esp
80103ae3:	68 40 39 11 80       	push   $0x80113940
80103ae8:	e8 32 06 00 00       	call   8010411f <release>
                return 0;
80103aed:	83 c4 10             	add    $0x10,%esp
80103af0:	b8 00 00 00 00       	mov    $0x0,%eax
        }
    }

    release(&ptable.lock);
    return -1;
}
80103af5:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103af8:	5b                   	pop    %ebx
80103af9:	5e                   	pop    %esi
80103afa:	5f                   	pop    %edi
80103afb:	5d                   	pop    %ebp
80103afc:	c3                   	ret    
                    priorityQueue[i].head = p->next;
80103afd:	8b 90 80 00 00 00    	mov    0x80(%eax),%edx
80103b03:	89 14 cd 20 39 11 80 	mov    %edx,-0x7feec6e0(,%ecx,8)
80103b0a:	eb b6                	jmp    80103ac2 <setpri+0x7f>
                    prevProc->next = NULL;
80103b0c:	c7 82 80 00 00 00 00 	movl   $0x0,0x80(%edx)
80103b13:	00 00 00 
                    priorityQueue[i].tail = prevProc;
80103b16:	89 14 cd 24 39 11 80 	mov    %edx,-0x7feec6dc(,%ecx,8)
80103b1d:	eb a3                	jmp    80103ac2 <setpri+0x7f>
    for (int i = 3; i >= 0; i--){
80103b1f:	83 e9 01             	sub    $0x1,%ecx
80103b22:	e9 49 ff ff ff       	jmp    80103a70 <setpri+0x2d>
    release(&ptable.lock);
80103b27:	83 ec 0c             	sub    $0xc,%esp
80103b2a:	68 40 39 11 80       	push   $0x80113940
80103b2f:	e8 eb 05 00 00       	call   8010411f <release>
    return -1;
80103b34:	83 c4 10             	add    $0x10,%esp
80103b37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103b3c:	eb b7                	jmp    80103af5 <setpri+0xb2>
        return -1;
80103b3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103b43:	eb b0                	jmp    80103af5 <setpri+0xb2>
                    return -1;
80103b45:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103b4a:	eb a9                	jmp    80103af5 <setpri+0xb2>

80103b4c <getpri>:

// returns the current priority of the specified PID.
// If the PID is not valid, it returns -1
int
getpri(int PID){
80103b4c:	55                   	push   %ebp
80103b4d:	89 e5                	mov    %esp,%ebp
80103b4f:	56                   	push   %esi
80103b50:	53                   	push   %ebx
80103b51:	8b 75 08             	mov    0x8(%ebp),%esi
    struct proc *p;
    acquire(&ptable.lock);
80103b54:	83 ec 0c             	sub    $0xc,%esp
80103b57:	68 40 39 11 80       	push   $0x80113940
80103b5c:	e8 59 05 00 00       	call   801040ba <acquire>

    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
80103b61:	83 c4 10             	add    $0x10,%esp
80103b64:	bb 74 39 11 80       	mov    $0x80113974,%ebx
80103b69:	81 fb 74 63 11 80    	cmp    $0x80116374,%ebx
80103b6f:	73 27                	jae    80103b98 <getpri+0x4c>
        if (p->pid == PID) {
80103b71:	39 73 10             	cmp    %esi,0x10(%ebx)
80103b74:	74 08                	je     80103b7e <getpri+0x32>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
80103b76:	81 c3 a8 00 00 00    	add    $0xa8,%ebx
80103b7c:	eb eb                	jmp    80103b69 <getpri+0x1d>
            release(&ptable.lock);
80103b7e:	83 ec 0c             	sub    $0xc,%esp
80103b81:	68 40 39 11 80       	push   $0x80113940
80103b86:	e8 94 05 00 00       	call   8010411f <release>
            return p->priority;
80103b8b:	8b 43 7c             	mov    0x7c(%ebx),%eax
80103b8e:	83 c4 10             	add    $0x10,%esp
        }
    }
    release(&ptable.lock);
    return -1;
}
80103b91:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b94:	5b                   	pop    %ebx
80103b95:	5e                   	pop    %esi
80103b96:	5d                   	pop    %ebp
80103b97:	c3                   	ret    
    release(&ptable.lock);
80103b98:	83 ec 0c             	sub    $0xc,%esp
80103b9b:	68 40 39 11 80       	push   $0x80113940
80103ba0:	e8 7a 05 00 00       	call   8010411f <release>
    return -1;
80103ba5:	83 c4 10             	add    $0x10,%esp
80103ba8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103bad:	eb e2                	jmp    80103b91 <getpri+0x45>

80103baf <printQueue>:


    return pid;
}

void printQueue() {
80103baf:	55                   	push   %ebp
80103bb0:	89 e5                	mov    %esp,%ebp
80103bb2:	56                   	push   %esi
80103bb3:	53                   	push   %ebx
    // helper method for printing the current pqueue
    struct proc *p;

    for (int i = 0; i < 4; i++){
80103bb4:	be 00 00 00 00       	mov    $0x0,%esi
80103bb9:	eb 23                	jmp    80103bde <printQueue+0x2f>
        for (p = priorityQueue[i].head; p != NULL;){
            //cprintf("PID: %d Proc: %p  Next: %p Head: %p Tail: %p\n", p->pid, p, p->next, priorityQueue[i].head, priorityQueue[i].tail);
            cprintf("PID: %d PRIORITY: %d \n", p->pid, p->priority);
80103bbb:	83 ec 04             	sub    $0x4,%esp
80103bbe:	ff 73 7c             	pushl  0x7c(%ebx)
80103bc1:	ff 73 10             	pushl  0x10(%ebx)
80103bc4:	68 2d 70 10 80       	push   $0x8010702d
80103bc9:	e8 3d ca ff ff       	call   8010060b <cprintf>
            p = p->next;
80103bce:	8b 9b 80 00 00 00    	mov    0x80(%ebx),%ebx
80103bd4:	83 c4 10             	add    $0x10,%esp
        for (p = priorityQueue[i].head; p != NULL;){
80103bd7:	85 db                	test   %ebx,%ebx
80103bd9:	75 e0                	jne    80103bbb <printQueue+0xc>
    for (int i = 0; i < 4; i++){
80103bdb:	83 c6 01             	add    $0x1,%esi
80103bde:	83 fe 03             	cmp    $0x3,%esi
80103be1:	7f 09                	jg     80103bec <printQueue+0x3d>
        for (p = priorityQueue[i].head; p != NULL;){
80103be3:	8b 1c f5 20 39 11 80 	mov    -0x7feec6e0(,%esi,8),%ebx
80103bea:	eb eb                	jmp    80103bd7 <printQueue+0x28>
        }
    }
}
80103bec:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103bef:	5b                   	pop    %ebx
80103bf0:	5e                   	pop    %esi
80103bf1:	5d                   	pop    %ebp
80103bf2:	c3                   	ret    

80103bf3 <fork2>:
fork2(int pri) {
80103bf3:	55                   	push   %ebp
80103bf4:	89 e5                	mov    %esp,%ebp
80103bf6:	57                   	push   %edi
80103bf7:	56                   	push   %esi
80103bf8:	53                   	push   %ebx
80103bf9:	83 ec 1c             	sub    $0x1c,%esp
    if (pri < 0 || pri > 3) {
80103bfc:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
80103c00:	76 0d                	jbe    80103c0f <fork2+0x1c>
        if (pri == -1) {
80103c02:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
80103c06:	75 63                	jne    80103c6b <fork2+0x78>
            pri = 3;
80103c08:	c7 45 08 03 00 00 00 	movl   $0x3,0x8(%ebp)
    struct proc *curproc = myproc();
80103c0f:	e8 1d f6 ff ff       	call   80103231 <myproc>
80103c14:	89 c3                	mov    %eax,%ebx
    if((np = allocproc()) == 0){
80103c16:	e8 49 f4 ff ff       	call   80103064 <allocproc>
80103c1b:	89 c7                	mov    %eax,%edi
80103c1d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80103c20:	85 c0                	test   %eax,%eax
80103c22:	0f 84 5b 01 00 00    	je     80103d83 <fork2+0x190>
    if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
80103c28:	83 ec 08             	sub    $0x8,%esp
80103c2b:	ff 33                	pushl  (%ebx)
80103c2d:	ff 73 04             	pushl  0x4(%ebx)
80103c30:	e8 48 2c 00 00       	call   8010687d <copyuvm>
80103c35:	89 47 04             	mov    %eax,0x4(%edi)
80103c38:	83 c4 10             	add    $0x10,%esp
80103c3b:	85 c0                	test   %eax,%eax
80103c3d:	74 31                	je     80103c70 <fork2+0x7d>
    np->sz = curproc->sz;
80103c3f:	8b 03                	mov    (%ebx),%eax
80103c41:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103c44:	89 07                	mov    %eax,(%edi)
    np->parent = curproc;
80103c46:	89 f8                	mov    %edi,%eax
80103c48:	89 5f 14             	mov    %ebx,0x14(%edi)
    *np->tf = *curproc->tf;
80103c4b:	8b 73 18             	mov    0x18(%ebx),%esi
80103c4e:	8b 7f 18             	mov    0x18(%edi),%edi
80103c51:	b9 13 00 00 00       	mov    $0x13,%ecx
80103c56:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
    np->tf->eax = 0;
80103c58:	89 c7                	mov    %eax,%edi
80103c5a:	8b 40 18             	mov    0x18(%eax),%eax
80103c5d:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
    for(i = 0; i < NOFILE; i++)
80103c64:	be 00 00 00 00       	mov    $0x0,%esi
80103c69:	eb 31                	jmp    80103c9c <fork2+0xa9>
            exit();
80103c6b:	e8 1c fa ff ff       	call   8010368c <exit>
        kfree(np->kstack);
80103c70:	83 ec 0c             	sub    $0xc,%esp
80103c73:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103c76:	ff 73 08             	pushl  0x8(%ebx)
80103c79:	e8 26 e3 ff ff       	call   80101fa4 <kfree>
        np->kstack = 0;
80103c7e:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        np->state = UNUSED;
80103c85:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        return -1;
80103c8c:	83 c4 10             	add    $0x10,%esp
80103c8f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103c94:	e9 c1 00 00 00       	jmp    80103d5a <fork2+0x167>
    for(i = 0; i < NOFILE; i++)
80103c99:	83 c6 01             	add    $0x1,%esi
80103c9c:	83 fe 0f             	cmp    $0xf,%esi
80103c9f:	7f 1a                	jg     80103cbb <fork2+0xc8>
        if(curproc->ofile[i])
80103ca1:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103ca5:	85 c0                	test   %eax,%eax
80103ca7:	74 f0                	je     80103c99 <fork2+0xa6>
            np->ofile[i] = filedup(curproc->ofile[i]);
80103ca9:	83 ec 0c             	sub    $0xc,%esp
80103cac:	50                   	push   %eax
80103cad:	e8 dc cf ff ff       	call   80100c8e <filedup>
80103cb2:	89 44 b7 28          	mov    %eax,0x28(%edi,%esi,4)
80103cb6:	83 c4 10             	add    $0x10,%esp
80103cb9:	eb de                	jmp    80103c99 <fork2+0xa6>
    np->cwd = idup(curproc->cwd);
80103cbb:	83 ec 0c             	sub    $0xc,%esp
80103cbe:	ff 73 68             	pushl  0x68(%ebx)
80103cc1:	e8 8b d8 ff ff       	call   80101551 <idup>
80103cc6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103cc9:	89 47 68             	mov    %eax,0x68(%edi)
    safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103ccc:	83 c3 6c             	add    $0x6c,%ebx
80103ccf:	8d 47 6c             	lea    0x6c(%edi),%eax
80103cd2:	83 c4 0c             	add    $0xc,%esp
80103cd5:	6a 10                	push   $0x10
80103cd7:	53                   	push   %ebx
80103cd8:	50                   	push   %eax
80103cd9:	e8 ef 05 00 00       	call   801042cd <safestrcpy>
    pid = np->pid;
80103cde:	8b 5f 10             	mov    0x10(%edi),%ebx
    if (priorityQueue[pri].head == NULL && priorityQueue[pri].tail == NULL) {
80103ce1:	83 c4 10             	add    $0x10,%esp
80103ce4:	8b 45 08             	mov    0x8(%ebp),%eax
80103ce7:	83 3c c5 20 39 11 80 	cmpl   $0x0,-0x7feec6e0(,%eax,8)
80103cee:	00 
80103cef:	74 73                	je     80103d64 <fork2+0x171>
        priorityQueue[pri].tail->next = np;
80103cf1:	8b 45 08             	mov    0x8(%ebp),%eax
80103cf4:	8b 04 c5 24 39 11 80 	mov    -0x7feec6dc(,%eax,8),%eax
80103cfb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103cfe:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
        priorityQueue[pri].tail = np;
80103d04:	8b 45 08             	mov    0x8(%ebp),%eax
80103d07:	89 14 c5 24 39 11 80 	mov    %edx,-0x7feec6dc(,%eax,8)
    np->next = NULL;
80103d0e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103d11:	c7 87 80 00 00 00 00 	movl   $0x0,0x80(%edi)
80103d18:	00 00 00 
    np->priority = pri;
80103d1b:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103d1e:	89 4f 7c             	mov    %ecx,0x7c(%edi)
    cprintf("%s\n", "NEW FORK CALL");
80103d21:	83 ec 08             	sub    $0x8,%esp
80103d24:	68 44 70 10 80       	push   $0x80107044
80103d29:	68 52 70 10 80       	push   $0x80107052
80103d2e:	e8 d8 c8 ff ff       	call   8010060b <cprintf>
    printQueue();
80103d33:	e8 77 fe ff ff       	call   80103baf <printQueue>
    acquire(&ptable.lock);
80103d38:	c7 04 24 40 39 11 80 	movl   $0x80113940,(%esp)
80103d3f:	e8 76 03 00 00       	call   801040ba <acquire>
    np->state = RUNNABLE;
80103d44:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
    release(&ptable.lock);
80103d4b:	c7 04 24 40 39 11 80 	movl   $0x80113940,(%esp)
80103d52:	e8 c8 03 00 00       	call   8010411f <release>
    return pid;
80103d57:	83 c4 10             	add    $0x10,%esp
}
80103d5a:	89 d8                	mov    %ebx,%eax
80103d5c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103d5f:	5b                   	pop    %ebx
80103d60:	5e                   	pop    %esi
80103d61:	5f                   	pop    %edi
80103d62:	5d                   	pop    %ebp
80103d63:	c3                   	ret    
    if (priorityQueue[pri].head == NULL && priorityQueue[pri].tail == NULL) {
80103d64:	83 3c c5 24 39 11 80 	cmpl   $0x0,-0x7feec6dc(,%eax,8)
80103d6b:	00 
80103d6c:	75 83                	jne    80103cf1 <fork2+0xfe>
        priorityQueue[pri].head = np;
80103d6e:	89 c1                	mov    %eax,%ecx
80103d70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103d73:	89 04 cd 20 39 11 80 	mov    %eax,-0x7feec6e0(,%ecx,8)
        priorityQueue[pri].tail = np;
80103d7a:	89 04 cd 24 39 11 80 	mov    %eax,-0x7feec6dc(,%ecx,8)
80103d81:	eb 8b                	jmp    80103d0e <fork2+0x11b>
        return -1;
80103d83:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103d88:	eb d0                	jmp    80103d5a <fork2+0x167>

80103d8a <fork>:
{
80103d8a:	55                   	push   %ebp
80103d8b:	89 e5                	mov    %esp,%ebp
80103d8d:	83 ec 14             	sub    $0x14,%esp
  int pid = fork2(-1);
80103d90:	6a ff                	push   $0xffffffff
80103d92:	e8 5c fe ff ff       	call   80103bf3 <fork2>
}
80103d97:	c9                   	leave  
80103d98:	c3                   	ret    

80103d99 <getpinfo>:

// returns 0 on success and -1 on failure
int
getpinfo(struct pstat *pstat){
80103d99:	55                   	push   %ebp
80103d9a:	89 e5                	mov    %esp,%ebp
80103d9c:	57                   	push   %edi
80103d9d:	56                   	push   %esi
80103d9e:	81 ec bc 00 00 00    	sub    $0xbc,%esp

    acquire(&ptable.lock);
80103da4:	68 40 39 11 80       	push   $0x80113940
80103da9:	e8 0c 03 00 00       	call   801040ba <acquire>

    for (int i = 0; i < NPROC; i++){
80103dae:	83 c4 10             	add    $0x10,%esp
80103db1:	ba 00 00 00 00       	mov    $0x0,%edx
80103db6:	eb 24                	jmp    80103ddc <getpinfo+0x43>
        fpstat.pid[i] = proc.pid;
        fpstat.priority[i] = proc.priority;

        fpstat.state[i] = proc.state;
        for (int j = 0; j < 4; j++) {
            fpstat.ticks[i][j] = proc.agg_ticks[j];
80103db8:	8d 0c 90             	lea    (%eax,%edx,4),%ecx
80103dbb:	8b 7c 85 d8          	mov    -0x28(%ebp,%eax,4),%edi
80103dbf:	89 3c 8d 20 31 11 80 	mov    %edi,-0x7feecee0(,%ecx,4)
            fpstat.qtail[i][j] = proc.qtail[j];
80103dc6:	8b 74 85 e8          	mov    -0x18(%ebp,%eax,4),%esi
80103dca:	89 34 8d 20 35 11 80 	mov    %esi,-0x7feecae0(,%ecx,4)
        for (int j = 0; j < 4; j++) {
80103dd1:	83 c0 01             	add    $0x1,%eax
80103dd4:	83 f8 03             	cmp    $0x3,%eax
80103dd7:	7e df                	jle    80103db8 <getpinfo+0x1f>
    for (int i = 0; i < NPROC; i++){
80103dd9:	83 c2 01             	add    $0x1,%edx
80103ddc:	83 fa 3f             	cmp    $0x3f,%edx
80103ddf:	7f 53                	jg     80103e34 <getpinfo+0x9b>
        struct proc proc = ptable.proc[i];
80103de1:	69 f2 a8 00 00 00    	imul   $0xa8,%edx,%esi
80103de7:	8d bd 50 ff ff ff    	lea    -0xb0(%ebp),%edi
80103ded:	81 c6 74 39 11 80    	add    $0x80113974,%esi
80103df3:	b9 2a 00 00 00       	mov    $0x2a,%ecx
80103df8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
        fpstat.inuse[i] = (proc.state == UNUSED);
80103dfa:	8b 85 5c ff ff ff    	mov    -0xa4(%ebp),%eax
80103e00:	85 c0                	test   %eax,%eax
80103e02:	0f 94 c1             	sete   %cl
80103e05:	0f b6 c9             	movzbl %cl,%ecx
80103e08:	89 0c 95 20 2d 11 80 	mov    %ecx,-0x7feed2e0(,%edx,4)
        fpstat.pid[i] = proc.pid;
80103e0f:	8b 8d 60 ff ff ff    	mov    -0xa0(%ebp),%ecx
80103e15:	89 0c 95 20 2e 11 80 	mov    %ecx,-0x7feed1e0(,%edx,4)
        fpstat.priority[i] = proc.priority;
80103e1c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
80103e1f:	89 0c 95 20 2f 11 80 	mov    %ecx,-0x7feed0e0(,%edx,4)
        fpstat.state[i] = proc.state;
80103e26:	89 04 95 20 30 11 80 	mov    %eax,-0x7feecfe0(,%edx,4)
        for (int j = 0; j < 4; j++) {
80103e2d:	b8 00 00 00 00       	mov    $0x0,%eax
80103e32:	eb a0                	jmp    80103dd4 <getpinfo+0x3b>
        }
    }

    pstat = &fpstat;

    for(int i = 0; i < NPROC; i++) {
80103e34:	be 00 00 00 00       	mov    $0x0,%esi
80103e39:	eb 1a                	jmp    80103e55 <getpinfo+0xbc>
        cprintf("%d\n", pstat->state[i]);
80103e3b:	83 ec 08             	sub    $0x8,%esp
80103e3e:	ff 34 b5 20 30 11 80 	pushl  -0x7feecfe0(,%esi,4)
80103e45:	68 14 6f 10 80       	push   $0x80106f14
80103e4a:	e8 bc c7 ff ff       	call   8010060b <cprintf>
    for(int i = 0; i < NPROC; i++) {
80103e4f:	83 c6 01             	add    $0x1,%esi
80103e52:	83 c4 10             	add    $0x10,%esp
80103e55:	83 fe 3f             	cmp    $0x3f,%esi
80103e58:	7e e1                	jle    80103e3b <getpinfo+0xa2>
    }
    release(&ptable.lock);
80103e5a:	83 ec 0c             	sub    $0xc,%esp
80103e5d:	68 40 39 11 80       	push   $0x80113940
80103e62:	e8 b8 02 00 00       	call   8010411f <release>
    return 0;
}
80103e67:	b8 00 00 00 00       	mov    $0x0,%eax
80103e6c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103e6f:	5e                   	pop    %esi
80103e70:	5f                   	pop    %edi
80103e71:	5d                   	pop    %ebp
80103e72:	c3                   	ret    

80103e73 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103e73:	55                   	push   %ebp
80103e74:	89 e5                	mov    %esp,%ebp
80103e76:	53                   	push   %ebx
80103e77:	83 ec 0c             	sub    $0xc,%esp
80103e7a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103e7d:	68 c0 70 10 80       	push   $0x801070c0
80103e82:	8d 43 04             	lea    0x4(%ebx),%eax
80103e85:	50                   	push   %eax
80103e86:	e8 f3 00 00 00       	call   80103f7e <initlock>
  lk->name = name;
80103e8b:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e8e:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103e91:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103e97:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103e9e:	83 c4 10             	add    $0x10,%esp
80103ea1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103ea4:	c9                   	leave  
80103ea5:	c3                   	ret    

80103ea6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103ea6:	55                   	push   %ebp
80103ea7:	89 e5                	mov    %esp,%ebp
80103ea9:	56                   	push   %esi
80103eaa:	53                   	push   %ebx
80103eab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103eae:	8d 73 04             	lea    0x4(%ebx),%esi
80103eb1:	83 ec 0c             	sub    $0xc,%esp
80103eb4:	56                   	push   %esi
80103eb5:	e8 00 02 00 00       	call   801040ba <acquire>
  while (lk->locked) {
80103eba:	83 c4 10             	add    $0x10,%esp
80103ebd:	eb 0d                	jmp    80103ecc <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103ebf:	83 ec 08             	sub    $0x8,%esp
80103ec2:	56                   	push   %esi
80103ec3:	53                   	push   %ebx
80103ec4:	e8 be f8 ff ff       	call   80103787 <sleep>
80103ec9:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103ecc:	83 3b 00             	cmpl   $0x0,(%ebx)
80103ecf:	75 ee                	jne    80103ebf <acquiresleep+0x19>
  }
  lk->locked = 1;
80103ed1:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103ed7:	e8 55 f3 ff ff       	call   80103231 <myproc>
80103edc:	8b 40 10             	mov    0x10(%eax),%eax
80103edf:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103ee2:	83 ec 0c             	sub    $0xc,%esp
80103ee5:	56                   	push   %esi
80103ee6:	e8 34 02 00 00       	call   8010411f <release>
}
80103eeb:	83 c4 10             	add    $0x10,%esp
80103eee:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ef1:	5b                   	pop    %ebx
80103ef2:	5e                   	pop    %esi
80103ef3:	5d                   	pop    %ebp
80103ef4:	c3                   	ret    

80103ef5 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103ef5:	55                   	push   %ebp
80103ef6:	89 e5                	mov    %esp,%ebp
80103ef8:	56                   	push   %esi
80103ef9:	53                   	push   %ebx
80103efa:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103efd:	8d 73 04             	lea    0x4(%ebx),%esi
80103f00:	83 ec 0c             	sub    $0xc,%esp
80103f03:	56                   	push   %esi
80103f04:	e8 b1 01 00 00       	call   801040ba <acquire>
  lk->locked = 0;
80103f09:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103f0f:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103f16:	89 1c 24             	mov    %ebx,(%esp)
80103f19:	e8 d1 f9 ff ff       	call   801038ef <wakeup>
  release(&lk->lk);
80103f1e:	89 34 24             	mov    %esi,(%esp)
80103f21:	e8 f9 01 00 00       	call   8010411f <release>
}
80103f26:	83 c4 10             	add    $0x10,%esp
80103f29:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103f2c:	5b                   	pop    %ebx
80103f2d:	5e                   	pop    %esi
80103f2e:	5d                   	pop    %ebp
80103f2f:	c3                   	ret    

80103f30 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103f30:	55                   	push   %ebp
80103f31:	89 e5                	mov    %esp,%ebp
80103f33:	56                   	push   %esi
80103f34:	53                   	push   %ebx
80103f35:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103f38:	8d 73 04             	lea    0x4(%ebx),%esi
80103f3b:	83 ec 0c             	sub    $0xc,%esp
80103f3e:	56                   	push   %esi
80103f3f:	e8 76 01 00 00       	call   801040ba <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103f44:	83 c4 10             	add    $0x10,%esp
80103f47:	83 3b 00             	cmpl   $0x0,(%ebx)
80103f4a:	75 17                	jne    80103f63 <holdingsleep+0x33>
80103f4c:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103f51:	83 ec 0c             	sub    $0xc,%esp
80103f54:	56                   	push   %esi
80103f55:	e8 c5 01 00 00       	call   8010411f <release>
  return r;
}
80103f5a:	89 d8                	mov    %ebx,%eax
80103f5c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103f5f:	5b                   	pop    %ebx
80103f60:	5e                   	pop    %esi
80103f61:	5d                   	pop    %ebp
80103f62:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103f63:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103f66:	e8 c6 f2 ff ff       	call   80103231 <myproc>
80103f6b:	3b 58 10             	cmp    0x10(%eax),%ebx
80103f6e:	74 07                	je     80103f77 <holdingsleep+0x47>
80103f70:	bb 00 00 00 00       	mov    $0x0,%ebx
80103f75:	eb da                	jmp    80103f51 <holdingsleep+0x21>
80103f77:	bb 01 00 00 00       	mov    $0x1,%ebx
80103f7c:	eb d3                	jmp    80103f51 <holdingsleep+0x21>

80103f7e <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103f7e:	55                   	push   %ebp
80103f7f:	89 e5                	mov    %esp,%ebp
80103f81:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103f84:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f87:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103f8a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103f90:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103f97:	5d                   	pop    %ebp
80103f98:	c3                   	ret    

80103f99 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103f99:	55                   	push   %ebp
80103f9a:	89 e5                	mov    %esp,%ebp
80103f9c:	53                   	push   %ebx
80103f9d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103fa0:	8b 45 08             	mov    0x8(%ebp),%eax
80103fa3:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103fa6:	b8 00 00 00 00       	mov    $0x0,%eax
80103fab:	83 f8 09             	cmp    $0x9,%eax
80103fae:	7f 25                	jg     80103fd5 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103fb0:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103fb6:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103fbc:	77 17                	ja     80103fd5 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103fbe:	8b 5a 04             	mov    0x4(%edx),%ebx
80103fc1:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103fc4:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103fc6:	83 c0 01             	add    $0x1,%eax
80103fc9:	eb e0                	jmp    80103fab <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103fcb:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103fd2:	83 c0 01             	add    $0x1,%eax
80103fd5:	83 f8 09             	cmp    $0x9,%eax
80103fd8:	7e f1                	jle    80103fcb <getcallerpcs+0x32>
}
80103fda:	5b                   	pop    %ebx
80103fdb:	5d                   	pop    %ebp
80103fdc:	c3                   	ret    

80103fdd <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103fdd:	55                   	push   %ebp
80103fde:	89 e5                	mov    %esp,%ebp
80103fe0:	53                   	push   %ebx
80103fe1:	83 ec 04             	sub    $0x4,%esp
80103fe4:	9c                   	pushf  
80103fe5:	5b                   	pop    %ebx
  asm volatile("cli");
80103fe6:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103fe7:	e8 ce f1 ff ff       	call   801031ba <mycpu>
80103fec:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103ff3:	74 12                	je     80104007 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103ff5:	e8 c0 f1 ff ff       	call   801031ba <mycpu>
80103ffa:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80104001:	83 c4 04             	add    $0x4,%esp
80104004:	5b                   	pop    %ebx
80104005:	5d                   	pop    %ebp
80104006:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80104007:	e8 ae f1 ff ff       	call   801031ba <mycpu>
8010400c:	81 e3 00 02 00 00    	and    $0x200,%ebx
80104012:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80104018:	eb db                	jmp    80103ff5 <pushcli+0x18>

8010401a <popcli>:

void
popcli(void)
{
8010401a:	55                   	push   %ebp
8010401b:	89 e5                	mov    %esp,%ebp
8010401d:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104020:	9c                   	pushf  
80104021:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80104022:	f6 c4 02             	test   $0x2,%ah
80104025:	75 28                	jne    8010404f <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80104027:	e8 8e f1 ff ff       	call   801031ba <mycpu>
8010402c:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80104032:	8d 51 ff             	lea    -0x1(%ecx),%edx
80104035:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
8010403b:	85 d2                	test   %edx,%edx
8010403d:	78 1d                	js     8010405c <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
8010403f:	e8 76 f1 ff ff       	call   801031ba <mycpu>
80104044:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
8010404b:	74 1c                	je     80104069 <popcli+0x4f>
    sti();
}
8010404d:	c9                   	leave  
8010404e:	c3                   	ret    
    panic("popcli - interruptible");
8010404f:	83 ec 0c             	sub    $0xc,%esp
80104052:	68 cb 70 10 80       	push   $0x801070cb
80104057:	e8 ec c2 ff ff       	call   80100348 <panic>
    panic("popcli");
8010405c:	83 ec 0c             	sub    $0xc,%esp
8010405f:	68 e2 70 10 80       	push   $0x801070e2
80104064:	e8 df c2 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80104069:	e8 4c f1 ff ff       	call   801031ba <mycpu>
8010406e:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80104075:	74 d6                	je     8010404d <popcli+0x33>
  asm volatile("sti");
80104077:	fb                   	sti    
}
80104078:	eb d3                	jmp    8010404d <popcli+0x33>

8010407a <holding>:
{
8010407a:	55                   	push   %ebp
8010407b:	89 e5                	mov    %esp,%ebp
8010407d:	53                   	push   %ebx
8010407e:	83 ec 04             	sub    $0x4,%esp
80104081:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80104084:	e8 54 ff ff ff       	call   80103fdd <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80104089:	83 3b 00             	cmpl   $0x0,(%ebx)
8010408c:	75 12                	jne    801040a0 <holding+0x26>
8010408e:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80104093:	e8 82 ff ff ff       	call   8010401a <popcli>
}
80104098:	89 d8                	mov    %ebx,%eax
8010409a:	83 c4 04             	add    $0x4,%esp
8010409d:	5b                   	pop    %ebx
8010409e:	5d                   	pop    %ebp
8010409f:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
801040a0:	8b 5b 08             	mov    0x8(%ebx),%ebx
801040a3:	e8 12 f1 ff ff       	call   801031ba <mycpu>
801040a8:	39 c3                	cmp    %eax,%ebx
801040aa:	74 07                	je     801040b3 <holding+0x39>
801040ac:	bb 00 00 00 00       	mov    $0x0,%ebx
801040b1:	eb e0                	jmp    80104093 <holding+0x19>
801040b3:	bb 01 00 00 00       	mov    $0x1,%ebx
801040b8:	eb d9                	jmp    80104093 <holding+0x19>

801040ba <acquire>:
{
801040ba:	55                   	push   %ebp
801040bb:	89 e5                	mov    %esp,%ebp
801040bd:	53                   	push   %ebx
801040be:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
801040c1:	e8 17 ff ff ff       	call   80103fdd <pushcli>
  if(holding(lk))
801040c6:	83 ec 0c             	sub    $0xc,%esp
801040c9:	ff 75 08             	pushl  0x8(%ebp)
801040cc:	e8 a9 ff ff ff       	call   8010407a <holding>
801040d1:	83 c4 10             	add    $0x10,%esp
801040d4:	85 c0                	test   %eax,%eax
801040d6:	75 3a                	jne    80104112 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
801040d8:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
801040db:	b8 01 00 00 00       	mov    $0x1,%eax
801040e0:	f0 87 02             	lock xchg %eax,(%edx)
801040e3:	85 c0                	test   %eax,%eax
801040e5:	75 f1                	jne    801040d8 <acquire+0x1e>
  __sync_synchronize();
801040e7:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
801040ec:	8b 5d 08             	mov    0x8(%ebp),%ebx
801040ef:	e8 c6 f0 ff ff       	call   801031ba <mycpu>
801040f4:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
801040f7:	8b 45 08             	mov    0x8(%ebp),%eax
801040fa:	83 c0 0c             	add    $0xc,%eax
801040fd:	83 ec 08             	sub    $0x8,%esp
80104100:	50                   	push   %eax
80104101:	8d 45 08             	lea    0x8(%ebp),%eax
80104104:	50                   	push   %eax
80104105:	e8 8f fe ff ff       	call   80103f99 <getcallerpcs>
}
8010410a:	83 c4 10             	add    $0x10,%esp
8010410d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104110:	c9                   	leave  
80104111:	c3                   	ret    
    panic("acquire");
80104112:	83 ec 0c             	sub    $0xc,%esp
80104115:	68 e9 70 10 80       	push   $0x801070e9
8010411a:	e8 29 c2 ff ff       	call   80100348 <panic>

8010411f <release>:
{
8010411f:	55                   	push   %ebp
80104120:	89 e5                	mov    %esp,%ebp
80104122:	53                   	push   %ebx
80104123:	83 ec 10             	sub    $0x10,%esp
80104126:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80104129:	53                   	push   %ebx
8010412a:	e8 4b ff ff ff       	call   8010407a <holding>
8010412f:	83 c4 10             	add    $0x10,%esp
80104132:	85 c0                	test   %eax,%eax
80104134:	74 23                	je     80104159 <release+0x3a>
  lk->pcs[0] = 0;
80104136:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
8010413d:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80104144:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80104149:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
8010414f:	e8 c6 fe ff ff       	call   8010401a <popcli>
}
80104154:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104157:	c9                   	leave  
80104158:	c3                   	ret    
    panic("release");
80104159:	83 ec 0c             	sub    $0xc,%esp
8010415c:	68 f1 70 10 80       	push   $0x801070f1
80104161:	e8 e2 c1 ff ff       	call   80100348 <panic>

80104166 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80104166:	55                   	push   %ebp
80104167:	89 e5                	mov    %esp,%ebp
80104169:	57                   	push   %edi
8010416a:	53                   	push   %ebx
8010416b:	8b 55 08             	mov    0x8(%ebp),%edx
8010416e:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80104171:	f6 c2 03             	test   $0x3,%dl
80104174:	75 05                	jne    8010417b <memset+0x15>
80104176:	f6 c1 03             	test   $0x3,%cl
80104179:	74 0e                	je     80104189 <memset+0x23>
  asm volatile("cld; rep stosb" :
8010417b:	89 d7                	mov    %edx,%edi
8010417d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104180:	fc                   	cld    
80104181:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80104183:	89 d0                	mov    %edx,%eax
80104185:	5b                   	pop    %ebx
80104186:	5f                   	pop    %edi
80104187:	5d                   	pop    %ebp
80104188:	c3                   	ret    
    c &= 0xFF;
80104189:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
8010418d:	c1 e9 02             	shr    $0x2,%ecx
80104190:	89 f8                	mov    %edi,%eax
80104192:	c1 e0 18             	shl    $0x18,%eax
80104195:	89 fb                	mov    %edi,%ebx
80104197:	c1 e3 10             	shl    $0x10,%ebx
8010419a:	09 d8                	or     %ebx,%eax
8010419c:	89 fb                	mov    %edi,%ebx
8010419e:	c1 e3 08             	shl    $0x8,%ebx
801041a1:	09 d8                	or     %ebx,%eax
801041a3:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
801041a5:	89 d7                	mov    %edx,%edi
801041a7:	fc                   	cld    
801041a8:	f3 ab                	rep stos %eax,%es:(%edi)
801041aa:	eb d7                	jmp    80104183 <memset+0x1d>

801041ac <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801041ac:	55                   	push   %ebp
801041ad:	89 e5                	mov    %esp,%ebp
801041af:	56                   	push   %esi
801041b0:	53                   	push   %ebx
801041b1:	8b 4d 08             	mov    0x8(%ebp),%ecx
801041b4:	8b 55 0c             	mov    0xc(%ebp),%edx
801041b7:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
801041ba:	8d 70 ff             	lea    -0x1(%eax),%esi
801041bd:	85 c0                	test   %eax,%eax
801041bf:	74 1c                	je     801041dd <memcmp+0x31>
    if(*s1 != *s2)
801041c1:	0f b6 01             	movzbl (%ecx),%eax
801041c4:	0f b6 1a             	movzbl (%edx),%ebx
801041c7:	38 d8                	cmp    %bl,%al
801041c9:	75 0a                	jne    801041d5 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
801041cb:	83 c1 01             	add    $0x1,%ecx
801041ce:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
801041d1:	89 f0                	mov    %esi,%eax
801041d3:	eb e5                	jmp    801041ba <memcmp+0xe>
      return *s1 - *s2;
801041d5:	0f b6 c0             	movzbl %al,%eax
801041d8:	0f b6 db             	movzbl %bl,%ebx
801041db:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
801041dd:	5b                   	pop    %ebx
801041de:	5e                   	pop    %esi
801041df:	5d                   	pop    %ebp
801041e0:	c3                   	ret    

801041e1 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801041e1:	55                   	push   %ebp
801041e2:	89 e5                	mov    %esp,%ebp
801041e4:	56                   	push   %esi
801041e5:	53                   	push   %ebx
801041e6:	8b 45 08             	mov    0x8(%ebp),%eax
801041e9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801041ec:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801041ef:	39 c1                	cmp    %eax,%ecx
801041f1:	73 3a                	jae    8010422d <memmove+0x4c>
801041f3:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
801041f6:	39 c3                	cmp    %eax,%ebx
801041f8:	76 37                	jbe    80104231 <memmove+0x50>
    s += n;
    d += n;
801041fa:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
801041fd:	eb 0d                	jmp    8010420c <memmove+0x2b>
      *--d = *--s;
801041ff:	83 eb 01             	sub    $0x1,%ebx
80104202:	83 e9 01             	sub    $0x1,%ecx
80104205:	0f b6 13             	movzbl (%ebx),%edx
80104208:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
8010420a:	89 f2                	mov    %esi,%edx
8010420c:	8d 72 ff             	lea    -0x1(%edx),%esi
8010420f:	85 d2                	test   %edx,%edx
80104211:	75 ec                	jne    801041ff <memmove+0x1e>
80104213:	eb 14                	jmp    80104229 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80104215:	0f b6 11             	movzbl (%ecx),%edx
80104218:	88 13                	mov    %dl,(%ebx)
8010421a:	8d 5b 01             	lea    0x1(%ebx),%ebx
8010421d:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80104220:	89 f2                	mov    %esi,%edx
80104222:	8d 72 ff             	lea    -0x1(%edx),%esi
80104225:	85 d2                	test   %edx,%edx
80104227:	75 ec                	jne    80104215 <memmove+0x34>

  return dst;
}
80104229:	5b                   	pop    %ebx
8010422a:	5e                   	pop    %esi
8010422b:	5d                   	pop    %ebp
8010422c:	c3                   	ret    
8010422d:	89 c3                	mov    %eax,%ebx
8010422f:	eb f1                	jmp    80104222 <memmove+0x41>
80104231:	89 c3                	mov    %eax,%ebx
80104233:	eb ed                	jmp    80104222 <memmove+0x41>

80104235 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80104235:	55                   	push   %ebp
80104236:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80104238:	ff 75 10             	pushl  0x10(%ebp)
8010423b:	ff 75 0c             	pushl  0xc(%ebp)
8010423e:	ff 75 08             	pushl  0x8(%ebp)
80104241:	e8 9b ff ff ff       	call   801041e1 <memmove>
}
80104246:	c9                   	leave  
80104247:	c3                   	ret    

80104248 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80104248:	55                   	push   %ebp
80104249:	89 e5                	mov    %esp,%ebp
8010424b:	53                   	push   %ebx
8010424c:	8b 55 08             	mov    0x8(%ebp),%edx
8010424f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80104252:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80104255:	eb 09                	jmp    80104260 <strncmp+0x18>
    n--, p++, q++;
80104257:	83 e8 01             	sub    $0x1,%eax
8010425a:	83 c2 01             	add    $0x1,%edx
8010425d:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80104260:	85 c0                	test   %eax,%eax
80104262:	74 0b                	je     8010426f <strncmp+0x27>
80104264:	0f b6 1a             	movzbl (%edx),%ebx
80104267:	84 db                	test   %bl,%bl
80104269:	74 04                	je     8010426f <strncmp+0x27>
8010426b:	3a 19                	cmp    (%ecx),%bl
8010426d:	74 e8                	je     80104257 <strncmp+0xf>
  if(n == 0)
8010426f:	85 c0                	test   %eax,%eax
80104271:	74 0b                	je     8010427e <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80104273:	0f b6 02             	movzbl (%edx),%eax
80104276:	0f b6 11             	movzbl (%ecx),%edx
80104279:	29 d0                	sub    %edx,%eax
}
8010427b:	5b                   	pop    %ebx
8010427c:	5d                   	pop    %ebp
8010427d:	c3                   	ret    
    return 0;
8010427e:	b8 00 00 00 00       	mov    $0x0,%eax
80104283:	eb f6                	jmp    8010427b <strncmp+0x33>

80104285 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80104285:	55                   	push   %ebp
80104286:	89 e5                	mov    %esp,%ebp
80104288:	57                   	push   %edi
80104289:	56                   	push   %esi
8010428a:	53                   	push   %ebx
8010428b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
8010428e:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80104291:	8b 45 08             	mov    0x8(%ebp),%eax
80104294:	eb 04                	jmp    8010429a <strncpy+0x15>
80104296:	89 fb                	mov    %edi,%ebx
80104298:	89 f0                	mov    %esi,%eax
8010429a:	8d 51 ff             	lea    -0x1(%ecx),%edx
8010429d:	85 c9                	test   %ecx,%ecx
8010429f:	7e 1d                	jle    801042be <strncpy+0x39>
801042a1:	8d 7b 01             	lea    0x1(%ebx),%edi
801042a4:	8d 70 01             	lea    0x1(%eax),%esi
801042a7:	0f b6 1b             	movzbl (%ebx),%ebx
801042aa:	88 18                	mov    %bl,(%eax)
801042ac:	89 d1                	mov    %edx,%ecx
801042ae:	84 db                	test   %bl,%bl
801042b0:	75 e4                	jne    80104296 <strncpy+0x11>
801042b2:	89 f0                	mov    %esi,%eax
801042b4:	eb 08                	jmp    801042be <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
801042b6:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
801042b9:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
801042bb:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
801042be:	8d 4a ff             	lea    -0x1(%edx),%ecx
801042c1:	85 d2                	test   %edx,%edx
801042c3:	7f f1                	jg     801042b6 <strncpy+0x31>
  return os;
}
801042c5:	8b 45 08             	mov    0x8(%ebp),%eax
801042c8:	5b                   	pop    %ebx
801042c9:	5e                   	pop    %esi
801042ca:	5f                   	pop    %edi
801042cb:	5d                   	pop    %ebp
801042cc:	c3                   	ret    

801042cd <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801042cd:	55                   	push   %ebp
801042ce:	89 e5                	mov    %esp,%ebp
801042d0:	57                   	push   %edi
801042d1:	56                   	push   %esi
801042d2:	53                   	push   %ebx
801042d3:	8b 45 08             	mov    0x8(%ebp),%eax
801042d6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801042d9:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
801042dc:	85 d2                	test   %edx,%edx
801042de:	7e 23                	jle    80104303 <safestrcpy+0x36>
801042e0:	89 c1                	mov    %eax,%ecx
801042e2:	eb 04                	jmp    801042e8 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
801042e4:	89 fb                	mov    %edi,%ebx
801042e6:	89 f1                	mov    %esi,%ecx
801042e8:	83 ea 01             	sub    $0x1,%edx
801042eb:	85 d2                	test   %edx,%edx
801042ed:	7e 11                	jle    80104300 <safestrcpy+0x33>
801042ef:	8d 7b 01             	lea    0x1(%ebx),%edi
801042f2:	8d 71 01             	lea    0x1(%ecx),%esi
801042f5:	0f b6 1b             	movzbl (%ebx),%ebx
801042f8:	88 19                	mov    %bl,(%ecx)
801042fa:	84 db                	test   %bl,%bl
801042fc:	75 e6                	jne    801042e4 <safestrcpy+0x17>
801042fe:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80104300:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80104303:	5b                   	pop    %ebx
80104304:	5e                   	pop    %esi
80104305:	5f                   	pop    %edi
80104306:	5d                   	pop    %ebp
80104307:	c3                   	ret    

80104308 <strlen>:

int
strlen(const char *s)
{
80104308:	55                   	push   %ebp
80104309:	89 e5                	mov    %esp,%ebp
8010430b:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
8010430e:	b8 00 00 00 00       	mov    $0x0,%eax
80104313:	eb 03                	jmp    80104318 <strlen+0x10>
80104315:	83 c0 01             	add    $0x1,%eax
80104318:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
8010431c:	75 f7                	jne    80104315 <strlen+0xd>
    ;
  return n;
}
8010431e:	5d                   	pop    %ebp
8010431f:	c3                   	ret    

80104320 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80104320:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80104324:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80104328:	55                   	push   %ebp
  pushl %ebx
80104329:	53                   	push   %ebx
  pushl %esi
8010432a:	56                   	push   %esi
  pushl %edi
8010432b:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010432c:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010432e:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80104330:	5f                   	pop    %edi
  popl %esi
80104331:	5e                   	pop    %esi
  popl %ebx
80104332:	5b                   	pop    %ebx
  popl %ebp
80104333:	5d                   	pop    %ebp
  ret
80104334:	c3                   	ret    

80104335 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104335:	55                   	push   %ebp
80104336:	89 e5                	mov    %esp,%ebp
80104338:	53                   	push   %ebx
80104339:	83 ec 04             	sub    $0x4,%esp
8010433c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
8010433f:	e8 ed ee ff ff       	call   80103231 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80104344:	8b 00                	mov    (%eax),%eax
80104346:	39 d8                	cmp    %ebx,%eax
80104348:	76 19                	jbe    80104363 <fetchint+0x2e>
8010434a:	8d 53 04             	lea    0x4(%ebx),%edx
8010434d:	39 d0                	cmp    %edx,%eax
8010434f:	72 19                	jb     8010436a <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80104351:	8b 13                	mov    (%ebx),%edx
80104353:	8b 45 0c             	mov    0xc(%ebp),%eax
80104356:	89 10                	mov    %edx,(%eax)
  return 0;
80104358:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010435d:	83 c4 04             	add    $0x4,%esp
80104360:	5b                   	pop    %ebx
80104361:	5d                   	pop    %ebp
80104362:	c3                   	ret    
    return -1;
80104363:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104368:	eb f3                	jmp    8010435d <fetchint+0x28>
8010436a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010436f:	eb ec                	jmp    8010435d <fetchint+0x28>

80104371 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80104371:	55                   	push   %ebp
80104372:	89 e5                	mov    %esp,%ebp
80104374:	53                   	push   %ebx
80104375:	83 ec 04             	sub    $0x4,%esp
80104378:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
8010437b:	e8 b1 ee ff ff       	call   80103231 <myproc>

  if(addr >= curproc->sz)
80104380:	39 18                	cmp    %ebx,(%eax)
80104382:	76 26                	jbe    801043aa <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80104384:	8b 55 0c             	mov    0xc(%ebp),%edx
80104387:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80104389:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
8010438b:	89 d8                	mov    %ebx,%eax
8010438d:	39 d0                	cmp    %edx,%eax
8010438f:	73 0e                	jae    8010439f <fetchstr+0x2e>
    if(*s == 0)
80104391:	80 38 00             	cmpb   $0x0,(%eax)
80104394:	74 05                	je     8010439b <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80104396:	83 c0 01             	add    $0x1,%eax
80104399:	eb f2                	jmp    8010438d <fetchstr+0x1c>
      return s - *pp;
8010439b:	29 d8                	sub    %ebx,%eax
8010439d:	eb 05                	jmp    801043a4 <fetchstr+0x33>
  }
  return -1;
8010439f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801043a4:	83 c4 04             	add    $0x4,%esp
801043a7:	5b                   	pop    %ebx
801043a8:	5d                   	pop    %ebp
801043a9:	c3                   	ret    
    return -1;
801043aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043af:	eb f3                	jmp    801043a4 <fetchstr+0x33>

801043b1 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801043b1:	55                   	push   %ebp
801043b2:	89 e5                	mov    %esp,%ebp
801043b4:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801043b7:	e8 75 ee ff ff       	call   80103231 <myproc>
801043bc:	8b 50 18             	mov    0x18(%eax),%edx
801043bf:	8b 45 08             	mov    0x8(%ebp),%eax
801043c2:	c1 e0 02             	shl    $0x2,%eax
801043c5:	03 42 44             	add    0x44(%edx),%eax
801043c8:	83 ec 08             	sub    $0x8,%esp
801043cb:	ff 75 0c             	pushl  0xc(%ebp)
801043ce:	83 c0 04             	add    $0x4,%eax
801043d1:	50                   	push   %eax
801043d2:	e8 5e ff ff ff       	call   80104335 <fetchint>
}
801043d7:	c9                   	leave  
801043d8:	c3                   	ret    

801043d9 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801043d9:	55                   	push   %ebp
801043da:	89 e5                	mov    %esp,%ebp
801043dc:	56                   	push   %esi
801043dd:	53                   	push   %ebx
801043de:	83 ec 10             	sub    $0x10,%esp
801043e1:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
801043e4:	e8 48 ee ff ff       	call   80103231 <myproc>
801043e9:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
801043eb:	83 ec 08             	sub    $0x8,%esp
801043ee:	8d 45 f4             	lea    -0xc(%ebp),%eax
801043f1:	50                   	push   %eax
801043f2:	ff 75 08             	pushl  0x8(%ebp)
801043f5:	e8 b7 ff ff ff       	call   801043b1 <argint>
801043fa:	83 c4 10             	add    $0x10,%esp
801043fd:	85 c0                	test   %eax,%eax
801043ff:	78 24                	js     80104425 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104401:	85 db                	test   %ebx,%ebx
80104403:	78 27                	js     8010442c <argptr+0x53>
80104405:	8b 16                	mov    (%esi),%edx
80104407:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010440a:	39 c2                	cmp    %eax,%edx
8010440c:	76 25                	jbe    80104433 <argptr+0x5a>
8010440e:	01 c3                	add    %eax,%ebx
80104410:	39 da                	cmp    %ebx,%edx
80104412:	72 26                	jb     8010443a <argptr+0x61>
    return -1;
  *pp = (char*)i;
80104414:	8b 55 0c             	mov    0xc(%ebp),%edx
80104417:	89 02                	mov    %eax,(%edx)
  return 0;
80104419:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010441e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104421:	5b                   	pop    %ebx
80104422:	5e                   	pop    %esi
80104423:	5d                   	pop    %ebp
80104424:	c3                   	ret    
    return -1;
80104425:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010442a:	eb f2                	jmp    8010441e <argptr+0x45>
    return -1;
8010442c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104431:	eb eb                	jmp    8010441e <argptr+0x45>
80104433:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104438:	eb e4                	jmp    8010441e <argptr+0x45>
8010443a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010443f:	eb dd                	jmp    8010441e <argptr+0x45>

80104441 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104441:	55                   	push   %ebp
80104442:	89 e5                	mov    %esp,%ebp
80104444:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104447:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010444a:	50                   	push   %eax
8010444b:	ff 75 08             	pushl  0x8(%ebp)
8010444e:	e8 5e ff ff ff       	call   801043b1 <argint>
80104453:	83 c4 10             	add    $0x10,%esp
80104456:	85 c0                	test   %eax,%eax
80104458:	78 13                	js     8010446d <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
8010445a:	83 ec 08             	sub    $0x8,%esp
8010445d:	ff 75 0c             	pushl  0xc(%ebp)
80104460:	ff 75 f4             	pushl  -0xc(%ebp)
80104463:	e8 09 ff ff ff       	call   80104371 <fetchstr>
80104468:	83 c4 10             	add    $0x10,%esp
}
8010446b:	c9                   	leave  
8010446c:	c3                   	ret    
    return -1;
8010446d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104472:	eb f7                	jmp    8010446b <argstr+0x2a>

80104474 <syscall>:
[SYS_getpinfo] sys_getpinfo,
};

void
syscall(void)
{
80104474:	55                   	push   %ebp
80104475:	89 e5                	mov    %esp,%ebp
80104477:	53                   	push   %ebx
80104478:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
8010447b:	e8 b1 ed ff ff       	call   80103231 <myproc>
80104480:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104482:	8b 40 18             	mov    0x18(%eax),%eax
80104485:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80104488:	8d 50 ff             	lea    -0x1(%eax),%edx
8010448b:	83 fa 18             	cmp    $0x18,%edx
8010448e:	77 18                	ja     801044a8 <syscall+0x34>
80104490:	8b 14 85 20 71 10 80 	mov    -0x7fef8ee0(,%eax,4),%edx
80104497:	85 d2                	test   %edx,%edx
80104499:	74 0d                	je     801044a8 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
8010449b:	ff d2                	call   *%edx
8010449d:	8b 53 18             	mov    0x18(%ebx),%edx
801044a0:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
801044a3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801044a6:	c9                   	leave  
801044a7:	c3                   	ret    
            curproc->pid, curproc->name, num);
801044a8:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801044ab:	50                   	push   %eax
801044ac:	52                   	push   %edx
801044ad:	ff 73 10             	pushl  0x10(%ebx)
801044b0:	68 f9 70 10 80       	push   $0x801070f9
801044b5:	e8 51 c1 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
801044ba:	8b 43 18             	mov    0x18(%ebx),%eax
801044bd:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
801044c4:	83 c4 10             	add    $0x10,%esp
}
801044c7:	eb da                	jmp    801044a3 <syscall+0x2f>

801044c9 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801044c9:	55                   	push   %ebp
801044ca:	89 e5                	mov    %esp,%ebp
801044cc:	56                   	push   %esi
801044cd:	53                   	push   %ebx
801044ce:	83 ec 18             	sub    $0x18,%esp
801044d1:	89 d6                	mov    %edx,%esi
801044d3:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801044d5:	8d 55 f4             	lea    -0xc(%ebp),%edx
801044d8:	52                   	push   %edx
801044d9:	50                   	push   %eax
801044da:	e8 d2 fe ff ff       	call   801043b1 <argint>
801044df:	83 c4 10             	add    $0x10,%esp
801044e2:	85 c0                	test   %eax,%eax
801044e4:	78 2e                	js     80104514 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801044e6:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801044ea:	77 2f                	ja     8010451b <argfd+0x52>
801044ec:	e8 40 ed ff ff       	call   80103231 <myproc>
801044f1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044f4:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
801044f8:	85 c0                	test   %eax,%eax
801044fa:	74 26                	je     80104522 <argfd+0x59>
    return -1;
  if(pfd)
801044fc:	85 f6                	test   %esi,%esi
801044fe:	74 02                	je     80104502 <argfd+0x39>
    *pfd = fd;
80104500:	89 16                	mov    %edx,(%esi)
  if(pf)
80104502:	85 db                	test   %ebx,%ebx
80104504:	74 23                	je     80104529 <argfd+0x60>
    *pf = f;
80104506:	89 03                	mov    %eax,(%ebx)
  return 0;
80104508:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010450d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104510:	5b                   	pop    %ebx
80104511:	5e                   	pop    %esi
80104512:	5d                   	pop    %ebp
80104513:	c3                   	ret    
    return -1;
80104514:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104519:	eb f2                	jmp    8010450d <argfd+0x44>
    return -1;
8010451b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104520:	eb eb                	jmp    8010450d <argfd+0x44>
80104522:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104527:	eb e4                	jmp    8010450d <argfd+0x44>
  return 0;
80104529:	b8 00 00 00 00       	mov    $0x0,%eax
8010452e:	eb dd                	jmp    8010450d <argfd+0x44>

80104530 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104530:	55                   	push   %ebp
80104531:	89 e5                	mov    %esp,%ebp
80104533:	53                   	push   %ebx
80104534:	83 ec 04             	sub    $0x4,%esp
80104537:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
80104539:	e8 f3 ec ff ff       	call   80103231 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
8010453e:	ba 00 00 00 00       	mov    $0x0,%edx
80104543:	83 fa 0f             	cmp    $0xf,%edx
80104546:	7f 18                	jg     80104560 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
80104548:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
8010454d:	74 05                	je     80104554 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
8010454f:	83 c2 01             	add    $0x1,%edx
80104552:	eb ef                	jmp    80104543 <fdalloc+0x13>
      curproc->ofile[fd] = f;
80104554:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
80104558:	89 d0                	mov    %edx,%eax
8010455a:	83 c4 04             	add    $0x4,%esp
8010455d:	5b                   	pop    %ebx
8010455e:	5d                   	pop    %ebp
8010455f:	c3                   	ret    
  return -1;
80104560:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104565:	eb f1                	jmp    80104558 <fdalloc+0x28>

80104567 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104567:	55                   	push   %ebp
80104568:	89 e5                	mov    %esp,%ebp
8010456a:	56                   	push   %esi
8010456b:	53                   	push   %ebx
8010456c:	83 ec 10             	sub    $0x10,%esp
8010456f:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104571:	b8 20 00 00 00       	mov    $0x20,%eax
80104576:	89 c6                	mov    %eax,%esi
80104578:	39 43 58             	cmp    %eax,0x58(%ebx)
8010457b:	76 2e                	jbe    801045ab <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010457d:	6a 10                	push   $0x10
8010457f:	50                   	push   %eax
80104580:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104583:	50                   	push   %eax
80104584:	53                   	push   %ebx
80104585:	e8 e9 d1 ff ff       	call   80101773 <readi>
8010458a:	83 c4 10             	add    $0x10,%esp
8010458d:	83 f8 10             	cmp    $0x10,%eax
80104590:	75 0c                	jne    8010459e <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104592:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104597:	75 1e                	jne    801045b7 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104599:	8d 46 10             	lea    0x10(%esi),%eax
8010459c:	eb d8                	jmp    80104576 <isdirempty+0xf>
      panic("isdirempty: readi");
8010459e:	83 ec 0c             	sub    $0xc,%esp
801045a1:	68 88 71 10 80       	push   $0x80107188
801045a6:	e8 9d bd ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801045ab:	b8 01 00 00 00       	mov    $0x1,%eax
}
801045b0:	8d 65 f8             	lea    -0x8(%ebp),%esp
801045b3:	5b                   	pop    %ebx
801045b4:	5e                   	pop    %esi
801045b5:	5d                   	pop    %ebp
801045b6:	c3                   	ret    
      return 0;
801045b7:	b8 00 00 00 00       	mov    $0x0,%eax
801045bc:	eb f2                	jmp    801045b0 <isdirempty+0x49>

801045be <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801045be:	55                   	push   %ebp
801045bf:	89 e5                	mov    %esp,%ebp
801045c1:	57                   	push   %edi
801045c2:	56                   	push   %esi
801045c3:	53                   	push   %ebx
801045c4:	83 ec 44             	sub    $0x44,%esp
801045c7:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801045ca:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801045cd:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801045d0:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801045d3:	52                   	push   %edx
801045d4:	50                   	push   %eax
801045d5:	e8 1f d6 ff ff       	call   80101bf9 <nameiparent>
801045da:	89 c6                	mov    %eax,%esi
801045dc:	83 c4 10             	add    $0x10,%esp
801045df:	85 c0                	test   %eax,%eax
801045e1:	0f 84 3a 01 00 00    	je     80104721 <create+0x163>
    return 0;
  ilock(dp);
801045e7:	83 ec 0c             	sub    $0xc,%esp
801045ea:	50                   	push   %eax
801045eb:	e8 91 cf ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801045f0:	83 c4 0c             	add    $0xc,%esp
801045f3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801045f6:	50                   	push   %eax
801045f7:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801045fa:	50                   	push   %eax
801045fb:	56                   	push   %esi
801045fc:	e8 af d3 ff ff       	call   801019b0 <dirlookup>
80104601:	89 c3                	mov    %eax,%ebx
80104603:	83 c4 10             	add    $0x10,%esp
80104606:	85 c0                	test   %eax,%eax
80104608:	74 3f                	je     80104649 <create+0x8b>
    iunlockput(dp);
8010460a:	83 ec 0c             	sub    $0xc,%esp
8010460d:	56                   	push   %esi
8010460e:	e8 15 d1 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
80104613:	89 1c 24             	mov    %ebx,(%esp)
80104616:	e8 66 cf ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010461b:	83 c4 10             	add    $0x10,%esp
8010461e:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104623:	75 11                	jne    80104636 <create+0x78>
80104625:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
8010462a:	75 0a                	jne    80104636 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
8010462c:	89 d8                	mov    %ebx,%eax
8010462e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104631:	5b                   	pop    %ebx
80104632:	5e                   	pop    %esi
80104633:	5f                   	pop    %edi
80104634:	5d                   	pop    %ebp
80104635:	c3                   	ret    
    iunlockput(ip);
80104636:	83 ec 0c             	sub    $0xc,%esp
80104639:	53                   	push   %ebx
8010463a:	e8 e9 d0 ff ff       	call   80101728 <iunlockput>
    return 0;
8010463f:	83 c4 10             	add    $0x10,%esp
80104642:	bb 00 00 00 00       	mov    $0x0,%ebx
80104647:	eb e3                	jmp    8010462c <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
80104649:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
8010464d:	83 ec 08             	sub    $0x8,%esp
80104650:	50                   	push   %eax
80104651:	ff 36                	pushl  (%esi)
80104653:	e8 26 cd ff ff       	call   8010137e <ialloc>
80104658:	89 c3                	mov    %eax,%ebx
8010465a:	83 c4 10             	add    $0x10,%esp
8010465d:	85 c0                	test   %eax,%eax
8010465f:	74 55                	je     801046b6 <create+0xf8>
  ilock(ip);
80104661:	83 ec 0c             	sub    $0xc,%esp
80104664:	50                   	push   %eax
80104665:	e8 17 cf ff ff       	call   80101581 <ilock>
  ip->major = major;
8010466a:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
8010466e:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104672:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104676:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
8010467c:	89 1c 24             	mov    %ebx,(%esp)
8010467f:	e8 9c cd ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104684:	83 c4 10             	add    $0x10,%esp
80104687:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
8010468c:	74 35                	je     801046c3 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
8010468e:	83 ec 04             	sub    $0x4,%esp
80104691:	ff 73 04             	pushl  0x4(%ebx)
80104694:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104697:	50                   	push   %eax
80104698:	56                   	push   %esi
80104699:	e8 92 d4 ff ff       	call   80101b30 <dirlink>
8010469e:	83 c4 10             	add    $0x10,%esp
801046a1:	85 c0                	test   %eax,%eax
801046a3:	78 6f                	js     80104714 <create+0x156>
  iunlockput(dp);
801046a5:	83 ec 0c             	sub    $0xc,%esp
801046a8:	56                   	push   %esi
801046a9:	e8 7a d0 ff ff       	call   80101728 <iunlockput>
  return ip;
801046ae:	83 c4 10             	add    $0x10,%esp
801046b1:	e9 76 ff ff ff       	jmp    8010462c <create+0x6e>
    panic("create: ialloc");
801046b6:	83 ec 0c             	sub    $0xc,%esp
801046b9:	68 9a 71 10 80       	push   $0x8010719a
801046be:	e8 85 bc ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
801046c3:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801046c7:	83 c0 01             	add    $0x1,%eax
801046ca:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801046ce:	83 ec 0c             	sub    $0xc,%esp
801046d1:	56                   	push   %esi
801046d2:	e8 49 cd ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801046d7:	83 c4 0c             	add    $0xc,%esp
801046da:	ff 73 04             	pushl  0x4(%ebx)
801046dd:	68 aa 71 10 80       	push   $0x801071aa
801046e2:	53                   	push   %ebx
801046e3:	e8 48 d4 ff ff       	call   80101b30 <dirlink>
801046e8:	83 c4 10             	add    $0x10,%esp
801046eb:	85 c0                	test   %eax,%eax
801046ed:	78 18                	js     80104707 <create+0x149>
801046ef:	83 ec 04             	sub    $0x4,%esp
801046f2:	ff 76 04             	pushl  0x4(%esi)
801046f5:	68 a9 71 10 80       	push   $0x801071a9
801046fa:	53                   	push   %ebx
801046fb:	e8 30 d4 ff ff       	call   80101b30 <dirlink>
80104700:	83 c4 10             	add    $0x10,%esp
80104703:	85 c0                	test   %eax,%eax
80104705:	79 87                	jns    8010468e <create+0xd0>
      panic("create dots");
80104707:	83 ec 0c             	sub    $0xc,%esp
8010470a:	68 ac 71 10 80       	push   $0x801071ac
8010470f:	e8 34 bc ff ff       	call   80100348 <panic>
    panic("create: dirlink");
80104714:	83 ec 0c             	sub    $0xc,%esp
80104717:	68 b8 71 10 80       	push   $0x801071b8
8010471c:	e8 27 bc ff ff       	call   80100348 <panic>
    return 0;
80104721:	89 c3                	mov    %eax,%ebx
80104723:	e9 04 ff ff ff       	jmp    8010462c <create+0x6e>

80104728 <sys_dup>:
{
80104728:	55                   	push   %ebp
80104729:	89 e5                	mov    %esp,%ebp
8010472b:	53                   	push   %ebx
8010472c:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
8010472f:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104732:	ba 00 00 00 00       	mov    $0x0,%edx
80104737:	b8 00 00 00 00       	mov    $0x0,%eax
8010473c:	e8 88 fd ff ff       	call   801044c9 <argfd>
80104741:	85 c0                	test   %eax,%eax
80104743:	78 23                	js     80104768 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104745:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104748:	e8 e3 fd ff ff       	call   80104530 <fdalloc>
8010474d:	89 c3                	mov    %eax,%ebx
8010474f:	85 c0                	test   %eax,%eax
80104751:	78 1c                	js     8010476f <sys_dup+0x47>
  filedup(f);
80104753:	83 ec 0c             	sub    $0xc,%esp
80104756:	ff 75 f4             	pushl  -0xc(%ebp)
80104759:	e8 30 c5 ff ff       	call   80100c8e <filedup>
  return fd;
8010475e:	83 c4 10             	add    $0x10,%esp
}
80104761:	89 d8                	mov    %ebx,%eax
80104763:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104766:	c9                   	leave  
80104767:	c3                   	ret    
    return -1;
80104768:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010476d:	eb f2                	jmp    80104761 <sys_dup+0x39>
    return -1;
8010476f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104774:	eb eb                	jmp    80104761 <sys_dup+0x39>

80104776 <sys_read>:
{
80104776:	55                   	push   %ebp
80104777:	89 e5                	mov    %esp,%ebp
80104779:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010477c:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010477f:	ba 00 00 00 00       	mov    $0x0,%edx
80104784:	b8 00 00 00 00       	mov    $0x0,%eax
80104789:	e8 3b fd ff ff       	call   801044c9 <argfd>
8010478e:	85 c0                	test   %eax,%eax
80104790:	78 43                	js     801047d5 <sys_read+0x5f>
80104792:	83 ec 08             	sub    $0x8,%esp
80104795:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104798:	50                   	push   %eax
80104799:	6a 02                	push   $0x2
8010479b:	e8 11 fc ff ff       	call   801043b1 <argint>
801047a0:	83 c4 10             	add    $0x10,%esp
801047a3:	85 c0                	test   %eax,%eax
801047a5:	78 35                	js     801047dc <sys_read+0x66>
801047a7:	83 ec 04             	sub    $0x4,%esp
801047aa:	ff 75 f0             	pushl  -0x10(%ebp)
801047ad:	8d 45 ec             	lea    -0x14(%ebp),%eax
801047b0:	50                   	push   %eax
801047b1:	6a 01                	push   $0x1
801047b3:	e8 21 fc ff ff       	call   801043d9 <argptr>
801047b8:	83 c4 10             	add    $0x10,%esp
801047bb:	85 c0                	test   %eax,%eax
801047bd:	78 24                	js     801047e3 <sys_read+0x6d>
  return fileread(f, p, n);
801047bf:	83 ec 04             	sub    $0x4,%esp
801047c2:	ff 75 f0             	pushl  -0x10(%ebp)
801047c5:	ff 75 ec             	pushl  -0x14(%ebp)
801047c8:	ff 75 f4             	pushl  -0xc(%ebp)
801047cb:	e8 07 c6 ff ff       	call   80100dd7 <fileread>
801047d0:	83 c4 10             	add    $0x10,%esp
}
801047d3:	c9                   	leave  
801047d4:	c3                   	ret    
    return -1;
801047d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047da:	eb f7                	jmp    801047d3 <sys_read+0x5d>
801047dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047e1:	eb f0                	jmp    801047d3 <sys_read+0x5d>
801047e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047e8:	eb e9                	jmp    801047d3 <sys_read+0x5d>

801047ea <sys_write>:
{
801047ea:	55                   	push   %ebp
801047eb:	89 e5                	mov    %esp,%ebp
801047ed:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801047f0:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801047f3:	ba 00 00 00 00       	mov    $0x0,%edx
801047f8:	b8 00 00 00 00       	mov    $0x0,%eax
801047fd:	e8 c7 fc ff ff       	call   801044c9 <argfd>
80104802:	85 c0                	test   %eax,%eax
80104804:	78 43                	js     80104849 <sys_write+0x5f>
80104806:	83 ec 08             	sub    $0x8,%esp
80104809:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010480c:	50                   	push   %eax
8010480d:	6a 02                	push   $0x2
8010480f:	e8 9d fb ff ff       	call   801043b1 <argint>
80104814:	83 c4 10             	add    $0x10,%esp
80104817:	85 c0                	test   %eax,%eax
80104819:	78 35                	js     80104850 <sys_write+0x66>
8010481b:	83 ec 04             	sub    $0x4,%esp
8010481e:	ff 75 f0             	pushl  -0x10(%ebp)
80104821:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104824:	50                   	push   %eax
80104825:	6a 01                	push   $0x1
80104827:	e8 ad fb ff ff       	call   801043d9 <argptr>
8010482c:	83 c4 10             	add    $0x10,%esp
8010482f:	85 c0                	test   %eax,%eax
80104831:	78 24                	js     80104857 <sys_write+0x6d>
  return filewrite(f, p, n);
80104833:	83 ec 04             	sub    $0x4,%esp
80104836:	ff 75 f0             	pushl  -0x10(%ebp)
80104839:	ff 75 ec             	pushl  -0x14(%ebp)
8010483c:	ff 75 f4             	pushl  -0xc(%ebp)
8010483f:	e8 18 c6 ff ff       	call   80100e5c <filewrite>
80104844:	83 c4 10             	add    $0x10,%esp
}
80104847:	c9                   	leave  
80104848:	c3                   	ret    
    return -1;
80104849:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010484e:	eb f7                	jmp    80104847 <sys_write+0x5d>
80104850:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104855:	eb f0                	jmp    80104847 <sys_write+0x5d>
80104857:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010485c:	eb e9                	jmp    80104847 <sys_write+0x5d>

8010485e <sys_close>:
{
8010485e:	55                   	push   %ebp
8010485f:	89 e5                	mov    %esp,%ebp
80104861:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104864:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104867:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010486a:	b8 00 00 00 00       	mov    $0x0,%eax
8010486f:	e8 55 fc ff ff       	call   801044c9 <argfd>
80104874:	85 c0                	test   %eax,%eax
80104876:	78 25                	js     8010489d <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
80104878:	e8 b4 e9 ff ff       	call   80103231 <myproc>
8010487d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104880:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104887:	00 
  fileclose(f);
80104888:	83 ec 0c             	sub    $0xc,%esp
8010488b:	ff 75 f0             	pushl  -0x10(%ebp)
8010488e:	e8 40 c4 ff ff       	call   80100cd3 <fileclose>
  return 0;
80104893:	83 c4 10             	add    $0x10,%esp
80104896:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010489b:	c9                   	leave  
8010489c:	c3                   	ret    
    return -1;
8010489d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048a2:	eb f7                	jmp    8010489b <sys_close+0x3d>

801048a4 <sys_fstat>:
{
801048a4:	55                   	push   %ebp
801048a5:	89 e5                	mov    %esp,%ebp
801048a7:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801048aa:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801048ad:	ba 00 00 00 00       	mov    $0x0,%edx
801048b2:	b8 00 00 00 00       	mov    $0x0,%eax
801048b7:	e8 0d fc ff ff       	call   801044c9 <argfd>
801048bc:	85 c0                	test   %eax,%eax
801048be:	78 2a                	js     801048ea <sys_fstat+0x46>
801048c0:	83 ec 04             	sub    $0x4,%esp
801048c3:	6a 14                	push   $0x14
801048c5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801048c8:	50                   	push   %eax
801048c9:	6a 01                	push   $0x1
801048cb:	e8 09 fb ff ff       	call   801043d9 <argptr>
801048d0:	83 c4 10             	add    $0x10,%esp
801048d3:	85 c0                	test   %eax,%eax
801048d5:	78 1a                	js     801048f1 <sys_fstat+0x4d>
  return filestat(f, st);
801048d7:	83 ec 08             	sub    $0x8,%esp
801048da:	ff 75 f0             	pushl  -0x10(%ebp)
801048dd:	ff 75 f4             	pushl  -0xc(%ebp)
801048e0:	e8 ab c4 ff ff       	call   80100d90 <filestat>
801048e5:	83 c4 10             	add    $0x10,%esp
}
801048e8:	c9                   	leave  
801048e9:	c3                   	ret    
    return -1;
801048ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048ef:	eb f7                	jmp    801048e8 <sys_fstat+0x44>
801048f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048f6:	eb f0                	jmp    801048e8 <sys_fstat+0x44>

801048f8 <sys_link>:
{
801048f8:	55                   	push   %ebp
801048f9:	89 e5                	mov    %esp,%ebp
801048fb:	56                   	push   %esi
801048fc:	53                   	push   %ebx
801048fd:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104900:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104903:	50                   	push   %eax
80104904:	6a 00                	push   $0x0
80104906:	e8 36 fb ff ff       	call   80104441 <argstr>
8010490b:	83 c4 10             	add    $0x10,%esp
8010490e:	85 c0                	test   %eax,%eax
80104910:	0f 88 32 01 00 00    	js     80104a48 <sys_link+0x150>
80104916:	83 ec 08             	sub    $0x8,%esp
80104919:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010491c:	50                   	push   %eax
8010491d:	6a 01                	push   $0x1
8010491f:	e8 1d fb ff ff       	call   80104441 <argstr>
80104924:	83 c4 10             	add    $0x10,%esp
80104927:	85 c0                	test   %eax,%eax
80104929:	0f 88 20 01 00 00    	js     80104a4f <sys_link+0x157>
  begin_op();
8010492f:	e8 7a de ff ff       	call   801027ae <begin_op>
  if((ip = namei(old)) == 0){
80104934:	83 ec 0c             	sub    $0xc,%esp
80104937:	ff 75 e0             	pushl  -0x20(%ebp)
8010493a:	e8 a2 d2 ff ff       	call   80101be1 <namei>
8010493f:	89 c3                	mov    %eax,%ebx
80104941:	83 c4 10             	add    $0x10,%esp
80104944:	85 c0                	test   %eax,%eax
80104946:	0f 84 99 00 00 00    	je     801049e5 <sys_link+0xed>
  ilock(ip);
8010494c:	83 ec 0c             	sub    $0xc,%esp
8010494f:	50                   	push   %eax
80104950:	e8 2c cc ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
80104955:	83 c4 10             	add    $0x10,%esp
80104958:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010495d:	0f 84 8e 00 00 00    	je     801049f1 <sys_link+0xf9>
  ip->nlink++;
80104963:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104967:	83 c0 01             	add    $0x1,%eax
8010496a:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010496e:	83 ec 0c             	sub    $0xc,%esp
80104971:	53                   	push   %ebx
80104972:	e8 a9 ca ff ff       	call   80101420 <iupdate>
  iunlock(ip);
80104977:	89 1c 24             	mov    %ebx,(%esp)
8010497a:	e8 c4 cc ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
8010497f:	83 c4 08             	add    $0x8,%esp
80104982:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104985:	50                   	push   %eax
80104986:	ff 75 e4             	pushl  -0x1c(%ebp)
80104989:	e8 6b d2 ff ff       	call   80101bf9 <nameiparent>
8010498e:	89 c6                	mov    %eax,%esi
80104990:	83 c4 10             	add    $0x10,%esp
80104993:	85 c0                	test   %eax,%eax
80104995:	74 7e                	je     80104a15 <sys_link+0x11d>
  ilock(dp);
80104997:	83 ec 0c             	sub    $0xc,%esp
8010499a:	50                   	push   %eax
8010499b:	e8 e1 cb ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801049a0:	83 c4 10             	add    $0x10,%esp
801049a3:	8b 03                	mov    (%ebx),%eax
801049a5:	39 06                	cmp    %eax,(%esi)
801049a7:	75 60                	jne    80104a09 <sys_link+0x111>
801049a9:	83 ec 04             	sub    $0x4,%esp
801049ac:	ff 73 04             	pushl  0x4(%ebx)
801049af:	8d 45 ea             	lea    -0x16(%ebp),%eax
801049b2:	50                   	push   %eax
801049b3:	56                   	push   %esi
801049b4:	e8 77 d1 ff ff       	call   80101b30 <dirlink>
801049b9:	83 c4 10             	add    $0x10,%esp
801049bc:	85 c0                	test   %eax,%eax
801049be:	78 49                	js     80104a09 <sys_link+0x111>
  iunlockput(dp);
801049c0:	83 ec 0c             	sub    $0xc,%esp
801049c3:	56                   	push   %esi
801049c4:	e8 5f cd ff ff       	call   80101728 <iunlockput>
  iput(ip);
801049c9:	89 1c 24             	mov    %ebx,(%esp)
801049cc:	e8 b7 cc ff ff       	call   80101688 <iput>
  end_op();
801049d1:	e8 52 de ff ff       	call   80102828 <end_op>
  return 0;
801049d6:	83 c4 10             	add    $0x10,%esp
801049d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049de:	8d 65 f8             	lea    -0x8(%ebp),%esp
801049e1:	5b                   	pop    %ebx
801049e2:	5e                   	pop    %esi
801049e3:	5d                   	pop    %ebp
801049e4:	c3                   	ret    
    end_op();
801049e5:	e8 3e de ff ff       	call   80102828 <end_op>
    return -1;
801049ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049ef:	eb ed                	jmp    801049de <sys_link+0xe6>
    iunlockput(ip);
801049f1:	83 ec 0c             	sub    $0xc,%esp
801049f4:	53                   	push   %ebx
801049f5:	e8 2e cd ff ff       	call   80101728 <iunlockput>
    end_op();
801049fa:	e8 29 de ff ff       	call   80102828 <end_op>
    return -1;
801049ff:	83 c4 10             	add    $0x10,%esp
80104a02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a07:	eb d5                	jmp    801049de <sys_link+0xe6>
    iunlockput(dp);
80104a09:	83 ec 0c             	sub    $0xc,%esp
80104a0c:	56                   	push   %esi
80104a0d:	e8 16 cd ff ff       	call   80101728 <iunlockput>
    goto bad;
80104a12:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104a15:	83 ec 0c             	sub    $0xc,%esp
80104a18:	53                   	push   %ebx
80104a19:	e8 63 cb ff ff       	call   80101581 <ilock>
  ip->nlink--;
80104a1e:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104a22:	83 e8 01             	sub    $0x1,%eax
80104a25:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104a29:	89 1c 24             	mov    %ebx,(%esp)
80104a2c:	e8 ef c9 ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104a31:	89 1c 24             	mov    %ebx,(%esp)
80104a34:	e8 ef cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104a39:	e8 ea dd ff ff       	call   80102828 <end_op>
  return -1;
80104a3e:	83 c4 10             	add    $0x10,%esp
80104a41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a46:	eb 96                	jmp    801049de <sys_link+0xe6>
    return -1;
80104a48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a4d:	eb 8f                	jmp    801049de <sys_link+0xe6>
80104a4f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a54:	eb 88                	jmp    801049de <sys_link+0xe6>

80104a56 <sys_unlink>:
{
80104a56:	55                   	push   %ebp
80104a57:	89 e5                	mov    %esp,%ebp
80104a59:	57                   	push   %edi
80104a5a:	56                   	push   %esi
80104a5b:	53                   	push   %ebx
80104a5c:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104a5f:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104a62:	50                   	push   %eax
80104a63:	6a 00                	push   $0x0
80104a65:	e8 d7 f9 ff ff       	call   80104441 <argstr>
80104a6a:	83 c4 10             	add    $0x10,%esp
80104a6d:	85 c0                	test   %eax,%eax
80104a6f:	0f 88 83 01 00 00    	js     80104bf8 <sys_unlink+0x1a2>
  begin_op();
80104a75:	e8 34 dd ff ff       	call   801027ae <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104a7a:	83 ec 08             	sub    $0x8,%esp
80104a7d:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104a80:	50                   	push   %eax
80104a81:	ff 75 c4             	pushl  -0x3c(%ebp)
80104a84:	e8 70 d1 ff ff       	call   80101bf9 <nameiparent>
80104a89:	89 c6                	mov    %eax,%esi
80104a8b:	83 c4 10             	add    $0x10,%esp
80104a8e:	85 c0                	test   %eax,%eax
80104a90:	0f 84 ed 00 00 00    	je     80104b83 <sys_unlink+0x12d>
  ilock(dp);
80104a96:	83 ec 0c             	sub    $0xc,%esp
80104a99:	50                   	push   %eax
80104a9a:	e8 e2 ca ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104a9f:	83 c4 08             	add    $0x8,%esp
80104aa2:	68 aa 71 10 80       	push   $0x801071aa
80104aa7:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104aaa:	50                   	push   %eax
80104aab:	e8 eb ce ff ff       	call   8010199b <namecmp>
80104ab0:	83 c4 10             	add    $0x10,%esp
80104ab3:	85 c0                	test   %eax,%eax
80104ab5:	0f 84 fc 00 00 00    	je     80104bb7 <sys_unlink+0x161>
80104abb:	83 ec 08             	sub    $0x8,%esp
80104abe:	68 a9 71 10 80       	push   $0x801071a9
80104ac3:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104ac6:	50                   	push   %eax
80104ac7:	e8 cf ce ff ff       	call   8010199b <namecmp>
80104acc:	83 c4 10             	add    $0x10,%esp
80104acf:	85 c0                	test   %eax,%eax
80104ad1:	0f 84 e0 00 00 00    	je     80104bb7 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104ad7:	83 ec 04             	sub    $0x4,%esp
80104ada:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104add:	50                   	push   %eax
80104ade:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104ae1:	50                   	push   %eax
80104ae2:	56                   	push   %esi
80104ae3:	e8 c8 ce ff ff       	call   801019b0 <dirlookup>
80104ae8:	89 c3                	mov    %eax,%ebx
80104aea:	83 c4 10             	add    $0x10,%esp
80104aed:	85 c0                	test   %eax,%eax
80104aef:	0f 84 c2 00 00 00    	je     80104bb7 <sys_unlink+0x161>
  ilock(ip);
80104af5:	83 ec 0c             	sub    $0xc,%esp
80104af8:	50                   	push   %eax
80104af9:	e8 83 ca ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
80104afe:	83 c4 10             	add    $0x10,%esp
80104b01:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104b06:	0f 8e 83 00 00 00    	jle    80104b8f <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104b0c:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104b11:	0f 84 85 00 00 00    	je     80104b9c <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104b17:	83 ec 04             	sub    $0x4,%esp
80104b1a:	6a 10                	push   $0x10
80104b1c:	6a 00                	push   $0x0
80104b1e:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104b21:	57                   	push   %edi
80104b22:	e8 3f f6 ff ff       	call   80104166 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104b27:	6a 10                	push   $0x10
80104b29:	ff 75 c0             	pushl  -0x40(%ebp)
80104b2c:	57                   	push   %edi
80104b2d:	56                   	push   %esi
80104b2e:	e8 3d cd ff ff       	call   80101870 <writei>
80104b33:	83 c4 20             	add    $0x20,%esp
80104b36:	83 f8 10             	cmp    $0x10,%eax
80104b39:	0f 85 90 00 00 00    	jne    80104bcf <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104b3f:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104b44:	0f 84 92 00 00 00    	je     80104bdc <sys_unlink+0x186>
  iunlockput(dp);
80104b4a:	83 ec 0c             	sub    $0xc,%esp
80104b4d:	56                   	push   %esi
80104b4e:	e8 d5 cb ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
80104b53:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104b57:	83 e8 01             	sub    $0x1,%eax
80104b5a:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104b5e:	89 1c 24             	mov    %ebx,(%esp)
80104b61:	e8 ba c8 ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104b66:	89 1c 24             	mov    %ebx,(%esp)
80104b69:	e8 ba cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104b6e:	e8 b5 dc ff ff       	call   80102828 <end_op>
  return 0;
80104b73:	83 c4 10             	add    $0x10,%esp
80104b76:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b7b:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104b7e:	5b                   	pop    %ebx
80104b7f:	5e                   	pop    %esi
80104b80:	5f                   	pop    %edi
80104b81:	5d                   	pop    %ebp
80104b82:	c3                   	ret    
    end_op();
80104b83:	e8 a0 dc ff ff       	call   80102828 <end_op>
    return -1;
80104b88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b8d:	eb ec                	jmp    80104b7b <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104b8f:	83 ec 0c             	sub    $0xc,%esp
80104b92:	68 c8 71 10 80       	push   $0x801071c8
80104b97:	e8 ac b7 ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104b9c:	89 d8                	mov    %ebx,%eax
80104b9e:	e8 c4 f9 ff ff       	call   80104567 <isdirempty>
80104ba3:	85 c0                	test   %eax,%eax
80104ba5:	0f 85 6c ff ff ff    	jne    80104b17 <sys_unlink+0xc1>
    iunlockput(ip);
80104bab:	83 ec 0c             	sub    $0xc,%esp
80104bae:	53                   	push   %ebx
80104baf:	e8 74 cb ff ff       	call   80101728 <iunlockput>
    goto bad;
80104bb4:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104bb7:	83 ec 0c             	sub    $0xc,%esp
80104bba:	56                   	push   %esi
80104bbb:	e8 68 cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104bc0:	e8 63 dc ff ff       	call   80102828 <end_op>
  return -1;
80104bc5:	83 c4 10             	add    $0x10,%esp
80104bc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bcd:	eb ac                	jmp    80104b7b <sys_unlink+0x125>
    panic("unlink: writei");
80104bcf:	83 ec 0c             	sub    $0xc,%esp
80104bd2:	68 da 71 10 80       	push   $0x801071da
80104bd7:	e8 6c b7 ff ff       	call   80100348 <panic>
    dp->nlink--;
80104bdc:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104be0:	83 e8 01             	sub    $0x1,%eax
80104be3:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104be7:	83 ec 0c             	sub    $0xc,%esp
80104bea:	56                   	push   %esi
80104beb:	e8 30 c8 ff ff       	call   80101420 <iupdate>
80104bf0:	83 c4 10             	add    $0x10,%esp
80104bf3:	e9 52 ff ff ff       	jmp    80104b4a <sys_unlink+0xf4>
    return -1;
80104bf8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bfd:	e9 79 ff ff ff       	jmp    80104b7b <sys_unlink+0x125>

80104c02 <sys_open>:

int
sys_open(void)
{
80104c02:	55                   	push   %ebp
80104c03:	89 e5                	mov    %esp,%ebp
80104c05:	57                   	push   %edi
80104c06:	56                   	push   %esi
80104c07:	53                   	push   %ebx
80104c08:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104c0b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104c0e:	50                   	push   %eax
80104c0f:	6a 00                	push   $0x0
80104c11:	e8 2b f8 ff ff       	call   80104441 <argstr>
80104c16:	83 c4 10             	add    $0x10,%esp
80104c19:	85 c0                	test   %eax,%eax
80104c1b:	0f 88 30 01 00 00    	js     80104d51 <sys_open+0x14f>
80104c21:	83 ec 08             	sub    $0x8,%esp
80104c24:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104c27:	50                   	push   %eax
80104c28:	6a 01                	push   $0x1
80104c2a:	e8 82 f7 ff ff       	call   801043b1 <argint>
80104c2f:	83 c4 10             	add    $0x10,%esp
80104c32:	85 c0                	test   %eax,%eax
80104c34:	0f 88 21 01 00 00    	js     80104d5b <sys_open+0x159>
    return -1;

  begin_op();
80104c3a:	e8 6f db ff ff       	call   801027ae <begin_op>

  if(omode & O_CREATE){
80104c3f:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104c43:	0f 84 84 00 00 00    	je     80104ccd <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104c49:	83 ec 0c             	sub    $0xc,%esp
80104c4c:	6a 00                	push   $0x0
80104c4e:	b9 00 00 00 00       	mov    $0x0,%ecx
80104c53:	ba 02 00 00 00       	mov    $0x2,%edx
80104c58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104c5b:	e8 5e f9 ff ff       	call   801045be <create>
80104c60:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104c62:	83 c4 10             	add    $0x10,%esp
80104c65:	85 c0                	test   %eax,%eax
80104c67:	74 58                	je     80104cc1 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104c69:	e8 bf bf ff ff       	call   80100c2d <filealloc>
80104c6e:	89 c3                	mov    %eax,%ebx
80104c70:	85 c0                	test   %eax,%eax
80104c72:	0f 84 ae 00 00 00    	je     80104d26 <sys_open+0x124>
80104c78:	e8 b3 f8 ff ff       	call   80104530 <fdalloc>
80104c7d:	89 c7                	mov    %eax,%edi
80104c7f:	85 c0                	test   %eax,%eax
80104c81:	0f 88 9f 00 00 00    	js     80104d26 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104c87:	83 ec 0c             	sub    $0xc,%esp
80104c8a:	56                   	push   %esi
80104c8b:	e8 b3 c9 ff ff       	call   80101643 <iunlock>
  end_op();
80104c90:	e8 93 db ff ff       	call   80102828 <end_op>

  f->type = FD_INODE;
80104c95:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104c9b:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104c9e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104ca5:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ca8:	83 c4 10             	add    $0x10,%esp
80104cab:	a8 01                	test   $0x1,%al
80104cad:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104cb1:	a8 03                	test   $0x3,%al
80104cb3:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104cb7:	89 f8                	mov    %edi,%eax
80104cb9:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104cbc:	5b                   	pop    %ebx
80104cbd:	5e                   	pop    %esi
80104cbe:	5f                   	pop    %edi
80104cbf:	5d                   	pop    %ebp
80104cc0:	c3                   	ret    
      end_op();
80104cc1:	e8 62 db ff ff       	call   80102828 <end_op>
      return -1;
80104cc6:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104ccb:	eb ea                	jmp    80104cb7 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104ccd:	83 ec 0c             	sub    $0xc,%esp
80104cd0:	ff 75 e4             	pushl  -0x1c(%ebp)
80104cd3:	e8 09 cf ff ff       	call   80101be1 <namei>
80104cd8:	89 c6                	mov    %eax,%esi
80104cda:	83 c4 10             	add    $0x10,%esp
80104cdd:	85 c0                	test   %eax,%eax
80104cdf:	74 39                	je     80104d1a <sys_open+0x118>
    ilock(ip);
80104ce1:	83 ec 0c             	sub    $0xc,%esp
80104ce4:	50                   	push   %eax
80104ce5:	e8 97 c8 ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104cea:	83 c4 10             	add    $0x10,%esp
80104ced:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104cf2:	0f 85 71 ff ff ff    	jne    80104c69 <sys_open+0x67>
80104cf8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104cfc:	0f 84 67 ff ff ff    	je     80104c69 <sys_open+0x67>
      iunlockput(ip);
80104d02:	83 ec 0c             	sub    $0xc,%esp
80104d05:	56                   	push   %esi
80104d06:	e8 1d ca ff ff       	call   80101728 <iunlockput>
      end_op();
80104d0b:	e8 18 db ff ff       	call   80102828 <end_op>
      return -1;
80104d10:	83 c4 10             	add    $0x10,%esp
80104d13:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d18:	eb 9d                	jmp    80104cb7 <sys_open+0xb5>
      end_op();
80104d1a:	e8 09 db ff ff       	call   80102828 <end_op>
      return -1;
80104d1f:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d24:	eb 91                	jmp    80104cb7 <sys_open+0xb5>
    if(f)
80104d26:	85 db                	test   %ebx,%ebx
80104d28:	74 0c                	je     80104d36 <sys_open+0x134>
      fileclose(f);
80104d2a:	83 ec 0c             	sub    $0xc,%esp
80104d2d:	53                   	push   %ebx
80104d2e:	e8 a0 bf ff ff       	call   80100cd3 <fileclose>
80104d33:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104d36:	83 ec 0c             	sub    $0xc,%esp
80104d39:	56                   	push   %esi
80104d3a:	e8 e9 c9 ff ff       	call   80101728 <iunlockput>
    end_op();
80104d3f:	e8 e4 da ff ff       	call   80102828 <end_op>
    return -1;
80104d44:	83 c4 10             	add    $0x10,%esp
80104d47:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d4c:	e9 66 ff ff ff       	jmp    80104cb7 <sys_open+0xb5>
    return -1;
80104d51:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d56:	e9 5c ff ff ff       	jmp    80104cb7 <sys_open+0xb5>
80104d5b:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d60:	e9 52 ff ff ff       	jmp    80104cb7 <sys_open+0xb5>

80104d65 <sys_mkdir>:

int
sys_mkdir(void)
{
80104d65:	55                   	push   %ebp
80104d66:	89 e5                	mov    %esp,%ebp
80104d68:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104d6b:	e8 3e da ff ff       	call   801027ae <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104d70:	83 ec 08             	sub    $0x8,%esp
80104d73:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d76:	50                   	push   %eax
80104d77:	6a 00                	push   $0x0
80104d79:	e8 c3 f6 ff ff       	call   80104441 <argstr>
80104d7e:	83 c4 10             	add    $0x10,%esp
80104d81:	85 c0                	test   %eax,%eax
80104d83:	78 36                	js     80104dbb <sys_mkdir+0x56>
80104d85:	83 ec 0c             	sub    $0xc,%esp
80104d88:	6a 00                	push   $0x0
80104d8a:	b9 00 00 00 00       	mov    $0x0,%ecx
80104d8f:	ba 01 00 00 00       	mov    $0x1,%edx
80104d94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d97:	e8 22 f8 ff ff       	call   801045be <create>
80104d9c:	83 c4 10             	add    $0x10,%esp
80104d9f:	85 c0                	test   %eax,%eax
80104da1:	74 18                	je     80104dbb <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104da3:	83 ec 0c             	sub    $0xc,%esp
80104da6:	50                   	push   %eax
80104da7:	e8 7c c9 ff ff       	call   80101728 <iunlockput>
  end_op();
80104dac:	e8 77 da ff ff       	call   80102828 <end_op>
  return 0;
80104db1:	83 c4 10             	add    $0x10,%esp
80104db4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104db9:	c9                   	leave  
80104dba:	c3                   	ret    
    end_op();
80104dbb:	e8 68 da ff ff       	call   80102828 <end_op>
    return -1;
80104dc0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dc5:	eb f2                	jmp    80104db9 <sys_mkdir+0x54>

80104dc7 <sys_mknod>:

int
sys_mknod(void)
{
80104dc7:	55                   	push   %ebp
80104dc8:	89 e5                	mov    %esp,%ebp
80104dca:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104dcd:	e8 dc d9 ff ff       	call   801027ae <begin_op>
  if((argstr(0, &path)) < 0 ||
80104dd2:	83 ec 08             	sub    $0x8,%esp
80104dd5:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dd8:	50                   	push   %eax
80104dd9:	6a 00                	push   $0x0
80104ddb:	e8 61 f6 ff ff       	call   80104441 <argstr>
80104de0:	83 c4 10             	add    $0x10,%esp
80104de3:	85 c0                	test   %eax,%eax
80104de5:	78 62                	js     80104e49 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104de7:	83 ec 08             	sub    $0x8,%esp
80104dea:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104ded:	50                   	push   %eax
80104dee:	6a 01                	push   $0x1
80104df0:	e8 bc f5 ff ff       	call   801043b1 <argint>
  if((argstr(0, &path)) < 0 ||
80104df5:	83 c4 10             	add    $0x10,%esp
80104df8:	85 c0                	test   %eax,%eax
80104dfa:	78 4d                	js     80104e49 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104dfc:	83 ec 08             	sub    $0x8,%esp
80104dff:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104e02:	50                   	push   %eax
80104e03:	6a 02                	push   $0x2
80104e05:	e8 a7 f5 ff ff       	call   801043b1 <argint>
     argint(1, &major) < 0 ||
80104e0a:	83 c4 10             	add    $0x10,%esp
80104e0d:	85 c0                	test   %eax,%eax
80104e0f:	78 38                	js     80104e49 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104e11:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104e15:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104e19:	83 ec 0c             	sub    $0xc,%esp
80104e1c:	50                   	push   %eax
80104e1d:	ba 03 00 00 00       	mov    $0x3,%edx
80104e22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e25:	e8 94 f7 ff ff       	call   801045be <create>
80104e2a:	83 c4 10             	add    $0x10,%esp
80104e2d:	85 c0                	test   %eax,%eax
80104e2f:	74 18                	je     80104e49 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104e31:	83 ec 0c             	sub    $0xc,%esp
80104e34:	50                   	push   %eax
80104e35:	e8 ee c8 ff ff       	call   80101728 <iunlockput>
  end_op();
80104e3a:	e8 e9 d9 ff ff       	call   80102828 <end_op>
  return 0;
80104e3f:	83 c4 10             	add    $0x10,%esp
80104e42:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e47:	c9                   	leave  
80104e48:	c3                   	ret    
    end_op();
80104e49:	e8 da d9 ff ff       	call   80102828 <end_op>
    return -1;
80104e4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e53:	eb f2                	jmp    80104e47 <sys_mknod+0x80>

80104e55 <sys_chdir>:

int
sys_chdir(void)
{
80104e55:	55                   	push   %ebp
80104e56:	89 e5                	mov    %esp,%ebp
80104e58:	56                   	push   %esi
80104e59:	53                   	push   %ebx
80104e5a:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104e5d:	e8 cf e3 ff ff       	call   80103231 <myproc>
80104e62:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104e64:	e8 45 d9 ff ff       	call   801027ae <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104e69:	83 ec 08             	sub    $0x8,%esp
80104e6c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e6f:	50                   	push   %eax
80104e70:	6a 00                	push   $0x0
80104e72:	e8 ca f5 ff ff       	call   80104441 <argstr>
80104e77:	83 c4 10             	add    $0x10,%esp
80104e7a:	85 c0                	test   %eax,%eax
80104e7c:	78 52                	js     80104ed0 <sys_chdir+0x7b>
80104e7e:	83 ec 0c             	sub    $0xc,%esp
80104e81:	ff 75 f4             	pushl  -0xc(%ebp)
80104e84:	e8 58 cd ff ff       	call   80101be1 <namei>
80104e89:	89 c3                	mov    %eax,%ebx
80104e8b:	83 c4 10             	add    $0x10,%esp
80104e8e:	85 c0                	test   %eax,%eax
80104e90:	74 3e                	je     80104ed0 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104e92:	83 ec 0c             	sub    $0xc,%esp
80104e95:	50                   	push   %eax
80104e96:	e8 e6 c6 ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104e9b:	83 c4 10             	add    $0x10,%esp
80104e9e:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104ea3:	75 37                	jne    80104edc <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104ea5:	83 ec 0c             	sub    $0xc,%esp
80104ea8:	53                   	push   %ebx
80104ea9:	e8 95 c7 ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104eae:	83 c4 04             	add    $0x4,%esp
80104eb1:	ff 76 68             	pushl  0x68(%esi)
80104eb4:	e8 cf c7 ff ff       	call   80101688 <iput>
  end_op();
80104eb9:	e8 6a d9 ff ff       	call   80102828 <end_op>
  curproc->cwd = ip;
80104ebe:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104ec1:	83 c4 10             	add    $0x10,%esp
80104ec4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ec9:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104ecc:	5b                   	pop    %ebx
80104ecd:	5e                   	pop    %esi
80104ece:	5d                   	pop    %ebp
80104ecf:	c3                   	ret    
    end_op();
80104ed0:	e8 53 d9 ff ff       	call   80102828 <end_op>
    return -1;
80104ed5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eda:	eb ed                	jmp    80104ec9 <sys_chdir+0x74>
    iunlockput(ip);
80104edc:	83 ec 0c             	sub    $0xc,%esp
80104edf:	53                   	push   %ebx
80104ee0:	e8 43 c8 ff ff       	call   80101728 <iunlockput>
    end_op();
80104ee5:	e8 3e d9 ff ff       	call   80102828 <end_op>
    return -1;
80104eea:	83 c4 10             	add    $0x10,%esp
80104eed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ef2:	eb d5                	jmp    80104ec9 <sys_chdir+0x74>

80104ef4 <sys_exec>:

int
sys_exec(void)
{
80104ef4:	55                   	push   %ebp
80104ef5:	89 e5                	mov    %esp,%ebp
80104ef7:	53                   	push   %ebx
80104ef8:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104efe:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f01:	50                   	push   %eax
80104f02:	6a 00                	push   $0x0
80104f04:	e8 38 f5 ff ff       	call   80104441 <argstr>
80104f09:	83 c4 10             	add    $0x10,%esp
80104f0c:	85 c0                	test   %eax,%eax
80104f0e:	0f 88 a8 00 00 00    	js     80104fbc <sys_exec+0xc8>
80104f14:	83 ec 08             	sub    $0x8,%esp
80104f17:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104f1d:	50                   	push   %eax
80104f1e:	6a 01                	push   $0x1
80104f20:	e8 8c f4 ff ff       	call   801043b1 <argint>
80104f25:	83 c4 10             	add    $0x10,%esp
80104f28:	85 c0                	test   %eax,%eax
80104f2a:	0f 88 93 00 00 00    	js     80104fc3 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104f30:	83 ec 04             	sub    $0x4,%esp
80104f33:	68 80 00 00 00       	push   $0x80
80104f38:	6a 00                	push   $0x0
80104f3a:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104f40:	50                   	push   %eax
80104f41:	e8 20 f2 ff ff       	call   80104166 <memset>
80104f46:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104f49:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104f4e:	83 fb 1f             	cmp    $0x1f,%ebx
80104f51:	77 77                	ja     80104fca <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104f53:	83 ec 08             	sub    $0x8,%esp
80104f56:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104f5c:	50                   	push   %eax
80104f5d:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104f63:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104f66:	50                   	push   %eax
80104f67:	e8 c9 f3 ff ff       	call   80104335 <fetchint>
80104f6c:	83 c4 10             	add    $0x10,%esp
80104f6f:	85 c0                	test   %eax,%eax
80104f71:	78 5e                	js     80104fd1 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104f73:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104f79:	85 c0                	test   %eax,%eax
80104f7b:	74 1d                	je     80104f9a <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104f7d:	83 ec 08             	sub    $0x8,%esp
80104f80:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104f87:	52                   	push   %edx
80104f88:	50                   	push   %eax
80104f89:	e8 e3 f3 ff ff       	call   80104371 <fetchstr>
80104f8e:	83 c4 10             	add    $0x10,%esp
80104f91:	85 c0                	test   %eax,%eax
80104f93:	78 46                	js     80104fdb <sys_exec+0xe7>
  for(i=0;; i++){
80104f95:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104f98:	eb b4                	jmp    80104f4e <sys_exec+0x5a>
      argv[i] = 0;
80104f9a:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104fa1:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104fa5:	83 ec 08             	sub    $0x8,%esp
80104fa8:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104fae:	50                   	push   %eax
80104faf:	ff 75 f4             	pushl  -0xc(%ebp)
80104fb2:	e8 1b b9 ff ff       	call   801008d2 <exec>
80104fb7:	83 c4 10             	add    $0x10,%esp
80104fba:	eb 1a                	jmp    80104fd6 <sys_exec+0xe2>
    return -1;
80104fbc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fc1:	eb 13                	jmp    80104fd6 <sys_exec+0xe2>
80104fc3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fc8:	eb 0c                	jmp    80104fd6 <sys_exec+0xe2>
      return -1;
80104fca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fcf:	eb 05                	jmp    80104fd6 <sys_exec+0xe2>
      return -1;
80104fd1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104fd6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104fd9:	c9                   	leave  
80104fda:	c3                   	ret    
      return -1;
80104fdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fe0:	eb f4                	jmp    80104fd6 <sys_exec+0xe2>

80104fe2 <sys_pipe>:

int
sys_pipe(void)
{
80104fe2:	55                   	push   %ebp
80104fe3:	89 e5                	mov    %esp,%ebp
80104fe5:	53                   	push   %ebx
80104fe6:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104fe9:	6a 08                	push   $0x8
80104feb:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104fee:	50                   	push   %eax
80104fef:	6a 00                	push   $0x0
80104ff1:	e8 e3 f3 ff ff       	call   801043d9 <argptr>
80104ff6:	83 c4 10             	add    $0x10,%esp
80104ff9:	85 c0                	test   %eax,%eax
80104ffb:	78 77                	js     80105074 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104ffd:	83 ec 08             	sub    $0x8,%esp
80105000:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105003:	50                   	push   %eax
80105004:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105007:	50                   	push   %eax
80105008:	e8 28 dd ff ff       	call   80102d35 <pipealloc>
8010500d:	83 c4 10             	add    $0x10,%esp
80105010:	85 c0                	test   %eax,%eax
80105012:	78 67                	js     8010507b <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80105014:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105017:	e8 14 f5 ff ff       	call   80104530 <fdalloc>
8010501c:	89 c3                	mov    %eax,%ebx
8010501e:	85 c0                	test   %eax,%eax
80105020:	78 21                	js     80105043 <sys_pipe+0x61>
80105022:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105025:	e8 06 f5 ff ff       	call   80104530 <fdalloc>
8010502a:	85 c0                	test   %eax,%eax
8010502c:	78 15                	js     80105043 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
8010502e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105031:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80105033:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105036:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80105039:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010503e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105041:	c9                   	leave  
80105042:	c3                   	ret    
    if(fd0 >= 0)
80105043:	85 db                	test   %ebx,%ebx
80105045:	78 0d                	js     80105054 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80105047:	e8 e5 e1 ff ff       	call   80103231 <myproc>
8010504c:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80105053:	00 
    fileclose(rf);
80105054:	83 ec 0c             	sub    $0xc,%esp
80105057:	ff 75 f0             	pushl  -0x10(%ebp)
8010505a:	e8 74 bc ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
8010505f:	83 c4 04             	add    $0x4,%esp
80105062:	ff 75 ec             	pushl  -0x14(%ebp)
80105065:	e8 69 bc ff ff       	call   80100cd3 <fileclose>
    return -1;
8010506a:	83 c4 10             	add    $0x10,%esp
8010506d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105072:	eb ca                	jmp    8010503e <sys_pipe+0x5c>
    return -1;
80105074:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105079:	eb c3                	jmp    8010503e <sys_pipe+0x5c>
    return -1;
8010507b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105080:	eb bc                	jmp    8010503e <sys_pipe+0x5c>

80105082 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80105082:	55                   	push   %ebp
80105083:	89 e5                	mov    %esp,%ebp
80105085:	83 ec 08             	sub    $0x8,%esp
  return fork();
80105088:	e8 fd ec ff ff       	call   80103d8a <fork>
}
8010508d:	c9                   	leave  
8010508e:	c3                   	ret    

8010508f <sys_exit>:

int
sys_exit(void)
{
8010508f:	55                   	push   %ebp
80105090:	89 e5                	mov    %esp,%ebp
80105092:	83 ec 08             	sub    $0x8,%esp
  exit();
80105095:	e8 f2 e5 ff ff       	call   8010368c <exit>
  return 0;  // not reached
}
8010509a:	b8 00 00 00 00       	mov    $0x0,%eax
8010509f:	c9                   	leave  
801050a0:	c3                   	ret    

801050a1 <sys_wait>:

int
sys_wait(void)
{
801050a1:	55                   	push   %ebp
801050a2:	89 e5                	mov    %esp,%ebp
801050a4:	83 ec 08             	sub    $0x8,%esp
  return wait();
801050a7:	e8 6c e7 ff ff       	call   80103818 <wait>
}
801050ac:	c9                   	leave  
801050ad:	c3                   	ret    

801050ae <sys_kill>:

int
sys_kill(void)
{
801050ae:	55                   	push   %ebp
801050af:	89 e5                	mov    %esp,%ebp
801050b1:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
801050b4:	8d 45 f4             	lea    -0xc(%ebp),%eax
801050b7:	50                   	push   %eax
801050b8:	6a 00                	push   $0x0
801050ba:	e8 f2 f2 ff ff       	call   801043b1 <argint>
801050bf:	83 c4 10             	add    $0x10,%esp
801050c2:	85 c0                	test   %eax,%eax
801050c4:	78 10                	js     801050d6 <sys_kill+0x28>
    return -1;
  return kill(pid);
801050c6:	83 ec 0c             	sub    $0xc,%esp
801050c9:	ff 75 f4             	pushl  -0xc(%ebp)
801050cc:	e8 47 e8 ff ff       	call   80103918 <kill>
801050d1:	83 c4 10             	add    $0x10,%esp
}
801050d4:	c9                   	leave  
801050d5:	c3                   	ret    
    return -1;
801050d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050db:	eb f7                	jmp    801050d4 <sys_kill+0x26>

801050dd <sys_getpid>:

int
sys_getpid(void)
{
801050dd:	55                   	push   %ebp
801050de:	89 e5                	mov    %esp,%ebp
801050e0:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
801050e3:	e8 49 e1 ff ff       	call   80103231 <myproc>
801050e8:	8b 40 10             	mov    0x10(%eax),%eax
}
801050eb:	c9                   	leave  
801050ec:	c3                   	ret    

801050ed <sys_sbrk>:

int
sys_sbrk(void)
{
801050ed:	55                   	push   %ebp
801050ee:	89 e5                	mov    %esp,%ebp
801050f0:	53                   	push   %ebx
801050f1:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801050f4:	8d 45 f4             	lea    -0xc(%ebp),%eax
801050f7:	50                   	push   %eax
801050f8:	6a 00                	push   $0x0
801050fa:	e8 b2 f2 ff ff       	call   801043b1 <argint>
801050ff:	83 c4 10             	add    $0x10,%esp
80105102:	85 c0                	test   %eax,%eax
80105104:	78 27                	js     8010512d <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80105106:	e8 26 e1 ff ff       	call   80103231 <myproc>
8010510b:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
8010510d:	83 ec 0c             	sub    $0xc,%esp
80105110:	ff 75 f4             	pushl  -0xc(%ebp)
80105113:	e8 8b e2 ff ff       	call   801033a3 <growproc>
80105118:	83 c4 10             	add    $0x10,%esp
8010511b:	85 c0                	test   %eax,%eax
8010511d:	78 07                	js     80105126 <sys_sbrk+0x39>
    return -1;
  return addr;
}
8010511f:	89 d8                	mov    %ebx,%eax
80105121:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105124:	c9                   	leave  
80105125:	c3                   	ret    
    return -1;
80105126:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010512b:	eb f2                	jmp    8010511f <sys_sbrk+0x32>
    return -1;
8010512d:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80105132:	eb eb                	jmp    8010511f <sys_sbrk+0x32>

80105134 <sys_sleep>:

int
sys_sleep(void)
{
80105134:	55                   	push   %ebp
80105135:	89 e5                	mov    %esp,%ebp
80105137:	53                   	push   %ebx
80105138:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
8010513b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010513e:	50                   	push   %eax
8010513f:	6a 00                	push   $0x0
80105141:	e8 6b f2 ff ff       	call   801043b1 <argint>
80105146:	83 c4 10             	add    $0x10,%esp
80105149:	85 c0                	test   %eax,%eax
8010514b:	78 75                	js     801051c2 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
8010514d:	83 ec 0c             	sub    $0xc,%esp
80105150:	68 80 63 11 80       	push   $0x80116380
80105155:	e8 60 ef ff ff       	call   801040ba <acquire>
  ticks0 = ticks;
8010515a:	8b 1d c0 6b 11 80    	mov    0x80116bc0,%ebx
  while(ticks - ticks0 < n){
80105160:	83 c4 10             	add    $0x10,%esp
80105163:	a1 c0 6b 11 80       	mov    0x80116bc0,%eax
80105168:	29 d8                	sub    %ebx,%eax
8010516a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010516d:	73 39                	jae    801051a8 <sys_sleep+0x74>
    if(myproc()->killed){
8010516f:	e8 bd e0 ff ff       	call   80103231 <myproc>
80105174:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105178:	75 17                	jne    80105191 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
8010517a:	83 ec 08             	sub    $0x8,%esp
8010517d:	68 80 63 11 80       	push   $0x80116380
80105182:	68 c0 6b 11 80       	push   $0x80116bc0
80105187:	e8 fb e5 ff ff       	call   80103787 <sleep>
8010518c:	83 c4 10             	add    $0x10,%esp
8010518f:	eb d2                	jmp    80105163 <sys_sleep+0x2f>
      release(&tickslock);
80105191:	83 ec 0c             	sub    $0xc,%esp
80105194:	68 80 63 11 80       	push   $0x80116380
80105199:	e8 81 ef ff ff       	call   8010411f <release>
      return -1;
8010519e:	83 c4 10             	add    $0x10,%esp
801051a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051a6:	eb 15                	jmp    801051bd <sys_sleep+0x89>
  }
  release(&tickslock);
801051a8:	83 ec 0c             	sub    $0xc,%esp
801051ab:	68 80 63 11 80       	push   $0x80116380
801051b0:	e8 6a ef ff ff       	call   8010411f <release>
  return 0;
801051b5:	83 c4 10             	add    $0x10,%esp
801051b8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801051bd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801051c0:	c9                   	leave  
801051c1:	c3                   	ret    
    return -1;
801051c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051c7:	eb f4                	jmp    801051bd <sys_sleep+0x89>

801051c9 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801051c9:	55                   	push   %ebp
801051ca:	89 e5                	mov    %esp,%ebp
801051cc:	53                   	push   %ebx
801051cd:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
801051d0:	68 80 63 11 80       	push   $0x80116380
801051d5:	e8 e0 ee ff ff       	call   801040ba <acquire>
  xticks = ticks;
801051da:	8b 1d c0 6b 11 80    	mov    0x80116bc0,%ebx
  release(&tickslock);
801051e0:	c7 04 24 80 63 11 80 	movl   $0x80116380,(%esp)
801051e7:	e8 33 ef ff ff       	call   8010411f <release>
  return xticks;
}
801051ec:	89 d8                	mov    %ebx,%eax
801051ee:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801051f1:	c9                   	leave  
801051f2:	c3                   	ret    

801051f3 <sys_setpri>:


// This sets the priority of the specified PID to pri
// return -1 if pri or PID are invalid
int
sys_setpri(void){
801051f3:	55                   	push   %ebp
801051f4:	89 e5                	mov    %esp,%ebp
801051f6:	83 ec 20             	sub    $0x20,%esp
    int PID;
    int pri;

    if(argint(0, &PID) < 0 || argint(1, &pri) < 0){
801051f9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801051fc:	50                   	push   %eax
801051fd:	6a 00                	push   $0x0
801051ff:	e8 ad f1 ff ff       	call   801043b1 <argint>
80105204:	83 c4 10             	add    $0x10,%esp
80105207:	85 c0                	test   %eax,%eax
80105209:	78 28                	js     80105233 <sys_setpri+0x40>
8010520b:	83 ec 08             	sub    $0x8,%esp
8010520e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105211:	50                   	push   %eax
80105212:	6a 01                	push   $0x1
80105214:	e8 98 f1 ff ff       	call   801043b1 <argint>
80105219:	83 c4 10             	add    $0x10,%esp
8010521c:	85 c0                	test   %eax,%eax
8010521e:	78 1a                	js     8010523a <sys_setpri+0x47>
        return -1;
    }

    int rc = setpri(PID, pri);
80105220:	83 ec 08             	sub    $0x8,%esp
80105223:	ff 75 f0             	pushl  -0x10(%ebp)
80105226:	ff 75 f4             	pushl  -0xc(%ebp)
80105229:	e8 15 e8 ff ff       	call   80103a43 <setpri>
    return rc;
8010522e:	83 c4 10             	add    $0x10,%esp
}
80105231:	c9                   	leave  
80105232:	c3                   	ret    
        return -1;
80105233:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105238:	eb f7                	jmp    80105231 <sys_setpri+0x3e>
8010523a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010523f:	eb f0                	jmp    80105231 <sys_setpri+0x3e>

80105241 <sys_getpri>:

// returns the current priority of the specified PID.  If the PID is not valid, it returns -1
int
sys_getpri(void){
80105241:	55                   	push   %ebp
80105242:	89 e5                	mov    %esp,%ebp
80105244:	83 ec 20             	sub    $0x20,%esp
    int PID;

    if(argint(0, &PID) < 0){
80105247:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010524a:	50                   	push   %eax
8010524b:	6a 00                	push   $0x0
8010524d:	e8 5f f1 ff ff       	call   801043b1 <argint>
80105252:	83 c4 10             	add    $0x10,%esp
80105255:	85 c0                	test   %eax,%eax
80105257:	78 10                	js     80105269 <sys_getpri+0x28>
        return -1;
    }

    int rc = getpri(PID);
80105259:	83 ec 0c             	sub    $0xc,%esp
8010525c:	ff 75 f4             	pushl  -0xc(%ebp)
8010525f:	e8 e8 e8 ff ff       	call   80103b4c <getpri>
    return rc;
80105264:	83 c4 10             	add    $0x10,%esp
}
80105267:	c9                   	leave  
80105268:	c3                   	ret    
        return -1;
80105269:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010526e:	eb f7                	jmp    80105267 <sys_getpri+0x26>

80105270 <sys_fork2>:

//
int
sys_fork2(void){
80105270:	55                   	push   %ebp
80105271:	89 e5                	mov    %esp,%ebp
80105273:	83 ec 20             	sub    $0x20,%esp

    int pri;

    if(argint(0, &pri) < 0){
80105276:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105279:	50                   	push   %eax
8010527a:	6a 00                	push   $0x0
8010527c:	e8 30 f1 ff ff       	call   801043b1 <argint>
80105281:	83 c4 10             	add    $0x10,%esp
80105284:	85 c0                	test   %eax,%eax
80105286:	78 10                	js     80105298 <sys_fork2+0x28>
        return -1;
    }

    int rc = fork2(pri);
80105288:	83 ec 0c             	sub    $0xc,%esp
8010528b:	ff 75 f4             	pushl  -0xc(%ebp)
8010528e:	e8 60 e9 ff ff       	call   80103bf3 <fork2>
    return rc;
80105293:	83 c4 10             	add    $0x10,%esp
}
80105296:	c9                   	leave  
80105297:	c3                   	ret    
        return -1;
80105298:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010529d:	eb f7                	jmp    80105296 <sys_fork2+0x26>

8010529f <sys_getpinfo>:

// returns 0 on success and -1 on failure
int
sys_getpinfo(void){
8010529f:	55                   	push   %ebp
801052a0:	89 e5                	mov    %esp,%ebp
801052a2:	83 ec 1c             	sub    $0x1c,%esp

    struct pstat *ptr;

    if(argptr(0, (char**)&ptr, sizeof(ptr )) < 0){
801052a5:	6a 04                	push   $0x4
801052a7:	8d 45 f4             	lea    -0xc(%ebp),%eax
801052aa:	50                   	push   %eax
801052ab:	6a 00                	push   $0x0
801052ad:	e8 27 f1 ff ff       	call   801043d9 <argptr>
801052b2:	83 c4 10             	add    $0x10,%esp
801052b5:	85 c0                	test   %eax,%eax
801052b7:	78 10                	js     801052c9 <sys_getpinfo+0x2a>
        return -1;
    }

    int rc = getpinfo(ptr);
801052b9:	83 ec 0c             	sub    $0xc,%esp
801052bc:	ff 75 f4             	pushl  -0xc(%ebp)
801052bf:	e8 d5 ea ff ff       	call   80103d99 <getpinfo>
    return rc;
801052c4:	83 c4 10             	add    $0x10,%esp

}
801052c7:	c9                   	leave  
801052c8:	c3                   	ret    
        return -1;
801052c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052ce:	eb f7                	jmp    801052c7 <sys_getpinfo+0x28>

801052d0 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801052d0:	1e                   	push   %ds
  pushl %es
801052d1:	06                   	push   %es
  pushl %fs
801052d2:	0f a0                	push   %fs
  pushl %gs
801052d4:	0f a8                	push   %gs
  pushal
801052d6:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
801052d7:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801052db:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801052dd:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
801052df:	54                   	push   %esp
  call trap
801052e0:	e8 e3 00 00 00       	call   801053c8 <trap>
  addl $4, %esp
801052e5:	83 c4 04             	add    $0x4,%esp

801052e8 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801052e8:	61                   	popa   
  popl %gs
801052e9:	0f a9                	pop    %gs
  popl %fs
801052eb:	0f a1                	pop    %fs
  popl %es
801052ed:	07                   	pop    %es
  popl %ds
801052ee:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801052ef:	83 c4 08             	add    $0x8,%esp
  iret
801052f2:	cf                   	iret   

801052f3 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801052f3:	55                   	push   %ebp
801052f4:	89 e5                	mov    %esp,%ebp
801052f6:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
801052f9:	b8 00 00 00 00       	mov    $0x0,%eax
801052fe:	eb 4a                	jmp    8010534a <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80105300:	8b 0c 85 18 a0 10 80 	mov    -0x7fef5fe8(,%eax,4),%ecx
80105307:	66 89 0c c5 c0 63 11 	mov    %cx,-0x7fee9c40(,%eax,8)
8010530e:	80 
8010530f:	66 c7 04 c5 c2 63 11 	movw   $0x8,-0x7fee9c3e(,%eax,8)
80105316:	80 08 00 
80105319:	c6 04 c5 c4 63 11 80 	movb   $0x0,-0x7fee9c3c(,%eax,8)
80105320:	00 
80105321:	0f b6 14 c5 c5 63 11 	movzbl -0x7fee9c3b(,%eax,8),%edx
80105328:	80 
80105329:	83 e2 f0             	and    $0xfffffff0,%edx
8010532c:	83 ca 0e             	or     $0xe,%edx
8010532f:	83 e2 8f             	and    $0xffffff8f,%edx
80105332:	83 ca 80             	or     $0xffffff80,%edx
80105335:	88 14 c5 c5 63 11 80 	mov    %dl,-0x7fee9c3b(,%eax,8)
8010533c:	c1 e9 10             	shr    $0x10,%ecx
8010533f:	66 89 0c c5 c6 63 11 	mov    %cx,-0x7fee9c3a(,%eax,8)
80105346:	80 
  for(i = 0; i < 256; i++)
80105347:	83 c0 01             	add    $0x1,%eax
8010534a:	3d ff 00 00 00       	cmp    $0xff,%eax
8010534f:	7e af                	jle    80105300 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80105351:	8b 15 18 a1 10 80    	mov    0x8010a118,%edx
80105357:	66 89 15 c0 65 11 80 	mov    %dx,0x801165c0
8010535e:	66 c7 05 c2 65 11 80 	movw   $0x8,0x801165c2
80105365:	08 00 
80105367:	c6 05 c4 65 11 80 00 	movb   $0x0,0x801165c4
8010536e:	0f b6 05 c5 65 11 80 	movzbl 0x801165c5,%eax
80105375:	83 c8 0f             	or     $0xf,%eax
80105378:	83 e0 ef             	and    $0xffffffef,%eax
8010537b:	83 c8 e0             	or     $0xffffffe0,%eax
8010537e:	a2 c5 65 11 80       	mov    %al,0x801165c5
80105383:	c1 ea 10             	shr    $0x10,%edx
80105386:	66 89 15 c6 65 11 80 	mov    %dx,0x801165c6

  initlock(&tickslock, "time");
8010538d:	83 ec 08             	sub    $0x8,%esp
80105390:	68 e9 71 10 80       	push   $0x801071e9
80105395:	68 80 63 11 80       	push   $0x80116380
8010539a:	e8 df eb ff ff       	call   80103f7e <initlock>
}
8010539f:	83 c4 10             	add    $0x10,%esp
801053a2:	c9                   	leave  
801053a3:	c3                   	ret    

801053a4 <idtinit>:

void
idtinit(void)
{
801053a4:	55                   	push   %ebp
801053a5:	89 e5                	mov    %esp,%ebp
801053a7:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
801053aa:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
801053b0:	b8 c0 63 11 80       	mov    $0x801163c0,%eax
801053b5:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801053b9:	c1 e8 10             	shr    $0x10,%eax
801053bc:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
801053c0:	8d 45 fa             	lea    -0x6(%ebp),%eax
801053c3:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
801053c6:	c9                   	leave  
801053c7:	c3                   	ret    

801053c8 <trap>:

void
trap(struct trapframe *tf)
{
801053c8:	55                   	push   %ebp
801053c9:	89 e5                	mov    %esp,%ebp
801053cb:	57                   	push   %edi
801053cc:	56                   	push   %esi
801053cd:	53                   	push   %ebx
801053ce:	83 ec 1c             	sub    $0x1c,%esp
801053d1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
801053d4:	8b 43 30             	mov    0x30(%ebx),%eax
801053d7:	83 f8 40             	cmp    $0x40,%eax
801053da:	74 13                	je     801053ef <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
801053dc:	83 e8 20             	sub    $0x20,%eax
801053df:	83 f8 1f             	cmp    $0x1f,%eax
801053e2:	0f 87 3a 01 00 00    	ja     80105522 <trap+0x15a>
801053e8:	ff 24 85 90 72 10 80 	jmp    *-0x7fef8d70(,%eax,4)
    if(myproc()->killed)
801053ef:	e8 3d de ff ff       	call   80103231 <myproc>
801053f4:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801053f8:	75 1f                	jne    80105419 <trap+0x51>
    myproc()->tf = tf;
801053fa:	e8 32 de ff ff       	call   80103231 <myproc>
801053ff:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80105402:	e8 6d f0 ff ff       	call   80104474 <syscall>
    if(myproc()->killed)
80105407:	e8 25 de ff ff       	call   80103231 <myproc>
8010540c:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105410:	74 7e                	je     80105490 <trap+0xc8>
      exit();
80105412:	e8 75 e2 ff ff       	call   8010368c <exit>
80105417:	eb 77                	jmp    80105490 <trap+0xc8>
      exit();
80105419:	e8 6e e2 ff ff       	call   8010368c <exit>
8010541e:	eb da                	jmp    801053fa <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80105420:	e8 f1 dd ff ff       	call   80103216 <cpuid>
80105425:	85 c0                	test   %eax,%eax
80105427:	74 6f                	je     80105498 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80105429:	e8 6b cf ff ff       	call   80102399 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010542e:	e8 fe dd ff ff       	call   80103231 <myproc>
80105433:	85 c0                	test   %eax,%eax
80105435:	74 1c                	je     80105453 <trap+0x8b>
80105437:	e8 f5 dd ff ff       	call   80103231 <myproc>
8010543c:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105440:	74 11                	je     80105453 <trap+0x8b>
80105442:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105446:	83 e0 03             	and    $0x3,%eax
80105449:	66 83 f8 03          	cmp    $0x3,%ax
8010544d:	0f 84 62 01 00 00    	je     801055b5 <trap+0x1ed>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.

  // TODO: MIGHT NEED TO ADD MORE CONDITIONS TO IF STATEMENT
  if(myproc() && myproc()->state == RUNNING &&
80105453:	e8 d9 dd ff ff       	call   80103231 <myproc>
80105458:	85 c0                	test   %eax,%eax
8010545a:	74 0f                	je     8010546b <trap+0xa3>
8010545c:	e8 d0 dd ff ff       	call   80103231 <myproc>
80105461:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105465:	0f 84 54 01 00 00    	je     801055bf <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010546b:	e8 c1 dd ff ff       	call   80103231 <myproc>
80105470:	85 c0                	test   %eax,%eax
80105472:	74 1c                	je     80105490 <trap+0xc8>
80105474:	e8 b8 dd ff ff       	call   80103231 <myproc>
80105479:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010547d:	74 11                	je     80105490 <trap+0xc8>
8010547f:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105483:	83 e0 03             	and    $0x3,%eax
80105486:	66 83 f8 03          	cmp    $0x3,%ax
8010548a:	0f 84 43 01 00 00    	je     801055d3 <trap+0x20b>
    exit();
}
80105490:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105493:	5b                   	pop    %ebx
80105494:	5e                   	pop    %esi
80105495:	5f                   	pop    %edi
80105496:	5d                   	pop    %ebp
80105497:	c3                   	ret    
      acquire(&tickslock);
80105498:	83 ec 0c             	sub    $0xc,%esp
8010549b:	68 80 63 11 80       	push   $0x80116380
801054a0:	e8 15 ec ff ff       	call   801040ba <acquire>
      ticks++;
801054a5:	83 05 c0 6b 11 80 01 	addl   $0x1,0x80116bc0
      wakeup(&ticks);
801054ac:	c7 04 24 c0 6b 11 80 	movl   $0x80116bc0,(%esp)
801054b3:	e8 37 e4 ff ff       	call   801038ef <wakeup>
      release(&tickslock);
801054b8:	c7 04 24 80 63 11 80 	movl   $0x80116380,(%esp)
801054bf:	e8 5b ec ff ff       	call   8010411f <release>
801054c4:	83 c4 10             	add    $0x10,%esp
801054c7:	e9 5d ff ff ff       	jmp    80105429 <trap+0x61>
    ideintr();
801054cc:	e8 a2 c8 ff ff       	call   80101d73 <ideintr>
    lapiceoi();
801054d1:	e8 c3 ce ff ff       	call   80102399 <lapiceoi>
    break;
801054d6:	e9 53 ff ff ff       	jmp    8010542e <trap+0x66>
    kbdintr();
801054db:	e8 fd cc ff ff       	call   801021dd <kbdintr>
    lapiceoi();
801054e0:	e8 b4 ce ff ff       	call   80102399 <lapiceoi>
    break;
801054e5:	e9 44 ff ff ff       	jmp    8010542e <trap+0x66>
    uartintr();
801054ea:	e8 05 02 00 00       	call   801056f4 <uartintr>
    lapiceoi();
801054ef:	e8 a5 ce ff ff       	call   80102399 <lapiceoi>
    break;
801054f4:	e9 35 ff ff ff       	jmp    8010542e <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801054f9:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801054fc:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105500:	e8 11 dd ff ff       	call   80103216 <cpuid>
80105505:	57                   	push   %edi
80105506:	0f b7 f6             	movzwl %si,%esi
80105509:	56                   	push   %esi
8010550a:	50                   	push   %eax
8010550b:	68 f4 71 10 80       	push   $0x801071f4
80105510:	e8 f6 b0 ff ff       	call   8010060b <cprintf>
    lapiceoi();
80105515:	e8 7f ce ff ff       	call   80102399 <lapiceoi>
    break;
8010551a:	83 c4 10             	add    $0x10,%esp
8010551d:	e9 0c ff ff ff       	jmp    8010542e <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105522:	e8 0a dd ff ff       	call   80103231 <myproc>
80105527:	85 c0                	test   %eax,%eax
80105529:	74 5f                	je     8010558a <trap+0x1c2>
8010552b:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
8010552f:	74 59                	je     8010558a <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105531:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105534:	8b 43 38             	mov    0x38(%ebx),%eax
80105537:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010553a:	e8 d7 dc ff ff       	call   80103216 <cpuid>
8010553f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105542:	8b 53 34             	mov    0x34(%ebx),%edx
80105545:	89 55 dc             	mov    %edx,-0x24(%ebp)
80105548:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
8010554b:	e8 e1 dc ff ff       	call   80103231 <myproc>
80105550:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105553:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105556:	e8 d6 dc ff ff       	call   80103231 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010555b:	57                   	push   %edi
8010555c:	ff 75 e4             	pushl  -0x1c(%ebp)
8010555f:	ff 75 e0             	pushl  -0x20(%ebp)
80105562:	ff 75 dc             	pushl  -0x24(%ebp)
80105565:	56                   	push   %esi
80105566:	ff 75 d8             	pushl  -0x28(%ebp)
80105569:	ff 70 10             	pushl  0x10(%eax)
8010556c:	68 4c 72 10 80       	push   $0x8010724c
80105571:	e8 95 b0 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105576:	83 c4 20             	add    $0x20,%esp
80105579:	e8 b3 dc ff ff       	call   80103231 <myproc>
8010557e:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80105585:	e9 a4 fe ff ff       	jmp    8010542e <trap+0x66>
8010558a:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010558d:	8b 73 38             	mov    0x38(%ebx),%esi
80105590:	e8 81 dc ff ff       	call   80103216 <cpuid>
80105595:	83 ec 0c             	sub    $0xc,%esp
80105598:	57                   	push   %edi
80105599:	56                   	push   %esi
8010559a:	50                   	push   %eax
8010559b:	ff 73 30             	pushl  0x30(%ebx)
8010559e:	68 18 72 10 80       	push   $0x80107218
801055a3:	e8 63 b0 ff ff       	call   8010060b <cprintf>
      panic("trap");
801055a8:	83 c4 14             	add    $0x14,%esp
801055ab:	68 ee 71 10 80       	push   $0x801071ee
801055b0:	e8 93 ad ff ff       	call   80100348 <panic>
    exit();
801055b5:	e8 d2 e0 ff ff       	call   8010368c <exit>
801055ba:	e9 94 fe ff ff       	jmp    80105453 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
801055bf:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801055c3:	0f 85 a2 fe ff ff    	jne    8010546b <trap+0xa3>
    yield();
801055c9:	e8 87 e1 ff ff       	call   80103755 <yield>
801055ce:	e9 98 fe ff ff       	jmp    8010546b <trap+0xa3>
    exit();
801055d3:	e8 b4 e0 ff ff       	call   8010368c <exit>
801055d8:	e9 b3 fe ff ff       	jmp    80105490 <trap+0xc8>

801055dd <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801055dd:	55                   	push   %ebp
801055de:	89 e5                	mov    %esp,%ebp
  if(!uart)
801055e0:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
801055e7:	74 15                	je     801055fe <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801055e9:	ba fd 03 00 00       	mov    $0x3fd,%edx
801055ee:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801055ef:	a8 01                	test   $0x1,%al
801055f1:	74 12                	je     80105605 <uartgetc+0x28>
801055f3:	ba f8 03 00 00       	mov    $0x3f8,%edx
801055f8:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801055f9:	0f b6 c0             	movzbl %al,%eax
}
801055fc:	5d                   	pop    %ebp
801055fd:	c3                   	ret    
    return -1;
801055fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105603:	eb f7                	jmp    801055fc <uartgetc+0x1f>
    return -1;
80105605:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010560a:	eb f0                	jmp    801055fc <uartgetc+0x1f>

8010560c <uartputc>:
  if(!uart)
8010560c:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105613:	74 3b                	je     80105650 <uartputc+0x44>
{
80105615:	55                   	push   %ebp
80105616:	89 e5                	mov    %esp,%ebp
80105618:	53                   	push   %ebx
80105619:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010561c:	bb 00 00 00 00       	mov    $0x0,%ebx
80105621:	eb 10                	jmp    80105633 <uartputc+0x27>
    microdelay(10);
80105623:	83 ec 0c             	sub    $0xc,%esp
80105626:	6a 0a                	push   $0xa
80105628:	e8 8b cd ff ff       	call   801023b8 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010562d:	83 c3 01             	add    $0x1,%ebx
80105630:	83 c4 10             	add    $0x10,%esp
80105633:	83 fb 7f             	cmp    $0x7f,%ebx
80105636:	7f 0a                	jg     80105642 <uartputc+0x36>
80105638:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010563d:	ec                   	in     (%dx),%al
8010563e:	a8 20                	test   $0x20,%al
80105640:	74 e1                	je     80105623 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105642:	8b 45 08             	mov    0x8(%ebp),%eax
80105645:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010564a:	ee                   	out    %al,(%dx)
}
8010564b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010564e:	c9                   	leave  
8010564f:	c3                   	ret    
80105650:	f3 c3                	repz ret 

80105652 <uartinit>:
{
80105652:	55                   	push   %ebp
80105653:	89 e5                	mov    %esp,%ebp
80105655:	56                   	push   %esi
80105656:	53                   	push   %ebx
80105657:	b9 00 00 00 00       	mov    $0x0,%ecx
8010565c:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105661:	89 c8                	mov    %ecx,%eax
80105663:	ee                   	out    %al,(%dx)
80105664:	be fb 03 00 00       	mov    $0x3fb,%esi
80105669:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010566e:	89 f2                	mov    %esi,%edx
80105670:	ee                   	out    %al,(%dx)
80105671:	b8 0c 00 00 00       	mov    $0xc,%eax
80105676:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010567b:	ee                   	out    %al,(%dx)
8010567c:	bb f9 03 00 00       	mov    $0x3f9,%ebx
80105681:	89 c8                	mov    %ecx,%eax
80105683:	89 da                	mov    %ebx,%edx
80105685:	ee                   	out    %al,(%dx)
80105686:	b8 03 00 00 00       	mov    $0x3,%eax
8010568b:	89 f2                	mov    %esi,%edx
8010568d:	ee                   	out    %al,(%dx)
8010568e:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105693:	89 c8                	mov    %ecx,%eax
80105695:	ee                   	out    %al,(%dx)
80105696:	b8 01 00 00 00       	mov    $0x1,%eax
8010569b:	89 da                	mov    %ebx,%edx
8010569d:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010569e:	ba fd 03 00 00       	mov    $0x3fd,%edx
801056a3:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801056a4:	3c ff                	cmp    $0xff,%al
801056a6:	74 45                	je     801056ed <uartinit+0x9b>
  uart = 1;
801056a8:	c7 05 bc a5 10 80 01 	movl   $0x1,0x8010a5bc
801056af:	00 00 00 
801056b2:	ba fa 03 00 00       	mov    $0x3fa,%edx
801056b7:	ec                   	in     (%dx),%al
801056b8:	ba f8 03 00 00       	mov    $0x3f8,%edx
801056bd:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801056be:	83 ec 08             	sub    $0x8,%esp
801056c1:	6a 00                	push   $0x0
801056c3:	6a 04                	push   $0x4
801056c5:	e8 b4 c8 ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801056ca:	83 c4 10             	add    $0x10,%esp
801056cd:	bb 10 73 10 80       	mov    $0x80107310,%ebx
801056d2:	eb 12                	jmp    801056e6 <uartinit+0x94>
    uartputc(*p);
801056d4:	83 ec 0c             	sub    $0xc,%esp
801056d7:	0f be c0             	movsbl %al,%eax
801056da:	50                   	push   %eax
801056db:	e8 2c ff ff ff       	call   8010560c <uartputc>
  for(p="xv6...\n"; *p; p++)
801056e0:	83 c3 01             	add    $0x1,%ebx
801056e3:	83 c4 10             	add    $0x10,%esp
801056e6:	0f b6 03             	movzbl (%ebx),%eax
801056e9:	84 c0                	test   %al,%al
801056eb:	75 e7                	jne    801056d4 <uartinit+0x82>
}
801056ed:	8d 65 f8             	lea    -0x8(%ebp),%esp
801056f0:	5b                   	pop    %ebx
801056f1:	5e                   	pop    %esi
801056f2:	5d                   	pop    %ebp
801056f3:	c3                   	ret    

801056f4 <uartintr>:

void
uartintr(void)
{
801056f4:	55                   	push   %ebp
801056f5:	89 e5                	mov    %esp,%ebp
801056f7:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801056fa:	68 dd 55 10 80       	push   $0x801055dd
801056ff:	e8 3a b0 ff ff       	call   8010073e <consoleintr>
}
80105704:	83 c4 10             	add    $0x10,%esp
80105707:	c9                   	leave  
80105708:	c3                   	ret    

80105709 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105709:	6a 00                	push   $0x0
  pushl $0
8010570b:	6a 00                	push   $0x0
  jmp alltraps
8010570d:	e9 be fb ff ff       	jmp    801052d0 <alltraps>

80105712 <vector1>:
.globl vector1
vector1:
  pushl $0
80105712:	6a 00                	push   $0x0
  pushl $1
80105714:	6a 01                	push   $0x1
  jmp alltraps
80105716:	e9 b5 fb ff ff       	jmp    801052d0 <alltraps>

8010571b <vector2>:
.globl vector2
vector2:
  pushl $0
8010571b:	6a 00                	push   $0x0
  pushl $2
8010571d:	6a 02                	push   $0x2
  jmp alltraps
8010571f:	e9 ac fb ff ff       	jmp    801052d0 <alltraps>

80105724 <vector3>:
.globl vector3
vector3:
  pushl $0
80105724:	6a 00                	push   $0x0
  pushl $3
80105726:	6a 03                	push   $0x3
  jmp alltraps
80105728:	e9 a3 fb ff ff       	jmp    801052d0 <alltraps>

8010572d <vector4>:
.globl vector4
vector4:
  pushl $0
8010572d:	6a 00                	push   $0x0
  pushl $4
8010572f:	6a 04                	push   $0x4
  jmp alltraps
80105731:	e9 9a fb ff ff       	jmp    801052d0 <alltraps>

80105736 <vector5>:
.globl vector5
vector5:
  pushl $0
80105736:	6a 00                	push   $0x0
  pushl $5
80105738:	6a 05                	push   $0x5
  jmp alltraps
8010573a:	e9 91 fb ff ff       	jmp    801052d0 <alltraps>

8010573f <vector6>:
.globl vector6
vector6:
  pushl $0
8010573f:	6a 00                	push   $0x0
  pushl $6
80105741:	6a 06                	push   $0x6
  jmp alltraps
80105743:	e9 88 fb ff ff       	jmp    801052d0 <alltraps>

80105748 <vector7>:
.globl vector7
vector7:
  pushl $0
80105748:	6a 00                	push   $0x0
  pushl $7
8010574a:	6a 07                	push   $0x7
  jmp alltraps
8010574c:	e9 7f fb ff ff       	jmp    801052d0 <alltraps>

80105751 <vector8>:
.globl vector8
vector8:
  pushl $8
80105751:	6a 08                	push   $0x8
  jmp alltraps
80105753:	e9 78 fb ff ff       	jmp    801052d0 <alltraps>

80105758 <vector9>:
.globl vector9
vector9:
  pushl $0
80105758:	6a 00                	push   $0x0
  pushl $9
8010575a:	6a 09                	push   $0x9
  jmp alltraps
8010575c:	e9 6f fb ff ff       	jmp    801052d0 <alltraps>

80105761 <vector10>:
.globl vector10
vector10:
  pushl $10
80105761:	6a 0a                	push   $0xa
  jmp alltraps
80105763:	e9 68 fb ff ff       	jmp    801052d0 <alltraps>

80105768 <vector11>:
.globl vector11
vector11:
  pushl $11
80105768:	6a 0b                	push   $0xb
  jmp alltraps
8010576a:	e9 61 fb ff ff       	jmp    801052d0 <alltraps>

8010576f <vector12>:
.globl vector12
vector12:
  pushl $12
8010576f:	6a 0c                	push   $0xc
  jmp alltraps
80105771:	e9 5a fb ff ff       	jmp    801052d0 <alltraps>

80105776 <vector13>:
.globl vector13
vector13:
  pushl $13
80105776:	6a 0d                	push   $0xd
  jmp alltraps
80105778:	e9 53 fb ff ff       	jmp    801052d0 <alltraps>

8010577d <vector14>:
.globl vector14
vector14:
  pushl $14
8010577d:	6a 0e                	push   $0xe
  jmp alltraps
8010577f:	e9 4c fb ff ff       	jmp    801052d0 <alltraps>

80105784 <vector15>:
.globl vector15
vector15:
  pushl $0
80105784:	6a 00                	push   $0x0
  pushl $15
80105786:	6a 0f                	push   $0xf
  jmp alltraps
80105788:	e9 43 fb ff ff       	jmp    801052d0 <alltraps>

8010578d <vector16>:
.globl vector16
vector16:
  pushl $0
8010578d:	6a 00                	push   $0x0
  pushl $16
8010578f:	6a 10                	push   $0x10
  jmp alltraps
80105791:	e9 3a fb ff ff       	jmp    801052d0 <alltraps>

80105796 <vector17>:
.globl vector17
vector17:
  pushl $17
80105796:	6a 11                	push   $0x11
  jmp alltraps
80105798:	e9 33 fb ff ff       	jmp    801052d0 <alltraps>

8010579d <vector18>:
.globl vector18
vector18:
  pushl $0
8010579d:	6a 00                	push   $0x0
  pushl $18
8010579f:	6a 12                	push   $0x12
  jmp alltraps
801057a1:	e9 2a fb ff ff       	jmp    801052d0 <alltraps>

801057a6 <vector19>:
.globl vector19
vector19:
  pushl $0
801057a6:	6a 00                	push   $0x0
  pushl $19
801057a8:	6a 13                	push   $0x13
  jmp alltraps
801057aa:	e9 21 fb ff ff       	jmp    801052d0 <alltraps>

801057af <vector20>:
.globl vector20
vector20:
  pushl $0
801057af:	6a 00                	push   $0x0
  pushl $20
801057b1:	6a 14                	push   $0x14
  jmp alltraps
801057b3:	e9 18 fb ff ff       	jmp    801052d0 <alltraps>

801057b8 <vector21>:
.globl vector21
vector21:
  pushl $0
801057b8:	6a 00                	push   $0x0
  pushl $21
801057ba:	6a 15                	push   $0x15
  jmp alltraps
801057bc:	e9 0f fb ff ff       	jmp    801052d0 <alltraps>

801057c1 <vector22>:
.globl vector22
vector22:
  pushl $0
801057c1:	6a 00                	push   $0x0
  pushl $22
801057c3:	6a 16                	push   $0x16
  jmp alltraps
801057c5:	e9 06 fb ff ff       	jmp    801052d0 <alltraps>

801057ca <vector23>:
.globl vector23
vector23:
  pushl $0
801057ca:	6a 00                	push   $0x0
  pushl $23
801057cc:	6a 17                	push   $0x17
  jmp alltraps
801057ce:	e9 fd fa ff ff       	jmp    801052d0 <alltraps>

801057d3 <vector24>:
.globl vector24
vector24:
  pushl $0
801057d3:	6a 00                	push   $0x0
  pushl $24
801057d5:	6a 18                	push   $0x18
  jmp alltraps
801057d7:	e9 f4 fa ff ff       	jmp    801052d0 <alltraps>

801057dc <vector25>:
.globl vector25
vector25:
  pushl $0
801057dc:	6a 00                	push   $0x0
  pushl $25
801057de:	6a 19                	push   $0x19
  jmp alltraps
801057e0:	e9 eb fa ff ff       	jmp    801052d0 <alltraps>

801057e5 <vector26>:
.globl vector26
vector26:
  pushl $0
801057e5:	6a 00                	push   $0x0
  pushl $26
801057e7:	6a 1a                	push   $0x1a
  jmp alltraps
801057e9:	e9 e2 fa ff ff       	jmp    801052d0 <alltraps>

801057ee <vector27>:
.globl vector27
vector27:
  pushl $0
801057ee:	6a 00                	push   $0x0
  pushl $27
801057f0:	6a 1b                	push   $0x1b
  jmp alltraps
801057f2:	e9 d9 fa ff ff       	jmp    801052d0 <alltraps>

801057f7 <vector28>:
.globl vector28
vector28:
  pushl $0
801057f7:	6a 00                	push   $0x0
  pushl $28
801057f9:	6a 1c                	push   $0x1c
  jmp alltraps
801057fb:	e9 d0 fa ff ff       	jmp    801052d0 <alltraps>

80105800 <vector29>:
.globl vector29
vector29:
  pushl $0
80105800:	6a 00                	push   $0x0
  pushl $29
80105802:	6a 1d                	push   $0x1d
  jmp alltraps
80105804:	e9 c7 fa ff ff       	jmp    801052d0 <alltraps>

80105809 <vector30>:
.globl vector30
vector30:
  pushl $0
80105809:	6a 00                	push   $0x0
  pushl $30
8010580b:	6a 1e                	push   $0x1e
  jmp alltraps
8010580d:	e9 be fa ff ff       	jmp    801052d0 <alltraps>

80105812 <vector31>:
.globl vector31
vector31:
  pushl $0
80105812:	6a 00                	push   $0x0
  pushl $31
80105814:	6a 1f                	push   $0x1f
  jmp alltraps
80105816:	e9 b5 fa ff ff       	jmp    801052d0 <alltraps>

8010581b <vector32>:
.globl vector32
vector32:
  pushl $0
8010581b:	6a 00                	push   $0x0
  pushl $32
8010581d:	6a 20                	push   $0x20
  jmp alltraps
8010581f:	e9 ac fa ff ff       	jmp    801052d0 <alltraps>

80105824 <vector33>:
.globl vector33
vector33:
  pushl $0
80105824:	6a 00                	push   $0x0
  pushl $33
80105826:	6a 21                	push   $0x21
  jmp alltraps
80105828:	e9 a3 fa ff ff       	jmp    801052d0 <alltraps>

8010582d <vector34>:
.globl vector34
vector34:
  pushl $0
8010582d:	6a 00                	push   $0x0
  pushl $34
8010582f:	6a 22                	push   $0x22
  jmp alltraps
80105831:	e9 9a fa ff ff       	jmp    801052d0 <alltraps>

80105836 <vector35>:
.globl vector35
vector35:
  pushl $0
80105836:	6a 00                	push   $0x0
  pushl $35
80105838:	6a 23                	push   $0x23
  jmp alltraps
8010583a:	e9 91 fa ff ff       	jmp    801052d0 <alltraps>

8010583f <vector36>:
.globl vector36
vector36:
  pushl $0
8010583f:	6a 00                	push   $0x0
  pushl $36
80105841:	6a 24                	push   $0x24
  jmp alltraps
80105843:	e9 88 fa ff ff       	jmp    801052d0 <alltraps>

80105848 <vector37>:
.globl vector37
vector37:
  pushl $0
80105848:	6a 00                	push   $0x0
  pushl $37
8010584a:	6a 25                	push   $0x25
  jmp alltraps
8010584c:	e9 7f fa ff ff       	jmp    801052d0 <alltraps>

80105851 <vector38>:
.globl vector38
vector38:
  pushl $0
80105851:	6a 00                	push   $0x0
  pushl $38
80105853:	6a 26                	push   $0x26
  jmp alltraps
80105855:	e9 76 fa ff ff       	jmp    801052d0 <alltraps>

8010585a <vector39>:
.globl vector39
vector39:
  pushl $0
8010585a:	6a 00                	push   $0x0
  pushl $39
8010585c:	6a 27                	push   $0x27
  jmp alltraps
8010585e:	e9 6d fa ff ff       	jmp    801052d0 <alltraps>

80105863 <vector40>:
.globl vector40
vector40:
  pushl $0
80105863:	6a 00                	push   $0x0
  pushl $40
80105865:	6a 28                	push   $0x28
  jmp alltraps
80105867:	e9 64 fa ff ff       	jmp    801052d0 <alltraps>

8010586c <vector41>:
.globl vector41
vector41:
  pushl $0
8010586c:	6a 00                	push   $0x0
  pushl $41
8010586e:	6a 29                	push   $0x29
  jmp alltraps
80105870:	e9 5b fa ff ff       	jmp    801052d0 <alltraps>

80105875 <vector42>:
.globl vector42
vector42:
  pushl $0
80105875:	6a 00                	push   $0x0
  pushl $42
80105877:	6a 2a                	push   $0x2a
  jmp alltraps
80105879:	e9 52 fa ff ff       	jmp    801052d0 <alltraps>

8010587e <vector43>:
.globl vector43
vector43:
  pushl $0
8010587e:	6a 00                	push   $0x0
  pushl $43
80105880:	6a 2b                	push   $0x2b
  jmp alltraps
80105882:	e9 49 fa ff ff       	jmp    801052d0 <alltraps>

80105887 <vector44>:
.globl vector44
vector44:
  pushl $0
80105887:	6a 00                	push   $0x0
  pushl $44
80105889:	6a 2c                	push   $0x2c
  jmp alltraps
8010588b:	e9 40 fa ff ff       	jmp    801052d0 <alltraps>

80105890 <vector45>:
.globl vector45
vector45:
  pushl $0
80105890:	6a 00                	push   $0x0
  pushl $45
80105892:	6a 2d                	push   $0x2d
  jmp alltraps
80105894:	e9 37 fa ff ff       	jmp    801052d0 <alltraps>

80105899 <vector46>:
.globl vector46
vector46:
  pushl $0
80105899:	6a 00                	push   $0x0
  pushl $46
8010589b:	6a 2e                	push   $0x2e
  jmp alltraps
8010589d:	e9 2e fa ff ff       	jmp    801052d0 <alltraps>

801058a2 <vector47>:
.globl vector47
vector47:
  pushl $0
801058a2:	6a 00                	push   $0x0
  pushl $47
801058a4:	6a 2f                	push   $0x2f
  jmp alltraps
801058a6:	e9 25 fa ff ff       	jmp    801052d0 <alltraps>

801058ab <vector48>:
.globl vector48
vector48:
  pushl $0
801058ab:	6a 00                	push   $0x0
  pushl $48
801058ad:	6a 30                	push   $0x30
  jmp alltraps
801058af:	e9 1c fa ff ff       	jmp    801052d0 <alltraps>

801058b4 <vector49>:
.globl vector49
vector49:
  pushl $0
801058b4:	6a 00                	push   $0x0
  pushl $49
801058b6:	6a 31                	push   $0x31
  jmp alltraps
801058b8:	e9 13 fa ff ff       	jmp    801052d0 <alltraps>

801058bd <vector50>:
.globl vector50
vector50:
  pushl $0
801058bd:	6a 00                	push   $0x0
  pushl $50
801058bf:	6a 32                	push   $0x32
  jmp alltraps
801058c1:	e9 0a fa ff ff       	jmp    801052d0 <alltraps>

801058c6 <vector51>:
.globl vector51
vector51:
  pushl $0
801058c6:	6a 00                	push   $0x0
  pushl $51
801058c8:	6a 33                	push   $0x33
  jmp alltraps
801058ca:	e9 01 fa ff ff       	jmp    801052d0 <alltraps>

801058cf <vector52>:
.globl vector52
vector52:
  pushl $0
801058cf:	6a 00                	push   $0x0
  pushl $52
801058d1:	6a 34                	push   $0x34
  jmp alltraps
801058d3:	e9 f8 f9 ff ff       	jmp    801052d0 <alltraps>

801058d8 <vector53>:
.globl vector53
vector53:
  pushl $0
801058d8:	6a 00                	push   $0x0
  pushl $53
801058da:	6a 35                	push   $0x35
  jmp alltraps
801058dc:	e9 ef f9 ff ff       	jmp    801052d0 <alltraps>

801058e1 <vector54>:
.globl vector54
vector54:
  pushl $0
801058e1:	6a 00                	push   $0x0
  pushl $54
801058e3:	6a 36                	push   $0x36
  jmp alltraps
801058e5:	e9 e6 f9 ff ff       	jmp    801052d0 <alltraps>

801058ea <vector55>:
.globl vector55
vector55:
  pushl $0
801058ea:	6a 00                	push   $0x0
  pushl $55
801058ec:	6a 37                	push   $0x37
  jmp alltraps
801058ee:	e9 dd f9 ff ff       	jmp    801052d0 <alltraps>

801058f3 <vector56>:
.globl vector56
vector56:
  pushl $0
801058f3:	6a 00                	push   $0x0
  pushl $56
801058f5:	6a 38                	push   $0x38
  jmp alltraps
801058f7:	e9 d4 f9 ff ff       	jmp    801052d0 <alltraps>

801058fc <vector57>:
.globl vector57
vector57:
  pushl $0
801058fc:	6a 00                	push   $0x0
  pushl $57
801058fe:	6a 39                	push   $0x39
  jmp alltraps
80105900:	e9 cb f9 ff ff       	jmp    801052d0 <alltraps>

80105905 <vector58>:
.globl vector58
vector58:
  pushl $0
80105905:	6a 00                	push   $0x0
  pushl $58
80105907:	6a 3a                	push   $0x3a
  jmp alltraps
80105909:	e9 c2 f9 ff ff       	jmp    801052d0 <alltraps>

8010590e <vector59>:
.globl vector59
vector59:
  pushl $0
8010590e:	6a 00                	push   $0x0
  pushl $59
80105910:	6a 3b                	push   $0x3b
  jmp alltraps
80105912:	e9 b9 f9 ff ff       	jmp    801052d0 <alltraps>

80105917 <vector60>:
.globl vector60
vector60:
  pushl $0
80105917:	6a 00                	push   $0x0
  pushl $60
80105919:	6a 3c                	push   $0x3c
  jmp alltraps
8010591b:	e9 b0 f9 ff ff       	jmp    801052d0 <alltraps>

80105920 <vector61>:
.globl vector61
vector61:
  pushl $0
80105920:	6a 00                	push   $0x0
  pushl $61
80105922:	6a 3d                	push   $0x3d
  jmp alltraps
80105924:	e9 a7 f9 ff ff       	jmp    801052d0 <alltraps>

80105929 <vector62>:
.globl vector62
vector62:
  pushl $0
80105929:	6a 00                	push   $0x0
  pushl $62
8010592b:	6a 3e                	push   $0x3e
  jmp alltraps
8010592d:	e9 9e f9 ff ff       	jmp    801052d0 <alltraps>

80105932 <vector63>:
.globl vector63
vector63:
  pushl $0
80105932:	6a 00                	push   $0x0
  pushl $63
80105934:	6a 3f                	push   $0x3f
  jmp alltraps
80105936:	e9 95 f9 ff ff       	jmp    801052d0 <alltraps>

8010593b <vector64>:
.globl vector64
vector64:
  pushl $0
8010593b:	6a 00                	push   $0x0
  pushl $64
8010593d:	6a 40                	push   $0x40
  jmp alltraps
8010593f:	e9 8c f9 ff ff       	jmp    801052d0 <alltraps>

80105944 <vector65>:
.globl vector65
vector65:
  pushl $0
80105944:	6a 00                	push   $0x0
  pushl $65
80105946:	6a 41                	push   $0x41
  jmp alltraps
80105948:	e9 83 f9 ff ff       	jmp    801052d0 <alltraps>

8010594d <vector66>:
.globl vector66
vector66:
  pushl $0
8010594d:	6a 00                	push   $0x0
  pushl $66
8010594f:	6a 42                	push   $0x42
  jmp alltraps
80105951:	e9 7a f9 ff ff       	jmp    801052d0 <alltraps>

80105956 <vector67>:
.globl vector67
vector67:
  pushl $0
80105956:	6a 00                	push   $0x0
  pushl $67
80105958:	6a 43                	push   $0x43
  jmp alltraps
8010595a:	e9 71 f9 ff ff       	jmp    801052d0 <alltraps>

8010595f <vector68>:
.globl vector68
vector68:
  pushl $0
8010595f:	6a 00                	push   $0x0
  pushl $68
80105961:	6a 44                	push   $0x44
  jmp alltraps
80105963:	e9 68 f9 ff ff       	jmp    801052d0 <alltraps>

80105968 <vector69>:
.globl vector69
vector69:
  pushl $0
80105968:	6a 00                	push   $0x0
  pushl $69
8010596a:	6a 45                	push   $0x45
  jmp alltraps
8010596c:	e9 5f f9 ff ff       	jmp    801052d0 <alltraps>

80105971 <vector70>:
.globl vector70
vector70:
  pushl $0
80105971:	6a 00                	push   $0x0
  pushl $70
80105973:	6a 46                	push   $0x46
  jmp alltraps
80105975:	e9 56 f9 ff ff       	jmp    801052d0 <alltraps>

8010597a <vector71>:
.globl vector71
vector71:
  pushl $0
8010597a:	6a 00                	push   $0x0
  pushl $71
8010597c:	6a 47                	push   $0x47
  jmp alltraps
8010597e:	e9 4d f9 ff ff       	jmp    801052d0 <alltraps>

80105983 <vector72>:
.globl vector72
vector72:
  pushl $0
80105983:	6a 00                	push   $0x0
  pushl $72
80105985:	6a 48                	push   $0x48
  jmp alltraps
80105987:	e9 44 f9 ff ff       	jmp    801052d0 <alltraps>

8010598c <vector73>:
.globl vector73
vector73:
  pushl $0
8010598c:	6a 00                	push   $0x0
  pushl $73
8010598e:	6a 49                	push   $0x49
  jmp alltraps
80105990:	e9 3b f9 ff ff       	jmp    801052d0 <alltraps>

80105995 <vector74>:
.globl vector74
vector74:
  pushl $0
80105995:	6a 00                	push   $0x0
  pushl $74
80105997:	6a 4a                	push   $0x4a
  jmp alltraps
80105999:	e9 32 f9 ff ff       	jmp    801052d0 <alltraps>

8010599e <vector75>:
.globl vector75
vector75:
  pushl $0
8010599e:	6a 00                	push   $0x0
  pushl $75
801059a0:	6a 4b                	push   $0x4b
  jmp alltraps
801059a2:	e9 29 f9 ff ff       	jmp    801052d0 <alltraps>

801059a7 <vector76>:
.globl vector76
vector76:
  pushl $0
801059a7:	6a 00                	push   $0x0
  pushl $76
801059a9:	6a 4c                	push   $0x4c
  jmp alltraps
801059ab:	e9 20 f9 ff ff       	jmp    801052d0 <alltraps>

801059b0 <vector77>:
.globl vector77
vector77:
  pushl $0
801059b0:	6a 00                	push   $0x0
  pushl $77
801059b2:	6a 4d                	push   $0x4d
  jmp alltraps
801059b4:	e9 17 f9 ff ff       	jmp    801052d0 <alltraps>

801059b9 <vector78>:
.globl vector78
vector78:
  pushl $0
801059b9:	6a 00                	push   $0x0
  pushl $78
801059bb:	6a 4e                	push   $0x4e
  jmp alltraps
801059bd:	e9 0e f9 ff ff       	jmp    801052d0 <alltraps>

801059c2 <vector79>:
.globl vector79
vector79:
  pushl $0
801059c2:	6a 00                	push   $0x0
  pushl $79
801059c4:	6a 4f                	push   $0x4f
  jmp alltraps
801059c6:	e9 05 f9 ff ff       	jmp    801052d0 <alltraps>

801059cb <vector80>:
.globl vector80
vector80:
  pushl $0
801059cb:	6a 00                	push   $0x0
  pushl $80
801059cd:	6a 50                	push   $0x50
  jmp alltraps
801059cf:	e9 fc f8 ff ff       	jmp    801052d0 <alltraps>

801059d4 <vector81>:
.globl vector81
vector81:
  pushl $0
801059d4:	6a 00                	push   $0x0
  pushl $81
801059d6:	6a 51                	push   $0x51
  jmp alltraps
801059d8:	e9 f3 f8 ff ff       	jmp    801052d0 <alltraps>

801059dd <vector82>:
.globl vector82
vector82:
  pushl $0
801059dd:	6a 00                	push   $0x0
  pushl $82
801059df:	6a 52                	push   $0x52
  jmp alltraps
801059e1:	e9 ea f8 ff ff       	jmp    801052d0 <alltraps>

801059e6 <vector83>:
.globl vector83
vector83:
  pushl $0
801059e6:	6a 00                	push   $0x0
  pushl $83
801059e8:	6a 53                	push   $0x53
  jmp alltraps
801059ea:	e9 e1 f8 ff ff       	jmp    801052d0 <alltraps>

801059ef <vector84>:
.globl vector84
vector84:
  pushl $0
801059ef:	6a 00                	push   $0x0
  pushl $84
801059f1:	6a 54                	push   $0x54
  jmp alltraps
801059f3:	e9 d8 f8 ff ff       	jmp    801052d0 <alltraps>

801059f8 <vector85>:
.globl vector85
vector85:
  pushl $0
801059f8:	6a 00                	push   $0x0
  pushl $85
801059fa:	6a 55                	push   $0x55
  jmp alltraps
801059fc:	e9 cf f8 ff ff       	jmp    801052d0 <alltraps>

80105a01 <vector86>:
.globl vector86
vector86:
  pushl $0
80105a01:	6a 00                	push   $0x0
  pushl $86
80105a03:	6a 56                	push   $0x56
  jmp alltraps
80105a05:	e9 c6 f8 ff ff       	jmp    801052d0 <alltraps>

80105a0a <vector87>:
.globl vector87
vector87:
  pushl $0
80105a0a:	6a 00                	push   $0x0
  pushl $87
80105a0c:	6a 57                	push   $0x57
  jmp alltraps
80105a0e:	e9 bd f8 ff ff       	jmp    801052d0 <alltraps>

80105a13 <vector88>:
.globl vector88
vector88:
  pushl $0
80105a13:	6a 00                	push   $0x0
  pushl $88
80105a15:	6a 58                	push   $0x58
  jmp alltraps
80105a17:	e9 b4 f8 ff ff       	jmp    801052d0 <alltraps>

80105a1c <vector89>:
.globl vector89
vector89:
  pushl $0
80105a1c:	6a 00                	push   $0x0
  pushl $89
80105a1e:	6a 59                	push   $0x59
  jmp alltraps
80105a20:	e9 ab f8 ff ff       	jmp    801052d0 <alltraps>

80105a25 <vector90>:
.globl vector90
vector90:
  pushl $0
80105a25:	6a 00                	push   $0x0
  pushl $90
80105a27:	6a 5a                	push   $0x5a
  jmp alltraps
80105a29:	e9 a2 f8 ff ff       	jmp    801052d0 <alltraps>

80105a2e <vector91>:
.globl vector91
vector91:
  pushl $0
80105a2e:	6a 00                	push   $0x0
  pushl $91
80105a30:	6a 5b                	push   $0x5b
  jmp alltraps
80105a32:	e9 99 f8 ff ff       	jmp    801052d0 <alltraps>

80105a37 <vector92>:
.globl vector92
vector92:
  pushl $0
80105a37:	6a 00                	push   $0x0
  pushl $92
80105a39:	6a 5c                	push   $0x5c
  jmp alltraps
80105a3b:	e9 90 f8 ff ff       	jmp    801052d0 <alltraps>

80105a40 <vector93>:
.globl vector93
vector93:
  pushl $0
80105a40:	6a 00                	push   $0x0
  pushl $93
80105a42:	6a 5d                	push   $0x5d
  jmp alltraps
80105a44:	e9 87 f8 ff ff       	jmp    801052d0 <alltraps>

80105a49 <vector94>:
.globl vector94
vector94:
  pushl $0
80105a49:	6a 00                	push   $0x0
  pushl $94
80105a4b:	6a 5e                	push   $0x5e
  jmp alltraps
80105a4d:	e9 7e f8 ff ff       	jmp    801052d0 <alltraps>

80105a52 <vector95>:
.globl vector95
vector95:
  pushl $0
80105a52:	6a 00                	push   $0x0
  pushl $95
80105a54:	6a 5f                	push   $0x5f
  jmp alltraps
80105a56:	e9 75 f8 ff ff       	jmp    801052d0 <alltraps>

80105a5b <vector96>:
.globl vector96
vector96:
  pushl $0
80105a5b:	6a 00                	push   $0x0
  pushl $96
80105a5d:	6a 60                	push   $0x60
  jmp alltraps
80105a5f:	e9 6c f8 ff ff       	jmp    801052d0 <alltraps>

80105a64 <vector97>:
.globl vector97
vector97:
  pushl $0
80105a64:	6a 00                	push   $0x0
  pushl $97
80105a66:	6a 61                	push   $0x61
  jmp alltraps
80105a68:	e9 63 f8 ff ff       	jmp    801052d0 <alltraps>

80105a6d <vector98>:
.globl vector98
vector98:
  pushl $0
80105a6d:	6a 00                	push   $0x0
  pushl $98
80105a6f:	6a 62                	push   $0x62
  jmp alltraps
80105a71:	e9 5a f8 ff ff       	jmp    801052d0 <alltraps>

80105a76 <vector99>:
.globl vector99
vector99:
  pushl $0
80105a76:	6a 00                	push   $0x0
  pushl $99
80105a78:	6a 63                	push   $0x63
  jmp alltraps
80105a7a:	e9 51 f8 ff ff       	jmp    801052d0 <alltraps>

80105a7f <vector100>:
.globl vector100
vector100:
  pushl $0
80105a7f:	6a 00                	push   $0x0
  pushl $100
80105a81:	6a 64                	push   $0x64
  jmp alltraps
80105a83:	e9 48 f8 ff ff       	jmp    801052d0 <alltraps>

80105a88 <vector101>:
.globl vector101
vector101:
  pushl $0
80105a88:	6a 00                	push   $0x0
  pushl $101
80105a8a:	6a 65                	push   $0x65
  jmp alltraps
80105a8c:	e9 3f f8 ff ff       	jmp    801052d0 <alltraps>

80105a91 <vector102>:
.globl vector102
vector102:
  pushl $0
80105a91:	6a 00                	push   $0x0
  pushl $102
80105a93:	6a 66                	push   $0x66
  jmp alltraps
80105a95:	e9 36 f8 ff ff       	jmp    801052d0 <alltraps>

80105a9a <vector103>:
.globl vector103
vector103:
  pushl $0
80105a9a:	6a 00                	push   $0x0
  pushl $103
80105a9c:	6a 67                	push   $0x67
  jmp alltraps
80105a9e:	e9 2d f8 ff ff       	jmp    801052d0 <alltraps>

80105aa3 <vector104>:
.globl vector104
vector104:
  pushl $0
80105aa3:	6a 00                	push   $0x0
  pushl $104
80105aa5:	6a 68                	push   $0x68
  jmp alltraps
80105aa7:	e9 24 f8 ff ff       	jmp    801052d0 <alltraps>

80105aac <vector105>:
.globl vector105
vector105:
  pushl $0
80105aac:	6a 00                	push   $0x0
  pushl $105
80105aae:	6a 69                	push   $0x69
  jmp alltraps
80105ab0:	e9 1b f8 ff ff       	jmp    801052d0 <alltraps>

80105ab5 <vector106>:
.globl vector106
vector106:
  pushl $0
80105ab5:	6a 00                	push   $0x0
  pushl $106
80105ab7:	6a 6a                	push   $0x6a
  jmp alltraps
80105ab9:	e9 12 f8 ff ff       	jmp    801052d0 <alltraps>

80105abe <vector107>:
.globl vector107
vector107:
  pushl $0
80105abe:	6a 00                	push   $0x0
  pushl $107
80105ac0:	6a 6b                	push   $0x6b
  jmp alltraps
80105ac2:	e9 09 f8 ff ff       	jmp    801052d0 <alltraps>

80105ac7 <vector108>:
.globl vector108
vector108:
  pushl $0
80105ac7:	6a 00                	push   $0x0
  pushl $108
80105ac9:	6a 6c                	push   $0x6c
  jmp alltraps
80105acb:	e9 00 f8 ff ff       	jmp    801052d0 <alltraps>

80105ad0 <vector109>:
.globl vector109
vector109:
  pushl $0
80105ad0:	6a 00                	push   $0x0
  pushl $109
80105ad2:	6a 6d                	push   $0x6d
  jmp alltraps
80105ad4:	e9 f7 f7 ff ff       	jmp    801052d0 <alltraps>

80105ad9 <vector110>:
.globl vector110
vector110:
  pushl $0
80105ad9:	6a 00                	push   $0x0
  pushl $110
80105adb:	6a 6e                	push   $0x6e
  jmp alltraps
80105add:	e9 ee f7 ff ff       	jmp    801052d0 <alltraps>

80105ae2 <vector111>:
.globl vector111
vector111:
  pushl $0
80105ae2:	6a 00                	push   $0x0
  pushl $111
80105ae4:	6a 6f                	push   $0x6f
  jmp alltraps
80105ae6:	e9 e5 f7 ff ff       	jmp    801052d0 <alltraps>

80105aeb <vector112>:
.globl vector112
vector112:
  pushl $0
80105aeb:	6a 00                	push   $0x0
  pushl $112
80105aed:	6a 70                	push   $0x70
  jmp alltraps
80105aef:	e9 dc f7 ff ff       	jmp    801052d0 <alltraps>

80105af4 <vector113>:
.globl vector113
vector113:
  pushl $0
80105af4:	6a 00                	push   $0x0
  pushl $113
80105af6:	6a 71                	push   $0x71
  jmp alltraps
80105af8:	e9 d3 f7 ff ff       	jmp    801052d0 <alltraps>

80105afd <vector114>:
.globl vector114
vector114:
  pushl $0
80105afd:	6a 00                	push   $0x0
  pushl $114
80105aff:	6a 72                	push   $0x72
  jmp alltraps
80105b01:	e9 ca f7 ff ff       	jmp    801052d0 <alltraps>

80105b06 <vector115>:
.globl vector115
vector115:
  pushl $0
80105b06:	6a 00                	push   $0x0
  pushl $115
80105b08:	6a 73                	push   $0x73
  jmp alltraps
80105b0a:	e9 c1 f7 ff ff       	jmp    801052d0 <alltraps>

80105b0f <vector116>:
.globl vector116
vector116:
  pushl $0
80105b0f:	6a 00                	push   $0x0
  pushl $116
80105b11:	6a 74                	push   $0x74
  jmp alltraps
80105b13:	e9 b8 f7 ff ff       	jmp    801052d0 <alltraps>

80105b18 <vector117>:
.globl vector117
vector117:
  pushl $0
80105b18:	6a 00                	push   $0x0
  pushl $117
80105b1a:	6a 75                	push   $0x75
  jmp alltraps
80105b1c:	e9 af f7 ff ff       	jmp    801052d0 <alltraps>

80105b21 <vector118>:
.globl vector118
vector118:
  pushl $0
80105b21:	6a 00                	push   $0x0
  pushl $118
80105b23:	6a 76                	push   $0x76
  jmp alltraps
80105b25:	e9 a6 f7 ff ff       	jmp    801052d0 <alltraps>

80105b2a <vector119>:
.globl vector119
vector119:
  pushl $0
80105b2a:	6a 00                	push   $0x0
  pushl $119
80105b2c:	6a 77                	push   $0x77
  jmp alltraps
80105b2e:	e9 9d f7 ff ff       	jmp    801052d0 <alltraps>

80105b33 <vector120>:
.globl vector120
vector120:
  pushl $0
80105b33:	6a 00                	push   $0x0
  pushl $120
80105b35:	6a 78                	push   $0x78
  jmp alltraps
80105b37:	e9 94 f7 ff ff       	jmp    801052d0 <alltraps>

80105b3c <vector121>:
.globl vector121
vector121:
  pushl $0
80105b3c:	6a 00                	push   $0x0
  pushl $121
80105b3e:	6a 79                	push   $0x79
  jmp alltraps
80105b40:	e9 8b f7 ff ff       	jmp    801052d0 <alltraps>

80105b45 <vector122>:
.globl vector122
vector122:
  pushl $0
80105b45:	6a 00                	push   $0x0
  pushl $122
80105b47:	6a 7a                	push   $0x7a
  jmp alltraps
80105b49:	e9 82 f7 ff ff       	jmp    801052d0 <alltraps>

80105b4e <vector123>:
.globl vector123
vector123:
  pushl $0
80105b4e:	6a 00                	push   $0x0
  pushl $123
80105b50:	6a 7b                	push   $0x7b
  jmp alltraps
80105b52:	e9 79 f7 ff ff       	jmp    801052d0 <alltraps>

80105b57 <vector124>:
.globl vector124
vector124:
  pushl $0
80105b57:	6a 00                	push   $0x0
  pushl $124
80105b59:	6a 7c                	push   $0x7c
  jmp alltraps
80105b5b:	e9 70 f7 ff ff       	jmp    801052d0 <alltraps>

80105b60 <vector125>:
.globl vector125
vector125:
  pushl $0
80105b60:	6a 00                	push   $0x0
  pushl $125
80105b62:	6a 7d                	push   $0x7d
  jmp alltraps
80105b64:	e9 67 f7 ff ff       	jmp    801052d0 <alltraps>

80105b69 <vector126>:
.globl vector126
vector126:
  pushl $0
80105b69:	6a 00                	push   $0x0
  pushl $126
80105b6b:	6a 7e                	push   $0x7e
  jmp alltraps
80105b6d:	e9 5e f7 ff ff       	jmp    801052d0 <alltraps>

80105b72 <vector127>:
.globl vector127
vector127:
  pushl $0
80105b72:	6a 00                	push   $0x0
  pushl $127
80105b74:	6a 7f                	push   $0x7f
  jmp alltraps
80105b76:	e9 55 f7 ff ff       	jmp    801052d0 <alltraps>

80105b7b <vector128>:
.globl vector128
vector128:
  pushl $0
80105b7b:	6a 00                	push   $0x0
  pushl $128
80105b7d:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105b82:	e9 49 f7 ff ff       	jmp    801052d0 <alltraps>

80105b87 <vector129>:
.globl vector129
vector129:
  pushl $0
80105b87:	6a 00                	push   $0x0
  pushl $129
80105b89:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80105b8e:	e9 3d f7 ff ff       	jmp    801052d0 <alltraps>

80105b93 <vector130>:
.globl vector130
vector130:
  pushl $0
80105b93:	6a 00                	push   $0x0
  pushl $130
80105b95:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105b9a:	e9 31 f7 ff ff       	jmp    801052d0 <alltraps>

80105b9f <vector131>:
.globl vector131
vector131:
  pushl $0
80105b9f:	6a 00                	push   $0x0
  pushl $131
80105ba1:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105ba6:	e9 25 f7 ff ff       	jmp    801052d0 <alltraps>

80105bab <vector132>:
.globl vector132
vector132:
  pushl $0
80105bab:	6a 00                	push   $0x0
  pushl $132
80105bad:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105bb2:	e9 19 f7 ff ff       	jmp    801052d0 <alltraps>

80105bb7 <vector133>:
.globl vector133
vector133:
  pushl $0
80105bb7:	6a 00                	push   $0x0
  pushl $133
80105bb9:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105bbe:	e9 0d f7 ff ff       	jmp    801052d0 <alltraps>

80105bc3 <vector134>:
.globl vector134
vector134:
  pushl $0
80105bc3:	6a 00                	push   $0x0
  pushl $134
80105bc5:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105bca:	e9 01 f7 ff ff       	jmp    801052d0 <alltraps>

80105bcf <vector135>:
.globl vector135
vector135:
  pushl $0
80105bcf:	6a 00                	push   $0x0
  pushl $135
80105bd1:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105bd6:	e9 f5 f6 ff ff       	jmp    801052d0 <alltraps>

80105bdb <vector136>:
.globl vector136
vector136:
  pushl $0
80105bdb:	6a 00                	push   $0x0
  pushl $136
80105bdd:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105be2:	e9 e9 f6 ff ff       	jmp    801052d0 <alltraps>

80105be7 <vector137>:
.globl vector137
vector137:
  pushl $0
80105be7:	6a 00                	push   $0x0
  pushl $137
80105be9:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105bee:	e9 dd f6 ff ff       	jmp    801052d0 <alltraps>

80105bf3 <vector138>:
.globl vector138
vector138:
  pushl $0
80105bf3:	6a 00                	push   $0x0
  pushl $138
80105bf5:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105bfa:	e9 d1 f6 ff ff       	jmp    801052d0 <alltraps>

80105bff <vector139>:
.globl vector139
vector139:
  pushl $0
80105bff:	6a 00                	push   $0x0
  pushl $139
80105c01:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105c06:	e9 c5 f6 ff ff       	jmp    801052d0 <alltraps>

80105c0b <vector140>:
.globl vector140
vector140:
  pushl $0
80105c0b:	6a 00                	push   $0x0
  pushl $140
80105c0d:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105c12:	e9 b9 f6 ff ff       	jmp    801052d0 <alltraps>

80105c17 <vector141>:
.globl vector141
vector141:
  pushl $0
80105c17:	6a 00                	push   $0x0
  pushl $141
80105c19:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105c1e:	e9 ad f6 ff ff       	jmp    801052d0 <alltraps>

80105c23 <vector142>:
.globl vector142
vector142:
  pushl $0
80105c23:	6a 00                	push   $0x0
  pushl $142
80105c25:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105c2a:	e9 a1 f6 ff ff       	jmp    801052d0 <alltraps>

80105c2f <vector143>:
.globl vector143
vector143:
  pushl $0
80105c2f:	6a 00                	push   $0x0
  pushl $143
80105c31:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105c36:	e9 95 f6 ff ff       	jmp    801052d0 <alltraps>

80105c3b <vector144>:
.globl vector144
vector144:
  pushl $0
80105c3b:	6a 00                	push   $0x0
  pushl $144
80105c3d:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105c42:	e9 89 f6 ff ff       	jmp    801052d0 <alltraps>

80105c47 <vector145>:
.globl vector145
vector145:
  pushl $0
80105c47:	6a 00                	push   $0x0
  pushl $145
80105c49:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105c4e:	e9 7d f6 ff ff       	jmp    801052d0 <alltraps>

80105c53 <vector146>:
.globl vector146
vector146:
  pushl $0
80105c53:	6a 00                	push   $0x0
  pushl $146
80105c55:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105c5a:	e9 71 f6 ff ff       	jmp    801052d0 <alltraps>

80105c5f <vector147>:
.globl vector147
vector147:
  pushl $0
80105c5f:	6a 00                	push   $0x0
  pushl $147
80105c61:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105c66:	e9 65 f6 ff ff       	jmp    801052d0 <alltraps>

80105c6b <vector148>:
.globl vector148
vector148:
  pushl $0
80105c6b:	6a 00                	push   $0x0
  pushl $148
80105c6d:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105c72:	e9 59 f6 ff ff       	jmp    801052d0 <alltraps>

80105c77 <vector149>:
.globl vector149
vector149:
  pushl $0
80105c77:	6a 00                	push   $0x0
  pushl $149
80105c79:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105c7e:	e9 4d f6 ff ff       	jmp    801052d0 <alltraps>

80105c83 <vector150>:
.globl vector150
vector150:
  pushl $0
80105c83:	6a 00                	push   $0x0
  pushl $150
80105c85:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105c8a:	e9 41 f6 ff ff       	jmp    801052d0 <alltraps>

80105c8f <vector151>:
.globl vector151
vector151:
  pushl $0
80105c8f:	6a 00                	push   $0x0
  pushl $151
80105c91:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105c96:	e9 35 f6 ff ff       	jmp    801052d0 <alltraps>

80105c9b <vector152>:
.globl vector152
vector152:
  pushl $0
80105c9b:	6a 00                	push   $0x0
  pushl $152
80105c9d:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105ca2:	e9 29 f6 ff ff       	jmp    801052d0 <alltraps>

80105ca7 <vector153>:
.globl vector153
vector153:
  pushl $0
80105ca7:	6a 00                	push   $0x0
  pushl $153
80105ca9:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105cae:	e9 1d f6 ff ff       	jmp    801052d0 <alltraps>

80105cb3 <vector154>:
.globl vector154
vector154:
  pushl $0
80105cb3:	6a 00                	push   $0x0
  pushl $154
80105cb5:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105cba:	e9 11 f6 ff ff       	jmp    801052d0 <alltraps>

80105cbf <vector155>:
.globl vector155
vector155:
  pushl $0
80105cbf:	6a 00                	push   $0x0
  pushl $155
80105cc1:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105cc6:	e9 05 f6 ff ff       	jmp    801052d0 <alltraps>

80105ccb <vector156>:
.globl vector156
vector156:
  pushl $0
80105ccb:	6a 00                	push   $0x0
  pushl $156
80105ccd:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105cd2:	e9 f9 f5 ff ff       	jmp    801052d0 <alltraps>

80105cd7 <vector157>:
.globl vector157
vector157:
  pushl $0
80105cd7:	6a 00                	push   $0x0
  pushl $157
80105cd9:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105cde:	e9 ed f5 ff ff       	jmp    801052d0 <alltraps>

80105ce3 <vector158>:
.globl vector158
vector158:
  pushl $0
80105ce3:	6a 00                	push   $0x0
  pushl $158
80105ce5:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105cea:	e9 e1 f5 ff ff       	jmp    801052d0 <alltraps>

80105cef <vector159>:
.globl vector159
vector159:
  pushl $0
80105cef:	6a 00                	push   $0x0
  pushl $159
80105cf1:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105cf6:	e9 d5 f5 ff ff       	jmp    801052d0 <alltraps>

80105cfb <vector160>:
.globl vector160
vector160:
  pushl $0
80105cfb:	6a 00                	push   $0x0
  pushl $160
80105cfd:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105d02:	e9 c9 f5 ff ff       	jmp    801052d0 <alltraps>

80105d07 <vector161>:
.globl vector161
vector161:
  pushl $0
80105d07:	6a 00                	push   $0x0
  pushl $161
80105d09:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105d0e:	e9 bd f5 ff ff       	jmp    801052d0 <alltraps>

80105d13 <vector162>:
.globl vector162
vector162:
  pushl $0
80105d13:	6a 00                	push   $0x0
  pushl $162
80105d15:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105d1a:	e9 b1 f5 ff ff       	jmp    801052d0 <alltraps>

80105d1f <vector163>:
.globl vector163
vector163:
  pushl $0
80105d1f:	6a 00                	push   $0x0
  pushl $163
80105d21:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105d26:	e9 a5 f5 ff ff       	jmp    801052d0 <alltraps>

80105d2b <vector164>:
.globl vector164
vector164:
  pushl $0
80105d2b:	6a 00                	push   $0x0
  pushl $164
80105d2d:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105d32:	e9 99 f5 ff ff       	jmp    801052d0 <alltraps>

80105d37 <vector165>:
.globl vector165
vector165:
  pushl $0
80105d37:	6a 00                	push   $0x0
  pushl $165
80105d39:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105d3e:	e9 8d f5 ff ff       	jmp    801052d0 <alltraps>

80105d43 <vector166>:
.globl vector166
vector166:
  pushl $0
80105d43:	6a 00                	push   $0x0
  pushl $166
80105d45:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105d4a:	e9 81 f5 ff ff       	jmp    801052d0 <alltraps>

80105d4f <vector167>:
.globl vector167
vector167:
  pushl $0
80105d4f:	6a 00                	push   $0x0
  pushl $167
80105d51:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105d56:	e9 75 f5 ff ff       	jmp    801052d0 <alltraps>

80105d5b <vector168>:
.globl vector168
vector168:
  pushl $0
80105d5b:	6a 00                	push   $0x0
  pushl $168
80105d5d:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105d62:	e9 69 f5 ff ff       	jmp    801052d0 <alltraps>

80105d67 <vector169>:
.globl vector169
vector169:
  pushl $0
80105d67:	6a 00                	push   $0x0
  pushl $169
80105d69:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105d6e:	e9 5d f5 ff ff       	jmp    801052d0 <alltraps>

80105d73 <vector170>:
.globl vector170
vector170:
  pushl $0
80105d73:	6a 00                	push   $0x0
  pushl $170
80105d75:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105d7a:	e9 51 f5 ff ff       	jmp    801052d0 <alltraps>

80105d7f <vector171>:
.globl vector171
vector171:
  pushl $0
80105d7f:	6a 00                	push   $0x0
  pushl $171
80105d81:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105d86:	e9 45 f5 ff ff       	jmp    801052d0 <alltraps>

80105d8b <vector172>:
.globl vector172
vector172:
  pushl $0
80105d8b:	6a 00                	push   $0x0
  pushl $172
80105d8d:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105d92:	e9 39 f5 ff ff       	jmp    801052d0 <alltraps>

80105d97 <vector173>:
.globl vector173
vector173:
  pushl $0
80105d97:	6a 00                	push   $0x0
  pushl $173
80105d99:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105d9e:	e9 2d f5 ff ff       	jmp    801052d0 <alltraps>

80105da3 <vector174>:
.globl vector174
vector174:
  pushl $0
80105da3:	6a 00                	push   $0x0
  pushl $174
80105da5:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105daa:	e9 21 f5 ff ff       	jmp    801052d0 <alltraps>

80105daf <vector175>:
.globl vector175
vector175:
  pushl $0
80105daf:	6a 00                	push   $0x0
  pushl $175
80105db1:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105db6:	e9 15 f5 ff ff       	jmp    801052d0 <alltraps>

80105dbb <vector176>:
.globl vector176
vector176:
  pushl $0
80105dbb:	6a 00                	push   $0x0
  pushl $176
80105dbd:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105dc2:	e9 09 f5 ff ff       	jmp    801052d0 <alltraps>

80105dc7 <vector177>:
.globl vector177
vector177:
  pushl $0
80105dc7:	6a 00                	push   $0x0
  pushl $177
80105dc9:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105dce:	e9 fd f4 ff ff       	jmp    801052d0 <alltraps>

80105dd3 <vector178>:
.globl vector178
vector178:
  pushl $0
80105dd3:	6a 00                	push   $0x0
  pushl $178
80105dd5:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105dda:	e9 f1 f4 ff ff       	jmp    801052d0 <alltraps>

80105ddf <vector179>:
.globl vector179
vector179:
  pushl $0
80105ddf:	6a 00                	push   $0x0
  pushl $179
80105de1:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105de6:	e9 e5 f4 ff ff       	jmp    801052d0 <alltraps>

80105deb <vector180>:
.globl vector180
vector180:
  pushl $0
80105deb:	6a 00                	push   $0x0
  pushl $180
80105ded:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105df2:	e9 d9 f4 ff ff       	jmp    801052d0 <alltraps>

80105df7 <vector181>:
.globl vector181
vector181:
  pushl $0
80105df7:	6a 00                	push   $0x0
  pushl $181
80105df9:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105dfe:	e9 cd f4 ff ff       	jmp    801052d0 <alltraps>

80105e03 <vector182>:
.globl vector182
vector182:
  pushl $0
80105e03:	6a 00                	push   $0x0
  pushl $182
80105e05:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105e0a:	e9 c1 f4 ff ff       	jmp    801052d0 <alltraps>

80105e0f <vector183>:
.globl vector183
vector183:
  pushl $0
80105e0f:	6a 00                	push   $0x0
  pushl $183
80105e11:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105e16:	e9 b5 f4 ff ff       	jmp    801052d0 <alltraps>

80105e1b <vector184>:
.globl vector184
vector184:
  pushl $0
80105e1b:	6a 00                	push   $0x0
  pushl $184
80105e1d:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105e22:	e9 a9 f4 ff ff       	jmp    801052d0 <alltraps>

80105e27 <vector185>:
.globl vector185
vector185:
  pushl $0
80105e27:	6a 00                	push   $0x0
  pushl $185
80105e29:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105e2e:	e9 9d f4 ff ff       	jmp    801052d0 <alltraps>

80105e33 <vector186>:
.globl vector186
vector186:
  pushl $0
80105e33:	6a 00                	push   $0x0
  pushl $186
80105e35:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105e3a:	e9 91 f4 ff ff       	jmp    801052d0 <alltraps>

80105e3f <vector187>:
.globl vector187
vector187:
  pushl $0
80105e3f:	6a 00                	push   $0x0
  pushl $187
80105e41:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105e46:	e9 85 f4 ff ff       	jmp    801052d0 <alltraps>

80105e4b <vector188>:
.globl vector188
vector188:
  pushl $0
80105e4b:	6a 00                	push   $0x0
  pushl $188
80105e4d:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105e52:	e9 79 f4 ff ff       	jmp    801052d0 <alltraps>

80105e57 <vector189>:
.globl vector189
vector189:
  pushl $0
80105e57:	6a 00                	push   $0x0
  pushl $189
80105e59:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105e5e:	e9 6d f4 ff ff       	jmp    801052d0 <alltraps>

80105e63 <vector190>:
.globl vector190
vector190:
  pushl $0
80105e63:	6a 00                	push   $0x0
  pushl $190
80105e65:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105e6a:	e9 61 f4 ff ff       	jmp    801052d0 <alltraps>

80105e6f <vector191>:
.globl vector191
vector191:
  pushl $0
80105e6f:	6a 00                	push   $0x0
  pushl $191
80105e71:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105e76:	e9 55 f4 ff ff       	jmp    801052d0 <alltraps>

80105e7b <vector192>:
.globl vector192
vector192:
  pushl $0
80105e7b:	6a 00                	push   $0x0
  pushl $192
80105e7d:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105e82:	e9 49 f4 ff ff       	jmp    801052d0 <alltraps>

80105e87 <vector193>:
.globl vector193
vector193:
  pushl $0
80105e87:	6a 00                	push   $0x0
  pushl $193
80105e89:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105e8e:	e9 3d f4 ff ff       	jmp    801052d0 <alltraps>

80105e93 <vector194>:
.globl vector194
vector194:
  pushl $0
80105e93:	6a 00                	push   $0x0
  pushl $194
80105e95:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105e9a:	e9 31 f4 ff ff       	jmp    801052d0 <alltraps>

80105e9f <vector195>:
.globl vector195
vector195:
  pushl $0
80105e9f:	6a 00                	push   $0x0
  pushl $195
80105ea1:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105ea6:	e9 25 f4 ff ff       	jmp    801052d0 <alltraps>

80105eab <vector196>:
.globl vector196
vector196:
  pushl $0
80105eab:	6a 00                	push   $0x0
  pushl $196
80105ead:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105eb2:	e9 19 f4 ff ff       	jmp    801052d0 <alltraps>

80105eb7 <vector197>:
.globl vector197
vector197:
  pushl $0
80105eb7:	6a 00                	push   $0x0
  pushl $197
80105eb9:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105ebe:	e9 0d f4 ff ff       	jmp    801052d0 <alltraps>

80105ec3 <vector198>:
.globl vector198
vector198:
  pushl $0
80105ec3:	6a 00                	push   $0x0
  pushl $198
80105ec5:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105eca:	e9 01 f4 ff ff       	jmp    801052d0 <alltraps>

80105ecf <vector199>:
.globl vector199
vector199:
  pushl $0
80105ecf:	6a 00                	push   $0x0
  pushl $199
80105ed1:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105ed6:	e9 f5 f3 ff ff       	jmp    801052d0 <alltraps>

80105edb <vector200>:
.globl vector200
vector200:
  pushl $0
80105edb:	6a 00                	push   $0x0
  pushl $200
80105edd:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105ee2:	e9 e9 f3 ff ff       	jmp    801052d0 <alltraps>

80105ee7 <vector201>:
.globl vector201
vector201:
  pushl $0
80105ee7:	6a 00                	push   $0x0
  pushl $201
80105ee9:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105eee:	e9 dd f3 ff ff       	jmp    801052d0 <alltraps>

80105ef3 <vector202>:
.globl vector202
vector202:
  pushl $0
80105ef3:	6a 00                	push   $0x0
  pushl $202
80105ef5:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105efa:	e9 d1 f3 ff ff       	jmp    801052d0 <alltraps>

80105eff <vector203>:
.globl vector203
vector203:
  pushl $0
80105eff:	6a 00                	push   $0x0
  pushl $203
80105f01:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105f06:	e9 c5 f3 ff ff       	jmp    801052d0 <alltraps>

80105f0b <vector204>:
.globl vector204
vector204:
  pushl $0
80105f0b:	6a 00                	push   $0x0
  pushl $204
80105f0d:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105f12:	e9 b9 f3 ff ff       	jmp    801052d0 <alltraps>

80105f17 <vector205>:
.globl vector205
vector205:
  pushl $0
80105f17:	6a 00                	push   $0x0
  pushl $205
80105f19:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105f1e:	e9 ad f3 ff ff       	jmp    801052d0 <alltraps>

80105f23 <vector206>:
.globl vector206
vector206:
  pushl $0
80105f23:	6a 00                	push   $0x0
  pushl $206
80105f25:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105f2a:	e9 a1 f3 ff ff       	jmp    801052d0 <alltraps>

80105f2f <vector207>:
.globl vector207
vector207:
  pushl $0
80105f2f:	6a 00                	push   $0x0
  pushl $207
80105f31:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105f36:	e9 95 f3 ff ff       	jmp    801052d0 <alltraps>

80105f3b <vector208>:
.globl vector208
vector208:
  pushl $0
80105f3b:	6a 00                	push   $0x0
  pushl $208
80105f3d:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105f42:	e9 89 f3 ff ff       	jmp    801052d0 <alltraps>

80105f47 <vector209>:
.globl vector209
vector209:
  pushl $0
80105f47:	6a 00                	push   $0x0
  pushl $209
80105f49:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105f4e:	e9 7d f3 ff ff       	jmp    801052d0 <alltraps>

80105f53 <vector210>:
.globl vector210
vector210:
  pushl $0
80105f53:	6a 00                	push   $0x0
  pushl $210
80105f55:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105f5a:	e9 71 f3 ff ff       	jmp    801052d0 <alltraps>

80105f5f <vector211>:
.globl vector211
vector211:
  pushl $0
80105f5f:	6a 00                	push   $0x0
  pushl $211
80105f61:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105f66:	e9 65 f3 ff ff       	jmp    801052d0 <alltraps>

80105f6b <vector212>:
.globl vector212
vector212:
  pushl $0
80105f6b:	6a 00                	push   $0x0
  pushl $212
80105f6d:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105f72:	e9 59 f3 ff ff       	jmp    801052d0 <alltraps>

80105f77 <vector213>:
.globl vector213
vector213:
  pushl $0
80105f77:	6a 00                	push   $0x0
  pushl $213
80105f79:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105f7e:	e9 4d f3 ff ff       	jmp    801052d0 <alltraps>

80105f83 <vector214>:
.globl vector214
vector214:
  pushl $0
80105f83:	6a 00                	push   $0x0
  pushl $214
80105f85:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105f8a:	e9 41 f3 ff ff       	jmp    801052d0 <alltraps>

80105f8f <vector215>:
.globl vector215
vector215:
  pushl $0
80105f8f:	6a 00                	push   $0x0
  pushl $215
80105f91:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105f96:	e9 35 f3 ff ff       	jmp    801052d0 <alltraps>

80105f9b <vector216>:
.globl vector216
vector216:
  pushl $0
80105f9b:	6a 00                	push   $0x0
  pushl $216
80105f9d:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105fa2:	e9 29 f3 ff ff       	jmp    801052d0 <alltraps>

80105fa7 <vector217>:
.globl vector217
vector217:
  pushl $0
80105fa7:	6a 00                	push   $0x0
  pushl $217
80105fa9:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105fae:	e9 1d f3 ff ff       	jmp    801052d0 <alltraps>

80105fb3 <vector218>:
.globl vector218
vector218:
  pushl $0
80105fb3:	6a 00                	push   $0x0
  pushl $218
80105fb5:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105fba:	e9 11 f3 ff ff       	jmp    801052d0 <alltraps>

80105fbf <vector219>:
.globl vector219
vector219:
  pushl $0
80105fbf:	6a 00                	push   $0x0
  pushl $219
80105fc1:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105fc6:	e9 05 f3 ff ff       	jmp    801052d0 <alltraps>

80105fcb <vector220>:
.globl vector220
vector220:
  pushl $0
80105fcb:	6a 00                	push   $0x0
  pushl $220
80105fcd:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105fd2:	e9 f9 f2 ff ff       	jmp    801052d0 <alltraps>

80105fd7 <vector221>:
.globl vector221
vector221:
  pushl $0
80105fd7:	6a 00                	push   $0x0
  pushl $221
80105fd9:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105fde:	e9 ed f2 ff ff       	jmp    801052d0 <alltraps>

80105fe3 <vector222>:
.globl vector222
vector222:
  pushl $0
80105fe3:	6a 00                	push   $0x0
  pushl $222
80105fe5:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105fea:	e9 e1 f2 ff ff       	jmp    801052d0 <alltraps>

80105fef <vector223>:
.globl vector223
vector223:
  pushl $0
80105fef:	6a 00                	push   $0x0
  pushl $223
80105ff1:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105ff6:	e9 d5 f2 ff ff       	jmp    801052d0 <alltraps>

80105ffb <vector224>:
.globl vector224
vector224:
  pushl $0
80105ffb:	6a 00                	push   $0x0
  pushl $224
80105ffd:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80106002:	e9 c9 f2 ff ff       	jmp    801052d0 <alltraps>

80106007 <vector225>:
.globl vector225
vector225:
  pushl $0
80106007:	6a 00                	push   $0x0
  pushl $225
80106009:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
8010600e:	e9 bd f2 ff ff       	jmp    801052d0 <alltraps>

80106013 <vector226>:
.globl vector226
vector226:
  pushl $0
80106013:	6a 00                	push   $0x0
  pushl $226
80106015:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
8010601a:	e9 b1 f2 ff ff       	jmp    801052d0 <alltraps>

8010601f <vector227>:
.globl vector227
vector227:
  pushl $0
8010601f:	6a 00                	push   $0x0
  pushl $227
80106021:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80106026:	e9 a5 f2 ff ff       	jmp    801052d0 <alltraps>

8010602b <vector228>:
.globl vector228
vector228:
  pushl $0
8010602b:	6a 00                	push   $0x0
  pushl $228
8010602d:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80106032:	e9 99 f2 ff ff       	jmp    801052d0 <alltraps>

80106037 <vector229>:
.globl vector229
vector229:
  pushl $0
80106037:	6a 00                	push   $0x0
  pushl $229
80106039:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
8010603e:	e9 8d f2 ff ff       	jmp    801052d0 <alltraps>

80106043 <vector230>:
.globl vector230
vector230:
  pushl $0
80106043:	6a 00                	push   $0x0
  pushl $230
80106045:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
8010604a:	e9 81 f2 ff ff       	jmp    801052d0 <alltraps>

8010604f <vector231>:
.globl vector231
vector231:
  pushl $0
8010604f:	6a 00                	push   $0x0
  pushl $231
80106051:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80106056:	e9 75 f2 ff ff       	jmp    801052d0 <alltraps>

8010605b <vector232>:
.globl vector232
vector232:
  pushl $0
8010605b:	6a 00                	push   $0x0
  pushl $232
8010605d:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80106062:	e9 69 f2 ff ff       	jmp    801052d0 <alltraps>

80106067 <vector233>:
.globl vector233
vector233:
  pushl $0
80106067:	6a 00                	push   $0x0
  pushl $233
80106069:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
8010606e:	e9 5d f2 ff ff       	jmp    801052d0 <alltraps>

80106073 <vector234>:
.globl vector234
vector234:
  pushl $0
80106073:	6a 00                	push   $0x0
  pushl $234
80106075:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010607a:	e9 51 f2 ff ff       	jmp    801052d0 <alltraps>

8010607f <vector235>:
.globl vector235
vector235:
  pushl $0
8010607f:	6a 00                	push   $0x0
  pushl $235
80106081:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80106086:	e9 45 f2 ff ff       	jmp    801052d0 <alltraps>

8010608b <vector236>:
.globl vector236
vector236:
  pushl $0
8010608b:	6a 00                	push   $0x0
  pushl $236
8010608d:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80106092:	e9 39 f2 ff ff       	jmp    801052d0 <alltraps>

80106097 <vector237>:
.globl vector237
vector237:
  pushl $0
80106097:	6a 00                	push   $0x0
  pushl $237
80106099:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
8010609e:	e9 2d f2 ff ff       	jmp    801052d0 <alltraps>

801060a3 <vector238>:
.globl vector238
vector238:
  pushl $0
801060a3:	6a 00                	push   $0x0
  pushl $238
801060a5:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801060aa:	e9 21 f2 ff ff       	jmp    801052d0 <alltraps>

801060af <vector239>:
.globl vector239
vector239:
  pushl $0
801060af:	6a 00                	push   $0x0
  pushl $239
801060b1:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801060b6:	e9 15 f2 ff ff       	jmp    801052d0 <alltraps>

801060bb <vector240>:
.globl vector240
vector240:
  pushl $0
801060bb:	6a 00                	push   $0x0
  pushl $240
801060bd:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801060c2:	e9 09 f2 ff ff       	jmp    801052d0 <alltraps>

801060c7 <vector241>:
.globl vector241
vector241:
  pushl $0
801060c7:	6a 00                	push   $0x0
  pushl $241
801060c9:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801060ce:	e9 fd f1 ff ff       	jmp    801052d0 <alltraps>

801060d3 <vector242>:
.globl vector242
vector242:
  pushl $0
801060d3:	6a 00                	push   $0x0
  pushl $242
801060d5:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801060da:	e9 f1 f1 ff ff       	jmp    801052d0 <alltraps>

801060df <vector243>:
.globl vector243
vector243:
  pushl $0
801060df:	6a 00                	push   $0x0
  pushl $243
801060e1:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801060e6:	e9 e5 f1 ff ff       	jmp    801052d0 <alltraps>

801060eb <vector244>:
.globl vector244
vector244:
  pushl $0
801060eb:	6a 00                	push   $0x0
  pushl $244
801060ed:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801060f2:	e9 d9 f1 ff ff       	jmp    801052d0 <alltraps>

801060f7 <vector245>:
.globl vector245
vector245:
  pushl $0
801060f7:	6a 00                	push   $0x0
  pushl $245
801060f9:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801060fe:	e9 cd f1 ff ff       	jmp    801052d0 <alltraps>

80106103 <vector246>:
.globl vector246
vector246:
  pushl $0
80106103:	6a 00                	push   $0x0
  pushl $246
80106105:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
8010610a:	e9 c1 f1 ff ff       	jmp    801052d0 <alltraps>

8010610f <vector247>:
.globl vector247
vector247:
  pushl $0
8010610f:	6a 00                	push   $0x0
  pushl $247
80106111:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80106116:	e9 b5 f1 ff ff       	jmp    801052d0 <alltraps>

8010611b <vector248>:
.globl vector248
vector248:
  pushl $0
8010611b:	6a 00                	push   $0x0
  pushl $248
8010611d:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80106122:	e9 a9 f1 ff ff       	jmp    801052d0 <alltraps>

80106127 <vector249>:
.globl vector249
vector249:
  pushl $0
80106127:	6a 00                	push   $0x0
  pushl $249
80106129:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
8010612e:	e9 9d f1 ff ff       	jmp    801052d0 <alltraps>

80106133 <vector250>:
.globl vector250
vector250:
  pushl $0
80106133:	6a 00                	push   $0x0
  pushl $250
80106135:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
8010613a:	e9 91 f1 ff ff       	jmp    801052d0 <alltraps>

8010613f <vector251>:
.globl vector251
vector251:
  pushl $0
8010613f:	6a 00                	push   $0x0
  pushl $251
80106141:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80106146:	e9 85 f1 ff ff       	jmp    801052d0 <alltraps>

8010614b <vector252>:
.globl vector252
vector252:
  pushl $0
8010614b:	6a 00                	push   $0x0
  pushl $252
8010614d:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80106152:	e9 79 f1 ff ff       	jmp    801052d0 <alltraps>

80106157 <vector253>:
.globl vector253
vector253:
  pushl $0
80106157:	6a 00                	push   $0x0
  pushl $253
80106159:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
8010615e:	e9 6d f1 ff ff       	jmp    801052d0 <alltraps>

80106163 <vector254>:
.globl vector254
vector254:
  pushl $0
80106163:	6a 00                	push   $0x0
  pushl $254
80106165:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010616a:	e9 61 f1 ff ff       	jmp    801052d0 <alltraps>

8010616f <vector255>:
.globl vector255
vector255:
  pushl $0
8010616f:	6a 00                	push   $0x0
  pushl $255
80106171:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80106176:	e9 55 f1 ff ff       	jmp    801052d0 <alltraps>

8010617b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010617b:	55                   	push   %ebp
8010617c:	89 e5                	mov    %esp,%ebp
8010617e:	57                   	push   %edi
8010617f:	56                   	push   %esi
80106180:	53                   	push   %ebx
80106181:	83 ec 0c             	sub    $0xc,%esp
80106184:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80106186:	c1 ea 16             	shr    $0x16,%edx
80106189:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
8010618c:	8b 1f                	mov    (%edi),%ebx
8010618e:	f6 c3 01             	test   $0x1,%bl
80106191:	74 22                	je     801061b5 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80106193:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80106199:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
8010619f:	c1 ee 0c             	shr    $0xc,%esi
801061a2:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
801061a8:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
801061ab:	89 d8                	mov    %ebx,%eax
801061ad:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061b0:	5b                   	pop    %ebx
801061b1:	5e                   	pop    %esi
801061b2:	5f                   	pop    %edi
801061b3:	5d                   	pop    %ebp
801061b4:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801061b5:	85 c9                	test   %ecx,%ecx
801061b7:	74 2b                	je     801061e4 <walkpgdir+0x69>
801061b9:	e8 fd be ff ff       	call   801020bb <kalloc>
801061be:	89 c3                	mov    %eax,%ebx
801061c0:	85 c0                	test   %eax,%eax
801061c2:	74 e7                	je     801061ab <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
801061c4:	83 ec 04             	sub    $0x4,%esp
801061c7:	68 00 10 00 00       	push   $0x1000
801061cc:	6a 00                	push   $0x0
801061ce:	50                   	push   %eax
801061cf:	e8 92 df ff ff       	call   80104166 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
801061d4:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801061da:	83 c8 07             	or     $0x7,%eax
801061dd:	89 07                	mov    %eax,(%edi)
801061df:	83 c4 10             	add    $0x10,%esp
801061e2:	eb bb                	jmp    8010619f <walkpgdir+0x24>
      return 0;
801061e4:	bb 00 00 00 00       	mov    $0x0,%ebx
801061e9:	eb c0                	jmp    801061ab <walkpgdir+0x30>

801061eb <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801061eb:	55                   	push   %ebp
801061ec:	89 e5                	mov    %esp,%ebp
801061ee:	57                   	push   %edi
801061ef:	56                   	push   %esi
801061f0:	53                   	push   %ebx
801061f1:	83 ec 1c             	sub    $0x1c,%esp
801061f4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801061f7:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
801061fa:	89 d3                	mov    %edx,%ebx
801061fc:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80106202:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80106206:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010620c:	b9 01 00 00 00       	mov    $0x1,%ecx
80106211:	89 da                	mov    %ebx,%edx
80106213:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106216:	e8 60 ff ff ff       	call   8010617b <walkpgdir>
8010621b:	85 c0                	test   %eax,%eax
8010621d:	74 2e                	je     8010624d <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
8010621f:	f6 00 01             	testb  $0x1,(%eax)
80106222:	75 1c                	jne    80106240 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80106224:	89 f2                	mov    %esi,%edx
80106226:	0b 55 0c             	or     0xc(%ebp),%edx
80106229:	83 ca 01             	or     $0x1,%edx
8010622c:	89 10                	mov    %edx,(%eax)
    if(a == last)
8010622e:	39 fb                	cmp    %edi,%ebx
80106230:	74 28                	je     8010625a <mappages+0x6f>
      break;
    a += PGSIZE;
80106232:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80106238:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010623e:	eb cc                	jmp    8010620c <mappages+0x21>
      panic("remap");
80106240:	83 ec 0c             	sub    $0xc,%esp
80106243:	68 18 73 10 80       	push   $0x80107318
80106248:	e8 fb a0 ff ff       	call   80100348 <panic>
      return -1;
8010624d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80106252:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106255:	5b                   	pop    %ebx
80106256:	5e                   	pop    %esi
80106257:	5f                   	pop    %edi
80106258:	5d                   	pop    %ebp
80106259:	c3                   	ret    
  return 0;
8010625a:	b8 00 00 00 00       	mov    $0x0,%eax
8010625f:	eb f1                	jmp    80106252 <mappages+0x67>

80106261 <seginit>:
{
80106261:	55                   	push   %ebp
80106262:	89 e5                	mov    %esp,%ebp
80106264:	53                   	push   %ebx
80106265:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80106268:	e8 a9 cf ff ff       	call   80103216 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010626d:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80106273:	66 c7 80 f8 27 11 80 	movw   $0xffff,-0x7feed808(%eax)
8010627a:	ff ff 
8010627c:	66 c7 80 fa 27 11 80 	movw   $0x0,-0x7feed806(%eax)
80106283:	00 00 
80106285:	c6 80 fc 27 11 80 00 	movb   $0x0,-0x7feed804(%eax)
8010628c:	0f b6 88 fd 27 11 80 	movzbl -0x7feed803(%eax),%ecx
80106293:	83 e1 f0             	and    $0xfffffff0,%ecx
80106296:	83 c9 1a             	or     $0x1a,%ecx
80106299:	83 e1 9f             	and    $0xffffff9f,%ecx
8010629c:	83 c9 80             	or     $0xffffff80,%ecx
8010629f:	88 88 fd 27 11 80    	mov    %cl,-0x7feed803(%eax)
801062a5:	0f b6 88 fe 27 11 80 	movzbl -0x7feed802(%eax),%ecx
801062ac:	83 c9 0f             	or     $0xf,%ecx
801062af:	83 e1 cf             	and    $0xffffffcf,%ecx
801062b2:	83 c9 c0             	or     $0xffffffc0,%ecx
801062b5:	88 88 fe 27 11 80    	mov    %cl,-0x7feed802(%eax)
801062bb:	c6 80 ff 27 11 80 00 	movb   $0x0,-0x7feed801(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801062c2:	66 c7 80 00 28 11 80 	movw   $0xffff,-0x7feed800(%eax)
801062c9:	ff ff 
801062cb:	66 c7 80 02 28 11 80 	movw   $0x0,-0x7feed7fe(%eax)
801062d2:	00 00 
801062d4:	c6 80 04 28 11 80 00 	movb   $0x0,-0x7feed7fc(%eax)
801062db:	0f b6 88 05 28 11 80 	movzbl -0x7feed7fb(%eax),%ecx
801062e2:	83 e1 f0             	and    $0xfffffff0,%ecx
801062e5:	83 c9 12             	or     $0x12,%ecx
801062e8:	83 e1 9f             	and    $0xffffff9f,%ecx
801062eb:	83 c9 80             	or     $0xffffff80,%ecx
801062ee:	88 88 05 28 11 80    	mov    %cl,-0x7feed7fb(%eax)
801062f4:	0f b6 88 06 28 11 80 	movzbl -0x7feed7fa(%eax),%ecx
801062fb:	83 c9 0f             	or     $0xf,%ecx
801062fe:	83 e1 cf             	and    $0xffffffcf,%ecx
80106301:	83 c9 c0             	or     $0xffffffc0,%ecx
80106304:	88 88 06 28 11 80    	mov    %cl,-0x7feed7fa(%eax)
8010630a:	c6 80 07 28 11 80 00 	movb   $0x0,-0x7feed7f9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80106311:	66 c7 80 08 28 11 80 	movw   $0xffff,-0x7feed7f8(%eax)
80106318:	ff ff 
8010631a:	66 c7 80 0a 28 11 80 	movw   $0x0,-0x7feed7f6(%eax)
80106321:	00 00 
80106323:	c6 80 0c 28 11 80 00 	movb   $0x0,-0x7feed7f4(%eax)
8010632a:	c6 80 0d 28 11 80 fa 	movb   $0xfa,-0x7feed7f3(%eax)
80106331:	0f b6 88 0e 28 11 80 	movzbl -0x7feed7f2(%eax),%ecx
80106338:	83 c9 0f             	or     $0xf,%ecx
8010633b:	83 e1 cf             	and    $0xffffffcf,%ecx
8010633e:	83 c9 c0             	or     $0xffffffc0,%ecx
80106341:	88 88 0e 28 11 80    	mov    %cl,-0x7feed7f2(%eax)
80106347:	c6 80 0f 28 11 80 00 	movb   $0x0,-0x7feed7f1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010634e:	66 c7 80 10 28 11 80 	movw   $0xffff,-0x7feed7f0(%eax)
80106355:	ff ff 
80106357:	66 c7 80 12 28 11 80 	movw   $0x0,-0x7feed7ee(%eax)
8010635e:	00 00 
80106360:	c6 80 14 28 11 80 00 	movb   $0x0,-0x7feed7ec(%eax)
80106367:	c6 80 15 28 11 80 f2 	movb   $0xf2,-0x7feed7eb(%eax)
8010636e:	0f b6 88 16 28 11 80 	movzbl -0x7feed7ea(%eax),%ecx
80106375:	83 c9 0f             	or     $0xf,%ecx
80106378:	83 e1 cf             	and    $0xffffffcf,%ecx
8010637b:	83 c9 c0             	or     $0xffffffc0,%ecx
8010637e:	88 88 16 28 11 80    	mov    %cl,-0x7feed7ea(%eax)
80106384:	c6 80 17 28 11 80 00 	movb   $0x0,-0x7feed7e9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
8010638b:	05 f0 27 11 80       	add    $0x801127f0,%eax
  pd[0] = size-1;
80106390:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80106396:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
8010639a:	c1 e8 10             	shr    $0x10,%eax
8010639d:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
801063a1:	8d 45 f2             	lea    -0xe(%ebp),%eax
801063a4:	0f 01 10             	lgdtl  (%eax)
}
801063a7:	83 c4 14             	add    $0x14,%esp
801063aa:	5b                   	pop    %ebx
801063ab:	5d                   	pop    %ebp
801063ac:	c3                   	ret    

801063ad <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801063ad:	55                   	push   %ebp
801063ae:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
801063b0:	a1 c4 6b 11 80       	mov    0x80116bc4,%eax
801063b5:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
801063ba:	0f 22 d8             	mov    %eax,%cr3
}
801063bd:	5d                   	pop    %ebp
801063be:	c3                   	ret    

801063bf <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801063bf:	55                   	push   %ebp
801063c0:	89 e5                	mov    %esp,%ebp
801063c2:	57                   	push   %edi
801063c3:	56                   	push   %esi
801063c4:	53                   	push   %ebx
801063c5:	83 ec 1c             	sub    $0x1c,%esp
801063c8:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
801063cb:	85 f6                	test   %esi,%esi
801063cd:	0f 84 dd 00 00 00    	je     801064b0 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
801063d3:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
801063d7:	0f 84 e0 00 00 00    	je     801064bd <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
801063dd:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
801063e1:	0f 84 e3 00 00 00    	je     801064ca <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
801063e7:	e8 f1 db ff ff       	call   80103fdd <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
801063ec:	e8 c9 cd ff ff       	call   801031ba <mycpu>
801063f1:	89 c3                	mov    %eax,%ebx
801063f3:	e8 c2 cd ff ff       	call   801031ba <mycpu>
801063f8:	8d 78 08             	lea    0x8(%eax),%edi
801063fb:	e8 ba cd ff ff       	call   801031ba <mycpu>
80106400:	83 c0 08             	add    $0x8,%eax
80106403:	c1 e8 10             	shr    $0x10,%eax
80106406:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106409:	e8 ac cd ff ff       	call   801031ba <mycpu>
8010640e:	83 c0 08             	add    $0x8,%eax
80106411:	c1 e8 18             	shr    $0x18,%eax
80106414:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
8010641b:	67 00 
8010641d:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80106424:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80106428:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
8010642e:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80106435:	83 e2 f0             	and    $0xfffffff0,%edx
80106438:	83 ca 19             	or     $0x19,%edx
8010643b:	83 e2 9f             	and    $0xffffff9f,%edx
8010643e:	83 ca 80             	or     $0xffffff80,%edx
80106441:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80106447:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
8010644e:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80106454:	e8 61 cd ff ff       	call   801031ba <mycpu>
80106459:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106460:	83 e2 ef             	and    $0xffffffef,%edx
80106463:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80106469:	e8 4c cd ff ff       	call   801031ba <mycpu>
8010646e:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106474:	8b 5e 08             	mov    0x8(%esi),%ebx
80106477:	e8 3e cd ff ff       	call   801031ba <mycpu>
8010647c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106482:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80106485:	e8 30 cd ff ff       	call   801031ba <mycpu>
8010648a:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106490:	b8 28 00 00 00       	mov    $0x28,%eax
80106495:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106498:	8b 46 04             	mov    0x4(%esi),%eax
8010649b:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
801064a0:	0f 22 d8             	mov    %eax,%cr3
  popcli();
801064a3:	e8 72 db ff ff       	call   8010401a <popcli>
}
801064a8:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064ab:	5b                   	pop    %ebx
801064ac:	5e                   	pop    %esi
801064ad:	5f                   	pop    %edi
801064ae:	5d                   	pop    %ebp
801064af:	c3                   	ret    
    panic("switchuvm: no process");
801064b0:	83 ec 0c             	sub    $0xc,%esp
801064b3:	68 1e 73 10 80       	push   $0x8010731e
801064b8:	e8 8b 9e ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
801064bd:	83 ec 0c             	sub    $0xc,%esp
801064c0:	68 34 73 10 80       	push   $0x80107334
801064c5:	e8 7e 9e ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
801064ca:	83 ec 0c             	sub    $0xc,%esp
801064cd:	68 49 73 10 80       	push   $0x80107349
801064d2:	e8 71 9e ff ff       	call   80100348 <panic>

801064d7 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801064d7:	55                   	push   %ebp
801064d8:	89 e5                	mov    %esp,%ebp
801064da:	56                   	push   %esi
801064db:	53                   	push   %ebx
801064dc:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
801064df:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801064e5:	77 4c                	ja     80106533 <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
801064e7:	e8 cf bb ff ff       	call   801020bb <kalloc>
801064ec:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801064ee:	83 ec 04             	sub    $0x4,%esp
801064f1:	68 00 10 00 00       	push   $0x1000
801064f6:	6a 00                	push   $0x0
801064f8:	50                   	push   %eax
801064f9:	e8 68 dc ff ff       	call   80104166 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801064fe:	83 c4 08             	add    $0x8,%esp
80106501:	6a 06                	push   $0x6
80106503:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106509:	50                   	push   %eax
8010650a:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010650f:	ba 00 00 00 00       	mov    $0x0,%edx
80106514:	8b 45 08             	mov    0x8(%ebp),%eax
80106517:	e8 cf fc ff ff       	call   801061eb <mappages>
  memmove(mem, init, sz);
8010651c:	83 c4 0c             	add    $0xc,%esp
8010651f:	56                   	push   %esi
80106520:	ff 75 0c             	pushl  0xc(%ebp)
80106523:	53                   	push   %ebx
80106524:	e8 b8 dc ff ff       	call   801041e1 <memmove>
}
80106529:	83 c4 10             	add    $0x10,%esp
8010652c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010652f:	5b                   	pop    %ebx
80106530:	5e                   	pop    %esi
80106531:	5d                   	pop    %ebp
80106532:	c3                   	ret    
    panic("inituvm: more than a page");
80106533:	83 ec 0c             	sub    $0xc,%esp
80106536:	68 5d 73 10 80       	push   $0x8010735d
8010653b:	e8 08 9e ff ff       	call   80100348 <panic>

80106540 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106540:	55                   	push   %ebp
80106541:	89 e5                	mov    %esp,%ebp
80106543:	57                   	push   %edi
80106544:	56                   	push   %esi
80106545:	53                   	push   %ebx
80106546:	83 ec 0c             	sub    $0xc,%esp
80106549:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010654c:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106553:	75 07                	jne    8010655c <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80106555:	bb 00 00 00 00       	mov    $0x0,%ebx
8010655a:	eb 3c                	jmp    80106598 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
8010655c:	83 ec 0c             	sub    $0xc,%esp
8010655f:	68 18 74 10 80       	push   $0x80107418
80106564:	e8 df 9d ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106569:	83 ec 0c             	sub    $0xc,%esp
8010656c:	68 77 73 10 80       	push   $0x80107377
80106571:	e8 d2 9d ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106576:	05 00 00 00 80       	add    $0x80000000,%eax
8010657b:	56                   	push   %esi
8010657c:	89 da                	mov    %ebx,%edx
8010657e:	03 55 14             	add    0x14(%ebp),%edx
80106581:	52                   	push   %edx
80106582:	50                   	push   %eax
80106583:	ff 75 10             	pushl  0x10(%ebp)
80106586:	e8 e8 b1 ff ff       	call   80101773 <readi>
8010658b:	83 c4 10             	add    $0x10,%esp
8010658e:	39 f0                	cmp    %esi,%eax
80106590:	75 47                	jne    801065d9 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106592:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106598:	39 fb                	cmp    %edi,%ebx
8010659a:	73 30                	jae    801065cc <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010659c:	89 da                	mov    %ebx,%edx
8010659e:	03 55 0c             	add    0xc(%ebp),%edx
801065a1:	b9 00 00 00 00       	mov    $0x0,%ecx
801065a6:	8b 45 08             	mov    0x8(%ebp),%eax
801065a9:	e8 cd fb ff ff       	call   8010617b <walkpgdir>
801065ae:	85 c0                	test   %eax,%eax
801065b0:	74 b7                	je     80106569 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
801065b2:	8b 00                	mov    (%eax),%eax
801065b4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801065b9:	89 fe                	mov    %edi,%esi
801065bb:	29 de                	sub    %ebx,%esi
801065bd:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801065c3:	76 b1                	jbe    80106576 <loaduvm+0x36>
      n = PGSIZE;
801065c5:	be 00 10 00 00       	mov    $0x1000,%esi
801065ca:	eb aa                	jmp    80106576 <loaduvm+0x36>
      return -1;
  }
  return 0;
801065cc:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065d1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801065d4:	5b                   	pop    %ebx
801065d5:	5e                   	pop    %esi
801065d6:	5f                   	pop    %edi
801065d7:	5d                   	pop    %ebp
801065d8:	c3                   	ret    
      return -1;
801065d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065de:	eb f1                	jmp    801065d1 <loaduvm+0x91>

801065e0 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801065e0:	55                   	push   %ebp
801065e1:	89 e5                	mov    %esp,%ebp
801065e3:	57                   	push   %edi
801065e4:	56                   	push   %esi
801065e5:	53                   	push   %ebx
801065e6:	83 ec 0c             	sub    $0xc,%esp
801065e9:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801065ec:	39 7d 10             	cmp    %edi,0x10(%ebp)
801065ef:	73 11                	jae    80106602 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801065f1:	8b 45 10             	mov    0x10(%ebp),%eax
801065f4:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801065fa:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106600:	eb 19                	jmp    8010661b <deallocuvm+0x3b>
    return oldsz;
80106602:	89 f8                	mov    %edi,%eax
80106604:	eb 64                	jmp    8010666a <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106606:	c1 eb 16             	shr    $0x16,%ebx
80106609:	83 c3 01             	add    $0x1,%ebx
8010660c:	c1 e3 16             	shl    $0x16,%ebx
8010660f:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106615:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010661b:	39 fb                	cmp    %edi,%ebx
8010661d:	73 48                	jae    80106667 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010661f:	b9 00 00 00 00       	mov    $0x0,%ecx
80106624:	89 da                	mov    %ebx,%edx
80106626:	8b 45 08             	mov    0x8(%ebp),%eax
80106629:	e8 4d fb ff ff       	call   8010617b <walkpgdir>
8010662e:	89 c6                	mov    %eax,%esi
    if(!pte)
80106630:	85 c0                	test   %eax,%eax
80106632:	74 d2                	je     80106606 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106634:	8b 00                	mov    (%eax),%eax
80106636:	a8 01                	test   $0x1,%al
80106638:	74 db                	je     80106615 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
8010663a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010663f:	74 19                	je     8010665a <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106641:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106646:	83 ec 0c             	sub    $0xc,%esp
80106649:	50                   	push   %eax
8010664a:	e8 55 b9 ff ff       	call   80101fa4 <kfree>
      *pte = 0;
8010664f:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106655:	83 c4 10             	add    $0x10,%esp
80106658:	eb bb                	jmp    80106615 <deallocuvm+0x35>
        panic("kfree");
8010665a:	83 ec 0c             	sub    $0xc,%esp
8010665d:	68 86 6c 10 80       	push   $0x80106c86
80106662:	e8 e1 9c ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106667:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010666a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010666d:	5b                   	pop    %ebx
8010666e:	5e                   	pop    %esi
8010666f:	5f                   	pop    %edi
80106670:	5d                   	pop    %ebp
80106671:	c3                   	ret    

80106672 <allocuvm>:
{
80106672:	55                   	push   %ebp
80106673:	89 e5                	mov    %esp,%ebp
80106675:	57                   	push   %edi
80106676:	56                   	push   %esi
80106677:	53                   	push   %ebx
80106678:	83 ec 1c             	sub    $0x1c,%esp
8010667b:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
8010667e:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106681:	85 ff                	test   %edi,%edi
80106683:	0f 88 c1 00 00 00    	js     8010674a <allocuvm+0xd8>
  if(newsz < oldsz)
80106689:	3b 7d 0c             	cmp    0xc(%ebp),%edi
8010668c:	72 5c                	jb     801066ea <allocuvm+0x78>
  a = PGROUNDUP(oldsz);
8010668e:	8b 45 0c             	mov    0xc(%ebp),%eax
80106691:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106697:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
8010669d:	39 fb                	cmp    %edi,%ebx
8010669f:	0f 83 ac 00 00 00    	jae    80106751 <allocuvm+0xdf>
    mem = kalloc();
801066a5:	e8 11 ba ff ff       	call   801020bb <kalloc>
801066aa:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801066ac:	85 c0                	test   %eax,%eax
801066ae:	74 42                	je     801066f2 <allocuvm+0x80>
    memset(mem, 0, PGSIZE);
801066b0:	83 ec 04             	sub    $0x4,%esp
801066b3:	68 00 10 00 00       	push   $0x1000
801066b8:	6a 00                	push   $0x0
801066ba:	50                   	push   %eax
801066bb:	e8 a6 da ff ff       	call   80104166 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801066c0:	83 c4 08             	add    $0x8,%esp
801066c3:	6a 06                	push   $0x6
801066c5:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801066cb:	50                   	push   %eax
801066cc:	b9 00 10 00 00       	mov    $0x1000,%ecx
801066d1:	89 da                	mov    %ebx,%edx
801066d3:	8b 45 08             	mov    0x8(%ebp),%eax
801066d6:	e8 10 fb ff ff       	call   801061eb <mappages>
801066db:	83 c4 10             	add    $0x10,%esp
801066de:	85 c0                	test   %eax,%eax
801066e0:	78 38                	js     8010671a <allocuvm+0xa8>
  for(; a < newsz; a += PGSIZE){
801066e2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801066e8:	eb b3                	jmp    8010669d <allocuvm+0x2b>
    return oldsz;
801066ea:	8b 45 0c             	mov    0xc(%ebp),%eax
801066ed:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801066f0:	eb 5f                	jmp    80106751 <allocuvm+0xdf>
      cprintf("allocuvm out of memory\n");
801066f2:	83 ec 0c             	sub    $0xc,%esp
801066f5:	68 95 73 10 80       	push   $0x80107395
801066fa:	e8 0c 9f ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801066ff:	83 c4 0c             	add    $0xc,%esp
80106702:	ff 75 0c             	pushl  0xc(%ebp)
80106705:	57                   	push   %edi
80106706:	ff 75 08             	pushl  0x8(%ebp)
80106709:	e8 d2 fe ff ff       	call   801065e0 <deallocuvm>
      return 0;
8010670e:	83 c4 10             	add    $0x10,%esp
80106711:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106718:	eb 37                	jmp    80106751 <allocuvm+0xdf>
      cprintf("allocuvm out of memory (2)\n");
8010671a:	83 ec 0c             	sub    $0xc,%esp
8010671d:	68 ad 73 10 80       	push   $0x801073ad
80106722:	e8 e4 9e ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106727:	83 c4 0c             	add    $0xc,%esp
8010672a:	ff 75 0c             	pushl  0xc(%ebp)
8010672d:	57                   	push   %edi
8010672e:	ff 75 08             	pushl  0x8(%ebp)
80106731:	e8 aa fe ff ff       	call   801065e0 <deallocuvm>
      kfree(mem);
80106736:	89 34 24             	mov    %esi,(%esp)
80106739:	e8 66 b8 ff ff       	call   80101fa4 <kfree>
      return 0;
8010673e:	83 c4 10             	add    $0x10,%esp
80106741:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106748:	eb 07                	jmp    80106751 <allocuvm+0xdf>
    return 0;
8010674a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106751:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106754:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106757:	5b                   	pop    %ebx
80106758:	5e                   	pop    %esi
80106759:	5f                   	pop    %edi
8010675a:	5d                   	pop    %ebp
8010675b:	c3                   	ret    

8010675c <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010675c:	55                   	push   %ebp
8010675d:	89 e5                	mov    %esp,%ebp
8010675f:	56                   	push   %esi
80106760:	53                   	push   %ebx
80106761:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
80106764:	85 f6                	test   %esi,%esi
80106766:	74 1a                	je     80106782 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
80106768:	83 ec 04             	sub    $0x4,%esp
8010676b:	6a 00                	push   $0x0
8010676d:	68 00 00 00 80       	push   $0x80000000
80106772:	56                   	push   %esi
80106773:	e8 68 fe ff ff       	call   801065e0 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80106778:	83 c4 10             	add    $0x10,%esp
8010677b:	bb 00 00 00 00       	mov    $0x0,%ebx
80106780:	eb 10                	jmp    80106792 <freevm+0x36>
    panic("freevm: no pgdir");
80106782:	83 ec 0c             	sub    $0xc,%esp
80106785:	68 c9 73 10 80       	push   $0x801073c9
8010678a:	e8 b9 9b ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
8010678f:	83 c3 01             	add    $0x1,%ebx
80106792:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
80106798:	77 1f                	ja     801067b9 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
8010679a:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
8010679d:	a8 01                	test   $0x1,%al
8010679f:	74 ee                	je     8010678f <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801067a1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801067a6:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801067ab:	83 ec 0c             	sub    $0xc,%esp
801067ae:	50                   	push   %eax
801067af:	e8 f0 b7 ff ff       	call   80101fa4 <kfree>
801067b4:	83 c4 10             	add    $0x10,%esp
801067b7:	eb d6                	jmp    8010678f <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801067b9:	83 ec 0c             	sub    $0xc,%esp
801067bc:	56                   	push   %esi
801067bd:	e8 e2 b7 ff ff       	call   80101fa4 <kfree>
}
801067c2:	83 c4 10             	add    $0x10,%esp
801067c5:	8d 65 f8             	lea    -0x8(%ebp),%esp
801067c8:	5b                   	pop    %ebx
801067c9:	5e                   	pop    %esi
801067ca:	5d                   	pop    %ebp
801067cb:	c3                   	ret    

801067cc <setupkvm>:
{
801067cc:	55                   	push   %ebp
801067cd:	89 e5                	mov    %esp,%ebp
801067cf:	56                   	push   %esi
801067d0:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
801067d1:	e8 e5 b8 ff ff       	call   801020bb <kalloc>
801067d6:	89 c6                	mov    %eax,%esi
801067d8:	85 c0                	test   %eax,%eax
801067da:	74 55                	je     80106831 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
801067dc:	83 ec 04             	sub    $0x4,%esp
801067df:	68 00 10 00 00       	push   $0x1000
801067e4:	6a 00                	push   $0x0
801067e6:	50                   	push   %eax
801067e7:	e8 7a d9 ff ff       	call   80104166 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801067ec:	83 c4 10             	add    $0x10,%esp
801067ef:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
801067f4:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
801067fa:	73 35                	jae    80106831 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
801067fc:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801067ff:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106802:	29 c1                	sub    %eax,%ecx
80106804:	83 ec 08             	sub    $0x8,%esp
80106807:	ff 73 0c             	pushl  0xc(%ebx)
8010680a:	50                   	push   %eax
8010680b:	8b 13                	mov    (%ebx),%edx
8010680d:	89 f0                	mov    %esi,%eax
8010680f:	e8 d7 f9 ff ff       	call   801061eb <mappages>
80106814:	83 c4 10             	add    $0x10,%esp
80106817:	85 c0                	test   %eax,%eax
80106819:	78 05                	js     80106820 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010681b:	83 c3 10             	add    $0x10,%ebx
8010681e:	eb d4                	jmp    801067f4 <setupkvm+0x28>
      freevm(pgdir);
80106820:	83 ec 0c             	sub    $0xc,%esp
80106823:	56                   	push   %esi
80106824:	e8 33 ff ff ff       	call   8010675c <freevm>
      return 0;
80106829:	83 c4 10             	add    $0x10,%esp
8010682c:	be 00 00 00 00       	mov    $0x0,%esi
}
80106831:	89 f0                	mov    %esi,%eax
80106833:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106836:	5b                   	pop    %ebx
80106837:	5e                   	pop    %esi
80106838:	5d                   	pop    %ebp
80106839:	c3                   	ret    

8010683a <kvmalloc>:
{
8010683a:	55                   	push   %ebp
8010683b:	89 e5                	mov    %esp,%ebp
8010683d:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106840:	e8 87 ff ff ff       	call   801067cc <setupkvm>
80106845:	a3 c4 6b 11 80       	mov    %eax,0x80116bc4
  switchkvm();
8010684a:	e8 5e fb ff ff       	call   801063ad <switchkvm>
}
8010684f:	c9                   	leave  
80106850:	c3                   	ret    

80106851 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106851:	55                   	push   %ebp
80106852:	89 e5                	mov    %esp,%ebp
80106854:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106857:	b9 00 00 00 00       	mov    $0x0,%ecx
8010685c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010685f:	8b 45 08             	mov    0x8(%ebp),%eax
80106862:	e8 14 f9 ff ff       	call   8010617b <walkpgdir>
  if(pte == 0)
80106867:	85 c0                	test   %eax,%eax
80106869:	74 05                	je     80106870 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010686b:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
8010686e:	c9                   	leave  
8010686f:	c3                   	ret    
    panic("clearpteu");
80106870:	83 ec 0c             	sub    $0xc,%esp
80106873:	68 da 73 10 80       	push   $0x801073da
80106878:	e8 cb 9a ff ff       	call   80100348 <panic>

8010687d <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010687d:	55                   	push   %ebp
8010687e:	89 e5                	mov    %esp,%ebp
80106880:	57                   	push   %edi
80106881:	56                   	push   %esi
80106882:	53                   	push   %ebx
80106883:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106886:	e8 41 ff ff ff       	call   801067cc <setupkvm>
8010688b:	89 45 dc             	mov    %eax,-0x24(%ebp)
8010688e:	85 c0                	test   %eax,%eax
80106890:	0f 84 c4 00 00 00    	je     8010695a <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106896:	bf 00 00 00 00       	mov    $0x0,%edi
8010689b:	3b 7d 0c             	cmp    0xc(%ebp),%edi
8010689e:	0f 83 b6 00 00 00    	jae    8010695a <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801068a4:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801068a7:	b9 00 00 00 00       	mov    $0x0,%ecx
801068ac:	89 fa                	mov    %edi,%edx
801068ae:	8b 45 08             	mov    0x8(%ebp),%eax
801068b1:	e8 c5 f8 ff ff       	call   8010617b <walkpgdir>
801068b6:	85 c0                	test   %eax,%eax
801068b8:	74 65                	je     8010691f <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801068ba:	8b 00                	mov    (%eax),%eax
801068bc:	a8 01                	test   $0x1,%al
801068be:	74 6c                	je     8010692c <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801068c0:	89 c6                	mov    %eax,%esi
801068c2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
801068c8:	25 ff 0f 00 00       	and    $0xfff,%eax
801068cd:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
801068d0:	e8 e6 b7 ff ff       	call   801020bb <kalloc>
801068d5:	89 c3                	mov    %eax,%ebx
801068d7:	85 c0                	test   %eax,%eax
801068d9:	74 6a                	je     80106945 <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801068db:	81 c6 00 00 00 80    	add    $0x80000000,%esi
801068e1:	83 ec 04             	sub    $0x4,%esp
801068e4:	68 00 10 00 00       	push   $0x1000
801068e9:	56                   	push   %esi
801068ea:	50                   	push   %eax
801068eb:	e8 f1 d8 ff ff       	call   801041e1 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801068f0:	83 c4 08             	add    $0x8,%esp
801068f3:	ff 75 e0             	pushl  -0x20(%ebp)
801068f6:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801068fc:	50                   	push   %eax
801068fd:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106902:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106905:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106908:	e8 de f8 ff ff       	call   801061eb <mappages>
8010690d:	83 c4 10             	add    $0x10,%esp
80106910:	85 c0                	test   %eax,%eax
80106912:	78 25                	js     80106939 <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
80106914:	81 c7 00 10 00 00    	add    $0x1000,%edi
8010691a:	e9 7c ff ff ff       	jmp    8010689b <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
8010691f:	83 ec 0c             	sub    $0xc,%esp
80106922:	68 e4 73 10 80       	push   $0x801073e4
80106927:	e8 1c 9a ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
8010692c:	83 ec 0c             	sub    $0xc,%esp
8010692f:	68 fe 73 10 80       	push   $0x801073fe
80106934:	e8 0f 9a ff ff       	call   80100348 <panic>
      kfree(mem);
80106939:	83 ec 0c             	sub    $0xc,%esp
8010693c:	53                   	push   %ebx
8010693d:	e8 62 b6 ff ff       	call   80101fa4 <kfree>
      goto bad;
80106942:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106945:	83 ec 0c             	sub    $0xc,%esp
80106948:	ff 75 dc             	pushl  -0x24(%ebp)
8010694b:	e8 0c fe ff ff       	call   8010675c <freevm>
  return 0;
80106950:	83 c4 10             	add    $0x10,%esp
80106953:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
8010695a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010695d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106960:	5b                   	pop    %ebx
80106961:	5e                   	pop    %esi
80106962:	5f                   	pop    %edi
80106963:	5d                   	pop    %ebp
80106964:	c3                   	ret    

80106965 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106965:	55                   	push   %ebp
80106966:	89 e5                	mov    %esp,%ebp
80106968:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010696b:	b9 00 00 00 00       	mov    $0x0,%ecx
80106970:	8b 55 0c             	mov    0xc(%ebp),%edx
80106973:	8b 45 08             	mov    0x8(%ebp),%eax
80106976:	e8 00 f8 ff ff       	call   8010617b <walkpgdir>
  if((*pte & PTE_P) == 0)
8010697b:	8b 00                	mov    (%eax),%eax
8010697d:	a8 01                	test   $0x1,%al
8010697f:	74 10                	je     80106991 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
80106981:	a8 04                	test   $0x4,%al
80106983:	74 13                	je     80106998 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106985:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010698a:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010698f:	c9                   	leave  
80106990:	c3                   	ret    
    return 0;
80106991:	b8 00 00 00 00       	mov    $0x0,%eax
80106996:	eb f7                	jmp    8010698f <uva2ka+0x2a>
    return 0;
80106998:	b8 00 00 00 00       	mov    $0x0,%eax
8010699d:	eb f0                	jmp    8010698f <uva2ka+0x2a>

8010699f <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010699f:	55                   	push   %ebp
801069a0:	89 e5                	mov    %esp,%ebp
801069a2:	57                   	push   %edi
801069a3:	56                   	push   %esi
801069a4:	53                   	push   %ebx
801069a5:	83 ec 0c             	sub    $0xc,%esp
801069a8:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801069ab:	eb 25                	jmp    801069d2 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801069ad:	8b 55 0c             	mov    0xc(%ebp),%edx
801069b0:	29 f2                	sub    %esi,%edx
801069b2:	01 d0                	add    %edx,%eax
801069b4:	83 ec 04             	sub    $0x4,%esp
801069b7:	53                   	push   %ebx
801069b8:	ff 75 10             	pushl  0x10(%ebp)
801069bb:	50                   	push   %eax
801069bc:	e8 20 d8 ff ff       	call   801041e1 <memmove>
    len -= n;
801069c1:	29 df                	sub    %ebx,%edi
    buf += n;
801069c3:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801069c6:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801069cc:	89 45 0c             	mov    %eax,0xc(%ebp)
801069cf:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801069d2:	85 ff                	test   %edi,%edi
801069d4:	74 2f                	je     80106a05 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801069d6:	8b 75 0c             	mov    0xc(%ebp),%esi
801069d9:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801069df:	83 ec 08             	sub    $0x8,%esp
801069e2:	56                   	push   %esi
801069e3:	ff 75 08             	pushl  0x8(%ebp)
801069e6:	e8 7a ff ff ff       	call   80106965 <uva2ka>
    if(pa0 == 0)
801069eb:	83 c4 10             	add    $0x10,%esp
801069ee:	85 c0                	test   %eax,%eax
801069f0:	74 20                	je     80106a12 <copyout+0x73>
    n = PGSIZE - (va - va0);
801069f2:	89 f3                	mov    %esi,%ebx
801069f4:	2b 5d 0c             	sub    0xc(%ebp),%ebx
801069f7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
801069fd:	39 df                	cmp    %ebx,%edi
801069ff:	73 ac                	jae    801069ad <copyout+0xe>
      n = len;
80106a01:	89 fb                	mov    %edi,%ebx
80106a03:	eb a8                	jmp    801069ad <copyout+0xe>
  }
  return 0;
80106a05:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a0a:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106a0d:	5b                   	pop    %ebx
80106a0e:	5e                   	pop    %esi
80106a0f:	5f                   	pop    %edi
80106a10:	5d                   	pop    %ebp
80106a11:	c3                   	ret    
      return -1;
80106a12:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a17:	eb f1                	jmp    80106a0a <copyout+0x6b>
