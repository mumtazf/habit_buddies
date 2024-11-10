import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bismillah_habitbuddy/controllers/habit_controller.dart';

class AddHabitScreen extends StatefulWidget {
  @override
  _AddHabitScreenState createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedTag = 'Health';
  int _selectedDays = 21;

  final List<String> _tags = ['Health', 'Fitness', 'Study', 'Work', 'Personal'];
  final List<int> _dayOptions = [7, 21, 30, 60, 90];

  Future<void> _submitHabit() async {
  if (_formKey.currentState!.validate()) {
    try {
      final user = FirebaseAuth.instance.currentUser; //if the user is logged in
      if (user == null) return;

      final habitId = FirebaseFirestore.instance.collection('habits').doc().id;

      final habit = Habit(
        id: habitId,  
        userId: user.uid,
        title: _titleController.text,
        description: _descriptionController.text,
        tag: _selectedTag,
        days: _selectedDays,
        completedDays: {},
        createdAt: DateTime.now(),
      );

      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        FirebaseFirestore.instance.collection('habits').doc(habitId),
        habit.toJson()
      );

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {
          'listOfHabits': FieldValue.arrayUnion([habitId])
        }
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit created successfully!'))
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error creating habit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create habit. Please try again.'))
        );
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Habit'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Habit Name',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a habit name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTag,
                decoration: InputDecoration(
                  labelText: 'Tag',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                items: _tags.map((tag) {
                  return DropdownMenuItem(
                    value: tag,
                    child: Text(tag),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTag = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedDays,
                decoration: InputDecoration(
                  labelText: 'Number of Days',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                items: _dayOptions.map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text('$days days'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDays = value!;
                  });
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitHabit,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Create Habit'),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// habit_list_item.dart
class HabitListItem extends StatelessWidget {
  final Habit habit;
  final Function(String, String, bool) onToggleDay;

  const HabitListItem({
    Key? key,
    required this.habit,
    required this.onToggleDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    habit.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(habit.tag),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              ],
            ),
            if (habit.description.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(habit.description),
            ],
            SizedBox(height: 16),
            Text(
              'Progress',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            _buildHeatmap(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    final today = DateTime.now();
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: habit.days,
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: habit.days - 1 - index));
          final dateString = date.toIso8601String().split('T')[0];
          final isCompleted = habit.completedDays[dateString] ?? false;

          return GestureDetector(
            onTap: () => onToggleDay(habit.id, dateString, !isCompleted),
            child: Container(
              width: 30,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isCompleted ? Colors.white : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}