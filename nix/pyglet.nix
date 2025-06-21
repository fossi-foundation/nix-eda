# Copyright 2025 nix-eda Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Code adapated from Nixpkgs, original license follows:
# ---
# Copyright (c) 2003-2023 Eelco Dolstra and the Nixpkgs/NixOS contributors
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
{
  lib,
  stdenv,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
  libGL,
  libGLU,
  xorg,
  pytestCheckHook,
  glibc,
  gtk2-x11,
  gdk-pixbuf,
  fontconfig,
  freetype,
  ffmpeg-full,
  openal,
  libpulseaudio,
  mesa,
  apple-sdk,
  harfbuzz,
  ffmpeg,
  version ? "2.1.6",
  hash ? "sha256-GEg4gLFBGzlpLq93VoGShXl7Gq+e9j1A65+bXQHGNBY=",
}: let
  frameworkPath = name: "${apple-sdk}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/${name}.framework/${name}";
  self = buildPythonPackage {
    pname = "pyglet";
    inherit version;
    format = "setuptools";
    disabled = pythonOlder "3.6";

    src = fetchPypi {
      inherit (self) pname version;
      inherit hash;
    };

    # find_library doesn't reliably work with nix (https://github.com/NixOS/nixpkgs/issues/7307).
    # Even naively searching `LD_LIBRARY_PATH` won't work since `libc.so` is a linker script and
    # ctypes.cdll.LoadLibrary cannot deal with those. Therefore, just hardcode the paths to the
    # necessary libraries.
    postPatch = let
      ext = stdenv.hostPlatform.extensions.sharedLibrary;
    in
      if stdenv.isLinux
      then ''
        cat > pyglet/lib.py <<EOF
        import ctypes
        def load_library(*names, **kwargs):
            for name in names:
                path = None
                if name == 'GL':
                    path = '${libGL}/lib/libGL${ext}'
                elif name == 'EGL':
                    path = '${libGL}/lib/libEGL${ext}'
                elif name == 'GLU':
                    path = '${libGLU}/lib/libGLU${ext}'
                elif name == 'c':
                    path = '${glibc}/lib/libc${ext}.6'
                elif name == 'X11':
                    path = '${xorg.libX11}/lib/libX11${ext}'
                elif name == 'gdk-x11-2.0':
                    path = '${gtk2-x11}/lib/libgdk-x11-2.0${ext}'
                elif name == 'gdk_pixbuf-2.0':
                    path = '${gdk-pixbuf}/lib/libgdk_pixbuf-2.0${ext}'
                elif name == 'Xext':
                    path = '${xorg.libXext}/lib/libXext${ext}'
                elif name == 'fontconfig':
                    path = '${fontconfig.lib}/lib/libfontconfig${ext}'
                elif name == 'freetype':
                    path = '${freetype}/lib/libfreetype${ext}'
                elif name[0:2] == 'av' or name[0:2] == 'sw':
                    path = '${lib.getLib ffmpeg-full}/lib/lib' + name + '${ext}'
                elif name == 'openal':
                    path = '${openal}/lib/libopenal${ext}'
                elif name == 'pulse':
                    path = '${libpulseaudio}/lib/libpulse${ext}'
                elif name == 'Xi':
                    path = '${xorg.libXi}/lib/libXi${ext}'
                elif name == 'Xinerama':
                    path = '${xorg.libXinerama}/lib/libXinerama${ext}'
                elif name == 'Xxf86vm':
                    path = '${xorg.libXxf86vm}/lib/libXxf86vm${ext}'
                if path is not None:
                    return ctypes.cdll.LoadLibrary(path)
            raise Exception("Could not load library {}".format(names))
        EOF
      ''
      else if stdenv.isDarwin
      then ''
        cat > pyglet/lib.py <<EOF
        import os
        import ctypes
        def load_library(*names, **kwargs):
            path = None
            framework = kwargs.get('framework')
            if framework is not None:
              path = '${apple-sdk}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/{framework}.framework/{framework}'.format(framework=framework)
            else:
                names = kwargs.get('darwin', names)
                if not isinstance(names, tuple):
                    names = (names,)
                for name in names:
                    if name == "libharfbuzz.0.dylib":
                        path = '${harfbuzz}/lib/%s' % name
                        break
                    elif name.startswith('avutil'):
                        path = '${ffmpeg.dev}/lib/lib%s.dylib' % name
                        if not os.path.exists(path):
                            path = None
                        else:
                            break
            if path is not None:
                return ctypes.cdll.LoadLibrary(path)
            raise ImportError("Could not load library {}".format(names))
        EOF
      ''
      else "";

    # needs GL set up which isn't really possible in a build environment even in headless mode.
    # tests do run and pass in nix-shell, however.
    doCheck = false;

    nativeCheckInputs = [pytestCheckHook];

    preCheck =
      if stdenv.isLinux
      # libEGL not available for Darwin (despite meta.platforms on libGL) or
      # BSD. or anything
      then ''
        export PYGLET_HEADLESS=True
      ''
      else "";

    # test list taken from .travis.yml
    disabledTestPaths = [
      "tests/base"
      "tests/interactive"
      "tests/integration"
      "tests/unit/text/test_layout.py"
    ];

    pythonImportsCheck = ["pyglet"];

    meta = with lib; {
      homepage = "http://www.pyglet.org/";
      description = "Cross-platform windowing and multimedia library";
      license = licenses.bsd3;
      # The patch needs adjusting for other platforms
      platforms = platforms.linux ++ platforms.darwin;
    };
  };
in
  self
