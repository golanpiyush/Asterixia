class Logger {
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    print('[DEBUG] $message');
    if (error != null) {
      print('[ERROR] $error');
      if (stackTrace != null) {
        print('[STACK] $stackTrace');
      }
    }
  }

  static void info(String message) {
    print('[INFO] $message');
  }

  static void warning(String message) {
    print('[WARNING] $message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    print('[ERROR] $message');
    if (error != null) {
      print('[ERROR DETAIL] $error');
    }
    if (stackTrace != null) {
      print('[STACK TRACE] $stackTrace');
    }
  }

  static void ar(String message) {
    print('[AR] $message');
  }

  static void sensor(String message) {
    print('[SENSOR] $message');
  }

  static void astronomy(String message) {
    print('[ASTRONOMY] $message');
  }
}
