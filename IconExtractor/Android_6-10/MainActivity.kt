package com.example.iconextractor

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Bundle
import android.os.Environment
import androidx.activity.ComponentActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.io.FileOutputStream

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Проверяем разрешение на запись в /sdcard
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                100
            )
        } else {
            extractIconsAndFinish()
        }
    }

    private fun extractIconsAndFinish() {
        val iconsDir = File(Environment.getExternalStorageDirectory(), "IconExtractor/icons")
        if (!iconsDir.exists()) iconsDir.mkdirs()

        val pm = packageManager
        val packages = pm.getInstalledApplications(0)

        // Многопоточность: количество потоков = числу ядер CPU
        val threadCount = Runtime.getRuntime().availableProcessors()
        val chunkSize = (packages.size + threadCount - 1) / threadCount
        val threads = mutableListOf<Thread>()

        for (i in 0 until threadCount) {
            val start = i * chunkSize
            val end = minOf(start + chunkSize, packages.size)
            if (start >= end) break

            val subList = packages.subList(start, end)
            val t = Thread {
                for (app in subList) {
                    try {
                        val drawable = pm.getApplicationIcon(app)
                        val bitmap = drawableToBitmap(drawable)
                        val file = File(iconsDir, "${app.packageName}.png")
                        FileOutputStream(file).use { out ->
                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
            threads.add(t)
            t.start()
        }

        // Ждём завершения всех потоков
        threads.forEach { it.join() }

        // Завершаем Activity и процесс
        finish()
        android.os.Process.killProcess(android.os.Process.myPid())
        System.exit(0)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 100 && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            extractIconsAndFinish()
        } else {
            // Пользователь не дал разрешение → завершаем Activity и процесс
            finish()
            android.os.Process.killProcess(android.os.Process.myPid())
            System.exit(0)
        }
    }

    // --- Функция безопасного преобразования Drawable в Bitmap ---
    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            drawable.bitmap?.let { return it }
        }

        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}

