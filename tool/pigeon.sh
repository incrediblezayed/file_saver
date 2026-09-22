#!/usr/bin/env bash
# Regenerates the platform channel code from pigeons/messages.dart.
set -euo pipefail
cd "$(dirname "$0")/.."
dart run pigeon --input pigeons/messages.dart
# Pigeon writes a single Swift file; the macOS target builds from its own copy.
cp ios/file_saver/Sources/file_saver/Messages.g.swift \
   macos/file_saver/Sources/file_saver/Messages.g.swift
