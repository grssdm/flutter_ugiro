import 'dart:html';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ugiro/my_button.dart';
import 'package:flutter_ugiro/my_text_field.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'models/account.dart';

class HomePage extends StatefulWidget {
  final PackageInfo packageInfo;

  const HomePage(this.packageInfo, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _taxNumberController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _associationController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _delayController = TextEditingController();

  final ValueNotifier<DateTime> _debitDate = ValueNotifier(DateTime.now());
  final ValueNotifier<Excel?> _excelFile = ValueNotifier(null);
  final ValueNotifier<bool> _isProcessAllowed = ValueNotifier(false);

  void _isProcessAllowedListener() {
    if (_taxNumberController.text.isEmpty ||
        _bankAccountController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _associationController.text.isEmpty ||
        _commentController.text.isEmpty ||
        _excelFile.value == null) {
      _isProcessAllowed.value = false;
    } else {
      _isProcessAllowed.value = true;
    }
  }

  @override
  void initState() {
    super.initState();

    _delayController.text = '8';

    _taxNumberController.addListener(_isProcessAllowedListener);
    _bankAccountController.addListener(_isProcessAllowedListener);
    _titleController.addListener(_isProcessAllowedListener);
    _associationController.addListener(_isProcessAllowedListener);
    _commentController.addListener(_isProcessAllowedListener);

    _excelFile.addListener(_isProcessAllowedListener);
  }

  Future<void> _openFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'xlsx',
        'xls',
      ],
    );

    if (result != null) {
      _excelFile.value = Excel.decodeBytes(result.files.first.bytes!);
    }
  }

  List<Account> _checkFileData(Excel excel) {
    List<Account> accounts = [];
    for (var (i, row) in excel.tables.values.first.rows.indexed) {
      if (i == 0) continue;
      var data = row.map((cell) => cell!.value.toString()).toList();
      var account = Account.fromRow(data);

      if (account.id.length > 24) {
        throw Exception("[${i + 1}. sor] 24 karakternél hosszabb a tagszám!");
      }
      if (account.name.length > 35) {
        throw Exception(
            "[${i + 1}. sor] 35 karakternél hosszabb az ügyfél neve!");
      }
      if (account.accountHolderName.length > 35) {
        throw Exception(
            "[${i + 1}. sor] 35 karakternél hosszabb a számlatulajdonos neve!");
      }
      if (account.accountNumber.length > 24) {
        throw Exception(
            "[${i + 1}. sor] 24 karakternél hosszabb a bankszámlaszám!");
      }
      if (account.id.length > 35) {
        throw Exception("[${i + 1}. sor] 35 karakternél hosszabb a cím!");
      }
      if (account.fee.length > 10) {
        throw Exception("[${i + 1}. sor] 10 karakternél hosszabb a díj!");
      }

      accounts.add(account);
    }

    return accounts;
  }

  void _buildGiroFile(
    String headRecordType,
    String messageType,
    String duplumCode,
    String taxNumber,
    String compilationDate,
    String number,
    String accountNumber,
    String notificationDateLine,
    String title,
    String organization,
    String headComment,
    String itemRecordType,
    String itemComment,
    List<Account> accounts,
    String footerRecordType,
  ) {
    List<String> outputLines = [];
    String head = headRecordType +
        messageType +
        duplumCode +
        taxNumber.padRight(13) +
        compilationDate +
        number.padLeft(4, "0") +
        accountNumber.padRight(24) +
        notificationDateLine +
        title.padRight(3) +
        organization.padRight(35) +
        headComment.padRight(70) +
        '\n';

    outputLines.add(head);

    int sum = 0;

    for (var (i, account) in accounts.indexed) {
      outputLines.add(
        itemRecordType +
            (i + 1).toString().padLeft(6, '0') +
            notificationDateLine +
            account.fee +
            account.accountNumber +
            account.id +
            account.name +
            account.address +
            account.accountHolderName +
            itemComment.padRight(70) +
            '\n',
      );
      sum += int.parse(account.fee);
    }

    String footer = footerRecordType +
        accounts.length.toString().padLeft(6, '0') +
        sum.toString().padLeft(16, '0') +
        '\n';

    outputLines.add(footer);

    // Create a Blob with the file contents
    final blob = Blob(outputLines, 'text/plain');

    // Create an anchor element with a download attribute to trigger the download
    final anchor = AnchorElement(href: Url.createObjectUrlFromBlob(blob))
      ..setAttribute("download", "ugiro-file.cbe")
      ..click();

    // Clean up the URL created for the blob
    Url.revokeObjectUrl(anchor.href!);
  }

  void _process() {
    try {
      List<Account> accounts = _checkFileData(_excelFile.value!);

      _buildGiroFile(
        '01',
        'BESZED',
        '0',
        _taxNumberController.text,
        DateFormat('yyyyMMdd')
            .format(_debitDate.value.subtract(const Duration(days: 1))),
        '1',
        _bankAccountController.text,
        DateFormat('yyyyMMdd').format(_debitDate.value),
        _titleController.text,
        _associationController.text,
        '',
        '02',
        _commentController.text,
        accounts,
        '03',
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Hiba'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _downloadSample() async {
    // Create an anchor element with a download attribute to trigger the download
    final anchor = AnchorElement(href: 'assets/csoportos-beszedes-minta.xlsx')
      ..setAttribute("download", "csoportos-beszedes-minta.xlsx")
      ..click();

    // Clean up the URL created for the blob
    Url.revokeObjectUrl(anchor.href!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ugiro',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0.0,
        padding: EdgeInsets.zero,
        height: 24.0,
        child: Center(
          child: Text('v${widget.packageInfo.version}'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth > 700.0
                  ? 500.0
                  : MediaQuery.of(context).size.width * 0.85,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 64.0,
                      ),
                      MyTextField(
                        controller: _taxNumberController,
                        keyboardType: TextInputType.text,
                        hintText: 'A########',
                        label: 'Adóazonosító',
                      ),
                      MyTextField(
                        controller: _bankAccountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        hintText: '########-########-########',
                        label: 'Bankszámlaszám',
                      ),
                      MyTextField(
                        controller: _titleController,
                        keyboardType: TextInputType.text,
                        hintText: 'EGY',
                        label: 'Jogcím',
                      ),
                      MyTextField(
                        controller: _associationController,
                        keyboardType: TextInputType.text,
                        hintText: 'PSZHVSZ',
                        label: 'Szervezet neve',
                      ),
                      MyTextField(
                        controller: _commentController,
                        keyboardType: TextInputType.text,
                        hintText: 'PSZHVSZ tagdíj',
                        label: 'Megjegyzés',
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            flex: 1,
                            child: ValueListenableBuilder<DateTime>(
                              valueListenable: _debitDate,
                              builder: (_, DateTime debitDate, __) =>
                                  ElevatedButton(
                                onPressed: () async {
                                  DateTime? dateTime = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate:
                                        DateTime(DateTime.now().year + 50),
                                  );

                                  if (dateTime != null) {
                                    _debitDate.value = dateTime;
                                  }
                                },
                                child: Text(
                                  'Terhelés dátuma: ${DateFormat('yyyy.MM.dd').format(debitDate)}',
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: TextFormField(
                                      controller: _delayController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  flex: 4,
                                  child: Text(' nappal korábban'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _downloadSample,
                        child: const Text('Minta .xlsx fájl letöltése'),
                      ),
                      MyButton(
                        onPressed: _openFilePicker,
                        title: 'Excel fájl kiválasztása',
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isProcessAllowed,
                        builder: (_, isProcessAllowed, __) => MyButton(
                          onPressed: isProcessAllowed ? _process : null,
                          title: 'Indítás',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
