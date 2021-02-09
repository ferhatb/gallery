// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';

typedef LibraryLoader = Future<void> Function();
typedef DeferredWidgetBuilder = Widget Function();

/// Wraps the child inside a deferred module loader.
///
/// The child is created and a single instance of the Widget is maintained in
/// state as long as closure to create widget stays the same.
///
class DeferredWidget extends StatefulWidget {
  DeferredWidget(this.libraryLoader, this.createWidget, {Key key})
      : super(key: key);

  final LibraryLoader libraryLoader;
  final DeferredWidgetBuilder createWidget;
  static final Map<LibraryLoader, Future<void>> _moduleLoaders = {};

  static Future<void> preload(LibraryLoader loader) {
    if (!_moduleLoaders.containsKey(loader)) {
      _moduleLoaders[loader] = loader();
    }
    return _moduleLoaders[loader];
  }

  @override
  _DeferredWidgetState createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  _DeferredWidgetState();
  Widget _loadedChild;
  DeferredWidgetBuilder _loadedCreator;

  @override
  void initState() {
    DeferredWidget.preload(widget.libraryLoader)
        .then((dynamic _) => _onLibraryLoaded());
    super.initState();
  }

  void _onLibraryLoaded() {
    setState(() {
      _loadedCreator = widget.createWidget;
      _loadedChild = _loadedCreator();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadedCreator != widget.createWidget &&
        _loadedCreator != null) {
      _loadedCreator = widget.createWidget;
      _loadedChild = _loadedCreator();
    }
    return _loadedChild ?? Container();
  }
}
