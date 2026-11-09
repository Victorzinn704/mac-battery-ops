import subprocess
from battery_ops.domain import parse_pmset


class MacOSPower:
    def __init__(self, run=subprocess.run):
        self.run = run

    def read(self):
        result = self.run(["pmset", "-g", "batt"], capture_output=True, text=True, timeout=10)
        if result.returncode:
            raise RuntimeError("Could not read macOS battery information")
        return parse_pmset(result.stdout)

    def apply(self, change):
        result = self.run(list(change.argv), capture_output=True, text=True, timeout=10)
        if result.returncode:
            raise RuntimeError("Power change failed; check permissions locally")
