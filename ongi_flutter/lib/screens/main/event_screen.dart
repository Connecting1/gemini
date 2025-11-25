// import 'package:flutter/material.dart';
//
// class EventScreenPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         child: Center(
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import '../auth/sign_up_start.dart';

class EventScreenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Image.asset(
            'assets/images/eaves.png', // ✅ 앱바처럼 상단에 배치
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Provider.of<SignUpProvider>(context, listen: false).logout(); // ✅ 로그아웃 기능 호출
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpStartPage()), // ✅ 로그인 화면으로 이동
                            (route) => false,
                      );
                    },
                    child: Text('로그아웃'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}