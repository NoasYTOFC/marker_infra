package com.example.marker_infra

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.marker_infra/files"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedFile" -> {
                    val filePath = getSharedFilePath()
                    result.success(filePath)
                }
                else -> result.notImplemented()
            }
        }
        
        // Enviar arquivo compartilhado ao abrir
        handleSharedFile()
    }

    private fun getSharedFilePath(): String? {
        val intent = intent
        return when {
            intent.action == Intent.ACTION_VIEW -> {
                val uri: Uri? = intent.data
                uri?.path ?: uri?.toString()
            }
            else -> null
        }
    }

    private fun handleSharedFile() {
        val intent = intent
        if (intent.action == Intent.ACTION_VIEW) {
            val uri = intent.data
            if (uri != null && (uri.path?.endsWith(".kml") == true || uri.path?.endsWith(".kmz") == true)) {
                // Arquivo será processado no Dart
                intent.putExtra("shared_file_uri", uri.toString())
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleSharedFile()
    }
}
