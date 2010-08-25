id: @(#)stringar.fth 2.7 03/03/21 14:31:39
purpose: 
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.
\ Copyright 1985-1990 Bradley Forthware

\ String-array
\ Creates an array of strings.
\ Used in the form:
\ string-array name
\   ," This is the first string in the table"
\   ," this is the second one"
\   ," and this is the third"
\ end-string-array
\
\ name is later executed as:
\
\ name ( index -- addr )
\   index is a number between 0 and one less than the number of strings in
\   the array.  addr is the address of the corresponding packed string.
\   if index is less than 0 or greater than or equal to the number of
\   strings in the array, name aborts with the message:
\        String array index out of range

headers

\  This implementation runs fast, but at some cost in code space;
\  we reduced that cost by using w-words for the offset entries,
\  instead of cell-sized words as in the original implementation.
\  (The cost was not too bad when cell-size was /l, but with the
\   growth of cell-size to /x, it got downright wasteful!)
\
\  After the strings, a table is constructed, indexed to the strings.
\  Each entry in the table is the offset, in bytes, from the start
\  of the Parameter Field to the indexed string.
\
\  The first w-word of the PF contains the number of strings.
\
\  The second w-word of the PF contains the offset from the start
\  of the PF to the table.  The indexed string is found by indexing
\  into the table for the offset, then adding the offset to the PFA.

: string-array  \ name ( -- )
   create
   0 w,    \  The number of strings
   0 w,    \  The starting offset of the pointer table
   does>					( index pfa )
   2dup w@					( index pfa index #strings )
   0 swap within  0= abort" String array index out of range"   ( index pfa )
   tuck  dup wa1+ w@ +				( pfa index table-address )
   swap wa+ w@ +				( string-address )
;

\  After the strings are all created (using  ,"  as shown above), run
\  this to construct the pointer table and fill in the number of strings.
: end-string-array ( -- )
   0 here 		( #strings string-end-addr )
   lastacf >body	( #strings string-end-addr pfa )

   \  Remember PFA for use as the base address
   tuck                 ( #strings pfa string-end-addr pfa )

   \ Offset to table-addr goes into 2nd w-word of PF
   2dup -		( #strings pfa string-end-addr pfa table-offset )
   swap wa1+		( #strings pfa string-end-addr table-offset 2nd-w-word )
   tuck w!		( #strings pfa string-end-addr 2nd-w-word )

   \  Construct the table of offset-pointers
   wa1+			( #strings pfa string-end-addr first-string-addr )
   begin		( #strings pfa string-end-addr this-string-addr )
      3dup >		( .... pfa more? )
   while
      \ Store string offset in table
			( #strings pfa string-end-addr this-string-addr pfa )
      2dup - nip w,	( #strings pfa string-end-addr this-string-addr )
      \ Increment #strings
      2swap swap 1+ swap 2swap		( #strings' ... )
      \ Find next string address
      +str		( #strings' pfa string-end-addr next-string-addr )
   repeat		( #strings pfa string-end-addr last-string-addr pfa )
   \ We counted the number of strings; now store
   3drop w!		( #strings pfa )
;

\  It's highly unlikely -- but no longer impossible -- for a string-array 
\  to overflow the capacity of a w-word (it'd have to exceed 64K!), so we
\  really ought to check.  We'd rather not incur any cost of space in the
\  final ROM image, so we'll make the test transient.

\  Mini-forth loads this file as transient.
\  We probably should, some day, revisit the prohibition against
\  " Nested transient's" (as well as that dubious apostrophe),
\  but in the meantime, we'll do an unpretty point-solution...

transient? 0= dup if    transient   then
\  Leave copy of "not-already-transient" flag on compile-time stack

overload: end-string-array ( -- )
   here lastacf >body -
   h# 1.0000 < if
      end-string-array
   else
      where ." Can't accommodate such a large string-array!" cr
      (compile-time-error)
   then
;

\  Copy of "not-already-transient" flag is on compile-time stack
if    resident     then


headerless

\  Size-of-a-string-array.
\  Return the number of strings in the string-array whose CFA is given.
\  If we ever change the data-structure again, we need only change this
\  routine, and the callers will all remain in sync.
\
: /string-array ( acf -- index )
   >body w@
;

\  Example of usage of the above:

\  \  Print out an entire string-array, under control of the  exit?  utility.
\  : .string-array ( acf -- )
\     dup /string-array 0 do i over execute ". cr exit? ?leave loop drop
\  ;

headers

