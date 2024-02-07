import 'dart:html';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ugiro/my_button.dart';
import 'package:flutter_ugiro/my_text_field.dart';
import 'package:flutter_ugiro/person_details.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _taxNumberController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _associationController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _delayController = TextEditingController();

  final ValueNotifier<DateTime> _debitDate = ValueNotifier(DateTime.now());
  final ValueNotifier<PlatformFile?> _selectedFile = ValueNotifier(null);
  final ValueNotifier<bool> _isProcessAllowed = ValueNotifier(false);

  void _isProcessAllowedListener() {
    if (_taxNumberController.text.isEmpty ||
        _bankAccountController.text.isEmpty ||
        _associationController.text.isEmpty ||
        _commentController.text.isEmpty ||
        _selectedFile.value == null) {
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
    _associationController.addListener(_isProcessAllowedListener);
    _commentController.addListener(_isProcessAllowedListener);

    _selectedFile.addListener(_isProcessAllowedListener);
  }

  Future<void> _openFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      _selectedFile.value = result.files.first;
    }
  }

  void _process() {
    final csvContent =
        String.fromCharCodes(_selectedFile.value!.bytes!).split('\n');

    final List<PersonDetails> people = [];

    for (final (i, line) in csvContent.indexed) {
      if (i == csvContent.length - 1) {
        break;
      }

      List<String> lineComponents = line.split(';');

      people.add(
        PersonDetails(
          lineComponents[0].trim(),
          lineComponents[1].trim(),
          lineComponents[2].trim(),
          lineComponents[3].trim().split('-').join(''),
          lineComponents[4].trim(),
          lineComponents[5].trim(),
          lineComponents[6].trim(),
          lineComponents[7].trim(),
        ),
      );
    }

    List<String> outputLines = [];
    String line = ('01' +
                'BESZED' +
                '0' +
                _taxNumberController.text.padRight(13, ' ') +
                DateFormat('yyyyMMdd').format(
                  _debitDate.value.subtract(
                    Duration(days: int.parse(_delayController.text)),
                  ),
                ) +
                '0001' +
                _bankAccountController.text.padRight(24, ' ') +
                DateFormat('yyyyMMdd').format(_debitDate.value) +
                _associationController.text)
            .padRight(174, ' ') +
        '\n';

    outputLines.add(line);

    int sum = 0;

    for (int i = 0; i < people.length; i++) {
      line = ('02' +
                  (i + 1).toString().padLeft(6, '0') +
                  DateFormat('yyyyMMdd').format(_debitDate.value) +
                  people[i].fee.padLeft(10, '0') +
                  people[i].accountNumber.padRight(24, ' ') +
                  people[i].membershipNumber.padRight(24, ' ') +
                  people[i].name.padRight(35, ' ') +
                  people[i].fullAddress.padRight(35, ' ') +
                  people[i].name.padRight(35, ' ') +
                  _commentController.text.padRight(70, ' '))
              .padRight(249, ' ') +
          '\n';
      outputLines.add(line);
      sum += int.parse(people[i].fee);
    }

    line = '03' +
        people.length.toString().padLeft(6, '0') +
        sum.toString().padLeft(16, '0');
    outputLines.add(line);
    outputLines.add('\n');

    // Create a Blob with the file contents
    final blob = Blob(outputLines, 'text/plain');

    // Create an anchor element with a download attribute to trigger the download
    final anchor = AnchorElement(href: Url.createObjectUrlFromBlob(blob))
      ..setAttribute(
          "download", "${_selectedFile.value!.name.split('.').first}.txt")
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
                        controller: _associationController,
                        keyboardType: TextInputType.text,
                        hintText: 'EGYPSZHVSZ',
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
                      MyButton(
                        onPressed: _openFilePicker,
                        title: 'CSV kiválasztása',
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
