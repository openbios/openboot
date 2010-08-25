\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: dload.fth
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
id: @(#)dload.fth 1.14 01/05/29
purpose: 
copyright: Copyright 1990-2001 Sun Microsystems, Inc.  All Rights Reserved

\ Diagnostic loading feature.  Directly loads a named file using TFTP,
\ instead of first loading the boot file that the server provides.
\ Also reads the symbol table if it is present.
\ The server must be configured for "non-secure" tftp; i.e. the tftp
\ daemon must be started without the "-s" flag.  See /etc/inetd.conf

headerless
: $strcat ( src$ dest$ -- dest+src$ )
   rot			( src dest dlen slen )
   2dup + >r		( src dest dlen slen )	( r: tlen )
   -rot			( src slen dest dlen )	( r: tlen )
   over >r		( src slen dest dlen )	( r: tlen dest )
   ca+			( src slen dest+dlen )	( r: tlen dest )
   swap cmove		(  )			( r: tlen dest )
   r> r>		( dest tlen )
   2dup ca+ 0 swap c!	( dest+src$ )
;
d# 256 buffer: dload-buf
: (dload$) \ filename ( load-adr -- name$ )
   cleanup
   is load-base  optional-arg$		( name$ )
   strip-blanks				( name$ )
   ?dup 0=  if				( adr )
      p" "r"nUsage: <load-address> dload <filename> [ <args> ] "r"n"
      throw
   then					( name$ )
;

headers
: $dload-read ( name$ dev$ -- )
   2swap					( dev$ name$ )
   \ Replace every  '/'  with  '|'
   \ because arguments cannot include '/'s.
   2dup bounds  ?do
      i c@ ascii /  =  if  ascii | i c!  then
      i c@ bl = ?leave
   loop  2swap					( name$ dev$ )

   \ Expand the device alias and stash it away
   ?expand-alias dload-buf pack count		( name$ alias$ )		

   \ Get arguments to the network device (the last component of the
   \ the device path) and format the argument list as follows:
   \ - Add a ':' to the path if it isnt specified in the devalias
   \ - If device arguments are present, and if the last argument
   \   is "dhcp" or "bootp" without a trailing comma, add one.
   \ - Append ',<filename>' at the end

   ascii / split-after 2drop			( name$ node$ )
   ascii : split-before 2drop			( name$ devargs$ )
   dup 0=  if
      2drop " :" dload-buf $cat
   else
      + 4 - 4 2dup " dhcp" $=  -rot " bootp" $= or  if
         " ," dload-buf $cat
      then
   then	
   " ," dload-buf $cat  dload-buf $cat

   dload-buf count				( dev+name$ )	

   state-valid off				( dev+name$ )
   restartable? off				( dev+name$ )

   $boot-read					(  )
;

: $dload ( name$ -- )  " net" $dload-read  ;

: dload  \  filename  ( load-addr -- )
   (dload$) " net" $dload-read
;
headers

