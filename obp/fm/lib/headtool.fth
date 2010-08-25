id: @(#)headtool.fth 1.9 03/12/11 09:22:54
purpose: 
copyright: Copyright 1990-2001 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.
\ Copyright 1985-1990 Bradley Forthware

\ Tools to make headerless definitions easier to live with.
\ To reheader the headerless words, download the headers file
\ via  DL  or something like it. 

headers

\  The format of each line of the "headers" file produced by the OBP
\  make  process is:
\      h#  <Offset>  <headerless:|header:>  <name>
\
\  After reading the "headers" file through these definitions, it should
\  be possible to find a name for most definitions.

\  Re-create headers by making them an alias for the actual name.  Keep them
\  within the special re-created headers' vocabulary.  If they are leftover
\  transient words, i.e., outside the dictionary, ignore them...
: headerless:  \ name  ( offset -- )   compile-time
               \       ( ??? -- ??? )  run-time
   origin+ dup in-dictionary? parse-word rot if
	  [ also hidden ]
	  ['] re-heads
	  [ previous ] $create-word flagalias  acf-align token,
   else
	  3drop
   then
;

: header:      \ name  ( offset -- )   compile-time
               \       ( ??? -- ??? )  run-time
   drop [compile] \
;


\  Before faking-out a headerless name, scan the vocabulary of the
\  re-created headers.  Fake-out the name only if it isn't found.
: find-head  ( cfa -- nfa )
   [ also hidden ]
   ['] re-heads
   [ previous ] follow begin	( cfa )
      another?			( cfa nfa flag )
   while			( cfa nfa )
      2dup name> token@		( cfa nfa cfa cfa2 )
      = if			( cfa nfa )
	 nip exit		( nfa )
      else
	 drop			( cfa )
      then			( cfa )
   repeat			( cfa )
   fake-name			( nfa )
;


\  Plug the routine to scan the re-created headers' vocabulary in to
\  the word that looks up names.  It does no harm to have it plugged
\  in place even if the headers file has not been read, because the
\  initial link-pointer in the re-created headers' vocabulary is null.

patch find-head fake-name >name


