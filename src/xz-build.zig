const std = @import("std");

fn defineMacros(
    exe_or_lib: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    windows_rc_file: []const u8,
) void {
    exe_or_lib.defineCMacro("HAVE_INTTYPES_H", null);
    exe_or_lib.defineCMacro("HAVE_STDINT_H", null);
    exe_or_lib.defineCMacro("HAVE_STDBOOL_H", null);
    exe_or_lib.defineCMacro("HAVE__BOOL", null);

    exe_or_lib.defineCMacro("HAVE_CHECK_CRC32", null);
    exe_or_lib.defineCMacro("HAVE_CHECK_CRC64", null);
    exe_or_lib.defineCMacro("HAVE_CHECK_SHA256", null);

    exe_or_lib.defineCMacro("HAVE_ENCODERS", null);
    exe_or_lib.defineCMacro("HAVE_DECODERS", null);

    exe_or_lib.defineCMacro("ASSUME_RAM", "128");
    exe_or_lib.defineCMacro("PACKAGE_NAME", "\"XZ Utils\"");
    exe_or_lib.defineCMacro("PACKAGE_BUGREPORT", "\"xz@tukaani.org\"");
    exe_or_lib.defineCMacro("PACKAGE_URL", "\"https://tukaani.org/xz/\"");

    switch (target.result.os.tag) {
        .windows => {
            exe_or_lib.defineCMacro("DLL_EXPORT", null);
            exe_or_lib.defineCMacro("HAVE_UTIME", null);
            exe_or_lib.addWin32ResourceFile(.{
                .file = .{ .path = windows_rc_file },
                .flags = &.{
                    "-I./src/liblzma/api/",
                    "-I./src/common/",
                    "/dPACKAGE_NAME",
                    "/dPACKAGE_BUGREPORT",
                    "/dPACKAGE_URL",
                },
            });
        },
        else => {
            exe_or_lib.defineCMacro("HAVE_FUTIMES", null);
        },
    }
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const liblzma_static = b.option(
        bool,
        "static",
        "Build and link liblzma statically",
    ) orelse true;

    const liblzma = block: {
        if (liblzma_static) {
            const liblzma = b.addStaticLibrary(.{
                .name = "lzma",
                .target = target,
                .optimize = optimize,
            });
            liblzma.defineCMacro("LZMA_API_STATIC", null);
            break :block liblzma;
        } else {
            const liblzma = b.addSharedLibrary(.{
                .name = "lzma",
                .target = target,
                .optimize = optimize,
                .version = .{ .major = 0, .minor = 1, .patch = 0 },
            });
            break :block liblzma;
        }
    };

    defineMacros(
        liblzma,
        target,
        "src/liblzma/liblzma_w32res.rc",
    );

    inline for (&[_][]const u8{ "HC3", "HC4", "BT2", "BT3", "BT4" }) |name| {
        liblzma.defineCMacro("HAVE_MF_" ++ name, null);
    }

    inline for (&[_][]const u8{ "LZMA1", "LZMA2", "DELTA" }) |name| {
        liblzma.defineCMacro("HAVE_ENCODER_" ++ name, null);
        liblzma.defineCMacro("HAVE_DECODER_" ++ name, null);
    }

    liblzma.linkLibC();

    liblzma.addCSourceFiles(.{ .files = &LZMA_SOURCES });
    liblzma.addIncludePath(.{ .path = "src/liblzma/api" });
    liblzma.addIncludePath(.{ .path = "src/liblzma/common" });
    liblzma.addIncludePath(.{ .path = "src/liblzma/check" });
    liblzma.addIncludePath(.{ .path = "src/liblzma/lz" });
    liblzma.addIncludePath(.{ .path = "src/liblzma/rangecoder" });
    liblzma.addIncludePath(.{ .path = "src/liblzma/lzma" });
    liblzma.addIncludePath(.{ .path = "src/liblzma/delta" });
    liblzma.addIncludePath(.{ .path = "src/liblzma/simple" });
    liblzma.addIncludePath(.{ .path = "src/common" });

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

    defineMacros(xzexe, target, "src/xz/xz_w32res.rc");

    b.installArtifact(liblzma);
    b.installArtifact(xzexe);
}

