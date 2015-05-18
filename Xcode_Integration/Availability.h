
#ifndef __AVAILABILITY__
#define __AVAILABILITY__

#define __MAC_10_0            1000
#define __MAC_10_1            1010
#define __MAC_10_2            1020
#define __MAC_10_3            1030
#define __MAC_10_4            1040
#define __MAC_10_5            1050
#define __MAC_10_6            1060
#define __MAC_10_7            1070
#define __MAC_10_8            1080
#define __MAC_10_9            1090
#define __MAC_10_10         101000


#define __IPHONE_2_0     20000
#define __IPHONE_2_1     20100
#define __IPHONE_2_2     20200
#define __IPHONE_3_0     30000
#define __IPHONE_3_1     30100
#define __IPHONE_3_2     30200
#define __IPHONE_4_0     40000
#define __IPHONE_4_1     40100
#define __IPHONE_4_2     40200
#define __IPHONE_4_3     40300
#define __IPHONE_5_0     50000
#define __IPHONE_5_1     50100
#define __IPHONE_6_0     60000
#define __IPHONE_6_1     60100
#define __IPHONE_7_0     70000
#define __IPHONE_7_1     70100
#define __IPHONE_8_0     80000
#define __IPHONE_8_1     80100

/* AVAILABLE */
#define __OSX_AVAILABLE_STARTING(_osx, _ios)
#define __OSX_AVAILABLE_BUT_DEPRECATED(_osxIntro, _osxDep, _iosIntro, _iosDep)
#define __OSX_AVAILABLE_BUT_DEPRECATED_MSG(_osxIntro, _osxDep, _iosIntro, _iosDep, _msg)

#define __OS_AVAILABILITY(_target, _availability)
#define __OS_AVAILABILITY_MSG(_target, _availability, _msg)

#define __OSX_EXTENSION_UNAVAILABLE(_msg)
#define __IOS_EXTENSION_UNAVAILABLE(_msg)

#define __OS_EXTENSION_UNAVAILABLE(_msg)  __OSX_EXTENSION_UNAVAILABLE(_msg) __IOS_EXTENSION_UNAVAILABLE(_msg)

/* Target Develepment */
#ifndef __IPHONE_OS_VERSION_MIN_REQUIRED
#define __IPHONE_OS_VERSION_MIN_REQUIRED 50000
#endif

/* SDK Version */
#ifndef __IPHONE_OS_VERSION_MAX_ALLOWED
#define __IPHONE_OS_VERSION_MAX_ALLOWED 80100
#endif
	 
	 
#endif  /* __AVAILABILITY__ */
	 
#ifndef __AVAILABILITYMACROS__
#define __AVAILABILITYMACROS__
	 
/*
 * only certain compilers support __attribute__((deprecated))
 */
#if defined(__has_feature) && defined(__has_attribute)
    #if __has_attribute(deprecated)
        #define DEPRECATED_ATTRIBUTE        __attribute__((deprecated))
        #if __has_feature(attribute_deprecated_with_message)
            #define DEPRECATED_MSG_ATTRIBUTE(s) __attribute__((deprecated(s)))
        #else
            #define DEPRECATED_MSG_ATTRIBUTE(s) __attribute__((deprecated))
        #endif
    #else
        #define DEPRECATED_ATTRIBUTE
        #define DEPRECATED_MSG_ATTRIBUTE(s)
    #endif
#elif defined(__GNUC__) && ((__GNUC__ >= 4) || ((__GNUC__ == 3) && (__GNUC_MINOR__ >= 1)))
    #define DEPRECATED_ATTRIBUTE        __attribute__((deprecated))
    #if (__GNUC__ >= 5) || ((__GNUC__ == 4) && (__GNUC_MINOR__ >= 5))
        #define DEPRECATED_MSG_ATTRIBUTE(s) __attribute__((deprecated(s)))
    #else
        #define DEPRECATED_MSG_ATTRIBUTE(s) __attribute__((deprecated))
    #endif
#else
    #define DEPRECATED_ATTRIBUTE
    #define DEPRECATED_MSG_ATTRIBUTE(s)
#endif
	 
	/*
	 * only certain compilers support __attribute__((unavailable))
	 */
	#if defined(__GNUC__) && ((__GNUC__ >= 4) || ((__GNUC__ == 3) && (__GNUC_MINOR__ >= 1)))
	    #define UNAVAILABLE_ATTRIBUTE __attribute__((unavailable))
	#else
	    #define UNAVAILABLE_ATTRIBUTE
	#endif
		 
#endif  /* __AVAILABILITYMACROS__ */