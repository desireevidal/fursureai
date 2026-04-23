#!/usr/bin/env dart
// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  print('Cleaning build artifacts...');
  await _run('flutter', ['clean']);
  await _run('flutter', ['pub', 'get']);
  print('Clean complete!');
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
