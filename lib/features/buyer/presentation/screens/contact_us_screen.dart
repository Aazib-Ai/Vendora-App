import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  String? selectedFileName;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Contact Us',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
              child: ConstrainedBox(
                constraints:
                BoxConstraints(minHeight: constraints.maxHeight - 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    const Center(
                      child: Text(
                        "We’d love to hear from you! Whether it’s feedback,\n"
                            "questions, or support — reach out anytime",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    _PillTextField(hint: "Full Name", keyboardType: TextInputType.name),
                    const SizedBox(height: 14),

                    _PillTextField(
                        hint: "Email address",
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),

                    _PillTextField(hint: "Message", maxLines: 3),
                    const SizedBox(height: 14),

                    // --------------------------
                    //   ATTACHMENT PICKER FIELD
                    // --------------------------
                    GestureDetector(
                      onTap: pickFile,
                      child: AbsorbPointer(
                        child: _PillTextField(
                          hint: selectedFileName ?? "Attachment (if any)",
                          readOnly: true,
                          suffixIcon: Icons.attach_file,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // SEND BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Message sent successfully")),
                          );
                        },
                        child: const Text(
                          "Send",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Center(
                      child: Text(
                        "Our Social Appearance",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // SOCIAL ICONS ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _SocialIcon(icon: Icons.facebook),
                        SizedBox(width: 16),
                        _SocialIcon(icon: Icons.camera_alt), // Instagram style
                        SizedBox(width: 16),
                        _SocialIcon(icon: Icons.business), // LinkedIn style
                        SizedBox(width: 16),
                        _SocialIcon(icon: Icons.code), // GitHub
                        SizedBox(width: 16),
                        _SocialIcon(icon: Icons.close), // Twitter/X (custom icon later)
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PillTextField extends StatelessWidget {
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final IconData? suffixIcon;

  const _PillTextField({
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade300,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: const BorderSide(color: Colors.black, width: 1.2),
        ),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.grey.shade700, size: 20)
            : null,
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  const _SocialIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: Colors.black),
    );
  }
}
