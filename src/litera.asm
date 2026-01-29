; Definicje adresów
ACIA_DATA   = $D200
ACIA_STATUS = $D201
lda #$41

SEND_CHAR:
    PHA             ; Zachowaj literę na stosie
WAIT_TX:
    LDA ACIA_STATUS ; Odczytaj status
    AND #$10        ; Maskuj bit 4 (Transmit Data Register Empty)
    BEQ WAIT_TX     ; Jeśli bit = 0 (zajęty), pętla
    PLA             ; Odzyskaj literę ze stosu
    STA ACIA_DATA   ; WSTAW LITERĘ TUTAJ - to rozpoczyna wysyłkę
    RTS
