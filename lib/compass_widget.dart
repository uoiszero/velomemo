import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 指南针方向指示器组件
/// 显示设备指向的方向和刻度
class CompassWidget extends StatefulWidget {
  const CompassWidget({super.key});

  @override
  State<CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget>
    with TickerProviderStateMixin {
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  double _heading = 0.0; // 当前方向角度（0-360度）
  double _smoothedHeading = 0.0; // 平滑后的方向角度
  double _animatedHeading = 0.0; // 动画中的方向角度
  
  // 传感器数据
  MagnetometerEvent? _lastMagnetometer;
  AccelerometerEvent? _lastAccelerometer;
  
  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _headingAnimation;
  
  // 动画参数
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Curve _animationCurve = Curves.easeOutCubic;
  
  // 方向名称映射
  static const Map<String, double> _directions = {
    '北': 0,
    '东北': 45,
    '东': 90,
    '东南': 135,
    '南': 180,
    '西南': 225,
    '西': 270,
    '西北': 315,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    
    // 初始化动画
    _headingAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: _animationCurve,
    ));
    
    // 监听动画值变化
    _headingAnimation.addListener(() {
      setState(() {
        _updateAnimatedHeading();
      });
    });
    
    _startSensorListening();
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// 开始监听传感器数据
  void _startSensorListening() {
    // 监听磁力计
    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      _lastMagnetometer = event;
      _calculateHeading();
    });
    
    // 监听加速度计（用于倾斜补偿）
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _lastAccelerometer = event;
      _calculateHeading();
    });
  }

  /// 计算设备方向角度
  void _calculateHeading() {
    if (_lastMagnetometer == null || _lastAccelerometer == null) return;
    
    final mag = _lastMagnetometer!;
    final acc = _lastAccelerometer!;
    
    // 计算倾斜补偿后的方向角度
    double heading = atan2(mag.y, mag.x) * 180 / pi;
    
    // 标准化角度到0-360度
    if (heading < 0) {
      heading += 360;
    }
    
    // 应用平滑滤波
    _smoothHeading(heading);
  }

  /// 平滑方向角度变化并启动动画
  void _smoothHeading(double newHeading) {
    // 处理角度跳跃（例如从359度到1度）
    double diff = newHeading - _smoothedHeading;
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }
    
    // 应用低通滤波器
    const double alpha = 0.15; // 平滑系数，稍微提高响应速度
    _smoothedHeading += diff * alpha;
    
    // 标准化角度
    if (_smoothedHeading < 0) {
      _smoothedHeading += 360;
    } else if (_smoothedHeading >= 360) {
      _smoothedHeading -= 360;
    }
    
    // 启动动画到新的方向
    _animateToHeading(_smoothedHeading);
  }
  
  /// 启动方向角度动画
  void _animateToHeading(double targetHeading) {
    // 计算最短路径的角度差
    double currentHeading = _animatedHeading;
    double diff = targetHeading - currentHeading;
    
    // 处理角度跳跃，选择最短路径
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }
    
    // 如果角度变化很小，不需要动画
    if (diff.abs() < 0.5) {
      _heading = targetHeading;
      _animatedHeading = targetHeading;
      return;
    }
    
    // 设置动画的起始和结束值
    final double endHeading = currentHeading + diff;
    
    // 停止当前动画
    _animationController.stop();
    
    // 创建新的动画
    _headingAnimation = Tween<double>(
      begin: currentHeading,
      end: endHeading,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: _animationCurve,
    ));
    
    // 启动动画
    _animationController.reset();
    _animationController.forward();
  }
  
  /// 更新动画值并标准化角度
  void _updateAnimatedHeading() {
    double value = _headingAnimation.value;
    // 标准化角度到0-360度
    if (value < 0) {
      value += 360;
    } else if (value >= 360) {
      value -= 360;
    }
    _animatedHeading = value;
    _heading = value;
  }

  /// 获取当前方向的文字描述
  String _getDirectionText() {
    for (final entry in _directions.entries) {
      double diff = (_heading - entry.value).abs();
      if (diff > 180) diff = 360 - diff;
      if (diff <= 22.5) {
        return entry.key;
      }
    }
    return '北'; // 默认返回北
  }

  /// 获取方向颜色
  Color _getDirectionColor() {
    final direction = _getDirectionText();
    switch (direction) {
      case '北':
        return Colors.red;
      case '东':
        return Colors.blue;
      case '南':
        return Colors.green;
      case '西':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 方向文字和角度
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getDirectionText(),
                  style: TextStyle(
                    color: _getDirectionColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_heading.toInt()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 刻度条
          Container(
            height: 40,
            width: double.infinity,
            child: CustomPaint(
              painter: CompassScalePainter(_animatedHeading),
            ),
          ),
        ],
      ),
    );
  }
}

