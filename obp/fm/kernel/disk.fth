\ disk.fth 2.11 01/04/06
\ Copyright 1985-1994 Bradley Forthware
\ copyright: Copyright 1994-2001 Sun Microsystems, Inc.  All Rights Reserved

\ High level interface to disk files.

headerless

\ If the underlying operating system requires that files be accessed
\ in fixed-length records, then /fbuf must be a multiple of that length.
\ Even if the system allows arbitrary length file accesses, there is probably
\ a length that is particularly efficient, and /fbuf should be a multiple
\ of that length for best performance.  1K works well for many systems.

td 1024 constant /fbuf

headerless

\ An implementation factor which gets a file descriptor and attaches a
\ file buffer to it
headerless
: get-fd  ( -- )
   (get-fd  dup 0= ( ?? ) abort" all fds used "  ( fd )
   file !
   /fbuf alloc-mem  /fbuf initbuf     ( )
;
headers
\ Amount of space needed:
\   #fds * /fd     for automatically allocated file descriptors
\   1 * /fd        for "accept" descriptor
\   tib            for "accept" buffer
\
\ #fds = 8, so total of 9 * /fd  = 9 * 56 = 486 for fds
\ 8 * 1024 +  3 * 128  +  tib
\ Total is ~9K

\ Returns the current position within the current file

: dftell  ( fd -- d.byte# )
   file @ >r  file !  fstart 2@  bfcurrent @ bfbase @ -  0 d+  r> file !
;
: ftell  ( fd -- byte# )  dftell drop  ;

\ Updates the disk copy of the file to match the buffer
headerless
: fflush  ( fd -- )  file @ >r  file !  ?flushbuf  r> file !  ;
headers
\ Starting here, some stuff doesn't have to be in the kernel

\ Sets the position within the current file to "d.byte#".
: dfseek  ( d.byte# fd -- )
   file @ >r  file !
   bfsync

   \ See if the desired byte is in the buffer
   \ The byte is in the buffer iff offset.high is 0 and offset.low
   \ is less than the number of bytes in the buffer
   2dup fstart 2@ d-                   ( d.byte# offset.low offset.high )
   over bfend @ bfbase @ -  u>= or  if ( d.byte# offset )
      \ Not in buffer
      \ Flush the buffer and get the one containing the desired byte.
      drop ?flushbuf 2dup fillbuf      ( d.byte# )
      >bufaddr                         ( bufaddr )
   else
      \ The desired byte is already in the buffer.
      nip nip  bfbase @ +           ( bufaddr )
   then

   \ Seeking past end of file actually goes to the end of the file
   bftop @  umin   bfcurrent !
   r> file !
;
: fseek  ( byte# fd -- )  0 swap dfseek  ;

\ Returns true if the current file has reached the end.
\ XXX This may only be valid after fseek or shortseek
headerless
: (feof?  ( -- f )   bfcurrent @  bftop @  u>=  ;

headers
\ Gets the next byte from the current file
: fgetc  ( fd -- byte )
   file @ >r  file !   bfcurrent @  bftop @  u<
   if   \ desired character is in the buffer
      bfcurrent @c@++
   else \ end of buffer has been reached
      bfcurrent @ shortseek
      (feof?  if  eof  else  bfcurrent @c@++  then
   then
   r> file !
;

\ Stores a byte into the current file at the next position
: fputc  ( byte fd -- )
   file @ >r  file !
   bfcurrent @   bfend @ u>=     ( byte flag )  \ Is the buffer full?
   if  bfcurrent @ shortseek  then     ( byte ) \ If so advance to next buffer
   bfcurrent @c!++  bfdirty on
   r> file !
;

\ An implementation factor
\ Copyin copies bytes starting at current into the file buffer at
\ bfcurrent.  The number of bytes copied is either all the bytes from
\ current to end, if the buffer has enough room, or all the bytes the
\ buffer will hold, if not.
\ newcurrent is left pointing to the first byte not copied.
headerless
: copyin  ( end current -- end newcurrent )
   2dup -                      ( end current remaining )
   bfend @  bfcurrent @  -     ( end current remaining bfremaining )
   min                         ( end current #bytes-to-copy )
   dup if  bfdirty on  then    ( end current #bytes-to-copy )
   2dup  bfcurrent @ swap      ( end current #bytes  current bfcurrent #bytes)
   move                        ( end current #bytes )
   dup bfcurrent +!            ( end current #bytes )
   +                           ( end newcurrent)
;

\ Copyout copies bytes from the file buffer into memory starting at current.
\ The number of bytes copied is either enough to fill memory up to end,
\ if the buffer has enough characters, or all the bytes the
\ buffer has left, if not.
\ newcurrent is left pointing to the first byte not filled.
headerless
: copyout  ( end current -- end newcurrent )
   2dup -                      ( end current remaining )
   bftop @  bfcurrent @  -     ( end current remaining bfrem )
   min                         ( end current #bytes-to-copy)
   2dup bfcurrent @ rot rot    ( end current #bytes  current bfcurrent #bytes)
   move                        ( end current #bytes)
   dup  bfcurrent +!           ( end current #bytes)
   +                           ( end newcurrent )
;
headers
\ Writes count bytes from memory starting at "adr" to the current file
: fputs  ( adr count fd -- )
   file @ >r  file !
   over + swap  ( endaddr startaddr )
   begin  copyin  2dup u>
   while
      \ Here there should be some code to see if there are enough remaining
      \ bytes in the request to justify bypassing the file buffer and writing
      \ directly from the user's buffer.  'Enough' = more than one file buffer
      bfsync  bfcurrent @ shortseek ( endaddr curraddr )
   repeat
   2drop
   r> file !
;

\ Reads up to count characters from the file into memory starting
\ at "adr"

: fgets  ( adr count fd -- #read )
   file @ >r  file !
   bfsync
   over + over  ( startaddr endaddr startaddr )
   begin  copyout  2dup u>
   while
      \ Here there should be some code to see if there are enough remaining
      \ bytes in the request to justify bypassing the file buffer and reading
      \ directly to the user's buffer.  'Enough' = more than one file buffer
      bfcurrent @ shortseek ( startaddr endaddr curraddr )
      (feof?  if  nip swap -  r> file !  exit then
   repeat
   nip swap -
   r> file !
;

\ Returns the current length of the file
: dfsize  ( fd -- d.size )
   file @ >r  file !
   fstart 2@  bftop @  bfbase @  -  0 d+  ( buffered-position )
   fid @  sizeop @  execute               ( buffered-position file-size )
   dmax
   r> file !
;
: fsize  ( fd -- size )  dfsize drop  ;


\ End of stuff that doesn't have to be in the kernel

defer do-fopen

\ Prepares a file for later access, returning "fd" which is subsequently
\ used to refer to the file.

: fopen  ( name mode -- fd )
   2 ?enough
   get-fd   ( name mode )  over >r
   do-fopen  if
      setupfd  file @  r> count set-name
   else
      not-open fmode !  0  r> drop
   then
;

headers

\ Closes all the open files and reclaims their file descriptors.
\ Use this if you see an "all fds used" message.

: close-files ( -- )  fds @  /fds  bounds   do   i fclose   /fd +loop  ;

: create-file  ( name$ mode -- fileid ior )  create-flag or  open-file  ;

: make  ( name-pstr -- flag )	\ Creates an empty file
   count  r/w  create-file  if  drop false  else  close-file drop true  then
;
