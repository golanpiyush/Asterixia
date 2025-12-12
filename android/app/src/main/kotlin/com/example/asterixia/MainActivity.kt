// android/app/src/main/kotlin/com/example/asterixia/MainActivity.kt
package com.example.asterixia

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.ar.core.ArCoreApk
import com.google.ar.core.exceptions.UnavailableException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.astronomy.ar/engine"
    private val EVENT_CHANNEL = "com.astronomy.ar/events"
    private val CAMERA_PERMISSION_CODE = 1001

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    
    private val mainHandler = Handler(Looper.getMainLooper())
    private var userRequestedInstall = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkARCoreAvailability()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register ARView platform view factory
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "com.example.astronomy_ar/arview",
                ARViewFactory()
            )

        // Setup Method Channel
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        )
        
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeARSession" -> {
                    val enablePlaneDetection = call.argument<Boolean>("enablePlaneDetection") ?: false
                    val enableLightEstimation = call.argument<Boolean>("enableLightEstimation") ?: true
                    val enableAutoFocus = call.argument<Boolean>("enableAutoFocus") ?: true
                    
                    initializeARSession(
                        enablePlaneDetection,
                        enableLightEstimation,
                        enableAutoFocus,
                        result
                    )
                }
                
                "addCelestialBody" -> {
                    val name = call.argument<String>("name") ?: ""
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    val z = call.argument<Double>("z")?.toFloat() ?: 0f
                    val scale = call.argument<Double>("scale")?.toFloat() ?: 1f
                    val colorInt = (call.argument<Any>("color") as? Number)?.toInt() ?: Color.WHITE
                    val glowIntensity = call.argument<Double>("glowIntensity")?.toFloat() ?: 0.5f
                    val type = call.argument<String>("type") ?: "planet"
                    val realDistance = call.argument<Double>("realDistance") ?: 0.0
                    
                    // Convert Android color to RGBA float array
                    val color = floatArrayOf(
                        Color.red(colorInt) / 255f,
                        Color.green(colorInt) / 255f,
                        Color.blue(colorInt) / 255f,
                        Color.alpha(colorInt) / 255f
                    )
                    
                    val arView = ARViewRegistry.getLatestView()
                    val nodeId = arView?.addCelestialBody(
                        name, x, y, z, scale, color, glowIntensity, type, realDistance
                    )
                    result.success(nodeId ?: "")
                }
                
                "addConstellationLine" -> {
                    val name = call.argument<String>("name") ?: ""
                    val points = call.argument<List<Map<String, Double>>>("points") ?: emptyList()
                    val colorInt = (call.argument<Any>("color") as? Number)?.toInt() ?: Color.WHITE
                    val width = call.argument<Double>("width")?.toFloat() ?: 0.005f
                    
                    // Convert color
                    val color = floatArrayOf(
                        Color.red(colorInt) / 255f,
                        Color.green(colorInt) / 255f,
                        Color.blue(colorInt) / 255f,
                        Color.alpha(colorInt) / 255f
                    )
                    
                    // Convert points to float arrays
                    val floatPoints = points.map { point ->
                        floatArrayOf(
                            point["x"]?.toFloat() ?: 0f,
                            point["y"]?.toFloat() ?: 0f,
                            point["z"]?.toFloat() ?: 0f
                        )
                    }
                    
                    val arView = ARViewRegistry.getLatestView()
                    val nodeId = arView?.addGuideLine(name, floatPoints, color, width)
                    result.success(nodeId ?: "")
                }
                
                "addGuideCircle" -> {
                    val name = call.argument<String>("name") ?: ""
                    val radius = call.argument<Double>("radius") ?: 1.0
                    val colorInt = (call.argument<Any>("color") as? Number)?.toInt() ?: Color.YELLOW
                    val thickness = call.argument<Double>("thickness")?.toFloat() ?: 0.01f
                    
                    // Convert color
                    val color = floatArrayOf(
                        Color.red(colorInt) / 255f,
                        Color.green(colorInt) / 255f,
                        Color.blue(colorInt) / 255f,
                        Color.alpha(colorInt) / 255f
                    )
                    
                    // Create circle points
                    val points = mutableListOf<FloatArray>()
                    val segments = 100
                    for (i in 0..segments) {
                        val angle = (i.toDouble() / segments) * 2.0 * Math.PI
                        val x = radius * Math.cos(angle)
                        val z = radius * Math.sin(angle)
                        points.add(floatArrayOf(x.toFloat(), 0f, z.toFloat()))
                    }
                    
                    val arView = ARViewRegistry.getLatestView()
                    val nodeId = arView?.addGuideLine(name, points, color, thickness)
                    result.success(nodeId ?: "")
                }
                
                "addOrbitalPath" -> {
                    val planetName = call.argument<String>("planetName") ?: ""
                    val centerX = call.argument<Double>("centerX") ?: 0.0
                    val centerY = call.argument<Double>("centerY") ?: 0.0
                    val centerZ = call.argument<Double>("centerZ") ?: 0.0
                    val semiMajorAxis = call.argument<Double>("semiMajorAxis") ?: 1.0
                    val semiMinorAxis = call.argument<Double>("semiMinorAxis") ?: 1.0
                    val inclination = call.argument<Double>("inclination") ?: 0.0
                    val colorInt = (call.argument<Any>("color") as? Number)?.toInt() ?: Color.WHITE
                    
                    // Convert color
                    val color = floatArrayOf(
                        Color.red(colorInt) / 255f,
                        Color.green(colorInt) / 255f,
                        Color.blue(colorInt) / 255f,
                        Color.alpha(colorInt) / 255f
                    )
                    
                    // Create elliptical orbit points
                    val points = mutableListOf<FloatArray>()
                    val segments = 360
                    
                    for (i in 0..segments) {
                        val angle = (i.toDouble() / segments) * 2.0 * Math.PI
                        
                        val x = semiMajorAxis * Math.cos(angle)
                        val z = semiMinorAxis * Math.sin(angle)
                        
                        // Apply inclination
                        val incRad = Math.toRadians(inclination)
                        val y = z * Math.sin(incRad)
                        val zFinal = z * Math.cos(incRad)
                        
                        points.add(floatArrayOf(
                            (centerX + x).toFloat(),
                            (centerY + y).toFloat(),
                            (centerZ + zFinal).toFloat()
                        ))
                    }
                    
                    val arView = ARViewRegistry.getLatestView()
                    val nodeId = arView?.addGuideLine("${planetName}_orbit", points, color, 0.005f)
                    result.success(nodeId ?: "")
                }
                
                "addAxisLine" -> {
                    // Not fully implemented yet - placeholder
                    result.success("")
                }
                
                "addTextLabel" -> {
                    // Not fully implemented yet - placeholder
                    result.success("")
                }
                
                "updateNodePosition" -> {
                    // Not fully implemented yet - placeholder
                    result.success(false)
                }
                
                "removeNode" -> {
                    // Not fully implemented yet - placeholder
                    result.success(false)
                }
                
                "clearAllNodes" -> {
                    // Clear by recreating the AR view
                    result.success(true)
                }
                
                "setNightMode" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val intensity = call.argument<Double>("intensity")?.toFloat() ?: 0.3f
                    
                    val arView = ARViewRegistry.getLatestView()
                    arView?.setNightMode(enabled, intensity)
                    
                    mainHandler.post {
                        eventSink?.success(mapOf(
                            "type" to "nightModeChanged",
                            "data" to mapOf(
                                "enabled" to enabled,
                                "intensity" to intensity
                            )
                        ))
                    }
                    
                    result.success(true)
                }
                
                "pauseSession" -> {
                    ARViewRegistry.getLatestView()?.pause()
                    result.success(null)
                }
                
                "resumeSession" -> {
                    ARViewRegistry.getLatestView()?.resume()
                    result.success(null)
                }
                
                "takeScreenshot" -> {
                    // TODO: Implement screenshot capture
                    result.success(null)
                }
                
                else -> result.notImplemented()
            }
        }

        // Setup Event Channel
        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        )
        
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                
                // Setup tap callback to send events to Flutter
                ARViewRegistry.getLatestView()?.setTapCallback { nodeId, name ->
                    mainHandler.post {
                        events?.success(mapOf(
                            "type" to "celestialBodyTapped",
                            "data" to mapOf(
                                "id" to nodeId,
                                "name" to name
                            )
                        ))
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun checkARCoreAvailability() {
        try {
            when (ArCoreApk.getInstance().checkAvailability(this)) {
                ArCoreApk.Availability.SUPPORTED_INSTALLED -> {
                    // ARCore is installed and ready
                }
                ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD,
                ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED -> {
                    try {
                        val installStatus = ArCoreApk.getInstance()
                            .requestInstall(this, userRequestedInstall)
                        
                        when (installStatus) {
                            ArCoreApk.InstallStatus.INSTALLED -> {
                                // Installation complete
                            }
                            ArCoreApk.InstallStatus.INSTALL_REQUESTED -> {
                                userRequestedInstall = false
                                return
                            }
                        }
                    } catch (e: UnavailableException) {
                        showError("ARCore installation failed: ${e.message}")
                    }
                }
                ArCoreApk.Availability.UNSUPPORTED_DEVICE_NOT_CAPABLE -> {
                    showError("This device does not support AR")
                }
                else -> {
                    showError("ARCore availability unknown")
                }
            }
        } catch (e: Exception) {
            showError("Error checking ARCore: ${e.message}")
        }
    }

    private fun initializeARSession(
        enablePlaneDetection: Boolean,
        enableLightEstimation: Boolean,
        enableAutoFocus: Boolean,
        result: MethodChannel.Result
    ) {
        // Check camera permission first
        if (!hasCameraPermission()) {
            requestCameraPermission()
            result.error("PERMISSION_DENIED", "Camera permission not granted", null)
            return
        }

        try {
            val arView = ARViewRegistry.getLatestView()
            if (arView != null) {
                // Configure the AR session
                arView.configureSession(
                    enablePlaneDetection,
                    enableLightEstimation,
                    enableAutoFocus
                )
                
                // Send success event to Flutter
                mainHandler.post {
                    eventSink?.success(mapOf(
                        "type" to "sessionInitialized",
                        "data" to mapOf("success" to true)
                    ))
                }
                
                result.success(true)
            } else {
                result.error("NO_VIEW", "AR view not found. Make sure ARViewWidget is displayed first.", null)
            }
        } catch (e: Exception) {
            result.error("INIT_ERROR", "Error initializing AR: ${e.message}", null)
        }
    }

    private fun hasCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestCameraPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == CAMERA_PERMISSION_CODE) {
            if (grantResults.isNotEmpty() && 
                grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                mainHandler.post {
                    Toast.makeText(this, "Camera permission granted. Please try again.", Toast.LENGTH_SHORT).show()
                    
                    eventSink?.success(mapOf(
                        "type" to "permissionGranted",
                        "data" to mapOf("permission" to "camera")
                    ))
                }
            } else {
                showError("Camera permission is required for AR functionality")
            }
        }
    }

    override fun onResume() {
        super.onResume()
        ARViewRegistry.getLatestView()?.resume()
    }

    override fun onPause() {
        super.onPause()
        ARViewRegistry.getLatestView()?.pause()
    }

    private fun showError(message: String) {
        mainHandler.post {
            Toast.makeText(this, message, Toast.LENGTH_LONG).show()
            
            eventSink?.success(mapOf(
                "type" to "error",
                "data" to mapOf("message" to message)
            ))
        }
    }
}