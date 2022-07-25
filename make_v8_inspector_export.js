const fs = require('fs');

let v8_inspector_h_path = 'deps/v8/include/v8-inspector.h';
let v8_inspector_h_context = fs.readFileSync(v8_inspector_h_path, 'utf-8');

let v8_inspector_h_insert_pos = v8_inspector_h_context.lastIndexOf('namespace v8_inspector {');

let v8_inspector_h_insert_code = `

#ifdef _WIN32
# ifndef BUILDING_NODE_EXTENSION
#  define NODE_EXTERN __declspec(dllexport)
# else
#  define NODE_EXTERN __declspec(dllimport)
# endif
#else
# define NODE_EXTERN __attribute__((visibility("default")))
#endif
`;

fs.writeFileSync(v8_inspector_h_path, v8_inspector_h_context.slice(0, v8_inspector_h_insert_pos) + v8_inspector_h_insert_code + v8_inspector_h_context.slice(v8_inspector_h_insert_pos).replace('class V8_EXPORT V8Inspector', 'class NODE_EXTERN V8Inspector'));


