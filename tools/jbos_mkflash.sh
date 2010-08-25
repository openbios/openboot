#!/bin/sh
# ========== Copyright Header Begin ==========================================
# 
# Hypervisor Software File: jbos_mkflash.sh
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

#
# id: @(#)jbos_mkflash.sh 1.1 02/11/08
# purpose: Stiletto-specific version of the mkflash script.
# purpose: Builds the final script for the OS-level Flash PROM Update Utility
# copyright: Copyright 2002 Sun Microsystems, Inc. All Rights Reserved
# copyright: Use is subject to license terms.
#

say () {
	echo "$*" 2>&1 > /dev/tty
}

usage() {
	say "mkflash <in: gpio drvr name> <in: update prog name> <out: filename>"	say "        <in: drvr name 64b> [ OPS ] [ SUN4U ]"
	exit 1;
}

check() {
	if [ ! -f $1 ];
	then
		say  $1: No such file or directory
		exit 1
	fi
}

PATH=/usr/bin:/usr/sbin:/sbin
export PATH
RMF="rm -f"
RMRF="rm -rf"

cleanup() {
	$RMF $OUTPUT
}

trap cleanup 1 2 3 15

if test $# -lt 4
then
	usage
fi
if test $# -gt 6
then
	usage
fi
# Note that there will normally be 4 args, as shown in usage().  However,
# for Ops, a 5th arg may be passed in which, if it is "OPS", will cause
# the final script to be created such that a final reboot is not issued.
# Also the SUN4U flag may be provided, which causes the kernel nvram driver
# to be added as "eeprom" (sun4s doesn't have an eeprom node and so by
# default the eeprom driver does not get added).

INPGPIODRV=$1
INPGPIOCONF=$1.conf
PROGRAM=$2
OUTPUT=$3
INPDRVR64=$4
if test $# -eq 5
then
	ARG5=$5
else
	ARG5=NULL
fi

if test $# -eq 6
then
	ARG6=$6
else
	ARG6=NULL
fi

DRVRNAME=flashprom
DRV=/kernel/drv/$DRVRNAME

if [ $ARG5 = SUN4U -0 $ARG6 = SUN4U ]
then
EDRVRNAM=eeprom
EDRV=/kernel/drv/$EDRVRNAM
fi

GPIODRVRNAME=sb_gpio

check $INPGPIODRV
check $INPGPIOCONF
check $INPDRVR64
check $PROGRAM

cat << SEND > $OUTPUT
#!/bin/sh

#
# Copyright 1995-2000,2002 Sun Microsystems, Inc.
# All Rights Reserved
#

textdom="SUNW_UXFL_DTOP"

