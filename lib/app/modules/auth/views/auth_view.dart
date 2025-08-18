import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class AuthView extends GetView<AuthController> {
  AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logokpu.png', width: 200),
                const SizedBox(height: 20),
                // const Text(
                //   'Selamat Datang di Perjadin KPU',
                //   style: TextStyle(
                //     fontSize: 20,
                //     fontWeight: FontWeight.bold,
                // color: Color.fromRGBO(68, 185, 255, 1),
                //   ),
                // ),
                const SizedBox(height: 28),
                TextField(
                  controller: controller.emailT,
                  decoration: InputDecoration(
                    labelText: 'Email Pengguna',
                    border: OutlineInputBorder(),
                    errorText:
                        controller.authError.value ? 'Email tidak valid' : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.passwordT,
                  obscureText: controller.isObscureText.value,
                  decoration: InputDecoration(
                    errorText:
                        controller.authError.value
                            ? 'Kata sandi tidak valid'
                            : null,
                    labelText: 'Kata Sandi',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.visibility),
                      onPressed:
                          () =>
                              controller.isObscureText.value =
                                  !controller.isObscureText.value,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF78C7FF),
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      controller.login(
                        controller.emailT.text,
                        controller.passwordT.text,
                      );
                    },
                    child: const Text(
                      'Masuk',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // body: CustomScrollView(
        //   slivers: [
        //     SliverAppBar(
        //       backgroundColor: Color.fromRGBO(68, 185, 255, 1),
        //       expandedHeight: 150,
        //       flexibleSpace: FlexibleSpaceBar(
        //         background: SafeArea(
        //           child: Padding(
        //             padding: const EdgeInsets.all(8.0),
        //             child: Image.asset('assets/images/logokpu.png'),
        //           ),
        //         ),
        //       ),
        //     ),
        //     SliverToBoxAdapter(
        //       child: Container(
        //         padding: const EdgeInsets.all(20),
        //         child: Column(
        //           children: [
        //             Text(
        //               'Selamat Datang di Perjadin KPU',
        //               style: TextStyle(
        //                 fontSize: 20,
        //                 fontWeight: FontWeight.bold,
        //                 color: Color.fromRGBO(68, 185, 255, 1),
        //               ),
        //             ),
        //             SizedBox(height: 28),

        //             SizedBox(height: 16),
        //             TextField(
        //               decoration: InputDecoration(
        //                 labelText: 'Nama Pengguna',
        //                 border: OutlineInputBorder(),
        //               ),
        //             ),
        //             SizedBox(height: 16),
        //             TextField(
        //               obscureText: true,
        //               decoration: InputDecoration(
        //                 labelText: 'Kata Sandi',
        //                 border: OutlineInputBorder(),
        //                 suffixIcon: IconButton(
        //                   icon: Icon(Icons.visibility),
        //                   onPressed: () {},
        //                 ),
        //               ),
        //             ),
        //             SizedBox(height: 16),
        //             Row(
        //               mainAxisAlignment: MainAxisAlignment.start,
        //               children: [
        //                 ElevatedButton(onPressed: () {}, child: Text('Masuk')),
        //               ],
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      );
    });
  }
}
