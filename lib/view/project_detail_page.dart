import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:to_gram_grad_project/view/task_detail_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTasks();
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
    } catch (e) {
      print('Hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showAddTaskDialog(String status) async {
    String taskTitle = '';
    String taskDescription = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                });
                Navigator.pop(context);
                _loadTasks();
              }
            },
            child: const Text('Ekle'),
          ),
        ],
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
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {},
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
                          child: _buildTaskCard(task, color),
                        ),
                        child: _buildTaskCard(task, color),
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

  Widget _buildTaskCard(Map<String, dynamic> task, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailPage(
                uid: widget.uid,
                projectId: widget.projectId,
                task: task,
                statusColor: color,
              ),
            ),
          ).then((_) => _loadTasks());
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: ListTile(
            title: Text(
              task['title'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: task['description']?.isNotEmpty ?? false
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      task['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  )
                : null,
            trailing: PopupMenuButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Düzenle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20),
                      SizedBox(width: 8),
                      Text('Sil'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                // Düzenleme ve silme işlemleri
              },
            ),
          ),
        ),
      ),
    );
  }
} 