;
; Client side linker / relocator
; Called by the library's load() function
;

%import diskio
%import textio

lib {
    %option ignore_unused

    const ubyte JMP_SLOT0 = $00
    const ubyte RELOC_BYTE = JMP_SLOT0 + $02

    ; C64/X16 relocatable loading.
    sub loadreloc(uword rl_buf, str rl_fname, ubyte rl_pages, bool init) -> bool {
        ubyte rl_adjust = 0
        uword i = 0
        bool rl_subtract = true

        txt.print("before loading...")
        txt.print(rl_fname)
        txt.nl()
        txt.print("rl_buf: ")
        txt.print_uwhex(rl_buf, true)
        txt.nl()
        uword endaddress = diskio.loadlib(rl_fname, rl_buf)
        txt.print("\nendaddress: ")
        txt.print_uwhex(endaddress, true)
        txt.nl()
        if endaddress == 0 {
            return false
        }

        txt.print("after loading...")
        txt.print_uwhex(rl_buf, true)
        txt.print("...")
        txt.print_uwhex(endaddress, true)
        txt.nl()

        ; do relocation fixup..
        ubyte libpg = msb(rl_buf)
        ubyte reloc = @(rl_buf+RELOC_BYTE)
        ubyte reloc_min = reloc-1
        ubyte reloc_max = reloc+rl_pages

        txt.print("relocating...")
        txt.print_ubhex(reloc, true)
        txt.print(" -> ")
        txt.print_ubhex(libpg, true)
        txt.nl()

        if libpg > reloc {
            rl_subtract = false
            rl_adjust = libpg - reloc
        } else {
            rl_subtract = true
            rl_adjust = reloc - libpg
        }

        for i in 0 to rl_pages*256-1 {
            if rl_buf[i] > reloc_min and rl_buf[i] < reloc_max {
                if rl_subtract {
                    rl_buf[i] = rl_buf[i] - rl_adjust
                } else {
                    rl_buf[i] = rl_buf[i] + rl_adjust
                }
            }
        }

        txt.print("relocation complete.")
        txt.nl()

        ; call first function (start) in lib
        if init {
            void call(rl_buf+JMP_SLOT0)
        }

        return true
    }

    ; C64/X16 bank loading.
    sub loadbank(uword rl_buf, str rl_fname, bool init) -> bool {
        txt.print("loadbank loading... ")
        txt.print(rl_fname)
        txt.spc()
        txt.print_uwhex(rl_buf, true)
        txt.nl()
        uword endaddress = diskio.loadlib(rl_fname, rl_buf)
        if endaddress == 0 {
            return false
        }

        txt.print("after loading...")
        txt.print_uwhex(rl_buf, true)
        txt.print("...")
        txt.print_uwhex(endaddress, true)
        txt.nl()

        ; call first function (start) in lib
        if init {
            txt.print("calling lib start()")
            txt.nl()
            void call(rl_buf+JMP_SLOT0)
        }

        return true
    }
}
