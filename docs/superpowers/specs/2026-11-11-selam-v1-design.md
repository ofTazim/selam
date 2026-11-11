# Selam v1.0 — Tasarım Dokümanı

Tarih: 2026-11-11
Durum: Kullanıcı incelemesi bekliyor

## 1. Amaç

Selam, iki amaca hizmet eden bir iOS uygulamasıdır:

1. Namaz kaçırmamak.
2. Cemaatle namaza teşvik etmek; herkesin bir camisi/mescidi olması.

Ürün iki bağımsız aşamaya bölünmüştür. Bu doküman yalnızca **v1.0**'ı kapsar.

| Aşama | Kapsam | Sunucu |
|---|---|---|
| v1.0 (bu doküman) | Namaz vakitleri, hatırlatma, Canlı Etkinlik, cami seçimi, yürüme süresi, widget'lar, Apple Watch | Yok |
| v1.5 (ayrı spec) | Hesap, cami üyeliği, imam/müezzin rolleri, sohbet, paylaşım, yardım talepleri, etkinlikler, moderasyon | Var |

## 2. Kesinleşen kararlar

| Konu | Karar |
|---|---|
| Platform | iOS 26+, watchOS 26+. Native Swift / SwiftUI. |
| Sunucu | Yok. Tüm veri ve hesaplama cihazda. Hesap, giriş, analitik yok. |
| Canlı Etkinlik başlatma | Cihazda yerel zamanlama (iOS 26 zamanlanmış başlatma). Yedek plan: sunucudan push-to-start. |
| Tasarım yönü | "Gök": ekran arka planı gerçek güneş konumuna göre değişen gökyüzü. Saat ve widget'larda 24 saatlik halka. |
| Diller | Türkçe, İngilizce, Arapça, Endonezce, Urduca, Fransızca. Arapça ve Urduca sağdan sola. |
| Gelir | Ücretsiz, reklamsız. Gönüllü bağış (uygulama içi satın alma, üç sabit tutar). |
| Çalışma düzeni | Kod Windows'ta yazılır, Mac'te Xcode ile derlenir. Proje dosyası XcodeGen ile üretilir. |

## 3. Ekranlar

### 3.1 Bugün (ana ekran)

- Tam ekran gökyüzü: bulunulan konumdaki güneş yüksekliğine göre sürekli değişen renk geçişi. Beş ana durum: seher (lacivert), gündüz (mavi), ikindi (altın), akşam (kızıl), gece (koyu).
- Sonraki vaktin adı ve geri sayım, büyük tipografiyle.
- Güneş yayı: gün doğumundan batımına bir yay; vakitler yay üzerinde nokta, güneş anlık konumunda.
- Alt cam kart: ana caminin adı, yürüme süresi ve "X dk içinde çık". Cami seçilmemişse "Camini seç" çağrısı.
- Aşağı kaydırınca: günün tüm vakitleri (imsak, güneş, öğle, ikindi, akşam, yatsı), 7 günlük çizelge, hicri tarih.
- Okunabilirlik kuralı: metin her gökyüzü durumunda WCAG AA kontrastını sağlar; gerekirse metnin arkasına cam katman girer.

### 3.2 Camilerim

- Harita ve liste: konuma yakın camiler (Apple Haritalar araması).
- Kullanıcı en fazla 3 camiyi "cemaatim" olarak seçer; biri ana camidir.
- Haritada olmayan mescit, iğne bırakıp ad vererek elle eklenir.
- Her cami için: ad, mesafe, yürüme süresi, cemaat saati kaydırması (bkz. 4.4).
- Cami değiştirme sınırı v1.0'da yoktur (v1.5'te sunucuyla gelir).

### 3.3 Ayarlar

- Hesaplama: yöntem, Asr mezhebi (Şafii/Hanefi), yüksek enlem kuralı, vakit başına dakika düzeltmesi.
- Bildirimler: vakit başına aç/kapa; "ezandan önce", "çıkma zamanı", "vakit girdi", "vakit çıkıyor" türleri; ezan sesi aç/kapa.
- Canlı Etkinlik: aç/kapa, başlangıç süresi (varsayılan ezandan 30 dk önce).
- Dil, hicri tarih düzeltmesi (±2 gün), bağış, hakkında, gizlilik.

### 3.4 Karşılama

Dört adım: tanıtım, konum izni, bildirim izni, cami seçimi (atlanabilir). Hesaplama yöntemi ülkeye göre kendiliğinden seçilir ve kullanıcıya gösterilir. Konum izni verilmezse şehir elle seçilir.

## 4. Hatırlatma akışı

### 4.1 Canlı Etkinlik aşamaları

Her farz vakit için (sabah, öğle, ikindi, akşam, yatsı) kilit ekranında ve Dynamic Island'da:

| Aşama | Başlangıç | İçerik |
|---|---|---|
| Yaklaşıyor | Ezandan 30 dk önce (ayarlanabilir) | Ezana geri sayım; cami seçiliyse "X dk içinde çık" |
| Çıkma zamanı | Cemaat saati − yürüme süresi − 2 dk | "Şimdi çık", cami adı, yürüme süresi |
| Vakit girdi | Ezan | Vaktin çıkmasına kalan süre, ilerleme çubuğu |
| Son dakikalar | Vaktin çıkmasına 20 dk kala | Uyarı görünümü, son geri sayım |

