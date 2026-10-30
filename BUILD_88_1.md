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

Yerel Godot 4.6.3 sözdizimi kontrolü ve 65 entegrasyon kontrolü başarılıdır
(0 hata). Godot 4.4.1 indirmesi `curl: (7) Failed to connect to proxy port 8080`
hatasıyla engellendi; 4.4.1 çalışma zamanı doğrulaması yapılamadı. Kullanılan
API'ler 4.4.1 hedefiyle tutuldu; 4.6.3 sonucu 4.4.1 doğrulaması sayılmaz.
