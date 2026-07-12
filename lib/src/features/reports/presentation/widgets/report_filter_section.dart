import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/report_repository.dart';

class ReportFilterSection extends ConsumerWidget {
  const ReportFilterSection({super.key});

  Future<void> _pilihTanggalFilter(
    BuildContext context,
    WidgetRef ref,
    DateTime currentDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != currentDate) {
      ref.read(reportFilterDateProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilterType = ref.watch(reportFilterTypeProvider);
    final activeFilterDate = ref.watch(reportFilterDateProvider);
    final activeWeekIndex = ref.watch(
      reportFilterWeekIndexProvider,
    ); // <--- BARU: Ambil minggu aktif

    final dateFormat = DateFormat('dd MMMM yyyy');
    final monthFormat = DateFormat('MMMM yyyy');

    return Column(
      children: [
        // A. Pilihan filter utama horisontal (Semua, Harian, Mingguan, Bulanan)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip(ref, 'semua', 'Semua', activeFilterType),
              const SizedBox(width: 8),
              _buildFilterChip(ref, 'harian', 'Harian', activeFilterType),
              const SizedBox(width: 8),
              _buildFilterChip(ref, 'mingguan', 'Mingguan', activeFilterType),
              const SizedBox(width: 8),
              _buildFilterChip(ref, 'bulanan', 'Bulanan', activeFilterType),
            ],
          ),
        ),

        // B. Tombol kalender dinamis (Hanya muncul jika bukan filter 'semua')
        if (activeFilterType != 'semua')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () =>
                  _pilihTanggalFilter(context, ref, activeFilterDate),
              icon: const Icon(Icons.date_range),
              label: Text(
                activeFilterType == 'harian'
                    ? 'Tanggal: ${dateFormat.format(activeFilterDate)}'
                    : (activeFilterType == 'mingguan'
                          ? 'Bulan Acuan: ${monthFormat.format(activeFilterDate)}' // <--- Diubah agar fokus memilih bulan acuan
                          : 'Bulan: ${monthFormat.format(activeFilterDate)}'),
              ),
            ),
          ),

        // C. BARU: TAMPILAN TOMBOL PILIHAN MINGGU 1 S.D MINGGU 4 (Hanya muncul saat filter 'mingguan' aktif)
        if (activeFilterType == 'mingguan')
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildWeekChip(ref, 1, 'Minggu 1 (Tgl 1-7)', activeWeekIndex),
                const SizedBox(width: 8),
                _buildWeekChip(ref, 2, 'Minggu 2 (Tgl 8-14)', activeWeekIndex),
                const SizedBox(width: 8),
                _buildWeekChip(ref, 3, 'Minggu 3 (Tgl 15-21)', activeWeekIndex),
                const SizedBox(width: 8),
                _buildWeekChip(
                  ref,
                  4,
                  'Minggu 4 (Tgl 22-End)',
                  activeWeekIndex,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Widget helper membuat ChoiceChip pilihan filter utama
  Widget _buildFilterChip(
    WidgetRef ref,
    String type,
    String label,
    String activeType,
  ) {
    final isSelected = activeType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          ref.read(reportFilterTypeProvider.notifier).state = type;
        }
      },
    );
  }

  // WIDGET HELPER BARU: Membuat ChoiceChip khusus untuk memilih Minggu ke-1 s.d ke-4 (Metode B)
  Widget _buildWeekChip(
    WidgetRef ref,
    int index,
    String label,
    int activeIndex,
  ) {
    final isSelected = activeIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blue.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade900 : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (bool selected) {
        if (selected) {
          // Setiap kali diklik, perbarui status indeks minggu yang dipilih
          ref.read(reportFilterWeekIndexProvider.notifier).state = index;
        }
      },
    );
  }
}
