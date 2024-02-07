class PersonDetails {
  final String membershipNumber;
  final String name;
  final String accountHolder;
  final String accountNumber;
  final String postalCode;
  final String city;
  final String address;
  final String fee;

  const PersonDetails(
    this.membershipNumber,
    this.name,
    this.accountHolder,
    this.accountNumber,
    this.postalCode,
    this.city,
    this.address,
    this.fee,
  );

  String get fullAddress => '$postalCode $city $address';
}
