package com.omniverselabs.loud_guard

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    companion object {
        private const val METHOD_CHANNEL = "com.omniverselabs.loud_guard/audio_meter"
        private const val EVENT_CHANNEL = "com.omniverselabs.loud_guard/audio_meter_stream"
        private const val REQ_RECORD_AUDIO = 4109
        private const val SAMPLE_RATE = 44100
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null

    @Volatile
    private var isRecording = false
    private var audioRecord: AudioRecord? = null
    private var workerThread: Thread? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasAudioPermission())
                    "requestPermission" -> requestAudioPermission(result)
                    "start" -> {
                        val started = startMeter()
                        result.success(started)
                    }
                    "stop" -> {
                        stopMeter()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    stopMeter()
                }
            })
    }

    private fun hasAudioPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestAudioPermission(result: MethodChannel.Result) {
        if (hasAudioPermission()) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("PERMISSION_IN_PROGRESS", "Permission request already active", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            REQ_RECORD_AUDIO
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_RECORD_AUDIO) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    @Synchronized
    private fun startMeter(): Boolean {
        if (!hasAudioPermission()) return false
        if (isRecording) return true

        val minBufBytes = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        if (minBufBytes == AudioRecord.ERROR || minBufBytes == AudioRecord.ERROR_BAD_VALUE) {
            return false
        }

        val bufferShortsCount = max(minBufBytes / 2, SAMPLE_RATE / 16)
        val record = try {
            AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferShortsCount * 2
            )
        } catch (_: SecurityException) {
            return false
        } catch (_: IllegalArgumentException) {
            return false
        }

        if (record.state != AudioRecord.STATE_INITIALIZED) {
            record.release()
            return false
        }

        audioRecord = record
        isRecording = true
        record.startRecording()

        workerThread = thread(start = true, name = "LoudGuardAudioSampler") {
            val buffer = ShortArray(bufferShortsCount)
            while (isRecording) {
                val read = record.read(buffer, 0, buffer.size)
                if (read > 0) {
                    var sumSquares = 0.0
                    for (i in 0 until read) {
                        val sample = buffer[i].toDouble()
                        sumSquares += sample * sample
                    }
                    val rms = sqrt(sumSquares / read)
                    val dbfs = if (rms <= 1.0) {
                        -96.0
                    } else {
                        (20.0 * log10(rms / 32767.0)).coerceIn(-96.0, 0.0)
                    }
                    mainHandler.post {
                        eventSink?.success(dbfs)
                    }
                }
            }
        }
        return true
    }

    @Synchronized
    private fun stopMeter() {
        isRecording = false
        try {
            audioRecord?.stop()
        } catch (_: IllegalStateException) {
        }
        try {
            audioRecord?.release()
        } catch (_: Exception) {
        }
        audioRecord = null
        workerThread = null
    }

    override fun onDestroy() {
        stopMeter()
        super.onDestroy()
    }
}
