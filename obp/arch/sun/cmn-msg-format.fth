\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: cmn-msg-format.fth
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
id: @(#)cmn-msg-format.fth 1.15 06/04/21 17:06:50
purpose: Common messaging framework
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved.
copyright: Use is subject to license terms.

headerless

defer platform-fatal-hook    ' noop is platform-fatal-hook
defer platform-error-hook    ' noop is platform-error-hook
defer platform-warning-hook  ' noop is platform-warning-hook
defer platform-note-hook     ' noop is platform-note-hook
defer platform-cmn-end-hook  ' noop is platform-cmn-end-hook
defer platform-cmn-end-hook2 ' noop is platform-cmn-end-hook2

\ System FATAL and ERROR flags
\ If you set the fatal state the machine will suppress the boot command
\ and will not attempt to auto-boot, it will also print an ugly message.
\ If you set the error-state? an auto-boot? may not happen.

0 value system-fatal-state?
0 value system-error-state?

headers vocabulary cmn-messaging
also cmn-messaging definitions 
headerless

\ Message categories are as follows:
\ we are converting these numbers into the matching bitpatterns that the
\ verbosity framework uses so we can use simple AND logic to determine if
\ the message is printed.

VRBS-MAX VRBS-DEBUG             or      constant cmn-type 
h# 40               cmn-type    or      constant cmn-msg 
VRBS-MED            cmn-msg     or      constant cmn-note 
VRBS-MIN            cmn-note    or      constant cmn-warning 
h# 80               cmn-warning or      constant cmn-error 
VRBS-NONE           cmn-error   or      constant cmn-fatal 

\ Message Frame Data Structure Format
\ Each message frame contains the following fields:
\
\ 8 bytes - address of the parent frame (0 if no parent) 
\ 8 bytes - address of the first child frame (0 if no children)
\ 8 bytes - address of the next peer frame (0 if no more peers) 
\ 8 bytes - address of the message buffer (allocated dynamically) 
\ 8 bytes - phandle of the device pathname associated with message 
\ 1 byte  - category of common message
\ 1 byte  - message completion flag (true/false)

struct
/n       field >cmn-parent      \ address of the parent frame
/n       field >cmn-child       \ address of the first child frame
/n       field >cmn-peer        \ address of the peer frame
/n	 field >cmn-message     \ address of the message buffer 
/n       field >cmn-phandle     \ phandle of the device pathname
/c       field >cmn-category    \ category of common message
/c       field >cmn-completion  \ message completion flag
constant /cmn-frame

\ Message Data Structure Format
\ Each message contains the following fields:
\
\ 2 bytes - max length of the current string
\ 2 bytes - length of the current text sting
\ N bytes - current text sting itself

struct
/w      field >cmn-message>maxlen \ max length of the long string
/w      field >cmn-message>lstr   \ start of long counted text string
constant /cmn-message

\ Size of initial message buffer and size of each increment
d# 255 constant max-message-len  

variable current-frame$ 0 current-frame$ ! \ pointer to the current message frame

\ Long packed strings format: first 2 bytes - count, then string itself.
\ long-count takes long packed string address from the stack and returns
\ the string address and the length of the string on the stack.

: long-count ( lpstr -- str,len) dup wa1+ swap w@ ;

\ Concatenates a string to the end of packed long string
: $long-cat  ( adr len lpstr -- )
   >r r@ long-count ca+ ( adr len end-adr ) ( r: lpstr )
   swap dup >r        ( adr end-adr len )   ( r: lpstr len )
   cmove r> r>        ( len lpstr )
   dup w@ rot ca+ swap w!
;

\ Concatenates a given number of spaces to end of packed long string
: $long-spaces ( n lpstr -- )
   >r r@ long-count ca+  ( n end-adr ) ( r: lpstr )
   over bl fill	r>       ( n lpstr )
   dup w@ rot ca+ swap w!
;

\ Returns phandle for active instance or 0 if no instance
: ?phandle ( -- phandle|0)  my-self dup  if  ihandle>phandle  then ;

\ Add a new child to the current frame.
\ If this is the first child, it becomes the frame's >cmn-child.
\ Otherwise it becomes the last entry in the >cmn-peer chain starting from >cmn-child.

: add-new-child ( new-frame-addr -- ) 
   current-frame$ @ >cmn-child 
   begin
      dup @
   while
      @ >cmn-peer
   repeat
   !
;

: current>message ( -- addr) current-frame$  @ >cmn-message ;
: current>string  ( -- addr) current>message @ >cmn-message>lstr ;
: current>maxlen  ( -- addr) current>message @ >cmn-message>maxlen ;

\ Ensures that current>string is long enough to $long-cat n bytes 

: expand-current>string ( n -- )

   \ Calculate length of new string
   current>string w@ +         	( len ) 

   \ Retrieve the max length of the current message buffer and compare 
   dup current>maxlen w@ >  if  	\ Need allocate bigger message buffer

      \ Calculate the size of the new message frame
      max-message-len / 1+ max-message-len *  ( new-len )
 
      \ Allocate new message buffer     
      dup /cmn-message + alloc-mem ( new-len new-buffer-addr ) 

      \ Erase new message buffer header
      dup /cmn-message erase   	( new-len new-buffer-addr )

      \ Move old message to the new bigger buffer
      dup >cmn-message>lstr current>string long-count rot $long-cat ( new-len new-buffer-addr )
 
      \ Update new buffer maxlen field 
      tuck >cmn-message>maxlen w!   ( new-buffer-addr )   

      \ Release old message buffer
      current>message @        	( new-buffer-addr old-buffer-addr ) 
      current>maxlen w@        	( new-buffer-addr old-buffer-addr old-len )
      /cmn-message + free-mem  	( new-buffer-addr )

      \ Update message frame >cmn-message pointer  
      current>message !        	( ) 
      
   else				( len )
      drop 			( )
   then                        	( )
;

\ Like "type", but buffered into current message frame
: buffered-type ( adr,len -- )
   dup expand-current>string		( adr,len )
   current>string $long-cat		( )
;

\ Like "spaces", but buffered into current message frame
: buffered-spaces ( n -- )
   dup expand-current>string		( adr,len )
   current>string $long-spaces
;

\ There is one [ifdef] in this file: [ifdef] cmn-reentrant?
\ this is a place holder so that the entire cmn-append code becomes
\ re-entrant.
\
\ FWARC/2004/311 format encoder extension
\ 
\ This works by parsing the string from left->right, recursing until all the
\ tokens are encoded, and then pushing the stack items into the fmt-data
\ structures on the return (unnesting) path.
\
\ Once the sequence is complete the stack is logically empty and the entire
\ sequence is replayed left-to-right.
\
\ Each fmt-data structure will contain the acf of the number->string encoder
\ appropriate for the encoding and the actual stack data.
\ After each node is processed the node is released.
\ 
\ Everything ends up being funnelled through the (fmt-s) routine, so buffering
\ the constructed message should be trivial - though it will be assembled in
\ pieces.
\ 
\ How to use this:
\
\     1) man  printf            and read, this covers the basics.
\     2) the delta with printf is the % behaviour; printf will consume
\        the %<illegal> and this implemention does not.
\        If you want to print a %x (a reserved sequence) you need to
\        escape the % by using another one. %%x
\
\ Valid encodings are:
\ 
\       %c              - character
\       %d              - signed decimal 32bit value
\       %x              - unsigned hex 32bit value
\       %ld             - signed decimal 64bit value
\       %lx             - unsigned hex 64bit value
\
\ In addition you can encode field widths for all the valid encodings.
\
\ An example using decimal.
\ 
\       %5d             - put a 32bit signed decimal number in
\                         a field width of 5, the number is truncated
\                         and right justified.
\       %-5d            - put a 32bit signed decimal number in
\                         a field width of 5, the number is truncated
\                         and left justified.
\ 
\ A simple example, print a name and an age and a newline.
\
\  : display-record ( name$ age -- )
\     cmn-type[ " %s is %d years old"r"n" ]cmn-end
\  ;
\
\ Note that the arguments are used in the order they appear in the stack
\ diagram - from left to right, NOT by their stack positions.
\
\ Extending the example a little, to put the name and age in fixed width
\ fields: 10 characters for the name, left justified and 3 for the age.
\ 
\  : display-record ( name$ age -- )
\     cmn-type[ " %-10s is %3d years old"r"n" ]cmn-end
\  ;

