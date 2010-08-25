\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: devtree.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
id: @(#)devtree.fth 3.23 06/02/16 19:19:51
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

headers
: get  ( acf -- value )  0 perform-action  ;
: set  ( value acf -- )  1 perform-action  ;
: decode  ( value acf -- adr len )  3 perform-action  ;
: encode  ( adr len acf -- true | value false )
   4 ['] perform-action  catch  if
      2drop 2drop true
   else
      false
   then
;

\ TODO
\ Don't use the system search order; use a private stack
\ $find searches through the private stack
\ Change names back from "regprop" to "reg", etc.
\ Either implement a true breadth-first search or don't specify it.

2 actions
action: drop context token@  ;
action: drop context token!  definitions  ;
create current-device  use-actions

: >node-offset ( apf -- addr )	@  current-device  >body >user +  ;

1 actions
action: >node-offset ;

transient

: (ufield) \ name ( offset size -- offset' )
  create over , +
;

: ufield  \ name  ( offset size -- offset' )
   (ufield) use-actions
;

resident

3 actions
action: >node-offset token@ execute ;
action: >node-offset token! ;
action: >node-offset ;

transient
: node-defer \ name ( offset -- offset' )
   /token (ufield) use-actions
;
resident

\ Notes for a more abstract searching mechanism:
\ Instead of the child and peer links in the device node, packages
\ with children have "search", "create", and "enumerate" methods.
\ To search a level, call that package's search method.  Those
\ methods probably need to work from a phandle, not an ihandle.

\  The 'check-user-size' below enables user space to grow on demand.

: unaligned-ualloc  ( size -- user# )
   check-user-size  #user @ swap #user +! ( user# )
;

struct  ( devnode )
/link #threads *  ufield  'threads	\ Package methods
dup					\ These fields will be "ualloc"ed
   /token  ufield  'child		\ Pointer to first child
   /token  ufield  'peer		\ Pointer to next peer
   /token  ufield  'properties		\ Pointer to properties vocabulary
   /n      ufield  '#adr-cells		\ Size of a parent address
   /n      ufield  '#buffers
   /n      ufield  '#values
   /token  ufield  'values
   /n      ufield  support-node?	\ is this a support node?
   /n      ufield  inherit-node-flags?  \ inherit parent props?
   node-defer	   (encode-unit)	\ encode-unit method
   node-defer	   (decode-unit)	\ decode-unit method
( starting-offset ending-offset )  swap -  ( size-to-ualloc )
constant /devnode-extra

headers
: >parent  ( node -- parent-node )  >voc-link  link@  ;

: push-package  ( phandle -- )  also  execute  definitions  ;
: pop-package  ( -- )  previous definitions  ;
: push-device  ( acf -- )  to current-device  ;

: pop-device  ( -- )
   current-device >parent    ( parent-voc )
   non-null?  if  push-device  then
;

\ Each package instance has its own private data storage area.
\ The data creation words "value", "variable", and "buffer:",
\ when used during compilation of a package, allocate memory
\ relative to a base pointer.  The package definition includes the
\ initial values for the words created with "value" and "variable".
\ When a package instance is created, memory is allocated for the
\ package's data and the portion used for values and variables is
\ initialized from the values stored in the package definition.
\
\ While the package is being defined (i.e. its code is being compiled),
\ a "dummy" instance is created with space for data, so that
\ data words may be used as soon as they are created.  The "dummy"
\ instance data area is given a "generous" default size (for 100 * cellsize
\ bytes of initialized data, 700 * cellsize for buffers).
\ Hopefully this won't be exceeded.

headerless
variable package-level  package-level off
variable next-is-instance  next-is-instance off
headers
variable instance-mode  instance-mode off
headerless
: instance?  ( -- flag )

\   \ Debugging code.  Keep this in until we have "sanitized" the drivers.
\   package-level @ 0<>  next-is-instance @ 0=  and  instance-mode @ and  if
\      ." Instance problem " where ??cr
\   then

   package-level @ 0<>  next-is-instance @   instance-mode @  or  and
   next-is-instance off
;
headers
: instance  ( -- )  next-is-instance on  ;
headerless

\ Now in machine code in obp/os/bootprom/sparc/instance.fth
\ : >instance-data  ( pfa -- adr )  @ my-self +  ;

: value#,  ( size -- adr )
   '#values @  dup ,   ( size offset )
   tuck + '#values !   ( offset )
   my-self +           ( adr )
;

headers
overload: value  \ name  ( initial-value -- )
   header noop   \  Will patch with (value)
;
headerless
3 actions
action:  >instance-data @  ;
action:  >instance-data !  ;
action:  >instance-data    ;

: (value)  ( initial-value -- )
   instance?  if
      create-cf use-actions  /n value#,
   else
      value-cf /n user#,
   then  ( value adr )
   !
; patch (value) noop value

\ Create fields which are present in every instance record.
\ "fixed instance value"

headers
transient
: fibuf:  \ name  ( offset -- offset' )
   create -1 na+ dup ,  ( offset' )
   use-actions
;
: fival:  \ name  ( offset -- offset' )
   create dup , na1+ ( offset' )
   use-actions
;
resident

headers
overload: buffer:  \ name  ( size -- )
   header noop  \ Will patch with (buffer:)
;

3 actions
action:  >instance-data    ;
action:  >instance-data !  ;
action:  >instance-data    ;

headerless
overload: (buffer:)  ( #bytes -- )
   instance?  if
      create-cf
      \ The address computation should use "#dalign round-up", but 
      \ #dalign (8) is defined later, in the "allocator" vocabulary.
      '#buffers @ swap 8 round-up -  dup  ,  '#buffers !  use-actions
   else
      (buffer:)
   then
; patch (buffer:) noop buffer:

headers
overload: variable  \ name  ( -- )
   header  noop \ Will patch with (variable)
;

3 actions
action:  >instance-data    ;
action:  >instance-data !  ;
action:  >instance-data    ;

headerless
: (variable)  ( -- )
   instance?  if
      create-cf use-actions  0 /n value#,  else  user-cf  0 /n  user#,
   then
   !
; patch (variable) noop variable

headers
overload: defer  \ name  ( -- )
   header noop \ Will patch with (defer)
;

3 actions
action:  >instance-data token@ execute  ;
action:  >instance-data token!  ;
action:  >instance-data token@  ;

headerless
: (defer)  ( -- )
   instance?  if
      create-cf  ['] crash /token  ( value data-size )
      use-actions  value#,
   else
     defer-cf  ['] crash /token    ( value data-size )
     user#,
   then                            ( value adr )
   token!
; patch (defer) noop defer

headers
\ Instance values that are automatically created for every package instance.

0
fival: my-adr0		\ F: First component of device probe address
fival: my-adr1		\ F: Intermediate component of device probe address
fival: my-adr2		\ F: Intermediate component of device probe address
fival: my-space 	\ F: Last component of device probe address
fival: frame-buffer-adr \ F: Frame buffer address.  Strictly speaking, this
                        \ should not be in every package, but we put it
                        \ here as a work-around for some old CG6 FCode
                        \ drivers whose selftest routines use frame-buffer-adr
                        \ for diagnostics mappings.  If frame-buffer-adr is
                        \ global, that would cause dual-cg6 systems to break.
fival: my-termemu
fival: interposed?	\ Was this instance interposed?
headerless
constant #fixed-vals
headers

0
fibuf: my-voc           \ Package definition (code) for this instance
fibuf: my-parent        \ Current instance just before this one was created
fibuf: my-args-adr      \ Argument string - base address
fibuf: my-args-len      \ Argument string - length
fibuf: my-unit-3	\ Fourth component of device instance address
fibuf: my-unit-2	\ Third  component of device instance address
fibuf: my-unit-1	\ Second component of device instance address
fibuf: my-unit-low	\ First  component of device instance address

headerless
constant #fixed-bufs

headers
: my-args  ( -- adr len )  my-args-adr my-args-len  ;

headerless
: allocate-instance  ( value-size variable-size -- )
   \ Allocate instance record
   my-self >r					( val-size var-size )
   tuck +  alloc-mem				( var-size base-adr )
   + is my-self					( )

   \ Set the fixed fields
   r> to my-parent				( )
   current-device  to my-voc			( )

   0 to my-args-len  0 to my-args-adr		( )  \ May be changed later
   0 to interposed?				( )
   0 to my-unit-low  0 to my-unit-1             ( )
   0 to my-unit-2    0 to my-unit-3             ( )
;

: initial-values  ( -- adr )  'values token@  ;

\ Returns the address of the initial value of the named instance data.
: (initial-addr)  ( adr -- adr' )    my-self -  initial-values +  ;
: initial-addr  \ name  ( -- addr )
   [compile] addr
   state @  if  compile (initial-addr)  else  (initial-addr)  then
; immediate

headers
: copy-args  ( args-adr,len -- )
   dup  if
      dup alloc-mem to my-args-adr          ( args-adr,len )
      to my-args-len                        ( args-adr )
      my-args-adr my-args-len move          ( )
   else
      2drop
   then
;

\ my-self points to a position in the middle of the instance record.
\ Initialized data ("values") is at positive offsets from my-self,
\ and uninitialized data ("variables" and "buffers") is at negative offsets.
: new-instance  ( args-adr args-len -- )
   '#values @  '#buffers @ negate  allocate-instance

   \ Copy in the initialized data
   initial-values  my-self  '#values @  move  ( args-adr args-len )

   copy-args
;

headerless
: deallocate-instance  ( value-size variabled-size -- )
   my-args-len  if  my-args-adr my-args-len free-mem  then
   my-self  my-parent is my-self   ( val-size var-size self )
   over -                          ( val-size var-size base-adr )
   -rot  +  free-mem               ( )
;

\ Destroy instance has the side effect of setting my-self to the parent
\ of the node that is being destroyed.  This prevents my-self from referring
\ to a non-existent instance.

headers
: destroy-instance  ( -- )
   also  my-voc execute               ( )
   '#values @  '#buffers @  negate    ( value-size variable-size )
   previous                           ( value-size variable-size )
   deallocate-instance
;

headerless
\ When creating a package definition, we initialize the buffer
\ (unitialized data) allocation pointer and the value (initialized data)
\ allocation pointer.

\ Size of the buffer that is used as the instance data when the package
\ is being created.  This allows variables, buffers, and values to be
\ used while the package is being created.

: initial-sizes  ( -- value-size variable-size )
   d# 100 /n*  d# 700 /n*
;

: extend-package  ( -- )
   next-is-instance off
   1 package-level +!  initial-sizes  allocate-instance
;

: allot-package-data  ( -- )
   acf-align here dup 'values token!  '#values @ dup allot  erase
;
: finish-package-data  ( -- )
   \ Copy the initialized data into the dictionary and set up the
   \ pointer to it.
   '#values @  if  allot-package-data  then
   my-self  initial-values  '#values @  move            ( )

   initial-addr frame-buffer-adr off
   initial-addr my-termemu       off

   initial-sizes deallocate-instance                    ( )
   package-level @ 1- 0 max package-level !
;

\ Internal factor used to implement first-child and next-child
: set-child?  ( link-adr -- flag )
   get-token?  if  push-device true  else  false  then
;

\ Interface to searching code in breadth.fth:
: first-child  ( -- another? )  'child set-child?  ;
: next-child   ( -- another? )  'peer  pop-device  set-child?  ;

\ Removes the voc-link field from the most-recently-created vocabulary
: erase-voc-link  ( -- )
   voc-link  link@ >voc-link link@  voc-link link!
   /link na1+ negate allot
;

\ Creates an unnamed vocabulary
: (vocabulary)  ( -- )
   ['] acf-align is header
   vocabulary
   ['] (header) is header

   erase-voc-link
;

: allocate-node-record  ( -- )
   \ Allocate user (RAM) space for  properties, "last" field, children, peers
   /devnode-extra  unaligned-ualloc drop

   lastacf  push-device           ( parent's-child-field )
;
: init-properties  ( -- )  (vocabulary)  lastacf 'properties token!  ;

headerless

\ this was moved from finddev because the encode/decode unit recovery
\ mechanism needs it, and in order to only complain once about missing
\ methods and to accelerate the device tree parsing these were moved here.

2variable saved-method$
variable  saved-method-package
defer no-proc ' true is no-proc	\ definition requires forward references..

: setup-method$ ( adr len phandle -- adr len phandle )
   >r r@ saved-method-package !				( adr len )
   2dup saved-method$ 2!				( adr len )
   r>							( adr len phandle )
;
headers

: current-properties  ( -- )  'properties token@  ;

: $vexecute?  ( adr len voc-acf -- true | ??? false)
   (search-wordlist)  if  execute false  else  true  then
;

: $vexecute  ( adr len voc-acf -- ?? )  $vexecute? drop  ;

\ Used during compilation (probing), when the search order includes
\ the current vocabulary as well as the parent vocabularies.
: get-property  ( name-adr,len -- true | value-adr,len false )
   current-properties $vexecute?
;
headerless
: #adr-cells  ( -- n )
   " #address-cells" get-property  if  2  else  get-encoded-int  then
;

\ this routine will only execute once per node, unless the device tree
\ changes (via cd, device-end or finish-device) it looks up the static
\ acf for the encode/decode method substituting the default 2cell form
\ and complaining once, if the method does not exist.
: (lookup-method) ( ? ? def-acf ptr method$ -- ? ? )
   current-device setup-method$ (search-wordlist) if ( ? ? def-acf ptr acf )
      >r					( ? ? default-acf ptr )
      nip					( ? ? ptr )
   else						( ? ? default-acf ptr )
      swap >r					( ? ? ptr )
      no-proc					( ? ? ptr -2 )
      2 #adr-cells tuck				( ? ? ptr -2 n 2 n )
      <> swap 0<> and if  throw  else drop then	( ? ? ptr )
      diagnostic-mode? if			( ? ? ptr )
         ??cr ." Notice: " abort-message type cr
      then					( ? ? ptr )
   then						( ? ? ptr )
   r> tuck swap					( ? ? acf acf ptr )
   set						( ? ? acf )
   execute					( ? ? )
;

\ Moved from findev.fth because the device tree depends upon
\ encode-unit and decode-unit, and because some cards are missing those
\ methods and we have to workaround them this becomes a fundamental part
\ of the device tree operation now.

create bad-number ," Bad number syntax"
: safe->number  ( adr len -- n )  $hnumber  if  bad-number throw  then  ;

headers

: parse-int  ( adr len -- n )  dup  if  safe->number  else  2drop 0  then  ;

: parse-2int  ( adr len -- address space )
   ascii , left-parse-string     ( after-str before-str )
   parse-int  >r                ( after-str )
   parse-int  r>                ( address space )
;

headerless

: (encode-2ints) ( l h -- adr,len )  swap <# u#s drop ascii , hold u#s u#> ;

: lookup-decode-unit ( unit$ -- pa.lo .. pa.hi )
   ['] parse-2int ['] (decode-unit) " decode-unit" (lookup-method)
;

: lookup-encode-unit ( pa.lo .. pa.hi -- unit$ )
   ['] (encode-2ints) ['] (encode-unit) " encode-unit" (lookup-method)
;

\ reset the current device cached encode/decode methods
: reset-xxcoders ( -- )
   ['] lookup-decode-unit is (decode-unit)
   ['] lookup-encode-unit is (encode-unit)
;

: init-node  ( #address-cells -- )
   allocate-node-record

  '#adr-cells !
  'child      !null-token      \ No children yet
  'peer       !null-token      \ Null peer

   #fixed-vals  '#values    !  \ Initialize data sizes
   #fixed-bufs  '#buffers   !

   'values    !null-token      \ No initial data values yet

   init-properties

   0 support-node? !			\ Not a support node by default
   true inherit-node-flags? !		\ inherit by default
   reset-xxcoders 
;

: link-to-peer  ( parent's-child-field -- )
   dup token@ 'peer token!             ( parent's-child-field )
   current-device  swap token!         ( )
;
: device-node?  ( voc -- flag )
   voc-link  begin  another-link?  while        ( voc link )
      2dup voc>  =  if  2drop false exit  then  ( voc link )
      >voc-link
   repeat                                       ( voc )
   drop true
;

headers

: new-node  ( -- )
   (vocabulary)  current-device link,  ( )  \ Up-link to parent device

   \ Save parent linkage address on stack for later use
   inherit-node-flags? @               ( in? )
   support-node? @  over and	       ( in? support? )
   'child                              ( in? support? parent's-child-field )
   #adr-cells init-node                ( in? support? parent's-child-field )
   link-to-peer                        ( in? support? )
   support-node? !                     ( in? )
   inherit-node-flags? !               (  )
;

: new-device   ( -- )  new-node  extend-package  ;

: device-end   ( -- )
   \ The false will be patched later with device-context?
   false if  reset-xxcoders  then
   only forth also definitions  package-level off
;

: my-#adr-cells  ( -- n )
   my-self  if	\ Use current instance's package if there is a current instance
      my-voc also execute  '#adr-cells @  previous
   else		\ Otherwise use the active package
      '#adr-cells @
   then
;

\ my-address applies to the current instance, regardless of whether or
\ not the active package corresponds to the current instance, thus it must
\ use my-#adr-cells, which explicitly refers to the current instance's
\ package.

: my-address  ( -- phys.lo .. )
   addr my-adr0  my-#adr-cells 1- 1 max /n* bounds  ?do  i @  /n +loop
;
: my-unit  ( -- phys.lo .. )
   addr my-unit-low  my-#adr-cells /n* bounds  ?do  i @  /n +loop
;

vocabulary root-node
   erase-voc-link  null link,   \ Root has no parent
   0 init-node
   allot-package-data
device-end

: root-device  ( -- )  only forth also  ['] root-node push-device  ;

: finish-device  ( -- )  reset-xxcoders  finish-package-data  pop-device  ;

\ The magic-device-types vocabulary contains words whose names are the
\ same as the names of the device_type property values that we wish to
\ recognize as special cases.  "device_type" in the "magic-properties"
\ vocabulary searches this vocabulary every time that a "device_type"
\ property is created, and executes the corresponding word if a match
\ is found.  That word may look at the property name and value on the
\ stack, but it must not remove them.  However, it might wish to alter
\ the value!

vocabulary magic-device-types

\ The magic-properties vocabulary contains words whose names are the
\ same as the names of properties that we wish to recognize as special
\ cases.  "property" searches this vocabulary every time that an
\ property is created, and executes the corresponding word if a match
\ is found.  That word may look at the property name and value on the
\ stack, but it must not remove them.  However, it might wish to alter
\ either the name or the value!

vocabulary magic-properties
also magic-properties definitions
: device_type  ( value-str name-str -- value-str name-str )
   2over get-encoded-string  ['] magic-device-types  $vexecute
;
previous definitions


\ The parameter field of a property word contains:
\    offset size
\ Offset is the 32-bit positive distance from the beginning of the
\ property-encoded byte array to the parameter field address.  size is the
\ 16-bit size of the property value array.  This representation depends on
\ the fact that property-encoded arrays are stored in the dictionary.

headerless
: make-property-name  ( name-adr,len -- )
   current token@ >r current-properties current token!
   ['] $header behavior >r
   ['] ($header) to $header
   $create
   r> to $header
   r> current token!
;

headers
5 actions
action:  dup dup unaligned-l@ l->n -  swap la1+ w@  ;
action:  ( adr,len apf -- )
   tuck la1+ w!                 ( adr apf )
   dup rot - swap unaligned-l!  (  )
;
action:  ;
action:  drop  ;
action:  drop  ;

: (property)  ( value-adr,len  name-adr,len  -- )
   2dup  ['] magic-properties  $vexecute          ( value-str name-str )
   2dup current-properties (search-wordlist)  if  ( value-str name-str acf )
      nip nip  set                                ( )
   else                                           ( value-str name-str )
      make-property-name                          ( value-str )
      here rot -  l,  w,  align use-actions       ( )
   then                                           ( )
;

: property  ( value-adr,len  name-adr,len  -- )
   my-self if
      context token@ >r my-voc execute
      (property)
      r> context token!
   else
      (property)
   then
;

: delete-property  ( name-adr,len -- )
   current-properties (search-wordlist)  if
      >link current-properties  remove-word
   then
;
overload: forget  \ name  ( -- )
   current token@  device-node?  abort" Can't forget device methods"
   forget
;

headerless
: get-unit  ( -- true | adr len false )  " reg" get-property  ;

: unit-str>phys-  ( adr len -- phys.hi .. phys.lo )
   '#adr-cells @  0  ?do  decode-int -rot  loop  2drop   ( phys.hi .. phys.lo )
;

: reorder  ( xn .. x1 n -- x1 .. xn )  0  ?do  i roll  loop  ;

: unit-str>phys  ( adr len -- phys.lo .. phys.hi )
   unit-str>phys-           ( phys.hi .. phys.lo )
   '#adr-cells @  reorder   ( phys.lo .. phys.hi )
;
headers
