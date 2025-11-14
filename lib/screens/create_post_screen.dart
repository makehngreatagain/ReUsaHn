import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/article_model.dart';
import '../models/post_model.dart';
import '../utils/colors.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _suggestions = [];
  final _suggestionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _selectedImagePath;
  ArticleCategory _selectedCategory = ArticleCategory.otros;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar imagen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addSuggestion() {
    if (_suggestionController.text.trim().isNotEmpty) {
      setState(() {
        _suggestions.add(_suggestionController.text.trim());
        _suggestionController.clear();
      });
    }
  }

  void _removeSuggestion(int index) {
    setState(() {
      _suggestions.removeAt(index);
    });
  }

  void _createPost() {
    if (_formKey.currentState!.validate()) {
      if (_suggestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agrega al menos una sugerencia de intercambio'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Crear el nuevo post
      final newPost = PostModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        user: UserModel(
          id: 'current_user',
          name: 'Usuario Actual', // Aquí irá el usuario logueado
          profileImageUrl: '',
        ),
        article: ArticleModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: _selectedImagePath ?? 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800',
          interestedInExchangeFor: _suggestions,
          category: _selectedCategory,
        ),
        createdAt: DateTime.now(),
      );

      // Devolver el post a la pantalla anterior
      Navigator.pop(context, newPost);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Nueva Publicación',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título del artículo',
                hintText: 'Ej: Silla de Madera',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un título';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText: 'Describe tu artículo en detalle...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Selector de categoría
            DropdownButtonFormField<ArticleCategory>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoría del artículo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: ArticleCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (ArticleCategory? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Selector de imagen
            const Text(
              'Imagen del artículo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca para seleccionar imagen',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Sugerencias de intercambio
            const Text(
              'Sugerencias de intercambio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Chips de categorías predefinidas
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ArticleCategory.values.map((category) {
                final isSelected = _suggestions.contains(category.displayName);
                return FilterChip(
                  label: Text(category.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _suggestions.add(category.displayName);
                      } else {
                        _suggestions.remove(category.displayName);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: AppColors.chipBackground,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.chipText : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Campo para agregar sugerencia personalizada
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _suggestionController,
                    decoration: InputDecoration(
                      hintText: 'Agregar otra sugerencia personalizada',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _addSuggestion(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSuggestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Lista de sugerencias agregadas
            if (_suggestions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final suggestion = entry.value;
                  return Chip(
                    label: Text(suggestion),
                    backgroundColor: AppColors.chipBackground,
                    labelStyle: const TextStyle(
                      color: AppColors.chipText,
                      fontWeight: FontWeight.w500,
                    ),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.chipText,
                    ),
                    onDeleted: () => _removeSuggestion(index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),

            const SizedBox(height: 32),

            // Botón para publicar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Publicar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
