#import "@preview/polylux:0.3.1": *
#import "tamburlaine.typ": *

#show: tamburlaine-theme.with(aspect-ratio: "4-3")
#show link: item => underline(text(blue)[#item])

#let citation(b) = {
  [
    #v(1fr)
    #set text(size: 12pt)
    #set align(right)
    #b
    #v(2em)
  ]
}

#enable-handout-mode(true)

#let zig_logo = read("./assets/zig-logo-light.svg").replace("#FFF", SECONDARY_COLOR.to-hex())

#title-slide(
  title: [
    Optimal approaches with #h(3.872em)
    #move(dy: -2em, image.decode(zig_logo, width: 55%))
  ],
  authors: ("Fergus Baker",),
  where: "Cambridge RSE Seminar",
)

#slide(title:"About Me")[
]

#slide(title:"About Zig")[
  #grid(columns: (70%, 1fr),
  [
  - Created by *Andrew Kelley*
  - *Zig Software Foundation* charity
  - 501(c)(3) not-for-profit corporation
  - *Systems programming language* and *toolchain*
  - Use case is for where software *can't fail*
],[
  #move(dx: 2cm, image("./assets/andrew-kelley.jpg", width: 70%))
])
  #v(1em)#align(right)[
    #quote("Fix the problems with C and no more") \
    See more in #link("https://www.youtube.com/watch?v=Gv2I7qTux7g")[The Road to Zig 1.0 (YouTube)]
  ]
]

#slide(title:"Outline for this talk")[
  #set text(size: 30pt)
  #grid(columns: (40%, 1fr),
  [
  - Zig the builder
  - Zig the language
  - Zig the project
],
  [
    #move(dy: -0cm, dx: 4cm, scale(x: -100%, image("./assets/satisfaction.png", height: 75%)))
  ])

  #citation[
    Illustration: #link("https://victorianweb.org/art/illustration/thomson/6.html")
  ]
]

#slide()[
  #set par(leading: 20pt)
  #rect(fill: TEXT_COLOR, width: 100%, height: 85%, inset: (right: 1cm))[
  #v(5em)
  #align(right, text(size: 110pt, weight:"black", fill: SECONDARY_COLOR)[the \ builder])
  #move(dy: -12cm, dx: 4cm, image.decode(zig_logo, width: 50%))
  ]
]

#slide()[
  #set align(center)
  #v(-18em)
  #text(size: 420pt, weight: "black")[xz]
]

#slide()[
  #set align(center)
  #image("./assets/sock-puppets.png", height: 90%)
]

#slide()[
  #set align(center)
  #image("./assets/rewrite-in-rust.png")
]

#slide()[
  #set align(center)
  #v(-18em)
  #text(size: 420pt, weight: "black")[xz]
]

#slide()[
  #set align(center)
  #image("./assets/to-host-backdoor.png", height: 80%)

  #citation[
    Source: #link("https://gist.github.com/thesamesam/223949d5a074ebc3dce9ee78baad9e27#design-specifics")
  ]
]

#slide()[
  #set align(center)
  #v(3em)
  #image("./assets/autotools-horrible.png", width: 90%)

  #citation[
  Source: #link("https://felipec.wordpress.com/2024/04/04/xz-backdoor-and-autotools-insanity/") (I do not agree with the post)
  ]
]

#slide()[
  #set align(center)
  #image("./assets/cmake-landlock.png", width: 80%)
  #image("./assets/evil-dot.png", width: 80%)

  #citation[
  Source: #link("https://github.com/tukaani-project/xz/commit/328c52da8a2bbb81307644efdb58db2c422d9ba7")
  ]
]

#slide(title: "Build systems are complex")[
  To develop in *C* you need to know one of \[*autotools*, *GNU make*, *CMake*, *meson*, *ninja*, *Gradle*, *SCons*, *Shake*, *Tup*, *bazel*, *premake*, *Ceedling*, ... \]

  #uncover("2-")[
  To develop in *C* you need to know #text(fill: PRIMARY_COLOR)[*a second language*].
]

  #grid(columns: (50%, 1fr),
  [
    #move(dx: 1cm, image("./assets/ancient-mariner.png", width: 60%))
  ],
  align(right)[
    #v(2em)
    #uncover("3-")[
    Zig builds are written in Zig. \
  ]
    #uncover("4-")[
    Zig also compiles C/C++ code.
  ]
  ]
)

  #citation[
    Illustration: #link("https://victorianweb.org/art/illustration/wehnert/34.html")
  ]
]

