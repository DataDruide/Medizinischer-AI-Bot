package com.example.medizinischer_ai_bot

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        AppIconScheduler.onAppOpened(applicationContext)
    }
}
