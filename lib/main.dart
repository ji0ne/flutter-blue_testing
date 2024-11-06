import 'package:firstnote/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

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
                          Row(  // 버튼들을 가로로 배치
                            children: [
                              // 복사 버튼 추가
                              TextButton.icon(
                                onPressed: () {
                                  // 모든 로그를 하나의 문자열로 결합
                                  final allLogs = controller.receivedDataList.join('\n');
                                  // 클립보드에 복사
                                  Clipboard.setData(ClipboardData(text: allLogs));
                                  // 복사 완료 알림 (선택사항)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('모든 로그가 복사되었습니다'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 20, color: Colors.deepOrange),
                                label: const Text(
                                  'Copy',
                                  style: TextStyle(
                                    color: Colors.deepOrange,
                                    fontSize: 14,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),  // 버튼 사이 간격
                              IconButton(
                                icon: const Icon(Icons.clear_all),
                                onPressed: () => controller.receivedDataList.clear(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        return ListView(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: controller.receivedDataList.map((data) =>
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: SelectableText(  // Text 위젯을 SelectableText로 변경
                                  data,
                                  style: TextStyle(
                                    color: data.contains('!') ? Colors.black : Colors.deepOrange,
                                    fontFamily: 'Courier',
                                    fontSize: 12,
                                  ),
                                  // SelectableText의 추가 속성들
                                  showCursor: true,  // 선택 시 커서 표시
                                  toolbarOptions: const ToolbarOptions(  // 복사 메뉴 옵션 설정
                                    copy: true,
                                    selectAll: true,
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
                        if (snapshot.hasData) {
                          // "PET"을 포함하는 기기만 필터링
                          final filteredDevices = snapshot.data!.where((result) {
                            final deviceName = result.device.name.toUpperCase();
                            return deviceName.contains("PET");
                          }).toList();

                          if (filteredDevices.isNotEmpty) {
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filteredDevices.length,
                              itemBuilder: (context, index) {
                                final data = filteredDevices[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Text(
                                          data.device.name.isEmpty ? 'Unknown Device' : data.device.name,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        // 연결 상태 표시
                                        Obx(() => controller.connectedDeviceId.value == data.device.id.id
                                            ? Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.green),
                                          ),
                                          child: const Text(
                                            'Connected',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )
                                            : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      data.device.id.id,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(data.rssi.toString()),
                                    onTap: () => controller.connectToDevice(data.device),
                                  ),
                                );
                              },
                            );
                          } else {
                            return const Center(
                              child: Text("PET 기기를 찾을 수 없습니다"),
                            );
                          }
                        } else {
                          return const Center(
                            child: Text("기기를 검색중입니다..."),
                          );
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