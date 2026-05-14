import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // If the user is already signed in and verified, skip straight to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  Widget _buildTeamMember(String name, String role, String imageAssetPath, double radius) {
    return Column(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[300],
          // Ignore error if image doesn't exist yet, show fallback icon
          child: ClipOval(
            child: Image.asset(
              imageAssetPath,
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.person, size: radius, color: Colors.grey[500]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: radius > 30 ? 16 : 14,
          ),
        ),
        Text(
          role,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: radius > 30 ? 14 : 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Welcome to SoulPing Care!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "We are dedicated to keeping your loved ones safe, connected, and cared for.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const Text(
                  "Meet Our Team",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                // Leader
                _buildTeamMember(
                  "Ahmed",
                  "Project Leader",
                  "assets/images/team/Ahmed.jpeg",
                  50.0, // Bigger photo
                ),
                const SizedBox(height: 24),
                // Other 4 members in two rows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeamMember(
                      "Abdullah",
                      "Developer",
                      "assets/images/team/Abdullah.jpeg",
                      30.0,
                    ),
                    _buildTeamMember(
                      "Moaz",
                      "Designer",
                      "assets/images/team/moazz.jpeg",
                      30.0,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeamMember(
                      "Mai",
                      "QA Engineer",
                      "assets/images/team/mai.jpeg",
                      30.0,
                    ),
                    _buildTeamMember(
                      "Seif",
                      "Product",
                      "assets/images/team/seif.jpeg",
                      30.0,
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      "Let's Start",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
