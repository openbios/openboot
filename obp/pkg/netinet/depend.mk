# ========== Copyright Header Begin ==========================================
# 
# Hypervisor Software File: depend.mk
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
# id: @(#)depend.mk  1.1  04/09/07
# purpose: 
# copyright: Copyright 2004 Sun Microsystems, Inc. All Rights Reserved
# copyright: Use is subject to license terms.
# This is a machine generated file
# DO NOT EDIT IT BY HAND

obptftp.fc: ${BP}/pkg/netinet/args.fth
obptftp.fc: ${BP}/pkg/netinet/arp-h.fth
obptftp.fc: ${BP}/pkg/netinet/arp.fth
obptftp.fc: ${BP}/pkg/netinet/cfg-params.fth
obptftp.fc: ${BP}/pkg/netinet/dhcp-h.fth
obptftp.fc: ${BP}/pkg/netinet/dhcp.fth
obptftp.fc: ${BP}/pkg/netinet/ethernet.fth
obptftp.fc: ${BP}/pkg/netinet/hmac-sha1.fth
obptftp.fc: ${BP}/pkg/netinet/http.fth
obptftp.fc: ${BP}/pkg/netinet/icmp.fth
obptftp.fc: ${BP}/pkg/netinet/in-cksum.fth
obptftp.fc: ${BP}/pkg/netinet/in-h.fth
obptftp.fc: ${BP}/pkg/netinet/inet.fth
obptftp.fc: ${BP}/pkg/netinet/inpcb.fth
obptftp.fc: ${BP}/pkg/netinet/insock.fth
obptftp.fc: ${BP}/pkg/netinet/ip-h.fth
obptftp.fc: ${BP}/pkg/netinet/ip-input.fth
obptftp.fc: ${BP}/pkg/netinet/ip-output.fth
obptftp.fc: ${BP}/pkg/netinet/ip.fth
obptftp.fc: ${BP}/pkg/netinet/ipreasm-h.fth
obptftp.fc: ${BP}/pkg/netinet/nbpools.fth
obptftp.fc: ${BP}/pkg/netinet/netif-h.fth
obptftp.fc: ${BP}/pkg/netinet/netif.fth
obptftp.fc: ${BP}/pkg/netinet/netload.fth
obptftp.fc: ${BP}/pkg/netinet/prerrors-h.fth
obptftp.fc: ${BP}/pkg/netinet/props.fth
obptftp.fc: ${BP}/pkg/netinet/queue.fth
obptftp.fc: ${BP}/pkg/netinet/rarp.fth
obptftp.fc: ${BP}/pkg/netinet/route.fth
obptftp.fc: ${BP}/pkg/netinet/sha1.fth
obptftp.fc: ${BP}/pkg/netinet/sock-h.fth
obptftp.fc: ${BP}/pkg/netinet/sockif.fth
obptftp.fc: ${BP}/pkg/netinet/strings.fth
obptftp.fc: ${BP}/pkg/netinet/tcb.fth
obptftp.fc: ${BP}/pkg/netinet/tcp-debug.fth
obptftp.fc: ${BP}/pkg/netinet/tcp-h.fth
obptftp.fc: ${BP}/pkg/netinet/tcp-input.fth
obptftp.fc: ${BP}/pkg/netinet/tcp-output.fth
obptftp.fc: ${BP}/pkg/netinet/tcp-reqs.fth
obptftp.fc: ${BP}/pkg/netinet/tcp-timer.fth
obptftp.fc: ${BP}/pkg/netinet/tcp-trace.fth
obptftp.fc: ${BP}/pkg/netinet/tcp.fth
obptftp.fc: ${BP}/pkg/netinet/tcpbuf.fth
obptftp.fc: ${BP}/pkg/netinet/tftp-h.fth
obptftp.fc: ${BP}/pkg/netinet/tftp.fth
obptftp.fc: ${BP}/pkg/netinet/timer.fth
obptftp.fc: ${BP}/pkg/netinet/udp-h.fth
obptftp.fc: ${BP}/pkg/netinet/udp-reqs.fth
obptftp.fc: ${BP}/pkg/netinet/udp.fth
obptftp.fc: ${BP}/pkg/netinet/uriparse.fth
obptftp.fc: ${BP}/pkg/netinet/utils.fth
obptftp.fc: ${BP}/pkg/netinet/wanboot.fth
obptftp.fc: ${BP}/pkg/netinet/obptftp.tok