#slide(title: "Building xz with Zig")[
#grid(columns: (60%, 1fr),
[
#set text(size: 16pt)
#set par(leading: 6pt)
```zig
const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const liblzma = b.addStaticLibrary(.{
        .name = "lzma",
        .target = target,
        .optimize = optimize,
    });

    // call to our utility function
    defineMacros(liblzma);
    liblzma.defineCMacro("LZMA_API_STATIC", null);

    liblzma.linkLibC();

    liblzma.addCSourceFiles(.{ .files = &LZMA_SOURCES });
    // add include paths
    liblzma.addIncludePath(.{
       .path = "src/liblzma/api",
    });
    // ... lots more

    // install into `./zig-out/lib/liblzma.a`
    b.installArtifact(liblzma);
}
```],
[
  Checked by the Zig compiler for syntax

  - Explicit
  - Simple

  Utility functions

  #move(dx: 2em, dy:3em, scale(x: -100%, image("./assets/ziggy.svg", width: 60%)))
]
)
]

#slide(title: "Linking to executables")[
#v(1em)
#set text(size: 20pt)
#show "linkLibrary": text.with(weight: "black", fill: PRIMARY_COLOR)
```zig
const xzexe = b.addExecutable(.{
    .name = "xz",
    .target = target,
    .optimize = optimize,
});

xzexe.linkLibC();
xzexe.linkLibrary(liblzma);

xzexe.addCSourceFiles(.{ .files = &XZ_SOURCES });

xzexe.addIncludePath(.{ .path = "src/common" });
xzexe.addIncludePath(.{ .path = "src/liblzma/api/lzma/" });
xzexe.addIncludePath(.{ .path = "src/liblzma/api/" });

defineMacros(xzexe);

b.installArtifact(xzexe);
```
]


#slide(title: "Immediate benefits")[
Cached compilation for free

#grid(columns:(50%, 1fr),
[
#set block(spacing: 20pt)

#let highlight = text.with(weight: "black")
#show regex("^\$.*"): highlight
#show regex("user .*"): text.with(fill: PRIMARY_COLOR, weight: "black")
```
$ time zig build
  CPU       197%
  user      15.860
  system    3.363
  total     9.718
```
#v(0.3em)

#uncover("2-")[
Making some changes
#v(0.3em)

```
$ vim src/xz/main.c
$ time zig build
  CPU      155%
  user     0.107
  system   0.206
  total    0.201
```
]
],
[
  #v(1em)
  Sensible defaults
  - UB sanitizer
  - Warnings
  - `-fno-omit-framepointer`
])
]


#slide(title: "Native debug build")[
#set block(spacing: 20pt)
#block(text(weight: "black", raw("$ zig build")))
#block(text(weight: "black", raw("$ file ./zig-out/bin/xz")))
#{
  let highlight = text.with(fill: PRIMARY_COLOR, weight: "black")
  show "x86-64": highlight
  show "64-bit": highlight
  ```
  ./zig-out/bin/xz: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 4.4.0, with debug_info, not stripped
  ```
}
#block(text(weight: "black", raw("$ ldd ./zig-out/bin/xz")))
```
	linux-vdso.so.1 (0x00007ffeaafd0000)
	liblzma.so.0 => /home/lilith/Developer/xz/zig-cache/o/4b1bf6dae4eb1dd6464b6aa63cb44c53/liblzma.so.0 (0x000077b6b770d000)
	libc.so.6 => /usr/lib/libc.so.6 (0x000077b6b7504000)
	/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2 (0x000077b6b77f4000)
```
]

