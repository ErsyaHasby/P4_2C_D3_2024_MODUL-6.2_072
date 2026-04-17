import 'dart:typed_data';
import 'dart:math';

import 'package:image/image.dart' as img;

/// Enum untuk jenis filter yang dapat diterapkan
/// Setiap filter mengimplementasikan algoritma pengolahan citra digital sesuai definisi teknis
enum ImageFilter {
  normal('Normal', 'Tidak ada filter - gambar ditampilkan apa adanya'),
  grayscale(
    'Grayscale',
    'Konversi citra ke skala abu-abu (Y = 0.299R + 0.587G + 0.114B)',
  ),
  equalizeHistogram(
    'Equalize',
    'Ekualisasi histogram: redistribusi intensitas untuk kontras lebih baik',
  ),
  convolution(
    'Konvolusi',
    'Konvolusi kernel untuk pengolahan fitur: blur, sharpen, edge enhancement',
  ),
  edgeDetection(
    'Edge Detection',
    'Deteksi tepi menggunakan Sobel operator: identifikasi perubahan intensitas drastis',
  ),
  highContrast(
    'High Contrast',
    'Tingkatkan kontras dengan perbedaan tajam terang-gelap (factor 1.8)',
  ),
  brightness(
    'Brightness',
    'Sesuaikan kecerahan dengan perkalian intensitas seragam (0.3-2.0)',
  );

  final String label;
  final String description;

  const ImageFilter(this.label, this.description);
}

/// Representasi gambar dalam format RGBA
class RgbaImage {
  final int width;
  final int height;
  final Uint8List data; // RGBA format, 4 bytes per pixel

  RgbaImage({required this.width, required this.height, required this.data});

  /// Get pixel RGBA value at (x, y)
  void getPixelAt(int x, int y, List<int> rgba) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      rgba[0] = rgba[1] = rgba[2] = rgba[3] = 0;
      return;
    }
    final index = (y * width + x) * 4;
    rgba[0] = data[index];
    rgba[1] = data[index + 1];
    rgba[2] = data[index + 2];
    rgba[3] = data[index + 3];
  }

  /// Set pixel RGBA value at (x, y)
  void setPixelAt(int x, int y, int r, int g, int b, int a) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    final index = (y * width + x) * 4;
    data[index] = r;
    data[index + 1] = g;
    data[index + 2] = b;
    data[index + 3] = a;
  }

  /// Create copy of this image
  RgbaImage clone() {
    return RgbaImage(
      width: width,
      height: height,
      data: Uint8List.fromList(data),
    );
  }
}

/// Class untuk implementasi berbagai filter pengolahan citra digital
class ImageProcessor {
  /// Decode image bytes, apply the selected filter, then re-encode to JPEG.
  static Uint8List applyFilterToBytes(
    Uint8List imageBytes,
    ImageFilter filter, {
    double brightnessValue = 1.0,
    int jpegQuality = 95,
  }) {
    final decoded = img.decodeJpg(imageBytes) ?? img.decodeImage(imageBytes);
    if (decoded == null) {
      return imageBytes;
    }

    final processed = _applyImagePackageFilter(
      img.bakeOrientation(decoded),
      filter,
      brightnessValue: brightnessValue,
    );

    return Uint8List.fromList(img.encodeJpg(processed, quality: jpegQuality));
  }

  static img.Image _applyImagePackageFilter(
    img.Image image,
    ImageFilter filter, {
    double brightnessValue = 1.0,
  }) {
    final source = img.Image.from(image);

    switch (filter) {
      case ImageFilter.normal:
        return source;
      case ImageFilter.grayscale:
        return img.grayscale(source);
      case ImageFilter.equalizeHistogram:
        return img.histogramEqualization(
          source,
          mode: img.HistogramEqualizeMode.color,
        );
      case ImageFilter.convolution:
        return img.gaussianBlur(source, radius: 2);
      case ImageFilter.edgeDetection:
        return img.sobel(img.grayscale(source));
      case ImageFilter.highContrast:
        return img.contrast(source, contrast: 250);
      case ImageFilter.brightness:
        return img.adjustColor(source, brightness: brightnessValue);
    }
  }

