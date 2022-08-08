const fs = require('fs');
const path = require('path')
const { program, Option } = require('commander');
const { exec } = require('child_process');
const iconv = require('iconv-lite')
const sxExecAsync = async function(command) {
    return new Promise(resolve=> {  
        let child = exec(command, {
            async: true,
            silent: true,
            encoding: 'binary'
        }, resolve);
        child.stdout.on('data', function(data) {
            console.log(iconv.decode(data, process.platform == 'win32' ? "gb2312" : 'utf-8'));
        })
        child.stderr.on('data', function(data) {
            console.error(iconv.decode(data, process.platform == 'win32' ? "gb2312" : 'utf-8'));
        })
    })
}
program.option("-p <patch>", "the path of the patch file");
program.parse(process.argv);

const patchfile = path.resolve(process.cwd(), program.opts().p);

// CRLF to LF
fs.writeFileSync(patchfile, fs.readFileSync(patchfile, {encoding: 'utf-8'}).toString().replace(/\r\n/g, '\n'));

(async function () {
    await sxExecAsync(`git apply --cached --reject ${patchfile}`);
    await sxExecAsync('git checkout -- .')
})()
// exec('git add .')