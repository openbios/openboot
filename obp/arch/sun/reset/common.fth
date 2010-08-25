\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: common.fth
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
id: @(#)common.fth 1.2 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

: ,string ( adr,len -- )
   here over  allot place-cstr drop
;
: ,decimal ( n -- )
   base @ >r decimal
   <# u#s u#>   here over allot place-cstr drop
   r> base !
;

create sccs-id
   " "r"n@(#)OBP "     ,string
   obp-release count   ,string
   "  "                ,string
   compile-signature compile-date$   ,string
[ifndef] SUN4V
   banner-name$ dup if "  " ,string ,string else 2drop then
[then]
   sub-release  count  ?dup if  "  " ,string  ,string  else  drop  then
   0 c,

0 value obj-base
0 value obj-size

also assembler definitions

[ifexist] eprom-pa
: >prom-addr ( symbol -- pa )  obj-base - eprom-pa + ;
[then]

: $set-external  ( name$ register -- )
   >r				( name$ ) ( r: reg)
   0 r@  sethi			( $name ) ( r: reg )
   2>r here obj-base - 4 - 2r>	( adr $name ) ( r: reg )
   3dup				( adr $name adr $name ) ( r: reg )
   $set-reference-hi22		( adr name$ ) ( r: reg )
   r@ 0 r> or			( adr name$ )
   here obj-base - 4 - -rot	( adr adr2 name$ )
   $set-reference-lo10		( adr )
   drop
;

: $export-procedure ( adr name$ -- )
   rot obj-base -   -rot external-procedure $add-symbol
;

: $acall   ( procedure-name$ -- )
   [ also assembler ]

   here call		\ make space for relocatable addr
   here 4 - obj-base -  ( procedure-name$ offset )
   -rot  $add-call	\ symtab entry
   [ previous ]
;

: clear-call-stack
   %o7  %g6 move
   here 8 + call nop
   here 8 + call nop
   here 8 + call nop
   here 8 + call nop
   here 8 + call nop
   here 8 + call nop
   here 8 + call nop
   here 8 + call nop
   %g6 %o7  move
;

previous definitions
also srassembler alias $export-procedure $export-procedure previous

: dropin-size ( -- n )
   decomp-size 4 round-up
   obj-size    4 round-up +
   h# 20 -	\ Drop-in Header Size
;

: save-obj ( pstr -- )
   terminate-string-table
   new-file

   dropin-magic      obj-base 0 la+ l!	\ MAGIC
   dropin-size       obj-base 1 la+ l!	\ Size
   0                 obj-base 2 la+ l!	\ Reserved
   0                 obj-base 3 la+ l!	\ Reserved
   0                 obj-base 4 la+ x!
   " OBP"            obj-base 4 la+ place-cstr drop
   compile-signature xlsplit obj-base d# 11 wa+ w!
   ( date.time )     obj-base d# 6 la+ l!
   0                 obj-base d# 7 la+ l!
   major-release#    obj-base d# 28 ca+ c!
   minor-release#    obj-base d# 29 ca+ c!
   patch-release#    obj-base d# 30 ca+ c!
   h# 7f             obj-base d# 31 ca+ c!

   /elf32-header /section-headers +     ( first-offset )

   /section-names        1 !loc   \ Section name table size
   obj-size              2 !loc   \ Text size
   0                     3 !loc   \ Data size
   0                     4 !loc   \ BSS size
   /relocation-table     5 !loc   \ Text reloc. table size
   0                     6 !loc   \ Data reloc. table size
   /symbol-table         7 !loc   \ Symbol table size
   /string-table         8 !loc   \ String table size
   drop

   default-elf-header   /elf32-header      ofd @  fputs   \ ELF header
   section-headers      /section-headers   ofd @  fputs   \ Section headers
   section-names        /section-names     ofd @  fputs   \ Section name table

   obj-base             obj-size           ofd @  fputs

   relocation-table     /relocation-table  ofd @  fputs
   symbol-table         /symbol-table      ofd @  fputs
   string-table         /string-table      ofd @  fputs

   ofd @ fclose
;

0 value symbol.fd

: begin-obj  ( -- )
   [ also assembler ] init-labels [ previous ]
   h# 1000 [ also assembler ] .align [ previous ]
   here is obj-base
   p" reset.symbols" new-file ofd @ is symbol.fd
   " # This is a machine generated file"r"n" symbol.fd fputs
;

: end-obj ( -- )
   end-code  here obj-base - to obj-size
   symbol.fd ?dup if fclose  then
;

0 value in-label?
: (check-stack) ( -- )
   depth if
      where  lastacf .name
      depth 0< if ." underflowed" else ." mangled" then
      ."  the stack" cr abort
   then
;

: (write-trace) ( N -- )
   symbol.fd if
      "    trace: " symbol.fd fputs
      here obj-base - push-hex  (u.) pop-base symbol.fd fputs
      " ," symbol.fd fputs
      push-hex  (u.) pop-base symbol.fd fputs
      " "r"n" symbol.fd fputs
   else
      drop
   then
;

: label  ( -- )
   (check-stack)
   in-label? if
      where
      ." end-code missing from " lastacf .name
      ." .. Sequential labels are not allowed!!" cr
      abort
   then
   true to in-label?
   align here transient  value  resident
   symbol.fd if
      lastacf >name name>string symbol.fd fputs
      " : " symbol.fd fputs
      lastacf execute obj-base - push-hex  (u.) pop-base symbol.fd fputs
      " "r"n" symbol.fd fputs
   then
   do-entercode
;

also assembler definitions
: end-code ( -- )
   0 to in-label? (check-stack)
   do-exitcode
;
previous definitions
