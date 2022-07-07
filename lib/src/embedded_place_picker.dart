import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker/google_maps_place_picker.dart';
import 'package:google_maps_place_picker/providers/place_provider.dart';
import 'package:google_maps_place_picker/src/bubble.dart';
import 'package:google_maps_place_picker/src/google_map_place_picker.dart';
import 'package:google_maps_webservice/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

class EmbeddedPlacePicker extends StatefulWidget {
  const EmbeddedPlacePicker({
    Key? key,
    required this.initialTarget,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.onSearchFailed,
    this.onMoveStart,
    this.onMapCreated,
    this.debounceMilliseconds,
    this.enableMapTypeButton,
    this.enableMyLocationButton,
    this.onToggleMapType,
    this.onMyLocation,
    this.onPlacePicked,
    this.usePinPointingSearch,
    this.usePlaceDetailSearch,
    this.selectInitialPosition,
    this.language,
    this.forceSearchOnZoomChanged,
    this.hidePlaceDetailsWhenDraggingPin,
    this.borderRadius,
    this.enableMyLocation,
  }) : super(key: key);

  final LatLng initialTarget;

  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;
  final PinBuilder? pinBuilder;

  final ValueChanged<String>? onSearchFailed;
  final VoidCallback? onMoveStart;
  final MapCreatedCallback? onMapCreated;
  final VoidCallback? onToggleMapType;
  final VoidCallback? onMyLocation;
  final ValueChanged<PickResult>? onPlacePicked;

  final int? debounceMilliseconds;
  final bool? enableMapTypeButton;
  final bool? enableMyLocationButton;

  final bool? usePinPointingSearch;
  final bool? usePlaceDetailSearch;

  final bool? selectInitialPosition;

  final String? language;
  final bool? enableMyLocation;
  final bool? forceSearchOnZoomChanged;
  final bool? hidePlaceDetailsWhenDraggingPin;
  final BorderRadius? borderRadius;

  @override
  State<EmbeddedPlacePicker> createState() => _EmbeddedPlacePickerState();
}

class _EmbeddedPlacePickerState extends State<EmbeddedPlacePicker> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _buildGoogleMap(context),
        _buildPin(),
        // _buildFloatingCard(),
        _buildMapIcons(context),
      ],
    );
  }

  Widget _buildGoogleMap(BuildContext context) {
    PlaceProvider provider = PlaceProvider.of(context, listen: false);

    return _GoogleMap(
      enableMyLocation: widget.enableMyLocation,
      initialTarget: widget.initialTarget,
      provider: provider,
      borderRadius: widget.borderRadius,
      debounceMilliseconds: widget.debounceMilliseconds,
      enableMapTypeButton: widget.enableMapTypeButton,
      enableMyLocationButton: widget.enableMyLocationButton,
      forceSearchOnZoomChanged: widget.forceSearchOnZoomChanged,
      hidePlaceDetailsWhenDraggingPin: widget.hidePlaceDetailsWhenDraggingPin,
      language: widget.language,
      onMapCreated: widget.onMapCreated,
      onMoveStart: widget.onMoveStart,
      onMyLocation: widget.onMyLocation,
      onPlacePicked: widget.onPlacePicked,
      onSearchFailed: widget.onSearchFailed,
      onToggleMapType: widget.onMyLocation,
      pinBuilder: widget.pinBuilder,
      selectedPlaceWidgetBuilder: widget.selectedPlaceWidgetBuilder,
      selectInitialPosition: widget.selectInitialPosition,
      usePinPointingSearch: widget.usePinPointingSearch,
      usePlaceDetailSearch: widget.usePlaceDetailSearch,
    );
  }

  Widget _buildPin() {
    return Center(
      child: Selector<PlaceProvider, Tuple5>(
        // selector: (_, provider) => provider.pinState,
        selector: (_, provider) => Tuple5(
          provider.selectedPlace,
          provider.placeSearchingState,
          provider.isSearchBarFocused,
          provider.pinState,
          provider.isOnUpdateLocationCooldown,
        ),
        builder: (context, state, __) {
          if (widget.pinBuilder == null) {
            return _defaultPinBuilder(
                context, state.item4, state.item1, state.item2, state.item5);
          } else {
            return Builder(
                builder: (builderContext) =>
                    widget.pinBuilder!(builderContext, state.item4));
          }
        },
      ),
    );
  }

  Widget _defaultPinBuilder(
      BuildContext context,
      PinState state,
      PickResult? selectedPlace,
      SearchingState searchState,
      bool isOnUpdateLocationCooldown) {
    if (state == PinState.Preparing) {
      return Container();
    } else if (state == PinState.Idle) {
      return selectedPlace?.localityAddress != '' &&
              selectedPlace?.localityAddress != null
          ? Center(
              child: CustomPaint(
                painter: BubblePainter(color: Colors.black, radius: 20),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 15, left: 10, right: 10, bottom: 25),
                  child: Text(
                    selectedPlace?.localityAddress ?? '',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : const SizedBox();
    } else {
      return selectedPlace?.localityAddress != '' &&
              selectedPlace?.localityAddress != null
          ? Center(
              child: CustomPaint(
                painter: BubblePainter(color: Colors.black, radius: 20),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 15, left: 10, right: 10, bottom: 25),
                  child: searchState == SearchingState.Searching
                      ? Text(selectedPlace?.localityAddress ?? '',
                          style: TextStyle(color: Colors.white))
                      : SizedBox(
                          width: 100,
                          height: 24,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                ),
              ),
            )
          : const SizedBox();
    }
  }

  Widget _buildMapIcons(BuildContext context) {
    return Positioned(
      top: 40,
      right: 15,
      child: Column(
        children: <Widget>[
          widget.enableMapTypeButton!
              ? Container(
                  width: 35,
                  height: 35,
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    fillColor: Colors.black54,
                    elevation: 8.0,
                    onPressed: widget.onToggleMapType,
                    child: Icon(Icons.layers),
                  ),
                )
              : Container(),
          SizedBox(height: 10),
          // enableMyLocationButton!
          //     ? Container(
          //         width: 35,
          //         height: 35,
          //         child: RawMaterialButton(
          //           shape: CircleBorder(),
          //           fillColor: Colors.black54,
          //           elevation: 8.0,
          //           onPressed: onMyLocation,
          //           child: Icon(Icons.my_location),
          //         ),
          //       )
          //     : Container(),
        ],
      ),
    );
  }
}

