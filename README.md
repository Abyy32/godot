# Shinobi Arena 2D

Prototipe game pertarungan 2D side-scrolling yang kini ditargetkan ke **Godot 3.6 stable**. Pemain memilih petarung dan arena, lalu bertarung melawan lawan AI. UI, arena, dan beberapa efek digambar secara prosedural; karakter menggunakan atlas sprite PNG.

> **Status:** port dari Godot 4 ke Godot 3.6 telah diterapkan pada berkas proyek dan skrip, tetapi belum dijalankan di Godot 3.6 maupun diekspor. Karena itu, kompatibilitas runtime dan Web belum terverifikasi. Proyek tetap prototipe, bukan rilis komersial.

## Struktur proyek

```text
.
├── project.godot                 # Konfigurasi Godot 3, scene awal, autoload
├── export_presets.cfg            # Preset HTML5, Windows Desktop, Android
├── scenes/
│   ├── main.tscn                 # Scene utama
│   └── arenas/                   # Tiga scene arena
├── scripts/
│   ├── main.gd                   # Menu dan alur pertandingan
│   ├── game_session.gd           # Data game, input, pengaturan, progres
│   ├── fighter.gd                # Gerak, animasi, dan pertarungan petarung
│   ├── enemy.gd                  # AI lawan
│   ├── arena_stage.gd             # Latar dan collision arena
│   ├── arena_preview.gd           # Pratinjau arena
│   ├── hud.gd                     # HUD serta kontrol sentuh
│   ├── projectile.gd              # Proyektil Energy Bolt
│   └── combat/                    # Hitbox dan hurtbox
├── assets/sprites/                # Atlas sprite karakter
├── docs/ROADMAP.md
└── .github/workflows/             # Validasi dan ekspor otomatis
```

## Membuka proyek

Gunakan editor **Godot 3.6 stable** dan buka `project.godot`. Proyek memakai renderer **GLES2**, yang menargetkan WebGL 1.0 untuk cakupan browser luas. Scene awal adalah `res://scenes/main.tscn`, viewport 1280×720.

Jangan membuka dan menyimpan proyek ini dengan Godot 4 jika ingin mempertahankan format Godot 3. Berkas `.tscn` memakai format 2; skrip menggunakan API Godot 3 seperti `KinematicBody2D`, `AnimatedSprite`, `File`, `PoolVector2Array`, `instance()`, dan koneksi sinyal berbasis nama metode.

## Ekspor dan penerapan ke Web

Godot 3 mengekspor proyek browser sebagai **HTML5**. Ekspor menghasilkan satu set berkas—halaman HTML, JavaScript, WebAssembly, dan data game—yang harus tetap berada bersama saat diunggah ke host.

### Melalui Godot Editor

1. Pasang **Godot 3.6 stable** dan export templates yang cocok dengan versi 3.6.
2. Buka proyek, lalu pilih **Project → Export**.
3. Pilih preset **HTML5** yang sudah ada. Jika preset tidak muncul, tambahkan preset HTML5 dan atur export type ke **Regular**.
4. Ekspor ke `build/web/index.html` atau direktori lain yang dipilih.
5. Unggah **semua berkas hasil ekspor** ke host Web, pertahankan struktur/nama berkasnya, lalu sajikan melalui web server. Untuk penggunaan publik, gunakan HTTPS. Jangan membuka HTML langsung sebagai `file://`.

Preset `HTML5` menggunakan export type **Regular**, tanpa threads dan GDNative. Renderer GLES2 dipilih untuk WebGL 1.0. Ini pilihan kompatibilitas browser, bukan hasil pengukuran performa proyek.

### GitHub Pages

Workflow `.github/workflows/validate.yml` mengimpor/memeriksa proyek, menjalankan smoke test headless, lalu mengekspor dan menerapkan HTML5 ke GitHub Pages hanya pada push atau pemicu manual di branch `main` setelah validasi berhasil. Workflow ekspor terpisah juga dapat dijalankan manual atau pada tag `v*` dan mengunggah hasil sebagai artefak.

Sebelum publikasi Pages, atur sumber GitHub Pages ke **GitHub Actions** di pengaturan repositori. Konfigurasi workflow tidak menjamin bahwa build, ekspor, atau deployment berhasil; alur tersebut belum dijalankan setelah port ini.

### Catatan khusus Web

- Peramban dapat menangguhkan game ketika tab tidak aktif; periksa console browser (`F12`) bila terjadi masalah.
- Browser dapat membatasi audio autoplay sampai ada interaksi pengguna.
- Penyimpanan Godot `user://` di Web bergantung pada dukungan/pengaturan IndexedDB dan cookie browser; mode privat atau kebijakan cookie dapat menghalangi persistensi.
- Untuk referensi MIME dan cara menyajikan `.wasm`/berkas ekspor lainnya, lihat dokumentasi ekspor Web resmi Godot 3.6 di bagian Referensi.

## Alur permainan

