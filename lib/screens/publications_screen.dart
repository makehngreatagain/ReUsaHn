import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/article_model.dart';
import '../services/post_service.dart';
import '../utils/colors.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

class PublicationsScreen extends StatefulWidget {
  const PublicationsScreen({super.key});

  @override
  State<PublicationsScreen> createState() => _PublicationsScreenState();
}

enum SortOption {
  newest('Más reciente'),
  oldest('Más antiguo'),
  titleAZ('Título A-Z'),
  titleZA('Título Z-A');

  final String displayName;
  const SortOption(this.displayName);
}

enum AvailabilityFilter {
  all('Todos'),
  available('Disponibles'),
  exchanged('Intercambiados');

  final String displayName;
  const AvailabilityFilter(this.displayName);
}

class _PublicationsScreenState extends State<PublicationsScreen> {
  final PostService _postService = PostService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ArticleCategory? _selectedCategory;
  AvailabilityFilter _availabilityFilter = AvailabilityFilter.all;
  SortOption _sortOption = SortOption.newest;
  bool _isExpanded = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Escuchar cambios en el campo de búsqueda con debounce
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text.toLowerCase();
    if (_searchQuery != newQuery) {
      setState(() {
        _searchQuery = newQuery;
      });
    }
  }

  void _toggleFilters() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<PostModel> _filterAndSortPosts(List<PostModel> posts) {
    // Primero filtrar
    var filtered = posts.where((post) {
      // Filtrar por búsqueda
      final matchesSearch = _searchQuery.isEmpty ||
          post.article.title.toLowerCase().contains(_searchQuery) ||
          post.article.description.toLowerCase().contains(_searchQuery);

      // Filtrar por categoría
      final matchesCategory = _selectedCategory == null || post.article.category == _selectedCategory;

      // Filtrar por disponibilidad
      final matchesAvailability = _availabilityFilter == AvailabilityFilter.all ||
          (_availabilityFilter == AvailabilityFilter.available && post.article.isAvailable) ||
          (_availabilityFilter == AvailabilityFilter.exchanged && !post.article.isAvailable);

      return matchesSearch && matchesCategory && matchesAvailability;
    }).toList();

    // Luego ordenar
    switch (_sortOption) {
      case SortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.titleAZ:
        filtered.sort((a, b) => a.article.title.toLowerCase().compareTo(b.article.title.toLowerCase()));
        break;
      case SortOption.titleZA:
        filtered.sort((a, b) => b.article.title.toLowerCase().compareTo(a.article.title.toLowerCase()));
        break;
    }

    return filtered;
  }

  void _navigateToCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );

    // El CreatePostScreen ya muestra su propio mensaje de éxito
    // No necesitamos hacer nada aquí porque el StreamBuilder se actualizará automáticamente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Publicaciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreatePost,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Publicación'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(_isExpanded ? 16 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra de búsqueda con botón de filtros
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar publicaciones...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón para mostrar/ocultar filtros
                    Material(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _toggleFilters,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  // Filtro por disponibilidad y ordenamiento
                  Row(
                    children: [
                      // Filtro de disponibilidad
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<AvailabilityFilter>(
                              value: _availabilityFilter,
                              isExpanded: true,
                              icon: const Icon(Icons.filter_list, size: 20),
                              items: AvailabilityFilter.values.map((filter) {
                                return DropdownMenuItem(
                                  value: filter,
                                  child: Row(
                                    children: [
                                      Icon(
                                        filter == AvailabilityFilter.all
                                            ? Icons.view_list
                                            : filter == AvailabilityFilter.available
                                                ? Icons.check_circle
                                                : Icons.check_circle_outline,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        filter.displayName,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _availabilityFilter = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Ordenamiento
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SortOption>(
                              value: _sortOption,
                              isExpanded: true,
                              icon: const Icon(Icons.sort, size: 20),
                              items: SortOption.values.map((sort) {
                                return DropdownMenuItem(
                                  value: sort,
                                  child: Row(
                                    children: [
                                      Icon(
                                        sort == SortOption.newest || sort == SortOption.oldest
                                            ? Icons.access_time
                                            : Icons.sort_by_alpha,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          sort.displayName,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _sortOption = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filtro por categoría
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Todas'),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 8),
                        ...ArticleCategory.values.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category.displayName),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? category : null;
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ] else if (_selectedCategory != null) ...[
                  // Mostrar categoría seleccionada cuando está colapsado
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_selectedCategory!.displayName),
                              const SizedBox(width: 4),
                              const Icon(Icons.close, size: 16),
                            ],
                          ),
                          selected: true,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista de publicaciones con StreamBuilder
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: _postService.getApprovedPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar publicaciones',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final allPosts = snapshot.data ?? [];
                final filteredPosts = _filterAndSortPosts(allPosts);

                if (filteredPosts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allPosts.isEmpty
                              ? 'No hay publicaciones todavía'
                              : 'No se encontraron publicaciones',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allPosts.isEmpty
                              ? 'Sé el primero en publicar un artículo'
                              : 'Intenta con otros filtros de búsqueda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (allPosts.isEmpty)
                          ElevatedButton.icon(
                            onPressed: _navigateToCreatePost,
                            icon: const Icon(Icons.add),
                            label: const Text('Crear Publicación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // El StreamBuilder se actualiza automáticamente
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PostCard(post: filteredPosts[index]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
