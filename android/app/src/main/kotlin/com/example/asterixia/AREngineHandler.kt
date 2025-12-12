// android/app/src/main/kotlin/com/astronomy/ar/AREngineHandler.kt
package com.example.asterixia

import android.content.Context
import android.graphics.Color
import android.opengl.GLES20
import android.opengl.Matrix
import com.google.ar.core.*
import com.google.ar.core.exceptions.*
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.*

class AREngineHandler(private val context: Context) {
    private var session: Session? = null
    private var config: Config? = null
    private val celestialBodies = mutableMapOf<String, CelestialNode>()
    private val axisLines = mutableMapOf<String, AxisLine>()
    private val guideLines = mutableMapOf<String, GuideLine>()
    private var eventSink: EventChannel.EventSink? = null
    
    // Camera and rendering
    private val viewMatrix = FloatArray(16)
    private val projectionMatrix = FloatArray(16)
    private var isSessionInitialized = false

    // MARK: - Session Management
    
    fun initializeSession(
        enablePlaneDetection: Boolean,
        enableLightEstimation: Boolean,
        enableAutoFocus: Boolean
    ): Boolean {
        return try {
            if (session == null) {
                session = Session(context)
            }
            
            config = Config(session).apply {
                if (enablePlaneDetection) {
                    planeFindingMode = Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
                }
                
                if (enableLightEstimation) {
                    lightEstimationMode = Config.LightEstimationMode.AMBIENT_INTENSITY
                }
                
                if (enableAutoFocus) {
                    focusMode = Config.FocusMode.AUTO
                }
                
                // Enable depth for better occlusion
                depthMode = Config.DepthMode.AUTOMATIC
            }
            
            session?.configure(config)
            session?.resume()
            
            isSessionInitialized = true
            sendEvent("sessionInitialized", mapOf("success" to true))
            true
        } catch (e: Exception) {
            sendEvent("error", mapOf("message" to e.message.orEmpty()))
            false
        }
    }

    fun pauseSession() {
        session?.pause()
    }

    fun resumeSession() {
        session?.resume()
    }

    // MARK: - Celestial Bodies
    
    fun addCelestialBody(
        name: String,
        x: Double,
        y: Double,
        z: Double,
        scale: Double,
        color: Int,
        type: String,
        glowIntensity: Double
    ): String {
        val nodeId = java.util.UUID.randomUUID().toString()
        
        val celestialNode = CelestialNode(
            id = nodeId,
            name = name,
            position = floatArrayOf(x.toFloat(), y.toFloat(), z.toFloat()),
            scale = scale.toFloat(),
            color = color,
            type = type,
            glowIntensity = glowIntensity.toFloat()
        )
        
        celestialBodies[nodeId] = celestialNode
        return nodeId
    }

    // MARK: - Axis Lines (Planetary and Solar)
    
    fun addAxisLine(
        name: String,
        bodyName: String,
        length: Double,
        tilt: Double,
        color: Int,
        showRotation: Boolean = true
    ): String {
        val nodeId = java.util.UUID.randomUUID().toString()
        
        val axisLine = AxisLine(
            id = nodeId,
            name = name,
            attachedTo = bodyName,
            length = length.toFloat(),
            tilt = tilt.toFloat(),
            color = color,
            showRotation = showRotation
        )
        
        axisLines[nodeId] = axisLine
        return nodeId
    }

    // MARK: - Guide Lines (Orbits, Ecliptic, etc.)
    
    fun addGuideLine(
        name: String,
        points: List<Map<String, Double>>,
        color: Int,
        width: Double,
        isDashed: Boolean = false
    ): String {
        val nodeId = java.util.UUID.randomUUID().toString()
        
        val positions = points.map { point ->
            floatArrayOf(
                point["x"]?.toFloat() ?: 0f,
                point["y"]?.toFloat() ?: 0f,
                point["z"]?.toFloat() ?: 0f
            )
        }
        
        val guideLine = GuideLine(
            id = nodeId,
            name = name,
            points = positions,
            color = color,
            width = width.toFloat(),
            isDashed = isDashed
        )
        
        guideLines[nodeId] = guideLine
        return nodeId
    }

