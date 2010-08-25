\ ansio.fth 1.11 05/01/04
\ Copyright 1994 FirmWorks  All Rights Reserved
\ Copyright 1994-2002, 2004 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

headers
: allocate  ( size -- adr ior )  alloc-mem  dup 0=  ;

\ Assumes free-mem doesn't really need the size parameter; usually true
: free  ( adr -- ior )  0 free-mem 0  ;

nuser insane
0 value exit-interact?

\ XXX check for EOF on keyboard stream
: more-input?  ( -- flag )  insane off  true  ;

d# 1024 constant /tib

variable blk
defer ?block-valid  ( -- flag )  ' false is ?block-valid

variable >in
variable #tib
nuser 'source-id
: source-id  ( -- fid )  'source-id @  ;

nuser 'source
nuser #source
: source-adr  ( -- adr )  'source @  ;
: source      ( -- adr len )  source-adr  #source @  ;
: set-source  ( adr len -- )  #source !  'source !  ;

: save-input  ( -- source-adr source-len source-id >in blk 5 )
   source  source-id  >in @  blk @  5
;
: restore-input  ( source-adr source-len source-id >in blk 5 -- flag )
   drop
   blk !  >in !  'source-id !  set-source
   false
;
: set-input  ( source-adr source-len source-id -- )
   0 0 5 restore-input drop
;
headerless
: skipwhite  ( adr1 len1 -- adr2 len2  )
   begin  dup 0>  while       ( adr len )
      over c@  bl >  if  exit  then
      1 /string
   repeat                     ( adr' 0 )
;

\ Adr2 points to the delimiter or to the end of the buffer
\ Adr3 points to the character after the delimiter or to the end of the buffer
: scantowhite  ( adr1 len1 -- adr1 adr2 adr3 )
   over swap                       ( adr1 adr1 len1 )
   begin  dup 0>  while            ( adr1 adr len )
      over c@  bl <=  if  drop dup 1+  exit  then
      1 /string                    ( adr1 adr' len' )
   repeat                          ( adr1 adr2 0 )
   drop dup                        ( adr1 adr2 adr2 )
;

: skipchar  ( adr1 len1 delim -- adr2 len2 )
   >r                         ( adr1 len1 )  ( r: delim )
   begin  dup 0>  while       ( adr len )
      over c@  r@ <>  if      ( adr len )
         r> drop exit         ( adr2 len2 )
      then                    ( adr len )
      1 /string               ( adr' len' )
   repeat                     ( adr' 0 )
   r> drop                    ( adr2 0 )
;

\ Adr2 points to the delimiter or to the end of the buffer
\ Adr3 points to the character after the delimiter or to the end of the buffer
: scantochar  ( adr1 len1 char -- adr1 adr2 adr3 )
   >r                              ( adr1 len1 )   ( r: delim )
   over swap                       ( adr1 adr1 len1 )
   begin  dup 0>  while            ( adr1 adr len )
      over c@  r@ =  if            ( adr1 adr len )
         r> 2drop dup 1+  exit     ( adr1 adr2 adr3 )
      then                         ( adr1 adr len )
      1 /string                    ( adr1 adr' len' )
   repeat                          ( adr1 adr2 0 )
   r> 2drop dup                    ( adr1 adr2 adr2 )
;
headers
: parse-word  ( -- adr len )
   source >in @ /string  over >r   ( adr1 len1 )  ( r: adr1 )
   skipwhite                       ( adr2 len2 )
   scantowhite                     ( adr2 adr3 adr4 )
   r> - >in +!                     ( adr2 adr3 ) ( r: )
   over -                          ( adr1 len )
;
: parse  ( delim -- adr len )
   source >in @ /string rot	   ( adr len delim )
   -1 over = if			   ( adr len delim )
      \ CRLF..
      drop parse-line 2drop	   ( adr' len' )
      dup >in +!		   ( adr' len' )
      exit			   ( adr' len' )
   else				   ( adr len delim )
      -rot			   ( delim adr len )
   then				   ( delim adr1 len1 )
   over >r			   ( delim adr1 len1 )  ( r: adr1 )
   rot scantochar                  ( adr1 adr2 adr3 )  ( r: adr1 )
   r> - >in +!                     ( adr1 adr2 ) ( r: )
   over -                          ( adr1 len )
;
: word  ( delim -- pstr )
   source >in @ /string  over >r   ( delim adr1 len1 )  ( r: adr1 )
   rot >r r@ skipchar              ( adr2 len2 )        ( r: adr1 delim )
   r> scantochar                   ( adr2 adr3 adr4 )   ( r: adr1 )
   r> - >in +!                     ( adr2 adr3 ) ( r: )
   over -                          ( adr1 len )
   dup h# 255 >  ( -18 ) abort" Parsed string overflow"
   'word pack                      ( pstr )
;

defer refill-line ( adr fd -- actual not-eof? error? )

: simple-refill-line ( adr fd -- actual not-eof? error? )
   drop						( adr )
   \ The ANS Forth standard does not mention the possibility
   \ that ACCEPT might not be able to deliver any more input,
   \ but in this implementation, the `keyboard' can be redirected
   \ to a file via the command line, so it is indeed possible for
   \ ACCEPT to have no more characters to deliver.  Furthermore,
   \ we also provide a "finished" flag that can be set to force an
   \ exit from the interpreter loop.
   /tib accept  insane off			( cnt )
   dup  if  true  else  more-input?  then	( cnt more? )
;
' simple-refill-line is refill-line

: refill  ( -- more? )
   blk @  if  1 blk +!  ?block-valid  exit  then

   source-id  -1 =  if  false exit  then
   source-adr  source-id  refill-line		     ( adr )
   swap  #source !  0 >in !                          ( more? )
;

: (prompt)  ( -- )
   interactive?  if	\ Suppress prompt if input is redirected to a file
      ??cr status
      state @  if
         level @  ?dup if  1 .r  else  ."  "  then  ." ] "
      else
         (ok)
      then
      mark-output
   then
;
' (prompt) is prompt

: (interact)  ( -- )
   tib /tib 0 set-input
   [compile] [
   begin
      depth 0<  if  ." Stack Underflow" cr  clear  then
      sp@  sp0 @  ps-size -  u<  if  ." Stack Overflow" cr  clear  then
      do-prompt
   refill  while
      ['] interpret catch  ??cr  ?dup if
	 [compile] [  .error
	 \ ANS Forth sort of requires the following "clear", but it's a
	 \ real pain and doesn't affect programs, so we don't do it
	 \ clear
      then
   exit-interact? until then
   false is exit-interact?
;
: interact  ( -- )
   save-input  2>r 2>r 2>r
   (interact)
   2r> 2r> 2r> restore-input  throw
;
: (quit)  ( -- )
   \ XXX We really should clean up any open input files here...
   reset-checkpts
   0 level !  ]
   rp0 @ rp!
   interact
   bye
;
' (quit) is quit

: (evaluate) ( adr len -- )  -1 set-input  interpret  ;

: evaluate  ( adr len -- )
   save-input  2>r 2>r 2>r   ( adr len )
   ['] (evaluate) catch  dup  if  nip nip  then   ( error# )
   2r> 2r> 2r> restore-input  throw               ( error# )
   throw
;
