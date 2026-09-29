import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin/admin_page.dart';
import 'data/catalog_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (BackendConfig.enabled) {
    await Supabase.initialize(
      url: BackendConfig.url,
      anonKey: BackendConfig.publishableKey,
    );
  }
  runApp(const EmirSeramikApp());
}

const _ink = Color(0xFF1B1A19);
const _sage = Color(0xFF936D58);
const _paper = Color(0xFFF7F5F1);

class EmirSeramikApp extends StatefulWidget {
  const EmirSeramikApp({super.key});

  @override
  State<EmirSeramikApp> createState() => _EmirSeramikAppState();
}

class _EmirSeramikAppState extends State<EmirSeramikApp> {
  late Future<CatalogData> catalogFuture = CatalogData.load();
  void refresh() => setState(() => catalogFuture = CatalogData.load());

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Emir Seramik',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _sage, surface: _paper),
          scaffoldBackgroundColor: _paper,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: _paper,
            foregroundColor: _ink,
            centerTitle: false,
          ),
        ),
        home: FutureBuilder<CatalogData>(
          future: catalogFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Katalog şu anda açılamıyor.'),
                  const SizedBox(height: 12),
                  TextButton(onPressed: refresh, child: const Text('Tekrar dene')),
                ])),
              );
            }
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return Storefront(data: snapshot.data!, onRefresh: refresh);
          },
        ),
      );
}

class Storefront extends StatefulWidget {
  const Storefront({required this.data, required this.onRefresh, super.key});
  final CatalogData data;
  final VoidCallback onRefresh;

  @override
  State<Storefront> createState() => _StorefrontState();
}

class _StorefrontState extends State<Storefront> {
  int tab = 0;
  ProductCategory? category;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.data.products.where((product) {
      final matchesCategory = category == null || product.category == category;
      final search = query.trim().toLowerCase();
      final matchesSearch = search.isEmpty ||
          '${product.name} ${product.brand} ${product.size}'
              .toLowerCase()
              .contains(search);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EMİR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                letterSpacing: 4, height: 1)),
            Text('SERAMİK', style: TextStyle(fontSize: 10, letterSpacing: 5)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Yönetim',
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => const AdminPage(),
              ));
              if (mounted) widget.onRefresh();
            },
          ),
        ],
      ),
      body: tab == 0 ? _productsView(filtered) : _catalogsView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view), label: 'Ürünler'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book), label: 'Kataloglar'),
        ],
      ),
    );
  }

  Widget _productsView(List<Product> products) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset('assets/brand/emir_seramik.png',
                height: 190, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 26),
          const Text('Ürünleri keşfet', style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 5),
          const Text('Seramik ve yapı ürünleri',
              style: TextStyle(color: _sage)),
          const SizedBox(height: 22),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: 'Ürün veya marka ara',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip(null, 'Tümü'),
                for (final item in ProductCategory.values)
                  _categoryChip(item, item.label),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (products.isEmpty)
            _emptyCard(
              widget.data.products.isEmpty
                  ? 'Ürünler yakında burada görünecek.'
                  : 'Bu aramaya uygun ürün bulunamadı.',
              Icons.grid_view_rounded,
            )
          else
            for (final product in products) ...[
              _productCard(product),
              const SizedBox(height: 14),
            ],
        ],
      );

  Widget _categoryChip(ProductCategory? item, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: category == item,
          onSelected: (_) => setState(() => category = item),
          selectedColor: const Color(0xFFDDE5DD),
          side: BorderSide.none,
          backgroundColor: Colors.white,
        ),
      );

  Widget _productCard(Product product) => Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 0,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(
            builder: (_) => ProductDetails(product: product,
                whatsappNumber: widget.data.whatsappNumber),
          )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImage(product: product, height: 210),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.category.label.toUpperCase(), style: const TextStyle(
                        fontSize: 11, letterSpacing: 1.5, color: _sage,
                        fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(product.name, style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text([product.brand, product.size]
                        .where((part) => part.isNotEmpty).join(' · '),
                        style: const TextStyle(color: _sage)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _catalogsView() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const Text('Kataloglar', style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('Ürün seçkileri', style: TextStyle(color: _sage)),
          const SizedBox(height: 26),
          if (widget.data.catalogs.isEmpty)
            _emptyCard('Kataloglar yakında burada görünecek.',
                Icons.menu_book_outlined),
          for (final catalog in widget.data.catalogs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                color: Colors.white,
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE7ECE7),
                      child: Icon(Icons.menu_book_outlined, color: _sage)),
                  title: Text(catalog.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(catalog.description.isEmpty
                      ? '${catalog.productIds.length} ürün'
                      : catalog.description),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    final items = widget.data.products.where((product) =>
                        catalog.productIds.contains(product.id)).toList();
                    Navigator.push(context, MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(catalog.title)),
                        body: items.isEmpty
                            ? Center(child: _emptyCard('Bu katalogda henüz ürün yok.',
                                Icons.grid_view_rounded))
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: items.length,
                                itemBuilder: (_, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _productCard(items[index]),
                                ),
                              ),
                      ),
                    ));
                  },
                ),
              ),
            ),
        ],
      );

  Widget _emptyCard(String message, IconData icon) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 46),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(icon, size: 42, color: _sage),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: _sage, fontSize: 16)),
          ],
        ),
      );
}

class ProductImage extends StatelessWidget {
  const ProductImage({required this.product, required this.height, super.key});
  final Product product;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFE9EAE6),
      child: Icon(product.category.icon, size: 52,
          color: _sage.withValues(alpha: 0.6)),
    );
    if (!product.imageUrl.startsWith('https://')) return placeholder;
    return Image.network(product.imageUrl, height: height,
        width: double.infinity, fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => placeholder);
  }
}

class ProductDetails extends StatelessWidget {
  const ProductDetails({required this.product,
      required this.whatsappNumber, super.key});
  final Product product;
  final String whatsappNumber;

  Future<void> _contact(BuildContext context) async {
    final message = 'Merhaba, Emir Seramik uygulamasındaki ${product.name} hakkında bilgi almak istiyorum.';
    final uri = Uri.https('wa.me', '/$whatsappNumber', {'text': message});
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // A missing browser or WhatsApp handler is shown as a readable error.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('WhatsApp bağlantısı açılamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ürün detayı')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(18),
                child: ProductImage(product: product, height: 350)),
            const SizedBox(height: 25),
            Text(product.category.label.toUpperCase(), style: const TextStyle(
                color: _sage, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(product.name, style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w700)),
            const SizedBox(height: 25),
            if (product.brand.isNotEmpty) _infoRow('Marka', product.brand),
            if (product.size.isNotEmpty) _infoRow('Ebat', product.size),
            if (product.quality.isNotEmpty) _infoRow('Kalite', product.quality),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(20),
          child: FilledButton.icon(
            onPressed: RegExp(r'^\d{10,15}$').hasMatch(whatsappNumber)
                ? () => _contact(context) : null,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('WhatsApp ile iletişime geç'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          ),
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          SizedBox(width: 90, child: Text(label,
              style: const TextStyle(color: _sage))),
          Expanded(child: Text(value, style: const TextStyle(
              fontWeight: FontWeight.w600))),
        ]),
      );
}
