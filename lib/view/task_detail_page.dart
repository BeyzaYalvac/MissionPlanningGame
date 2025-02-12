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
      print("Kullanıcılar yüklenmeye başlıyor..."); // Debug
      var usersSnapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> tempUsers = [];
      
      for (var doc in usersSnapshot.docs) {
        var userData = doc.data();
        print("Kullanıcı verisi: ${doc.id} - ${userData['username']}"); // Debug
        tempUsers.add({
          'id': doc.id,
          'username': userData['username'] ?? 'İsimsiz Kullanıcı',
        });
      }

      setState(() {
        _users = tempUsers;
        _isLoadingUsers = false;
      });
      print("Toplam yüklenen kullanıcı sayısı: ${_users.length}"); // Debug
      print("Yüklenen kullanıcılar: $_users"); // Debug
    } catch (e) {
      print('Kullanıcılar yüklenirken hata: $e');
      setState(() {
        _isLoadingUsers = false;
      });
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
      print("Kaydetme başlıyor..."); // Debug
      print("Seçili kullanıcı ID: $_selectedUserId"); // Debug
      print("Yüklü kullanıcılar: $_users"); // Debug

      String assignedUsername = '';
      if (_selectedUserId != null) {
        // Kullanıcı arama mantığını değiştiriyoruz
        var matchingUsers = _users.where((user) => user['id'] == _selectedUserId).toList();
        print("Eşleşen kullanıcılar: $matchingUsers"); // Debug

        if (matchingUsers.isNotEmpty) {
          assignedUsername = matchingUsers.first['username']?.toString() ?? '';
          print("Atanan kullanıcı adı: $assignedUsername"); // Debug

          // Seçilen kullanıcının projelerini kontrol et
          var userProjectsRef = _firestore
              .collection('users')
              .doc(_selectedUserId)
              .collection('projects');

          try {
            // Projenin adını almak için ana projeyi çek
            var projectDoc = await _firestore
                .collection('users')
                .doc(widget.uid)
                .collection('projects')
                .doc(widget.projectId)
                .get();

            if (projectDoc.exists) {
              String projectName = projectDoc.data()?['name'] ?? '';
              print("Proje adı: $projectName"); // Debug
              
              // Atanan kullanıcının projeler koleksiyonunda bu proje var mı kontrol et
              var existingProject = await userProjectsRef.doc(widget.projectId).get();

              // Eğer proje yoksa, kullanıcının projects koleksiyonuna ekle
              if (!existingProject.exists) {
                print('Proje kullanıcıya ekleniyor: $projectName');
                await userProjectsRef.doc(widget.projectId).set({
                  'name': projectName,
                  'createdAt': Timestamp.now(),
                  'status': 'active',
                  'ownerId': widget.uid,
                });
                print('Proje kullanıcıya eklendi');
              }
            }
          } catch (e) {
            print("Proje işlemleri sırasında hata: $e");
          }
        } else {
          print("Seçili kullanıcı ID için eşleşen kullanıcı bulunamadı");
        }
      } else {
        print("Seçili kullanıcı ID null");
      }

      // Task güncelleme
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

      print("Task başarıyla güncellendi"); // Debug
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görev başarıyla güncellendi')),
      );
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
                       _users.any((user) => user['id'] == _selectedUserId)
                    ? _selectedUserId
                    : null,
                hint: const Text('Görev atanacak kişiyi seçin'),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: widget.statusColor,
                          radius: 15,
                          child: const Text(
                           'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        SizedBox(width: 8,),
                        const Text('Atanmamış'),
                      ],
                    ),
                  ),
                  ..._users.map((user) {
                    print("Dropdown item oluşturuluyor: ${user['id']} - ${user['username']}"); // Debug için
                    return DropdownMenuItem<String?>(
                      value: user['id'],
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: widget.statusColor,
                            radius: 15,
                            child: Text(
                              user['username'].toString().isNotEmpty
                                  ? user['username'].toString()[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user['username'].toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (String? newValue) {
                  print("Yeni seçilen değer: $newValue"); // Debug için
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