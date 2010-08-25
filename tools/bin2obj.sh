#!/bin/sh
# ========== Copyright Header Begin ==========================================
# 
# Hypervisor Software File: bin2obj.sh
# 
# Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
# 
#  - Do no alter or remove copyright notices
# 
#  - Redistribution and use of this software in source and binary forms, with 
#    or without modification, are permitted provided that the following 
#    conditions are met: 
# 
#  - Redistribution of source code must retain the above copyright notice, 
#    this list of conditions and the following disclaimer.
# 
#  - Redistribution in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution. 
# 
#    Neither the name of Sun Microsystems, Inc. or the names of contributors 
# may be used to endorse or promote products derived from this software 
# without specific prior written permission. 
# 
#     This software is provided "AS IS," without a warranty of any kind. 
# ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
# INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
# PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
# MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
# ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
# DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
# OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
# FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
# DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
# ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
# SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
# 
# You acknowledge that this software is not designed, licensed or
# intended for use in the design, construction, operation or maintenance of
# any nuclear facility. 
# 
# ========== Copyright Header End ============================================
#	id: @(#)bin2obj.sh 1.7 03/04/01
#	purpose: Convert a binary  file into native object ( .o ) file
#	Copyright 1992-1997,2003 Sun Microsystems, Inc.  All Rights Reserved
#	Use is subject to license terms.

#
#  Usage:  bin2obj symbol-name  input-file output-file
#

usage() {
    echo Usage:  bin2obj [ -start ssymbol ] [ -end esymbol ] [ -64 ] \
	input-file output-file
    exit 1;
}

add_symbol() {
cat << END >> $TMP
.seg "data"
.global $1,
$1:
END
	if [ -x /usr/ccs/bin/as ]
	then
	cat << END >> $TMP
.type $1, #object; .size $1, 1
END
	fi
}

cleanup() {
    $RM  -f $TMP
}

trap cleanup 1 2 3 10

if test $# -lt 2
 then
	usage
fi


while [ x"$1" != x"" ]
do
case $1 in
    	-end)
		shift
                ENDSYM=$1
		shift
                ;;
    	-start)
		shift
                STARTSYM=$1
		shift
                ;;
	-64)
		ASARG="-xarch=v9"
		shift
		;;
	*)
	    if [ "$infile" = "" ] ;
	    then
		infile=$1;
		shift
	    else
		if [ "$outfile" = "" ] ;
		then
		    outfile=$1
		    shift
		else
		    usage
		fi
	    fi
	    ;;
esac
done

if [ ! -f $infile ] ;
then
    echo Can\'t open input file: $infile
    exit 1;
fi

RM=/usr/bin/rm
AS=/usr/bin/as
OD=/usr/bin/od
AWK=/usr/bin/awk

# On Solaris 2.x assembler is in /usr/ccs/bin
if [ -x /usr/ccs/bin/as ]
then
  AS=/usr/ccs/bin/as
fi

TMP=/tmp/$$.s

$RM -f $TMP

if [ "$STARTSYM" != "" ] ;
then
    add_symbol $STARTSYM
fi

$OD -Xv $infile | $AWK '{ if ( NF == 5 ) \
{ printf ".word 0x%s, 0x%s, 0x%s, 0x%s\n", $2, $3, $4, $5 ;} \
else { for ( i = 2 ; i <= NF; i++ ) \
{ printf ".word 0x%s\n", $i ; } }}' >> $TMP

if [ "$ENDSYM" != "" ] ;
then
    add_symbol $ENDSYM
fi

$AS $ASARG $TMP -o $outfile

cleanup

