\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: availmem.fth
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
id: @(#)availmem.fth 1.14 99/02/02
purpose: 
copyright: Copyright 1990-1994 Sun Microsystems, Inc.  All Rights Reserved

headers

" /memory" find-device

headerless

: make-phys-memlist  ( adr len node-adr -- adr len' false )
   \   node-range pages>phys-adr,len encode-reg encode+ false
   node-range pages>phys-adr,len   ( lo hi size )
   parent-#size-cells 1 =  if
      >r >r encode-int encode+ r> encode-int encode+ r> encode-int encode+
   else
      nip  ( lo size )
      >r  xlsplit swap >r encode-int encode+ r>  encode-int encode+
      r>  xlsplit swap >r encode-int encode+ r>  encode-int encode+
   then  false
;

headers

5 actions
action:  drop
   here 0                                        ( adr 0 )
   physavail  ['] make-phys-memlist  find-node   ( adr len  prev 0 )
   2drop  over here - allot                      ( adr len )
;
action:  drop 2drop  ;
action:  ;
action:  drop  ;
action:  drop  ;

" available" make-property-name  use-actions

: size  ( -- d.#bytes )
   current-device >r
   my-voc push-device
   0 0  2>r                       (  )              ( r: d.size )
   get-unit  0=  if               ( adr len )       ( r: d.size )
      begin  dup  while           ( adr len )       ( r: d.size )
	 2 decode-ints 2drop      ( adr' len' )     ( r: d.size )
	 parent-#size-cells 1 =  if
	    decode-int  s>d       ( adr' len' ud )  ( r: d.size )
	 else
	    parent-#size-cells  decode-ints lxjoin s>d ( adr' len' ud )  ( r: d.size )
	 then
	 2r> d+ 2>r               ( adr' len' )     ( r: d.size' )
      repeat                      ( adr 0 )         ( r: d.size' )
      2drop                       (  )              ( r: d.size' )
   then  2r>                      ( d.#bytes )
   parent-#size-cells 2 =  if  drop xlsplit  then
   r> push-device
;

device-end

" /virtual-memory" find-device  extend-package

headerless
\ : range>reg  ( start end -- )  over - 0 swap  encode-reg  ;
: make-virt-memlist  ( adr len node-adr -- adr len' false )
   node-range   ( adr size  )
   parent-#size-cells 1 =  if
      >r >r 0 encode-int encode+ r> encode-int encode+ r> encode-int encode+
   else
      >r  xlsplit swap >r encode-int encode+ r>  encode-int encode+
      r>  xlsplit swap >r encode-int encode+ r>  encode-int encode+
   then  false
;

headers

5 actions
action:  drop
   0 0  encode-bytes        \ "prime" the property-encoded array

   \ Append the pieces from the non-PROM virtual memory list
   osvirt  ['] make-virt-memlist  find-node  2drop   ( adr len )

   \ Append the pieces from the virtual memory free list
   fwvirt  ['] make-virt-memlist  find-node  2drop   ( adr len )

   over here - allot                              ( adr len )
;
action:  drop 2drop  ;
action:  ;
action:  drop  ;
action:  drop  ;

   " available" make-property-name  use-actions

   0 0 encode-bytes
   0         hole-start
   >r  xlsplit swap >r encode-int encode+ r>  encode-int encode+
   r>  xlsplit swap >r encode-int encode+ r>  encode-int encode+
   hole-end  0 hole-end -
   >r  xlsplit swap >r encode-int encode+ r>  encode-int encode+
   r>  xlsplit swap >r encode-int encode+ r>  encode-int encode+
   " existing" property

finish-device device-end

: "/memory" ( -- adr,len )  " /memory"  ;
