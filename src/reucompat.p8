c64 {
%option merge
    ; replace default routine with one that checks for reu banks
    ; If bank is 8 or above (0 relative) it is passed to reujsrfar 
    asmsub x16jsrfar() {
        %asm {{
            ; setup a JSRFAR call (using X16 call convention)
            sta  P8ZP_SCRATCH_W2        ; save A
            sty  P8ZP_SCRATCH_W2+1      ; save Y
            php
            pla
            sta  P8ZP_SCRATCH_REG       ; save Status

            pla
            sta  P8ZP_SCRATCH_W1
            pla
            sta  P8ZP_SCRATCH_W1+1

            ; retrieve arguments
            ldy  #$01
            lda  (P8ZP_SCRATCH_W1),y            ; grab low byte of target address
            sta  _jmpfar+1
            iny
            lda  (P8ZP_SCRATCH_W1),y            ; now the high byte
            sta  _jmpfar+2
            iny
            lda  (P8ZP_SCRATCH_W1),y            ; then the target bank
            sta  P8ZP_SCRATCH_B1
            ; check if this is an REU simulated RAM bank
            cmp  #8                             ; first 8 banks are 6510 hardware
            bcc  +
            jmp  c64.reujsrfar
            ; adjust return address to skip over the arguments
+           clc
            lda  P8ZP_SCRATCH_W1
            adc  #3
            sta  P8ZP_SCRATCH_W1
            lda  P8ZP_SCRATCH_W1+1
            adc  #0
            pha
            lda  P8ZP_SCRATCH_W1
            pha
            lda  $01        ; save old ram banks
            pha
            ; set target bank, restore A, Y and flags
            lda  P8ZP_SCRATCH_REG
            pha
            lda  P8ZP_SCRATCH_B1
            jsr  banks
            lda  P8ZP_SCRATCH_W2
            ldy  P8ZP_SCRATCH_W2+1
            plp
            jsr  _jmpfar        ; do the actual call
            ; restore bank without clobbering status flags and A register
            sta  P8ZP_SCRATCH_W1
            php
            pla
            sta  P8ZP_SCRATCH_B1
            pla
            jsr  banks
            lda  P8ZP_SCRATCH_B1
            pha
            lda  P8ZP_SCRATCH_W1
            plp
            rts

_jmpfar     jmp  $0000          ; modified
        }}
    }

    ; x16jsrfar calls here if the bank is not 0-7.
    ; this is not a full implementation, but picks up
    ; where x16jsrfar left off
    asmsub reujsrfar() {
        %asm {{
            ; finish a JSRFAR call started in x16jsrfar (using X16 calling convention)
            ; adjust return address to skip over the arguments
            clc
            lda  P8ZP_SCRATCH_W1
            adc  #3
            sta  P8ZP_SCRATCH_W1
            lda  P8ZP_SCRATCH_W1+1
            adc  #0
            pha
            lda  P8ZP_SCRATCH_W1
            pha
            lda  p8b_reu.p8v_current_bank ; save old reu bank
            pha
            ; set target bank, restore A, Y and flags
            lda  P8ZP_SCRATCH_REG       ; status on stack
            pha
            lda  P8ZP_SCRATCH_W2        ; A on stack
            pha
            lda  P8ZP_SCRATCH_W2+1      ; Y on stack
            pha
            lda  P8ZP_SCRATCH_B1
            sta  p8b_reu.p8s_bank.p8v_banknum
            jsr  p8b_reu.p8s_bank
            pla
            tay
            pla
            plp
            jsr  x16jsrfar._jmpfar        ; do the actual call
            ; restore bank without clobbering status flags and A register
            sta  P8ZP_SCRATCH_W1    ; stash A
            pla                     ; old bank from stack
            sta  P8ZP_SCRATCH_B1    ; stash for call
            php                     ; status on stack
            lda  P8ZP_SCRATCH_W1    ; restore A
            pha                     ; A on stack
            txa
            pha                     ; X on stack
            tya
            pha                     ; Y on stack
            ; everything saved to stack
            lda  P8ZP_SCRATCH_B1
            sta  p8b_reu.p8s_bank.p8v_banknum
            jsr  p8b_reu.p8s_bank
            pla
            tay
            pla
            tax
            pla
            plp
            rts
        }}
    }

}

