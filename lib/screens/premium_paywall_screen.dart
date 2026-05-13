import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';
import 'dart:ui';

class PremiumPaywallScreen extends StatelessWidget {
  const PremiumPaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.textMain, // AppTheme.textMain serves as a dark bg
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pinkAccent.withValues(alpha: 0.2),
              ),
            ),
          ),
          
          // Glassmorphism Content
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    const Icon(Icons.security_rounded, size: 80, color: AppTheme.primary),
                    const SizedBox(height: 24),
                    
                    Text(
                      "Keep Your Loved Ones Safe",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Upgrade to Premium for absolute peace of mind with intelligent automation.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Features List
                    Expanded(
                      child: ListView(
                        children: const [
                          _FeatureRow(
                            icon: Icons.notifications_active_rounded,
                            title: "Smart Missed Check-in Alerts",
                            description: "Instant push notifications if an elder misses their daily check-in.",
                          ),
                          _FeatureRow(
                            icon: Icons.group_rounded,
                            title: "Up to 5 Trusted Contacts",
                            description: "Keep the whole family in the loop. Free plan allows up to 3.",
                          ),
                          _FeatureRow(
                            icon: Icons.route_rounded,
                            title: "Intelligent Escalation",
                            description: "If the first contact doesn't respond, we try the next. A true emergency system.",
                          ),
                          _FeatureRow(
                            icon: Icons.analytics_rounded,
                            title: "Safety Insights",
                            description: "Review weekly check-in trends easily.",
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pricing & Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text("\$2.99", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text("/month", style: TextStyle(fontSize: 16, color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Consumer<AppAuthProvider>(
                            builder: (context, auth, _) {
                              final isPremium = auth.userModel?.isPremium ?? false;
                              if (isPremium) {
                                return const CustomButton(
                                  text: 'You are subscribed!',
                                  onPressed: null,
                                );
                              }
                              return CustomButton(
                                text: 'Upgrade Now',
                                isLoading: auth.isLoading,
                                onPressed: () {
                                  if (kDebugMode) {
                                    // Dev-only bypass: activates premium without payment
                                    auth.upgradeToPremium().then((_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('[DEBUG] Premium activated!')),
                                        );
                                        Navigator.pop(context);
                                      }
                                    }).catchError((e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    });
                                  } else {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => const _ComingSoonSheet(),
                                    );
                                  }
                                },
                              );
                            }
                          ),
                          const SizedBox(height: 12),
                          Text("Cancel anytime. No commitment.", style: TextStyle(fontSize: 12, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonSheet extends StatelessWidget {
  const _ComingSoonSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: AppTheme.primary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Coming Soon',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Secure payment integration is in progress.\nYou will be able to subscribe very soon!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Got it', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
