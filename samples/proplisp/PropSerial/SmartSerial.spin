'
' SmartSerial.spin2
' simple smart pin serial object for P2 eval board
' implements a subset of FullDuplexSerial functionality
'
CON
  _txmode       = %0000_0000_000_0000000000000_01_11110_0 'async tx mode, output enabled for smart output
  _rxmode       = %0000_0000_000_0000000000000_00_11111_0 'async rx mode, input  enabled for smart input

VAR
  long rx_pin, tx_pin

PUB start(rxpin, txpin, mode, baudrate) | bitperiod, txmode, rxmode
  bitperiod := 7 + ((CLKFREQ / baudrate) << 16)
  rx_pin := rxpin
  tx_pin := txpin
  txmode := _txmode
  rxmode := _rxmode
  wrpin_(txmode, txpin)
  wxpin_(bitperiod, txpin)
  dirh_(txpin)
  wrpin_(rxmode, rxpin)
  wxpin_(bitperiod, rxpin)
  dirh_(rxpin)
  return 1
  
PUB tx(val) | txpin
  txpin := tx_pin
  wypin_(val, txpin)
  waitx_(1)
  txflush

PUB txflush | txpin, z
  txpin := tx_pin
  z := 1
  repeat while z <> 0
    asm
      testp txpin wc
   if_c mov z, #0
    endasm

' check if byte received (never waits)
' returns -1 if no byte, otherwise byte

PUB rxcheck : rxbyte | rxpin, z
  rxbyte := -1
  rxpin := rx_pin
  asm
    testp rxpin wc  ' char ready?
    if_c rdpin rxbyte, rxpin
    if_c shr rxbyte, #24
  endasm

' receive a byte (waits until one ready)
PUB rx : v
  repeat
    v := rxcheck
  while v == -1

' transmit a string
PUB str(s) | c
  REPEAT WHILE ((c := byte[s++]) <> 0)
    tx(c)

PUB dec(value) | i, x

'' Print a decimal number
  result := 0
  x := value == NEGX                                                            'Check for max negative
  if value < 0
    value := ||(value+x)                                                        'If negative, make positive; adjust for max negative
    tx("-")                                                                     'and output sign

  i := 1_000_000_000                                                            'Initialize divisor

  repeat 10                                                                     'Loop for 10 digits
    if value => i                                                               
      tx(value / i + "0" + x*(i == 1))                                          'If non-zero digit, output digit; adjust for max negative
      value //= i                                                               'and digit from value
      result~~                                                                  'flag non-zero found
    elseif result or i == 1
      tx("0")                                                                   'If zero digit (or only digit) output it
    i /= 10                                                                     'Update divisor

PUB hex(val, digits) | shft, x
  shft := (digits - 1) << 2
  repeat digits
    x := (val >> shft) & $F
    shft -= 4
    if (x => 10)
      x := (x - 10) + "A"
    else
      x := x + "0"
    tx(x)
