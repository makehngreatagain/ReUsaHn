import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/article_model.dart';
import '../utils/colors.dart';
import '../utils/dummy_data.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

class PublicationsScreen extends StatefulWidget {
  const PublicationsScreen({super.key});

  @override
  State<PublicationsScreen> createState() => _PublicationsScreenState();
}

class _PublicationsScreenState extends State<PublicationsScreen> {
  List<PostModel> posts = [];
  List<PostModel> filteredPosts = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ArticleCategory? _selectedCategory;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    // Inicializar con los posts de prueba
    posts = List.from(DummyData.posts);
    filteredPosts = List.from(posts);

    // Escuchar el scroll para minimizar/expandir la barra
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && _isExpanded) {
        setState(() {
          _isExpanded = false;
        });
      } else if (_scrollController.offset <= 50 && !_isExpanded) {
        setState(() {
          _isExpanded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterPosts() {
    setState(() {
      filteredPosts = posts.where((post) {
        // Filtrar por búsqueda
        final matchesSearch = _searchController.text.isEmpty ||
            post.article.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            post.article.description.toLowerCase().contains(_searchController.text.toLowerCase());

        // Filtrar por categoría
        final matchesCategory = _selectedCategory == null || post.article.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _navigateToCreatePost() async {
    final newPost = await Navigator.push<PostModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );

    if (newPost != null) {
      setState(() {
        // Agregar el nuevo post al inicio de la lista
        posts.insert(0, newPost);
        // También agregar a DummyData para que persista
        DummyData.posts.insert(0, newPost);
        // Refiltrar los posts
        _filterPosts();
      });

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('¡Publicación creada exitosamente!'),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _deletePost(PostModel post) {
    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                posts.remove(post);
                DummyData.posts.remove(post);
                _filterPosts();
              });
              Navigator.pop(context);

              // Mostrar mensaje de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('¡Publicación eliminada exitosamente!'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mercado de Intercambios',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            color: AppColors.primary,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barra de búsqueda - siempre visible pero más pequeña cuando está minimizada
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Buscar artículos...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.primary),
                              onPressed: () {
                                _searchController.clear();
                                _filterPosts();
                              },
                            )
                          : IconButton(
                              icon: Icon(
                                _isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: AppColors.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: _isExpanded ? 16 : 12,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) => _filterPosts(),
                  ),
                ),
                // Filtros y botón - se ocultan cuando está minimizado
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Column(
                          children: [
                            const SizedBox(height: 12),
                            // Filtro de categorías
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // Opción "Todas"
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: const Text('Todas'),
                                      selected: _selectedCategory == null,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedCategory = null;
                                          _filterPosts();
                                        });
                                      },
                                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                                      selectedColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: _selectedCategory == null ? AppColors.primary : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      side: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  // Categorías
                                  ...ArticleCategory.values.map((category) {
                                    final isSelected = _selectedCategory == category;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(category.displayName),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedCategory = selected ? category : null;
                                            _filterPosts();
                                          });
                                        },
                                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                                        selectedColor: Colors.white,
                                        labelStyle: TextStyle(
                                          color: isSelected ? AppColors.primary : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        side: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Botón de nueva publicación
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _navigateToCreatePost,
                                icon: const Icon(Icons.add),
                                label: const Text('Nueva Publicación'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Lista de posts filtrados
          Expanded(
            child: filteredPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron artículos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredPosts.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      return PostCard(
                        post: post,
                        onDelete: () => _deletePost(post),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
