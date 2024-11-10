// habit_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Habit {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String tag;
  final int days;
  final Map<String, bool> completedDays;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.tag,
    required this.days,
    required this.completedDays,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'description': description,
    'tag': tag,
    'days': days,
    'completedDays': completedDays,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'],
    userId: json['userId'],
    title: json['title'],
    description: json['description'],
    tag: json['tag'],
    days: json['days'],
    completedDays: Map<String, bool>.from(json['completedDays']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}
