import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/config/theme.dart';

class AsyncData<T> {
  final T? data;
  final Object? error;
  final bool isLoading;
  const AsyncData({this.data, this.error, this.isLoading = false});
  factory AsyncData.loading() => AsyncData(isLoading: true);
  factory AsyncData.data(T data) => AsyncData(data: data);
  factory AsyncData.error(Object error) => AsyncData(error: error);
  bool get hasData => data != null;
  bool get hasError => error != null;
}

class AsyncController<T> extends ChangeNotifier {
  AsyncData<T> _state = AsyncData.loading();
  AsyncData<T> get state => _state;
  AsyncController({Future<T>? future}) {
    if (future != null) {
      loadData(future);
    }
  }
  void loadData(Future<T> future) {
    _state = AsyncData.loading();
    notifyListeners();
    future
        .then((data) {
          _state = AsyncData.data(data);
          notifyListeners();
        })
        .catchError((error) {
          _state = AsyncData.error(error);
          notifyListeners();
        });
  }

  void reload(Future<T> Function() dataLoader) {
    loadData(dataLoader());
  }

  void setData(T data) {
    _state = AsyncData.data(data);
    notifyListeners();
  }

  void setError(Object error) {
    _state = AsyncData.error(error);
    notifyListeners();
  }
}

class Async<T extends dynamic> extends StatefulWidget {
  final Widget Function(BuildContext context, T data) builder;
  final dynamic errorBuilder;
  final dynamic loadingBuilder;
  final Future<T> Function() wait;
  final Widget? emptyBuilder;
  final bool autoLoad;
  final AsyncController<T>? controller;
  final void Function(T data)? onData;
  final void Function(Object error)? onError;
  const Async({
    super.key,
    required this.builder,
    required this.wait,
    this.errorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.autoLoad = true,
    this.controller,
    this.onData,
    this.onError,
  });
  @override
  State<Async<T>> createState() => _AsyncState<T>();
}

class _AsyncState<T> extends State<Async<T>> {
  late AsyncController<T> _controller;
  bool _isControllerInternal = false;
  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = AsyncController<T>();
      _isControllerInternal = true;
    }
    if (widget.autoLoad) {
      _loadData();
    }
    _controller.addListener(_handleStateChange);
  }

  void _handleStateChange() {
    if (_controller.state.hasData && widget.onData != null) {
      widget.onData!(_controller.state.data as T);
    }
    if (_controller.state.hasError && widget.onError != null) {
      widget.onError!(_controller.state.error!);
    }
  }

  void _loadData() {
    try {
      final future = widget.wait();
      _controller.loadData(future);
    } catch (e) {
      _controller.setError(e);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleStateChange);
    if (_isControllerInternal) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        if (state.isLoading) {
          if (widget.loadingBuilder is Widget) {
            return widget.loadingBuilder as Widget;
          } else if (widget.loadingBuilder is Function) {
            return widget.loadingBuilder(context);
          }
          return const Center(child: CircularProgressIndicator());
        }
        if (state.hasError) {
          if (widget.errorBuilder is Widget) {
            return widget.errorBuilder as Widget;
          } else if (widget.errorBuilder is Function) {
            return widget.errorBuilder(context, state.error);
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.circleAlert, color: AppColors.errorColor, size: 48),
                const SizedBox(height: 16),
                Text(
                  state.error.toString(),
                  style: const TextStyle(color: AppColors.errorColor),
                  textAlign: TextAlign.center,
                ),

                Text(
                  state.toString(),
                  style: const TextStyle(color: AppColors.errorColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(AppColors.errorColor),
                  ),
                  onPressed: _loadData,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        if (!state.hasData) {
          return widget.emptyBuilder ?? const Center(child: Text('No hay datos'));
        }
        return widget.builder(context, state.data as T);
      },
    );
  }
}

class AsyncList<T> extends StatelessWidget {
  final Future<List<T>> Function() wait;
  final Widget Function(BuildContext context, T item, int index) builder;
  final dynamic loadingBuilder;
  final dynamic errorBuilder;
  final Widget? emptyBuilder;
  final AsyncController<List<T>>? controller;
  final bool autoLoad;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final void Function(List<T> data)? onData;
  final void Function(Object error)? onError;
  const AsyncList({
    super.key,
    required this.wait,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.controller,
    this.autoLoad = true,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.onData,
    this.onError,
  });
  @override
  Widget build(BuildContext context) {
    return Async<List<T>>(
      wait: wait,
      controller: controller,
      autoLoad: autoLoad,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      onData: onData,
      onError: onError,
      emptyBuilder: emptyBuilder ?? const Center(child: Text('No hay elementos')),
      builder: (context, data) {
        if (data.isEmpty && emptyBuilder != null) {
          return emptyBuilder!;
        }
        return ListView.builder(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: data.length,
          itemBuilder: (context, index) => builder(context, data[index], index),
        );
      },
    );
  }
}

class SearchableAsyncList<T> extends StatefulWidget {
  final Future<List<T>> Function() wait;
  final Widget Function(BuildContext context, T item, int index) builder;
  final dynamic loadingBuilder;
  final dynamic errorBuilder;
  final Widget? emptyBuilder;
  final AsyncController<List<T>>? controller;
  final bool autoLoad;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final void Function(List<T> data)? onData;
  final void Function(Object error)? onError;

  final bool enablePullToRefresh;
  final Color? refreshIndicatorColor;
  final Duration refreshIndicatorTriggerMode;

  final bool enableSearch;
  final String? searchHint;
  final Widget? searchIcon;
  final Widget? clearSearchIcon;
  final EdgeInsetsGeometry? searchPadding;
  final TextStyle? searchTextStyle;
  final InputDecoration? searchDecoration;
  final Duration searchDebounceTime;

