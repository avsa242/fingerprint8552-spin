{
    --------------------------------------------
    Filename: FINGERPRINT-8552-Test.spin
    Author: Jesse Burt
    Description: Test of the Fingerprint reader SKU#8552 driver
    Copyright (c) 2020
    Started May 18, 2020
    Updated May 18, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    FPRINT_RX   = 9
    FPRINT_TX   = 8
    FPRINT_BL   = 10
    FPRINT_RST  = 11
    FPRINT_BPS  = 19_200

OBJ

    cfg     : "core.con.boardcfg.parraldev"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    fng     : "input.biometric.fingerprint-8552.uart"

VAR

    byte _ser_cog, _r[8]

PUB Main | uid, tmp

    Setup

    ser.str(string("total user count: "))
    ser.dec(uid := fng.TotalUserCount)
    fng.response(@_r)
    ser.hexdump(@_r, 0, 8, 8, 0, 3)
    ser.newline
{
    ser.str(string("delete all users", ser#CR, ser#LF))
    fng.DeleteAllUsers
    fng.Response(@_r)
    ser.hexdump(@_r, 0, 8, 8, 0, 5)
    ser.newline
}

    fng.AddPolicy(0)
    ser.str(string("Add policy: "))
    ser.dec(fng.AddPolicy(-2))
    ser.newline
    ser.newline

{
    uid := 1
    fng.DeleteUser(uid)
    ser.str(string("Delete user "))
    ser.dec(uid)
    fng.Response(@_r)
    ser.hexdump(@_r, 0, 8, 8, 0, 9)
    ser.newline
}
{
    uid++
    ser.str(string("add user "))
    ser.dec(uid)
    ser.newline
    fng.AddPrint(uid, 1)
    ser.hex(fng.Status, 8)
}

{
    repeat
        ser.str(string("user matches uid "))
        ser.dec(uid)
        ser.str(string("? "))
        tmp := fng.PrintMatchesUser(2)
        fng.response(@_r)
'       ser.hexdump(@_r, 0, 8, 8, 0, 10)
        ser.dec(tmp)
        ser.newline
}

    repeat
        ser.str(string("user id of print: "))
        tmp := fng.PrintMatch
        ser.dec(tmp)
        ser.newline

    flashled(led, 100)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    fng.Start(FPRINT_TX, FPRINT_RX, FPRINT_BPS, FPRINT_BL, FPRINT_RST)
    ser.Str(string("Fingerprint reader started", ser#CR, ser#LF))

#include "lib.utility.spin"

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
