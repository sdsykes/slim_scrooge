/* Author: Lourens Naudé */

#include "ruby.h"
#include "node.h"
#include "env.h"

static int strhash(register const char *string) {
  register int c;
  register int val;
  register const char* s1 = string;
  register const char* s2 = string;

  while ((c = *string++) != '\0') {
    if (c == '/') {
      if (val)
        s1 = string;
      else
        s2 = string;
      val = !val;
  }
  }
  if (s1 > s2) {
    s1 = s2;
  }
  val = 0;
  while ((c = *s1++) != '\0') {
    val = val*997 + c;
  }
  return val + (val>>5);
}

static VALUE rb_f_callsite(VALUE obj) {
  struct FRAME *frame = ruby_frame;
  NODE *n;
  int csite = 0;
  int files = 0;

  if (frame->last_func == ID_ALLOCATOR) frame = frame->prev;

  ruby_set_current_source();
  if (ruby_sourcefile) csite += strhash(ruby_sourcefile);
  csite += frame->last_func + ruby_sourceline; 

  for (; frame && (n = frame->node) && files < 10; frame = frame->prev) {
    if (frame->prev && frame->prev->last_func) {
      if (frame->prev->node == n) {
        if (frame->prev->last_func == frame->last_func) continue;
      }
      csite += frame->prev->last_func;
    }
    if (n->nd_file) {
      csite += strhash(n->nd_file);
      files++;
    } 
    csite += nd_line(n);
  }

  return INT2FIX(csite);
}

void Init_callsite_hash() {
  rb_define_global_function("callsite_hash", rb_f_callsite, 0);
}