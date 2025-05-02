;
; Client side linkage for a C64 module in $A000 banked memory
;

%import lib

libbank {
    const uword loadaddr = $a000
    extsub loadaddr + $00 = start()
    extsub loadaddr + $03 = link(ubyte banknum @A)
    extsub loadaddr + $06 = name() -> str @AY
    extsub loadaddr + $09 = number() -> ubyte @A
    extsub loadaddr + $0c = multiply(ubyte arg0 @A, ubyte arg1 @Y, uword resultptr @R15)
    extsub loadaddr + $0f = args(ubyte arg0 @A, ubyte arg1 @Y) -> ubyte @A, ubyte @Y

    ; library filename
    str library = "bank.lib.r"

    ; unload (free) resources from load
    ; (only if allocated somehow)
    sub unload() -> bool {
        return true
    }

    ; use lib.loadbank() to load into loaddr ($A000 above)
    sub load() -> bool {
        bool result = lib.loadbank(loadaddr, library, true)
        ; cleanup.
        return result
    }

}
