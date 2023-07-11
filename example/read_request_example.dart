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
