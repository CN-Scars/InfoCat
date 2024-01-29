import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('InfoCat: Home Modem Information Tool'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
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
                        flex: 1, // 当不显示"光猫MAC地址"时，"光猫网关地址"占满整个行
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
                      if (_isManualMac) ...[
                        // 仅当_isManualMac为true时添加以下组件
                        SizedBox(width: 16.0),

                        Flexible(
                          flex: 1,
                          child: AnimatedOpacity(
                            opacity: _isManualMac ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 500),
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
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 16.0),
                  SwitchListTile(
                    title: Text('手动输入MAC地址'),
                    value: _isManualMac,
                    onChanged: (value) {
                      setState(() {
                        _isManualMac = value;
                        _addLog('手动输入MAC地址: ${_isManualMac ? '开启' : '关闭'}');
                      });
                    },
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.spaceAround, // 按钮之间的间距均匀分布
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () async {
                          _addLog('尝试连接到光猫: $_gatewayAddress');
                          String gatewayMACAddress;
                          if (!_isManualMac) {
                            gatewayMACAddress =
                                await NativeCode.getGatewayMACAddress(
                                    _gatewayAddress);
                          } else {
                            gatewayMACAddress =
                                _manualMacAddress; // 使用手动输入的MAC地址
                          }
                          _addLog(gatewayMACAddress.isNotEmpty
                              ? '光猫 MAC 地址: $gatewayMACAddress'
                              : '无法连接到光猫');
                        },
                        child: Text('连接到光猫'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement about software functionality
                        },
                        child: Text('关于软件'),
                      ),
                    ],
                  ),
                  // 下半部分预留空间
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(8.0),
              margin: EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
              ),
              constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.5),
              child: SingleChildScrollView(
                controller: _logScrollController,
                child: Text(_logs), // 显示日志
              ),
            ),
          ),
        ],
      ),
    );
  }
}
