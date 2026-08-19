import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

class SuspendedAccountScreen extends StatelessWidget {
  const SuspendedAccountScreen({super.key});

  void _contactSuperAdmin() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'visibloai@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Account Suspended Inquiry',
        'body': 'Hello Super Admin,\n\nI am writing to inquire about the suspension of my account.\n\nThank you.',
      }),
    );
    
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  void _backToLogin() {
    Get.offAllNamed('/login'); // Assuming GetX is used for routing
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/visiblo_logo.png', // Replace with exact logo path if different
              height: 28,
              errorBuilder: (context, error, stackTrace) => const Text('VisibloAI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            onPressed: () {
              // Help action
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              
              // Shield Banner Image
              Center(
                child: Image.asset(
                  'assets/images/app-banner9.png',
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.security, size: 100, color: Colors.blueGrey),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Title
              const Text(
                'Access Disabled',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Cyan Underline
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Description
              const Text(
                'Your account access has been disabled\nby the Super Admin due to some reason.\nPlease contact the Super Admin to know more.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Email Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mail_outline,
                        color: Color(0xFF0284C7),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Super Admin Email',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'visibloai@gmail.com',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Contact Super Admin Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _contactSuperAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1E42),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.mail_outline, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Contact Super Admin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.chevron_right, size: 24),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Back to Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _backToLogin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Back to Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      SizedBox(width: 24), // Balance spacing
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bottom Info Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF06B6D4),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This restriction can only be reviewed\nby the Super Admin.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
