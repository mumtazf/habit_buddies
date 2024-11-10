import 'package:bismillah_habitbuddy/controllers/user_controller.dart';
import 'package:bismillah_habitbuddy/pages/Login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bismillah_habitbuddy/pages/HabitsWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bismillah_habitbuddy/controllers/habit_controller.dart';
import 'package:bismillah_habitbuddy/pages/GroupDetails.dart';
import 'package:bismillah_habitbuddy/controllers/group_implementation.dart';

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override 
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage>{
User? currentUser;
Map<String, dynamic>? userData;

 @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchUserData();
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          currentUser = user;
        });
        if (user != null) {
          fetchUserData();
        }
      }
    });
  }

Future<void> fetchUserData() async {
    if (currentUser == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(UserController.user?.uid);
    final docSnapshot = await userDoc.get();
    if (docSnapshot.exists) {
      setState(() {
        userData = docSnapshot.data();
      });
    }
  }

  Widget _showGroupsList(){
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: currentUser?.uid)
          .snapshots(),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!groupSnapshot.hasData || groupSnapshot.data!.docs.isEmpty) {
            return Center(child: Text('No groups found.'));
        }

      final groups = groupSnapshot.data!.docs;

      return Container(
        color: Colors.grey[200],
        child: Column(
          children: [
             ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300),
             child: Image.asset('assets/team.jpeg')
             ),
            Expanded(
              child: ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Card(
                         color: Colors.blueGrey[50],
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          tileColor: Colors.white,
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              group['name']?.substring(0, 1) ?? '',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            group['name'] ?? 'No Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(group['description'] ?? 'No Description'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupDetailsScreen(groupId: groups[index].id),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
            ),
          ],
        ),
      );
  });
}
  Widget _buildHabitsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final listOfHabits = (userData?['listOfHabits'] as List<dynamic>?) ?? [];

        if (listOfHabits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No habits yet',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddHabitScreen()),
                    );
                  },
                  child: const Text('Create your first habit'),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('habits')
              .where(FieldPath.documentId, whereIn: listOfHabits)
              .snapshots(),
          builder: (context, habitsSnapshot) {
            if (habitsSnapshot.hasError) {
              return const Center(child: Text('Error loading habits'));
            }

            if (habitsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final habits = habitsSnapshot.data?.docs ?? [];

            return ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index].data() as Map<String, dynamic>;
                return HabitListItem(
                  habit: Habit.fromJson(habit),
                  onToggleDay: (habitId, date, completed) {
                    FirebaseFirestore.instance
                        .collection('habits')
                        .doc(habitId)
                        .update({
                      'completedDays.$date': completed,
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

@override
Widget build(BuildContext context){
  return Scaffold(
    appBar: AppBar(
        title: Text('My Habits'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddHabitScreen()),
              );
            },
          ),
        ],
      ),
    body:
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
          SizedBox(height: 120),

          CircleAvatar(
            radius: 50,
             foregroundImage: currentUser?.photoURL != null
                  ? NetworkImage(currentUser!.photoURL!)
                  : null,
              child: currentUser?.photoURL == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
          ),
          SizedBox(height: 50),

          Text(currentUser?.displayName ?? '',
          style: TextStyle(
                fontSize: 24, // Increase the font size
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateGroupScreen()),
                );
              },
              child: Text('Create Group'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JoinGroupScreen()),
                );
              },
              child: Text('Join Group'),
            ),

             ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => _showGroupsList()),
                );
              },
              child: Text('Show Groups I\'m a part of!'),
             ),

          SizedBox(height: 40),

          const Text("Your Habits"),
            Expanded(
              child: _buildHabitsList(),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  await UserController.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  }
                },
                child: const Text("Logout"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}