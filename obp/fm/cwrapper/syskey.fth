\ syskey.fth 2.5 98/10/21
\ Copyright 1985-1994 Bradley Forthware

\ Console I/O using the C wrapper program

headerless
decimal

: sys-emit   ( c -- )   1 syscall drop  ;	\ Outputs a character
: sys-key    ( -- c )   0 syscall retval  ;	\ Inputs a character
: sys-(key?  ( -- f )   8 syscall retval  ;	\ Is a character waiting?
: sys-cr     ( -- )    27 syscall  #out off  1 #line +!  ;  \ Go to next line

\ Is the input stream coming from a keyboard?

: sys-interactive?  ( -- f )  12 syscall retval  0=  ;

headers
\ Reads at most "len" characters into memory starting at "adr".
\ Performs keyboard editing (erase character, erase line, etc).
\ The operation terminates when either a "return" is typed or "len"
\ characters have been read.
\ The operating system does the line editing until we load the line editor

: sys-accept  ( adr len -- actual )
   14 syscall 2drop retval   #out off  1 #line +!
;
headerless

\ Outputs "len" characters from memory starting at "adr"

: sys-type  ( adr len -- )  13 syscall  2drop  ;

\ Returns to the OS

: sys-bye  ( -- )  0 9 syscall  ;

\ Memory allocation

: sys-alloc-mem  (s #bytes -- adr )  26 syscall  drop  retval  ;
: sys-free-mem  (s adr #bytes -- )   32 syscall  2drop  ;

\ Cache flushing - needed for copyback data caches (e.g. 68040)

: sys-sync-cache  ( adr len -- )  swap 29 syscall 2drop  ;

: install-wrapper-io  ( -- )
   ['] sys-alloc-mem     is alloc-mem
   ['] sys-free-mem      is free-mem

   ['] sys-cr            is cr
   ['] sys-type          is (type
   ['] sys-emit          is (emit
   ['] sys-key           is (key
   ['] sys-(key?         is key?
   ['] sys-bye           is bye
   ['] sys-accept        is accept
   ['] sys-interactive?  is (interactive?

   ['] sys-sync-cache    is sync-cache
;
headers
