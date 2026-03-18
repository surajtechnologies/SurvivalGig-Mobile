import 'package:equatable/equatable.dart';

/// Domain entity representing the current user location in home screen.
class CurrentLocation extends Equatable {
  final String city;
  final String pincode;

  const CurrentLocation({required this.city, required this.pincode});

  @override
  List<Object?> get props => [city, pincode];
}
