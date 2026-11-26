// Other platforms retain the existing in-memory chat behavior.
class LocalChatHistory {
  static LocalChatHistory? desktop() => null;
  List<Map<String, Object?>> read(String peer, bool outgoing) => [];
  void append(String peer, bool outgoing, bool mine, int time, String text) {}
  void clear(String peer, bool outgoing) {}
  void clearAll() {}
  void prune() {}
}
