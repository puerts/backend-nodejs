set VERSION=%1
set WORKSPACE=%GITHUB_WORKSPACE%
cd %HOMEPATH%
git clone https://github.com/nodejs/node.git

cd node
git fetch origin v%VERSION%
git checkout v%VERSION%

echo =====[ Patching Node.js ]=====
node %WORKSPACE%\node-script\do-gitpatch.js -p %WORKSPACE%\patchs\win_build_v%VERSION%.patch
node %WORKSPACE%\node-script\do-gitpatch.js -p %WORKSPACE%\patchs\lib_uv_add_on_watcher_queue_updated_v%VERSION%.patch
copy /y %WORKSPACE%\zlib.def deps\zlib\win32\zlib.def
node %~dp0\node-script\add_arraybuffer_new_without_stl.js deps/v8
node %~dp0\node-script\make_v8_inspector_export.js

echo =====[ Building Node.js ]=====
.\vcbuild.bat dll openssl-no-asm
