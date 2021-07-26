import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:smooth_app/data_models/continuous_scan_model.dart';
import 'package:smooth_app/pages/product/product_page.dart';

class ProductLoaderPage extends StatelessWidget {
  const ProductLoaderPage(this._continuousScanModel, this._barcode);

  final ContinuousScanModel _continuousScanModel;
  final String _barcode;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product?>(
      future: _continuousScanModel.queryBarcode(_barcode),
      builder: (BuildContext context, AsyncSnapshot<Product?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final Product? product = snapshot.data;
          if (product != null) {
            return ProductPage(product: product);
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
