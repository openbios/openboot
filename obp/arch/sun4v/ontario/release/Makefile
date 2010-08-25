# id: @(#)Makefile  1.1  06/02/16
# purpose: 
# copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
# Use is subject to license terms.

ROOT		= ../../../../..
BP		= ${ROOT}/obp
SUN4V		= ${BP}/arch/sun4v
PLATFORM	= ${SUN4V}/ontario
RESET		= ${SUN4V}/niagara/reset.fth
LOADFILE	= ${SUN4V}/niagara/loadprom.fth
DROPINSRC	= ${PLATFORM}/release/dropins.src

PLATFLAGS	+= -D SUN4V
PLATFLAGS	+= -D Ontario

# Uncomment the following line to have verbose output for reset code.
# PLATFLAGS	+= -D VERBOSE-RESET

all:	openboot.bin

include ${SUN4V}/common.mk
include ../depend.mk
include ../reset.mk

FORCE:
