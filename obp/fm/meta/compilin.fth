id: @(#)compilin.fth 3.15 03/12/08 13:22:30
purpose: 
copyright: Copyright 1994-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1985-1994 Bradley Forthware, Inc.
copyright: Use is subject to license terms.

forth definitions

vocabulary transition

meta definitions

h# 80 constant metacompiling

\ Non-immediate version which is compiled inside several
\ meta and transition words
: literal-t  ( n -- )  n->l-t compile-t (lit) ,-t  ;

\ vocabularies:
\ transition
\ symbols  \ entries are does> words
\ labels   \ entries are constants
\ meta
\
\ Compiling:  order:  transition symbols labels
\   If found in transition, execute it
\   If found in symbols, execute it
\      If is immediate, complain (should have been in transition)
\   If not found, addlink
\
\ Interpreting: meta
\
: metacompile-do-literal  ( n -- )
   state @  metacompiling =  if
[ifndef] oldhack
      2 =  if  where ." oops double number "  cr  source type  cr  drop  then
[then]
      literal-t
   else
      (do-literal)
   then
;

: metacompile-do-defined  ( acf -1 | acf 1 -- )
   drop execute
;
: $metacompile-do-undefined  ( adr len -- ) \ compile a forward reference
   $compile-t
;

\ XXX need to include labels in the search path when interpreting

\ XXX switch search order when going from metacompiling to interpreting
\ and back.
\ 3 states:
\ interpreting is just the normal interpret state, with labels in the search
\ path
\ compiling is just the normal compile state, with labels in the search path
\ metacompiling is the special state.

: meta-base  ( -- )  only forth also labels also meta also   ;
: meta-compile  ( -- )  meta-base definitions  ;
: meta-assemble  ( -- )  meta-base assembler  ;
: extend-meta-assembler  ( -- )  meta-assemble also definitions  ;
: meta-asm[  ( -- )  also meta assembler  ; immediate
: ]meta-asm  ( -- )  previous  ; immediate

variable doestarget

\ "resolves" gives a name to the run-time clause specified by the most-
\ recently-defined "does>" or ";code" word.  A number of defining words
\ assume that their appropriate run-time clause will be resolved with a
\ particular word.  For instance, "vocabulary" refers to a run-time clause
\ called <vocabulary>.  When the run-time code for vocabularies is defined
\ in the kernel source, "resolves" is used to associate its address with
\ the name <vocabulary>.  See the kernel source for examples.

: resolves \ name ( -- )
   doestarget @   safe-parse-word $findsymbol  resolution!
;

\ This is a smart equ which defines words that can be later used
\ inside colon definitions, in which case they will compile their
\ value as a literal.  Perhaps these should be created in the
\ labels vocabulary.

: $equ  ( value adr len -- )
   [ forth ] ['] labels $vcreate , immediate
   does>  \ ( -- value )  or  ( -- )
   @
   [ meta ] state @ metacompiling = if literal-t then
;
: equ  \ name  ( value -- )
   safe-parse-word $equ
;

\ Tools for building control constructs.  The details of the branch
\ target (offset or absolute, # of bytes, etc) are hidden in
\ /branch branch, and branch!  which are defined earlier.

: >mark    ( -- addr ) here-t here-t branch, ;
: >resolve ( addr -- ) here-t branch! ;
: <mark    ( -- addr ) here-t ;
: <resolve ( addr -- ) branch, ;
: ?comp    ( -- ) state @ metacompiling <> abort" compile only" ;

\   "Transition" words.  Versions of compiling words which are defined
\ in the host environment but which compile code into the target
\ environment.
\   Once compiling words are redefined, care must be taken to select
\ the old instance of that word for use in other definitions.  For instance,
\ when "if" is redefined, subsequent definitions will frequently want to use
\ the old "if", so the search order must be explicitly controlled in order
\ to access the old one instead of the new one.

: target  ( -- )  only forth also transition  ; immediate

transition definitions

\ Set the search path to exclude the transition vocabulary so that
\ we can define transition words but still use the normal versions
\ of compiling words like  if  and  [compile]
: host    ( -- )  only forth also meta        ; immediate

\ Transition version of control constructs.

: of      ( [ addresses ] 4 -- 5 )
   host  ?comp  4 ?pairs  compile-t (of)    >mark  5  target
; immediate

: case    ( -- 4 )  host  ?comp  csp @ !csp  4  target  ; immediate
: endof   ( [ addresses ] 5 -- [ one more address ] 4 )
   host  5 ?pairs  compile-t  (endof)   >mark  swap  >resolve  4  target
; immediate
: endcase ( [ addresses ] 4 -- )
   host  4 ?pairs  compile-t (endcase)
   begin  sp@ csp @ <>  while  >resolve  repeat
   csp !
   target
; immediate

: if      host   ?comp  compile-t ?branch >mark        target  ; immediate
: ahead   host   ?comp  compile-t  branch >mark        target  ; immediate
: else    host   ?comp  compile-t  branch >mark
                 swap  >resolve                        target  ; immediate
: then    host   ?comp >resolve                        target  ; immediate

: begin   host   ?comp  <mark                          target  ; immediate
: until   host   ?comp  compile-t ?branch <resolve     target  ; immediate
: while   host   ?comp  compile-t ?branch >mark  swap  target  ; immediate
: again   host   ?comp  compile-t  branch <resolve     target  ; immediate

: repeat  host   ?comp  compile-t branch <resolve >resolve  target  ; immediate

: ?do     host   ?comp  compile-t (?do)    >mark  target  ; immediate
: do      host   ?comp  compile-t (do)     >mark  target  ; immediate
: leave   host   ?comp  compile-t (leave)         target  ; immediate
: ?leave  host   ?comp  compile-t (?leave)        target  ; immediate
: loop    host   ?comp  compile-t (loop)
          dup /branch +  <resolve >resolve        target  ; immediate
: +loop   host   ?comp  compile-t (+loop)
          dup /branch +  <resolve >resolve        target  ; immediate

\ Transition version of words which compile numeric literals
: literal ( n -- )
   host  literal-t  target
; immediate

: ascii  \ string  ( -- char )
   host  bl word 1+ c@ state @  if  literal-t  then  target
; immediate

: control  \ string ( -- char )
   host  bl word 1+ c@ bl 1- and state @  if  literal-t  then  target
; immediate

: [char]  \ string  ( -- char )
   host  bl word 1+ c@ literal-t  target
; immediate

: th  \ string  ( -- n )
   host  base @ >r hex
   parse-word  $handle-literal?  0=  if
      ." Bogus number after th" cr
   then
   r> base !  target
; immediate

: td  \ string  ( -- n )
   host  base @ >r decimal
   parse-word  $handle-literal?  0=  if
      ." Bogus number after td" cr
   then
   r> base !  target
; immediate
alias h# th
alias d# td

\ From now on we start to see familiar words with "-h" suffixes.  These
\ are aliases for the familiar word, used because we have redefined the
\ word to operate in the target environment, but we still need to use the
\ original word.  Rather that having to do [ forth ] foo [ meta ] all the
\ time, we make an alias foo-h for foo.

forth definitions

alias '-h      '
alias [']-h   [']
alias :-h     :
alias ;-h     ;
alias ]-h     ]
alias forth-h forth
alias immediate-h immediate
alias is-h    is

\ Transition versions of tick and bracket-tick.  Forward references
\ are not permitted with tick because there is no way to know how
\ the address will be used.  The mechanism for eventually resolving
\ forward references depends on the assumption that the forward
\ reference resolves to a compilation address that is compiled into
\ a definition.  This assumption doesn't hold for tick'ed words, so
\ we don't allow them to be forward references.

meta definitions
: ' ( -- acf )
   safe-parse-word
   2dup $sfind  if  ( adr len acf )  \ The word has already been seen
       dup resolved?  ( adr len acf flag )
       if   nip  nip  resolution@  ( resolution )  exit   then
       drop
   then               ( adr len adr len  |  adr len )
   type ."  hasn't been defined yet, so ' won't work" cr
   abort
;

: [']-t  \ name ( -- )
   compile-t (')    safe-parse-word  $compile-t
; immediate

: place-t  ( adr len to-t -- )
   2dup + 1+  0 swap c!-t        \ Put a null byte at the end
   2dup c!-t  1+ swap cmove-t
;

\ Emplace a string into the target dictionary
: ,"-t  \ string"  ( -- )  \ cram the string at here
   td 34 ( ascii " ) word count              ( adr len )
   here-t                                    ( adr len here )
   over 2+ note-string-t allot-t  talign-t   ( adr len here )
   place-t
;

transition definitions
: ."      host  compile-t (.")     ,"-t  target  ; immediate
: abort"  host  compile-t (abort") ,"-t  target  ; immediate
: "       host  compile-t (")      ,"-t  target  ; immediate
: p"      host  compile-t ("s)     ,"-t  target  ; immediate

