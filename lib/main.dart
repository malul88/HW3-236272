import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:hello_me/userProfile.dart';
import 'package:provider/provider.dart';
import 'package:hello_me/settingNotifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingNotifier(),
      child: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
                body: Center(
                    child: Text(snapshot.error.toString(),
                        textDirection: TextDirection.ltr)));
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return const MyApp();
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        // MODIFY with const
        appBarTheme: const AppBarTheme(
          color: Colors.deepPurple,
        ),
      ),
      home: const RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool isLoginDisabled = false;
  bool isSignupDisabled = false;
  bool isLogedIn = false;
  final _biggerFont = const TextStyle(fontSize: 18, color: Colors.black);
  Timer? timer;

  sync() {
    final saved = Provider.of<SettingNotifier>(context, listen: false);
    timer = Timer.periodic(
        const Duration(seconds: 30), (timer) => saved.syncSaved());
  }

  unSync() {
    timer?.cancel();
  }

  void _logout(BuildContext context) {
    unSync();
    var auth = Provider.of<SettingNotifier>(context, listen: false);
    auth.logout();
    setState(() {
      isLogedIn = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  void _pushSaved() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation)  {
          var auth = Provider.of<SettingNotifier>(context, listen: false);
          final tiles = auth.saved.map(
                (String pair) {
              return Dismissible(
                key: Key(pair),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete suggestion'),
                        content: Text('Are you sure you want do delete $pair'
                            ' from you saved suggestions?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              auth.saved.remove(pair);
                              Navigator.of(context).pop(true);
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Padding(
                                padding:
                                EdgeInsets.fromLTRB(17.0, 10.0, 17.0, 10.0),
                                child: Text(
                                  'Yes',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Padding(
                                padding:
                                EdgeInsets.fromLTRB(17.0, 10.0, 17.0, 10.0),
                                child: Text(
                                  'No',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                background: Container(
                  color: Colors.deepPurple,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: const [
                        Icon(Icons.delete_sweep, color: Colors.white),
                        Text(' Delete suggestion',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.deepPurple,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text('Delete suggestion ',
                            style: TextStyle(color: Colors.white)),
                        Icon(Icons.delete_sweep, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    pair,
                    style: _biggerFont,
                  ),
                  hoverColor: Colors.white10,
                ),
              );
            },
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1, 0.0);
          var end = Offset.zero;
          var curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),

    );
  }
  void _pushLogin() {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
      var auth = Provider.of<SettingNotifier>(context);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
        ),
        body: Center(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('welcome to startup generator please login',
                  style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Email',
                  alignLabelWithHint: true,
                ),
                controller: email,
              ),
              TextField(
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Password',
                ),
                controller: password,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    backgroundColor:
                    isLoginDisabled ? Colors.white24 : Colors.deepPurple),
                onPressed: isLoginDisabled
                    ? null
                    : () {
                  setState(() {
                    isLoginDisabled = true;
                  });
                  auth
                      .signIn(email.text, password.text, context)
                      .then((value) async {
                    if (value) {
                      setState(() {
                        isLoginDisabled = false;
                        isLogedIn = true;
                      });
                      const snak = SnackBar(
                        content: Text('Login success'),
                        duration: Duration(seconds: 2),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snak);
                      sync();
                      password.clear();
                      email.clear();
                      setState(() {
                        auth.status = Status.Authenticated;
                      });
                      Navigator.of(context).pop();
                    } else {
                      password.clear();
                      var snak = const SnackBar(
                        content: Text(
                            'There was an error logging into the app'),
                        duration: Duration(seconds: 2),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snak);
                      setState(() {
                        isLoginDisabled = false;
                      });
                    }
                  });
                },
                child: const Text('Login'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  backgroundColor: Colors.blue,
                ),
                onPressed: signUp,
                child: const Text('New user? Click to signup'),
              )
            ],
          ),
        ),
      );
    },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ));

  }



  void signUp() {
    TextEditingController rePassword = TextEditingController();
    var auth = Provider.of<SettingNotifier>(context, listen: false);
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please confirm your password below',
                    style: TextStyle(fontSize: 14),
                  ),
                  TextField(
                    obscureText: true,
                    controller: rePassword,
                    decoration: const InputDecoration(
                      hintText: 'confirm password',
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7)),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      if (rePassword.text == password.text) {
                        auth
                            .singUp(email.text, password.text, context)
                            .then((value) {
                          if (value != null) {
                            auth
                                .signIn(email.text, password.text, context)
                                .then((value) async {
                              if (value) {
                                setState(() {
                                  isLoginDisabled = false;
                                  isLogedIn = true;
                                });
                              }
                            });
                            password.clear();
                            rePassword.clear();
                            email.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Signed up'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          } else {
                            password.clear();
                            rePassword.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('There was an error signing up'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        });
                      } else {
                        password.clear();
                        rePassword.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords must match'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    var loginButton = IconButton(
      icon: const Icon(Icons.login_sharp),
      onPressed: _pushLogin,
      tooltip: "Login",
    );
    var logoutButton = IconButton(
      icon: const Icon(Icons.logout_sharp),
      onPressed: () => _logout(context),
      tooltip: "Logout",
    );
    var auth = Provider.of<SettingNotifier>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Startup name generator"),
        actions: [
          isLogedIn ? logoutButton : loginButton,
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),

        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, i) {
                if (i.isOdd) return const Divider();
                final index = i ~/ 2;
                if (index >= auth.suggestions.length) {
                  auth.suggestions.addAll(generateWordPairs().take(100));
                }
                final alreadySaved =
                    auth.saved.contains(auth.suggestions[index].asPascalCase);
                return ListTile(
                  title: Text(
                    auth.suggestions[index].asPascalCase,
                    style: _biggerFont,
                  ),
                  trailing: Icon(
                    alreadySaved ? Icons.favorite : Icons.favorite_border,
                    color: alreadySaved ? Colors.red : null,
                    semanticLabel: alreadySaved ? "Remove from saved" : "Save",
                  ),
                  onTap: () {
                    setState(() {
                      if (alreadySaved) {
                        auth.removeSaved(auth.suggestions[index].asPascalCase);
                      } else {
                        auth.addSaved(auth.suggestions[index].asPascalCase);
                      }
                    });
                  },
                );
              }),
          if (isLogedIn) LoginSheet()
        ],
      ),
    );
  }
}
