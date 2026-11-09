from typing import Protocol
from battery_ops.domain import BatterySnapshot, PowerChange


class BatterySensor(Protocol):
    def read(self) -> BatterySnapshot: ...


class PowerControl(Protocol):
    def apply(self, change: PowerChange) -> None: ...
