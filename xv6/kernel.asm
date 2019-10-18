
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
80100046:	e8 43 40 00 00       	call   8010408e <acquire>

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
8010007c:	e8 72 40 00 00       	call   801040f3 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 ee 3d 00 00       	call   80103e7a <acquiresleep>
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
801000ca:	e8 24 40 00 00       	call   801040f3 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 a0 3d 00 00       	call   80103e7a <acquiresleep>
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
801000ea:	68 00 6a 10 80       	push   $0x80106a00
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 11 6a 10 80       	push   $0x80106a11
80100100:	68 c0 b5 10 80       	push   $0x8010b5c0
80100105:	e8 48 3e 00 00       	call   80103f52 <initlock>
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
8010013a:	68 18 6a 10 80       	push   $0x80106a18
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 ff 3c 00 00       	call   80103e47 <initsleeplock>
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
801001a8:	e8 57 3d 00 00       	call   80103f04 <holdingsleep>
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
801001cb:	68 1f 6a 10 80       	push   $0x80106a1f
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
801001e4:	e8 1b 3d 00 00       	call   80103f04 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 d0 3c 00 00       	call   80103ec9 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100200:	e8 89 3e 00 00       	call   8010408e <acquire>
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
8010024c:	e8 a2 3e 00 00       	call   801040f3 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 26 6a 10 80       	push   $0x80106a26
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
8010028a:	e8 ff 3d 00 00       	call   8010408e <acquire>
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
801002d1:	e8 1d 3e 00 00       	call   801040f3 <release>
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
80100331:	e8 bd 3d 00 00       	call   801040f3 <release>
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
80100363:	68 2d 6a 10 80       	push   $0x80106a2d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 22 70 10 80 	movl   $0x80107022,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 d9 3b 00 00       	call   80103f6d <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 41 6a 10 80       	push   $0x80106a41
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
8010049e:	68 45 6a 10 80       	push   $0x80106a45
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 f6 3c 00 00       	call   801041b5 <memmove>
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
801004d9:	e8 5c 3c 00 00       	call   8010413a <memset>
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
80100506:	e8 d5 50 00 00       	call   801055e0 <uartputc>
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
8010051f:	e8 bc 50 00 00       	call   801055e0 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 b0 50 00 00       	call   801055e0 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 a4 50 00 00       	call   801055e0 <uartputc>
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
80100576:	0f b6 92 70 6a 10 80 	movzbl -0x7fef9590(%edx),%edx
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
801005ca:	e8 bf 3a 00 00       	call   8010408e <acquire>
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
801005f1:	e8 fd 3a 00 00       	call   801040f3 <release>
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
80100638:	e8 51 3a 00 00       	call   8010408e <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 5f 6a 10 80       	push   $0x80106a5f
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
801006ee:	be 58 6a 10 80       	mov    $0x80106a58,%esi
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
80100734:	e8 ba 39 00 00       	call   801040f3 <release>
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
8010074f:	e8 3a 39 00 00       	call   8010408e <acquire>
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
80100873:	e8 7b 38 00 00       	call   801040f3 <release>
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
80100894:	68 68 6a 10 80       	push   $0x80106a68
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 af 36 00 00       	call   80103f52 <initlock>

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
80100952:	68 81 6a 10 80       	push   $0x80106a81
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
80100972:	e8 29 5e 00 00       	call   801067a0 <setupkvm>
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
80100a06:	e8 3b 5c 00 00       	call   80106646 <allocuvm>
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
80100a38:	e8 d7 5a 00 00       	call   80106514 <loaduvm>
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
80100a74:	e8 cd 5b 00 00       	call   80106646 <allocuvm>
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
80100a9d:	e8 8e 5c 00 00       	call   80106730 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 64 5d 00 00       	call   80106825 <clearpteu>
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
80100ae2:	e8 f5 37 00 00       	call   801042dc <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 e3 37 00 00       	call   801042dc <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 68 5e 00 00       	call   80106973 <copyout>
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
80100b66:	e8 08 5e 00 00       	call   80106973 <copyout>
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
80100ba3:	e8 f9 36 00 00       	call   801042a1 <safestrcpy>
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
80100bd1:	e8 bd 57 00 00       	call   80106393 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 52 5b 00 00       	call   80106730 <freevm>
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
80100c19:	68 8d 6a 10 80       	push   $0x80106a8d
80100c1e:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c23:	e8 2a 33 00 00       	call   80103f52 <initlock>
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
80100c39:	e8 50 34 00 00       	call   8010408e <acquire>
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
80100c68:	e8 86 34 00 00       	call   801040f3 <release>
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
80100c7f:	e8 6f 34 00 00       	call   801040f3 <release>
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
80100c9d:	e8 ec 33 00 00       	call   8010408e <acquire>
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
80100cba:	e8 34 34 00 00       	call   801040f3 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 94 6a 10 80       	push   $0x80106a94
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
80100ce2:	e8 a7 33 00 00       	call   8010408e <acquire>
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
80100d03:	e8 eb 33 00 00       	call   801040f3 <release>
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
80100d13:	68 9c 6a 10 80       	push   $0x80106a9c
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
80100d49:	e8 a5 33 00 00       	call   801040f3 <release>
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
80100e4b:	68 a6 6a 10 80       	push   $0x80106aa6
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
80100f10:	68 af 6a 10 80       	push   $0x80106aaf
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
80100f2d:	68 b5 6a 10 80       	push   $0x80106ab5
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
80100f8a:	e8 26 32 00 00       	call   801041b5 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 16 32 00 00       	call   801041b5 <memmove>
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
80100fdf:	e8 56 31 00 00       	call   8010413a <memset>
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
801010a3:	68 bf 6a 10 80       	push   $0x80106abf
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
8010117d:	68 d5 6a 10 80       	push   $0x80106ad5
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
8010119a:	e8 ef 2e 00 00       	call   8010408e <acquire>
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
801011e1:	e8 0d 2f 00 00       	call   801040f3 <release>
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
80101217:	e8 d7 2e 00 00       	call   801040f3 <release>
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
8010122c:	68 e8 6a 10 80       	push   $0x80106ae8
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
80101255:	e8 5b 2f 00 00       	call   801041b5 <memmove>
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
801012e2:	68 f8 6a 10 80       	push   $0x80106af8
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 0b 6b 10 80       	push   $0x80106b0b
801012f8:	68 e0 09 11 80       	push   $0x801109e0
801012fd:	e8 50 2c 00 00       	call   80103f52 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 12 6b 10 80       	push   $0x80106b12
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 20 0a 11 80       	add    $0x80110a20,%eax
80101321:	50                   	push   %eax
80101322:	e8 20 2b 00 00       	call   80103e47 <initsleeplock>
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
8010136c:	68 78 6b 10 80       	push   $0x80106b78
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
801013df:	68 18 6b 10 80       	push   $0x80106b18
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 44 2d 00 00       	call   8010413a <memset>
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
80101480:	e8 30 2d 00 00       	call   801041b5 <memmove>
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
80101560:	e8 29 2b 00 00       	call   8010408e <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101575:	e8 79 2b 00 00       	call   801040f3 <release>
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
8010159a:	e8 db 28 00 00       	call   80103e7a <acquiresleep>
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
801015b2:	68 2a 6b 10 80       	push   $0x80106b2a
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
80101614:	e8 9c 2b 00 00       	call   801041b5 <memmove>
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
80101639:	68 30 6b 10 80       	push   $0x80106b30
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
80101656:	e8 a9 28 00 00       	call   80103f04 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 58 28 00 00       	call   80103ec9 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 3f 6b 10 80       	push   $0x80106b3f
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
80101698:	e8 dd 27 00 00       	call   80103e7a <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 13 28 00 00       	call   80103ec9 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016bd:	e8 cc 29 00 00       	call   8010408e <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016d2:	e8 1c 2a 00 00       	call   801040f3 <release>
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
801016ea:	e8 9f 29 00 00       	call   8010408e <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016f9:	e8 f5 29 00 00       	call   801040f3 <release>
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
8010182a:	e8 86 29 00 00       	call   801041b5 <memmove>
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
80101926:	e8 8a 28 00 00       	call   801041b5 <memmove>
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
801019a9:	e8 6e 28 00 00       	call   8010421c <strncmp>
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
801019d0:	68 47 6b 10 80       	push   $0x80106b47
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 59 6b 10 80       	push   $0x80106b59
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
80101b92:	68 68 6b 10 80       	push   $0x80106b68
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 ab 26 00 00       	call   80104259 <strncpy>
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
80101bd7:	68 a0 71 10 80       	push   $0x801071a0
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
80101ccc:	68 cb 6b 10 80       	push   $0x80106bcb
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 d4 6b 10 80       	push   $0x80106bd4
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
80101d06:	68 e6 6b 10 80       	push   $0x80106be6
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 3d 22 00 00       	call   80103f52 <initlock>
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
80101d80:	e8 09 23 00 00       	call   8010408e <acquire>

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
80101dcb:	e8 23 23 00 00       	call   801040f3 <release>
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
80101de2:	e8 0c 23 00 00       	call   801040f3 <release>
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
80101e1a:	e8 e5 20 00 00       	call   80103f04 <holdingsleep>
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
80101e47:	e8 42 22 00 00       	call   8010408e <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 ea 6b 10 80       	push   $0x80106bea
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 00 6c 10 80       	push   $0x80106c00
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 15 6c 10 80       	push   $0x80106c15
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
80101ec3:	e8 2b 22 00 00       	call   801040f3 <release>
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
80101f3f:	68 34 6c 10 80       	push   $0x80106c34
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
80101fd6:	e8 5f 21 00 00       	call   8010413a <memset>

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
80102005:	68 66 6c 10 80       	push   $0x80106c66
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 40 26 11 80       	push   $0x80112640
80102017:	e8 72 20 00 00       	call   8010408e <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 40 26 11 80       	push   $0x80112640
80102029:	e8 c5 20 00 00       	call   801040f3 <release>
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
8010206f:	68 6c 6c 10 80       	push   $0x80106c6c
80102074:	68 40 26 11 80       	push   $0x80112640
80102079:	e8 d4 1e 00 00       	call   80103f52 <initlock>
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
801020f4:	e8 95 1f 00 00       	call   8010408e <acquire>
801020f9:	83 c4 10             	add    $0x10,%esp
801020fc:	eb cd                	jmp    801020cb <kalloc+0x10>
    release(&kmem.lock);
801020fe:	83 ec 0c             	sub    $0xc,%esp
80102101:	68 40 26 11 80       	push   $0x80112640
80102106:	e8 e8 1f 00 00       	call   801040f3 <release>
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
80102150:	0f b6 8a a0 6d 10 80 	movzbl -0x7fef9260(%edx),%ecx
80102157:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
8010215d:	0f b6 82 a0 6c 10 80 	movzbl -0x7fef9360(%edx),%eax
80102164:	31 c1                	xor    %eax,%ecx
80102166:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
8010216c:	89 c8                	mov    %ecx,%eax
8010216e:	83 e0 03             	and    $0x3,%eax
80102171:	8b 04 85 80 6c 10 80 	mov    -0x7fef9380(,%eax,4),%eax
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
801021ac:	0f b6 82 a0 6d 10 80 	movzbl -0x7fef9260(%edx),%eax
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
80102497:	e8 e4 1c 00 00       	call   80104180 <memcmp>
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
80102602:	e8 ae 1b 00 00       	call   801041b5 <memmove>
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
80102701:	e8 af 1a 00 00       	call   801041b5 <memmove>
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
8010276f:	68 a0 6e 10 80       	push   $0x80106ea0
80102774:	68 80 26 11 80       	push   $0x80112680
80102779:	e8 d4 17 00 00       	call   80103f52 <initlock>
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
801027b9:	e8 d0 18 00 00       	call   8010408e <acquire>
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
8010281e:	e8 d0 18 00 00       	call   801040f3 <release>
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
80102834:	e8 55 18 00 00       	call   8010408e <acquire>
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
8010286e:	e8 80 18 00 00       	call   801040f3 <release>
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
80102882:	68 a4 6e 10 80       	push   $0x80106ea4
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
801028ab:	e8 de 17 00 00       	call   8010408e <acquire>
    log.committing = 0;
801028b0:	c7 05 c0 26 11 80 00 	movl   $0x0,0x801126c0
801028b7:	00 00 00 
    wakeup(&log);
801028ba:	c7 04 24 80 26 11 80 	movl   $0x80112680,(%esp)
801028c1:	e8 29 10 00 00       	call   801038ef <wakeup>
    release(&log.lock);
801028c6:	c7 04 24 80 26 11 80 	movl   $0x80112680,(%esp)
801028cd:	e8 21 18 00 00       	call   801040f3 <release>
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
80102909:	e8 80 17 00 00       	call   8010408e <acquire>
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
80102934:	68 b3 6e 10 80       	push   $0x80106eb3
80102939:	e8 0a da ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
8010293e:	83 ec 0c             	sub    $0xc,%esp
80102941:	68 c9 6e 10 80       	push   $0x80106ec9
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
80102964:	e8 8a 17 00 00       	call   801040f3 <release>
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
80102992:	e8 1e 18 00 00       	call   801041b5 <memmove>

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
80102a23:	68 e4 6e 10 80       	push   $0x80106ee4
80102a28:	e8 de db ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102a2d:	e8 46 29 00 00       	call   80105378 <idtinit>
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
80102a50:	e8 2c 39 00 00       	call   80106381 <switchkvm>
  seginit();
80102a55:	e8 db 37 00 00       	call   80106235 <seginit>
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
80102a84:	e8 85 3d 00 00       	call   8010680e <kvmalloc>
  mpinit();        // detect other processors
80102a89:	e8 c9 01 00 00       	call   80102c57 <mpinit>
  lapicinit();     // interrupt controller
80102a8e:	e8 e1 f7 ff ff       	call   80102274 <lapicinit>
  seginit();       // segment descriptors
80102a93:	e8 9d 37 00 00       	call   80106235 <seginit>
  picinit();       // disable pic
80102a98:	e8 82 02 00 00       	call   80102d1f <picinit>
  ioapicinit();    // another interrupt controller
80102a9d:	e8 58 f4 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102aa2:	e8 e7 dd ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102aa7:	e8 7a 2b 00 00       	call   80105626 <uartinit>
  pinit();         // process table
80102aac:	e8 ef 06 00 00       	call   801031a0 <pinit>
  tvinit();        // trap vectors
80102ab1:	e8 11 28 00 00       	call   801052c7 <tvinit>
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
80102b27:	68 f8 6e 10 80       	push   $0x80106ef8
80102b2c:	53                   	push   %ebx
80102b2d:	e8 4e 16 00 00       	call   80104180 <memcmp>
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
80102bec:	68 fd 6e 10 80       	push   $0x80106efd
80102bf1:	56                   	push   %esi
80102bf2:	e8 89 15 00 00       	call   80104180 <memcmp>
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
80102c88:	68 02 6f 10 80       	push   $0x80106f02
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
80102cc7:	ff 24 85 3c 6f 10 80 	jmp    *-0x7fef90c4(,%eax,4)
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
80102d15:	68 1c 6f 10 80       	push   $0x80106f1c
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
80102dd1:	68 50 6f 10 80       	push   $0x80106f50
80102dd6:	50                   	push   %eax
80102dd7:	e8 76 11 00 00       	call   80103f52 <initlock>
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
80102e2d:	e8 5c 12 00 00       	call   8010408e <acquire>
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
80102e6d:	e8 81 12 00 00       	call   801040f3 <release>
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
80102e9c:	e8 52 12 00 00       	call   801040f3 <release>
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
80102ebd:	e8 cc 11 00 00       	call   8010408e <acquire>
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
80102f24:	e8 ca 11 00 00       	call   801040f3 <release>
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
80102f6d:	e8 81 11 00 00       	call   801040f3 <release>
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
80102f89:	e8 00 11 00 00       	call   8010408e <acquire>
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
80102fcd:	e8 21 11 00 00       	call   801040f3 <release>
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
80103024:	e8 ca 10 00 00       	call   801040f3 <release>
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
80103070:	e8 19 10 00 00       	call   8010408e <acquire>
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
8010309b:	e8 53 10 00 00       	call   801040f3 <release>
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
801030ff:	e8 ef 0f 00 00       	call   801040f3 <release>
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
8010311c:	c7 80 b0 0f 00 00 bc 	movl   $0x801052bc,0xfb0(%eax)
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
80103136:	e8 ff 0f 00 00       	call   8010413a <memset>
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
80103168:	e8 86 0f 00 00       	call   801040f3 <release>
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
801031a6:	68 55 6f 10 80       	push   $0x80106f55
801031ab:	68 40 39 11 80       	push   $0x80113940
801031b0:	e8 9d 0d 00 00       	call   80103f52 <initlock>
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
801031f2:	68 50 70 10 80       	push   $0x80107050
801031f7:	e8 4c d1 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801031fc:	83 ec 0c             	sub    $0xc,%esp
801031ff:	68 5c 6f 10 80       	push   $0x80106f5c
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
80103238:	e8 74 0d 00 00       	call   80103fb1 <pushcli>
  c = mycpu();
8010323d:	e8 78 ff ff ff       	call   801031ba <mycpu>
  p = c->proc;
80103242:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103248:	e8 a1 0d 00 00       	call   80103fee <popcli>
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
80103268:	e8 33 35 00 00       	call   801067a0 <setupkvm>
8010326d:	89 43 04             	mov    %eax,0x4(%ebx)
80103270:	85 c0                	test   %eax,%eax
80103272:	0f 84 d5 00 00 00    	je     8010334d <userinit+0xf8>
    inituvm(p->pgdir, _binary_initcode_start, (int) _binary_initcode_size);
80103278:	83 ec 04             	sub    $0x4,%esp
8010327b:	68 2c 00 00 00       	push   $0x2c
80103280:	68 60 a4 10 80       	push   $0x8010a460
80103285:	50                   	push   %eax
80103286:	e8 20 32 00 00       	call   801064ab <inituvm>
    p->sz = PGSIZE;
8010328b:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
    memset(p->tf, 0, sizeof(*p->tf));
80103291:	83 c4 0c             	add    $0xc,%esp
80103294:	6a 4c                	push   $0x4c
80103296:	6a 00                	push   $0x0
80103298:	ff 73 18             	pushl  0x18(%ebx)
8010329b:	e8 9a 0e 00 00       	call   8010413a <memset>
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
801032ee:	68 85 6f 10 80       	push   $0x80106f85
801032f3:	50                   	push   %eax
801032f4:	e8 a8 0f 00 00       	call   801042a1 <safestrcpy>
    p->cwd = namei("/");
801032f9:	c7 04 24 8e 6f 10 80 	movl   $0x80106f8e,(%esp)
80103300:	e8 dc e8 ff ff       	call   80101be1 <namei>
80103305:	89 43 68             	mov    %eax,0x68(%ebx)
    acquire(&ptable.lock);
80103308:	c7 04 24 40 39 11 80 	movl   $0x80113940,(%esp)
8010330f:	e8 7a 0d 00 00       	call   8010408e <acquire>
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
80103340:	e8 ae 0d 00 00       	call   801040f3 <release>
}
80103345:	83 c4 10             	add    $0x10,%esp
80103348:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010334b:	c9                   	leave  
8010334c:	c3                   	ret    
        panic("userinit: out of memory?");
8010334d:	83 ec 0c             	sub    $0xc,%esp
80103350:	68 6c 6f 10 80       	push   $0x80106f6c
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
801033c6:	e8 e9 31 00 00       	call   801065b4 <deallocuvm>
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
801033e3:	e8 5e 32 00 00       	call   80106646 <allocuvm>
801033e8:	83 c4 10             	add    $0x10,%esp
801033eb:	85 c0                	test   %eax,%eax
801033ed:	74 1a                	je     80103409 <growproc+0x66>
  curproc->sz = sz;
801033ef:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801033f1:	83 ec 0c             	sub    $0xc,%esp
801033f4:	53                   	push   %ebx
801033f5:	e8 99 2f 00 00       	call   80106393 <switchuvm>
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
8010343d:	e8 51 2f 00 00       	call   80106393 <switchuvm>
                    p->state = RUNNING;
80103442:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
                    swtch(&(c->scheduler), p->context);
80103449:	83 c4 08             	add    $0x8,%esp
8010344c:	ff 73 1c             	pushl  0x1c(%ebx)
8010344f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103452:	83 c0 04             	add    $0x4,%eax
80103455:	50                   	push   %eax
80103456:	e8 99 0e 00 00       	call   801042f4 <swtch>
                    switchkvm();
