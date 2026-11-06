"""Run repository Lua regressions with exact Lua 5.1 (test-only lupa dependency).

Usage: python tools/ui/run_checks.py [addon directory]
Install test dependency: python -m pip install lupa
No WoW API, renderer, secure execution or client validation is implied.
"""
from pathlib import Path
import sys
from lupa.lua51 import LuaRuntime

repository = Path(__file__).resolve().parents[2]
addon = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else repository / "ZygorGuidesViewerRM"
compiler = LuaRuntime()
check = compiler.eval("function(s,n) local f,e=loadstring(s,n); assert(f,e) end")
# Parse all changed production files, plus the rest of the addon's own Lua.
# Libraries ship upstream Lua dialect quirks; leave their validation to upstream.
syntax_files = list(addon.glob("*.lua"))
for path in syntax_files:
    check(path.read_text(encoding="utf-8-sig"), str(path))
print(f"PASS: {len(syntax_files)} top-level addon files parse under Lua 5.1", flush=True)
failures = []
tests = sorted((repository / "tools").rglob("test_*.lua"))
for path in tests:
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.globals().arg = runtime.table_from({1: addon.as_posix()})
    try:
        runtime.execute(path.read_text(encoding="utf-8-sig"))
        print("PASS:", path.relative_to(repository), flush=True)
    except Exception as error:
        failures.append(path)
        print("FAIL:", path.relative_to(repository), error, flush=True)
if failures:
    raise SystemExit(f"{len(failures)} Lua test script(s) failed")
print(f"PASS: all {len(tests)} Lua test scripts", flush=True)
