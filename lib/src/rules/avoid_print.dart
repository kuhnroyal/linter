// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'Avoid `print` calls in production code.';

const _details = r'''
**DO** avoid `print` calls in production code.

**BAD:**
```dart
void f(int x) {
  print('debug: $x');
  ...
}
```
''';

class AvoidPrint extends LintRule {
  AvoidPrint()
      : super(
            name: 'avoid_print',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    bool isDartCore(MethodInvocation node) =>
        node.methodName.staticElement?.library?.name == 'dart.core';

    if (node.methodName.name == 'print' &&
        isDartCore(node) &&
        !_isDebugOnly(node)) {
      rule.reportLint(node.methodName);
    }

    node.argumentList.arguments.forEach(_validateArgument);
  }

  bool _isDebugOnly(Expression expression) {
    AstNode? node = expression;
    while (node != null) {
      var parent = node.parent;
      if (parent is IfStatement && node == parent.thenStatement) {
        var condition = parent.condition;
        if (condition is SimpleIdentifier &&
            isKDebugMode(condition.staticElement)) {
          return true;
        }
      } else if (parent is FunctionBody) {
        return false;
      }
      node = parent;
    }
    return false;
  }

  void _validateArgument(Expression expression) {
    if (expression is SimpleIdentifier) {
      var element = expression.staticElement;
      if (element is FunctionElement &&
          element.name == 'print' &&
          element.library.isDartCore) {
        rule.reportLint(expression);
      }
    }
  }
}
