import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/file_detail_page.dart';

/// Route wrapper for the data-bucket `:id` route (CF-031).
///
/// When [file] is null (deep link / reload / bookmark — `extra` is gone), it
/// fetches the file by [fileId] from [repository] instead of dead-ending on the
/// missing in-memory object. The `extra`-supplied file remains the fast path.
class FileDetailRoute extends StatefulWidget {
  final GeospatialFile? file;
  final String? fileId;
  final DataBucketRepository repository;

  const FileDetailRoute({
    super.key,
    required this.file,
    required this.fileId,
    required this.repository,
  });

  @override
  State<FileDetailRoute> createState() => _FileDetailRouteState();
}

class _FileDetailRouteState extends State<FileDetailRoute> {
  late final Future<GeospatialFile?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.file != null
        ? Future.value(widget.file)
        : widget.repository.getFile(widget.fileId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FutureBuilder<GeospatialFile?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final file = snapshot.data;
        if (file == null) {
          return Scaffold(
            body: Center(
              child: Text(
                'File tidak ditemukan.',
                style: theme.typography.body.md.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          );
        }

        return FileDetailPage(file: file, repository: widget.repository);
      },
    );
  }
}
