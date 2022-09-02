[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"
WORKSPACE=$GITHUB_WORKSPACE
HOMEPATH=~
VERSION=$1
ARCH="$2"

case $ARCH in
    arm)
        OUTPUT="armeabi-v7a"
        ;;
    x86)
        OUTPUT="x86"
        ;;
    x86_64)
        OUTPUT="x64"
        ;;
    arm64|aarch64)
        OUTPUT="arm64-v8a"
        ;;
    *)
        echo "Unsupported architecture provided: $ARCH"
        exit 1
        ;;
esac

cd $HOMEPATH
git clone https://github.com/nodejs/node.git

cd node
git fetch origin v$VERSION
git checkout v$VERSION

echo "=====[Patching Node.js]====="
# node $WORKSPACE/node-script/do-gitpatch.js -p $WORKSPACE/patchs/android_disable_alink_thin_v$VERSION.patch
node $WORKSPACE/node-script/do-gitpatch.js -p $WORKSPACE/patchs/lib_uv_add_on_watcher_queue_updated_v$VERSION.patch
node $WORKSPACE/node-script/do-gitpatch.js -p $WORKSPACE/patchs/fix_no_handler_inside_posix_v$VERSION.patch
node $WORKSPACE/node-script/add_arraybuffer_new_without_stl.js deps/v8
node $WORKSPACE/node-script/make_v8_inspector_export.js

echo "=====[Building Node.js]====="

cp $WORKSPACE/android-configure-static ./
./android-configure-static ~/android-ndk-r21b $2 24
make -j8

mkdir -p ../puerts-node/nodejs/lib/Android_Static/$OUTPUT/

cp \
  out/Release/obj.target/deps/histogram/libhistogram.a \
  out/Release/obj.target/deps/uvwasi/libuvwasi.a \
  out/Release/obj.target/libnode.a \
  out/Release/obj.target/libnode_stub.a \
  out/Release/obj.target/tools/v8_gypfiles/libv8_snapshot.a \
  out/Release/obj.target/tools/v8_gypfiles/libv8_libplatform.a \
  out/Release/obj.target/deps/zlib/libzlib.a \
  out/Release/obj.target/deps/llhttp/libllhttp.a \
  out/Release/obj.target/deps/cares/libcares.a \
  out/Release/obj.target/deps/uv/libuv.a \
  out/Release/obj.target/deps/nghttp2/libnghttp2.a \
  out/Release/obj.target/deps/brotli/libbrotli.a \
  out/Release/obj.target/deps/openssl/libopenssl.a \
  out/Release/obj.target/tools/v8_gypfiles/libv8_base_without_compiler.a \
  out/Release/obj.target/tools/v8_gypfiles/libv8_libbase.a \
  out/Release/obj.target/tools/v8_gypfiles/libv8_zlib.a \
  out/Release/obj.target/tools/v8_gypfiles/libv8_compiler.a \
  out/Release/obj.target/tools/v8_gypfiles/libv8_initializers.a \
  ../puerts-node/nodejs/lib/Android_Static/$OUTPUT/

vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

vercomp "16" $VERSION

if [ $? == 2 ]
then
cp \
  out/Release/obj/deps/ngtcp2/libngtcp2.a \
  out/Release/obj/deps/ngtcp2/libnghttp3.a \
  ../puerts-node/nodejs/lib/Android_Static/$OUTPUT/
else
cp out/Release/obj/tools/v8_gypfiles/libv8_libsampler.a \
  ../puerts-node/nodejs/lib/Android_Static/$OUTPUT/
fi
