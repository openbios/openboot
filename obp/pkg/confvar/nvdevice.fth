\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: nvdevice.fth
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
id: @(#)nvdevice.fth 1.6 06/02/07
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

exported-headerless

defer reset-config	' noop is reset-config
defer init-nvram-hook	' noop is init-nvram-hook

: init-nvmagic# ( -- )
   nvmagic-hash nvfixed-size +  init-nvram-hook xlsplit +  is nvmagic#
;

: open-nvram ( nvdevice$ -- ok? )
   2dup open-nvfixed-region >r  open-nvtoken-region r> and
;

: init-nvram ( nvdevice$ -- )
   open-nvram 0=  if
      cmn-fatal[ " Unable to open NVRAM device" ]cmn-end  exit
   then
   init-nvmagic#
   load-nvfixed-data
   nvfixed-region-ok?  nvtoken-region-ok?  and  if
      ['] load-nvtoken-data catch 0=  if  exit  then
      cmn-fatal[ 
      " NVRAM contents corrupt; Reinitializing NVRAM parameters." 
      ]cmn-end
   else
      cmn-note[ 
      " NVRAM contents invalid; Setting NVRAM parameters to default values." 
      ]cmn-end
   then
   init-nvfixed-region init-nvtoken-region
   true to token-store-disabled?
   (set-defaults)
   false to token-store-disabled?
   reset-config
;

: disable-backing-store ( -- )
   (garbage-collect)
   true to fixed-store-disabled?
   true to token-store-disabled?
;

: enable-backing-store ( -- )
   false to fixed-store-disabled? 
   false to token-store-disabled? 
;

unexported-words
