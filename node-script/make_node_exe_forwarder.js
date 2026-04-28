const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const toolCache = new Map();

function parseDumpbinExports(output) {
  const names = [];
  const seen = new Set();

  for (const line of output.split(/\r?\n/)) {
    const match = line.match(/^\s*\d+\s+[0-9A-Fa-f]+\s+[0-9A-Fa-f]+\s+(\S+)/);
    if (!match) continue;

    const name = match[1];
    if (name === '[NONAME]' || seen.has(name)) continue;
    seen.add(name);
    names.push(name);
  }

  return names;
}

function parseMachine(output) {
  const match = output.match(/\b(8664|14C|AA64)\s+machine\b/i);
  if (!match) {
    throw new Error('Unable to determine target machine from dumpbin /headers output.');
  }

  const machine = match[1].toUpperCase();
  if (machine === '8664') return 'X64';
  if (machine === '14C') return 'X86';
  if (machine === 'AA64') return 'ARM64';

  throw new Error(`Unsupported target machine: ${machine}`);
}

function generateForwarderDef(exportNames) {
  if (!exportNames.length) {
    throw new Error('No exports found in libnode.dll.');
  }

  return [
    'LIBRARY NODE.EXE',
    'EXPORTS',
    ...exportNames.map((name) => `  ${name}=libnode.${name}`),
    '',
  ].join('\n');
}

function buildLinkArgs(defPath, outputPath, implibPath, machine) {
  return [
    '/nologo',
    '/dll',
    '/noentry',
    `/machine:${machine}`,
    `/def:${defPath}`,
    `/out:${outputPath}`,
    `/implib:${implibPath}`,
  ];
}

function compareVersion(a, b) {
  return a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' });
}

function findVsTool(command) {
  if (process.platform !== 'win32') return null;

  const exeName = command.toLowerCase().endsWith('.exe') ? command : `${command}.exe`;
  const programFilesX86 = process.env['ProgramFiles(x86)'] || process.env.ProgramFiles;
  if (!programFilesX86) return null;

  const vswhere = path.join(programFilesX86, 'Microsoft Visual Studio', 'Installer', 'vswhere.exe');
  if (!fs.existsSync(vswhere)) return null;

  const result = spawnSync(
    vswhere,
    [
      '-latest',
      '-products',
      '*',
      '-requires',
      'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
      '-property',
      'installationPath',
    ],
    { encoding: 'utf8', windowsHide: true }
  );
  if (result.status !== 0) return null;

  const installPath = (result.stdout || '').trim().split(/\r?\n/)[0];
  if (!installPath) return null;

  const msvcRoot = path.join(installPath, 'VC', 'Tools', 'MSVC');
  if (!fs.existsSync(msvcRoot)) return null;

  const versions = fs
    .readdirSync(msvcRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort(compareVersion)
    .reverse();

  for (const version of versions) {
    const candidate = path.join(msvcRoot, version, 'bin', 'Hostx64', 'x64', exeName);
    if (fs.existsSync(candidate)) return candidate;
  }

  return null;
}

function resolveTool(command) {
  if (toolCache.has(command)) return toolCache.get(command);

  const vsTool = findVsTool(command);
  if (vsTool) {
    toolCache.set(command, vsTool);
    return vsTool;
  }

  toolCache.set(command, command);
  return command;
}

function runTool(command, args) {
  const toolPath = resolveTool(command);
  const result = spawnSync(toolPath, args, {
    encoding: 'utf8',
    windowsHide: true,
  });

  if (result.error) {
    throw result.error;
  }

  const output = `${result.stdout || ''}${result.stderr || ''}`;
  if (result.status !== 0) {
    throw new Error(`${toolPath} ${args.join(' ')} failed with code ${result.status}\n${output}`);
  }

  return output;
}

function makeForwarder(libnodePath, outputPath) {
  const resolvedLibnode = path.resolve(libnodePath);
  const resolvedOutput = path.resolve(outputPath || path.join(path.dirname(resolvedLibnode), 'node.exe'));
  const outputDir = path.dirname(resolvedOutput);
  const defPath = path.join(outputDir, 'node_exe_forwarder.def');
  const implibPath = path.join(outputDir, 'node_exe_forwarder.lib');

  if (!fs.existsSync(resolvedLibnode)) {
    throw new Error(`libnode.dll not found: ${resolvedLibnode}`);
  }

  fs.mkdirSync(outputDir, { recursive: true });

  const machine = parseMachine(runTool('dumpbin', ['/headers', resolvedLibnode]));
  const exports = parseDumpbinExports(runTool('dumpbin', ['/exports', resolvedLibnode]));
  fs.writeFileSync(defPath, generateForwarderDef(exports), 'utf8');

  runTool('link', buildLinkArgs(defPath, resolvedOutput, implibPath, machine));

  return {
    defPath,
    exportCount: exports.length,
    implibPath,
    machine,
    outputPath: resolvedOutput,
  };
}

function main(argv) {
  const [, , libnodePath, outputPath] = argv;
  if (!libnodePath) {
    console.error('Usage: node make_node_exe_forwarder.js <path-to-libnode.dll> [output-node.exe]');
    process.exitCode = 1;
    return;
  }

  try {
    const result = makeForwarder(libnodePath, outputPath);
    console.log(
      `Created ${result.machine} NODE.EXE forwarder at ${result.outputPath} with ${result.exportCount} exports.`
    );
  } catch (error) {
    console.error(error && error.stack ? error.stack : error);
    process.exitCode = 1;
  }
}

module.exports = {
  buildLinkArgs,
  findVsTool,
  generateForwarderDef,
  makeForwarder,
  parseDumpbinExports,
  parseMachine,
  resolveTool,
};

if (require.main === module) {
  main(process.argv);
}
