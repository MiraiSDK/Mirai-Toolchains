#if defined(__ANDROID__)

#define TARGET_OS_MAC               0
#define TARGET_OS_LINUX             1
#define TARGET_OS_WIN32             0
#define TARGET_OS_UNIX              0
#define TARGET_OS_EMBEDDED          1 
#define TARGET_OS_IPHONE            1 
#define TARGET_IPHONE_SIMULATOR     0 
#define TARGET_OS_ANDROID           1

//arm
#if defined(__arm__)
#define TARGET_CPU_PPC          0
#define TARGET_CPU_PPC64        0
#define TARGET_CPU_68K          0
#define TARGET_CPU_X86          0
#define TARGET_CPU_X86_64       0
#define TARGET_CPU_ARM          1
#define TARGET_CPU_ARM64        0
#define TARGET_CPU_MIPS         0
#define TARGET_CPU_SPARC        0
#define TARGET_CPU_ALPHA        0
#define TARGET_RT_MAC_CFM       0
#define TARGET_RT_MAC_MACHO     1
#define TARGET_RT_LITTLE_ENDIAN 1
#define TARGET_RT_BIG_ENDIAN    0
#define TARGET_RT_64_BIT        0
#elif defined(__i386__)
#define TARGET_CPU_PPC          0
#define TARGET_CPU_PPC64        0
#define TARGET_CPU_68K          0
#define TARGET_CPU_X86          1
#define TARGET_CPU_X86_64       0
#define TARGET_CPU_ARM          0
#define TARGET_CPU_ARM64        0
#define TARGET_CPU_MIPS         0
#define TARGET_CPU_SPARC        0
#define TARGET_CPU_ALPHA        0
#define TARGET_RT_MAC_CFM       0
#define TARGET_RT_MAC_MACHO     1
#define TARGET_RT_LITTLE_ENDIAN 1
#define TARGET_RT_BIG_ENDIAN    0
#define TARGET_RT_64_BIT        0
#else
#error unrecognized GNU C compiler
#endif

#endif
