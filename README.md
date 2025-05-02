# Commodore 64 REU banking for Prog8

This module provides RAM banking like the Commander X16, but on the Commodore 64 with an REU.

The banked ram is 8KB from  $A000 to $BFFF like on the Commander X16.
Banked ROM is not supported.

The main module is `src/reu.p8` which detects the presence of the REU and the size of it along with bank switching routines.
The additional module `src/reucompat.p8` provides compatibility routines matching several banking relate routines on Commander X16.

By importing both of these modules you almost directly compile code that relies on Commander X16 banking.

# Compiling.

Just put the two modules with your other source code and import them.  Then call `reu.init()` prior to using any banking features. Typically you would do that immediately in `start()`

```prog8
%import reu
%import reucompat

main {
    sub start() {
        reu.init()
    }
}
```

That is all you need to start using it.  One difference is that you need to call an `init()` routine to detect the presence of the REU and the size.  On a Commander X16 the banking is in the hardware and always present.  On C64 we need to detect if the REU is present.

# Usage

The bare minimum for existing code that use banking was mentioned above, but that doesn't explain much.  Here I'll try to provide a better explanation.

## REU Module

First and foremost you need to `%import reu` to get the base support.  Once it is imported you can use the following sub routines.
```
reu.init() -> uword
reu.detect() -> ubyte, bool
reu.cmd(uword c64addr, uword reuaddr, uword length, ubyte bank, ubyte command)
reu.bank(ubyte banknum)
reu.save(ubyte savebank)
```

The `reu.init()` routine looks for an REU and returns the size in kilobytes or zero if an REU was not found.  With a 512KB REU calling `reu.init()` will return 512.

As part of the initialization process `reu.init()` will update a variable `reu.banks` with the number of detected REU hardware banks. These are REU 64KB banks, not the 8KB logical banks provided for compatibility with the Commander X16.  The number of physical banks can be useful for directly accessing the REU, but isn't important when using 8KB logical banks.

The `reu.detect()` routine does the actual detection and proving of the size of the REU.  It is called by `reu.init()` and typically would not be called directly in your code.  It returns the number of banks as a ubyte and a bool indicating if the REU was actually detected.  If the REU is detected but the banks value is zero, that means a 16MB REU due to the 8 bit value wrapping from 255 back to 0.

The `reu.cmd()` routine is used by this module to control the DMA engine on the REU.  In can be used to directly communicate with the REU, but should not be used if you're using the logical banking functionality.  Unless you are very careful you should not access the REU directly, but use the compatiblity banking functions.

Call `reu.bank()` to switch banks.  These are the 8KB logical banks and switching is as simple as `reu.bank(25)` for example.
Due to the way the REU works, this routine saves (stashes in REU terminology)  the contents of the current bank from $A000-$BFFF back to the correct location in the REU and then fetches the new bank.  That means switching banks moves 16KB of data.  The REU DMA engine can move 1 byte per clock cycle so this bank change will take 16384 cycles.
That is another major difference with the hardware banking in the Commander X16.

The `reu.save()` routine saves the current contents of the 8KB bank to the REU. This is mostly useful when using an emulator like VICE where you want to save the REU image out to a file.
Since the currently active bank is just 8KB of main C64 RAM ($A000-$BFFF) any updated contents will not be written out since the active bank is never stashed in the REU.
This is also useful for something like the RAMLink if you have an REU installed and in direct mode.  The RAMLink can keep the REU powered, but once you power off the C64 the currently active bank is gone and might have been changed from what is in the REU.
Also the 1541 Ultimate II+ and Ultimate64 can save the contents of the REU to a file on the USB storage device. Calling `reu.save()` could be important prior to saving the REU image.

Switching banks always stashes the current bank before fetching the new one.  So switching banks is enough to save the current bank.

To properly save the current bank, without switching to another, you would call it like this.
```
reu.save(reu.current_bank)
```

## REU Compatibility

The compatibility routines in `reucompat.p8` provide routines matching Commander X16 routines. Some of the routines are NOPs like the ROM bank related ones. Only RAM bank compatibility is provided by this module.

This module patches some routines to replace builtin Prog8 routines with version that support banking.  In particular `c64.x16jsrfar()` must be patched to allow using the `@bank 123` notation on `extsub` definitions.

The first 8 banks, either with the `c64.banks()` call or the `@bank` notation correspond with hardware 6510 CPU banking that is builtin to the C64.  Banks 9 through 255 are intercepted and routed to the REU.

Below are the routines in `reucompat.p8`

```
c64.x16jsrfar()
c64.reujsrfar()
cx16.rombank(ubyte bank @A)
cx16.rambank(ubyte bank @A)
cx16.getrombank() -> ubyte @A
cx16.getrambank() -> ubyte @A
cx16.push_rombank(ubyte newbank @A) clobbers(Y)
cx16.pop_rombank()
cx16.push_rambank(ubyte newbank @A) clobbers(Y)
cx16.pop_rambank()
cx16.numbanks() clobbers(X) -> uword @AY
diskio.load(uword filenameptr, uword address_override) -> uword
diskio.loadbank(uword filenameptr, uword address) -> uword
diskio.load_size(ubyte startbank, uword startaddress, uword endaddress) -> uword
```

The `c64.x16jsrfar()` routine is a copy of the standard library routine with a check for banks above 8.  If the bank is above 8 it forwards the request to `c64.reujsrfar()` to complete the call.

All of the "rombank" routines are NOPs and do nothing. They are there for source code compatibility but trying to use anything rombank related will crash.  These may be removed in the future or configured to generate an error message instead.

Most of the work is done by the `cx16.rambank()` routine.  Note that this function deals exclusively with REU banks logical banks.  So there is no restriction on using banks 0-8 with this call.  So the `c64.banks()` or `extsub @bank` can't use rambanks 0-8, but this routine can.  Keep that in mind.

Likewise `cx16.getrambank()` returns only information about the current REU logical bank, not 6510 CPU banking.

With `push_rambank()` and `pop_rambank()` you can conveniently push the current bank to the stack and switch to a new bank.
Then you can pop the previous rambank from the stack and switch back to it.
This saves you from having to keep track of the previous bank, at the cost of another byte on the stack.

The `reu.numbanks()` routine returns the number of logical 8KB banks available. This is currently capped at 256 to match the 2MB limit of the Commander X16.

On the Commander X16 if you call the kernal load routine to load a file into banked memory, the kernal will keep loading the file until the bank is full (or end of file is reached) and switch to the next bank to continue loading.  Once the end of file is reached the call returns.  You should save the current bank number, then load the file, then look at the ending bank number to know how large the file was and what banks are used.

The `diskio.load()` routine replaces the Prog8 builtin routine.  It provides banked based file loading that should be compatible with the method on the Commander X16.

The `diskio.loadbank()` routine is for loading into the bank directly and is used when `diskio.load()` determines the load is meant for banked memory.  Typically you would use `diskio.load()` instead as it handles regular and banked memory.

Call `diskio.load_size()` immediately after a load, and before changing banks.  It will return the size of the file that was loaded by calculating from the start bank, addres, end address, and current bank.