#slide(title: "Static aarch64 release")[
#set block(spacing: 20pt)
#block(text(weight: "black", raw("$ zig build \\")))
#block(text(weight: "black", raw("      -Doptimize=ReleaseSmall -Dtarget=aarch64-linux-musl")))
#block(text(weight: "black", raw("$ file ./zig-out/bin/xz")))
#{
  let highlight = text.with(fill: PRIMARY_COLOR, weight: "black")
  show "ARM aarch64": highlight
  show "statically linked": highlight
  show "64-bit": highlight
  ```
  ./zig-out/bin/xz: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
  ```
}
#block(text(weight: "black", raw("$ ldd ./zig-out/bin/xz")))
```
	not a dynamic executable
```
]

#slide(title: "Adding a build option")[
#{
set text(size: 22pt)
```zig
const liblzma_static = b.option(
    bool,
    "static",
    "Build and link liblzma statically",
) orelse true;

if (liblzma_static) {
  // configure things for a static build
} else {
  // configure for shared library
}
```
}
#uncover("2-")[
#block(text(weight: "black", raw("$ zig build --help")))

```
Project-Specific Options:
  ...
  -Dstatic=[bool]       Build and link liblzma statically
```
]
]

#slide(title: "Target specifics")[
#v(0.1em)
Switch on the target:
#{
set text(size: 20pt)
let highlight = text.with(weight: "black")
```zig
switch (target.result.os.tag) {
    .windows => {
        // ...
        exe_or_lib.addWin32ResourceFile(.{
            .file = .{ .path = windows_rc_file },
            .flags = &.{
                "-I./src/liblzma/api/",
                // ...
            },
        });
    },
    else => {
        exe_or_lib.defineCMacro("HAVE_FUTIMES", null);
    },
}
```
}
]

#slide(title: "DLLs and Windows")[
#set block(spacing: 20pt)
#block(text(weight: "black", raw("$ zig build -Dstatic=false -Dtarget=x86_64-windows")))
#block(text(weight: "black", raw("$ file ./zig-out/bin/xz")))
#{
  let highlight = text.with(fill: PRIMARY_COLOR, weight: "black")
  show "MS Windows": highlight
  ```
./zig-out/bin/xz.exe: PE32+ executable (console) x86-64, for MS Windows, 8 sections
  ```
}
#block(text(weight: "black", raw("$ ls ./zig-out/lib/")))
```
lzma.dll  lzma.lib  lzma.pdb
```
#v(2em)
#align(right)[
Build *from* any target *to* any target.
]

#citation[ I don't have a Windows machine so I couldn't test the binary. ]
]

#slide(title: "Installing the cross-compiler toolchain")[
  Other cross compilers have tedious setup, need all sorts of gcc binaries or MSVC hell
  #uncover("2-")[
    1. Download and decompress (using our freshly built xz)
  ]
  #uncover("3-")[
    2. #text(fill: PRIMARY_COLOR, [*That's it, we're done.*])
  ]
  #v(-0.6em)
  #uncover("4-")[
  #align(center, image("./assets/install-zig.png", width: 70%))
  ]
]

#slide(title: "Made with Zig")[
  list of big projects that use Zig as buildtool
]

#slide()[
  #set par(leading: 20pt)
  #rect(fill: TEXT_COLOR, width: 100%, height: 85%, inset: (right: 1cm))[
  #v(5em)
  #align(right, text(size: 110pt, weight:"black", fill: SECONDARY_COLOR)[the language])
  #move(dy: -12cm, dx: 4cm, image.decode(zig_logo, width: 50%))
  ]
]

#slide()[
  #v(-1.5em)
  #grid(
    columns:(60%, 1fr),
  [
  - *Errors*
  - *Allocators*
  - *Comptime functions*
  - Call conventions
  - `test`
  - Pointers and slices
  - Packed structs
  - Struct of Arrays
  - Anonymous structs
  - Optionals
  - Comptime types
  - Enums
  - Async
  - Unions and tagged unions
  - Arrays and hashmaps
  - SIMD intrinsics `@Vector`
],[
  #v(1.5em)
  Focus on these today
  #move(dx: -4cm, dy: -2.8cm, text(size: 88pt, "}"))

  #image("./assets/zero.svg")
]
)
]

#slide(title: "Errors are everywhere")[
  #align(center, image("./assets/never-do-malloc-like-this.png", width: 80%))

  Errors need to be handled.
  - A language should make it *easy* to handle them.
  - Optimal: a language should make it *easier* to handle errors than to *ignore* them.
]

