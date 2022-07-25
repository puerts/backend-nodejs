const fs = require('fs');

let v8_h_path = process.argv[2] + '/include/v8.h';
let v8_h_context = fs.readFileSync(v8_h_path, 'utf-8');

let v8_h_insert_pos = v8_h_context.lastIndexOf('#endif');

let v8_h_insert_code = `

#define HAS_ARRAYBUFFER_NEW_WITHOUT_STL 1

namespace v8
{
// do not new two ArrayBuffer with the same data and length
V8_EXPORT Local<ArrayBuffer> ArrayBuffer_New_Without_Stl(Isolate* isolate, 
      void* data, size_t byte_length, v8::BackingStore::DeleterCallback deleter,
      void* deleter_data);
V8_EXPORT Local<ArrayBuffer> ArrayBuffer_New_Without_Stl(Isolate* isolate, 
      void* data, size_t byte_length);
V8_EXPORT void* ArrayBuffer_Get_Data(Local<ArrayBuffer> array_buffer, size_t &byte_length);
V8_EXPORT void* ArrayBuffer_Get_Data(Local<ArrayBuffer> array_buffer);
}

`;

fs.writeFileSync(v8_h_path, v8_h_context.slice(0, v8_h_insert_pos) + v8_h_insert_code + v8_h_context.slice(v8_h_insert_pos));


let api_cc_path = process.argv[2] + '/src/api/api.cc';

let api_cc_insert_code = `
namespace v8
{
Local<ArrayBuffer> ArrayBuffer_New_Without_Stl(Isolate* isolate, 
      void* data, size_t byte_length, BackingStore::DeleterCallback deleter,
      void* deleter_data)
{
    auto Backing = ArrayBuffer::NewBackingStore(
            data, byte_length,deleter,
            deleter_data);
    return ArrayBuffer::New(isolate, std::move(Backing));
}

V8_EXPORT Local<ArrayBuffer> ArrayBuffer_New_Without_Stl(Isolate* isolate, 
      void* data, size_t byte_length)
{
#if V8_MAJOR_VERSION < 9
  CHECK_IMPLIES(byte_length != 0, data != nullptr);
  CHECK_LE(byte_length, i::JSArrayBuffer::kMaxByteLength);
  i::Isolate* i_isolate = reinterpret_cast<i::Isolate*>(isolate);

  std::shared_ptr<i::BackingStore> backing_store = LookupOrCreateBackingStore(
      i_isolate, data, byte_length, i::SharedFlag::kNotShared, ArrayBufferCreationMode::kExternalized);

  i::Handle<i::JSArrayBuffer> obj =
      i_isolate->factory()->NewJSArrayBuffer(std::move(backing_store));
  obj->set_is_external(true);
  return Utils::ToLocal(obj);
#else
  auto Backing = ArrayBuffer::NewBackingStore(
          data, byte_length, BackingStore::EmptyDeleter, nullptr);
  return ArrayBuffer::New(isolate, std::move(Backing));
#endif
}

void* ArrayBuffer_Get_Data(Local<ArrayBuffer> array_buffer, size_t &byte_length)
{
    byte_length = array_buffer->GetBackingStore()->ByteLength();
    return array_buffer->GetBackingStore()->Data();
}
void* ArrayBuffer_Get_Data(Local<ArrayBuffer> array_buffer)
{
    return array_buffer->GetBackingStore()->Data();
}
}
`

fs.writeFileSync(api_cc_path, fs.readFileSync(api_cc_path, 'utf-8') + api_cc_insert_code);