\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: name.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
id: @(#)name.fth 1.4 00/07/12
purpose: 
copyright: Copyright 1998, 2000 Sun Microsystems, Inc.  All Rights Reserved

: name-prop  ( addr len -- )  encode-string " name" property  ;

: hub-name  ( -- )  " hub" name-prop  ;

: snd-ctrl-name  ( -- )  " sound-control" name-prop  ;

: sound-name  ( -- )  " sound" name-prop  ;

: midi-name  ( -- )  " midi" name-prop  ;

: audio-name  ( int-descrip-addr -- int-descrip-addr )
   dup i-descript-sub c@
   case  1  of  snd-ctrl-name  endof
         2  of  sound-name  endof
         3  of  midi-name  endof
      sound-name
   endcase
;

: line-name  ( -- )  " line" name-prop  ;

: modem-name  ( -- )  " modem" name-prop  ;

: tele-name  ( -- )  " telephone" name-prop  ;

: isdn-name  ( -- )  " isdn" name-prop  ;

: ether-name  ( -- )  " ethernet" name-prop  ;

: atm-name  ( -- )  " atm-network" name-prop  ;

: control-name  ( -- )  " control" name-prop  ;

: comm-name  ( int-descrip-addr -- int-descrip-addr )
   dup i-descript-sub c@
   case  1  of  line-name  endof
         2  of  modem-name  endof
         3  of  tele-name  endof
         4  of  isdn-name  endof
         5  of  isdn-name  endof
         6  of  ether-name  endof
         7  of  atm-name   endof
      control-name
   endcase
;

: kbd-name  ( -- )  " keyboard" name-prop  ;

: mse-name  ( -- )  " mouse" name-prop  ;

: input-name  ( -- )  " input" name-prop  ;

: kbd-mse-name  ( int-descrip-addr -- int-descrip-addr )
   dup i-descript-sub c@  1 <>  if  input-name  exit  then
   dup i-descript-protocol c@
   case  1  of  kbd-name  endof
         2  of  mse-name  endof
      input-name
   endcase
;

: phys-name  ( -- )  " physical" name-prop  ;

: printer-name  ( -- )  " printer" name-prop  ;

: storage-name  ( -- )  " storage" name-prop  ;

: data-name  ( -- )  " data" name-prop  ;

: security-name  ( -- )  " security" name-prop  ;

: firm-name  ( -- )  " firmware" name-prop  ;

: irda-name  ( -- )  " IrDA" name-prop  ;

: interface-name  ( -- )  " interface" name-prop  ;

: app-name  ( int-descrip-addr -- int-descrip-addr )
   dup i-descript-sub c@
   case  1  of  firm-name  endof
         2  of  irda-name  endof
      interface-name
   endcase
;

: create-interface-name  ( int-descrip-addr -- )
   dup i-descript-class c@
   case  1  of  audio-name  endof
         2  of  comm-name   endof
         3  of  kbd-mse-name  endof
         5  of  phys-name   endof
         7  of  printer-name  endof
         8  of  storage-name   endof
         9  of  hub-name  endof
         a  of  data-name   endof
         d  of  security-name  endof
        fe  of  app-name    endof
      interface-name
   endcase  drop
;
