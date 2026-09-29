import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/catalog_data.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool busy = true;
  bool authorized = false;
  String? error;
  int tab = 0;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> catalogs = [];

  SupabaseClient get client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (BackendConfig.enabled) _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() { busy = true; error = null; });
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() { busy = false; authorized = false; });
        return;
      }
      final member = await client.from('admin_users').select('user_id')
          .eq('user_id', user.id).maybeSingle();
      if (member == null) {
        await client.auth.signOut();
        throw Exception('Bu hesap yönetici olarak tanımlanmamış.');
      }
      if (!mounted) return;
      setState(() => authorized = true);
      await _reload();
    } catch (e) {
      if (mounted) setState(() { busy = false; authorized = false; error = e.toString(); });
    }
  }

  Future<void> _reload() async {
    try {
      final productRows = await client.from('products')
          .select('id,name,brand,size,quality,description,category,image_path,published,sort_order')
          .order('sort_order');
      final catalogRows = await client.from('catalogs')
          .select('id,title,description,published,sort_order,catalog_products(product_id)')
          .order('sort_order');
      if (mounted) setState(() {
        products = productRows.map((row) => Map<String, dynamic>.from(row)).toList();
        catalogs = catalogRows.map((row) => Map<String, dynamic>.from(row)).toList();
        busy = false;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() { busy = false; error = e.toString(); });
    }
  }

  Future<void> _openProduct([Map<String, dynamic>? product]) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => ProductEditor(product: product),
    ));
    if (saved == true) await _reload();
  }

  Future<void> _openCatalog([Map<String, dynamic>? catalog]) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => CatalogEditor(catalog: catalog, products: products),
    ));
    if (saved == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (!BackendConfig.enabled) {
      return Scaffold(appBar: AppBar(title: const Text('Yönetim')), body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Yönetim için önce Supabase proje adresi ve publishable key tanımlanmalı. Kurulum adımları repodaki README dosyasında.')),
      ));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Yönetim'), actions: [
        if (authorized) IconButton(
          tooltip: 'Çıkış yap', icon: const Icon(Icons.logout),
          onPressed: () async { await client.auth.signOut(); if (mounted) setState(() => authorized = false); },
        ),
      ]),
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : !authorized
              ? AdminLogin(error: error, onSignedIn: _checkSession)
              : Column(children: [
                  Padding(padding: const EdgeInsets.all(16), child: SegmentedButton<int>(
                    segments: const [ButtonSegment(value: 0, label: Text('Ürünler')), ButtonSegment(value: 1, label: Text('Kataloglar'))],
                    selected: {tab}, onSelectionChanged: (selection) => setState(() => tab = selection.first),
                  )),
                  if (error != null) Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: const TextStyle(color: Colors.red))),
                  Expanded(child: RefreshIndicator(onRefresh: _reload, child: ListView(
                    children: tab == 0
                        ? products.map((item) => ListTile(
                            title: Text(item['name'] as String),
                            subtitle: Text('${ProductCategory.fromKey(item['category'] as String).label} · ${item['published'] == true ? 'Yayında' : 'Taslak'}'),
                            trailing: const Icon(Icons.chevron_right), onTap: () => _openProduct(item),
                          )).toList()
                        : catalogs.map((item) => ListTile(
                            title: Text(item['title'] as String),
                            subtitle: Text(item['published'] == true ? 'Yayında' : 'Taslak'),
                            trailing: const Icon(Icons.chevron_right), onTap: () => _openCatalog(item),
                          )).toList(),
                  ))),
                ]),
      floatingActionButton: authorized ? FloatingActionButton.extended(
        onPressed: () => tab == 0 ? _openProduct() : _openCatalog(),
        icon: const Icon(Icons.add), label: Text(tab == 0 ? 'Ürün ekle' : 'Katalog ekle'),
      ) : null,
    );
  }
}

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key, required this.onSignedIn, this.error});
  final VoidCallback onSignedIn;
  final String? error;

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? message;

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  Future<void> signIn() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => message = 'E-posta ve şifre girin.'); return;
    }
    setState(() { busy = true; message = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(), password: password.text,
      );
      widget.onSignedIn();
    } catch (_) {
      if (mounted) setState(() => message = 'Giriş başarısız. Bilgilerinizi kontrol edin.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
    const Text('Yalnızca Emir Seramik yöneticileri giriş yapabilir.', style: TextStyle(fontSize: 17)),
    const SizedBox(height: 24),
    TextField(controller: email, keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'E-posta', border: OutlineInputBorder())),
    const SizedBox(height: 14),
    TextField(controller: password, obscureText: true,
      decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder())),
    const SizedBox(height: 16),
    if (message != null || widget.error != null) Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(message ?? widget.error!, style: const TextStyle(color: Colors.red)),
    ),
    FilledButton(onPressed: busy ? null : signIn, child: const Text('Giriş yap')),
  ]);
}

