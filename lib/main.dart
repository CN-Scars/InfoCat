import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'native_code.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InfoCat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String _gatewayAddress = '192.168.1.1'; // 默认的光猫网关地址
  bool _isManualMac = false; // 是否手动输入MAC地址
  String _manualMacAddress = ''; // 手动输入的MAC地址
  String _logs = ''; // 用于存储日志的字符串
  final ScrollController _logScrollController =
      ScrollController(); // 用于控制日志滚动的控制器
  String? selectedKey; // 选择的键
  String selectedValue = ''; // 选择的值
  HashMap<Object?, Object?> _factoryConfig = HashMap(); // 光猫工厂配置

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _addLog(String log) {
    setState(() {
      _logs += log + '\n'; // 添加日志信息并换行
    });
    // 缓慢滚动到底部
    _logScrollController.animateTo(
      _logScrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInSine,
    );
  }

  Future<void> _initConnectivity() async {
    var connectivityResult;
    try {
      connectivityResult = await _connectivity.checkConnectivity();
    } catch (e) {
      print('无法检查网络连接： $e');
      return;
    }
    _updateConnectionStatus(connectivityResult);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    String wifiName = '';
    if (result == ConnectivityResult.wifi) {
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          wifiName = await NetworkInfo().getWifiName() ?? '未知 Wi-Fi';
        } catch (e) {
          print('无法获取 Wi-Fi 名称： $e');
        }
      }
    }

    setState(() {
      switch (result) {
        case ConnectivityResult.wifi:
          _connectionStatus = '已连接到 Wi-Fi $wifiName';
          break;
        case ConnectivityResult.mobile:
          _connectionStatus = '已连接到移动网络';
          break;
        case ConnectivityResult.ethernet:
          _connectionStatus = '已通过网线连接';
          break;
        case ConnectivityResult.none:
          _connectionStatus = '没有连接到互联网';
          break;
        default:
          _connectionStatus = '未知连接状态';
          break;
      }
    });

    _addLog('网络状态更新: $_connectionStatus');
  }

  Future<String> getGatewayMacAddress(String _gatewayAddress) async {
    String gatewayMACAddress;

    if (!_isManualMac) {
      _addLog('获取光猫：$_gatewayAddress 的MAC地址中...');
      gatewayMACAddress =
          await NativeCode.getGatewayMACAddress(_gatewayAddress);
    } else {
      gatewayMACAddress = _manualMacAddress; // 使用手动输入的MAC地址
      _addLog('已手动输入光猫MAC地址：${gatewayMACAddress}');
    }

    _addLog(gatewayMACAddress.isNotEmpty
        ? '光猫 MAC 地址: $gatewayMACAddress'
        : '无法连接到光猫');

    return gatewayMACAddress;
  }

  Future<bool> tryEnableTelnet(
      String gatewayAddress, String gatewayMACAddress) async {
    _addLog('尝试开启telnet中...');
    String url =
        'http://$gatewayAddress/cgi-bin/telnetenable.cgi?telnetenable=1&key=$gatewayMACAddress';

    // 发送GET请求
    var response = await http.get(Uri.parse(url));
    String responseBody = utf8.decode(response.bodyBytes);

    // 判断telnet是否开启
    bool isTelnetEnabled = responseBody.contains("if (1 == 1)");
    _addLog(isTelnetEnabled ? 'telnet已开启' : 'telnet未开启');

    return isTelnetEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('InfoCat: Home Modem Information Tool'),
      ),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('网络状态： $_connectionStatus'),
                          SizedBox(height: 8.0),
                          Row(
                            children: [
                              Flexible(
                                child: TextFormField(
                                  initialValue: _gatewayAddress,
                                  decoration: InputDecoration(
                                    labelText: '光猫网关地址',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    _gatewayAddress = value;
                                  },
                                ),
                              ),
                              SizedBox(width: 16.0),
                              if (_isManualMac)
                                Flexible(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      labelText: '光猫MAC地址',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      _manualMacAddress = value;
                                    },
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                          SwitchListTile(
                            title: Text('手动输入MAC地址'),
                            value: _isManualMac,
                            onChanged: (bool value) {
                              setState(() {
                                _isManualMac = value;
                              });
                            },
                          ),
                          ButtonBar(
                            alignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              ElevatedButton(
                                onPressed: () async {
                                  String gatewayMACAddress =
                                      await getGatewayMacAddress(
                                          _gatewayAddress);
                                  if (gatewayMACAddress.isEmpty) {
                                    _addLog('错误：MAC地址为空，操作终止');
                                    return;
                                  }

                                  bool telnetEnabled = await tryEnableTelnet(
                                      _gatewayAddress, gatewayMACAddress);
                                  if (!telnetEnabled) {
                                    _addLog('错误：telnet未成功开启，操作终止');
                                    return;
                                  }

                                  // 获取配置信息
                                  var config =
                                      await NativeCode.getFactoryConfig(
                                          _gatewayAddress);
                                  // 使用setState更新_factoryConfig，并触发界面重建
                                  setState(() {
                                    _factoryConfig = config;
                                  });
                                },
                                child: Text('连接到光猫'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: 关于软件弹窗
                                },
                                child: Text('关于软件'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: ListView(
                        children: [
                          DropdownButton<String>(
                            isExpanded: true,
                            value: selectedKey,
                            hint: Text('请选择一个选项'),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedKey = newValue;
                                selectedValue =
                                    _factoryConfig[newValue]?.toString() ?? '';
                              });
                            },
                            items: _factoryConfig.keys
                                .map<DropdownMenuItem<String>>((key) {
                              String stringKey = key.toString();
                              return DropdownMenuItem<String>(
                                value: stringKey,
                                child: Text(stringKey),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller:
                                TextEditingController(text: selectedValue),
                            readOnly: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '值',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.topLeft,
              padding: EdgeInsets.all(8.0),
              margin: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
              ),
              // 使用IntrinsicWidth强制宽度适应
              child: IntrinsicWidth(
                stepWidth: double.infinity,
                child: SingleChildScrollView(
                  controller: _logScrollController,
                  child: Text(
                    _logs,
                    textAlign: TextAlign.left,
                  ), // 显示日志
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
