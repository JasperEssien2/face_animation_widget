import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData.light()
          .copyWith(scaffoldBackgroundColor: Colors.amber[100]),
      home: const Scaffold(
        body: Center(
          child: FaceAnimationWidget(),
        ),
      ),
    );
  }
}

class FaceAnimationWidget extends LeafRenderObjectWidget {
  const FaceAnimationWidget({Key? key}) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderFaceAnimationWidget();
  }
}

class _RenderFaceAnimationWidget extends RenderBox
    with SizesHelper, _AnimTickerProvider {
  _RenderFaceAnimationWidget() {
    dragGestureRecognizer = PanGestureRecognizer()..onUpdate = _dragUpdate;
    tapGestureRecognizer = TapGestureRecognizer()..onTapDown = _tapDown;

    _leftEyelidAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _leftEyeLidAnimController, curve: Curves.decelerate))
      ..addListener(_animationListener)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _leftEyeLidAnimController.reverse();
        }
      });

    _rightEyelidAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _rightEyeLidAnimController, curve: Curves.decelerate))
      ..addListener(_animationListener)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _rightEyeLidAnimController.reverse();
        }
      });
  }

  Path _sliderPath = Path();
  Path _leftEyeClickablePath = Path();
  Path _rightEyeClickablePath = Path();

  late Offset _sliderOffset;
  late final DragGestureRecognizer dragGestureRecognizer;
  late final TapGestureRecognizer tapGestureRecognizer;

  var _sliderDirection = 0.0;

  late final AnimationController _leftEyeLidAnimController =
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));

  late final Animation _leftEyelidAnimation;
  late final AnimationController _rightEyeLidAnimController =
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));

  late final Animation _rightEyelidAnimation;

  void _animationListener() => markNeedsPaint();

  @override
  bool get sizedByParent => true;

  double get sliderHeight => w20;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = math.min(constraints.maxWidth, constraints.maxHeight);
    setScreenSize(Size(width, width));
    var dy = _sliderDy + (sliderHeight / 2);
    _sliderOffset = Offset((-width / 2) + 10, dy);

    initMaxSliderRange(
        SliderRange(start: Offset(-width / 2, dy), end: Offset(width / 2, dy)));
    return Size(width, width);
  }

  @override
  bool hitTestSelf(Offset position) {
    var translatedPos = _translateToSliderPosition(position);

    if (_leftEyeClickablePath.contains(translatedPos)) {
      _leftEyeLidAnimController.forward();
    }
    if (_rightEyeClickablePath.contains(translatedPos)) {
      _rightEyeLidAnimController.forward();
    }
    var contains = _sliderPath.contains(translatedPos);

    return contains;
  }

  Offset _translateToSliderPosition(Offset position) {
    return position.translate(
        -(constraints.maxWidth / 2), -_sliderDy - (sliderHeight * 2));
  }

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    if (event is PointerDownEvent) {
      tapGestureRecognizer.addPointer(event);
      dragGestureRecognizer.addPointer(event);
    }
  }

  void _dragUpdate(DragUpdateDetails details) {
    _updateKnobPosition(details.localPosition);
    markNeedsPaint();
  }

  void _tapDown(TapDownDetails details) {
    _updateKnobPosition(details.localPosition);
    markNeedsPaint();
  }

  void _updateKnobPosition(Offset offset) {
    final position = _translateToSliderPosition(offset);
    var dy = _sliderDy + sliderHeight / 2;
    _sliderOffset = Offset(position.dx, dy);
    _sliderDirection =
        convertDirectionToRangeZeroToOne(_sliderOffset.direction);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    canvas.translate(size.width / 2, constraints.maxHeight / 2);

    final double eyeRadius = w32;
    final distanceBetweenEyesAndNose = constraints.maxWidth * 0.3;

    _drawHead(canvas);

    _drawLeftEyes(distanceBetweenEyesAndNose, eyeRadius, canvas);

    _drawRightEyes(distanceBetweenEyesAndNose - w20, eyeRadius, canvas);

    _drawNose(canvas);

    _drawMouth(canvas);

    _drawSlider(canvas);
  }

  void _drawHead(Canvas canvas) {
    var faceHeight = size.width * 0.7;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: constraints.maxWidth - w20,
        height: faceHeight,
      ),
      _outlinePaint,
    );
    ;
    canvas.save();
    canvas.translate(-w45, 0);
    for (int i = 0; i < 3; i++) {
      var x = w40 * i.toDouble();
      Path _hairStrandPath = Path()
        ..moveTo(x, -faceHeight / 2)
        ..arcToPoint(
          Offset(x, -faceHeight / 2 + w40),
          radius: Radius.circular(w40),
        );

      canvas.drawPath(_hairStrandPath, _outlinePaint);
    }
    canvas.restore();
  }

  void _drawLeftEyes(
    double distanceBetweenEyesAndNose,
    double eyeRadius,
    Canvas canvas,
  ) {
    Path eyeBrows = Path()
      ..moveTo(-distanceBetweenEyesAndNose - eyeRadius + w5,
          -eyeRadius - convertRangeMinMax(_sliderDirection, w15, w5))
      ..lineTo(-distanceBetweenEyesAndNose + eyeRadius - w5,
          -eyeRadius - convertRangeMinMax(_sliderDirection, w5, w15));

    canvas.drawPath(eyeBrows, _outlinePaint);

    Path eyeSclera = Path()
      ..moveTo(-distanceBetweenEyesAndNose - eyeRadius + w4, eyeRadius * -0.20)
      ..lineTo(-distanceBetweenEyesAndNose + eyeRadius - w3, eyeRadius * -0.06)
      ..moveTo(-distanceBetweenEyesAndNose - eyeRadius + w6, eyeRadius * 0.2)
      ..lineTo(-distanceBetweenEyesAndNose + eyeRadius - w4, eyeRadius * 0.06)
      ..moveTo(-distanceBetweenEyesAndNose - eyeRadius, eyeRadius * -0.20)
      ..close();

    canvas.drawPath(
      eyeSclera,
      Paint()
        ..color = Colors.white.withOpacity(_leftEyelidAnimation.value)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(-distanceBetweenEyesAndNose + eyeRadius, 0),
        radius: eyeRadius * 1.9,
      ),
      math.pi - 0.14,
      math.pi / 10.5,
      true,
      Paint()
        ..color = Colors.white.withOpacity(_leftEyelidAnimation.value)
        ..strokeWidth = 4
        ..style = PaintingStyle.fill,
    );

    Path eye = Path()
      ..moveTo(-distanceBetweenEyesAndNose, 0)
      ..addOval(Rect.fromCircle(
          center: Offset(-distanceBetweenEyesAndNose, 0), radius: eyeRadius))
      ..moveTo(-distanceBetweenEyesAndNose - eyeRadius,
          eyeRadius * -0.35 * _leftEyelidAnimation.value)
      ..lineTo(-distanceBetweenEyesAndNose + eyeRadius,
          eyeRadius * -0.2 * _leftEyelidAnimation.value)
      ..moveTo(-distanceBetweenEyesAndNose - eyeRadius,
          eyeRadius * 0.35 * _leftEyelidAnimation.value)
      ..lineTo(-distanceBetweenEyesAndNose + eyeRadius,
          eyeRadius * 0.2 * _leftEyelidAnimation.value)
      ..close();

    canvas.drawPath(
      eye,
      _outlinePaint,
    );

    canvas.drawCircle(
      Offset(
        _eyeBallOffset(-distanceBetweenEyesAndNose, eyeRadius),
        0.20,
      ),
      5,
      Paint()..color = Colors.black.withOpacity(_leftEyelidAnimation.value),
    );
    _leftEyeClickablePath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(-distanceBetweenEyesAndNose, 0), radius: eyeRadius));
  }

  void _drawRightEyes(
    double distanceBetweenEyesAndNose,
    double eyeRadius,
    Canvas canvas,
  ) {
    Path eyeBrows = Path()
      ..moveTo(distanceBetweenEyesAndNose - eyeRadius + w5,
          -eyeRadius - convertRangeMinMax(_sliderDirection, w5, w15))
      ..lineTo(distanceBetweenEyesAndNose + eyeRadius - w5,
          -eyeRadius - convertRangeMinMax(_sliderDirection, w15, w5));

    canvas.drawPath(eyeBrows, _outlinePaint);

    Path eyeSclera = Path()
      ..moveTo(distanceBetweenEyesAndNose - eyeRadius + w4, eyeRadius * -0.06)
      ..lineTo(distanceBetweenEyesAndNose + eyeRadius - w3, eyeRadius * -0.20)
      ..moveTo(distanceBetweenEyesAndNose - eyeRadius + w6, eyeRadius * 0.06)
      ..lineTo(distanceBetweenEyesAndNose + eyeRadius - w4, eyeRadius * 0.2)
      ..moveTo(distanceBetweenEyesAndNose - eyeRadius, eyeRadius * -0.20)
      ..close();

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(distanceBetweenEyesAndNose - eyeRadius, 0),
        radius: eyeRadius * 1.9,
      ),
      (math.pi * 2) - 0.14,
      math.pi / 10.5,
      true,
      Paint()
        ..color = Colors.white.withOpacity(_rightEyelidAnimation.value)
        ..strokeWidth = 4
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      eyeSclera,
      Paint()
        ..color = Colors.white.withOpacity(_rightEyelidAnimation.value)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke,
    );

    Path eye = Path()
      ..moveTo(distanceBetweenEyesAndNose, 0)
      ..addOval(Rect.fromCircle(
          center: Offset(distanceBetweenEyesAndNose, 0), radius: eyeRadius))
      ..moveTo(distanceBetweenEyesAndNose - eyeRadius,
          eyeRadius * -0.2 * _rightEyelidAnimation.value)
      ..lineTo(distanceBetweenEyesAndNose + eyeRadius,
          eyeRadius * -0.35 * _rightEyelidAnimation.value)
      ..moveTo(distanceBetweenEyesAndNose - eyeRadius,
          eyeRadius * 0.2 * _rightEyelidAnimation.value)
      ..lineTo(distanceBetweenEyesAndNose + eyeRadius,
          eyeRadius * 0.35 * _rightEyelidAnimation.value)
      ..close();

    canvas.drawPath(
      eye,
      _outlinePaint,
    );

    canvas.drawCircle(
      Offset(_eyeBallOffset(distanceBetweenEyesAndNose, eyeRadius), -0.9),
      5,
      Paint()..color = Colors.black.withOpacity(_rightEyelidAnimation.value),
    );
    _rightEyeClickablePath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(distanceBetweenEyesAndNose, 0), radius: eyeRadius));
  }

  double _eyeBallOffset(double distanceBetweenEyesAndNose, double eyeRadius) {
    return distanceBetweenEyesAndNose -
        eyeRadius +
        (5 * _sliderDirection - 5).abs() +
        ((eyeRadius * 2) * _sliderDirection);
  }

  Paint get _outlinePaint {
    return Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
  }

  void _drawNose(Canvas canvas) {
    canvas.save();
    canvas.translate(w20, w10);
    Path _nosePath = Path()
      ..moveTo(-w20, -w20)
      ..lineTo(0, 0)
      ..lineTo(-w20, w20);
    canvas.drawPath(
      _nosePath,
      _outlinePaint..strokeCap = StrokeCap.round,
    );
    Path _noseShadowPath = Path()
      ..moveTo(-w20, -w20)
      ..lineTo(w10, 0)
      ..lineTo(-w20, w20);
    canvas.drawPath(
      _noseShadowPath,
      _outlinePaint
        ..strokeCap = StrokeCap.round
        ..color = Colors.grey.withOpacity(.17)
        ..strokeWidth = w10
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  void _drawMouth(Canvas canvas) {
    canvas.save();
    canvas.translate(0, w10);
    Path _mouthPath = Path()
      ..moveTo(w20, w30)
      ..lineTo(w30, w40)
      ..arcToPoint(
        Offset(-w20, w50),
        radius: Radius.circular(w200),
        largeArc: false,
        clockwise: false,
      )
      ..moveTo(w25, w42)
      ..lineTo(w15, w52);

    canvas.drawPath(
      _mouthPath,
      _outlinePaint..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  void _drawSlider(Canvas canvas) {
    _sliderPath = _sliderPath
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset((-size.width / 2) + sliderHeight, _sliderDy) &
              Size(size.width - (sliderHeight * 2), sliderHeight),
          const Radius.circular(20),
        ),
      );

    canvas.drawPath(
      _sliderPath,
      _outlinePaint
        ..strokeWidth = 1
        ..color = Colors.black87
        ..style = PaintingStyle.fill
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(_sliderOffset, 28, Paint()..color = Colors.black26);
    canvas.drawCircle(_sliderOffset, 25, Paint()..color = Colors.black87);
    canvas.drawCircle(_sliderOffset, 15, Paint()..color = Colors.amber[100]!);
  }

  double get _sliderDy =>
      (math.min(constraints.maxWidth, constraints.maxHeight) * 0.8) / 2;

  @override
  void dispose() {
    _leftEyeLidAnimController.dispose();
    _rightEyeLidAnimController.dispose();

    super.dispose();
  }
}

mixin SizesHelper {
  static late Size _size;
  static late SliderRange _sliderRange;

  void setScreenSize(Size size) {
    _size = size;
  }

  void initMaxSliderRange(SliderRange range) {
    _sliderRange = range;
  }

  double convertDirectionToRangeZeroToOne(double val) {
    final min = _sliderRange.start.direction;
    final max = _sliderRange.end.direction;

    return ((val - min) / (max - min)).abs();
  }

  double convertRangeMinMax(double a, double min, double max) {
    return ((max - min) * a) + min;
  }

  double get w3 => _size.width * 0.0077;

  double get w4 => _size.width * 0.0102;

  double get w5 => _size.width * 0.0129;

  double get w6 => _size.width * 0.0154;

  double get w10 => _size.width * 0.027;

  double get w15 => _size.width * 0.039;

  double get w20 => _size.width * 0.052;

  double get w25 => _size.width * 0.064;

  double get w30 => _size.width * 0.079;

  double get w32 => _size.width * 0.083;

  double get w40 => _size.width * 0.1029;

  double get w42 => _size.width * 0.109;

  double get w45 => _size.width * 0.115;

  double get w50 => _size.width * 0.13;

  double get w52 => _size.width * 0.133;

  double get w200 => _size.width * 0.512;
}

class SliderRange {
  SliderRange({required this.start, required this.end});

  final Offset start;
  final Offset end;
}

class CustomTicker extends Ticker {
  CustomTicker(TickerCallback onTick) : super(onTick);
}

class _AnimTickerProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => CustomTicker(onTick);
}
