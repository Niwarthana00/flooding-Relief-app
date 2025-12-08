import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sahana/features/auth/screens/beneficiary_registration_screen.dart';
import 'package:sahana/features/auth/screens/role_selection_screen.dart';
import 'package:sahana/features/dashboard/screens/beneficiary_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              // Show loading while fetching user profile
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // If user profile exists, go to Dashboard
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                return const BeneficiaryDashboard();
              }

              // If user is logged in but has no profile, go to Registration
              return const BeneficiaryRegistrationScreen();
            },
          );
        }

        // If user is not logged in, show Role Selection
        return const RoleSelectionScreen();
      },
    );
  }
}
