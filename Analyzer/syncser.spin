''***************************************************************************
''* Synchronous serial receiver for DCC-Link
''* Copyright (C) 2018 Jac Goudsmit
''*
''* TERMS OF USE: MIT License. See bottom of file.                                                            
''***************************************************************************
''
''
'' This module reads the communication from the synchronous serial port of
'' the UPD 78058 microcontroller in the Philips DCC-175.
''
'' The synchronous serial port uses a clock line and two data lines (one for
'' transmit, one for receive). The clock is always generated by the
'' microcontroller, and transmitting and receiving take place at the same
'' time. The rising edge of the clock is when the transmitted data is valid
'' and when the microcontroller samples the received data.
''
'' The DCC-175 transmits and receives packets of 32 bytes of data. Each bit
'' takes about 2.64 microseconds of time. There are no startbits or stopbits,
'' but the clock is synchronized to the system clock of the microcontroller,
'' so clock pulses always have the same length. The serial clock remains high
'' when there is no data. There are two bit-times between bytes, and a much
'' longer time between packets.
''
'' This module uses a cog to read the synchronous serial traffic on one
'' data line and one clock line. If you want to analyze transmitted traffic
'' as well as received traffic, use two instances of the module. The module
'' also uses one pin as output line for a timer. Multiple instances that
'' use the same serial clock input can also use the same timer output.
'' 
'' To analyze the data, the code uses both timers of the cog: one to measure
'' the exact length of the negative pulse, and the other to detect the end
'' of a byte or the end of a packet.
''  
OBJ

  hw:           "hardware"
  

VAR

  long  cog           ' Cog ID + 1       
    
PUB Start(clockpin, datapin, timerpin, buffer, packetlen, outdataptr)
'' Sets up a synchronous serial port receiver
'' - clockpin   is the input  pin number for the serial clock
'' - datapin    is the input  pin number for the serial data
'' - timerpin   is the output pin number used for the timer
'' - buffer     is a hub address where data is stored. See below
'' - packetlen  is the maximum length of a packet
'' - outdataptr is a pointer to a LONG where incoming data is reported
'' RETURNS: a nonzero value if the cog was started successfully.
''
'' The function starts a cog to read a synchronous serial port and store the
'' incoming data into a double buffer.
''
'' The timer output pin is needed to let the code generate time-outs. The
'' pin shouldn't be connected to anything. The timeouts are generated from
'' the serial clock, so you can share timer pins between multiple instances
'' of this module, but ONLY if all those instances use the same clockpin.
'' If you use multiple instances that use different clock pins, each instance
'' MUST have its own timer pin.
''
'' Data is stored in a buffer that's provided by the caller. The buffer
'' must provide enough storage for TWO packets with the given maximum length.
'' The cog stores incoming bytes as they come in, in consecutive locations
'' starting at the buffer pointer, until a timeout occurs or until the given
'' packet length has been reached. Then it stores data in the output data
'' pointer and switches to the other packet buffer. Only one buffer is in
'' use by the cog at the time (either byte[buffer]..byte[buffer+packetlen-1]
'' or byte[buffer+packetlen]..byte[buffer+packetlen*2-1] ).
''
'' The cog stores a LONG at the output data pointer whenever a buffer is
'' complete. The value of the LONG is compatible with the TXX.spin module
'' and represents a TXX command to generate a hex dump of the buffer that
'' was just received: The low 16 bits of the stored LONG indicate the address
'' (either "buffer" or "buffer+packetlen" depending on which buffer was just
'' filled), and the high word contains the length of the data stored in the
'' buffer, with the high nibble set to the value that makes TXX generate
'' a hexdump.
''
'' This function should only be called from one cog at a time.

  ' Stop if we're already running
  Stop

  ' Set parameters in the pasm code in the hub before starting the cog
  ' This is an easy way to store parameters but it's not safe if the function
  ' may be called from multiple cogs, because if multiple cogs run this code
  ' at the same time, they'll overwrite each others' parameters and at least
  ' one of the syncser cogs will be misconfigured.
  ' To fix this, the parameters could be stored in VAR variables and passed
  ' to the cog via PAR. But the problem is not that urgent. I'll fix it
  ' later if necessary. 
  parm_pin_SCK    := clockpin
  parm_pin_DATA   := datapin
  parm_pin_TIMER  := timerpin
  parm_buffer     := buffer
  parm_packetlen  := packetlen
  parm_outdataptr := outdataptr

  ' Start the cog  
  result := (cog := cognew(@syncser, 0) + 1)
  