- Cami seçilmemişse "Çıkma zamanı" aşaması atlanır.
- Geri sayım ve ilerleme çubuğu sistem zamanlayıcı görünümleriyle (güncelleme gerektirmeden) akar.
- Aşama geçişleri, her aşama için ayrı zamanlanmış başlatma ve önceki aşamanın bitiş tarihiyle sağlanır.

### 4.2 Kapanış

- Karttaki "Kıldım" düğmesi (uygulamayı açmadan çalışır) o vaktin Canlı Etkinlik'ini ve kalan bildirimlerini iptal eder.
- Vakit çıkınca kart kendiliğinden kapanır.
- Geçmiş tutulmaz; yalnızca "bugünün şu vakti susturuldu" bilgisi gün sonuna kadar saklanır.

### 4.3 Vakit pencereleri

| Vakit | Çıkış |
|---|---|
| Sabah | Güneş doğuşu |
| Öğle | İkindi |
| İkindi | Akşam |
| Akşam | Yatsı |
| Yatsı | Canlı Etkinlik için gece yarısı (akşam ile imsak arasının ortası); bildirim için aynı |

### 4.4 Cemaat saati

v1.0'da camilerin kamet saati bilinmez. Cemaat saati = ezan + kaydırma. Varsayılan kaydırma tüm vakitlerde 10 dk'dır (akşamda 5 dk); cami başına ve vakit başına ayarlanabilir. v1.5'te imam girer.

### 4.5 Bildirimler

- Yerel bildirimler. Varsayılan açık türler: "vakit girdi" ve "vakit çıkıyor" (çıkıştan 20 dk önce). İsteğe bağlı: "ezandan önce", "çıkma zamanı".
- iOS'un 64 bekleyen bildirim sınırı nedeniyle plan kayan penceredir: varsayılan ayarlarla 6 gün (günde 10 bildirim), tüm türler açıkken 3 gün.
- Plan şu durumlarda yenilenir: uygulama açılışı, arka plan yenilemesi, belirgin konum değişimi, saat dilimi değişimi, ayar değişimi.
- Pencerenin son günü için "Hatırlatmaların sürmesi için Selam'ı aç" bildirimi planlanır; plan yenilenince iptal edilir.

### 4.6 Bilinen sınırlar

