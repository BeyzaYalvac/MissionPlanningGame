import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      print("Projeler yükleniyor... UID: ${widget.uid}"); // Debug için
      var projectsSnapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .get();

      var projectsList = projectsSnapshot.docs.map((doc) {
        print("Proje verisi: ${doc.data()}"); // Debug için
        return {
          ...doc.data(),
          'id': doc.id,
        };
      }).toList();

      setState(() {
        projects = projectsList;
        isLoading = false;
      });
      print("Yüklenen proje sayısı: ${projects.length}"); // Debug için
    } catch (e) {
      print('Hata: $e');
      setState(() {
        isLoading = false;
      });
    }
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
                  // Proje ismini belge ID olarak kullanmak için uygun hale getir
                  String projectId = projectName.trim().replaceAll(' ', '_').toLowerCase();

                  // Yeni projeyi oluştur
                  await _firestore
                      .collection('users')
                      .doc(widget.uid)
                      .collection('projects')
                      .doc(projectId) // Proje ID olarak düzenlenmiş proje ismi
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
                }
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
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
                        childAspectRatio: 1.2,
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
                                    uid: isOwner ? widget.uid : project['ownerId'],
                                    projectId: project['id'],
                                    projectName: project['name'],
                                  ),
                                ),
                              ).then((_) => _loadProjects());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          project['name'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!isOwner)
                                        const Tooltip(
                                          message: 'Davet edildiğiniz proje',
                                          child: Icon(
                                            Icons.people_outline,
                                            size: 20,
                                            color: Colors.blue,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Durum: ${project['status']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Oluşturulma: ${DateFormat('dd/MM/yyyy').format(project['createdAt'].toDate())}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
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
        onPressed: _showCreateProjectDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 