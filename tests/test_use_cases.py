import unittest
from battery_ops.domain import parse_pmset
from battery_ops.application import BatteryService

class FakePort:
    def __init__(self): self.changes = []
    def read(self): return parse_pmset("Now drawing from 'Battery Power'\n -InternalBattery-0 38%; discharging; 4:00 remaining")
    def apply(self, change): self.changes.append(change)

class BatteryTests(unittest.TestCase):
    def test_parses_source_percentage_and_state(self):
        snapshot = FakePort().read()
        self.assertEqual((snapshot.percent, snapshot.source, snapshot.state), (38, "Battery Power", "discharging"))

    def test_unavailable_or_invalid_reading_is_not_reported_as_full(self):
        for text in ("", "No batteries", "Now drawing from 'AC Power'\nBattery 200%; charged;", "Now drawing from 'unknown'\nBattery 50%; charging;"):
            with self.subTest(text=text), self.assertRaises(ValueError): parse_pmset(text)

    def test_ac_charging_is_recognized(self):
        reading = parse_pmset("Now drawing from 'AC Power'\n -InternalBattery-0 82%; charging; 1:00 remaining")
        self.assertEqual(reading.state, "charging")

    def test_default_change_is_only_a_plan(self):
        port = FakePort()
        plan = BatteryService(port, port).change_low_power(True, "battery")
        self.assertEqual(plan.argv, ("pmset", "-b", "lowpowermode", "1"))
        self.assertEqual(port.changes, [])

    def test_explicit_apply_uses_injected_control(self):
        port = FakePort()
        BatteryService(port, port).change_low_power(False, "ac", apply=True)
        self.assertEqual(port.changes[0].argv, ("pmset", "-c", "lowpowermode", "0"))

    def test_invalid_scope_or_non_boolean_rejected_before_effect(self):
        port = FakePort()
        for enabled, scope in [(True,"-a; command"), ("false","battery")]:
            with self.subTest(scope=scope), self.assertRaises(ValueError):
                BatteryService(port, port).change_low_power(enabled, scope, apply=True)
        self.assertEqual(port.changes, [])
