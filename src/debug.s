start_vec   =     $a846

*           =     $8500

entry
            lda   #$de
            sta   $EB
            lda   #$ad
            sta   $EC
            lda   #$be
            sta   $ED
            lda   #$ef
            sta   $EE
            jmp   start_vec
