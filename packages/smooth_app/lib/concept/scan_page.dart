import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smooth_app/concept/product_page.dart';
import 'package:smooth_app/data_models/continuous_scan_model.dart';
import 'package:smooth_app/database/dao_product.dart';
import 'package:smooth_ui_library/animations/smooth_reveal_animation.dart';
import 'package:smooth_ui_library/widgets/smooth_view_finder.dart';
import 'package:smooth_app/database/local_database.dart';
import 'package:smooth_app/database/product_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:openfoodfacts/model/Product.dart';
import 'package:smooth_app/pages/choose_page.dart';
import 'package:smooth_app/pages/product/product_page.dart';
import 'package:smooth_ui_library/widgets/smooth_product_image.dart';

// TODO(slava-sh): Merge ScanPage and ContinuousScanPage classes.
class ScanPage extends StatefulWidget {
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late ContinuousScanModel _continuousScanModel;
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    final LocalDatabase localDatabase = context.watch<LocalDatabase>();
    return FutureBuilder<ContinuousScanModel?>(
      future: ContinuousScanModel(
        contributionMode: false,
        languageCode: ProductQuery.getCurrentLanguageCode(context),
        countryCode: ProductQuery.getCurrentCountryCode(),
        scanCallback: (String barcode) => _onScan(context, barcode),
      ).load(localDatabase),
      builder:
          (BuildContext context, AsyncSnapshot<ContinuousScanModel?> snapshot) {
        if (_isActive && snapshot.connectionState == ConnectionState.done) {
          final ContinuousScanModel? continuousScanModel = snapshot.data;
          if (continuousScanModel != null) {
            _continuousScanModel = continuousScanModel;
            return ContinuousScanPage(continuousScanModel);
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _onScan(BuildContext context, String barcode) {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    debugPrint('Scanned barcode $barcode');
    Navigator.push<Widget>(
      context,
      MaterialPageRoute<Widget>(
        builder: (BuildContext context) =>
            ProductLoaderPage(_continuousScanModel, barcode),
      ),
    ).then((_) => setState(() {
          _isActive = true;
        }));
  }
}

class ContinuousScanPage extends StatelessWidget {
  ContinuousScanPage(this._continuousScanModel);

  final ContinuousScanModel _continuousScanModel;
  final PanelController _searchPanelController = PanelController();

  final GlobalKey _scannerViewKey = GlobalKey(debugLabel: 'Barcode Scanner');

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final ThemeData themeData = Theme.of(context);
    return ChangeNotifierProvider<ContinuousScanModel>.value(
      value: _continuousScanModel,
      child: Consumer<ContinuousScanModel>(
        builder:
            (BuildContext context, ContinuousScanModel dummy, Widget? child) =>
                _buildPage(context, appLocalizations, screenSize, themeData),
      ),
    );
  }

  Widget _buildPage(BuildContext context, AppLocalizations appLocalizations,
      Size screenSize, ThemeData themeData) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: <Widget>[
          SmoothRevealAnimation(
            delay: 400,
            startOffset: Offset.zero,
            animationCurve: Curves.easeInOutBack,
            child: false
                ? Container(color: Colors.blue)
                : QRView(
                    key: _scannerViewKey,
                    onQRViewCreated: (QRViewController controller) =>
                        _continuousScanModel.setupScanner(controller),
                  ),
          ),
          SmoothRevealAnimation(
            delay: 400,
            startOffset: const Offset(0.0, 0.1),
            animationCurve: Curves.easeInOutBack,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: SmoothViewFinder(
                    width: screenSize.width * 0.8,
                    height: screenSize.width * 0.4,
                    animationDuration: 1500,
                  ),
                )
              ],
            ),
          ),
          _buildSearchPanel(context),
        ],
      ),
    );
  }

  SlidingUpPanel _buildSearchPanel(BuildContext context) {
    final LocalDatabase localDatabase = context.watch<LocalDatabase>();
    final DaoProduct daoProduct = DaoProduct(localDatabase);
    return SlidingUpPanel(
      controller: _searchPanelController,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      panel: Column(
        children: <Widget>[
          TextSearchWidget(
            daoProduct: daoProduct,
            onFocus: _searchPanelController.open,
          ),
        ],
      ),
      maxHeight: 300, // TODO(slava-sh): Make this relative to screen size?
    );
  }
}