    // MARK: - Orbital Path Creation
    
    fun addOrbitalPath(
        planetName: String,
        centerX: Double,
        centerY: Double,
        centerZ: Double,
        semiMajorAxis: Double,
        semiMinorAxis: Double,
        inclination: Double,
        color: Int
    ): String {
        val points = mutableListOf<Map<String, Double>>()
        val segments = 360
        
        for (i in 0 until segments) {
            val angle = (i * 360.0 / segments) * PI / 180.0
            
            // Calculate position on ellipse
            val x = semiMajorAxis * cos(angle)
            val z = semiMinorAxis * sin(angle)
            
            // Apply inclination
            val incRad = inclination * PI / 180.0
            val y = z * sin(incRad)
            val zFinal = z * cos(incRad)
            
            points.add(mapOf(
                "x" to (centerX + x),
                "y" to (centerY + y),
                "z" to (centerZ + zFinal)
            ))
        }
        
        // Close the orbit
        if (points.isNotEmpty()) {
            points.add(points[0])
        }
        
        return addGuideLine("${planetName}_orbit", points, color, 0.005)
    }

    // MARK: - Text Labels
    
    fun addTextLabel(
        text: String,
        x: Double,
        y: Double,
        z: Double,
        color: Int,
        fontSize: Double,
        billboarding: Boolean
    ): String {
        val nodeId = java.util.UUID.randomUUID().toString()
        
        val label = TextLabel(
            id = nodeId,
            text = text,
            position = floatArrayOf(x.toFloat(), y.toFloat(), z.toFloat()),
            color = color,
            fontSize = fontSize.toFloat(),
            billboarding = billboarding
        )
        
        // Store in a separate collection if needed
        return nodeId
    }

    // MARK: - Update and Render
    
    fun update(deltaTime: Float) {
        if (!isSessionInitialized) return
        
        try {
            val frame = session?.update() ?: return
            
            // Update camera transform
            val camera = frame.camera
            camera.getViewMatrix(viewMatrix, 0)
            camera.getProjectionMatrix(projectionMatrix, 0, 0.1f, 100f)
            
            // Update celestial body positions (for real-time calculations)
            updateCelestialPositions(System.currentTimeMillis())
            
            // Update axis rotations
            updateAxisRotations(deltaTime)
            
            // Send camera transform event
            val position = getCameraPosition()
            sendEvent("cameraTransform", mapOf(
                "x" to position[0],
                "y" to position[1],
                "z" to position[2]
            ))
            
        } catch (e: Exception) {
            sendEvent("error", mapOf("message" to "Update error: ${e.message}"))
        }
    }

    private fun updateCelestialPositions(timestamp: Long) {
        // This would be called with positions calculated from AstronomyService
        // For now, just update stored positions
    }

    private fun updateAxisRotations(deltaTime: Float) {
        axisLines.forEach { (_, axis) ->
            if (axis.showRotation) {
                axis.rotationAngle += deltaTime * axis.rotationSpeed
                if (axis.rotationAngle > 360f) axis.rotationAngle -= 360f
            }
        }
    }

    fun render() {
        if (!isSessionInitialized) return
        
        // Clear screen
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)
        
        // Render celestial bodies
        celestialBodies.forEach { (_, body) ->
            renderCelestialBody(body)
        }
        
        // Render axis lines
        axisLines.forEach { (_, axis) ->
            renderAxisLine(axis)
        }
        
