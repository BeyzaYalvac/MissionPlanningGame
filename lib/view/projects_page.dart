import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_gram_grad_project/view/create_project_page.dart';
import 'package:to_gram_grad_project/view/project_detail_page.dart';

class ProjectsPage extends StatefulWidget {
  final String uid;
  const ProjectsPage({super.key, required this.uid});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> projects = [];
  bool isLoading = true;
  String? userEmail; // 📌 Kullanıcı e-posta değişkeni

  @override
  void initState() {
    super.initState();
    _loadUserEmail(); // 📌 Kullanıcı e-postasını yükle
    _loadProjects();
  }

  /// 📌 **Kullanıcının e-posta adresini Firestore'dan al**
  Future<void> _loadUserEmail() async {
    try {
      var userDoc = await _firestore.collection('users').doc(widget.uid).get();
      var data = userDoc.data();
      if (data != null && data.containsKey('email')) {
        setState(() {
          userEmail = data['email']; // 🔥 **E-posta yüklenince güncelle**
        });
      }
    } catch (e) {
      print("Kullanıcı e-postası yüklenirken hata: $e");
    }
  }

  /// 📌 **Kullanıcının sahip olduğu ve davet edildiği projeleri yükler**
  Future<void> _loadProjects() async {
    try {
      setState(() {
        isLoading = true;
      });

      List<Map<String, dynamic>> allProjects = [];

      var ownProjectsSnapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .get();

      for (var doc in ownProjectsSnapshot.docs) {
        var data = doc.data();
        allProjects.add({
          ...data,
          'id': doc.id,
          'isOwner': true,
        });
      }

      if (userEmail != null) {
        var invitedProjectsSnapshot = await _firestore
            .collection('projects')
            .where('teamMembers', arrayContains: userEmail)
            .get();

        for (var doc in invitedProjectsSnapshot.docs) {
          var data = doc.data();
          if (!allProjects.any((p) => p['id'] == doc.id)) {
            allProjects.add({
              ...data,
              'id': doc.id,
              'isOwner': false,
            });
          }
        }
      }

      setState(() {
        projects = allProjects;
        isLoading = false;
      });
    } catch (e) {
      print('Proje yükleme hatası: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 📌 **Yeni proje oluşturma sayfasına yönlendirme**
  void _goToCreateProjectPage() {
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı e-postası yükleniyor, lütfen bekleyin!")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProjectPage(uid: widget.uid, userEmail: userEmail!),
      ),
    ).then((_) => _loadProjects()); // 📌 Yeni proje eklendikten sonra listeyi yenile
  }

  Future<void> _showCreateProjectDialog() async {
    String projectName = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Proje Oluştur'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Proje Adı',
            hintText: 'Projenizin adını giriniz',
          ),
          onChanged: (value) => projectName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              if (projectName.trim().isNotEmpty) {
                try {
                  // Projeyi, girilen isimle doküman olarak oluştur
                  await _firestore
                      .collection('users')
                      .doc(widget.uid)
                      .collection('projects')
                      .doc(projectName
                          .trim()) // Proje adını doküman ID'si olarak kullan
                      .set({
                    'name': projectName.trim(),
                    'createdAt': Timestamp.now(),
                    'status': 'active',
                    'ownerId': widget.uid,
                  });

                  Navigator.pop(context);
                  _loadProjects(); // Projeleri yeniden yükle
                } catch (e) {
                  print('Proje oluşturma hatası: $e');
                  // Kullanıcıya hata mesajı göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Proje oluşturulurken hata: $e')),
                  );
                }
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProjectDialog(Map<String, dynamic> project) async {
    String newProjectName = project['name'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proje Adını Düzenle'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Yeni Proje Adı',
          ),
          controller: TextEditingController(text: project['name']),
          onChanged: (value) => newProjectName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              if (newProjectName.trim().isNotEmpty) {
                try {
                  await _firestore
                      .collection('users')
                      .doc(widget.uid)
                      .collection('projects')
                      .doc(project['id'])
                      .update({
                    'name': newProjectName.trim(),
                  });
                  Navigator.pop(context);
                  _loadProjects();
                } catch (e) {
                  print('Proje güncelleme hatası: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Proje güncellenirken hata: $e')),
                  );
                }
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject(Map<String, dynamic> project) async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Projeyi Sil'),
            content:
                const Text('Bu projeyi silmek istediğinizden emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmDelete) {
      try {
        await _firestore
            .collection('users')
            .doc(widget.uid)
            .collection('projects')
            .doc(project['id'])
            .delete();
        _loadProjects();
      } catch (e) {
        print('Proje silme hatası: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proje silinirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projelerim'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz projeniz bulunmamakta.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _showCreateProjectDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Yeni Proje Oluştur'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        final bool isOwner = project['ownerId'] == widget.uid;

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProjectDetailPage(
                                    uid: isOwner
                                        ? widget.uid
                                        : project['ownerId'],
                                    projectId: project['id'],
                                    projectName: project['name'],
                                  ),
                                ),
                              ).then((_) => _loadProjects());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          project['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isOwner)
                                        PopupMenuButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.more_vert,
                                              size: 20),
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
                                                  Icon(Icons.delete,
                                                      size: 20,
                                                      color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Sil',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showEditProjectDialog(project);
                                            } else if (value == 'delete') {
                                              _deleteProject(project);
                                            }
                                          },
                                        )
                                      else if (!isOwner)
                                        const Tooltip(
                                          message: 'Davet edildiğiniz proje',
                                          child: Icon(
                                            Icons.people_outline,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Durum: ${project['status']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Oluşturulma: ${DateFormat('dd/MM/yyyy').format(project['createdAt'].toDate())}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreateProjectPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}
