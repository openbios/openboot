\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: logodata.fth
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
id: @(#)logodata.fth 1.3 94/11/07
purpose: Bitmap image of Sun logo
copyright: Copyright 1990-1994 Sun Microsystems, Inc.  All Rights Reserved

\
\  Format_version=1, Width=64, Height=64, Depth=1, Valid_bits_per_item=16
\
\  Description: Sun logo, with curved ends on U's.
\  Background: White.
\

hex
headers

label sun-logo
   0000 w, 0003 w, C000 w, 0000 w, 0000 w, 000F w, F000 w, 0000 w,
   0000 w, 001F w, F800 w, 0000 w, 0000 w, 003F w, FC00 w, 0000 w,
   0000 w, 003F w, FE00 w, 0000 w, 0000 w, 007F w, FF00 w, 0000 w,
   0000 w, 007E w, FF80 w, 0000 w, 0000 w, 027F w, 7FC0 w, 0000 w,
   0000 w, 073F w, BFE0 w, 0000 w, 0000 w, 0FBF w, DFF0 w, 0000 w,
   0000 w, 1FDF w, EFF8 w, 0000 w, 0000 w, 2FEF w, F7FC w, 0000 w,
   0000 w, 77F7 w, FBFE w, 0000 w, 0000 w, FBFB w, FDFF w, 0000 w,
   0001 w, FDFD w, FEFF w, 0000 w, 0001 w, FEFE w, FF7E w, C000 w,
   0006 w, FF7F w, 7FBD w, E000 w, 000F w, 7FBF w, BFDB w, F000 w,
   001F w, BFDF w, DFE7 w, F800 w, 003F w, DFEF w, EFEF w, F400 w,
   007F w, AFF7 w, F7DF w, EE00 w, 00FF w, 77FB w, F3BF w, DF00 w,
   01FE w, FBFD w, F97F w, BF80 w, 03FD w, FDFF w, F8FF w, 7F00 w,
   07FB w, F8FF w, F9FE w, FE00 w, 0FF7 w, F07F w, F3FD w, FCE0 w,
   1FEF w, E73F w, F7FB w, FBF8 w, 3FDF w, DFDF w, EFF7 w, F7FC w,
   7FBF w, BFE7 w, 9FEF w, EFFE w, 7F7F w, 7FE0 w, 1FDF w, DFFE w,
   FEFE w, FFF0 w, 3FBF w, BFFF w, FDFD w, FFF0 w, 3F7F w, 7FFF w,
   FFFB w, FBF0 w, 3FFE w, FF7F w, FFF7 w, F7F0 w, 3FFD w, FEFF w,
   7FEF w, EFE0 w, 1FFB w, FDFE w, 7FDF w, DFE7 w, 9FF7 w, FBFE w,
   3FBF w, BFDF w, EFEF w, F7FC w, 0E7F w, 7FBF w, F39F w, EFF8 w,
   00FE w, FF3F w, F83F w, DFF0 w, 01FD w, FE7F w, FC7F w, BFE0 w,
   03FB w, FC7F w, FEFF w, 7FC0 w, 01F7 w, FA7E w, FF7E w, FF80 w,
   00EF w, F73F w, 7FBD w, FF00 w, 005F w, EFBF w, BFDB w, FE00 w,
   003F w, DFDF w, DFE7 w, FC00 w, 001F w, AFEF w, EFF7 w, F800 w,
   000F w, 77F7 w, F7FB w, F000 w, 0006 w, FBFB w, FBFD w, E000 w,
   0001 w, FDFD w, FDFE w, C000 w, 0001 w, FEFE w, FEFF w, 0000 w,
   0000 w, FF7F w, 7F7F w, 0000 w, 0000 w, 7FBF w, BFBE w, 0000 w,
   0000 w, 3FDF w, DFDC w, 0000 w, 0000 w, 1FEF w, EFE8 w, 0000 w,
   0000 w, 0FF7 w, F7F0 w, 0000 w, 0000 w, 07FB w, FBE0 w, 0000 w,
   0000 w, 03FD w, F9C0 w, 0000 w, 0000 w, 01FE w, FC80 w, 0000 w,
   0000 w, 00FF w, FC00 w, 0000 w, 0000 w, 007F w, FC00 w, 0000 w,
   0000 w, 003F w, F800 w, 0000 w, 0000 w, 001F w, F800 w, 0000 w,
   0000 w, 000F w, F000 w, 0000 w, 0000 w, 0003 w, C000 w, 0000 w,
end-code

headers