/// 指南针刻度绘制器
/// 绘制方向刻度线，每5度一个短刻度，每15度一个长刻度
/// 支持平滑动画过渡效果
class CompassScalePainter extends CustomPainter {
  final double heading;
  
  CompassScalePainter(this.heading);
  
  /// 获取方向对应的颜色
  Color _getDirectionColor(int angle) {
    switch (angle) {
      case 0:
      case 360:
        return Colors.red; // 北
      case 90:
        return Colors.blue; // 东
      case 180:
        return Colors.green; // 南
      case 270:
        return Colors.orange; // 西
      default:
        return Colors.white;
    }
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    final centerX = size.width / 2;
    final scaleWidth = size.width * 0.8; // 刻度条宽度
    
    // 绘制中心指针（带阴影效果）
    final pointerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 4.0;
    
    final pointerPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;
    
    // 绘制指针阴影
    canvas.drawLine(
      Offset(centerX + 1, size.height / 2 - 15 + 1),
      Offset(centerX + 1, size.height / 2 + 15 + 1),
      pointerShadowPaint,
    );
    
    // 绘制指针
    canvas.drawLine(
      Offset(centerX, size.height / 2 - 15),
      Offset(centerX, size.height / 2 + 15),
      pointerPaint,
    );
    
    // 绘制刻度线和标签
    for (int angle = -60; angle <= 60; angle += 5) {
      final normalizedAngle = (heading + angle) % 360;
      final roundedAngle = normalizedAngle.round();
      
      final x = centerX + (angle / 60.0) * (scaleWidth / 2);
      
      // 确定刻度线高度
      double tickHeight;
      bool showLabel = false;
      
      if (angle % 15 == 0) {
        // 长刻度（每15度）
        tickHeight = 20;
        showLabel = true;
      } else {
        // 短刻度（每5度）
        tickHeight = 5;
      }
      
      if (tickHeight > 0){
        // 根据方向设置刻度颜色
        final tickPaint = Paint()
          ..color = _getDirectionColor(roundedAngle)
          ..strokeWidth = (angle % 15 == 0) ? 2.0 : 1.0
          ..style = PaintingStyle.stroke;
        
        // 绘制刻度线
        canvas.drawLine(
          Offset(x, size.height / 2 - tickHeight / 2),
          Offset(x, size.height / 2 + tickHeight / 2),
          tickPaint,
        );
      }
      
      // 绘制角度标签（仅长刻度）
      if (showLabel) {
        String labelText;
        
        // 将特定角度替换为方向汉字
        switch (roundedAngle) {
          case 0:
          case 360:
            labelText = '北';
            break;
          case 45:
            labelText = '东北';
            break;
          case 90:
            labelText = '东';
            break;
          case 135:
            labelText = '东南';
            break;
          case 180:
            labelText = '南';
            break;
          case 225:
            labelText = '西南';
            break;
          case 270:
            labelText = '西';
            break;
          case 315:
            labelText = '西北';
            break;
          default:
            labelText = '';
        }
        
        if (labelText.isNotEmpty) {
          // 文字阴影
          textPainter.text = TextSpan(
            text: labelText,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.5),
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();

          final textX = x - textPainter.width / 2;
          final textY = size.height / 2 + tickHeight / 2 + 2;

          textPainter.paint(canvas, Offset(textX + 1, textY + 1));
          
          // 文字主体
          textPainter.text = TextSpan(
            text: labelText,
            style: TextStyle(
              color: _getDirectionColor(roundedAngle),
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();

          textPainter.paint(canvas, Offset(textX, textY));
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(CompassScalePainter oldDelegate) {
    return oldDelegate.heading != heading;
  }
}