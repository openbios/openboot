\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: help.fth
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
id: @(#)help.fth 1.10 06/02/08
purpose: implements OBP command line interface help
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
also hidden definitions
vocabulary help-category  erase-voc-link
also help-category definitions
headers
: nvramrc     ." nvramrc (making new commands permanent)"  ;
: file        ." File download and boot " ;
: resume      ." Resume execution"  ;
: diag        ." Diag (diagnostic routines)"  ;
: power       ." Power on reset"  ;
: eject       ." eject devices"  ;
: select      ." Select I/O devices"  ;
: system      ." System and boot configuration parameters"  ;
: line        ." Line editor" ;
: memory      ." Memory access" ;
: arithmetic  ." Arithmetic"  ;
: radix       ." Radix (number base conversions)"  ;
: numeric     ." Numeric output"  ;
: defining    ." Defining new commands"  ;
: repeated    ." Repeated loops"  ;
: breakpoints ." Breakpoints (debugging)" ;

previous definitions

headerless
vocabulary help-voc  erase-voc-link
also help-voc definitions
headers

: nvramrc ( -- )
   ??cr ." nvedit         Start nvramrc line editor using a temporary edit buffer"
   ??cr ." use-nvramrc?   If this variable is true , Contents of nvramrc "
   ??cr ."       is executed automatically. Set using  setenv  command"
   ??cr ." nvrun          Execute the contents of nvedit edit buffer"
   ??cr ." nvstore        Save the contents of the nvedit buffer into NVRAM"
   ??cr ." nvrecover      Recover nvramrc after a set-defaults"
   ??cr ." nvalias <name> <path>   Edit nvramrc to include devalias called 'name'"
   ??cr ." nvunalias <name>   Edit nvramrc to remove  devalias called 'name'"
;

alias nvedit        nvramrc
alias use-nvramrc?  nvramrc
alias nvrun         nvramrc
alias nvstore       nvramrc
alias nvrecover     nvramrc
alias nvalias       nvramrc
alias nvunalias     nvramrc

: file
   ??cr  ." boot <specifier>  ( -- )    boot kernel ( default ) or other file"
   ??cr  ."   Examples:"
   ??cr  ."     boot                    - boot kernel from default device."
   ??cr  ."                                Factory default is to boot"
   ??cr  ."                                from DISK if present, otherwise from NET."
   ??cr  ."     boot net                - boot kernel from network"
   ??cr  ."     boot cdrom              - boot kernel from CD-ROM"
   ??cr  ."     boot disk1:h            - boot from disk1 partition h"
   ??cr  ."     boot tape               - boot default file from tape"
   ??cr  ."     boot disk myunix -as    - boot myunix from disk with flags ""-as"" "
   ??cr ." dload <filename>  ( addr -- )     debug load of file over network at address"
   ??cr ."   Examples:"
   ??cr ."      4000 dload /export/root/foo/test"
   ??cr ."      ?go        - if executable program, execute it"
   ??cr ."                   or if Forth program, compile it"
;

alias boot  file
alias dload file

: resume
   ??cr ." go      Start or continue execution of program"
;

: diag
   ??cr ." test  <device-specifier>   Run selftest method for specified device"
   ??cr ."   Examples:"
   ??cr ."     test floppy       - test floppy disk drive"
   ??cr ."     test net          - test net"
   ??cr ."     test scsi         - test scsi"
   ??cr ." test-all        Execute test for all devices with selftest method"
[ifexist] post				\ FWARC 2003/703 'post' command
   ??cr ." post            Invoke platform POST (will cause a reset)
   ??cr ."   Syntax:   post [ <diag-level> [ <verbosity> ] ]"
[then]
   ??cr ." watch-clock     Show ticks of real-time clock"
   ??cr ." watch-net       Monitor network broadcast packets "
   ??cr ." watch-net-all   Monitor broadcast packets on all net interfaces"
[ifndef] no-onboard-scsi
   ??cr ." probe-scsi      Show attached SCSI devices"
[then]
   ??cr ." probe-scsi-all  Show attached SCSI devices for all host adapters"
;

alias test            diag
alias test-all        diag
alias watch-clock     diag
alias watch-net       diag
alias watch-net-all   diag
[ifndef] no-onboard-scsi
alias probe-scsi      diag
[then]
alias probe-scsi-all  diag
[ifexist] post
alias post            diag
[then]

: power
   ??cr ." reset-all   reset machine, ( simulates power cycling )"
   ??cr ." power-off   Power Off"
;

alias reset-all power
alias power-off power

: eject
   ??cr ." eject <device>  Eject <device> from drive"
   ??cr ."    floppy       eject the floppy"
   ??cr ."    cdrom        eject the cdrom"
;

: select
   ??cr ." input   Select input source ( ttya or ttyb or keyboard )"
   ??cr ."    Examples:"
   ??cr ."      ttya input      - use ttya for subsequent input"
   ??cr ."      keyboard input  - use Sun keyboard for subsequent input"
   ??cr ." output  Select output source ( ttya or ttyb or screen )"
   ??cr ."    Examples:"
   ??cr ."      screen output   - use Sun screen for subsequent output"
   ??cr ." io      Select input and output ( ttya or ttyb)"
   ??cr ."    Examples:"
   ??cr ."      ttya io         - use ttya for subsequent input and output"
;

alias input   select
alias output  select
alias io      select

: system
   ??cr ." devalias                 - Display all device aliases"
   ??cr ." devalias <name> <value>  - Create or change a device alias"
   ??cr ." printenv      Show all configuration parameters"
   ??cr ."                 numbers are shown in decimal"
   ??cr ." setenv <name> <value>   Change a configuration parameter"
   ??cr ."          changes are permanent but only take effect after a reset"
   ??cr ."    Examples:"
   ??cr ."      setenv input-device ttya         - use ttya input next time"
   ??cr ."      setenv screen-#rows 0x1e         - use 30 rows of display ( hex 1e )"
   ??cr ."      setenv boot-device net           - specify network as boot device"
   ??cr ."      setenv auto-boot? false          - disable automatic boot"
[ifexist] auto-boot-on-error?
   ??cr ."      setenv auto-boot-on-error? false - disable automatic boot only on"
   ??cr ."                                         system/hardware error"
[then]					\ End auto-boot-on-error?
   ??cr ." set-defaults    Revert to factory configuration"
   ??cr ." See also: nvramrc"
;

: register
   ??cr ." %pc %npc %tba ..."
   ??cr ." %i0 ... %i7"
   ??cr ." %l0 ... %l7"
   ??cr ." %o0 ... %o7"
   ??cr ." %g0 ... %g7 ( -- n )  Place the saved register value on the stack"
   ??cr ." to regname  ( n -- )  Change saved register value"
   ??cr ."   Example:"
   ??cr ."     1234 to %i3"
   ??cr ." set-pc  ( pc -- )     Set %pc to value and %npc to value+4"
   ??cr ."   Example:"
   ??cr ."     5000 set-pc"
   ??cr ." w ( n -- )        Select a set of window registers"
   ??cr ."   Example:"
   ??cr ."     5 w"
   ??cr ." ctrace            C subroutine call trace"
   ??cr ." .locals           Show the saved %ix %lx and %ox registers"
   ??cr ." .registers        Show the saved registers %gx and %pc thru %tba"
   ??cr ." .window ( n -- )  Same as  ""w .locals"" "
   ??cr ." .pstate           Show fields of %pstate"
;

alias  ctrace register
alias  .locals register
alias  .registers register
alias  .window    register

: sync
   ??cr ." sync     Reenter Operating System to sync the disks"
;

: breakpoints
   ??cr ." go                Begin or continue execution"
   ??cr ." .bp               Show all current breakpoints"
   ??cr ." +bp  ( adr -- )   Add a breakpoint at the given address"
   ??cr ." -bp  ( adr -- )   Remove the breakpoint at the given address"
   ??cr ." --bp              Remove the most recently set breakpoint"
   ??cr ." bpoff             Remove all breakpoints"
   ??cr ." step              Single-step one instruction"
   ??cr ." steps ( n -- )    Do n step's"
   ??cr ." hop               Like step; doesn't descend into subroutines"
   ??cr ." hops  ( n -- )    Do n hop's"
   ??cr ." skip              Skip over the current instruction"
   ??cr ." till  ( adr -- )  Execute until the given address ( like '+bp go' )"
   ??cr ." return            Execute until the end of this subroutine"
   ??cr ." returnl           Execute until the end of this leaf subroutine"
   ??cr ." finish-loop       Execute until the end of this loop"
   ??cr ." .instruction      Show address and opcode for last encountered breakpoint"
   ??cr ." .breakpoint       Executed after every encountered breakpoint"
   ??cr ."                   Default behavior is .instruction"
   ??cr ."    Examples:"
   ??cr ."      ' .registers  is  .breakpoint"
   ??cr ."      ' .instruction is .breakpoint"
;

: line
   ??cr ." ^P     Recall previous line"
   ??cr ." ^N     Recall subsequent line"
   ??cr ." ^A     Beginning of line"
   ??cr ." ^E     End of line"
   ??cr ." ^B     Backward one character"
   ??cr ." ESC-B  Backward one word"
   ??cr ." ^F     Forward one character"
   ??cr ." ESC-F  Forward one word"
   ??cr ." ^D     Erase this character"
   ??cr ." ESC-D  Erase here to end of this word"
   ??cr ." ^K     Erase here to end of line"
   ??cr ." ^H     Erase previous character ( also backspace, delete )"
   ??cr ." ESC-H , ^W  Erase previous word"
   ??cr ." ^U     Erase entire line"
   ??cr ." ^R     Retype line"
   ??cr ." ^L     Display command history"
   ??cr ." ^` , ^SPACE  Commmand completion"
   ??cr ." ^} , ^? Show possible completions"
   ??cr ." ^Q     Enter next character as-is"
;

: memory
   ??cr ." dump  ( addr length -- )       Display memory at addr for length bytes"
   ??cr ." fill  ( addr length byte -- )  Fill memory starting at addr with byte"
   ??cr ." move  ( src dest length -- )   Copy length bytes from src to dest address"
   ??cr ." map?  ( vaddr -- )   Show memory map information for the virtual address"
   ??cr ." x?    ( addr -- )    Display the 64-bit number from location addr"
   ??cr ." l?    ( addr -- )    Display the 32-bit number from location addr"
   ??cr ." w?    ( addr -- )    Display the 16-bit number from location addr"
   ??cr ." c?    ( addr -- )    Display the 8-bit number from location addr"
   ??cr ." x@    ( addr -- n )  Place on the stack the 64-bit data at location addr"
   ??cr ." l@    ( addr -- n )  Place on the stack the 32-bit data at location addr"
   ??cr ." w@    ( addr -- n )  Place on the stack the 16-bit data at location addr"
   ??cr ." c@    ( addr -- n )  Place on the stack the 8-bit data at location addr"
   ??cr ." x!    ( n addr -- )  Store the 64-bit value n at location addr"
   ??cr ." l!    ( n addr -- )  Store the 32-bit value n at location addr"
   ??cr ." w!    ( n addr -- )  Store the 16-bit value n at location addr"
   ??cr ." c!    ( n addr -- )  Store the 8-bit value n at location addr"
;

: arithmetic
   ??cr ." +       ( n1 n2 -- n3 )     Add n1+n2 and place on the stack"
   ??cr ." -       ( n1 n2 -- n3 )     Subtract n1-n2 and place on the stack"
   ??cr ." *       ( n1 n2 -- n3 )     Multiply n1*n2 and place on the stack"
   ??cr ." /       ( n1 n2 -- n3 )     Divide n1/n2 truncated and place on the stack"
   ??cr ." mod     ( n1 n2 -- n3 )     Place on the stack remainder of n1/n2"
   ??cr ." lshift  ( n1 count -- n2 )  Left shift n1 by count places"
   ??cr ." rshift  ( n1 count -- n2 )  Right shift n1 by count places"
;

: radix
   ??cr ." decimal   Subsequent numeric I/O is performed in base 10"
   ??cr ." hex       Subsequent numeric I/O is performed in base 16"
   ??cr ." d# <number>   Interpret number in base 10 and place on the stack"
   ??cr ."    Example:"
   ??cr ."      ( in base 16 ) d# 12 .        - prints out 'c'"
   ??cr ." h# <number>   Interpret number in base 16 and place on the stack"
   ??cr ."    Example:"
   ??cr ."      ( in base 10 ) h# 12 .    - prints out '18'"
;

: numeric
   ??cr ." .   ( n -- )      Show the number in the current base"
   ??cr ." .d  ( n -- )      Show the number in base 10"
   ??cr ." .h  ( n -- )      Show the number in base 16"
   ??cr ." .s  ( ?? -- ?? )  Show the stack without altering it"
   ??cr ." showstack         Show stack contents before each 'ok' prompt"
;

: repeated
   ??cr ." begin   ( -- )       Start a loop"
   ??cr ." until   ( flag -- )  Repeat 'begin' loop until flag is true"
   ??cr ."    Examples:"
   ??cr ."       begin  4000 c@  55 = until"
   ??cr ."       begin  0 2005 c!  key? until"
   ??cr ." do      ( end+1 start -- )  Start a counted loop"
   ??cr ." loop    ( -- )              End a 'do' loop"
   ??cr ." +loop   ( n -- )            End a 'do' loop"
   ??cr ." i       (-- n )             Place on the stack the current 'do' loop index"
   ??cr ."   Examples:"
   ??cr ."      7 0  do  i .  loop      - prints 0 1 2 3 4 5 6"
   ??cr ."      7 0  do  i .  3 +loop   - prints 0 3 6"
;

: defining
   ??cr ." : <name>    Begin creation of a new command called 'name'"
   ??cr ."     Examples:"
   ??cr ."       : mycalc  ( n1 -- n2 )  10000 *  11 +  ;"
   ??cr ."       : target  ( -- addr )  26 mycalc  ;"
   ??cr ." ;           End creation of a new ':' command"
   ??cr ." ' <name>  ( -- acf )  Place on the stack the compilation address of 'name'"
   ??cr ." words                 Show the names of all commands"
   ??cr ." see name              Decompile or disassemble the command 'name'"
;

previous  previous definitions

headerless
: do-help ( -- )
   ??cr ." Enter 'help command-name' or 'help category-name' for more help"
   ??cr ." (Use ONLY the first word of a category description) "
   ??cr ." Examples:  help select   -or-   help line"
   ??cr ."     Main categories are: "
   0 [ hidden ] ['] help-category [ previous ]
   begin  another-word?  while  ( alf' voc nfa )
      ??cr  name>  execute
   repeat
;

: $do-help ( adr,len -- found? )
   2>r 0  [ also hidden ] ['] help-voc  [ previous ]  ( alf voc-acf ) ( r: adr,len )
   begin  another-word?  while       ( alf' voc-acf nfa ) ( r: adr,len )
      dup 2r@ rot name>string sindex ( alf' voc nfa index|-1 ) ( r: adr,len )
      0>=  if                        ( alf' voc nfa )  ( r: adr,len )
	 nip nip 2r> 2drop           ( anf )
	 dup name> swap n>flags c@ h# 20 and  if  token@  then
	 execute  true  exit
      then                           ( alf' voc nfa )  ( r: adr,len )
      drop                           ( alf' voc )  ( r: adr,len )
   repeat  2r> 2drop  false          (  )
;

: (help-msg  ( -- )  ??cr ." Type  help  for more information" cr  ;
' (help-msg is help-msg

headers
: help ( -- )
   optional-arg$                     ( adr,len )
   2dup lower
   bl left-parse-string 2swap 2drop  ( adr,len' )
   ?dup  if
      2dup  $do-help  if  2drop  exit  then
      ." No help available for " type  exit
   then  drop
   do-help
;

headers