pub Stop
'' Stop the cog, if necessary

  if cog
    cogstop(cog - 1)

DAT

                        org     0

syncser
                        ' Init

                        ' Read the clock frequency from the hub
                        rdlong  offline_timeout, #0     ' Read CLKFREQ

                        ' Set the mask for the serial clock
                        mov     mask_SCK, #1
                        shl     mask_SCK, parm_pin_SCK

                        ' Set the mask for the timer output pin
                        mov     mask_TIMER, #1
                        shl     mask_TIMER, parm_pin_TIMER

                        ' Set the mask for timer or SCK
                        mov     mask_SCK_TIMER, mask_SCK
                        or      mask_SCK_TIMER, mask_TIMER

                        ' Set the mask for the data pin
                        mov     mask_DATA, #1
                        shl     mask_DATA, parm_pin_DATA
                        
                        ' Timer A is used to measure the length of the LOW
                        ' pulses of the SCLK input. We set FRQA to 2 so that
                        ' for each Propeller clock, PHSA is increased by 2.
                        ' Since the serial clock is symmetrical (because it's
                        ' in sync with the microcontroller clock), the result
                        ' is that at the end of the LOW pulse, PHSA contains
                        ' the total duration of one bit time (i.e. the LOW
                        ' period plus the following HIGH period) of the serial
                        ' clock, measured in Propeller clocks.
                        ' NOTE: The measurement itself is accurate within
                        ' 12.5 nanoseconds if the Propeller is running at
                        ' 80MHz; however external factors such as jitter and
                        ' interference could influence the measurement.
                        ' However, the actual length of the serial clock pulse
                        ' is mostly irrelevant: we just need the measured bit
                        ' time to distinguish between bits within a byte,
                        ' bytes that follow other bytes within the same
                        ' packet, and the starts and ends of packets.                            
                        movs    init_CTRA, parm_pin_SCK ' Set the pin number  
                        mov     CTRA, init_CTRA         ' Timer A measures LOW pulse
                        mov     FRQA, #2                ' Timer A counts up in twos

                        ' Timer B is used in NCO (numerically controlled
                        ' oscillator) mode: the timer output pin is high
                        ' when the most significant bit of PHSB is high.
                        ' We set FRQB to $FFFFFFFF so that PHSB ends up
                        ' counting backwards from the initial value, and when
                        ' a timeout occurs, the PHSA value goes negative and
                        ' the timer pin goes high. We use this to implement
                        ' a wait-with-timeout using the WAITPNE instruction:
                        ' basically whenever we want to wait until the serial
                        ' clock goes LOW (HIGH) with a timeout, we store the
                        ' timeout into the PHSB register and wait for the
                        ' timer pin to not be 0 anymore, or the SCK pin to
                        ' not be HIGH (LOW) anymore.
                        movs    init_CTRB, parm_pin_TIMER ' Set the pin number
                        mov     CTRB, init_CTRB         ' Timer B is NCO                                       
                        mov     FRQB, vFFFFFFFF         ' Timer B counts down

                        ' Set the direction register
                        mov     DIRA, mask_TIMER

                        ' Initialize byte-writing variables
                        mov     current_buffer, parm_buffer
                                                
err_low_timeout
err_too_many_bits
err_not_enough_bits
err_buffer_overflow
reset
                        ' Clear counter for number of received bits in the
                        ' current byte
                        mov     bit_count, #0

                        ' Clear current byte
                        mov     current_byte, #0

                        ' Start storing data at start of the current buffer
                        mov     current_location, current_buffer
                         
                        ' Set timer B to a long timeout. If nothing happens
                        ' before it triggers, we're offline.
                        mov     PHSB, offline_timeout

                        ' Wait for high without timeout
                        waitpeq mask_SCK, mask_SCK

