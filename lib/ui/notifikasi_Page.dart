import 'package:flutter/material.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Pengajuan Cuti Disetujui',
      'message': 'Pengajuan cuti Anda tanggal 06-10 Agt telah disetujui Atasan.',
      'time': '2 jam lalu',
      'dotColor': Colors.teal,
      'isUnread': true,
    },
    {
      'title': 'Update Lembur',
      'message': 'Lembur tanggal 03 Agt sedang menunggu persetujuan HRD.',
      'time': '4 jam lalu',
      'dotColor': Colors.orange,
      'isUnread': true,
    },
    {
      'title': 'Reminder Absen Pagi',
      'message': 'Jangan lupa absen masuk! Jam kerja mulai pukul 08:00.',
      'time': '1 hari lalu',
      'dotColor': Colors.blue,
      'isUnread': false,
    },
    {
      'title': 'Pengajuan Ditolak',
      'message': 'Pengajuan izin tanggal 20 Jul ditolak oleh Atasan.',
      'time': '2 hari lalu',
      'dotColor': Colors.red,
      'isUnread': false,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item['isUnread'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai telah dibaca'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: _markAllAsRead,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE0F2F1),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tandai Dibaca Semua',
                style: TextStyle(
                  color: Color(0xFF009688),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          children: _notifications.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildNotificationCard(
                title: item['title'],
                message: item['message'],
                time: item['time'],
                dotColor: item['dotColor'],
                isUnread: item['isUnread'],
                onTap: () {
                  setState(() => _notifications[index]['isUnread'] = false);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String time,
    required Color dotColor,
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? const Color(0xFF009688) : Colors.grey.shade200,
            width: isUnread ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: dotColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF009688),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}