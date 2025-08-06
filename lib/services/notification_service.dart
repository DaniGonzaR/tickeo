import 'package:flutter/material.dart';
import 'package:tickeo/models/bill.dart';
import 'package:tickeo/models/payment.dart';

/// Service for managing notifications and alerts within the app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Show a confirmation dialog for important actions
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            return AlertDialog(
              title: Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                message,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 14,
                  height: 1.4,
                ),
              ),
              contentPadding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 24,
                isMobile ? 16 : 20,
                isMobile ? 20 : 24,
                isMobile ? 8 : 12,
              ),
              actionsPadding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                0,
                isMobile ? 12 : 16,
                isMobile ? 12 : 16,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    minimumSize: Size(isMobile ? 80 : 64, isMobile ? 44 : 36),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 12,
                      vertical: isMobile ? 12 : 8,
                    ),
                  ),
                  child: Text(
                    cancelText,
                    style: TextStyle(fontSize: isMobile ? 16 : 14),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    minimumSize: Size(isMobile ? 80 : 64, isMobile ? 44 : 36),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 12,
                      vertical: isMobile ? 12 : 8,
                    ),
                  ),
                  child: Text(
                    confirmText,
                    style: TextStyle(fontSize: isMobile ? 16 : 14),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    return result ?? false;
  }

  /// Show bill completion confirmation
  static Future<bool> showBillCompletionDialog({
    required BuildContext context,
    required Bill bill,
  }) async {
    final unpaidParticipants = bill.payments
        .where((payment) => !payment.isPaid)
        .map((payment) => payment.participantName)
        .toList();

    String message = 'Are you sure you want to complete this bill?';
    
    if (unpaidParticipants.isNotEmpty) {
      message += '\n\nWarning: The following participants haven\'t paid yet:\n';
      message += unpaidParticipants.map((name) => '• $name').join('\n');
    }

    return await showConfirmationDialog(
      context: context,
      title: 'Complete Bill',
      message: message,
      confirmText: 'Complete',
      confirmColor: unpaidParticipants.isEmpty ? Colors.green : Colors.orange,
    );
  }

  /// Show delete confirmation dialog
  static Future<bool> showDeleteConfirmationDialog({
    required BuildContext context,
    required String itemType,
    required String itemName,
  }) async {
    return await showConfirmationDialog(
      context: context,
      title: 'Delete $itemType',
      message: 'Are you sure you want to delete "$itemName"?\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: Colors.red,
    );
  }

  /// Show payment reminder dialog
  static Future<void> showPaymentReminderDialog({
    required BuildContext context,
    required List<Payment> unpaidPayments,
  }) async {
    if (unpaidPayments.isEmpty) return;

    final totalUnpaid = unpaidPayments.fold<double>(
      0.0,
      (sum, payment) => sum + payment.amount,
    );

    String message = 'Pending payments:\n\n';
    for (final payment in unpaidPayments) {
      message += '• ${payment.participantName}: €${payment.amount.toStringAsFixed(2)}\n';
    }
    message += '\nTotal unpaid: €${totalUnpaid.toStringAsFixed(2)}';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            return AlertDialog(
              title: Text(
                'Payment Reminder',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 14,
                    height: 1.4,
                  ),
                ),
              ),
              contentPadding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 24,
                isMobile ? 16 : 20,
                isMobile ? 20 : 24,
                isMobile ? 8 : 12,
              ),
              actionsPadding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                0,
                isMobile ? 12 : 16,
                isMobile ? 12 : 16,
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(isMobile ? 80 : 64, isMobile ? 44 : 36),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 12,
                      vertical: isMobile ? 12 : 8,
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(fontSize: isMobile ? 16 : 14),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Show bill summary dialog
  static Future<void> showBillSummaryDialog({
    required BuildContext context,
    required Bill bill,
  }) async {
    final totalPaid = bill.getTotalPaid();
    final remaining = bill.getRemainingAmount();
    final completionPercentage = bill.total > 0 ? (totalPaid / bill.total * 100) : 0;

    String message = 'Bill Summary:\n\n';
    message += 'Total: €${bill.total.toStringAsFixed(2)}\n';
    message += 'Paid: €${totalPaid.toStringAsFixed(2)}\n';
    message += 'Remaining: €${remaining.toStringAsFixed(2)}\n';
    message += 'Completion: ${completionPercentage.toStringAsFixed(1)}%\n\n';
    
    message += 'Participants: ${bill.participants.length}\n';
    message += 'Items: ${bill.items.length}';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            return AlertDialog(
              title: Text(
                '${bill.name} - Summary',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 14,
                    height: 1.4,
                  ),
                ),
              ),
              contentPadding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 24,
                isMobile ? 16 : 20,
                isMobile ? 20 : 24,
                isMobile ? 8 : 12,
              ),
              actionsPadding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                0,
                isMobile ? 12 : 16,
                isMobile ? 12 : 16,
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(isMobile ? 80 : 64, isMobile ? 44 : 36),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 12,
                      vertical: isMobile ? 12 : 8,
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(fontSize: isMobile ? 16 : 14),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Show sharing options dialog
  static Future<void> showSharingOptionsDialog({
    required BuildContext context,
    required Bill bill,
    required VoidCallback onShareLink,
    required VoidCallback onShareQR,
    required VoidCallback onExportPDF,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            return AlertDialog(
              title: Text(
                'Share Bill',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.link,
                      size: isMobile ? 24 : 20,
                    ),
                    title: Text(
                      'Share Link',
                      style: TextStyle(fontSize: isMobile ? 16 : 14),
                    ),
                    subtitle: Text(
                      'Share bill via link',
                      style: TextStyle(fontSize: isMobile ? 14 : 12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 12,
                      vertical: isMobile ? 8 : 4,
                    ),
                    minVerticalPadding: isMobile ? 12 : 8,
                    onTap: () {
                      Navigator.of(context).pop();
                      onShareLink();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.qr_code,
                      size: isMobile ? 24 : 20,
                    ),
                    title: Text(
                      'Share QR Code',
                      style: TextStyle(fontSize: isMobile ? 16 : 14),
                    ),
                    subtitle: Text(
                      'Generate QR code for easy access',
                      style: TextStyle(fontSize: isMobile ? 14 : 12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 12,
                      vertical: isMobile ? 8 : 4,
                    ),
                    minVerticalPadding: isMobile ? 12 : 8,
                    onTap: () {
                      Navigator.of(context).pop();
                      onShareQR();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.picture_as_pdf,
                      size: isMobile ? 24 : 20,
                    ),
                    title: Text(
                      'Export PDF',
                      style: TextStyle(fontSize: isMobile ? 16 : 14),
                    ),
                    subtitle: Text(
                      'Export bill as PDF document',
                      style: TextStyle(fontSize: isMobile ? 14 : 12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 12,
                      vertical: isMobile ? 8 : 4,
                    ),
                    minVerticalPadding: isMobile ? 12 : 8,
                    onTap: () {
                      Navigator.of(context).pop();
                      onExportPDF();
                    },
                  ),
                ],
              ),
              contentPadding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 24,
                isMobile ? 16 : 20,
                isMobile ? 12 : 24,
                isMobile ? 8 : 12,
              ),
              actionsPadding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                0,
                isMobile ? 12 : 16,
                isMobile ? 12 : 16,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    minimumSize: Size(isMobile ? 80 : 64, isMobile ? 44 : 36),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 12,
                      vertical: isMobile ? 12 : 8,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: isMobile ? 16 : 14),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Show tips and help dialog
  static Future<void> showTipsDialog({
    required BuildContext context,
  }) async {
    const tips = [
      '💡 Tap on items to assign them to participants',
      '📱 Use the share feature to collaborate with others',
      '💰 Add a tip before completing the bill',
      '✅ Mark payments as completed when received',
      '📊 View bill history to track past expenses',
      '🔍 Use the search feature to find specific bills',
    ];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tips & Tricks'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tips.map((tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(tip),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }
}