/// Local product search by text
class TextSearchWidget extends StatefulWidget {
  const TextSearchWidget({
    this.color,
    required this.daoProduct,
    this.addProductCallback,
    this.onFocus,
  });

  /// Icon color
  final Color? color;
  final DaoProduct daoProduct;
  final void Function()? onFocus;

  /// Callback after a product page is reached from the search, then pop'ed
  final Future<void> Function(Product product)? addProductCallback;

  @override
  State<TextSearchWidget> createState() => _TextSearchWidgetState();
}

class _TextSearchWidgetState extends State<TextSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _visibleCloseButton = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        debugPrint('focus on search');
        widget.onFocus?.call();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return TypeAheadField<Product?>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: _searchController,
        focusNode: _focusNode,
        autofocus: false,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(20.0),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: _getIcon(Icons.search),
          ),
          suffixIcon: _getInvisibleIconButton(
            Icons.close,
            () => setState(
              () {
                FocusScope.of(context).unfocus();
                _searchController.text = '';
                _visibleCloseButton = false;
              },
            ),
          ),
          border: InputBorder.none,
          hintText: appLocalizations.what_are_you_looking_for,
          hintStyle: Theme.of(context)
              .textTheme
              .subtitle1!
              .copyWith(fontWeight: FontWeight.w300),
        ),
      ),
      hideOnEmpty: true,
      hideOnLoading: true,
      suggestionsCallback: (String value) async => _search(value),
      transitionBuilder: (BuildContext context, Widget suggestionsBox,
              AnimationController? controller) =>
          suggestionsBox,
      itemBuilder: (BuildContext context, Product? suggestion) {
        if (suggestion == null) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Click here for server search'),
              onPressed: () => ChoosePage.onSubmitted(
                _searchController.text,
                this.context, // careful, here use the "main" context and not the transient item context
                widget.daoProduct.localDatabase,
              ),
            ),
          );
        }
        return ListTile(
          leading: SmoothProductImage(
            product: suggestion,
            width: screenSize.height / 10,
            height: screenSize.height / 10,
          ),
          title: Text(
            suggestion.productName ?? suggestion.barcode ?? 'Unknown',
          ),
          subtitle: Text('(local result) (${suggestion.barcode})'),
        );
      },
      onSuggestionSelected: (Product? suggestion) async {
        await Navigator.push<Widget>(
          context,
          MaterialPageRoute<Widget>(
            builder: (BuildContext context) => ProductPage(
              product: suggestion!,
            ),
          ),
        );
        widget.addProductCallback?.call(suggestion!);
      },
    );
  }

  Widget _getInvisibleIconButton(
    final IconData iconData,
    final void Function() onPressed,
  ) =>
      AnimatedOpacity(
        opacity: _visibleCloseButton ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 100),
        child: IgnorePointer(
          ignoring: !_visibleCloseButton,
          child: IconButton(icon: _getIcon(iconData), onPressed: onPressed),
        ),
      );

  Icon _getIcon(final IconData iconData) => Icon(iconData, color: widget.color);

  Future<List<Product?>> _search(String pattern) async {
    const int _MINIMUM_TEXT_SIZE = 3;
    final bool _oldVisibleCloseButton = _visibleCloseButton;
    _visibleCloseButton = pattern.isNotEmpty;
    if (_oldVisibleCloseButton != _visibleCloseButton) {
      setState(() {});
    }
    final List<Product?> result = <Product?>[];
    if (pattern.length < _MINIMUM_TEXT_SIZE) {
      return result;
    }
    result.add(null);
    result.addAll(
      await widget.daoProduct.getSuggestions(pattern, _MINIMUM_TEXT_SIZE),
    );
    return result;
  }
}
