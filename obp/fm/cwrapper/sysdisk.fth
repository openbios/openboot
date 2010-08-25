\ @(#)sysdisk.fth 2.11 01/05/18
\ Copyright 1985-1994 Bradley Forthware
\ Copyright 1994-2001 Sun Microsystems, Inc.  All Rights Reserved

\ File I/O interface using the C wrapper program
headerless
decimal

\ Closes an open file, freeing its descriptor for reuse.
: _fclose  ( file# -- )
   bfbase @  bflimit @ over -  free-mem   \ Hack!  Hack!
   4 syscall  drop
;

\ Writes "count" bytes from the buffer at address "adr" to a file.
\ Returns the number of bytes actually written.

: _fwrite  ( adr #bytes file# -- #written )
   >r swap r>  6 syscall 3drop retval  error?  if  drop 0  then  ( #written)
;

\ Reads at most "count" bytes into the buffer at address "adr" from a file.
\ Returns the number of bytes actually read.

: _fread  ( adr #bytes file# -- #read )
   >r swap r>  5 syscall 3drop retval  error? abort" _fread failed" ( #read )
;

\ Used by _fseek, _ftell, and _fsize

: _lseek  ( whence l.byte# file# -- l.byte# error? )
   10 syscall drop drop drop retval error?
;

\ Positions to byte number "l.byte#" in a file

: _fseek  ( l.byte# file# -- )
   0 -rot  _lseek  abort" _fseek failed" drop
;
: _dfseek  ( d.byte# file# -- )
   swap abort" _dfseek argument too large"  _fseek
;

\ Returns the current position "l.current-position" within a file

: _ftell  ( file# -- l.byte# )  1 0 rot  _lseek  abort" _ftell failed"  ;
: _dftell  ( file# -- d.byte# )  _ftell 0  ;

\ Returns the current size "l.size" of a file

: _fsize  ( file# -- l.size )
   \ remember the current position
   >r  r@ _ftell    ( l.position )

   \ seek to end of file to find out where the eof is
   2  0 r@ _lseek  abort" _fsize failed"  ( l.pos l.size )

   \ return to the original position
   swap r> _fseek  ( l.size )
;
: _dfsize  ( file# -- d.size )  _fsize 0  ;

\ Protection to be assigned to newly-created files
\ Defaults to public read permission, owner and group write permission.

variable file-protection
-1 is file-protection  \ Use system default until overridden

\ Prepares a file for later access.  Name is the pathname of the file
\ and mode is the mode (0 read, 1 write, 2 modify).  If the operation
\ succeeds, returns the addresses of routines to perform I/O on the
\ open file and true.  If the operation fails, returns false.

: sys_fopen
   ( name mode -- [ fid mode sizeop alignop closeop writeop readop ] okay? )
   >r r@ swap cstr file-protection @ -rot    ( prot mode name )
   over  8 and  if                           ( prot mode name )
      nip 3  syscall 2drop  retval          ( fid )
   else                                      ( prot mode name )
      2  syscall 3drop  retval               ( fid )
   then                                      ( fid )
   error?  if  r> drop drop false  exit  then   ( fid )
   r@   ['] _dfsize   ['] _dfalign   ['] _fclose   ['] _dfseek
   r@ read  =  if  ['] nullwrite  else  ['] _fwrite  then
   r> write =  if  ['] nullread   else  ['] _fread   then
   true
;

\ Removes the named file from its directory.

headers
: _delete  ( name -- err? )  cstr 11 syscall  drop retval  ;
headerless

: sys_newline  ( -- adr )  28 syscall  retval  ;

: install-disk-io  ( -- )
   ['] sys_newline is newline-pstring
   ['] sys_fopen   is do-fopen
;

\ Line terminators for various operating systems
create lf-pstr    1 c, linefeed c,               \ Unix
create cr-pstr    1 c, carret   c,               \ Macintosh, OS-9
create crlf-pstr  2 c, carret   c,  linefeed c,  \ DOS


\ Aligns to a 512-byte boundary for Unix

: _falign  ( byte# fd -- aligned )  drop  h# 1ff invert and  ;
: _dfalign  ( d.byte# fd -- d.aligned )  drop  swap h# 1ff invert and  swap  ;

th 1b4 is file-protection  \ rw-rw-r--  Unix file protection code

chain: unix-init-io
   install-disk-io
;

headers
