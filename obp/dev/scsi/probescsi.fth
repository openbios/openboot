\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: probescsi.fth
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
id: @(#)probescsi.fth 1.13 03/02/10
purpose: 
copyright: Copyright 1990-2000, 2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

: probe-scsi? ( -- )
   already-go? 0= if true exit then

   ." This command may hang the system if a Stop-A or halt command" cr
   ." has been executed.  Please type reset-all to reset the system " cr
   ." before executing this command. " cr
   ." Do you wish to continue? (y/n) " 

   begin  key?  until
   key lcc dup emit
   ascii y - 0=  if 
      true
   else 
      false
   then  cr
;

headers
[ifndef] no-onboard-scsi
: probe-scsi  ( -- )
   probe-scsi?  if 
      " scsi"  " show-children"  execute-device-method drop
   then
;
[then]
headerless

: scsi-children  ( -- )
   \ Ignore nodes that do not have device_type = scsi* or hierarchical
   " device_type" get-property  if  exit  then	( enc$ )
   get-encoded-string				( adr,len )
   over " scsi"  comp 0= >r			( adr,len ) ( r: flag )
   " hierarchical" $=  r>  or  if		(  )
      " show-children" method-name 2!  do-method?
   then
;

headers

: probe-scsi-all ( -- )
   probe-scsi?  if 
      optional-arg-or-/$  ['] scsi-children  scan-subtree
   then
;
