// android/app/src/main/kotlin/com/example/asterixia/ARView.kt
package com.example.asterixia

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.opengl.Matrix
import android.view.MotionEvent
import android.view.View
import com.google.ar.core.*
import com.google.ar.core.exceptions.*
import io.flutter.plugin.platform.PlatformView
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.*

class ARView(
    private val context: Context,
    private val id: Int,
    private val creationParams: Map<String, Any>?
) : PlatformView, GLSurfaceView.Renderer {

    private val glSurfaceView: GLSurfaceView
    private var session: Session? = null
    private val backgroundRenderer = BackgroundRenderer()
    
    // Matrices
    private val viewMatrix = FloatArray(16)
    private val projectionMatrix = FloatArray(16)
    private val anchorMatrix = FloatArray(16)
    
    // Renderers
    private val modelLoader = GLBModelLoader(context)
    private val lineRenderer = LineRenderer()
    
    // Scene objects
    private val celestialBodies = mutableListOf<CelestialBody>()
    private val guideLines = mutableListOf<GuideLine>()
    
    private var isSessionConfigured = false
    private var viewportWidth = 0
    private var viewportHeight = 0
    private var rotationAngle = 0f
    private var displayRotation = 0
    
    // Night mode
    private var isNightMode = false
    private var nightModeIntensity = 0.3f // Dim to 30% brightness
    
    // Tap detection
    private var tapCallback: ((String, String) -> Unit)? = null
    private var lastTapTime = 0L
    private val tapTimeout = 300L // 300ms for double tap

    init {
        glSurfaceView = GLSurfaceView(context).apply {
            preserveEGLContextOnPause = true
            setEGLContextClientVersion(2)
            setEGLConfigChooser(8, 8, 8, 8, 16, 0)
            setRenderer(this@ARView)
            renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
            
            // Handle touch events
            setOnTouchListener { v, event ->
                if (event.action == MotionEvent.ACTION_DOWN) {
                    handleTap(event.x, event.y)
                    true
                } else false
            }
        }
        
        ARViewRegistry.registerView(id, this)
    }

    override fun getView(): View = glSurfaceView

    override fun dispose() {
        session?.close()
        ARViewRegistry.unregisterView(id)
    }

    // GLSurfaceView.Renderer methods
    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        
        try {
            backgroundRenderer.createOnGlThread(context)
            modelLoader.initialize()
            lineRenderer.createOnGlThread()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        viewportWidth = width
        viewportHeight = height
        GLES20.glViewport(0, 0, width, height)
        
        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as android.view.WindowManager
        displayRotation = windowManager.defaultDisplay.rotation
        
        session?.setDisplayGeometry(displayRotation, width, height)
    }

    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)

        val session = session ?: return
        
        if (!isSessionConfigured) return

        try {
            session.setCameraTextureName(backgroundRenderer.textureId)
            
            val frame = session.update()
            val camera = frame.camera
            
            if (camera.trackingState == TrackingState.PAUSED) {
                return
            }

            // Draw camera background with night mode filter
            backgroundRenderer.draw(frame, isNightMode, nightModeIntensity)

            // Get camera matrices
            camera.getViewMatrix(viewMatrix, 0)
            camera.getProjectionMatrix(projectionMatrix, 0, 0.1f, 100f)

            // Enable depth testing and blending for glow
            GLES20.glEnable(GLES20.GL_DEPTH_TEST)
            GLES20.glEnable(GLES20.GL_BLEND)
            GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)

            // Update rotation for animated bodies
            rotationAngle += 0.5f
            if (rotationAngle > 360f) rotationAngle -= 360f

            // Calculate glow boost in night mode
            val glowBoost = if (isNightMode) 2.0f else 1.0f

            // Draw celestial bodies using GLB models
            celestialBodies.forEach { body ->
                val modelName = body.type.lowercase()
                
                // Enhanced glow in night mode
                val enhancedGlow = body.glowIntensity * glowBoost
                
                modelLoader.draw(
                    modelName = modelName,
                    viewMatrix = viewMatrix,
                    projectionMatrix = projectionMatrix,
                    position = body.position,
                    scale = body.scale,
                    rotation = if (body.type != "star") rotationAngle else 0f,
                    glowIntensity = enhancedGlow
                )
            }

            // Draw guide lines
            guideLines.forEach { line ->
                lineRenderer.draw(
                    viewMatrix,
                    projectionMatrix,
                    line.points,
                    line.color,
                    line.width
                )
            }

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun configureSession(
        enablePlaneDetection: Boolean,
        enableLightEstimation: Boolean,
        enableAutoFocus: Boolean
    ) {
        try {
            if (session == null) {
                session = Session(context)
            }

            val config = Config(session).apply {
                if (enablePlaneDetection) {
                    planeFindingMode = Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
                } else {
                    planeFindingMode = Config.PlaneFindingMode.DISABLED
                }

                if (enableLightEstimation) {
                    lightEstimationMode = Config.LightEstimationMode.AMBIENT_INTENSITY
                }

                if (enableAutoFocus) {
                    focusMode = Config.FocusMode.AUTO
                }

                depthMode = Config.DepthMode.AUTOMATIC
            }

            session?.configure(config)
            session?.resume()
            isSessionConfigured = true
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun addCelestialBody(
        name: String,
        x: Float,
        y: Float,
        z: Float,
        scale: Float,
        color: FloatArray,
        glowIntensity: Float,
        type: String = "planet",
        realDistance: Double = 0.0 // Distance from Earth in AU or km
    ): String {
        val id = java.util.UUID.randomUUID().toString()
        
        // Scale based on actual distance (logarithmic scale for visibility)
        val adjustedScale = calculateScaleByDistance(scale, realDistance, type)
        
        celestialBodies.add(
            CelestialBody(
                id = id,
                name = name,
                position = floatArrayOf(x, y, z),
                scale = adjustedScale,
                color = color,
                glowIntensity = glowIntensity,
                type = type,
                realDistance = realDistance
            )
        )
        return id
    }
    
    private fun calculateScaleByDistance(baseScale: Float, distance: Double, type: String): Float {
        if (distance == 0.0) return baseScale
        
        return when (type) {
            "star" -> baseScale * 2.0f // Stars are always visible
            "moon" -> baseScale // Moon size is fixed
            else -> {
                // Logarithmic scale for planets based on AU distance
                val logScale = ln(max(1.0, distance)).toFloat()
                baseScale * max(0.3f, 1.0f / (logScale * 0.5f))
            }
        }
    }

    fun addGuideLine(
        name: String,
        points: List<FloatArray>,
        color: FloatArray,
        width: Float
    ): String {
        val id = java.util.UUID.randomUUID().toString()
        guideLines.add(
            GuideLine(
                id = id,
                name = name,
                points = points,
                color = color,
                width = width
            )
        )
        return id
    }
    
    fun setNightMode(enabled: Boolean, intensity: Float = 0.3f) {
        isNightMode = enabled
        nightModeIntensity = intensity.coerceIn(0.1f, 1.0f)
    }
    
    fun setTapCallback(callback: (String, String) -> Unit) {
        tapCallback = callback
    }
    
    private fun handleTap(screenX: Float, screenY: Float) {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastTapTime < tapTimeout) {
            return // Ignore double taps
        }
        lastTapTime = currentTime
        
        // Convert screen coordinates to normalized device coordinates
        val normalizedX = (screenX / viewportWidth) * 2f - 1f
        val normalizedY = -((screenY / viewportHeight) * 2f - 1f)
        
        // Create ray from camera
        val nearPoint = floatArrayOf(normalizedX, normalizedY, -1f, 1f)
        val farPoint = floatArrayOf(normalizedX, normalizedY, 1f, 1f)
        
        val invProjection = FloatArray(16)
        val invView = FloatArray(16)
        Matrix.invertM(invProjection, 0, projectionMatrix, 0)
        Matrix.invertM(invView, 0, viewMatrix, 0)
        
        val nearWorld = FloatArray(4)
        val farWorld = FloatArray(4)
        
        Matrix.multiplyMV(nearWorld, 0, invProjection, 0, nearPoint, 0)
        Matrix.multiplyMV(farWorld, 0, invProjection, 0, farPoint, 0)
        
        // Normalize
        nearWorld[0] /= nearWorld[3]
        nearWorld[1] /= nearWorld[3]
        nearWorld[2] /= nearWorld[3]
        
        farWorld[0] /= farWorld[3]
        farWorld[1] /= farWorld[3]
        farWorld[2] /= farWorld[3]
        
        Matrix.multiplyMV(nearWorld, 0, invView, 0, nearWorld, 0)
        Matrix.multiplyMV(farWorld, 0, invView, 0, farWorld, 0)
        
        // Ray direction
        val rayDir = floatArrayOf(
            farWorld[0] - nearWorld[0],
            farWorld[1] - nearWorld[1],
            farWorld[2] - nearWorld[2]
        )
        
        // Check intersection with celestial bodies
        var closestBody: CelestialBody? = null
        var closestDistance = Float.MAX_VALUE
        
        celestialBodies.forEach { body ->
            val distance = rayIntersectsSphere(
                nearWorld,
                rayDir,
                body.position,
                body.scale * 1.5f // Add some tolerance
            )
            
            if (distance != null && distance < closestDistance) {
                closestDistance = distance
                closestBody = body
            }
        }
        
        // Notify Flutter about the tap
        closestBody?.let { body ->
            tapCallback?.invoke(body.id, body.name)
        }
    }
    
    private fun rayIntersectsSphere(
        rayOrigin: FloatArray,
        rayDir: FloatArray,
        sphereCenter: FloatArray,
        radius: Float
    ): Float? {
        val oc = floatArrayOf(
            rayOrigin[0] - sphereCenter[0],
            rayOrigin[1] - sphereCenter[1],
            rayOrigin[2] - sphereCenter[2]
        )
        
        val a = rayDir[0] * rayDir[0] + rayDir[1] * rayDir[1] + rayDir[2] * rayDir[2]
        val b = 2f * (oc[0] * rayDir[0] + oc[1] * rayDir[1] + oc[2] * rayDir[2])
        val c = oc[0] * oc[0] + oc[1] * oc[1] + oc[2] * oc[2] - radius * radius
        
        val discriminant = b * b - 4 * a * c
        
        if (discriminant < 0) return null
        
        val t = (-b - sqrt(discriminant)) / (2f * a)
        return if (t > 0) t else null
    }

    fun pause() {
        session?.pause()
    }

    fun resume() {
        try {
            session?.resume()
        } catch (e: CameraNotAvailableException) {
            e.printStackTrace()
        }
    }

    data class CelestialBody(
        val id: String,
        val name: String,
        var position: FloatArray,
        val scale: Float,
        val color: FloatArray,
        val glowIntensity: Float,
        val type: String,
        val realDistance: Double = 0.0
    )

    data class GuideLine(
        val id: String,
        val name: String,
        val points: List<FloatArray>,
        val color: FloatArray,
        val width: Float
    )
}

