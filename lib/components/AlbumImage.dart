import 'package:cached_network_image/cached_network_image.dart';
import '../services/FinampSettingsHelper.dart';
import '../services/JellyfinApiData.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/JellyfinModels.dart';
import 'package:get_it/get_it.dart';




class AlbumImage extends StatelessWidget {
  AlbumImage({Key? key, this.item}) : super(key: key);

  final BaseItemDto? item;

  final JellyfinApiData _jellyfinApiData = GetIt.instance<JellyfinApiData>();

  static final BorderRadius borderRadius = BorderRadius.circular(4);

  @override
  Widget build(BuildContext context) {
    if (FinampSettingsHelper.finampSettings.isOffline || item == null) {
      // If we're in offline mode, don't show images since they could be loaded online
      return const _AlbumImageErrorPlaceholder();
    } else if (kDebugMode) {
      // If Flutter encounters an error, such as a 404, when getting an image, it will throw an exception.
      // This is super annoying while debugging since every blank album stops the whole app.
      // Because of this, I don't load images while the app is in debug mode.

      return AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            color: Theme.of(context).cardColor,
            child: Image.asset(
              'assets/images/logo.png',
            ),
            // child: const Placeholder(),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: borderRadius,
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, constraints) {
            // LayoutBuilder (and other pixel-related stuff in Flutter) returns logical pixels instead of physical pixels.
            // While this is great for doing layout stuff, we want to get images that are the right size in pixels.
            // Logical pixels aren't the same as the physical pixels on the device, they're quite a bit bigger.
            // If we use logical pixels for the image request, we'll get a smaller image than we want.
            // Because of this, we convert the logical pixels to physical pixels by multiplying by the device's DPI.
            final MediaQueryData mediaQuery = MediaQuery.of(context);
            final int physicalWidth =
                (constraints.maxWidth * mediaQuery.devicePixelRatio).toInt();
            final int physicalHeight =
                (constraints.maxHeight * mediaQuery.devicePixelRatio).toInt();

            Uri? imageUrl = _jellyfinApiData.getImageUrl(
              item: item!,
              maxWidth: physicalWidth,
              maxHeight: physicalHeight,
            );

            return CachedNetworkImage(
              imageUrl: imageUrl.toString(),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Theme.of(context).cardColor,
              ),
              errorWidget: (_, __, ___) => const _AlbumImageErrorPlaceholder(),
              // errorWidget: (_, __, ___) => Image.asset(
              //   'assets/images/logo.png',
              // ),
            );
          }),
        ),
      );
    }
  }
}

class _AlbumImageErrorPlaceholder extends StatelessWidget {
  const _AlbumImageErrorPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: AlbumImage.borderRadius,
        child: Container(
          color: Theme.of(context).cardColor,
          child: const Icon(Icons.album),
        ),
      ),
    );
  }
}
