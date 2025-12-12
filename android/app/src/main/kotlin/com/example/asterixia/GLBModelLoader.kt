// android/app/src/main/kotlin/com/example/asterixia/GLBModelLoader.kt
package com.example.asterixia

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.opengl.GLES20
import android.opengl.GLUtils
import android.opengl.Matrix
import java.io.InputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.nio.ShortBuffer

class GLBModelLoader(private val context: Context) {
    private val models = mutableMapOf<String, GLBModel>()
    private var program = 0
    private var positionAttrib = 0
    private var texCoordAttrib = 0
    private var normalAttrib = 0
    private var mvpMatrixUniform = 0
    private var textureUniform = 0
    private var lightPosUniform = 0
    private var colorUniform = 0
    private var glowUniform = 0

    fun initialize() {
        createShaderProgram()
        loadPlanetModels()
    }

    private fun createShaderProgram() {
        val vertexShader = """
            attribute vec4 a_Position;
            attribute vec2 a_TexCoord;
            attribute vec3 a_Normal;
            
            uniform mat4 u_MVP;
            uniform vec3 u_LightPos;
            
            varying vec2 v_TexCoord;
            varying vec3 v_Normal;
            varying vec3 v_LightDir;
            varying float v_Distance;
            
            void main() {
                gl_Position = u_MVP * a_Position;
                v_TexCoord = a_TexCoord;
                v_Normal = a_Normal;
                v_LightDir = normalize(u_LightPos - a_Position.xyz);
                v_Distance = length(a_Position.xyz);
            }
        """.trimIndent()

        val fragmentShader = """
            precision mediump float;
            
            varying vec2 v_TexCoord;
            varying vec3 v_Normal;
            varying vec3 v_LightDir;
            varying float v_Distance;
            
            uniform sampler2D u_Texture;
            uniform vec4 u_Color;
            uniform float u_Glow;
            
            void main() {
                vec4 texColor = texture2D(u_Texture, v_TexCoord);
                vec3 normal = normalize(v_Normal);
                
                // Diffuse lighting
                float diffuse = max(dot(normal, v_LightDir), 0.3);
                
                // Rim lighting effect for glow
                vec3 viewDir = normalize(-vec3(0.0, 0.0, v_Distance));
                float rim = 1.0 - max(dot(viewDir, normal), 0.0);
                rim = pow(rim, 3.0);
                
                // Combine lighting with glow
                vec3 finalColor = texColor.rgb * u_Color.rgb * diffuse;
                finalColor += texColor.rgb * u_Glow * rim;
                
                // Add ambient glow
                finalColor += texColor.rgb * u_Glow * 0.5;
                
                gl_FragColor = vec4(finalColor, texColor.a * u_Color.a);
            }
        """.trimIndent()

        program = createProgram(vertexShader, fragmentShader)
        positionAttrib = GLES20.glGetAttribLocation(program, "a_Position")
        texCoordAttrib = GLES20.glGetAttribLocation(program, "a_TexCoord")
        normalAttrib = GLES20.glGetAttribLocation(program, "a_Normal")
        mvpMatrixUniform = GLES20.glGetUniformLocation(program, "u_MVP")
        textureUniform = GLES20.glGetUniformLocation(program, "u_Texture")
        lightPosUniform = GLES20.glGetUniformLocation(program, "u_LightPos")
        colorUniform = GLES20.glGetUniformLocation(program, "u_Color")
        glowUniform = GLES20.glGetUniformLocation(program, "u_Glow")
    }

    private fun loadPlanetModels() {
        val planetNames = listOf(
            "sun", "mercury", "venus", "earth", "mars",
            "jupiter", "saturn", "uranus", "neptune", "moon"
        )

        planetNames.forEach { name ->
            try {
                loadModel(name)
            } catch (e: Exception) {
                android.util.Log.e("GLBModelLoader", "Failed to load $name: ${e.message}")
                createFallbackSphere(name)
            }
        }
    }

    private fun loadModel(name: String) {
        try {
            val inputStream = context.assets.open("models/$name.glb")
            val model = parseGLB(inputStream, name)
            models[name] = model
            inputStream.close()
        } catch (e: Exception) {
            android.util.Log.w("GLBModelLoader", "GLB not found for $name, using fallback")
            createFallbackSphere(name)
        }
    }

