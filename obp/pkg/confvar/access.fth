\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: access.fth
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
id: @(#)access.fth 1.4 03/10/28
purpose: option access words
copyright: Copyright 1998-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

exported-headerless

: nvseek ( offset ihandle -- )
   >r 0 " seek" r> $call-method throw
;

: (nvtransfer) ( adr,len str,len ihandle -- )
   >r 2>r tuck 2r> r> $call-method <> throw
;

: nvread  ( adr len ihandle -- )  " read"  rot (nvtransfer)  ;
: nvwrite ( adr len ihandle -- )  " write" rot (nvtransfer)  ;

: nvsync ( ihandle -- )
   " sync" rot ['] $call-method catch  if 3drop then
;

: nvsize ( ihandle -- )  " size" rot $call-method ;

0     value	nvfixed-ihandle
      variable	nvfixed-lastpos

: nvfixed-open ( dev$ -- ok? )
   open-dev dup to nvfixed-ihandle  0 nvfixed-lastpos !
;

: nvfixed-read ( adr len -- )
   tuck  nvfixed-ihandle nvread  nvfixed-lastpos +!
;

: nvfixed-write ( adr len -- )
   tuck  nvfixed-ihandle nvwrite  nvfixed-lastpos +!
;

: nvfixed-seek ( offset -- )
   dup  nvfixed-ihandle nvseek  nvfixed-lastpos !
;

: nvfixed-sync  ( -- )       nvfixed-ihandle nvsync ;
: nvfixed-size  ( -- size )  nvfixed-ihandle nvsize ;
: nvfixed-ftell ( -- pos )   nvfixed-lastpos @ ;

: nvfixed-close ( -- )
   nvfixed-sync  nvfixed-ihandle close-dev
;

0     value	nvoption-ihandle
      variable	nvoption-lastpos

: nvoption-open ( dev$ -- ok? )
   open-dev dup to nvoption-ihandle  0 nvoption-lastpos !
;

: nvoption-read ( adr len -- )
   tuck  nvoption-ihandle nvread  nvoption-lastpos +!
;

: nvoption-write ( adr len -- )
   tuck  nvoption-ihandle nvwrite  nvoption-lastpos +!
;

: nvoption-seek ( offset -- )
   dup  nvoption-ihandle nvseek  nvoption-lastpos !
;

: nvoption-sync  ( -- )       nvoption-ihandle nvsync  ;
: nvoption-size  ( -- size )  nvoption-ihandle nvsize ;
: nvoption-ftell ( -- pos )   nvoption-lastpos @ ;

: nvoption-close ( -- )
   nvoption-sync  nvoption-ihandle close-dev
;
   
unexported-words
