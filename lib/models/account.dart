class Account {
  final String id;
  final String name;
  final String accountHolderName;
  final String accountNumber;
  final String address;
  final String fee;

  Account({
    required this.id,
    required this.name,
    required this.accountHolderName,
    required this.accountNumber,
    required this.address,
    required this.fee,
  });

  factory Account.fromRow(List<String> data) => Account(
    id: data[0].padRight(24),
    name: data[1].padRight(35),
    accountHolderName: data[2].padRight(35),
    accountNumber: data[3].split('-').join().padRight(24),
    address: "${data[4]} ${data[5]} ${data[6]}".padRight(35),
    fee: data[7].padLeft(10, "0")
  );
}
