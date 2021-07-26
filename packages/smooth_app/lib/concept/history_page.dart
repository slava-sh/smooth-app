import 'package:flutter/material.dart';
import 'package:smooth_app/data_models/product_list.dart';
import 'package:smooth_app/pages/home_page.dart';
import 'package:smooth_app/pages/product/common/product_list_page.dart';

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_backup_restore),
            tooltip: 'Back to original Smoothie',
            onPressed: () => _openOriginalSmootie(context),
          ),
        ],
      ),
      body: ProductListPage(
        ProductList(
          listType: ProductList.LIST_TYPE_HISTORY,
          parameters: '',
        ),
        showAppBar: false,
        showActionButton: false,
      ),
    );
  }

  void _openOriginalSmootie(BuildContext context) {
    Navigator.push<Widget>(
      context,
      MaterialPageRoute<Widget>(
        builder: (BuildContext context) => const HomePage(),
      ),
    );
  }
}
