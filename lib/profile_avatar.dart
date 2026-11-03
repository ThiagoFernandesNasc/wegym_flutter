import 'dart:convert';

import 'package:flutter/material.dart';

import 'stitch_design_system.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 24,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final url = imageUrl?.trim() ?? '';
    return Semantics(
      image: true,
      label: 'Foto de $name',
      child: ClipOval(
        child: SizedBox.square(
          dimension: diameter,
          child: url.isEmpty
              ? _fallback(diameter)
              : url.startsWith('data:image/')
              ? _dataImage(url, diameter)
              : Image.network(
                  url,
                  key: ValueKey('profile-avatar-image-$name'),
                  width: diameter,
                  height: diameter,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallback(diameter),
                ),
        ),
      ),
    );
  }

  Widget _dataImage(String dataUrl, double diameter) {
    try {
      final separator = dataUrl.indexOf(',');
      if (separator < 0) return _fallback(diameter);
      return Image.memory(
        base64Decode(dataUrl.substring(separator + 1)),
        key: ValueKey('profile-avatar-data-$name'),
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(diameter),
      );
    } catch (_) {
      return _fallback(diameter);
    }
  }

  Widget _fallback(double diameter) => Container(
    key: const ValueKey('profile-avatar-fallback'),
    width: diameter,
    height: diameter,
    alignment: Alignment.center,
    color: stitchOrange.withValues(alpha: .2),
    child: Text(
      name.trim().isEmpty ? 'W' : name.trim().characters.first.toUpperCase(),
      style: TextStyle(
        color: stitchOrange,
        fontSize: radius * .85,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
