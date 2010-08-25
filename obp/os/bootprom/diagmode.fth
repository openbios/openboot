\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: diagmode.fth
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
id: @(#)diagmode.fth 2.5 04/04/28
purpose: 
copyright: Copyright 1993-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

hex
headers
defer diagnostic-mode?  ' false is diagnostic-mode?
defer svc-mode?         ' false is svc-mode?

headerless

\ First, the mode control words. These words return the current
\ effective verbosity for determining whether or not to display a
\ given "level" of output on the console. Generally, these modes
\ are hierarchical or layered in effect, lower-levels of verbosity
\ are satisfied by a higher level being set, e.g., anything you
\ would type in minimum verbosity you would also type in maximum
\ verbosity. This is reflected in the mode words with "+": 'min+mode'
\ is minimum or higher ("minimum plus"), while mode words with "-"
\ are more strictly defined as just that mode: 'brief-mode' is ONLY
\ medium ("normal" keyword) verbosity, not maximum or minimum.
\
\ 'diagnostic-mode?' set (returning "true") is treated as maximum
\ ("max" keyword) verbosity.


\ The min+mode words typeout if verbosity is "min" or higher (min,
\ "normal", "max", "debug") or if 'diagnostic?-mode' is true. For
\ example, the OpenBoot banner prints in min+mode.

defer min+mode?     ( -- flag )		\ 'true' if "min" or higher
' true is min+mode?			\ Pre-"verbosity" control


\ The brief-mode words typeout iff verbosity is "normal"; unlike other
\ verbosity-controlled typeout, higher-level verbosity (max, debug, etc)
\ do NOT count for "brief" typeout. This implements a distinct class
\ of "inbetween minimum and maximum" firmware verbosity, enough output
\ to inform the user that the firmware is alive and making progress,
\ without multiple screenfuls of cybercrud meaningless to normal mortals.
\
\ This mode is available only with full firmware verbosity control
\ implemented (i.e., 'verbosity' NVRAM configuration variable, reset-
\ level assembly support, etc.); here it is effectively nullified
\ (see verbosity.fth).

defer brief-mode?   ( -- flag )		\ 'true' if "normal" verbosity ONLY
' false is brief-mode?


\ The med+mode words typeout if verbosity is medium ("normal"
\ keyword) or higher, or if 'diagnostic-mode?' is true.
\
\ As with brief above, this is available only with full firmware
\ verbosity control implemented, and is by default disabled.

defer med+mode?     ( -- flag )		\ 'true' if medium or higher verbosity
' false is med+mode?			\ Pre-verbosity control


\ The max+mode words effectively overlay with the "diag-" words,
\ with the exception of 'max+mode?' which exists in its own right.
\ This mode maps exactly to pre-verbosity-controlled output levels
\ controlled by 1275 'diagnostic-mode?' unless full firmware
\ verbosity control is implemented (see verbosity.fth).

defer max+mode?     ( -- flag )		\ 'true' if max/debug/diag
' diagnostic-mode? is max+mode?		\ Pre-"verbosity" control


\ The "debug" mode words typeout if verbosity is debug or higher.
\ The default here is driven by stand-init-debug.  Note that
\ 'diagnostic-mode?' does NOT feed into "debug or higher" verbosity.

defer debug+mode?   ( -- flag )		\ 'true' if debug/diag
[ifdef] stand-init-debug
   ' true				\ Default on for stand-init-debug
[else]
   ' false				\ Default off normally
[then]   is debug+mode?



\ For hysterical reasons (i.e., backwards-compatibility with non-
\ verbosity-supporting platforms, as well as not having to change
\ every file in OpenBoot that calls diag-type and friends), the
\ "diag-" moniker is left as is, even though the routines are now
\ more than merely 'diagnostic-mode?'-controlled output routines
\ when coupled with full firmware verbosity control (verbosity.fth).

: diag-type ( adr,len -- )  max+mode?  if  type  else  2drop  then  ;
: diag-cr   ( -- )  max+mode?  if  cr  then  ;
: diag-.d   ( n -- ) max+mode?  if  .d  else  drop  then  ;   
: diag-type-cr ( adr,len -- )  diag-type diag-cr  ;

headers
