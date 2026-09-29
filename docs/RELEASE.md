# Emir Seramik mağaza yayını

## Bu repoda hazır olanlar

- Flutter vitrini ve Supabase yönetimi.
- Uygulama içindeki gizlilik bağlantısı ve herkese açık [gizlilik politikası](../PRIVACY.md).
- Ürün açıklaması, fotoğraf yükleme ve yönetimden dönüşte yenileme.

## Yayın derlemesinden önce

1. Mac'teki mevcut çalışan projede `git pull` yapın. `ios/` ve `android/` klasörlerini, yerel `Info.plist` izinleriyle birlikte repoya ekleyin. Flutter'ın ürettiği platform yapılandırmasını inceleyip uygulama kimliğini her iki platformda kesinleştirin. Mağazaya ilk yüklemeden sonra kimliği değiştirmek yeni uygulama oluşturmayı gerektirir.
2. Apple Developer Program ve Google Play Console hesaplarının durumunu kontrol edin. Her iki mağazada uygulama adı **Emir Seramik** ve yayıncı kimliği tutarlı olmalı.
3. Herkese açık vitrinde gerçek ürünleri ve en az bir anlamlı kataloğu yayınlayın; taslak kayıtlar görünmez. Uygulama ücretsiz, fiyat ve sepet yok; ürün iletişimi WhatsApp üzerinden.
4. Varsayılan Flutter simgesi yerine marka için uygun uygulama simgesini üretin ve iOS/Android'e yerleştirin. Gerçek uygulamadan iPhone ve Android mağaza ekran görüntüleri alın. Fotoğrafların ve markaların kullanım hakkını doğrulayın.
5. [Gizlilik politikasını](../PRIVACY.md) işletmenin gerçek veri uygulamalarıyla kontrol edin. App Store Connect ve Play Console gizlilik formlarını uygulamanın gerçek SDK ve backend davranışına göre doldurun. Mağazalar için gizlilik URL'si: `https://github.com/yuceloper/emir-seramik-app/blob/main/PRIVACY.md`.
   Destek URL'si: `https://github.com/yuceloper/emir-seramik-app/blob/main/SUPPORT.md`. Google Play mağaza kaydı için ayrıca bir destek e-posta adresi gerekir.
6. Android `targetSdk` değerinin Google Play'in güncel yeni uygulama gereğini karşıladığını ve iOS derlemesinin Apple'ın güncel Xcode/SDK gereğiyle yapıldığını doğrulayın.

## Mac üzerinde doğrulama ve çıktı

```sh
flutter pub get
flutter analyze
flutter test
flutter build ipa --release
flutter build appbundle --release
```

`flutter build ipa` için Apple imzalama/Team seçimi Xcode'da ayarlanmalı. `flutter build appbundle` için Android yükleme anahtarı ve release signing yapılandırılmalı; anahtar dosyaları ve şifreler git'e eklenmemeli. Çıktılar `build/ios/ipa/` ve `build/app/outputs/bundle/release/` altındadır. Üretilen IPA'yı App Store Connect/TestFlight'a, AAB'yi önce Play Console test kanalına yükleyin. Mağaza incelemesi ve nihai yayın için mağaza listelemeleri, ekran görüntüleri ve hesap doğrulamaları gerekir.

Google Play'deki yeni kişisel geliştirici hesapları için kapalı test ve üretim erişimi şartları uygulanabilir. Bu durum hesabın açılış tarihine bağlıdır.

## Mağaza açıklaması taslağı

**Kısa açıklama:** Emir Seramik ürünlerini ve kataloglarını keşfedin, ürünler için WhatsApp üzerinden bilgi alın.

**Açıklama:** Seramik, fayans yapıştırıcısı, klozet ve lavabo ürünlerini kategorilere göre inceleyin. Marka, ebat, kalite ve ürün açıklamalarını görüntüleyin. İlgilendiğiniz ürün hakkında Emir Seramik ile WhatsApp üzerinden iletişime geçin. Uygulamada fiyat, sepet veya ödeme bulunmaz.

Mağaza açıklamaları, ekran görüntüleri ve gizlilik beyanları gerçek yayın içeriğiyle son kez karşılaştırılmalıdır.
