/// Flag para mostrar una sola vez el SnackBar "Perfil completado correctamente"
/// al llegar a Home tras completar el onboarding (evita depender de query params
/// que el redirect puede quitar).
bool showProfileCompletedSnackBarPending = false;

void setProfileCompletedSnackBarPending() {
  showProfileCompletedSnackBarPending = true;
}

bool consumeProfileCompletedSnackBarPending() {
  final value = showProfileCompletedSnackBarPending;
  showProfileCompletedSnackBarPending = false;
  return value;
}