variable fmt-head
variable fmt-tail
struct
   /n    field >fmt-next                \ next format block
   /c    field >fmt-width               \ field width
   /c    field >fmt-flags               \ bit0 = Long Value, bit1 = unsigned
   /w    field >fmt-data
   /n    field >fmt-encode              \ type encoder
   2 /n* field >fmt-args                \ data for encoder
constant /fmt-data

\ ff is -1.
\ a primitive sign extending c@ would be nice - like <w@

[ifnexist] <c@
: <c@ ( n -- x ) c@ dup h# 80 and if d# 256 - then ;
[then]

\ copy the args out
: (fmt-s)  ( ptr -- )
   >r r@ >fmt-args 2@                   ( str len )
   r> >fmt-width <c@                    ( str len )
   ?dup if
      >r r@ 0< if                       ( str,len )
         r@ abs min                     ( str,len' )
         tuck buffered-type		( len' )
         r> +                           ( n )
         negate buffered-spaces exit 	( )
      else                              ( str,len )
         r@ min                         ( str,len )
         r> over - buffered-spaces	( )
      then
   then
   buffered-type
;

: (fmt-cpy) ( ptr -- )  >fmt-args 2@ buffered-type ;
: (fmt-c) ( ptr -- )
   >r
   r@ >fmt-args @ r@ >fmt-data c!
   r@ >fmt-data 1 r@ >fmt-args 2!
   r> (fmt-s)
;
: (fmt-.n) ( ptr -- )
   >r r@ >fmt-args dup @                ( dptr data )
   r@ >fmt-flags c@ case                ( dptr data )
      0 of over l! dup <l@ (.) endof   \ signed 32 bit
      1 of (.)                 endof   \ 64 bit, signed
      2 of over l! dup l@ (u.) endof   \ unsigned 32 bit
      3 of (u.)                endof   \ 64 bit, unsigned
   endcase 
   rot 2!                               ( )
   r> (fmt-s)                           ( )
;

: (fmt-.d) ( ptr -- )   decimal (fmt-.n) ;
: (fmt-.x) ( ptr -- )   hex (fmt-.n) ;

: (fmt-save) ( ?? items ptr -- )
   >r case                              ( ?? )
     0 of                       endof   ( )
     1 of  r@ >fmt-args !       endof   ( )
     2 of  r@ >fmt-args 2!      endof   ( )
     ." Can't support " .d ." arguments in common messaging string" cr
     abort
   endcase                              ( )
   r> drop                              ( )
;

: (fmt-push) ( ?? items code acf -- node )
   /fmt-data alloc-mem >r               ( )
   r@ >fmt-encode !                     ( ?? items code )
   wbsplit                              ( ?? items width flags )
   r@ >fmt-flags c!                     ( ?? items width )
   r@ >fmt-width c!                     ( ?? items )
   0 r@ >fmt-next !                     ( ?? items )
   r@ (fmt-save)                        ( )
   r@                                   ( node )
   fmt-tail dup @                       ( node ptr tail )
   r@                                   ( node ptr tail node )
   rot !                                ( node tail )
   ?dup if                              ( node tail )
      >fmt-next !                       ( )
   else                                 ( node )
      fmt-head !                        ( )
   then                                 ( )
   r>                                   ( node )
;

\ Unroll the string
: (fmt-exec) ( -- )
   fmt-head @                           ( ptr )
   begin                                ( ptr )
      ?dup while                        ( ptr )
      >r r@ r@ >fmt-encode @ execute    ( ptr )
      r@ >fmt-next @                    ( ptr )
      r> /fmt-data free-mem             ( ptr )
      dup fmt-head !                    ( ptr )
   repeat                               ( )
;

: (fmt-valid?) ( ptr -- flag )
   c@ case
      ascii d of true endof     \ decimal
      ascii x of true endof     \ hex
      ascii c of true endof     \ char
      ascii s of true endof     \ string
      ascii p of true endof     \ pointer
      false swap
   endcase
;

\ verify that the string contains a valid encoder sequence.
\ return the skip size (2 for ld), (1 for d) for example.
\ and a flag.

: (sfmt-valid?) ( str,len -- str,len,n,-1 | str,len,0 )
   dup 2 >= if                          ( str,len )
      over c@ ascii l = if              ( str,len )
         over 1+ (fmt-valid?) if        ( str,len )
            2 true                      ( str,len )
         else                           ( str,len )
            false                       ( str,len,0 )
         then                           ( str,len )
         exit                           ( str,len,n,-1 | str,len,0 )
      then                              ( str,len )
   then                                 ( str,len )
   over (fmt-valid?) if                 ( str,len )
      1 true                            ( str,len,1,true )
   else                                 ( str,len )
      false                             ( str,len,0 )
   then                                 ( str,len,n,-1 | str,len,0 )
;

\ an optimisation for tokens..
: ((fmt-.x)) h# 200 or ['] (fmt-.x) 1 false ;

\ convert the character encoding into field widths, and the encoder
\ acf
: (fmt-decode) ( flags,ptr -- flags,acf,n,flag )
   c@ case
      ascii d of ['] (fmt-.d) 1 false endof             \ decimal
      ascii x of ((fmt-.x))           endof             \ hex (unsigned)
      ascii c of ['] (fmt-c) 1 false  endof             \ char
      ascii s of ['] (fmt-s) 2 false  endof             \ string
      ascii p of ((fmt-.x))           endof             \ hex pointer
      >r 2 ['] (fmt-cpy) true r>
   endcase
;

\ return true if this string does not have a valid encoding
\ else return false, the field with and the encoding acf

: (scan-for-fmt) ( str$ -- str$,w,acf,n,0 | str$,true )
   recursive
   over c@ ascii % = if                 ( str$ )
      \ %% forces a % which is a special case
      1 /string true                    ( str$,true )
      exit                              ( str$,true )
   then                                 ( str$ )

   \ Simple fieldless sequence?
   (sfmt-valid?) if                     ( str$,n )
      2 pick >r                         ( str$,n )
      >r r@ /string                     ( str$' )
      0 r@ 1- bwjoin                    ( str$,w )
      r> 1- r> + (fmt-decode)           ( str$,w,acf,n,flag )
      exit                              ( str,len )
   then                                 ( str,len )

   \ field is left justified?
   over c@ ascii - = if                 ( str,len 1 )
      -1 1                              ( str,len -1 1 )
   else                                 ( str,len )
      0 0                               ( str,len 1 0 )
   then                                 ( str,len 1 0 )

   \ skip the numbers
   3 pick + 0                           ( str,len sign num,len )
   begin                                ( str,len sign num,len )
      2dup + c@ d# 10 digit nip while   ( str,len sign num,n )
        1+                              ( str,len sign )
   repeat                               ( str,len sign num,len )

   \ verify the token following the numbers (if any)
   ?dup if                              ( str,len sign num,len )
      rot /string                       ( str,len num,len )
      tuck                              ( str,len len num,len )
      $number if                        ( str,len len )
         drop true exit                 ( str,len,true )
      then                              ( str,len len w )
      >r                                ( str,len len )
      dup                               ( str,len len len )
      3 pick + r> over >r >r            ( str,len len fmt )
      2 pick 2 pick -                   ( str,len len fmt,len )
      (sfmt-valid?) if                  ( str,len len fmt,len s )
         >r 2drop                       ( str,len len )
         r@ + /string                   ( str$ )
         r> 1-                          ( str$ s' )
         r> over bwjoin                 ( str$ s' code )
         swap r> +                      ( str$ code fmt' )
         (fmt-decode)                   ( str$ code,acf,n,flag )
         exit
      else                              ( str,len len fmt,len )
         2r> 3drop                      ( str,len len fmt )
      then                              ( str,len len fmt )
   then                                 ( str,len len fmt )
   2drop                                ( str,len )
   true                                 ( str$,true )
;

\ the meat of the parsing
: (fmt-parse) ( str,len -- )
   dup 0= if  2drop exit  then
   recursive
   ascii % left-parse-string ?dup if            ( right$ left$ )
      2 0 ['] (fmt-cpy) (fmt-push) drop         ( right$ )
   else                                         ( right$ leftva )
      drop                                      ( right$ )
   then                                         ( right$ )
   ?dup if                                      ( right$ )
      (scan-for-fmt) if                         ( right$ )
         \ we have a % to print, fake it with a %c conversion
         ascii % 1 0 ['] (fmt-c) (fmt-push) drop ( right$ )
         (fmt-parse)                            ( )
      else                                      ( right$ )
         >r 0 -rot (fmt-push)                   ( right$ ptr )
         >r (fmt-parse)                         ( right$ )
         r> r> swap (fmt-save)                  ( )
      then
   else                                         ( va )
      drop                                      ( )
   then                                         ( )
;

previous definitions also cmn-messaging

headers
: cmn-append ( ?? str,len -- )  
   \ Check if there is a current frame to append to
   current-frame$ @ 0=  if
      ??cr 
      ." Missing cmn-xxx[ caused cmn-append with '" type 
      ." ' argument to fail"r"n" 
      abort
   then
   [ifdef] cmn-reentrant?
      fmt-head dup @ >r off  fmt-tail dup @ >r off
   [else]
      fmt-head off fmt-tail off
   [then]
   push-decimal
   (fmt-parse)
   (fmt-exec)
   pop-base
   [ifdef] cmn-reentrant?  r> fmt-tail !  r> fmt-head !  [then]
;
 
previous also cmn-messaging definitions

headerless
: cmn-[ ( msg-category -- )

    \ Allocate buffer for a new message text string
    max-message-len /cmn-message + alloc-mem ( category message-addr) 

    \ Clear the buffer headers with zeroes
    dup /cmn-message erase    ( category message-addr)
  
    \ Compile buffer length at the beginning into cmn>messsage>maxlen field
    max-message-len over >cmn-message>maxlen w! ( category message-addr)
 
    \ Allocate pointer data structure for a new message frame 
    /cmn-frame alloc-mem >r      ( category message-addr )  ( r: frame-addr)

    \ Clear the pointer data structure with zeroes
    r@ /cmn-frame erase          ( category message-addr )  

    \ Set >cmn-message field;
    \ Store the pointer to the message text string buffer into >cmn-message field
    \ of the message frame pointer data structure
    r@ >cmn-message !             ( category )              

    \ Compile the current message category into >cmn-category field 
    \ of the message frame pointer data structure
    r@ >cmn-category c!           ( )              

    \ Set >cmn-phandle field 
    \ Store phandle into current >cmn-phandle field
    \ of the message frame pointer data structure
    ?phandle r@ >cmn-phandle !    ( )            

    \ Set >cmn-parent field
    \ Store the pointer to the parent frame into >cmn-parent field
    \ of the message frame pointer data structure
    current-frame$ @ r@ >cmn-parent !             

    \ Set >cmn-peer field
    0 r@ >cmn-peer !
    current-frame$ @  if  r@ add-new-child  then

    \ Store the pointer to the current message frame pointer
    \ data structure into current-frame$
    r> current-frame$ !        ( )       ( r: ) 
    
    \ The 'lose' is patched to cmn-end, later in this file 
    \ we dont want or need to use a defer!!
    push-checkpt  ?dup if 
       " ...(text may have been truncated due to an exception)"r"n" lose 
       throw 
    then  

;

\ Prints the content of the message between cmn-xxx[ and ]cmn-end
: .message-content ( frame-addr -- ) 
   >cmn-message @ >cmn-message>lstr long-count type 
;

\ Prints device path followed by colon  
: .devpath ( frame-addr -- ) 
   >cmn-phandle @ ?dup  if  ( phandle)
      phandle>devname type 
      ascii : emit space
   then
;

\ Selects individual format based on message category
: (print-message) ( frame-addr -- )
   >r

   r@ >cmn-category c@  case
  
   cmn-fatal of  
      ??cr
      ." FATAL: "   
      r@ .devpath 
      r@ .message-content 
   endof
 
   cmn-error of  
      ??cr
      ." ERROR: "   
      r@ .devpath 
      r@ .message-content 
   endof
  
   cmn-warning of  
      ??cr
      ." WARNING: " 
      r@ .devpath 
      r@ .message-content 
   endof
  
   cmn-note of  
      ??cr
      ." NOTICE: "              
      r@ .message-content 
   endof

   cmn-type of     
      r@ .message-content
   endof
  
   cmn-msg of
      r@ .devpath 
      r@ .message-content
   endof
         
   endcase
 
   r> drop
; 

\ Release messaging frame and message buffer after message was printed

: release-frame ( frame-addr -- )

   \ Release message buffer first 
   dup >cmn-message @                        ( frame-addr message-addr)
   dup >cmn-message>maxlen w@ /cmn-message + ( frame-addr message-addr message-maxlen )
   free-mem                                 ( frame-addr)

   \ Then release message frame
   /cmn-frame free-mem      ( )
; 

\ Print message based on type and verbosity level

: print-message ( frame -- )
   fw-verbosity diagnostic-mode? or over >cmn-category c@ and if (print-message) else drop then
;

\ Common messaging frame printing code

: print-messaging-tree ( frame-addr -- ) recursive
   begin  ?dup  while                ( frame-addr ) 
      dup print-message              ( frame-addr )
      dup >cmn-child @               ( frame-addr child-addr)
      print-messaging-tree           ( frame-addr)
      dup >cmn-peer @                ( frame-addr peer-addr)
      swap release-frame             ( peer-addr)
   repeat                            ( )
; 

\ ]cmn-end should always fetch address from current >cmn-parent
\ field and store it into current-frame$

: cmn-end ( str,len -- ) 
   cmn-append                  ( ) 
   true current-frame$ @ >cmn-completion c! \ Message completed
   current-frame$ dup @        ( current-frame$ current-frame-addr )
   >cmn-parent @               ( current-frame$ parent-frame-addr )
   ?dup  if                    ( current-frame$ parent-frame-addr )
      swap ! exit              ( )
   then                        ( current-frame$ )
   dup @                       ( current-frame$ root-frame-addr )
   platform-cmn-end-hook       ( current-frame$ )
   print-messaging-tree        ( current-frame$ )
   0 swap !                    ( ) 
   platform-cmn-end-hook2      ( )
;
\ Fixup the forward reference in cmn-[
patch cmn-end lose cmn-[

previous definitions also cmn-messaging
headers

: ]cmn-end ( str,len -- ) cmn-append " "r"n" cmn-end pop-checkpt ; 

: cmn-fatal[ ( -- ) platform-fatal-hook true is system-fatal-state? cmn-fatal   cmn-[ ;
: cmn-error[ ( -- ) platform-error-hook true is system-error-state? cmn-error   cmn-[ ;
: cmn-warn[  ( -- ) platform-warning-hook                           cmn-warning cmn-[ ;
: cmn-note[  ( -- ) platform-note-hook                              cmn-note    cmn-[ ;
: cmn-msg[   ( -- )                                                 cmn-msg     cmn-[ ;
: cmn-type[  ( -- )                                                 cmn-type    cmn-[ ;

\ Need name here because it is now calling cmn-append
 
previous definitions 

also magic-properties definitions

\ Name now automatically cmn-appends the name of the node
\ to the current cmn-messaging frame which must be started 
\ with cmn-msg[. Used for OBP probing output. Executes type
\ if there is no active messaging frame.

: name ( value-str name-str  -- value-str name-str )
   [ also cmn-messaging ]
   diagnostic-mode?  if
      2over decode-string  current-frame$ @  if
         " %s " cmn-append
      else
         type space
      then
      2drop
   then
   [ previous ]
;

previous definitions

headerless