  final bool Function(String query, T item)? searchFilter;

  const SearchableAsyncList({
    super.key,
    required this.wait,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.controller,
    this.autoLoad = true,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.onData,
    this.onError,

    this.enablePullToRefresh = false,
    this.refreshIndicatorColor,
    this.refreshIndicatorTriggerMode = const Duration(milliseconds: 200),

    this.enableSearch = false,
    this.searchHint = 'Buscar...',
    this.searchIcon,
    this.clearSearchIcon,
    this.searchPadding = const EdgeInsets.symmetric(vertical: 8.0),
    this.searchTextStyle,
    this.searchDecoration,
    this.searchDebounceTime = const Duration(milliseconds: 300),
    this.searchFilter,
  });

  @override
  State<SearchableAsyncList<T>> createState() => _SearchableAsyncListState<T>();
}

class _SearchableAsyncListState<T> extends State<SearchableAsyncList<T>> {
  late AsyncController<List<T>> _controller;
  bool _isControllerInternal = false;
  List<T> _filteredData = [];
  String _searchQuery = '';
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = AsyncController<List<T>>();
      _isControllerInternal = true;
    }

    _controller.addListener(_handleDataChange);

    if (widget.autoLoad) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    if (_isControllerInternal) {
      _controller.dispose();
    }
    _controller.removeListener(_handleDataChange);
    super.dispose();
  }

  void _handleDataChange() {
    if (_controller.state.hasData) {
      _applySearch();
      if (widget.onData != null) {
        widget.onData!(_controller.state.data as List<T>);
      }
    }
    if (_controller.state.hasError && widget.onError != null) {
      widget.onError!(_controller.state.error!);
    }
  }

  Future<void> _loadData() async {
    try {
      final future = widget.wait();
      _controller.loadData(future);
    } catch (e) {
      _controller.setError(e);
    }
  }

  Future<void> _refreshData() async {
    return _loadData();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.searchDebounceTime, () {
      setState(() {
        _searchQuery = query;
        _applySearch();
      });
    });
  }

  void _applySearch() {
    if (!_controller.state.hasData) return;

    final data = _controller.state.data as List<T>;

    if (_searchQuery.isEmpty) {
      _filteredData = List.from(data);
      return;
    }

    if (widget.searchFilter != null) {
      _filteredData = data.where((item) => widget.searchFilter!(_searchQuery, item)).toList();
    } else {
      _filteredData =
          data
              .where((item) => item.toString().toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _applySearch();
    });
  }

  Widget _buildSearchBar() {
    if (!widget.enableSearch) return const SizedBox.shrink();

    return Padding(
      padding: widget.searchPadding ?? const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        style: widget.searchTextStyle,
        decoration:
            widget.searchDecoration ??
            InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: widget.searchIcon ?? const Icon(LucideIcons.search),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? GestureDetector(
                        onTap: _clearSearch,
                        child: widget.clearSearchIcon ?? const Icon(LucideIcons.x),
                      )
                      : null,
            ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildList(List<T> data) {
    return ListView.builder(
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,

      itemCount: data.isEmpty ? 1 : data.length,
      itemBuilder: (context, index) {
        if (data.isEmpty) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child:
                  widget.emptyBuilder ??
                  const Padding(padding: EdgeInsets.all(16.0), child: Text('No hay elementos')),
            ),
          );
        }
        return widget.builder(context, data[index], index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        if (state.isLoading) {
          if (widget.loadingBuilder is Widget) {
            return widget.loadingBuilder as Widget;
          } else if (widget.loadingBuilder is Function) {
            return widget.loadingBuilder(context);
          }
          return const Center(child: CircularProgressIndicator());
        }

        if (state.hasError) {
          if (widget.errorBuilder is Widget) {
            return widget.errorBuilder as Widget;
          } else if (widget.errorBuilder is Function) {
            return widget.errorBuilder(context, state.error);
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.circleAlert, color: AppColors.errorColor, size: 48),
                const SizedBox(height: 16),
                Text(
                  state.error.toString(),
                  style: const TextStyle(color: AppColors.errorColor),
                  textAlign: TextAlign.center,
                ),
                Text(
                  state.toString(),
                  style: const TextStyle(color: AppColors.errorColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(AppColors.errorColor),
                  ),
                  onPressed: _loadData,

                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (!state.hasData) {
          final emptyContent = widget.emptyBuilder ?? const Center(child: Text('No hay datos'));

          if (widget.enablePullToRefresh) {
            final scrollableEmpty = ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(child: emptyContent),
                ),
              ],
            );

            return RefreshIndicator(
              color: widget.refreshIndicatorColor,
              onRefresh: _refreshData,
              child: scrollableEmpty,
            );
          }

          return Center(child: emptyContent);
        }

        if (_filteredData.isEmpty && _searchQuery.isEmpty) {
          _applySearch();
        }

        final content = Column(
          children: [_buildSearchBar(), Expanded(child: _buildList(_filteredData))],
        );

        if (widget.enablePullToRefresh) {
          return RefreshIndicator(
            color: widget.refreshIndicatorColor,
            onRefresh: _refreshData,
            child: content,
          );
        }

        return content;
      },
    );
  }
}

extension RefreshableAsyncController<T> on AsyncController<T> {
  Future<void> refresh(Future<T> Function() dataLoader) async {
    reload(dataLoader);
  }

  void filter<E>(List<E> originalList, bool Function(E item) filterFn) {
    if (state.hasData && state.data is List<E>) {
      final filtered = originalList.where(filterFn).toList();
      setData(filtered as T);
    }
  }
}
