import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/chalan-details/channal_bloc.dart';
import 'package:marketing/services/challan_details.dart';
import 'package:marketing/services/models/chalan_details.dart';

class ChallanDetailsPage extends StatelessWidget {
  final int partyId;
  final int compId;
  final int challanId;
  final String token;

  const ChallanDetailsPage({
    super.key,
    required this.partyId,
    required this.compId,
    required this.challanId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challan Details'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: BlocProvider(
        create: (context) =>
            ChallanBlocDetails(challanService: ChallanService())..add(
              FetchChallanDetails(
                partyId: partyId,
                compId: compId,
                challanId: challanId,
                token: token,
              ),
            ),
        child: const ChallanDetailsView(),
      ),
    );
  }
}

class ChallanDetailsView extends StatelessWidget {
  const ChallanDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChallanBlocDetails, ChallanState>(
      builder: (context, state) {
        if (state is ChallanLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ChallanLoaded) {
          return _buildChallanDetails(context, state.challanDetail);
        } else if (state is ChallanError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error: ${state.message}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('No data available'));
      },
    );
  }

  Widget _buildChallanDetails(BuildContext context, ChallanDetail detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade900, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Challan Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          detail.challanType,
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Challan No', '#${detail.challanNo}'),
                  _buildInfoRow(
                    'Challan Date',
                    _formatDate(detail.challanDate),
                  ),
                  _buildInfoRow(
                    'Order No',
                    detail.orderNo.isEmpty ? 'N/A' : detail.orderNo,
                  ),
                  _buildInfoRow(
                    'Bill To',
                    detail.billTo.isEmpty ? 'N/A' : detail.billTo,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Delivery Information Card
          if (detail.deliveryLocation != null ||
              detail.driverName != null ||
              detail.transportName != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (detail.deliveryLocation != null)
                      _buildInfoRow(
                        'Location',
                        detail.deliveryLocation.toString(),
                      ),
                    if (detail.driverName != null)
                      _buildInfoRow(
                        'Driver Name',
                        detail.driverName.toString(),
                      ),
                    if (detail.driverContactNo != null)
                      _buildInfoRow(
                        'Driver Contact',
                        detail.driverContactNo.toString(),
                      ),
                    if (detail.transportName != null)
                      _buildInfoRow(
                        'Transport',
                        detail.transportName.toString(),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Products Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detail.details.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final product = detail.details[index];
                      return _buildProductCard(product);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductDetail product) {
    final totalPrice = (product.unitPrice * product.unitQty).abs();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.unitQty < 0
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: product.unitQty < 0
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Text(
                  'Qty: ${product.unitQty.abs()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: product.unitQty < 0
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rate: £${product.unitPrice}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Total: £$totalPrice',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          if (product.returnQty > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Return Qty: ${product.returnQty}',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return 'N/A';
    if (date.length == 8) {
      return '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)}';
    }
    return date;
  }
}
