import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final String uid;

  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userInfo;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userInfo = userDoc.data();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgileri alınırken hata oluştu')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil resmi yükleniyor...')),
      );

      // Dosya yolu oluştur - uid'yi dosya adına ekleyelim
      final String fileName = 'profile_${widget.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(widget.uid) // Kullanıcıya özel klasör
          .child(fileName);

      // Dosyayı yükle
      final File imageFile = File(image.path);
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': widget.uid},
        ),
      );

      // Yükleme tamamlanana kadar bekle ve sonucu al
      final TaskSnapshot taskSnapshot = await uploadTask;
      
      // URL'i al
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Firestore'u güncelle
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'profileImageUrl': downloadUrl});

      await getUserInfo();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil resmi başarıyla güncellendi')),
      );

    } catch (e) {
      print('Hata detayı: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil resmi yüklenirken bir hata oluştu')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Fotoğraf Çek'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: userInfo == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: userInfo!['profileImageUrl'] != null
                            ? NetworkImage(userInfo!['profileImageUrl'])
                            : null,
                        child: userInfo!['profileImageUrl'] == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard('Kullanıcı Adı', userInfo!['username'] ?? 'Belirtilmemiş'),
                  _buildInfoCard('E-posta', userInfo!['email'] ?? 'Belirtilmemiş'),
                  _buildInfoCard('Oluşturulma Tarihi', 
                    userInfo!['createdAt'] != null 
                      ? (userInfo!['createdAt'] as Timestamp).toDate().toString()
                      : 'Belirtilmemiş'
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 