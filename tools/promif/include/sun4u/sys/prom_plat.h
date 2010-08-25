/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_plat.h
* 
* Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
* 
*  - Do no alter or remove copyright notices
* 
*  - Redistribution and use of this software in source and binary forms, with 
*    or without modification, are permitted provided that the following 
*    conditions are met: 
* 
*  - Redistribution of source code must retain the above copyright notice, 
*    this list of conditions and the following disclaimer.
* 
*  - Redistribution in binary form must reproduce the above copyright notice,
*    this list of conditions and the following disclaimer in the
*    documentation and/or other materials provided with the distribution. 
* 
*    Neither the name of Sun Microsystems, Inc. or the names of contributors 
* may be used to endorse or promote products derived from this software 
* without specific prior written permission. 
* 
*     This software is provided "AS IS," without a warranty of any kind. 
* ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
* INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
* PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
* MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
* ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
* DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
* OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
* FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
* DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
* ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
* SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
* 
* You acknowledge that this software is not designed, licensed or
* intended for use in the design, construction, operation or maintenance of
* any nuclear facility. 
* 
* ========== Copyright Header End ============================================
*/
/*
 * Copyright (c) 2000, 2003 Sun Microsystems, Inc. All rights reserved.
 * Use is subject to license terms.
 */

#ifndef	_SYS_PROM_PLAT_H
#define	_SYS_PROM_PLAT_H

#pragma ident	"@(#)prom_plat.h	1.1	00/08/07 SMI"

