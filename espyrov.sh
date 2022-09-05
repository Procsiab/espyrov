#!/bin/bash

# Quit script on error
set -e

_SCRIPT_VERSION=1.1
_SCRIPT_YES=0
_SCRIPT_VERBOSE=0
_DEVICE=""
_FW_FILE=""
_BOARD_TYPE=""
_JUST_UPLOAD=0
_JUST_FLASH=0

# Echo when verbose flag is passed
function _fn_echoverb {
    if [[ ( _SCRIPT_VERBOSE -eq 1 ) || ( $1 -eq 3 ) ]]
    then
        case $1 in
            0)
                _level="";;
            1)
                _level="[INFO]: ";;
            2)
                _level="[WARN]: ";;
            *)
                _level="[ERR]: ";;
        esac
        echo -e "$_level$2"
    fi
}

# Warn if the script was run by user root
function _fn_check_root {
    if [ "$EUID" -eq 0 ]
        then _fn_echoverb 2 "You are not supposed to be running this script as root!"
        exit 1
    fi
}

# Flash the binary firmware
function _fn_flash_fw {
    if [ -f "$_FW_FILE" ]
    then
        if [ -e "$_DEVICE" ]
        then
            _BOARD_MODIFIER=""
            _START_ADDR="0"
            case $_BOARD_TYPE in
                ""|"8266")
                    _fn_echoverb 1 "Selecting board ESP8266"
                    _BOARD_MODIFIER="esp8266";;
                "32")
                    _fn_echoverb 1 "Selecting board ESP32"
                    _BOARD_MODIFIER="esp32"
                    _START_ADDR="0x1000";;
            esac
            _fn_echoverb 1 "Erasing device flash..."
            esptool.py --chip "$_BOARD_MODIFIER" --port "$_DEVICE" erase_flash
            _fn_echoverb 1 "Flashing new firmware..."
            esptool.py --chip "$_BOARD_MODIFIER" --port "$_DEVICE" --baud 460800 write_flash --flash_size=detect "$_START_ADDR" "$_FW_FILE"
        else
            _fn_echoverb 3 "Unable to find device '$_DEVICE'!"
            exit 1
        fi
    else
        _fn_echoverb 3 "Unable to find firmware file '$_FW_FILE'!"
        exit 1
    fi
}

# Upload the configuration files containing the credentials
function _fn_upload {
    if [ -z `hash rshell` ]
    then
        _fn_echoverb 1 "Generating WebREPL password"
        _WREPL_PW=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 9 | head -n 1`
        echo "PASS = '$_WREPL_PW'" > webrepl_cfg.py
        _fn_echoverb 1 "Uploading config files"
        sleep 5
        rshell -p $_DEVICE -b 115200 cp webrepl_cfg.py /pyboard
        rshell -p $_DEVICE -b 115200 cp boot.py /pyboard
        rm webrepl_cfg.py
    else
        _fn_echoverb 3 "Unable to find command rshell: install it through pip or your package manager!"
        exit 1
    fi
}

# Guide the user throughout the script, prompt for file problems
function _fn_main {
    _fn_echoverb 0 "******* ESP PYTHON PROVISION *******"
    _fn_echoverb 0 "Flash firmware and set up random"
    _fn_echoverb 0 "credentials large pools of ESP devices"
    _fn_echoverb 0 "(both WiFi AP and WebREPL credentials)\n"

    if [[ $_SCRIPT_YES -ne 1 ]]
    then
        read -p "This script will erase your device flash: would you like to proceed? (N/y)" -n 1 -r
    else
        REPLY="y"
    fi
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        _fn_check_root
        if [ $_JUST_UPLOAD -ne 1 ]
        then
            _fn_flash_fw
        else
            _fn_echoverb 1 "Skipping flash..."
        fi
        sleep 10
        if [ $_JUST_FLASH -ne 1 ]
        then
            _fn_upload
        else
            _fn_echoverb 1 "Skipping upload"
        fi
    fi
}

# Parse command line arguments
while [ "$#" -gt 0 ]
do
    case $1 in
        -y)
            _SCRIPT_YES=1;;
        -u)
            _JUST_UPLOAD=1;;
        -U)
            _JUST_FLASH=1;;
        -l|--log)
            _SCRIPT_VERBOSE=1;;
        -h|--help)
            echo "Usage: espyrov -d /dev/USB -f esp.bin (-y) (-l) (-u / -U) (-t 8266,32)"
            exit 0;;
        -v|--version)
            echo "Script version: $_SCRIPT_VERSION"
            exit 0;;
        -d|--device)
            _DEVICE=$2
            shift;;
        -f|--firmware)
            _FW_FILE=$2
            shift;;
        -t|--board-type)
            _BOARD_TYPE=$2
            shift;;
        *) _fn_echoverb 3 "Unknown parameter passed: $1"; exit 1;;
    esac
    shift
done
# Main function, entry point
_fn_main
