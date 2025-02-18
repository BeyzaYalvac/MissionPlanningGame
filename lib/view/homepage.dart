import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:to_gram_grad_project/view/projects_page.dart';
import 'package:to_gram_grad_project/view/project_detail_page.dart';
import 'package:to_gram_grad_project/view/settings_page.dart';
import 'package:to_gram_grad_project/view/profile_page.dart';
import 'package:to_gram_grad_project/view/invitations_page.dart';

class HomePage extends StatefulWidget {
  final String uid;

  const HomePage({super.key, required this.uid,});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? userInfo;
  int activeProjectCount = 0;
  int pendingTasksCount = 0;
  List<Map<String, dynamic>> recentProjects = [];

  Future<void> getUserInfos() async {
    FirebaseFirestore _firebase = FirebaseFirestore.instance;
    CollectionReference _usersCollection = _firebase.collection('users');
    DocumentReference _userDocReference = _usersCollection.doc(widget.uid);

    try {
      var resultGetUser = await _userDocReference.get();

      if (resultGetUser.exists) {
        var result = resultGetUser.data() as Map<String, dynamic>;
        setState(() {
          userInfo = result;
        });
      } else {
        // Kullanıcı dokümanı yoksa oluştur
        await _userDocReference.set({
          'username': 'Kullanıcı',
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          userInfo = {'username': 'Kullanıcı'};
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı bilgileri alınırken hata oluştu')),
      );
    }
  }

  Future<void> getActiveProjectCount() async {
    try {
      var projectsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('projects')
          .where('status', isEqualTo: 'active')
          .get();

      setState(() {
        activeProjectCount = projectsSnapshot.docs.length;
      });
    } catch (e) {
      print("Aktif proje sayısı alınırken hata: $e");
    }
  }

  Future<void> getPendingTasksCount() async {
    try {
      var projectsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('projects')
          .get();

      int totalPendingTasks = 0;

      for (var project in projectsSnapshot.docs) {
        var tasksSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('projects')
            .doc(project.id)
            .collection('tasks')
            .where('status', isEqualTo: 'todo')
            .where('assignedToId', isEqualTo: widget.uid)
            .get();

        totalPendingTasks += tasksSnapshot.docs.length;
      }

      setState(() {
        pendingTasksCount = totalPendingTasks;
      });
    } catch (e) {
      print("Bekleyen görev sayısı alınırken hata: $e");
    }
  }

  Future<void> loadRecentProjects() async {
    try {
      var projectsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      setState(() {
        recentProjects = projectsSnapshot.docs.map((doc) {
          var data = doc.data();
          return {
            ...data,
            'id': doc.id,
            'isOwner': data['ownerId'] == widget.uid,
          };
        }).toList();
      });
    } catch (e) {
      print("Son projeler yüklenirken hata: $e");
    }
  }

  // Bekleyen davetleri kontrol eden stream
  Stream<int> _getPendingInvitationsCount() {
    return FirebaseFirestore.instance
        .collection('project_invitations')
        .where('email', isEqualTo: userInfo?['email'])
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  void initState() {
    super.initState();
    getUserInfos();
    getActiveProjectCount();
    loadRecentProjects();
    getPendingTasksCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proje Yönetimi'),
        actions: [
          // Bildirim ikonu
          StreamBuilder<int>(
            stream: _getPendingInvitationsCount(),
            builder: (context, snapshot) {
              final hasInvitations = (snapshot.data ?? 0) > 0;
              
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      hasInvitations ? Icons.notifications_active : Icons.notifications,
                      color: hasInvitations ? Colors.amber : null,
                    ),
                    onPressed: () {
                      if (userInfo != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvitationsPage(
                              userEmail: userInfo!['email'],
                            ),
                          ),
                        );
                      }
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
                            fontWeight: FontWeight.bold,
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
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(uid: widget.uid),
                ),
              );
            },
          ),
        ],
      ),
      body: userInfo == null
          ? const Center(child: CircularProgressIndicator()) // Yüklenme göstergesi
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hoşgeldin mesajı
              Text(
                'Hoş geldin, ${userInfo!['username'] ?? 'Kullanıcı'}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // İstatistik kartları
              Row(
                children: [
                  _buildStatCard('Aktif Projeler', activeProjectCount.toString(), Colors.blue),
                  const SizedBox(width: 16),
                  _buildStatCard('Bekleyen Görevler', pendingTasksCount.toString(), Colors.orange),
                ],
              ),
              const SizedBox(height: 20),

              // Projeler başlığı ve liste
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Projelerim',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectsPage(uid: widget.uid),
                        ),
                      ).then((_) {
                        getActiveProjectCount();
                        loadRecentProjects();
                      });
                    },
                    child: const Text('Tümünü Gör'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildProjectList(),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsPage(

                ),
              ),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Takvim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    if (recentProjects.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Henüz proje bulunmamakta',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentProjects.length,
      itemBuilder: (context, index) {
        final project = recentProjects[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(project['name']),
            subtitle: Text('Durum: ${project['status']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: project['status'] == 'active' 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    project['status'] == 'active' ? 'Aktif' : 'Pasif',
                    style: TextStyle(
                      color: project['status'] == 'active' ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailPage(
                    uid: widget.uid,
                    projectId: project['id'],
                    projectName: project['name'],
                  ),
                ),
              ).then((_) {
                loadRecentProjects();
                getActiveProjectCount();
                getPendingTasksCount();
              });
            },
          ),
        );
      },
    );
  }
}
