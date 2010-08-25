\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: callback.fth
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
id: @(#)callback.fth 1.7 02/01/15
purpose: Callbacks into client program, callback and sync commands
copyright: Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved

headerless
0 value cb-array
: free-cb-array ( size -- )
   cb-array 0 to cb-array
   swap free-mem
;
create callback-err ," callback failed"
headers

nuser vector     0 vector !

: $callback  ( argn .. arg1 nargs adr len -- retn .. ret2 ret1 Nreturns )
   vector @  0=  abort" No callback routine has been installed"

   2 pick 9 + /n* dup >r alloc-mem is cb-array
   cb-array r@ erase

   \ Prepare argument array
   $cstr cb-array !        \ service name   ( argn .. arg1 nargs )
   dup cb-array na1+ !     \ N_args         ( argn .. arg1 nargs )
   6   cb-array 2 na+ !    \ N_rets         ( argn .. arg1 nargs )
   0  ?do  cb-array i 3 + na+ !  loop       ( )  \ arg1 .. argN

   cb-array  vector @ callback-call  if
      r> free-cb-array callback-err throw
   then

   \ Compute address of ret1
   cb-array na1+ @  ( n_args ) 3 +  cb-array swap na+  ( ret1-adr )

   \ Push N return values
   cb-array 2 na+ @   /n* over +                    ( ret1-adr retN+1-adr )
   begin  2dup u<  while  /n - dup @ -rot  repeat   ( rN .. ret1-adr retX-adr )
   2drop                                            ( retN .. ret2 ret1 )

   cb-array 2 na+ @                                 ( retN .. ret2 ret1 N )
   r> free-cb-array                                 ( retN .. ret2 ret1 N )
   dup 0<=  if  callback-err throw  then            ( retN .. ret2 ret1 N )
   1- swap throw                                    ( retN .. ret2 N-1 )
;
: sync  ( -- )  0 " sync" $callback drop  ;
: callback  \ service-name  rest of line  ( -- )
   parse-word  -1 parse  dup over + 0 swap c!  ( adr len arg-adr )
   -rot 1 -rot  $callback
;

cif: interpret  ( arg-P .. arg1 cstr -- res-Q ... res-1 catch-result )
   only forth also definitions
   cscount  ['] interpret-string  catch  dup  if
      nip nip
   then
;

cif: set-callback  ( newfunc -- oldfunc )  vector @  swap vector !  ;

