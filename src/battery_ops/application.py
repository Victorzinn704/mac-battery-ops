from battery_ops.domain import PowerChange
from battery_ops.ports import BatterySensor, PowerControl


class BatteryService:
    def __init__(self, sensor: BatterySensor, control: PowerControl):
        self.sensor = sensor
        self.control = control

    def status(self):
        return self.sensor.read()

    def change_low_power(self, enabled: bool, scope: str, *, apply: bool = False):
        change = PowerChange(enabled, scope)
        if apply:
            self.control.apply(change)
        return change
