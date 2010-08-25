\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: nvramrc.fth
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
id:  @(#)nvramrc.fth 1.1 00/04/20 
purpose: Implements NVRAMRC
copyright: Copyright 1990-2000 Sun Microsystems, Inc.  All Rights Reserved

\ Architecture document notes:
\ * It may not be reasonable to test the contents of nvramrc without
\ rebooting, because of temporal issues about probing (for instance,
\ the probing may have already taken place).

\ Some magic happens here..
\ The format of this option is different to the others.
\	/token		acf of normal hash storage
\	/token		acf of fallback storage
\	/w		default length = 0
\	/w		default data = 0
\
\ This format prevents using some of the other options common code
\ because the fields are in different positions. Be careful. This option
\ is also different because a set-default doesn't just free the storage
\ resource.
\ The 'old' storage will persist until garbage collection happens.
\ after that event nvrecover will do nothing.
\

" oldnvramrc" create-nvhash constant nvrecover#

0 2 ta+ /w + constant  nvdata-offset

: getnvram-default ( apf -- )  nvdata-offset + 0  ;

: get-nvramrc ( apf -- )
   options-open? if				( apf )
      token@ execute exit			( adr,len )
   then						( apf )
   getnvram-default				( adr,len )
;

\
\ Most of the time we Joe.User to know about write failures to the device
\ However, for the nvramrc it is acceptable to lose the ability to
\ nvrecover if space in the device is low, unfortunately the data->file
\ tracking is handled entirely by the hash objects and by default they
\ complain when write fail. So we have a silent flag.
\
: strset ( adr len acf error? -- )
   write-errors? @ >r write-errors? !
   over if  set  else  3 perform-action 2drop  then
   r> write-errors? !
;

\ like the 'C' library counterpart.
: strdup ( adr len -- adr' len' )
   tuck dup alloc-mem tuck >r			( len adr mem len )
   move r> swap					( adr len )
;

\ Watch Out with this code.
\ The trick here is to release as much resource as possible
\ before starting to write anything. We release the various buffers
\ first because a triggered garbage collection will not write any hash
\ keys that have no data.
\

: set-nvramrc  ( new$,len apf -- )
   dup /token + token@ dup >r			( new$,len apf h2-acf )
   4 perform-action				( new$,len apf )
   token@ >r r@ get strdup			( new$,len old$,len )
   r@ 4 perform-action				( new$,len old$,len )
   2swap r> true strset				( old$,len )
   2dup r> false strset				( old$,len )
   free-mem					( -- )
;

7 actions
action: get-nvramrc		; ( apf -- adr len )
action: set-nvramrc		; ( adr len apf -- )
action: config-adr		; ( apf -- adr )
action: drop			; ( adr len acf -- adr len )
action: drop			; ( adr len acf -- adr len )
action: drop false		;
action: getnvram-default	; ( apf -- adr,len )

exported-headers  transient

0 value nvramrc-created?

: nvramrc-bytes  \ name  ( -- )
   nvramrc-created? abort" Only One NVRAMRC file is permitted"
   ['] $header behavior >r			( -- )
   ['] ($header) to $header			( -- )
   parse-word					( adr,len )
   nvrecover# create-config-hash -rot		( h2-acf adr,len )
   2dup create-nvhash				( h2-acf adr,len hash )
   create-config-hash -rot			( h2-acf h1-acf adr,len )
   also options definitions			( h2-acf h1-acf adr,len )
   $create					( h2-acf h1-acf )
   r> to $header				( h2-acf h1-acf )
   previous definitions				( h2-acf h1-acf )
   lastacf >r					( h2-acf h1-acf )
   dup token,					( h2-acf h1-acf )
   >body r> swap token!				( h2-acf )
   token,					( -- )
\ the next three lines are useful for debugging..
\ as the keep the association between oldnvramrc and nvramrc
\   >body r@ swap token!			( h2-acf )
\   dup token,					( h2-acf )
\   >body r> swap token!			( -- )
   0 l, 					( -- )
   use-actions
   true to nvramrc-created?
;

unexported-words resident
