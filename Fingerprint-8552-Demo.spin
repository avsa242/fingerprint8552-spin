{
    --------------------------------------------
    Filename: FINGERPRINT-8552-Demo.spin
    Author: Jesse Burt
    Description: Demo of the Fingerprint reader SKU#8552 driver
    Copyright (c) 2021
    Started May 18, 2020
    Updated Jan 1, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    FPRINT_RX   = 9
    FPRINT_TX   = 8
    FPRINT_BL   = 10
    FPRINT_RST  = 11
' --

    PROMPT_X    = 0
    PROMPT_Y    = 20

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    fng     : "input.biometric.fingerprint-8552"

VAR

    long _usercnt, _cmplvl, _add_pol

PUB Main{} | uid, tmp, priv, finished, stmp, priv_lvl

    setup{}

    _cmplvl := 5                                ' 0..9 (lenient..strict)
    _add_pol := fng#PROHIBIT                    ' ALLOW (0), PROHIBIT (1)

    repeat
        ser.clear{}

        showsettings{}
        showhelp{}

        case ser.charin{}
            "a", "A":                           ' add a user/print
                repeat
                    ser.position(PROMPT_X, PROMPT_Y)
                    uid := _usercnt+1
                    ser.printf1(string("Privilege level for user %d? (1..3) > "), uid)
                    priv_lvl := ser.decin{}
                    ifnot lookdown(priv_lvl: 1..3)
                        quit                    ' invalid privilege level
                    ser.strln(string(" (3 scans will be required)"))
                    ' scanner requires 3 scans of a fingerprint
                    stmp := fng.addprint(uid, priv_lvl)
                    ser.newline{}
                    if stmp <> 0                ' scan failed
                        ser.str(string("Scan was unsuccessful: "))
                        case stmp               ' error code returned from
                            $01:                '   the sensor:
                                ser.str(string("Non-specific failure"))
                            $06:
                                ser.str(string("User already exists"))
                            $07:
                                ser.str(string("Fingerprint already exists"))
                            $08:
                                ser.str(string("Timeout"))
                        ser.newline{}
                        ser.str(string("Retry? (y/n)> "))
                        case ser.charin{}
                            "y", "Y": finished := FALSE
                            other: finished := TRUE
                    else                        ' scan succeeded
                        finished := TRUE
                until finished                  ' finished adding user/print
            "d":                                ' delete specific user
                ' only try if there's at least one user stored in the database
                if _usercnt
                    ser.position(PROMPT_X, PROMPT_Y)
                    uid := prompt(string("Delete user #> "))
                    fng.deleteuser(uid)
                else
                    next
            "D":                                ' delete all users
                if _usercnt
                    ser.position(PROMPT_X, PROMPT_Y)
                    ser.strln(string("delete all users"))
                    fng.deleteallusers{}
                else
                    next
            "l", "L":                           ' set print comparison level
                ser.position(PROMPT_X, PROMPT_Y)
                tmp := prompt(string("Comparison level? (0..9)> "))
                if lookdown(tmp: 0..9)
                    fng.comparisonlevel(tmp)
                    _cmplvl := tmp
            "m":                                ' check match against uid
                if _usercnt
                    ser.position(PROMPT_X, PROMPT_Y)
                    ser.printf1(string("Check fingerprint against stored uid# (1..%d) > "), _usercnt)
                    uid := ser.decin{}
                    ifnot lookdown(uid: 1.._usercnt)
                        next                    ' invalid uid
                    ser.dec(uid)
                    ser.newline{}
                    tmp := fng.printmatchesuser(uid)
                    ser.str(lookupz(||(tmp): string("Not a match"), string("Match")))
                    ser.clearline{}
                    ser.newline{}
                    pressanykey{}
            "M":                                ' find a match to any uid
                if _usercnt
                    ser.position(PROMPT_X, PROMPT_Y)
                    ser.str(string("Ready to match print to a user: "))
                    if tmp := fng.printmatch{}
                        ser.printf1(string("Matches user #%d"), tmp)
                    else
                        ser.str(string("Unrecognized"))
                    ser.newline{}
                    pressanykey{}
            "p", "P":                           ' toggle duplicate add policy
                _add_pol ^= 1
                fng.addpolicy(_add_pol)
            "q", "Q":                           ' quit
                ser.str(string("Halting"))
                quit
            "u", "U":                           ' list users and privileges
                if _usercnt
                    repeat tmp from 1 to _usercnt
                        priv := fng.userpriv(tmp)
                        ser.printf2(string("Privilege for uid %d: %d\n"), tmp, priv)
                    pressanykey{}
            other:

    repeat

PRI PressAnyKey{}

    ser.str(string("Press any key to return"))
    repeat until ser.charin{}

PRI Prompt(ptr_str): dec
' display a prompt and wait for a decimal number input
    ser.str(ptr_str)
    return ser.decin{}

PRI ShowHelp{}

    ser.position(0, 6)
    ser.strln(string("Help:"))
    ser.strln(string("a, A: Add a fingerprint to the database"))
    ser.strln(string("l, L: Change comparison level"))
    ser.strln(string("p, P: Change fingerprint add policy"))
    if _usercnt
        ser.strln(string("d: Delete a specific user from the database"))
        ser.strln(string("D: Delete all users from the database"))
        ser.strln(string("u, U: List users with their privilege levels"))
        ser.strln(string("m: Check fingerprint for match against specific user"))
        ser.strln(string("M: Check fingerprint for match against any user"))
    ser.strln(string("q, Q: Quit"))

PRI ShowSettings{}

        ser.position(0, 3)
        ser.str(string("Total user count: "))
        ser.dec(_usercnt := fng.totalusercount{})

        ser.position(50, 3)
        fng.comparisonlevel(_cmplvl)
        ser.str(string("Comparison level: "))
        ser.dec(fng.comparisonlevel(-2))

        ser.position(50, 4)
        fng.addpolicy(_add_pol)
        ser.str(string("Duplicate print add policy: "))
        _add_pol := fng.addpolicy(-2)
        ser.str(lookupz(_add_pol: string("Allow"), string("Prohibit")))

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear
    ser.strln(string("Serial terminal started"))
    fng.start(FPRINT_TX, FPRINT_RX, FPRINT_BL, FPRINT_RST)
    ser.strln(string("Fingerprint reader started"))


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
