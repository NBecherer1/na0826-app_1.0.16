import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/JellyfinModels.dart';
import 'package:chopper/chopper.dart';
import 'package:logging/logging.dart';
import '../models/FinampModels.dart';
import 'package:get_it/get_it.dart';
import 'JellyfinApi.dart';
import 'dart:developer';



class JellyfinApiData {

  final _currentUserIdBox = Hive.box<String>("CurrentUserId");
  final _finampUserBox = Hive.box<FinampUser>("FinampUsers");
  final _jellyfinApiDataLogger = Logger("JellyfinApiData");
  final jellyfinApi = JellyfinApi.create();
  String? baseUrlTemp;

  /// Checks if there are any saved users.
  bool get isUsersEmpty => _finampUserBox.isEmpty;

  /// Loads the FinampUser with the id from CurrentUserId. Returns null if no
  /// user exists.
  FinampUser? get currentUser =>
      _finampUserBox.get(_currentUserIdBox.get("CurrentUserId"));

  ValueListenable<Box<FinampUser>> get finampUsersListenable =>
      _finampUserBox.listenable();

  /// Saves a new user to the Hive box and sets the CurrentUserId.
  Future<void> saveUser(FinampUser newUser) async {
    log("Saving new user");
    await Future.wait([
      _finampUserBox.put(newUser.id, newUser),
      _currentUserIdBox.put("CurrentUserId", newUser.id),
    ]);
  }

  /// Sets the views of the current user
  void setCurrentUserViews(List<BaseItemDto> newViews, [bool init = true]) {
    final currentUserId = _currentUserIdBox.get("CurrentUserId");
    FinampUser currentUserTemp = currentUser!;

    currentUserTemp.views = Map<String, BaseItemDto>.fromEntries(
        newViews.map((e) => MapEntry(e.id, e)));
    if (init) {
      currentUserTemp.currentViewId = currentUserTemp.views.keys.first;
    }

    _finampUserBox.put(currentUserId, currentUserTemp);
  }

  void setCurrentUserCurrentViewId(String newViewId) {

    final currentUserId = _currentUserIdBox.get("CurrentUserId");
    FinampUser currentUserTemp = currentUser!;

    currentUserTemp.currentViewId = newViewId;

    _finampUserBox.put(currentUserId, currentUserTemp);
  }

  Future<List<BaseItemDto>?> getItems({
    BaseItemDto? parentItem,
    String? includeItemTypes,
    String? sortBy,
    String? sortOrder,
    String? searchTerm,
    required bool isGenres,
    String? filters,
    /// The record index to start at. All items with a lower index will be
    /// dropped from the results.
    int? startIndex,

    /// The maximum number of records to return.
    int? limit,
  }) async {

    if (currentUser == null) {
      // When logging out, this request causes errors since currentUser is
      // required sometimes. We just return an empty list since this error
      // usually happens becuase the listeners on MusicScreenTabView update
      // milliseconds before the page is popped. This shouldn't happen in normal
      // use.
      return [];
    }

    Response response;

    // We send a different request for playlists so that we get them back in the
    // right order. Doing this in the same function makes sense since they both
    // return the same thing. It also means we can easily share album widgets
    // with playlists.
    if (parentItem?.type == "Playlist") {
      response = await jellyfinApi.getPlaylistItems(
        playlistId: parentItem!.id,
        // We'll be logged in to see playlists, so the null checks should be
        // fine.
        userId: currentUser!.id,
        parentId: parentItem.id,
        includeItemTypes: includeItemTypes,
        recursive: true,
      );
    } else if (includeItemTypes == "MusicArtist") {
      // For artists, we need to use a different endpoint
      response = await jellyfinApi.getAlbumArtists(
        parentId: parentItem?.id,
        recursive: true,
        sortBy: sortBy,
        sortOrder: sortOrder,
        searchTerm: searchTerm,
        filters: filters,
        startIndex: startIndex,
        limit: limit,
      );
    } else if (parentItem?.type == "MusicArtist") {
      // For getting the children of artists, we need to use albumArtistIds
      // instead of parentId
      response = await jellyfinApi.getItems(
        userId: currentUser!.id,
        albumArtistIds: parentItem?.id,
        includeItemTypes: includeItemTypes,
        recursive: true,
        sortBy: sortBy,
        sortOrder: sortOrder,
        searchTerm: searchTerm,
        filters: filters,
        startIndex: startIndex,
        limit: limit,
      );
    } else if (includeItemTypes == "MusicGenre") {
      response = await jellyfinApi.getGenres(
        parentId: parentItem?.id,
        // includeItemTypes: includeItemTypes,
        searchTerm: searchTerm,
        startIndex: startIndex,
        limit: limit,
      );
    } else if (parentItem?.type == "MusicGenre") {
      response = await jellyfinApi.getItems(
        userId: currentUser!.id,
        genreIds: parentItem?.id,
        includeItemTypes: includeItemTypes,
        recursive: true,
        sortBy: sortBy,
        sortOrder: sortOrder,
        searchTerm: searchTerm,
        filters: filters,
        startIndex: startIndex,
        limit: limit,
      );
    } else {

      // This will be run when getting albums, songs in albums, and stuff like
      // that.
      response = await jellyfinApi.getItems(
        userId: currentUser!.id,
        // TODO: 22
        // parentId: '7e64e319657a9516ec78490da03edccb', // Music
        parentId: parentItem?.id,
        includeItemTypes: includeItemTypes,
        recursive: true,
        sortBy: sortBy,
        sortOrder: sortOrder,
        searchTerm: searchTerm,
        filters: filters,
        startIndex: startIndex,
        limit: limit,
      );
    }

    if (response.isSuccessful) {
      return (QueryResult_BaseItemDto.fromJson(response.body).items);
    } else {
      return Future.error(response);
    }
  }

