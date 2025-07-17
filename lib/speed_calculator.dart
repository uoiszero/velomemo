import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 速度计算器
/// 使用GPS数据计算基础速度，结合陀螺仪和加速度计数据进行修正
class SpeedCalculator {
  static SpeedCalculator? _instance;
  static SpeedCalculator get instance => _instance ??= SpeedCalculator._();
  
  SpeedCalculator._();
  
  // GPS相关
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  Timer? _gpsTimer;
  
  // 传感器相关
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // 速度数据
  double _currentSpeed = 0.0; // 当前速度 (m/s)
  double _gpsSpeed = 0.0; // GPS计算的速度
  double _correctedSpeed = 0.0; // 修正后的速度
  
  // 传感器数据
  AccelerometerEvent? _lastAccelerometer;
  GyroscopeEvent? _lastGyroscope;
  
  // 速度变化监听器
  final List<Function(double)> _speedListeners = [];
  
  // 配置参数
  static const int _gpsUpdateInterval = 2; // GPS更新间隔(秒)
  static const double _speedSmoothingFactor = 0.3; // 速度平滑系数
  static const double _accelerometerThreshold = 0.5; // 加速度计阈值
  
  /// 初始化速度计算器
  Future<bool> initialize() async {
    try {
      // 检查位置权限
      if (!await _checkLocationPermission()) {
        print('位置权限未授予');
        return false;
      }
      
      // 启动GPS监听
      await _startGPSTracking();
      
      // 启动传感器监听
      _startSensorTracking();
      
      print('速度计算器初始化成功');
      return true;
    } catch (e) {
      print('速度计算器初始化失败: $e');
      return false;
    }
  }
  
  /// 检查并请求位置权限
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    // 检查位置服务是否启用
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('位置服务未启用');
      return false;
    }
    
    // 检查权限
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('位置权限被拒绝');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('位置权限被永久拒绝');
      return false;
    }
    
    return true;
  }
  
  /// 启动GPS跟踪
  Future<void> _startGPSTracking() async {
    // 获取初始位置
    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastPositionTime = DateTime.now();
      print('获取初始GPS位置: ${_lastPosition!.latitude}, ${_lastPosition!.longitude}');
    } catch (e) {
      print('获取初始位置失败: $e');
    }
    
    // 启动定时器，每2秒获取一次位置
    _gpsTimer = Timer.periodic(Duration(seconds: _gpsUpdateInterval), (timer) {
      _updateGPSPosition();
    });
  }
  
  /// 更新GPS位置并计算速度
  Future<void> _updateGPSPosition() async {
    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final currentTime = DateTime.now();
      
      if (_lastPosition != null && _lastPositionTime != null) {
        // 计算距离(米)
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          currentPosition.latitude,
          currentPosition.longitude,
        );
        
        // 计算时间差(秒)
        final timeDiff = currentTime.difference(_lastPositionTime!).inMilliseconds / 1000.0;
        
        if (timeDiff > 0) {
          // 计算速度(m/s)
          _gpsSpeed = distance / timeDiff;
          
          // 应用传感器修正
          _applySensorCorrection();
          
          print('GPS速度: ${_gpsSpeed.toStringAsFixed(2)} m/s, 修正后速度: ${_correctedSpeed.toStringAsFixed(2)} m/s');
        }
      }
      
      _lastPosition = currentPosition;
      _lastPositionTime = currentTime;
      
    } catch (e) {
      print('更新GPS位置失败: $e');
    }
  }
  
  /// 启动传感器跟踪
  void _startSensorTracking() {
    // 监听加速度计
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _lastAccelerometer = event;
    });
    
    // 监听陀螺仪
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      _lastGyroscope = event;
    });
    
    print('传感器监听已启动');
  }
  
  /// 应用传感器修正
  void _applySensorCorrection() {
    double correctionFactor = 1.0;
    
    // 使用加速度计数据进行修正
    if (_lastAccelerometer != null) {
      // 计算总加速度
      final totalAcceleration = sqrt(
        pow(_lastAccelerometer!.x, 2) +
        pow(_lastAccelerometer!.y, 2) +
        pow(_lastAccelerometer!.z, 2)
      );
      
      // 如果加速度变化明显，说明在加速或减速
      final accelerationChange = (totalAcceleration - 9.8).abs();
      if (accelerationChange > _accelerometerThreshold) {
        // 根据加速度调整修正系数
        correctionFactor += accelerationChange * 0.1;
      }
    }
    
    // 使用陀螺仪数据检测转向
    if (_lastGyroscope != null) {
      final rotationMagnitude = sqrt(
        pow(_lastGyroscope!.x, 2) +
        pow(_lastGyroscope!.y, 2) +
        pow(_lastGyroscope!.z, 2)
      );
      
      // 如果在转向，速度可能不够准确，降低修正系数
      if (rotationMagnitude > 0.5) {
        correctionFactor *= 0.9;
      }
    }
    
    // 应用修正并平滑处理
    final newCorrectedSpeed = _gpsSpeed * correctionFactor;
    _correctedSpeed = _correctedSpeed * (1 - _speedSmoothingFactor) + 
                     newCorrectedSpeed * _speedSmoothingFactor;
    
    // 更新当前速度
    _currentSpeed = _correctedSpeed;
    
    // 通知监听器
    _notifySpeedListeners();
  }
  
  /// 通知速度变化监听器
  void _notifySpeedListeners() {
    for (final listener in _speedListeners) {
      try {
        listener(_currentSpeed);
      } catch (e) {
        print('速度监听器回调失败: $e');
      }
    }
  }
  
  /// 添加速度变化监听器
  void addSpeedListener(Function(double) listener) {
    _speedListeners.add(listener);
  }
  
  /// 移除速度变化监听器
  void removeSpeedListener(Function(double) listener) {
    _speedListeners.remove(listener);
  }
  
  /// 获取当前速度 (m/s)
  double get currentSpeed => _currentSpeed;
  
  /// 获取当前速度 (km/h)
  double get currentSpeedKmh => _currentSpeed * 3.6;
  
  /// 获取GPS原始速度 (m/s)
  double get gpsSpeed => _gpsSpeed;
  
  /// 获取修正后速度 (m/s)
  double get correctedSpeed => _correctedSpeed;
  
  /// 获取当前位置
  Position? get currentPosition => _lastPosition;
  
  /// 获取加速度计数据
  AccelerometerEvent? get accelerometerData => _lastAccelerometer;
  
  /// 获取陀螺仪数据
  GyroscopeEvent? get gyroscopeData => _lastGyroscope;
  
  /// 停止速度计算
  void stop() {
    _gpsTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    
    _gpsTimer = null;
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    
    _speedListeners.clear();
    
    print('速度计算器已停止');
  }
  
  /// 重置速度数据
  void reset() {
    _currentSpeed = 0.0;
    _gpsSpeed = 0.0;
    _correctedSpeed = 0.0;
    _lastPosition = null;
    _lastPositionTime = null;
    _lastAccelerometer = null;
    _lastGyroscope = null;
    
    print('速度数据已重置');
  }
  
  /// 获取速度统计信息
  Map<String, dynamic> getSpeedStats() {
    return {
      'currentSpeed': _currentSpeed,
      'currentSpeedKmh': currentSpeedKmh,
      'gpsSpeed': _gpsSpeed,
      'correctedSpeed': _correctedSpeed,
      'hasPosition': _lastPosition != null,
      'hasAccelerometer': _lastAccelerometer != null,
      'hasGyroscope': _lastGyroscope != null,
      'lastUpdateTime': _lastPositionTime?.toIso8601String(),
    };
  }
}