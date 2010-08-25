id: @(#)fileio.fth 1.3 04/04/15 19:10:04
purpose: 
copyright: Copyright 1994-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.
\ Copyright 1994 FirmWorks  All Rights Reserved

headerless

: (file-read-line) ( adr fd -- actual not-eof? error? )
   dup if						( adr source )
      /tib swap read-line				( adr len id )
      ( -37 ) abort" Read error in refill"  ( cnt more? )
      over /tib = ( -18 ) abort" line too long in input file"  ( cnt more? )
   else							( adr )
      simple-refill-line				( cnt more? )
   then							( cnt more? )
; ' (file-read-line) is refill-line

: interpret-lines  ( -- )  begin  refill  while  interpret  repeat  ;

: include-file  ( fid -- )
   /tib 4 + allocate throw	( fid adr )
   save-input 2>r 2>r 2>r       ( fid adr )

   /tib rot set-input

   ['] interpret-lines catch    ( error# )
   source-id close-file drop    ( error# )

   source-adr free drop         ( error# )

   2r> 2r> 2r> restore-input  throw  ( error# )
   throw
;

defer $open-error        ' noop is $open-error

[ifnexist] include-hook 	\  Might be defined in  xref.fth 
   headers
   defer include-hook       ' noop is include-hook
   defer include-exit-hook  ' noop is include-exit-hook
   headerless
[then]

: include-buffer  ( adr len -- )
   open-buffer  ?dup  if  " <buffer>" $open-error  then  include-file
;

: $abort-include  ( error# filename$ -- )  2drop  throw  ;
' $abort-include is $open-error

headers
: included  ( adr len -- )
   include-hook
   r/o open-file  ?dup  if
      opened-filename 2@ $open-error
   then                 ( fid )
   include-file
   include-exit-hook
;
headerless
' included is cmdline-file

: including  ( "name" -- )  safe-parse-word included  ;
: fl  ( "name" -- )  including  ;

0 value error-file
nuser error-line#
nuser error-source-id
nuser error-source-adr
nuser error-#source
chain: init  ( -- )
   d# 128 alloc-mem  is error-file
   error-source-id off
   0 error-file c!
   error-line# off
;

: (eol-mark?) ( c -- flag )
   dup 0= >r			( c )
   dup control M = r> or	( c cr? )
   swap control J = or		( cr? )
;

: (mark-error)  ( -- )
   \ Suppress message if input is interactive or from "evaluate"
   source-id  error-source-id !
   source-id  0<>  if
      source-id  -1 =  if
         \ Record the approx error position not the whole buffer!!
         true source >r >in @		( flag adr offset )
         begin				( flag adr offset )
            rot				( adr offset more? )
            over and while		( adr offset )
               2dup + c@		( adr offset )
               (eol-mark?) if		( adr offset )
                  1+ 0 -rot		( 0 adr offset )
               else			( adr offset )
                  true -rot 1-		( -1 adr offset )
               then			( flag adr offset )
         repeat				( adr offset )
         r> swap /string 		( adr' len' )
         >r 0 over r>			( adr' 0 adr' len )
         bounds ?do			( adr' 0 )
            i c@ (eol-mark?) if		( adr' len' )
               leave			( adr' len' )
            else			( adr' len' )
               1+			( adr' len' )
            then			( adr' len' )
         loop				( adr' len' )
         error-#source !  error-source-adr !
      else
         source-id file-name error-file place
         source-id file-line error-line# !
      then
   then
;
' (mark-error) is mark-error
: (show-error)  ( -- )
   ??cr
   error-source-id @  if
      error-source-id @ -1  =  if
         ." Evaluating: " error-source-adr @ error-#source @  type cr
      else
         error-file count ?dup if		( va,len )
            type  ." :"				( )
            error-line# @ (.d)			( $adr,len )
            type  ." : "			( )
         else					( va )
            drop				( )
         then					( )
      then					( )
   then						( )
;
' (show-error) is show-error

\ Environment?

headers

defer environment?
: null-environment?  ( c-addr u -- false | i*x true )  2drop false  ;
' null-environment? is environment?

: fload fl ;

: $report-name  ( name$ -- name$ )
   ??cr ." Loading " 2dup type cr
;
: fexit ( -- )  source-id close-file drop -1 'source-id !  ;