    private fun parseGLB(inputStream: InputStream, name: String): GLBModel {
        val vertices = createSphereVertices(1f, 30, 30)
        val texCoords = createSphereTexCoords(30, 30)
        val normals = createSphereNormals(1f, 30, 30)
        val indices = createSphereIndices(30, 30)
        val textureId = loadTexture(name)

        return GLBModel(
            name = name,
            vertices = createFloatBuffer(vertices),
            texCoords = createFloatBuffer(texCoords),
            normals = createFloatBuffer(normals),
            indices = createShortBuffer(indices),
            indexCount = indices.size,
            textureId = textureId
        )
    }

    private fun createFallbackSphere(name: String) {
        val vertices = createSphereVertices(1f, 20, 20)
        val texCoords = createSphereTexCoords(20, 20)
        val normals = createSphereNormals(1f, 20, 20)
        val indices = createSphereIndices(20, 20)
        val textureId = loadTexture(name)

        models[name] = GLBModel(
            name = name,
            vertices = createFloatBuffer(vertices),
            texCoords = createFloatBuffer(texCoords),
            normals = createFloatBuffer(normals),
            indices = createShortBuffer(indices),
            indexCount = indices.size,
            textureId = textureId
        )
    }

    private fun createSphereVertices(radius: Float, latBands: Int, longBands: Int): FloatArray {
        val vertices = mutableListOf<Float>()
        
        for (lat in 0..latBands) {
            val theta = lat * Math.PI / latBands
            val sinTheta = Math.sin(theta).toFloat()
            val cosTheta = Math.cos(theta).toFloat()

            for (long in 0..longBands) {
                val phi = long * 2 * Math.PI / longBands
                val sinPhi = Math.sin(phi).toFloat()
                val cosPhi = Math.cos(phi).toFloat()

                val x = cosPhi * sinTheta
                val y = cosTheta
                val z = sinPhi * sinTheta

                vertices.add(radius * x)
                vertices.add(radius * y)
                vertices.add(radius * z)
            }
        }

        return vertices.toFloatArray()
    }

    private fun createSphereTexCoords(latBands: Int, longBands: Int): FloatArray {
        val texCoords = mutableListOf<Float>()
        
        for (lat in 0..latBands) {
            for (long in 0..longBands) {
                texCoords.add(long.toFloat() / longBands)
                texCoords.add(lat.toFloat() / latBands)
            }
        }

        return texCoords.toFloatArray()
    }

    private fun createSphereNormals(radius: Float, latBands: Int, longBands: Int): FloatArray {
        val normals = mutableListOf<Float>()
        
        for (lat in 0..latBands) {
            val theta = lat * Math.PI / latBands
            val sinTheta = Math.sin(theta).toFloat()
            val cosTheta = Math.cos(theta).toFloat()

            for (long in 0..longBands) {
                val phi = long * 2 * Math.PI / longBands
                val sinPhi = Math.sin(phi).toFloat()
                val cosPhi = Math.cos(phi).toFloat()

                normals.add(cosPhi * sinTheta)
                normals.add(cosTheta)
                normals.add(sinPhi * sinTheta)
            }
        }

        return normals.toFloatArray()
    }

    private fun createSphereIndices(latBands: Int, longBands: Int): ShortArray {
        val indices = mutableListOf<Short>()
        
        for (lat in 0 until latBands) {
            for (long in 0 until longBands) {
                val first = (lat * (longBands + 1) + long).toShort()
                val second = (first + longBands + 1).toShort()

                indices.add(first)
                indices.add(second)
                indices.add((first + 1).toShort())

                indices.add(second)
                indices.add((second + 1).toShort())
                indices.add((first + 1).toShort())
            }
        }

        return indices.toShortArray()
    }

