import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
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
  final Uri? routeUri;
  final VoidCallback? onClose;

  const FileDetailRoute({
    super.key,
    required this.file,
    required this.fileId,
    required this.repository,
    this.routeUri,
    this.onClose,
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
        : Future.sync(() => widget.repository.getFile(widget.fileId ?? ''));
  }

  void _handleClose(BuildContext context) {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.dataBucket);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeIdentity =
        widget.routeUri?.toString() ??
        '/tools/data-bucket/${widget.fileId ?? ""}';

    return FutureBuilder<GeospatialFile?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Detail File',
            mode: AppResponsiveSheetMode.readOnlyInspector,
            onDismissApproved: () => _handleClose(context),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: FCircularProgress(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Detail File',
            mode: AppResponsiveSheetMode.readOnlyInspector,
            onDismissApproved: () => _handleClose(context),
            footer: SizedBox(
              width: double.infinity,
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: () => _handleClose(context),
                child: const Text('Kembali'),
              ),
            ),
            body: AppStatePanel(
              title: 'Gagal Memuat File',
              message: snapshot.error.toString(),
              actionLabel: 'Kembali',
              onAction: () => _handleClose(context),
            ),
          );
        }

        final file = snapshot.data;
        if (file == null) {
          final l10n = Localizations.of<AppLocalizations>(
            context,
            AppLocalizations,
          );
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Detail File',
            mode: AppResponsiveSheetMode.readOnlyInspector,
            onDismissApproved: () => _handleClose(context),
            footer: SizedBox(
              width: double.infinity,
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: () => _handleClose(context),
                child: const Text('Kembali'),
              ),
            ),
            body: AppStatePanel(
              title: 'File Tidak Ditemukan',
              message:
                  l10n?.fileDetailNotFound ??
                  'File yang Anda cari tidak ditemukan atau telah dihapus.',
              actionLabel: 'Kembali',
              onAction: () => _handleClose(context),
            ),
          );
        }

        return FileDetailPage(
          file: file,
          repository: widget.repository,
          routeUri: widget.routeUri,
          onClose: widget.onClose,
        );
      },
    );
  }
}
