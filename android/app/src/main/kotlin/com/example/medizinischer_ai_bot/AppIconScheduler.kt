package com.example.medizinischer_ai_bot

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

internal object AppIconScheduler {
    private const val preferencesName = "medi_app_icon"
    private const val lastOpenedKey = "last_opened_at"
    private const val workName = "medi_sad_app_icon"
    private const val inactiveAfterDays = 7L

    fun onAppOpened(context: Context) {
        val appContext = context.applicationContext
        val now = System.currentTimeMillis()
        appContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putLong(lastOpenedKey, now)
            .apply()
        setIcon(appContext, sad = false)
        schedule(appContext, INACTIVE_DELAY_MILLIS)
    }

    fun updateIfInactive(context: Context) {
        val appContext = context.applicationContext
        val preferences =
            appContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val lastOpened = preferences.getLong(lastOpenedKey, 0L)
        if (lastOpened == 0L) return

        val remaining = INACTIVE_DELAY_MILLIS -
            (System.currentTimeMillis() - lastOpened)
        if (remaining <= 0L) {
            setIcon(appContext, sad = true)
        } else {
            schedule(appContext, remaining)
        }
    }

    private fun schedule(context: Context, delayMillis: Long) {
        val request = OneTimeWorkRequestBuilder<AppIconWorker>()
            .setInitialDelay(delayMillis, TimeUnit.MILLISECONDS)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            workName,
            ExistingWorkPolicy.REPLACE,
            request,
        )
    }

    private fun setIcon(context: Context, sad: Boolean) {
        val packageName = context.packageName
        val normal = ComponentName(packageName, "$packageName.MainActivityDefault")
        val sadIcon = ComponentName(packageName, "$packageName.MainActivitySad")
        val packageManager = context.packageManager
        val enable = if (sad) sadIcon else normal
        val disable = if (sad) normal else sadIcon

        packageManager.setComponentEnabledSetting(
            enable,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        packageManager.setComponentEnabledSetting(
            disable,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP,
        )
    }

    private const val INACTIVE_DELAY_MILLIS =
        inactiveAfterDays * 24L * 60L * 60L * 1000L
}

internal class AppIconWorker(
    context: Context,
    parameters: WorkerParameters,
) : Worker(context, parameters) {
    override fun doWork(): Result {
        return try {
            AppIconScheduler.updateIfInactive(applicationContext)
            Result.success()
        } catch (error: SecurityException) {
            Log.e("MediAppIcon", "Unable to update launcher icon permissions", error)
            Result.retry()
        } catch (error: IllegalArgumentException) {
            Log.e("MediAppIcon", "Unable to resolve launcher icon component", error)
            Result.failure()
        }
    }
}