    private fun loadTexture(name: String): Int {
        val textureIds = IntArray(1)
        GLES20.glGenTextures(1, textureIds, 0)
        val textureId = textureIds[0]

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_REPEAT)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_REPEAT)

        try {
            val inputStream = context.assets.open("textures/$name.png")
            val bitmap = BitmapFactory.decodeStream(inputStream)
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
            bitmap.recycle()
            inputStream.close()
        } catch (e: Exception) {
            android.util.Log.w("GLBModelLoader", "Texture not found for $name")
            createSolidColorTexture(textureId, getDefaultColor(name))
        }

        return textureId
    }

    private fun createSolidColorTexture(textureId: Int, color: Int) {
        val bitmap = Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(color)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
        bitmap.recycle()
    }

    private fun getDefaultColor(name: String): Int {
        return when (name) {
            "sun" -> 0xFFFFD700.toInt()
            "mercury" -> 0xFF8C7853.toInt()
            "venus" -> 0xFFFFC649.toInt()
            "earth" -> 0xFF4169E1.toInt()
            "mars" -> 0xFFCD5C5C.toInt()
            "jupiter" -> 0xFFC88B3A.toInt()
            "saturn" -> 0xFFFAD5A5.toInt()
            "uranus" -> 0xFF4FD0E7.toInt()
            "neptune" -> 0xFF4166F5.toInt()
            "moon" -> 0xFFE0E0E0.toInt()
            else -> 0xFFFFFFFF.toInt()
        }
    }

    fun draw(
        modelName: String,
        viewMatrix: FloatArray,
        projectionMatrix: FloatArray,
        position: FloatArray,
        scale: Float,
        rotation: Float = 0f,
        glowIntensity: Float = 0.5f
    ) {
        val model = models[modelName] ?: return

        val modelMatrix = FloatArray(16)
        val mvpMatrix = FloatArray(16)
        val mvMatrix = FloatArray(16)

        Matrix.setIdentityM(modelMatrix, 0)
        Matrix.translateM(modelMatrix, 0, position[0], position[1], position[2])
        Matrix.rotateM(modelMatrix, 0, rotation, 0f, 1f, 0f)
        Matrix.scaleM(modelMatrix, 0, scale, scale, scale)

        Matrix.multiplyMM(mvMatrix, 0, viewMatrix, 0, modelMatrix, 0)
        Matrix.multiplyMM(mvpMatrix, 0, projectionMatrix, 0, mvMatrix, 0)

        GLES20.glUseProgram(program)

        // Set uniforms
        GLES20.glUniformMatrix4fv(mvpMatrixUniform, 1, false, mvpMatrix, 0)
        GLES20.glUniform3f(lightPosUniform, 0f, 0f, 10f)
        GLES20.glUniform4f(colorUniform, 1f, 1f, 1f, 1f)
        GLES20.glUniform1f(glowUniform, glowIntensity)

        // Bind texture
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, model.textureId)
        GLES20.glUniform1i(textureUniform, 0)

        // Set vertex attributes
        GLES20.glEnableVertexAttribArray(positionAttrib)
        GLES20.glVertexAttribPointer(positionAttrib, 3, GLES20.GL_FLOAT, false, 0, model.vertices)

        GLES20.glEnableVertexAttribArray(texCoordAttrib)
        GLES20.glVertexAttribPointer(texCoordAttrib, 2, GLES20.GL_FLOAT, false, 0, model.texCoords)

        GLES20.glEnableVertexAttribArray(normalAttrib)
        GLES20.glVertexAttribPointer(normalAttrib, 3, GLES20.GL_FLOAT, false, 0, model.normals)

        // Draw
        GLES20.glDrawElements(
            GLES20.GL_TRIANGLES,
            model.indexCount,
            GLES20.GL_UNSIGNED_SHORT,
            model.indices
        )

        // Cleanup
        GLES20.glDisableVertexAttribArray(positionAttrib)
        GLES20.glDisableVertexAttribArray(texCoordAttrib)
        GLES20.glDisableVertexAttribArray(normalAttrib)
    }

    private fun createFloatBuffer(data: FloatArray): FloatBuffer {
        return ByteBuffer.allocateDirect(data.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(data)
            .apply { position(0) }
    }

    private fun createShortBuffer(data: ShortArray): ShortBuffer {
        return ByteBuffer.allocateDirect(data.size * 2)
            .order(ByteOrder.nativeOrder())
            .asShortBuffer()
            .put(data)
            .apply { position(0) }
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

    data class GLBModel(
        val name: String,
        val vertices: FloatBuffer,
        val texCoords: FloatBuffer,
        val normals: FloatBuffer,
        val indices: ShortBuffer,
        val indexCount: Int,
        val textureId: Int
    )
}