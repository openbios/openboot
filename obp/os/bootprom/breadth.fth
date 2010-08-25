\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: breadth.fth
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
id: @(#)breadth.fth 2.5 02/05/02
purpose: 
copyright: Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Tree searching code:
\ This implements a funny-order search of an n-ary tree.
\ First, all the child nodes at this level are searched.
\ If not found, then the first child node is made the current node
\ and the process is repeated recursively.  If that fails, the second
\ child node is selected, and so on.
\ All the descendents of the first node will thus be searched before
\ any of the descendents of the second node.
\ This is not quite a breadth-first search.

\ Interface to code in devtree.fth:
\   first-child   ( -- another? )
\       If current-node has a first child, sets current-node to that
\	child and returns true.
\   next-child    ( -- another? )
\	If current-node has a next peer, sets current-node to that peer
\	and returns true, else sets current-node to the parent of
\	current-node and returns false.
\
\ This rather strange interface turns out to be extremely convenient
\ to use in a loop over all children; e.g.
\
\       first-child  begin while   XXX   next-child repeat
\
\ where XXX is the code to be executed for each child.

headerless

create found 0 c,
create not-found  ," Device not found"

: (search-level)  ( ? acf -- ? acf )
   first-child  begin while                ( ? acf )

      dup execute  if  found throw  then   ( ? acf )

   next-child repeat                       ( ? acf )
;

: (search-preorder)  ( ? acf -- ? acf )   recursive
   (search-level)

   first-child  begin while  (search-preorder)  next-child repeat
;

: invert-signal  ( ? acf -- ? acf )
   catch  case
      0     of     not-found throw    endof
      found of                        endof
      ( default )  throw
   endcase
;
: search-preorder  ( ? acf -- ? acf )  ['] (search-preorder)  invert-signal  ;
: search-level     ( ? acf -- ? acf )  ['] (search-level)     invert-signal  ;
headers
