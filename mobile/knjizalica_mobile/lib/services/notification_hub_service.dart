import 'package:signalr_netcore/signalr_client.dart';

import '../config/api_config.dart';
import '../models/notification_models.dart';
import 'token_storage.dart';

typedef NotificationReceivedHandler = void Function(NotificationDto notification);

class NotificationHubService {
  HubConnection? _connection;
  NotificationReceivedHandler? onNotificationReceived;

  Future<void> connect(TokenStorage tokenStorage) async {
    await disconnect();

    final token = await tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    _connection = HubConnectionBuilder()
        .withUrl(
          ApiConfig.hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('NotificationReceived', (arguments) {
      if (arguments == null || arguments.isEmpty) {
        return;
      }
      final payload = arguments.first;
      if (payload is Map<String, dynamic>) {
        onNotificationReceived?.call(NotificationDto.fromJson(payload));
      } else if (payload is Map) {
        onNotificationReceived?.call(
          NotificationDto.fromJson(Map<String, dynamic>.from(payload)),
        );
      }
    });

    await _connection!.start();
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.stop();
      } catch (_) {
        // Ignore disconnect errors.
      }
      _connection = null;
    }
  }
}
