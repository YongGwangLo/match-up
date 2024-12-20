import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:match_up/data/model/user.dart';
import 'package:match_up/data/repository/user_repository.dart';
import 'package:match_up/data/repository/vworld_repository.dart';

class UserState {
  UserState({
    this.user,
    this.isNewUser = false,
    this.isLoading = false,
    this.isError = false,
  });

  UserModel? user;
  bool isNewUser;
  bool isLoading;
  bool isError;

  UserState copyWith({
    UserModel? user,
    bool? isNewUser,
    bool? isLoading,
    bool? isError,
  }) {
    return UserState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        isNewUser: isNewUser ?? this.isNewUser,
        isError: isError ?? this.isError);
  }
}

class UserViewModel extends Notifier<UserState> {
  @override
  UserState build() {
    return UserState(user: null);
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      // google 로그인

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        // 구글에서 받은 accessToken과 idToken을 firebase가 이해할수 있는 걸로 변환
        // .credential이라는 메서드는 google_auth 패키지꺼

        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        // Firebase에 로그인(앱에 로그인하는 것과는 별개임)
        // 새 사용자라면 Firebase Authentication에서 사용자 생성

        final user = userCredential.user;
        // 36번줄에서 로그인한 user의 uid, email, displyName, photoURL

        // ----아래부터는 이제 matchUp 로그인 로직입니다.----
        // 1. firestore에 user가 있는지 확인
        // 2. 없으면 정보 넣어주고, isNewUser는 true
        // 2-1. main에서 userState를 watch하다가 isNewUser가 true가 되면, registerPage로 보낼겁니다.
        // 3. 있으면 user정보 넣어주고, isNewUser는 false
        // 3-1. main에서 user가 null이 아니게 되면 mapPage로 보낼겁니다.
        // 4. registerPage에서 남은 정보를 입력하게 되면, fireStore를 업데이트하고 userState를 업데이트 해주는 함수로 업데이트 시킬겁니다.
        // 4-1. 풀어서 말하자면 userRepository의 saveUser를 실행시켜서 fireStore 업데이트, 그리고 userState업데이트, isNewUser = false가 되겠죠
        // ----끝----

        UserRepository userRepository = UserRepository();
        if (user != null) {
          final fetchedUser = await userRepository.fetchUser(user.uid);
          if (fetchedUser != null) {
            state = state.copyWith(
              user: fetchedUser,
              isLoading: false,
            );
          } else {
            state = state.copyWith(
              user: UserModel(
                  uid: user.uid,
                  name: user.displayName ?? "",
                  nickname: "",
                  img: user.photoURL ?? "",
                  geoPoint: GeoPoint(0, 0),
                  createdRooms: [],
                  joinedRooms: [],
                  address: ""),
              isNewUser: true,
              isLoading: false,
            );
          }
        }
      }
    } catch (e) {
      state = state.copyWith(user: null, isLoading: false, isError: true);
    }
  }

  Future<void> updateUserLocation(double latitude, double longitude) async {
    VworldRepository vworldRepository = VworldRepository();
    final user = state.user;
    if (user != null) {
      final geoPoint = GeoPoint(latitude, longitude);
      final address =
          await vworldRepository.findByLatLng(lat: latitude, lng: longitude);
      state = state.copyWith(
        user: user.copyWith(address: address[0], geoPoint: geoPoint),
      );
    }
  }

  Future<void> updateUserNickname(String newNickname) async {
    final user = state.user;
    if (user != null) {
      state = state.copyWith(
        user: user.copyWith(nickname: newNickname),
      );
    }
  }

  Future<void> submitUserToFirestore() async {
    final user = state.user;
    if (user != null) {
      try {
        UserRepository userRepository = UserRepository();
        await userRepository.saveUser(user);

        state = state.copyWith(
          isNewUser: false,
          isLoading: false,
        );
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          isError: true,
        );
      }
    }
  }

  Future<void> updateUserToFirestore(BuildContext context) async {
    final user = state.user;
    if (user != null) {
      try {
        UserRepository userRepository = UserRepository();
        await userRepository.updateUser(user);

        state = state.copyWith(
          isLoading: false,
          isError: false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('정보가 성공적으로 수정되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          isError: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('정보 수정에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

final userViewModelProvider = NotifierProvider<UserViewModel, UserState>(() {
  return UserViewModel();
});
