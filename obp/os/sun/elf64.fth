\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: elf64.fth
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
id: @(#)elf64.fth 1.3 01/04/06
purpose:
copyright: Copyright 1991-2001 Sun Microsystems, Inc.  All Rights Reserved

\
\ ELF-64
\

struct  \ ELF64 File Header
   0  field >e64_ident       \ Alias for the next 16 bytes

   \ Subfields within "ident"
   4  field >e64_magicword  \ <7f>ELF
   1  field >e64_class      \ 32- or 64-bit
   1  field >e64_data       \ endianness
   1  field >e64_iversion   \
   9  field >e64_pad        \ ( reserved )

   /w field >e64_type	    \ file type
   /w field >e64_machine    \ target machine
   /l field >e64_version    \ file version
   /x field >e64_entry	    \ start address
   /x field >e64_phoff	    \ phdr file offset
   /x field >e64_shoff	    \ shdr file offset
   /l field >e64_flags	    \ file flags
   /w field >e64_ehsize	    \ sizeof ehdr
   /w field >e64_phentsize  \ sizeof phdr
   /w field >e64_phnum	    \ number phdrs
   /w field >e64_shentsize  \ sizeof shdr
   /w field >e64_shnum	    \ number shdrs
   /w field >e64_shstrndx   \ shdr string index
constant /elf64-header

/elf64-header buffer: elf64-header

: e64_magicword  ( -- n )  elf64-header >e64_magicword  l@  ;
: e64_machine    ( -- n )  elf64-header >e64_machine    w@  ;
: e64_class      ( -- n )  elf64-header >e64_class      c@  ;
: e64_entry      ( -- n )  elf64-header >e64_entry      x@  ;
: e64_phoff      ( -- n )  elf64-header >e64_phoff      x@  ;
: e64_phentsize  ( -- n )  elf64-header >e64_phentsize  w@  ;
: e64_phnum      ( -- n )  elf64-header >e64_phnum      w@  ;
: e64_shoff      ( -- n )  elf64-header >e64_shoff      x@  ;
: e64_shentsize  ( -- n )  elf64-header >e64_shentsize  w@  ;
: e64_shnum      ( -- n )  elf64-header >e64_shnum      w@  ;

struct  \ ELF64 Program Header
  /l field >p64_type         \ entry type
  /l field >p64_flags        \ entry flags
  /x field >p64_offset       \ file offset
  /x field >p64_vaddr        \ virtual address
  /x field >p64_paddr        \ physical address
  /x field >p64_filesz       \ file size
  /x field >p64_memsz        \ memory size
  /x field >p64_align        \ memory/file alignment
constant /elf64-pheader

/elf64-pheader buffer: elf64-pheader

: p64_type    ( -- n )  elf64-pheader >p64_type    l@  ;
: p64_flags   ( -- n )  elf64-pheader >p64_flags   l@  ;
: p64_offset  ( -- n )  elf64-pheader >p64_offset  x@  ;
: p64_vaddr   ( -- n )  elf64-pheader >p64_vaddr   x@  ;
: p64_paddr   ( -- n )  elf64-pheader >p64_paddr   x@  ;
: p64_filesz  ( -- n )  elf64-pheader >p64_filesz  x@  ;
: p64_memsz   ( -- n )  elf64-pheader >p64_memsz   x@  ;
: p64_align   ( -- n )  elf64-pheader >p64_align   x@  ;

struct  \ ELF64 Section Header
   /l field >sh64_name        \ section name
   /l field >sh64_type        \ section type
   /x field >sh64_flags       \ section flags
   /x field >sh64_addr        \ virtual address
   /x field >sh64_offset      \ file offset
   /x field >sh64_size        \ section size
   /l field >sh64_link        \ misc info
   /l field >sh64_info        \ misc info
   /x field >sh64_addralign   \ memory alignment
   /x field >sh64_entsize     \ entry size if table
constant /elf64-sheader

/elf64-sheader buffer: elf64-sheader

: sh64_flags   ( -- n )  elf64-sheader >sh64_flags   x@  ;
: sh64_type    ( -- n )  elf64-sheader >sh64_type    l@  ;
: sh64_offset  ( -- n )  elf64-sheader >sh64_offset  x@  ;
: sh64_size    ( -- n )  elf64-sheader >sh64_size    x@  ;
: sh64_link    ( -- n )  elf64-sheader >sh64_link    l@  ;

struct  \ ELF64 symbol table entry
  /l field st64_name
  /c field st64_info
  /c field st64_other
  /w field st64_shndx
  /x field st64_value
  /x field st64_size
constant /elf64-symbol
