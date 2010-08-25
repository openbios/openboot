\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usb-us.fth
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
\ id: @(#)usb-us.fth 1.5 99/07/23
\ purpose: 
\ copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved
\

\ Note that per the usb "Device Class Definition for Human Interface Devices"
\ document, key (decimal) 76 should be a delete forward key, but we are
\ implementing it the same as backspace (decimal 42), such that it deletes
\ the character in front of the cursor.

decimal

33 full-keyboard: usa

\  0     1        2        3         4         5        6        7
hole     hole     hole     hole      ascii a   ascii b  ascii c  ascii d  8keys

\  8     9        10       11        12        13       14       15
ascii e  ascii f  ascii g  ascii h   ascii i   ascii j  ascii k  ascii l  8keys

\ 16     17       18       19        20        21       22       23
ascii m  ascii n  ascii o  ascii p   ascii q   ascii r  ascii s  ascii t  8keys

\ 24     25       26       27        28        29       30       31
ascii u  ascii v  ascii w  ascii x   ascii y   ascii z  ascii 1  ascii 2  8keys

\ 32     33       34       35        36        37       38       39
ascii 3  ascii 4  ascii 5  ascii 6   ascii 7   ascii 8  ascii 9  ascii 0  8keys

\ 40     41       42       43        44        45       46       47
carret   esc      del      tab       bl        ascii -  ascii =  ascii [  8keys

\ 48     49       50       51        52        53       54       55
ascii ]  ascii \  oops     ascii ;   ascii '   ascii `  ascii ,  ascii .  8keys

\ 56     57       58       59        60        61       62       63
ascii /  capslock oops     oops      oops      oops     oops     oops     8keys

\ 64     65       66       67        68        69       70       71
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 72     73       74       75        76        77       78       79
oops     oops     oops     oops      del       oops     oops     oops     8keys

\ 80     81       82       83        84        85       86       87
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 88     89       90       91        92        93       94       95
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 96     97       98       99        100       101      102      103
oops     oops     oops     oops      hole      oops     oops     hole     8keys

\ 104    105      106      107       108       109      110      111
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 112    113      114      115       116       117      118      119
hole     hole     hole     hole      hole      oops     oops     oops     8keys

\ 120    121      122      123       124       125      126      127
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 128    129      130      131       132       133      134      135
oops     oops     oops     oops      oops      hole     hole     hole     8keys

\ 136    137      138      139       140       141      142      143
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 144    145      146      147       148       149      150      151
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 152                                                            159
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 160                                                            167
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 168                                                            175
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 176                                                            183
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 184                                                            191
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 192                                                            199
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 200                                                            207
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 208                                                            215
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 216                                                            223
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 224    225      226      227       228       229      230      231
ctrl     shift    oops     oops      oops      shift    altg     oops     8keys

\ 232                                                            239
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 240                                                            247
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 248                                                            255
hole     hole     hole     hole      hole      hole     hole     hole     8keys



\ shifted keyboard table

\  0     1        2        3         4         5        6        7
hole     hole     hole     hole      ascii A   ascii B  ascii C  ascii D  8keys

\  8     9        10       11        12        13       14       15
ascii E  ascii F  ascii G  ascii H   ascii I   ascii J  ascii K  ascii L  8keys

\ 16     17       18       19        20        21       22       23
ascii M  ascii N  ascii O  ascii P   ascii Q   ascii R  ascii S  ascii T  8keys

\ 24     25       26       27        28        29       30       31
ascii U  ascii V  ascii W  ascii X   ascii Y   ascii Z  ascii !  ascii @  8keys

\ 32     33       34       35        36        37       38       39
ascii #  ascii $  ascii %  ascii ^   ascii &   ascii *  ascii (  ascii )  8keys

\ 40     41       42       43        44        45       46       47
carret   esc      del      tab       bl        ascii _  ascii +  ascii {  8keys

\ 48     49       50       51        52        53       54       55
ascii }  ascii |  oops     ascii :   ascii "   ascii ~  ascii <  ascii >  8keys

\ 56     57       58       59        60        61       62       63
ascii ?  capslock oops     oops      oops      oops     oops     oops     8keys

\ 64     65       66       67        68        69       70       71
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 72     73       74       75        76        77       78       79
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 80     81       82       83        84        85       86       87
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 88     89       90       91        92        93       94       95
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 96     97       98       99        100       101      102      103
oops     oops     oops     oops      hole      oops     power    hole     8keys

\ 104    105      106      107       108       109      110      111
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 112    113      114      115       116       117      118      119
hole     hole     hole     hole      hole      oops     oops     oops     8keys

\ 120    121      122      123       124       125      126      127
oops     oops     oops     oops      oops      oops     oops  mon-off/on  8keys

\ 128    129      130      131       132       133      134      135
oops     oops     oops     oops      oops      hole     hole     hole     8keys

\ 136    137      138      139       140       141      142      143
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 144    145      146      147       148       149      150      151
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 152                                                            159
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 160                                                            167
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 168                                                            175
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 176                                                            183
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 184                                                            191
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 192                                                            199
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 200                                                            207
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 208                                                            215
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 216                                                            223
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 224    225      226      227       228       229      230      231
ctrl     shift    oops     oops      oops      shift    altg     oops     8keys

\ 232                                                            239
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 240                                                            247
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 248                                                            255
hole     hole     hole     hole      hole      hole     hole     hole     8keys


\ Alt Graph keys
\ US keyboard doesn't use any Alt-Graph keys, so the only values that
\ you'll find in this section are oops, hole, and altg.

\  0     1        2        3         4         5        6        7
hole     hole     hole     hole      oops      oops     oops     oops     8keys

\  8     9        10       11        12        13       14       15
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 16     17       18       19        20        21       22       23
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 24     25       26       27        28        29       30       31
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 32     33       34       35        36        37       38       39
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 40     41       42       43        44        45       46       47
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 48     49       50       51        52        53       54       55
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 56     57       58       59        60        61       62       63
oops     capslock oops     oops      oops      oops     oops     oops     8keys

\ 64     65       66       67        68        69       70       71
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 72     73       74       75        76        77       78       79
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 80     81       82       83        84        85       86       87
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 88     89       90       91        92        93       94       95
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 96     97       98       99        100       101      102      103
oops     oops     oops     oops      hole      oops     oops     hole     8keys

\ 104    105      106      107       108       109      110      111
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 112    113      114      115       116       117      118      119
hole     hole     hole     hole      hole      oops     oops     oops     8keys

\ 120    121      122      123       124       125      126      127
oops     oops     oops     oops      oops      oops     oops     oops     8keys

\ 128    129      130      131       132       133      134      135
oops     oops     oops     oops      oops      hole     hole     hole     8keys

\ 136    137      138      139       140       141      142      143
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 144    145      146      147       148       149      150      151
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 152                                                            159
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 160                                                            167
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 168                                                            175
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 176                                                            183
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 184                                                            191
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 192                                                            199
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 200                                                            207
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 208                                                            215
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 216                                                            223
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 224    225      226      227       228       229      230      231
ctrl     oops     oops     oops      oops      oops     altg     oops     8keys

\ 232                                                            239
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 240                                                            247
hole     hole     hole     hole      hole      hole     hole     hole     8keys

\ 248                                                            255
hole     hole     hole     hole      hole      hole     hole     hole     8keys


kend

