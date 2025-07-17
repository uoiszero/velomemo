package com.example.velomemo

import android.Manifest
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

/**
 * MainActivity - 处理视频录制的Platform Channel调用
 * 实现基于MediaRecorder的连续视频分割功能
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.velomemo/video_recorder"
    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false
    private val REQUEST_PERMISSIONS = 1001
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    val filePath = call.argument<String>("filePath")
                    val maxDurationMs = call.argument<Int>("maxDurationMs")
                    if (filePath != null && maxDurationMs != null) {
                        startRecording(filePath, maxDurationMs, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing filePath or maxDurationMs", null)
                    }
                }
                "setNextOutputFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        setNextOutputFile(filePath, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing filePath", null)
                    }
                }
                "stopRecording" -> {
                    stopRecording(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    /**
     * 开始视频录制
     */
    private fun startRecording(filePath: String, maxDurationMs: Int, result: MethodChannel.Result) {
        if (!checkPermissions()) {
            requestPermissions()
            result.error("PERMISSION_DENIED", "Camera and microphone permissions required", null)
            return
        }
        
        try {
            if (isRecording) {
                stopRecording(null)
            }
            
            // 确保目录存在
            val file = File(filePath)
            file.parentFile?.mkdirs()
            
            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }
            
            mediaRecorder?.apply {
                // 设置音频源
                setAudioSource(MediaRecorder.AudioSource.MIC)
                // 设置视频源
                setVideoSource(MediaRecorder.VideoSource.CAMERA)
                
                // 设置输出格式
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                
                // 设置编码器
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setVideoEncoder(MediaRecorder.VideoEncoder.H264)
                
                // 设置视频参数
                setVideoSize(1920, 1080) // Full HD
                setVideoFrameRate(30)
                setVideoEncodingBitRate(8000000) // 8Mbps
                
                // 设置音频参数
                setAudioEncodingBitRate(128000) // 128kbps
                setAudioSamplingRate(44100)
                
                // 设置输出文件
                setOutputFile(filePath)
                
                // 设置最大录制时长
                setMaxDuration(maxDurationMs)
                
                // 设置信息监听器，用于处理分割
                setOnInfoListener { mr, what, extra ->
                    when (what) {
                        MediaRecorder.MEDIA_RECORDER_INFO_MAX_DURATION_REACHED -> {
                            Log.d("VideoRecorder", "Max duration reached, ready for next segment")
                            // 这里不需要做任何操作，Flutter端会调用setNextOutputFile
                        }
                        MediaRecorder.MEDIA_RECORDER_INFO_MAX_FILESIZE_REACHED -> {
                            Log.d("VideoRecorder", "Max file size reached")
                        }
                    }
                }
                
                // 设置错误监听器
                setOnErrorListener { mr, what, extra ->
                    Log.e("VideoRecorder", "Recording error: what=$what, extra=$extra")
                    isRecording = false
                }
                
                prepare()
                start()
                isRecording = true
                
                Log.d("VideoRecorder", "Recording started: $filePath")
                result.success("Recording started")
            }
        } catch (e: IOException) {
            Log.e("VideoRecorder", "Failed to start recording", e)
            result.error("RECORDING_ERROR", "Failed to start recording: ${e.message}", null)
        } catch (e: Exception) {
            Log.e("VideoRecorder", "Unexpected error", e)
            result.error("UNEXPECTED_ERROR", "Unexpected error: ${e.message}", null)
        }
    }
    
    /**
     * 设置下一个输出文件（用于视频分割）
     */
    private fun setNextOutputFile(filePath: String, result: MethodChannel.Result) {
        try {
            if (!isRecording || mediaRecorder == null) {
                result.error("NOT_RECORDING", "Not currently recording", null)
                return
            }
            
            // 确保目录存在
            val file = File(filePath)
            file.parentFile?.mkdirs()
            
            // 使用setNextOutputFile实现无缝分割
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                mediaRecorder?.setNextOutputFile(file)
                Log.d("VideoRecorder", "Next output file set: $filePath")
                result.success("Next output file set")
            } else {
                result.error("UNSUPPORTED", "setNextOutputFile requires Android API 26+", null)
            }
        } catch (e: Exception) {
            Log.e("VideoRecorder", "Failed to set next output file", e)
            result.error("SET_NEXT_FILE_ERROR", "Failed to set next output file: ${e.message}", null)
        }
    }
    
    /**
     * 停止录制
     */
    private fun stopRecording(result: MethodChannel.Result?) {
        try {
            if (isRecording && mediaRecorder != null) {
                mediaRecorder?.stop()
                mediaRecorder?.release()
                mediaRecorder = null
                isRecording = false
                
                Log.d("VideoRecorder", "Recording stopped")
                result?.success("Recording stopped")
            } else {
                result?.error("NOT_RECORDING", "Not currently recording", null)
            }
        } catch (e: Exception) {
            Log.e("VideoRecorder", "Failed to stop recording", e)
            mediaRecorder?.release()
            mediaRecorder = null
            isRecording = false
            result?.error("STOP_ERROR", "Failed to stop recording: ${e.message}", null)
        }
    }
    
    /**
     * 检查权限
     */
    private fun checkPermissions(): Boolean {
        val cameraPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
        val audioPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
        val storagePermission = ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
        
        return cameraPermission == PackageManager.PERMISSION_GRANTED &&
               audioPermission == PackageManager.PERMISSION_GRANTED &&
               (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q || storagePermission == PackageManager.PERMISSION_GRANTED)
    }
    
    /**
     * 请求权限
     */
    private fun requestPermissions() {
        val permissions = mutableListOf(
            Manifest.permission.CAMERA,
            Manifest.permission.RECORD_AUDIO
        )
        
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            permissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        }
        
        ActivityCompat.requestPermissions(this, permissions.toTypedArray(), REQUEST_PERMISSIONS)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        if (isRecording) {
            stopRecording(null)
        }
    }
}