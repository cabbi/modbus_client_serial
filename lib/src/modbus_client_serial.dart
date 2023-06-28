library modbus_client_serial_impl;

import 'dart:async';
import 'dart:typed_data';

import 'package:libserialport/libserialport.dart';
import 'package:synchronized/synchronized.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_serial/modbus_client_serial.dart';

part 'modbus_client_serial_rtu.dart';
part 'modbus_client_serial_ascii.dart';

/// The serial Modbus client class.
abstract class ModbusClientSerial extends ModbusClient {
  final String portName;
  final SerialBaudRate baudRate;
  final SerialDataBits dataBits;
  final SerialStopBits stopBits;
  final SerialParity parity;
  final SerialFlowControl flowControl;

  final Duration connectionTimeout;
  final Duration responseTimeout;
  final Duration? delayAfterConnect;

  SerialPort? _serialPort;
  SerialPortConfig? _serialConfig;
  final Lock _lock = Lock();

  ModbusClientSerial(
      {required this.portName,
      super.unitId,
      this.baudRate = SerialBaudRate.b19200,
      this.dataBits = SerialDataBits.bits8,
      this.stopBits = SerialStopBits.one,
      this.parity = SerialParity.none,
      this.flowControl = SerialFlowControl.rtsCts,
      this.connectionTimeout = const Duration(seconds: 3),
      this.responseTimeout = const Duration(seconds: 3),
      this.delayAfterConnect});

  /// Returns the serial telegram checksum length
  int get checksumByteCount;

  /// Returns the modbus telegram out of this request's PDU
  Uint8List _getTxTelegram(ModbusRequest request, int unitId);

  /// Read response from device.
  ModbusResponseCode _readResponseHeader(_ModbusSerialResponse response);

  /// Reads the full pdu response from device.
  ///
  /// NOTE: response header should be already being read!
  ModbusResponseCode _readResponsePdu(_ModbusSerialResponse response);

  /// Returns true if connection is established
  @override
  bool get isConnected => _serialPort != null;

  /// Close the connection
  @override
  Future<void> disconnect() async {
    if (_serialConfig != null) {
      _serialConfig!.dispose();
      _serialConfig = null;
    }
    if (_serialPort != null) {
      _serialPort!.close();
      _serialPort!.dispose();
      _serialPort = null;
    }
  }

  @override

  /// Sends a modbus request
  Future<ModbusResponseCode> send(ModbusRequest request,
      {bool autoConnect = true}) async {
    return _lock.synchronized(() async {
      // Connect if needed
      try {
        if (autoConnect) {
          await connect();
        }
        if (!isConnected) {
          return ModbusResponseCode.connectionFailed;
        }
      } catch (ex) {
        ModbusAppLogger.severe(
            "Unexpected exception in connecting to $portName", ex);
        return ModbusResponseCode.connectionFailed;
      }

      // Reset this request in case it was already used before
      request.reset();

      // Send the request data
      var unitId = getUnitId(request);
      try {
        // Flush both tx & rx buffers (discard old pending requests & responses)
        _serialPort!.flush();

        // Sent the serial telegram
        _serialPort!.write(_getTxTelegram(request, unitId), timeout: 2000);
      } catch (_) {
        request.setResponseCode(ModbusResponseCode.requestTxFailed);
        return request.responseCode;
      }

      // Lets check the response header (i.e.read first bytes only to check if
      // response is normal or has error)
      var response = _ModbusSerialResponse(
          request: request,
          unitId: unitId,
          checksumByteCount: checksumByteCount);
      var responseCode = _readResponseHeader(response);
      if (responseCode != ModbusResponseCode.requestSucceed) {
        request.setResponseCode(responseCode);
        return request.responseCode;
      }

      // Lets wait the rest of the PDU response
      var resCode = _readResponsePdu(response);
      if (resCode != ModbusResponseCode.requestSucceed) {
        request.setResponseCode(resCode);
        return request.responseCode;
      }

      // Set the request response based on received PDU
      request.setFromPduResponse(response.pdu);
      return request.responseCode;
    });
  }

  /// Connect the port if not already done or disconnected
  @override
  Future<bool> connect() async {
    if (isConnected) {
      return true;
    }

    // New connection
    _serialPort = SerialPort(portName);
    if (!_serialPort!.openReadWrite()) {
      _serialPort!.dispose();
      return false;
    }

    // Update the config for your setup
    _serialConfig = SerialPortConfig()
      ..baudRate = baudRate.intValue
      ..bits = dataBits.intValue
      ..stopBits = stopBits.intValue
      ..parity = parity.intValue
      ..setFlowControl(flowControl.intValue);
    _serialPort!.config = _serialConfig!;

    // Is a delay requested?
    if (delayAfterConnect != null) {
      await Future.delayed(delayAfterConnect!);
    }

    return true;
  }
}

/// The modbus serial response is composed from:
/// BYTE - UnitId
/// BYTE - Function code
/// BYTE - Modbus exception code if Function code & 0x80 (i.e. bit 8 == 1)
class _ModbusSerialResponse {
  final ModbusRequest request;
  final int unitId;
  final int checksumByteCount;

  _ModbusSerialResponse(
      {required this.request,
      required this.unitId,
      required this.checksumByteCount});

  List<int>? _rxData;
  void setRxData(List<int> rxData) =>
      _rxData = List<int>.from(rxData, growable: true);
  void addRxData(List<int> rxData) => _rxData!.addAll(rxData);

  ModbusResponseCode get headerResponseCode {
    if (_rxData == null || _rxData!.length < 3) {
      return ModbusResponseCode.requestRxFailed;
    }
    if (_rxData![0] != unitId) {
      return ModbusResponseCode.requestRxWrongUnitId;
    }
    if (_rxData![1] & 0x80 != 0) {
      return ModbusResponseCode.fromCode(_rxData![2]);
    }
    if (_rxData![1] != request.functionCode) {
      return ModbusResponseCode.requestRxWrongFunctionCode;
    }
    return ModbusResponseCode.requestSucceed;
  }

  Iterable<int> getRxData({required bool includeChecksum}) => _rxData!
      .getRange(0, _rxData!.length - (includeChecksum ? 0 : checksumByteCount));

  Uint8List get pdu => // serial telegram has: <unit id> + <pdu> + <checksum>
      _rxData == null
          ? Uint8List(0)
          : Uint8List.fromList(
              _rxData!.sublist(1, _rxData!.length - checksumByteCount));

  Uint8List get checksum => _rxData == null
      ? Uint8List(0)
      : Uint8List.fromList(
          _rxData!.sublist(_rxData!.length - checksumByteCount));
}
