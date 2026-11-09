import argparse
from dataclasses import asdict
import json
import sys
from battery_ops.adapters import MacOSPower
from battery_ops.application import BatteryService


def main(argv=None):
    parser = argparse.ArgumentParser(description="Battery status and explicit power changes")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("status")
    change = commands.add_parser("low-power")
    change.add_argument("mode", choices=["on", "off"])
    change.add_argument("--scope", choices=["battery", "ac", "all"], default="battery")
    change.add_argument("--apply", action="store_true")
    args = parser.parse_args(argv)
    port = MacOSPower()
    service = BatteryService(port, port)
    try:
        if args.command == "status":
            print(json.dumps(asdict(service.status())))
        else:
            result = service.change_low_power(args.mode == "on", args.scope, apply=args.apply)
            print(json.dumps({"argv": result.argv, "applied": args.apply}))
        return 0
    except (OSError, ValueError, RuntimeError, subprocess_error()) as error:
        print(str(error), file=sys.stderr)
        return 1


def subprocess_error():
    from subprocess import TimeoutExpired
    return TimeoutExpired
