import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_client/web_socket_client.dart';

class ChatWebService {
  static final _instance = ChatWebService._internal();
  WebSocket? _socket;
  ConnectionState _connectionState = const Disconnected();

  factory ChatWebService() => _instance;

  ChatWebService._internal();
  final _searchResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _contentController = StreamController<Map<String, dynamic>>.broadcast();
  final _queryStartController = StreamController<String>.broadcast();
  final _isGeneratingController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get searchResultStream =>
      _searchResultController.stream;
  Stream<Map<String, dynamic>> get contentStream => _contentController.stream;
  Stream<String> get queryStartStream => _queryStartController.stream;
  Stream<bool> get isGeneratingStream => _isGeneratingController.stream;

  static String get _wsUrl {
    if (kIsWeb) {
      return "ws://localhost:8000/ws/chat";
    } else {
      // Live Render backend WebSocket URL for all mobile users worldwide
      return "wss://nova-10g6.onrender.com/ws/chat";
    }
  }

  void connect() {
    if (_socket != null) return;
    final url = _wsUrl;
    debugPrint("[ChatWebService] Connecting to $url");
    _socket = WebSocket(Uri.parse(url), backoff: const ConstantBackoff(Duration(seconds: 1)));

    _socket!.connection.listen((state) {
      _connectionState = state;
      debugPrint("[ChatWebService] Connection state changed: $state");
    });

    _socket!.messages.listen(
      (message) {
        try {
          final data = json.decode(message);
          if (data['type'] == 'search_result') {
            debugPrint("[ChatWebService] Received search_result: ${data['data']?.length} sources");
            _searchResultController.add(data);
          } else if (data['type'] == 'content') {
            _contentController.add(data);
          }
        } catch (e) {
          debugPrint("[ChatWebService] JSON decode error: $e");
        }
      },
      onError: (error) {
        debugPrint("[ChatWebService] WebSocket error: $error");
        _isGeneratingController.add(false);
      },
      onDone: () {
        debugPrint("[ChatWebService] WebSocket done");
        _socket = null;
        _connectionState = const Disconnected();
        _isGeneratingController.add(false);
      },
    );
  }

  void chat(String query) {
    if (_socket == null) {
      connect();
    }

    _isGeneratingController.add(true);
    _queryStartController.add(query);

    debugPrint("[ChatWebService] Preparing to send query: $query, current state: $_connectionState");

    void sendPayload() {
      debugPrint("[ChatWebService] Sending JSON query payload: $query");
      _socket?.send(json.encode({'query': query}));
    }

    if (_connectionState is Connected) {
      sendPayload();
    } else if (_socket != null) {
      _socket!.connection.firstWhere((state) => state is Connected).then((_) {
        sendPayload();
      }).catchError((err) {
        debugPrint("[ChatWebService] Error waiting for connection: $err");
        _socket = null;
        _isGeneratingController.add(false);
      });
    }
  }

  void stopStream() {
    debugPrint("[ChatWebService] Stopping active stream...");
    try {
      _socket?.close();
    } catch (e) {
      debugPrint("[ChatWebService] Error closing socket: $e");
    }
    _socket = null;
    _connectionState = const Disconnected();
    _isGeneratingController.add(false);
  }

  void finishGeneration() {
    _isGeneratingController.add(false);
  }
}
