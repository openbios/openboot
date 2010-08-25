id: @(#)decomp.fth 2.17 04/02/02 10:01:54
purpose: 
copyright: Copyright 1999-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1985-1994 Bradley Forthware, Inc.
copyright: Use is subject to license terms.

\
\ The decompiler.
\ This program is based on the F83 decompiler by Perry and Laxen,
\ but it has been heavily modified:
\   Structured decompilation of conditionals
\   Largely machine independent
\   Prints the name of the definer for child words instead of the
\     definer's DOES> clause.
\   "Smart" decompilation of literals.

\ A Forth decompiler is a utility program that translates
\ executable forth code back into source code.  For many compiled languages,
\ decompilation is very hard or impossible.  Decompilation of threaded
\ code is relatively easy.
\ It was written with modifiability in mind, so if you add your
\ own special compiling words, it will be easy to change the
\ decompiler to include them.  This code is implementation
\ dependant, and will not necessarily work on other Forth system.
\ However, most of the  machine dependencies have been isolated into a
\ separate file "decompiler.m.f".
\ To invoke the decompiler, use the word SEE <name> where <name> is the
\ name of a Forth word.  Alternatively,  (SEE) will decompile the word
\ whose acf is on the stack.

: (in-dictionary?)  ( adr -- flag )  origin here within  ;
\ defer in-dictionary?
' (in-dictionary?) is in-dictionary?

: probably-cfa?  ( possible-acf -- flag )
   dup dup acf-aligned =  over in-dictionary?  and  if
      colon-cf?
   else
      drop false
   then
;

\ Given an ip, scan backwards until you find the acf.  This assumes
\ that the ip is within a colon definition, and it is not absolutely
\ guaranteed to work, but in practice it usually does.

: find-cfa  ( ip -- acf )
   begin
      dup in-dictionary?  0=  if  drop ['] lose  exit  then
      #talign -  dup  probably-cfa?
   until
;

\needs iscreate  create iscreate
\needs (wlit)    create (wlit)

start-module
decimal

only forth also hidden also forth definitions
defer (see)

hidden definitions
headerless
\ Like ." but goes to a new line if needed.
: cr".  ( adr len -- )  dup ?line type  ;
: .."   ( -- )  [compile] " compile cr".  ; immediate

\ Positional case defining word
\ Subscripts start from 0

\  Support routines:
\  Report out of range error
: out   ( #subscript pfa -- )
   cr  ." subscript out of range on "  dup body> .name
   ."    max is " ?   ."    tried " .  quit
;

\  Convert subscript # to address of token within body
: maptoken  ( #subscript pfa -- token-adr )
   2dup @  u<  if  na1+ swap ta+   else   out  then
;

\  forth definitions
\
\  headers

\  Positional case defining word
: case:  ( n -- )
   create ,    ]
   does>   ( #subscript pfa -- ) \ executes #'th word
      maptoken  token@  execute
;

: tassociative: ( n -- )
   create ,
   does>         ( xt pfa -- index )
      dup @				( xt pfa cnt )
      dup 2swap 			( cnt cnt xt pfa )
      na1+				( cnt cnt xt table-addr )
      rot 0  do				( cnt xt table-addr )
         2dup token@ =  if
            \  Clear stack and return index that matched
            3drop   i 0 0   leave
         then
         ta1+				( cnt xt table-addr' )
      loop				( index xt table-addr' )
      2drop
;

\  hidden definitions	\  We are already -- still  -- in
			\    hidden definitions headerless
headers transient
: #entries  ( associative-acf -- n )  >body @  ;
resident headerless

: nulldis  ( apf -- )  drop ." <no disassembler>"  ;
defer disassemble  ' nulldis is disassemble

\  headerless		\  We are already -- still  -- in
			\    hidden definitions headerless

\ Breaks is a list of places in a colon definition where control
\ is transferred without there being a branch nearby.
\ Each entry has two items: the address and a number which indicates
\ what kind of branch target it is (either a begin, for backward branches,
\ a then, for forward branches, or an exit.

h# 40 /n* buffer: breaks
variable end-breaks

variable break-type  variable break-addr   variable where-break
: next-break  ( -- break-address break-type )
   -1 break-addr !   ( prime stack)
   end-breaks @  breaks  ?do
      i  2@ over   break-addr @ u<  if
         break-type !  break-addr !  i where-break !
      else
         2drop
      then
   /n 2* +loop
   break-addr @  -1  <>  if  -1 -1 where-break @ 2!  then
;
: forward-branch?  ( ip-of-branch-token -- f )
   dup >target u<
;

\ Bare-if? checks to see if the target address on the stack was
\ produced by an IF with no ELSE.  This is used to decide whether
\ to put a THEN at that target address.  If the conditional branch
\ to this target is part of an IF ELSE THEN, the target address
\ for the THEN is found from the ELSE.  If the conditional branch
\ to this target was produced by a WHILE, there is no THEN.

   \  Support function for IF and WHILE
   \  Prepare for further examination of the token preceding
   \      the target of the current branch; it might be a branch...
   \  Leave its IP as well as its CFA on the stack
: >next-branch? ( ip-of-branch-target -- ip' possible-branch-acf )
   /branch - /token - dup token@	( ip' possible-branch-acf )
;

: bare-if? ( ip-of-branch-target -- f )
   >next-branch?				( ip' possible-branch-acf )
   dup ['] branch  =    \ unconditional branch means else or repeat
   if  drop drop false exit then  ( ip' acf )
   ['] ?branch =        \ cond. forw. branch is for an IF THEN with null body
   if   forward-branch?  else  drop true  then
;

\ While? decides if the conditional branch at the current ip is
\ for a WHILE as opposed to an IF.  It finds out by looking at the
\ target for the conditional branch;  if there is a backward branch
\ just before the target, it is a WHILE.
: while?  ( ip-of-?branch -- f )
  >target >next-branch? 		( ip' possible-branch-acf )
  ['] branch =  if          \ looking for the uncond. branch from the REPEAT
     forward-branch? 0=     \ if the branch is forward, it's an IF .. ELSE
  else
     drop false
  then

;
defer indent
: (indent)  ( -- )
  #out @ lmargin @ >  if  cr  then
  lmargin @ #out @ - spaces
;
' (indent) is indent

: +indent  ( -- )   3 lmargin +!  indent  ;
: -indent  ( -- )  -3 lmargin +!  indent  ;
: <indent  ( -- )  -3 lmargin +!  indent  3 lmargin +!   ;

: .begin  ( -- )  .." begin " +indent  ;
: .then   ( -- )  -indent .." then  "  ;

\ Extent holds the largest known extent of the current word, as determined
\ by branch targets seen so far.  This is used to decide if an exit should
\ terminate the decompilation, or whether it is "protected" by a conditional.
variable extent  extent off
: +extent  ( possible-new-extent -- )  extent @ umax extent !  ;
: +branch  ( ip-of-branch -- next-ip )  ta1+ /branch +  ;
: .endof  ( ip -- ip' )  .." endof" indent +branch  ;
: .endcase  ( ip -- ip' )  indent .." endcase" indent ta1+  ;

: add-break  ( break-address break-type -- )
   end-breaks @  breaks h# 40 /n* +  >=      ( adr,type full? )
   abort" Decompiler internal table overlow" ( adr,type )
   end-breaks @ breaks >  if                 ( adr,type )
      over end-breaks @ /n 2* - >r r@ 2@     ( adr,type  adr prev-adr,type )
      ['] .endof  =  -rot  =  and  if        ( adr,type )
	 r@ 2@  2swap  r> 2!                 ( prev-adr,type )
      else                                   ( adr,type )
	 r> drop                             ( adr,type )
      then                                   ( adr,type )
   then                                      ( adr,type )
   end-breaks @ 2!  /n 2*  end-breaks +!     (  )
;
: ?add-break  ( break-address break-type -- )
   over             ( break-address break-type break-address )
   end-breaks @ breaks  ?do
      dup  i 2@ drop   =  ( found? )  if
         drop 0  leave
      then
   /n 2*  +loop     ( break-address break-type not-found? )

   if  add-break  else  2drop  then
;

: scan-of  ( ip-of-(of -- ip' )
   dup >target dup +extent   ( ip next-of )
   /branch - /token -        ( ip endof-addr )
   dup ['] .endof add-break  ( ip endof-addr )
   ['] .endcase ?add-break
   +branch
;
: scan-branch  ( ip-of-?branch -- ip' )
   dup dup forward-branch?  if
      >target dup +extent   ( branch-target-address)
      dup bare-if?  if  ( ip ) \ is this an IF branch?
         ['] .then add-break
      else
         drop
      then
   else
      >target  ['] .begin add-break
   then
   +branch
;

: scan-unnest  ( ip -- ip' | 0 )
   dup extent @ u>=  if  drop 0  else  ta1+  then
;
: scan-;code ( ip -- ip' | 0 )  does-ip?  0=  if  drop 0  then  ;
: .;code    ( ip -- ip' )
   does-ip?  if
      .." does> "
   else
      0 lmargin ! indent .." ;code "  cr disassemble     0
   then
;
: .branch  ( ip -- ip' )
   dup forward-branch?  if
      <indent .." else" indent
   else
      -indent .." repeat "
   then
   +branch
;
: .?branch  ( ip -- ip' )
  dup forward-branch?  if
     dup while?  if
        <indent .." while" indent
     else
        .." if    "  +indent
     then
  else
     -indent .." until "
  then
  +branch
;

: .do     ( ip -- ip' )  .." do    " +indent  +branch  ;
: .?do    ( ip -- ip' )  .." ?do   " +indent  +branch  ;
: .loop   ( ip -- ip' )  -indent .." loop  " +branch  ;
: .+loop  ( ip -- ip' )  -indent .." +loop " +branch  ;
: .of     ( ip -- ip' )  .." of   " +branch  ;

\ first check for word being immediate so that it may be preceded
\ by [compile] if necessary
: check-[compile]  ( acf -- acf )
   dup immediate?  if  .." [compile] "  then
;

: .cword        ( ip -- ip' )	\ Display run-time word, e.g. (is) sans '()'
   dup token@ ?cr                     ( ip acf )
   >name name>string                  ( ip adr len )
   swap 1+ swap 2 -  type space       ( ip )	\ Remove parentheses
   ta1+
;
: .word         ( ip -- ip' )  dup token@ check-[compile] ?cr .name   ta1+  ;
\  : skip-word     ( ip -- ip' )  ta1+  ;
alias skip-word  ta1+
: .inline       ( ip -- ip' )  ta1+ dup unaligned-@  n.  na1+   ;
: skip-inline   ( ip -- ip' )  ta1+ na1+  ;
: .wlit         ( ip -- ip' )  ta1+ dup unaligned-w@ 1- . wa1+  ;
: .llit         ( ip -- ip' )  ta1+ dup unaligned-l@ 1- . la1+  ;
: .dlit         ( ip -- ip' )  ta1+ dup 2@ swap (ud.) type  ." . "  2 na+  ;
: skip-wlit     ( ip -- ip' )  ta1+ wa1+  ;
: skip-llit     ( ip -- ip' )  ta1+ la1+  ;
: skip-dlit     ( ip -- ip' )  ta1+ 2 na+  ;
: skip-branch   ( ip -- ip' )  +branch  ;
: .quote        ( ip -- ip' )  .word   .word   ;
\  : skip-quote    ( ip -- ip' )  ta1+ ta1+  ;
: skip-2-tokens ( ip -- ip' )  ta1+ ta1+  ;
alias skip-quote skip-2-tokens
: .compile      ( ip -- ip' )  ." compile " ta1+ .word   ;
\  : skip-compile  ( ip -- ip' )  ta1+ ta1+  ;
alias skip-compile skip-2-tokens
: skip-string   ( ip -- ip' )  ta1+ +str  ;
: .(')          ( ip -- ip' )  ta1+  .." ['] " dup token@ .name  ta1+ ;
\  : skip-(')      ( ip -- ip' )  ta1+ ta1+  ;
alias skip-(') skip-2-tokens
: .is           ( ip -- ip' )  ." is " ta1+ dup token@ .name  ta1+ ;
: .string-tail  ( ip -- ip' )  dup count type  +str ." "" " ;
: .string       ( ip -- ip' )  .cword .string-tail ;
: .pstring      ( ip -- ip' )  ?cr  ." p"" "   ta1+ .string-tail ;

\ Use this version of .branch if the structured conditional code is not used
\ : .branch     ( ip -- ip' )  .word   dup <w@ .   /branch +   ;

: .unnest     ( ip -- ip' )
   dup extent @ u>=  if
      0 lmargin ! indent .." ; " drop   0
   else
      .." exit " ta1+
   then
;

: dummy ;

\ classify each word in a definition
\  Common constant for sizing the three classes:
headers
transient  d# 34 constant #decomp-classes  resident
headerless

#decomp-classes tassociative: execution-class  ( token -- index )
]
   (  0 )     (lit)                 (  1 )     ?branch
   (  2 )     branch                (  3 )     (loop)
   (  4 )     (+loop)               (  5 )     (do)
   (  6 )     compile               (  7 )     (.")
   (  8 )     (abort")              (  9 )     (;code)
   ( 10 )     unnest                ( 11 )     (")
   ( 12 )     (?do)                 ( 13 )     (does>)
   ( 14 )     exit                  ( 15 )     (wlit)
   ( 16 )     (')                   ( 17 )     (of)
   ( 18 )     (endof)               ( 19 )     (endcase)
   ( 20 )     ("s)	            ( 21 )     (is-defer)
   ( 22 )     (dlit)                ( 23 )     (llit)
   ( 24 )     (is-user)             ( 25 )     (is-const)
   ( 26 )     dummy                 ( 27 )     dummy
   ( 28 )     dummy                 ( 29 )     dummy
   ( 30 )     dummy                 ( 31 )     dummy
   ( 32 )     dummy                 ( 33 )     dummy
[

\ Print a word that has been classified by  execution-class
#decomp-classes 1+ case: .execution-class  ( ip index -- ip' )
   (  0 )     .inline                (  1 )     .?branch
   (  2 )     .branch                (  3 )     .loop
   (  4 )     .+loop                 (  6 )     .do
   (  6 )     .compile               (  7 )     .string
   (  8 )     .string                (  9 )     .;code
   ( 10 )     .unnest                ( 11 )     .string
   ( 12 )     .?do                   ( 13 )     .;code
   ( 14 )     .unnest                ( 15 )     .wlit
   ( 16 )     .(')                   ( 17 )     .of
   ( 18 )     .endof                 ( 19 )     .endcase
   ( 20 )     .pstring               ( 21 )     .is
   ( 22 )     .dlit                  ( 23 )     .llit
   ( 24 )     .is                    ( 25 )     .is  
   ( 26 )     dummy                  ( 27 )     dummy
   ( 28 )     dummy                  ( 29 )     dummy
   ( 30 )     dummy                  ( 31 )     dummy
   ( 32 )     dummy                  ( 33 )     dummy
   ( default ) .word
[

\ Determine the control structure implications of a word
\ that has been classified by  execution-class
#decomp-classes 1+ case: do-scan
   (  0 )     skip-inline            (  1 )     scan-branch
   (  2 )     scan-branch            (  3 )     skip-branch
   (  4 )     skip-branch            (  6 )     skip-branch
   (  6 )     skip-compile           (  7 )     skip-string
   (  8 )     skip-string            (  9 )     scan-;code
   ( 10 )     scan-unnest            ( 11 )     skip-string
   ( 12 )     skip-branch            ( 13 )     scan-;code
   ( 14 )     scan-unnest            ( 15 )     skip-wlit
   ( 16 )     skip-(')		     ( 17 )     scan-of
   ( 18 )     skip-branch            ( 19 )     skip-word
   ( 20 )     skip-string            ( 21 )     skip-word
   ( 22 )     skip-dlit              ( 23 )     skip-llit
   ( 24 )     skip-word              ( 25 )     skip-word
   ( 26 )     dummy                  ( 27 )     dummy
   ( 28 )     dummy                  ( 29 )     dummy
   ( 30 )     dummy                  ( 31 )     dummy
   ( 32 )     dummy                  ( 33 )     dummy
  ( default ) skip-word
[

: install-decomp  ( literal-acf display-acf skip-acf -- )
   rot					( disp-acf skip-acf lit-acf )
   ['] dummy					\  target
   ['] execution-class >body na1+		\  search-start
   dup   [ #decomp-classes ] literal ta+	\  search-limit
   tsearch if  token!
      ['] dummy ['] do-scan          (patch
      ['] dummy ['] .execution-class (patch
   else  3drop  where ." Can't install-decomp.  Tables full." cr
   then
;

\ Scan the parameter field of a colon definition and determine the
\ places where control is transferred.
: scan-pf   ( apf -- )
   dup extent !                           ( apf )
   breaks end-breaks !                    ( apf )
   begin                                  ( adr )
      dup token@ execution-class do-scan  ( adr' )
      dup 0=                              ( adr' flag )
   until                                  ( adr )
   drop
;

forth definitions
headers
: .token  ( ip -- ip' | 0 )  dup token@ execution-class .execution-class  ;

\ Decompile the parameter field of colon definition
: .pf   ( apf -- )
   dup scan-pf next-break 3 lmargin ! indent          ( apf )
   begin                                              ( adr )
      ?cr  break-addr @ over =  if                    ( adr )
	 begin                                        ( adr )
	    break-type @ execute                      ( adr )
	    next-break  break-addr @ over <>          ( adr done? )
	 until                                        ( adr )
      else                                            ( adr )
         .token                                       ( adr' )
      then                                            ( adr' )
      dup 0=  exit?  if  nullstring throw  then       ( adr' )
   until  drop                                        (  )
;
headerless
hidden definitions

: .immediate  ( acf -- )   immediate? if   .." immediate"   then   ;

: .definer    ( acf definer-acf -- acf )  .name  dup .name  ;

: dump-body  ( pfa -- )
   push-hex
   dup @ n. 2 spaces  8 emit.ln
   pop-base
;
\ Display category of word
: .:           ( acf definer -- )  .definer space space  >body  .pf   ;
: .constant    ( acf definer -- )  over >data ?   .definer drop  ;
: .2constant   ( acf definer -- )  over >data dup ?  na1+ ?  .definer drop  ;
: .vocabulary  ( acf definer -- )  .definer drop  ;
: .code        ( acf definer -- )  .definer >code disassemble  ;
: .variable    ( acf definer -- )
   over >data n.   .definer   .." value = " >data ?
;
: .create     ( acf definer -- )
   over >body n.   .definer   .." value = " >body dump-body
;
: .user        ( acf definer -- )
   over >body ?   .definer   .."  value = "   >data  ?
;
: .defer       ( acf definer -- )
   .definer  .." is " cr  >data token@ (see)
;
: .alias       ( acf definer -- )
   .definer >body token@ .name
;
: .value      ( acf definer -- )
   swap >data ? .definer
;


\ Decompile a word whose type is not one of those listed in
\ definition-class.  These include does> and ;code words which
\ are not explicitly recognized in definition-class.
: .other   ( acf definer -- )
   .definer   >body ."    (Body: " dump-body ."  ) " cr
;


\ Classify a word based on its acf
headers transient
alias  isalias  noop
create iscreate
0 0 2constant is2cons

: wt,  \ name  ( -- )  \ Compile name's word type
   ' word-type token,
;
resident headerless

d# 10 tassociative: word-types
   ( 0 )   wt, here        ( 1 )   wt, bl
   ( 2 )   wt, #user       ( 3 )   wt, base
   ( 4 )   wt, emit        ( 5 )   wt, iscreate
   ( 6 )   wt, forth       ( 7 )   wt, isalias
   ( 8 )   wt, limit       ( 9 )   wt, is2cons

d# 11 tassociative: definition-class
]
   (  0 )   :               (  1 )   constant
   (  2 )   variable        (  3 )   user
   (  4 )   defer           (  5 )   create
   (  6 )   vocabulary      (  7 )   alias
   (  8 )   value           (  9 )   2constant
   ( 10 )   code
[

d# 12  case: .definition-class
   ( 0 )   .:              ( 1 )   .constant
   ( 2 )   .variable       ( 3 )   .user
   ( 4 )   .defer          ( 5 )   .create
   ( 6 )   .vocabulary     ( 7 )   .alias
   ( 8 )   .value          ( 9 )   .2constant
   ( 10)   .code           ( 11)   .other
[

: definer  ( acf-of-child -- acf-of-defining-word )
   dup code?  if  drop ['] code   exit then            ( acf )
   dup word-type word-types                            ( acf index )
   dup [ ' word-types #entries ] literal   =  if       ( acf index )
      drop word-type find-cfa                          ( definer )
   else                                                ( acf index )
      nip  ['] definition-class >body maptoken token@  ( definer )
   then
;

\ top level of the decompiler SEE
: ((see   ( acf -- )
   d# 64 rmargin !
   dup dup definer dup   definition-class .definition-class
   .immediate
   ??cr
;
headers
' ((see  is (see)

forth definitions

: see  \ name  ( -- )
   '  ['] (see) catch  if  drop  then
;
only forth also definitions
end-module
