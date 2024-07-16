import 'dart:html' as html;

import '../../../browser.dart';

class PlatformAttach extends ProxyComponent {
  const PlatformAttach({required this.target, this.attributes, super.key});

  final String target;
  final Map<String, String>? attributes;

  @override
  Element createElement() => AttachElement(this);
}

class AttachElement extends ProxyRenderObjectElement {
  AttachElement(PlatformAttach super.component);

  @override
  RenderObject createRenderObject() {
    var PlatformAttach(:target, :attributes) = component as PlatformAttach;
    return AttachRenderObject(target, depth);
  }

  @override
  void updateRenderObject() {
    var PlatformAttach(:target, :attributes) = component as PlatformAttach;
    (renderObject as AttachRenderObject)
      ..target = target
      ..attributes = attributes;
  }

  @override
  void activate() {
    super.activate();
    (renderObject as AttachRenderObject).depth = depth;
  }

  @override
  void detachRenderObject() {
    super.detachRenderObject();
    final renderObject = this.renderObject as AttachRenderObject;
    AttachAdapter.instanceFor(renderObject._target).unregister(renderObject);
  }
}

class AttachRenderObject extends DomRenderObject {
  AttachRenderObject(this._target, this._depth) {
    node = html.Text('');
    AttachAdapter.instanceFor(_target).register(this);
  }

  String _target;
  set target(String target) {
    if (_target == target) return;
    AttachAdapter.instanceFor(_target).unregister(this);
    _target = target;
    AttachAdapter.instanceFor(_target).register(this);
    AttachAdapter.instanceFor(_target).update();
  }

  Map<String, String>? _attributes;
  set attributes(Map<String, String>? attrs) {
    if (_attributes == attrs) return;
    _attributes = attrs;
    AttachAdapter.instanceFor(_target).update();
  }

  int _depth;
  set depth(int depth) {
    if (_depth == depth) return;
    _depth = depth;
    AttachAdapter.instanceFor(_target)._needsResorting = true;
    AttachAdapter.instanceFor(_target).update();
  }
}

class AttachAdapter {
  static AttachAdapter instanceFor(String target) {
    return _instances[target] ??= AttachAdapter(target);
  }

  static final Map<String, AttachAdapter> _instances = {};

  AttachAdapter(this.target);

  final String target;

  late final html.Element? element = html.querySelector(target);

  late final Map<String, String> initialAttributes = {...?element?.attributes};

  final List<AttachRenderObject> _attachRenderObjects = [];
  bool _needsResorting = true;

  void update() {
    if (_needsResorting) {
      _attachRenderObjects.sort((a, b) => a._depth - b._depth);
      _needsResorting = false;
    }

    Map<String, String> attributes = initialAttributes;

    for (var renderObject in _attachRenderObjects) {
      assert(renderObject._target == target);
      if (renderObject._attributes case final attrs?) {
        attributes.addAll(attrs);
      }
    }

    element?.attributes.clear();
    element?.attributes.addAll(attributes);
  }

  void register(AttachRenderObject renderObject) {
    _attachRenderObjects.add(renderObject);
    _needsResorting = true;
  }

  void unregister(AttachRenderObject renderObject) {
    _attachRenderObjects.remove(renderObject);
    update();
  }
}