class ProductEditor extends StatefulWidget {
  const ProductEditor({super.key, this.product});
  final Map<String, dynamic>? product;

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.product?['name'] as String? ?? '');
  late final brand = TextEditingController(text: widget.product?['brand'] as String? ?? '');
  late final size = TextEditingController(text: widget.product?['size'] as String? ?? '');
  late final quality = TextEditingController(text: widget.product?['quality'] as String? ?? '');
  late final description = TextEditingController(text: widget.product?['description'] as String? ?? '');
  late ProductCategory category = widget.product == null ? ProductCategory.ceramic
      : ProductCategory.fromKey(widget.product!['category'] as String);
  late bool published = widget.product?['published'] == true;
  XFile? chosenImage;
  Uint8List? imageBytes;
  bool busy = false;
  String? error;

  @override
  void dispose() { name.dispose(); brand.dispose(); size.dispose(); quality.dispose(); description.dispose(); super.dispose(); }

  Future<void> pickImage(ImageSource source) async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: source,
        imageQuality: 85, maxWidth: 2000, requestFullMetadata: false);
    } catch (_) {
      if (mounted) setState(() => error = source == ImageSource.camera
          ? 'Fotoğraf çekilemedi. Kamera erişimini kontrol edin.'
          : 'Fotoğraf seçilemedi. Fotoğraf erişimini kontrol edin.');
      return;
    }
    if (picked == null) return;
    final extension = picked.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      if (mounted) setState(() => error = 'JPG, PNG veya WebP görsel seçin.');
      return;
    }
    try {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 10 * 1024 * 1024) {
        setState(() => error = 'Görsel 10 MB altında olmalı.');
        return;
      }
      setState(() { chosenImage = picked; imageBytes = bytes; error = null; });
    } catch (_) {
      if (mounted) setState(() => error = 'Fotoğraf açılamadı. Tekrar deneyin.');
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    final client = Supabase.instance.client;
    try {
      final payload = {
        'name': name.text.trim(), 'brand': brand.text.trim(),
        'size': size.text.trim(), 'quality': quality.text.trim(),
        'description': description.text.trim(),
        'category': category.key, 'published': published,
      };
      String id;
      if (widget.product == null) {
        final row = await client.from('products').insert(payload).select('id').single();
        id = row['id'] as String;
      } else {
        id = widget.product!['id'] as String;
        await client.from('products').update(payload).eq('id', id);
      }
      if (chosenImage != null && imageBytes != null) {
        final extension = chosenImage!.name.split('.').last.toLowerCase();
        final mime = extension == 'png' ? 'image/png' : extension == 'webp' ? 'image/webp' : 'image/jpeg';
        final path = '$id/${DateTime.now().millisecondsSinceEpoch}.$extension';
        await client.storage.from('product-images').uploadBinary(path, imageBytes!,
          fileOptions: FileOptions(contentType: mime));
        await client.from('products').update({'image_path': path}).eq('id', id);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = 'Kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final oldPath = widget.product?['image_path'] as String?;
    final oldUrl = oldPath == null ? null : Supabase.instance.client.storage.from('product-images').getPublicUrl(oldPath);
    return Scaffold(appBar: AppBar(title: Text(widget.product == null ? 'Ürün ekle' : 'Ürünü düzenle')),
      body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
        if (imageBytes != null) Image.memory(imageBytes!, height: 220, fit: BoxFit.contain)
        else if (oldUrl != null) Image.network(oldUrl, height: 220, fit: BoxFit.contain),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          OutlinedButton.icon(
            onPressed: busy ? null : () => pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined), label: const Text('Fotoğraf çek'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : () => pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined), label: const Text('Galeriden seç'),
          ),
        ]),
        const SizedBox(height: 16),
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Ürün adı *'),
          validator: (value) => value == null || value.trim().isEmpty ? 'Ürün adı gerekli' : null),
        DropdownButtonFormField<ProductCategory>(value: category,
          decoration: const InputDecoration(labelText: 'Kategori'),
          items: ProductCategory.values.map((item) => DropdownMenuItem(value: item, child: Text(item.label))).toList(),
          onChanged: (value) { if (value != null) setState(() => category = value); }),
        TextFormField(controller: brand, decoration: const InputDecoration(labelText: 'Marka')),
        TextFormField(controller: size, decoration: const InputDecoration(labelText: 'Ebat')),
        TextFormField(controller: quality, decoration: const InputDecoration(labelText: 'Kalite')),
        TextFormField(controller: description, maxLines: 4,
          decoration: const InputDecoration(labelText: 'Açıklama (isteğe bağlı)', alignLabelWithHint: true)),
        const SizedBox(height: 14),
        SwitchListTile(title: const Text('Yayında'), subtitle: const Text('Açıldığında müşteriler bu ürünü görür.'),
          value: published, onChanged: (value) => setState(() => published = value)),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Kaydediliyor...' : 'Kaydet')),
      ])),
    );
  }
}

