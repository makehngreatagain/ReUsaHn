import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/exchange_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/exchange_service.dart';
import '../utils/colors.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ExchangeService _exchangeService = ExchangeService();

  UserModel? _otherUser;
  ChatModel? _chatData;
  ExchangeModel? _activeExchange;
  int _lastMessageCount = 0;
  bool _isLoadingExchange = false;

  @override
  void initState() {
    super.initState();
    _loadChatData();
    _listenToMessages();
    _loadActiveExchange();
    _listenToActiveExchange();
  }

  Future<void> _loadChatData() async {
    // Cargar información del chat
    final chatStream = _chatService.getChat(widget.chatId);
    chatStream.listen((chat) async {
      if (chat != null && mounted) {
        setState(() {
          _chatData = chat;
        });

        // Cargar datos del otro usuario
        final otherUserId = chat.getOtherUserId(widget.currentUserId);
        final user = await _authService.getUserById(otherUserId);
        if (mounted) {
          setState(() {
            _otherUser = user;
          });
        }
      }
    });
  }

  void _listenToMessages() {
    // Escuchar mensajes y marcarlos como leídos cuando cambien
    _chatService.getChatMessages(widget.chatId).listen((messages) {
      if (messages.length != _lastMessageCount) {
        _lastMessageCount = messages.length;
        // Marcar como leídos después de un pequeño delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _chatService.markMessagesAsRead(widget.chatId, widget.currentUserId);
          }
        });
      }
    });
  }

  Future<void> _loadActiveExchange() async {
    try {
      final exchange = await _exchangeService.getActiveExchangeForChat(widget.chatId);
      if (mounted) {
        setState(() {
          _activeExchange = exchange;
        });
      }
    } catch (e) {
      // Error silencioso, no hay intercambio activo
    }
  }

  void _listenToActiveExchange() {
    // Escuchar cambios en el intercambio activo
    _exchangeService.getActiveExchangeStream(widget.chatId).listen((exchange) {
      if (mounted) {
        setState(() {
          _activeExchange = exchange;
        });
      }
    });
  }

  Future<void> _proposeExchange() async {
    if (_chatData == null || _otherUser == null) return;

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proponer Intercambio'),
        content: Text(
          '¿Quieres proponer un intercambio con ${_otherUser!.name} sobre "${_chatData!.postTitle}"?\n\nAmbos deberán confirmar el intercambio para que se complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proponer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingExchange = true);

    try {
      final currentUser = await _authService.getUserById(widget.currentUserId);
      if (currentUser == null) throw Exception('Usuario no encontrado');

      await _exchangeService.proposeExchange(
        chatId: widget.chatId,
        postId: _chatData!.postId,
        user1Id: widget.currentUserId,
        user1Name: currentUser.name,
        user1ImageUrl: currentUser.profileImageUrl,
        user2Id: _otherUser!.id,
        user2Name: _otherUser!.name,
        user2ImageUrl: _otherUser!.profileImageUrl,
      );

      // Recargar intercambio activo
      await _loadActiveExchange();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Intercambio propuesto. Esperando confirmación del otro usuario.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingExchange = false);
      }
    }
  }

  Future<void> _confirmExchange() async {
    if (_activeExchange == null) return;

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Intercambio'),
        content: const Text(
          '¿Confirmas que realizaste este intercambio?\n\nAl confirmar, se contabilizará en tu progreso de retos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingExchange = true);

    try {
      await _exchangeService.confirmExchange(
        exchangeId: _activeExchange!.id,
        userId: widget.currentUserId,
      );

      // Recargar intercambio activo
      await _loadActiveExchange();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Intercambio confirmado! Se ha actualizado tu progreso.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingExchange = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        text: messageText,
      );

      // Scroll al final después de enviar
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatMessageTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  Widget _buildExchangeBanner() {
    if (_otherUser == null) {
      return const SizedBox.shrink();
    }

    // Caso 1: No hay intercambio activo - mostrar botón para proponer
    if (_activeExchange == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Listos para intercambiar?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Propón un intercambio con ${_otherUser!.name}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isLoadingExchange ? null : _proposeExchange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: _isLoadingExchange
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : const Icon(Icons.handshake, size: 18),
                label: const Text(
                  'Proponer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Caso 2: Intercambio completado
    if (_activeExchange!.isCompleted) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.green.shade200, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Intercambio Completado!',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ambos confirmaron el intercambio',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
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

    // Caso 3: Usuario actual propuso y está esperando confirmación
    if (_activeExchange!.user1Id == widget.currentUserId &&
        _activeExchange!.user1Confirmed &&
        !_activeExchange!.user2Confirmed) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.orange.shade200, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.hourglass_empty,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intercambio Propuesto',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Esperando que ${_otherUser!.name} confirme',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
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

    // Caso 4: El otro usuario propuso y este debe confirmar
    if (_activeExchange!.user2Id == widget.currentUserId &&
        !_activeExchange!.user2Confirmed) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notification_important,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¡Te propusieron un intercambio!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_otherUser!.name} quiere intercambiar contigo',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isLoadingExchange ? null : _confirmExchange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade700,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                icon: _isLoadingExchange
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                        ),
                      )
                    : const Icon(Icons.check_circle, size: 20),
                label: const Text(
                  'Confirmar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _deleteChat() async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Chat'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta conversación?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _chatService.deleteChat(widget.chatId);

      if (mounted) {
        // Volver a la pantalla anterior
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: _otherUser == null || _chatData == null
            ? const Text('Cargando...')
            : Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: _otherUser!.profileImageUrl.isNotEmpty
                        ? NetworkImage(_otherUser!.profileImageUrl)
                        : null,
                    child: _otherUser!.profileImageUrl.isEmpty
                        ? Text(
                            _otherUser!.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _otherUser!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _chatData!.postTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          // Botón de intercambio
          if (_activeExchange == null)
            // No hay intercambio, mostrar botón para proponer
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Proponer intercambio',
              onPressed: _isLoadingExchange ? null : _proposeExchange,
            )
          else if (_activeExchange!.isCompleted)
            // Intercambio completado, mostrar check
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.check_circle, color: Colors.greenAccent),
            )
          else if (_activeExchange!.user1Id == widget.currentUserId && _activeExchange!.user1Confirmed && !_activeExchange!.user2Confirmed)
            // El usuario actual propuso y está esperando confirmación
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.hourglass_empty, color: Colors.orangeAccent),
            )
          else if (_activeExchange!.user2Id == widget.currentUserId && !_activeExchange!.user2Confirmed)
            // El otro usuario propuso y este debe confirmar
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Confirmar intercambio',
              onPressed: _isLoadingExchange ? null : _confirmExchange,
            ),
          // Botón de eliminar chat
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteChat();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Eliminar chat',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de estado de intercambio
          _buildExchangeBanner(),

          // Lista de mensajes con StreamBuilder
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar mensajes: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No hay mensajes aún',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envía el primer mensaje',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll al final cuando hay mensajes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUserId;

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      formatTime: _formatMessageTime,
                    );
                  },
                );
              },
            ),
          ),

          // Input de mensaje
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
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
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String Function(DateTime) formatTime;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) const Spacer(flex: 2),
          Flexible(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isMe) const Spacer(flex: 2),
        ],
      ),
    );
  }
}
