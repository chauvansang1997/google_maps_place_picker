import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker/google_maps_place_picker.dart';
import 'package:google_maps_place_picker/providers/place_provider.dart';
import 'package:google_maps_place_picker/src/controllers/autocomplete_search_controller.dart';
import 'package:google_maps_place_picker/src/embedded_autocomplete_search.dart';
import 'package:google_maps_place_picker/src/embedded_place_picker.dart';
import 'package:google_maps_place_picker/src/google_map_place_picker.dart';
import 'package:google_maps_place_picker/src/utils/uuid.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class EmbeddedSearchGoogleMap extends StatefulWidget {
  EmbeddedSearchGoogleMap(
      {Key? key,
      required this.apiKey,
      this.onPlacePicked,
      required this.initialPosition,
      this.useCurrentLocation = true,
      this.desiredLocationAccuracy = LocationAccuracy.high,
      this.onMapCreated,
      this.searchingText,
      this.onAutoCompleteFailed,
      this.onGeocodingSearchFailed,
      this.proxyBaseUrl,
      this.httpClient,
      this.selectedPlaceWidgetBuilder,
      this.pinBuilder,
      this.autoCompleteDebounceInMilliseconds = 500,
      this.cameraMoveDebounceInMilliseconds = 750,
      this.initialMapType = MapType.normal,
      this.enableMapTypeButton = true,
      this.enableMyLocationButton = true,
      this.myLocationButtonCooldown = 10,
      this.usePinPointingSearch = true,
      this.usePlaceDetailSearch = false,
      this.autocompleteOffset,
      this.autocompleteRadius,
      this.autocompleteLanguage,
      this.autocompleteComponents,
      this.autocompleteTypes,
      this.strictbounds,
      this.region,
      this.selectInitialPosition = false,
      this.resizeToAvoidBottomInset = true,
      this.initialSearchString,
      this.searchForInitialValue = false,
      this.forceAndroidLocationManager = false,
      this.forceSearchOnZoomChanged = false,
      this.autocompleteOnTrailingWhitespace = false,
      this.hidePlaceDetailsWhenDraggingPin = true,
      this.mapPadding = const EdgeInsets.fromLTRB(0, 5, 0, 0),
      this.suggestionPadding = const EdgeInsets.fromLTRB(0, 5, 0, 0),
      this.searchHeight = 40,
      this.inputDecoration,
      this.iconClear,
      this.mapDecoration,
      this.mapBorderRadius,
      this.enableMyLocation})
      : super(key: key);

  final String apiKey;

  final LatLng initialPosition;
  final bool? useCurrentLocation;
  final LocationAccuracy desiredLocationAccuracy;
  final EdgeInsetsGeometry mapPadding;
  final EdgeInsetsGeometry suggestionPadding;
  final double searchHeight;
  final Decoration? mapDecoration;
  final MapCreatedCallback? onMapCreated;
  final String? searchingText;
  final InputDecoration? inputDecoration;
  final Widget? iconClear;
  final BorderRadius? mapBorderRadius;

  // final double searchBarHeight;
  // final EdgeInsetsGeometry contentPadding;

  final ValueChanged<String>? onAutoCompleteFailed;
  final ValueChanged<String>? onGeocodingSearchFailed;
  final int autoCompleteDebounceInMilliseconds;
  final int cameraMoveDebounceInMilliseconds;

  final MapType initialMapType;
  final bool enableMapTypeButton;
  final bool enableMyLocationButton;
  final int myLocationButtonCooldown;

  final bool usePinPointingSearch;
  final bool usePlaceDetailSearch;
  final bool? enableMyLocation;
  final num? autocompleteOffset;
  final num? autocompleteRadius;
  final String? autocompleteLanguage;
  final List<String>? autocompleteTypes;
  final List<Component>? autocompleteComponents;
  final bool? strictbounds;
  final String? region;

  /// If true the [body] and the scaffold's floating widgets should size
  /// themselves to avoid the onscreen keyboard whose height is defined by the
  /// ambient [MediaQuery]'s [MediaQueryData.viewInsets] `bottom` property.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// scaffold, the body can be resized to avoid overlapping the keyboard, which
  /// prevents widgets inside the body from being obscured by the keyboard.
  ///
  /// Defaults to true.
  final bool resizeToAvoidBottomInset;

  final bool selectInitialPosition;

  /// By using default setting of Place Picker, it will result result when user hits the select here button.
  ///
  /// If you managed to use your own [selectedPlaceWidgetBuilder], then this WILL NOT be invoked, and you need use data which is
  /// being sent with [selectedPlaceWidgetBuilder].
  final ValueChanged<PickResult>? onPlacePicked;

  /// optional - builds selected place's UI
  ///
  /// It is provided by default if you leave it as a null.
  /// INPORTANT: If this is non-null, [onPlacePicked] will not be invoked, as there will be no default 'Select here' button.
  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;

  /// optional - builds customized pin widget which indicates current pointing position.
  ///
  /// It is provided by default if you leave it as a null.
  final PinBuilder? pinBuilder;

  /// optional - sets 'proxy' value in google_maps_webservice
  ///
  /// In case of using a proxy the baseUrl can be set.
  /// The apiKey is not required in case the proxy sets it.
  /// (Not storing the apiKey in the app is good practice)
  final String? proxyBaseUrl;

  /// optional - set 'client' value in google_maps_webservice
  ///
  /// In case of using a proxy url that requires authentication
  /// or custom configuration
  final BaseClient? httpClient;

  /// Initial value of autocomplete search
  final String? initialSearchString;

  /// Whether to search for the initial value or not
  final bool searchForInitialValue;

  /// On Android devices you can set [forceAndroidLocationManager]
  /// to true to force the plugin to use the [LocationManager] to determine the
  /// position instead of the [FusedLocationProviderClient]. On iOS this is ignored.
  final bool forceAndroidLocationManager;

  /// Allow searching place when zoom has changed. By default searching is disabled when zoom has changed in order to prevent unwilling API usage.
  final bool forceSearchOnZoomChanged;

  /// Will perform an autocomplete search, if set to true. Note that setting
  /// this to true, while providing a smoother UX experience, may cause
  /// additional unnecessary queries to the Places API.
  ///
  /// Defaults to false.
  final bool autocompleteOnTrailingWhitespace;

  final bool hidePlaceDetailsWhenDraggingPin;

  @override
  _EmbeddedSearchGoogleMapState createState() =>
      _EmbeddedSearchGoogleMapState();
}

