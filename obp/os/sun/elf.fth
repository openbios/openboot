\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: elf.fth
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
id: @(#)elf.fth 1.9 01/05/18
purpose:
copyright: Copyright 1991-2001 Sun Microsystems, Inc.  All Rights Reserved

decimal
headerless

\
\ ELF constants
\

1  constant  ELFCLASS32
2  constant  ELFCLASS64

d#  2  constant  EM_SPARC
d# 11  constant  EM_SPARC64
d# 18  constant  EM_SPARC32PLUS

1  constant  PT_LOAD

2  constant  SHT_SYMTAB
3  constant  SHT_STRTAB

struct  \ ELF32 File Header
  0  field >e32_ident		\ Alias for the next 16 bytes
  4  field >e32_magicword	\ \7fELF
  1  field >e32_class		\ 32- or 64-bit
  1  field >e32_data		\ endianness
  1  field >e32_iversion	\
  9  field >e32_pad		\ ( reserved )
  /w field >e32_type		\ file type
  /w field >e32_machine		\ target machine
  /l field >e32_version		\ file version
  /l field >e32_entry		\ start address
  /l field >e32_phoff		\ phdr file offset
  /l field >e32_shoff		\ shdr file offset
  /l field >e32_flags		\ file flags
  /w field >e32_ehsize		\ sizeof ehdr
  /w field >e32_phentsize	\ sizeof phdr
  /w field >e32_phnum		\ number phdrs
  /w field >e32_shentsize	\ sizeof shdr
  /w field >e32_shnum		\ number shdrs
  /w field >e32_shstrndx	\ shdr string index
constant /elf32-header

/elf32-header buffer: elf32-header

: e32_magicword  ( -- n )  elf32-header >e32_magicword  l@  ;
: e32_machine    ( -- n )  elf32-header >e32_machine    w@  ;
: e32_class      ( -- n )  elf32-header >e32_class      c@  ;
: e32_entry      ( -- n )  elf32-header >e32_entry      l@  ;
: e32_phoff      ( -- n )  elf32-header >e32_phoff      l@  ;
: e32_phentsize  ( -- n )  elf32-header >e32_phentsize  w@  ;
: e32_phnum      ( -- n )  elf32-header >e32_phnum      w@  ;
: e32_shoff      ( -- n )  elf32-header >e32_shoff      l@  ;
: e32_shentsize  ( -- n )  elf32-header >e32_shentsize  w@  ;
: e32_shnum      ( -- n )  elf32-header >e32_shnum      w@  ;

struct  \ ELF32 Program Header
  /l field >p32_type         \ entry type
  /l field >p32_offset       \ file offset
  /l field >p32_vaddr        \ virtual address
  /l field >p32_paddr        \ physical address
  /l field >p32_filesz       \ file size
  /l field >p32_memsz        \ memory size
  /l field >p32_flags        \ entry flags
  /l field >p32_align        \ memory/file alignment
constant /elf32-pheader

/elf32-pheader buffer: elf32-pheader

: p32_type    ( -- n )  elf32-pheader >p32_type    l@  ;
: p32_offset  ( -- n )  elf32-pheader >p32_offset  l@  ;
: p32_vaddr   ( -- n )  elf32-pheader >p32_vaddr   l@  ;
: p32_filesz  ( -- n )  elf32-pheader >p32_filesz  l@  ;
: p32_memsz   ( -- n )  elf32-pheader >p32_memsz   l@  ;
: p32_flags   ( -- n )  elf32-pheader >p32_flags   l@  ;
: p32_align   ( -- n )  elf32-pheader >p32_align   l@  ;

struct  \ ELF32 Section Header
  /l field >sh32_name        \ section name
  /l field >sh32_type        \ section type
  /l field >sh32_flags       \ section flags
  /l field >sh32_addr        \ virtual address
  /l field >sh32_offset      \ file offset
  /l field >sh32_size        \ section size
  /l field >sh32_link        \ misc info
  /l field >sh32_info        \ misc info
  /l field >sh32_addralign   \ memory alignment
  /l field >sh32_entsize     \ entry size if table
constant /elf32-sheader

/elf32-sheader buffer: elf32-sheader

: sh32_flags   ( -- n )  elf32-sheader >sh32_flags   l@  ;
: sh32_type    ( -- n )  elf32-sheader >sh32_type    l@  ;
: sh32_offset  ( -- n )  elf32-sheader >sh32_offset  l@  ;
: sh32_size    ( -- n )  elf32-sheader >sh32_size    l@  ;
: sh32_link    ( -- n )  elf32-sheader >sh32_link    l@  ;

struct  \ ELF32 symbol table entry
  /l field st32_name
  /l field st32_value
  /l field st32_size
  /c field st32_info
  /c field st32_other
  /w field st32_shndx
constant /elf32-symbol
headers
