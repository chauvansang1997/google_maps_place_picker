import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_place_picker/google_maps_place_picker.dart';
import 'package:google_maps_place_picker/providers/place_provider.dart';
import 'package:google_maps_place_picker/providers/search_provider.dart';
import 'package:google_maps_place_picker/src/components/prediction_tile.dart';
import 'package:google_maps_place_picker/src/controllers/autocomplete_search_controller.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';

class SearchStyles {
  SearchStyles({
    this.enabledBorder,
    this.disabledBorder,
    this.focusedBorder,
    this.border,
    this.filled,
    this.hintText,
    this.hintStyle,
    this.fillColor,
    this.suffix,
    this.prefix,
    this.textStyle,
    this.isDense,
  });

  final InputBorder? enabledBorder;
  final InputBorder? disabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? border;
  final bool? filled;
  final bool? isDense;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final String? hintText;
  final Color? fillColor;
  final Widget? suffix;
  final Widget? prefix;
}

class EmbeddedAutoCompleteSearch extends StatefulWidget {
  const EmbeddedAutoCompleteSearch({
    Key? key,
    required this.sessionToken,
    required this.onPicked,
    this.searchingText = "Searching...",
    this.height = 40,
    this.contentPadding = EdgeInsets.zero,
    this.debounceMilliseconds,
    this.onSearchFailed,
    required this.searchBarController,
    this.autocompleteOffset,
    this.autocompleteRadius,
    this.autocompleteLanguage,
    this.autocompleteComponents,
    this.autocompleteTypes,
    this.strictbounds,
    this.region,
    this.initialSearchString,
    this.searchForInitialValue,
    this.autocompleteOnTrailingWhitespace,
    this.suggestionPadding = const EdgeInsets.fromLTRB(5, 5, 5, 5),
    this.backgroundColor,
    this.inputDecoration,
    this.iconClear,
  }) : super(key: key);

  final String? sessionToken;
  final String? searchingText;
  final double height;

  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry suggestionPadding;
  final int? debounceMilliseconds;
  final ValueChanged<Prediction> onPicked;
  final ValueChanged<String>? onSearchFailed;
  final EmbeddedSearchBarController searchBarController;
  final num? autocompleteOffset;
  final num? autocompleteRadius;
  final String? autocompleteLanguage;
  final List<String>? autocompleteTypes;
  final List<Component>? autocompleteComponents;
  final bool? strictbounds;
  final String? region;
  final String? initialSearchString;
  final bool? searchForInitialValue;
  final bool? autocompleteOnTrailingWhitespace;
  final Color? backgroundColor;
  final InputDecoration? inputDecoration;
  final Widget? iconClear;

  @override
  EmbeddedAutoCompleteSearchState createState() =>
      EmbeddedAutoCompleteSearchState();
}