class _GoogleMap extends StatefulWidget {
  const _GoogleMap({
    Key? key,
    this.onPlacePicked,
    required this.provider,
    this.enableMyLocationButton,
    required this.initialTarget,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.onSearchFailed,
    this.onMoveStart,
    this.onMapCreated,
    this.onToggleMapType,
    this.onMyLocation,
    this.debounceMilliseconds,
    this.enableMapTypeButton,
    this.usePinPointingSearch,
    this.usePlaceDetailSearch,
    this.selectInitialPosition,
    this.language,
    this.forceSearchOnZoomChanged,
    this.hidePlaceDetailsWhenDraggingPin,
    this.borderRadius,
    this.enableMyLocation,
  }) : super(key: key);

  final PlaceProvider provider;
  final LatLng initialTarget;

  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;
  final PinBuilder? pinBuilder;

  final ValueChanged<String>? onSearchFailed;
  final VoidCallback? onMoveStart;
  final MapCreatedCallback? onMapCreated;
  final VoidCallback? onToggleMapType;
  final VoidCallback? onMyLocation;
  final ValueChanged<PickResult>? onPlacePicked;

  final int? debounceMilliseconds;
  final bool? enableMapTypeButton;
  final bool? enableMyLocationButton;

  final bool? usePinPointingSearch;
  final bool? usePlaceDetailSearch;

  final bool? selectInitialPosition;
  final bool? enableMyLocation;

  final String? language;

  final bool? forceSearchOnZoomChanged;
  final bool? hidePlaceDetailsWhenDraggingPin;
  final BorderRadius? borderRadius;

  @override
  _GoogleMapState createState() => _GoogleMapState();
}

