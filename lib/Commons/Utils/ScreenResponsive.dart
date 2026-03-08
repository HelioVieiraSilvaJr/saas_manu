import 'package:flutter/material.dart';

// enum PlatformResponsive { mobile, tablet, web }
enum PlatformResponsive { mobile, web }

PlatformResponsive PLATFORMRESPONSIVE = PlatformResponsive.web;

class ScreenResponsive extends StatelessWidget {
  final Widget mobile;
  // final Widget? tablet;
  final Widget web;

  ScreenResponsive({
    Key? key,
    required this.mobile,
    required this.web,
    // this.tablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          PlatformResponsive platform;

          if (constraints.maxWidth >= 1000) {
            platform = PlatformResponsive.web;
          // } else if (constraints.maxWidth >= 500) {
          //   platform = tablet != null ? PlatformResponsive.tablet : PlatformResponsive.web;
          } else {
            platform = PlatformResponsive.mobile;
          }

          PLATFORMRESPONSIVE = platform;

          switch (platform) {
            case PlatformResponsive.web:
              return web;
            // case PlatformResponsive.tablet:
            //   return tablet!;
            case PlatformResponsive.mobile:
              return mobile;
          }
        },
      ),
    );
  }
}
