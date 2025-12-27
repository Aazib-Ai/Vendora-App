import 'package:flutter/material.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/models/demo_data.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Editable fields
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  String selectedPayment = "";

  @override
  void initState() {
    super.initState();
    final order = demoOrders.first;

    nameCtrl.text = order.shippingInfo.name;
    addressCtrl.text = order.shippingInfo.address;
    phoneCtrl.text = order.shippingInfo.phone;
  }

  @override
  Widget build(BuildContext context) {
    final order = demoOrders.first;
    final subtotal = order.subtotal;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        centerTitle: true,
        title: const Text(
          "Checkout",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------
            // SHIPPING INFORMATION
            // ---------------------
            const SizedBox(height: 10),
            const Text(
              "Shipping Information",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            _editableField(nameCtrl),
            const SizedBox(height: 12),
            _editableField(addressCtrl),
            const SizedBox(height: 12),
            _editableField(phoneCtrl),

            const SizedBox(height: 6),

            Center(
              child: InkWell(
                onTap: () {
                  final saved = demoOrders.first.shippingInfo;
                  setState(() {
                    nameCtrl.text = saved.name;
                    addressCtrl.text = saved.address;
                    phoneCtrl.text = saved.phone;
                  });
                },
                child: Text(
                  "Use Saved Address",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ---------------------
            // PAYMENT SECTION
            // ---------------------
            const Text(
              "Payment Info",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            _paymentOption(
              title: "Debit / Credit Card",
              iconPath: "assets/images/visa.png",
              onTap: () => _openCardModal(),
            ),
            const SizedBox(height: 12),

            _paymentOption(
              title: "JazzCash",
              iconPath: "assets/images/jazzcash.png",
              onTap: () => _openJazzCashModal(),
            ),
            const SizedBox(height: 12),

            _paymentOption(
              title: "Cash on Delivery",
              iconPath: "assets/images/cod.png",
              onTap: () {
                setState(() => selectedPayment = "Cash on Delivery");
              },
            ),

            const SizedBox(height: 30),

            // ---------------------
            // ORDER SUMMARY
            // ---------------------
            const Text(
              "Order Summary",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          Text("Qty (${item.quantity})",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]))
                        ]),
                    Text("Rs ${item.total.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),

            const Divider(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sub Total",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text("Rs ${subtotal.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),

            const SizedBox(height: 30),

            // ---------------------
            // PAY BUTTON
            // ---------------------
            GestureDetector(
              onTap: () {
                if (selectedPayment.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Select a payment method")));
                  return;
                }
                Navigator.pushNamed(context, AppRoutes.orderComplete);
              },
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Center(
                  child: Text(
                    "Pay",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // EDITABLE FIELD UI
  Widget _editableField(TextEditingController c) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none),
      ),
    );
  }

  // PAYMENT OPTION CARD
  Widget _paymentOption({
    required String title,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedPayment == title;

    return InkWell(
      onTap: () {
        setState(() => selectedPayment = title);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 40, height: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // MODAL — CARD PAYMENT
  // -------------------------
  void _openCardModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("Card Payment",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextField(decoration: _modalInput("Name on Card")),
              const SizedBox(height: 12),

              TextField(
                  keyboardType: TextInputType.number,
                  decoration: _modalInput("Card Number")),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                    child: TextField(
                        decoration: _modalInput("Expiry (MM/YY)"))),
                const SizedBox(width: 12),
                Expanded(
                    child: TextField(
                        decoration: _modalInput("CVV"))),
              ]),

              const SizedBox(height: 20),

              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30)),
                  child: const Center(
                      child: Text("Save & Continue",
                          style: TextStyle(color: Colors.white))),
                ),
              )
            ]),
          ),
        );
      },
    );
  }

  // -------------------------
  // MODAL — JAZZCASH PAYMENT
  // -------------------------
  void _openJazzCashModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("JazzCash Payment",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextField(decoration: _modalInput("Full Name")),
              const SizedBox(height: 12),

              TextField(
                  keyboardType: TextInputType.number,
                  decoration:
                  _modalInput("JazzCash Account Number")),
              const SizedBox(height: 12),

              ElevatedButton(
                  onPressed: () {}, child: const Text("Upload Payment Proof")),

              const SizedBox(height: 20),

              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30)),
                  child: const Center(
                      child: Text("Save & Continue",
                          style: TextStyle(color: Colors.white))),
                ),
              )
            ]),
          ),
        );
      },
    );
  }

  // DECORATION FOR MODAL FIELDS
  InputDecoration _modalInput(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade200,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
