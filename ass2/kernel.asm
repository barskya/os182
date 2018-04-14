
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
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
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
80100028:	bc 30 c6 10 80       	mov    $0x8010c630,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 5d 38 10 80       	mov    $0x8010385d,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	83 ec 08             	sub    $0x8,%esp
8010003d:	68 1c 83 10 80       	push   $0x8010831c
80100042:	68 40 c6 10 80       	push   $0x8010c640
80100047:	e8 1d 4f 00 00       	call   80104f69 <initlock>
8010004c:	83 c4 10             	add    $0x10,%esp

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004f:	c7 05 8c 0d 11 80 3c 	movl   $0x80110d3c,0x80110d8c
80100056:	0d 11 80 
  bcache.head.next = &bcache.head;
80100059:	c7 05 90 0d 11 80 3c 	movl   $0x80110d3c,0x80110d90
80100060:	0d 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100063:	c7 45 f4 74 c6 10 80 	movl   $0x8010c674,-0xc(%ebp)
8010006a:	eb 47                	jmp    801000b3 <binit+0x7f>
    b->next = bcache.head.next;
8010006c:	8b 15 90 0d 11 80    	mov    0x80110d90,%edx
80100072:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100075:	89 50 54             	mov    %edx,0x54(%eax)
    b->prev = &bcache.head;
80100078:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007b:	c7 40 50 3c 0d 11 80 	movl   $0x80110d3c,0x50(%eax)
    initsleeplock(&b->lock, "buffer");
80100082:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100085:	83 c0 0c             	add    $0xc,%eax
80100088:	83 ec 08             	sub    $0x8,%esp
8010008b:	68 23 83 10 80       	push   $0x80108323
80100090:	50                   	push   %eax
80100091:	e8 76 4d 00 00       	call   80104e0c <initsleeplock>
80100096:	83 c4 10             	add    $0x10,%esp
    bcache.head.next->prev = b;
80100099:	a1 90 0d 11 80       	mov    0x80110d90,%eax
8010009e:	8b 55 f4             	mov    -0xc(%ebp),%edx
801000a1:	89 50 50             	mov    %edx,0x50(%eax)
    bcache.head.next = b;
801000a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000a7:	a3 90 0d 11 80       	mov    %eax,0x80110d90

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
801000ac:	81 45 f4 5c 02 00 00 	addl   $0x25c,-0xc(%ebp)
801000b3:	b8 3c 0d 11 80       	mov    $0x80110d3c,%eax
801000b8:	39 45 f4             	cmp    %eax,-0xc(%ebp)
801000bb:	72 af                	jb     8010006c <binit+0x38>
    b->prev = &bcache.head;
    initsleeplock(&b->lock, "buffer");
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000bd:	90                   	nop
801000be:	c9                   	leave  
801000bf:	c3                   	ret    

801000c0 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
801000c0:	55                   	push   %ebp
801000c1:	89 e5                	mov    %esp,%ebp
801000c3:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000c6:	83 ec 0c             	sub    $0xc,%esp
801000c9:	68 40 c6 10 80       	push   $0x8010c640
801000ce:	e8 b8 4e 00 00       	call   80104f8b <acquire>
801000d3:	83 c4 10             	add    $0x10,%esp

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000d6:	a1 90 0d 11 80       	mov    0x80110d90,%eax
801000db:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000de:	eb 58                	jmp    80100138 <bget+0x78>
    if(b->dev == dev && b->blockno == blockno){
801000e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e3:	8b 40 04             	mov    0x4(%eax),%eax
801000e6:	3b 45 08             	cmp    0x8(%ebp),%eax
801000e9:	75 44                	jne    8010012f <bget+0x6f>
801000eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000ee:	8b 40 08             	mov    0x8(%eax),%eax
801000f1:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000f4:	75 39                	jne    8010012f <bget+0x6f>
      b->refcnt++;
801000f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f9:	8b 40 4c             	mov    0x4c(%eax),%eax
801000fc:	8d 50 01             	lea    0x1(%eax),%edx
801000ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100102:	89 50 4c             	mov    %edx,0x4c(%eax)
      release(&bcache.lock);
80100105:	83 ec 0c             	sub    $0xc,%esp
80100108:	68 40 c6 10 80       	push   $0x8010c640
8010010d:	e8 e7 4e 00 00       	call   80104ff9 <release>
80100112:	83 c4 10             	add    $0x10,%esp
      acquiresleep(&b->lock);
80100115:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100118:	83 c0 0c             	add    $0xc,%eax
8010011b:	83 ec 0c             	sub    $0xc,%esp
8010011e:	50                   	push   %eax
8010011f:	e8 24 4d 00 00       	call   80104e48 <acquiresleep>
80100124:	83 c4 10             	add    $0x10,%esp
      return b;
80100127:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010012a:	e9 9d 00 00 00       	jmp    801001cc <bget+0x10c>
  struct buf *b;

  acquire(&bcache.lock);

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010012f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100132:	8b 40 54             	mov    0x54(%eax),%eax
80100135:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100138:	81 7d f4 3c 0d 11 80 	cmpl   $0x80110d3c,-0xc(%ebp)
8010013f:	75 9f                	jne    801000e0 <bget+0x20>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100141:	a1 8c 0d 11 80       	mov    0x80110d8c,%eax
80100146:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100149:	eb 6b                	jmp    801001b6 <bget+0xf6>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
8010014b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010014e:	8b 40 4c             	mov    0x4c(%eax),%eax
80100151:	85 c0                	test   %eax,%eax
80100153:	75 58                	jne    801001ad <bget+0xed>
80100155:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100158:	8b 00                	mov    (%eax),%eax
8010015a:	83 e0 04             	and    $0x4,%eax
8010015d:	85 c0                	test   %eax,%eax
8010015f:	75 4c                	jne    801001ad <bget+0xed>
      b->dev = dev;
80100161:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100164:	8b 55 08             	mov    0x8(%ebp),%edx
80100167:	89 50 04             	mov    %edx,0x4(%eax)
      b->blockno = blockno;
8010016a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016d:	8b 55 0c             	mov    0xc(%ebp),%edx
80100170:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = 0;
80100173:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100176:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      b->refcnt = 1;
8010017c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010017f:	c7 40 4c 01 00 00 00 	movl   $0x1,0x4c(%eax)
      release(&bcache.lock);
80100186:	83 ec 0c             	sub    $0xc,%esp
80100189:	68 40 c6 10 80       	push   $0x8010c640
8010018e:	e8 66 4e 00 00       	call   80104ff9 <release>
80100193:	83 c4 10             	add    $0x10,%esp
      acquiresleep(&b->lock);
80100196:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100199:	83 c0 0c             	add    $0xc,%eax
8010019c:	83 ec 0c             	sub    $0xc,%esp
8010019f:	50                   	push   %eax
801001a0:	e8 a3 4c 00 00       	call   80104e48 <acquiresleep>
801001a5:	83 c4 10             	add    $0x10,%esp
      return b;
801001a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001ab:	eb 1f                	jmp    801001cc <bget+0x10c>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
801001ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001b0:	8b 40 50             	mov    0x50(%eax),%eax
801001b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801001b6:	81 7d f4 3c 0d 11 80 	cmpl   $0x80110d3c,-0xc(%ebp)
801001bd:	75 8c                	jne    8010014b <bget+0x8b>
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }
  panic("bget: no buffers");
801001bf:	83 ec 0c             	sub    $0xc,%esp
801001c2:	68 2a 83 10 80       	push   $0x8010832a
801001c7:	e8 d4 03 00 00       	call   801005a0 <panic>
}
801001cc:	c9                   	leave  
801001cd:	c3                   	ret    

801001ce <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
801001ce:	55                   	push   %ebp
801001cf:	89 e5                	mov    %esp,%ebp
801001d1:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  b = bget(dev, blockno);
801001d4:	83 ec 08             	sub    $0x8,%esp
801001d7:	ff 75 0c             	pushl  0xc(%ebp)
801001da:	ff 75 08             	pushl  0x8(%ebp)
801001dd:	e8 de fe ff ff       	call   801000c0 <bget>
801001e2:	83 c4 10             	add    $0x10,%esp
801001e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((b->flags & B_VALID) == 0) {
801001e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001eb:	8b 00                	mov    (%eax),%eax
801001ed:	83 e0 02             	and    $0x2,%eax
801001f0:	85 c0                	test   %eax,%eax
801001f2:	75 0e                	jne    80100202 <bread+0x34>
    iderw(b);
801001f4:	83 ec 0c             	sub    $0xc,%esp
801001f7:	ff 75 f4             	pushl  -0xc(%ebp)
801001fa:	e8 5d 27 00 00       	call   8010295c <iderw>
801001ff:	83 c4 10             	add    $0x10,%esp
  }
  return b;
80100202:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80100205:	c9                   	leave  
80100206:	c3                   	ret    

80100207 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
80100207:	55                   	push   %ebp
80100208:	89 e5                	mov    %esp,%ebp
8010020a:	83 ec 08             	sub    $0x8,%esp
  if(!holdingsleep(&b->lock))
8010020d:	8b 45 08             	mov    0x8(%ebp),%eax
80100210:	83 c0 0c             	add    $0xc,%eax
80100213:	83 ec 0c             	sub    $0xc,%esp
80100216:	50                   	push   %eax
80100217:	e8 de 4c 00 00       	call   80104efa <holdingsleep>
8010021c:	83 c4 10             	add    $0x10,%esp
8010021f:	85 c0                	test   %eax,%eax
80100221:	75 0d                	jne    80100230 <bwrite+0x29>
    panic("bwrite");
80100223:	83 ec 0c             	sub    $0xc,%esp
80100226:	68 3b 83 10 80       	push   $0x8010833b
8010022b:	e8 70 03 00 00       	call   801005a0 <panic>
  b->flags |= B_DIRTY;
80100230:	8b 45 08             	mov    0x8(%ebp),%eax
80100233:	8b 00                	mov    (%eax),%eax
80100235:	83 c8 04             	or     $0x4,%eax
80100238:	89 c2                	mov    %eax,%edx
8010023a:	8b 45 08             	mov    0x8(%ebp),%eax
8010023d:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010023f:	83 ec 0c             	sub    $0xc,%esp
80100242:	ff 75 08             	pushl  0x8(%ebp)
80100245:	e8 12 27 00 00       	call   8010295c <iderw>
8010024a:	83 c4 10             	add    $0x10,%esp
}
8010024d:	90                   	nop
8010024e:	c9                   	leave  
8010024f:	c3                   	ret    

80100250 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100250:	55                   	push   %ebp
80100251:	89 e5                	mov    %esp,%ebp
80100253:	83 ec 08             	sub    $0x8,%esp
  if(!holdingsleep(&b->lock))
80100256:	8b 45 08             	mov    0x8(%ebp),%eax
80100259:	83 c0 0c             	add    $0xc,%eax
8010025c:	83 ec 0c             	sub    $0xc,%esp
8010025f:	50                   	push   %eax
80100260:	e8 95 4c 00 00       	call   80104efa <holdingsleep>
80100265:	83 c4 10             	add    $0x10,%esp
80100268:	85 c0                	test   %eax,%eax
8010026a:	75 0d                	jne    80100279 <brelse+0x29>
    panic("brelse");
8010026c:	83 ec 0c             	sub    $0xc,%esp
8010026f:	68 42 83 10 80       	push   $0x80108342
80100274:	e8 27 03 00 00       	call   801005a0 <panic>

  releasesleep(&b->lock);
80100279:	8b 45 08             	mov    0x8(%ebp),%eax
8010027c:	83 c0 0c             	add    $0xc,%eax
8010027f:	83 ec 0c             	sub    $0xc,%esp
80100282:	50                   	push   %eax
80100283:	e8 24 4c 00 00       	call   80104eac <releasesleep>
80100288:	83 c4 10             	add    $0x10,%esp

  acquire(&bcache.lock);
8010028b:	83 ec 0c             	sub    $0xc,%esp
8010028e:	68 40 c6 10 80       	push   $0x8010c640
80100293:	e8 f3 4c 00 00       	call   80104f8b <acquire>
80100298:	83 c4 10             	add    $0x10,%esp
  b->refcnt--;
8010029b:	8b 45 08             	mov    0x8(%ebp),%eax
8010029e:	8b 40 4c             	mov    0x4c(%eax),%eax
801002a1:	8d 50 ff             	lea    -0x1(%eax),%edx
801002a4:	8b 45 08             	mov    0x8(%ebp),%eax
801002a7:	89 50 4c             	mov    %edx,0x4c(%eax)
  if (b->refcnt == 0) {
801002aa:	8b 45 08             	mov    0x8(%ebp),%eax
801002ad:	8b 40 4c             	mov    0x4c(%eax),%eax
801002b0:	85 c0                	test   %eax,%eax
801002b2:	75 47                	jne    801002fb <brelse+0xab>
    // no one is waiting for it.
    b->next->prev = b->prev;
801002b4:	8b 45 08             	mov    0x8(%ebp),%eax
801002b7:	8b 40 54             	mov    0x54(%eax),%eax
801002ba:	8b 55 08             	mov    0x8(%ebp),%edx
801002bd:	8b 52 50             	mov    0x50(%edx),%edx
801002c0:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
801002c3:	8b 45 08             	mov    0x8(%ebp),%eax
801002c6:	8b 40 50             	mov    0x50(%eax),%eax
801002c9:	8b 55 08             	mov    0x8(%ebp),%edx
801002cc:	8b 52 54             	mov    0x54(%edx),%edx
801002cf:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
801002d2:	8b 15 90 0d 11 80    	mov    0x80110d90,%edx
801002d8:	8b 45 08             	mov    0x8(%ebp),%eax
801002db:	89 50 54             	mov    %edx,0x54(%eax)
    b->prev = &bcache.head;
801002de:	8b 45 08             	mov    0x8(%ebp),%eax
801002e1:	c7 40 50 3c 0d 11 80 	movl   $0x80110d3c,0x50(%eax)
    bcache.head.next->prev = b;
801002e8:	a1 90 0d 11 80       	mov    0x80110d90,%eax
801002ed:	8b 55 08             	mov    0x8(%ebp),%edx
801002f0:	89 50 50             	mov    %edx,0x50(%eax)
    bcache.head.next = b;
801002f3:	8b 45 08             	mov    0x8(%ebp),%eax
801002f6:	a3 90 0d 11 80       	mov    %eax,0x80110d90
  }
  
  release(&bcache.lock);
801002fb:	83 ec 0c             	sub    $0xc,%esp
801002fe:	68 40 c6 10 80       	push   $0x8010c640
80100303:	e8 f1 4c 00 00       	call   80104ff9 <release>
80100308:	83 c4 10             	add    $0x10,%esp
}
8010030b:	90                   	nop
8010030c:	c9                   	leave  
8010030d:	c3                   	ret    

8010030e <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010030e:	55                   	push   %ebp
8010030f:	89 e5                	mov    %esp,%ebp
80100311:	83 ec 14             	sub    $0x14,%esp
80100314:	8b 45 08             	mov    0x8(%ebp),%eax
80100317:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010031b:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010031f:	89 c2                	mov    %eax,%edx
80100321:	ec                   	in     (%dx),%al
80100322:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80100325:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80100329:	c9                   	leave  
8010032a:	c3                   	ret    

8010032b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010032b:	55                   	push   %ebp
8010032c:	89 e5                	mov    %esp,%ebp
8010032e:	83 ec 08             	sub    $0x8,%esp
80100331:	8b 55 08             	mov    0x8(%ebp),%edx
80100334:	8b 45 0c             	mov    0xc(%ebp),%eax
80100337:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010033b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010033e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80100342:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80100346:	ee                   	out    %al,(%dx)
}
80100347:	90                   	nop
80100348:	c9                   	leave  
80100349:	c3                   	ret    

8010034a <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
8010034a:	55                   	push   %ebp
8010034b:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
8010034d:	fa                   	cli    
}
8010034e:	90                   	nop
8010034f:	5d                   	pop    %ebp
80100350:	c3                   	ret    

80100351 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
80100351:	55                   	push   %ebp
80100352:	89 e5                	mov    %esp,%ebp
80100354:	53                   	push   %ebx
80100355:	83 ec 24             	sub    $0x24,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100358:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010035c:	74 1c                	je     8010037a <printint+0x29>
8010035e:	8b 45 08             	mov    0x8(%ebp),%eax
80100361:	c1 e8 1f             	shr    $0x1f,%eax
80100364:	0f b6 c0             	movzbl %al,%eax
80100367:	89 45 10             	mov    %eax,0x10(%ebp)
8010036a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010036e:	74 0a                	je     8010037a <printint+0x29>
    x = -xx;
80100370:	8b 45 08             	mov    0x8(%ebp),%eax
80100373:	f7 d8                	neg    %eax
80100375:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100378:	eb 06                	jmp    80100380 <printint+0x2f>
  else
    x = xx;
8010037a:	8b 45 08             	mov    0x8(%ebp),%eax
8010037d:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100380:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100387:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010038a:	8d 41 01             	lea    0x1(%ecx),%eax
8010038d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100390:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80100393:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100396:	ba 00 00 00 00       	mov    $0x0,%edx
8010039b:	f7 f3                	div    %ebx
8010039d:	89 d0                	mov    %edx,%eax
8010039f:	0f b6 80 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%eax
801003a6:	88 44 0d e0          	mov    %al,-0x20(%ebp,%ecx,1)
  }while((x /= base) != 0);
801003aa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801003ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801003b0:	ba 00 00 00 00       	mov    $0x0,%edx
801003b5:	f7 f3                	div    %ebx
801003b7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801003ba:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801003be:	75 c7                	jne    80100387 <printint+0x36>

  if(sign)
801003c0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801003c4:	74 2a                	je     801003f0 <printint+0x9f>
    buf[i++] = '-';
801003c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801003c9:	8d 50 01             	lea    0x1(%eax),%edx
801003cc:	89 55 f4             	mov    %edx,-0xc(%ebp)
801003cf:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
801003d4:	eb 1a                	jmp    801003f0 <printint+0x9f>
    consputc(buf[i]);
801003d6:	8d 55 e0             	lea    -0x20(%ebp),%edx
801003d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801003dc:	01 d0                	add    %edx,%eax
801003de:	0f b6 00             	movzbl (%eax),%eax
801003e1:	0f be c0             	movsbl %al,%eax
801003e4:	83 ec 0c             	sub    $0xc,%esp
801003e7:	50                   	push   %eax
801003e8:	e8 d8 03 00 00       	call   801007c5 <consputc>
801003ed:	83 c4 10             	add    $0x10,%esp
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
801003f0:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
801003f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801003f8:	79 dc                	jns    801003d6 <printint+0x85>
    consputc(buf[i]);
}
801003fa:	90                   	nop
801003fb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801003fe:	c9                   	leave  
801003ff:	c3                   	ret    

80100400 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
80100400:	55                   	push   %ebp
80100401:	89 e5                	mov    %esp,%ebp
80100403:	83 ec 28             	sub    $0x28,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
80100406:	a1 d4 b5 10 80       	mov    0x8010b5d4,%eax
8010040b:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
8010040e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80100412:	74 10                	je     80100424 <cprintf+0x24>
    acquire(&cons.lock);
80100414:	83 ec 0c             	sub    $0xc,%esp
80100417:	68 a0 b5 10 80       	push   $0x8010b5a0
8010041c:	e8 6a 4b 00 00       	call   80104f8b <acquire>
80100421:	83 c4 10             	add    $0x10,%esp

  if (fmt == 0)
80100424:	8b 45 08             	mov    0x8(%ebp),%eax
80100427:	85 c0                	test   %eax,%eax
80100429:	75 0d                	jne    80100438 <cprintf+0x38>
    panic("null fmt");
8010042b:	83 ec 0c             	sub    $0xc,%esp
8010042e:	68 49 83 10 80       	push   $0x80108349
80100433:	e8 68 01 00 00       	call   801005a0 <panic>

  argp = (uint*)(void*)(&fmt + 1);
80100438:	8d 45 0c             	lea    0xc(%ebp),%eax
8010043b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
8010043e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100445:	e9 1a 01 00 00       	jmp    80100564 <cprintf+0x164>
    if(c != '%'){
8010044a:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
8010044e:	74 13                	je     80100463 <cprintf+0x63>
      consputc(c);
80100450:	83 ec 0c             	sub    $0xc,%esp
80100453:	ff 75 e4             	pushl  -0x1c(%ebp)
80100456:	e8 6a 03 00 00       	call   801007c5 <consputc>
8010045b:	83 c4 10             	add    $0x10,%esp
      continue;
8010045e:	e9 fd 00 00 00       	jmp    80100560 <cprintf+0x160>
    }
    c = fmt[++i] & 0xff;
80100463:	8b 55 08             	mov    0x8(%ebp),%edx
80100466:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010046a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010046d:	01 d0                	add    %edx,%eax
8010046f:	0f b6 00             	movzbl (%eax),%eax
80100472:	0f be c0             	movsbl %al,%eax
80100475:	25 ff 00 00 00       	and    $0xff,%eax
8010047a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
8010047d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100481:	0f 84 ff 00 00 00    	je     80100586 <cprintf+0x186>
      break;
    switch(c){
80100487:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010048a:	83 f8 70             	cmp    $0x70,%eax
8010048d:	74 47                	je     801004d6 <cprintf+0xd6>
8010048f:	83 f8 70             	cmp    $0x70,%eax
80100492:	7f 13                	jg     801004a7 <cprintf+0xa7>
80100494:	83 f8 25             	cmp    $0x25,%eax
80100497:	0f 84 98 00 00 00    	je     80100535 <cprintf+0x135>
8010049d:	83 f8 64             	cmp    $0x64,%eax
801004a0:	74 14                	je     801004b6 <cprintf+0xb6>
801004a2:	e9 9d 00 00 00       	jmp    80100544 <cprintf+0x144>
801004a7:	83 f8 73             	cmp    $0x73,%eax
801004aa:	74 47                	je     801004f3 <cprintf+0xf3>
801004ac:	83 f8 78             	cmp    $0x78,%eax
801004af:	74 25                	je     801004d6 <cprintf+0xd6>
801004b1:	e9 8e 00 00 00       	jmp    80100544 <cprintf+0x144>
    case 'd':
      printint(*argp++, 10, 1);
801004b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004b9:	8d 50 04             	lea    0x4(%eax),%edx
801004bc:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004bf:	8b 00                	mov    (%eax),%eax
801004c1:	83 ec 04             	sub    $0x4,%esp
801004c4:	6a 01                	push   $0x1
801004c6:	6a 0a                	push   $0xa
801004c8:	50                   	push   %eax
801004c9:	e8 83 fe ff ff       	call   80100351 <printint>
801004ce:	83 c4 10             	add    $0x10,%esp
      break;
801004d1:	e9 8a 00 00 00       	jmp    80100560 <cprintf+0x160>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
801004d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004d9:	8d 50 04             	lea    0x4(%eax),%edx
801004dc:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004df:	8b 00                	mov    (%eax),%eax
801004e1:	83 ec 04             	sub    $0x4,%esp
801004e4:	6a 00                	push   $0x0
801004e6:	6a 10                	push   $0x10
801004e8:	50                   	push   %eax
801004e9:	e8 63 fe ff ff       	call   80100351 <printint>
801004ee:	83 c4 10             	add    $0x10,%esp
      break;
801004f1:	eb 6d                	jmp    80100560 <cprintf+0x160>
    case 's':
      if((s = (char*)*argp++) == 0)
801004f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004f6:	8d 50 04             	lea    0x4(%eax),%edx
801004f9:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004fc:	8b 00                	mov    (%eax),%eax
801004fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100501:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80100505:	75 22                	jne    80100529 <cprintf+0x129>
        s = "(null)";
80100507:	c7 45 ec 52 83 10 80 	movl   $0x80108352,-0x14(%ebp)
      for(; *s; s++)
8010050e:	eb 19                	jmp    80100529 <cprintf+0x129>
        consputc(*s);
80100510:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100513:	0f b6 00             	movzbl (%eax),%eax
80100516:	0f be c0             	movsbl %al,%eax
80100519:	83 ec 0c             	sub    $0xc,%esp
8010051c:	50                   	push   %eax
8010051d:	e8 a3 02 00 00       	call   801007c5 <consputc>
80100522:	83 c4 10             	add    $0x10,%esp
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
80100525:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100529:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010052c:	0f b6 00             	movzbl (%eax),%eax
8010052f:	84 c0                	test   %al,%al
80100531:	75 dd                	jne    80100510 <cprintf+0x110>
        consputc(*s);
      break;
80100533:	eb 2b                	jmp    80100560 <cprintf+0x160>
    case '%':
      consputc('%');
80100535:	83 ec 0c             	sub    $0xc,%esp
80100538:	6a 25                	push   $0x25
8010053a:	e8 86 02 00 00       	call   801007c5 <consputc>
8010053f:	83 c4 10             	add    $0x10,%esp
      break;
80100542:	eb 1c                	jmp    80100560 <cprintf+0x160>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
80100544:	83 ec 0c             	sub    $0xc,%esp
80100547:	6a 25                	push   $0x25
80100549:	e8 77 02 00 00       	call   801007c5 <consputc>
8010054e:	83 c4 10             	add    $0x10,%esp
      consputc(c);
80100551:	83 ec 0c             	sub    $0xc,%esp
80100554:	ff 75 e4             	pushl  -0x1c(%ebp)
80100557:	e8 69 02 00 00       	call   801007c5 <consputc>
8010055c:	83 c4 10             	add    $0x10,%esp
      break;
8010055f:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100560:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100564:	8b 55 08             	mov    0x8(%ebp),%edx
80100567:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010056a:	01 d0                	add    %edx,%eax
8010056c:	0f b6 00             	movzbl (%eax),%eax
8010056f:	0f be c0             	movsbl %al,%eax
80100572:	25 ff 00 00 00       	and    $0xff,%eax
80100577:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010057a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010057e:	0f 85 c6 fe ff ff    	jne    8010044a <cprintf+0x4a>
80100584:	eb 01                	jmp    80100587 <cprintf+0x187>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
80100586:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
80100587:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010058b:	74 10                	je     8010059d <cprintf+0x19d>
    release(&cons.lock);
8010058d:	83 ec 0c             	sub    $0xc,%esp
80100590:	68 a0 b5 10 80       	push   $0x8010b5a0
80100595:	e8 5f 4a 00 00       	call   80104ff9 <release>
8010059a:	83 c4 10             	add    $0x10,%esp
}
8010059d:	90                   	nop
8010059e:	c9                   	leave  
8010059f:	c3                   	ret    

801005a0 <panic>:

void
panic(char *s)
{
801005a0:	55                   	push   %ebp
801005a1:	89 e5                	mov    %esp,%ebp
801005a3:	83 ec 38             	sub    $0x38,%esp
  int i;
  uint pcs[10];

  cli();
801005a6:	e8 9f fd ff ff       	call   8010034a <cli>
  cons.locking = 0;
801005ab:	c7 05 d4 b5 10 80 00 	movl   $0x0,0x8010b5d4
801005b2:	00 00 00 
  // use lapiccpunum so that we can call panic from mycpu()
  cprintf("lapicid %d: panic: ", lapicid());
801005b5:	e8 31 2a 00 00       	call   80102feb <lapicid>
801005ba:	83 ec 08             	sub    $0x8,%esp
801005bd:	50                   	push   %eax
801005be:	68 59 83 10 80       	push   $0x80108359
801005c3:	e8 38 fe ff ff       	call   80100400 <cprintf>
801005c8:	83 c4 10             	add    $0x10,%esp
  cprintf(s);
801005cb:	8b 45 08             	mov    0x8(%ebp),%eax
801005ce:	83 ec 0c             	sub    $0xc,%esp
801005d1:	50                   	push   %eax
801005d2:	e8 29 fe ff ff       	call   80100400 <cprintf>
801005d7:	83 c4 10             	add    $0x10,%esp
  cprintf("\n");
801005da:	83 ec 0c             	sub    $0xc,%esp
801005dd:	68 6d 83 10 80       	push   $0x8010836d
801005e2:	e8 19 fe ff ff       	call   80100400 <cprintf>
801005e7:	83 c4 10             	add    $0x10,%esp
  getcallerpcs(&s, pcs);
801005ea:	83 ec 08             	sub    $0x8,%esp
801005ed:	8d 45 cc             	lea    -0x34(%ebp),%eax
801005f0:	50                   	push   %eax
801005f1:	8d 45 08             	lea    0x8(%ebp),%eax
801005f4:	50                   	push   %eax
801005f5:	e8 51 4a 00 00       	call   8010504b <getcallerpcs>
801005fa:	83 c4 10             	add    $0x10,%esp
  for(i=0; i<10; i++)
801005fd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100604:	eb 1c                	jmp    80100622 <panic+0x82>
    cprintf(" %p", pcs[i]);
80100606:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100609:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
8010060d:	83 ec 08             	sub    $0x8,%esp
80100610:	50                   	push   %eax
80100611:	68 6f 83 10 80       	push   $0x8010836f
80100616:	e8 e5 fd ff ff       	call   80100400 <cprintf>
8010061b:	83 c4 10             	add    $0x10,%esp
  // use lapiccpunum so that we can call panic from mycpu()
  cprintf("lapicid %d: panic: ", lapicid());
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
8010061e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100622:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80100626:	7e de                	jle    80100606 <panic+0x66>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
80100628:	c7 05 80 b5 10 80 01 	movl   $0x1,0x8010b580
8010062f:	00 00 00 
  for(;;)
    ;
80100632:	eb fe                	jmp    80100632 <panic+0x92>

80100634 <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
80100634:	55                   	push   %ebp
80100635:	89 e5                	mov    %esp,%ebp
80100637:	83 ec 18             	sub    $0x18,%esp
  int pos;

  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
8010063a:	6a 0e                	push   $0xe
8010063c:	68 d4 03 00 00       	push   $0x3d4
80100641:	e8 e5 fc ff ff       	call   8010032b <outb>
80100646:	83 c4 08             	add    $0x8,%esp
  pos = inb(CRTPORT+1) << 8;
80100649:	68 d5 03 00 00       	push   $0x3d5
8010064e:	e8 bb fc ff ff       	call   8010030e <inb>
80100653:	83 c4 04             	add    $0x4,%esp
80100656:	0f b6 c0             	movzbl %al,%eax
80100659:	c1 e0 08             	shl    $0x8,%eax
8010065c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
8010065f:	6a 0f                	push   $0xf
80100661:	68 d4 03 00 00       	push   $0x3d4
80100666:	e8 c0 fc ff ff       	call   8010032b <outb>
8010066b:	83 c4 08             	add    $0x8,%esp
  pos |= inb(CRTPORT+1);
8010066e:	68 d5 03 00 00       	push   $0x3d5
80100673:	e8 96 fc ff ff       	call   8010030e <inb>
80100678:	83 c4 04             	add    $0x4,%esp
8010067b:	0f b6 c0             	movzbl %al,%eax
8010067e:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
80100681:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100685:	75 30                	jne    801006b7 <cgaputc+0x83>
    pos += 80 - pos%80;
80100687:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010068a:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010068f:	89 c8                	mov    %ecx,%eax
80100691:	f7 ea                	imul   %edx
80100693:	c1 fa 05             	sar    $0x5,%edx
80100696:	89 c8                	mov    %ecx,%eax
80100698:	c1 f8 1f             	sar    $0x1f,%eax
8010069b:	29 c2                	sub    %eax,%edx
8010069d:	89 d0                	mov    %edx,%eax
8010069f:	c1 e0 02             	shl    $0x2,%eax
801006a2:	01 d0                	add    %edx,%eax
801006a4:	c1 e0 04             	shl    $0x4,%eax
801006a7:	29 c1                	sub    %eax,%ecx
801006a9:	89 ca                	mov    %ecx,%edx
801006ab:	b8 50 00 00 00       	mov    $0x50,%eax
801006b0:	29 d0                	sub    %edx,%eax
801006b2:	01 45 f4             	add    %eax,-0xc(%ebp)
801006b5:	eb 34                	jmp    801006eb <cgaputc+0xb7>
  else if(c == BACKSPACE){
801006b7:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
801006be:	75 0c                	jne    801006cc <cgaputc+0x98>
    if(pos > 0) --pos;
801006c0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801006c4:	7e 25                	jle    801006eb <cgaputc+0xb7>
801006c6:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
801006ca:	eb 1f                	jmp    801006eb <cgaputc+0xb7>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
801006cc:	8b 0d 00 90 10 80    	mov    0x80109000,%ecx
801006d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006d5:	8d 50 01             	lea    0x1(%eax),%edx
801006d8:	89 55 f4             	mov    %edx,-0xc(%ebp)
801006db:	01 c0                	add    %eax,%eax
801006dd:	01 c8                	add    %ecx,%eax
801006df:	8b 55 08             	mov    0x8(%ebp),%edx
801006e2:	0f b6 d2             	movzbl %dl,%edx
801006e5:	80 ce 07             	or     $0x7,%dh
801006e8:	66 89 10             	mov    %dx,(%eax)

  if(pos < 0 || pos > 25*80)
801006eb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801006ef:	78 09                	js     801006fa <cgaputc+0xc6>
801006f1:	81 7d f4 d0 07 00 00 	cmpl   $0x7d0,-0xc(%ebp)
801006f8:	7e 0d                	jle    80100707 <cgaputc+0xd3>
    panic("pos under/overflow");
801006fa:	83 ec 0c             	sub    $0xc,%esp
801006fd:	68 73 83 10 80       	push   $0x80108373
80100702:	e8 99 fe ff ff       	call   801005a0 <panic>

  if((pos/80) >= 24){  // Scroll up.
80100707:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
8010070e:	7e 4c                	jle    8010075c <cgaputc+0x128>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100710:	a1 00 90 10 80       	mov    0x80109000,%eax
80100715:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010071b:	a1 00 90 10 80       	mov    0x80109000,%eax
80100720:	83 ec 04             	sub    $0x4,%esp
80100723:	68 60 0e 00 00       	push   $0xe60
80100728:	52                   	push   %edx
80100729:	50                   	push   %eax
8010072a:	e8 92 4b 00 00       	call   801052c1 <memmove>
8010072f:	83 c4 10             	add    $0x10,%esp
    pos -= 80;
80100732:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
80100736:	b8 80 07 00 00       	mov    $0x780,%eax
8010073b:	2b 45 f4             	sub    -0xc(%ebp),%eax
8010073e:	8d 14 00             	lea    (%eax,%eax,1),%edx
80100741:	a1 00 90 10 80       	mov    0x80109000,%eax
80100746:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100749:	01 c9                	add    %ecx,%ecx
8010074b:	01 c8                	add    %ecx,%eax
8010074d:	83 ec 04             	sub    $0x4,%esp
80100750:	52                   	push   %edx
80100751:	6a 00                	push   $0x0
80100753:	50                   	push   %eax
80100754:	e8 a9 4a 00 00       	call   80105202 <memset>
80100759:	83 c4 10             	add    $0x10,%esp
  }

  outb(CRTPORT, 14);
8010075c:	83 ec 08             	sub    $0x8,%esp
8010075f:	6a 0e                	push   $0xe
80100761:	68 d4 03 00 00       	push   $0x3d4
80100766:	e8 c0 fb ff ff       	call   8010032b <outb>
8010076b:	83 c4 10             	add    $0x10,%esp
  outb(CRTPORT+1, pos>>8);
8010076e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100771:	c1 f8 08             	sar    $0x8,%eax
80100774:	0f b6 c0             	movzbl %al,%eax
80100777:	83 ec 08             	sub    $0x8,%esp
8010077a:	50                   	push   %eax
8010077b:	68 d5 03 00 00       	push   $0x3d5
80100780:	e8 a6 fb ff ff       	call   8010032b <outb>
80100785:	83 c4 10             	add    $0x10,%esp
  outb(CRTPORT, 15);
80100788:	83 ec 08             	sub    $0x8,%esp
8010078b:	6a 0f                	push   $0xf
8010078d:	68 d4 03 00 00       	push   $0x3d4
80100792:	e8 94 fb ff ff       	call   8010032b <outb>
80100797:	83 c4 10             	add    $0x10,%esp
  outb(CRTPORT+1, pos);
8010079a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010079d:	0f b6 c0             	movzbl %al,%eax
801007a0:	83 ec 08             	sub    $0x8,%esp
801007a3:	50                   	push   %eax
801007a4:	68 d5 03 00 00       	push   $0x3d5
801007a9:	e8 7d fb ff ff       	call   8010032b <outb>
801007ae:	83 c4 10             	add    $0x10,%esp
  crt[pos] = ' ' | 0x0700;
801007b1:	a1 00 90 10 80       	mov    0x80109000,%eax
801007b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801007b9:	01 d2                	add    %edx,%edx
801007bb:	01 d0                	add    %edx,%eax
801007bd:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
801007c2:	90                   	nop
801007c3:	c9                   	leave  
801007c4:	c3                   	ret    

801007c5 <consputc>:

void
consputc(int c)
{
801007c5:	55                   	push   %ebp
801007c6:	89 e5                	mov    %esp,%ebp
801007c8:	83 ec 08             	sub    $0x8,%esp
  if(panicked){
801007cb:	a1 80 b5 10 80       	mov    0x8010b580,%eax
801007d0:	85 c0                	test   %eax,%eax
801007d2:	74 07                	je     801007db <consputc+0x16>
    cli();
801007d4:	e8 71 fb ff ff       	call   8010034a <cli>
    for(;;)
      ;
801007d9:	eb fe                	jmp    801007d9 <consputc+0x14>
  }

  if(c == BACKSPACE){
801007db:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
801007e2:	75 29                	jne    8010080d <consputc+0x48>
    uartputc('\b'); uartputc(' '); uartputc('\b');
801007e4:	83 ec 0c             	sub    $0xc,%esp
801007e7:	6a 08                	push   $0x8
801007e9:	e8 ed 62 00 00       	call   80106adb <uartputc>
801007ee:	83 c4 10             	add    $0x10,%esp
801007f1:	83 ec 0c             	sub    $0xc,%esp
801007f4:	6a 20                	push   $0x20
801007f6:	e8 e0 62 00 00       	call   80106adb <uartputc>
801007fb:	83 c4 10             	add    $0x10,%esp
801007fe:	83 ec 0c             	sub    $0xc,%esp
80100801:	6a 08                	push   $0x8
80100803:	e8 d3 62 00 00       	call   80106adb <uartputc>
80100808:	83 c4 10             	add    $0x10,%esp
8010080b:	eb 0e                	jmp    8010081b <consputc+0x56>
  } else
    uartputc(c);
8010080d:	83 ec 0c             	sub    $0xc,%esp
80100810:	ff 75 08             	pushl  0x8(%ebp)
80100813:	e8 c3 62 00 00       	call   80106adb <uartputc>
80100818:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
8010081b:	83 ec 0c             	sub    $0xc,%esp
8010081e:	ff 75 08             	pushl  0x8(%ebp)
80100821:	e8 0e fe ff ff       	call   80100634 <cgaputc>
80100826:	83 c4 10             	add    $0x10,%esp
}
80100829:	90                   	nop
8010082a:	c9                   	leave  
8010082b:	c3                   	ret    

8010082c <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
8010082c:	55                   	push   %ebp
8010082d:	89 e5                	mov    %esp,%ebp
8010082f:	83 ec 18             	sub    $0x18,%esp
  int c, doprocdump = 0;
80100832:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&cons.lock);
80100839:	83 ec 0c             	sub    $0xc,%esp
8010083c:	68 a0 b5 10 80       	push   $0x8010b5a0
80100841:	e8 45 47 00 00       	call   80104f8b <acquire>
80100846:	83 c4 10             	add    $0x10,%esp
  while((c = getc()) >= 0){
80100849:	e9 44 01 00 00       	jmp    80100992 <consoleintr+0x166>
    switch(c){
8010084e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100851:	83 f8 10             	cmp    $0x10,%eax
80100854:	74 1e                	je     80100874 <consoleintr+0x48>
80100856:	83 f8 10             	cmp    $0x10,%eax
80100859:	7f 0a                	jg     80100865 <consoleintr+0x39>
8010085b:	83 f8 08             	cmp    $0x8,%eax
8010085e:	74 6b                	je     801008cb <consoleintr+0x9f>
80100860:	e9 9b 00 00 00       	jmp    80100900 <consoleintr+0xd4>
80100865:	83 f8 15             	cmp    $0x15,%eax
80100868:	74 33                	je     8010089d <consoleintr+0x71>
8010086a:	83 f8 7f             	cmp    $0x7f,%eax
8010086d:	74 5c                	je     801008cb <consoleintr+0x9f>
8010086f:	e9 8c 00 00 00       	jmp    80100900 <consoleintr+0xd4>
    case C('P'):  // Process listing.
      // procdump() locks cons.lock indirectly; invoke later
      doprocdump = 1;
80100874:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
      break;
8010087b:	e9 12 01 00 00       	jmp    80100992 <consoleintr+0x166>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
80100880:	a1 28 10 11 80       	mov    0x80111028,%eax
80100885:	83 e8 01             	sub    $0x1,%eax
80100888:	a3 28 10 11 80       	mov    %eax,0x80111028
        consputc(BACKSPACE);
8010088d:	83 ec 0c             	sub    $0xc,%esp
80100890:	68 00 01 00 00       	push   $0x100
80100895:	e8 2b ff ff ff       	call   801007c5 <consputc>
8010089a:	83 c4 10             	add    $0x10,%esp
    case C('P'):  // Process listing.
      // procdump() locks cons.lock indirectly; invoke later
      doprocdump = 1;
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010089d:	8b 15 28 10 11 80    	mov    0x80111028,%edx
801008a3:	a1 24 10 11 80       	mov    0x80111024,%eax
801008a8:	39 c2                	cmp    %eax,%edx
801008aa:	0f 84 e2 00 00 00    	je     80100992 <consoleintr+0x166>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
801008b0:	a1 28 10 11 80       	mov    0x80111028,%eax
801008b5:	83 e8 01             	sub    $0x1,%eax
801008b8:	83 e0 7f             	and    $0x7f,%eax
801008bb:	0f b6 80 a0 0f 11 80 	movzbl -0x7feef060(%eax),%eax
    case C('P'):  // Process listing.
      // procdump() locks cons.lock indirectly; invoke later
      doprocdump = 1;
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
801008c2:	3c 0a                	cmp    $0xa,%al
801008c4:	75 ba                	jne    80100880 <consoleintr+0x54>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
801008c6:	e9 c7 00 00 00       	jmp    80100992 <consoleintr+0x166>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
801008cb:	8b 15 28 10 11 80    	mov    0x80111028,%edx
801008d1:	a1 24 10 11 80       	mov    0x80111024,%eax
801008d6:	39 c2                	cmp    %eax,%edx
801008d8:	0f 84 b4 00 00 00    	je     80100992 <consoleintr+0x166>
        input.e--;
801008de:	a1 28 10 11 80       	mov    0x80111028,%eax
801008e3:	83 e8 01             	sub    $0x1,%eax
801008e6:	a3 28 10 11 80       	mov    %eax,0x80111028
        consputc(BACKSPACE);
801008eb:	83 ec 0c             	sub    $0xc,%esp
801008ee:	68 00 01 00 00       	push   $0x100
801008f3:	e8 cd fe ff ff       	call   801007c5 <consputc>
801008f8:	83 c4 10             	add    $0x10,%esp
      }
      break;
801008fb:	e9 92 00 00 00       	jmp    80100992 <consoleintr+0x166>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100900:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100904:	0f 84 87 00 00 00    	je     80100991 <consoleintr+0x165>
8010090a:	8b 15 28 10 11 80    	mov    0x80111028,%edx
80100910:	a1 20 10 11 80       	mov    0x80111020,%eax
80100915:	29 c2                	sub    %eax,%edx
80100917:	89 d0                	mov    %edx,%eax
80100919:	83 f8 7f             	cmp    $0x7f,%eax
8010091c:	77 73                	ja     80100991 <consoleintr+0x165>
        c = (c == '\r') ? '\n' : c;
8010091e:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80100922:	74 05                	je     80100929 <consoleintr+0xfd>
80100924:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100927:	eb 05                	jmp    8010092e <consoleintr+0x102>
80100929:	b8 0a 00 00 00       	mov    $0xa,%eax
8010092e:	89 45 f0             	mov    %eax,-0x10(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
80100931:	a1 28 10 11 80       	mov    0x80111028,%eax
80100936:	8d 50 01             	lea    0x1(%eax),%edx
80100939:	89 15 28 10 11 80    	mov    %edx,0x80111028
8010093f:	83 e0 7f             	and    $0x7f,%eax
80100942:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100945:	88 90 a0 0f 11 80    	mov    %dl,-0x7feef060(%eax)
        consputc(c);
8010094b:	83 ec 0c             	sub    $0xc,%esp
8010094e:	ff 75 f0             	pushl  -0x10(%ebp)
80100951:	e8 6f fe ff ff       	call   801007c5 <consputc>
80100956:	83 c4 10             	add    $0x10,%esp
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
80100959:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
8010095d:	74 18                	je     80100977 <consoleintr+0x14b>
8010095f:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100963:	74 12                	je     80100977 <consoleintr+0x14b>
80100965:	a1 28 10 11 80       	mov    0x80111028,%eax
8010096a:	8b 15 20 10 11 80    	mov    0x80111020,%edx
80100970:	83 ea 80             	sub    $0xffffff80,%edx
80100973:	39 d0                	cmp    %edx,%eax
80100975:	75 1a                	jne    80100991 <consoleintr+0x165>
          input.w = input.e;
80100977:	a1 28 10 11 80       	mov    0x80111028,%eax
8010097c:	a3 24 10 11 80       	mov    %eax,0x80111024
          wakeup(&input.r);
80100981:	83 ec 0c             	sub    $0xc,%esp
80100984:	68 20 10 11 80       	push   $0x80111020
80100989:	e8 ca 42 00 00       	call   80104c58 <wakeup>
8010098e:	83 c4 10             	add    $0x10,%esp
        }
      }
      break;
80100991:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c, doprocdump = 0;

  acquire(&cons.lock);
  while((c = getc()) >= 0){
80100992:	8b 45 08             	mov    0x8(%ebp),%eax
80100995:	ff d0                	call   *%eax
80100997:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010099a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010099e:	0f 89 aa fe ff ff    	jns    8010084e <consoleintr+0x22>
        }
      }
      break;
    }
  }
  release(&cons.lock);
801009a4:	83 ec 0c             	sub    $0xc,%esp
801009a7:	68 a0 b5 10 80       	push   $0x8010b5a0
801009ac:	e8 48 46 00 00       	call   80104ff9 <release>
801009b1:	83 c4 10             	add    $0x10,%esp
  if(doprocdump) {
801009b4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801009b8:	74 05                	je     801009bf <consoleintr+0x193>
    procdump();  // now call procdump() wo. cons.lock held
801009ba:	e8 54 43 00 00       	call   80104d13 <procdump>
  }
}
801009bf:	90                   	nop
801009c0:	c9                   	leave  
801009c1:	c3                   	ret    

801009c2 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
801009c2:	55                   	push   %ebp
801009c3:	89 e5                	mov    %esp,%ebp
801009c5:	83 ec 18             	sub    $0x18,%esp
  uint target;
  int c;

  iunlock(ip);
801009c8:	83 ec 0c             	sub    $0xc,%esp
801009cb:	ff 75 08             	pushl  0x8(%ebp)
801009ce:	e8 50 11 00 00       	call   80101b23 <iunlock>
801009d3:	83 c4 10             	add    $0x10,%esp
  target = n;
801009d6:	8b 45 10             	mov    0x10(%ebp),%eax
801009d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
801009dc:	83 ec 0c             	sub    $0xc,%esp
801009df:	68 a0 b5 10 80       	push   $0x8010b5a0
801009e4:	e8 a2 45 00 00       	call   80104f8b <acquire>
801009e9:	83 c4 10             	add    $0x10,%esp
  while(n > 0){
801009ec:	e9 ab 00 00 00       	jmp    80100a9c <consoleread+0xda>
    while(input.r == input.w){
      if(myproc()->killed){
801009f1:	e8 92 38 00 00       	call   80104288 <myproc>
801009f6:	8b 40 24             	mov    0x24(%eax),%eax
801009f9:	85 c0                	test   %eax,%eax
801009fb:	74 28                	je     80100a25 <consoleread+0x63>
        release(&cons.lock);
801009fd:	83 ec 0c             	sub    $0xc,%esp
80100a00:	68 a0 b5 10 80       	push   $0x8010b5a0
80100a05:	e8 ef 45 00 00       	call   80104ff9 <release>
80100a0a:	83 c4 10             	add    $0x10,%esp
        ilock(ip);
80100a0d:	83 ec 0c             	sub    $0xc,%esp
80100a10:	ff 75 08             	pushl  0x8(%ebp)
80100a13:	e8 f8 0f 00 00       	call   80101a10 <ilock>
80100a18:	83 c4 10             	add    $0x10,%esp
        return -1;
80100a1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100a20:	e9 ab 00 00 00       	jmp    80100ad0 <consoleread+0x10e>
      }
      sleep(&input.r, &cons.lock);
80100a25:	83 ec 08             	sub    $0x8,%esp
80100a28:	68 a0 b5 10 80       	push   $0x8010b5a0
80100a2d:	68 20 10 11 80       	push   $0x80111020
80100a32:	e8 3b 41 00 00       	call   80104b72 <sleep>
80100a37:	83 c4 10             	add    $0x10,%esp

  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
    while(input.r == input.w){
80100a3a:	8b 15 20 10 11 80    	mov    0x80111020,%edx
80100a40:	a1 24 10 11 80       	mov    0x80111024,%eax
80100a45:	39 c2                	cmp    %eax,%edx
80100a47:	74 a8                	je     801009f1 <consoleread+0x2f>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100a49:	a1 20 10 11 80       	mov    0x80111020,%eax
80100a4e:	8d 50 01             	lea    0x1(%eax),%edx
80100a51:	89 15 20 10 11 80    	mov    %edx,0x80111020
80100a57:	83 e0 7f             	and    $0x7f,%eax
80100a5a:	0f b6 80 a0 0f 11 80 	movzbl -0x7feef060(%eax),%eax
80100a61:	0f be c0             	movsbl %al,%eax
80100a64:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
80100a67:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100a6b:	75 17                	jne    80100a84 <consoleread+0xc2>
      if(n < target){
80100a6d:	8b 45 10             	mov    0x10(%ebp),%eax
80100a70:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80100a73:	73 2f                	jae    80100aa4 <consoleread+0xe2>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
80100a75:	a1 20 10 11 80       	mov    0x80111020,%eax
80100a7a:	83 e8 01             	sub    $0x1,%eax
80100a7d:	a3 20 10 11 80       	mov    %eax,0x80111020
      }
      break;
80100a82:	eb 20                	jmp    80100aa4 <consoleread+0xe2>
    }
    *dst++ = c;
80100a84:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a87:	8d 50 01             	lea    0x1(%eax),%edx
80100a8a:	89 55 0c             	mov    %edx,0xc(%ebp)
80100a8d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100a90:	88 10                	mov    %dl,(%eax)
    --n;
80100a92:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
80100a96:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100a9a:	74 0b                	je     80100aa7 <consoleread+0xe5>
  int c;

  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
80100a9c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100aa0:	7f 98                	jg     80100a3a <consoleread+0x78>
80100aa2:	eb 04                	jmp    80100aa8 <consoleread+0xe6>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
80100aa4:	90                   	nop
80100aa5:	eb 01                	jmp    80100aa8 <consoleread+0xe6>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100aa7:	90                   	nop
  }
  release(&cons.lock);
80100aa8:	83 ec 0c             	sub    $0xc,%esp
80100aab:	68 a0 b5 10 80       	push   $0x8010b5a0
80100ab0:	e8 44 45 00 00       	call   80104ff9 <release>
80100ab5:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80100ab8:	83 ec 0c             	sub    $0xc,%esp
80100abb:	ff 75 08             	pushl  0x8(%ebp)
80100abe:	e8 4d 0f 00 00       	call   80101a10 <ilock>
80100ac3:	83 c4 10             	add    $0x10,%esp

  return target - n;
80100ac6:	8b 45 10             	mov    0x10(%ebp),%eax
80100ac9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100acc:	29 c2                	sub    %eax,%edx
80100ace:	89 d0                	mov    %edx,%eax
}
80100ad0:	c9                   	leave  
80100ad1:	c3                   	ret    

80100ad2 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100ad2:	55                   	push   %ebp
80100ad3:	89 e5                	mov    %esp,%ebp
80100ad5:	83 ec 18             	sub    $0x18,%esp
  int i;

  iunlock(ip);
80100ad8:	83 ec 0c             	sub    $0xc,%esp
80100adb:	ff 75 08             	pushl  0x8(%ebp)
80100ade:	e8 40 10 00 00       	call   80101b23 <iunlock>
80100ae3:	83 c4 10             	add    $0x10,%esp
  acquire(&cons.lock);
80100ae6:	83 ec 0c             	sub    $0xc,%esp
80100ae9:	68 a0 b5 10 80       	push   $0x8010b5a0
80100aee:	e8 98 44 00 00       	call   80104f8b <acquire>
80100af3:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < n; i++)
80100af6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100afd:	eb 21                	jmp    80100b20 <consolewrite+0x4e>
    consputc(buf[i] & 0xff);
80100aff:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100b02:	8b 45 0c             	mov    0xc(%ebp),%eax
80100b05:	01 d0                	add    %edx,%eax
80100b07:	0f b6 00             	movzbl (%eax),%eax
80100b0a:	0f be c0             	movsbl %al,%eax
80100b0d:	0f b6 c0             	movzbl %al,%eax
80100b10:	83 ec 0c             	sub    $0xc,%esp
80100b13:	50                   	push   %eax
80100b14:	e8 ac fc ff ff       	call   801007c5 <consputc>
80100b19:	83 c4 10             	add    $0x10,%esp
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100b1c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100b20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100b23:	3b 45 10             	cmp    0x10(%ebp),%eax
80100b26:	7c d7                	jl     80100aff <consolewrite+0x2d>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100b28:	83 ec 0c             	sub    $0xc,%esp
80100b2b:	68 a0 b5 10 80       	push   $0x8010b5a0
80100b30:	e8 c4 44 00 00       	call   80104ff9 <release>
80100b35:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80100b38:	83 ec 0c             	sub    $0xc,%esp
80100b3b:	ff 75 08             	pushl  0x8(%ebp)
80100b3e:	e8 cd 0e 00 00       	call   80101a10 <ilock>
80100b43:	83 c4 10             	add    $0x10,%esp

  return n;
80100b46:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100b49:	c9                   	leave  
80100b4a:	c3                   	ret    

80100b4b <consoleinit>:

void
consoleinit(void)
{
80100b4b:	55                   	push   %ebp
80100b4c:	89 e5                	mov    %esp,%ebp
80100b4e:	83 ec 08             	sub    $0x8,%esp
  initlock(&cons.lock, "console");
80100b51:	83 ec 08             	sub    $0x8,%esp
80100b54:	68 86 83 10 80       	push   $0x80108386
80100b59:	68 a0 b5 10 80       	push   $0x8010b5a0
80100b5e:	e8 06 44 00 00       	call   80104f69 <initlock>
80100b63:	83 c4 10             	add    $0x10,%esp

  devsw[CONSOLE].write = consolewrite;
80100b66:	c7 05 ec 19 11 80 d2 	movl   $0x80100ad2,0x801119ec
80100b6d:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100b70:	c7 05 e8 19 11 80 c2 	movl   $0x801009c2,0x801119e8
80100b77:	09 10 80 
  cons.locking = 1;
80100b7a:	c7 05 d4 b5 10 80 01 	movl   $0x1,0x8010b5d4
80100b81:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
80100b84:	83 ec 08             	sub    $0x8,%esp
80100b87:	6a 00                	push   $0x0
80100b89:	6a 01                	push   $0x1
80100b8b:	e8 94 1f 00 00       	call   80102b24 <ioapicenable>
80100b90:	83 c4 10             	add    $0x10,%esp
}
80100b93:	90                   	nop
80100b94:	c9                   	leave  
80100b95:	c3                   	ret    

80100b96 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100b96:	55                   	push   %ebp
80100b97:	89 e5                	mov    %esp,%ebp
80100b99:	81 ec 18 01 00 00    	sub    $0x118,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
80100b9f:	e8 e4 36 00 00       	call   80104288 <myproc>
80100ba4:	89 45 d0             	mov    %eax,-0x30(%ebp)

  begin_op();
80100ba7:	e8 89 29 00 00       	call   80103535 <begin_op>

  if((ip = namei(path)) == 0){
80100bac:	83 ec 0c             	sub    $0xc,%esp
80100baf:	ff 75 08             	pushl  0x8(%ebp)
80100bb2:	e8 99 19 00 00       	call   80102550 <namei>
80100bb7:	83 c4 10             	add    $0x10,%esp
80100bba:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100bbd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100bc1:	75 1f                	jne    80100be2 <exec+0x4c>
    end_op();
80100bc3:	e8 f9 29 00 00       	call   801035c1 <end_op>
    cprintf("exec: fail\n");
80100bc8:	83 ec 0c             	sub    $0xc,%esp
80100bcb:	68 8e 83 10 80       	push   $0x8010838e
80100bd0:	e8 2b f8 ff ff       	call   80100400 <cprintf>
80100bd5:	83 c4 10             	add    $0x10,%esp
    return -1;
80100bd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100bdd:	e9 f1 03 00 00       	jmp    80100fd3 <exec+0x43d>
  }
  ilock(ip);
80100be2:	83 ec 0c             	sub    $0xc,%esp
80100be5:	ff 75 d8             	pushl  -0x28(%ebp)
80100be8:	e8 23 0e 00 00       	call   80101a10 <ilock>
80100bed:	83 c4 10             	add    $0x10,%esp
  pgdir = 0;
80100bf0:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
80100bf7:	6a 34                	push   $0x34
80100bf9:	6a 00                	push   $0x0
80100bfb:	8d 85 08 ff ff ff    	lea    -0xf8(%ebp),%eax
80100c01:	50                   	push   %eax
80100c02:	ff 75 d8             	pushl  -0x28(%ebp)
80100c05:	e8 f7 12 00 00       	call   80101f01 <readi>
80100c0a:	83 c4 10             	add    $0x10,%esp
80100c0d:	83 f8 34             	cmp    $0x34,%eax
80100c10:	0f 85 66 03 00 00    	jne    80100f7c <exec+0x3e6>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100c16:	8b 85 08 ff ff ff    	mov    -0xf8(%ebp),%eax
80100c1c:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100c21:	0f 85 58 03 00 00    	jne    80100f7f <exec+0x3e9>
    goto bad;

  if((pgdir = setupkvm()) == 0)
80100c27:	e8 ab 6e 00 00       	call   80107ad7 <setupkvm>
80100c2c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100c2f:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100c33:	0f 84 49 03 00 00    	je     80100f82 <exec+0x3ec>
    goto bad;

  // Load program into memory.
  sz = 0;
80100c39:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c40:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100c47:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
80100c4d:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c50:	e9 de 00 00 00       	jmp    80100d33 <exec+0x19d>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100c55:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c58:	6a 20                	push   $0x20
80100c5a:	50                   	push   %eax
80100c5b:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
80100c61:	50                   	push   %eax
80100c62:	ff 75 d8             	pushl  -0x28(%ebp)
80100c65:	e8 97 12 00 00       	call   80101f01 <readi>
80100c6a:	83 c4 10             	add    $0x10,%esp
80100c6d:	83 f8 20             	cmp    $0x20,%eax
80100c70:	0f 85 0f 03 00 00    	jne    80100f85 <exec+0x3ef>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100c76:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
80100c7c:	83 f8 01             	cmp    $0x1,%eax
80100c7f:	0f 85 a0 00 00 00    	jne    80100d25 <exec+0x18f>
      continue;
    if(ph.memsz < ph.filesz)
80100c85:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100c8b:	8b 85 f8 fe ff ff    	mov    -0x108(%ebp),%eax
80100c91:	39 c2                	cmp    %eax,%edx
80100c93:	0f 82 ef 02 00 00    	jb     80100f88 <exec+0x3f2>
      goto bad;
    if(ph.vaddr + ph.memsz < ph.vaddr)
80100c99:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c9f:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100ca5:	01 c2                	add    %eax,%edx
80100ca7:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100cad:	39 c2                	cmp    %eax,%edx
80100caf:	0f 82 d6 02 00 00    	jb     80100f8b <exec+0x3f5>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100cb5:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100cbb:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100cc1:	01 d0                	add    %edx,%eax
80100cc3:	83 ec 04             	sub    $0x4,%esp
80100cc6:	50                   	push   %eax
80100cc7:	ff 75 e0             	pushl  -0x20(%ebp)
80100cca:	ff 75 d4             	pushl  -0x2c(%ebp)
80100ccd:	e8 aa 71 00 00       	call   80107e7c <allocuvm>
80100cd2:	83 c4 10             	add    $0x10,%esp
80100cd5:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cd8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cdc:	0f 84 ac 02 00 00    	je     80100f8e <exec+0x3f8>
      goto bad;
    if(ph.vaddr % PGSIZE != 0)
80100ce2:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100ce8:	25 ff 0f 00 00       	and    $0xfff,%eax
80100ced:	85 c0                	test   %eax,%eax
80100cef:	0f 85 9c 02 00 00    	jne    80100f91 <exec+0x3fb>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100cf5:	8b 95 f8 fe ff ff    	mov    -0x108(%ebp),%edx
80100cfb:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100d01:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100d07:	83 ec 0c             	sub    $0xc,%esp
80100d0a:	52                   	push   %edx
80100d0b:	50                   	push   %eax
80100d0c:	ff 75 d8             	pushl  -0x28(%ebp)
80100d0f:	51                   	push   %ecx
80100d10:	ff 75 d4             	pushl  -0x2c(%ebp)
80100d13:	e8 97 70 00 00       	call   80107daf <loaduvm>
80100d18:	83 c4 20             	add    $0x20,%esp
80100d1b:	85 c0                	test   %eax,%eax
80100d1d:	0f 88 71 02 00 00    	js     80100f94 <exec+0x3fe>
80100d23:	eb 01                	jmp    80100d26 <exec+0x190>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100d25:	90                   	nop
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100d26:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100d2a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100d2d:	83 c0 20             	add    $0x20,%eax
80100d30:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d33:	0f b7 85 34 ff ff ff 	movzwl -0xcc(%ebp),%eax
80100d3a:	0f b7 c0             	movzwl %ax,%eax
80100d3d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100d40:	0f 8f 0f ff ff ff    	jg     80100c55 <exec+0xbf>
    if(ph.vaddr % PGSIZE != 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100d46:	83 ec 0c             	sub    $0xc,%esp
80100d49:	ff 75 d8             	pushl  -0x28(%ebp)
80100d4c:	e8 f0 0e 00 00       	call   80101c41 <iunlockput>
80100d51:	83 c4 10             	add    $0x10,%esp
  end_op();
80100d54:	e8 68 28 00 00       	call   801035c1 <end_op>
  ip = 0;
80100d59:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100d60:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d63:	05 ff 0f 00 00       	add    $0xfff,%eax
80100d68:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100d6d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100d70:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d73:	05 00 20 00 00       	add    $0x2000,%eax
80100d78:	83 ec 04             	sub    $0x4,%esp
80100d7b:	50                   	push   %eax
80100d7c:	ff 75 e0             	pushl  -0x20(%ebp)
80100d7f:	ff 75 d4             	pushl  -0x2c(%ebp)
80100d82:	e8 f5 70 00 00       	call   80107e7c <allocuvm>
80100d87:	83 c4 10             	add    $0x10,%esp
80100d8a:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d8d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100d91:	0f 84 00 02 00 00    	je     80100f97 <exec+0x401>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100d97:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d9a:	2d 00 20 00 00       	sub    $0x2000,%eax
80100d9f:	83 ec 08             	sub    $0x8,%esp
80100da2:	50                   	push   %eax
80100da3:	ff 75 d4             	pushl  -0x2c(%ebp)
80100da6:	e8 33 73 00 00       	call   801080de <clearpteu>
80100dab:	83 c4 10             	add    $0x10,%esp
  sp = sz;
80100dae:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100db1:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100db4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100dbb:	e9 96 00 00 00       	jmp    80100e56 <exec+0x2c0>
    if(argc >= MAXARG)
80100dc0:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100dc4:	0f 87 d0 01 00 00    	ja     80100f9a <exec+0x404>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100dca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dcd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dd4:	8b 45 0c             	mov    0xc(%ebp),%eax
80100dd7:	01 d0                	add    %edx,%eax
80100dd9:	8b 00                	mov    (%eax),%eax
80100ddb:	83 ec 0c             	sub    $0xc,%esp
80100dde:	50                   	push   %eax
80100ddf:	e8 6b 46 00 00       	call   8010544f <strlen>
80100de4:	83 c4 10             	add    $0x10,%esp
80100de7:	89 c2                	mov    %eax,%edx
80100de9:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100dec:	29 d0                	sub    %edx,%eax
80100dee:	83 e8 01             	sub    $0x1,%eax
80100df1:	83 e0 fc             	and    $0xfffffffc,%eax
80100df4:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100df7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dfa:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e01:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e04:	01 d0                	add    %edx,%eax
80100e06:	8b 00                	mov    (%eax),%eax
80100e08:	83 ec 0c             	sub    $0xc,%esp
80100e0b:	50                   	push   %eax
80100e0c:	e8 3e 46 00 00       	call   8010544f <strlen>
80100e11:	83 c4 10             	add    $0x10,%esp
80100e14:	83 c0 01             	add    $0x1,%eax
80100e17:	89 c1                	mov    %eax,%ecx
80100e19:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e1c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e23:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e26:	01 d0                	add    %edx,%eax
80100e28:	8b 00                	mov    (%eax),%eax
80100e2a:	51                   	push   %ecx
80100e2b:	50                   	push   %eax
80100e2c:	ff 75 dc             	pushl  -0x24(%ebp)
80100e2f:	ff 75 d4             	pushl  -0x2c(%ebp)
80100e32:	e8 46 74 00 00       	call   8010827d <copyout>
80100e37:	83 c4 10             	add    $0x10,%esp
80100e3a:	85 c0                	test   %eax,%eax
80100e3c:	0f 88 5b 01 00 00    	js     80100f9d <exec+0x407>
      goto bad;
    ustack[3+argc] = sp;
80100e42:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e45:	8d 50 03             	lea    0x3(%eax),%edx
80100e48:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e4b:	89 84 95 3c ff ff ff 	mov    %eax,-0xc4(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100e52:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100e56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e59:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e60:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e63:	01 d0                	add    %edx,%eax
80100e65:	8b 00                	mov    (%eax),%eax
80100e67:	85 c0                	test   %eax,%eax
80100e69:	0f 85 51 ff ff ff    	jne    80100dc0 <exec+0x22a>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100e6f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e72:	83 c0 03             	add    $0x3,%eax
80100e75:	c7 84 85 3c ff ff ff 	movl   $0x0,-0xc4(%ebp,%eax,4)
80100e7c:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100e80:	c7 85 3c ff ff ff ff 	movl   $0xffffffff,-0xc4(%ebp)
80100e87:	ff ff ff 
  ustack[1] = argc;
80100e8a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e8d:	89 85 40 ff ff ff    	mov    %eax,-0xc0(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100e93:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e96:	83 c0 01             	add    $0x1,%eax
80100e99:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ea0:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ea3:	29 d0                	sub    %edx,%eax
80100ea5:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)

  sp -= (3+argc+1) * 4;
80100eab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eae:	83 c0 04             	add    $0x4,%eax
80100eb1:	c1 e0 02             	shl    $0x2,%eax
80100eb4:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100eb7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eba:	83 c0 04             	add    $0x4,%eax
80100ebd:	c1 e0 02             	shl    $0x2,%eax
80100ec0:	50                   	push   %eax
80100ec1:	8d 85 3c ff ff ff    	lea    -0xc4(%ebp),%eax
80100ec7:	50                   	push   %eax
80100ec8:	ff 75 dc             	pushl  -0x24(%ebp)
80100ecb:	ff 75 d4             	pushl  -0x2c(%ebp)
80100ece:	e8 aa 73 00 00       	call   8010827d <copyout>
80100ed3:	83 c4 10             	add    $0x10,%esp
80100ed6:	85 c0                	test   %eax,%eax
80100ed8:	0f 88 c2 00 00 00    	js     80100fa0 <exec+0x40a>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100ede:	8b 45 08             	mov    0x8(%ebp),%eax
80100ee1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100ee4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ee7:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100eea:	eb 17                	jmp    80100f03 <exec+0x36d>
    if(*s == '/')
80100eec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100eef:	0f b6 00             	movzbl (%eax),%eax
80100ef2:	3c 2f                	cmp    $0x2f,%al
80100ef4:	75 09                	jne    80100eff <exec+0x369>
      last = s+1;
80100ef6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ef9:	83 c0 01             	add    $0x1,%eax
80100efc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100eff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100f03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f06:	0f b6 00             	movzbl (%eax),%eax
80100f09:	84 c0                	test   %al,%al
80100f0b:	75 df                	jne    80100eec <exec+0x356>
    if(*s == '/')
      last = s+1;
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100f0d:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f10:	83 c0 6c             	add    $0x6c,%eax
80100f13:	83 ec 04             	sub    $0x4,%esp
80100f16:	6a 10                	push   $0x10
80100f18:	ff 75 f0             	pushl  -0x10(%ebp)
80100f1b:	50                   	push   %eax
80100f1c:	e8 e4 44 00 00       	call   80105405 <safestrcpy>
80100f21:	83 c4 10             	add    $0x10,%esp

  // Commit to the user image.
  oldpgdir = curproc->pgdir;
80100f24:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f27:	8b 40 04             	mov    0x4(%eax),%eax
80100f2a:	89 45 cc             	mov    %eax,-0x34(%ebp)
  curproc->pgdir = pgdir;
80100f2d:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f30:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100f33:	89 50 04             	mov    %edx,0x4(%eax)
  curproc->sz = sz;
80100f36:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f39:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100f3c:	89 10                	mov    %edx,(%eax)
  curproc->tf->eip = elf.entry;  // main
80100f3e:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f41:	8b 40 18             	mov    0x18(%eax),%eax
80100f44:	8b 95 20 ff ff ff    	mov    -0xe0(%ebp),%edx
80100f4a:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100f4d:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f50:	8b 40 18             	mov    0x18(%eax),%eax
80100f53:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100f56:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(curproc);
80100f59:	83 ec 0c             	sub    $0xc,%esp
80100f5c:	ff 75 d0             	pushl  -0x30(%ebp)
80100f5f:	e8 3d 6c 00 00       	call   80107ba1 <switchuvm>
80100f64:	83 c4 10             	add    $0x10,%esp
  freevm(oldpgdir);
80100f67:	83 ec 0c             	sub    $0xc,%esp
80100f6a:	ff 75 cc             	pushl  -0x34(%ebp)
80100f6d:	e8 d3 70 00 00       	call   80108045 <freevm>
80100f72:	83 c4 10             	add    $0x10,%esp
  return 0;
80100f75:	b8 00 00 00 00       	mov    $0x0,%eax
80100f7a:	eb 57                	jmp    80100fd3 <exec+0x43d>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
    goto bad;
80100f7c:	90                   	nop
80100f7d:	eb 22                	jmp    80100fa1 <exec+0x40b>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100f7f:	90                   	nop
80100f80:	eb 1f                	jmp    80100fa1 <exec+0x40b>

  if((pgdir = setupkvm()) == 0)
    goto bad;
80100f82:	90                   	nop
80100f83:	eb 1c                	jmp    80100fa1 <exec+0x40b>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100f85:	90                   	nop
80100f86:	eb 19                	jmp    80100fa1 <exec+0x40b>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100f88:	90                   	nop
80100f89:	eb 16                	jmp    80100fa1 <exec+0x40b>
    if(ph.vaddr + ph.memsz < ph.vaddr)
      goto bad;
80100f8b:	90                   	nop
80100f8c:	eb 13                	jmp    80100fa1 <exec+0x40b>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100f8e:	90                   	nop
80100f8f:	eb 10                	jmp    80100fa1 <exec+0x40b>
    if(ph.vaddr % PGSIZE != 0)
      goto bad;
80100f91:	90                   	nop
80100f92:	eb 0d                	jmp    80100fa1 <exec+0x40b>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100f94:	90                   	nop
80100f95:	eb 0a                	jmp    80100fa1 <exec+0x40b>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100f97:	90                   	nop
80100f98:	eb 07                	jmp    80100fa1 <exec+0x40b>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100f9a:	90                   	nop
80100f9b:	eb 04                	jmp    80100fa1 <exec+0x40b>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100f9d:	90                   	nop
80100f9e:	eb 01                	jmp    80100fa1 <exec+0x40b>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100fa0:	90                   	nop
  switchuvm(curproc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100fa1:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100fa5:	74 0e                	je     80100fb5 <exec+0x41f>
    freevm(pgdir);
80100fa7:	83 ec 0c             	sub    $0xc,%esp
80100faa:	ff 75 d4             	pushl  -0x2c(%ebp)
80100fad:	e8 93 70 00 00       	call   80108045 <freevm>
80100fb2:	83 c4 10             	add    $0x10,%esp
  if(ip){
80100fb5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100fb9:	74 13                	je     80100fce <exec+0x438>
    iunlockput(ip);
80100fbb:	83 ec 0c             	sub    $0xc,%esp
80100fbe:	ff 75 d8             	pushl  -0x28(%ebp)
80100fc1:	e8 7b 0c 00 00       	call   80101c41 <iunlockput>
80100fc6:	83 c4 10             	add    $0x10,%esp
    end_op();
80100fc9:	e8 f3 25 00 00       	call   801035c1 <end_op>
  }
  return -1;
80100fce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100fd3:	c9                   	leave  
80100fd4:	c3                   	ret    

80100fd5 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100fd5:	55                   	push   %ebp
80100fd6:	89 e5                	mov    %esp,%ebp
80100fd8:	83 ec 08             	sub    $0x8,%esp
  initlock(&ftable.lock, "ftable");
80100fdb:	83 ec 08             	sub    $0x8,%esp
80100fde:	68 9a 83 10 80       	push   $0x8010839a
80100fe3:	68 40 10 11 80       	push   $0x80111040
80100fe8:	e8 7c 3f 00 00       	call   80104f69 <initlock>
80100fed:	83 c4 10             	add    $0x10,%esp
}
80100ff0:	90                   	nop
80100ff1:	c9                   	leave  
80100ff2:	c3                   	ret    

80100ff3 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100ff3:	55                   	push   %ebp
80100ff4:	89 e5                	mov    %esp,%ebp
80100ff6:	83 ec 18             	sub    $0x18,%esp
  struct file *f;

  acquire(&ftable.lock);
80100ff9:	83 ec 0c             	sub    $0xc,%esp
80100ffc:	68 40 10 11 80       	push   $0x80111040
80101001:	e8 85 3f 00 00       	call   80104f8b <acquire>
80101006:	83 c4 10             	add    $0x10,%esp
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101009:	c7 45 f4 74 10 11 80 	movl   $0x80111074,-0xc(%ebp)
80101010:	eb 2d                	jmp    8010103f <filealloc+0x4c>
    if(f->ref == 0){
80101012:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101015:	8b 40 04             	mov    0x4(%eax),%eax
80101018:	85 c0                	test   %eax,%eax
8010101a:	75 1f                	jne    8010103b <filealloc+0x48>
      f->ref = 1;
8010101c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010101f:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80101026:	83 ec 0c             	sub    $0xc,%esp
80101029:	68 40 10 11 80       	push   $0x80111040
8010102e:	e8 c6 3f 00 00       	call   80104ff9 <release>
80101033:	83 c4 10             	add    $0x10,%esp
      return f;
80101036:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101039:	eb 23                	jmp    8010105e <filealloc+0x6b>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
8010103b:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
8010103f:	b8 d4 19 11 80       	mov    $0x801119d4,%eax
80101044:	39 45 f4             	cmp    %eax,-0xc(%ebp)
80101047:	72 c9                	jb     80101012 <filealloc+0x1f>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80101049:	83 ec 0c             	sub    $0xc,%esp
8010104c:	68 40 10 11 80       	push   $0x80111040
80101051:	e8 a3 3f 00 00       	call   80104ff9 <release>
80101056:	83 c4 10             	add    $0x10,%esp
  return 0;
80101059:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010105e:	c9                   	leave  
8010105f:	c3                   	ret    

80101060 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80101060:	55                   	push   %ebp
80101061:	89 e5                	mov    %esp,%ebp
80101063:	83 ec 08             	sub    $0x8,%esp
  acquire(&ftable.lock);
80101066:	83 ec 0c             	sub    $0xc,%esp
80101069:	68 40 10 11 80       	push   $0x80111040
8010106e:	e8 18 3f 00 00       	call   80104f8b <acquire>
80101073:	83 c4 10             	add    $0x10,%esp
  if(f->ref < 1)
80101076:	8b 45 08             	mov    0x8(%ebp),%eax
80101079:	8b 40 04             	mov    0x4(%eax),%eax
8010107c:	85 c0                	test   %eax,%eax
8010107e:	7f 0d                	jg     8010108d <filedup+0x2d>
    panic("filedup");
80101080:	83 ec 0c             	sub    $0xc,%esp
80101083:	68 a1 83 10 80       	push   $0x801083a1
80101088:	e8 13 f5 ff ff       	call   801005a0 <panic>
  f->ref++;
8010108d:	8b 45 08             	mov    0x8(%ebp),%eax
80101090:	8b 40 04             	mov    0x4(%eax),%eax
80101093:	8d 50 01             	lea    0x1(%eax),%edx
80101096:	8b 45 08             	mov    0x8(%ebp),%eax
80101099:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
8010109c:	83 ec 0c             	sub    $0xc,%esp
8010109f:	68 40 10 11 80       	push   $0x80111040
801010a4:	e8 50 3f 00 00       	call   80104ff9 <release>
801010a9:	83 c4 10             	add    $0x10,%esp
  return f;
801010ac:	8b 45 08             	mov    0x8(%ebp),%eax
}
801010af:	c9                   	leave  
801010b0:	c3                   	ret    

801010b1 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
801010b1:	55                   	push   %ebp
801010b2:	89 e5                	mov    %esp,%ebp
801010b4:	83 ec 28             	sub    $0x28,%esp
  struct file ff;

  acquire(&ftable.lock);
801010b7:	83 ec 0c             	sub    $0xc,%esp
801010ba:	68 40 10 11 80       	push   $0x80111040
801010bf:	e8 c7 3e 00 00       	call   80104f8b <acquire>
801010c4:	83 c4 10             	add    $0x10,%esp
  if(f->ref < 1)
801010c7:	8b 45 08             	mov    0x8(%ebp),%eax
801010ca:	8b 40 04             	mov    0x4(%eax),%eax
801010cd:	85 c0                	test   %eax,%eax
801010cf:	7f 0d                	jg     801010de <fileclose+0x2d>
    panic("fileclose");
801010d1:	83 ec 0c             	sub    $0xc,%esp
801010d4:	68 a9 83 10 80       	push   $0x801083a9
801010d9:	e8 c2 f4 ff ff       	call   801005a0 <panic>
  if(--f->ref > 0){
801010de:	8b 45 08             	mov    0x8(%ebp),%eax
801010e1:	8b 40 04             	mov    0x4(%eax),%eax
801010e4:	8d 50 ff             	lea    -0x1(%eax),%edx
801010e7:	8b 45 08             	mov    0x8(%ebp),%eax
801010ea:	89 50 04             	mov    %edx,0x4(%eax)
801010ed:	8b 45 08             	mov    0x8(%ebp),%eax
801010f0:	8b 40 04             	mov    0x4(%eax),%eax
801010f3:	85 c0                	test   %eax,%eax
801010f5:	7e 15                	jle    8010110c <fileclose+0x5b>
    release(&ftable.lock);
801010f7:	83 ec 0c             	sub    $0xc,%esp
801010fa:	68 40 10 11 80       	push   $0x80111040
801010ff:	e8 f5 3e 00 00       	call   80104ff9 <release>
80101104:	83 c4 10             	add    $0x10,%esp
80101107:	e9 8b 00 00 00       	jmp    80101197 <fileclose+0xe6>
    return;
  }
  ff = *f;
8010110c:	8b 45 08             	mov    0x8(%ebp),%eax
8010110f:	8b 10                	mov    (%eax),%edx
80101111:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101114:	8b 50 04             	mov    0x4(%eax),%edx
80101117:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010111a:	8b 50 08             	mov    0x8(%eax),%edx
8010111d:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101120:	8b 50 0c             	mov    0xc(%eax),%edx
80101123:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101126:	8b 50 10             	mov    0x10(%eax),%edx
80101129:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010112c:	8b 40 14             	mov    0x14(%eax),%eax
8010112f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101132:	8b 45 08             	mov    0x8(%ebp),%eax
80101135:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010113c:	8b 45 08             	mov    0x8(%ebp),%eax
8010113f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101145:	83 ec 0c             	sub    $0xc,%esp
80101148:	68 40 10 11 80       	push   $0x80111040
8010114d:	e8 a7 3e 00 00       	call   80104ff9 <release>
80101152:	83 c4 10             	add    $0x10,%esp

  if(ff.type == FD_PIPE)
80101155:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101158:	83 f8 01             	cmp    $0x1,%eax
8010115b:	75 19                	jne    80101176 <fileclose+0xc5>
    pipeclose(ff.pipe, ff.writable);
8010115d:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101161:	0f be d0             	movsbl %al,%edx
80101164:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101167:	83 ec 08             	sub    $0x8,%esp
8010116a:	52                   	push   %edx
8010116b:	50                   	push   %eax
8010116c:	e8 a1 2d 00 00       	call   80103f12 <pipeclose>
80101171:	83 c4 10             	add    $0x10,%esp
80101174:	eb 21                	jmp    80101197 <fileclose+0xe6>
  else if(ff.type == FD_INODE){
80101176:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101179:	83 f8 02             	cmp    $0x2,%eax
8010117c:	75 19                	jne    80101197 <fileclose+0xe6>
    begin_op();
8010117e:	e8 b2 23 00 00       	call   80103535 <begin_op>
    iput(ff.ip);
80101183:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101186:	83 ec 0c             	sub    $0xc,%esp
80101189:	50                   	push   %eax
8010118a:	e8 e2 09 00 00       	call   80101b71 <iput>
8010118f:	83 c4 10             	add    $0x10,%esp
    end_op();
80101192:	e8 2a 24 00 00       	call   801035c1 <end_op>
  }
}
80101197:	c9                   	leave  
80101198:	c3                   	ret    

80101199 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80101199:	55                   	push   %ebp
8010119a:	89 e5                	mov    %esp,%ebp
8010119c:	83 ec 08             	sub    $0x8,%esp
  if(f->type == FD_INODE){
8010119f:	8b 45 08             	mov    0x8(%ebp),%eax
801011a2:	8b 00                	mov    (%eax),%eax
801011a4:	83 f8 02             	cmp    $0x2,%eax
801011a7:	75 40                	jne    801011e9 <filestat+0x50>
    ilock(f->ip);
801011a9:	8b 45 08             	mov    0x8(%ebp),%eax
801011ac:	8b 40 10             	mov    0x10(%eax),%eax
801011af:	83 ec 0c             	sub    $0xc,%esp
801011b2:	50                   	push   %eax
801011b3:	e8 58 08 00 00       	call   80101a10 <ilock>
801011b8:	83 c4 10             	add    $0x10,%esp
    stati(f->ip, st);
801011bb:	8b 45 08             	mov    0x8(%ebp),%eax
801011be:	8b 40 10             	mov    0x10(%eax),%eax
801011c1:	83 ec 08             	sub    $0x8,%esp
801011c4:	ff 75 0c             	pushl  0xc(%ebp)
801011c7:	50                   	push   %eax
801011c8:	e8 ee 0c 00 00       	call   80101ebb <stati>
801011cd:	83 c4 10             	add    $0x10,%esp
    iunlock(f->ip);
801011d0:	8b 45 08             	mov    0x8(%ebp),%eax
801011d3:	8b 40 10             	mov    0x10(%eax),%eax
801011d6:	83 ec 0c             	sub    $0xc,%esp
801011d9:	50                   	push   %eax
801011da:	e8 44 09 00 00       	call   80101b23 <iunlock>
801011df:	83 c4 10             	add    $0x10,%esp
    return 0;
801011e2:	b8 00 00 00 00       	mov    $0x0,%eax
801011e7:	eb 05                	jmp    801011ee <filestat+0x55>
  }
  return -1;
801011e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801011ee:	c9                   	leave  
801011ef:	c3                   	ret    

801011f0 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801011f0:	55                   	push   %ebp
801011f1:	89 e5                	mov    %esp,%ebp
801011f3:	83 ec 18             	sub    $0x18,%esp
  int r;

  if(f->readable == 0)
801011f6:	8b 45 08             	mov    0x8(%ebp),%eax
801011f9:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801011fd:	84 c0                	test   %al,%al
801011ff:	75 0a                	jne    8010120b <fileread+0x1b>
    return -1;
80101201:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101206:	e9 9b 00 00 00       	jmp    801012a6 <fileread+0xb6>
  if(f->type == FD_PIPE)
8010120b:	8b 45 08             	mov    0x8(%ebp),%eax
8010120e:	8b 00                	mov    (%eax),%eax
80101210:	83 f8 01             	cmp    $0x1,%eax
80101213:	75 1a                	jne    8010122f <fileread+0x3f>
    return piperead(f->pipe, addr, n);
80101215:	8b 45 08             	mov    0x8(%ebp),%eax
80101218:	8b 40 0c             	mov    0xc(%eax),%eax
8010121b:	83 ec 04             	sub    $0x4,%esp
8010121e:	ff 75 10             	pushl  0x10(%ebp)
80101221:	ff 75 0c             	pushl  0xc(%ebp)
80101224:	50                   	push   %eax
80101225:	e8 8f 2e 00 00       	call   801040b9 <piperead>
8010122a:	83 c4 10             	add    $0x10,%esp
8010122d:	eb 77                	jmp    801012a6 <fileread+0xb6>
  if(f->type == FD_INODE){
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 00                	mov    (%eax),%eax
80101234:	83 f8 02             	cmp    $0x2,%eax
80101237:	75 60                	jne    80101299 <fileread+0xa9>
    ilock(f->ip);
80101239:	8b 45 08             	mov    0x8(%ebp),%eax
8010123c:	8b 40 10             	mov    0x10(%eax),%eax
8010123f:	83 ec 0c             	sub    $0xc,%esp
80101242:	50                   	push   %eax
80101243:	e8 c8 07 00 00       	call   80101a10 <ilock>
80101248:	83 c4 10             	add    $0x10,%esp
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010124b:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010124e:	8b 45 08             	mov    0x8(%ebp),%eax
80101251:	8b 50 14             	mov    0x14(%eax),%edx
80101254:	8b 45 08             	mov    0x8(%ebp),%eax
80101257:	8b 40 10             	mov    0x10(%eax),%eax
8010125a:	51                   	push   %ecx
8010125b:	52                   	push   %edx
8010125c:	ff 75 0c             	pushl  0xc(%ebp)
8010125f:	50                   	push   %eax
80101260:	e8 9c 0c 00 00       	call   80101f01 <readi>
80101265:	83 c4 10             	add    $0x10,%esp
80101268:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010126b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010126f:	7e 11                	jle    80101282 <fileread+0x92>
      f->off += r;
80101271:	8b 45 08             	mov    0x8(%ebp),%eax
80101274:	8b 50 14             	mov    0x14(%eax),%edx
80101277:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010127a:	01 c2                	add    %eax,%edx
8010127c:	8b 45 08             	mov    0x8(%ebp),%eax
8010127f:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
80101282:	8b 45 08             	mov    0x8(%ebp),%eax
80101285:	8b 40 10             	mov    0x10(%eax),%eax
80101288:	83 ec 0c             	sub    $0xc,%esp
8010128b:	50                   	push   %eax
8010128c:	e8 92 08 00 00       	call   80101b23 <iunlock>
80101291:	83 c4 10             	add    $0x10,%esp
    return r;
80101294:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101297:	eb 0d                	jmp    801012a6 <fileread+0xb6>
  }
  panic("fileread");
80101299:	83 ec 0c             	sub    $0xc,%esp
8010129c:	68 b3 83 10 80       	push   $0x801083b3
801012a1:	e8 fa f2 ff ff       	call   801005a0 <panic>
}
801012a6:	c9                   	leave  
801012a7:	c3                   	ret    

801012a8 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801012a8:	55                   	push   %ebp
801012a9:	89 e5                	mov    %esp,%ebp
801012ab:	53                   	push   %ebx
801012ac:	83 ec 14             	sub    $0x14,%esp
  int r;

  if(f->writable == 0)
801012af:	8b 45 08             	mov    0x8(%ebp),%eax
801012b2:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801012b6:	84 c0                	test   %al,%al
801012b8:	75 0a                	jne    801012c4 <filewrite+0x1c>
    return -1;
801012ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012bf:	e9 1b 01 00 00       	jmp    801013df <filewrite+0x137>
  if(f->type == FD_PIPE)
801012c4:	8b 45 08             	mov    0x8(%ebp),%eax
801012c7:	8b 00                	mov    (%eax),%eax
801012c9:	83 f8 01             	cmp    $0x1,%eax
801012cc:	75 1d                	jne    801012eb <filewrite+0x43>
    return pipewrite(f->pipe, addr, n);
801012ce:	8b 45 08             	mov    0x8(%ebp),%eax
801012d1:	8b 40 0c             	mov    0xc(%eax),%eax
801012d4:	83 ec 04             	sub    $0x4,%esp
801012d7:	ff 75 10             	pushl  0x10(%ebp)
801012da:	ff 75 0c             	pushl  0xc(%ebp)
801012dd:	50                   	push   %eax
801012de:	e8 d9 2c 00 00       	call   80103fbc <pipewrite>
801012e3:	83 c4 10             	add    $0x10,%esp
801012e6:	e9 f4 00 00 00       	jmp    801013df <filewrite+0x137>
  if(f->type == FD_INODE){
801012eb:	8b 45 08             	mov    0x8(%ebp),%eax
801012ee:	8b 00                	mov    (%eax),%eax
801012f0:	83 f8 02             	cmp    $0x2,%eax
801012f3:	0f 85 d9 00 00 00    	jne    801013d2 <filewrite+0x12a>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
801012f9:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
80101300:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101307:	e9 a3 00 00 00       	jmp    801013af <filewrite+0x107>
      int n1 = n - i;
8010130c:	8b 45 10             	mov    0x10(%ebp),%eax
8010130f:	2b 45 f4             	sub    -0xc(%ebp),%eax
80101312:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101315:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101318:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010131b:	7e 06                	jle    80101323 <filewrite+0x7b>
        n1 = max;
8010131d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101320:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101323:	e8 0d 22 00 00       	call   80103535 <begin_op>
      ilock(f->ip);
80101328:	8b 45 08             	mov    0x8(%ebp),%eax
8010132b:	8b 40 10             	mov    0x10(%eax),%eax
8010132e:	83 ec 0c             	sub    $0xc,%esp
80101331:	50                   	push   %eax
80101332:	e8 d9 06 00 00       	call   80101a10 <ilock>
80101337:	83 c4 10             	add    $0x10,%esp
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
8010133a:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010133d:	8b 45 08             	mov    0x8(%ebp),%eax
80101340:	8b 50 14             	mov    0x14(%eax),%edx
80101343:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80101346:	8b 45 0c             	mov    0xc(%ebp),%eax
80101349:	01 c3                	add    %eax,%ebx
8010134b:	8b 45 08             	mov    0x8(%ebp),%eax
8010134e:	8b 40 10             	mov    0x10(%eax),%eax
80101351:	51                   	push   %ecx
80101352:	52                   	push   %edx
80101353:	53                   	push   %ebx
80101354:	50                   	push   %eax
80101355:	e8 fe 0c 00 00       	call   80102058 <writei>
8010135a:	83 c4 10             	add    $0x10,%esp
8010135d:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101360:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101364:	7e 11                	jle    80101377 <filewrite+0xcf>
        f->off += r;
80101366:	8b 45 08             	mov    0x8(%ebp),%eax
80101369:	8b 50 14             	mov    0x14(%eax),%edx
8010136c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010136f:	01 c2                	add    %eax,%edx
80101371:	8b 45 08             	mov    0x8(%ebp),%eax
80101374:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
80101377:	8b 45 08             	mov    0x8(%ebp),%eax
8010137a:	8b 40 10             	mov    0x10(%eax),%eax
8010137d:	83 ec 0c             	sub    $0xc,%esp
80101380:	50                   	push   %eax
80101381:	e8 9d 07 00 00       	call   80101b23 <iunlock>
80101386:	83 c4 10             	add    $0x10,%esp
      end_op();
80101389:	e8 33 22 00 00       	call   801035c1 <end_op>

      if(r < 0)
8010138e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101392:	78 29                	js     801013bd <filewrite+0x115>
        break;
      if(r != n1)
80101394:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101397:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010139a:	74 0d                	je     801013a9 <filewrite+0x101>
        panic("short filewrite");
8010139c:	83 ec 0c             	sub    $0xc,%esp
8010139f:	68 bc 83 10 80       	push   $0x801083bc
801013a4:	e8 f7 f1 ff ff       	call   801005a0 <panic>
      i += r;
801013a9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013ac:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801013af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b2:	3b 45 10             	cmp    0x10(%ebp),%eax
801013b5:	0f 8c 51 ff ff ff    	jl     8010130c <filewrite+0x64>
801013bb:	eb 01                	jmp    801013be <filewrite+0x116>
        f->off += r;
      iunlock(f->ip);
      end_op();

      if(r < 0)
        break;
801013bd:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801013be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013c1:	3b 45 10             	cmp    0x10(%ebp),%eax
801013c4:	75 05                	jne    801013cb <filewrite+0x123>
801013c6:	8b 45 10             	mov    0x10(%ebp),%eax
801013c9:	eb 14                	jmp    801013df <filewrite+0x137>
801013cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801013d0:	eb 0d                	jmp    801013df <filewrite+0x137>
  }
  panic("filewrite");
801013d2:	83 ec 0c             	sub    $0xc,%esp
801013d5:	68 cc 83 10 80       	push   $0x801083cc
801013da:	e8 c1 f1 ff ff       	call   801005a0 <panic>
}
801013df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801013e2:	c9                   	leave  
801013e3:	c3                   	ret    

801013e4 <readsb>:
struct superblock sb; 

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801013e4:	55                   	push   %ebp
801013e5:	89 e5                	mov    %esp,%ebp
801013e7:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;

  bp = bread(dev, 1);
801013ea:	8b 45 08             	mov    0x8(%ebp),%eax
801013ed:	83 ec 08             	sub    $0x8,%esp
801013f0:	6a 01                	push   $0x1
801013f2:	50                   	push   %eax
801013f3:	e8 d6 ed ff ff       	call   801001ce <bread>
801013f8:	83 c4 10             	add    $0x10,%esp
801013fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
801013fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101401:	83 c0 5c             	add    $0x5c,%eax
80101404:	83 ec 04             	sub    $0x4,%esp
80101407:	6a 1c                	push   $0x1c
80101409:	50                   	push   %eax
8010140a:	ff 75 0c             	pushl  0xc(%ebp)
8010140d:	e8 af 3e 00 00       	call   801052c1 <memmove>
80101412:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
80101415:	83 ec 0c             	sub    $0xc,%esp
80101418:	ff 75 f4             	pushl  -0xc(%ebp)
8010141b:	e8 30 ee ff ff       	call   80100250 <brelse>
80101420:	83 c4 10             	add    $0x10,%esp
}
80101423:	90                   	nop
80101424:	c9                   	leave  
80101425:	c3                   	ret    

80101426 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101426:	55                   	push   %ebp
80101427:	89 e5                	mov    %esp,%ebp
80101429:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;

  bp = bread(dev, bno);
8010142c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010142f:	8b 45 08             	mov    0x8(%ebp),%eax
80101432:	83 ec 08             	sub    $0x8,%esp
80101435:	52                   	push   %edx
80101436:	50                   	push   %eax
80101437:	e8 92 ed ff ff       	call   801001ce <bread>
8010143c:	83 c4 10             	add    $0x10,%esp
8010143f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101442:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101445:	83 c0 5c             	add    $0x5c,%eax
80101448:	83 ec 04             	sub    $0x4,%esp
8010144b:	68 00 02 00 00       	push   $0x200
80101450:	6a 00                	push   $0x0
80101452:	50                   	push   %eax
80101453:	e8 aa 3d 00 00       	call   80105202 <memset>
80101458:	83 c4 10             	add    $0x10,%esp
  log_write(bp);
8010145b:	83 ec 0c             	sub    $0xc,%esp
8010145e:	ff 75 f4             	pushl  -0xc(%ebp)
80101461:	e8 07 23 00 00       	call   8010376d <log_write>
80101466:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
80101469:	83 ec 0c             	sub    $0xc,%esp
8010146c:	ff 75 f4             	pushl  -0xc(%ebp)
8010146f:	e8 dc ed ff ff       	call   80100250 <brelse>
80101474:	83 c4 10             	add    $0x10,%esp
}
80101477:	90                   	nop
80101478:	c9                   	leave  
80101479:	c3                   	ret    

8010147a <balloc>:
// Blocks.

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
8010147a:	55                   	push   %ebp
8010147b:	89 e5                	mov    %esp,%ebp
8010147d:	83 ec 18             	sub    $0x18,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
80101480:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101487:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010148e:	e9 13 01 00 00       	jmp    801015a6 <balloc+0x12c>
    bp = bread(dev, BBLOCK(b, sb));
80101493:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101496:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
8010149c:	85 c0                	test   %eax,%eax
8010149e:	0f 48 c2             	cmovs  %edx,%eax
801014a1:	c1 f8 0c             	sar    $0xc,%eax
801014a4:	89 c2                	mov    %eax,%edx
801014a6:	a1 58 1a 11 80       	mov    0x80111a58,%eax
801014ab:	01 d0                	add    %edx,%eax
801014ad:	83 ec 08             	sub    $0x8,%esp
801014b0:	50                   	push   %eax
801014b1:	ff 75 08             	pushl  0x8(%ebp)
801014b4:	e8 15 ed ff ff       	call   801001ce <bread>
801014b9:	83 c4 10             	add    $0x10,%esp
801014bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014bf:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801014c6:	e9 a6 00 00 00       	jmp    80101571 <balloc+0xf7>
      m = 1 << (bi % 8);
801014cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014ce:	99                   	cltd   
801014cf:	c1 ea 1d             	shr    $0x1d,%edx
801014d2:	01 d0                	add    %edx,%eax
801014d4:	83 e0 07             	and    $0x7,%eax
801014d7:	29 d0                	sub    %edx,%eax
801014d9:	ba 01 00 00 00       	mov    $0x1,%edx
801014de:	89 c1                	mov    %eax,%ecx
801014e0:	d3 e2                	shl    %cl,%edx
801014e2:	89 d0                	mov    %edx,%eax
801014e4:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801014e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014ea:	8d 50 07             	lea    0x7(%eax),%edx
801014ed:	85 c0                	test   %eax,%eax
801014ef:	0f 48 c2             	cmovs  %edx,%eax
801014f2:	c1 f8 03             	sar    $0x3,%eax
801014f5:	89 c2                	mov    %eax,%edx
801014f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014fa:	0f b6 44 10 5c       	movzbl 0x5c(%eax,%edx,1),%eax
801014ff:	0f b6 c0             	movzbl %al,%eax
80101502:	23 45 e8             	and    -0x18(%ebp),%eax
80101505:	85 c0                	test   %eax,%eax
80101507:	75 64                	jne    8010156d <balloc+0xf3>
        bp->data[bi/8] |= m;  // Mark block in use.
80101509:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010150c:	8d 50 07             	lea    0x7(%eax),%edx
8010150f:	85 c0                	test   %eax,%eax
80101511:	0f 48 c2             	cmovs  %edx,%eax
80101514:	c1 f8 03             	sar    $0x3,%eax
80101517:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010151a:	0f b6 54 02 5c       	movzbl 0x5c(%edx,%eax,1),%edx
8010151f:	89 d1                	mov    %edx,%ecx
80101521:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101524:	09 ca                	or     %ecx,%edx
80101526:	89 d1                	mov    %edx,%ecx
80101528:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010152b:	88 4c 02 5c          	mov    %cl,0x5c(%edx,%eax,1)
        log_write(bp);
8010152f:	83 ec 0c             	sub    $0xc,%esp
80101532:	ff 75 ec             	pushl  -0x14(%ebp)
80101535:	e8 33 22 00 00       	call   8010376d <log_write>
8010153a:	83 c4 10             	add    $0x10,%esp
        brelse(bp);
8010153d:	83 ec 0c             	sub    $0xc,%esp
80101540:	ff 75 ec             	pushl  -0x14(%ebp)
80101543:	e8 08 ed ff ff       	call   80100250 <brelse>
80101548:	83 c4 10             	add    $0x10,%esp
        bzero(dev, b + bi);
8010154b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010154e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101551:	01 c2                	add    %eax,%edx
80101553:	8b 45 08             	mov    0x8(%ebp),%eax
80101556:	83 ec 08             	sub    $0x8,%esp
80101559:	52                   	push   %edx
8010155a:	50                   	push   %eax
8010155b:	e8 c6 fe ff ff       	call   80101426 <bzero>
80101560:	83 c4 10             	add    $0x10,%esp
        return b + bi;
80101563:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101566:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101569:	01 d0                	add    %edx,%eax
8010156b:	eb 57                	jmp    801015c4 <balloc+0x14a>
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010156d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101571:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101578:	7f 17                	jg     80101591 <balloc+0x117>
8010157a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010157d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101580:	01 d0                	add    %edx,%eax
80101582:	89 c2                	mov    %eax,%edx
80101584:	a1 40 1a 11 80       	mov    0x80111a40,%eax
80101589:	39 c2                	cmp    %eax,%edx
8010158b:	0f 82 3a ff ff ff    	jb     801014cb <balloc+0x51>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101591:	83 ec 0c             	sub    $0xc,%esp
80101594:	ff 75 ec             	pushl  -0x14(%ebp)
80101597:	e8 b4 ec ff ff       	call   80100250 <brelse>
8010159c:	83 c4 10             	add    $0x10,%esp
{
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
8010159f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801015a6:	8b 15 40 1a 11 80    	mov    0x80111a40,%edx
801015ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015af:	39 c2                	cmp    %eax,%edx
801015b1:	0f 87 dc fe ff ff    	ja     80101493 <balloc+0x19>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801015b7:	83 ec 0c             	sub    $0xc,%esp
801015ba:	68 d8 83 10 80       	push   $0x801083d8
801015bf:	e8 dc ef ff ff       	call   801005a0 <panic>
}
801015c4:	c9                   	leave  
801015c5:	c3                   	ret    

801015c6 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
801015c6:	55                   	push   %ebp
801015c7:	89 e5                	mov    %esp,%ebp
801015c9:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;
  int bi, m;

  readsb(dev, &sb);
801015cc:	83 ec 08             	sub    $0x8,%esp
801015cf:	68 40 1a 11 80       	push   $0x80111a40
801015d4:	ff 75 08             	pushl  0x8(%ebp)
801015d7:	e8 08 fe ff ff       	call   801013e4 <readsb>
801015dc:	83 c4 10             	add    $0x10,%esp
  bp = bread(dev, BBLOCK(b, sb));
801015df:	8b 45 0c             	mov    0xc(%ebp),%eax
801015e2:	c1 e8 0c             	shr    $0xc,%eax
801015e5:	89 c2                	mov    %eax,%edx
801015e7:	a1 58 1a 11 80       	mov    0x80111a58,%eax
801015ec:	01 c2                	add    %eax,%edx
801015ee:	8b 45 08             	mov    0x8(%ebp),%eax
801015f1:	83 ec 08             	sub    $0x8,%esp
801015f4:	52                   	push   %edx
801015f5:	50                   	push   %eax
801015f6:	e8 d3 eb ff ff       	call   801001ce <bread>
801015fb:	83 c4 10             	add    $0x10,%esp
801015fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101601:	8b 45 0c             	mov    0xc(%ebp),%eax
80101604:	25 ff 0f 00 00       	and    $0xfff,%eax
80101609:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010160c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010160f:	99                   	cltd   
80101610:	c1 ea 1d             	shr    $0x1d,%edx
80101613:	01 d0                	add    %edx,%eax
80101615:	83 e0 07             	and    $0x7,%eax
80101618:	29 d0                	sub    %edx,%eax
8010161a:	ba 01 00 00 00       	mov    $0x1,%edx
8010161f:	89 c1                	mov    %eax,%ecx
80101621:	d3 e2                	shl    %cl,%edx
80101623:	89 d0                	mov    %edx,%eax
80101625:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101628:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010162b:	8d 50 07             	lea    0x7(%eax),%edx
8010162e:	85 c0                	test   %eax,%eax
80101630:	0f 48 c2             	cmovs  %edx,%eax
80101633:	c1 f8 03             	sar    $0x3,%eax
80101636:	89 c2                	mov    %eax,%edx
80101638:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010163b:	0f b6 44 10 5c       	movzbl 0x5c(%eax,%edx,1),%eax
80101640:	0f b6 c0             	movzbl %al,%eax
80101643:	23 45 ec             	and    -0x14(%ebp),%eax
80101646:	85 c0                	test   %eax,%eax
80101648:	75 0d                	jne    80101657 <bfree+0x91>
    panic("freeing free block");
8010164a:	83 ec 0c             	sub    $0xc,%esp
8010164d:	68 ee 83 10 80       	push   $0x801083ee
80101652:	e8 49 ef ff ff       	call   801005a0 <panic>
  bp->data[bi/8] &= ~m;
80101657:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010165a:	8d 50 07             	lea    0x7(%eax),%edx
8010165d:	85 c0                	test   %eax,%eax
8010165f:	0f 48 c2             	cmovs  %edx,%eax
80101662:	c1 f8 03             	sar    $0x3,%eax
80101665:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101668:	0f b6 54 02 5c       	movzbl 0x5c(%edx,%eax,1),%edx
8010166d:	89 d1                	mov    %edx,%ecx
8010166f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101672:	f7 d2                	not    %edx
80101674:	21 ca                	and    %ecx,%edx
80101676:	89 d1                	mov    %edx,%ecx
80101678:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010167b:	88 4c 02 5c          	mov    %cl,0x5c(%edx,%eax,1)
  log_write(bp);
8010167f:	83 ec 0c             	sub    $0xc,%esp
80101682:	ff 75 f4             	pushl  -0xc(%ebp)
80101685:	e8 e3 20 00 00       	call   8010376d <log_write>
8010168a:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
8010168d:	83 ec 0c             	sub    $0xc,%esp
80101690:	ff 75 f4             	pushl  -0xc(%ebp)
80101693:	e8 b8 eb ff ff       	call   80100250 <brelse>
80101698:	83 c4 10             	add    $0x10,%esp
}
8010169b:	90                   	nop
8010169c:	c9                   	leave  
8010169d:	c3                   	ret    

8010169e <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
8010169e:	55                   	push   %ebp
8010169f:	89 e5                	mov    %esp,%ebp
801016a1:	57                   	push   %edi
801016a2:	56                   	push   %esi
801016a3:	53                   	push   %ebx
801016a4:	83 ec 2c             	sub    $0x2c,%esp
  int i = 0;
801016a7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  
  initlock(&icache.lock, "icache");
801016ae:	83 ec 08             	sub    $0x8,%esp
801016b1:	68 01 84 10 80       	push   $0x80108401
801016b6:	68 60 1a 11 80       	push   $0x80111a60
801016bb:	e8 a9 38 00 00       	call   80104f69 <initlock>
801016c0:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NINODE; i++) {
801016c3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801016ca:	eb 2d                	jmp    801016f9 <iinit+0x5b>
    initsleeplock(&icache.inode[i].lock, "inode");
801016cc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801016cf:	89 d0                	mov    %edx,%eax
801016d1:	c1 e0 03             	shl    $0x3,%eax
801016d4:	01 d0                	add    %edx,%eax
801016d6:	c1 e0 04             	shl    $0x4,%eax
801016d9:	83 c0 30             	add    $0x30,%eax
801016dc:	05 60 1a 11 80       	add    $0x80111a60,%eax
801016e1:	83 c0 10             	add    $0x10,%eax
801016e4:	83 ec 08             	sub    $0x8,%esp
801016e7:	68 08 84 10 80       	push   $0x80108408
801016ec:	50                   	push   %eax
801016ed:	e8 1a 37 00 00       	call   80104e0c <initsleeplock>
801016f2:	83 c4 10             	add    $0x10,%esp
iinit(int dev)
{
  int i = 0;
  
  initlock(&icache.lock, "icache");
  for(i = 0; i < NINODE; i++) {
801016f5:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801016f9:	83 7d e4 31          	cmpl   $0x31,-0x1c(%ebp)
801016fd:	7e cd                	jle    801016cc <iinit+0x2e>
    initsleeplock(&icache.inode[i].lock, "inode");
  }

  readsb(dev, &sb);
801016ff:	83 ec 08             	sub    $0x8,%esp
80101702:	68 40 1a 11 80       	push   $0x80111a40
80101707:	ff 75 08             	pushl  0x8(%ebp)
8010170a:	e8 d5 fc ff ff       	call   801013e4 <readsb>
8010170f:	83 c4 10             	add    $0x10,%esp
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101712:	a1 58 1a 11 80       	mov    0x80111a58,%eax
80101717:	89 45 d4             	mov    %eax,-0x2c(%ebp)
8010171a:	8b 3d 54 1a 11 80    	mov    0x80111a54,%edi
80101720:	8b 35 50 1a 11 80    	mov    0x80111a50,%esi
80101726:	8b 1d 4c 1a 11 80    	mov    0x80111a4c,%ebx
8010172c:	8b 0d 48 1a 11 80    	mov    0x80111a48,%ecx
80101732:	8b 15 44 1a 11 80    	mov    0x80111a44,%edx
80101738:	a1 40 1a 11 80       	mov    0x80111a40,%eax
8010173d:	ff 75 d4             	pushl  -0x2c(%ebp)
80101740:	57                   	push   %edi
80101741:	56                   	push   %esi
80101742:	53                   	push   %ebx
80101743:	51                   	push   %ecx
80101744:	52                   	push   %edx
80101745:	50                   	push   %eax
80101746:	68 10 84 10 80       	push   $0x80108410
8010174b:	e8 b0 ec ff ff       	call   80100400 <cprintf>
80101750:	83 c4 20             	add    $0x20,%esp
 inodestart %d bmap start %d\n", sb.size, sb.nblocks,
          sb.ninodes, sb.nlog, sb.logstart, sb.inodestart,
          sb.bmapstart);
}
80101753:	90                   	nop
80101754:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101757:	5b                   	pop    %ebx
80101758:	5e                   	pop    %esi
80101759:	5f                   	pop    %edi
8010175a:	5d                   	pop    %ebp
8010175b:	c3                   	ret    

8010175c <ialloc>:
// Allocate an inode on device dev.
// Mark it as allocated by  giving it type type.
// Returns an unlocked but allocated and referenced inode.
struct inode*
ialloc(uint dev, short type)
{
8010175c:	55                   	push   %ebp
8010175d:	89 e5                	mov    %esp,%ebp
8010175f:	83 ec 28             	sub    $0x28,%esp
80101762:	8b 45 0c             	mov    0xc(%ebp),%eax
80101765:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101769:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101770:	e9 9e 00 00 00       	jmp    80101813 <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
80101775:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101778:	c1 e8 03             	shr    $0x3,%eax
8010177b:	89 c2                	mov    %eax,%edx
8010177d:	a1 54 1a 11 80       	mov    0x80111a54,%eax
80101782:	01 d0                	add    %edx,%eax
80101784:	83 ec 08             	sub    $0x8,%esp
80101787:	50                   	push   %eax
80101788:	ff 75 08             	pushl  0x8(%ebp)
8010178b:	e8 3e ea ff ff       	call   801001ce <bread>
80101790:	83 c4 10             	add    $0x10,%esp
80101793:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101796:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101799:	8d 50 5c             	lea    0x5c(%eax),%edx
8010179c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010179f:	83 e0 07             	and    $0x7,%eax
801017a2:	c1 e0 06             	shl    $0x6,%eax
801017a5:	01 d0                	add    %edx,%eax
801017a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801017aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017ad:	0f b7 00             	movzwl (%eax),%eax
801017b0:	66 85 c0             	test   %ax,%ax
801017b3:	75 4c                	jne    80101801 <ialloc+0xa5>
      memset(dip, 0, sizeof(*dip));
801017b5:	83 ec 04             	sub    $0x4,%esp
801017b8:	6a 40                	push   $0x40
801017ba:	6a 00                	push   $0x0
801017bc:	ff 75 ec             	pushl  -0x14(%ebp)
801017bf:	e8 3e 3a 00 00       	call   80105202 <memset>
801017c4:	83 c4 10             	add    $0x10,%esp
      dip->type = type;
801017c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017ca:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
801017ce:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801017d1:	83 ec 0c             	sub    $0xc,%esp
801017d4:	ff 75 f0             	pushl  -0x10(%ebp)
801017d7:	e8 91 1f 00 00       	call   8010376d <log_write>
801017dc:	83 c4 10             	add    $0x10,%esp
      brelse(bp);
801017df:	83 ec 0c             	sub    $0xc,%esp
801017e2:	ff 75 f0             	pushl  -0x10(%ebp)
801017e5:	e8 66 ea ff ff       	call   80100250 <brelse>
801017ea:	83 c4 10             	add    $0x10,%esp
      return iget(dev, inum);
801017ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017f0:	83 ec 08             	sub    $0x8,%esp
801017f3:	50                   	push   %eax
801017f4:	ff 75 08             	pushl  0x8(%ebp)
801017f7:	e8 f8 00 00 00       	call   801018f4 <iget>
801017fc:	83 c4 10             	add    $0x10,%esp
801017ff:	eb 30                	jmp    80101831 <ialloc+0xd5>
    }
    brelse(bp);
80101801:	83 ec 0c             	sub    $0xc,%esp
80101804:	ff 75 f0             	pushl  -0x10(%ebp)
80101807:	e8 44 ea ff ff       	call   80100250 <brelse>
8010180c:	83 c4 10             	add    $0x10,%esp
{
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
8010180f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101813:	8b 15 48 1a 11 80    	mov    0x80111a48,%edx
80101819:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010181c:	39 c2                	cmp    %eax,%edx
8010181e:	0f 87 51 ff ff ff    	ja     80101775 <ialloc+0x19>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101824:	83 ec 0c             	sub    $0xc,%esp
80101827:	68 63 84 10 80       	push   $0x80108463
8010182c:	e8 6f ed ff ff       	call   801005a0 <panic>
}
80101831:	c9                   	leave  
80101832:	c3                   	ret    

80101833 <iupdate>:
// Must be called after every change to an ip->xxx field
// that lives on disk, since i-node cache is write-through.
// Caller must hold ip->lock.
void
iupdate(struct inode *ip)
{
80101833:	55                   	push   %ebp
80101834:	89 e5                	mov    %esp,%ebp
80101836:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101839:	8b 45 08             	mov    0x8(%ebp),%eax
8010183c:	8b 40 04             	mov    0x4(%eax),%eax
8010183f:	c1 e8 03             	shr    $0x3,%eax
80101842:	89 c2                	mov    %eax,%edx
80101844:	a1 54 1a 11 80       	mov    0x80111a54,%eax
80101849:	01 c2                	add    %eax,%edx
8010184b:	8b 45 08             	mov    0x8(%ebp),%eax
8010184e:	8b 00                	mov    (%eax),%eax
80101850:	83 ec 08             	sub    $0x8,%esp
80101853:	52                   	push   %edx
80101854:	50                   	push   %eax
80101855:	e8 74 e9 ff ff       	call   801001ce <bread>
8010185a:	83 c4 10             	add    $0x10,%esp
8010185d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101860:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101863:	8d 50 5c             	lea    0x5c(%eax),%edx
80101866:	8b 45 08             	mov    0x8(%ebp),%eax
80101869:	8b 40 04             	mov    0x4(%eax),%eax
8010186c:	83 e0 07             	and    $0x7,%eax
8010186f:	c1 e0 06             	shl    $0x6,%eax
80101872:	01 d0                	add    %edx,%eax
80101874:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101877:	8b 45 08             	mov    0x8(%ebp),%eax
8010187a:	0f b7 50 50          	movzwl 0x50(%eax),%edx
8010187e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101881:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101884:	8b 45 08             	mov    0x8(%ebp),%eax
80101887:	0f b7 50 52          	movzwl 0x52(%eax),%edx
8010188b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010188e:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101892:	8b 45 08             	mov    0x8(%ebp),%eax
80101895:	0f b7 50 54          	movzwl 0x54(%eax),%edx
80101899:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010189c:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801018a0:	8b 45 08             	mov    0x8(%ebp),%eax
801018a3:	0f b7 50 56          	movzwl 0x56(%eax),%edx
801018a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018aa:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801018ae:	8b 45 08             	mov    0x8(%ebp),%eax
801018b1:	8b 50 58             	mov    0x58(%eax),%edx
801018b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018b7:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801018ba:	8b 45 08             	mov    0x8(%ebp),%eax
801018bd:	8d 50 5c             	lea    0x5c(%eax),%edx
801018c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018c3:	83 c0 0c             	add    $0xc,%eax
801018c6:	83 ec 04             	sub    $0x4,%esp
801018c9:	6a 34                	push   $0x34
801018cb:	52                   	push   %edx
801018cc:	50                   	push   %eax
801018cd:	e8 ef 39 00 00       	call   801052c1 <memmove>
801018d2:	83 c4 10             	add    $0x10,%esp
  log_write(bp);
801018d5:	83 ec 0c             	sub    $0xc,%esp
801018d8:	ff 75 f4             	pushl  -0xc(%ebp)
801018db:	e8 8d 1e 00 00       	call   8010376d <log_write>
801018e0:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
801018e3:	83 ec 0c             	sub    $0xc,%esp
801018e6:	ff 75 f4             	pushl  -0xc(%ebp)
801018e9:	e8 62 e9 ff ff       	call   80100250 <brelse>
801018ee:	83 c4 10             	add    $0x10,%esp
}
801018f1:	90                   	nop
801018f2:	c9                   	leave  
801018f3:	c3                   	ret    

801018f4 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801018f4:	55                   	push   %ebp
801018f5:	89 e5                	mov    %esp,%ebp
801018f7:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801018fa:	83 ec 0c             	sub    $0xc,%esp
801018fd:	68 60 1a 11 80       	push   $0x80111a60
80101902:	e8 84 36 00 00       	call   80104f8b <acquire>
80101907:	83 c4 10             	add    $0x10,%esp

  // Is the inode already cached?
  empty = 0;
8010190a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101911:	c7 45 f4 94 1a 11 80 	movl   $0x80111a94,-0xc(%ebp)
80101918:	eb 60                	jmp    8010197a <iget+0x86>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010191a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010191d:	8b 40 08             	mov    0x8(%eax),%eax
80101920:	85 c0                	test   %eax,%eax
80101922:	7e 39                	jle    8010195d <iget+0x69>
80101924:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101927:	8b 00                	mov    (%eax),%eax
80101929:	3b 45 08             	cmp    0x8(%ebp),%eax
8010192c:	75 2f                	jne    8010195d <iget+0x69>
8010192e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101931:	8b 40 04             	mov    0x4(%eax),%eax
80101934:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101937:	75 24                	jne    8010195d <iget+0x69>
      ip->ref++;
80101939:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010193c:	8b 40 08             	mov    0x8(%eax),%eax
8010193f:	8d 50 01             	lea    0x1(%eax),%edx
80101942:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101945:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101948:	83 ec 0c             	sub    $0xc,%esp
8010194b:	68 60 1a 11 80       	push   $0x80111a60
80101950:	e8 a4 36 00 00       	call   80104ff9 <release>
80101955:	83 c4 10             	add    $0x10,%esp
      return ip;
80101958:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010195b:	eb 77                	jmp    801019d4 <iget+0xe0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010195d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101961:	75 10                	jne    80101973 <iget+0x7f>
80101963:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101966:	8b 40 08             	mov    0x8(%eax),%eax
80101969:	85 c0                	test   %eax,%eax
8010196b:	75 06                	jne    80101973 <iget+0x7f>
      empty = ip;
8010196d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101970:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101973:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
8010197a:	81 7d f4 b4 36 11 80 	cmpl   $0x801136b4,-0xc(%ebp)
80101981:	72 97                	jb     8010191a <iget+0x26>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101983:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101987:	75 0d                	jne    80101996 <iget+0xa2>
    panic("iget: no inodes");
80101989:	83 ec 0c             	sub    $0xc,%esp
8010198c:	68 75 84 10 80       	push   $0x80108475
80101991:	e8 0a ec ff ff       	call   801005a0 <panic>

  ip = empty;
80101996:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101999:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
8010199c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010199f:	8b 55 08             	mov    0x8(%ebp),%edx
801019a2:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801019a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019a7:	8b 55 0c             	mov    0xc(%ebp),%edx
801019aa:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
801019ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019b0:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->valid = 0;
801019b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019ba:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  release(&icache.lock);
801019c1:	83 ec 0c             	sub    $0xc,%esp
801019c4:	68 60 1a 11 80       	push   $0x80111a60
801019c9:	e8 2b 36 00 00       	call   80104ff9 <release>
801019ce:	83 c4 10             	add    $0x10,%esp

  return ip;
801019d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801019d4:	c9                   	leave  
801019d5:	c3                   	ret    

801019d6 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801019d6:	55                   	push   %ebp
801019d7:	89 e5                	mov    %esp,%ebp
801019d9:	83 ec 08             	sub    $0x8,%esp
  acquire(&icache.lock);
801019dc:	83 ec 0c             	sub    $0xc,%esp
801019df:	68 60 1a 11 80       	push   $0x80111a60
801019e4:	e8 a2 35 00 00       	call   80104f8b <acquire>
801019e9:	83 c4 10             	add    $0x10,%esp
  ip->ref++;
801019ec:	8b 45 08             	mov    0x8(%ebp),%eax
801019ef:	8b 40 08             	mov    0x8(%eax),%eax
801019f2:	8d 50 01             	lea    0x1(%eax),%edx
801019f5:	8b 45 08             	mov    0x8(%ebp),%eax
801019f8:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801019fb:	83 ec 0c             	sub    $0xc,%esp
801019fe:	68 60 1a 11 80       	push   $0x80111a60
80101a03:	e8 f1 35 00 00       	call   80104ff9 <release>
80101a08:	83 c4 10             	add    $0x10,%esp
  return ip;
80101a0b:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101a0e:	c9                   	leave  
80101a0f:	c3                   	ret    

80101a10 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101a10:	55                   	push   %ebp
80101a11:	89 e5                	mov    %esp,%ebp
80101a13:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101a16:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a1a:	74 0a                	je     80101a26 <ilock+0x16>
80101a1c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a1f:	8b 40 08             	mov    0x8(%eax),%eax
80101a22:	85 c0                	test   %eax,%eax
80101a24:	7f 0d                	jg     80101a33 <ilock+0x23>
    panic("ilock");
80101a26:	83 ec 0c             	sub    $0xc,%esp
80101a29:	68 85 84 10 80       	push   $0x80108485
80101a2e:	e8 6d eb ff ff       	call   801005a0 <panic>

  acquiresleep(&ip->lock);
80101a33:	8b 45 08             	mov    0x8(%ebp),%eax
80101a36:	83 c0 0c             	add    $0xc,%eax
80101a39:	83 ec 0c             	sub    $0xc,%esp
80101a3c:	50                   	push   %eax
80101a3d:	e8 06 34 00 00       	call   80104e48 <acquiresleep>
80101a42:	83 c4 10             	add    $0x10,%esp

  if(ip->valid == 0){
80101a45:	8b 45 08             	mov    0x8(%ebp),%eax
80101a48:	8b 40 4c             	mov    0x4c(%eax),%eax
80101a4b:	85 c0                	test   %eax,%eax
80101a4d:	0f 85 cd 00 00 00    	jne    80101b20 <ilock+0x110>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101a53:	8b 45 08             	mov    0x8(%ebp),%eax
80101a56:	8b 40 04             	mov    0x4(%eax),%eax
80101a59:	c1 e8 03             	shr    $0x3,%eax
80101a5c:	89 c2                	mov    %eax,%edx
80101a5e:	a1 54 1a 11 80       	mov    0x80111a54,%eax
80101a63:	01 c2                	add    %eax,%edx
80101a65:	8b 45 08             	mov    0x8(%ebp),%eax
80101a68:	8b 00                	mov    (%eax),%eax
80101a6a:	83 ec 08             	sub    $0x8,%esp
80101a6d:	52                   	push   %edx
80101a6e:	50                   	push   %eax
80101a6f:	e8 5a e7 ff ff       	call   801001ce <bread>
80101a74:	83 c4 10             	add    $0x10,%esp
80101a77:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101a7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a7d:	8d 50 5c             	lea    0x5c(%eax),%edx
80101a80:	8b 45 08             	mov    0x8(%ebp),%eax
80101a83:	8b 40 04             	mov    0x4(%eax),%eax
80101a86:	83 e0 07             	and    $0x7,%eax
80101a89:	c1 e0 06             	shl    $0x6,%eax
80101a8c:	01 d0                	add    %edx,%eax
80101a8e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101a91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a94:	0f b7 10             	movzwl (%eax),%edx
80101a97:	8b 45 08             	mov    0x8(%ebp),%eax
80101a9a:	66 89 50 50          	mov    %dx,0x50(%eax)
    ip->major = dip->major;
80101a9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aa1:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101aa5:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa8:	66 89 50 52          	mov    %dx,0x52(%eax)
    ip->minor = dip->minor;
80101aac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aaf:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101ab3:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab6:	66 89 50 54          	mov    %dx,0x54(%eax)
    ip->nlink = dip->nlink;
80101aba:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101abd:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101ac1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac4:	66 89 50 56          	mov    %dx,0x56(%eax)
    ip->size = dip->size;
80101ac8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101acb:	8b 50 08             	mov    0x8(%eax),%edx
80101ace:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad1:	89 50 58             	mov    %edx,0x58(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101ad4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ad7:	8d 50 0c             	lea    0xc(%eax),%edx
80101ada:	8b 45 08             	mov    0x8(%ebp),%eax
80101add:	83 c0 5c             	add    $0x5c,%eax
80101ae0:	83 ec 04             	sub    $0x4,%esp
80101ae3:	6a 34                	push   $0x34
80101ae5:	52                   	push   %edx
80101ae6:	50                   	push   %eax
80101ae7:	e8 d5 37 00 00       	call   801052c1 <memmove>
80101aec:	83 c4 10             	add    $0x10,%esp
    brelse(bp);
80101aef:	83 ec 0c             	sub    $0xc,%esp
80101af2:	ff 75 f4             	pushl  -0xc(%ebp)
80101af5:	e8 56 e7 ff ff       	call   80100250 <brelse>
80101afa:	83 c4 10             	add    $0x10,%esp
    ip->valid = 1;
80101afd:	8b 45 08             	mov    0x8(%ebp),%eax
80101b00:	c7 40 4c 01 00 00 00 	movl   $0x1,0x4c(%eax)
    if(ip->type == 0)
80101b07:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0a:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80101b0e:	66 85 c0             	test   %ax,%ax
80101b11:	75 0d                	jne    80101b20 <ilock+0x110>
      panic("ilock: no type");
80101b13:	83 ec 0c             	sub    $0xc,%esp
80101b16:	68 8b 84 10 80       	push   $0x8010848b
80101b1b:	e8 80 ea ff ff       	call   801005a0 <panic>
  }
}
80101b20:	90                   	nop
80101b21:	c9                   	leave  
80101b22:	c3                   	ret    

80101b23 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101b23:	55                   	push   %ebp
80101b24:	89 e5                	mov    %esp,%ebp
80101b26:	83 ec 08             	sub    $0x8,%esp
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
80101b29:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101b2d:	74 20                	je     80101b4f <iunlock+0x2c>
80101b2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b32:	83 c0 0c             	add    $0xc,%eax
80101b35:	83 ec 0c             	sub    $0xc,%esp
80101b38:	50                   	push   %eax
80101b39:	e8 bc 33 00 00       	call   80104efa <holdingsleep>
80101b3e:	83 c4 10             	add    $0x10,%esp
80101b41:	85 c0                	test   %eax,%eax
80101b43:	74 0a                	je     80101b4f <iunlock+0x2c>
80101b45:	8b 45 08             	mov    0x8(%ebp),%eax
80101b48:	8b 40 08             	mov    0x8(%eax),%eax
80101b4b:	85 c0                	test   %eax,%eax
80101b4d:	7f 0d                	jg     80101b5c <iunlock+0x39>
    panic("iunlock");
80101b4f:	83 ec 0c             	sub    $0xc,%esp
80101b52:	68 9a 84 10 80       	push   $0x8010849a
80101b57:	e8 44 ea ff ff       	call   801005a0 <panic>

  releasesleep(&ip->lock);
80101b5c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b5f:	83 c0 0c             	add    $0xc,%eax
80101b62:	83 ec 0c             	sub    $0xc,%esp
80101b65:	50                   	push   %eax
80101b66:	e8 41 33 00 00       	call   80104eac <releasesleep>
80101b6b:	83 c4 10             	add    $0x10,%esp
}
80101b6e:	90                   	nop
80101b6f:	c9                   	leave  
80101b70:	c3                   	ret    

80101b71 <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101b71:	55                   	push   %ebp
80101b72:	89 e5                	mov    %esp,%ebp
80101b74:	83 ec 18             	sub    $0x18,%esp
  acquiresleep(&ip->lock);
80101b77:	8b 45 08             	mov    0x8(%ebp),%eax
80101b7a:	83 c0 0c             	add    $0xc,%eax
80101b7d:	83 ec 0c             	sub    $0xc,%esp
80101b80:	50                   	push   %eax
80101b81:	e8 c2 32 00 00       	call   80104e48 <acquiresleep>
80101b86:	83 c4 10             	add    $0x10,%esp
  if(ip->valid && ip->nlink == 0){
80101b89:	8b 45 08             	mov    0x8(%ebp),%eax
80101b8c:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b8f:	85 c0                	test   %eax,%eax
80101b91:	74 6a                	je     80101bfd <iput+0x8c>
80101b93:	8b 45 08             	mov    0x8(%ebp),%eax
80101b96:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80101b9a:	66 85 c0             	test   %ax,%ax
80101b9d:	75 5e                	jne    80101bfd <iput+0x8c>
    acquire(&icache.lock);
80101b9f:	83 ec 0c             	sub    $0xc,%esp
80101ba2:	68 60 1a 11 80       	push   $0x80111a60
80101ba7:	e8 df 33 00 00       	call   80104f8b <acquire>
80101bac:	83 c4 10             	add    $0x10,%esp
    int r = ip->ref;
80101baf:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb2:	8b 40 08             	mov    0x8(%eax),%eax
80101bb5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    release(&icache.lock);
80101bb8:	83 ec 0c             	sub    $0xc,%esp
80101bbb:	68 60 1a 11 80       	push   $0x80111a60
80101bc0:	e8 34 34 00 00       	call   80104ff9 <release>
80101bc5:	83 c4 10             	add    $0x10,%esp
    if(r == 1){
80101bc8:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80101bcc:	75 2f                	jne    80101bfd <iput+0x8c>
      // inode has no links and no other references: truncate and free.
      itrunc(ip);
80101bce:	83 ec 0c             	sub    $0xc,%esp
80101bd1:	ff 75 08             	pushl  0x8(%ebp)
80101bd4:	e8 b2 01 00 00       	call   80101d8b <itrunc>
80101bd9:	83 c4 10             	add    $0x10,%esp
      ip->type = 0;
80101bdc:	8b 45 08             	mov    0x8(%ebp),%eax
80101bdf:	66 c7 40 50 00 00    	movw   $0x0,0x50(%eax)
      iupdate(ip);
80101be5:	83 ec 0c             	sub    $0xc,%esp
80101be8:	ff 75 08             	pushl  0x8(%ebp)
80101beb:	e8 43 fc ff ff       	call   80101833 <iupdate>
80101bf0:	83 c4 10             	add    $0x10,%esp
      ip->valid = 0;
80101bf3:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf6:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
    }
  }
  releasesleep(&ip->lock);
80101bfd:	8b 45 08             	mov    0x8(%ebp),%eax
80101c00:	83 c0 0c             	add    $0xc,%eax
80101c03:	83 ec 0c             	sub    $0xc,%esp
80101c06:	50                   	push   %eax
80101c07:	e8 a0 32 00 00       	call   80104eac <releasesleep>
80101c0c:	83 c4 10             	add    $0x10,%esp

  acquire(&icache.lock);
80101c0f:	83 ec 0c             	sub    $0xc,%esp
80101c12:	68 60 1a 11 80       	push   $0x80111a60
80101c17:	e8 6f 33 00 00       	call   80104f8b <acquire>
80101c1c:	83 c4 10             	add    $0x10,%esp
  ip->ref--;
80101c1f:	8b 45 08             	mov    0x8(%ebp),%eax
80101c22:	8b 40 08             	mov    0x8(%eax),%eax
80101c25:	8d 50 ff             	lea    -0x1(%eax),%edx
80101c28:	8b 45 08             	mov    0x8(%ebp),%eax
80101c2b:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101c2e:	83 ec 0c             	sub    $0xc,%esp
80101c31:	68 60 1a 11 80       	push   $0x80111a60
80101c36:	e8 be 33 00 00       	call   80104ff9 <release>
80101c3b:	83 c4 10             	add    $0x10,%esp
}
80101c3e:	90                   	nop
80101c3f:	c9                   	leave  
80101c40:	c3                   	ret    

80101c41 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101c41:	55                   	push   %ebp
80101c42:	89 e5                	mov    %esp,%ebp
80101c44:	83 ec 08             	sub    $0x8,%esp
  iunlock(ip);
80101c47:	83 ec 0c             	sub    $0xc,%esp
80101c4a:	ff 75 08             	pushl  0x8(%ebp)
80101c4d:	e8 d1 fe ff ff       	call   80101b23 <iunlock>
80101c52:	83 c4 10             	add    $0x10,%esp
  iput(ip);
80101c55:	83 ec 0c             	sub    $0xc,%esp
80101c58:	ff 75 08             	pushl  0x8(%ebp)
80101c5b:	e8 11 ff ff ff       	call   80101b71 <iput>
80101c60:	83 c4 10             	add    $0x10,%esp
}
80101c63:	90                   	nop
80101c64:	c9                   	leave  
80101c65:	c3                   	ret    

80101c66 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101c66:	55                   	push   %ebp
80101c67:	89 e5                	mov    %esp,%ebp
80101c69:	53                   	push   %ebx
80101c6a:	83 ec 14             	sub    $0x14,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101c6d:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101c71:	77 42                	ja     80101cb5 <bmap+0x4f>
    if((addr = ip->addrs[bn]) == 0)
80101c73:	8b 45 08             	mov    0x8(%ebp),%eax
80101c76:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c79:	83 c2 14             	add    $0x14,%edx
80101c7c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c80:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c83:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c87:	75 24                	jne    80101cad <bmap+0x47>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101c89:	8b 45 08             	mov    0x8(%ebp),%eax
80101c8c:	8b 00                	mov    (%eax),%eax
80101c8e:	83 ec 0c             	sub    $0xc,%esp
80101c91:	50                   	push   %eax
80101c92:	e8 e3 f7 ff ff       	call   8010147a <balloc>
80101c97:	83 c4 10             	add    $0x10,%esp
80101c9a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c9d:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca0:	8b 55 0c             	mov    0xc(%ebp),%edx
80101ca3:	8d 4a 14             	lea    0x14(%edx),%ecx
80101ca6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ca9:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101cad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cb0:	e9 d1 00 00 00       	jmp    80101d86 <bmap+0x120>
  }
  bn -= NDIRECT;
80101cb5:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101cb9:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101cbd:	0f 87 b6 00 00 00    	ja     80101d79 <bmap+0x113>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101cc3:	8b 45 08             	mov    0x8(%ebp),%eax
80101cc6:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101ccc:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ccf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101cd3:	75 20                	jne    80101cf5 <bmap+0x8f>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101cd5:	8b 45 08             	mov    0x8(%ebp),%eax
80101cd8:	8b 00                	mov    (%eax),%eax
80101cda:	83 ec 0c             	sub    $0xc,%esp
80101cdd:	50                   	push   %eax
80101cde:	e8 97 f7 ff ff       	call   8010147a <balloc>
80101ce3:	83 c4 10             	add    $0x10,%esp
80101ce6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ce9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cec:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cef:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
    bp = bread(ip->dev, addr);
80101cf5:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf8:	8b 00                	mov    (%eax),%eax
80101cfa:	83 ec 08             	sub    $0x8,%esp
80101cfd:	ff 75 f4             	pushl  -0xc(%ebp)
80101d00:	50                   	push   %eax
80101d01:	e8 c8 e4 ff ff       	call   801001ce <bread>
80101d06:	83 c4 10             	add    $0x10,%esp
80101d09:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101d0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d0f:	83 c0 5c             	add    $0x5c,%eax
80101d12:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101d15:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d18:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d1f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d22:	01 d0                	add    %edx,%eax
80101d24:	8b 00                	mov    (%eax),%eax
80101d26:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d29:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101d2d:	75 37                	jne    80101d66 <bmap+0x100>
      a[bn] = addr = balloc(ip->dev);
80101d2f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d32:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d39:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d3c:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101d3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d42:	8b 00                	mov    (%eax),%eax
80101d44:	83 ec 0c             	sub    $0xc,%esp
80101d47:	50                   	push   %eax
80101d48:	e8 2d f7 ff ff       	call   8010147a <balloc>
80101d4d:	83 c4 10             	add    $0x10,%esp
80101d50:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d56:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101d58:	83 ec 0c             	sub    $0xc,%esp
80101d5b:	ff 75 f0             	pushl  -0x10(%ebp)
80101d5e:	e8 0a 1a 00 00       	call   8010376d <log_write>
80101d63:	83 c4 10             	add    $0x10,%esp
    }
    brelse(bp);
80101d66:	83 ec 0c             	sub    $0xc,%esp
80101d69:	ff 75 f0             	pushl  -0x10(%ebp)
80101d6c:	e8 df e4 ff ff       	call   80100250 <brelse>
80101d71:	83 c4 10             	add    $0x10,%esp
    return addr;
80101d74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d77:	eb 0d                	jmp    80101d86 <bmap+0x120>
  }

  panic("bmap: out of range");
80101d79:	83 ec 0c             	sub    $0xc,%esp
80101d7c:	68 a2 84 10 80       	push   $0x801084a2
80101d81:	e8 1a e8 ff ff       	call   801005a0 <panic>
}
80101d86:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101d89:	c9                   	leave  
80101d8a:	c3                   	ret    

80101d8b <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101d8b:	55                   	push   %ebp
80101d8c:	89 e5                	mov    %esp,%ebp
80101d8e:	83 ec 18             	sub    $0x18,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d91:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101d98:	eb 45                	jmp    80101ddf <itrunc+0x54>
    if(ip->addrs[i]){
80101d9a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d9d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101da0:	83 c2 14             	add    $0x14,%edx
80101da3:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101da7:	85 c0                	test   %eax,%eax
80101da9:	74 30                	je     80101ddb <itrunc+0x50>
      bfree(ip->dev, ip->addrs[i]);
80101dab:	8b 45 08             	mov    0x8(%ebp),%eax
80101dae:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101db1:	83 c2 14             	add    $0x14,%edx
80101db4:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101db8:	8b 55 08             	mov    0x8(%ebp),%edx
80101dbb:	8b 12                	mov    (%edx),%edx
80101dbd:	83 ec 08             	sub    $0x8,%esp
80101dc0:	50                   	push   %eax
80101dc1:	52                   	push   %edx
80101dc2:	e8 ff f7 ff ff       	call   801015c6 <bfree>
80101dc7:	83 c4 10             	add    $0x10,%esp
      ip->addrs[i] = 0;
80101dca:	8b 45 08             	mov    0x8(%ebp),%eax
80101dcd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101dd0:	83 c2 14             	add    $0x14,%edx
80101dd3:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101dda:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101ddb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101ddf:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101de3:	7e b5                	jle    80101d9a <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }

  if(ip->addrs[NDIRECT]){
80101de5:	8b 45 08             	mov    0x8(%ebp),%eax
80101de8:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101dee:	85 c0                	test   %eax,%eax
80101df0:	0f 84 aa 00 00 00    	je     80101ea0 <itrunc+0x115>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101df6:	8b 45 08             	mov    0x8(%ebp),%eax
80101df9:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80101dff:	8b 45 08             	mov    0x8(%ebp),%eax
80101e02:	8b 00                	mov    (%eax),%eax
80101e04:	83 ec 08             	sub    $0x8,%esp
80101e07:	52                   	push   %edx
80101e08:	50                   	push   %eax
80101e09:	e8 c0 e3 ff ff       	call   801001ce <bread>
80101e0e:	83 c4 10             	add    $0x10,%esp
80101e11:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101e14:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e17:	83 c0 5c             	add    $0x5c,%eax
80101e1a:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101e1d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101e24:	eb 3c                	jmp    80101e62 <itrunc+0xd7>
      if(a[j])
80101e26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e29:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e30:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e33:	01 d0                	add    %edx,%eax
80101e35:	8b 00                	mov    (%eax),%eax
80101e37:	85 c0                	test   %eax,%eax
80101e39:	74 23                	je     80101e5e <itrunc+0xd3>
        bfree(ip->dev, a[j]);
80101e3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e3e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e45:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e48:	01 d0                	add    %edx,%eax
80101e4a:	8b 00                	mov    (%eax),%eax
80101e4c:	8b 55 08             	mov    0x8(%ebp),%edx
80101e4f:	8b 12                	mov    (%edx),%edx
80101e51:	83 ec 08             	sub    $0x8,%esp
80101e54:	50                   	push   %eax
80101e55:	52                   	push   %edx
80101e56:	e8 6b f7 ff ff       	call   801015c6 <bfree>
80101e5b:	83 c4 10             	add    $0x10,%esp
  }

  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101e5e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101e62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e65:	83 f8 7f             	cmp    $0x7f,%eax
80101e68:	76 bc                	jbe    80101e26 <itrunc+0x9b>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	ff 75 ec             	pushl  -0x14(%ebp)
80101e70:	e8 db e3 ff ff       	call   80100250 <brelse>
80101e75:	83 c4 10             	add    $0x10,%esp
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101e78:	8b 45 08             	mov    0x8(%ebp),%eax
80101e7b:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101e81:	8b 55 08             	mov    0x8(%ebp),%edx
80101e84:	8b 12                	mov    (%edx),%edx
80101e86:	83 ec 08             	sub    $0x8,%esp
80101e89:	50                   	push   %eax
80101e8a:	52                   	push   %edx
80101e8b:	e8 36 f7 ff ff       	call   801015c6 <bfree>
80101e90:	83 c4 10             	add    $0x10,%esp
    ip->addrs[NDIRECT] = 0;
80101e93:	8b 45 08             	mov    0x8(%ebp),%eax
80101e96:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80101e9d:	00 00 00 
  }

  ip->size = 0;
80101ea0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea3:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
  iupdate(ip);
80101eaa:	83 ec 0c             	sub    $0xc,%esp
80101ead:	ff 75 08             	pushl  0x8(%ebp)
80101eb0:	e8 7e f9 ff ff       	call   80101833 <iupdate>
80101eb5:	83 c4 10             	add    $0x10,%esp
}
80101eb8:	90                   	nop
80101eb9:	c9                   	leave  
80101eba:	c3                   	ret    

80101ebb <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
80101ebb:	55                   	push   %ebp
80101ebc:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101ebe:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec1:	8b 00                	mov    (%eax),%eax
80101ec3:	89 c2                	mov    %eax,%edx
80101ec5:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ec8:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101ecb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ece:	8b 50 04             	mov    0x4(%eax),%edx
80101ed1:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ed4:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101ed7:	8b 45 08             	mov    0x8(%ebp),%eax
80101eda:	0f b7 50 50          	movzwl 0x50(%eax),%edx
80101ede:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ee1:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101ee4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee7:	0f b7 50 56          	movzwl 0x56(%eax),%edx
80101eeb:	8b 45 0c             	mov    0xc(%ebp),%eax
80101eee:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101ef2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef5:	8b 50 58             	mov    0x58(%eax),%edx
80101ef8:	8b 45 0c             	mov    0xc(%ebp),%eax
80101efb:	89 50 10             	mov    %edx,0x10(%eax)
}
80101efe:	90                   	nop
80101eff:	5d                   	pop    %ebp
80101f00:	c3                   	ret    

80101f01 <readi>:
//PAGEBREAK!
// Read data from inode.
// Caller must hold ip->lock.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101f01:	55                   	push   %ebp
80101f02:	89 e5                	mov    %esp,%ebp
80101f04:	83 ec 18             	sub    $0x18,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f07:	8b 45 08             	mov    0x8(%ebp),%eax
80101f0a:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80101f0e:	66 83 f8 03          	cmp    $0x3,%ax
80101f12:	75 5c                	jne    80101f70 <readi+0x6f>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101f14:	8b 45 08             	mov    0x8(%ebp),%eax
80101f17:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f1b:	66 85 c0             	test   %ax,%ax
80101f1e:	78 20                	js     80101f40 <readi+0x3f>
80101f20:	8b 45 08             	mov    0x8(%ebp),%eax
80101f23:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f27:	66 83 f8 09          	cmp    $0x9,%ax
80101f2b:	7f 13                	jg     80101f40 <readi+0x3f>
80101f2d:	8b 45 08             	mov    0x8(%ebp),%eax
80101f30:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f34:	98                   	cwtl   
80101f35:	8b 04 c5 e0 19 11 80 	mov    -0x7feee620(,%eax,8),%eax
80101f3c:	85 c0                	test   %eax,%eax
80101f3e:	75 0a                	jne    80101f4a <readi+0x49>
      return -1;
80101f40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f45:	e9 0c 01 00 00       	jmp    80102056 <readi+0x155>
    return devsw[ip->major].read(ip, dst, n);
80101f4a:	8b 45 08             	mov    0x8(%ebp),%eax
80101f4d:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f51:	98                   	cwtl   
80101f52:	8b 04 c5 e0 19 11 80 	mov    -0x7feee620(,%eax,8),%eax
80101f59:	8b 55 14             	mov    0x14(%ebp),%edx
80101f5c:	83 ec 04             	sub    $0x4,%esp
80101f5f:	52                   	push   %edx
80101f60:	ff 75 0c             	pushl  0xc(%ebp)
80101f63:	ff 75 08             	pushl  0x8(%ebp)
80101f66:	ff d0                	call   *%eax
80101f68:	83 c4 10             	add    $0x10,%esp
80101f6b:	e9 e6 00 00 00       	jmp    80102056 <readi+0x155>
  }

  if(off > ip->size || off + n < off)
80101f70:	8b 45 08             	mov    0x8(%ebp),%eax
80101f73:	8b 40 58             	mov    0x58(%eax),%eax
80101f76:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f79:	72 0d                	jb     80101f88 <readi+0x87>
80101f7b:	8b 55 10             	mov    0x10(%ebp),%edx
80101f7e:	8b 45 14             	mov    0x14(%ebp),%eax
80101f81:	01 d0                	add    %edx,%eax
80101f83:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f86:	73 0a                	jae    80101f92 <readi+0x91>
    return -1;
80101f88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f8d:	e9 c4 00 00 00       	jmp    80102056 <readi+0x155>
  if(off + n > ip->size)
80101f92:	8b 55 10             	mov    0x10(%ebp),%edx
80101f95:	8b 45 14             	mov    0x14(%ebp),%eax
80101f98:	01 c2                	add    %eax,%edx
80101f9a:	8b 45 08             	mov    0x8(%ebp),%eax
80101f9d:	8b 40 58             	mov    0x58(%eax),%eax
80101fa0:	39 c2                	cmp    %eax,%edx
80101fa2:	76 0c                	jbe    80101fb0 <readi+0xaf>
    n = ip->size - off;
80101fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa7:	8b 40 58             	mov    0x58(%eax),%eax
80101faa:	2b 45 10             	sub    0x10(%ebp),%eax
80101fad:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101fb0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101fb7:	e9 8b 00 00 00       	jmp    80102047 <readi+0x146>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101fbc:	8b 45 10             	mov    0x10(%ebp),%eax
80101fbf:	c1 e8 09             	shr    $0x9,%eax
80101fc2:	83 ec 08             	sub    $0x8,%esp
80101fc5:	50                   	push   %eax
80101fc6:	ff 75 08             	pushl  0x8(%ebp)
80101fc9:	e8 98 fc ff ff       	call   80101c66 <bmap>
80101fce:	83 c4 10             	add    $0x10,%esp
80101fd1:	89 c2                	mov    %eax,%edx
80101fd3:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd6:	8b 00                	mov    (%eax),%eax
80101fd8:	83 ec 08             	sub    $0x8,%esp
80101fdb:	52                   	push   %edx
80101fdc:	50                   	push   %eax
80101fdd:	e8 ec e1 ff ff       	call   801001ce <bread>
80101fe2:	83 c4 10             	add    $0x10,%esp
80101fe5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101fe8:	8b 45 10             	mov    0x10(%ebp),%eax
80101feb:	25 ff 01 00 00       	and    $0x1ff,%eax
80101ff0:	ba 00 02 00 00       	mov    $0x200,%edx
80101ff5:	29 c2                	sub    %eax,%edx
80101ff7:	8b 45 14             	mov    0x14(%ebp),%eax
80101ffa:	2b 45 f4             	sub    -0xc(%ebp),%eax
80101ffd:	39 c2                	cmp    %eax,%edx
80101fff:	0f 46 c2             	cmovbe %edx,%eax
80102002:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80102005:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102008:	8d 50 5c             	lea    0x5c(%eax),%edx
8010200b:	8b 45 10             	mov    0x10(%ebp),%eax
8010200e:	25 ff 01 00 00       	and    $0x1ff,%eax
80102013:	01 d0                	add    %edx,%eax
80102015:	83 ec 04             	sub    $0x4,%esp
80102018:	ff 75 ec             	pushl  -0x14(%ebp)
8010201b:	50                   	push   %eax
8010201c:	ff 75 0c             	pushl  0xc(%ebp)
8010201f:	e8 9d 32 00 00       	call   801052c1 <memmove>
80102024:	83 c4 10             	add    $0x10,%esp
    brelse(bp);
80102027:	83 ec 0c             	sub    $0xc,%esp
8010202a:	ff 75 f0             	pushl  -0x10(%ebp)
8010202d:	e8 1e e2 ff ff       	call   80100250 <brelse>
80102032:	83 c4 10             	add    $0x10,%esp
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102035:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102038:	01 45 f4             	add    %eax,-0xc(%ebp)
8010203b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010203e:	01 45 10             	add    %eax,0x10(%ebp)
80102041:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102044:	01 45 0c             	add    %eax,0xc(%ebp)
80102047:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010204a:	3b 45 14             	cmp    0x14(%ebp),%eax
8010204d:	0f 82 69 ff ff ff    	jb     80101fbc <readi+0xbb>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102053:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102056:	c9                   	leave  
80102057:	c3                   	ret    

80102058 <writei>:
// PAGEBREAK!
// Write data to inode.
// Caller must hold ip->lock.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102058:	55                   	push   %ebp
80102059:	89 e5                	mov    %esp,%ebp
8010205b:	83 ec 18             	sub    $0x18,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
8010205e:	8b 45 08             	mov    0x8(%ebp),%eax
80102061:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80102065:	66 83 f8 03          	cmp    $0x3,%ax
80102069:	75 5c                	jne    801020c7 <writei+0x6f>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
8010206b:	8b 45 08             	mov    0x8(%ebp),%eax
8010206e:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80102072:	66 85 c0             	test   %ax,%ax
80102075:	78 20                	js     80102097 <writei+0x3f>
80102077:	8b 45 08             	mov    0x8(%ebp),%eax
8010207a:	0f b7 40 52          	movzwl 0x52(%eax),%eax
8010207e:	66 83 f8 09          	cmp    $0x9,%ax
80102082:	7f 13                	jg     80102097 <writei+0x3f>
80102084:	8b 45 08             	mov    0x8(%ebp),%eax
80102087:	0f b7 40 52          	movzwl 0x52(%eax),%eax
8010208b:	98                   	cwtl   
8010208c:	8b 04 c5 e4 19 11 80 	mov    -0x7feee61c(,%eax,8),%eax
80102093:	85 c0                	test   %eax,%eax
80102095:	75 0a                	jne    801020a1 <writei+0x49>
      return -1;
80102097:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010209c:	e9 3d 01 00 00       	jmp    801021de <writei+0x186>
    return devsw[ip->major].write(ip, src, n);
801020a1:	8b 45 08             	mov    0x8(%ebp),%eax
801020a4:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801020a8:	98                   	cwtl   
801020a9:	8b 04 c5 e4 19 11 80 	mov    -0x7feee61c(,%eax,8),%eax
801020b0:	8b 55 14             	mov    0x14(%ebp),%edx
801020b3:	83 ec 04             	sub    $0x4,%esp
801020b6:	52                   	push   %edx
801020b7:	ff 75 0c             	pushl  0xc(%ebp)
801020ba:	ff 75 08             	pushl  0x8(%ebp)
801020bd:	ff d0                	call   *%eax
801020bf:	83 c4 10             	add    $0x10,%esp
801020c2:	e9 17 01 00 00       	jmp    801021de <writei+0x186>
  }

  if(off > ip->size || off + n < off)
801020c7:	8b 45 08             	mov    0x8(%ebp),%eax
801020ca:	8b 40 58             	mov    0x58(%eax),%eax
801020cd:	3b 45 10             	cmp    0x10(%ebp),%eax
801020d0:	72 0d                	jb     801020df <writei+0x87>
801020d2:	8b 55 10             	mov    0x10(%ebp),%edx
801020d5:	8b 45 14             	mov    0x14(%ebp),%eax
801020d8:	01 d0                	add    %edx,%eax
801020da:	3b 45 10             	cmp    0x10(%ebp),%eax
801020dd:	73 0a                	jae    801020e9 <writei+0x91>
    return -1;
801020df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020e4:	e9 f5 00 00 00       	jmp    801021de <writei+0x186>
  if(off + n > MAXFILE*BSIZE)
801020e9:	8b 55 10             	mov    0x10(%ebp),%edx
801020ec:	8b 45 14             	mov    0x14(%ebp),%eax
801020ef:	01 d0                	add    %edx,%eax
801020f1:	3d 00 18 01 00       	cmp    $0x11800,%eax
801020f6:	76 0a                	jbe    80102102 <writei+0xaa>
    return -1;
801020f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020fd:	e9 dc 00 00 00       	jmp    801021de <writei+0x186>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102102:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102109:	e9 99 00 00 00       	jmp    801021a7 <writei+0x14f>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010210e:	8b 45 10             	mov    0x10(%ebp),%eax
80102111:	c1 e8 09             	shr    $0x9,%eax
80102114:	83 ec 08             	sub    $0x8,%esp
80102117:	50                   	push   %eax
80102118:	ff 75 08             	pushl  0x8(%ebp)
8010211b:	e8 46 fb ff ff       	call   80101c66 <bmap>
80102120:	83 c4 10             	add    $0x10,%esp
80102123:	89 c2                	mov    %eax,%edx
80102125:	8b 45 08             	mov    0x8(%ebp),%eax
80102128:	8b 00                	mov    (%eax),%eax
8010212a:	83 ec 08             	sub    $0x8,%esp
8010212d:	52                   	push   %edx
8010212e:	50                   	push   %eax
8010212f:	e8 9a e0 ff ff       	call   801001ce <bread>
80102134:	83 c4 10             	add    $0x10,%esp
80102137:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
8010213a:	8b 45 10             	mov    0x10(%ebp),%eax
8010213d:	25 ff 01 00 00       	and    $0x1ff,%eax
80102142:	ba 00 02 00 00       	mov    $0x200,%edx
80102147:	29 c2                	sub    %eax,%edx
80102149:	8b 45 14             	mov    0x14(%ebp),%eax
8010214c:	2b 45 f4             	sub    -0xc(%ebp),%eax
8010214f:	39 c2                	cmp    %eax,%edx
80102151:	0f 46 c2             	cmovbe %edx,%eax
80102154:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102157:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010215a:	8d 50 5c             	lea    0x5c(%eax),%edx
8010215d:	8b 45 10             	mov    0x10(%ebp),%eax
80102160:	25 ff 01 00 00       	and    $0x1ff,%eax
80102165:	01 d0                	add    %edx,%eax
80102167:	83 ec 04             	sub    $0x4,%esp
8010216a:	ff 75 ec             	pushl  -0x14(%ebp)
8010216d:	ff 75 0c             	pushl  0xc(%ebp)
80102170:	50                   	push   %eax
80102171:	e8 4b 31 00 00       	call   801052c1 <memmove>
80102176:	83 c4 10             	add    $0x10,%esp
    log_write(bp);
80102179:	83 ec 0c             	sub    $0xc,%esp
8010217c:	ff 75 f0             	pushl  -0x10(%ebp)
8010217f:	e8 e9 15 00 00       	call   8010376d <log_write>
80102184:	83 c4 10             	add    $0x10,%esp
    brelse(bp);
80102187:	83 ec 0c             	sub    $0xc,%esp
8010218a:	ff 75 f0             	pushl  -0x10(%ebp)
8010218d:	e8 be e0 ff ff       	call   80100250 <brelse>
80102192:	83 c4 10             	add    $0x10,%esp
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102195:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102198:	01 45 f4             	add    %eax,-0xc(%ebp)
8010219b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010219e:	01 45 10             	add    %eax,0x10(%ebp)
801021a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021a4:	01 45 0c             	add    %eax,0xc(%ebp)
801021a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021aa:	3b 45 14             	cmp    0x14(%ebp),%eax
801021ad:	0f 82 5b ff ff ff    	jb     8010210e <writei+0xb6>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
801021b3:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801021b7:	74 22                	je     801021db <writei+0x183>
801021b9:	8b 45 08             	mov    0x8(%ebp),%eax
801021bc:	8b 40 58             	mov    0x58(%eax),%eax
801021bf:	3b 45 10             	cmp    0x10(%ebp),%eax
801021c2:	73 17                	jae    801021db <writei+0x183>
    ip->size = off;
801021c4:	8b 45 08             	mov    0x8(%ebp),%eax
801021c7:	8b 55 10             	mov    0x10(%ebp),%edx
801021ca:	89 50 58             	mov    %edx,0x58(%eax)
    iupdate(ip);
801021cd:	83 ec 0c             	sub    $0xc,%esp
801021d0:	ff 75 08             	pushl  0x8(%ebp)
801021d3:	e8 5b f6 ff ff       	call   80101833 <iupdate>
801021d8:	83 c4 10             	add    $0x10,%esp
  }
  return n;
801021db:	8b 45 14             	mov    0x14(%ebp),%eax
}
801021de:	c9                   	leave  
801021df:	c3                   	ret    

801021e0 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801021e0:	55                   	push   %ebp
801021e1:	89 e5                	mov    %esp,%ebp
801021e3:	83 ec 08             	sub    $0x8,%esp
  return strncmp(s, t, DIRSIZ);
801021e6:	83 ec 04             	sub    $0x4,%esp
801021e9:	6a 0e                	push   $0xe
801021eb:	ff 75 0c             	pushl  0xc(%ebp)
801021ee:	ff 75 08             	pushl  0x8(%ebp)
801021f1:	e8 61 31 00 00       	call   80105357 <strncmp>
801021f6:	83 c4 10             	add    $0x10,%esp
}
801021f9:	c9                   	leave  
801021fa:	c3                   	ret    

801021fb <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801021fb:	55                   	push   %ebp
801021fc:	89 e5                	mov    %esp,%ebp
801021fe:	83 ec 28             	sub    $0x28,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102201:	8b 45 08             	mov    0x8(%ebp),%eax
80102204:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80102208:	66 83 f8 01          	cmp    $0x1,%ax
8010220c:	74 0d                	je     8010221b <dirlookup+0x20>
    panic("dirlookup not DIR");
8010220e:	83 ec 0c             	sub    $0xc,%esp
80102211:	68 b5 84 10 80       	push   $0x801084b5
80102216:	e8 85 e3 ff ff       	call   801005a0 <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
8010221b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102222:	eb 7b                	jmp    8010229f <dirlookup+0xa4>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102224:	6a 10                	push   $0x10
80102226:	ff 75 f4             	pushl  -0xc(%ebp)
80102229:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010222c:	50                   	push   %eax
8010222d:	ff 75 08             	pushl  0x8(%ebp)
80102230:	e8 cc fc ff ff       	call   80101f01 <readi>
80102235:	83 c4 10             	add    $0x10,%esp
80102238:	83 f8 10             	cmp    $0x10,%eax
8010223b:	74 0d                	je     8010224a <dirlookup+0x4f>
      panic("dirlookup read");
8010223d:	83 ec 0c             	sub    $0xc,%esp
80102240:	68 c7 84 10 80       	push   $0x801084c7
80102245:	e8 56 e3 ff ff       	call   801005a0 <panic>
    if(de.inum == 0)
8010224a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010224e:	66 85 c0             	test   %ax,%ax
80102251:	74 47                	je     8010229a <dirlookup+0x9f>
      continue;
    if(namecmp(name, de.name) == 0){
80102253:	83 ec 08             	sub    $0x8,%esp
80102256:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102259:	83 c0 02             	add    $0x2,%eax
8010225c:	50                   	push   %eax
8010225d:	ff 75 0c             	pushl  0xc(%ebp)
80102260:	e8 7b ff ff ff       	call   801021e0 <namecmp>
80102265:	83 c4 10             	add    $0x10,%esp
80102268:	85 c0                	test   %eax,%eax
8010226a:	75 2f                	jne    8010229b <dirlookup+0xa0>
      // entry matches path element
      if(poff)
8010226c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102270:	74 08                	je     8010227a <dirlookup+0x7f>
        *poff = off;
80102272:	8b 45 10             	mov    0x10(%ebp),%eax
80102275:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102278:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010227a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010227e:	0f b7 c0             	movzwl %ax,%eax
80102281:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102284:	8b 45 08             	mov    0x8(%ebp),%eax
80102287:	8b 00                	mov    (%eax),%eax
80102289:	83 ec 08             	sub    $0x8,%esp
8010228c:	ff 75 f0             	pushl  -0x10(%ebp)
8010228f:	50                   	push   %eax
80102290:	e8 5f f6 ff ff       	call   801018f4 <iget>
80102295:	83 c4 10             	add    $0x10,%esp
80102298:	eb 19                	jmp    801022b3 <dirlookup+0xb8>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlookup read");
    if(de.inum == 0)
      continue;
8010229a:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
8010229b:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010229f:	8b 45 08             	mov    0x8(%ebp),%eax
801022a2:	8b 40 58             	mov    0x58(%eax),%eax
801022a5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801022a8:	0f 87 76 ff ff ff    	ja     80102224 <dirlookup+0x29>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801022ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
801022b3:	c9                   	leave  
801022b4:	c3                   	ret    

801022b5 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801022b5:	55                   	push   %ebp
801022b6:	89 e5                	mov    %esp,%ebp
801022b8:	83 ec 28             	sub    $0x28,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801022bb:	83 ec 04             	sub    $0x4,%esp
801022be:	6a 00                	push   $0x0
801022c0:	ff 75 0c             	pushl  0xc(%ebp)
801022c3:	ff 75 08             	pushl  0x8(%ebp)
801022c6:	e8 30 ff ff ff       	call   801021fb <dirlookup>
801022cb:	83 c4 10             	add    $0x10,%esp
801022ce:	89 45 f0             	mov    %eax,-0x10(%ebp)
801022d1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801022d5:	74 18                	je     801022ef <dirlink+0x3a>
    iput(ip);
801022d7:	83 ec 0c             	sub    $0xc,%esp
801022da:	ff 75 f0             	pushl  -0x10(%ebp)
801022dd:	e8 8f f8 ff ff       	call   80101b71 <iput>
801022e2:	83 c4 10             	add    $0x10,%esp
    return -1;
801022e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801022ea:	e9 9c 00 00 00       	jmp    8010238b <dirlink+0xd6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801022ef:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801022f6:	eb 39                	jmp    80102331 <dirlink+0x7c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801022f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022fb:	6a 10                	push   $0x10
801022fd:	50                   	push   %eax
801022fe:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102301:	50                   	push   %eax
80102302:	ff 75 08             	pushl  0x8(%ebp)
80102305:	e8 f7 fb ff ff       	call   80101f01 <readi>
8010230a:	83 c4 10             	add    $0x10,%esp
8010230d:	83 f8 10             	cmp    $0x10,%eax
80102310:	74 0d                	je     8010231f <dirlink+0x6a>
      panic("dirlink read");
80102312:	83 ec 0c             	sub    $0xc,%esp
80102315:	68 d6 84 10 80       	push   $0x801084d6
8010231a:	e8 81 e2 ff ff       	call   801005a0 <panic>
    if(de.inum == 0)
8010231f:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102323:	66 85 c0             	test   %ax,%ax
80102326:	74 18                	je     80102340 <dirlink+0x8b>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102328:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010232b:	83 c0 10             	add    $0x10,%eax
8010232e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102331:	8b 45 08             	mov    0x8(%ebp),%eax
80102334:	8b 50 58             	mov    0x58(%eax),%edx
80102337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010233a:	39 c2                	cmp    %eax,%edx
8010233c:	77 ba                	ja     801022f8 <dirlink+0x43>
8010233e:	eb 01                	jmp    80102341 <dirlink+0x8c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80102340:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102341:	83 ec 04             	sub    $0x4,%esp
80102344:	6a 0e                	push   $0xe
80102346:	ff 75 0c             	pushl  0xc(%ebp)
80102349:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010234c:	83 c0 02             	add    $0x2,%eax
8010234f:	50                   	push   %eax
80102350:	e8 58 30 00 00       	call   801053ad <strncpy>
80102355:	83 c4 10             	add    $0x10,%esp
  de.inum = inum;
80102358:	8b 45 10             	mov    0x10(%ebp),%eax
8010235b:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010235f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102362:	6a 10                	push   $0x10
80102364:	50                   	push   %eax
80102365:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102368:	50                   	push   %eax
80102369:	ff 75 08             	pushl  0x8(%ebp)
8010236c:	e8 e7 fc ff ff       	call   80102058 <writei>
80102371:	83 c4 10             	add    $0x10,%esp
80102374:	83 f8 10             	cmp    $0x10,%eax
80102377:	74 0d                	je     80102386 <dirlink+0xd1>
    panic("dirlink");
80102379:	83 ec 0c             	sub    $0xc,%esp
8010237c:	68 e3 84 10 80       	push   $0x801084e3
80102381:	e8 1a e2 ff ff       	call   801005a0 <panic>

  return 0;
80102386:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010238b:	c9                   	leave  
8010238c:	c3                   	ret    

8010238d <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
8010238d:	55                   	push   %ebp
8010238e:	89 e5                	mov    %esp,%ebp
80102390:	83 ec 18             	sub    $0x18,%esp
  char *s;
  int len;

  while(*path == '/')
80102393:	eb 04                	jmp    80102399 <skipelem+0xc>
    path++;
80102395:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102399:	8b 45 08             	mov    0x8(%ebp),%eax
8010239c:	0f b6 00             	movzbl (%eax),%eax
8010239f:	3c 2f                	cmp    $0x2f,%al
801023a1:	74 f2                	je     80102395 <skipelem+0x8>
    path++;
  if(*path == 0)
801023a3:	8b 45 08             	mov    0x8(%ebp),%eax
801023a6:	0f b6 00             	movzbl (%eax),%eax
801023a9:	84 c0                	test   %al,%al
801023ab:	75 07                	jne    801023b4 <skipelem+0x27>
    return 0;
801023ad:	b8 00 00 00 00       	mov    $0x0,%eax
801023b2:	eb 7b                	jmp    8010242f <skipelem+0xa2>
  s = path;
801023b4:	8b 45 08             	mov    0x8(%ebp),%eax
801023b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801023ba:	eb 04                	jmp    801023c0 <skipelem+0x33>
    path++;
801023bc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
801023c0:	8b 45 08             	mov    0x8(%ebp),%eax
801023c3:	0f b6 00             	movzbl (%eax),%eax
801023c6:	3c 2f                	cmp    $0x2f,%al
801023c8:	74 0a                	je     801023d4 <skipelem+0x47>
801023ca:	8b 45 08             	mov    0x8(%ebp),%eax
801023cd:	0f b6 00             	movzbl (%eax),%eax
801023d0:	84 c0                	test   %al,%al
801023d2:	75 e8                	jne    801023bc <skipelem+0x2f>
    path++;
  len = path - s;
801023d4:	8b 55 08             	mov    0x8(%ebp),%edx
801023d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023da:	29 c2                	sub    %eax,%edx
801023dc:	89 d0                	mov    %edx,%eax
801023de:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801023e1:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801023e5:	7e 15                	jle    801023fc <skipelem+0x6f>
    memmove(name, s, DIRSIZ);
801023e7:	83 ec 04             	sub    $0x4,%esp
801023ea:	6a 0e                	push   $0xe
801023ec:	ff 75 f4             	pushl  -0xc(%ebp)
801023ef:	ff 75 0c             	pushl  0xc(%ebp)
801023f2:	e8 ca 2e 00 00       	call   801052c1 <memmove>
801023f7:	83 c4 10             	add    $0x10,%esp
801023fa:	eb 26                	jmp    80102422 <skipelem+0x95>
  else {
    memmove(name, s, len);
801023fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023ff:	83 ec 04             	sub    $0x4,%esp
80102402:	50                   	push   %eax
80102403:	ff 75 f4             	pushl  -0xc(%ebp)
80102406:	ff 75 0c             	pushl  0xc(%ebp)
80102409:	e8 b3 2e 00 00       	call   801052c1 <memmove>
8010240e:	83 c4 10             	add    $0x10,%esp
    name[len] = 0;
80102411:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102414:	8b 45 0c             	mov    0xc(%ebp),%eax
80102417:	01 d0                	add    %edx,%eax
80102419:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010241c:	eb 04                	jmp    80102422 <skipelem+0x95>
    path++;
8010241e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102422:	8b 45 08             	mov    0x8(%ebp),%eax
80102425:	0f b6 00             	movzbl (%eax),%eax
80102428:	3c 2f                	cmp    $0x2f,%al
8010242a:	74 f2                	je     8010241e <skipelem+0x91>
    path++;
  return path;
8010242c:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010242f:	c9                   	leave  
80102430:	c3                   	ret    

80102431 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102431:	55                   	push   %ebp
80102432:	89 e5                	mov    %esp,%ebp
80102434:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102437:	8b 45 08             	mov    0x8(%ebp),%eax
8010243a:	0f b6 00             	movzbl (%eax),%eax
8010243d:	3c 2f                	cmp    $0x2f,%al
8010243f:	75 17                	jne    80102458 <namex+0x27>
    ip = iget(ROOTDEV, ROOTINO);
80102441:	83 ec 08             	sub    $0x8,%esp
80102444:	6a 01                	push   $0x1
80102446:	6a 01                	push   $0x1
80102448:	e8 a7 f4 ff ff       	call   801018f4 <iget>
8010244d:	83 c4 10             	add    $0x10,%esp
80102450:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102453:	e9 ba 00 00 00       	jmp    80102512 <namex+0xe1>
  else
    ip = idup(myproc()->cwd);
80102458:	e8 2b 1e 00 00       	call   80104288 <myproc>
8010245d:	8b 40 68             	mov    0x68(%eax),%eax
80102460:	83 ec 0c             	sub    $0xc,%esp
80102463:	50                   	push   %eax
80102464:	e8 6d f5 ff ff       	call   801019d6 <idup>
80102469:	83 c4 10             	add    $0x10,%esp
8010246c:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010246f:	e9 9e 00 00 00       	jmp    80102512 <namex+0xe1>
    ilock(ip);
80102474:	83 ec 0c             	sub    $0xc,%esp
80102477:	ff 75 f4             	pushl  -0xc(%ebp)
8010247a:	e8 91 f5 ff ff       	call   80101a10 <ilock>
8010247f:	83 c4 10             	add    $0x10,%esp
    if(ip->type != T_DIR){
80102482:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102485:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80102489:	66 83 f8 01          	cmp    $0x1,%ax
8010248d:	74 18                	je     801024a7 <namex+0x76>
      iunlockput(ip);
8010248f:	83 ec 0c             	sub    $0xc,%esp
80102492:	ff 75 f4             	pushl  -0xc(%ebp)
80102495:	e8 a7 f7 ff ff       	call   80101c41 <iunlockput>
8010249a:	83 c4 10             	add    $0x10,%esp
      return 0;
8010249d:	b8 00 00 00 00       	mov    $0x0,%eax
801024a2:	e9 a7 00 00 00       	jmp    8010254e <namex+0x11d>
    }
    if(nameiparent && *path == '\0'){
801024a7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801024ab:	74 20                	je     801024cd <namex+0x9c>
801024ad:	8b 45 08             	mov    0x8(%ebp),%eax
801024b0:	0f b6 00             	movzbl (%eax),%eax
801024b3:	84 c0                	test   %al,%al
801024b5:	75 16                	jne    801024cd <namex+0x9c>
      // Stop one level early.
      iunlock(ip);
801024b7:	83 ec 0c             	sub    $0xc,%esp
801024ba:	ff 75 f4             	pushl  -0xc(%ebp)
801024bd:	e8 61 f6 ff ff       	call   80101b23 <iunlock>
801024c2:	83 c4 10             	add    $0x10,%esp
      return ip;
801024c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024c8:	e9 81 00 00 00       	jmp    8010254e <namex+0x11d>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801024cd:	83 ec 04             	sub    $0x4,%esp
801024d0:	6a 00                	push   $0x0
801024d2:	ff 75 10             	pushl  0x10(%ebp)
801024d5:	ff 75 f4             	pushl  -0xc(%ebp)
801024d8:	e8 1e fd ff ff       	call   801021fb <dirlookup>
801024dd:	83 c4 10             	add    $0x10,%esp
801024e0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801024e3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801024e7:	75 15                	jne    801024fe <namex+0xcd>
      iunlockput(ip);
801024e9:	83 ec 0c             	sub    $0xc,%esp
801024ec:	ff 75 f4             	pushl  -0xc(%ebp)
801024ef:	e8 4d f7 ff ff       	call   80101c41 <iunlockput>
801024f4:	83 c4 10             	add    $0x10,%esp
      return 0;
801024f7:	b8 00 00 00 00       	mov    $0x0,%eax
801024fc:	eb 50                	jmp    8010254e <namex+0x11d>
    }
    iunlockput(ip);
801024fe:	83 ec 0c             	sub    $0xc,%esp
80102501:	ff 75 f4             	pushl  -0xc(%ebp)
80102504:	e8 38 f7 ff ff       	call   80101c41 <iunlockput>
80102509:	83 c4 10             	add    $0x10,%esp
    ip = next;
8010250c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010250f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);

  while((path = skipelem(path, name)) != 0){
80102512:	83 ec 08             	sub    $0x8,%esp
80102515:	ff 75 10             	pushl  0x10(%ebp)
80102518:	ff 75 08             	pushl  0x8(%ebp)
8010251b:	e8 6d fe ff ff       	call   8010238d <skipelem>
80102520:	83 c4 10             	add    $0x10,%esp
80102523:	89 45 08             	mov    %eax,0x8(%ebp)
80102526:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010252a:	0f 85 44 ff ff ff    	jne    80102474 <namex+0x43>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102530:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102534:	74 15                	je     8010254b <namex+0x11a>
    iput(ip);
80102536:	83 ec 0c             	sub    $0xc,%esp
80102539:	ff 75 f4             	pushl  -0xc(%ebp)
8010253c:	e8 30 f6 ff ff       	call   80101b71 <iput>
80102541:	83 c4 10             	add    $0x10,%esp
    return 0;
80102544:	b8 00 00 00 00       	mov    $0x0,%eax
80102549:	eb 03                	jmp    8010254e <namex+0x11d>
  }
  return ip;
8010254b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010254e:	c9                   	leave  
8010254f:	c3                   	ret    

80102550 <namei>:

struct inode*
namei(char *path)
{
80102550:	55                   	push   %ebp
80102551:	89 e5                	mov    %esp,%ebp
80102553:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102556:	83 ec 04             	sub    $0x4,%esp
80102559:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010255c:	50                   	push   %eax
8010255d:	6a 00                	push   $0x0
8010255f:	ff 75 08             	pushl  0x8(%ebp)
80102562:	e8 ca fe ff ff       	call   80102431 <namex>
80102567:	83 c4 10             	add    $0x10,%esp
}
8010256a:	c9                   	leave  
8010256b:	c3                   	ret    

8010256c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
8010256c:	55                   	push   %ebp
8010256d:	89 e5                	mov    %esp,%ebp
8010256f:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80102572:	83 ec 04             	sub    $0x4,%esp
80102575:	ff 75 0c             	pushl  0xc(%ebp)
80102578:	6a 01                	push   $0x1
8010257a:	ff 75 08             	pushl  0x8(%ebp)
8010257d:	e8 af fe ff ff       	call   80102431 <namex>
80102582:	83 c4 10             	add    $0x10,%esp
}
80102585:	c9                   	leave  
80102586:	c3                   	ret    

80102587 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102587:	55                   	push   %ebp
80102588:	89 e5                	mov    %esp,%ebp
8010258a:	83 ec 14             	sub    $0x14,%esp
8010258d:	8b 45 08             	mov    0x8(%ebp),%eax
80102590:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102594:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102598:	89 c2                	mov    %eax,%edx
8010259a:	ec                   	in     (%dx),%al
8010259b:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010259e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801025a2:	c9                   	leave  
801025a3:	c3                   	ret    

801025a4 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
801025a4:	55                   	push   %ebp
801025a5:	89 e5                	mov    %esp,%ebp
801025a7:	57                   	push   %edi
801025a8:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801025a9:	8b 55 08             	mov    0x8(%ebp),%edx
801025ac:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801025af:	8b 45 10             	mov    0x10(%ebp),%eax
801025b2:	89 cb                	mov    %ecx,%ebx
801025b4:	89 df                	mov    %ebx,%edi
801025b6:	89 c1                	mov    %eax,%ecx
801025b8:	fc                   	cld    
801025b9:	f3 6d                	rep insl (%dx),%es:(%edi)
801025bb:	89 c8                	mov    %ecx,%eax
801025bd:	89 fb                	mov    %edi,%ebx
801025bf:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801025c2:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801025c5:	90                   	nop
801025c6:	5b                   	pop    %ebx
801025c7:	5f                   	pop    %edi
801025c8:	5d                   	pop    %ebp
801025c9:	c3                   	ret    

801025ca <outb>:

static inline void
outb(ushort port, uchar data)
{
801025ca:	55                   	push   %ebp
801025cb:	89 e5                	mov    %esp,%ebp
801025cd:	83 ec 08             	sub    $0x8,%esp
801025d0:	8b 55 08             	mov    0x8(%ebp),%edx
801025d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801025d6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801025da:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801025dd:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801025e1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801025e5:	ee                   	out    %al,(%dx)
}
801025e6:	90                   	nop
801025e7:	c9                   	leave  
801025e8:	c3                   	ret    

801025e9 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801025e9:	55                   	push   %ebp
801025ea:	89 e5                	mov    %esp,%ebp
801025ec:	56                   	push   %esi
801025ed:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801025ee:	8b 55 08             	mov    0x8(%ebp),%edx
801025f1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801025f4:	8b 45 10             	mov    0x10(%ebp),%eax
801025f7:	89 cb                	mov    %ecx,%ebx
801025f9:	89 de                	mov    %ebx,%esi
801025fb:	89 c1                	mov    %eax,%ecx
801025fd:	fc                   	cld    
801025fe:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102600:	89 c8                	mov    %ecx,%eax
80102602:	89 f3                	mov    %esi,%ebx
80102604:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102607:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
8010260a:	90                   	nop
8010260b:	5b                   	pop    %ebx
8010260c:	5e                   	pop    %esi
8010260d:	5d                   	pop    %ebp
8010260e:	c3                   	ret    

8010260f <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
8010260f:	55                   	push   %ebp
80102610:	89 e5                	mov    %esp,%ebp
80102612:	83 ec 10             	sub    $0x10,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80102615:	90                   	nop
80102616:	68 f7 01 00 00       	push   $0x1f7
8010261b:	e8 67 ff ff ff       	call   80102587 <inb>
80102620:	83 c4 04             	add    $0x4,%esp
80102623:	0f b6 c0             	movzbl %al,%eax
80102626:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102629:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010262c:	25 c0 00 00 00       	and    $0xc0,%eax
80102631:	83 f8 40             	cmp    $0x40,%eax
80102634:	75 e0                	jne    80102616 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102636:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010263a:	74 11                	je     8010264d <idewait+0x3e>
8010263c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010263f:	83 e0 21             	and    $0x21,%eax
80102642:	85 c0                	test   %eax,%eax
80102644:	74 07                	je     8010264d <idewait+0x3e>
    return -1;
80102646:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010264b:	eb 05                	jmp    80102652 <idewait+0x43>
  return 0;
8010264d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102652:	c9                   	leave  
80102653:	c3                   	ret    

80102654 <ideinit>:

void
ideinit(void)
{
80102654:	55                   	push   %ebp
80102655:	89 e5                	mov    %esp,%ebp
80102657:	83 ec 18             	sub    $0x18,%esp
  int i;

  initlock(&idelock, "ide");
8010265a:	83 ec 08             	sub    $0x8,%esp
8010265d:	68 eb 84 10 80       	push   $0x801084eb
80102662:	68 e0 b5 10 80       	push   $0x8010b5e0
80102667:	e8 fd 28 00 00       	call   80104f69 <initlock>
8010266c:	83 c4 10             	add    $0x10,%esp
  ioapicenable(IRQ_IDE, ncpu - 1);
8010266f:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80102674:	83 e8 01             	sub    $0x1,%eax
80102677:	83 ec 08             	sub    $0x8,%esp
8010267a:	50                   	push   %eax
8010267b:	6a 0e                	push   $0xe
8010267d:	e8 a2 04 00 00       	call   80102b24 <ioapicenable>
80102682:	83 c4 10             	add    $0x10,%esp
  idewait(0);
80102685:	83 ec 0c             	sub    $0xc,%esp
80102688:	6a 00                	push   $0x0
8010268a:	e8 80 ff ff ff       	call   8010260f <idewait>
8010268f:	83 c4 10             	add    $0x10,%esp

  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102692:	83 ec 08             	sub    $0x8,%esp
80102695:	68 f0 00 00 00       	push   $0xf0
8010269a:	68 f6 01 00 00       	push   $0x1f6
8010269f:	e8 26 ff ff ff       	call   801025ca <outb>
801026a4:	83 c4 10             	add    $0x10,%esp
  for(i=0; i<1000; i++){
801026a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801026ae:	eb 24                	jmp    801026d4 <ideinit+0x80>
    if(inb(0x1f7) != 0){
801026b0:	83 ec 0c             	sub    $0xc,%esp
801026b3:	68 f7 01 00 00       	push   $0x1f7
801026b8:	e8 ca fe ff ff       	call   80102587 <inb>
801026bd:	83 c4 10             	add    $0x10,%esp
801026c0:	84 c0                	test   %al,%al
801026c2:	74 0c                	je     801026d0 <ideinit+0x7c>
      havedisk1 = 1;
801026c4:	c7 05 18 b6 10 80 01 	movl   $0x1,0x8010b618
801026cb:	00 00 00 
      break;
801026ce:	eb 0d                	jmp    801026dd <ideinit+0x89>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);

  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801026d0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801026d4:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801026db:	7e d3                	jle    801026b0 <ideinit+0x5c>
      break;
    }
  }

  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801026dd:	83 ec 08             	sub    $0x8,%esp
801026e0:	68 e0 00 00 00       	push   $0xe0
801026e5:	68 f6 01 00 00       	push   $0x1f6
801026ea:	e8 db fe ff ff       	call   801025ca <outb>
801026ef:	83 c4 10             	add    $0x10,%esp
}
801026f2:	90                   	nop
801026f3:	c9                   	leave  
801026f4:	c3                   	ret    

801026f5 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801026f5:	55                   	push   %ebp
801026f6:	89 e5                	mov    %esp,%ebp
801026f8:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801026fb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801026ff:	75 0d                	jne    8010270e <idestart+0x19>
    panic("idestart");
80102701:	83 ec 0c             	sub    $0xc,%esp
80102704:	68 ef 84 10 80       	push   $0x801084ef
80102709:	e8 92 de ff ff       	call   801005a0 <panic>
  if(b->blockno >= FSSIZE)
8010270e:	8b 45 08             	mov    0x8(%ebp),%eax
80102711:	8b 40 08             	mov    0x8(%eax),%eax
80102714:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102719:	76 0d                	jbe    80102728 <idestart+0x33>
    panic("incorrect blockno");
8010271b:	83 ec 0c             	sub    $0xc,%esp
8010271e:	68 f8 84 10 80       	push   $0x801084f8
80102723:	e8 78 de ff ff       	call   801005a0 <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
80102728:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
8010272f:	8b 45 08             	mov    0x8(%ebp),%eax
80102732:	8b 50 08             	mov    0x8(%eax),%edx
80102735:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102738:	0f af c2             	imul   %edx,%eax
8010273b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
8010273e:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80102742:	75 07                	jne    8010274b <idestart+0x56>
80102744:	b8 20 00 00 00       	mov    $0x20,%eax
80102749:	eb 05                	jmp    80102750 <idestart+0x5b>
8010274b:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102750:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;
80102753:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80102757:	75 07                	jne    80102760 <idestart+0x6b>
80102759:	b8 30 00 00 00       	mov    $0x30,%eax
8010275e:	eb 05                	jmp    80102765 <idestart+0x70>
80102760:	b8 c5 00 00 00       	mov    $0xc5,%eax
80102765:	89 45 e8             	mov    %eax,-0x18(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102768:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
8010276c:	7e 0d                	jle    8010277b <idestart+0x86>
8010276e:	83 ec 0c             	sub    $0xc,%esp
80102771:	68 ef 84 10 80       	push   $0x801084ef
80102776:	e8 25 de ff ff       	call   801005a0 <panic>

  idewait(0);
8010277b:	83 ec 0c             	sub    $0xc,%esp
8010277e:	6a 00                	push   $0x0
80102780:	e8 8a fe ff ff       	call   8010260f <idewait>
80102785:	83 c4 10             	add    $0x10,%esp
  outb(0x3f6, 0);  // generate interrupt
80102788:	83 ec 08             	sub    $0x8,%esp
8010278b:	6a 00                	push   $0x0
8010278d:	68 f6 03 00 00       	push   $0x3f6
80102792:	e8 33 fe ff ff       	call   801025ca <outb>
80102797:	83 c4 10             	add    $0x10,%esp
  outb(0x1f2, sector_per_block);  // number of sectors
8010279a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010279d:	0f b6 c0             	movzbl %al,%eax
801027a0:	83 ec 08             	sub    $0x8,%esp
801027a3:	50                   	push   %eax
801027a4:	68 f2 01 00 00       	push   $0x1f2
801027a9:	e8 1c fe ff ff       	call   801025ca <outb>
801027ae:	83 c4 10             	add    $0x10,%esp
  outb(0x1f3, sector & 0xff);
801027b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027b4:	0f b6 c0             	movzbl %al,%eax
801027b7:	83 ec 08             	sub    $0x8,%esp
801027ba:	50                   	push   %eax
801027bb:	68 f3 01 00 00       	push   $0x1f3
801027c0:	e8 05 fe ff ff       	call   801025ca <outb>
801027c5:	83 c4 10             	add    $0x10,%esp
  outb(0x1f4, (sector >> 8) & 0xff);
801027c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027cb:	c1 f8 08             	sar    $0x8,%eax
801027ce:	0f b6 c0             	movzbl %al,%eax
801027d1:	83 ec 08             	sub    $0x8,%esp
801027d4:	50                   	push   %eax
801027d5:	68 f4 01 00 00       	push   $0x1f4
801027da:	e8 eb fd ff ff       	call   801025ca <outb>
801027df:	83 c4 10             	add    $0x10,%esp
  outb(0x1f5, (sector >> 16) & 0xff);
801027e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027e5:	c1 f8 10             	sar    $0x10,%eax
801027e8:	0f b6 c0             	movzbl %al,%eax
801027eb:	83 ec 08             	sub    $0x8,%esp
801027ee:	50                   	push   %eax
801027ef:	68 f5 01 00 00       	push   $0x1f5
801027f4:	e8 d1 fd ff ff       	call   801025ca <outb>
801027f9:	83 c4 10             	add    $0x10,%esp
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
801027fc:	8b 45 08             	mov    0x8(%ebp),%eax
801027ff:	8b 40 04             	mov    0x4(%eax),%eax
80102802:	83 e0 01             	and    $0x1,%eax
80102805:	c1 e0 04             	shl    $0x4,%eax
80102808:	89 c2                	mov    %eax,%edx
8010280a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010280d:	c1 f8 18             	sar    $0x18,%eax
80102810:	83 e0 0f             	and    $0xf,%eax
80102813:	09 d0                	or     %edx,%eax
80102815:	83 c8 e0             	or     $0xffffffe0,%eax
80102818:	0f b6 c0             	movzbl %al,%eax
8010281b:	83 ec 08             	sub    $0x8,%esp
8010281e:	50                   	push   %eax
8010281f:	68 f6 01 00 00       	push   $0x1f6
80102824:	e8 a1 fd ff ff       	call   801025ca <outb>
80102829:	83 c4 10             	add    $0x10,%esp
  if(b->flags & B_DIRTY){
8010282c:	8b 45 08             	mov    0x8(%ebp),%eax
8010282f:	8b 00                	mov    (%eax),%eax
80102831:	83 e0 04             	and    $0x4,%eax
80102834:	85 c0                	test   %eax,%eax
80102836:	74 35                	je     8010286d <idestart+0x178>
    outb(0x1f7, write_cmd);
80102838:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010283b:	0f b6 c0             	movzbl %al,%eax
8010283e:	83 ec 08             	sub    $0x8,%esp
80102841:	50                   	push   %eax
80102842:	68 f7 01 00 00       	push   $0x1f7
80102847:	e8 7e fd ff ff       	call   801025ca <outb>
8010284c:	83 c4 10             	add    $0x10,%esp
    outsl(0x1f0, b->data, BSIZE/4);
8010284f:	8b 45 08             	mov    0x8(%ebp),%eax
80102852:	83 c0 5c             	add    $0x5c,%eax
80102855:	83 ec 04             	sub    $0x4,%esp
80102858:	68 80 00 00 00       	push   $0x80
8010285d:	50                   	push   %eax
8010285e:	68 f0 01 00 00       	push   $0x1f0
80102863:	e8 81 fd ff ff       	call   801025e9 <outsl>
80102868:	83 c4 10             	add    $0x10,%esp
  } else {
    outb(0x1f7, read_cmd);
  }
}
8010286b:	eb 17                	jmp    80102884 <idestart+0x18f>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
  if(b->flags & B_DIRTY){
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
  } else {
    outb(0x1f7, read_cmd);
8010286d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102870:	0f b6 c0             	movzbl %al,%eax
80102873:	83 ec 08             	sub    $0x8,%esp
80102876:	50                   	push   %eax
80102877:	68 f7 01 00 00       	push   $0x1f7
8010287c:	e8 49 fd ff ff       	call   801025ca <outb>
80102881:	83 c4 10             	add    $0x10,%esp
  }
}
80102884:	90                   	nop
80102885:	c9                   	leave  
80102886:	c3                   	ret    

80102887 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102887:	55                   	push   %ebp
80102888:	89 e5                	mov    %esp,%ebp
8010288a:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
8010288d:	83 ec 0c             	sub    $0xc,%esp
80102890:	68 e0 b5 10 80       	push   $0x8010b5e0
80102895:	e8 f1 26 00 00       	call   80104f8b <acquire>
8010289a:	83 c4 10             	add    $0x10,%esp

  if((b = idequeue) == 0){
8010289d:	a1 14 b6 10 80       	mov    0x8010b614,%eax
801028a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801028a5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801028a9:	75 15                	jne    801028c0 <ideintr+0x39>
    release(&idelock);
801028ab:	83 ec 0c             	sub    $0xc,%esp
801028ae:	68 e0 b5 10 80       	push   $0x8010b5e0
801028b3:	e8 41 27 00 00       	call   80104ff9 <release>
801028b8:	83 c4 10             	add    $0x10,%esp
    return;
801028bb:	e9 9a 00 00 00       	jmp    8010295a <ideintr+0xd3>
  }
  idequeue = b->qnext;
801028c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028c3:	8b 40 58             	mov    0x58(%eax),%eax
801028c6:	a3 14 b6 10 80       	mov    %eax,0x8010b614

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801028cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028ce:	8b 00                	mov    (%eax),%eax
801028d0:	83 e0 04             	and    $0x4,%eax
801028d3:	85 c0                	test   %eax,%eax
801028d5:	75 2d                	jne    80102904 <ideintr+0x7d>
801028d7:	83 ec 0c             	sub    $0xc,%esp
801028da:	6a 01                	push   $0x1
801028dc:	e8 2e fd ff ff       	call   8010260f <idewait>
801028e1:	83 c4 10             	add    $0x10,%esp
801028e4:	85 c0                	test   %eax,%eax
801028e6:	78 1c                	js     80102904 <ideintr+0x7d>
    insl(0x1f0, b->data, BSIZE/4);
801028e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028eb:	83 c0 5c             	add    $0x5c,%eax
801028ee:	83 ec 04             	sub    $0x4,%esp
801028f1:	68 80 00 00 00       	push   $0x80
801028f6:	50                   	push   %eax
801028f7:	68 f0 01 00 00       	push   $0x1f0
801028fc:	e8 a3 fc ff ff       	call   801025a4 <insl>
80102901:	83 c4 10             	add    $0x10,%esp

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102904:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102907:	8b 00                	mov    (%eax),%eax
80102909:	83 c8 02             	or     $0x2,%eax
8010290c:	89 c2                	mov    %eax,%edx
8010290e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102911:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102913:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102916:	8b 00                	mov    (%eax),%eax
80102918:	83 e0 fb             	and    $0xfffffffb,%eax
8010291b:	89 c2                	mov    %eax,%edx
8010291d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102920:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102922:	83 ec 0c             	sub    $0xc,%esp
80102925:	ff 75 f4             	pushl  -0xc(%ebp)
80102928:	e8 2b 23 00 00       	call   80104c58 <wakeup>
8010292d:	83 c4 10             	add    $0x10,%esp

  // Start disk on next buf in queue.
  if(idequeue != 0)
80102930:	a1 14 b6 10 80       	mov    0x8010b614,%eax
80102935:	85 c0                	test   %eax,%eax
80102937:	74 11                	je     8010294a <ideintr+0xc3>
    idestart(idequeue);
80102939:	a1 14 b6 10 80       	mov    0x8010b614,%eax
8010293e:	83 ec 0c             	sub    $0xc,%esp
80102941:	50                   	push   %eax
80102942:	e8 ae fd ff ff       	call   801026f5 <idestart>
80102947:	83 c4 10             	add    $0x10,%esp

  release(&idelock);
8010294a:	83 ec 0c             	sub    $0xc,%esp
8010294d:	68 e0 b5 10 80       	push   $0x8010b5e0
80102952:	e8 a2 26 00 00       	call   80104ff9 <release>
80102957:	83 c4 10             	add    $0x10,%esp
}
8010295a:	c9                   	leave  
8010295b:	c3                   	ret    

8010295c <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
8010295c:	55                   	push   %ebp
8010295d:	89 e5                	mov    %esp,%ebp
8010295f:	83 ec 18             	sub    $0x18,%esp
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80102962:	8b 45 08             	mov    0x8(%ebp),%eax
80102965:	83 c0 0c             	add    $0xc,%eax
80102968:	83 ec 0c             	sub    $0xc,%esp
8010296b:	50                   	push   %eax
8010296c:	e8 89 25 00 00       	call   80104efa <holdingsleep>
80102971:	83 c4 10             	add    $0x10,%esp
80102974:	85 c0                	test   %eax,%eax
80102976:	75 0d                	jne    80102985 <iderw+0x29>
    panic("iderw: buf not locked");
80102978:	83 ec 0c             	sub    $0xc,%esp
8010297b:	68 0a 85 10 80       	push   $0x8010850a
80102980:	e8 1b dc ff ff       	call   801005a0 <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102985:	8b 45 08             	mov    0x8(%ebp),%eax
80102988:	8b 00                	mov    (%eax),%eax
8010298a:	83 e0 06             	and    $0x6,%eax
8010298d:	83 f8 02             	cmp    $0x2,%eax
80102990:	75 0d                	jne    8010299f <iderw+0x43>
    panic("iderw: nothing to do");
80102992:	83 ec 0c             	sub    $0xc,%esp
80102995:	68 20 85 10 80       	push   $0x80108520
8010299a:	e8 01 dc ff ff       	call   801005a0 <panic>
  if(b->dev != 0 && !havedisk1)
8010299f:	8b 45 08             	mov    0x8(%ebp),%eax
801029a2:	8b 40 04             	mov    0x4(%eax),%eax
801029a5:	85 c0                	test   %eax,%eax
801029a7:	74 16                	je     801029bf <iderw+0x63>
801029a9:	a1 18 b6 10 80       	mov    0x8010b618,%eax
801029ae:	85 c0                	test   %eax,%eax
801029b0:	75 0d                	jne    801029bf <iderw+0x63>
    panic("iderw: ide disk 1 not present");
801029b2:	83 ec 0c             	sub    $0xc,%esp
801029b5:	68 35 85 10 80       	push   $0x80108535
801029ba:	e8 e1 db ff ff       	call   801005a0 <panic>

  acquire(&idelock);  //DOC:acquire-lock
801029bf:	83 ec 0c             	sub    $0xc,%esp
801029c2:	68 e0 b5 10 80       	push   $0x8010b5e0
801029c7:	e8 bf 25 00 00       	call   80104f8b <acquire>
801029cc:	83 c4 10             	add    $0x10,%esp

  // Append b to idequeue.
  b->qnext = 0;
801029cf:	8b 45 08             	mov    0x8(%ebp),%eax
801029d2:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
801029d9:	c7 45 f4 14 b6 10 80 	movl   $0x8010b614,-0xc(%ebp)
801029e0:	eb 0b                	jmp    801029ed <iderw+0x91>
801029e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029e5:	8b 00                	mov    (%eax),%eax
801029e7:	83 c0 58             	add    $0x58,%eax
801029ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029f0:	8b 00                	mov    (%eax),%eax
801029f2:	85 c0                	test   %eax,%eax
801029f4:	75 ec                	jne    801029e2 <iderw+0x86>
    ;
  *pp = b;
801029f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029f9:	8b 55 08             	mov    0x8(%ebp),%edx
801029fc:	89 10                	mov    %edx,(%eax)

  // Start disk if necessary.
  if(idequeue == b)
801029fe:	a1 14 b6 10 80       	mov    0x8010b614,%eax
80102a03:	3b 45 08             	cmp    0x8(%ebp),%eax
80102a06:	75 23                	jne    80102a2b <iderw+0xcf>
    idestart(b);
80102a08:	83 ec 0c             	sub    $0xc,%esp
80102a0b:	ff 75 08             	pushl  0x8(%ebp)
80102a0e:	e8 e2 fc ff ff       	call   801026f5 <idestart>
80102a13:	83 c4 10             	add    $0x10,%esp

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a16:	eb 13                	jmp    80102a2b <iderw+0xcf>
    sleep(b, &idelock);
80102a18:	83 ec 08             	sub    $0x8,%esp
80102a1b:	68 e0 b5 10 80       	push   $0x8010b5e0
80102a20:	ff 75 08             	pushl  0x8(%ebp)
80102a23:	e8 4a 21 00 00       	call   80104b72 <sleep>
80102a28:	83 c4 10             	add    $0x10,%esp
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a2b:	8b 45 08             	mov    0x8(%ebp),%eax
80102a2e:	8b 00                	mov    (%eax),%eax
80102a30:	83 e0 06             	and    $0x6,%eax
80102a33:	83 f8 02             	cmp    $0x2,%eax
80102a36:	75 e0                	jne    80102a18 <iderw+0xbc>
    sleep(b, &idelock);
  }


  release(&idelock);
80102a38:	83 ec 0c             	sub    $0xc,%esp
80102a3b:	68 e0 b5 10 80       	push   $0x8010b5e0
80102a40:	e8 b4 25 00 00       	call   80104ff9 <release>
80102a45:	83 c4 10             	add    $0x10,%esp
}
80102a48:	90                   	nop
80102a49:	c9                   	leave  
80102a4a:	c3                   	ret    

80102a4b <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102a4b:	55                   	push   %ebp
80102a4c:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a4e:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a53:	8b 55 08             	mov    0x8(%ebp),%edx
80102a56:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102a58:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a5d:	8b 40 10             	mov    0x10(%eax),%eax
}
80102a60:	5d                   	pop    %ebp
80102a61:	c3                   	ret    

80102a62 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102a62:	55                   	push   %ebp
80102a63:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a65:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a6a:	8b 55 08             	mov    0x8(%ebp),%edx
80102a6d:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102a6f:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a74:	8b 55 0c             	mov    0xc(%ebp),%edx
80102a77:	89 50 10             	mov    %edx,0x10(%eax)
}
80102a7a:	90                   	nop
80102a7b:	5d                   	pop    %ebp
80102a7c:	c3                   	ret    

80102a7d <ioapicinit>:

void
ioapicinit(void)
{
80102a7d:	55                   	push   %ebp
80102a7e:	89 e5                	mov    %esp,%ebp
80102a80:	83 ec 18             	sub    $0x18,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80102a83:	c7 05 b4 36 11 80 00 	movl   $0xfec00000,0x801136b4
80102a8a:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102a8d:	6a 01                	push   $0x1
80102a8f:	e8 b7 ff ff ff       	call   80102a4b <ioapicread>
80102a94:	83 c4 04             	add    $0x4,%esp
80102a97:	c1 e8 10             	shr    $0x10,%eax
80102a9a:	25 ff 00 00 00       	and    $0xff,%eax
80102a9f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102aa2:	6a 00                	push   $0x0
80102aa4:	e8 a2 ff ff ff       	call   80102a4b <ioapicread>
80102aa9:	83 c4 04             	add    $0x4,%esp
80102aac:	c1 e8 18             	shr    $0x18,%eax
80102aaf:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102ab2:	0f b6 05 e0 37 11 80 	movzbl 0x801137e0,%eax
80102ab9:	0f b6 c0             	movzbl %al,%eax
80102abc:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102abf:	74 10                	je     80102ad1 <ioapicinit+0x54>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102ac1:	83 ec 0c             	sub    $0xc,%esp
80102ac4:	68 54 85 10 80       	push   $0x80108554
80102ac9:	e8 32 d9 ff ff       	call   80100400 <cprintf>
80102ace:	83 c4 10             	add    $0x10,%esp

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102ad1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102ad8:	eb 3f                	jmp    80102b19 <ioapicinit+0x9c>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102ada:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102add:	83 c0 20             	add    $0x20,%eax
80102ae0:	0d 00 00 01 00       	or     $0x10000,%eax
80102ae5:	89 c2                	mov    %eax,%edx
80102ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aea:	83 c0 08             	add    $0x8,%eax
80102aed:	01 c0                	add    %eax,%eax
80102aef:	83 ec 08             	sub    $0x8,%esp
80102af2:	52                   	push   %edx
80102af3:	50                   	push   %eax
80102af4:	e8 69 ff ff ff       	call   80102a62 <ioapicwrite>
80102af9:	83 c4 10             	add    $0x10,%esp
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102afc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aff:	83 c0 08             	add    $0x8,%eax
80102b02:	01 c0                	add    %eax,%eax
80102b04:	83 c0 01             	add    $0x1,%eax
80102b07:	83 ec 08             	sub    $0x8,%esp
80102b0a:	6a 00                	push   $0x0
80102b0c:	50                   	push   %eax
80102b0d:	e8 50 ff ff ff       	call   80102a62 <ioapicwrite>
80102b12:	83 c4 10             	add    $0x10,%esp
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102b15:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b1c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102b1f:	7e b9                	jle    80102ada <ioapicinit+0x5d>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102b21:	90                   	nop
80102b22:	c9                   	leave  
80102b23:	c3                   	ret    

80102b24 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102b24:	55                   	push   %ebp
80102b25:	89 e5                	mov    %esp,%ebp
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102b27:	8b 45 08             	mov    0x8(%ebp),%eax
80102b2a:	83 c0 20             	add    $0x20,%eax
80102b2d:	89 c2                	mov    %eax,%edx
80102b2f:	8b 45 08             	mov    0x8(%ebp),%eax
80102b32:	83 c0 08             	add    $0x8,%eax
80102b35:	01 c0                	add    %eax,%eax
80102b37:	52                   	push   %edx
80102b38:	50                   	push   %eax
80102b39:	e8 24 ff ff ff       	call   80102a62 <ioapicwrite>
80102b3e:	83 c4 08             	add    $0x8,%esp
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102b41:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b44:	c1 e0 18             	shl    $0x18,%eax
80102b47:	89 c2                	mov    %eax,%edx
80102b49:	8b 45 08             	mov    0x8(%ebp),%eax
80102b4c:	83 c0 08             	add    $0x8,%eax
80102b4f:	01 c0                	add    %eax,%eax
80102b51:	83 c0 01             	add    $0x1,%eax
80102b54:	52                   	push   %edx
80102b55:	50                   	push   %eax
80102b56:	e8 07 ff ff ff       	call   80102a62 <ioapicwrite>
80102b5b:	83 c4 08             	add    $0x8,%esp
}
80102b5e:	90                   	nop
80102b5f:	c9                   	leave  
80102b60:	c3                   	ret    

80102b61 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102b61:	55                   	push   %ebp
80102b62:	89 e5                	mov    %esp,%ebp
80102b64:	83 ec 08             	sub    $0x8,%esp
  initlock(&kmem.lock, "kmem");
80102b67:	83 ec 08             	sub    $0x8,%esp
80102b6a:	68 86 85 10 80       	push   $0x80108586
80102b6f:	68 c0 36 11 80       	push   $0x801136c0
80102b74:	e8 f0 23 00 00       	call   80104f69 <initlock>
80102b79:	83 c4 10             	add    $0x10,%esp
  kmem.use_lock = 0;
80102b7c:	c7 05 f4 36 11 80 00 	movl   $0x0,0x801136f4
80102b83:	00 00 00 
  freerange(vstart, vend);
80102b86:	83 ec 08             	sub    $0x8,%esp
80102b89:	ff 75 0c             	pushl  0xc(%ebp)
80102b8c:	ff 75 08             	pushl  0x8(%ebp)
80102b8f:	e8 2a 00 00 00       	call   80102bbe <freerange>
80102b94:	83 c4 10             	add    $0x10,%esp
}
80102b97:	90                   	nop
80102b98:	c9                   	leave  
80102b99:	c3                   	ret    

80102b9a <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102b9a:	55                   	push   %ebp
80102b9b:	89 e5                	mov    %esp,%ebp
80102b9d:	83 ec 08             	sub    $0x8,%esp
  freerange(vstart, vend);
80102ba0:	83 ec 08             	sub    $0x8,%esp
80102ba3:	ff 75 0c             	pushl  0xc(%ebp)
80102ba6:	ff 75 08             	pushl  0x8(%ebp)
80102ba9:	e8 10 00 00 00       	call   80102bbe <freerange>
80102bae:	83 c4 10             	add    $0x10,%esp
  kmem.use_lock = 1;
80102bb1:	c7 05 f4 36 11 80 01 	movl   $0x1,0x801136f4
80102bb8:	00 00 00 
}
80102bbb:	90                   	nop
80102bbc:	c9                   	leave  
80102bbd:	c3                   	ret    

80102bbe <freerange>:

void
freerange(void *vstart, void *vend)
{
80102bbe:	55                   	push   %ebp
80102bbf:	89 e5                	mov    %esp,%ebp
80102bc1:	83 ec 18             	sub    $0x18,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102bc4:	8b 45 08             	mov    0x8(%ebp),%eax
80102bc7:	05 ff 0f 00 00       	add    $0xfff,%eax
80102bcc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102bd1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102bd4:	eb 15                	jmp    80102beb <freerange+0x2d>
    kfree(p);
80102bd6:	83 ec 0c             	sub    $0xc,%esp
80102bd9:	ff 75 f4             	pushl  -0xc(%ebp)
80102bdc:	e8 1a 00 00 00       	call   80102bfb <kfree>
80102be1:	83 c4 10             	add    $0x10,%esp
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102be4:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102beb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bee:	05 00 10 00 00       	add    $0x1000,%eax
80102bf3:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102bf6:	76 de                	jbe    80102bd6 <freerange+0x18>
    kfree(p);
}
80102bf8:	90                   	nop
80102bf9:	c9                   	leave  
80102bfa:	c3                   	ret    

80102bfb <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102bfb:	55                   	push   %ebp
80102bfc:	89 e5                	mov    %esp,%ebp
80102bfe:	83 ec 18             	sub    $0x18,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80102c01:	8b 45 08             	mov    0x8(%ebp),%eax
80102c04:	25 ff 0f 00 00       	and    $0xfff,%eax
80102c09:	85 c0                	test   %eax,%eax
80102c0b:	75 18                	jne    80102c25 <kfree+0x2a>
80102c0d:	81 7d 08 28 65 11 80 	cmpl   $0x80116528,0x8(%ebp)
80102c14:	72 0f                	jb     80102c25 <kfree+0x2a>
80102c16:	8b 45 08             	mov    0x8(%ebp),%eax
80102c19:	05 00 00 00 80       	add    $0x80000000,%eax
80102c1e:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102c23:	76 0d                	jbe    80102c32 <kfree+0x37>
    panic("kfree");
80102c25:	83 ec 0c             	sub    $0xc,%esp
80102c28:	68 8b 85 10 80       	push   $0x8010858b
80102c2d:	e8 6e d9 ff ff       	call   801005a0 <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102c32:	83 ec 04             	sub    $0x4,%esp
80102c35:	68 00 10 00 00       	push   $0x1000
80102c3a:	6a 01                	push   $0x1
80102c3c:	ff 75 08             	pushl  0x8(%ebp)
80102c3f:	e8 be 25 00 00       	call   80105202 <memset>
80102c44:	83 c4 10             	add    $0x10,%esp

  if(kmem.use_lock)
80102c47:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102c4c:	85 c0                	test   %eax,%eax
80102c4e:	74 10                	je     80102c60 <kfree+0x65>
    acquire(&kmem.lock);
80102c50:	83 ec 0c             	sub    $0xc,%esp
80102c53:	68 c0 36 11 80       	push   $0x801136c0
80102c58:	e8 2e 23 00 00       	call   80104f8b <acquire>
80102c5d:	83 c4 10             	add    $0x10,%esp
  r = (struct run*)v;
80102c60:	8b 45 08             	mov    0x8(%ebp),%eax
80102c63:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102c66:	8b 15 f8 36 11 80    	mov    0x801136f8,%edx
80102c6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c6f:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102c71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c74:	a3 f8 36 11 80       	mov    %eax,0x801136f8
  if(kmem.use_lock)
80102c79:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102c7e:	85 c0                	test   %eax,%eax
80102c80:	74 10                	je     80102c92 <kfree+0x97>
    release(&kmem.lock);
80102c82:	83 ec 0c             	sub    $0xc,%esp
80102c85:	68 c0 36 11 80       	push   $0x801136c0
80102c8a:	e8 6a 23 00 00       	call   80104ff9 <release>
80102c8f:	83 c4 10             	add    $0x10,%esp
}
80102c92:	90                   	nop
80102c93:	c9                   	leave  
80102c94:	c3                   	ret    

80102c95 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102c95:	55                   	push   %ebp
80102c96:	89 e5                	mov    %esp,%ebp
80102c98:	83 ec 18             	sub    $0x18,%esp
  struct run *r;

  if(kmem.use_lock)
80102c9b:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102ca0:	85 c0                	test   %eax,%eax
80102ca2:	74 10                	je     80102cb4 <kalloc+0x1f>
    acquire(&kmem.lock);
80102ca4:	83 ec 0c             	sub    $0xc,%esp
80102ca7:	68 c0 36 11 80       	push   $0x801136c0
80102cac:	e8 da 22 00 00       	call   80104f8b <acquire>
80102cb1:	83 c4 10             	add    $0x10,%esp
  r = kmem.freelist;
80102cb4:	a1 f8 36 11 80       	mov    0x801136f8,%eax
80102cb9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102cbc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102cc0:	74 0a                	je     80102ccc <kalloc+0x37>
    kmem.freelist = r->next;
80102cc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cc5:	8b 00                	mov    (%eax),%eax
80102cc7:	a3 f8 36 11 80       	mov    %eax,0x801136f8
  if(kmem.use_lock)
80102ccc:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102cd1:	85 c0                	test   %eax,%eax
80102cd3:	74 10                	je     80102ce5 <kalloc+0x50>
    release(&kmem.lock);
80102cd5:	83 ec 0c             	sub    $0xc,%esp
80102cd8:	68 c0 36 11 80       	push   $0x801136c0
80102cdd:	e8 17 23 00 00       	call   80104ff9 <release>
80102ce2:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
80102ce5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102ce8:	c9                   	leave  
80102ce9:	c3                   	ret    

80102cea <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102cea:	55                   	push   %ebp
80102ceb:	89 e5                	mov    %esp,%ebp
80102ced:	83 ec 14             	sub    $0x14,%esp
80102cf0:	8b 45 08             	mov    0x8(%ebp),%eax
80102cf3:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102cf7:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102cfb:	89 c2                	mov    %eax,%edx
80102cfd:	ec                   	in     (%dx),%al
80102cfe:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102d01:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102d05:	c9                   	leave  
80102d06:	c3                   	ret    

80102d07 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102d07:	55                   	push   %ebp
80102d08:	89 e5                	mov    %esp,%ebp
80102d0a:	83 ec 10             	sub    $0x10,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102d0d:	6a 64                	push   $0x64
80102d0f:	e8 d6 ff ff ff       	call   80102cea <inb>
80102d14:	83 c4 04             	add    $0x4,%esp
80102d17:	0f b6 c0             	movzbl %al,%eax
80102d1a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102d1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d20:	83 e0 01             	and    $0x1,%eax
80102d23:	85 c0                	test   %eax,%eax
80102d25:	75 0a                	jne    80102d31 <kbdgetc+0x2a>
    return -1;
80102d27:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d2c:	e9 23 01 00 00       	jmp    80102e54 <kbdgetc+0x14d>
  data = inb(KBDATAP);
80102d31:	6a 60                	push   $0x60
80102d33:	e8 b2 ff ff ff       	call   80102cea <inb>
80102d38:	83 c4 04             	add    $0x4,%esp
80102d3b:	0f b6 c0             	movzbl %al,%eax
80102d3e:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102d41:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102d48:	75 17                	jne    80102d61 <kbdgetc+0x5a>
    shift |= E0ESC;
80102d4a:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102d4f:	83 c8 40             	or     $0x40,%eax
80102d52:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
    return 0;
80102d57:	b8 00 00 00 00       	mov    $0x0,%eax
80102d5c:	e9 f3 00 00 00       	jmp    80102e54 <kbdgetc+0x14d>
  } else if(data & 0x80){
80102d61:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d64:	25 80 00 00 00       	and    $0x80,%eax
80102d69:	85 c0                	test   %eax,%eax
80102d6b:	74 45                	je     80102db2 <kbdgetc+0xab>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102d6d:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102d72:	83 e0 40             	and    $0x40,%eax
80102d75:	85 c0                	test   %eax,%eax
80102d77:	75 08                	jne    80102d81 <kbdgetc+0x7a>
80102d79:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d7c:	83 e0 7f             	and    $0x7f,%eax
80102d7f:	eb 03                	jmp    80102d84 <kbdgetc+0x7d>
80102d81:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d84:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102d87:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d8a:	05 20 90 10 80       	add    $0x80109020,%eax
80102d8f:	0f b6 00             	movzbl (%eax),%eax
80102d92:	83 c8 40             	or     $0x40,%eax
80102d95:	0f b6 c0             	movzbl %al,%eax
80102d98:	f7 d0                	not    %eax
80102d9a:	89 c2                	mov    %eax,%edx
80102d9c:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102da1:	21 d0                	and    %edx,%eax
80102da3:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
    return 0;
80102da8:	b8 00 00 00 00       	mov    $0x0,%eax
80102dad:	e9 a2 00 00 00       	jmp    80102e54 <kbdgetc+0x14d>
  } else if(shift & E0ESC){
80102db2:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102db7:	83 e0 40             	and    $0x40,%eax
80102dba:	85 c0                	test   %eax,%eax
80102dbc:	74 14                	je     80102dd2 <kbdgetc+0xcb>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102dbe:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102dc5:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102dca:	83 e0 bf             	and    $0xffffffbf,%eax
80102dcd:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  }

  shift |= shiftcode[data];
80102dd2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102dd5:	05 20 90 10 80       	add    $0x80109020,%eax
80102dda:	0f b6 00             	movzbl (%eax),%eax
80102ddd:	0f b6 d0             	movzbl %al,%edx
80102de0:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102de5:	09 d0                	or     %edx,%eax
80102de7:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  shift ^= togglecode[data];
80102dec:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102def:	05 20 91 10 80       	add    $0x80109120,%eax
80102df4:	0f b6 00             	movzbl (%eax),%eax
80102df7:	0f b6 d0             	movzbl %al,%edx
80102dfa:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102dff:	31 d0                	xor    %edx,%eax
80102e01:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  c = charcode[shift & (CTL | SHIFT)][data];
80102e06:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102e0b:	83 e0 03             	and    $0x3,%eax
80102e0e:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
80102e15:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e18:	01 d0                	add    %edx,%eax
80102e1a:	0f b6 00             	movzbl (%eax),%eax
80102e1d:	0f b6 c0             	movzbl %al,%eax
80102e20:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102e23:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102e28:	83 e0 08             	and    $0x8,%eax
80102e2b:	85 c0                	test   %eax,%eax
80102e2d:	74 22                	je     80102e51 <kbdgetc+0x14a>
    if('a' <= c && c <= 'z')
80102e2f:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102e33:	76 0c                	jbe    80102e41 <kbdgetc+0x13a>
80102e35:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102e39:	77 06                	ja     80102e41 <kbdgetc+0x13a>
      c += 'A' - 'a';
80102e3b:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102e3f:	eb 10                	jmp    80102e51 <kbdgetc+0x14a>
    else if('A' <= c && c <= 'Z')
80102e41:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102e45:	76 0a                	jbe    80102e51 <kbdgetc+0x14a>
80102e47:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102e4b:	77 04                	ja     80102e51 <kbdgetc+0x14a>
      c += 'a' - 'A';
80102e4d:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102e51:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102e54:	c9                   	leave  
80102e55:	c3                   	ret    

80102e56 <kbdintr>:

void
kbdintr(void)
{
80102e56:	55                   	push   %ebp
80102e57:	89 e5                	mov    %esp,%ebp
80102e59:	83 ec 08             	sub    $0x8,%esp
  consoleintr(kbdgetc);
80102e5c:	83 ec 0c             	sub    $0xc,%esp
80102e5f:	68 07 2d 10 80       	push   $0x80102d07
80102e64:	e8 c3 d9 ff ff       	call   8010082c <consoleintr>
80102e69:	83 c4 10             	add    $0x10,%esp
}
80102e6c:	90                   	nop
80102e6d:	c9                   	leave  
80102e6e:	c3                   	ret    

80102e6f <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102e6f:	55                   	push   %ebp
80102e70:	89 e5                	mov    %esp,%ebp
80102e72:	83 ec 14             	sub    $0x14,%esp
80102e75:	8b 45 08             	mov    0x8(%ebp),%eax
80102e78:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102e7c:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102e80:	89 c2                	mov    %eax,%edx
80102e82:	ec                   	in     (%dx),%al
80102e83:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102e86:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102e8a:	c9                   	leave  
80102e8b:	c3                   	ret    

80102e8c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102e8c:	55                   	push   %ebp
80102e8d:	89 e5                	mov    %esp,%ebp
80102e8f:	83 ec 08             	sub    $0x8,%esp
80102e92:	8b 55 08             	mov    0x8(%ebp),%edx
80102e95:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e98:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102e9c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e9f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102ea3:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102ea7:	ee                   	out    %al,(%dx)
}
80102ea8:	90                   	nop
80102ea9:	c9                   	leave  
80102eaa:	c3                   	ret    

80102eab <lapicw>:
volatile uint *lapic;  // Initialized in mp.c

//PAGEBREAK!
static void
lapicw(int index, int value)
{
80102eab:	55                   	push   %ebp
80102eac:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102eae:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102eb3:	8b 55 08             	mov    0x8(%ebp),%edx
80102eb6:	c1 e2 02             	shl    $0x2,%edx
80102eb9:	01 c2                	add    %eax,%edx
80102ebb:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ebe:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102ec0:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102ec5:	83 c0 20             	add    $0x20,%eax
80102ec8:	8b 00                	mov    (%eax),%eax
}
80102eca:	90                   	nop
80102ecb:	5d                   	pop    %ebp
80102ecc:	c3                   	ret    

80102ecd <lapicinit>:

void
lapicinit(void)
{
80102ecd:	55                   	push   %ebp
80102ece:	89 e5                	mov    %esp,%ebp
  if(!lapic)
80102ed0:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102ed5:	85 c0                	test   %eax,%eax
80102ed7:	0f 84 0b 01 00 00    	je     80102fe8 <lapicinit+0x11b>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102edd:	68 3f 01 00 00       	push   $0x13f
80102ee2:	6a 3c                	push   $0x3c
80102ee4:	e8 c2 ff ff ff       	call   80102eab <lapicw>
80102ee9:	83 c4 08             	add    $0x8,%esp

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102eec:	6a 0b                	push   $0xb
80102eee:	68 f8 00 00 00       	push   $0xf8
80102ef3:	e8 b3 ff ff ff       	call   80102eab <lapicw>
80102ef8:	83 c4 08             	add    $0x8,%esp
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102efb:	68 20 00 02 00       	push   $0x20020
80102f00:	68 c8 00 00 00       	push   $0xc8
80102f05:	e8 a1 ff ff ff       	call   80102eab <lapicw>
80102f0a:	83 c4 08             	add    $0x8,%esp
  lapicw(TICR, 10000000);
80102f0d:	68 80 96 98 00       	push   $0x989680
80102f12:	68 e0 00 00 00       	push   $0xe0
80102f17:	e8 8f ff ff ff       	call   80102eab <lapicw>
80102f1c:	83 c4 08             	add    $0x8,%esp

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102f1f:	68 00 00 01 00       	push   $0x10000
80102f24:	68 d4 00 00 00       	push   $0xd4
80102f29:	e8 7d ff ff ff       	call   80102eab <lapicw>
80102f2e:	83 c4 08             	add    $0x8,%esp
  lapicw(LINT1, MASKED);
80102f31:	68 00 00 01 00       	push   $0x10000
80102f36:	68 d8 00 00 00       	push   $0xd8
80102f3b:	e8 6b ff ff ff       	call   80102eab <lapicw>
80102f40:	83 c4 08             	add    $0x8,%esp

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102f43:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102f48:	83 c0 30             	add    $0x30,%eax
80102f4b:	8b 00                	mov    (%eax),%eax
80102f4d:	c1 e8 10             	shr    $0x10,%eax
80102f50:	0f b6 c0             	movzbl %al,%eax
80102f53:	83 f8 03             	cmp    $0x3,%eax
80102f56:	76 12                	jbe    80102f6a <lapicinit+0x9d>
    lapicw(PCINT, MASKED);
80102f58:	68 00 00 01 00       	push   $0x10000
80102f5d:	68 d0 00 00 00       	push   $0xd0
80102f62:	e8 44 ff ff ff       	call   80102eab <lapicw>
80102f67:	83 c4 08             	add    $0x8,%esp

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102f6a:	6a 33                	push   $0x33
80102f6c:	68 dc 00 00 00       	push   $0xdc
80102f71:	e8 35 ff ff ff       	call   80102eab <lapicw>
80102f76:	83 c4 08             	add    $0x8,%esp

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102f79:	6a 00                	push   $0x0
80102f7b:	68 a0 00 00 00       	push   $0xa0
80102f80:	e8 26 ff ff ff       	call   80102eab <lapicw>
80102f85:	83 c4 08             	add    $0x8,%esp
  lapicw(ESR, 0);
80102f88:	6a 00                	push   $0x0
80102f8a:	68 a0 00 00 00       	push   $0xa0
80102f8f:	e8 17 ff ff ff       	call   80102eab <lapicw>
80102f94:	83 c4 08             	add    $0x8,%esp

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102f97:	6a 00                	push   $0x0
80102f99:	6a 2c                	push   $0x2c
80102f9b:	e8 0b ff ff ff       	call   80102eab <lapicw>
80102fa0:	83 c4 08             	add    $0x8,%esp

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102fa3:	6a 00                	push   $0x0
80102fa5:	68 c4 00 00 00       	push   $0xc4
80102faa:	e8 fc fe ff ff       	call   80102eab <lapicw>
80102faf:	83 c4 08             	add    $0x8,%esp
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102fb2:	68 00 85 08 00       	push   $0x88500
80102fb7:	68 c0 00 00 00       	push   $0xc0
80102fbc:	e8 ea fe ff ff       	call   80102eab <lapicw>
80102fc1:	83 c4 08             	add    $0x8,%esp
  while(lapic[ICRLO] & DELIVS)
80102fc4:	90                   	nop
80102fc5:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102fca:	05 00 03 00 00       	add    $0x300,%eax
80102fcf:	8b 00                	mov    (%eax),%eax
80102fd1:	25 00 10 00 00       	and    $0x1000,%eax
80102fd6:	85 c0                	test   %eax,%eax
80102fd8:	75 eb                	jne    80102fc5 <lapicinit+0xf8>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102fda:	6a 00                	push   $0x0
80102fdc:	6a 20                	push   $0x20
80102fde:	e8 c8 fe ff ff       	call   80102eab <lapicw>
80102fe3:	83 c4 08             	add    $0x8,%esp
80102fe6:	eb 01                	jmp    80102fe9 <lapicinit+0x11c>

void
lapicinit(void)
{
  if(!lapic)
    return;
80102fe8:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102fe9:	c9                   	leave  
80102fea:	c3                   	ret    

80102feb <lapicid>:

int
lapicid(void)
{
80102feb:	55                   	push   %ebp
80102fec:	89 e5                	mov    %esp,%ebp
  if (!lapic)
80102fee:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102ff3:	85 c0                	test   %eax,%eax
80102ff5:	75 07                	jne    80102ffe <lapicid+0x13>
    return 0;
80102ff7:	b8 00 00 00 00       	mov    $0x0,%eax
80102ffc:	eb 0d                	jmp    8010300b <lapicid+0x20>
  return lapic[ID] >> 24;
80102ffe:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80103003:	83 c0 20             	add    $0x20,%eax
80103006:	8b 00                	mov    (%eax),%eax
80103008:	c1 e8 18             	shr    $0x18,%eax
}
8010300b:	5d                   	pop    %ebp
8010300c:	c3                   	ret    

8010300d <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
8010300d:	55                   	push   %ebp
8010300e:	89 e5                	mov    %esp,%ebp
  if(lapic)
80103010:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80103015:	85 c0                	test   %eax,%eax
80103017:	74 0c                	je     80103025 <lapiceoi+0x18>
    lapicw(EOI, 0);
80103019:	6a 00                	push   $0x0
8010301b:	6a 2c                	push   $0x2c
8010301d:	e8 89 fe ff ff       	call   80102eab <lapicw>
80103022:	83 c4 08             	add    $0x8,%esp
}
80103025:	90                   	nop
80103026:	c9                   	leave  
80103027:	c3                   	ret    

80103028 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103028:	55                   	push   %ebp
80103029:	89 e5                	mov    %esp,%ebp
}
8010302b:	90                   	nop
8010302c:	5d                   	pop    %ebp
8010302d:	c3                   	ret    

8010302e <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010302e:	55                   	push   %ebp
8010302f:	89 e5                	mov    %esp,%ebp
80103031:	83 ec 14             	sub    $0x14,%esp
80103034:	8b 45 08             	mov    0x8(%ebp),%eax
80103037:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;

  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
8010303a:	6a 0f                	push   $0xf
8010303c:	6a 70                	push   $0x70
8010303e:	e8 49 fe ff ff       	call   80102e8c <outb>
80103043:	83 c4 08             	add    $0x8,%esp
  outb(CMOS_PORT+1, 0x0A);
80103046:	6a 0a                	push   $0xa
80103048:	6a 71                	push   $0x71
8010304a:	e8 3d fe ff ff       	call   80102e8c <outb>
8010304f:	83 c4 08             	add    $0x8,%esp
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103052:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103059:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010305c:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103061:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103064:	83 c0 02             	add    $0x2,%eax
80103067:	8b 55 0c             	mov    0xc(%ebp),%edx
8010306a:	c1 ea 04             	shr    $0x4,%edx
8010306d:	66 89 10             	mov    %dx,(%eax)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103070:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103074:	c1 e0 18             	shl    $0x18,%eax
80103077:	50                   	push   %eax
80103078:	68 c4 00 00 00       	push   $0xc4
8010307d:	e8 29 fe ff ff       	call   80102eab <lapicw>
80103082:	83 c4 08             	add    $0x8,%esp
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103085:	68 00 c5 00 00       	push   $0xc500
8010308a:	68 c0 00 00 00       	push   $0xc0
8010308f:	e8 17 fe ff ff       	call   80102eab <lapicw>
80103094:	83 c4 08             	add    $0x8,%esp
  microdelay(200);
80103097:	68 c8 00 00 00       	push   $0xc8
8010309c:	e8 87 ff ff ff       	call   80103028 <microdelay>
801030a1:	83 c4 04             	add    $0x4,%esp
  lapicw(ICRLO, INIT | LEVEL);
801030a4:	68 00 85 00 00       	push   $0x8500
801030a9:	68 c0 00 00 00       	push   $0xc0
801030ae:	e8 f8 fd ff ff       	call   80102eab <lapicw>
801030b3:	83 c4 08             	add    $0x8,%esp
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801030b6:	6a 64                	push   $0x64
801030b8:	e8 6b ff ff ff       	call   80103028 <microdelay>
801030bd:	83 c4 04             	add    $0x4,%esp
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801030c0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801030c7:	eb 3d                	jmp    80103106 <lapicstartap+0xd8>
    lapicw(ICRHI, apicid<<24);
801030c9:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801030cd:	c1 e0 18             	shl    $0x18,%eax
801030d0:	50                   	push   %eax
801030d1:	68 c4 00 00 00       	push   $0xc4
801030d6:	e8 d0 fd ff ff       	call   80102eab <lapicw>
801030db:	83 c4 08             	add    $0x8,%esp
    lapicw(ICRLO, STARTUP | (addr>>12));
801030de:	8b 45 0c             	mov    0xc(%ebp),%eax
801030e1:	c1 e8 0c             	shr    $0xc,%eax
801030e4:	80 cc 06             	or     $0x6,%ah
801030e7:	50                   	push   %eax
801030e8:	68 c0 00 00 00       	push   $0xc0
801030ed:	e8 b9 fd ff ff       	call   80102eab <lapicw>
801030f2:	83 c4 08             	add    $0x8,%esp
    microdelay(200);
801030f5:	68 c8 00 00 00       	push   $0xc8
801030fa:	e8 29 ff ff ff       	call   80103028 <microdelay>
801030ff:	83 c4 04             	add    $0x4,%esp
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103102:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103106:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
8010310a:	7e bd                	jle    801030c9 <lapicstartap+0x9b>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010310c:	90                   	nop
8010310d:	c9                   	leave  
8010310e:	c3                   	ret    

8010310f <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
8010310f:	55                   	push   %ebp
80103110:	89 e5                	mov    %esp,%ebp
  outb(CMOS_PORT,  reg);
80103112:	8b 45 08             	mov    0x8(%ebp),%eax
80103115:	0f b6 c0             	movzbl %al,%eax
80103118:	50                   	push   %eax
80103119:	6a 70                	push   $0x70
8010311b:	e8 6c fd ff ff       	call   80102e8c <outb>
80103120:	83 c4 08             	add    $0x8,%esp
  microdelay(200);
80103123:	68 c8 00 00 00       	push   $0xc8
80103128:	e8 fb fe ff ff       	call   80103028 <microdelay>
8010312d:	83 c4 04             	add    $0x4,%esp

  return inb(CMOS_RETURN);
80103130:	6a 71                	push   $0x71
80103132:	e8 38 fd ff ff       	call   80102e6f <inb>
80103137:	83 c4 04             	add    $0x4,%esp
8010313a:	0f b6 c0             	movzbl %al,%eax
}
8010313d:	c9                   	leave  
8010313e:	c3                   	ret    

8010313f <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
8010313f:	55                   	push   %ebp
80103140:	89 e5                	mov    %esp,%ebp
  r->second = cmos_read(SECS);
80103142:	6a 00                	push   $0x0
80103144:	e8 c6 ff ff ff       	call   8010310f <cmos_read>
80103149:	83 c4 04             	add    $0x4,%esp
8010314c:	89 c2                	mov    %eax,%edx
8010314e:	8b 45 08             	mov    0x8(%ebp),%eax
80103151:	89 10                	mov    %edx,(%eax)
  r->minute = cmos_read(MINS);
80103153:	6a 02                	push   $0x2
80103155:	e8 b5 ff ff ff       	call   8010310f <cmos_read>
8010315a:	83 c4 04             	add    $0x4,%esp
8010315d:	89 c2                	mov    %eax,%edx
8010315f:	8b 45 08             	mov    0x8(%ebp),%eax
80103162:	89 50 04             	mov    %edx,0x4(%eax)
  r->hour   = cmos_read(HOURS);
80103165:	6a 04                	push   $0x4
80103167:	e8 a3 ff ff ff       	call   8010310f <cmos_read>
8010316c:	83 c4 04             	add    $0x4,%esp
8010316f:	89 c2                	mov    %eax,%edx
80103171:	8b 45 08             	mov    0x8(%ebp),%eax
80103174:	89 50 08             	mov    %edx,0x8(%eax)
  r->day    = cmos_read(DAY);
80103177:	6a 07                	push   $0x7
80103179:	e8 91 ff ff ff       	call   8010310f <cmos_read>
8010317e:	83 c4 04             	add    $0x4,%esp
80103181:	89 c2                	mov    %eax,%edx
80103183:	8b 45 08             	mov    0x8(%ebp),%eax
80103186:	89 50 0c             	mov    %edx,0xc(%eax)
  r->month  = cmos_read(MONTH);
80103189:	6a 08                	push   $0x8
8010318b:	e8 7f ff ff ff       	call   8010310f <cmos_read>
80103190:	83 c4 04             	add    $0x4,%esp
80103193:	89 c2                	mov    %eax,%edx
80103195:	8b 45 08             	mov    0x8(%ebp),%eax
80103198:	89 50 10             	mov    %edx,0x10(%eax)
  r->year   = cmos_read(YEAR);
8010319b:	6a 09                	push   $0x9
8010319d:	e8 6d ff ff ff       	call   8010310f <cmos_read>
801031a2:	83 c4 04             	add    $0x4,%esp
801031a5:	89 c2                	mov    %eax,%edx
801031a7:	8b 45 08             	mov    0x8(%ebp),%eax
801031aa:	89 50 14             	mov    %edx,0x14(%eax)
}
801031ad:	90                   	nop
801031ae:	c9                   	leave  
801031af:	c3                   	ret    

801031b0 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
801031b0:	55                   	push   %ebp
801031b1:	89 e5                	mov    %esp,%ebp
801031b3:	83 ec 48             	sub    $0x48,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801031b6:	6a 0b                	push   $0xb
801031b8:	e8 52 ff ff ff       	call   8010310f <cmos_read>
801031bd:	83 c4 04             	add    $0x4,%esp
801031c0:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801031c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031c6:	83 e0 04             	and    $0x4,%eax
801031c9:	85 c0                	test   %eax,%eax
801031cb:	0f 94 c0             	sete   %al
801031ce:	0f b6 c0             	movzbl %al,%eax
801031d1:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801031d4:	8d 45 d8             	lea    -0x28(%ebp),%eax
801031d7:	50                   	push   %eax
801031d8:	e8 62 ff ff ff       	call   8010313f <fill_rtcdate>
801031dd:	83 c4 04             	add    $0x4,%esp
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801031e0:	6a 0a                	push   $0xa
801031e2:	e8 28 ff ff ff       	call   8010310f <cmos_read>
801031e7:	83 c4 04             	add    $0x4,%esp
801031ea:	25 80 00 00 00       	and    $0x80,%eax
801031ef:	85 c0                	test   %eax,%eax
801031f1:	75 27                	jne    8010321a <cmostime+0x6a>
        continue;
    fill_rtcdate(&t2);
801031f3:	8d 45 c0             	lea    -0x40(%ebp),%eax
801031f6:	50                   	push   %eax
801031f7:	e8 43 ff ff ff       	call   8010313f <fill_rtcdate>
801031fc:	83 c4 04             	add    $0x4,%esp
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801031ff:	83 ec 04             	sub    $0x4,%esp
80103202:	6a 18                	push   $0x18
80103204:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103207:	50                   	push   %eax
80103208:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010320b:	50                   	push   %eax
8010320c:	e8 58 20 00 00       	call   80105269 <memcmp>
80103211:	83 c4 10             	add    $0x10,%esp
80103214:	85 c0                	test   %eax,%eax
80103216:	74 05                	je     8010321d <cmostime+0x6d>
80103218:	eb ba                	jmp    801031d4 <cmostime+0x24>

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
8010321a:	90                   	nop
    fill_rtcdate(&t2);
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
8010321b:	eb b7                	jmp    801031d4 <cmostime+0x24>
    fill_rtcdate(&t1);
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
8010321d:	90                   	nop
  }

  // convert
  if(bcd) {
8010321e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103222:	0f 84 b4 00 00 00    	je     801032dc <cmostime+0x12c>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80103228:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010322b:	c1 e8 04             	shr    $0x4,%eax
8010322e:	89 c2                	mov    %eax,%edx
80103230:	89 d0                	mov    %edx,%eax
80103232:	c1 e0 02             	shl    $0x2,%eax
80103235:	01 d0                	add    %edx,%eax
80103237:	01 c0                	add    %eax,%eax
80103239:	89 c2                	mov    %eax,%edx
8010323b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010323e:	83 e0 0f             	and    $0xf,%eax
80103241:	01 d0                	add    %edx,%eax
80103243:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
80103246:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103249:	c1 e8 04             	shr    $0x4,%eax
8010324c:	89 c2                	mov    %eax,%edx
8010324e:	89 d0                	mov    %edx,%eax
80103250:	c1 e0 02             	shl    $0x2,%eax
80103253:	01 d0                	add    %edx,%eax
80103255:	01 c0                	add    %eax,%eax
80103257:	89 c2                	mov    %eax,%edx
80103259:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010325c:	83 e0 0f             	and    $0xf,%eax
8010325f:	01 d0                	add    %edx,%eax
80103261:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
80103264:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103267:	c1 e8 04             	shr    $0x4,%eax
8010326a:	89 c2                	mov    %eax,%edx
8010326c:	89 d0                	mov    %edx,%eax
8010326e:	c1 e0 02             	shl    $0x2,%eax
80103271:	01 d0                	add    %edx,%eax
80103273:	01 c0                	add    %eax,%eax
80103275:	89 c2                	mov    %eax,%edx
80103277:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010327a:	83 e0 0f             	and    $0xf,%eax
8010327d:	01 d0                	add    %edx,%eax
8010327f:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103282:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103285:	c1 e8 04             	shr    $0x4,%eax
80103288:	89 c2                	mov    %eax,%edx
8010328a:	89 d0                	mov    %edx,%eax
8010328c:	c1 e0 02             	shl    $0x2,%eax
8010328f:	01 d0                	add    %edx,%eax
80103291:	01 c0                	add    %eax,%eax
80103293:	89 c2                	mov    %eax,%edx
80103295:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103298:	83 e0 0f             	and    $0xf,%eax
8010329b:	01 d0                	add    %edx,%eax
8010329d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
801032a0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801032a3:	c1 e8 04             	shr    $0x4,%eax
801032a6:	89 c2                	mov    %eax,%edx
801032a8:	89 d0                	mov    %edx,%eax
801032aa:	c1 e0 02             	shl    $0x2,%eax
801032ad:	01 d0                	add    %edx,%eax
801032af:	01 c0                	add    %eax,%eax
801032b1:	89 c2                	mov    %eax,%edx
801032b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801032b6:	83 e0 0f             	and    $0xf,%eax
801032b9:	01 d0                	add    %edx,%eax
801032bb:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801032be:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032c1:	c1 e8 04             	shr    $0x4,%eax
801032c4:	89 c2                	mov    %eax,%edx
801032c6:	89 d0                	mov    %edx,%eax
801032c8:	c1 e0 02             	shl    $0x2,%eax
801032cb:	01 d0                	add    %edx,%eax
801032cd:	01 c0                	add    %eax,%eax
801032cf:	89 c2                	mov    %eax,%edx
801032d1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032d4:	83 e0 0f             	and    $0xf,%eax
801032d7:	01 d0                	add    %edx,%eax
801032d9:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
801032dc:	8b 45 08             	mov    0x8(%ebp),%eax
801032df:	8b 55 d8             	mov    -0x28(%ebp),%edx
801032e2:	89 10                	mov    %edx,(%eax)
801032e4:	8b 55 dc             	mov    -0x24(%ebp),%edx
801032e7:	89 50 04             	mov    %edx,0x4(%eax)
801032ea:	8b 55 e0             	mov    -0x20(%ebp),%edx
801032ed:	89 50 08             	mov    %edx,0x8(%eax)
801032f0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801032f3:	89 50 0c             	mov    %edx,0xc(%eax)
801032f6:	8b 55 e8             	mov    -0x18(%ebp),%edx
801032f9:	89 50 10             	mov    %edx,0x10(%eax)
801032fc:	8b 55 ec             	mov    -0x14(%ebp),%edx
801032ff:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103302:	8b 45 08             	mov    0x8(%ebp),%eax
80103305:	8b 40 14             	mov    0x14(%eax),%eax
80103308:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
8010330e:	8b 45 08             	mov    0x8(%ebp),%eax
80103311:	89 50 14             	mov    %edx,0x14(%eax)
}
80103314:	90                   	nop
80103315:	c9                   	leave  
80103316:	c3                   	ret    

80103317 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
80103317:	55                   	push   %ebp
80103318:	89 e5                	mov    %esp,%ebp
8010331a:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010331d:	83 ec 08             	sub    $0x8,%esp
80103320:	68 91 85 10 80       	push   $0x80108591
80103325:	68 00 37 11 80       	push   $0x80113700
8010332a:	e8 3a 1c 00 00       	call   80104f69 <initlock>
8010332f:	83 c4 10             	add    $0x10,%esp
  readsb(dev, &sb);
80103332:	83 ec 08             	sub    $0x8,%esp
80103335:	8d 45 dc             	lea    -0x24(%ebp),%eax
80103338:	50                   	push   %eax
80103339:	ff 75 08             	pushl  0x8(%ebp)
8010333c:	e8 a3 e0 ff ff       	call   801013e4 <readsb>
80103341:	83 c4 10             	add    $0x10,%esp
  log.start = sb.logstart;
80103344:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103347:	a3 34 37 11 80       	mov    %eax,0x80113734
  log.size = sb.nlog;
8010334c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010334f:	a3 38 37 11 80       	mov    %eax,0x80113738
  log.dev = dev;
80103354:	8b 45 08             	mov    0x8(%ebp),%eax
80103357:	a3 44 37 11 80       	mov    %eax,0x80113744
  recover_from_log();
8010335c:	e8 b2 01 00 00       	call   80103513 <recover_from_log>
}
80103361:	90                   	nop
80103362:	c9                   	leave  
80103363:	c3                   	ret    

80103364 <install_trans>:

// Copy committed blocks from log to their home location
static void
install_trans(void)
{
80103364:	55                   	push   %ebp
80103365:	89 e5                	mov    %esp,%ebp
80103367:	83 ec 18             	sub    $0x18,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010336a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103371:	e9 95 00 00 00       	jmp    8010340b <install_trans+0xa7>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103376:	8b 15 34 37 11 80    	mov    0x80113734,%edx
8010337c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010337f:	01 d0                	add    %edx,%eax
80103381:	83 c0 01             	add    $0x1,%eax
80103384:	89 c2                	mov    %eax,%edx
80103386:	a1 44 37 11 80       	mov    0x80113744,%eax
8010338b:	83 ec 08             	sub    $0x8,%esp
8010338e:	52                   	push   %edx
8010338f:	50                   	push   %eax
80103390:	e8 39 ce ff ff       	call   801001ce <bread>
80103395:	83 c4 10             	add    $0x10,%esp
80103398:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
8010339b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010339e:	83 c0 10             	add    $0x10,%eax
801033a1:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
801033a8:	89 c2                	mov    %eax,%edx
801033aa:	a1 44 37 11 80       	mov    0x80113744,%eax
801033af:	83 ec 08             	sub    $0x8,%esp
801033b2:	52                   	push   %edx
801033b3:	50                   	push   %eax
801033b4:	e8 15 ce ff ff       	call   801001ce <bread>
801033b9:	83 c4 10             	add    $0x10,%esp
801033bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801033bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033c2:	8d 50 5c             	lea    0x5c(%eax),%edx
801033c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033c8:	83 c0 5c             	add    $0x5c,%eax
801033cb:	83 ec 04             	sub    $0x4,%esp
801033ce:	68 00 02 00 00       	push   $0x200
801033d3:	52                   	push   %edx
801033d4:	50                   	push   %eax
801033d5:	e8 e7 1e 00 00       	call   801052c1 <memmove>
801033da:	83 c4 10             	add    $0x10,%esp
    bwrite(dbuf);  // write dst to disk
801033dd:	83 ec 0c             	sub    $0xc,%esp
801033e0:	ff 75 ec             	pushl  -0x14(%ebp)
801033e3:	e8 1f ce ff ff       	call   80100207 <bwrite>
801033e8:	83 c4 10             	add    $0x10,%esp
    brelse(lbuf);
801033eb:	83 ec 0c             	sub    $0xc,%esp
801033ee:	ff 75 f0             	pushl  -0x10(%ebp)
801033f1:	e8 5a ce ff ff       	call   80100250 <brelse>
801033f6:	83 c4 10             	add    $0x10,%esp
    brelse(dbuf);
801033f9:	83 ec 0c             	sub    $0xc,%esp
801033fc:	ff 75 ec             	pushl  -0x14(%ebp)
801033ff:	e8 4c ce ff ff       	call   80100250 <brelse>
80103404:	83 c4 10             	add    $0x10,%esp
static void
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103407:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010340b:	a1 48 37 11 80       	mov    0x80113748,%eax
80103410:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103413:	0f 8f 5d ff ff ff    	jg     80103376 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf);
    brelse(dbuf);
  }
}
80103419:	90                   	nop
8010341a:	c9                   	leave  
8010341b:	c3                   	ret    

8010341c <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010341c:	55                   	push   %ebp
8010341d:	89 e5                	mov    %esp,%ebp
8010341f:	83 ec 18             	sub    $0x18,%esp
  struct buf *buf = bread(log.dev, log.start);
80103422:	a1 34 37 11 80       	mov    0x80113734,%eax
80103427:	89 c2                	mov    %eax,%edx
80103429:	a1 44 37 11 80       	mov    0x80113744,%eax
8010342e:	83 ec 08             	sub    $0x8,%esp
80103431:	52                   	push   %edx
80103432:	50                   	push   %eax
80103433:	e8 96 cd ff ff       	call   801001ce <bread>
80103438:	83 c4 10             	add    $0x10,%esp
8010343b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010343e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103441:	83 c0 5c             	add    $0x5c,%eax
80103444:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103447:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010344a:	8b 00                	mov    (%eax),%eax
8010344c:	a3 48 37 11 80       	mov    %eax,0x80113748
  for (i = 0; i < log.lh.n; i++) {
80103451:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103458:	eb 1b                	jmp    80103475 <read_head+0x59>
    log.lh.block[i] = lh->block[i];
8010345a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010345d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103460:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103464:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103467:	83 c2 10             	add    $0x10,%edx
8010346a:	89 04 95 0c 37 11 80 	mov    %eax,-0x7feec8f4(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103471:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103475:	a1 48 37 11 80       	mov    0x80113748,%eax
8010347a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010347d:	7f db                	jg     8010345a <read_head+0x3e>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
8010347f:	83 ec 0c             	sub    $0xc,%esp
80103482:	ff 75 f0             	pushl  -0x10(%ebp)
80103485:	e8 c6 cd ff ff       	call   80100250 <brelse>
8010348a:	83 c4 10             	add    $0x10,%esp
}
8010348d:	90                   	nop
8010348e:	c9                   	leave  
8010348f:	c3                   	ret    

80103490 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103490:	55                   	push   %ebp
80103491:	89 e5                	mov    %esp,%ebp
80103493:	83 ec 18             	sub    $0x18,%esp
  struct buf *buf = bread(log.dev, log.start);
80103496:	a1 34 37 11 80       	mov    0x80113734,%eax
8010349b:	89 c2                	mov    %eax,%edx
8010349d:	a1 44 37 11 80       	mov    0x80113744,%eax
801034a2:	83 ec 08             	sub    $0x8,%esp
801034a5:	52                   	push   %edx
801034a6:	50                   	push   %eax
801034a7:	e8 22 cd ff ff       	call   801001ce <bread>
801034ac:	83 c4 10             	add    $0x10,%esp
801034af:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801034b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034b5:	83 c0 5c             	add    $0x5c,%eax
801034b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801034bb:	8b 15 48 37 11 80    	mov    0x80113748,%edx
801034c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034c4:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801034c6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801034cd:	eb 1b                	jmp    801034ea <write_head+0x5a>
    hb->block[i] = log.lh.block[i];
801034cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034d2:	83 c0 10             	add    $0x10,%eax
801034d5:	8b 0c 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%ecx
801034dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034df:	8b 55 f4             	mov    -0xc(%ebp),%edx
801034e2:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801034e6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801034ea:	a1 48 37 11 80       	mov    0x80113748,%eax
801034ef:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801034f2:	7f db                	jg     801034cf <write_head+0x3f>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
801034f4:	83 ec 0c             	sub    $0xc,%esp
801034f7:	ff 75 f0             	pushl  -0x10(%ebp)
801034fa:	e8 08 cd ff ff       	call   80100207 <bwrite>
801034ff:	83 c4 10             	add    $0x10,%esp
  brelse(buf);
80103502:	83 ec 0c             	sub    $0xc,%esp
80103505:	ff 75 f0             	pushl  -0x10(%ebp)
80103508:	e8 43 cd ff ff       	call   80100250 <brelse>
8010350d:	83 c4 10             	add    $0x10,%esp
}
80103510:	90                   	nop
80103511:	c9                   	leave  
80103512:	c3                   	ret    

80103513 <recover_from_log>:

static void
recover_from_log(void)
{
80103513:	55                   	push   %ebp
80103514:	89 e5                	mov    %esp,%ebp
80103516:	83 ec 08             	sub    $0x8,%esp
  read_head();
80103519:	e8 fe fe ff ff       	call   8010341c <read_head>
  install_trans(); // if committed, copy from log to disk
8010351e:	e8 41 fe ff ff       	call   80103364 <install_trans>
  log.lh.n = 0;
80103523:	c7 05 48 37 11 80 00 	movl   $0x0,0x80113748
8010352a:	00 00 00 
  write_head(); // clear the log
8010352d:	e8 5e ff ff ff       	call   80103490 <write_head>
}
80103532:	90                   	nop
80103533:	c9                   	leave  
80103534:	c3                   	ret    

80103535 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103535:	55                   	push   %ebp
80103536:	89 e5                	mov    %esp,%ebp
80103538:	83 ec 08             	sub    $0x8,%esp
  acquire(&log.lock);
8010353b:	83 ec 0c             	sub    $0xc,%esp
8010353e:	68 00 37 11 80       	push   $0x80113700
80103543:	e8 43 1a 00 00       	call   80104f8b <acquire>
80103548:	83 c4 10             	add    $0x10,%esp
  while(1){
    if(log.committing){
8010354b:	a1 40 37 11 80       	mov    0x80113740,%eax
80103550:	85 c0                	test   %eax,%eax
80103552:	74 17                	je     8010356b <begin_op+0x36>
      sleep(&log, &log.lock);
80103554:	83 ec 08             	sub    $0x8,%esp
80103557:	68 00 37 11 80       	push   $0x80113700
8010355c:	68 00 37 11 80       	push   $0x80113700
80103561:	e8 0c 16 00 00       	call   80104b72 <sleep>
80103566:	83 c4 10             	add    $0x10,%esp
80103569:	eb e0                	jmp    8010354b <begin_op+0x16>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
8010356b:	8b 0d 48 37 11 80    	mov    0x80113748,%ecx
80103571:	a1 3c 37 11 80       	mov    0x8011373c,%eax
80103576:	8d 50 01             	lea    0x1(%eax),%edx
80103579:	89 d0                	mov    %edx,%eax
8010357b:	c1 e0 02             	shl    $0x2,%eax
8010357e:	01 d0                	add    %edx,%eax
80103580:	01 c0                	add    %eax,%eax
80103582:	01 c8                	add    %ecx,%eax
80103584:	83 f8 1e             	cmp    $0x1e,%eax
80103587:	7e 17                	jle    801035a0 <begin_op+0x6b>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103589:	83 ec 08             	sub    $0x8,%esp
8010358c:	68 00 37 11 80       	push   $0x80113700
80103591:	68 00 37 11 80       	push   $0x80113700
80103596:	e8 d7 15 00 00       	call   80104b72 <sleep>
8010359b:	83 c4 10             	add    $0x10,%esp
8010359e:	eb ab                	jmp    8010354b <begin_op+0x16>
    } else {
      log.outstanding += 1;
801035a0:	a1 3c 37 11 80       	mov    0x8011373c,%eax
801035a5:	83 c0 01             	add    $0x1,%eax
801035a8:	a3 3c 37 11 80       	mov    %eax,0x8011373c
      release(&log.lock);
801035ad:	83 ec 0c             	sub    $0xc,%esp
801035b0:	68 00 37 11 80       	push   $0x80113700
801035b5:	e8 3f 1a 00 00       	call   80104ff9 <release>
801035ba:	83 c4 10             	add    $0x10,%esp
      break;
801035bd:	90                   	nop
    }
  }
}
801035be:	90                   	nop
801035bf:	c9                   	leave  
801035c0:	c3                   	ret    

801035c1 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
801035c1:	55                   	push   %ebp
801035c2:	89 e5                	mov    %esp,%ebp
801035c4:	83 ec 18             	sub    $0x18,%esp
  int do_commit = 0;
801035c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
801035ce:	83 ec 0c             	sub    $0xc,%esp
801035d1:	68 00 37 11 80       	push   $0x80113700
801035d6:	e8 b0 19 00 00       	call   80104f8b <acquire>
801035db:	83 c4 10             	add    $0x10,%esp
  log.outstanding -= 1;
801035de:	a1 3c 37 11 80       	mov    0x8011373c,%eax
801035e3:	83 e8 01             	sub    $0x1,%eax
801035e6:	a3 3c 37 11 80       	mov    %eax,0x8011373c
  if(log.committing)
801035eb:	a1 40 37 11 80       	mov    0x80113740,%eax
801035f0:	85 c0                	test   %eax,%eax
801035f2:	74 0d                	je     80103601 <end_op+0x40>
    panic("log.committing");
801035f4:	83 ec 0c             	sub    $0xc,%esp
801035f7:	68 95 85 10 80       	push   $0x80108595
801035fc:	e8 9f cf ff ff       	call   801005a0 <panic>
  if(log.outstanding == 0){
80103601:	a1 3c 37 11 80       	mov    0x8011373c,%eax
80103606:	85 c0                	test   %eax,%eax
80103608:	75 13                	jne    8010361d <end_op+0x5c>
    do_commit = 1;
8010360a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103611:	c7 05 40 37 11 80 01 	movl   $0x1,0x80113740
80103618:	00 00 00 
8010361b:	eb 10                	jmp    8010362d <end_op+0x6c>
  } else {
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
8010361d:	83 ec 0c             	sub    $0xc,%esp
80103620:	68 00 37 11 80       	push   $0x80113700
80103625:	e8 2e 16 00 00       	call   80104c58 <wakeup>
8010362a:	83 c4 10             	add    $0x10,%esp
  }
  release(&log.lock);
8010362d:	83 ec 0c             	sub    $0xc,%esp
80103630:	68 00 37 11 80       	push   $0x80113700
80103635:	e8 bf 19 00 00       	call   80104ff9 <release>
8010363a:	83 c4 10             	add    $0x10,%esp

  if(do_commit){
8010363d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103641:	74 3f                	je     80103682 <end_op+0xc1>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103643:	e8 f5 00 00 00       	call   8010373d <commit>
    acquire(&log.lock);
80103648:	83 ec 0c             	sub    $0xc,%esp
8010364b:	68 00 37 11 80       	push   $0x80113700
80103650:	e8 36 19 00 00       	call   80104f8b <acquire>
80103655:	83 c4 10             	add    $0x10,%esp
    log.committing = 0;
80103658:	c7 05 40 37 11 80 00 	movl   $0x0,0x80113740
8010365f:	00 00 00 
    wakeup(&log);
80103662:	83 ec 0c             	sub    $0xc,%esp
80103665:	68 00 37 11 80       	push   $0x80113700
8010366a:	e8 e9 15 00 00       	call   80104c58 <wakeup>
8010366f:	83 c4 10             	add    $0x10,%esp
    release(&log.lock);
80103672:	83 ec 0c             	sub    $0xc,%esp
80103675:	68 00 37 11 80       	push   $0x80113700
8010367a:	e8 7a 19 00 00       	call   80104ff9 <release>
8010367f:	83 c4 10             	add    $0x10,%esp
  }
}
80103682:	90                   	nop
80103683:	c9                   	leave  
80103684:	c3                   	ret    

80103685 <write_log>:

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80103685:	55                   	push   %ebp
80103686:	89 e5                	mov    %esp,%ebp
80103688:	83 ec 18             	sub    $0x18,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010368b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103692:	e9 95 00 00 00       	jmp    8010372c <write_log+0xa7>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103697:	8b 15 34 37 11 80    	mov    0x80113734,%edx
8010369d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036a0:	01 d0                	add    %edx,%eax
801036a2:	83 c0 01             	add    $0x1,%eax
801036a5:	89 c2                	mov    %eax,%edx
801036a7:	a1 44 37 11 80       	mov    0x80113744,%eax
801036ac:	83 ec 08             	sub    $0x8,%esp
801036af:	52                   	push   %edx
801036b0:	50                   	push   %eax
801036b1:	e8 18 cb ff ff       	call   801001ce <bread>
801036b6:	83 c4 10             	add    $0x10,%esp
801036b9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801036bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036bf:	83 c0 10             	add    $0x10,%eax
801036c2:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
801036c9:	89 c2                	mov    %eax,%edx
801036cb:	a1 44 37 11 80       	mov    0x80113744,%eax
801036d0:	83 ec 08             	sub    $0x8,%esp
801036d3:	52                   	push   %edx
801036d4:	50                   	push   %eax
801036d5:	e8 f4 ca ff ff       	call   801001ce <bread>
801036da:	83 c4 10             	add    $0x10,%esp
801036dd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
801036e0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801036e3:	8d 50 5c             	lea    0x5c(%eax),%edx
801036e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036e9:	83 c0 5c             	add    $0x5c,%eax
801036ec:	83 ec 04             	sub    $0x4,%esp
801036ef:	68 00 02 00 00       	push   $0x200
801036f4:	52                   	push   %edx
801036f5:	50                   	push   %eax
801036f6:	e8 c6 1b 00 00       	call   801052c1 <memmove>
801036fb:	83 c4 10             	add    $0x10,%esp
    bwrite(to);  // write the log
801036fe:	83 ec 0c             	sub    $0xc,%esp
80103701:	ff 75 f0             	pushl  -0x10(%ebp)
80103704:	e8 fe ca ff ff       	call   80100207 <bwrite>
80103709:	83 c4 10             	add    $0x10,%esp
    brelse(from);
8010370c:	83 ec 0c             	sub    $0xc,%esp
8010370f:	ff 75 ec             	pushl  -0x14(%ebp)
80103712:	e8 39 cb ff ff       	call   80100250 <brelse>
80103717:	83 c4 10             	add    $0x10,%esp
    brelse(to);
8010371a:	83 ec 0c             	sub    $0xc,%esp
8010371d:	ff 75 f0             	pushl  -0x10(%ebp)
80103720:	e8 2b cb ff ff       	call   80100250 <brelse>
80103725:	83 c4 10             	add    $0x10,%esp
static void
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103728:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010372c:	a1 48 37 11 80       	mov    0x80113748,%eax
80103731:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103734:	0f 8f 5d ff ff ff    	jg     80103697 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from);
    brelse(to);
  }
}
8010373a:	90                   	nop
8010373b:	c9                   	leave  
8010373c:	c3                   	ret    

8010373d <commit>:

static void
commit()
{
8010373d:	55                   	push   %ebp
8010373e:	89 e5                	mov    %esp,%ebp
80103740:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103743:	a1 48 37 11 80       	mov    0x80113748,%eax
80103748:	85 c0                	test   %eax,%eax
8010374a:	7e 1e                	jle    8010376a <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
8010374c:	e8 34 ff ff ff       	call   80103685 <write_log>
    write_head();    // Write header to disk -- the real commit
80103751:	e8 3a fd ff ff       	call   80103490 <write_head>
    install_trans(); // Now install writes to home locations
80103756:	e8 09 fc ff ff       	call   80103364 <install_trans>
    log.lh.n = 0;
8010375b:	c7 05 48 37 11 80 00 	movl   $0x0,0x80113748
80103762:	00 00 00 
    write_head();    // Erase the transaction from the log
80103765:	e8 26 fd ff ff       	call   80103490 <write_head>
  }
}
8010376a:	90                   	nop
8010376b:	c9                   	leave  
8010376c:	c3                   	ret    

8010376d <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010376d:	55                   	push   %ebp
8010376e:	89 e5                	mov    %esp,%ebp
80103770:	83 ec 18             	sub    $0x18,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103773:	a1 48 37 11 80       	mov    0x80113748,%eax
80103778:	83 f8 1d             	cmp    $0x1d,%eax
8010377b:	7f 12                	jg     8010378f <log_write+0x22>
8010377d:	a1 48 37 11 80       	mov    0x80113748,%eax
80103782:	8b 15 38 37 11 80    	mov    0x80113738,%edx
80103788:	83 ea 01             	sub    $0x1,%edx
8010378b:	39 d0                	cmp    %edx,%eax
8010378d:	7c 0d                	jl     8010379c <log_write+0x2f>
    panic("too big a transaction");
8010378f:	83 ec 0c             	sub    $0xc,%esp
80103792:	68 a4 85 10 80       	push   $0x801085a4
80103797:	e8 04 ce ff ff       	call   801005a0 <panic>
  if (log.outstanding < 1)
8010379c:	a1 3c 37 11 80       	mov    0x8011373c,%eax
801037a1:	85 c0                	test   %eax,%eax
801037a3:	7f 0d                	jg     801037b2 <log_write+0x45>
    panic("log_write outside of trans");
801037a5:	83 ec 0c             	sub    $0xc,%esp
801037a8:	68 ba 85 10 80       	push   $0x801085ba
801037ad:	e8 ee cd ff ff       	call   801005a0 <panic>

  acquire(&log.lock);
801037b2:	83 ec 0c             	sub    $0xc,%esp
801037b5:	68 00 37 11 80       	push   $0x80113700
801037ba:	e8 cc 17 00 00       	call   80104f8b <acquire>
801037bf:	83 c4 10             	add    $0x10,%esp
  for (i = 0; i < log.lh.n; i++) {
801037c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801037c9:	eb 1d                	jmp    801037e8 <log_write+0x7b>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
801037cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037ce:	83 c0 10             	add    $0x10,%eax
801037d1:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
801037d8:	89 c2                	mov    %eax,%edx
801037da:	8b 45 08             	mov    0x8(%ebp),%eax
801037dd:	8b 40 08             	mov    0x8(%eax),%eax
801037e0:	39 c2                	cmp    %eax,%edx
801037e2:	74 10                	je     801037f4 <log_write+0x87>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
801037e4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801037e8:	a1 48 37 11 80       	mov    0x80113748,%eax
801037ed:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037f0:	7f d9                	jg     801037cb <log_write+0x5e>
801037f2:	eb 01                	jmp    801037f5 <log_write+0x88>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
801037f4:	90                   	nop
  }
  log.lh.block[i] = b->blockno;
801037f5:	8b 45 08             	mov    0x8(%ebp),%eax
801037f8:	8b 40 08             	mov    0x8(%eax),%eax
801037fb:	89 c2                	mov    %eax,%edx
801037fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103800:	83 c0 10             	add    $0x10,%eax
80103803:	89 14 85 0c 37 11 80 	mov    %edx,-0x7feec8f4(,%eax,4)
  if (i == log.lh.n)
8010380a:	a1 48 37 11 80       	mov    0x80113748,%eax
8010380f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103812:	75 0d                	jne    80103821 <log_write+0xb4>
    log.lh.n++;
80103814:	a1 48 37 11 80       	mov    0x80113748,%eax
80103819:	83 c0 01             	add    $0x1,%eax
8010381c:	a3 48 37 11 80       	mov    %eax,0x80113748
  b->flags |= B_DIRTY; // prevent eviction
80103821:	8b 45 08             	mov    0x8(%ebp),%eax
80103824:	8b 00                	mov    (%eax),%eax
80103826:	83 c8 04             	or     $0x4,%eax
80103829:	89 c2                	mov    %eax,%edx
8010382b:	8b 45 08             	mov    0x8(%ebp),%eax
8010382e:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103830:	83 ec 0c             	sub    $0xc,%esp
80103833:	68 00 37 11 80       	push   $0x80113700
80103838:	e8 bc 17 00 00       	call   80104ff9 <release>
8010383d:	83 c4 10             	add    $0x10,%esp
}
80103840:	90                   	nop
80103841:	c9                   	leave  
80103842:	c3                   	ret    

80103843 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103843:	55                   	push   %ebp
80103844:	89 e5                	mov    %esp,%ebp
80103846:	83 ec 10             	sub    $0x10,%esp
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103849:	8b 55 08             	mov    0x8(%ebp),%edx
8010384c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010384f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103852:	f0 87 02             	lock xchg %eax,(%edx)
80103855:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103858:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010385b:	c9                   	leave  
8010385c:	c3                   	ret    

8010385d <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010385d:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80103861:	83 e4 f0             	and    $0xfffffff0,%esp
80103864:	ff 71 fc             	pushl  -0x4(%ecx)
80103867:	55                   	push   %ebp
80103868:	89 e5                	mov    %esp,%ebp
8010386a:	51                   	push   %ecx
8010386b:	83 ec 04             	sub    $0x4,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
8010386e:	83 ec 08             	sub    $0x8,%esp
80103871:	68 00 00 40 80       	push   $0x80400000
80103876:	68 28 65 11 80       	push   $0x80116528
8010387b:	e8 e1 f2 ff ff       	call   80102b61 <kinit1>
80103880:	83 c4 10             	add    $0x10,%esp
  kvmalloc();      // kernel page table
80103883:	e8 e8 42 00 00       	call   80107b70 <kvmalloc>
  mpinit();        // detect other processors
80103888:	e8 ba 03 00 00       	call   80103c47 <mpinit>
  lapicinit();     // interrupt controller
8010388d:	e8 3b f6 ff ff       	call   80102ecd <lapicinit>
  seginit();       // segment descriptors
80103892:	e8 c4 3d 00 00       	call   8010765b <seginit>
  picinit();       // disable pic
80103897:	e8 fc 04 00 00       	call   80103d98 <picinit>
  ioapicinit();    // another interrupt controller
8010389c:	e8 dc f1 ff ff       	call   80102a7d <ioapicinit>
  consoleinit();   // console hardware
801038a1:	e8 a5 d2 ff ff       	call   80100b4b <consoleinit>
  uartinit();      // serial port
801038a6:	e8 49 31 00 00       	call   801069f4 <uartinit>
  pinit();         // process table
801038ab:	e8 21 09 00 00       	call   801041d1 <pinit>
  tvinit();        // trap vectors
801038b0:	e8 21 2d 00 00       	call   801065d6 <tvinit>
  binit();         // buffer cache
801038b5:	e8 7a c7 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801038ba:	e8 16 d7 ff ff       	call   80100fd5 <fileinit>
  ideinit();       // disk 
801038bf:	e8 90 ed ff ff       	call   80102654 <ideinit>
  startothers();   // start other processors
801038c4:	e8 80 00 00 00       	call   80103949 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801038c9:	83 ec 08             	sub    $0x8,%esp
801038cc:	68 00 00 00 8e       	push   $0x8e000000
801038d1:	68 00 00 40 80       	push   $0x80400000
801038d6:	e8 bf f2 ff ff       	call   80102b9a <kinit2>
801038db:	83 c4 10             	add    $0x10,%esp
  userinit();      // first user process
801038de:	e8 09 0b 00 00       	call   801043ec <userinit>
  mpmain();        // finish this processor's setup
801038e3:	e8 1a 00 00 00       	call   80103902 <mpmain>

801038e8 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801038e8:	55                   	push   %ebp
801038e9:	89 e5                	mov    %esp,%ebp
801038eb:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
801038ee:	e8 95 42 00 00       	call   80107b88 <switchkvm>
  seginit();
801038f3:	e8 63 3d 00 00       	call   8010765b <seginit>
  lapicinit();
801038f8:	e8 d0 f5 ff ff       	call   80102ecd <lapicinit>
  mpmain();
801038fd:	e8 00 00 00 00       	call   80103902 <mpmain>

80103902 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103902:	55                   	push   %ebp
80103903:	89 e5                	mov    %esp,%ebp
80103905:	53                   	push   %ebx
80103906:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80103909:	e8 e1 08 00 00       	call   801041ef <cpuid>
8010390e:	89 c3                	mov    %eax,%ebx
80103910:	e8 da 08 00 00       	call   801041ef <cpuid>
80103915:	83 ec 04             	sub    $0x4,%esp
80103918:	53                   	push   %ebx
80103919:	50                   	push   %eax
8010391a:	68 d5 85 10 80       	push   $0x801085d5
8010391f:	e8 dc ca ff ff       	call   80100400 <cprintf>
80103924:	83 c4 10             	add    $0x10,%esp
  idtinit();       // load idt register
80103927:	e8 20 2e 00 00       	call   8010674c <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
8010392c:	e8 df 08 00 00       	call   80104210 <mycpu>
80103931:	05 a0 00 00 00       	add    $0xa0,%eax
80103936:	83 ec 08             	sub    $0x8,%esp
80103939:	6a 01                	push   $0x1
8010393b:	50                   	push   %eax
8010393c:	e8 02 ff ff ff       	call   80103843 <xchg>
80103941:	83 c4 10             	add    $0x10,%esp
  scheduler();     // start running processes
80103944:	e8 36 10 00 00       	call   8010497f <scheduler>

80103949 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103949:	55                   	push   %ebp
8010394a:	89 e5                	mov    %esp,%ebp
8010394c:	83 ec 18             	sub    $0x18,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
8010394f:	c7 45 f0 00 70 00 80 	movl   $0x80007000,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103956:	b8 8a 00 00 00       	mov    $0x8a,%eax
8010395b:	83 ec 04             	sub    $0x4,%esp
8010395e:	50                   	push   %eax
8010395f:	68 ec b4 10 80       	push   $0x8010b4ec
80103964:	ff 75 f0             	pushl  -0x10(%ebp)
80103967:	e8 55 19 00 00       	call   801052c1 <memmove>
8010396c:	83 c4 10             	add    $0x10,%esp

  for(c = cpus; c < cpus+ncpu; c++){
8010396f:	c7 45 f4 00 38 11 80 	movl   $0x80113800,-0xc(%ebp)
80103976:	eb 79                	jmp    801039f1 <startothers+0xa8>
    if(c == mycpu())  // We've started already.
80103978:	e8 93 08 00 00       	call   80104210 <mycpu>
8010397d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103980:	74 67                	je     801039e9 <startothers+0xa0>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103982:	e8 0e f3 ff ff       	call   80102c95 <kalloc>
80103987:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010398a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010398d:	83 e8 04             	sub    $0x4,%eax
80103990:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103993:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103999:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
8010399b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010399e:	83 e8 08             	sub    $0x8,%eax
801039a1:	c7 00 e8 38 10 80    	movl   $0x801038e8,(%eax)
    *(int**)(code-12) = (void *) V2P(entrypgdir);
801039a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039aa:	83 e8 0c             	sub    $0xc,%eax
801039ad:	ba 00 a0 10 80       	mov    $0x8010a000,%edx
801039b2:	81 c2 00 00 00 80    	add    $0x80000000,%edx
801039b8:	89 10                	mov    %edx,(%eax)

    lapicstartap(c->apicid, V2P(code));
801039ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039bd:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
801039c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039c6:	0f b6 00             	movzbl (%eax),%eax
801039c9:	0f b6 c0             	movzbl %al,%eax
801039cc:	83 ec 08             	sub    $0x8,%esp
801039cf:	52                   	push   %edx
801039d0:	50                   	push   %eax
801039d1:	e8 58 f6 ff ff       	call   8010302e <lapicstartap>
801039d6:	83 c4 10             	add    $0x10,%esp

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801039d9:	90                   	nop
801039da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039dd:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
801039e3:	85 c0                	test   %eax,%eax
801039e5:	74 f3                	je     801039da <startothers+0x91>
801039e7:	eb 01                	jmp    801039ea <startothers+0xa1>
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == mycpu())  // We've started already.
      continue;
801039e9:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
801039ea:	81 45 f4 b0 00 00 00 	addl   $0xb0,-0xc(%ebp)
801039f1:	a1 80 3d 11 80       	mov    0x80113d80,%eax
801039f6:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
801039fc:	05 00 38 11 80       	add    $0x80113800,%eax
80103a01:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a04:	0f 87 6e ff ff ff    	ja     80103978 <startothers+0x2f>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103a0a:	90                   	nop
80103a0b:	c9                   	leave  
80103a0c:	c3                   	ret    

80103a0d <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103a0d:	55                   	push   %ebp
80103a0e:	89 e5                	mov    %esp,%ebp
80103a10:	83 ec 14             	sub    $0x14,%esp
80103a13:	8b 45 08             	mov    0x8(%ebp),%eax
80103a16:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103a1a:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103a1e:	89 c2                	mov    %eax,%edx
80103a20:	ec                   	in     (%dx),%al
80103a21:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103a24:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103a28:	c9                   	leave  
80103a29:	c3                   	ret    

80103a2a <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103a2a:	55                   	push   %ebp
80103a2b:	89 e5                	mov    %esp,%ebp
80103a2d:	83 ec 08             	sub    $0x8,%esp
80103a30:	8b 55 08             	mov    0x8(%ebp),%edx
80103a33:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a36:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103a3a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103a3d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103a41:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103a45:	ee                   	out    %al,(%dx)
}
80103a46:	90                   	nop
80103a47:	c9                   	leave  
80103a48:	c3                   	ret    

80103a49 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80103a49:	55                   	push   %ebp
80103a4a:	89 e5                	mov    %esp,%ebp
80103a4c:	83 ec 10             	sub    $0x10,%esp
  int i, sum;

  sum = 0;
80103a4f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103a56:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103a5d:	eb 15                	jmp    80103a74 <sum+0x2b>
    sum += addr[i];
80103a5f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103a62:	8b 45 08             	mov    0x8(%ebp),%eax
80103a65:	01 d0                	add    %edx,%eax
80103a67:	0f b6 00             	movzbl (%eax),%eax
80103a6a:	0f b6 c0             	movzbl %al,%eax
80103a6d:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;

  sum = 0;
  for(i=0; i<len; i++)
80103a70:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103a74:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103a77:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103a7a:	7c e3                	jl     80103a5f <sum+0x16>
    sum += addr[i];
  return sum;
80103a7c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103a7f:	c9                   	leave  
80103a80:	c3                   	ret    

80103a81 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103a81:	55                   	push   %ebp
80103a82:	89 e5                	mov    %esp,%ebp
80103a84:	83 ec 18             	sub    $0x18,%esp
  uchar *e, *p, *addr;

  addr = P2V(a);
80103a87:	8b 45 08             	mov    0x8(%ebp),%eax
80103a8a:	05 00 00 00 80       	add    $0x80000000,%eax
80103a8f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103a92:	8b 55 0c             	mov    0xc(%ebp),%edx
80103a95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a98:	01 d0                	add    %edx,%eax
80103a9a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103a9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103aa0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103aa3:	eb 36                	jmp    80103adb <mpsearch1+0x5a>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103aa5:	83 ec 04             	sub    $0x4,%esp
80103aa8:	6a 04                	push   $0x4
80103aaa:	68 ec 85 10 80       	push   $0x801085ec
80103aaf:	ff 75 f4             	pushl  -0xc(%ebp)
80103ab2:	e8 b2 17 00 00       	call   80105269 <memcmp>
80103ab7:	83 c4 10             	add    $0x10,%esp
80103aba:	85 c0                	test   %eax,%eax
80103abc:	75 19                	jne    80103ad7 <mpsearch1+0x56>
80103abe:	83 ec 08             	sub    $0x8,%esp
80103ac1:	6a 10                	push   $0x10
80103ac3:	ff 75 f4             	pushl  -0xc(%ebp)
80103ac6:	e8 7e ff ff ff       	call   80103a49 <sum>
80103acb:	83 c4 10             	add    $0x10,%esp
80103ace:	84 c0                	test   %al,%al
80103ad0:	75 05                	jne    80103ad7 <mpsearch1+0x56>
      return (struct mp*)p;
80103ad2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ad5:	eb 11                	jmp    80103ae8 <mpsearch1+0x67>
{
  uchar *e, *p, *addr;

  addr = P2V(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103ad7:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103adb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ade:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103ae1:	72 c2                	jb     80103aa5 <mpsearch1+0x24>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103ae3:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103ae8:	c9                   	leave  
80103ae9:	c3                   	ret    

80103aea <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103aea:	55                   	push   %ebp
80103aeb:	89 e5                	mov    %esp,%ebp
80103aed:	83 ec 18             	sub    $0x18,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103af0:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103afa:	83 c0 0f             	add    $0xf,%eax
80103afd:	0f b6 00             	movzbl (%eax),%eax
80103b00:	0f b6 c0             	movzbl %al,%eax
80103b03:	c1 e0 08             	shl    $0x8,%eax
80103b06:	89 c2                	mov    %eax,%edx
80103b08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b0b:	83 c0 0e             	add    $0xe,%eax
80103b0e:	0f b6 00             	movzbl (%eax),%eax
80103b11:	0f b6 c0             	movzbl %al,%eax
80103b14:	09 d0                	or     %edx,%eax
80103b16:	c1 e0 04             	shl    $0x4,%eax
80103b19:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103b1c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103b20:	74 21                	je     80103b43 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103b22:	83 ec 08             	sub    $0x8,%esp
80103b25:	68 00 04 00 00       	push   $0x400
80103b2a:	ff 75 f0             	pushl  -0x10(%ebp)
80103b2d:	e8 4f ff ff ff       	call   80103a81 <mpsearch1>
80103b32:	83 c4 10             	add    $0x10,%esp
80103b35:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b38:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103b3c:	74 51                	je     80103b8f <mpsearch+0xa5>
      return mp;
80103b3e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b41:	eb 61                	jmp    80103ba4 <mpsearch+0xba>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103b43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b46:	83 c0 14             	add    $0x14,%eax
80103b49:	0f b6 00             	movzbl (%eax),%eax
80103b4c:	0f b6 c0             	movzbl %al,%eax
80103b4f:	c1 e0 08             	shl    $0x8,%eax
80103b52:	89 c2                	mov    %eax,%edx
80103b54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b57:	83 c0 13             	add    $0x13,%eax
80103b5a:	0f b6 00             	movzbl (%eax),%eax
80103b5d:	0f b6 c0             	movzbl %al,%eax
80103b60:	09 d0                	or     %edx,%eax
80103b62:	c1 e0 0a             	shl    $0xa,%eax
80103b65:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103b68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b6b:	2d 00 04 00 00       	sub    $0x400,%eax
80103b70:	83 ec 08             	sub    $0x8,%esp
80103b73:	68 00 04 00 00       	push   $0x400
80103b78:	50                   	push   %eax
80103b79:	e8 03 ff ff ff       	call   80103a81 <mpsearch1>
80103b7e:	83 c4 10             	add    $0x10,%esp
80103b81:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b84:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103b88:	74 05                	je     80103b8f <mpsearch+0xa5>
      return mp;
80103b8a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b8d:	eb 15                	jmp    80103ba4 <mpsearch+0xba>
  }
  return mpsearch1(0xF0000, 0x10000);
80103b8f:	83 ec 08             	sub    $0x8,%esp
80103b92:	68 00 00 01 00       	push   $0x10000
80103b97:	68 00 00 0f 00       	push   $0xf0000
80103b9c:	e8 e0 fe ff ff       	call   80103a81 <mpsearch1>
80103ba1:	83 c4 10             	add    $0x10,%esp
}
80103ba4:	c9                   	leave  
80103ba5:	c3                   	ret    

80103ba6 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103ba6:	55                   	push   %ebp
80103ba7:	89 e5                	mov    %esp,%ebp
80103ba9:	83 ec 18             	sub    $0x18,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103bac:	e8 39 ff ff ff       	call   80103aea <mpsearch>
80103bb1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103bb4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103bb8:	74 0a                	je     80103bc4 <mpconfig+0x1e>
80103bba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bbd:	8b 40 04             	mov    0x4(%eax),%eax
80103bc0:	85 c0                	test   %eax,%eax
80103bc2:	75 07                	jne    80103bcb <mpconfig+0x25>
    return 0;
80103bc4:	b8 00 00 00 00       	mov    $0x0,%eax
80103bc9:	eb 7a                	jmp    80103c45 <mpconfig+0x9f>
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80103bcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bce:	8b 40 04             	mov    0x4(%eax),%eax
80103bd1:	05 00 00 00 80       	add    $0x80000000,%eax
80103bd6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103bd9:	83 ec 04             	sub    $0x4,%esp
80103bdc:	6a 04                	push   $0x4
80103bde:	68 f1 85 10 80       	push   $0x801085f1
80103be3:	ff 75 f0             	pushl  -0x10(%ebp)
80103be6:	e8 7e 16 00 00       	call   80105269 <memcmp>
80103beb:	83 c4 10             	add    $0x10,%esp
80103bee:	85 c0                	test   %eax,%eax
80103bf0:	74 07                	je     80103bf9 <mpconfig+0x53>
    return 0;
80103bf2:	b8 00 00 00 00       	mov    $0x0,%eax
80103bf7:	eb 4c                	jmp    80103c45 <mpconfig+0x9f>
  if(conf->version != 1 && conf->version != 4)
80103bf9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bfc:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103c00:	3c 01                	cmp    $0x1,%al
80103c02:	74 12                	je     80103c16 <mpconfig+0x70>
80103c04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c07:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103c0b:	3c 04                	cmp    $0x4,%al
80103c0d:	74 07                	je     80103c16 <mpconfig+0x70>
    return 0;
80103c0f:	b8 00 00 00 00       	mov    $0x0,%eax
80103c14:	eb 2f                	jmp    80103c45 <mpconfig+0x9f>
  if(sum((uchar*)conf, conf->length) != 0)
80103c16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c19:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103c1d:	0f b7 c0             	movzwl %ax,%eax
80103c20:	83 ec 08             	sub    $0x8,%esp
80103c23:	50                   	push   %eax
80103c24:	ff 75 f0             	pushl  -0x10(%ebp)
80103c27:	e8 1d fe ff ff       	call   80103a49 <sum>
80103c2c:	83 c4 10             	add    $0x10,%esp
80103c2f:	84 c0                	test   %al,%al
80103c31:	74 07                	je     80103c3a <mpconfig+0x94>
    return 0;
80103c33:	b8 00 00 00 00       	mov    $0x0,%eax
80103c38:	eb 0b                	jmp    80103c45 <mpconfig+0x9f>
  *pmp = mp;
80103c3a:	8b 45 08             	mov    0x8(%ebp),%eax
80103c3d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103c40:	89 10                	mov    %edx,(%eax)
  return conf;
80103c42:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103c45:	c9                   	leave  
80103c46:	c3                   	ret    

80103c47 <mpinit>:

void
mpinit(void)
{
80103c47:	55                   	push   %ebp
80103c48:	89 e5                	mov    %esp,%ebp
80103c4a:	83 ec 28             	sub    $0x28,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80103c4d:	83 ec 0c             	sub    $0xc,%esp
80103c50:	8d 45 dc             	lea    -0x24(%ebp),%eax
80103c53:	50                   	push   %eax
80103c54:	e8 4d ff ff ff       	call   80103ba6 <mpconfig>
80103c59:	83 c4 10             	add    $0x10,%esp
80103c5c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c5f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103c63:	75 0d                	jne    80103c72 <mpinit+0x2b>
    panic("Expect to run on an SMP");
80103c65:	83 ec 0c             	sub    $0xc,%esp
80103c68:	68 f6 85 10 80       	push   $0x801085f6
80103c6d:	e8 2e c9 ff ff       	call   801005a0 <panic>
  ismp = 1;
80103c72:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
  lapic = (uint*)conf->lapicaddr;
80103c79:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c7c:	8b 40 24             	mov    0x24(%eax),%eax
80103c7f:	a3 fc 36 11 80       	mov    %eax,0x801136fc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103c84:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c87:	83 c0 2c             	add    $0x2c,%eax
80103c8a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103c8d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c90:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103c94:	0f b7 d0             	movzwl %ax,%edx
80103c97:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c9a:	01 d0                	add    %edx,%eax
80103c9c:	89 45 e8             	mov    %eax,-0x18(%ebp)
80103c9f:	eb 7b                	jmp    80103d1c <mpinit+0xd5>
    switch(*p){
80103ca1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ca4:	0f b6 00             	movzbl (%eax),%eax
80103ca7:	0f b6 c0             	movzbl %al,%eax
80103caa:	83 f8 04             	cmp    $0x4,%eax
80103cad:	77 65                	ja     80103d14 <mpinit+0xcd>
80103caf:	8b 04 85 30 86 10 80 	mov    -0x7fef79d0(,%eax,4),%eax
80103cb6:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103cb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cbb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(ncpu < NCPU) {
80103cbe:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80103cc3:	83 f8 07             	cmp    $0x7,%eax
80103cc6:	7f 28                	jg     80103cf0 <mpinit+0xa9>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80103cc8:	8b 15 80 3d 11 80    	mov    0x80113d80,%edx
80103cce:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103cd1:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103cd5:	69 d2 b0 00 00 00    	imul   $0xb0,%edx,%edx
80103cdb:	81 c2 00 38 11 80    	add    $0x80113800,%edx
80103ce1:	88 02                	mov    %al,(%edx)
        ncpu++;
80103ce3:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80103ce8:	83 c0 01             	add    $0x1,%eax
80103ceb:	a3 80 3d 11 80       	mov    %eax,0x80113d80
      }
      p += sizeof(struct mpproc);
80103cf0:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103cf4:	eb 26                	jmp    80103d1c <mpinit+0xd5>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103cf6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cf9:	89 45 e0             	mov    %eax,-0x20(%ebp)
      ioapicid = ioapic->apicno;
80103cfc:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103cff:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103d03:	a2 e0 37 11 80       	mov    %al,0x801137e0
      p += sizeof(struct mpioapic);
80103d08:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103d0c:	eb 0e                	jmp    80103d1c <mpinit+0xd5>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103d0e:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103d12:	eb 08                	jmp    80103d1c <mpinit+0xd5>
    default:
      ismp = 0;
80103d14:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      break;
80103d1b:	90                   	nop

  if((conf = mpconfig(&mp)) == 0)
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103d1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d1f:	3b 45 e8             	cmp    -0x18(%ebp),%eax
80103d22:	0f 82 79 ff ff ff    	jb     80103ca1 <mpinit+0x5a>
    default:
      ismp = 0;
      break;
    }
  }
  if(!ismp)
80103d28:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103d2c:	75 0d                	jne    80103d3b <mpinit+0xf4>
    panic("Didn't find a suitable machine");
80103d2e:	83 ec 0c             	sub    $0xc,%esp
80103d31:	68 10 86 10 80       	push   $0x80108610
80103d36:	e8 65 c8 ff ff       	call   801005a0 <panic>

  if(mp->imcrp){
80103d3b:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103d3e:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103d42:	84 c0                	test   %al,%al
80103d44:	74 30                	je     80103d76 <mpinit+0x12f>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103d46:	83 ec 08             	sub    $0x8,%esp
80103d49:	6a 70                	push   $0x70
80103d4b:	6a 22                	push   $0x22
80103d4d:	e8 d8 fc ff ff       	call   80103a2a <outb>
80103d52:	83 c4 10             	add    $0x10,%esp
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103d55:	83 ec 0c             	sub    $0xc,%esp
80103d58:	6a 23                	push   $0x23
80103d5a:	e8 ae fc ff ff       	call   80103a0d <inb>
80103d5f:	83 c4 10             	add    $0x10,%esp
80103d62:	83 c8 01             	or     $0x1,%eax
80103d65:	0f b6 c0             	movzbl %al,%eax
80103d68:	83 ec 08             	sub    $0x8,%esp
80103d6b:	50                   	push   %eax
80103d6c:	6a 23                	push   $0x23
80103d6e:	e8 b7 fc ff ff       	call   80103a2a <outb>
80103d73:	83 c4 10             	add    $0x10,%esp
  }
}
80103d76:	90                   	nop
80103d77:	c9                   	leave  
80103d78:	c3                   	ret    

80103d79 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103d79:	55                   	push   %ebp
80103d7a:	89 e5                	mov    %esp,%ebp
80103d7c:	83 ec 08             	sub    $0x8,%esp
80103d7f:	8b 55 08             	mov    0x8(%ebp),%edx
80103d82:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d85:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103d89:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103d8c:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103d90:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103d94:	ee                   	out    %al,(%dx)
}
80103d95:	90                   	nop
80103d96:	c9                   	leave  
80103d97:	c3                   	ret    

80103d98 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80103d98:	55                   	push   %ebp
80103d99:	89 e5                	mov    %esp,%ebp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103d9b:	68 ff 00 00 00       	push   $0xff
80103da0:	6a 21                	push   $0x21
80103da2:	e8 d2 ff ff ff       	call   80103d79 <outb>
80103da7:	83 c4 08             	add    $0x8,%esp
  outb(IO_PIC2+1, 0xFF);
80103daa:	68 ff 00 00 00       	push   $0xff
80103daf:	68 a1 00 00 00       	push   $0xa1
80103db4:	e8 c0 ff ff ff       	call   80103d79 <outb>
80103db9:	83 c4 08             	add    $0x8,%esp
}
80103dbc:	90                   	nop
80103dbd:	c9                   	leave  
80103dbe:	c3                   	ret    

80103dbf <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103dbf:	55                   	push   %ebp
80103dc0:	89 e5                	mov    %esp,%ebp
80103dc2:	83 ec 18             	sub    $0x18,%esp
  struct pipe *p;

  p = 0;
80103dc5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103dcc:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dcf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103dd5:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dd8:	8b 10                	mov    (%eax),%edx
80103dda:	8b 45 08             	mov    0x8(%ebp),%eax
80103ddd:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103ddf:	e8 0f d2 ff ff       	call   80100ff3 <filealloc>
80103de4:	89 c2                	mov    %eax,%edx
80103de6:	8b 45 08             	mov    0x8(%ebp),%eax
80103de9:	89 10                	mov    %edx,(%eax)
80103deb:	8b 45 08             	mov    0x8(%ebp),%eax
80103dee:	8b 00                	mov    (%eax),%eax
80103df0:	85 c0                	test   %eax,%eax
80103df2:	0f 84 cb 00 00 00    	je     80103ec3 <pipealloc+0x104>
80103df8:	e8 f6 d1 ff ff       	call   80100ff3 <filealloc>
80103dfd:	89 c2                	mov    %eax,%edx
80103dff:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e02:	89 10                	mov    %edx,(%eax)
80103e04:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e07:	8b 00                	mov    (%eax),%eax
80103e09:	85 c0                	test   %eax,%eax
80103e0b:	0f 84 b2 00 00 00    	je     80103ec3 <pipealloc+0x104>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103e11:	e8 7f ee ff ff       	call   80102c95 <kalloc>
80103e16:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103e19:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103e1d:	0f 84 9f 00 00 00    	je     80103ec2 <pipealloc+0x103>
    goto bad;
  p->readopen = 1;
80103e23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e26:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103e2d:	00 00 00 
  p->writeopen = 1;
80103e30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e33:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103e3a:	00 00 00 
  p->nwrite = 0;
80103e3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e40:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103e47:	00 00 00 
  p->nread = 0;
80103e4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e4d:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103e54:	00 00 00 
  initlock(&p->lock, "pipe");
80103e57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e5a:	83 ec 08             	sub    $0x8,%esp
80103e5d:	68 44 86 10 80       	push   $0x80108644
80103e62:	50                   	push   %eax
80103e63:	e8 01 11 00 00       	call   80104f69 <initlock>
80103e68:	83 c4 10             	add    $0x10,%esp
  (*f0)->type = FD_PIPE;
80103e6b:	8b 45 08             	mov    0x8(%ebp),%eax
80103e6e:	8b 00                	mov    (%eax),%eax
80103e70:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103e76:	8b 45 08             	mov    0x8(%ebp),%eax
80103e79:	8b 00                	mov    (%eax),%eax
80103e7b:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103e7f:	8b 45 08             	mov    0x8(%ebp),%eax
80103e82:	8b 00                	mov    (%eax),%eax
80103e84:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103e88:	8b 45 08             	mov    0x8(%ebp),%eax
80103e8b:	8b 00                	mov    (%eax),%eax
80103e8d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e90:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103e93:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e96:	8b 00                	mov    (%eax),%eax
80103e98:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103e9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ea1:	8b 00                	mov    (%eax),%eax
80103ea3:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103ea7:	8b 45 0c             	mov    0xc(%ebp),%eax
80103eaa:	8b 00                	mov    (%eax),%eax
80103eac:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103eb0:	8b 45 0c             	mov    0xc(%ebp),%eax
80103eb3:	8b 00                	mov    (%eax),%eax
80103eb5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103eb8:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103ebb:	b8 00 00 00 00       	mov    $0x0,%eax
80103ec0:	eb 4e                	jmp    80103f10 <pipealloc+0x151>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103ec2:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103ec3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103ec7:	74 0e                	je     80103ed7 <pipealloc+0x118>
    kfree((char*)p);
80103ec9:	83 ec 0c             	sub    $0xc,%esp
80103ecc:	ff 75 f4             	pushl  -0xc(%ebp)
80103ecf:	e8 27 ed ff ff       	call   80102bfb <kfree>
80103ed4:	83 c4 10             	add    $0x10,%esp
  if(*f0)
80103ed7:	8b 45 08             	mov    0x8(%ebp),%eax
80103eda:	8b 00                	mov    (%eax),%eax
80103edc:	85 c0                	test   %eax,%eax
80103ede:	74 11                	je     80103ef1 <pipealloc+0x132>
    fileclose(*f0);
80103ee0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ee3:	8b 00                	mov    (%eax),%eax
80103ee5:	83 ec 0c             	sub    $0xc,%esp
80103ee8:	50                   	push   %eax
80103ee9:	e8 c3 d1 ff ff       	call   801010b1 <fileclose>
80103eee:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80103ef1:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ef4:	8b 00                	mov    (%eax),%eax
80103ef6:	85 c0                	test   %eax,%eax
80103ef8:	74 11                	je     80103f0b <pipealloc+0x14c>
    fileclose(*f1);
80103efa:	8b 45 0c             	mov    0xc(%ebp),%eax
80103efd:	8b 00                	mov    (%eax),%eax
80103eff:	83 ec 0c             	sub    $0xc,%esp
80103f02:	50                   	push   %eax
80103f03:	e8 a9 d1 ff ff       	call   801010b1 <fileclose>
80103f08:	83 c4 10             	add    $0x10,%esp
  return -1;
80103f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103f10:	c9                   	leave  
80103f11:	c3                   	ret    

80103f12 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103f12:	55                   	push   %ebp
80103f13:	89 e5                	mov    %esp,%ebp
80103f15:	83 ec 08             	sub    $0x8,%esp
  acquire(&p->lock);
80103f18:	8b 45 08             	mov    0x8(%ebp),%eax
80103f1b:	83 ec 0c             	sub    $0xc,%esp
80103f1e:	50                   	push   %eax
80103f1f:	e8 67 10 00 00       	call   80104f8b <acquire>
80103f24:	83 c4 10             	add    $0x10,%esp
  if(writable){
80103f27:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103f2b:	74 23                	je     80103f50 <pipeclose+0x3e>
    p->writeopen = 0;
80103f2d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f30:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103f37:	00 00 00 
    wakeup(&p->nread);
80103f3a:	8b 45 08             	mov    0x8(%ebp),%eax
80103f3d:	05 34 02 00 00       	add    $0x234,%eax
80103f42:	83 ec 0c             	sub    $0xc,%esp
80103f45:	50                   	push   %eax
80103f46:	e8 0d 0d 00 00       	call   80104c58 <wakeup>
80103f4b:	83 c4 10             	add    $0x10,%esp
80103f4e:	eb 21                	jmp    80103f71 <pipeclose+0x5f>
  } else {
    p->readopen = 0;
80103f50:	8b 45 08             	mov    0x8(%ebp),%eax
80103f53:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103f5a:	00 00 00 
    wakeup(&p->nwrite);
80103f5d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f60:	05 38 02 00 00       	add    $0x238,%eax
80103f65:	83 ec 0c             	sub    $0xc,%esp
80103f68:	50                   	push   %eax
80103f69:	e8 ea 0c 00 00       	call   80104c58 <wakeup>
80103f6e:	83 c4 10             	add    $0x10,%esp
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103f71:	8b 45 08             	mov    0x8(%ebp),%eax
80103f74:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103f7a:	85 c0                	test   %eax,%eax
80103f7c:	75 2c                	jne    80103faa <pipeclose+0x98>
80103f7e:	8b 45 08             	mov    0x8(%ebp),%eax
80103f81:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103f87:	85 c0                	test   %eax,%eax
80103f89:	75 1f                	jne    80103faa <pipeclose+0x98>
    release(&p->lock);
80103f8b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f8e:	83 ec 0c             	sub    $0xc,%esp
80103f91:	50                   	push   %eax
80103f92:	e8 62 10 00 00       	call   80104ff9 <release>
80103f97:	83 c4 10             	add    $0x10,%esp
    kfree((char*)p);
80103f9a:	83 ec 0c             	sub    $0xc,%esp
80103f9d:	ff 75 08             	pushl  0x8(%ebp)
80103fa0:	e8 56 ec ff ff       	call   80102bfb <kfree>
80103fa5:	83 c4 10             	add    $0x10,%esp
80103fa8:	eb 0f                	jmp    80103fb9 <pipeclose+0xa7>
  } else
    release(&p->lock);
80103faa:	8b 45 08             	mov    0x8(%ebp),%eax
80103fad:	83 ec 0c             	sub    $0xc,%esp
80103fb0:	50                   	push   %eax
80103fb1:	e8 43 10 00 00       	call   80104ff9 <release>
80103fb6:	83 c4 10             	add    $0x10,%esp
}
80103fb9:	90                   	nop
80103fba:	c9                   	leave  
80103fbb:	c3                   	ret    

80103fbc <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103fbc:	55                   	push   %ebp
80103fbd:	89 e5                	mov    %esp,%ebp
80103fbf:	83 ec 18             	sub    $0x18,%esp
  int i;

  acquire(&p->lock);
80103fc2:	8b 45 08             	mov    0x8(%ebp),%eax
80103fc5:	83 ec 0c             	sub    $0xc,%esp
80103fc8:	50                   	push   %eax
80103fc9:	e8 bd 0f 00 00       	call   80104f8b <acquire>
80103fce:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < n; i++){
80103fd1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103fd8:	e9 ac 00 00 00       	jmp    80104089 <pipewrite+0xcd>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || myproc()->killed){
80103fdd:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe0:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103fe6:	85 c0                	test   %eax,%eax
80103fe8:	74 0c                	je     80103ff6 <pipewrite+0x3a>
80103fea:	e8 99 02 00 00       	call   80104288 <myproc>
80103fef:	8b 40 24             	mov    0x24(%eax),%eax
80103ff2:	85 c0                	test   %eax,%eax
80103ff4:	74 19                	je     8010400f <pipewrite+0x53>
        release(&p->lock);
80103ff6:	8b 45 08             	mov    0x8(%ebp),%eax
80103ff9:	83 ec 0c             	sub    $0xc,%esp
80103ffc:	50                   	push   %eax
80103ffd:	e8 f7 0f 00 00       	call   80104ff9 <release>
80104002:	83 c4 10             	add    $0x10,%esp
        return -1;
80104005:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010400a:	e9 a8 00 00 00       	jmp    801040b7 <pipewrite+0xfb>
      }
      wakeup(&p->nread);
8010400f:	8b 45 08             	mov    0x8(%ebp),%eax
80104012:	05 34 02 00 00       	add    $0x234,%eax
80104017:	83 ec 0c             	sub    $0xc,%esp
8010401a:	50                   	push   %eax
8010401b:	e8 38 0c 00 00       	call   80104c58 <wakeup>
80104020:	83 c4 10             	add    $0x10,%esp
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104023:	8b 45 08             	mov    0x8(%ebp),%eax
80104026:	8b 55 08             	mov    0x8(%ebp),%edx
80104029:	81 c2 38 02 00 00    	add    $0x238,%edx
8010402f:	83 ec 08             	sub    $0x8,%esp
80104032:	50                   	push   %eax
80104033:	52                   	push   %edx
80104034:	e8 39 0b 00 00       	call   80104b72 <sleep>
80104039:	83 c4 10             	add    $0x10,%esp
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010403c:	8b 45 08             	mov    0x8(%ebp),%eax
8010403f:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104045:	8b 45 08             	mov    0x8(%ebp),%eax
80104048:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010404e:	05 00 02 00 00       	add    $0x200,%eax
80104053:	39 c2                	cmp    %eax,%edx
80104055:	74 86                	je     80103fdd <pipewrite+0x21>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104057:	8b 45 08             	mov    0x8(%ebp),%eax
8010405a:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104060:	8d 48 01             	lea    0x1(%eax),%ecx
80104063:	8b 55 08             	mov    0x8(%ebp),%edx
80104066:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
8010406c:	25 ff 01 00 00       	and    $0x1ff,%eax
80104071:	89 c1                	mov    %eax,%ecx
80104073:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104076:	8b 45 0c             	mov    0xc(%ebp),%eax
80104079:	01 d0                	add    %edx,%eax
8010407b:	0f b6 10             	movzbl (%eax),%edx
8010407e:	8b 45 08             	mov    0x8(%ebp),%eax
80104081:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104085:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104089:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010408c:	3b 45 10             	cmp    0x10(%ebp),%eax
8010408f:	7c ab                	jl     8010403c <pipewrite+0x80>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104091:	8b 45 08             	mov    0x8(%ebp),%eax
80104094:	05 34 02 00 00       	add    $0x234,%eax
80104099:	83 ec 0c             	sub    $0xc,%esp
8010409c:	50                   	push   %eax
8010409d:	e8 b6 0b 00 00       	call   80104c58 <wakeup>
801040a2:	83 c4 10             	add    $0x10,%esp
  release(&p->lock);
801040a5:	8b 45 08             	mov    0x8(%ebp),%eax
801040a8:	83 ec 0c             	sub    $0xc,%esp
801040ab:	50                   	push   %eax
801040ac:	e8 48 0f 00 00       	call   80104ff9 <release>
801040b1:	83 c4 10             	add    $0x10,%esp
  return n;
801040b4:	8b 45 10             	mov    0x10(%ebp),%eax
}
801040b7:	c9                   	leave  
801040b8:	c3                   	ret    

801040b9 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801040b9:	55                   	push   %ebp
801040ba:	89 e5                	mov    %esp,%ebp
801040bc:	53                   	push   %ebx
801040bd:	83 ec 14             	sub    $0x14,%esp
  int i;

  acquire(&p->lock);
801040c0:	8b 45 08             	mov    0x8(%ebp),%eax
801040c3:	83 ec 0c             	sub    $0xc,%esp
801040c6:	50                   	push   %eax
801040c7:	e8 bf 0e 00 00       	call   80104f8b <acquire>
801040cc:	83 c4 10             	add    $0x10,%esp
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801040cf:	eb 3e                	jmp    8010410f <piperead+0x56>
    if(myproc()->killed){
801040d1:	e8 b2 01 00 00       	call   80104288 <myproc>
801040d6:	8b 40 24             	mov    0x24(%eax),%eax
801040d9:	85 c0                	test   %eax,%eax
801040db:	74 19                	je     801040f6 <piperead+0x3d>
      release(&p->lock);
801040dd:	8b 45 08             	mov    0x8(%ebp),%eax
801040e0:	83 ec 0c             	sub    $0xc,%esp
801040e3:	50                   	push   %eax
801040e4:	e8 10 0f 00 00       	call   80104ff9 <release>
801040e9:	83 c4 10             	add    $0x10,%esp
      return -1;
801040ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040f1:	e9 bf 00 00 00       	jmp    801041b5 <piperead+0xfc>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801040f6:	8b 45 08             	mov    0x8(%ebp),%eax
801040f9:	8b 55 08             	mov    0x8(%ebp),%edx
801040fc:	81 c2 34 02 00 00    	add    $0x234,%edx
80104102:	83 ec 08             	sub    $0x8,%esp
80104105:	50                   	push   %eax
80104106:	52                   	push   %edx
80104107:	e8 66 0a 00 00       	call   80104b72 <sleep>
8010410c:	83 c4 10             	add    $0x10,%esp
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010410f:	8b 45 08             	mov    0x8(%ebp),%eax
80104112:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104118:	8b 45 08             	mov    0x8(%ebp),%eax
8010411b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104121:	39 c2                	cmp    %eax,%edx
80104123:	75 0d                	jne    80104132 <piperead+0x79>
80104125:	8b 45 08             	mov    0x8(%ebp),%eax
80104128:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010412e:	85 c0                	test   %eax,%eax
80104130:	75 9f                	jne    801040d1 <piperead+0x18>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104132:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104139:	eb 49                	jmp    80104184 <piperead+0xcb>
    if(p->nread == p->nwrite)
8010413b:	8b 45 08             	mov    0x8(%ebp),%eax
8010413e:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104144:	8b 45 08             	mov    0x8(%ebp),%eax
80104147:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010414d:	39 c2                	cmp    %eax,%edx
8010414f:	74 3d                	je     8010418e <piperead+0xd5>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104151:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104154:	8b 45 0c             	mov    0xc(%ebp),%eax
80104157:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
8010415a:	8b 45 08             	mov    0x8(%ebp),%eax
8010415d:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104163:	8d 48 01             	lea    0x1(%eax),%ecx
80104166:	8b 55 08             	mov    0x8(%ebp),%edx
80104169:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
8010416f:	25 ff 01 00 00       	and    $0x1ff,%eax
80104174:	89 c2                	mov    %eax,%edx
80104176:	8b 45 08             	mov    0x8(%ebp),%eax
80104179:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
8010417e:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104180:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104184:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104187:	3b 45 10             	cmp    0x10(%ebp),%eax
8010418a:	7c af                	jl     8010413b <piperead+0x82>
8010418c:	eb 01                	jmp    8010418f <piperead+0xd6>
    if(p->nread == p->nwrite)
      break;
8010418e:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010418f:	8b 45 08             	mov    0x8(%ebp),%eax
80104192:	05 38 02 00 00       	add    $0x238,%eax
80104197:	83 ec 0c             	sub    $0xc,%esp
8010419a:	50                   	push   %eax
8010419b:	e8 b8 0a 00 00       	call   80104c58 <wakeup>
801041a0:	83 c4 10             	add    $0x10,%esp
  release(&p->lock);
801041a3:	8b 45 08             	mov    0x8(%ebp),%eax
801041a6:	83 ec 0c             	sub    $0xc,%esp
801041a9:	50                   	push   %eax
801041aa:	e8 4a 0e 00 00       	call   80104ff9 <release>
801041af:	83 c4 10             	add    $0x10,%esp
  return i;
801041b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801041b5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801041b8:	c9                   	leave  
801041b9:	c3                   	ret    

801041ba <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801041ba:	55                   	push   %ebp
801041bb:	89 e5                	mov    %esp,%ebp
801041bd:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801041c0:	9c                   	pushf  
801041c1:	58                   	pop    %eax
801041c2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801041c5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801041c8:	c9                   	leave  
801041c9:	c3                   	ret    

801041ca <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801041ca:	55                   	push   %ebp
801041cb:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801041cd:	fb                   	sti    
}
801041ce:	90                   	nop
801041cf:	5d                   	pop    %ebp
801041d0:	c3                   	ret    

801041d1 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801041d1:	55                   	push   %ebp
801041d2:	89 e5                	mov    %esp,%ebp
801041d4:	83 ec 08             	sub    $0x8,%esp
  initlock(&ptable.lock, "ptable");
801041d7:	83 ec 08             	sub    $0x8,%esp
801041da:	68 4c 86 10 80       	push   $0x8010864c
801041df:	68 a0 3d 11 80       	push   $0x80113da0
801041e4:	e8 80 0d 00 00       	call   80104f69 <initlock>
801041e9:	83 c4 10             	add    $0x10,%esp
}
801041ec:	90                   	nop
801041ed:	c9                   	leave  
801041ee:	c3                   	ret    

801041ef <cpuid>:

// Must be called with interrupts disabled
int
cpuid() {
801041ef:	55                   	push   %ebp
801041f0:	89 e5                	mov    %esp,%ebp
801041f2:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
801041f5:	e8 16 00 00 00       	call   80104210 <mycpu>
801041fa:	89 c2                	mov    %eax,%edx
801041fc:	b8 00 38 11 80       	mov    $0x80113800,%eax
80104201:	29 c2                	sub    %eax,%edx
80104203:	89 d0                	mov    %edx,%eax
80104205:	c1 f8 04             	sar    $0x4,%eax
80104208:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010420e:	c9                   	leave  
8010420f:	c3                   	ret    

80104210 <mycpu>:

// Must be called with interrupts disabled to avoid the caller being
// rescheduled between reading lapicid and running through the loop.
struct cpu*
mycpu(void)
{
80104210:	55                   	push   %ebp
80104211:	89 e5                	mov    %esp,%ebp
80104213:	83 ec 18             	sub    $0x18,%esp
  int apicid, i;
  
  if(readeflags()&FL_IF)
80104216:	e8 9f ff ff ff       	call   801041ba <readeflags>
8010421b:	25 00 02 00 00       	and    $0x200,%eax
80104220:	85 c0                	test   %eax,%eax
80104222:	74 0d                	je     80104231 <mycpu+0x21>
    panic("mycpu called with interrupts enabled\n");
80104224:	83 ec 0c             	sub    $0xc,%esp
80104227:	68 54 86 10 80       	push   $0x80108654
8010422c:	e8 6f c3 ff ff       	call   801005a0 <panic>
  
  apicid = lapicid();
80104231:	e8 b5 ed ff ff       	call   80102feb <lapicid>
80104236:	89 45 f0             	mov    %eax,-0x10(%ebp)
  // APIC IDs are not guaranteed to be contiguous. Maybe we should have
  // a reverse map, or reserve a register to store &cpus[i].
  for (i = 0; i < ncpu; ++i) {
80104239:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104240:	eb 2d                	jmp    8010426f <mycpu+0x5f>
    if (cpus[i].apicid == apicid)
80104242:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104245:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
8010424b:	05 00 38 11 80       	add    $0x80113800,%eax
80104250:	0f b6 00             	movzbl (%eax),%eax
80104253:	0f b6 c0             	movzbl %al,%eax
80104256:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80104259:	75 10                	jne    8010426b <mycpu+0x5b>
      return &cpus[i];
8010425b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010425e:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80104264:	05 00 38 11 80       	add    $0x80113800,%eax
80104269:	eb 1b                	jmp    80104286 <mycpu+0x76>
    panic("mycpu called with interrupts enabled\n");
  
  apicid = lapicid();
  // APIC IDs are not guaranteed to be contiguous. Maybe we should have
  // a reverse map, or reserve a register to store &cpus[i].
  for (i = 0; i < ncpu; ++i) {
8010426b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010426f:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80104274:	39 45 f4             	cmp    %eax,-0xc(%ebp)
80104277:	7c c9                	jl     80104242 <mycpu+0x32>
    if (cpus[i].apicid == apicid)
      return &cpus[i];
  }
  panic("unknown apicid\n");
80104279:	83 ec 0c             	sub    $0xc,%esp
8010427c:	68 7a 86 10 80       	push   $0x8010867a
80104281:	e8 1a c3 ff ff       	call   801005a0 <panic>
}
80104286:	c9                   	leave  
80104287:	c3                   	ret    

80104288 <myproc>:

// Disable interrupts so that we are not rescheduled
// while reading proc from the cpu structure
struct proc*
myproc(void) {
80104288:	55                   	push   %ebp
80104289:	89 e5                	mov    %esp,%ebp
8010428b:	83 ec 18             	sub    $0x18,%esp
  struct cpu *c;
  struct proc *p;
  pushcli();
8010428e:	e8 63 0e 00 00       	call   801050f6 <pushcli>
  c = mycpu();
80104293:	e8 78 ff ff ff       	call   80104210 <mycpu>
80104298:	89 45 f4             	mov    %eax,-0xc(%ebp)
  p = c->proc;
8010429b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010429e:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801042a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  popcli();
801042a7:	e8 98 0e 00 00       	call   80105144 <popcli>
  return p;
801042ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801042af:	c9                   	leave  
801042b0:	c3                   	ret    

801042b1 <allocpid>:


int 
allocpid(void) 
{
801042b1:	55                   	push   %ebp
801042b2:	89 e5                	mov    %esp,%ebp
801042b4:	83 ec 18             	sub    $0x18,%esp
  int pid;
  acquire(&ptable.lock);
801042b7:	83 ec 0c             	sub    $0xc,%esp
801042ba:	68 a0 3d 11 80       	push   $0x80113da0
801042bf:	e8 c7 0c 00 00       	call   80104f8b <acquire>
801042c4:	83 c4 10             	add    $0x10,%esp
  pid = nextpid++;
801042c7:	a1 00 b0 10 80       	mov    0x8010b000,%eax
801042cc:	8d 50 01             	lea    0x1(%eax),%edx
801042cf:	89 15 00 b0 10 80    	mov    %edx,0x8010b000
801042d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&ptable.lock);
801042d8:	83 ec 0c             	sub    $0xc,%esp
801042db:	68 a0 3d 11 80       	push   $0x80113da0
801042e0:	e8 14 0d 00 00       	call   80104ff9 <release>
801042e5:	83 c4 10             	add    $0x10,%esp
  return pid;
801042e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801042eb:	c9                   	leave  
801042ec:	c3                   	ret    

801042ed <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
801042ed:	55                   	push   %ebp
801042ee:	89 e5                	mov    %esp,%ebp
801042f0:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
801042f3:	83 ec 0c             	sub    $0xc,%esp
801042f6:	68 a0 3d 11 80       	push   $0x80113da0
801042fb:	e8 8b 0c 00 00       	call   80104f8b <acquire>
80104300:	83 c4 10             	add    $0x10,%esp

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104303:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
8010430a:	eb 0e                	jmp    8010431a <allocproc+0x2d>
    if(p->state == UNUSED)
8010430c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010430f:	8b 40 0c             	mov    0xc(%eax),%eax
80104312:	85 c0                	test   %eax,%eax
80104314:	74 27                	je     8010433d <allocproc+0x50>
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104316:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010431a:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
80104321:	72 e9                	jb     8010430c <allocproc+0x1f>
    if(p->state == UNUSED)
      goto found;

  release(&ptable.lock);
80104323:	83 ec 0c             	sub    $0xc,%esp
80104326:	68 a0 3d 11 80       	push   $0x80113da0
8010432b:	e8 c9 0c 00 00       	call   80104ff9 <release>
80104330:	83 c4 10             	add    $0x10,%esp
  return 0;
80104333:	b8 00 00 00 00       	mov    $0x0,%eax
80104338:	e9 ad 00 00 00       	jmp    801043ea <allocproc+0xfd>

  acquire(&ptable.lock);

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
8010433d:	90                   	nop

  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
8010433e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104341:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  release(&ptable.lock);
80104348:	83 ec 0c             	sub    $0xc,%esp
8010434b:	68 a0 3d 11 80       	push   $0x80113da0
80104350:	e8 a4 0c 00 00       	call   80104ff9 <release>
80104355:	83 c4 10             	add    $0x10,%esp
  p->pid = allocpid();
80104358:	e8 54 ff ff ff       	call   801042b1 <allocpid>
8010435d:	89 c2                	mov    %eax,%edx
8010435f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104362:	89 50 10             	mov    %edx,0x10(%eax)


  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104365:	e8 2b e9 ff ff       	call   80102c95 <kalloc>
8010436a:	89 c2                	mov    %eax,%edx
8010436c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010436f:	89 50 08             	mov    %edx,0x8(%eax)
80104372:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104375:	8b 40 08             	mov    0x8(%eax),%eax
80104378:	85 c0                	test   %eax,%eax
8010437a:	75 11                	jne    8010438d <allocproc+0xa0>
    p->state = UNUSED;
8010437c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010437f:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104386:	b8 00 00 00 00       	mov    $0x0,%eax
8010438b:	eb 5d                	jmp    801043ea <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
8010438d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104390:	8b 40 08             	mov    0x8(%eax),%eax
80104393:	05 00 10 00 00       	add    $0x1000,%eax
80104398:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // Leave room for trap frame.
  sp -= sizeof *p->tf;
8010439b:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
8010439f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043a2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801043a5:	89 50 18             	mov    %edx,0x18(%eax)

  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801043a8:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801043ac:	ba 90 65 10 80       	mov    $0x80106590,%edx
801043b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043b4:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801043b6:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801043ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043bd:	8b 55 f0             	mov    -0x10(%ebp),%edx
801043c0:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801043c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043c6:	8b 40 1c             	mov    0x1c(%eax),%eax
801043c9:	83 ec 04             	sub    $0x4,%esp
801043cc:	6a 14                	push   $0x14
801043ce:	6a 00                	push   $0x0
801043d0:	50                   	push   %eax
801043d1:	e8 2c 0e 00 00       	call   80105202 <memset>
801043d6:	83 c4 10             	add    $0x10,%esp
  p->context->eip = (uint)forkret;
801043d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043dc:	8b 40 1c             	mov    0x1c(%eax),%eax
801043df:	ba 2c 4b 10 80       	mov    $0x80104b2c,%edx
801043e4:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
801043e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801043ea:	c9                   	leave  
801043eb:	c3                   	ret    

801043ec <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
801043ec:	55                   	push   %ebp
801043ed:	89 e5                	mov    %esp,%ebp
801043ef:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];

  p = allocproc();
801043f2:	e8 f6 fe ff ff       	call   801042ed <allocproc>
801043f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  initproc = p;
801043fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043fd:	a3 20 b6 10 80       	mov    %eax,0x8010b620
  if((p->pgdir = setupkvm()) == 0)
80104402:	e8 d0 36 00 00       	call   80107ad7 <setupkvm>
80104407:	89 c2                	mov    %eax,%edx
80104409:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010440c:	89 50 04             	mov    %edx,0x4(%eax)
8010440f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104412:	8b 40 04             	mov    0x4(%eax),%eax
80104415:	85 c0                	test   %eax,%eax
80104417:	75 0d                	jne    80104426 <userinit+0x3a>
    panic("userinit: out of memory?");
80104419:	83 ec 0c             	sub    $0xc,%esp
8010441c:	68 8a 86 10 80       	push   $0x8010868a
80104421:	e8 7a c1 ff ff       	call   801005a0 <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104426:	ba 2c 00 00 00       	mov    $0x2c,%edx
8010442b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010442e:	8b 40 04             	mov    0x4(%eax),%eax
80104431:	83 ec 04             	sub    $0x4,%esp
80104434:	52                   	push   %edx
80104435:	68 c0 b4 10 80       	push   $0x8010b4c0
8010443a:	50                   	push   %eax
8010443b:	e8 ff 38 00 00       	call   80107d3f <inituvm>
80104440:	83 c4 10             	add    $0x10,%esp
  p->sz = PGSIZE;
80104443:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104446:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
8010444c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010444f:	8b 40 18             	mov    0x18(%eax),%eax
80104452:	83 ec 04             	sub    $0x4,%esp
80104455:	6a 4c                	push   $0x4c
80104457:	6a 00                	push   $0x0
80104459:	50                   	push   %eax
8010445a:	e8 a3 0d 00 00       	call   80105202 <memset>
8010445f:	83 c4 10             	add    $0x10,%esp
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104462:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104465:	8b 40 18             	mov    0x18(%eax),%eax
80104468:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010446e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104471:	8b 40 18             	mov    0x18(%eax),%eax
80104474:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010447a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010447d:	8b 40 18             	mov    0x18(%eax),%eax
80104480:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104483:	8b 52 18             	mov    0x18(%edx),%edx
80104486:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010448a:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010448e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104491:	8b 40 18             	mov    0x18(%eax),%eax
80104494:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104497:	8b 52 18             	mov    0x18(%edx),%edx
8010449a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010449e:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801044a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044a5:	8b 40 18             	mov    0x18(%eax),%eax
801044a8:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801044af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044b2:	8b 40 18             	mov    0x18(%eax),%eax
801044b5:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801044bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044bf:	8b 40 18             	mov    0x18(%eax),%eax
801044c2:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801044c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044cc:	83 c0 6c             	add    $0x6c,%eax
801044cf:	83 ec 04             	sub    $0x4,%esp
801044d2:	6a 10                	push   $0x10
801044d4:	68 a3 86 10 80       	push   $0x801086a3
801044d9:	50                   	push   %eax
801044da:	e8 26 0f 00 00       	call   80105405 <safestrcpy>
801044df:	83 c4 10             	add    $0x10,%esp
  p->cwd = namei("/");
801044e2:	83 ec 0c             	sub    $0xc,%esp
801044e5:	68 ac 86 10 80       	push   $0x801086ac
801044ea:	e8 61 e0 ff ff       	call   80102550 <namei>
801044ef:	83 c4 10             	add    $0x10,%esp
801044f2:	89 c2                	mov    %eax,%edx
801044f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044f7:	89 50 68             	mov    %edx,0x68(%eax)

  // this assignment to p->state lets other cores
  // run this process. the acquire forces the above
  // writes to be visible, and the lock is also needed
  // because the assignment might not be atomic.
  acquire(&ptable.lock);
801044fa:	83 ec 0c             	sub    $0xc,%esp
801044fd:	68 a0 3d 11 80       	push   $0x80113da0
80104502:	e8 84 0a 00 00       	call   80104f8b <acquire>
80104507:	83 c4 10             	add    $0x10,%esp

  p->state = RUNNABLE;
8010450a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010450d:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  release(&ptable.lock);
80104514:	83 ec 0c             	sub    $0xc,%esp
80104517:	68 a0 3d 11 80       	push   $0x80113da0
8010451c:	e8 d8 0a 00 00       	call   80104ff9 <release>
80104521:	83 c4 10             	add    $0x10,%esp
}
80104524:	90                   	nop
80104525:	c9                   	leave  
80104526:	c3                   	ret    

80104527 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104527:	55                   	push   %ebp
80104528:	89 e5                	mov    %esp,%ebp
8010452a:	83 ec 18             	sub    $0x18,%esp
  uint sz;
  struct proc *curproc = myproc();
8010452d:	e8 56 fd ff ff       	call   80104288 <myproc>
80104532:	89 45 f0             	mov    %eax,-0x10(%ebp)

  sz = curproc->sz;
80104535:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104538:	8b 00                	mov    (%eax),%eax
8010453a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
8010453d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104541:	7e 2e                	jle    80104571 <growproc+0x4a>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80104543:	8b 55 08             	mov    0x8(%ebp),%edx
80104546:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104549:	01 c2                	add    %eax,%edx
8010454b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010454e:	8b 40 04             	mov    0x4(%eax),%eax
80104551:	83 ec 04             	sub    $0x4,%esp
80104554:	52                   	push   %edx
80104555:	ff 75 f4             	pushl  -0xc(%ebp)
80104558:	50                   	push   %eax
80104559:	e8 1e 39 00 00       	call   80107e7c <allocuvm>
8010455e:	83 c4 10             	add    $0x10,%esp
80104561:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104564:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104568:	75 3b                	jne    801045a5 <growproc+0x7e>
      return -1;
8010456a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010456f:	eb 4f                	jmp    801045c0 <growproc+0x99>
  } else if(n < 0){
80104571:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104575:	79 2e                	jns    801045a5 <growproc+0x7e>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80104577:	8b 55 08             	mov    0x8(%ebp),%edx
8010457a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010457d:	01 c2                	add    %eax,%edx
8010457f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104582:	8b 40 04             	mov    0x4(%eax),%eax
80104585:	83 ec 04             	sub    $0x4,%esp
80104588:	52                   	push   %edx
80104589:	ff 75 f4             	pushl  -0xc(%ebp)
8010458c:	50                   	push   %eax
8010458d:	e8 ef 39 00 00       	call   80107f81 <deallocuvm>
80104592:	83 c4 10             	add    $0x10,%esp
80104595:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104598:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010459c:	75 07                	jne    801045a5 <growproc+0x7e>
      return -1;
8010459e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045a3:	eb 1b                	jmp    801045c0 <growproc+0x99>
  }
  curproc->sz = sz;
801045a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801045a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045ab:	89 10                	mov    %edx,(%eax)
  switchuvm(curproc);
801045ad:	83 ec 0c             	sub    $0xc,%esp
801045b0:	ff 75 f0             	pushl  -0x10(%ebp)
801045b3:	e8 e9 35 00 00       	call   80107ba1 <switchuvm>
801045b8:	83 c4 10             	add    $0x10,%esp
  return 0;
801045bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045c0:	c9                   	leave  
801045c1:	c3                   	ret    

801045c2 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801045c2:	55                   	push   %ebp
801045c3:	89 e5                	mov    %esp,%ebp
801045c5:	57                   	push   %edi
801045c6:	56                   	push   %esi
801045c7:	53                   	push   %ebx
801045c8:	83 ec 1c             	sub    $0x1c,%esp
  int i, pid;
  struct proc *np;
  struct proc *curproc = myproc();
801045cb:	e8 b8 fc ff ff       	call   80104288 <myproc>
801045d0:	89 45 e0             	mov    %eax,-0x20(%ebp)

  // Allocate process.
  if((np = allocproc()) == 0){
801045d3:	e8 15 fd ff ff       	call   801042ed <allocproc>
801045d8:	89 45 dc             	mov    %eax,-0x24(%ebp)
801045db:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
801045df:	75 0a                	jne    801045eb <fork+0x29>
    return -1;
801045e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045e6:	e9 4c 01 00 00       	jmp    80104737 <fork+0x175>
  }

  // Copy process state from proc.
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
801045eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045ee:	8b 10                	mov    (%eax),%edx
801045f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045f3:	8b 40 04             	mov    0x4(%eax),%eax
801045f6:	83 ec 08             	sub    $0x8,%esp
801045f9:	52                   	push   %edx
801045fa:	50                   	push   %eax
801045fb:	e8 1f 3b 00 00       	call   8010811f <copyuvm>
80104600:	83 c4 10             	add    $0x10,%esp
80104603:	89 c2                	mov    %eax,%edx
80104605:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104608:	89 50 04             	mov    %edx,0x4(%eax)
8010460b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010460e:	8b 40 04             	mov    0x4(%eax),%eax
80104611:	85 c0                	test   %eax,%eax
80104613:	75 30                	jne    80104645 <fork+0x83>
    kfree(np->kstack);
80104615:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104618:	8b 40 08             	mov    0x8(%eax),%eax
8010461b:	83 ec 0c             	sub    $0xc,%esp
8010461e:	50                   	push   %eax
8010461f:	e8 d7 e5 ff ff       	call   80102bfb <kfree>
80104624:	83 c4 10             	add    $0x10,%esp
    np->kstack = 0;
80104627:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010462a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104631:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104634:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
8010463b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104640:	e9 f2 00 00 00       	jmp    80104737 <fork+0x175>
  }
  np->sz = curproc->sz;
80104645:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104648:	8b 10                	mov    (%eax),%edx
8010464a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010464d:	89 10                	mov    %edx,(%eax)
  np->parent = curproc;
8010464f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104652:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104655:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *curproc->tf;
80104658:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010465b:	8b 50 18             	mov    0x18(%eax),%edx
8010465e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104661:	8b 40 18             	mov    0x18(%eax),%eax
80104664:	89 c3                	mov    %eax,%ebx
80104666:	b8 13 00 00 00       	mov    $0x13,%eax
8010466b:	89 d7                	mov    %edx,%edi
8010466d:	89 de                	mov    %ebx,%esi
8010466f:	89 c1                	mov    %eax,%ecx
80104671:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104673:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104676:	8b 40 18             	mov    0x18(%eax),%eax
80104679:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104680:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104687:	eb 3d                	jmp    801046c6 <fork+0x104>
    if(curproc->ofile[i])
80104689:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010468c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010468f:	83 c2 08             	add    $0x8,%edx
80104692:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104696:	85 c0                	test   %eax,%eax
80104698:	74 28                	je     801046c2 <fork+0x100>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010469a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010469d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801046a0:	83 c2 08             	add    $0x8,%edx
801046a3:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801046a7:	83 ec 0c             	sub    $0xc,%esp
801046aa:	50                   	push   %eax
801046ab:	e8 b0 c9 ff ff       	call   80101060 <filedup>
801046b0:	83 c4 10             	add    $0x10,%esp
801046b3:	89 c1                	mov    %eax,%ecx
801046b5:	8b 45 dc             	mov    -0x24(%ebp),%eax
801046b8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801046bb:	83 c2 08             	add    $0x8,%edx
801046be:	89 4c 90 08          	mov    %ecx,0x8(%eax,%edx,4)
  *np->tf = *curproc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801046c2:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801046c6:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801046ca:	7e bd                	jle    80104689 <fork+0xc7>
    if(curproc->ofile[i])
      np->ofile[i] = filedup(curproc->ofile[i]);
  np->cwd = idup(curproc->cwd);
801046cc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046cf:	8b 40 68             	mov    0x68(%eax),%eax
801046d2:	83 ec 0c             	sub    $0xc,%esp
801046d5:	50                   	push   %eax
801046d6:	e8 fb d2 ff ff       	call   801019d6 <idup>
801046db:	83 c4 10             	add    $0x10,%esp
801046de:	89 c2                	mov    %eax,%edx
801046e0:	8b 45 dc             	mov    -0x24(%ebp),%eax
801046e3:	89 50 68             	mov    %edx,0x68(%eax)

  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
801046e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046e9:	8d 50 6c             	lea    0x6c(%eax),%edx
801046ec:	8b 45 dc             	mov    -0x24(%ebp),%eax
801046ef:	83 c0 6c             	add    $0x6c,%eax
801046f2:	83 ec 04             	sub    $0x4,%esp
801046f5:	6a 10                	push   $0x10
801046f7:	52                   	push   %edx
801046f8:	50                   	push   %eax
801046f9:	e8 07 0d 00 00       	call   80105405 <safestrcpy>
801046fe:	83 c4 10             	add    $0x10,%esp

  pid = np->pid;
80104701:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104704:	8b 40 10             	mov    0x10(%eax),%eax
80104707:	89 45 d8             	mov    %eax,-0x28(%ebp)

  acquire(&ptable.lock);
8010470a:	83 ec 0c             	sub    $0xc,%esp
8010470d:	68 a0 3d 11 80       	push   $0x80113da0
80104712:	e8 74 08 00 00       	call   80104f8b <acquire>
80104717:	83 c4 10             	add    $0x10,%esp

  np->state = RUNNABLE;
8010471a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010471d:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  release(&ptable.lock);
80104724:	83 ec 0c             	sub    $0xc,%esp
80104727:	68 a0 3d 11 80       	push   $0x80113da0
8010472c:	e8 c8 08 00 00       	call   80104ff9 <release>
80104731:	83 c4 10             	add    $0x10,%esp

  return pid;
80104734:	8b 45 d8             	mov    -0x28(%ebp),%eax
}
80104737:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010473a:	5b                   	pop    %ebx
8010473b:	5e                   	pop    %esi
8010473c:	5f                   	pop    %edi
8010473d:	5d                   	pop    %ebp
8010473e:	c3                   	ret    

8010473f <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
8010473f:	55                   	push   %ebp
80104740:	89 e5                	mov    %esp,%ebp
80104742:	83 ec 18             	sub    $0x18,%esp
  struct proc *curproc = myproc();
80104745:	e8 3e fb ff ff       	call   80104288 <myproc>
8010474a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  struct proc *p;
  int fd;

  if(curproc == initproc)
8010474d:	a1 20 b6 10 80       	mov    0x8010b620,%eax
80104752:	39 45 ec             	cmp    %eax,-0x14(%ebp)
80104755:	75 0d                	jne    80104764 <exit+0x25>
    panic("init exiting");
80104757:	83 ec 0c             	sub    $0xc,%esp
8010475a:	68 ae 86 10 80       	push   $0x801086ae
8010475f:	e8 3c be ff ff       	call   801005a0 <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104764:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010476b:	eb 3f                	jmp    801047ac <exit+0x6d>
    if(curproc->ofile[fd]){
8010476d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104770:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104773:	83 c2 08             	add    $0x8,%edx
80104776:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010477a:	85 c0                	test   %eax,%eax
8010477c:	74 2a                	je     801047a8 <exit+0x69>
      fileclose(curproc->ofile[fd]);
8010477e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104781:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104784:	83 c2 08             	add    $0x8,%edx
80104787:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010478b:	83 ec 0c             	sub    $0xc,%esp
8010478e:	50                   	push   %eax
8010478f:	e8 1d c9 ff ff       	call   801010b1 <fileclose>
80104794:	83 c4 10             	add    $0x10,%esp
      curproc->ofile[fd] = 0;
80104797:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010479a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010479d:	83 c2 08             	add    $0x8,%edx
801047a0:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801047a7:	00 

  if(curproc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801047a8:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801047ac:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801047b0:	7e bb                	jle    8010476d <exit+0x2e>
      fileclose(curproc->ofile[fd]);
      curproc->ofile[fd] = 0;
    }
  }

  begin_op();
801047b2:	e8 7e ed ff ff       	call   80103535 <begin_op>
  iput(curproc->cwd);
801047b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801047ba:	8b 40 68             	mov    0x68(%eax),%eax
801047bd:	83 ec 0c             	sub    $0xc,%esp
801047c0:	50                   	push   %eax
801047c1:	e8 ab d3 ff ff       	call   80101b71 <iput>
801047c6:	83 c4 10             	add    $0x10,%esp
  end_op();
801047c9:	e8 f3 ed ff ff       	call   801035c1 <end_op>
  curproc->cwd = 0;
801047ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
801047d1:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
801047d8:	83 ec 0c             	sub    $0xc,%esp
801047db:	68 a0 3d 11 80       	push   $0x80113da0
801047e0:	e8 a6 07 00 00       	call   80104f8b <acquire>
801047e5:	83 c4 10             	add    $0x10,%esp

  // Parent might be sleeping in wait().
  wakeup1(curproc->parent);
801047e8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801047eb:	8b 40 14             	mov    0x14(%eax),%eax
801047ee:	83 ec 0c             	sub    $0xc,%esp
801047f1:	50                   	push   %eax
801047f2:	e8 22 04 00 00       	call   80104c19 <wakeup1>
801047f7:	83 c4 10             	add    $0x10,%esp

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047fa:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
80104801:	eb 37                	jmp    8010483a <exit+0xfb>
    if(p->parent == curproc){
80104803:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104806:	8b 40 14             	mov    0x14(%eax),%eax
80104809:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010480c:	75 28                	jne    80104836 <exit+0xf7>
      p->parent = initproc;
8010480e:	8b 15 20 b6 10 80    	mov    0x8010b620,%edx
80104814:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104817:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
8010481a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010481d:	8b 40 0c             	mov    0xc(%eax),%eax
80104820:	83 f8 05             	cmp    $0x5,%eax
80104823:	75 11                	jne    80104836 <exit+0xf7>
        wakeup1(initproc);
80104825:	a1 20 b6 10 80       	mov    0x8010b620,%eax
8010482a:	83 ec 0c             	sub    $0xc,%esp
8010482d:	50                   	push   %eax
8010482e:	e8 e6 03 00 00       	call   80104c19 <wakeup1>
80104833:	83 c4 10             	add    $0x10,%esp

  // Parent might be sleeping in wait().
  wakeup1(curproc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104836:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010483a:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
80104841:	72 c0                	jb     80104803 <exit+0xc4>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  curproc->state = ZOMBIE;
80104843:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104846:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
8010484d:	e8 e5 01 00 00       	call   80104a37 <sched>
  panic("zombie exit");
80104852:	83 ec 0c             	sub    $0xc,%esp
80104855:	68 bb 86 10 80       	push   $0x801086bb
8010485a:	e8 41 bd ff ff       	call   801005a0 <panic>

8010485f <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
8010485f:	55                   	push   %ebp
80104860:	89 e5                	mov    %esp,%ebp
80104862:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  int havekids, pid;
  struct proc *curproc = myproc();
80104865:	e8 1e fa ff ff       	call   80104288 <myproc>
8010486a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  
  acquire(&ptable.lock);
8010486d:	83 ec 0c             	sub    $0xc,%esp
80104870:	68 a0 3d 11 80       	push   $0x80113da0
80104875:	e8 11 07 00 00       	call   80104f8b <acquire>
8010487a:	83 c4 10             	add    $0x10,%esp
  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
8010487d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104884:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
8010488b:	e9 a1 00 00 00       	jmp    80104931 <wait+0xd2>
      if(p->parent != curproc)
80104890:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104893:	8b 40 14             	mov    0x14(%eax),%eax
80104896:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104899:	0f 85 8d 00 00 00    	jne    8010492c <wait+0xcd>
        continue;
      havekids = 1;
8010489f:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801048a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048a9:	8b 40 0c             	mov    0xc(%eax),%eax
801048ac:	83 f8 05             	cmp    $0x5,%eax
801048af:	75 7c                	jne    8010492d <wait+0xce>
        // Found one.
        pid = p->pid;
801048b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048b4:	8b 40 10             	mov    0x10(%eax),%eax
801048b7:	89 45 e8             	mov    %eax,-0x18(%ebp)
        kfree(p->kstack);
801048ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048bd:	8b 40 08             	mov    0x8(%eax),%eax
801048c0:	83 ec 0c             	sub    $0xc,%esp
801048c3:	50                   	push   %eax
801048c4:	e8 32 e3 ff ff       	call   80102bfb <kfree>
801048c9:	83 c4 10             	add    $0x10,%esp
        p->kstack = 0;
801048cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048cf:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
801048d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048d9:	8b 40 04             	mov    0x4(%eax),%eax
801048dc:	83 ec 0c             	sub    $0xc,%esp
801048df:	50                   	push   %eax
801048e0:	e8 60 37 00 00       	call   80108045 <freevm>
801048e5:	83 c4 10             	add    $0x10,%esp
        p->pid = 0;
801048e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048eb:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801048f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048f5:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801048fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048ff:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104903:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104906:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        p->state = UNUSED;
8010490d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104910:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        release(&ptable.lock);
80104917:	83 ec 0c             	sub    $0xc,%esp
8010491a:	68 a0 3d 11 80       	push   $0x80113da0
8010491f:	e8 d5 06 00 00       	call   80104ff9 <release>
80104924:	83 c4 10             	add    $0x10,%esp
        return pid;
80104927:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010492a:	eb 51                	jmp    8010497d <wait+0x11e>
  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != curproc)
        continue;
8010492c:	90                   	nop
  
  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010492d:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104931:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
80104938:	0f 82 52 ff ff ff    	jb     80104890 <wait+0x31>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || curproc->killed){
8010493e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104942:	74 0a                	je     8010494e <wait+0xef>
80104944:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104947:	8b 40 24             	mov    0x24(%eax),%eax
8010494a:	85 c0                	test   %eax,%eax
8010494c:	74 17                	je     80104965 <wait+0x106>
      release(&ptable.lock);
8010494e:	83 ec 0c             	sub    $0xc,%esp
80104951:	68 a0 3d 11 80       	push   $0x80113da0
80104956:	e8 9e 06 00 00       	call   80104ff9 <release>
8010495b:	83 c4 10             	add    $0x10,%esp
      return -1;
8010495e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104963:	eb 18                	jmp    8010497d <wait+0x11e>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80104965:	83 ec 08             	sub    $0x8,%esp
80104968:	68 a0 3d 11 80       	push   $0x80113da0
8010496d:	ff 75 ec             	pushl  -0x14(%ebp)
80104970:	e8 fd 01 00 00       	call   80104b72 <sleep>
80104975:	83 c4 10             	add    $0x10,%esp
  }
80104978:	e9 00 ff ff ff       	jmp    8010487d <wait+0x1e>
}
8010497d:	c9                   	leave  
8010497e:	c3                   	ret    

8010497f <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
8010497f:	55                   	push   %ebp
80104980:	89 e5                	mov    %esp,%ebp
80104982:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  struct cpu *c = mycpu();
80104985:	e8 86 f8 ff ff       	call   80104210 <mycpu>
8010498a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  c->proc = 0;
8010498d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104990:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80104997:	00 00 00 
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
8010499a:	e8 2b f8 ff ff       	call   801041ca <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010499f:	83 ec 0c             	sub    $0xc,%esp
801049a2:	68 a0 3d 11 80       	push   $0x80113da0
801049a7:	e8 df 05 00 00       	call   80104f8b <acquire>
801049ac:	83 c4 10             	add    $0x10,%esp
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049af:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
801049b6:	eb 61                	jmp    80104a19 <scheduler+0x9a>
      if(p->state != RUNNABLE)
801049b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049bb:	8b 40 0c             	mov    0xc(%eax),%eax
801049be:	83 f8 03             	cmp    $0x3,%eax
801049c1:	75 51                	jne    80104a14 <scheduler+0x95>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      c->proc = p;
801049c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801049c6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049c9:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
      switchuvm(p);
801049cf:	83 ec 0c             	sub    $0xc,%esp
801049d2:	ff 75 f4             	pushl  -0xc(%ebp)
801049d5:	e8 c7 31 00 00       	call   80107ba1 <switchuvm>
801049da:	83 c4 10             	add    $0x10,%esp
      p->state = RUNNING;
801049dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049e0:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)

      swtch(&(c->scheduler), p->context);
801049e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049ea:	8b 40 1c             	mov    0x1c(%eax),%eax
801049ed:	8b 55 f0             	mov    -0x10(%ebp),%edx
801049f0:	83 c2 04             	add    $0x4,%edx
801049f3:	83 ec 08             	sub    $0x8,%esp
801049f6:	50                   	push   %eax
801049f7:	52                   	push   %edx
801049f8:	e8 79 0a 00 00       	call   80105476 <swtch>
801049fd:	83 c4 10             	add    $0x10,%esp
      switchkvm();
80104a00:	e8 83 31 00 00       	call   80107b88 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
80104a05:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a08:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80104a0f:	00 00 00 
80104a12:	eb 01                	jmp    80104a15 <scheduler+0x96>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80104a14:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a15:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104a19:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
80104a20:	72 96                	jb     801049b8 <scheduler+0x39>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
    }
    release(&ptable.lock);
80104a22:	83 ec 0c             	sub    $0xc,%esp
80104a25:	68 a0 3d 11 80       	push   $0x80113da0
80104a2a:	e8 ca 05 00 00       	call   80104ff9 <release>
80104a2f:	83 c4 10             	add    $0x10,%esp

  }
80104a32:	e9 63 ff ff ff       	jmp    8010499a <scheduler+0x1b>

80104a37 <sched>:
// be proc->intena and proc->ncli, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
80104a37:	55                   	push   %ebp
80104a38:	89 e5                	mov    %esp,%ebp
80104a3a:	83 ec 18             	sub    $0x18,%esp
  int intena;
  struct proc *p = myproc();
80104a3d:	e8 46 f8 ff ff       	call   80104288 <myproc>
80104a42:	89 45 f4             	mov    %eax,-0xc(%ebp)

  if(!holding(&ptable.lock))
80104a45:	83 ec 0c             	sub    $0xc,%esp
80104a48:	68 a0 3d 11 80       	push   $0x80113da0
80104a4d:	e8 73 06 00 00       	call   801050c5 <holding>
80104a52:	83 c4 10             	add    $0x10,%esp
80104a55:	85 c0                	test   %eax,%eax
80104a57:	75 0d                	jne    80104a66 <sched+0x2f>
    panic("sched ptable.lock");
80104a59:	83 ec 0c             	sub    $0xc,%esp
80104a5c:	68 c7 86 10 80       	push   $0x801086c7
80104a61:	e8 3a bb ff ff       	call   801005a0 <panic>
  if(mycpu()->ncli != 1)
80104a66:	e8 a5 f7 ff ff       	call   80104210 <mycpu>
80104a6b:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
80104a71:	83 f8 01             	cmp    $0x1,%eax
80104a74:	74 0d                	je     80104a83 <sched+0x4c>
    panic("sched locks");
80104a76:	83 ec 0c             	sub    $0xc,%esp
80104a79:	68 d9 86 10 80       	push   $0x801086d9
80104a7e:	e8 1d bb ff ff       	call   801005a0 <panic>
  if(p->state == RUNNING)
80104a83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a86:	8b 40 0c             	mov    0xc(%eax),%eax
80104a89:	83 f8 04             	cmp    $0x4,%eax
80104a8c:	75 0d                	jne    80104a9b <sched+0x64>
    panic("sched running");
80104a8e:	83 ec 0c             	sub    $0xc,%esp
80104a91:	68 e5 86 10 80       	push   $0x801086e5
80104a96:	e8 05 bb ff ff       	call   801005a0 <panic>
  if(readeflags()&FL_IF)
80104a9b:	e8 1a f7 ff ff       	call   801041ba <readeflags>
80104aa0:	25 00 02 00 00       	and    $0x200,%eax
80104aa5:	85 c0                	test   %eax,%eax
80104aa7:	74 0d                	je     80104ab6 <sched+0x7f>
    panic("sched interruptible");
80104aa9:	83 ec 0c             	sub    $0xc,%esp
80104aac:	68 f3 86 10 80       	push   $0x801086f3
80104ab1:	e8 ea ba ff ff       	call   801005a0 <panic>
  intena = mycpu()->intena;
80104ab6:	e8 55 f7 ff ff       	call   80104210 <mycpu>
80104abb:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104ac1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  swtch(&p->context, mycpu()->scheduler);
80104ac4:	e8 47 f7 ff ff       	call   80104210 <mycpu>
80104ac9:	8b 40 04             	mov    0x4(%eax),%eax
80104acc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104acf:	83 c2 1c             	add    $0x1c,%edx
80104ad2:	83 ec 08             	sub    $0x8,%esp
80104ad5:	50                   	push   %eax
80104ad6:	52                   	push   %edx
80104ad7:	e8 9a 09 00 00       	call   80105476 <swtch>
80104adc:	83 c4 10             	add    $0x10,%esp
  mycpu()->intena = intena;
80104adf:	e8 2c f7 ff ff       	call   80104210 <mycpu>
80104ae4:	89 c2                	mov    %eax,%edx
80104ae6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ae9:	89 82 a8 00 00 00    	mov    %eax,0xa8(%edx)
}
80104aef:	90                   	nop
80104af0:	c9                   	leave  
80104af1:	c3                   	ret    

80104af2 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104af2:	55                   	push   %ebp
80104af3:	89 e5                	mov    %esp,%ebp
80104af5:	83 ec 08             	sub    $0x8,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104af8:	83 ec 0c             	sub    $0xc,%esp
80104afb:	68 a0 3d 11 80       	push   $0x80113da0
80104b00:	e8 86 04 00 00       	call   80104f8b <acquire>
80104b05:	83 c4 10             	add    $0x10,%esp
  myproc()->state = RUNNABLE;
80104b08:	e8 7b f7 ff ff       	call   80104288 <myproc>
80104b0d:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104b14:	e8 1e ff ff ff       	call   80104a37 <sched>
  release(&ptable.lock);
80104b19:	83 ec 0c             	sub    $0xc,%esp
80104b1c:	68 a0 3d 11 80       	push   $0x80113da0
80104b21:	e8 d3 04 00 00       	call   80104ff9 <release>
80104b26:	83 c4 10             	add    $0x10,%esp
}
80104b29:	90                   	nop
80104b2a:	c9                   	leave  
80104b2b:	c3                   	ret    

80104b2c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104b2c:	55                   	push   %ebp
80104b2d:	89 e5                	mov    %esp,%ebp
80104b2f:	83 ec 08             	sub    $0x8,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104b32:	83 ec 0c             	sub    $0xc,%esp
80104b35:	68 a0 3d 11 80       	push   $0x80113da0
80104b3a:	e8 ba 04 00 00       	call   80104ff9 <release>
80104b3f:	83 c4 10             	add    $0x10,%esp

  if (first) {
80104b42:	a1 04 b0 10 80       	mov    0x8010b004,%eax
80104b47:	85 c0                	test   %eax,%eax
80104b49:	74 24                	je     80104b6f <forkret+0x43>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot
    // be run from main().
    first = 0;
80104b4b:	c7 05 04 b0 10 80 00 	movl   $0x0,0x8010b004
80104b52:	00 00 00 
    iinit(ROOTDEV);
80104b55:	83 ec 0c             	sub    $0xc,%esp
80104b58:	6a 01                	push   $0x1
80104b5a:	e8 3f cb ff ff       	call   8010169e <iinit>
80104b5f:	83 c4 10             	add    $0x10,%esp
    initlog(ROOTDEV);
80104b62:	83 ec 0c             	sub    $0xc,%esp
80104b65:	6a 01                	push   $0x1
80104b67:	e8 ab e7 ff ff       	call   80103317 <initlog>
80104b6c:	83 c4 10             	add    $0x10,%esp
  }

  // Return to "caller", actually trapret (see allocproc).
}
80104b6f:	90                   	nop
80104b70:	c9                   	leave  
80104b71:	c3                   	ret    

80104b72 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104b72:	55                   	push   %ebp
80104b73:	89 e5                	mov    %esp,%ebp
80104b75:	83 ec 18             	sub    $0x18,%esp
  struct proc *p = myproc();
80104b78:	e8 0b f7 ff ff       	call   80104288 <myproc>
80104b7d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  if(p == 0)
80104b80:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104b84:	75 0d                	jne    80104b93 <sleep+0x21>
    panic("sleep");
80104b86:	83 ec 0c             	sub    $0xc,%esp
80104b89:	68 07 87 10 80       	push   $0x80108707
80104b8e:	e8 0d ba ff ff       	call   801005a0 <panic>

  if(lk == 0)
80104b93:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104b97:	75 0d                	jne    80104ba6 <sleep+0x34>
    panic("sleep without lk");
80104b99:	83 ec 0c             	sub    $0xc,%esp
80104b9c:	68 0d 87 10 80       	push   $0x8010870d
80104ba1:	e8 fa b9 ff ff       	call   801005a0 <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104ba6:	81 7d 0c a0 3d 11 80 	cmpl   $0x80113da0,0xc(%ebp)
80104bad:	74 1e                	je     80104bcd <sleep+0x5b>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104baf:	83 ec 0c             	sub    $0xc,%esp
80104bb2:	68 a0 3d 11 80       	push   $0x80113da0
80104bb7:	e8 cf 03 00 00       	call   80104f8b <acquire>
80104bbc:	83 c4 10             	add    $0x10,%esp
    release(lk);
80104bbf:	83 ec 0c             	sub    $0xc,%esp
80104bc2:	ff 75 0c             	pushl  0xc(%ebp)
80104bc5:	e8 2f 04 00 00       	call   80104ff9 <release>
80104bca:	83 c4 10             	add    $0x10,%esp
  }
  // Go to sleep.
  p->chan = chan;
80104bcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bd0:	8b 55 08             	mov    0x8(%ebp),%edx
80104bd3:	89 50 20             	mov    %edx,0x20(%eax)
  p->state = SLEEPING;
80104bd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bd9:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  sched();
80104be0:	e8 52 fe ff ff       	call   80104a37 <sched>

  // Tidy up.
  p->chan = 0;
80104be5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104be8:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104bef:	81 7d 0c a0 3d 11 80 	cmpl   $0x80113da0,0xc(%ebp)
80104bf6:	74 1e                	je     80104c16 <sleep+0xa4>
    release(&ptable.lock);
80104bf8:	83 ec 0c             	sub    $0xc,%esp
80104bfb:	68 a0 3d 11 80       	push   $0x80113da0
80104c00:	e8 f4 03 00 00       	call   80104ff9 <release>
80104c05:	83 c4 10             	add    $0x10,%esp
    acquire(lk);
80104c08:	83 ec 0c             	sub    $0xc,%esp
80104c0b:	ff 75 0c             	pushl  0xc(%ebp)
80104c0e:	e8 78 03 00 00       	call   80104f8b <acquire>
80104c13:	83 c4 10             	add    $0x10,%esp
  }
}
80104c16:	90                   	nop
80104c17:	c9                   	leave  
80104c18:	c3                   	ret    

80104c19 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104c19:	55                   	push   %ebp
80104c1a:	89 e5                	mov    %esp,%ebp
80104c1c:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104c1f:	c7 45 fc d4 3d 11 80 	movl   $0x80113dd4,-0x4(%ebp)
80104c26:	eb 24                	jmp    80104c4c <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104c28:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104c2b:	8b 40 0c             	mov    0xc(%eax),%eax
80104c2e:	83 f8 02             	cmp    $0x2,%eax
80104c31:	75 15                	jne    80104c48 <wakeup1+0x2f>
80104c33:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104c36:	8b 40 20             	mov    0x20(%eax),%eax
80104c39:	3b 45 08             	cmp    0x8(%ebp),%eax
80104c3c:	75 0a                	jne    80104c48 <wakeup1+0x2f>
      p->state = RUNNABLE;
80104c3e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104c41:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104c48:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104c4c:	81 7d fc d4 5c 11 80 	cmpl   $0x80115cd4,-0x4(%ebp)
80104c53:	72 d3                	jb     80104c28 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104c55:	90                   	nop
80104c56:	c9                   	leave  
80104c57:	c3                   	ret    

80104c58 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104c58:	55                   	push   %ebp
80104c59:	89 e5                	mov    %esp,%ebp
80104c5b:	83 ec 08             	sub    $0x8,%esp
  acquire(&ptable.lock);
80104c5e:	83 ec 0c             	sub    $0xc,%esp
80104c61:	68 a0 3d 11 80       	push   $0x80113da0
80104c66:	e8 20 03 00 00       	call   80104f8b <acquire>
80104c6b:	83 c4 10             	add    $0x10,%esp
  wakeup1(chan);
80104c6e:	83 ec 0c             	sub    $0xc,%esp
80104c71:	ff 75 08             	pushl  0x8(%ebp)
80104c74:	e8 a0 ff ff ff       	call   80104c19 <wakeup1>
80104c79:	83 c4 10             	add    $0x10,%esp
  release(&ptable.lock);
80104c7c:	83 ec 0c             	sub    $0xc,%esp
80104c7f:	68 a0 3d 11 80       	push   $0x80113da0
80104c84:	e8 70 03 00 00       	call   80104ff9 <release>
80104c89:	83 c4 10             	add    $0x10,%esp
}
80104c8c:	90                   	nop
80104c8d:	c9                   	leave  
80104c8e:	c3                   	ret    

80104c8f <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104c8f:	55                   	push   %ebp
80104c90:	89 e5                	mov    %esp,%ebp
80104c92:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104c95:	83 ec 0c             	sub    $0xc,%esp
80104c98:	68 a0 3d 11 80       	push   $0x80113da0
80104c9d:	e8 e9 02 00 00       	call   80104f8b <acquire>
80104ca2:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ca5:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
80104cac:	eb 45                	jmp    80104cf3 <kill+0x64>
    if(p->pid == pid){
80104cae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cb1:	8b 40 10             	mov    0x10(%eax),%eax
80104cb4:	3b 45 08             	cmp    0x8(%ebp),%eax
80104cb7:	75 36                	jne    80104cef <kill+0x60>
      p->killed = 1;
80104cb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cbc:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104cc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cc6:	8b 40 0c             	mov    0xc(%eax),%eax
80104cc9:	83 f8 02             	cmp    $0x2,%eax
80104ccc:	75 0a                	jne    80104cd8 <kill+0x49>
        p->state = RUNNABLE;
80104cce:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cd1:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104cd8:	83 ec 0c             	sub    $0xc,%esp
80104cdb:	68 a0 3d 11 80       	push   $0x80113da0
80104ce0:	e8 14 03 00 00       	call   80104ff9 <release>
80104ce5:	83 c4 10             	add    $0x10,%esp
      return 0;
80104ce8:	b8 00 00 00 00       	mov    $0x0,%eax
80104ced:	eb 22                	jmp    80104d11 <kill+0x82>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104cef:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104cf3:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
80104cfa:	72 b2                	jb     80104cae <kill+0x1f>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104cfc:	83 ec 0c             	sub    $0xc,%esp
80104cff:	68 a0 3d 11 80       	push   $0x80113da0
80104d04:	e8 f0 02 00 00       	call   80104ff9 <release>
80104d09:	83 c4 10             	add    $0x10,%esp
  return -1;
80104d0c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104d11:	c9                   	leave  
80104d12:	c3                   	ret    

80104d13 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104d13:	55                   	push   %ebp
80104d14:	89 e5                	mov    %esp,%ebp
80104d16:	83 ec 48             	sub    $0x48,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d19:	c7 45 f0 d4 3d 11 80 	movl   $0x80113dd4,-0x10(%ebp)
80104d20:	e9 d7 00 00 00       	jmp    80104dfc <procdump+0xe9>
    if(p->state == UNUSED)
80104d25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d28:	8b 40 0c             	mov    0xc(%eax),%eax
80104d2b:	85 c0                	test   %eax,%eax
80104d2d:	0f 84 c4 00 00 00    	je     80104df7 <procdump+0xe4>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104d33:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d36:	8b 40 0c             	mov    0xc(%eax),%eax
80104d39:	83 f8 05             	cmp    $0x5,%eax
80104d3c:	77 23                	ja     80104d61 <procdump+0x4e>
80104d3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d41:	8b 40 0c             	mov    0xc(%eax),%eax
80104d44:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104d4b:	85 c0                	test   %eax,%eax
80104d4d:	74 12                	je     80104d61 <procdump+0x4e>
      state = states[p->state];
80104d4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d52:	8b 40 0c             	mov    0xc(%eax),%eax
80104d55:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104d5c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104d5f:	eb 07                	jmp    80104d68 <procdump+0x55>
    else
      state = "???";
80104d61:	c7 45 ec 1e 87 10 80 	movl   $0x8010871e,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104d68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d6b:	8d 50 6c             	lea    0x6c(%eax),%edx
80104d6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d71:	8b 40 10             	mov    0x10(%eax),%eax
80104d74:	52                   	push   %edx
80104d75:	ff 75 ec             	pushl  -0x14(%ebp)
80104d78:	50                   	push   %eax
80104d79:	68 22 87 10 80       	push   $0x80108722
80104d7e:	e8 7d b6 ff ff       	call   80100400 <cprintf>
80104d83:	83 c4 10             	add    $0x10,%esp
    if(p->state == SLEEPING){
80104d86:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d89:	8b 40 0c             	mov    0xc(%eax),%eax
80104d8c:	83 f8 02             	cmp    $0x2,%eax
80104d8f:	75 54                	jne    80104de5 <procdump+0xd2>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104d91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d94:	8b 40 1c             	mov    0x1c(%eax),%eax
80104d97:	8b 40 0c             	mov    0xc(%eax),%eax
80104d9a:	83 c0 08             	add    $0x8,%eax
80104d9d:	89 c2                	mov    %eax,%edx
80104d9f:	83 ec 08             	sub    $0x8,%esp
80104da2:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104da5:	50                   	push   %eax
80104da6:	52                   	push   %edx
80104da7:	e8 9f 02 00 00       	call   8010504b <getcallerpcs>
80104dac:	83 c4 10             	add    $0x10,%esp
      for(i=0; i<10 && pc[i] != 0; i++)
80104daf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104db6:	eb 1c                	jmp    80104dd4 <procdump+0xc1>
        cprintf(" %p", pc[i]);
80104db8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dbb:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104dbf:	83 ec 08             	sub    $0x8,%esp
80104dc2:	50                   	push   %eax
80104dc3:	68 2b 87 10 80       	push   $0x8010872b
80104dc8:	e8 33 b6 ff ff       	call   80100400 <cprintf>
80104dcd:	83 c4 10             	add    $0x10,%esp
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104dd0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104dd4:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104dd8:	7f 0b                	jg     80104de5 <procdump+0xd2>
80104dda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ddd:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104de1:	85 c0                	test   %eax,%eax
80104de3:	75 d3                	jne    80104db8 <procdump+0xa5>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104de5:	83 ec 0c             	sub    $0xc,%esp
80104de8:	68 2f 87 10 80       	push   $0x8010872f
80104ded:	e8 0e b6 ff ff       	call   80100400 <cprintf>
80104df2:	83 c4 10             	add    $0x10,%esp
80104df5:	eb 01                	jmp    80104df8 <procdump+0xe5>
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80104df7:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104df8:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104dfc:	81 7d f0 d4 5c 11 80 	cmpl   $0x80115cd4,-0x10(%ebp)
80104e03:	0f 82 1c ff ff ff    	jb     80104d25 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104e09:	90                   	nop
80104e0a:	c9                   	leave  
80104e0b:	c3                   	ret    

80104e0c <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80104e0c:	55                   	push   %ebp
80104e0d:	89 e5                	mov    %esp,%ebp
80104e0f:	83 ec 08             	sub    $0x8,%esp
  initlock(&lk->lk, "sleep lock");
80104e12:	8b 45 08             	mov    0x8(%ebp),%eax
80104e15:	83 c0 04             	add    $0x4,%eax
80104e18:	83 ec 08             	sub    $0x8,%esp
80104e1b:	68 5b 87 10 80       	push   $0x8010875b
80104e20:	50                   	push   %eax
80104e21:	e8 43 01 00 00       	call   80104f69 <initlock>
80104e26:	83 c4 10             	add    $0x10,%esp
  lk->name = name;
80104e29:	8b 45 08             	mov    0x8(%ebp),%eax
80104e2c:	8b 55 0c             	mov    0xc(%ebp),%edx
80104e2f:	89 50 38             	mov    %edx,0x38(%eax)
  lk->locked = 0;
80104e32:	8b 45 08             	mov    0x8(%ebp),%eax
80104e35:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->pid = 0;
80104e3b:	8b 45 08             	mov    0x8(%ebp),%eax
80104e3e:	c7 40 3c 00 00 00 00 	movl   $0x0,0x3c(%eax)
}
80104e45:	90                   	nop
80104e46:	c9                   	leave  
80104e47:	c3                   	ret    

80104e48 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80104e48:	55                   	push   %ebp
80104e49:	89 e5                	mov    %esp,%ebp
80104e4b:	83 ec 08             	sub    $0x8,%esp
  acquire(&lk->lk);
80104e4e:	8b 45 08             	mov    0x8(%ebp),%eax
80104e51:	83 c0 04             	add    $0x4,%eax
80104e54:	83 ec 0c             	sub    $0xc,%esp
80104e57:	50                   	push   %eax
80104e58:	e8 2e 01 00 00       	call   80104f8b <acquire>
80104e5d:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80104e60:	eb 15                	jmp    80104e77 <acquiresleep+0x2f>
    sleep(lk, &lk->lk);
80104e62:	8b 45 08             	mov    0x8(%ebp),%eax
80104e65:	83 c0 04             	add    $0x4,%eax
80104e68:	83 ec 08             	sub    $0x8,%esp
80104e6b:	50                   	push   %eax
80104e6c:	ff 75 08             	pushl  0x8(%ebp)
80104e6f:	e8 fe fc ff ff       	call   80104b72 <sleep>
80104e74:	83 c4 10             	add    $0x10,%esp

void
acquiresleep(struct sleeplock *lk)
{
  acquire(&lk->lk);
  while (lk->locked) {
80104e77:	8b 45 08             	mov    0x8(%ebp),%eax
80104e7a:	8b 00                	mov    (%eax),%eax
80104e7c:	85 c0                	test   %eax,%eax
80104e7e:	75 e2                	jne    80104e62 <acquiresleep+0x1a>
    sleep(lk, &lk->lk);
  }
  lk->locked = 1;
80104e80:	8b 45 08             	mov    0x8(%ebp),%eax
80104e83:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  lk->pid = myproc()->pid;
80104e89:	e8 fa f3 ff ff       	call   80104288 <myproc>
80104e8e:	8b 50 10             	mov    0x10(%eax),%edx
80104e91:	8b 45 08             	mov    0x8(%ebp),%eax
80104e94:	89 50 3c             	mov    %edx,0x3c(%eax)
  release(&lk->lk);
80104e97:	8b 45 08             	mov    0x8(%ebp),%eax
80104e9a:	83 c0 04             	add    $0x4,%eax
80104e9d:	83 ec 0c             	sub    $0xc,%esp
80104ea0:	50                   	push   %eax
80104ea1:	e8 53 01 00 00       	call   80104ff9 <release>
80104ea6:	83 c4 10             	add    $0x10,%esp
}
80104ea9:	90                   	nop
80104eaa:	c9                   	leave  
80104eab:	c3                   	ret    

80104eac <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80104eac:	55                   	push   %ebp
80104ead:	89 e5                	mov    %esp,%ebp
80104eaf:	83 ec 08             	sub    $0x8,%esp
  acquire(&lk->lk);
80104eb2:	8b 45 08             	mov    0x8(%ebp),%eax
80104eb5:	83 c0 04             	add    $0x4,%eax
80104eb8:	83 ec 0c             	sub    $0xc,%esp
80104ebb:	50                   	push   %eax
80104ebc:	e8 ca 00 00 00       	call   80104f8b <acquire>
80104ec1:	83 c4 10             	add    $0x10,%esp
  lk->locked = 0;
80104ec4:	8b 45 08             	mov    0x8(%ebp),%eax
80104ec7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->pid = 0;
80104ecd:	8b 45 08             	mov    0x8(%ebp),%eax
80104ed0:	c7 40 3c 00 00 00 00 	movl   $0x0,0x3c(%eax)
  wakeup(lk);
80104ed7:	83 ec 0c             	sub    $0xc,%esp
80104eda:	ff 75 08             	pushl  0x8(%ebp)
80104edd:	e8 76 fd ff ff       	call   80104c58 <wakeup>
80104ee2:	83 c4 10             	add    $0x10,%esp
  release(&lk->lk);
80104ee5:	8b 45 08             	mov    0x8(%ebp),%eax
80104ee8:	83 c0 04             	add    $0x4,%eax
80104eeb:	83 ec 0c             	sub    $0xc,%esp
80104eee:	50                   	push   %eax
80104eef:	e8 05 01 00 00       	call   80104ff9 <release>
80104ef4:	83 c4 10             	add    $0x10,%esp
}
80104ef7:	90                   	nop
80104ef8:	c9                   	leave  
80104ef9:	c3                   	ret    

80104efa <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80104efa:	55                   	push   %ebp
80104efb:	89 e5                	mov    %esp,%ebp
80104efd:	83 ec 18             	sub    $0x18,%esp
  int r;
  
  acquire(&lk->lk);
80104f00:	8b 45 08             	mov    0x8(%ebp),%eax
80104f03:	83 c0 04             	add    $0x4,%eax
80104f06:	83 ec 0c             	sub    $0xc,%esp
80104f09:	50                   	push   %eax
80104f0a:	e8 7c 00 00 00       	call   80104f8b <acquire>
80104f0f:	83 c4 10             	add    $0x10,%esp
  r = lk->locked;
80104f12:	8b 45 08             	mov    0x8(%ebp),%eax
80104f15:	8b 00                	mov    (%eax),%eax
80104f17:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&lk->lk);
80104f1a:	8b 45 08             	mov    0x8(%ebp),%eax
80104f1d:	83 c0 04             	add    $0x4,%eax
80104f20:	83 ec 0c             	sub    $0xc,%esp
80104f23:	50                   	push   %eax
80104f24:	e8 d0 00 00 00       	call   80104ff9 <release>
80104f29:	83 c4 10             	add    $0x10,%esp
  return r;
80104f2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104f2f:	c9                   	leave  
80104f30:	c3                   	ret    

80104f31 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104f31:	55                   	push   %ebp
80104f32:	89 e5                	mov    %esp,%ebp
80104f34:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104f37:	9c                   	pushf  
80104f38:	58                   	pop    %eax
80104f39:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104f3c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104f3f:	c9                   	leave  
80104f40:	c3                   	ret    

80104f41 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104f41:	55                   	push   %ebp
80104f42:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104f44:	fa                   	cli    
}
80104f45:	90                   	nop
80104f46:	5d                   	pop    %ebp
80104f47:	c3                   	ret    

80104f48 <sti>:

static inline void
sti(void)
{
80104f48:	55                   	push   %ebp
80104f49:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104f4b:	fb                   	sti    
}
80104f4c:	90                   	nop
80104f4d:	5d                   	pop    %ebp
80104f4e:	c3                   	ret    

80104f4f <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104f4f:	55                   	push   %ebp
80104f50:	89 e5                	mov    %esp,%ebp
80104f52:	83 ec 10             	sub    $0x10,%esp
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104f55:	8b 55 08             	mov    0x8(%ebp),%edx
80104f58:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f5b:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104f5e:	f0 87 02             	lock xchg %eax,(%edx)
80104f61:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104f64:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104f67:	c9                   	leave  
80104f68:	c3                   	ret    

80104f69 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104f69:	55                   	push   %ebp
80104f6a:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104f6c:	8b 45 08             	mov    0x8(%ebp),%eax
80104f6f:	8b 55 0c             	mov    0xc(%ebp),%edx
80104f72:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104f75:	8b 45 08             	mov    0x8(%ebp),%eax
80104f78:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104f7e:	8b 45 08             	mov    0x8(%ebp),%eax
80104f81:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104f88:	90                   	nop
80104f89:	5d                   	pop    %ebp
80104f8a:	c3                   	ret    

80104f8b <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104f8b:	55                   	push   %ebp
80104f8c:	89 e5                	mov    %esp,%ebp
80104f8e:	53                   	push   %ebx
80104f8f:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104f92:	e8 5f 01 00 00       	call   801050f6 <pushcli>
  if(holding(lk))
80104f97:	8b 45 08             	mov    0x8(%ebp),%eax
80104f9a:	83 ec 0c             	sub    $0xc,%esp
80104f9d:	50                   	push   %eax
80104f9e:	e8 22 01 00 00       	call   801050c5 <holding>
80104fa3:	83 c4 10             	add    $0x10,%esp
80104fa6:	85 c0                	test   %eax,%eax
80104fa8:	74 0d                	je     80104fb7 <acquire+0x2c>
    panic("acquire");
80104faa:	83 ec 0c             	sub    $0xc,%esp
80104fad:	68 66 87 10 80       	push   $0x80108766
80104fb2:	e8 e9 b5 ff ff       	call   801005a0 <panic>

  // The xchg is atomic.
  while(xchg(&lk->locked, 1) != 0)
80104fb7:	90                   	nop
80104fb8:	8b 45 08             	mov    0x8(%ebp),%eax
80104fbb:	83 ec 08             	sub    $0x8,%esp
80104fbe:	6a 01                	push   $0x1
80104fc0:	50                   	push   %eax
80104fc1:	e8 89 ff ff ff       	call   80104f4f <xchg>
80104fc6:	83 c4 10             	add    $0x10,%esp
80104fc9:	85 c0                	test   %eax,%eax
80104fcb:	75 eb                	jne    80104fb8 <acquire+0x2d>
    ;

  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that the critical section's memory
  // references happen after the lock is acquired.
  __sync_synchronize();
80104fcd:	f0 83 0c 24 00       	lock orl $0x0,(%esp)

  // Record info about lock acquisition for debugging.
  lk->cpu = mycpu();
80104fd2:	8b 5d 08             	mov    0x8(%ebp),%ebx
80104fd5:	e8 36 f2 ff ff       	call   80104210 <mycpu>
80104fda:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80104fdd:	8b 45 08             	mov    0x8(%ebp),%eax
80104fe0:	83 c0 0c             	add    $0xc,%eax
80104fe3:	83 ec 08             	sub    $0x8,%esp
80104fe6:	50                   	push   %eax
80104fe7:	8d 45 08             	lea    0x8(%ebp),%eax
80104fea:	50                   	push   %eax
80104feb:	e8 5b 00 00 00       	call   8010504b <getcallerpcs>
80104ff0:	83 c4 10             	add    $0x10,%esp
}
80104ff3:	90                   	nop
80104ff4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ff7:	c9                   	leave  
80104ff8:	c3                   	ret    

80104ff9 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104ff9:	55                   	push   %ebp
80104ffa:	89 e5                	mov    %esp,%ebp
80104ffc:	83 ec 08             	sub    $0x8,%esp
  if(!holding(lk))
80104fff:	83 ec 0c             	sub    $0xc,%esp
80105002:	ff 75 08             	pushl  0x8(%ebp)
80105005:	e8 bb 00 00 00       	call   801050c5 <holding>
8010500a:	83 c4 10             	add    $0x10,%esp
8010500d:	85 c0                	test   %eax,%eax
8010500f:	75 0d                	jne    8010501e <release+0x25>
    panic("release");
80105011:	83 ec 0c             	sub    $0xc,%esp
80105014:	68 6e 87 10 80       	push   $0x8010876e
80105019:	e8 82 b5 ff ff       	call   801005a0 <panic>

  lk->pcs[0] = 0;
8010501e:	8b 45 08             	mov    0x8(%ebp),%eax
80105021:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105028:	8b 45 08             	mov    0x8(%ebp),%eax
8010502b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that all the stores in the critical
  // section are visible to other cores before the lock is released.
  // Both the C compiler and the hardware may re-order loads and
  // stores; __sync_synchronize() tells them both not to.
  __sync_synchronize();
80105032:	f0 83 0c 24 00       	lock orl $0x0,(%esp)

  // Release the lock, equivalent to lk->locked = 0.
  // This code can't use a C assignment, since it might
  // not be atomic. A real OS would use C atomics here.
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80105037:	8b 45 08             	mov    0x8(%ebp),%eax
8010503a:	8b 55 08             	mov    0x8(%ebp),%edx
8010503d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  popcli();
80105043:	e8 fc 00 00 00       	call   80105144 <popcli>
}
80105048:	90                   	nop
80105049:	c9                   	leave  
8010504a:	c3                   	ret    

8010504b <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
8010504b:	55                   	push   %ebp
8010504c:	89 e5                	mov    %esp,%ebp
8010504e:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80105051:	8b 45 08             	mov    0x8(%ebp),%eax
80105054:	83 e8 08             	sub    $0x8,%eax
80105057:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
8010505a:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105061:	eb 38                	jmp    8010509b <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105063:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105067:	74 53                	je     801050bc <getcallerpcs+0x71>
80105069:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105070:	76 4a                	jbe    801050bc <getcallerpcs+0x71>
80105072:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105076:	74 44                	je     801050bc <getcallerpcs+0x71>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105078:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010507b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105082:	8b 45 0c             	mov    0xc(%ebp),%eax
80105085:	01 c2                	add    %eax,%edx
80105087:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010508a:	8b 40 04             	mov    0x4(%eax),%eax
8010508d:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
8010508f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105092:	8b 00                	mov    (%eax),%eax
80105094:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105097:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010509b:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010509f:	7e c2                	jle    80105063 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801050a1:	eb 19                	jmp    801050bc <getcallerpcs+0x71>
    pcs[i] = 0;
801050a3:	8b 45 f8             	mov    -0x8(%ebp),%eax
801050a6:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801050ad:	8b 45 0c             	mov    0xc(%ebp),%eax
801050b0:	01 d0                	add    %edx,%eax
801050b2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801050b8:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801050bc:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801050c0:	7e e1                	jle    801050a3 <getcallerpcs+0x58>
    pcs[i] = 0;
}
801050c2:	90                   	nop
801050c3:	c9                   	leave  
801050c4:	c3                   	ret    

801050c5 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
801050c5:	55                   	push   %ebp
801050c6:	89 e5                	mov    %esp,%ebp
801050c8:	53                   	push   %ebx
801050c9:	83 ec 04             	sub    $0x4,%esp
  return lock->locked && lock->cpu == mycpu();
801050cc:	8b 45 08             	mov    0x8(%ebp),%eax
801050cf:	8b 00                	mov    (%eax),%eax
801050d1:	85 c0                	test   %eax,%eax
801050d3:	74 16                	je     801050eb <holding+0x26>
801050d5:	8b 45 08             	mov    0x8(%ebp),%eax
801050d8:	8b 58 08             	mov    0x8(%eax),%ebx
801050db:	e8 30 f1 ff ff       	call   80104210 <mycpu>
801050e0:	39 c3                	cmp    %eax,%ebx
801050e2:	75 07                	jne    801050eb <holding+0x26>
801050e4:	b8 01 00 00 00       	mov    $0x1,%eax
801050e9:	eb 05                	jmp    801050f0 <holding+0x2b>
801050eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801050f0:	83 c4 04             	add    $0x4,%esp
801050f3:	5b                   	pop    %ebx
801050f4:	5d                   	pop    %ebp
801050f5:	c3                   	ret    

801050f6 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
801050f6:	55                   	push   %ebp
801050f7:	89 e5                	mov    %esp,%ebp
801050f9:	83 ec 18             	sub    $0x18,%esp
  int eflags;

  eflags = readeflags();
801050fc:	e8 30 fe ff ff       	call   80104f31 <readeflags>
80105101:	89 45 f4             	mov    %eax,-0xc(%ebp)
  cli();
80105104:	e8 38 fe ff ff       	call   80104f41 <cli>
  if(mycpu()->ncli == 0)
80105109:	e8 02 f1 ff ff       	call   80104210 <mycpu>
8010510e:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
80105114:	85 c0                	test   %eax,%eax
80105116:	75 15                	jne    8010512d <pushcli+0x37>
    mycpu()->intena = eflags & FL_IF;
80105118:	e8 f3 f0 ff ff       	call   80104210 <mycpu>
8010511d:	89 c2                	mov    %eax,%edx
8010511f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105122:	25 00 02 00 00       	and    $0x200,%eax
80105127:	89 82 a8 00 00 00    	mov    %eax,0xa8(%edx)
  mycpu()->ncli += 1;
8010512d:	e8 de f0 ff ff       	call   80104210 <mycpu>
80105132:	8b 90 a4 00 00 00    	mov    0xa4(%eax),%edx
80105138:	83 c2 01             	add    $0x1,%edx
8010513b:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
}
80105141:	90                   	nop
80105142:	c9                   	leave  
80105143:	c3                   	ret    

80105144 <popcli>:

void
popcli(void)
{
80105144:	55                   	push   %ebp
80105145:	89 e5                	mov    %esp,%ebp
80105147:	83 ec 08             	sub    $0x8,%esp
  if(readeflags()&FL_IF)
8010514a:	e8 e2 fd ff ff       	call   80104f31 <readeflags>
8010514f:	25 00 02 00 00       	and    $0x200,%eax
80105154:	85 c0                	test   %eax,%eax
80105156:	74 0d                	je     80105165 <popcli+0x21>
    panic("popcli - interruptible");
80105158:	83 ec 0c             	sub    $0xc,%esp
8010515b:	68 76 87 10 80       	push   $0x80108776
80105160:	e8 3b b4 ff ff       	call   801005a0 <panic>
  if(--mycpu()->ncli < 0)
80105165:	e8 a6 f0 ff ff       	call   80104210 <mycpu>
8010516a:	8b 90 a4 00 00 00    	mov    0xa4(%eax),%edx
80105170:	83 ea 01             	sub    $0x1,%edx
80105173:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80105179:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
8010517f:	85 c0                	test   %eax,%eax
80105181:	79 0d                	jns    80105190 <popcli+0x4c>
    panic("popcli");
80105183:	83 ec 0c             	sub    $0xc,%esp
80105186:	68 8d 87 10 80       	push   $0x8010878d
8010518b:	e8 10 b4 ff ff       	call   801005a0 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80105190:	e8 7b f0 ff ff       	call   80104210 <mycpu>
80105195:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
8010519b:	85 c0                	test   %eax,%eax
8010519d:	75 14                	jne    801051b3 <popcli+0x6f>
8010519f:	e8 6c f0 ff ff       	call   80104210 <mycpu>
801051a4:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
801051aa:	85 c0                	test   %eax,%eax
801051ac:	74 05                	je     801051b3 <popcli+0x6f>
    sti();
801051ae:	e8 95 fd ff ff       	call   80104f48 <sti>
}
801051b3:	90                   	nop
801051b4:	c9                   	leave  
801051b5:	c3                   	ret    

801051b6 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
801051b6:	55                   	push   %ebp
801051b7:	89 e5                	mov    %esp,%ebp
801051b9:	57                   	push   %edi
801051ba:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801051bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
801051be:	8b 55 10             	mov    0x10(%ebp),%edx
801051c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801051c4:	89 cb                	mov    %ecx,%ebx
801051c6:	89 df                	mov    %ebx,%edi
801051c8:	89 d1                	mov    %edx,%ecx
801051ca:	fc                   	cld    
801051cb:	f3 aa                	rep stos %al,%es:(%edi)
801051cd:	89 ca                	mov    %ecx,%edx
801051cf:	89 fb                	mov    %edi,%ebx
801051d1:	89 5d 08             	mov    %ebx,0x8(%ebp)
801051d4:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801051d7:	90                   	nop
801051d8:	5b                   	pop    %ebx
801051d9:	5f                   	pop    %edi
801051da:	5d                   	pop    %ebp
801051db:	c3                   	ret    

801051dc <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
801051dc:	55                   	push   %ebp
801051dd:	89 e5                	mov    %esp,%ebp
801051df:	57                   	push   %edi
801051e0:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801051e1:	8b 4d 08             	mov    0x8(%ebp),%ecx
801051e4:	8b 55 10             	mov    0x10(%ebp),%edx
801051e7:	8b 45 0c             	mov    0xc(%ebp),%eax
801051ea:	89 cb                	mov    %ecx,%ebx
801051ec:	89 df                	mov    %ebx,%edi
801051ee:	89 d1                	mov    %edx,%ecx
801051f0:	fc                   	cld    
801051f1:	f3 ab                	rep stos %eax,%es:(%edi)
801051f3:	89 ca                	mov    %ecx,%edx
801051f5:	89 fb                	mov    %edi,%ebx
801051f7:	89 5d 08             	mov    %ebx,0x8(%ebp)
801051fa:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801051fd:	90                   	nop
801051fe:	5b                   	pop    %ebx
801051ff:	5f                   	pop    %edi
80105200:	5d                   	pop    %ebp
80105201:	c3                   	ret    

80105202 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105202:	55                   	push   %ebp
80105203:	89 e5                	mov    %esp,%ebp
  if ((int)dst%4 == 0 && n%4 == 0){
80105205:	8b 45 08             	mov    0x8(%ebp),%eax
80105208:	83 e0 03             	and    $0x3,%eax
8010520b:	85 c0                	test   %eax,%eax
8010520d:	75 43                	jne    80105252 <memset+0x50>
8010520f:	8b 45 10             	mov    0x10(%ebp),%eax
80105212:	83 e0 03             	and    $0x3,%eax
80105215:	85 c0                	test   %eax,%eax
80105217:	75 39                	jne    80105252 <memset+0x50>
    c &= 0xFF;
80105219:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105220:	8b 45 10             	mov    0x10(%ebp),%eax
80105223:	c1 e8 02             	shr    $0x2,%eax
80105226:	89 c1                	mov    %eax,%ecx
80105228:	8b 45 0c             	mov    0xc(%ebp),%eax
8010522b:	c1 e0 18             	shl    $0x18,%eax
8010522e:	89 c2                	mov    %eax,%edx
80105230:	8b 45 0c             	mov    0xc(%ebp),%eax
80105233:	c1 e0 10             	shl    $0x10,%eax
80105236:	09 c2                	or     %eax,%edx
80105238:	8b 45 0c             	mov    0xc(%ebp),%eax
8010523b:	c1 e0 08             	shl    $0x8,%eax
8010523e:	09 d0                	or     %edx,%eax
80105240:	0b 45 0c             	or     0xc(%ebp),%eax
80105243:	51                   	push   %ecx
80105244:	50                   	push   %eax
80105245:	ff 75 08             	pushl  0x8(%ebp)
80105248:	e8 8f ff ff ff       	call   801051dc <stosl>
8010524d:	83 c4 0c             	add    $0xc,%esp
80105250:	eb 12                	jmp    80105264 <memset+0x62>
  } else
    stosb(dst, c, n);
80105252:	8b 45 10             	mov    0x10(%ebp),%eax
80105255:	50                   	push   %eax
80105256:	ff 75 0c             	pushl  0xc(%ebp)
80105259:	ff 75 08             	pushl  0x8(%ebp)
8010525c:	e8 55 ff ff ff       	call   801051b6 <stosb>
80105261:	83 c4 0c             	add    $0xc,%esp
  return dst;
80105264:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105267:	c9                   	leave  
80105268:	c3                   	ret    

80105269 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105269:	55                   	push   %ebp
8010526a:	89 e5                	mov    %esp,%ebp
8010526c:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;

  s1 = v1;
8010526f:	8b 45 08             	mov    0x8(%ebp),%eax
80105272:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105275:	8b 45 0c             	mov    0xc(%ebp),%eax
80105278:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
8010527b:	eb 30                	jmp    801052ad <memcmp+0x44>
    if(*s1 != *s2)
8010527d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105280:	0f b6 10             	movzbl (%eax),%edx
80105283:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105286:	0f b6 00             	movzbl (%eax),%eax
80105289:	38 c2                	cmp    %al,%dl
8010528b:	74 18                	je     801052a5 <memcmp+0x3c>
      return *s1 - *s2;
8010528d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105290:	0f b6 00             	movzbl (%eax),%eax
80105293:	0f b6 d0             	movzbl %al,%edx
80105296:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105299:	0f b6 00             	movzbl (%eax),%eax
8010529c:	0f b6 c0             	movzbl %al,%eax
8010529f:	29 c2                	sub    %eax,%edx
801052a1:	89 d0                	mov    %edx,%eax
801052a3:	eb 1a                	jmp    801052bf <memcmp+0x56>
    s1++, s2++;
801052a5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801052a9:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
801052ad:	8b 45 10             	mov    0x10(%ebp),%eax
801052b0:	8d 50 ff             	lea    -0x1(%eax),%edx
801052b3:	89 55 10             	mov    %edx,0x10(%ebp)
801052b6:	85 c0                	test   %eax,%eax
801052b8:	75 c3                	jne    8010527d <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
801052ba:	b8 00 00 00 00       	mov    $0x0,%eax
}
801052bf:	c9                   	leave  
801052c0:	c3                   	ret    

801052c1 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801052c1:	55                   	push   %ebp
801052c2:	89 e5                	mov    %esp,%ebp
801052c4:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
801052c7:	8b 45 0c             	mov    0xc(%ebp),%eax
801052ca:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
801052cd:	8b 45 08             	mov    0x8(%ebp),%eax
801052d0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
801052d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052d6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801052d9:	73 54                	jae    8010532f <memmove+0x6e>
801052db:	8b 55 fc             	mov    -0x4(%ebp),%edx
801052de:	8b 45 10             	mov    0x10(%ebp),%eax
801052e1:	01 d0                	add    %edx,%eax
801052e3:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801052e6:	76 47                	jbe    8010532f <memmove+0x6e>
    s += n;
801052e8:	8b 45 10             	mov    0x10(%ebp),%eax
801052eb:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
801052ee:	8b 45 10             	mov    0x10(%ebp),%eax
801052f1:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
801052f4:	eb 13                	jmp    80105309 <memmove+0x48>
      *--d = *--s;
801052f6:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
801052fa:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
801052fe:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105301:	0f b6 10             	movzbl (%eax),%edx
80105304:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105307:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105309:	8b 45 10             	mov    0x10(%ebp),%eax
8010530c:	8d 50 ff             	lea    -0x1(%eax),%edx
8010530f:	89 55 10             	mov    %edx,0x10(%ebp)
80105312:	85 c0                	test   %eax,%eax
80105314:	75 e0                	jne    801052f6 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105316:	eb 24                	jmp    8010533c <memmove+0x7b>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105318:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010531b:	8d 50 01             	lea    0x1(%eax),%edx
8010531e:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105321:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105324:	8d 4a 01             	lea    0x1(%edx),%ecx
80105327:	89 4d fc             	mov    %ecx,-0x4(%ebp)
8010532a:	0f b6 12             	movzbl (%edx),%edx
8010532d:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010532f:	8b 45 10             	mov    0x10(%ebp),%eax
80105332:	8d 50 ff             	lea    -0x1(%eax),%edx
80105335:	89 55 10             	mov    %edx,0x10(%ebp)
80105338:	85 c0                	test   %eax,%eax
8010533a:	75 dc                	jne    80105318 <memmove+0x57>
      *d++ = *s++;

  return dst;
8010533c:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010533f:	c9                   	leave  
80105340:	c3                   	ret    

80105341 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105341:	55                   	push   %ebp
80105342:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80105344:	ff 75 10             	pushl  0x10(%ebp)
80105347:	ff 75 0c             	pushl  0xc(%ebp)
8010534a:	ff 75 08             	pushl  0x8(%ebp)
8010534d:	e8 6f ff ff ff       	call   801052c1 <memmove>
80105352:	83 c4 0c             	add    $0xc,%esp
}
80105355:	c9                   	leave  
80105356:	c3                   	ret    

80105357 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105357:	55                   	push   %ebp
80105358:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
8010535a:	eb 0c                	jmp    80105368 <strncmp+0x11>
    n--, p++, q++;
8010535c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105360:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105364:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105368:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010536c:	74 1a                	je     80105388 <strncmp+0x31>
8010536e:	8b 45 08             	mov    0x8(%ebp),%eax
80105371:	0f b6 00             	movzbl (%eax),%eax
80105374:	84 c0                	test   %al,%al
80105376:	74 10                	je     80105388 <strncmp+0x31>
80105378:	8b 45 08             	mov    0x8(%ebp),%eax
8010537b:	0f b6 10             	movzbl (%eax),%edx
8010537e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105381:	0f b6 00             	movzbl (%eax),%eax
80105384:	38 c2                	cmp    %al,%dl
80105386:	74 d4                	je     8010535c <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105388:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010538c:	75 07                	jne    80105395 <strncmp+0x3e>
    return 0;
8010538e:	b8 00 00 00 00       	mov    $0x0,%eax
80105393:	eb 16                	jmp    801053ab <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105395:	8b 45 08             	mov    0x8(%ebp),%eax
80105398:	0f b6 00             	movzbl (%eax),%eax
8010539b:	0f b6 d0             	movzbl %al,%edx
8010539e:	8b 45 0c             	mov    0xc(%ebp),%eax
801053a1:	0f b6 00             	movzbl (%eax),%eax
801053a4:	0f b6 c0             	movzbl %al,%eax
801053a7:	29 c2                	sub    %eax,%edx
801053a9:	89 d0                	mov    %edx,%eax
}
801053ab:	5d                   	pop    %ebp
801053ac:	c3                   	ret    

801053ad <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801053ad:	55                   	push   %ebp
801053ae:	89 e5                	mov    %esp,%ebp
801053b0:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
801053b3:	8b 45 08             	mov    0x8(%ebp),%eax
801053b6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
801053b9:	90                   	nop
801053ba:	8b 45 10             	mov    0x10(%ebp),%eax
801053bd:	8d 50 ff             	lea    -0x1(%eax),%edx
801053c0:	89 55 10             	mov    %edx,0x10(%ebp)
801053c3:	85 c0                	test   %eax,%eax
801053c5:	7e 2c                	jle    801053f3 <strncpy+0x46>
801053c7:	8b 45 08             	mov    0x8(%ebp),%eax
801053ca:	8d 50 01             	lea    0x1(%eax),%edx
801053cd:	89 55 08             	mov    %edx,0x8(%ebp)
801053d0:	8b 55 0c             	mov    0xc(%ebp),%edx
801053d3:	8d 4a 01             	lea    0x1(%edx),%ecx
801053d6:	89 4d 0c             	mov    %ecx,0xc(%ebp)
801053d9:	0f b6 12             	movzbl (%edx),%edx
801053dc:	88 10                	mov    %dl,(%eax)
801053de:	0f b6 00             	movzbl (%eax),%eax
801053e1:	84 c0                	test   %al,%al
801053e3:	75 d5                	jne    801053ba <strncpy+0xd>
    ;
  while(n-- > 0)
801053e5:	eb 0c                	jmp    801053f3 <strncpy+0x46>
    *s++ = 0;
801053e7:	8b 45 08             	mov    0x8(%ebp),%eax
801053ea:	8d 50 01             	lea    0x1(%eax),%edx
801053ed:	89 55 08             	mov    %edx,0x8(%ebp)
801053f0:	c6 00 00             	movb   $0x0,(%eax)
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
801053f3:	8b 45 10             	mov    0x10(%ebp),%eax
801053f6:	8d 50 ff             	lea    -0x1(%eax),%edx
801053f9:	89 55 10             	mov    %edx,0x10(%ebp)
801053fc:	85 c0                	test   %eax,%eax
801053fe:	7f e7                	jg     801053e7 <strncpy+0x3a>
    *s++ = 0;
  return os;
80105400:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105403:	c9                   	leave  
80105404:	c3                   	ret    

80105405 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105405:	55                   	push   %ebp
80105406:	89 e5                	mov    %esp,%ebp
80105408:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
8010540b:	8b 45 08             	mov    0x8(%ebp),%eax
8010540e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105411:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105415:	7f 05                	jg     8010541c <safestrcpy+0x17>
    return os;
80105417:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010541a:	eb 31                	jmp    8010544d <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
8010541c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105420:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105424:	7e 1e                	jle    80105444 <safestrcpy+0x3f>
80105426:	8b 45 08             	mov    0x8(%ebp),%eax
80105429:	8d 50 01             	lea    0x1(%eax),%edx
8010542c:	89 55 08             	mov    %edx,0x8(%ebp)
8010542f:	8b 55 0c             	mov    0xc(%ebp),%edx
80105432:	8d 4a 01             	lea    0x1(%edx),%ecx
80105435:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105438:	0f b6 12             	movzbl (%edx),%edx
8010543b:	88 10                	mov    %dl,(%eax)
8010543d:	0f b6 00             	movzbl (%eax),%eax
80105440:	84 c0                	test   %al,%al
80105442:	75 d8                	jne    8010541c <safestrcpy+0x17>
    ;
  *s = 0;
80105444:	8b 45 08             	mov    0x8(%ebp),%eax
80105447:	c6 00 00             	movb   $0x0,(%eax)
  return os;
8010544a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010544d:	c9                   	leave  
8010544e:	c3                   	ret    

8010544f <strlen>:

int
strlen(const char *s)
{
8010544f:	55                   	push   %ebp
80105450:	89 e5                	mov    %esp,%ebp
80105452:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105455:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010545c:	eb 04                	jmp    80105462 <strlen+0x13>
8010545e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105462:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105465:	8b 45 08             	mov    0x8(%ebp),%eax
80105468:	01 d0                	add    %edx,%eax
8010546a:	0f b6 00             	movzbl (%eax),%eax
8010546d:	84 c0                	test   %al,%al
8010546f:	75 ed                	jne    8010545e <strlen+0xf>
    ;
  return n;
80105471:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105474:	c9                   	leave  
80105475:	c3                   	ret    

80105476 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105476:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
8010547a:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
8010547e:	55                   	push   %ebp
  pushl %ebx
8010547f:	53                   	push   %ebx
  pushl %esi
80105480:	56                   	push   %esi
  pushl %edi
80105481:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105482:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105484:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105486:	5f                   	pop    %edi
  popl %esi
80105487:	5e                   	pop    %esi
  popl %ebx
80105488:	5b                   	pop    %ebx
  popl %ebp
80105489:	5d                   	pop    %ebp
  ret
8010548a:	c3                   	ret    

8010548b <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
8010548b:	55                   	push   %ebp
8010548c:	89 e5                	mov    %esp,%ebp
8010548e:	83 ec 18             	sub    $0x18,%esp
  struct proc *curproc = myproc();
80105491:	e8 f2 ed ff ff       	call   80104288 <myproc>
80105496:	89 45 f4             	mov    %eax,-0xc(%ebp)

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80105499:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010549c:	8b 00                	mov    (%eax),%eax
8010549e:	3b 45 08             	cmp    0x8(%ebp),%eax
801054a1:	76 0f                	jbe    801054b2 <fetchint+0x27>
801054a3:	8b 45 08             	mov    0x8(%ebp),%eax
801054a6:	8d 50 04             	lea    0x4(%eax),%edx
801054a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054ac:	8b 00                	mov    (%eax),%eax
801054ae:	39 c2                	cmp    %eax,%edx
801054b0:	76 07                	jbe    801054b9 <fetchint+0x2e>
    return -1;
801054b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054b7:	eb 0f                	jmp    801054c8 <fetchint+0x3d>
  *ip = *(int*)(addr);
801054b9:	8b 45 08             	mov    0x8(%ebp),%eax
801054bc:	8b 10                	mov    (%eax),%edx
801054be:	8b 45 0c             	mov    0xc(%ebp),%eax
801054c1:	89 10                	mov    %edx,(%eax)
  return 0;
801054c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801054c8:	c9                   	leave  
801054c9:	c3                   	ret    

801054ca <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801054ca:	55                   	push   %ebp
801054cb:	89 e5                	mov    %esp,%ebp
801054cd:	83 ec 18             	sub    $0x18,%esp
  char *s, *ep;
  struct proc *curproc = myproc();
801054d0:	e8 b3 ed ff ff       	call   80104288 <myproc>
801054d5:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if(addr >= curproc->sz)
801054d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054db:	8b 00                	mov    (%eax),%eax
801054dd:	3b 45 08             	cmp    0x8(%ebp),%eax
801054e0:	77 07                	ja     801054e9 <fetchstr+0x1f>
    return -1;
801054e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054e7:	eb 43                	jmp    8010552c <fetchstr+0x62>
  *pp = (char*)addr;
801054e9:	8b 55 08             	mov    0x8(%ebp),%edx
801054ec:	8b 45 0c             	mov    0xc(%ebp),%eax
801054ef:	89 10                	mov    %edx,(%eax)
  ep = (char*)curproc->sz;
801054f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054f4:	8b 00                	mov    (%eax),%eax
801054f6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(s = *pp; s < ep; s++){
801054f9:	8b 45 0c             	mov    0xc(%ebp),%eax
801054fc:	8b 00                	mov    (%eax),%eax
801054fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105501:	eb 1c                	jmp    8010551f <fetchstr+0x55>
    if(*s == 0)
80105503:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105506:	0f b6 00             	movzbl (%eax),%eax
80105509:	84 c0                	test   %al,%al
8010550b:	75 0e                	jne    8010551b <fetchstr+0x51>
      return s - *pp;
8010550d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105510:	8b 45 0c             	mov    0xc(%ebp),%eax
80105513:	8b 00                	mov    (%eax),%eax
80105515:	29 c2                	sub    %eax,%edx
80105517:	89 d0                	mov    %edx,%eax
80105519:	eb 11                	jmp    8010552c <fetchstr+0x62>

  if(addr >= curproc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)curproc->sz;
  for(s = *pp; s < ep; s++){
8010551b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010551f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105522:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80105525:	72 dc                	jb     80105503 <fetchstr+0x39>
    if(*s == 0)
      return s - *pp;
  }
  return -1;
80105527:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010552c:	c9                   	leave  
8010552d:	c3                   	ret    

8010552e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010552e:	55                   	push   %ebp
8010552f:	89 e5                	mov    %esp,%ebp
80105531:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80105534:	e8 4f ed ff ff       	call   80104288 <myproc>
80105539:	8b 40 18             	mov    0x18(%eax),%eax
8010553c:	8b 40 44             	mov    0x44(%eax),%eax
8010553f:	8b 55 08             	mov    0x8(%ebp),%edx
80105542:	c1 e2 02             	shl    $0x2,%edx
80105545:	01 d0                	add    %edx,%eax
80105547:	83 c0 04             	add    $0x4,%eax
8010554a:	83 ec 08             	sub    $0x8,%esp
8010554d:	ff 75 0c             	pushl  0xc(%ebp)
80105550:	50                   	push   %eax
80105551:	e8 35 ff ff ff       	call   8010548b <fetchint>
80105556:	83 c4 10             	add    $0x10,%esp
}
80105559:	c9                   	leave  
8010555a:	c3                   	ret    

8010555b <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010555b:	55                   	push   %ebp
8010555c:	89 e5                	mov    %esp,%ebp
8010555e:	83 ec 18             	sub    $0x18,%esp
  int i;
  struct proc *curproc = myproc();
80105561:	e8 22 ed ff ff       	call   80104288 <myproc>
80105566:	89 45 f4             	mov    %eax,-0xc(%ebp)
 
  if(argint(n, &i) < 0)
80105569:	83 ec 08             	sub    $0x8,%esp
8010556c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010556f:	50                   	push   %eax
80105570:	ff 75 08             	pushl  0x8(%ebp)
80105573:	e8 b6 ff ff ff       	call   8010552e <argint>
80105578:	83 c4 10             	add    $0x10,%esp
8010557b:	85 c0                	test   %eax,%eax
8010557d:	79 07                	jns    80105586 <argptr+0x2b>
    return -1;
8010557f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105584:	eb 3b                	jmp    801055c1 <argptr+0x66>
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80105586:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010558a:	78 1f                	js     801055ab <argptr+0x50>
8010558c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010558f:	8b 00                	mov    (%eax),%eax
80105591:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105594:	39 d0                	cmp    %edx,%eax
80105596:	76 13                	jbe    801055ab <argptr+0x50>
80105598:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010559b:	89 c2                	mov    %eax,%edx
8010559d:	8b 45 10             	mov    0x10(%ebp),%eax
801055a0:	01 c2                	add    %eax,%edx
801055a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055a5:	8b 00                	mov    (%eax),%eax
801055a7:	39 c2                	cmp    %eax,%edx
801055a9:	76 07                	jbe    801055b2 <argptr+0x57>
    return -1;
801055ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055b0:	eb 0f                	jmp    801055c1 <argptr+0x66>
  *pp = (char*)i;
801055b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055b5:	89 c2                	mov    %eax,%edx
801055b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801055ba:	89 10                	mov    %edx,(%eax)
  return 0;
801055bc:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055c1:	c9                   	leave  
801055c2:	c3                   	ret    

801055c3 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801055c3:	55                   	push   %ebp
801055c4:	89 e5                	mov    %esp,%ebp
801055c6:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
801055c9:	83 ec 08             	sub    $0x8,%esp
801055cc:	8d 45 f4             	lea    -0xc(%ebp),%eax
801055cf:	50                   	push   %eax
801055d0:	ff 75 08             	pushl  0x8(%ebp)
801055d3:	e8 56 ff ff ff       	call   8010552e <argint>
801055d8:	83 c4 10             	add    $0x10,%esp
801055db:	85 c0                	test   %eax,%eax
801055dd:	79 07                	jns    801055e6 <argstr+0x23>
    return -1;
801055df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055e4:	eb 12                	jmp    801055f8 <argstr+0x35>
  return fetchstr(addr, pp);
801055e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055e9:	83 ec 08             	sub    $0x8,%esp
801055ec:	ff 75 0c             	pushl  0xc(%ebp)
801055ef:	50                   	push   %eax
801055f0:	e8 d5 fe ff ff       	call   801054ca <fetchstr>
801055f5:	83 c4 10             	add    $0x10,%esp
}
801055f8:	c9                   	leave  
801055f9:	c3                   	ret    

801055fa <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
801055fa:	55                   	push   %ebp
801055fb:	89 e5                	mov    %esp,%ebp
801055fd:	53                   	push   %ebx
801055fe:	83 ec 14             	sub    $0x14,%esp
  int num;
  struct proc *curproc = myproc();
80105601:	e8 82 ec ff ff       	call   80104288 <myproc>
80105606:	89 45 f4             	mov    %eax,-0xc(%ebp)

  num = curproc->tf->eax;
80105609:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010560c:	8b 40 18             	mov    0x18(%eax),%eax
8010560f:	8b 40 1c             	mov    0x1c(%eax),%eax
80105612:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105615:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105619:	7e 2d                	jle    80105648 <syscall+0x4e>
8010561b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010561e:	83 f8 15             	cmp    $0x15,%eax
80105621:	77 25                	ja     80105648 <syscall+0x4e>
80105623:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105626:	8b 04 85 20 b0 10 80 	mov    -0x7fef4fe0(,%eax,4),%eax
8010562d:	85 c0                	test   %eax,%eax
8010562f:	74 17                	je     80105648 <syscall+0x4e>
    curproc->tf->eax = syscalls[num]();
80105631:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105634:	8b 58 18             	mov    0x18(%eax),%ebx
80105637:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010563a:	8b 04 85 20 b0 10 80 	mov    -0x7fef4fe0(,%eax,4),%eax
80105641:	ff d0                	call   *%eax
80105643:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105646:	eb 2b                	jmp    80105673 <syscall+0x79>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
80105648:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010564b:	8d 50 6c             	lea    0x6c(%eax),%edx

  num = curproc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    curproc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
8010564e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105651:	8b 40 10             	mov    0x10(%eax),%eax
80105654:	ff 75 f0             	pushl  -0x10(%ebp)
80105657:	52                   	push   %edx
80105658:	50                   	push   %eax
80105659:	68 94 87 10 80       	push   $0x80108794
8010565e:	e8 9d ad ff ff       	call   80100400 <cprintf>
80105663:	83 c4 10             	add    $0x10,%esp
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
80105666:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105669:	8b 40 18             	mov    0x18(%eax),%eax
8010566c:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105673:	90                   	nop
80105674:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105677:	c9                   	leave  
80105678:	c3                   	ret    

80105679 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105679:	55                   	push   %ebp
8010567a:	89 e5                	mov    %esp,%ebp
8010567c:	83 ec 18             	sub    $0x18,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010567f:	83 ec 08             	sub    $0x8,%esp
80105682:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105685:	50                   	push   %eax
80105686:	ff 75 08             	pushl  0x8(%ebp)
80105689:	e8 a0 fe ff ff       	call   8010552e <argint>
8010568e:	83 c4 10             	add    $0x10,%esp
80105691:	85 c0                	test   %eax,%eax
80105693:	79 07                	jns    8010569c <argfd+0x23>
    return -1;
80105695:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010569a:	eb 51                	jmp    801056ed <argfd+0x74>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
8010569c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010569f:	85 c0                	test   %eax,%eax
801056a1:	78 22                	js     801056c5 <argfd+0x4c>
801056a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056a6:	83 f8 0f             	cmp    $0xf,%eax
801056a9:	7f 1a                	jg     801056c5 <argfd+0x4c>
801056ab:	e8 d8 eb ff ff       	call   80104288 <myproc>
801056b0:	89 c2                	mov    %eax,%edx
801056b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056b5:	83 c0 08             	add    $0x8,%eax
801056b8:	8b 44 82 08          	mov    0x8(%edx,%eax,4),%eax
801056bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801056bf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801056c3:	75 07                	jne    801056cc <argfd+0x53>
    return -1;
801056c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056ca:	eb 21                	jmp    801056ed <argfd+0x74>
  if(pfd)
801056cc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801056d0:	74 08                	je     801056da <argfd+0x61>
    *pfd = fd;
801056d2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801056d5:	8b 45 0c             	mov    0xc(%ebp),%eax
801056d8:	89 10                	mov    %edx,(%eax)
  if(pf)
801056da:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801056de:	74 08                	je     801056e8 <argfd+0x6f>
    *pf = f;
801056e0:	8b 45 10             	mov    0x10(%ebp),%eax
801056e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801056e6:	89 10                	mov    %edx,(%eax)
  return 0;
801056e8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801056ed:	c9                   	leave  
801056ee:	c3                   	ret    

801056ef <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801056ef:	55                   	push   %ebp
801056f0:	89 e5                	mov    %esp,%ebp
801056f2:	83 ec 18             	sub    $0x18,%esp
  int fd;
  struct proc *curproc = myproc();
801056f5:	e8 8e eb ff ff       	call   80104288 <myproc>
801056fa:	89 45 f0             	mov    %eax,-0x10(%ebp)

  for(fd = 0; fd < NOFILE; fd++){
801056fd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105704:	eb 2a                	jmp    80105730 <fdalloc+0x41>
    if(curproc->ofile[fd] == 0){
80105706:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105709:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010570c:	83 c2 08             	add    $0x8,%edx
8010570f:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105713:	85 c0                	test   %eax,%eax
80105715:	75 15                	jne    8010572c <fdalloc+0x3d>
      curproc->ofile[fd] = f;
80105717:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010571a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010571d:	8d 4a 08             	lea    0x8(%edx),%ecx
80105720:	8b 55 08             	mov    0x8(%ebp),%edx
80105723:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010572a:	eb 0f                	jmp    8010573b <fdalloc+0x4c>
fdalloc(struct file *f)
{
  int fd;
  struct proc *curproc = myproc();

  for(fd = 0; fd < NOFILE; fd++){
8010572c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105730:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80105734:	7e d0                	jle    80105706 <fdalloc+0x17>
    if(curproc->ofile[fd] == 0){
      curproc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105736:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010573b:	c9                   	leave  
8010573c:	c3                   	ret    

8010573d <sys_dup>:

int
sys_dup(void)
{
8010573d:	55                   	push   %ebp
8010573e:	89 e5                	mov    %esp,%ebp
80105740:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
80105743:	83 ec 04             	sub    $0x4,%esp
80105746:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105749:	50                   	push   %eax
8010574a:	6a 00                	push   $0x0
8010574c:	6a 00                	push   $0x0
8010574e:	e8 26 ff ff ff       	call   80105679 <argfd>
80105753:	83 c4 10             	add    $0x10,%esp
80105756:	85 c0                	test   %eax,%eax
80105758:	79 07                	jns    80105761 <sys_dup+0x24>
    return -1;
8010575a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010575f:	eb 31                	jmp    80105792 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105761:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105764:	83 ec 0c             	sub    $0xc,%esp
80105767:	50                   	push   %eax
80105768:	e8 82 ff ff ff       	call   801056ef <fdalloc>
8010576d:	83 c4 10             	add    $0x10,%esp
80105770:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105773:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105777:	79 07                	jns    80105780 <sys_dup+0x43>
    return -1;
80105779:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010577e:	eb 12                	jmp    80105792 <sys_dup+0x55>
  filedup(f);
80105780:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105783:	83 ec 0c             	sub    $0xc,%esp
80105786:	50                   	push   %eax
80105787:	e8 d4 b8 ff ff       	call   80101060 <filedup>
8010578c:	83 c4 10             	add    $0x10,%esp
  return fd;
8010578f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105792:	c9                   	leave  
80105793:	c3                   	ret    

80105794 <sys_read>:

int
sys_read(void)
{
80105794:	55                   	push   %ebp
80105795:	89 e5                	mov    %esp,%ebp
80105797:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010579a:	83 ec 04             	sub    $0x4,%esp
8010579d:	8d 45 f4             	lea    -0xc(%ebp),%eax
801057a0:	50                   	push   %eax
801057a1:	6a 00                	push   $0x0
801057a3:	6a 00                	push   $0x0
801057a5:	e8 cf fe ff ff       	call   80105679 <argfd>
801057aa:	83 c4 10             	add    $0x10,%esp
801057ad:	85 c0                	test   %eax,%eax
801057af:	78 2e                	js     801057df <sys_read+0x4b>
801057b1:	83 ec 08             	sub    $0x8,%esp
801057b4:	8d 45 f0             	lea    -0x10(%ebp),%eax
801057b7:	50                   	push   %eax
801057b8:	6a 02                	push   $0x2
801057ba:	e8 6f fd ff ff       	call   8010552e <argint>
801057bf:	83 c4 10             	add    $0x10,%esp
801057c2:	85 c0                	test   %eax,%eax
801057c4:	78 19                	js     801057df <sys_read+0x4b>
801057c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057c9:	83 ec 04             	sub    $0x4,%esp
801057cc:	50                   	push   %eax
801057cd:	8d 45 ec             	lea    -0x14(%ebp),%eax
801057d0:	50                   	push   %eax
801057d1:	6a 01                	push   $0x1
801057d3:	e8 83 fd ff ff       	call   8010555b <argptr>
801057d8:	83 c4 10             	add    $0x10,%esp
801057db:	85 c0                	test   %eax,%eax
801057dd:	79 07                	jns    801057e6 <sys_read+0x52>
    return -1;
801057df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057e4:	eb 17                	jmp    801057fd <sys_read+0x69>
  return fileread(f, p, n);
801057e6:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801057e9:	8b 55 ec             	mov    -0x14(%ebp),%edx
801057ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057ef:	83 ec 04             	sub    $0x4,%esp
801057f2:	51                   	push   %ecx
801057f3:	52                   	push   %edx
801057f4:	50                   	push   %eax
801057f5:	e8 f6 b9 ff ff       	call   801011f0 <fileread>
801057fa:	83 c4 10             	add    $0x10,%esp
}
801057fd:	c9                   	leave  
801057fe:	c3                   	ret    

801057ff <sys_write>:

int
sys_write(void)
{
801057ff:	55                   	push   %ebp
80105800:	89 e5                	mov    %esp,%ebp
80105802:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105805:	83 ec 04             	sub    $0x4,%esp
80105808:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010580b:	50                   	push   %eax
8010580c:	6a 00                	push   $0x0
8010580e:	6a 00                	push   $0x0
80105810:	e8 64 fe ff ff       	call   80105679 <argfd>
80105815:	83 c4 10             	add    $0x10,%esp
80105818:	85 c0                	test   %eax,%eax
8010581a:	78 2e                	js     8010584a <sys_write+0x4b>
8010581c:	83 ec 08             	sub    $0x8,%esp
8010581f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105822:	50                   	push   %eax
80105823:	6a 02                	push   $0x2
80105825:	e8 04 fd ff ff       	call   8010552e <argint>
8010582a:	83 c4 10             	add    $0x10,%esp
8010582d:	85 c0                	test   %eax,%eax
8010582f:	78 19                	js     8010584a <sys_write+0x4b>
80105831:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105834:	83 ec 04             	sub    $0x4,%esp
80105837:	50                   	push   %eax
80105838:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010583b:	50                   	push   %eax
8010583c:	6a 01                	push   $0x1
8010583e:	e8 18 fd ff ff       	call   8010555b <argptr>
80105843:	83 c4 10             	add    $0x10,%esp
80105846:	85 c0                	test   %eax,%eax
80105848:	79 07                	jns    80105851 <sys_write+0x52>
    return -1;
8010584a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010584f:	eb 17                	jmp    80105868 <sys_write+0x69>
  return filewrite(f, p, n);
80105851:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105854:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105857:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010585a:	83 ec 04             	sub    $0x4,%esp
8010585d:	51                   	push   %ecx
8010585e:	52                   	push   %edx
8010585f:	50                   	push   %eax
80105860:	e8 43 ba ff ff       	call   801012a8 <filewrite>
80105865:	83 c4 10             	add    $0x10,%esp
}
80105868:	c9                   	leave  
80105869:	c3                   	ret    

8010586a <sys_close>:

int
sys_close(void)
{
8010586a:	55                   	push   %ebp
8010586b:	89 e5                	mov    %esp,%ebp
8010586d:	83 ec 18             	sub    $0x18,%esp
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
80105870:	83 ec 04             	sub    $0x4,%esp
80105873:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105876:	50                   	push   %eax
80105877:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010587a:	50                   	push   %eax
8010587b:	6a 00                	push   $0x0
8010587d:	e8 f7 fd ff ff       	call   80105679 <argfd>
80105882:	83 c4 10             	add    $0x10,%esp
80105885:	85 c0                	test   %eax,%eax
80105887:	79 07                	jns    80105890 <sys_close+0x26>
    return -1;
80105889:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010588e:	eb 29                	jmp    801058b9 <sys_close+0x4f>
  myproc()->ofile[fd] = 0;
80105890:	e8 f3 e9 ff ff       	call   80104288 <myproc>
80105895:	89 c2                	mov    %eax,%edx
80105897:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010589a:	83 c0 08             	add    $0x8,%eax
8010589d:	c7 44 82 08 00 00 00 	movl   $0x0,0x8(%edx,%eax,4)
801058a4:	00 
  fileclose(f);
801058a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058a8:	83 ec 0c             	sub    $0xc,%esp
801058ab:	50                   	push   %eax
801058ac:	e8 00 b8 ff ff       	call   801010b1 <fileclose>
801058b1:	83 c4 10             	add    $0x10,%esp
  return 0;
801058b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801058b9:	c9                   	leave  
801058ba:	c3                   	ret    

801058bb <sys_fstat>:

int
sys_fstat(void)
{
801058bb:	55                   	push   %ebp
801058bc:	89 e5                	mov    %esp,%ebp
801058be:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  struct stat *st;

  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801058c1:	83 ec 04             	sub    $0x4,%esp
801058c4:	8d 45 f4             	lea    -0xc(%ebp),%eax
801058c7:	50                   	push   %eax
801058c8:	6a 00                	push   $0x0
801058ca:	6a 00                	push   $0x0
801058cc:	e8 a8 fd ff ff       	call   80105679 <argfd>
801058d1:	83 c4 10             	add    $0x10,%esp
801058d4:	85 c0                	test   %eax,%eax
801058d6:	78 17                	js     801058ef <sys_fstat+0x34>
801058d8:	83 ec 04             	sub    $0x4,%esp
801058db:	6a 14                	push   $0x14
801058dd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058e0:	50                   	push   %eax
801058e1:	6a 01                	push   $0x1
801058e3:	e8 73 fc ff ff       	call   8010555b <argptr>
801058e8:	83 c4 10             	add    $0x10,%esp
801058eb:	85 c0                	test   %eax,%eax
801058ed:	79 07                	jns    801058f6 <sys_fstat+0x3b>
    return -1;
801058ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058f4:	eb 13                	jmp    80105909 <sys_fstat+0x4e>
  return filestat(f, st);
801058f6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801058f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058fc:	83 ec 08             	sub    $0x8,%esp
801058ff:	52                   	push   %edx
80105900:	50                   	push   %eax
80105901:	e8 93 b8 ff ff       	call   80101199 <filestat>
80105906:	83 c4 10             	add    $0x10,%esp
}
80105909:	c9                   	leave  
8010590a:	c3                   	ret    

8010590b <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010590b:	55                   	push   %ebp
8010590c:	89 e5                	mov    %esp,%ebp
8010590e:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105911:	83 ec 08             	sub    $0x8,%esp
80105914:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105917:	50                   	push   %eax
80105918:	6a 00                	push   $0x0
8010591a:	e8 a4 fc ff ff       	call   801055c3 <argstr>
8010591f:	83 c4 10             	add    $0x10,%esp
80105922:	85 c0                	test   %eax,%eax
80105924:	78 15                	js     8010593b <sys_link+0x30>
80105926:	83 ec 08             	sub    $0x8,%esp
80105929:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010592c:	50                   	push   %eax
8010592d:	6a 01                	push   $0x1
8010592f:	e8 8f fc ff ff       	call   801055c3 <argstr>
80105934:	83 c4 10             	add    $0x10,%esp
80105937:	85 c0                	test   %eax,%eax
80105939:	79 0a                	jns    80105945 <sys_link+0x3a>
    return -1;
8010593b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105940:	e9 68 01 00 00       	jmp    80105aad <sys_link+0x1a2>

  begin_op();
80105945:	e8 eb db ff ff       	call   80103535 <begin_op>
  if((ip = namei(old)) == 0){
8010594a:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010594d:	83 ec 0c             	sub    $0xc,%esp
80105950:	50                   	push   %eax
80105951:	e8 fa cb ff ff       	call   80102550 <namei>
80105956:	83 c4 10             	add    $0x10,%esp
80105959:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010595c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105960:	75 0f                	jne    80105971 <sys_link+0x66>
    end_op();
80105962:	e8 5a dc ff ff       	call   801035c1 <end_op>
    return -1;
80105967:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010596c:	e9 3c 01 00 00       	jmp    80105aad <sys_link+0x1a2>
  }

  ilock(ip);
80105971:	83 ec 0c             	sub    $0xc,%esp
80105974:	ff 75 f4             	pushl  -0xc(%ebp)
80105977:	e8 94 c0 ff ff       	call   80101a10 <ilock>
8010597c:	83 c4 10             	add    $0x10,%esp
  if(ip->type == T_DIR){
8010597f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105982:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105986:	66 83 f8 01          	cmp    $0x1,%ax
8010598a:	75 1d                	jne    801059a9 <sys_link+0x9e>
    iunlockput(ip);
8010598c:	83 ec 0c             	sub    $0xc,%esp
8010598f:	ff 75 f4             	pushl  -0xc(%ebp)
80105992:	e8 aa c2 ff ff       	call   80101c41 <iunlockput>
80105997:	83 c4 10             	add    $0x10,%esp
    end_op();
8010599a:	e8 22 dc ff ff       	call   801035c1 <end_op>
    return -1;
8010599f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059a4:	e9 04 01 00 00       	jmp    80105aad <sys_link+0x1a2>
  }

  ip->nlink++;
801059a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059ac:	0f b7 40 56          	movzwl 0x56(%eax),%eax
801059b0:	83 c0 01             	add    $0x1,%eax
801059b3:	89 c2                	mov    %eax,%edx
801059b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059b8:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
801059bc:	83 ec 0c             	sub    $0xc,%esp
801059bf:	ff 75 f4             	pushl  -0xc(%ebp)
801059c2:	e8 6c be ff ff       	call   80101833 <iupdate>
801059c7:	83 c4 10             	add    $0x10,%esp
  iunlock(ip);
801059ca:	83 ec 0c             	sub    $0xc,%esp
801059cd:	ff 75 f4             	pushl  -0xc(%ebp)
801059d0:	e8 4e c1 ff ff       	call   80101b23 <iunlock>
801059d5:	83 c4 10             	add    $0x10,%esp

  if((dp = nameiparent(new, name)) == 0)
801059d8:	8b 45 dc             	mov    -0x24(%ebp),%eax
801059db:	83 ec 08             	sub    $0x8,%esp
801059de:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801059e1:	52                   	push   %edx
801059e2:	50                   	push   %eax
801059e3:	e8 84 cb ff ff       	call   8010256c <nameiparent>
801059e8:	83 c4 10             	add    $0x10,%esp
801059eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
801059ee:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801059f2:	74 71                	je     80105a65 <sys_link+0x15a>
    goto bad;
  ilock(dp);
801059f4:	83 ec 0c             	sub    $0xc,%esp
801059f7:	ff 75 f0             	pushl  -0x10(%ebp)
801059fa:	e8 11 c0 ff ff       	call   80101a10 <ilock>
801059ff:	83 c4 10             	add    $0x10,%esp
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105a02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a05:	8b 10                	mov    (%eax),%edx
80105a07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a0a:	8b 00                	mov    (%eax),%eax
80105a0c:	39 c2                	cmp    %eax,%edx
80105a0e:	75 1d                	jne    80105a2d <sys_link+0x122>
80105a10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a13:	8b 40 04             	mov    0x4(%eax),%eax
80105a16:	83 ec 04             	sub    $0x4,%esp
80105a19:	50                   	push   %eax
80105a1a:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105a1d:	50                   	push   %eax
80105a1e:	ff 75 f0             	pushl  -0x10(%ebp)
80105a21:	e8 8f c8 ff ff       	call   801022b5 <dirlink>
80105a26:	83 c4 10             	add    $0x10,%esp
80105a29:	85 c0                	test   %eax,%eax
80105a2b:	79 10                	jns    80105a3d <sys_link+0x132>
    iunlockput(dp);
80105a2d:	83 ec 0c             	sub    $0xc,%esp
80105a30:	ff 75 f0             	pushl  -0x10(%ebp)
80105a33:	e8 09 c2 ff ff       	call   80101c41 <iunlockput>
80105a38:	83 c4 10             	add    $0x10,%esp
    goto bad;
80105a3b:	eb 29                	jmp    80105a66 <sys_link+0x15b>
  }
  iunlockput(dp);
80105a3d:	83 ec 0c             	sub    $0xc,%esp
80105a40:	ff 75 f0             	pushl  -0x10(%ebp)
80105a43:	e8 f9 c1 ff ff       	call   80101c41 <iunlockput>
80105a48:	83 c4 10             	add    $0x10,%esp
  iput(ip);
80105a4b:	83 ec 0c             	sub    $0xc,%esp
80105a4e:	ff 75 f4             	pushl  -0xc(%ebp)
80105a51:	e8 1b c1 ff ff       	call   80101b71 <iput>
80105a56:	83 c4 10             	add    $0x10,%esp

  end_op();
80105a59:	e8 63 db ff ff       	call   801035c1 <end_op>

  return 0;
80105a5e:	b8 00 00 00 00       	mov    $0x0,%eax
80105a63:	eb 48                	jmp    80105aad <sys_link+0x1a2>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80105a65:	90                   	nop
  end_op();

  return 0;

bad:
  ilock(ip);
80105a66:	83 ec 0c             	sub    $0xc,%esp
80105a69:	ff 75 f4             	pushl  -0xc(%ebp)
80105a6c:	e8 9f bf ff ff       	call   80101a10 <ilock>
80105a71:	83 c4 10             	add    $0x10,%esp
  ip->nlink--;
80105a74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a77:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105a7b:	83 e8 01             	sub    $0x1,%eax
80105a7e:	89 c2                	mov    %eax,%edx
80105a80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a83:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
80105a87:	83 ec 0c             	sub    $0xc,%esp
80105a8a:	ff 75 f4             	pushl  -0xc(%ebp)
80105a8d:	e8 a1 bd ff ff       	call   80101833 <iupdate>
80105a92:	83 c4 10             	add    $0x10,%esp
  iunlockput(ip);
80105a95:	83 ec 0c             	sub    $0xc,%esp
80105a98:	ff 75 f4             	pushl  -0xc(%ebp)
80105a9b:	e8 a1 c1 ff ff       	call   80101c41 <iunlockput>
80105aa0:	83 c4 10             	add    $0x10,%esp
  end_op();
80105aa3:	e8 19 db ff ff       	call   801035c1 <end_op>
  return -1;
80105aa8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105aad:	c9                   	leave  
80105aae:	c3                   	ret    

80105aaf <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105aaf:	55                   	push   %ebp
80105ab0:	89 e5                	mov    %esp,%ebp
80105ab2:	83 ec 28             	sub    $0x28,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105ab5:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105abc:	eb 40                	jmp    80105afe <isdirempty+0x4f>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105abe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ac1:	6a 10                	push   $0x10
80105ac3:	50                   	push   %eax
80105ac4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105ac7:	50                   	push   %eax
80105ac8:	ff 75 08             	pushl  0x8(%ebp)
80105acb:	e8 31 c4 ff ff       	call   80101f01 <readi>
80105ad0:	83 c4 10             	add    $0x10,%esp
80105ad3:	83 f8 10             	cmp    $0x10,%eax
80105ad6:	74 0d                	je     80105ae5 <isdirempty+0x36>
      panic("isdirempty: readi");
80105ad8:	83 ec 0c             	sub    $0xc,%esp
80105adb:	68 b0 87 10 80       	push   $0x801087b0
80105ae0:	e8 bb aa ff ff       	call   801005a0 <panic>
    if(de.inum != 0)
80105ae5:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105ae9:	66 85 c0             	test   %ax,%ax
80105aec:	74 07                	je     80105af5 <isdirempty+0x46>
      return 0;
80105aee:	b8 00 00 00 00       	mov    $0x0,%eax
80105af3:	eb 1b                	jmp    80105b10 <isdirempty+0x61>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105af5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105af8:	83 c0 10             	add    $0x10,%eax
80105afb:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105afe:	8b 45 08             	mov    0x8(%ebp),%eax
80105b01:	8b 50 58             	mov    0x58(%eax),%edx
80105b04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b07:	39 c2                	cmp    %eax,%edx
80105b09:	77 b3                	ja     80105abe <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105b0b:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105b10:	c9                   	leave  
80105b11:	c3                   	ret    

80105b12 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105b12:	55                   	push   %ebp
80105b13:	89 e5                	mov    %esp,%ebp
80105b15:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105b18:	83 ec 08             	sub    $0x8,%esp
80105b1b:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105b1e:	50                   	push   %eax
80105b1f:	6a 00                	push   $0x0
80105b21:	e8 9d fa ff ff       	call   801055c3 <argstr>
80105b26:	83 c4 10             	add    $0x10,%esp
80105b29:	85 c0                	test   %eax,%eax
80105b2b:	79 0a                	jns    80105b37 <sys_unlink+0x25>
    return -1;
80105b2d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b32:	e9 bc 01 00 00       	jmp    80105cf3 <sys_unlink+0x1e1>

  begin_op();
80105b37:	e8 f9 d9 ff ff       	call   80103535 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105b3c:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105b3f:	83 ec 08             	sub    $0x8,%esp
80105b42:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105b45:	52                   	push   %edx
80105b46:	50                   	push   %eax
80105b47:	e8 20 ca ff ff       	call   8010256c <nameiparent>
80105b4c:	83 c4 10             	add    $0x10,%esp
80105b4f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105b52:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105b56:	75 0f                	jne    80105b67 <sys_unlink+0x55>
    end_op();
80105b58:	e8 64 da ff ff       	call   801035c1 <end_op>
    return -1;
80105b5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b62:	e9 8c 01 00 00       	jmp    80105cf3 <sys_unlink+0x1e1>
  }

  ilock(dp);
80105b67:	83 ec 0c             	sub    $0xc,%esp
80105b6a:	ff 75 f4             	pushl  -0xc(%ebp)
80105b6d:	e8 9e be ff ff       	call   80101a10 <ilock>
80105b72:	83 c4 10             	add    $0x10,%esp

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105b75:	83 ec 08             	sub    $0x8,%esp
80105b78:	68 c2 87 10 80       	push   $0x801087c2
80105b7d:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b80:	50                   	push   %eax
80105b81:	e8 5a c6 ff ff       	call   801021e0 <namecmp>
80105b86:	83 c4 10             	add    $0x10,%esp
80105b89:	85 c0                	test   %eax,%eax
80105b8b:	0f 84 4a 01 00 00    	je     80105cdb <sys_unlink+0x1c9>
80105b91:	83 ec 08             	sub    $0x8,%esp
80105b94:	68 c4 87 10 80       	push   $0x801087c4
80105b99:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b9c:	50                   	push   %eax
80105b9d:	e8 3e c6 ff ff       	call   801021e0 <namecmp>
80105ba2:	83 c4 10             	add    $0x10,%esp
80105ba5:	85 c0                	test   %eax,%eax
80105ba7:	0f 84 2e 01 00 00    	je     80105cdb <sys_unlink+0x1c9>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105bad:	83 ec 04             	sub    $0x4,%esp
80105bb0:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105bb3:	50                   	push   %eax
80105bb4:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105bb7:	50                   	push   %eax
80105bb8:	ff 75 f4             	pushl  -0xc(%ebp)
80105bbb:	e8 3b c6 ff ff       	call   801021fb <dirlookup>
80105bc0:	83 c4 10             	add    $0x10,%esp
80105bc3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105bc6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105bca:	0f 84 0a 01 00 00    	je     80105cda <sys_unlink+0x1c8>
    goto bad;
  ilock(ip);
80105bd0:	83 ec 0c             	sub    $0xc,%esp
80105bd3:	ff 75 f0             	pushl  -0x10(%ebp)
80105bd6:	e8 35 be ff ff       	call   80101a10 <ilock>
80105bdb:	83 c4 10             	add    $0x10,%esp

  if(ip->nlink < 1)
80105bde:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105be1:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105be5:	66 85 c0             	test   %ax,%ax
80105be8:	7f 0d                	jg     80105bf7 <sys_unlink+0xe5>
    panic("unlink: nlink < 1");
80105bea:	83 ec 0c             	sub    $0xc,%esp
80105bed:	68 c7 87 10 80       	push   $0x801087c7
80105bf2:	e8 a9 a9 ff ff       	call   801005a0 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105bf7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bfa:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105bfe:	66 83 f8 01          	cmp    $0x1,%ax
80105c02:	75 25                	jne    80105c29 <sys_unlink+0x117>
80105c04:	83 ec 0c             	sub    $0xc,%esp
80105c07:	ff 75 f0             	pushl  -0x10(%ebp)
80105c0a:	e8 a0 fe ff ff       	call   80105aaf <isdirempty>
80105c0f:	83 c4 10             	add    $0x10,%esp
80105c12:	85 c0                	test   %eax,%eax
80105c14:	75 13                	jne    80105c29 <sys_unlink+0x117>
    iunlockput(ip);
80105c16:	83 ec 0c             	sub    $0xc,%esp
80105c19:	ff 75 f0             	pushl  -0x10(%ebp)
80105c1c:	e8 20 c0 ff ff       	call   80101c41 <iunlockput>
80105c21:	83 c4 10             	add    $0x10,%esp
    goto bad;
80105c24:	e9 b2 00 00 00       	jmp    80105cdb <sys_unlink+0x1c9>
  }

  memset(&de, 0, sizeof(de));
80105c29:	83 ec 04             	sub    $0x4,%esp
80105c2c:	6a 10                	push   $0x10
80105c2e:	6a 00                	push   $0x0
80105c30:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105c33:	50                   	push   %eax
80105c34:	e8 c9 f5 ff ff       	call   80105202 <memset>
80105c39:	83 c4 10             	add    $0x10,%esp
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105c3c:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105c3f:	6a 10                	push   $0x10
80105c41:	50                   	push   %eax
80105c42:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105c45:	50                   	push   %eax
80105c46:	ff 75 f4             	pushl  -0xc(%ebp)
80105c49:	e8 0a c4 ff ff       	call   80102058 <writei>
80105c4e:	83 c4 10             	add    $0x10,%esp
80105c51:	83 f8 10             	cmp    $0x10,%eax
80105c54:	74 0d                	je     80105c63 <sys_unlink+0x151>
    panic("unlink: writei");
80105c56:	83 ec 0c             	sub    $0xc,%esp
80105c59:	68 d9 87 10 80       	push   $0x801087d9
80105c5e:	e8 3d a9 ff ff       	call   801005a0 <panic>
  if(ip->type == T_DIR){
80105c63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c66:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105c6a:	66 83 f8 01          	cmp    $0x1,%ax
80105c6e:	75 21                	jne    80105c91 <sys_unlink+0x17f>
    dp->nlink--;
80105c70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c73:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105c77:	83 e8 01             	sub    $0x1,%eax
80105c7a:	89 c2                	mov    %eax,%edx
80105c7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c7f:	66 89 50 56          	mov    %dx,0x56(%eax)
    iupdate(dp);
80105c83:	83 ec 0c             	sub    $0xc,%esp
80105c86:	ff 75 f4             	pushl  -0xc(%ebp)
80105c89:	e8 a5 bb ff ff       	call   80101833 <iupdate>
80105c8e:	83 c4 10             	add    $0x10,%esp
  }
  iunlockput(dp);
80105c91:	83 ec 0c             	sub    $0xc,%esp
80105c94:	ff 75 f4             	pushl  -0xc(%ebp)
80105c97:	e8 a5 bf ff ff       	call   80101c41 <iunlockput>
80105c9c:	83 c4 10             	add    $0x10,%esp

  ip->nlink--;
80105c9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ca2:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105ca6:	83 e8 01             	sub    $0x1,%eax
80105ca9:	89 c2                	mov    %eax,%edx
80105cab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cae:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
80105cb2:	83 ec 0c             	sub    $0xc,%esp
80105cb5:	ff 75 f0             	pushl  -0x10(%ebp)
80105cb8:	e8 76 bb ff ff       	call   80101833 <iupdate>
80105cbd:	83 c4 10             	add    $0x10,%esp
  iunlockput(ip);
80105cc0:	83 ec 0c             	sub    $0xc,%esp
80105cc3:	ff 75 f0             	pushl  -0x10(%ebp)
80105cc6:	e8 76 bf ff ff       	call   80101c41 <iunlockput>
80105ccb:	83 c4 10             	add    $0x10,%esp

  end_op();
80105cce:	e8 ee d8 ff ff       	call   801035c1 <end_op>

  return 0;
80105cd3:	b8 00 00 00 00       	mov    $0x0,%eax
80105cd8:	eb 19                	jmp    80105cf3 <sys_unlink+0x1e1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105cda:	90                   	nop
  end_op();

  return 0;

bad:
  iunlockput(dp);
80105cdb:	83 ec 0c             	sub    $0xc,%esp
80105cde:	ff 75 f4             	pushl  -0xc(%ebp)
80105ce1:	e8 5b bf ff ff       	call   80101c41 <iunlockput>
80105ce6:	83 c4 10             	add    $0x10,%esp
  end_op();
80105ce9:	e8 d3 d8 ff ff       	call   801035c1 <end_op>
  return -1;
80105cee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105cf3:	c9                   	leave  
80105cf4:	c3                   	ret    

80105cf5 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105cf5:	55                   	push   %ebp
80105cf6:	89 e5                	mov    %esp,%ebp
80105cf8:	83 ec 38             	sub    $0x38,%esp
80105cfb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105cfe:	8b 55 10             	mov    0x10(%ebp),%edx
80105d01:	8b 45 14             	mov    0x14(%ebp),%eax
80105d04:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105d08:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105d0c:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105d10:	83 ec 08             	sub    $0x8,%esp
80105d13:	8d 45 de             	lea    -0x22(%ebp),%eax
80105d16:	50                   	push   %eax
80105d17:	ff 75 08             	pushl  0x8(%ebp)
80105d1a:	e8 4d c8 ff ff       	call   8010256c <nameiparent>
80105d1f:	83 c4 10             	add    $0x10,%esp
80105d22:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d25:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d29:	75 0a                	jne    80105d35 <create+0x40>
    return 0;
80105d2b:	b8 00 00 00 00       	mov    $0x0,%eax
80105d30:	e9 90 01 00 00       	jmp    80105ec5 <create+0x1d0>
  ilock(dp);
80105d35:	83 ec 0c             	sub    $0xc,%esp
80105d38:	ff 75 f4             	pushl  -0xc(%ebp)
80105d3b:	e8 d0 bc ff ff       	call   80101a10 <ilock>
80105d40:	83 c4 10             	add    $0x10,%esp

  if((ip = dirlookup(dp, name, &off)) != 0){
80105d43:	83 ec 04             	sub    $0x4,%esp
80105d46:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105d49:	50                   	push   %eax
80105d4a:	8d 45 de             	lea    -0x22(%ebp),%eax
80105d4d:	50                   	push   %eax
80105d4e:	ff 75 f4             	pushl  -0xc(%ebp)
80105d51:	e8 a5 c4 ff ff       	call   801021fb <dirlookup>
80105d56:	83 c4 10             	add    $0x10,%esp
80105d59:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d5c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d60:	74 50                	je     80105db2 <create+0xbd>
    iunlockput(dp);
80105d62:	83 ec 0c             	sub    $0xc,%esp
80105d65:	ff 75 f4             	pushl  -0xc(%ebp)
80105d68:	e8 d4 be ff ff       	call   80101c41 <iunlockput>
80105d6d:	83 c4 10             	add    $0x10,%esp
    ilock(ip);
80105d70:	83 ec 0c             	sub    $0xc,%esp
80105d73:	ff 75 f0             	pushl  -0x10(%ebp)
80105d76:	e8 95 bc ff ff       	call   80101a10 <ilock>
80105d7b:	83 c4 10             	add    $0x10,%esp
    if(type == T_FILE && ip->type == T_FILE)
80105d7e:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105d83:	75 15                	jne    80105d9a <create+0xa5>
80105d85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d88:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105d8c:	66 83 f8 02          	cmp    $0x2,%ax
80105d90:	75 08                	jne    80105d9a <create+0xa5>
      return ip;
80105d92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d95:	e9 2b 01 00 00       	jmp    80105ec5 <create+0x1d0>
    iunlockput(ip);
80105d9a:	83 ec 0c             	sub    $0xc,%esp
80105d9d:	ff 75 f0             	pushl  -0x10(%ebp)
80105da0:	e8 9c be ff ff       	call   80101c41 <iunlockput>
80105da5:	83 c4 10             	add    $0x10,%esp
    return 0;
80105da8:	b8 00 00 00 00       	mov    $0x0,%eax
80105dad:	e9 13 01 00 00       	jmp    80105ec5 <create+0x1d0>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105db2:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105db6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105db9:	8b 00                	mov    (%eax),%eax
80105dbb:	83 ec 08             	sub    $0x8,%esp
80105dbe:	52                   	push   %edx
80105dbf:	50                   	push   %eax
80105dc0:	e8 97 b9 ff ff       	call   8010175c <ialloc>
80105dc5:	83 c4 10             	add    $0x10,%esp
80105dc8:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105dcb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105dcf:	75 0d                	jne    80105dde <create+0xe9>
    panic("create: ialloc");
80105dd1:	83 ec 0c             	sub    $0xc,%esp
80105dd4:	68 e8 87 10 80       	push   $0x801087e8
80105dd9:	e8 c2 a7 ff ff       	call   801005a0 <panic>

  ilock(ip);
80105dde:	83 ec 0c             	sub    $0xc,%esp
80105de1:	ff 75 f0             	pushl  -0x10(%ebp)
80105de4:	e8 27 bc ff ff       	call   80101a10 <ilock>
80105de9:	83 c4 10             	add    $0x10,%esp
  ip->major = major;
80105dec:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105def:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105df3:	66 89 50 52          	mov    %dx,0x52(%eax)
  ip->minor = minor;
80105df7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dfa:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105dfe:	66 89 50 54          	mov    %dx,0x54(%eax)
  ip->nlink = 1;
80105e02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e05:	66 c7 40 56 01 00    	movw   $0x1,0x56(%eax)
  iupdate(ip);
80105e0b:	83 ec 0c             	sub    $0xc,%esp
80105e0e:	ff 75 f0             	pushl  -0x10(%ebp)
80105e11:	e8 1d ba ff ff       	call   80101833 <iupdate>
80105e16:	83 c4 10             	add    $0x10,%esp

  if(type == T_DIR){  // Create . and .. entries.
80105e19:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105e1e:	75 6a                	jne    80105e8a <create+0x195>
    dp->nlink++;  // for ".."
80105e20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e23:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105e27:	83 c0 01             	add    $0x1,%eax
80105e2a:	89 c2                	mov    %eax,%edx
80105e2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e2f:	66 89 50 56          	mov    %dx,0x56(%eax)
    iupdate(dp);
80105e33:	83 ec 0c             	sub    $0xc,%esp
80105e36:	ff 75 f4             	pushl  -0xc(%ebp)
80105e39:	e8 f5 b9 ff ff       	call   80101833 <iupdate>
80105e3e:	83 c4 10             	add    $0x10,%esp
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105e41:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e44:	8b 40 04             	mov    0x4(%eax),%eax
80105e47:	83 ec 04             	sub    $0x4,%esp
80105e4a:	50                   	push   %eax
80105e4b:	68 c2 87 10 80       	push   $0x801087c2
80105e50:	ff 75 f0             	pushl  -0x10(%ebp)
80105e53:	e8 5d c4 ff ff       	call   801022b5 <dirlink>
80105e58:	83 c4 10             	add    $0x10,%esp
80105e5b:	85 c0                	test   %eax,%eax
80105e5d:	78 1e                	js     80105e7d <create+0x188>
80105e5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e62:	8b 40 04             	mov    0x4(%eax),%eax
80105e65:	83 ec 04             	sub    $0x4,%esp
80105e68:	50                   	push   %eax
80105e69:	68 c4 87 10 80       	push   $0x801087c4
80105e6e:	ff 75 f0             	pushl  -0x10(%ebp)
80105e71:	e8 3f c4 ff ff       	call   801022b5 <dirlink>
80105e76:	83 c4 10             	add    $0x10,%esp
80105e79:	85 c0                	test   %eax,%eax
80105e7b:	79 0d                	jns    80105e8a <create+0x195>
      panic("create dots");
80105e7d:	83 ec 0c             	sub    $0xc,%esp
80105e80:	68 f7 87 10 80       	push   $0x801087f7
80105e85:	e8 16 a7 ff ff       	call   801005a0 <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105e8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e8d:	8b 40 04             	mov    0x4(%eax),%eax
80105e90:	83 ec 04             	sub    $0x4,%esp
80105e93:	50                   	push   %eax
80105e94:	8d 45 de             	lea    -0x22(%ebp),%eax
80105e97:	50                   	push   %eax
80105e98:	ff 75 f4             	pushl  -0xc(%ebp)
80105e9b:	e8 15 c4 ff ff       	call   801022b5 <dirlink>
80105ea0:	83 c4 10             	add    $0x10,%esp
80105ea3:	85 c0                	test   %eax,%eax
80105ea5:	79 0d                	jns    80105eb4 <create+0x1bf>
    panic("create: dirlink");
80105ea7:	83 ec 0c             	sub    $0xc,%esp
80105eaa:	68 03 88 10 80       	push   $0x80108803
80105eaf:	e8 ec a6 ff ff       	call   801005a0 <panic>

  iunlockput(dp);
80105eb4:	83 ec 0c             	sub    $0xc,%esp
80105eb7:	ff 75 f4             	pushl  -0xc(%ebp)
80105eba:	e8 82 bd ff ff       	call   80101c41 <iunlockput>
80105ebf:	83 c4 10             	add    $0x10,%esp

  return ip;
80105ec2:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105ec5:	c9                   	leave  
80105ec6:	c3                   	ret    

80105ec7 <sys_open>:

int
sys_open(void)
{
80105ec7:	55                   	push   %ebp
80105ec8:	89 e5                	mov    %esp,%ebp
80105eca:	83 ec 28             	sub    $0x28,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105ecd:	83 ec 08             	sub    $0x8,%esp
80105ed0:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105ed3:	50                   	push   %eax
80105ed4:	6a 00                	push   $0x0
80105ed6:	e8 e8 f6 ff ff       	call   801055c3 <argstr>
80105edb:	83 c4 10             	add    $0x10,%esp
80105ede:	85 c0                	test   %eax,%eax
80105ee0:	78 15                	js     80105ef7 <sys_open+0x30>
80105ee2:	83 ec 08             	sub    $0x8,%esp
80105ee5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105ee8:	50                   	push   %eax
80105ee9:	6a 01                	push   $0x1
80105eeb:	e8 3e f6 ff ff       	call   8010552e <argint>
80105ef0:	83 c4 10             	add    $0x10,%esp
80105ef3:	85 c0                	test   %eax,%eax
80105ef5:	79 0a                	jns    80105f01 <sys_open+0x3a>
    return -1;
80105ef7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105efc:	e9 61 01 00 00       	jmp    80106062 <sys_open+0x19b>

  begin_op();
80105f01:	e8 2f d6 ff ff       	call   80103535 <begin_op>

  if(omode & O_CREATE){
80105f06:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f09:	25 00 02 00 00       	and    $0x200,%eax
80105f0e:	85 c0                	test   %eax,%eax
80105f10:	74 2a                	je     80105f3c <sys_open+0x75>
    ip = create(path, T_FILE, 0, 0);
80105f12:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f15:	6a 00                	push   $0x0
80105f17:	6a 00                	push   $0x0
80105f19:	6a 02                	push   $0x2
80105f1b:	50                   	push   %eax
80105f1c:	e8 d4 fd ff ff       	call   80105cf5 <create>
80105f21:	83 c4 10             	add    $0x10,%esp
80105f24:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80105f27:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f2b:	75 75                	jne    80105fa2 <sys_open+0xdb>
      end_op();
80105f2d:	e8 8f d6 ff ff       	call   801035c1 <end_op>
      return -1;
80105f32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f37:	e9 26 01 00 00       	jmp    80106062 <sys_open+0x19b>
    }
  } else {
    if((ip = namei(path)) == 0){
80105f3c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f3f:	83 ec 0c             	sub    $0xc,%esp
80105f42:	50                   	push   %eax
80105f43:	e8 08 c6 ff ff       	call   80102550 <namei>
80105f48:	83 c4 10             	add    $0x10,%esp
80105f4b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f4e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f52:	75 0f                	jne    80105f63 <sys_open+0x9c>
      end_op();
80105f54:	e8 68 d6 ff ff       	call   801035c1 <end_op>
      return -1;
80105f59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f5e:	e9 ff 00 00 00       	jmp    80106062 <sys_open+0x19b>
    }
    ilock(ip);
80105f63:	83 ec 0c             	sub    $0xc,%esp
80105f66:	ff 75 f4             	pushl  -0xc(%ebp)
80105f69:	e8 a2 ba ff ff       	call   80101a10 <ilock>
80105f6e:	83 c4 10             	add    $0x10,%esp
    if(ip->type == T_DIR && omode != O_RDONLY){
80105f71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f74:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105f78:	66 83 f8 01          	cmp    $0x1,%ax
80105f7c:	75 24                	jne    80105fa2 <sys_open+0xdb>
80105f7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f81:	85 c0                	test   %eax,%eax
80105f83:	74 1d                	je     80105fa2 <sys_open+0xdb>
      iunlockput(ip);
80105f85:	83 ec 0c             	sub    $0xc,%esp
80105f88:	ff 75 f4             	pushl  -0xc(%ebp)
80105f8b:	e8 b1 bc ff ff       	call   80101c41 <iunlockput>
80105f90:	83 c4 10             	add    $0x10,%esp
      end_op();
80105f93:	e8 29 d6 ff ff       	call   801035c1 <end_op>
      return -1;
80105f98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f9d:	e9 c0 00 00 00       	jmp    80106062 <sys_open+0x19b>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105fa2:	e8 4c b0 ff ff       	call   80100ff3 <filealloc>
80105fa7:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105faa:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105fae:	74 17                	je     80105fc7 <sys_open+0x100>
80105fb0:	83 ec 0c             	sub    $0xc,%esp
80105fb3:	ff 75 f0             	pushl  -0x10(%ebp)
80105fb6:	e8 34 f7 ff ff       	call   801056ef <fdalloc>
80105fbb:	83 c4 10             	add    $0x10,%esp
80105fbe:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105fc1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105fc5:	79 2e                	jns    80105ff5 <sys_open+0x12e>
    if(f)
80105fc7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105fcb:	74 0e                	je     80105fdb <sys_open+0x114>
      fileclose(f);
80105fcd:	83 ec 0c             	sub    $0xc,%esp
80105fd0:	ff 75 f0             	pushl  -0x10(%ebp)
80105fd3:	e8 d9 b0 ff ff       	call   801010b1 <fileclose>
80105fd8:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80105fdb:	83 ec 0c             	sub    $0xc,%esp
80105fde:	ff 75 f4             	pushl  -0xc(%ebp)
80105fe1:	e8 5b bc ff ff       	call   80101c41 <iunlockput>
80105fe6:	83 c4 10             	add    $0x10,%esp
    end_op();
80105fe9:	e8 d3 d5 ff ff       	call   801035c1 <end_op>
    return -1;
80105fee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ff3:	eb 6d                	jmp    80106062 <sys_open+0x19b>
  }
  iunlock(ip);
80105ff5:	83 ec 0c             	sub    $0xc,%esp
80105ff8:	ff 75 f4             	pushl  -0xc(%ebp)
80105ffb:	e8 23 bb ff ff       	call   80101b23 <iunlock>
80106000:	83 c4 10             	add    $0x10,%esp
  end_op();
80106003:	e8 b9 d5 ff ff       	call   801035c1 <end_op>

  f->type = FD_INODE;
80106008:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010600b:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106011:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106014:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106017:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
8010601a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010601d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106024:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106027:	83 e0 01             	and    $0x1,%eax
8010602a:	85 c0                	test   %eax,%eax
8010602c:	0f 94 c0             	sete   %al
8010602f:	89 c2                	mov    %eax,%edx
80106031:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106034:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106037:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010603a:	83 e0 01             	and    $0x1,%eax
8010603d:	85 c0                	test   %eax,%eax
8010603f:	75 0a                	jne    8010604b <sys_open+0x184>
80106041:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106044:	83 e0 02             	and    $0x2,%eax
80106047:	85 c0                	test   %eax,%eax
80106049:	74 07                	je     80106052 <sys_open+0x18b>
8010604b:	b8 01 00 00 00       	mov    $0x1,%eax
80106050:	eb 05                	jmp    80106057 <sys_open+0x190>
80106052:	b8 00 00 00 00       	mov    $0x0,%eax
80106057:	89 c2                	mov    %eax,%edx
80106059:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010605c:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010605f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106062:	c9                   	leave  
80106063:	c3                   	ret    

80106064 <sys_mkdir>:

int
sys_mkdir(void)
{
80106064:	55                   	push   %ebp
80106065:	89 e5                	mov    %esp,%ebp
80106067:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010606a:	e8 c6 d4 ff ff       	call   80103535 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010606f:	83 ec 08             	sub    $0x8,%esp
80106072:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106075:	50                   	push   %eax
80106076:	6a 00                	push   $0x0
80106078:	e8 46 f5 ff ff       	call   801055c3 <argstr>
8010607d:	83 c4 10             	add    $0x10,%esp
80106080:	85 c0                	test   %eax,%eax
80106082:	78 1b                	js     8010609f <sys_mkdir+0x3b>
80106084:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106087:	6a 00                	push   $0x0
80106089:	6a 00                	push   $0x0
8010608b:	6a 01                	push   $0x1
8010608d:	50                   	push   %eax
8010608e:	e8 62 fc ff ff       	call   80105cf5 <create>
80106093:	83 c4 10             	add    $0x10,%esp
80106096:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106099:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010609d:	75 0c                	jne    801060ab <sys_mkdir+0x47>
    end_op();
8010609f:	e8 1d d5 ff ff       	call   801035c1 <end_op>
    return -1;
801060a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060a9:	eb 18                	jmp    801060c3 <sys_mkdir+0x5f>
  }
  iunlockput(ip);
801060ab:	83 ec 0c             	sub    $0xc,%esp
801060ae:	ff 75 f4             	pushl  -0xc(%ebp)
801060b1:	e8 8b bb ff ff       	call   80101c41 <iunlockput>
801060b6:	83 c4 10             	add    $0x10,%esp
  end_op();
801060b9:	e8 03 d5 ff ff       	call   801035c1 <end_op>
  return 0;
801060be:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060c3:	c9                   	leave  
801060c4:	c3                   	ret    

801060c5 <sys_mknod>:

int
sys_mknod(void)
{
801060c5:	55                   	push   %ebp
801060c6:	89 e5                	mov    %esp,%ebp
801060c8:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
801060cb:	e8 65 d4 ff ff       	call   80103535 <begin_op>
  if((argstr(0, &path)) < 0 ||
801060d0:	83 ec 08             	sub    $0x8,%esp
801060d3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060d6:	50                   	push   %eax
801060d7:	6a 00                	push   $0x0
801060d9:	e8 e5 f4 ff ff       	call   801055c3 <argstr>
801060de:	83 c4 10             	add    $0x10,%esp
801060e1:	85 c0                	test   %eax,%eax
801060e3:	78 4f                	js     80106134 <sys_mknod+0x6f>
     argint(1, &major) < 0 ||
801060e5:	83 ec 08             	sub    $0x8,%esp
801060e8:	8d 45 ec             	lea    -0x14(%ebp),%eax
801060eb:	50                   	push   %eax
801060ec:	6a 01                	push   $0x1
801060ee:	e8 3b f4 ff ff       	call   8010552e <argint>
801060f3:	83 c4 10             	add    $0x10,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
  if((argstr(0, &path)) < 0 ||
801060f6:	85 c0                	test   %eax,%eax
801060f8:	78 3a                	js     80106134 <sys_mknod+0x6f>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801060fa:	83 ec 08             	sub    $0x8,%esp
801060fd:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106100:	50                   	push   %eax
80106101:	6a 02                	push   $0x2
80106103:	e8 26 f4 ff ff       	call   8010552e <argint>
80106108:	83 c4 10             	add    $0x10,%esp
  char *path;
  int major, minor;

  begin_op();
  if((argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
8010610b:	85 c0                	test   %eax,%eax
8010610d:	78 25                	js     80106134 <sys_mknod+0x6f>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
8010610f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106112:	0f bf c8             	movswl %ax,%ecx
80106115:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106118:	0f bf d0             	movswl %ax,%edx
8010611b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  int major, minor;

  begin_op();
  if((argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010611e:	51                   	push   %ecx
8010611f:	52                   	push   %edx
80106120:	6a 03                	push   $0x3
80106122:	50                   	push   %eax
80106123:	e8 cd fb ff ff       	call   80105cf5 <create>
80106128:	83 c4 10             	add    $0x10,%esp
8010612b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010612e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106132:	75 0c                	jne    80106140 <sys_mknod+0x7b>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
80106134:	e8 88 d4 ff ff       	call   801035c1 <end_op>
    return -1;
80106139:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010613e:	eb 18                	jmp    80106158 <sys_mknod+0x93>
  }
  iunlockput(ip);
80106140:	83 ec 0c             	sub    $0xc,%esp
80106143:	ff 75 f4             	pushl  -0xc(%ebp)
80106146:	e8 f6 ba ff ff       	call   80101c41 <iunlockput>
8010614b:	83 c4 10             	add    $0x10,%esp
  end_op();
8010614e:	e8 6e d4 ff ff       	call   801035c1 <end_op>
  return 0;
80106153:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106158:	c9                   	leave  
80106159:	c3                   	ret    

8010615a <sys_chdir>:

int
sys_chdir(void)
{
8010615a:	55                   	push   %ebp
8010615b:	89 e5                	mov    %esp,%ebp
8010615d:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80106160:	e8 23 e1 ff ff       	call   80104288 <myproc>
80106165:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  begin_op();
80106168:	e8 c8 d3 ff ff       	call   80103535 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
8010616d:	83 ec 08             	sub    $0x8,%esp
80106170:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106173:	50                   	push   %eax
80106174:	6a 00                	push   $0x0
80106176:	e8 48 f4 ff ff       	call   801055c3 <argstr>
8010617b:	83 c4 10             	add    $0x10,%esp
8010617e:	85 c0                	test   %eax,%eax
80106180:	78 18                	js     8010619a <sys_chdir+0x40>
80106182:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106185:	83 ec 0c             	sub    $0xc,%esp
80106188:	50                   	push   %eax
80106189:	e8 c2 c3 ff ff       	call   80102550 <namei>
8010618e:	83 c4 10             	add    $0x10,%esp
80106191:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106194:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106198:	75 0c                	jne    801061a6 <sys_chdir+0x4c>
    end_op();
8010619a:	e8 22 d4 ff ff       	call   801035c1 <end_op>
    return -1;
8010619f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061a4:	eb 68                	jmp    8010620e <sys_chdir+0xb4>
  }
  ilock(ip);
801061a6:	83 ec 0c             	sub    $0xc,%esp
801061a9:	ff 75 f0             	pushl  -0x10(%ebp)
801061ac:	e8 5f b8 ff ff       	call   80101a10 <ilock>
801061b1:	83 c4 10             	add    $0x10,%esp
  if(ip->type != T_DIR){
801061b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061b7:	0f b7 40 50          	movzwl 0x50(%eax),%eax
801061bb:	66 83 f8 01          	cmp    $0x1,%ax
801061bf:	74 1a                	je     801061db <sys_chdir+0x81>
    iunlockput(ip);
801061c1:	83 ec 0c             	sub    $0xc,%esp
801061c4:	ff 75 f0             	pushl  -0x10(%ebp)
801061c7:	e8 75 ba ff ff       	call   80101c41 <iunlockput>
801061cc:	83 c4 10             	add    $0x10,%esp
    end_op();
801061cf:	e8 ed d3 ff ff       	call   801035c1 <end_op>
    return -1;
801061d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061d9:	eb 33                	jmp    8010620e <sys_chdir+0xb4>
  }
  iunlock(ip);
801061db:	83 ec 0c             	sub    $0xc,%esp
801061de:	ff 75 f0             	pushl  -0x10(%ebp)
801061e1:	e8 3d b9 ff ff       	call   80101b23 <iunlock>
801061e6:	83 c4 10             	add    $0x10,%esp
  iput(curproc->cwd);
801061e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ec:	8b 40 68             	mov    0x68(%eax),%eax
801061ef:	83 ec 0c             	sub    $0xc,%esp
801061f2:	50                   	push   %eax
801061f3:	e8 79 b9 ff ff       	call   80101b71 <iput>
801061f8:	83 c4 10             	add    $0x10,%esp
  end_op();
801061fb:	e8 c1 d3 ff ff       	call   801035c1 <end_op>
  curproc->cwd = ip;
80106200:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106203:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106206:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106209:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010620e:	c9                   	leave  
8010620f:	c3                   	ret    

80106210 <sys_exec>:

int
sys_exec(void)
{
80106210:	55                   	push   %ebp
80106211:	89 e5                	mov    %esp,%ebp
80106213:	81 ec 98 00 00 00    	sub    $0x98,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106219:	83 ec 08             	sub    $0x8,%esp
8010621c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010621f:	50                   	push   %eax
80106220:	6a 00                	push   $0x0
80106222:	e8 9c f3 ff ff       	call   801055c3 <argstr>
80106227:	83 c4 10             	add    $0x10,%esp
8010622a:	85 c0                	test   %eax,%eax
8010622c:	78 18                	js     80106246 <sys_exec+0x36>
8010622e:	83 ec 08             	sub    $0x8,%esp
80106231:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106237:	50                   	push   %eax
80106238:	6a 01                	push   $0x1
8010623a:	e8 ef f2 ff ff       	call   8010552e <argint>
8010623f:	83 c4 10             	add    $0x10,%esp
80106242:	85 c0                	test   %eax,%eax
80106244:	79 0a                	jns    80106250 <sys_exec+0x40>
    return -1;
80106246:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010624b:	e9 c6 00 00 00       	jmp    80106316 <sys_exec+0x106>
  }
  memset(argv, 0, sizeof(argv));
80106250:	83 ec 04             	sub    $0x4,%esp
80106253:	68 80 00 00 00       	push   $0x80
80106258:	6a 00                	push   $0x0
8010625a:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106260:	50                   	push   %eax
80106261:	e8 9c ef ff ff       	call   80105202 <memset>
80106266:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80106269:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106270:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106273:	83 f8 1f             	cmp    $0x1f,%eax
80106276:	76 0a                	jbe    80106282 <sys_exec+0x72>
      return -1;
80106278:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010627d:	e9 94 00 00 00       	jmp    80106316 <sys_exec+0x106>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106282:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106285:	c1 e0 02             	shl    $0x2,%eax
80106288:	89 c2                	mov    %eax,%edx
8010628a:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106290:	01 c2                	add    %eax,%edx
80106292:	83 ec 08             	sub    $0x8,%esp
80106295:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
8010629b:	50                   	push   %eax
8010629c:	52                   	push   %edx
8010629d:	e8 e9 f1 ff ff       	call   8010548b <fetchint>
801062a2:	83 c4 10             	add    $0x10,%esp
801062a5:	85 c0                	test   %eax,%eax
801062a7:	79 07                	jns    801062b0 <sys_exec+0xa0>
      return -1;
801062a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062ae:	eb 66                	jmp    80106316 <sys_exec+0x106>
    if(uarg == 0){
801062b0:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801062b6:	85 c0                	test   %eax,%eax
801062b8:	75 27                	jne    801062e1 <sys_exec+0xd1>
      argv[i] = 0;
801062ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062bd:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801062c4:	00 00 00 00 
      break;
801062c8:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801062c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062cc:	83 ec 08             	sub    $0x8,%esp
801062cf:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801062d5:	52                   	push   %edx
801062d6:	50                   	push   %eax
801062d7:	e8 ba a8 ff ff       	call   80100b96 <exec>
801062dc:	83 c4 10             	add    $0x10,%esp
801062df:	eb 35                	jmp    80106316 <sys_exec+0x106>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
801062e1:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801062e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062ea:	c1 e2 02             	shl    $0x2,%edx
801062ed:	01 c2                	add    %eax,%edx
801062ef:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801062f5:	83 ec 08             	sub    $0x8,%esp
801062f8:	52                   	push   %edx
801062f9:	50                   	push   %eax
801062fa:	e8 cb f1 ff ff       	call   801054ca <fetchstr>
801062ff:	83 c4 10             	add    $0x10,%esp
80106302:	85 c0                	test   %eax,%eax
80106304:	79 07                	jns    8010630d <sys_exec+0xfd>
      return -1;
80106306:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010630b:	eb 09                	jmp    80106316 <sys_exec+0x106>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
8010630d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106311:	e9 5a ff ff ff       	jmp    80106270 <sys_exec+0x60>
  return exec(path, argv);
}
80106316:	c9                   	leave  
80106317:	c3                   	ret    

80106318 <sys_pipe>:

int
sys_pipe(void)
{
80106318:	55                   	push   %ebp
80106319:	89 e5                	mov    %esp,%ebp
8010631b:	83 ec 28             	sub    $0x28,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
8010631e:	83 ec 04             	sub    $0x4,%esp
80106321:	6a 08                	push   $0x8
80106323:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106326:	50                   	push   %eax
80106327:	6a 00                	push   $0x0
80106329:	e8 2d f2 ff ff       	call   8010555b <argptr>
8010632e:	83 c4 10             	add    $0x10,%esp
80106331:	85 c0                	test   %eax,%eax
80106333:	79 0a                	jns    8010633f <sys_pipe+0x27>
    return -1;
80106335:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010633a:	e9 b0 00 00 00       	jmp    801063ef <sys_pipe+0xd7>
  if(pipealloc(&rf, &wf) < 0)
8010633f:	83 ec 08             	sub    $0x8,%esp
80106342:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106345:	50                   	push   %eax
80106346:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106349:	50                   	push   %eax
8010634a:	e8 70 da ff ff       	call   80103dbf <pipealloc>
8010634f:	83 c4 10             	add    $0x10,%esp
80106352:	85 c0                	test   %eax,%eax
80106354:	79 0a                	jns    80106360 <sys_pipe+0x48>
    return -1;
80106356:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010635b:	e9 8f 00 00 00       	jmp    801063ef <sys_pipe+0xd7>
  fd0 = -1;
80106360:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106367:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010636a:	83 ec 0c             	sub    $0xc,%esp
8010636d:	50                   	push   %eax
8010636e:	e8 7c f3 ff ff       	call   801056ef <fdalloc>
80106373:	83 c4 10             	add    $0x10,%esp
80106376:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106379:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010637d:	78 18                	js     80106397 <sys_pipe+0x7f>
8010637f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106382:	83 ec 0c             	sub    $0xc,%esp
80106385:	50                   	push   %eax
80106386:	e8 64 f3 ff ff       	call   801056ef <fdalloc>
8010638b:	83 c4 10             	add    $0x10,%esp
8010638e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106391:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106395:	79 40                	jns    801063d7 <sys_pipe+0xbf>
    if(fd0 >= 0)
80106397:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010639b:	78 15                	js     801063b2 <sys_pipe+0x9a>
      myproc()->ofile[fd0] = 0;
8010639d:	e8 e6 de ff ff       	call   80104288 <myproc>
801063a2:	89 c2                	mov    %eax,%edx
801063a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063a7:	83 c0 08             	add    $0x8,%eax
801063aa:	c7 44 82 08 00 00 00 	movl   $0x0,0x8(%edx,%eax,4)
801063b1:	00 
    fileclose(rf);
801063b2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801063b5:	83 ec 0c             	sub    $0xc,%esp
801063b8:	50                   	push   %eax
801063b9:	e8 f3 ac ff ff       	call   801010b1 <fileclose>
801063be:	83 c4 10             	add    $0x10,%esp
    fileclose(wf);
801063c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801063c4:	83 ec 0c             	sub    $0xc,%esp
801063c7:	50                   	push   %eax
801063c8:	e8 e4 ac ff ff       	call   801010b1 <fileclose>
801063cd:	83 c4 10             	add    $0x10,%esp
    return -1;
801063d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063d5:	eb 18                	jmp    801063ef <sys_pipe+0xd7>
  }
  fd[0] = fd0;
801063d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801063da:	8b 55 f4             	mov    -0xc(%ebp),%edx
801063dd:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801063df:	8b 45 ec             	mov    -0x14(%ebp),%eax
801063e2:	8d 50 04             	lea    0x4(%eax),%edx
801063e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063e8:	89 02                	mov    %eax,(%edx)
  return 0;
801063ea:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063ef:	c9                   	leave  
801063f0:	c3                   	ret    

801063f1 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801063f1:	55                   	push   %ebp
801063f2:	89 e5                	mov    %esp,%ebp
801063f4:	83 ec 08             	sub    $0x8,%esp
  return fork();
801063f7:	e8 c6 e1 ff ff       	call   801045c2 <fork>
}
801063fc:	c9                   	leave  
801063fd:	c3                   	ret    

801063fe <sys_exit>:

int
sys_exit(void)
{
801063fe:	55                   	push   %ebp
801063ff:	89 e5                	mov    %esp,%ebp
80106401:	83 ec 08             	sub    $0x8,%esp
  exit();
80106404:	e8 36 e3 ff ff       	call   8010473f <exit>
  return 0;  // not reached
80106409:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010640e:	c9                   	leave  
8010640f:	c3                   	ret    

80106410 <sys_wait>:

int
sys_wait(void)
{
80106410:	55                   	push   %ebp
80106411:	89 e5                	mov    %esp,%ebp
80106413:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106416:	e8 44 e4 ff ff       	call   8010485f <wait>
}
8010641b:	c9                   	leave  
8010641c:	c3                   	ret    

8010641d <sys_kill>:

int
sys_kill(void)
{
8010641d:	55                   	push   %ebp
8010641e:	89 e5                	mov    %esp,%ebp
80106420:	83 ec 18             	sub    $0x18,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106423:	83 ec 08             	sub    $0x8,%esp
80106426:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106429:	50                   	push   %eax
8010642a:	6a 00                	push   $0x0
8010642c:	e8 fd f0 ff ff       	call   8010552e <argint>
80106431:	83 c4 10             	add    $0x10,%esp
80106434:	85 c0                	test   %eax,%eax
80106436:	79 07                	jns    8010643f <sys_kill+0x22>
    return -1;
80106438:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010643d:	eb 0f                	jmp    8010644e <sys_kill+0x31>
  return kill(pid);
8010643f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106442:	83 ec 0c             	sub    $0xc,%esp
80106445:	50                   	push   %eax
80106446:	e8 44 e8 ff ff       	call   80104c8f <kill>
8010644b:	83 c4 10             	add    $0x10,%esp
}
8010644e:	c9                   	leave  
8010644f:	c3                   	ret    

80106450 <sys_getpid>:

int
sys_getpid(void)
{
80106450:	55                   	push   %ebp
80106451:	89 e5                	mov    %esp,%ebp
80106453:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80106456:	e8 2d de ff ff       	call   80104288 <myproc>
8010645b:	8b 40 10             	mov    0x10(%eax),%eax
}
8010645e:	c9                   	leave  
8010645f:	c3                   	ret    

80106460 <sys_sbrk>:

int
sys_sbrk(void)
{
80106460:	55                   	push   %ebp
80106461:	89 e5                	mov    %esp,%ebp
80106463:	83 ec 18             	sub    $0x18,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106466:	83 ec 08             	sub    $0x8,%esp
80106469:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010646c:	50                   	push   %eax
8010646d:	6a 00                	push   $0x0
8010646f:	e8 ba f0 ff ff       	call   8010552e <argint>
80106474:	83 c4 10             	add    $0x10,%esp
80106477:	85 c0                	test   %eax,%eax
80106479:	79 07                	jns    80106482 <sys_sbrk+0x22>
    return -1;
8010647b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106480:	eb 27                	jmp    801064a9 <sys_sbrk+0x49>
  addr = myproc()->sz;
80106482:	e8 01 de ff ff       	call   80104288 <myproc>
80106487:	8b 00                	mov    (%eax),%eax
80106489:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010648c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010648f:	83 ec 0c             	sub    $0xc,%esp
80106492:	50                   	push   %eax
80106493:	e8 8f e0 ff ff       	call   80104527 <growproc>
80106498:	83 c4 10             	add    $0x10,%esp
8010649b:	85 c0                	test   %eax,%eax
8010649d:	79 07                	jns    801064a6 <sys_sbrk+0x46>
    return -1;
8010649f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064a4:	eb 03                	jmp    801064a9 <sys_sbrk+0x49>
  return addr;
801064a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801064a9:	c9                   	leave  
801064aa:	c3                   	ret    

801064ab <sys_sleep>:

int
sys_sleep(void)
{
801064ab:	55                   	push   %ebp
801064ac:	89 e5                	mov    %esp,%ebp
801064ae:	83 ec 18             	sub    $0x18,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
801064b1:	83 ec 08             	sub    $0x8,%esp
801064b4:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064b7:	50                   	push   %eax
801064b8:	6a 00                	push   $0x0
801064ba:	e8 6f f0 ff ff       	call   8010552e <argint>
801064bf:	83 c4 10             	add    $0x10,%esp
801064c2:	85 c0                	test   %eax,%eax
801064c4:	79 07                	jns    801064cd <sys_sleep+0x22>
    return -1;
801064c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064cb:	eb 76                	jmp    80106543 <sys_sleep+0x98>
  acquire(&tickslock);
801064cd:	83 ec 0c             	sub    $0xc,%esp
801064d0:	68 e0 5c 11 80       	push   $0x80115ce0
801064d5:	e8 b1 ea ff ff       	call   80104f8b <acquire>
801064da:	83 c4 10             	add    $0x10,%esp
  ticks0 = ticks;
801064dd:	a1 20 65 11 80       	mov    0x80116520,%eax
801064e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801064e5:	eb 38                	jmp    8010651f <sys_sleep+0x74>
    if(myproc()->killed){
801064e7:	e8 9c dd ff ff       	call   80104288 <myproc>
801064ec:	8b 40 24             	mov    0x24(%eax),%eax
801064ef:	85 c0                	test   %eax,%eax
801064f1:	74 17                	je     8010650a <sys_sleep+0x5f>
      release(&tickslock);
801064f3:	83 ec 0c             	sub    $0xc,%esp
801064f6:	68 e0 5c 11 80       	push   $0x80115ce0
801064fb:	e8 f9 ea ff ff       	call   80104ff9 <release>
80106500:	83 c4 10             	add    $0x10,%esp
      return -1;
80106503:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106508:	eb 39                	jmp    80106543 <sys_sleep+0x98>
    }
    sleep(&ticks, &tickslock);
8010650a:	83 ec 08             	sub    $0x8,%esp
8010650d:	68 e0 5c 11 80       	push   $0x80115ce0
80106512:	68 20 65 11 80       	push   $0x80116520
80106517:	e8 56 e6 ff ff       	call   80104b72 <sleep>
8010651c:	83 c4 10             	add    $0x10,%esp

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
8010651f:	a1 20 65 11 80       	mov    0x80116520,%eax
80106524:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106527:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010652a:	39 d0                	cmp    %edx,%eax
8010652c:	72 b9                	jb     801064e7 <sys_sleep+0x3c>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
8010652e:	83 ec 0c             	sub    $0xc,%esp
80106531:	68 e0 5c 11 80       	push   $0x80115ce0
80106536:	e8 be ea ff ff       	call   80104ff9 <release>
8010653b:	83 c4 10             	add    $0x10,%esp
  return 0;
8010653e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106543:	c9                   	leave  
80106544:	c3                   	ret    

80106545 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106545:	55                   	push   %ebp
80106546:	89 e5                	mov    %esp,%ebp
80106548:	83 ec 18             	sub    $0x18,%esp
  uint xticks;

  acquire(&tickslock);
8010654b:	83 ec 0c             	sub    $0xc,%esp
8010654e:	68 e0 5c 11 80       	push   $0x80115ce0
80106553:	e8 33 ea ff ff       	call   80104f8b <acquire>
80106558:	83 c4 10             	add    $0x10,%esp
  xticks = ticks;
8010655b:	a1 20 65 11 80       	mov    0x80116520,%eax
80106560:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106563:	83 ec 0c             	sub    $0xc,%esp
80106566:	68 e0 5c 11 80       	push   $0x80115ce0
8010656b:	e8 89 ea ff ff       	call   80104ff9 <release>
80106570:	83 c4 10             	add    $0x10,%esp
  return xticks;
80106573:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106576:	c9                   	leave  
80106577:	c3                   	ret    

80106578 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106578:	1e                   	push   %ds
  pushl %es
80106579:	06                   	push   %es
  pushl %fs
8010657a:	0f a0                	push   %fs
  pushl %gs
8010657c:	0f a8                	push   %gs
  pushal
8010657e:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
8010657f:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106583:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106585:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80106587:	54                   	push   %esp
  call trap
80106588:	e8 d7 01 00 00       	call   80106764 <trap>
  addl $4, %esp
8010658d:	83 c4 04             	add    $0x4,%esp

80106590 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106590:	61                   	popa   
  popl %gs
80106591:	0f a9                	pop    %gs
  popl %fs
80106593:	0f a1                	pop    %fs
  popl %es
80106595:	07                   	pop    %es
  popl %ds
80106596:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106597:	83 c4 08             	add    $0x8,%esp
  iret
8010659a:	cf                   	iret   

8010659b <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
8010659b:	55                   	push   %ebp
8010659c:	89 e5                	mov    %esp,%ebp
8010659e:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801065a1:	8b 45 0c             	mov    0xc(%ebp),%eax
801065a4:	83 e8 01             	sub    $0x1,%eax
801065a7:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801065ab:	8b 45 08             	mov    0x8(%ebp),%eax
801065ae:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801065b2:	8b 45 08             	mov    0x8(%ebp),%eax
801065b5:	c1 e8 10             	shr    $0x10,%eax
801065b8:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801065bc:	8d 45 fa             	lea    -0x6(%ebp),%eax
801065bf:	0f 01 18             	lidtl  (%eax)
}
801065c2:	90                   	nop
801065c3:	c9                   	leave  
801065c4:	c3                   	ret    

801065c5 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801065c5:	55                   	push   %ebp
801065c6:	89 e5                	mov    %esp,%ebp
801065c8:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801065cb:	0f 20 d0             	mov    %cr2,%eax
801065ce:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
801065d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801065d4:	c9                   	leave  
801065d5:	c3                   	ret    

801065d6 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801065d6:	55                   	push   %ebp
801065d7:	89 e5                	mov    %esp,%ebp
801065d9:	83 ec 18             	sub    $0x18,%esp
  int i;

  for(i = 0; i < 256; i++)
801065dc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801065e3:	e9 c3 00 00 00       	jmp    801066ab <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801065e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065eb:	8b 04 85 78 b0 10 80 	mov    -0x7fef4f88(,%eax,4),%eax
801065f2:	89 c2                	mov    %eax,%edx
801065f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065f7:	66 89 14 c5 20 5d 11 	mov    %dx,-0x7feea2e0(,%eax,8)
801065fe:	80 
801065ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106602:	66 c7 04 c5 22 5d 11 	movw   $0x8,-0x7feea2de(,%eax,8)
80106609:	80 08 00 
8010660c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010660f:	0f b6 14 c5 24 5d 11 	movzbl -0x7feea2dc(,%eax,8),%edx
80106616:	80 
80106617:	83 e2 e0             	and    $0xffffffe0,%edx
8010661a:	88 14 c5 24 5d 11 80 	mov    %dl,-0x7feea2dc(,%eax,8)
80106621:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106624:	0f b6 14 c5 24 5d 11 	movzbl -0x7feea2dc(,%eax,8),%edx
8010662b:	80 
8010662c:	83 e2 1f             	and    $0x1f,%edx
8010662f:	88 14 c5 24 5d 11 80 	mov    %dl,-0x7feea2dc(,%eax,8)
80106636:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106639:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
80106640:	80 
80106641:	83 e2 f0             	and    $0xfffffff0,%edx
80106644:	83 ca 0e             	or     $0xe,%edx
80106647:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
8010664e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106651:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
80106658:	80 
80106659:	83 e2 ef             	and    $0xffffffef,%edx
8010665c:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
80106663:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106666:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
8010666d:	80 
8010666e:	83 e2 9f             	and    $0xffffff9f,%edx
80106671:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
80106678:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010667b:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
80106682:	80 
80106683:	83 ca 80             	or     $0xffffff80,%edx
80106686:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
8010668d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106690:	8b 04 85 78 b0 10 80 	mov    -0x7fef4f88(,%eax,4),%eax
80106697:	c1 e8 10             	shr    $0x10,%eax
8010669a:	89 c2                	mov    %eax,%edx
8010669c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010669f:	66 89 14 c5 26 5d 11 	mov    %dx,-0x7feea2da(,%eax,8)
801066a6:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801066a7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801066ab:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801066b2:	0f 8e 30 ff ff ff    	jle    801065e8 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801066b8:	a1 78 b1 10 80       	mov    0x8010b178,%eax
801066bd:	66 a3 20 5f 11 80    	mov    %ax,0x80115f20
801066c3:	66 c7 05 22 5f 11 80 	movw   $0x8,0x80115f22
801066ca:	08 00 
801066cc:	0f b6 05 24 5f 11 80 	movzbl 0x80115f24,%eax
801066d3:	83 e0 e0             	and    $0xffffffe0,%eax
801066d6:	a2 24 5f 11 80       	mov    %al,0x80115f24
801066db:	0f b6 05 24 5f 11 80 	movzbl 0x80115f24,%eax
801066e2:	83 e0 1f             	and    $0x1f,%eax
801066e5:	a2 24 5f 11 80       	mov    %al,0x80115f24
801066ea:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
801066f1:	83 c8 0f             	or     $0xf,%eax
801066f4:	a2 25 5f 11 80       	mov    %al,0x80115f25
801066f9:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
80106700:	83 e0 ef             	and    $0xffffffef,%eax
80106703:	a2 25 5f 11 80       	mov    %al,0x80115f25
80106708:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
8010670f:	83 c8 60             	or     $0x60,%eax
80106712:	a2 25 5f 11 80       	mov    %al,0x80115f25
80106717:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
8010671e:	83 c8 80             	or     $0xffffff80,%eax
80106721:	a2 25 5f 11 80       	mov    %al,0x80115f25
80106726:	a1 78 b1 10 80       	mov    0x8010b178,%eax
8010672b:	c1 e8 10             	shr    $0x10,%eax
8010672e:	66 a3 26 5f 11 80    	mov    %ax,0x80115f26

  initlock(&tickslock, "time");
80106734:	83 ec 08             	sub    $0x8,%esp
80106737:	68 14 88 10 80       	push   $0x80108814
8010673c:	68 e0 5c 11 80       	push   $0x80115ce0
80106741:	e8 23 e8 ff ff       	call   80104f69 <initlock>
80106746:	83 c4 10             	add    $0x10,%esp
}
80106749:	90                   	nop
8010674a:	c9                   	leave  
8010674b:	c3                   	ret    

8010674c <idtinit>:

void
idtinit(void)
{
8010674c:	55                   	push   %ebp
8010674d:	89 e5                	mov    %esp,%ebp
  lidt(idt, sizeof(idt));
8010674f:	68 00 08 00 00       	push   $0x800
80106754:	68 20 5d 11 80       	push   $0x80115d20
80106759:	e8 3d fe ff ff       	call   8010659b <lidt>
8010675e:	83 c4 08             	add    $0x8,%esp
}
80106761:	90                   	nop
80106762:	c9                   	leave  
80106763:	c3                   	ret    

80106764 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106764:	55                   	push   %ebp
80106765:	89 e5                	mov    %esp,%ebp
80106767:	57                   	push   %edi
80106768:	56                   	push   %esi
80106769:	53                   	push   %ebx
8010676a:	83 ec 1c             	sub    $0x1c,%esp
  if(tf->trapno == T_SYSCALL){
8010676d:	8b 45 08             	mov    0x8(%ebp),%eax
80106770:	8b 40 30             	mov    0x30(%eax),%eax
80106773:	83 f8 40             	cmp    $0x40,%eax
80106776:	75 3d                	jne    801067b5 <trap+0x51>
    if(myproc()->killed)
80106778:	e8 0b db ff ff       	call   80104288 <myproc>
8010677d:	8b 40 24             	mov    0x24(%eax),%eax
80106780:	85 c0                	test   %eax,%eax
80106782:	74 05                	je     80106789 <trap+0x25>
      exit();
80106784:	e8 b6 df ff ff       	call   8010473f <exit>
    myproc()->tf = tf;
80106789:	e8 fa da ff ff       	call   80104288 <myproc>
8010678e:	89 c2                	mov    %eax,%edx
80106790:	8b 45 08             	mov    0x8(%ebp),%eax
80106793:	89 42 18             	mov    %eax,0x18(%edx)
    syscall();
80106796:	e8 5f ee ff ff       	call   801055fa <syscall>
    if(myproc()->killed)
8010679b:	e8 e8 da ff ff       	call   80104288 <myproc>
801067a0:	8b 40 24             	mov    0x24(%eax),%eax
801067a3:	85 c0                	test   %eax,%eax
801067a5:	0f 84 04 02 00 00    	je     801069af <trap+0x24b>
      exit();
801067ab:	e8 8f df ff ff       	call   8010473f <exit>
    return;
801067b0:	e9 fa 01 00 00       	jmp    801069af <trap+0x24b>
  }

  switch(tf->trapno){
801067b5:	8b 45 08             	mov    0x8(%ebp),%eax
801067b8:	8b 40 30             	mov    0x30(%eax),%eax
801067bb:	83 e8 20             	sub    $0x20,%eax
801067be:	83 f8 1f             	cmp    $0x1f,%eax
801067c1:	0f 87 b5 00 00 00    	ja     8010687c <trap+0x118>
801067c7:	8b 04 85 bc 88 10 80 	mov    -0x7fef7744(,%eax,4),%eax
801067ce:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
801067d0:	e8 1a da ff ff       	call   801041ef <cpuid>
801067d5:	85 c0                	test   %eax,%eax
801067d7:	75 3d                	jne    80106816 <trap+0xb2>
      acquire(&tickslock);
801067d9:	83 ec 0c             	sub    $0xc,%esp
801067dc:	68 e0 5c 11 80       	push   $0x80115ce0
801067e1:	e8 a5 e7 ff ff       	call   80104f8b <acquire>
801067e6:	83 c4 10             	add    $0x10,%esp
      ticks++;
801067e9:	a1 20 65 11 80       	mov    0x80116520,%eax
801067ee:	83 c0 01             	add    $0x1,%eax
801067f1:	a3 20 65 11 80       	mov    %eax,0x80116520
      wakeup(&ticks);
801067f6:	83 ec 0c             	sub    $0xc,%esp
801067f9:	68 20 65 11 80       	push   $0x80116520
801067fe:	e8 55 e4 ff ff       	call   80104c58 <wakeup>
80106803:	83 c4 10             	add    $0x10,%esp
      release(&tickslock);
80106806:	83 ec 0c             	sub    $0xc,%esp
80106809:	68 e0 5c 11 80       	push   $0x80115ce0
8010680e:	e8 e6 e7 ff ff       	call   80104ff9 <release>
80106813:	83 c4 10             	add    $0x10,%esp
    }
    lapiceoi();
80106816:	e8 f2 c7 ff ff       	call   8010300d <lapiceoi>
    break;
8010681b:	e9 0f 01 00 00       	jmp    8010692f <trap+0x1cb>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106820:	e8 62 c0 ff ff       	call   80102887 <ideintr>
    lapiceoi();
80106825:	e8 e3 c7 ff ff       	call   8010300d <lapiceoi>
    break;
8010682a:	e9 00 01 00 00       	jmp    8010692f <trap+0x1cb>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
8010682f:	e8 22 c6 ff ff       	call   80102e56 <kbdintr>
    lapiceoi();
80106834:	e8 d4 c7 ff ff       	call   8010300d <lapiceoi>
    break;
80106839:	e9 f1 00 00 00       	jmp    8010692f <trap+0x1cb>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
8010683e:	e8 40 03 00 00       	call   80106b83 <uartintr>
    lapiceoi();
80106843:	e8 c5 c7 ff ff       	call   8010300d <lapiceoi>
    break;
80106848:	e9 e2 00 00 00       	jmp    8010692f <trap+0x1cb>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010684d:	8b 45 08             	mov    0x8(%ebp),%eax
80106850:	8b 70 38             	mov    0x38(%eax),%esi
            cpuid(), tf->cs, tf->eip);
80106853:	8b 45 08             	mov    0x8(%ebp),%eax
80106856:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010685a:	0f b7 d8             	movzwl %ax,%ebx
8010685d:	e8 8d d9 ff ff       	call   801041ef <cpuid>
80106862:	56                   	push   %esi
80106863:	53                   	push   %ebx
80106864:	50                   	push   %eax
80106865:	68 1c 88 10 80       	push   $0x8010881c
8010686a:	e8 91 9b ff ff       	call   80100400 <cprintf>
8010686f:	83 c4 10             	add    $0x10,%esp
            cpuid(), tf->cs, tf->eip);
    lapiceoi();
80106872:	e8 96 c7 ff ff       	call   8010300d <lapiceoi>
    break;
80106877:	e9 b3 00 00 00       	jmp    8010692f <trap+0x1cb>

  //PAGEBREAK: 13
  default:
    if(myproc() == 0 || (tf->cs&3) == 0){
8010687c:	e8 07 da ff ff       	call   80104288 <myproc>
80106881:	85 c0                	test   %eax,%eax
80106883:	74 11                	je     80106896 <trap+0x132>
80106885:	8b 45 08             	mov    0x8(%ebp),%eax
80106888:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010688c:	0f b7 c0             	movzwl %ax,%eax
8010688f:	83 e0 03             	and    $0x3,%eax
80106892:	85 c0                	test   %eax,%eax
80106894:	75 3b                	jne    801068d1 <trap+0x16d>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106896:	e8 2a fd ff ff       	call   801065c5 <rcr2>
8010689b:	89 c6                	mov    %eax,%esi
8010689d:	8b 45 08             	mov    0x8(%ebp),%eax
801068a0:	8b 58 38             	mov    0x38(%eax),%ebx
801068a3:	e8 47 d9 ff ff       	call   801041ef <cpuid>
801068a8:	89 c2                	mov    %eax,%edx
801068aa:	8b 45 08             	mov    0x8(%ebp),%eax
801068ad:	8b 40 30             	mov    0x30(%eax),%eax
801068b0:	83 ec 0c             	sub    $0xc,%esp
801068b3:	56                   	push   %esi
801068b4:	53                   	push   %ebx
801068b5:	52                   	push   %edx
801068b6:	50                   	push   %eax
801068b7:	68 40 88 10 80       	push   $0x80108840
801068bc:	e8 3f 9b ff ff       	call   80100400 <cprintf>
801068c1:	83 c4 20             	add    $0x20,%esp
              tf->trapno, cpuid(), tf->eip, rcr2());
      panic("trap");
801068c4:	83 ec 0c             	sub    $0xc,%esp
801068c7:	68 72 88 10 80       	push   $0x80108872
801068cc:	e8 cf 9c ff ff       	call   801005a0 <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801068d1:	e8 ef fc ff ff       	call   801065c5 <rcr2>
801068d6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801068d9:	8b 45 08             	mov    0x8(%ebp),%eax
801068dc:	8b 78 38             	mov    0x38(%eax),%edi
801068df:	e8 0b d9 ff ff       	call   801041ef <cpuid>
801068e4:	89 45 e0             	mov    %eax,-0x20(%ebp)
801068e7:	8b 45 08             	mov    0x8(%ebp),%eax
801068ea:	8b 70 34             	mov    0x34(%eax),%esi
801068ed:	8b 45 08             	mov    0x8(%ebp),%eax
801068f0:	8b 58 30             	mov    0x30(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            myproc()->pid, myproc()->name, tf->trapno,
801068f3:	e8 90 d9 ff ff       	call   80104288 <myproc>
801068f8:	8d 48 6c             	lea    0x6c(%eax),%ecx
801068fb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
801068fe:	e8 85 d9 ff ff       	call   80104288 <myproc>
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpuid(), tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106903:	8b 40 10             	mov    0x10(%eax),%eax
80106906:	ff 75 e4             	pushl  -0x1c(%ebp)
80106909:	57                   	push   %edi
8010690a:	ff 75 e0             	pushl  -0x20(%ebp)
8010690d:	56                   	push   %esi
8010690e:	53                   	push   %ebx
8010690f:	ff 75 dc             	pushl  -0x24(%ebp)
80106912:	50                   	push   %eax
80106913:	68 78 88 10 80       	push   $0x80108878
80106918:	e8 e3 9a ff ff       	call   80100400 <cprintf>
8010691d:	83 c4 20             	add    $0x20,%esp
            "eip 0x%x addr 0x%x--kill proc\n",
            myproc()->pid, myproc()->name, tf->trapno,
            tf->err, cpuid(), tf->eip, rcr2());
    myproc()->killed = 1;
80106920:	e8 63 d9 ff ff       	call   80104288 <myproc>
80106925:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010692c:	eb 01                	jmp    8010692f <trap+0x1cb>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
8010692e:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010692f:	e8 54 d9 ff ff       	call   80104288 <myproc>
80106934:	85 c0                	test   %eax,%eax
80106936:	74 23                	je     8010695b <trap+0x1f7>
80106938:	e8 4b d9 ff ff       	call   80104288 <myproc>
8010693d:	8b 40 24             	mov    0x24(%eax),%eax
80106940:	85 c0                	test   %eax,%eax
80106942:	74 17                	je     8010695b <trap+0x1f7>
80106944:	8b 45 08             	mov    0x8(%ebp),%eax
80106947:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010694b:	0f b7 c0             	movzwl %ax,%eax
8010694e:	83 e0 03             	and    $0x3,%eax
80106951:	83 f8 03             	cmp    $0x3,%eax
80106954:	75 05                	jne    8010695b <trap+0x1f7>
    exit();
80106956:	e8 e4 dd ff ff       	call   8010473f <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
8010695b:	e8 28 d9 ff ff       	call   80104288 <myproc>
80106960:	85 c0                	test   %eax,%eax
80106962:	74 1d                	je     80106981 <trap+0x21d>
80106964:	e8 1f d9 ff ff       	call   80104288 <myproc>
80106969:	8b 40 0c             	mov    0xc(%eax),%eax
8010696c:	83 f8 04             	cmp    $0x4,%eax
8010696f:	75 10                	jne    80106981 <trap+0x21d>
     tf->trapno == T_IRQ0+IRQ_TIMER)
80106971:	8b 45 08             	mov    0x8(%ebp),%eax
80106974:	8b 40 30             	mov    0x30(%eax),%eax
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80106977:	83 f8 20             	cmp    $0x20,%eax
8010697a:	75 05                	jne    80106981 <trap+0x21d>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();
8010697c:	e8 71 e1 ff ff       	call   80104af2 <yield>

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80106981:	e8 02 d9 ff ff       	call   80104288 <myproc>
80106986:	85 c0                	test   %eax,%eax
80106988:	74 26                	je     801069b0 <trap+0x24c>
8010698a:	e8 f9 d8 ff ff       	call   80104288 <myproc>
8010698f:	8b 40 24             	mov    0x24(%eax),%eax
80106992:	85 c0                	test   %eax,%eax
80106994:	74 1a                	je     801069b0 <trap+0x24c>
80106996:	8b 45 08             	mov    0x8(%ebp),%eax
80106999:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010699d:	0f b7 c0             	movzwl %ax,%eax
801069a0:	83 e0 03             	and    $0x3,%eax
801069a3:	83 f8 03             	cmp    $0x3,%eax
801069a6:	75 08                	jne    801069b0 <trap+0x24c>
    exit();
801069a8:	e8 92 dd ff ff       	call   8010473f <exit>
801069ad:	eb 01                	jmp    801069b0 <trap+0x24c>
      exit();
    myproc()->tf = tf;
    syscall();
    if(myproc()->killed)
      exit();
    return;
801069af:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
    exit();
}
801069b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
801069b3:	5b                   	pop    %ebx
801069b4:	5e                   	pop    %esi
801069b5:	5f                   	pop    %edi
801069b6:	5d                   	pop    %ebp
801069b7:	c3                   	ret    

801069b8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801069b8:	55                   	push   %ebp
801069b9:	89 e5                	mov    %esp,%ebp
801069bb:	83 ec 14             	sub    $0x14,%esp
801069be:	8b 45 08             	mov    0x8(%ebp),%eax
801069c1:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801069c5:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801069c9:	89 c2                	mov    %eax,%edx
801069cb:	ec                   	in     (%dx),%al
801069cc:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801069cf:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801069d3:	c9                   	leave  
801069d4:	c3                   	ret    

801069d5 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801069d5:	55                   	push   %ebp
801069d6:	89 e5                	mov    %esp,%ebp
801069d8:	83 ec 08             	sub    $0x8,%esp
801069db:	8b 55 08             	mov    0x8(%ebp),%edx
801069de:	8b 45 0c             	mov    0xc(%ebp),%eax
801069e1:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801069e5:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801069e8:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801069ec:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801069f0:	ee                   	out    %al,(%dx)
}
801069f1:	90                   	nop
801069f2:	c9                   	leave  
801069f3:	c3                   	ret    

801069f4 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
801069f4:	55                   	push   %ebp
801069f5:	89 e5                	mov    %esp,%ebp
801069f7:	83 ec 18             	sub    $0x18,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
801069fa:	6a 00                	push   $0x0
801069fc:	68 fa 03 00 00       	push   $0x3fa
80106a01:	e8 cf ff ff ff       	call   801069d5 <outb>
80106a06:	83 c4 08             	add    $0x8,%esp

  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106a09:	68 80 00 00 00       	push   $0x80
80106a0e:	68 fb 03 00 00       	push   $0x3fb
80106a13:	e8 bd ff ff ff       	call   801069d5 <outb>
80106a18:	83 c4 08             	add    $0x8,%esp
  outb(COM1+0, 115200/9600);
80106a1b:	6a 0c                	push   $0xc
80106a1d:	68 f8 03 00 00       	push   $0x3f8
80106a22:	e8 ae ff ff ff       	call   801069d5 <outb>
80106a27:	83 c4 08             	add    $0x8,%esp
  outb(COM1+1, 0);
80106a2a:	6a 00                	push   $0x0
80106a2c:	68 f9 03 00 00       	push   $0x3f9
80106a31:	e8 9f ff ff ff       	call   801069d5 <outb>
80106a36:	83 c4 08             	add    $0x8,%esp
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106a39:	6a 03                	push   $0x3
80106a3b:	68 fb 03 00 00       	push   $0x3fb
80106a40:	e8 90 ff ff ff       	call   801069d5 <outb>
80106a45:	83 c4 08             	add    $0x8,%esp
  outb(COM1+4, 0);
80106a48:	6a 00                	push   $0x0
80106a4a:	68 fc 03 00 00       	push   $0x3fc
80106a4f:	e8 81 ff ff ff       	call   801069d5 <outb>
80106a54:	83 c4 08             	add    $0x8,%esp
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106a57:	6a 01                	push   $0x1
80106a59:	68 f9 03 00 00       	push   $0x3f9
80106a5e:	e8 72 ff ff ff       	call   801069d5 <outb>
80106a63:	83 c4 08             	add    $0x8,%esp

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106a66:	68 fd 03 00 00       	push   $0x3fd
80106a6b:	e8 48 ff ff ff       	call   801069b8 <inb>
80106a70:	83 c4 04             	add    $0x4,%esp
80106a73:	3c ff                	cmp    $0xff,%al
80106a75:	74 61                	je     80106ad8 <uartinit+0xe4>
    return;
  uart = 1;
80106a77:	c7 05 24 b6 10 80 01 	movl   $0x1,0x8010b624
80106a7e:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106a81:	68 fa 03 00 00       	push   $0x3fa
80106a86:	e8 2d ff ff ff       	call   801069b8 <inb>
80106a8b:	83 c4 04             	add    $0x4,%esp
  inb(COM1+0);
80106a8e:	68 f8 03 00 00       	push   $0x3f8
80106a93:	e8 20 ff ff ff       	call   801069b8 <inb>
80106a98:	83 c4 04             	add    $0x4,%esp
  ioapicenable(IRQ_COM1, 0);
80106a9b:	83 ec 08             	sub    $0x8,%esp
80106a9e:	6a 00                	push   $0x0
80106aa0:	6a 04                	push   $0x4
80106aa2:	e8 7d c0 ff ff       	call   80102b24 <ioapicenable>
80106aa7:	83 c4 10             	add    $0x10,%esp

  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106aaa:	c7 45 f4 3c 89 10 80 	movl   $0x8010893c,-0xc(%ebp)
80106ab1:	eb 19                	jmp    80106acc <uartinit+0xd8>
    uartputc(*p);
80106ab3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ab6:	0f b6 00             	movzbl (%eax),%eax
80106ab9:	0f be c0             	movsbl %al,%eax
80106abc:	83 ec 0c             	sub    $0xc,%esp
80106abf:	50                   	push   %eax
80106ac0:	e8 16 00 00 00       	call   80106adb <uartputc>
80106ac5:	83 c4 10             	add    $0x10,%esp
  inb(COM1+2);
  inb(COM1+0);
  ioapicenable(IRQ_COM1, 0);

  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106ac8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106acc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106acf:	0f b6 00             	movzbl (%eax),%eax
80106ad2:	84 c0                	test   %al,%al
80106ad4:	75 dd                	jne    80106ab3 <uartinit+0xbf>
80106ad6:	eb 01                	jmp    80106ad9 <uartinit+0xe5>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80106ad8:	90                   	nop
  ioapicenable(IRQ_COM1, 0);

  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80106ad9:	c9                   	leave  
80106ada:	c3                   	ret    

80106adb <uartputc>:

void
uartputc(int c)
{
80106adb:	55                   	push   %ebp
80106adc:	89 e5                	mov    %esp,%ebp
80106ade:	83 ec 18             	sub    $0x18,%esp
  int i;

  if(!uart)
80106ae1:	a1 24 b6 10 80       	mov    0x8010b624,%eax
80106ae6:	85 c0                	test   %eax,%eax
80106ae8:	74 53                	je     80106b3d <uartputc+0x62>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106aea:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106af1:	eb 11                	jmp    80106b04 <uartputc+0x29>
    microdelay(10);
80106af3:	83 ec 0c             	sub    $0xc,%esp
80106af6:	6a 0a                	push   $0xa
80106af8:	e8 2b c5 ff ff       	call   80103028 <microdelay>
80106afd:	83 c4 10             	add    $0x10,%esp
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106b00:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106b04:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106b08:	7f 1a                	jg     80106b24 <uartputc+0x49>
80106b0a:	83 ec 0c             	sub    $0xc,%esp
80106b0d:	68 fd 03 00 00       	push   $0x3fd
80106b12:	e8 a1 fe ff ff       	call   801069b8 <inb>
80106b17:	83 c4 10             	add    $0x10,%esp
80106b1a:	0f b6 c0             	movzbl %al,%eax
80106b1d:	83 e0 20             	and    $0x20,%eax
80106b20:	85 c0                	test   %eax,%eax
80106b22:	74 cf                	je     80106af3 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106b24:	8b 45 08             	mov    0x8(%ebp),%eax
80106b27:	0f b6 c0             	movzbl %al,%eax
80106b2a:	83 ec 08             	sub    $0x8,%esp
80106b2d:	50                   	push   %eax
80106b2e:	68 f8 03 00 00       	push   $0x3f8
80106b33:	e8 9d fe ff ff       	call   801069d5 <outb>
80106b38:	83 c4 10             	add    $0x10,%esp
80106b3b:	eb 01                	jmp    80106b3e <uartputc+0x63>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80106b3d:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80106b3e:	c9                   	leave  
80106b3f:	c3                   	ret    

80106b40 <uartgetc>:

static int
uartgetc(void)
{
80106b40:	55                   	push   %ebp
80106b41:	89 e5                	mov    %esp,%ebp
  if(!uart)
80106b43:	a1 24 b6 10 80       	mov    0x8010b624,%eax
80106b48:	85 c0                	test   %eax,%eax
80106b4a:	75 07                	jne    80106b53 <uartgetc+0x13>
    return -1;
80106b4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b51:	eb 2e                	jmp    80106b81 <uartgetc+0x41>
  if(!(inb(COM1+5) & 0x01))
80106b53:	68 fd 03 00 00       	push   $0x3fd
80106b58:	e8 5b fe ff ff       	call   801069b8 <inb>
80106b5d:	83 c4 04             	add    $0x4,%esp
80106b60:	0f b6 c0             	movzbl %al,%eax
80106b63:	83 e0 01             	and    $0x1,%eax
80106b66:	85 c0                	test   %eax,%eax
80106b68:	75 07                	jne    80106b71 <uartgetc+0x31>
    return -1;
80106b6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b6f:	eb 10                	jmp    80106b81 <uartgetc+0x41>
  return inb(COM1+0);
80106b71:	68 f8 03 00 00       	push   $0x3f8
80106b76:	e8 3d fe ff ff       	call   801069b8 <inb>
80106b7b:	83 c4 04             	add    $0x4,%esp
80106b7e:	0f b6 c0             	movzbl %al,%eax
}
80106b81:	c9                   	leave  
80106b82:	c3                   	ret    

80106b83 <uartintr>:

void
uartintr(void)
{
80106b83:	55                   	push   %ebp
80106b84:	89 e5                	mov    %esp,%ebp
80106b86:	83 ec 08             	sub    $0x8,%esp
  consoleintr(uartgetc);
80106b89:	83 ec 0c             	sub    $0xc,%esp
80106b8c:	68 40 6b 10 80       	push   $0x80106b40
80106b91:	e8 96 9c ff ff       	call   8010082c <consoleintr>
80106b96:	83 c4 10             	add    $0x10,%esp
}
80106b99:	90                   	nop
80106b9a:	c9                   	leave  
80106b9b:	c3                   	ret    

80106b9c <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106b9c:	6a 00                	push   $0x0
  pushl $0
80106b9e:	6a 00                	push   $0x0
  jmp alltraps
80106ba0:	e9 d3 f9 ff ff       	jmp    80106578 <alltraps>

80106ba5 <vector1>:
.globl vector1
vector1:
  pushl $0
80106ba5:	6a 00                	push   $0x0
  pushl $1
80106ba7:	6a 01                	push   $0x1
  jmp alltraps
80106ba9:	e9 ca f9 ff ff       	jmp    80106578 <alltraps>

80106bae <vector2>:
.globl vector2
vector2:
  pushl $0
80106bae:	6a 00                	push   $0x0
  pushl $2
80106bb0:	6a 02                	push   $0x2
  jmp alltraps
80106bb2:	e9 c1 f9 ff ff       	jmp    80106578 <alltraps>

80106bb7 <vector3>:
.globl vector3
vector3:
  pushl $0
80106bb7:	6a 00                	push   $0x0
  pushl $3
80106bb9:	6a 03                	push   $0x3
  jmp alltraps
80106bbb:	e9 b8 f9 ff ff       	jmp    80106578 <alltraps>

80106bc0 <vector4>:
.globl vector4
vector4:
  pushl $0
80106bc0:	6a 00                	push   $0x0
  pushl $4
80106bc2:	6a 04                	push   $0x4
  jmp alltraps
80106bc4:	e9 af f9 ff ff       	jmp    80106578 <alltraps>

80106bc9 <vector5>:
.globl vector5
vector5:
  pushl $0
80106bc9:	6a 00                	push   $0x0
  pushl $5
80106bcb:	6a 05                	push   $0x5
  jmp alltraps
80106bcd:	e9 a6 f9 ff ff       	jmp    80106578 <alltraps>

80106bd2 <vector6>:
.globl vector6
vector6:
  pushl $0
80106bd2:	6a 00                	push   $0x0
  pushl $6
80106bd4:	6a 06                	push   $0x6
  jmp alltraps
80106bd6:	e9 9d f9 ff ff       	jmp    80106578 <alltraps>

80106bdb <vector7>:
.globl vector7
vector7:
  pushl $0
80106bdb:	6a 00                	push   $0x0
  pushl $7
80106bdd:	6a 07                	push   $0x7
  jmp alltraps
80106bdf:	e9 94 f9 ff ff       	jmp    80106578 <alltraps>

80106be4 <vector8>:
.globl vector8
vector8:
  pushl $8
80106be4:	6a 08                	push   $0x8
  jmp alltraps
80106be6:	e9 8d f9 ff ff       	jmp    80106578 <alltraps>

80106beb <vector9>:
.globl vector9
vector9:
  pushl $0
80106beb:	6a 00                	push   $0x0
  pushl $9
80106bed:	6a 09                	push   $0x9
  jmp alltraps
80106bef:	e9 84 f9 ff ff       	jmp    80106578 <alltraps>

80106bf4 <vector10>:
.globl vector10
vector10:
  pushl $10
80106bf4:	6a 0a                	push   $0xa
  jmp alltraps
80106bf6:	e9 7d f9 ff ff       	jmp    80106578 <alltraps>

80106bfb <vector11>:
.globl vector11
vector11:
  pushl $11
80106bfb:	6a 0b                	push   $0xb
  jmp alltraps
80106bfd:	e9 76 f9 ff ff       	jmp    80106578 <alltraps>

80106c02 <vector12>:
.globl vector12
vector12:
  pushl $12
80106c02:	6a 0c                	push   $0xc
  jmp alltraps
80106c04:	e9 6f f9 ff ff       	jmp    80106578 <alltraps>

80106c09 <vector13>:
.globl vector13
vector13:
  pushl $13
80106c09:	6a 0d                	push   $0xd
  jmp alltraps
80106c0b:	e9 68 f9 ff ff       	jmp    80106578 <alltraps>

80106c10 <vector14>:
.globl vector14
vector14:
  pushl $14
80106c10:	6a 0e                	push   $0xe
  jmp alltraps
80106c12:	e9 61 f9 ff ff       	jmp    80106578 <alltraps>

80106c17 <vector15>:
.globl vector15
vector15:
  pushl $0
80106c17:	6a 00                	push   $0x0
  pushl $15
80106c19:	6a 0f                	push   $0xf
  jmp alltraps
80106c1b:	e9 58 f9 ff ff       	jmp    80106578 <alltraps>

80106c20 <vector16>:
.globl vector16
vector16:
  pushl $0
80106c20:	6a 00                	push   $0x0
  pushl $16
80106c22:	6a 10                	push   $0x10
  jmp alltraps
80106c24:	e9 4f f9 ff ff       	jmp    80106578 <alltraps>

80106c29 <vector17>:
.globl vector17
vector17:
  pushl $17
80106c29:	6a 11                	push   $0x11
  jmp alltraps
80106c2b:	e9 48 f9 ff ff       	jmp    80106578 <alltraps>

80106c30 <vector18>:
.globl vector18
vector18:
  pushl $0
80106c30:	6a 00                	push   $0x0
  pushl $18
80106c32:	6a 12                	push   $0x12
  jmp alltraps
80106c34:	e9 3f f9 ff ff       	jmp    80106578 <alltraps>

80106c39 <vector19>:
.globl vector19
vector19:
  pushl $0
80106c39:	6a 00                	push   $0x0
  pushl $19
80106c3b:	6a 13                	push   $0x13
  jmp alltraps
80106c3d:	e9 36 f9 ff ff       	jmp    80106578 <alltraps>

80106c42 <vector20>:
.globl vector20
vector20:
  pushl $0
80106c42:	6a 00                	push   $0x0
  pushl $20
80106c44:	6a 14                	push   $0x14
  jmp alltraps
80106c46:	e9 2d f9 ff ff       	jmp    80106578 <alltraps>

80106c4b <vector21>:
.globl vector21
vector21:
  pushl $0
80106c4b:	6a 00                	push   $0x0
  pushl $21
80106c4d:	6a 15                	push   $0x15
  jmp alltraps
80106c4f:	e9 24 f9 ff ff       	jmp    80106578 <alltraps>

80106c54 <vector22>:
.globl vector22
vector22:
  pushl $0
80106c54:	6a 00                	push   $0x0
  pushl $22
80106c56:	6a 16                	push   $0x16
  jmp alltraps
80106c58:	e9 1b f9 ff ff       	jmp    80106578 <alltraps>

80106c5d <vector23>:
.globl vector23
vector23:
  pushl $0
80106c5d:	6a 00                	push   $0x0
  pushl $23
80106c5f:	6a 17                	push   $0x17
  jmp alltraps
80106c61:	e9 12 f9 ff ff       	jmp    80106578 <alltraps>

80106c66 <vector24>:
.globl vector24
vector24:
  pushl $0
80106c66:	6a 00                	push   $0x0
  pushl $24
80106c68:	6a 18                	push   $0x18
  jmp alltraps
80106c6a:	e9 09 f9 ff ff       	jmp    80106578 <alltraps>

80106c6f <vector25>:
.globl vector25
vector25:
  pushl $0
80106c6f:	6a 00                	push   $0x0
  pushl $25
80106c71:	6a 19                	push   $0x19
  jmp alltraps
80106c73:	e9 00 f9 ff ff       	jmp    80106578 <alltraps>

80106c78 <vector26>:
.globl vector26
vector26:
  pushl $0
80106c78:	6a 00                	push   $0x0
  pushl $26
80106c7a:	6a 1a                	push   $0x1a
  jmp alltraps
80106c7c:	e9 f7 f8 ff ff       	jmp    80106578 <alltraps>

80106c81 <vector27>:
.globl vector27
vector27:
  pushl $0
80106c81:	6a 00                	push   $0x0
  pushl $27
80106c83:	6a 1b                	push   $0x1b
  jmp alltraps
80106c85:	e9 ee f8 ff ff       	jmp    80106578 <alltraps>

80106c8a <vector28>:
.globl vector28
vector28:
  pushl $0
80106c8a:	6a 00                	push   $0x0
  pushl $28
80106c8c:	6a 1c                	push   $0x1c
  jmp alltraps
80106c8e:	e9 e5 f8 ff ff       	jmp    80106578 <alltraps>

80106c93 <vector29>:
.globl vector29
vector29:
  pushl $0
80106c93:	6a 00                	push   $0x0
  pushl $29
80106c95:	6a 1d                	push   $0x1d
  jmp alltraps
80106c97:	e9 dc f8 ff ff       	jmp    80106578 <alltraps>

80106c9c <vector30>:
.globl vector30
vector30:
  pushl $0
80106c9c:	6a 00                	push   $0x0
  pushl $30
80106c9e:	6a 1e                	push   $0x1e
  jmp alltraps
80106ca0:	e9 d3 f8 ff ff       	jmp    80106578 <alltraps>

80106ca5 <vector31>:
.globl vector31
vector31:
  pushl $0
80106ca5:	6a 00                	push   $0x0
  pushl $31
80106ca7:	6a 1f                	push   $0x1f
  jmp alltraps
80106ca9:	e9 ca f8 ff ff       	jmp    80106578 <alltraps>

80106cae <vector32>:
.globl vector32
vector32:
  pushl $0
80106cae:	6a 00                	push   $0x0
  pushl $32
80106cb0:	6a 20                	push   $0x20
  jmp alltraps
80106cb2:	e9 c1 f8 ff ff       	jmp    80106578 <alltraps>

80106cb7 <vector33>:
.globl vector33
vector33:
  pushl $0
80106cb7:	6a 00                	push   $0x0
  pushl $33
80106cb9:	6a 21                	push   $0x21
  jmp alltraps
80106cbb:	e9 b8 f8 ff ff       	jmp    80106578 <alltraps>

80106cc0 <vector34>:
.globl vector34
vector34:
  pushl $0
80106cc0:	6a 00                	push   $0x0
  pushl $34
80106cc2:	6a 22                	push   $0x22
  jmp alltraps
80106cc4:	e9 af f8 ff ff       	jmp    80106578 <alltraps>

80106cc9 <vector35>:
.globl vector35
vector35:
  pushl $0
80106cc9:	6a 00                	push   $0x0
  pushl $35
80106ccb:	6a 23                	push   $0x23
  jmp alltraps
80106ccd:	e9 a6 f8 ff ff       	jmp    80106578 <alltraps>

80106cd2 <vector36>:
.globl vector36
vector36:
  pushl $0
80106cd2:	6a 00                	push   $0x0
  pushl $36
80106cd4:	6a 24                	push   $0x24
  jmp alltraps
80106cd6:	e9 9d f8 ff ff       	jmp    80106578 <alltraps>

80106cdb <vector37>:
.globl vector37
vector37:
  pushl $0
80106cdb:	6a 00                	push   $0x0
  pushl $37
80106cdd:	6a 25                	push   $0x25
  jmp alltraps
80106cdf:	e9 94 f8 ff ff       	jmp    80106578 <alltraps>

80106ce4 <vector38>:
.globl vector38
vector38:
  pushl $0
80106ce4:	6a 00                	push   $0x0
  pushl $38
80106ce6:	6a 26                	push   $0x26
  jmp alltraps
80106ce8:	e9 8b f8 ff ff       	jmp    80106578 <alltraps>

80106ced <vector39>:
.globl vector39
vector39:
  pushl $0
80106ced:	6a 00                	push   $0x0
  pushl $39
80106cef:	6a 27                	push   $0x27
  jmp alltraps
80106cf1:	e9 82 f8 ff ff       	jmp    80106578 <alltraps>

80106cf6 <vector40>:
.globl vector40
vector40:
  pushl $0
80106cf6:	6a 00                	push   $0x0
  pushl $40
80106cf8:	6a 28                	push   $0x28
  jmp alltraps
80106cfa:	e9 79 f8 ff ff       	jmp    80106578 <alltraps>

80106cff <vector41>:
.globl vector41
vector41:
  pushl $0
80106cff:	6a 00                	push   $0x0
  pushl $41
80106d01:	6a 29                	push   $0x29
  jmp alltraps
80106d03:	e9 70 f8 ff ff       	jmp    80106578 <alltraps>

80106d08 <vector42>:
.globl vector42
vector42:
  pushl $0
80106d08:	6a 00                	push   $0x0
  pushl $42
80106d0a:	6a 2a                	push   $0x2a
  jmp alltraps
80106d0c:	e9 67 f8 ff ff       	jmp    80106578 <alltraps>

80106d11 <vector43>:
.globl vector43
vector43:
  pushl $0
80106d11:	6a 00                	push   $0x0
  pushl $43
80106d13:	6a 2b                	push   $0x2b
  jmp alltraps
80106d15:	e9 5e f8 ff ff       	jmp    80106578 <alltraps>

80106d1a <vector44>:
.globl vector44
vector44:
  pushl $0
80106d1a:	6a 00                	push   $0x0
  pushl $44
80106d1c:	6a 2c                	push   $0x2c
  jmp alltraps
80106d1e:	e9 55 f8 ff ff       	jmp    80106578 <alltraps>

80106d23 <vector45>:
.globl vector45
vector45:
  pushl $0
80106d23:	6a 00                	push   $0x0
  pushl $45
80106d25:	6a 2d                	push   $0x2d
  jmp alltraps
80106d27:	e9 4c f8 ff ff       	jmp    80106578 <alltraps>

80106d2c <vector46>:
.globl vector46
vector46:
  pushl $0
80106d2c:	6a 00                	push   $0x0
  pushl $46
80106d2e:	6a 2e                	push   $0x2e
  jmp alltraps
80106d30:	e9 43 f8 ff ff       	jmp    80106578 <alltraps>

80106d35 <vector47>:
.globl vector47
vector47:
  pushl $0
80106d35:	6a 00                	push   $0x0
  pushl $47
80106d37:	6a 2f                	push   $0x2f
  jmp alltraps
80106d39:	e9 3a f8 ff ff       	jmp    80106578 <alltraps>

80106d3e <vector48>:
.globl vector48
vector48:
  pushl $0
80106d3e:	6a 00                	push   $0x0
  pushl $48
80106d40:	6a 30                	push   $0x30
  jmp alltraps
80106d42:	e9 31 f8 ff ff       	jmp    80106578 <alltraps>

80106d47 <vector49>:
.globl vector49
vector49:
  pushl $0
80106d47:	6a 00                	push   $0x0
  pushl $49
80106d49:	6a 31                	push   $0x31
  jmp alltraps
80106d4b:	e9 28 f8 ff ff       	jmp    80106578 <alltraps>

80106d50 <vector50>:
.globl vector50
vector50:
  pushl $0
80106d50:	6a 00                	push   $0x0
  pushl $50
80106d52:	6a 32                	push   $0x32
  jmp alltraps
80106d54:	e9 1f f8 ff ff       	jmp    80106578 <alltraps>

80106d59 <vector51>:
.globl vector51
vector51:
  pushl $0
80106d59:	6a 00                	push   $0x0
  pushl $51
80106d5b:	6a 33                	push   $0x33
  jmp alltraps
80106d5d:	e9 16 f8 ff ff       	jmp    80106578 <alltraps>

80106d62 <vector52>:
.globl vector52
vector52:
  pushl $0
80106d62:	6a 00                	push   $0x0
  pushl $52
80106d64:	6a 34                	push   $0x34
  jmp alltraps
80106d66:	e9 0d f8 ff ff       	jmp    80106578 <alltraps>

80106d6b <vector53>:
.globl vector53
vector53:
  pushl $0
80106d6b:	6a 00                	push   $0x0
  pushl $53
80106d6d:	6a 35                	push   $0x35
  jmp alltraps
80106d6f:	e9 04 f8 ff ff       	jmp    80106578 <alltraps>

80106d74 <vector54>:
.globl vector54
vector54:
  pushl $0
80106d74:	6a 00                	push   $0x0
  pushl $54
80106d76:	6a 36                	push   $0x36
  jmp alltraps
80106d78:	e9 fb f7 ff ff       	jmp    80106578 <alltraps>

80106d7d <vector55>:
.globl vector55
vector55:
  pushl $0
80106d7d:	6a 00                	push   $0x0
  pushl $55
80106d7f:	6a 37                	push   $0x37
  jmp alltraps
80106d81:	e9 f2 f7 ff ff       	jmp    80106578 <alltraps>

80106d86 <vector56>:
.globl vector56
vector56:
  pushl $0
80106d86:	6a 00                	push   $0x0
  pushl $56
80106d88:	6a 38                	push   $0x38
  jmp alltraps
80106d8a:	e9 e9 f7 ff ff       	jmp    80106578 <alltraps>

80106d8f <vector57>:
.globl vector57
vector57:
  pushl $0
80106d8f:	6a 00                	push   $0x0
  pushl $57
80106d91:	6a 39                	push   $0x39
  jmp alltraps
80106d93:	e9 e0 f7 ff ff       	jmp    80106578 <alltraps>

80106d98 <vector58>:
.globl vector58
vector58:
  pushl $0
80106d98:	6a 00                	push   $0x0
  pushl $58
80106d9a:	6a 3a                	push   $0x3a
  jmp alltraps
80106d9c:	e9 d7 f7 ff ff       	jmp    80106578 <alltraps>

80106da1 <vector59>:
.globl vector59
vector59:
  pushl $0
80106da1:	6a 00                	push   $0x0
  pushl $59
80106da3:	6a 3b                	push   $0x3b
  jmp alltraps
80106da5:	e9 ce f7 ff ff       	jmp    80106578 <alltraps>

80106daa <vector60>:
.globl vector60
vector60:
  pushl $0
80106daa:	6a 00                	push   $0x0
  pushl $60
80106dac:	6a 3c                	push   $0x3c
  jmp alltraps
80106dae:	e9 c5 f7 ff ff       	jmp    80106578 <alltraps>

80106db3 <vector61>:
.globl vector61
vector61:
  pushl $0
80106db3:	6a 00                	push   $0x0
  pushl $61
80106db5:	6a 3d                	push   $0x3d
  jmp alltraps
80106db7:	e9 bc f7 ff ff       	jmp    80106578 <alltraps>

80106dbc <vector62>:
.globl vector62
vector62:
  pushl $0
80106dbc:	6a 00                	push   $0x0
  pushl $62
80106dbe:	6a 3e                	push   $0x3e
  jmp alltraps
80106dc0:	e9 b3 f7 ff ff       	jmp    80106578 <alltraps>

80106dc5 <vector63>:
.globl vector63
vector63:
  pushl $0
80106dc5:	6a 00                	push   $0x0
  pushl $63
80106dc7:	6a 3f                	push   $0x3f
  jmp alltraps
80106dc9:	e9 aa f7 ff ff       	jmp    80106578 <alltraps>

80106dce <vector64>:
.globl vector64
vector64:
  pushl $0
80106dce:	6a 00                	push   $0x0
  pushl $64
80106dd0:	6a 40                	push   $0x40
  jmp alltraps
80106dd2:	e9 a1 f7 ff ff       	jmp    80106578 <alltraps>

80106dd7 <vector65>:
.globl vector65
vector65:
  pushl $0
80106dd7:	6a 00                	push   $0x0
  pushl $65
80106dd9:	6a 41                	push   $0x41
  jmp alltraps
80106ddb:	e9 98 f7 ff ff       	jmp    80106578 <alltraps>

80106de0 <vector66>:
.globl vector66
vector66:
  pushl $0
80106de0:	6a 00                	push   $0x0
  pushl $66
80106de2:	6a 42                	push   $0x42
  jmp alltraps
80106de4:	e9 8f f7 ff ff       	jmp    80106578 <alltraps>

80106de9 <vector67>:
.globl vector67
vector67:
  pushl $0
80106de9:	6a 00                	push   $0x0
  pushl $67
80106deb:	6a 43                	push   $0x43
  jmp alltraps
80106ded:	e9 86 f7 ff ff       	jmp    80106578 <alltraps>

80106df2 <vector68>:
.globl vector68
vector68:
  pushl $0
80106df2:	6a 00                	push   $0x0
  pushl $68
80106df4:	6a 44                	push   $0x44
  jmp alltraps
80106df6:	e9 7d f7 ff ff       	jmp    80106578 <alltraps>

80106dfb <vector69>:
.globl vector69
vector69:
  pushl $0
80106dfb:	6a 00                	push   $0x0
  pushl $69
80106dfd:	6a 45                	push   $0x45
  jmp alltraps
80106dff:	e9 74 f7 ff ff       	jmp    80106578 <alltraps>

80106e04 <vector70>:
.globl vector70
vector70:
  pushl $0
80106e04:	6a 00                	push   $0x0
  pushl $70
80106e06:	6a 46                	push   $0x46
  jmp alltraps
80106e08:	e9 6b f7 ff ff       	jmp    80106578 <alltraps>

80106e0d <vector71>:
.globl vector71
vector71:
  pushl $0
80106e0d:	6a 00                	push   $0x0
  pushl $71
80106e0f:	6a 47                	push   $0x47
  jmp alltraps
80106e11:	e9 62 f7 ff ff       	jmp    80106578 <alltraps>

80106e16 <vector72>:
.globl vector72
vector72:
  pushl $0
80106e16:	6a 00                	push   $0x0
  pushl $72
80106e18:	6a 48                	push   $0x48
  jmp alltraps
80106e1a:	e9 59 f7 ff ff       	jmp    80106578 <alltraps>

80106e1f <vector73>:
.globl vector73
vector73:
  pushl $0
80106e1f:	6a 00                	push   $0x0
  pushl $73
80106e21:	6a 49                	push   $0x49
  jmp alltraps
80106e23:	e9 50 f7 ff ff       	jmp    80106578 <alltraps>

80106e28 <vector74>:
.globl vector74
vector74:
  pushl $0
80106e28:	6a 00                	push   $0x0
  pushl $74
80106e2a:	6a 4a                	push   $0x4a
  jmp alltraps
80106e2c:	e9 47 f7 ff ff       	jmp    80106578 <alltraps>

80106e31 <vector75>:
.globl vector75
vector75:
  pushl $0
80106e31:	6a 00                	push   $0x0
  pushl $75
80106e33:	6a 4b                	push   $0x4b
  jmp alltraps
80106e35:	e9 3e f7 ff ff       	jmp    80106578 <alltraps>

80106e3a <vector76>:
.globl vector76
vector76:
  pushl $0
80106e3a:	6a 00                	push   $0x0
  pushl $76
80106e3c:	6a 4c                	push   $0x4c
  jmp alltraps
80106e3e:	e9 35 f7 ff ff       	jmp    80106578 <alltraps>

80106e43 <vector77>:
.globl vector77
vector77:
  pushl $0
80106e43:	6a 00                	push   $0x0
  pushl $77
80106e45:	6a 4d                	push   $0x4d
  jmp alltraps
80106e47:	e9 2c f7 ff ff       	jmp    80106578 <alltraps>

80106e4c <vector78>:
.globl vector78
vector78:
  pushl $0
80106e4c:	6a 00                	push   $0x0
  pushl $78
80106e4e:	6a 4e                	push   $0x4e
  jmp alltraps
80106e50:	e9 23 f7 ff ff       	jmp    80106578 <alltraps>

80106e55 <vector79>:
.globl vector79
vector79:
  pushl $0
80106e55:	6a 00                	push   $0x0
  pushl $79
80106e57:	6a 4f                	push   $0x4f
  jmp alltraps
80106e59:	e9 1a f7 ff ff       	jmp    80106578 <alltraps>

80106e5e <vector80>:
.globl vector80
vector80:
  pushl $0
80106e5e:	6a 00                	push   $0x0
  pushl $80
80106e60:	6a 50                	push   $0x50
  jmp alltraps
80106e62:	e9 11 f7 ff ff       	jmp    80106578 <alltraps>

80106e67 <vector81>:
.globl vector81
vector81:
  pushl $0
80106e67:	6a 00                	push   $0x0
  pushl $81
80106e69:	6a 51                	push   $0x51
  jmp alltraps
80106e6b:	e9 08 f7 ff ff       	jmp    80106578 <alltraps>

80106e70 <vector82>:
.globl vector82
vector82:
  pushl $0
80106e70:	6a 00                	push   $0x0
  pushl $82
80106e72:	6a 52                	push   $0x52
  jmp alltraps
80106e74:	e9 ff f6 ff ff       	jmp    80106578 <alltraps>

80106e79 <vector83>:
.globl vector83
vector83:
  pushl $0
80106e79:	6a 00                	push   $0x0
  pushl $83
80106e7b:	6a 53                	push   $0x53
  jmp alltraps
80106e7d:	e9 f6 f6 ff ff       	jmp    80106578 <alltraps>

80106e82 <vector84>:
.globl vector84
vector84:
  pushl $0
80106e82:	6a 00                	push   $0x0
  pushl $84
80106e84:	6a 54                	push   $0x54
  jmp alltraps
80106e86:	e9 ed f6 ff ff       	jmp    80106578 <alltraps>

80106e8b <vector85>:
.globl vector85
vector85:
  pushl $0
80106e8b:	6a 00                	push   $0x0
  pushl $85
80106e8d:	6a 55                	push   $0x55
  jmp alltraps
80106e8f:	e9 e4 f6 ff ff       	jmp    80106578 <alltraps>

80106e94 <vector86>:
.globl vector86
vector86:
  pushl $0
80106e94:	6a 00                	push   $0x0
  pushl $86
80106e96:	6a 56                	push   $0x56
  jmp alltraps
80106e98:	e9 db f6 ff ff       	jmp    80106578 <alltraps>

80106e9d <vector87>:
.globl vector87
vector87:
  pushl $0
80106e9d:	6a 00                	push   $0x0
  pushl $87
80106e9f:	6a 57                	push   $0x57
  jmp alltraps
80106ea1:	e9 d2 f6 ff ff       	jmp    80106578 <alltraps>

80106ea6 <vector88>:
.globl vector88
vector88:
  pushl $0
80106ea6:	6a 00                	push   $0x0
  pushl $88
80106ea8:	6a 58                	push   $0x58
  jmp alltraps
80106eaa:	e9 c9 f6 ff ff       	jmp    80106578 <alltraps>

80106eaf <vector89>:
.globl vector89
vector89:
  pushl $0
80106eaf:	6a 00                	push   $0x0
  pushl $89
80106eb1:	6a 59                	push   $0x59
  jmp alltraps
80106eb3:	e9 c0 f6 ff ff       	jmp    80106578 <alltraps>

80106eb8 <vector90>:
.globl vector90
vector90:
  pushl $0
80106eb8:	6a 00                	push   $0x0
  pushl $90
80106eba:	6a 5a                	push   $0x5a
  jmp alltraps
80106ebc:	e9 b7 f6 ff ff       	jmp    80106578 <alltraps>

80106ec1 <vector91>:
.globl vector91
vector91:
  pushl $0
80106ec1:	6a 00                	push   $0x0
  pushl $91
80106ec3:	6a 5b                	push   $0x5b
  jmp alltraps
80106ec5:	e9 ae f6 ff ff       	jmp    80106578 <alltraps>

80106eca <vector92>:
.globl vector92
vector92:
  pushl $0
80106eca:	6a 00                	push   $0x0
  pushl $92
80106ecc:	6a 5c                	push   $0x5c
  jmp alltraps
80106ece:	e9 a5 f6 ff ff       	jmp    80106578 <alltraps>

80106ed3 <vector93>:
.globl vector93
vector93:
  pushl $0
80106ed3:	6a 00                	push   $0x0
  pushl $93
80106ed5:	6a 5d                	push   $0x5d
  jmp alltraps
80106ed7:	e9 9c f6 ff ff       	jmp    80106578 <alltraps>

80106edc <vector94>:
.globl vector94
vector94:
  pushl $0
80106edc:	6a 00                	push   $0x0
  pushl $94
80106ede:	6a 5e                	push   $0x5e
  jmp alltraps
80106ee0:	e9 93 f6 ff ff       	jmp    80106578 <alltraps>

80106ee5 <vector95>:
.globl vector95
vector95:
  pushl $0
80106ee5:	6a 00                	push   $0x0
  pushl $95
80106ee7:	6a 5f                	push   $0x5f
  jmp alltraps
80106ee9:	e9 8a f6 ff ff       	jmp    80106578 <alltraps>

80106eee <vector96>:
.globl vector96
vector96:
  pushl $0
80106eee:	6a 00                	push   $0x0
  pushl $96
80106ef0:	6a 60                	push   $0x60
  jmp alltraps
80106ef2:	e9 81 f6 ff ff       	jmp    80106578 <alltraps>

80106ef7 <vector97>:
.globl vector97
vector97:
  pushl $0
80106ef7:	6a 00                	push   $0x0
  pushl $97
80106ef9:	6a 61                	push   $0x61
  jmp alltraps
80106efb:	e9 78 f6 ff ff       	jmp    80106578 <alltraps>

80106f00 <vector98>:
.globl vector98
vector98:
  pushl $0
80106f00:	6a 00                	push   $0x0
  pushl $98
80106f02:	6a 62                	push   $0x62
  jmp alltraps
80106f04:	e9 6f f6 ff ff       	jmp    80106578 <alltraps>

80106f09 <vector99>:
.globl vector99
vector99:
  pushl $0
80106f09:	6a 00                	push   $0x0
  pushl $99
80106f0b:	6a 63                	push   $0x63
  jmp alltraps
80106f0d:	e9 66 f6 ff ff       	jmp    80106578 <alltraps>

80106f12 <vector100>:
.globl vector100
vector100:
  pushl $0
80106f12:	6a 00                	push   $0x0
  pushl $100
80106f14:	6a 64                	push   $0x64
  jmp alltraps
80106f16:	e9 5d f6 ff ff       	jmp    80106578 <alltraps>

80106f1b <vector101>:
.globl vector101
vector101:
  pushl $0
80106f1b:	6a 00                	push   $0x0
  pushl $101
80106f1d:	6a 65                	push   $0x65
  jmp alltraps
80106f1f:	e9 54 f6 ff ff       	jmp    80106578 <alltraps>

80106f24 <vector102>:
.globl vector102
vector102:
  pushl $0
80106f24:	6a 00                	push   $0x0
  pushl $102
80106f26:	6a 66                	push   $0x66
  jmp alltraps
80106f28:	e9 4b f6 ff ff       	jmp    80106578 <alltraps>

80106f2d <vector103>:
.globl vector103
vector103:
  pushl $0
80106f2d:	6a 00                	push   $0x0
  pushl $103
80106f2f:	6a 67                	push   $0x67
  jmp alltraps
80106f31:	e9 42 f6 ff ff       	jmp    80106578 <alltraps>

80106f36 <vector104>:
.globl vector104
vector104:
  pushl $0
80106f36:	6a 00                	push   $0x0
  pushl $104
80106f38:	6a 68                	push   $0x68
  jmp alltraps
80106f3a:	e9 39 f6 ff ff       	jmp    80106578 <alltraps>

80106f3f <vector105>:
.globl vector105
vector105:
  pushl $0
80106f3f:	6a 00                	push   $0x0
  pushl $105
80106f41:	6a 69                	push   $0x69
  jmp alltraps
80106f43:	e9 30 f6 ff ff       	jmp    80106578 <alltraps>

80106f48 <vector106>:
.globl vector106
vector106:
  pushl $0
80106f48:	6a 00                	push   $0x0
  pushl $106
80106f4a:	6a 6a                	push   $0x6a
  jmp alltraps
80106f4c:	e9 27 f6 ff ff       	jmp    80106578 <alltraps>

80106f51 <vector107>:
.globl vector107
vector107:
  pushl $0
80106f51:	6a 00                	push   $0x0
  pushl $107
80106f53:	6a 6b                	push   $0x6b
  jmp alltraps
80106f55:	e9 1e f6 ff ff       	jmp    80106578 <alltraps>

80106f5a <vector108>:
.globl vector108
vector108:
  pushl $0
80106f5a:	6a 00                	push   $0x0
  pushl $108
80106f5c:	6a 6c                	push   $0x6c
  jmp alltraps
80106f5e:	e9 15 f6 ff ff       	jmp    80106578 <alltraps>

80106f63 <vector109>:
.globl vector109
vector109:
  pushl $0
80106f63:	6a 00                	push   $0x0
  pushl $109
80106f65:	6a 6d                	push   $0x6d
  jmp alltraps
80106f67:	e9 0c f6 ff ff       	jmp    80106578 <alltraps>

80106f6c <vector110>:
.globl vector110
vector110:
  pushl $0
80106f6c:	6a 00                	push   $0x0
  pushl $110
80106f6e:	6a 6e                	push   $0x6e
  jmp alltraps
80106f70:	e9 03 f6 ff ff       	jmp    80106578 <alltraps>

80106f75 <vector111>:
.globl vector111
vector111:
  pushl $0
80106f75:	6a 00                	push   $0x0
  pushl $111
80106f77:	6a 6f                	push   $0x6f
  jmp alltraps
80106f79:	e9 fa f5 ff ff       	jmp    80106578 <alltraps>

80106f7e <vector112>:
.globl vector112
vector112:
  pushl $0
80106f7e:	6a 00                	push   $0x0
  pushl $112
80106f80:	6a 70                	push   $0x70
  jmp alltraps
80106f82:	e9 f1 f5 ff ff       	jmp    80106578 <alltraps>

80106f87 <vector113>:
.globl vector113
vector113:
  pushl $0
80106f87:	6a 00                	push   $0x0
  pushl $113
80106f89:	6a 71                	push   $0x71
  jmp alltraps
80106f8b:	e9 e8 f5 ff ff       	jmp    80106578 <alltraps>

80106f90 <vector114>:
.globl vector114
vector114:
  pushl $0
80106f90:	6a 00                	push   $0x0
  pushl $114
80106f92:	6a 72                	push   $0x72
  jmp alltraps
80106f94:	e9 df f5 ff ff       	jmp    80106578 <alltraps>

80106f99 <vector115>:
.globl vector115
vector115:
  pushl $0
80106f99:	6a 00                	push   $0x0
  pushl $115
80106f9b:	6a 73                	push   $0x73
  jmp alltraps
80106f9d:	e9 d6 f5 ff ff       	jmp    80106578 <alltraps>

80106fa2 <vector116>:
.globl vector116
vector116:
  pushl $0
80106fa2:	6a 00                	push   $0x0
  pushl $116
80106fa4:	6a 74                	push   $0x74
  jmp alltraps
80106fa6:	e9 cd f5 ff ff       	jmp    80106578 <alltraps>

80106fab <vector117>:
.globl vector117
vector117:
  pushl $0
80106fab:	6a 00                	push   $0x0
  pushl $117
80106fad:	6a 75                	push   $0x75
  jmp alltraps
80106faf:	e9 c4 f5 ff ff       	jmp    80106578 <alltraps>

80106fb4 <vector118>:
.globl vector118
vector118:
  pushl $0
80106fb4:	6a 00                	push   $0x0
  pushl $118
80106fb6:	6a 76                	push   $0x76
  jmp alltraps
80106fb8:	e9 bb f5 ff ff       	jmp    80106578 <alltraps>

80106fbd <vector119>:
.globl vector119
vector119:
  pushl $0
80106fbd:	6a 00                	push   $0x0
  pushl $119
80106fbf:	6a 77                	push   $0x77
  jmp alltraps
80106fc1:	e9 b2 f5 ff ff       	jmp    80106578 <alltraps>

80106fc6 <vector120>:
.globl vector120
vector120:
  pushl $0
80106fc6:	6a 00                	push   $0x0
  pushl $120
80106fc8:	6a 78                	push   $0x78
  jmp alltraps
80106fca:	e9 a9 f5 ff ff       	jmp    80106578 <alltraps>

80106fcf <vector121>:
.globl vector121
vector121:
  pushl $0
80106fcf:	6a 00                	push   $0x0
  pushl $121
80106fd1:	6a 79                	push   $0x79
  jmp alltraps
80106fd3:	e9 a0 f5 ff ff       	jmp    80106578 <alltraps>

80106fd8 <vector122>:
.globl vector122
vector122:
  pushl $0
80106fd8:	6a 00                	push   $0x0
  pushl $122
80106fda:	6a 7a                	push   $0x7a
  jmp alltraps
80106fdc:	e9 97 f5 ff ff       	jmp    80106578 <alltraps>

80106fe1 <vector123>:
.globl vector123
vector123:
  pushl $0
80106fe1:	6a 00                	push   $0x0
  pushl $123
80106fe3:	6a 7b                	push   $0x7b
  jmp alltraps
80106fe5:	e9 8e f5 ff ff       	jmp    80106578 <alltraps>

80106fea <vector124>:
.globl vector124
vector124:
  pushl $0
80106fea:	6a 00                	push   $0x0
  pushl $124
80106fec:	6a 7c                	push   $0x7c
  jmp alltraps
80106fee:	e9 85 f5 ff ff       	jmp    80106578 <alltraps>

80106ff3 <vector125>:
.globl vector125
vector125:
  pushl $0
80106ff3:	6a 00                	push   $0x0
  pushl $125
80106ff5:	6a 7d                	push   $0x7d
  jmp alltraps
80106ff7:	e9 7c f5 ff ff       	jmp    80106578 <alltraps>

80106ffc <vector126>:
.globl vector126
vector126:
  pushl $0
80106ffc:	6a 00                	push   $0x0
  pushl $126
80106ffe:	6a 7e                	push   $0x7e
  jmp alltraps
80107000:	e9 73 f5 ff ff       	jmp    80106578 <alltraps>

80107005 <vector127>:
.globl vector127
vector127:
  pushl $0
80107005:	6a 00                	push   $0x0
  pushl $127
80107007:	6a 7f                	push   $0x7f
  jmp alltraps
80107009:	e9 6a f5 ff ff       	jmp    80106578 <alltraps>

8010700e <vector128>:
.globl vector128
vector128:
  pushl $0
8010700e:	6a 00                	push   $0x0
  pushl $128
80107010:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107015:	e9 5e f5 ff ff       	jmp    80106578 <alltraps>

8010701a <vector129>:
.globl vector129
vector129:
  pushl $0
8010701a:	6a 00                	push   $0x0
  pushl $129
8010701c:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107021:	e9 52 f5 ff ff       	jmp    80106578 <alltraps>

80107026 <vector130>:
.globl vector130
vector130:
  pushl $0
80107026:	6a 00                	push   $0x0
  pushl $130
80107028:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010702d:	e9 46 f5 ff ff       	jmp    80106578 <alltraps>

80107032 <vector131>:
.globl vector131
vector131:
  pushl $0
80107032:	6a 00                	push   $0x0
  pushl $131
80107034:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107039:	e9 3a f5 ff ff       	jmp    80106578 <alltraps>

8010703e <vector132>:
.globl vector132
vector132:
  pushl $0
8010703e:	6a 00                	push   $0x0
  pushl $132
80107040:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107045:	e9 2e f5 ff ff       	jmp    80106578 <alltraps>

8010704a <vector133>:
.globl vector133
vector133:
  pushl $0
8010704a:	6a 00                	push   $0x0
  pushl $133
8010704c:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107051:	e9 22 f5 ff ff       	jmp    80106578 <alltraps>

80107056 <vector134>:
.globl vector134
vector134:
  pushl $0
80107056:	6a 00                	push   $0x0
  pushl $134
80107058:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010705d:	e9 16 f5 ff ff       	jmp    80106578 <alltraps>

80107062 <vector135>:
.globl vector135
vector135:
  pushl $0
80107062:	6a 00                	push   $0x0
  pushl $135
80107064:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107069:	e9 0a f5 ff ff       	jmp    80106578 <alltraps>

8010706e <vector136>:
.globl vector136
vector136:
  pushl $0
8010706e:	6a 00                	push   $0x0
  pushl $136
80107070:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107075:	e9 fe f4 ff ff       	jmp    80106578 <alltraps>

8010707a <vector137>:
.globl vector137
vector137:
  pushl $0
8010707a:	6a 00                	push   $0x0
  pushl $137
8010707c:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107081:	e9 f2 f4 ff ff       	jmp    80106578 <alltraps>

80107086 <vector138>:
.globl vector138
vector138:
  pushl $0
80107086:	6a 00                	push   $0x0
  pushl $138
80107088:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
8010708d:	e9 e6 f4 ff ff       	jmp    80106578 <alltraps>

80107092 <vector139>:
.globl vector139
vector139:
  pushl $0
80107092:	6a 00                	push   $0x0
  pushl $139
80107094:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107099:	e9 da f4 ff ff       	jmp    80106578 <alltraps>

8010709e <vector140>:
.globl vector140
vector140:
  pushl $0
8010709e:	6a 00                	push   $0x0
  pushl $140
801070a0:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801070a5:	e9 ce f4 ff ff       	jmp    80106578 <alltraps>

801070aa <vector141>:
.globl vector141
vector141:
  pushl $0
801070aa:	6a 00                	push   $0x0
  pushl $141
801070ac:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801070b1:	e9 c2 f4 ff ff       	jmp    80106578 <alltraps>

801070b6 <vector142>:
.globl vector142
vector142:
  pushl $0
801070b6:	6a 00                	push   $0x0
  pushl $142
801070b8:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801070bd:	e9 b6 f4 ff ff       	jmp    80106578 <alltraps>

801070c2 <vector143>:
.globl vector143
vector143:
  pushl $0
801070c2:	6a 00                	push   $0x0
  pushl $143
801070c4:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801070c9:	e9 aa f4 ff ff       	jmp    80106578 <alltraps>

801070ce <vector144>:
.globl vector144
vector144:
  pushl $0
801070ce:	6a 00                	push   $0x0
  pushl $144
801070d0:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801070d5:	e9 9e f4 ff ff       	jmp    80106578 <alltraps>

801070da <vector145>:
.globl vector145
vector145:
  pushl $0
801070da:	6a 00                	push   $0x0
  pushl $145
801070dc:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801070e1:	e9 92 f4 ff ff       	jmp    80106578 <alltraps>

801070e6 <vector146>:
.globl vector146
vector146:
  pushl $0
801070e6:	6a 00                	push   $0x0
  pushl $146
801070e8:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801070ed:	e9 86 f4 ff ff       	jmp    80106578 <alltraps>

801070f2 <vector147>:
.globl vector147
vector147:
  pushl $0
801070f2:	6a 00                	push   $0x0
  pushl $147
801070f4:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801070f9:	e9 7a f4 ff ff       	jmp    80106578 <alltraps>

801070fe <vector148>:
.globl vector148
vector148:
  pushl $0
801070fe:	6a 00                	push   $0x0
  pushl $148
80107100:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107105:	e9 6e f4 ff ff       	jmp    80106578 <alltraps>

8010710a <vector149>:
.globl vector149
vector149:
  pushl $0
8010710a:	6a 00                	push   $0x0
  pushl $149
8010710c:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107111:	e9 62 f4 ff ff       	jmp    80106578 <alltraps>

80107116 <vector150>:
.globl vector150
vector150:
  pushl $0
80107116:	6a 00                	push   $0x0
  pushl $150
80107118:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010711d:	e9 56 f4 ff ff       	jmp    80106578 <alltraps>

80107122 <vector151>:
.globl vector151
vector151:
  pushl $0
80107122:	6a 00                	push   $0x0
  pushl $151
80107124:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107129:	e9 4a f4 ff ff       	jmp    80106578 <alltraps>

8010712e <vector152>:
.globl vector152
vector152:
  pushl $0
8010712e:	6a 00                	push   $0x0
  pushl $152
80107130:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107135:	e9 3e f4 ff ff       	jmp    80106578 <alltraps>

8010713a <vector153>:
.globl vector153
vector153:
  pushl $0
8010713a:	6a 00                	push   $0x0
  pushl $153
8010713c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107141:	e9 32 f4 ff ff       	jmp    80106578 <alltraps>

80107146 <vector154>:
.globl vector154
vector154:
  pushl $0
80107146:	6a 00                	push   $0x0
  pushl $154
80107148:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010714d:	e9 26 f4 ff ff       	jmp    80106578 <alltraps>

80107152 <vector155>:
.globl vector155
vector155:
  pushl $0
80107152:	6a 00                	push   $0x0
  pushl $155
80107154:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107159:	e9 1a f4 ff ff       	jmp    80106578 <alltraps>

8010715e <vector156>:
.globl vector156
vector156:
  pushl $0
8010715e:	6a 00                	push   $0x0
  pushl $156
80107160:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107165:	e9 0e f4 ff ff       	jmp    80106578 <alltraps>

8010716a <vector157>:
.globl vector157
vector157:
  pushl $0
8010716a:	6a 00                	push   $0x0
  pushl $157
8010716c:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107171:	e9 02 f4 ff ff       	jmp    80106578 <alltraps>

80107176 <vector158>:
.globl vector158
vector158:
  pushl $0
80107176:	6a 00                	push   $0x0
  pushl $158
80107178:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
8010717d:	e9 f6 f3 ff ff       	jmp    80106578 <alltraps>

80107182 <vector159>:
.globl vector159
vector159:
  pushl $0
80107182:	6a 00                	push   $0x0
  pushl $159
80107184:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107189:	e9 ea f3 ff ff       	jmp    80106578 <alltraps>

8010718e <vector160>:
.globl vector160
vector160:
  pushl $0
8010718e:	6a 00                	push   $0x0
  pushl $160
80107190:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107195:	e9 de f3 ff ff       	jmp    80106578 <alltraps>

8010719a <vector161>:
.globl vector161
vector161:
  pushl $0
8010719a:	6a 00                	push   $0x0
  pushl $161
8010719c:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801071a1:	e9 d2 f3 ff ff       	jmp    80106578 <alltraps>

801071a6 <vector162>:
.globl vector162
vector162:
  pushl $0
801071a6:	6a 00                	push   $0x0
  pushl $162
801071a8:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801071ad:	e9 c6 f3 ff ff       	jmp    80106578 <alltraps>

801071b2 <vector163>:
.globl vector163
vector163:
  pushl $0
801071b2:	6a 00                	push   $0x0
  pushl $163
801071b4:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801071b9:	e9 ba f3 ff ff       	jmp    80106578 <alltraps>

801071be <vector164>:
.globl vector164
vector164:
  pushl $0
801071be:	6a 00                	push   $0x0
  pushl $164
801071c0:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801071c5:	e9 ae f3 ff ff       	jmp    80106578 <alltraps>

801071ca <vector165>:
.globl vector165
vector165:
  pushl $0
801071ca:	6a 00                	push   $0x0
  pushl $165
801071cc:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801071d1:	e9 a2 f3 ff ff       	jmp    80106578 <alltraps>

801071d6 <vector166>:
.globl vector166
vector166:
  pushl $0
801071d6:	6a 00                	push   $0x0
  pushl $166
801071d8:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801071dd:	e9 96 f3 ff ff       	jmp    80106578 <alltraps>

801071e2 <vector167>:
.globl vector167
vector167:
  pushl $0
801071e2:	6a 00                	push   $0x0
  pushl $167
801071e4:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801071e9:	e9 8a f3 ff ff       	jmp    80106578 <alltraps>

801071ee <vector168>:
.globl vector168
vector168:
  pushl $0
801071ee:	6a 00                	push   $0x0
  pushl $168
801071f0:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801071f5:	e9 7e f3 ff ff       	jmp    80106578 <alltraps>

801071fa <vector169>:
.globl vector169
vector169:
  pushl $0
801071fa:	6a 00                	push   $0x0
  pushl $169
801071fc:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107201:	e9 72 f3 ff ff       	jmp    80106578 <alltraps>

80107206 <vector170>:
.globl vector170
vector170:
  pushl $0
80107206:	6a 00                	push   $0x0
  pushl $170
80107208:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010720d:	e9 66 f3 ff ff       	jmp    80106578 <alltraps>

80107212 <vector171>:
.globl vector171
vector171:
  pushl $0
80107212:	6a 00                	push   $0x0
  pushl $171
80107214:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107219:	e9 5a f3 ff ff       	jmp    80106578 <alltraps>

8010721e <vector172>:
.globl vector172
vector172:
  pushl $0
8010721e:	6a 00                	push   $0x0
  pushl $172
80107220:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107225:	e9 4e f3 ff ff       	jmp    80106578 <alltraps>

8010722a <vector173>:
.globl vector173
vector173:
  pushl $0
8010722a:	6a 00                	push   $0x0
  pushl $173
8010722c:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107231:	e9 42 f3 ff ff       	jmp    80106578 <alltraps>

80107236 <vector174>:
.globl vector174
vector174:
  pushl $0
80107236:	6a 00                	push   $0x0
  pushl $174
80107238:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010723d:	e9 36 f3 ff ff       	jmp    80106578 <alltraps>

80107242 <vector175>:
.globl vector175
vector175:
  pushl $0
80107242:	6a 00                	push   $0x0
  pushl $175
80107244:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107249:	e9 2a f3 ff ff       	jmp    80106578 <alltraps>

8010724e <vector176>:
.globl vector176
vector176:
  pushl $0
8010724e:	6a 00                	push   $0x0
  pushl $176
80107250:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107255:	e9 1e f3 ff ff       	jmp    80106578 <alltraps>

8010725a <vector177>:
.globl vector177
vector177:
  pushl $0
8010725a:	6a 00                	push   $0x0
  pushl $177
8010725c:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107261:	e9 12 f3 ff ff       	jmp    80106578 <alltraps>

80107266 <vector178>:
.globl vector178
vector178:
  pushl $0
80107266:	6a 00                	push   $0x0
  pushl $178
80107268:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
8010726d:	e9 06 f3 ff ff       	jmp    80106578 <alltraps>

80107272 <vector179>:
.globl vector179
vector179:
  pushl $0
80107272:	6a 00                	push   $0x0
  pushl $179
80107274:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107279:	e9 fa f2 ff ff       	jmp    80106578 <alltraps>

8010727e <vector180>:
.globl vector180
vector180:
  pushl $0
8010727e:	6a 00                	push   $0x0
  pushl $180
80107280:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107285:	e9 ee f2 ff ff       	jmp    80106578 <alltraps>

8010728a <vector181>:
.globl vector181
vector181:
  pushl $0
8010728a:	6a 00                	push   $0x0
  pushl $181
8010728c:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107291:	e9 e2 f2 ff ff       	jmp    80106578 <alltraps>

80107296 <vector182>:
.globl vector182
vector182:
  pushl $0
80107296:	6a 00                	push   $0x0
  pushl $182
80107298:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
8010729d:	e9 d6 f2 ff ff       	jmp    80106578 <alltraps>

801072a2 <vector183>:
.globl vector183
vector183:
  pushl $0
801072a2:	6a 00                	push   $0x0
  pushl $183
801072a4:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801072a9:	e9 ca f2 ff ff       	jmp    80106578 <alltraps>

801072ae <vector184>:
.globl vector184
vector184:
  pushl $0
801072ae:	6a 00                	push   $0x0
  pushl $184
801072b0:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801072b5:	e9 be f2 ff ff       	jmp    80106578 <alltraps>

801072ba <vector185>:
.globl vector185
vector185:
  pushl $0
801072ba:	6a 00                	push   $0x0
  pushl $185
801072bc:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801072c1:	e9 b2 f2 ff ff       	jmp    80106578 <alltraps>

801072c6 <vector186>:
.globl vector186
vector186:
  pushl $0
801072c6:	6a 00                	push   $0x0
  pushl $186
801072c8:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801072cd:	e9 a6 f2 ff ff       	jmp    80106578 <alltraps>

801072d2 <vector187>:
.globl vector187
vector187:
  pushl $0
801072d2:	6a 00                	push   $0x0
  pushl $187
801072d4:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801072d9:	e9 9a f2 ff ff       	jmp    80106578 <alltraps>

801072de <vector188>:
.globl vector188
vector188:
  pushl $0
801072de:	6a 00                	push   $0x0
  pushl $188
801072e0:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801072e5:	e9 8e f2 ff ff       	jmp    80106578 <alltraps>

801072ea <vector189>:
.globl vector189
vector189:
  pushl $0
801072ea:	6a 00                	push   $0x0
  pushl $189
801072ec:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801072f1:	e9 82 f2 ff ff       	jmp    80106578 <alltraps>

801072f6 <vector190>:
.globl vector190
vector190:
  pushl $0
801072f6:	6a 00                	push   $0x0
  pushl $190
801072f8:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801072fd:	e9 76 f2 ff ff       	jmp    80106578 <alltraps>

80107302 <vector191>:
.globl vector191
vector191:
  pushl $0
80107302:	6a 00                	push   $0x0
  pushl $191
80107304:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107309:	e9 6a f2 ff ff       	jmp    80106578 <alltraps>

8010730e <vector192>:
.globl vector192
vector192:
  pushl $0
8010730e:	6a 00                	push   $0x0
  pushl $192
80107310:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107315:	e9 5e f2 ff ff       	jmp    80106578 <alltraps>

8010731a <vector193>:
.globl vector193
vector193:
  pushl $0
8010731a:	6a 00                	push   $0x0
  pushl $193
8010731c:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107321:	e9 52 f2 ff ff       	jmp    80106578 <alltraps>

80107326 <vector194>:
.globl vector194
vector194:
  pushl $0
80107326:	6a 00                	push   $0x0
  pushl $194
80107328:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010732d:	e9 46 f2 ff ff       	jmp    80106578 <alltraps>

80107332 <vector195>:
.globl vector195
vector195:
  pushl $0
80107332:	6a 00                	push   $0x0
  pushl $195
80107334:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107339:	e9 3a f2 ff ff       	jmp    80106578 <alltraps>

8010733e <vector196>:
.globl vector196
vector196:
  pushl $0
8010733e:	6a 00                	push   $0x0
  pushl $196
80107340:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107345:	e9 2e f2 ff ff       	jmp    80106578 <alltraps>

8010734a <vector197>:
.globl vector197
vector197:
  pushl $0
8010734a:	6a 00                	push   $0x0
  pushl $197
8010734c:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107351:	e9 22 f2 ff ff       	jmp    80106578 <alltraps>

80107356 <vector198>:
.globl vector198
vector198:
  pushl $0
80107356:	6a 00                	push   $0x0
  pushl $198
80107358:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
8010735d:	e9 16 f2 ff ff       	jmp    80106578 <alltraps>

80107362 <vector199>:
.globl vector199
vector199:
  pushl $0
80107362:	6a 00                	push   $0x0
  pushl $199
80107364:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107369:	e9 0a f2 ff ff       	jmp    80106578 <alltraps>

8010736e <vector200>:
.globl vector200
vector200:
  pushl $0
8010736e:	6a 00                	push   $0x0
  pushl $200
80107370:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107375:	e9 fe f1 ff ff       	jmp    80106578 <alltraps>

8010737a <vector201>:
.globl vector201
vector201:
  pushl $0
8010737a:	6a 00                	push   $0x0
  pushl $201
8010737c:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107381:	e9 f2 f1 ff ff       	jmp    80106578 <alltraps>

80107386 <vector202>:
.globl vector202
vector202:
  pushl $0
80107386:	6a 00                	push   $0x0
  pushl $202
80107388:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
8010738d:	e9 e6 f1 ff ff       	jmp    80106578 <alltraps>

80107392 <vector203>:
.globl vector203
vector203:
  pushl $0
80107392:	6a 00                	push   $0x0
  pushl $203
80107394:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107399:	e9 da f1 ff ff       	jmp    80106578 <alltraps>

8010739e <vector204>:
.globl vector204
vector204:
  pushl $0
8010739e:	6a 00                	push   $0x0
  pushl $204
801073a0:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801073a5:	e9 ce f1 ff ff       	jmp    80106578 <alltraps>

801073aa <vector205>:
.globl vector205
vector205:
  pushl $0
801073aa:	6a 00                	push   $0x0
  pushl $205
801073ac:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801073b1:	e9 c2 f1 ff ff       	jmp    80106578 <alltraps>

801073b6 <vector206>:
.globl vector206
vector206:
  pushl $0
801073b6:	6a 00                	push   $0x0
  pushl $206
801073b8:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801073bd:	e9 b6 f1 ff ff       	jmp    80106578 <alltraps>

801073c2 <vector207>:
.globl vector207
vector207:
  pushl $0
801073c2:	6a 00                	push   $0x0
  pushl $207
801073c4:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801073c9:	e9 aa f1 ff ff       	jmp    80106578 <alltraps>

801073ce <vector208>:
.globl vector208
vector208:
  pushl $0
801073ce:	6a 00                	push   $0x0
  pushl $208
801073d0:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801073d5:	e9 9e f1 ff ff       	jmp    80106578 <alltraps>

801073da <vector209>:
.globl vector209
vector209:
  pushl $0
801073da:	6a 00                	push   $0x0
  pushl $209
801073dc:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801073e1:	e9 92 f1 ff ff       	jmp    80106578 <alltraps>

801073e6 <vector210>:
.globl vector210
vector210:
  pushl $0
801073e6:	6a 00                	push   $0x0
  pushl $210
801073e8:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801073ed:	e9 86 f1 ff ff       	jmp    80106578 <alltraps>

801073f2 <vector211>:
.globl vector211
vector211:
  pushl $0
801073f2:	6a 00                	push   $0x0
  pushl $211
801073f4:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
801073f9:	e9 7a f1 ff ff       	jmp    80106578 <alltraps>

801073fe <vector212>:
.globl vector212
vector212:
  pushl $0
801073fe:	6a 00                	push   $0x0
  pushl $212
80107400:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107405:	e9 6e f1 ff ff       	jmp    80106578 <alltraps>

8010740a <vector213>:
.globl vector213
vector213:
  pushl $0
8010740a:	6a 00                	push   $0x0
  pushl $213
8010740c:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107411:	e9 62 f1 ff ff       	jmp    80106578 <alltraps>

80107416 <vector214>:
.globl vector214
vector214:
  pushl $0
80107416:	6a 00                	push   $0x0
  pushl $214
80107418:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
8010741d:	e9 56 f1 ff ff       	jmp    80106578 <alltraps>

80107422 <vector215>:
.globl vector215
vector215:
  pushl $0
80107422:	6a 00                	push   $0x0
  pushl $215
80107424:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107429:	e9 4a f1 ff ff       	jmp    80106578 <alltraps>

8010742e <vector216>:
.globl vector216
vector216:
  pushl $0
8010742e:	6a 00                	push   $0x0
  pushl $216
80107430:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107435:	e9 3e f1 ff ff       	jmp    80106578 <alltraps>

8010743a <vector217>:
.globl vector217
vector217:
  pushl $0
8010743a:	6a 00                	push   $0x0
  pushl $217
8010743c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107441:	e9 32 f1 ff ff       	jmp    80106578 <alltraps>

80107446 <vector218>:
.globl vector218
vector218:
  pushl $0
80107446:	6a 00                	push   $0x0
  pushl $218
80107448:	68 da 00 00 00       	push   $0xda
  jmp alltraps
8010744d:	e9 26 f1 ff ff       	jmp    80106578 <alltraps>

80107452 <vector219>:
.globl vector219
vector219:
  pushl $0
80107452:	6a 00                	push   $0x0
  pushl $219
80107454:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107459:	e9 1a f1 ff ff       	jmp    80106578 <alltraps>

8010745e <vector220>:
.globl vector220
vector220:
  pushl $0
8010745e:	6a 00                	push   $0x0
  pushl $220
80107460:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107465:	e9 0e f1 ff ff       	jmp    80106578 <alltraps>

8010746a <vector221>:
.globl vector221
vector221:
  pushl $0
8010746a:	6a 00                	push   $0x0
  pushl $221
8010746c:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107471:	e9 02 f1 ff ff       	jmp    80106578 <alltraps>

80107476 <vector222>:
.globl vector222
vector222:
  pushl $0
80107476:	6a 00                	push   $0x0
  pushl $222
80107478:	68 de 00 00 00       	push   $0xde
  jmp alltraps
8010747d:	e9 f6 f0 ff ff       	jmp    80106578 <alltraps>

80107482 <vector223>:
.globl vector223
vector223:
  pushl $0
80107482:	6a 00                	push   $0x0
  pushl $223
80107484:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107489:	e9 ea f0 ff ff       	jmp    80106578 <alltraps>

8010748e <vector224>:
.globl vector224
vector224:
  pushl $0
8010748e:	6a 00                	push   $0x0
  pushl $224
80107490:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107495:	e9 de f0 ff ff       	jmp    80106578 <alltraps>

8010749a <vector225>:
.globl vector225
vector225:
  pushl $0
8010749a:	6a 00                	push   $0x0
  pushl $225
8010749c:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801074a1:	e9 d2 f0 ff ff       	jmp    80106578 <alltraps>

801074a6 <vector226>:
.globl vector226
vector226:
  pushl $0
801074a6:	6a 00                	push   $0x0
  pushl $226
801074a8:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801074ad:	e9 c6 f0 ff ff       	jmp    80106578 <alltraps>

801074b2 <vector227>:
.globl vector227
vector227:
  pushl $0
801074b2:	6a 00                	push   $0x0
  pushl $227
801074b4:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801074b9:	e9 ba f0 ff ff       	jmp    80106578 <alltraps>

801074be <vector228>:
.globl vector228
vector228:
  pushl $0
801074be:	6a 00                	push   $0x0
  pushl $228
801074c0:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801074c5:	e9 ae f0 ff ff       	jmp    80106578 <alltraps>

801074ca <vector229>:
.globl vector229
vector229:
  pushl $0
801074ca:	6a 00                	push   $0x0
  pushl $229
801074cc:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801074d1:	e9 a2 f0 ff ff       	jmp    80106578 <alltraps>

801074d6 <vector230>:
.globl vector230
vector230:
  pushl $0
801074d6:	6a 00                	push   $0x0
  pushl $230
801074d8:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801074dd:	e9 96 f0 ff ff       	jmp    80106578 <alltraps>

801074e2 <vector231>:
.globl vector231
vector231:
  pushl $0
801074e2:	6a 00                	push   $0x0
  pushl $231
801074e4:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801074e9:	e9 8a f0 ff ff       	jmp    80106578 <alltraps>

801074ee <vector232>:
.globl vector232
vector232:
  pushl $0
801074ee:	6a 00                	push   $0x0
  pushl $232
801074f0:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801074f5:	e9 7e f0 ff ff       	jmp    80106578 <alltraps>

801074fa <vector233>:
.globl vector233
vector233:
  pushl $0
801074fa:	6a 00                	push   $0x0
  pushl $233
801074fc:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107501:	e9 72 f0 ff ff       	jmp    80106578 <alltraps>

80107506 <vector234>:
.globl vector234
vector234:
  pushl $0
80107506:	6a 00                	push   $0x0
  pushl $234
80107508:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010750d:	e9 66 f0 ff ff       	jmp    80106578 <alltraps>

80107512 <vector235>:
.globl vector235
vector235:
  pushl $0
80107512:	6a 00                	push   $0x0
  pushl $235
80107514:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107519:	e9 5a f0 ff ff       	jmp    80106578 <alltraps>

8010751e <vector236>:
.globl vector236
vector236:
  pushl $0
8010751e:	6a 00                	push   $0x0
  pushl $236
80107520:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107525:	e9 4e f0 ff ff       	jmp    80106578 <alltraps>

8010752a <vector237>:
.globl vector237
vector237:
  pushl $0
8010752a:	6a 00                	push   $0x0
  pushl $237
8010752c:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107531:	e9 42 f0 ff ff       	jmp    80106578 <alltraps>

80107536 <vector238>:
.globl vector238
vector238:
  pushl $0
80107536:	6a 00                	push   $0x0
  pushl $238
80107538:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010753d:	e9 36 f0 ff ff       	jmp    80106578 <alltraps>

80107542 <vector239>:
.globl vector239
vector239:
  pushl $0
80107542:	6a 00                	push   $0x0
  pushl $239
80107544:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107549:	e9 2a f0 ff ff       	jmp    80106578 <alltraps>

8010754e <vector240>:
.globl vector240
vector240:
  pushl $0
8010754e:	6a 00                	push   $0x0
  pushl $240
80107550:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107555:	e9 1e f0 ff ff       	jmp    80106578 <alltraps>

8010755a <vector241>:
.globl vector241
vector241:
  pushl $0
8010755a:	6a 00                	push   $0x0
  pushl $241
8010755c:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107561:	e9 12 f0 ff ff       	jmp    80106578 <alltraps>

80107566 <vector242>:
.globl vector242
vector242:
  pushl $0
80107566:	6a 00                	push   $0x0
  pushl $242
80107568:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
8010756d:	e9 06 f0 ff ff       	jmp    80106578 <alltraps>

80107572 <vector243>:
.globl vector243
vector243:
  pushl $0
80107572:	6a 00                	push   $0x0
  pushl $243
80107574:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107579:	e9 fa ef ff ff       	jmp    80106578 <alltraps>

8010757e <vector244>:
.globl vector244
vector244:
  pushl $0
8010757e:	6a 00                	push   $0x0
  pushl $244
80107580:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107585:	e9 ee ef ff ff       	jmp    80106578 <alltraps>

8010758a <vector245>:
.globl vector245
vector245:
  pushl $0
8010758a:	6a 00                	push   $0x0
  pushl $245
8010758c:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107591:	e9 e2 ef ff ff       	jmp    80106578 <alltraps>

80107596 <vector246>:
.globl vector246
vector246:
  pushl $0
80107596:	6a 00                	push   $0x0
  pushl $246
80107598:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
8010759d:	e9 d6 ef ff ff       	jmp    80106578 <alltraps>

801075a2 <vector247>:
.globl vector247
vector247:
  pushl $0
801075a2:	6a 00                	push   $0x0
  pushl $247
801075a4:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801075a9:	e9 ca ef ff ff       	jmp    80106578 <alltraps>

801075ae <vector248>:
.globl vector248
vector248:
  pushl $0
801075ae:	6a 00                	push   $0x0
  pushl $248
801075b0:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801075b5:	e9 be ef ff ff       	jmp    80106578 <alltraps>

801075ba <vector249>:
.globl vector249
vector249:
  pushl $0
801075ba:	6a 00                	push   $0x0
  pushl $249
801075bc:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801075c1:	e9 b2 ef ff ff       	jmp    80106578 <alltraps>

801075c6 <vector250>:
.globl vector250
vector250:
  pushl $0
801075c6:	6a 00                	push   $0x0
  pushl $250
801075c8:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801075cd:	e9 a6 ef ff ff       	jmp    80106578 <alltraps>

801075d2 <vector251>:
.globl vector251
vector251:
  pushl $0
801075d2:	6a 00                	push   $0x0
  pushl $251
801075d4:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801075d9:	e9 9a ef ff ff       	jmp    80106578 <alltraps>

801075de <vector252>:
.globl vector252
vector252:
  pushl $0
801075de:	6a 00                	push   $0x0
  pushl $252
801075e0:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801075e5:	e9 8e ef ff ff       	jmp    80106578 <alltraps>

801075ea <vector253>:
.globl vector253
vector253:
  pushl $0
801075ea:	6a 00                	push   $0x0
  pushl $253
801075ec:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801075f1:	e9 82 ef ff ff       	jmp    80106578 <alltraps>

801075f6 <vector254>:
.globl vector254
vector254:
  pushl $0
801075f6:	6a 00                	push   $0x0
  pushl $254
801075f8:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801075fd:	e9 76 ef ff ff       	jmp    80106578 <alltraps>

80107602 <vector255>:
.globl vector255
vector255:
  pushl $0
80107602:	6a 00                	push   $0x0
  pushl $255
80107604:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107609:	e9 6a ef ff ff       	jmp    80106578 <alltraps>

8010760e <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
8010760e:	55                   	push   %ebp
8010760f:	89 e5                	mov    %esp,%ebp
80107611:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107614:	8b 45 0c             	mov    0xc(%ebp),%eax
80107617:	83 e8 01             	sub    $0x1,%eax
8010761a:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010761e:	8b 45 08             	mov    0x8(%ebp),%eax
80107621:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107625:	8b 45 08             	mov    0x8(%ebp),%eax
80107628:	c1 e8 10             	shr    $0x10,%eax
8010762b:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
8010762f:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107632:	0f 01 10             	lgdtl  (%eax)
}
80107635:	90                   	nop
80107636:	c9                   	leave  
80107637:	c3                   	ret    

80107638 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107638:	55                   	push   %ebp
80107639:	89 e5                	mov    %esp,%ebp
8010763b:	83 ec 04             	sub    $0x4,%esp
8010763e:	8b 45 08             	mov    0x8(%ebp),%eax
80107641:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107645:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107649:	0f 00 d8             	ltr    %ax
}
8010764c:	90                   	nop
8010764d:	c9                   	leave  
8010764e:	c3                   	ret    

8010764f <lcr3>:
  return val;
}

static inline void
lcr3(uint val)
{
8010764f:	55                   	push   %ebp
80107650:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107652:	8b 45 08             	mov    0x8(%ebp),%eax
80107655:	0f 22 d8             	mov    %eax,%cr3
}
80107658:	90                   	nop
80107659:	5d                   	pop    %ebp
8010765a:	c3                   	ret    

8010765b <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
8010765b:	55                   	push   %ebp
8010765c:	89 e5                	mov    %esp,%ebp
8010765e:	83 ec 18             	sub    $0x18,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpuid()];
80107661:	e8 89 cb ff ff       	call   801041ef <cpuid>
80107666:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
8010766c:	05 00 38 11 80       	add    $0x80113800,%eax
80107671:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107674:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107677:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
8010767d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107680:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107686:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107689:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
8010768d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107690:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107694:	83 e2 f0             	and    $0xfffffff0,%edx
80107697:	83 ca 0a             	or     $0xa,%edx
8010769a:	88 50 7d             	mov    %dl,0x7d(%eax)
8010769d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076a0:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801076a4:	83 ca 10             	or     $0x10,%edx
801076a7:	88 50 7d             	mov    %dl,0x7d(%eax)
801076aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ad:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801076b1:	83 e2 9f             	and    $0xffffff9f,%edx
801076b4:	88 50 7d             	mov    %dl,0x7d(%eax)
801076b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ba:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801076be:	83 ca 80             	or     $0xffffff80,%edx
801076c1:	88 50 7d             	mov    %dl,0x7d(%eax)
801076c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076c7:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801076cb:	83 ca 0f             	or     $0xf,%edx
801076ce:	88 50 7e             	mov    %dl,0x7e(%eax)
801076d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076d4:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801076d8:	83 e2 ef             	and    $0xffffffef,%edx
801076db:	88 50 7e             	mov    %dl,0x7e(%eax)
801076de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076e1:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801076e5:	83 e2 df             	and    $0xffffffdf,%edx
801076e8:	88 50 7e             	mov    %dl,0x7e(%eax)
801076eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ee:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801076f2:	83 ca 40             	or     $0x40,%edx
801076f5:	88 50 7e             	mov    %dl,0x7e(%eax)
801076f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076fb:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801076ff:	83 ca 80             	or     $0xffffff80,%edx
80107702:	88 50 7e             	mov    %dl,0x7e(%eax)
80107705:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107708:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010770c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010770f:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107716:	ff ff 
80107718:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010771b:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107722:	00 00 
80107724:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107727:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
8010772e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107731:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107738:	83 e2 f0             	and    $0xfffffff0,%edx
8010773b:	83 ca 02             	or     $0x2,%edx
8010773e:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107744:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107747:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010774e:	83 ca 10             	or     $0x10,%edx
80107751:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010775a:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107761:	83 e2 9f             	and    $0xffffff9f,%edx
80107764:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010776a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010776d:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107774:	83 ca 80             	or     $0xffffff80,%edx
80107777:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010777d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107780:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107787:	83 ca 0f             	or     $0xf,%edx
8010778a:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107790:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107793:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010779a:	83 e2 ef             	and    $0xffffffef,%edx
8010779d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077a6:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801077ad:	83 e2 df             	and    $0xffffffdf,%edx
801077b0:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b9:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801077c0:	83 ca 40             	or     $0x40,%edx
801077c3:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077cc:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801077d3:	83 ca 80             	or     $0xffffff80,%edx
801077d6:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077df:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801077e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e9:	66 c7 80 88 00 00 00 	movw   $0xffff,0x88(%eax)
801077f0:	ff ff 
801077f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f5:	66 c7 80 8a 00 00 00 	movw   $0x0,0x8a(%eax)
801077fc:	00 00 
801077fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107801:	c6 80 8c 00 00 00 00 	movb   $0x0,0x8c(%eax)
80107808:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010780b:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
80107812:	83 e2 f0             	and    $0xfffffff0,%edx
80107815:	83 ca 0a             	or     $0xa,%edx
80107818:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
8010781e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107821:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
80107828:	83 ca 10             	or     $0x10,%edx
8010782b:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
80107831:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107834:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
8010783b:	83 ca 60             	or     $0x60,%edx
8010783e:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
80107844:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107847:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
8010784e:	83 ca 80             	or     $0xffffff80,%edx
80107851:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
80107857:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010785a:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
80107861:	83 ca 0f             	or     $0xf,%edx
80107864:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
8010786a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010786d:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
80107874:	83 e2 ef             	and    $0xffffffef,%edx
80107877:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
8010787d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107880:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
80107887:	83 e2 df             	and    $0xffffffdf,%edx
8010788a:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
80107890:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107893:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
8010789a:	83 ca 40             	or     $0x40,%edx
8010789d:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
801078a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078a6:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
801078ad:	83 ca 80             	or     $0xffffff80,%edx
801078b0:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
801078b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078b9:	c6 80 8f 00 00 00 00 	movb   $0x0,0x8f(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801078c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c3:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
801078ca:	ff ff 
801078cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078cf:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
801078d6:	00 00 
801078d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078db:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801078e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078e5:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801078ec:	83 e2 f0             	and    $0xfffffff0,%edx
801078ef:	83 ca 02             	or     $0x2,%edx
801078f2:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801078f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078fb:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107902:	83 ca 10             	or     $0x10,%edx
80107905:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010790b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010790e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107915:	83 ca 60             	or     $0x60,%edx
80107918:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010791e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107921:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107928:	83 ca 80             	or     $0xffffff80,%edx
8010792b:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107931:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107934:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010793b:	83 ca 0f             	or     $0xf,%edx
8010793e:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107944:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107947:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010794e:	83 e2 ef             	and    $0xffffffef,%edx
80107951:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107957:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010795a:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107961:	83 e2 df             	and    $0xffffffdf,%edx
80107964:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010796a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010796d:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107974:	83 ca 40             	or     $0x40,%edx
80107977:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010797d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107980:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107987:	83 ca 80             	or     $0xffffff80,%edx
8010798a:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107990:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107993:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
8010799a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010799d:	83 c0 70             	add    $0x70,%eax
801079a0:	83 ec 08             	sub    $0x8,%esp
801079a3:	6a 30                	push   $0x30
801079a5:	50                   	push   %eax
801079a6:	e8 63 fc ff ff       	call   8010760e <lgdt>
801079ab:	83 c4 10             	add    $0x10,%esp
}
801079ae:	90                   	nop
801079af:	c9                   	leave  
801079b0:	c3                   	ret    

801079b1 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
801079b1:	55                   	push   %ebp
801079b2:	89 e5                	mov    %esp,%ebp
801079b4:	83 ec 18             	sub    $0x18,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
801079b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801079ba:	c1 e8 16             	shr    $0x16,%eax
801079bd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801079c4:	8b 45 08             	mov    0x8(%ebp),%eax
801079c7:	01 d0                	add    %edx,%eax
801079c9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801079cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801079cf:	8b 00                	mov    (%eax),%eax
801079d1:	83 e0 01             	and    $0x1,%eax
801079d4:	85 c0                	test   %eax,%eax
801079d6:	74 14                	je     801079ec <walkpgdir+0x3b>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
801079d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801079db:	8b 00                	mov    (%eax),%eax
801079dd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801079e2:	05 00 00 00 80       	add    $0x80000000,%eax
801079e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801079ea:	eb 42                	jmp    80107a2e <walkpgdir+0x7d>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801079ec:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801079f0:	74 0e                	je     80107a00 <walkpgdir+0x4f>
801079f2:	e8 9e b2 ff ff       	call   80102c95 <kalloc>
801079f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801079fa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801079fe:	75 07                	jne    80107a07 <walkpgdir+0x56>
      return 0;
80107a00:	b8 00 00 00 00       	mov    $0x0,%eax
80107a05:	eb 3e                	jmp    80107a45 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107a07:	83 ec 04             	sub    $0x4,%esp
80107a0a:	68 00 10 00 00       	push   $0x1000
80107a0f:	6a 00                	push   $0x0
80107a11:	ff 75 f4             	pushl  -0xc(%ebp)
80107a14:	e8 e9 d7 ff ff       	call   80105202 <memset>
80107a19:	83 c4 10             	add    $0x10,%esp
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80107a1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a1f:	05 00 00 00 80       	add    $0x80000000,%eax
80107a24:	83 c8 07             	or     $0x7,%eax
80107a27:	89 c2                	mov    %eax,%edx
80107a29:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a2c:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107a2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80107a31:	c1 e8 0c             	shr    $0xc,%eax
80107a34:	25 ff 03 00 00       	and    $0x3ff,%eax
80107a39:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107a40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a43:	01 d0                	add    %edx,%eax
}
80107a45:	c9                   	leave  
80107a46:	c3                   	ret    

80107a47 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107a47:	55                   	push   %ebp
80107a48:	89 e5                	mov    %esp,%ebp
80107a4a:	83 ec 18             	sub    $0x18,%esp
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80107a4d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107a50:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107a55:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107a58:	8b 55 0c             	mov    0xc(%ebp),%edx
80107a5b:	8b 45 10             	mov    0x10(%ebp),%eax
80107a5e:	01 d0                	add    %edx,%eax
80107a60:	83 e8 01             	sub    $0x1,%eax
80107a63:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107a68:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107a6b:	83 ec 04             	sub    $0x4,%esp
80107a6e:	6a 01                	push   $0x1
80107a70:	ff 75 f4             	pushl  -0xc(%ebp)
80107a73:	ff 75 08             	pushl  0x8(%ebp)
80107a76:	e8 36 ff ff ff       	call   801079b1 <walkpgdir>
80107a7b:	83 c4 10             	add    $0x10,%esp
80107a7e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107a81:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107a85:	75 07                	jne    80107a8e <mappages+0x47>
      return -1;
80107a87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107a8c:	eb 47                	jmp    80107ad5 <mappages+0x8e>
    if(*pte & PTE_P)
80107a8e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107a91:	8b 00                	mov    (%eax),%eax
80107a93:	83 e0 01             	and    $0x1,%eax
80107a96:	85 c0                	test   %eax,%eax
80107a98:	74 0d                	je     80107aa7 <mappages+0x60>
      panic("remap");
80107a9a:	83 ec 0c             	sub    $0xc,%esp
80107a9d:	68 44 89 10 80       	push   $0x80108944
80107aa2:	e8 f9 8a ff ff       	call   801005a0 <panic>
    *pte = pa | perm | PTE_P;
80107aa7:	8b 45 18             	mov    0x18(%ebp),%eax
80107aaa:	0b 45 14             	or     0x14(%ebp),%eax
80107aad:	83 c8 01             	or     $0x1,%eax
80107ab0:	89 c2                	mov    %eax,%edx
80107ab2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107ab5:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107ab7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aba:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107abd:	74 10                	je     80107acf <mappages+0x88>
      break;
    a += PGSIZE;
80107abf:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107ac6:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107acd:	eb 9c                	jmp    80107a6b <mappages+0x24>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107acf:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107ad0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107ad5:	c9                   	leave  
80107ad6:	c3                   	ret    

80107ad7 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107ad7:	55                   	push   %ebp
80107ad8:	89 e5                	mov    %esp,%ebp
80107ada:	53                   	push   %ebx
80107adb:	83 ec 14             	sub    $0x14,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107ade:	e8 b2 b1 ff ff       	call   80102c95 <kalloc>
80107ae3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107ae6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107aea:	75 07                	jne    80107af3 <setupkvm+0x1c>
    return 0;
80107aec:	b8 00 00 00 00       	mov    $0x0,%eax
80107af1:	eb 78                	jmp    80107b6b <setupkvm+0x94>
  memset(pgdir, 0, PGSIZE);
80107af3:	83 ec 04             	sub    $0x4,%esp
80107af6:	68 00 10 00 00       	push   $0x1000
80107afb:	6a 00                	push   $0x0
80107afd:	ff 75 f0             	pushl  -0x10(%ebp)
80107b00:	e8 fd d6 ff ff       	call   80105202 <memset>
80107b05:	83 c4 10             	add    $0x10,%esp
  if (P2V(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107b08:	c7 45 f4 80 b4 10 80 	movl   $0x8010b480,-0xc(%ebp)
80107b0f:	eb 4e                	jmp    80107b5f <setupkvm+0x88>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80107b11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b14:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0) {
80107b17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b1a:	8b 50 04             	mov    0x4(%eax),%edx
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (P2V(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80107b1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b20:	8b 58 08             	mov    0x8(%eax),%ebx
80107b23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b26:	8b 40 04             	mov    0x4(%eax),%eax
80107b29:	29 c3                	sub    %eax,%ebx
80107b2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b2e:	8b 00                	mov    (%eax),%eax
80107b30:	83 ec 0c             	sub    $0xc,%esp
80107b33:	51                   	push   %ecx
80107b34:	52                   	push   %edx
80107b35:	53                   	push   %ebx
80107b36:	50                   	push   %eax
80107b37:	ff 75 f0             	pushl  -0x10(%ebp)
80107b3a:	e8 08 ff ff ff       	call   80107a47 <mappages>
80107b3f:	83 c4 20             	add    $0x20,%esp
80107b42:	85 c0                	test   %eax,%eax
80107b44:	79 15                	jns    80107b5b <setupkvm+0x84>
                (uint)k->phys_start, k->perm) < 0) {
      freevm(pgdir);
80107b46:	83 ec 0c             	sub    $0xc,%esp
80107b49:	ff 75 f0             	pushl  -0x10(%ebp)
80107b4c:	e8 f4 04 00 00       	call   80108045 <freevm>
80107b51:	83 c4 10             	add    $0x10,%esp
      return 0;
80107b54:	b8 00 00 00 00       	mov    $0x0,%eax
80107b59:	eb 10                	jmp    80107b6b <setupkvm+0x94>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (P2V(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107b5b:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107b5f:	81 7d f4 c0 b4 10 80 	cmpl   $0x8010b4c0,-0xc(%ebp)
80107b66:	72 a9                	jb     80107b11 <setupkvm+0x3a>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
                (uint)k->phys_start, k->perm) < 0) {
      freevm(pgdir);
      return 0;
    }
  return pgdir;
80107b68:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107b6b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80107b6e:	c9                   	leave  
80107b6f:	c3                   	ret    

80107b70 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107b70:	55                   	push   %ebp
80107b71:	89 e5                	mov    %esp,%ebp
80107b73:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107b76:	e8 5c ff ff ff       	call   80107ad7 <setupkvm>
80107b7b:	a3 24 65 11 80       	mov    %eax,0x80116524
  switchkvm();
80107b80:	e8 03 00 00 00       	call   80107b88 <switchkvm>
}
80107b85:	90                   	nop
80107b86:	c9                   	leave  
80107b87:	c3                   	ret    

80107b88 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107b88:	55                   	push   %ebp
80107b89:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80107b8b:	a1 24 65 11 80       	mov    0x80116524,%eax
80107b90:	05 00 00 00 80       	add    $0x80000000,%eax
80107b95:	50                   	push   %eax
80107b96:	e8 b4 fa ff ff       	call   8010764f <lcr3>
80107b9b:	83 c4 04             	add    $0x4,%esp
}
80107b9e:	90                   	nop
80107b9f:	c9                   	leave  
80107ba0:	c3                   	ret    

80107ba1 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107ba1:	55                   	push   %ebp
80107ba2:	89 e5                	mov    %esp,%ebp
80107ba4:	56                   	push   %esi
80107ba5:	53                   	push   %ebx
80107ba6:	83 ec 10             	sub    $0x10,%esp
  if(p == 0)
80107ba9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80107bad:	75 0d                	jne    80107bbc <switchuvm+0x1b>
    panic("switchuvm: no process");
80107baf:	83 ec 0c             	sub    $0xc,%esp
80107bb2:	68 4a 89 10 80       	push   $0x8010894a
80107bb7:	e8 e4 89 ff ff       	call   801005a0 <panic>
  if(p->kstack == 0)
80107bbc:	8b 45 08             	mov    0x8(%ebp),%eax
80107bbf:	8b 40 08             	mov    0x8(%eax),%eax
80107bc2:	85 c0                	test   %eax,%eax
80107bc4:	75 0d                	jne    80107bd3 <switchuvm+0x32>
    panic("switchuvm: no kstack");
80107bc6:	83 ec 0c             	sub    $0xc,%esp
80107bc9:	68 60 89 10 80       	push   $0x80108960
80107bce:	e8 cd 89 ff ff       	call   801005a0 <panic>
  if(p->pgdir == 0)
80107bd3:	8b 45 08             	mov    0x8(%ebp),%eax
80107bd6:	8b 40 04             	mov    0x4(%eax),%eax
80107bd9:	85 c0                	test   %eax,%eax
80107bdb:	75 0d                	jne    80107bea <switchuvm+0x49>
    panic("switchuvm: no pgdir");
80107bdd:	83 ec 0c             	sub    $0xc,%esp
80107be0:	68 75 89 10 80       	push   $0x80108975
80107be5:	e8 b6 89 ff ff       	call   801005a0 <panic>

  pushcli();
80107bea:	e8 07 d5 ff ff       	call   801050f6 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80107bef:	e8 1c c6 ff ff       	call   80104210 <mycpu>
80107bf4:	89 c3                	mov    %eax,%ebx
80107bf6:	e8 15 c6 ff ff       	call   80104210 <mycpu>
80107bfb:	83 c0 08             	add    $0x8,%eax
80107bfe:	89 c6                	mov    %eax,%esi
80107c00:	e8 0b c6 ff ff       	call   80104210 <mycpu>
80107c05:	83 c0 08             	add    $0x8,%eax
80107c08:	c1 e8 10             	shr    $0x10,%eax
80107c0b:	88 45 f7             	mov    %al,-0x9(%ebp)
80107c0e:	e8 fd c5 ff ff       	call   80104210 <mycpu>
80107c13:	83 c0 08             	add    $0x8,%eax
80107c16:	c1 e8 18             	shr    $0x18,%eax
80107c19:	89 c2                	mov    %eax,%edx
80107c1b:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80107c22:	67 00 
80107c24:	66 89 b3 9a 00 00 00 	mov    %si,0x9a(%ebx)
80107c2b:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
80107c2f:	88 83 9c 00 00 00    	mov    %al,0x9c(%ebx)
80107c35:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107c3c:	83 e0 f0             	and    $0xfffffff0,%eax
80107c3f:	83 c8 09             	or     $0x9,%eax
80107c42:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107c48:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107c4f:	83 c8 10             	or     $0x10,%eax
80107c52:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107c58:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107c5f:	83 e0 9f             	and    $0xffffff9f,%eax
80107c62:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107c68:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107c6f:	83 c8 80             	or     $0xffffff80,%eax
80107c72:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107c78:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107c7f:	83 e0 f0             	and    $0xfffffff0,%eax
80107c82:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107c88:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107c8f:	83 e0 ef             	and    $0xffffffef,%eax
80107c92:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107c98:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107c9f:	83 e0 df             	and    $0xffffffdf,%eax
80107ca2:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107ca8:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107caf:	83 c8 40             	or     $0x40,%eax
80107cb2:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107cb8:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107cbf:	83 e0 7f             	and    $0x7f,%eax
80107cc2:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107cc8:	88 93 9f 00 00 00    	mov    %dl,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80107cce:	e8 3d c5 ff ff       	call   80104210 <mycpu>
80107cd3:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107cda:	83 e2 ef             	and    $0xffffffef,%edx
80107cdd:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80107ce3:	e8 28 c5 ff ff       	call   80104210 <mycpu>
80107ce8:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80107cee:	e8 1d c5 ff ff       	call   80104210 <mycpu>
80107cf3:	89 c2                	mov    %eax,%edx
80107cf5:	8b 45 08             	mov    0x8(%ebp),%eax
80107cf8:	8b 40 08             	mov    0x8(%eax),%eax
80107cfb:	05 00 10 00 00       	add    $0x1000,%eax
80107d00:	89 42 0c             	mov    %eax,0xc(%edx)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80107d03:	e8 08 c5 ff ff       	call   80104210 <mycpu>
80107d08:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  ltr(SEG_TSS << 3);
80107d0e:	83 ec 0c             	sub    $0xc,%esp
80107d11:	6a 28                	push   $0x28
80107d13:	e8 20 f9 ff ff       	call   80107638 <ltr>
80107d18:	83 c4 10             	add    $0x10,%esp
  lcr3(V2P(p->pgdir));  // switch to process's address space
80107d1b:	8b 45 08             	mov    0x8(%ebp),%eax
80107d1e:	8b 40 04             	mov    0x4(%eax),%eax
80107d21:	05 00 00 00 80       	add    $0x80000000,%eax
80107d26:	83 ec 0c             	sub    $0xc,%esp
80107d29:	50                   	push   %eax
80107d2a:	e8 20 f9 ff ff       	call   8010764f <lcr3>
80107d2f:	83 c4 10             	add    $0x10,%esp
  popcli();
80107d32:	e8 0d d4 ff ff       	call   80105144 <popcli>
}
80107d37:	90                   	nop
80107d38:	8d 65 f8             	lea    -0x8(%ebp),%esp
80107d3b:	5b                   	pop    %ebx
80107d3c:	5e                   	pop    %esi
80107d3d:	5d                   	pop    %ebp
80107d3e:	c3                   	ret    

80107d3f <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107d3f:	55                   	push   %ebp
80107d40:	89 e5                	mov    %esp,%ebp
80107d42:	83 ec 18             	sub    $0x18,%esp
  char *mem;

  if(sz >= PGSIZE)
80107d45:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107d4c:	76 0d                	jbe    80107d5b <inituvm+0x1c>
    panic("inituvm: more than a page");
80107d4e:	83 ec 0c             	sub    $0xc,%esp
80107d51:	68 89 89 10 80       	push   $0x80108989
80107d56:	e8 45 88 ff ff       	call   801005a0 <panic>
  mem = kalloc();
80107d5b:	e8 35 af ff ff       	call   80102c95 <kalloc>
80107d60:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107d63:	83 ec 04             	sub    $0x4,%esp
80107d66:	68 00 10 00 00       	push   $0x1000
80107d6b:	6a 00                	push   $0x0
80107d6d:	ff 75 f4             	pushl  -0xc(%ebp)
80107d70:	e8 8d d4 ff ff       	call   80105202 <memset>
80107d75:	83 c4 10             	add    $0x10,%esp
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80107d78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d7b:	05 00 00 00 80       	add    $0x80000000,%eax
80107d80:	83 ec 0c             	sub    $0xc,%esp
80107d83:	6a 06                	push   $0x6
80107d85:	50                   	push   %eax
80107d86:	68 00 10 00 00       	push   $0x1000
80107d8b:	6a 00                	push   $0x0
80107d8d:	ff 75 08             	pushl  0x8(%ebp)
80107d90:	e8 b2 fc ff ff       	call   80107a47 <mappages>
80107d95:	83 c4 20             	add    $0x20,%esp
  memmove(mem, init, sz);
80107d98:	83 ec 04             	sub    $0x4,%esp
80107d9b:	ff 75 10             	pushl  0x10(%ebp)
80107d9e:	ff 75 0c             	pushl  0xc(%ebp)
80107da1:	ff 75 f4             	pushl  -0xc(%ebp)
80107da4:	e8 18 d5 ff ff       	call   801052c1 <memmove>
80107da9:	83 c4 10             	add    $0x10,%esp
}
80107dac:	90                   	nop
80107dad:	c9                   	leave  
80107dae:	c3                   	ret    

80107daf <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107daf:	55                   	push   %ebp
80107db0:	89 e5                	mov    %esp,%ebp
80107db2:	83 ec 18             	sub    $0x18,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107db5:	8b 45 0c             	mov    0xc(%ebp),%eax
80107db8:	25 ff 0f 00 00       	and    $0xfff,%eax
80107dbd:	85 c0                	test   %eax,%eax
80107dbf:	74 0d                	je     80107dce <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107dc1:	83 ec 0c             	sub    $0xc,%esp
80107dc4:	68 a4 89 10 80       	push   $0x801089a4
80107dc9:	e8 d2 87 ff ff       	call   801005a0 <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107dce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107dd5:	e9 8f 00 00 00       	jmp    80107e69 <loaduvm+0xba>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107dda:	8b 55 0c             	mov    0xc(%ebp),%edx
80107ddd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107de0:	01 d0                	add    %edx,%eax
80107de2:	83 ec 04             	sub    $0x4,%esp
80107de5:	6a 00                	push   $0x0
80107de7:	50                   	push   %eax
80107de8:	ff 75 08             	pushl  0x8(%ebp)
80107deb:	e8 c1 fb ff ff       	call   801079b1 <walkpgdir>
80107df0:	83 c4 10             	add    $0x10,%esp
80107df3:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107df6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107dfa:	75 0d                	jne    80107e09 <loaduvm+0x5a>
      panic("loaduvm: address should exist");
80107dfc:	83 ec 0c             	sub    $0xc,%esp
80107dff:	68 c7 89 10 80       	push   $0x801089c7
80107e04:	e8 97 87 ff ff       	call   801005a0 <panic>
    pa = PTE_ADDR(*pte);
80107e09:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107e0c:	8b 00                	mov    (%eax),%eax
80107e0e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107e13:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107e16:	8b 45 18             	mov    0x18(%ebp),%eax
80107e19:	2b 45 f4             	sub    -0xc(%ebp),%eax
80107e1c:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107e21:	77 0b                	ja     80107e2e <loaduvm+0x7f>
      n = sz - i;
80107e23:	8b 45 18             	mov    0x18(%ebp),%eax
80107e26:	2b 45 f4             	sub    -0xc(%ebp),%eax
80107e29:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107e2c:	eb 07                	jmp    80107e35 <loaduvm+0x86>
    else
      n = PGSIZE;
80107e2e:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, P2V(pa), offset+i, n) != n)
80107e35:	8b 55 14             	mov    0x14(%ebp),%edx
80107e38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e3b:	01 d0                	add    %edx,%eax
80107e3d:	8b 55 e8             	mov    -0x18(%ebp),%edx
80107e40:	81 c2 00 00 00 80    	add    $0x80000000,%edx
80107e46:	ff 75 f0             	pushl  -0x10(%ebp)
80107e49:	50                   	push   %eax
80107e4a:	52                   	push   %edx
80107e4b:	ff 75 10             	pushl  0x10(%ebp)
80107e4e:	e8 ae a0 ff ff       	call   80101f01 <readi>
80107e53:	83 c4 10             	add    $0x10,%esp
80107e56:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107e59:	74 07                	je     80107e62 <loaduvm+0xb3>
      return -1;
80107e5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107e60:	eb 18                	jmp    80107e7a <loaduvm+0xcb>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80107e62:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107e69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e6c:	3b 45 18             	cmp    0x18(%ebp),%eax
80107e6f:	0f 82 65 ff ff ff    	jb     80107dda <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80107e75:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107e7a:	c9                   	leave  
80107e7b:	c3                   	ret    

80107e7c <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107e7c:	55                   	push   %ebp
80107e7d:	89 e5                	mov    %esp,%ebp
80107e7f:	83 ec 18             	sub    $0x18,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107e82:	8b 45 10             	mov    0x10(%ebp),%eax
80107e85:	85 c0                	test   %eax,%eax
80107e87:	79 0a                	jns    80107e93 <allocuvm+0x17>
    return 0;
80107e89:	b8 00 00 00 00       	mov    $0x0,%eax
80107e8e:	e9 ec 00 00 00       	jmp    80107f7f <allocuvm+0x103>
  if(newsz < oldsz)
80107e93:	8b 45 10             	mov    0x10(%ebp),%eax
80107e96:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107e99:	73 08                	jae    80107ea3 <allocuvm+0x27>
    return oldsz;
80107e9b:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e9e:	e9 dc 00 00 00       	jmp    80107f7f <allocuvm+0x103>

  a = PGROUNDUP(oldsz);
80107ea3:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ea6:	05 ff 0f 00 00       	add    $0xfff,%eax
80107eab:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107eb0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80107eb3:	e9 b8 00 00 00       	jmp    80107f70 <allocuvm+0xf4>
    mem = kalloc();
80107eb8:	e8 d8 ad ff ff       	call   80102c95 <kalloc>
80107ebd:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80107ec0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107ec4:	75 2e                	jne    80107ef4 <allocuvm+0x78>
      cprintf("allocuvm out of memory\n");
80107ec6:	83 ec 0c             	sub    $0xc,%esp
80107ec9:	68 e5 89 10 80       	push   $0x801089e5
80107ece:	e8 2d 85 ff ff       	call   80100400 <cprintf>
80107ed3:	83 c4 10             	add    $0x10,%esp
      deallocuvm(pgdir, newsz, oldsz);
80107ed6:	83 ec 04             	sub    $0x4,%esp
80107ed9:	ff 75 0c             	pushl  0xc(%ebp)
80107edc:	ff 75 10             	pushl  0x10(%ebp)
80107edf:	ff 75 08             	pushl  0x8(%ebp)
80107ee2:	e8 9a 00 00 00       	call   80107f81 <deallocuvm>
80107ee7:	83 c4 10             	add    $0x10,%esp
      return 0;
80107eea:	b8 00 00 00 00       	mov    $0x0,%eax
80107eef:	e9 8b 00 00 00       	jmp    80107f7f <allocuvm+0x103>
    }
    memset(mem, 0, PGSIZE);
80107ef4:	83 ec 04             	sub    $0x4,%esp
80107ef7:	68 00 10 00 00       	push   $0x1000
80107efc:	6a 00                	push   $0x0
80107efe:	ff 75 f0             	pushl  -0x10(%ebp)
80107f01:	e8 fc d2 ff ff       	call   80105202 <memset>
80107f06:	83 c4 10             	add    $0x10,%esp
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80107f09:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f0c:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
80107f12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f15:	83 ec 0c             	sub    $0xc,%esp
80107f18:	6a 06                	push   $0x6
80107f1a:	52                   	push   %edx
80107f1b:	68 00 10 00 00       	push   $0x1000
80107f20:	50                   	push   %eax
80107f21:	ff 75 08             	pushl  0x8(%ebp)
80107f24:	e8 1e fb ff ff       	call   80107a47 <mappages>
80107f29:	83 c4 20             	add    $0x20,%esp
80107f2c:	85 c0                	test   %eax,%eax
80107f2e:	79 39                	jns    80107f69 <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
80107f30:	83 ec 0c             	sub    $0xc,%esp
80107f33:	68 fd 89 10 80       	push   $0x801089fd
80107f38:	e8 c3 84 ff ff       	call   80100400 <cprintf>
80107f3d:	83 c4 10             	add    $0x10,%esp
      deallocuvm(pgdir, newsz, oldsz);
80107f40:	83 ec 04             	sub    $0x4,%esp
80107f43:	ff 75 0c             	pushl  0xc(%ebp)
80107f46:	ff 75 10             	pushl  0x10(%ebp)
80107f49:	ff 75 08             	pushl  0x8(%ebp)
80107f4c:	e8 30 00 00 00       	call   80107f81 <deallocuvm>
80107f51:	83 c4 10             	add    $0x10,%esp
      kfree(mem);
80107f54:	83 ec 0c             	sub    $0xc,%esp
80107f57:	ff 75 f0             	pushl  -0x10(%ebp)
80107f5a:	e8 9c ac ff ff       	call   80102bfb <kfree>
80107f5f:	83 c4 10             	add    $0x10,%esp
      return 0;
80107f62:	b8 00 00 00 00       	mov    $0x0,%eax
80107f67:	eb 16                	jmp    80107f7f <allocuvm+0x103>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80107f69:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107f70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f73:	3b 45 10             	cmp    0x10(%ebp),%eax
80107f76:	0f 82 3c ff ff ff    	jb     80107eb8 <allocuvm+0x3c>
      deallocuvm(pgdir, newsz, oldsz);
      kfree(mem);
      return 0;
    }
  }
  return newsz;
80107f7c:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107f7f:	c9                   	leave  
80107f80:	c3                   	ret    

80107f81 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107f81:	55                   	push   %ebp
80107f82:	89 e5                	mov    %esp,%ebp
80107f84:	83 ec 18             	sub    $0x18,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80107f87:	8b 45 10             	mov    0x10(%ebp),%eax
80107f8a:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107f8d:	72 08                	jb     80107f97 <deallocuvm+0x16>
    return oldsz;
80107f8f:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f92:	e9 ac 00 00 00       	jmp    80108043 <deallocuvm+0xc2>

  a = PGROUNDUP(newsz);
80107f97:	8b 45 10             	mov    0x10(%ebp),%eax
80107f9a:	05 ff 0f 00 00       	add    $0xfff,%eax
80107f9f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107fa4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80107fa7:	e9 88 00 00 00       	jmp    80108034 <deallocuvm+0xb3>
    pte = walkpgdir(pgdir, (char*)a, 0);
80107fac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107faf:	83 ec 04             	sub    $0x4,%esp
80107fb2:	6a 00                	push   $0x0
80107fb4:	50                   	push   %eax
80107fb5:	ff 75 08             	pushl  0x8(%ebp)
80107fb8:	e8 f4 f9 ff ff       	call   801079b1 <walkpgdir>
80107fbd:	83 c4 10             	add    $0x10,%esp
80107fc0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80107fc3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107fc7:	75 16                	jne    80107fdf <deallocuvm+0x5e>
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80107fc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fcc:	c1 e8 16             	shr    $0x16,%eax
80107fcf:	83 c0 01             	add    $0x1,%eax
80107fd2:	c1 e0 16             	shl    $0x16,%eax
80107fd5:	2d 00 10 00 00       	sub    $0x1000,%eax
80107fda:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107fdd:	eb 4e                	jmp    8010802d <deallocuvm+0xac>
    else if((*pte & PTE_P) != 0){
80107fdf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107fe2:	8b 00                	mov    (%eax),%eax
80107fe4:	83 e0 01             	and    $0x1,%eax
80107fe7:	85 c0                	test   %eax,%eax
80107fe9:	74 42                	je     8010802d <deallocuvm+0xac>
      pa = PTE_ADDR(*pte);
80107feb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107fee:	8b 00                	mov    (%eax),%eax
80107ff0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107ff5:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80107ff8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107ffc:	75 0d                	jne    8010800b <deallocuvm+0x8a>
        panic("kfree");
80107ffe:	83 ec 0c             	sub    $0xc,%esp
80108001:	68 19 8a 10 80       	push   $0x80108a19
80108006:	e8 95 85 ff ff       	call   801005a0 <panic>
      char *v = P2V(pa);
8010800b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010800e:	05 00 00 00 80       	add    $0x80000000,%eax
80108013:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108016:	83 ec 0c             	sub    $0xc,%esp
80108019:	ff 75 e8             	pushl  -0x18(%ebp)
8010801c:	e8 da ab ff ff       	call   80102bfb <kfree>
80108021:	83 c4 10             	add    $0x10,%esp
      *pte = 0;
80108024:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108027:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
8010802d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108034:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108037:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010803a:	0f 82 6c ff ff ff    	jb     80107fac <deallocuvm+0x2b>
      char *v = P2V(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108040:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108043:	c9                   	leave  
80108044:	c3                   	ret    

80108045 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108045:	55                   	push   %ebp
80108046:	89 e5                	mov    %esp,%ebp
80108048:	83 ec 18             	sub    $0x18,%esp
  uint i;

  if(pgdir == 0)
8010804b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010804f:	75 0d                	jne    8010805e <freevm+0x19>
    panic("freevm: no pgdir");
80108051:	83 ec 0c             	sub    $0xc,%esp
80108054:	68 1f 8a 10 80       	push   $0x80108a1f
80108059:	e8 42 85 ff ff       	call   801005a0 <panic>
  deallocuvm(pgdir, KERNBASE, 0);
8010805e:	83 ec 04             	sub    $0x4,%esp
80108061:	6a 00                	push   $0x0
80108063:	68 00 00 00 80       	push   $0x80000000
80108068:	ff 75 08             	pushl  0x8(%ebp)
8010806b:	e8 11 ff ff ff       	call   80107f81 <deallocuvm>
80108070:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NPDENTRIES; i++){
80108073:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010807a:	eb 48                	jmp    801080c4 <freevm+0x7f>
    if(pgdir[i] & PTE_P){
8010807c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010807f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108086:	8b 45 08             	mov    0x8(%ebp),%eax
80108089:	01 d0                	add    %edx,%eax
8010808b:	8b 00                	mov    (%eax),%eax
8010808d:	83 e0 01             	and    $0x1,%eax
80108090:	85 c0                	test   %eax,%eax
80108092:	74 2c                	je     801080c0 <freevm+0x7b>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80108094:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108097:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010809e:	8b 45 08             	mov    0x8(%ebp),%eax
801080a1:	01 d0                	add    %edx,%eax
801080a3:	8b 00                	mov    (%eax),%eax
801080a5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801080aa:	05 00 00 00 80       	add    $0x80000000,%eax
801080af:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
801080b2:	83 ec 0c             	sub    $0xc,%esp
801080b5:	ff 75 f0             	pushl  -0x10(%ebp)
801080b8:	e8 3e ab ff ff       	call   80102bfb <kfree>
801080bd:	83 c4 10             	add    $0x10,%esp
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
801080c0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801080c4:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801080cb:	76 af                	jbe    8010807c <freevm+0x37>
    if(pgdir[i] & PTE_P){
      char * v = P2V(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
801080cd:	83 ec 0c             	sub    $0xc,%esp
801080d0:	ff 75 08             	pushl  0x8(%ebp)
801080d3:	e8 23 ab ff ff       	call   80102bfb <kfree>
801080d8:	83 c4 10             	add    $0x10,%esp
}
801080db:	90                   	nop
801080dc:	c9                   	leave  
801080dd:	c3                   	ret    

801080de <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801080de:	55                   	push   %ebp
801080df:	89 e5                	mov    %esp,%ebp
801080e1:	83 ec 18             	sub    $0x18,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801080e4:	83 ec 04             	sub    $0x4,%esp
801080e7:	6a 00                	push   $0x0
801080e9:	ff 75 0c             	pushl  0xc(%ebp)
801080ec:	ff 75 08             	pushl  0x8(%ebp)
801080ef:	e8 bd f8 ff ff       	call   801079b1 <walkpgdir>
801080f4:	83 c4 10             	add    $0x10,%esp
801080f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
801080fa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801080fe:	75 0d                	jne    8010810d <clearpteu+0x2f>
    panic("clearpteu");
80108100:	83 ec 0c             	sub    $0xc,%esp
80108103:	68 30 8a 10 80       	push   $0x80108a30
80108108:	e8 93 84 ff ff       	call   801005a0 <panic>
  *pte &= ~PTE_U;
8010810d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108110:	8b 00                	mov    (%eax),%eax
80108112:	83 e0 fb             	and    $0xfffffffb,%eax
80108115:	89 c2                	mov    %eax,%edx
80108117:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010811a:	89 10                	mov    %edx,(%eax)
}
8010811c:	90                   	nop
8010811d:	c9                   	leave  
8010811e:	c3                   	ret    

8010811f <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010811f:	55                   	push   %ebp
80108120:	89 e5                	mov    %esp,%ebp
80108122:	83 ec 28             	sub    $0x28,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108125:	e8 ad f9 ff ff       	call   80107ad7 <setupkvm>
8010812a:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010812d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108131:	75 0a                	jne    8010813d <copyuvm+0x1e>
    return 0;
80108133:	b8 00 00 00 00       	mov    $0x0,%eax
80108138:	e9 eb 00 00 00       	jmp    80108228 <copyuvm+0x109>
  for(i = 0; i < sz; i += PGSIZE){
8010813d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108144:	e9 b7 00 00 00       	jmp    80108200 <copyuvm+0xe1>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108149:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010814c:	83 ec 04             	sub    $0x4,%esp
8010814f:	6a 00                	push   $0x0
80108151:	50                   	push   %eax
80108152:	ff 75 08             	pushl  0x8(%ebp)
80108155:	e8 57 f8 ff ff       	call   801079b1 <walkpgdir>
8010815a:	83 c4 10             	add    $0x10,%esp
8010815d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108160:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108164:	75 0d                	jne    80108173 <copyuvm+0x54>
      panic("copyuvm: pte should exist");
80108166:	83 ec 0c             	sub    $0xc,%esp
80108169:	68 3a 8a 10 80       	push   $0x80108a3a
8010816e:	e8 2d 84 ff ff       	call   801005a0 <panic>
    if(!(*pte & PTE_P))
80108173:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108176:	8b 00                	mov    (%eax),%eax
80108178:	83 e0 01             	and    $0x1,%eax
8010817b:	85 c0                	test   %eax,%eax
8010817d:	75 0d                	jne    8010818c <copyuvm+0x6d>
      panic("copyuvm: page not present");
8010817f:	83 ec 0c             	sub    $0xc,%esp
80108182:	68 54 8a 10 80       	push   $0x80108a54
80108187:	e8 14 84 ff ff       	call   801005a0 <panic>
    pa = PTE_ADDR(*pte);
8010818c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010818f:	8b 00                	mov    (%eax),%eax
80108191:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108196:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80108199:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010819c:	8b 00                	mov    (%eax),%eax
8010819e:	25 ff 0f 00 00       	and    $0xfff,%eax
801081a3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
801081a6:	e8 ea aa ff ff       	call   80102c95 <kalloc>
801081ab:	89 45 e0             	mov    %eax,-0x20(%ebp)
801081ae:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801081b2:	74 5d                	je     80108211 <copyuvm+0xf2>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801081b4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801081b7:	05 00 00 00 80       	add    $0x80000000,%eax
801081bc:	83 ec 04             	sub    $0x4,%esp
801081bf:	68 00 10 00 00       	push   $0x1000
801081c4:	50                   	push   %eax
801081c5:	ff 75 e0             	pushl  -0x20(%ebp)
801081c8:	e8 f4 d0 ff ff       	call   801052c1 <memmove>
801081cd:	83 c4 10             	add    $0x10,%esp
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0)
801081d0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801081d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801081d6:	8d 88 00 00 00 80    	lea    -0x80000000(%eax),%ecx
801081dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081df:	83 ec 0c             	sub    $0xc,%esp
801081e2:	52                   	push   %edx
801081e3:	51                   	push   %ecx
801081e4:	68 00 10 00 00       	push   $0x1000
801081e9:	50                   	push   %eax
801081ea:	ff 75 f0             	pushl  -0x10(%ebp)
801081ed:	e8 55 f8 ff ff       	call   80107a47 <mappages>
801081f2:	83 c4 20             	add    $0x20,%esp
801081f5:	85 c0                	test   %eax,%eax
801081f7:	78 1b                	js     80108214 <copyuvm+0xf5>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801081f9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108200:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108203:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108206:	0f 82 3d ff ff ff    	jb     80108149 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0)
      goto bad;
  }
  return d;
8010820c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010820f:	eb 17                	jmp    80108228 <copyuvm+0x109>
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108211:	90                   	nop
80108212:	eb 01                	jmp    80108215 <copyuvm+0xf6>
    memmove(mem, (char*)P2V(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0)
      goto bad;
80108214:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80108215:	83 ec 0c             	sub    $0xc,%esp
80108218:	ff 75 f0             	pushl  -0x10(%ebp)
8010821b:	e8 25 fe ff ff       	call   80108045 <freevm>
80108220:	83 c4 10             	add    $0x10,%esp
  return 0;
80108223:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108228:	c9                   	leave  
80108229:	c3                   	ret    

8010822a <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010822a:	55                   	push   %ebp
8010822b:	89 e5                	mov    %esp,%ebp
8010822d:	83 ec 18             	sub    $0x18,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108230:	83 ec 04             	sub    $0x4,%esp
80108233:	6a 00                	push   $0x0
80108235:	ff 75 0c             	pushl  0xc(%ebp)
80108238:	ff 75 08             	pushl  0x8(%ebp)
8010823b:	e8 71 f7 ff ff       	call   801079b1 <walkpgdir>
80108240:	83 c4 10             	add    $0x10,%esp
80108243:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108246:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108249:	8b 00                	mov    (%eax),%eax
8010824b:	83 e0 01             	and    $0x1,%eax
8010824e:	85 c0                	test   %eax,%eax
80108250:	75 07                	jne    80108259 <uva2ka+0x2f>
    return 0;
80108252:	b8 00 00 00 00       	mov    $0x0,%eax
80108257:	eb 22                	jmp    8010827b <uva2ka+0x51>
  if((*pte & PTE_U) == 0)
80108259:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010825c:	8b 00                	mov    (%eax),%eax
8010825e:	83 e0 04             	and    $0x4,%eax
80108261:	85 c0                	test   %eax,%eax
80108263:	75 07                	jne    8010826c <uva2ka+0x42>
    return 0;
80108265:	b8 00 00 00 00       	mov    $0x0,%eax
8010826a:	eb 0f                	jmp    8010827b <uva2ka+0x51>
  return (char*)P2V(PTE_ADDR(*pte));
8010826c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010826f:	8b 00                	mov    (%eax),%eax
80108271:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108276:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010827b:	c9                   	leave  
8010827c:	c3                   	ret    

8010827d <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010827d:	55                   	push   %ebp
8010827e:	89 e5                	mov    %esp,%ebp
80108280:	83 ec 18             	sub    $0x18,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108283:	8b 45 10             	mov    0x10(%ebp),%eax
80108286:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108289:	eb 7f                	jmp    8010830a <copyout+0x8d>
    va0 = (uint)PGROUNDDOWN(va);
8010828b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010828e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108293:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108296:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108299:	83 ec 08             	sub    $0x8,%esp
8010829c:	50                   	push   %eax
8010829d:	ff 75 08             	pushl  0x8(%ebp)
801082a0:	e8 85 ff ff ff       	call   8010822a <uva2ka>
801082a5:	83 c4 10             	add    $0x10,%esp
801082a8:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801082ab:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801082af:	75 07                	jne    801082b8 <copyout+0x3b>
      return -1;
801082b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801082b6:	eb 61                	jmp    80108319 <copyout+0x9c>
    n = PGSIZE - (va - va0);
801082b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082bb:	2b 45 0c             	sub    0xc(%ebp),%eax
801082be:	05 00 10 00 00       	add    $0x1000,%eax
801082c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801082c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082c9:	3b 45 14             	cmp    0x14(%ebp),%eax
801082cc:	76 06                	jbe    801082d4 <copyout+0x57>
      n = len;
801082ce:	8b 45 14             	mov    0x14(%ebp),%eax
801082d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
801082d4:	8b 45 0c             	mov    0xc(%ebp),%eax
801082d7:	2b 45 ec             	sub    -0x14(%ebp),%eax
801082da:	89 c2                	mov    %eax,%edx
801082dc:	8b 45 e8             	mov    -0x18(%ebp),%eax
801082df:	01 d0                	add    %edx,%eax
801082e1:	83 ec 04             	sub    $0x4,%esp
801082e4:	ff 75 f0             	pushl  -0x10(%ebp)
801082e7:	ff 75 f4             	pushl  -0xc(%ebp)
801082ea:	50                   	push   %eax
801082eb:	e8 d1 cf ff ff       	call   801052c1 <memmove>
801082f0:	83 c4 10             	add    $0x10,%esp
    len -= n;
801082f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082f6:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801082f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082fc:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801082ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108302:	05 00 10 00 00       	add    $0x1000,%eax
80108307:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010830a:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010830e:	0f 85 77 ff ff ff    	jne    8010828b <copyout+0xe>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108314:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108319:	c9                   	leave  
8010831a:	c3                   	ret    
