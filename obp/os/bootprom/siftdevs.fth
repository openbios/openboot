id: @(#)siftdevs.fth 1.5 00/09/15
purpose: Sift through the device-tree, using the enhanced display format.
copyright: Copyright 1994 FirmWorks  All Rights Reserved
copyright: Copyright 1995-1999 Sun Microsystems, Inc.  All Rights Reserved

only forth also hidden also definitions

headerless

\  Plug this in to the "hook" for showing a name only once.
\	Show the name of the device being sifted.
: .dev ( -- )   .in ." device  " pwd  ['] noop is .voc ;

\  Sift through the given node,
\      using the sift-string packed into  pad .
\	Control the display with  exit?
: (sift-node?) ( node-acf -- exit? )
    ['] .dev is .voc
    pad count rot
    vsift?
;


\  Sift through the current device-node,
\      using the sift-string packed into  pad .
\      and controlling the display with  exit?
: (sift-dev?) ( -- exit? )
    context-voc (sift-node?)
;

\  Do the actual work, using the sift-string given
\      on the stack as  addr,len  and the ACF of
\      either  sift-dev  or  sift-props (also given)
: $sift-nodes ( addr len ACF -- )
   >r
   pad place
   current-voc also			\  Save current search-order
      root-node r@ execute 0= if	\  Search root-device as well!
	 r@ ['] (search-preorder) catch 2drop
      then r> drop
   previous current token!		\  Restore old search-order
;


headers
forth definitions

\  Sift through all the device-nodes for the string given on the stack
: $sift-devs ( addr len -- )
   ['] (sift-dev?) $sift-nodes
;

\  Sift through all the device-nodes for the string given in the input stream.
: sift-devs  \ name  ( -- )
   safe-parse-word $sift-devs
;

only forth also definitions
