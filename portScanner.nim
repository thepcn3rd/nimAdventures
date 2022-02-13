import std/net
import os
import strutils

#[
    Compile for Linux
    nim c -r portScanner.nim

    Compile for Windows
    nim c -d:mingw portScanner.nim

]#

# Fixed where it only displays the 1st port that is open and then displays failed for subsequent errors...
# Identified that it only likes port ranges of a thousand...

proc checkPort(ip: string, port: int): string =
    try:
        # Added a delay because of it missing ports in the scan...
        sleep(20)
        var socket = newSocket()
        socket.connect(ip, Port(port))
        var info = "\e[32mIP: " & ip & " Port: " & $port & " Successful\e[0m"
        result = info
    except:
        var info = "IP: " & ip & " Port: " & $port & " Failed"
        result = info 

proc usage(): string =
    echo "Usage: portScanner <ip address> <port>"
    echo "  portScanner 127.0.0.1 23 - Scan 1 port"
    echo "  portScanner 127.0.0.1 5-23 - Range of ports scan"

if paramCount() == 2:
    var ipInput = paramStr(1)
    var portInput = paramStr(2)
    var outputResult: string = ""
    if "-" in portInput:
        let rangePorts = portInput.split('-')
        var i = parseInt(rangePorts[0])
        while i <= parseInt(rangePorts[1]):
            #echo "Range Low: ", rangePorts[0]
            #echo "Range High: ", rangePorts[1]
            #echo "i: ", i
            try:
                outputResult = checkPort(ipInput, i)
                # Only show ports that show as open...
                if "Successful" in outputResult:
                    echo outputResult
            except:
                discard usage()
            inc i
    else:
        try:
            outputResult = checkPort(ipInput, parseInt(portInput))
            # Only show ports that are open...
            if "Successful" in outputResult:
                echo outputResult
        except:
            discard usage()
else:
    discard usage()




