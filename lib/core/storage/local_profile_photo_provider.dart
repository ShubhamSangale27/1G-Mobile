import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import 'local_profile_photo_service.dart';

final localProfilePhotoServiceProvider = Provider<LocalProfilePhotoService>((ref) {
  return LocalProfilePhotoService(storage: ref.watch(secureStorageProvider));
});
