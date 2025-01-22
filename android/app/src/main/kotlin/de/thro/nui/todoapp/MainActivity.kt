package de.thro.nui.todoapp

import android.content.Context
import android.media.AudioManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val amanager: AudioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        amanager.adjustStreamVolume(AudioManager.STREAM_NOTIFICATION, AudioManager.ADJUST_MUTE, 0);
    }
}
