\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: sysprims-nofb.fth
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
id: @(#)sysprims-nofb.fth 1.1 00/03/14
purpose: 
copyright: Copyright 1999-2000 Sun Microsystems, Inc.  All Rights Reserved

hex
\ --- Memory allocation and mapping --------------------------------------
\ v1 v2   000 1  (reserved - because alocated by single byte fcodes)

v1 v2  001 1 byte-code: obsolete-fcode	\ Was dma-alloc  ( #bytes -- virtual )
v1 v2  002 1 byte-code: my-address            ( -- physical )
v1 v2  003 1 byte-code: my-space              ( -- space )
v1 v2  004 1 byte-code: obsolete-fcode	\ Was memmap   ( physical space size -- virtual )
v1 v2  005 1 byte-code: free-virtual          ( virtual len -- )
v1 v2  006 1 byte-code: obsolete-fcode	\ Was >physical ( virtual -- physical space )

\      007 1
\      008 1
\      009 1
\      00a 1
\      00b 1
\      00c 1
\      00d 1
\      00e 1

v1 v2  00f 1 byte-code: obsolete-fcode	\  Was my-params ( -- addr len )
v1 v2  010 1 byte-code: property         ( val-adr val-len name-adr name-len -- )
			\ Was attribute
v1 v2  011 1 byte-code: encode-int       ( n1 -- adr len )
			\ Was xdrint
v1 v2  012 1 byte-code: encode+          ( adr len1 adr len2-- adr len1+2 )
			\ Was xdr+
v1 v2  013 1 byte-code: encode-phys      ( paddr space -- adr len )
			\ Was xdrphys
v1 v2  014 1 byte-code: encode-string    ( adr len -- adr' len+1 )
			\ Was xdrstring
v2.1   015 1 byte-code: encode-bytes     ( adr len -- adr' len+1 )
			\ Was xdrbytes

\ --- Shorthand Property Creation --------------------------------------
v1 v2  016 1 byte-code: reg                   ( physical space size -- )
v1 v2  017 1 byte-code: obsolete-fcode	\ Was intr         ( int-level vector -- )
v1     018 1 byte-code: obsolete-fcode	\ driver           ( adr len -- )
v1 v2  019 1 byte-code: model                 ( adr len -- )
v1 v2  01a 1 byte-code: device-type           ( adr len -- )
   v2  01b 1 byte-code: parse-2int            ( adr len -- address space )
			\ Was decode-2int

\ --- Driver Installation ------------------------------------------------
v1 v2  01f 1 byte-code: new-device            ( -- )

\ --- Selftest -----------------------------------------------------------
v1 v2  020 1 byte-code: diagnostic-mode?      ( -- flag )

v1 v2  021 1 byte-code: obsolete-fcode	\ Was display-status        ( n -- )
v1 v2  022 1 byte-code: memory-test-suite     ( adr len -- status)
v1 v2  023 1 byte-code: obsolete-fcode	\ Was group-code            ( -- adr )
v1 v2  024 1 byte-code: mask                  ( -- adr )

v1 v2  025 1 byte-code: get-msecs             ( -- ms )
v1 v2  026 1 byte-code: ms                    ( n -- )
v1 v2  027 1 byte-code: finish-device         ( -- )

v3     028 1 byte-code: decode-phys     ( adr1 len2 -- adr2 len2 phys.lo..hi )
v3     029 1 byte-code: push-package	( phandle -- )
v3     02a 1 byte-code: pop-package	( -- )
v3     02b 1 byte-code: interpose	( adr len phandle -- )
\      02c
\      02d
\      02e
\      02f

  v1 v2  030 1 byte-code: map-low        ( phys size -- virt ) \ Was map-sbus

\ --- Sbus Support - now obsolescent
  v1 v2  031 1 byte-code: sbus-intr>cpu  ( sbus-intr# -- cpu-intr# )
\ v1 v2  037 1 -- [S-Bus support]

\ --- P4 Bus address spaces - (these moved to /dev/p4bus/fcodeprims.fth) -
\ v1     038 1  -- [P4 Bus support] obsolete
\ v1     ...    -- [P4 Bus support] obsolete
\ v1     03f 1  -- [P4 Bus support] obsolete

\ --- Interrupts (Think about this!) -------------------------------------
\        040 1 byte-code: catch-interrupt       ( level vector -- )
\        041 1 byte-code: restore-interrupt     ( level -- )
\        042 1 byte-code: interrupt-occurred?   ( -- flag )
\        043 1 byte-code: enable-interrupt      ( level -- )
\        044 1 byte-code: disable-interrupt     ( level -- )
\        045 1
\        046 1
\        047 1
\        048 1
\        049 1
\        04a 1
\        04b 1
\        04c 1
\        04d 1
\        04e 1
\        04f 1

\ --- VME Bus address spaces - (these moved to /dev/vmebus/fcodeprims.fth)
\ v1 v2  090 1  -- [VME Bus support]
\ v1 v2  ...    -- [VME Bus support]
\ v1 v2  096 1  -- [VME Bus support]

\ --- NET OPERATIONS -----------------------------------------------------
\ v1     0a0 1 byte-code: return-buffer
\ v1 obs 0a1 1 byte-code: xmit-packet           ( bufadr #bytes -- #sent     )
\ v1 obs 0a2 1 byte-code: poll-packet           ( bufadr #bytes -- #received )
\ v1     0a3 1 byte-code: local-mac-address     (    adr len -- ) \ Driver sets this
v1 v2  0a4 1 byte-code: mac-address           ( -- adr len )    \ System sets this

\      0a5 1
\      0a6 1
\      0a7 1
\      0a8 1
\      0a9 1
\      0aa 1
\      0ab 1
\      0ac 1
\      0ad 1
\      0ae 1
\      0af 1

\      0b0 1
\      ...
\      0ff 1

\ --- Package and device handling ----------------------------------------
\      000 2  (reserved - because alocated by single byte fcodes)
v2    001 2 byte-code: device-name           ( addr len -- )
v2    002 2 byte-code: my-args               ( -- addr len )
v2    003 2 byte-code: my-self               ( -- ihandle )
v2    004 2 byte-code: find-package          ( adr len -- [phandle] ok? )
v2    005 2 byte-code: open-package          ( adr len phandle -- ihandle | 0 )
v2    006 2 byte-code: close-package         ( ihandle -- )
v2    007 2 byte-code: find-method           ( adr len phandle -- [acf] ok? )
v2    008 2 byte-code: call-package          ( acf ihandle -- )
v2    009 2 byte-code: $call-parent          ( adr len -- )
v2    00a 2 byte-code: my-parent             ( -- ihandle )
v2    00b 2 byte-code: ihandle>phandle       ( ihandle -- phandle )

\     00c 2

v2    00d 2 byte-code: my-unit               ( -- offset space )
v2    00e 2 byte-code: $call-method          ( adr len ihandle -- )
v2    00f 2 byte-code: $open-package         ( arg-adr,len name-adr,len -- ihandle | 0 )

\ --- CPU information ----------------------------------------------------
\ Obs v2    010 2 byte-code: processor-type        ( -- processor-type )
v2    011 2 byte-code: obsolete-fcode	\ Was firmware-version      ( -- n )
v2    012 2 byte-code: obsolete-fcode	\ Was fcode-version         ( -- n )

\ --- Asyncronous support ------------------------------------------------
v2    013 2 byte-code: alarm                 ( acf n -- )

\ --- User interface -----------------------------------------------------
v2    014 2 byte-code: (is-user-word)        ( adr len acf -- )

\ --- Interpretation -----------------------------------------------------
v2    015 2 byte-code: suspend-fcode         ( -- )

\ --- Error handling -----------------------------------------------------
v2    016 2 byte-code: abort                 ( -- )
v2    017 2 byte-code: catch                 ( acf -- error-code )
v2    018 2 byte-code: throw                 ( error-code -- )
v2.1  019 2 byte-code: user-abort            ( -- )

\ --- Package attributes -------------------------------------------------
v2    01a 2 byte-code: get-my-property         ( nam-adr nam-len -- [val-adr val-len] failed? )
			\ Was get-my-attribute
v2    01b 2 byte-code: decode-int              ( val-adr val-len -- n )
			\ Was xdrtoint
v2    01c 2 byte-code: decode-string           ( val-adr val-len -- adr len )
			\ Was xdrtostring
v2    01d 2 byte-code: get-inherited-property  ( nam-adr nam-len -- [val-adr val-len] failed? )
			\ Was get-inherited-attribute
v2    01e 2 byte-code: delete-property         ( nam-adr nam-len -- )
			\ Was delete-attribute
v2    01f 2 byte-code: get-package-property    ( adr len phandle -- [val-adr val-len] failed? )
			\ Was get-package-attribute

\ --- aligned, atomic access ---------------------------------------------
v2    020 2 byte-code: cpeek                 ( adr -- { byte true } | false )
v2    021 2 byte-code: wpeek                 ( adr -- { word true } | false )
v2    022 2 byte-code: lpeek                 ( adr -- { long true } | false )

v2    023 2 byte-code: cpoke                 ( byte adr -- ok? )
v2    024 2 byte-code: wpoke                 ( word adr -- ok? )
v2    025 2 byte-code: lpoke                 ( long adr -- ok? )

v3    026 2 byte-code: lwflip                ( l1 -- l2 )
v3    027 2 byte-code: lbflip                ( l1 -- l2 )
v3    028 2 byte-code: lbflips               ( adr len -- )

\  v2 029 2 byte-code: adr-mask              ( n -- )
\     02a 2
\     02b 2
\     02c 2
\     02d 2

64\ v3     02e 2 byte-code: rx@	   ( xaddr -- o )
64\ v3     02f 2 byte-code: rx!        ( o xaddr -- )

[ifdef] notdef
\ These FCode Functions are installed in the token tables later, after their
\ system-dependent implementations are defined.  See ./regcodes.fth
v2    030 2 byte-code: rb@                   (      adr -- byte )
v2    031 2 byte-code: rb!                   ( byte adr --      )
v2    032 2 byte-code: rw@                   (      adr -- word )
v2    033 2 byte-code: rw!                   ( word adr --      )
v2    034 2 byte-code: rl@                   (      adr -- long )
v2    035 2 byte-code: rl!                   ( long adr --      )
[then]

fload ${BP}/pkg/fcode/regcodes.fth

v2    036 2 byte-code: wbflips               ( adr len -- )  \ Was wflips
v2    037 2 byte-code: lwflips               ( adr len -- )  \ Was lflips

\ --- probing of subordinate devices
v2.2  038 2 byte-code: obsolete-fcode	\ Was probe  ( arg-str reg-str fcode-str -- )
v2.2  039 2 byte-code: obsolete-fcode	\ Was probe-virtual ( arg-str reg-str fcode-adr -- )

\     03a 2
v2.3  03b 2 byte-code: child                 ( phandle -- phandle' )
v2.3  03c 2 byte-code: peer                  ( phandle -- phandle' )
v3    03d 2 byte-code: next-property
			     \  ( adr1 len1 phandle -- false | adr2 len2 true )
v3    03e 2 byte-code: byte-load	     ( adr xt -- )
v3    03f 2 byte-code: set-args            ( arg-str unit-str -- )

\ --- parsing argument strings
v2    040 2 byte-code: left-parse-string ( adr len char -- adrR lenR adrL lenL )
