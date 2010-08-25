\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: support.fth
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
id: @(#)support.fth 1.2 99/05/27
purpose: 
copyright: Copyright 1990-1998 Sun Microsystems, Inc.  All Rights Reserved

headerless

\ Interactive diagnostic
: (watch-clock)  ( -- )
   ." Watching the 'seconds' register of the real time clock chip."  cr
   ." It should be 'ticking' once a second." cr
   ." Type any key to stop."  cr
   -1
   begin    ( old-seconds )
      begin
         key?  if  key drop  drop exit  then
         get-seconds d# 10 ms
      2dup =  while   ( old-seconds old-seconds )
         drop
      repeat          ( old-seconds new-seconds )
      nip dup (cr .d
   again
   drop
;

: (date) ( -- )
   get-time   ( hour min secs )
   get-date   ( month date year )
   base @ >r decimal
   <# bl hold u# u# u# u# ascii / hold drop
   u# u# ascii / hold drop
   u# u# u#> type
   <# bl hold u# u# ascii : hold drop
   u# u# ascii : hold drop
   u# u# u#>  type
   r> base !
   ."  GMT "
;

" date"		' (date)	(is-user-word)
" watch-clock"	' (watch-clock)	(is-user-word)
