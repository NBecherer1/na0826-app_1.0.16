import '../../services/MusicPlayerBackgroundTask.dart';
import '../../services/progressStateStream.dart';
import '../../generateMaterialColor.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../printDuration.dart';




class ProgressSlider extends StatefulWidget {
  const ProgressSlider({Key? key}) : super(key: key);

  @override
  _ProgressSliderState createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider> {
  /// Value used to hold the slider's value when dragging.
  double? _dragValue;

  late SliderThemeData _sliderThemeData;

  final _audioHandler = GetIt.instance<MusicPlayerBackgroundTask>();


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 2.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.instance<MusicPlayerBackgroundTask>();
    return StreamBuilder<ProgressState>(
      stream: progressStateStream,
      builder: (context, snapshot) {
        if (snapshot.data?.mediaItem == null) {
          // If nothing is playing or the AudioService isn't connected, return a
          // greyed out slider with some fake numbers. We also do this if
          // currentPosition is null, which sometimes happens when the app is
          // closed and reopened.
          return Column(
            children: [
              SliderTheme(
                data: _sliderThemeData.copyWith(
                  trackShape: CustomTrackShape(),
                ),
                child: const Slider(
                  value: 0,
                  max: 1,
                  onChanged: null,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "00:00",
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(
                        color: Theme.of(context).textTheme.caption?.color),
                  ),
                  Text(
                    "00:00",
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(
                        color: Theme.of(context).textTheme.caption?.color),
                  ),
                ],
              ),
            ],
          );
        } else if (snapshot.hasData) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0, right: 8),
                child: IconButton(
                  iconSize: 30,
                  icon: Image.asset('assets/icon/15_backward_forward_icon.png',
                    color: Colors.white,
                  ),
                  // icon: const Icon(MdiIcons.skipBackward),
                  onPressed: () async {
                    int _inSeconds = snapshot.data!.position.inSeconds - 15;
                    await audioHandler.seek2(Duration(seconds: _inSeconds));
                  },
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        SliderTheme(
                          data: _sliderThemeData.copyWith(
                            thumbShape: HiddenThumbComponentShape(),
                            activeTrackColor:
                            generateMaterialColor(Theme.of(context).primaryColor)
                                .shade300,
                            inactiveTrackColor:
                            generateMaterialColor(Theme.of(context).primaryColor)
                                .shade500,
                            trackShape: CustomTrackShape(),
                          ),
                          child: ExcludeSemantics(
                            child: Slider(
                              min: 0.0,
                              max: snapshot.data!.mediaItem?.duration == null
                                  ? snapshot.data!.playbackState.bufferedPosition
                                  .inMicroseconds
                                  .toDouble()
                                  : snapshot.data!.mediaItem!.duration!.inMicroseconds
                                  .toDouble(),
                              // We do this check to not show buffer status on
                              // downloaded songs.
                              value: snapshot.data!.mediaItem
                                  ?.extras?["downloadedSongJson"] ==
                                  null
                                  ? snapshot.data!.playbackState.bufferedPosition
                                  .inMicroseconds
                                  .clamp(
                                0.0,
                                snapshot.data!.mediaItem!.duration == null
                                    ? snapshot.data!.playbackState
                                    .bufferedPosition.inMicroseconds
                                    : snapshot.data!.mediaItem!.duration!
                                    .inMicroseconds,
                              ).toDouble() : 0,
                              onChanged: (_) {},
                            ),
                          ),
                        ),
                        SliderTheme(
                          data: _sliderThemeData.copyWith(
                            inactiveTrackColor: Colors.transparent,
                            trackShape: CustomTrackShape(),
                          ),
                          child: Slider(
                            min: 0.0,
                            activeColor: Colors.white,
                            max: snapshot.data!.mediaItem?.duration == null
                                ? snapshot.data!.playbackState.bufferedPosition
                                .inMicroseconds
                                .toDouble()
                                : snapshot.data!.mediaItem!.duration!.inMicroseconds
                                .toDouble(),
                            // value: sliderValue == null
                            //     ? 0
                            //     : sliderValue!
                            //         .clamp(
                            //           0.0,
                            //           snapshot.data!.mediaItem?.duration == null
                            //               ? snapshot.data!.playbackState
                            //                   .bufferedPosition.inMicroseconds
                            //               : snapshot.data!.mediaItem!.duration!
                            //                   .inMicroseconds,
                            //         )
                            //         .toDouble(),
                            value: (_dragValue ??
                                snapshot.data!.position.inMicroseconds)
                                .clamp(
                                0,
                                snapshot.data!.mediaItem!.duration!.inMicroseconds
                                    .toDouble())
                                .toDouble(),
                            onChanged: (newValue) async {
                              // We don't actually tell audio_service to seek here
                              // because it would get flooded with seek requests
                              setState(() {
                                _dragValue = newValue;
                              });
                            },
                            onChangeStart: (value) {
                              setState(() {
                                _dragValue = value;
                              });
                            },
                            onChangeEnd: (newValue) async {
                              // Seek to the new position
                              await _audioHandler
                                  .seek(Duration(microseconds: newValue.toInt()));

                              // Clear drag value so that the slider uses the play
                              // duration again.
                              setState(() {
                                _dragValue = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          printDuration(
                            Duration(
                                microseconds: _dragValue?.toInt() ??
                                    snapshot.data!.position.inMicroseconds),
                          ),
                          style: Theme.of(context).textTheme.bodyText2?.copyWith(
                              color: Theme.of(context).textTheme.caption?.color),
                        ),
                        Text(
                          printDuration(snapshot.data!.mediaItem?.duration),
                          style: Theme.of(context).textTheme.bodyText2?.copyWith(
                              color: Theme.of(context).textTheme.caption?.color),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 0),
                child: IconButton(
                  iconSize: 30,
                  icon: Image.asset('assets/icon/15_forward_media_icon.png',
                    color: Colors.white,
                  ),
                  // icon: const Icon(MdiIcons.skipForward),
                  onPressed: () async {
                    int _inSeconds = snapshot.data!.position.inSeconds + 15;
                    await audioHandler.seek2(Duration(seconds: _inSeconds));
                  },
                ),
              ),
            ],
          );
        } else {
          return const Text(
            "Snapshot doesn't have data and MediaItem isn't null and AudioService is connected?",
          );
        }
      },
    );
  }
}

class HiddenThumbComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double>? activationAnimation,
    Animation<double>? enableAnimation,
    bool? isDiscrete,
    TextPainter? labelPainter,
    RenderBox? parentBox,
    SliderThemeData? sliderTheme,
    TextDirection? textDirection,
    double? value,
    double? textScaleFactor,
    Size? sizeWithOverflow,
  }) {}
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;

  PositionData(this.position, this.bufferedPosition);
}

/// Track shape used to remove horizontal padding.
/// https://github.com/flutter/flutter/issues/37057
class CustomTrackShape extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
