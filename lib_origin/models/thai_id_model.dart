class ThaiIDModel {
  final String id;
  final String thName;
  final String enName;
  final String birth;
  final String gender;
  final String issuer;
  final String issueDate;
  final String expireDate;
  final String address;
  final List<int> photo;

  ThaiIDModel({
    required this.id,
    required this.thName,
    required this.enName,
    required this.birth,
    required this.gender,
    required this.issuer,
    required this.issueDate,
    required this.expireDate,
    required this.address,
    required this.photo,
  });
}