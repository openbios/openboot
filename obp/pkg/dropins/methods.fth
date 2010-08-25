\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: methods.fth
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
id: @(#)methods.fth 1.10 05/11/03
purpose: 
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

instance defer (find-drop-in)		\ Alternative device specifiers
instance defer (fetch-drop-in)		\ Forward reference..

" /flashprom:"	encode-string
" source" property

: dropin-alloc ( len -- va )
   0 tuck [ also client-services ] claim [ previous ]
;

: dropin-free ( va len -- )
   swap [ also client-services ] release [ previous ]
;

headers

: free-drop-in ( va,len -- ) dropin-free ;

headerless

: level2? ( name$ -- left$ true | false )
   dup 0= if                            
      2drop false                       \ if namelen = 0, consume the args
                                        \   and return false
   else				( name$ )
     1-                                 \ subtract one from the length
                                        \   to point to the last char
                                        \   not the first byte beyond it
     over -1                            \ Copy the base address and
                                        \   make a flag word to mark a
                                        \   failed search 
	                        ( base len base -1)
     2swap bounds swap ?do      	\ Create the do-loop counters
                                        \   from base,len. Note that
                                        \   the swap will create a
                                        \   backward counter
                                ( base -1 )
        i c@ ascii / = if	               
           drop i leave			\ If "/", drop the "not
                                        \   found flag (-1) and get the
                                        \   address of where we found
                                        \   the slash and leave the loop
                                ( base addr-of-slash )
        then			( base -1 )
     -1 +loop				\ End of loop, decrementing counter
                                ( base -1 | base add-of-slash )  
     dup -1 = if                        \ Test to see if the not found
                                        \   flag is still on the stack
        2drop false                     \ Yes, slash not found, drop
                                        \   the base -1 and return false
                                ( false )
     else
        over - true                     \ calculate the length of the
                                        \   string and return true
     then			( base len )
   then
;

: $cat+replace-slashes ( src$ buf -- )
   dup c@				( src$ buf len )
   over + >r				( src$ buf )
   over over c@ +			( src$ buf len' )
   swap c! r> 1+			( src$ dest )
   -rot bounds ?do			( dest )
      i c@ dup ascii / = if drop ascii | then
      over c! 1+			( dest' )
   loop drop				( )		
;

\
\ You can't use open-package because that makes this package the
\ logical parent of the node you are opening which is incorrect.
\
: $open-dev ( arg$ dev$ extra$ -- ihandle )
   dup 5 pick + 3 pick + 1+ -rot	( arg$ dev$ n extra$ )
   2>r					( arg$ dev$ )
   dup >r alloc-mem			( arg$ dev$ va )
   >r 0 r@ c!				( arg$ dev$ )
   r@ $cat				( arg$ )
   r@ $cat+replace-slashes		( )
   r> r>				( va len )
   2r> 3 pick $cat+replace-slashes	( va len )
   over count open-dev			( va len ihandle )
   -rot free-mem			( ihandle )
;

: execute-drop-in ( ihandle -- )
   dup >r				( ihandle )
   (fetch-drop-in) if			( va,len )
     2dup execute-buffer		( va,len )
     free-drop-in			( )
   then					( )
   r> close-dev				( )
;

: open-dropin-device ( name$ dev$ -- ihandle )
   2over 2over over 0 $open-dev		( name$ dev$ ihandle|0 )
   ?dup if				( name$ dev$ ihandle )
      >r 2swap level2? if		( dev$ left$ )
         2swap " /.init" $open-dev	( ihandle )
         ?dup if  execute-drop-in  then	( ihandle )
      else				( dev$ )
         2drop				( )
      then				( )
      r>				( ihandle )
   else					( name$ dev$ )
      2drop 2drop false			( 0 )
   then					( 0 )
;

: decode-and-open-device ( name$ xdr,len -- name$ xdr,len ihandle )
   decode-string			( name$ xdr,len dev$ )
   2swap 2>r				( name$ dev$ )
   2over 2>r				( name$ dev$ )
   open-dropin-device			( ihandle )
   2r> rot 2r> rot			( name$ xdr,len ihandle )
;

: search-source-property ( name$ xdr,len -- ihandle ) recursive
   ?dup if				( name$ str$ )
      decode-and-open-device		( name$ xdr,len ihandle )
      ?dup if				( name$ xdr,len ihandle )
         >r 2drop 2drop r>		( ihandle )
      else				( name$ xdr,len )
         search-source-property		( ihandle )
      then				( ihandle )
   else					( name$ )
      3drop false			( false )
   then					( ihandle )
;

: locate-dropin-using-property ( name$ -- ihandle )
   " source" get-my-property if		( name$ )
      2drop false			( false )
   else					( name$ xdr,len )
      search-source-property		( flag )
   then					( flag )   
;

: locate-dropin-using-args ( name$ -- ihandle )
   my-args  open-dropin-device		( ihandle )
;

\ The format of a compressed dropin:
\ Dropin Header
\   4 bytes	magic-number	= COMP
\   4 bytes	size		= dropinhdr->size
\   4 bytes	comp-type
\   4 bytes	decomp-size

: dropin-compressed? ( buffer len -- flag )
   swap					( len buffer )
   dup l@ h# 434f4d50 =			( len data-ptr comp? )
   swap 1 la+ l@			( len comp? size )
   rot = and				( flag )
;

: do-decompress ( buf len -- buf len )
   over 3 la+ l@			( buf len dlen )
   >r d# 16 - swap d# 16 + swap r>	( buf' len' dlen )
   [ also decompressor ]
   dup dropin-alloc tuck		( buf len dest dlen dest )
   /decomp-data dropin-alloc		( buf len dest dlen dest scr )
   -rot					( adr len dest scratch dlen dest )
   swap 2>r dup >r			( adr len dest scratch )
   (decompress)				( -- )
   r> /decomp-data dropin-free		( -- )
   2r>					( addr' len' )
   [ previous ]
;

: decompress-dropin ( buf len -- buf len )
   2dup do-decompress			( data,len buf,len )
   2swap free-drop-in			( buf,len )
;

: fetch-drop-in ( ihandle -- adr,len,true | false )
   >r					( )
   " size" r@ $call-method		( n )
   dup dropin-alloc ?dup if		( n va )
      dup rot			        ( va va n )
      " read" r@ $call-method		( va len' )
      2dup dropin-compressed? if	( buf len )
         decompress-dropin		( buf len )
      then				( buf len )
      true				( buf len true )
   else					( n )
      drop false			( false )
   then					( flag )
   r> drop				( flag )
;
' fetch-drop-in to (fetch-drop-in)

headers
\
\ If open is called without arguments then the property
\ " source" is decoded and all devices in the encoded string will
\ be searched for a dropin, if an argument is specified then only
\ that device will be searched.
\

: open ( -- flag )
   my-args nip if
      ['] locate-dropin-using-args
   else
      ['] locate-dropin-using-property
   then
   ( acf )  to  (find-drop-in)
   true
;

: close ( -- )  ;

: find-drop-in ( name$ -- buf,len,true | false )
   ?dup if				( name$ )
      (find-drop-in)			( ihandle )
      ?dup if				( ihandle )
         dup >r fetch-drop-in		( flag )
         r> close-dev			( flag )
         exit				( flag )
      then				( )
   else					( arg )
      drop				( )
   then					( )
   false				( false )
;

headerless
: (do-drop-in) ( name$ xdr,len -- ) recursive
   ?dup if				( name$ str$ )
      decode-and-open-device		( name$ xdr,len ihandle )
      ?dup if  execute-drop-in  then	( name$ xdr,len )
      (do-drop-in)			( )
   else					( name$ xdr )
      3drop 				( )
   then					( )
;

headers
: do-drop-in ( name$ -- )
   " source" get-my-property if		( name$ )
      2drop				( )
   else					( name$ xdr,len )
     (do-drop-in)	 		( )
   then					( )
;

headerless
