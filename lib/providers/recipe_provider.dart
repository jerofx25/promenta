import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

class RecipeProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  Recipe? _selectedRecipe;
  
  // Filter states
  MealType? _selectedMealType;
  String _searchQuery = '';

  // Getters
  List<Recipe> get recipes => _recipes;
  Recipe? get selectedRecipe => _selectedRecipe;
  MealType? get selectedMealType => _selectedMealType;
  String get searchQuery => _searchQuery;

  RecipeProvider() {
    _loadRecipes();
  }

  // Load recipes from SharedPreferences
  Future<void> _loadRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = prefs.getStringList('recipes');
    
    if (recipesJson == null || recipesJson.isEmpty) {
      // Initialize with sample data if none exists
      await _initializeSampleRecipes();
    } else {
      _recipes = recipesJson
          .map((json) => Recipe.fromJson(jsonDecode(json)))
          .toList();
      notifyListeners();
    }
  }

  // Save recipes to SharedPreferences
  Future<void> _saveRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = _recipes
        .map((recipe) => jsonEncode(recipe.toJson()))
        .toList();
    
    await prefs.setStringList('recipes', recipesJson);
  }

  // Initialize with sample recipes
  Future<void> _initializeSampleRecipes() async {
    _recipes = [
      Recipe(
        id: '1',
        name: 'Bowl de Avena Proteica',
        mealType: MealType.breakfast,
        ingredients: [
          '1/2 taza de avena',
          '1 scoop de proteu00edna en polvo',
          '1 plu00e1tano',
          '1 cucharada de mantequilla de almendras',
          '1/4 taza de leche de almendras',
          'Canela al gusto',
          'Frutos rojos para decorar'
        ],
        preparationSteps: [
          'Mezcla la avena con la leche y calienta en microondas por 2 minutos',
          'Au00f1ade la proteu00edna en polvo y mezcla bien',
          'Corta el plu00e1tano en rodajas y au00f1adelas encima',
          'Agrega la mantequilla de almendras, espolvorea canela y decora con frutos rojos'
        ],
        preparationTime: 10,
        calories: 450,
        imageUrl: "https://pixabay.com/get/g0ec6fa72d25a55e25af0a970e7730c8076bbad5efbd8bae2042cce66e05175fb1846eb7662be52fe9a424be7cbf3bf9738b432a53f632d5cca2f1497c7a19a78_1280.jpg",
        nutritionFacts: {
          'Proteu00ednas': '25g',
          'Carbohidratos': '65g',
          'Grasas': '12g',
          'Fibra': '8g'
        },
      ),
      Recipe(
        id: '2',
        name: 'Pollo al Horno con Vegetales',
        mealType: MealType.lunch,
        ingredients: [
          '200g de pechuga de pollo',
          '1 calabacu00edn',
          '1 pimiento rojo',
          '1 cebolla',
          '2 cucharadas de aceite de oliva',
          'Romero, tomillo y oru00e9gano al gusto',
          'Sal y pimienta'
        ],
        preparationSteps: [
          'Precalienta el horno a 200u00b0C',
          'Corta los vegetales en trozos medianos',
          'Coloca el pollo y los vegetales en una bandeja para horno',
          'Condimenta con las hierbas, sal y pimienta. Au00f1ade el aceite de oliva',
          'Hornea por 25-30 minutos o hasta que el pollo estu00e9 completamente cocinado'
        ],
        preparationTime: 40,
        calories: 380,
        imageUrl: "https://pixabay.com/get/g28ec79c4e9bf4686a4fc5db872d2132bd401da3e740d68b1b1cd37d36a418af271de541414fc8e2bb443a049997c8be7680d21719fcad3764c40af5b6ba61b9e_1280.jpg",
        nutritionFacts: {
          'Proteu00ednas': '35g',
          'Carbohidratos': '15g',
          'Grasas': '18g',
          'Fibra': '5g'
        },
      ),
      Recipe(
        id: '3',
        name: 'Mix de Frutos Secos y Yogurt',
        mealType: MealType.snack,
        ingredients: [
          '1 yogurt griego natural',
          '10g de almendras',
          '10g de nueces',
          '5g de semillas de calabaza',
          '1 cucharadita de miel (opcional)',
          'Canela al gusto'
        ],
        preparationSteps: [
          'Coloca el yogurt en un bowl',
          'Au00f1ade los frutos secos y semillas',
          'Opcionalmente, endulza con miel',
          'Espolvorea canela al gusto'
        ],
        preparationTime: 5,
        calories: 230,
        imageUrl: "https://pixabay.com/get/gfdd86ff01c56279f3426cfb171201ddff04d4c35df407958062a4cea811443edcb58ffca1fe525ca732fd8f057a3c87ec640b29f077a041d1d80cbd3e7452d60_1280.jpg",
        nutritionFacts: {
          'Proteu00ednas': '18g',
          'Carbohidratos': '12g',
          'Grasas': '14g',
          'Fibra': '3g'
        },
      ),
      Recipe(
        id: '4',
        name: 'Salmu00f3n con Espu00e1rragos y Quinoa',
        mealType: MealType.dinner,
        ingredients: [
          '150g de filete de salmu00f3n',
          '100g de espu00e1rragos',
          '1/2 taza de quinoa',
          '1 limu00f3n',
          '2 cucharadas de aceite de oliva',
          'Eneldo fresco',
          'Sal y pimienta'
        ],
        preparationSteps: [
          'Cocina la quinoa segu00fan las instrucciones del paquete',
          'Precalienta el horno a 180u00b0C',
          'Coloca el salmu00f3n en papel de aluminio, condimenta con sal, pimienta y zumo de limu00f3n',
          'Envuelve el salmu00f3n y hornea por 15-20 minutos',
          'Hierve los espu00e1rragos durante 3-4 minutos hasta que estu00e9n tiernos',
          'Sirve el salmu00f3n sobre la quinoa, con los espu00e1rragos al lado. Rociar con aceite de oliva y decorar con eneldo'
        ],
        preparationTime: 30,
        calories: 420,
        imageUrl: "https://pixabay.com/get/g76066f981ba2b24f1a1aa16ce9dd836b1d08a7edb65d47188b05264218f7f5ac7eded7b8acac776d287622d8a1d30a25d3802b9dbd18be3cfda9e741394d482b_1280.jpg",
        nutritionFacts: {
          'Proteu00ednas': '32g',
          'Carbohidratos': '25g',
          'Grasas': '22g',
          'Fibra': '4g'
        },
      ),
      Recipe(
        id: '5',
        name: 'Batido Verde Energizante',
        mealType: MealType.breakfast,
        ingredients: [
          '1 plu00e1tano',
          '1 puu00f1o de espinacas',
          '1/2 aguacate',
          '1 cucharada de semillas de chu00eda',
          '1 taza de leche vegetal',
          '1 cucharada de mantequilla de manu00ed natural',
          'Hielo al gusto'
        ],
        preparationSteps: [
          'Au00f1ade todos los ingredientes a una licuadora',
          'Procesa hasta obtener una mezcla homogu00e9nea',
          'Si estu00e1 muy espeso, puedes agregar mu00e1s leche vegetal',
          'Sirve inmediatamente'
        ],
        preparationTime: 5,
        calories: 320,
        imageUrl: "https://pixabay.com/get/gbe8ffcc9bd8444b858f24aed18d03e24befb4acab1de3dc318b4f37d0a9e1bd403386798e2ece642657ede4325fd3d5faea351efcfda352c494e32d5b96c3776_1280.jpg",
        nutritionFacts: {
          'Proteu00ednas': '10g',
          'Carbohidratos': '38g',
          'Grasas': '18g',
          'Fibra': '9g'
        },
      ),
      Recipe(
        id: '6',
        name: 'Bowl de Atu00fan y Arroz Integral',
        mealType: MealType.lunch,
        ingredients: [
          '1 lata de atu00fan al natural',
          '1/2 taza de arroz integral cocido',
          '1/2 aguacate',
          '1/4 taza de edamame',
          '1/4 pepino en rodajas',
          '2 cucharadas de salsa de soja baja en sodio',
          '1 cucharadita de aceite de su00e9samo',
          'Semillas de su00e9samo para decorar'
        ],
        preparationSteps: [
          'Coloca el arroz integral en un bowl',
          'Au00f1ade el atu00fan escurrido',
          'Agrega el aguacate cortado en cubos, el edamame y el pepino',
          'Mezcla la salsa de soja con el aceite de su00e9samo y rociar sobre el bowl',
          'Decora con semillas de su00e9samo'
        ],
        preparationTime: 15,
        calories: 390,
        imageUrl: "https://pixabay.com/get/g540a702b00648cb78498f6d3ff24517139eab53d63f3879f8218337d8ac664ac9fd60a6f5cbe2249b6333079b006bfceb19db4507cdc6ab2eed9a4ef1302245a_1280.jpg",
        nutritionFacts: {
          'Proteu00ednas': '30g',
          'Carbohidratos': '40g',
          'Grasas': '12g',
          'Fibra': '7g'
        },
      ),
      Recipe(
        id: '7',
        name: 'Muffins de Plu00e1tano y Nueces',
        mealType: MealType.snack,
        ingredients: [
          '2 plu00e1tanos maduros',
          '2 huevos',
          '1/4 taza de aceite de coco',
          '1/4 taza de miel',
          '1 taza de harina de avena',
          '1 cucharadita de levadura en polvo',
          '1/2 cucharadita de canela',
          '1/4 taza de nueces picadas'
        ],
        preparationSteps: [
          'Precalienta el horno a 180u00b0C y prepara un molde para muffins',
          'Machaca los plu00e1tanos en un bowl',
          'Au00f1ade los huevos, el aceite de coco y la miel. Mezcla bien',
          'Incorpora la harina de avena, la levadura y la canela',
          'Agrega las nueces y mezcla suavemente',
          'Vierte la mezcla en el molde y hornea por 20-25 minutos'
        ],
        preparationTime: 35,
        calories: 180,
        imageUrl: "https://pixabay.com/get/gc9b40e17e2946379f19e9cc5bdadff09b4024690f11181fd63075363b428fe78d15b9cebb4af11330691abe1d279031469430e60334c5a1ca455e8d3babe1346_1280.jpg",
        nutritionFacts: {
          'Proteu00ednas': '5g',
          'Carbohidratos': '22g',
          'Grasas': '10g',
          'Fibra': '3g'
        },
      ),
      Recipe(
        id: '8',
        name: 'Tofu Salteado con Verduras',
        mealType: MealType.dinner,
        ingredients: [
          '200g de tofu firme',
          '1 bru00f3coli pequeu00f1o',
          '1 zanahoria',
          '1 pimiento rojo',
          '2 dientes de ajo',
          '2 cucharadas de salsa de soja',
          '1 cucharada de aceite de su00e9samo',
          '1 cucharadita de jengibre rallado',
          'Semillas de su00e9samo para decorar'
        ],
        preparationSteps: [
          'Corta el tofu en cubos y presiu00f3nalo con papel absorbente para eliminar el exceso de agua',
          'Corta todas las verduras en trozos pequeu00f1os',
          'Calienta el aceite en un wok o sartu00e9n grande',
          'Saltea el ajo y jengibre por 1 minuto',
          'Au00f1ade el tofu y dora por 3-4 minutos',
          'Agrega las verduras y saltea por 5-7 minutos hasta que estu00e9n tiernas pero crujientes',
          'Incorpora la salsa de soja, mezcla bien y cocina por 1 minuto mu00e1s',
          'Sirve caliente y decora con semillas de su00e9samo'
        ],
        preparationTime: 25,
        calories: 320,
        imageUrl: "https://pixabay.com/get/g6b2e2b0d2c35ef3316c2802814f6cff36d1c96725aa1b945a4374c7c4b187f5c25918bcccbfbe0eb59ffaec6e312c02c6a0cd66e5d6b4504ac785f151acd6c42_1280.jpg",
        nutritionFacts: {
          'Proteu00ednas': '22g',
          'Carbohidratos': '25g',
          'Grasas': '15g',
          'Fibra': '8g'
        },
      ),
    ];

    await _saveRecipes();
    notifyListeners();
  }

  // Set the selected recipe
  void selectRecipe(String id) {
    _selectedRecipe = _recipes.firstWhere(
      (recipe) => recipe.id == id,
      orElse: () => _recipes.first,
    );
    notifyListeners();
  }

  // Set meal type filter
  void setMealTypeFilter(MealType? mealType) {
    _selectedMealType = mealType;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Get filtered recipes
  List<Recipe> getFilteredRecipes() {
    return _recipes.where((recipe) {
      // Filter by meal type if selected
      bool matchesMealType = _selectedMealType == null || recipe.mealType == _selectedMealType;
      
      // Filter by search query
      bool matchesSearch = _searchQuery.isEmpty ||
          recipe.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesMealType && matchesSearch;
    }).toList();
  }

  // Get recipes by meal type
  List<Recipe> getRecipesByMealType(MealType mealType) {
    return _recipes.where((recipe) => recipe.mealType == mealType).toList();
  }
}