#!/bin/sh
#
# move-if-changed <file1> <file2>
# 
# if (file2 != file1) then copy file2 to file1.
#
src=$1
dest=$2
tmp1=$src.tmp
tmp2=$dest.tmp

RM="/usr/bin/rm -f"
GREP="/usr/bin/grep"
SCCS="/usr/ccs/bin/sccs"
CP="/usr/bin/cp -p"
TOUCH="/usr/bin/touch"
CMP="/usr/bin/cmp -s"
CHMOD="/usr/bin/chmod"

$RM $tmp1 $tmp2
$GREP -v '#' $src > $tmp1
$GREP -v '#' $dest > $tmp2
$TOUCH $tmp1 $tmp2
if $CMP $tmp1 $tmp2; then
	/bin/true
else
	dir=`dirname $src`;
	fname=`basename $src`;
	here=`pwd`;
	cd $dir
	$CHMOD -w $fname
	$RM SCCS/p.$fname
	$SCCS edit $fname > /dev/null
	cd $here
	$CP -f $dest $src
fi
$RM $tmp1 $tmp2 $dest
exit 0