class EmbeddedAutoCompleteSearchState
    extends State<EmbeddedAutoCompleteSearch> {
  TextEditingController _controller = TextEditingController();
  FocusNode _focus = FocusNode();
  OverlayEntry? _overlayEntry;
  SearchProvider _provider = SearchProvider();
  GlobalKey _searchKey = GlobalKey();

  Widget? _overlayChild;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchString != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.initialSearchString!;
        if (widget.searchForInitialValue!) {
          _onSearchInputChange();
        }
      });
    }
    _controller.addListener(_onSearchInputChange);
    _focus.addListener(_onFocusChanged);

    widget.searchBarController.attach(this);
  }

  @override
  void didUpdateWidget(covariant EmbeddedAutoCompleteSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_overlayEntry != null) {
      _displayOverlay();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchInputChange);
    _controller.dispose();
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _clearOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: SizedBox(
        key: _searchKey,
        height: widget.height,
        child: _buildSearchTextField(),
      ),
    );
  }

  Widget _buildSearchTextField() {
    final InputDecoration? inputDecoration = widget.inputDecoration;
    return TextFormField(
      controller: _controller,
      focusNode: _focus,
      // scrollPadding: EdgeInsets.only(bottom: 100),
      decoration: inputDecoration?.copyWith(
        hintText: inputDecoration.hintText,
        isDense: inputDecoration.isDense,
        contentPadding: inputDecoration.contentPadding ??
            EdgeInsets.only(left: 16, right: 16),
        // Border
        enabledBorder: inputDecoration.enabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
            ),
        disabledBorder: inputDecoration.disabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
            ),
        focusedBorder: inputDecoration.focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
            ),
        border: inputDecoration.border ??
            OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
            ),
        hintStyle: inputDecoration.hintStyle ??
            TextStyle(
              color: Theme.of(context).hintColor,
            ),
        fillColor: inputDecoration.fillColor ?? Theme.of(context).canvasColor,
        prefixIcon: inputDecoration.prefixIcon ?? Icon(Icons.search),
        suffixIcon: _buildTextClearIcon(),
      ),
    );
  }

  Widget _buildTextClearIcon() {
    return Selector<SearchProvider, String>(
        selector: (_, provider) => provider.searchTerm,
        builder: (_, data, __) {
          if (data.length > 0) {
            return GestureDetector(
              child: widget.inputDecoration?.suffixIcon ??
                  widget.inputDecoration?.suffix ??
                  Icon(
                    Icons.clear,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
              onTap: () {
                clearText();
              },
            );
          } else {
            return SizedBox(width: 10);
          }
        });
  }

  _onSearchInputChange() {
    if (!mounted) return;
    this._provider.searchTerm = _controller.text;

    PlaceProvider provider = PlaceProvider.of(context, listen: false);

    if (_controller.text.isEmpty) {
      provider.debounceTimer?.cancel();
      _searchPlace(_controller.text);
      return;
    }

    if (_controller.text.trim() == this._provider.prevSearchTerm.trim()) {
      provider.debounceTimer?.cancel();
      return;
    }

    if (!widget.autocompleteOnTrailingWhitespace! &&
        _controller.text.substring(_controller.text.length - 1) == " ") {
      provider.debounceTimer?.cancel();
      return;
    }

    if (provider.debounceTimer?.isActive ?? false) {
      provider.debounceTimer!.cancel();
    }

    provider.debounceTimer =
        Timer(Duration(milliseconds: widget.debounceMilliseconds!), () {
      _searchPlace(_controller.text.trim());
    });
  }

  _onFocusChanged() {
    PlaceProvider provider = PlaceProvider.of(context, listen: false);
    provider.isSearchBarFocused = _focus.hasFocus;
    if (!_focus.hasFocus) {
      _clearOverlay();
    }
    provider.debounceTimer?.cancel();
    provider.placeSearchingState = SearchingState.Idle;
  }

  _searchPlace(String searchTerm) {
    this._provider.prevSearchTerm = searchTerm;

    _clearOverlay();

    if (searchTerm.length < 1) return;
    _overlayChild = _buildSearchingOverlay();
    _displayOverlay();

    _performAutoCompleteSearch(searchTerm);
  }

  _clearOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  _displayOverlay() {
    _clearOverlay();

    final RenderBox? appBarRenderBox =
        _searchKey.currentContext!.findRenderObject() as RenderBox?;

    var offset = appBarRenderBox!.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + appBarRenderBox.size.height,
        left: offset.dx,
        width: appBarRenderBox.size.width,
        child: Padding(
          padding: widget.suggestionPadding,
          child: Material(
            elevation: 4.0,
            child: _overlayChild ?? const SizedBox(),
          ),
        ),
      ),
    );

    Overlay.of(context)!.insert(_overlayEntry!);
  }

  Widget _buildSearchingOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: <Widget>[
          SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Text(
              widget.searchingText ?? "Searching...",
              style: TextStyle(fontSize: 16),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPredictionOverlay(List<Prediction> predictions) {
    return ListBody(
      children: predictions
          .map(
            (p) => PredictionTile(
              prediction: p,
              onTap: (selectedPrediction) {
                resetSearchBar();
                widget.onPicked(selectedPrediction);
              },
            ),
          )
          .toList(),
    );
  }

  _performAutoCompleteSearch(String searchTerm) async {
    PlaceProvider provider = PlaceProvider.of(context, listen: false);

    if (searchTerm.isNotEmpty) {
      final PlacesAutocompleteResponse response =
          await provider.places.autocomplete(
        searchTerm,
        sessionToken: widget.sessionToken,
        location: provider.currentPosition == null
            ? null
            : Location(
                lat: provider.currentPosition!.latitude,
                lng: provider.currentPosition!.longitude),
        offset: widget.autocompleteOffset,
        radius: widget.autocompleteRadius,
        language: widget.autocompleteLanguage,
        types: widget.autocompleteTypes ?? const [],
        components: widget.autocompleteComponents ?? const [],
        strictbounds: widget.strictbounds ?? false,
        region: widget.region,
      );

      if (response.errorMessage?.isNotEmpty == true ||
          response.status == "REQUEST_DENIED") {
        if (widget.onSearchFailed != null) {
          widget.onSearchFailed!(response.status);
        }
        return;
      }
      _overlayChild = _buildPredictionOverlay(response.predictions);
      _displayOverlay();
    }
  }

  clearText() {
    _provider.searchTerm = "";
    _controller.clear();
  }

  resetSearchBar() {
    clearText();
    _clearOverlay();
    _focus.unfocus();
  }

  clearOverlay() {
    _clearOverlay();
  }
}
