// group_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bismillah_habitbuddy/controllers/group_implementation.dart';
import 'package:bismillah_habitbuddy/controllers/habit_controller.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String groupId;

  const GroupDetailsScreen({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Group Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .snapshots(),
        builder: (context, groupSnapshot) {
          if (groupSnapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (!groupSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final groupData = groupSnapshot.data!.data() as Map<String, dynamic>;
          final group = Group.fromJson(groupData);

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(group.description),
                    SizedBox(height: 16),
                    Text(
                      'Invite Code: ${group.inviteCode}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where(FieldPath.documentId, whereIn: group.members)
                      .snapshots(),
                  builder: (context, membersSnapshot) {
                    if (!membersSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final members = membersSnapshot.data!.docs;

                    return ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final memberData = 
                            members[index].data() as Map<String, dynamic>;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: memberData['photoURL'] != null
                                ? NetworkImage(memberData['photoURL'])
                                : null,
                            child: memberData['photoURL'] == null
                                ? Icon(Icons.person)
                                : null,
                          ),
                          title: Text(memberData['displayName'] ?? 'Unknown'),
                          subtitle: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('habits')
                                .where('userId', isEqualTo: members[index].id)
                                .snapshots(),
                            builder: (context, habitsSnapshot) {
                              if (!habitsSnapshot.hasData) {
                                return Text('Loading habits...');
                              }
                              
                              final habits = habitsSnapshot.data!.docs;
                              return Text(
                                '${habits.length} active habits',
                                style: TextStyle(color: Colors.grey),
                              );
                            },
                          ),
                          onTap: () {
                            // Show member's habits in a bottom sheet
                            showMemberHabits(context, members[index].id);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void showMemberHabits(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('habits')
                .where('userId', isEqualTo: userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final habits = snapshot.data!.docs;

              return ListView.builder(
                controller: scrollController,
                itemCount: habits.length,
                itemBuilder: (context, index) {
                  final habit = 
                      Habit.fromJson(habits[index].data() as Map<String, dynamic>);
                  return ListTile(
                    title: Text(habit.title),
                    subtitle: Text(habit.description),
                    trailing: Text('${habit.days} days'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}