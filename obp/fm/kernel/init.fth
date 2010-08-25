id: @(#)init.fth 2.6 03/12/08 13:22:04
purpose: 
copyright: Copyright 1994-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1985-1994 Bradley Forthware
copyright: Use is subject to license terms.

\ Now that everything is defined, we can set the values of the
\ user variables that are shadowed in the metacompiler.

#user-t @ is #user

voc-link-t link-t@ is voc-link

here-t is fence
