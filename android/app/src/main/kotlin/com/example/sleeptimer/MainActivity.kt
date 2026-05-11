package com.example.sleeptimer

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.SystemClock
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "sleep_timer/native"
    private val ytMusicPkg = "com.google.android.apps.youtube.music"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "openYouTubeMusic" -> {
                    val launch = packageManager.getLaunchIntentForPackage(ytMusicPkg)
                    if (launch != null) {
                        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(launch)
                        result.success(true)
                    } else {
                        result.error("NOT_INSTALLED", "YouTube Music não está instalado", null)
                    }
                }
                "pauseMedia" -> {
                    sendMediaKey(KeyEvent.KEYCODE_MEDIA_PAUSE)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sendMediaKey(keyCode: Int) {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val now = SystemClock.uptimeMillis()
        am.dispatchMediaKeyEvent(KeyEvent(now, now, KeyEvent.ACTION_DOWN, keyCode, 0))
        am.dispatchMediaKeyEvent(KeyEvent(now, now, KeyEvent.ACTION_UP, keyCode, 0))
    }
}
