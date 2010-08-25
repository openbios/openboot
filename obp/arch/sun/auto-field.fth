\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: auto-field.fth
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
id: @(#)auto-field.fth 1.3 01/09/28
purpose:
copyright: Copyright 2001 Sun Microsystems, Inc.  All Rights Reserved

\ Use this to make structured member use more efficient for large structs
\ that only have a few fields used.
\
\ constants and structs defined once inline-struct? is set to on will
\ be defined as immediate transients that will replace their references with
\ the literal value or sequence of tokens representing their literal value in
\ all referencing routines.
\
\ This saves space and makes code easier to maintain, however it is important
\ to realise that inline structs used more than 4 or 5 times are more expensive
\ in dictionary usage than the simple alternative. Naturally, this is a
\ direct function of the usage of the struct/constant definitions and the
\ unused struct members.
\
\ You have been warned! You are not a supposed to define all structures and
\ constants as inline.. If you are unsure then don't do it.
\
\ Example use:
\	inline-struct? on
\	struct
\	  \n field >foo
\	  \n field >bar
\	  \c field >thingy
\	constant /widget
\	inline-struct? off
\
\	: foo! ( n va -- )  >foo ! ;
\	: bar@ ( va -- n )  >bar @ ;
\
\	Now 'see foo!'
\	Notice how the '>foo' has been completed optimised out..
\
\	Now 'see bar@'
\	The '>bar' is now represented as '/x +'
\
\	For this specific case the payback on the definition of /widget is
\	4 or 5 uses of each of the fields and constants.
\
\ An inline struct/constant behaves exactly as expected when not in compile
\ mode, so:
\
\	/widget .
\	0 >foo .
\	0 >bar .
\
\ will all behave as expected.
\
\
\ Need this to ensure that defining 'no-auto-field?' will still compile, but
\ will suppress the inline struct behaviour.
\
[ifnexist] inline-struct?
variable inline-struct?
[then]

[ifndef] no-auto-field?
also forth definitions

[ifnexist] headerless?
\ The assembler does not define headerless? which is problematic for this
\ code..
0 value headerless?
: headerless headerless true is headerless?  ;
: headers headers false is headerless?  ;
[then]

headerless? headers
transient?  0= if  transient  then
inline-struct? off

warning @ warning off
: auto-field ( a b -- c )
   state @ 0= if  +  exit  then		( a b )
   case
      0 of				endof
      1 of  postpone 1+ 		endof
      2 of  postpone 2+ 		endof
      3 of  postpone 3 postpone + 	endof
     /l of  postpone la1+		endof
     /x of  postpone xa1+		endof
      dup postpone literal postpone +
   endcase				( c )
;
: auto-const ( n -- )
    state @ 0= if  exit  then		( n )
    case
       0  of  postpone 0	endof
       1  of  postpone 1	endof
       2  of  postpone 2	endof
       3  of  postpone 3	endof
       4  of  postpone 4	endof
       5  of  postpone 5	endof
       6  of  postpone 6	endof
       7  of  postpone 7	endof
       8  of  postpone 8	endof
       dup postpone literal
    endcase				( )
;
: auto-create ( -- )
   headerless? >r  headers
   transient? 0= dup >r if  transient  then
   create  immediate ,
   r> if  resident  then
   r> if  headerless  then
;
: auto-field ( n a -- n' ) over auto-create + does> @ auto-field ;
: auto-const ( n -- )      auto-create does> @ auto-const ;

: constant ( n -- ) \ name
   ['] constant  inline-struct? @ if
      drop auto-const
   else
      state @ if  token,  else  execute  then
   then
; immediate
: field ( offset n -- n' ) \ name
   inline-struct? @ if  auto-field  else  field  then
; immediate

warning !

resident  if  headerless  then
previous definitions
[then]  \ no-auto-field?
