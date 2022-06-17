import '../../services/MusicPlayerBackgroundTask.dart';
import 'package:na0826/models/JellyfinModels.dart';
import '../../services/JellyfinApiData.dart';
import '../../widgets/favourite_page.dart';
import '../../widgets/help_center.dart';
import 'OfflineModeSwitchListTile.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get/get.dart';
import 'ViewListTile.dart';
import 'dart:developer';
import 'dart:io';



class MusicScreenDrawer extends StatefulWidget {
  const MusicScreenDrawer({Key? key}) : super(key: key);

  @override
  _MusicScreenDrawerState createState() => _MusicScreenDrawerState();
}

class _MusicScreenDrawerState extends State<MusicScreenDrawer> {

  JellyfinApiData jellyfinApiData = GetIt.instance<JellyfinApiData>();
  final _audioHandler = GetIt.instance<MusicPlayerBackgroundTask>();
  late Future<List<BaseItemDto>> viewListFuture;
  final Map<BaseItemDto, bool> _views = {};

  @override
  void initState() {
    super.initState();
    viewListFuture = jellyfinApiData.getViews();
  }


  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
      context: context, builder: (context) => AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF00A4DC),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100)
                ),
                child: Image.asset('assets/images/logo-transparent.png',
                  height: 25, width: 25,
                  // color: MsMaterialColor(kPrimaryColor),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text("name_app".tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          )
      ),
      content: Text('msg_exit_app'.tr),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('no'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('yes'.tr),
        ),
      ],
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final jellyfinApiData = GetIt.instance<JellyfinApiData>();
    return Drawer(
      child: Scrollbar(
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate.fixed(
                [
                  DrawerHeader(
                      child: Stack(
                    children: const [
                      Align(
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: AssetImage(
                            'assets/images/logo-transparent-min.webp',
                          ),
                          radius: 50.0,
                        ),
                      ),
                    ],
                  )),

                  // TODO: 15
                  //Todo//*
                  ListTile(
                    leading: const Icon(Icons.file_download),
                    title: const Text("Downloads"),
                    onTap: () => Navigator.of(context).pushNamed("/downloads"),
                  ),
                  const OfflineModeSwitchListTile(),
                  const Divider(),
                   //Todo */

                  /*
                  ListTile(
                    leading: const Icon(Icons.star_rate),
                    title: const Text("Rate us"),
                    onTap: () async {
                      await rateMyApp.init().then((_) {
                        // if (rateMyApp.shouldOpenDialog) {
                          rateMyApp.showRateDialog(
                            context,
                            title: 'Your opinion interests us',
                            message: 'If you like this app, please give your opinion. It would help us a lot.Thank you!',
                            dialogStyle: const DialogStyle(
                              titleAlign: TextAlign.center,
                              messageAlign: TextAlign.center,
                              messagePadding: EdgeInsets.only(bottom: 20.0),
                            ),
                            rateButton: 'Rate',
                            noButton: 'No Thanks',
                            laterButton: 'Maybe Later',
                            onDismissed: () => rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed),
                          );
                        // }
                      });
                    }
                  ),
                  const Divider(),
                   */
                ],
              ),
            ),
            // This causes an error when logging out if we show this widget
            if (jellyfinApiData.currentUser != null)
              FutureBuilder<List<BaseItemDto>>(
                future: viewListFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    log('-------- 1 --------');
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return ViewListTile(
                            view: jellyfinApiData.currentUser!.views.values.elementAt(index));
                      }, childCount: jellyfinApiData.currentUser!.views.length),
                    );
                  } else {

                    if (_views.isEmpty) {
                      _views.addEntries(snapshot.data!
                          .where((element) => element.collectionType != "playlists")
                          .map((e) => MapEntry(e, e.collectionType == "music")));
                    }
                    log('-------- 2 -------- ${_views.keys.length}');
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return ViewListTile(
                            view: _views.keys.elementAt(index));
                      }, childCount: _views.keys.length),
                    );
                  }
                },
              ),



            SliverFillRemaining(
              hasScrollBody: false,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(),
                      // TODO: 16
                      /*
                      ListTile(
                        leading: const Icon(Icons.warning),
                        title: const Text("Logs"),
                        onTap: () => Navigator.of(context).pushNamed("/logs"),
                      ),
                       */
                      ListTile(
                        leading: const Icon(Icons.star),
                        title: Text("favorites".tr),
                        onTap: () => Get.to(() => const FavouritePage())
                      ),
                      ListTile(
                        leading: const Icon(Icons.menu_book),
                        title: Text("how_center".tr),
                        onTap: () => Get.to(() => const HelpCenter()),
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text("Settings"),
                        onTap: () => Navigator.of(context).pushNamed("/settings"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.mobile_off),
                        title: Text("exit_app".tr),
                        onTap: () async {
                          final exitApp = await _onWillPop(context);
                          if (exitApp) {
                            Navigator.of(context).pop();
                            await _audioHandler.stop();
                            if (Platform.isAndroid) {
                              SystemNavigator.pop();
                            } else if (Platform.isIOS) {
                              exit(0);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
