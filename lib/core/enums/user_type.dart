enum UserType {
  cuidador,
  familiar;

  static UserType fromString(String? value) {
    if (value == 'cuidador') return UserType.cuidador;
    return UserType.familiar;
  }

  String toShortString() {
    return toString().split('.').last;
  }
}