echo ""
echo \`gettext \$textdom \\
"Flash Update 2.4: Program and system initialization in progress..."\`
SEND

if [ $ARG5 = OPS -0 $ARG6 = OPS ]
then

cat << SEND >> $OUTPUT
echo ""
echo "This version of the flash update utility is intended for"
echo "use within Sun Microsystems' Operations groups only.  It"
echo "is not intended for use by other groups within Sun or by"
echo "customers external to Sun."
echo ""
SEND

fi

cat << SEND >> $OUTPUT

PATH=/usr/bin:/usr/sbin:/sbin
export PATH
XDRV=/kernel/drv
TMP=/tmp/flash-update.\$\$

if [ -w \$XDRV ]
then
        DRV=\$XDRV/$DRVRNAME
if [ $ARG5 = SUN4U -0 $ARG6 = SUN4U ]
then
	EDRV=\$XDRV/$EDRVRNAM
fi
else
# backup driver location is for OPS, since their systems usually run
# as clients, and thus don't have a /usr/kernel/drv.
    ALTDRVPATH=/platform/sun4u/kernel/drv
    if [ -w \$ALTDRVPATH ]
    then
      echo \`gettext \$textdom "\$XDRV does not exist or is not writable:"\`
      echo \`gettext \$textdom "Driver is now located at \$ALTDRVPATH ."\`
      DRV=\$ALTDRVPATH/$DRVRNAME
      EDRV=\$ALTDRVPATH/$EDRVRNAM
    else
      echo
      echo \`gettext \$textdom "Could not find a writable driver location;"\`
      echo \`gettext \$textdom "       \$XDRV"\`
      echo \`gettext \$textdom "       \$ALTDRVPATH"\`
      echo \`gettext \$textdom "\(Be sure the program is run as root.\)"\`
      echo
      echo \`gettext \$textdom "The flash PROM update was not successful."\`
      echo
      exit 1
    fi
fi

cleanup() {
rem_drv $DRVRNAME > /dev/null 2>&1
if [ $ARG5 = SUN4U -0 $ARG6 = SUN4U ]
    then
	    rem_drv $EDRVRNAM > /dev/null 2>&1
	    $RMF /dev/eeprom
	    $RMF \$EDRV
    fi
    $RMF /dev/flashprom:?
    $RMF \$DRV
    $RMF \$DRV.conf
    $RMF /kernel/drv/$GPIODRVRNAME.conf
    $RMRF \$TMP
}

trap cleanup 1 2 3 15

mkdir -m 700 \$TMP

GPIODRV_UU=\$TMP/sb_gpio.uu
GPIOCONF_UU=\$TMP/sb_gpio_conf.uu
DRV64_UU=\$TMP/flashprom64.uu

$RMF \$GPIODRV_UU \$TMP/sb_gpio.Z \$GPIOCONF_UU
$RMF \$DRV64_UU \$TMP/flashprom64.Z

cat << END > \$DRV64_UU
SEND

$RMF \$DRV64_UU

compress -cf $INPDRVR64 | uuencode flashprom64.Z \
		|sed 's/\\/\\\\/g' \
		|sed 's/\$/\\$/g' \
		>> $OUTPUT

cat << SEND >> $OUTPUT
END


# gpio driver (64-bit only)
cat << END >\$GPIODRV_UU
SEND

$RMF \$GPIODRV_UU

compress -cf $INPGPIODRV | uuencode sb_gpio64.Z \
		|sed 's/\\/\\\\/g' \
		|sed 's/\$/\\$/g' \
		>> $OUTPUT

cat << SEND >> $OUTPUT
END

# gpio driver conf file
cat << END >\$GPIOCONF_UU
SEND

$RMF \$GPIOCONF_UU

compress -cf $INPGPIOCONF | uuencode sb_gpio_conf.Z \
		|sed 's/\\/\\\\/g' \
		|sed 's/\$/\\$/g' \
		>> $OUTPUT

cat << SEND >> $OUTPUT
END

OUR_CWD=\`pwd\`

rem_drv $DRVRNAME > /dev/null 2>&1
rem_drv $GPIODRVRNAME > /dev/null 2>&1

if [ $ARG5 = SUN4U -0 $ARG6 = SUN4U ]
then
rem_drv $EDRVRNAM > /dev/null 2>&1
fi

$RMF \$DRV
if [ $ARG5 = SUN4U -0 $ARG6 = SUN4U ]
then
$RMF \$EDRV
fi
if [ -d /kernel/drv/sparcv9 ]
then
	$RMF /kernel/drv/sparcv9/$DRVRNAME
	$RMF /kernel/drv/sparcv9/$GPIODRVRNAME
	$RMF /kernel/drv/$GPIODRVRNAME.conf
	$RMF /kernel/drv/$DRVRNAME.conf
if [ $ARG5 = SUN4U -0 $ARG6 = SUN4U ]
then
	$RMF /kernel/drv/sparcv9/$EDRVRNAM
fi
fi

cd \$TMP; uudecode \$GPIODRV_UU ; uncompress sb_gpio64.Z
cd \$TMP; uudecode \$GPIOCONF_UU ; uncompress sb_gpio_conf.Z
cd \$TMP; uudecode \$DRV64_UU ; uncompress flashprom64.Z
cd \$OUR_CWD

if [ -d /kernel/drv/sparcv9 ]
then

    if [ $ARG5 = SUN4U -0 $ARG6 = SUN4U ]
    then
	cp -p \$TMP/flashprom64 /kernel/drv/sparcv9/$EDRVRNAM
    fi
    mv -f \$TMP/flashprom64 /kernel/drv/sparcv9/$DRVRNAME
    mv -f \$TMP/sb_gpio64 /kernel/drv/sparcv9/$GPIODRVRNAME
    mv -f \$TMP/sb_gpio_conf /kernel/drv/$GPIODRVRNAME.conf

     
else
    $RMF \$TMP/flashprom64
    echo \`gettext \$textdom "Flash Update 2.4: 64-bit kernel is required."\`
    echo \`gettext \$textdom "The flash PROM update was not successful."\`
    exit 1
fi

$RMF \$GPIODRV_UU \$TMP/sb_gpio64.Z \$DRV64_UU \$TMP/flashprom64.Z
$RMF \$GPIOCONF_UU \$TMP/sb_gpio_conf.Z

add_drv $DRVRNAME
add_drv $GPIODRVRNAME

if [ $ARG5 = SUN4U -0 $ARG6 = SUN4U ]
then
add_drv $EDRVRNAM
fi

AWKSCR=\$TMP/awk.\$$
cat <<EOF > \$AWKSCR
{
    printf  "rm -f /dev/flashprom:%s\n", \\\$2;
    printf  "ln -s %s:%s /dev/flashprom:%s\n", \\\$1, \\\$2, \\\$2;
}

EOF

AWKSCRE=\$TMP/awke.\$$
cat <<EOF > \$AWKSCRE
{
    printf  "rm -f /dev/eeprom\n";
    printf  "ln -s %s:%s /dev/eeprom\n", \\\$1, \\\$2;
}

EOF

AWKSCRG=\$TMP/awkg.\$$
cat <<EOF > \$AWKSCRG
{
    printf  "rm -f /dev/sb_gpio\n";
    printf  "ln -s %s:%s /dev/sb_gpio\n", \\\$1, \\\$2;
}

EOF

make_link() {
(
cd /devices
find ../devices -name "flashprom@*:\$1" -exec echo {} \; \
	|awk -F: -f \$AWKSCR  | /bin/sh
find ../devices -name "sb_gpio@*" -exec echo {} \; \
	|awk -F: -f \$AWKSCRG  | /bin/sh
if [ $ARG5 = SUN4U -0 $ARG6 = SUN4U ]
then
find ../devices -name "eeprom@*:\$1" -exec echo {} \; \
	|awk -F: -f \$AWKSCRE  | /bin/sh
fi
)
}

make_link 0

$RMF \$AWKSCR
if [ $ARG5 = SUN4U -0 $ARG6 = SUN4U ]
then
$RMF \$AWKSCRE
fi

PRG_UU=\$TMP/flash-update.uu

$RMF \$PRG_UU \$TMP/flash-update.Z
cat << END > \$PRG_UU
SEND

$RMF \$PRG_UU \$TMP/flash-update.Z

compress -cf $PROGRAM | uuencode flash-update.Z \
		|sed 's/\\/\\\\/g' \
		|sed 's/\$/\\$/g' \
		>> $OUTPUT


cat << SEND >> $OUTPUT
END

cd \$TMP; uudecode \$PRG_UU ; uncompress flash-update.Z ; \
chmod u+x flash-update
cd \$OUR_CWD
$RMF \$PRG_UU \$TMP/flash-update.Z

\$TMP/flash-update
exitval=\$?

cleanup

if [ \$exitval -eq 25 ]
then
# Exit status to indicate that the user chose to exit without doing the
# update - this is necessary so that a reboot is not issued.
      exit 0
fi


SEND

if [ $ARG5 = OPS -0 $ARG6 = OPS ]
then
#******ifthen-else-fi intentionally not indented******
# For Ops, always exit such that a reboot is never issued.

cat << SEND >> $OUTPUT
exit \$exitval
SEND

else

cat << SEND >> $OUTPUT
if [ \$exitval -ne 0 ]
then
	exit \$exitval
fi

echo ""
echo \`gettext \$textdom \\
"Please wait while the system is rebooted..."\`
echo ""
/etc/shutdown -i6 -g0 -y

SEND

fi
