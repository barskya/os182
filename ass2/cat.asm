
_cat:     file format elf32-i386


Disassembly of section .text:

00000000 <cat>:

char buf[512];

void
cat(int fd)
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 ec 18             	sub    $0x18,%esp
  int n;

  while((n = read(fd, buf, sizeof(buf))) > 0) {
   6:	eb 31                	jmp    39 <cat+0x39>
    if (write(1, buf, n) != n) {
   8:	83 ec 04             	sub    $0x4,%esp
   b:	ff 75 f4             	pushl  -0xc(%ebp)
   e:	68 a0 0b 00 00       	push   $0xba0
  13:	6a 01                	push   $0x1
  15:	e8 88 03 00 00       	call   3a2 <write>
  1a:	83 c4 10             	add    $0x10,%esp
  1d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  20:	74 17                	je     39 <cat+0x39>
      printf(1, "cat: write error\n");
  22:	83 ec 08             	sub    $0x8,%esp
  25:	68 af 08 00 00       	push   $0x8af
  2a:	6a 01                	push   $0x1
  2c:	e8 c8 04 00 00       	call   4f9 <printf>
  31:	83 c4 10             	add    $0x10,%esp
      exit();
  34:	e8 49 03 00 00       	call   382 <exit>
void
cat(int fd)
{
  int n;

  while((n = read(fd, buf, sizeof(buf))) > 0) {
  39:	83 ec 04             	sub    $0x4,%esp
  3c:	68 00 02 00 00       	push   $0x200
  41:	68 a0 0b 00 00       	push   $0xba0
  46:	ff 75 08             	pushl  0x8(%ebp)
  49:	e8 4c 03 00 00       	call   39a <read>
  4e:	83 c4 10             	add    $0x10,%esp
  51:	89 45 f4             	mov    %eax,-0xc(%ebp)
  54:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  58:	7f ae                	jg     8 <cat+0x8>
    if (write(1, buf, n) != n) {
      printf(1, "cat: write error\n");
      exit();
    }
  }
  if(n < 0){
  5a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  5e:	79 17                	jns    77 <cat+0x77>
    printf(1, "cat: read error\n");
  60:	83 ec 08             	sub    $0x8,%esp
  63:	68 c1 08 00 00       	push   $0x8c1
  68:	6a 01                	push   $0x1
  6a:	e8 8a 04 00 00       	call   4f9 <printf>
  6f:	83 c4 10             	add    $0x10,%esp
    exit();
  72:	e8 0b 03 00 00       	call   382 <exit>
  }
}
  77:	90                   	nop
  78:	c9                   	leave  
  79:	c3                   	ret    

0000007a <main>:

int
main(int argc, char *argv[])
{
  7a:	8d 4c 24 04          	lea    0x4(%esp),%ecx
  7e:	83 e4 f0             	and    $0xfffffff0,%esp
  81:	ff 71 fc             	pushl  -0x4(%ecx)
  84:	55                   	push   %ebp
  85:	89 e5                	mov    %esp,%ebp
  87:	53                   	push   %ebx
  88:	51                   	push   %ecx
  89:	83 ec 10             	sub    $0x10,%esp
  8c:	89 cb                	mov    %ecx,%ebx
  int fd, i;

  if(argc <= 1){
  8e:	83 3b 01             	cmpl   $0x1,(%ebx)
  91:	7f 12                	jg     a5 <main+0x2b>
    cat(0);
  93:	83 ec 0c             	sub    $0xc,%esp
  96:	6a 00                	push   $0x0
  98:	e8 63 ff ff ff       	call   0 <cat>
  9d:	83 c4 10             	add    $0x10,%esp
    exit();
  a0:	e8 dd 02 00 00       	call   382 <exit>
  }

  for(i = 1; i < argc; i++){
  a5:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  ac:	eb 71                	jmp    11f <main+0xa5>
    if((fd = open(argv[i], 0)) < 0){
  ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
  b1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  b8:	8b 43 04             	mov    0x4(%ebx),%eax
  bb:	01 d0                	add    %edx,%eax
  bd:	8b 00                	mov    (%eax),%eax
  bf:	83 ec 08             	sub    $0x8,%esp
  c2:	6a 00                	push   $0x0
  c4:	50                   	push   %eax
  c5:	e8 f8 02 00 00       	call   3c2 <open>
  ca:	83 c4 10             	add    $0x10,%esp
  cd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  d0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  d4:	79 29                	jns    ff <main+0x85>
      printf(1, "cat: cannot open %s\n", argv[i]);
  d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  d9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  e0:	8b 43 04             	mov    0x4(%ebx),%eax
  e3:	01 d0                	add    %edx,%eax
  e5:	8b 00                	mov    (%eax),%eax
  e7:	83 ec 04             	sub    $0x4,%esp
  ea:	50                   	push   %eax
  eb:	68 d2 08 00 00       	push   $0x8d2
  f0:	6a 01                	push   $0x1
  f2:	e8 02 04 00 00       	call   4f9 <printf>
  f7:	83 c4 10             	add    $0x10,%esp
      exit();
  fa:	e8 83 02 00 00       	call   382 <exit>
    }
    cat(fd);
  ff:	83 ec 0c             	sub    $0xc,%esp
 102:	ff 75 f0             	pushl  -0x10(%ebp)
 105:	e8 f6 fe ff ff       	call   0 <cat>
 10a:	83 c4 10             	add    $0x10,%esp
    close(fd);
 10d:	83 ec 0c             	sub    $0xc,%esp
 110:	ff 75 f0             	pushl  -0x10(%ebp)
 113:	e8 92 02 00 00       	call   3aa <close>
 118:	83 c4 10             	add    $0x10,%esp
  if(argc <= 1){
    cat(0);
    exit();
  }

  for(i = 1; i < argc; i++){
 11b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
 11f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 122:	3b 03                	cmp    (%ebx),%eax
 124:	7c 88                	jl     ae <main+0x34>
      exit();
    }
    cat(fd);
    close(fd);
  }
  exit();
 126:	e8 57 02 00 00       	call   382 <exit>

0000012b <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
 12b:	55                   	push   %ebp
 12c:	89 e5                	mov    %esp,%ebp
 12e:	57                   	push   %edi
 12f:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
 130:	8b 4d 08             	mov    0x8(%ebp),%ecx
 133:	8b 55 10             	mov    0x10(%ebp),%edx
 136:	8b 45 0c             	mov    0xc(%ebp),%eax
 139:	89 cb                	mov    %ecx,%ebx
 13b:	89 df                	mov    %ebx,%edi
 13d:	89 d1                	mov    %edx,%ecx
 13f:	fc                   	cld    
 140:	f3 aa                	rep stos %al,%es:(%edi)
 142:	89 ca                	mov    %ecx,%edx
 144:	89 fb                	mov    %edi,%ebx
 146:	89 5d 08             	mov    %ebx,0x8(%ebp)
 149:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
 14c:	90                   	nop
 14d:	5b                   	pop    %ebx
 14e:	5f                   	pop    %edi
 14f:	5d                   	pop    %ebp
 150:	c3                   	ret    

00000151 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 151:	55                   	push   %ebp
 152:	89 e5                	mov    %esp,%ebp
 154:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
 157:	8b 45 08             	mov    0x8(%ebp),%eax
 15a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
 15d:	90                   	nop
 15e:	8b 45 08             	mov    0x8(%ebp),%eax
 161:	8d 50 01             	lea    0x1(%eax),%edx
 164:	89 55 08             	mov    %edx,0x8(%ebp)
 167:	8b 55 0c             	mov    0xc(%ebp),%edx
 16a:	8d 4a 01             	lea    0x1(%edx),%ecx
 16d:	89 4d 0c             	mov    %ecx,0xc(%ebp)
 170:	0f b6 12             	movzbl (%edx),%edx
 173:	88 10                	mov    %dl,(%eax)
 175:	0f b6 00             	movzbl (%eax),%eax
 178:	84 c0                	test   %al,%al
 17a:	75 e2                	jne    15e <strcpy+0xd>
    ;
  return os;
 17c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 17f:	c9                   	leave  
 180:	c3                   	ret    

00000181 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 181:	55                   	push   %ebp
 182:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 184:	eb 08                	jmp    18e <strcmp+0xd>
    p++, q++;
 186:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 18a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 18e:	8b 45 08             	mov    0x8(%ebp),%eax
 191:	0f b6 00             	movzbl (%eax),%eax
 194:	84 c0                	test   %al,%al
 196:	74 10                	je     1a8 <strcmp+0x27>
 198:	8b 45 08             	mov    0x8(%ebp),%eax
 19b:	0f b6 10             	movzbl (%eax),%edx
 19e:	8b 45 0c             	mov    0xc(%ebp),%eax
 1a1:	0f b6 00             	movzbl (%eax),%eax
 1a4:	38 c2                	cmp    %al,%dl
 1a6:	74 de                	je     186 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 1a8:	8b 45 08             	mov    0x8(%ebp),%eax
 1ab:	0f b6 00             	movzbl (%eax),%eax
 1ae:	0f b6 d0             	movzbl %al,%edx
 1b1:	8b 45 0c             	mov    0xc(%ebp),%eax
 1b4:	0f b6 00             	movzbl (%eax),%eax
 1b7:	0f b6 c0             	movzbl %al,%eax
 1ba:	29 c2                	sub    %eax,%edx
 1bc:	89 d0                	mov    %edx,%eax
}
 1be:	5d                   	pop    %ebp
 1bf:	c3                   	ret    

000001c0 <strlen>:

uint
strlen(char *s)
{
 1c0:	55                   	push   %ebp
 1c1:	89 e5                	mov    %esp,%ebp
 1c3:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 1c6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 1cd:	eb 04                	jmp    1d3 <strlen+0x13>
 1cf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 1d3:	8b 55 fc             	mov    -0x4(%ebp),%edx
 1d6:	8b 45 08             	mov    0x8(%ebp),%eax
 1d9:	01 d0                	add    %edx,%eax
 1db:	0f b6 00             	movzbl (%eax),%eax
 1de:	84 c0                	test   %al,%al
 1e0:	75 ed                	jne    1cf <strlen+0xf>
    ;
  return n;
 1e2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 1e5:	c9                   	leave  
 1e6:	c3                   	ret    

000001e7 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1e7:	55                   	push   %ebp
 1e8:	89 e5                	mov    %esp,%ebp
  stosb(dst, c, n);
 1ea:	8b 45 10             	mov    0x10(%ebp),%eax
 1ed:	50                   	push   %eax
 1ee:	ff 75 0c             	pushl  0xc(%ebp)
 1f1:	ff 75 08             	pushl  0x8(%ebp)
 1f4:	e8 32 ff ff ff       	call   12b <stosb>
 1f9:	83 c4 0c             	add    $0xc,%esp
  return dst;
 1fc:	8b 45 08             	mov    0x8(%ebp),%eax
}
 1ff:	c9                   	leave  
 200:	c3                   	ret    

00000201 <strchr>:

char*
strchr(const char *s, char c)
{
 201:	55                   	push   %ebp
 202:	89 e5                	mov    %esp,%ebp
 204:	83 ec 04             	sub    $0x4,%esp
 207:	8b 45 0c             	mov    0xc(%ebp),%eax
 20a:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 20d:	eb 14                	jmp    223 <strchr+0x22>
    if(*s == c)
 20f:	8b 45 08             	mov    0x8(%ebp),%eax
 212:	0f b6 00             	movzbl (%eax),%eax
 215:	3a 45 fc             	cmp    -0x4(%ebp),%al
 218:	75 05                	jne    21f <strchr+0x1e>
      return (char*)s;
 21a:	8b 45 08             	mov    0x8(%ebp),%eax
 21d:	eb 13                	jmp    232 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 21f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 223:	8b 45 08             	mov    0x8(%ebp),%eax
 226:	0f b6 00             	movzbl (%eax),%eax
 229:	84 c0                	test   %al,%al
 22b:	75 e2                	jne    20f <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 22d:	b8 00 00 00 00       	mov    $0x0,%eax
}
 232:	c9                   	leave  
 233:	c3                   	ret    

00000234 <gets>:

char*
gets(char *buf, int max)
{
 234:	55                   	push   %ebp
 235:	89 e5                	mov    %esp,%ebp
 237:	83 ec 18             	sub    $0x18,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 23a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 241:	eb 42                	jmp    285 <gets+0x51>
    cc = read(0, &c, 1);
 243:	83 ec 04             	sub    $0x4,%esp
 246:	6a 01                	push   $0x1
 248:	8d 45 ef             	lea    -0x11(%ebp),%eax
 24b:	50                   	push   %eax
 24c:	6a 00                	push   $0x0
 24e:	e8 47 01 00 00       	call   39a <read>
 253:	83 c4 10             	add    $0x10,%esp
 256:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 259:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 25d:	7e 33                	jle    292 <gets+0x5e>
      break;
    buf[i++] = c;
 25f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 262:	8d 50 01             	lea    0x1(%eax),%edx
 265:	89 55 f4             	mov    %edx,-0xc(%ebp)
 268:	89 c2                	mov    %eax,%edx
 26a:	8b 45 08             	mov    0x8(%ebp),%eax
 26d:	01 c2                	add    %eax,%edx
 26f:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 273:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
 275:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 279:	3c 0a                	cmp    $0xa,%al
 27b:	74 16                	je     293 <gets+0x5f>
 27d:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 281:	3c 0d                	cmp    $0xd,%al
 283:	74 0e                	je     293 <gets+0x5f>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 285:	8b 45 f4             	mov    -0xc(%ebp),%eax
 288:	83 c0 01             	add    $0x1,%eax
 28b:	3b 45 0c             	cmp    0xc(%ebp),%eax
 28e:	7c b3                	jl     243 <gets+0xf>
 290:	eb 01                	jmp    293 <gets+0x5f>
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
 292:	90                   	nop
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 293:	8b 55 f4             	mov    -0xc(%ebp),%edx
 296:	8b 45 08             	mov    0x8(%ebp),%eax
 299:	01 d0                	add    %edx,%eax
 29b:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 29e:	8b 45 08             	mov    0x8(%ebp),%eax
}
 2a1:	c9                   	leave  
 2a2:	c3                   	ret    

000002a3 <stat>:

int
stat(char *n, struct stat *st)
{
 2a3:	55                   	push   %ebp
 2a4:	89 e5                	mov    %esp,%ebp
 2a6:	83 ec 18             	sub    $0x18,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2a9:	83 ec 08             	sub    $0x8,%esp
 2ac:	6a 00                	push   $0x0
 2ae:	ff 75 08             	pushl  0x8(%ebp)
 2b1:	e8 0c 01 00 00       	call   3c2 <open>
 2b6:	83 c4 10             	add    $0x10,%esp
 2b9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 2bc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 2c0:	79 07                	jns    2c9 <stat+0x26>
    return -1;
 2c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 2c7:	eb 25                	jmp    2ee <stat+0x4b>
  r = fstat(fd, st);
 2c9:	83 ec 08             	sub    $0x8,%esp
 2cc:	ff 75 0c             	pushl  0xc(%ebp)
 2cf:	ff 75 f4             	pushl  -0xc(%ebp)
 2d2:	e8 03 01 00 00       	call   3da <fstat>
 2d7:	83 c4 10             	add    $0x10,%esp
 2da:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 2dd:	83 ec 0c             	sub    $0xc,%esp
 2e0:	ff 75 f4             	pushl  -0xc(%ebp)
 2e3:	e8 c2 00 00 00       	call   3aa <close>
 2e8:	83 c4 10             	add    $0x10,%esp
  return r;
 2eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 2ee:	c9                   	leave  
 2ef:	c3                   	ret    

000002f0 <atoi>:

int
atoi(const char *s)
{
 2f0:	55                   	push   %ebp
 2f1:	89 e5                	mov    %esp,%ebp
 2f3:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 2f6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 2fd:	eb 25                	jmp    324 <atoi+0x34>
    n = n*10 + *s++ - '0';
 2ff:	8b 55 fc             	mov    -0x4(%ebp),%edx
 302:	89 d0                	mov    %edx,%eax
 304:	c1 e0 02             	shl    $0x2,%eax
 307:	01 d0                	add    %edx,%eax
 309:	01 c0                	add    %eax,%eax
 30b:	89 c1                	mov    %eax,%ecx
 30d:	8b 45 08             	mov    0x8(%ebp),%eax
 310:	8d 50 01             	lea    0x1(%eax),%edx
 313:	89 55 08             	mov    %edx,0x8(%ebp)
 316:	0f b6 00             	movzbl (%eax),%eax
 319:	0f be c0             	movsbl %al,%eax
 31c:	01 c8                	add    %ecx,%eax
 31e:	83 e8 30             	sub    $0x30,%eax
 321:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 324:	8b 45 08             	mov    0x8(%ebp),%eax
 327:	0f b6 00             	movzbl (%eax),%eax
 32a:	3c 2f                	cmp    $0x2f,%al
 32c:	7e 0a                	jle    338 <atoi+0x48>
 32e:	8b 45 08             	mov    0x8(%ebp),%eax
 331:	0f b6 00             	movzbl (%eax),%eax
 334:	3c 39                	cmp    $0x39,%al
 336:	7e c7                	jle    2ff <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 338:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 33b:	c9                   	leave  
 33c:	c3                   	ret    

0000033d <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 33d:	55                   	push   %ebp
 33e:	89 e5                	mov    %esp,%ebp
 340:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;

  dst = vdst;
 343:	8b 45 08             	mov    0x8(%ebp),%eax
 346:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 349:	8b 45 0c             	mov    0xc(%ebp),%eax
 34c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 34f:	eb 17                	jmp    368 <memmove+0x2b>
    *dst++ = *src++;
 351:	8b 45 fc             	mov    -0x4(%ebp),%eax
 354:	8d 50 01             	lea    0x1(%eax),%edx
 357:	89 55 fc             	mov    %edx,-0x4(%ebp)
 35a:	8b 55 f8             	mov    -0x8(%ebp),%edx
 35d:	8d 4a 01             	lea    0x1(%edx),%ecx
 360:	89 4d f8             	mov    %ecx,-0x8(%ebp)
 363:	0f b6 12             	movzbl (%edx),%edx
 366:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;

  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 368:	8b 45 10             	mov    0x10(%ebp),%eax
 36b:	8d 50 ff             	lea    -0x1(%eax),%edx
 36e:	89 55 10             	mov    %edx,0x10(%ebp)
 371:	85 c0                	test   %eax,%eax
 373:	7f dc                	jg     351 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 375:	8b 45 08             	mov    0x8(%ebp),%eax
}
 378:	c9                   	leave  
 379:	c3                   	ret    

0000037a <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 37a:	b8 01 00 00 00       	mov    $0x1,%eax
 37f:	cd 40                	int    $0x40
 381:	c3                   	ret    

00000382 <exit>:
SYSCALL(exit)
 382:	b8 02 00 00 00       	mov    $0x2,%eax
 387:	cd 40                	int    $0x40
 389:	c3                   	ret    

0000038a <wait>:
SYSCALL(wait)
 38a:	b8 03 00 00 00       	mov    $0x3,%eax
 38f:	cd 40                	int    $0x40
 391:	c3                   	ret    

00000392 <pipe>:
SYSCALL(pipe)
 392:	b8 04 00 00 00       	mov    $0x4,%eax
 397:	cd 40                	int    $0x40
 399:	c3                   	ret    

0000039a <read>:
SYSCALL(read)
 39a:	b8 05 00 00 00       	mov    $0x5,%eax
 39f:	cd 40                	int    $0x40
 3a1:	c3                   	ret    

000003a2 <write>:
SYSCALL(write)
 3a2:	b8 10 00 00 00       	mov    $0x10,%eax
 3a7:	cd 40                	int    $0x40
 3a9:	c3                   	ret    

000003aa <close>:
SYSCALL(close)
 3aa:	b8 15 00 00 00       	mov    $0x15,%eax
 3af:	cd 40                	int    $0x40
 3b1:	c3                   	ret    

000003b2 <kill>:
SYSCALL(kill)
 3b2:	b8 06 00 00 00       	mov    $0x6,%eax
 3b7:	cd 40                	int    $0x40
 3b9:	c3                   	ret    

000003ba <exec>:
SYSCALL(exec)
 3ba:	b8 07 00 00 00       	mov    $0x7,%eax
 3bf:	cd 40                	int    $0x40
 3c1:	c3                   	ret    

000003c2 <open>:
SYSCALL(open)
 3c2:	b8 0f 00 00 00       	mov    $0xf,%eax
 3c7:	cd 40                	int    $0x40
 3c9:	c3                   	ret    

000003ca <mknod>:
SYSCALL(mknod)
 3ca:	b8 11 00 00 00       	mov    $0x11,%eax
 3cf:	cd 40                	int    $0x40
 3d1:	c3                   	ret    

000003d2 <unlink>:
SYSCALL(unlink)
 3d2:	b8 12 00 00 00       	mov    $0x12,%eax
 3d7:	cd 40                	int    $0x40
 3d9:	c3                   	ret    

000003da <fstat>:
SYSCALL(fstat)
 3da:	b8 08 00 00 00       	mov    $0x8,%eax
 3df:	cd 40                	int    $0x40
 3e1:	c3                   	ret    

000003e2 <link>:
SYSCALL(link)
 3e2:	b8 13 00 00 00       	mov    $0x13,%eax
 3e7:	cd 40                	int    $0x40
 3e9:	c3                   	ret    

000003ea <mkdir>:
SYSCALL(mkdir)
 3ea:	b8 14 00 00 00       	mov    $0x14,%eax
 3ef:	cd 40                	int    $0x40
 3f1:	c3                   	ret    

000003f2 <chdir>:
SYSCALL(chdir)
 3f2:	b8 09 00 00 00       	mov    $0x9,%eax
 3f7:	cd 40                	int    $0x40
 3f9:	c3                   	ret    

000003fa <dup>:
SYSCALL(dup)
 3fa:	b8 0a 00 00 00       	mov    $0xa,%eax
 3ff:	cd 40                	int    $0x40
 401:	c3                   	ret    

00000402 <getpid>:
SYSCALL(getpid)
 402:	b8 0b 00 00 00       	mov    $0xb,%eax
 407:	cd 40                	int    $0x40
 409:	c3                   	ret    

0000040a <sbrk>:
SYSCALL(sbrk)
 40a:	b8 0c 00 00 00       	mov    $0xc,%eax
 40f:	cd 40                	int    $0x40
 411:	c3                   	ret    

00000412 <sleep>:
SYSCALL(sleep)
 412:	b8 0d 00 00 00       	mov    $0xd,%eax
 417:	cd 40                	int    $0x40
 419:	c3                   	ret    

0000041a <uptime>:
SYSCALL(uptime)
 41a:	b8 0e 00 00 00       	mov    $0xe,%eax
 41f:	cd 40                	int    $0x40
 421:	c3                   	ret    

00000422 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 422:	55                   	push   %ebp
 423:	89 e5                	mov    %esp,%ebp
 425:	83 ec 18             	sub    $0x18,%esp
 428:	8b 45 0c             	mov    0xc(%ebp),%eax
 42b:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 42e:	83 ec 04             	sub    $0x4,%esp
 431:	6a 01                	push   $0x1
 433:	8d 45 f4             	lea    -0xc(%ebp),%eax
 436:	50                   	push   %eax
 437:	ff 75 08             	pushl  0x8(%ebp)
 43a:	e8 63 ff ff ff       	call   3a2 <write>
 43f:	83 c4 10             	add    $0x10,%esp
}
 442:	90                   	nop
 443:	c9                   	leave  
 444:	c3                   	ret    

00000445 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 445:	55                   	push   %ebp
 446:	89 e5                	mov    %esp,%ebp
 448:	53                   	push   %ebx
 449:	83 ec 24             	sub    $0x24,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 44c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 453:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 457:	74 17                	je     470 <printint+0x2b>
 459:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 45d:	79 11                	jns    470 <printint+0x2b>
    neg = 1;
 45f:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 466:	8b 45 0c             	mov    0xc(%ebp),%eax
 469:	f7 d8                	neg    %eax
 46b:	89 45 ec             	mov    %eax,-0x14(%ebp)
 46e:	eb 06                	jmp    476 <printint+0x31>
  } else {
    x = xx;
 470:	8b 45 0c             	mov    0xc(%ebp),%eax
 473:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 476:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 47d:	8b 4d f4             	mov    -0xc(%ebp),%ecx
 480:	8d 41 01             	lea    0x1(%ecx),%eax
 483:	89 45 f4             	mov    %eax,-0xc(%ebp)
 486:	8b 5d 10             	mov    0x10(%ebp),%ebx
 489:	8b 45 ec             	mov    -0x14(%ebp),%eax
 48c:	ba 00 00 00 00       	mov    $0x0,%edx
 491:	f7 f3                	div    %ebx
 493:	89 d0                	mov    %edx,%eax
 495:	0f b6 80 5c 0b 00 00 	movzbl 0xb5c(%eax),%eax
 49c:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
 4a0:	8b 5d 10             	mov    0x10(%ebp),%ebx
 4a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
 4a6:	ba 00 00 00 00       	mov    $0x0,%edx
 4ab:	f7 f3                	div    %ebx
 4ad:	89 45 ec             	mov    %eax,-0x14(%ebp)
 4b0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 4b4:	75 c7                	jne    47d <printint+0x38>
  if(neg)
 4b6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 4ba:	74 2d                	je     4e9 <printint+0xa4>
    buf[i++] = '-';
 4bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4bf:	8d 50 01             	lea    0x1(%eax),%edx
 4c2:	89 55 f4             	mov    %edx,-0xc(%ebp)
 4c5:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
 4ca:	eb 1d                	jmp    4e9 <printint+0xa4>
    putc(fd, buf[i]);
 4cc:	8d 55 dc             	lea    -0x24(%ebp),%edx
 4cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4d2:	01 d0                	add    %edx,%eax
 4d4:	0f b6 00             	movzbl (%eax),%eax
 4d7:	0f be c0             	movsbl %al,%eax
 4da:	83 ec 08             	sub    $0x8,%esp
 4dd:	50                   	push   %eax
 4de:	ff 75 08             	pushl  0x8(%ebp)
 4e1:	e8 3c ff ff ff       	call   422 <putc>
 4e6:	83 c4 10             	add    $0x10,%esp
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 4e9:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 4ed:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 4f1:	79 d9                	jns    4cc <printint+0x87>
    putc(fd, buf[i]);
}
 4f3:	90                   	nop
 4f4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 4f7:	c9                   	leave  
 4f8:	c3                   	ret    

000004f9 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 4f9:	55                   	push   %ebp
 4fa:	89 e5                	mov    %esp,%ebp
 4fc:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 4ff:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 506:	8d 45 0c             	lea    0xc(%ebp),%eax
 509:	83 c0 04             	add    $0x4,%eax
 50c:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 50f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 516:	e9 59 01 00 00       	jmp    674 <printf+0x17b>
    c = fmt[i] & 0xff;
 51b:	8b 55 0c             	mov    0xc(%ebp),%edx
 51e:	8b 45 f0             	mov    -0x10(%ebp),%eax
 521:	01 d0                	add    %edx,%eax
 523:	0f b6 00             	movzbl (%eax),%eax
 526:	0f be c0             	movsbl %al,%eax
 529:	25 ff 00 00 00       	and    $0xff,%eax
 52e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 531:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 535:	75 2c                	jne    563 <printf+0x6a>
      if(c == '%'){
 537:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 53b:	75 0c                	jne    549 <printf+0x50>
        state = '%';
 53d:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 544:	e9 27 01 00 00       	jmp    670 <printf+0x177>
      } else {
        putc(fd, c);
 549:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 54c:	0f be c0             	movsbl %al,%eax
 54f:	83 ec 08             	sub    $0x8,%esp
 552:	50                   	push   %eax
 553:	ff 75 08             	pushl  0x8(%ebp)
 556:	e8 c7 fe ff ff       	call   422 <putc>
 55b:	83 c4 10             	add    $0x10,%esp
 55e:	e9 0d 01 00 00       	jmp    670 <printf+0x177>
      }
    } else if(state == '%'){
 563:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 567:	0f 85 03 01 00 00    	jne    670 <printf+0x177>
      if(c == 'd'){
 56d:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 571:	75 1e                	jne    591 <printf+0x98>
        printint(fd, *ap, 10, 1);
 573:	8b 45 e8             	mov    -0x18(%ebp),%eax
 576:	8b 00                	mov    (%eax),%eax
 578:	6a 01                	push   $0x1
 57a:	6a 0a                	push   $0xa
 57c:	50                   	push   %eax
 57d:	ff 75 08             	pushl  0x8(%ebp)
 580:	e8 c0 fe ff ff       	call   445 <printint>
 585:	83 c4 10             	add    $0x10,%esp
        ap++;
 588:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 58c:	e9 d8 00 00 00       	jmp    669 <printf+0x170>
      } else if(c == 'x' || c == 'p'){
 591:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 595:	74 06                	je     59d <printf+0xa4>
 597:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 59b:	75 1e                	jne    5bb <printf+0xc2>
        printint(fd, *ap, 16, 0);
 59d:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5a0:	8b 00                	mov    (%eax),%eax
 5a2:	6a 00                	push   $0x0
 5a4:	6a 10                	push   $0x10
 5a6:	50                   	push   %eax
 5a7:	ff 75 08             	pushl  0x8(%ebp)
 5aa:	e8 96 fe ff ff       	call   445 <printint>
 5af:	83 c4 10             	add    $0x10,%esp
        ap++;
 5b2:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 5b6:	e9 ae 00 00 00       	jmp    669 <printf+0x170>
      } else if(c == 's'){
 5bb:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 5bf:	75 43                	jne    604 <printf+0x10b>
        s = (char*)*ap;
 5c1:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5c4:	8b 00                	mov    (%eax),%eax
 5c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 5c9:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 5cd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 5d1:	75 25                	jne    5f8 <printf+0xff>
          s = "(null)";
 5d3:	c7 45 f4 e7 08 00 00 	movl   $0x8e7,-0xc(%ebp)
        while(*s != 0){
 5da:	eb 1c                	jmp    5f8 <printf+0xff>
          putc(fd, *s);
 5dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
 5df:	0f b6 00             	movzbl (%eax),%eax
 5e2:	0f be c0             	movsbl %al,%eax
 5e5:	83 ec 08             	sub    $0x8,%esp
 5e8:	50                   	push   %eax
 5e9:	ff 75 08             	pushl  0x8(%ebp)
 5ec:	e8 31 fe ff ff       	call   422 <putc>
 5f1:	83 c4 10             	add    $0x10,%esp
          s++;
 5f4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 5f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 5fb:	0f b6 00             	movzbl (%eax),%eax
 5fe:	84 c0                	test   %al,%al
 600:	75 da                	jne    5dc <printf+0xe3>
 602:	eb 65                	jmp    669 <printf+0x170>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 604:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 608:	75 1d                	jne    627 <printf+0x12e>
        putc(fd, *ap);
 60a:	8b 45 e8             	mov    -0x18(%ebp),%eax
 60d:	8b 00                	mov    (%eax),%eax
 60f:	0f be c0             	movsbl %al,%eax
 612:	83 ec 08             	sub    $0x8,%esp
 615:	50                   	push   %eax
 616:	ff 75 08             	pushl  0x8(%ebp)
 619:	e8 04 fe ff ff       	call   422 <putc>
 61e:	83 c4 10             	add    $0x10,%esp
        ap++;
 621:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 625:	eb 42                	jmp    669 <printf+0x170>
      } else if(c == '%'){
 627:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 62b:	75 17                	jne    644 <printf+0x14b>
        putc(fd, c);
 62d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 630:	0f be c0             	movsbl %al,%eax
 633:	83 ec 08             	sub    $0x8,%esp
 636:	50                   	push   %eax
 637:	ff 75 08             	pushl  0x8(%ebp)
 63a:	e8 e3 fd ff ff       	call   422 <putc>
 63f:	83 c4 10             	add    $0x10,%esp
 642:	eb 25                	jmp    669 <printf+0x170>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 644:	83 ec 08             	sub    $0x8,%esp
 647:	6a 25                	push   $0x25
 649:	ff 75 08             	pushl  0x8(%ebp)
 64c:	e8 d1 fd ff ff       	call   422 <putc>
 651:	83 c4 10             	add    $0x10,%esp
        putc(fd, c);
 654:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 657:	0f be c0             	movsbl %al,%eax
 65a:	83 ec 08             	sub    $0x8,%esp
 65d:	50                   	push   %eax
 65e:	ff 75 08             	pushl  0x8(%ebp)
 661:	e8 bc fd ff ff       	call   422 <putc>
 666:	83 c4 10             	add    $0x10,%esp
      }
      state = 0;
 669:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 670:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 674:	8b 55 0c             	mov    0xc(%ebp),%edx
 677:	8b 45 f0             	mov    -0x10(%ebp),%eax
 67a:	01 d0                	add    %edx,%eax
 67c:	0f b6 00             	movzbl (%eax),%eax
 67f:	84 c0                	test   %al,%al
 681:	0f 85 94 fe ff ff    	jne    51b <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 687:	90                   	nop
 688:	c9                   	leave  
 689:	c3                   	ret    

0000068a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 68a:	55                   	push   %ebp
 68b:	89 e5                	mov    %esp,%ebp
 68d:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 690:	8b 45 08             	mov    0x8(%ebp),%eax
 693:	83 e8 08             	sub    $0x8,%eax
 696:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 699:	a1 88 0b 00 00       	mov    0xb88,%eax
 69e:	89 45 fc             	mov    %eax,-0x4(%ebp)
 6a1:	eb 24                	jmp    6c7 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6a3:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6a6:	8b 00                	mov    (%eax),%eax
 6a8:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6ab:	77 12                	ja     6bf <free+0x35>
 6ad:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6b0:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6b3:	77 24                	ja     6d9 <free+0x4f>
 6b5:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6b8:	8b 00                	mov    (%eax),%eax
 6ba:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 6bd:	77 1a                	ja     6d9 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6bf:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6c2:	8b 00                	mov    (%eax),%eax
 6c4:	89 45 fc             	mov    %eax,-0x4(%ebp)
 6c7:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6ca:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6cd:	76 d4                	jbe    6a3 <free+0x19>
 6cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6d2:	8b 00                	mov    (%eax),%eax
 6d4:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 6d7:	76 ca                	jbe    6a3 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 6d9:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6dc:	8b 40 04             	mov    0x4(%eax),%eax
 6df:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 6e6:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6e9:	01 c2                	add    %eax,%edx
 6eb:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6ee:	8b 00                	mov    (%eax),%eax
 6f0:	39 c2                	cmp    %eax,%edx
 6f2:	75 24                	jne    718 <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
 6f4:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6f7:	8b 50 04             	mov    0x4(%eax),%edx
 6fa:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6fd:	8b 00                	mov    (%eax),%eax
 6ff:	8b 40 04             	mov    0x4(%eax),%eax
 702:	01 c2                	add    %eax,%edx
 704:	8b 45 f8             	mov    -0x8(%ebp),%eax
 707:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 70a:	8b 45 fc             	mov    -0x4(%ebp),%eax
 70d:	8b 00                	mov    (%eax),%eax
 70f:	8b 10                	mov    (%eax),%edx
 711:	8b 45 f8             	mov    -0x8(%ebp),%eax
 714:	89 10                	mov    %edx,(%eax)
 716:	eb 0a                	jmp    722 <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
 718:	8b 45 fc             	mov    -0x4(%ebp),%eax
 71b:	8b 10                	mov    (%eax),%edx
 71d:	8b 45 f8             	mov    -0x8(%ebp),%eax
 720:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 722:	8b 45 fc             	mov    -0x4(%ebp),%eax
 725:	8b 40 04             	mov    0x4(%eax),%eax
 728:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 72f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 732:	01 d0                	add    %edx,%eax
 734:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 737:	75 20                	jne    759 <free+0xcf>
    p->s.size += bp->s.size;
 739:	8b 45 fc             	mov    -0x4(%ebp),%eax
 73c:	8b 50 04             	mov    0x4(%eax),%edx
 73f:	8b 45 f8             	mov    -0x8(%ebp),%eax
 742:	8b 40 04             	mov    0x4(%eax),%eax
 745:	01 c2                	add    %eax,%edx
 747:	8b 45 fc             	mov    -0x4(%ebp),%eax
 74a:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 74d:	8b 45 f8             	mov    -0x8(%ebp),%eax
 750:	8b 10                	mov    (%eax),%edx
 752:	8b 45 fc             	mov    -0x4(%ebp),%eax
 755:	89 10                	mov    %edx,(%eax)
 757:	eb 08                	jmp    761 <free+0xd7>
  } else
    p->s.ptr = bp;
 759:	8b 45 fc             	mov    -0x4(%ebp),%eax
 75c:	8b 55 f8             	mov    -0x8(%ebp),%edx
 75f:	89 10                	mov    %edx,(%eax)
  freep = p;
 761:	8b 45 fc             	mov    -0x4(%ebp),%eax
 764:	a3 88 0b 00 00       	mov    %eax,0xb88
}
 769:	90                   	nop
 76a:	c9                   	leave  
 76b:	c3                   	ret    