        // Render guide lines
        guideLines.forEach { (_, line) ->
            renderGuideLine(line)
        }
    }

    private fun renderCelestialBody(body: CelestialNode) {
        val modelMatrix = FloatArray(16)
        Matrix.setIdentityM(modelMatrix, 0)
        Matrix.translateM(modelMatrix, 0, body.position[0], body.position[1], body.position[2])
        Matrix.scaleM(modelMatrix, 0, body.scale, body.scale, body.scale)
        
        // Render sphere with body's properties
        renderSphere(modelMatrix, body.color, body.glowIntensity)
    }

    private fun renderAxisLine(axis: AxisLine) {
        val attachedBody = celestialBodies.values.find { it.name == axis.attachedTo } ?: return
        
        val modelMatrix = FloatArray(16)
        Matrix.setIdentityM(modelMatrix, 0)
        
        // Position at body's location
        Matrix.translateM(modelMatrix, 0, 
            attachedBody.position[0], 
            attachedBody.position[1], 
            attachedBody.position[2])
        
        // Apply tilt
        Matrix.rotateM(modelMatrix, 0, axis.tilt, 1f, 0f, 0f)
        
        // Apply rotation animation
        if (axis.showRotation) {
            Matrix.rotateM(modelMatrix, 0, axis.rotationAngle, 0f, 1f, 0f)
        }
        
        // Render line from center upward and downward
        val halfLength = axis.length / 2
        renderLine(
            modelMatrix,
            floatArrayOf(0f, -halfLength, 0f),
            floatArrayOf(0f, halfLength, 0f),
            axis.color,
            0.01f
        )
    }

    private fun renderGuideLine(line: GuideLine) {
        for (i in 0 until line.points.size - 1) {
            val start = line.points[i]
            val end = line.points[i + 1]
            
            val modelMatrix = FloatArray(16)
            Matrix.setIdentityM(modelMatrix, 0)
            
            renderLine(modelMatrix, start, end, line.color, line.width)
        }
    }

    // MARK: - Rendering Primitives
    
    private fun renderSphere(modelMatrix: FloatArray, color: Int, glowIntensity: Float) {
        // Implementation using OpenGL ES
        // Create sphere mesh and render with shader
    }

    private fun renderLine(
        modelMatrix: FloatArray,
        start: FloatArray,
        end: FloatArray,
        color: Int,
        width: Float
    ) {
        // Implementation using OpenGL ES
        // Create line geometry and render
    }

    // MARK: - Node Management
    
    fun updateNodePosition(nodeId: String, x: Double, y: Double, z: Double): Boolean {
        celestialBodies[nodeId]?.let {
            it.position = floatArrayOf(x.toFloat(), y.toFloat(), z.toFloat())
            return true
        }
        return false
    }

    fun removeNode(nodeId: String): Boolean {
        return celestialBodies.remove(nodeId) != null ||
               axisLines.remove(nodeId) != null ||
               guideLines.remove(nodeId) != null
    }

    fun clearAllNodes() {
        celestialBodies.clear()
        axisLines.clear()
        guideLines.clear()
    }

    // MARK: - Utility Functions
    
    private fun getCameraPosition(): FloatArray {
        val position = FloatArray(3)
        Matrix.multiplyMV(FloatArray(4), 0, viewMatrix, 0, floatArrayOf(0f, 0f, 0f, 1f), 0)
        return position
    }

    private fun sendEvent(type: String, data: Map<String, Any>) {
        eventSink?.success(mapOf(
            "type" to type,
            "data" to data
        ))
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun dispose() {
        session?.close()
        session = null
        clearAllNodes()
    }
}

// MARK: - Data Classes

data class CelestialNode(
    val id: String,
    val name: String,
    var position: FloatArray,
    val scale: Float,
    val color: Int,
    val type: String,
    val glowIntensity: Float
)

data class AxisLine(
    val id: String,
    val name: String,
    val attachedTo: String,
    val length: Float,
    val tilt: Float,
    val color: Int,
    val showRotation: Boolean,
    var rotationAngle: Float = 0f,
    val rotationSpeed: Float = 10f // degrees per second
)

data class GuideLine(
    val id: String,
    val name: String,
    val points: List<FloatArray>,
    val color: Int,
    val width: Float,
    val isDashed: Boolean
)

data class TextLabel(
    val id: String,
    val text: String,
    var position: FloatArray,
    val color: Int,
    val fontSize: Float,
    val billboarding: Boolean
)