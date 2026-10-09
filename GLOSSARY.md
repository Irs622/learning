# 📖 Glosarium

Materi repo ini memakai istilah teknis bahasa Inggris apa adanya (agar Anda mengenali istilah yang sama di dokumentasi, audit report, dan diskusi komunitas). Tabel ini menjelaskan artinya dalam bahasa Indonesia beserta fase tempat istilah itu dibahas.

| Istilah | Arti singkat | Fase |
|---|---|---|
| **ABI** (Application Binary Interface) | Format standar untuk meng-encode pemanggilan fungsi & event agar bisa dipahami contract dan aplikasi | 2, 9 |
| **Account Abstraction (AA)** | Wallet berupa smart contract dengan aturan validasi sendiri (multisig, passkey, sponsor gas) | 13 |
| **Allowance / approve** | Izin bagi address lain untuk memindahkan token Anda hingga jumlah tertentu | 5 |
| **AMM** (Automated Market Maker) | Bursa berbasis rumus (misal `x · y = k`), bukan order book | 11 |
| **Anvil** | Node Ethereum lokal untuk pengembangan (bagian Foundry) | 6 |
| **Blob** | Paket data ~128 KB untuk rollup (EIP-4844), murah & dihapus setelah ~18 hari | 12 |
| **Bridge** | Mekanisme memindahkan aset/pesan antar-chain | 12 |
| **Bundler** | Node yang mengumpulkan UserOperation ERC-4337 dan mengirimnya ke EntryPoint | 13 |
| **Calldata** | Data input transaksi, read-only | 2 |
| **CEI** (Checks-Effects-Interactions) | Urutan aman: validasi → ubah state → panggil pihak luar | 4, 8 |
| **Cheatcode** | Fungsi `vm.*` khusus test Foundry untuk memanipulasi lingkungan EVM | 6 |
| **Collateral** | Jaminan yang dikunci untuk meminjam | 11 |
| **Commit-reveal** | Pola menyembunyikan nilai (commit hash) lalu mengungkapnya kemudian | 3, 8 |
| **Data availability (DA)** | Jaminan bahwa data transaksi dipublikasikan dan bisa diambil siapa pun | 12 |
| **EOA** (Externally Owned Account) | Akun yang dikendalikan private key | 2 |
| **EntryPoint** | Contract singleton ERC-4337 yang memvalidasi & mengeksekusi UserOperation | 13 |
| **Event / log** | Catatan yang di-emit contract untuk konsumen off-chain | 2, 10 |
| **Finality / finalized** | Status block yang praktis tidak bisa dibatalkan (~13 menit di Ethereum) | 1, 10 |
| **Flash loan** | Pinjaman tanpa jaminan yang harus dikembalikan dalam transaksi yang sama | 8, 11 |
| **Fork test** | Test terhadap salinan lokal state mainnet | 7 |
| **Front-running** | Menyisipkan transaksi sebelum transaksi korban yang terlihat di mempool | 1, 8 |
| **Fuzz test** | Test dengan input acak untuk membuktikan sebuah properti | 7 |
| **Gas / gas limit** | Satuan biaya komputasi / batas maksimum gas sebuah transaksi atau block | 1, 2 |
| **Ghost variable** | Variabel di handler test yang mencatat nilai yang seharusnya, untuk dibandingkan dengan state | 7 |
| **Handler** | Contract pembungkus agar invariant fuzzer memanggil fungsi dengan input yang bermakna | 7 |
| **HD wallet** | Wallet yang menurunkan banyak kunci dari satu seed (BIP-32/44) | 3 |
| **Health factor** | Rasio nilai jaminan terhadap hutang; < 1 berarti bisa dilikuidasi | 11 |
| **Impermanent loss** | Selisih nilai antara menjadi LP dan sekadar menyimpan aset | 11 |
| **Indexer** | Layanan yang membaca event dan menyimpannya ke database untuk query cepat | 10 |
| **Invariant** | Properti yang harus selalu benar di setiap state | 7 |
| **L2 / rollup** | Jaringan yang mengeksekusi di luar L1 tetapi mem-posting data/bukti ke L1 | 12 |
| **Liquidation** | Penjualan paksa jaminan peminjam yang health factor-nya < 1 | 11 |
| **LP** (Liquidity Provider) | Penyedia likuiditas ke pool AMM | 11 |
| **Mempool** | Antrean transaksi yang belum masuk block | 1 |
| **MEV** (Maximal Extractable Value) | Nilai yang bisa diambil dengan mengatur urutan transaksi | 1, 8, 13 |
| **Mnemonic / seed phrase** | 12–24 kata yang menjadi cadangan seluruh kunci HD wallet | 3 |
| **Nonce** | Penghitung transaksi per akun (atau penghitung anti-replay pada signature) | 1, 3, 8 |
| **Oracle** | Sumber data off-chain untuk contract (misal harga) | 8, 11 |
| **Paymaster** | Contract yang membayarkan gas untuk UserOperation | 13 |
| **PoC** (Proof of Concept) | Kode yang membuktikan sebuah kerentanan benar-benar bisa dieksploitasi | 8 |
| **Proxy / upgradeable** | Pola memisahkan alamat & storage (proxy) dari logika (implementation) | 13 |
| **Reentrancy** | Contract dipanggil kembali sebelum eksekusi sebelumnya selesai | 4, 8 |
| **Reorg** | Pergantian block di ujung chain karena node beralih ke cabang lain | 1, 10 |
| **Revert** | Membatalkan seluruh perubahan state dalam sebuah call | 4 |
| **Selector** | 4 byte pertama `keccak256` dari signature fungsi | 2 |
| **Sequencer** | Pihak yang mengurutkan transaksi di L2 | 12 |
| **Slashing** | Hukuman pemotongan stake validator yang melanggar aturan | 1 |
| **Slippage** | Selisih harga yang diharapkan dengan harga eksekusi | 9, 11 |
| **Slot (storage)** | Unit penyimpanan 32 byte di storage contract | 2 |
| **TWAP** | Harga rata-rata tertimbang waktu, lebih sulit dimanipulasi daripada harga spot | 8, 11 |
| **UserOperation** | "Niat" transaksi dari smart account ERC-4337 | 13 |
