package com.scanpay.document_opener

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import java.io.File

class DocumentOpenerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.scanpay.document_opener")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "openDocument" -> {
                val filePath = call.argument<String>("file_path")
                if (filePath == null) {
                    result.success(createResult("error", "File path cannot be null"))
                    return
                }

                if (!isValidFileType(filePath)) {
                    result.success(createResult("error", "Only PDF and CSV files are supported"))
                    return
                }

                if (activity == null) {
                    result.success(createResult("error", "Activity is not available"))
                    return
                }

                try {
                    openDocument(filePath, result)
                } catch (e: Exception) {
                    result.success(createResult("error", e.message ?: "Unknown error occurred"))
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun isValidFileType(filePath: String): Boolean {
        val lowercasePath = filePath.lowercase()
        return lowercasePath.endsWith(".pdf") || lowercasePath.endsWith(".csv")
    }

    private fun openDocument(filePath: String, result: Result) {
        val file = File(filePath)
        if (!file.exists()) {
            result.success(createResult("error", "File does not exist"))
            return
        }

        val intent = Intent(Intent.ACTION_VIEW)
        val uri = FileProvider.getUriForFile(
            context!!,
            context!!.packageName + ".fileprovider", 
            file
        )

        val extension = filePath.substring(filePath.lastIndexOf(".") + 1).lowercase()
        val mimeType = when (extension) {
            "pdf" -> "application/pdf"
            "csv" -> "text/csv"
            else -> ""
        }

        intent.setDataAndType(uri, mimeType)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        try {
            activity!!.startActivity(intent)
            result.success(createResult("done", "File opened successfully"))
        } catch (e: Exception) {
            result.success(createResult("noAppToOpen", "No app found to open this file type"))
        }
    }

    private fun createResult(type: String, message: String): String {
        val json = JSONObject()
        json.put("type", type)
        json.put("message", message)
        return json.toString()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
} 