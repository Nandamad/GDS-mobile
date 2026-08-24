import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  Color _getDotColor(String title) {
    title = title.toLowerCase();
    if (title.contains('tolak')) return Colors.red;
    if (title.contains('tuju')) return Colors.teal;
    if (title.contains('lembur')) return Colors.orange;
    return Colors.blue;
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final dio = ApiService().dio;
      final response = await dio.get('/notifikasi');
      if (response.statusCode == 200) {
        final payload = response.data;
        final list = (payload['data'] as List?) ?? (payload as List?) ?? [];
        
        setState(() {
          _notifications = list.map((e) {
            final data = e['data'] ?? {};
            return {
              'id': e['id'],
              'title': data['title'] ?? 'Notifikasi',
              'message': data['message'] ?? '',
              'time': _formatDate(e['created_at']),
              'isUnread': e['read_at'] == null,
              'dotColor': _getDotColor(data['title'] ?? ''),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('GET /notifikasi ERROR: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final dio = ApiService().dio;
      await dio.patch('/notifikasi/read-all');
      setState(() {
        for (var item in _notifications) {
          item['isUnread'] = false;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai telah dibaca'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('PATCH /notifikasi/read-all ERROR: $e');
    }
  }
  
  Future<void> _markAsRead(String id, int index) async {
    if (!_notifications[index]['isUnread']) return;
    
    setState(() => _notifications[index]['isUnread'] = false);
    try {
      final dio = ApiService().dio;
      await dio.patch('/notifikasi/$id/read');
    } catch (e) {
      debugPrint('PATCH /notifikasi/id/read ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // TOMBOL BACK LINGKARAN DI SEBELAH KIRI
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
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
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada notifikasi.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
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
                            if (item['id'] != null) {
                              _markAsRead(item['id'].toString(), index);
                            }
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