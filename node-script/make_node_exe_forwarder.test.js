const assert = require('assert');

const {
  buildLinkArgs,
  generateForwarderDef,
  parseDumpbinExports,
  parseMachine,
} = require('./make_node_exe_forwarder');

const sampleExports = `
 ordinal hint RVA      name

       1    0 00001010 ?cppname@node@@YAHXZ
       2    1 00001020 napi_create_object
       3    2 00001030 uv_close
`;

assert.deepStrictEqual(parseDumpbinExports(sampleExports), [
  '?cppname@node@@YAHXZ',
  'napi_create_object',
  'uv_close',
]);

assert.strictEqual(
  generateForwarderDef(['napi_create_object', 'uv_close']),
  [
    'LIBRARY NODE.EXE',
    'EXPORTS',
    '  napi_create_object=libnode.napi_create_object',
    '  uv_close=libnode.uv_close',
    '',
  ].join('\n')
);

assert.strictEqual(parseMachine('8664 machine (x64)'), 'X64');
assert.strictEqual(parseMachine('14C machine (x86)'), 'X86');
assert.strictEqual(parseMachine('AA64 machine (ARM64)'), 'ARM64');

assert.deepStrictEqual(
  buildLinkArgs('node.def', 'node.exe', 'node_exe.lib', 'X64'),
  [
    '/nologo',
    '/dll',
    '/noentry',
    '/machine:X64',
    '/def:node.def',
    '/out:node.exe',
    '/implib:node_exe.lib',
  ]
);

console.log('make_node_exe_forwarder tests passed');
