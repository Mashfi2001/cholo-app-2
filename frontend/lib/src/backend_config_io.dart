import 'dart:io' show Platform;

String backendUrlImpl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}