8010345b:	e8 21 2f 00 00       	call   80106381 <switchkvm>
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
801035c6:	e8 28 0b 00 00       	call   801040f3 <release>
    for (;;) {
801035cb:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
801035ce:	fb                   	sti    
        acquire(&ptable.lock);
801035cf:	83 ec 0c             	sub    $0xc,%esp
801035d2:	68 40 39 11 80       	push   $0x80113940
801035d7:	e8 b2 0a 00 00       	call   8010408e <acquire>
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
801035fd:	e8 4c 0a 00 00       	call   8010404e <holding>
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
8010363e:	e8 b1 0c 00 00       	call   801042f4 <swtch>
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
8010365b:	68 90 6f 10 80       	push   $0x80106f90
80103660:	e8 e3 cc ff ff       	call   80100348 <panic>
    panic("sched locks");
80103665:	83 ec 0c             	sub    $0xc,%esp
80103668:	68 a2 6f 10 80       	push   $0x80106fa2
8010366d:	e8 d6 cc ff ff       	call   80100348 <panic>
    panic("sched running");
80103672:	83 ec 0c             	sub    $0xc,%esp
80103675:	68 ae 6f 10 80       	push   $0x80106fae
8010367a:	e8 c9 cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
8010367f:	83 ec 0c             	sub    $0xc,%esp
80103682:	68 bc 6f 10 80       	push   $0x80106fbc
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
801036aa:	68 d0 6f 10 80       	push   $0x80106fd0
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
801036fd:	e8 8c 09 00 00       	call   8010408e <acquire>
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
8010374b:	68 dd 6f 10 80       	push   $0x80106fdd
80103750:	e8 f3 cb ff ff       	call   80100348 <panic>

80103755 <yield>:
{
80103755:	55                   	push   %ebp
80103756:	89 e5                	mov    %esp,%ebp
80103758:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
8010375b:	68 40 39 11 80       	push   $0x80113940
80103760:	e8 29 09 00 00       	call   8010408e <acquire>
  myproc()->state = RUNNABLE;
80103765:	e8 c7 fa ff ff       	call   80103231 <myproc>
8010376a:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103771:	e8 73 fe ff ff       	call   801035e9 <sched>
  release(&ptable.lock);
80103776:	c7 04 24 40 39 11 80 	movl   $0x80113940,(%esp)
8010377d:	e8 71 09 00 00       	call   801040f3 <release>
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
801037ae:	e8 db 08 00 00       	call   8010408e <acquire>
    release(lk);
801037b3:	89 1c 24             	mov    %ebx,(%esp)
801037b6:	e8 38 09 00 00       	call   801040f3 <release>
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
801037e7:	e8 07 09 00 00       	call   801040f3 <release>
    acquire(lk);
801037ec:	89 1c 24             	mov    %ebx,(%esp)
801037ef:	e8 9a 08 00 00       	call   8010408e <acquire>
801037f4:	83 c4 10             	add    $0x10,%esp
}
801037f7:	8d 65 f8             	lea    -0x8(%ebp),%esp
801037fa:	5b                   	pop    %ebx
801037fb:	5e                   	pop    %esi
801037fc:	5d                   	pop    %ebp
801037fd:	c3                   	ret    
    panic("sleep");
801037fe:	83 ec 0c             	sub    $0xc,%esp
80103801:	68 e9 6f 10 80       	push   $0x80106fe9
80103806:	e8 3d cb ff ff       	call   80100348 <panic>
    panic("sleep without lk");
8010380b:	83 ec 0c             	sub    $0xc,%esp
8010380e:	68 ef 6f 10 80       	push   $0x80106fef
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
8010382c:	e8 5d 08 00 00       	call   8010408e <acquire>
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
8010385b:	e8 d0 2e 00 00       	call   80106730 <freevm>
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
80103887:	e8 67 08 00 00       	call   801040f3 <release>
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
801038ca:	e8 24 08 00 00       	call   801040f3 <release>
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
801038fa:	e8 8f 07 00 00       	call   8010408e <acquire>
  wakeup1(chan);
801038ff:	8b 45 08             	mov    0x8(%ebp),%eax
80103902:	e8 2f f7 ff ff       	call   80103036 <wakeup1>
  release(&ptable.lock);
80103907:	c7 04 24 40 39 11 80 	movl   $0x80113940,(%esp)
8010390e:	e8 e0 07 00 00       	call   801040f3 <release>
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
80103927:	e8 62 07 00 00       	call   8010408e <acquire>
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
8010395c:	e8 92 07 00 00       	call   801040f3 <release>
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
8010397f:	e8 6f 07 00 00       	call   801040f3 <release>
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
8010399d:	b8 00 70 10 80       	mov    $0x80107000,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
801039a2:	8d 53 6c             	lea    0x6c(%ebx),%edx
801039a5:	52                   	push   %edx
801039a6:	50                   	push   %eax
801039a7:	ff 73 10             	pushl  0x10(%ebx)
801039aa:	68 04 70 10 80       	push   $0x80107004
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
801039c0:	68 22 70 10 80       	push   $0x80107022
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
801039e7:	8b 04 85 78 70 10 80 	mov    -0x7fef8f88(,%eax,4),%eax
801039ee:	85 c0                	test   %eax,%eax
801039f0:	75 b0                	jne    801039a2 <procdump+0x14>
      state = "???";
801039f2:	b8 00 70 10 80       	mov    $0x80107000,%eax
801039f7:	eb a9                	jmp    801039a2 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
801039f9:	8b 43 1c             	mov    0x1c(%ebx),%eax
801039fc:	8b 40 0c             	mov    0xc(%eax),%eax
801039ff:	83 c0 08             	add    $0x8,%eax
80103a02:	83 ec 08             	sub    $0x8,%esp
80103a05:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103a08:	52                   	push   %edx
80103a09:	50                   	push   %eax
80103a0a:	e8 5e 05 00 00       	call   80103f6d <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a0f:	83 c4 10             	add    $0x10,%esp
80103a12:	be 00 00 00 00       	mov    $0x0,%esi
80103a17:	eb 14                	jmp    80103a2d <procdump+0x9f>
        cprintf(" %p", pc[i]);
80103a19:	83 ec 08             	sub    $0x8,%esp
80103a1c:	50                   	push   %eax
80103a1d:	68 41 6a 10 80       	push   $0x80106a41
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
80103a63:	e8 26 06 00 00       	call   8010408e <acquire>
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
80103ae8:	e8 06 06 00 00       	call   801040f3 <release>
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
80103b2f:	e8 bf 05 00 00       	call   801040f3 <release>
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
80103b5c:	e8 2d 05 00 00       	call   8010408e <acquire>

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
80103b86:	e8 68 05 00 00       	call   801040f3 <release>
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
80103ba0:	e8 4e 05 00 00       	call   801040f3 <release>
    return -1;
80103ba5:	83 c4 10             	add    $0x10,%esp
80103ba8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103bad:	eb e2                	jmp    80103b91 <getpri+0x45>

80103baf <fork2>:

//
int
fork2(int pri) {
80103baf:	55                   	push   %ebp
80103bb0:	89 e5                	mov    %esp,%ebp
80103bb2:	57                   	push   %edi
80103bb3:	56                   	push   %esi
80103bb4:	53                   	push   %ebx
80103bb5:	83 ec 1c             	sub    $0x1c,%esp

    if (pri < 0 || pri > 3) {
80103bb8:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
80103bbc:	76 0d                	jbe    80103bcb <fork2+0x1c>
        // TODO: PRINT ERROR MESSAGE
        if (pri == -1) {
80103bbe:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
80103bc2:	75 63                	jne    80103c27 <fork2+0x78>
            pri = 3;
80103bc4:	c7 45 08 03 00 00 00 	movl   $0x3,0x8(%ebp)
            exit();
        }
    }
    int i, pid;
    struct proc *np;
    struct proc *curproc = myproc();
80103bcb:	e8 61 f6 ff ff       	call   80103231 <myproc>
80103bd0:	89 c3                	mov    %eax,%ebx

    // Allocate process.
    if((np = allocproc()) == 0){
80103bd2:	e8 8d f4 ff ff       	call   80103064 <allocproc>
80103bd7:	89 c7                	mov    %eax,%edi
80103bd9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80103bdc:	85 c0                	test   %eax,%eax
80103bde:	0f 84 45 01 00 00    	je     80103d29 <fork2+0x17a>
        return -1;
    }

    // Copy process state from proc.
    if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
80103be4:	83 ec 08             	sub    $0x8,%esp
80103be7:	ff 33                	pushl  (%ebx)
80103be9:	ff 73 04             	pushl  0x4(%ebx)
80103bec:	e8 60 2c 00 00       	call   80106851 <copyuvm>
80103bf1:	89 47 04             	mov    %eax,0x4(%edi)
80103bf4:	83 c4 10             	add    $0x10,%esp
80103bf7:	85 c0                	test   %eax,%eax
80103bf9:	74 31                	je     80103c2c <fork2+0x7d>
        kfree(np->kstack);
        np->kstack = 0;
        np->state = UNUSED;
        return -1;
    }
    np->sz = curproc->sz;
80103bfb:	8b 03                	mov    (%ebx),%eax
80103bfd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103c00:	89 07                	mov    %eax,(%edi)
    np->parent = curproc;
80103c02:	89 f8                	mov    %edi,%eax
80103c04:	89 5f 14             	mov    %ebx,0x14(%edi)
    *np->tf = *curproc->tf;
80103c07:	8b 73 18             	mov    0x18(%ebx),%esi
80103c0a:	8b 7f 18             	mov    0x18(%edi),%edi
80103c0d:	b9 13 00 00 00       	mov    $0x13,%ecx
80103c12:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

    // Clear %eax so that fork returns 0 in the child.
    np->tf->eax = 0;
80103c14:	89 c7                	mov    %eax,%edi
80103c16:	8b 40 18             	mov    0x18(%eax),%eax
80103c19:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

    for(i = 0; i < NOFILE; i++)
80103c20:	be 00 00 00 00       	mov    $0x0,%esi
80103c25:	eb 31                	jmp    80103c58 <fork2+0xa9>
            exit();
80103c27:	e8 60 fa ff ff       	call   8010368c <exit>
        kfree(np->kstack);
80103c2c:	83 ec 0c             	sub    $0xc,%esp
80103c2f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103c32:	ff 73 08             	pushl  0x8(%ebx)
80103c35:	e8 6a e3 ff ff       	call   80101fa4 <kfree>
        np->kstack = 0;
80103c3a:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        np->state = UNUSED;
80103c41:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        return -1;
80103c48:	83 c4 10             	add    $0x10,%esp
80103c4b:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103c50:	e9 ab 00 00 00       	jmp    80103d00 <fork2+0x151>
    for(i = 0; i < NOFILE; i++)
80103c55:	83 c6 01             	add    $0x1,%esi
80103c58:	83 fe 0f             	cmp    $0xf,%esi
80103c5b:	7f 1a                	jg     80103c77 <fork2+0xc8>
        if(curproc->ofile[i])
80103c5d:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103c61:	85 c0                	test   %eax,%eax
80103c63:	74 f0                	je     80103c55 <fork2+0xa6>
            np->ofile[i] = filedup(curproc->ofile[i]);
80103c65:	83 ec 0c             	sub    $0xc,%esp
80103c68:	50                   	push   %eax
80103c69:	e8 20 d0 ff ff       	call   80100c8e <filedup>
80103c6e:	89 44 b7 28          	mov    %eax,0x28(%edi,%esi,4)
80103c72:	83 c4 10             	add    $0x10,%esp
80103c75:	eb de                	jmp    80103c55 <fork2+0xa6>
    np->cwd = idup(curproc->cwd);
80103c77:	83 ec 0c             	sub    $0xc,%esp
80103c7a:	ff 73 68             	pushl  0x68(%ebx)
80103c7d:	e8 cf d8 ff ff       	call   80101551 <idup>
80103c82:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103c85:	89 47 68             	mov    %eax,0x68(%edi)

    safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103c88:	83 c3 6c             	add    $0x6c,%ebx
80103c8b:	8d 47 6c             	lea    0x6c(%edi),%eax
80103c8e:	83 c4 0c             	add    $0xc,%esp
80103c91:	6a 10                	push   $0x10
80103c93:	53                   	push   %ebx
80103c94:	50                   	push   %eax
80103c95:	e8 07 06 00 00       	call   801042a1 <safestrcpy>

    pid = np->pid;
80103c9a:	8b 5f 10             	mov    0x10(%edi),%ebx


    if (priorityQueue[pri].head == NULL && priorityQueue[pri].tail == NULL) {
80103c9d:	83 c4 10             	add    $0x10,%esp
80103ca0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ca3:	83 3c c5 20 39 11 80 	cmpl   $0x0,-0x7feec6e0(,%eax,8)
80103caa:	00 
80103cab:	74 5d                	je     80103d0a <fork2+0x15b>
        priorityQueue[pri].head = np;
        priorityQueue[pri].tail = np;
    } else {
        priorityQueue[pri].tail->next = np;
80103cad:	8b 45 08             	mov    0x8(%ebp),%eax
80103cb0:	8b 04 c5 24 39 11 80 	mov    -0x7feec6dc(,%eax,8),%eax
80103cb7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103cba:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
        priorityQueue[pri].tail = np;
80103cc0:	8b 45 08             	mov    0x8(%ebp),%eax
80103cc3:	89 14 c5 24 39 11 80 	mov    %edx,-0x7feec6dc(,%eax,8)
    }

    np->next = NULL;
80103cca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103ccd:	c7 87 80 00 00 00 00 	movl   $0x0,0x80(%edi)
80103cd4:	00 00 00 
    np->priority = pri;
80103cd7:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103cda:	89 4f 7c             	mov    %ecx,0x7c(%edi)

    acquire(&ptable.lock);
80103cdd:	83 ec 0c             	sub    $0xc,%esp
80103ce0:	68 40 39 11 80       	push   $0x80113940
80103ce5:	e8 a4 03 00 00       	call   8010408e <acquire>
    np->state = RUNNABLE;
80103cea:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
    release(&ptable.lock);
80103cf1:	c7 04 24 40 39 11 80 	movl   $0x80113940,(%esp)
80103cf8:	e8 f6 03 00 00       	call   801040f3 <release>


    return pid;
80103cfd:	83 c4 10             	add    $0x10,%esp
}
80103d00:	89 d8                	mov    %ebx,%eax
80103d02:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103d05:	5b                   	pop    %ebx
80103d06:	5e                   	pop    %esi
80103d07:	5f                   	pop    %edi
80103d08:	5d                   	pop    %ebp
80103d09:	c3                   	ret    
    if (priorityQueue[pri].head == NULL && priorityQueue[pri].tail == NULL) {
80103d0a:	83 3c c5 24 39 11 80 	cmpl   $0x0,-0x7feec6dc(,%eax,8)
80103d11:	00 
80103d12:	75 99                	jne    80103cad <fork2+0xfe>
        priorityQueue[pri].head = np;
80103d14:	89 c1                	mov    %eax,%ecx
80103d16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103d19:	89 04 cd 20 39 11 80 	mov    %eax,-0x7feec6e0(,%ecx,8)
        priorityQueue[pri].tail = np;
80103d20:	89 04 cd 24 39 11 80 	mov    %eax,-0x7feec6dc(,%ecx,8)
80103d27:	eb a1                	jmp    80103cca <fork2+0x11b>
        return -1;
80103d29:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103d2e:	eb d0                	jmp    80103d00 <fork2+0x151>

80103d30 <fork>:
{
80103d30:	55                   	push   %ebp
80103d31:	89 e5                	mov    %esp,%ebp
80103d33:	83 ec 14             	sub    $0x14,%esp
  int pid = fork2(-1);
80103d36:	6a ff                	push   $0xffffffff
80103d38:	e8 72 fe ff ff       	call   80103baf <fork2>
}
80103d3d:	c9                   	leave  
80103d3e:	c3                   	ret    

80103d3f <printQueue>:

void printQueue() {
80103d3f:	55                   	push   %ebp
80103d40:	89 e5                	mov    %esp,%ebp
80103d42:	56                   	push   %esi
80103d43:	53                   	push   %ebx
    // helper method for printing the current pqueue
    struct proc *p;

    for (int i = 0; i < 4; i++){
80103d44:	be 00 00 00 00       	mov    $0x0,%esi
80103d49:	eb 23                	jmp    80103d6e <printQueue+0x2f>
        for (p = priorityQueue[i].head; p != NULL;){
            //cprintf("PID: %d Proc: %p  Next: %p Head: %p Tail: %p\n", p->pid, p, p->next, priorityQueue[i].head, priorityQueue[i].tail);
            cprintf("PID: %d PRIORITY: %d \n", p->pid, p->priority);
80103d4b:	83 ec 04             	sub    $0x4,%esp
80103d4e:	ff 73 7c             	pushl  0x7c(%ebx)
80103d51:	ff 73 10             	pushl  0x10(%ebx)
80103d54:	68 0d 70 10 80       	push   $0x8010700d
80103d59:	e8 ad c8 ff ff       	call   8010060b <cprintf>
            p = p->next;
80103d5e:	8b 9b 80 00 00 00    	mov    0x80(%ebx),%ebx
80103d64:	83 c4 10             	add    $0x10,%esp
        for (p = priorityQueue[i].head; p != NULL;){
80103d67:	85 db                	test   %ebx,%ebx
80103d69:	75 e0                	jne    80103d4b <printQueue+0xc>
    for (int i = 0; i < 4; i++){
80103d6b:	83 c6 01             	add    $0x1,%esi
80103d6e:	83 fe 03             	cmp    $0x3,%esi
80103d71:	7f 09                	jg     80103d7c <printQueue+0x3d>
        for (p = priorityQueue[i].head; p != NULL;){
80103d73:	8b 1c f5 20 39 11 80 	mov    -0x7feec6e0(,%esi,8),%ebx
80103d7a:	eb eb                	jmp    80103d67 <printQueue+0x28>
        }
    }
}
80103d7c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103d7f:	5b                   	pop    %ebx
80103d80:	5e                   	pop    %esi
80103d81:	5d                   	pop    %ebp
80103d82:	c3                   	ret    

80103d83 <getpinfo>:

// returns 0 on success and -1 on failure
int
getpinfo(struct pstat *pstat){
80103d83:	55                   	push   %ebp
80103d84:	89 e5                	mov    %esp,%ebp
80103d86:	57                   	push   %edi
80103d87:	56                   	push   %esi
80103d88:	53                   	push   %ebx
80103d89:	81 ec c8 00 00 00    	sub    $0xc8,%esp
80103d8f:	8b 5d 08             	mov    0x8(%ebp),%ebx

    acquire(&ptable.lock);
80103d92:	68 40 39 11 80       	push   $0x80113940
80103d97:	e8 f2 02 00 00       	call   8010408e <acquire>
    for (int i = 0; i < NPROC; i++){
80103d9c:	83 c4 10             	add    $0x10,%esp
80103d9f:	b8 00 00 00 00       	mov    $0x0,%eax
80103da4:	eb 24                	jmp    80103dca <getpinfo+0x47>
        pstat->pid[i] = proc.pid;
        pstat->priority[i] = proc.priority;
        pstat->state[i] = proc.state;

        for (int j = 0; j < 4; j++) {
            pstat->ticks[i][j] = proc.agg_ticks[j];
80103da6:	8b 74 95 c8          	mov    -0x38(%ebp,%edx,4),%esi
80103daa:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
80103dad:	89 b4 8b 00 04 00 00 	mov    %esi,0x400(%ebx,%ecx,4)
            pstat->qtail[i][j] = proc.qtail[j];
80103db4:	8b 74 95 d8          	mov    -0x28(%ebp,%edx,4),%esi
80103db8:	89 b4 8b 00 08 00 00 	mov    %esi,0x800(%ebx,%ecx,4)
        for (int j = 0; j < 4; j++) {
80103dbf:	83 c2 01             	add    $0x1,%edx
80103dc2:	83 fa 03             	cmp    $0x3,%edx
80103dc5:	7e df                	jle    80103da6 <getpinfo+0x23>
    for (int i = 0; i < NPROC; i++){
80103dc7:	83 c0 01             	add    $0x1,%eax
80103dca:	83 f8 3f             	cmp    $0x3f,%eax
80103dcd:	7f 4f                	jg     80103e1e <getpinfo+0x9b>
        struct proc proc = ptable.proc[i];
80103dcf:	69 f0 a8 00 00 00    	imul   $0xa8,%eax,%esi
80103dd5:	8d bd 40 ff ff ff    	lea    -0xc0(%ebp),%edi
80103ddb:	81 c6 74 39 11 80    	add    $0x80113974,%esi
80103de1:	b9 2a 00 00 00       	mov    $0x2a,%ecx
80103de6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
        pstat->inuse[i] = (proc.state == UNUSED);
80103de8:	8b 95 4c ff ff ff    	mov    -0xb4(%ebp),%edx
80103dee:	85 d2                	test   %edx,%edx
80103df0:	0f 94 c1             	sete   %cl
80103df3:	0f b6 c9             	movzbl %cl,%ecx
80103df6:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
        pstat->pid[i] = proc.pid;
80103df9:	8b 8d 50 ff ff ff    	mov    -0xb0(%ebp),%ecx
80103dff:	89 8c 83 00 01 00 00 	mov    %ecx,0x100(%ebx,%eax,4)
        pstat->priority[i] = proc.priority;
80103e06:	8b 4d bc             	mov    -0x44(%ebp),%ecx
80103e09:	89 8c 83 00 02 00 00 	mov    %ecx,0x200(%ebx,%eax,4)
        pstat->state[i] = proc.state;
80103e10:	89 94 83 00 03 00 00 	mov    %edx,0x300(%ebx,%eax,4)
        for (int j = 0; j < 4; j++) {
80103e17:	ba 00 00 00 00       	mov    $0x0,%edx
80103e1c:	eb a4                	jmp    80103dc2 <getpinfo+0x3f>
        }
    }

    for(int i = 0; i < NPROC; i++) {
80103e1e:	b8 00 00 00 00       	mov    $0x0,%eax
80103e23:	eb 03                	jmp    80103e28 <getpinfo+0xa5>
80103e25:	83 c0 01             	add    $0x1,%eax
80103e28:	83 f8 3f             	cmp    $0x3f,%eax
80103e2b:	7e f8                	jle    80103e25 <getpinfo+0xa2>
        //cprintf("%d\n", pstat->state[i]);
    }
    release(&ptable.lock);
80103e2d:	83 ec 0c             	sub    $0xc,%esp
80103e30:	68 40 39 11 80       	push   $0x80113940
80103e35:	e8 b9 02 00 00       	call   801040f3 <release>
    return 0;
}
80103e3a:	b8 00 00 00 00       	mov    $0x0,%eax
80103e3f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103e42:	5b                   	pop    %ebx
80103e43:	5e                   	pop    %esi
80103e44:	5f                   	pop    %edi
80103e45:	5d                   	pop    %ebp
80103e46:	c3                   	ret    

80103e47 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103e47:	55                   	push   %ebp
80103e48:	89 e5                	mov    %esp,%ebp
80103e4a:	53                   	push   %ebx
80103e4b:	83 ec 0c             	sub    $0xc,%esp
80103e4e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103e51:	68 90 70 10 80       	push   $0x80107090
80103e56:	8d 43 04             	lea    0x4(%ebx),%eax
80103e59:	50                   	push   %eax
80103e5a:	e8 f3 00 00 00       	call   80103f52 <initlock>
  lk->name = name;
80103e5f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e62:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103e65:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103e6b:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103e72:	83 c4 10             	add    $0x10,%esp
80103e75:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e78:	c9                   	leave  
80103e79:	c3                   	ret    

80103e7a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103e7a:	55                   	push   %ebp
80103e7b:	89 e5                	mov    %esp,%ebp
80103e7d:	56                   	push   %esi
80103e7e:	53                   	push   %ebx
80103e7f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103e82:	8d 73 04             	lea    0x4(%ebx),%esi
80103e85:	83 ec 0c             	sub    $0xc,%esp
80103e88:	56                   	push   %esi
80103e89:	e8 00 02 00 00       	call   8010408e <acquire>
  while (lk->locked) {
80103e8e:	83 c4 10             	add    $0x10,%esp
80103e91:	eb 0d                	jmp    80103ea0 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103e93:	83 ec 08             	sub    $0x8,%esp
80103e96:	56                   	push   %esi
80103e97:	53                   	push   %ebx
80103e98:	e8 ea f8 ff ff       	call   80103787 <sleep>
80103e9d:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103ea0:	83 3b 00             	cmpl   $0x0,(%ebx)
80103ea3:	75 ee                	jne    80103e93 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103ea5:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103eab:	e8 81 f3 ff ff       	call   80103231 <myproc>
80103eb0:	8b 40 10             	mov    0x10(%eax),%eax
80103eb3:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103eb6:	83 ec 0c             	sub    $0xc,%esp
80103eb9:	56                   	push   %esi
80103eba:	e8 34 02 00 00       	call   801040f3 <release>
}
80103ebf:	83 c4 10             	add    $0x10,%esp
80103ec2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ec5:	5b                   	pop    %ebx
80103ec6:	5e                   	pop    %esi
80103ec7:	5d                   	pop    %ebp
80103ec8:	c3                   	ret    

80103ec9 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103ec9:	55                   	push   %ebp
80103eca:	89 e5                	mov    %esp,%ebp
80103ecc:	56                   	push   %esi
80103ecd:	53                   	push   %ebx
80103ece:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103ed1:	8d 73 04             	lea    0x4(%ebx),%esi
80103ed4:	83 ec 0c             	sub    $0xc,%esp
80103ed7:	56                   	push   %esi
80103ed8:	e8 b1 01 00 00       	call   8010408e <acquire>
  lk->locked = 0;
80103edd:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103ee3:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103eea:	89 1c 24             	mov    %ebx,(%esp)
80103eed:	e8 fd f9 ff ff       	call   801038ef <wakeup>
  release(&lk->lk);
80103ef2:	89 34 24             	mov    %esi,(%esp)
80103ef5:	e8 f9 01 00 00       	call   801040f3 <release>
}
80103efa:	83 c4 10             	add    $0x10,%esp
80103efd:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103f00:	5b                   	pop    %ebx
80103f01:	5e                   	pop    %esi
80103f02:	5d                   	pop    %ebp
80103f03:	c3                   	ret    

80103f04 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103f04:	55                   	push   %ebp
80103f05:	89 e5                	mov    %esp,%ebp
80103f07:	56                   	push   %esi
80103f08:	53                   	push   %ebx
80103f09:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103f0c:	8d 73 04             	lea    0x4(%ebx),%esi
80103f0f:	83 ec 0c             	sub    $0xc,%esp
80103f12:	56                   	push   %esi
80103f13:	e8 76 01 00 00       	call   8010408e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103f18:	83 c4 10             	add    $0x10,%esp
80103f1b:	83 3b 00             	cmpl   $0x0,(%ebx)
80103f1e:	75 17                	jne    80103f37 <holdingsleep+0x33>
80103f20:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103f25:	83 ec 0c             	sub    $0xc,%esp
80103f28:	56                   	push   %esi
80103f29:	e8 c5 01 00 00       	call   801040f3 <release>
  return r;
}
80103f2e:	89 d8                	mov    %ebx,%eax
80103f30:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103f33:	5b                   	pop    %ebx
80103f34:	5e                   	pop    %esi
80103f35:	5d                   	pop    %ebp
80103f36:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103f37:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103f3a:	e8 f2 f2 ff ff       	call   80103231 <myproc>
80103f3f:	3b 58 10             	cmp    0x10(%eax),%ebx
80103f42:	74 07                	je     80103f4b <holdingsleep+0x47>
80103f44:	bb 00 00 00 00       	mov    $0x0,%ebx
80103f49:	eb da                	jmp    80103f25 <holdingsleep+0x21>
80103f4b:	bb 01 00 00 00       	mov    $0x1,%ebx
80103f50:	eb d3                	jmp    80103f25 <holdingsleep+0x21>

80103f52 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103f52:	55                   	push   %ebp
80103f53:	89 e5                	mov    %esp,%ebp
80103f55:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103f58:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f5b:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103f5e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103f64:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103f6b:	5d                   	pop    %ebp
80103f6c:	c3                   	ret    

80103f6d <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103f6d:	55                   	push   %ebp
80103f6e:	89 e5                	mov    %esp,%ebp
80103f70:	53                   	push   %ebx
80103f71:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103f74:	8b 45 08             	mov    0x8(%ebp),%eax
80103f77:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103f7a:	b8 00 00 00 00       	mov    $0x0,%eax
80103f7f:	83 f8 09             	cmp    $0x9,%eax
80103f82:	7f 25                	jg     80103fa9 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103f84:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103f8a:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103f90:	77 17                	ja     80103fa9 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103f92:	8b 5a 04             	mov    0x4(%edx),%ebx
80103f95:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103f98:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103f9a:	83 c0 01             	add    $0x1,%eax
80103f9d:	eb e0                	jmp    80103f7f <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103f9f:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103fa6:	83 c0 01             	add    $0x1,%eax
80103fa9:	83 f8 09             	cmp    $0x9,%eax
80103fac:	7e f1                	jle    80103f9f <getcallerpcs+0x32>
}
80103fae:	5b                   	pop    %ebx
80103faf:	5d                   	pop    %ebp
80103fb0:	c3                   	ret    

80103fb1 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103fb1:	55                   	push   %ebp
80103fb2:	89 e5                	mov    %esp,%ebp
80103fb4:	53                   	push   %ebx
80103fb5:	83 ec 04             	sub    $0x4,%esp
80103fb8:	9c                   	pushf  
80103fb9:	5b                   	pop    %ebx
  asm volatile("cli");
80103fba:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103fbb:	e8 fa f1 ff ff       	call   801031ba <mycpu>
80103fc0:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103fc7:	74 12                	je     80103fdb <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103fc9:	e8 ec f1 ff ff       	call   801031ba <mycpu>
80103fce:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103fd5:	83 c4 04             	add    $0x4,%esp
80103fd8:	5b                   	pop    %ebx
80103fd9:	5d                   	pop    %ebp
80103fda:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103fdb:	e8 da f1 ff ff       	call   801031ba <mycpu>
80103fe0:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103fe6:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103fec:	eb db                	jmp    80103fc9 <pushcli+0x18>

80103fee <popcli>:

void
popcli(void)
{
80103fee:	55                   	push   %ebp
80103fef:	89 e5                	mov    %esp,%ebp
80103ff1:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103ff4:	9c                   	pushf  
80103ff5:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103ff6:	f6 c4 02             	test   $0x2,%ah
80103ff9:	75 28                	jne    80104023 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103ffb:	e8 ba f1 ff ff       	call   801031ba <mycpu>
80104000:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80104006:	8d 51 ff             	lea    -0x1(%ecx),%edx
80104009:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
8010400f:	85 d2                	test   %edx,%edx
80104011:	78 1d                	js     80104030 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80104013:	e8 a2 f1 ff ff       	call   801031ba <mycpu>
80104018:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
8010401f:	74 1c                	je     8010403d <popcli+0x4f>
    sti();
}
80104021:	c9                   	leave  
80104022:	c3                   	ret    
    panic("popcli - interruptible");
80104023:	83 ec 0c             	sub    $0xc,%esp
80104026:	68 9b 70 10 80       	push   $0x8010709b
8010402b:	e8 18 c3 ff ff       	call   80100348 <panic>
    panic("popcli");
80104030:	83 ec 0c             	sub    $0xc,%esp
80104033:	68 b2 70 10 80       	push   $0x801070b2
80104038:	e8 0b c3 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
8010403d:	e8 78 f1 ff ff       	call   801031ba <mycpu>
80104042:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80104049:	74 d6                	je     80104021 <popcli+0x33>
  asm volatile("sti");
8010404b:	fb                   	sti    
}
8010404c:	eb d3                	jmp    80104021 <popcli+0x33>

8010404e <holding>:
{
8010404e:	55                   	push   %ebp
8010404f:	89 e5                	mov    %esp,%ebp
80104051:	53                   	push   %ebx
80104052:	83 ec 04             	sub    $0x4,%esp
80104055:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80104058:	e8 54 ff ff ff       	call   80103fb1 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
8010405d:	83 3b 00             	cmpl   $0x0,(%ebx)
80104060:	75 12                	jne    80104074 <holding+0x26>
80104062:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80104067:	e8 82 ff ff ff       	call   80103fee <popcli>
}
8010406c:	89 d8                	mov    %ebx,%eax
8010406e:	83 c4 04             	add    $0x4,%esp
80104071:	5b                   	pop    %ebx
80104072:	5d                   	pop    %ebp
80104073:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80104074:	8b 5b 08             	mov    0x8(%ebx),%ebx
80104077:	e8 3e f1 ff ff       	call   801031ba <mycpu>
8010407c:	39 c3                	cmp    %eax,%ebx
8010407e:	74 07                	je     80104087 <holding+0x39>
80104080:	bb 00 00 00 00       	mov    $0x0,%ebx
80104085:	eb e0                	jmp    80104067 <holding+0x19>
80104087:	bb 01 00 00 00       	mov    $0x1,%ebx
8010408c:	eb d9                	jmp    80104067 <holding+0x19>

8010408e <acquire>:
{
8010408e:	55                   	push   %ebp
8010408f:	89 e5                	mov    %esp,%ebp
80104091:	53                   	push   %ebx
80104092:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104095:	e8 17 ff ff ff       	call   80103fb1 <pushcli>
  if(holding(lk))
8010409a:	83 ec 0c             	sub    $0xc,%esp
8010409d:	ff 75 08             	pushl  0x8(%ebp)
801040a0:	e8 a9 ff ff ff       	call   8010404e <holding>
801040a5:	83 c4 10             	add    $0x10,%esp
801040a8:	85 c0                	test   %eax,%eax
801040aa:	75 3a                	jne    801040e6 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
801040ac:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
801040af:	b8 01 00 00 00       	mov    $0x1,%eax
801040b4:	f0 87 02             	lock xchg %eax,(%edx)
801040b7:	85 c0                	test   %eax,%eax
801040b9:	75 f1                	jne    801040ac <acquire+0x1e>
  __sync_synchronize();
801040bb:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
801040c0:	8b 5d 08             	mov    0x8(%ebp),%ebx
801040c3:	e8 f2 f0 ff ff       	call   801031ba <mycpu>
801040c8:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
801040cb:	8b 45 08             	mov    0x8(%ebp),%eax
801040ce:	83 c0 0c             	add    $0xc,%eax
801040d1:	83 ec 08             	sub    $0x8,%esp
801040d4:	50                   	push   %eax
801040d5:	8d 45 08             	lea    0x8(%ebp),%eax
801040d8:	50                   	push   %eax
801040d9:	e8 8f fe ff ff       	call   80103f6d <getcallerpcs>
}
801040de:	83 c4 10             	add    $0x10,%esp
801040e1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801040e4:	c9                   	leave  
801040e5:	c3                   	ret    
    panic("acquire");
801040e6:	83 ec 0c             	sub    $0xc,%esp
801040e9:	68 b9 70 10 80       	push   $0x801070b9
801040ee:	e8 55 c2 ff ff       	call   80100348 <panic>

801040f3 <release>:
{
801040f3:	55                   	push   %ebp
801040f4:	89 e5                	mov    %esp,%ebp
801040f6:	53                   	push   %ebx
801040f7:	83 ec 10             	sub    $0x10,%esp
801040fa:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
801040fd:	53                   	push   %ebx
801040fe:	e8 4b ff ff ff       	call   8010404e <holding>
80104103:	83 c4 10             	add    $0x10,%esp
80104106:	85 c0                	test   %eax,%eax
80104108:	74 23                	je     8010412d <release+0x3a>
  lk->pcs[0] = 0;
8010410a:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80104111:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80104118:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
8010411d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80104123:	e8 c6 fe ff ff       	call   80103fee <popcli>
}
80104128:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010412b:	c9                   	leave  
8010412c:	c3                   	ret    
    panic("release");
8010412d:	83 ec 0c             	sub    $0xc,%esp
80104130:	68 c1 70 10 80       	push   $0x801070c1
80104135:	e8 0e c2 ff ff       	call   80100348 <panic>

8010413a <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010413a:	55                   	push   %ebp
8010413b:	89 e5                	mov    %esp,%ebp
8010413d:	57                   	push   %edi
8010413e:	53                   	push   %ebx
8010413f:	8b 55 08             	mov    0x8(%ebp),%edx
80104142:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80104145:	f6 c2 03             	test   $0x3,%dl
80104148:	75 05                	jne    8010414f <memset+0x15>
8010414a:	f6 c1 03             	test   $0x3,%cl
8010414d:	74 0e                	je     8010415d <memset+0x23>
  asm volatile("cld; rep stosb" :
8010414f:	89 d7                	mov    %edx,%edi
80104151:	8b 45 0c             	mov    0xc(%ebp),%eax
80104154:	fc                   	cld    
80104155:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80104157:	89 d0                	mov    %edx,%eax
80104159:	5b                   	pop    %ebx
8010415a:	5f                   	pop    %edi
8010415b:	5d                   	pop    %ebp
8010415c:	c3                   	ret    
    c &= 0xFF;
8010415d:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80104161:	c1 e9 02             	shr    $0x2,%ecx
80104164:	89 f8                	mov    %edi,%eax
80104166:	c1 e0 18             	shl    $0x18,%eax
80104169:	89 fb                	mov    %edi,%ebx
8010416b:	c1 e3 10             	shl    $0x10,%ebx
8010416e:	09 d8                	or     %ebx,%eax
80104170:	89 fb                	mov    %edi,%ebx
80104172:	c1 e3 08             	shl    $0x8,%ebx
80104175:	09 d8                	or     %ebx,%eax
80104177:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80104179:	89 d7                	mov    %edx,%edi
8010417b:	fc                   	cld    
8010417c:	f3 ab                	rep stos %eax,%es:(%edi)
8010417e:	eb d7                	jmp    80104157 <memset+0x1d>

80104180 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80104180:	55                   	push   %ebp
80104181:	89 e5                	mov    %esp,%ebp
80104183:	56                   	push   %esi
80104184:	53                   	push   %ebx
80104185:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104188:	8b 55 0c             	mov    0xc(%ebp),%edx
8010418b:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
8010418e:	8d 70 ff             	lea    -0x1(%eax),%esi
80104191:	85 c0                	test   %eax,%eax
80104193:	74 1c                	je     801041b1 <memcmp+0x31>
    if(*s1 != *s2)
80104195:	0f b6 01             	movzbl (%ecx),%eax
80104198:	0f b6 1a             	movzbl (%edx),%ebx
8010419b:	38 d8                	cmp    %bl,%al
8010419d:	75 0a                	jne    801041a9 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
8010419f:	83 c1 01             	add    $0x1,%ecx
801041a2:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
801041a5:	89 f0                	mov    %esi,%eax
801041a7:	eb e5                	jmp    8010418e <memcmp+0xe>
      return *s1 - *s2;
801041a9:	0f b6 c0             	movzbl %al,%eax
801041ac:	0f b6 db             	movzbl %bl,%ebx
801041af:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
801041b1:	5b                   	pop    %ebx
801041b2:	5e                   	pop    %esi
801041b3:	5d                   	pop    %ebp
801041b4:	c3                   	ret    

801041b5 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801041b5:	55                   	push   %ebp
801041b6:	89 e5                	mov    %esp,%ebp
801041b8:	56                   	push   %esi
801041b9:	53                   	push   %ebx
801041ba:	8b 45 08             	mov    0x8(%ebp),%eax
801041bd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801041c0:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801041c3:	39 c1                	cmp    %eax,%ecx
801041c5:	73 3a                	jae    80104201 <memmove+0x4c>
801041c7:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
801041ca:	39 c3                	cmp    %eax,%ebx
801041cc:	76 37                	jbe    80104205 <memmove+0x50>
    s += n;
    d += n;
801041ce:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
801041d1:	eb 0d                	jmp    801041e0 <memmove+0x2b>
      *--d = *--s;
801041d3:	83 eb 01             	sub    $0x1,%ebx
801041d6:	83 e9 01             	sub    $0x1,%ecx
801041d9:	0f b6 13             	movzbl (%ebx),%edx
801041dc:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
801041de:	89 f2                	mov    %esi,%edx
801041e0:	8d 72 ff             	lea    -0x1(%edx),%esi
801041e3:	85 d2                	test   %edx,%edx
801041e5:	75 ec                	jne    801041d3 <memmove+0x1e>
801041e7:	eb 14                	jmp    801041fd <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
801041e9:	0f b6 11             	movzbl (%ecx),%edx
801041ec:	88 13                	mov    %dl,(%ebx)
801041ee:	8d 5b 01             	lea    0x1(%ebx),%ebx
801041f1:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
801041f4:	89 f2                	mov    %esi,%edx
801041f6:	8d 72 ff             	lea    -0x1(%edx),%esi
801041f9:	85 d2                	test   %edx,%edx
801041fb:	75 ec                	jne    801041e9 <memmove+0x34>

  return dst;
}
801041fd:	5b                   	pop    %ebx
801041fe:	5e                   	pop    %esi
801041ff:	5d                   	pop    %ebp
80104200:	c3                   	ret    
80104201:	89 c3                	mov    %eax,%ebx
80104203:	eb f1                	jmp    801041f6 <memmove+0x41>
80104205:	89 c3                	mov    %eax,%ebx
80104207:	eb ed                	jmp    801041f6 <memmove+0x41>

80104209 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80104209:	55                   	push   %ebp
8010420a:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
8010420c:	ff 75 10             	pushl  0x10(%ebp)
8010420f:	ff 75 0c             	pushl  0xc(%ebp)
80104212:	ff 75 08             	pushl  0x8(%ebp)
80104215:	e8 9b ff ff ff       	call   801041b5 <memmove>
}
8010421a:	c9                   	leave  
8010421b:	c3                   	ret    

8010421c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
8010421c:	55                   	push   %ebp
8010421d:	89 e5                	mov    %esp,%ebp
8010421f:	53                   	push   %ebx
80104220:	8b 55 08             	mov    0x8(%ebp),%edx
80104223:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80104226:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80104229:	eb 09                	jmp    80104234 <strncmp+0x18>
    n--, p++, q++;
8010422b:	83 e8 01             	sub    $0x1,%eax
8010422e:	83 c2 01             	add    $0x1,%edx
80104231:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80104234:	85 c0                	test   %eax,%eax
80104236:	74 0b                	je     80104243 <strncmp+0x27>
80104238:	0f b6 1a             	movzbl (%edx),%ebx
8010423b:	84 db                	test   %bl,%bl
8010423d:	74 04                	je     80104243 <strncmp+0x27>
8010423f:	3a 19                	cmp    (%ecx),%bl
80104241:	74 e8                	je     8010422b <strncmp+0xf>
  if(n == 0)
80104243:	85 c0                	test   %eax,%eax
80104245:	74 0b                	je     80104252 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80104247:	0f b6 02             	movzbl (%edx),%eax
8010424a:	0f b6 11             	movzbl (%ecx),%edx
8010424d:	29 d0                	sub    %edx,%eax
}
8010424f:	5b                   	pop    %ebx
80104250:	5d                   	pop    %ebp
80104251:	c3                   	ret    
    return 0;
80104252:	b8 00 00 00 00       	mov    $0x0,%eax
80104257:	eb f6                	jmp    8010424f <strncmp+0x33>

80104259 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80104259:	55                   	push   %ebp
8010425a:	89 e5                	mov    %esp,%ebp
8010425c:	57                   	push   %edi
8010425d:	56                   	push   %esi
8010425e:	53                   	push   %ebx
8010425f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80104262:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80104265:	8b 45 08             	mov    0x8(%ebp),%eax
80104268:	eb 04                	jmp    8010426e <strncpy+0x15>
8010426a:	89 fb                	mov    %edi,%ebx
8010426c:	89 f0                	mov    %esi,%eax
8010426e:	8d 51 ff             	lea    -0x1(%ecx),%edx
80104271:	85 c9                	test   %ecx,%ecx
80104273:	7e 1d                	jle    80104292 <strncpy+0x39>
80104275:	8d 7b 01             	lea    0x1(%ebx),%edi
80104278:	8d 70 01             	lea    0x1(%eax),%esi
8010427b:	0f b6 1b             	movzbl (%ebx),%ebx
8010427e:	88 18                	mov    %bl,(%eax)
80104280:	89 d1                	mov    %edx,%ecx
80104282:	84 db                	test   %bl,%bl
80104284:	75 e4                	jne    8010426a <strncpy+0x11>
80104286:	89 f0                	mov    %esi,%eax
80104288:	eb 08                	jmp    80104292 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
8010428a:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
8010428d:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
8010428f:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80104292:	8d 4a ff             	lea    -0x1(%edx),%ecx
80104295:	85 d2                	test   %edx,%edx
80104297:	7f f1                	jg     8010428a <strncpy+0x31>
  return os;
}
80104299:	8b 45 08             	mov    0x8(%ebp),%eax
8010429c:	5b                   	pop    %ebx
8010429d:	5e                   	pop    %esi
8010429e:	5f                   	pop    %edi
8010429f:	5d                   	pop    %ebp
801042a0:	c3                   	ret    

801042a1 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801042a1:	55                   	push   %ebp
801042a2:	89 e5                	mov    %esp,%ebp
801042a4:	57                   	push   %edi
801042a5:	56                   	push   %esi
801042a6:	53                   	push   %ebx
801042a7:	8b 45 08             	mov    0x8(%ebp),%eax
801042aa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801042ad:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
801042b0:	85 d2                	test   %edx,%edx
801042b2:	7e 23                	jle    801042d7 <safestrcpy+0x36>
801042b4:	89 c1                	mov    %eax,%ecx
801042b6:	eb 04                	jmp    801042bc <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
801042b8:	89 fb                	mov    %edi,%ebx
801042ba:	89 f1                	mov    %esi,%ecx
801042bc:	83 ea 01             	sub    $0x1,%edx
801042bf:	85 d2                	test   %edx,%edx
801042c1:	7e 11                	jle    801042d4 <safestrcpy+0x33>
801042c3:	8d 7b 01             	lea    0x1(%ebx),%edi
801042c6:	8d 71 01             	lea    0x1(%ecx),%esi
801042c9:	0f b6 1b             	movzbl (%ebx),%ebx
801042cc:	88 19                	mov    %bl,(%ecx)
801042ce:	84 db                	test   %bl,%bl
801042d0:	75 e6                	jne    801042b8 <safestrcpy+0x17>
801042d2:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
801042d4:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
801042d7:	5b                   	pop    %ebx
801042d8:	5e                   	pop    %esi
801042d9:	5f                   	pop    %edi
801042da:	5d                   	pop    %ebp
801042db:	c3                   	ret    

801042dc <strlen>:

