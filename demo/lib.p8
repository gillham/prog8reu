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

        uword endaddress = diskio.loadlib(rl_fname, rl_buf)
        if endaddress == 0 {
            return false
        }

        ; do relocation fixup..
        ubyte libpg = msb(rl_buf)
        ubyte reloc = @(rl_buf+RELOC_BYTE)
        ubyte reloc_min = reloc-1
        ubyte reloc_max = reloc+rl_pages

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

        ; call first function (start) in lib
        if init {
            void call(rl_buf+JMP_SLOT0)
        }

        return true
    }

    ; C64/X16 bank loading.
    sub loadbank(uword rl_buf, str rl_fname, bool init) -> bool {
        uword endaddress = diskio.loadlib(rl_fname, rl_buf)
        if endaddress == 0 {
            return false
        }

        ; call first function (start) in lib
        if init {
            void call(rl_buf+JMP_SLOT0)
        }

        return true
    }
}
