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

#enable-handout-mode(false)

#let zig_logo = read("./assets/zig-logo-light.svg").replace("#FFF", SECONDARY_COLOR.to-hex())

#title-slide(
  title: [
    Optimal approaches in #h(4.31em)
    #move(dy: -2em, image.decode(zig_logo, width: 60%))
  ],
  authors: ("Fergus Baker",),
  where: "Cambridge RSE Seminar",
)

#slide(title:"Zig")[
  - Created by Andrew Kelley, now under the Zig Software Foundation charity
  - Systems programming language and toolchain
  - Use case is for where software can't fail
  - "Fix the problems with C and no more"
]

#slide(title:"Outline")[
  Approaches learned from
  - Zig the builder
  - Zig the language
  - Zig the community
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

  To develop in *C* you need to know #text(fill: PRIMARY_COLOR)[*a second language*].

  #v(2em)
  #align(right)[
    Zig builds are written in Zig.
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
]
)
]

#slide(title: "Linking to executables")[
#v(1em)
#set text(size: 20pt)
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
#block(text(weight: "black", raw("$ zig build --help")))

```
Project-Specific Options:
  ...
  -Dstatic=[bool]       Build and link liblzma statically
```
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

#citation[ I don't have a Windows machine so I couldn't test the binary. ]
]

#slide()[
/home/lilith/.zigup/cache/0.12.0/files/lib/libc/include/wasm-wasi-musl/signal.h:2:2: error: "wasm lacks signal support; to enable minimal signal emulation, compile with -D_WASI_EMULATED_SIGNAL and link with -lwasi-emulated-signal"
]

#slide(title: "Installing the cross-compiler toolchain")[
  Other cross compilers have tedious setup, need all sorts of gcc binaries or MVSC hell
  1. Download and decompress (using our freshly built xz)
  2. That's it, we're done.
  #v(-0.6em)
  #align(center, image("./assets/install-zig.png", width: 70%))
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
  - *Errors*
  - *Allocators*
  - *Comptime functions*
  - Call conventions
  - `test`
  - Pointers and slices
  - Packed structs
  - Anonymous and comptime structs
  - Optionals
  - Enums
  - Async
  - Unions and tagged unions
  - Arrays and hashmaps
  - SIMD intrinsics `@Vector`
  ...
]

#slide(title: "Errors are everywhere")[
  Zig makes it easy to do the right thing with them
  - all prongs of `switch` must be handled (side effect: changing errors is a semver breaking change -- as it should be)
  - cleanup with `defer`

  "Zig wraps C libraries better than C"

  Optimal approach
]

#slide(title: "No hidden allocations")[
  Standard library accepts a `std.Allocator` to do all memory allocations.
  - Allocations can fail, Zig makes it easy to handle them with
  - Various allocators available, custom ones simple to add
  - Have various allocators
  - Arena allocators for when performance is key or too many allocations to track
    - Allocator all together, free at the same time
  - GPA will do leak, double free, etc detection
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
#align(right)[
#uncover("5-", quote[The C preprocessor is a foot gun])
]

#uncover("5-")[
#citation[
  Worth reading: #link("https://gcc.gnu.org/onlinedocs/gcc-6.3.0/cpp/Macro-Pitfalls.html#Macro-Pitfalls")
]
]
]

#slide(title: "Comptime")[

Execute code (explicitly) at *compile time*
- Comptime is Zig's way of *metaprogramming*


]

#slide(title: "A glimpse at comptime generics")[

Compile time execution _is_ metaprogramming:
```zig
fn range(comptime N: usize, x: anytype) [N]@TypeOf(x) {
    const T = @TypeOf(x);
    switch (@typeInfo(T)) {
        .Int => {},
        else => @compileError("Range needs integers!"),
    }
    const arr: [N]T = undefined;
    for (arr, x..) |*a, i| {
        a.* = i;
    }
    return arr;
}
```
]

#slide()[
  #set par(leading: 20pt)
  #rect(fill: TEXT_COLOR, width: 100%, height: 85%, inset: (right: 1cm))[
  #v(5em)
  #align(right, text(size: 110pt, weight:"black", fill: SECONDARY_COLOR)[the community])
  #move(dy: -12cm, dx: 4cm, image.decode(zig_logo, width: 50%))
  ]
]

#slide()[
  #v(-4em)
  #align(right, par(leading: 25pt, text(size: 90pt, weight: "black")[Optimal approaches to develop#text(fill:PRIMARY_COLOR)[ing]]))
  what does Zig encourage you do to?
  - keep code simple by making the right thing the easy thing
  - allocators that monitor memory and give reports
  - easy to generate compile time errors
  - meta program in the same language
  - write the build in the same language
]

#slide()[
  #v(-4em)
  #align(right, par(leading: 25pt, text(size: 90pt, weight: "black")[Optimal approaches to develop#text(fill:PRIMARY_COLOR)[ers]]))
  Zig community is full of talented people
  - Package manager means software is now easy to share
  - talented developers working on open source software is a net gain for the community
  - talented developers working on proprietary software only benefits the stakeholder
  Reading Zig blogs gave me a new approach to open source
  - Donations and sponsorship let people build the software that they want to
  - Go back to XZ example; would financial support have helped this developer be able to full-time work on `xz`?
  - Maybe not but it's easy to imagine projects that could benefit enormously from donations
]

#slide()[
  - XZ developer couldn't accept donations because of Finnish law
  - Sponsorship is not the complete answer to the need to support open source developers
  - As a community, we need to ask what we can do?
]

#slide()[
  Build and support https://softwareyoucan.love
]

#slide()[
  Thanks and references slide
]

