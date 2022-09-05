# This file is executed on every boot (including wake-boot from deepsleep)

import webrepl
import network

webrepl.start()

SSID = "My ESP AP"
PASS = "keepmesecret"

sta_if = network.WLAN(network.STA_IF)
sta_if.active(True)
sta_if.connect(SSID, PASS)

print("\n** Access point credentials **")
print('SSID:\t\t' + SSID)
print('password:\t' + PASS)
f = open("webrepl_cfg.py", "r")
webrepl_pass = f.read()
print("\n** WebREPL password **")
print(webrepl_pass.split()[2].replace("'", ""))
