
%zeropage basicsafe

%import diskio
%import textio

; reu bank support
%import reu
%import reucompat
; banked module
%import libbank

main {
    extsub @bank 42 $A006 = name42() -> str @AY
    extsub @bank 42 $A009 = number42() -> ubyte @A
    extsub @bank 42 $A00c = multiply42(ubyte arg0 @A, ubyte arg1 @Y, uword arg2 @R15)
    extsub @bank 42 $A00f = args42(ubyte arg0 @A, ubyte arg1 @X, ubyte arg2 @Y) -> ubyte @A, ubyte @X, ubyte @Y

    extsub @bank 85 $A006 = name85() -> str @AY
    extsub @bank 85 $A009 = number85() -> ubyte @A
    extsub @bank 85 $A00c = multiply85(ubyte arg0 @A, ubyte arg1 @Y, uword arg2 @R15)
    extsub @bank 242 $A006 = name242() -> str @AY
    extsub @bank 242 $A009 = number242() -> ubyte @A
    extsub @bank 242 $A00c = multiply242(ubyte arg0 @A, ubyte arg1 @Y, uword arg3 @R15) 


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
        reu.bank(0)
        if not libbank.load() {
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
        for i in 0 to 255 {
            libbank.link(i)
            reu.bank.save(i)
        }
        txt.nl()
        txt.nl()

        reu.bank(42)
        txt.print(libbank.name())
        txt.nl()
        reu.bank(95)
        txt.nl()

        ; test x16jsrfar -> reujsrfar
        txt.print("about to jsrfar...")
        txt.nl()
        txt.print_ub(number42())
        txt.nl()
        txt.print_ub(number85())
        txt.nl()
        txt.print_ub(number242())
        txt.nl()
        txt.print_ub(number42())
        txt.nl()

        ; pass an address for results to multiply
        ; clunkier than just using cx16.r0 or something
        ; but just a test.
        uword result
        multiply242(6,6,&result)
        txt.print_uw(result)
        txt.nl()
        multiply85(60,80,&result)
        txt.print_uw(result)
        txt.nl()
        multiply42(6,8,&result)
        txt.print_uw(result)
        txt.nl()


        i, j, k = args42(25, 33, 97)
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

        cx16.rambank(20)
        ; load a large file into banked memory.
        txt.print("loading 256kb load.bin...\n")
        txt.print("this can take 5-6 minutes...\n")
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
