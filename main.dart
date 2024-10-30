import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e, isDragged) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: isDragged ? 60 : 48, // Increase height when dragged
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                  boxShadow: [
                    if (isDragged)
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4), // Shadow for pop-out effect
                      ),
                  ],
                ),
                child: Center(
                  child: Transform.scale(
                    scale: isDragged ? 1.2 : 1.0, // Scale up when dragged
                    child: Icon(e, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  final List<T> items;
  final Widget Function(T, bool isDragged) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T extends Object> extends State<Dock<T>> {
  late final List<T> _items = widget.items.toList();
  T? _draggedItem;
  Offset? _dragPosition;
  final GlobalKey _dockKey = GlobalKey();
  Rect? _dockRect;
  int? _targetIndex;

  double _getAdjustedSpacing(int index) {
    const double baseSpacing = 8.0;
    const double expandedSpacing = 48.0;

    if (_draggedItem != null) {
      if (_targetIndex == index) {
        return expandedSpacing; // Give extra space to dragged icon
      }
      // Reduce space for icons directly next to the dragged icon
      if (_targetIndex == index - 1 || _targetIndex == index + 1) {
        return baseSpacing / 2; // Reduce to half base spacing for adjacent icons
      }
    }

    return baseSpacing;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box = _dockKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        _dockRect = box.localToGlobal(Offset.zero) & box.size;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _dockKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.2),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _items.length; i++)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300), // Longer duration for smooth movement
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: Draggable<T>(
                key: ValueKey(_items[i]),
                data: _items[i],
                feedback: Material(
                  color: Colors.transparent,
                  child: widget.builder(_items[i], true), // true for dragged item
                ),
                childWhenDragging: const SizedBox.shrink(),
                onDragStarted: () {
                  setState(() {
                    _draggedItem = _items[i];
                    _targetIndex = i;
                  });
                },
                onDragEnd: (details) {
                  setState(() {
                    if (_targetIndex != null) {
                      final draggedIndex = _items.indexOf(_draggedItem!);
                      if (draggedIndex != _targetIndex) {
                        final draggedItem = _items.removeAt(draggedIndex);
                        _items.insert(_targetIndex!, draggedItem);
                      }
                    }
                    _draggedItem = null;
                    _dragPosition = null;
                    _targetIndex = null;
                  });
                },
                onDragUpdate: (details) {
                  setState(() {
                    _dragPosition = details.globalPosition;

                    // Calculate nearest target index based on the drag position
                    if (_dockRect != null) {
                      final double x = _dragPosition!.dx - _dockRect!.left;
                      final int newTargetIndex = (x / (_dockRect!.width / _items.length))
                          .clamp(0, _items.length - 1)
                          .toInt();
                      if (_targetIndex != newTargetIndex) {
                        _targetIndex = newTargetIndex;
                      }
                    }
                  });
                },
                child: DragTarget<T>(
                  onWillAccept: (receivedItem) => receivedItem != _items[i],
                  onAccept: (receivedItem) {
                    setState(() {
                      final oldIndex = _items.indexOf(receivedItem);
                      final newIndex = i;
                      _items.removeAt(oldIndex);
                      _items.insert(newIndex, receivedItem);
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.only(
                        left: 8.0,
                        right: _getAdjustedSpacing(i), // Adjusted right spacing
                      ),
                      child: widget.builder(_items[i], false), // false for non-dragged items
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
