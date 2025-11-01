package com.infraplan.app

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

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
    }

    private fun getSharedFilePath(): String? {
        val intent = intent
        if (intent.action != Intent.ACTION_VIEW) {
            android.util.Log.d("MainActivity", "❌ Intent action is not ACTION_VIEW: ${intent.action}")
            return null
        }

        val uri: Uri? = intent.data
        if (uri == null) {
            android.util.Log.d("MainActivity", "❌ Intent data is null")
            return null
        }

        android.util.Log.d("MainActivity", "📱 Received URI: $uri")
        android.util.Log.d("MainActivity", "📱 URI scheme: ${uri.scheme}")
        android.util.Log.d("MainActivity", "📱 URI path: ${uri.path}")

        return try {
            // Se for um content:// URI, precisamos copiar para um arquivo temporário
            if (uri.scheme == "content") {
                android.util.Log.d("MainActivity", "✅ Content URI detected, copying to temp file...")
                val fileName = getFileName(uri) ?: "shared_file.kml"
                val tempFile = File(cacheDir, fileName)
                
                contentResolver.openInputStream(uri)?.use { input ->
                    FileOutputStream(tempFile).use { output ->
                        input.copyTo(output)
                    }
                }
                
                android.util.Log.d("MainActivity", "✅ File copied to: ${tempFile.absolutePath}")
                tempFile.absolutePath
            } else if (uri.scheme == "file") {
                // Se for file:// URI, podemos usar diretamente
                android.util.Log.d("MainActivity", "✅ File URI detected: ${uri.path}")
                uri.path
            } else {
                android.util.Log.d("MainActivity", "❌ Unknown URI scheme: ${uri.scheme}")
                null
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "❌ Error processing file: ${e.message}", e)
            e.printStackTrace()
            null
        }
    }

    private fun getFileName(uri: Uri): String? {
        var fileName: String? = null
        if (uri.scheme == "content") {
            val cursor = contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1) {
                        fileName = it.getString(nameIndex)
                    }
                }
            }
        }
        if (fileName == null) {
            fileName = uri.path?.substringAfterLast('/')
        }
        return fileName
    }
}
