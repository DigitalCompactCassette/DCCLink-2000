''***************************************************************************
''* I2S/Serial Analyzer for DCC-Link
''* Copyright (C) 2018 Jac Goudsmit
''*
''* TERMS OF USE: MIT License. See bottom of file.                                                            
''***************************************************************************
''

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ

  hw:           "hardware"
  tx:           "txx"
  so2:          "syncser"

VAR
  long  tx_cmd_ptr              ' Pointer to store commands for debug output
  byte  so2buffer[64]           ' Buffer for data from SO2
  
PUB main

  ' The synchronous serial port runs at approximately 380 kbits/second.
  tx_cmd_ptr := tx.Start(hw#pin_TX, 1_000_000)

  ' Announce us and make sure TXX is settled
  waitcnt(CLKFREQ * 5 + CNT)
  tx.Str(string("DCC-175 synchronous serial analyzer",13))
  tx.Wait

  ' Start the serial monitor for the output channel 
  so2.Start(hw#pin_SCK2, hw#pin_SO2, hw#pin_LED1, @so2buffer, 32, tx_cmd_ptr) 
    
  ' Wake up the DCC recorder
  OUTA[hw#pin_WAKEUP]:=0
  DIRA[hw#pin_WAKEUP]:=1

  ' Loop forever  
  repeat while true
              
DAT

                        org     0
logicprobe
                        mov     dira, outputmask
loop                        
                        test    mask_PROBE, ina wc
                        muxc    outa, mask_LED1
                        muxnc   outa, mask_LED2
                        jmp     #loop

outputmask              long    hw#mask_LED1 | hw#mask_LED2
mask_LED1               long    hw#mask_LED1
mask_LED2               long    hw#mask_LED2
mask_PROBE              long    |< hw#pin_0

                                              
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
                                                            