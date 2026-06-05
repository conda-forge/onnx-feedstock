# onnx 1.22.0 — build notes & upstream issues

Tracking notes for [conda-forge/onnx-feedstock#147](https://github.com/conda-forge/onnx-feedstock/issues/147)
("Integrate the upcoming ONNX 1.22.0 release"). This file is the local
substitute for opening GitHub issues: each item below that is an upstream
(onnx) concern is marked **[upstream]** and should eventually be reported to
the onnx repository / @cbourjau before the final 1.22.0 release.

Scope of this round of work: get onnx **1.22.0rc1** to *build* on conda-forge
with no behavioural improvements — only the minimum changes needed to track
the new build system. Source used is the official PyPI sdist
(`onnx-1.22.0rc1.tar.gz`, sha256 `7799c0…`) because 1.22.0 has no GitHub
release tag yet (only the `rel-1.22.0` branch exists).

## Summary of challenges

| # | Challenge | Resolution | Where |
|---|-----------|------------|-------|
| 1 | Build backend `setuptools` → `scikit-build-core` (`setup.py` gone) | host dep `setuptools` → `scikit-build-core` | `recipe.yaml` |
| 2 | scikit-build-core installs the C++ lib/headers/CMake config **inside the wheel** (`site-packages/lib`) instead of `$PREFIX` (its `CMAKE_INSTALL_PREFIX` is the wheel staging dir) | keep `-DONNX_INSTALL=ON`, relocate `libonnx*`/`lib/cmake/ONNX`/`include/onnx` into `$PREFIX` in `build.sh` | `build.sh` |
| 3 | Ship one **abi3 / version-independent** artifact instead of per-Python builds | `build.python.version_independent` + `skip: is_abi3 and not is_python_min`, host `python-abi3`, `abi3audit` test | `recipe.yaml` |
| 3a | abi3 floor must be **3.12** (nanobind hard-requires CPython ≥3.12 for stable ABI); conda-forge's `python_min` is 3.10 and `is_python_min` is a hard-coded zipped list not recomputed from `python_min` | override `python_min` **and** the `python`/`is_python_min` zip to 3.12 | `recipe/conda_build_config.yaml` |
| 4 | abi3 extension came out version-specific (`*.cpython-312*.so`) not `*.abi3.so` → `version_independent` import failed | patch `0001` must keep `Development.SABIModule` (nanobind needs `Python_SOSABI`); reuse onnx's `${python_dev_component}` | `0001-*.patch` |
| 5 | protobuf/abseil linked **PUBLIC** (leak into the public CMake interface) | patch to `PRIVATE` | `0002-*.patch` |
| 6 | Fragile dual `find_package(Python3)`+`find_package(Python)` + cross-compile branch | collapse to one `find_package(Python ... ${python_dev_component})` | `0001-*.patch` |
| 7 | **Windows** `find_package(Python ... Development.SABIModule)` failed: scikit-build-core FORCE-sets `Python_*` in its `CMakeInit.txt` but leaves `Python_LIBRARY`/`Python_SABI_LIBRARY` unset (conda's `sysconfig` `LIBDIR` empty); `CMAKE_ARGS -D` collides with the FORCE cache and corrupts version detection | inject the two libs via `--config-settings=cmake.define.Python_LIBRARY/Python_SABI_LIBRARY` (same init cache) | `build.bat` |
| 8 | Pre-existing `build.bat` typos (`CAMKE_ARGS`, `Python_EXECTUABLE`) silently dropped flags | fixed spelling | `build.bat` |

Status: **linux-64 (local) and Windows (CI) build green**; abi3 verified
(`*.abi3.so` / `*.pyd`, abi3audit clean, `cpython >=3.12`). See per-item detail
below.

---

## 1. Build backend changed: setuptools → scikit-build-core

`setup.py` is gone in 1.22. `pyproject.toml` now declares:

```toml
[build-system]
requires = ["scikit-build-core>=0.11", "protobuf==4.25.1"]
build-backend = "scikit_build_core.build"
```

**Recipe impact (done):**
- `recipe.yaml` host: `setuptools` → `scikit-build-core` (kept `pip`).
- CMake configuration is now driven from `[tool.scikit-build.cmake.define]`
  in `pyproject.toml`. Our `build.sh` `CMAKE_ARGS` are still honoured because
  scikit-build-core appends the `CMAKE_ARGS` environment variable.

## 2. C++ artifacts land inside the wheel (site-packages), not $PREFIX

This is the main behavioural change vs 1.21 and the one that broke the build.

`pyproject.toml` sets `ONNX_INSTALL = "OFF"` in `[tool.scikit-build.cmake.define]`
(the CMake option itself defaults `ON`, `CMakeLists.txt:49`). With the
setuptools backend in 1.21, `cmake --install .setuptools-cmake-build` installed
`libonnx`/`libonnx_proto`/headers/`lib/cmake/ONNX` into `$PREFIX` because the
configured `CMAKE_INSTALL_PREFIX` was `$PREFIX`.

With **scikit-build-core**, `CMAKE_INSTALL_PREFIX` is the *wheel staging
directory*, which maps to `site-packages`. So when we re-enable `ONNX_INSTALL`:

- `install(TARGETS onnx_cpp2py_export LIBRARY DESTINATION onnx)` (gated by
  `ONNX_BUILD_PYTHON`) correctly lands the extension in `site-packages/onnx/` ✓
- `install(TARGETS onnx onnx_proto ...)`, the `ONNXTargets` export and the
  headers (gated by `ONNX_INSTALL`) land in
  `site-packages/lib/` and `site-packages/include/` ✗

The leftover `cmake --install .setuptools-cmake-build` reuses the cached
staging prefix too, so it does **not** help — both the wheel build and the
manual install write into the wheel. The original recipe test
(`test -f "${PREFIX}/lib/libonnx.so"`) therefore failed.

**Recipe impact (done):** keep `-DONNX_INSTALL=ON`, drop the broken
`cmake --install` line, and in `build.sh` relocate the C++ tree out of
site-packages into the conda prefix:

```bash
sp_dir=$(${PYTHON} -c "import sysconfig; print(sysconfig.get_path('platlib'))")
mv "${sp_dir}/lib/cmake/ONNX" "${PREFIX}/lib/cmake/"
mv "${sp_dir}/lib/"libonnx*    "${PREFIX}/lib/"
mv "${sp_dir}/include/onnx"    "${PREFIX}/include/"
```

The Python extension links `onnx_core` statically (`NB_STATIC` +
`$<TARGET_OBJECTS:onnx_core>`) and does **not** `DT_NEEDED` `libonnx.so`, so
relocating the C++ lib does not affect `import onnx`.

**[upstream / packaging]** With scikit-build-core there is no in-tree way to
install the C++ targets to a location *outside* the wheel; distributors that
want a system-style `libonnx` must relocate after the fact. It would help if
onnx documented this, or offered a separate CMake-only build path for the C++
library independent of the Python wheel.

## 3. abi3 (CPython stable ABI) — single artifact across Python versions

We build onnx as a conda-forge **abi3 / version-independent** package: one
artifact compiled against `python_min` that installs on all newer CPython
versions, instead of one package per Python minor. onnx already builds the
nanobind extension with `STABLE_ABI` and tags the wheel `wheel.py-api =
"cp312"`, so this is upstream-supported — we just keep it (patch `0001` no
longer disables either) and turn on the conda-forge plumbing:

- `recipe.yaml` `build`: `skip: is_abi3 and not is_python_min` and
  `python.version_independent: ${{ is_abi3 }}`.
- `host`: add `python-abi3` (under `if: is_abi3`).
- `tests`: pin the import test to `${{ python_min }}.*` and add an `abi3audit`
  test that asserts the extension only uses limited-API symbols.

### Minimum Python version — must be 3.12, not conda-forge's `python_min` (3.10)

conda-forge's global `python_min` is **3.10**, but **nanobind's stable ABI
support requires Python ≥ 3.12** (this is exactly why onnx sets
`wheel.py-api = "cp312"`). Building the abi3 artifact against 3.10/3.11 cannot
produce a real abi3 extension. We therefore override `python_min` to `3.12`
in `recipe/conda_build_config.yaml`.

> **This is not patchable at the feedstock level — keep `python_min = 3.12`.**
> The gate lives in nanobind itself (`nanobind/cmake/nanobind-config.cmake`), a
> conda-forge dependency, not in onnx source:
>
> ```cmake
> # Stable ABI builds require CPython >= 3.12 and Python::SABIModule
> if ((Python_VERSION VERSION_LESS 3.12) OR
>     (NOT Python_INTERPRETER_ID STREQUAL "Python") OR
>     (NOT TARGET Python::SABIModule))
>   set(ARG_STABLE_ABI FALSE)
> endif()
> ```
>
> nanobind also hard-errors if scikit-build-core requests `wheel.py-api` below
> `cp312`. The 3.12 floor reflects the CPython Limited API only gaining the
> symbols nanobind needs in 3.12; forcing the flag would just fail to compile.
>
> Empirically confirmed (per request): an abi3 build against Python **3.10**
> produces a version-specific `onnx_cpp2py_export.cpython-310-*.so` (not
> `.abi3.so`), even with `Development.SABIModule` found, and the
> `version_independent` package then fails to import on any newer interpreter:
> `ImportError: cannot import name 'ONNX_ML' from 'onnx.onnx_cpp2py_export'
> (unknown location)`. The only alternatives are 3.12-floored abi3 (chosen) or
> abandoning abi3 for per-Python builds.

**[upstream]** The combination `STABLE_ABI` + `FREE_THREADED` is contradictory
on free-threaded interpreters (the limited API does not cover the free-threaded
build). nanobind silently drops STABLE_ABI there, but onnx may want to gate
`wheel.py-api`/`STABLE_ABI` off for free-threaded wheels explicitly. (For the
conda-forge abi3 build, the free-threaded variant is handled separately by
`is_freethreading`/the pinning.)

## 4. Python detection block (patch 0001) — [upstream]

`CMakeLists.txt` runs a dual `find_package(Python3 ...)` +
`find_package(Python ...)` dance requesting
`Development.Module Development.SABIModule`, with a separate cross-compiling
branch. On conda-forge (where cross-python provides the `Python` package and
sysconfig data) this is fragile. The feedstock replaces the whole block with a
single call, **reusing onnx's own `python_dev_component`**:

```cmake
find_package(Python REQUIRED COMPONENTS Interpreter ${python_dev_component})
set(ONNX_PYTHON_INTERPRETER Python::Interpreter)
```

> **Gotcha (cost me a build):** the components must include
> `Development.SABIModule`, not just `Development`. nanobind only emits a
> stable-ABI `*.abi3.so` when `Python_SOSABI` is set, which requires the
> `Development.SABIModule` component. An earlier version of this patch used a
> plain `COMPONENTS Interpreter Development`; that silently dropped SABIModule,
> nanobind fell back to a version-specific `*.cpython-312-*.so`, and the
> `version_independent` package then failed to import (`onnx.onnx_cpp2py_export`
> resolved to the `.pyi` stub directory — "unknown location"). Reusing
> `${python_dev_component}` (= `Development.Module Development.SABIModule`)
> fixes it; CMake logs `found components: Interpreter Development.Module
> Development.SABIModule` and abi3audit reports 0 violations.

Long-term it would be nicer if onnx supported a single `find_package(Python
...)` path so downstream packagers don't have to patch it.

## 5. protobuf / abseil linked PUBLIC (patch 0002) — [upstream]

`cmake/Utils.cmake:add_onnx_compile_options` links the protobuf target and the
abseil targets `PUBLIC`:

```cmake
target_link_libraries(${target} PUBLIC ${LINKED_PROTOBUF_TARGET})
...
target_link_libraries(${target} PUBLIC ${ABSL_USED_TARGET})
```

This leaks protobuf/abseil into the public link interface (they appear in
`lib/cmake/ONNX/ONNXTargets.cmake`), forcing every downstream C++ consumer to
resolve protobuf the same way onnx did, and tripping conda-forge's overlinking
expectations. The feedstock patches both to `PRIVATE`. The recipe test
asserts protobuf is absent from `ONNXTargets.cmake`.

This was already true in 1.21; still present in 1.22. Good candidate to push
upstream (PRIVATE linkage, or at least a switch).

## 6. Dependency versions expected by 1.22 (`sbom.cdx.json`)

1.22 added a new `sbom.cdx.json` + `sbom_get_dep()` CMake helper as the single
source of truth for bundled dependency versions (used only on the FetchContent
fallback path, which we never hit because we provide system libraries):

| dep        | version expected by onnx 1.22 |
|------------|-------------------------------|
| nanobind   | 2.12.0                        |
| protobuf   | 25.1 (build pin `protobuf==4.25.1`) |
| abseil-cpp | 20250127.0                    |

conda-forge currently pins `libprotobuf 6.33.5` / `libabseil 20260107` via the
`absl_grpc_proto_26Q1` migration — newer than onnx's vendored versions, which
is fine since we build against the system libraries. nanobind on conda-forge is
≥2.12, satisfying onnx's expectation.

## 7. nanobind offline lookup (patch 0001) — informational

1.22 wraps the nanobind lookup so that, when `find_package(nanobind CONFIG
QUIET)` fails *and* `FETCHCONTENT_FULLY_DISCONNECTED=ON` (which we set), it
hard-errors instead of trying to clone nanobind. We replace this with
`find_package(nanobind REQUIRED)` since conda always provides nanobind, giving a
clearer error if it is ever missing. The upstream offline guard is an
improvement over 1.21 and is acknowledged.

---

## Status

- [x] Patches re-fingerprinted for 1.22 (`0001`, `0002`) and apply cleanly.
- [x] `recipe.yaml`, `build.sh` updated for scikit-build-core + ONNX_INSTALL +
      C++ artifact relocation.
- [x] Converted to a conda-forge **abi3 (version-independent)** package built
      against `python_min` = 3.12 (overridden in `recipe/conda_build_config.yaml`).
- [x] Local build **linux-64 abi3 succeeds — all recipe tests pass**
      (`onnx-1.22.0rc1-py312h11d1ca9_0.conda`). The extension is a true
      `onnx_cpp2py_export.abi3.so`; **abi3audit reports 0 ABI violations**; run
      constraint is `cpython >=3.12` with `_python_abi3_support`. Built with
      `pixi run rattler-build build --recipe recipe -m .ci_support/linux_64_is_python_mintruepython3.12.____cpython.yaml`.
- [ ] Other linux variants (aarch64, ppc64le) not yet built locally, but use
      the same unix `build.sh` path. Cross-compiled abi3 is the main CI risk
      (the patch removed onnx's `CMAKE_CROSSCOMPILING` branch).
- [ ] osx-64 / osx-arm64 not built locally (cannot cross-build here); the
      relocation logic is platform-agnostic (`SHLIB_EXT`/`platlib` aware) so it
      should carry over. Needs CI confirmation.
- [x] Windows (`build.bat`) — **green** (Azure build 1533256): produces a true
      abi3 wheel `onnx-1.22.0rc1-cp312-abi3-win_amd64.whl` with the extension
      `onnx_cpp2py_export.pyd` (built via `nanobind-static-abi3`); abi3audit and
      all recipe tests pass.
  - Fixed two pre-existing typos that silently dropped flags:
    `CAMKE_ARGS` → `CMAKE_ARGS` (×2) and `Python_EXECTUABLE` →
    `Python_EXECUTABLE`.
  - Windows builds the **Python package only** (no `libonnx.dll`):
    `BUILD_SHARED_LIBS` stays OFF and `ONNX_INSTALL` is left at its
    scikit-build-core default (OFF), so the C++ install rules never run and no
    relocation step is needed (unlike unix). The extension links `onnx_core`
    statically.
  - The win-specific `tests:` block in `recipe.yaml` remains commented out
    because no DLL/import-lib is shipped.

### Windows: scikit-build-core's CMakeInit.txt vs. FindPython (the real fix)

CMake configure kept failing with
`Could NOT find Python (missing: Interpreter Development.Module
Development.SABIModule)`. Root cause, confirmed by dumping scikit-build-core's
generated `.setuptools-cmake-build/CMakeInit.txt`:

```cmake
set(Python_EXECUTABLE  [===[.../python.exe]===] CACHE PATH "" FORCE)
set(Python_ROOT_DIR    [===[<PREFIX>]===]       CACHE PATH "" FORCE)
set(Python_INCLUDE_DIR [===[<PREFIX>/Include]===] CACHE PATH "" FORCE)
set(SKBUILD_SABI_COMPONENT [===[Development.SABIModule]===] ...)
set(SKBUILD_SABI_VERSION   [===[3.12]===] ...)
```

scikit-build-core FORCE-sets the interpreter/root/include but — because conda's
Windows `python` has empty `sysconfig` `LIBDIR` (`get_python_library()` returns
`None`) — it **never sets `Python_LIBRARY` / `Python_SABI_LIBRARY`**. Supplying
those via `CMAKE_ARGS -D` does *not* work: it becomes a second source for the
`Python_*` artifacts that collides with the FORCE cache entries, and the
inconsistency corrupts version detection (CMake reports `found version "3"`,
parsed from `python3.lib`) so every component is rejected. Two standalone
`find_package(Python ...)` probes (run from `build.bat` with `--debug-find`)
proved the *same* artifacts resolve `3.12.13` with all components when they are
**not** fighting that cache.

Fix: inject only the two missing libraries into the *same* init cache via
scikit-build-core's own `cmake.define`, so every `Python_*` variable is
consistent:

```bat
%PYTHON% -m pip install --no-deps --ignore-installed --verbose . ^
  --config-settings=cmake.define.Python_LIBRARY=%PREFIX%\libs\python312.lib ^
  --config-settings=cmake.define.Python_SABI_LIBRARY=%PREFIX%\libs\python3.lib
```

`python312.lib` is the versioned import lib (abi3 floor is 3.12 — update if the
floor is ever raised); `python3.lib` is the stable-ABI import lib that
`Development.SABIModule` needs. Both live in `%PREFIX%\libs` (verified against
the real `python-3.12.13` win-64 package: `include/Python.h`,
`libs/python312.lib`, `libs/python3.lib` — `%PREFIX%`, not `%LIBRARY_PREFIX%`).

**[upstream]** scikit-build-core could fall back to the conda `%PREFIX%\libs`
layout when `sysconfig` `LIBDIR` is empty (Windows), instead of leaving
`Python_LIBRARY` unset; that would make abi3 nanobind extensions build on
conda-forge Windows without the `cmake.define` workaround.
