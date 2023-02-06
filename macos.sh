[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"
WORKSPACE=$GITHUB_WORKSPACE
HOMEPATH=~
VERSION=$1

cd $HOMEPATH
git clone https://github.com/nodejs/node.git

cd node
git fetch origin v$VERSION
git checkout v$VERSION

echo "=====[Patching Node.js]====="
node $WORKSPACE/node-script/do-gitpatch.js -p $WORKSPACE/patchs/lib_uv_add_on_watcher_queue_updated_v$VERSION.patch
node $WORKSPACE/node-script/add_arraybuffer_new_without_stl.js deps/v8
node $WORKSPACE/node-script/make_v8_inspector_export.js

echo "=====[Building Node.js]====="

./configure --shared
make -j8

mkdir -p ../puerts-node/nodejs/include
mkdir -p ../puerts-node/nodejs/deps/uv/include
mkdir -p ../puerts-node/nodejs/deps/v8/include

mkdir -p ../puerts-node/nodejs/lib/macOS/
cp out/Release/libnode.*.dylib ../puerts-node/nodejs/lib/macOS/
