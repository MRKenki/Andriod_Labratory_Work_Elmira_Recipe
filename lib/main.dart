import 'package:flutter/material.dart';

void main() {
  runApp(const RecipeBookApp());
}

class Recipe {
  final String id;
  final String name;
  final String category;
  final int prepTime;
  final String difficulty;
  bool isFavorite;

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.prepTime,
    required this.difficulty,
    this.isFavorite = false,
  });
}

class RecipeBookApp extends StatelessWidget {
  const RecipeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Recipe> _recipes = [
    Recipe(
      id: '1',
      name: 'Spaghetti Carbonara',
      category: 'Italian',
      prepTime: 30,
      difficulty: 'Medium',
    ),
    Recipe(
      id: '2',
      name: 'Chicken Tikka Masala',
      category: 'Indian',
      prepTime: 45,
      difficulty: 'Hard',
    ),
    Recipe(
      id: '3',
      name: 'Caesar Salad',
      category: 'Salad',
      prepTime: 15,
      difficulty: 'Easy',
    ),
    Recipe(
      id: '4',
      name: 'Beef Tacos',
      category: 'Mexican',
      prepTime: 25,
      difficulty: 'Easy',
    ),
    Recipe(
      id: '5',
      name: 'Pad Thai',
      category: 'Thai',
      prepTime: 35,
      difficulty: 'Medium',
    ),
    Recipe(
      id: '6',
      name: 'Greek Moussaka',
      category: 'Greek',
      prepTime: 90,
      difficulty: 'Hard',
    ),
    Recipe(
      id: '7',
      name: 'French Onion Soup',
      category: 'French',
      prepTime: 60,
      difficulty: 'Medium',
    ),
    Recipe(
      id: '8',
      name: 'Sushi Rolls',
      category: 'Japanese',
      prepTime: 40,
      difficulty: 'Hard',
    ),
  ];

  void _toggleFavorite(String recipeId) {
    setState(() {
      final recipe = _recipes.firstWhere((r) => r.id == recipeId);
      recipe.isFavorite = !recipe.isFavorite;
    });
  }

  int get _favoriteCount => _recipes.where((r) => r.isFavorite).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Recipe Book'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Badge(
                label: Text('$_favoriteCount'),
                isLabelVisible: _favoriteCount > 0,
                child: const Icon(Icons.favorite),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return RecipeCard(
            recipe: recipe,
            onFavoriteToggle: () => _toggleFavorite(recipe.id),
          );
        },
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onFavoriteToggle;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onFavoriteToggle,
  });

  Color _getDifficultyColor() {
    switch (recipe.difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                  onPressed: onFavoriteToggle,
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
                  ),
                  side: BorderSide.none,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${recipe.prepTime} min'),
                  avatar: const Icon(Icons.access_time, size: 18),
                  side: BorderSide.none,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}