\ Bogus 1024 constant b/buf

meta also assembler definitions
: end-code
   meta-compile
\   current @ context !
;
previous definitions

\ Some debugging words.  Allow the printing of the name of words as they
\ are defined.  threshhold is the number of words that must be defined
\ before any printing starts, and granularity is the interval between
\ words that are printed after the threshhold is crossed.  This is very
\ useful if the metacompiler crashes, because it helps you to locate
\ where the crash occurred.  If needed, start with threshhold = 0 and
\ granularity = 20, then set threshhold to whatever word was printed
\ before the crash and granularity to 1.

forth definitions
variable #words       0 #words !
variable threshold   10000 threshold !
variable granularity 10 granularity !
variable prev-depth  0 prev-depth ! ( expected depth )
: .debug ( -- )
   threshold @ -1 <>  if
      base @  decimal  #words @ 5 .r space  base !
      [ also meta ] .lastname [ previous ]
      depth 0 <> if  space .x  then  cr
   then
;
: ?debug ( -- )
   depth  prev-depth @ <>  if
      .debug  depth prev-depth !
   else
      #words @ threshold @ >=
      if  #words @ granularity @ mod
	 0= if  .debug  then
      then
   then
   1 #words +!
;

meta definitions

0 value  lastacf-t	\ acf of the most-recently-created target word

