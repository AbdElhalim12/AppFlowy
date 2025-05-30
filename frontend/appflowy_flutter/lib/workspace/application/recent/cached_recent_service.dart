import 'dart:async';

import 'package:appflowy/shared/list_extension.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/recent/recent_listener.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

/// This is a lazy-singleton to share recent views across the application.
///
/// Use-cases:
/// - Desktop: Command Palette recent view history
/// - Desktop: (Documents) Inline-page reference recent view history
/// - Mobile: Recent view history on home screen
///
/// See the related [LaunchTask] in [RecentServiceTask].
///
class CachedRecentService {
  CachedRecentService();

  Completer<void> _completer = Completer();

  ValueNotifier<List<SectionViewPB>> notifier = ValueNotifier(const []);

  List<SectionViewPB> get _recentViews => notifier.value;
  set _recentViews(List<SectionViewPB> value) => notifier.value = value;

  final _listener = RecentViewsListener();

  bool isDisposed = false;

  Future<List<SectionViewPB>> recentViews() async {
    if (_isInitialized || _completer.isCompleted) return _recentViews;

    _isInitialized = true;

    _listener.start(recentViewsUpdated: _recentViewsUpdated);
    _recentViews = await _readRecentViews().fold(
      (s) => s.items.unique((e) => e.item.id),
      (_) => [],
    );
    _completer.complete();

    return _recentViews;
  }

  /// Updates the recent views history
  Future<FlowyResult<void, FlowyError>> updateRecentViews(
    List<String> viewIds,
    bool addInRecent,
  ) async {
    final List<String> duplicatedViewIds = [];
    for (final viewId in viewIds) {
      for (final view in _recentViews) {
        if (view.item.id == viewId) {
          duplicatedViewIds.add(viewId);
        }
      }
    }
    return FolderEventUpdateRecentViews(
      UpdateRecentViewPayloadPB(
        viewIds: addInRecent ? viewIds : duplicatedViewIds,
        addInRecent: addInRecent,
      ),
    ).send();
  }

  Future<FlowyResult<RepeatedRecentViewPB, FlowyError>>
      _readRecentViews() async {
    final payload = ReadRecentViewsPB(start: Int64(), limit: Int64(100));
    final result = await FolderEventReadRecentViews(payload).send();
    return result.fold(
      (recentViews) {
        return FlowyResult.success(
          RepeatedRecentViewPB(
            // filter the space view and the orphan view
            items: recentViews.items.where(
              (e) => !e.item.isSpace && e.item.id != e.item.parentViewId,
            ),
          ),
        );
      },
      (error) => FlowyResult.failure(error),
    );
  }

  bool _isInitialized = false;

  Future<void> reset() async {
    await _listener.stop();
    _resetCompleter();
    _isInitialized = false;
    _recentViews = const [];
  }

  Future<void> dispose() async {
    if (isDisposed) return;

    isDisposed = true;
    notifier.dispose();
    await _listener.stop();
  }

  void _recentViewsUpdated(
    FlowyResult<RepeatedViewIdPB, FlowyError> result,
  ) async {
    final viewIds = result.toNullable();
    if (viewIds != null) {
      _recentViews = await _readRecentViews().fold(
        (s) => s.items.unique((e) => e.item.id),
        (_) => [],
      );
    }
  }

  void _resetCompleter() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
    _completer = Completer<void>();
  }
}
