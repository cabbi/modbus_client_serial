import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_serial/modbus_client_serial.dart';

enum BatteryStatus implements ModbusIntEnum {
  offline(0),
  standby(1),
  running(2),
  fault(3),
  sleepMode(4);

  const BatteryStatus(this.intValue);

  @override
  final int intValue;

  @override
  String toString() {
    return name;
  }
}

enum MeterStatus implements ModbusIntEnum {
  offline(0),
  normal(1);

  const MeterStatus(this.intValue);

  @override
  final int intValue;

  @override
  String toString() {
    return name;
  }
}

void main() async {
  ModbusAppLogger(Level.FINEST);

  var r0 = ModbusEnumRegister(
      name: "BatteryStatus",
      address: 0,
      type: ModbusElementType.holdingRegister,
      enumValues: BatteryStatus.values);

  var r1 = ModbusUint32Register(
      name: "Daily energy yield",
      address: 14,
      type: ModbusElementType.holdingRegister,
      uom: "kwh",
      multiplier: .01);

  var r2 = ModbusInt16Register(
      name: "BatteryTemperature",
      type: ModbusElementType.holdingRegister,
      address: 22,
      uom: "°C",
      multiplier: 0.1);

/*
  var modbusClient = ModbusClientSerialAscii(
      portName: "COM2", responseTimeout: Duration(seconds: 1), unitId: 1);
*/
  var modbusClient = ModbusClientSerialRtu(
      portName: "COM2", responseTimeout: Duration(seconds: 1), unitId: 1);

  // Single read requests
  modbusClient.send(r0.getReadRequest());
  modbusClient.send(r1.getReadRequest());
  var res = await modbusClient.send(r2.getReadRequest());
  print(r0);
  print(r1);
  print(r2);
  print(res);

  // Register write request
  res = await modbusClient.send(r0.getWriteRequest(BatteryStatus.sleepMode));
  res = await modbusClient.send(r1.getWriteRequest(9999999.87));
  res = await modbusClient.send(r2.getWriteRequest(-32.1));

  // Group of elements
  var regGroup = ModbusElementsGroup([r0, r1, r2]);
  await modbusClient.send(regGroup.getReadRequest());
  print(r0);
  print(r1);
  print(r2);

  // Bit elements
  var b0 = ModbusBitElement(
      name: "myFirstBit", address: 0x03, type: ModbusElementType.coil);
  var b1 = ModbusBitElement(
      name: "mySecondBit", address: 0x10, type: ModbusElementType.coil);
  var b2 = ModbusBitElement(
      name: "myThirdBit", address: 0x11, type: ModbusElementType.coil);

  // Read request
  await modbusClient.send(b0.getReadRequest());
  await modbusClient.send(b1.getReadRequest());
  await modbusClient.send(b2.getReadRequest());
  print(b0);
  print(b1);
  print(b2);

  // Write request
  await modbusClient.send(b0.getWriteRequest(true));
  await modbusClient.send(b1.getWriteRequest(false));
  await modbusClient.send(b2.getWriteRequest(true));
  print(b0);
  print(b1);
  print(b2);

  // Group request
  var bitGroup = ModbusElementsGroup([b0, b1, b2]);
  await modbusClient.send(bitGroup.getReadRequest());
  print(b0);
  print(b1);
  print(b2);

  modbusClient.disconnect();
}