variable show?		\ True if we should show all the symbols
show? off


\ Header control:
\   The kernel can be compiled in 3 modes:
\      always-headers:      All words have headers  (default mode)
\      never-headers:       No words have headers
\      sometimes-headers:   Words have headers unless "headerless" is active

\ -1 : never   0 : always  1 : yes  2 : no

variable header-control   0 header-control !

: headerless  ( -- )  header-control @  0>  if  2 header-control !  then  ;
: headers     ( -- )  header-control @  0>  if  1 header-control !  then  ;

: always-headers     ( -- )   0 header-control !  ;
: sometimes-headers  ( -- )   1 header-control !  ;
: never-headers      ( -- )  -1 header-control !  ;

: make-header?  ( -- flag )  header-control @  0 1 between  ;



: initmeta  ( -- )  initmeta  0 is lastacf-t  ;

variable flags-t

\ Creates a header in the target image
: $really-header-t  ( str -- )
   \ Find the metacompiler's copy of the threads
   2dup current-t @  $hash-t                  ( str thread )

   -rot dup 1+ /link-t +                      ( thread str,len n )
   here-t + dup acf-aligned-t swap - allot-t  ( thread str,len )


   tuck here-t over 1+ note-string-t allot-t  ( thread len str,len adr )
   place-cstr-t  over + c!-t                  ( thread )

   here-t 1- dup c@-t h# 80 or swap c!-t
   here-t 1- flags-t !

   \ get the link to the top word           ( thread )
   dup link-t@                              ( thread top-word )

   \ link the existing list to the new word
   link,-t                                 ( thread )

   \ link the thread to the new word
   here-t swap link-t!


;
: showsym  ( str -- )
   base @ >r hex
   here-t 8 u.r  ( drop )  space type cr
   r> base !
;