  Future<List<BaseItemDto>?> getItemsMusic({
    BaseItemDto? parentItem,
    String? includeItemTypes,
    String? sortBy,
    String? sortOrder,
    String? searchTerm,
    required bool isGenres,
    String? filters,
    /// The record index to start at. All items with a lower index will be
    /// dropped from the results.
    int? startIndex,

    /// The maximum number of records to return.
    int? limit,
  }) async {

    if (currentUser == null) {
      // When logging out, this request causes errors since currentUser is
      // required sometimes. We just return an empty list since this error
      // usually happens becuase the listeners on MusicScreenTabView update
      // milliseconds before the page is popped. This shouldn't happen in normal
      // use.
      return [];
    }

    Response response = await jellyfinApi.getItems(
      userId: currentUser!.id,
      // TODO: 22
      parentId: '7e64e319657a9516ec78490da03edccb', // Music
      // parentId: parentItem?.id,
      includeItemTypes: includeItemTypes,
      recursive: true,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchTerm: searchTerm,
      filters: filters,
      startIndex: startIndex,
      limit: limit,
    );

    if (response.isSuccessful) {
      return (QueryResult_BaseItemDto.fromJson(response.body).items);
    } else {
      return Future.error(response);
    }
  }

  Future<List<BaseItemDto>?> getItemsMusicTest({
    required String parentId,
    // String? includeItemTypes,
    String? sortBy,
    // String? sortOrder,
    // String? searchTerm,
    // required bool isGenres,
    // String? filters,
    /// The record index to start at. All items with a lower index will be
    /// dropped from the results.
    // int? startIndex,

    /// The maximum number of records to return.
    int? limit,
  }) async {

    if (currentUser == null) {
      // When logging out, this request causes errors since currentUser is
      // required sometimes. We just return an empty list since this error
      // usually happens becuase the listeners on MusicScreenTabView update
      // milliseconds before the page is popped. This shouldn't happen in normal
      // use.
      return [];
    }

    Response response = await jellyfinApi.getItems(
      userId: currentUser!.id,
      parentId: parentId,
      // includeItemTypes: includeItemTypes,
      // recursive: true,
      sortBy: sortBy,
      // sortOrder: sortOrder,
      // searchTerm: searchTerm,
      // filters: filters,
      // startIndex: startIndex,
      limit: limit,
    );

    if (response.isSuccessful) {
      return (QueryResult_BaseItemDto.fromJson(response.body).items);
    } else {
      return Future.error(response);
    }
  }


