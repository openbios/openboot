\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: clientif.fth
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
id: @(#)clientif.fth 1.18 04/01/28
purpose: 
copyright: Copyright 1993-2002, 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
only forth also definitions

\
\ Access to Client Interface Arguments
\

defer carg@  ( adr -- n )
defer carg!  ( n adr -- )
defer carga+ ( adr n -- adr+n*cells )
defer /carg  ( -- #cells )
defer /carg* ( n -- n*cells )

: cif-32 ( -- )
   ['] l@  to carg@
   ['] l!  to carg!
   ['] la+ to carga+
   ['] /l  to /carg
   ['] /l* to /carg*
;

64\ : cif-64 ( -- )
64\    ['] x@  to carg@
64\    ['] x!  to carg!
64\    ['] xa+ to carga+
64\    ['] /x  to /carg
64\    ['] /x* to /carg*
64\ ;

cif-32

headerless

0 value cif-struct
: #cargs  ( -- n )  cif-struct 1 carga+ carg@  ;
: #crets  ( -- n )  cif-struct 2 carga+ carg@  ;

: service-name  ( -- adr,len )  cif-struct carg@ cscount  ;
: args-adr      ( -- arg-n )  cif-struct 3 carga+  ;

: is-cif-function?  ( adr,len -- false | acf +-1 )
   ['] client-services behavior (search-wordlist)
;

headers transient
\ 
\ NOTE:
\	Don't define client service methods using the old way any longer.
\	the old way being:
\		also client-services definitions headers caps @ caps on
\		: SUNW,failed ( -- failed? ) true ;
\		previous definitions headerless caps !
\ 
\	Now you can define this same routine by simply:
\		cif: SUNW,failed ( -- failed? ) true ;
\ 
\
\ this method takes the pain out of flipping the case sensitivity of a CIF
\ call and also ensures the method goes into the correct vocabulary.
\ 
\ It works by recording the current headers/headerless and caps state,
\ then setting then appropriately, moving to client-services and calling ':'
\ to create the word, then we restore the original state again.
\ 
: cif: \ name of headered routine with case sensitive name
   headerless? dup >r if headers then
   also client-services definitions
   caps @ >r caps off : r> caps ! r> if headerless then
   previous definitions
;
resident headerless

\
\  Client Interface Handler
\

headers
forth also definitions

defer cif-enter-hook ' noop is cif-enter-hook
defer cif-error-hook ' noop is cif-error-hook
defer cif-exit-hook  ' noop is cif-exit-hook
: .cif(  ( -- )
   ??cr dup .name  ." ( "  #cargs  0  ?do  #cargs i -  pick .x  loop  ." -- "
;
: ).cif  ( -- )
   dup  if
      ." Error "
   else
      #crets  0  ?do  #crets  i -  pick  .x  loop
   then
   ." )" cr
;
: verbose-cif  ( -- )
   ['] .cif(  to cif-enter-hook
   ['] ).cif  to cif-exit-hook
;
: silent-cif  ( -- )
   ['] noop  to cif-enter-hook
   ['] noop  to cif-exit-hook
;

: do-cif  ( adr  -- result )
   dup is cif-struct

   \ Push arguments on the stack
   #cargs  if
      args-adr  #cargs 1- /carg*  bounds  swap  do
	 i carg@  /carg negate
      +loop
   then

   service-name  is-cif-function?  if   ( args.. acf )
      cif-enter-hook                    ( args.. acf )
      catch 0<>                         ( rets.. error? )
      cif-exit-hook
   else                                 ( args.. )
      cif-error-hook true               ( args.. error )
   then                                 ( rets.. error? )

   >r
   \ Pop results from the stack
   args-adr  #cargs carga+  #crets /carg*  bounds
   ?do  i carg!  /carg +loop
   r>
;

\ Support functions for client interface services
headerless

: copy-out  ( len,buf adr len1 -- len1 )
   dup >r                    ( len,buf adr,len1 )  ( r: len1 )
   2swap swap                ( adr len1 buf,len )  ( r: len1 )
   rot min cmove             ( )   ( r: len1 )
   r>
;

: setnode  ( nodeid | 0 -- )
   dup 0=  if  drop ['] root-node  then  also execute
;

: options?  ( -- flag )  'properties token@  ['] options  =  ;

: null?  ( cstr -- flag )  dup  if  c@ 0=  else  drop true  then  ;

: str>cstr  ( adr len -- cstr )
   tuck cstrbuf swap cmove  cstrbuf +  0 swap c!  cstrbuf
;
: &link>cstr  ( alf -- acf cstr true |  nullstr false )
   another-link?  if                  ( acf )
      dup >name name>string str>cstr  ( acf cstr )
      true                            ( acf cstr true )
   else                               (  )
      nullstring  false               ( cstr false )
   then
;
false value canonical-properties?
d# 32 buffer: canon-prop
: $canonical-property  ( cstr -- adr len )
   cscount
   canonical-properties?  if  d# 31 min canon-prop $save 2dup lower  then
;
: find-property  ( cstr -- adr len false | acf true )
   $canonical-property
   2dup current-properties (search-wordlist)  dup  if  2swap 2drop  then
;
: first-property  ( -- cstr )
   current-properties  >threads  &link>cstr  if  nip  then
;


: next-property  ( cstr -- cstr )
   find-property  if                     ( acf )

      \ Get the next property that has not been superceded by a
      \ later redefinition of the same name.

      begin                                 ( acf )
	 dup  >name n>link  &link>cstr  if  ( acf acf' cstr )
	    rot drop                        ( acf' cstr )
	    \ Check to see if this is the most recent
	    \ version of the property with this name.

	    dup find-property  if           ( acf' cstr acf" )
	       rot tuck  <>                 ( cstr acf" deleted? )
	    else                            ( acf' cstr name$ )
	       2drop swap false             ( cstr acf' false )
	    then                            ( cstr acf" deleted? )
	 else                               ( acf nullstr )
	    \ There are no more firmware-defined configuration variables;
	    \ find the first user-created environment variable
	    2drop                           ( )
            options?  if                    ( )
               null$ next-env-var str>cstr  ( cstr )
            else                            ( )
               nullstring                   ( cstr )
            then                            ( cstr )
            exit
	 then                               ( cstr acf" deleted? )
      while                                 ( cstr acf" )

	 \ The property returned by "find-property" has
	 \ a different acf than the one we're looking at,
	 \ even though they have the same name.  We conclude
	 \ that the one we're looking at has been superceded,
	 \ and go back to try the next one.

	 nip                             ( acf" )
      repeat                             ( cstr acf )
      drop                               ( cstr )
   else                                  ( name$ )
      \ The input string is not a firmware-defined configuration
      \ variable; perhaps it is a user-created environment variable
      options?  if                       ( name$ )
         next-env-var str>cstr           ( cstr )
      else                               ( name$ )
         2drop nullstring                ( cstr )
      then                               ( cstr )
   then                                  ( nullstr | cstr )
;

\ .cstr defined in fm/lib/util.fth
\ : .cstr  ( cstr -- )  begin  dup c@ ?dup  while  emit 1+  repeat  drop  ;

\
\ Generic Client Interface Services
\

only forth  ( also hidden  also forth )  also client-services  definitions
headers
cif: ci-properties  ( -- )  true  to canonical-properties?  ;

cif: cs-properties  ( -- )  false to canonical-properties?  ;

cif: test  ( service-name -- missing? )  cscount  is-cif-function?  0=  ;

cif: test-method ( method-cstr phandle -- missing? )
   >r cscount r>  find-method  if  drop  false  else  true  then
;

cif: child  ( phandle -- phandle' )
   setnode                           ( )
   0  'child                         ( last-nodeid &next-nodeid )
   begin  get-token?  while          ( last-nodeid next-nodeid )
      nip  dup execute               ( next-nodeid )
      'peer                          ( last-nodeid' &next-nodeid )
   repeat                            ( last-nodeid' )
   previous                          ( nodeid )
;

cif: peer  ( phandle -- phandle' )
   dup 0=  if
      drop ['] root-node exit
   then                              ( nodeid )

   dup  ['] root-node =  if
      drop 0  exit
   then                              ( nodeid )

   \ Select the first child of our parent
   dup >parent also execute          ( nodeid )
   'child token@ execute             ( nodeid )

   dup current-device  =  if         ( nodeid )
      \ Argument node is first child of parent; return "no more nodes"
      drop 0                         ( 0 )
   else                              ( nodeid )
      \ Search for the node preceding the argument node
      begin                          ( nodeid )
         'peer token@ 2dup  <>       ( nodeid next-nodeid flag )
      while                          ( nodeid next-nodeid )
         push-device                 ( nodeid )
      repeat                         ( nodeid )
      2drop current-device           ( nodeid' )
   then                              ( nodeid | 0 )
   previous                          ( nodeid | 0 )
;

cif: parent  ( phandle -- phandle' )
   dup ['] root-node =  if   ( root-phandle )
      drop 0 exit                    ( 0 )
   then                              ( parent-phandle )
   >parent
;

\ cif-buf passes client's buffer adr,len to the property 'get' routine
\ non-zero len and non-zero adr indicates this is a getprop and the
\ contains the adr,len. A non-zero len and zero adr indicates this 
\ is a getproplen so that the property 'get' routine can optimise.
\ This mechanism is relied upon by the 'translations' property. 
2variable cif-buf  0 0 cif-buf 2!

cif: getproplen  ( cstr phandle -- len )
   setnode find-property  if                   ( acf )
      0 -1 cif-buf 2!                          ( acf )
      >r r@ get r> decode nip                  ( len )
      0 0 cif-buf 2!                           ( len )
   else                                        ( name$ )
      options?  if                             ( name$ )
         get-env-var  if  -1  else  nip  then  ( len | -1 )
      else                                     ( name$ )
         2drop -1                              ( -1 )
      then                                     ( len | -1 )
   then                                        ( len | -1 )
   previous                                    ( len | -1 )
;

cif: instance-to-package  ( ihandle -- phandle )  ihandle>phandle  ;

cif: getprop  ( len,buf cstr phandle -- size )
   setnode find-property  if                              ( len,buf acf )
      >r 2dup swap                                        ( len,buf buf,len )
      2dup erase                                          ( len,buf buf,len )
      cif-buf 2!                                          ( len,buf )
      r@ get r> decode                                    ( len,buf adr,len1 )
      copy-out                                            ( len1 )
      0 0 cif-buf 2!                                      ( len1 )
   else                                                   ( len,buf name$ )
      options?  if                                        ( len,buf name$ )
         get-env-var  if                                  ( len,buf )
           2drop -1                                       ( -1 )
         else                                             ( len,buf name$ )
           2over swap erase                               ( len,buf name$ )
           copy-out                                       ( len )
         then                                             ( len|-1 )
      else                                                ( len,buf name$ )
         2drop 2drop -1                                   ( -1 )
      then                                                ( len|-1 )
   then                                                   ( len|-1 )
   previous                                               ( len|-1 )
;

cif: nextprop  ( buf prev phandle -- 0|1 )
   setnode                           ( buf prev-cstr )
   dup null?  if                     ( buf prev-cstr )
      drop  first-property           ( buf first-cstr )
   else                              ( buf prev-cstr )
      next-property                  ( buf next-cstr )
   then                              ( buf cstr )
   previous                          ( buf cstr )

   over >r                           ( buf cstr ) ( r: buf )
   cscount 1+                        ( buf adr,len )
   rot swap cmove                    ( cstr )
   r> null?  if  0  else  1 then     ( 0|1 )
;

cif: setprop  ( len buf name phandle -- error|len' )
   setnode find-property  if            ( buf-len buf-adr acf )
      >r swap  1-  0 max                ( buf-adr buf-len )
      r@ encode  if                     ( )
         r> drop  -1                    ( -1 )
      else                              ( encoded-value )
         r@ set  r@ get r> decode       ( adr len )
         nip                            ( len' )
      then                              ( len|-1 )
   else                                 ( buf-len,adr name$ )
      options?  if                      ( buf-len,adr name$ )
         2swap swap 2swap  put-env-var  ( len|-1 )
      else                              ( buf-len,adr name$ )
         2drop 2drop -1                 ( -1 )
      then                              ( len|-1 )
   then                                 ( len|-1 )
   previous
;

cif: finddevice  ( cstr -- phandle )  cscount  locate-device ?dup drop  ;
cif: instance-to-path  ( len,buf ihandle -- len' )
   >r 2dup swap erase r>
   ihandle>devname  copy-out
;

cif: instance-to-interposed-path ( len,buf ihandle -- len' )
   >r 2dup swap erase r>
   ihandle>devpath copy-out
;

cif: package-to-path   ( len,buf phandle -- len' )
   >r 2dup swap erase r>
   phandle>devname  copy-out
;

cif: call-method  ( arg-P .. ihandle cstr -- res-Q ... res-1 catch-result )
   cscount  rot ['] $call-method catch
;

cif: call-static-method  ( arg-P .. phandle cstr -- res-Q ... res-1 result )
   cscount  rot ['] $call-static-method catch
;

cif: open    ( cstr -- ihandle )  cscount  open-dev  ;

cif: close   ( ihandle -- )  close-dev  ;

cif: read    ( len,addr ihandle -- len' )
   >r swap  " read" r>  ['] $call-method  catch if
      2drop 3drop -1
   then			( -1|#read )
;

cif: write   ( len,addr ihandle -- len' )
   >r swap  " write" r>  ['] $call-method  catch if
      2drop 3drop -1
   then			( -1|#written )
;

cif: seek    ( low,high ihandle -- status )
   " seek" rot  ['] $call-method  catch if	( d.offset adr len nodeid )
       2drop 3drop -1
   then			( -1|0|1)
;

\ set-symbol-lookup is defined in os/sun/symdebug.fth

cif: milliseconds ( -- )  get-msecs   ;

cif: execute-buffer ( adr len -- )  'execute-buffer execute  ;

also forth definitions
alias child child	\ Make visible outside the client-services package
alias peer peer		\ Make visible outside the client-services package

only forth also definitions

headerless
d# 32 buffer: nextprop-cstr
headers
overload: next-property ( prev$ phandle -- false | next$ true )
   current-device >r
   setnode                                  ( prev$ )
   nextprop-cstr dup d# 32 erase            ( prev$ cstr )
   swap cmove  nextprop-cstr dup null?  if  ( prev-cstr )
      drop  first-property                  ( first-cstr )
   else                                     ( prev-cstr )
      next-property                         ( next-cstr )
   then                                     ( cstr )
   previous                                 ( cstr )
   dup null?  if  2drop false  else  cscount  true  then
   r> push-device
;

