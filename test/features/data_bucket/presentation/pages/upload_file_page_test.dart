import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/network/google_drive_service.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/upload_file_page.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:cross_file/cross_file.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';

class MockFilePickerPlatform extends Mock with MockPlatformInterfaceMixin implements FilePickerPlatform {}

class MockDataBucketRepository extends Mock implements DataBucketRepository {}

class MockGoogleDriveService extends Mock implements GoogleDriveService {}

class MockZoneRepository extends Mock implements ZoneRepository {}

base class FakePlatformFile extends PlatformFile {
  final String _name;
  final int _size;
  final Uint8List _bytes;
  final bool _shouldThrow;

  FakePlatformFile(this._name, this._size, this._bytes, {bool shouldThrow = false})
      : _shouldThrow = shouldThrow;
        

  @override
  String get name => _name;

  @override
  String? get extension {
    final dot = _name.lastIndexOf('.');
    if (dot < 0) return null;
    return _name.substring(dot + 1);
  }

  @override
  Future<int> length() async => _size;

  @override
  Future<Uint8List> readAsBytes() async {
    if (_shouldThrow) throw Exception('Gagal membaca file');
    return _bytes;
  }

  @override
  Uri get uri => Uri.file(_name);

  @override
  XFile get xFile => XFile.fromData(_bytes, name: _name, length: _size);

  @override
  Stream<Uint8List> readAsByteStream() async* {
    if (_shouldThrow) throw Exception('Read error');
    yield _bytes;
  }
}

void main() {
  late MockFilePickerPlatform mockFilePicker;
  late MockDataBucketRepository repository;
  late MockGoogleDriveService driveService;
  late MockZoneRepository zoneRepository;

  setUpAll(() {
    registerFallbackValue(FileType.custom);
  });

  setUp(() {
    mockFilePicker = MockFilePickerPlatform();
    FilePickerPlatform.instance = mockFilePicker;
    repository = MockDataBucketRepository();
    driveService = MockGoogleDriveService();
    zoneRepository = MockZoneRepository();

    when(() => zoneRepository.getZones()).thenReturn(<ZoneEntity>[]);
  });

  Widget buildTestApp() {
    return MaterialApp(
      home: FTheme(
        data: FTheme.neutral.light.touch,
        child: UploadFilePage(
          repository: repository,
          siteId: 'site-1',
          driveService: driveService,
          zoneRepository: zoneRepository,
        ),
      ),
    );
  }

  testWidgets('Happy path: selects a valid 1MB file', (tester) async {
    final fakeFile = FakePlatformFile('test.shp', 1024 * 1024, Uint8List(10));
    when(
      () => mockFilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: any(named: 'allowedExtensions'),
      ),
    ).thenAnswer((_) async => fakeFile);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Tap the picker button
    await tester.tap(find.text('Pilih File'));
    await tester.pumpAndSettle();

    expect(find.text('test.shp'), findsOneWidget);
    expect(find.text('1.0 MB'), findsOneWidget);
  });

  testWidgets('Boundary: rejects file 1 byte over max size (50MB)', (
    tester,
  ) async {
    const int maxBytes = 50 * 1024 * 1024;
    final fakeFile = FakePlatformFile('huge.tiff', maxBytes + 1, Uint8List(0));
    when(
      () => mockFilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: any(named: 'allowedExtensions'),
      ),
    ).thenAnswer((_) async => fakeFile);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih File'));
    await tester.pumpAndSettle();

    // Should show error and not select the file
    expect(find.text('File terlalu besar (maks 50 MB).'), findsOneWidget);
    expect(find.text('huge.tiff'), findsNothing);
  });

  testWidgets('Boundary: accepts file exactly at max size (50MB)', (
    tester,
  ) async {
    const int maxBytes = 50 * 1024 * 1024;
    final fakeFile = FakePlatformFile('exact.tiff', maxBytes, Uint8List(10));
    when(
      () => mockFilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: any(named: 'allowedExtensions'),
      ),
    ).thenAnswer((_) async => fakeFile);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih File'));
    await tester.pumpAndSettle();

    expect(find.text('exact.tiff'), findsOneWidget);
  });

  testWidgets('Cancellation: keeps previous state if picker cancelled', (
    tester,
  ) async {
    when(
      () => mockFilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: any(named: 'allowedExtensions'),
      ),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih File'));
    await tester.pumpAndSettle();

    // Still shows the placeholder
    expect(find.text('Pilih File'), findsOneWidget);
  });

  testWidgets('Read failure: shows error if readAsBytes throws', (
    tester,
  ) async {
    final fakeFile = FakePlatformFile(
      'error.shp',
      1024,
      Uint8List(0),
      shouldThrow: true,
    );
    when(
      () => mockFilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: any(named: 'allowedExtensions'),
      ),
    ).thenAnswer((_) async => fakeFile);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih File'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal memilih file:'), findsOneWidget);
    expect(find.text('error.shp'), findsNothing);
  });
}