0000076c <morecore>:

static Header*
morecore(uint nu)
{
 76c:	55                   	push   %ebp
 76d:	89 e5                	mov    %esp,%ebp
 76f:	83 ec 18             	sub    $0x18,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 772:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 779:	77 07                	ja     782 <morecore+0x16>
    nu = 4096;
 77b:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 782:	8b 45 08             	mov    0x8(%ebp),%eax
 785:	c1 e0 03             	shl    $0x3,%eax
 788:	83 ec 0c             	sub    $0xc,%esp
 78b:	50                   	push   %eax
 78c:	e8 79 fc ff ff       	call   40a <sbrk>
 791:	83 c4 10             	add    $0x10,%esp
 794:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 797:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 79b:	75 07                	jne    7a4 <morecore+0x38>
    return 0;
 79d:	b8 00 00 00 00       	mov    $0x0,%eax
 7a2:	eb 26                	jmp    7ca <morecore+0x5e>
  hp = (Header*)p;
 7a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 7aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7ad:	8b 55 08             	mov    0x8(%ebp),%edx
 7b0:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 7b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7b6:	83 c0 08             	add    $0x8,%eax
 7b9:	83 ec 0c             	sub    $0xc,%esp
 7bc:	50                   	push   %eax
 7bd:	e8 c8 fe ff ff       	call   68a <free>
 7c2:	83 c4 10             	add    $0x10,%esp
  return freep;
 7c5:	a1 88 0b 00 00       	mov    0xb88,%eax
}
 7ca:	c9                   	leave  
 7cb:	c3                   	ret    