int
strlen(const char *s)
{
801042dc:	55                   	push   %ebp
801042dd:	89 e5                	mov    %esp,%ebp
801042df:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
801042e2:	b8 00 00 00 00       	mov    $0x0,%eax
801042e7:	eb 03                	jmp    801042ec <strlen+0x10>
801042e9:	83 c0 01             	add    $0x1,%eax
801042ec:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
801042f0:	75 f7                	jne    801042e9 <strlen+0xd>
    ;
  return n;
}
801042f2:	5d                   	pop    %ebp
801042f3:	c3                   	ret    

801042f4 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
801042f4:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801042f8:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
801042fc:	55                   	push   %ebp
  pushl %ebx
801042fd:	53                   	push   %ebx
  pushl %esi
801042fe:	56                   	push   %esi
  pushl %edi
801042ff:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80104300:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80104302:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80104304:	5f                   	pop    %edi
  popl %esi
80104305:	5e                   	pop    %esi
  popl %ebx
80104306:	5b                   	pop    %ebx
  popl %ebp
80104307:	5d                   	pop    %ebp
  ret
80104308:	c3                   	ret    

80104309 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104309:	55                   	push   %ebp
8010430a:	89 e5                	mov    %esp,%ebp
8010430c:	53                   	push   %ebx
8010430d:	83 ec 04             	sub    $0x4,%esp
80104310:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80104313:	e8 19 ef ff ff       	call   80103231 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80104318:	8b 00                	mov    (%eax),%eax
8010431a:	39 d8                	cmp    %ebx,%eax
8010431c:	76 19                	jbe    80104337 <fetchint+0x2e>
8010431e:	8d 53 04             	lea    0x4(%ebx),%edx
80104321:	39 d0                	cmp    %edx,%eax
80104323:	72 19                	jb     8010433e <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80104325:	8b 13                	mov    (%ebx),%edx
80104327:	8b 45 0c             	mov    0xc(%ebp),%eax
8010432a:	89 10                	mov    %edx,(%eax)
  return 0;
8010432c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104331:	83 c4 04             	add    $0x4,%esp
80104334:	5b                   	pop    %ebx
80104335:	5d                   	pop    %ebp
80104336:	c3                   	ret    
    return -1;
80104337:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010433c:	eb f3                	jmp    80104331 <fetchint+0x28>
8010433e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104343:	eb ec                	jmp    80104331 <fetchint+0x28>

80104345 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80104345:	55                   	push   %ebp
80104346:	89 e5                	mov    %esp,%ebp
80104348:	53                   	push   %ebx
80104349:	83 ec 04             	sub    $0x4,%esp
8010434c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
8010434f:	e8 dd ee ff ff       	call   80103231 <myproc>

  if(addr >= curproc->sz)
80104354:	39 18                	cmp    %ebx,(%eax)
80104356:	76 26                	jbe    8010437e <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80104358:	8b 55 0c             	mov    0xc(%ebp),%edx
8010435b:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
8010435d:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
8010435f:	89 d8                	mov    %ebx,%eax
80104361:	39 d0                	cmp    %edx,%eax
80104363:	73 0e                	jae    80104373 <fetchstr+0x2e>
    if(*s == 0)
80104365:	80 38 00             	cmpb   $0x0,(%eax)
80104368:	74 05                	je     8010436f <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
8010436a:	83 c0 01             	add    $0x1,%eax
8010436d:	eb f2                	jmp    80104361 <fetchstr+0x1c>
      return s - *pp;
8010436f:	29 d8                	sub    %ebx,%eax
80104371:	eb 05                	jmp    80104378 <fetchstr+0x33>
  }
  return -1;
80104373:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104378:	83 c4 04             	add    $0x4,%esp
8010437b:	5b                   	pop    %ebx
8010437c:	5d                   	pop    %ebp
8010437d:	c3                   	ret    
    return -1;
8010437e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104383:	eb f3                	jmp    80104378 <fetchstr+0x33>

80104385 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80104385:	55                   	push   %ebp
80104386:	89 e5                	mov    %esp,%ebp
80104388:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
8010438b:	e8 a1 ee ff ff       	call   80103231 <myproc>
80104390:	8b 50 18             	mov    0x18(%eax),%edx
80104393:	8b 45 08             	mov    0x8(%ebp),%eax
80104396:	c1 e0 02             	shl    $0x2,%eax
80104399:	03 42 44             	add    0x44(%edx),%eax
8010439c:	83 ec 08             	sub    $0x8,%esp
8010439f:	ff 75 0c             	pushl  0xc(%ebp)
801043a2:	83 c0 04             	add    $0x4,%eax
801043a5:	50                   	push   %eax
801043a6:	e8 5e ff ff ff       	call   80104309 <fetchint>
}
801043ab:	c9                   	leave  
801043ac:	c3                   	ret    

801043ad <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801043ad:	55                   	push   %ebp
801043ae:	89 e5                	mov    %esp,%ebp
801043b0:	56                   	push   %esi
801043b1:	53                   	push   %ebx
801043b2:	83 ec 10             	sub    $0x10,%esp
801043b5:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
801043b8:	e8 74 ee ff ff       	call   80103231 <myproc>
801043bd:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
801043bf:	83 ec 08             	sub    $0x8,%esp
801043c2:	8d 45 f4             	lea    -0xc(%ebp),%eax
801043c5:	50                   	push   %eax
801043c6:	ff 75 08             	pushl  0x8(%ebp)
801043c9:	e8 b7 ff ff ff       	call   80104385 <argint>
801043ce:	83 c4 10             	add    $0x10,%esp
801043d1:	85 c0                	test   %eax,%eax
801043d3:	78 24                	js     801043f9 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
801043d5:	85 db                	test   %ebx,%ebx
801043d7:	78 27                	js     80104400 <argptr+0x53>
801043d9:	8b 16                	mov    (%esi),%edx
801043db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043de:	39 c2                	cmp    %eax,%edx
801043e0:	76 25                	jbe    80104407 <argptr+0x5a>
801043e2:	01 c3                	add    %eax,%ebx
801043e4:	39 da                	cmp    %ebx,%edx
801043e6:	72 26                	jb     8010440e <argptr+0x61>
    return -1;
  *pp = (char*)i;
801043e8:	8b 55 0c             	mov    0xc(%ebp),%edx
801043eb:	89 02                	mov    %eax,(%edx)
  return 0;
801043ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
801043f2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801043f5:	5b                   	pop    %ebx
801043f6:	5e                   	pop    %esi
801043f7:	5d                   	pop    %ebp
801043f8:	c3                   	ret    
    return -1;
801043f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043fe:	eb f2                	jmp    801043f2 <argptr+0x45>
    return -1;
80104400:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104405:	eb eb                	jmp    801043f2 <argptr+0x45>
80104407:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010440c:	eb e4                	jmp    801043f2 <argptr+0x45>
8010440e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104413:	eb dd                	jmp    801043f2 <argptr+0x45>

80104415 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104415:	55                   	push   %ebp
80104416:	89 e5                	mov    %esp,%ebp
80104418:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010441b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010441e:	50                   	push   %eax
8010441f:	ff 75 08             	pushl  0x8(%ebp)
80104422:	e8 5e ff ff ff       	call   80104385 <argint>
80104427:	83 c4 10             	add    $0x10,%esp
8010442a:	85 c0                	test   %eax,%eax
8010442c:	78 13                	js     80104441 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
8010442e:	83 ec 08             	sub    $0x8,%esp
80104431:	ff 75 0c             	pushl  0xc(%ebp)
80104434:	ff 75 f4             	pushl  -0xc(%ebp)
80104437:	e8 09 ff ff ff       	call   80104345 <fetchstr>
8010443c:	83 c4 10             	add    $0x10,%esp
}
8010443f:	c9                   	leave  
80104440:	c3                   	ret    
    return -1;
80104441:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104446:	eb f7                	jmp    8010443f <argstr+0x2a>

80104448 <syscall>:
[SYS_getpinfo] sys_getpinfo,
};

void
syscall(void)
{
80104448:	55                   	push   %ebp
80104449:	89 e5                	mov    %esp,%ebp
8010444b:	53                   	push   %ebx
8010444c:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
8010444f:	e8 dd ed ff ff       	call   80103231 <myproc>
80104454:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104456:	8b 40 18             	mov    0x18(%eax),%eax
80104459:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010445c:	8d 50 ff             	lea    -0x1(%eax),%edx
8010445f:	83 fa 18             	cmp    $0x18,%edx
80104462:	77 18                	ja     8010447c <syscall+0x34>
80104464:	8b 14 85 00 71 10 80 	mov    -0x7fef8f00(,%eax,4),%edx
8010446b:	85 d2                	test   %edx,%edx
8010446d:	74 0d                	je     8010447c <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
8010446f:	ff d2                	call   *%edx
80104471:	8b 53 18             	mov    0x18(%ebx),%edx
80104474:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
80104477:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010447a:	c9                   	leave  
8010447b:	c3                   	ret    
            curproc->pid, curproc->name, num);
8010447c:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
8010447f:	50                   	push   %eax
80104480:	52                   	push   %edx
80104481:	ff 73 10             	pushl  0x10(%ebx)
80104484:	68 c9 70 10 80       	push   $0x801070c9
80104489:	e8 7d c1 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
8010448e:	8b 43 18             	mov    0x18(%ebx),%eax
80104491:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
80104498:	83 c4 10             	add    $0x10,%esp
}
8010449b:	eb da                	jmp    80104477 <syscall+0x2f>

8010449d <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010449d:	55                   	push   %ebp
8010449e:	89 e5                	mov    %esp,%ebp
801044a0:	56                   	push   %esi
801044a1:	53                   	push   %ebx
801044a2:	83 ec 18             	sub    $0x18,%esp
801044a5:	89 d6                	mov    %edx,%esi
801044a7:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801044a9:	8d 55 f4             	lea    -0xc(%ebp),%edx
801044ac:	52                   	push   %edx
801044ad:	50                   	push   %eax
801044ae:	e8 d2 fe ff ff       	call   80104385 <argint>
801044b3:	83 c4 10             	add    $0x10,%esp
801044b6:	85 c0                	test   %eax,%eax
801044b8:	78 2e                	js     801044e8 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801044ba:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801044be:	77 2f                	ja     801044ef <argfd+0x52>
801044c0:	e8 6c ed ff ff       	call   80103231 <myproc>
801044c5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044c8:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
801044cc:	85 c0                	test   %eax,%eax
801044ce:	74 26                	je     801044f6 <argfd+0x59>
    return -1;
  if(pfd)
801044d0:	85 f6                	test   %esi,%esi
801044d2:	74 02                	je     801044d6 <argfd+0x39>
    *pfd = fd;
801044d4:	89 16                	mov    %edx,(%esi)
  if(pf)
801044d6:	85 db                	test   %ebx,%ebx
801044d8:	74 23                	je     801044fd <argfd+0x60>
    *pf = f;
801044da:	89 03                	mov    %eax,(%ebx)
  return 0;
801044dc:	b8 00 00 00 00       	mov    $0x0,%eax
}
801044e1:	8d 65 f8             	lea    -0x8(%ebp),%esp
801044e4:	5b                   	pop    %ebx
801044e5:	5e                   	pop    %esi
801044e6:	5d                   	pop    %ebp
801044e7:	c3                   	ret    
    return -1;
801044e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044ed:	eb f2                	jmp    801044e1 <argfd+0x44>
    return -1;
801044ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044f4:	eb eb                	jmp    801044e1 <argfd+0x44>
801044f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044fb:	eb e4                	jmp    801044e1 <argfd+0x44>
  return 0;
801044fd:	b8 00 00 00 00       	mov    $0x0,%eax
80104502:	eb dd                	jmp    801044e1 <argfd+0x44>

80104504 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104504:	55                   	push   %ebp
80104505:	89 e5                	mov    %esp,%ebp
80104507:	53                   	push   %ebx
80104508:	83 ec 04             	sub    $0x4,%esp
8010450b:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010450d:	e8 1f ed ff ff       	call   80103231 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104512:	ba 00 00 00 00       	mov    $0x0,%edx
80104517:	83 fa 0f             	cmp    $0xf,%edx
8010451a:	7f 18                	jg     80104534 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
8010451c:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104521:	74 05                	je     80104528 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104523:	83 c2 01             	add    $0x1,%edx
80104526:	eb ef                	jmp    80104517 <fdalloc+0x13>
      curproc->ofile[fd] = f;
80104528:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
8010452c:	89 d0                	mov    %edx,%eax
8010452e:	83 c4 04             	add    $0x4,%esp
80104531:	5b                   	pop    %ebx
80104532:	5d                   	pop    %ebp
80104533:	c3                   	ret    
  return -1;
80104534:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104539:	eb f1                	jmp    8010452c <fdalloc+0x28>

8010453b <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010453b:	55                   	push   %ebp
8010453c:	89 e5                	mov    %esp,%ebp
8010453e:	56                   	push   %esi
8010453f:	53                   	push   %ebx
80104540:	83 ec 10             	sub    $0x10,%esp
80104543:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104545:	b8 20 00 00 00       	mov    $0x20,%eax
8010454a:	89 c6                	mov    %eax,%esi
8010454c:	39 43 58             	cmp    %eax,0x58(%ebx)
8010454f:	76 2e                	jbe    8010457f <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104551:	6a 10                	push   $0x10
80104553:	50                   	push   %eax
80104554:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104557:	50                   	push   %eax
80104558:	53                   	push   %ebx
80104559:	e8 15 d2 ff ff       	call   80101773 <readi>
8010455e:	83 c4 10             	add    $0x10,%esp
80104561:	83 f8 10             	cmp    $0x10,%eax
80104564:	75 0c                	jne    80104572 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104566:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
8010456b:	75 1e                	jne    8010458b <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010456d:	8d 46 10             	lea    0x10(%esi),%eax
80104570:	eb d8                	jmp    8010454a <isdirempty+0xf>
      panic("isdirempty: readi");
80104572:	83 ec 0c             	sub    $0xc,%esp
80104575:	68 68 71 10 80       	push   $0x80107168
8010457a:	e8 c9 bd ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
8010457f:	b8 01 00 00 00       	mov    $0x1,%eax
}
80104584:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104587:	5b                   	pop    %ebx
80104588:	5e                   	pop    %esi
80104589:	5d                   	pop    %ebp
8010458a:	c3                   	ret    
      return 0;
8010458b:	b8 00 00 00 00       	mov    $0x0,%eax
80104590:	eb f2                	jmp    80104584 <isdirempty+0x49>

80104592 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104592:	55                   	push   %ebp
80104593:	89 e5                	mov    %esp,%ebp
80104595:	57                   	push   %edi
80104596:	56                   	push   %esi
80104597:	53                   	push   %ebx
80104598:	83 ec 44             	sub    $0x44,%esp
8010459b:	89 55 c4             	mov    %edx,-0x3c(%ebp)
8010459e:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801045a1:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801045a4:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801045a7:	52                   	push   %edx
801045a8:	50                   	push   %eax
801045a9:	e8 4b d6 ff ff       	call   80101bf9 <nameiparent>
801045ae:	89 c6                	mov    %eax,%esi
801045b0:	83 c4 10             	add    $0x10,%esp
801045b3:	85 c0                	test   %eax,%eax
801045b5:	0f 84 3a 01 00 00    	je     801046f5 <create+0x163>
    return 0;
  ilock(dp);
801045bb:	83 ec 0c             	sub    $0xc,%esp
801045be:	50                   	push   %eax
801045bf:	e8 bd cf ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801045c4:	83 c4 0c             	add    $0xc,%esp
801045c7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801045ca:	50                   	push   %eax
801045cb:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801045ce:	50                   	push   %eax
801045cf:	56                   	push   %esi
801045d0:	e8 db d3 ff ff       	call   801019b0 <dirlookup>
801045d5:	89 c3                	mov    %eax,%ebx
801045d7:	83 c4 10             	add    $0x10,%esp
801045da:	85 c0                	test   %eax,%eax
801045dc:	74 3f                	je     8010461d <create+0x8b>
    iunlockput(dp);
801045de:	83 ec 0c             	sub    $0xc,%esp
801045e1:	56                   	push   %esi
801045e2:	e8 41 d1 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
801045e7:	89 1c 24             	mov    %ebx,(%esp)
801045ea:	e8 92 cf ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801045ef:	83 c4 10             	add    $0x10,%esp
801045f2:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
801045f7:	75 11                	jne    8010460a <create+0x78>
801045f9:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
801045fe:	75 0a                	jne    8010460a <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104600:	89 d8                	mov    %ebx,%eax
80104602:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104605:	5b                   	pop    %ebx
80104606:	5e                   	pop    %esi
80104607:	5f                   	pop    %edi
80104608:	5d                   	pop    %ebp
80104609:	c3                   	ret    
    iunlockput(ip);
8010460a:	83 ec 0c             	sub    $0xc,%esp
8010460d:	53                   	push   %ebx
8010460e:	e8 15 d1 ff ff       	call   80101728 <iunlockput>
    return 0;
80104613:	83 c4 10             	add    $0x10,%esp
80104616:	bb 00 00 00 00       	mov    $0x0,%ebx
8010461b:	eb e3                	jmp    80104600 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
8010461d:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104621:	83 ec 08             	sub    $0x8,%esp
80104624:	50                   	push   %eax
80104625:	ff 36                	pushl  (%esi)
80104627:	e8 52 cd ff ff       	call   8010137e <ialloc>
8010462c:	89 c3                	mov    %eax,%ebx
8010462e:	83 c4 10             	add    $0x10,%esp
80104631:	85 c0                	test   %eax,%eax
80104633:	74 55                	je     8010468a <create+0xf8>
  ilock(ip);
80104635:	83 ec 0c             	sub    $0xc,%esp
80104638:	50                   	push   %eax
80104639:	e8 43 cf ff ff       	call   80101581 <ilock>
  ip->major = major;
8010463e:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104642:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104646:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
8010464a:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
80104650:	89 1c 24             	mov    %ebx,(%esp)
80104653:	e8 c8 cd ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104658:	83 c4 10             	add    $0x10,%esp
8010465b:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
80104660:	74 35                	je     80104697 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
80104662:	83 ec 04             	sub    $0x4,%esp
80104665:	ff 73 04             	pushl  0x4(%ebx)
80104668:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010466b:	50                   	push   %eax
8010466c:	56                   	push   %esi
8010466d:	e8 be d4 ff ff       	call   80101b30 <dirlink>
80104672:	83 c4 10             	add    $0x10,%esp
80104675:	85 c0                	test   %eax,%eax
80104677:	78 6f                	js     801046e8 <create+0x156>
  iunlockput(dp);
80104679:	83 ec 0c             	sub    $0xc,%esp
8010467c:	56                   	push   %esi
8010467d:	e8 a6 d0 ff ff       	call   80101728 <iunlockput>
  return ip;
80104682:	83 c4 10             	add    $0x10,%esp
80104685:	e9 76 ff ff ff       	jmp    80104600 <create+0x6e>
    panic("create: ialloc");
8010468a:	83 ec 0c             	sub    $0xc,%esp
8010468d:	68 7a 71 10 80       	push   $0x8010717a
80104692:	e8 b1 bc ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104697:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010469b:	83 c0 01             	add    $0x1,%eax
8010469e:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801046a2:	83 ec 0c             	sub    $0xc,%esp
801046a5:	56                   	push   %esi
801046a6:	e8 75 cd ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801046ab:	83 c4 0c             	add    $0xc,%esp
801046ae:	ff 73 04             	pushl  0x4(%ebx)
801046b1:	68 8a 71 10 80       	push   $0x8010718a
801046b6:	53                   	push   %ebx
801046b7:	e8 74 d4 ff ff       	call   80101b30 <dirlink>
801046bc:	83 c4 10             	add    $0x10,%esp
801046bf:	85 c0                	test   %eax,%eax
801046c1:	78 18                	js     801046db <create+0x149>
801046c3:	83 ec 04             	sub    $0x4,%esp
801046c6:	ff 76 04             	pushl  0x4(%esi)
801046c9:	68 89 71 10 80       	push   $0x80107189
801046ce:	53                   	push   %ebx
801046cf:	e8 5c d4 ff ff       	call   80101b30 <dirlink>
801046d4:	83 c4 10             	add    $0x10,%esp
801046d7:	85 c0                	test   %eax,%eax
801046d9:	79 87                	jns    80104662 <create+0xd0>
      panic("create dots");
801046db:	83 ec 0c             	sub    $0xc,%esp
801046de:	68 8c 71 10 80       	push   $0x8010718c
801046e3:	e8 60 bc ff ff       	call   80100348 <panic>
    panic("create: dirlink");
801046e8:	83 ec 0c             	sub    $0xc,%esp
801046eb:	68 98 71 10 80       	push   $0x80107198
801046f0:	e8 53 bc ff ff       	call   80100348 <panic>
    return 0;
801046f5:	89 c3                	mov    %eax,%ebx
801046f7:	e9 04 ff ff ff       	jmp    80104600 <create+0x6e>

801046fc <sys_dup>:
{
801046fc:	55                   	push   %ebp
801046fd:	89 e5                	mov    %esp,%ebp
801046ff:	53                   	push   %ebx
80104700:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104703:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104706:	ba 00 00 00 00       	mov    $0x0,%edx
8010470b:	b8 00 00 00 00       	mov    $0x0,%eax
80104710:	e8 88 fd ff ff       	call   8010449d <argfd>
80104715:	85 c0                	test   %eax,%eax
80104717:	78 23                	js     8010473c <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104719:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010471c:	e8 e3 fd ff ff       	call   80104504 <fdalloc>
80104721:	89 c3                	mov    %eax,%ebx
80104723:	85 c0                	test   %eax,%eax
80104725:	78 1c                	js     80104743 <sys_dup+0x47>
  filedup(f);
80104727:	83 ec 0c             	sub    $0xc,%esp
8010472a:	ff 75 f4             	pushl  -0xc(%ebp)
8010472d:	e8 5c c5 ff ff       	call   80100c8e <filedup>
  return fd;
80104732:	83 c4 10             	add    $0x10,%esp
}
80104735:	89 d8                	mov    %ebx,%eax
80104737:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010473a:	c9                   	leave  
8010473b:	c3                   	ret    
    return -1;
8010473c:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104741:	eb f2                	jmp    80104735 <sys_dup+0x39>
    return -1;
80104743:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104748:	eb eb                	jmp    80104735 <sys_dup+0x39>

8010474a <sys_read>:
{
8010474a:	55                   	push   %ebp
8010474b:	89 e5                	mov    %esp,%ebp
8010474d:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104750:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104753:	ba 00 00 00 00       	mov    $0x0,%edx
80104758:	b8 00 00 00 00       	mov    $0x0,%eax
8010475d:	e8 3b fd ff ff       	call   8010449d <argfd>
80104762:	85 c0                	test   %eax,%eax
80104764:	78 43                	js     801047a9 <sys_read+0x5f>
80104766:	83 ec 08             	sub    $0x8,%esp
80104769:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010476c:	50                   	push   %eax
8010476d:	6a 02                	push   $0x2
8010476f:	e8 11 fc ff ff       	call   80104385 <argint>
80104774:	83 c4 10             	add    $0x10,%esp
80104777:	85 c0                	test   %eax,%eax
80104779:	78 35                	js     801047b0 <sys_read+0x66>
8010477b:	83 ec 04             	sub    $0x4,%esp
8010477e:	ff 75 f0             	pushl  -0x10(%ebp)
80104781:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104784:	50                   	push   %eax
80104785:	6a 01                	push   $0x1
80104787:	e8 21 fc ff ff       	call   801043ad <argptr>
8010478c:	83 c4 10             	add    $0x10,%esp
8010478f:	85 c0                	test   %eax,%eax
80104791:	78 24                	js     801047b7 <sys_read+0x6d>
  return fileread(f, p, n);
80104793:	83 ec 04             	sub    $0x4,%esp
80104796:	ff 75 f0             	pushl  -0x10(%ebp)
80104799:	ff 75 ec             	pushl  -0x14(%ebp)
8010479c:	ff 75 f4             	pushl  -0xc(%ebp)
8010479f:	e8 33 c6 ff ff       	call   80100dd7 <fileread>
801047a4:	83 c4 10             	add    $0x10,%esp
}
801047a7:	c9                   	leave  
801047a8:	c3                   	ret    
    return -1;
801047a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047ae:	eb f7                	jmp    801047a7 <sys_read+0x5d>
801047b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047b5:	eb f0                	jmp    801047a7 <sys_read+0x5d>
801047b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047bc:	eb e9                	jmp    801047a7 <sys_read+0x5d>

801047be <sys_write>:
{
801047be:	55                   	push   %ebp
801047bf:	89 e5                	mov    %esp,%ebp
801047c1:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801047c4:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801047c7:	ba 00 00 00 00       	mov    $0x0,%edx
801047cc:	b8 00 00 00 00       	mov    $0x0,%eax
801047d1:	e8 c7 fc ff ff       	call   8010449d <argfd>
801047d6:	85 c0                	test   %eax,%eax
801047d8:	78 43                	js     8010481d <sys_write+0x5f>
801047da:	83 ec 08             	sub    $0x8,%esp
801047dd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801047e0:	50                   	push   %eax
801047e1:	6a 02                	push   $0x2
801047e3:	e8 9d fb ff ff       	call   80104385 <argint>
801047e8:	83 c4 10             	add    $0x10,%esp
801047eb:	85 c0                	test   %eax,%eax
801047ed:	78 35                	js     80104824 <sys_write+0x66>
801047ef:	83 ec 04             	sub    $0x4,%esp
801047f2:	ff 75 f0             	pushl  -0x10(%ebp)
801047f5:	8d 45 ec             	lea    -0x14(%ebp),%eax
801047f8:	50                   	push   %eax
801047f9:	6a 01                	push   $0x1
801047fb:	e8 ad fb ff ff       	call   801043ad <argptr>
80104800:	83 c4 10             	add    $0x10,%esp
80104803:	85 c0                	test   %eax,%eax
80104805:	78 24                	js     8010482b <sys_write+0x6d>
  return filewrite(f, p, n);
80104807:	83 ec 04             	sub    $0x4,%esp
8010480a:	ff 75 f0             	pushl  -0x10(%ebp)
8010480d:	ff 75 ec             	pushl  -0x14(%ebp)
80104810:	ff 75 f4             	pushl  -0xc(%ebp)
80104813:	e8 44 c6 ff ff       	call   80100e5c <filewrite>
80104818:	83 c4 10             	add    $0x10,%esp
}
8010481b:	c9                   	leave  
8010481c:	c3                   	ret    
    return -1;
8010481d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104822:	eb f7                	jmp    8010481b <sys_write+0x5d>
80104824:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104829:	eb f0                	jmp    8010481b <sys_write+0x5d>
8010482b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104830:	eb e9                	jmp    8010481b <sys_write+0x5d>

