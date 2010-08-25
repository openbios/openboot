id: @(#)fcode-rom.fth 1.5 06/04/21
purpose: PCI bus package
copyright: Copyright 1994 FirmWorks  All Rights Reserved
copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved.
copyright: Use is subject to license terms.

headerless
\ If the expansion ROM mapped at "virt" contains an FCode program,
\ copy it into RAM and return its address

: le-w@  ( adr -- n )  dup c@  swap 1+ c@  bwjoin  ;
: be-l@  ( adr -- n )
   dup 3 + c@  swap dup 2 + c@  swap dup 1 + c@  swap c@   bljoin
;

: fcode-image?  ( PCI-struct-adr -- flag )
   dup " PCIR" comp  if  drop false exit  then

   \ Check if the Vendor ID matches
   dup 4 + le-w@  0 parent-w@ <>  if
      drop false exit
   then

   \ Check if the device ID matches
   dup h# 06 + le-w@  h# 02 parent-w@ <>  if
      drop false exit
   then

   h# 14 + c@  1 =
;

[ifdef] fcode-checksum
\ This code can be enabled to perform a checksum test on
\ the Plugin card FCode PROM. Checksum test is performed
\ before the FCode is evaluated to make sure that the FCode
\ driver in FCode PROM is not corrupted. Checksum calculation 
\ algorithm and related stuff is defined in PCI Specification 
\ document.
: fcode-sum-ok? ( adr len -- ok? )
   over 4 + l@ < if		( h-adr )	\ h-adr: header address
      drop false exit		( false )	\ length error
   then				( h-adr )

   dup 2+ w@ swap		( exp-sum h-adr )
   dup 8 +			( exp-sum h-adr b-adr )	\ b-adr: body-address
   swap 4 + l@ 8 -		( exp-sum b-adr b-len )	\ b-len: body-length
   bounds 0  -rot do		( exp-sum 0 )		
      i c@ +			( exp-sum csum )
   loop
   lwsplit + lwsplit + h# ffff and	( exp-sum sum )
   2dup <> if	( exp-sum sum )
      cmn-warn[
         " FCode checksum error; expected: %x result: %x"	( )
      ]cmn-end
      false			( false )
   else		( exp-sum sum )
      2drop true		( true )
   then
;
[then]

: release-rom-resource ( phys.hi release? -- )
   if						( phys.hi )
      \ Zero the ROM Base Address Register
      \ and release associated resources
      0 over parent-l!				( -- )
      release-bar-resources			( -- )
   else						( phys.hi )
      \ disable ROMBAR address decode
      dup parent-l@  1 invert and		( phys.hi reg' )
      swap parent-l!				( -- )
   then						( -- )
;

headers
0 value rom-base

: locate-fcode  ( rom-image-adr -- false | adr len true )
   dup to rom-base
   begin
      dup  le-w@  h# aa55 <>  if
         drop false exit
      then 			    ( rom-image-adr )

      dup  h# 18 +  le-w@  over +   ( rom-image-adr PCI-struct-adr )
      dup fcode-image?  if          ( rom-image-adr PCI-struct-adr )
         drop dup rom-base -        ( rom-image-adr offset )
         encode-int  " fcode-rom-offset" property
         dup     2 + le-w@ +        ( FCode-image-adr )
	 dup >r  4 + be-l@          ( FCode-len )
	 dup alloc-mem              ( FCode-len adr )
         swap 2dup r> -rot cmove    ( adr len )
[ifdef] fcode-checksum
         2dup fcode-sum-ok? 0= if   ( adr len )
            2drop false exit        ( false )
         then
[then]
         true exit
      then
      dup h# 15 + c@  h# 80 and 0=  ( rom-image-adr PCI-struct-adr )
   while    \ More images           ( rom-image-adr PCI-struct-adr )
      h# 10 +  le-w@  9 lshift +    ( rom-image-adr' )
   repeat                           ( rom-image-adr' )
   2drop false
;

: find-fcode?  ( -- false | adr len true )

   expansion-rom get-bar# >bar-struct >r 	( -- )
   r@ >bar.implemented? @ 0= if			( -- )
     r> drop false exit				( -- )
   then						( -- )

   0 0 r@ >bar.phys.hi @   r> >bar.size @ 	( 0 0 phys.hi size )
   h# 2.0000 min dup >r				( 0 0 phys.hi size' )
   " map-in" $call-parent			( va ) ( r: size )
   r>						( va len )

   \ Turn on address decode enable in Expansion ROM Base Address Register
   expansion-rom >r				( va len ) ( r: offset )
   r@  parent-l@  1 or  r@  parent-l!		( va len ) ( r: offset )

   \ Turn on memory enable
   4 parent-w@ 2 or 4 parent-w!			( va len ) ( r: offset )

   >r dup >r locate-fcode			( false | adr len true )

   r> r> " map-out" $call-parent		( false | adr len true )

   r> false release-rom-resource		( false | adr len true )
;


\ After a function has been located and a device node has been created
\ for it, fill in the device node with properties and methods.

headerless

: driver-name ( -- str len )
   sub-vendev-id-value nip  if		\ Subsystem Ven ID is non-zero
      vdss-id-value			\ Use pciVVVV,DDDD.SSSS.ssss
   else
      vendev-id-value			\ Use pciVVVV,DDDD
   then
;

: no-builtin-fcode?  ( -- flag )
   builtin-drivers find-package if		( phandle )
     >r						( -- )
     driver-name r@ find-method if		( acf )
       true true				( acf true true )
     else					( -- )
       class-property-value r@ find-method if	( acf )
          false true				( acf false true )
       else					( -- )
          false					( false )
       then					( acf name? true | false )
     then					( acf name? true | false )
     r> drop					( acf name? true | false )
     if						( acf name? )
	drop					( acf )
        catch 0= if  false exit  then		( false )
     then					( -- )
   then
   true
;
