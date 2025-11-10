import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


@pragma('vm:entry-point')
void callbackDispatcher() {

}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  if (!kIsWeb) {
    try {
      // Динамический импорт WorkManager только для не-Web платформ
      print('WorkManager инициализация пропущена на Web');
    } catch (e) {
      print('WorkManager не доступен на этой платформе');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => RecipeViewModel(preferences),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsViewModel(preferences),
        ),
      ],
      child: const RecipeBookApp(),
    ),
  );
}

// Models
class Recipe {
  final String id;
  final String name;
  final String category;
  final int prepTime;
  final String difficulty;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final String? imageUrl;
  bool isFavorite;
  final int createdAt;

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.prepTime,
    required this.difficulty,
    required this.description,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    this.isFavorite = false,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? 'Unknown Recipe',
      category: json['strCategory'] ?? 'Other',
      prepTime: 30,
      difficulty: 'Medium',
      description: json['strInstructions']?.substring(0, json['strInstructions'].length > 100 ? 100 : json['strInstructions'].length) ?? 'Delicious recipe',
      ingredients: _extractIngredients(json),
      instructions: _extractInstructions(json['strInstructions']),
      imageUrl: json['strMealThumb'],
      isFavorite: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'prepTime': prepTime,
      'difficulty': difficulty,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
    };
  }

  factory Recipe.fromJsonStorage(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      prepTime: json['prepTime'],
      difficulty: json['difficulty'],
      description: json['description'],
      ingredients: List<String>.from(json['ingredients']),
      instructions: List<String>.from(json['instructions']),
      imageUrl: json['imageUrl'],
      isFavorite: json['isFavorite'] ?? false,
      createdAt: json['createdAt'],
    );
  }

  static List<String> _extractIngredients(Map<String, dynamic> json) {
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add('$measure $ingredient'.trim());
      }
    }
    return ingredients;
  }

  static List<String> _extractInstructions(String? instructions) {
    if (instructions == null || instructions.isEmpty) {
      return ['No instructions available'];
    }
    return instructions
        .split('.')
        .where((step) => step.trim().isNotEmpty)
        .map((step) => step.trim())
        .toList();
  }
}

// API Service
class RecipeApiService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search.php?s=$query'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          return (data['meals'] as List)
              .map((meal) => Recipe.fromJson(meal))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching recipes: $e');
      return [];
    }
  }

  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/filter.php?c=$category'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          final meals = (data['meals'] as List).take(10);
          List<Recipe> recipes = [];

          for (var meal in meals) {
            final detailedRecipe = await getRecipeDetails(meal['idMeal']);
            if (detailedRecipe != null) {
              recipes.add(detailedRecipe);
            }
          }
          return recipes;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching recipes by category: $e');
      return [];
    }
  }

  Future<Recipe?> getRecipeDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lookup.php?i=$id'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return Recipe.fromJson(data['meals'][0]);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching recipe details: $e');
      return null;
    }
  }

  Future<List<Recipe>> getRandomRecipes({int count = 10}) async {
    try {
      final futures = List.generate(
        count,
            (_) => http.get(Uri.parse('$baseUrl/random.php'))
            .timeout(const Duration(seconds: 10)),
      );

      final responses = await Future.wait(futures);
      List<Recipe> recipes = [];

      for (var response in responses) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['meals'] != null && data['meals'].isNotEmpty) {
            recipes.add(Recipe.fromJson(data['meals'][0]));
          }
        }
      }
      return recipes;
    } catch (e) {
      print('Error fetching random recipes: $e');
      return [];
    }
  }
}

// ViewModel
class RecipeViewModel extends ChangeNotifier {
  final SharedPreferences _preferences;
  final RecipeApiService _apiService = RecipeApiService();

  List<Recipe> _recipes = [];
  List<Recipe> _searchResults = [];
  List<Recipe> _favoriteRecipes = [];
  Recipe? _recipeOfTheDay;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'All';

  RecipeViewModel(this._preferences) {
    _selectedCategory = _preferences.getString('lastCategory') ?? 'All';
    _loadFavoritesFromPrefs();
    _loadRecipeOfTheDay();
    loadRecipes();
  }

