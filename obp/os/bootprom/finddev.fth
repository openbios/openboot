\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: finddev.fth
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
id: @(#)finddev.fth 2.43 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.


headers

vocabulary aliases

headerless
4 /n* buffer: unit#
0 value unit#-valid?
: unit-bounds  ( -- end-adr start-adr )  unit#  '#adr-cells @ /n*  bounds  ;

: "name" ( -- adr,len )  " name"  ;  \ Space savings

\ True if "name$" matches the node's name
: name-match?  ( name$ -- name$ flag )
   "name" get-property  if                  ( name$ )
      false                                 ( name$ false )
   else                                     ( name$ adr' len' )
      1-    \ Omit null byte 		    ( name$ adr' len' )
      2over 2over  $=  if                   ( name$ adr' len' )
         2drop true                         ( name$ true )
      else                                  ( name$ adr' len' )
         \ Omit the manufacturer name and test again
         ascii , left-parse-string  2drop  2over  $=
      then
   then                                     ( name$ flag )
;

\ True if "unit-adr,space" matches the node's unit number
: unit-match?  ( -- flag )
   get-unit  if                 (  )
      false  	                ( flag )  \ No "reg" property
   else                         ( phys.lo .. phys.hi )
      true                      ( unit-adr,len )
      unit-bounds  ?do          ( unit-adr,len  flag )
         -rot  decode-int       ( flag  unit-adr,len' n )
	 i @ =  3 roll and      ( unit-adr,len' flag' )
      /n +loop                  ( unit-adr,len' flag )
      nip nip                   ( flag )
   then                         ( flag )
;

\ True if the node has no unit number and "name$" matches the node's name
: wildcard-match?  ( name$ acf -- name$ acf flag )
   >r
   dup  if
      name-match?  0=  if  r> false  exit  then
   then                                                   ( name$ )

   get-unit  0=  if   nip nip  r> false  exit  then       ( name$ )

   dup 0=  unit#-valid? 0=  and  if  r> false  exit  then

   r> true
;

: exact-match?  ( name$ acf -- name$ acf flag )
   >r
   dup  if                              ( name$ )       \ Name present
      name-match?  0=  if  r> false  exit  then
   then                                 ( name$ )
   unit#-valid?  if                     ( name$ )       \ Unit present
      unit-match?  0=  if  r> false  exit  then
   then
   r> true
;

: (package-execute) ( str,len package -- ?? )
   setup-method$ (search-wordlist) if
      execute
   else
      no-proc throw
   then
;

headers

\ 1) Search direct children for an exact match
\ 2) Search direct children for a wildcard match
\ 3) Select each child node in turn and (recursively) repeat steps
\    (1), (2), and (3)

