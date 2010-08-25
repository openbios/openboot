\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: elfdebug.fth
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
id: @(#)elfdebug.fth 1.5 95/09/14
purpose: 
copyright: Copyright 1991-1994 Sun Microsystems, Inc.  All Rights Reserved

headerless
: get-s32hdr ( filebase index -- )
   e32_shentsize * e32_shoff + +
   elf32-sheader e32_shentsize move
;

: >elf32-st_name ( sym-entry -- cstr )  st32_name l@ strings +  ;
: >elf32-st_value ( sym-entry -- symbol-address )  st32_value l@  ;
: >elf32-st_info  ( sym-entry -- valid-sym? ) st32_info c@ h# 0f and 1 2 between  ;

headers
: init-elf32syms ( filebase -- filebase )
   0 to strings  0 to /strings
   0 to symbols  0 to /symbols
   e32_shnum 0  ?do
      \ ." symtab " i . cr
      dup i get-s32hdr
      sh32_type SHT_SYMTAB  =  sh32_link 1- i = and  if
	 sh32_offset is  symbols
	 \ symbols . cr
	 sh32_size   is  /symbols
	 \ /symbols . cr
	 leave
      then
   loop          ( filebase )
   symbols  if
      e32_shnum sh32_link  ?do
	 \ ." strtab " i . cr
	 dup sh32_link get-s32hdr
	 sh32_type SHT_STRTAB =  if
	    strings 0=  if
	       sh32_offset is strings
	       sh32_size   is /strings
	    else
	       strings /strings + sh32_offset =  if
		  sh32_size /strings + to /strings
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
      ['] >elf32-st_name  is  >string
      ['] >elf32-st_value is  >value
      ['] >elf32-st_info  is  >sym_type
      /elf32-symbol to /symtab-entry
      ['] $sym-handle-literal? is $handle-literal?
   else
      0 to strings  0 to /strings
      0 to symbols  0 to /symbols
   then                                        ( filebase )
;


headerless
\ h# 7f454c46  \x7fELF
: is-elf32? (  -- is-elf? )
   true
   e32_magicword h# 7f454c46  =  and
   e32_class     ELFCLASS32   =  and
;
: get-p32hdr ( filebase index -- )
   e32_phentsize * e32_phoff + +
   elf32-pheader e32_phentsize move
;
: get-elf32hdr ( base -- )
   elf32-header /elf32-header 0 fill     ( filebase )
   dup  elf32-header /elf32-header move  ( filebase )
;
: init-elf32load ( filebase -- filebase )
   e32_phnum 0  ?do             ( filebase )
      dup i get-p32hdr
      p32_type PT_LOAD =  if
	 \ Move it into the correct vaddr.
	 dup p32_offset + p32_vaddr p32_filesz move
	 p32_memsz p32_filesz >  if
	    \ Zero out the BSS section.
	    p32_vaddr p32_filesz +  p32_memsz p32_filesz -  erase
	 then
      then
   loop                         ( filebase )
;
: adjust-elf32-header ( filebase -- entry-point true | false )
   get-elf32hdr is-elf32?  0=  if  drop  false  exit  then

   init-elf32syms        ( filebase )
   init-elf32load        ( filebase )
   drop e32_entry  true  ( entry true )
;

headers
