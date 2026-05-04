import 'src/backend_config_io.dart'
    if (dart.library.html) 'src/backend_config_web.dart';

// Set this to true for deployment and update prodUrl with your Render/Backend URL
const bool isProduction = false;
const String prodUrl = 'https://cholo-backend.onrender.com';

String get backendUrl => isProduction ? prodUrl : backendUrlImpl();
