\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: brackif.fth
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
\ @(#)brackif.fth 1.8 02/05/02
\ Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.
\ 
\ rewrite to scan tokens properly skipping strings and comments
\
\ <symbols> are not forth words, they exist outside the forth environment.
\ <definitions> are forth words and exist in the dictionary.
\
\ DO NOT POSTONE ANY OF THESE DIRECTIVES.
\
\ DO NOT USE ANY OF THE INTERNAL ROUTINES, The list of useable directives is:
\
\	[if], [else], [then]
\		these three work much like the C pre-processor directives
\		#if #else #endif.
\
\	[ifdef]	<symbol>
\	[ifndef] <symbol>
\		these three work much like the C pre-processor #ifdef, #ifndef
\		versions, no surprise there
\
\	[undef] <symbol>
\		Once a symbol is [undef]'d it is gone and no further directive
\		will match it.
\
\    	[defined] <symbol>
\		is a little different, it returns the state of the <symbol>
\		on the stack suitable for using with [if].
\		an undefined symbol returns	0,0
\		a boolean symbol returns	va,0
\		a symbol with a value returns	va,len
\
\	[set-symbol] ( data,len symb,len -- )
\	[get-symbol] ( symb,len -- data,len )
\		These both work as you would expect and all the directives
\		above treat them indistinguishably from the -D command line
\		form.
\
\	[ifexist] <definition>
\	[ifnexist] <definition>
\		these both work to detect the existance of a forth word.
\
\ Examples:
\
\		forth -D FILENAME=foo.fth -D debug? -U slow-mode?
\
\	[defined] FILENAME would return:	va,7 (foo.fth),
\	[defined] debug? would return:		va,0
\	[defined] slow-mode? would return:	0,0
\
\	" foo.fth" " FILENAME" [set-symbol]
\		is the equivalent of -D FILENAME=foo.fth on the command line.
\
\	" FILENAME" [get-symbol]	would return "foo.fth"
\
\	0 0 " slow-mode?" [set-symbol]
\		is the equivalent of -D slow-mode? on the command line.
\
\	[ifexist] dup  ." YES" [then]
\		would print the 'YES'.
\
\	[ifndef] dup ." NO" [then]
\		would print:
\			<file:line:> do you mean [*exist]? dup
\			NO
\		because the forth defintion 'dup' is not the
\		same as the <symbol> definition. [ifexist] does not check
\		the <symbol> definitions.
\
headerless
1 constant IF-IS-NOOP
2 constant ELSE-IS-NOOP
3 constant SKIP-TO-ELSE-THEN
4 constant SKIP-TO-THEN
5 constant SKIP-ALL

create dangling-else ," Dangling [else]"
create botched-else  ," [then] must follow [else]"
create dangling-then ," Dangling [then]"
create missing-token ," missing token following [..] construct"
create bad-symbol-name ," ! is not permitted in a symbol definition"

variable brackif-state brackif-state off
struct
   /n	field	>brackif-state
   /n	field	>brackif-else
   /n	field	>brackif-next
constant /brackif

variable do-brackif  do-brackif off

: [push-state] ( n -- )
   1 do-brackif +!
   brackif-state >r			( flag n )
   /brackif alloc-mem tuck		( flag va n va )
   >brackif-state !			( flag va )
   r@ @ over >brackif-next !		( va )
   r> !					( )
;

: [set-state] ( state -- )
   brackif-state @ ?dup if  >brackif-state ! then
;

: [get-state] ( -- state )
   brackif-state @ ?dup if  >brackif-state @ else 0 then
;

: [pop-state] ( -- state )
   brackif-state >r r@ @ if		( )
      -1 do-brackif +!			( )
      r@ @ dup >brackif-next @		( va next )
      r> !				( va )
      dup >brackif-state @ swap		( state va )
      /brackif free-mem			( state )
   else
      r> drop 0
   then
;

: [error] ( error -- )
   ?dup if  begin [pop-state] while repeat throw  then
;

: nprompt
   do-brackif @ .
   [get-state] case
      IF-IS-NOOP		of ." [pending else/then] " endof
      SKIP-TO-ELSE-THEN		of ." [skip to else/then] " endof
      SKIP-TO-THEN		of ." [skip to then] " endof
      ELSE-IS-NOOP		of ." [pending then] " endof
      SKIP-ALL			of ." [skip all??] " endof
      dup ascii [ emit 0 .r ." ] "
   endcase
;

\ ' nprompt is status

: [skip-comment] ( c -- )
   ascii \ = if
      postpone \
   else
      long-comments dup @ over 2>r on postpone ( 2r> !
\ where      ascii ) parse ." skipped: " type cr
   then
;

: [skip-quoted?] ( adr,len -- adr,len,0 | true )
   2dup " "(22)"        $= >r				( str len )
   2dup " .("		$= r> or >r			( str len )
   2dup " abort"(22)"	$= r> or >r			( str len )
   2dup " ."(22)"	$= r> or >r			( str len )
   2dup " ,"(22)"	$= r> or if			( str len )
      2drop  ascii " parse  2drop  true			( )
   else							( str len )
      2dup " :" $= if					( )
         2drop parse-word 2drop true			( true )
      else						( str,len )
         2dup " [message]" $= if			( str,len )
            2drop -1 parse 2drop true			( true )
	 else						( str,len )
            false					( str len 0 )
         then						( str,len,0 | true )
      then						( adr,len,0 | true )
   then							( adr,len,0 | true )
;

: [continue-parse] ( adr,len -- level' )
   [skip-quoted?] 0= if					( adr,len )
      2dup s" [if]"     $=  >r				( adr len )
      2dup s" [ifdef]"  $=  r> or >r			( adr len )
      2dup s" [ifndef]" $=  r> or >r			( adr len )
      2dup s" [ifexist]" $= r> or >r			( adr len )
      2dup s" [ifnexist]" $= r> or if			( str len )
         2drop						( )
         SKIP-ALL [push-state]				( )
      else						( adr len )
         2dup s" [else]" $= if				( adr len )
            2drop					( )
	    [get-state] case				( )
	       SKIP-ALL		 of  endof			( )
               SKIP-TO-THEN      of  botched-else [error] endof
               SKIP-TO-ELSE-THEN of  ELSE-IS-NOOP [set-state] endof	( )
               ( ) ." [?? ELSE STATE] " nprompt cr
            endcase
         else						( adr len )
            s" [then]" $= if				( )
               [get-state] case				( )
                  SKIP-ALL       of  [pop-state] drop endof		( )
                  SKIP-TO-THEN	 of  [pop-state] drop  endof	( )
                  SKIP-TO-ELSE-THEN of [pop-state] drop endof	( )
                  ( ) ." [?? THEN STATE] " nprompt cr
               endcase
            then
         then						( )
      then						( )
   then							( )
;

: [skip-tokens] ( -- )
   true begin						( flag )
     [get-state] >r					( flag )
     r@ 0<> IF-IS-NOOP r@ <> and			( flag f )
     r> ELSE-IS-NOOP <> and				( flag f' )
     over and						( flag f' )
     while						( flag )
        parse-word dup if	 			( flag str,len )
           $canonical					( flag str,len )
           2dup " \" $= >r				( flag str,len )
           2dup " (" $= r> or if			( flag str,len )
               drop c@ [skip-comment]			( flag )
           else						( flag adr len )
               [continue-parse]				( flag )
           then						( flag )
        else						( flag str,len )
           2drop refill 0= if				( flag )
              where ." parse error" cr drop false	( flag )
           then 					( flag )
        then						( flag )
  repeat						( flag )
  drop
;

headers

: [else]
  [get-state] 1 <> if dangling-else [error] then
  [pop-state] drop
  SKIP-TO-THEN [push-state] [skip-tokens]
; immediate

: [if] ( -- )
   if
      IF-IS-NOOP [push-state]
   else
      SKIP-TO-ELSE-THEN [push-state] [skip-tokens]
   then
; immediate

: [then] ( -- )
   [pop-state] dup IF-IS-NOOP <> swap ELSE-IS-NOOP <> and if
      dangling-then [error]
   then
; immediate

headerless
: (ifcommon) ( verify? -- str,len )
   >r parse-word dup 0= if  missing-token [error]  then
   r> if  over c@ ascii ! = if bad-symbol-name [error] then  then
;


base @ decimal

\ These two will not match ANY symbol in the forth dictionary;
\ they only match symbols [define]d or -D symbol to the wrapper.
\
: (ndefined) ( -- str,len )
   caps @ >r caps off				( )
   parse-word  2dup $find if			( str,len acf )
      drop where				( str,len )
      ." do you mean [*exist]?, " 2dup type cr	( str,len )
   else						( str,len str,len )
      2drop					( str,len )
   then						( str,len )
   55 45 fsyscall				( va,len )
   r> caps !					( va,len )
;

headers

: [set-symbol] ( data,len name,len -- )  true 53 45 fsyscall  ;

: [get-symbol] ( name,len -- data,len )  55 45 fsyscall ;

\ define a boolen symbol
: [define]
   true (ifcommon)			( str,len )
   0 0 2swap				( 0 0 str,len )
   true 53 45 fsyscall			( )
; immediate

\ takes a single arg
: [undef]
   true (ifcommon)			( str,len )
   0 53 45 fsyscall 			( )
; immediate

\ Snag the next arg from the line and return the definition status/value
\ 0 0 means undefined, <non-zero> <len> is the value.
: [defined]
   false (ifcommon) [get-symbol]
; immediate


: [ifdef]
   (ndefined) drop postpone [if]
\   postpone [defined] drop postpone [if]
; immediate

: [ifndef]
   (ndefined) = postpone [if]
\   postpone [defined] = postpone [if]
; immediate

hex

\ These two are for scanning for defined words in the dictionary;
\ they will not match any [define] symbol.
\
: [ifexist]
   $defined  nip  dup 0=  if  nip  then  postpone [if]
; immediate

: [ifnexist]
   $defined  nip  0= dup  if  nip  then  postpone [if]
; immediate

base !
