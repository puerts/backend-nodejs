[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"

VERSION=$1
ARCH="$2"

case $ARCH in
    arm)
        OUTPUT="armv7"
        ;;
    x86)
        OUTPUT="x86"
        ;;
    x86_64)
        OUTPUT="x64"
        ARCH="x64"
        ;;
    arm64|aarch64)
        OUTPUT="arm64"
        ;;
    *)
        echo "Unsupported architecture provided: $ARCH"
        exit 1
        ;;
esac

cd ~
wget https://nodejs.org/download/release/v14.16.1/node-v14.16.1.tar.gz
tar xvfz node-v14.16.1.tar.gz

cd node-v14.16.1

echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
node $GITHUB_WORKSPACE/add_arraybuffer_new_without_stl.js deps/v8

echo "=====[ add make_v8_inspector_export ]====="
node $GITHUB_WORKSPACE/make_v8_inspector_export.js

echo "=====[Building Node.js]====="

cp ../android-configure ./
sh android-configure ~/android-ndk-r21b $ARCH 23
make -j8

mkdir -p ../puerts-node/nodejs/lib/Android/$OUTPUT/
cp out/Release/libnode.so* ../puerts-node/nodejs/lib/Android/$OUTPUT/