import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InvitationsPage extends StatefulWidget {
  final String userEmail;

  const InvitationsPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore'dan bekleyen davetleri çekiyoruz
  Stream<QuerySnapshot> _getInvitations() {
    return _firestore
        .collection('project_invitations')
        .where('email', isEqualTo: widget.userEmail)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> _handleInvitation(
      String invitationId, String projectId, bool accept) async {
    try {
      if (accept) {
        // 📌 Proje detaylarını al
        var projectDoc = await _firestore.collection('projects').doc(projectId).get();
        var projectData = projectDoc.data();

        if (projectData != null) {
          // 📌 Kullanıcının Firestore'daki ID'sini çek (e-posta ile arama yap)
          var userQuery = await _firestore
              .collection('users')
              .where('email', isEqualTo: widget.userEmail)
              .get();

          if (userQuery.docs.isNotEmpty) {
            String userId = userQuery.docs.first.id;

            // 📌 Kullanıcıyı projenin "teamMembers" listesine ekle
            await _firestore.collection('projects').doc(projectId).update({
              'teamMembers': FieldValue.arrayUnion([widget.userEmail])
            });

            // 📌 Kullanıcının kendi projects koleksiyonuna projeyi ekle
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('projects')
                .doc(projectId)
                .set({
              'name': projectData['name'],
              'createdAt': projectData['createdAt'],
              'status': projectData['status'],
              'ownerId': projectData['ownerId'],
            });
          }
        }
      }

      // 📌 Daveti güncelle (Kabul veya Reddet)
      await _firestore.collection('project_invitations').doc(invitationId).update({
        'status': accept ? 'accepted' : 'rejected'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'Davet kabul edildi' : 'Davet reddedildi')),
      );
    } catch (e) {
      print('Davet işleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proje Davetleri')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getInvitations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Bekleyen davetiniz bulunmuyor'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final invitation = snapshot.data!.docs[index];
              final data = invitation.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(data['projectName']),
                  subtitle: Text('Davet eden: ${data['ownerId']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _handleInvitation(
                          invitation.id,
                          data['projectId'],
                          true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _handleInvitation(
                          invitation.id,
                          data['projectId'],
                          false,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
