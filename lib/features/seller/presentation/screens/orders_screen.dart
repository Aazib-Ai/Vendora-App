import 'package:flutter/material.dart';
import 'package:vendora/models/order_model.dart';

class SellerOrdersScreen extends StatefulWidget {
  final List<Order> orders;

  const SellerOrdersScreen({super.key, required this.orders});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  String searchQuery = "";
  String filter = "all"; // all, delivered, pending

  @override
  Widget build(BuildContext context) {
    final filteredOrders = widget.orders.where((order) {
      final buyerName = order.shippingInfo.name.toLowerCase();
      final matchesSearch = buyerName.contains(searchQuery.toLowerCase());

      final matchesFilter = filter == "all"
          ? true
          : filter == "delivered"
          ? order.status == "completed"
          : order.status == "pending";

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Orders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // SEARCH BAR (Styled with black border)
            TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search Sellers...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // FILTER PILLS
            Row(
              children: [
                _filterPill("All", "all"),
                const SizedBox(width: 10),
                _filterPill("Delivered", "delivered"),
                const SizedBox(width: 10),
                _filterPill("Pending", "pending"),
              ],
            ),

            const SizedBox(height: 25),

            // TABLE HEADER
            _tableHeader(),

            const SizedBox(height: 12),

            // ORDER ROWS
            Expanded(
              child: ListView.builder(
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  return _orderRow(filteredOrders[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ORDER DETAILS MODAL ----------------
  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      "Order Details",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text("ID: ${order.id}", style: TextStyle(color: Colors.grey)),
                    const Divider(height: 40),

                    const Text("SHIPPING INFO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    Text(order.shippingInfo.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(order.shippingInfo.phone),
                    Text(order.shippingInfo.address, style: const TextStyle(color: Colors.black54)),

                    const Divider(height: 40),
                    const Text("ORDER ITEMS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text("${item.quantity}x ${item.productName}")),
                          Text("Rs ${item.price.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )).toList(),

                    const Divider(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Bill", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("Rs ${order.total.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- FILTER PILL ----------------
  Widget _filterPill(String label, String value) {
    final isActive = filter == value;

    return GestureDetector(
      onTap: () => setState(() => filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ---------------- TABLE HEADER ----------------
  Widget _tableHeader() {
    return Row(
      children: [
        _headerCell("Order Id", 3),
        _headerCell("Buyer", 4),
        _headerCell("Items", 5),
        _headerCell("Total", 3),
        _headerCell("Status", 3),
        _headerCell("Pay", 3),
      ],
    );
  }

  Widget _headerCell(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  // ---------------- ORDER ROW ----------------
  Widget _orderRow(Order order) {
    return InkWell(
      onTap: () => _showOrderDetails(order),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _rowCell(order.id, 3),
            _rowCell(order.shippingInfo.name, 4),
            _rowCell(order.items.first.productName, 5),
            _rowCell("Rs ${order.total.toStringAsFixed(0)}", 3),
            _statusToggle(order, 3),
            _paymentBadge(order.paymentInfo.method.toUpperCase(), 3),
          ],
        ),
      ),
    );
  }

  Widget _rowCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: Colors.black54),
      ),
    );
  }

  // ---------------- STATUS TOGGLE ----------------
  Widget _statusToggle(Order order, int flex) {
    final bool isPending = order.status == "pending";

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () {
          setState(() {
            int index = widget.orders.indexOf(order);
            if (index != -1) {
              widget.orders[index] = order.copyWith(
                status: isPending ? "completed" : "pending",
              );
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isPending ? Colors.orange.shade400 : Colors.green.shade400,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isPending ? "Pending" : "Delivered",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ---------------- PAYMENT BADGE ----------------
  Widget _paymentBadge(String method, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          method,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}