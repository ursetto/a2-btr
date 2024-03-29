            !cpu  6502

; Modified version of DIRECT.SECTOR which enables dual-drive use.
; For one-drive use, no modifications are necessary.
; For two-drive use, set $302 to 2 at startup time, and modify
; entry points for data disk and storage disk to call DIRECT_RWTS1
; instead of DIRECT_RWTS.

RWTS        =     $bd00                 ;DOS33 RWTS entry point

; RWTS Input/Output Control Block used for reading sectors
*           =     $0300
RWTS_IOB    !byte $01                   ;table type
            !byte $60                   ;slot number * 16
RWTS_IOB_drive
            !byte $01                   ;drive number
            !byte $00                   ;volume (0=any)
RWTS_IOB_track
            !byte $00                   ;track
RWTS_IOB_sector
            !byte $00                   ;sector
            !word RWTS_DCT              ;ptr to device characteristics table
RWTS_IOB_buf
            !word $0200                 ;ptr to READ/WRITE buffer
            !byte $00                   ;unused
            !byte $00                   ;byte count (0=256 bytes)
RWTS_IOB_command
            !byte $00                   ;command code
            !byte $00                   ;return code
            !byte $00                   ;volume of last access
            !byte $60                   ;slot * 16 of last access
            !byte $02                   ;drive of last access
; Standard device characteristics table for Disk ][
RWTS_DCT    !byte $00                   ;device type (0=DISK ][)
            !byte $01                   ;phases per track (1=DISK ][)
            !byte $ef                   ;Motor on time count ($EF for DISK ][)
            !byte $d8                   ;Motor on time count ($D8 for DISK ][)

; Call RWTS with IOB at $0300. Used to access any disk when using 1 drive,
; and data disk (drive 2) when using 2 drives. The RWTS entry point in the original code.
DIRECT_RWTS ldy   #<RWTS_IOB
            lda   #>RWTS_IOB
            jmp   RWTS

; Call RWTS, temporarily overriding drive to 1. Used to access data disk
; or storage disk when using 2 drives. Note: Assumes you have set drive
; to 2 at startup time.
DIRECT_RWTS1
            dec   RWTS_IOB_drive        ;drive 1
            jsr   DIRECT_RWTS
            inc   RWTS_IOB_drive        ;drive 2
            rts

;;; Alternate entry point for HELLO. Swap in our debug code (bloaded at $D000
;;; in LC RAM bank 2) and jump to normal setup, which calls back to $D000 after
;;; relocating SCREEN. The game does not use any ROM calls except for PREAD (joystick),
;;; so we do not need to copy ROM to RAM for keyboard mode.
;;; Note: BIT $C080 (read-only RAM bank 2) saves 3 bytes but disallows self-modifying
;;; code (should we need it).
setup_entry bit   $c083                 ; read/write LC RAM bank 2
            bit   $c083                 ; twice
            jmp   $5b00                 ; SCREEN setup entry point

; 1 byte free

!if * > $330 {
            ;; !warn to generate report, !error to fail
            !error "DIRECT_SECTOR overlaps BIGMESS by ", * - $330, " bytes"
}
