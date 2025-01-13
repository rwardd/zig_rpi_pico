const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
const Target = std.Target;
const Feature = std.Target.Cpu.Feature;

pub fn build(b: *std.Build) void {
    const crc_padder = b.addExecutable(.{
        .name = "compute_crc",
        .root_source_file = b.path("compute_crc.zig"),
        .target = b.host,
    });
    b.installArtifact(crc_padder);

    const bootloader_optimize = b.standardOptimizeOption(.{});
    const target = std.Target.Query{
        .cpu_arch = Target.Cpu.Arch.arm,
        .os_tag = Target.Os.Tag.freestanding,
        .abi = Target.Abi.none,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    };

    const boot = b.addExecutable(.{ .name = "bootloader", .optimize = bootloader_optimize, .target = b.resolveTargetQuery(target) });
    boot.addAssemblyFile(b.path("src/boot2.s"));
    boot.setLinkerScriptPath(b.path("src/boot2.ld"));
    boot.step.dependOn(&crc_padder.step);

    b.installArtifact(boot);
    //const boot_elf = b.addInstallArtifact(boot, .{});
    //b.default_step.dependOn(&boot_elf.step);

    const boot_bin = b.addObjCopy(boot.getEmittedBin(), .{ .format = .bin });
    boot_bin.step.dependOn(&boot.step);

    const boot_binary = b.addInstallBinFile(boot_bin.getOutput(), "boot2_unpadded.bin");
    b.default_step.dependOn(&boot_binary.step);

    const generate_crc = [_][]const u8{ "./zig-out/bin/compute_crc", "./zig-out/bin/boot2_unpadded.bin" };
    //const compute_crc = b.addSystemCommand(&.{"./zig-out/bin/compute_crc"});
    //compute_crc.addArg("./zig-out/bin/boot2_unpadded.bin");
    _ = b.run(&generate_crc);

    const exe = b.addExecutable(.{
        .target = b.resolveTargetQuery(target),
        .name = "main",
        .root_source_file = b.path("src/start.zig"),
    });
    exe.addAssemblyFile(b.path("src/boot2.s"));
    exe.setLinkerScriptPath(b.path("src/link.ld"));

    exe.addIncludePath(b.path("src"));
    b.installArtifact(exe);
}
