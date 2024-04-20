# deserialize_demo

通常 Flutter 项目涉及网络请求，就会用到 JSON 转对象，看网上的方案要么 Editor/IDE 工具生成，要么是用网页生成……总之就是要做一件很钢笔又重复的事，本着看闹热不嫌事大的心态，我决定用 Rust 来处理这桩事。

## 引入 frb

主要作用是让 Dart 调用 Rust 来完成反序列化工作，在此之前先把这个插件用上[flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge)。这个插件可以让 Flutter 无缝调用 Rust（基础原理是通过 CLI 生成 Dart 跟相应的 FFI 绑定），好处是可以把一些 Rust 实现得库包装一层给 Flutter 调用，而且操作非常简单，省去了自己配置/编译/构建的一系列工程问题，开箱即用。
首先是安装该插件的 CLI，根据 [文档](https://cjycode.com/flutter_rust_bridge/) 的说法直接（写这篇东西的时候还是 ^2.0.0-dev.32，虽然目前还处于 dev 版，但是已经相当可用了）

```bash
cargo install 'flutter_rust_bridge_codegen@^2.0.0-dev.32'
```

安装结束后，如果已经有现成的 Flutter 项目，则可以直接通过

```bash
flutter_rust_bridge_codegen integrate
```

完成整合，或者直接通过

```bash
flutter_rust_bridge_codegen create your_app_name
```

来创建整合好该插件的项目。

## 用 Rust 反序列化生成 Dart 对象

## 基础配置

假设现在来创建一个简单的项目

```bash
flutter_rust_bridge_codegen create deserialize_demo
```

等待命令执行结束后，来看一下目录结构长啥样

```bash
tree -L 1
.
├── README.md
├── analysis_options.yaml
├── android
├── deserialize_demo.iml
├── flutter_rust_bridge.yaml
├── integration_test
├── ios
├── lib
├── linux
├── macos
├── pubspec.lock
├── pubspec.yaml
├── rust
├── rust_builder
├── test
├── test_driver
├── web
└── windows

13 directories, 6 files
```

我们来重点关注 lib 跟 rust 文件夹，

```bash
cd lib && tree -L 3
.
├── main.dart
└── src
    └── rust
        ├── api
        ├── frb_generated.dart
        ├── frb_generated.io.dart
        └── frb_generated.web.dart

4 directories, 4 files

-------------------------------------------------------

cd rust && tree -L 3
.
├── Cargo.lock
├── Cargo.toml
└── src
    ├── api
    │   ├── mod.rs
    │   └── simple.rs
    ├── frb_generated.io.rs
    ├── frb_generated.rs
    ├── frb_generated.web.rs
    └── lib.rs

3 directories, 8 files
```

可以看出创建项目后，会生成一个基础的 Rust 项目，同时也把 Rust 生成了对应的 Dart 跟 FFI 绑定的代码。  
既然 Rust 这边是一个正常的项目，那意味着我们可以直接写一个反序列化的函数导出给 Dart 这边调用，先把 Rust 的 serde 库引入进来

```toml
[package]
name = "rust_lib_deserialize_demo"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib", "staticlib"]

[dependencies]
flutter_rust_bridge = "=2.0.0-dev.32"
serde = { version = "1.0.198", features = ["derive"] }
serde_json = "1.0.116"
```

然后把 simple.rs 的代码调整一下，记得保留一下原先的 init_app 函数，因为目前没有啥需要自定义的一些初始行为，我的建议是新建个文件（譬如 init.rs）

文件结构变成

```bash
.
├── Cargo.lock
├── Cargo.toml
└── src
    ├── api
    │   ├── init.rs
    │   ├── mod.rs
    │   └── simple.rs
    ├── frb_generated.io.rs
    ├── frb_generated.rs
    ├── frb_generated.web.rs
    └── lib.rs
```

再把内容给誊上去

```rust
// init.rs
#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
  // Default utilities - feel free to customize
  flutter_rust_bridge::setup_default_user_utils();
}
```

### 处理后端响应的数据

现在我们假设后端响应给我们的是如下这段 JSON，如果没有错误时 err 为 null，没有数据时 data 为 null

```rust
{
    "err": null,
    "data": null
}
```

然后就可以用 Rust 定义响应结构

```rust
#[derive(Debug)]
pub struct Void {}

#[derive(Debug)]
pub struct Response {
  pub err: Option<Void>,
  pub data: Option<Void>,
}
```

我们还得实现一下通过字符串转换的函数，但是与此同时，我们还得处理意外情况，譬如后端接口已经有变化了，返回的数据跟你的结构已经不匹配，这就涉及到 Rust 的错误处理，我们先把正常情况的函数写出来，注意 derive 的变化，以及我们直接通过 unwrap 解包裹

```rust
#[derive(Debug, Deserialize)]
pub struct Void {}

#[derive(Debug, Deserialize)]
pub struct Response {
  pub err: Option<Void>,
  pub data: Option<Void>,
}

impl Response {
  pub fn from(json: String) -> Response {
    serde_json::from_str::<Response>(&json).unwrap()
  }
}
```

先来定义一个专门表达错误的枚举类型，为啥要这么麻烦，主要是考虑用 Rust 可能不止做反序列化这一件事，可能未来项目中会用于处理一些其他方面的事（譬如对接算法工程师的算法，或者进行一些 I/O 无关但吃 CPU 的操作），个么统一称呼这一类错误叫 FFIError，具体哪一类就是对应的枚举值

```rust
#[derive(Debug)]
pub enum FFIError {
  JsonError(serde_json::Error),
}
```

现在光定义枚举还不行，还要给枚举实现三个 trait，std::fmt::Display 是用来输出错误，From<serde_json::Error> 是用来传递 serde_json 转换的错误，至于 SseEncode 是给 frb 这个库使用的，因为它不认识 FFIError 这个类型

```rust
impl std::fmt::Display for FFIError {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match *self {
      FFIError::JsonError(ref cause) => write!(f, "{}", cause),
    }
  }
}

impl From<serde_json::Error> for FFIError {
  fn from(value: serde_json::Error) -> Self {
    FFIError::JsonError(value)
  }
}

impl SseEncode for FFIError {
  fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
    <String>::sse_encode(format!("{:?}", self), serializer);
  }
}
```

现在把重新回来反序列化的函数，把它改成

```rust
pub type Result<T> = std::result::Result<T, FFIError>;

impl Response {
  pub fn from(json: String) -> Result<Response> {
    Ok(serde_json::from_str::<Response>(&json)?)
  }
}
```

我们做了两桩事，一桩是类型别名了一个 Result，另一桩是干掉了 unwrap。  
现在我们来处理另一桩事，之前提到过我们

> 当前项目中，一段 JSON 如果没有错误时 err 为 null，没有数据时 data 为 null

个么就是讲，err 不为空的情况也得处理，假设这是后端定义的错误时的 JSON 表示

```rust
{
    "err": {
        "code": 403,
        "msg": "权限不足"
    },
    "data": null
}
```

于是我们写一个结构体，同时把之前 code 的类型改一下

```rust
#[derive(Debug, Deserialize)]
pub struct RespErr {
  pub code: i32,
  pub msg: String,
}

#[derive(Debug, Deserialize)]
pub struct Response {
  pub err: Option<RespErr>,
  pub data: Option<Void>,
}
```

当然这只是个例子，还有对应的 data 数据也要处理，只是把 Void 结构体改成相应的嵌套结构即可，而如果不存在 data 的情况，Void 就拿来占位。记得写完之后执行下生成指令

```bash
flutter_rust_bridge_codegen generate
```

执行完之后，重点关注 Flutter 的 lib 文件夹，它现在变成了，能看到多出了 init.dart 跟 simple.dart，
也就是分别对应 init.rs 跟 simple.rs

```bash
├── lib
│   ├── main.dart
│   └── src
│       └── rust
│           ├── api
│           │   ├── init.dart
│           │   └── simple.dart
│           ├── frb_generated.dart
│           ├── frb_generated.io.dart
│           └── frb_generated.web.dart
```

现在是完整的 simple.rs 的代码

```rust
use serde::Deserialize;
use std::result;

use crate::frb_generated::SseEncode;

#[derive(Debug, Deserialize)]
pub struct RespErr {
  pub code: i32,
  pub msg: String,
}

#[derive(Debug, Deserialize)]
pub struct Void {}

pub type Result<T> = result::Result<T, FFIError>;

#[derive(Debug)]
pub enum FFIError {
  JsonError(serde_json::Error),
}

impl std::fmt::Display for FFIError {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match *self {
      FFIError::JsonError(ref cause) => write!(f, "{}", cause),
    }
  }
}

impl From<serde_json::Error> for FFIError {
  fn from(value: serde_json::Error) -> Self {
    FFIError::JsonError(value)
  }
}

#[derive(Debug, Deserialize)]
pub struct Response {
  pub err: Option<RespErr>,
  pub data: Option<Void>,
}

impl Response {
  pub fn from(json: String) -> Result<Response> {
    Ok(serde_json::from_str::<Response>(&json)?)
  }
}

impl SseEncode for FFIError {
  fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
    <String>::sse_encode(format!("{:?}", self), serializer);
  }
}
```

## 结合 Dio 使用

上面只是讲这玩意怎么写，肯定有人会有疑问，为啥要这么麻烦，其实只是初期工作会比较多，后面这些套路模板只要写一遍，唯一会变的就是每个响应有错误或者有数据的情况要随机应变一下，譬如像 Response 跟 Void 这种就是要根据实际业务改变的结构体。  
现在来结合 Dio 使用，首先肯定是给项目添加 Dio

```bash
flutter pub add dio
```

然后写个简单的 NodeJS 程序模拟下返回 JSON 的接口，本来想写 PHP 的，因为用 PHP 写得代码比 NodeJS 更少，后来发觉我现在这个设备没装 PHP 环境

```javascript
const http = require('http');
const hostname = '127.0.0.1';
const port = 3000;
 
const server = http.createServer((req, res) => {
  const jsonData = {
    err: null,
    data: null
  };
  // const jsonData = {
  //   err: {
  //     code: 403,
  //     msg: "权限不足"
  //   },
  //   data: null
  // };
 
  res.statusCode = 200;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(jsonData));
});
 
server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});
```

写完直接用 NodeJS 跑起来，然后改改 Flutter 的 main.dart，因为是示例项目，直接在 main.dart 改就行了

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:deserialize_demo/src/rust/api/simple.dart' as simple;
import 'package:deserialize_demo/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _text = ValueNotifier("");

  String get text => _text.value;
  set text(String newValue) {
    if (newValue == text) {
      return;
    }
    _text.value = newValue;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final options = Options(responseType: ResponseType.plain);
            final res =
                await Dio().post("http://127.0.0.1:3000", options: options);
            final result = await simple.Response.from(json: res.data);
            if (result.err == null) {
              text = "None";
            } else {
              text = result.err!.msg;
            }
          },
          child: const Icon(Icons.send),
        ),
        appBar: AppBar(title: const Text('JSON Deserialize')),
        body: Center(
          child: ValueListenableBuilder(
            valueListenable: _text,
            builder: (context, v, _) => Text(v),
          ),
        ),
      ),
    );
  }
}
```

可以分别测试一下 err 为空的情况跟 err 不为空的情况，总之就是现在我们已经实现了自动反序列化的操作了。

## from 方法简化

我们还发觉，实现从字符串反序列化的函数也是模板，这怎么能忍，直接派生宏走起

```bash
cargo init duplicated-derive
```

改改 Cargo.toml

```toml
[package]
name = "duplicated-derive"
version = "0.1.0"
edition = "2021"

[lib]
proc-macro = true

[dependencies]
quote = "1.0"
proc-macro2 = "1.0"
syn = { version = "2", features = ["full"] }
```

实现下宏

```rust
use proc_macro::TokenStream;
use syn::{parse_macro_input, DeriveInput};

#[proc_macro_derive(Duplicated)]
pub fn derive_duplicated(i: TokenStream) -> TokenStream {
  fn generate(syntax_tree: DeriveInput) -> syn::Result<proc_macro2::TokenStream> {
    let struct_name = syntax_tree.ident;

    Ok(quote::quote! {
      impl #struct_name {
          pub fn from(json: String) -> Result<#struct_name> {
              Ok(serde_json::from_str::<#struct_name>(&json)?)
          }
      }
    })
  }
  let syntax_tree = parse_macro_input!(i as DeriveInput);
  match generate(syntax_tree) {
    Ok(st) => st.into(),
    Err(e) => e.to_compile_error().into(),
  }
}
```

然后把 simple.rs 某段代码改掉，后续有同类（入口）结构体，都可以用这个派生宏

```rust
#[derive(Debug, Deserialize, duplicated_derive::Duplicated)]
pub struct Response {
  pub err: Option<RespErr>,
  pub data: Option<Void>,
}
```
