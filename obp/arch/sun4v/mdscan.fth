\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mdscan.fth
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
id: @(#)mdscan.fth 1.1 06/02/22
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
0 value pd-data

headerless
0        constant  LIST_END
ascii N  constant  NODE
ascii E  constant  NODE_END
h# 20	 constant  NODE_NULL
ascii a  constant  PROP_ARC
ascii v  constant  PROP_VAL
ascii s  constant  PROP_STR
ascii d	 constant  PROP_DATA

struct
    /l		field  >hdr-version
    /l		field  >hdr-nodes
    /l		field  >hdr-names
    /l		field  >hdr-data
constant /pdhdr

struct
   /c           field  >pdentry-tag
   /c		field  >pdentry-namelen
   /w +
   /l		field  >pdentry-name
   /l		field  >pdentry-datalen
   /l		field  >pdentry-data
constant /pdentry

0 value pd-text
0 value pd-bytes
0 value pd-nodes
headers
: pd-rootnode ( -- pdnode )
   pd-nodes 0= if
      pd-data /pdhdr + is pd-nodes
      pd-nodes pd-data >hdr-nodes l@ + is pd-text
      pd-text pd-data >hdr-names l@ + is pd-bytes
   then
   pd-nodes
;

: pdentry-tag@  ( pdentry -- tag )   >pdentry-tag c@ ;

: pdentry-name@ ( pdentry -- name$ )
   >r r@ >pdentry-name l@ pd-text +	( adr )
   r> >pdentry-namelen c@		( adr,len )
;

: (pd-link) ( offset -- ptr ) /pdentry * pd-rootnode + ;
: (pd-bytes) ( offset ptr -- buf,len ) >pdentry-datalen l@ >r pd-bytes + r> ;

\ decode the entry
: pdentry-data@ ( pdentry -- [data,len]|data )
   >r r@ >pdentry-data l@				( offset )
   r@ pdentry-tag@ case					( offset )
      NODE	of  (pd-link)			endof	( ptr )
      NODE_END	of  drop 0			endof	( 0 )
      NODE_NULL of  drop 0			endof	( 0 )
      PROP_ARC	of  (pd-link)			endof	( ptr )
      PROP_VAL	of  drop r@ >pdentry-datalen x@	endof	( data )
      PROP_STR	of  r@ (pd-bytes) 1-		endof	( buf,len )
      PROP_DATA	of  r@ (pd-bytes)		endof	( buf,len )
   endcase r> drop					( ?? )
;
alias pddecode-prop pdentry-data@
0 value pdlastnode
0 value pdlastprop

\
\ node = 0 means use root, else use 'node' as the start.
\ 
: pdfind-node ( name$ node -- pdentry | false )
   0 is pdlastnode 					( name$ node )
   0 is pdlastprop 					( name$ node )
   0 swap ?dup 0= if pd-rootnode then			( name$ 0 node' )
   begin						( name$ 0 node' )
      over 0= over pdentry-tag@ LIST_END <> and while	( name$ 0 node' )
         >r						( name$ 0 )
         2 pick 2 pick r@ pdentry-name@ $= if		( name$ 0 )
	    drop r@ r>					( name$ ptr node' )
	    dup is pdlastnode				( name$ ptr node' )
            dup /pdentry + is pdlastprop		( name$ ptr node' )
         else						( name$ 0 )
	    r> >pdentry-data l@ /pdentry * pd-rootnode + ( name$ 0 node'' )
         then						( name$ ptr node'' )
   repeat						( name$ ptr node'' )
   drop nip nip						( pdentry|0 )
;

\ Get the next property in the current node
: pdnext-prop ( -- pdentry|0 )
   pdlastprop pdentry-tag@ NODE_END <> if		( )
      begin						( )
         pdlastprop pdentry-tag@ NODE_NULL = while	( )
            pdlastprop /pdentry + is pdlastprop		( )
      repeat
      pdlastprop dup /pdentry + is pdlastprop		( ptr )
   else							( )
      0							( 0 )
   then							( ptr|0 )
;

: (pdselect-node) ( node -- )
   dup -1 = if						( node )
      drop pdlastnode					( node' )
   then /pdentry + is pdlastprop			( )
;

\ search the current node for a property
\  type =  -1 means dont care about type
\  node =  -1 mean use the current node
: pdget-prop ( name$ type node -- entry|0 )
   (pdselect-node)					( name$ type )
   0 2swap						( type 0 name$ )
   begin						( type 0 name$ )
      pdnext-prop dup 4 pick 0= and  while		( type 0 name$ ptr )
      >r 2dup r@ pdentry-name@ $=			( type 0 name$ name? )
      4 pick dup -1 = swap r@ pdentry-tag@ = or and if	( type 0 name$ )
          3drop drop r> exit 				( ptr )
      else						( type 0 name$ )
         r> drop					( type 0 name$ )
      then						( type 0 name$ )
   repeat						( type 0 name$ ptr )
   3drop nip						( entry|0 )
;
