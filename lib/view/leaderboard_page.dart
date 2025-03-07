import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardPage extends StatefulWidget {
  final String uid;

  const LeaderboardPage({super.key, required this.uid});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> userScores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    calculateUserScores();
  }

  Future<void> calculateUserScores() async {
    try {
      setState(() => isLoading = true);
      print('Veri yükleme başladı');
      
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .get();
      
      print('Bulunan toplam proje sayısı: ${projectsSnapshot.docs.length}');
      
      Map<String, int> scoreMap = {};
      Map<String, String> userNames = {};

      for (var projectDoc in projectsSnapshot.docs) {
        print('İşlenen proje ID: ${projectDoc.id}');
        
        final tasksSnapshot = await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectDoc.id)
            .collection('tasks')
            .where('status', isEqualTo: 'done')
            .get();
        
        print('Proje ${projectDoc.id} için bulunan done task sayısı: ${tasksSnapshot.docs.length}');

        for (var taskDoc in tasksSnapshot.docs) {
          String? assignedToId = taskDoc.data()['assignedToId'];
          String? assignedTo = taskDoc.data()['assignedTo'];
          
          print('Task bilgileri:');
          print('AssignedToId: $assignedToId');
          print('AssignedTo: $assignedTo');
          print('Task Data: ${taskDoc.data()}');

          if (assignedToId == null || assignedToId.isEmpty) {
            if (assignedTo != null && assignedTo.isNotEmpty) {
              final userQuery = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: assignedTo)
                  .limit(1)
                  .get();
              
              if (userQuery.docs.isNotEmpty) {
                assignedToId = userQuery.docs.first.id;
              }
            }
          }

          if (assignedToId != null && assignedToId.isNotEmpty) {
            print('Task atanan kullanıcı ID: $assignedToId');
            
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(assignedToId)
                .get();
            
            if (userDoc.exists) {
              userNames[assignedToId] = userDoc.data()?['username'] ?? 
                                      userDoc.data()?['email'] ?? 
                                      'İsimsiz Kullanıcı';
              
              int difficulty = taskDoc.data()['difficulty'] ?? 1;
              
              scoreMap[assignedToId] = (scoreMap[assignedToId] ?? 0) + difficulty;
              
              print('Kullanıcı ${userNames[assignedToId]} için eklenen puan: $difficulty');
            }
          } else {
            print('Task için geçerli bir kullanıcı ID\'si bulunamadı');
          }
        }
      }

      print('Toplam skor haritası: $scoreMap');
      print('Kullanıcı isimleri: $userNames');

      List<Map<String, dynamic>> sortedUsers = scoreMap.entries.map((entry) {
        return {
          'userId': entry.key,
          'username': userNames[entry.key],
          'score': entry.value,
        };
      }).toList();

      sortedUsers.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      setState(() {
        userScores = sortedUsers;
        isLoading = false;
      });
      
      print('İşlem tamamlandı. Toplam kullanıcı sayısı: ${sortedUsers.length}');
    } catch (e, stackTrace) {
      print('Hata: $e');
      print('Stack trace: $stackTrace');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liderlik Tablosu'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: userScores.length,
              itemBuilder: (context, index) {
                final user = userScores[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getLeaderColor(index),
                      child: Text('${index + 1}'),
                    ),
                    title: Text(user['username'] ?? 'İsimsiz Kullanıcı'),
                    trailing: Text(
                      '${user['score']} puan',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getLeaderColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Altın
      case 1:
        return Colors.grey[300]!; // Gümüş
      case 2:
        return Colors.brown[300]!; // Bronz
      default:
        return Colors.blue[100]!;
    }
  }
} 