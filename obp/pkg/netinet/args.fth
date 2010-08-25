\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: args.fth
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
id: @(#)args.fth 1.1 04/09/07
purpose: Network boot support package argument processing
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ Get next comma delimited argument. Used for old style argument processing.
: arg-nextfield ( $ -- rem$ field$ )  ascii , left-parse-string ;

\ Get next argument. Arguments are separated by commas and may consist
\ of a single key or a key=value pair. Commas may appear in the value
\ field if the value is a quoted string. 
: arg-nextparam ( args$ -- rem$ value$ key$ )
   " ," string-skipchars  dup 0=  if			( args$' )
      null$ null$ exit
   then							( args$' )
   2dup 0 -rot bounds ?do				( args$' 0 )
      i c@  dup  ascii , =  swap ascii = =  or  if
         drop  i c@  leave
      then
   loop							( args$' delim )
   dup >r  left-parse-string 2swap  r>			( key$ $ delim )
   ascii = <>  over 0=  or  if				( key$ $ )
      null$ 2rot exit					( rem$ value$ key$ )
   then							( key$ $ )
   over c@  ascii " =  if				( key$ $ )
      2dup  1 /string  ascii " left-parse-string	( key$ $ $' val$ )
      2swap dup  if					( key$ $ val$ $' )
         over c@  ascii , =				( key$ $ val$ $' ok? )
      else						( key$ $ val$ $' )
         2over ca+ c@  ascii " =			( key$ $ val$ $' ok? )
      then  nip nip  					( key$ $ val$ ok? )
      0=  if						( key$ $ val$ )
         ." Bad quoted string '" 2swap type  ." '"  cr  -1 throw
      then						( key$ $ val$ )
      nip 2+ string-split				( key$ rem$ value$ )
   else							( key$ $ )
      ascii , left-parse-string				( key$ rem$ value$ )
   then							( key$ rem$ value$ )
   2rot							( rem$ value$ key$ )
;

: set-inet-addr ( ip$ adr -- )  inet-aton 0= throw ;
: get-dnumber   ( $ -- n )      $dnumber throw ;

: set-hostip       ( ip$ -- )    my-ip-addr     set-inet-addr ;
: set-subnet-mask  ( ip$ -- )    my-netmask     set-inet-addr ;
: set-router       ( ip$ -- )    router-ip      set-inet-addr ;
: set-tftp-server  ( ip$ -- )    tftp-server-ip set-inet-addr ;

: set-hostname     ( name$ -- )  hostname   pack drop ;

\ Client identifiers may be specified either as the ASCII hexadecimal
\ representation of the identifier, or as a quoted string. The identifier
\ specified here is used, without any transformations, as the client 
\ identifier in DHCP transactions and in the WANboot HTTP request 
\ query string.

: (set-client-id) ( $ -- invalid? )
   over c@  ascii " =  if					( $ )
      qdstring>string  dup 2 MAX_CID_LEN between  if		( cid$ )
         client-id pack drop  false				( false )
      else							( $ )
         2drop true						( true )
      then							( invalid? )
   else								( $ )
      dup 2 mod 0=  over 2/  2 MAX_CID_LEN between  and  if	( $ )
         hexascii-to-octet  dup if				( cid,len )
            client-id pack drop  false				( false )
         else							( $ )
            2drop true						( true )
         then							( invalid? )
      else							( $ )
         2drop true						( true )
      then							( invalid? )
   then								( invalid? )
;

: set-client-id ( $ -- )  (set-client-id) throw ;

\ Boot file URIs must be "safe-encoded". URIs containing commas are 
\ presented as quoted strings. Replace all occurences of "\" or "|" 
\ with "/".
: set-boot-file ( $ -- )
   qdstring>string  bootfile pack count  2dup bounds ?do
      i c@ dup  ascii \ =  swap ascii | =  or  if  ascii / i c!  then
   loop
   2dup is-uri? if  check-uri$-form  else  2drop  then
;

\ HTTP proxy server specification.
: set-http-proxy ( proxy$ -- )
   2dup  check-htproxy$-form  http-proxy pack drop
;

: set-dhcp-retries ( $ -- )  get-dnumber to dhcp-max-retries ;
: set-tftp-retries ( $ -- )  get-dnumber to tftp-max-retries ;

: arg=protocol? ( $ -- flag )
   2dup  " rarp" $= >r  2dup " bootp" $= >r  " dhcp" $=  r> r>  or or
;

\ Process protocol argument. "bootp" is treated as a synonym of "dhcp".
: process-protocol-arg ( $ -- )
   2dup " bootp" $=  if  2drop " dhcp"  then		( strategy$ )
   config-strategy pack drop				( )
;

\ Key table for handling arguments specifying configuration parameters
create cfgparam-args
   " file"		true	['] set-boot-file	token-handler,
   "host-ip"		true	['] set-hostip		token-handler,
   "router-ip"		true	['] set-router		token-handler,
   "subnet-mask"	true	['] set-subnet-mask	token-handler,
   "client-id"		true	['] set-client-id	token-handler,
   "hostname"		true	['] set-hostname	token-handler,
   "http-proxy"		true	['] set-http-proxy	token-handler,
   "dhcp-retries"	true	['] set-dhcp-retries	token-handler,
   "tftp-retries"	true	['] set-tftp-retries	token-handler,
   null$ 		0	0			token-handler,

: (process-argument) ( value$ key$ xt -- )
   >r 2swap r> catch if
      2drop ." Improperly formatted value for '" type ." '"  cr -1 throw
   else
      2drop
   then
;

: process-argument ( value$ key$ -- )
   2dup cfgparam-args find-token-handler 0=  if		( value$ key$ )
      ." Unknown key '" type ." '" cr  2drop exit	( )
   then							( value$ key$ xt )
   3 pick 0=  if					( value$ key$ xt )
      drop ." Missing value for '" type ." '" cr -1 throw 
   then							( value$ key$ xt )
   (process-argument)					( )
;

\ Process arguments specified in the new-style syntax.
\    [protocol,] [key=value,]*
\
\ When the key=value style syntax is used, absence of the protocol
\ parameter implies manual configuration.

: newstyle-args? ( args$ -- flag )  ascii = strchr 0<> ;

: process-newstyle-args ( args$ -- )
   " manual" config-strategy pack drop		( args$ )
   begin  dup  while				( args$ )
      arg-nextparam  2dup arg=protocol?  if	( rem$ null$ protocol$ )
         2swap 2drop  process-protocol-arg	( rem$ )
      else					( rem$ value$ key$ )
         process-argument			( rem$ )
      then					( rem$ )
   repeat  2drop				( )
;

\ Process arguments specified in (old-style) positional parameter syntax. 
\   [dhcp|bootp|rarp,][server-ip],[filename],[client-ip],[router-ip],
\       [boot-retries],[tftp-retries],[subnet-mask]

: ?arg-nextfield ( $ -- rem$ field$ true | rem$ false )
   arg-nextfield dup if  true  else  2drop false  then
;

: process-oldstyle-args ( args$ -- )
   2dup arg-nextfield  2dup arg=protocol?  if		( args$ $ protocol$ )
      process-protocol-arg  2swap 2drop			( $ )
   else							( args$ $ arg$ )
      2drop 2drop					( rem$ )
   then							( rem$ )
   ?arg-nextfield  if
      "tftp-server"  ['] set-tftp-server (process-argument)
   then
   ?arg-nextfield  if  " file"         process-argument  then
   ?arg-nextfield  if  "host-ip"      process-argument  then
   ?arg-nextfield  if  "router-ip"    process-argument  then
   ?arg-nextfield  if  "dhcp-retries" process-argument  then
   ?arg-nextfield  if  "tftp-retries" process-argument  then
   ?arg-nextfield  if  "subnet-mask"  process-argument  then
   2drop
;

\ Manual configuration requires that the client be provided with (at the
\ minimum) its own IP address, address of the boot server and the name
\ of the bootfile. Hence, the argument must be in URI form. URI syntax
\ would have been validated already - the code here verifies that the
\ file component in the URI has been specified.

: (check-manual-config-args) ( -- ok? )
   my-ip-addr inaddr-any?  if				( )
      false exit					( false )
   then							( )
   bootfile count dup if				( $ )
      2dup is-uri?  if					( $ )
         parse-uri  2drop 2drop nip 0<>			( ok? )
      else						( $ )
         2drop false					( false )
      then						( ok? )
   else							( null$ )
      2drop false					( false )
   then							( ok? )
;

: check-manual-config-args ( -- )
   ['] (check-manual-config-args)  catch if
      ." Manual Configuration: "
      ." Host IP, boot server and filename must be specified" cr
      -1 throw
   then
;

\ Process package arguments specified either on the command line or in
\ 'network-boot-arguments'. If any argument is specified on the command 
\ line, all arguments in 'network-boot-arguments' are ignored.

: process-args ( $ -- )
   dup 0=  if							( null$ )
      2drop  " network-boot-arguments" get-option-string	( args$ )
   then								( args$ )
   dup 0=  if  2drop exit  then					( args$ )
   2dup newstyle-args?  if					( args$ )
      process-newstyle-args					( )
      config-strategy count " manual" $=  if			( )
         check-manual-config-args 				( )
      then							( )
   else								( args$ )
      process-oldstyle-args					( )
   then								( )
;

headers
