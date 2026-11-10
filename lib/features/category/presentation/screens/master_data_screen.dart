import 'package:flutter/material.dart';
import '../../../addon/presentation/screens/addon_tab_view.dart';
import '../../../product/presentation/screens/product_tab_view.dart';
import 'category_tab_view.dart';

/// Layar Master Data dengan TabBar 3 tab: Kategori, Produk, dan Add-on.
class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Kategori'),
              Tab(text: 'Produk'),
              Tab(text: 'Add-on'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                CategoryTabView(),
                ProductTabView(),
                AddonTabView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
