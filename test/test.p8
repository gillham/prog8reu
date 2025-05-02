
%zeropage basicsafe

%import diskio
%import textio

; reu bank support
%import reu
%import reucompat

main {
    sub start() {
        uword count
        uword size = reu.init()
        txt.print("reu size: ")
        txt.print_uw(size)
        txt.print("kb")
        txt.nl()

        ; load test file into first bank
        reu.bank(0)

        ; load 1 page file (skips 2 byte load address) to start of bank
        count = diskio.load("page.bin", $a000)

        txt.print("\nload page $a000 end: ")
        txt.print_uwhex(count, true)
        txt.nl()

        ; load 1 page file (skips 2 byte load address) to offset in bank
        count = diskio.load("page.bin", $a100)

        txt.print("\nload page $a100 end: ")
        txt.print_uwhex(count, true)
        txt.nl()

        ; load 1 8kb bank file (skips 2 byte load address) to start of bank
        count = diskio.load("bank.bin", $a000)

        txt.print("\nload $a000 full bank end: ")
        txt.print_uwhex(count, true)
        txt.nl()

        ; load 1 8kb-256byte file (skips 2 byte load address) to start of bank + 256
        count = diskio.load("partbank.bin", $a100)

        txt.print("\nload $a100 part bank end: ")
        txt.print_uwhex(count, true)
        txt.nl()

        ; load 1 8kb-256byte file raw (with 2 byte load address) to start of bank + 256
        count = diskio.load_raw("partbank.bin", $a100)

        txt.print("\nload_raw $a100 part bank end: ")
        txt.print_uwhex(count, true)
        txt.nl()

        ; make sure the reu stashes the current bank
        reu.bank(0)
        ;cx16.rambank(0)
        repeat {}
    }
}
