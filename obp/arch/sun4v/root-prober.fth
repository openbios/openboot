\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: root-prober.fth
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
id: @(#)root-prober.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

: make-root$ ( n type$ -- root$ )
   push-hex
   rot <# u#s -rot ascii - hold 1- bounds swap do i c@ hold -1 +loop u#>
   pop-base
;

: get-root-driver? ( name$ -- acf,-1|0 )
   ['] builtin-drivers-package find-method
;

0 value pdnode-handle

\ do a sort of 'compatible' search:
\ look for "device-type"-"unit" first
\ then "device-type"
\
: make-io-nodes ( -- )
   0							( here )
   begin
      >r " iodevice" r> pdfind-node ?dup while		( node )
      " disabled" -1 -1 pdget-prop dup if		( node x )
         pdentry-data@					( node status )
      then						( node )
      0= if						( node )
         >r " cfg-handle" -1 -1 pdget-prop ?dup if	( prop )
            pdentry-data@ >r				( )
            r@ " device-type" -1 -1 pdget-prop ?dup if	( unit prop )
	       pdentry-data@				( unit str,len )
	    else					( )
               " io-"					( unit str,len )
            then					( unit str,len )
            2>r 2r@					( unit str,len )
	    make-root$ get-root-driver? dup 0= if	( )
               drop 2r@ get-root-driver?		( acf,-1|0 )
            then 2r> 2drop if				( acf )            
	       0 0 r@ push-hex (.) pop-base
               cmn-type[ " Device: " cmn-append
               " /" begin-package			( )
                  catch drop				( )
	       end-package				( )
               " " ]cmn-end
	    then					( )
	    r> drop					( )
[ifndef] RELEASE
         else
            ." Error: missing 'cfg-handle' in io-device description" cr
[then]
         then
         r>
      then
      pdentry-data@					( node )
   repeat 						( )
;

stand-init: Probe root devices
   make-io-nodes
;
