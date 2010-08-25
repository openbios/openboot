\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: preload.fth
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
\ preload.fth 1.2 02/05/02
\ Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

\ Until we load this we can't use the id: form of file identification.
\ that includes this file.. So don't change the header.
\
warning off caps on decimal

\ We do this early so we can start xref as soon as possible.
\ in this case before we even have [ifdef] available.
\ which is why the symbols are $find executed, so it compiles into the
\ temporary execution buffer when XREF is not defined..
\
" XREF" 55 45 fsyscall drop if
   " xref-init" $find if execute then 0= abort" Xref failed to initialise"
   " ${BP}/arch/preload.fth" " xref-push-file" $find if execute then 2drop
   " xref-on" $find if execute then
then

fload ${BP}/fm/lib/copyrigh.fth

fload ${BP}/fm/lib/transien.fth
decimal limit origin- 27 * 100 / aligned  1000 set-transize
transient fload ${BP}/fm/lib/headless.fth resident
transient fload ${BP}/fm/lib/brackif.fth resident
[ifndef] RESET
transient fload ${BP}/fm/kernel/sparc/loadsyms.fth resident
[then]

\ This is a symbol aware version of fload, it ensure that make depend
\ works most of the time. However you cannot nest depend-load files.
\ You have to be very carefull with what you depend-load - you have been
\ warned.
transient
: depend-load \ 'feature-symbol' file
   safe-parse-word safe-parse-word		( symbol$ file$ )
   2swap [get-symbol] drop if			( file$ )
      included					( )
   else						( file$ )
      " DEPEND" [get-symbol] drop if		( file$ )
         ." File: " type cr			( )
      else					( file$ )
         2drop					( )
      then					( )
   then						( )
;

fload ${BP}/fm/lib/message.fth

resident

warning on

fload ${BP}/os/unix/simforth/findnext.fth

[defined] LOADFILE dup 0= abort" Missing platform loadfile" included
