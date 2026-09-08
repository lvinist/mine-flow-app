// Standalone CI workflow YAML validator (STEP-48.29 R-1).
//
// Validates that .github/workflows/ci.yml still parses after guard edits.
// The prompt suggests `python -c "import yaml; ..."`, but the agent runtime
// gates python one-liners; package:yaml is already a transitive dependency
// (see pubspec.lock), so this dart entry point does the same job.
//
// Usage: dart run tool/ci/validate_workflow_yaml.dart [path-to-yaml]
library;

// Tooling script: imports the already-vendored transitive `yaml` package
// directly rather than promoting it to a direct pubspec dependency.
// ignore: depend_on_referenced_packages
import 'package:yaml/yaml.dart';
// Tooling script output is its product; print is the right sink here.
// ignore_for_file: avoid_print
import 'dart:io';

void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : '.github/workflows/ci.yml';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('[ERROR] workflow file not found: $path');
    exit(2);
  }
  try {
    final doc = loadYaml(file.readAsStringSync());
    if (doc is! YamlMap) {
      stderr.writeln('[ERROR] $path parsed but is not a YAML mapping');
      exit(1);
    }
    print('ci.yml: valid YAML (${doc.keys.length} top-level keys)');
  } on YamlException catch (e) {
    stderr.writeln('[ERROR] $path is not valid YAML: $e');
    exit(1);
  }
}
