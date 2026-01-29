.file [name="eprom_image.bin", type="bin", segments="EPROM"]

.segment EPROM []
// Start at the very beginning of the 128KB EPROM
* = $0000 "EPROM Start"

// 1. Fill from $0000 to $0EFFF (The first 60KB approx)
.fill $f000, $ea

// Base address for your ACIA
.label ACIA_DATA    = $d200
.label ACIA_STATUS  = $d201
.label ACIA_CMD     = $d202
.label ACIA_CTRL    = $d203

// 2. Your Main Program at the equivalent of CPU $F000
* = $f000 "Main Program"
main:
        sei             // Disable interrupts
        cld             // Clear decimal mode
        
        // 1. Initialize ACIA
        lda #$00
        sta ACIA_STATUS // Software reset
        
        // 2. Setup Control Register ($1E = 9600, 8-N-1)
        // %0 = 1 stop bit, %00 = 8 bits, %11110 = 9600 baud
        lda #%00011110  
        sta ACIA_CTRL

        // 3. Setup Command Register ($0B)
        // %000 = No parity, %0 = Normal mode, %1 = No IRQ, %011 = DTR/RTS low
        lda #%00001011
        sta ACIA_CMD

        // 4. Send Message Loop
        ldx #$00
print_loop:
        lda Message,X
        beq done        // If we hit a null byte (0), we're finished
        jsr send_char
        inx
        jmp print_loop

done:   jmp ($fffe)        // Loop forever

send_char:
        pha             // Save A so we don't lose the character
wait_tx:
        lda ACIA_STATUS // Read status register
        sta $00
        and #$10        // Mask Bit 4 (Transmitter Data Register Empty)
        beq wait_tx     // If bit is 0, it's still busy, so loop
        pla             // Restore the character to A
        sta ACIA_DATA   // Send it!
        rts

// 3. Fill the gap between Main and Message
.fill $f200-*, $ea

* = $f200 "Message"
Message:
        .text "CZESC TU SUPER KOMPUTER PAWLA           "
        .byte $0D, $0A, 0 // CR, LF, and Null terminator
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