: $meta-execute  ( pstr -- )
   ['] labels $vfind  if
      execute
   else
      ['] meta $vfind  if  execute  else   type  ." ?"  abort  then
   then
;

: $header-t  ( name$ cf$ -- )   \ Make a header in the target area
   2>r

   xref-header-hook				\ for Xreferencing
   2dup $create-s                            \ symbol table entry
   \ Make header unless headerless
   make-header?  if  2dup $really-header-t  then
   acf-align-t
   show? @  if  showsym  else  2drop  then

   here-t is lastacf-t	\ Remember where the code field starts

   here-t  lastacf-s @  resolution!    \ resolve it

   header-control @ 3 and  lastacf-s @ info!

   2r> $meta-execute
;

\  Construct the list of  "actions" that may be performed
\  when a given target-word is the target of "is"
\  Make these words state-smart so they can be used both
\  when the "is" is applied at meta-compile time and when it
\  is being compiled-in.  The meta-compiling-state part will
\  compile-in the appropriate run-time variant of "is".

\  Support function for noting misuses:
: don't-use-with-is ( $adr,len -- bufr )  \  Start off the message
   " Don't you know not to use IS with "  "temp pack	( $adr,len bufr )
   dup 2swap						( bufr bufr $adr,len )
   rot $cat						( bufr )
;
: don't-use-is-while-metacomp ( bufr -- )  \  Finish off the message.
   dup "  while metacompiling" rot $cat 		( bufr )
   count .not-found
;

: don't-use-interp-is ( $adr,len -- )   \  Interpret-time message
   don't-use-with-is
   don't-use-is-while-metacomp
;

\  The interpret-time variants
\  I would have liked to call these  is<whatever>-interp  but there are
\  a few of 'em scattered around for use in the defining process; I'll
\  just continue to call them  is<whatever>

: isuser ( n acf-t -- )      >user-t n-t!  ;
: istuser ( acf-t1 acf-t -- )  >user-t token-t!  ;
: isvalue ( n acf-t -- )     >user-t n-t!  ;
: isdefer ( acf-t1 acf-t -- )  >user-t token-t!  ;

\  We'll allow a constant to be changed at metacompile-time
: isconstant ( n acf-t -- )  >body-t !-t  ;

\ : iscreate ( acf-t -- addr )  >body-t  ;       \ This isn't used

\  In-dictionary variables are a leftover from the earliest FORTH
\  implementations.  They have no place in a ROMable target-system
\  and we are deprecating support for them; but Just In Case you
\  ever want to restore support for them, define the command-line
\  symbol:   in-dictionary-variables
[ifdef] in-dictionary-variables
   : isvariable ( n acf-t -- )  >body-t !-t  ;
[then]

: isvocabulary ( threads acf-t -- )
   >user-t  ( threads threadsaddr-t )
   #threads-t 0
   do
      over link-t@ over link-t!  ( threads threadsaddr-t )
      /link-t +   swap  /link-t +  swap
   loop
   2drop
;

\  The meta-compile-time variants

\  Support function for noting misuses:
: don't-use-meta-is ( $adr,len -- )   \  Meta-compile-time message
   don't-use-with-is				( bufr )
   dup "  inside a definition" rot $cat 	( bufr )
   don't-use-is-while-metacomp
;

: don't-use-is-at-all ( [ | n ] $adr,len -- )	\  Dispatch to proper message
   state @ metacompiling = if			( $adr,len )
      don't-use-meta-is 		\  Dispatch to meta-compile-time message
   else 					( acf-t1 $adr,len )
      rot drop don't-use-interp-is	\  Dispatch to interpret-time message
   then
;

: isvocabulary-meta ( acf-s -- )
    drop " a VOCABULARY definition" don't-use-meta-is
;

: isvalue-meta  ( acf-s -- ) compile-t (is-user)  compile,-t ;

: isdefer-meta  ( acf-s -- ) compile-t (is-defer) compile,-t ;

: isuser-meta   ( acf-s -- ) compile-t (is-user)  compile,-t ;

: istuser-meta  ( acf-s -- ) compile-t (is-defer) compile,-t ;

[ifdef] in-dictionary-variables
   : isvariable-meta ( acf -- ) compile-t (is-const) ;
[then]

\  The actual is<whatever>-action words.
: isvalue-action ( [ | n ] acf-s acf-t -- )
   state @ metacompiling = if		( acf-s acf-t )
      drop isvalue-meta
   else 				( n acf-s acf-t )
      nip isvalue
   then
;

: isdefer-action ( [ | acf-t1 ] acf-s acf-t -- )
   state @ metacompiling = if		( acf-s acf-t )
      drop isdefer-meta
   else 				( acf-t1 acf-s acf-t )
      nip isdefer
   then
;

: isuser-action ( [ | n ] acf-s acf-t -- )
   state @ metacompiling = if		( acf-s acf-t )
      drop isuser-meta
   else 				( n acf-s acf-t )
      nip isuser
   then
;

: istuser-action ( acf1 acf -- )
   state @ metacompiling = if
      drop istuser-meta
   else 				( acf1 acf)
      nip istuser
   then
;

: isconstant-action ( [ | n ] acf-s acf-t -- n )
   state @ metacompiling = if		( acf-s acf-t )
      2drop " a CONSTANT" don't-use-meta-is
   else 				( n acf-s acf-t )
      nip isconstant
   then
;
: iscreate-action ( [ | acf-t1 ] acf-s acf-t -- )	\  Don't do this!
   2drop " a CREATE definition"
   don't-use-is-at-all
;

[ifdef] in-dictionary-variables
   : isvariable-action ( n acf -- )
      state @ metacompiling = if
	 drop isvariable-meta
      else
	 nip isvariable
      then
   ;
[then]

: isvocabulary-action ( [ | threads ] acf-s acf-t -- )
   state @ metacompiling = if			( acf-s acf-t )
      drop isvocabulary-meta
   else 					( threads acf-s acf-t )
      nip isvocabulary
   then
;
: iscolon-action ( [ | acf-t1 ] acf-s acf-t -- )
   2drop " a Colon or Code definition"
   don't-use-is-at-all
;


\ Perform a create for the target system.  This includes making or
\ resolving a symbol table entry.  A partial code field may be generated.

: header-t  \ name  ( name-str -- )
   safe-parse-word 2swap $header-t
;

\ Automatic allocation of space in the user area
variable #user-t
/n constant #ualign-t
: ualigned-t ( n -- n' )  #ualign-t 1- + #ualign-t negate and  ;

: ualloc-t  ( n -- next-user-# )  \ allocate n bytes and leave a user number
   ( #bytes )  #user-t @  over #ualign-t >=  if
      ualigned-t dup #user-t !
   then  ( #bytes user# )

   swap #user-t +!
;

: constant  \ name  ( n -- )
   safe-parse-word  3dup $equ
   " constant-cf"  $header-t    s->l-t ,-t
   ['] isconstant-action setaction    ?debug
;

: create  \ name  ( -- )
   " create-cf" header-t
   ['] iscreate-action setaction    ?debug
;

[ifdef] in-dictionary-variables
   : variable  \ name  ( -- )
      " variable-cf" header-t   0 n->n-t ,-t
      ['] isvariable-action setaction    ?debug
   ;
[then]

\ isuser is in target.fth
\ X : isuser  ( n acf -- )  >user-t n-t!  ;
: user  \ name   ( user# -- )
   " user-cf" header-t          n->n-t ,user#-t
   ['] isuser-action    setaction    ?debug
;
: nuser  \ name  ( -- )
   /n-t ualloc-t user
;

\ istuser is in target.fth
\ X : istuser  ( acf1 acf -- )  >user-t token-t!  ;
: tuser  \ name  ( -- )
   /token-t ualloc-t user ['] istuser-action setaction
;

: isauser  ( adr acf -- )  >user-t a-t!  ;
: auser  \ name  ( -- )
   /a-t ualloc-t user ['] istuser-action setaction
;

\ isvalue  is in target.fth
\ X : isvalue  ( n acf -- )  >user-t n-t!  ;
: value  \ name  ( n -- )
   safe-parse-word  3dup $equ
   " value-cf" $header-t     /n-t ualloc-t  n->n-t  ,user#-t
   lastacf-t  isvalue
   ['] isvalue-action setaction    ?debug
;
\ : buffer:  \ name  ( size -- )
\    " buffer-cf" header-t
\    /n-t ualloc-t n->n-t ,user#-t	\ user#
\    n->n-t ,-t			\ size
\    here-t  buffer-link-t a-t@  a,-t  buffer-link-t ha-t!
\ ;
: code  \ name  ( -- )
   " code-cf" header-t       entercode  ?debug
;

: $label  ( name$ -- )
   show? @  if  2dup showsym  then
   also labels definitions
   ['] labels $vcreate  here-t ,  immediate-h
   previous definitions
   does> @
   state @  case
      metacompiling of            literal-t  endof
      true          of  [compile] literal    endof
   endcase
;
: label  \ name  ( -- )
   safe-parse-word  2dup  " label-cf" $header-t   entercode  ( name$ )
   $label
;

\ Creates a label that will only exist in the metacompiler;
\ When later executed, the label returns the target address where the
\ label was defined.  No changes are made to the target image as a result
\ of defining the label.

: mlabel  \ name  ( -- )  ( Later:  -- adr-t )
   safe-parse-word  align-t acf-align-t $label
;
: mloclabel  \ name  ( -- )  ( Later:  -- adr-t )
   safe-parse-word  $label
;

: code-field:  \ name  ( -- )
\   label
   mlabel  meta-assemble  entercode
;

\ This vocabulary allocates space for its threads in the user area
\ instead of in the dictionary.  It is therefore ROMable.  The existence
\ of the voc-link in the dictionary does not compromise this, since
\ the voc-link is only written once, when the vocabulary is created.
lvariable voc-link-t
: voc-link,-t  ( -- )
   lastacf-t  voc-link-t link-t@   a,-t
   voc-link-t  link-t!
;

: set-threads-t  ( name$ -- )
   " forth"  $=  if
      threads-t  lastacf-t  isvocabulary
   else
      lastacf-t >user-t  clear-threads-t
   then
;

: definitions-t  ( -- )  context-t @ >user-t current-t !  ;

\ If we make several metacompiled vocabularies, we need to initialize
\ the threads with link, to  make them relocatable
: vocabulary  \ name  ( -- )
   safe-parse-word  2dup   " vocabulary-cf" $header-t   ( name )
   \ The 1 extra thread is the "last" field
   #threads-t /link-t * ualloc-t			( name$ user# )
   n->n-t ,user#-t                                      ( name$ )
   voc-link,-t                                          ( name$ )
   2dup set-threads-t                                   ( name$ )
   ?debug                                               ( name$ )
   ['] isvocabulary-action setaction
   ['] meta $vcreate lastacf-t ,  does> @ context-t !
;
\ /defer-t  is the number of user area bytes to alloc for a deferred word

\ isdefer  is in target.fth
\ X : isdefer  ( acf acf -- )  >user-t token-t!  ;
: defer-t  \ name  ( -- )
   " defer-cf" header-t   /defer-t ualloc-t n->n-t ,user#-t
   ?debug
   ['] isdefer-action setaction
;

: compile-in-user-area  ( -- compilation-base here )
   compilation-base  here-t
   0 dp-t !  userarea-t is compilation-base  \ Select user area
;
: restore-dictionary  ( compilation-base here -- )
   dp-t !  is compilation-base
;

transition definitions
: does>     ( -- )
   host
   compile-t (does>)
   \ XXX the alignment should be done in startdoes; it is incorrect
   \ to assume that acf alignment is sufficient (code alignment might
   \ be stricter).
   align-t acf-align-t here-t doestarget !
   " startdoes" $meta-execute
   target
; immediate

: ;code     ( -- )
   host
   ?csp  compile-t (;code)   align-t  acf-align-t  here-t doestarget !
   " start;code" $meta-execute
   [compile] [  reveal-t  entercode
   target
;  immediate

: [compile]  \ name  ( -- )
   host  safe-parse-word  $compile-t  target
; immediate

meta definitions

\ Initialization of variables, defers, vocabularies, etc.
\ Because this word is immediate, it can be used in the
\ interpretive state as well as inside target-compiled
\ colon definitions.
\ The secret is that the "action" words set (via  setaction )
\ for each defining-type are themselves state-smart, and will
\ Do The Right Thing in either state.
: is  \ word  ( ? -- )
   safe-parse-word  $sfind  if		( acf-s )
      dup resolution@			( acf-s acf-t )
      over do-action			(  )
   else
      .not-found
   then
;  immediate

alias is-t is immediate

only forth also meta also definitions

: metacompile-do-undefined  ( pstr -- ) \ compile a forward reference
   count $compile-t
;

: ]-t  ( -- )
   ['] metacompile-do-defined   is-h do-defined
[ifndef] oldhack
   ['] $metacompile-do-undefined is-h $do-undefined
[else]
   ['] metacompile-do-undefined is-h do-undefined
[then]
   ['] metacompile-do-literal   is-h do-literal
   metacompiling state !
   only forth labels also forth symbols also forth transition
;
: [-t  ( -- )
   [compile] [
   meta-base
; immediate
: ;-t  ( -- )
   ?comp  ?csp  compile-t unnest  reveal-t  [compile] [-t
; immediate

only forth also meta also definitions
: immediate  ( -- )
   flags-t @  th 40 toggle-t       \ fix target header
   immediate-s				\ fix symbol table
;

: :-t  \ name  ( -- )
   !csp  " colon-cf" header-t   hide-t  ]-t   ?debug
   ['] iscolon-action  setaction
;

\
\ These are meta compiler versions of the fm/lib/chains.fth file
\ the same rules apply just the implementation changes.
\
: (overload:-t) ( str,len chain? -- )
   -rot 2dup $sfind  if				( chain? str,len acf )
      resolved? if				( chain? str,len )
         2dup					( chain? str,len str,len )
      else					( chain? str,len )
         type ." must exist!" abort		( )
      then					( chain? str,len )
   else						( chain? str,len str,len )
      2drop 0 0					( chain? str,len str,len )
   then						( chain? str,len link,len )
   2swap					( chain? link,len str,len )
   show? @ 0= if  warning-t dup @ >r off then	( chain? link,len str,len )
   header-control @ >r				( chain? link,len str,len )
   r@ if  headerless  then			( chain? link,len str,len )
   " colon-cf" $header-t   hide-t  ]-t   ?debug	( chain? link,len )
   ['] iscolon-action  setaction		( chain? link,len )
   rot if					( link,len )
      ?dup if  $compile-t  else  drop  then	( )
   else						( )
      2drop					( )
   then						( )
   r> header-control !				( )
   show? @ 0= if  r> warning-t !  then		( )
;

: chain:-t \ name ( -- )
   !csp safe-parse-word			( str,len )
   true (overload:-t)			( )
;

: overload:-t \ name ( -- )
   !csp safe-parse-word			( str,len )
   false (overload:-t)			( )
;

\  Create functional equivalents of  [ifexist]  and  [ifnexist]
\  for use during metacompilation; these will search only the
\  target dictionary instead of the host dictionary.
\  If the word is found in the LABELS vocabulary, it "exists".
\  Otherwise, if it is found in the SYMBOLS vocabulary it
\  "exists" only if it is RESOLVED.
\  We look in the SYMBOLS vocabulary first because things are
\  more likely to be there.

: meta-defined? ( -- meta-defined? ) \ name
   safe-parse-word  $sfind  if
      resolved?
   else   ['] labels  $vfind nip ?dup nip
   then
;

: [ifnexist]-t ( -- ) \ name
    meta-defined? 0= postpone [if]
;
: [ifexist]-t ( -- ) \ name
    meta-defined? postpone [if]
;


\ Turn on the metacompiler by
\ changing the words used by the assembler to store into the dictionary.
\ They should store into the target dictionary instead of the host one.

only forth meta also forth also definitions

: metaon  ( -- )
   meta-compile
   install-target-assembler
   meta-xref-on
;
: metaoff  ( -- )
   forth definitions
   install-host-assembler
   meta-xref-off
;

meta assembler definitions
: 'body   \ name ( -- apf )
  [ meta ]
    '  ( acf-of-variable )
    >body-t
  [ assembler ]
;

meta definitions
alias [ifexist] [ifexist]-t
alias [ifnexist] [ifnexist]-t
alias :   :-t
alias chain: chain:-t
alias overload: overload:-t
alias ]   ]-t
alias /n  /n-t
alias /w  /w-t
alias /l  /l-t
alias /a  /a-t
alias #talign #talign-t
alias /token /token-t
alias /link  /link-t
alias ,   ,-t
alias l,  l,-t
alias w,  w,-t
alias c,  c,-t
alias defer  defer-t

alias 16\  16\
alias 32\  32\
alias 64\  64\
alias \itc \itc-t
alias \dtc \dtc-t
alias \t16 \t16-t
alias \t32 \t32-t

alias here   here-t
alias origin origin-t

transition definitions
alias [    [-t
alias ;    ;-t
alias is   is-t
alias [']  [']-t
alias 16\  16\
alias 32\  32\
alias 64\  64\
alias \itc \itc-t
alias \dtc \dtc-t
alias \t16 \t16-t
alias \t32 \t32-t
alias .(   .(
alias (    (
alias (s   (
alias \    \
alias [ifdef]  [ifdef]
alias [ifndef] [ifndef]
alias [if]     [if]
alias [else]   [else]
alias [then]   [then]
alias [defined] [defined]
alias [define] [define]
alias [undef] [undef]
alias [ifexist] [ifexist]-t
alias [ifnexist] [ifnexist]-t

only forth also meta assembler definitions
alias .(   .(
alias (    (
alias (s   (
alias \    \

only forth also definitions
