\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: detokeni.fth
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
id: @(#)detokeni.fth 1.4 03/12/11 09:22:47
purpose: 
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\  Decompiles FCode binary code into FCode source text

only forth definitions
vocabulary detokenizer
only forth also detokenizer also definitions

warning @  warning off
: headers ; : headerless ;

needs init-tables ${BP}/pkg/fcode/common.fth
\ fload ${BP}/pkg/fcode/common.fth
32 buffer: name-buf
\ : $create  ( adr len -- )  name-buf pack count $create  ;
: /string  ( adr len cnt -- adr+cnt len-cnt )  tuck 2swap +  -rot -  ;

0 value paginate?
: cr  ( -- )  cr  paginate?  if  exit?  if  bye  then  then  ;
also forth definitions
: paginate  ( -- )  true to paginate?  ;

\  "Indenting" counterparts of  cr  and  ??cr
: icr ( -- )  cr lmargin @ spaces  ;
: ??icr ( -- )  #out @  lmargin @ >  if  icr  then  ;

previous definitions

: +indent ( -- )  3 lmargin +!  ;
: -indent ( -- ) -3 lmargin +!  ;

: name-leng ( acf -- $len+1 )
   >name name>string nip 1+		( $len+1 )  \  Account for space after...
;
: show-name ( acf -- )  dup name-leng  ?line  .name  ;
: show-byte  ( adr immediate? -- )  if  execute  ?cr  else  show-name  then  ;

: byte-load  ( adr spread -- )
   ['] show-byte is do-byte-compile
   push-hex
      byte-interpret	\ Interpret byte sequence
   pop-base
   cr ." end0 " cr
;


\  We will first load obsolete FCodes' token-table-entries with the
\      function  obsolete-fcode
\ 
\  Afterwards, we will load the same (obsolete) FCode numbers with
\      their functions' old names, causing each old (obsolete) name
\      to be freshly created as a  byte-code  word.  We will take
\      advantage of that:  detokenization will show the old name
\      together with an indication that the function is obsolete...
\ 
1 actions
action:		\  Detokenizer's display of an obsolete-fcode
   body>  dup ??icr .name
   ." "t\  Warning:  " .name ."  is an obsolete fcode."  icr
;

\  Test whether the newly created  byte-code  word is
\      an entry for an obsolete word.
\ 
\  If it is, attach the action to it.
\ 
\  Return an indication as to whether it was:  TRUE = it wasn't
\ 
: ?obsolete? ( code# tableaddr acf ftoken-addr --   ..... )
			( .... -- code# tableaddr acf ftoken-addr flag )
   dup token@ ['] obsolete-fcode <>	( code# tableaddr acf ftoken-addr flag )
   ?dup 0= if
      use-actions  2over set-immed
      false
   then
;

\  Test for token definitions that are duplicated, and issue a warning
: ?duplicate ( ftoken-addr -- ftoken-addr )
   dup token@
   ['] ferror <>
   if
     ??cr ." ****** DUPLICATE TOKEN "
     over .name cr
   then
;

\  Control the sequence of special testing of token definitions:
\ 
\  If the token isn't a name that was found, but was newly created,
\      then we want to test whether it was already entered in the
\      tables as an obsolete FCode.  If it was, then we want to
\      bypass the test for duplicate token definitions.
\ 
\  We want to test for duplicate token definitions if the token
\      is a name that was found, or if its name wasn't found and
\      wasn't already entered in the tables as an obsolete FCode.
\ 
: test-tokens ( code# tableaddr acf ftoken-addr new? --   .... )
				( ..... -- code# tableaddr acf ftoken-addr )
   if  ?obsolete?
   else  true
   then
   if  ?duplicate  then
;

: byte-code:  \ name  ( code# table# -- )
   >token-table 			      ( code# tableaddr )
   2dup parse-word  $find
   dup 0= >r						( R: new? )
   ?dup  if				( c#,t-a code# tableaddr acf immed? )
      dup 0> if 			( c#,t-a code# tableaddr acf immed? )
	 2over set-immed
      then drop				( c#,t-a code# tableaddr acf )
   else                                 ( c#,t-a code# tableaddr $adr,len )
      $create lastacf			( c#,t-a code# tableaddr acf )
   then 				( c#,t-a code# tableaddr acf )
   -rot swap ta+			( c#,t-a acf ftoken-addr ) ( R: new? )
   r>  test-tokens  
   token!  2drop			(   )
;

: .def  ( adr len -- )
   type space lastacf .name
;

variable tok-state tok-state off
: b(:)   ??cr  " :"  .def   3 lmargin !   icr tok-state on ; immediate

: b(field)           " field"    .def cr     ; immediate
: b(create)    ??cr  " create"   .def space  ; immediate
: b(constant)        " constant" .def cr     ; immediate
: b(variable)  ??cr  " variable" .def space  ; immediate
: b(value)           " value"    .def cr     ; immediate
: b(defer)     ??cr  " defer"    .def cr     ; immediate
: b(buffer:)         " buffer:"  .def cr     ; immediate

: b(;)  0 lmargin !  ??cr  ." ;" cr tok-state off ; immediate

: b(lit)  get-long ." h# " .x  ?cr  ; immediate

: b(') ( -- )
   tok-state @  if  ." ['] "  else  ." ' "  then next-fc-token drop .name  ?cr
; immediate

: b(")
   ascii " emit space get-bstring type ascii " emit space  ?cr
; immediate

: b(to)  ." to "  ; immediate

: .offset  ( adr len -- )  type  ." (" get-offset  (.) type ." ) "  ?cr  ;

: bbranch
   get-offset  0<  if
      -indent  icr  ." again "
   else
      -indent icr ." else "  +indent   icr
      next-fc-token 2drop  \ eat the b(>resolve)
   then
; immediate

\ : b?branch   " ?branch"  .offset  ; immediate
: b?branch
   get-offset  dup 0<  if
      drop
      -indent  icr  ." until" icr
   else  ( offset )
      interpreter-pointer @ +
      offset16? @  if  6  else  4  then -   ( adr )
      \ bbranch followed by a negative offset
      dup dup c@ h# 13 =   swap 1+ c@ h# 80 and 0<>  and  if ( addr )
	 -indent  icr  ." while "
	    h# b3 swap c!	\ Store the fake FCode for b(repeat)
      else                     ( addr )
	 drop ."  if  "
      then   +indent  icr
   then
; immediate

: drop-offset  ( -- )  get-offset drop  ;

: b(<mark)     ." begin  "  +indent icr  ; immediate
: b(>resolve)  -indent  icr ." then  "  ; immediate

: b(case)    ." case "  +indent icr  ; immediate
: b(of)      ." of "         drop-offset  ; immediate
: b(endof)   ." endof " icr  drop-offset  ; immediate
: b(endcase) -indent  icr  ." endcase " icr  ; immediate

: b(repeat)
   -indent  icr ." repeat  " drop-offset next-fc-token 2drop
; immediate

: b(loop)    ." loop  "   drop-offset  ?cr  ; immediate
: b(+loop)   ." +loop  "  drop-offset  ?cr  ; immediate
: b(do)      ." do  "     drop-offset  ?cr  ; immediate
: b(?do)     ." ?do  "    drop-offset  ?cr  ; immediate

: b(leave)   ." leave "  ; immediate

\  We would like to have the detokenizer's output be such that it can
\      be re-cycled through the tokenizer.  This would not only be a
\      "proof-of-correctness" tool, but also provide a way of testing
\      proposed changes to a piece of FCode for which source is not
\      available, as, for example, when a plug-in-card is found to
\      have a buggy driver.
\ 
\  In order to do this, we distinguish between the way the "fake-name"
\      is shown for a headerless token and for one whose name exists.
\ 
\  A headerless token should be shown as "(TT,CC)" (where TT and CC
\      are the Table and Code numbers), with no space separating the
\      open-paren from the rest of the string.  This could then become
\      the stand-in for the function's name, and will be displayed
\      -- for example -- after the colon.
\ 
\  A headerful token has its "fake-name" shown before the definition
\      occurs, with its supplied name appearing before the defining
\      line.  It should be in the form of a comment, i.e., as "( TT,CC)"
\      (note the space after the open-paren), because it really is
\      purely an informative item, and it only gets typed out anyway. 
\
\  Factor out the common elements:
\ 
\  We want to make sure we print out two digits, and not just one for
\  byte-codes less than 10.  It's safe to print exactly two digits,
\  because they're bytes and we're printing in hex.  Table-codes,
\  though, may be printed as only one digit...
: begin-fake-name  ( code# table# -- )
   swap <# ascii ) hold  u# u# drop  ascii , hold  u#s
;
: end-fake-name  ( -- $adr,len )
   ascii ( hold u#>
;

: fake-headerless-name  ( code# table# -- $adr,len )
   begin-fake-name  end-fake-name
;
: fake-headered-name  ( code# table# -- $adr,len )
   begin-fake-name bl hold  end-fake-name
;

: show-def  next-fc-token  drop execute  ;

: set-entry  ( acf code# table# -- )  >token-table swap ta+  token!  ;

\  The other thing we need to do to accomplish that is to print the
\      "naming" state.  That is to say, whenever a transition
\      is made between named, un-named, and external definitions,
\      we want to print the appropriate directive.
\  We accomplish that with a special variable and some special
\      words to handle them...
defer detok-naming-state   ' noop is detok-naming-state

\  Defining-word for a naming-state

\  Transition the naming-state; print it out if changed.
\ 
: is-naming-state ( apf -- )
   body>					( acf )
   ['] detok-naming-state behavior		( acf current-state )
   over = if  drop
   else 					( acf )
      dup is detok-naming-state
      cr .name cr
   then
;

:  detok-name-state:  ( -- ) \ name
   create
   does>  is-naming-state
;

\  Now we're ready to define the three magic words.
\ 
\  Better stash 'em out of the way of usual compilation,
\      in a vocabulary of their own...
\ 
vocabulary detok-name-states

detok-name-states definitions 
   detok-name-state: headerless
   detok-name-state: headers
   detok-name-state: external
detokenizer definitions

: new-token     \ then table#, code#, token-type
   [ also detok-name-states ] headerless [ previous ]
   get-byte get-byte swap			( code# table# )
   2dup fake-headerless-name $create  lastacf	( code# table# acf )
   -rot set-entry
   show-def
; immediate

: (named-token) ( -- )
   get-bstring $create  lastacf			( acf )
   get-byte get-byte swap			( acf code# table# )
   2dup cr fake-headered-name type space	( acf code# table# )
   set-entry
   show-def
;

: named-token   \ then string, table#, code#, token-type
   [ also detok-name-states ] headers [ previous ]
   (named-token)
; immediate

: external-token   \ then string, table#, code#, token-type
   [ also detok-name-states ] external [ previous ]
   (named-token)
; immediate

previous definitions

: .header  ( adr len -- )
   space  icr
   get-word		\  Show the Checksum later
   get-long dup 	\  Show Image Size in Hex and Decimal
   ." \  Image Size     h# " .x
   ."  ( d# "  .d  ." )   bytes." icr
   ." \  Checksum       h# "  .x  cr icr
;
: version1   \ then 0byte,chksum(2bytes),length(4bytes)
   ." FCode-version1"  .header
   get-byte drop  \ Skip the Rev# field
; immediate

: .start  ( -- )
   offset16  ." FCode-version"
   get-byte  8 >=  if  ." 3"  else  ." 2"  then   \ Rev# field
   ."  ( start"
;

: start0  ( -- )  .start ." 0 )" .header  ; immediate
: start1  ( -- )  .start ." 1 )" .header  ; immediate
: start2  ( -- )  .start ." 2 )" .header  ; immediate
: start4  ( -- )  .start ." 4 )" .header  ; immediate

: offset16   offset16  ." offset16" icr  ; immediate

: 4-byte-id  \ then 3 more bytes
   ." 4-byte-id " get-byte .x  get-byte .x  get-byte .x  icr
; immediate

: property  ." property" icr  ; immediate

alias v1   noop
alias v2   noop
alias v2.1 noop
alias v2.2 noop
alias v2.3 noop
alias v3   noop

\  We need non-immediate definitions of  >R   R>  and  R@
\      in the  detokenizer  vocabulary, so that they will
\      print out (instead of executing) during detokenization.
\  It would also be nice if they actually work...

\  context: detokenizer detokenizer forth re-heads root     current: detokenizer 
  forth
\  context: forth detokenizer forth re-heads root     current: detokenizer 

: r>   2r>  >r ;
: >r   r>  2>r ;
: r@  2r@ drop ;

  detokenizer

init-tables

fload ${BP}/pkg/tokenizr/primlist.fth

\  Load the obsolete FCode functions for the DeTokenizer
fload ${BP}/pkg/tokenizr/obsfcdtk.fth


h# 0b3 0 byte-code: b(repeat)  \ Used to be byte-code for V1 set-token

h# 10020 buffer: fcode-buf

: load-fcode  ( -- )
   fcode-buf h# 10020  ifd @ fgets  drop
   ifd @ fclose
;

\  Initialize simple variables for the detokenizer 
: init-detok ( -- )
   offset16? off
   ['] noop is detok-naming-state
   d# 64 rmargin !
;
only forth also detokenizer also forth definitions

: detokenize  \ name  ( -- )
   .detokenizer-version
   reading  load-fcode
   init-detok
   fcode-buf  dup @  h# 01030107 =  if  h# 20 +  then   ( adr )
   1 byte-load
   cr
;

warning !
