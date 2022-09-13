[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"
WORKSPACE=$GITHUB_WORKSPACE
HOMEPATH=~
VERSION=$1
WITH_SSL=$2

cd $HOMEPATH
git clone https://github.com/nodejs/node.git

cd node
git fetch origin v$VERSION
git checkout v$VERSION

echo "=====[Patching Node.js]====="
node $WORKSPACE/node-script/do-gitpatch.js -p $WORKSPACE/patchs/lib_uv_add_on_watcher_queue_updated_v$VERSION.patch
node $WORKSPACE/node-script/do-gitpatch.js -p $WORKSPACE/patchs/fix_no_handler_inside_posix_v$VERSION.patch
node $WORKSPACE/node-script/do-gitpatch.js -p $WORKSPACE/patchs/ios_ninja_compile_for_v$VERSION.patch
node $WORKSPACE/node-script/add_arraybuffer_new_without_stl.js deps/v8
node $WORKSPACE/node-script/make_v8_inspector_export.js

echo "=====[ fetch ninja for mac ]====="
wget https://github.com/ninja-build/ninja/releases/download/v1.8.2/ninja-mac.zip
unzip ninja-mac.zip

echo "=====[Building libnode]====="
HOST_OS="mac"
HOST_ARCH="x86_64"
export CC_host=$(command -v clang)
export CXX_host=$(command -v clang++)

export CC="$(xcrun -sdk iphoneos -find clang)"
export CXX="$(xcrun -sdk iphoneos -find clang++)"
export AR="$(xcrun -sdk iphoneos -find ar)"
export AS="$(xcrun -sdk iphoneos -find as)"
export LD="$(xcrun -sdk iphoneos -find ld)"
export LIBTOOL="$(xcrun -sdk iphoneos -find libtool)"
export STRIP="$(xcrun -sdk iphoneos -find strip)"
export RANLIB="$(xcrun -sdk iphoneos -find ranlib)"

export SDK=`xcrun --sdk iphoneos --show-sdk-path`

export CXXFLAGS="-std=c++17 -O -arch arm64 -isysroot $SDK" 
export CFLAGS="-O -arch arm64 -isysroot $SDK" 
#export LDFLAGS="-O -arch arm64 -isysroot $SDK" 

export CXXFLAGS_host="-DV8_HOST_ARCH_X64 -std=c++17" 
export CFLAGS_host="" 

GYP_DEFINES="target_arch=arm64"
GYP_DEFINES+=" v8_target_arch=arm64"
GYP_DEFINES+=" ios_target_arch=arm64"
GYP_DEFINES+=" host_os=$HOST_OS OS=ios"
export GYP_DEFINES

if [ -f "configure" ]; then

  if [ $WITHSSL == "" ]; then
    ./configure \
        --ninja \
        --dest-cpu=arm64 \
        --dest-os=ios \
        --without-snapshot \
        --without-ssl \
        --enable-static \
        --with-intl=none \
        --no-browser-globals \
        --cross-compiling
  else
    ./configure \
        --ninja \
        --dest-cpu=arm64 \
        --dest-os=ios \
        --without-snapshot \
        --enable-static \
        --with-intl=none \
        --no-browser-globals \
        --cross-compiling
  fi
fi

./ninja -j 8 -w dupbuild=warn -C out/Release

echo "=====[Archive libnode]====="
#mkdir -p ../puerts-node/nodejs/iosinc/include
#mkdir -p ../puerts-node/nodejs/iosinc/deps/uv/include
#mkdir -p ../puerts-node/nodejs/iosinc/deps/v8/include

#cp src/node.h ../puerts-node/nodejs/iosinc/include
#cp src/node_version.h ../puerts-node/nodejs/iosinc/include
#cp -r deps/uv/include ../puerts-node/nodejs/iosinc/deps/uv
#cp -r deps/v8/include ../puerts-node/nodejs/iosinc/deps/v8

mkdir -p ../puerts-node/nodejs/lib/iOS/
cp \
  out/Release/obj/deps/histogram/libhistogram.a \
  out/Release/obj/deps/uvwasi/libuvwasi.a \
  out/Release/obj/libnode.a \
  out/Release/obj/libnode_stub.a \
  out/Release/obj/tools/v8_gypfiles/libv8_snapshot.a \
  out/Release/obj/tools/v8_gypfiles/libv8_libplatform.a \
  out/Release/obj/deps/zlib/libzlib.a \
  out/Release/obj/deps/llhttp/libllhttp.a \
  out/Release/obj/deps/cares/libcares.a \
  out/Release/obj/deps/uv/libuv.a \
  out/Release/obj/deps/nghttp2/libnghttp2.a \
  out/Release/obj/deps/brotli/libbrotli.a \
  out/Release/obj/deps/openssl/libopenssl.a \
  out/Release/obj/tools/v8_gypfiles/libv8_base_without_compiler.a \
  out/Release/obj/tools/v8_gypfiles/libv8_libbase.a \
  out/Release/obj/tools/v8_gypfiles/libv8_zlib.a \
  out/Release/obj/tools/v8_gypfiles/libv8_compiler.a \
  out/Release/obj/tools/v8_gypfiles/libv8_initializers.a \
  ../puerts-node/nodejs/lib/iOS/

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }

if version_lt $VERSION "16"; then
cp out/Release/obj/tools/v8_gypfiles/libv8_libsampler.a ../puerts-node/nodejs/lib/iOS/
fi
