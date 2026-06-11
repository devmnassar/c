import 'package:flutter/material.dart';

import '../../domain/models/order_mock.dart';

void showOrderHistoryBottomSheet(BuildContext context, OrderMock order) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green[600],
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _DetailRow(
              label: 'Order Number',
              value: '#${order.orderNumber ?? order.id}'),
          _DetailRow(label: 'Customer Name', value: order.customerName),
          _DetailRow(
            label: 'Payment',
            value: order.isCash == true ? 'Cash' : 'Paid Online',
          ),
          _DetailRow(
            label: 'Customer Phone',
            value: order.customerPhone,
          ),
          _DetailRow(
            label: 'Order Type',
            value: _orderTypeLabel(order),
          ),
          _DetailRow(
            label: 'Item Description',
            value: order.itemDescription?.trim() ?? '',
          ),
          _DetailRow(
            label: 'Service Name',
            value: order.laundryTypeName?.trim() ?? '',
          ),
          _DetailRow(
            label: 'Sub Services',
            value: _subServicesValue(order),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: const Color(0xFF1F2937),
                elevation: 0,
              ),
              child: const Text(
                'Close Archive',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String _orderTypeLabel(OrderMock order) {
  return order.type == OrderTypeMock.delivery ? 'Delivery' : 'Pickup';
}

String _subServicesValue(OrderMock order) {
  final orderItems = order.orderItems;
  if (orderItems == null || orderItems.isEmpty) {
    return '';
  }

  return orderItems
      .map((item) => '${item.quantity}x ${item.nameEn}')
      .join(', ');
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
