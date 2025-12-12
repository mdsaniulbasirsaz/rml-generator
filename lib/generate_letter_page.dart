import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';     // ← NEW
import 'package:intl/intl.dart';                       // ← NEW
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Color Palette
const Color primaryBlue = Color(0xFF1976D2);
const Color accentYellow = Color(0xFFFFC107);
const Color actionRed = Color(0xFFE53935);

class GenerateLetterPage extends StatefulWidget {
  const GenerateLetterPage({super.key});

  @override
  State<GenerateLetterPage> createState() => _GenerateLetterPageState();
}

class _GenerateLetterPageState extends State<GenerateLetterPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers (unchanged)
  final TextEditingController _nameCtrl = TextEditingController(text: "John Doe");
  final TextEditingController _universityCtrl = TextEditingController(text: "University of Cambridge");
  final TextEditingController _knownCtrl = TextEditingController(text: "through his exceptional research work");
  final TextEditingController _courseTaughtCtrl = TextEditingController(text: "Advanced Computer Networks, Network Security");
  final TextEditingController _knownDurationCtrl = TextEditingController(text: "3 years (2022-2025)");
  final TextEditingController _researchTitleCtrl = TextEditingController(
      text: "SDN-enabled IoT-based transport layer DDoS attack detection using Recurrent Neural Networks");
  final TextEditingController _salutationCtrl = TextEditingController(text: "Dear Admissions Committee");

  String _knownBy = 'Research';
  String _recommendedFor = 'PhD';

  Uint8List? _pdfBytes;
  Uint8List? _logoImage;
  Uint8List? _signatureImage;        // ← NEW: Signature image

  final List<String> _knownByOptions = ['Research', 'Class', 'Supervision', 'Department Student'];
  final List<String> _recommendedForOptions = ['BSc', 'MSc', 'MPhil', 'PhD', 'PostDoc', 'Faculty Position', 'Research Fellowship', 'Internship', 'Job Position'];

  static const String _logoUrl = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTcNl2v55ROw-DZ9Kw7P8oYT1Xirbie2DJCvw&s';

  // --- Date Formatting (Only date, no time) ---
  final now = DateTime.now();
  String get dateFormatted => DateFormat('dd MMMM, yyyy').format(now); // Example: 08 December, 2025


  @override
  void initState() {
    super.initState();
    _initializeData();
    _addTextListeners();
  }

  void _addTextListeners() {
    void listener() => _updatePdfPreview();
    _nameCtrl.addListener(listener);
    _universityCtrl.addListener(listener);
    _knownCtrl.addListener(listener);
    _courseTaughtCtrl.addListener(listener);
    _knownDurationCtrl.addListener(listener);
    _researchTitleCtrl.addListener(listener);
    _salutationCtrl.addListener(listener);
  }

  Future<void> _initializeData() async {
    await _loadLogoFromUrl();
    _updatePdfPreview();
  }

  // ────────────────────── NEW: Signature Picker ──────────────────────
  Future<void> _pickSignature() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _signatureImage = bytes;
      });
      _updatePdfPreview();
    }
  }

  // ────────────────────── Logo Loading (unchanged) ──────────────────────
  Future<void> _loadLogoFromUrl() async {
    try {
      final response = await http.get(Uri.parse(_logoUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty && _isValidImage(response.bodyBytes)) {
        setState(() => _logoImage = response.bodyBytes);
        return;
      }
    } catch (e) {
      debugPrint('Logo load failed: $e');
    }
    final fallback = await _generateFallbackLogo();
    setState(() => _logoImage = fallback);
  }

  bool _isValidImage(Uint8List bytes) {
    if (bytes.length < 4) return false;
    final header = bytes.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return header.startsWith('ffd8ffe') || // JPEG
        header.startsWith('89504e47') || // PNG
        header.startsWith('52494646'); // WEBP
  }

  Future<Uint8List> _generateFallbackLogo() async {
    const size = 440.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bgPaint = Paint()..color = primaryBlue;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, size, size), const Radius.circular(20)), bgPaint);

    textPainter.text = const TextSpan(text: 'CSNL', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900));
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2 - 10));

    textPainter.text = const TextSpan(text: 'JUST', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold));
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2 + 20));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _universityCtrl.dispose();
    _knownCtrl.dispose();
    _courseTaughtCtrl.dispose();
    _knownDurationCtrl.dispose();
    _researchTitleCtrl.dispose();
    _salutationCtrl.dispose();
    super.dispose();
  }

  void _updatePdfPreview() {
    _generatePdfDocument().then((bytes) {
      if (mounted) setState(() => _pdfBytes = bytes);
    });
  }

  Map<String, String> _getLetterTemplate() {
    final name = _nameCtrl.text;
    final program = _recommendedFor;
    final university = _universityCtrl.text;
    final known = _knownCtrl.text;
    final duration = _knownDurationCtrl.text;
    final course = _courseTaughtCtrl.text;
    final researchTitle = _researchTitleCtrl.text;

    return switch (_knownBy) {
      'Research' => {
          'intro': "I am writing to provide my strongest recommendation for $name's application for the $program program at $university. I have had the privilege of working closely with $name $known over the past $duration, during which time I have been consistently impressed by their exceptional research abilities and intellectual curiosity.",
          'body1': 'During our research collaboration, $name demonstrated outstanding analytical skills and independent thinking. Their work on "$researchTitle" was exemplary, showing proficiency in ${course.isNotEmpty ? course : 'advanced topics'}.',
          'body2': '$name possesses technical expertise, creativity, and perseverance essential for advanced research. They consistently showed initiative and self-motivation.',
          'conclusion': 'I give $name my highest recommendation without reservation.'
        },
      'Class' => {
          'intro': 'I am pleased to recommend $name, a former student in my ${course.isNotEmpty ? course : 'courses'} $known for $duration.',
          'body1': 'Throughout the course(s), $name demonstrated exceptional academic performance, active participation, and deep understanding of complex topics.',
          'body2': '$name excelled in assignments and projects, showing strong analytical and collaborative skills.',
          'conclusion': 'I am confident $name will excel in the $program program.'
        },
      'Supervision' => {
          'intro': 'I enthusiastically recommend $name for the $program program at $university. As their academic supervisor $known, I observed their growth over $duration.',
          'body1': 'Under my guidance, $name completed high-quality work with independence, rigor, and excellent communication skills.',
          'body2': 'They were highly receptive to feedback while contributing original ideas.',
          'conclusion': '$name is fully prepared for advanced graduate study.'
        },
      _ => {
          'intro': 'I am pleased to recommend $name for the $program program at $university. As a faculty member, I have known $name $known for $duration.',
          'body1': '$name has been an outstanding student with strong academic performance and exemplary character.',
          'body2': 'They are respected for integrity, collaboration, and passion for learning.',
          'conclusion': '$name will be an excellent addition to your program.'
        },
    };
  }

  // ────────────────────── PDF Generation (now with signature + date footer) ──────────────────────
  Future<Uint8List> _generatePdfDocument() async {
  final pdf = pw.Document();
  final regular = pw.Font.times();
  final bold = pw.Font.timesBold();
  final italic = pw.Font.timesItalic();
  final template = _getLetterTemplate();

  final now = DateTime.now();
  final dateFormatted = DateFormat('dd MMMM yyyy, HH:mm').format(now);

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(60),
    build: (_) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // === Header (unchanged) ===
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 20),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 2))),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (_logoImage != null)
                pw.Image(pw.MemoryImage(_logoImage!), width: 90, height: 90)
              else
                pw.Container(width: 90, height: 90, color: PdfColors.blue, child: pw.Center(child: pw.Text('LOGO', style: pw.TextStyle(color: PdfColors.white, font: bold)))),
              pw.SizedBox(width: 25),
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                  pw.Text('Department of Computer Science and Engineering (CSE)', style: pw.TextStyle(font: bold, fontSize: 14)),
                  pw.Text('Jashore University of Science and Technology (JUST)', style: pw.TextStyle(font: regular, fontSize: 13)),
                  pw.Text('Jashore - 7408, Bangladesh', style: pw.TextStyle(font: regular, fontSize: 13)),
                  pw.SizedBox(height: 8),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                    pw.Text('Email: n.amin@just.edu.bd', style: pw.TextStyle(font: regular, fontSize: 12)),
                    pw.SizedBox(width: 20),
                    pw.Text('Phone: +880 01714 - 492550', style: pw.TextStyle(font: regular, fontSize: 12)),
                  ]),
                  pw.SizedBox(height: 6),
                  pw.Text('https://www.cse.just.edu.bd', style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColors.blue900)),
                ]),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // --- PDF RichText for Date ---
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Left Side → Ref
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'Ref: ',
                    style: pw.TextStyle(font: bold, fontSize: 12),
                  ),
                  pw.TextSpan(
                    text: 'CSRL-227${100 + Random().nextInt(900)}',
                    style: pw.TextStyle(font: regular, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Right Side → Date
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'Date: ',
                    style: pw.TextStyle(font: bold, fontSize: 12),
                  ),
                  pw.TextSpan(
                    text: DateFormat('EEEE, MMMM d, yyyy').format(now),
                    style: pw.TextStyle(font: regular, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),




        pw.SizedBox(height: 25),
        pw.Center(child: pw.Text('Letter of Recommendation', style: pw.TextStyle(font: bold, fontSize: 20))),
        pw.SizedBox(height: 30),
        pw.Text('${_salutationCtrl.text},', style: pw.TextStyle(font: regular, fontSize: 12)),
        pw.SizedBox(height: 20),

        // Body paragraphs
        ...['intro', 'body1', 'body2', 'conclusion'].map((key) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 16),
              child: pw.RichText(
                text: pw.TextSpan(
                  style: pw.TextStyle(font: regular, fontSize: 12, height: 1.8),
                  children: _buildRichTextSpans(template[key]!, [_nameCtrl.text, _researchTitleCtrl.text], bold, regular),
                ),
                textAlign: pw.TextAlign.justify,
              ),
            )),

        pw.Paragraph(
          text: 'Should you require any additional information, please do not hesitate to contact me.',
          style: pw.TextStyle(font: regular, fontSize: 12, height: 1.8),
          textAlign: pw.TextAlign.justify,
        ),

        pw.Spacer(),

        // ───── SIGNATURE & SIGN-OFF (UPDATED) ─────
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Sincerely,', style: pw.TextStyle(font: bold, fontSize: 12)),

          // Signature image directly below "Sincerely,"
          if (_signatureImage != null) ...[
            pw.SizedBox(height: 10),

            // LEFT aligned signature image
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Image(
                pw.MemoryImage(_signatureImage!),
                width: 100,  // realistic signature width
                height: 40,  // small height for signature
                fit: pw.BoxFit.contain,
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          // Name and designation
          pw.SizedBox(height: _signatureImage != null ? 10 : 10),
          pw.Text('Dr. Mohammad Nowsin Amin Sheikh', style: pw.TextStyle(font: bold, fontSize: 13)),
          pw.Text('Assistant Professor', style: pw.TextStyle(font: regular, fontSize: 12)),
          pw.Text('Department of Computer Science and Engineering', style: pw.TextStyle(font: regular, fontSize: 12)),
          pw.Text('Jashore University of Science and Technology (JUST)', style: pw.TextStyle(font: regular, fontSize: 12)),
          pw.Text('Jashore-7408, Bangladesh', style: pw.TextStyle(font: regular, fontSize: 12)),
        ]),

        pw.SizedBox(height: 30),

        // Footer with date
        // pw.Container(
        //   padding: const pw.EdgeInsets.only(top: 12),
        //   decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1.5))),
        //   child: pw.Center(
        //     child: pw.Text(
        //       'Generated on: $dateFormatted',
        //       style: pw.TextStyle(font: italic, fontSize: 9, color: PdfColors.grey700),
        //     ),
        //   ),
        // ),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(width: 1.5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start, // bottom text left align
            children: [

              // // RIGHT aligned date
              // pw.Row(
              //   mainAxisAlignment: pw.MainAxisAlignment.end,
              //   children: [
              //     pw.Text(
              //       'Generated on: $dateFormatted',
              //       style: pw.TextStyle(
              //         font: italic,
              //         fontSize: 10,
              //         color: PdfColors.grey700,
              //       ),
              //     ),
              //   ],
              // ),r
              // LEFT aligned contact info
              pw.Text(
                'Email: n.amin@just.edu.bd,  Phone: +880 01714-492550, '
                'Kazi Nazrul Islam Academic Building, Room No: 227, Jashore University of Science and Technology, Jashore 7408, Bangladesh',
                style: pw.TextStyle(
                  font: regular,
                  fontSize: 10,
                  color: PdfColors.grey800,
                ),
              ),
              // RIGHT aligned date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Generated on: $dateFormatted',
                    style: pw.TextStyle(
                      font: italic,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

      ],
    ),
  ));

  return pdf.save();
}

  List<pw.TextSpan> _buildRichTextSpans(String text, List<String> boldWords, pw.Font boldFont, pw.Font regularFont) {
    final spans = <pw.TextSpan>[];
    var remaining = text;

    while (remaining.isNotEmpty) {
      int earliest = -1;
      String? match;
      for (final word in boldWords.where((w) => w.isNotEmpty)) {
        final idx = remaining.indexOf(word);
        if (idx != -1 && (earliest == -1 || idx < earliest)) {
          earliest = idx;
          match = word;
        }
      }
      if (match == null) {
        spans.add(pw.TextSpan(text: remaining, style: pw.TextStyle(font: regularFont)));
        break;
      }
      if (earliest > 0) spans.add(pw.TextSpan(text: remaining.substring(0, earliest), style: pw.TextStyle(font: regularFont)));
      spans.add(pw.TextSpan(text: match, style: pw.TextStyle(font: boldFont)));
      remaining = remaining.substring(earliest + match.length);
    }
    return spans;
  }

  // ────────────────────── UI: Form with Signature Upload ──────────────────────
  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accentYellow, width: 2)),
            filled: true,
            fillColor: const Color.fromARGB(255, 145, 210, 25).withValues(alpha: 0.05),
          ),
          validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
          onChanged: (_) => _updatePdfPreview(),
        ),
      );

  Widget _dropdown(String label, String initialValue, List<String> items, ValueChanged<String?> onChanged) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: DropdownButtonFormField<String>(
          value: initialValue,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accentYellow, width: 2)),
            filled: true,
            fillColor: primaryBlue.withValues(alpha: 0.05),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {
            if (v != null) {
              onChanged(v);
              _updatePdfPreview();
            }
          },
        ),
      );

  Widget _buildForm() => Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Candidate Information', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryBlue)),
            const Divider(color: accentYellow, thickness: 3, height: 30),
            _field('Full Name', _nameCtrl),
            _field('Salutation', _salutationCtrl),
            _dropdown('Known By (Category)', _knownBy, _knownByOptions, (v) => setState(() => _knownBy = v!)),
            _field('How Known', _knownCtrl),
            _field('Duration Known', _knownDurationCtrl),
            _field('Courses / Research Area', _courseTaughtCtrl, maxLines: 2),
            if (_knownBy == 'Research') _field('Research Title', _researchTitleCtrl, maxLines: 3),

            const SizedBox(height: 20),
            const Text('Recommendation Target', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryBlue)),
            const Divider(color: accentYellow, thickness: 3, height: 30),
            _dropdown('Recommended For', _recommendedFor, _recommendedForOptions, (v) => setState(() => _recommendedFor = v!)),
            _field('University', _universityCtrl),

            const SizedBox(height: 30),

            // ───── NEW: Signature Upload Section ─────
            const Text('Recommender Signature (Optional)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color.fromARGB(255, 60, 0, 224))),
            const Divider(color: accentYellow, thickness: 2),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickSignature,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_signatureImage == null ? 'Upload Signature' : 'Change Signature'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 242, 242, 243)),
                  ),
                ),
                if (_signatureImage != null) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.clear, color: actionRed),
                    onPressed: () {
                      setState(() => _signatureImage = null);
                      _updatePdfPreview();
                    },
                  ),
                ]
              ],
            ),
            if (_signatureImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(child: Image.memory(_signatureImage!, height: 100, fit: BoxFit.contain)),
              ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: accentYellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: accentYellow, width: 2)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.info_outline, color: primaryBlue), SizedBox(width: 8), Text('Selected Category', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue))]),
                const SizedBox(height: 8),
                Text(_getCategoryDescription(), style: TextStyle(color: Colors.grey[800])),
              ]),
            ),
          ]),
        ),
      );

  String _getCategoryDescription() => switch (_knownBy) {
        'Research' => 'Focuses on research collaboration, analytical skills, and independent thinking.',
        'Class' => 'Emphasizes classroom performance and intellectual engagement.',
        'Supervision' => 'Highlights project supervision and academic mentorship.',
        _ => 'General recommendation based on departmental observation.',
      };

  Widget _buildPreview(double width) => Column(children: [
        const Padding(padding: EdgeInsets.all(16), child: Text('Live PDF Preview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryBlue))),
        const Divider(color: accentYellow, thickness: 3),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: accentYellow, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 4))]),
            child: _pdfBytes != null
                ? PdfPreview(build: (_) => _pdfBytes!, maxPageWidth: width, pdfFileName: 'Recommendation_${_nameCtrl.text.replaceAll(' ', '_')}.pdf')
                : const Center(child: CircularProgressIndicator(color: primaryBlue)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () => _formKey.currentState!.validate() && _pdfBytes != null ? Printing.layoutPdf(onLayout: (_) => _pdfBytes!) : null,
              icon: const Icon(Icons.print, color: Colors.white),
              label: const Text('Print / Save PDF', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: actionRed, elevation: 5),
            ),
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendation Letter Generator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: primaryBlue),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(children: [
              Expanded(child: _buildForm()),
              const VerticalDivider(color: accentYellow, thickness: 2),
              Expanded(flex: 2, child: _buildPreview(constraints.maxWidth * 0.66)),
            ]);
          }
          return SingleChildScrollView(child: Column(children: [_buildForm(), _buildPreview(constraints.maxWidth)]));
        },
      ),
    );
  }
}