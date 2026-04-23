#!/usr/bin/env dart
// Usage:
//   dart scripts/bump_version.dart {major|minor|patch|build} [--no-commit] [commit message]
//
// Flags:
//   --no-commit   Bump pubspec.yaml but skip the git commit step.
//
// Examples:
//   dart scripts/bump_version.dart patch
//   dart scripts/bump_version.dart minor --no-commit
//   dart scripts/bump_version.dart build "chore: release build for QA"

import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart scripts/bump_version.dart {major|minor|patch|build} [--no-commit] [message]',
    );
    exit(1);
  }

  final type = args[0];
  if (!['major', 'minor', 'patch', 'build'].contains(type)) {
    stderr.writeln('Error: type must be one of: major, minor, patch, build');
    exit(1);
  }

  final noCommit = args.contains('--no-commit');
  final msgArgs =
      args.sublist(1).where((a) => a != '--no-commit').toList();

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('Error: pubspec.yaml not found. Run from project root.');
    exit(1);
  }

  final content = pubspec.readAsStringSync();
  final versionRegex = RegExp(
    r'^version:\s+(\d+)\.(\d+)\.(\d+)\+(\d+)',
    multiLine: true,
  );
  final match = versionRegex.firstMatch(content);

  if (match == null) {
    stderr.writeln('Error: Could not parse version from pubspec.yaml');
    exit(1);
  }

  var major = int.parse(match.group(1)!);
  var minor = int.parse(match.group(2)!);
  var patch = int.parse(match.group(3)!);
  var build = int.parse(match.group(4)!);

  final current = '$major.$minor.$patch+$build';

  switch (type) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      build = 1;
    case 'minor':
      minor++;
      patch = 0;
      build = 1;
    case 'patch':
      patch++;
      build = 1;
    case 'build':
      build++;
  }

  final next = '$major.$minor.$patch+$build';
  final updated = content.replaceFirst('version: $current', 'version: $next');

  pubspec.writeAsStringSync(updated);
  stdout.writeln('$current → $next');

  if (noCommit) return;

  final msg = msgArgs.isNotEmpty
      ? msgArgs.join(' ')
      : 'chore: bump version to $next';

  await _run('git', ['add', 'pubspec.yaml']);
  await _run('git', ['commit', '-m', msg]);
  stdout.writeln('Committed: $msg');
}

Future<void> _run(String exe, List<String> args) async {
  final process = await Process.start(
    exe,
    args,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await process.exitCode;
  if (code != 0) exit(code);
}
