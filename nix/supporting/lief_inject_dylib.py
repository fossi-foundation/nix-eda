#!/usr/bin/env python3
"""
Uses the lief library to inject a dylib
"""
import os
import lief
import click


@click.command()
@click.option("-o", "--dylib-out", type=click.Path(writable=True), required=False)
@click.option("-i", "--inplace", is_flag=True)
@click.option("--inject", type=click.Path(readable=True), required=True)
@click.argument("dylib_in")
@click.pass_context
def main(ctx, dylib_out, inplace, inject, dylib_in):
    universal = lief.MachO.parse(dylib_in)
    if universal is None:
        ctx.exit(-1)

    inject = os.path.abspath(inject)

    if inplace:
        dylib_out = dylib_in

    arch_found = False
    for arch in universal:
        if arch_found:
            ctx.fail("lief_inject_dylib.py doesn't support multi-arch binaries")
            ctx.exit(-1)
        arch_found = True
        arch.add_library(os.path.abspath(inject))

        if arch.has_code_signature:
            arch.remove_signature()

    print(f"Writing to '{dylib_out}'…")
    universal.write(dylib_out)


if __name__ == "__main__":
    main()