starthigh                        
                        ' At this point, SCK is high. Set everything up for
                        ' when SCK goes low.
                        ' If SCK goes low before we do the next WAIT, our
                        ' measurement of the first bit will be inaccurate.
                        ' That's okay, it will just cause a framing error
                        ' and whatever bits are coming in, will be discarded.

                        ' Clear timer A so it's ready to count
                        mov     PHSA, #0

                        ' Reset the counter that keeps track of how long the
                        ' serial clock stays high. The counter starts at 0
                        ' and is increased for each time a timeout occurs,
                        ' until it reaches 4. Then the counter is held at
                        ' the same value by a MAX instruction so it doesn't
                        ' overflow.
                        '
                        ' We use this counter to count the number of times
                        ' that timer B expires before SCK goes LOW, basically
                        ' measuring the high-time of SCK, expressed in
                        ' bit-times:
                        ' - If there is less than one bit-time between two
                        '   LOW pulses, the new LOW pulse is a bit that's
                        '   part of the same byte as the previous LOW pulse.
                        ' - Otherwise, if there is less then three bit-times
                        '   between twp LOW-pulses, the new LOW pulse is the
                        '   start of a new byte within the same packet.
                        ' - Otherwise, the end of a packet has been reached
                        '   and it should be marked ready to process.
                        ' The counter starts at 0 and is increased for every
                        ' bit-time timeout in the following code, but a MAX
                        ' instruction keeps it from overflowing.   
                        mov     num_high_timeouts, #0
waitforlow
                        ' Set timer B to the bit time measured during the
                        ' previous LOW pulse. If no previous measurements
                        ' have been done or if the state machine had to be
                        ' reset, the bit time is set to a high value so
                        ' that we don't time out easily.  
                        mov     PHSB, bit_time

                        ' Wait for Not(SCK HIGH and Timer pin LOW)
                        ' In other words: wait for SCK=LOW or Timer=HIGH
                        waitpne mask_SCK, mask_SCK_TIMER
                        
                        ' If SCK is LOW, we're done here. Timer A is
                        ' measuring the length of the LOW period, we just
                        ' need to wait until SCK is high again.
                        test    mask_SCK, INA wz        ' ZF=1 if SCK=LOW
              if_z      jmp     #startlow

                        ' Timeout waiting for LOW pulse.
                        ' We're either at the end of a byte or at the end
                        ' of a packet.
                        '
                        ' Increase timeout counter
                        add     num_high_timeouts, #1

                        ' If this was the first timeout after a LOW pulse,
                        ' we should be at the end of a byte.
                        cmp     num_high_timeouts, #1 wz ' ZF=1 if first timeout
              if_z      jmp     #process_byte

                        ' If there were 8 bit times after the last LOW pulse,
                        ' this is the end of a packet. Otherwise, keep looping.
                        cmp     num_high_timeouts, #8 wz ' ZF=1 if 8 timeouts
              if_nz     jmp     #waitforlow

process_packet                                    
                        ' We've detected the end of a packet.
                        ' Send a TXX huxdump command to the output pointer.
                        '                        
                        ' Determine length.
                        ' If there's nothing in the buffer, reset.
                        ' TODO: If this happens a few times, signal OFFLINE state
                        mov     x, current_location
                        sub     x, current_buffer wz    ' x=current length
              if_z      jmp     #reset                                  

                        ' Process into a command for TXX
                        shl     x, #16                  ' Move length to high word
                        or      x, current_buffer       ' Add the 16-bit address
                        or      x, v80000000            ' Set high bit for hexdump
                        wrlong  x, parm_outdataptr      ' Start dumping

                        ' Now switch to the other buffer
                        cmp     current_buffer, parm_buffer wz ' ZF=1 when using first buffer
                        mov     current_buffer, parm_buffer
              if_z      add     current_buffer, parm_packetlen

                        ' Reset the parser
                        ' This also resets the current store pointer
                        jmp     #reset                                                                    

