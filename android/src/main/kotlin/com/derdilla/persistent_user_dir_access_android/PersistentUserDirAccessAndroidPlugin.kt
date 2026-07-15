package com.derdilla.persistent_user_dir_access_android

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat.startActivityForResult
import androidx.documentfile.provider.DocumentFile

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException
import java.lang.UnsupportedOperationException

/** PersistentUserDirAccessAndroidPlugin */
class PersistentUserDirAccessAndroidPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /** The MethodChannel that will the communication between Flutter and native Android */
  private lateinit var channel : MethodChannel

  /** The activity from which to start the intend */
  private var activity: ActivityPluginBinding? = null

  /**
   * Upwards counting code for intents
   * ```kt
   * lastReqCode++;
   * val code = lastReqCode
   * ```
   */
  private var lastReqCode: Int = 1;

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "persistent_user_dir_access_android")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
        "requestDirectoryUri" -> requestDirectoryUri(result)
        "writeFile" -> writeFile(call, result)
        else -> result.notImplemented()
    }
  }

  private fun requestDirectoryUri(result: Result) {
    if (activity != null) {
      val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
      lastReqCode++;
      val code = lastReqCode
      activity!!.addActivityResultListener { requestCode, resultCode, data ->
        if (requestCode != code) {
          false
        } else if (activity != null
          && resultCode == Activity.RESULT_OK && data?.data != null) {
          activity!!.activity.contentResolver.takePersistableUriPermission(
            data.data!!,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
          )
          result.success(data.data!!.toString())
          true
        } else {
          result.success(null)
          true
        }
      }
      activity!!.activity.startActivityForResult(intent, code)
    } else {
      result.error("NoAct", "No active android activity", null)
    }
  }

  // Algorithm roughly follows: https://stackoverflow.com/a/61120265
  private fun writeFile(call: MethodCall, result: Result) {
    if (activity == null) {
      result.error("NoAct", "No active android activity", null)
      return
    }

    val dir = call.argument<String>("dir")
    val fileName = call.argument<String>("name")
    val mimeType = call.argument<String>("mime")
    val data = call.argument<ByteArray>("data")
    val overwrite = call.argument<Boolean>("overwrite");
    if (dir == null || mimeType == null || fileName == null || data == null || overwrite == null) {
      result.error("ArgErr", "Wrong writeFile arguments passed to native implementation", null)
      return
    }

    // Not compiled for older platform versions so true assert is fine
    val dirUri = DocumentFile.fromTreeUri(activity!!.activity.applicationContext, Uri.parse(dir))!!
    
    val file = (if (overwrite) dirUri.findFile(fileName) else null) 
      ?: try {
        dirUri.createFile(mimeType, fileName)
      } catch (e: UnsupportedOperationException) {
        result.error("IOErr", e.message, null)
        return
      }!!
      
    // Open file to write. Existing content will be truncated
    try {
      activity!!.activity.contentResolver.openOutputStream(file.uri, "wt").use { stream ->
        stream?.write(data)
        result.success(true)
      }
    } catch (e: FileNotFoundException) {
      result.error("NoFile", e.message, null)
    } catch (e: IOException) {
      result.error("IOErr", e.message, null)
    }
  }
}
