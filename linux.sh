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
  if command -v clang-19 >/dev/null 2>&1; then
    export CC=clang-19
    export CXX=clang++-19
  elif command -v clang-20 >/dev/null 2>&1; then
    export CC=clang-20
    export CXX=clang++-20
  else
    export CC=clang
    export CXX=clang++
  fi
  export CXXFLAGS="-stdlib=libc++"
  export LDFLAGS="-stdlib=libc++"
  ./configure --shared --v8-disable-temporal-support --without-ffi
else
  export CC=clang
  export CXX=clang++
  export CXXFLAGS="-stdlib=libc++"
  export LDFLAGS="-stdlib=libc++"
  ./configure --shared
fi
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
SO_FILE=$(ls libnode.so.* | head -n 1)
ln -s "$SO_FILE" libnode.so
cd -
