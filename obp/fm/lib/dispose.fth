\ dispose.fth 3.5 99/05/04
\ Copyright 1985-1990 Bradley Forthware

\ Transient vocabulary disposal
\
\ This file (and also headless.fth) may be compiled within 'transient'
\ in order to save space.  If this is done, however, only ONE 'dispose'
\ is possible.
\
\ Multiple 'start-module' - 'end-module' cycles are still allowed.
\ Nested modules are allowed.
\
\ dispose   ( -- )	Throw away the transient dictionary and
\	reclaim its space.  Names are saved in the 'headers' file.
\
\ start-module  ( -- )	Mark the start of a module.
\
\ end-module  ( -- )	The end of a module.  The heads of all
\	headerless words within the module are immediately tossed.

decimal

\ File output primitives
variable header:?   \ If true, output 'header:' else output 'headerless:'
: ftype  ( adr len -- )  ofd @ fputs  ;
: f.acf  ( anf acf  -- )
   " h# " ftype
   origin-  (.)   ( adr len )
   5 over - 0 ?do  ascii 0 ofd @ fputc loop  ( adr len )
   ftype
   header:? @  if  "  header: "  else  "  headerless: "  then
   ftype
;
\ : fspace  ( -- )  bl  ofd @ fputc  ;
: fcr  ( -- )  linefeed ofd @ fputc  ;

: open-headerfile  ( -- )  " headers" $append-open  ;
: close-headerfile ( -- )  fcr fcr ofd @ fclose  ;

: alias?  ( anf -- alias? )  n>flags c@  32 and  ;
: new-name>  ( anf -- acf )     \ Handles alias properly
   dup name>  swap   ( acf anf )
   alias?  if  token@  then
;

: f.immediate ( anf -- )  n>flags c@  64 and  if  "  immediate" ftype  then  ;

: f.name  ( anf acf -- )  fcr  f.acf  dup name>string ftype f.immediate  ;

: word.  ( alf -- )
   l>name      ( anf )
   dup alias?  if  dup new-name> f.name  else  drop  then
;
: ..name  ( acf -- )  \ Print acf and name
   dup >name swap  f.name
;

: buffer:.  ( acf -- )  \ buffer: pfa = user#, size, link-to-prev-buffer:
   ..name  "  ( buffer: )" ftype
;

: vocab.  ( voclink -- )  \ vocab pfa = user#, link-to-prev-vocab
   ..name   "  ( vocabulary )" ftype
;
defer link.  ( link -- )  \ Different links are printed differently

\ variable tosscount
variable showit?   showit? on
: showit  ( alf -- )
   showit? @ if
      link.
\       1 tosscount +!
\       #out @ 65 >  if  cr  2 spaces  then
   else
      drop
   then
;


defer item@  ( this-item -- next-item )
defer item!  ( data-item addr-item -- )
\ ITEMS are alf's for word (thread searches)
\ ITEMS are links for buffer: and vocab
\ ITEMS are acf's for (cold

0 value resboundary   \ Lower boundary of region to dispose
0 value tranboundary
: relink  ( first-link -- )  \ Removes transients from any linked list
   begin       ( good-link )
      \ Skip over all consecutive words in the transient vocabulary
      dup
      begin   ( prev-item this-item )
         item@  dup tranboundary >=  ( prev-item next-item tran? )
         dup if  over showit  then
      0= until       ( prev-item next-kept-item )
      \ Link the next non-transient word to the previous non-transient one
      dup rot  item!           ( next-kept-item )
      dup resboundary <        ( next-kept-item <resboundary? )
      over transtart >=   ( next-kept-item <resboundary? safe-transient? )
      or
   until   drop
;

: relink-voc  ( voc-acf -- )  \ Follow and relink threads in this vocab.
   >threads  #threads /link *  bounds  do  i relink  /link +loop
;

