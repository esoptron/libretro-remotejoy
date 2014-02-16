DEBUG=0
FRONTEND_SUPPORTS_RGB565=1

ifneq ($(EMSCRIPTEN),)
   platform = emscripten
endif

ifeq ($(platform),)
platform = unix
ifeq ($(shell uname -a),)
   platform = win
else ifneq ($(findstring MINGW,$(shell uname -a)),)
   platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
   platform = osx
else ifneq ($(findstring win,$(shell uname -a)),)
   platform = win
endif
endif

# system platform
system_platform = unix
ifeq ($(shell uname -a),)
EXE_EXT = .exe
   system_platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
   system_platform = osx
else ifneq ($(findstring MINGW,$(shell uname -a)),)
   system_platform = win
endif

#CC         = gcc
TARGET_NAME := remotejoy

LIBUSB_CFLAGS := -DLIBUSB_DESCRIBE=\"\" -DLIBUSB_MAJOR=1 -DLIBUSB_MINOR=1 -DLIBUSB_MICRO=1 -DLIBUSB_RC=\"\" -DENABLE_LOGGING 

ifeq ($(platform), unix)
   TARGET := $(TARGET_NAME)_libretro.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=libretro/link.T
	LIBUSB = 1
	LIBUSB_LINUX = 1
	LIBUSB_CFLAGS += -DOS_LINUX -DTHREADS_POSIX -DPOLL_NFDS_TYPE=nfds_t -pthread -DHAVE_POLL_H -DHAVE_GETTIMEOFDAY -DHAVE_SYS_TIME_H
else ifeq ($(platform), osx)
   TARGET := $(TARGET_NAME)_libretro.dylib
   fpic := -fPIC -mmacosx-version-min=10.6
   SHARED := -dynamiclib
	LIBUSB = 1
	LIBUSB_DARWIN = 1
	LIBUSB_CFLAGS += -DOS_DARWIN
else ifeq ($(platform), ios)
   TARGET := $(TARGET_NAME)_libretro_ios.dylib
   fpic := -fPIC
   SHARED := -dynamiclib

   CC = clang -arch armv7 -isysroot $(IOSSDK) -miphoneos-version-min=5.0
   CFLAGS += -DIOS -miphoneos-version-min=5.0
else ifeq ($(platform), qnx)
   TARGET := $(TARGET_NAME)_libretro_qnx.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=libretro/link.T

   CC = qcc -Vgcc_ntoarmv7le
   AR = qcc -Vgcc_ntoarmv7le
   CFLAGS += -D__BLACKBERRY_QNX__
else ifeq ($(platform), ps3)
   TARGET := $(TARGET_NAME)_libretro_ps3.a
   CC = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-gcc.exe
   AR = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-ar.exe
   CFLAGS += -D__ppc__
	STATIC_LINKING = 1
else ifeq ($(platform), sncps3)
   TARGET := $(TARGET_NAME)_libretro_ps3.a
   CC = $(CELL_SDK)/host-win32/sn/bin/ps3ppusnc.exe
   AR = $(CELL_SDK)/host-win32/sn/bin/ps3snarl.exe
   CFLAGS += -D__ppc__
	STATIC_LINKING = 1
else ifeq ($(platform), psl1ght)
   TARGET := $(TARGET_NAME)_libretro_psl1ght.a
   CC = $(PS3DEV)/ppu/bin/ppu-gcc$(EXE_EXT)
   AR = $(PS3DEV)/ppu/bin/ppu-ar$(EXE_EXT)
   CFLAGS += -D__ppc__
	STATIC_LINKING = 1
else ifeq ($(platform), psp1)
	TARGET := $(TARGET_NAME)_libretro_psp1.a
	CC = psp-gcc$(EXE_EXT)
	AR = psp-ar$(EXE_EXT)
	CFLAGS += -DPSP -G0
	STATIC_LINKING = 1
else ifeq ($(platform), xenon)
   TARGET := $(TARGET_NAME)_libretro_xenon360.a
   CC = xenon-gcc$(EXE_EXT)
   AR = xenon-ar$(EXE_EXT)
   CFLAGS += -D__LIBXENON__ -m32 -D__ppc__
	STATIC_LINKING = 1
else ifeq ($(platform), ngc)
   TARGET := $(TARGET_NAME)_libretro_ngc.a
   CC = $(DEVKITPPC)/bin/powerpc-eabi-gcc$(EXE_EXT)
   AR = $(DEVKITPPC)/bin/powerpc-eabi-ar$(EXE_EXT)
   CFLAGS += -DGEKKO -DHW_DOL -mrvl -mcpu=750 -meabi -mhard-float -D__ppc__
	STATIC_LINKING = 1
else ifeq ($(platform), wii)
   TARGET := $(TARGET_NAME)_libretro_wii.a
   CC = $(DEVKITPPC)/bin/powerpc-eabi-gcc$(EXE_EXT)
   AR = $(DEVKITPPC)/bin/powerpc-eabi-ar$(EXE_EXT)
   CFLAGS += -DGEKKO -DHW_RVL -mrvl -mcpu=750 -meabi -mhard-float -D__ppc__
	STATIC_LINKING = 1
