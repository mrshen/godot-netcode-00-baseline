"""Chapter tooling, Python standard library only. No pip or PowerShell needed."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
LOCK = json.loads((ROOT / "toolchain.lock.json").read_text(encoding="utf-8"))
ARTIFACTS = ROOT / "artifacts"


def tool_roots() -> list[Path]:
    roots = [ROOT / ".tools", ROOT.parent / ".tools"]
    if os.environ.get("SYNC_DEMO_TOOLS_DIR"):
        roots.insert(0, Path(os.environ["SYNC_DEMO_TOOLS_DIR"]))
    return roots


def resolve_tool(name: str) -> Path:
    spec = LOCK[name]
    override = os.environ.get(f"NETCODE_{name.upper()}")
    local_config = ROOT / ".local-tools.json"
    if not override and local_config.exists():
        override = json.loads(local_config.read_text(encoding="utf-8")).get(name)
    if override:
        executable = Path(override).expanduser().resolve()
        if not executable.is_file():
            raise RuntimeError(f"Invalid local {name} path: {executable}")
        return executable
    for directory in tool_roots():
        executable = directory / spec["directory"] / spec["executable"]
        if executable.is_file():
            return executable
    command = shutil.which({"godot": "godot", "git": "git", "github": "gh"}[name])
    if command:
        return Path(command)
    raise FileNotFoundError(f"Missing {name}; run setup.bat first.")


def process_env() -> dict[str, str]:
    env = os.environ.copy()
    # Python discovers the existing Windows proxy settings; Git/gh otherwise
    # only see proxy environment variables. Reuse them in child processes only.
    for scheme, address in urllib.request.getproxies().items():
        if scheme in ("http", "https"):
            if f"{scheme}_proxy" not in env and f"{scheme.upper()}_PROXY" not in env:
                env[f"{scheme.upper()}_PROXY"] = address
    # gh invokes git internally. Make the located Git visible to this process only.
    try:
        git = resolve_tool("git")
        env["PATH"] = str(git.parent) + os.pathsep + env.get("PATH", "")
    except FileNotFoundError:
        pass
    return env


def execute(args: list[str | Path], *, capture: bool = False, timeout: int | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        [str(arg) for arg in args], cwd=ROOT, env=process_env(), check=True,
        text=True, encoding="utf-8", errors="replace", capture_output=capture, timeout=timeout,
    )


def godot_executable() -> Path:
    executable = resolve_tool("godot")
    version = execute([executable, "--version"], capture=True, timeout=15).stdout.strip()
    if not version.startswith(LOCK["godot"]["runtimeVersionPrefix"]):
        raise RuntimeError(f"Expected Godot {LOCK['godot']['version']}; found {version}")
    return executable


def install_tool(name: str, destination: Path) -> None:
    spec = LOCK[name]
    target = destination / spec["directory"]
    executable = target / spec["executable"]
    if executable.is_file():
        print(f"Already available: {name} {spec['version']}", flush=True)
        return
    downloads = destination / "downloads"
    downloads.mkdir(parents=True, exist_ok=True)
    archive = downloads / spec["url"].rsplit("/", 1)[1]
    if not archive.is_file():
        temporary = archive.with_suffix(archive.suffix + ".part")
        print(f"Downloading {name} {spec['version']}...", flush=True)
        request = urllib.request.Request(spec["url"], headers={"User-Agent": "Godot-Netcode-Lab"})
        with urllib.request.urlopen(request, timeout=60) as source, temporary.open("wb") as output:
            shutil.copyfileobj(source, output)
        temporary.replace(archive)
    with archive.open("rb") as source:
        digest = hashlib.file_digest(source, "sha256").hexdigest()
    if digest != spec["sha256"]:
        raise RuntimeError(f"SHA256 mismatch: {archive}. Move the archive aside and retry.")
    target.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        for entry in bundle.infolist():
            if not (target / entry.filename).resolve().is_relative_to(target.resolve()):
                raise RuntimeError("Unsafe archive member: " + entry.filename)
        bundle.extractall(target)
    if not executable.is_file():
        raise RuntimeError(f"Missing executable after extraction: {executable}")
    print(f"Ready: {executable}", flush=True)


def setup(args: argparse.Namespace) -> None:
    destination = args.destination.resolve() if args.destination else tool_roots()[0]
    for name in args.tools:
        if not args.destination:
            try:
                print(f"Using {name}: {resolve_tool(name)}", flush=True)
                continue
            except FileNotFoundError:
                pass
        install_tool(name, destination)
    install_python_dependencies()
    doctor()


def install_python_dependencies() -> None:
    requirements = ROOT / "requirements.txt"
    lines = requirements.read_text(encoding="utf-8").splitlines()
    if not any(line.strip() and not line.lstrip().startswith("#") for line in lines):
        print("requirements.txt: standard library only; no packages to install.")
        return
    try:
        execute([sys.executable, "-m", "pip", "--version"], capture=True, timeout=15)
    except subprocess.CalledProcessError as error:
        raise RuntimeError(
            "Python packages now require pip. Select a full Python 3.11+ installation "
            "with NETCODE_PYTHON, then rerun setup. The embeddable fallback has no pip."
        ) from error
    # Keep third-party dependencies inside this chapter, never in global Python.
    environment = ROOT / ".venv"
    environment_python = environment / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
    if not environment_python.is_file():
        execute([sys.executable, "-m", "venv", environment])
    execute([environment_python, "-m", "pip", "install", "-r", requirements])


def doctor() -> None:
    print(f"OS: {platform.platform()}")
    print(f"Architecture: {platform.machine()}")
    print(f"Python: {platform.python_version()} ({sys.executable})")
    print("Gameplay: GDScript, bundled with the pinned Godot version")
    for name in ("godot", "git", "github"):
        try:
            executable = resolve_tool(name)
            version = execute([executable, "--version"], capture=True, timeout=15).stdout.splitlines()[0]
            print(f"{name}: {version} ({executable})")
        except FileNotFoundError:
            print(f"{name}: not installed (run setup.bat)")
    print("No .NET SDK, pip packages, or PowerShell scripts are required.")


def godot_check(arguments: list[str | Path], log_name: str) -> str:
    result = execute([godot_executable(), "--path", ROOT, *arguments], capture=True, timeout=90)
    output = result.stdout + result.stderr
    (ARTIFACTS / log_name).write_text(output, encoding="utf-8")
    print(output.strip(), flush=True)
    # Godot may return zero even when it logs a script parse/runtime error.
    if "SCRIPT ERROR:" in output or "ERROR:" in output:
        raise RuntimeError(f"Godot reported an error; see artifacts/{log_name}")
    return output


def verify(args: argparse.Namespace) -> None:
    ARTIFACTS.mkdir(exist_ok=True)
    godot_check(["--headless", "--editor", "--import", "--quit"], "import.log")
    reports = []
    for role in ("client", "server"):
        report = ARTIFACTS / f"verification-{role}.json"
        flags = [] if role == "client" and args.rendered_client else ["--headless"]
        output = godot_check([
            *flags, "--", f"--role={role}", "--verify", f"--report={report.as_posix()}",
        ], f"verification-{role}.log")
        if f"VERIFY role={role} passed=true ticks=360 samples=6" not in output:
            raise RuntimeError(f"Missing completion marker for {role}; refusing stale reports")
        data = json.loads(report.read_text(encoding="utf-8"))
        if (not data["passed"] or data["role"] != role or data["physics_hz"] != 60
                or data["total_ticks"] != 360 or len(data["samples"]) != 6):
            raise RuntimeError(f"Incomplete or failed {role} verification")
        reports.append(data)
    for client, server in zip(reports[0]["samples"], reports[1]["samples"], strict=True):
        if client["tick"] != server["tick"]:
            raise RuntimeError("Client/server sample ticks differ")
        for key in ("position", "velocity"):
            for left, right in zip(client[key], server[key], strict=True):
                if abs(left - right) > 0.001:
                    raise RuntimeError(f"Client/server {key} differ at tick {client['tick']}")
    print("PASS: import, wall collision, sliding, normalized diagonal movement, boundaries, idle.")
    print("PASS: both runtime roles matched at 6 checkpoints / 360 ticks (tolerance 0.001).")
    print("This checks the current scenario on this machine; it does not prove cross-platform determinism.")


def main() -> int:
    if sys.version_info < (3, 11):
        raise RuntimeError("Python 3.11+ is required; tools.bat supplies pinned Python 3.14.7.")
    if len(sys.argv) > 1 and sys.argv[1] in ("git", "gh"):
        name = "github" if sys.argv[1] == "gh" else "git"
        execute([resolve_tool(name), *sys.argv[2:]])
        return 0
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    install = commands.add_parser("setup", help="Download and verify portable tools")
    install.add_argument("--destination", type=Path)
    install.add_argument("--tools", nargs="+", choices=["godot", "git", "github"], default=["godot", "git", "github"])
    commands.add_parser("doctor", help="Print the actual local tool versions")
    client = commands.add_parser("client", help="Run the local demo, or open its editor")
    client.add_argument("--editor", action="store_true")
    server = commands.add_parser("server", help="Run the shared world headless; no networking in chapter 00")
    server.add_argument("--ticks", type=int, default=0)
    checks = commands.add_parser("verify", help="Run a recorded input scenario through both roles")
    checks.add_argument("--rendered-client", action="store_true")
    screenshot = commands.add_parser("screenshot", help="Capture the actual rendered demo")
    screenshot.add_argument("--output", type=Path, default=ROOT / "docs/images/baseline.png")
    for name in ("git", "gh"):
        command = commands.add_parser(name, help=f"Invoke located {name} without changing system PATH", add_help=False)
        command.add_argument("arguments", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.command == "setup":
        setup(args)
    elif args.command == "doctor":
        doctor()
    elif args.command == "client":
        flags = ["--editor"] if args.editor else ["--", "--role=client"]
        execute([godot_executable(), "--path", ROOT, *flags])
    elif args.command == "server":
        if args.ticks < 0:
            raise RuntimeError("--ticks must be zero (run until stopped) or positive")
        execute([godot_executable(), "--headless", "--path", ROOT, "--", "--role=server", f"--ticks={args.ticks}"])
    elif args.command == "verify":
        verify(args)
    elif args.command == "screenshot":
        target = args.output.resolve()
        target.parent.mkdir(parents=True, exist_ok=True)
        execute([godot_executable(), "--path", ROOT, "--", "--role=client", f"--capture={target.as_posix()}"], timeout=30)
        print(f"Screenshot: {target}")
    else:
        tool = resolve_tool("github" if args.command == "gh" else "git")
        execute([tool, *args.arguments])
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("Stopped.", file=sys.stderr)
        sys.exit(130)
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError):
            if error.stdout:
                print(error.stdout, file=sys.stderr)
            if error.stderr:
                print(error.stderr, file=sys.stderr)
        sys.exit(1)
