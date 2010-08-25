\ showspac.fth 2.2 90/09/03
\ Copyright 1985-1990 Bradley Forthware

\ show-space  ( -- )	displays the amount of remaining space in the
\			resident and transient dictionaries

: show-space  ( -- )
   base @ >r decimal
   ." Bytes available (decimal): Resident: " limit here - .
   ."  Transient " hedge there - .  cr
   r> base !
;
