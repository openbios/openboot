id: @(#)loadsyms.fth 1.5 02/05/02
copyright: Copyright 1991-1994 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1994 Firmworks  All Rights Reserved
copyright: Copyright 1994-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

: headerless:  ( r-xt -- )  origin+  create 0 setalias  ;
: header:      ( r-xt -- )  drop [compile] \ ; immediate

hex  alias h# noop

[ifndef] kernel-hdr-file
true abort" kernel-hdr-file not defined"
[then]
[defined] kernel-hdr-file included

