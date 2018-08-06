# DCCLink-2000
Jac Goudsmit

In this repository I'm going to develop the software and hardware to reverse-engineer and re-engineer the functionality of the PC-Link cable that was once available from Philips for use with the DCC-175 Digital Compact Cassette recorder, to make it communicate with a PC running 16-bit Windows.

Because not everyone has a computer with a parallel port and a 16-bit version of Windows in 2018, replicating the original cable from the Philips PCA10DC package is not top priority, though I may get to it sometime.

Please follow the progress of this project on the [Hackaday project page](https://hackaday.io/project/20404).

## Context
The Philips DCC-175 portable digital compact cassette recorder was released in the Netherlands in November 1995. It wasn't released elsewhere, possibly for legal reasons but we can only speculate about that.

This recorder had a feature that was unique across all DCC recorders: it had a special connector where a cable could plug in that would allow a computer to control the recorder.

The cable was available in a separate package with the PCA10DC type name, but it was also possible to buy the recorder and the cable in a bundle package typed PCA11DC. Included with the cable was some software that made it possible to copy tapes to the computer's hard disk and do some simple audio editing. It was also possible to use a DCC tape as backup medium, though this was not very useful because of the low speed (384kbps wasn't much, even in 1995) and because it didn't support the long file names of the brand new Windows 95 and later.

The cable was more than an actual cable: the plug that went into the parallel port of the PC had a few chips in it. One of the chips was produced by Philips Key Modules, and not documented.

This made it impossible for hobbyists to build your own cable, which was unfortunate, especially because many more recorders than cables were produced.

Philips discontinued the Digital Compact Cassette in 1996, because sales had been disappointing. Presumably, it also didn't make sense anymore to focus on digital cassettes, while recordable (and later rewriteable) CD's changed from being a professional medium to a consumer product (Philips released the CDD-2000, one of the first consumer-grade computer CD recorders, at the end of 1996).

## Purpose of this project 
In 1997 I was in contact with someone who had started reverse-engineering the DCC software, to find out how the DCC-175 can be controlled if you have the PC-Link cable.

In 2018, I know a lot more about things such as the I2S protocol, and there are lots of datasheets and service manuals online with information about the DCC-175 and the chips that it uses. And a cable that connects to a parallel port on a computer that runs a 16 bit version of Windows doesn't make that much sense anymore.

I was inspired to get back to the reverse-engineering project but this time I'm taking a different approach: I used a logic analyzer to find out how the DCC-175 communicates with the PC-Link plug, and I decided I want to make a device that replaces not only the cable, but also the PC and the Windows software.

What this is going to look like and how it will work, is not clear yet at the time of this writing. It will use a Propeller because I'm familiar with it; I won't have to buy hardware to get started and I know it's powerful enough to do what I want it to do.

The device will be able to copy a DCC cassette to an SD card (or to a PC via a USB port), and it will be possible to do some simple editing with a jog/shuttle interface.

It should also be possible to copy DCC files back to tape, including track markers and song title information that's compatible with 3rd generation players. Making compilation tapes should be easy.

The ultimate goal would be to use the device to record a tape in the same format as prerecorded tapes, with the Table of Content continuously repeated in the auxiliary track, so it's possible to see (and search for) all the track titles on every DCC recorder. At this time, it's not clear if this is possible.

The datasheet of the Drive Processor chips indicates that anything can be recorded as SYSINFO and AUXINFO. And there is no indication that recording of auxiliary data separately from the audio data is limited in any way. So the only information that's needed to make a drive processor record a prerecorded tape appears to be the information about the data that needs to be recorded as SYSINFO and AUXINFO.

Unfortunately, the PC communicates with the microcontroller in the DCC-175; it doesn't talk directly to the Drive Processor. It's possible that the microcontroller will pass information from the PC straight through to the DRP (which would make it possible to record a prerecorded cassette once the data format can be reverse engineered), but it's not unthinkable that the DCC-175 microcontroller somehow makes it impossible to do this.

## Project Log
For a detailed blog, see the Hackaday project page linked above.

### 2018-08-04
Created the repository and this page
