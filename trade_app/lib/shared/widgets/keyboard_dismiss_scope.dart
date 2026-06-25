import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trade_app/core/theme/app_colors.dart';
import 'package:trade_app/core/theme/app_text_styles.dart';

class KeyboardDismissScope extends StatelessWidget {
  final Widget child;

  const KeyboardDismissScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
            const _IosKeyboardDoneToolbar(),
        ],
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    final focusedNode = FocusManager.instance.primaryFocus;
    if (focusedNode == null || !focusedNode.hasFocus) return;
    if (_isInsideFocusedWidget(focusedNode, event.position)) return;

    focusedNode.unfocus();
  }

  bool _isInsideFocusedWidget(FocusNode focusedNode, Offset globalPosition) {
    final focusedContext = focusedNode.context;
    if (focusedContext == null) return false;

    final renderObject = focusedContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;

    final topLeft = renderObject.localToGlobal(Offset.zero);
    return (topLeft & renderObject.size).contains(globalPosition);
  }
}

class HideIosKeyboardDoneToolbar extends StatelessWidget {
  final Widget child;

  const HideIosKeyboardDoneToolbar({super.key, required this.child});

  static bool isActiveForFocusedInput() {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) return false;
    return focusedContext
            .getElementForInheritedWidgetOfExactType<
              _HideIosKeyboardDoneToolbarScope
            >() !=
        null;
  }

  @override
  Widget build(BuildContext context) {
    return _HideIosKeyboardDoneToolbarScope(child: child);
  }
}

class _HideIosKeyboardDoneToolbarScope extends InheritedWidget {
  const _HideIosKeyboardDoneToolbarScope({required super.child});

  @override
  bool updateShouldNotify(_HideIosKeyboardDoneToolbarScope oldWidget) => false;
}

class _IosKeyboardDoneToolbar extends StatelessWidget {
  const _IosKeyboardDoneToolbar();

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardInset <= 0) return const SizedBox.shrink();
    if (HideIosKeyboardDoneToolbar.isActiveForFocusedInput()) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: keyboardInset,
      child: Material(
        color: AppColors.dashboardSurfaceElevated,
        elevation: 4,
        surfaceTintColor: AppColors.transparent,
        child: SizedBox(
          height: 44,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextButton(
                onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Text(
                  'Done',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
