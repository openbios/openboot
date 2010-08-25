\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: dropin.fth
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
id: @(#)dropin.fth 1.29 01/04/06
purpose: 
copyright: Copyright 1992-2001 Sun Microsystems, Inc.  All Rights Reserved

\ Drop-in driver support.
\
\ Drop-in drivers are stored in otherwise-unused PROM, usually near the
\ end of the CPU PROM, after the main firmware image.

\ The layout is as follows:
\
\   End of PROM:
\
\      <free space>
\      Module n
\        ...
\      Module 1
\      Startup checksum
\      Startup Code
\
\   Beginning of PROM:
\
\ Each module contains:
\
\   High address:
\
\      Module image (n bytes)    The module itself
\      Module name  (16 bytes)   Null-terminated string
\      Reserved     (4 bytes)    reserved for future extension - must be 0
\      Checksum     (4 bytes)    32-bit sum of image bytes
\      Image size   (4 bytes)    size in bytes of image
\      Magic Number (4 bytes)    "OBMD"
\      Sync bytes   (1-3 bytes)  Enough 0x01 bytes to align the Magic Number
\                                on a 4-byte boundary.
\
\   Low address:
\
\  Currently The "Module name" must be one of :
\
\ 	cpu-devices-	cpu-devices+
\	nvramrc-	nvramrc+
\	probe-		probe+
\	banner-		banner+
\	test-		test+
\	boot-		boot+
\
\  Search and execution order can be either one of :
\		(A)				   (B)
\	1.  cpu-devices-                     1.  cpu-devices-
\	2.  cpu-devices+	             2.  cpu-devices+
\	3.  nvramrc-		             3.  nvramrc-
\	4.  nvramrc+		             4.  probe-
\	5.  probe-		             5.  probe+
\	6.  probe+		             6.  banner-
\	7.  banner-		             7.  banner+
\	8.  banner+		             8.  nvramrc+
\	9.  test-		             9.  test-
\      10.  test+		            10.  test+
\      11.  boot-		            11.  boot-
\      12.  boot+             	            12.  boot+
\
\
\  (A). The search and execution order will be as specified in (A)
\	If at least one of the following two statements is true.
\
\		a) NVRAMRC is empty or use-nvramrc? NVRAM parameter is false
\
\		b) NVRAMRC does not contain the sequence:
\			probe-all
\			install-console
\			banner
\
\
\  (B). The search and execution order will be as specified in (B)
\	If both of the following two statements are true
\
\		a) NVRAMRC contains the following sequence:
\			probe-all
\			install-console
\			banner
\
\		b) NVRAM parameter use-nvramrc? is true
\
\

headerless
0 value di-header
0 value di-level
0 value header-page

: difield  \ name  ( offset -- offset' )
   create  over c,  +  does> c@ di-header +
;

struct
    /l difield di-magic
    /l difield di-size
    /l difield di-sum
    /l difield di-exp  \ Reserved
d# 16 difield di-name
    0 difield di-image
constant /di-header

0 value di-base

: direct-open-drop-in  ( -- 0 )
   di-level 0= if  map-drop-in is di-base  then
   di-level 1+ to di-level
   0
;

: direct-close-drop-in  ( -- )
   di-level 1-  dup  0=  if  ( level )
      di-base unmap-drop-in  0 to di-base
   then                      ( level )
   0 max is di-level         ( level )
;

: check-di-magic ( addr -- header flag? )
   4 round-up is di-header
   di-magic l@ h# 4f424d44 =
   di-header swap
;

: another-dropin?  ( header -- false  | header' true )
   is di-header
   di-base -1 =  if  false exit  then
   di-header  if  di-image  di-size l@ +  else  di-base  then   ( adr )
   check-di-magic dup 0= if  nip  then
;

tail-chain: execute-buffer  ( adr len -- )                \ Try machine code
   2dup  4 min  " CODE"  $=  if             ( adr len )
      drop 4 +  0 swap  call  2drop exit
   then                                     ( adr len )
tail;

: (dropin>data) ( -- data,len ) di-image di-size l@ ;

defer dropin>data ' (dropin>data) is dropin>data
defer release-di-data ' 2drop is release-di-data

\ Executes all drop-in packages whose names match the argument

: direct-do-drop-in  ( name-adr,len -- )
   2>r                             ( )              ( r: name-adr,len )
   direct-open-drop-in             ( header )
   begin  another-dropin?  while   ( header )

      \ We go to a fair amount of extra trouble to keep the name
      \ and the current header address on the return stack, in
      \ case a drop-in messes up the data stack.

      2r@ rot >r                   ( name-adr,len ) ( r: name-adr,len header)

      di-name cscount  $=  if      ( )              ( r: name-adr,len header)
         dropin>data 2dup 2>r
         'execute-buffer catch  if  2drop  then     ( )
         2r> release-di-data        ( )
      then                         ( )              ( r: name-adr,len header)
      r>                           ( header )       ( r: name-adr,len )
   repeat                          ( )              ( r: name-adr,len )
   direct-close-drop-in            ( )              ( r: name-adr,len )
   2r> 2drop                       ( )
; ' direct-do-drop-in is do-drop-in

\ After calling this routine, it is the responsibility of the
\ caller to execute "free-drop-in" after it is finished using
\ the located drop-in package.  Failing to do so can result in
\ wasted virtual memory.

: direct-find-drop-in  ( name-adr,len -- false  | drop-in-adr,len true )
   direct-open-drop-in                    ( name-adr,len header )
   begin  another-dropin?  while          ( name-adr,len header )
      2 pick 2 pick                       ( name-adr,len header name-adr,len )
      di-name cscount  $=  if             ( name-adr,len header )
         drop 2drop                       ( )
         dropin>data  true                ( virtual size true )
         exit
      then
   repeat
   direct-close-drop-in
   2drop false
; ' direct-find-drop-in is find-drop-in

: direct-free-drop-in  ( adr len -- )
   release-di-data
   direct-close-drop-in
; ' direct-free-drop-in is free-drop-in

headerless
: (.dropin) ( -- )
   push-decimal
   di-name cscount tuck type d# 17 swap - spaces
   di-size l@ d# 11 u.r  di-exp  l@ d# 11 push-hex .r pop-base
   di-sum  l@ d# 11 u.r  cr
   pop-base
;
headers
: .dropins ( -- )
   ." Name                  Length  Expansion   Checksum" cr
   direct-open-drop-in			( header )
   begin  another-dropin?  while	( header )
      (.dropin)				( header )
   repeat				( header )
   direct-close-drop-in			(  )
;
