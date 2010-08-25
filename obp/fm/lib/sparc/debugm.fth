\ debugm.fth 1.13 02/08/22
\ Copyright 1990 Bradley Forthware
\ Copyright 2002 Sun Microsystems, Inc.  All Rights Reserved
\ copyright: Use is subject to license terms.
\ Machine-dependent support routines for Forth debugger.

\dtc [define] T32_KERNEL
[ifdef] T32_KERNEL
hex

headerless
: low-dictionary-adr  ( -- adr )  origin  ;

nuser debug-next  \ Pointer to "next"
headers
vocabulary bug   bug also definitions
headerless
nuser 'debug   \ code field for high level trace
nuser <ip      \ lower limit of ip
nuser ip>      \ upper limit of ip
nuser cnt      \ how many times thru debug next

label _flush_cache  ( -- )
   %o7 8  %g0  jmpl
   nop
end-code

label _disable_cache  ( -- )
   %o7 8  %g0  jmpl
   nop
end-code

\ Change all the next routines in the indicated range to jump through
\ the user area vector
code slow-next  ( high low -- )
\ \dtc   _disable_cache call  nop
\dtc				\ Low address in tos
\dtc   sp  scr  pop		\ High address in scr
\dtc   h# e0016000  sc2  set	\ First word of "next"
\dtc   h# 81c40002  sc3  set	\ Second word of "next"
\dtc 64\ h# e058e000  sc4  set	\ Template for first word of replacement "next"
				\ ldx [%g3+0],%l0

\dtc 32\ h# e000e000  sc4  set	\ Template for first word of replacement "next"
\dtc   sc4  'user# debug-next  sc4  add  \ add user number (up nnn scr ld)
\dtc   h# 81c42000  sc5  set	\ Second word of replacement "next" (scr jmpl)
\dtc   h# 80000000  sc7  set	\ Third word of replacement "next" (nop)
\dtc
\dtc   begin
\dtc      tos scr  cmp		\ Loop over addresses from low to high
\dtc   u< while  nop
\dtc      tos 0  sc6  ld
\dtc      sc6    sc2  cmp
\dtc      = if  nop
\dtc         tos 4  sc6  ld
\dtc         sc6    sc3  cmp
\dtc         = if  nop
\dtc            sc4  tos 0  st 	tos  0   iflush
\dtc            sc5  tos 4  st	tos  4   iflush
\dtc            sc7  tos 8  st	tos  8   iflush
\dtc         then
\dtc      then
\dtc      tos 4  tos  add
\dtc   repeat  nop
\ \dtc   _flush_cache call  nop
\dtc   sp   tos  pop
c;

\ Change all the next routines in the indicated range to perform the
\ in-line next routine
code fast-next  ( high low -- )
\ \dtc   _disable_cache call  nop
\dtc				\ Low address in tos
\dtc   sp  scr  pop		\ High address in scr
\dtc   h# e0016000  sc2  set	\ First word of "next"
\dtc   h# 81c40002  sc3  set	\ Second word of "next"
\dtc 32\ h# e000e000  sc4  set	\ Template for first word of replacement "next"
\dtc 64\ h# e058e000  sc4  set	\ Template for first word of replacement "next"
\dtc   sc4  'user# debug-next  sc4  add  \ add user number (up nnn scr ld)
\dtc   h# 81c42000  sc5  set	\ Second word of replacement "next" (scr jmpl)
\dtc   h# 8a016004  sc7  set	\ Third word of "next"
\dtc
\dtc   begin
\dtc      tos scr  cmp		\ Loop over addresses from low to high
\dtc   u< while  nop
\dtc      tos 0  sc6  ld
\dtc      sc6    sc4  cmp
\dtc      = if  nop
\dtc         tos 4  sc6  ld
\dtc         sc6    sc5  cmp
\dtc         = if  nop
\dtc            sc2  tos 0  st	tos  0   iflush
\dtc            sc3  tos 4  st	tos  4   iflush
\dtc            sc7  tos 8  st	tos  8   iflush
\dtc         then
\dtc      then
\dtc      tos 4  tos  add
\dtc   repeat  nop
\ \dtc   _flush_cache call  nop
\dtc   sp   tos  pop
c;

label normal-next
   \ This is slightly different from the normal next (the order of
   \ the registers in the jmpl instruction is reversed) so that it
   \ won't be clobbered by slow-next
   ip 0      scr  ld
   base scr  %g0  jmpl
   ip 4      ip   add
end-code

label debnext
   'user <ip  scr  nget
   ip         scr  cmp
   u>= if  nop
      'user ip>  scr  nget
      ip         scr  cmp
      u<= if  nop
         'user cnt  scr  nget
         scr 1      scr  add
	 scr  'user cnt  nput
         scr        2    cmp
	 = if  nop
            %g0             'user cnt  nput
            normal-next origin -  scr  set	\ Relative address
            scr base              scr  add	\ Absolute address
            scr      'user debug-next  nput
            'user 'debug          scr  ld	\ This is a token, not absolute
            scr base              %g0  jmpl
            nop
         then
      then
   then
   \ This is slightly different from the normal next (the order of
   \ the registers in the jmpl instruction is reversed) so that it
   \ won't be clobbered by slow-next
   ip 0      scr  ld
   base scr  %g0  jmpl
   ip 4      ip   add
end-code

\ Fix the next routine to use the debug version
: pnext   (s -- )  debnext debug-next !  ;

\ Turn off debugging
: unbug   (s -- )  normal-next debug-next !  ;

headers

forth definitions
unbug

[then]