  /// Authenticates a user and saves the login details
  Future<void> authenticateViaName({
    required String username,
    String? password,
  }) async {
    Response response;

    // Some users won't have a password.
    if (password == null) {
      response = await jellyfinApi.authenticateViaName({"Username": username});
    } else {
      response = await jellyfinApi.authenticateViaName({"Username": username, "Pw": password});
    }

    if (response.isSuccessful) {
      AuthenticationResult newUserAuthenticationResult =
          AuthenticationResult.fromJson(response.body);

      FinampUser newUser = FinampUser(
        id: newUserAuthenticationResult.user!.id,
        baseUrl: baseUrlTemp!,
        accessToken: newUserAuthenticationResult.accessToken!,
        serverId: newUserAuthenticationResult.serverId!,
        views: {},
      );

      await saveUser(newUser);
    } else {
      return Future.error(response);
    }
  }

  /// Gets all the user's views.
  Future<List<BaseItemDto>> getViews() async {
    JellyfinApiData jellyfinApiData = GetIt.instance<JellyfinApiData>();
    // final view = jellyfinApiData.currentUser!.currentViewId;
    final Map<BaseItemDto, bool> _views = {};
    Response response = await jellyfinApi.getViews(currentUser!.id);
    if (response.isSuccessful) {
      final result = QueryResult_BaseItemDto.fromJson(response.body).items!;
      _views.addEntries(result.where((element) => element.collectionType != "playlists")
          .map((e) => MapEntry(e, e.collectionType == "music")));
      jellyfinApiData.setCurrentUserViews(_views.entries
          .where((element) => element.value == true)
          .map((e) => e.key)
          .toList(), false);
      // if (view != null) {
      //   jellyfinApiData.setCurrentUserCurrentViewId(view);
      // }
      return result;
    } else {
      return Future.error(response);
    }
  }

  /// Gets the playback info for an item, such as format and bitrate. Usually, I'd require a BaseItemDto as an argument
  /// but since this will be run inside of [MusicPlayerBackgroundTask], I've just set the raw id as an argument.
  Future<List<MediaSourceInfo>?> getPlaybackInfo(String itemId) async {
    Response response = await jellyfinApi.getPlaybackInfo(
      id: itemId,
      userId: currentUser!.id,
    );

    if (response.isSuccessful) {
      // getPlaybackInfo returns a PlaybackInfoResponse. We only need the List<MediaSourceInfo> in it so we convert it here and
      // return that List<MediaSourceInfo>.
      final PlaybackInfoResponse decodedResponse =
          PlaybackInfoResponse.fromJson(response.body);
      return decodedResponse.mediaSources;
    } else {
      return Future.error(response);
    }
  }

  /// Tells the Jellyfin server that playback has started
  Future<void> reportPlaybackStart(PlaybackProgressInfo playbackProgressInfo) async {
    Response response = await jellyfinApi.startPlayback(playbackProgressInfo);

    if (!response.isSuccessful) {
      return Future.error(response);
    }
  }

  /// Updates player progress so that Jellyfin can track what we're listening to
  Future<void> updatePlaybackProgress(
      PlaybackProgressInfo playbackProgressInfo) async {

    Response response =
        await jellyfinApi.playbackStatusUpdate(playbackProgressInfo);

    if (!response.isSuccessful) {
      return Future.error(response);
    }
  }

  /// Tells Jellyfin that we've stopped listening to music (called when the audio service is stopped)
  Future<void> stopPlaybackProgress(
      PlaybackProgressInfo playbackProgressInfo) async {
    Response response =
        await jellyfinApi.playbackStatusStopped(playbackProgressInfo);

    if (!response.isSuccessful) {
      return Future.error(response);
    }
  }

  /// Gets an item from a user's library.
  Future<BaseItemDto> getItemById(String itemId) async {
    final Response response = await jellyfinApi.getItemById(
      userId: currentUser!.id,
      itemId: itemId,
    );

    if (response.isSuccessful) {
      return (BaseItemDto.fromJson(response.body));
    } else {
      return Future.error(response);
    }
  }

  /// Creates a new playlist.
  Future<NewPlaylistResponse> createNewPlaylist(NewPlaylist newPlaylist) async {
    final Response response = await jellyfinApi.createNewPlaylist(
      newPlaylist: newPlaylist,
    );

    if (response.isSuccessful) {
      return NewPlaylistResponse.fromJson(response.body);
    } else {
      return Future.error(response);
    }
  }

  /// Adds items to a playlist.
  Future<void> addItemstoPlaylist({
    /// The playlist id.
    required String playlistId,

    /// Item ids to add.
    List<String>? ids,
  }) async {
    final Response response = await jellyfinApi.addItemsToPlaylist(
      playlistId: playlistId,
      ids: ids?.join(","),
    );

    if (!response.isSuccessful) {
      return Future.error(response);
    }
  }

