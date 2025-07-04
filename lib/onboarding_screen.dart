import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _titles = [
    'Welcome to PassMate',
    'Secure Storage',
    'Sync with Drive',
  ];

  final List<String> _subtitles = [
    'Manage your passwords easily and securely.',
    'Everything is stored using encrypted local storage.',
    'Optionally backup your data to Google Drive.',
  ];

  void _finishOnboarding() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _titles.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_titles[index], style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        SizedBox(height: 20),
                        Text(_subtitles[index], textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text("Skip"),
                  ),
                  Row(
                    children: List.generate(
                      _titles.length,
                          (index) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_currentPage == _titles.length - 1) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(_currentPage == _titles.length - 1 ? "Done" : "Next"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}