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
git clone https://github.com/nodejs/node.git

cd node
git fetch origin v$VERSION
git checkout v$VERSION

echo "=====[Patching Node.js]====="

node $GITHUB_WORKSPACE/CRLF2LF.js $GITHUB_WORKSPACE/nodemod.patch
git apply --cached $GITHUB_WORKSPACE/nodemod.patch
node $GITHUB_WORKSPACE/CRLF2LF.js $GITHUB_WORKSPACE/lib_uv_add_on_watcher_queue_updated.patch
git apply --cached $GITHUB_WORKSPACE/lib_uv_add_on_watcher_queue_updated.patch
git checkout -- .

echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
node $GITHUB_WORKSPACE/add_arraybuffer_new_without_stl.js deps/v8

echo "=====[ add make_v8_inspector_export ]====="
node $GITHUB_WORKSPACE/make_v8_inspector_export.js

echo "=====[Building Node.js]====="

cp $GITHUB_WORKSPACE/android-configure ./
./android-configure ~/android-ndk-r21b $2 24
make -j8

mkdir -p ../puerts-node/nodejs/lib/Android/$OUTPUT/
cp out/Release/libnode.so* ../puerts-node/nodejs/lib/Android/$OUTPUT/