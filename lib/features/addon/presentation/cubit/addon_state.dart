import 'package:equatable/equatable.dart';
import '../../domain/entities/addon.dart';

abstract class AddonState extends Equatable {
  const AddonState();

  @override
  List<Object?> get props => [];
}

class AddonInitial extends AddonState {}

class AddonLoading extends AddonState {}

class AddonLoaded extends AddonState {
  final List<Addon> addons;

  const AddonLoaded(this.addons);

  @override
  List<Object?> get props => [addons];
}

class AddonFailure extends AddonState {
  final String message;

  const AddonFailure(this.message);

  @override
  List<Object?> get props => [message];
}

