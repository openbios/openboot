id: @(#)unit.fth 1.2 97/10/14
purpose: PCI bus package
copyright: Copyright 1994 FirmWorks  All Rights Reserved
copyright: Copyright 1997 Sun Microsystems Inc All Rights Reserved

\ The encode/decode unit methods

headerless
h# 40 buffer: unit-string

: ?p  ( adr len phys -- adr' len' phys' )
   over 1 >=  if                            ( adr len phys )
      2 pick c@  upc  ascii P =  if         ( adr len phys )
         h# 4000.0000 +  >r  1 /string  r>  ( adr' len' phys' )
      then
   then
;
: ?t  ( adr len phys -- adr' len' phys' )
   over 1 >=  if                            ( adr len phys )
      2 pick c@  upc  ascii T =  if         ( adr len phys )
         h# 2000.0000 +  >r  1 /string  r>  ( adr' len' phys' )
      then
   then
;

: pci-decode-unit  ( adr len -- phys.lo phys.mid phys.hi )
   dup 0=  if  2drop 0 0 0  exit  then        ( adr len )
   0 >r
   over c@  upc  ascii N =  if  r> h# 8000.0000 + >r  1 /string  then  ( adr len )
   over c@  upc  case
      ascii I  of  r> h# 0100.0000 + >r  1 /string  r> ?t    >r  endof
      ascii M  of  r> h# 0200.0000 + >r  1 /string  r> ?t ?p >r  endof
      ascii X  of  r> h# 0300.0000 + >r  1 /string  r>    ?p >r  endof
      ( default )
   endcase

   \ XX do range checks

   ascii , left-parse-string                            ( rem$ DD$ )
   $hnumber  if  0  then  h# 1f and d# 11 lshift r> + >r   ( rem$ )
   dup 0=  if  2drop  0 0 r>  exit  then                ( rem$ )

   ascii , left-parse-string                            ( rem$ F$ )
   $hnumber  if  0  then  h#  f and d#  8 lshift  r> + >r   ( rem$ )
   dup 0=  if  2drop  0 0 r>  exit  then                ( rem$ )

   ascii , left-parse-string                            ( rem$ RR$ )
   $hnumber  if  0  then  h# ff and           r> + >r   ( rem$ )
   dup 0=  if  2drop  0 0 r>  exit  then                ( rem$ )

   \ Parse the remaining digits as a number, forcing the result to
   \ be a double number by pushing zeroes as needed
   $hdnumber?  ( 0 | n 1 | d 2 )  2 swap  ?do  0  loop  r>
;
headerless

: convert-device  ( phys.hi -- phys.hi )
   dup d# 11 >>  h# 1f and  u#s  drop
;
: convert-function  ( phys.hi -- phys.hi )
   dup 8 >>  7 and  u#  ascii , hold  drop
;
: convert-high  ( phys.hi -- phys.hi )
   dup h# 700 and  if  convert-function  then
   convert-device
;
: convert-rr  ( phys.hi -- phys.hi )
   ascii , hold
   dup h# ff and  u# u#s  drop   ( phys.hi )  \ RR field
   ascii , hold
   convert-function convert-device
;
: ?tpn  ( phys.hi char -- 0 )
   over  h# 2000.0000 and  if  ascii t hold  then
   over  h# 4000.0000 and  if  ascii p hold  then
   hold
   h# 8000.0000 and  if  ascii n hold  then
;

: pci-encode-unit  ( phys.lo phys.mid phys.hi -- adr len )
   push-hex
   <#
   dup  d# 24 >>  3 and  case                   ( phys.low phys.mid phys.hi )
      0  of  nip nip  convert-high  drop  endof  \ Configuration space
      1  of                                      \ I/O space
             nip swap            ( phys.hi phys.low )
	     u# u#s  drop        ( phys.hi )
             convert-rr          ( phys.hi )
             ascii i  ?tpn       ( )
      endof
      2  of					 \ Memory-32 space
             nip swap            ( phys.hi phys.low )
	     u# u#s  drop        ( phys.hi )
             convert-rr          ( phys.hi )
             ascii m  ?tpn       ( )
      endof
      3  of					 \ Memory-64 space
             -rot                ( phys.hi phys.low phys.mid )
	     # #s  2drop         ( phys.hi )
             convert-rr          ( phys.hi )
	     ascii x  ?tpn       ( )
      endof
   endcase
   0 u#> unit-string $save
   pop-base
;