: (find-node)  ( unit$ name$ -- unit$ name$ )

   \ If the node has no children, then there is no point in searching it,
   \ and it doesn't matter if it has no decode-unit method
   first-child  0= if  exit  then

   \ Omit unit match test if no unit string or this is a support node
   support-node? @ 0=  pop-device  unit#-valid? and  if
      2over ['] (decode-unit) catch  if
         not-found throw
      then				( unit$ name$ phys.lo .. phys.hi )
      \ We can't use unit-bounds here
      unit# #adr-cells /n*  bounds  ?do  i !  /n +loop   ( unit$ name$ )
   then

   \ (search-level) will throw "found" to (find-device) if it succeeds
   ['] exact-match?     (search-level)  drop             ( unit$ name$ )
   ['] wildcard-match?  (search-level)  drop             ( unit$ name$ )
;

: (find-child-node)  ( unit$ name$ -- unit$ name$ ) recursive
   first-child  begin while   (find-node) (find-child-node)  next-child repeat
;

: (find-device)  ( str -- )

   0 to unit#-valid?

   \ If a search path is present, find the indicated subdirectory
   begin  dup  while                       ( str )

      \ Split the remaining string at the first backslash, if there is one
      ascii / left-parse-string            ( str component-str )

      \ Separate out arguments
      ascii : left-parse-string            ( str args-str name.unit$ )

      \ Arguments only apply to "open", so discard them when searching
      2swap 2drop                          ( rem$  name.unit$ )

      \ Split name and unit
      ascii @  left-parse-string           ( rem$  unit$  name$ )

      2 pick is unit#-valid?               ( rem$  unit$  name$ )

      ['] (find-node)  catch  0=  if            ( rem$ unit$ name$ )
         ['] (find-child-node)  invert-signal   ( rem$ unit$ name$ )
      then                                      ( rem$ unit$ name$ )
      2drop 2drop
   repeat                                  ( rem$ )

   2drop
;

: not-alias?  ( str -- expansion$ false | true )
   \ Search the alias list.
   ['] aliases (search-wordlist)  if  execute false  else  true  then
;

d# 132 buffer: alias-buf

\ Expands devaliases optionally overwriting the default argument
\ to the rightmost component of the expanded pathname
: expand-alias  ( devspec$ -- pathname$ flag )

   \ Extract the part of the pathname that can be an alias

   2dup  ascii /  split-before  ( devspec$ tail$ head$ )
   ascii :  split-before        ( devspec$ tail$ arg$ name$ )

   \ If the device-specifier is not an alias, return it unmodified.

   not-alias?  if               ( devspec$ tail$ arg$ )
      2drop 2drop false  exit   ( devspec$ )
   then                         ( devspec$ tail$ arg$ expansion$ )

   \ The device-specifier is an alias.

   \ If the aliased component of the device-specifier had explicit
   \ arguments, use them to override any arguments that were included
   \ in the alias expansion.

   2 pick  if                   ( devspec$ tail$ arg$ expansion$ )
      \ alias name has args
      ascii / split-after       ( devspec$ tail$ arg$ alias-tail$ alias-head$ )
      alias-buf place           ( devspec$ tail$ arg$ alias-tail$ )
      ascii : split-before      ( devspec$ tail$ arg$ $deadargs $alias-tail$' )
      alias-buf $cat            ( devspec$ tail$ arg$ $deadargs )
      2drop  alias-buf $cat     ( devspec$ tail$ )
   else                         ( devspec$ tail$ arg$ expansion$ )
      \ alias name does not have args
      alias-buf place           ( devspec$ tail$ arg$ )
      2drop                     ( devspec$ tail$ )
   then                         ( devspec$ tail$ )

   \ Append the tail of the device specifier to the expanded alias

   alias-buf $cat               ( devspec$ )
   2drop                        ( devspec$ )
   alias-buf count  true        ( pathname$ true )
;
: aliased?  ( name-str -- name-str false | alias-expansion-str true )
   \ The empty string is not an alias
   dup 0=  if  false exit  then               ( str )

   \ A pathname beginning with a slash is not an alias
   over c@  ascii / =  if  false exit  then   ( str )

   expand-alias
;
: ?expand-alias  ( name-str -- name-str | alias-expansion-str )
   aliased? drop
;

: context-voc? ( voc acf -- voc acf false | ??) over context-voc = throw false ;

: device-context? ( -- device-node? )
   context-voc ['] root-node =  if  true exit  then
   current-voc >r also context-voc root-node            ( voc )
   ['] context-voc? ['] (search-preorder) catch nip nip ( device-node?)
   r> set-current previous				( device-node?) 
;
\ rather than move a whole load of code around it is easier to patch
\ the device-end routine in devtree.fth
patch device-context? false device-end

: ?not-found  ( flag -- )  if  not-found throw  then  ;
: noalias-find-device  ( str -- )
   \ Throw if null string
   ?dup 0=  ?not-found                 ( str$ )

   \ The path starts at the root directory if the first character is "/";
   \ otherwise it starts at the current directory
   dup 1 >=  if                        ( str$ )
      over c@  ascii /  =  if  1 /string  ['] root-node push-device  then
   then                                ( str$ )

   current-device null =  ?not-found
   device-context?  0= ?not-found
   (find-device)
;
: aliased-find-device  ( str -- )  ?expand-alias noalias-find-device  ;
headers
5 actions
action: count  ;
action: 3drop  ;        \ No "store" method
action:        ;        \ Just return the address
action: drop   ;        \ Decode method is null because string is already right
action: drop   ;        \ Encode method is null too
: $devalias  ( name-str expansion-str -- )
   also aliases definitions
   strip-blanks  2swap strip-blanks
   \ Create the alias w/o not unique warning.
   warning @ >r warning off $create r> warning !
   previous definitions
   ",
   use-actions
;
headerless
\ Do
: locate-device  ( adr len -- true  |  phandle false )
   also
   ['] aliased-find-device catch  if
      2drop true
   else
      current-device false
   then
   previous definitions
;
: noa-find-device  ( adr len -- )
   current-device >r
   ['] noalias-find-device  catch  case
      0          of  r> drop                          endof
      not-found  of  r> push-device  not-found throw  endof
      ( default )    r> push-device  throw
   endcase
;
headers
: find-device  ( adr len -- )  ?expand-alias noa-find-device  ;

: $parent-execute  ( adr len -- )
   current-device >r  pop-device  r@ >parent (package-execute)  r> push-device
;

: delete-device ( phandle -- deleted? )
   \ Save the current device
   current-device >r

   dup >parent   push-device     ( phandle )
   'child  begin                 ( phandle &phandle' )
      2dup link@ =  if           ( phandle &phandle' )
         true true               ( phandle &phandle' true true )
      else                       ( phandle &phandle' )
         link@ dup null =  if    ( phandle null )
            drop false true      ( phandle false true )
         else                    ( phandle phandle' )
            push-device 'peer    ( phandle &phandle" )
            false                ( phandle &phandle" done? )
         then                    ( phandle &phandle" false )
      then                       ( phandle &phandle' true true )
      \ OR                       ( phandle false true )
      \ OR 			 ( phandle &phandle" false )
   until  if                     ( phandle &prev-phandle )
      swap push-device 'peer     ( &prev-phandle &next-phandle )
      link@ swap link!  true     ( ok )
   else                          ( phandle )
      drop false                 ( failed )
   then                          ( ok? )
   \ Restore the current device
   r> push-device                ( ok? )
;

: $delete-device ( path$ -- deleted? )
   locate-device  if  false  exit  then  delete-device  ( deleted? )
;
headers
