\ external.fth 2.6 94/09/06
\ Copyright 1985-1990 Bradley Forthware

\ external: defining word for "constants" whose value is the value
\ of an external symbol to be resolved by the linker.  Usage example:
\
\     p" _root_node"  external: root-node
\
\ Later:
\
\     root-node .
\

: do-external  ( apf -- ext-adr )  does> aligned l@  ;
transient
: $external:  \ name  ( external-name-adr,len -- )
   create align dictionary-size 0 l,   ( external-name-adr,len offset )
   -rot  $add-reference
   do-external
;
resident
