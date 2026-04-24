import 'package:flutter/widgets.dart';

class BreedInfo {
  const BreedInfo({
    required this.id,
    required this.name,
    required this.imageAssetPath,
    required this.heroImageAssetPath,
    this.thumbnailAlignment = Alignment.center,
    this.thumbnailScale = 1,
    required this.description,
    required this.facts,
    required this.health,
    required this.grooming,
    required this.nutrition,
  });

  final String id;
  final String name;
  final String imageAssetPath;
  final String heroImageAssetPath;
  final Alignment thumbnailAlignment;
  final double thumbnailScale;
  final String description;
  final List<BreedFact> facts;
  final String health;
  final String grooming;
  final String nutrition;
}

class BreedFact {
  const BreedFact({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

const BreedInfo domesticShorthairBreedInfo = BreedInfo(
  id: 'domesticshorthair',
  name: 'Domestic Shorthair',
  imageAssetPath: 'assets/images/breed_info_cropped/domestic_shorthair_cropped.jpg',
  heroImageAssetPath: 'assets/images/breed_info/domestic_shorthair.jpg',
  thumbnailAlignment: Alignment.center,
  thumbnailScale: 1,
  description:
      'Domestic Shorthair cats are friendly, adaptable, and easy-going. '
      'They are playful and enjoy interactive toys, but can also relax '
      'comfortably in a lap for a snooze. They are known for their sturdy, '
      'muscular build and diverse coat colors and patterns.',
  facts: [
    BreedFact(label: 'Length/Size', value: 'Medium'),
    BreedFact(
      label: 'Weight',
      value: 'Females and males vary; generally medium-sized and muscular',
    ),
    BreedFact(label: 'Lifespan', value: 'Up to 20 years with proper care'),
    BreedFact(
      label: 'Origin',
      value:
          'North America, descended from working cats brought by early settlers',
    ),
  ],
  health:
      'Domestic Shorthairs are generally healthy and robust. Regular vet '
      'check-ups are recommended to maintain optimal health and prevent '
      'obesity.',
  grooming:
      'Their short coat requires minimal grooming. Routine brushing, nail '
      'trimming, and dental care help keep them in good condition.',
  nutrition:
      'Feed a high-quality cat food on a regular schedule and provide fresh '
      'water daily. Interactive feeding toys can help keep them active and '
      'prevent overeating.',
);

const BreedInfo siameseBreedInfo = BreedInfo(
  id: 'siamese',
  name: 'Siamese',
  imageAssetPath: 'assets/images/breed_info_cropped/siamese_cropped.jpg',
  heroImageAssetPath: 'assets/images/breed_info/siamese.jpg',
  thumbnailAlignment: Alignment.center,
  thumbnailScale: 1,
  description:
      'Siamese cats are elegant, social, and intelligent. They are playful, '
      'affectionate, and highly interactive; they thrive with attention and '
      'love to engage with their owners. They are known for their striking '
      'blue almond-shaped eyes, long sleek bodies, and distinctive point '
      'coloring.',
  facts: [
    BreedFact(label: 'Length/Size', value: 'Medium'),
    BreedFact(label: 'Weight', value: 'Females 5-8 lbs, Males 8-12 lbs'),
    BreedFact(label: 'Lifespan', value: '10+ years, sometimes 20+'),
    BreedFact(label: 'Origin', value: 'Thailand (historically Siam)'),
  ],
  health:
      'Siamese cats are generally healthy but can be sensitive to anesthesia. '
      'They may be susceptible to Amyloidosis, so regular vet check-ups are '
      'recommended.',
  grooming:
      'Their short coat requires minimal care and is easy to groom. Weekly '
      'brushing or damp-hand stroking removes loose hair. Nails, teeth, and '
      'ears should be maintained regularly.',
  nutrition:
      'Feed adults twice daily and kittens three to four times daily. Provide '
      'fresh, clean water at all times, ideally placed away from food. '
      'High-protein canned food is preferred.',
);

const BreedInfo persianBreedInfo = BreedInfo(
  id: 'persian',
  name: 'Persian',
  imageAssetPath: 'assets/images/breed_info_cropped/persian_cropped.jpg',
  heroImageAssetPath: 'assets/images/breed_info/persian.jpg',
  thumbnailAlignment: Alignment.center,
  thumbnailScale: 1,
  description:
      'Persian cats are gentle, calm, and affectionate. They are ideal for '
      'quiet homes. They are known for their luxurious long coat, round face, '
      'snub nose, and expressive eyes. They enjoy attention but are not '
      'demanding.',
  facts: [
    BreedFact(label: 'Length/Size', value: 'Medium'),
    BreedFact(label: 'Weight', value: 'Females 7-12 lbs, Males 9-14 lbs'),
    BreedFact(label: 'Lifespan', value: '8-11 years'),
    BreedFact(label: 'Origin', value: 'Persia (modern-day Iran)'),
  ],
  health:
      'Persians can be prone to Polycystic Kidney Disease (PKD), respiratory '
      'problems, eye issues, and Hypertrophic Cardiomyopathy. Regular vet '
      'visits and screenings are recommended.',
  grooming:
      'Their long coat requires daily combing and occasional baths. Eyes '
      'should be wiped daily. Nails and teeth should be maintained regularly.',
  nutrition:
      'A high-quality diet is recommended. Fresh water should always be '
      'available, and portions monitored to prevent obesity.',
);

const BreedInfo maineCoonBreedInfo = BreedInfo(
  id: 'mainecoon',
  name: 'Maine Coon',
  imageAssetPath: 'assets/images/breed_info_cropped/maine_coon_cropped.jpg',
  heroImageAssetPath: 'assets/images/breed_info/maine_coon.jpg',
  thumbnailAlignment: Alignment.center,
  thumbnailScale: 1,
  description:
      'Maine Coon cats are gentle, friendly, and affectionate "gentle '
      'giants." They are social but independent, and they enjoy following '
      'their owners around and interacting without being overly demanding. '
      'They are known for their large size, bushy tails, expressive eyes, and '
      'tufted ears.',
  facts: [
    BreedFact(
      label: 'Length/Size',
      value: 'Medium-to-large, full maturity at 3-5 years',
    ),
    BreedFact(label: 'Weight', value: 'Females 12-15 lbs, Males 18-22 lbs'),
    BreedFact(label: 'Lifespan', value: '12.5+ years'),
    BreedFact(label: 'Origin', value: 'United States (Maine)'),
  ],
  health:
      'Maine Coons may be susceptible to Hypertrophic Cardiomyopathy (HCM), '
      'hip dysplasia, luxating patella, spinal muscular atrophy (SMA), and '
      'pyruvate kinase deficiency. Regular vet check-ups and genetic '
      'screenings are recommended.',
  grooming:
      'Their semi-long coat is generally low-maintenance; weekly combing is '
      'sufficient. Nails and teeth should be trimmed and brushed regularly.',
  nutrition:
      'Feed a high-quality, protein-rich diet with low carbohydrates. Adults '
      'generally need about 2/3-3/4 cup per day. Fresh water should always be '
      'available, and play encouraged to maintain fitness.',
);

const BreedInfo russianBlueBreedInfo = BreedInfo(
  id: 'russianblue',
  name: 'Russian Blue',
  imageAssetPath: 'assets/images/breed_info_cropped/russian_blue_cropped.jpg',
  heroImageAssetPath: 'assets/images/breed_info/russian_blue.jpg',
  thumbnailAlignment: Alignment.center,
  thumbnailScale: 1,
  description:
      'Russian Blues are elegant, intelligent, and affectionate cats with a '
      'quiet but communicative nature. They tend to be reserved with '
      'strangers at first, but once bonded, they are loyal, loving, and '
      'closely attached to their families. They are playful companions that '
      'do well with children and other pets, and their dense blue coat, '
      'silver shimmer, emerald eyes, and subtle "smile" are signature '
      'traits.',
  facts: [
    BreedFact(label: 'Length/Size', value: 'Medium-sized'),
    BreedFact(
      label: 'Weight',
      value: 'Not specified on the TICA breed page',
    ),
    BreedFact(label: 'Lifespan', value: '10-20 years'),
    BreedFact(label: 'Origin', value: 'Arkhangelsk (Archangel), Russia'),
    BreedFact(label: 'Coat/Color', value: 'Short coat; blue with silver tipping'),
  ],
  health:
      'Russian Blues are generally considered a healthy breed, and some may '
      'live 16 years or more with proper care. Regular veterinary care and '
      'routine hygiene are still important for long-term wellness.',
  grooming:
      'Their coat is relatively easy to maintain and should be brushed '
      'regularly, about once or twice a week. Eye corners should be wiped '
      'gently as needed, ears checked weekly and cleaned if dirty, teeth '
      'brushed weekly to help prevent periodontal disease, and nails trimmed '
      'every couple of weeks.',
  nutrition:
      'Russian Blues are known to have healthy appetites, so they should be '
      'kept on a regular feeding schedule and not overindulged with treats. '
      'Fresh, clean water should be available daily, and some cats may drink '
      'better if their water is placed away from their food.',
);

const BreedInfo bombayBreedInfo = BreedInfo(
  id: 'bombay',
  name: 'Bombay',
  imageAssetPath: 'assets/images/breed_info_cropped/bombay_cropped.jpg',
  heroImageAssetPath: 'assets/images/breed_info/bombay.jpg',
  thumbnailAlignment: Alignment.center,
  thumbnailScale: 1,
  description:
      'Bombay cats are affectionate, social, and playful "mini-panther" '
      'cats. They love human company, greet family members at the door, and '
      'enjoy cuddling and playing. They are excellent with children and other '
      'pets.',
  facts: [
    BreedFact(label: 'Length/Size', value: 'Medium-to-large'),
    BreedFact(label: 'Weight', value: 'Muscular, robust (medium size)'),
    BreedFact(label: 'Lifespan', value: '12+ years'),
    BreedFact(
      label: 'Origin',
      value: 'United States (from American Shorthair and Burmese)',
    ),
  ],
  health:
      'Bombays may be at risk for Hypertrophic Cardiomyopathy (HCM). Regular '
      'vet check-ups and echocardiogram screenings are recommended.',
  grooming:
      'Their short coat sheds very little and is easy to maintain with weekly '
      'brushing. Nails, ears, and teeth should be cared for regularly, and a '
      'scratching post provided.',
  nutrition:
      'Feed a high-quality diet appropriate for size and activity. Fresh '
      'water should always be available, ideally separated from food; a water '
      'fountain can help encourage drinking.',
);

String normalizeBreedName(String breed) =>
    breed.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

BreedInfo? findBreedInfo(String? breed) {
  if (breed == null || breed.isEmpty) return null;

  switch (normalizeBreedName(breed)) {
    case 'domesticshorthair':
      return domesticShorthairBreedInfo;
    case 'siamese':
      return siameseBreedInfo;
    case 'persian':
      return persianBreedInfo;
    case 'mainecoon':
      return maineCoonBreedInfo;
    case 'russianblue':
      return russianBlueBreedInfo;
    case 'bombay':
      return bombayBreedInfo;
    default:
      return null;
  }
}

List<BreedInfo> resolveBreedInfos(String? breedText) {
  if (breedText == null || breedText.isEmpty) return const [];

  final parts = breedText
      .split(RegExp(r'[,/|]+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  final candidates = parts.isEmpty ? [breedText.trim()] : parts;
  final results = <BreedInfo>[];
  final seen = <String>{};

  for (final candidate in candidates) {
    final info = findBreedInfo(candidate);
    if (info != null && seen.add(info.id)) {
      results.add(info);
    }
  }

  if (results.isNotEmpty) return results;

  final fallback = findBreedInfo(breedText);
  return fallback == null ? const [] : [fallback];
}
