import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items] mimicking macOS dock behavior.
class Dock<T> extends StatefulWidget {
  const Dock({super.key, this.items = const [], required this.builder});

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder creating a widget from the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items] and manage animations.
class _DockState<T> extends State<Dock<T>> {
  /// Items being manipulated in the dock.
  late final List<T> _items = widget.items.toList();

  /// Whether an item is currently being dragged.
  bool _isDragging = false;

  /// Index of the item currently being dragged.
  int? _draggedIndex;

  /// Index of the item currently being hovered over.
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(mainAxisSize: MainAxisSize.min, children: _buildDockItems()),
    );
  }

  /// Builds the list of dock items with drag and animation capabilities.
  List<Widget> _buildDockItems() {
    final List<Widget> dockItems = [];

    for (int i = 0; i < _items.length; i++) {
      if (_isDragging && i == _draggedIndex) continue;
      final scale = _getScaleForIndex(i);
      dockItems.add(_buildDraggableItem(_items[i], i, scale));
    }

    return dockItems;
  }

  /// Calculates the zoom scale based on proximity to hovered index.
  double _getScaleForIndex(int index) {
    if (_hoveredIndex == null) return 1.0;
    final distance = (index - _hoveredIndex!).abs();

    if (distance == -1) return 1.1;
    if (distance == 0) return 1.2;
    if (distance == 1) return 1.1;
    return 1.0;
  }

  /// Builds a draggable item with hover-based magnification animation.
  Widget _buildDraggableItem(T item, int index, double scale) {
    Widget itemWidget = widget.builder(item);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Draggable<int>(
        data: index,
        feedback: Material(
          color: Colors.transparent,
          child: widget.builder(item),
        ),
        onDragStarted: () {
          setState(() {
            _isDragging = true;
            _draggedIndex = index;
          });
        },
        onDragEnd: (_) {
          setState(() {
            _isDragging = false;
            _draggedIndex = null;
          });
        },
        child: DragTarget<int>(
          onWillAccept: (data) => data != null && data != index,
          onAccept: (oldIndex) {
            setState(() {
              final item = _items.removeAt(oldIndex);
              final insertIndex = index > oldIndex ? index - 1 : index;
              _items.insert(insertIndex, item);
            });
          },
          builder: (context, candidateData, rejectedData) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.identity()..scale(scale),
              transformAlignment: Alignment.bottomCenter,
              child: itemWidget,
            );
          },
        ),
      ),
    );
  }
}