class _GoogleMapState extends State<_GoogleMap> {
  LatLng? _initialTarget;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.enableMyLocation ?? false) {
        _determinePosition();
      } else {
        _initialTarget = widget.initialTarget;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // bool _firstPosition = f
  Future<void> _determinePosition() async {
    // var status = await Permission.location.status;
    //
    // if (status.isDenied) {
    //   _initialTarget = widget.initialTarget;
    //   setState(() {});
    //   return;
    // }

    // status = await Permission.location.request();
    // print("Permission.location $status");
    // if (status.isDenied) {
    //   _initialTarget = widget.initialTarget;
    //   setState(() {});
    //   return;
    // }

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _initialTarget = widget.initialTarget;
      setState(() {});
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _initialTarget = widget.initialTarget;
        setState(() {});
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _initialTarget = widget.initialTarget;
      setState(() {});
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    final lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition != null) {
      _initialTarget = LatLng(lastPosition.latitude, lastPosition.longitude);
      setState(() {});
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.lowest);
    _initialTarget = LatLng(position.latitude, position.longitude);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    PlaceProvider provider = widget.provider;

    return Selector<PlaceProvider, MapType>(
      selector: (_, provider) => provider.mapType,
      builder: (_, data, __) {
        final initialTarget = _initialTarget;
        if (initialTarget == null) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }

        CameraPosition initialCameraPosition =
            CameraPosition(target: initialTarget, zoom: 15);

        return ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(0),
          child: GoogleMap(
            key: ValueKey<String>('GoogleMap'),
            myLocationButtonEnabled: true,
            compassEnabled: false,
            mapToolbarEnabled: false,
            initialCameraPosition: initialCameraPosition,
            mapType: data,
            myLocationEnabled: true,

            onMapCreated: (GoogleMapController controller) {
              provider.mapController = controller;
              // provider.setCameraPosition(null);
              provider.pinState = PinState.Idle;
              // When select initialPosition set to true.
              if (widget.selectInitialPosition ?? false) {
                provider.setCameraPosition(initialCameraPosition);
                _searchByCameraLocation();
              }
            },
            onCameraIdle: () {
              if (provider.isAutoCompleteSearching) {
                provider.isAutoCompleteSearching = false;
                provider.pinState = PinState.Idle;
                return;
              }

              // Perform search only if the setting is to true.
              if (widget.usePinPointingSearch ?? false) {
                // Search current camera location only if camera has moved (dragged) before.
                if (provider.pinState == PinState.Dragging) {
                  // Cancel previous timer.
                  if (provider.debounceTimer?.isActive ?? false) {
                    provider.debounceTimer!.cancel();
                  }
                  provider.debounceTimer = Timer(
                      Duration(milliseconds: widget.debounceMilliseconds!), () {
                    _searchByCameraLocation(onSearchComplete: () {
                      provider.pinState = PinState.Idle;
                    });
                  });
                } else {
                  provider.pinState = PinState.Idle;
                }
              } else {
                provider.pinState = PinState.Idle;
              }
            },
            onCameraMoveStarted: () {
              provider.setPrevCameraPosition(provider.cameraPosition);

              // Cancel any other timer.
              provider.debounceTimer?.cancel();

              // Update state, dismiss keyboard and clear text.
              provider.pinState = PinState.Dragging;

              // Begins the search state if the hide details is enabled
              if (this.widget.hidePlaceDetailsWhenDraggingPin ?? false) {
                provider.placeSearchingState = SearchingState.Searching;
              }

              widget.onMoveStart?.call();
            },
            onCameraMove: (CameraPosition position) {
              provider.setCameraPosition(position);
              provider.placeSearchingState = SearchingState.Idle;
            },
            // gestureRecognizers make it possible to navigate the map when it's a
            // child in a scroll view e.g ListView, SingleChildScrollView...
            gestureRecognizers: Set()
              ..add(Factory<EagerGestureRecognizer>(
                  () => EagerGestureRecognizer())),
          ),
        );
      },
    );
  }

  _searchByCameraLocation({Function()? onSearchComplete}) async {
    PlaceProvider provider = widget.provider;
    // We don't want to search location again if camera location is changed by zooming in/out.
    bool hasZoomChanged = provider.cameraPosition != null &&
        provider.prevCameraPosition != null &&
        provider.cameraPosition!.zoom != provider.prevCameraPosition!.zoom;

    if (widget.forceSearchOnZoomChanged == false && hasZoomChanged) {
      provider.placeSearchingState = SearchingState.Idle;
      onSearchComplete?.call();
      return;
    }

    // provider.placeSearchingState = SearchingState.Searching;

    final GeocodingResponse response =
        await provider.geocoding.searchByLocation(
      Location(
          lat: provider.cameraPosition!.target.latitude,
          lng: provider.cameraPosition!.target.longitude),
      language: widget.language,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      print("Camera Location Search Error: " + response.errorMessage!);
      if (widget.onSearchFailed != null) {
        widget.onSearchFailed!(response.status);
      }
      provider.placeSearchingState = SearchingState.Idle;
      onSearchComplete?.call();
      return;
    }

    PickResult result = PickResult.fromGeocodingResult(response.results[0]);

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
    // print(result.shortAddress);
    // print(city);
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
    }

    result.localityAddress = address;
    provider.selectedPlace = result;
    widget.onPlacePicked?.call(result);

    provider.placeSearchingState = SearchingState.Idle;
    onSearchComplete?.call();
  }
}
