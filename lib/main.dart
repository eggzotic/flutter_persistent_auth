import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//
import 'counter_state.dart';

//
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Auth Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      // here's where we insert our Provider into the Widget tree. This
      //  MyHomePage widget, and any widget created below that, can access this
      //  instance of CounterState by simply calling
      //  "Provider.of<CounterState>(context)" in it's build method.
      home: ChangeNotifierProvider(
        create: (context) => CounterState(),
        child: MyHomePage(title: 'Cloud Auth Demo'),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    //
    // This method is rerun every time notifyListeners() is called from the Provider.
    //
    final counterState = Provider.of<CounterState>(context);
    //
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            icon: Icon(counterState.authIsValid ? Icons.lock_outline : Icons.lock_open),
            onPressed: counterState.isWaiting
                ? null
                : () {
                    counterState.toggleAuth();
                  },
            disabledColor: Colors.white.withOpacity(0.5),
          )
        ],
      ),
      body: counterState.hasError
          ? Center(child: Text("Oops, something's wrong!"))
          : counterState.isWaiting
              ? Center(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Please wait...'),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ))
              : !counterState.authIsValid
                  ? Center(
                      child: RaisedButton(
                        child: Text('Sign-in'),
                        color: Colors.blue,
                        textColor: Colors.white,
                        onPressed: () => counterState.toggleAuth(),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('The counter value is:'),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              elevation: 8.0,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                child: Text(
                                  '${counterState.value}',
                                  style: Theme.of(context).textTheme.display1,
                                ),
                              ),
                            ),
                          ),
                          (counterState.hasError || counterState.isWaiting)
                              ? Text('')
                              : Column(
                                  children: [
                                    Text('updated by device: ${counterState.lastUpdatedByDevice}'),
                                    SizedBox(height: 8.0),
                                    Text('and user: ${counterState.lastUpdatedByUser}'),
                                  ],
                                ),
                        ],
                      ),
                    ),
      floatingActionButton: counterState.authIsValid
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                FloatingActionButton(
                  child: Icon(Icons.undo),
                  // colours indicate when the button is inactive (i.e when counterState is waiting)
                  backgroundColor: counterState.isWaiting
                      ? Theme.of(context).buttonColor
                      : Theme.of(context).floatingActionButtonTheme.backgroundColor,
                  // the button action is disabled when counterState is waiting
                  onPressed: counterState.isWaiting ? null : counterState.reset,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('${counterState.myDevice}'),
                    SizedBox(height: 4.0),
                    Text('${counterState.userName}'),
                  ],
                ),
                FloatingActionButton(
                  child: Icon(Icons.add),
                  // colours indicate when the button is inactive (i.e when counterState is waiting)
                  backgroundColor: (counterState.isWaiting || counterState.hasError)
                      ? Theme.of(context).buttonColor
                      : Theme.of(context).floatingActionButtonTheme.backgroundColor,
                  // the button action is disabled when counterState is waiting
                  onPressed: (counterState.isWaiting || counterState.hasError) ? null : counterState.increment,
                ),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
