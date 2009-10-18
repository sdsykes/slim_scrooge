require 'mkmf'

dir_config('callsite_hash')

create_makefile('callsite_hash')

$defs.push("-DRUBY18") if have_var('rb_trap_immediate', ['ruby.h', 'rubysig.h'])
