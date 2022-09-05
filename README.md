# ESP Python Provision

This script automates the provisioning process of an ESP device with MicroPython flashing and credentials generation procedures.

You will end up with a fresh ROM on your device, along with WebREPL enabled with a random 9 char password and WiFi credentials installed: the board will turn on the STATION interface, trying to connect to the provided access point; however, the ACCESSPOINT interface will be on by default.

To configure the ESP's soft AP SSID and password you can issue the following commands from the REPL:
```python
import network

ap_if = network.WLAN(network.AP_IF)
ap_if.active(True)

ap_if.config(essid='My ESP AP')
ap_if.config(password='keepmesecret')
```

## Requirements

The script assumes to find both the binary firmware file and the block device of your serial adapter in your filesystem (you must provide both arguments to the script).

**NOTE**: You can download the binary files for MicroPython firmware from their [website](https://micropython.org/download/).

Moreover, you will need to install the following tools:
- `rshell`
- `esptool`

They can be obtained from *pip* (or from your package manager):
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -U pip
pip install -r requirements.txt
```

To run the script just issue this command, in the following flavour
```bash
./espyrov.sh -d /dev/ttyUSB0 -f ../esp8266.bin -l
```
In that way you are telling `esptool` to look for a serial adapter on /dev/ttyUSB0 and to flash the firmware called esp8266.bin (which is in the parent directory); also, you are asking the script for the maximum verbosity (-l) and finally the script defaults to provision ESP8266 boards (use the *-t 32* option to specify you are using an ESP32 device).

## The WebREPL

### Configure the WiFi credentials

At the moment to provide the access point credentials the ESP will connect to, you must edit the global variables SSID and PASS inside the file `boot.py`, before running this script.

### Accesing the WebREPL

When your ESP is connected to the same network as yours, you will be able to interact with the WebREPL: this can be done via the [https://github.com/micropython/webrepl](micropython/webrepl) tool, which basically is an HTML client for the WebREPL.

You only need to provide the IP address of your ESP on the network (the port will default to a number depending on the ESP device) and if you will be prompted to enter your REPL password, you will connect afterwards through web socket to your ESP.

## Other ways to connect

To connect to your ESP via cable, either for debugging or better convenience, you can use the *picocom* or the *screen* tools: they are available from all major software repositories, and to work they just need a block device and a baud rate (the serial communication speed, on an ESP device will default to 115200).

For example, you would connect to your device via USB using *picocom* through the following command:
```bash
picocom /dev/ttyUSB0 -b 115200
```
