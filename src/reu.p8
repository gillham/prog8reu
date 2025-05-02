;
; C64 REU banking.
;

%import textio

reu {

    ; memory-mapped ubyte
    &ubyte reu_status           = $df00 ; read-only
    &ubyte reu_cmdreg           = $df01

    ; command bits
    const ubyte REU_EXECUTE     = %10000000
    const ubyte REU_AUTOLOAD    = %00100000
    const ubyte REU_IMMEDIATE   = %00010000
    const ubyte REU_C64TOREU    = %00000000
    const ubyte REU_REUTOC64    = %00000001
    const ubyte REU_DOSWAP      = %00000010
    const ubyte REU_DOCOMPARE   = %00000011

    ; reu commands
    const ubyte REU_FETCH       = REU_EXECUTE|REU_IMMEDIATE|REU_REUTOC64
    const ubyte REU_STASH       = REU_EXECUTE|REU_IMMEDIATE|REU_C64TOREU
    const ubyte REU_SWAP        = REU_EXECUTE|REU_IMMEDIATE|REU_DOSWAP

    ; memory mapped uword
    &uword reu_c64addr          = $df02 ; low, $df03 high
    &uword reu_extaddr          = $df04 ; low, $df05 high

    ; memory-mapped ubyte
    &ubyte reu_extbank          = $df06   

    ; memory mapped uword
    &uword reu_len              = $df07 ; low, $df08 high

    ; memory-mapped ubyte
    &ubyte reu_intmask          = $df09
    &ubyte reu_addrcontrol      = $df0a
    const ubyte REU_ADDRFIXC64  = %10000000
    const ubyte REU_ADDRFIXREU  = %01000000
    &ubyte reu_start            = $ff00 ; write anything to start

    ; is an REU present?
    bool present = false
    ; current bank
    ubyte current_bank = 0
    ; number of reu real banks (256 max)
    uword banks = 0
    ; number of simulated 8KB banks
    uword rambanks = 0

    ;
    ; Detect an REU and return size in KB
    ; detect() is currently destructive.
    ;
    sub init() -> uword {
        uword size = 0
        ubyte detectbanks
        detectbanks, present = detect()

        if present {
            rambanks = 256
            banks = detectbanks
            when detectbanks {
                $00 -> {
                    banks = 256
                    size=16384
                }
                $7f -> { size=8192 }
                $3f -> { size=4096 }
                $1f -> { size=2048 }
                $0f -> {
                    rambanks=128
                    size=1024
                }
                $07 -> {
                    rambanks=64
                    size=512
                }
                $03 -> {
                    rambanks=32
                    size=256
                }
                $01 -> {
                    rambanks=16
                    size=128
                }
            }
        }
        return size
    }

    ;
    ; Detect an REU and its size in banks.
    ; TODO: Make this use the raster line
    ; detection method. Make size detection
    ; non-destructive
    ;
    sub detect() -> ubyte, bool {
        ubyte[] signature = [$00, 'p', 'r', 'o', 'g', '8', 'r', 'e', 'u']
        ubyte[] xsignature = ['x', 'p', 'r', 'o', 'g', '8', 'r', 'e', 'u']
        ubyte i
        ubyte j
        bool found = false

        for i in 255 to 0 step -1 {
            signature[0] = i
            cmd(signature, 0, 9, i, REU_STASH)
        }

        for i in 0 to 255 {
            signature[0] = i
            cmd(xsignature, 0, 9, i, REU_FETCH)
            for j in 0 to 8 {
                if signature[j] != xsignature[j] {
                    return i-1, found
                }
            found = true
            }
        }
        return i, found
    }

    sub cmd(uword c64addr, uword reuaddr, uword length, ubyte bank, ubyte command) {
        reu_c64addr = c64addr
        reu_extaddr = reuaddr
        reu_extbank = bank
        reu_len = length
        reu_cmdreg = command
    }

    sub bank(ubyte banknum) {
        ubyte reubank
        uword offset

        ; if banknum == current_bank we want
        ; to leave the bank alone. do nothing.
        ; (should we save the bank? we could move this down below save())
        if banknum == current_bank
            return

        ; save our current bank
        save(current_bank)

        ; fetch new bank
        reubank = banknum / 8
        offset = (banknum % 8) as uword * 8192
        cmd($a000, offset, 8192, reubank, REU_FETCH)
        current_bank = banknum

        ; save/copy $A000 to arbitary logical bank
        sub save(ubyte savebank) {
            ubyte reusavebank = savebank / 8
            uword saveoffset = (savebank % 8) as uword * 8192
            ; stash to new bank
            cmd($a000, saveoffset, 8192, reusavebank, REU_STASH)
        }
    }
}
