# Emir Seramik

iPhone ve Android için Flutter ürün vitrini. Ürün grupları: seramik, fayans yapıştırıcısı, klozet ve lavabo. Fiyat, sepet ve uygulama içi satış yok; ürün detayından tek WhatsApp numarasına iletişim var.

## Durum

İlk ekran ve veri modeli hazır. Depo boş başladığı için henüz gerçek ürün, katalog ve WhatsApp numarası tanımlı değil. `assets/catalog.json` örnek içeriği uygulamaya paketlenir; bu dosya şu aşamada yalnızca arayüz akışını doğrulamak içindir. Herkese açık ve telefondan yönetilebilir katalog için sonraki aşamada ortak veri servisi, görsel depolama ve yönetici kimlik doğrulaması gerekir. Telefonun içine kaydedilen bir ürün diğer kullanıcıların cihazında görünmez.

## Çalıştırma

Flutter SDK kurulu bir Mac üzerinde depo kökünde:

```sh
flutter create --platforms=android,ios --project-name=emir_seramik_app --org=com.emirseramik .
flutter pub get
flutter run
```

`flutter create` platform iskeletini üretir; `lib/main.dart`, `pubspec.yaml` ve `assets/catalog.json` bu repoda tutulur. Oluşan Android ve iOS klasörleri sonraki aşamada repoya eklenmelidir. Geliştirme ortamında Flutter SDK olmadığı için burada derleme yapılmadı.

## Veri biçimi

`assets/catalog.json` içindeki `whatsappNumber`, ülke koduyla yalnızca rakam olmalı (örnek: `905xxxxxxxxx`). Boşken WhatsApp düğmesi devre dışıdır. Ürünlerin `id`, `name`, `brand`, `size`, `quality`, `category`, `imageUrl` alanları vardır. `category`: `ceramic`, `adhesive`, `toilet`, `sink`. `imageUrl` herkese açık HTTPS görseli olabilir. `catalogs` kayıtları `id`, `title`, `description`, `productIds` içerir. Ürünün bir katalogda yer alması zorunlu değildir.

## Sonraki iş

Ortak veri kaynağı ve yönetici girişi, telefonla ürün ekleme, fotoğrafın perspektif düzeltmesi ve görsel yükleme, gerçek ürünlerin girilmesi, WhatsApp numarasının tanımlanması. Uygulama mağazası dağıtımı ve yalnızca uygulamada açılan ürün bağlantısı da ayrı aşamadır.