#slide()[
  #v(2em)
  #align(right)[
  Unsafe code is code that doesn't handle all of it's errors.
]
  #v(1em)
  #align(left)[
  *Safe code* is code that *handles all of its errors*, not code that doesn't have any errors.
  ]
  #move(dx: 3cm,
    image("./assets/thackeray.jpg")
  )
  #citation[Illustration: #link("https://victorianweb.org/art/illustration/thackeray/cooke4.html")]
]

#slide(title: "Errors are unavoidable")[
#set text(size: 23pt)
```zig
fn overwrite(sub_path: []const u8) void {
    const f = std.fs.cwd().openFile(
        sub_path,
        .{ .mode = .read_write },
    );
    f.seekTo(0);
    _ = f.write("Hello start");
    f.close();
}
```

Forced to handle `openFile` errors:

#align(center)[
#image("./assets/file-seek-error.png", width: 95%)
]
]

#slide(title: "Catching errors")[
#set text(size: 23pt)
#grid(columns: (50%, 1fr),
[
#show "catch": it => [#box(radius: 3pt, fill: PRIMARY_COLOR, text(weight: "black", fill: TEXT_COLOR, it))]
```zig
const f = std.fs.cwd().openFile(
    sub_path,
    .{ .mode = .read_write },
) catch |err| {
    switch (err) {}
};
```
Error sets are part of the API

- Explicit sets
```zig
fn foo() error{OhNo,Sad}!void {
  // ...
}
```
],
[
  #v(2em)
  #image("./assets/switch-cases.png")
])
]

#slide(title: "Bubbling errors up")[
#text(size: 23pt)[
#show "try": it => [#box(radius: 3pt, fill: PRIMARY_COLOR, text(weight: "black", fill: TEXT_COLOR, it))]
#show "!": it => [#box(radius: 3pt, fill: PRIMARY_COLOR, text(weight: "black", fill: TEXT_COLOR, it))]
```zig
fn overwrite(sub_path: []const u8) !void {
    const f = try std.fs.cwd().openFile(
        sub_path,
        .{ .mode = .read_write },
    );
    try f.seekTo(0);
    _ = try f.write("Hello start");
    f.close();
}
```
]
#grid(columns:(55%, 1fr),
[
Let the caller handle the error
- Bubble back to `main` and report the error to the user *with a trace*
],[
  #move(dx: 2cm, dy: -3cm, image("./assets/cat-tenniel.jpg", width: 80%))
])
#citation[Illustration: #link("https://victorianweb.org/art/illustration/tenniel/lookingglass/1.2.html")]
]

#slide(title: "Errors past main")[
  #set align(center)
  #v(1em)
  #image("./assets/runtime-error.png")
]

#slide(title: "Defer")[
#text(size: 23pt)[
#show "defer": it => [#box(radius: 3pt, fill: PRIMARY_COLOR, text(weight: "black", fill: TEXT_COLOR, it))]
```zig
fn overwrite(sub_path: []const u8) !void {
    const f = try std.fs.cwd().openFile(
        sub_path,
        .{ .mode = .read_write },
    );
    defer f.close();
    try f.seekTo(0);
    _ = try f.write("Hello start");
}
```
]
Initialisation and destruction are *right next to eachother*.
#set text(size: 20pt)
```zig
std.debug.print("Outer", .{});
defer std.debug.print("Outer goodbye", .{});
{
   std.debug.print("Inner", .{});
   defer std.debug.print("Inner goodbye 1", .{});
   defer std.debug.print("Inner goodbye 2", .{});
}
```
]

#slide(title: "Errdefer")[
  Caller now obtains the file handle and must close.
#grid(columns: (60%, 1fr),
[
  #show "errdefer": it => [#box(radius: 3pt, fill: PRIMARY_COLOR, text(weight: "black", fill: TEXT_COLOR, it))]
  #text(size: 22pt)[
  ```zig
  fn overwrite(sub_path: []const u8) !File {
      const f = try std.fs.cwd().openFile(
          sub_path,
          .{ .mode = .read_write },
      );
      errdefer f.close();
      try f.seekTo(0);
      _ = try f.write("Hello start");
      return f;
  }
  ```
If anything goes wrong we have *cleanup*]],
[#v(2cm) #image("./assets/doormouse.jpg", height: 45%)])
#citation[
  Illustration: #link("https://victorianweb.org/art/illustration/tenniel/alice/7.3.html")
]
]

