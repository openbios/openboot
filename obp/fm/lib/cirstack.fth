\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: cirstack.fth
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
id: @(#)cirstack.fth 1.6 03/12/08 13:22:21
purpose: 
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Circular stack defining words
\
\     Examples:
\ 10 circular-stack: foo    Create a new stack named  foo 
\				with space for 10 numbers
\ 123 foo push        Push the number 123 on the stack  foo 
\ foo pop             Pop the top element from the stack  foo 
\				onto the data stack
\ foo top@            Copy the top element from the stack  foo 
\				onto the data stack, but do not
\				remove it from the stack  foo 
\
\ Advantages of a circular stack:
\    does not have to be cleared
\    cannot overflow or underflow
\    invocation is easy
\
\ Disadvantages:
\    can silently lose data
\
\ Applications:
\  + Useful for implementing user interfaces where you want to remember
\    a limited amount of "history", such as the last n commands, or the
\    last n directories "visited", but it is not necessary to guarantee
\    unlimited backtracking.
\  + Can easily be adapted, by adding functions  pushc  and  type-circ ,
\    for keeping a history of characters, for such uses as shadowing and
\    logging console output.

\ Implementation notes:
\    The circular stack parameter field is intentionally the same as
\    the parameter field of a word defined by  buffer: .  This allows
\    us to use the  buffer:  mechanism to automatically allocate the
\    necessary storage space.
\
\    The parameter field elements are located and sized as follows:
\        pfa:		  user#		(  /user# , which is either  /l )
\  					(     or, in the \t16 model, /w )
\        pfa+/user#:	  buffer-size	( might be /n, which was /l in  )
\					( the 32-bit model, but might.  )
\					( with the introduction of the  )
\					( 64-bit model, have become /x  )
\					( because the code remained /n. )
\					( Or it might explicitly be /l, )
\					( which is plenty large enough. )
\  					( Holds the size of the data    )
\  					( area plus one cell.           )
\        pfa+/user#+/n:	  buffer-link	(  /a , which is either   /l    )
\  					(  or, in the \t16 model, /w    )
\
\    As with a   buffer: ,  user#  is the offset of a user area location
\    containing the address of an allocated memory buffer that contains
\    the circular stack data structure.
\
\    The circular stack data structure consists of the following elements:
\        current      Offset into stack data of the next element to pop,
\		      which is equivalent to the last element that was pushed;
\		      occupies one cell at the start of the structure.
\		      (Note:  Although /l would be sufficient for this, we
\		      allocate a cell to keep the data area cell-aligned.)
\        stack data   Space to store the stacked numbers.  It occupies the
\		      remainder of the structure.
\    The "limit", i.e., the size of the stack data area, is obtained
\    from the  buffer-size  minus one cell.
\
\    Invoking the circular stack by name returns one item on the stack,
\    the Parameter Field Address, referred to as  stack-pfa  in stack
\    diagrams.
\
\    Every operator that acts on a  stack-pfa  needs to convert it
\    to three items:  the buffer-address, the limit, and the current
\    pointer; that's done via the  cir-stack-params  function.  That
\    step could have been put into a  does>  clause of the defining
\    word, but it was felt that doing so would create an unwieldy
\    programming interface.

headerless
\ Implementation factors:
\
\  Common arrangement of necessary params
: cir-stack-params ( stack-pfa -- buff-adr limit current )
   dup /buffer		( stack-pfa size )
   /n - swap		( limit stack-pfa )
   do-buffer		( limit buff-adr )
   tuck @		( buff-adr limit current )
;
\
\  Store adjusted "current" offset.
\  Return addresses of both the old and the new "current" items.
: cir-stack-ptr! ( buff-adr old-current new-current -- ... )
					( ... -- old-item-adr new-item-adr )
   rot 2dup !		( old new buff-adr )	\  Store adjusted "current"
   na1+ 		( old new data-adr )	\  Bump to data-area
   dup d+ 		( old-item-ptr new-item-ptr )
;
headers

\ Create a new circular-stack;
\ when executed, it will return its PFA.
: circular-stack: ( #entries -- )  \ name
   1+ /n*			( size )
   create make-buffer
;

\ Add a number to the stack
: push  ( n stack-pfa -- )
   cir-stack-params		( n buff-adr limit current )
   dup na1+			( n buff-adr limit current next? )
   \  Adjust overflow of incremented "current"
   rot over = if drop 0 then	( n buff-adr current next )
   cir-stack-ptr!		( n old-item-adr new-item-adr )
   \  Store into "new" item address
   nip !
;
 
\ Remove a number from the stack
: pop  ( stack-pfa -- n )
   cir-stack-params		( buff-adr limit current )
   \  Adjust imminent underflow of "current", then decrement
   tuck				( buff-adr current limit current )
   if drop dup then /n -	( buff-adr current next ) 
   cir-stack-ptr!		( old-item-adr new-item-adr )
   \  Fetch from "current" (now "old") item address
   drop @
;

\ Return, without popping, the number on top of the stack
: top@  ( stack-pfa -- n )
   cir-stack-params		( buff-adr limit current )
   \  Fetch from "current" item address.  Bump to data-area
   nip na1+ +  @
;
