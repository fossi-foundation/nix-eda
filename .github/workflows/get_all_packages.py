import sys
import json
import subprocess


def run(purpose, *args):
    process = subprocess.Popen(
        [*args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        encoding="utf8",
    )
    process.wait()
    if process.returncode:
        print(f"Failed to {purpose}:", file=sys.stderr)
        print(process.stderr.read(), file=sys.stderr)
        exit(-1)
    return process.stdout


flake_meta = json.load(run("get flake metadata", "nix", "flake", "show", "--json"))
packages = flake_meta["packages"]
for platform, packages in packages.items():
    for package, package_info in packages.items():
        if len(package_info) == 0:
            continue
        tgt = f".#packages.{platform}.{package}"
        outputs = []
        drv = json.load(
            run(f"get derivation info for {package}", "nix", "derivation", "show", tgt)
        )
        keys = list(drv.keys())
        if len(keys) != 1:
            print(
                f"'nix derivation show' unexpectedly returned {len(keys)} paths, expected exactly 1: {tgt}",
                file=sys.stderr,
            )
            exit(-1)
        output_list = drv[keys[0]]["outputs"]
        for output in output_list:
            print(f"{tgt}.{output}")
