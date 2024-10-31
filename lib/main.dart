import 'package:firstnote/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const PetProfileScreen(),
    );
  }
}

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final BleController controller = Get.put(BleController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(8.0),  // 패딩 줄임
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.deepOrange),
                    onPressed: () {},
                  ),
                  const Text(
                    '오늘의 히로',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.videocam, color: Colors.deepOrange),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Upper half: Data Log
            Expanded(
              flex: 1,  // 상단 절반
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),  // 마진 조정
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "데이터 로그",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_all),
                            onPressed: () => controller.receivedDataList.clear(),
                            padding: EdgeInsets.zero,  // 아이콘 패딩 제거
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        return ListView(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 8),  // 패딩 조정
                          children: controller.receivedDataList.map((data) =>
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),  // 패딩 줄임
                                child: Text(
                                  data,
                                  style: TextStyle(
                                    color: data.contains('!') ? Colors.blue : Colors.grey,
                                    fontFamily: 'Courier',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ).toList(),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // Lower half: BLE Device List
            Expanded(
              flex: 1,  // 하단 절반
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),  // 마진 조정
                child: GetBuilder<BleController>(
                  builder: (controller) {
                    return StreamBuilder<List<ScanResult>>(
                      stream: controller.scanResults,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return ListView.builder(
                            padding: EdgeInsets.zero,  // 패딩 제거
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final data = snapshot.data![index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    data.device.name.isEmpty ? 'Unknown Device' : data.device.name,
                                    style: const TextStyle(fontSize: 14),  // 폰트 크기 조정
                                  ),
                                  subtitle: Text(
                                    data.device.id.id,
                                    style: const TextStyle(fontSize: 12),  // 폰트 크기 조정
                                  ),
                                  trailing: Text(data.rssi.toString()),
                                  onTap: () => controller.connectToDevice(data.device),
                                ),
                              );
                            },
                          );
                        } else {
                          return const Center(child: Text("검색된 기기가 없습니다"));
                        }
                      },
                    );
                  },
                ),
              ),
            ),

            // Bottom Buttons & Nav - Compact version
            Column(
              mainAxisSize: MainAxisSize.min,  // 최소 크기로 설정
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),  // 패딩 조정
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF3EE),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 40),  // 높이 줄임
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => controller.scanDevices(),
                    child: const Text('주변 기기 찾기'),
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}