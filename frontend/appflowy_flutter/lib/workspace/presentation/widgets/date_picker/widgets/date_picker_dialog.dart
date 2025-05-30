import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker_base.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/desktop_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/date_time_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/user_time_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Provides arguemnts for [AppFlowyDatePicker] when showing
/// a [DatePickerMenu]
///
class DatePickerOptions {
  DatePickerOptions({
    DateTime? focusedDay,
    this.selectedDay,
    this.includeTime = false,
    this.isRange = false,
    this.dateFormat = UserDateFormatPB.Friendly,
    this.timeFormat = UserTimeFormatPB.TwentyFourHour,
    this.selectedReminderOption,
    this.onDaySelected,
    this.onRangeSelected,
    this.onIncludeTimeChanged,
    this.onIsRangeChanged,
    this.onReminderSelected,
  }) : focusedDay = focusedDay ?? DateTime.now();

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final bool includeTime;
  final bool isRange;
  final UserDateFormatPB dateFormat;
  final UserTimeFormatPB timeFormat;
  final ReminderOption? selectedReminderOption;

  final DaySelectedCallback? onDaySelected;
  final RangeSelectedCallback? onRangeSelected;
  final IncludeTimeChangedCallback? onIncludeTimeChanged;
  final IsRangeChangedCallback? onIsRangeChanged;
  final OnReminderSelected? onReminderSelected;

  DatePickerOptions copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    bool? includeTime,
    bool? isRange,
    UserDateFormatPB? dateFormat,
    UserTimeFormatPB? timeFormat,
    ReminderOption? selectedReminderOption,
    DaySelectedCallback? onDaySelected,
    RangeSelectedCallback? onRangeSelected,
    IncludeTimeChangedCallback? onIncludeTimeChanged,
    IsRangeChangedCallback? onIsRangeChanged,
    OnReminderSelected? onReminderSelected,
  }) {
    return DatePickerOptions(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      includeTime: includeTime ?? this.includeTime,
      isRange: isRange ?? this.isRange,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      selectedReminderOption:
          selectedReminderOption ?? this.selectedReminderOption,
      onDaySelected: onDaySelected ?? this.onDaySelected,
      onRangeSelected: onRangeSelected ?? this.onRangeSelected,
      onIncludeTimeChanged: onIncludeTimeChanged ?? this.onIncludeTimeChanged,
      onIsRangeChanged: onIsRangeChanged ?? this.onIsRangeChanged,
      onReminderSelected: onReminderSelected ?? this.onReminderSelected,
    );
  }
}

abstract class DatePickerService {
  void show(Offset offset, {required DatePickerOptions options});

  void dismiss();
}

const double _datePickerWidth = 260;
const double _datePickerHeight = 404;
const double _ySpacing = 15;

class DatePickerMenu extends DatePickerService {
  DatePickerMenu({required this.context, required this.editorState});

  final BuildContext context;
  final EditorState editorState;
  PopoverMutex? popoverMutex;

  OverlayEntry? _menuEntry;

  @override
  void dismiss() {
    _menuEntry?.remove();
    _menuEntry = null;
    popoverMutex?.close();
    popoverMutex?.dispose();
    popoverMutex = null;
  }

  @override
  void show(Offset offset, {required DatePickerOptions options}) =>
      _show(offset, options: options);

  void _show(Offset offset, {required DatePickerOptions options}) {
    dismiss();

    final editorSize = editorState.renderBox!.size;

    double offsetX = offset.dx;
    double offsetY = offset.dy;

    final showRight = (offset.dx + _datePickerWidth) < editorSize.width;
    if (!showRight) {
      offsetX = offset.dx - _datePickerWidth;
    }

    final showBelow = (offset.dy + _datePickerHeight) < editorSize.height;
    if (!showBelow) {
      if ((offset.dy - _datePickerHeight) < 0) {
        // Show dialog in the middle
        offsetY = offset.dy - (_datePickerHeight / 3);
      } else {
        // Show above
        offsetY = offset.dy - _datePickerHeight;
      }
    }

    popoverMutex = PopoverMutex();
    _menuEntry = OverlayEntry(
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: SizedBox(
          height: editorSize.height,
          width: editorSize.width,
          child: KeyboardListener(
            focusNode: FocusNode()..requestFocus(),
            onKeyEvent: (event) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                dismiss();
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: dismiss,
              child: Stack(
                children: [
                  _AnimatedDatePicker(
                    offset: Offset(offsetX, offsetY),
                    showBelow: showBelow,
                    options: options,
                    popoverMutex: popoverMutex,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_menuEntry!);
  }
}

class _AnimatedDatePicker extends StatefulWidget {
  const _AnimatedDatePicker({
    required this.offset,
    required this.showBelow,
    required this.options,
    this.popoverMutex,
  });

  final Offset offset;
  final bool showBelow;
  final DatePickerOptions options;
  final PopoverMutex? popoverMutex;

  @override
  State<_AnimatedDatePicker> createState() => _AnimatedDatePickerState();
}

class _AnimatedDatePickerState extends State<_AnimatedDatePicker> {
  late DatePickerOptions options = widget.options;

  @override
  Widget build(BuildContext context) {
    final dy = widget.offset.dy + (widget.showBelow ? _ySpacing : -_ySpacing);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: dy,
      left: widget.offset.dx,
      child: Container(
        decoration: FlowyDecoration.decoration(
          Theme.of(context).cardColor,
          Theme.of(context).colorScheme.shadow,
        ),
        constraints: BoxConstraints.loose(const Size(_datePickerWidth, 465)),
        child: DesktopAppFlowyDatePicker(
          includeTime: options.includeTime,
          isRange: options.isRange,
          dateFormat: options.dateFormat.simplified,
          timeFormat: options.timeFormat.simplified,
          dateTime: options.selectedDay,
          popoverMutex: widget.popoverMutex,
          reminderOption: options.selectedReminderOption ?? ReminderOption.none,
          onDaySelected: options.onDaySelected == null
              ? null
              : (d) {
                  options.onDaySelected?.call(d);
                  setState(() {
                    options = options.copyWith(selectedDay: d);
                  });
                },
          onIsRangeChanged: options.onIsRangeChanged == null
              ? null
              : (isRange, s, e) {
                  options.onIsRangeChanged?.call(isRange, s, e);
                },
          onIncludeTimeChanged: options.onIncludeTimeChanged == null
              ? null
              : (include, s, e) {
                  options.onIncludeTimeChanged?.call(include, s, e);
                  setState(() {
                    options =
                        options.copyWith(includeTime: include, selectedDay: s);
                  });
                },
          onRangeSelected: options.onRangeSelected == null
              ? null
              : (s, e) {
                  options.onRangeSelected?.call(s, e);
                },
          onReminderSelected: options.onReminderSelected == null
              ? null
              : (o) {
                  options.onReminderSelected?.call(o);
                  setState(() {
                    options = options.copyWith(selectedReminderOption: o);
                  });
                },
        ),
      ),
    );
  }
}
