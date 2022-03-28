set VERSION=%1

cd %HOMEPATH%
git clone --single-branch -b v14.x https://github.com/nodejs/node.git

cd node
git fetch origin v%VERSION%
git checkout v%VERSION%

echo =====[ Patching Node.js ]=====

node %GITHUB_WORKSPACE%\CRLF2LF.js %GITHUB_WORKSPACE%\nodemod.patch
call git apply --cached --reject %GITHUB_WORKSPACE%\nodemod.patch
node %GITHUB_WORKSPACE%\CRLF2LF.js %GITHUB_WORKSPACE%\lib_uv_add_on_watcher_queue_updated.patch
call git apply --cached --reject %GITHUB_WORKSPACE%\lib_uv_add_on_watcher_queue_updated.patch
call git checkout -- .

copy /y %GITHUB_WORKSPACE%\zlib.def deps\zlib\win32\zlib.def

echo =====[ Building Node.js ]=====
.\vcbuild.bat dll openssl-no-asm
