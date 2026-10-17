import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_item.dart';

class CardService extends ChangeNotifier {
  static const String _keyFavorites = 'charlemos_favorites';
  static const String _keyCustomCards = 'charlemos_custom_cards';
  static const String _keyPlayedHistory = 'charlemos_played_history';

  final SharedPreferences _prefs;

  List<CardItem> _allCards = [];
  List<CardItem> _customCards = [];
  Set<String> _favoriteIds = {};
  Set<String> _playedCardIds = {};

  int _selectedLevel = 0; // 0: All, 1: Level 1, 2: Level 2, 3: Level 3, 4: Challenges
  String _selectedCategory = 'all'; // all, dates, couples, friends, challenges, custom
  Set<String> _activeMultiCategories = {}; // For multi-category group games
  CardItem? _currentCard;

  // Session history for previous/back navigation
  final List<CardItem> _history = [];
  int _historyIndex = -1;

  bool _isLoading = true;

  CardService(this._prefs) {
    load();
  }

  bool get isLoading => _isLoading;
  int get selectedLevel => _selectedLevel;
  String get selectedCategory => _selectedCategory;
  Set<String> get activeMultiCategories => _activeMultiCategories;
  CardItem? get currentCard => _currentCard;
  List<CardItem> get customCards => _customCards;
  bool get canGoPrevious => _historyIndex > 0;
  int get historyIndex => _historyIndex;
  int get historyLength => _history.length;

  List<CardItem> get favoriteCards =>
      _allCards.where((c) => _favoriteIds.contains(c.id)).toList();

  int get totalCardsCount => _allCards.length;
  int get playedCount => _playedCardIds.length;

  int countByCategory(String category) {
    if (category == 'custom') return _customCards.length;
    return _allCards.where((c) => c.category == category && !c.isCustom).length;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _favoriteIds = (_prefs.getStringList(_keyFavorites) ?? []).toSet();
    _playedCardIds = (_prefs.getStringList(_keyPlayedHistory) ?? []).toSet();

    // Load custom cards
    final customRaw = _prefs.getStringList(_keyCustomCards) ?? [];
    _customCards = customRaw
        .map((s) => CardItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();

    // Load bundled cards from assets
    try {
      final jsonString = await rootBundle.loadString('assets/data/cards.json');
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      _allCards = list
          .map((item) => CardItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cards.json: $e');
      }
      _allCards = [];
    }

    // Merge custom cards
    _allCards.addAll(_customCards);

    // Apply favorite states
    _allCards = _allCards
        .map((c) => c.copyWith(isFavorite: _favoriteIds.contains(c.id)))
        .toList();

    drawNextCard();
    _isLoading = false;
    notifyListeners();
  }

  List<CardItem> get filteredPool {
    return _allCards.where((c) {
      if (_selectedLevel != 0 && c.level != _selectedLevel) return false;
      if (_activeMultiCategories.isNotEmpty) {
        if (!_activeMultiCategories.contains(c.category)) return false;
      } else if (_selectedCategory != 'all' && c.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  void setLevelFilter(int level) {
    _selectedLevel = level;
    _history.clear();
    _historyIndex = -1;
    drawNextCard();
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    _activeMultiCategories.clear();
    _history.clear();
    _historyIndex = -1;
    drawNextCard();
    notifyListeners();
  }

  void setMultiCategoryFilter(Set<String> categories) {
    _activeMultiCategories = Set.from(categories);
    _selectedCategory = 'all';
    _history.clear();
    _historyIndex = -1;
    drawNextCard();
    notifyListeners();
  }

  void drawNextCard() {
    // If user navigated backwards into history, moving forward revisits already drawn cards
    if (_historyIndex >= 0 && _historyIndex < _history.length - 1) {
      _historyIndex++;
      _currentCard = _history[_historyIndex];
      notifyListeners();
      return;
    }

    final pool = filteredPool;
    if (pool.isEmpty) {
      _currentCard = null;
      notifyListeners();
      return;
    }

    // Filter unplayed if possible
    final unplayed = pool.where((c) => !_playedCardIds.contains(c.id)).toList();
    if (unplayed.isNotEmpty) {
      unplayed.shuffle();
      _currentCard = unplayed.first;
    } else {
      // If all played, reset pool history for this filter
      pool.shuffle();
      _currentCard = pool.first;
    }

    if (_currentCard != null) {
      _playedCardIds.add(_currentCard!.id);
      _prefs.setStringList(_keyPlayedHistory, _playedCardIds.toList());

      // Append to session history (capped at last 50 cards to remain lightweight)
      _history.add(_currentCard!);
      if (_history.length > 50) {
        _history.removeAt(0);
      }
      _historyIndex = _history.length - 1;
    }
    notifyListeners();
  }

  bool goToPreviousCard() {
    if (!canGoPrevious) return false;
    _historyIndex--;
    _currentCard = _history[_historyIndex];
    notifyListeners();
    return true;
  }

  Future<void> toggleFavorite(CardItem card) async {
    final newFav = !_favoriteIds.contains(card.id);
    if (newFav) {
      _favoriteIds.add(card.id);
    } else {
      _favoriteIds.remove(card.id);
    }
    await _prefs.setStringList(_keyFavorites, _favoriteIds.toList());

    _allCards = _allCards.map((c) {
      if (c.id == card.id) {
        return c.copyWith(isFavorite: newFav);
      }
      return c;
    }).toList();

    if (_currentCard?.id == card.id) {
      _currentCard = _currentCard!.copyWith(isFavorite: newFav);
    }

    notifyListeners();
  }

  Future<void> addCustomCard({
    required String text,
    required int level,
    required String category,
  }) async {
    final newCard = CardItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      level: level,
      category: category,
      textEs: text,
      textEn: text,
      textPt: text,
      textFr: text,
      textIt: text,
      isCustom: true,
    );

    _customCards.add(newCard);
    _allCards.add(newCard);

    final raw = _customCards.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList(_keyCustomCards, raw);
    notifyListeners();
  }

  Future<void> deleteCustomCard(String cardId) async {
    _customCards.removeWhere((c) => c.id == cardId);
    _allCards.removeWhere((c) => c.id == cardId);
    _favoriteIds.remove(cardId);
    _playedCardIds.remove(cardId);

    final raw = _customCards.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList(_keyCustomCards, raw);
    await _prefs.setStringList(_keyFavorites, _favoriteIds.toList());

    if (_currentCard?.id == cardId) {
      drawNextCard();
    } else {
      notifyListeners();
    }
  }

  void resetHistory() {
    _playedCardIds.clear();
    _prefs.setStringList(_keyPlayedHistory, []);
    _history.clear();
    _historyIndex = -1;
    drawNextCard();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    _playedCardIds.clear();
    _favoriteIds.clear();
    _customCards.clear();
    _history.clear();
    _historyIndex = -1;
    await _prefs.remove(_keyPlayedHistory);
    await _prefs.remove(_keyFavorites);
    await _prefs.remove(_keyCustomCards);
    await load();
  }
}