  /// Updates an item.
  Future<void> updateItem({
    /// The item id.
    required String itemId,

    /// What to update the item with. You should give a BaseItemDto with only
    /// changed values.
    required BaseItemDto newItem,
  }) async {
    final Response response =
        await jellyfinApi.updateItem(itemId: itemId, newItem: newItem);

    if (!response.isSuccessful) {
      return Future.error(response);
    }
  }

  /// Marks an item as a favorite.
  Future<UserItemDataDto> addFavourite(String itemId) async {
    final Response response =
        await jellyfinApi.addFavourite(userId: currentUser!.id, itemId: itemId);

    if (response.isSuccessful) {
      return UserItemDataDto.fromJson(response.body);
    } else {
      return Future.error(response);
    }
  }

  /// Unmarks item as a favorite.
  Future<UserItemDataDto> removeFavourite(String itemId) async {
    final Response response = await jellyfinApi.removeFavourite(
        userId: currentUser!.id, itemId: itemId);

    if (response.isSuccessful) {
      return UserItemDataDto.fromJson(response.body);
    } else {
      return Future.error(response);
    }
  }

  /// Removes the current user from the DB and revokes the token on Jellyfin
  Future<void> logoutCurrentUser() async {
    Response? response;

    // We put this in a try-catch loop that basically ignores errors so that the
    // user can still log out during scenarios like wrong IP, no internet etc.

    try {
      response = await jellyfinApi.logout();
    } catch (e) {
      _jellyfinApiDataLogger.warning(
          "Jellyfin logout failed. Logging out anyway, but be aware that Jellyfin may have not got the signal.",
          e);
    } finally {
      // If the logout response wasn't successful, warn the user in the logs.
      // We continue anyway since this will mostly be for when the client becomes
      // unauthorised, which will return 401.
      if (response?.isSuccessful == false) {
        _jellyfinApiDataLogger.warning(
            "Jellyfin logout returned ${response!.statusCode}. Logging out anyway, but be aware that Jellyfin may still consider this device logged in.");
      }

      // If we're unauthorised, the logout command will fail but we're already
      // basically logged out so we shouldn't fail.
      _finampUserBox.delete(_currentUserIdBox.get("CurrentUserId"));
      _currentUserIdBox.delete("CurrentUserId");
    }
  }

  /// Creates the X-Emby-Token header
  String? getTokenHeader() {
    if (currentUser == null) {
      return null;
    } else {
      return currentUser!.accessToken;
    }
  }

  /// Returns the correct image URL for the given item, or null if there is no
  /// image. Uses [getImageId] to get the actual id. [maxWidth] and [maxHeight]
  /// can be specified to return a smaller image. [quality] can be modified to
  /// get a higher/lower quality image.
  Uri? getImageUrl({
    required BaseItemDto item,
    int? maxWidth,
    int? maxHeight,
    int quality = 90,
  }) {
    final imageId = getImageId(item);

    if (imageId != null) {
      final parsedBaseUrl = Uri.parse(currentUser!.baseUrl);

      return Uri(
          host: parsedBaseUrl.host,
          port: parsedBaseUrl.port,
          scheme: parsedBaseUrl.scheme,
          pathSegments: [
            "Items",
            imageId,
            "Images",
            "Primary",
          ],
          queryParameters: {
            "format": "jpg",
            "quality": quality.toString(),
            if (maxWidth != null) "MaxWidth": maxWidth.toString(),
            if (maxHeight != null) "MaxHeight": maxHeight.toString(),
          });
    }
  }

  /// Gets the image id of a given item. If the item has its own image, it will
  /// return the item id. Otherwise, if the item's parent has an image ID, it
  /// returns that ID. Otherwise, if the item is an album and has an album ID,
  /// it will return that. If the item meets none of these conditions, this
  /// function will return null.
  String? getImageId(BaseItemDto item) {
    if (item.imageTags?.containsKey("Primary") == true) {
      return item.id;
    } else if (item.parentPrimaryImageItemId != null) {
      return item.parentPrimaryImageItemId;
    } else if (item.albumId != null && item.albumPrimaryImageTag != null) {
      return item.albumId;
    }
  }
}