80104832 <sys_close>:
{
80104832:	55                   	push   %ebp
80104833:	89 e5                	mov    %esp,%ebp
80104835:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104838:	8d 4d f0             	lea    -0x10(%ebp),%ecx
8010483b:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010483e:	b8 00 00 00 00       	mov    $0x0,%eax
80104843:	e8 55 fc ff ff       	call   8010449d <argfd>
80104848:	85 c0                	test   %eax,%eax
8010484a:	78 25                	js     80104871 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
8010484c:	e8 e0 e9 ff ff       	call   80103231 <myproc>
80104851:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104854:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
8010485b:	00 
  fileclose(f);
8010485c:	83 ec 0c             	sub    $0xc,%esp
8010485f:	ff 75 f0             	pushl  -0x10(%ebp)
80104862:	e8 6c c4 ff ff       	call   80100cd3 <fileclose>
  return 0;
80104867:	83 c4 10             	add    $0x10,%esp
8010486a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010486f:	c9                   	leave  
80104870:	c3                   	ret    
    return -1;
80104871:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104876:	eb f7                	jmp    8010486f <sys_close+0x3d>

80104878 <sys_fstat>:
{
80104878:	55                   	push   %ebp
80104879:	89 e5                	mov    %esp,%ebp
8010487b:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010487e:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104881:	ba 00 00 00 00       	mov    $0x0,%edx
80104886:	b8 00 00 00 00       	mov    $0x0,%eax
8010488b:	e8 0d fc ff ff       	call   8010449d <argfd>
80104890:	85 c0                	test   %eax,%eax
80104892:	78 2a                	js     801048be <sys_fstat+0x46>
80104894:	83 ec 04             	sub    $0x4,%esp
80104897:	6a 14                	push   $0x14
80104899:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010489c:	50                   	push   %eax
8010489d:	6a 01                	push   $0x1
8010489f:	e8 09 fb ff ff       	call   801043ad <argptr>
801048a4:	83 c4 10             	add    $0x10,%esp
801048a7:	85 c0                	test   %eax,%eax
801048a9:	78 1a                	js     801048c5 <sys_fstat+0x4d>
  return filestat(f, st);
801048ab:	83 ec 08             	sub    $0x8,%esp
801048ae:	ff 75 f0             	pushl  -0x10(%ebp)
801048b1:	ff 75 f4             	pushl  -0xc(%ebp)
801048b4:	e8 d7 c4 ff ff       	call   80100d90 <filestat>
801048b9:	83 c4 10             	add    $0x10,%esp
}
801048bc:	c9                   	leave  
801048bd:	c3                   	ret    
    return -1;
801048be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048c3:	eb f7                	jmp    801048bc <sys_fstat+0x44>
801048c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048ca:	eb f0                	jmp    801048bc <sys_fstat+0x44>

801048cc <sys_link>:
{
801048cc:	55                   	push   %ebp
801048cd:	89 e5                	mov    %esp,%ebp
801048cf:	56                   	push   %esi
801048d0:	53                   	push   %ebx
801048d1:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801048d4:	8d 45 e0             	lea    -0x20(%ebp),%eax
801048d7:	50                   	push   %eax
801048d8:	6a 00                	push   $0x0
801048da:	e8 36 fb ff ff       	call   80104415 <argstr>
801048df:	83 c4 10             	add    $0x10,%esp
801048e2:	85 c0                	test   %eax,%eax
801048e4:	0f 88 32 01 00 00    	js     80104a1c <sys_link+0x150>
801048ea:	83 ec 08             	sub    $0x8,%esp
801048ed:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801048f0:	50                   	push   %eax
801048f1:	6a 01                	push   $0x1
801048f3:	e8 1d fb ff ff       	call   80104415 <argstr>
801048f8:	83 c4 10             	add    $0x10,%esp
801048fb:	85 c0                	test   %eax,%eax
801048fd:	0f 88 20 01 00 00    	js     80104a23 <sys_link+0x157>
  begin_op();
80104903:	e8 a6 de ff ff       	call   801027ae <begin_op>
  if((ip = namei(old)) == 0){
80104908:	83 ec 0c             	sub    $0xc,%esp
8010490b:	ff 75 e0             	pushl  -0x20(%ebp)
8010490e:	e8 ce d2 ff ff       	call   80101be1 <namei>
80104913:	89 c3                	mov    %eax,%ebx
80104915:	83 c4 10             	add    $0x10,%esp
80104918:	85 c0                	test   %eax,%eax
8010491a:	0f 84 99 00 00 00    	je     801049b9 <sys_link+0xed>
  ilock(ip);
80104920:	83 ec 0c             	sub    $0xc,%esp
80104923:	50                   	push   %eax
80104924:	e8 58 cc ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
80104929:	83 c4 10             	add    $0x10,%esp
8010492c:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104931:	0f 84 8e 00 00 00    	je     801049c5 <sys_link+0xf9>
  ip->nlink++;
80104937:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010493b:	83 c0 01             	add    $0x1,%eax
8010493e:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104942:	83 ec 0c             	sub    $0xc,%esp
80104945:	53                   	push   %ebx
80104946:	e8 d5 ca ff ff       	call   80101420 <iupdate>
  iunlock(ip);
8010494b:	89 1c 24             	mov    %ebx,(%esp)
8010494e:	e8 f0 cc ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104953:	83 c4 08             	add    $0x8,%esp
80104956:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104959:	50                   	push   %eax
8010495a:	ff 75 e4             	pushl  -0x1c(%ebp)
8010495d:	e8 97 d2 ff ff       	call   80101bf9 <nameiparent>
80104962:	89 c6                	mov    %eax,%esi
80104964:	83 c4 10             	add    $0x10,%esp
80104967:	85 c0                	test   %eax,%eax
80104969:	74 7e                	je     801049e9 <sys_link+0x11d>
  ilock(dp);
8010496b:	83 ec 0c             	sub    $0xc,%esp
8010496e:	50                   	push   %eax
8010496f:	e8 0d cc ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80104974:	83 c4 10             	add    $0x10,%esp
80104977:	8b 03                	mov    (%ebx),%eax
80104979:	39 06                	cmp    %eax,(%esi)
8010497b:	75 60                	jne    801049dd <sys_link+0x111>
8010497d:	83 ec 04             	sub    $0x4,%esp
80104980:	ff 73 04             	pushl  0x4(%ebx)
80104983:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104986:	50                   	push   %eax
80104987:	56                   	push   %esi
80104988:	e8 a3 d1 ff ff       	call   80101b30 <dirlink>
8010498d:	83 c4 10             	add    $0x10,%esp
80104990:	85 c0                	test   %eax,%eax
80104992:	78 49                	js     801049dd <sys_link+0x111>
  iunlockput(dp);
80104994:	83 ec 0c             	sub    $0xc,%esp
80104997:	56                   	push   %esi
80104998:	e8 8b cd ff ff       	call   80101728 <iunlockput>
  iput(ip);
8010499d:	89 1c 24             	mov    %ebx,(%esp)
801049a0:	e8 e3 cc ff ff       	call   80101688 <iput>
  end_op();
801049a5:	e8 7e de ff ff       	call   80102828 <end_op>
  return 0;
801049aa:	83 c4 10             	add    $0x10,%esp
801049ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049b2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801049b5:	5b                   	pop    %ebx
801049b6:	5e                   	pop    %esi
801049b7:	5d                   	pop    %ebp
801049b8:	c3                   	ret    
    end_op();
801049b9:	e8 6a de ff ff       	call   80102828 <end_op>
    return -1;
801049be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049c3:	eb ed                	jmp    801049b2 <sys_link+0xe6>
    iunlockput(ip);
801049c5:	83 ec 0c             	sub    $0xc,%esp
801049c8:	53                   	push   %ebx
801049c9:	e8 5a cd ff ff       	call   80101728 <iunlockput>
    end_op();
801049ce:	e8 55 de ff ff       	call   80102828 <end_op>
    return -1;
801049d3:	83 c4 10             	add    $0x10,%esp
801049d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049db:	eb d5                	jmp    801049b2 <sys_link+0xe6>
    iunlockput(dp);
801049dd:	83 ec 0c             	sub    $0xc,%esp
801049e0:	56                   	push   %esi
801049e1:	e8 42 cd ff ff       	call   80101728 <iunlockput>
    goto bad;
801049e6:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
801049e9:	83 ec 0c             	sub    $0xc,%esp
801049ec:	53                   	push   %ebx
801049ed:	e8 8f cb ff ff       	call   80101581 <ilock>
  ip->nlink--;
801049f2:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801049f6:	83 e8 01             	sub    $0x1,%eax
801049f9:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801049fd:	89 1c 24             	mov    %ebx,(%esp)
80104a00:	e8 1b ca ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104a05:	89 1c 24             	mov    %ebx,(%esp)
80104a08:	e8 1b cd ff ff       	call   80101728 <iunlockput>
  end_op();
80104a0d:	e8 16 de ff ff       	call   80102828 <end_op>
  return -1;
80104a12:	83 c4 10             	add    $0x10,%esp
80104a15:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a1a:	eb 96                	jmp    801049b2 <sys_link+0xe6>
    return -1;
80104a1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a21:	eb 8f                	jmp    801049b2 <sys_link+0xe6>
80104a23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a28:	eb 88                	jmp    801049b2 <sys_link+0xe6>

80104a2a <sys_unlink>:
{
80104a2a:	55                   	push   %ebp
80104a2b:	89 e5                	mov    %esp,%ebp
80104a2d:	57                   	push   %edi
80104a2e:	56                   	push   %esi
80104a2f:	53                   	push   %ebx
80104a30:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104a33:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104a36:	50                   	push   %eax
80104a37:	6a 00                	push   $0x0
80104a39:	e8 d7 f9 ff ff       	call   80104415 <argstr>
80104a3e:	83 c4 10             	add    $0x10,%esp
80104a41:	85 c0                	test   %eax,%eax
80104a43:	0f 88 83 01 00 00    	js     80104bcc <sys_unlink+0x1a2>
  begin_op();
80104a49:	e8 60 dd ff ff       	call   801027ae <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104a4e:	83 ec 08             	sub    $0x8,%esp
80104a51:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104a54:	50                   	push   %eax
80104a55:	ff 75 c4             	pushl  -0x3c(%ebp)
80104a58:	e8 9c d1 ff ff       	call   80101bf9 <nameiparent>
80104a5d:	89 c6                	mov    %eax,%esi
80104a5f:	83 c4 10             	add    $0x10,%esp
80104a62:	85 c0                	test   %eax,%eax
80104a64:	0f 84 ed 00 00 00    	je     80104b57 <sys_unlink+0x12d>
  ilock(dp);
80104a6a:	83 ec 0c             	sub    $0xc,%esp
80104a6d:	50                   	push   %eax
80104a6e:	e8 0e cb ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104a73:	83 c4 08             	add    $0x8,%esp
80104a76:	68 8a 71 10 80       	push   $0x8010718a
80104a7b:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104a7e:	50                   	push   %eax
80104a7f:	e8 17 cf ff ff       	call   8010199b <namecmp>
80104a84:	83 c4 10             	add    $0x10,%esp
80104a87:	85 c0                	test   %eax,%eax
80104a89:	0f 84 fc 00 00 00    	je     80104b8b <sys_unlink+0x161>
80104a8f:	83 ec 08             	sub    $0x8,%esp
80104a92:	68 89 71 10 80       	push   $0x80107189
80104a97:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104a9a:	50                   	push   %eax
80104a9b:	e8 fb ce ff ff       	call   8010199b <namecmp>
80104aa0:	83 c4 10             	add    $0x10,%esp
80104aa3:	85 c0                	test   %eax,%eax
80104aa5:	0f 84 e0 00 00 00    	je     80104b8b <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104aab:	83 ec 04             	sub    $0x4,%esp
80104aae:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104ab1:	50                   	push   %eax
80104ab2:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104ab5:	50                   	push   %eax
80104ab6:	56                   	push   %esi
80104ab7:	e8 f4 ce ff ff       	call   801019b0 <dirlookup>
80104abc:	89 c3                	mov    %eax,%ebx
80104abe:	83 c4 10             	add    $0x10,%esp
80104ac1:	85 c0                	test   %eax,%eax
80104ac3:	0f 84 c2 00 00 00    	je     80104b8b <sys_unlink+0x161>
  ilock(ip);
80104ac9:	83 ec 0c             	sub    $0xc,%esp
80104acc:	50                   	push   %eax
80104acd:	e8 af ca ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
80104ad2:	83 c4 10             	add    $0x10,%esp
80104ad5:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104ada:	0f 8e 83 00 00 00    	jle    80104b63 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104ae0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104ae5:	0f 84 85 00 00 00    	je     80104b70 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104aeb:	83 ec 04             	sub    $0x4,%esp
80104aee:	6a 10                	push   $0x10
80104af0:	6a 00                	push   $0x0
80104af2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104af5:	57                   	push   %edi
80104af6:	e8 3f f6 ff ff       	call   8010413a <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104afb:	6a 10                	push   $0x10
80104afd:	ff 75 c0             	pushl  -0x40(%ebp)
80104b00:	57                   	push   %edi
80104b01:	56                   	push   %esi
80104b02:	e8 69 cd ff ff       	call   80101870 <writei>
80104b07:	83 c4 20             	add    $0x20,%esp
80104b0a:	83 f8 10             	cmp    $0x10,%eax
80104b0d:	0f 85 90 00 00 00    	jne    80104ba3 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104b13:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104b18:	0f 84 92 00 00 00    	je     80104bb0 <sys_unlink+0x186>
  iunlockput(dp);
80104b1e:	83 ec 0c             	sub    $0xc,%esp
80104b21:	56                   	push   %esi
80104b22:	e8 01 cc ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
80104b27:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104b2b:	83 e8 01             	sub    $0x1,%eax
80104b2e:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104b32:	89 1c 24             	mov    %ebx,(%esp)
80104b35:	e8 e6 c8 ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104b3a:	89 1c 24             	mov    %ebx,(%esp)
80104b3d:	e8 e6 cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104b42:	e8 e1 dc ff ff       	call   80102828 <end_op>
  return 0;
80104b47:	83 c4 10             	add    $0x10,%esp
80104b4a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b4f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104b52:	5b                   	pop    %ebx
80104b53:	5e                   	pop    %esi
80104b54:	5f                   	pop    %edi
80104b55:	5d                   	pop    %ebp
80104b56:	c3                   	ret    
    end_op();
80104b57:	e8 cc dc ff ff       	call   80102828 <end_op>
    return -1;
80104b5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b61:	eb ec                	jmp    80104b4f <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104b63:	83 ec 0c             	sub    $0xc,%esp
80104b66:	68 a8 71 10 80       	push   $0x801071a8
80104b6b:	e8 d8 b7 ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104b70:	89 d8                	mov    %ebx,%eax
80104b72:	e8 c4 f9 ff ff       	call   8010453b <isdirempty>
80104b77:	85 c0                	test   %eax,%eax
80104b79:	0f 85 6c ff ff ff    	jne    80104aeb <sys_unlink+0xc1>
    iunlockput(ip);
80104b7f:	83 ec 0c             	sub    $0xc,%esp
80104b82:	53                   	push   %ebx
80104b83:	e8 a0 cb ff ff       	call   80101728 <iunlockput>
    goto bad;
80104b88:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104b8b:	83 ec 0c             	sub    $0xc,%esp
80104b8e:	56                   	push   %esi
80104b8f:	e8 94 cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104b94:	e8 8f dc ff ff       	call   80102828 <end_op>
  return -1;
80104b99:	83 c4 10             	add    $0x10,%esp
80104b9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ba1:	eb ac                	jmp    80104b4f <sys_unlink+0x125>
    panic("unlink: writei");
80104ba3:	83 ec 0c             	sub    $0xc,%esp
80104ba6:	68 ba 71 10 80       	push   $0x801071ba
80104bab:	e8 98 b7 ff ff       	call   80100348 <panic>
    dp->nlink--;
80104bb0:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104bb4:	83 e8 01             	sub    $0x1,%eax
80104bb7:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104bbb:	83 ec 0c             	sub    $0xc,%esp
80104bbe:	56                   	push   %esi
80104bbf:	e8 5c c8 ff ff       	call   80101420 <iupdate>
80104bc4:	83 c4 10             	add    $0x10,%esp
80104bc7:	e9 52 ff ff ff       	jmp    80104b1e <sys_unlink+0xf4>
    return -1;
80104bcc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bd1:	e9 79 ff ff ff       	jmp    80104b4f <sys_unlink+0x125>

80104bd6 <sys_open>:

int
sys_open(void)
{
80104bd6:	55                   	push   %ebp
80104bd7:	89 e5                	mov    %esp,%ebp
80104bd9:	57                   	push   %edi
80104bda:	56                   	push   %esi
80104bdb:	53                   	push   %ebx
80104bdc:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104bdf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104be2:	50                   	push   %eax
80104be3:	6a 00                	push   $0x0
80104be5:	e8 2b f8 ff ff       	call   80104415 <argstr>
80104bea:	83 c4 10             	add    $0x10,%esp
80104bed:	85 c0                	test   %eax,%eax
80104bef:	0f 88 30 01 00 00    	js     80104d25 <sys_open+0x14f>
80104bf5:	83 ec 08             	sub    $0x8,%esp
80104bf8:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104bfb:	50                   	push   %eax
80104bfc:	6a 01                	push   $0x1
80104bfe:	e8 82 f7 ff ff       	call   80104385 <argint>
80104c03:	83 c4 10             	add    $0x10,%esp
80104c06:	85 c0                	test   %eax,%eax
80104c08:	0f 88 21 01 00 00    	js     80104d2f <sys_open+0x159>
    return -1;

  begin_op();
80104c0e:	e8 9b db ff ff       	call   801027ae <begin_op>

  if(omode & O_CREATE){
80104c13:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104c17:	0f 84 84 00 00 00    	je     80104ca1 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104c1d:	83 ec 0c             	sub    $0xc,%esp
80104c20:	6a 00                	push   $0x0
80104c22:	b9 00 00 00 00       	mov    $0x0,%ecx
80104c27:	ba 02 00 00 00       	mov    $0x2,%edx
80104c2c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104c2f:	e8 5e f9 ff ff       	call   80104592 <create>
80104c34:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104c36:	83 c4 10             	add    $0x10,%esp
80104c39:	85 c0                	test   %eax,%eax
80104c3b:	74 58                	je     80104c95 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104c3d:	e8 eb bf ff ff       	call   80100c2d <filealloc>
80104c42:	89 c3                	mov    %eax,%ebx
80104c44:	85 c0                	test   %eax,%eax
80104c46:	0f 84 ae 00 00 00    	je     80104cfa <sys_open+0x124>
80104c4c:	e8 b3 f8 ff ff       	call   80104504 <fdalloc>
80104c51:	89 c7                	mov    %eax,%edi
80104c53:	85 c0                	test   %eax,%eax
80104c55:	0f 88 9f 00 00 00    	js     80104cfa <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104c5b:	83 ec 0c             	sub    $0xc,%esp
80104c5e:	56                   	push   %esi
80104c5f:	e8 df c9 ff ff       	call   80101643 <iunlock>
  end_op();
80104c64:	e8 bf db ff ff       	call   80102828 <end_op>

  f->type = FD_INODE;
80104c69:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104c6f:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104c72:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104c79:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c7c:	83 c4 10             	add    $0x10,%esp
80104c7f:	a8 01                	test   $0x1,%al
80104c81:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104c85:	a8 03                	test   $0x3,%al
80104c87:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104c8b:	89 f8                	mov    %edi,%eax
80104c8d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104c90:	5b                   	pop    %ebx
80104c91:	5e                   	pop    %esi
80104c92:	5f                   	pop    %edi
80104c93:	5d                   	pop    %ebp
80104c94:	c3                   	ret    
      end_op();
80104c95:	e8 8e db ff ff       	call   80102828 <end_op>
      return -1;
80104c9a:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104c9f:	eb ea                	jmp    80104c8b <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104ca1:	83 ec 0c             	sub    $0xc,%esp
80104ca4:	ff 75 e4             	pushl  -0x1c(%ebp)
80104ca7:	e8 35 cf ff ff       	call   80101be1 <namei>
80104cac:	89 c6                	mov    %eax,%esi
80104cae:	83 c4 10             	add    $0x10,%esp
80104cb1:	85 c0                	test   %eax,%eax
80104cb3:	74 39                	je     80104cee <sys_open+0x118>
    ilock(ip);
80104cb5:	83 ec 0c             	sub    $0xc,%esp
80104cb8:	50                   	push   %eax
80104cb9:	e8 c3 c8 ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104cbe:	83 c4 10             	add    $0x10,%esp
80104cc1:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104cc6:	0f 85 71 ff ff ff    	jne    80104c3d <sys_open+0x67>
80104ccc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104cd0:	0f 84 67 ff ff ff    	je     80104c3d <sys_open+0x67>
      iunlockput(ip);
80104cd6:	83 ec 0c             	sub    $0xc,%esp
80104cd9:	56                   	push   %esi
80104cda:	e8 49 ca ff ff       	call   80101728 <iunlockput>
      end_op();
80104cdf:	e8 44 db ff ff       	call   80102828 <end_op>
      return -1;
80104ce4:	83 c4 10             	add    $0x10,%esp
80104ce7:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104cec:	eb 9d                	jmp    80104c8b <sys_open+0xb5>
      end_op();
80104cee:	e8 35 db ff ff       	call   80102828 <end_op>
      return -1;
80104cf3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104cf8:	eb 91                	jmp    80104c8b <sys_open+0xb5>
    if(f)
80104cfa:	85 db                	test   %ebx,%ebx
80104cfc:	74 0c                	je     80104d0a <sys_open+0x134>
      fileclose(f);
80104cfe:	83 ec 0c             	sub    $0xc,%esp
80104d01:	53                   	push   %ebx
80104d02:	e8 cc bf ff ff       	call   80100cd3 <fileclose>
80104d07:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104d0a:	83 ec 0c             	sub    $0xc,%esp
80104d0d:	56                   	push   %esi
80104d0e:	e8 15 ca ff ff       	call   80101728 <iunlockput>
    end_op();
80104d13:	e8 10 db ff ff       	call   80102828 <end_op>
    return -1;
80104d18:	83 c4 10             	add    $0x10,%esp
80104d1b:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d20:	e9 66 ff ff ff       	jmp    80104c8b <sys_open+0xb5>
    return -1;
80104d25:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d2a:	e9 5c ff ff ff       	jmp    80104c8b <sys_open+0xb5>
80104d2f:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104d34:	e9 52 ff ff ff       	jmp    80104c8b <sys_open+0xb5>

80104d39 <sys_mkdir>:

int
sys_mkdir(void)
{
80104d39:	55                   	push   %ebp
80104d3a:	89 e5                	mov    %esp,%ebp
80104d3c:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104d3f:	e8 6a da ff ff       	call   801027ae <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104d44:	83 ec 08             	sub    $0x8,%esp
80104d47:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d4a:	50                   	push   %eax
80104d4b:	6a 00                	push   $0x0
80104d4d:	e8 c3 f6 ff ff       	call   80104415 <argstr>
80104d52:	83 c4 10             	add    $0x10,%esp
80104d55:	85 c0                	test   %eax,%eax
80104d57:	78 36                	js     80104d8f <sys_mkdir+0x56>
80104d59:	83 ec 0c             	sub    $0xc,%esp
80104d5c:	6a 00                	push   $0x0
80104d5e:	b9 00 00 00 00       	mov    $0x0,%ecx
80104d63:	ba 01 00 00 00       	mov    $0x1,%edx
80104d68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d6b:	e8 22 f8 ff ff       	call   80104592 <create>
80104d70:	83 c4 10             	add    $0x10,%esp
80104d73:	85 c0                	test   %eax,%eax
80104d75:	74 18                	je     80104d8f <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104d77:	83 ec 0c             	sub    $0xc,%esp
80104d7a:	50                   	push   %eax
80104d7b:	e8 a8 c9 ff ff       	call   80101728 <iunlockput>
  end_op();
80104d80:	e8 a3 da ff ff       	call   80102828 <end_op>
  return 0;
80104d85:	83 c4 10             	add    $0x10,%esp
80104d88:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d8d:	c9                   	leave  
80104d8e:	c3                   	ret    
    end_op();
80104d8f:	e8 94 da ff ff       	call   80102828 <end_op>
    return -1;
80104d94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d99:	eb f2                	jmp    80104d8d <sys_mkdir+0x54>

80104d9b <sys_mknod>:

int
sys_mknod(void)
{
80104d9b:	55                   	push   %ebp
80104d9c:	89 e5                	mov    %esp,%ebp
80104d9e:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104da1:	e8 08 da ff ff       	call   801027ae <begin_op>
  if((argstr(0, &path)) < 0 ||
80104da6:	83 ec 08             	sub    $0x8,%esp
80104da9:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dac:	50                   	push   %eax
80104dad:	6a 00                	push   $0x0
80104daf:	e8 61 f6 ff ff       	call   80104415 <argstr>
80104db4:	83 c4 10             	add    $0x10,%esp
80104db7:	85 c0                	test   %eax,%eax
80104db9:	78 62                	js     80104e1d <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104dbb:	83 ec 08             	sub    $0x8,%esp
80104dbe:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104dc1:	50                   	push   %eax
80104dc2:	6a 01                	push   $0x1
80104dc4:	e8 bc f5 ff ff       	call   80104385 <argint>
  if((argstr(0, &path)) < 0 ||
80104dc9:	83 c4 10             	add    $0x10,%esp
80104dcc:	85 c0                	test   %eax,%eax
80104dce:	78 4d                	js     80104e1d <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104dd0:	83 ec 08             	sub    $0x8,%esp
80104dd3:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104dd6:	50                   	push   %eax
80104dd7:	6a 02                	push   $0x2
80104dd9:	e8 a7 f5 ff ff       	call   80104385 <argint>
     argint(1, &major) < 0 ||
80104dde:	83 c4 10             	add    $0x10,%esp
80104de1:	85 c0                	test   %eax,%eax
80104de3:	78 38                	js     80104e1d <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104de5:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104de9:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104ded:	83 ec 0c             	sub    $0xc,%esp
80104df0:	50                   	push   %eax
80104df1:	ba 03 00 00 00       	mov    $0x3,%edx
80104df6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104df9:	e8 94 f7 ff ff       	call   80104592 <create>
80104dfe:	83 c4 10             	add    $0x10,%esp
80104e01:	85 c0                	test   %eax,%eax
80104e03:	74 18                	je     80104e1d <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104e05:	83 ec 0c             	sub    $0xc,%esp
80104e08:	50                   	push   %eax
80104e09:	e8 1a c9 ff ff       	call   80101728 <iunlockput>
  end_op();
80104e0e:	e8 15 da ff ff       	call   80102828 <end_op>
  return 0;
80104e13:	83 c4 10             	add    $0x10,%esp
80104e16:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e1b:	c9                   	leave  
80104e1c:	c3                   	ret    
    end_op();
80104e1d:	e8 06 da ff ff       	call   80102828 <end_op>
    return -1;
80104e22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e27:	eb f2                	jmp    80104e1b <sys_mknod+0x80>

80104e29 <sys_chdir>:

int
sys_chdir(void)
{
80104e29:	55                   	push   %ebp
80104e2a:	89 e5                	mov    %esp,%ebp
80104e2c:	56                   	push   %esi
80104e2d:	53                   	push   %ebx
80104e2e:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104e31:	e8 fb e3 ff ff       	call   80103231 <myproc>
80104e36:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104e38:	e8 71 d9 ff ff       	call   801027ae <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104e3d:	83 ec 08             	sub    $0x8,%esp
80104e40:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e43:	50                   	push   %eax
80104e44:	6a 00                	push   $0x0
80104e46:	e8 ca f5 ff ff       	call   80104415 <argstr>
80104e4b:	83 c4 10             	add    $0x10,%esp
80104e4e:	85 c0                	test   %eax,%eax
80104e50:	78 52                	js     80104ea4 <sys_chdir+0x7b>
80104e52:	83 ec 0c             	sub    $0xc,%esp
80104e55:	ff 75 f4             	pushl  -0xc(%ebp)
80104e58:	e8 84 cd ff ff       	call   80101be1 <namei>
80104e5d:	89 c3                	mov    %eax,%ebx
80104e5f:	83 c4 10             	add    $0x10,%esp
80104e62:	85 c0                	test   %eax,%eax
80104e64:	74 3e                	je     80104ea4 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104e66:	83 ec 0c             	sub    $0xc,%esp
80104e69:	50                   	push   %eax
80104e6a:	e8 12 c7 ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104e6f:	83 c4 10             	add    $0x10,%esp
80104e72:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104e77:	75 37                	jne    80104eb0 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104e79:	83 ec 0c             	sub    $0xc,%esp
80104e7c:	53                   	push   %ebx
80104e7d:	e8 c1 c7 ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104e82:	83 c4 04             	add    $0x4,%esp
80104e85:	ff 76 68             	pushl  0x68(%esi)
80104e88:	e8 fb c7 ff ff       	call   80101688 <iput>
  end_op();
80104e8d:	e8 96 d9 ff ff       	call   80102828 <end_op>
  curproc->cwd = ip;
80104e92:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104e95:	83 c4 10             	add    $0x10,%esp
80104e98:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e9d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104ea0:	5b                   	pop    %ebx
80104ea1:	5e                   	pop    %esi
80104ea2:	5d                   	pop    %ebp
80104ea3:	c3                   	ret    
    end_op();
80104ea4:	e8 7f d9 ff ff       	call   80102828 <end_op>
    return -1;
80104ea9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eae:	eb ed                	jmp    80104e9d <sys_chdir+0x74>
    iunlockput(ip);
80104eb0:	83 ec 0c             	sub    $0xc,%esp
80104eb3:	53                   	push   %ebx
80104eb4:	e8 6f c8 ff ff       	call   80101728 <iunlockput>
    end_op();
80104eb9:	e8 6a d9 ff ff       	call   80102828 <end_op>
    return -1;
80104ebe:	83 c4 10             	add    $0x10,%esp
80104ec1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ec6:	eb d5                	jmp    80104e9d <sys_chdir+0x74>

80104ec8 <sys_exec>:

int
sys_exec(void)
{
80104ec8:	55                   	push   %ebp
80104ec9:	89 e5                	mov    %esp,%ebp
80104ecb:	53                   	push   %ebx
80104ecc:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104ed2:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ed5:	50                   	push   %eax
80104ed6:	6a 00                	push   $0x0
80104ed8:	e8 38 f5 ff ff       	call   80104415 <argstr>
80104edd:	83 c4 10             	add    $0x10,%esp
80104ee0:	85 c0                	test   %eax,%eax
80104ee2:	0f 88 a8 00 00 00    	js     80104f90 <sys_exec+0xc8>
80104ee8:	83 ec 08             	sub    $0x8,%esp
80104eeb:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104ef1:	50                   	push   %eax
80104ef2:	6a 01                	push   $0x1
80104ef4:	e8 8c f4 ff ff       	call   80104385 <argint>
80104ef9:	83 c4 10             	add    $0x10,%esp
80104efc:	85 c0                	test   %eax,%eax
80104efe:	0f 88 93 00 00 00    	js     80104f97 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104f04:	83 ec 04             	sub    $0x4,%esp
80104f07:	68 80 00 00 00       	push   $0x80
80104f0c:	6a 00                	push   $0x0
80104f0e:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104f14:	50                   	push   %eax
80104f15:	e8 20 f2 ff ff       	call   8010413a <memset>
80104f1a:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104f1d:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104f22:	83 fb 1f             	cmp    $0x1f,%ebx
80104f25:	77 77                	ja     80104f9e <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104f27:	83 ec 08             	sub    $0x8,%esp
80104f2a:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104f30:	50                   	push   %eax
80104f31:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104f37:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104f3a:	50                   	push   %eax
80104f3b:	e8 c9 f3 ff ff       	call   80104309 <fetchint>
80104f40:	83 c4 10             	add    $0x10,%esp
80104f43:	85 c0                	test   %eax,%eax
80104f45:	78 5e                	js     80104fa5 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104f47:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104f4d:	85 c0                	test   %eax,%eax
80104f4f:	74 1d                	je     80104f6e <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104f51:	83 ec 08             	sub    $0x8,%esp
80104f54:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104f5b:	52                   	push   %edx
80104f5c:	50                   	push   %eax
80104f5d:	e8 e3 f3 ff ff       	call   80104345 <fetchstr>
80104f62:	83 c4 10             	add    $0x10,%esp
80104f65:	85 c0                	test   %eax,%eax
80104f67:	78 46                	js     80104faf <sys_exec+0xe7>
  for(i=0;; i++){
80104f69:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104f6c:	eb b4                	jmp    80104f22 <sys_exec+0x5a>
      argv[i] = 0;
80104f6e:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104f75:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104f79:	83 ec 08             	sub    $0x8,%esp
80104f7c:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104f82:	50                   	push   %eax
80104f83:	ff 75 f4             	pushl  -0xc(%ebp)
80104f86:	e8 47 b9 ff ff       	call   801008d2 <exec>
80104f8b:	83 c4 10             	add    $0x10,%esp
80104f8e:	eb 1a                	jmp    80104faa <sys_exec+0xe2>
    return -1;
80104f90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f95:	eb 13                	jmp    80104faa <sys_exec+0xe2>
80104f97:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f9c:	eb 0c                	jmp    80104faa <sys_exec+0xe2>
      return -1;
80104f9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fa3:	eb 05                	jmp    80104faa <sys_exec+0xe2>
      return -1;
80104fa5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104faa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104fad:	c9                   	leave  
80104fae:	c3                   	ret    
      return -1;
80104faf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fb4:	eb f4                	jmp    80104faa <sys_exec+0xe2>

80104fb6 <sys_pipe>:

int
sys_pipe(void)
{
80104fb6:	55                   	push   %ebp
80104fb7:	89 e5                	mov    %esp,%ebp
80104fb9:	53                   	push   %ebx
80104fba:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104fbd:	6a 08                	push   $0x8
80104fbf:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104fc2:	50                   	push   %eax
80104fc3:	6a 00                	push   $0x0
80104fc5:	e8 e3 f3 ff ff       	call   801043ad <argptr>
80104fca:	83 c4 10             	add    $0x10,%esp
80104fcd:	85 c0                	test   %eax,%eax
80104fcf:	78 77                	js     80105048 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104fd1:	83 ec 08             	sub    $0x8,%esp
80104fd4:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104fd7:	50                   	push   %eax
80104fd8:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104fdb:	50                   	push   %eax
80104fdc:	e8 54 dd ff ff       	call   80102d35 <pipealloc>
80104fe1:	83 c4 10             	add    $0x10,%esp
80104fe4:	85 c0                	test   %eax,%eax
80104fe6:	78 67                	js     8010504f <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104fe8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104feb:	e8 14 f5 ff ff       	call   80104504 <fdalloc>
80104ff0:	89 c3                	mov    %eax,%ebx
80104ff2:	85 c0                	test   %eax,%eax
80104ff4:	78 21                	js     80105017 <sys_pipe+0x61>
80104ff6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104ff9:	e8 06 f5 ff ff       	call   80104504 <fdalloc>
80104ffe:	85 c0                	test   %eax,%eax
80105000:	78 15                	js     80105017 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80105002:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105005:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80105007:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010500a:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
8010500d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105012:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105015:	c9                   	leave  
80105016:	c3                   	ret    
    if(fd0 >= 0)
80105017:	85 db                	test   %ebx,%ebx
80105019:	78 0d                	js     80105028 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
8010501b:	e8 11 e2 ff ff       	call   80103231 <myproc>
80105020:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80105027:	00 
    fileclose(rf);
80105028:	83 ec 0c             	sub    $0xc,%esp
8010502b:	ff 75 f0             	pushl  -0x10(%ebp)
8010502e:	e8 a0 bc ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80105033:	83 c4 04             	add    $0x4,%esp
80105036:	ff 75 ec             	pushl  -0x14(%ebp)
80105039:	e8 95 bc ff ff       	call   80100cd3 <fileclose>
    return -1;
8010503e:	83 c4 10             	add    $0x10,%esp
80105041:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105046:	eb ca                	jmp    80105012 <sys_pipe+0x5c>
    return -1;
80105048:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010504d:	eb c3                	jmp    80105012 <sys_pipe+0x5c>
    return -1;
8010504f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105054:	eb bc                	jmp    80105012 <sys_pipe+0x5c>

80105056 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80105056:	55                   	push   %ebp
80105057:	89 e5                	mov    %esp,%ebp
80105059:	83 ec 08             	sub    $0x8,%esp
  return fork();
8010505c:	e8 cf ec ff ff       	call   80103d30 <fork>
}
80105061:	c9                   	leave  
80105062:	c3                   	ret    

80105063 <sys_exit>:

int
sys_exit(void)
{
80105063:	55                   	push   %ebp
80105064:	89 e5                	mov    %esp,%ebp
80105066:	83 ec 08             	sub    $0x8,%esp
  exit();
80105069:	e8 1e e6 ff ff       	call   8010368c <exit>
  return 0;  // not reached
}
8010506e:	b8 00 00 00 00       	mov    $0x0,%eax
80105073:	c9                   	leave  
80105074:	c3                   	ret    

80105075 <sys_wait>:

int
sys_wait(void)
{
80105075:	55                   	push   %ebp
80105076:	89 e5                	mov    %esp,%ebp
80105078:	83 ec 08             	sub    $0x8,%esp
  return wait();
8010507b:	e8 98 e7 ff ff       	call   80103818 <wait>
}
80105080:	c9                   	leave  
80105081:	c3                   	ret    

80105082 <sys_kill>:

int
sys_kill(void)
{
80105082:	55                   	push   %ebp
80105083:	89 e5                	mov    %esp,%ebp
80105085:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80105088:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010508b:	50                   	push   %eax
8010508c:	6a 00                	push   $0x0
8010508e:	e8 f2 f2 ff ff       	call   80104385 <argint>
80105093:	83 c4 10             	add    $0x10,%esp
80105096:	85 c0                	test   %eax,%eax
80105098:	78 10                	js     801050aa <sys_kill+0x28>
    return -1;
  return kill(pid);
8010509a:	83 ec 0c             	sub    $0xc,%esp
8010509d:	ff 75 f4             	pushl  -0xc(%ebp)
801050a0:	e8 73 e8 ff ff       	call   80103918 <kill>
801050a5:	83 c4 10             	add    $0x10,%esp
}
801050a8:	c9                   	leave  
801050a9:	c3                   	ret    
    return -1;
801050aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050af:	eb f7                	jmp    801050a8 <sys_kill+0x26>

801050b1 <sys_getpid>:

int
sys_getpid(void)
{
801050b1:	55                   	push   %ebp
801050b2:	89 e5                	mov    %esp,%ebp
801050b4:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
801050b7:	e8 75 e1 ff ff       	call   80103231 <myproc>
801050bc:	8b 40 10             	mov    0x10(%eax),%eax
}
801050bf:	c9                   	leave  
801050c0:	c3                   	ret    

801050c1 <sys_sbrk>:

int
sys_sbrk(void)
{
801050c1:	55                   	push   %ebp
801050c2:	89 e5                	mov    %esp,%ebp
801050c4:	53                   	push   %ebx
801050c5:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801050c8:	8d 45 f4             	lea    -0xc(%ebp),%eax
801050cb:	50                   	push   %eax
801050cc:	6a 00                	push   $0x0
801050ce:	e8 b2 f2 ff ff       	call   80104385 <argint>
801050d3:	83 c4 10             	add    $0x10,%esp
801050d6:	85 c0                	test   %eax,%eax
801050d8:	78 27                	js     80105101 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
801050da:	e8 52 e1 ff ff       	call   80103231 <myproc>
801050df:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
801050e1:	83 ec 0c             	sub    $0xc,%esp
801050e4:	ff 75 f4             	pushl  -0xc(%ebp)
801050e7:	e8 b7 e2 ff ff       	call   801033a3 <growproc>
801050ec:	83 c4 10             	add    $0x10,%esp
801050ef:	85 c0                	test   %eax,%eax
801050f1:	78 07                	js     801050fa <sys_sbrk+0x39>
    return -1;
  return addr;
}
801050f3:	89 d8                	mov    %ebx,%eax
801050f5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801050f8:	c9                   	leave  
801050f9:	c3                   	ret    
    return -1;
801050fa:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801050ff:	eb f2                	jmp    801050f3 <sys_sbrk+0x32>
    return -1;
80105101:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80105106:	eb eb                	jmp    801050f3 <sys_sbrk+0x32>

80105108 <sys_sleep>:

int
sys_sleep(void)
{
80105108:	55                   	push   %ebp
80105109:	89 e5                	mov    %esp,%ebp
8010510b:	53                   	push   %ebx
8010510c:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
8010510f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105112:	50                   	push   %eax
80105113:	6a 00                	push   $0x0
80105115:	e8 6b f2 ff ff       	call   80104385 <argint>
8010511a:	83 c4 10             	add    $0x10,%esp
8010511d:	85 c0                	test   %eax,%eax
8010511f:	78 75                	js     80105196 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80105121:	83 ec 0c             	sub    $0xc,%esp
80105124:	68 80 63 11 80       	push   $0x80116380
80105129:	e8 60 ef ff ff       	call   8010408e <acquire>
  ticks0 = ticks;
8010512e:	8b 1d c0 6b 11 80    	mov    0x80116bc0,%ebx
  while(ticks - ticks0 < n){
80105134:	83 c4 10             	add    $0x10,%esp
80105137:	a1 c0 6b 11 80       	mov    0x80116bc0,%eax
8010513c:	29 d8                	sub    %ebx,%eax
8010513e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80105141:	73 39                	jae    8010517c <sys_sleep+0x74>
    if(myproc()->killed){
80105143:	e8 e9 e0 ff ff       	call   80103231 <myproc>
80105148:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010514c:	75 17                	jne    80105165 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
8010514e:	83 ec 08             	sub    $0x8,%esp
80105151:	68 80 63 11 80       	push   $0x80116380
80105156:	68 c0 6b 11 80       	push   $0x80116bc0
8010515b:	e8 27 e6 ff ff       	call   80103787 <sleep>
80105160:	83 c4 10             	add    $0x10,%esp
80105163:	eb d2                	jmp    80105137 <sys_sleep+0x2f>
      release(&tickslock);
80105165:	83 ec 0c             	sub    $0xc,%esp
80105168:	68 80 63 11 80       	push   $0x80116380
8010516d:	e8 81 ef ff ff       	call   801040f3 <release>
      return -1;
80105172:	83 c4 10             	add    $0x10,%esp
80105175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010517a:	eb 15                	jmp    80105191 <sys_sleep+0x89>
  }
  release(&tickslock);
8010517c:	83 ec 0c             	sub    $0xc,%esp
8010517f:	68 80 63 11 80       	push   $0x80116380
80105184:	e8 6a ef ff ff       	call   801040f3 <release>
  return 0;
80105189:	83 c4 10             	add    $0x10,%esp
8010518c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105191:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105194:	c9                   	leave  
80105195:	c3                   	ret    
    return -1;
80105196:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010519b:	eb f4                	jmp    80105191 <sys_sleep+0x89>

8010519d <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
8010519d:	55                   	push   %ebp
8010519e:	89 e5                	mov    %esp,%ebp
801051a0:	53                   	push   %ebx
801051a1:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
801051a4:	68 80 63 11 80       	push   $0x80116380
801051a9:	e8 e0 ee ff ff       	call   8010408e <acquire>
  xticks = ticks;
801051ae:	8b 1d c0 6b 11 80    	mov    0x80116bc0,%ebx
  release(&tickslock);
801051b4:	c7 04 24 80 63 11 80 	movl   $0x80116380,(%esp)
801051bb:	e8 33 ef ff ff       	call   801040f3 <release>
  return xticks;
}
801051c0:	89 d8                	mov    %ebx,%eax
801051c2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801051c5:	c9                   	leave  
801051c6:	c3                   	ret    

801051c7 <sys_setpri>:


// This sets the priority of the specified PID to pri
// return -1 if pri or PID are invalid
int
sys_setpri(void){
801051c7:	55                   	push   %ebp
801051c8:	89 e5                	mov    %esp,%ebp
801051ca:	83 ec 20             	sub    $0x20,%esp
    int PID;
    int pri;

    if(argint(0, &PID) < 0 || argint(1, &pri) < 0){
801051cd:	8d 45 f4             	lea    -0xc(%ebp),%eax
801051d0:	50                   	push   %eax
801051d1:	6a 00                	push   $0x0
801051d3:	e8 ad f1 ff ff       	call   80104385 <argint>
801051d8:	83 c4 10             	add    $0x10,%esp
801051db:	85 c0                	test   %eax,%eax
801051dd:	78 28                	js     80105207 <sys_setpri+0x40>
801051df:	83 ec 08             	sub    $0x8,%esp
801051e2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801051e5:	50                   	push   %eax
801051e6:	6a 01                	push   $0x1
801051e8:	e8 98 f1 ff ff       	call   80104385 <argint>
801051ed:	83 c4 10             	add    $0x10,%esp
801051f0:	85 c0                	test   %eax,%eax
801051f2:	78 1a                	js     8010520e <sys_setpri+0x47>
        return -1;
    }

    int rc = setpri(PID, pri);
801051f4:	83 ec 08             	sub    $0x8,%esp
801051f7:	ff 75 f0             	pushl  -0x10(%ebp)
801051fa:	ff 75 f4             	pushl  -0xc(%ebp)
801051fd:	e8 41 e8 ff ff       	call   80103a43 <setpri>
    return rc;
80105202:	83 c4 10             	add    $0x10,%esp
}
80105205:	c9                   	leave  
80105206:	c3                   	ret    
        return -1;
80105207:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010520c:	eb f7                	jmp    80105205 <sys_setpri+0x3e>
8010520e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105213:	eb f0                	jmp    80105205 <sys_setpri+0x3e>

80105215 <sys_getpri>:

// returns the current priority of the specified PID.  If the PID is not valid, it returns -1
int
sys_getpri(void){
80105215:	55                   	push   %ebp
80105216:	89 e5                	mov    %esp,%ebp
80105218:	83 ec 20             	sub    $0x20,%esp
    int PID;

    if(argint(0, &PID) < 0){
8010521b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010521e:	50                   	push   %eax
8010521f:	6a 00                	push   $0x0
80105221:	e8 5f f1 ff ff       	call   80104385 <argint>
80105226:	83 c4 10             	add    $0x10,%esp
80105229:	85 c0                	test   %eax,%eax
8010522b:	78 10                	js     8010523d <sys_getpri+0x28>
        return -1;
    }

    int rc = getpri(PID);
8010522d:	83 ec 0c             	sub    $0xc,%esp
80105230:	ff 75 f4             	pushl  -0xc(%ebp)
80105233:	e8 14 e9 ff ff       	call   80103b4c <getpri>
    return rc;
80105238:	83 c4 10             	add    $0x10,%esp
}
8010523b:	c9                   	leave  
8010523c:	c3                   	ret    
        return -1;
8010523d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105242:	eb f7                	jmp    8010523b <sys_getpri+0x26>

80105244 <sys_fork2>:

//
int
sys_fork2(void){
80105244:	55                   	push   %ebp
80105245:	89 e5                	mov    %esp,%ebp
80105247:	83 ec 20             	sub    $0x20,%esp

    int pri;

    if(argint(0, &pri) < 0){
8010524a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010524d:	50                   	push   %eax
8010524e:	6a 00                	push   $0x0
80105250:	e8 30 f1 ff ff       	call   80104385 <argint>
80105255:	83 c4 10             	add    $0x10,%esp
80105258:	85 c0                	test   %eax,%eax
8010525a:	78 10                	js     8010526c <sys_fork2+0x28>
        return -1;
    }

    int rc = fork2(pri);
8010525c:	83 ec 0c             	sub    $0xc,%esp
8010525f:	ff 75 f4             	pushl  -0xc(%ebp)
80105262:	e8 48 e9 ff ff       	call   80103baf <fork2>
    return rc;
80105267:	83 c4 10             	add    $0x10,%esp
}
8010526a:	c9                   	leave  
8010526b:	c3                   	ret    
        return -1;
8010526c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105271:	eb f7                	jmp    8010526a <sys_fork2+0x26>

80105273 <sys_getpinfo>:

// returns 0 on success and -1 on failure
int
sys_getpinfo(void){
80105273:	55                   	push   %ebp
80105274:	89 e5                	mov    %esp,%ebp
80105276:	83 ec 1c             	sub    $0x1c,%esp

    struct pstat *ptr;

    if(argptr(0, (char**)&ptr, sizeof(ptr )) < 0){
80105279:	6a 04                	push   $0x4
8010527b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010527e:	50                   	push   %eax
8010527f:	6a 00                	push   $0x0
80105281:	e8 27 f1 ff ff       	call   801043ad <argptr>
80105286:	83 c4 10             	add    $0x10,%esp
80105289:	85 c0                	test   %eax,%eax
8010528b:	78 10                	js     8010529d <sys_getpinfo+0x2a>
        return -1;
    }

    int rc = getpinfo(ptr);
8010528d:	83 ec 0c             	sub    $0xc,%esp
80105290:	ff 75 f4             	pushl  -0xc(%ebp)
80105293:	e8 eb ea ff ff       	call   80103d83 <getpinfo>
    return rc;
80105298:	83 c4 10             	add    $0x10,%esp

}
8010529b:	c9                   	leave  
8010529c:	c3                   	ret    
        return -1;
8010529d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052a2:	eb f7                	jmp    8010529b <sys_getpinfo+0x28>

801052a4 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801052a4:	1e                   	push   %ds
  pushl %es
801052a5:	06                   	push   %es
  pushl %fs
801052a6:	0f a0                	push   %fs
  pushl %gs
801052a8:	0f a8                	push   %gs
  pushal
801052aa:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
801052ab:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801052af:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801052b1:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
801052b3:	54                   	push   %esp
  call trap
801052b4:	e8 e3 00 00 00       	call   8010539c <trap>
  addl $4, %esp
801052b9:	83 c4 04             	add    $0x4,%esp

801052bc <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801052bc:	61                   	popa   
  popl %gs
801052bd:	0f a9                	pop    %gs
  popl %fs
801052bf:	0f a1                	pop    %fs
  popl %es
801052c1:	07                   	pop    %es
  popl %ds
801052c2:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801052c3:	83 c4 08             	add    $0x8,%esp
  iret
801052c6:	cf                   	iret   

801052c7 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801052c7:	55                   	push   %ebp
801052c8:	89 e5                	mov    %esp,%ebp
801052ca:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
801052cd:	b8 00 00 00 00       	mov    $0x0,%eax
801052d2:	eb 4a                	jmp    8010531e <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801052d4:	8b 0c 85 18 a0 10 80 	mov    -0x7fef5fe8(,%eax,4),%ecx
801052db:	66 89 0c c5 c0 63 11 	mov    %cx,-0x7fee9c40(,%eax,8)
801052e2:	80 
801052e3:	66 c7 04 c5 c2 63 11 	movw   $0x8,-0x7fee9c3e(,%eax,8)
801052ea:	80 08 00 
801052ed:	c6 04 c5 c4 63 11 80 	movb   $0x0,-0x7fee9c3c(,%eax,8)
801052f4:	00 
801052f5:	0f b6 14 c5 c5 63 11 	movzbl -0x7fee9c3b(,%eax,8),%edx
801052fc:	80 
801052fd:	83 e2 f0             	and    $0xfffffff0,%edx
80105300:	83 ca 0e             	or     $0xe,%edx
80105303:	83 e2 8f             	and    $0xffffff8f,%edx
80105306:	83 ca 80             	or     $0xffffff80,%edx
80105309:	88 14 c5 c5 63 11 80 	mov    %dl,-0x7fee9c3b(,%eax,8)
80105310:	c1 e9 10             	shr    $0x10,%ecx
80105313:	66 89 0c c5 c6 63 11 	mov    %cx,-0x7fee9c3a(,%eax,8)
8010531a:	80 
  for(i = 0; i < 256; i++)
8010531b:	83 c0 01             	add    $0x1,%eax
8010531e:	3d ff 00 00 00       	cmp    $0xff,%eax
80105323:	7e af                	jle    801052d4 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80105325:	8b 15 18 a1 10 80    	mov    0x8010a118,%edx
8010532b:	66 89 15 c0 65 11 80 	mov    %dx,0x801165c0
80105332:	66 c7 05 c2 65 11 80 	movw   $0x8,0x801165c2
80105339:	08 00 
8010533b:	c6 05 c4 65 11 80 00 	movb   $0x0,0x801165c4
80105342:	0f b6 05 c5 65 11 80 	movzbl 0x801165c5,%eax
80105349:	83 c8 0f             	or     $0xf,%eax
8010534c:	83 e0 ef             	and    $0xffffffef,%eax
8010534f:	83 c8 e0             	or     $0xffffffe0,%eax
80105352:	a2 c5 65 11 80       	mov    %al,0x801165c5
80105357:	c1 ea 10             	shr    $0x10,%edx
8010535a:	66 89 15 c6 65 11 80 	mov    %dx,0x801165c6

  initlock(&tickslock, "time");
80105361:	83 ec 08             	sub    $0x8,%esp
80105364:	68 c9 71 10 80       	push   $0x801071c9
80105369:	68 80 63 11 80       	push   $0x80116380
8010536e:	e8 df eb ff ff       	call   80103f52 <initlock>
}
80105373:	83 c4 10             	add    $0x10,%esp
80105376:	c9                   	leave  
80105377:	c3                   	ret    

80105378 <idtinit>:

void
idtinit(void)
{
80105378:	55                   	push   %ebp
80105379:	89 e5                	mov    %esp,%ebp
8010537b:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
8010537e:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80105384:	b8 c0 63 11 80       	mov    $0x801163c0,%eax
80105389:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010538d:	c1 e8 10             	shr    $0x10,%eax
80105390:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80105394:	8d 45 fa             	lea    -0x6(%ebp),%eax
80105397:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
8010539a:	c9                   	leave  
8010539b:	c3                   	ret    

8010539c <trap>:

void
trap(struct trapframe *tf)
{
8010539c:	55                   	push   %ebp
8010539d:	89 e5                	mov    %esp,%ebp
8010539f:	57                   	push   %edi
801053a0:	56                   	push   %esi
801053a1:	53                   	push   %ebx
801053a2:	83 ec 1c             	sub    $0x1c,%esp
801053a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
801053a8:	8b 43 30             	mov    0x30(%ebx),%eax
801053ab:	83 f8 40             	cmp    $0x40,%eax
801053ae:	74 13                	je     801053c3 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
801053b0:	83 e8 20             	sub    $0x20,%eax
801053b3:	83 f8 1f             	cmp    $0x1f,%eax
801053b6:	0f 87 3a 01 00 00    	ja     801054f6 <trap+0x15a>
801053bc:	ff 24 85 70 72 10 80 	jmp    *-0x7fef8d90(,%eax,4)
    if(myproc()->killed)
801053c3:	e8 69 de ff ff       	call   80103231 <myproc>
801053c8:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801053cc:	75 1f                	jne    801053ed <trap+0x51>
    myproc()->tf = tf;
801053ce:	e8 5e de ff ff       	call   80103231 <myproc>
801053d3:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
801053d6:	e8 6d f0 ff ff       	call   80104448 <syscall>
    if(myproc()->killed)
801053db:	e8 51 de ff ff       	call   80103231 <myproc>
801053e0:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801053e4:	74 7e                	je     80105464 <trap+0xc8>
      exit();
801053e6:	e8 a1 e2 ff ff       	call   8010368c <exit>
801053eb:	eb 77                	jmp    80105464 <trap+0xc8>
      exit();
801053ed:	e8 9a e2 ff ff       	call   8010368c <exit>
801053f2:	eb da                	jmp    801053ce <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
801053f4:	e8 1d de ff ff       	call   80103216 <cpuid>
801053f9:	85 c0                	test   %eax,%eax
801053fb:	74 6f                	je     8010546c <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
801053fd:	e8 97 cf ff ff       	call   80102399 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105402:	e8 2a de ff ff       	call   80103231 <myproc>
80105407:	85 c0                	test   %eax,%eax
80105409:	74 1c                	je     80105427 <trap+0x8b>
8010540b:	e8 21 de ff ff       	call   80103231 <myproc>
80105410:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105414:	74 11                	je     80105427 <trap+0x8b>
80105416:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
8010541a:	83 e0 03             	and    $0x3,%eax
8010541d:	66 83 f8 03          	cmp    $0x3,%ax
80105421:	0f 84 62 01 00 00    	je     80105589 <trap+0x1ed>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.

  // TODO: MIGHT NEED TO ADD MORE CONDITIONS TO IF STATEMENT
  if(myproc() && myproc()->state == RUNNING &&
80105427:	e8 05 de ff ff       	call   80103231 <myproc>
8010542c:	85 c0                	test   %eax,%eax
8010542e:	74 0f                	je     8010543f <trap+0xa3>
80105430:	e8 fc dd ff ff       	call   80103231 <myproc>
80105435:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105439:	0f 84 54 01 00 00    	je     80105593 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010543f:	e8 ed dd ff ff       	call   80103231 <myproc>
80105444:	85 c0                	test   %eax,%eax
80105446:	74 1c                	je     80105464 <trap+0xc8>
80105448:	e8 e4 dd ff ff       	call   80103231 <myproc>
8010544d:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105451:	74 11                	je     80105464 <trap+0xc8>
80105453:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105457:	83 e0 03             	and    $0x3,%eax
8010545a:	66 83 f8 03          	cmp    $0x3,%ax
8010545e:	0f 84 43 01 00 00    	je     801055a7 <trap+0x20b>
    exit();
}
80105464:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105467:	5b                   	pop    %ebx
80105468:	5e                   	pop    %esi
80105469:	5f                   	pop    %edi
8010546a:	5d                   	pop    %ebp
8010546b:	c3                   	ret    
      acquire(&tickslock);
8010546c:	83 ec 0c             	sub    $0xc,%esp
8010546f:	68 80 63 11 80       	push   $0x80116380
80105474:	e8 15 ec ff ff       	call   8010408e <acquire>
      ticks++;
80105479:	83 05 c0 6b 11 80 01 	addl   $0x1,0x80116bc0
      wakeup(&ticks);
80105480:	c7 04 24 c0 6b 11 80 	movl   $0x80116bc0,(%esp)
80105487:	e8 63 e4 ff ff       	call   801038ef <wakeup>
      release(&tickslock);
8010548c:	c7 04 24 80 63 11 80 	movl   $0x80116380,(%esp)
80105493:	e8 5b ec ff ff       	call   801040f3 <release>
80105498:	83 c4 10             	add    $0x10,%esp
8010549b:	e9 5d ff ff ff       	jmp    801053fd <trap+0x61>
    ideintr();
801054a0:	e8 ce c8 ff ff       	call   80101d73 <ideintr>
    lapiceoi();
801054a5:	e8 ef ce ff ff       	call   80102399 <lapiceoi>
    break;
801054aa:	e9 53 ff ff ff       	jmp    80105402 <trap+0x66>
    kbdintr();
801054af:	e8 29 cd ff ff       	call   801021dd <kbdintr>
    lapiceoi();
801054b4:	e8 e0 ce ff ff       	call   80102399 <lapiceoi>
    break;
801054b9:	e9 44 ff ff ff       	jmp    80105402 <trap+0x66>
    uartintr();
801054be:	e8 05 02 00 00       	call   801056c8 <uartintr>
    lapiceoi();
801054c3:	e8 d1 ce ff ff       	call   80102399 <lapiceoi>
    break;
801054c8:	e9 35 ff ff ff       	jmp    80105402 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801054cd:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801054d0:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801054d4:	e8 3d dd ff ff       	call   80103216 <cpuid>
801054d9:	57                   	push   %edi
801054da:	0f b7 f6             	movzwl %si,%esi
801054dd:	56                   	push   %esi
801054de:	50                   	push   %eax
801054df:	68 d4 71 10 80       	push   $0x801071d4
801054e4:	e8 22 b1 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801054e9:	e8 ab ce ff ff       	call   80102399 <lapiceoi>
    break;
801054ee:	83 c4 10             	add    $0x10,%esp
801054f1:	e9 0c ff ff ff       	jmp    80105402 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
801054f6:	e8 36 dd ff ff       	call   80103231 <myproc>
801054fb:	85 c0                	test   %eax,%eax
801054fd:	74 5f                	je     8010555e <trap+0x1c2>
801054ff:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105503:	74 59                	je     8010555e <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105505:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105508:	8b 43 38             	mov    0x38(%ebx),%eax
8010550b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010550e:	e8 03 dd ff ff       	call   80103216 <cpuid>
80105513:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105516:	8b 53 34             	mov    0x34(%ebx),%edx
80105519:	89 55 dc             	mov    %edx,-0x24(%ebp)
8010551c:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
8010551f:	e8 0d dd ff ff       	call   80103231 <myproc>
80105524:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105527:	89 4d d8             	mov    %ecx,-0x28(%ebp)
8010552a:	e8 02 dd ff ff       	call   80103231 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010552f:	57                   	push   %edi
80105530:	ff 75 e4             	pushl  -0x1c(%ebp)
80105533:	ff 75 e0             	pushl  -0x20(%ebp)
80105536:	ff 75 dc             	pushl  -0x24(%ebp)
80105539:	56                   	push   %esi
8010553a:	ff 75 d8             	pushl  -0x28(%ebp)
8010553d:	ff 70 10             	pushl  0x10(%eax)
80105540:	68 2c 72 10 80       	push   $0x8010722c
80105545:	e8 c1 b0 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
8010554a:	83 c4 20             	add    $0x20,%esp
8010554d:	e8 df dc ff ff       	call   80103231 <myproc>
80105552:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80105559:	e9 a4 fe ff ff       	jmp    80105402 <trap+0x66>
8010555e:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80105561:	8b 73 38             	mov    0x38(%ebx),%esi
80105564:	e8 ad dc ff ff       	call   80103216 <cpuid>
80105569:	83 ec 0c             	sub    $0xc,%esp
8010556c:	57                   	push   %edi
8010556d:	56                   	push   %esi
8010556e:	50                   	push   %eax
8010556f:	ff 73 30             	pushl  0x30(%ebx)
80105572:	68 f8 71 10 80       	push   $0x801071f8
80105577:	e8 8f b0 ff ff       	call   8010060b <cprintf>
      panic("trap");
8010557c:	83 c4 14             	add    $0x14,%esp
8010557f:	68 ce 71 10 80       	push   $0x801071ce
80105584:	e8 bf ad ff ff       	call   80100348 <panic>
    exit();
80105589:	e8 fe e0 ff ff       	call   8010368c <exit>
8010558e:	e9 94 fe ff ff       	jmp    80105427 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
80105593:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80105597:	0f 85 a2 fe ff ff    	jne    8010543f <trap+0xa3>
    yield();
8010559d:	e8 b3 e1 ff ff       	call   80103755 <yield>
801055a2:	e9 98 fe ff ff       	jmp    8010543f <trap+0xa3>
    exit();
801055a7:	e8 e0 e0 ff ff       	call   8010368c <exit>
801055ac:	e9 b3 fe ff ff       	jmp    80105464 <trap+0xc8>

801055b1 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801055b1:	55                   	push   %ebp
801055b2:	89 e5                	mov    %esp,%ebp
  if(!uart)
801055b4:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
801055bb:	74 15                	je     801055d2 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801055bd:	ba fd 03 00 00       	mov    $0x3fd,%edx
801055c2:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801055c3:	a8 01                	test   $0x1,%al
801055c5:	74 12                	je     801055d9 <uartgetc+0x28>
801055c7:	ba f8 03 00 00       	mov    $0x3f8,%edx
801055cc:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801055cd:	0f b6 c0             	movzbl %al,%eax
}
801055d0:	5d                   	pop    %ebp
801055d1:	c3                   	ret    
    return -1;
801055d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055d7:	eb f7                	jmp    801055d0 <uartgetc+0x1f>
    return -1;
801055d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055de:	eb f0                	jmp    801055d0 <uartgetc+0x1f>

801055e0 <uartputc>:
  if(!uart)
801055e0:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
801055e7:	74 3b                	je     80105624 <uartputc+0x44>
{
801055e9:	55                   	push   %ebp
801055ea:	89 e5                	mov    %esp,%ebp
801055ec:	53                   	push   %ebx
801055ed:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801055f0:	bb 00 00 00 00       	mov    $0x0,%ebx
801055f5:	eb 10                	jmp    80105607 <uartputc+0x27>
    microdelay(10);
801055f7:	83 ec 0c             	sub    $0xc,%esp
801055fa:	6a 0a                	push   $0xa
801055fc:	e8 b7 cd ff ff       	call   801023b8 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105601:	83 c3 01             	add    $0x1,%ebx
80105604:	83 c4 10             	add    $0x10,%esp
80105607:	83 fb 7f             	cmp    $0x7f,%ebx
8010560a:	7f 0a                	jg     80105616 <uartputc+0x36>
8010560c:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105611:	ec                   	in     (%dx),%al
80105612:	a8 20                	test   $0x20,%al
80105614:	74 e1                	je     801055f7 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105616:	8b 45 08             	mov    0x8(%ebp),%eax
80105619:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010561e:	ee                   	out    %al,(%dx)
}
8010561f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105622:	c9                   	leave  
80105623:	c3                   	ret    
80105624:	f3 c3                	repz ret 

80105626 <uartinit>:
{
80105626:	55                   	push   %ebp
80105627:	89 e5                	mov    %esp,%ebp
80105629:	56                   	push   %esi
8010562a:	53                   	push   %ebx
8010562b:	b9 00 00 00 00       	mov    $0x0,%ecx
80105630:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105635:	89 c8                	mov    %ecx,%eax
80105637:	ee                   	out    %al,(%dx)
80105638:	be fb 03 00 00       	mov    $0x3fb,%esi
8010563d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80105642:	89 f2                	mov    %esi,%edx
80105644:	ee                   	out    %al,(%dx)
80105645:	b8 0c 00 00 00       	mov    $0xc,%eax
8010564a:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010564f:	ee                   	out    %al,(%dx)
80105650:	bb f9 03 00 00       	mov    $0x3f9,%ebx
80105655:	89 c8                	mov    %ecx,%eax
80105657:	89 da                	mov    %ebx,%edx
80105659:	ee                   	out    %al,(%dx)
8010565a:	b8 03 00 00 00       	mov    $0x3,%eax
8010565f:	89 f2                	mov    %esi,%edx
80105661:	ee                   	out    %al,(%dx)
80105662:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105667:	89 c8                	mov    %ecx,%eax
80105669:	ee                   	out    %al,(%dx)
8010566a:	b8 01 00 00 00       	mov    $0x1,%eax
8010566f:	89 da                	mov    %ebx,%edx
80105671:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105672:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105677:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105678:	3c ff                	cmp    $0xff,%al
8010567a:	74 45                	je     801056c1 <uartinit+0x9b>
  uart = 1;
8010567c:	c7 05 bc a5 10 80 01 	movl   $0x1,0x8010a5bc
80105683:	00 00 00 
80105686:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010568b:	ec                   	in     (%dx),%al
8010568c:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105691:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
80105692:	83 ec 08             	sub    $0x8,%esp
80105695:	6a 00                	push   $0x0
80105697:	6a 04                	push   $0x4
80105699:	e8 e0 c8 ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
8010569e:	83 c4 10             	add    $0x10,%esp
801056a1:	bb f0 72 10 80       	mov    $0x801072f0,%ebx
801056a6:	eb 12                	jmp    801056ba <uartinit+0x94>
    uartputc(*p);
801056a8:	83 ec 0c             	sub    $0xc,%esp
801056ab:	0f be c0             	movsbl %al,%eax
801056ae:	50                   	push   %eax
801056af:	e8 2c ff ff ff       	call   801055e0 <uartputc>
  for(p="xv6...\n"; *p; p++)
801056b4:	83 c3 01             	add    $0x1,%ebx
801056b7:	83 c4 10             	add    $0x10,%esp
801056ba:	0f b6 03             	movzbl (%ebx),%eax
801056bd:	84 c0                	test   %al,%al
801056bf:	75 e7                	jne    801056a8 <uartinit+0x82>
}
801056c1:	8d 65 f8             	lea    -0x8(%ebp),%esp
801056c4:	5b                   	pop    %ebx
801056c5:	5e                   	pop    %esi
801056c6:	5d                   	pop    %ebp
801056c7:	c3                   	ret    

801056c8 <uartintr>:

void
uartintr(void)
{
801056c8:	55                   	push   %ebp
801056c9:	89 e5                	mov    %esp,%ebp
801056cb:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801056ce:	68 b1 55 10 80       	push   $0x801055b1
801056d3:	e8 66 b0 ff ff       	call   8010073e <consoleintr>
}
801056d8:	83 c4 10             	add    $0x10,%esp
801056db:	c9                   	leave  
801056dc:	c3                   	ret    

801056dd <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801056dd:	6a 00                	push   $0x0
  pushl $0
801056df:	6a 00                	push   $0x0
  jmp alltraps
801056e1:	e9 be fb ff ff       	jmp    801052a4 <alltraps>

801056e6 <vector1>:
.globl vector1
vector1:
  pushl $0
801056e6:	6a 00                	push   $0x0
  pushl $1
801056e8:	6a 01                	push   $0x1
  jmp alltraps
801056ea:	e9 b5 fb ff ff       	jmp    801052a4 <alltraps>

801056ef <vector2>:
.globl vector2
vector2:
  pushl $0
801056ef:	6a 00                	push   $0x0
  pushl $2
801056f1:	6a 02                	push   $0x2
  jmp alltraps
801056f3:	e9 ac fb ff ff       	jmp    801052a4 <alltraps>

801056f8 <vector3>:
.globl vector3
vector3:
  pushl $0
801056f8:	6a 00                	push   $0x0
  pushl $3
801056fa:	6a 03                	push   $0x3
  jmp alltraps
801056fc:	e9 a3 fb ff ff       	jmp    801052a4 <alltraps>

80105701 <vector4>:
.globl vector4
vector4:
  pushl $0
80105701:	6a 00                	push   $0x0
  pushl $4
80105703:	6a 04                	push   $0x4
  jmp alltraps
80105705:	e9 9a fb ff ff       	jmp    801052a4 <alltraps>

8010570a <vector5>:
.globl vector5
vector5:
  pushl $0
8010570a:	6a 00                	push   $0x0
  pushl $5
8010570c:	6a 05                	push   $0x5
  jmp alltraps
8010570e:	e9 91 fb ff ff       	jmp    801052a4 <alltraps>

80105713 <vector6>:
.globl vector6
vector6:
  pushl $0
80105713:	6a 00                	push   $0x0
  pushl $6
80105715:	6a 06                	push   $0x6
  jmp alltraps
80105717:	e9 88 fb ff ff       	jmp    801052a4 <alltraps>

8010571c <vector7>:
.globl vector7
vector7:
  pushl $0
8010571c:	6a 00                	push   $0x0
  pushl $7
8010571e:	6a 07                	push   $0x7
  jmp alltraps
80105720:	e9 7f fb ff ff       	jmp    801052a4 <alltraps>

80105725 <vector8>:
.globl vector8
vector8:
  pushl $8
80105725:	6a 08                	push   $0x8
  jmp alltraps
80105727:	e9 78 fb ff ff       	jmp    801052a4 <alltraps>

8010572c <vector9>:
.globl vector9
vector9:
  pushl $0
8010572c:	6a 00                	push   $0x0
  pushl $9
8010572e:	6a 09                	push   $0x9
  jmp alltraps
80105730:	e9 6f fb ff ff       	jmp    801052a4 <alltraps>

80105735 <vector10>:
.globl vector10
vector10:
  pushl $10
80105735:	6a 0a                	push   $0xa
  jmp alltraps
80105737:	e9 68 fb ff ff       	jmp    801052a4 <alltraps>

8010573c <vector11>:
.globl vector11
vector11:
  pushl $11
8010573c:	6a 0b                	push   $0xb
  jmp alltraps
8010573e:	e9 61 fb ff ff       	jmp    801052a4 <alltraps>

80105743 <vector12>:
.globl vector12
vector12:
  pushl $12
80105743:	6a 0c                	push   $0xc
  jmp alltraps
80105745:	e9 5a fb ff ff       	jmp    801052a4 <alltraps>

8010574a <vector13>:
.globl vector13
vector13:
  pushl $13
8010574a:	6a 0d                	push   $0xd
  jmp alltraps
8010574c:	e9 53 fb ff ff       	jmp    801052a4 <alltraps>

80105751 <vector14>:
.globl vector14
vector14:
  pushl $14
80105751:	6a 0e                	push   $0xe
  jmp alltraps
80105753:	e9 4c fb ff ff       	jmp    801052a4 <alltraps>

80105758 <vector15>:
.globl vector15
vector15:
  pushl $0
80105758:	6a 00                	push   $0x0
  pushl $15
8010575a:	6a 0f                	push   $0xf
  jmp alltraps
8010575c:	e9 43 fb ff ff       	jmp    801052a4 <alltraps>

80105761 <vector16>:
.globl vector16
vector16:
  pushl $0
80105761:	6a 00                	push   $0x0
  pushl $16
80105763:	6a 10                	push   $0x10
  jmp alltraps
80105765:	e9 3a fb ff ff       	jmp    801052a4 <alltraps>

8010576a <vector17>:
.globl vector17
vector17:
  pushl $17
8010576a:	6a 11                	push   $0x11
  jmp alltraps
8010576c:	e9 33 fb ff ff       	jmp    801052a4 <alltraps>

80105771 <vector18>:
.globl vector18
vector18:
  pushl $0
80105771:	6a 00                	push   $0x0
  pushl $18
80105773:	6a 12                	push   $0x12
  jmp alltraps
80105775:	e9 2a fb ff ff       	jmp    801052a4 <alltraps>

8010577a <vector19>:
.globl vector19
vector19:
  pushl $0
8010577a:	6a 00                	push   $0x0
  pushl $19
8010577c:	6a 13                	push   $0x13
  jmp alltraps
8010577e:	e9 21 fb ff ff       	jmp    801052a4 <alltraps>

80105783 <vector20>:
.globl vector20
vector20:
  pushl $0
80105783:	6a 00                	push   $0x0
  pushl $20
80105785:	6a 14                	push   $0x14
  jmp alltraps
80105787:	e9 18 fb ff ff       	jmp    801052a4 <alltraps>

8010578c <vector21>:
.globl vector21
vector21:
  pushl $0
8010578c:	6a 00                	push   $0x0
  pushl $21
8010578e:	6a 15                	push   $0x15
  jmp alltraps
80105790:	e9 0f fb ff ff       	jmp    801052a4 <alltraps>

80105795 <vector22>:
.globl vector22
vector22:
  pushl $0
80105795:	6a 00                	push   $0x0
  pushl $22
80105797:	6a 16                	push   $0x16
  jmp alltraps
80105799:	e9 06 fb ff ff       	jmp    801052a4 <alltraps>

8010579e <vector23>:
.globl vector23
vector23:
  pushl $0
8010579e:	6a 00                	push   $0x0
  pushl $23
801057a0:	6a 17                	push   $0x17
  jmp alltraps
801057a2:	e9 fd fa ff ff       	jmp    801052a4 <alltraps>

801057a7 <vector24>:
.globl vector24
vector24:
  pushl $0
801057a7:	6a 00                	push   $0x0
  pushl $24
801057a9:	6a 18                	push   $0x18
  jmp alltraps
801057ab:	e9 f4 fa ff ff       	jmp    801052a4 <alltraps>

801057b0 <vector25>:
.globl vector25
vector25:
  pushl $0
801057b0:	6a 00                	push   $0x0
  pushl $25
801057b2:	6a 19                	push   $0x19
  jmp alltraps
801057b4:	e9 eb fa ff ff       	jmp    801052a4 <alltraps>

801057b9 <vector26>:
.globl vector26
vector26:
  pushl $0
801057b9:	6a 00                	push   $0x0
  pushl $26
801057bb:	6a 1a                	push   $0x1a
  jmp alltraps
801057bd:	e9 e2 fa ff ff       	jmp    801052a4 <alltraps>

801057c2 <vector27>:
.globl vector27
vector27:
  pushl $0
801057c2:	6a 00                	push   $0x0
  pushl $27
801057c4:	6a 1b                	push   $0x1b
  jmp alltraps
801057c6:	e9 d9 fa ff ff       	jmp    801052a4 <alltraps>

801057cb <vector28>:
.globl vector28
vector28:
  pushl $0
801057cb:	6a 00                	push   $0x0
  pushl $28
801057cd:	6a 1c                	push   $0x1c
  jmp alltraps
801057cf:	e9 d0 fa ff ff       	jmp    801052a4 <alltraps>

801057d4 <vector29>:
.globl vector29
vector29:
  pushl $0
801057d4:	6a 00                	push   $0x0
  pushl $29
801057d6:	6a 1d                	push   $0x1d
  jmp alltraps
801057d8:	e9 c7 fa ff ff       	jmp    801052a4 <alltraps>

801057dd <vector30>:
.globl vector30
vector30:
  pushl $0
801057dd:	6a 00                	push   $0x0
  pushl $30
801057df:	6a 1e                	push   $0x1e
  jmp alltraps
801057e1:	e9 be fa ff ff       	jmp    801052a4 <alltraps>

801057e6 <vector31>:
.globl vector31
vector31:
  pushl $0
801057e6:	6a 00                	push   $0x0
  pushl $31
801057e8:	6a 1f                	push   $0x1f
  jmp alltraps
801057ea:	e9 b5 fa ff ff       	jmp    801052a4 <alltraps>

801057ef <vector32>:
.globl vector32
vector32:
  pushl $0
801057ef:	6a 00                	push   $0x0
  pushl $32
801057f1:	6a 20                	push   $0x20
  jmp alltraps
801057f3:	e9 ac fa ff ff       	jmp    801052a4 <alltraps>

801057f8 <vector33>:
.globl vector33
vector33:
  pushl $0
801057f8:	6a 00                	push   $0x0
  pushl $33
801057fa:	6a 21                	push   $0x21
  jmp alltraps
801057fc:	e9 a3 fa ff ff       	jmp    801052a4 <alltraps>

80105801 <vector34>:
.globl vector34
vector34:
  pushl $0
80105801:	6a 00                	push   $0x0
  pushl $34
80105803:	6a 22                	push   $0x22
  jmp alltraps
80105805:	e9 9a fa ff ff       	jmp    801052a4 <alltraps>

8010580a <vector35>:
.globl vector35
vector35:
  pushl $0
8010580a:	6a 00                	push   $0x0
  pushl $35
8010580c:	6a 23                	push   $0x23
  jmp alltraps
8010580e:	e9 91 fa ff ff       	jmp    801052a4 <alltraps>

80105813 <vector36>:
.globl vector36
vector36:
  pushl $0
80105813:	6a 00                	push   $0x0
  pushl $36
80105815:	6a 24                	push   $0x24
  jmp alltraps
80105817:	e9 88 fa ff ff       	jmp    801052a4 <alltraps>

8010581c <vector37>:
.globl vector37
vector37:
  pushl $0
8010581c:	6a 00                	push   $0x0
  pushl $37
8010581e:	6a 25                	push   $0x25
  jmp alltraps
80105820:	e9 7f fa ff ff       	jmp    801052a4 <alltraps>

80105825 <vector38>:
.globl vector38
vector38:
  pushl $0
80105825:	6a 00                	push   $0x0
  pushl $38
80105827:	6a 26                	push   $0x26
  jmp alltraps
80105829:	e9 76 fa ff ff       	jmp    801052a4 <alltraps>

8010582e <vector39>:
.globl vector39
vector39:
  pushl $0
8010582e:	6a 00                	push   $0x0
  pushl $39
80105830:	6a 27                	push   $0x27
  jmp alltraps
80105832:	e9 6d fa ff ff       	jmp    801052a4 <alltraps>

80105837 <vector40>:
.globl vector40
vector40:
  pushl $0
80105837:	6a 00                	push   $0x0
  pushl $40
80105839:	6a 28                	push   $0x28
  jmp alltraps
8010583b:	e9 64 fa ff ff       	jmp    801052a4 <alltraps>

80105840 <vector41>:
.globl vector41
vector41:
  pushl $0
80105840:	6a 00                	push   $0x0
  pushl $41
80105842:	6a 29                	push   $0x29
  jmp alltraps
80105844:	e9 5b fa ff ff       	jmp    801052a4 <alltraps>

80105849 <vector42>:
.globl vector42
vector42:
  pushl $0
80105849:	6a 00                	push   $0x0
  pushl $42
8010584b:	6a 2a                	push   $0x2a
  jmp alltraps
8010584d:	e9 52 fa ff ff       	jmp    801052a4 <alltraps>

80105852 <vector43>:
.globl vector43
vector43:
  pushl $0
80105852:	6a 00                	push   $0x0
  pushl $43
80105854:	6a 2b                	push   $0x2b
  jmp alltraps
80105856:	e9 49 fa ff ff       	jmp    801052a4 <alltraps>

8010585b <vector44>:
.globl vector44
vector44:
  pushl $0
8010585b:	6a 00                	push   $0x0
  pushl $44
8010585d:	6a 2c                	push   $0x2c
  jmp alltraps
8010585f:	e9 40 fa ff ff       	jmp    801052a4 <alltraps>

80105864 <vector45>:
.globl vector45
vector45:
  pushl $0
80105864:	6a 00                	push   $0x0
  pushl $45
80105866:	6a 2d                	push   $0x2d
  jmp alltraps
80105868:	e9 37 fa ff ff       	jmp    801052a4 <alltraps>

8010586d <vector46>:
.globl vector46
vector46:
  pushl $0
8010586d:	6a 00                	push   $0x0
  pushl $46
8010586f:	6a 2e                	push   $0x2e
  jmp alltraps
80105871:	e9 2e fa ff ff       	jmp    801052a4 <alltraps>

80105876 <vector47>:
.globl vector47
vector47:
  pushl $0
80105876:	6a 00                	push   $0x0
  pushl $47
80105878:	6a 2f                	push   $0x2f
  jmp alltraps
8010587a:	e9 25 fa ff ff       	jmp    801052a4 <alltraps>

8010587f <vector48>:
.globl vector48
vector48:
  pushl $0
8010587f:	6a 00                	push   $0x0
  pushl $48
80105881:	6a 30                	push   $0x30
  jmp alltraps
80105883:	e9 1c fa ff ff       	jmp    801052a4 <alltraps>

80105888 <vector49>:
.globl vector49
vector49:
  pushl $0
80105888:	6a 00                	push   $0x0
  pushl $49
8010588a:	6a 31                	push   $0x31
  jmp alltraps
8010588c:	e9 13 fa ff ff       	jmp    801052a4 <alltraps>

80105891 <vector50>:
.globl vector50
vector50:
  pushl $0
80105891:	6a 00                	push   $0x0
  pushl $50
80105893:	6a 32                	push   $0x32
  jmp alltraps
80105895:	e9 0a fa ff ff       	jmp    801052a4 <alltraps>

8010589a <vector51>:
.globl vector51
vector51:
  pushl $0
8010589a:	6a 00                	push   $0x0
  pushl $51
8010589c:	6a 33                	push   $0x33
  jmp alltraps
8010589e:	e9 01 fa ff ff       	jmp    801052a4 <alltraps>

801058a3 <vector52>:
.globl vector52
vector52:
  pushl $0
801058a3:	6a 00                	push   $0x0
  pushl $52
801058a5:	6a 34                	push   $0x34
  jmp alltraps
801058a7:	e9 f8 f9 ff ff       	jmp    801052a4 <alltraps>

801058ac <vector53>:
.globl vector53
vector53:
  pushl $0
801058ac:	6a 00                	push   $0x0
  pushl $53
801058ae:	6a 35                	push   $0x35
  jmp alltraps
801058b0:	e9 ef f9 ff ff       	jmp    801052a4 <alltraps>

801058b5 <vector54>:
.globl vector54
vector54:
  pushl $0
801058b5:	6a 00                	push   $0x0
  pushl $54
801058b7:	6a 36                	push   $0x36
  jmp alltraps
801058b9:	e9 e6 f9 ff ff       	jmp    801052a4 <alltraps>

801058be <vector55>:
.globl vector55
vector55:
  pushl $0
801058be:	6a 00                	push   $0x0
  pushl $55
801058c0:	6a 37                	push   $0x37
  jmp alltraps
801058c2:	e9 dd f9 ff ff       	jmp    801052a4 <alltraps>

801058c7 <vector56>:
.globl vector56
vector56:
  pushl $0
801058c7:	6a 00                	push   $0x0
  pushl $56
801058c9:	6a 38                	push   $0x38
  jmp alltraps
801058cb:	e9 d4 f9 ff ff       	jmp    801052a4 <alltraps>

801058d0 <vector57>:
.globl vector57
vector57:
  pushl $0
801058d0:	6a 00                	push   $0x0
  pushl $57
801058d2:	6a 39                	push   $0x39
  jmp alltraps
801058d4:	e9 cb f9 ff ff       	jmp    801052a4 <alltraps>

801058d9 <vector58>:
.globl vector58
vector58:
  pushl $0
801058d9:	6a 00                	push   $0x0
  pushl $58
801058db:	6a 3a                	push   $0x3a
  jmp alltraps
801058dd:	e9 c2 f9 ff ff       	jmp    801052a4 <alltraps>

801058e2 <vector59>:
.globl vector59
vector59:
  pushl $0
801058e2:	6a 00                	push   $0x0
  pushl $59
801058e4:	6a 3b                	push   $0x3b
  jmp alltraps
801058e6:	e9 b9 f9 ff ff       	jmp    801052a4 <alltraps>

801058eb <vector60>:
.globl vector60
vector60:
  pushl $0
801058eb:	6a 00                	push   $0x0
  pushl $60
801058ed:	6a 3c                	push   $0x3c
  jmp alltraps
801058ef:	e9 b0 f9 ff ff       	jmp    801052a4 <alltraps>

801058f4 <vector61>:
.globl vector61
vector61:
  pushl $0
801058f4:	6a 00                	push   $0x0
  pushl $61
801058f6:	6a 3d                	push   $0x3d
  jmp alltraps
801058f8:	e9 a7 f9 ff ff       	jmp    801052a4 <alltraps>

801058fd <vector62>:
.globl vector62
vector62:
  pushl $0
801058fd:	6a 00                	push   $0x0
  pushl $62
801058ff:	6a 3e                	push   $0x3e
  jmp alltraps
80105901:	e9 9e f9 ff ff       	jmp    801052a4 <alltraps>

80105906 <vector63>:
.globl vector63
vector63:
  pushl $0
80105906:	6a 00                	push   $0x0
  pushl $63
80105908:	6a 3f                	push   $0x3f
  jmp alltraps
8010590a:	e9 95 f9 ff ff       	jmp    801052a4 <alltraps>

8010590f <vector64>:
.globl vector64
vector64:
  pushl $0
8010590f:	6a 00                	push   $0x0
  pushl $64
80105911:	6a 40                	push   $0x40
  jmp alltraps
80105913:	e9 8c f9 ff ff       	jmp    801052a4 <alltraps>

80105918 <vector65>:
.globl vector65
vector65:
  pushl $0
80105918:	6a 00                	push   $0x0
  pushl $65
8010591a:	6a 41                	push   $0x41
  jmp alltraps
8010591c:	e9 83 f9 ff ff       	jmp    801052a4 <alltraps>

80105921 <vector66>:
.globl vector66
vector66:
  pushl $0
80105921:	6a 00                	push   $0x0
  pushl $66
80105923:	6a 42                	push   $0x42
  jmp alltraps
80105925:	e9 7a f9 ff ff       	jmp    801052a4 <alltraps>

8010592a <vector67>:
.globl vector67
vector67:
  pushl $0
8010592a:	6a 00                	push   $0x0
  pushl $67
8010592c:	6a 43                	push   $0x43
  jmp alltraps
8010592e:	e9 71 f9 ff ff       	jmp    801052a4 <alltraps>

80105933 <vector68>:
.globl vector68
vector68:
  pushl $0
80105933:	6a 00                	push   $0x0
  pushl $68
80105935:	6a 44                	push   $0x44
  jmp alltraps
80105937:	e9 68 f9 ff ff       	jmp    801052a4 <alltraps>

8010593c <vector69>:
.globl vector69
vector69:
  pushl $0
8010593c:	6a 00                	push   $0x0
  pushl $69
8010593e:	6a 45                	push   $0x45
  jmp alltraps
80105940:	e9 5f f9 ff ff       	jmp    801052a4 <alltraps>

80105945 <vector70>:
.globl vector70
vector70:
  pushl $0
80105945:	6a 00                	push   $0x0
  pushl $70
80105947:	6a 46                	push   $0x46
  jmp alltraps
80105949:	e9 56 f9 ff ff       	jmp    801052a4 <alltraps>

8010594e <vector71>:
.globl vector71
vector71:
  pushl $0
8010594e:	6a 00                	push   $0x0
  pushl $71
80105950:	6a 47                	push   $0x47
  jmp alltraps
80105952:	e9 4d f9 ff ff       	jmp    801052a4 <alltraps>

80105957 <vector72>:
.globl vector72
vector72:
  pushl $0
80105957:	6a 00                	push   $0x0
  pushl $72
80105959:	6a 48                	push   $0x48
  jmp alltraps
8010595b:	e9 44 f9 ff ff       	jmp    801052a4 <alltraps>

80105960 <vector73>:
.globl vector73
vector73:
  pushl $0
80105960:	6a 00                	push   $0x0
  pushl $73
80105962:	6a 49                	push   $0x49
  jmp alltraps
80105964:	e9 3b f9 ff ff       	jmp    801052a4 <alltraps>

80105969 <vector74>:
.globl vector74
vector74:
  pushl $0
80105969:	6a 00                	push   $0x0
  pushl $74
8010596b:	6a 4a                	push   $0x4a
  jmp alltraps
8010596d:	e9 32 f9 ff ff       	jmp    801052a4 <alltraps>

80105972 <vector75>:
.globl vector75
vector75:
  pushl $0
80105972:	6a 00                	push   $0x0
  pushl $75
80105974:	6a 4b                	push   $0x4b
  jmp alltraps
80105976:	e9 29 f9 ff ff       	jmp    801052a4 <alltraps>

8010597b <vector76>:
.globl vector76
vector76:
  pushl $0
8010597b:	6a 00                	push   $0x0
  pushl $76
8010597d:	6a 4c                	push   $0x4c
  jmp alltraps
8010597f:	e9 20 f9 ff ff       	jmp    801052a4 <alltraps>

80105984 <vector77>:
.globl vector77
vector77:
  pushl $0
80105984:	6a 00                	push   $0x0
  pushl $77
80105986:	6a 4d                	push   $0x4d
  jmp alltraps
80105988:	e9 17 f9 ff ff       	jmp    801052a4 <alltraps>

8010598d <vector78>:
.globl vector78
vector78:
  pushl $0
8010598d:	6a 00                	push   $0x0
  pushl $78
8010598f:	6a 4e                	push   $0x4e
  jmp alltraps
80105991:	e9 0e f9 ff ff       	jmp    801052a4 <alltraps>

80105996 <vector79>:
.globl vector79
vector79:
  pushl $0
80105996:	6a 00                	push   $0x0
  pushl $79
80105998:	6a 4f                	push   $0x4f
  jmp alltraps
8010599a:	e9 05 f9 ff ff       	jmp    801052a4 <alltraps>

8010599f <vector80>:
.globl vector80
vector80:
  pushl $0
8010599f:	6a 00                	push   $0x0
  pushl $80
801059a1:	6a 50                	push   $0x50
  jmp alltraps
801059a3:	e9 fc f8 ff ff       	jmp    801052a4 <alltraps>

801059a8 <vector81>:
.globl vector81
vector81:
  pushl $0
801059a8:	6a 00                	push   $0x0
  pushl $81
801059aa:	6a 51                	push   $0x51
  jmp alltraps
801059ac:	e9 f3 f8 ff ff       	jmp    801052a4 <alltraps>

801059b1 <vector82>:
.globl vector82
vector82:
  pushl $0
801059b1:	6a 00                	push   $0x0
  pushl $82
801059b3:	6a 52                	push   $0x52
  jmp alltraps
801059b5:	e9 ea f8 ff ff       	jmp    801052a4 <alltraps>

801059ba <vector83>:
.globl vector83
vector83:
  pushl $0
801059ba:	6a 00                	push   $0x0
  pushl $83
801059bc:	6a 53                	push   $0x53
  jmp alltraps
801059be:	e9 e1 f8 ff ff       	jmp    801052a4 <alltraps>

801059c3 <vector84>:
.globl vector84
vector84:
  pushl $0
801059c3:	6a 00                	push   $0x0
  pushl $84
801059c5:	6a 54                	push   $0x54
  jmp alltraps
801059c7:	e9 d8 f8 ff ff       	jmp    801052a4 <alltraps>

801059cc <vector85>:
.globl vector85
vector85:
  pushl $0
801059cc:	6a 00                	push   $0x0
  pushl $85
801059ce:	6a 55                	push   $0x55
  jmp alltraps
801059d0:	e9 cf f8 ff ff       	jmp    801052a4 <alltraps>

801059d5 <vector86>:
.globl vector86
vector86:
  pushl $0
801059d5:	6a 00                	push   $0x0
  pushl $86
801059d7:	6a 56                	push   $0x56
  jmp alltraps
801059d9:	e9 c6 f8 ff ff       	jmp    801052a4 <alltraps>

801059de <vector87>:
.globl vector87
vector87:
  pushl $0
801059de:	6a 00                	push   $0x0
  pushl $87
801059e0:	6a 57                	push   $0x57
  jmp alltraps
801059e2:	e9 bd f8 ff ff       	jmp    801052a4 <alltraps>

801059e7 <vector88>:
.globl vector88
vector88:
  pushl $0
801059e7:	6a 00                	push   $0x0
  pushl $88
801059e9:	6a 58                	push   $0x58
  jmp alltraps
801059eb:	e9 b4 f8 ff ff       	jmp    801052a4 <alltraps>

801059f0 <vector89>:
.globl vector89
vector89:
  pushl $0
801059f0:	6a 00                	push   $0x0
  pushl $89
801059f2:	6a 59                	push   $0x59
  jmp alltraps
801059f4:	e9 ab f8 ff ff       	jmp    801052a4 <alltraps>

801059f9 <vector90>:
.globl vector90
vector90:
  pushl $0
801059f9:	6a 00                	push   $0x0
  pushl $90
801059fb:	6a 5a                	push   $0x5a
  jmp alltraps
801059fd:	e9 a2 f8 ff ff       	jmp    801052a4 <alltraps>

80105a02 <vector91>:
.globl vector91
vector91:
  pushl $0
80105a02:	6a 00                	push   $0x0
  pushl $91
80105a04:	6a 5b                	push   $0x5b
  jmp alltraps
80105a06:	e9 99 f8 ff ff       	jmp    801052a4 <alltraps>

80105a0b <vector92>:
.globl vector92
vector92:
  pushl $0
80105a0b:	6a 00                	push   $0x0
  pushl $92
80105a0d:	6a 5c                	push   $0x5c
  jmp alltraps
80105a0f:	e9 90 f8 ff ff       	jmp    801052a4 <alltraps>

80105a14 <vector93>:
.globl vector93
vector93:
  pushl $0
80105a14:	6a 00                	push   $0x0
  pushl $93
80105a16:	6a 5d                	push   $0x5d
  jmp alltraps
80105a18:	e9 87 f8 ff ff       	jmp    801052a4 <alltraps>

80105a1d <vector94>:
.globl vector94
vector94:
  pushl $0
80105a1d:	6a 00                	push   $0x0
  pushl $94
80105a1f:	6a 5e                	push   $0x5e
  jmp alltraps
80105a21:	e9 7e f8 ff ff       	jmp    801052a4 <alltraps>

80105a26 <vector95>:
.globl vector95
vector95:
  pushl $0
80105a26:	6a 00                	push   $0x0
  pushl $95
80105a28:	6a 5f                	push   $0x5f
  jmp alltraps
80105a2a:	e9 75 f8 ff ff       	jmp    801052a4 <alltraps>

80105a2f <vector96>:
.globl vector96
vector96:
  pushl $0
80105a2f:	6a 00                	push   $0x0
  pushl $96
80105a31:	6a 60                	push   $0x60
  jmp alltraps
80105a33:	e9 6c f8 ff ff       	jmp    801052a4 <alltraps>

80105a38 <vector97>:
.globl vector97
vector97:
  pushl $0
80105a38:	6a 00                	push   $0x0
  pushl $97
80105a3a:	6a 61                	push   $0x61
  jmp alltraps
80105a3c:	e9 63 f8 ff ff       	jmp    801052a4 <alltraps>

80105a41 <vector98>:
.globl vector98
vector98:
  pushl $0
80105a41:	6a 00                	push   $0x0
  pushl $98
80105a43:	6a 62                	push   $0x62
  jmp alltraps
80105a45:	e9 5a f8 ff ff       	jmp    801052a4 <alltraps>

80105a4a <vector99>:
.globl vector99
vector99:
  pushl $0
80105a4a:	6a 00                	push   $0x0
  pushl $99
80105a4c:	6a 63                	push   $0x63
  jmp alltraps
80105a4e:	e9 51 f8 ff ff       	jmp    801052a4 <alltraps>

80105a53 <vector100>:
.globl vector100
vector100:
  pushl $0
80105a53:	6a 00                	push   $0x0
  pushl $100
80105a55:	6a 64                	push   $0x64
  jmp alltraps
80105a57:	e9 48 f8 ff ff       	jmp    801052a4 <alltraps>

80105a5c <vector101>:
.globl vector101
vector101:
  pushl $0
80105a5c:	6a 00                	push   $0x0
  pushl $101
80105a5e:	6a 65                	push   $0x65
  jmp alltraps
80105a60:	e9 3f f8 ff ff       	jmp    801052a4 <alltraps>

80105a65 <vector102>:
.globl vector102
vector102:
  pushl $0
80105a65:	6a 00                	push   $0x0
  pushl $102
80105a67:	6a 66                	push   $0x66
  jmp alltraps
80105a69:	e9 36 f8 ff ff       	jmp    801052a4 <alltraps>

80105a6e <vector103>:
.globl vector103
vector103:
  pushl $0
80105a6e:	6a 00                	push   $0x0
  pushl $103
80105a70:	6a 67                	push   $0x67
  jmp alltraps
80105a72:	e9 2d f8 ff ff       	jmp    801052a4 <alltraps>

80105a77 <vector104>:
.globl vector104
vector104:
  pushl $0
80105a77:	6a 00                	push   $0x0
  pushl $104
80105a79:	6a 68                	push   $0x68
  jmp alltraps
80105a7b:	e9 24 f8 ff ff       	jmp    801052a4 <alltraps>

80105a80 <vector105>:
.globl vector105
vector105:
  pushl $0
80105a80:	6a 00                	push   $0x0
  pushl $105
80105a82:	6a 69                	push   $0x69
  jmp alltraps
80105a84:	e9 1b f8 ff ff       	jmp    801052a4 <alltraps>

80105a89 <vector106>:
.globl vector106
vector106:
  pushl $0
80105a89:	6a 00                	push   $0x0
  pushl $106
80105a8b:	6a 6a                	push   $0x6a
  jmp alltraps
80105a8d:	e9 12 f8 ff ff       	jmp    801052a4 <alltraps>

80105a92 <vector107>:
.globl vector107
vector107:
  pushl $0
80105a92:	6a 00                	push   $0x0
  pushl $107
80105a94:	6a 6b                	push   $0x6b
  jmp alltraps
80105a96:	e9 09 f8 ff ff       	jmp    801052a4 <alltraps>

80105a9b <vector108>:
.globl vector108
vector108:
  pushl $0
80105a9b:	6a 00                	push   $0x0
  pushl $108
80105a9d:	6a 6c                	push   $0x6c
  jmp alltraps
80105a9f:	e9 00 f8 ff ff       	jmp    801052a4 <alltraps>

80105aa4 <vector109>:
.globl vector109
vector109:
  pushl $0
80105aa4:	6a 00                	push   $0x0
  pushl $109
80105aa6:	6a 6d                	push   $0x6d
  jmp alltraps
80105aa8:	e9 f7 f7 ff ff       	jmp    801052a4 <alltraps>

80105aad <vector110>:
.globl vector110
vector110:
  pushl $0
80105aad:	6a 00                	push   $0x0
  pushl $110
80105aaf:	6a 6e                	push   $0x6e
  jmp alltraps
80105ab1:	e9 ee f7 ff ff       	jmp    801052a4 <alltraps>

80105ab6 <vector111>:
.globl vector111
vector111:
  pushl $0
80105ab6:	6a 00                	push   $0x0
  pushl $111
80105ab8:	6a 6f                	push   $0x6f
  jmp alltraps
80105aba:	e9 e5 f7 ff ff       	jmp    801052a4 <alltraps>

80105abf <vector112>:
.globl vector112
vector112:
  pushl $0
80105abf:	6a 00                	push   $0x0
  pushl $112
80105ac1:	6a 70                	push   $0x70
  jmp alltraps
80105ac3:	e9 dc f7 ff ff       	jmp    801052a4 <alltraps>

80105ac8 <vector113>:
.globl vector113
vector113:
  pushl $0
80105ac8:	6a 00                	push   $0x0
  pushl $113
80105aca:	6a 71                	push   $0x71
  jmp alltraps
80105acc:	e9 d3 f7 ff ff       	jmp    801052a4 <alltraps>

80105ad1 <vector114>:
.globl vector114
vector114:
  pushl $0
80105ad1:	6a 00                	push   $0x0
  pushl $114
80105ad3:	6a 72                	push   $0x72
  jmp alltraps
80105ad5:	e9 ca f7 ff ff       	jmp    801052a4 <alltraps>

80105ada <vector115>:
.globl vector115
vector115:
  pushl $0
80105ada:	6a 00                	push   $0x0
  pushl $115
80105adc:	6a 73                	push   $0x73
  jmp alltraps
80105ade:	e9 c1 f7 ff ff       	jmp    801052a4 <alltraps>

80105ae3 <vector116>:
.globl vector116
vector116:
  pushl $0
80105ae3:	6a 00                	push   $0x0
  pushl $116
80105ae5:	6a 74                	push   $0x74
  jmp alltraps
80105ae7:	e9 b8 f7 ff ff       	jmp    801052a4 <alltraps>

80105aec <vector117>:
.globl vector117
vector117:
  pushl $0
80105aec:	6a 00                	push   $0x0
  pushl $117
80105aee:	6a 75                	push   $0x75
  jmp alltraps
80105af0:	e9 af f7 ff ff       	jmp    801052a4 <alltraps>

80105af5 <vector118>:
.globl vector118
vector118:
  pushl $0
80105af5:	6a 00                	push   $0x0
  pushl $118
80105af7:	6a 76                	push   $0x76
  jmp alltraps
80105af9:	e9 a6 f7 ff ff       	jmp    801052a4 <alltraps>

80105afe <vector119>:
.globl vector119
vector119:
  pushl $0
80105afe:	6a 00                	push   $0x0
  pushl $119
80105b00:	6a 77                	push   $0x77
  jmp alltraps
80105b02:	e9 9d f7 ff ff       	jmp    801052a4 <alltraps>

80105b07 <vector120>:
.globl vector120
vector120:
  pushl $0
80105b07:	6a 00                	push   $0x0
  pushl $120
80105b09:	6a 78                	push   $0x78
  jmp alltraps
80105b0b:	e9 94 f7 ff ff       	jmp    801052a4 <alltraps>

80105b10 <vector121>:
.globl vector121
vector121:
  pushl $0
80105b10:	6a 00                	push   $0x0
  pushl $121
80105b12:	6a 79                	push   $0x79
  jmp alltraps
80105b14:	e9 8b f7 ff ff       	jmp    801052a4 <alltraps>

80105b19 <vector122>:
.globl vector122
vector122:
  pushl $0
80105b19:	6a 00                	push   $0x0
  pushl $122
80105b1b:	6a 7a                	push   $0x7a
  jmp alltraps
80105b1d:	e9 82 f7 ff ff       	jmp    801052a4 <alltraps>

80105b22 <vector123>:
.globl vector123
vector123:
  pushl $0
80105b22:	6a 00                	push   $0x0
  pushl $123
80105b24:	6a 7b                	push   $0x7b
  jmp alltraps
80105b26:	e9 79 f7 ff ff       	jmp    801052a4 <alltraps>

80105b2b <vector124>:
.globl vector124
vector124:
  pushl $0
80105b2b:	6a 00                	push   $0x0
  pushl $124
80105b2d:	6a 7c                	push   $0x7c
  jmp alltraps
80105b2f:	e9 70 f7 ff ff       	jmp    801052a4 <alltraps>

80105b34 <vector125>:
.globl vector125
vector125:
  pushl $0
80105b34:	6a 00                	push   $0x0
  pushl $125
80105b36:	6a 7d                	push   $0x7d
  jmp alltraps
80105b38:	e9 67 f7 ff ff       	jmp    801052a4 <alltraps>

80105b3d <vector126>:
.globl vector126
vector126:
  pushl $0
80105b3d:	6a 00                	push   $0x0
  pushl $126
80105b3f:	6a 7e                	push   $0x7e
  jmp alltraps
80105b41:	e9 5e f7 ff ff       	jmp    801052a4 <alltraps>

80105b46 <vector127>:
.globl vector127
vector127:
  pushl $0
80105b46:	6a 00                	push   $0x0
  pushl $127
80105b48:	6a 7f                	push   $0x7f
  jmp alltraps
80105b4a:	e9 55 f7 ff ff       	jmp    801052a4 <alltraps>

80105b4f <vector128>:
.globl vector128
vector128:
  pushl $0
80105b4f:	6a 00                	push   $0x0
  pushl $128
80105b51:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105b56:	e9 49 f7 ff ff       	jmp    801052a4 <alltraps>

80105b5b <vector129>:
.globl vector129
vector129:
  pushl $0
80105b5b:	6a 00                	push   $0x0
  pushl $129
80105b5d:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80105b62:	e9 3d f7 ff ff       	jmp    801052a4 <alltraps>

80105b67 <vector130>:
.globl vector130
vector130:
  pushl $0
80105b67:	6a 00                	push   $0x0
  pushl $130
80105b69:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105b6e:	e9 31 f7 ff ff       	jmp    801052a4 <alltraps>

80105b73 <vector131>:
.globl vector131
vector131:
  pushl $0
80105b73:	6a 00                	push   $0x0
  pushl $131
80105b75:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105b7a:	e9 25 f7 ff ff       	jmp    801052a4 <alltraps>

80105b7f <vector132>:
.globl vector132
vector132:
  pushl $0
80105b7f:	6a 00                	push   $0x0
  pushl $132
80105b81:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105b86:	e9 19 f7 ff ff       	jmp    801052a4 <alltraps>

80105b8b <vector133>:
.globl vector133
vector133:
  pushl $0
80105b8b:	6a 00                	push   $0x0
  pushl $133
80105b8d:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105b92:	e9 0d f7 ff ff       	jmp    801052a4 <alltraps>

80105b97 <vector134>:
.globl vector134
vector134:
  pushl $0
80105b97:	6a 00                	push   $0x0
  pushl $134
80105b99:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105b9e:	e9 01 f7 ff ff       	jmp    801052a4 <alltraps>

80105ba3 <vector135>:
.globl vector135
vector135:
  pushl $0
80105ba3:	6a 00                	push   $0x0
  pushl $135
80105ba5:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105baa:	e9 f5 f6 ff ff       	jmp    801052a4 <alltraps>

80105baf <vector136>:
.globl vector136
vector136:
  pushl $0
80105baf:	6a 00                	push   $0x0
  pushl $136
80105bb1:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105bb6:	e9 e9 f6 ff ff       	jmp    801052a4 <alltraps>

80105bbb <vector137>:
.globl vector137
vector137:
  pushl $0
80105bbb:	6a 00                	push   $0x0
  pushl $137
80105bbd:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105bc2:	e9 dd f6 ff ff       	jmp    801052a4 <alltraps>

80105bc7 <vector138>:
.globl vector138
vector138:
  pushl $0
80105bc7:	6a 00                	push   $0x0
  pushl $138
80105bc9:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105bce:	e9 d1 f6 ff ff       	jmp    801052a4 <alltraps>

80105bd3 <vector139>:
.globl vector139
vector139:
  pushl $0
80105bd3:	6a 00                	push   $0x0
  pushl $139
80105bd5:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105bda:	e9 c5 f6 ff ff       	jmp    801052a4 <alltraps>

80105bdf <vector140>:
.globl vector140
vector140:
  pushl $0
80105bdf:	6a 00                	push   $0x0
  pushl $140
80105be1:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105be6:	e9 b9 f6 ff ff       	jmp    801052a4 <alltraps>

80105beb <vector141>:
.globl vector141
vector141:
  pushl $0
80105beb:	6a 00                	push   $0x0
  pushl $141
80105bed:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105bf2:	e9 ad f6 ff ff       	jmp    801052a4 <alltraps>

80105bf7 <vector142>:
.globl vector142
vector142:
  pushl $0
80105bf7:	6a 00                	push   $0x0
  pushl $142
80105bf9:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105bfe:	e9 a1 f6 ff ff       	jmp    801052a4 <alltraps>

80105c03 <vector143>:
.globl vector143
vector143:
  pushl $0
80105c03:	6a 00                	push   $0x0
  pushl $143
80105c05:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105c0a:	e9 95 f6 ff ff       	jmp    801052a4 <alltraps>

80105c0f <vector144>:
.globl vector144
vector144:
  pushl $0
80105c0f:	6a 00                	push   $0x0
  pushl $144
80105c11:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105c16:	e9 89 f6 ff ff       	jmp    801052a4 <alltraps>

80105c1b <vector145>:
.globl vector145
vector145:
  pushl $0
80105c1b:	6a 00                	push   $0x0
  pushl $145
80105c1d:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105c22:	e9 7d f6 ff ff       	jmp    801052a4 <alltraps>

80105c27 <vector146>:
.globl vector146
vector146:
  pushl $0
80105c27:	6a 00                	push   $0x0
  pushl $146
80105c29:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105c2e:	e9 71 f6 ff ff       	jmp    801052a4 <alltraps>

80105c33 <vector147>:
.globl vector147
vector147:
  pushl $0
80105c33:	6a 00                	push   $0x0
  pushl $147
80105c35:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105c3a:	e9 65 f6 ff ff       	jmp    801052a4 <alltraps>

80105c3f <vector148>:
.globl vector148
vector148:
  pushl $0
80105c3f:	6a 00                	push   $0x0
  pushl $148
80105c41:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105c46:	e9 59 f6 ff ff       	jmp    801052a4 <alltraps>

80105c4b <vector149>:
.globl vector149
vector149:
  pushl $0
80105c4b:	6a 00                	push   $0x0
  pushl $149
80105c4d:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105c52:	e9 4d f6 ff ff       	jmp    801052a4 <alltraps>

80105c57 <vector150>:
.globl vector150
vector150:
  pushl $0
80105c57:	6a 00                	push   $0x0
  pushl $150
80105c59:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105c5e:	e9 41 f6 ff ff       	jmp    801052a4 <alltraps>

80105c63 <vector151>:
.globl vector151
vector151:
  pushl $0
80105c63:	6a 00                	push   $0x0
  pushl $151
80105c65:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105c6a:	e9 35 f6 ff ff       	jmp    801052a4 <alltraps>

80105c6f <vector152>:
.globl vector152
vector152:
  pushl $0
80105c6f:	6a 00                	push   $0x0
  pushl $152
80105c71:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105c76:	e9 29 f6 ff ff       	jmp    801052a4 <alltraps>

80105c7b <vector153>:
.globl vector153
vector153:
  pushl $0
80105c7b:	6a 00                	push   $0x0
  pushl $153
80105c7d:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105c82:	e9 1d f6 ff ff       	jmp    801052a4 <alltraps>

80105c87 <vector154>:
.globl vector154
vector154:
  pushl $0
80105c87:	6a 00                	push   $0x0
  pushl $154
80105c89:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105c8e:	e9 11 f6 ff ff       	jmp    801052a4 <alltraps>

80105c93 <vector155>:
.globl vector155
vector155:
  pushl $0
80105c93:	6a 00                	push   $0x0
  pushl $155
80105c95:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105c9a:	e9 05 f6 ff ff       	jmp    801052a4 <alltraps>

80105c9f <vector156>:
.globl vector156
vector156:
  pushl $0
80105c9f:	6a 00                	push   $0x0
  pushl $156
80105ca1:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105ca6:	e9 f9 f5 ff ff       	jmp    801052a4 <alltraps>

80105cab <vector157>:
.globl vector157
vector157:
  pushl $0
80105cab:	6a 00                	push   $0x0
  pushl $157
80105cad:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105cb2:	e9 ed f5 ff ff       	jmp    801052a4 <alltraps>

80105cb7 <vector158>:
.globl vector158
vector158:
  pushl $0
80105cb7:	6a 00                	push   $0x0
  pushl $158
80105cb9:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105cbe:	e9 e1 f5 ff ff       	jmp    801052a4 <alltraps>

80105cc3 <vector159>:
.globl vector159
vector159:
  pushl $0
80105cc3:	6a 00                	push   $0x0
  pushl $159
80105cc5:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105cca:	e9 d5 f5 ff ff       	jmp    801052a4 <alltraps>

80105ccf <vector160>:
.globl vector160
vector160:
  pushl $0
80105ccf:	6a 00                	push   $0x0
  pushl $160
80105cd1:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105cd6:	e9 c9 f5 ff ff       	jmp    801052a4 <alltraps>

80105cdb <vector161>:
.globl vector161
vector161:
  pushl $0
80105cdb:	6a 00                	push   $0x0
  pushl $161
80105cdd:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105ce2:	e9 bd f5 ff ff       	jmp    801052a4 <alltraps>

80105ce7 <vector162>:
.globl vector162
vector162:
  pushl $0
80105ce7:	6a 00                	push   $0x0
  pushl $162
80105ce9:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105cee:	e9 b1 f5 ff ff       	jmp    801052a4 <alltraps>

80105cf3 <vector163>:
.globl vector163
vector163:
  pushl $0
80105cf3:	6a 00                	push   $0x0
  pushl $163
80105cf5:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105cfa:	e9 a5 f5 ff ff       	jmp    801052a4 <alltraps>

80105cff <vector164>:
.globl vector164
vector164:
  pushl $0
80105cff:	6a 00                	push   $0x0
  pushl $164
80105d01:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105d06:	e9 99 f5 ff ff       	jmp    801052a4 <alltraps>

80105d0b <vector165>:
.globl vector165
vector165:
  pushl $0
80105d0b:	6a 00                	push   $0x0
  pushl $165
80105d0d:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105d12:	e9 8d f5 ff ff       	jmp    801052a4 <alltraps>

80105d17 <vector166>:
.globl vector166
vector166:
  pushl $0
80105d17:	6a 00                	push   $0x0
  pushl $166
80105d19:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105d1e:	e9 81 f5 ff ff       	jmp    801052a4 <alltraps>

80105d23 <vector167>:
.globl vector167
vector167:
  pushl $0
80105d23:	6a 00                	push   $0x0
  pushl $167
80105d25:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105d2a:	e9 75 f5 ff ff       	jmp    801052a4 <alltraps>

80105d2f <vector168>:
.globl vector168
vector168:
  pushl $0
80105d2f:	6a 00                	push   $0x0
  pushl $168
80105d31:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105d36:	e9 69 f5 ff ff       	jmp    801052a4 <alltraps>

80105d3b <vector169>:
.globl vector169
vector169:
  pushl $0
80105d3b:	6a 00                	push   $0x0
  pushl $169
80105d3d:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105d42:	e9 5d f5 ff ff       	jmp    801052a4 <alltraps>

80105d47 <vector170>:
.globl vector170
vector170:
  pushl $0
80105d47:	6a 00                	push   $0x0
  pushl $170
80105d49:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105d4e:	e9 51 f5 ff ff       	jmp    801052a4 <alltraps>

80105d53 <vector171>:
.globl vector171
vector171:
  pushl $0
80105d53:	6a 00                	push   $0x0
  pushl $171
80105d55:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105d5a:	e9 45 f5 ff ff       	jmp    801052a4 <alltraps>

80105d5f <vector172>:
.globl vector172
vector172:
  pushl $0
80105d5f:	6a 00                	push   $0x0
  pushl $172
80105d61:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105d66:	e9 39 f5 ff ff       	jmp    801052a4 <alltraps>

80105d6b <vector173>:
.globl vector173
vector173:
  pushl $0
80105d6b:	6a 00                	push   $0x0
  pushl $173
80105d6d:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105d72:	e9 2d f5 ff ff       	jmp    801052a4 <alltraps>

80105d77 <vector174>:
.globl vector174
vector174:
  pushl $0
80105d77:	6a 00                	push   $0x0
  pushl $174
80105d79:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105d7e:	e9 21 f5 ff ff       	jmp    801052a4 <alltraps>

80105d83 <vector175>:
.globl vector175
vector175:
  pushl $0
80105d83:	6a 00                	push   $0x0
  pushl $175
80105d85:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105d8a:	e9 15 f5 ff ff       	jmp    801052a4 <alltraps>

80105d8f <vector176>:
.globl vector176
vector176:
  pushl $0
80105d8f:	6a 00                	push   $0x0
  pushl $176
80105d91:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105d96:	e9 09 f5 ff ff       	jmp    801052a4 <alltraps>

80105d9b <vector177>:
.globl vector177
vector177:
  pushl $0
80105d9b:	6a 00                	push   $0x0
  pushl $177
80105d9d:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105da2:	e9 fd f4 ff ff       	jmp    801052a4 <alltraps>

80105da7 <vector178>:
.globl vector178
vector178:
  pushl $0
80105da7:	6a 00                	push   $0x0
  pushl $178
80105da9:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105dae:	e9 f1 f4 ff ff       	jmp    801052a4 <alltraps>

80105db3 <vector179>:
.globl vector179
vector179:
  pushl $0
80105db3:	6a 00                	push   $0x0
  pushl $179
80105db5:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105dba:	e9 e5 f4 ff ff       	jmp    801052a4 <alltraps>

80105dbf <vector180>:
.globl vector180
vector180:
  pushl $0
80105dbf:	6a 00                	push   $0x0
  pushl $180
80105dc1:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105dc6:	e9 d9 f4 ff ff       	jmp    801052a4 <alltraps>

80105dcb <vector181>:
.globl vector181
vector181:
  pushl $0
80105dcb:	6a 00                	push   $0x0
  pushl $181
80105dcd:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105dd2:	e9 cd f4 ff ff       	jmp    801052a4 <alltraps>

80105dd7 <vector182>:
.globl vector182
vector182:
  pushl $0
80105dd7:	6a 00                	push   $0x0
  pushl $182
80105dd9:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105dde:	e9 c1 f4 ff ff       	jmp    801052a4 <alltraps>

80105de3 <vector183>:
.globl vector183
vector183:
  pushl $0
80105de3:	6a 00                	push   $0x0
  pushl $183
80105de5:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105dea:	e9 b5 f4 ff ff       	jmp    801052a4 <alltraps>

80105def <vector184>:
.globl vector184
vector184:
  pushl $0
80105def:	6a 00                	push   $0x0
  pushl $184
80105df1:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105df6:	e9 a9 f4 ff ff       	jmp    801052a4 <alltraps>

80105dfb <vector185>:
.globl vector185
vector185:
  pushl $0
80105dfb:	6a 00                	push   $0x0
  pushl $185
80105dfd:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105e02:	e9 9d f4 ff ff       	jmp    801052a4 <alltraps>

80105e07 <vector186>:
.globl vector186
vector186:
  pushl $0
80105e07:	6a 00                	push   $0x0
  pushl $186
80105e09:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105e0e:	e9 91 f4 ff ff       	jmp    801052a4 <alltraps>

80105e13 <vector187>:
.globl vector187
vector187:
  pushl $0
80105e13:	6a 00                	push   $0x0
  pushl $187
80105e15:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105e1a:	e9 85 f4 ff ff       	jmp    801052a4 <alltraps>

80105e1f <vector188>:
.globl vector188
vector188:
  pushl $0
80105e1f:	6a 00                	push   $0x0
  pushl $188
80105e21:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105e26:	e9 79 f4 ff ff       	jmp    801052a4 <alltraps>

80105e2b <vector189>:
.globl vector189
vector189:
  pushl $0
80105e2b:	6a 00                	push   $0x0
  pushl $189
80105e2d:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105e32:	e9 6d f4 ff ff       	jmp    801052a4 <alltraps>

80105e37 <vector190>:
.globl vector190
vector190:
  pushl $0
80105e37:	6a 00                	push   $0x0
  pushl $190
80105e39:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105e3e:	e9 61 f4 ff ff       	jmp    801052a4 <alltraps>

80105e43 <vector191>:
.globl vector191
vector191:
  pushl $0
80105e43:	6a 00                	push   $0x0
  pushl $191
80105e45:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105e4a:	e9 55 f4 ff ff       	jmp    801052a4 <alltraps>

80105e4f <vector192>:
.globl vector192
vector192:
  pushl $0
80105e4f:	6a 00                	push   $0x0
  pushl $192
80105e51:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105e56:	e9 49 f4 ff ff       	jmp    801052a4 <alltraps>

80105e5b <vector193>:
.globl vector193
vector193:
  pushl $0
80105e5b:	6a 00                	push   $0x0
  pushl $193
80105e5d:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105e62:	e9 3d f4 ff ff       	jmp    801052a4 <alltraps>

80105e67 <vector194>:
.globl vector194
vector194:
  pushl $0
80105e67:	6a 00                	push   $0x0
  pushl $194
80105e69:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105e6e:	e9 31 f4 ff ff       	jmp    801052a4 <alltraps>

80105e73 <vector195>:
.globl vector195
vector195:
  pushl $0
80105e73:	6a 00                	push   $0x0
  pushl $195
80105e75:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105e7a:	e9 25 f4 ff ff       	jmp    801052a4 <alltraps>

80105e7f <vector196>:
.globl vector196
vector196:
  pushl $0
80105e7f:	6a 00                	push   $0x0
  pushl $196
80105e81:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105e86:	e9 19 f4 ff ff       	jmp    801052a4 <alltraps>

80105e8b <vector197>:
.globl vector197
vector197:
  pushl $0
80105e8b:	6a 00                	push   $0x0
  pushl $197
80105e8d:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105e92:	e9 0d f4 ff ff       	jmp    801052a4 <alltraps>

80105e97 <vector198>:
.globl vector198
vector198:
  pushl $0
80105e97:	6a 00                	push   $0x0
  pushl $198
80105e99:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105e9e:	e9 01 f4 ff ff       	jmp    801052a4 <alltraps>

80105ea3 <vector199>:
.globl vector199
vector199:
  pushl $0
80105ea3:	6a 00                	push   $0x0
  pushl $199
80105ea5:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105eaa:	e9 f5 f3 ff ff       	jmp    801052a4 <alltraps>

80105eaf <vector200>:
.globl vector200
vector200:
  pushl $0
80105eaf:	6a 00                	push   $0x0
  pushl $200
80105eb1:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105eb6:	e9 e9 f3 ff ff       	jmp    801052a4 <alltraps>

80105ebb <vector201>:
.globl vector201
vector201:
  pushl $0
80105ebb:	6a 00                	push   $0x0
  pushl $201
80105ebd:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105ec2:	e9 dd f3 ff ff       	jmp    801052a4 <alltraps>

80105ec7 <vector202>:
.globl vector202
vector202:
  pushl $0
80105ec7:	6a 00                	push   $0x0
  pushl $202
80105ec9:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105ece:	e9 d1 f3 ff ff       	jmp    801052a4 <alltraps>

80105ed3 <vector203>:
.globl vector203
vector203:
  pushl $0
80105ed3:	6a 00                	push   $0x0
  pushl $203
80105ed5:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105eda:	e9 c5 f3 ff ff       	jmp    801052a4 <alltraps>

80105edf <vector204>:
.globl vector204
vector204:
  pushl $0
80105edf:	6a 00                	push   $0x0
  pushl $204
80105ee1:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105ee6:	e9 b9 f3 ff ff       	jmp    801052a4 <alltraps>

80105eeb <vector205>:
.globl vector205
vector205:
  pushl $0
80105eeb:	6a 00                	push   $0x0
  pushl $205
80105eed:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105ef2:	e9 ad f3 ff ff       	jmp    801052a4 <alltraps>

80105ef7 <vector206>:
.globl vector206
vector206:
  pushl $0
80105ef7:	6a 00                	push   $0x0
  pushl $206
80105ef9:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105efe:	e9 a1 f3 ff ff       	jmp    801052a4 <alltraps>

80105f03 <vector207>:
.globl vector207
vector207:
  pushl $0
80105f03:	6a 00                	push   $0x0
  pushl $207
80105f05:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105f0a:	e9 95 f3 ff ff       	jmp    801052a4 <alltraps>

80105f0f <vector208>:
.globl vector208
vector208:
  pushl $0
80105f0f:	6a 00                	push   $0x0
  pushl $208
80105f11:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105f16:	e9 89 f3 ff ff       	jmp    801052a4 <alltraps>

80105f1b <vector209>:
.globl vector209
vector209:
  pushl $0
80105f1b:	6a 00                	push   $0x0
  pushl $209
80105f1d:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105f22:	e9 7d f3 ff ff       	jmp    801052a4 <alltraps>

80105f27 <vector210>:
.globl vector210
vector210:
  pushl $0
80105f27:	6a 00                	push   $0x0
  pushl $210
80105f29:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105f2e:	e9 71 f3 ff ff       	jmp    801052a4 <alltraps>

80105f33 <vector211>:
.globl vector211
vector211:
  pushl $0
80105f33:	6a 00                	push   $0x0
  pushl $211
80105f35:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105f3a:	e9 65 f3 ff ff       	jmp    801052a4 <alltraps>

80105f3f <vector212>:
.globl vector212
vector212:
  pushl $0
80105f3f:	6a 00                	push   $0x0
  pushl $212
80105f41:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105f46:	e9 59 f3 ff ff       	jmp    801052a4 <alltraps>

80105f4b <vector213>:
.globl vector213
vector213:
  pushl $0
80105f4b:	6a 00                	push   $0x0
  pushl $213
80105f4d:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105f52:	e9 4d f3 ff ff       	jmp    801052a4 <alltraps>

80105f57 <vector214>:
.globl vector214
vector214:
  pushl $0
80105f57:	6a 00                	push   $0x0
  pushl $214
80105f59:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105f5e:	e9 41 f3 ff ff       	jmp    801052a4 <alltraps>

80105f63 <vector215>:
.globl vector215
vector215:
  pushl $0
80105f63:	6a 00                	push   $0x0
  pushl $215
80105f65:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105f6a:	e9 35 f3 ff ff       	jmp    801052a4 <alltraps>

80105f6f <vector216>:
.globl vector216
vector216:
  pushl $0
80105f6f:	6a 00                	push   $0x0
  pushl $216
80105f71:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105f76:	e9 29 f3 ff ff       	jmp    801052a4 <alltraps>

80105f7b <vector217>:
.globl vector217
vector217:
  pushl $0
80105f7b:	6a 00                	push   $0x0
  pushl $217
80105f7d:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105f82:	e9 1d f3 ff ff       	jmp    801052a4 <alltraps>

80105f87 <vector218>:
.globl vector218
vector218:
  pushl $0
80105f87:	6a 00                	push   $0x0
  pushl $218
80105f89:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105f8e:	e9 11 f3 ff ff       	jmp    801052a4 <alltraps>

80105f93 <vector219>:
.globl vector219
vector219:
  pushl $0
80105f93:	6a 00                	push   $0x0
  pushl $219
80105f95:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105f9a:	e9 05 f3 ff ff       	jmp    801052a4 <alltraps>

80105f9f <vector220>:
.globl vector220
vector220:
  pushl $0
80105f9f:	6a 00                	push   $0x0
  pushl $220
80105fa1:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105fa6:	e9 f9 f2 ff ff       	jmp    801052a4 <alltraps>

80105fab <vector221>:
.globl vector221
vector221:
  pushl $0
80105fab:	6a 00                	push   $0x0
  pushl $221
80105fad:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105fb2:	e9 ed f2 ff ff       	jmp    801052a4 <alltraps>

80105fb7 <vector222>:
.globl vector222
vector222:
  pushl $0
80105fb7:	6a 00                	push   $0x0
  pushl $222
80105fb9:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105fbe:	e9 e1 f2 ff ff       	jmp    801052a4 <alltraps>

80105fc3 <vector223>:
.globl vector223
vector223:
  pushl $0
80105fc3:	6a 00                	push   $0x0
  pushl $223
80105fc5:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105fca:	e9 d5 f2 ff ff       	jmp    801052a4 <alltraps>

80105fcf <vector224>:
.globl vector224
vector224:
  pushl $0
80105fcf:	6a 00                	push   $0x0
  pushl $224
80105fd1:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105fd6:	e9 c9 f2 ff ff       	jmp    801052a4 <alltraps>

80105fdb <vector225>:
.globl vector225
vector225:
  pushl $0
80105fdb:	6a 00                	push   $0x0
  pushl $225
80105fdd:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105fe2:	e9 bd f2 ff ff       	jmp    801052a4 <alltraps>

80105fe7 <vector226>:
.globl vector226
vector226:
  pushl $0
80105fe7:	6a 00                	push   $0x0
  pushl $226
80105fe9:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105fee:	e9 b1 f2 ff ff       	jmp    801052a4 <alltraps>

80105ff3 <vector227>:
.globl vector227
vector227:
  pushl $0
80105ff3:	6a 00                	push   $0x0
  pushl $227
80105ff5:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105ffa:	e9 a5 f2 ff ff       	jmp    801052a4 <alltraps>

80105fff <vector228>:
.globl vector228
vector228:
  pushl $0
80105fff:	6a 00                	push   $0x0
  pushl $228
80106001:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80106006:	e9 99 f2 ff ff       	jmp    801052a4 <alltraps>

8010600b <vector229>:
.globl vector229
vector229:
  pushl $0
8010600b:	6a 00                	push   $0x0
  pushl $229
8010600d:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80106012:	e9 8d f2 ff ff       	jmp    801052a4 <alltraps>

80106017 <vector230>:
.globl vector230
vector230:
  pushl $0
80106017:	6a 00                	push   $0x0
  pushl $230
80106019:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
8010601e:	e9 81 f2 ff ff       	jmp    801052a4 <alltraps>

80106023 <vector231>:
.globl vector231
vector231:
  pushl $0
80106023:	6a 00                	push   $0x0
  pushl $231
80106025:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
8010602a:	e9 75 f2 ff ff       	jmp    801052a4 <alltraps>

8010602f <vector232>:
.globl vector232
vector232:
  pushl $0
8010602f:	6a 00                	push   $0x0
  pushl $232
80106031:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80106036:	e9 69 f2 ff ff       	jmp    801052a4 <alltraps>

8010603b <vector233>:
.globl vector233
vector233:
  pushl $0
8010603b:	6a 00                	push   $0x0
  pushl $233
8010603d:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80106042:	e9 5d f2 ff ff       	jmp    801052a4 <alltraps>

80106047 <vector234>:
.globl vector234
vector234:
  pushl $0
80106047:	6a 00                	push   $0x0
  pushl $234
80106049:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010604e:	e9 51 f2 ff ff       	jmp    801052a4 <alltraps>

80106053 <vector235>:
.globl vector235
vector235:
  pushl $0
80106053:	6a 00                	push   $0x0
  pushl $235
80106055:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
8010605a:	e9 45 f2 ff ff       	jmp    801052a4 <alltraps>

8010605f <vector236>:
.globl vector236
vector236:
  pushl $0
8010605f:	6a 00                	push   $0x0
  pushl $236
80106061:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80106066:	e9 39 f2 ff ff       	jmp    801052a4 <alltraps>

8010606b <vector237>:
.globl vector237
vector237:
  pushl $0
8010606b:	6a 00                	push   $0x0
  pushl $237
8010606d:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80106072:	e9 2d f2 ff ff       	jmp    801052a4 <alltraps>

80106077 <vector238>:
.globl vector238
vector238:
  pushl $0
80106077:	6a 00                	push   $0x0
  pushl $238
80106079:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010607e:	e9 21 f2 ff ff       	jmp    801052a4 <alltraps>

80106083 <vector239>:
.globl vector239
vector239:
  pushl $0
80106083:	6a 00                	push   $0x0
  pushl $239
80106085:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
8010608a:	e9 15 f2 ff ff       	jmp    801052a4 <alltraps>

8010608f <vector240>:
.globl vector240
vector240:
  pushl $0
8010608f:	6a 00                	push   $0x0
  pushl $240
80106091:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80106096:	e9 09 f2 ff ff       	jmp    801052a4 <alltraps>

8010609b <vector241>:
.globl vector241
vector241:
  pushl $0
8010609b:	6a 00                	push   $0x0
  pushl $241
8010609d:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801060a2:	e9 fd f1 ff ff       	jmp    801052a4 <alltraps>

801060a7 <vector242>:
.globl vector242
vector242:
  pushl $0
801060a7:	6a 00                	push   $0x0
  pushl $242
801060a9:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801060ae:	e9 f1 f1 ff ff       	jmp    801052a4 <alltraps>

801060b3 <vector243>:
.globl vector243
vector243:
  pushl $0
801060b3:	6a 00                	push   $0x0
  pushl $243
801060b5:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801060ba:	e9 e5 f1 ff ff       	jmp    801052a4 <alltraps>

801060bf <vector244>:
.globl vector244
vector244:
  pushl $0
801060bf:	6a 00                	push   $0x0
  pushl $244
801060c1:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801060c6:	e9 d9 f1 ff ff       	jmp    801052a4 <alltraps>

801060cb <vector245>:
.globl vector245
vector245:
  pushl $0
801060cb:	6a 00                	push   $0x0
  pushl $245
801060cd:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801060d2:	e9 cd f1 ff ff       	jmp    801052a4 <alltraps>

801060d7 <vector246>:
.globl vector246
vector246:
  pushl $0
801060d7:	6a 00                	push   $0x0
  pushl $246
801060d9:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801060de:	e9 c1 f1 ff ff       	jmp    801052a4 <alltraps>

801060e3 <vector247>:
.globl vector247
vector247:
  pushl $0
801060e3:	6a 00                	push   $0x0
  pushl $247
801060e5:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801060ea:	e9 b5 f1 ff ff       	jmp    801052a4 <alltraps>

801060ef <vector248>:
.globl vector248
vector248:
  pushl $0
801060ef:	6a 00                	push   $0x0
  pushl $248
801060f1:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801060f6:	e9 a9 f1 ff ff       	jmp    801052a4 <alltraps>

801060fb <vector249>:
.globl vector249
vector249:
  pushl $0
801060fb:	6a 00                	push   $0x0
  pushl $249
801060fd:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80106102:	e9 9d f1 ff ff       	jmp    801052a4 <alltraps>

80106107 <vector250>:
.globl vector250
vector250:
  pushl $0
80106107:	6a 00                	push   $0x0
  pushl $250
80106109:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
8010610e:	e9 91 f1 ff ff       	jmp    801052a4 <alltraps>

80106113 <vector251>:
.globl vector251
vector251:
  pushl $0
80106113:	6a 00                	push   $0x0
  pushl $251
80106115:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
8010611a:	e9 85 f1 ff ff       	jmp    801052a4 <alltraps>

8010611f <vector252>:
.globl vector252
vector252:
  pushl $0
8010611f:	6a 00                	push   $0x0
  pushl $252
80106121:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80106126:	e9 79 f1 ff ff       	jmp    801052a4 <alltraps>

8010612b <vector253>:
.globl vector253
vector253:
  pushl $0
8010612b:	6a 00                	push   $0x0
  pushl $253
8010612d:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80106132:	e9 6d f1 ff ff       	jmp    801052a4 <alltraps>

80106137 <vector254>:
.globl vector254
vector254:
  pushl $0
80106137:	6a 00                	push   $0x0
  pushl $254
80106139:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010613e:	e9 61 f1 ff ff       	jmp    801052a4 <alltraps>

80106143 <vector255>:
.globl vector255
vector255:
  pushl $0
80106143:	6a 00                	push   $0x0
  pushl $255
80106145:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
8010614a:	e9 55 f1 ff ff       	jmp    801052a4 <alltraps>

8010614f <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010614f:	55                   	push   %ebp
80106150:	89 e5                	mov    %esp,%ebp
80106152:	57                   	push   %edi
80106153:	56                   	push   %esi
80106154:	53                   	push   %ebx
80106155:	83 ec 0c             	sub    $0xc,%esp
80106158:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
8010615a:	c1 ea 16             	shr    $0x16,%edx
8010615d:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80106160:	8b 1f                	mov    (%edi),%ebx
80106162:	f6 c3 01             	test   $0x1,%bl
80106165:	74 22                	je     80106189 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80106167:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
8010616d:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80106173:	c1 ee 0c             	shr    $0xc,%esi
80106176:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
8010617c:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
8010617f:	89 d8                	mov    %ebx,%eax
80106181:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106184:	5b                   	pop    %ebx
80106185:	5e                   	pop    %esi
80106186:	5f                   	pop    %edi
80106187:	5d                   	pop    %ebp
80106188:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80106189:	85 c9                	test   %ecx,%ecx
8010618b:	74 2b                	je     801061b8 <walkpgdir+0x69>
8010618d:	e8 29 bf ff ff       	call   801020bb <kalloc>
80106192:	89 c3                	mov    %eax,%ebx
80106194:	85 c0                	test   %eax,%eax
80106196:	74 e7                	je     8010617f <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80106198:	83 ec 04             	sub    $0x4,%esp
8010619b:	68 00 10 00 00       	push   $0x1000
801061a0:	6a 00                	push   $0x0
801061a2:	50                   	push   %eax
801061a3:	e8 92 df ff ff       	call   8010413a <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
801061a8:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801061ae:	83 c8 07             	or     $0x7,%eax
801061b1:	89 07                	mov    %eax,(%edi)
801061b3:	83 c4 10             	add    $0x10,%esp
801061b6:	eb bb                	jmp    80106173 <walkpgdir+0x24>
      return 0;
801061b8:	bb 00 00 00 00       	mov    $0x0,%ebx
801061bd:	eb c0                	jmp    8010617f <walkpgdir+0x30>

801061bf <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801061bf:	55                   	push   %ebp
801061c0:	89 e5                	mov    %esp,%ebp
801061c2:	57                   	push   %edi
801061c3:	56                   	push   %esi
801061c4:	53                   	push   %ebx
801061c5:	83 ec 1c             	sub    $0x1c,%esp
801061c8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801061cb:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
801061ce:	89 d3                	mov    %edx,%ebx
801061d0:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
801061d6:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
801061da:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
801061e0:	b9 01 00 00 00       	mov    $0x1,%ecx
801061e5:	89 da                	mov    %ebx,%edx
801061e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801061ea:	e8 60 ff ff ff       	call   8010614f <walkpgdir>
801061ef:	85 c0                	test   %eax,%eax
801061f1:	74 2e                	je     80106221 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
801061f3:	f6 00 01             	testb  $0x1,(%eax)
801061f6:	75 1c                	jne    80106214 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
801061f8:	89 f2                	mov    %esi,%edx
801061fa:	0b 55 0c             	or     0xc(%ebp),%edx
801061fd:	83 ca 01             	or     $0x1,%edx
80106200:	89 10                	mov    %edx,(%eax)
    if(a == last)
80106202:	39 fb                	cmp    %edi,%ebx
80106204:	74 28                	je     8010622e <mappages+0x6f>
      break;
    a += PGSIZE;
80106206:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
8010620c:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80106212:	eb cc                	jmp    801061e0 <mappages+0x21>
      panic("remap");
80106214:	83 ec 0c             	sub    $0xc,%esp
80106217:	68 f8 72 10 80       	push   $0x801072f8
8010621c:	e8 27 a1 ff ff       	call   80100348 <panic>
      return -1;
80106221:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80106226:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106229:	5b                   	pop    %ebx
8010622a:	5e                   	pop    %esi
8010622b:	5f                   	pop    %edi
8010622c:	5d                   	pop    %ebp
8010622d:	c3                   	ret    
  return 0;
8010622e:	b8 00 00 00 00       	mov    $0x0,%eax
80106233:	eb f1                	jmp    80106226 <mappages+0x67>

80106235 <seginit>:
{
80106235:	55                   	push   %ebp
80106236:	89 e5                	mov    %esp,%ebp
80106238:	53                   	push   %ebx
80106239:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
8010623c:	e8 d5 cf ff ff       	call   80103216 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80106241:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80106247:	66 c7 80 f8 27 11 80 	movw   $0xffff,-0x7feed808(%eax)
8010624e:	ff ff 
80106250:	66 c7 80 fa 27 11 80 	movw   $0x0,-0x7feed806(%eax)
80106257:	00 00 
80106259:	c6 80 fc 27 11 80 00 	movb   $0x0,-0x7feed804(%eax)
80106260:	0f b6 88 fd 27 11 80 	movzbl -0x7feed803(%eax),%ecx
80106267:	83 e1 f0             	and    $0xfffffff0,%ecx
8010626a:	83 c9 1a             	or     $0x1a,%ecx
8010626d:	83 e1 9f             	and    $0xffffff9f,%ecx
80106270:	83 c9 80             	or     $0xffffff80,%ecx
80106273:	88 88 fd 27 11 80    	mov    %cl,-0x7feed803(%eax)
80106279:	0f b6 88 fe 27 11 80 	movzbl -0x7feed802(%eax),%ecx
80106280:	83 c9 0f             	or     $0xf,%ecx
80106283:	83 e1 cf             	and    $0xffffffcf,%ecx
80106286:	83 c9 c0             	or     $0xffffffc0,%ecx
80106289:	88 88 fe 27 11 80    	mov    %cl,-0x7feed802(%eax)
8010628f:	c6 80 ff 27 11 80 00 	movb   $0x0,-0x7feed801(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80106296:	66 c7 80 00 28 11 80 	movw   $0xffff,-0x7feed800(%eax)
8010629d:	ff ff 
8010629f:	66 c7 80 02 28 11 80 	movw   $0x0,-0x7feed7fe(%eax)
801062a6:	00 00 
801062a8:	c6 80 04 28 11 80 00 	movb   $0x0,-0x7feed7fc(%eax)
801062af:	0f b6 88 05 28 11 80 	movzbl -0x7feed7fb(%eax),%ecx
801062b6:	83 e1 f0             	and    $0xfffffff0,%ecx
801062b9:	83 c9 12             	or     $0x12,%ecx
801062bc:	83 e1 9f             	and    $0xffffff9f,%ecx
801062bf:	83 c9 80             	or     $0xffffff80,%ecx
801062c2:	88 88 05 28 11 80    	mov    %cl,-0x7feed7fb(%eax)
801062c8:	0f b6 88 06 28 11 80 	movzbl -0x7feed7fa(%eax),%ecx
801062cf:	83 c9 0f             	or     $0xf,%ecx
801062d2:	83 e1 cf             	and    $0xffffffcf,%ecx
801062d5:	83 c9 c0             	or     $0xffffffc0,%ecx
801062d8:	88 88 06 28 11 80    	mov    %cl,-0x7feed7fa(%eax)
801062de:	c6 80 07 28 11 80 00 	movb   $0x0,-0x7feed7f9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801062e5:	66 c7 80 08 28 11 80 	movw   $0xffff,-0x7feed7f8(%eax)
801062ec:	ff ff 
801062ee:	66 c7 80 0a 28 11 80 	movw   $0x0,-0x7feed7f6(%eax)
801062f5:	00 00 
801062f7:	c6 80 0c 28 11 80 00 	movb   $0x0,-0x7feed7f4(%eax)
801062fe:	c6 80 0d 28 11 80 fa 	movb   $0xfa,-0x7feed7f3(%eax)
80106305:	0f b6 88 0e 28 11 80 	movzbl -0x7feed7f2(%eax),%ecx
8010630c:	83 c9 0f             	or     $0xf,%ecx
8010630f:	83 e1 cf             	and    $0xffffffcf,%ecx
80106312:	83 c9 c0             	or     $0xffffffc0,%ecx
80106315:	88 88 0e 28 11 80    	mov    %cl,-0x7feed7f2(%eax)
8010631b:	c6 80 0f 28 11 80 00 	movb   $0x0,-0x7feed7f1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80106322:	66 c7 80 10 28 11 80 	movw   $0xffff,-0x7feed7f0(%eax)
80106329:	ff ff 
8010632b:	66 c7 80 12 28 11 80 	movw   $0x0,-0x7feed7ee(%eax)
80106332:	00 00 
80106334:	c6 80 14 28 11 80 00 	movb   $0x0,-0x7feed7ec(%eax)
8010633b:	c6 80 15 28 11 80 f2 	movb   $0xf2,-0x7feed7eb(%eax)
80106342:	0f b6 88 16 28 11 80 	movzbl -0x7feed7ea(%eax),%ecx
80106349:	83 c9 0f             	or     $0xf,%ecx
8010634c:	83 e1 cf             	and    $0xffffffcf,%ecx
8010634f:	83 c9 c0             	or     $0xffffffc0,%ecx
80106352:	88 88 16 28 11 80    	mov    %cl,-0x7feed7ea(%eax)
80106358:	c6 80 17 28 11 80 00 	movb   $0x0,-0x7feed7e9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
8010635f:	05 f0 27 11 80       	add    $0x801127f0,%eax
  pd[0] = size-1;
80106364:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
8010636a:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
8010636e:	c1 e8 10             	shr    $0x10,%eax
80106371:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80106375:	8d 45 f2             	lea    -0xe(%ebp),%eax
80106378:	0f 01 10             	lgdtl  (%eax)
}
8010637b:	83 c4 14             	add    $0x14,%esp
8010637e:	5b                   	pop    %ebx
8010637f:	5d                   	pop    %ebp
80106380:	c3                   	ret    

80106381 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80106381:	55                   	push   %ebp
80106382:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80106384:	a1 c4 6b 11 80       	mov    0x80116bc4,%eax
80106389:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010638e:	0f 22 d8             	mov    %eax,%cr3
}
80106391:	5d                   	pop    %ebp
80106392:	c3                   	ret    

80106393 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80106393:	55                   	push   %ebp
80106394:	89 e5                	mov    %esp,%ebp
80106396:	57                   	push   %edi
80106397:	56                   	push   %esi
80106398:	53                   	push   %ebx
80106399:	83 ec 1c             	sub    $0x1c,%esp
8010639c:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
8010639f:	85 f6                	test   %esi,%esi
801063a1:	0f 84 dd 00 00 00    	je     80106484 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
801063a7:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
801063ab:	0f 84 e0 00 00 00    	je     80106491 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
801063b1:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
801063b5:	0f 84 e3 00 00 00    	je     8010649e <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
801063bb:	e8 f1 db ff ff       	call   80103fb1 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
801063c0:	e8 f5 cd ff ff       	call   801031ba <mycpu>
801063c5:	89 c3                	mov    %eax,%ebx
801063c7:	e8 ee cd ff ff       	call   801031ba <mycpu>
801063cc:	8d 78 08             	lea    0x8(%eax),%edi
801063cf:	e8 e6 cd ff ff       	call   801031ba <mycpu>
801063d4:	83 c0 08             	add    $0x8,%eax
801063d7:	c1 e8 10             	shr    $0x10,%eax
801063da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801063dd:	e8 d8 cd ff ff       	call   801031ba <mycpu>
801063e2:	83 c0 08             	add    $0x8,%eax
801063e5:	c1 e8 18             	shr    $0x18,%eax
801063e8:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
801063ef:	67 00 
801063f1:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
801063f8:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
801063fc:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106402:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80106409:	83 e2 f0             	and    $0xfffffff0,%edx
8010640c:	83 ca 19             	or     $0x19,%edx
8010640f:	83 e2 9f             	and    $0xffffff9f,%edx
80106412:	83 ca 80             	or     $0xffffff80,%edx
80106415:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
8010641b:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106422:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80106428:	e8 8d cd ff ff       	call   801031ba <mycpu>
8010642d:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106434:	83 e2 ef             	and    $0xffffffef,%edx
80106437:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
8010643d:	e8 78 cd ff ff       	call   801031ba <mycpu>
80106442:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106448:	8b 5e 08             	mov    0x8(%esi),%ebx
8010644b:	e8 6a cd ff ff       	call   801031ba <mycpu>
80106450:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106456:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80106459:	e8 5c cd ff ff       	call   801031ba <mycpu>
8010645e:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106464:	b8 28 00 00 00       	mov    $0x28,%eax
80106469:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
8010646c:	8b 46 04             	mov    0x4(%esi),%eax
8010646f:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106474:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80106477:	e8 72 db ff ff       	call   80103fee <popcli>
}
8010647c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010647f:	5b                   	pop    %ebx
80106480:	5e                   	pop    %esi
80106481:	5f                   	pop    %edi
80106482:	5d                   	pop    %ebp
80106483:	c3                   	ret    
    panic("switchuvm: no process");
80106484:	83 ec 0c             	sub    $0xc,%esp
80106487:	68 fe 72 10 80       	push   $0x801072fe
8010648c:	e8 b7 9e ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
80106491:	83 ec 0c             	sub    $0xc,%esp
80106494:	68 14 73 10 80       	push   $0x80107314
80106499:	e8 aa 9e ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
8010649e:	83 ec 0c             	sub    $0xc,%esp
801064a1:	68 29 73 10 80       	push   $0x80107329
801064a6:	e8 9d 9e ff ff       	call   80100348 <panic>

801064ab <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801064ab:	55                   	push   %ebp
801064ac:	89 e5                	mov    %esp,%ebp
801064ae:	56                   	push   %esi
801064af:	53                   	push   %ebx
801064b0:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
801064b3:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801064b9:	77 4c                	ja     80106507 <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
801064bb:	e8 fb bb ff ff       	call   801020bb <kalloc>
801064c0:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801064c2:	83 ec 04             	sub    $0x4,%esp
801064c5:	68 00 10 00 00       	push   $0x1000
801064ca:	6a 00                	push   $0x0
801064cc:	50                   	push   %eax
801064cd:	e8 68 dc ff ff       	call   8010413a <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801064d2:	83 c4 08             	add    $0x8,%esp
801064d5:	6a 06                	push   $0x6
801064d7:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801064dd:	50                   	push   %eax
801064de:	b9 00 10 00 00       	mov    $0x1000,%ecx
801064e3:	ba 00 00 00 00       	mov    $0x0,%edx
801064e8:	8b 45 08             	mov    0x8(%ebp),%eax
801064eb:	e8 cf fc ff ff       	call   801061bf <mappages>
  memmove(mem, init, sz);
801064f0:	83 c4 0c             	add    $0xc,%esp
801064f3:	56                   	push   %esi
801064f4:	ff 75 0c             	pushl  0xc(%ebp)
801064f7:	53                   	push   %ebx
801064f8:	e8 b8 dc ff ff       	call   801041b5 <memmove>
}
801064fd:	83 c4 10             	add    $0x10,%esp
80106500:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106503:	5b                   	pop    %ebx
80106504:	5e                   	pop    %esi
80106505:	5d                   	pop    %ebp
80106506:	c3                   	ret    
    panic("inituvm: more than a page");
80106507:	83 ec 0c             	sub    $0xc,%esp
8010650a:	68 3d 73 10 80       	push   $0x8010733d
8010650f:	e8 34 9e ff ff       	call   80100348 <panic>

80106514 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106514:	55                   	push   %ebp
80106515:	89 e5                	mov    %esp,%ebp
80106517:	57                   	push   %edi
80106518:	56                   	push   %esi
80106519:	53                   	push   %ebx
8010651a:	83 ec 0c             	sub    $0xc,%esp
8010651d:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80106520:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106527:	75 07                	jne    80106530 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80106529:	bb 00 00 00 00       	mov    $0x0,%ebx
8010652e:	eb 3c                	jmp    8010656c <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
80106530:	83 ec 0c             	sub    $0xc,%esp
80106533:	68 f8 73 10 80       	push   $0x801073f8
80106538:	e8 0b 9e ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
8010653d:	83 ec 0c             	sub    $0xc,%esp
80106540:	68 57 73 10 80       	push   $0x80107357
80106545:	e8 fe 9d ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
8010654a:	05 00 00 00 80       	add    $0x80000000,%eax
8010654f:	56                   	push   %esi
80106550:	89 da                	mov    %ebx,%edx
80106552:	03 55 14             	add    0x14(%ebp),%edx
80106555:	52                   	push   %edx
80106556:	50                   	push   %eax
80106557:	ff 75 10             	pushl  0x10(%ebp)
8010655a:	e8 14 b2 ff ff       	call   80101773 <readi>
8010655f:	83 c4 10             	add    $0x10,%esp
80106562:	39 f0                	cmp    %esi,%eax
80106564:	75 47                	jne    801065ad <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106566:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010656c:	39 fb                	cmp    %edi,%ebx
8010656e:	73 30                	jae    801065a0 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106570:	89 da                	mov    %ebx,%edx
80106572:	03 55 0c             	add    0xc(%ebp),%edx
80106575:	b9 00 00 00 00       	mov    $0x0,%ecx
8010657a:	8b 45 08             	mov    0x8(%ebp),%eax
8010657d:	e8 cd fb ff ff       	call   8010614f <walkpgdir>
80106582:	85 c0                	test   %eax,%eax
80106584:	74 b7                	je     8010653d <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
80106586:	8b 00                	mov    (%eax),%eax
80106588:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
8010658d:	89 fe                	mov    %edi,%esi
8010658f:	29 de                	sub    %ebx,%esi
80106591:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106597:	76 b1                	jbe    8010654a <loaduvm+0x36>
      n = PGSIZE;
80106599:	be 00 10 00 00       	mov    $0x1000,%esi
8010659e:	eb aa                	jmp    8010654a <loaduvm+0x36>
      return -1;
  }
  return 0;
801065a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
801065a8:	5b                   	pop    %ebx
801065a9:	5e                   	pop    %esi
801065aa:	5f                   	pop    %edi
801065ab:	5d                   	pop    %ebp
801065ac:	c3                   	ret    
      return -1;
801065ad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065b2:	eb f1                	jmp    801065a5 <loaduvm+0x91>

801065b4 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801065b4:	55                   	push   %ebp
801065b5:	89 e5                	mov    %esp,%ebp
801065b7:	57                   	push   %edi
801065b8:	56                   	push   %esi
801065b9:	53                   	push   %ebx
801065ba:	83 ec 0c             	sub    $0xc,%esp
801065bd:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801065c0:	39 7d 10             	cmp    %edi,0x10(%ebp)
801065c3:	73 11                	jae    801065d6 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801065c5:	8b 45 10             	mov    0x10(%ebp),%eax
801065c8:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801065ce:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801065d4:	eb 19                	jmp    801065ef <deallocuvm+0x3b>
    return oldsz;
801065d6:	89 f8                	mov    %edi,%eax
801065d8:	eb 64                	jmp    8010663e <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801065da:	c1 eb 16             	shr    $0x16,%ebx
801065dd:	83 c3 01             	add    $0x1,%ebx
801065e0:	c1 e3 16             	shl    $0x16,%ebx
801065e3:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801065e9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801065ef:	39 fb                	cmp    %edi,%ebx
801065f1:	73 48                	jae    8010663b <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
801065f3:	b9 00 00 00 00       	mov    $0x0,%ecx
801065f8:	89 da                	mov    %ebx,%edx
801065fa:	8b 45 08             	mov    0x8(%ebp),%eax
801065fd:	e8 4d fb ff ff       	call   8010614f <walkpgdir>
80106602:	89 c6                	mov    %eax,%esi
    if(!pte)
80106604:	85 c0                	test   %eax,%eax
80106606:	74 d2                	je     801065da <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106608:	8b 00                	mov    (%eax),%eax
8010660a:	a8 01                	test   $0x1,%al
8010660c:	74 db                	je     801065e9 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
8010660e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106613:	74 19                	je     8010662e <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106615:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010661a:	83 ec 0c             	sub    $0xc,%esp
8010661d:	50                   	push   %eax
8010661e:	e8 81 b9 ff ff       	call   80101fa4 <kfree>
      *pte = 0;
80106623:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106629:	83 c4 10             	add    $0x10,%esp
8010662c:	eb bb                	jmp    801065e9 <deallocuvm+0x35>
        panic("kfree");
8010662e:	83 ec 0c             	sub    $0xc,%esp
80106631:	68 66 6c 10 80       	push   $0x80106c66
80106636:	e8 0d 9d ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
8010663b:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010663e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106641:	5b                   	pop    %ebx
80106642:	5e                   	pop    %esi
80106643:	5f                   	pop    %edi
80106644:	5d                   	pop    %ebp
80106645:	c3                   	ret    

80106646 <allocuvm>:
{
80106646:	55                   	push   %ebp
80106647:	89 e5                	mov    %esp,%ebp
80106649:	57                   	push   %edi
8010664a:	56                   	push   %esi
8010664b:	53                   	push   %ebx
8010664c:	83 ec 1c             	sub    $0x1c,%esp
8010664f:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
80106652:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106655:	85 ff                	test   %edi,%edi
80106657:	0f 88 c1 00 00 00    	js     8010671e <allocuvm+0xd8>
  if(newsz < oldsz)
8010665d:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106660:	72 5c                	jb     801066be <allocuvm+0x78>
  a = PGROUNDUP(oldsz);
80106662:	8b 45 0c             	mov    0xc(%ebp),%eax
80106665:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010666b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
80106671:	39 fb                	cmp    %edi,%ebx
80106673:	0f 83 ac 00 00 00    	jae    80106725 <allocuvm+0xdf>
    mem = kalloc();
80106679:	e8 3d ba ff ff       	call   801020bb <kalloc>
8010667e:	89 c6                	mov    %eax,%esi
    if(mem == 0){
80106680:	85 c0                	test   %eax,%eax
80106682:	74 42                	je     801066c6 <allocuvm+0x80>
    memset(mem, 0, PGSIZE);
80106684:	83 ec 04             	sub    $0x4,%esp
80106687:	68 00 10 00 00       	push   $0x1000
8010668c:	6a 00                	push   $0x0
8010668e:	50                   	push   %eax
8010668f:	e8 a6 da ff ff       	call   8010413a <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80106694:	83 c4 08             	add    $0x8,%esp
80106697:	6a 06                	push   $0x6
80106699:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
8010669f:	50                   	push   %eax
801066a0:	b9 00 10 00 00       	mov    $0x1000,%ecx
801066a5:	89 da                	mov    %ebx,%edx
801066a7:	8b 45 08             	mov    0x8(%ebp),%eax
801066aa:	e8 10 fb ff ff       	call   801061bf <mappages>
801066af:	83 c4 10             	add    $0x10,%esp
801066b2:	85 c0                	test   %eax,%eax
801066b4:	78 38                	js     801066ee <allocuvm+0xa8>
  for(; a < newsz; a += PGSIZE){
801066b6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801066bc:	eb b3                	jmp    80106671 <allocuvm+0x2b>
    return oldsz;
801066be:	8b 45 0c             	mov    0xc(%ebp),%eax
801066c1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801066c4:	eb 5f                	jmp    80106725 <allocuvm+0xdf>
      cprintf("allocuvm out of memory\n");
801066c6:	83 ec 0c             	sub    $0xc,%esp
801066c9:	68 75 73 10 80       	push   $0x80107375
801066ce:	e8 38 9f ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801066d3:	83 c4 0c             	add    $0xc,%esp
801066d6:	ff 75 0c             	pushl  0xc(%ebp)
801066d9:	57                   	push   %edi
801066da:	ff 75 08             	pushl  0x8(%ebp)
801066dd:	e8 d2 fe ff ff       	call   801065b4 <deallocuvm>
      return 0;
801066e2:	83 c4 10             	add    $0x10,%esp
801066e5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801066ec:	eb 37                	jmp    80106725 <allocuvm+0xdf>
      cprintf("allocuvm out of memory (2)\n");
801066ee:	83 ec 0c             	sub    $0xc,%esp
801066f1:	68 8d 73 10 80       	push   $0x8010738d
801066f6:	e8 10 9f ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801066fb:	83 c4 0c             	add    $0xc,%esp
801066fe:	ff 75 0c             	pushl  0xc(%ebp)
80106701:	57                   	push   %edi
80106702:	ff 75 08             	pushl  0x8(%ebp)
80106705:	e8 aa fe ff ff       	call   801065b4 <deallocuvm>
      kfree(mem);
8010670a:	89 34 24             	mov    %esi,(%esp)
8010670d:	e8 92 b8 ff ff       	call   80101fa4 <kfree>
      return 0;
80106712:	83 c4 10             	add    $0x10,%esp
80106715:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010671c:	eb 07                	jmp    80106725 <allocuvm+0xdf>
    return 0;
8010671e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106725:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106728:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010672b:	5b                   	pop    %ebx
8010672c:	5e                   	pop    %esi
8010672d:	5f                   	pop    %edi
8010672e:	5d                   	pop    %ebp
8010672f:	c3                   	ret    

80106730 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80106730:	55                   	push   %ebp
80106731:	89 e5                	mov    %esp,%ebp
80106733:	56                   	push   %esi
80106734:	53                   	push   %ebx
80106735:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
80106738:	85 f6                	test   %esi,%esi
8010673a:	74 1a                	je     80106756 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010673c:	83 ec 04             	sub    $0x4,%esp
8010673f:	6a 00                	push   $0x0
80106741:	68 00 00 00 80       	push   $0x80000000
80106746:	56                   	push   %esi
80106747:	e8 68 fe ff ff       	call   801065b4 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010674c:	83 c4 10             	add    $0x10,%esp
8010674f:	bb 00 00 00 00       	mov    $0x0,%ebx
80106754:	eb 10                	jmp    80106766 <freevm+0x36>
    panic("freevm: no pgdir");
80106756:	83 ec 0c             	sub    $0xc,%esp
80106759:	68 a9 73 10 80       	push   $0x801073a9
8010675e:	e8 e5 9b ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106763:	83 c3 01             	add    $0x1,%ebx
80106766:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
8010676c:	77 1f                	ja     8010678d <freevm+0x5d>
    if(pgdir[i] & PTE_P){
8010676e:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
80106771:	a8 01                	test   $0x1,%al
80106773:	74 ee                	je     80106763 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106775:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010677a:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010677f:	83 ec 0c             	sub    $0xc,%esp
80106782:	50                   	push   %eax
80106783:	e8 1c b8 ff ff       	call   80101fa4 <kfree>
80106788:	83 c4 10             	add    $0x10,%esp
8010678b:	eb d6                	jmp    80106763 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
8010678d:	83 ec 0c             	sub    $0xc,%esp
80106790:	56                   	push   %esi
80106791:	e8 0e b8 ff ff       	call   80101fa4 <kfree>
}
80106796:	83 c4 10             	add    $0x10,%esp
80106799:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010679c:	5b                   	pop    %ebx
8010679d:	5e                   	pop    %esi
8010679e:	5d                   	pop    %ebp
8010679f:	c3                   	ret    

801067a0 <setupkvm>:
{
801067a0:	55                   	push   %ebp
801067a1:	89 e5                	mov    %esp,%ebp
801067a3:	56                   	push   %esi
801067a4:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
801067a5:	e8 11 b9 ff ff       	call   801020bb <kalloc>
801067aa:	89 c6                	mov    %eax,%esi
801067ac:	85 c0                	test   %eax,%eax
801067ae:	74 55                	je     80106805 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
801067b0:	83 ec 04             	sub    $0x4,%esp
801067b3:	68 00 10 00 00       	push   $0x1000
801067b8:	6a 00                	push   $0x0
801067ba:	50                   	push   %eax
801067bb:	e8 7a d9 ff ff       	call   8010413a <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801067c0:	83 c4 10             	add    $0x10,%esp
801067c3:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
801067c8:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
801067ce:	73 35                	jae    80106805 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
801067d0:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801067d3:	8b 4b 08             	mov    0x8(%ebx),%ecx
801067d6:	29 c1                	sub    %eax,%ecx
801067d8:	83 ec 08             	sub    $0x8,%esp
801067db:	ff 73 0c             	pushl  0xc(%ebx)
801067de:	50                   	push   %eax
801067df:	8b 13                	mov    (%ebx),%edx
801067e1:	89 f0                	mov    %esi,%eax
801067e3:	e8 d7 f9 ff ff       	call   801061bf <mappages>
801067e8:	83 c4 10             	add    $0x10,%esp
801067eb:	85 c0                	test   %eax,%eax
801067ed:	78 05                	js     801067f4 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801067ef:	83 c3 10             	add    $0x10,%ebx
801067f2:	eb d4                	jmp    801067c8 <setupkvm+0x28>
      freevm(pgdir);
801067f4:	83 ec 0c             	sub    $0xc,%esp
801067f7:	56                   	push   %esi
801067f8:	e8 33 ff ff ff       	call   80106730 <freevm>
      return 0;
801067fd:	83 c4 10             	add    $0x10,%esp
80106800:	be 00 00 00 00       	mov    $0x0,%esi
}
80106805:	89 f0                	mov    %esi,%eax
80106807:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010680a:	5b                   	pop    %ebx
8010680b:	5e                   	pop    %esi
8010680c:	5d                   	pop    %ebp
8010680d:	c3                   	ret    

8010680e <kvmalloc>:
{
8010680e:	55                   	push   %ebp
8010680f:	89 e5                	mov    %esp,%ebp
80106811:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106814:	e8 87 ff ff ff       	call   801067a0 <setupkvm>
80106819:	a3 c4 6b 11 80       	mov    %eax,0x80116bc4
  switchkvm();
8010681e:	e8 5e fb ff ff       	call   80106381 <switchkvm>
}
80106823:	c9                   	leave  
80106824:	c3                   	ret    

80106825 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106825:	55                   	push   %ebp
80106826:	89 e5                	mov    %esp,%ebp
80106828:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010682b:	b9 00 00 00 00       	mov    $0x0,%ecx
80106830:	8b 55 0c             	mov    0xc(%ebp),%edx
80106833:	8b 45 08             	mov    0x8(%ebp),%eax
80106836:	e8 14 f9 ff ff       	call   8010614f <walkpgdir>
  if(pte == 0)
8010683b:	85 c0                	test   %eax,%eax
8010683d:	74 05                	je     80106844 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010683f:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
80106842:	c9                   	leave  
80106843:	c3                   	ret    
    panic("clearpteu");
80106844:	83 ec 0c             	sub    $0xc,%esp
80106847:	68 ba 73 10 80       	push   $0x801073ba
8010684c:	e8 f7 9a ff ff       	call   80100348 <panic>

80106851 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80106851:	55                   	push   %ebp
80106852:	89 e5                	mov    %esp,%ebp
80106854:	57                   	push   %edi
80106855:	56                   	push   %esi
80106856:	53                   	push   %ebx
80106857:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
8010685a:	e8 41 ff ff ff       	call   801067a0 <setupkvm>
8010685f:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106862:	85 c0                	test   %eax,%eax
80106864:	0f 84 c4 00 00 00    	je     8010692e <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010686a:	bf 00 00 00 00       	mov    $0x0,%edi
8010686f:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106872:	0f 83 b6 00 00 00    	jae    8010692e <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80106878:	89 7d e4             	mov    %edi,-0x1c(%ebp)
8010687b:	b9 00 00 00 00       	mov    $0x0,%ecx
80106880:	89 fa                	mov    %edi,%edx
80106882:	8b 45 08             	mov    0x8(%ebp),%eax
80106885:	e8 c5 f8 ff ff       	call   8010614f <walkpgdir>
8010688a:	85 c0                	test   %eax,%eax
8010688c:	74 65                	je     801068f3 <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
8010688e:	8b 00                	mov    (%eax),%eax
80106890:	a8 01                	test   $0x1,%al
80106892:	74 6c                	je     80106900 <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106894:	89 c6                	mov    %eax,%esi
80106896:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
8010689c:	25 ff 0f 00 00       	and    $0xfff,%eax
801068a1:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
801068a4:	e8 12 b8 ff ff       	call   801020bb <kalloc>
801068a9:	89 c3                	mov    %eax,%ebx
801068ab:	85 c0                	test   %eax,%eax
801068ad:	74 6a                	je     80106919 <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801068af:	81 c6 00 00 00 80    	add    $0x80000000,%esi
801068b5:	83 ec 04             	sub    $0x4,%esp
801068b8:	68 00 10 00 00       	push   $0x1000
801068bd:	56                   	push   %esi
801068be:	50                   	push   %eax
801068bf:	e8 f1 d8 ff ff       	call   801041b5 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801068c4:	83 c4 08             	add    $0x8,%esp
801068c7:	ff 75 e0             	pushl  -0x20(%ebp)
801068ca:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801068d0:	50                   	push   %eax
801068d1:	b9 00 10 00 00       	mov    $0x1000,%ecx
801068d6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801068d9:	8b 45 dc             	mov    -0x24(%ebp),%eax
801068dc:	e8 de f8 ff ff       	call   801061bf <mappages>
801068e1:	83 c4 10             	add    $0x10,%esp
801068e4:	85 c0                	test   %eax,%eax
801068e6:	78 25                	js     8010690d <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
801068e8:	81 c7 00 10 00 00    	add    $0x1000,%edi
801068ee:	e9 7c ff ff ff       	jmp    8010686f <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
801068f3:	83 ec 0c             	sub    $0xc,%esp
801068f6:	68 c4 73 10 80       	push   $0x801073c4
801068fb:	e8 48 9a ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106900:	83 ec 0c             	sub    $0xc,%esp
80106903:	68 de 73 10 80       	push   $0x801073de
80106908:	e8 3b 9a ff ff       	call   80100348 <panic>
      kfree(mem);
8010690d:	83 ec 0c             	sub    $0xc,%esp
80106910:	53                   	push   %ebx
80106911:	e8 8e b6 ff ff       	call   80101fa4 <kfree>
      goto bad;
80106916:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106919:	83 ec 0c             	sub    $0xc,%esp
8010691c:	ff 75 dc             	pushl  -0x24(%ebp)
8010691f:	e8 0c fe ff ff       	call   80106730 <freevm>
  return 0;
80106924:	83 c4 10             	add    $0x10,%esp
80106927:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
8010692e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106931:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106934:	5b                   	pop    %ebx
80106935:	5e                   	pop    %esi
80106936:	5f                   	pop    %edi
80106937:	5d                   	pop    %ebp
80106938:	c3                   	ret    

80106939 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106939:	55                   	push   %ebp
8010693a:	89 e5                	mov    %esp,%ebp
8010693c:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010693f:	b9 00 00 00 00       	mov    $0x0,%ecx
80106944:	8b 55 0c             	mov    0xc(%ebp),%edx
80106947:	8b 45 08             	mov    0x8(%ebp),%eax
8010694a:	e8 00 f8 ff ff       	call   8010614f <walkpgdir>
  if((*pte & PTE_P) == 0)
8010694f:	8b 00                	mov    (%eax),%eax
80106951:	a8 01                	test   $0x1,%al
80106953:	74 10                	je     80106965 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
80106955:	a8 04                	test   $0x4,%al
80106957:	74 13                	je     8010696c <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106959:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010695e:	05 00 00 00 80       	add    $0x80000000,%eax
}
80106963:	c9                   	leave  
80106964:	c3                   	ret    
    return 0;
80106965:	b8 00 00 00 00       	mov    $0x0,%eax
8010696a:	eb f7                	jmp    80106963 <uva2ka+0x2a>
    return 0;
8010696c:	b8 00 00 00 00       	mov    $0x0,%eax
80106971:	eb f0                	jmp    80106963 <uva2ka+0x2a>

80106973 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80106973:	55                   	push   %ebp
80106974:	89 e5                	mov    %esp,%ebp
80106976:	57                   	push   %edi
80106977:	56                   	push   %esi
80106978:	53                   	push   %ebx
80106979:	83 ec 0c             	sub    $0xc,%esp
8010697c:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010697f:	eb 25                	jmp    801069a6 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
80106981:	8b 55 0c             	mov    0xc(%ebp),%edx
80106984:	29 f2                	sub    %esi,%edx
80106986:	01 d0                	add    %edx,%eax
80106988:	83 ec 04             	sub    $0x4,%esp
8010698b:	53                   	push   %ebx
8010698c:	ff 75 10             	pushl  0x10(%ebp)
8010698f:	50                   	push   %eax
80106990:	e8 20 d8 ff ff       	call   801041b5 <memmove>
    len -= n;
80106995:	29 df                	sub    %ebx,%edi
    buf += n;
80106997:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
8010699a:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801069a0:	89 45 0c             	mov    %eax,0xc(%ebp)
801069a3:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801069a6:	85 ff                	test   %edi,%edi
801069a8:	74 2f                	je     801069d9 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801069aa:	8b 75 0c             	mov    0xc(%ebp),%esi
801069ad:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801069b3:	83 ec 08             	sub    $0x8,%esp
801069b6:	56                   	push   %esi
801069b7:	ff 75 08             	pushl  0x8(%ebp)
801069ba:	e8 7a ff ff ff       	call   80106939 <uva2ka>
    if(pa0 == 0)
801069bf:	83 c4 10             	add    $0x10,%esp
801069c2:	85 c0                	test   %eax,%eax
801069c4:	74 20                	je     801069e6 <copyout+0x73>
    n = PGSIZE - (va - va0);
801069c6:	89 f3                	mov    %esi,%ebx
801069c8:	2b 5d 0c             	sub    0xc(%ebp),%ebx
801069cb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
801069d1:	39 df                	cmp    %ebx,%edi
801069d3:	73 ac                	jae    80106981 <copyout+0xe>
      n = len;
801069d5:	89 fb                	mov    %edi,%ebx
801069d7:	eb a8                	jmp    80106981 <copyout+0xe>
  }
  return 0;
801069d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801069de:	8d 65 f4             	lea    -0xc(%ebp),%esp
801069e1:	5b                   	pop    %ebx
801069e2:	5e                   	pop    %esi
801069e3:	5f                   	pop    %edi
801069e4:	5d                   	pop    %ebp
801069e5:	c3                   	ret    
      return -1;
801069e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069eb:	eb f1                	jmp    801069de <copyout+0x6b>
