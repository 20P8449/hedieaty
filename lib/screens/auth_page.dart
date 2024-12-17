// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
// class AuthPage extends StatefulWidget {
//   @override
//   _AuthPageState createState() => _AuthPageState();
// }
//
// class _AuthPageState extends State<AuthPage> {
//   final AuthService _authService = AuthService();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _rePasswordController = TextEditingController();
//
//   bool _isLogin = true;
//
//   void _toggleForm() {
//     setState(() {
//       _isLogin = !_isLogin;
//       _passwordController.clear();
//       _rePasswordController.clear(); // Clear re-enter password field
//     });
//   }
//
//   void _submit() async {
//     String email = _emailController.text.trim();
//     String password = _passwordController.text.trim();
//     String rePassword = _rePasswordController.text.trim();
//
//     if (_isLogin) {
//       // Login Logic
//       var user = await _authService.login(email, password);
//       if (user != null) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Successful')));
//         Navigator.pushReplacementNamed(context, '/home');
//
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Failed')));
//       }
//     } else {
//       // Signup Logic with Password Confirmation
//       if (password != rePassword) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passwords do not match')));
//         return;
//       }
//
//       var user = await _authService.signUp(email, password);
//       if (user != null) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup Successful and User Added')));
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup Failed')));
//       }
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Signup')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: InputDecoration(labelText: 'Email'),
//             ),
//             TextField(
//               controller: _passwordController,
//               decoration: InputDecoration(labelText: 'Password'),
//               obscureText: true,
//             ),
//             if (!_isLogin)
//               TextField(
//                 controller: _rePasswordController,
//                 decoration: InputDecoration(labelText: 'Re-enter Password'),
//                 obscureText: true,
//               ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _submit,
//               child: Text(_isLogin ? 'Login' : 'Signup'),
//             ),
//             TextButton(
//               onPressed: _toggleForm,
//               child: Text(_isLogin ? 'Switch to Signup' : 'Switch to Login'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }