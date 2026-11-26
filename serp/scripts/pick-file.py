#!/usr/bin/env python3
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

PORTAL = "org.freedesktop.portal.Desktop"
PORTAL_PATH = "/org/freedesktop/portal/desktop"


def main():
    title = sys.argv[1] if len(sys.argv) > 1 else "Open"
    filter_name = sys.argv[2] if len(sys.argv) > 2 else "Files"
    patterns = sys.argv[3:] or ["*"]

    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    token = "serp%d" % GLib.random_int()
    sender = bus.get_unique_name()[1:].replace(".", "_")
    request_path = "%s/request/%s/%s" % (PORTAL_PATH, sender, token)

    loop = GLib.MainLoop()
    result = {"code": 2, "uris": []}

    def on_response(_conn, _sender, _path, _iface, _signal, params, _data):
        code, results = params.unpack()
        result["code"] = code
        result["uris"] = results.get("uris", [])
        loop.quit()

    def on_owner_changed(_conn, _sender, _path, _iface, _signal, params, _data):
        name, _old, new = params.unpack()
        if name == PORTAL and not new:
            loop.quit()

    bus.signal_subscribe(PORTAL, "org.freedesktop.portal.Request", "Response", request_path,
                         None, Gio.DBusSignalFlags.NONE, on_response, None)
    bus.signal_subscribe("org.freedesktop.DBus", "org.freedesktop.DBus", "NameOwnerChanged",
                         "/org/freedesktop/DBus", PORTAL, Gio.DBusSignalFlags.NONE, on_owner_changed, None)

    options = {
        "handle_token": GLib.Variant("s", token),
        "modal": GLib.Variant("b", True),
        "filters": GLib.Variant("a(sa(us))", [(filter_name, [(0, p) for p in patterns])]),
    }
    bus.call_sync(PORTAL, PORTAL_PATH, "org.freedesktop.portal.FileChooser", "OpenFile",
                  GLib.Variant("(ssa{sv})", ("", title, options)), GLib.VariantType("(o)"),
                  Gio.DBusCallFlags.NONE, -1, None)
    loop.run()

    if result["code"] == 0 and result["uris"]:
        path = Gio.File.new_for_uri(result["uris"][0]).get_path()
        if path:
            print(path)
            return 0
    return 1 if result["code"] == 1 else 2


if __name__ == "__main__":
    sys.exit(main())
