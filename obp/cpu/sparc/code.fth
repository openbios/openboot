\ code.fth 2.6 02/05/02
\ Copyright 1985-1990 Bradley Forthware
\ Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

headers

defer do-label-hook ' noop is do-label-hook

: label  \ name  ( -- )
   create  do-entercode  do-label-hook  does> aligned
;

: code \ name ( -- )
    code do-label-hook
;

headerless
