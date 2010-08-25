\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: ui-cvars.fth
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
id: @(#)ui-cvars.fth 1.6 06/02/07
purpose:  
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

unexported-words

: $find-option  ( adr len -- false | xt true )
   ['] options search-wordlist
;

: find-option  ( adr len -- false | xt true )
   2dup  $find-option  if            ( adr len xt )
      nip nip  true                  ( xt true )
   else                              ( adr len )
      ." Unknown option: " type cr   ( )
      false                          ( false )
   then
;

exported-headers

: getenv-default \ name ( -- )
   parse-word dup  if				( adr len )
      find-option  if				( acf )
         do-get-default				( str,len )
      then					( )
   else						( adr len )
      2drop  ." Usage: get-default option-name" cr  ( )
   then						( )
;

: set-default  \ name  ( -- )
   parse-word dup  if				( adr len )
      find-option  if				( acf )
         do-set-default				( -- )
      then					( )
   else						( adr len )
      2drop  ." Usage: set-default option-name" cr  ( )
   then						( )
;

: set-defaults  ( -- )
   ." Setting NVRAM parameters to default values."  cr
   (set-defaults)
;

unexported-words

: to-column:  \ name ( col# -- )  ( -- )
   create c,  does>  c@ to-column
;

d# 24 to-column: value-column
d# 55 to-column: default-column

: (type-entry)  ( adr,len  -- )
   2dup text?  if
      bounds  ?do
	 i c@  dup  newline =  if
	    drop cr value-column  exit? ?leave
	 else
	    emit
	 then
      loop
   else
      chdump
   then
;
: $type-entry  ( adr len -- )
   tuck 2dup text?  if  d# 24  else  8  then  ( len adr len len' )
   min rot over                               ( adr len' len len' )
   >  >r  (type-entry) r>  if ."  ..."  then   (  )
;
: $type-entry-long  ( adr len acf -- )  decode  (type-entry)  ;

\ XXX should be done using "string-property" or "driver" or something
\ create name " options" 1+ ",  does> count  ;  \ Include null byte in count

: show-config-entry  ( acf -- )
   >r
   r@ .name
   value-column  r@ get	r@ decode $type-entry
   r> do-get-default	default-column	$type-entry
   cr
;

: show-current-value ( acf -- )
   dup .name ." = "  value-column
   >r  r@ get  r> ( adr len acf )  $type-entry-long cr
;

: printenv-all  ( -- )
   ." Variable Name"  value-column  ." Value"
   default-column ." Default Value" cr cr

   0  ['] options  ( alf voc-acf )
   begin
      another-word?  exit?  if  if  3drop  then  false  then
   while                              ( alf' voc-acf anf )
      dup name>string " name" $=  if  ( alf' voc-acf anf )
	 \ Don't display the "name" property
         drop                         ( alf' voc-acf )
      else                            ( alf' voc-acf anf )
         name>  show-config-entry     ( alf' voc-acf )
      then                            ( alf' voc-acf )
   repeat                             (  )
   show-extra-env-vars                (  )
;

: (printenv)  ( adr len -- )
   2dup  $find-option  if
      nip nip show-current-value
   else
      show-extra-env-var
   then
;

: usage  ( -- )  ." Usage: setenv option-name value" cr  ;


: list  ( addr count -- )  \ a version of "type" used for displaying nvramrc
   bounds  ?do
      i c@ newline =  if  cr  else  i c@ emit  then
   loop
;

exported-headers

: $set-default ( name$ -- )
   $find-option if			( xt )
      do-set-default
   then
;

: $getenv  ( name$ -- true | value$ false )
   2dup  $find-option  if            ( name$ xt )
      nip nip                        ( xt )
      >r  r@ get  r> decode  false   ( value$ false )
   else                              ( value$ )
      get-env-var
   then
;

: printenv  \ [ option-name ]  ( -- )
   parse-word dup  if  (printenv)  else  2drop printenv-all  then
;

: $setenv  ( value$ name$ -- )
   2dup $find-option  if                             ( value$ name$ xt )
      nip nip

      >r r@  encode  if
         r> drop  ." Invalid value; previous value retained." cr
         exit
      then                                              ( value )

      \ We've passed all the error checks, now set the option value.

      r@ set  r> show-current-value                           ( )
   else
      put-extra-env-var
   then
;

: setenv  \ name value  ( -- )
   parse-word  -1 parse strip-blanks             ( name$ value$ )
   ?dup 0=  if  3drop usage  exit  then  2swap   ( value$ name$ )
   2 pick over or  0=  if  2drop 2drop usage   exit  then  ( value$ name$ )
   $setenv
;

unexported-words
