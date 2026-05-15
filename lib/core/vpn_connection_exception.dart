/// Ошибка подключения VPN с текстом для UI (без префикса «Bad state»).
class VpnConnectionException implements Exception {
  VpnConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

String vpnErrorMessage(Object error) {
  if (error is VpnConnectionException) return error.message;
  if (error is StateError) {
    final msg = error.message;
    if (msg.isNotEmpty) return msg;
  }
  final text = error.toString();
  const prefix = 'Bad state: ';
  if (text.startsWith(prefix)) {
    final body = text.substring(prefix.length).trim();
    if (body.isNotEmpty) return body;
  }
  return text;
}
