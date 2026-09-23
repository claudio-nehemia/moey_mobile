import 'package:flutter/material.dart';
import '../../../../utils/constant.dart';

class OrderTeamSection extends StatelessWidget {
  final List<dynamic>? users;

  const OrderTeamSection({super.key, this.users});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, String>>> roleGroups = {
      'Kepala Marketing': [],
      'Surveyor / Drafter': [],
      'Desainer': [],
    };

    if (users != null) {
      for (final u in users!) {
        final role = u['role'] as String? ?? 'Anggota';
        final name = u['name'] as String? ?? '';
        final email = u['email'] as String? ?? '';

        final userMap = {'name': name, 'email': email};

        if (role == 'Kepala Marketing') {
          roleGroups['Kepala Marketing']!.add(userMap);
        } else if (role == 'Surveyor' || role == 'Drafter') {
          roleGroups['Surveyor / Drafter']!.add(userMap);
        } else if (role == 'Desainer') {
          roleGroups['Desainer']!.add(userMap);
        }
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Constants.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded, size: 18, color: Constants.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Penugasan Tim Kerja',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Constants.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Constants.borderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoleListRow('Kepala Marketing', roleGroups['Kepala Marketing']!, Colors.indigo.withOpacity(0.08), Colors.indigo),
                const SizedBox(height: 16),
                _buildRoleListRow('Surveyor / Drafter', roleGroups['Surveyor / Drafter']!, Colors.amber.withOpacity(0.08), Colors.amber[800]!),
                const SizedBox(height: 16),
                _buildRoleListRow('Desainer', roleGroups['Desainer']!, Colors.purple.withOpacity(0.08), Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleListRow(String roleLabel, List<Map<String, String>> members, Color avatarBg, Color avatarText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          roleLabel,
          style: const TextStyle(fontSize: 10, color: Constants.textLight, fontWeight: FontWeight.bold, letterSpacing: 0.2),
        ),
        const SizedBox(height: 6),
        members.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  'Belum ditugaskan',
                  style: TextStyle(fontSize: 12, color: Constants.textMedium, fontStyle: FontStyle.italic),
                ),
              )
            : Column(
                children: members.map((u) {
                  final name = u['name'] ?? '';
                  final email = u['email'] ?? '';
                  final initials = name.isNotEmpty
                      ? name.split(' ').map((p) => p[0]).take(2).join('').toUpperCase()
                      : '?';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Constants.surfaceColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Constants.borderColor.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: avatarBg,
                          child: Text(
                            initials,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: avatarText),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Constants.textDark),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                email,
                                style: const TextStyle(fontSize: 10, color: Constants.textLight),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}