  /// Apply filter berdasarkan jenis yang dipilih
  static RgbaImage applyFilter(
    RgbaImage image,
    ImageFilter filter, {
    double value = 0.5,
  }) {
    switch (filter) {
      case ImageFilter.normal:
        return image.clone();
      case ImageFilter.grayscale:
        return _applyGrayscale(image);
      case ImageFilter.equalizeHistogram:
        return _applyEqualizeHistogram(image);
      case ImageFilter.convolution:
        return _applyConvolution(image);
      case ImageFilter.edgeDetection:
        return _applyEdgeDetection(image);
      case ImageFilter.highContrast:
        return _applyHighContrast(image);
      case ImageFilter.brightness:
        return _applyBrightness(image, value);
    }
  }

  /// Filter: Grayscale - Konversi gambar ke skala abu-abu
  ///
  /// DEFINISI TEKNIS:
  /// Citra yang hanya memiliki tingkat warna abu-abu, tanpa informasi warna (RGB).
  /// Hasil menampilkan gradasi dari hitam pekat (#000000) hingga putih bersih (#FFFFFF).
  ///
  /// ALGORITMA:
  /// Y = 0.299 × R + 0.587 × G + 0.114 × B (Luminance formula - ITU-R BT.601)
  /// Setiap channel RGB diset ke nilai luminance yang sama untuk menghasilkan grayscale.
  ///
  /// PSEUDOCODE:
  /// for setiap pixel (x, y):
  ///   gray = 0.299 × pixel.red + 0.587 × pixel.green + 0.114 × pixel.blue
  ///   pixel.red = pixel.green = pixel.blue = gray
  static RgbaImage _applyGrayscale(RgbaImage image) {
    final result = image.clone();
    final rgba = List<int>.filled(4, 0);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        image.getPixelAt(x, y, rgba);

        // Luminance formula: 0.299*R + 0.587*G + 0.114*B
        final gray = (0.299 * rgba[0] + 0.587 * rgba[1] + 0.114 * rgba[2])
            .toInt();
        result.setPixelAt(x, y, gray, gray, gray, rgba[3]);
      }
    }

    return result;
  }

  /// Filter: Equalize Histogram - Tingkatkan kontras dengan histogram equalization
  ///
  /// DEFINISI TEKNIS:
  /// EKUALISASI adalah metode REDISTRIBUSI NILAI INTENSITAS piksel yang bertujuan untuk
  /// MERATAKAN HISTOGRAM citra, sehingga KONTRAS gambar meningkat dan DETAIL di area
  /// yang terlalu gelap atau terang menjadi lebih TERLIHAT.
  ///
  /// ALGORITMA: HISTOGRAM EQUALIZATION
  /// 1. Hitung histogram: frekuensi setiap nilai intensitas (0-255) untuk setiap channel RGB
  /// 2. Hitung cumulative histogram: akumulasi secara berurutan
  /// 3. Normalisasi: map cumulative histogram ke range 0-255
  /// 4. Buat lookup table untuk transformasi
  /// 5. Aplikasikan lookup table ke setiap pixel
  ///
  /// PSEUDOCODE:
  /// # Step 1: Build histogram (count frequency of each intensity)
  /// histogram[0..255] = 0
  /// for setiap pixel (x, y):
  ///   intensity = pixel.value
  ///   histogram[intensity]++
  ///
  /// # Step 2: Calculate cumulative histogram
  /// cumulative[0] = histogram[0]
  /// for i = 1 to 255:
  ///   cumulative[i] = cumulative[i-1] + histogram[i]
  ///
  /// # Step 3: Normalize
  /// pixelCount = image.width × image.height
  /// lookup[i] = (cumulative[i] × 255) / pixelCount
  ///
  /// # Step 4: Apply transformation
  /// for setiap pixel (x, y):
  ///   pixel.value = lookup[pixel.value]
  ///
  /// HASIL:
  /// - Histogram menjadi lebih "flat/spread out"
  /// - Kontras meningkat signifikan
  /// - Detail yang sebelumnya tersembunyi menjadi terlihat
  /// - Area terlalu gelap menjadi lebih terang, area terlalu terang menjadi lebih gelap
  static RgbaImage _applyEqualizeHistogram(RgbaImage image) {
    final result = image.clone();

    // Calculate histogram for each channel
    final histR = List<int>.filled(256, 0);
    final histG = List<int>.filled(256, 0);
    final histB = List<int>.filled(256, 0);

    final rgba = List<int>.filled(4, 0);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        image.getPixelAt(x, y, rgba);
        histR[rgba[0]]++;
        histG[rgba[1]]++;
        histB[rgba[2]]++;
      }
    }

    // Calculate cumulative histograms
    final cumR = _cumulativeHistogram(histR);
    final cumG = _cumulativeHistogram(histG);
    final cumB = _cumulativeHistogram(histB);

    // Normalize
    final pixelCount = image.width * image.height;
    final lookupR = List<int>.filled(256, 0);
    final lookupG = List<int>.filled(256, 0);
    final lookupB = List<int>.filled(256, 0);

    for (int i = 0; i < 256; i++) {
      lookupR[i] = ((cumR[i] * 255) ~/ pixelCount).clamp(0, 255);
      lookupG[i] = ((cumG[i] * 255) ~/ pixelCount).clamp(0, 255);
      lookupB[i] = ((cumB[i] * 255) ~/ pixelCount).clamp(0, 255);
    }

    // Apply transformation
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        image.getPixelAt(x, y, rgba);
        result.setPixelAt(
          x,
          y,
          lookupR[rgba[0]],
          lookupG[rgba[1]],
          lookupB[rgba[2]],
          rgba[3],
        );
      }
    }

    return result;
  }

  /// Calculate cumulative histogram
  static List<int> _cumulativeHistogram(List<int> histogram) {
    final cumulative = List<int>.filled(256, 0);
    cumulative[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cumulative[i] = cumulative[i - 1] + histogram[i];
    }
    return cumulative;
  }

  /// Filter: Convolution - Blur/Smoothing dengan kernel Gaussian
  ///
  /// DEFINISI TEKNIS:
  /// KONVOLUSI adalah operasi matematis yang mengalikan sebuah MATRIKS KECIL (kernel/filter)
  /// dengan AREA PIKSEL pada citra untuk menghasilkan efek tertentu:
  /// - Gaussian Blur: MENGABURKAN citra (smoothing/blur effect)
  /// - Laplacian: Penajaman (sharpening)
  /// - Sobel: Edge detection
  ///
  /// KERNEL YANG DIGUNAKAN: GAUSSIAN BLUR (3×3)
  /// [1  2  1]
  /// [2  4  2]  ÷ 16 (normalisasi)
  /// [1  2  1]
  ///
  /// Cara kerja GAUSSIAN BLUR:
  /// 1. Untuk setiap pixel (x, y), ambil area 3×3 di sekitarnya
  /// 2. Kalikan setiap pixel di area dengan nilai kernel yang sesuai
  /// 3. Jumlahkan hasil perkalian dan bagi dengan 16 (normalisasi)
  /// 4. Clamp ke range 0-255
  ///
  /// PSEUDOCODE:
  /// for setiap pixel (x, y) yang bukan border:
  ///   sum = 0
  ///   for ky = -1 to 1:
  ///     for kx = -1 to 1:
  ///       pixel_value = image[x+kx, y+ky]
  ///       sum += pixel_value × kernel[ky+1, kx+1]
  ///   output_pixel = clamp(sum / 16, 0, 255)  # NORMALISASI
  ///
  /// HASIL DENGAN GAUSSIAN KERNEL: BLUR/SMOOTHING
  /// - Detail gambar menjadi HALUS atau KABUR
  /// - Seolah dilihat melalui KACA BURAM
  /// - Noise berkurang, gambar terlihat lebih "soft"
  static RgbaImage _applyConvolution(RgbaImage image) {
    final result = image.clone();

    // Kernel Gaussian untuk blur (smoothing)
    const kernel = [
      [1, 2, 1],
      [2, 4, 2],
      [1, 2, 1],
    ];
    const kernelSum = 16; // Normalisasi untuk Gaussian

    final rgba = List<int>.filled(4, 0);
    final neighbors = List<int>.filled(4, 0);

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        int sumR = 0, sumG = 0, sumB = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            image.getPixelAt(x + kx, y + ky, neighbors);
            final k = kernel[ky + 1][kx + 1];

            sumR += (neighbors[0] * k);
            sumG += (neighbors[1] * k);
            sumB += (neighbors[2] * k);
          }
        }

        // Normalisasi dengan membagi kernel sum
        final r = (sumR ~/ kernelSum).clamp(0, 255);
        final g = (sumG ~/ kernelSum).clamp(0, 255);
        final b = (sumB ~/ kernelSum).clamp(0, 255);

        image.getPixelAt(x, y, rgba);
        result.setPixelAt(x, y, r, g, b, rgba[3]);
      }
    }

    return result;
  }

  /// Filter: Edge Detection - Deteksi tepi menggunakan Sobel operator
  ///
  /// DEFINISI TEKNIS:
  /// Teknik pengolahan citra untuk mengidentifikasi TITIK-TITIK di mana terdapat
  /// perubahan intensitas cahaya yang DRASTIS. HASIL AKHIR:
  /// - Gambar HITAM dengan GARIS-GARIS PUTIH yang membentuk kerangka/outline
  /// - Semua detail permukaan (warna kulit, tekstur kain, dll) HILANG
  /// - Tersisa hanya "SKETSA" bentuk objek saja
  ///
  /// ALGORITMA: SOBEL OPERATOR + INVERSION
  /// Menggunakan dua kernel 3×3:
  ///
  /// Sobel-X (deteksi tepi vertikal):     Sobel-Y (deteksi tepi horizontal):
  /// [-1  0  1]                           [-1  -2  -1]
  /// [-2  0  2]                           [ 0   0   0]
  /// [-1  0  1]                           [ 1   2   1]
  ///
  /// Cara kerja:
  /// 1. Konvolusi kernel-X dengan area 3×3 = Gx (gradien horizontal)
  /// 2. Konvolusi kernel-Y dengan area 3×3 = Gy (gradien vertikal)
  /// 3. Magnitude = sqrt(Gx² + Gy²) menunjukkan kekuatan tepi
  /// 4. INVERT: 255 - magnitude agar tepi menjadi putih, background hitam
  ///
  /// PSEUDOCODE:
  /// for setiap pixel (x, y) yang bukan border:
  ///   Gx = konvolusi 3×3 dengan kernel-X
  ///   Gy = konvolusi 3×3 dengan kernel-Y
  ///   magnitude = sqrt(Gx² + Gy²)
  ///   pixel output = 255 - magnitude  # INVERT untuk putih-on-black
  ///
  /// HASIL: Background HITAM PEKAT, tepi/garis objek PUTIH CEMERLANG
  /// Efeknya seperti "X-ray" atau "sketsa garis" saja
  static RgbaImage _applyEdgeDetection(RgbaImage image) {
    final result = image.clone();

    // Sobel kernels
    const sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];

    const sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    final neighbors = List<int>.filled(4, 0);

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        int gx = 0, gy = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            image.getPixelAt(x + kx, y + ky, neighbors);

            // Luminance formula
            final gray =
                (0.299 * neighbors[0] +
                        0.587 * neighbors[1] +
                        0.114 * neighbors[2])
                    .toInt();

            gx += gray * sobelX[ky + 1][kx + 1];
            gy += gray * sobelY[ky + 1][kx + 1];
          }
        }

        // Hitung magnitude
        final magnitude = (sqrt(
          (gx * gx + gy * gy).toDouble(),
        )).clamp(0, 255).toInt();

        // INVERT: Tepi menjadi putih, background menjadi hitam
        final inverted = 255 - magnitude;

        result.setPixelAt(x, y, inverted, inverted, inverted, 255);
      }
    }

    return result;
  }

  /// Filter: High Contrast - Tingkatkan kontras gambar
  ///
  /// DEFINISI TEKNIS:
  /// Kondisi citra di mana terdapat perbedaan intensitas yang sangat TAJAM antara area
  /// terang dan area gelap, menciptakan efek "mencolok":
  /// - Bayangan akan terlihat HITAM PEKAT (#000000)
  /// - Area terang akan terlihat PUTIH MENYALA (#FFFFFF)
  /// - Warna-warna perantara (abu-abu/midtones) akan MENGHILANG
  ///
  /// ALGORITMA: CONTRAST STRETCHING DENGAN AGRESIF
  /// output = (input - midpoint) × contrastFactor + midpoint, di mana:
  /// - midpoint = 128 (tengah range 0-255)
  /// - contrastFactor = 3.0 (300% peningkatan kontras - EKSTRIM)
  /// - Nilai ekstrim ini menghasilkan "clipping" yang membuat midtones hilang
  ///
  /// PSEUDOCODE:
  /// for setiap pixel (x, y):
  ///   pixel.red = clamp((pixel.red - 128) × 3.0 + 128, 0, 255)
  ///   pixel.green = clamp((pixel.green - 128) × 3.0 + 128, 0, 255)
  ///   pixel.blue = clamp((pixel.blue - 128) × 3.0 + 128, 0, 255)
  ///
  /// EFEK VISUAL:
  /// - Bayangan (< 85) → Hitam pekat (0)
  /// - Midtone (85-170) → Push ke extreme: hitam atau putih
  /// - Highlight (> 170) → Putih menyala (255)
  /// - Detail di area menengah akan hilang karena "clipping"
  static RgbaImage _applyHighContrast(RgbaImage image) {
    final result = image.clone();

    // Contrast factor yang lebih ekstrim (3.0) untuk efek "mencolok"
    const contrastFactor = 3.0;
    const midpoint = 128.0;

    final rgba = List<int>.filled(4, 0);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        image.getPixelAt(x, y, rgba);

        final r = (((rgba[0] - midpoint) * contrastFactor + midpoint).clamp(
          0,
          255,
        )).toInt();
        final g = (((rgba[1] - midpoint) * contrastFactor + midpoint).clamp(
          0,
          255,
        )).toInt();
        final b = (((rgba[2] - midpoint) * contrastFactor + midpoint).clamp(
          0,
          255,
        )).toInt();

        result.setPixelAt(x, y, r, g, b, rgba[3]);
      }
    }

    return result;
  }

  /// Filter: Brightness - Sesuaikan kecerahan gambar
  ///
  /// DEFINISI TEKNIS:
  /// Nilai intensitas cahaya pada citra yang menentukan seberapa terang/gelapnya gambar.
  /// Operasi dilakukan dengan menambah/mengurangi nilai setiap piksel secara SERAGAM.
  ///
  /// ALGORITMA: PENAMBAHAN (ADDITION)
  /// Brightness ditambahkan ke setiap channel RGB:
  /// - Area hitam (0) akan menjadi abu-abu ketika brightness ditambah
  /// - Area putih (255) tetap putih (karena sudah maksimal)
  /// - Efeknya seperti "terpapar cahaya matahari" secara merata
  ///
  /// Formula:
  /// offset = (value - 1.0) × 127.5, di mana value: 0.3-2.0
  /// - value 0.3: offset ≈ -88 (gambar lebih gelap)
  /// - value 1.0: offset = 0 (normal, tidak ada perubahan)
  /// - value 2.0: offset ≈ 127 (gambar lebih terang)
  /// output = clamp(input + offset, 0, 255)
  ///
  /// PSEUDOCODE:
  /// offset = (value - 1.0) × 127.5
  /// for setiap pixel (x, y):
  ///   pixel.red = clamp(pixel.red + offset, 0, 255)
  ///   pixel.green = clamp(pixel.green + offset, 0, 255)
  ///   pixel.blue = clamp(pixel.blue + offset, 0, 255)
  ///
  /// CATATAN: Berbeda dengan multiply, addition membuat area gelap menjadi lebih terang
  /// sambil area terang tetap putih (saturasi). Hasil: terlihat terpapar cahaya.
  static RgbaImage _applyBrightness(RgbaImage image, double value) {
    final result = image.clone();

    // Convert value (0.3-2.0) ke offset (-88 to 127)
    final offset = ((value - 1.0) * 127.5).toInt();
    final rgba = List<int>.filled(4, 0);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        image.getPixelAt(x, y, rgba);

        final r = (rgba[0] + offset).clamp(0, 255);
        final g = (rgba[1] + offset).clamp(0, 255);
        final b = (rgba[2] + offset).clamp(0, 255);

        result.setPixelAt(x, y, r, g, b, rgba[3]);
      }
    }

    return result;
  }
}
