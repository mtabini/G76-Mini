# G76 Mini - A $10 VGA interface for homebrew retrocomputing

![320x240 8BPP palette demo](https://raw.githubusercontent.com/mtabini/G76-Mini/main/img/palette.jpeg?token=GHSAT0AAAAAABTFPRVX3R6AFZ6QSDOHAJCYYSTEFOA)
![640x240 4BPP “high res” palette demo (bonus 80-column text)](https://raw.githubusercontent.com/mtabini/G76-Mini/main/img/palette_highres.jpeg?token=GHSAT0AAAAAABTFPRVWUIKQVOPRYHQJWV7EYSTEEYA)

The G76 Mini is a simple and inexpensive VGA module for homebrew retrocomputing projects. It requires only a handful of easy-to-procure components and can be either integrated into SBC designs or as a standalone board that can interface with most 8-bit architectures (though it was built with the 6502 in mind). You can view a demo of the interface running [on YouTube](https://youtu.be/on7V5krxY_A).

The hardware design uses the EPM240 from the [Max II family](https://www.intel.com/content/dam/altera-www/global/zh_CN/pdfs/literature/hb/max2/max2_mii5v1_01.pdf) by Altera (now Intel), but the SystemVerilog code should be easily portable to other CPLDs or FPGAs, since it doesn't use any proprietary IP. The EPM240, while technically obsolete, can easily be obtained for around $3 (as of May 2022) on eBay or AliExpress; with the added cost of SRAM and passives, the interface can be incorporated into an existing design for around $5, or built as a standalone board for around $10.

It is additionally possible to completely avoid having to solder SMD parts by purchasing a MAX II EPM240 minimal development board and building a shield on top of it. These typically cost $10 on sites like AliExpress and come with a USB Blaster JTAG programmer to boot.

## Features

The G76 Mini supports these features:

- Completely asynchronous operation; you should be able to just bitbang data into the registers at the typical speeds supported by most hobbyist retrocomputing projects.
- 320x240 resolution at 8BPP (RRRGGGBB), rendered as a 640x480 @ 60Hz standard VGA signal.
- 640x240 resolution at 4BPP “high res” mode using a CGA-like palette, capable of 80x30 text (though you will have to implement the text rendering in software).
- Full read and write access to the video RAM through a set of interface registers.
- Hardware-accelerated vertical scrolling (handy for text displays).
- Toggable self-incrementing X coordinate for faster data transfers.
- Active-low interrupt when entering the non-visible area at the bottom of the screen.

### Features that almost made the cut

The design doesn't support tiling or sprites; there just isn't enough space for them in the EPM240. This is something that I eventually plan to add (possibly after some additional cleanup), but it will likely require more expensive—or, at least, more powerful—hardware.

It should be possible to rewrite the video rendering code to use the 640x400 @ 72Hz VGA mode, thus supporting 8PP even in high-res mode. I am not sure, however, that the design would still fit in an EPM240, and every monitor in my possession struggles to support that resolution, so I didn't really bother with it. An interesting alternative would be to still use 640x480 @ 60Hz, but only render 400 vertical lines through the judicious use of borders.

Finally, there currently is no reset mechanism. Though initially an oversight, this eventually proved to be a requirement to fit the design within the available number of gates.

## Programming guide

The G76 Mini implements 6 addressable 8-bit registers:

| Address | Description |
| --- | --- |
| 0 | Low 8-bits of X coordinate |
| 1 | Bit 0: High bit of X coordinate<br>Bits 1-7: Unused |
| 2 | Y coordinate |
| 3 | Pixel Data |
| 4 | Control<br>Bit 0: Enable/disable X coordinate auto-increment<br>Bit 1: Enable/disable high res mode<br>Bit 2: Enable/disable vertical blank interrupt signal<br>Bit 3: Vertical blank status (read-only)<br>Bits 4-7: Unused<br><br>Writing to this register also clears the vertical blanking interrupt.|
| 5 | Y Offset |

In order to write a single pixel, you first set the X and Y coordinates (in any order), then write the appropriate color value in the Pixel Data register. The new value is placed in the interface's internal memory approximately 60ns later, at which point the system is ready for a new pixel (note, however, that you can start setting new coordinates after only approximately 20ns). Unless auto-increment mode is on, the X and Y coordinates are preserved indefinitely; this helps minimize the need to write data to the coordinate registers, thus speeding up operations.

Reading works in the same way, including support for automatic X-coordinate increment.

### Using auto-increment mode

If Bit 0 of the Control register is set, the internal address pointer is incremented by 1 every time a new value is written to or read from the Pixel Data register. This allows you to read and write entire rows of pixels without having to reset the coordinates every time. 

Note that the increment mechanism is unaware of the system's internal memory layout; thus, if you are in high-res mode, the X coordinate is incremented by _two_ pixels with every access, and, if you exceed the horizontal resolution, you will have to access another 80 values to the Pixel Data register before ending up at the beginning of the next visible line (in practice, you will simply want to reset your coordinates to the beginning of the next line).

### Using hardware-accelerated Y scrolling

Writing a value into the Y Offset register causes the display to be shifted down (that is, scroll up) by a corresponding number of lines. This feature is designed to aid in the implementation of text displays, since the G76 Mini doesn't support any text modes and re-rendering the entire screen would be exceedingly slow. Instead, when the cursor reaches the end of the screen, a new line of text can be rendered beyond the bottom of the display (i.e.: starting at row 240), and then the Y Offset register incremented by the pixel height of the font used.

Note that the Y coordinate register is _relative_ to the Y offset. That means that “Y coordinate 0” is always the top row of the _visible_ portion of the display, regardless of what the Y Offset register is set to.

### Using high-res mode

When bit 1 of the Control register is set, the interface switches to “high res” mode, which displays 640x240 pixels at 4BPP; if you use an 8x8 pixel font, this allows you to display text at 80 columns by 30 rows.

In this mode, each nibble describes a pixel, which is rendered using a palette that approximates the original 16-color CGA mode:

| Value | Color |
| --- | --- |
| 0 | Black |
| 1 | Blue |
| 2 | Green |
| 3 | Cyan | 
| 4 | Red |
| 5 | Magenta |
| 6 | Brown |
| 7 | Grey |
| 8 | Dark grey |
| 9 | Light blue |
| 10 | Light green |
| 11 | Light cyan |
| 12 | Light red |
| 13 | Light magenta |
| 14 | Yellow |
| 15 | White |

Note that the X coordinate register is unaware of the difference in resolution between standard and high-res modes; therefore, you can only really address two pixels at a time, and will always end up accessing an even coordinate by default (e.g.: writing a byte to “x coordinate 0” writes both pixels at `x=0` and `x=1`). This is caused by the fact that, internally, reading a byte value so that individual bits could be updated would be too time-intensive, and so I left it purposefully out of the design. It makes high-res mode much less useful for dynamic display, though it is, of course, still possible to do so.

## Synchronizing with the screen's vertical refresh

If you enable bit 2 of the Control Register, the system brings the  `/VOUT_IRQ` line low when the screen rendering enters the vertical blanking interval, thus allowing you to synchronize your screen updates to the monitor's natural refresh rate for flicker-free animations.

Note that the line remains asserted low until you write any value to the Control register (you can simply read the register and write back onto itself so that you won't make any changes to it), or until you disable interrupts altogether. This is important: If you don't clear the interrupt before exiting your interrupt handler, your computer will likely get stuck in a perpetual loop!

When writing software for a computer that uses the G76 Mini, you should plan for the fact that the interface could be pulling the IRQ line low on soft boot, and therefore should clear it explicitly on boot before you allow the CPU to process interrupts.

If you don't want to deal with interrupts at all, you can simply synchronously observe bit 3 of the Control register, which the interface sets to 1 whenever the raster is in the blanking interval.

## Hardware interface

The hardware interface requires 8 data lines and 3 address lines to access the registers, as well as a Chip Select (active high), and a Read/Write (active low) line. Data is written on the rising edge of Read/Write when Chip Select is high. Data and address lines need to be valid for approximately 20ns after Read/Write rises to allow the CPLD to read the values.

Optionally, a `/VOUT_IRQ` line, active low, can be used to detect when the display raster enters the non-visible zone at the end of the screen; this enables synchronized rendering to avoid flickering.

The interface operates at 3.3V and is **not 5V safe.** Interoperation with a 5V design should be possible using a level shifter, but this is as yet untested.

## Interfacing considerations

The G76 Mini reads data when the `MPU_CS` signal goes high (and, for write operations, when the `/MPU_WE` signal goes low). This makes it compatible with most 8-bit CPUs like the Z80 and 6502, so long as you provide the glue logic required to control the `MPU_CS` signal.

In a design based on the 6502, this means that you will need to qualify `MPU_CS` with the CPU's clock signal, because the CPU doesn't place a valid address on the bus until the high part of the clock cycle. Thus, `MPU_CS` can only go high at the same time as the `PHI2` signal that provides the clock.

## Reference design

I have included a [simple reference design](/reference_design/schematic.pdf) ([B/W version](/reference_design/schematic_bw.pdf)) for a standalone video card in the project. As you can see from the schematic, the interface really only needs a handful of components and is quite simple, since it depends so heavily on the CPLD.

The VGA output is generated using a few resistors, and is of surprisingly good quality, especially if you stick with 1% tolerances. An R2R network might produce a more consistent result, and of course a DAC would be best, but it seemed overkill for a homebrew project.

I picked the [CY7C1018DV33-10VXI](https://www.mouser.ca/datasheet/2/100/CYPR_S_A0001416448_1-2540640.pdf), an inexpensive (about $3.50 from any major North American distributor as of April 2022) 128kiB, 10ns SRAM chip from Cypress as the video memory for the reference design. I suspect that any 3.3V-compatible chip with cycle times of 20ns or faster would work equally well, though I have not tested with anything else.

### Programming the CPLD

The Max II can be programmed using Altera's [USB Blaster](https://www.intel.com/content/www/us/en/products/sku/215633/intel-fpga-download-cable/specifications.html), which has been imaginatively renamed the “FPGA Download Cable” by Intel. (Perhaps they should change their name to “Chip Manufacturing Corporation”.) Clones of the USB Blaster are readily available on Amazon, eBay, and AliExpress for just a few dollars—in fact, most sellers bundle it with their Max II development boards, which are sometimes cheaper than the JTAG programmer alone.

The G76 Mini's SystemVerilog source can be compiled using Quartus II; you should be able to just open the [VGA320.qpf](./VGA320.qpf) project and, provided that you use the same pinout as I did, compile and write it to the hardware. 

Figuring out how to actually connect the CPLD to your computer can be a frustrating experience; the Max II is officially obsolete, and supported only by older versions of Quartus. Unfortunately, these come with unsigned drivers that cannot be installed on Windows 10, leading to much confusion.

In the end, this process worked for me:

- Install [Quartus II Web Edition 13.0sp1](https://www.intel.com/content/www/us/en/software-kit/711791/intel-quartus-ii-web-edition-design-software-version-13-0sp1-for-windows.html), which includes the IP required to compile against the Max II.
- Then install [Quartus II Prime Lite 21.1](https://www.intel.com/content/www/us/en/software-kit/684216/intel-quartus-prime-lite-edition-design-software-version-21-1-for-windows.html), which includes drivers for USB Blaster that are compatible for Windows 10.

You can then use Quartus II Prime Lite 21.1 to both compile and upload your design to the CPLD. Note, however, that I arrived at this setup after much fidgeting with both the software and the operating system, so it's possible that I did something else in addition to installing those two pieces of software and don't remember. As always, YMMV.

### Theory of operation

The system is written in SystemVerilog and is composed of four main modules:

- [VGA](./VGA.sv) is the top-level interface that glues everything together and connects to the outside world.
- [MemoryManager](./memory_manager.sv) provides overall pacing synchronized to the main 50MHz clock signal, and primarily dictated by having to share access to the external RAM between video output and MPU write access.
- [VideoOutput](./video_output.sv) generates the VGA output and sync signals, in addition to the vertical refresh IRQ.
- [MPUInterface](./mcu_interface.sv) manages the interface with the external processing unit bus.

MemoryManager operates on a sequence made up of four clock cycles:

- During the first clock cycle, it reads the byte at the address requested by the VideoOutput module and sets up either a read or write operation if requested by MPUInterface.
- During the second cycle, it starts the read or write operation, if one is pending.
- During the third cycle, it concludes the read or write operation and notifies MPUInterface. If a read was requested, the it also makes the corresponding data available.
- During the last cycle, it sets the memory bus up for the next video data read.

This effectively results in 2 memory operations occurring at 12.5MHz, which is sufficient for a horizontal resolution of 320 pixels at 8BPP. Given that the CY7C1018DV33 has a read/write cycle of 10ns, there is plenty of headroom, and a faster clock (or cleverer algorithm) may result in more bandwidth.

The VideoOutput module is little more than a glorified counter; it simply keeps track of the raster position, issues the appropriate sync signals to the VGA interface, and ensures that the right pixel is being output at all times. Note that the system operates at a pixel clock 25MHz, which is _technically_ out of spec, as [the standard](http://tinyvga.com/vga-timing/640x480@60Hz) expects 25.175MHz. I suspect that most modern monitors will be fine with it (mine reports a 61Hz signal, but doesn't seem to care), but older CRTs may be unhappy and possibly even damaged by the signal. Please keep this in mind!

When it receives a request to write pixel data, MPUInterface raises a flag that is synchronized with the main clock; when the sync occurs, the code sends a write requests to MemoryManager. Thus, while a write should take around 60ns, it should be possible to start writing new data to the coordinate registers much sooner. In my tests, the interface works flawlessly with a 6502 running at 13MHz (which is the fastest clock supported by my experimental computer--the G76 Mini may actually work at even faster speeds).

## Reporting bugs and contributing

This is only my first Verilog project, and my background is not in hardware design. While things seem to work to me, I suspect that there are plenty of bugs, and that the design could be optimized significantly. If you find something broken, please open an issue—and if you would like to contribute any enhancements, please open a PR.

Do note that I am also not a Windows user… if you're having trouble installing Quartus or the USB Blaster drivers, I will probably be of limited use.
