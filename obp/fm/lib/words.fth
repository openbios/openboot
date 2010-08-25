\ words.fth 2.9 02/11/26
\ Copyright 1985-1990 Bradley Forthware
\ Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

\ Display the WORDS in the Context Vocabulary

decimal

only forth also definitions

: over-vocabulary  (s acf-of-word-to-execute voc-acf -- )
   follow  begin  another?  while   ( acf anf )
      n>link over execute           ( acf )
   repeat  ( acf )  drop
;
: +words   (s -- )
   0 lmargin !  d# 64 rmargin !  d# 14 tabstops !
   ??cr
   begin  another?  while      ( anf )
     dup name>string nip .tab  ( anf )
     .id                       ( )
     exit? if  exit  then      ( )
   repeat                      ( )
;
: follow-to  (s adr voc-acf -- error? )
   follow  begin  another?  while         ( adr anf )
      over u<  if  drop false exit  then  ( adr )
   repeat                                 ( adr )
   drop true
;
: prior-words  (s adr -- )
   context token@ follow-to  if
      ." There are no words prior to this address." cr
   else
      +words
   then
;

\ [ifdef] Daktari
\ [message] XXX (words) and voc-words for Daktari
: (words)  ( lmarg rmarg tabs -- )
   tabstops !				\ Set tab/column width
   rmargin !				\ Set right-hand margin
   lmargin !				\ Set left-hand margin
   ??cr
   0  context token@			( 0 voc-acf )
   begin another-word?  while		( alf voc-acf anf )
     dup name>string nip .tab		( alf voc-acf anf )
     .id				( alf voc-acf )
     exit? if  2drop exit  then		( alf voc-acf )
   repeat				( )
;
\ [then]

: words  (s -- )
   0 lmargin !  d# 64 rmargin !  d# 14 tabstops !  ??cr
   0  context token@             ( 0 voc-acf )
   begin another-word?  while    ( alf voc-acf anf )
     dup name>string nip .tab    ( alf voc-acf anf )
     .id                         ( alf voc-acf )
     exit? if  2drop exit  then  ( alf voc-acf )
   repeat                        ( )
;

\ [ifdef] Daktari
\ voc-words -- List all words in a specified vocabulary

: voc-words (s lmarg rmarg tabs vocabulary-xt -- )
   also execute				\ Select specified vocabulary
   (words)				\ List out the vocabulary
   previous				\ Discard specified vocabulary
;
\ [then]

only definitions forth also
: words    words ;  \ Version for 'root' vocabulary
only forth also definitions
