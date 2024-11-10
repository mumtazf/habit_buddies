import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math'; //for random number gen

class Group {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> members;
  final DateTime createdAt;
  final String? inviteCode;  //i will generate a random invite code

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.members,
    required this.createdAt,
    this.inviteCode,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['createdBy'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      inviteCode: json['inviteCode'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'createdBy': createdBy,
    'members': members,
    'createdAt': Timestamp.fromDate(createdAt),
    'inviteCode': inviteCode,
  };
}

// create_group_screen.dart
class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        //generating a random invite code
        final inviteCode = generateInviteCode();
        
        //creating group document in firebase
        final groupRef = FirebaseFirestore.instance.collection('groups').doc();
        final group = Group(
          id: groupRef.id,
          name: _nameController.text,
          description: _descriptionController.text,
          createdBy: user.uid,
          members: [user.uid],  
          createdAt: DateTime.now(),
          inviteCode: inviteCode,
        );

        // Start a batch write
        final batch = FirebaseFirestore.instance.batch();

        // Create the group
        batch.set(groupRef, group.toJson());

        // Update user's groups list
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(user.uid),
          {
            'groups': FieldValue.arrayUnion([groupRef.id])
          }
        );

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group created! Invite code: $inviteCode'))
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error creating group: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create group'))
          );
        }
      }
    }
  }

  String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Group')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a group name' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createGroup,
              child: Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}

// join_group_screen.dart
class JoinGroupScreen extends StatefulWidget {
  @override
  _JoinGroupScreenState createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  Future<void> _joinGroup() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Find group by invite code
        final groupQuery = await FirebaseFirestore.instance
            .collection('groups')
            .where('inviteCode', isEqualTo: _codeController.text.toUpperCase())
            .get();

        if (groupQuery.docs.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid invite code'))
            );
          }
          return;
        }

        final groupDoc = groupQuery.docs.first;
        final groupId = groupDoc.id;
        final groupData = groupDoc.data();
        
        // Check if user is already a member
        if ((groupData['members'] as List).contains(user.uid)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are already a member of this group'))
            );
          }
          return;
        }

        // Start a batch write
        final batch = FirebaseFirestore.instance.batch();

        // Add user to group members
        batch.update(
          FirebaseFirestore.instance.collection('groups').doc(groupId),
          {
            'members': FieldValue.arrayUnion([user.uid])
          }
        );

        // Add group to user's groups list
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(user.uid),
          {
            'groups': FieldValue.arrayUnion([groupId])
          }
        );

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully joined group!'))
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error joining group: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to join group'))
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Group')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Invite Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter the invite code' : null,
                textCapitalization: TextCapitalization.characters,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _joinGroup,
                child: Text('Join Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}