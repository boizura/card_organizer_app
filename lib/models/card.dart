class PlayingCard {
  final int? id;
  final String cardName;
  final String suit;
  final String? imageUrl;
  final int folderId;

  PlayingCard({
    this.id,
    required this.cardName,
    required this.suit,
    this.imageUrl,
    required this.folderId,
  });

  Map toMap() {
    return {
      'id': id,
      'card_name': cardName,
      'suit': suit,
      'image_url': imageUrl,
      'folder_id': folderId,
    };
  }

  factory PlayingCard.fromMap(Map map) {
    return PlayingCard(
      id: map['id'],
      cardName: map['card_name'],
      suit: map['suit'],
      imageUrl: map['image_url'],
      folderId: map['folder_id'],
    );
  }

  PlayingCard copyWith({
    int? id,
    String? cardName,
    String? suit,
    String? imageUrl,
    int? folderId,
  }) {
    return PlayingCard(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      suit: suit ?? this.suit,
      imageUrl: imageUrl ?? this.imageUrl,
      folderId: folderId ?? this.folderId,
    );
  }

  @override
  String toString() {
    return 'PlayingCard{id: $id, cardName: $cardName, suit: $suit, folderId: $folderId}';
  }
}