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
id: @(#)nvramrc.fth 1.12 03/10/28
purpose: Implements NVRAMRC and its editor
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ The default size of the nvramrc file is zero.  set-defaults will
\ establish this size, but nvrecover may be used to recover the
\ previous contents of the nvramrc file if there were any.

headerless

0 value nvramrc-buffer	\ Buffer for editing nvramrc
0 value nvramrc-size	\ Current size of file being edited in memory
0 value nvramrc-allocd	\ Current alloced size.

: /max-nvramrc ( -- n )  nvoption-size d# 12 -  nvramrc nip max  ;

: deallocate-buffer  ( -- )
   nvramrc-buffer  if
\nvdebug ." deallocate-buffer: " nvramrc-buffer .x nvramrc-allocd .x cr
      nvramrc-buffer nvramrc-allocd free-mem
   then
   0 is nvramrc-buffer
   0 is nvramrc-size
;

: allocate-buffer  ( -- )
   /max-nvramrc 0< abort" No space left for NVRAMRC"
   nvramrc-buffer 0=  if
      ['] nvramrc get				( adr,len )
      dup to nvramrc-size			( adr,len )
      /max-nvramrc dup to nvramrc-allocd	( adr,len max-len )
      alloc-mem dup is nvramrc-buffer		( adr,len dest )
      dup nvramrc-allocd erase			( adr,len dest )
      swap move					( -- )
\nvdebug ." allocate-buffer: " nvramrc-buffer .x
\nvdebug nvramrc-allocd .x nvramrc-size .x cr
   then
;

exported-headers

\ Returns address and length of edit buffer
: nvbuf  ( -- adr len )   nvramrc-buffer nvramrc-size ;

\ Begin or continue editing nvramrc
: nvedit  ( -- )
   allocate-buffer
   [ also hidden ]
   nvbuf  nvramrc-allocd edit-file  is nvramrc-size
   [ previous ]
;

\ Allows you to recover the contents of the nvramrc file if its size
\ has been set to 0 by set-defaults.
: nvrecover  ( -- )
   ['] nvramrc >body 1 ta+ token@ get		( adr,len )
   strdup					( old$,len )
   2dup to nvramrc				( old$,len )
   free-mem					( -- )
   nvedit					( -- )
;

\ Stop editing nvramrc, discarding the changes
: nvquit  ( -- )
   " Discard edits"  confirmed?  if  deallocate-buffer  then
;

exported-headerless

\ Execute the contents of the stack buffer
: (nvrun)  ( str,len -- )
   use-nvramrc? >r r@ if  0 to use-nvramrc?  then
   ['] interpret-string  catch  if  2drop  then
   r> if  true to use-nvramrc?  then
;

exported-headers

: nvrun ( -- )  nvbuf (nvrun)  ;

\ Copy the contents of the nvramrce edit buffer back into the NVRAM,
\ and deallocate the edit buffer.
: nvstore  ( -- )
   nvramrc-buffer if
      nvbuf to nvramrc
      deallocate-buffer
   then
;

exported-headerless

: execute-nvramrc  ( -- )
   " nvramrc-" do-drop-in                       (  )
   use-nvramrc?  if  nvramrc (nvrun)  then      (  )
   " nvramrc+" do-drop-in                       (  )
;

unexported-words
