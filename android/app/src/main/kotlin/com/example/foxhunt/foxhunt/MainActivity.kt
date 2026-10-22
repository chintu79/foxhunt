package com.example.foxhunt.foxhunt

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.foxhunt/sound"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playRealSound" -> {
                    playRealTone()
                    result.success(true)
                }
                "playDummySound" -> {
                    playDummyTone()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playRealTone() {
        Thread {
            try {
                val toneGen = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
                // Crisp high-pitch affirmative double-tone sequence (Real Target Lock)
                toneGen.startTone(ToneGenerator.TONE_PROP_ACK, 200)
                Thread.sleep(220)
                toneGen.startTone(ToneGenerator.TONE_CDMA_ALERT_NETWORK_LITE, 350)
                Thread.sleep(380)
                toneGen.release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }.start()
    }

    private fun playDummyTone() {
        Thread {
            try {
                val toneGen = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
                // Low-pitch buzzing decoy/error sequence (Dummy / Empty)
                toneGen.startTone(ToneGenerator.TONE_PROP_NACK, 300)
                Thread.sleep(320)
                toneGen.startTone(ToneGenerator.TONE_CDMA_LOW_L, 450)
                Thread.sleep(480)
                toneGen.release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }.start()
    }
}
