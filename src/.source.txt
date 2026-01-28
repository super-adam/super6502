.file [name="eprom_image.bin", type="bin", segments="EPROM"]

.segment EPROM []
// Start at the very beginning of the 128KB EPROM
* = $0000 "EPROM Start"

// 1. Fill from $0000 to $0EFFF (The first 60KB approx)
.fill $f000, $ea

// 2. Your Main Program at the equivalent of CPU $F000
* = $f000 "Main Program"
main:
        ldx #$00
loop1:  lda Message,X    
        sta $4000,X
        inx 
        cpx #$28
        bne loop1

        ldx #$00
loop2:  lda $4000,X
        sta $0400,X
        inx 
        cpx #$28
        bne loop2
        jmp ($fffe) 

// 3. Fill the gap between Main and Message
.fill $f200-*, $ea

* = $f200 "Message"
Message:
        .text "CZESC TU SUPER KOMPUTER PAWLA           "

// 4. Fill the gap between Message and the Vectors at the very end
.fill $fffa-*, $ea

* = $fffa "Vectors"
        .word main // NMI
        .word main // RESET
        .word main // IRQ

// 5. Final padding to reach exactly 128KB ($20000 bytes)
// This fills from $10000 to $1FFFF
* = $10000 "Upper 64KB Bank"
.fill $10000, $ea