class _EmbeddedSearchGoogleMapState extends State<EmbeddedSearchGoogleMap>
    with AutomaticKeepAliveClientMixin {
  Future<PlaceProvider>? _futureProvider;
  PlaceProvider? provider;
  EmbeddedSearchBarController searchBarController =
      EmbeddedSearchBarController();

  @override
  void initState() {
    super.initState();

    _futureProvider = _initPlaceProvider();
  }

  @override
  void dispose() {
    searchBarController.dispose();

    super.dispose();
  }

  Future<PlaceProvider> _initPlaceProvider() async {
    final headers = await GoogleApiHeaders().getHeaders();
    final provider = PlaceProvider(
      widget.apiKey,
      widget.proxyBaseUrl,
      widget.httpClient,
      headers,
    );
    provider.sessionToken = Uuid().generateV4();
    provider.desiredAccuracy = widget.desiredLocationAccuracy;
    provider.setMapType(widget.initialMapType);

    return provider;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () {
        searchBarController.clearOverlay();
        return Future.value(true);
      },
      child: FutureBuilder<PlaceProvider>(
        future: _futureProvider,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            provider = snapshot.data;

            return MultiProvider(
              providers: [
                ChangeNotifierProvider<PlaceProvider>.value(value: provider!),
              ],
              child: Material(
                color: Colors.white,
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildSearchBar(context),
                      Expanded(child: _buildMapWithLocation()),
                    ],
                  ),
                ),
              ),
            );
          }

          final children = <Widget>[];
          if (snapshot.hasError) {
            children.addAll([
              Icon(
                Icons.error_outline,
                color: Theme.of(context).errorColor,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              )
            ]);
          } else {
            children.add(CircularProgressIndicator());
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return EmbeddedAutoCompleteSearch(
      height: widget.searchHeight,
      key: ValueKey<String>('EmbeddedAutoCompleteSearch'),
      suggestionPadding: widget.suggestionPadding,
      searchBarController: searchBarController,
      sessionToken: provider!.sessionToken,
      searchingText: widget.searchingText,
      debounceMilliseconds: widget.autoCompleteDebounceInMilliseconds,
      onPicked: (prediction) {
        _pickPrediction(prediction);
      },
      inputDecoration: widget.inputDecoration,
      iconClear: widget.iconClear,
      onSearchFailed: (status) {
        if (widget.onAutoCompleteFailed != null) {
          widget.onAutoCompleteFailed!(status);
        }
      },
      autocompleteOffset: widget.autocompleteOffset,
      autocompleteRadius: widget.autocompleteRadius,
      autocompleteLanguage: widget.autocompleteLanguage,
      autocompleteComponents: widget.autocompleteComponents,
      autocompleteTypes: widget.autocompleteTypes,
      strictbounds: widget.strictbounds,
      region: widget.region,
      initialSearchString: widget.initialSearchString,
      searchForInitialValue: widget.searchForInitialValue,
      autocompleteOnTrailingWhitespace: widget.autocompleteOnTrailingWhitespace,
    );
  }

  _pickPrediction(Prediction prediction) async {

    provider!.placeSearchingState = SearchingState.Searching;
    try {
      final PlacesDetailsResponse response =
          await provider!.places.getDetailsByPlaceId(
        prediction.placeId!,
        sessionToken: provider!.sessionToken,
        language: widget.autocompleteLanguage,
      );

      if (response.errorMessage?.isNotEmpty == true ||
          response.status == "REQUEST_DENIED") {
        if (widget.onAutoCompleteFailed != null) {
          widget.onAutoCompleteFailed!(response.status);
        }
        return;
      }

      PickResult result = PickResult.fromPlaceDetailResult(response.result);
      String city = '';
      String country = '';
      String state = '';

      String shortCity = '';
      String shortCountry = '';
      String shortState = '';

      if (result.addressComponents != null) {
        for (final addressComponent in result.addressComponents!) {
          if (addressComponent.types.contains('country')) {
            country = addressComponent.longName;
            shortCountry = addressComponent.shortName;
          } else if (addressComponent.types.contains('locality')) {
            city = addressComponent.longName;
            shortCity = addressComponent.shortName;
          } else if (addressComponent.types
              .contains('administrative_area_level_1')) {
            state = addressComponent.longName;
            shortState = addressComponent.shortName;
          }
        }
      }

      String shortAddress = '';
      if (shortCity != '') {
        shortAddress += '$shortCity, ';
      }

      if (shortState != '') {
        shortAddress += '$shortState';
      } else {
        shortAddress = shortAddress.replaceAll(', ', '');
      }

      result.shortAddress = shortAddress;

      if (city != state) {
        result.city = city;
        result.state = state;
      } else {
        result.city = city;
        result.state = '';
      }

      result.country = country;
      String address = '';
      if (result.city != null && result.city != '') {
        address += '${result.city}, ';
      }

      if (result.state != null && result.state != '') {
        address += '${result.state}, ';
      }
      if (result.country != null && result.country != '') {
        address += '${result.country}';
      } else {
        address = address.replaceAll(', ', '');
      }

      result.localityAddress = address;
      provider!.selectedPlace = result;

      // Prevents searching again by camera movement.
      provider!.isAutoCompleteSearching = true;

      if (provider?.selectedPlace != null) {
        widget.onPlacePicked?.call(provider!.selectedPlace!);
      }

      await _moveTo(provider!.selectedPlace!.geometry!.location.lat,
          provider!.selectedPlace!.geometry!.location.lng);

      provider!.placeSearchingState = SearchingState.Idle;
    } catch (e) {
      provider!.placeSearchingState = SearchingState.Idle;
    }
  }

  _moveTo(double latitude, double longitude) async {
    GoogleMapController? controller = provider?.mapController;
    if (controller == null) return;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 16,
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  _moveToCurrentPosition() async {
    if (provider!.currentPosition != null) {
      await _moveTo(provider!.currentPosition!.latitude,
          provider!.currentPosition!.longitude);
    }
  }

  Widget _buildMapWithLocation() {
    return FutureBuilder(
      future:
          provider!.updateCurrentLocation(widget.forceAndroidLocationManager),
      builder: (context, snap) {
        if (provider!.currentPosition == null) {
          return _buildMap(widget.initialPosition);
        } else {
          return _buildMap(LatLng(provider!.currentPosition!.latitude,
              provider!.currentPosition!.longitude));
        }
      },
    );
  }

  Widget _buildMap(LatLng initialTarget) {
    return Padding(
      padding: widget.mapPadding,
      child: EmbeddedPlacePicker(
        initialTarget: initialTarget,
        enableMyLocation: widget.enableMyLocation,
        borderRadius: widget.mapBorderRadius,
        selectedPlaceWidgetBuilder: widget.selectedPlaceWidgetBuilder,
        pinBuilder: widget.pinBuilder,
        onSearchFailed: widget.onGeocodingSearchFailed,
        debounceMilliseconds: widget.cameraMoveDebounceInMilliseconds,
        enableMapTypeButton: widget.enableMapTypeButton,
        enableMyLocationButton: widget.enableMyLocationButton,
        usePinPointingSearch: widget.usePinPointingSearch,
        usePlaceDetailSearch: widget.usePlaceDetailSearch,
        onMapCreated: widget.onMapCreated,
        selectInitialPosition: widget.selectInitialPosition,
        language: widget.autocompleteLanguage,
        forceSearchOnZoomChanged: widget.forceSearchOnZoomChanged,
        hidePlaceDetailsWhenDraggingPin: widget.hidePlaceDetailsWhenDraggingPin,
        onToggleMapType: () {
          provider!.switchMapType();
        },
        onMyLocation: () async {
          // Prevent to click many times in short period.
          if (provider!.isOnUpdateLocationCooldown == false) {
            provider!.isOnUpdateLocationCooldown = true;
            Timer(
              Duration(seconds: widget.myLocationButtonCooldown),
              () {
                provider!.isOnUpdateLocationCooldown = false;
              },
            );
            await provider!
                .updateCurrentLocation(widget.forceAndroidLocationManager);
            await _moveToCurrentPosition();
          }
        },
        onPlacePicked: (PickResult result) {
          widget.onPlacePicked?.call(result);
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
