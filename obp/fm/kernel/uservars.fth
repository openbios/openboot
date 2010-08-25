id: @(#)uservars.fth 2.14 03/12/08 13:22:17
purpose: 
copyright: Copyright 1999-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1985-1994 Bradley Forthware
copyright: Use is subject to license terms.

decimal

\ Initial user number

[ifexist] #user-init
#user-init
[else]
0
[then]

[ifndef] run-time
\ First 5 user variables are used for multitasking
     dup user link		\ link to next task
/n + dup user entry		\ entry address for this task
 /n + dup user saved-rp	\ this is not MP safe
 /n + dup user saved-sp	\ this is not MP safe
[then]

\ next 2 user variables are used for booting
/n + dup user up0     \ initial up
/n + dup user #user   \ next available user location
/n +     #user-t !

/n constant #ualign
: ualigned  ( n -- n' )  #ualign round-up  ;

: (check-user-size) ( #bytes -- #bytes )
   dup #user @ + user-size >= abort" ERROR: User area used up!"   ( #bytes )
;

\  These will be altered later to enable user space to grow on demand:
user-size-t value user-size
defer check-user-size  ' (check-user-size) is check-user-size

: ualloc  ( #bytes -- new-user-number )  \ allocates user space
   check-user-size
   \ If we are allocating fewer bytes than the alignment granularity,
   \ it is safe to assume that strict alignment is not required.
   \ For example, a 2-byte token doesn't have to be aligned on a 4-byte
   \ boundary.
							   ( #bytes )
   #user @						   ( #bytes user# )
   over #ualign >=  if  ualigned dup #user !  then	   ( #bytes user#' )

   swap #user +!
;

[ifndef] run-time
: nuser  \ name  ( -- )  \ like user but automatically allocates space
   /n ualloc user
;
: tuser  \ name  ( -- )  \ like user but automatically allocates space
   /token ualloc user
;
: auser  \ name  ( -- )  \ like user but automatically allocates space
   /a ualloc user
;
[then]

nuser .sp0			\ initial parameter stack
nuser .rp0			\ initial return stack

defer sp0	' .sp0 is sp0	\ MPsafe versions
defer rp0	' .rp0 is rp0	\ MPsafe versions

headerless
\ This is the beginning of the initialization chain
chain: init ( -- )  up@ link !  ;	\ Initially, only one task is active
headers
