import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => RecipeViewModel(),
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
  bool isFavorite;

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.prepTime,
    required this.difficulty,
    required this.description,
    required this.ingredients,
    required this.instructions,
    this.isFavorite = false,
  });
}

// ViewModel
class RecipeViewModel extends ChangeNotifier {
  final List<Recipe> _recipes = [
    Recipe(
      id: '1',
      name: 'Spaghetti Carbonara',
      category: 'Italian',
      prepTime: 30,
      difficulty: 'Medium',
      description: 'Classic Italian pasta dish with eggs, cheese, and pancetta',
      ingredients: [
        '400g spaghetti',
        '200g pancetta',
        '4 eggs',
        '100g Parmesan cheese',
        'Black pepper',
        'Salt',
      ],
      instructions: [
        'Cook spaghetti according to package directions',
        'Fry pancetta until crispy',
        'Beat eggs with grated Parmesan',
        'Drain pasta and mix with pancetta',
        'Remove from heat and stir in egg mixture',
        'Season with black pepper and serve',
      ],
    ),
    Recipe(
      id: '2',
      name: 'Chicken Tikka Masala',
      category: 'Indian',
      prepTime: 45,
      difficulty: 'Hard',
      description: 'Creamy and spicy Indian chicken curry',
      ingredients: [
        '500g chicken breast',
        '200ml yogurt',
        '400ml coconut cream',
        '2 onions',
        'Ginger and garlic',
        'Tikka masala spices',
        'Tomato paste',
      ],
      instructions: [
        'Marinate chicken in yogurt and spices for 2 hours',
        'Grill chicken until charred',
        'Sauté onions, ginger, and garlic',
        'Add tomato paste and spices',
        'Add coconut cream and simmer',
        'Add grilled chicken and cook for 10 minutes',
      ],
    ),
    Recipe(
      id: '3',
      name: 'Caesar Salad',
      category: 'Salad',
      prepTime: 15,
      difficulty: 'Easy',
      description: 'Fresh romaine lettuce with Caesar dressing',
      ingredients: [
        'Romaine lettuce',
        '100g Parmesan cheese',
        'Croutons',
        '2 egg yolks',
        'Garlic',
        'Lemon juice',
        'Olive oil',
        'Anchovies',
      ],
      instructions: [
        'Wash and chop romaine lettuce',
        'Make dressing: blend egg yolks, garlic, anchovies, lemon',
        'Slowly add olive oil while blending',
        'Toss lettuce with dressing',
        'Top with Parmesan and croutons',
      ],
    ),
    Recipe(
      id: '4',
      name: 'Beef Tacos',
      category: 'Mexican',
      prepTime: 25,
      difficulty: 'Easy',
      description: 'Delicious Mexican tacos with seasoned beef',
      ingredients: [
        '500g ground beef',
        'Taco shells',
        'Lettuce',
        'Tomatoes',
        'Cheese',
        'Sour cream',
        'Taco seasoning',
      ],
      instructions: [
        'Brown ground beef in a pan',
        'Add taco seasoning and water',
        'Simmer until thickened',
        'Warm taco shells',
        'Assemble tacos with toppings',
      ],
    ),
    Recipe(
      id: '5',
      name: 'Pad Thai',
      category: 'Thai',
      prepTime: 35,
      difficulty: 'Medium',
      description: 'Traditional Thai stir-fried noodles',
      ingredients: [
        '200g rice noodles',
        '200g shrimp',
        '2 eggs',
        'Bean sprouts',
        'Peanuts',
        'Tamarind paste',
        'Fish sauce',
        'Palm sugar',
      ],
      instructions: [
        'Soak rice noodles in warm water',
        'Make sauce: mix tamarind, fish sauce, sugar',
        'Stir-fry shrimp and remove',
        'Scramble eggs in same pan',
        'Add noodles and sauce',
        'Add shrimp, bean sprouts, and peanuts',
      ],
    ),
  ];

  List<Recipe> get recipes => _recipes;
  List<Recipe> get favoriteRecipes =>
      _recipes.where((r) => r.isFavorite).toList();
  int get favoriteCount => favoriteRecipes.length;

  void toggleFavorite(String recipeId) {
    final recipe = _recipes.firstWhere((r) => r.id == recipeId);
    recipe.isFavorite = !recipe.isFavorite;
    notifyListeners();
  }

  Recipe? getRecipeById(String id) {
    try {
      return _recipes.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
}

// Main App
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
        cardTheme: CardThemeData (
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
      initialRoute: '/',
      routes: {
        '/': (context) => const MainNavigationScreen(),
        '/favorites': (context) => const FavoritesScreen(),
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

// Main Navigation with Bottom Navigation Bar
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
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Recipe Book'),
        actions: [
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
      body: isTablet
          ? _buildGridView(context, viewModel)
          : _buildListView(context, viewModel),
    );
  }

  Widget _buildListView(BuildContext context, RecipeViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.recipes.length,
      itemBuilder: (context, index) {
        final recipe = viewModel.recipes[index];
        return RecipeCard(recipe: recipe);
      },
    );
  }

  Widget _buildGridView(BuildContext context, RecipeViewModel viewModel) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: viewModel.recipes.length,
      itemBuilder: (context, index) {
        final recipe = viewModel.recipes[index];
        return RecipeCard(recipe: recipe);
      },
    );
  }
}

// Recipe Card
class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({
    super.key,
    required this.recipe,
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
    final viewModel = context.read<RecipeViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/recipe',
            arguments: recipe.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
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
                          style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.category,
                          style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                            Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => viewModel.toggleFavorite(recipe.id),
                    icon: Icon(
                      recipe.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
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
      ),
    );
  }
}

// Recipe Detail Screen
class RecipeDetailScreen extends StatelessWidget {
  final String recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

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
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(
            onPressed: () => viewModel.toggleFavorite(recipe.id),
            icon: Icon(
              recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: recipe.isFavorite ? Colors.red : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(recipe.category),
                        avatar: const Icon(Icons.category, size: 18),
                      ),
                      Chip(
                        label: Text('${recipe.prepTime} min'),
                        avatar: const Icon(Icons.access_time, size: 18),
                      ),
                      Chip(
                        label: Text(recipe.difficulty),
                        avatar: const Icon(Icons.signal_cellular_alt, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  // Ingredients
                  Text(
                    'Ingredients',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recipe.ingredients.map(
                        (ingredient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ingredient,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Instructions
                  Text(
                    'Instructions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recipe.instructions.asMap().entries.map(
                        (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            child: Text('${entry.key + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
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
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No favorite recipes yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add recipes to favorites to see them here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favoriteRecipes.length,
        itemBuilder: (context, index) {
          final recipe = favoriteRecipes[index];
          return RecipeCard(recipe: recipe);
        },
      ),
    );
  }
}