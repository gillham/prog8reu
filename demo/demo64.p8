
%zeropage basicsafe

%import diskio
%import textio

; reu bank support
%import reu
%import reucompat
; banked module
%import libbank

main {
    extsub @bank 28 $A006 = name28() -> str @AY
    extsub @bank 28 $A009 = number28() -> ubyte @A
    extsub @bank 28 $A00c = mutiply28(ubyte arg0 @A, ubyte arg1 @Y, uword arg2 @R15)
    extsub @bank 28 $A00f = args28(ubyte arg0 @A, ubyte arg1 @X, ubyte arg2 @Y) -> ubyte @A, ubyte @X, ubyte @Y

    extsub @bank 15 $A006 = name15() -> str @AY
    extsub @bank 15 $A009 = number15() -> ubyte @A
    extsub @bank 15 $A00c = multiply15(ubyte arg0 @A, ubyte arg1 @Y, uword arg2 @R15)
    extsub @bank 13 $A006 = name13() -> str @AY
    extsub @bank 13 $A009 = number13() -> ubyte @A
    extsub @bank 13 $A00c = multiply13(ubyte arg0 @A, ubyte arg1 @Y, uword arg3 @R15) 


    sub start() {
        ubyte i
        ubyte j
        ubyte k
        uword size = reu.init()
        txt.print("reu size: ")
        txt.print_uw(size)
        txt.print("kb")
        txt.nl()

        ; load module into first bank
        ; though it doesn't write back to the REU until we switch to 
        ; another or use reu.bank.save(0).
        ;reu.bank(0)
        if not libbank.load("bank.lib.r") {
            txt.nl()
            txt.print("libbank.load() failure")
            txt.nl()
        }

        ; use compat function
        txt.nl()
        txt.print("reu.rambanks: ")
        txt.print_uw(reu.rambanks)
        txt.nl()
        txt.print("numbanks: ")
        txt.print_uw(cx16.numbanks())
        txt.nl()

        ; check what cx16 compat bank are we on?
        txt.print("getrambank: ")
        txt.print_uw(cx16.getrambank())
        txt.nl()
        ; copy module into all banks
        txt.print("copying module to all banks...")
        txt.nl()
        ;
        ; Initialize all banks by saving the
        ; one we just loaded.  Rather than
        ; loading each from disk.
        ; We need to update reu.current_bank to
        ; match the bank we are saving to avoid
        ; the zero bank getting overwritten with
        ; the last bank on our first switch.
        for i in 0 to (reu.rambanks-1) as ubyte  {
            reu.current_bank = i ; hack to keep state
            libbank.link(i)
            reu.bank.save(i)
            txt.chrout('.')
        }

        txt.nl()

        ; validate our banks slightly
        txt.print("validating banks...\n")
        for i in 0 to (reu.rambanks-1) as ubyte  {
            ; switch to bank
            reu.bank(i)
            if i != libbank.number() {
                txt.print("mismatch: ")
                txt.print_ub(i)
                txt.spc()
                txt.print_ub(libbank.number())
                txt.nl()
            } else {
                txt.chrout('.')
            }
        }
        txt.nl()

        ; check an arbitrary bank
        reu.bank(28)
        txt.print(libbank.name())
        txt.nl()

        ; test x16jsrfar via reu 
        txt.print("about to jsrfar...")
        txt.nl()
        txt.print_ub(number28())
        txt.nl()
        txt.print_ub(number15())
        txt.nl()
        txt.print_ub(number13())
        txt.nl()
        txt.print_ub(number28())
        txt.nl()

        ; pass an address for results to multiply
        ; clunkier than just using cx16.r0 or something
        ; but just a test.
        uword result
        multiply13(6,6,&result)
        txt.print_uw(result)
        txt.nl()
        multiply15(60,80,&result)
        txt.print_uw(result)
        txt.nl()
        mutiply28(6,8,&result)
        txt.print_uw(result)
        txt.nl()


        ; this just passes 3, returns 3
        ; args are swapped around by the function
        i, j, k = args28(25, 33, 97)
        txt.print("i: ")
        txt.print_ub(i)
        txt.spc()
        txt.print("j: ")
        txt.print_ub(j)
        txt.spc()
        txt.print("k: ")
        txt.print_ub(k)
        txt.nl()

        txt.print("after jsrfar...")
        txt.nl()
        void libbank.unload()

        cx16.rambank(0)
        ; load a large file into banked memory.
        txt.print("loading 256kb load.bin...\n")
        txt.print("this can take 1-2 minutes on c64...\n")
        txt.print_ub(cx16.getrambank())
        txt.nl()
        ; full file
        uword count = diskio.load_raw("load.bin", $a000)
        ; missing first two bytes
        ;uword count = diskio.load("load.bin", $a000)
        ; missing first two bytes
        ;uword count = diskio.loadlib("load.bin", $a000)
        txt.print_uwhex(count, true)
        txt.nl()
        txt.print("after load.bin...")
        txt.print_ub(cx16.getrambank())
        txt.nl()
        ; make sure the reu stashes the current bank
        cx16.rambank(0)
    }
}