#slide(title: "No hidden allocations")[
  Allocating functions in Zig have an interface like
  ```zig
  fn foo(allocator: Allocator) !void {
      // do memory things
  }
  ```

  Allocators are *passed* to functions.

  ```zig
  const slice = try allocator.alloc(u8, 10);
  ```

  Allocations *can fail*.

  #v(2em)
  #align(right)[
    Possible to have different allocators for different things or different scopes.
  ]
]

#slide(title: "Memory leaks")[
  ```zig
  var gpa = std.heap.GeneralPurposeAllocator(.{}){};
  defer _ = gpa.deinit();
  const allocator = gpa.allocator();
  ```
  Trace of the leak, and where it was allocated:
  #align(center)[
    #image("./assets/memory-leak.png", width: 80%)
  ]
]

#slide(title: "Segfaults")[
  Use after free:
  #align(center)[
    #image("./assets/segfault.png", width: 80%)
  ]
  Double free:
  #align(center)[
    #image("./assets/double-free.png", width: 80%)
  ]

]

#slide(title: "Allocation patterns")[
  ```zig
  const slice = try allocator.alloc(u32, num);
  defer allocator.free(slice);
  ```

  Structs may hold onto their allocator to free themselves

  ```zig
  var list = std.ArrayList(f32).init(allocator);
  // the allocator is held by the array list
  defer list.deinit();
  ```

  *Arena allocators* for performance and simplicity

  ```zig
  var mem = std.heap.ArenaAllocator.init(allocator);
  defer mem.deinit();

  _ = try mem.allocator().alloc(u32, 1024);
  _ = try mem.allocator().alloc(u32, 1024);
  ```
]

#slide(title: [#uncover("4-")[C Metaprogramming]])[
#block[
  #set raw(lang: "c")
  #raw("#include <stdlib.h>\n")
  #uncover("3-", raw("#define abs(x) (x < 0 ? -x : x)\n"))
  #raw("int main() {\n  int x = -2;\n  return abs(++x);\n}\n")
]
#uncover("2-")[
```
$ gcc -Wall -Wextra -Wpedantic ./a.c && ./a.out ; echo "$?"
0
```
]
#v(-2em)
#uncover("5-")[
  #align(right)[
    #quote[The C preprocessor is a foot gun]
  ]
  #v(-2em)
  #move(dx: 2em)[
    #image("./assets/footguns.png", width: 30%)
  ]
]

#uncover("5-")[
#citation[
  Worth reading: #link("https://gcc.gnu.org/onlinedocs/gcc-6.3.0/cpp/Macro-Pitfalls.html#Macro-Pitfalls")
]
]
]

#slide(title: "Comptime")[

Execute code (explicitly) at *compile time*

```zig
// string literal
const name = "Shelagh Delaney";

// labeled block explicitly comptime
const e_count = comptime label: {
    var count: usize = 0;
    for (name) |c| {
        if (c == 'e') count += 1;
    }
    break :label count;
};
```

]

#slide(title: "Runtime")[
  #set align(center)
  #image("./assets/shelagh-runtime.png", width: 90%)
  #citation[
    #link("https://godbolt.org/z/Paja3d7dE")
  ]
]

#slide(title: "Comptime")[
  #set align(center)
  #image("./assets/shelagh-comptime.png", width: 90%)
  #citation[
    #link("https://godbolt.org/z/s7xzKqPvs")
  ]
]

#slide(title: "A glance at generics")[