#ifdef	__cplusplus
extern "C" {
#endif

/*
 * This file contains external sun4u-specific promif interface definitions.
 */

/*
 * Memory allocation plus memory/mmu interfaces:
 *
 * Routines with fine-grained memory and MMU control are platform-dependent.
 *
 * MMU node virtualized "mode" arguments and results:
 *
 * The default virtualized "mode" for client program mappings created
 * by the firmware is as follows:
 *
 * G (global)		Clear
 * L (locked)		Clear
 * W (write)		Set
 * R (read - soft)	Set (Prom is not required to implement soft bits)
 * X (exec - soft)	Set (Prom is not required to implement soft bits)
 * CV,CP (Cacheable)	Set if memory page, Clear if IO page
 * E (side effects)	Clear if memory page; Set if IO page
 * IE (Invert endian.)	Clear
 *
 * The following fields are initialized as follows in the TTE-data for any
 * mappings created by the firmware on behalf of the client program:
 *
 * P (Priviledged)	Set
 * V (Valid)		Set
 * NFO (No Fault Only)	Clear
 * Context		0
 * Soft bits		< private to the firmware implementation >
 *
 * Page size of Prom mappings are typically 8k, "modify" cannot change
 * page sizes. Mappings created by "map" are 8k pages.
 *
 * If the virtualized "mode" is -1, the defaults as shown above are used,
 * otherwise the virtualized "mode" is set (and returned) based on the
 * following virtualized "mode" abstractions. The mmu node "translations"
 * property contains the actual tte-data, not the virtualized "mode".
 *
 * Note that client programs may not create locked mappings by setting
 * the LOCKED bit. There are specific client interfaces to create
 * and remove locked mappings. (SUNW,{i,d}tlb-load).
 * The LOCKED bit is defined here since it may be returned by the
 * "translate" method.
 *
 * The PROM is not required to implement the Read and eXecute soft bits,
 * and is not required to track them for the client program. They may be
 * set on calls to "map" and "modfify" and may be ignored by the firmware,
 * and are not necessarily returned from "translate".
 *
 * The TTE soft bits are private to the firmware.  No assumptions may
 * be made regarding the contents of the TTE soft bits.
 *
 * Changing a mapping from cacheable to non-cacheable implies a flush
 * or invalidate operation, if necessary.
 *
 * The "map" MMU node method should NOT be used to create IO device
 * mappings. The correct way to do this is to call the device's parent
 * "map-in" method using the CALL-METHOD client interface service.
 */

#define	PROM_MMU_MODE_DEFAULT	((int)-1)	/* Default "mode", see above */

#define	PROM_MMU_MODE_WRITE	0x0001	/* Translation is Writable */
#define	PROM_MMU_MODE_READ	0x0002	/* Soft: Readable, See above */
#define	PROM_MMU_MODE_EXEC	0x0004	/* Soft: eXecutable, See above */
#define	PROM_MMU_MODE_RWX_MASK	0x0007	/* Mask for R-W-X bits */

#define	PROM_MMU_MODE_LOCKED	0x0010	/* Read-only: Locked; see above */
#define	PROM_MMU_MODE_CACHED	0x0020	/* Set means both CV,CP bits */
#define	PROM_MMU_MODE_EFFECTS	0x0040	/* side Effects bit in MMU */
#define	PROM_MMU_MODE_GLOBAL	0x0080	/* Global bit */
#define	PROM_MMU_MODE_INVERT	0x0100	/* Invert Endianness */

/*
 * prom_alloc is platform dependent and has historical semantics
 * associated with the align argument and the return value.
 * prom_malloc is the generic memory allocator.
 */
extern	caddr_t		prom_alloc(caddr_t virthint, size_t size, uint_t align);

extern	caddr_t		prom_allocate_virt(uint_t align, size_t size);
extern	caddr_t		prom_claim_virt(size_t size, caddr_t virt);
extern	void		prom_free_virt(size_t size, caddr_t virt);

extern	int		prom_allocate_phys(size_t size, uint_t align,
			    unsigned long long *physaddr);
extern	int		prom_claim_phys(size_t size,
			    unsigned long long physaddr);
extern	void		prom_free_phys(size_t size,
			    unsigned long long physaddr);

extern	int		prom_map_phys(int mode, size_t size, caddr_t virt,
			    unsigned long long physaddr);
extern	void		prom_unmap_phys(size_t size, caddr_t virt);
extern	void		prom_unmap_virt(size_t size, caddr_t virt);

/*
 * prom_retain allocates or returns retained physical memory
 * identified by the arguments of name string "id", "size" and "align".
 */
extern	int		prom_retain(char *id, size_t size, uint_t align,
			    unsigned long long *physaddr);

/*
 * prom_translate_virt returns the physical address and virtualized "mode"
 * for the given virtual address. After the call, if *valid is non-zero,
 * a mapping to 'virt' exists and the physical address and virtualized
 * "mode" were returned to the caller.
 */
extern	int		prom_translate_virt(caddr_t virt, int *valid,
			    unsigned long long *physaddr, int *mode);

/*
 * prom_modify_mapping changes the "mode" of an existing mapping or
 * repeated mappings. virt is the virtual address whose "mode" is to
 * be changed; size is some multiple of the fundamental pagesize.
 * This method cannot be used to change the pagesize of an MMU mapping,
 * nor can it be used to Lock a translation into the i or d tlb.
 */
extern	int	prom_modify_mapping(caddr_t virt, size_t size, int mode);

/*
 * Client interfaces for managing the {i,d}tlb handoff to client programs.
 */
extern	int		prom_itlb_load(int index,
			    unsigned long long tte_data, caddr_t virt);
extern	int		prom_dtlb_load(int index,
			    unsigned long long tte_data, caddr_t virt);

/*
 * Prom heartbeat
 */
extern	int		prom_heartbeat(int msecs);

/*
 * CPU Control Group: MP's only.
 */
extern	int		prom_startcpu(dnode_t node, caddr_t pc, int arg);
extern	int		prom_stop_self(void);
extern	int		prom_idle_self(void);
extern	int		prom_resumecpu(dnode_t node);

/*
 * Set trap table
 */
extern	void		prom_set_traptable(void *tba_addr);

/*
 * Power-off
 */
extern	void		prom_power_off(void);

/*
 * The client program implementation is required to provide a wrapper
 * to the client handler, for the 32 bit client program to 64 bit cell-sized
 * client interface handler (switch stack, etc.).  This function is not
 * to be used externally!
 */
extern	int		client_handler(void *cif_handler, void *arg_array);

/*
 * The 'format' of the "translations" property in the 'mmu' node ...
 */
struct translation {
	uint32_t virt_hi;	/* upper 32 bits of vaddr */
	uint32_t virt_lo;	/* lower 32 bits of vaddr */
	uint32_t size_hi;	/* upper 32 bits of size in bytes */
	uint32_t size_lo;	/* lower 32 bits of size in bytes */
	uint32_t tte_hi;	/* higher 32 bites of tte */
	uint32_t tte_lo;	/* lower 32 bits of tte */
};

#ifdef	__cplusplus
}
#endif

#endif /* _SYS_PROM_PLAT_H */
