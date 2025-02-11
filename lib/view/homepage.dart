import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:to_gram_grad_project/view/projects_page.dart';

class HomePage extends StatefulWidget {
  final String uid;
  const HomePage({super.key, required this.uid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? userInfo;

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

        print("User data fetched successfully: $result");
      } else {
        print("User document does not exist!");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }


  @override
  void initState() {
    super.initState();
    getUserInfos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proje Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Bildirimler sayfasına yönlendirme
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Profil sayfasına yönlendirme
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
                  _buildStatCard('Aktif Projeler', '5', Colors.blue),
                  const SizedBox(width: 16),
                  _buildStatCard('Bekleyen Görevler', '12', Colors.orange),
                ],
              ),
              const SizedBox(height: 20),

              // Projeler başlığı
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
                      );
                    },
                    child: const Text('Tümünü Gör'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Proje listesi
              _buildProjectList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yeni proje ekleme sayfasına yönlendirme
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
            icon: Icon(Icons.chat),
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3, // Örnek olarak 3 proje gösteriyoruz
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Proje ${index + 1}'),
            subtitle: const Text('3 görev bekliyor'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Proje detay sayfasına yönlendirme
            },
          ),
        );
      },
    );
  }
}
