library modbus_client_serial;

import 'package:libserialport/libserialport.dart';
import 'package:modbus_client/modbus_client.dart';

export 'src/modbus_client_serial.dart';

/// Serial baud rates definition
enum SerialBaudRate implements ModbusIntEnum {
  b200(200),
  b300(300),
  b600(600),
  b1200(1200),
  b1800(1800),
  b2400(2400),
  b4800(4800),
  b9600(9600),
  b19200(19200),
  b28800(28800),
  b38400(38400),
  b57600(57600),
  b76800(76800),
  b115200(115200),
  b230400(230400),
  b460800(460800),
  b576000(576000),
  b921600(921600);

  const SerialBaudRate(this.intValue);

  @override
  final int intValue;
}

/// Serial data bits definition
enum SerialDataBits implements ModbusIntEnum {
  bits5(5),
  bits6(6),
  bits7(7),
  bits8(8),
  bits9(9);

  const SerialDataBits(this.intValue);

  @override
  final int intValue;
}

/// Serial stop bits definition
enum SerialStopBits implements ModbusIntEnum {
  none(0),
  one(1),
  //oneAndHalf(3), not supported with current implementation!
  two(2);

  const SerialStopBits(this.intValue);

  @override
  final int intValue;
}

/// Serial parity definition
enum SerialParity implements ModbusIntEnum {
  none(SerialPortParity.none),
  odd(SerialPortParity.odd),
  even(SerialPortParity.even),
  mark(SerialPortParity.mark),
  space(SerialPortParity.space);

  const SerialParity(this.intValue);

  @override
  final int intValue;
}

/// Serial flow control definition
enum SerialFlowControl implements ModbusIntEnum {
  none(SerialPortFlowControl.none),
  xonXoff(SerialPortFlowControl.xonXoff),
  rtsCts(SerialPortFlowControl.rtsCts),
  dtrDsr(SerialPortFlowControl.dtrDsr);

  const SerialFlowControl(this.intValue);

  @override
  final int intValue;
}
