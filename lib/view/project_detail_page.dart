import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    task['assignedTo'] ?? 'Atanmamış',
                    style: TextStyle(color: Colors.grey[600]),
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
                  if (task['storyPoint'] != null) ...[
                    const SizedBox(width: 16),
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
                  ],
                ],
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailPage(
                  uid: widget.uid,
                  projectId: widget.projectId,
                  task: task,
                  statusColor: statusColor,
                ),
              ),
            ).then((_) => _loadTasks());
          },
        ),
      ),
    );
  }
} 