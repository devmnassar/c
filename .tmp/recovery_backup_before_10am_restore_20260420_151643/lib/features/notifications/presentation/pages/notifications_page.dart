import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  static const String id = '/notifications';
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF23C1B2);

    final notifications = [
      {
        'title': 'New Order #1234',
        'time': '10 mins ago',
        'body': 'Pickup required at Al Olaya',
        'type': 'order',
        'isUnread': true,
      },
      {
        'title': 'Order #1230 Completed',
        'time': '1 hour ago',
        'body': 'Customer successfully received order',
        'type': 'success',
        'isUnread': true,
      },
      {
        'title': 'System Update',
        'time': '2 hours ago',
        'body': 'Your app was updated to version 1.0.1',
        'type': 'system',
        'isUnread': false,
      },
      {
        'title': 'Promotion Available',
        'time': '1 day ago',
        'body': 'Complete 5 deliveries to get 50 SAR bonus',
        'type': 'promo',
        'isUnread': false,
      },
      {
        'title': 'Tip Received',
        'time': '2 days ago',
        'body': 'You received a tip of 10 SAR from Order #1120',
        'type': 'success',
        'isUnread': false,
      },
      {
        'title': 'Document Approved',
        'time': '3 days ago',
        'body': 'Your vehicle registration has been approved',
        'type': 'document',
        'isUnread': false,
      },
      {
        'title': 'Welcome to Gaseel',
        'time': '1 week ago',
        'body': 'Get started with delivering orders!',
        'type': 'system',
        'isUnread': false,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final type = notif['type'] as String;
          final isUnread = notif['isUnread'] as bool;

          IconData iconData;
          Color iconColor;
          Color bgColor;

          switch (type) {
            case 'order':
              iconData = Icons.local_shipping_rounded;
              iconColor = const Color(0xFF3B82F6);
              bgColor = const Color(0xFFEFF6FF);
              break;
            case 'success':
              iconData = Icons.check_circle_rounded;
              iconColor = const Color(0xFF10B981);
              bgColor = const Color(0xFFECFDF5);
              break;
            case 'promo':
              iconData = Icons.local_offer_rounded;
              iconColor = const Color(0xFFF59E0B);
              bgColor = const Color(0xFFFFFBEB);
              break;
            case 'document':
              iconData = Icons.description_rounded;
              iconColor = const Color(0xFF8B5CF6);
              bgColor = const Color(0xFFF5F3FF);
              break;
            case 'system':
            default:
              iconData = Icons.settings_rounded;
              iconColor = const Color(0xFF6B7280);
              bgColor = const Color(0xFFF3F4F6);
              break;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isUnread ? Colors.white : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnread
                    ? primaryColor.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.1),
                width: isUnread ? 1.5 : 1,
              ),
              boxShadow: isUnread
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['title'] as String,
                                    style: TextStyle(
                                      fontWeight: isUnread
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 15,
                                      color: isUnread
                                          ? const Color(0xFF111827)
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notif['body'] as String,
                              style: TextStyle(
                                color: isUnread
                                    ? const Color(0xFF4B5563)
                                    : const Color(0xFF6B7280),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notif['time'] as String,
                              style: TextStyle(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
