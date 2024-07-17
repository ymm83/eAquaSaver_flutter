part of 'mi_ubicacion_bloc.dart';

@immutable
class MiUbicacionState {

  final bool siguiendo;
  final bool existeUbicacion;

  MiUbicacionState({
    this.siguiendo = true,
    this.existeUbicacion = false,
  }); 

  MiUbicacionState copyWith({
    bool siguiendo,
    bool existeUbicacion,
  }) => new MiUbicacionState(
    siguiendo       : siguiendo ?? this.siguiendo,
    existeUbicacion : existeUbicacion ?? this.existeUbicacion,
  );
  

}
