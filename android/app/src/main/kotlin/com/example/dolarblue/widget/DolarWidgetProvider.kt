package com.example.dolarblue.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.rodrigodesarrollador.dolarblue.R
import java.text.SimpleDateFormat
import java.util.*

class DolarWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.dolar_widget)

            // Leer datos desde SharedPreferences (escritas por Flutter)
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val blueSell = prefs.getString("widget_blue_sell", "\$---") ?: "\$---"
            val oficialSell = prefs.getString("widget_oficial_sell", "\$---") ?: "\$---"
            val updateTime = prefs.getString("widget_update_time", "--:--") ?: "--:--"

            views.setTextViewText(R.id.widget_blue_sell, blueSell)
            views.setTextViewText(R.id.widget_oficial_sell, oficialSell)
            views.setTextViewText(R.id.widget_update_time, "Actualizado: $updateTime")

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
