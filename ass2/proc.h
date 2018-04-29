// Per-CPU state
struct cpu {
  uchar apicid;                // Local APIC ID
  struct context *scheduler;   // swtch() here to enter scheduler
  struct taskstate ts;         // Used by x86 to find stack for interrupt
  struct segdesc gdt[NSEGS];   // x86 global descriptor table
  volatile uint started;       // Has the CPU started?
  int ncli;                    // Depth of pushcli nesting.
  int intena;                  // Were interrupts enabled before pushcli?
  struct proc *proc;           // The process running on this cpu or null
};

extern struct cpu cpus[NCPU];
extern int ncpu;

//PAGEBREAK: 17
// Saved registers for kernel context switches.
// Don't need to save all the segment registers (%cs, etc),
// because they are constant across kernel contexts.
// Don't need to save %eax, %ecx, %edx, because the
// x86 convention is that the caller has saved them.
// Contexts are stored at the bottom of the stack they
// describe; the stack pointer is the address of the context.
// The layout of the context matches the layout of the stack in swtch.S
// at the "Switch stacks" comment. Switch doesn't save eip explicitly,
// but it is on the stack and allocproc() manipulates it.
struct context {
  uint edi;
  uint esi;
  uint ebx;
  uint ebp;
  uint eip;
};

enum procstate {  UNUSED, // 0
                  NEG_UNUSED, // 1
                  EMBRYO, // 2
                  SLEEPING, // 3
                  NEG_SLEEPING, // 4
                  RUNNABLE, // 5
                  NEG_RUNNABLE, // 6
                  RUNNING, // 7
                  ZOMBIE, // 8
                  NEG_ZOMBIE  // 9
               };

void freeproc2(struct proc *p);

// todo uinque-ify
// entry in concurrent stack
struct cstackframe {
    int sender_pid;
    int recepient_pid;
    int value;
    int used;
    struct cstackframe *next;
};

// todo unique-ify
// concurrent stack
struct cstack {
    struct cstackframe frames[10];
    struct cstackframe *head;
};

// Per-process state
struct proc {
  uint sz;                     // Size of process memory (bytes)
  pde_t* pgdir;                // Page table
  char *kstack;                // Bottom of kernel stack for this process
  enum procstate state;        // Process state
  int pid;                     // Process ID
  struct proc *parent;         // Parent process
  struct trapframe *tf;        // Trap frame for current syscall
  struct context *context;     // swtch() here to run process
  void *chan;                  // If non-zero, sleeping on chan
  int killed;                  // If non-zero, have been killed
  struct file *ofile[NOFILE];  // Open files
  struct inode *cwd;           // Current directory
  char name[16];               // Process name (debugging)

  // ass2
  uint pending_signals;
  uint signal_mask;
  void* signal_handlers[32];
  struct trapframe* tf_backup;
  int stopped;
  int ignore_signals;
};

// ass2
#define SIG_DFL 0 // default
#define SIG_IGN 1 // ignore

#define SIGKILL 9
#define SIGSTOP 17
#define SIGCONT 19

// Process memory is laid out contiguously, low addresses first:
//   text
//   original data and bss
//   fixed-size stack
//   expandable heap