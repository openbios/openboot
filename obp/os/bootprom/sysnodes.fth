\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: sysnodes.fth
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
id: @(#)sysnodes.fth 1.6 02/08/20
purpose: 
copyright: Copyright 1990-1994,2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
defer client-services

\ Create the standard system nodes
root-device
   new-device				\ Node for software "library" packages
      " packages" device-name
      true support-node? !		\ Not a real device node!!
   finish-device

   new-device				\ Reports firmware run-time choices
      " chosen" device-name
      true support-node? !		\ Not a real device node!!
   finish-device

   new-device				\ Node describing the firmware
      " openprom" device-name
      true support-node? !		\ Not a real device node!!
      0 0 " relative-addressing" property
      0 0 " aligned-allocator"	 property

      new-device     current-device to client-services
         " client-services" device-name
      finish-device
   finish-device

   new-device				\ Node for configuration options
      ' options 'properties token!	\ "options" voc is node's property list
      " options" device-name
      true support-node? !		\ Not a real device node!!
   finish-device

   new-device				\ Node for configuration options
      ' aliases 'properties token!	\ "options" voc is node's property list
      " aliases" device-name
      true support-node? !		\ Not a real device node!!
   finish-device
device-end

headerless
\ "chosen-variable" is a convenient way to report the contents of a
\ variable in a "/chosen" property.  Example: stdout " stdout" chosen-variable
5 actions
action:  token@ execute @ encode-int over here - allot  ;   \ get
action:  token@ execute >r get-encoded-int r> !   ;         \ set
action:  token@ execute  ;                                  \ addr
action:  drop  ;
action:  drop  ;

: chosen-variable  ( acf adr len -- )
   also " /chosen" find-device
      make-property-name token, use-actions
   previous definitions
;

5 actions
\ Add NULL at the end of the string to the length
action:  token@ execute cscount 1+ ( adr len )  ;          \ get
action:  token@ execute >r cscount r> place-cstr drop  ;   \ set
action:  token@ execute  ;                                 \ addr
action:  drop  ;
action:  drop  ;

: chosen-string  ( acf adr len -- )
   also " /chosen" find-device
      make-property-name token, use-actions
   previous definitions
;
headers
