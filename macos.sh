set -e
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

MAJOR_VER=$(echo $VERSION | cut -d. -f1)
if [ "$MAJOR_VER" -ge 26 ]; then
  if [ "$(uname -m)" = "arm64" ]; then
    CC_host="clang -arch arm64" CXX_host="clang++ -arch arm64" CC_target="clang -arch x86_64" CXX_target="clang++ -arch x86_64" CC="clang -arch x86_64" CXX="clang++ -arch x86_64" ./configure --shared --cross-compiling --dest-cpu=x64 --v8-disable-temporal-support --without-ffi
  else
    ./configure --shared --v8-disable-temporal-support --without-ffi
  fi
else
  ./configure --shared
fi
make -j8

mkdir -p ../puerts-node/nodejs/include
mkdir -p ../puerts-node/nodejs/deps/uv/include
mkdir -p ../puerts-node/nodejs/deps/v8/include

mkdir -p ../puerts-node/nodejs/lib/macOS/
cp out/Release/libnode.*.dylib ../puerts-node/nodejs/lib/macOS/
