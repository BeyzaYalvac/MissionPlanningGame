import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_gram_grad_project/view/task_detail_page.dart';
import 'package:to_gram_grad_project/view/project_statistics_page.dart';
import 'package:to_gram_grad_project/view/invitations_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final String uid;
  final String projectId;
  final String projectName;

  const ProjectDetailPage({
    super.key,
    required this.uid,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> tasks = {
    'todo': [],
    'doing': [],
    'done': [],
    'verify': [],
  };
  List<Map<String, dynamic>> teamMembers = [];
  bool isLoading = true;

  // Renk tanımlamaları
  final Map<String, Color> columnColors = {
    'todo': const Color(0xFFF87171),    // Kırmızımsı
    'doing': const Color(0xFFFBBF24),   // Turuncumsu
    'done': const Color(0xFF34D399),    // Yeşilimsi
    'verify': const Color(0xFF60A5FA),  // Mavimsi
  };

  // İkon tanımlamaları
  final Map<String, IconData> columnIcons = {
    'todo': Icons.list_alt,
    'doing': Icons.running_with_errors,
    'done': Icons.task_alt,
    'verify': Icons.verified,
  };

  // Bekleyen davetleri kontrol eden stream
  Stream<int> _getPendingInvitationsCount() {
    return _firestore
        .collection('project_invitations')
        .where('email', isEqualTo: widget.uid) // veya kullanıcının emaili
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
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
              'email': email,
              'name': userData['name'] ?? 'İsimsiz Kullanıcı',
              'isOwner': projectData['ownerId'] == userQuery.docs.first.id,
              'uid': userQuery.docs.first.id,
            });
          }
        }

        setState(() {
          teamMembers = members;
        });
      }

      await _loadTasks();
    } catch (e) {
      print('Proje verisi yüklenirken hata: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadTasks() async {
    try {
      var tasksSnapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('projects')
          .doc(widget.projectId)
          .collection('tasks')
          .get();

      Map<String, List<Map<String, dynamic>>> tempTasks = {
        'todo': [],
        'doing': [],
        'done': [],
        'verify': [],
      };

      for (var doc in tasksSnapshot.docs) {
        var taskData = doc.data();
        taskData['id'] = doc.id;
        tempTasks[taskData['status']]?.add(taskData);
      }

      setState(() {
        tasks = tempTasks;
        isLoading = false;
      });

      // Tasks yüklendikten sonra istatistikleri güncelle
      await _updateStatistics();
    } catch (e) {
      print('Hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateStatistics() async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('projects')
          .doc(widget.projectId)
          .collection('statistics')
          .add({
        'date': Timestamp.now(),
        'todo': tasks['todo']?.length ?? 0,
        'doing': tasks['doing']?.length ?? 0,
        'done': tasks['done']?.length ?? 0,
        'verify': tasks['verify']?.length ?? 0,
      });
    } catch (e) {
      print('İstatistik güncellenirken hata: $e');
    }
  }

  Future<void> _showAddTaskDialog(String status) async {
    String taskTitle = '';
    String taskDescription = '';
    int difficulty = 1;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Yeni Görev Ekle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Görev Başlığı',
                    hintText: 'Görev başlığını giriniz',
                  ),
                  onChanged: (value) => taskTitle = value,
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Görev Açıklaması',
                    hintText: 'Görev açıklamasını giriniz',
                  ),
                  onChanged: (value) => taskDescription = value,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Zorluk Seviyesi: '),
                    Expanded(
                      child: Slider(
                        value: difficulty.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: difficulty.toString(),
                        onChanged: (value) {
                          setState(() {
                            difficulty = value.round();
                          });
                        },
                      ),
                    ),
                    Text(difficulty.toString()),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  if (taskTitle.trim().isNotEmpty) {
                    await _firestore
                        .collection('users')
                        .doc(widget.uid)
                        .collection('projects')
                        .doc(widget.projectId)
                        .collection('tasks')
                        .add({
                      'title': taskTitle,
                      'description': taskDescription,
                      'status': status,
                      'createdAt': Timestamp.now(),
                      'assignedTo': '',
                      'assignedToId': '',
                      'startDate': null,
                      'endDate': null,
                      'storyPoint': 0,
                      'difficulty': difficulty,
                    });
                    Navigator.pop(context);
                    _loadTasks();
                  }
                },
                child: const Text('Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateTaskStatus(
      String taskId, String oldStatus, String newStatus) async {
    await _firestore
        .collection('users')
        .doc(widget.uid)
        .collection('projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(taskId)
        .update({'status': newStatus});
    _loadTasks();
  }

  void _showTeamMembersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.group, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Takım Üyeleri (${teamMembers.length})'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: teamMembers.map((member) => ListTile(
              leading: CircleAvatar(
                backgroundColor: member['isOwner'] ? Colors.orange : Colors.blue,
                child: Text(
                  member['name'][0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(member['name']),
              subtitle: Text(member['email']),
              trailing: member['isOwner']
                  ? const Tooltip(
                      message: 'Proje Sahibi',
                      child: Icon(Icons.star, color: Colors.orange),
                    )
                  : null,
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showAssignTaskDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.assignment_ind, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Görevi Ata'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: teamMembers.map((member) => ListTile(
              leading: CircleAvatar(
                backgroundColor: member['isOwner'] ? Colors.orange : Colors.blue,
                child: Text(
                  (member['name'] ?? '').toString().isNotEmpty 
                      ? member['name'][0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(member['name'] ?? 'İsimsiz Kullanıcı'),
              subtitle: Text(member['email'] ?? ''),
              trailing: task['assignedTo'] == member['email']
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : member['isOwner']
                      ? const Tooltip(
                          message: 'Proje Sahibi',
                          child: Icon(Icons.star, color: Colors.orange),
                        )
                      : null,
              onTap: () async {
                await _firestore
                    .collection('users')
                    .doc(widget.uid)
                    .collection('projects')
                    .doc(widget.projectId)
                    .collection('tasks')
                    .doc(task['id'])
                    .update({
                  'assignedTo': member['email'],
                  'assignedToName': member['name'],
                  'assignedToId': member['uid'],
                });
                Navigator.pop(context);
                _loadTasks();
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.projectName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // Takım üyeleri butonu
          TextButton.icon(
            icon: const Icon(Icons.group),
            label: Text('${teamMembers.length} Üye'),
            onPressed: _showTeamMembersDialog,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
          // Bildirimler butonu
          StreamBuilder<int>(
            stream: _getPendingInvitationsCount(),
            builder: (context, snapshot) {
              final hasInvitations = (snapshot.data ?? 0) > 0;
              
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications,
                      color: hasInvitations ? Colors.amber : Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvitationsPage(
                            userEmail: widget.uid, // veya kullanıcının emaili
                          ),
                        ),
                      );
                    },
                  ),
                  if (hasInvitations)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${snapshot.data}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectStatisticsPage(
                    uid: widget.uid,
                    projectId: widget.projectId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[100]!,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 
                        AppBar().preferredSize.height - 
                        MediaQuery.of(context).padding.top - 
                        MediaQuery.of(context).padding.bottom - 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildColumn('Yapılacaklar', 'todo'),
                        _buildColumn('Yapılıyor', 'doing'),
                        _buildColumn('Tamamlandı', 'done'),
                        _buildColumn('Kontrol', 'verify'),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildColumn(String title, String status) {
    final color = columnColors[status]!;
    return Container(
      width: 320,
      margin: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(columnIcons[status], color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks[status]?.length ?? 0}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.add, color: color),
                  onPressed: () => _showAddTaskDialog(status),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DragTarget<Map<String, dynamic>>(
                onAccept: (data) {
                  _updateTaskStatus(data['id'], data['status'], status);
                },
                builder: (context, candidateData, rejectedData) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks[status]?.length ?? 0,
                    itemBuilder: (context, index) {
                      var task = tasks[status]![index];
                      return Draggable<Map<String, dynamic>>(
                        data: task,
                        feedback: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 300,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  task['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (task['description']?.isNotEmpty ?? false)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      task['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: _buildTaskCard(task, columnColors[status]!),
                        ),
                        child: _buildTaskCard(task, columnColors[status]!),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, Color statusColor) {
    // Bitiş tarihini kontrol et
    bool isOverdue = false;
    if (task['endDate'] != null) {
      DateTime endDate = (task['endDate'] as Timestamp).toDate();
      isOverdue = endDate.isBefore(DateTime.now());
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isOverdue 
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: isOverdue 
              ? LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  task['title'] ?? 'İsimsiz Görev',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? Colors.red : null,
                  ),
                ),
              ),
              if (isOverdue)
                const Tooltip(
                  message: 'Görev Süresi Doldu',
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (task['description'] != null && task['description'].toString().isNotEmpty)
                Text(
                  task['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Atanan kişi avatarı
                  if (task['assignedToName'] != null && task['assignedToName'].toString().isNotEmpty)
                    Tooltip(
                      message: '${task['assignedToName']} (${task['assignedTo']})',
                      child: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.8),
                        radius: 12,
                        child: Text(
                          task['assignedToName'][0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Tooltip(
                      message: 'Atanmamış',
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[400],
                        radius: 12,
                        child: const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  if (task['endDate'] != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format((task['endDate'] as Timestamp).toDate()),
                      style: TextStyle(
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                  if (task['storyPoint'] != null || task['difficulty'] != null) ...[
                    const SizedBox(width: 16),
                    if (task['storyPoint'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${task['storyPoint']} SP',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                          ),
                        ),
                      ),
                    if (task['difficulty'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up, size: 14, color: Colors.purple),
                            const SizedBox(width: 4),
                            Text(
                              '${task['difficulty']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailPage(
                  uid: widget.uid,
                  projectId: widget.projectId,
                  task: task,
                  statusColor: statusColor,
                ),
              ),
            );
            
            if (result == true) {
              _loadTasks();
            }
          },
        ),
      ),
    );
  }
} 