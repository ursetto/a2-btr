            !cpu  6502
*           =     $d000


levelSpirit =     $23
levelFood   =     $24                     ; level of food, max limit-1
levelRest   =     $25                     ; level of rest, max limit-1
levelStamina=     $26                     ; level of stamina
limitSpirit =     $27
limitFood   =     $2a                     ; not shown, levelStamina/2 + 1
limitRest   =     $2b                     ; not shown, levelStamina/2 + 1
maxWeight   =     $2c

MENUCOL     =     $71
MENUROW     =     $72
debugFlag   =     $EE
debugMenu   =     $EF

GAME2_cleartext = $6006
GAME2_PRNTSTR =   $600c
GAME2_action_menu = $7700
GAME2_message_wait = $7706
GAME2_action_menu_noop = $7739
;;; enter_menu = $604e
start_vec   =     $a846
SCRN_chkkey =     $b609

handle_kbd_or_joy = $761a
handle_ijkm_space = $7621
jmp_select_menu_item = $7746
select_menu_item = $7792
jmp_pause   =     $779a                 ; jmp to GAME2_cleartext when menu item is PAUSE (pos 0,0)
action_text =     $7844
do_menu_status =  $82c1

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

!macro fstr .str {
            !text .str
            !byte $ff
}

!macro hvstr .h, .v, .str {
            !byte .v * 40 + .h
            +fstr .str
}

!macro print_hvstr .h, .v, .str {
            jsr GAME2_PRNTSTR
            +hvstr .h, .v, .str
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

            ;; Patch in call to handling PAUSE/DEBUG menu item.
            +pokew jmp_pause+1, handle_pause_debug
            ;; Patch debug kbd handler into keyboard handler
            +pokew handle_ijkm_space+1, handle_debug_kbd
            ;; Patch our menu item selector in place of the normal one
            +pokew jmp_select_menu_item+1, select_menu_item_2

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
            +poke action_menu_text+1, 'D'
            +poke action_menu_text+2, 'E'
            +poke action_menu_text+3, 'B'
            +poke action_menu_text+4, 'U'
            +poke action_menu_text+5, 'G'
            jsr   select_menu0          ;ensure menu text is copied
            beq   @ret                  ;always (Z=0 after select_menu0)
@pause
            +poke action_menu_text+1, 'P'
            +poke action_menu_text+2, 'A'
            +poke action_menu_text+3, 'U'
            +poke action_menu_text+4, 'S'
            +poke action_menu_text+5, 'E'
            jsr   select_menu0          ;ensure menu text is copied
@ret        pla
@rts        rts

; saw corruption once, which could indicate these are unsafe
.src        =     $09
.dst        =     $11

select_menu0
            lda #$00
            sta debugMenu
            lda #<action_menu_text
            ldy #>action_menu_text
            bne +
select_menu1
            lda #$FF
            sta debugMenu
            lda #<debug_menu_text
            ldy #>debug_menu_text
            ;; Copy menu text from (Y,A) into primary menu text
+           sta .src
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
            !text " PAUSE ", " MOVE ", "  -   ", " LEVEL UP   ", "         "
            !text " REGEN ", " TICK ", "  -   ", " MAX OUT    ", "         "
            !text "   -   ", " GET  ", "      ", "            ", "         "
            !text "   -   ", "      ", "      ", "            ", "        "

debug_menu_routines                     ; all offsets must be -1
            !word m_pause-1, m_move-1, m_noop-1, m_noimpl-1,     m_noop-1
            !word m_regen-1, m_tick-1, m_noop-1, m_maxout-1,     m_noop-1
            !word m_noop-1,  m_get-1,  m_noop-1, m_noop-1,       m_noop-1
            !word m_noop-1,  m_noop-1, m_noop-1, m_noop-1,       m_noop-1

;;; Menu item selector. Called when the user clicks on an item.
select_menu_item_2
            lda debugMenu
            bne @debug                  ; handle debug items if in debug menu
            lda debugFlag
            beq @ret                    ; normal menu if debug flag is disabled
            lda MENUCOL
            bne @ret
            lda MENUROW
            bne @ret                    ; normal menu if position != (0,0)
            jsr select_menu1            ; swap in debug menu text
            jsr GAME2_action_menu       ; display and handle debug menu
            jmp select_menu0            ; restore action menu text and rts

@ret        jmp select_menu_item        ; continue with normal action menu
;; Jump to debug menu routine handler at table + (MENUROW*5+MENUCOL)*2.
;; A jump table is easier to maintain than the chained conditionals of
;; the original, in my opinion.
@debug
            lda   MENUROW
            asl
            asl                         ;row*4
            clc
            adc   MENUROW               ;row*5
            adc   MENUCOL               ;row*5+col
            asl
            tax
            ;; jmp (debug_menu_routines,x) for 6502
            lda   debug_menu_routines+1,x
            pha
            lda   debug_menu_routines,x
            pha
            rts

;;; Menu item handling code
m_pause     jmp GAME2_cleartext
m_regen     lda limitSpirit                     ;REGEN
            sta levelSpirit
            ldy limitFood
            dey
            sty levelFood
            ldy limitRest
            dey
            sty levelRest
            jmp do_menu_status
m_maxout    lda #99
            sta limitSpirit
            sta maxWeight               ; note: this might allow you to carry too many items
            sta levelStamina
            ;; note: recalced as levelStamina/2 + 1 if you gain stamina via elixir
            lda #100
            sta limitFood
            sta limitRest
            jmp m_regen

m_move      jmp GAME2_cleartext
;;; Disabling TICKING also stops NPCs and other processing. Setting
;;; the doorNeshom flag will prevent starvation and time passing, but entering a door
;;; will teleport you to D'Ol Neshom.
m_tick      jmp m_noimpl
m_get       jmp m_noimpl
m_noimpl    jsr GAME2_cleartext
            +print_hvstr 1, 0, "NOT IMPLEMENTED"
            jmp GAME2_message_wait
m_noop      jmp GAME2_action_menu_noop
