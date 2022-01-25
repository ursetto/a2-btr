            !cpu  6502
*           =     $8500

debugFlag   =     $EE
debugMenu   =     $EF

GAME2_cleartext = $6006
start_vec   =     $a846
SCRN_chkkey =     $b609

handle_kbd_or_joy = $761a
handle_ijkm_space = $7621
jmp_pause   =     $779a                 ; jmp to GAME2_cleartext when menu item is PAUSE (pos 0,0)
action_text =     $7844

!macro pokew .addr, .val {
            lda   #(.val & 255)
            sta   .addr
            lda   #(.val >> 8) & 255
            sta   .addr+1
}

!macro poke .addr, .val {
            lda   #.val
            sta   .addr
}

; In handle_ijkm_keyboard (or patch to it), we can test for Ctrl-D and toggle a debugflag. This flag would
; indicate debug mode is enabled (not that we should enter the debug menu). We should probably then
; immediately update the main menu text to change "PAUSE" to "DEBUG" (or vice versa, based on the flag value).

; We should be able to reuse the menu choice code, but we need another flag to say we are in the debug menu.
;
; The menu display code hardcodes the address of the action strings (action_text) used during menu display and
; highlight, as well as the exact text columns (which is ok), so we must either duplicate all this code or
; swap in/out the text as needed. Swapping is simplest, but is complicated by needing to write "DEBUG/PAUSE"
; to the main menu.

; In main game loop, check if entering menu
; 60a3: a5 9f        @check_menu_entry     lda     enterMenu               ;enter menu on this frame?
; Called from main game loop if enterMenu is set on that frame.
; 604e: 20 00 77     enter_menu            jsr     GAME2_action_menu

; In action menu, this handles item selection, and could be patched
; to handle a debug menu, using the normal action code to move.
; 7746: 4c 92 77                           jmp     select_menu_item

; 
; 7727: 20 2f 78     action_menu           jsr     display_actions

; This subroutine jumps to GAME2_cleartext if col,row is 0,0. This jump could be patched
; to test the debugflag and enter the debug menu.
; 7792: a5 71        select_menu_item      lda     MENUCOL                 ;col 0, row 0 (PAUSE)

;; We can patch Ctrl-D keyboard handler here (if we want to support it for both JOY and KBD)
;; 761a: a5 b1        handle_kbd_or_joy     lda     JOYFLG
;; 761c: f0 03                              beq     handle_ijkm_space
;; 761e: 4c ac 76                           jmp     handle_joystick
;;  or here (for KBD only, slightly cleaner)
;; 7621: 20 09 b6     handle_ijkm_space     jsr     SCRN_chkkey


;;; Action text for menu; we can modify PAUSE to DEBUG when debug flag is set.
;;; 7844: a0 d0 c1 d5+ action_text .str " PAUSE ...."

entry
            lda   #0
            sta   debugFlag
            sta   debugMenu

            ; Patch in call to handling PAUSE/DEBUG menu item.
            +pokew jmp_pause+1, handle_pause_debug
            ;; Patch debug kbd handler into keyboard handler
            +pokew handle_ijkm_space+1, handle_debug_kbd

            jmp   start_vec

handle_pause_debug
            ;; test to make sure menu item patch worked
            lda   #$de
            sta   $EB
            lda   #$ad
            sta   $EC
            jmp   GAME2_cleartext

handle_debug_kbd
            ;; Must preserve SCRN_chkkey value in A on return.
            jsr   SCRN_chkkey
            cmp   #$84                  ; Ctrl-D (or shift-4 '$')
            bne   @rts
            pha
            lda   debugFlag
            eor   #$FF
            sta   debugFlag
            beq   @pause
            jsr   select_menu0          ; TEST
            +poke action_text+1, 'D'
            +poke action_text+2, 'E'
            +poke action_text+3, 'B'
            +poke action_text+4, 'U'
            +poke action_text+5, 'G'
            bne   @ret
@pause
            jsr   select_menu1          ; TEST
            +poke action_text+1, 'P'
            +poke action_text+2, 'A'
            +poke action_text+3, 'U'
            +poke action_text+4, 'S'
            +poke action_text+5, 'E'
@ret        pla
@rts        rts

; saw corruption once, which could indicate these are unsafe
.src        =     $09
.dst        =     $11

select_menu0
            lda #<action_menu_text
            ldy #>action_menu_text
            bne +
select_menu1
            lda #<debug_menu_text
            ldy #>debug_menu_text
+
            sta .src
            sty .src+1
            lda #<action_text
            ldy #>action_text
            sta .dst
            sty .dst+1
            ldy #debug_menu_text-action_menu_text-1 ; length of menu text - 1
-           lda (.src),y
            sta (.dst),y
            dey
            bne -
            rts

; todo: conversion table
; $A0 (4 * $28) bytes long == 160 chars (4 rows * 40 cols)
; Actual and max string length is $9F; last char is not printed
action_menu_text
            !text " PAUSE ", " TAKE ", " DROP ", " EXAMINE    ", " STATUS  "
            !text " SPEAK ", " BUY  ", " SELL ", " INVENTORY  ", " RENEW   "
            !text " PENSE ", " USE  ", " HEAL ", " GRUNSPREKE ", " MENU    "
            !text " OFFER ", " EAT  ", " REST ", " KINIPORT   ", " SOUND  " ; last must be short 1 char

debug_menu_text
            !text " PAUSE ", " MOVE ", "  -   ", "            ", "         "
            !text " REGEN ", " TICK ", "  -   ", "            ", "         "
            !text "   -   ", "  -   ", "      ", "            ", "         "
            !text "   -   ", "      ", "      ", "            ", "        "

!if * > $9600 {
            !error "Encroached into SCREEN at $9600 by ", * - $9600, " bytes"
} else {
            ; !warn       $9600 - *, " bytes available"
}
