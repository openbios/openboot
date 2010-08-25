id: @(#)device-props.fth 1.9 05/10/12
purpose: PCI bus package
copyright: Copyright 1994 FirmWorks  All Rights Reserved
copyright: Copyright 2005 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

\ All the code in this file executes as a child of a PCI device
\ and so my-space is valid and config-X $call-parent (parent-X)
\ accesses must be used.

: vid,did ( -- ven-id dev-id )  0 parent-l@ lwsplit ;

: svid,ssid ( -- subven-id subsys-id ) subsystem-base parent-l@ lwsplit ;

: rev-id ( -- n )  8 parent-w@ ;

: class-code  ( -- n )  8 parent-l@ 8 rshift  ;

\ Traverse capability list looking for PCI-Express capabilities
: pcie-capability-regs ( -- pointer | 0 )
   h# 34 parent-b@
   begin  dup  while
      dup parent-w@  wbsplit  swap h# 10 =  if
         drop exit
      else
         nip
      then
   repeat
;

\ Create properties reflecting standard configuration header information

: int16-property ( phys.hi name$ -- )  2>r  parent-w@  2r> integer-property  ;
: int8-property  ( phys.hi name$ -- )  2>r  parent-b@  2r> integer-property  ;

: ?int16-property  ( phys.hi name$ -- )
   2>r parent-w@  ?dup if  2r> integer-property  else  2r> 2drop  then
;

\ Create properties common to PCI and PCIE.
: make-basic-function-properties ( -- )
   0  " vendor-id"   int16-property
   2  " device-id"   int16-property
   8  " revision-id" int8-property

   header-type 1 <>  if		\ Not a PCI-PCI bridge
      subsystem-base					( offset )
      dup " subsystem-vendor-id"  ?int16-property
      2+  " subsystem-id"         ?int16-property
   then

   class-code  " class-code"  integer-property

   h# 3d parent-b@  ?dup  if				( intr )
      dup " interrupts" integer-property		( intr )
      my-space swap " assign-int-line" $call-parent	( line#,true | false )
      if  h# 3c parent-b!  then				( )
   then							( )
;

: make-pci-specific-properties ( -- )
   header-type 1 <>  if
      card-bus? if
         \ cardbus requires that we set the PRIMARY bus number.
         my-space cfg>bus# h# 18 parent-b!
      else
         h# 3e  " min-grant"   int8-property
         h# 3f  " max-latency" int8-property
      then
   then

   \ Per Solaris/OBP agreement (see psypci.c, simba.c), set cache line size
   \ and latency timer. By setting them this early, we get full PCI speed
   \ during boot, solving bugid 4346844. See also bugids 1234181 and 1235094.
   \
   \ If variations on either value are needed, they can be changed via nvramrc
   \ script, and the Solaris PCI nexi will respect the changed properties.

   h# 10 h# 0c tuck parent-b! " cache-line-size" int8-property
   h# 40 h# 0d tuck parent-b! " latency-timer"   int8-property

   6 parent-w@					( int )
   dup 9 rshift 3 and      " devsel-speed"       integer-property
   dup 7 rshift 1 and  if  " fast-back-to-back"  boolean-property  then
   dup 6 rshift 1 and  if  " udf-supported"      boolean-property  then
       5 rshift 1 and  if  " 66mhz-capable"      boolean-property  then
;

[ifndef] RELEASE
: create-port-type-property ( -- )		\ XXX DEBUG ONLY XXX
   pcie-capability-regs 2 +  parent-w@  4 >>  h# f and
   case
      0  of  " PCIE-Endpoint"         endof
      1  of  " Legacy-PCIE-Endpoint"  endof
      4  of  " Root-Port"             endof
      5  of  " Upstream-Port"         endof
      6  of  " Downstream-Port"       endof
      7  of  " PCIE-PCI/PCIX-Bridge"  endof
      8  of  " PCI/PCIX-PCIE-Bridge"  endof
      ( default )  " Other"  rot
   endcase
   encode-string " port-type" property
;
[then]

: make-pcie-specific-properties ( -- )
[ifndef] RELEASE
   create-port-type-property			\ XXX DEBUG ONLY XXX
[then]
;

: pci-make-function-properties  ( -- )
   make-basic-function-properties
   pci-express? 0=  if
      make-pci-specific-properties
   else
      make-pcie-specific-properties
   then
;

fload ${BP}/dev/pci/generic-names.fth
fload ${BP}/dev/pci/compatible-prop.fth

\ If a generic name cannot be found, create a name of the form pciVVVV,DDDD 
\ unless subdevice subvendor IDS exist in which case use them instead.
\
: name-property-value ( -- adr len )
   pci-express?  if
      vid,did
   else
      svid,ssid 2dup or  0=  if  2drop vid,did  then 
   then
   ascii-vendev-id
;

: make-name-property  ( -- )
   class-code unknown-class?  if  name-property-value  then
   encode-string  " name" property
;

: class-property-value  ( -- adr len )
   push-hex  class-code <# u# u# u# u# u# u# " class" $hold u#> pop-base
;

\ Create standard properties for functions with no fcode drivers
: make-std-fcode-properties ( -- )
   make-name-property
   make-compatible-property
   make-reg-property
;
