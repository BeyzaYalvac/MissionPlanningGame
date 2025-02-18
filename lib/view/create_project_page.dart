import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:to_gram_grad_project/view/project_detail_page.dart';
import 'package:to_gram_grad_project/view/sprint_duration_page.dart';

class CreateProjectPage extends StatefulWidget {
  final String uid;
  final String userEmail;

  const CreateProjectPage({
    Key? key,
    required this.uid,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  
  String projectName = '';
  String projectDescription = '';
  String memberEmail = '';
  List<String> teamMembers = [];
  bool isLoading = false;
  int sprintDuration = 7; // Varsayılan olarak 7 gün
  String sprintDurationType = 'gün'; // 'gün' veya 'hafta'

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);

    try {
      // Projeyi ana projects koleksiyonunda oluştur
      DocumentReference projectRef = await _firestore.collection('projects').add({
        'name': projectName.trim(),
        'description': projectDescription.trim(),
        'createdAt': Timestamp.now(),
        'status': 'active',
        'ownerId': widget.uid,
        'teamMembers': [widget.userEmail], // Proje sahibini ekle
        'sprintDuration': sprintDuration,
        'sprintDurationType': sprintDurationType, // Yeni alanları ekleyin
      });

      // Projeyi kullanıcının projects koleksiyonuna ekle
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('projects')
          .doc(projectRef.id)
          .set({
        'name': projectName.trim(),
        'description': projectDescription.trim(),
        'createdAt': Timestamp.now(),
        'status': 'active',
        'ownerId': widget.uid,
      });

      // Takım üyelerine davetiye gönder
      for (String email in teamMembers) {
        await _firestore.collection('project_invitations').add({
          'projectId': projectRef.id,
          'projectName': projectName.trim(),
          'email': email,
          'ownerId': widget.userEmail,
          'status': 'pending',
          'createdAt': Timestamp.now(),
        });
      }

      // Sprint süre sayfasına yönlendir
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SprintDurationPage(),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proje oluşturulurken hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Proje Oluştur'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Proje Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Proje adı gereklidir';
                  }
                  return null;
                },
                onChanged: (value) => projectName = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Proje Açıklaması',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Proje açıklaması gereklidir';
                  }
                  return null;
                },
                onChanged: (value) => projectDescription = value,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Üye E-posta',
                        hintText: 'Üye e-posta adresi',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => memberEmail = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (memberEmail.isNotEmpty && memberEmail.contains('@')) {
                        setState(() {
                          teamMembers.add(memberEmail);
                          memberEmail = '';
                        });
                      }
                    },
                  ),
                ],
              ),
              if (teamMembers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Ekip Üyeleri:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: teamMembers.map((email) => Chip(
                    label: Text(email),
                    onDeleted: () {
                      setState(() {
                        teamMembers.remove(email);
                      });
                    },
                  )).toList(),
                ),
              ],
              const SizedBox(height: 24),
              const Text('Sprint Süresi:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: sprintDuration.toString(),
                      onChanged: (value) {
                        setState(() {
                          sprintDuration = int.tryParse(value) ?? 7;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: sprintDurationType,
                    items: const [
                      DropdownMenuItem(value: 'gün', child: Text('Gün')),
                      DropdownMenuItem(value: 'hafta', child: Text('Hafta')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        sprintDurationType = value ?? 'gün';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _createProject,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Projeyi Oluştur'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 