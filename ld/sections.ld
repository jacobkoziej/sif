/* SPDX-License-Identifier: MPL-2.0 */
/*
 * sections.ld -- section mapping
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

.rodata._vectors (READONLY) : ALIGN(vector_align) {
	KEEP(*(.rodata._vectors))
} > flash_vma AT> flash_lma

.text (READONLY) : ALIGN(word_align) {
	*(.text)
	*(.text.*)
} > flash_vma AT> flash_lma

.ARM.exidx (READONLY) : ALIGN(word_align) {
	*(.ARM.exidx)
	*(.ARM.exidx.*)
} > flash_vma AT> flash_lma

.rodata (READONLY) : ALIGN(word_align) {
	*(.rodata)
	*(.rodata.*)
} > flash_vma AT> flash_lma

.data : ALIGN(word_align) {
	*(.data)
	*(.data.*)
} > sram AT> flash_lma

.bss (NOLOAD) : ALIGN(word_align) {
	*(.bss)
	*(.bss.*)
} > sram

.ARM.attributes 0 : { *(.ARM.attributes) }
.comment        0 : { *(.comment)        }
.debug_abbrev   0 : { *(.debug_abbrev)   }
.debug_aranges  0 : { *(.debug_aranges)  }
.debug_frame    0 : { *(.debug_frame)    }
.debug_info     0 : { *(.debug_info)     }
.debug_line     0 : { *(.debug_line)     }
.debug_line_str 0 : { *(.debug_line_str) }
.debug_loclists 0 : { *(.debug_loclists) }
.debug_rnglists 0 : { *(.debug_rnglists) }
.debug_str      0 : { *(.debug_str)      }
.shstrtab       0 : { *(.shstrtab)       }
.strtab         0 : { *(.strtab)         }
.symtab         0 : { *(.symtab)         }

.unmapped 0 : { *(*) }

ASSERT(SIZEOF(.unmapped) == 0, "SIZEOF(.unmapped) != 0")
