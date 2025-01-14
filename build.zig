const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
const Target = std.Target;
const Feature = std.Target.Cpu.Feature;

pub fn build(b: *std.Build) void {
    const bootloader_optimize = b.standardOptimizeOption(.{});
    const crc_padder = b.addExecutable(.{
        .name = "compute_crc",
        .root_source_file = b.path("compute_crc.zig"),
        .target = b.host,
    });
    b.installArtifact(crc_padder);

    const target = std.Target.Query{
        .cpu_arch = Target.Cpu.Arch.arm,
        .os_tag = Target.Os.Tag.freestanding,
        .abi = Target.Abi.eabi,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    };

    const boot = b.addExecutable(.{ .name = "bootloader", .optimize = bootloader_optimize, .target = b.resolveTargetQuery(target) });
    boot.addAssemblyFile(b.path("src/boot2.s"));
    boot.setLinkerScriptPath(b.path("src/boot2.ld"));
    boot.step.dependOn(&crc_padder.step);

    b.installArtifact(boot);

    const boot_bin = b.addObjCopy(boot.getEmittedBin(), .{ .format = .bin });
    boot_bin.step.dependOn(&boot.step);

    const boot_binary = b.addInstallBinFile(boot_bin.getOutput(), "boot2_unpadded.bin");
    b.default_step.dependOn(&boot_binary.step);

    const crc_step = b.addRunArtifact(crc_padder);
    crc_step.addFileArg(boot_bin.getOutput());
    const output = crc_step.addOutputFileArg("padded_checked_boot.s");

    const exe = b.addExecutable(.{
        .target = b.resolveTargetQuery(target),
        .name = "main",
        .root_source_file = b.path("src/start.zig"),
        .optimize = bootloader_optimize,
    });
    exe.addAssemblyFile(output);
    exe.addAssemblyFile(b.path("src/start.s"));
    exe.setLinkerScriptPath(b.path("src/link.ld"));

    exe.addIncludePath(b.path("src"));
    b.installArtifact(exe);
}
