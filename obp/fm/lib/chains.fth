\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: chains.fth
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
id: @(#)chains.fth 1.3 01/08/07
purpose: 
copyright: Copyright 2001 Sun Microsystems, Inc  All rights reserved

\ Provide 4 new compile methods:
\
\   chain: \ name
\	create a new headerless chain.
\	Add a call to 'name' before dropping into the new definition if it
\	exists. stand-init is an example of one such chain.
\	terminate with ';' as for a normal colon definition.
\	Note: a chained word will always be available in the forth vocabulary
\	at compile time regardless of what vocabulary it was defined under.
\
\   tail-chain: \ name
\	create a new headerless chain.
\	terminate with 'tail;' which will compile in a call to the previous
\	definition of 'name' before returning.
\	execute-buffer is an example of a tail-chain: where the routine
\	decides to call the previous routine *after* executing some internal
\	code.
\
\   tail;
\	Part of 'tail-chain:' complete a tail-chain call.
\	It is an error to break a tail-chain by terminating without a 'tail;'
\	Detection will only happen upon the next tail-chain call.
\
\   overload: \ name
\	create a new routine, supressing warnings for the creation.
\	It is an error to declare a routine as 'overload'ed if it does not
\	already exist.
\	The new routine is headered or headerless depending upon the current
\	header state.
\
\
\ Usage examples:
\
\   1	chain: foo  ." hello " ;		\ foo1
\	chain: foo  ." world" ;			\ foo2
\	
\	Executing foo will print 'hello world' because foo2 calls foo1 before
\	executing any internal code.
\
\   2	tail-chain: bar  ." world" tail;	\ bar1
\	tail-chain: bar  ." hello " tail;	\ bar2
\
\	Executing bar will also print 'hello world' this time bar2 prints
\	" hello" and then when finished (tail;) calls bar1 which prints "world"
\
\	Useage of tail-chain: should be deprecated. Its easy to make mistakes
\	execute-buffer is a good use, others probably are not.
\
\   3	: xxx ." xxx" ;
\	: yyy xxx ." yyy" ;
\	overload: xxx ['] xxx catch drop ;
\
\	yyy wants to call the raw routine xxx, but the official interface to
\	xxx is supposed to be catch protected, so xxx is intentionally
\	overloaded to pretect its callers from 'throw'.
\
\	However for this specific case renaming the first xxx to (xxx) would
\	have been a better choice and then no overload: is required.
\
\   Everything else is private DONT call it.
\
headers transient

variable chain-acf
h#  20 alloc-mem value chain-name
h# 200 alloc-mem value tail-chain-info

[ifnexist] headerless?
0 value headerless?
warning @ warning off
: headers 0 is headerless? headers ;
: headerless true is headerless? headerless ;
warning !
[then]

: (make-chain) ( -- )   chain-acf @ ?dup if  token,  then chain-acf off ;

: (chain-header) ( -- ) chain-name count $header acf-align  ;

: (chain:) ( str,len -- )
   chain-name pack count $find 0= if  2drop false  then chain-acf !
[ifndef] show-duplicates?  warning @ >r warning off  [then]
   ['] header behavior >r ['] (chain-header) is header : r> is header
[ifndef] show-duplicates?  r> warning !  [then]
;

: (headerless-chain:) ( str,len -- )
   get-current >r ['] forth set-current   ( str, len)  ( r: c-voc )
   headerless? >r headerless (chain:) r> 0= if  headers  then ( ) ( r: c-voc )
   r> set-current		          ( ) ( r: )
;

: chain: ( -- ) \ Name
   safe-parse-word  (headerless-chain:) (make-chain)
; immediate

: overload: ( -- ) \ Name
   safe-parse-word 2dup $find if	( str,len acf )
      drop (chain:)			( )
   else					( str,len )
      where ." Error: overload of " type  ."  not neccessary" cr
      abort				( )
   then
; immediate

[ifexist] file-name
: tail-chain: ( -- ) \ Name
   safe-parse-word				( str,len )
   tail-chain-info c@ if			( str,len )
      tail-chain-info count type
      0 tail-chain-info c! abort
   then
   source-id ?dup 0<> if			( str,len )
      dup file-name tail-chain-info pack >r	( str,len id )
      " :" r@ $cat file-line			( str,len id )
      base @ >r decimal (.) r> base ! r@ $cat	( str,len )
      " : Error: Broken tail call for " r> $cat	( str,len )
   then						( str,len )
   2dup tail-chain-info $cat			( str,len )
   (headerless-chain:)				( )
; immediate

: tail; ( -- )  (make-chain) postpone ; 0 tail-chain-info c! ; immediate
[then]

resident headerless


