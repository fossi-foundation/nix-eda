#include <stdlib.h>

#ifndef GHDL_PREFIX
#pragma error "GHDL_PREFIX must be set"
#define GHDL_PREFIX "dummy"
#endif

__attribute__((constructor))
static void set_ghdl_pfx(void) {
    if (!getenv("GHDL_PREFIX")) {
        setenv("GHDL_PREFIX", GHDL_PREFIX, 1);
    }
}
