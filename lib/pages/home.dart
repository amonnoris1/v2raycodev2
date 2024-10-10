import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter V2Ray',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const Scaffold(
        body: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;
  int _remainingTime = 60; // Example: Countdown for 60 seconds

  bool isConnected = false;
  late final FlutterV2ray flutterV2ray = FlutterV2ray(
    onStatusChanged: (status) {
      v2rayStatus.value = status;
    },
  );
  final config = TextEditingController();
  bool proxyOnly = false;
  var v2rayStatus = ValueNotifier<V2RayStatus>(V2RayStatus());
  final bypassSubnetController = TextEditingController();
  List<String> bypassSubnets = [];
  String? coreVersion;

  // IP and country variables
  String currentIp = "Fetching IP...";
  String country = "Fetching location...";
  String network = "Fetching network...";

  String remark = "Default Remark";

  void connect() async {
    if (await flutterV2ray.requestPermission()) {
      flutterV2ray.startV2Ray(
        remark: remark,
        config: config.text,
        proxyOnly: proxyOnly,
        bypassSubnets: bypassSubnets,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission Denied'),
          ),
        );
      }
    }
  }

  void importConfig() async {
    if (await Clipboard.hasStrings()) {
      try {
        final String link =
            (await Clipboard.getData('text/plain'))?.text?.trim() ?? '';
        final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(link);
        remark = v2rayURL.remark;
        config.text = v2rayURL.getFullConfiguration();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Success',
              ),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: $error',
              ),
            ),
          );
        }
      }
    }
  }

  void delay() async {
    late int delay;
    if (v2rayStatus.value.state == 'CONNECTED') {
      delay = await flutterV2ray.getConnectedServerDelay();
    } else {
      delay = await flutterV2ray.getServerDelay(config: config.text);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${delay}ms',
        ),
      ),
    );
  }

  void bypassSubnet() {
    bypassSubnetController.text = bypassSubnets.join("\n");
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Subnets:',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: bypassSubnetController,
                maxLines: 5,
                minLines: 5,
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                  bypassSubnets =
                      bypassSubnetController.text.trim().split('\n');
                  if (bypassSubnets.first.isEmpty) {
                    bypassSubnets = [];
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchIpAndLocation(); // Fetch IP and location at the start
    flutterV2ray.initializeV2Ray().then((value) async {
      coreVersion = await flutterV2ray.getCoreVersion();
      setState(() {});
    });
    if (kDebugMode) {
      print(v2rayStatus.value.state);
    }
  }

  @override
  void dispose() {
    // Cancel the timer if the widget is disposed
    _timer?.cancel();
    config.dispose();
    bypassSubnetController.dispose();
    super.dispose();
  }

  Future<void> fetchIpAndLocation() async {
    final url = Uri.parse('http://ip-api.com/json/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          currentIp = data['query'] ?? 'Unknown IP';
          country = data['country'] ?? 'Unknown Location';
          network = data['as'] ?? 'Unknown Location';
        });
      } else {
        throw Exception('Failed to fetch IP');
      }
    } catch (e) {
      setState(() {
        currentIp = 'Error fetching IP';
        country = 'Error fetching location';
        network = 'Error fetching location';
      });
      print('Error: $e');
    }
  }

  // Function to start the timer
  void startTimer() {
    // Cancel any existing timer before starting a new one
    if (_timer != null) {
      _timer!.cancel();
    }

    setState(() {
      _remainingTime = 5; // Reset timer (you can change this value)
    });

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--; // Decrement remaining time every second
        });
      } else {
        // Time is up, stop V2Ray connection
        flutterV2ray.stopV2Ray();
        setState(() {
          v2rayStatus.value = v2rayStatus.value.copyWith(state: 'DISCONNECTED');
          isConnected = false;
        });
        _timer?.cancel(); // Stop the timer
      }
    });
  }

  // Function to handle connection based on status
  void handleConnection() {
    if (v2rayStatus.value.state == 'CONNECTED' && !isConnected) {
      setState(() {
        isConnected = true;
      });
      startTimer(); // Start the timer when the user connects
    } else if (v2rayStatus.value.state == 'DISCONNECTED' && isConnected) {
      setState(() {
        isConnected = false;
        _timer?.cancel(); // Stop the timer when disconnected
      });
      flutterV2ray.stopV2Ray(); // Call stopV2Ray when disconnected
    }
  }

  @override
  Widget build(BuildContext context) {
    handleConnection();
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // Text(
                  //   '$country\nYour location',
                  //   style: const TextStyle(fontSize: 16),
                  // ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: country, // The part you want to make bold
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold, // Make this part bold
                                fontSize:
                                    18, // Set the font size for the country name
                              ),
                            ),
                            const TextSpan(
                              text: '\nYour location', // The rest of the text
                              style: TextStyle(
                                  fontWeight:
                                      FontWeight.normal, // Normal weight
                                  fontSize: 14,
                                  color: Colors.grey // Different font size
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          width: 10), // Adding some space between the texts
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: currentIp, // The part you want to make bold
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold, // Make this part bold
                                fontSize:
                                    18, // Set the font size for the country name
                              ),
                            ),
                            const TextSpan(
                              text: '\nIP Address', // The rest of the text
                              style: TextStyle(
                                  fontWeight:
                                      FontWeight.normal, // Normal weight
                                  fontSize: 14,
                                  color: Colors.grey // Different font size
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'V2Ray', // The part you want to make bold
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold, // Make this part bold
                                fontSize:
                                    18, // Set the font size for the country name
                              ),
                            ),
                            TextSpan(
                              text: '\nProtocal In use', // The rest of the text
                              style: TextStyle(
                                  fontWeight:
                                      FontWeight.normal, // Normal weight
                                  fontSize: 14,
                                  color: Colors.grey // Different font size
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                          width: 10), // Adding some space between the texts
                      Text(
                        '$currentIp\nIP Address',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  // Text(
                  //   '$currentIp\nIP Address',
                  //   style: const TextStyle(fontSize: 16),
                  // ),
                  const SizedBox(height: 30),
                  // Text(
                  //   '$network\nIP Address',
                  //   style: const TextStyle(fontSize: 16),
                  // ),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: config,
                    maxLines: 10,
                    minLines: 10,
                  ),
                  if (v2rayStatus.value.state == 'DISCONNECTED')
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        importConfig();
                      },
                      child: const Text(
                        'Import from v2ray share link (clipboard)',
                      ),
                    ),
                  if (v2rayStatus.value.state == 'CONNECTED')
                    const Text('ALREADY CONNECTED'),
                  ElevatedButton(
                    onPressed: delay,
                    child: const Text('Server Delay'),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder(
                    valueListenable: v2rayStatus,
                    builder: (context, value, child) {
                      return Column(
                        children: [
                          const SizedBox(height: 10),
                          // Show the remaining time
                          if (isConnected)
                            Text(
                              textAlign: TextAlign.center,
                              'Time remaining: $_remainingTime Min',
                              style: const TextStyle(fontSize: 24),
                            ),
                          Text(v2rayStatus.value.state),
                          const SizedBox(height: 10),
                          Text(v2rayStatus.value.duration),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Speed:'),
                              const SizedBox(width: 10),
                              Text(v2rayStatus.value.uploadSpeed.toString()),
                              const Text('↑'),
                              const SizedBox(width: 10),
                              Text(v2rayStatus.value.downloadSpeed.toString()),
                              const Text('↓'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Traffic:'),
                              const SizedBox(width: 10),
                              Text(v2rayStatus.value.upload.toString()),
                              const Text('↑'),
                              const SizedBox(width: 10),
                              Text(v2rayStatus.value.download.toString()),
                              const Text('↓'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('Core Version: $coreVersion'),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              setState(() => proxyOnly = !proxyOnly),
                          child: Text(proxyOnly ? 'Proxy Only' : 'VPN Mode'),
                        ),
                        ElevatedButton(
                          onPressed: bypassSubnet,
                          child: const Text('Bypass Subnet'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                height: 150,
                child: Positioned(
                  child: Card(
                    child: Column(
                      children: [
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     if (v2rayStatus.value.state == 'DISCONNECTED')
                        //       SizedBox(
                        //         child: ElevatedButton(
                        //           style: ElevatedButton.styleFrom(
                        //             backgroundColor: Colors.blue,
                        //             fixedSize: const Size(200, 50),
                        //           ),
                        //           onPressed: () {
                        //             // Connect action
                        //             setState(() {
                        //               v2rayStatus.value = V2RayStatus(
                        //                 duration: v2rayStatus.value.duration,
                        //                 uploadSpeed:
                        //                     v2rayStatus.value.uploadSpeed,
                        //                 downloadSpeed:
                        //                     v2rayStatus.value.downloadSpeed,
                        //                 upload: v2rayStatus.value.upload,
                        //                 download: v2rayStatus.value.download,
                        //                 state:
                        //                     'CONNECTED', // Update state to CONNECTED
                        //               );
                        //             });
                        //             connect(); // Call your connect function
                        //           },
                        //           child: const Text('Connect'),
                        //         ),
                        //       ),
                        //     if (v2rayStatus.value.state == 'CONNECTED')
                        //       ElevatedButton(
                        //         style: ElevatedButton.styleFrom(
                        //           backgroundColor: Colors.red,
                        //           fixedSize: const Size(200, 50),
                        //         ),
                        //         onPressed: () {
                        //           // Disconnect action
                        //           setState(() {
                        //             v2rayStatus.value = V2RayStatus(
                        //               duration: v2rayStatus.value.duration,
                        //               uploadSpeed:
                        //                   v2rayStatus.value.uploadSpeed,
                        //               downloadSpeed:
                        //                   v2rayStatus.value.downloadSpeed,
                        //               upload: v2rayStatus.value.upload,
                        //               download: v2rayStatus.value.download,
                        //               state:
                        //                   'DISCONNECTED', // Update state to DISCONNECTED
                        //             );
                        //           });
                        //           flutterV2ray.stopV2Ray(); // Call stopV2Ray
                        //         },
                        //         child: const Text('Disconnect'),
                        //       ),
                        //   ],
                        // ),
                        const Text('Hello'), // Add other content here

                        // Spacer pushes the button to the bottom of the card
                        const Spacer(),

                        // The ElevatedButton stays at the bottom of the card
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 10,
                              left: 10,
                              right: 10), // Optional horizontal padding

                          child: Column(
                            children: [
                              if (v2rayStatus.value.state == 'DISCONNECTED')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Connect action
                                      setState(() {
                                        v2rayStatus.value = V2RayStatus(
                                          duration: v2rayStatus.value.duration,
                                          uploadSpeed:
                                              v2rayStatus.value.uploadSpeed,
                                          downloadSpeed:
                                              v2rayStatus.value.downloadSpeed,
                                          upload: v2rayStatus.value.upload,
                                          download: v2rayStatus.value.download,
                                          state:
                                              'CONNECTED', // Update state to CONNECTED
                                        );
                                      });
                                      connect(); // Call your connect function
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF00BCD4), // Cyan color
                                      foregroundColor:
                                          Colors.black, // Black text color
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical:
                                              15), // Adjust vertical padding
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            10), // Rounded corners
                                      ),
                                    ),
                                    child: const Text('CONNECT'),
                                  ),
                                ),
                              if (v2rayStatus.value.state == 'CONNECTED')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Disconnect action
                                      setState(() {
                                        v2rayStatus.value = V2RayStatus(
                                          duration: v2rayStatus.value.duration,
                                          uploadSpeed:
                                              v2rayStatus.value.uploadSpeed,
                                          downloadSpeed:
                                              v2rayStatus.value.downloadSpeed,
                                          upload: v2rayStatus.value.upload,
                                          download: v2rayStatus.value.download,
                                          state:
                                              'DISCONNECTED', // Update state to DISCONNECTED
                                        );
                                      });
                                      flutterV2ray
                                          .stopV2Ray(); // Call stopV2Ray
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 212, 49, 0), // Cyan color
                                      foregroundColor: const Color.fromARGB(255,
                                          248, 243, 243), // Black text color
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical:
                                              15), // Adjust vertical padding
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            10), // Rounded corners
                                      ),
                                    ),
                                    child: const Text('DISCONNECT'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
