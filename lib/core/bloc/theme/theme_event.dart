sealed class ThemeEvent {
  const ThemeEvent();
}

class ToggleThemeEvent extends ThemeEvent {
  final bool isDark;
  const ToggleThemeEvent(this.isDark);
}
