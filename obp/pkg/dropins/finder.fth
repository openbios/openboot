\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: finder.fth
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
id: @(#)finder.fth 1.3 06/04/18
purpose: Package for FLASH ROM device 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

hex
headerless

0 value di-limit

struct
   /l field >di-magic
   /l field >di-size
   /l field >di-sum
   /l field >di-exp  \ Reserved
d# 16 field >di-name
    0 field >di-image
constant /lvl1-hdr

struct
    /l field >di2-magic
     0 field >di2-image
constant lvl2-hdr

: check-di-magic ( addr -- header flag? )
   4 round-up				( addr' )
   dup >di-magic rl@ h# 4f424d44 =	( addr' flag )
;

: check-directory-magic ( addr -- addr flag )
   dup rl@ h# 4f424d45 =		( addr' flag )
;

: (find-drop-in?) ( name$ base -- false | header,true )
   recursive
   swap d# 15 min swap			( name$' base )
   over 0= if  3drop false exit  then	( false )
   check-di-magic if			( name$ addr )
      >r 2dup r@ >di-name cscount $= if	( name$ )
         2drop r> true			( header,true )
      else				( name$ )
         r> dup >di-size rl@ 		( name$ addr len )
         swap >di-image +		( name$ addr )
	 dup di-limit  <  if 		( name$ addr )
            (find-drop-in?)		( header,true | false )
         else 				( header,true | false )
            cmn-warn[ " Dropin search goes past prom boundary" ]cmn-end
            3drop false exit 		( false )
         then				( false )
      then				( header,true | false )
   else					( name$ header )
      3drop false			( false )
   then					( header,true | false )
;

\
\ The device tree requires that / be replaced with |
\ so that arguments and device nodes are correctly delimited.
\ So the left-parse-string below uses |
\
: find-drop-in? ( name-adr,len addr -- addr,true | false )
   recursive
   >r					( name$ )
   ascii | left-parse-string		( r,len l,len )
   r> (find-drop-in?) if		( r,len addr )
      over if				( r,len )
         >di-image			( r,len addr' )
         check-directory-magic if	( r,len addr )
            >di2-image find-drop-in?	( addr,true | false )
         else				( r,len addr )
            3drop false			( false )
         then				( addr,true | false )
      else				( r,0 addr )
         nip nip true			( addr,true )
      then				( addr,true | false )
   else					( r,len )
      2drop false			( false )
   then					( addr,true | false )
;

