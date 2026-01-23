import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/support_ticket_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/support_ticket_service.dart';
import '../utils/colors.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final SupportTicketService _ticketService = SupportTicketService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Soporte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTicketDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Ticket'),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  '¿Necesitas ayuda?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Crea un ticket y te responderemos pronto',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          // Lista de tickets
          Expanded(
            child: StreamBuilder<List<SupportTicketModel>>(
              stream: _ticketService.getUserTickets(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar tickets',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final tickets = snapshot.data ?? [];

                if (tickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes tickets',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea uno si necesitas ayuda',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    return _buildTicketCard(tickets[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket) {
    Color statusColor;
    IconData statusIcon;

    switch (ticket.status) {
      case TicketStatus.open:
        statusColor = Colors.blue;
        statusIcon = Icons.fiber_new;
        break;
      case TicketStatus.inProgress:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case TicketStatus.resolved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TicketStatus.closed:
        statusColor = Colors.grey;
        statusIcon = Icons.lock;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openTicketDetail(ticket),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ticket.category.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(ticket.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (ticket.messages.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${ticket.messages.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTicketDetail(SupportTicketModel ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(ticketId: ticket.id),
      ),
    );
  }

  void _showCreateTicketDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateTicketSheet(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} min';
    } else {
      return 'Ahora';
    }
  }
}

// Sheet para crear nuevo ticket
class CreateTicketSheet extends StatefulWidget {
  const CreateTicketSheet({super.key});

  @override
  State<CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<CreateTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final SupportTicketService _ticketService = SupportTicketService();
  final UserService _userService = UserService();

  TicketCategory _selectedCategory = TicketCategory.general;
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid ?? '';
      final userEmail = authService.currentUser?.email ?? '';

      // Obtener nombre del usuario
      final user = await _userService.getUserById(userId);
      final userName = user?.name ?? 'Usuario';

      await _ticketService.createTicket(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Título
              const Text(
                'Nuevo Ticket de Soporte',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Categoría
              const Text(
                'Categoría',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TicketCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: TicketCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Asunto
              const Text(
                'Asunto',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: 'Describe brevemente tu consulta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El asunto es requerido';
                  }
                  if (value.trim().length < 5) {
                    return 'El asunto debe tener al menos 5 caracteres';
                  }
                  return null;
                },
                inputFormatters: [
                  LengthLimitingTextInputFormatter(100),
                ],
              ),
              const SizedBox(height: 16),

              // Descripción
              const Text(
                'Descripción',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Describe tu problema o consulta en detalle',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es requerida';
                  }
                  if (value.trim().length < 20) {
                    return 'La descripción debe tener al menos 20 caracteres';
                  }
                  return null;
                },
                inputFormatters: [
                  LengthLimitingTextInputFormatter(500),
                ],
              ),
              const SizedBox(height: 24),

              // Botón enviar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enviar Ticket',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Pantalla de detalle del ticket
class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final SupportTicketService _ticketService = SupportTicketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  SupportTicketModel? _ticket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  void _loadTicket() {
    _ticketService.getTicket(widget.ticketId).listen((ticket) {
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _isLoading = false;
        });

        // Auto scroll cuando hay nuevos mensajes
        if (ticket != null && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid ?? '';
      final userEmail = authService.currentUser?.email ?? 'Usuario';

      await _ticketService.addMessage(
        ticketId: widget.ticketId,
        senderId: userId,
        senderName: userEmail.split('@').first,
        message: _messageController.text.trim(),
        isAdmin: false,
      );

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando...'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final ticket = _ticket;

    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ticket no encontrado'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('El ticket no existe'),
        ),
      );
    }

    final isClosed = ticket.status == TicketStatus.closed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Ticket #${ticket.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Info del ticket
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    _buildStatusChip(ticket.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      ticket.category.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(ticket.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mensajes
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Descripción original
                _buildMessageBubble(
                  message: ticket.description,
                  senderName: ticket.userName,
                  timestamp: ticket.createdAt,
                  isAdmin: false,
                  isOriginal: true,
                ),

                // Mensajes de la conversación
                ...ticket.messages.map((msg) => _buildMessageBubble(
                      message: msg.message,
                      senderName: msg.senderName,
                      timestamp: msg.timestamp,
                      isAdmin: msg.isAdmin,
                    )),
              ],
            ),
          ),

          // Input de mensaje
          if (!isClosed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Este ticket está cerrado',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TicketStatus status) {
    Color color;
    switch (status) {
      case TicketStatus.open:
        color = Colors.blue;
        break;
      case TicketStatus.inProgress:
        color = Colors.orange;
        break;
      case TicketStatus.resolved:
        color = Colors.green;
        break;
      case TicketStatus.closed:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required String senderName,
    required DateTime timestamp,
    required bool isAdmin,
    bool isOriginal = false,
  }) {
    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAdmin
              ? Colors.white
              : isOriginal
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: isAdmin ? Border.all(color: Colors.grey[300]!) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SOPORTE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                if (isAdmin) const SizedBox(width: 8),
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isAdmin
                        ? Colors.grey[700]
                        : isOriginal
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isAdmin
                    ? Colors.grey[800]
                    : isOriginal
                        ? Colors.grey[800]
                        : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isAdmin
                    ? Colors.grey[500]
                    : isOriginal
                        ? Colors.grey[500]
                        : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
