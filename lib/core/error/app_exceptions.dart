class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ModelDownloadException extends AppException {
  const ModelDownloadException(super.message);
}

class ModelLoadException extends AppException {
  const ModelLoadException(super.message);
}

class InferenceException extends AppException {
  const InferenceException(super.message);
}

class CameraException extends AppException {
  const CameraException(super.message);
}

class AudioRecordingException extends AppException {
  const AudioRecordingException(super.message);
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message);
}
