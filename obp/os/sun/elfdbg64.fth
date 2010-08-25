\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: elfdbg64.fth
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
id: @(#)elfdbg64.fth 1.2 95/09/14
purpose: 
copyright: Copyright 1991-1994 Sun Microsystems, Inc.  All Rights Reserved

headerless
: get-s64hdr ( filebase index -- )
   e64_shentsize * e64_shoff + +
   elf64-sheader e64_shentsize move
;

: >elf64-st_name ( sym-entry -- cstr )  st64_name l@ strings +  ;
: >elf64-st_value ( sym-entry -- symbol-address )  st64_value x@  ;
: >elf64-st_info  ( sym-entry -- valid-sym? ) st64_info c@ h# 0f and 1 2 between  ;

headers
: init-elf64syms ( filebase -- filebase )
   0 to strings  0 to /strings
   0 to symbols  0 to /symbols
   e64_shnum 0  ?do
      \ ." symtab " i . cr
      dup i get-s64hdr
      sh64_type SHT_SYMTAB  =  sh64_link 1- i = and  if
	 sh64_offset is  symbols
	 \ symbols . cr
	 sh64_size   is  /symbols
	 \ /symbols . cr
	 leave
      then
   loop          ( filebase )
   symbols  if
      e64_shnum sh64_link  ?do
	 \ ." strtab " i . cr
	 dup sh64_link get-s64hdr
	 sh64_type SHT_STRTAB =  if
	    strings 0=  if
	       sh64_offset is strings
	       sh64_size   is /strings
	    else
	       strings /strings + sh64_offset =  if
		  sh64_size /strings + to /strings
	       else
		  leave
	       then
	    then
	 then
      loop
   then                ( filebase )
   strings  if
      \ ." symbols " symbols . /symbols . cr
      \ ." strings " strings . /strings . cr
      strings over + over symbols +           ( filebase strbase symbase )
      /symbols  /strings + allocate-symtab    ( filebase strbase symbase addr )
      tuck /symbols  move                     ( filebase strbase addr )
      dup to symbols                          ( filebase strbase addr )
      /symbols +                              ( filebase strbase addr' )
      tuck  /strings move                     ( filebase addr' )
      to strings
      ['] >elf64-st_name  is  >string
      ['] >elf64-st_value is  >value
      ['] >elf64-st_info  is  >sym_type
      /elf64-symbol to /symtab-entry
      ['] $sym-handle-literal? is $handle-literal?
   else
      0 to strings  0 to /strings
      0 to symbols  0 to /symbols
   then                                        ( filebase )
;


headerless
\ h# 7f454c46  \x7fELF
: is-elf64? (  -- is-elf? )
   true
   e64_magicword h# 7f454c46  =  and
   e64_class     ELFCLASS64   =  and
;
: get-p64hdr ( filebase index -- )
   e64_phentsize * e64_phoff + +
   elf64-pheader e64_phentsize move
;
: get-elf64hdr ( base -- )
   elf64-header /elf64-header 0 fill     ( filebase )
   dup  elf64-header /elf64-header move  ( filebase )
;
: init-elf64load ( filebase -- filebase )
   e64_phnum 0  ?do             ( filebase )
      dup i get-p64hdr
      p64_type PT_LOAD =  if
	 \ Move it into the correct vaddr.
	 dup p64_offset + p64_vaddr p64_filesz move
	 p64_memsz p64_filesz >  if
	    \ Zero out the BSS section.
	    p64_vaddr p64_filesz +  p64_memsz p64_filesz -  erase
	 then
      then
   loop                         ( filebase )
;
: adjust-elf64-header ( filebase -- entry-point true | false )
   get-elf64hdr is-elf64?  0=  if  drop  false  exit  then

   init-elf64syms        ( filebase )
   init-elf64load        ( filebase )
   drop e64_entry  true  ( entry true )
;

headers
