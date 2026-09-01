// Widget tests for the Data Bucket upload screen's picker path (STEP-47.2).
//
// Mocks at the `FilePickerPlatform.instance` boundary per Doc 12's mocking
// strategy. The fake is hand-rolled rather than a `mocktail` mock so that the
// test needs no `plugin_platform_interface` import (that package is only a
// transitive dependency here): extending `FilePickerPlatform` passes
// `PlatformInterface.verifyToken` through the real constructor's token.
//
// Covers CF-078's 50 MB cap, which had no test before this substep.

import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/core/network/google_drive_service.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/bloc/data_bucket_upload_cubit.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/upload_file_page.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDataBucketRepository extends Mock implements DataBucketRepository {}

class MockGoogleDriveService extends Mock implements GoogleDriveService {}

class MockZoneRepository extends Mock implements ZoneRepository {}

/// A [PlatformFile] whose size and bytes are supplied by the test.
///
/// `PlatformFile` is `abstract base` in `file_picker_platform_interface`, so a
/// fake must `extend` it (it cannot be `implements`-ed or mocked).
base class FakePlatformFile extends PlatformFile {
  FakePlatformFile(
    this._name,
    this._size,
    this._bytes, {
    this.shouldThrowOnRead = false,
  });

  final String _name;
  final int _size;
  final Uint8List _bytes;

  /// When true, [readAsBytes] and [readAsByteStream] fail — exercising the
  /// upload page's read-error path.
  final bool shouldThrowOnRead;

  @override
  String get name => _name;

  @override
  Uri get uri => Uri.file(_name);

  @override
  Future<int> length() async => _size;

  @override
  Future<Uint8List> readAsBytes() async {
    if (shouldThrowOnRead) {
      throw Exception('Gagal membaca file');
    }
    return _bytes;
  }

  @override
  Stream<Uint8List> readAsByteStream() async* {
    if (shouldThrowOnRead) {
      throw Exception('Gagal membaca file');
    }
    yield _bytes;
  }

  // `xFile` is never used by UploadFilePage. Declaring the override as `Never`
  // satisfies the base class without importing `cross_file` (XFile's package),
  // which is not a declared dependency of this app.
  @override
  Never get xFile =>
      throw UnsupportedError('xFile is not used by UploadFilePage');
}

/// Returns [nextFile] from [pickFile] and records the arguments it was given.
class FakeFilePickerPlatform extends FilePickerPlatform {
  /// The file the next [pickFile] call resolves with; `null` = user cancelled.
  PlatformFile? nextFile;

  /// Arguments captured from the most recent [pickFile] call.
  FileType? lastType;
  List<String>? lastAllowedExtensions;
  int pickFileCallCount = 0;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    pickFileCallCount++;
    lastType = type;
    lastAllowedExtensions = allowedExtensions;
    return nextFile;
  }
}

void main() {
  late FakeFilePickerPlatform filePicker;
  late MockDataBucketRepository repository;
  late MockGoogleDriveService driveService;
  late MockZoneRepository zoneRepository;

  const int maxBytes = 50 * 1024 * 1024;

  setUp(() {
    filePicker = FakeFilePickerPlatform();
    FilePickerPlatform.instance = filePicker;
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

  testWidgets('renders an explicit state when Drive is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FTheme(
          data: FTheme.neutral.light.touch,
          child: UploadFilePage(
            repository: repository,
            siteId: 'site-1',
            zoneRepository: zoneRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Integrasi Google Drive belum dikonfigurasi.'),
      findsOneWidget,
    );
    expect(
      find.text('Upload file belum tersedia di lingkungan ini.'),
      findsOneWidget,
    );
    expect(find.byType(DataBucketUploadCubit), findsNothing);
  });

  Future<void> tapPicker(WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih File'));
    await tester.pumpAndSettle();
  }

  testWidgets('Happy path: selects a valid 1MB file', (tester) async {
    filePicker.nextFile = FakePlatformFile(
      'test.shp',
      1024 * 1024,
      Uint8List(10),
    );

    await tapPicker(tester);

    expect(find.text('test.shp'), findsOneWidget);
    expect(find.text('1.0 MB'), findsOneWidget);

    // Single pick (the v11 double-pick workaround is gone) with the screen's
    // 10 allowed geospatial extensions unchanged.
    expect(filePicker.pickFileCallCount, 1);
    expect(filePicker.lastType, FileType.custom);
    expect(filePicker.lastAllowedExtensions, const [
      'shp',
      'tiff',
      'tif',
      'dxf',
      'dwg',
      'csv',
      'kml',
      'kmz',
      'gpx',
      'pdf',
    ]);
  });

  testWidgets('Boundary: accepts file exactly at max size (50MB)', (
    tester,
  ) async {
    filePicker.nextFile = FakePlatformFile(
      'exact.tiff',
      maxBytes,
      Uint8List(10),
    );

    await tapPicker(tester);

    expect(find.text('exact.tiff'), findsOneWidget);
    expect(find.text('File terlalu besar (maks 50 MB).'), findsNothing);
  });

  testWidgets('Boundary: rejects file 1 byte over max size (50MB)', (
    tester,
  ) async {
    filePicker.nextFile = FakePlatformFile(
      'huge.tiff',
      maxBytes + 1,
      Uint8List(0),
    );

    await tapPicker(tester);

    expect(find.text('File terlalu besar (maks 50 MB).'), findsOneWidget);
    expect(find.text('huge.tiff'), findsNothing);
  });

  testWidgets('Cancellation: keeps previous state if picker cancelled', (
    tester,
  ) async {
    filePicker.nextFile = null;

    await tapPicker(tester);

    // Still shows the placeholder, no error surfaced.
    expect(find.text('Pilih File'), findsOneWidget);
    expect(find.textContaining('Gagal'), findsNothing);
  });

  testWidgets('Read failure: shows error if readAsBytes throws', (
    tester,
  ) async {
    filePicker.nextFile = FakePlatformFile(
      'error.shp',
      1024,
      Uint8List(0),
      shouldThrowOnRead: true,
    );

    await tapPicker(tester);

    expect(find.textContaining('Gagal memilih file:'), findsOneWidget);
    expect(find.text('error.shp'), findsNothing);
  });
}
