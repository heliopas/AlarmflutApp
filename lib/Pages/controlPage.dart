import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:ndialog/ndialog.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ControlPage();
  }
}

class _ControlPage extends State<ControlPage> {
  final MqttServerClient client =
      MqttServerClient('a5xv18ahpzevq-ats.iot.us-west-2.amazonaws.com', '');

  bool get isConnected => true;

  set isConnected(bool isConnected) {}

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AppBar(
              title: Text('AUTO HOME - V1.0'),
              centerTitle: true,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            SizedBox(
              height: 5,
            ),
            ElevatedButton(
              onPressed: () {
                _connect();
              },
              child: Text('Connect to AWS'),
            ),
            SizedBox(
              height: 5,
            ),
            ElevatedButton(
              onPressed: () {
                _disconnect();
              },
              child: Text('Disconect from AWS'),
            ),
            SizedBox(
              height: 5,
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Tocar BUZZER'),
            ),
            SizedBox(
              height: 5,
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Ligar lâmpada 1'),
            ),
            SizedBox(
              height: 5,
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Ligar lâmpada 2'),
            ),
            SizedBox(
              height: 5,
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Ligar lâmpada 3'),
            ),
            SizedBox(
              height: 5,
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Ligar lâmpada 4'),
            ),
          ],
        ),
      ),
    );
  }

  _connect() async {
    ProgressDialog progressDialog = ProgressDialog(context,
        blur: 0,
        dialogTransitionType: DialogTransitionType.Shrink,
        title: Text("AWS connecting"),
        message: Text("Connecting"),
        onDismiss: () {});
    progressDialog.setLoadingWidget(CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.red),
    ));
    progressDialog.setMessage(Text("Please wait connecting to AWS"));
    progressDialog.setTitle(Text("Loading"));
    progressDialog.show();

    isConnected = await mqttConnect('esp32poltst');
    if (isConnected = true) {
      progressDialog.dismiss();
    }
  }

  _disconnect() async {
    ProgressDialog progressDialog = ProgressDialog(context,
        blur: 0,
        dialogTransitionType: DialogTransitionType.Shrink,
        title: Text("AWS disconect"),
        message: Text("Disconecting"),
        onDismiss: () {});
    progressDialog.setLoadingWidget(CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.red),
    ));
    progressDialog.setMessage(Text("Please wait until disconect from AWS"));
    progressDialog.setTitle(Text("Loading"));
    progressDialog.show();

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      client.disconnect();
    }
  }

  Future<bool> mqttConnect(String id) async {
    setStatus("Connecting MQTT Broker");

    //reading certificates to connect in AWS iot
    ByteData rootCA = await rootBundle.load('certs/AmazonRootCA1.pem');
    ByteData deviceCert = await rootBundle.load('certs/certificate.pem.crt');
    ByteData privateKey = await rootBundle.load('certs/private.pem.key');

    SecurityContext context = SecurityContext.defaultContext;
    context.setClientAuthoritiesBytes(rootCA.buffer.asUint8List());
    context.useCertificateChainBytes(deviceCert.buffer.asUint8List());
    context.usePrivateKeyBytes(privateKey.buffer.asUint8List());

    client.securityContext = context;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.connectTimeoutPeriod = 2000;
    client.port = 8883;
    client.secure = true;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.pongCallback = pong;
    client.onSubscribed = onSubscribed;

    final connMess = MqttConnectMessage().withClientIdentifier(id).startClean();

    client.connectionMessage = connMess;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('EXAMPLE::socket exception - $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Connected to AWS successfully!');
      return true;
    } else {
      print('Error during the connection proces!!');
      client.disconnect();
      return false;
    }

/*     const pub = 'esp32/pub';
    const sub = 'esp32/sub';

    //client.subscribe(pub, MqttQos.atMostOnce);

    final builder = MqttClientPayloadBuilder();
    builder.addString('Hello AWS');

    try {
      client.publishMessage(pub, MqttQos.exactlyOnce, builder.payload!);
    } on InvalidMessageException catch (e) {
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    }
    return true; */
  }

  void setStatus(String content) {
    setState(() {});
  }

  void onConnected() {
    setStatus("Client connected!!");
  }

  void onDisconnected() {
    setStatus("Client loose the connection");
  }

  void pong() {
    print('Ping response client callback invoked');
  }

  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
  }
}
