import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_serial/modbus_client_serial.dart';

/// The serial Modbus ASCII client class.
class ModbusClientSerialAscii extends ModbusClientSerialAsciiBase {
  ModbusClientSerialAscii(
      {required String portName,
      super.unitId,
      super.connectionMode = ModbusConnectionMode.autoConnectAndKeepConnected,
      SerialBaudRate baudRate = SerialBaudRate.b19200,
      SerialDataBits dataBits = SerialDataBits.bits8,
      SerialStopBits stopBits = SerialStopBits.one,
      SerialParity parity = SerialParity.none,
      SerialFlowControl flowControl = SerialFlowControl.rtsCts,
      super.responseTimeout = const Duration(seconds: 3),
      super.flushOnRequest = true})
      : super(
            serialPort: LibSerialPort(
                portName, baudRate, dataBits, stopBits, parity, flowControl));
}
