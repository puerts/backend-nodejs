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

export CC=clang
export CXX=clang++
# export CXXFLAGS="-stdlib=libc++"
# export LDFLAGS="-stdlib=libc++"

./configure --shared
make -j8

mkdir -p ../puerts-node/nodejs/include
mkdir -p ../puerts-node/nodejs/deps/uv/include
mkdir -p ../puerts-node/nodejs/deps/v8/include

cp src/node.h ../puerts-node/nodejs/include
cp src/node_version.h ../puerts-node/nodejs/include
cp -r deps/uv/include ../puerts-node/nodejs/deps/uv
cp -r deps/v8/include ../puerts-node/nodejs/deps/v8

mkdir -p ../puerts-node/nodejs/lib/Linux/
cp out/Release/libnode.so.* ../puerts-node/nodejs/lib/Linux/
cd ../puerts-node/nodejs/lib/Linux/
ln -s libnode.so.93 libnode.so
cd -
