import 'package:errand/pages/Homepage/home.dart';
import 'package:errand/pages/Taskpage/post_task.dart';
import 'package:errand/pages/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class Navigationbar extends StatelessWidget {
  const Navigationbar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Scaffold(
      bottomNavigationBar: Obx(
        () => Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 63, 97),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4), // Lifting effect
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: Colors.transparent, // Remove selection effect
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent, // Blend with the container
              height: 50,
              elevation: 0,
              selectedIndex: controller.selectedIndex.value,
              onDestinationSelected:
                  (index) => controller.selectedIndex.value = index,
              labelBehavior:
                  NavigationDestinationLabelBehavior
                      .onlyShowSelected, // Hide labels until clicked
              destinations: const [
                NavigationDestination(
                  icon: Icon(Iconsax.home, color: Colors.white),
                  selectedIcon: Icon(
                    Iconsax.home5,
                    color: Colors.white,
                  ), // Different icon when selected
                  label: "Home",
                ),
                NavigationDestination(
                  icon: Icon(Iconsax.clipboard_text, color: Colors.white),
                  selectedIcon: Icon(
                    Iconsax.clipboard_text5,
                    color: Colors.white,
                  ),
                  label: "Post Task",
                ),
                NavigationDestination(
                  icon: Icon(Iconsax.heart, color: Colors.white),
                  selectedIcon: Icon(Iconsax.heart5, color: Colors.white),
                  label: "Favourites",
                ),
                NavigationDestination(
                  icon: Icon(Iconsax.user, color: Colors.white),
                  selectedIcon: Icon(Iconsax.user, color: Colors.white),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const Home(),
    PostTaskPage(),
    Container(color: const Color.fromARGB(255, 255, 255, 255)),
    ProfilePage(),
  ];
}
