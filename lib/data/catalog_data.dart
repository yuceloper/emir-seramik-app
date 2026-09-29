import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackendConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool get enabled => url.isNotEmpty && publishableKey.isNotEmpty;
}

enum ProductCategory {
  ceramic('ceramic', 'Seramik', Icons.grid_view_rounded),
  adhesive('adhesive', 'Fayans yapıştırıcısı', Icons.layers_rounded),
  toilet('toilet', 'Klozet', Icons.bathroom_rounded),
  sink('sink', 'Lavabo', Icons.water_drop_outlined);

  const ProductCategory(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;

  static ProductCategory fromKey(String key) =>
      ProductCategory.values.firstWhere((value) => value.key == key);
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.size,
    required this.quality,
    required this.category,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String brand;
  final String size;
  final String quality;
  final ProductCategory category;
  final String imageUrl;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String? ?? '',
        size: json['size'] as String? ?? '',
        quality: json['quality'] as String? ?? '',
        category: ProductCategory.fromKey(json['category'] as String),
        imageUrl: json['imageUrl'] as String? ?? '',
      );
}

class ProductCatalog {
  const ProductCatalog({
    required this.id,
    required this.title,
    required this.description,
    required this.productIds,
  });

  final String id;
  final String title;
  final String description;
  final List<String> productIds;

  factory ProductCatalog.fromJson(Map<String, dynamic> json) => ProductCatalog(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        productIds: List<String>.from(json['productIds'] as List? ?? []),
      );
}

class CatalogData {
  const CatalogData(this.whatsappNumber, this.products, this.catalogs);
  final String whatsappNumber;
  final List<Product> products;
  final List<ProductCatalog> catalogs;

  static Future<CatalogData> load() async {
    final raw = await rootBundle.loadString('assets/catalog.json');
    final local = jsonDecode(raw) as Map<String, dynamic>;
    final whatsappNumber = local['whatsappNumber'] as String? ?? '';
    if (!BackendConfig.enabled) {
      return CatalogData(
        whatsappNumber,
        (local['products'] as List? ?? [])
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList(),
        (local['catalogs'] as List? ?? [])
            .map((item) => ProductCatalog.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    }

    final client = Supabase.instance.client;
    final productRows = await client.from('products')
        .select('id,name,brand,size,quality,category,image_path')
        .eq('published', true).order('sort_order');
    final catalogRows = await client.from('catalogs')
        .select('id,title,description,catalog_products(product_id)')
        .eq('published', true).order('sort_order');
    final products = productRows.map((row) {
      final data = Map<String, dynamic>.from(row);
      final path = data['image_path'] as String?;
      data['imageUrl'] = path == null || path.isEmpty
          ? '' : client.storage.from('product-images').getPublicUrl(path);
      return Product.fromJson(data);
    }).toList();
    final catalogs = catalogRows.map((row) {
      final data = Map<String, dynamic>.from(row);
      final links = data['catalog_products'] as List? ?? [];
      data['productIds'] = links.map((link) => link['product_id'] as String).toList();
      return ProductCatalog.fromJson(data);
    }).toList();
    return CatalogData(whatsappNumber, products, catalogs);
  }
}
