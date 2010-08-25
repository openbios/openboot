\ filecomm.fth 2.21 02/11/19
\ Copyright 1985-1994 Bradley Forthware, Inc.
\ copyright: Copyright 1994-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

decimal

\ buffered i/o  constants
-1 constant eof

\ field creates words which return their address within the structure
\ pointed-to by the contents of file

\ The file descriptor structure describes an open file.
\ There is a pool of several of these structures.  When a file is opened,
\ a structure is allocated and initialized.  While performing an io
\ operation, the user variable "file" contains a pointer to the file
\ on which the operation is being performed.

headers
struct ( file descriptor )
/n file-field bfbase     \ starting address of the buffer for this file
/n file-field bflimit    \ ending address of the buffer for this file
headerless
/n file-field bftop      \ address past last valid character in the buffer
/n file-field bfend      \ address past last place to write in the buffer
/n file-field bfcurrent  \ address of the current character in the buffer
/n file-field bfdirty    \ contains true if the buffer has been modified
/n file-field fmode      \ not-open, read, write, or modify
/n 2* file-field fstart  \ Position in file of the first byte in buffer
/n file-field fid        \ File handle for underlying operating system
/n file-field seekop     \ Points to system routine to set the file position
/n file-field readop     \ Points to system routine to read blocks
/n file-field writeop    \ Points to system routine to write blocks
/n file-field closeop    \ Points to system routine to close file
/n file-field alignop    \ Points to system routine to align to block boundary
/n file-field sizeop     \ Points to system routine to return the file size
/n file-field (file-line) \ Number of line delims that read-line has consumed
/c file-field line-delimiter  \ The last delimiter at the end of each line
/c file-field pre-delimiter   \ The first line delimiter (if any)
d# 128 file-field (file-name)  \ The name of the file
/n round-up
headers
constant /fd

: set-name  ( adr len -- )
   \ If the name is too long, cut off initial characters (because the
   \ latter ones are more likely to be interesting), and replace the
   \ first character with "?".
   dup d# 127 -  0 max  dup >r  /string  (file-name) place
   r>  if  ascii ? (file-name) 1+ c!  then
;
: file-name  ( fd -- adr len )
   file @ >r  file !  (file-name) count  r> file !
;
: file-line  ( fd -- n )  file @ >r  file !  (file-line) @  r> file !  ;
: setupfd  ( fid fmode sizeop alignop closeop seekop writeop readop -- )
   readop !  writeop !  seekop !  closeop !  alignop !  sizeop !
   fmode !  fid !  0 (file-line) !  0 0 set-name
;

headerless
\ values for mode field
-1  constant not-open
headers
 0  constant read
headerless
 1  constant write
headers
 2  constant modify
headerless
modify constant read-write  ( for old programs )

