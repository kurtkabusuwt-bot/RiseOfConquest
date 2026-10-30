# Build #88 — komutan aktif yetenekleri

Bu belge Build #88'in tarihsel davranışını açıklar. Güncel aktif yetenek
kuralları ve test bilgileri için `BUILD_88_1.md` dosyasına bakın.

Savaş Sistemi 7.3, çift komutan bonusları, kuşatma, savaş deneyimi ve kayıt
biçimleri korunur. Ana sahne `war_build_88.gd` üzerinden 7.3'ü genişletir.

Komutanlar menüsünden savaş öncesi ana ve yardımcı komutanı seçin. Savaşta sağ
alttaki iki dokunmatik düğme, atanmış komutanın yeteneğini ve kalan süreyi gösterir.
Diğer kahramanlar pasif komutan bonuslarını korur; aktif yetenekleri henüz yoktur.

| Kahraman | Yetenek | Temel etki | Bekleme |
| --- | --- | --- | --- |
| Fatih Sultan Mehmet | Şahi Topu | Sura 85, en fazla üç düşmana 45 hasar | 18 sn |
| Halid bin Velid | Süvari Hücumu | En fazla üç düşmana 40 + yaşayan süvari başına 4 hasar (en fazla 10 süvari) | 14 sn |
| Hasan Sabbah | Gizli Hançer | Önce okçu/kuşatma hedefleyen tek düşmana 110 hasar | 16 sn |

Aktif beceri seviyesi başına güç %15 artar (0–5). Yardımcı komutanın yetenek gücü
%50'dir. Süreler bağımsızdır, ilk kullanım hazırdır ve yeni savaşta sıfırlanır.
Başarısız kullanım süre tüketmez. Aynı komutan iki kez kullanılamaz. Birlik hasarı
mevcut savaş motorundan geçer; kalkan ve kayıp sayımı korunur. Süvari Hücumu
anlık hasardır; geçici istatistik değişimi veya ayrı bir süvari animasyonu eklemez.

Test (yeni, geçici kullanıcı verisi dizini kullanın):

```sh
godot --headless --path . --check-only --script war_build_88.gd
XDG_DATA_HOME=/tmp/roc-build88-tests godot --headless --path . --script tests/test_build_88.gd
```

Entegrasyon testleri savaş başlangıcını, komutan bonuslarını, üç yeteneğin hasar ve
hedef seçimini, beceri gelişimini, bağımsız bekleme sürelerini, hatalı kullanımları,
ölüm/kayıp sayımını, deneyim ödüllerini ve sonraki savaşın sıfırlanmasını doğrular.
GitHub Actions yalnızca Godot 4.4.1 testlerini çalıştırır; bu branch için APK
derlemesi veya yayınlama tetiklenmez. Android cihazda dokunma ve görünüm kontrolü
APK aşamasında yapılmalıdır.