const XZ_SOURCES = [_][]const u8{
    "src/common/tuklib_exit.c",
    "src/common/tuklib_mbstr_fw.c",
    "src/common/tuklib_mbstr_width.c",
    "src/common/tuklib_open_stdxxx.c",
    "src/common/tuklib_progname.c",
    "src/xz/args.c",
    "src/xz/coder.c",
    "src/xz/file_io.c",
    "src/xz/hardware.c",
    "src/xz/main.c",
    "src/xz/message.c",
    "src/xz/mytime.c",
    "src/xz/options.c",
    "src/xz/sandbox.c",
    "src/xz/signals.c",
    "src/xz/suffix.c",
    "src/xz/util.c",
    "src/xz/list.c",
};

const LZMA_SOURCES = [_][]const u8{
    "src/common/tuklib_physmem.c",
    "src/liblzma/check/check.c",
    "src/liblzma/common/block_util.c",
    "src/liblzma/common/common.c",
    "src/liblzma/common/easy_preset.c",
    "src/liblzma/common/filter_common.c",
    "src/liblzma/common/hardware_physmem.c",
    "src/liblzma/common/index.c",
    "src/liblzma/common/stream_flags_common.c",
    "src/liblzma/common/string_conversion.c",
    "src/liblzma/common/vli_size.c",
    //CRC
    "src/liblzma/check/crc32_fast.c",
    "src/liblzma/check/crc32_table.c",
    "src/liblzma/check/crc64_fast.c",
    "src/liblzma/check/crc64_table.c",
    "src/liblzma/check/sha256.c",
    // ENCODER
    "src/liblzma/common/alone_encoder.c",
    "src/liblzma/common/block_buffer_encoder.c",
    "src/liblzma/common/block_encoder.c",
    "src/liblzma/common/block_header_encoder.c",
    "src/liblzma/common/easy_buffer_encoder.c",
    "src/liblzma/common/easy_encoder.c",
    "src/liblzma/common/easy_encoder_memusage.c",
    "src/liblzma/common/filter_buffer_encoder.c",
    "src/liblzma/common/filter_encoder.c",
    "src/liblzma/common/filter_flags_encoder.c",
    "src/liblzma/common/index_encoder.c",
    "src/liblzma/common/stream_buffer_encoder.c",
    "src/liblzma/common/stream_encoder.c",
    "src/liblzma/common/stream_flags_encoder.c",
    "src/liblzma/common/vli_encoder.c",
    // LZMA1
    "src/liblzma/lzma/lzma_encoder.c",
    "src/liblzma/lzma/lzma_encoder_optimum_fast.c",
    "src/liblzma/lzma/lzma_encoder_optimum_normal.c",
    "src/liblzma/lz/lz_encoder.c",
    "src/liblzma/lz/lz_encoder_mf.c",
    "src/liblzma/rangecoder/price_table.c",
    // DECODER
    "src/liblzma/common/alone_decoder.c",
    "src/liblzma/common/auto_decoder.c",
    "src/liblzma/common/block_buffer_decoder.c",
    "src/liblzma/common/block_decoder.c",
    "src/liblzma/common/block_header_decoder.c",
    "src/liblzma/common/easy_decoder_memusage.c",
    "src/liblzma/common/file_info.c",
    "src/liblzma/common/filter_buffer_decoder.c",
    "src/liblzma/common/filter_decoder.c",
    "src/liblzma/common/filter_flags_decoder.c",
    "src/liblzma/common/index_decoder.c",
    "src/liblzma/common/index_hash.c",
    "src/liblzma/common/stream_buffer_decoder.c",
    "src/liblzma/common/stream_decoder.c",
    "src/liblzma/common/stream_flags_decoder.c",
    "src/liblzma/common/vli_decoder.c",
    //LZMA1
    "src/liblzma/lzma/lzma_decoder.c",
    "src/liblzma/lz/lz_decoder.c",
    //PRESET
    "src/liblzma/lzma/lzma_encoder_presets.c",
    "src/liblzma/lzma/fastpos_table.c",
    "src/liblzma/delta/delta_common.c",
    "src/liblzma/simple/simple_coder.c",
    //OTHER
    "src/liblzma/delta/delta_encoder.c",
    "src/liblzma/lzma/lzma2_encoder.c",
    "src/liblzma/simple/simple_encoder.c",
    "src/liblzma/delta/delta_decoder.c",
    "src/liblzma/lzma/lzma2_decoder.c",
    "src/liblzma/simple/simple_decoder.c",
};
