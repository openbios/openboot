\  @(#)filetool.fth 2.8 03/07/17
\ Copyright 1985-1990 Bradley Forthware
\ Copyright 1994-2003 Sun Microsystems, Inc.  All Rights Reserved.
\ Copyright Use is subject to license terms.

\ Some convenience words for dealing with files.

decimal

\ Relative seek
: +fseek  ( loffset fd -- )
   tuck ftell  ( fd loffset lpos )
   + swap fseek
;
\ Relative seek from end of file.  loffset should be negative.
: fseek-from-end  ( loffset fd -- )
   tuck fsize     ( fd loffset lsize )
   +             ( fd lposition )
   0 max   swap  fseek
;

\ linefeed constant newline

\ Handy file descriptor variables
variable ifd
variable ofd

: $read-open  ( name$ -- )
   2dup r/o open-file  if      ( name$ x )
      drop  ." Can't open " type ."  for reading." cr abort
   then                        ( name$ fd )
   ifd !                       ( name$ )
   2drop
;
: reading  ( "filename" -- )  safe-parse-word $read-open  ;

: $write-open  ( name$ -- )
   2dup r/w open-file  if      ( name x )
      drop  ." Can't open " type ."  for writing." cr abort
   then                        ( name$ fd )
   ofd !                       ( name$ )
   2drop
;
: $new-file  ( name$ -- )
   2dup r/w create-file  if    ( name$ x )
      drop  ." Can't create " type  cr abort
   then                        ( name$ fd )
   ofd !                       ( name$ )
   2drop
;
: writing  ( "filename" -- )  safe-parse-word $new-file  ;

: $append-open  ( name$ -- )
   2dup r/w open-file  if      				( name$ ior )
      \ We have to make the file
      drop $new-file					( )
   else  \ The file already exists, so seek to the end  ( name$ fd )
      ofd !  2drop					( )
      0 ofd @ fseek-from-end                            ( )
   then
;
: appending  ( "filename" -- )  safe-parse-word $append-open  ;

: $file-exists?  ( name$ -- flag ) \ True if the named file already exists
   r/o open-file  if  drop false  else  close-file drop true  then
;

: $file,  ( adr len -- )
   r/o  bin or   open-file  abort" Can't open file"  ifd !

   here   ifd @ fsize dup allot                    ( adr len )
   2dup   ifd @ fgets  over <> abort" Short read"  ( adr len )
   ifd @ fclose                                    ( adr len )
   note-string  2drop   \ Mark as a sequence of bytes
;

\ Backwards compatibility ...

: read-open     ( name-pstr -- )  count $read-open    ;
: write-open    ( name-pstr -- )  count $write-open   ;
: new-file      ( name-pstr -- )  count $new-file     ;
: append-open   ( name-pstr -- )  count $append-open  ;
: file-exists?  ( name-pstr -- flag ) \ True if the named file already exists
   read fopen  ( fd )   dup   if  fclose true  then
;

headers

