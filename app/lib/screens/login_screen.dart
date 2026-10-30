import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  

Future<void> navigateByRole(User user) async {
  try {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final profile = await userRef.get();

    if (!mounted) return;

    if (!profile.exists) {
      // Create a profile for an older account.
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('PROFILE: created for existing account');
    }

    final updatedProfile = await userRef.get();
    final role = updatedProfile.data()?['role'];

    if (!mounted) return;

    if (role == 'user' || role == 'organization') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );

      print('LOGIN: role = $role');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid account role. Please contact support.'),
        ),
      );
    }
  } catch (e) {
    print('PROFILE ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not load your profile. Check your connection and try again.',
        ),
      ),
    );
  }
}


  
Future<String?> chooseAccountRole() async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Choose your account type'),
      content: const Text(
        'How would you like to use TagIT?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext, 'user');
          },
          child: const Text('Community User'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext, 'organization');
          },
          child: const Text('Organization'),
        ),
      ],
    ),
  );
}


  Future<void> signInWithGoogle() async {
    try {
      print("GOOGLE: authentication started");

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      print("GOOGLE: account selected");

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      print("GOOGLE: got authentication");

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      print("GOOGLE: Firebase credential created");

      await FirebaseAuth.instance.signInWithCredential(credential);

      print("GOOGLE: Firebase sign-in successful");
    } on GoogleSignInException catch (e) {
      print("GOOGLE SIGN-IN ERROR:");
      print("Code: ${e.code}");
      print("Description: ${e.description}");
    } catch (e) {
      print("GENERAL SIGN-IN ERROR: $e");
    }
  }

  Future<void> signInWithEmail() async {
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("EMAIL: sign-in successful");

   await navigateByRole(
  FirebaseAuth.instance.currentUser!,
);
    } on FirebaseAuthException catch (e) {
      print("EMAIL SIGN-IN ERROR:");
      print("Code: ${e.code}");
      print("Message: ${e.message}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Sign-in failed."),
          ),
        );
      }
    }
  }


Future<void> createAccount() async {
  try {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email and password.'),
        ),
      );
      return;
    }

    final role = await chooseAccountRole();

    if (role == null || !mounted) return;

    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'email': user.email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('ACCOUNT: created with role $role');

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  } on FirebaseAuthException catch (e) {
    print('ACCOUNT CREATION ERROR: ${e.code}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Account creation failed.'),
        ),
      );
    }
  } catch (e) {
    print('PROFILE CREATION ERROR: $e');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account was created, but profile setup failed. '
            'Please contact support before creating another account.',
          ),
        ),
      );
    }
  }
}


  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo / Branding
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Center(
                child: Text(
                  "Tag IT",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  "Report waste. Improve your community.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              const Text(
                "Welcome back",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Sign in to continue to Tag IT",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: signInWithEmail,
                  child: const Text(
                    "Sign In",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: createAccount,
                  child: const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  const Expanded(
                    child: Divider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: Text(
                      "OR",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Google Sign-In will be available soon.",
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Center(
                child: Text(
                  "Together, we can keep our communities cleaner.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}