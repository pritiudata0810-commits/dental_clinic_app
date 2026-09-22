import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../state/clinic_scope.dart';
import 'add_patient_screen.dart';
import 'patient_profile_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<Map<String, String>> _samplePatients = const [
    {
      'name': 'Aarav Mehta',
      'initials': 'AM',
      'age': '28',
      'gender': 'Male',
      'phone': '+91 98765 43210',
      'lastVisit': '04 Sep 2026',
      'status': 'Active Treatment',
      'diagnosis': 'Scaling & Root Planing',
    },
    {
      'name': 'Ananya Patil',
      'initials': 'AP',
      'age': '34',
      'gender': 'Female',
      'phone': '+91 98220 12345',
      'lastVisit': '28 Aug 2026',
      'status': 'Follow-up Due',
      'diagnosis': 'Dental Cleaning',
    },
    {
      'name': 'Rohan Deshmukh',
      'initials': 'RD',
      'age': '42',
      'gender': 'Male',
      'phone': '+91 97654 98765',
      'lastVisit': '10 Sep 2026',
      'status': 'Active Treatment',
      'diagnosis': 'Root Canal Treatment',
    },
    {
      'name': 'Sneha Kulkarni',
      'initials': 'SK',
      'age': '19',
      'gender': 'Female',
      'phone': '+91 94230 45678',
      'lastVisit': '15 Aug 2026',
      'status': 'Under Treatment',
      'diagnosis': 'Ceramic Braces Adjustment',
    },
    {
      'name': 'Vedant Joshi',
      'initials': 'VJ',
      'age': '51',
      'gender': 'Male',
      'phone': '+91 98900 11223',
      'lastVisit': '01 Sep 2026',
      'status': 'Completed',
      'diagnosis': 'Zirconia Crown Placement',
    },
    {
      'name': 'Kavita Iyer',
      'initials': 'KI',
      'age': '29',
      'gender': 'Female',
      'phone': '+91 97300 99887',
      'lastVisit': '18 Aug 2026',
      'status': 'Active Treatment',
      'diagnosis': 'Invisalign Monitoring',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final statePatients = clinic.patients;

    final allPatients = statePatients.isNotEmpty
        ? statePatients.map((p) => {
            'name': p.name,
            'initials': p.name.isNotEmpty ? p.name[0] : 'P',
            'age': '32',
            'gender': p.gender,
            'phone': p.phone,
            'lastVisit': p.lastVisit,
            'status': 'Active Treatment',
            'diagnosis': p.notes.isNotEmpty ? p.notes : 'Routine Care',
          }).toList()
        : _samplePatients;

    final filtered = allPatients.where((p) {
      final matchesSearch = p['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p['phone']!.contains(_searchQuery);
      if (_selectedFilter == 'All') return matchesSearch;
      return matchesSearch && p['status']!.toLowerCase().contains(_selectedFilter.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Doctor Patient Directory', style: AppTextStyles.h3),
                      SizedBox(height: 3),
                      Text('Clinical records, dental charts & treatment history', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                AppButton(
                  text: '+ Add Patient',
                  icon: Icons.person_add_alt_1_outlined,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddPatientScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Search Bar & Filter Chips
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search patients by name, phone or ID...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                      onPressed: () => setState(() => _searchQuery = ''),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Filter Chips
            Wrap(
              spacing: 8,
              children: ['All', 'Active', 'Follow-up', 'Completed'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter == 'All' ? 'All Patients' : filter),
                  selected: isSelected,
                  selectedColor: AppColors.primaryLight,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = filter);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Patient List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final patient = filtered[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientProfileScreen(
                          patientName: patient['name']!,
                          initials: patient['initials']!,
                          age: patient['age']!,
                          gender: patient['gender']!,
                          phone: patient['phone']!,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            patient['initials']!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    patient['name']!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${patient['gender']}, ${patient['age']} yrs',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${patient['phone']} • Last Visit: ${patient['lastVisit']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: patient['status'] == 'Completed'
                                ? const Color(0xFFDCFCE7)
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            patient['status']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: patient['status'] == 'Completed'
                                  ? const Color(0xFF16A34A)
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}