#!/bin/sh

# Get the VLC build path
if [ "x$1" = "x" ]; then
    echo "This script needs the vlc build path"
    exit 1
fi
VLC_BULD_PATH=$1

# Get the VLC contrib build directory
if [ "x$2" = "x" ]; then
    echo "This script needs the contrib build path"
    exit 1
fi
VLC_CONTRIB_PATH=$2

# Do we have an absolute path ?
prefix=""
if [ `echo $VLC_BULD_PATH | head -c 1` != "/" ]; then
    prefix="../"
fi

# If the contrib path is not absolute, change it
if [ `echo $VLC_CONTRIB_PATH | head -c 1` != "/" ]; then
    VLC_CONTRIB_PATH="../$VLC_CONTRIB_PATH"
fi

# Lookup for every static modules in the VLC build path
modules=`find $VLC_BULD_PATH/modules -name '*.a'`

# Build the list of modules
LDFLAGS=""
DEFINITION=""
BUILTINS="const void *vlc_builtins_modules[] = {\n"

for file in $modules; do
    name=`echo $file | sed 's/.*\.libs\/lib//' | sed 's/_plugin\.a//'`

    LDFLAGS=$LDFLAGS"$prefix$file "
    DEFINITION=$DEFINITION"vlc_declare_plugin(${name});\n"
    BUILTINS=$BUILTINS"    vlc_plugin(${name}),\n"
done;

BUILTINS=$BUILTINS"    NULL\n"
BUILTINS=$BUILTINS"};\n"

# Write the right files
rm -f libvlcjni/jni/libvlcjni.h
echo "// libvlcjni.h\n// Autogenerated from the list of modules\n" > libvlcjni/jni/libvlcjni.h
echo "$DEFINITION\n" >> libvlcjni/jni/libvlcjni.h
echo $BUILTINS >> libvlcjni/jni/libvlcjni.h

rm -f libvlcjni/jni/Android.mk
echo "LOCAL_PATH := \$(call my-dir)

include \$(CLEAR_VARS)

LOCAL_MODULE    := libvlcjni
LOCAL_SRC_FILES := libvlcjni.c
LOCAL_C_INCLUDES := \$(LOCAL_PATH)/../../../../../include
LOCAL_LDLIBS := -L$VLC_CONTRIB_PATH/lib $LDFLAGS $prefix$VLC_BULD_PATH/src/.libs/libvlc.a $prefix$VLC_BULD_PATH/src/.libs/libvlccore.a -ldl -lz -lavformat -lavcodec -lm -lz -lavcore -lavutil -lpostproc -lswscale -lmpeg2 -lgcc

include \$(BUILD_SHARED_LIBRARY)
" > libvlcjni/jni/Android.mk
