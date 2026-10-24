# Atlas karakter

Lima atlas PNG transparan berukuran 1536×1024 dibuat sebagai seni prototipe menggunakan OpenAI ImageGen. Tiap karakter memiliki kostum, siluet, dan pose gerak/serangan yang khas, sementara seluruh atlas memakai grid dan skala sel yang sama agar tetap cocok dengan animasi game. Desain karakter adalah prototipe orisinal, bukan karakter berlisensi dari waralaba lain.

Setiap atlas pose berisi empat kolom dan dua baris; ukuran setiap sel adalah 384×512. Urutan sel:

| Sel | Pose |
|---|---|
| Baris 1, kolom 1–4 | Idle, lari, lompat, guard |
| Baris 2, kolom 1–4 | Serangan ringan, serangan berat, skill energi, KO |

Setiap karakter juga memiliki strip `*_run_cycle.png` transparan berukuran 1536×512 dengan empat pose lari berurutan. Strip ini dipakai khusus untuk loop lari, sementara atlas utama menyimpan pose idle, lompat, guard, serangan, skill, dan KO. Proyek Godot 3.6 memakai `AtlasTexture` pada `AnimatedSprite`; `scripts/fighter.gd` memetakan state gerak dan pertarungan ke atlas yang sesuai. Jika aset diganti, periksa kembali tepi alpha dan posisi gambar di setiap sel.
