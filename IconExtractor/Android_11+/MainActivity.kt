package com.example.iconextractor

import android.content.ContentResolver
import android.content.ContentValues
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import androidx.activity.ComponentActivity
import java.util.concurrent.Executors

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        clearIconsFolder()
        extractIconsAndFinish()
    }

    private fun extractIconsAndFinish() {
        val pm = packageManager
        val packages = pm.getInstalledApplications(0)

        val executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors())

        for (app in packages) {
            executor.submit {
                try {
                    val drawable = pm.getApplicationIcon(app)
                    val bitmap = drawableToBitmap(drawable)
                    saveToMediaStore(bitmap, "${app.packageName}.png")
                } catch (_: Exception) { /* игнорируем ошибки */ }
            }
        }

        executor.shutdown()
        while (!executor.isTerminated) {
            Thread.sleep(50)
        }

        finish()
        android.os.Process.killProcess(android.os.Process.myPid())
    }

    // --- Удаляем все PNG в папке IconExtractor/icons ---
    private fun clearIconsFolder() {
        val resolver: ContentResolver = contentResolver
        val collection = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val selection = "${MediaStore.Images.Media.RELATIVE_PATH}=? AND ${MediaStore.Images.Media.MIME_TYPE}=?"
        val selectionArgs = arrayOf("Pictures/IconExtractor/icons/", "image/png")
        resolver.delete(collection, selection, selectionArgs)
    }

    private fun saveToMediaStore(bitmap: Bitmap, fileName: String) {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/IconExtractor/icons")
        }

        contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)?.let { uri: Uri ->
            contentResolver.openOutputStream(uri)?.use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) drawable.bitmap?.let { return it }

        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}

