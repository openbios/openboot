\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: uriparse.fth
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
id: @(#)uriparse.fth 1.1 04/09/07
purpose: URI parsing routines
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 2396: Uniform Resource Identifiers (URI): Generic Syntax
\ RFC 3617: URI Scheme for TFTP

headerless

\ Check if this is an URI. Only "://" forms are accepted.
: is-uri? ( $ -- flag )  " ://" strstr ;

\ Extract URI scheme name
: uri>scheme ( uri$ -- scheme$ )
   ascii : left-parse-string  2swap 2drop
;

\ Split URI into component parts
: parse-uri ( uri$ -- file$ server$ scheme$ )
   ascii : left-parse-string  2swap  2 /string		( scheme$ $ )
   ascii / left-parse-string  2rot			( file$ srv$ scheme$ )
;

\ Split server string into component parts (host and port)
: parse-hostport ( server$ -- port$ host$ )
   ascii : left-parse-string
;

\ Server must be specified as an IP address
: check-host$-form ( host$ -- )
   inet-addr if  ." Illegal IP address"  -1 throw  else  drop  then
;

\ Port must be a decimal number
: check-port$-form ( port$ -- )
   $dnumber if  ." Illegal port number"  -1 throw  else  drop  then
;

\ Check syntax in server specification
: check-server$-form ( server$ -- )
   parse-hostport					( port$ host$ )
   check-host$-form					( port$ )
   dup if  check-port$-form  else  2drop  then		( )
;

d# 256  instance buffer:  htunescape-buf

\ Decode %xx escaped characters in a URI component.
: htunescape ( adr len -- buf buflen false | true )
   htunescape-buf 0  2swap			( buf 0 adr len )
   begin  dup  while				( buf n adr len )
      over c@  ascii % =  if			( buf n adr len )
         1 /string  dup 2 <  if			( buf n adr' len' )
            2drop 2drop true exit		( true )
         then					( buf n adr' len' )
         2dup 2 min $hnumber  if		( buf n adr' len' )
            2drop 2drop true exit		( true )
         then					( buf n adr' len' char )
         >r  2 /string  r>			( buf n adr' len' char )
      else					( buf n adr len )
         over c@ >r  1 /string  r>		( buf n adr' len' char )
      then					( buf n adr' len' char )
      >r  2over ca+  r> swap c!			( buf n adr' len' )
      2swap 1+ 2swap				( buf n' adr' len' )
   repeat  2drop false				( buf n' false )
;

\ Check escape encoding in file path
: check-file$-form ( $ -- )
   htunescape if  ." Incorrect escape encoding" -1 throw  else  2drop  then
;

\ HTTP URL syntax
\   http_URL = "http://" host [ ":" port ] [ path ]

: is-http-url? ( $ -- flag )
   2dup is-uri? if  uri>scheme " http" $case=  else  2drop false  then
;

: parse-http-url ( url$ -- file$ server$ )  parse-uri 2drop ;

: check-httpurl$-form ( url$ -- )
   parse-http-url  check-server$-form  check-file$-form 
;

\ TFTP URI syntax
\   tftpURI = "tftp://" host "/" [ file [ mode ] ]
\   mode    = ";"  "mode=" ( "netascii" / "octet" )

: is-tftp-uri? ( $ -- flag )
   2dup is-uri? if  uri>scheme " tftp" $case=  else  2drop false  then
;

: parse-tftp-uri ( uri$ -- mode$ file$ server$ )
   parse-uri  2drop  2swap  ascii ; left-parse-string  2rot
;

: tftpuri>srv ( uri$ -- host$ )
   parse-tftp-uri  2swap 2drop  2swap 2drop
;

\ Escape decoding has to be applied for filenames in TFTP URIs
: tftpuri>file ( uri$ -- file$ )
   parse-tftp-uri  2drop 2swap 2drop  2dup htunescape 0=  if
      2swap 2drop
   then
;

: check-tftp-mode$ ( mode$ -- )
   " mode=octet" $case= 0=  if  ." Invalid TFTP transfer mode" -1 throw  then
;

: check-tftpuri$-form ( tftpuri$ -- )
   parse-tftp-uri					( mode$ file$ host$ )
   check-host$-form					( mode$ file$ )
   check-file$-form					( mode$ )
   dup if  check-tftp-mode$  else  2drop  then		( )
;

\ Check HTTP proxy syntax
: check-htproxy$-form ( proxy$ -- )
   2dup ['] check-server$-form catch  if
      2drop ."  in HTTP proxy " type cr  -1 throw
   then  2drop
;

: (check-uri$-form) ( uri$ -- )
   2dup is-http-url?  if
      check-httpurl$-form
   else
      2dup is-tftp-uri?  if
         check-tftpuri$-form
      else
         ." Unknown URI scheme" -1 throw
      then
   then
;

\ Check URI syntax. Print out URI along with any error message
: check-uri$-form ( uri$ -- )
   2dup ['] (check-uri$-form) catch  if
      2drop  ."  in "  type cr  -1 throw
   then  2drop
;

headers