1. Pilih **Quick Battle** atau **Practice Dojo** di Home.
2. Pilih karakter pemain dan rival.
3. Pilih arena atau gunakan **Random Arena**, lalu mulai pertandingan.
4. Quick Battle selesai saat salah satu petarung KO atau timer 99 detik habis. Saat waktu habis, HP tersisa menentukan pemenang; HP sama menghasilkan seri.
5. Practice menonaktifkan timer dan membuat rival pasif. KO masih mengakhiri pertandingan.
6. Layar hasil menyediakan rematch, pemilihan karakter/arena, dan kembali ke Home.

Versus Local belum tersedia. Collection menampilkan roster dan rekor menang/kalah/seri, tetapi belum ada sistem unlock progresif.

## Kontrol

| Aksi | Keyboard |
|---|---|
| Bergerak | `A` / `D` atau panah kiri/kanan |
| Melompat | `W`, `Space`, atau panah atas |
| Serangan/kombo | `J`, tekan lagi dalam jendela kombo |
| Energy Bolt | `K` |
| Rising Strike | `U` |
| Dash | `L` |
| Guard | `H` atau `Shift` |
| Jeda/kembali | `Escape` |

HUD menyediakan tombol sentuh untuk gerak, lompat, guard, serangan, skill, dan dash. Tata letak Classic/Compact dapat dipilih di Settings. Input sentuh dilepas saat tombol diangkat, game dijeda, atau aplikasi kehilangan fokus.

## Petarung

| ID | Nama | Peran | HP | Kecepatan | Power |
|---|---|---|---:|---:|---:|
| `kairo` | Kairo | Seimbang | 100 | 280 | 12 |
| `ren` | Ren | Cepat | 86 | 350 | 9 |
| `daigo` | Daigo | Berat | 125 | 220 | 17 |
| `luna` | Luna | Lunar | 96 | 315 | 11 |
| `sara` | Sara | Duelist | 90 | 320 | 13 |

Data karakter dan arena berada di `scripts/game_session.gd`. AI dapat mendekat, mundur, menyerang, menjaga, atau menggunakan skill berdasarkan jarak, HP, energi, dan peluang acak. Kelima atlas sprite masing-masing berukuran 1536×1024, berisi delapan sel 384×512: idle, lari, lompat, guard, serangan ringan/berat, skill, dan KO. Detail atlas ada di [`assets/sprites/README.md`](assets/sprites/README.md).

## Sistem pertarungan

- Gerak menggunakan `KinematicBody2D.move_and_slide(velocity, Vector2.UP)`, dengan gravitasi, batas arena, dan lantai collision.
- Serangan dasar memiliki kombo tiga langkah dengan pengali damage 1,0×, 1,25×, dan 1,5×. Jendela kombo 0,58 detik; hitbox aktif sebentar dan mencegah target yang sama menerima hit berulang dalam satu ayunan.
- **Energy Bolt** memakai 28 energi, cooldown 1,1 detik, damage 22, dan kecepatan 620 unit/detik. Energi pulih 8 unit/detik.
- **Rising Strike** memakai 36 energi, cooldown 2,4 detik, damage 1,8× power, serta melontarkan petarung ke atas.
- Guard mengurangi damage masuk menjadi 25% serta mengurangi knockback. Dash memberikan dorongan gerak singkat.
- HUD menampilkan HP/energi, timer, cooldown, dan banner saat skill digunakan. Pertandingan dapat dijeda.

Angka tersebut berasal dari parameter implementasi dan belum melalui pengujian keseimbangan.

## Arena, pengaturan, dan data lokal

Arena Forest Shrine, Training Dojo, dan Ruined Outpost menggunakan `scripts/arena_stage.gd` untuk ilustrasi prosedural serta lantai collision. Pratinjau menu digambar oleh `scripts/arena_preview.gd`.

`GameSession` adalah autoload global. Pengaturan mencakup volume master/musik/SFX, sensitivitas kontrol, tata letak sentuh, kualitas efek, screen shake, pengurangan efek, dan intensitas flash. Data versi 1 disimpan lokal di `user://settings.json`; rekor menang/kalah/seri disimpan di `user://progress.json`. Tidak ada layanan akun/cloud, trek musik, maupun aset audio dalam proyek.

## Referensi resmi

- [Rilis Godot 3.6 stable](https://github.com/godotengine/godot/releases/tag/3.6-stable)
- [Dokumentasi GDScript Godot 3.6](https://docs.godotengine.org/en/3.6/tutorials/scripting/gdscript/gdscript_basics.html)
- [Kinematic character 2D Godot 3.6](https://docs.godotengine.org/en/3.6/tutorials/physics/kinematic_character_2d.html)
- [Ekspor proyek ke Web/HTML5 Godot 3.6](https://docs.godotengine.org/en/3.6/tutorials/export/exporting_for_web.html)
- [Ekspor Android Godot 3.6](https://docs.godotengine.org/en/3.6/tutorials/export/exporting_for_android.html)

## Batasan port

Port ini menyesuaikan kode dan format proyek dari API Godot 4 ke Godot 3.6, termasuk skrip UI yang callback-nya kini menggunakan koneksi sinyal Godot 3. Beberapa tata letak menu dibuat lebih sederhana selama penyesuaian. Belum ada validasi parser/editor Godot 3.6, playtest, ekspor HTML5, atau pengujian pada browser/perangkat target. Periksa semua itu sebelum menganggap port siap dipublikasikan.
