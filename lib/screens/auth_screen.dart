import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';



import 'chat_screen.dart';



class AuthScreen extends StatefulWidget {

  const AuthScreen({super.key});



  @override

  State<AuthScreen> createState() => _AuthScreenState();

}



class _AuthScreenState extends State<AuthScreen> {

  final _auth = FirebaseAuth.instance;

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final _nicknameController = TextEditingController();

  final _nameController = TextEditingController();

  final _ageController = TextEditingController();



  bool _isLogin = true;

  bool _isLoading = false;

  bool _obscurePassword = true;

  String _selectedGender = 'Мужской';



  @override

  void initState() {

    super.initState();

    _checkCurrentUser();

  }



  Future<void> _checkCurrentUser() async {

    final user = _auth.currentUser;

    if (user != null) {

      setState(() => _isLoading = true);

      try {

        final userDoc = await FirebaseFirestore.instance

            .collection('users')

            .doc(user.uid)

            .get();



        String nickname = 'Боец';

        if (userDoc.exists) {

          nickname = userDoc.data()?['nickname'] ?? 'Боец';

        }



        if (mounted) {

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (context) => ChatScreen(nickname: nickname),

            ),

          );

        }

      } catch (e) {

        if (mounted) {

          setState(() => _isLoading = false);

        }

      }

    }

  }



  @override

  void dispose() {

    _emailController.dispose();

    _passwordController.dispose();

    _nicknameController.dispose();

    _nameController.dispose();

    _ageController.dispose();

    super.dispose();

  }



  bool _isEmailValid(String email) {

    return email.contains('@') && email.contains('.');

  }



  Future<void> _submitAuth() async {

    final email = _emailController.text.trim();

    final password = _passwordController.text.trim();



    if (email.isEmpty || password.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Заполните Email и пароль!')),

      );

      return;

    }



    if (!_isEmailValid(email)) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Некорректный email')),

      );

      return;

    }



    if (password.length < 6) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Пароль должен быть не менее 6 символов!')),

      );

      return;

    }



    setState(() => _isLoading = true);



    if (_isLogin) {

      try {

        final credential = await _auth.signInWithEmailAndPassword(

          email: email,

          password: password,

        );



        final userDoc = await FirebaseFirestore.instance

            .collection('users')

            .doc(credential.user!.uid)

            .get();



        String nickname = 'Боец';

        if (userDoc.exists) {

          nickname = userDoc.data()?['nickname'] ?? 'Боец';

        }



        if (mounted) {

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (context) => ChatScreen(nickname: nickname),

            ),

          );

        }

      } on FirebaseAuthException catch (e) {

        if (mounted) {

          if (e.code == 'user-not-found' ||

              e.code == 'wrong-password' ||

              e.code == 'invalid-credential' ||

              e.code == 'invalid-email') {

            ScaffoldMessenger.of(context).showSnackBar(

              const SnackBar(

                content: Text('Проверьте правильность ввода Email или пароля'),

                backgroundColor: Colors.redAccent,

              ),

            );

          } else {

            ScaffoldMessenger.of(context).showSnackBar(

              SnackBar(content: Text(e.message ?? 'Ошибка авторизации')),

            );

          }

        }

      } finally {

        if (mounted) setState(() => _isLoading = false);

      }

    } else {

      final nickname = _nicknameController.text.trim();

      final name = _nameController.text.trim();

      final age = _ageController.text.trim();



      if (nickname.isEmpty || name.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Укажите ваше имя и никнейм!')),

        );

        setState(() => _isLoading = false);

        return;

      }



      try {

        final nickQuery = await FirebaseFirestore.instance

            .collection('users')

            .where('nickname', isEqualTo: nickname)

            .get();



        if (nickQuery.docs.isNotEmpty) {

          if (mounted) {

            ScaffoldMessenger.of(context).showSnackBar(

              const SnackBar(content: Text('Такой никнейм уже занят!')),

            );

          }

          setState(() => _isLoading = false);

          return;

        }



        final credential = await _auth.createUserWithEmailAndPassword(

          email: email,

          password: password,

        );



        final uid = credential.user!.uid;



        await FirebaseFirestore.instance.collection('users').doc(uid).set({

          'nickname': nickname,

          'name': name,

          'age': age.isNotEmpty ? age : 'Не указан',

          'gender': _selectedGender,

          'email': email,

          'avatarUrl': '',

          'prefix': '',

          'isOnline': true,

          'createdAt': FieldValue.serverTimestamp(),

          'welcomed': false,

          'blockedUsers': [],

        });



        await credential.user?.sendEmailVerification();



        if (mounted) {

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (context) => ChatScreen(nickname: nickname),

            ),

          );

        }

      } on FirebaseAuthException catch (e) {

        if (mounted) {

          if (e.code == 'email-already-in-use') {

            ScaffoldMessenger.of(context).showSnackBar(

              const SnackBar(content: Text('Этот Email уже зарегистрирован!')),

            );

          } else {

            ScaffoldMessenger.of(context).showSnackBar(

              SnackBar(content: Text(e.message ?? 'Ошибка регистрации')),

            );

          }

        }

      } finally {

        if (mounted) setState(() => _isLoading = false);

      }

    }

  }



  void _showForgotPasswordDialog() {

    final resetEmailController = TextEditingController(text: _emailController.text.trim());



    showDialog(

      context: context,

      builder: (ctx) => AlertDialog(

        title: const Text('Сброс пароля'),

        content: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            const Text(

              'Введите ваш Email, и мы отправим ссылку для восстановления пароля.',

              style: TextStyle(fontSize: 13, color: Colors.grey),

            ),

            const SizedBox(height: 15),

            TextField(

              controller: resetEmailController,

              keyboardType: TextInputType.emailAddress,

              decoration: const InputDecoration(

                labelText: 'Email',

                border: OutlineInputBorder(),

              ),

            ),

          ],

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(ctx),

            child: const Text('Отмена'),

          ),

          ElevatedButton(

            onPressed: () async {

              final resetEmail = resetEmailController.text.trim();

              if (resetEmail.isEmpty || !resetEmail.contains('@')) {

                ScaffoldMessenger.of(context).showSnackBar(

                  const SnackBar(content: Text('Некорректный email')),

                );

                return;

              }



              try {

                await _auth.sendPasswordResetEmail(email: resetEmail);

                if (ctx.mounted) {

                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(

                    const SnackBar(content: Text('Ссылка отправлена! Проверьте почту и папку СПАМ.')),

                  );

                }

              } catch (e) {

                if (ctx.mounted) {

                  ScaffoldMessenger.of(context).showSnackBar(

                    SnackBar(content: Text('Ошибка: $e')),

                  );

                }

              }

            },

            child: const Text('Отправить'),

          ),

        ],

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);



    return Scaffold(

      body: Center(

        child: SingleChildScrollView(

          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),

          child: ConstrainedBox(

            constraints: const BoxConstraints(maxWidth: 420),

            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                Icon(

                  Icons.shield,

                  size: 70,

                  color: theme.colorScheme.primary,

                ),

                const SizedBox(height: 12),

                Text(

                  _isLogin ? 'Вход в [vPv]' : 'Регистрация в [vPv]',

                  textAlign: TextAlign.center,

                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),

                ),

                const SizedBox(height: 6),

                const Text(

                  'Альянс «Волчий Протокол»',

                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 14, color: Colors.grey),

                ),

                const SizedBox(height: 30),



                TextField(

                  controller: _emailController,

                  keyboardType: TextInputType.emailAddress,

                  decoration: const InputDecoration(

                    labelText: 'Email',

                    prefixIcon: Icon(Icons.email_outlined),

                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),

                  ),

                ),

                const SizedBox(height: 15),



                TextField(

                  controller: _passwordController,

                  obscureText: _obscurePassword,

                  decoration: InputDecoration(

                    labelText: 'Пароль',

                    prefixIcon: const Icon(Icons.lock_outline),

                    suffixIcon: IconButton(

                      icon: Icon(

                        _obscurePassword ? Icons.visibility_off : Icons.visibility,

                        color: Colors.grey,

                      ),

                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),

                    ),

                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),

                  ),

                ),



                if (!_isLogin) ...[

                  const SizedBox(height: 15),

                  TextField(

                    controller: _nicknameController,

                    decoration: const InputDecoration(

                      labelText: 'Никнейм в игре',

                      prefixIcon: Icon(Icons.alternate_email),

                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),

                    ),

                  ),

                  const SizedBox(height: 15),

                  TextField(

                    controller: _nameController,

                    decoration: const InputDecoration(

                      labelText: 'Реальное имя',

                      prefixIcon: Icon(Icons.badge_outlined),

                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),

                    ),

                  ),

                  const SizedBox(height: 15),

                  TextField(

                    controller: _ageController,

                    keyboardType: TextInputType.number,

                    decoration: const InputDecoration(

                      labelText: 'Возраст',

                      prefixIcon: Icon(Icons.cake_outlined),

                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),

                    ),

                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(

                    value: _selectedGender,

                    decoration: const InputDecoration(

                      labelText: 'Пол',

                      prefixIcon: Icon(Icons.people_outline),

                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),

                    ),

                    items: const [

                      DropdownMenuItem(value: 'Мужской', child: Text('Мужской')),

                      DropdownMenuItem(value: 'Женский', child: Text('Женский')),

                    ],

                    onChanged: (val) {

                      if (val != null) setState(() => _selectedGender = val);

                    },

                  ),

                ],



                if (_isLogin) ...[

                  Align(

                    alignment: Alignment.centerRight,

                    child: TextButton(

                      onPressed: _showForgotPasswordDialog,

                      child: const Text('Забыли пароль?'),

                    ),

                  ),

                ] else

                  const SizedBox(height: 20),



                SizedBox(

                  height: 50,

                  child: ElevatedButton(

                    style: ElevatedButton.styleFrom(

                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                    ),

                    onPressed: _isLoading ? null : _submitAuth,

                    child: _isLoading

                        ? const SizedBox(

                      width: 22,

                      height: 22,

                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),

                    )

                        : Text(

                      _isLogin ? 'Войти' : 'Зарегистрироваться',

                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),

                    ),

                  ),

                ),

                const SizedBox(height: 12),



                TextButton(

                  onPressed: () {

                    setState(() {

                      _isLogin = !_isLogin;

                    });

                  },

                  child: Text(

                    _isLogin ? 'Нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти',

                  ),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}



