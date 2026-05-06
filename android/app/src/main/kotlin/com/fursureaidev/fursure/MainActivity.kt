package com.fursureaidev.fursure

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.tensorflow.lite.Interpreter
import java.nio.ByteBuffer
import java.nio.ByteOrder

class MainActivity : FlutterActivity() {
    private var breedInterpreter: Interpreter? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "fursure/breed_native",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadBreedModel" -> {
                    val modelBytes = call.argument<ByteArray>("modelBytes")
                    if (modelBytes == null) {
                        result.error("invalid_args", "Missing model bytes.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        loadBreedModel(modelBytes)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("model_load", e.message, null)
                    }
                }

                "runBreedModel" -> {
                    val inputBytes = call.argument<ByteArray>("inputBytes")
                    if (inputBytes == null) {
                        result.error("invalid_args", "Missing input bytes.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        result.success(runBreedModel(inputBytes))
                    } catch (e: Exception) {
                        result.error("inference_failed", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        breedInterpreter?.close()
        breedInterpreter = null
        super.onDestroy()
    }

    private fun loadBreedModel(modelBytes: ByteArray) {
        val modelBuffer = ByteBuffer.allocateDirect(modelBytes.size)
            .order(ByteOrder.nativeOrder())
        modelBuffer.put(modelBytes)
        modelBuffer.rewind()

        val options = Interpreter.Options().apply {
            setNumThreads(4)
        }

        breedInterpreter?.close()
        breedInterpreter = Interpreter(modelBuffer, options)
    }

    private fun runBreedModel(inputBytes: ByteArray): List<Double> {
        val interpreter = breedInterpreter
            ?: error("Breed model is not loaded.")

        val inputBuffer = ByteBuffer.allocateDirect(inputBytes.size)
            .order(ByteOrder.nativeOrder())
        inputBuffer.put(inputBytes)
        inputBuffer.rewind()

        val outputTensor = interpreter.getOutputTensor(0)
        val outputBuffer = ByteBuffer.allocateDirect(outputTensor.numBytes())
            .order(ByteOrder.nativeOrder())
        outputBuffer.rewind()

        interpreter.run(inputBuffer, outputBuffer)

        outputBuffer.rewind()
        val outputCount = outputTensor.numBytes() / 4
        return List(outputCount) { outputBuffer.float.toDouble() }
    }
}
