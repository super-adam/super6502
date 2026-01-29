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
sei
        cld
        ldx #$ff
        txs

        // 1. Reset ACIA
        sta ACIA_STATUS 

        // 2. Setup (9600, 8-N-1)
        lda #%00011110  
        sta ACIA_CTRL

        // 3. Command (No Parity, No IRQ, DTR Low)
        lda #%00001011
        sta ACIA_CMD

        ldx #$00
test_loop:
        lda Message,x
        beq finished    // End of string?
        
        jsr send_and_receive_back
        
        inx
        jmp test_loop

finished:
        jmp finished

// --- The Loopback Logic ---
send_and_receive_back:
        pha             // Save the character to send
        
        // Step A: Wait for TX buffer to be empty
wait_tx:
        lda ACIA_STATUS
        sta $00
        and #$10        // Bit 4: Transmit Data Register Empty
        beq wait_tx
        
        pla             // Get character back
        sta ACIA_DATA   // SEND IT
        
        // Step B: Wait for the SAME character to come back via RxD
wait_rx:
        lda ACIA_STATUS
        sta $00
        and #$08        // Bit 3: Receiver Data Register Full
        beq wait_rx     // If we never receive it, the CPU hangs here (Test fails)
        
        lda ACIA_DATA   // Clear the receive register (Read the looped-back byte)
        sta $01
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