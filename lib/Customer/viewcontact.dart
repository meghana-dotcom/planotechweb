import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planotech/baseurl.dart';

class ViewContactPage extends StatefulWidget {
  const ViewContactPage({Key? key}) : super(key: key);

  @override
  State<ViewContactPage> createState() => _ViewContactPageState();
}

class _ViewContactPageState extends State<ViewContactPage> {
  List<Map<String, dynamic>> _userList = [];
  bool _isDataLoaded = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final url = baseurl+'/admin/fetchallcontactus';

    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print(response);
        if (responseData != null && responseData['status'] == true) {
          setState(() {
            _userList =
                List<Map<String, dynamic>>.from(responseData['userList'] ?? []);
            _isDataLoaded = true;
            _isLoading = false;
          });
        } else {
          // Handle the case where status is false or responseData is null
          print(
              'Error: ${responseData != null ? responseData['statusMessage'] : 'Response is null'}');
          setState(() {
            _isDataLoaded = true;
            _isLoading = false;
          });
        }
      } else {
        // Handle non-200 responses
        print(
            'Error: Server responded with status code ${response.statusCode}');
        setState(() {
          _isDataLoaded = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching data: $error');
      setState(() {
        _isDataLoaded = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contact Us Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 139, 12, 3),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userList.isEmpty && _isDataLoaded
              ? Center(
                  child: Text('No data found', style: TextStyle(fontSize: 18)),
                )
              : ListView.builder(
                  itemCount: _userList.length,
                  itemBuilder: (context, index) {
                    final user = _userList[index];
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          tileColor: Colors.blue[100],
                          contentPadding: EdgeInsets.all(20),
                          title: Text(
                            'Name: ${user['name'] ?? ''}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildBox('Email', user['email'] ?? ''),
                              buildBox('Message', user['message'] ?? ''),
                              buildBox('Date', user['date'] ?? ''),
                              buildBox('Time', user['time'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget buildBox(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.normal),
              maxLines: 100,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
