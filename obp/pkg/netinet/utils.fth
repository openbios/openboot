\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: utils.fth
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
id: @(#)utils.fth 1.1 04/09/07
purpose: Generic utility functions
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

: 3dup  ( n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )  dup 2over rot ;

: decimal  ( -- )    d# 10 base ! ;
: hex      ( -- )    h# 10 base ! ;
: .d       ( n -- )  base @  swap  decimal .  base ! ;
: spaces   ( n -- )  0 max  0 ?do  space  loop ;

fload ${BP}/pkg/netinet/queue.fth
fload ${BP}/pkg/netinet/strings.fth

headerless

: encapsulated-data ( pkt pktlen hdrlen -- data datalen )
   tuck - >r + r>
;

: encapsulating-hdr ( data datalen hdrlen -- pkt pktlen )
   tuck + >r - r>
;

: timed-out? ( when -- flag )  get-msecs < ;

: pstring, ( adr len -- )  dup c,  bounds ?do  i c@ c,  loop  ;
: cstring, ( adr len -- )  bounds ?do  i c@ c,  loop  0 c,  ;

: call-cif-method ( ?? name$ -- ?? )
   " /openprom/client-services" find-package  if
      >r  2dup  r>  find-method  if
         nip nip execute
      else
         ." Can't find client interface service " type cr  -1 throw 
      then
   else
      ." Can't find '/openprom/client-services'" cr  -1 throw
   then
;

: set-chosen-property ( adr,len propname$ -- )
   " /chosen" find-package  if
      my-self >r  0 to my-self
      push-package  property  pop-package
      r> to my-self
   else
      2drop 2drop
   then
;

: get-property ( node$ propname$ -- adr,len )
   0 0  2swap 2rot  find-package if
      get-package-property 0=  if  2swap 2drop  then
   else
      2drop
   then
;

: get-option-string ( propname$ -- $ )
   " /options" 2swap get-property  decode-string 2swap 2drop
;

\ Random number generator
\       x(n+1) = (69069 * x(n)) mod 2^32
: random ( -- n )
   get-msecs dup					( now seed )
   begin  over get-msecs =  while
      d# 69069 *  1 d# 32 << 1- and
   repeat  nip						( n )
;

\ Token handling is implemented using token tables. Each table entry 
\ specifies the token string (keyname), the associated handler and the
\ case-sensitivity to be used for keyname comparions. A null table
\ entry marks the end of the table.
\
\ A token table registering handlers for 2 case-insensitive tokens
\ would look like
\    create keys-table
\       " key1"  false  ['] key1-handler  token-handler,
\       " key2"  false  ['] key2-handler  token-handler,
\       0 0      0      0                 token-handler,

: token-handler, ( token$ case-sensitive? xt -- )
   swap 2swap						( xt flag token$ )
   dup 2+ >r  pstring,  c,  r>				( xt n )
   dup aligned swap  ?do  0 c,  loop			( xt )
   ,							( )
;

: token-match? ( token$ $ -- match? )
   2dup ca+  c@  if  $=  else  $case=  then
;

: find-token-handler ( token$ table -- xt true | false )
   begin						( token$ adr )
      count						( token$ $ )
   dup while						( token$ $ )
      2over 2over token-match?  if			( token$ $ )
         2swap 2drop  ca+ ca1+ aligned @  true exit	( xt true )
      then						( token$ $ )
      ca+ ca1+ aligned na1+				( token$ adr' )
   repeat						( token$ $ )
   2drop 2drop false					( false )
;

\ Use a spinner to report progress.

0 instance value activity-counter

: show-progress ( -- )
   activity-counter 1+ dup to activity-counter
   dup h# f and 0=  if
      4 rshift 3 and " \|/-" drop swap ca+ c@ emit bs emit  -2 #out +!
   else
      drop
   then
;

headers
