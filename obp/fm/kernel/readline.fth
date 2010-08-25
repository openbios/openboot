\ readline.fth 1.7 01/05/18
\ Copyright 1994 FirmWorks  All Rights Reserved
\ Copyright 1994-2001 Sun Microsystems, Inc.  All Rights Reserved

headers
0 constant r/o
1 constant w/o
2 constant r/w
4 constant bin
8 constant create-flag

headerless
2 /n-t * ualloc-t user opened-filename
headers

: open-file  ( adr len mode -- fd ior )
   >r 2dup opened-filename 2! cstrbuf pack r@ fopen   ( fd )  ( r: mode )

   \ Bail out now if the open failed
   dup  0=  if  mark-error d# -38  r> drop  exit  then

   \ But first, initialize the delimiters to the default values for the
   \ underlying operating system, in case the file is initially empty.
   newline-string  case
      1 of  c@         0        endof
      2 of  dup 1+ c@  swap c@  endof
      ( default )  linefeed carret rot
   endcase   pre-delimiter c!  line-delimiter c!

   \ If the mode is neither "w/o" nor "binary", and the file isn't
   \ being newly created, establish the line delimiter(s) by looking
   \ for the first carriage return or line feed

   dup  r@ bin create-flag or  and 0=  and  r> w/o <> and  if
      dup set-line-delimiter
   then                                           ( fd )
   0                                              ( fd ior )
;
: close-file  ( fd -- ior )
   ?dup  0=  if  0  exit  then
   dup -1 =  if  drop 0  exit  then
   ['] fclose catch  ?dup  if  nip  else  0  then
;

: left-parse-string  ( adr len delim -- tail$ head$ )
   split-string  dup if  1 /string  then  2swap
;

: remaining$  ( -- adr len )  bfcurrent @  bftop @ over -  ;

: $set-line-delimiter  ( adr len -- )
   carret split-string  dup  if           ( head-adr,len tail-adr,len )
      carret line-delimiter c!            ( head-adr,len tail-adr,len )
      1 >  if                             ( head-adr,len tail-adr )
         dup 1+ c@ linefeed  =  if        ( head-adr,len tail-adr )
            carret pre-delimiter c!       ( head-adr,len tail-adr )
            linefeed line-delimiter c!    ( head-adr,len tail-adr )
         then                             ( head-adr,len tail-adr )
      then                                ( head-adr,len tail-adr )
   else                                   ( adr,len tail-adr,0 )
      2drop  linefeed split-string  if    ( head-adr,len tail-adr )
         0 pre-delimiter c!               ( head-adr,len tail-adr )
         linefeed line-delimiter c!       ( head-adr,len tail-adr )
      then                                ( head-adr,len tail-adr )
   then                                   ( head-adr,len tail-adr )
   3drop                                  ( )
;
: set-line-delimiter  ( fd -- )
   file @ >r  file !  0 0 fillbuf  remaining$  $set-line-delimiter  r> file !
;
: -pre-delimiter  ( adr len -- adr' len' )
   pre-delimiter c@  if
      dup  if
         2dup + 1- c@  pre-delimiter c@  =  if
            1-
         then
      then
   then
;

: parse-line-piece  ( adr len #so-far -- actual retry? )
   >r  2>r  ( r: #so-far adr len )

   remaining$                          ( fbuf$ )
   line-delimiter c@ split-string      ( head$ tail$ )  ( r: # adr len )

   2swap -pre-delimiter                ( tail$ head$')  ( r: # adr len )

   dup r@  u>=  if                     ( tail$ head$ )  ( r: # adr len )
      \ The parsed line doesn't fit into the buffer, so we consume
      \ from the file buffer only the portion that we copy into the
      \ buffer.
      over r@ +  bfcurrent !           ( tail$ head$ )
      drop nip nip                     ( head-adr )  ( r: # adr len )
      2r> dup >r  move                 ( )           ( r: # len )
      2r> + false                      ( actual don't-retry )
      exit
   then                                ( tail$ head$ )  ( r: # adr len )

   \ The parsed line fits into the buffer, so we copy it all in
   tuck  2r> drop  swap  move          ( tail$ head-len )  ( r: # )
   r> +  -rot                          ( actual tail$ )

   \ Consume the parsed line from the file buffer, including the
   \ delimiter if one was found (as indicated by nonzero tail-len)
   tuck  if  1+  then  bfcurrent !     ( actual tail-len )

   \ If a delimiter was found, increment the line number the next time.
   dup if  1 (file-line) +!  then

   \ If a delimiter was found, we need not retry.
   0=                                  ( actual retry? )
;
: read-line  ( adr len fd -- actual not-eof? error? )
   file @ >r  file !
   0
   begin  >r 2dup r>  parse-line-piece  while   ( adr len actual )

      \ The end of the file buffer was reached without filling the
      \ argument buffer, so we refill the file buffer and try again.

      bftop @  ['] shortseek catch  ?dup  if  ( adr len actual x error-code )
         \ A file read error (more serious than end-of-file) occurred
         drop 2swap 2drop  false swap         ( actual false ior )
	 r> file !  exit
      then                                    ( adr len actual )
      remaining$  nip 0=  if                  ( adr len actual )

         \ Shortseek did not put any more characters into the file buffer,
         \ so we return the number of characters that were copied into the
	 \ argument buffer before shortseek was called and a flag.
         \ If no characters were copied into the argument buffer, the
         \ flag is false, indicating end-of-file

         nip  nip  dup 0<>  0                ( #copied not-eof? 0 )
         r> file !  exit
      then                                   ( adr len #copied )
      \ There are more characters in the file buffer, so we update
      \ adr len to reflect the portion of the buffer that has
      \ already been filled.
      dup >r /string r>                     ( adr' len' actual' )
   repeat                                   ( adr len actual )
   nip nip true 0                           ( actual true 0 )
   r> file !
;
\ Some more ANS Forth versions of file operations
: reposition-file  ( d.position fd -- ior )
   ['] dfseek catch  dup  if  nip nip nip  then
;
: file-size  ( fd -- d.size ior )
   ['] dfsize catch  dup if  0 0 rot  then
;
: read-file  ( adr len fd -- actual ior )
   ['] fgets catch  dup  if  >r 3drop 0 r>  then
;
: write-file  ( adr len fd -- actual ior )
   over >r  ['] fputs catch  dup  if   ( x x x ior )  ( r: len )
      r> drop  >r 3drop 0 r>           ( 0 ior )
   else                                ( ior )        ( r: len )
      r> swap                          ( len ior )
   then                                ( actual ior )
;
: flush-file  ( fd -- ior )  ['] fflush  catch  dup  if  nip  then  ;
: write-line  ( adr len fd -- ior )
   dup >r ['] fputs catch  ?dup  if  nip nip nip  r> drop exit  then  ( )
   pre-delimiter c@  if
      pre-delimiter c@  r@  ['] fputc catch  ?dup  if  ( x x ior )
         nip nip  r> drop exit
      then                                             ( )
   then
   line-delimiter c@  r>  ['] fputc catch  dup  if     ( x x ior )
      nip nip exit
   then                                                ( ior )
;
\ Missing: file-status, create-file, delete-file, resize-file, rename-file
