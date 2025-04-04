import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_serial/modbus_client_serial.dart';

enum ModbusType { rtu, ascii }

Future<String?> discover(
    {required int unitId,
    required ModbusType type,
    SerialBaudRate baudRate = SerialBaudRate.b19200,
    SerialDataBits dataBits = SerialDataBits.bits8,
    SerialStopBits stopBits = SerialStopBits.one,
    SerialParity parity = SerialParity.none,
    SerialFlowControl flowControl = SerialFlowControl.rtsCts,
    Duration responseTimeout = const Duration(seconds: 1)}) async {
  var dummyRequest = ModbusInt16Register(
          address: 6666,
          name: "dummy register",
          type: ModbusElementType.holdingRegister)
      .getReadRequest(unitId: unitId, responseTimeout: responseTimeout);
  for (var dev in ["COM4", "COM3", "COM2", "COM1"]) {
    late ModbusClientSerial client;
    if (type == ModbusType.rtu) {
      client = ModbusClientSerialRtu(
          portName: dev,
          baudRate: baudRate,
          dataBits: dataBits,
          stopBits: stopBits,
          parity: parity,
          flowControl: flowControl);
    } else {
      client = ModbusClientSerialAscii(
          portName: dev,
          baudRate: baudRate,
          dataBits: dataBits,
          stopBits: stopBits,
          parity: parity,
          flowControl: flowControl);
    }
    var res = await client.send(dummyRequest);
    if (res == ModbusResponseCode.requestSucceed ||
        res.isStandardModbusExceptionCode) {
      return dev;
    }
  }
  return null;
}

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  var port = await discover(unitId: 1, type: ModbusType.rtu);

  // Create a modbus int16 register element
  var batteryTemperature = ModbusInt16Register(
      name: "BatteryTemperature",
      type: ModbusElementType.inputRegister,
      address: 22,
      uom: "°C",
      multiplier: 0.1,
      onUpdate: (self) => print(self));

  // Create the modbus client.
  var modbusClient = ModbusClientSerialRtu(portName: "COM2", unitId: 1);

  // Send a read request from the element
  var res = await modbusClient.send(batteryTemperature.getReadRequest());
  print(res);

  // Ending here
  modbusClient.disconnect();
}
