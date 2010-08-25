\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tokenize.fth
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
id: @(#)tokenize.fth 1.16 06/02/16
purpose: Tokenizer program source - converts FCode source to byte codes
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ TODO:
\ Add a means to define symbols for use with ifdef
\ Add a means to set the start code from the command line

only forth also definitions

\ ' $report-name is include-hook
\ ' noop         is include-hook

\ Force externals, this is for debugging
variable force-external? force-external? off

\ Force headers, also for debugging
variable force-headers? force-headers? off

\ Force headerless.  For debugging and also
\     for trimming down your binary without
\     changing your source-base.
variable force-headerless? force-headerless? off

\  To activate any of the above, set it "on" from the command-line

vocabulary tokenizer
also tokenizer also definitions

decimal  warning off  caps on
fload ${BP}/fm/lib/split.fth      \ 32>8,8,8,8; 16>8,8; 8,8>16 ...

\ Keep quiet about warnings and statistics.
variable silent  silent off

\ when true,  #, #s, #> uses single vs double stack values.
variable pre1275  pre1275 off

\ true to prepend an a.out header to the output file
variable aout-header?  aout-header? off

\ Statistics variables used in final statistics word
variable #literals
variable #locals
variable #apps
variable #primitives

variable #constants
variable #values
variable #variables
variable #buffers
variable #defers

variable compiling		   \ True if in an FCode definition
variable #end0s  #end0s off	   \ How many END0 tokens encountered
variable offset-8?  offset-8? off  \ Can be set to true by tokenize script

defer fcode-start-code		   \ start0, start1, start2, or start4

variable tokenization-error	\ True if error encountered in FCode source

\  File header creation, fill in size later (see a.out(5) for format)
create header  h# 01030107 ,  0 ,  0 ,  0 ,  0 ,  h# 4000 ,  0 ,  0 ,

\  Monitor current output counters
\ 'bhere' returns the total # of byte-codes output so far.
\ 'fhere' returns the current position in the file.  This will be
\ different, because of the file header (32 bytes), and sometimes more
\ because of debugging information being output as well as byte-codes.

variable bytes-emitted  \ Total # of byte-codes output so far
: bhere  ( -- #token-bytes-emitted )  bytes-emitted @  ;
: fhere  ( -- cur-file-pos )  ofd @ ftell  ;


\ Vectored output primitives
: .byte  ( c -- )
   \ put byte to output file
   ofd @ fputc
;

\  : .word  ( w -- )
\     wbsplit .byte .byte
\  ;
\
\  : .long  ( l -- )
\     lbsplit .byte .byte .byte .byte
\  ;


: inc    ( adr -- )  1 swap +! ;   \ increment variable

variable checksum 	\ Running total of all emitted bytes
: emit-fbyte  ( c -- )
   dup checksum +!  .byte  bytes-emitted inc
\   bytes-emitted @ .x checksum @ .x cr
;

\ The user-level "emit-byte" will *not* affect the running-total
\ length and checksum fields before "fcode-versionx" and after "end0"
\ This allows embedded binary before and after the fcode to work
\ correctly, i.e. leave the fcode-only image unaltered.
defer emit-byte
' .byte is emit-byte  \ Will later be vectored to emit-fbyte

: emit-word  ( w -- )  wbsplit  emit-byte emit-byte  ;
: emit-long  ( l -- )  lwsplit  emit-word emit-word  ;

: emit-token        ( apf -- )
   c@ emit-byte
;

: emit-local-escape ( apf -- )  \ (adr+1)c@=0 then output 1 byte token
   ca1+  dup c@  if  emit-token  else  drop  then
;

: emit-local  ( apf -- )
   dup emit-local-escape emit-token
;

: pad-size  ( -- )  \ Pad file to longword boundary
   ofd @ ftell  ( size )
   dup /l round-up swap -  0  ?do  0 emit-byte  loop
;

\  Compiling word to create primitive tokens
variable which-version    \ bit variable - each bit represents a version's use

variable #version1s    \ accumulator of version 1   tokens compiled
variable #version1+2s  \ accumulator of version 1+2 tokens compiled
variable #version2s    \ accumulator of version   2.x tokens compiled
variable #version2.1s  \ accumulator of version   2.1 tokens compiled
variable #version2.2s  \ accumulator of version   2.2 tokens compiled
variable #version2.3s  \ accumulator of version   2.3 tokens compiled
variable #version3s    \ accumulator of version   3   tokens compiled
variable #obsoletes    \ accumulator of obsolete      tokens compiled

: or!    ( adr bit$ -- ) over @ or swap ! ;  \ or in bit string

: v1   ( -- ) which-version 1 or! ;      \ FCode was/is versions 1
: v2   ( -- ) which-version 2 or! ;      \ FCode was/is versions 2.0
: v2.1 ( -- ) which-version 4 or! ;      \ FCode was/is versions 2.1
: v2.2 ( -- ) which-version 8 or! ;      \ FCode was/is versions 2.2
: v2.3 ( -- ) which-version h# 10 or! ;  \ FCode was/is versions 2.3
: v3   ( -- ) which-version h# 20 or! ;  \ FCode was/is versions 3
: obs  ( -- ) h# 40 which-version ! ;    \ FCode is obsolete

\  We need a convenient way to mark ALL the obsoleted FCodes with  obs
\      but we can't change them in their source files, because their
\      version-designators may be used elsewhere...
\
vocabulary obs-fcoder  also obs-fcoder definitions
   \  We're going to redefine, in this vocabulary, all of the
   \      version-designators (except  v1 , since, if a token
   \      designated by  v1  alone is used in an FCode source,
   \      that will invalidate the tokenization) that are used
   \      in the collection of obsoleted FCodes to designate
   \      obsolete versions.
   \ 
   \  Put this vocabulary at the top of the search-order before
   \      loading the obsoleted FCodes; it will act as a filter.
   \ 
   alias v2  obs
   alias v2.2  obs
   \ 
   \  The codes  v2.1  v2.3  or  v3  are not used in the collection
   \      of obsoleted FCodes, and might not even designate obsolete
   \      versions at all...
previous definitions

h# 40 constant max-version

: check-version ( -- vers# )
   which-version dup @  swap off
   dup 0=  abort" missing v1, v2 ... byte-code: prefix"
   dup max-version > abort" something wrong with ver-flag; (too big)"
;

\  Print the token's name in back-and-forward quotes, thus:  `name'
: .`name' ( cfa -- )
    ." `"  >name name>string type  ." '"	\  No space after
;

: .token-warning ( pfa -- pfa )
   where ." *** Warning: "  dup body> .`name'
;

: count-version ( pfa vers# -- pfa )
   case
       1 of
	  .token-warning
	  ."  is an obsoleted version 1 token. ***"
	     #version1s
	 endof
       2 of  #version2s    endof
       3 of  #version1+2s  endof

       4 of  #version2.1s  endof
       8 of  #version2.2s  endof
   h# 10 of  #version2.3s  endof
   h# 20 of  #version3s    endof
   h# 40 of
	    silent @ 0=  if
	       .token-warning
	       ."  is an obsolete FCode token. ***" cr
	    then
	      #obsoletes
	 endof
   endcase				( pfa adr )
   inc
;

\  Common preface to a tokenization-error message:
: .tokenization-error ( -- )
   tokenization-error on
   where ." Error: "
;

\  Include this in a definition of an obsolete word that will
\      have special redeeming behavior, but still should shout
\      a warning.  Obtain the calling word's PFA from its
\      inevitable residue on the return stack.
: .obsolete ( -- )
   r@ find-cfa >body		\  PFA of calling word
   h# 40  count-version  drop
;

\  Incorporate this into a special definition where a sequence
\      will replace the named token.  The replacement sequence
\      should be passed as a string which will be interpreted
\      in the tokenization context.  The calling word's name
\      will also be obtained from the return stack to be printed.
: replace ( $adr,len -- )
   silent @ 0=  if
      r@ find-cfa			\  CFA of calling word
      where ." *** Replacing "		( $adr,len cfa )
      .`name'  ."  with:  "		( $adr,len )
      2dup  type  cr
   then
   eval 			(  )
;


\  We're going to create the means to give an error message if
\      the target of  ' ("tick") or ['] ("bracket-tick-bracket")
\      is not what the user expects it to be (e.g., a macro that
\      resolves into a multi-byte-code sequence).
\
\  Valid targets are words that will issue a direct byte-code.
\      Some of them can be identified by their defining-word;
\      the  word-type  function will yield that information.
\
\  We're going to create a linked-list of word-types that identify
\      valid "tick-targets".  To do that, we'll create a modifying
\      word -- syntactically similar to  immediate  in that it
\      takes effect on the last definition made.
\
\  All the valid defining-words are  create ... does>  type words
\      and we're going to take advantage of that fact plus the fact
\      that the invocation of  does>  updates  lastacf  to point
\      at exactly the location that will be returned when  word-type
\      is applied to a word defined by the defining-word just defined.
\      (Does this make your head spin?  I'm positively giddy!)
\
\  First, we need a place to keep the start of the linked-list:

create tick-target-word-type-link    null link,


\  Each entry in the linked list will consist of two items:
\      (1)  The word-type token to be entered into the list
\      (2)  A link pointing to the preceding link (null at end of list).

\  Support function.  Enter the given CFA into the list whose
\      starter-pointer address is also given:
: (valid-tick-target) ( type-cfa link-start-addr -- )
   swap  token,
   here 			\  Establish new start of linked-list
   swap					( here link-start-addr )
   dup link@				( here link-start-addr prev-link )
   link,				( here link-start-addr )
   link!				(  )
;

\  Enter the word-type of words that will be defined by a newly-defined
\      defining-word into the list of valid "tick-targets".
\
\  Use this immediately after defining the defining-word.
\      (Syntactically similar to  immediate .)
: valid-tick-target-word-type ( -- )
   lastacf tick-target-word-type-link  (valid-tick-target)
;

\  Scan through the linked-list, to find whether the word-type
\      of the function whose CFA is given is a valid tick-target.
\
\  Return a  not-valid?  flag, indicating whether further checking
\      is required, and under that, either the original CFA (if
\      it's not valid) or another false, to be passed on as the
\       not-valid?  flag for the next customer...
\
\  Support function.  Given a CFA (of a word-type or a function)
\      and the address of the link that starts the list, do the
\      actual search through the list:
: (bad-tick-target?) ( cfa link-start-addr -- cfa true | false false )
   over true 2swap begin			( cfa true cfa link-adr )
   another-link?  while 			( cfa true cfa next-link )
      2dup /token - token@ = if
	 [ also hidden ] 4drop [ previous ] false false
	 exit
      then					( cfa true cfa next-link )
   repeat					( cfa true cfa )
   drop
;

\  Rather than require awkward stack-dancing, we will not attempt to
\      retain the CFA on the stack, nor to return it.  The calling
\      routine will have a much easier time handling that...
: bad-tick-target-word-type? ( cfa -- true | false false )
   word-type				( word-type )
   tick-target-word-type-link		( word-type link-start-addr )
   (bad-tick-target?)			( word-type true | false false )
   dup if nip then
;


\  We will create an "exceptions list" that is a linked-list of
\      tokens of colon-definitions that are valid "tick-targets".

\  Start with a pointer to the start of the list

create tick-target-:-link    null link,

\  The entries in this linked list are structured similarly to
\      the one preceding.  The first item is the token of the
\      exempted word.  It is remarkably similar in form... ;-)

\  Enter the newly-defined function into the list of valid
\      "tick-targets" even though its word-type (mainly colon)
\      doesn't qualify it.
\
\  Use this immediately after defining the function to validate.
\      (Syntactically similar to  immediate .)
: valid-tick-target ( -- ) 
   lastacf tick-target-:-link  (valid-tick-target)
;


\  Scan through the linked-list, to find whether the function
\      whose CFA is given is a valid colon-defined tick-target.
: bad-:-tick-target? ( cfa -- cfa true | false false )
   tick-target-:-link 
   (bad-tick-target?)
;

\  Chain together the categories we're testing.
\       At present, there are only two of 'em...
: bad-tick-target? ( cfa -- not-valid? )
   \  Do the  word-type  test first because:
   \      (A)  It's faster (fewer entries in the table)
   \  and (B)  it's -- by far -- more frequently encountered.
   dup bad-tick-target-word-type? if
      dup bad-:-tick-target? nip
   then  nip
;

\  Give the error-message.
: .bad-tick-target ( cfa -- cfa )
   .tokenization-error
   dup .`name'
   ."  is not a valid target for ' or [']" cr
;


\  Shout if the next token in the input stream
\      isn't a valid target for  '  or  [']
\
\  Incorporate this into the '  or  ['] words...
\
: ?valid-tick-target ( -- )  \  <name> (but does not consume it.)
   >in @					( old>in )
      parse-word				( old>in $adr,len )
   rot >in !

   $find if					( cfa )
      dup bad-tick-target? if			( cfa )
	 .bad-tick-target
      then  drop
   else 					( $adr,len )
      \  Next token wasn't found; let normal  ?  mechanism handle it.
      2drop
   then 					(  )
;


: byte-code:  \ name  ( token# table# -- )  \ Compiling
   ( -- )  \ At execute time, sends proper token# to output stream
   check-version
   create  rot c, swap c, c,
   does>  dup 2 ca+ c@
   count-version
   emit-local  #apps inc
;   valid-tick-target-word-type

\  A  v2-compat:  definition need not necessarily be a valid "tick-target"
\      but we can detect if it is and mark it as such.

: v2-compat:  \ old-name current-name  ( -- )
   create  '					( current-name-cfa )
   dup bad-tick-target? 0= swap 		( valid? cfa )
   token,
   if    valid-tick-target   then
   does>
      silent @ 0=  if
         where
         ." Warning: Substituting " dup token@ .`name'
         ."  for old name " dup body> .`name' cr
      then
      token@ execute
;

: Pre-1275:  \ new-name new-name old-name ( -- )
   create
   hide  ' token,  ' token,   reveal
   does>
      silent @ 0=  if
         pre1275 @  if
            where
            ." Warning: Substituting single stack item "
            dup  ta1+  token@ .`name'
            ."  for "  dup token@ .`name' cr
         then
      then
      pre1275 @  if  ta1+   then
      token@ execute
;

: depend-load \ 'feature-symbol' file
   safe-parse-word safe-parse-word		( symbol$ file$ )
   2swap [get-symbol] drop if			( file$ )
      included					( )
   else						( file$ )
      " DEPEND" [get-symbol] drop if		( file$ )
         ." File: " type cr			( )
      else					( file$ )
         2drop					( )
      then					( )
   then						( )
;

fload ${BP}/fm/lib/message.fth

\ When executing, forth, tokens and 'reforth' words are allowed.
\   'reforth' vocab. redefines certain words like : and constant.
\
\ When compiling, *only* prim. tokens, macros or new local tokens
\   are allowed.  The file 'crosslis.fth' holds equivalent names
\   for missing primitives, e.g.  : 2+  2 + ;
\
\ Needed words that do not have primitive token equivalents
\   (e.g.:  h#  etc.) are handled with aliases to standard forth.
\
\ Control words (if, begin, loop, etc.) have custom definitions, as
\   do a limited set of string input words as well as words that
\   generate special literals, (e.g.:  ascii  control  etc.).


\  Add allowed tokens into 'tokens' vocabulary
only forth definitions
vocabulary tokens
vocabulary reforth

\   don't search the tokens voc because it includes numbers (-1, 0, 1, ..)
only forth also tokenizer also  tokens definitions  tokenizer

fload ${BP}/pkg/tokenizr/primlist.fth      \ Basic ("complete"?) set of FCodes

[ifdef] v2-compat
   also obs-fcoder
fload ${BP}/pkg/tokenizr/obsfcode.fth
   previous
[then]
only forth also tokenizer also

\   For the rest of this file, the search order is *always* either:
\
\     context: forth   forth root     current: forth     - or -
\     context: tokens  forth root     current: tokens    - or -
\     context: reforth forth root     current: reforth

tokens definitions
alias \		\
alias 16\	\
alias (		(
alias (s	(
alias .(	.(
alias th	th	\ becoming obsolete
alias td	td	\ becoming obsolete
alias h#	h#
alias d#	d#
alias o#	o#
alias b#	b#

alias [define] [define]			\ define a symbol
alias [undef] [undef]			\ undefine
alias [defined] [defined]		\ forward parsed symbol-value
alias [ifdef] [ifdef]
alias [ifndef] [ifndef]
alias [ifexist] [ifexist]
alias [ifnexist] [ifnexist]
alias [message] [message]		\ For spitting out compile info
alias depend-load depend-load
alias [then]   [then]
alias [else]   [else]
alias recursive recursive
tokenizer definitions

\ Init search path during execution
: init-path  ( )  \ Outside of definitions, allow  'tokens' and 'reforth'
   only root also reforth also tokens definitions
;

: tokens-only  ( -- )  \ Allow only tokens within definitions
   only tokens also definitions
;

: restore-path  ( )
   only forth also definitions
;

\  More output primitives
: emit-number  ( n -- )
   [ also tokens ]  b(lit)  [ previous ]  emit-long
   1 #literals +!
;
: tokenize-literal  ( n 1 | d 2 -- )
   2 = if swap emit-number then emit-number  ;

\ Lookup table primitives
\ 'lookup' table contains 256 longword values, corresponding
\ to 256 possible local tokens.  Entry #n contains the offset from the
\ beginning of the bytes-output file where the definition of local
\ token#n begins.  For variables and constants, entry #n+1 contains
\ the actual value of the variable (0 initially) or constant.

8 constant first-local-escape

256 /l* constant 1tablesize  \ Size of one 256-word table
1tablesize  8 * buffer: lookup

variable next-lookup#  \ Next lookup# available
variable local-escape  \ Current local escape-code

: advance-lookup#  ( -- )  1 next-lookup# +!  ;
: lookup#-range-check  ( -- )
   next-lookup# @  d# 254 >  if
      1 local-escape +!   0 next-lookup# !
   then
;

: next-lookup  ( -- addr )
   next-lookup# @  /l*
   local-escape @  first-local-escape -  1tablesize *  +
   lookup +
;

: set-lookup-pointer  ( bhere -- )  \ Pnt cur lookup# to current byte-out
   lookup#-range-check
   next-lookup  l!
;


\  Go back and patch previous output items
: patch-byte  ( byte addr -- )     \ Go back to 'addr' and insert 'val'
   fhere  >r  			   \ Save current file pointer
   ofd @  fseek  		   \ Move back to 'addr' location
   emit-fbyte  -1 bytes-emitted +! \ fix forward reference
   r>  ofd @  fseek  		   \ Restore current file pointer
;
: patch-word  ( word addr -- )  >r wbsplit  r@ patch-byte  r> 1+ patch-byte  ;
: patch-long  ( long addr -- )  >r lwsplit  r@ patch-word  r> 2+ patch-word  ;

variable dummy   0 dummy !   \ Use this form just so we can see
                             \ the name with emit-token during debug.
: emit-dummy  ( -- )
   ['] dummy >body emit-token  \ Emit 0-value dummy token for now
;

variable local-start  \ Byte-count at start of current word
: save-local-start  ( -- )  \ Save current bytes-emitted value
   bhere  local-start !
;


\  Length & checksum creation
variable checksumloc    \ Location of checksum and length fields

variable fcode-vers fcode-vers off
: .mult-fcode-vers-error ( -- )
   silent @ 0=  if
      ??cr where ." Warning: Multiple Fcode-version# commands encountered. " cr
   then
;
: restore-header ( -- )
   ['] tokenize-literal  is do-literal
   [ forth ]  ['] (header)  is header [ tokenizer ]
;

tokens definitions

\ The accepted plug-in format is:
\ fd  - version1 fcode (1 byte) for first encountered fcode.
\  0  - revision byte
\ checksum - 2 bytes containing the fcode PROM checksum.
\ length - 4 bytes specifying the total usable length of fcode data
\          (i.e. from 'version1' to 'end0' inclusive)
\
\ The checksum is calculated by summing all remaining bytes, from just after
\ the length field to the end of the usable fcode data (as indicated
\ by the length field).


: (fcode-version) ( -- )
   bhere abort" Fcode-version# should be the first FCode command!"
   restore-header
   [ tokenizer ]
   fcode-vers on
   which-version off  \ init version flag to normal state
   #version1s    off  \ init version 1 code counter
   #version1+2s  off  \ init version 1 and 2 code counter
   #version2s    off  \ init version 2 code counter
   #version2.1s  off  \ init version 2.1 code counter
   #version2.2s  off  \ init version 2.2 code counter
   #version2.3s  off  \ init version 2.3 code counter
   #version3s    off  \ init version 3 code counter
   #obsoletes    off  \ init obsolete  code counter
   checksum      off  \ Clear checksum bits set by version1
   pad-size
   ['] emit-fbyte is emit-byte
   [ tokens ]
;

: ((fcode-version ( offset16? sub-ver# -- )
   [ tokenizer ]
   emit-byte		\ sub-version (or violence?)
   fhere checksumloc !
   0 emit-word		\ Filler for later checksum field
   0 emit-long		\ Filler for later length field
   checksum  off	\ Needed again; we emited bytes we aren't counting.
   if
      [ tokens ]  offset16  [ tokenizer ]	\ compile offset16 Fcode
   then
   [ tokens ]
;

: Fcode-version1 ( -- )
   [ tokenizer ]
   fcode-vers @  if    .mult-fcode-vers-error
   else
      pre1275 on

   [ tokens ]
      (fcode-version)  version1 	\ (0xfd token)
   [ tokenizer ]
      offset-8?  @ 0=			\  Compile offset16 Fcode?
      3 				\ sub-version (2.2 with fixed checksum)
   [ tokens ]
      ((fcode-version
   [ tokenizer ]
   then
   [ tokens ]
;

:  Fcode-version2 ( -- )
   [ tokenizer ]
   fcode-vers @  if    .mult-fcode-vers-error
   else

      pre1275 on

      [ tokens ] (fcode-version)  start1  [ tokenizer ]
      offset-8?  off  false		\  Don't compile offset16 Fcode
      3 				\ sub-version (2.2 with fixed checksum)
   [ tokens ]
      ((fcode-version
   [ tokenizer ]
   then
   [ tokens ]
;

' start1 is fcode-start-code

:  Fcode-version3 ( -- )
   [ tokenizer ]
   fcode-vers @  if    .mult-fcode-vers-error
   else

      pre1275 off

      [ tokens ] (fcode-version)  fcode-start-code  [ tokenizer ]
      offset-8?  off  false		\  Don't compile offset16 Fcode
      8 				\ sub-version (3.  P1275-compliant).
   [ tokens ]
      ((fcode-version
   [ tokenizer ]
   then
   [ tokens ]
;

tokenizer definitions
\ Test for branch offsets greter than one byte
: test-span   ( delta -- )   \ Test if offset is too great
   d# -128 d# 127  between  0=  ( error? )  if
      .tokenization-error
     ." Branch interval of +-127 bytes exceeded." cr
     ." Use OFFSET16 or, better yet, use shorter dfns." cr
  then
;


\ Token control structure primitives
\ Number of bytes in a branch offset
: /branch-offset ( -- n )  1 offset-8? @ 0= if  1+  then  ;
variable Level

: +Level  ( -- )   1 Level +!  ;
: -Level  ( -- )  -1 Level +!  Level @ 0< abort" Bad conditional"  ;  \  XXX 

: >Mark    ( -- bhere fhere )
   bhere fhere   emit-dummy
   offset-8? @ 0= if emit-dummy then  \ Two bytes if offset-16 is true
;

: >Resolve ( oldb oldf -- )
   bhere  rot -  swap    ( delta oldf )
   offset-8? @ if
      over test-span patch-byte
   else
      patch-word
   then
;

: <Mark  ( -- bhere fhere )  bhere fhere  ;
: <Resolve ( oldb oldf -- )
   drop bhere  -   ( delta )
   offset-8? @ if
      dup  test-span emit-byte
   else
      emit-word
   then
;

\  Bypass the  abort"  built in to  ?pairs  and  ?csp
: catch-tok.error ( XT -- error? )
   catch dup if
      \  We want to print the error using our format,  (i.e., w/ leading  " Error: ")
      \      not the default.  To do that, we need to temporarily suppress the action
      \      of  show-error  and use our own instead...
      .tokenization-error
      ['] show-error behavior			( error# old-show-error )
      ['] noop is show-error  
      over .error
      ( old-show-error )  is show-error 	( error# )
   then
;
: tok?csp? ( -- error? )              ['] ?csp   catch-tok.error  ;
: tok?pairs? ( chk2 chk1 -- error? )
   ['] ?pairs catch-tok.error  dup if nip nip then
;

: but  ( b1 f1 t1 b2 f2 t2 -- b2 f2 t2 b1 f1 t1 )
   >r rot >r  2swap        ( b2 f2 b1 f1 )  ( r: t2 t1 )
   r> r> swap >r -rot r>   ( b2 f2 t2 b1 f1 t1 )
;
: +>Mark  ( -- bhere fhere )     +Level >Mark      ;
: +<Mark  ( -- bhere fhere 11 )  +Level <Mark  11  ;
: ->Resolve  ( oldb oldf chk2 chk1 -- )
   tok?pairs?   if  2drop  else  >Resolve -Level  then
;
: -<Resolve  ( oldb oldf chk -- )
  11 tok?pairs? if  2drop  else  <Resolve -Level  then
;

tokens definitions

also forth

\  Use this to "Roll Your Own"
: token: ( bytecode -- ) \ Name
   also tokens definitions
   create w,
   previous definitions
   does> w@ emit-word
;  valid-tick-target-word-type

previous

\ Take Forth/tokenizer commands only
: tokenizer[  ( -- )
\   ['] interpret-do-literal  is do-literal
   [ forth ]  ['] drop [ tokens ]  is do-literal
   only forth also tokenizer definitions
;

tokenizer definitions

\ Restore normal FCode behavior
: ]tokenizer  ( -- )
   ['] tokenize-literal is do-literal
   compiling @  if  tokens-only  else  init-path  then
;


tokens definitions
\  Token control structure words
\   !! Any word followed by ( T) is an executable token, *not* forth!

: ['] ( -- )  ?valid-tick-target  b(')  ;  valid-tick-target
: to ( -- )  b(to)  ;  valid-tick-target

: ahead  ( -- fhere 22 )  bbranch  ( T)  +>Mark h# 22  ;
: if     ( -- fhere 22 )  b?branch ( T)  +>Mark h# 22  ;

: then ( oldb oldf 22 -- )
   b(>resolve)  ( T)
   [ tokenizer ]  h# 22 ->Resolve  [ tokens ]
;

: else ( fhere1 22 -- fhere2 22 )
   ahead  [ tokenizer ]  but  [ tokens ]     ( fhere2 22 fhere1 22 )
   then ( T)             ( )
;

: begin  ( -- bhere fhere 11 )  b(<mark) ( T)   +<Mark  ;
: again  ( oldb 11 -- )  bbranch ( T)  -<Resolve  ;
: until  ( oldb 11 -- )  b?branch ( T) -<Resolve  ;
: while  ( bhere fhere 11 -- bhere2 fhere2 22  bhere fhere 11 )
   if ( T)
   [ tokenizer ] but ( whileb whilef 22 oldb 11 )  [ tokens ]
;

: repeat ( fhere 22 bhere 11 -- )  again ( T)  then ( T)  ;


: case ( -- 0 44 )
   +Level b(case) ( T) [ tokenizer ]  0  h# 44  [ tokens ]
;

: of ( 44 -- of-b of-f 55 )
   h# 44 tok?pairs?  [ also forth ] 0= if  [ previous ]
      b(of) ( T)  >Mark  h# 55
   [ also forth ] then  [ previous ]
;

: endof ( of-b of-f 55 -- endof-b endof-f 44 )
   b(endof) ( T)  >Mark h# 66		( of-b of-f endof-b endof-f )
   [ also tokenizer ]   but ( T)
    h# 55 tok?pairs?  [ forth ] 0= if
      [ tokenizer ]  >Resolve  h# 44
   [ forth ] then  [ previous ]
;

: endcase ( 0 [endof-address 66 ...] 44 -- )
   b(endcase) ( T)
   h# 44 tok?pairs?  [ also forth ] 0= if
      begin  h# 66 =  while
	 [ tokenizer ] >Resolve ( T) [ forth ]
      repeat
	 [ tokenizer ]  -Level ( T)
   [ forth ] then  [ previous ]
;


: do  ( -- >b >f 33 <b <f 11 )  b(do)  ( T)  +>Mark h# 33  +<Mark  ;
: ?do ( -- >b >f 33 <b <f 11 )  b(?do) ( T)  +>Mark h# 33  +<Mark  ;

: loop  ( >b >f 33 <b <f 11 -- )
   b(loop) ( T)  [ tokenizer ]  -<Resolve  h# 33 ->Resolve  [ tokens ]
;

: +loop  ( >b >f 33 <b <f 11 -- )
   b(+loop) ( T)  [ tokenizer ]  -<Resolve  h# 33 ->Resolve  [ tokens ]
;

: leave ( ??? -- ??? ) b(leave) ( T)  ;
: ?leave ( ??? -- ??? )  if ( T)  leave ( T)  then ( T)  ;


\  Add cross-compiler macros for common non-tokens
fload ${BP}/pkg/tokenizr/crosslis.fth


: hex ( -- )
   [ also forth ]
   compiling @  if  m-hex  else  hex  then
   [ previous ]
;
: decimal ( -- )
   [ also forth ]
   compiling @  if  m-decimal  else  decimal  then
   [ previous ]
;
: octal ( -- )
   [ also forth ]
   compiling @  if  m-octal  else  octal  then
   [ previous ]
;
: binary ( -- )
   [ also forth ]
   compiling @  if  m-binary  else  binary  then
   [ previous ]
;


\ String compiling words

\ (Implementation word, will not be supported)
hidden definitions
   : ",  ( adr len -- )  \ compile the string into byte-codes
      [ tokenizer ]
      dup emit-byte    ( adr len )
      bounds  ?do
	 i c@  emit-byte
      loop
      [ hidden ]
   ;

   \ (Implementation word, will not be supported)
   : ,"  \ name"  ( -- )
      [ tokenizer ]  get-string [ hidden ] ",
   ;

tokens definitions

: "  \ text"  ( -- )  \ Compiling ( -- adr len )  \ Executing
   b(") [ also hidden ]  ," [ previous ]
;

: s" \ text"  ( -- )  \ Compiling ( -- adr len )  \ Executing
   b(")
   [ tokenizer ]  ascii " parse  [ hidden ] ", [ tokens ]
;

: ."   ( -- )  \ text"
   "  type
;

: .( ( -- )  \  text)
   b(")  [ tokenizer ]  ascii ) parse [ hidden ] ", [ tokens ]  type
;

\  Offset16 support
: offset16  ( -- )   \ Intentional redefinition
   offset16          \ compile token
   offset-8? [ tokenizer ] off  \ Set flag for 16-bit branch offsets
	     [ tokens ]
;


\  New NAME shorthand form for "name" property
: name   ( adr len -- )
   encode-string  b(") [ tokenizer ] " name"
   [ hidden ]  ", [ tokens ]
   property
;

: ascii  \ name  ( -- n )
   [ tokenizer ]  safe-parse-word drop  c@ emit-number  [ tokens ]
;

: control  \ name  ( -- n )
   [ tokenizer ]  safe-parse-word drop  c@ h# 1f and  emit-number  [ tokens ]
;

: char  \ name  ( -- n )
   [ also forth ]
   compiling @  if
     .tokenization-error ." 'char' is not permitted inside FCode definitions"
   exit then
   [ previous ]
   ascii ( T)
;

: [char]  \ name  ( -- n )
   [ also forth ]
   compiling @  0= if
     .tokenization-error ." '[char]' is not permitted outside FCode definitions"
   exit then
   [ previous ]
   ascii ( T)
;

\  Three ways of creating a new token's name:
\      Make it an external name,
\      make it headered only if fcode-debug? is true,
\      or don't make its name at all.
\
also forth also hidden definitions
   : make-external-token ( $adr,len -- )
      external-token   ",
   ;
   : make-headerless-token ( $adr,len -- )
      2drop new-token
   ;
   : make-headered-token ( $adr,len -- )
      named-token      ",
   ;
previous previous definitions


tokenizer definitions

also forth also hidden

defer make-token-name   ['] make-headerless-token  to make-token-name

\  Create word for newly-defined 'local' tokens
: local:  \ name  ( -- )
   safe-parse-word  2dup $create  ( adr len )
   make-token-name
   here   next-lookup# @ c,
   local-escape @ c,  emit-local advance-lookup#
   1 #locals +!
   does>   emit-local
;  valid-tick-target-word-type

previous previous

: define-local: ( -- )  also tokens definitions  local:  previous  ;

\  End creation of new local token
: end-local-token  ( -- )

   compiling @ if
      compiling off
      init-path
      tok?csp?  if  exit   then
   else
      .tokenization-error ." ';' only allowed within definitions."
      exit
   then

   [ also tokens ]  reveal  b(;) [ previous ]
;

tokens definitions

: ;  ( -- )  \ New version of ; to end new-token definitions
   end-local-token
;


tokenizer definitions
\ Create new local tokens
: start-local-token  \ name ( -- )
   bhere set-lookup-pointer define-local:
   tokens-only  	\ Restrict search within localword to tokens
;

variable crash-site
: emit-crash  ( -- )
   bhere crash-site ! [ also tokens ]  crash  unnest  [ previous ]
;

\  The user may over-ride  headerless  directives in the source by
\      turning on the variable  force-headers?  or  force-external? 
\      before running the  tokenize  command.  (This is most commonly
\      done on the comand-line.)  Similarly, the user may over-ride
\       headers  directives by turning on  force-headerless? 
\      
\  In case of conflict, i.e., if more than one of these variables
\      are turned on,   force-external?  over-rides  force-headers?  
\      and  force-headers?  over-rides  force-headerless?
\ 
\  Don't ever over-ride or down-grade the  external  directive!
\ 
: set-make-token-name ( ACF -- )
   [ also hidden ] 
   force-headerless?  @ if  drop  ['] make-headerless-token  then
   force-headers?     @ if  drop  ['] make-headered-token  then
   force-external?    @ if  drop  ['] make-external-token  then
   [ previous ]
   to make-token-name
;

only forth also tokenizer also reforth definitions
also hidden
: headers     ( -- )   ['] make-headered-token    set-make-token-name ;
: headerless  ( -- )   ['] make-headerless-token  set-make-token-name ;
: external    ( -- )   ['] make-external-token  to make-token-name ;
previous

alias fload      fload
alias id:        id:
alias purpose:   purpose:
alias copyright: copyright:

: defer  \ name  ( -- )  \ Compiling
   #defers inc
   crash-site @  set-lookup-pointer  \ Deferred token points to 'crash'
   define-local:  [ also tokens ]  b(defer)  [ previous ]
;

: constant  \ name  ( -- )  \ Compiling  ( -- n )  \ Executing
   start-local-token  ( n ) #constants inc
   [ also tokens ]  b(constant)  [ previous ]
   \ advance-lookup#
   init-path
;

: value  \ name  ( -- )  \ Compiling ( -- n )  \ Executing
   start-local-token  ( n )  #values inc
   [ also tokens ]  b(value)  [ previous ]
   \ advance-lookup#
   init-path
;

: variable  \ name  ( -- )  \ Compiling ( -- adr )  \ Executing
   start-local-token #variables inc
   [ also tokens ]  b(variable)  [ previous ]
   \ advance-lookup#
   init-path
;

alias lvariable variable
alias alias   alias

\  Override certain Forth words in interpret state

\ We only allow 'create' in interpret state, for creating data tables
\   using c, w, etc.
: create  \ name  ( -- )  \ This 'create' for interpreting only
   start-local-token
   [ also tokens ]  b(create)  [ previous ]
   init-path
;

: buffer:  \ name  ( -- )  \ Tokenizing ( -- buff-adr )  \ Executing
   start-local-token #buffers inc
   [ also tokens ]  b(buffer:)  [ previous ]
   init-path
;

\  Although ' is only allowed in interpret state, we can still make it a
\      valid target of itself because it results in the same thing as  ['] 
: ' ( -- )  \ name
   ?valid-tick-target
   [ also tokens ]  b(')  [ previous ]
;  valid-tick-target
: colon-cf ( -- )
   [ also tokens ]  b(:)  [ previous ]
;

: dict-msg ( -- )  ." Dictionary storage is restricted. "  where  ;
: allot ( #bytes -- ) ." ALLOT - "  dict-msg  ;


\  New STRUCT structure words
: struct ( -- )  [ also tokens ]  0  [ previous ]  ;

: field  \ name  ( -- )  \ Tokenizing ( struct-adr -- field-adr )  \ Executing
   start-local-token
   [ also tokens ]  b(field)  [ previous ]
   init-path
;

: vocab-msg  ." Vocabulary changing is not allowed. "  where  ;
\ : only      vocab-msg  ;  \ Escape below with 'only'
: also        vocab-msg  ;
: previous    vocab-msg  ;
: except      vocab-msg  ;
: seal        vocab-msg  ;
: definitions vocab-msg  ;
: forth       vocab-msg  ;
: root        vocab-msg  ;
: hidden      vocab-msg  ;
: assembler   vocab-msg  ;


\  Save dangerous defining words for last
: :  \ name  ( -- )  \ New version of : to create new tokens
   !csp              \ save stack so ";" can check it
   start-local-token  colon-cf
   hide  compiling on
;


only forth also tokenizer also definitions
\  Initialize prior to executing  tokenize 
   \
   \     Support routines:  We want to be able to clear the dictionary
   \     after we're done so that we can do multiple invocations of
   \      tokenize  from within a single invocation of the tokenizer.
   \
   create tkz-marker-cmnd ," marker tkz-barrier"
   : set-tkz-marker ( -- )  tkz-marker-cmnd count eval ;
   : clear-tkz-marker ( -- ) tkz-marker-cmnd count 7 /string eval ;

: init-vars  ( -- )
   #literals     off
   #apps         off
   #locals       off
   #primitives   off

   #values       off
   #variables    off
   #constants    off
   #defers       off
   #buffers      off

   #end0s        off

   [ reforth ] headers [ tokenizer ]
   bytes-emitted off
   next-lookup#  off
   checksum      off
   Level         off
   compiling     off
   first-local-escape local-escape !
   next-lookup#  off
   fcode-vers    off

   tokenization-error off

   -1 checksumloc !
   set-tkz-marker
;

\  Cleanup after executing  tokenize 
: tkz-cleanup ( -- )
   clear-tkz-marker
;

: debug-interpret ( -- )
   begin
      ?stack parse-word dup
   while
      cr ." stack is: " .s
      cr ." word is: "  dup ".
      cr ." order is: " order
      cr $compile
   repeat
   2drop
;

\  Show final compilation statistics

\  Show one at a time:
: .statistic ( $adr,len vble-addr -- )
   @ ?dup if
       8 .r space 2dup type cr
   then  2drop
;

: .statistics ( -- )
   push-decimal

   " :Version 1   FCodes compiled (obsolete FCodes)"
   #version1s    .statistic

   " :Version 1   FCodes compiled"
   #version1+2s  .statistic

   " :Version 2.0 FCodes compiled (may require version 2 bootprom)"
   #version2s    .statistic

   " :Version 2.1 FCodes compiled (may require version 2.3 bootprom)"
   #version2.1s  .statistic

   " :Version 2.2 FCodes compiled (may require version 2.4 bootprom)"
   #version2.2s  .statistic

   " :Version 2.3 FCodes compiled (may require version 2.6 bootprom)"
   #version2.3s  .statistic

   " :Version 3   FCodes compiled (may require version 3 bootprom)"
   #version3s    .statistic

   " :Obsolete FCodes compiled (may not work on version 3 bootproms)"
   #obsoletes   .statistic

   pop-base
;

tokens definitions 

also forth
: end0  ( -- )  \ Intentional redefinition
   end0   silent @ 0=  if
      cr ." END0 encountered."  cr
     tokenization-error @ 0= if  .statistics  then
   then
   compiling @ 0=  if  1 #end0s +!  else  #end0s off  then
;  valid-tick-target
previous

tokenizer definitions

: .stat ( $adr,len vble-addr -- )
   @  8 .r space type cr
;
: .stats ( -- )
   push-decimal
   " Literals " 	    #literals	.stat
   " Non-(lit) Primitives"  #primitives	.stat
   " Application Codes"     #apps	.stat
   " Local Codes Created"   #locals	.stat
   " Variables" 	    #variables	.stat
   " Values"		    #values	.stat
   " Constants" 	    #constants	.stat
   " Buffer:s"		    #buffers	.stat
   " Defers"		    #defers	.stat
   pop-base
;

: write-header  ( -- )  header  d# 32  ofd @ fputs  ; \ don't affect checksum

: full-size  ( -- size )  \ Entire file, except a.out header
   ofd @ ftell  aout-header? @  if  d# 32 -  then
;
: fcode-size  ( -- size )  \ fcode-versionx thru end0 ONLY
   bytes-emitted @
;

: fix-length   ( -- size )
   #end0s @ 0=  if
      silent @ 0=  if
         ??cr ." *** Warning: FCode token END0 is missing at the end of the file. ***" cr
      then
      0 emit-byte  \ END0
   then
   fcode-size  checksumloc @ 2+  patch-long
;
: fix-checksum ( -- )
   checksum @  checksum off
   lwsplit + lwsplit +
   h# ffff and  checksumloc @  patch-word
;
: fix-header ( -- )
   aout-header? @  if  full-size 4 patch-long  then
;

create symtab  4 , 5 c, 0 c, 0 w, 0 , 0 w, 0 c,
d# 15 constant /symtab

: Fcode-version1 ( -- )
   [ tokens ] Fcode-version1 [ tokenizer ]
;
: Fcode-version2 ( -- )
   [ tokens ] Fcode-version2 [ tokenizer ]
;
: Fcode-version3 ( -- )
   [ tokens ] Fcode-version3 [ tokenizer ]
;

\ a.out(5) symbol buffer
128 buffer: label-string

variable append-label?    append-label? off


: fix-symtab ( -- )
   append-label? @  if
      h# 0c h# 10 patch-long
      symtab /symtab ofd @ fputs              (  )
      bl word label-string "copy              (  )
      label-string dup c@ dup >r              ( adr len )
      1+ 4 + swap c!                          (  )
      label-string r> 2+ ofd @ fputs   (  )
   then
;

: .fcode-vers-sb-first ( -- )
   true abort" Fcode-version# should be the first FCode command!"
;

only forth also tokenizer also forth definitions

0 value pci-prom?

: patch-pci-byte ( byte offset -- )
   aout-header? @  if  d# 32 +  then
   fhere  >r                       \ Save current file pointer
   ofd @  fseek                    \ Move back to 'addr' location
   .byte
   r>  ofd @  fseek                \ Restore current file pointer
;
: patch-pci-word-le ( w offset -- )
   >r wbsplit swap r@ patch-pci-byte
   r> ca1+ patch-pci-byte
;
: set-pci-fcode-size ( -- )
   fcode-size h# 200 round-up h# 200 /  ( size%512 )
   h# 2c  patch-pci-word-le
;

: pci-code-revision ( w -- )
   pci-prom? 0=  if  drop  exit  then
   lwsplit  if
      ." PCI Code Revision value too large. Must be a 2-byte value, "
      ." truncating to h#" dup .x cr
   then
   h# 2e patch-pci-word-le
;
: pci-vpd-offset    ( w -- )
   pci-prom? 0=  if  drop  exit  then
   lwsplit  if
      ." PCI VPD Offset value too large. Must be a 2-byte value, "
      ." truncating to h#" dup .x cr
   then
   h# 24 patch-pci-word-le
;

d# 100 buffer: output-name-buf

\ Remove the filename extension if there is one in the last pathname component
: ?shorten-name  ( input-file$ -- file$ )
   2dup                    ( adr len  adr len )
   begin  dup  while       ( adr len  adr len' )
      1-  2dup + c@  case  ( adr len  adr len' )
         \ Stop if we encounter "/" or "\" before a "."
         ascii /  of        2drop exit  endof
         ascii \  of        2drop exit  endof
         ascii .  of  2swap 2drop exit  endof
      endcase
   repeat                  ( adr len  adr len' )
   2drop
;
: synthesize-name  ( input-file$ -- input-file$ output-file$ )
   0 output-name-buf c!
   2dup ?shorten-name  output-name-buf $cat
   " .fc" output-name-buf $cat
   output-name-buf count
;

: ?arg ( $len tokenizer? -- )
    swap 0=  if
      ." Usage: "
      dup 0= if  ." de"  then
      ." tokenize input-filename"
      if  ."  [ output-filename ]"  then
      cr abort
   then  drop
;

: check-args  ( input-file$ output-file$ -- )
   2 pick  true ?arg
   dup  0=  if  2drop synthesize-name  then
;

128 buffer: string3
: save$3  ( adr len -- pstr )  string3 pack  ;

: .not-generated ( -- )
   string3 _delete drop
   cr ."    Output file not generated"
   cr cr
;

\  Generate common text for Tokenizer and De-Tokenizer Version display.

string-array tkz-version-string
   ,"  Version 3.3"
   ," Copyright 1996-2006 Sun Microsystems, Inc.  All Rights Reserved"
   ," Use is subject to license terms."
end-string-array

: .inp-fil ( $adr,len -- )
   ." Input file: " type
;

: .outp-fil ( $adr,len -- )
   ."     Output file: " type
;


: .tokenizer-version ( inp-flnm$ outp-flnm$ -- inp-flnm$ outp-flnm$ )
   ." FCode Tokenizer"
   ['] tkz-version-string /string-array
   0 do  i tkz-version-string ". cr loop
   cr
   2over .inp-fil
   2dup  .outp-fil  cr
;

: .detokenizer-version ( -- )  \  <input-filename> (but does not consume it.)
   >in @ >r
      parse-word				( inp-flnm$ )
   r> >in !
   dup false ?arg
   ." \  FCode Detokenizer"   0 tkz-version-string ". cr
   ['] tkz-version-string /string-array
   1 do ." \  " i tkz-version-string ". cr loop
   cr
   ." \  "  .inp-fil  cr
;

: tokenizer-order
   only forth also tokenizer also forth definitions
;

\  The real nitty-gritty work of the tokenizer.
\  In order to get messages for all our errors,
\      we need a substitute for  $do-undefined
\  Of course, we'll put it back when we're done...

: $tok-interpret-do-undefined
   tokenization-error on
   .not-found
;

: (tokenize) ( input-filename$adr,len -- error? )
   [']   $do-undefined   behavior  >r
   ['] $tok-interpret-do-undefined
      to $do-undefined

   init-path

   ['] included catch			(  n1 n2 error# | false )

   restore-path

   r> to $do-undefined
   ?dup  if   .error  2drop true 
   else  tokenization-error @
   then					( error? )

;

: $tokenize  ( input-filename$ output-filename$ -- )

   check-args

   tokenizer-order

   init-vars
   \  warning on

[ifexist] xref-on
   xref-init if 2swap xref-push-file  2swap  xref-on  then
[then]
   \ Define the TOKENIZER? symbol so code can check against it.
   0 0 " TOKENIZER?" [set-symbol]

   ['] .fcode-vers-sb-first is header
   ['] .fcode-vers-sb-first is do-literal
   silent @ if  warning off
   else
      .tokenizer-version
   then

   save$3 new-file                             ( input$ )
   aout-header? @  if  write-header  then      ( input$ )

   \ Save the current stack depth
   \    (now counting  input$ ; later counting  error?  and the old depth)
   depth >r

   (tokenize)					( error? )

   \ Compare the current SP against the previous one
   r> depth <>
   dup    if  ." Error: Stack depth changed"  cr
   then  or					( error?' )

   #version1s @
   dup    if
      cr ." Fatal error:  Obsolete version 1 tokens used"
   then  or					( error?'' )

   silent @ 0=  if  cr  then
						( error?'' )
   if
      string3 _delete drop
      cr ."    Output file not generated"
      cr cr
      exit
   then

   pad-size
   fix-checksum
   fix-length
   pci-prom?  if  set-pci-fcode-size  false to pci-prom?  then
   fix-header         \ !!! fix header last so checksum is correct.

   fix-symtab

   ofd @ fclose

[ifexist] xref-off
   xref-off
[then]

   tkz-cleanup

;

: tokenize ( -- )  \ input-filename  output-filename
   parse-word parse-word $tokenize
;

only forth also tokenizer also forth definitions

\ Make the following variables available in vocabulary forth
alias silent          silent
alias silent?         silent
alias pre1275         pre1275
alias append-label?   append-label?
alias aout-header?    aout-header?
alias offset-8?       offset-8?

: pci-header  ( vendor-id device-id class-code -- )     \ Generate ROM header

   pci-prom?  if
      ." Only one PCI Header is allowed"
      3drop exit
   then

   true to pci-prom?
   \ The device-id and vendor-id should be 2-byte (word) values.
   \ The class-code is a 3-byte value. This method will check that
   \ the values passed in are not too big, but will not report a
   \ problem if they are too small...

   false >r
                                ( vendor-id device-id class-code )
   dup h# ff00.0000 and 0<>  if ( vendor-id device-id class-code )
      ." Class-code value too large. Must be a 3-byte value!" cr
      r> drop true >r           ( vendor-id device-id class-code )
   then                         ( vendor-id device-id class-code )

                                ( vendor-id device-id class-code )
   over h# ffff.0000 and 0<>  if
      ." Device-id value too large. Must be a 2-byte value!" cr
      r> drop true >r           ( vendor-id device-id class-code )
   then

                                ( vendor-id device-id class-code )
   rot dup h# ffff.0000 and 0<>  if ( device-id class-code vendor-id )
      ." Vendor-id value too large. Must be a 2-byte value!" cr
      r> drop true >r               ( device-id class-code vendor-id )
   then                             ( device-id class-code vendor-id )

   r>  if  3drop exit  then         ( device-id class-code vendor-id )

   rot swap                         ( class-code device-id vendor-id )


   \ Preliminaries out of the way, now to build the header...

                                ( class-code device-id vendor-id )

   55 emit-byte aa emit-byte    ( class-code device-id vendor-id )      \ PCI magic number
   34 emit-byte 00 emit-byte    ( class-code device-id vendor-id )      \ Start of FCode

   14 0 do 0 emit-byte loop     ( class-code device-id vendor-id )

   1c emit-byte 00 emit-byte    ( class-code device-id vendor-id )
   00 emit-byte 00 emit-byte    ( class-code device-id vendor-id )      \ Start of PCI Data Structure:

   ascii P emit-byte            ( class-code device-id vendor-id )      \ PCIR string
   ascii C emit-byte            ( class-code device-id vendor-id )
   ascii I emit-byte            ( class-code device-id vendor-id )
   ascii R emit-byte            ( class-code device-id vendor-id )

   \ Now we consume the vendor-id
   wbsplit swap                 ( class-code device-id vend-hi vend-lo )
   emit-byte emit-byte          ( class-code device-id )

   \ Now we consume the device-id
   wbsplit swap                 ( class-code dev-hi dev-lo )
   emit-byte emit-byte          ( class-code )

   00 emit-byte 00 emit-byte    ( class-code )                  \ 2 VPD
   18 emit-byte 00 emit-byte    ( class-code )                  \ 2 DS len
   00 emit-byte                 ( class-code )                  \ 1 rev

   \ Now we consume the class-code
   lwsplit swap                 ( class-up class-lo )
   wbsplit swap                 ( class-up class-lohi class-lolo )
   emit-byte emit-byte          ( class-up )
   wbsplit swap                 ( class-uphi class-uplo )
   emit-byte drop               ( )

   \ Now finish off the header
   10 emit-byte 00 emit-byte    ( )	\ 2 image len XXX - We can't know this yet
   01 emit-byte 00 emit-byte    ( )	\ 2 rev of code
   01 emit-byte                 ( )	\ 1 code type
   80 emit-byte                 ( )	\ 1 indicator
   00 emit-byte 00 emit-byte    ( )	\ 2 reserved
;

only forth definitions

fload ${BP}/pkg/fcode/detokeni.fth	\ Detokenizer
only forth definitions
"   No new words defined yet." $create

warning on	\  Set the default state before saving forth image.