// Background renderer with night mode support
class BackgroundRenderer {
    var textureId = -1
        private set

    private var quadVertices: FloatBuffer? = null
    private var quadTexCoord: FloatBuffer? = null
    private var quadProgram = 0
    private var quadPositionAttrib = 0
    private var quadTexCoordAttrib = 0
    private var nightModeUniform = 0
    private var brightnessUniform = 0

    fun createOnGlThread(context: Context) {
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        textureId = textures[0]
        
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)

        val vertexShader = """
            attribute vec4 a_Position;
            attribute vec2 a_TexCoord;
            varying vec2 v_TexCoord;
            
            void main() {
                gl_Position = a_Position;
                v_TexCoord = a_TexCoord;
            }
        """.trimIndent()

        val fragmentShader = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            varying vec2 v_TexCoord;
            uniform samplerExternalOES u_Texture;
            uniform float u_Brightness;
            uniform bool u_NightMode;
            
            void main() {
                vec4 color = texture2D(u_Texture, v_TexCoord);
                if (u_NightMode) {
                    // Reduce brightness for night mode
                    color.rgb *= u_Brightness;
                }
                gl_FragColor = color;
            }
        """.trimIndent()

        quadProgram = createProgram(vertexShader, fragmentShader)
        quadPositionAttrib = GLES20.glGetAttribLocation(quadProgram, "a_Position")
        quadTexCoordAttrib = GLES20.glGetAttribLocation(quadProgram, "a_TexCoord")
        nightModeUniform = GLES20.glGetUniformLocation(quadProgram, "u_NightMode")
        brightnessUniform = GLES20.glGetUniformLocation(quadProgram, "u_Brightness")

        val coords = floatArrayOf(
            -1f, -1f, 
             1f, -1f, 
            -1f,  1f, 
             1f,  1f
        )
        quadVertices = ByteBuffer.allocateDirect(coords.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(coords)
        quadVertices?.position(0)

        // Rotated texture coordinates to fix orientation
        val texCoords = floatArrayOf(
            1f, 1f,
            1f, 0f,
            0f, 1f,
            0f, 0f
        )
        quadTexCoord = ByteBuffer.allocateDirect(texCoords.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(texCoords)
        quadTexCoord?.position(0)
    }

    fun draw(frame: Frame, nightMode: Boolean = false, brightness: Float = 1.0f) {
        if (frame.hasDisplayGeometryChanged()) {
            val transformedCoords = FloatBuffer.allocate(8)
            frame.transformDisplayUvCoords(quadTexCoord, transformedCoords)
            transformedCoords.position(0)
            
            quadTexCoord?.clear()
            quadTexCoord?.put(transformedCoords)
            quadTexCoord?.position(0)
        }

        GLES20.glDisable(GLES20.GL_DEPTH_TEST)
        GLES20.glDepthMask(false)

        GLES20.glUseProgram(quadProgram)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)

        // Set night mode uniforms
        GLES20.glUniform1i(nightModeUniform, if (nightMode) 1 else 0)
        GLES20.glUniform1f(brightnessUniform, brightness)

        GLES20.glEnableVertexAttribArray(quadPositionAttrib)
        GLES20.glVertexAttribPointer(quadPositionAttrib, 2, GLES20.GL_FLOAT, false, 0, quadVertices)

        GLES20.glEnableVertexAttribArray(quadTexCoordAttrib)
        GLES20.glVertexAttribPointer(quadTexCoordAttrib, 2, GLES20.GL_FLOAT, false, 0, quadTexCoord)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(quadPositionAttrib)
        GLES20.glDisableVertexAttribArray(quadTexCoordAttrib)

        GLES20.glDepthMask(true)
        GLES20.glEnable(GLES20.GL_DEPTH_TEST)
    }

    private fun createProgram(vertexSource: String, fragmentSource: String): Int {
        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource)
        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource)
        
        val program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vertexShader)
        GLES20.glAttachShader(program, fragmentShader)
        GLES20.glLinkProgram(program)
        
        return program
    }

    private fun loadShader(type: Int, source: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)
        return shader
    }
}

// Line renderer remains the same
class LineRenderer {
    private var program = 0
    private var positionAttrib = 0
    private var mvpMatrixUniform = 0
    private var colorUniform = 0

    fun createOnGlThread() {
        val vertexShader = """
            attribute vec4 a_Position;
            uniform mat4 u_MVP;
            