  List<Recipe> get recipes => _recipes;
  List<Recipe> get searchResults => _searchResults;
  List<Recipe> get favoriteRecipes => _favoriteRecipes;
  Recipe? get recipeOfTheDay => _recipeOfTheDay;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  int get favoriteCount => _favoriteRecipes.length;

  final List<String> categories = [
    'All',
    'Beef',
    'Chicken',
    'Dessert',
    'Lamb',
    'Pasta',
    'Pork',
    'Seafood',
    'Vegetarian',
  ];

  void _loadFavoritesFromPrefs() {
    try {
      final favoritesJson = _preferences.getString('favorites');
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        _favoriteRecipes = favoritesList
            .map((item) => Recipe.fromJsonStorage(item))
            .toList();
      }
    } catch (e) {
      print('Error loading favorites: $e');
      _favoriteRecipes = [];
    }
  }

  void _loadRecipeOfTheDay() {
    try {
      final recipeJson = _preferences.getString('recipe_of_the_day');
      final dateStr = _preferences.getString('recipe_of_the_day_date');

      if (recipeJson != null && dateStr != null) {
        final savedDate = DateTime.parse(dateStr);
        final now = DateTime.now();

        if (savedDate.year == now.year &&
            savedDate.month == now.month &&
            savedDate.day == now.day) {
          final recipeData = json.decode(recipeJson);
          _recipeOfTheDay = Recipe.fromJsonStorage(recipeData);
        } else {
          // Если рецепт устарел, загружаем новый
          _fetchNewRecipeOfTheDay();
        }
      } else {
        // Если рецепта нет, загружаем новый
        _fetchNewRecipeOfTheDay();
      }
    } catch (e) {
      print('Error loading recipe of the day: $e');
      _fetchNewRecipeOfTheDay();
    }
  }

  // Загрузка нового рецепта дня
  Future<void> _fetchNewRecipeOfTheDay() async {
    try {
      final recipes = await _apiService.getRandomRecipes(count: 1);
      if (recipes.isNotEmpty) {
        _recipeOfTheDay = recipes[0];
        _recipeOfTheDay!.isFavorite = _isFavorite(_recipeOfTheDay!.id);

        // Сохраняем в SharedPreferences
        final recipeJson = json.encode(_recipeOfTheDay!.toJson());
        await _preferences.setString('recipe_of_the_day', recipeJson);
        await _preferences.setString('recipe_of_the_day_date', DateTime.now().toIso8601String());

        notifyListeners();
      }
    } catch (e) {
      print('Error fetching new recipe of the day: $e');
    }
  }

  Future<void> _saveFavoritesToPrefs() async {
    try {
      final favoritesJson = json.encode(
        _favoriteRecipes.map((r) => r.toJson()).toList(),
      );
      await _preferences.setString('favorites', favoritesJson);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  bool _isFavorite(String id) {
    return _favoriteRecipes.any((fav) => fav.id == id);
  }

  Future<void> loadRecipes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recipes = await _apiService.getRandomRecipes(count: 10);

      for (var recipe in _recipes) {
        recipe.isFavorite = _isFavorite(recipe.id);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load recipes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecipesByCategory(String category) async {
    _selectedCategory = category;
    await _preferences.setString('lastCategory', category);

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (category == 'All') {
        _recipes = await _apiService.getRandomRecipes(count: 10);
      } else {
        _recipes = await _apiService.getRecipesByCategory(category);
      }

      for (var recipe in _recipes) {
        recipe.isFavorite = _isFavorite(recipe.id);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load recipes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchRecipes(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _apiService.searchRecipes(query);

      for (var recipe in _searchResults) {
        recipe.isFavorite = _isFavorite(recipe.id);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  Future<void> toggleFavorite(String recipeId) async {
    Recipe? foundRecipe;

    // Ищем рецепт во всех источниках
    try {
      foundRecipe = _recipes.firstWhere((r) => r.id == recipeId);
    } catch (e) {
      try {
        foundRecipe = _searchResults.firstWhere((r) => r.id == recipeId);
      } catch (e) {
        try {
          foundRecipe = _favoriteRecipes.firstWhere((r) => r.id == recipeId);
        } catch (e) {
          if (_recipeOfTheDay?.id == recipeId) {
            foundRecipe = _recipeOfTheDay;
          }
        }
      }
    }

    // Если рецепт не найден, выходим
    if (foundRecipe == null) return;

    // Теперь foundRecipe точно не null, работаем с ним
    foundRecipe.isFavorite = !foundRecipe.isFavorite;

    if (foundRecipe.isFavorite) {
      _favoriteRecipes.add(foundRecipe);
    } else {
      _favoriteRecipes.removeWhere((r) => r.id == foundRecipe!.id);
    }

    await _saveFavoritesToPrefs();
    notifyListeners();
  }

  Recipe? getRecipeById(String id) {
    try {
      return _recipes.firstWhere((r) => r.id == id);
    } catch (e) {
      try {
        return _searchResults.firstWhere((r) => r.id == id);
      } catch (e) {
        try {
          return _favoriteRecipes.firstWhere((r) => r.id == id);
        } catch (e) {
          if (_recipeOfTheDay?.id == id) {
            return _recipeOfTheDay;
          }
          return null;
        }
      }
    }
  }
}

// Settings ViewModel
class SettingsViewModel extends ChangeNotifier {
  final SharedPreferences _preferences;
  bool _isDarkMode;
  bool _isGridView;

  SettingsViewModel(this._preferences)
      : _isDarkMode = _preferences.getBool('isDarkMode') ?? false,
        _isGridView = _preferences.getBool('isGridView') ?? false;

  bool get isDarkMode => _isDarkMode;
  bool get isGridView => _isGridView;

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _preferences.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> toggleGridView() async {
    _isGridView = !_isGridView;
    await _preferences.setBool('isGridView', _isGridView);
    notifyListeners();
  }
}

// Main App
class RecipeBookApp extends StatelessWidget {
  const RecipeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();

    return MaterialApp(
      title: 'Recipe Book',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      themeMode: settingsViewModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainNavigationScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/search': (context) => const SearchScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/recipe') {
          final recipeId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipeId: recipeId),
          );
        }
        return null;
      },
    );
  }
}

// Main Navigation
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecipeViewModel>();
    final settingsViewModel = context.watch<SettingsViewModel>();
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Recipe Book'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/search'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Badge(
                label: Text('${viewModel.favoriteCount}'),
                isLabelVisible: viewModel.favoriteCount > 0,
                child: const Icon(Icons.favorite),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Recipe of the Day Banner
          if (viewModel.recipeOfTheDay != null)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/recipe',
                    arguments: viewModel.recipeOfTheDay!.id,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: viewModel.recipeOfTheDay!.imageUrl != null
                            ? CachedNetworkImage(
                          imageUrl: viewModel.recipeOfTheDay!.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  'Recipe of the Day',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              viewModel.recipeOfTheDay!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          // Category Filter
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: viewModel.categories.length,
              itemBuilder: (context, index) {
                final category = viewModel.categories[index];
                final isSelected = viewModel.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => viewModel.loadRecipesByCategory(category),
                  ),
                );
              },
            ),
          ),
          // Recipe List
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(viewModel.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: viewModel.loadRecipes,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : viewModel.recipes.isEmpty
                ? const Center(child: Text('No recipes found'))
                : (settingsViewModel.isGridView || isTablet)
                ? _buildGridView(context, viewModel)
                : _buildListView(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, RecipeViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: viewModel.loadRecipes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.recipes.length,
        itemBuilder: (context, index) => RecipeCard(recipe: viewModel.recipes[index]),
      ),
    );
  }

  Widget _buildGridView(BuildContext context, RecipeViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: viewModel.loadRecipes,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: viewModel.recipes.length,
        itemBuilder: (context, index) => RecipeCard(recipe: viewModel.recipes[index]),
      ),
    );
  }
}