Compile time execution _is_ metaprogramming:
#set text(size: 16pt)
#grid(columns: (40%, 1fr),
[
```zig
const FlagInfo = struct {
    required: bool = false,
    name: []const u8 = "flag",
    arg_id: u32,
    arg_count: u32 = 0,
};
```
#move(dx: 1.5cm, scale(x:-100%, image("./assets/honest-work.jpg", width: 55%)))
],[
```zig
fn numArgFields(comptime T: type) usize {
    const info = @typeInfo(T);
    switch (info) {
        .Struct => {},
        else => @compileError("Must be a struct."),
    }

    var arg_count: usize = 0;
    inline for (info.Struct.fields) |field| {
        if (std.mem.startsWith(u8, field.name, "arg_")) {
            arg_count += 1;
        }
    }
    return arg_count;
}
```
])
  #citation[
    Illustration: #link("https://victorianweb.org/art/illustration/barnes/21.html")
  ]
]

#slide()[
#v(3em)
#align(center)[
#image("./assets/compiler-error.png", width: 80%)
]
Compile time error message
- Reference trace
- Information about the specific build command that triggered the error
]

#slide()[
  #set par(leading: 20pt)
  #rect(fill: TEXT_COLOR, width: 100%, height: 85%, inset: (right: 1cm))[
  #v(5em)
  #align(right, text(size: 110pt, weight:"black", fill: SECONDARY_COLOR)[the \ project])
  #move(dy: -12cm, dx: 4cm, image.decode(zig_logo, width: 50%))
  ]
]
#slide(title: "Zen of Zig")[
  #v(1em)
  #set text(size: 22pt)
  - Communicate intent precisely.
  - Edge cases matter.
  - Favor reading code over writing code.
  - Only one obvious way to do things.
  - *Runtime crashes are better than bugs.*
  - *Compile errors are better than runtime crashes.*
  - Incremental improvements.
  - Avoid local maximums.
  - Reduce the amount one must remember.
  - Focus on code rather than style.
  - *Resource allocation may fail; resource deallocation must succeed.*
  - *Memory is a resource.*
  - Together we serve the users.
  ]

#slide()[
  #v(-2em)
  #align(right, par(leading: 25pt, text(size: 90pt, weight: "black")[Optimal approaches to develop#text(fill:PRIMARY_COLOR)[ing]]))
]

#slide()[
  #align(center)[
    #image("./assets/lorris-cro-talk.png", width: 80%)
    #text(size: 22pt)[Interview with Loris Cro of ZFS \ #link("https://www.youtube.com/watch?v=5_oqWE9otaE")]
  ]
]

#slide(title: "Notable projects")[
  #v(2em)
  #align(center)[
    #image.decode(read("./assets/logo-with-text-white.svg").replace("white", TEXT_COLOR.to-hex()), width: 70%)
    #image("./assets/bun.png", width: 20%)
  ]
]

#slide()[
  #v(-2em)
  #align(right, par(leading: 25pt, text(size: 90pt, weight: "black")[Optimal approaches to develop#text(fill:PRIMARY_COLOR)[ing]]))
]

#slide()[
  #v(-2em)
  #align(right, par(leading: 25pt, text(size: 90pt, weight: "black")[Optimal approaches to develop#text(fill:PRIMARY_COLOR)[ers]]))
]

#slide()[
  #set align(center)
  #v(-18em)
  #text(size: 420pt, weight: "black")[xz]
]

#slide()[
  #v(3em)
  #align(center)[
    #image("./assets/struggle-maintain.png", width: 80%)
  ]
]

#slide()[
  #set align(center)
  #v(-18em)
  #text(size: 420pt, weight: "black")[xz]
]

#slide(title: "Programming is emotional")[
  #align(center,
    image("./assets/c-swearwords.jpg", height: 70%)
  )
]

#slide()[
  #align(center)[
    #link("https://softwareyoucan.love")[
      #set text(size: 50pt)
      #text("https://")#text(weight: "black", fill: TEXT_COLOR, "software")#text(weight: "black", fill: PRIMARY_COLOR, "you")#text(weight: "black", fill: TEXT_COLOR, "can")#text(".")#text(weight: "black", fill: PRIMARY_COLOR, "love")
    ]
  ]
  #v(-1cm)
  #align(center, image("./assets/sycl-vancouver.png", width: 70%))
  #citation[
    Banner art from #link("https://softwareyoucanlove.ca/")
  ]
]

#slide(title: "Thanks")[
  Thanks and references slide

  Ziglings
  Zig guide
]

