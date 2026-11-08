"""Export Hordas with the official Godot 4.7.2 Windows x64 release template.

Only the selected compressed ZIP entry is fetched using explicit HTTP ranges.
The 1.28 GB multi-platform template archive is never downloaded in full.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import urllib.request
import zipfile


ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.7.2-stable"
RELEASE_API = f"https://api.github.com/repos/godotengine/godot-builds/releases/tags/{VERSION}"
ARCHIVE_NAME = f"Godot_v{VERSION}_export_templates.tpz"
TEMPLATE_NAME = "templates/windows_release_x86_64.exe"
CACHE = ROOT / "tools" / ".cache"
TEMPLATE = CACHE / "windows_release_x86_64.exe"
BUILD = ROOT / "build"


def request(url: str, **headers: str):
    return urllib.request.urlopen(
        urllib.request.Request(url, headers={"User-Agent": "Brasafria-build", **headers}),
        timeout=60,
    )


class RemoteZip(io.RawIOBase):
    """Seekable, bounded read access to a remote ZIP via HTTPS Range."""

    def __init__(self, url: str, size: int):
        self.url = url
        self.size = size
        self.position = 0
        self.transferred = 0

    def readable(self):
        return True

    def seekable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset: int, whence: int = io.SEEK_SET):
        if whence == io.SEEK_SET:
            self.position = offset
        elif whence == io.SEEK_CUR:
            self.position += offset
        elif whence == io.SEEK_END:
            self.position = self.size + offset
        else:
            raise ValueError("Invalid seek origin")
        if self.position < 0:
            raise ValueError("Negative position")
        return self.position

    def read(self, size: int = -1):
        if size < 0:
            size = self.size - self.position
        size = min(size, self.size - self.position)
        if size <= 0:
            return b""
        # A malformed ZIP or server must never turn this into a full-archive fetch.
        if size > 128 * 1024 * 1024:
            raise RuntimeError(f"Refusing unexpectedly large range: {size}")
        end = self.position + size - 1
        with request(self.url, Range=f"bytes={self.position}-{end}") as response:
            if response.status != 206:
                raise RuntimeError("Server does not support explicit HTTP ranges")
            payload = response.read(size + 1)
        if len(payload) != size:
            raise RuntimeError(f"Incomplete range: expected {size}, got {len(payload)}")
        self.position += size
        self.transferred += size
        return payload


def ensure_template():
    CACHE.mkdir(parents=True, exist_ok=True)
    if TEMPLATE.exists() and TEMPLATE.stat().st_size > 1_000_000:
        return
    with request(RELEASE_API) as response:
        metadata = json.load(response)
    asset = next(item for item in metadata["assets"] if item["name"] == ARCHIVE_NAME)
    remote = RemoteZip(asset["browser_download_url"], asset["size"])
    with zipfile.ZipFile(remote) as archive:
        info = archive.getinfo(TEMPLATE_NAME)
        print(f"Fetching Windows template: {info.compress_size:,} compressed bytes", flush=True)
        # zipfile validates the uncompressed entry against the ZIP's CRC32.
        payload = archive.read(info)
    if payload[:2] != b"MZ":
        raise RuntimeError("Template is not a Windows executable")
    staging = TEMPLATE.with_suffix(".download")
    staging.write_bytes(payload)
    staging.replace(TEMPLATE)
    provenance = {
        "godot_version": VERSION,
        "source": asset["browser_download_url"],
        "entry": TEMPLATE_NAME,
        "entry_crc32": f"{info.CRC:08x}",
        "template_sha256": hashlib.sha256(payload).hexdigest(),
        "bytes_transferred": remote.transferred,
        "archive_bytes": asset["size"],
    }
    (CACHE / "template_provenance.json").write_text(json.dumps(provenance, indent=2), encoding="utf-8")
    print(f"Verified template CRC32; fetched {remote.transferred:,} bytes", flush=True)


def ensure_license():
    for source_name, output_name in [
        ("LICENSE.txt", "LICENSE_GODOT_4.7.2.txt"),
        ("COPYRIGHT.txt", "LICENSE_GODOT_THIRD_PARTY_4.7.2.txt"),
    ]:
        destination = ROOT / output_name
        if not destination.exists():
            url = f"https://raw.githubusercontent.com/godotengine/godot/{VERSION}/{source_name}"
            with request(url) as response:
                text = response.read().decode("utf-8")
            destination.write_text(f"Godot Engine 4.7.2\nSource: {url}\n\n{text}", encoding="utf-8")
        shutil.copy2(destination, BUILD / destination.name)
    ofl = ROOT / "assets" / "OFL.txt"
    if ofl.exists():
        shutil.copy2(ofl, BUILD / "LICENSE_FONT_OFL.txt")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, default=Path.home() / "Downloads" / "Godot_v4.7.2-stable_win64_console.exe")
    parser.add_argument("--template-only", action="store_true")
    parser.add_argument("--output", type=Path, default=BUILD / "Hordas-0.24.0" / "Hordas-0.24.0.exe")
    parser.add_argument("--dev", action="store_true", help="Export the development-only boss panel build")
    parser.add_argument("--smoke", action="store_true", help="Run exported executable headlessly for 120 frames")
    args = parser.parse_args()
    if not (ROOT / "assets/fonts/AurusenthialGothic.ttf").is_file():
        raise SystemExit("Licensed AurusenthialGothic.ttf is required locally for this export; see docs/AJUSTES_0_18.md")
    for kind in ("soldier", "orc"):
        if not (ROOT / "assets/tiny_rpg" / (kind + ".png")).is_file():
            raise SystemExit("Missing local Tiny RPG atlas: " + kind + "; run tools/tiny_rpg20.py with the official pack")
    ensure_template()
    if args.template_only:
        return
    if not args.godot.is_file():
        raise SystemExit(f"Godot not found: {args.godot}; pass --godot PATH")
    BUILD.mkdir(parents=True, exist_ok=True)
    ensure_license()
    target = ((BUILD / "Hordas-DEV-0.24.0" / "Hordas-DEV-0.24.0.exe") if args.dev and args.output == BUILD / "Hordas-0.24.0" / "Hordas-0.24.0.exe" else args.output).resolve()
    if os.name == "nt":
        probe = subprocess.run(["powershell", "-NoProfile", "-Command", "Get-CimInstance Win32_Process | Select-Object ExecutablePath,CommandLine | ConvertTo-Json -Compress"],capture_output=True,text=True,encoding="utf-8",errors="replace")
        if probe.returncode == 0:
            records = json.loads(probe.stdout or "[]")
            records = records if isinstance(records,list) else [records]
            wanted = str(target).lower()
            for record in records:
                executable = str(record.get("ExecutablePath") or "").lower()
                command = str(record.get("CommandLine") or "").lower()
                if executable == wanted or ("--main-pack" in command and wanted in command):
                    raise SystemExit("Export blocked: target is in use. Run tests against an immutable copy first.")
    target.parent.mkdir(parents=True, exist_ok=True)
    export_result = subprocess.run([
        str(args.godot), "--headless", "--path", str(ROOT),
        "--export-release", "Windows Development" if args.dev else "Windows Desktop", str(target),
    ], cwd=ROOT, capture_output=True, text=True)
    (BUILD / "export.log").write_text(export_result.stdout + export_result.stderr, encoding="utf-8")
    if export_result.returncode or not target.is_file():
        raise SystemExit(f"Export failed; see {BUILD / 'export.log'}")
    payload = target.read_bytes()
    manifest = {
        "file": target.name,
        "game_version": "0.24.0",
        "godot_version": VERSION,
        "size_bytes": len(payload),
        "sha256": hashlib.sha256(payload).hexdigest(),
        "embedded_pck": True,
        "development_tools": args.dev,
        "smoke_test": "not_run",
    }
    if args.smoke:
        outcome = subprocess.run([
            str(target), "--headless",
            "--log-file", str(BUILD / "smoke.log"), "--", "--profile-slot=release_smoke_06", "--smoke-shutdown",
        ], cwd=BUILD, capture_output=True, text=True, timeout=45)
        manifest["smoke_test"] = f"headless_120_frames_exit_{outcome.returncode}"
        (BUILD / "smoke_stdout.log").write_text(outcome.stdout + outcome.stderr, encoding="utf-8")
        smoke_log = BUILD / "smoke.log"
        log_text = smoke_log.read_text(encoding="utf-8") if smoke_log.exists() else ""
        if outcome.returncode or "ERROR:" in log_text or "ERROR:" in outcome.stderr:
            raise SystemExit(f"Exported smoke failed: {outcome.returncode}")
    (BUILD / "build_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    (target.parent / "build_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps(manifest, indent=2), flush=True)


if __name__ == "__main__":
    main()
