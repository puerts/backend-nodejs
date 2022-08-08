set VERSION=%1

cd %HOMEPATH%
git clone https://github.com/nodejs/node.git

cd node
git fetch origin v%VERSION%
git checkout v%VERSION%

echo =====[ Patching Node.js ]=====

node %GITHUB_WORKSPACE%\CRLF2LF.js %GITHUB_WORKSPACE%\patchs\win_build_v%VERSION%.patch
call git apply --cached --reject %GITHUB_WORKSPACE%\patchs\win_build_v%VERSION%.patch
node %GITHUB_WORKSPACE%\CRLF2LF.js %GITHUB_WORKSPACE%\patchs\lib_uv_add_on_watcher_queue_updated_v%VERSION%.patch
call git apply --cached --reject %GITHUB_WORKSPACE%\patchs\lib_uv_add_on_watcher_queue_updated_v%VERSION%.patch
call git checkout -- .

copy /y %GITHUB_WORKSPACE%\zlib.def deps\zlib\win32\zlib.def

echo =====[ add ArrayBuffer_New_Without_Stl ]=====
node %~dp0\add_arraybuffer_new_without_stl.js deps/v8

echo =====[ make_v8_inspector_export.js ]=====
node %~dp0\make_v8_inspector_export.js

echo =====[ switch to v141  ]=====
node -e "const fs = require('fs'); fs.writeFileSync('./vcbuild.bat', fs.readFileSync('./vcbuild.bat', 'utf-8').replace('set extra_msbuild_args=', 'set extra_msbuild_args=/p:PlatformToolset=v141'));

echo =====[ Building Node.js ]=====
.\vcbuild.bat dll openssl-no-asm
