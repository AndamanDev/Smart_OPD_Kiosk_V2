class DisplayMode {
  final bool showResultColors;

  const DisplayMode({this.showResultColors = true});

  DisplayMode copyWith({bool? showResultColors}) {
    return DisplayMode(
      showResultColors: showResultColors ?? this.showResultColors,
    );
  }
}
