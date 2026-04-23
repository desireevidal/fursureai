/// Constants owned by the prediction pipeline.
///
/// These values are determined by the ML model contracts (input shapes,
/// label sets, audio requirements) and belong here rather than in a
/// generic app constants file.
class PredictionConstants {
  // Order matches image_dataset_from_directory alphabetical sort used during training:
  // ['Maine_Coon', 'Puspin', 'Russian_Blue', '_Bombay', '_Persian', '_Siamese']
  static const List<String> breedLabels = [
    'Maine Coon',
    'Puspin',
    'Russian Blue',
    'Bombay',
    'Persian',
    'Siamese',
  ];

  // Order matches notebook CLASSES = ["female", "male"] (female=0, male=1).
  // The gender model outputs a single sigmoid value: P(male).
  static const List<String> genderLabels = ['Female', 'Male'];

  // ── Image model ────────────────────────────────────────────────────────────
  static const int imageInputSize = 224;

  // ── Audio / gender model ───────────────────────────────────────────────────
  // All values match FurSure_Gender(MFCC+CNN).ipynb cells 5–7.

  /// Recording sample rate expected by the gender model (notebook SR = 22050).
  static const int audioSampleRate = 22050;

  static const int audioMinDurationSeconds = 1;
  static const int audioMaxDurationSeconds = 2;

  /// Samples per clip: SR × 2 s = 44 100.
  static const int audioTargetSamples = 44100;

  // MFCC extraction parameters (librosa.feature.mfcc defaults used in notebook).
  static const int mfccCoefficients = 13; // N_MFCC
  static const int mfccMaxTimeSteps = 87; // MAX_LEN
  static const int mfccTotalFeatures = 39; // nMfcc + delta + delta2

  static const int mfccNFft = 2048; // librosa n_fft default
  static const int mfccHopLength = 512; // librosa hop_length default
  static const int mfccNMels = 128; // librosa n_mels default

  /// Silence trim threshold in dB (notebook TOP_DB = 20).
  static const double audioTopDb = 20.0;
}
