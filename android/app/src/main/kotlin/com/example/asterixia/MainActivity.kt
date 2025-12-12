// android/app/src/main/kotlin/com/astronomy/ar/MainActivity.kt
package com.example.asterixia

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.ar.core.ArCoreApk
import com.google.ar.core.exceptions.UnavailableException
import com.example.asterixia.AREngineHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.opengl.GLSurfaceView
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import android.os.Handler
import android.os.Looper

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.astronomy.ar/engine"
    private val EVENT_CHANNEL = "com.astronomy.ar/events"
    private val CAMERA_PERMISSION_CODE = 1001

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    
    private var arEngineHandler: AREngineHandler? = null
    private var glSurfaceView: GLSurfaceView? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    
    private var isARSessionActive = false
    private var userRequestedInstall = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check ARCore availability
        checkARCoreAvailability()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup Method Channel
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        )
        
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeARSession" -> {
                    val enablePlaneDetection = call.argument<Boolean>("enablePlaneDetection") ?: true
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
                    val x = call.argument<Double>("x") ?: 0.0
                    val y = call.argument<Double>("y") ?: 0.0
                    val z = call.argument<Double>("z") ?: 0.0
                    val scale = call.argument<Double>("scale") ?: 1.0
                    val color = call.argument<Int>("color") ?: Color.WHITE
                    val type = call.argument<String>("type") ?: "planet"
                    val glowIntensity = call.argument<Double>("glowIntensity") ?: 0.5
                    
                    val nodeId = arEngineHandler?.addCelestialBody(
                        name, x, y, z, scale, color, type, glowIntensity
                    )
                    result.success(nodeId)
                }
                
                "addAxisLine" -> {
                    val name = call.argument<String>("name") ?: ""
                    val bodyName = call.argument<String>("bodyName") ?: ""
                    val length = call.argument<Double>("length") ?: 1.0
                    val tilt = call.argument<Double>("tilt") ?: 0.0
                    val color = call.argument<Int>("color") ?: Color.CYAN
                    val showRotation = call.argument<Boolean>("showRotation") ?: true
                    
                    val nodeId = arEngineHandler?.addAxisLine(
                        name, bodyName, length, tilt, color, showRotation
                    )
                    result.success(nodeId)
                }
                
                "addOrbitalPath" -> {
                    val planetName = call.argument<String>("planetName") ?: ""
                    val centerX = call.argument<Double>("centerX") ?: 0.0
                    val centerY = call.argument<Double>("centerY") ?: 0.0
                    val centerZ = call.argument<Double>("centerZ") ?: 0.0
                    val semiMajorAxis = call.argument<Double>("semiMajorAxis") ?: 1.0
                    val semiMinorAxis = call.argument<Double>("semiMinorAxis") ?: 1.0
                    val inclination = call.argument<Double>("inclination") ?: 0.0
                    val color = call.argument<Int>("color") ?: Color.WHITE
                    
                    val nodeId = arEngineHandler?.addOrbitalPath(
                        planetName, centerX, centerY, centerZ,
                        semiMajorAxis, semiMinorAxis, inclination, color
                    )
                    result.success(nodeId)
                }
                
                "addConstellationLine" -> {
                    val name = call.argument<String>("name") ?: ""
                    val points = call.argument<List<Map<String, Double>>>("points") ?: emptyList()
                    val color = call.argument<Int>("color") ?: Color.WHITE
                    val width = call.argument<Double>("width") ?: 0.005
                    
                    val nodeId = arEngineHandler?.addGuideLine(
                        name, points, color, width, false
                    )
                    result.success(nodeId)
                }
                
                "addGuideCircle" -> {
                    val name = call.argument<String>("name") ?: ""
                    val radius = call.argument<Double>("radius") ?: 1.0
                    val color = call.argument<Int>("color") ?: Color.YELLOW
                    val thickness = call.argument<Double>("thickness") ?: 0.01
                    val tilt = call.argument<Double>("tilt") ?: 0.0
                    val rotation = call.argument<Double>("rotation") ?: 0.0
                    
                    // Create circle points
                    val points = mutableListOf<Map<String, Double>>()
                    val segments = 360
                    for (i in 0 until segments) {
                        val angle = (i * 360.0 / segments) * Math.PI / 180.0
                        val x = radius * Math.cos(angle)
                        val z = radius * Math.sin(angle)
                        points.add(mapOf("x" to x, "y" to 0.0, "z" to z))
                    }
                    points.add(points[0]) // Close the circle
                    
                    val nodeId = arEngineHandler?.addGuideLine(
                        name, points, color, thickness, false
                    )
                    result.success(nodeId)
                }
                
                "addTextLabel" -> {
                    val text = call.argument<String>("text") ?: ""
                    val x = call.argument<Double>("x") ?: 0.0
                    val y = call.argument<Double>("y") ?: 0.0
                    val z = call.argument<Double>("z") ?: 0.0
                    val color = call.argument<Int>("color") ?: Color.WHITE
                    val fontSize = call.argument<Double>("fontSize") ?: 0.1
                    val billboarding = call.argument<Boolean>("billboarding") ?: true
                    
                    val nodeId = arEngineHandler?.addTextLabel(
                        text, x, y, z, color, fontSize, billboarding
                    )
                    result.success(nodeId)
                }
                
                "updateNodePosition" -> {
                    val nodeId = call.argument<String>("nodeId") ?: ""
                    val x = call.argument<Double>("x") ?: 0.0
                    val y = call.argument<Double>("y") ?: 0.0
                    val z = call.argument<Double>("z") ?: 0.0
                    
                    val success = arEngineHandler?.updateNodePosition(nodeId, x, y, z) ?: false
                    result.success(success)
                }
                
                "removeNode" -> {
                    val nodeId = call.argument<String>("nodeId") ?: ""
                    val success = arEngineHandler?.removeNode(nodeId) ?: false
                    result.success(success)
                }
                
                "clearAllNodes" -> {
                    arEngineHandler?.clearAllNodes()
                    result.success(true)
                }
                
                "pauseSession" -> {
                    arEngineHandler?.pauseSession()
                    result.success(null)
                }
                
                "resumeSession" -> {
                    arEngineHandler?.resumeSession()
                    result.success(null)
                }
                
                "takeScreenshot" -> {
                    // TODO: Implement screenshot capture
                    result.success(null)
                }
                
                "setNightMode" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val intensity = call.argument<Double>("intensity") ?: 0.8
                    // TODO: Implement night mode filter
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
                arEngineHandler?.setEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                arEngineHandler?.setEventSink(null)
            }
        })
    }

    private fun checkARCoreAvailability() {
        try {
            when (ArCoreApk.getInstance().checkAvailability(this)) {
                ArCoreApk.Availability.SUPPORTED_INSTALLED -> {
                    // ARCore is installed and supported
                }
                ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD,
                ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED -> {
                    // Request ARCore installation
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
        // Check camera permission
        if (!hasCameraPermission()) {
            requestCameraPermission()
            result.error("PERMISSION_DENIED", "Camera permission not granted", null)
            return
        }

        try {
            // Initialize AR Engine Handler
            if (arEngineHandler == null) {
                arEngineHandler = AREngineHandler(this)
            }

            // Initialize AR session
            val success = arEngineHandler?.initializeSession(
                enablePlaneDetection,
                enableLightEstimation,
                enableAutoFocus
            ) ?: false

            if (success) {
                isARSessionActive = true
                setupRenderLoop()
                result.success(true)
            } else {
                result.error("INIT_FAILED", "Failed to initialize AR session", null)
            }
        } catch (e: Exception) {
            result.error("INIT_ERROR", "Error initializing AR: ${e.message}", null)
        }
    }

    private fun setupRenderLoop() {
        // Create GLSurfaceView for rendering
        glSurfaceView = GLSurfaceView(this).apply {
            setEGLContextClientVersion(2)
            setEGLConfigChooser(8, 8, 8, 8, 16, 0)
            setRenderer(object : GLSurfaceView.Renderer {
                private var lastFrameTime = System.currentTimeMillis()

                override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
                    // OpenGL initialization
                }

                override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
                    // Handle surface changes
                }

                override fun onDrawFrame(gl: GL10?) {
                    val currentTime = System.currentTimeMillis()
                    val deltaTime = (currentTime - lastFrameTime) / 1000f
                    lastFrameTime = currentTime

                    // Update AR session
                    arEngineHandler?.update(deltaTime)
                    
                    // Render AR content
                    arEngineHandler?.render()
                }
            })
            renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
        }

        // Note: In a real implementation, you'd need to properly integrate
        // this with Flutter's rendering pipeline or use a platform view
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
                Toast.makeText(this, "Camera permission granted", Toast.LENGTH_SHORT).show()
            } else {
                showError("Camera permission is required for AR")
            }
        }
    }

    override fun onResume() {
        super.onResume()
        
        if (isARSessionActive) {
            arEngineHandler?.resumeSession()
            glSurfaceView?.onResume()
        }
    }

    override fun onPause() {
        super.onPause()
        
        if (isARSessionActive) {
            arEngineHandler?.pauseSession()
            glSurfaceView?.onPause()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        
        arEngineHandler?.dispose()
        arEngineHandler = null
        isARSessionActive = false
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