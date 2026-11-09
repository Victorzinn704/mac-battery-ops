from dataclasses import dataclass
import re


@dataclass(frozen=True)
class BatterySnapshot:
    percent: int
    source: str
    state: str


def parse_pmset(text: str) -> BatterySnapshot:
    source = re.search(r"Now drawing from '(AC Power|Battery Power)'", text)
    reading = re.search(r"\b(\d+)%;\s*([^;\n]+)", text)
    if not source or not reading or not 0 <= int(reading[1]) <= 100:
        raise ValueError("Battery information unavailable or invalid")
    return BatterySnapshot(int(reading[1]), source[1], reading[2].strip())


@dataclass(frozen=True)
class PowerChange:
    enabled: bool
    scope: str

    def __post_init__(self):
        if type(self.enabled) is not bool or self.scope not in {"battery", "ac", "all"}:
            raise ValueError("Use a boolean and scope battery, ac or all")

    @property
    def argv(self) -> tuple[str, ...]:
        flag = {"battery": "-b", "ac": "-c", "all": "-a"}[self.scope]
        return ("pmset", flag, "lowpowermode", "1" if self.enabled else "0")
