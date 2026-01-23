import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/support_ticket_model.dart';
import '../../services/support_ticket_service.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';

class AdminTicketsWebScreen extends StatefulWidget {
  const AdminTicketsWebScreen({super.key});

  @override
  State<AdminTicketsWebScreen> createState() => _AdminTicketsWebScreenState();
}

class _AdminTicketsWebScreenState extends State<AdminTicketsWebScreen> {
  final SupportTicketService _ticketService = SupportTicketService();
  final TextEditingController _searchController = TextEditingController();

  TicketStatus? _statusFilter;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tickets de Soporte',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gestiona las consultas de los usuarios',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                // Estadísticas rápidas
                _buildQuickStats(),
              ],
            ),
            const SizedBox(height: 24),

            // Filtros y búsqueda
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Búsqueda
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por asunto o usuario...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value.toLowerCase());
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Filtro por estado
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TicketStatus?>(
                            value: _statusFilter,
                            isExpanded: true,
                            hint: const Text('Todos los estados'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todos los estados'),
                              ),
                              ...TicketStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Row(
                                    children: [
                                      _buildStatusDot(status),
                                      const SizedBox(width: 8),
                                      Text(status.displayName),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() => _statusFilter = value);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Lista de tickets
            StreamBuilder<List<SupportTicketModel>>(
              stream: _ticketService.getAllTickets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                var tickets = snapshot.data ?? [];

                // Aplicar filtros
                if (_statusFilter != null) {
                  tickets = tickets.where((t) => t.status == _statusFilter).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  tickets = tickets.where((t) =>
                      t.subject.toLowerCase().contains(_searchQuery) ||
                      t.userName.toLowerCase().contains(_searchQuery) ||
                      t.userEmail.toLowerCase().contains(_searchQuery)).toList();
                }

                if (tickets.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay tickets',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _buildTicketRow(tickets[index]);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return FutureBuilder<Map<String, int>>(
      future: _ticketService.getTicketStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};

        return Row(
          children: [
            _buildStatChip(
              'Abiertos',
              stats['open'] ?? 0,
              Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              'En Progreso',
              stats['inProgress'] ?? 0,
              Colors.orange,
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              'Resueltos',
              stats['resolved'] ?? 0,
              Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(TicketStatus status) {
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
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTicketRow(SupportTicketModel ticket) {
    return InkWell(
      onTap: () => _showTicketDetail(ticket),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Estado
            _buildStatusBadge(ticket.status),
            const SizedBox(width: 16),

            // Info principal
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Usuario
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    ticket.userEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Categoría
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ticket.category.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Fecha
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(ticket.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (ticket.messages.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble, size: 12, color: Colors.grey[500]),
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
            ),
            const SizedBox(width: 8),

            // Acciones
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('Ver detalle'),
                    ],
                  ),
                ),
                if (ticket.status != TicketStatus.closed) ...[
                  const PopupMenuItem(
                    value: 'resolve',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Marcar resuelto'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'close',
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Cerrar ticket'),
                      ],
                    ),
                  ),
                ],
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleAction(value, ticket),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TicketStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case TicketStatus.open:
        color = Colors.blue;
        icon = Icons.fiber_new;
        break;
      case TicketStatus.inProgress:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case TicketStatus.resolved:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case TicketStatus.closed:
        color = Colors.grey;
        icon = Icons.lock;
        break;
    }

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, SupportTicketModel ticket) {
    switch (action) {
      case 'view':
        _showTicketDetail(ticket);
        break;
      case 'resolve':
        _updateStatus(ticket.id, TicketStatus.resolved);
        break;
      case 'close':
        _updateStatus(ticket.id, TicketStatus.closed);
        break;
      case 'delete':
        _confirmDelete(ticket);
        break;
    }
  }

  void _updateStatus(String ticketId, TicketStatus status) async {
    try {
      await _ticketService.updateTicketStatus(ticketId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a: ${status.displayName}'),
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
    }
  }

  void _confirmDelete(SupportTicketModel ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ticket'),
        content: Text('¿Estás seguro de eliminar el ticket "${ticket.subject}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _ticketService.deleteTicket(ticket.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ticket eliminado'),
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
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTicketDetail(SupportTicketModel ticket) {
    showDialog(
      context: context,
      builder: (context) => _TicketDetailDialog(ticket: ticket),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Dialog para ver detalle del ticket y responder
class _TicketDetailDialog extends StatefulWidget {
  final SupportTicketModel ticket;

  const _TicketDetailDialog({required this.ticket});

  @override
  State<_TicketDetailDialog> createState() => _TicketDetailDialogState();
}

class _TicketDetailDialogState extends State<_TicketDetailDialog> {
  final SupportTicketService _ticketService = SupportTicketService();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final adminEmail = authService.currentUser?.email ?? 'Admin';

      await _ticketService.addMessage(
        ticketId: widget.ticket.id,
        senderId: authService.currentUser?.uid ?? '',
        senderName: adminEmail.split('@').first,
        message: _replyController.text.trim(),
        isAdmin: true,
      );

      _replyController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respuesta enviada'),
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
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<SupportTicketModel?>(
          stream: _ticketService.getTicket(widget.ticket.id),
          builder: (context, snapshot) {
            final ticket = snapshot.data ?? widget.ticket;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.subject,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${ticket.userName} (${ticket.userEmail})',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ticket.category.displayName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Cambiar estado
                    if (ticket.status != TicketStatus.closed)
                      PopupMenuButton<TicketStatus>(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(ticket.status.displayName),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => TicketStatus.values.map((status) {
                          return PopupMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onSelected: (status) async {
                          await _ticketService.updateTicketStatus(ticket.id, status);
                        },
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Conversación
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      // Mensaje original
                      _buildMessage(
                        sender: ticket.userName,
                        message: ticket.description,
                        timestamp: ticket.createdAt,
                        isAdmin: false,
                      ),

                      // Mensajes
                      ...ticket.messages.map((msg) => _buildMessage(
                            sender: msg.senderName,
                            message: msg.message,
                            timestamp: msg.timestamp,
                            isAdmin: msg.isAdmin,
                          )),
                    ],
                  ),
                ),

                // Input de respuesta
                if (ticket.status != TicketStatus.closed) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          decoration: InputDecoration(
                            hintText: 'Escribe tu respuesta...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendReply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        icon: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: const Text('Enviar'),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessage({
    required String sender,
    required String message,
    required DateTime timestamp,
    required bool isAdmin,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAdmin ? Colors.blue[200]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SOPORTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              Text(
                sender,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
}
