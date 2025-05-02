;
; $A000 banked library
;

%memtop $BFFF
%address $A000
%output library
%zeropage dontuse

%import conv
%import textio

main {
    ; This must be first in main!
    ; The compiler always generates the first slot in the jump
    ; table as main.start. Shown here (commented out) as a reminder.
    ;%jmptable(main.start)
    %jmptable(main.link, main.name, main.number, main.multiply_, main.args_)

    sub start() {
        txt.print("bank.lib start() called...\n")
    }

    ; update bank number...
    sub link(ubyte banknum) {
        uword ptr = conv.str_ub0(banknum)
        str bankname = "libbank?????????????"
        bankname[7] = ptr[0]
        bankname[8] = ptr[1]
        bankname[9] = ptr[2]
        bankname[10] = ptr[3]
    }

    ; return the name of this library
    sub name() -> uword {
        return(main.link.bankname)
    }

    ; return the bank number 
    sub number() -> ubyte {
        return(main.link.banknum)
    }

    ;
    asmsub args_(ubyte i @A, ubyte j @X, ubyte k @Y) -> ubyte @A, ubyte @X, ubyte @Y {
        %asm {{
;            ; swap X & Y
;            pha
;            txa
;            pha
;            tya
;            tax
;            pla
;            tay
;            pla
            ; swap A & X
            sta cx16.r13
            stx cx16.r14
            tya
            tax
            ldy cx16.r13
            lda cx16.r14
            rts
        }}
    }

    ; this is clunky but writes the result back to a pointer.
    ; demonstrates passing an address not value.
    asmsub multiply_(ubyte i @A, ubyte j @Y, uword resultptr @R15) {
        %asm {{
            sta p8b_main.p8s_multiply.p8v_i
            sty p8b_main.p8s_multiply.p8v_j
            lda cx16.r15L
            sta p8b_main.p8s_multiply.p8v_resultptr
            lda cx16.r15H
            sta p8b_main.p8s_multiply.p8v_resultptr+1
            jmp p8b_main.p8s_multiply
        }}
    }

    sub multiply(ubyte i, ubyte j, uword resultptr) {
        pokew(resultptr,  i as uword * j as uword)
    }
}
