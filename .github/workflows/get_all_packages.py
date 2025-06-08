import sys
import json
import subprocess

flake_meta_process = subprocess.Popen(
    ["nix", "flake", "show", "--json"],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    encoding="utf8",
)
flake_meta_process.wait()
if flake_meta_process.returncode:
    print(f"Failed to get flake metadata:", file=sys.stderr)
    print(flake_meta_process.stderr.read(), file=sys.stderr)
    exit(-1)
flake_meta = json.load(flake_meta_process.stdout)
packages = flake_meta["packages"]
for platform, packages in packages.items():
    for package, package_info in packages.items():
        if len(package_info):
            print(f".#packages.{platform}.{package}", end=" ")
