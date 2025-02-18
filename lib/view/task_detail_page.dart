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
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers().then((_) {
      // Takım üyeleri yüklendikten sonra verileri güncelle
      setState(() {
        _initializeData();
      });
    });
  }

  Future<void> _loadTeamMembers() async {
    try {
      // Projeyi ana koleksiyondan al
      var projectDoc = await _firestore
          .collection('projects')
          .doc(widget.projectId)
          .get();
      
      if (projectDoc.exists) {
        var projectData = projectDoc.data()!;
        List<String> memberEmails = List<String>.from(projectData['teamMembers'] ?? []);
        
        // Tüm üyelerin bilgilerini al
        List<Map<String, dynamic>> members = [];
        for (String email in memberEmails) {
          var userQuery = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .get();
          
          if (userQuery.docs.isNotEmpty) {
            var userData = userQuery.docs.first.data();
            members.add({
              'id': userQuery.docs.first.id,
              'email': email,
              'username': userData['name'] ?? 'İsimsiz Kullanıcı',
              'isOwner': projectData['ownerId'] == userQuery.docs.first.id,
            });
          }
        }

        setState(() {
          _teamMembers = members;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      print('Takım üyeleri yüklenirken hata: $e');
      setState(() => _isLoadingUsers = false);
    }
  }

  void _initializeData() {
    try {
      print("Task verisi: ${widget.task}"); // Debug için
      _titleController.text = widget.task['title'] ?? '';
      _descriptionController.text = widget.task['description'] ?? '';
      _storyPointController.text = widget.task['storyPoint']?.toString() ?? '0';
      _startDate = widget.task['startDate']?.toDate();
      _endDate = widget.task['endDate']?.toDate();
      _selectedUserId = widget.task['assignedToId'];
      print("Seçili kullanıcı ID: $_selectedUserId"); // Debug için
    } catch (e) {
      print("Initialize hatası: $e");
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime currentDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? _startDate ?? currentDate
          : _endDate ?? (_startDate?.add(const Duration(days: 1)) ?? currentDate),
      firstDate: isStartDate 
          ? currentDate
          : _startDate ?? currentDate,
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
          // Eğer bitiş tarihi başlangıç tarihinden önceyse veya null ise
          if (_endDate == null || _endDate!.isBefore(_startDate!)) {
            // Bitiş tarihini başlangıç tarihinden bir gün sonraya ayarla
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveTask() async {
    try {
      String assignedUsername = '';
      String assignedEmail = '';
      
      if (_selectedUserId != null) {
        var matchingUser = _teamMembers.firstWhere(
          (user) => user['id'] == _selectedUserId,
          orElse: () => {},
        );
        
        if (matchingUser.isNotEmpty) {
          assignedUsername = matchingUser['username']?.toString() ?? '';
          assignedEmail = matchingUser['email']?.toString() ?? '';

          // Seçilen kullanıcının projelerini kontrol et
          var userProjectsRef = _firestore
              .collection('users')
              .doc(_selectedUserId)
              .collection('projects');

          try {
            var projectDoc = await _firestore
                .collection('users')
                .doc(widget.uid)
                .collection('projects')
                .doc(widget.projectId)
                .get();

            if (projectDoc.exists) {
              String projectName = projectDoc.data()?['name'] ?? '';
              
              var existingProject = await userProjectsRef.doc(widget.projectId).get();

              if (!existingProject.exists) {
                await userProjectsRef.doc(widget.projectId).set({
                  'name': projectName,
                  'createdAt': Timestamp.now(),
                  'status': 'active',
                  'ownerId': widget.uid,
                });
              }
            }
          } catch (e) {
            print("Proje işlemleri sırasında hata: $e");
          }
        }
      }

      // Ana task güncelleme
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
        'assignedTo': assignedEmail,  // Email'i kaydediyoruz
        'assignedToName': assignedUsername,  // Kullanıcı adını kaydediyoruz
        'updatedAt': Timestamp.now(),
      });

      // Başarılı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görev başarıyla güncellendi')),
      );

      // Önceki sayfaya dön ve güncelleme yapıldığını bildir
      Navigator.pop(context, true);

    } catch (e) {
      print('Hata detayı: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  Widget _buildUserDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isLoadingUsers
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: _selectedUserId != null && 
                       _teamMembers.any((user) => user['id'] == _selectedUserId)
                    ? _selectedUserId
                    : null,
                hint: const Text('Görev atanacak kişiyi seçin'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.person_outline),
                        SizedBox(width: 8),
                        Text('Atanmamış'),
                      ],
                    ),
                  ),
                  ..._teamMembers.map((member) {
                    return DropdownMenuItem<String?>(
                      value: member['id'],
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: member['isOwner'] 
                                ? Colors.orange 
                                : widget.statusColor,
                            radius: 15,
                            child: Text(
                              member['username'].toString().isNotEmpty
                                  ? member['username'].toString()[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  member['username'].toString(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  member['email'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (member['isOwner'])
                            const Tooltip(
                              message: 'Proje Sahibi',
                              child: Icon(Icons.star, color: Colors.orange, size: 16),
                            ),
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
    );
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
                border: OutlineInputBorder(),
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
                border: OutlineInputBorder(),
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
            Text('Görev atanacak kişiyi seçin'),
            // Atanan Kişi Dropdown
            _buildUserDropdown(),
            const SizedBox(height: 16),

            // Açıklama
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _storyPointController.dispose();
    super.dispose();
  }
} 