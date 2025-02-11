import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class TaskDetailPage extends StatefulWidget {
  final String uid;
  final String projectId;
  final Map<String, dynamic> task;
  final Color statusColor;

  const TaskDetailPage({
    Key? key,
    required this.uid,
    required this.projectId,
    required this.task,
    required this.statusColor,
  }) : super(key: key);

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _storyPointController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedUserId;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      var usersSnapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> tempUsers = [];
      
      for (var doc in usersSnapshot.docs) {
        var userData = doc.data();
        tempUsers.add({
          'id': doc.id,
          'username': userData['username'] ?? 'İsimsiz Kullanıcı',
        });
      }

      setState(() {
        _users = tempUsers;
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('Kullanıcılar yüklenirken hata: $e');
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  void _initializeData() {
    _titleController.text = widget.task['title'] ?? '';
    _descriptionController.text = widget.task['description'] ?? '';
    _storyPointController.text = widget.task['storyPoint']?.toString() ?? '0';
    _startDate = widget.task['startDate']?.toDate();
    _endDate = widget.task['endDate']?.toDate();
    _selectedUserId = widget.task['assignedToId'];
  }

  Future<void> _saveTask() async {
    try {
      String assignedUsername = '';
      if (_selectedUserId != null) {
        var selectedUser = _users.firstWhere(
          (user) => user['id'] == _selectedUserId,
          orElse: () => {'username': ''},
        );
        assignedUsername = selectedUser['username'] ?? '';
      }

      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('projects')
          .doc(widget.projectId)
          .collection('tasks')
          .doc(widget.task['id'])
          .update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'storyPoint': int.tryParse(_storyPointController.text) ?? 0,
        'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'assignedToId': _selectedUserId,
        'assignedTo': assignedUsername,
        'updatedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görev başarıyla güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Detayı'),
        backgroundColor: widget.statusColor.withOpacity(0.8),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Görev Başlığı',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.statusColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Story Point
            TextField(
              controller: _storyPointController,
              decoration: InputDecoration(
                labelText: 'Story Point',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.statusColor),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Tarih Seçiciler
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Başlangıç Tarihi'),
                    subtitle: Text(
                      _startDate != null
                          ? DateFormat('dd/MM/yyyy').format(_startDate!)
                          : 'Seçilmedi',
                    ),
                    onTap: () => _selectDate(context, true),
                    leading: Icon(Icons.calendar_today, color: widget.statusColor),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Bitiş Tarihi'),
                    subtitle: Text(
                      _endDate != null
                          ? DateFormat('dd/MM/yyyy').format(_endDate!)
                          : 'Seçilmedi',
                    ),
                    onTap: () => _selectDate(context, false),
                    leading: Icon(Icons.event, color: widget.statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Atanan Kişi Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedUserId,
                        hint: const Text('Görev atanacak kişiyi seçin'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Atanmamış'),
                          ),
                          ..._users.map((user) {
                            return DropdownMenuItem<String>(
                              value: user['id'],
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: widget.statusColor,
                                    radius: 15,
                                    child: Text(
                                      user['username'][0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(user['username']),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedUserId = newValue;
                          });
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Açıklama
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Açıklama',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.statusColor),
                ),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: isStartDate ? DateTime(2000) : _startDate ?? DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.statusColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _storyPointController.dispose();
    super.dispose();
  }
} 