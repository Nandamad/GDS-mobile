import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionText extends StatefulWidget {
  final String prefix;
  final TextStyle style;

  const AppVersionText({super.key, required this.prefix, required this.style});

  @override
  State<AppVersionText> createState() => _AppVersionTextState();
}

class _AppVersionTextState extends State<AppVersionText> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final text = snapshot.hasError
            ? 'Versi tidak tersedia'
            : snapshot.hasData
            ? '${widget.prefix}${snapshot.data!.version}'
            : 'Memuat versi...';
        return Text(text, style: widget.style);
      },
    );
  }
}
