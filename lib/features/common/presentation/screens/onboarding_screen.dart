import 'package:flutter/material.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/core/widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      subtitle: "Buy or Sell in Seconds",
      description:
      "Whether you’re a shopper or a seller, Vendora makes transactions simple, secure, and fast.",
      imagePath: "assets/images/onboard1.png",
    ),
    _OnboardingPageData(
      subtitle: "Welcome to Vendora",
      description:
      "Discover, sell, and shop from trusted local vendors — all in one app.",
      imagePath: "assets/images/onboard2.png",
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // ✅ Final step → Login Screen
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _pages[_currentPage];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),

            // LOGO (slightly left shifted)
            Transform.translate(
              offset: const Offset(-4, 0),
              child: Image.asset(
                "assets/images/vendora_logo.png",
                width: 130,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              current.subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Image.asset(
                          data.imagePath,
                          height: 240,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 35),
                        Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // INDICATOR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 28 : 10,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.black
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 35),

            // BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CustomButton(
                text: _currentPage == _pages.length - 1
                    ? "Get Started"
                    : "Next",
                onPressed: _onNext,
              ),
            ),

            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String subtitle;
  final String description;
  final String imagePath;

  _OnboardingPageData({
    required this.subtitle,
    required this.description,
    required this.imagePath,
  });
}
