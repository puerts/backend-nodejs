[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"

VERSION=$1

cd ~
git clone https://github.com/nodejs/node.git

cd node
git fetch origin v$VERSION
git checkout v$VERSION

echo "=====[Patching Node.js]====="

git apply --cached $GITHUB_WORKSPACE/nodemod.patch
git apply --cached $GITHUB_WORKSPACE/lib_uv_add_on_watcher_queue_updated.patch
git checkout -- .

echo "=====[Building Node.js]====="

CC_host="clang" CXX_host="clang++" CC_target="clang -arch arm64" CXX_target="clang++ -arch arm64" CC="clang -arch arm64" CXX="clang++ -arch arm64" ./configure --no-browser-globals --shared --cross-compiling --dest-cpu=arm64
make -j8

mkdir -p ../puerts-node/nodejs/include
mkdir -p ../puerts-node/nodejs/deps/uv/include
mkdir -p ../puerts-node/nodejs/deps/v8/include

cp src/node.h ../puerts-node/nodejs/include
cp src/node_version.h ../puerts-node/nodejs/include
cp -r deps/uv/include ../puerts-node/nodejs/deps/uv
cp -r deps/v8/include ../puerts-node/nodejs/deps/v8

mkdir -p ../puerts-node/nodejs/lib/macOS_arm64/
cp out/Release/libnode.*.dylib ../puerts-node/nodejs/lib/macOS_arm64/
