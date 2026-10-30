# Build #88.1

Build #88, yerel `546a882` commit'inde korunur. Başlangıç çalışma alanındaki
satır sonu farkları da `2f3b3c2` commit'inde güvenceye alınmıştır.

| Aktif yetenek | Etki | Süre | Bekleme |
| --- | --- | --- | --- |
| Fatih Sultan Mehmet — Şahi Topu | Kuşatma birliklerinin saldırılarına ve sura verilen hasara +%30 | 8 sn | 45 sn |
| Halid bin Velid — Süvari Hücumu | Süvari saldırılarına +%25 | 6 sn | 40 sn |
| Hasan Sabbah — Gizli Hançer | Etkinleştirme anında yaşayan her suikastçının sonraki gerçek vuruşuna +%35 | Vuruş gerçekleşene kadar | 50 sn |

Aktif oranlar iki komutan yuvasında da aynıdır; eski aktif yeteneklerin anlık
hasarı, beceri seviyesi çarpanı ve yardımcı komutanın aktif %50 kuralı kaldırılmıştır.
7.3'ün pasif komutan bonusları, yardımcı katkısı, kahraman gelişimi, savaş XP'si,
kuşatma, kayıplar ve kayıt biçimleri korunur.

Bekleme süresi etkinleştirmede başlar. Süreli etki ve bekleme süresi birlikte
gösterilir. Hasan için bekleyen birlik sayısı gösterilir; ölen birliklerin hakkı
kaldırılır. Bekleyen ilk vuruşlar yeniden etkinleştirerek biriktirilemez. Hasan
yaşayan suikastçı yoksa etkinleşmez ve bekleme harcamaz. Süreli etkiler, uygun
birliğin sonraki saldırıları için hazırlanabilir. Bütün etkiler savaş bitişinde
temizlenir ve yeni savaşta yeniden hazır olur.

Hasar yalnızca gerçek saldırı menzili, yaşayan hedef ve saldırı zamanlayıcısı
kontrollerinden sonra değiştirilir. Birlik temel hasarı değiştirilmez.
Kalkan, kritik, formasyon, emir ve süvari hücumu hesapları eski motor üzerinden
devam eder. Merminin bonusu atış anında belirlenir, çarpmada yeniden uygulanmaz.
Kuşatma birliğinin sura giden paralel hasar kolu, birlik bonusu uygulanmadan
ayrılır; sur bonusu `Siege.damage` içinde yalnızca bir kez hesaplanır. Periyodik
7.3 kuşatma saldırısı da aynı sur hasarı girişini kullanır.

Ana ve yardımcı yeteneklerin süreleri ve ilk vuruş hakları bağımsızdır.
Komutan seçimi savaş başlangıcında sabitlenir; aynı kahraman iki kez atanamaz.
Geçici yetenek durumu kalıcı kayıt dosyalarına yazılmaz.

Linux/Bash üzerinde Godot 4.4.1 ile doğrulama:

```sh
godot --version
godot --headless --path . --check-only --script war_build_88.gd
ROC881_TEST_DATA=$(mktemp -d)
XDG_DATA_HOME="$ROC881_TEST_DATA" godot --headless --path . --script tests/test_build_88.gd
```

Testler geçici kullanıcı verisiyle çalıştırılmalıdır; test senaryoları kendi
savaş ve kahraman kayıtlarını oluşturur. Test dosyasının yolu Build #88 ile
aynı tutulmuştur. GitHub Actions Godot 4.4.1'i kullanır; APK oluşturmaz.

Yerel Godot 4.6.3 sözdizimi kontrolü ve 128 entegrasyon kontrolü başarılıdır
(0 hata). Godot 4.4.1 indirmesi `curl: (7) Failed to connect to proxy port 8080`
hatasıyla engellendi; 4.4.1 çalışma zamanı doğrulaması yapılamadı. Kullanılan
API'ler 4.4.1 hedefiyle tutuldu; 4.6.3 sonucu 4.4.1 doğrulaması sayılmaz.

## Android aktif yetenek arayüzü düzeltmesi

`war_build_88.gd`, aktif yetenek arayüzünü komutan seçim panelinden bağımsız
`BattleAbilitiesHUD` CanvasLayer'ında oluşturur. Katman 120'dir; mevcut savaş
(40), krallık (45), komutan (65), kahraman (80) ve şehir etkileşimi (100)
katmanlarının üzerindedir. Tam ekran kök Control dokunmayı engellemez; panel
ve düğmeler kendi alanlarında girdiyi yakalar. Başka bir panel açık olsa da
savaş yetenekleri üstte kalır; düğme tıklaması alttaki oyuna geçmez.

Kurulum tekrar çağrıldığında ikinci bir arayüz veya komutan paneli oluşturmaz.
Savaş başlarken veya savaş sırasında arayüz eksik, silinmiş veya yarım kalmışsa
yeniden oluşturulur. Bu işlem yeteneklerin aktif sürelerini, beklemelerini veya
Hasan Sabbah'ın ilk vuruş haklarını sıfırlamaz. Savaş bitince arayüz gizlenir.

Yerleşim sabit alt/sağ anchor offsetlerine dayanmaz. Android güvenli ekran
alanı fiziksel ekran koordinatlarından viewport'un ters ekran dönüşümüyle
mantıksal koordinatlara çevrilir ve görünür alanla kesiştirilir. Panel güvenli
alanın sağ altına, kenar boşluğu bırakılarak yerleştirilir. Alan daraldığında
panel orantılı küçülür. Yeniden boyutlandırma ve güvenli alan değişiklikleri
takip edilir. Düğmeler normal ölçekte 64 mantıksal birim yüksekliğindedir.

Eksik arayüz yeniden kurulurken uyarı, sahne ağacı dışında kurulmaya
çalışıldığında hata üretilir. Debug derlemede kurulumda kullanılan katman da
yazdırılır. Kurtarma testlerinde kasıtlı silme nedeniyle görülen iki yeniden
kurulum uyarısı beklenen davranıştır.

Mevcut 65 hasar/XP/kayıt kontrolüne 63 arayüz kontrolü eklenmiştir. Testler:

- 1280×720, 2400×1080, 800×360, 360×640 ve 320×180 viewport boyutları;
- güvenli alan sınırları, panel ve düğme dikdörtgenleri, hazır düğmelerin
  görünürlüğü/etkinliği ve test edilen boyutlarda en az 44 birim dokunma yüksekliği;
- fiziksel güvenli alanın ölçek ve ekran konumu üzerinden dönüşümü;
- tekrarlanan kurulum ve tam/kısmi arayüz silinmesinden kurtarma;
- yeniden kurulumda aktif yetenek durumunun korunması;
- katman 100'de girdiyi yakalayan başka bir panel varken gerçek viewport
  GUI tıklamasının yardımcı komutanın yeteneğine ulaşması;
- `InputEventScreenTouch` olayının fare emülasyonuyla ana komutan yeteneğini
  etkinleştirmesi ve savaş sonunda panelin gizlenmesi.

Bu kontroller headless Godot 4.6.3 üzerinde çalıştırıldı. Android cihazda
görsel doğrulama yerine geçmez; güncellenmiş APK üzerinde Fatih ana/Halid
yardımcı seçimiyle, çentik/gezinti alanı ve ekran boyutu kontrolü tekrar
yapılmalıdır. Bu düzeltmede APK oluşturulmadı. Hasar motoru, aktif yetenek
oranları, savaş gelişimi ve kayıt dosyaları değiştirilmedi.