// Recipe Card
class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  Color _getDifficultyColor() {
    switch (recipe.difficulty) {
      case 'Easy': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'Hard': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<RecipeViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/recipe', arguments: recipe.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.imageUrl != null)
              CachedNetworkImage(
                imageUrl: recipe.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, size: 64),
                ),
              )
            else
              Container(
                height: 200,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.restaurant, size: 80, color: Theme.of(context).colorScheme.primary),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recipe.category,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => viewModel.toggleFavorite(recipe.id),
                        icon: Icon(
                          recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: recipe.isFavorite ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(
                        label: Text(recipe.difficulty),
                        backgroundColor: _getDifficultyColor().withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _getDifficultyColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('${recipe.prepTime} min'),
                        avatar: const Icon(Icons.access_time, size: 16),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Search Screen
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecipeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search recipes...',
            border: InputBorder.none,
          ),
          onSubmitted: (value) => viewModel.searchRecipes(value),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _searchController.clear();
              viewModel.clearSearch();
            },
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.searchResults.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for recipes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.searchResults.length,
        itemBuilder: (context, index) => RecipeCard(recipe: viewModel.searchResults[index]),
      ),
    );
  }
}

// Settings Screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: settingsViewModel.isDarkMode,
            onChanged: (_) => settingsViewModel.toggleDarkMode(),
            secondary: Icon(settingsViewModel.isDarkMode ? Icons.dark_mode : Icons.light_mode),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Grid View'),
            subtitle: const Text('Display recipes in grid layout'),
            value: settingsViewModel.isGridView,
            onChanged: (_) => settingsViewModel.toggleGridView(),
            secondary: Icon(settingsViewModel.isGridView ? Icons.grid_view : Icons.view_list),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Recipe Book v1.1.0 (Unit 7 - Web)'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Recipe Book',
                applicationVersion: '1.1.0 (Unit 7 - Daily Recipe)',
                applicationIcon: const Icon(Icons.restaurant_menu, size: 48),
                children: const [
                  Text('A recipe book app with Recipe of the Day'),
                  SizedBox(height: 8),
                  Text('✓ Daily featured recipe'),
                  Text('✓ Automatic recipe refresh'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Recipe Detail Screen
class RecipeDetailScreen extends StatelessWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecipeViewModel>();
    final recipe = viewModel.getRecipeById(recipeId);

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recipe Not Found')),
        body: const Center(child: Text('Recipe not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.name,
                style: const TextStyle(
                  shadows: [Shadow(offset: Offset(0, 1), blurRadius: 3.0, color: Colors.black54)],
                ),
              ),
              background: recipe.imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: recipe.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, size: 64),
                ),
              )
                  : Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.restaurant_menu, size: 120, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => viewModel.toggleFavorite(recipe.id),
                icon: Icon(
                  recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: recipe.isFavorite ? Colors.red : Colors.white,
                  shadows: const [Shadow(offset: Offset(0, 1), blurRadius: 3.0, color: Colors.black54)],
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(recipe.category), avatar: const Icon(Icons.category, size: 18)),
                      Chip(label: Text('${recipe.prepTime} min'), avatar: const Icon(Icons.access_time, size: 18)),
                      Chip(label: Text(recipe.difficulty), avatar: const Icon(Icons.signal_cellular_alt, size: 18)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Description', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(recipe.description, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  Text('Ingredients', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...recipe.ingredients.map((ingredient) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Expanded(child: Text(ingredient, style: Theme.of(context).textTheme.bodyLarge)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),
                  Text('Instructions', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...recipe.instructions.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 16, child: Text('${entry.key + 1}')),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.value, style: Theme.of(context).textTheme.bodyLarge)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Favorites Screen
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecipeViewModel>();
    final favoriteRecipes = viewModel.favoriteRecipes;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Favorites'),
      ),
      body: favoriteRecipes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No favorite recipes yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Add recipes to favorites to see them here', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favoriteRecipes.length,
        itemBuilder: (context, index) => RecipeCard(recipe: favoriteRecipes[index]),
      ),
    );
  }
}