else ifneq (,$(findstring armv,$(platform)))
   TARGET := $(TARGET_NAME)_libretro.so
   SHARED := -shared -Wl,--no-undefined
   fpic := -fPIC
   CC = gcc
ifneq (,$(findstring cortexa8,$(platform)))
   CFLAGS += -marm -mcpu=cortex-a8
   ASFLAGS += -mcpu=cortex-a8
else ifneq (,$(findstring cortexa9,$(platform)))
   CFLAGS += -marm -mcpu=cortex-a9
   ASFLAGS += -mcpu=cortex-a9
endif
   CFLAGS += -marm
ifneq (,$(findstring neon,$(platform)))
   CFLAGS += -mfpu=neon
   ASFLAGS += -mfpu=neon
   HAVE_NEON = 1
endif
ifneq (,$(findstring softfloat,$(platform)))
   CFLAGS += -mfloat-abi=softfp
   ASFLAGS += -mfloat-abi=softfp
else ifneq (,$(findstring hardfloat,$(platform)))
   CFLAGS += -mfloat-abi=hard
   ASFLAGS += -mfloat-abi=hard
endif
   CFLAGS += -DARM
else ifeq ($(platform), emscripten)
   TARGET := $(TARGET_NAME)_libretro_emscripten.bc
else
   TARGET := $(TARGET_NAME)_libretro.dll
   CC = gcc
   SHARED := -shared -static-libgcc -static-libstdc++ -Wl,--version-script=libretro/link.T
   CFLAGS += -D__WIN32__ -D__LIBRETRO__
	LIBUSB = 1
	LIBUSB_WINDOWS = 1
	LIBUSB_CFLAGS += -DOS_WINDOWS -DHAVE_GETTIMEOFDAY -DHAVE_INTTYPES_H -DHAVE_MEMORY_H -DHAVE_STDINT_H -DHAVE_STDLIB_H -DHAVE_STRINGS_H -DHAVE_STRING_H -DHAVE_SYS_STAT_H -DHAVE_SYS_TIME_H -DHAVE_SYS_TYPES_H -DHAVE_UNISTD_H -DPOLL_NFDS_TYPE='unsigned int' -DSTDC_HEADERS -D_GNU_SOURCE
endif

ifeq ($(DEBUG), 1)
CFLAGS += -O0 -g
LIBUSB_CFLAGS += -DENABLE_DEBUG_LOGGING 
else ifeq ($(platform), emscripten)
CFLAGS += -O2
else
CFLAGS += -O3
endif

SOURCES 	 := libretro/libretro.c libretro/remotejoy.c libretro/thread.c

ifeq ($(LIBUSB), 1)
SOURCES   += libusb/libusb/core.c \
				 libusb/libusb/descriptor.c \
				 libusb/libusb/io.c \
				 libusb/libusb/sync.c
ifeq ($(LIBUSB_LINUX), 1)
SOURCES   += libusb/libusb/os/linux_usbfs.c \
				 libusb/libusb/os/threads_posix.c
endif
ifeq ($(LIBUSB_DARWIN), 1)
SOURCES   += libusb/libusb/os/darwin_usb.c \
				 libusb/libusb/os/threads_posix.c
endif
ifeq ($(LIBUSB_WINDOWS), 1)
SOURCES   += libusb/libusb/os/poll_windows.c \
				 libusb/libusb/os/threads_windows.c \
				 libusb/libusb/os/windows_usb.c
endif
endif


OBJECTS    = $(SOURCES:.c=.o)

INCLUDES   = -I. -I.. -Ilibusb/libusb
DEFINES    = -DHAVE_STRINGS_H -DHAVE_STDINT_H -DHAVE_INTTYPES_H -D__LIBRETRO__ -DINLINE=inline $(LIBUSB_CFLAGS)

ifeq ($(platform), sncps3)
WARNINGS_DEFINES =
CODE_DEFINES =
else ifeq ($(platform), ios)
WARNINGS_DEFINES =
CODE_DEFINES =
else
WARNINGS_DEFINES = -Wall -W -Wno-unused-parameter -Wno-sign-compare -Wno-uninitialized -std=gnu99
CODE_DEFINES = -fomit-frame-pointer
endif

COMMON_DEFINES += $(CODE_DEFINES) $(WARNINGS_DEFINES) -DNDEBUG=1 $(fpic)

CFLAGS     += $(DEFINES) $(COMMON_DEFINES)

ifeq ($(FRONTEND_SUPPORTS_RGB565), 1)
CFLAGS += -DFRONTEND_SUPPORTS_RGB565
endif

all: $(TARGET)

$(TARGET): $(OBJECTS)
ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJECTS)
else
	$(CC) $(fpic) $(SHARED) $(INCLUDES) -o $@ $(OBJECTS) -lm
endif

%.o: %.c
	$(CC) $(INCLUDES) $(CFLAGS) -c -o $@ $<

clean-objs:
	rm -rf $(OBJECTS)

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: clean

