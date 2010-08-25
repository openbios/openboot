id: @(#)sysuart.fth 2.11 00/08/02
purpose: 
copyright: Copyright 1985-1990 Bradley Forthware
copyright: Copyright 1990-2000 Sun Microsystems, Inc.  All Rights Reserved

headerless
: install-uart-io  ( -- )
   ['] lf-pstr          ['] newline-pstring  (is
   ['] ukey?            ['] key?   (is
   ['] ukey             ['] (key   (is
   ['] uemit            ['] (emit  (is
   ['] default-type     ['] (type  (is
   ['] emit1            ['] emit   (is
   ['] type1            ['] type   (is
   ['] crlf             ['] cr     (is
   ['] true             ['] (interactive? (is
   ['] key1		['] key    (is
;
headers
