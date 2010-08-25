\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: consredir.fth
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
id: @(#)consredir.fth 1.3 01/04/06
purpose: 
copyright: Copyright 1994-2001 Sun Microsystems, Inc.  All Rights Reserved

headerless
: (give/take-console) ( method$ ihandle -- )
   ?dup if
      dup " reg" rot ihandle>phandle	( method$ ihandle reg$ phandle )
      get-package-property  if		( method$ ihandle )
         safe-execute			(  )
      else				( method$ ihandle prop$ )
         2drop 3drop			(  )
      then				(  )
   else					( method$ )
      2drop				(  )
   then
;
: (take-console) ( ihandle -- )
   " take" rot (give/take-console)
;
: (give-console) ( ihandle -- )
   " give" rot (give/take-console)
;
: take-console ( -- )
   stdin  @ (take-console)
   stdout @ (take-console)
;
: give-console ( -- )
   stdin  @ (give-console)
   stdout @ (give-console)
;

chain: enterforth-chain
   take-console
;

chain: go-chain ( -- )
   give-console
;

headers
