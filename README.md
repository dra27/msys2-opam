# MSYS2 Environment configuration in opam-repository

[MSYS2][] installs a friendly fork of [Cygwin][], by default in `C:\msys64`.
This is based on Cygwin, but uses a different packaging system for the native
Windows compiler toolchains from Cygwin's. MSYS2 has a concept of an
[Environment][], and each environment has one compiler toolchain. These
toolchains are installed in entirely separate root directories (i.e. they have
strictly separated bin, include and lib directories, rather than using multilib
approaches) and have their own package namespace.

An MSYS2 Environment is activated in a not dissimilar way to a Visual Studio
Tools Command Prompt. The base Environment (MSYS) provides the POSIX utilities
needed to support configuration and build of software (and packages installed in
this are based on Cygwin's newlib and POSIX emulation layer, rather than native
Windows libraries and the Win32 API) and then one additional Environment can
then be selected on top of this, causing its bin directory, etc. to be selected
in the environment.

This project provides an msys2 package and a series of virtual packages to
select which additional MSYS2 Environment should be activated for a given
switch.

[MSYS2]: https://msys2.org
[Cygwin]: https://cygwin.com
[Environment]: https://www.msys2.org/docs/environments

# Mechanism

MSYS2's Environment is fundamentally derived from the MSYSTEM environment
variable (which is what the various Terminal shortcuts set before then starting
the login shell). The value **MSYS** refers to the base "default" Environment
(that is a POSIX gcc based on Cygwin's newlib) and is assumed to have been
set-up by the user (or opam). The remaining 6 values seelect actual native
compilation toolchains:

| MSYSTEM        | Toolchain | Architecture | C Library | C++ Library |                                                                              |
|----------------|-----------|--------------|-----------|-------------|------------------------------------------------------------------------------|
| **UCRT64**     | gcc       | x86\_64      | ucrt      | libstdc++   | <img src="https://www.msys2.org/docs/ucrt64.png" width="25" height="25">     |
| **CLANG64**    | llvm      | x86\_64      | ucrt      | libc++      | <img src="https://www.msys2.org/docs/clang64.png" width="25" height="25">    |
| **CLANGARM64** | llvm      | aarch64      | ucrt      | libc++      | <img src="https://www.msys2.org/docs/clangarm64.png" width="25" height="25"> |
| **CLANG32**    | llvm      | i686         | ucrt      | libc++      | <img src="https://www.msys2.org/docs/clang32.png" width="25" height="25">    |
| **MINGW64**    | gcc       | x86\_64      | msvcrt    | libstdc++   | <img src="https://www.msys2.org/docs/mingw64.png" width="25" height="25">    |
| **MINGW32**    | gcc       | i686         | msvcrt    | libstdc++   | <img src="https://www.msys2.org/docs/mingw32.png" width="25" height="25">    |

Each of these six toolchains is represented by an msys2-_toolchain_ package,
msys2-ucrt64, msys2-clang64, etc. Only one of these six packages may be
installed in a given opam switch.

`gen_config.sh` sets MSYSTEM to one of these six values and then sources
`/etc/msystem` (which is what MSYS2's `/etc/profile` also does). `/etc/msystem`
is responsible for setting 6 environment variables:
- MSYSTEM\_CARCH / MINGW\_CARCH are identical and are the Architecture from the
  table above
- MSYSTEM\_CHOST / MINGW\_CHOST are identical and the target triplet of the
  compiler (effectively `"$MSYSTEM_CARCH-w64-mingw32"`)
- MSYSTEM\_PREFIX is the Unix-style path to the Environment's files
  (e.g. `/mingw64` for the **MINGW64** environment)
- MINGW\_PACKAGE\_PREFIX is the prefix used for packages in the MSYS2 package
  repository. For example, to install libzstd for the current environment, one
  installs `"$MINGW_PACKAGE_PREFIX-zstd"` (e.g. mingw-w64-clang-x86\_64-zstd)

The msys2 package:
- Verifies that MSYSTEM\_CARCH equals MINGW\_CARCH and MSYSTEM\_CHOST equals
  MINGW\_CHOST
- Exports opam package variables with:
```sh
      _:carch = "$MSYSTEM_CARCH"
      _:chost = "$MSYSTEM_CHOST"
      _:root = "$MSYSTEM_PREFIX"
      _:native-root = "$(cygpath -w $MSYSTEM_PREFIX)"
      _:package-prefix = "$MINGW_PACKAGE_PREFIX"
```
- Adds MSYSTEM and the six variables set by `/etc/msystem` to the user's
  environment (via opam's `setenv` mechanism)
- Unconditionally sets (again, via `setenv`):
```sh
      export CONFIG_SITE='/etc/config.site'
      export PKG_CONFIG_PATH="$MSYSTEM_PREFIX/lib/pkgconfig:$MSYSTEM_PREFIX/share/pkgconfig"
      export PKG_CONFIG_SYSTEM_INCLUDE_PATH="$MSYSTEM_PREFIX/include"
      export PKG_CONFIG_SYSTEM_LIBRARY_PATH="$MSYSTEM_PREFIX/lib"
      export ACLOCAL_PATH="$MSYSTEM_PREFIX/share/aclocal:$MSYSTEM_PREFIX/usr/share/aclocal"
```
- `PATH`, `MANPATH` and `INFOPATH` have the appropriate directories under
  MINGW\_PREFIX added using `setenv`'s `+=` operator

This process mirrors that done by `/etc/profile` in MSYS2.

# opam package

`gen_config.sh` is intended for use in [opam-repository][] and generates an
opam .config file. The script itself must be run under MSYS2, not Cygwin (it
will gracefully fail to find `/etc/msystem` if run on Cygwin).

[opam-repository]: https://github.com/ocaml/opam-repository
