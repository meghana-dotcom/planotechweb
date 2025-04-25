import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:planotech/baseurl.dart';

class SalarySlipPage extends StatefulWidget {
  @override
  _SalarySlipPageState createState() => _SalarySlipPageState();
}

class _SalarySlipPageState extends State<SalarySlipPage> {
  List userList = [];
  List filteredList = [];

  bool isLoading = false;

  String selectedMonth = 'April';
  String selectedYear = '2025';
  String selectedDepartment = 'All';
  String searchQuery = '';

  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  final years = List.generate(10, (index) => (2020 + index).toString());

  List<String> departments = ['All'];

  @override
  void initState() {
    super.initState();
    fetchSalaryData();
  }

  Future<void> fetchSalaryData() async {
    setState(() {
      isLoading = true;
      selectedDepartment = 'All';
    });

    final url = Uri.parse(
        "$baseurl/admin/fetchallsalaryslipbymonthyear?month=$selectedMonth&year=$selectedYear");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        userList = data['userList'] ?? [];

        departments = ['All'];
        departments.addAll(
          userList
              .map<String>((e) => e['empDepartment']?.toString().trim() ?? '')
              .where((d) => d.isNotEmpty)
              .toSet()
              .toList(),
        );

        applyFilters();
      }
    } catch (e) {
      print("Error fetching data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  void applyFilters() {
    setState(() {
      filteredList = userList.where((user) {
        final matchesDepartment = selectedDepartment == 'All' ||
            (user['empDepartment']?.toString().trim() ?? '') == selectedDepartment;
        final matchesName = user['empName']
            .toString()
            .toLowerCase()
            .contains(searchQuery.toLowerCase());

        return matchesDepartment && matchesName;
      }).toList();
    });
  }

  Future<void> uploadSlip(Map<String, dynamic> user) async {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = false;
    uploadInput.accept = '.pdf,.doc,.docx,.png,.jpg,.jpeg';
    
    uploadInput.click();
    
    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      
      final file = files[0];
      final reader = html.FileReader();
      
      reader.onLoadEnd.listen((e) async {
        if (reader.result == null) return;
        
        setState(() => isLoading = true);
        
        try {
          final date = DateFormat('dd-MM-yyyy').format(DateTime.now());
          final time = TimeOfDay.now().format(context);
          final day = getDayName(DateTime.now().weekday);

          final salarySlipMap = {
            "employeeId": user['employeeId'].toString(),
            "empName": user['empName'],
            "empDepartment": user['empDepartment'],
            "date": date,
            "time": time,
            "day": day,
            "salaryMonth": selectedMonth,
            "salaryYear": selectedYear,
          };

          var request = http.MultipartRequest(
            'POST',
            Uri.parse('$baseurl/admin/uploadsalaryslip'),
          );

          request.fields['SalarySlip'] = jsonEncode(salarySlipMap);
          
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            reader.result as List<int>,
            filename: file.name,
          ));

          final response = await http.Response.fromStream(await request.send());
          
          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Upload successful!")),
            );
            await fetchSalaryData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Upload failed: ${response.body}")),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error uploading file: $e")),
          );
        } finally {
          setState(() => isLoading = false);
        }
      });
      
      reader.readAsArrayBuffer(file);
    });
  }

  String getDayName(int weekday) {
    switch (weekday) {
      case 1: return "Monday";
      case 2: return "Tuesday";
      case 3: return "Wednesday";
      case 4: return "Thursday";
      case 5: return "Friday";
      case 6: return "Saturday";
      case 7: return "Sunday";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Salary Slips", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 139, 12, 3),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedMonth,
                    items: months
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedMonth = val!);
                      fetchSalaryData();
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedYear,
                    items: years
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedYear = val!);
                      fetchSalaryData();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedDepartment,
                    items: departments
                        .map((dept) => DropdownMenuItem<String>(
                              value: dept,
                              child: Text(dept),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedDepartment = value!);
                      applyFilters();
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                      applyFilters();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                      ? Center(
                          child: Text(
                            "No data found for selected month and year.",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (_, index) {
                            final user = filteredList[index];
                            final hasSlip = user['salarySlipLink'] != null;

                            return Card(
                              elevation: 4,
                              margin: EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  hasSlip ? Icons.check_circle : Icons.cancel,
                                  color: hasSlip ? Colors.green : Colors.red,
                                ),
                                title: Text(user['empName'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(user['empDepartment'] ?? ''),
                                trailing: ElevatedButton(
                                  onPressed: () => uploadSlip(user),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromARGB(255, 139, 12, 3),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6))),
                                  child: Text("Upload",
                                      style: TextStyle(
                                        color: Colors.white,
                                      )),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}