\ ccall.fth 2.6 94/09/06
\ Copyright 1985-1990 Bradley Forthware

\ Usage:
\ Subroutine calls:
\
\    " external-procedure-name" $ccall
\ or
\    " external-procedure-name" $ccall: name  { args -- results }

\ NOTE: sc1 through sc6  (%l1 through %l6) are destroyed
\
\ Data references:
\
\    " external-name" <register-name> $set-external

\ Assembler macro to assemble code to call a named C subroutine.
\ This is an implementation word used by "ccall:".
\ The code to transfer the arguments from the stack must be generated
\ before executing this macro.  Afterwards, the code to transfer the
\ results back onto the stack must be generated.  "ccall" generates:
\
\     sethi  %hi(c_entry_point), %l0
\     call   do-ccall
\     or     %l0, %lo(c_entry_point), %l0
\
\ do-ccall is a shared procedure that saves and restores the Forth
\ virtual machine state before calling the C procedure.

: $ccall   ( procedure-name-adr,len -- )
   [ also assembler ]
   ?$add-symbol                                   ( sym# )

   \ To optimize the generated code, we move the "or" half of the
   \ "set" instruction into the delay slot of the call, generating
   \ relocation table entries accordingly.

   dictionary-size   over  0 sparc-hi22 make-relocation  ( sym# )
   0  %l0  sethi                                         ( sym# )

   do-ccall call			                 ( sym# )

   dictionary-size   swap  0 sparc-lo10 make-relocation  ( )
   %l0 0  %l0  or
   [ previous ]
;
: $ccall:  \ name  ( procedure-name$ -- procedure-name$ 'subroutine-call )
   ['] $ccall code   current token@ context token!
;
also assembler definitions
: $set-external  ( name$ register -- )
   dictionary-size  2swap  $set-reference   ( register )
   0 over sethi                             ( register )
   0 over or
;
previous definitions
