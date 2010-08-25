\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mkfonts.fth
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
id: @(#)mkfonts.fth 1.7 97/07/24
purpose: 
copyright: Copyright 1990-1994 Sun Microsystems, Inc.  All Rights Reserved

defer new-font			\ the current font being created
defer romfont			\ so I dont have to change font files

h# 40 buffer: fname

." writing the fonts" cr

\ I am about to redefine the label routine so that I get a dropin name
\ that matches the forth symbol name, I also pull some tricks with
\ end-code to get the font size.
\
\

: label ( -- )
  safe-parse-word				( adr,len )
  2dup $create					( adr,len )
  2dup $find if					( adr,len acf )
    is new-font					( adr,len )
    ." Creating font: " 2dup type space		( adr,len )
    ascii ( emit				( adr,len )
    fname pack " .fnt" rot $cat			( -- )
    fname dup count type ascii ) emit space	( adr )
    new-file					( -- )
  else						( adr,len adr,len )
    2drop 					( adr,len adr,len )
    ." ABORT: creation of font " type		( -- )
    ." failed"	cr				( -- )
    ofd @ fclose				( -- )
    abort					( -- )
  then						( -- )
;

\ I need to redefine these so that data is not restricted to any padding
\ arrangement.
: l, ( data -- ) lbsplit c, c, c, c, ;
: w, ( data -- ) wbsplit c, c, ;
\
\ This actually writes the font data to the dropin file
\
: end-code ( -- )
  new-font here over - dup .d ." bytes" cr
  ofd @ fputs ofd @ fclose
;

\
\ Add more font files here
\
fload ${BP}/pkg/termemu/gallant.fth
\
\