            void main() {
                gl_Position = u_MVP * a_Position;
            }
        """.trimIndent()

        val fragmentShader = """
            precision mediump float;
            uniform vec4 u_Color;
            
            void main() {
                gl_FragColor = u_Color;
            }
        """.trimIndent()

        program = createProgram(vertexShader, fragmentShader)
        positionAttrib = GLES20.glGetAttribLocation(program, "a_Position")
        mvpMatrixUniform = GLES20.glGetUniformLocation(program, "u_MVP")
        colorUniform = GLES20.glGetUniformLocation(program, "u_Color")
    }

    fun draw(
        viewMatrix: FloatArray,
        projectionMatrix: FloatArray,
        points: List<FloatArray>,
        color: FloatArray,
        width: Float
    ) {
        val vertices = mutableListOf<Float>()
        points.forEach { point ->
            vertices.addAll(point.toList())
        }

        val vertexBuffer = ByteBuffer.allocateDirect(vertices.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(vertices.toFloatArray())
        vertexBuffer.position(0)

        val mvpMatrix = FloatArray(16)
        Matrix.multiplyMM(mvpMatrix, 0, projectionMatrix, 0, viewMatrix, 0)

        GLES20.glUseProgram(program)
        GLES20.glLineWidth(width * 100)
        
        GLES20.glEnableVertexAttribArray(positionAttrib)
        GLES20.glVertexAttribPointer(positionAttrib, 3, GLES20.GL_FLOAT, false, 0, vertexBuffer)
        
        GLES20.glUniformMatrix4fv(mvpMatrixUniform, 1, false, mvpMatrix, 0)
        GLES20.glUniform4fv(colorUniform, 1, color, 0)
        
        GLES20.glDrawArrays(GLES20.GL_LINE_STRIP, 0, points.size)
        
        GLES20.glDisableVertexAttribArray(positionAttrib)
    }

    private fun createProgram(vertexSource: String, fragmentSource: String): Int {
        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource)
        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource)
        
        val program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vertexShader)
        GLES20.glAttachShader(program, fragmentShader)
        GLES20.glLinkProgram(program)
        
        return program
    }

    private fun loadShader(type: Int, source: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)
        return shader
    }
}

object ARViewRegistry {
    private val views = mutableMapOf<Int, ARView>()
    
    fun registerView(id: Int, view: ARView) {
        views[id] = view
    }
    
    fun unregisterView(id: Int) {
        views.remove(id)
    }
    
    fun getView(id: Int): ARView? = views[id]
    
    fun getLatestView(): ARView? = views.values.lastOrNull()
}