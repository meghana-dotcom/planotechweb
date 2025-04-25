import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:planotech/Employee/empdashboard.dart';
import 'package:flutter/foundation.dart';
import 'package:planotech/baseurl.dart'; // Add this import for kIsWeb

var Id;
var userName;
var userDepartment;

class ReportSubmissionScreen extends StatefulWidget {
  ReportSubmissionScreen(var empId, var empName, var empDepartment) {
    Id = empId;
    userName = empName;
    userDepartment = empDepartment;
  }

  @override
  _ReportSubmissionScreenState createState() => _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState extends State<ReportSubmissionScreen> {
  final TextEditingController _reportController = TextEditingController();
  bool _isSubmitting = false;
  PlatformFile? _selectedDocumentFile; // Use PlatformFile for web compatibility
  final int maxSizeInBytes = 25 * 1024 * 1024;

  Icon _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'doc':
      case 'docx':
        return Icon(Icons.description, color: Colors.blue);
      case 'xls':
      case 'xlsx':
        return Icon(Icons.table_chart, color: Colors.green);
      default:
        return Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  Widget _buildUploadedFile(PlatformFile file) {
    final extension = file.name.split('.').last.toLowerCase();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(file.name),
        leading: _getFileIcon(extension),
        trailing: IconButton(
          icon: Icon(Icons.cancel),
          onPressed: () {
            setState(() {
              _selectedDocumentFile = null;
            });
          },
        ),
        onTap: () {
          // Open the file if possible (not supported on web)
          if (!kIsWeb && file.path != null) {
            OpenFile.open(file.path!);
          }
        },
      ),
    );
  }

  void _showFileSizeLimitExceededSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload less than 25MB files')),
    );
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      if (file.size > maxSizeInBytes) {
        _showFileSizeLimitExceededSnackBar();
      } else {
        setState(() {
          _selectedDocumentFile = file;
        });
      }
    }
  }

  bool _isFormValid() {
    return _reportController.text.trim().isNotEmpty || _selectedDocumentFile != null;
  }

  Future<void> _submit() async {
    if (_isFormValid()) {
      setState(() {
        _isSubmitting = true;
      });

      String report = _reportController.text;
      DateTime now = DateTime.now();
      String date = '${now.day}-${now.month}-${now.year}';
      String time = DateFormat('hh:mm a').format(now);

      try {
        await _uploadReport(report, date, time, _selectedDocumentFile);
        _reportController.clear();
        setState(() {
          _selectedDocumentFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report submitted successfully'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmployeeDashboard()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _uploadReport(
      String report, String date, String time, PlatformFile? file) async {
    try {
      final url = Uri.parse(baseurl+'/emp/dailyemployeereport');

      final Map<String, dynamic>? employeeReport = {
        "employeeId": Id,
        "date": date,
        "time": time,
        "employeeName": userName,
        "employeeDepartment": userDepartment,
      };

      String employeeReportString = jsonEncode(employeeReport);
      print('Employee Report JSON: $employeeReportString');
      final request = http.MultipartRequest('POST', url);
      request.fields['employeeReport'] = employeeReportString;
      request.fields['report'] = report;
      print(request);

      if (file != null) {
        print('Adding report file: ${file.name}');
        if (kIsWeb) {
          // For web, use bytes to upload the file
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ));
        } else {
          // For mobile/desktop, use the file path
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
          ));
        }
        print('Report file added to request.');
      } else {
        print('No report file to add.');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('JSON Response: $jsonResponse');

        if (jsonResponse != null && jsonResponse['status'] != null) {
          if (jsonResponse['status'] == true) {
            print('Report submitted successfully: ${jsonResponse['message']}');
          } else {
            throw Exception('Failed to submit report.');
          }
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to upload report.');
      }
    } catch (e) {
      print('Error uploading report: $e');
      throw Exception('Error uploading report');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Submission',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 30, 93, 209),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _reportController,
                onChanged: (_) {
                  setState(() {});
                },
                maxLines: 8,
                maxLength: 3000,
                decoration: const InputDecoration(
                  hintText: 'Enter your report here...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your report';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Upload Document',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8.0),
                  Tooltip(
                    message: 'Upload Documents',
                    child: IconButton(
                      icon: Icon(Icons.attach_file),
                      onPressed: _pickFile,
                    ),
                  ),
                ],
              ),
              if (_selectedDocumentFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _buildUploadedFile(_selectedDocumentFile!),
                ),
              const SizedBox(height: 30.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 30, 93, 209),
                ),
                onPressed: _isFormValid() ? _submit : null,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}