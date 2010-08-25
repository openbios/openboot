id: @(#)forward.fth 2.12 03/12/08 13:22:32
purpose: 
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.
\ Copyright 1985-1990 Bradley Forthware

\ Metacompiler forward referencing code, target-independent

only forth also meta also forth definitions

\ Symbol entries in "symbols" vocabulary:

\    The "first-occurrence" field is the head of a linked list
\ its value is a pointer to an occurrence of this word in the
\ target dictionary.  Each node in the list is one 16-bit word.
\ The last node contains 0.  If there are no occurrences, the
\ first-occurrence field contains 0.
\    The "resadd" field contains the compilation address of the
\ word, or 0 if the word hasn't been defined yet.
\    Symbols are "does>" words, but historically hadn't been.

\  It is important to keep in mind the distinction between the ACF of the
\  named word as it occurs in the  symbols  vocabulary and as it occurs
\  in the target-space.  In stack diagrams, the former will be notated
\   acf-s  and the latter, acf-t .  The notation of just-plain  acf  will
\  be used to designate an ACF in the metacompilation host, as in what
\  gets "set" in the  setaction  function.

\ The PF of words in the  symbols  vocabulary consists of four fields:
\
: >first-occurrence ( acf-s -- first-occurrence-add ) >body ;
: >resolution  ( acf-s -- resolution-add ) >first-occurrence /a-t + ;
: >action      ( acf-s -- action-add ) >resolution /token-t + ;
: >info        ( acf-s -- info-addr ) >action /token +  ;
\
\  Note:  The order of these fields is closely linked with the sequence
\  of "<something>comma" events in the definition of  $makesym

: first-occurrence@ ( acf-s -- first-occurrence )  >first-occurrence rlink-t@  ;
: first-occurrence! ( first-occurrence acf-s -- )  >first-occurrence rlink-t!  ;
: resolution@ ( acf-s -- resolution ) >resolution token-t@ ;
: resolution! ( resolution acf-s -- ) >resolution token-t! ;
: action@     ( acf-s -- acf )   >action token@  ;
: action!     ( acf acf-s -- )   >action token!  ;
: info@       ( acf-s -- info )  >info c@  ;
: info!       ( info acf-s -- )  >info c!  ;

\ Add a new occurrence of word to the linked-list of occurrences.
\ The "first-occurrence" field is the head of the list.  If the list
\ is empty, it contains 0.  If the list isn't empty, it contains the
\ non-relocated target address of the most-recent
\ occurrence of the word.  That location, in turn, points to the
\ previous occurrence.  The last one in the list contains 0.

: addlink ( acf-s -- )
   here-t
   over first-occurrence@   ( acf-s occurrence old-first-link )
   over rlink!-t            ( acf-s occurrence )  \ link old list to occurrence
   swap first-occurrence!   ( )  \ link occurrence to head-of-list-node
   /token-t allot-t
;

variable lastacf-s
variable lastanf-s

\ Establish the action to be performed by the most recently
\ defined  symbol  when it is the target of "is"
: setaction  ( acf -- )  lastacf-s @  action!  ;

\ Perform the established action when the target-word
\ is the target of "is"
: do-action  ( ??? acf-s -- )
   action@  execute
;

\  The default action of a newly-defined  symbol  (until it's over-written)
: isunknown  ( n??? -- )
   drop  ." Unknown `is' action." cr
;

: $makesym  ( adr len -- acf-s )   \ makes a new symbol entry
   ['] symbols $vcreate
   here body>             \ leave acf-s for downstream code
   0  a-t,                \ initialize first-occurrence
   0  token-t,            \ initialize resolution
   ['] isunknown token,   \ initialize action
   0  c,		  \ info ( headers/headerless & immediate )
   does>
      \ When a target symbol executes, it compiles itself into the
      \ target dictionary by adding a reference to itself to the list.
      body>  ( acf )
      dup immediate?
      if
         .name
         ."  is immediate in the target system but it" cr
         ." is not defined in the metacompiler." cr abort
      else
         addlink
      then
;
: makesym ( str -- acf-s )  count $makesym  ;  \ makes a new symbol entry

: resolved?  ( acf-s -- flag )  \ true if already resolved
   resolution@ origin-t u>
;

\ Words to manipulate the symbol table vocabulary at the end of compilation.

: .x  ( -- )
   depth 30 u<  if  push-hex .s pop-base  else  ." Underflow"  then
;

\ Is there another entry in this list of occurrences?
: another-occurrence?  ( current-occurrence -- [ current-occurrence ] flag )
   dup  origin-t u>  if  true  else  drop false  then
;

\ resolve is used to replace all the references chained to
\ its argument acf-s with the associated referent
variable debugflag debugflag off
: resolve ( acf-s -- )  \ replace all links with the resolution
   dup resolution@ >r			(  )			  ( R: resol'n )
   first-occurrence@			( first-occ )
   \ If there are no occurrences,
   \ the resolution is just put in
   \ the "first-occurrence" field,
   \ which doesn't hurt anything
   begin   another-occurrence?     while
      \ first grab link to next occurrence before clobbering it
      dup rlink@-t          		( current-occ next-occ )  ( R: resol'n )
      \ put the resolution value in the current-occ.
      r@ rot  token!-t			( next-occurrence )	  ( R: resol'n )
   repeat
   r> drop
;

\ Print the addresses of all the places where this word is used
: where-used  ( acf-s -- )
   first-occurrence@			( first-occurrence )
   begin  another-occurrence?   while
      dup u. token@-t
   repeat
;

\ For each target symbol, prints the name of the word,
\ its compilation address, and all the places it's used.
\ Basically a cross-reference listing for the word.
: show  ( acf-s -- )  \ name, resolution, occurrences
   dup  .name   dup resolution@ u.   where-used
;

\ Find the named target symbol
: n'  \ name  ( voc-acf -- acf )
\ CROSS   [compile] ""
   safe-parse-word rot  $vfind 0=  if  type ."  not found" abort  then
;

\ Display all the target symbols
: nwords  ( voc-cfa -- )
   follow  begin   another?   while   .id 2 spaces   repeat
;

: .targ-acf ( acf-t -- )  ." h# "  <# u# u# u# u# u# u# u#> type  ;

\  Display all the symbols, with their offsets and types, along with
\  the   header: / headerless: indication.
: nheads ( -- )
   push-hex
   ['] symbols follow  begin   another?   while  ( anf )
      dup name>					 ( anf acf-s )
      dup  resolution@				 ( anf acf-s acf-t )
      .targ-acf 				 ( anf acf-s )
      info@ dup 3 and				 ( anf info-type header-type )
      over  ."  ( type " . ." )"
      case					 ( anf info-type )
	 0  of  ."  header: "      endof
	 1  of  ."  header: "      endof
	 2  of  ."  headerless: "  endof
         3  of  ."  header: "      endof
      endcase					 ( anf info-type )
      swap .id					 ( info-type )
      h# 80 and  if  ." immediate"  then	 (  )
      cr
   repeat
   pop-base
;

\  Display only the  headerless:  symbols with their offsets.
: nheadless ( -- )
   push-hex
   ['] symbols follow  begin   another?   while  ( anf )
      dup name> 				 ( anf acf-s )
      dup info@ 				 ( anf acf-s info-type )
      dup 3 and 2 <> if  3drop
      else  -rot				 ( info-type anf acf-s )
	 resolution@				 ( info-type anf acf-t )
	 .targ-acf 				 ( info-type anf )
	 ."  headerless: " .id			 ( info-type )
         h# 80 and  if  ." immediate"  then	 (  )
         cr
      then
   repeat
   pop-base
;

\ Display a cross-reference list
: cref  ( voc-cfa -- )
   follow  begin   another?   while   name> cr show   repeat
;

\ Display undefined forward references
: undef  ( voc-cfa -- )
   follow  begin  another?  while
     dup name> resolved? 0=  ( lfa f )
     if  .id space  else  drop  then
   repeat
;

\ Replace all the references with the resolution address
: fixall  ( voc-cfa -- )
   follow  begin  another?  while
     dup name> dup resolved?  ( lfa acf f )
     if   resolve  drop
     else drop .id ." not defined" cr then
   repeat
;
variable warning-t  \ warning for target
warning-t off

only forth also meta also definitions


\ Finds the acf-s of the symbol whose name is str, or makes it if it
\ doesn't already exist.
: $findsymbol  ( str -- acf-s )  $sfind 0=  if  $makesym  then  ;

\ Defines a new target symbol with name str.
\ If a symbol with the same name exists and has already been resolved,
\ a new one is created and a warning message is printed.
\ If a symbol of the same name exists but is unresolved (a forward reference),
\ a new one is not created.

: $create-s  ( str -- acf-s )
   2dup $findsymbol			( str acf-s )
   dup resolved?  if			( str acf-s )
      drop				( str )
      warning-t @  if			( str )
	 where 2dup type ."  isn't unique in target" cr
      then
      $makesym				( acf-s )
   else nip nip				( acf-s )
   then					( acf-s )
   dup lastacf-s !  >name lastanf-s !
;

\ Set the precedence bit on the most-recently-resolved symbol.
\ We can't do this with immediate-h because the symbol we need to make
\ immediate isn't necessarily the last one for which a header was
\ created.  It could have been a forward reference, with the header
\ created long ago.
: immediate-s  ( -- )
   lastanf-s @ n>flags   h# 40 toggle        \ fix symbol table
   lastacf-s @ dup info@ h# 80 or swap info!
;

\ hide-t temporarily prevents the most-recently-created word from being
\ found.  It is used when creating a colon definition, so that a colon
\ definition may refer to a previous word with the same name as itself,
\ without resulting in recursion.
\
\ reveal-t is the inverse of hide-t, allowing the most-recently-created
\ word to be found again.
\
\ In the normal Forth kernel, hide is implemented by unhooking the most
\ recent word from the dictionary.  That implementation doesn't work in
\ the metacompiler, because due to forward referencing, the current colon
\ definition is not necessarily the most-recently-created symbol.
\ Instead, we use a technique similar to the old FIG-Forth "smudge", where
\ the name is altered to make it unrecognizable.  "Smudge" was a toggle,
\ which suffered from the problem that sometimes "smudge" would inadvertantly
\ be executed one too many times, thus leaving the word hidden when it
\ should have been visible.  To eliminate this, we use separate words
\ hide and reveal.

: hide-t  ( -- )
   lastanf-s @  name>string xref-hide-hook
   drop  dup c@  h# 80  or  swap c!
;
: reveal-t  ( -- )
   lastanf-s @ name>string			( str,len )
   over dup c@  h# 80  invert and  swap c!	( str,len )
   xref-reveal-hook 2drop			( )
;
: .lastname  ( -- )
   \ This hack gets around the fact that symbol headers are "smudged"
   lastanf-s @ ?dup if  name>string  h# 1f and  bounds  ?do  i c@ h# 7f and emit  loop  then
;

\  compile,-t takes an acf-s and compiles it into
\  the current definition in the target-space.
: compile,-t ( acf-s -- ) addlink  ;

\ $compile-t takes a string and compiles a reference to that word in the
\ target dictionary.  In the case of a forward reference, this may
\ involve creating an entry in the symbol vocabulary.  Even if the
\ word has already been defined, we don't emplace the compilation address
\ yet.  Instead, we just add this location to a linked list of references
\ to the word.  For what it's worth, this makes generating a
\ cross-reference list easy at the end of the metacompilation.

: $compile-t  ( adr len -- )  $findsymbol ( acf-s ) addlink  ;

\ compile-t is used inside a definition.  It takes an in-line string
\ argument and stores the string somewhere in the definition.  When the
\ definition executes, that string is $compile-t'd.  This allows
\ immediate words to compile run-time words, even if the run-time
\ word hasn't yet been defined in the target system.

\ example : foo   compile-t bar   ;
\ when foo executes, it will then search for the word bar and
\ compile a reference to it.  The STRING bar is stored within foo

: compile-t  \ name  ( -- )
   [compile] [""]  compile count  compile $compile-t
; immediate
