import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/colors.dart';

class UserProfileHeader extends StatelessWidget {
  final UserModel user;

  const UserProfileHeader({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: user.profileImageUrl.isNotEmpty
              ? NetworkImage(user.profileImageUrl)
              : null,
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: user.profileImageUrl.isEmpty
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            user.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
