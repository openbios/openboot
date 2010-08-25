id: @(#)make-device.fth 1.7 05/10/12
purpose: PCI bus package
copyright: Copyright 1994 FirmWorks  All Rights Reserved
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.


\ ---------------------------------------------------------------------
\ All routines loaded from here assume we are executing in the child
\ node of a pci bus device.
\ any references to my-space are only valid for such children.
\ and all routines executing in this context will use the parent-X words.
\
\ Routines that are used in both contexts will leave phys.hi on the
\ data stack and won't do $call-<anything>  the routine not-relocatable?
\ is an example of such a routine.
\

: parent-l!  ( l phys.hi -- )   my-space + $config-l! $call-parent  ;
: parent-b@  ( phys.hi -- b )   my-space + $config-b@ $call-parent  ;
: parent-b!  ( b phys.hi -- )   my-space + $config-b! $call-parent  ;
: parent-w@  ( phys.hi -- b )   my-space + $config-w@ $call-parent  ;
: parent-w!  ( w phys.hi -- )   my-space + $config-w! $call-parent  ;
: parent-l@  ( phys.hi -- l )   my-space + $config-l@ $call-parent  ;
: parent-l!  ( l phys.hi -- )   my-space + $config-l! $call-parent  ;

: not-relocatable?  ( phys.hi -- flag )  h# 80 ss#>cfg and  0<>  ;

: header-type ( -- type ) h# 0e parent-b@ h# 7f and ;

\ True if the header type indicates that the function is a PCI-PCI bridge
: bridge?  ( -- flag )   
   header-type h# 1 = h# 0a parent-w@ h# 0609 =  or 
;

\ True if the header type indicates that the funtion is a PCI-Cardbus
: card-bus? ( -- flag )  header-type  h# 2 =  ;

: expansion-rom  ( -- offset )
   header-type h# 1 =  if  h# 38  else  h# 30   then
;

: subsystem-base ( -- offset )
   card-bus? if  h# 40  else  h# 2c  then
;

: base-register-bounds  ( -- high low )
   bridge?  if  h# 18  else
      card-bus?	if  h# 14  else  h# 28  then
   then
   h# 10
;

: io? ( phys.hi -- flag ) cfg>ss# 1 = ;

false value pci-express?	\ Set by each call to populate-device-node 

fload ${BP}/dev/pci/probe-reg.fth
fload ${BP}/dev/pci/device-props.fth
fload ${BP}/dev/pci/fcode-rom.fth

: load-fcode  ( adr len -- )
   >r >r r@  1 byte-load  r> r> free-mem
;

: populate-device-node  ( -- )
   pcie-capability-regs 0<> to pci-express?
   pci-make-function-properties
   assign-addresses				( )
   find-fcode? if				( adr len )
      load-fcode true				( )
   else						( )
      no-builtin-fcode?  if
         make-std-fcode-properties false	( false )
      else					( )
         true					( true )
      then					( flag )
   then						( flag )
   make-assigned-property			( )
   
   device-enabled? 0= bridge? 0= and if
      \ Disables all card response
      0 4 parent-w!
   then
;
