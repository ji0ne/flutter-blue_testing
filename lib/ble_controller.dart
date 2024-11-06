import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController {
  FlutterBlue ble = FlutterBlue.instance;

  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];
  StreamSubscription<BluetoothDeviceState>? _deviceStateSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;

  RxList<String> receivedDataList = <String>[].obs;
  BluetoothCharacteristic? writeCharacteristic;

  StringBuffer _dataBuffer = StringBuffer();
  RxString bpmData = "74".obs;  // 초기값 설정
  RxString temperatureData = "36.5".obs;

  //다른 클래스에서 사용할 수신한 전체데이터 변수
  //String get s_completeData=> completeData;
  StringBuffer _completeLog = StringBuffer();
  String get s_bpm => bpmData.value;
  String get s_temperature => temperatureData.value;


  @override
  void onInit() {
    super.onInit();
    _dataBuffer = StringBuffer();
  }


  Future<void> scanDevices() async {
    if (await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      ble.startScan(timeout: Duration(seconds: 10));
      await Future.delayed(Duration(seconds: 10));
      ble.stopScan();
    } else {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    }
  }

  RxString connectedDeviceId = "".obs;

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: Duration(seconds: 15));
      connectedDevice = device;
      connectedDeviceId.value = device.id.id;
      print("기기 연결됨 : $connectedDevice");

      // 연결 상태 모니터링
      _deviceStateSubscription = device.state.listen((state) {
        if (state == BluetoothDeviceState.disconnected) {
          connectedDeviceId.value = "";  // 연결 해제 시 ID 초기화
          print("기기 연결 해제됨");
        }
      });

      services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == Guid('00002a57-0000-1000-8000-00805f9b34fb')) {
            if (characteristic.properties.notify) {
              print("캐릭터 : $characteristic");
              _subscribeToCharacteristic(characteristic);
            }
            if(characteristic.properties.write)
              {
                  writeCharacteristic = characteristic;
                  print("Write특성 찾음 : $writeCharacteristic");
              }
          }
        }
      }
    } catch (e) {
      connectedDeviceId.value ="";
      print("에러 발생: $e");
    }
  }

  void _subscribeToCharacteristic(BluetoothCharacteristic characteristic) {
    characteristic.setNotifyValue(true);
    _characteristicSubscription = characteristic.value.listen((value) {
      String receivedData = utf8.decode(value);
      _processReceivedData(receivedData);

      // if(data.contains('!')) {
      //   completeData += data;
      //   receivedDataList.add("${DateTime.now().toString().substring(11, 19)} : $completeData");
      //   completeData = "";
      // } else {
      //   completeData += data;
      // }

      // 리스트 크기 관리
      // if (receivedDataList.length > 100) {
      //   receivedDataList.removeRange(0, 20); // 한 번에 20개씩 제거
      // }
    });
  }
  //String s_completeLog ="";
  // void _processReceivedData(String packet) {
  //
  //   String timeStamp = DateTime.now().toString().substring(11, 19);
  //
  //   _completeLog.write(packet);
  //
  //   if (packet.contains('!')) {
  //     String completeData = _completeLog.toString();
  //     String formattedLog = "$timeStamp : $completeData";
  //     print("통문자 : ${completeData}");
  //     receivedDataList.insert(0, formattedLog);
  //     _completeLog.clear();
  //   }
  //
  //   // 로그 크기 관리
  //   if (receivedDataList.length > 100) {
  //     receivedDataList.removeRange(80, receivedDataList.length);
  //   }
  //
  //
  // }
  //
  // void _processReceivedData(String packet) {
  //   String timeStamp = DateTime.now().toString().substring(11, 19);
  //
  //   // V를 포함한 첫 번째 패킷이나 이전 누적 데이터가 없는 경우에만 새로 시작
  //   if ((packet.contains('V') && _completeLog.isEmpty) || _completeLog.isEmpty) {
  //     _completeLog.write(packet);
  //   }
  //   // V를 포함하지 않고 !를 포함한 마지막 패킷인 경우
  //   else if (!packet.contains('V') && packet.contains('!')) {
  //     _completeLog.write(packet);
  //     String completeData = _completeLog.toString();
  //     String formattedLog = "$timeStamp : $completeData";
  //     print("통문자 : $completeData");
  //     receivedDataList.insert(0, formattedLog);
  //     _completeLog.clear();  // 버퍼 초기화
  //   }
  //
  //   // 로그 크기 관리
  //   if (receivedDataList.length > 100) {
  //     receivedDataList.removeRange(80, receivedDataList.length);
  //   }
  // }

  void _processReceivedData(String packet) {
    String timeStamp = DateTime.now().toString().substring(11, 19);

    // V를 포함한 첫 번째 패킷이면 새로 시작
    if (packet.contains('V')) {
      _completeLog.clear();  // 새로운 데이터 시작
      _completeLog.write(packet);
    }
    // A나 다른 중간 패킷이면 누적
    else if (packet.contains('A')) {
      if (!_completeLog.isEmpty) {  // V 패킷이 있을 때만 추가
        _completeLog.write(packet);
      }
    }
    // !로 끝나는 마지막 패킷이면 완성하고 출력
    else if (packet.contains('!')) {
      if (!_completeLog.isEmpty) {  // 이전 패킷들이 있을 때만 처리
        _completeLog.write(packet);
        String completeData = _completeLog.toString();
        String formattedLog = "$timeStamp : $completeData";
        print("통문자 : $completeData");
        receivedDataList.insert(0, formattedLog);
        _completeLog.clear();  // 버퍼 초기화
      }
    }

    if (receivedDataList.length > 100) {
      receivedDataList.removeRange(80, receivedDataList.length);
    }
  }



  Stream<List<ScanResult>> get scanResults => ble.scanResults;

  @override
  void onClose() {
    _deviceStateSubscription?.cancel();
    super.onClose();
  }

  @override
  void dispose() {
    connectedDeviceId.value = "";
    connectedDevice?.disconnect();
    _deviceStateSubscription?.cancel();
    _characteristicSubscription?.cancel();
    super.dispose();
  }
}