\ Stub routines for readop and writeop
headers
\ These return 0 for the number of bytes actually transferred.
: nullwrite  ( adr count fd -- 0 )  drop 2drop 0  ;
: fakewrite  ( adr count fd -- count )  drop nip  ;
: nullalign  ( d.position fd -- d.position' )  drop  ;
: nullread  ( adr count fd -- 0 )  drop 2drop 0  ;
: nullseek  ( d.byte# fd -- )  drop 2drop  ;
headerless
\ This one pretends to have transferred the requested number of bytes
: fakeread  ( adr count fd -- count )  drop nip  ;

headers
\ Initializes the current descriptor to use the buffer "bufstart,buflen"
: initbuf  ( bufstart buflen -- )
   0 0 fstart 2!   over + bflimit !  ( bufstart )
   dup bfbase ! dup bfcurrent ! dup bfend !  bftop !
   bfdirty off
;

\ "unallocate" a file descriptor
: release-fd  ( fd -- )  file @ >r  file !  not-open fmode !  r> file !  ;
headerless

\ An implementation factor which returns true if the file descriptor fd
\ is not currently in use
: fdavail?  ( fd -- f )  file @ >r  file !  fmode @ not-open =  r> file !  ;

\ These are the words that a program uses to read and write to/from a file.

\ An implementation factor which
\ ensures that the bftop is >= the bfcurrent variable.  bfcurrent
\ can temporarily advance beyond bftop while a file is being extended.

: bfsync  ( -- )  \ if current > top, move up top
   bftop @ bfcurrent @ u<   if    bfcurrent @  bftop !    then
;

\ If the current file's buffer is modified, write it out
\ Need to better handle the case where the file can't be extended,
\ for instance if the file is a memory array
: ?flushbuf  ( -- )
   bfdirty @   if
      bfsync
      fstart 2@  fid @  seekop @ execute  ( )
      bftop @ bfbase @  -                 ( #bytes-to-write)
      bfbase @  over                      ( #bytes adr #bytes )
      fid @ writeop @ execute             ( #bytes-to-write #bytes-written )
      u>  ( -37 ) abort" Flushbuf error"
      bfdirty off
      bfbase @   dup bftop !  bfcurrent !
   then
;

\ An implementation factor which
\ fills the buffer with a block from the current file.  The block will
\ be chosen so that the file address "d.byte#" is somewhere within that
\ block.

: fillbuf  ( d.byte# -- )
   fid @ alignop @ execute  ( d.byte# ) \ Aligns position to a buffer boundary
   2dup fstart 2!           ( d.byte# )
   fid @ seekop @ execute               ( )
   bfbase @   bflimit @ over -          ( adr #bytes-to-read )
   fid @ readop @ execute               ( #bytes-read )
   bfbase @ +   bftop !
   bflimit @  bfend !
;

\ An implementation factor which
\ returns the address within the buffer corresponding to the
\ selected position "d.byte#" within the current file.

: >bufaddr  ( d.byte# -- bufaddr )  fstart 2@ d- drop  bfbase @ +  ;

\ An implementation factor which
\ advances to the next block in the file.  This is used when accesses
\ to the file are sequential (the most common case).

\ Assumes the byte is not already in the buffer!
: shortseek  ( bufaddr -- )
   ?flushbuf                             ( bufaddr )
   bfbase @ - s>d  fstart 2@  d+         ( d.byte# )
   2dup fillbuf                          ( d.byte# )
   >bufaddr  bftop @  umin  bfcurrent !
;

\ Buffer boundaries are transparant
\ end-of-file conditions work correctly
\ The actual delimiter encountered in stored in delimiter.

headers
\ input-file contains the file descriptor which defines the input stream.
nuser input-file

headerless

\ ?fillbuf is called by the string scanning routines after skipbl, scanbl,
\ skipto, or scanto has returned.  ?fillbuf determines whether or not
\ the end of a buffer has been reached.  If so, the buffer is refilled and
\ end? is set to false so that the skip/scan routine will be called again,
\ (unless the end of the file is reached).

: ?fillbuf  ( endaddr [ adr ]  delimiter -- endaddr' addr' end? )
    dup delimiter !  eof =  if ( endaddr )
       shortseek
       bftop @  bfcurrent @    ( endaddr'  addr' )
       2dup u<=                ( endaddr'  addr' end-of-file? )
    else                       ( endaddr addr )
       true            \ True so we'll exit the loop
    then
;

headers
\ Closes the file.
: fclose  ( fd -- )
   file @ >r  file !
   file @  fdavail?  0=  if
      ?flushbuf  fid @ closeop @ execute
      file @  release-fd
   then
   r> file !
;

headerless
\ File descriptor allocation

 8         constant #fds
#fds /fd * constant /fds

nuser fds

\ Initialize pool of file descriptors
chain: init  ( -- )
   /stringbuf alloc-mem is 'word
   /fds alloc-mem  ( base-address )  fds !
   fds @  /fds   bounds   do   i release-fd   /fd +loop
;

\ Allocates a file descriptor if possible
: (get-fd  ( -- fd | 0 )
   0
   fds @  /fds  bounds  ?do               ( 0 )
      i fdavail?  if  drop i leave  then  ( 0 )
   /fd +loop                              ( fd | 0 )
;

: string-sizeop  ( fhandle -- d.length )  drop  bflimit @  bfbase @ -  0  ;

: open-buffer  ( adr len -- fd ior )
   2 ?enough
   \ XXX we need a "throw" code for "no more fds"
   (get-fd  ?dup 0=  if  0 true exit  then  ( adr len fd )
   file !
   2dup                                     ( adr len )
   initbuf                                  ( adr len )
   bflimit @  dup bfend !  bftop !          ( adr len )

   0  modify
   ['] string-sizeop  ['] drop  ['] drop
   ['] nullseek  ['] fakewrite  ['] nullread   setupfd  ( adr len )
   $set-line-delimiter

   \ Set the file name field to "<buffer@ADDRESS>"
   base @ >r hex
   bfbase @ <#  ascii > hold  u#s " <buffer@" hold$ u#> set-name
   r> base !

   file @  false
;

headerless
: (.error#)  ( error# -- )
   dup d# -38  =  if
      ." The file '"  opened-filename 2@ type  ." ' cannot be opened."
   else  ." Error " .  then
;
' (.error#) is .error#
