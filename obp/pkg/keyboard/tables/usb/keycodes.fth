\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: keycodes.fth
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
id: @(#)keycodes.fth 1.14 99/07/23
purpose: Low-level definitions for Sun keyboard driver
copyright: Copyright 1990-1997 Sun Microsystems, Inc.  All Rights Reserved

\  Header file for USB keyboard routines
\
\  The USB keyboard differs greatly from the Sun keyboard in that the
\  USB kbd doesn't send idle, reset or error codes as part of the
\  keycode stream, nor does it send key "up" codes".
\

hex
\ headerless
external


\ Sofware related definitions

\ This defines the format of translation tables.
\
\ A translation table is 256 bytes of "entries", each having a position
\ in the chart which equates to the key number, and each keynumber has
\ a value assigned to it.  Some of these values are printable, some are
\ "special", e.g. shift, and some just indicate that the key is never
\ expected to be received (holes), or if it is seen then we're to do
\ nothing with it (oops).  The entries are decoded by keyboard.c.
\
\ USB key numbers are assigned as follows (per the 1.0 Draft #4 of the
\ USB HID document);
\ 0 : Reserved (no event indicated)
\ 1 : Kbd Error RollOver
\ 2 : Kbd POST Failure
\ 3 : Kbd Error Undefined
\ 4-164, 224-231
\    These values are for keys, some of which will be on our keyboards,
\    some of which will not be.  These keys include all "special" keys,
\    such as shift, control, F1, mute, power, et cetera.
\
\ 165-223, 232-255: Reserved

\ Note that a USB keymap is twice the size of a Sun keymap because the
\ USB keyboards may return a range of 1-256 for the key numbers.

headerless

      -1  constant nokey

\ LETTERS USING A or a
h#    c0  constant a-grave		\ cap A with `
h#    e0  constant grave-a		\ lower a with `
h#    c1  constant a-acute		\ cap A with '
h#    e1  constant acute-a		\ lower a with '
h#    c2  constant a-circm		\ cap A with ^
h#    e2  constant circm-a		\ lower a with ^
h#    c3  constant a-tilde		\ cap A with ~
h#    e3  constant tilde-a		\ lower a with ~
h#    c4  constant a-diaer		\ cap A with dbl dots
h#    e4  constant diaer-a		\ lower a with dbl dots
h#    c5  constant a-angst		\ cap A Angstrom
h#    e5  constant angst-a		\ lower a Angstrom
h#    c6  constant a-dipth		\ cap A combined with E
h#    e6  constant dipth-a		\ lower a combined with e

\ LETTERS USING C or c
h#    c7  constant c-dilla		\ cap C bottom curly pig-tail
h#    e7  constant dilla-c		\ lower c bottom curly pig-tail

\ LETTERS USING D or d
h#    f0  constant th-e			\ cap Eth (D with crossed vert bar)
h#    d0  constant e-th			\ lower eth (fat d with crossed top)

\ LETTERS USING E or e
h#    c8  constant e-grave		\ cap E with `
h#    e8  constant grave-e		\ lower e with `
h#    c9  constant e-acute		\ cap E with '
h#    e9  constant acute-e		\ lower e with '
h#    ca  constant e-circm		\ cap E with ^
h#    ea  constant circm-e		\ lower e with ^
h#    cb  constant e-diaer		\ cap E with dbl dots
h#    eb  constant diaer-e		\ lower e with dbl dots

\ LETTERS USING I or i
h#    cc  constant i-grave		\ cap I with `
h#    ec  constant grave-i		\ lower i with `
h#    cd  constant i-acute		\ cap I with '
h#    ed  constant acute-i		\ lower i with '
h#    ce  constant i-circm		\ cap I with ^
h#    ee  constant circm-i		\ lower i with ^
h#    ce  constant i-diaer		\ cap I with dbl dots
h#    ee  constant diaer-i		\ lower i with dbl dots

\ LETTERS USING N or n
h#    d1  constant n-tilde		\ cap N with ~
h#    f1  constant tilde-n		\ lower n with ~

\ LETTERS USING O or o
h#    d2  constant o-grave		\ cap O with `
h#    f2  constant grave-o		\ lower o with `
h#    d3  constant o-acute		\ cap O with '
h#    f3  constant acute-o		\ lower o with '
h#    d4  constant o-circm		\ cap O with ^
h#    f4  constant circm-o		\ lower o with ^
h#    d5  constant o-tilde		\ cap O with ~
h#    f5  constant tilde-o		\ lower o with ~
h#    d6  constant o-diaer		\ cap O with dbl dots
h#    f6  constant diaer-o		\ lower o with dbl dots
h#    d8  constant o-null		\ cap O with / through it
h#    f8  constant null-o		\ lower o with / through it

\ LETTERS USING P or p
h#    de  constant p-thorn		\ droopy lookin' Cap P
h#    fe  constant thorn-p		\ droopy lookin' lower p

\ LETTERS USING S or s
h#    df  constant s-doubl		\ German double S

\ LETTERS USING U or u
h#    d9  constant u-grave		\ cap U with `
h#    f9  constant grave-u		\ lower u with `
h#    da  constant u-acute		\ cap U with '
h#    fa  constant acute-u		\ lower u with '
h#    db  constant u-circm		\ cap U with ^
h#    fb  constant circm-u		\ lower u with ^
h#    dc  constant u-diaer		\ cap U with dbl dots
h#    fc  constant diaer-u		\ lower u with dbl dots

\ LETTERS USING Y or y
h#    ff  constant diaer-y		\ lower y with dbl dots
h#    dd  constant y-acute		\ cap Y with '
h#    fd  constant acute-y		\ lower y with '

\    SYMBOLS
h#    a2  constant cents		\ cents symbol
h#    a3  constant p-strlg		\ Pounds Sterling symbol
h#    a4  constant currncy		\ currency symbol
h#    a5  constant yen			\ Yen symbol
h#    a6  constant bk-vbar		\ broken vertical bar
h#    aa  constant femsup		\ raised small a with underbar
h#    ba  constant mascsup		\ raised small o with underbar
h#    a9  constant copyrgt		\ copyright symbol
h#    ae  constant regstrd		\ registered symbol
h#    af  constant macron		\ macron symbol (raised dash)
h#    a7  constant section		\ section mark symbol (cap S over S)
h#    b6  constant paramrk		\ paragraph mark symbol (tall pi)
h#    b5  constant mu			\ mu symbol
h#    b0  constant degrees		\ degrees symbol
h#    b7  constant cen-dot		\ centered dot
h#    b1  constant plusmin		\ plus or minus symbol
h#    d7  constant multsym		\ multiplication symbol
h#    f7  constant divsym		\ division symbol
h#    ac  constant notsign		\ not sign (raised horiz L - leg dn)
h#    ad  constant softhyp		\ soft hyphen
h#    b9  constant raised1		\ 1 raised up
h#    b2  constant raised2		\ 2 raised up
h#    b3  constant raised3		\ 3 raised up
h#    bc  constant one4th		\ 1/4
h#    bd  constant onehalf		\ 1/2
h#    be  constant thre4th		\ 3/4
h#    ab  constant lftgull		\ left guillemot (<<)
h#    bb  constant rtguill		\ right guillemot (>>)
h#    a1  constant invert!		\ Spanish upside-down !
h#    bf  constant invert?		\ Spanish upside-down ?
h#    a8  constant diaeres		\ diaeresis (dbl dots)
h#    b4  constant acuteac		\ acute accent (')
h#    b8  constant cedilla		\ cedilla - bottom curly tail
h#    a0  constant nonspac		\ nonbreaking space

