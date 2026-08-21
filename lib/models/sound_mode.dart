class SoundMode {
  bool bellSound;
  bool thaiVoice;
  bool englishVoice; // รอพัฒนา
  bool readValues;   // รอพัฒนา

  SoundMode({
    this.bellSound = true,
    this.thaiVoice = true,
    this.englishVoice = false,
    this.readValues = false,
  });

  SoundMode copyWith({
    bool? bellSound,
    bool? thaiVoice,
    bool? englishVoice,
    bool? readValues,
  }) {
    return SoundMode(
      bellSound: bellSound ?? this.bellSound,
      thaiVoice: thaiVoice ?? this.thaiVoice,
      englishVoice: englishVoice ?? this.englishVoice,
      readValues: readValues ?? this.readValues,
    );
  }
}
