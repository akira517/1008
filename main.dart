import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:math' as math;
import 'dart:convert';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(child: RaisedButton(
        onPressed: () {
          //↓バッチ処理のテスト
          //batchTest();

          //↓jsonデータエクスポートのテスト
          //setCollection("teacher");

          //↓ソート処理のテスト（不完全）
          //sortCollection();

          //↓productコレクションとcustomerコレクションを作成し、
          //customerコレクション内部にproductコレクションを作成する３点セット
          //initCollection("product", jsonDecode(productSample));
          //initCollection("customer", jsonDecode(customerSample));
          //subColSet("customer", "product", jsonDecode(middleSample));

          transactionUpdateTest(
              "product", "P0", {"price": 2300, "productName": "akua"});
        },
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

//コレクショングループでソートするメソッド
Future<void> sortCollection() async {
  await Firebase.initializeApp();

  FirebaseFirestore.instance
      .collectionGroup("student")
      .where("studentId", isEqualTo: "5E4tm77pRdHDzcj0EBxL")
      //.where("club", isEqualTo: "soccer")
      .orderBy("score", descending: true)
      .get()
      .then((value) => value.docs.forEach((element) {
            print(element.data());
          }));
}

//コレクション内のドキュメント一覧を取得し、それぞれにサブコレクションを代入するメソッド
Future<void> setCollection(String col) async {
  await Firebase.initializeApp();

  //ドキュメントへのリファレンス作成
  CollectionReference colRef = FirebaseFirestore.instance.collection(col);

  //コレクションのドキュメント一覧のスナップショットを取得
  QuerySnapshot snapshots = await colRef.get();

  //生徒IDをしまうListを初期化
  List studentIds = [];

  snapshots.docs.forEach((snapshot) {
    List testDatas = jsonDecode(initString);

    if (studentIds.isEmpty) {
      testDatas.forEach((element) {
        studentIds.add(FirebaseFirestore.instance
            .collection(col)
            .doc("${snapshot.id}")
            .collection("students")
            .doc()
            .id);
      });
    }

    testDatas.asMap().forEach((index, data) {
      data = Map<String, dynamic>.from(data);

      //jsonDataに生徒IDと先生IDとポイントを更新

      //生徒ID
      data["studentId"] = studentIds[index];

      //先生ID
      data["teacherId"] = snapshot.id;
      //ポイント
      data["score"] = math.Random().nextInt(11);

      print(data);

      //Firestoreにセット
      FirebaseFirestore.instance
          .collection(col)
          .doc("${snapshot.id}")
          .collection("student")
          .add(data);
    });
  });
}

Future<void> batchTest() async {
  await Firebase.initializeApp();

  //インスタンスを生成
  var db = FirebaseFirestore.instance;
  //バッチを作成
  var batch = db.batch();
  //参照を作成
  var userNameRef = db.collection("user").doc("A2TEHAB6Dg1haD4hRlMK");

  //上のコレクションの名前を変更
  batch.update(userNameRef, {"name": "Yuyuko"});

  //nameがReimuの取得
  var postRef = db.collection("post").doc("4e4OIwreXnMI2hi0mZd3");

  //上のコレクションの名前を変更
  batch.update(postRef, {"userName": "Yuyuko"});

  batch.commit().then((value) => print("バッチ成功"));
}

//Map→コレクションの中の適当なドキュメント
Future<void> initCollection(String collection, List json) async {
  await Firebase.initializeApp();

  print("ok");

  json.forEach((element) {
    FirebaseFirestore.instance.collection(collection).doc().set(element);
  });
}

//サブコレクションをセット
Future<void> subColSet(String collection, String subColName, List data) async {
  await Firebase.initializeApp();
  var snapshot = await FirebaseFirestore.instance.collection(collection).get();
  snapshot.docs.forEach((doc) {
    data.forEach((json) {
      FirebaseFirestore.instance
          .collection(collection)
          .doc(doc.id)
          .collection(subColName)
          .doc()
          .set(json);
    });
  });
}

//トランザクションのテスト
//引数で指定した商品IDの情報をMapの値に更新します
//以下のコメントでは、引数のcollection=productを前提としている
Future<void> transactionUpdateTest(
    String collection, String productId, Map<String, dynamic> map) async {
  await Firebase.initializeApp();

  FirebaseFirestore.instance
      .runTransaction((transaction) async {
        //productコレクションを更新
        //指定したプロダクトIDのドキュメント取得
        var product = await FirebaseFirestore.instance
            .collection(collection)
            .where("productID", isEqualTo: productId)
            .get();

        //ドキュメントIDを取得して、更新データをセット
        product.docs.forEach((doc) {
          FirebaseFirestore.instance
              .collection(collection)
              .doc(doc.id)
              .update(map);
        });

        //中間コレクションのproductサブコレクション
        //customerコレクション下の全ドキュメントを取得
        var productDocs =
            await FirebaseFirestore.instance.collection("customer").get();
        //TODO:引数化したい

        //customerコレクション下の全ドキュメントを回す
        productDocs.docs.forEach((doc) {
          //customerコレクション下の全ドキュメントを取得
          FirebaseFirestore.instance
              .collection("customer")
              .doc(doc.id)
              .collection("product")
              .where("productID", isEqualTo: productId)
              .get()
              .then((subDoc) => subDoc.docs.forEach((subDoc) {
                    FirebaseFirestore.instance
                        .collection("customer")
                        .doc(doc.id)
                        .collection("product")
                        .doc(subDoc.id)
                        .update(map);
                  }));
        });
      })
      .then((_) => print("トランザクション完了"))
      .catchError((onError) {
        print(onError);
      });
}

String middleSample = '''
[
  {
    "customerID": "C0",
    "customerName": "Kristi",
    "age": 16,
    "productID": "P0",
    "productName": "Lavonne",
    "price": 2697
  },
  {
    "customerID": "C1",
    "customerName": "Murphy",
    "age": 18,
    "productID": "P1",
    "productName": "Millicent",
    "price": 8835
  },
  {
    "customerID": "C2",
    "customerName": "Burton",
    "age": 17,
    "productID": "P2",
    "productName": "Nadine",
    "price": 6428
  },
  {
    "customerID": "C3",
    "customerName": "Richmond",
    "age": 15,
    "productID": "P3",
    "productName": "Nicholson",
    "price": 5048
  },
  {
    "customerID": "C4",
    "customerName": "Lucile",
    "age": 18,
    "productID": "P4",
    "productName": "Carlene",
    "price": 4921
  }
]
''';

String productSample = '''
[
  {
    "productID": "P0",
    "productName": "Lavonne",
    "price": 2697
  },
  {
    "productID": "P1",
    "productName": "Millicent",
    "price": 8835
  },
  {
    "productID": "P2",
    "productName": "Nadine",
    "price": 6428
  },
  {
    "productID": "P3",
    "productName": "Nicholson",
    "price": 5048
  },
  {
    "productID": "P4",
    "productName": "Carlene",
    "price": 4921
  }
]
''';

String customerSample = '''
[
  {
    "customerID": "C0",
    "customerName": "Kristi",
    "age": 16
  },
  {
    "customerID": "C1",
    "customerName": "Murphy",
    "age": 18
  },
  {
    "customerID": "C2",
    "customerName": "Burton",
    "age": 17
  },
  {
    "customerID": "C3",
    "customerName": "Richmond",
    "age": 15
  },
  {
    "customerID": "C4",
    "customerName": "Lucile",
    "age": 18
  }
]
''';

//コレクションを書き込むメソッド
String initString = '''
[
  {
    "teacherId": "",
    "studentId": "",
    "name": "Norma Young",
    "age": 12,
    "subject": "baseBall",
    "score": 1
  },
  {
    "teacherId": "",
    "studentId": "",
    "name": "Rivers Thomas",
    "age": 14,
    "subject": "baseBall",
    "score": 0
  },
  {
    "teacherId": "",
    "studentId": "",
    "name": "Monica Matthews",
    "age": 14,
    "subject": "volleyBall",
    "score": 0
  },
  {
    "teacherId": "",
    "studentId": "",
    "name": "Dawson Pennington",
    "age": 13,
    "subject": "soccer",
    "score": 0
  },
  {
    "teacherId": "",
    "studentId": "",
    "name": "Phelps Olson",
    "age": 14,
    "subject": "volleyBall",
    "score": 0
  }
]
 ''';
