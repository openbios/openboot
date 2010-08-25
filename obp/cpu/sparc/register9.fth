\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: register9.fth
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
id: @(#)register9.fth 1.12 06/02/16 19:17:20
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ This version uses multiple-code-field defining words for the self-fetching
\ register names.

\ Display and modify the saved state of the machine.
\
\ This code is highly machine-dependent.
\
\ Version for the Spitfire processor
\
\ Requires:
\
\ >state  ( offset -- addr )
\	Returns an address within the processor state array given the
\	offset into that array
\ #windows ( -- n )
\	The number of implemented register windows
\ window-registers ( -- offset )
\	The offset from CPU-STATE to the start of the area where the
\	window registers are stored
\
\ Defines:
\
\ %g0 .. %g7  %o0 .. %o7  %l0 .. %l7  %i0 .. %i7
\ %pc %npc %y %psr %wim %tbr
\ cwp
\ w
\ .registers .locals

needs action: objects.fth

decimal

only forth hidden also forth also definitions

\ This is used to examine state inside the cpu struct.
headerless
0 value cpu-reg-offset
4 actions
action:  w@ >state cpu-reg-offset + @  ;
action:  w@ >state cpu-reg-offset + !  ; \ to
action:  w@ >state cpu-reg-offset +   ; \ addr
action:  drop /n      ; \ size-of
transient
: global-reg  \ name  ( offset -- offset+/l )
   create  allocate-reg w,
   use-actions
;
: global-regs  \ name name ... ( offset #regs -- offset' )
   ( offset #regs )  0  ?do  global-reg  loop  ( offset' )
;
: offset-of  \ name  ( -- offset )
   parse-word ['] forth $vfind  if
      >body w@ 1
   else
      ." offset-of can't find " type  cr
      where
   then
   do-literal
; immediate
resident

headerless
d# 2047 constant V9_SP_BIAS
variable view-window
variable previous-outs
: >outreg  ( reg# -- adr flag )
   previous-outs @ dup 1 and  if
      \ 64-bit stack frame
      V9_SP_BIAS + swap na+  cpu-reg-offset + true
   else
      \ 32-bit stack frame
      swap la+ cpu-reg-offset + false
   then
;
: >window  ( reg# -- adr flag )
   view-window @ dup 1 and  if
      \ 64-bit stack frame
      V9_SP_BIAS + swap na+  cpu-reg-offset + true
   else
      \ 32-bit stack frame
      swap la+ cpu-reg-offset + false
   then
;
headers

4 actions
action:  w@  >window  if  x@  else  l@  then  ;
action:  w@  >window  if  x!  else  l!  then  ; \  to
action:  w@                                     \  addr
   view-window @  dup  1  and  if
      \ 64-bit stack frame
      swap na+
   else
      \ 32-bit stack frame
      swap la+
   then cpu-reg-offset + 
;
action:  drop view-window @ 1 and  if  /n  else /l  then  ; \ size-of
transient
: local-regs  \ name name ... ( reg# #regs -- )
   bounds  ?do  create  i w,  use-actions  loop
;
resident

4 actions
action:  w@ >outreg  if x@  else l@  then  ;
action:  w@ >outreg  if x!  else x@  then  ; \ to
action:  w@                                  \  addr
   view-window @  dup  1  and  if
      \ 64-bit stack frame
      swap na+
   else
      \ 32-bit stack frame
      swap la+
   then cpu-reg-offset + 
;
action:  drop view-window @ 1 and  if  /n  else /l  then  ; \ size-of
transient
: out-regs  \ name name ... ( #regs -- )
   ( #regs )  0  do  create  i w,  use-actions  loop
;
resident
3 action-name size-of
action-compiler: size-of

[ifdef] SUN4V
2 global-regs %tpc-1     %tpc-2
2 global-regs %tnpc-1    %tnpc-2
2 global-regs %tt-1      %tt-2
2 global-regs %tstate-1  %tstate-2
2 global-regs %gl %mmu-info-ptr
[else]
5 global-regs %tpc-1     %tpc-2     %tpc-3     %tpc-4     %tpc-5
5 global-regs %tnpc-1    %tnpc-2    %tnpc-3    %tnpc-4    %tnpc-5
5 global-regs %tt-1      %tt-2      %tt-3      %tt-4      %tt-5
5 global-regs %tstate-1  %tstate-2  %tstate-3  %tstate-4  %tstate-5

8 global-regs %v0  %v1  %v2  %v3  %v4  %v5  %v6  %v7
8 global-regs %m0  %m1  %m2  %m3  %m4  %m5  %m6  %m7

1 global-regs %lsucr
[then]

5 global-regs %tpc-c  %tnpc-c  %tt-c  %tl-c  %tstate-c

1 global-regs %pc
5 global-regs %npc  %cwp  %pil    %cansave  %otherwin
5 global-regs %ccr  %y    %fprs   %pstate   %wstate
4 global-regs %cleanwin   %tba    %asi      %canrestore

8 global-regs %g0  %g1  %g2  %g3  %g4  %g5  %g6  %g7
8 global-regs %a0  %a1  %a2  %a3  %a4  %a5  %a6  %a7

alias %base %g2
alias %up   %g3
alias %tos  %g4
alias %ip   %g5
alias %rp   %g6

\ These aren't aliases because the trap could have happened from a
\ C environment
\ global-reg %rp
\ global-reg %sp

2 global-regs %pcontext %scontext
4 global-regs %state-valid %restartable? %saved-my-self  last-trap#
3 global-regs error-reset-trap full-save? %nwins

\ Following words defined here to satisfy the
\ references to these "variables" anywhere else
: saved-my-self ( -- addr )  addr %saved-my-self  ;
: state-valid   ( -- addr )  addr %state-valid   ;
: restartable?  ( -- addr )  addr %restartable?  ;

\ The set of out registers has to be defined as a single batch.
\ They can't be defined piecemeal like global registers.
\ The set of local registers must be "batched" too.

8 out-regs    %o0  %o1  %o2  %o3  %o4  %o5  %o6  %o7

0 8 local-regs %l0  %l1  %l2  %l3  %l4  %l5  %l6  %l7
8 8 local-regs %i0  %i1  %i2  %i3  %i4  %i5  %i6  %i7

false value standalone?	\ Can be used to turn off stuff in stand.exe
headerless

0 value window#

: aligned?  ( adr -- flag )  3 and 0=  ;
defer accessible?   ( adr -- flag )
: yes-accessible  ( adr -- true )  drop true  ;
' yes-accessible is accessible?

\ Invalid, unaligned, or inaccessible call point
headers
: pointer-bad?  ( adr -- flag )   \ True if the address is not a good pointer
   dup  1 and  if   ( adr )
      \ 64-bit stack frame
      V9_SP_BIAS +
   else             ( adr )
      \ 32-bit stack frame
      n->l          ( adr )
   then				( adr )
   dup aligned?			( adr flag )
   swap accessible?		( flag flag )
   and 0=
;

[ifnexist] log2		\  Might be defined in code
headerless
: log2  ( n -- log2-of-n )
   -1 swap begin			( initl-log n )
   ?dup while
      swap 1+ swap
      u2/
   repeat 
;
headers
[then]

\ : %cwp ( -- psr.cwp )  %psr h# 1f and  ;

: 0w  ( -- )
   0 is window#
   window-registers >state
   V9_SP_BIAS -  dup previous-outs !
   8 na+  view-window !
;
: (+w)  ( -- last? )
   standalone?  if
      #windows 1 -  %cansave -       ( #valid-windows )
      window# 1+ >  if
	 addr %i0 dup previous-outs !  8 na+ view-window !
	 window#  1+  is window#
	 false exit
      then
   then

   %i6 pointer-bad?   %i6 0=  or  if
      true exit
   else
      addr %i0  previous-outs !
      %i6  view-window !
   then
   window#  1+  is window#
   false
;
: +w  ( -- )  (+w) abort" No more valid windows"  ;

: set-window  ( n -- )  0w  ( n ) 0 ?do   (+w) ?leave  loop  ;
: w  ( n -- )
   dup  set-window  window# <>  if
      ." Window number too large.  The maximum number is " window# . cr
   then
;

headerless
: .reg# ( n -- )  <# ascii : hold u#s u#> type space  ;

: .glob-regs ( adr0 -- )
   8 0  do  i .reg#  dup i xa+  x@  .nx  cr  loop  drop
;

: (.cc) ( cc -- )
   dup     8 and  if  ." N"  else  ." n"  then
   dup     4 and  if  ." Z"  else  ." z"  then
   dup     2 and  if  ." V"  else  ." v"  then
           1 and  if  ." C"  else  ." c"  then
;
: (.icc)  ( ccr -- )  ." ICC:"  (.cc)  ;
: (.xcc)  ( ccr -- )  ." XCC:"  4 rshift  (.cc)  ;
: (.ccr)  ( ccr -- ) dup (.xcc)  3 spaces  (.icc)  ;
headers
: .icc  ( -- )  %ccr (.icc)  ;
: .xcc  ( -- )  %ccr (.xcc)  ;
: .ccr  ( -- )  %ccr (.ccr)  ;

: .registers ( -- )
   ??cr
   d#  8 to-column ." Normal"
[ifndef] SUN4V
   d# 24 to-column ." Alternate"
   d# 40 to-column ." MMU"
   d# 58 to-column ." Vector" cr

   0 .reg#  %g0 .nx  %a0 .nx  %m0 .nx  %v0 .nx  cr
   1 .reg#  %g1 .nx  %a1 .nx  %m1 .nx  %v1 .nx  cr
   2 .reg#  %g2 .nx  %a2 .nx  %m2 .nx  %v2 .nx  cr
   3 .reg#  %g3 .nx  %a3 .nx  %m3 .nx  %v3 .nx  cr
   4 .reg#  %g4 .nx  %a4 .nx  %m4 .nx  %v4 .nx  cr
   5 .reg#  %g5 .nx  %a5 .nx  %m5 .nx  %v5 .nx  cr
   6 .reg#  %g6 .nx  %a6 .nx  %m6 .nx  %v6 .nx  cr
   7 .reg#  %g7 .nx  %a7 .nx  %m7 .nx  %v7 .nx  cr
[else]
   d# 24 to-column ." GL=1"   cr
   0 .reg#  %g0 .nx  %a0 .nx cr
   1 .reg#  %g1 .nx  %a1 .nx cr
   2 .reg#  %g2 .nx  %a2 .nx cr
   3 .reg#  %g3 .nx  %a3 .nx cr
   4 .reg#  %g4 .nx  %a4 .nx cr
   5 .reg#  %g5 .nx  %a5 .nx cr
   6 .reg#  %g6 .nx  %a6 .nx cr
   7 .reg#  %g7 .nx  %a7 .nx cr
[then]
   ." %PC  " %pc  .x ." %nPC " %npc .x  cr
   ." %TBA " %tba .x ." %CCR " %ccr .x .ccr  cr
;

: .globals           ( -- )  addr %g0  .glob-regs  ;
: .alternate-globals ( -- )  addr %a0  .glob-regs  ;
[ifndef] SUN4V
: .mmu-globals       ( -- )  addr %m0  .glob-regs  ;
: .vector-globals    ( -- )  addr %v0  .glob-regs  ;
[then]

: .locals ( -- )
   d#  8 to-column ." INs"
   d# 24 to-column ." LOCALs"
   d# 40 to-column ." OUTs" cr

   0 .reg#  %i0 .nx   %l0 .nx   %o0 .nx  cr
   1 .reg#  %i1 .nx   %l1 .nx   %o1 .nx  cr
   2 .reg#  %i2 .nx   %l2 .nx   %o2 .nx  cr
   3 .reg#  %i3 .nx   %l3 .nx   %o3 .nx  cr
   4 .reg#  %i4 .nx   %l4 .nx   %o4 .nx  cr
   5 .reg#  %i5 .nx   %l5 .nx   %o5 .nx  cr
   6 .reg#  %i6 .nx   %l6 .nx   %o6 .nx  cr
   7 .reg#  %i7 .nx   %l7 .nx   %o7 .nx  cr
;

: (.pstate)  ( pstate -- )
   ." AG:"    1 bits  .  \ 0
   ." IE:"    1 bits  .  \ 1
   ." PRIV:"  1 bits  .  \ 2
   ." AM:"    1 bits  .  \ 3
   ." PEF:"   1 bits  .  \ 4
   ." RED:"   1 bits  .  \ 5
   ." MM:"    2 bits  .  \ 7:6
   ." TLE:"   1 bits  .  \ 8
   ." CLE:"   1 bits  .  \ 9
   ." MG:"    1 bits  .  \ 10
   ." IG:"    1 bits  .  \ 11
   drop
;

: (.tstate) ( tstate -- )
   ." %TSTATE:" dup .x
   ."  %CWP:"  8 bits  .x cr
   ."    %PSTATE:"  d# 16 bits dup .x (.pstate) cr
   ."    %ASI:"     8 bits .x
   ."  %CCR:"     8 bits dup .x ."  " (.ccr)
   drop
;

headers
: .pstate  ( -- )  pstate@ (.pstate)  ;

: .tstate ( level -- )
   1- addr %tstate-1 swap xa+ x@ (.tstate)
;
: %tstate ( level -- n )  1- addr %tstate-1 swap xa+ x@  ;
: %tpc    ( level -- n )  1- addr %tpc-1    swap xa+ x@  ;
: %tnpc   ( level -- n )  1- addr %tnpc-1   swap xa+ x@  ;
: %tt     ( level -- n )  1- addr %tt-1     swap xa+ x@  ;

: .trap-registers ( -- )
[ifdef] SUN4V 2 [else] 6 [then] 1 do
      ." %TL:"      i .x
      ." %TT:"      i %tt .x
      ." %TPC:"     i %tpc .x
      ." %TnPC:"    i %tnpc .x cr
      i %tstate  (.tstate)
      cr cr
   loop
;

[ifndef] SUN4V
: .ver ( -- )
   ver@
   ." MAXWIN:"  5 bits     .x
   ( reserved ) 3 bits drop
   ." MAXTL:"   8 bits     .x
   ( reserved ) 8 bits  drop
   ." MASK:"    8 bits     .x
   ." IMPL:"    d# 16 bits .x
   ." MANUF:"   d# 16 bits .x
   drop
;
[then]

: init-window  ( -- )  0w  ;

: .window  ( window# -- )  w .locals  ;

: wr ( n -- )
   init-window
   #windows %cwp - + #windows mod  0  ?do
      addr %i0 dup previous-outs !
      8 na+ view-window !
   loop
;

only forth also definitions
