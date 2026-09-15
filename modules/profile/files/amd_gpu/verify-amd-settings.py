#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Verify AMD MI300X BIOS/"Auto" settings from a booted host (T431553).

Implements the OS-side checks described in verification.md: the settings that
can be confirmed at runtime with lspci (PCIe config space), MSR reads, and
sysfs, without a reboot into BIOS. Read-only. Run as root.

Data Fabric / SMU knobs (Determinism, APBDIS, DF C-states, SOC P-state, the
socket xGMI links, and the programmed power limit) have no PCIe-config or
plain-MSR representation and are intentionally reported as "needs Redfish/BIOS".

stdlib only; Python 3.13. Tools used when present (all optional, degrade
gracefully): lspci, dmesg, ipmitool. The `msr` kernel module is loaded if
needed. No third-party packages.
"""

from __future__ import annotations

import argparse
import glob
import os
import re
import shutil
import struct
import subprocess
import sys
import time
from dataclasses import dataclass

# --- MSR addresses (AMD, 0xC001xxxx range) --------------------------------
MSR_SYSCFG = 0xC0010010          # bit 23 = MemEncryptionModeEn (SMEE / TSME)
MSR_RAPL_POWER_UNIT = 0xC0010299  # bits [12:8] = energy unit exponent
MSR_PKG_ENERGY_STAT = 0xC001029B  # 32-bit accumulating package energy counter


# ==========================================================================
# POLICY - the one place to edit what we want the machine to look like.
#
# For each setting the script can read at runtime: `desired` is our intended
# end-state (the checks flag anything else as WARN); `amd` is AMD's stated
# recommendation; `stance` is where we've landed so far. For settings we have
# not finally decided, we default `desired` to AMD's recommendation and note
# the open question in `stance`. Editing intent = edit this block only.
#
# `desired` meaning is per-setting (bool on/off, a flag char, a string, a
# count) and is interpreted by the matching check below.
# ==========================================================================
@dataclass(frozen=True)
class Policy:
    desired: object
    amd: str
    stance: str


POLICY: dict[str, Policy] = {
    "Resizable BAR": Policy(
        desired=True,  # BAR sized to full VRAM
        amd="Enabled - lets the CPU map the whole GPU VRAM",
        stance="Adopt. GPUs work without it today, so enable and confirm no regression."),
    "ACS": Policy(
        desired=False,  # ACS enforcement OFF
        amd="Disabled on non-virtualized hosts",
        stance="Adopt (disable). We already run iommu=pt, so keep GPU-to-GPU P2P open."),
    "SR-IOV": Policy(
        desired=True,  # capability present/enabled (current state)
        amd="Disabled on non-virtualized hosts",
        stance="Diverge: leave enabled/default. Unused here, negligible surface, "
               "avoids GPU re-enumeration risk."),
    "PCIe 10-bit tag": Policy(
        desired="+",
        amd="Enabled",
        stance="Adopt."),
    "PCIe ARI": Policy(
        desired="+",
        amd="Enabled",
        stance="Adopt."),
    "PCIe link (Gen5 x16)": Policy(
        desired="32GT/s x16",
        amd="Gen5 x16 host link",
        stance="Expected healthy state; a slower/narrower link is a fault to investigate."),
    "TSME": Policy(
        desired=False,  # memory encryption OFF
        amd="Disabled for performance",
        stance="Lean to disabling; the only real threat needs physical DC access. "
               "Revisit if a benchmark shows it actually costs us."),
    "SMT": Policy(
        desired=False,  # SMT OFF
        amd="Disabled for determinism/performance",
        stance="Open: also removes SMT side channels, but halves logical CPUs "
               "(384->192) - pending a k8s CPU-capacity check."),
    "Global C-states": Policy(
        desired=True,  # BIOS C-state control enabled (states present)
        amd="Global C-state control Enabled",
        stance="Keep enabled in BIOS; we disable only C2 at the OS level separately."),
    "NUMA (NPS1)": Policy(
        desired=2,  # NUMA nodes = 1 per socket
        amd="NPS1 (one NUMA node per socket) + memory interleaving",
        stance="Adopt; already satisfied (2 nodes seen)."),
}

# --- tiny output layer ----------------------------------------------------
_TTY = sys.stdout.isatty()


def _c(code: str, text: str) -> str:
    return f"\033[{code}m{text}\033[0m" if _TTY else text


STATUS_STYLE = {
    "OK": "32",     # green
    "INFO": "36",   # cyan
    "WARN": "33",   # yellow
    "SKIP": "90",   # grey
    "????": "35",   # magenta - could not determine
    "BIOS": "34",   # blue - needs Redfish/BIOS
}

# item name -> (status, one-line detail); filled as we go, printed as summary.
SUMMARY: list[tuple[str, str, str]] = []


def record(item: str, status: str, detail: str) -> None:
    SUMMARY.append((item, status, detail))


def section(title: str) -> None:
    print()
    print(_c("1", f"== {title} =="))


def line(item: str, status: str, detail: str) -> None:
    tag = _c(STATUS_STYLE.get(status, "0"), f"[{status:^4}]")
    print(f"  {tag} {item}: {detail}")
    record(item, status, detail)


def policy_line(item: str, ok: bool, detail: str, undetermined: bool = False) -> None:
    """Emit a check result against POLICY: OK if matched, WARN if diverged.

    On divergence, append AMD's recommendation and our stance so a reader who
    hasn't seen plan.md still knows what the intended value is and why.
    """
    if undetermined:
        line(item, "????", detail)
        return
    if ok:
        line(item, "OK", detail)
        return
    p = POLICY[item]
    line(item, "WARN", f"{detail}   [AMD: {p.amd}; ours: {p.stance}]")


# --- process / file helpers ----------------------------------------------
def sh(args: list[str], timeout: int = 30) -> tuple[int, str, str]:
    """Run a command, never raise. Returns (rc, stdout, stderr)."""
    try:
        p = subprocess.run(
            args, capture_output=True, text=True, timeout=timeout, check=False
        )
        return p.returncode, p.stdout, p.stderr
    except FileNotFoundError:
        return 127, "", "not found"
    except subprocess.TimeoutExpired:
        return 124, "", "timeout"


def have(tool: str) -> bool:
    return shutil.which(tool) is not None


def read_text(path: str) -> str | None:
    try:
        with open(path, "r") as fh:
            return fh.read()
    except OSError:
        return None


# --- MSR access via /dev/cpu/N/msr ---------------------------------------
_msr_ready = False


def ensure_msr() -> bool:
    global _msr_ready
    if _msr_ready:
        return True
    if not glob.glob("/dev/cpu/*/msr"):
        sh(["modprobe", "msr"])
    _msr_ready = bool(glob.glob("/dev/cpu/0/msr"))
    return _msr_ready


def read_msr(cpu: int, addr: int) -> int | None:
    path = f"/dev/cpu/{cpu}/msr"
    try:
        fd = os.open(path, os.O_RDONLY)
    except OSError:
        return None
    try:
        data = os.pread(fd, 8, addr)
    except OSError:
        return None
    finally:
        os.close(fd)
    return struct.unpack("<Q", data)[0] if len(data) == 8 else None


# --- lspci parsing --------------------------------------------------------
BDF_RE = re.compile(r"^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.\d")
HEAD_RE = re.compile(
    r"^(?P<bdf>\S+)\s+(?P<cls>.*?)\s+\[(?P<clscode>[0-9a-f]{4})\]:\s+"
    r"(?P<desc>.*?)\s+\[(?P<ven>[0-9a-f]{4}):(?P<dev>[0-9a-f]{4})\]"
)


class PciDev:
    def __init__(self, head: str):
        self.head = head
        self.lines: list[str] = []
        m = HEAD_RE.match(head)
        self.bdf = head.split()[0]
        self.clscode = m.group("clscode") if m else ""
        self.desc = m.group("desc") if m else head
        self.ven = m.group("ven") if m else ""
        self.dev = m.group("dev") if m else ""

    @property
    def text(self) -> str:
        return "\n".join(self.lines)

    def find(self, prefix: str) -> str | None:
        for ln in self.lines:
            if ln.strip().startswith(prefix):
                return ln.strip()
        return None

    def is_amd_gpu(self) -> bool:
        # vendor AMD/ATI + a graphics/3D/processing-accelerator class.
        return self.ven == "1002" and (
            self.clscode.startswith("03") or self.clscode == "1200"
        )


def load_pci() -> list[PciDev] | None:
    if not have("lspci"):
        return None
    rc, out, _ = sh(["lspci", "-Dvvvnn"])
    if rc != 0 or not out:
        return None
    devs: list[PciDev] = []
    cur: PciDev | None = None
    for ln in out.splitlines():
        if BDF_RE.match(ln):
            cur = PciDev(ln)
            devs.append(cur)
        elif cur is not None:
            cur.lines.append(ln)
    return devs


def upstream_bridges(devs: list[PciDev]) -> dict[str, PciDev]:
    """Map each bus number to the bridge whose secondary bus is that number."""
    by_secondary: dict[str, PciDev] = {}
    for d in devs:
        m = re.search(r"secondary=([0-9a-fA-F]+)", d.find("Bus:") or "")
        if m:
            by_secondary[m.group(1).lower()] = d
    return by_secondary


def flag(text: str | None, name: str) -> str | None:
    """Return '+'/'-' for a `Name+`/`Name-` flag in an lspci line."""
    if not text:
        return None
    m = re.search(rf"{re.escape(name)}([+-])", text)
    return m.group(1) if m else None


def aggregate(pairs: dict[str, str]) -> str:
    """Collapse a per-BDF value map into 'N/M funcs: value' or list outliers."""
    if not pairs:
        return "no matching functions"
    total = len(pairs)
    vals: dict[str, int] = {}
    for v in pairs.values():
        vals[v] = vals.get(v, 0) + 1
    if len(vals) == 1:
        only = next(iter(vals))
        return f"{total}/{total} functions: {only}"
    parts = [f"{cnt}x {val}" for val, cnt in sorted(vals.items())]
    return f"{total} functions, mixed: " + ", ".join(parts)


# --- size helpers (Resizable BAR) ----------------------------------------
_UNIT = {"B": 1, "KB": 1 << 10, "MB": 1 << 20, "GB": 1 << 30, "TB": 1 << 40}


def to_bytes(tok: str) -> int | None:
    m = re.match(r"(\d+)\s*([KMGT]?B)$", tok.strip())
    if not m:
        return None
    return int(m.group(1)) * _UNIT[m.group(2)]


# ==========================================================================
# Checks
# ==========================================================================
def check_pci(devs: list[PciDev] | None) -> None:
    section("PCIe config space (lspci)")
    if devs is None:
        for it in ("Resizable BAR", "ACS", "SR-IOV", "PCIe 10-bit tag",
                   "PCIe ARI", "PCIe link (Gen5 x16)"):
            line(it, "SKIP", "lspci unavailable or returned nothing")
        return

    gpus = [d for d in devs if d.is_amd_gpu()]
    if not gpus:
        line("AMD GPU discovery", "WARN",
             "no AMD (1002) GPU/accelerator functions found via lspci")

    # Resizable BAR: current vs max supported size, per GPU function.
    rebar: dict[str, str] = {}
    for d in gpus:
        cur = sup = None
        for ln in d.lines:
            m = re.search(r"current size (\S+), supported:?\s*(.*)$", ln)
            if m:
                cur = to_bytes(m.group(1))
                toks = [to_bytes(t) for t in m.group(2).split()]
                toks = [t for t in toks if t]
                sup = max(toks) if toks else None
                break
        if cur is None:
            rebar[d.bdf] = "no Resizable BAR capability"
        elif sup and cur >= sup:
            rebar[d.bdf] = f"ENABLED (current {cur >> 30}GB == max)"
        else:
            cg = cur >> 20 if cur < (1 << 30) else cur >> 30
            unit = "MB" if cur < (1 << 30) else "GB"
            rebar[d.bdf] = f"not full (current {cg}{unit} < max)"
    if gpus:
        ok = all("ENABLED" in v for v in rebar.values())
        policy_line("Resizable BAR", ok, aggregate(rebar))

    # ACS: enforcement lives on bridges/switch downstream ports.
    acs_ports: dict[str, str] = {}
    for d in devs:
        ctl = d.find("ACSCtl:")
        if ctl is None:
            continue
        enforced = "+" in ctl.split("ACSCtl:", 1)[1]
        acs_ports[d.bdf] = "enforcing" if enforced else "off (P2P allowed)"
    if acs_ports:
        n_on = sum(1 for v in acs_ports.values() if v == "enforcing")
        detail = (f"{len(acs_ports)} ports with ACS cap; "
                  f"{n_on} enforcing, {len(acs_ports) - n_on} off")
        policy_line("ACS", n_on == 0, detail)
    else:
        policy_line("ACS", False, "no ACS-capable bridges expose ACSCtl",
                    undetermined=True)

    # SR-IOV: capability present on GPU physical functions?
    sriov: dict[str, str] = {}
    for d in gpus:
        if "Single Root I/O Virtualization" in d.text:
            en = flag(d.find("IOVCtl:"), "Enable")
            sriov[d.bdf] = f"cap present (IOVCtl Enable{en or '?'})"
        else:
            sriov[d.bdf] = "no SR-IOV capability"
    if gpus:
        ok = all("cap present" in val for val in sriov.values())
        policy_line("SR-IOV", ok, aggregate(sriov))

    # 10-bit tag: per-Function requester-enable bit (DevCtl2), read from the
    # GPU function itself.
    tbt: dict[str, str] = {}
    for d in gpus:
        t = flag(d.find("DevCtl2:"), "10BitTagReq")
        tbt[d.bdf] = f"10BitTagReq{t}" if t else "no DevCtl2/10BitTag"
    if gpus:
        policy_line("PCIe 10-bit tag",
                    all(val.endswith("+") for val in tbt.values()), aggregate(tbt))

    # ARI Forwarding Enable is a Downstream Port bit (PCIe spec); it's
    # reserved/hardwired-0 on endpoints, so read it from each GPU's upstream
    # bridge instead of the GPU function's own DevCtl2 (which would always
    # read ARIFwd- and false-positive a WARN).
    bridges = upstream_bridges(devs)
    ari: dict[str, str] = {}
    for d in gpus:
        bus = d.bdf.split(":")[1].lower()
        bridge = bridges.get(bus)
        if bridge is None:
            ari[d.bdf] = "no upstream bridge found"
            continue
        a = flag(bridge.find("DevCtl2:"), "ARIFwd")
        ari[d.bdf] = f"ARIFwd{a}" if a else "no DevCtl2/ARIFwd on upstream bridge"
    if gpus:
        policy_line("PCIe ARI",
                    all(val.endswith("+") for val in ari.values()), aggregate(ari))

    # PCIe uplink speed/width (NOT the BIOS xGMI rows).
    link: dict[str, str] = {}
    for d in gpus:
        sta = d.find("LnkSta:")
        if sta:
            sp = re.search(r"Speed ([\d.]+GT/s)", sta)
            wd = re.search(r"Width (x\d+)", sta)
            link[d.bdf] = f"{sp.group(1) if sp else '?'} {wd.group(1) if wd else '?'}"
        else:
            link[d.bdf] = "no LnkSta"
    if gpus:
        ok = all("32GT/s x16" in v for v in link.values())
        policy_line("PCIe link (Gen5 x16)", ok,
                    aggregate(link) + "  [host PCIe link, not socket xGMI]")


def check_tsme() -> None:
    section("Memory encryption / TSME (MSR + dmesg)")
    if not ensure_msr():
        line("TSME", "SKIP",
             "/dev/cpu/*/msr unavailable (msr module could not load)")
    else:
        raw = read_msr(0, MSR_SYSCFG)
        if raw is None:
            policy_line("TSME", False, "could not read MSR 0xC0010010",
                        undetermined=True)
        else:
            on = bool((raw >> 23) & 1)
            detail = (f"SYSCFG bit 23 = {int(on)}: memory encryption "
                      f"{'ACTIVE (TSME/SME on)' if on else 'OFF'}")
            # desired = False (off) -> OK when encryption is off.
            policy_line("TSME", not on, detail)

    # Cross-checks.
    rc, out, _ = sh(["dmesg"])
    hits = [ln.strip() for ln in out.splitlines()
            if "memory encryption" in ln.lower()] if rc == 0 else []
    line("dmesg encryption line", "INFO",
         hits[0] if hits else "no 'Memory Encryption' line in dmesg")
    cpuinfo = read_text("/proc/cpuinfo") or ""
    has_sme = bool(re.search(r"\bsme\b", cpuinfo))
    line("/proc/cpuinfo 'sme' flag", "INFO",
         "present (SME active/exposed)" if has_sme else "absent")


def check_smt() -> None:
    section("SMT (sysfs / lscpu)")
    active = read_text("/sys/devices/system/cpu/smt/active")
    control = read_text("/sys/devices/system/cpu/smt/control")
    # desired = False (SMT off) -> OK when SMT is off.
    if active is not None:
        on = active.strip() == "1"
        policy_line("SMT", not on,
                    f"{'ON' if on else 'OFF'} (smt/active={active.strip()}, "
                    f"control={(control or '').strip() or '?'})")
    elif have("lscpu"):
        _, out, _ = sh(["lscpu"])
        m = re.search(r"Thread\(s\) per core:\s*(\d+)", out)
        tpc = m.group(1) if m else "?"
        policy_line("SMT", tpc != "2",
                    f"{'ON' if tpc == '2' else 'OFF'} (threads per core={tpc})")
    else:
        policy_line("SMT", False, "no sysfs smt node and no lscpu",
                    undetermined=True)


def check_cstates() -> None:
    section("Global C-state control (cpuidle sysfs)")
    states = sorted(glob.glob("/sys/devices/system/cpu/cpu0/cpuidle/state*"))
    if not states:
        policy_line("Global C-states", False,
                    "no cpuidle states exposed (idle driver off?)",
                    undetermined=True)
        return
    names = []
    for s in states:
        nm = (read_text(os.path.join(s, "name")) or "?").strip()
        dis = (read_text(os.path.join(s, "disable")) or "0").strip()
        names.append(nm + ("(disabled)" if dis == "1" else ""))
    deep = [n for n in names if not n.startswith("POLL") and not n.startswith("C1")]
    detail = ", ".join(names)
    detail += "  =>  deep C-states present" if deep else "  =>  only C1/POLL (deep C-states off)"
    # desired = True (BIOS C-state control on -> deep states exist).
    policy_line("Global C-states", bool(deep), detail)


def check_numa() -> None:
    section("Memory interleaving / NUMA (sysfs, indirect)")
    nodes = sorted(glob.glob("/sys/devices/system/node/node[0-9]*"))
    sizes = []
    for n in nodes:
        mi = read_text(os.path.join(n, "meminfo")) or ""
        m = re.search(r"MemTotal:\s*(\d+)\s*kB", mi)
        if m:
            sizes.append(int(m.group(1)) // (1024 * 1024))  # GiB
    # desired = 2 nodes (NPS1). Interleaving itself is inferred, not a direct bit.
    policy_line("NUMA (NPS1)", len(nodes) == POLICY["NUMA (NPS1)"].desired,
                f"{len(nodes)} node(s), sizes(GiB)={sizes} "
                f"(2 nodes == NPS1; interleaving inferred, not a direct bit)")


def check_power(interval: float) -> None:
    section("Package power draw (RAPL MSR, indirect cTDP check)")
    if interval <= 0:
        line("Package power", "SKIP", "power sampling disabled (--power-interval 0)")
        return
    if not ensure_msr():
        line("Package power", "SKIP", "/dev/cpu/*/msr unavailable")
        return
    unit_raw = read_msr(0, MSR_RAPL_POWER_UNIT)
    if unit_raw is None:
        line("Package power", "????", "could not read RAPL power unit MSR")
        return
    esu = (unit_raw >> 8) & 0x1F
    energy_unit = 0.5 ** esu  # Joules per tick

    # One CPU per NUMA node approximates one CPU per package on these hosts.
    cpus = []
    for cl in sorted(glob.glob("/sys/devices/system/node/node[0-9]*/cpulist")):
        txt = read_text(cl) or ""
        first = re.match(r"(\d+)", txt.strip())
        if first:
            cpus.append(int(first.group(1)))
    if not cpus:
        cpus = [0]

    e0 = {c: read_msr(c, MSR_PKG_ENERGY_STAT) for c in cpus}
    time.sleep(interval)
    e1 = {c: read_msr(c, MSR_PKG_ENERGY_STAT) for c in cpus}
    for c in cpus:
        a, b = e0[c], e1[c]
        if a is None or b is None:
            line(f"Package power (cpu{c})", "????", "energy MSR unreadable")
            continue
        delta = (b - a) & 0xFFFFFFFF  # 32-bit counter wrap
        watts = delta * energy_unit / interval
        line(f"Package power (cpu{c})", "INFO",
             f"~{watts:.0f} W over {interval:.1f}s (draw only; 400 W is the "
             f"cTDP limit, not read here)")


def check_hsmp_note() -> None:
    section("EPYC power limit / determinism (ESMI/HSMP - optional)")
    loaded = os.path.exists("/dev/hsmp") or bool(
        glob.glob("/sys/devices/platform/*hsmp*"))
    if not loaded:
        sh(["modprobe", "amd_hsmp"])
        loaded = os.path.exists("/dev/hsmp") or bool(
            glob.glob("/sys/devices/platform/*hsmp*"))
    line("amd_hsmp interface", "INFO" if loaded else "SKIP",
         "present - use AMD ESMI (e_smi) tool to read the programmed PPT/cTDP "
         "limit" if loaded else
         "not available; read the power limit via Redfish/BIOS instead")


def check_ipmi(enable: bool) -> None:
    section("BMC power reading (ipmitool - optional cross-check)")
    if not enable:
        line("BMC power", "SKIP", "not requested (pass --ipmi to attempt)")
        return
    if not have("ipmitool"):
        line("BMC power", "SKIP", "ipmitool not installed")
        return
    rc, out, _ = sh(["ipmitool", "dcmi", "power", "reading"], timeout=20)
    if rc == 0 and out:
        m = re.search(r"Instantaneous power reading:\s*(\d+)\s*Watts", out)
        line("BMC power (DCMI)", "INFO",
             f"{m.group(1)} W (whole node)" if m else out.strip().splitlines()[0])
    else:
        line("BMC power (DCMI)", "SKIP",
             "DCMI reading unavailable (BMC may not support it)")


def check_residual() -> None:
    section("Not OS-verifiable - needs Redfish/BIOS")
    for it, why in [
        ("Determinism control", "SMU domain; no PCIe/MSR read path"),
        ("APBDIS", "Data Fabric setting; no OS read path"),
        ("DF C-states", "Data Fabric setting; no OS read path"),
        ("Fixed SOC P-state (P0)", "SoC/uncore P-state; SMU domain"),
        ("xGMI link width / max speed", "socket Infinity Fabric, not PCIe/MSR "
         "(GPU-GPU xGMI: use rocm-smi --showtopo)"),
        ("cTDP / package power LIMIT", "programmed cap needs ESMI/HSMP or Redfish"),
    ]:
        line(it, "BIOS", why)


def print_summary() -> None:
    section("Summary")
    width = max(len(i) for i, _, _ in SUMMARY)
    for item, status, _detail in SUMMARY:
        tag = _c(STATUS_STYLE.get(status, "0"), f"{status:^4}")
        print(f"  {item.ljust(width)}  {tag}")
    print()
    print("Legend: OK=matches desired policy  WARN=diverges from desired "
          "policy (see POLICY block at top)  INFO=read-only context  "
          "????=read failed  SKIP=tool/cap absent  BIOS=needs Redfish/BIOS")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--power-interval", type=float, default=1.0,
                    help="seconds to sample RAPL energy for package power "
                         "(0 disables sampling)")
    ap.add_argument("--ipmi", action="store_true",
                    help="also attempt a BMC power reading via ipmitool")
    args = ap.parse_args()

    if os.geteuid() != 0:
        print("This script must be run as root (MSR + extended PCI config "
              "space + dmesg).", file=sys.stderr)
        return 2

    print(_c("1", "AMD MI300X setting verification (T431553) - host: "
             + os.uname().nodename))

    devs = load_pci()
    check_pci(devs)
    check_tsme()
    check_smt()
    check_cstates()
    check_numa()
    check_power(args.power_interval)
    check_hsmp_note()
    check_ipmi(args.ipmi)
    check_residual()
    print_summary()
    return 0


if __name__ == "__main__":
    sys.exit(main())