000007cc <malloc>:

void*
malloc(uint nbytes)
{
 7cc:	55                   	push   %ebp
 7cd:	89 e5                	mov    %esp,%ebp
 7cf:	83 ec 18             	sub    $0x18,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7d2:	8b 45 08             	mov    0x8(%ebp),%eax
 7d5:	83 c0 07             	add    $0x7,%eax
 7d8:	c1 e8 03             	shr    $0x3,%eax
 7db:	83 c0 01             	add    $0x1,%eax
 7de:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 7e1:	a1 88 0b 00 00       	mov    0xb88,%eax
 7e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
 7e9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 7ed:	75 23                	jne    812 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 7ef:	c7 45 f0 80 0b 00 00 	movl   $0xb80,-0x10(%ebp)
 7f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7f9:	a3 88 0b 00 00       	mov    %eax,0xb88
 7fe:	a1 88 0b 00 00       	mov    0xb88,%eax
 803:	a3 80 0b 00 00       	mov    %eax,0xb80
    base.s.size = 0;
 808:	c7 05 84 0b 00 00 00 	movl   $0x0,0xb84
 80f:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 812:	8b 45 f0             	mov    -0x10(%ebp),%eax
 815:	8b 00                	mov    (%eax),%eax
 817:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 81a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 81d:	8b 40 04             	mov    0x4(%eax),%eax
 820:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 823:	72 4d                	jb     872 <malloc+0xa6>
      if(p->s.size == nunits)
 825:	8b 45 f4             	mov    -0xc(%ebp),%eax
 828:	8b 40 04             	mov    0x4(%eax),%eax
 82b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 82e:	75 0c                	jne    83c <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 830:	8b 45 f4             	mov    -0xc(%ebp),%eax
 833:	8b 10                	mov    (%eax),%edx
 835:	8b 45 f0             	mov    -0x10(%ebp),%eax
 838:	89 10                	mov    %edx,(%eax)
 83a:	eb 26                	jmp    862 <malloc+0x96>
      else {
        p->s.size -= nunits;
 83c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 83f:	8b 40 04             	mov    0x4(%eax),%eax
 842:	2b 45 ec             	sub    -0x14(%ebp),%eax
 845:	89 c2                	mov    %eax,%edx
 847:	8b 45 f4             	mov    -0xc(%ebp),%eax
 84a:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 84d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 850:	8b 40 04             	mov    0x4(%eax),%eax
 853:	c1 e0 03             	shl    $0x3,%eax
 856:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 859:	8b 45 f4             	mov    -0xc(%ebp),%eax
 85c:	8b 55 ec             	mov    -0x14(%ebp),%edx
 85f:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 862:	8b 45 f0             	mov    -0x10(%ebp),%eax
 865:	a3 88 0b 00 00       	mov    %eax,0xb88
      return (void*)(p + 1);
 86a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 86d:	83 c0 08             	add    $0x8,%eax
 870:	eb 3b                	jmp    8ad <malloc+0xe1>
    }
    if(p == freep)
 872:	a1 88 0b 00 00       	mov    0xb88,%eax
 877:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 87a:	75 1e                	jne    89a <malloc+0xce>
      if((p = morecore(nunits)) == 0)
 87c:	83 ec 0c             	sub    $0xc,%esp
 87f:	ff 75 ec             	pushl  -0x14(%ebp)
 882:	e8 e5 fe ff ff       	call   76c <morecore>
 887:	83 c4 10             	add    $0x10,%esp
 88a:	89 45 f4             	mov    %eax,-0xc(%ebp)
 88d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 891:	75 07                	jne    89a <malloc+0xce>
        return 0;
 893:	b8 00 00 00 00       	mov    $0x0,%eax
 898:	eb 13                	jmp    8ad <malloc+0xe1>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 89a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 89d:	89 45 f0             	mov    %eax,-0x10(%ebp)
 8a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8a3:	8b 00                	mov    (%eax),%eax
 8a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 8a8:	e9 6d ff ff ff       	jmp    81a <malloc+0x4e>
}
 8ad:	c9                   	leave  
 8ae:	c3                   	ret    