1. Uygulama günlerce açılmaz ve iOS arka plan yenilemesi vermezse hatırlatmalar durur (4.5'teki uyarı bildirimi bunun içindir).
2. Zamanlanmış Canlı Etkinlik başlatma davranışı Apple dokümanından değil topluluk kaynaklarından doğrulanmıştır. İlk iş gerçek cihazda denenir (bkz. 9, adım 1).
   - Tutarsa: dört aşama.
   - Aşama geçişi tutmaz ama tek başlatma tutarsa: iki aşama (ezan öncesi, ezan sonrası).
   - Hiç tutmazsa: push-to-start için küçük bir sunucu eklenir; bu doküman güncellenir.

## 5. Widget'lar ve Apple Watch

- Ana ekran, küçük: sonraki vakit, geri sayım, mini halka.
- Ana ekran, orta: günün beş vakti, sonraki vurgulu.
- Kilit ekranı: yuvarlak (halka + kalan süre), dikdörtgen (sonraki vakit + saat + geri sayım), satır içi (ad + saat).
- Apple Watch uygulaması: sonraki vakit ve geri sayım (24 saatlik halka), günün vakitleri listesi, kadran bileşenleri. Vakitler saatte SelamCore ile hesaplanır; konum ve ayarlar telefondan eşitlenir.
- Takvim baskısı olursa Apple Watch v1.1'e kayar; diğer her şey v1.0'da kalır.

## 6. Mimari

Temel kural: hesaplama ve zamanlama mantığı arayüzden ayrıdır ve arayüz olmadan test edilir.

| Birim | Sorumluluk | Bağımlılık |
|---|---|---|
| `SelamCore` (Swift paketi) | Vakit hesabı, vakit pencereleri, Canlı Etkinlik aşama planı, "ne zaman çık" hesabı, bildirim planı, güneş yüksekliği → gökyüzü durumu, hicri tarih, ülke → yöntem eşlemesi | Adhan (Swift), Foundation |
| `Selam` (uygulama) | Ekranlar, karşılama, gökyüzü çizimi, konum, harita araması, yol süresi, bildirim ve Canlı Etkinlik zamanlamasının sisteme uygulanması, bağış | SelamCore |
| `SelamWidgets` (uzantı) | Widget'lar, Canlı Etkinlik görünümleri, "Kıldım" App Intent'i | SelamCore |
| `SelamWatch` (saat uygulaması) | Saat ekranları, kadran bileşenleri | SelamCore |

`SelamCore` saf fonksiyonlardan oluşur: girdi olarak konum, tarih, ayarlar ve camiyi alır; çıktı olarak vakitleri, aşama zaman çizelgesini ve bildirim listesini verir. Sistem API'lerine (bildirim, konum, ActivityKit) dokunmaz; bunlar uygulama katmanındaki ince bağdaştırıcılardadır.

### 6.1 Veri

- Depolama: App Group paylaşımlı alanı. Ayarlar ve camiler küçük bir JSON dosyası / UserDefaults; veritabanı yok.
- Modeller: `Settings` (yöntem, mezhep, düzeltmeler, bildirim tercihleri), `Mosque` (ad, koordinat, kaynak: harita/elle, cemaat kaydırmaları, yürüme süresi önbelleği, ana mı), `MutedPrayer` (tarih + vakit).
- Konum yalnızca cihazda kullanılır. Cihaz dışına çıkan tek veri Apple Haritalar araması ve yol tarifi istekleridir.

### 6.2 Dış kaynaklar

- Vakit hesabı: Adhan Swift kütüphanesi (MIT). Hesaplanan vakitler resmi takvimlerden 1-2 dk sapabilir; düzeltme ayarı ve lansman öncesi resmi takvim karşılaştırması bunun içindir.
- Camiler: MapKit yerel arama. Yürüme süresi: MapKit yol tarifi; sonuç cami başına önbelleğe alınır, konum 200 m'den fazla değişince yenilenir.
- Bağış: StoreKit 2, üç tüketilebilir ürün.

### 6.3 Hata durumları

| Durum | Davranış |
|---|---|
| Konum izni yok | Şehir elle seçilir; yürüme süresi ve yakın cami listesi kapalı |
| Bildirim izni yok | Uygulama çalışır; Bugün ekranında kalıcı ama kapatılabilir uyarı |
| Canlı Etkinlik kapalı | Yalnızca bildirimler |
| İnternet yok | Vakitler ve hatırlatmalar çalışır; cami araması ve yürüme süresi önbellekten |
| Yüksek enlem (yatsı/imsak hesaplanamıyor) | Seçili yüksek enlem kuralı uygulanır; varsayılan "gecenin ortası" |
| Saat dilimi / konum değişimi | Vakitler ve tüm planlar yeniden hesaplanır |

## 7. Yerelleştirme

- String Catalog ile 6 dil. Arayüzde sabit yön yok; tüm düzen leading/trailing ile kurulur.
- Vakit adları ve dini terimler her dilde o topluluğun kullandığı biçimde (ör. Fajr / İmsak-Sabah / Subuh). Çeviriler yayından önce ana dili konuşan biri tarafından gözden geçirilir (proje sahibinin sorumluluğu).
- Sayılar ve saatler cihaz yerel ayarına göre biçimlenir.

## 8. Test

| Katman | Nerede | Ne |
|---|---|---|
| `SelamCore` birim testleri | Windows (Swift araç zinciri kurulursa) ve Mac | Bilinen şehir/tarih için vakitler, vakit pencereleri, aşama zaman çizelgesi, çıkma zamanı, bildirim planı ve 64 sınırı, yüksek enlem, saat dilimi geçişi |
| Arayüz | Mac, Xcode önizleme ve simülatör | Beş gökyüzü durumu, küçük/büyük iPhone, Dynamic Type, sağdan sola, VoiceOver |
| Cihaz | Gerçek iPhone ve Apple Watch | Zamanlanmış Canlı Etkinlik, bildirimler, "Kıldım" düğmesi, widget yenilenmesi |
| Doğruluk | Elle | İstanbul, Mekke, Cakarta, Karaçi, Paris, Londra için resmi takvimle karşılaştırma |

Her uygulama adımı, Mac'te derlenip görülecek net bir kontrol listesiyle biter.

## 9. Yol haritası

1. **Deneme:** zamanlanmış Canlı Etkinlik başlatmayı ve aşama geçişini gerçek iPhone'da kanıtlayan küçük proje. Sonuç 4.6'daki dallardan birini seçer.
2. **Çekirdek:** `SelamCore` ve testleri.
3. **Uygulama:** Bugün ekranı ve gökyüzü; Camilerim; Ayarlar; karşılama.
4. **Uzantılar:** Canlı Etkinlik, widget'lar, Apple Watch.
5. **Yerelleştirme:** 6 dil, sağdan sola, çeviri incelemesi.
6. **Yayın hazırlığı:** Apple geliştirici hesabı, TestFlight, App Store sayfası ve ekran görüntüleri, gizlilik beyanı, inceleme.
7. **Tanıtım:** ayrı plan (arama optimizasyonu, öne çıkarılma başvurusu, tasarım ödülleri, topluluk yayılımı, ücretli reklam).

Hedef: Ramazan 2027 (şubat başı) öncesinde App Store'da olmak.

## 10. Kapsam dışı

Hesap ve giriş, sohbet, paylaşım, yardım talepleri, etkinlikler, imam/müezzin rolleri, cami değiştirme sınırı, namaz takibi ve seri, kıble, Kur'an, zikir, Android, iPad'e özel düzen, iOS 26 altı.