: .word-link ( alf1 alf2 -- alf1 alf2 )  showit? @ if  ??cr ." WL " 2dup . . then  ;
: word-link@ ( alf -- alf' )  link@ >link  ;
: word-link! ( alf1 alf2 -- ) ( .word-link ) swap link> swap link!  ;
: do-word-link    ( -- )  ['] word-link@ is item@   ['] word-link! is item!  ;

: relink-words  ( -- )
   \ showit? @  if  cr ." Words: "  then
   ['] word.    is link.   do-word-link
   voc-link  begin  another-link?   while  dup voc> relink-voc >voc-link repeat
;

: .buffer-link ( a1 a2 -- a1 a2 )  showit? @  if  ??cr ." BL " 2dup . .  then  ;
: buf-link! ( link adr -- ) ( .buffer-link ) >buffer-link link!  ;
: buf-link@ ( adr -- link )  >buffer-link link@  ;
: do-buf-link ( -- )  ['] buf-link@ is item@   ['] buf-link! is item!  ;
: relink-buffer:s  ( -- )
   \ showit? @  if  cr ." Buffer:s "  then
   ['] buffer:. is link.   do-buf-link  buffer-link link@  relink
;

: .voc-link ( a1 a2 -- a1 a2 )  showit? @  if  ??cr ." VL " 2dup . .  then  ;
: voc-link! ( link adr -- )  ( .voc-link ) >voc-link link!  ;
: voc-link@ ( adr -- link )  >voc-link link@  ;
: do-voc-link ( -- )  ['] voc-link! is item! ['] voc-link@ is item@  ;
: relink-voc-list  ( -- )
   \ showit? @  if  cr ." Vocabularies: "  then
   ['] vocab.   is link.   do-voc-link   voc-link link@  relink
;

: (cold.  ( acf -- )  \ (cold pfa = prev-(cold-cfa, content-cfa, ...
\    ."  initialization word containing: "  >body  /token +  token@  ..name
\    dup ..name  "  ( containing: " ftype
\    >body  /token +  token@  ..name  "  )" ftype
   ..name
;
: cold@  ( acf -- next-acf )  >body token@  ;
: cold!  ( next-acf acf -- )  >body token!  ;

: relink-init-chain  ( str -- )  $find  if  relink  else  2drop  then  ;
: relink-init-chains  ( -- )
   \ cr ." Initialization chains: "
   ['] (cold. is link.   ['] cold@ is item@   ['] cold! is item!
   " init"              relink-init-chain
\  " unix-init"         relink-init-chain
\  " unix-init-io"      relink-init-chain
\  " stand-init"        relink-init-chain
\  " stand-init-io"     relink-init-chain
   " (cold-hook"        relink-init-chain
;

defer relink-hook  ' noop is relink-hook

: unlink-all  ( resboundary tranboundary -- )
   is tranboundary   is resboundary
   header:? off      \ Dump using 'headerless:', not 'header:'
   resident    \ Just to be sure

   base @ >r hex
   open-headerfile
   relink-buffer:s
   relink-voc-list
   relink-init-chains
   relink-words
   relink-hook
   close-headerfile
   r> base !
   tranboundary is there
;

: dispose  ( -- )  \ Dispose transient, and save names of words tossed
\  showit? @  if  ." DISPOSING ..."  then
\    tosscount off
\ Lower res. bound is start of 'transien.fth' package
   ['] there transtart unlink-all
\    cr ." Number of headers disposed: " tosscount @ .
\    cr ." Transient start: " transtart .
\    cr ." Transient end:   " there .
\    cr
;

hex fe1f constant magic#
decimal

: start-module  ( -- here there magic# )
   here there magic#
;

: end-module  ( oldhere oldthere magic# -- )
   base @ >r decimal
   magic# <> abort" illegal stack for end-module"

   ( oldhere oldthere )

   \ ." here=" here .  ." there=" there . cr
   \ ." transtart=" transtart . ." transize=" transize . cr
   \ ." oldhere=" over .  ." oldthere=" dup .  cr

   ( oldhere oldthere ) unlink-all

   \ ??cr ." here=" here .  ." there=" there . cr
   \ ." transtart=" transtart . ." transize=" transize . cr
   \ ??cr ." EM " .s cr

   r> base !
;

"" headers _delete  drop
: start-module ;
: end-module ;
