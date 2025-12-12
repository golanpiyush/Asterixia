// android/app/src/main/kotlin/com/example/asterixia/ARViewFactory.kt
package com.example.asterixia

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class ARViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any>
        return ARView(context!!, viewId, creationParams)
    }
}
