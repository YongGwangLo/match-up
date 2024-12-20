import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match_up/constant/colors.dart';
import 'package:match_up/ui/login/%08widgets/custom_social_button.dart';
import 'package:match_up/ui/viewmodels/user_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _gradientColor1;
  late Animation<Color?> _gradientColor2;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _gradientColor1 = ColorTween(
      begin: AppColors.black,
      end: AppColors.purple,
    ).animate(_controller);

    _gradientColor2 = ColorTween(
      begin: AppColors.purple,
      end: AppColors.black,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_gradientColor1.value!, _gradientColor2.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Center(
                child: Transform.translate(
                  offset: Offset(0, -50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "동네친구와 뜨거운 스포츠 한판!",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.white),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Image.asset(
                        "assets/images/login_logo.png",
                        width: 210,
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final userState = ref.watch(userViewModelProvider);
                      final userViewModel =
                          ref.read(userViewModelProvider.notifier);

                      if (userState.isLoading) {
                        return Center(
                          child:
                              CircularProgressIndicator(color: AppColors.white),
                        );
                      }

                      if (userState.isError) {
                        Future.delayed(Duration.zero, () {
                          // build보다 먼저 나온다고 에러가 나올때 해결법, UI가 랜더링 된 이후에
                          // snackBar가 나올수 있도록 보장하기 위한 delay
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Center(
                                child: Text(
                                  '로그인에 실패했습니다. 다시 시도해 주세요.',
                                  style: TextStyle(color: AppColors.white),
                                ),
                              ),
                              backgroundColor: AppColors.onError,
                            ),
                          );
                        });
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomSocialButton(
                            onPressed: () async {
                              userViewModel.signInWithGoogle();
                            },
                            text: "구글로 시작하기",
                            backgroundColor: AppColors.white,
                            textColor: AppColors.black,
                            iconPath: "assets/images/google_icon.png",
                            iconSize: 20,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      );
                    },
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
