\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: instance.fth
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
id: @(#)instance.fth 2.59 02/08/20
purpose: Create, destroy, and call package instances
copyright: Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Creation and destruction of device instances.  Also package interface words.

defer fm-hook  ( adr len phandle -- adr len phandle )
' noop is fm-hook
: find-method  ( adr len phandle -- false | acf true )
   fm-hook  (search-wordlist)
;

: "open"  " open"  ;
: $call-self  ( adr len -- )
   my-voc  setup-method$  fm-hook  $vexecute?  if  no-proc throw  then
;

[ifndef] package(
transient
: )package-macro ( -- )  r> is my-self ;
: package(-macro ( ihandle -- ) my-self >r is my-self ;
resident
macro: package( package(-macro
macro: )package )package-macro
[then]

: call-package  ( ??? acf ihandle -- ??? )      package( execute    )package  ;
: $call-method  ( ??? adr len ihandle -- ??? )  package( $call-self )package  ;
: $call-parent  ( adr len -- ) my-parent package( $call-self )package ;
: (skip-interposed) ( -- )
   begin interposed? while my-parent is my-self repeat
;

: ihandle>phandle  ( ihandle -- phandle )
   package(  (skip-interposed) my-voc )package
;

: $call-static-method  ( ??? adr len phandle -- ??? )
   setup-method$ find-method  0=  if  no-proc throw  then  execute
;

\ set-args is executed only during probing, at which time the active package
\ corresponds to the current instance, thus '#adr-cells can be executed
\ directly.

: set-args  ( arg-str reg-str -- )
   current-device >r pop-device (decode-unit) r> push-device
   '#adr-cells @  ( arg-str phys .. #cells )
   dup  if  swap  to my-space  1-   then       ( arg-str phys .. #cells' )
   addr my-adr0  swap /n* bounds  ?do  i !  /n +loop   ( arg-str )
   copy-args
;

: get-package-property  ( adr len phandle -- true | adr' len' false )
   also execute  get-property  previous
;

\ Used when executing from an open package instance.  Finds a property
\ associated with the current package.
: get-my-property  ( adr len -- true | adr' len' false )
   my-voc get-package-property
;

headerless
0 value interposer	\ phandle of interposing package, if any
0 value ip-arg-adr	\ arguments for interposing package
0 value ip-arg-len

\ Internal factor of get-inherited-property.  This factoring is necessary
\ because we use "exit" to make the control flow easier.
: (get-any)   ( adr len -- true | adr' len' false )
   begin  my-self   while            ( adr len )  \ Search up parent chain
      my-voc  current token!         ( adr len )
      2dup get-my-property  0=  if   ( adr len adr' len' )
         2swap 2drop false exit      ( adr' len' false )   \ Found
      then                           ( adr len )
      my-parent is my-self           ( adr len )
   repeat                            ( adr len )
   2drop true                        ( true )              \ Not found
;

headers
\ Finds a property associated with the current package or with one of
\ its parents.
: get-inherited-property  ( adr len -- true | adr' len' false )
   current token@ >r   my-self >r
   (get-any)
   r> is my-self  r> current token!
;

headerless
: try-close  ( -- )  " close"  ['] $call-self  catch  if  2drop  then  ;
headers
: close-package  ( ihandle -- )
   package( try-close destroy-instance )package
;
headerless
: close-parents  ( -- )
   begin  my-self  while  try-close destroy-instance  repeat
;
: close-chain  ( -- )  destroy-instance  close-parents  ;
headers
: close-dev  ( ihandle -- )  package(  close-parents  )package  ;

\ Extract the next (leftmost) component from the path name, updating the
\ path variable to reflect the remainder of the path after the extracted
\ component.
: parse-component  ( path$ -- path$ args$ devname$ )
   ascii / left-parse-string      ( path$' component$ )
   ascii : left-parse-string      ( path$ args$ devname$ )
   dup 0=  if  2drop  " /"  then  ( path$ args$ devname$' )
;

: apply-method  ( adr len -- no-such-method? )
   my-voc setup-method$
   fm-hook  ['] $vexecute?  catch  ?dup  if	( x x x errno )
      \ executing method caused an error
      nip nip nip				( errno )
   then						( ??? false | true | errno )
;

headerless

d# 64 buffer: package-name-buf

headers

: my-unit-bounds  ( -- end-adr start-adr )
   addr my-unit-low  '#adr-cells @ /n*  bounds
;
: set-my-unit  ( phys.hi .. phys.lo -- )
   my-unit-bounds  ?do  i !  /n +loop
;

: set-default-unit  ( -- )
   get-unit  0=  if  unit-str>phys- set-my-unit  then
;
\ Set the my-unit fields in the instance record:
\ If an address was given in path component, use it
\ If not, use address in "reg" property of package
\ Otherwise, use 0,0
: set-instance-address  ( -- )
   unit#-valid?  if
      unit-bounds  ?do  i @  /n +loop  set-my-unit
   else
      set-default-unit
   then
;

headerless
: (apply-method)  ( adr len -- ??? )
   apply-method  if  close-chain no-proc throw  then    ( )
;
: (open-node)  ( -- )
   "open"  (apply-method)  0=  if          ( okay? )
      close-chain  p" open failed" throw   ( )
   then
;

: encode-bytes+  ( adr1 len1  adr2 len2  --  adr1 len1+len2 )
   encode-bytes encode+
;

: encode-number+  ( u adr,len -- adr,len' )
   base @ >r hex
   rot  (u.)  encode-bytes+
   r> base !
;

: make-node-alias  ( nodeid name-str -- )
   current-device >r				( nodeid name-str )
   rot push-device				( name-str )
   pwd$						( name-str expansion-str )
   r> push-device				( name-str expansion-str )
   $devalias					(  )
;

: (append-args) ( arg$ base$ -- base$' )
   2 pick if					( arg$ base$ )
      " :" 2swap $add				( arg$ base$' )
   then						( arg$ base$ )
   $add						( base$ )
;

: (ihandle>path) ( no-interpose? str,len -- allow-interpose? str,len' )
   recursive
   2 pick if (skip-interposed) then			( flag str,len )
   my-parent  if					( flag str,len )
      my-parent	package( (ihandle>path)	)package	( flag str,len )
      my-voc push-device				( flag str,len )
      interposed? if " %"  else  " /"  then		( flag str,len' sep$ )
      2swap $add					( flag str,len' )
      (append-name)					( flag str,len' )
      support-node? @ if exit then			( flag str,len )
      2>r my-unit 2r> (append-unit)			( flag str,len' )
      my-args 2swap (append-args)			( flag str,len' )
   then							( flag str,len )
;

overload: (ihandle>path) ( ihandle flag -- str,len )
   current-device my-self 2>r			( ihandle flag )
   swap is my-self				( flag )
   "temp 0 (ihandle>path)			( flag str,len )
   2r> is my-self push-device rot drop		( str,len )
;

headers
\ ihandle>devname returns the device tree nodes for this ihandle
: ihandle>devname ( ihandle -- adr,len )	1 (ihandle>path) ;

\ ihandle>devpath returns the full instance path, including interposed packages
: ihandle>devpath ( ihandle -- adr,len )	0 (ihandle>path) ;

: phandle>devname ( phandle -- adr,len )
   current-device >r				( phandle )  ( r: phandle' )
   push-device  pwd$				( adr,len )  ( r: phandle' )
   r> push-device				( adr,len )
;

: open-node  ( -- ) recursive
   (open-node)
   interposer  if
      interposer  0 to interposer  push-package
      ip-arg-adr ip-arg-len new-instance true is interposed? open-node
      pop-package
   then
;

: interpose  ( args$ phandle -- )
   to interposer  to ip-arg-len  to ip-arg-adr
;

headerless

: (no-proc) ( -- )
   " Unimplemented procedure '" "temp pack >r		( )
   saved-method$ 2@ r@ $cat				( )
   saved-method-package @ dup if			( )
      " ' in " r@ $cat  phandle>devname			( str,len )
   else							( )
      drop " '"						( str,len )
   then r@ $cat						( )
   r> count						( str,len )
   set-abort-message -2					( -2 )
; 
\ Resolve the forward references to no-proc
' (no-proc) is no-proc

: open-parents  ( parent-phandle end-phandle -- )   recursive
   \ Exit at null "parent" of root node
   2dup =  if  2drop exit  then

   over >parent swap  open-parents  ( phandle )

   push-device                      (  )
   " "  new-instance                (  )
   set-default-unit                 (  )
   open-node                        (  )
;

\ Open packages between, but not including, "phandle" and the active package
: select-node  ( path$ -- path$' )
   current-device >r
   parse-component                          ( path$ args$ devname$ )
   noa-find-device                          ( path$ args$ )
   current-device dup  >parent  r> open-parents  ( path$ args$ my-phandle )
   push-device                              ( path$ args$ )
   new-instance                             ( path$ )
   set-instance-address                     ( path$ )
;

\ Open pathname components until the last one, and then apply the indicated
\ method to the last component.
: open-path  ( path$ -- )
   ?dup  if                                              ( path$ )
      \ Establish the initial parent
      null to current-device                             ( path$ )
      0 to interposer
      ?expand-alias  select-node                         ( path$ )
      begin  dup  while  open-node select-node  repeat   ( path$' )
      2drop                                              (  )
   else                                                  ( adr )
      not-found throw                                    (  )
   then                                                  (  )
;

headers
: open-package  ( args$ phandle -- ihandle )
   push-package                              ( args$ )
   new-instance                              ( )
   "open" apply-method  if  false  then  if  (  )
      my-self  my-parent is my-self          ( ihandle )
   else                                      (  )
      destroy-instance  0                    ( 0 )
   then                                      ( ihandle )
   pop-package                               ( ihandle )
;

: find-package  ( name$ -- false  |  phandle true )
   dup 0=  if  true  else  over c@  ascii / <>  then  ( name$ relative? )
   if                                                 ( name$ )
      " /packages/" package-name-buf pack  $cat       ( )
      package-name-buf count                          ( name$' )
   then                                               ( name$' )
   locate-device  0=                                  ( false | phandle true )
;

: $open-package  ( arg$ name$ -- ihandle )
   find-package  if  open-package  else  2drop 0  then
;

headers

: begin-open-dev  ( path$ -- ihandle )
   0 package(  current-device >r

      \ Since "catch/throw" saves and restores my-self,
      \ my-self will be 0 if a throw occurred.

      ['] open-path catch  if  2drop  then
      my-self                                   ( ihandle )

   r> push-device  )package                     ( ihandle )
;

headerless

: (open-dev)  ( path$ -- )  open-path  open-node  ;

headers

: open-dev  ( adr len -- ihandle | 0 )
   0 package(  current-device >r

      \ Since "catch/throw" saves and restores my-self,
      \ my-self will be 0 if a throw occurred.

      ['] (open-dev) catch  if  2drop  then
      my-self                                   ( ihandle )

   r> push-device  )package                     ( ihandle )
;

headerless

: (execute-method)  ( path$ method$ -- false | ??? true )
   2swap  open-path  (apply-method)
;

headers

: execute-device-method  ( path$ method$ -- false | ??? true )
   0 package(  current-device >r       ( path$ method$ )
      ['] (execute-method)  catch  if  ( x x x x )
         2drop 2drop  false            ( false )
      else                             ( ??? )
         close-chain  true             ( ??? true )
      then                             ( false | ??? true )
      device-end                       ( false | ??? true )
   r> push-device  )package            ( false | ??? true )
;

\ Easier to use version of execute-device-method
\
\ ex:  apply  selftest  net
\
: apply ( -- ??? ) \ method { devpath | alias }
   safe-parse-word  safe-parse-word  ( method$ devpath$ )
   2swap  execute-device-method      ( ??? success? )
   0= abort" apply failed."          ( ??? )
;


h# 10 circular-stack: istack

\ select-dev opens a package, sets my-self to that ihandle, pushes the
\ old my-self on the instance stack, and pushes that package's vocabulary
\ on the search order.  unselect-dev undoes select-dev .

: iselect  ( ihandle -- )
   dup 0= abort" Can't open device"  ( ihandle )
   my-self istack push  is my-self
   also my-voc  push-device
;
: select-dev  ( adr,len -- )  open-dev  iselect  ;
: begin-select-dev  ( adr,len -- )   begin-open-dev  iselect  ;
: end-select-dev  ( -- )
   previous definitions
   my-parent  istack pop is my-self  close-dev
;

: select  ( "name" -- )  safe-parse-word select-dev  ;
: begin-select  ( "name" -- )  safe-parse-word begin-select-dev  ;

: unselect-dev  ( -- )
   previous definitions
   my-self  istack pop is my-self  close-dev
;

: begin-package  ( arg-str reg-str parent-str -- )
   select-dev  new-device  set-args
;

: end-package  ( -- )  finish-device  unselect-dev  ;

: (execute-phandle-method)  ( method-adr,len phandle -- ??? )
   0 to unit#-valid?              ( method-adr,len phandle )
   dup >parent null open-parents  ( method-adr,len phandle )
   push-device                    ( method-adr,len )
   " "  new-instance              ( method-adr,len )
   set-default-unit               ( method-adr,len )
   (apply-method)                 ( ???? )
;

headers
: open-phandle  ( phandle -- ihandle | 0 )
   0 package(                   ( phandle )
      current-device >r         ( phandle )
      0 to unit#-valid?         ( phandle )
      null ['] open-parents catch  if  ( x x error-code )
         3drop  0               ( 0 )
      else                      (   )
         my-self                ( ihandle )
      then                      ( ihandle | 0 )
      r> push-device            ( ihandle | 0 )
   )package                     ( ihandle | 0 )
;

: execute-phandle-method  ( method-adr,len phandle -- false | ??? true )
   0 package(                                  ( method-adr,len phandle )
      current-device >r                        ( method-adr,len phandle )
      ['] (execute-phandle-method)  catch  if  ( method-adr,len phandle err-code )
         3drop false                           ( false )
      else                                     ( ??? )
         close-chain true                      ( ??? true )
      then                                     ( false | ??? true )
      r> push-device                           ( false | ??? true )
   )package                                    ( false | ??? true )
;

: create-dev-instance (  arg$ phandle -- ihandle )
   my-self >r                            			( arg$ phandle ) 
   dup >parent open-phandle to my-self   			( )
   push-package new-instance set-instance-address pop-package	( )
   my-self r> to my-self                 			( ihandle ) 
;

: destroy-dev-instance ( ihandle -- )
   my-self >r to my-self		( )
   destroy-instance my-self close-dev	( )
   r> to my-self			( )
;

: .path  ( ihandle -- ) dup if ihandle>devname type cr else drop then ;

headerless