process_byte
                        ' Store the current byte into the current packet
                        '
                        ' Make sure the byte has been received completely
                        cmp     bit_count, #8 wc        ' CF=1 not enough bits
              if_c      jmp     #err_not_enough_bits 

                        ' Make sure there's space in the current buffer
                        mov     x, current_location
                        sub     x, current_buffer       ' x=current length
                        cmp     x, parm_packetlen wc    ' CF=0 if at max packet len
              if_nc     jmp     #err_buffer_overflow           

                        ' Store the current byte
                        shr     current_byte, #24       ' Shift to lowest 8 bits
                        wrbyte  current_byte, current_location
                        add     current_location, #1

                        jmp     #waitforlow

startlow
                        ' At this point, SCK is LOW.
                        ' TODO: reset OFFLINE state
                        '
                        ' While timer A measures the duration of the LOW
                        ' pulse, we don't have anything to do but wait
                        ' until SCK goes HIGH again.
                        mov     PHSB, offline_timeout
waitforhigh
                        ' Wait for Not(SCK LOW and Timer pin LOW)
                        ' In other words: Wait for SCK=HIGH or Timer=HIGH
                        ' Once that happens, sample the inputs immediately
                        ' so the serial data line is read at (pretty much)
                        ' the same time as the serial clock goes HIGH.
                        waitpne zero, mask_SCK_TIMER
                        mov     x, INA

                        ' If SCK still low, it means we got a timeout
                        test    mask_SCK, x wz          ' ZF=1 if SCK low
              if_z      jmp     #err_low_timeout

                        ' SCK is definitely HIGH.
                        ' At this point, we know we got a valid bit.
                         
                        ' Make sure that we're okay to receive it
                        cmp     bit_count, #8 wc        ' CF=1 if bitcount<8
              if_nc     jmp     #err_too_many_bits              

                        ' Rotate data into current byte
                        test    x, mask_DATA wc         ' CF=1 if data bit=1
                        rcr     current_byte, #1
                                                
                        ' Increase bit count
                        add     bit_count, #1

                        ' Store LOW period time
                        mov     bit_time, PHSA

                        ' Continue processing for HIGH state
                        jmp     #starthigh                                                       

                        ' Constants
zero                    long    0                       ' Zero
v80000000               long    $80000000               ' High bit set                        
vFFFFFFFF               long    $FFFFFFFF               ' -1                        
init_CTRA               long    (%01100 << 26)          ' Count LOW time. SCK pin to be added
init_CTRB               long    (%00100 << 26)          ' Generate timeout on pin. Pin to be added

                        ' Parameters
parm_pin_SCK            long    0                       ' Pin number for serial clock input
parm_pin_DATA           long    0                       ' Pin number for serial data
parm_pin_TIMER          long    0                       ' Pin number for timer output
parm_buffer             long    0                       ' Location of double buffer
parm_packetlen          long    0                       ' Max packet length in bytes
parm_outdataptr         long    0                       ' Output data pointer                                

                        ' Uninitialized variables
x                       res     1                       ' Multi-purpose scratch variable                        
mask_TIMER              res     1                       ' Bitmask for timer pin                        
mask_SCK                res     1                       ' Bitmask for serial clock pin
mask_SCK_TIMER          res     1                       ' Bitmask for serial clock + timer pins
mask_DATA               res     1                       ' Bitmask for serial data pin
current_byte            res     1                       ' Byte value currently being received
current_location        res     1                       ' Location to store next byte
current_buffer          res     1                       ' Start of current buffer
bit_count               res     1                       ' Number of bits in current byte
num_high_timeouts       res     1                       ' Number of timeouts while SCK high        
bit_time                res     1                       ' Measured half-bit time x2
offline_timeout         res     1                       ' Copied from CLKFREQ (long[0])                                         
                                                                         
                                     
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
                                                            