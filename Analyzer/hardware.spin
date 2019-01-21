''***************************************************************************
''* Pin assignments and other global constants
''* Copyright (C) 2018 Jac Goudsmit
''*
''* TERMS OF USE: MIT License. See bottom of file.                                                            
''***************************************************************************
''

CON

  #0

  pin_0                         ' Reserved for SD card                        
  pin_1                         ' Reserved for SD card                                                              
  pin_2                         ' Reserved for SD card                       
  pin_3                         ' Reserved for SD card

  pin_4
  pin_5
  pin_6
  pin_7

  pin_8
  pin_9
  pin_AUDIOR                    ' Analog audio out on Demo board and HID board, right channel
  pin_AUDIOL                    ' Analog audio out on Demo board and HID board, left  channel

  pin_12
  pin_13
  pin_14
  pin_15

  ' 16
  pin_WAKEUP                    ' Wakeup signal (active low) to recorder
  pin_SCK2                      ' Synchronous serial clock from recorder
  pin_SBWS                      ' I2S PASC Word Select from recorder
  pin_SBDAI                     ' I2S PASC to recorder                        

  pin_SBDAO                     ' I2S PASC from recorder
  pin_SO2                       ' Synchronous serial from recorder                         
  pin_SI2                       ' Synchronous serial to recorder
  pin_L3REF                     ' PASC time segment sync
  
  pin_24
  pin_25
  pin_26                        ' LED on the Parallax FLiP
  pin_27                        ' LED on the Parallax FLiP
  
  pin_SCL                       ' I2C clock                                      
  pin_SDA                       ' I2C data
  pin_TX                        ' Serial transmit                        
  pin_RX                        ' Serial receive


  ' LEDs
  pin_LED1      = pin_26
  pin_LED2      = pin_27
  
  ' Bitmasks for LEDs
  mask_LED1     = |< pin_LED1
  mask_LED2     = |< pin_LED2

  ' Use LED 1 as debug output
  pin_DEBUG     = pin_LED1
  mask_DEBUG    = |< pin_DEBUG

  
PUB dummy
{{ The module won't compile without at least one public function }}

CON     
''***************************************************************************
''* MIT LICENSE
''*
''* Permission is hereby granted, free of charge, to any person obtaining a
''* copy of this software and associated documentation files (the
''* "Software"), to deal in the Software without restriction, including
''* without limitation the rights to use, copy, modify, merge, publish,
''* distribute, sublicense, and/or sell copies of the Software, and to permit
''* persons to whom the Software is furnished to do so, subject to the
''* following conditions:
''*
''* The above copyright notice and this permission notice shall be included
''* in all copies or substantial portions of the Software.
''*
''* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
''* OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
''* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
''* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
''* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
''* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
''* THE USE OR OTHER DEALINGS IN THE SOFTWARE.
''***************************************************************************