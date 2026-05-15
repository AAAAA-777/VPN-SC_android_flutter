class ServerNode {
  const ServerNode({
    required this.id,
    required this.remark,
    required this.shareLink,
    required this.configJson,
  });

  final String id;
  final String remark;
  final String shareLink;
  final String configJson;

  Map<String, dynamic> toJson() => {
        'id': id,
        'remark': remark,
        'shareLink': shareLink,
        'configJson': configJson,
      };

  factory ServerNode.fromJson(Map<String, dynamic> json) => ServerNode(
        id: json['id'] as String,
        remark: json['remark'] as String,
        shareLink: json['shareLink'] as String,
        configJson: json['configJson'] as String,
      );
}
