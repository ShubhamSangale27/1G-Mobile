abstract final class StorageKeys {
  static const accessToken = 'accessToken';
  static const refreshToken = 'refreshToken';
  static const user = 'user';
  static const pendingVerify = 'pendingVerify';

  static String localProfilePhotoPath(int userId) => 'localProfilePhotoPath_$userId';
}
