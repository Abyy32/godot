# Atlas karakter

Tiga atlas PNG transparan berukuran 1536×1024 dibuat sebagai seni prototipe menggunakan OpenAI ImageGen. Desain karakter adalah prototipe orisinal, bukan karakter berlisensi dari waralaba lain.

Setiap atlas berisi empat kolom dan dua baris; ukuran setiap sel adalah 384×512. Urutan sel:

| Sel | Pose |
|---|---|
| Baris 1, kolom 1–4 | Idle, lari, lompat, guard |
| Baris 2, kolom 1–4 | Serangan ringan, serangan berat, skill energi, KO |

Proyek target Godot 3.6 memakai `AtlasTexture` pada animasi `AnimatedSprite`. `scripts/fighter.gd` memetakan state gerak/pertarungan ke pose atlas. Sejumlah state hanya memiliki satu frame dan belum menjadi animasi final. Jika atlas diganti, periksa kembali tepi alpha dan posisi gambar di setiap sel.
