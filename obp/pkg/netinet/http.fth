\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: http.fth
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
id: @(#)http.fth 1.1 04/09/07
purpose: HTTP support
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 2616: Hypertext Transfer Protocol -- HTTP/1.1
\ RFC 2046: Multipurpose Internet Mail Extensions: Media Types

headerless

0         instance value    http-sockid
/insock   instance buffer:  http-srv-addr
/ip-addr  instance buffer:  http-server-ip
/ip-addr  instance buffer:  http-proxy-ip
0         instance value    http-server-port
0         instance value    http-proxy-port

\ Register the HTTP server and port. Use port 80 (decimal) as the
\ default port.
: http-init-server ( server$ -- )
   parse-hostport  http-server-ip inet-aton drop		( port$ )
   $dnumber if  IPPORT_HTTP  then  to http-server-port		( )
;

\ Register the HTTP proxy server and port. Use port 8080 (decimal) as
\ the default proxy port.
: http-init-proxy ( proxy$ -- )
   inaddr-any http-proxy-ip copy-ip-addr			( proxy$ )
   dup  if							( proxy$ )
      2dup check-htproxy$-form					( proxy$ )
      parse-hostport http-proxy-ip inet-aton drop		( port$ )
      $dnumber if  IPPORT_HTTP_ALT  then  to http-proxy-port	( )
   else								( null$ )
      2drop							( )
   then								( )
;

\ Is a proxy server in use?
: use-proxy? ( -- flag )  http-proxy-ip inaddr-any? 0=  ;

\ Issue an HTTP GET request. The absolute URI form must be used if 
\ the request is being made to a proxy. Since persistent connections
\ are the default with HTTP/1.1, we use the "close" connection option
\ to signal that a persistent connection is not required.

: http-send-request ( url$ -- )
   d# 512 dup alloc-mem swap >r >r			( url$ ) ( r: len adr )
   r@ 0							( url$ msg$ )
   " GET "				strcat		( url$ msg$ )
   use-proxy?  if					( url$ msg$ )
      2over				strcat		( url$ msg$ )
   else							( url$ msg$ )
      " /"				strcat		( url$ msg$ )
      2over parse-http-url 2drop	strcat		( url$ msg$ )
   then							( url$ msg$ )
   "  HTTP/1.1"r"n"			strcat		( url$ msg$ )
   " Host: "				strcat		( url$ msg$ )
   2swap parse-http-url 2swap 2drop	strcat		( msg$ )
   " "r"n"				strcat		( msg$ )
   " Connection: close"r"n"		strcat		( msg$ )
   " "r"n"				strcat		( msg$ )
   http-sockid -rot 0 sosend  drop			( )
   r> r> free-mem					( ) ( r: )
;

\ Incoming data is buffered before further processing since we may
\ need to peek at the data stream to determine the course of action. 

struct
   /n     field  >http-bufadr		\ Receive buffer address
   /l     field  >http-bufsize		\ Buffer size
   /l     field  >http-bufstart		\ Offset to start of data
   /l     field  >http-bufnbytes	\ Unread bytes in buffer
constant /http-inbuf

0      instance value    http-inbuf

\ Allocate receive buffer resources
: htbuf-alloc ( -- htbuf )
   /http-inbuf alloc-mem  >r
   h# 1000 dup alloc-mem  r@ >http-bufadr    !
                          r@ >http-bufsize   l!
   0                      r@ >http-bufstart  l!
   0                      r@ >http-bufnbytes l!
   r>
;

\ Get receive buffer address and size
: htbuf>adr,size ( htbuf -- adr size )
   dup >http-bufadr @  swap  >http-bufsize l@
;

\ Get address and size of unread data in receive buffer
: htbuf>data,len ( htbuf -- data len )
   dup >http-bufadr @  over >http-bufstart l@ ca+  swap  >http-bufnbytes l@
;

\ Check if the receive buffer is empty
: htbuf-empty? ( htbuf -- empty? )  >http-bufnbytes l@  0=  ;

\ Read data arriving on this socket.
: http-read-bytes ( adr len -- actual )  http-sockid -rot 0 sorecv ;

\ Read data into the buffer. Called only when the buffer is empty.
: htbuf-fill ( htbuf -- n )
   dup  htbuf>adr,size  http-read-bytes		( htbuf n )
   tuck  over >http-bufnbytes  l!		( n htbuf )
   0     swap >http-bufstart   l!		( n )
;

\ Read data from receive buffer, reading more data into the buffer
\ if it is empty.
: htbuf-read ( htbuf adr len -- #read )
   rot >r					( adr len ) ( r: htbuf )
   r@ htbuf-empty?  if				( adr len )
      r@ htbuf-fill 0=  if			( adr len )
         2drop r> drop 0 exit			( 0 )
      then					( adr len )
      show-progress				( adr len )
   then						( adr len )
   r@ htbuf>data,len				( adr len data n )
   2swap  rot min  dup >r  move  r>		( #read )
   r@ >http-bufnbytes  2dup l@ swap -  swap l!	( #read )
   r> >http-bufstart   2dup l@ +       swap l!	( #read )
;

\ Peek at next character in stream
: htbuf-peekchar ( htbuf -- char true | false )
   dup htbuf-empty?  if
      dup htbuf-fill 0=  if  drop false exit  then
   then
   htbuf>data,len drop  c@  true
;

\ Free receive buffer resources
: htbuf-free ( htbuf -- )
   dup  htbuf>adr,size free-mem  /http-inbuf free-mem
;

\ Each HTTP header line ends with a CRLF sequence which serves as the
\ end-of-line marker. But, HTTP/1.1 header field values can be folded 
\ onto multiple lines if the continuation line begins with a space 
\ or horizontal tab.

: is-space? ( char -- flag )  dup h# 20 =  swap  h# 09 =  or ;

: http-read-hdrline ( adr maxlen -- adr len )
   over >r  over ca+ swap				( end nxt ) ( r: adr )
   begin						( end nxt )
      2dup =  if  nip  r> tuck -  exit  then		( end nxt )
      http-inbuf over 1 htbuf-read 0=  if		( end nxt )
         nip  r> tuck -  exit				( adr len )
      then						( end nxt )
      dup c@ linefeed =  if				( end nxt )
         http-inbuf htbuf-peekchar  if			( end nxt char )
            is-space? 0=  if				( end nxt )
               nip  r> tuck -  exit			( adr len )
            then					( end nxt )
         then						( end nxt )
      else						( end nxt )
         dup c@ carret <>  if  ca1+  then		( end nxt' )
      then
   again
;

\ Return the next HTTP header line token. Words may be separated
\ by linear white space, or one of "," ";" or "=". The field value
\ may be quoted string.

: htnextfield ( $ -- rem$ tok$ )
   "  "t"r"n,=;" 					( $ delim$ )
   2swap 2over string-skipchars  dup if			( delim$ $' )
      over c@  ascii " =  if				( delim$ $' )
         1 /string  ascii " left-parse-string		( delim$ rem$ tok$ )
      else						( delim$ $' )
         2over strtok					( delim$ rem$ tok$ )
      then						( delim$ rem$ tok$ )
   else							( delim$ $' )
      null$						( delim$ rem$ null$ )
   then							( delim$ rem$ tok$ )
   2rot 2drop						( rem$ tok$ )
;

\ The HTTP response begins with a Status-Line and is followed by
\ message headers and a message body.
\
\ We expect a 2xx status code in the response status line, and process
\ the "Content-Length", "Content-Type" and "Transfer-Encoding" HTTP
\ message header fields. The message body may be a multipart message
\ and may have the "chunked" transfer encoding applied to it. 

0      instance value    http-transfer-length	\ Total message length
false  instance value    http-is-multipart?	\ Multipart message?
d# 72  instance buffer:  http-part-boundary	\ Multipart message boundary
0      instance value    http-bodypart-length	\ Current bodypart length
false  instance value    http-is-chunked?	\ Chunked transfer?

\ Process HTTP status line in the response.
: http-check-statusline ( $ -- )
   "  " strtok						( rem$ ver$ )
   2dup " HTTP/1.1" $= >r  2dup " HTTP/1.0" $=  r> or  0= if
      ." HTTP: Bad Version: " type cr  -1 throw
   then  2drop						( rem$ )
   "  " strtok						( msg$ code$ )
   2dup $dnumber if
      ." HTTP: Bad Status code: " type cr -1 throw
   then  nip nip					( msg$ code )
   dup d# 200 <>  if	
      ." HTTP: Bad Response: "  .d type cr -1 throw
   then							( msg$ code )
   3drop						( )
;

\ Get the size of the HTTP message body.
: http-content-length ( $ -- )
   htnextfield 2swap 2drop  $dnumber			( n false | true )
   if ." HTTP Content Length Invalid" -1 throw  then	( n )
   to http-transfer-length				( )
;

\ Process "Content-Type" field of HTTP message header. If this a multipart
\ message, get the boundary parameter value.
: http-content-type ( $ -- )
   htnextfield " multipart/mixed" $case=  0=  if  2drop exit  then
   htnextfield " Boundary"        $case=  0=  if
      ." Multipart Message Boundary not specified" -1 throw
   then
   htnextfield http-part-boundary pack drop  2drop
   true to http-is-multipart?
;

\ Get the transfer encoding applied to the message body.
: http-transfer-encoding ( $ -- )
   htnextfield 2swap 2drop  " chunked" $case=  to http-is-chunked?
;

\ Token table for HTTP message headers.
create http-headers
   " Content-Length"	false	['] http-content-length		token-handler,
   " Content-Type"	false	['] http-content-type		token-handler, 
   " Transfer-Encoding" false	['] http-transfer-encoding	token-handler,
   null$ 		0	0				token-handler,

\ Process HTTP message headers.
: http-process-headers ( -- )
   d# 1000 dup alloc-mem swap			( buf$ )
   2dup http-read-hdrline			( buf$ line$ )
   http-check-statusline			( buf$ )
   begin					( buf$ )
      2dup http-read-hdrline			( buf$ line$ )
   dup while					( buf$ line$ )
      ascii : left-parse-string			( buf$ value$ field$ )
      http-headers find-token-handler  if	( buf$ value$ xt )
         execute				( buf$ )
      else					( buf$ value$ )
         2drop					( buf$ )
      then					( buf$ )
   repeat  2drop				( buf$ )
   free-mem					( )
;

\ With chunked transfer encoding, the message body is split into one or
\ more "chunks". A chunk appears as 
\	chunk	=	chunk-size CRLF
\			chunk-data CRLF
\ The chunk-size field indicates the size (in hexadecimal) of the data 
\ in that chunk. The last chunk has a size of zero.

struct
   d# 80  field  >http-chunkline$	\ Buffer to read chunk-size lines
   /l     field  >http-chunk-nleft	\ Unread data in current chunk
constant /http-chunkinfo

0  instance value http-chunkinfo

\ Initialize structures to enable chunk decoding
: http-chunk-init ( -- htchunk )
   /http-chunkinfo dup alloc-mem  tuck swap erase
;

\ Free chunking data structures
: http-chunk-free ( htchunk -- )
   /http-chunkinfo free-mem
;

\ Get size of unread data in the current chunk
: htchunk-nleft@ ( -- n )  http-chunkinfo >http-chunk-nleft l@ ;

\ Update size of unread data in current chunk
: htchunk-nleft! ( n -- )  http-chunkinfo >http-chunk-nleft l! ;

\ Read chunk line (size of chunk or trailing CRLF)
: http-read-chunkline ( -- line$ )
   http-chunkinfo >http-chunkline$  d# 80  over 0  2swap  bounds  ?do
      http-inbuf i 1 htbuf-read 0=  ?leave
      i c@ linefeed =               ?leave
      i c@ carret <>  if  1+  then
   loop							( adr len )
;

\ Get size of next chunk
: http-read-chunksize ( -- n )
   http-read-chunkline  2dup  $hnumber  if
      ." HTTP: Bad Chunk Size " type cr  -1 throw
   then  nip nip					( n )
   dup htchunk-nleft!					( n )
;

\ Read chunk data. If all data from the previous chunk has been
\ processed, get the size of the new chunk before reading data.
\ If all data in the current chunk has been processed as a result
\ of this read, process the trailing CRLF as well.

: http-read-chunkdata ( adr len -- #read )
   htchunk-nleft@ 0=  if				( adr len )
      http-read-chunksize 0=  if			( adr len )
         2drop 0 exit					( 0 )
      then						( adr len )
   then							( adr len )
   http-inbuf -rot  htchunk-nleft@ min  htbuf-read	( #read )
   htchunk-nleft@ over -  htchunk-nleft!		( #read )
   htchunk-nleft@ 0=  if				( #read )
      http-read-chunkline 2drop				( #read )
   then							( #read )
;

\ Decode the chunked transfer-coding to get the message body contents.
: http-chunked-read ( adr len -- #read )
   over >r						( adr len ) ( r: adr )
   begin  dup  while					( nxt rem )
      2dup http-read-chunkdata  ?dup  if		( nxt rem n )
         tuck -  >r  ca+  r>				( nxt' rem' )
      else						( nxt rem )
         drop  r> -  exit				( #read )
      then						( nxt' rem' )
   repeat						( nxt' rem' )
   drop  r> -						( #read )
;

\ Read contents from an unencoded message body.
: http-unencoded-read ( adr len -- #read )
   over >r						( adr len ) ( r: adr )
   begin  dup  while					( nxt rem )
      2dup http-inbuf -rot htbuf-read ?dup  if		( nxt rem nread )
         tuck - >r ca+ r>				( nxt' rem' )
      else						( nxt rem )
         drop  r> - exit				( #read )
      then						( nxt' rem' )
   repeat						( nxt' rem' )
   drop r> -						( #read )
;

\ Read a block of data from the message body.
: http-read-body ( adr len -- #read )
   http-is-chunked?  if  http-chunked-read  else  http-unencoded-read  then
;

\ Processing body part headers of a multipart message.
\
\ Each body part of a multipart message is preceded by a boundary delimiter 
\ line, and the last one is followed by the closing boundary delimiter 
\ line. After its boundary delimiter line, the body part consists of a 
\ header area, a blank line, and a body area.
\
\ A boundary delimiter line is of the form "--<boundary>". A closing 
\ boundary delimiter line is of the form "--<boundary>--". The boundary 
\ string is specified in the "Content-Type" field in the HTTP header.
\
\ The "Content-Length" and "Content-Type" fields in the body part header 
\ lines provide the length and description of data contained in the 
\ body part.
\
\ Since the HTTP message body (which includes body parts of the multipart 
\ message) may be chunked, the transfer-coding must be decoded before 
\ reading body part header lines.

: http-part-content-length ( $ -- )
   htnextfield 2swap 2drop  $dnumber  if
      ." HTTP Bodypart Content Length Invalid" -1 throw
   then  to http-bodypart-length
;

: http-part-content-type ( $ -- )
   htnextfield 2swap 2drop				( type$ )
   2dup " application/octet-stream" $case=  0= if
      ." HTTP: Unexpected media type " type cr -1 throw
   then  2drop
;

\ Token table for body part header fields.
create http-part-headers
   " Content-Length"	false	['] http-part-content-length	token-handler,
   " Content-Type"	false	['] http-part-content-type	token-handler,
   null$ 		0	0				token-handler,

: http-process-boundary$ ( boundary$ -- closing-boundary? )
   over " --" comp 0<>	if
      ." HTTP: Missing Multipart Message Boundary" -1 throw
   then
   over 2+  http-part-boundary count comp 0<>  if
      ." HTTP: Multipart Message Boundary Mismatch" -1 throw
   then
   drop 2+ http-part-boundary count nip ca+ " --" comp 0=
;

\ Read next body part header line.
: http-read-part-hdrline ( adr maxlen -- adr len )
   over 0  2swap  bounds  ?do
      i 1 http-read-body 0=  ?leave
      i c@ linefeed =        ?leave
      i c@ carret <>  if  1+  then
   loop
;

\ Process body part header lines.
: http-process-part-headers ( -- )
   d# 80 dup alloc-mem swap				( buf$ )
   0 to http-bodypart-length				( buf$ )
   begin  2dup http-read-part-hdrline  dup 0=  while	( buf$ line$ )
      2drop						( buf$ )
   repeat						( buf$ boundary$ )
   http-process-boundary$ 0=  if			( buf$ )
      begin  2dup http-read-part-hdrline  dup while	( buf$ line$ )
         ascii : left-parse-string			( buf$ value$ field$ )
         http-part-headers find-token-handler if	( buf$ value$ xt )
            execute					( buf$ )
         else						( buf$ value$ )
            2drop					( buf$ )
         then						( buf$ )
      repeat  2drop					( buf$ )
   then							( buf$ )
   free-mem						( )
;

\ Establish a connection with the HTTP server. The server is accessed
\ via a proxy server if one was specified.

: http-init ( url$ proxy$ -- )
   http-init-proxy					( url$ )
   2dup check-httpurl$-form				( url$ ) 
   parse-http-url  2swap 2drop  http-init-server	( )

   http-srv-addr					( insock )
   use-proxy?  if					( insock )
      http-proxy-ip http-proxy-port			( insock proxyip,port )
   else							( insock )
      http-server-ip http-server-port			( insock srvip,port )
   then							( insock ipaddr,port )
   insock-init						( )

   AF_INET SOCK_STREAM 0 socreate  to http-sockid	( )
   http-sockid http-srv-addr /insock soconnect		( 0 | error# )
   0<>  if						( )
      http-sockid  http-srv-addr			( sockid insock )
      ." HTTP: Could not connect to " .insock .soerror	( )
      -1 throw
   then							( )

   htbuf-alloc      to http-inbuf			( )
   http-chunk-init  to http-chunkinfo			( )
;

\ Close HTTP connection and free resources.
: http-close ( -- )
   http-sockid soclose						( )
   http-inbuf htbuf-free  http-chunkinfo http-chunk-free	( )
;

[ifdef] DEBUG
: http-load ( adr url$ proxy$ -- )
   2over 2swap http-init				( adr url$ )
   http-send-request					( adr )
   http-process-headers					( adr )
   h# a00000 http-read-body				( size )
   http-close						( size )
;
[then]

headers