cx16 {
%option merge
; ---- utilities -----

; no rom unless we fake it?
inline asmsub rombank(ubyte bank @A) {
    ; -- set the rom banks
    %asm {{
        nop
    }}
}

; support reu banks starting with zero?
; so rambank(0) and banks(0) are not the same...
inline asmsub rambank(ubyte bank @A) {
    ; -- set the ram bank
    %asm {{
        sta p8b_reu.p8s_bank.p8v_banknum
        jsr p8b_reu.p8s_bank
    }}
}

; all rom banks are 0 for now.
inline asmsub getrombank() -> ubyte @A {
    ; -- get the current rom bank
    %asm {{
        lda  #$00
    }}
}

; this *only* reports REU backed 8KB RAM banks
; this is not related to native c64 6510 banking
inline asmsub getrambank() -> ubyte @A {
    ; -- get the current RAM bank
    %asm {{
        lda  p8b_reu.p8v_current_bank
    }}
}

inline asmsub push_rombank(ubyte newbank @A) clobbers(Y) {
    ; push the current rombank on the stack and makes the given rom bank active
    ; combined with pop_rombank() makes for easy temporary rom bank switch
    %asm {{
        nop
    }}
}

inline asmsub pop_rombank() {
    ; sets the current rom bank back to what was stored previously on the stack
    %asm {{
        nop
    }}
}

inline asmsub push_rambank(ubyte newbank @A) clobbers(Y) {
    ; push the current hiram bank on the stack and makes the given hiram bank active
    ; combined with pop_rombank() makes for easy temporary hiram bank switch
    %asm {{
        sta  p8b_reu.p8s_bank.p8v_banknum
        lda  p8b_reu.p8v_current_bank
        pha
        jsr  p8b_reu.p8s_bank
    }}
}

inline asmsub pop_rambank() {
    ; sets the current hiram bank back to what was stored previously on the stack
    %asm {{
        pla
        sta  p8b_reu.p8s_bank.p8v_banknum
        jsr  p8b_reu.p8s_bank
    }}
}

asmsub numbanks() clobbers(X) -> uword @AY {
    ; -- Returns the number of available REU backed 8KB RAM banks.
    ;    Note that on the X16 the number of banks can be 256 so a word is returned.
    ;    Currently this is capped at 256 * 8KB banks (2MB REU) on C64 to match.
    %asm {{
        lda p8b_reu.p8v_rambanks
        ldy p8b_reu.p8v_rambanks+1
        rts
    }}
  }
}

diskio {
    %option merge

    ; Use kernal LOAD routine to load the given program file in memory.
    ; This is similar to Basic's  LOAD "filename",drive  /  LOAD "filename",drive,1
    ; If you don't give an address_override, the location in memory is taken from the 2-byte file header.
    ; If you specify a custom address_override, the first 2 bytes in the file are ignored
    ; and the rest is loaded at the given location in memory.
    ; Returns the end load address+1 if successful or 0 if a load error occurred.
    sub load(uword filenameptr, uword address_override) -> uword {
        if msb(address_override) & $e0 == $a0 return loadbank(filenameptr, address_override)
        cbm.SETNAM(strings.length(filenameptr), filenameptr)
        ubyte secondary = 1
        cx16.r1 = 0
        if address_override!=0
            secondary = 0
        cbm.SETLFS(1, drivenumber, secondary)
        %asm {{
            lda  #0
            ldx  address_override
            ldy  address_override+1
            jsr  cbm.LOAD
            bcs  +
            stx  cx16.r1
            sty  cx16.r1+1
+
        }}

        return cx16.r1
    }

    ; load files into $a000 bank
    ; increment bank if the file is larger than 8KB
    sub loadbank(uword filenameptr, uword address) -> uword {
        uword count
        uword size = $c000 - address

        if not f_open(filenameptr) return $0000

        ; eat the two byte load address or two bytes already
        ; read by load_raw().
        count = f_read(address, 2)

        ; special handling for first bank (from load_raw)
        ; or any load that that doesn't start at $a000.
        if address > $a000 {
                count = f_read(address, size)
                ; this returns the next address *after* the 
                ; last byte loaded like cbm.LOAD()
                if count < size {
                    return address + count
                }
                reu.bank(reu.current_bank + 1)
        }
        repeat {
            count = f_read($a000, 8192)
            ; this returns the next address *after* the 
            ; last byte loaded like cbm.LOAD()
            if count < 8192 {
                return $a000 + count
            }
            reu.bank(reu.current_bank + 1)
        }
    }

    ; CommanderX16 extensions over the basic C64/C128 diskio routines:

    ; For use directly after a load or load_raw call (don't mess with the ram bank yet):
    ; Calculates the number of bytes loaded (files > 64Kb are truncated to 16 bits)
    sub load_size(ubyte startbank, uword startaddress, uword endaddress) -> uword {
        return $2000 * (cx16.getrambank() - startbank) + endaddress - startaddress
    }
}
