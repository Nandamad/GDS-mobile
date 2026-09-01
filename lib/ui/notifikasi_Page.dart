import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  // We'll store parsed and grouped notifications here
  List<Map<String, dynamic>> _todayNotifications = [];
  List<Map<String, dynamic>> _yesterdayNotifications = [];
  List<Map<String, dynamic>> _olderNotifications = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  String _formatRelativeTime(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inSeconds < 60) {
        return 'Baru saja';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} menit lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} jam lalu';
      } else if (diff.inDays == 1) {
        return '1 hari lalu';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} hari lalu';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    } catch (_) {
      return value.toString();
    }
  }
  
  String _getGroupCategory(dynamic value) {
    if (value == null) return 'Lainnya';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateToCompare = DateTime(date.year, date.month, date.day);
      
      if (dateToCompare == today) {
        return 'Hari ini';
      } else if (dateToCompare == yesterday) {
        return 'Kemarin';
      } else {
        return 'Lainnya';
      }
    } catch (_) {
      return 'Lainnya';
    }
  }

  Map<String, dynamic> _getIconAndColor(String title) {
    title = title.toLowerCase();
    
    // Setujui
    if (title.contains('disetujui') || title.contains('tuju')) {
      return {
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF009688), // Teal
        'bgColor': const Color(0xFFE0F2F1),
      };
    } 
    // Ditolak
    else if (title.contains('ditolak') || title.contains('tolak')) {
      return {
        'icon': Icons.cancel_outlined,
        'color': const Color(0xFFDC2626), // Red
        'bgColor': const Color(0xFFFEE2E2),
      };
    } 
    // Lembur/Update
    else if (title.contains('lembur')) {
      return {
        'icon': Icons.access_time,
        'color': const Color(0xFFF59E0B), // Orange
        'bgColor': const Color(0xFFFEF3C7),
      };
    } 
    // Default (Pengingat / dll)
    else {
      return {
        'icon': Icons.notifications_none,
        'color': const Color(0xFF3B82F6), // Blue
        'bgColor': const Color(0xFFDBEAFE),
      };
    }
  }

  Map<String, dynamic> _readNotificationData(Map item) {
    final rawData = item['data'];
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  List<dynamic> _readList(dynamic payload) {
    dynamic value = payload;
    for (var index = 0; index < 3 && value is Map; index++) {
      value = value['data'] ?? value['items'] ?? value['result'] ?? value;
      if (value is Map &&
          !value.containsKey('data') &&
          !value.containsKey('items') &&
          !value.containsKey('result')) {
        break;
      }
    }
    return value is List ? value : const [];
  }

  String _buildFormattedMessage(Map<String, dynamic> data, Map rawItem) {
    final String rawMessage = (data['message'] ?? data['body'] ?? rawItem['message'] ?? '').toString().trim();
    if (rawMessage.isNotEmpty && !rawMessage.toLowerCase().contains('ada pembaruan')) {
      return rawMessage;
    }
    final String jenis = (data['jenis'] ?? data['type'] ?? data['kategori'] ?? 'Pengajuan').toString();
    final String status = (data['status'] ?? 'diproses').toString();
    final String tgl = data['tanggal'] != null ? ' tanggal ${data['tanggal']}' : '';
    final String oleh = data['approved_by'] != null ? ' oleh ${data['approved_by']}' : '';

    if (status.toLowerCase().contains('setuju') || status.toLowerCase().contains('approved')) {
      return 'Pengajuan $jenis Anda$tgl telah disetujui$oleh.';
    } else if (status.toLowerCase().contains('tolak') || status.toLowerCase().contains('rejected')) {
      final String alasan = data['alasan'] != null ? ' (${data['alasan']})' : '';
      return 'Pengajuan $jenis Anda$tgl ditolak$alasan.';
    }
    return 'Pengajuan $jenis Anda$tgl sedang dalam proses verifikasi.';
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final dio = ApiService().dio;
      final response = await dio.get('/notifikasi');
      
      List<Map<String, dynamic>> allNotifs = [];

      if (response.statusCode == 200) {
        final payload = response.data;
        final list = _readList(payload);

        allNotifs = list.whereType<Map>().map((e) {
          final data = _readNotificationData(e);
          final title = (data['title'] ?? e['title'] ?? e['type'] ?? 'Notifikasi System').toString();
          final message = _buildFormattedMessage(data, e);
          final iconData = _getIconAndColor(title);
          
          return {
            'id': e['id'],
            'title': title,
            'message': message,
            'timeRaw': e['created_at'],
            'time': _formatRelativeTime(e['created_at']),
            'isUnread': e['read_at'] == null,
            'icon': iconData['icon'],
            'iconColor': iconData['color'],
            'iconBgColor': iconData['bgColor'],
            'group': _getGroupCategory(e['created_at']),
          };
        }).toList();
      }
      
      // Append pending approvals
      final pendingList = await _fetchPendingApprovals();
      allNotifs = [...pendingList, ...allNotifs];
      
      // Group them
      _todayNotifications = allNotifs.where((e) => e['group'] == 'Hari ini').toList();
      _yesterdayNotifications = allNotifs.where((e) => e['group'] == 'Kemarin').toList();
      _olderNotifications = allNotifs.where((e) => e['group'] == 'Lainnya').toList();
      
    } catch (e) {
      debugPrint('GET /notifikasi ERROR: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPendingApprovals() async {
    try {
      final response = await ApiService().dio.get('/approval/pending');
      final pending = _readList(response.data);
      if (pending.isEmpty) return [];

      return pending.whereType<Map>().map((item) {
        final type = (item['type'] ?? item['jenis_pengajuan'] ?? 'Pengajuan').toString().toLowerCase();
        final isLembur = type.contains('lembur');
        final isCuti = type.contains('cuti');
        final isIzin = type.contains('izin');

        String kat = 'Persetujuan Baru';
        if (isLembur) kat = 'Persetujuan Lembur';
        if (isCuti) kat = 'Persetujuan Cuti';
        if (isIzin) kat = 'Persetujuan Izin';

        final employee = item['user']?['name'] ?? item['karyawan']?['nama_lengkap'] ?? item['karyawan']?['nama'] ?? item['nama_karyawan'] ?? 'Karyawan';
        final durasi = item['durasi'] != null ? ' (${item['durasi']})' : '';
        
        final iconData = _getIconAndColor(kat);

        return <String, dynamic>{
          'id': null,
          'title': kat,
          'message': '$employee mengajukan ${isLembur ? 'lembur' : 'izin/cuti'}$durasi. Membutuhkan persetujuan Anda.',
          'timeRaw': item['created_at'],
          'time': _formatRelativeTime(item['created_at']),
          'isUnread': true,
          'icon': iconData['icon'],
          'iconColor': iconData['color'],
          'iconBgColor': iconData['bgColor'],
          'group': _getGroupCategory(item['created_at']),
        };
      }).toList();
    } catch (e) {
      debugPrint('GET /approval/pending NOTIFICATION ERROR: $e');
      return [];
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final dio = ApiService().dio;
      await dio.patch('/notifikasi/read-all');
      
      void markListAsRead(List<Map<String, dynamic>> list) {
        for (var item in list) {
          item['isUnread'] = false;
        }
      }
      
      setState(() {
        markListAsRead(_todayNotifications);
        markListAsRead(_yesterdayNotifications);
        markListAsRead(_olderNotifications);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua notifikasi ditandai telah dibaca'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint('PATCH /notifikasi/read-all ERROR: $e');
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> item) async {
    if (item['isUnread'] == false || item['id'] == null) return;

    setState(() => item['isUnread'] = false);
    try {
      final dio = ApiService().dio;
      await dio.patch('/notifikasi/${item['id']}/read');
    } catch (e) {
      debugPrint('PATCH /notifikasi/id/read ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _todayNotifications.isEmpty && _yesterdayNotifications.isEmpty && _olderNotifications.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF0F172A)),
            ),
          ),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: isEmpty ? null : _markAllAsRead,
              child: Text(
                'Tandai Dibaca Semua',
                style: TextStyle(
                  color: isEmpty ? Colors.grey : const Color(0xFF009688),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: isEmpty ? Colors.grey : const Color(0xFF009688),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : isEmpty
              ? const Center(child: Text('Belum ada notifikasi.', style: TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_todayNotifications.isNotEmpty) ...[
                        const Text('Hari ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        const SizedBox(height: 12),
                        ..._todayNotifications.map((item) => _buildNotificationCard(item)).toList(),
                        const SizedBox(height: 12),
                      ],
                      if (_yesterdayNotifications.isNotEmpty) ...[
                        const Text('Kemarin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        const SizedBox(height: 12),
                        ..._yesterdayNotifications.map((item) => _buildNotificationCard(item)).toList(),
                        const SizedBox(height: 12),
                      ],
                      if (_olderNotifications.isNotEmpty) ...[
                        const Text('Lainnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        const SizedBox(height: 12),
                        ..._olderNotifications.map((item) => _buildNotificationCard(item)).toList(),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final bool isUnread = item['isUnread'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _markAsRead(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnread ? const Color(0xFF009688).withOpacity(0.5) : Colors.grey.shade200,
              width: isUnread ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (isUnread)
                BoxShadow(color: const Color(0xFF009688).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: item['iconBgColor'],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item['icon'], size: 16, color: item['iconColor']),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['message'],
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 10),
              Text(
                item['time'],
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}