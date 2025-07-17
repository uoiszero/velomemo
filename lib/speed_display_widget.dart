import 'package:flutter/material.dart';
import 'speed_calculator.dart';

/// 速度显示组件
/// 实时显示当前速度、GPS速度和修正后速度等信息
class SpeedDisplayWidget extends StatefulWidget {
  final bool showDetailedInfo;
  final TextStyle? speedTextStyle;
  final TextStyle? unitTextStyle;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  
  const SpeedDisplayWidget({
    super.key,
    this.showDetailedInfo = false,
    this.speedTextStyle,
    this.unitTextStyle,
    this.backgroundColor,
    this.padding,
  });
  
  @override
  State<SpeedDisplayWidget> createState() => _SpeedDisplayWidgetState();
}

class _SpeedDisplayWidgetState extends State<SpeedDisplayWidget> {
  double _currentSpeed = 0.0;
  double _gpsSpeed = 0.0;
  double _correctedSpeed = 0.0;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeSpeedCalculator();
  }
  
  @override
  void dispose() {
    SpeedCalculator.instance.removeSpeedListener(_onSpeedChanged);
    super.dispose();
  }
  
  /// 初始化速度计算器
  Future<void> _initializeSpeedCalculator() async {
    final success = await SpeedCalculator.instance.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = success;
      });
      
      if (success) {
        SpeedCalculator.instance.addSpeedListener(_onSpeedChanged);
      }
    }
  }
  
  /// 速度变化回调
  void _onSpeedChanged(double speed) {
    if (mounted) {
      setState(() {
        _currentSpeed = speed;
        _gpsSpeed = SpeedCalculator.instance.gpsSpeed;
        _correctedSpeed = SpeedCalculator.instance.correctedSpeed;
      });
    }
  }
  
  /// 构建主要速度显示
  Widget _buildMainSpeedDisplay() {
    final speedKmh = _currentSpeed * 3.6;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              speedKmh.toStringAsFixed(1),
              style: widget.speedTextStyle ?? const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'km/h',
              style: widget.unitTextStyle ?? const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (!_isInitialized)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '正在初始化GPS...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
          ),
      ],
    );
  }
  
  /// 构建详细信息显示
  Widget _buildDetailedInfo() {
    if (!widget.showDetailedInfo) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(color: Colors.white30),
        const SizedBox(height: 8),
        _buildInfoRow('GPS速度', '${(_gpsSpeed * 3.6).toStringAsFixed(1)} km/h'),
        _buildInfoRow('修正速度', '${(_correctedSpeed * 3.6).toStringAsFixed(1)} km/h'),
        _buildInfoRow('原始速度', '${_currentSpeed.toStringAsFixed(2)} m/s'),
        const SizedBox(height: 8),
        _buildSensorStatus(),
      ],
    );
  }
  
  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建传感器状态显示
  Widget _buildSensorStatus() {
    final calculator = SpeedCalculator.instance;
    final hasGPS = calculator.currentPosition != null;
    final hasAccelerometer = calculator.accelerometerData != null;
    final hasGyroscope = calculator.gyroscopeData != null;
    
    return Column(
      children: [
        const Text(
          '传感器状态',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSensorIndicator('GPS', hasGPS),
            _buildSensorIndicator('加速度计', hasAccelerometer),
            _buildSensorIndicator('陀螺仪', hasGyroscope),
          ],
        ),
      ],
    );
  }
  
  /// 构建传感器指示器
  Widget _buildSensorIndicator(String name, bool isActive) {
    return Column(
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isActive ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
  
  /// 获取速度颜色
  Color _getSpeedColor() {
    final speedKmh = _currentSpeed * 3.6;
    if (speedKmh < 10) return Colors.green;
    if (speedKmh < 30) return Colors.orange;
    return Colors.red;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSpeedColor(),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMainSpeedDisplay(),
          _buildDetailedInfo(),
        ],
      ),
    );
  }
}

/// 简化的速度显示组件
/// 只显示当前速度，适用于小空间显示
class SimpleSpeedDisplay extends StatefulWidget {
  final double? width;
  final double? height;
  final TextStyle? textStyle;
  
  const SimpleSpeedDisplay({
    super.key,
    this.width,
    this.height,
    this.textStyle,
  });
  
  @override
  State<SimpleSpeedDisplay> createState() => _SimpleSpeedDisplayState();
}

class _SimpleSpeedDisplayState extends State<SimpleSpeedDisplay> {
  double _currentSpeed = 0.0;
  
  @override
  void initState() {
    super.initState();
    SpeedCalculator.instance.addSpeedListener(_onSpeedChanged);
  }
  
  @override
  void dispose() {
    SpeedCalculator.instance.removeSpeedListener(_onSpeedChanged);
    super.dispose();
  }
  
  void _onSpeedChanged(double speed) {
    if (mounted) {
      setState(() {
        _currentSpeed = speed;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final speedKmh = _currentSpeed * 3.6;
    
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            speedKmh.toStringAsFixed(0),
            style: widget.textStyle ?? const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
          const Text(
            'km/h',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}