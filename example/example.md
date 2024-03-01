## Read request

``` dart
import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_serial/modbus_client_serial.dart';

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

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
  await modbusClient.send(batteryTemperature.getReadRequest());

  // Ending here
  modbusClient.disconnect();
}
```

## Group read request

``` dart
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
}

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  // Create a modbus elements group
  var batteryRegs = ModbusElementsGroup([
    ModbusEnumRegister(
        name: "BatteryStatus",
        type: ModbusElementType.holdingRegister,
        address: 37000,
        enumValues: BatteryStatus.values),
    ModbusInt32Register(
        name: "BatteryChargingPower",
        type: ModbusElementType.holdingRegister,
        address: 37001,
        uom: "W",
        description: "> 0: charging - < 0: discharging"),
    ModbusUint16Register(
        name: "BatteryCharge",
        type: ModbusElementType.holdingRegister,
        address: 37004,
        uom: "%",
        multiplier: 0.1),
    ModbusUint16Register(
        name: "BatteryTemperature",
        type: ModbusElementType.holdingRegister,
        address: 37022,
        uom: "°C",
        multiplier: 0.1),
  ]);

  // Create the modbus client.
  var modbusClient = ModbusClientSerialRtu(portName: "COM2", unitId: 1);

  // Send a read request from the group
  await modbusClient.send(batteryRegs.getReadRequest());
  print(batteryRegs[0]);
  print(batteryRegs[1]);
  print(batteryRegs[2]);
  print(batteryRegs[3]);

  // Ending here
  modbusClient.disconnect();
}
```

## Write request

``` dart
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

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  var batteryStatus = ModbusEnumRegister(
      name: "BatteryStatus",
      address: 11,
      type: ModbusElementType.holdingRegister,
      enumValues: BatteryStatus.values,
      onUpdate: (self) => print(self));

  var modbusClient = ModbusClientSerialRtu(portName: "COM2", unitId: 1);

  var req = batteryStatus.getWriteRequest(BatteryStatus.running);
  var res = await modbusClient.send(req);
  print(res.name);

  modbusClient.disconnect();
}
```

## File records write and read example

``` dart
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_serial/modbus_client_serial.dart';

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  // Create the modbus client.
  var modbusClient = ModbusClientSerialRtu(portName: "COM1", unitId: 1);

  // Write two file records
  var r1 = ModbusFileUint16Record(
      fileNumber: 4,
      recordNumber: 1,
      recordData: Uint16List.fromList([12573, 56312]));
  var r2 = ModbusFileDoubleRecord(
      fileNumber: 3,
      recordNumber: 9,
      recordData: Float64List.fromList([123.5634, 125756782.8492]));
  await modbusClient.send(ModbusFileRecordsWriteRequest([r1, r2]));

  // Read two file records
  r1 = ModbusFileUint16Record.empty(
      fileNumber: 4, recordNumber: 1, recordDataCount: 2);
  r2 = ModbusFileDoubleRecord.empty(
      fileNumber: 3, recordNumber: 9, recordDataCount: 2);
  await modbusClient.send(ModbusFileRecordsReadRequest([r1, r2]));

  // Write multiple records
  var multipleRecords =
      ModbusFileMultipleRecord(fileNumber: 4, recordNumber: 1);
  multipleRecords.addNext(ModbusRecordType.int16, -123);
  multipleRecords.addNext(ModbusRecordType.uint16, 5000);
  multipleRecords.addNext(ModbusRecordType.int32, -1234567890);
  multipleRecords.addNext(ModbusRecordType.uint32, 1234567890);
  multipleRecords.addNext(ModbusRecordType.float, 123.45);
  multipleRecords.addNext(ModbusRecordType.double, 12345.6789);
  await modbusClient.send(multipleRecords.getWriteRequest());

  multipleRecords = ModbusFileMultipleRecord.empty(
      fileNumber: 4, recordNumber: 1, recordDataByteLength: 24);
  await modbusClient.send(multipleRecords.getReadRequest());
  multipleRecords.start();
  print(multipleRecords.getNext(ModbusRecordType.int16));
  print(multipleRecords.getNext(ModbusRecordType.uint16));
  print(multipleRecords.getNext(ModbusRecordType.int32));
  print(multipleRecords.getNext(ModbusRecordType.uint32));
  print(multipleRecords.getNext(ModbusRecordType.float));
  print(multipleRecords.getNext(ModbusRecordType.double));

  // Ending here
  modbusClient.disconnect();
}
```