class CatalogEditor extends StatefulWidget {
  const CatalogEditor({super.key, this.catalog, required this.products});
  final Map<String, dynamic>? catalog;
  final List<Map<String, dynamic>> products;

  @override
  State<CatalogEditor> createState() => _CatalogEditorState();
}

class _CatalogEditorState extends State<CatalogEditor> {
  final formKey = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.catalog?['title'] as String? ?? '');
  late final description = TextEditingController(text: widget.catalog?['description'] as String? ?? '');
  late bool published = widget.catalog?['published'] == true;
  late final Set<String> selected = (widget.catalog?['catalog_products'] as List? ?? [])
      .map((link) => link['product_id'] as String).toSet();
  bool busy = false;
  String? error;

  @override
  void dispose() { title.dispose(); description.dispose(); super.dispose(); }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    final client = Supabase.instance.client;
    try {
      await client.rpc('save_emir_catalog', params: {
        'p_id': widget.catalog?['id'],
        'p_title': title.text.trim(),
        'p_description': description.text.trim(),
        'p_published': published,
        'p_product_ids': selected.toList(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = 'Kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.catalog == null ? 'Katalog ekle' : 'Kataloğu düzenle')),
    body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
      TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Katalog adı *'),
        validator: (value) => value == null || value.trim().isEmpty ? 'Katalog adı gerekli' : null),
      TextFormField(controller: description, decoration: const InputDecoration(labelText: 'Açıklama')),
      const SizedBox(height: 20),
      const Text('Katalogdaki ürünler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const Text('Ürünler hiçbir kataloğa eklenmeden de vitrinde yer alabilir.'),
      for (final product in widget.products) CheckboxListTile(
        title: Text(product['name'] as String),
        value: selected.contains(product['id']),
        onChanged: (value) => setState(() {
          if (value == true) { selected.add(product['id'] as String); }
          else { selected.remove(product['id']); }
        }),
      ),
      SwitchListTile(title: const Text('Yayında'), value: published,
        onChanged: (value) => setState(() => published = value)),
      if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 12),
      FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Kaydediliyor...' : 'Kaydet')),
    ])),
  );
}
