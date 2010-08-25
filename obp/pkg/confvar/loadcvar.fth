\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: loadcvar.fth
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
id: @(#)loadcvar.fth 1.13 06/02/07
purpose: Load file for configuration variable manager
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Load file for NVRAM configuration option management
headers
transient

\ These words control which of the internal functions from the
\ nvdevice vocabulary we export.
\ 
\ exported-headers		- executable at the OK prompt
\ exported-headerless		- callable from forth code at compile time.
\ unexported-words		- headerless and private to the nvdevice.
\
0 value exporting-routines?

: exported-headers
   exporting-routines? 0= if
      also forth definitions
      true to exporting-routines?
   then
   headers
; immediate

: unexported-words
   exporting-routines? if
      previous definitions
      false to exporting-routines?
   then
   headerless
; immediate 

: exported-headerless
   exporting-routines? 0= if
      also forth definitions
      true to exporting-routines?
   then
   headerless
; immediate

\ general debug
alias \nvdebug \
\ alias \nvdebug noop
\nvdebug [message] XXX nvdebug is enabled

\ The garbage collector.
alias \nvdebug1 \
\ alias \nvdebug1 noop
\nvdebug1 [message] XXX nvdebug (garbage collector) is enabled

resident headers

vocabulary nvdevice

headerless
vocabulary nvhash-keys
also nvdevice definitions

unexported-words

fload ${BP}/pkg/confvar/access.fth
fload ${BP}/pkg/confvar/confact.fth		\ Action names

: (set-defaults) ( -- )
   0  ['] options                               ( alf voc-acf )
   begin  another-word?  while                  ( alf' voc-acf anf )
      dup name>string  " name" $=  if
         drop
      else
         name> do-set-default
      then
   repeat                                       (  )
;

fload ${BP}/pkg/confvar/hashdevice.fth

fload ${BP}/pkg/confvar/accesstypes.fth
fload ${BP}/pkg/confvar/fixed-access.fth

fload ${BP}/pkg/confvar/nvdevice.fth

context token@ ' nvdevice <> exporting-routines? or if
   true abort" ERROR: vocabulary ordering is broken in the NVRAM package" cr
then

previous definitions

fload ${BP}/pkg/confvar/attach.fth
