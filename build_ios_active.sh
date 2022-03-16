#!/bin/bash

XCODE=$(xcode-select -p)
if [ ! -d "$XCODE" ]; then
	echo "You have to install Xcode and the command line tools first"
	exit 1
fi

CURL_NAME="resource"
CURRENT_PATH=$(cd $(dirname $0); pwd)
CURL_PATH="$CURRENT_PATH/$CURL_NAME"
ROOT_DIR=$(pwd)
cd "$CURL_PATH"

if [ ! -x "$CURL_PATH/configure" ]; then
	echo "Curl needs external tools to be compiled"
	echo "Make sure you have autoconf, automake and libtool installed"

	./buildconf

	EXITCODE=$?
	if [ $EXITCODE -ne 0 ]; then
		echo "Error running the buildconf program"
		cd "$ROOT_DIR"
		exit $EXITCODE
	fi
fi

LIB_DIR="$CURRENT_PATH/libs"
LIB_HEADERS="$LIB_DIR/include/curl"
export IPHONEOS_DEPLOYMENT_TARGET="9.0"

HOSTS=(arm x86_64)
ARCHS=(arm64 x86_64)
SDK=(iPhoneOS iPhoneSimulator)
PLATFORMS=(iPhoneOS iPhoneSimulator)

for (( i=0; i<${#ARCHS[@]}; i++ )); do
	ARCH=${ARCHS[$i]}
	export CFLAGS="-arch $ARCH -pipe -Os -gdwarf-2 -isysroot $XCODE/Platforms/${PLATFORMS[$i]}.platform/Developer/SDKs/${SDK[$i]}.sdk -miphoneos-version-min=${IPHONEOS_DEPLOYMENT_TARGET} -fembed-bitcode -Werror=partial-availability"
	export LDFLAGS="-arch $ARCH -isysroot $XCODE/Platforms/${PLATFORMS[$i]}.platform/Developer/SDKs/${SDK[$i]}.sdk"
	if [ "${PLATFORMS[$i]}" = "iPhoneSimulator" ]; then
		export CPPFLAGS="-D__IPHONE_OS_VERSION_MIN_REQUIRED=${IPHONEOS_DEPLOYMENT_TARGET%%.*}0000"
	fi
    
	cd "$CURL_PATH"
	./configure	--host="${HOSTS[$i]}-apple-darwin" \
            --with-secure-transport \
            --enable-static \
            --disable-shared \
            --enable-threaded-resolver \
            --disable-verbose \
            --enable-ipv6 \
            --without-ssl
	EXITCODE=$?
	if [ $EXITCODE -ne 0 ]; then
		echo "Error running the cURL configure program"
		cd "$ROOT_DIR"
		exit $EXITCODE
	fi

	make -j $(sysctl -n hw.logicalcpu_max)
	EXITCODE=$?
	if [ $EXITCODE -ne 0 ]; then
		echo "Error running the make program"
		cd "$ROOT_DIR"
		exit $EXITCODE
	fi
    
    if [ -d "$LIB_DIR/$ARCH" ]; then
        rm -rf "$LIB_DIR/$ARCH"
    fi

	mkdir -p "$LIB_DIR/$ARCH"
	cp "$CURL_PATH/lib/.libs/libcurl.a" "$LIB_DIR/$ARCH/"
	cp "$CURL_PATH/lib/.libs/libcurl.a" "$LIB_DIR/libcurl-$ARCH.a"
	make clean
done

cd "$LIB_DIR"
lipo -create -output libcurl.a libcurl-*.a
rm libcurl-*.a

if [ -d "$LIB_DIR/include" ]; then
    rm -rf "$LIB_DIR/include"
fi
    
mkdir -p "$LIB_DIR/include"
cp -R "$CURL_PATH/include/curl" "$LIB_HEADERS"

if [ -f "$LIB_HEADERS/.gitignore" ]; then
    rm -rf "$LIB_HEADERS/.gitignore"
fi

if [ -f "$LIB_HEADERS/Makefile" ]; then
    rm -rf "$LIB_HEADERS/Makefile"
fi

if [ -f "$LIB_HEADERS/Makefile.in" ]; then
    rm -rf "$LIB_HEADERS/Makefile.in"
fi

if [ -f "$LIB_HEADERS/Makefile.am" ]; then
    rm -rf "$LIB_HEADERS/Makefile.am"
fi

echo ""
echo "####################################"
echo "#                                  #"
echo "#          Build Complete          #"
echo "#                                  #"
echo "####################################"
echo ""
