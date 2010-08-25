\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: execall.fth
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
id: @(#)execall.fth 1.9 99/12/09
purpose: 
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

headerless

defer the-action    ( phandle -- )
: execute-action  ( -- false )
   current-device >r  the-action  false  r> push-device
;

: (scan-level)  ( -- )
   current-device >r
   ['] execute-action ['] (search-level) catch  2drop
   r> push-device
;

: scan-level  ( action-acf -- )  is the-action (scan-level)  ;

headers

\ "action-acf" is executed for each device node in the subtree
\ rooted at dev-addr,len , with current-device set to the
\ node in question.  "action-acf" can perform arbitrary tests
\ on the node to determine if that node is appropriate for
\ the action that it wished to undertake.

: scan-subtree  ( dev-addr,len action-acf -- )
   current-device >r  ( dev-addr,len action-acf )
   is the-action      ( dev-addr,len )
   find-device        (  )
   ['] execute-action  ['] (search-preorder)  catch  2drop
   r> push-device     (  )
;

headerless

2variable method-name

\ : output-device?  ( -- flag )  current-device stdout @ pihandle=  ;

\ do-method? is an action routine for "scan-subtree" that is used
\ by execute-all-methods.  For each device node, excluding the current
\ output device, that has a method whose name is given by method-name ,
\ that method is executed.

: do-method?  ( -- )
   \ Don't test the output device
\   output-device?  if  exit  then

   method-name 2@  current-device  (search-wordlist)  if  ( xt )
      drop  pwd$                                ( path-adr,len )
      2dup type cr                              ( path-adr,len )
      method-name 2@  execute-device-method drop cr  (  )
   then                                              (  )
;

headers

: execute-all-methods  ( dev-addr,len method-adr,len -- )
   method-name 2!
   ['] do-method?  scan-subtree
;

: most-tests  ( -- )
   \ Don't test the output device
   \   output-device?  if  exit  then

   method-name 2@  current-device  (search-wordlist)  if  ( xt )

      drop                                                (  )

      \ We only want to execute the selftest routine if the device has
      \ a "reg" property.  This eliminates the execution of selftest
      \ routines for "wildcard" devices like st and sd.

      " reg"  get-property  if  exit  then 2drop        (  )

      ??cr ." Testing "  pwd
      method-name 2@  current-device              ( method-adr,len phandle )
      execute-phandle-method  drop                ( result )

      ?dup  if  ??cr ." Selftest failed. Return code = " .d cr  then

   then                                            (  )
;

