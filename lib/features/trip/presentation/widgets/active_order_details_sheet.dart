import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/app_theme.dart';
import '../../../orders/domain/models/order_mock.dart';

class ActiveOrderDetailsSheet extends StatelessWidget {
  final OrderMock order;

  const ActiveOrderDetailsSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isPickup = order.type == OrderTypeMock.pickup;
    final showCashAmount = order.isCash == true;
    final scheduledDateTime = order.createdOn ?? order.scheduledAt;
    final currencyFormatter = intl.NumberFormat.currency(
      locale: 'en',
      symbol: 'SAR ',
      decimalDigits: order.totalPrice % 1 == 0 ? 0 : 2,
    );
    final scheduledDateFormatter = intl.DateFormat('yyyy-MM-dd');
    final scheduledTimeFormatter = intl.DateFormat('hh:mm a');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'orderDetails'.tr,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                    fontSize: 18.sp,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: isPickup
                      ? Colors.amber.shade100
                      : AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  isPickup ? 'Pickup' : 'Delivery',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isPickup
                        ? Colors.amber.shade900
                        : AppTheme.primaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                _buildInfoBit(
                  'orderNumberLabel'.trParams({
                    'number': order.orderNumber ?? order.id,
                  }),
                  '#${order.orderNumber ?? order.id}',
                  theme,
                ),
                const Spacer(),
                _buildInfoBit(
                  'Scheduled',
                  '${scheduledDateFormatter.format(scheduledDateTime)} ${scheduledTimeFormatter.format(scheduledDateTime)}',
                  theme,
                  alignCenter: true,
                ),
              ],
            ),
          ),
          if (!isPickup) ...[
            SizedBox(height: 24.h),
            Text(
              'Service Name',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 8.h),
            _buildDescriptionRow(order.laundryTypeName?.trim() ?? '', theme),
            SizedBox(height: 16.h),
            Text(
              'Order Items',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 12.h),
            if (order.orderItems != null && order.orderItems!.isNotEmpty)
              ...order.orderItems!
                  .map((item) => _buildItemRow(item, isRtl, theme))
            else
              _buildEmptyValueSpace(),
            SizedBox(height: 16.h),
            Text(
              'Item Description',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 8.h),
            _buildDescriptionRow(order.itemDescription?.trim() ?? '', theme),
          ],
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
              Text(
                (order.isCash ?? true) ? 'Cash on Delivery' : 'Paid Online',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: (order.isCash ?? true) ? Colors.orange : Colors.green,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          if (showCashAmount) ...[
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Price',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  currencyFormatter.format(order.totalPrice),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'close'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildInfoBit(
    String label,
    String value,
    ThemeData theme, {
    bool alignEnd = false,
    bool alignCenter = false,
  }) {
    final crossAxisAlignment = alignCenter
        ? CrossAxisAlignment.center
        : alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start;
    final textAlign = alignCenter
        ? TextAlign.center
        : alignEnd
            ? TextAlign.end
            : TextAlign.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            textAlign: textAlign,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 12.sp,
            ),
          ),
        if (label.isNotEmpty) SizedBox(height: 4.h),
        Text(
          value,
          textAlign: textAlign,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(OrderItemMock item, bool isRtl, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'x${item.quantity}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              isRtl ? item.nameAr : item.nameEn,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionRow(String description, ThemeData theme) {
    final hasValue = description.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'i',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: hasValue
                ? Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  )
                : SizedBox(
                    height: 20.h,
                    child: const Text(''),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyValueSpace() {
    return SizedBox(
      height: 24.h,
      width: double.infinity,
    );
  }
}
