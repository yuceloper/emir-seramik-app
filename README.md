# Emir Seramik

iPhone ve Android için Flutter ürün vitrini. Ürün grupları: seramik, fayans yapıştırıcısı, klozet ve lavabo. Fiyat, sepet ve uygulama içi satış yok; ürün detayından tek WhatsApp numarasına iletişim var.

## Durum

İlk ekran ve veri modeli hazır. İletişim numarası tanımlı. Uygulama Emir Seramik Supabase projesine bağlıdır; herkese açık vitrin yayımlanmış ürünleri ve katalogları sunucudan yükler, yönetici bölümünde ürün ve katalog ekleme/düzenleme ile fotoğraf yükleme bulunur. Sunucuda henüz yayımlanmış kayıt yoksa vitrin boş görünür. `assets/catalog.json` yalnızca kod geliştirmede kullanılan demo verisidir.

## Çalıştırma

Flutter SDK kurulu bir Mac üzerinde depo kökünde:

```sh
flutter create --platforms=android,ios --project-name=emir_seramik_app --org=com.emirseramik .
flutter pub get
flutter run
```

`flutter create` platform iskeletini üretir; `lib/main.dart`, `pubspec.yaml`, `assets/catalog.json` ve marka görseli bu repoda tutulur. Oluşan Android ve iOS klasörleri sonraki aşamada repoya eklenmelidir. Geliştirme ortamında Flutter SDK olmadığı için burada derleme yapılmadı.

## Ortak katalog ve yönetici kurulumu

1. Bir Supabase projesi oluşturun. SQL Editor'de `supabase/migrations/20260929_catalog.sql` dosyasını çalıştırın. Bu dosya tabloları, ürün fotoğrafları bucket'ını ve erişim kurallarını oluşturur.
   Önceden kurulmuş projede ürün açıklaması için `supabase/migrations/20260929_product_description.sql` dosyasını da SQL Editor'de çalıştırın. Bu adımı uygulamanın yeni sürümünü çalıştırmadan önce yapın; mevcut ürünlerin açıklaması boş kalır.
2. Supabase Authentication içinde kendi e-posta/şifre kullanıcınızı oluşturun. Kullanıcının UUID değerini alın. SQL Editor'de `insert into public.admin_users(user_id) values ('KULLANICI_UUID');` çalıştırın. Yalnızca bu tabloda bulunan hesaplar değişiklik yapabilir.
3. Proje URL'si ve **publishable** anahtarı `lib/data/catalog_data.dart` içinde tanımlıdır; normal `flutter run` bu projeye bağlanır. Başka bir projeyi denemek için derleme sırasında değiştirebilirsiniz. `service_role` / secret key değerini mobil uygulamaya asla koymayın:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://PROJE.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=PROJE_PUBLISHABLE_KEY
```

Yönetim simgesi üst sağdadır. Yönetici girişi yapın; yeni ürünler ve kataloglar başlangıçta taslaktır. Ürün formunda isteğe bağlı açıklama yazabilir, kamerayla anlık fotoğraf çekebilir veya galeriden seçebilirsiniz; fotoğrafı kaydetmeden önce önizleme gösterilir. Fotoğraflar en fazla 10 MB, JPG/PNG/WebP olabilir. Ürün veya katalog için **Yayında** seçeneğini açınca müşteriler görür. Ürün bir kataloğa eklenmek zorunda değildir. Yönetici hesabı oluşturma ve bu SQL adımları bir defalıktır; yönetici e-postası/şifresi GitHub'a yazılmaz.

iPhone için `flutter create` sonrasında `ios/Runner/Info.plist` dosyasındaki ana `<dict>` içine fotoğraf ve kamera erişimi açıklamalarını ekleyin:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Ürün fotoğraflarını kataloğa eklemek için fotoğraf arşivine erişim gerekir.</string>
<key>NSCameraUsageDescription</key>
<string>Ürün fotoğraflarını çekip kataloğa eklemek için kameraya erişim gerekir.</string>
```

Uygulama içindeki `assets/catalog.json` yalnızca geliştirme demosudur. Proje adresi ve publishable key sağlanmazsa bu yerel demo açılır. Demo ürünler canlı ortama otomatik eklenmez. İnternet/veri servisi hatasında boş veya eski katalog göstermek yerine yeniden deneme düğmeli hata ekranı gösterilir.

## Veri biçimi

`assets/catalog.json` içindeki `whatsappNumber`, ülke koduyla yalnızca rakam olmalı (örnek: `905xxxxxxxxx`). Boşken WhatsApp düğmesi devre dışıdır. Ürünlerin `id`, `name`, `brand`, `size`, `quality`, `category`, `imageUrl` alanları vardır; `description` isteğe bağlıdır. `category`: `ceramic`, `adhesive`, `toilet`, `sink`. `imageUrl` herkese açık HTTPS görseli olabilir. `catalogs` kayıtları `id`, `title`, `description`, `productIds` içerir. Ürünün bir katalogda yer alması zorunlu değildir.

## Sonraki iş

Supabase projesinin kurulması, yönetici hesabının açılması, fiyatsız gerçek ürün fotoğrafları ve bilgilerin doğrulanması. Uygulama mağazası dağıtımı ve yalnızca uygulamada açılan ürün bağlantısı ayrı aşamadır.

## Marka ve örnek içerik

Gönderilen kare Emir Seramik görseli ana vitrinde kullanılır. Bien 30×60 örneği kullanıcı fotoğrafındaki ürün yazısından alınmıştır; fotoğrafta fiyat bulunduğu için uygulamaya eklenmemiştir. Diğer üç kayıt yalnızca kategori akışını göstermek içindir. Fiyat bilgisi uygulamada gösterilmez.
