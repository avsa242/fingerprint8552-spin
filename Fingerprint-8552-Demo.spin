{
----------------------------------------------------------------------------------------------------
    Filename:       Fingerprint-8552-Demo.spin
    Description:    Demo of the Fingerprint reader SKU#8552 driver
    Author:         Jesse Burt
    Started:        May 18, 2020
    Updated:        Oct 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


    PROMPT_X    = 0
    PROMPT_Y    = 20


OBJ

    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    reader: "input.biometric.fingerprint-8552" | RX_PIN=0, TX_PIN=1, BL_PIN=2, RST_PIN=3


VAR

    long _usercnt, _cmplvl, _add_pol


PUB main() | uid, tmp, priv, finished, stmp, priv_lvl

    setup()

    _cmplvl := 5                                ' 0..9 (lenient..strict)
    _add_pol := reader.PROHIBIT                 ' ALLOW (0), PROHIBIT (1)

    repeat
        ser.clear()
        show_settings()
        show_help()

        case ser.getchar()
            "a", "A":                           ' add a user/print
                repeat
                    ser.pos_xy(PROMPT_X, PROMPT_Y)
                    uid := _usercnt+1
                    ser.printf(@"Privilege level for user %d? (1..3) > ", uid)
                    priv_lvl := ser.getdec()
                    ifnot ( lookdown(priv_lvl: 1..3) )
                        quit                    ' invalid privilege level
                    ser.strln(@" (3 scans will be required)")
                    ' scanner requires 3 scans of a fingerprint
                    stmp := reader.add_print(uid, priv_lvl)
                    ser.newline()
                    if ( stmp <> 0 )            ' scan failed
                        ser.str(@"Scan was unsuccessful: ")
                        case stmp               ' error code returned from
                            $01:                '   the sensor:
                                ser.str(@"Non-specific failure")
                            $06:
                                ser.str(@"User already exists")
                            $07:
                                ser.str(@"Fingerprint already exists")
                            $08:
                                ser.str(@"Timeout")
                        ser.newline()
                        ser.str(@"Retry? (y/n)> ")
                        case ser.getchar()
                            "y", "Y": finished := FALSE
                            other: finished := TRUE
                    else                        ' scan succeeded
                        finished := TRUE
                until finished                  ' finished adding user/print
            "d":                                ' delete specific user
                ' only try if there's at least one user stored in the database
                if ( _usercnt )
                    ser.pos_xy(PROMPT_X, PROMPT_Y)
                    uid := prompt(@"Delete user #> ")
                    reader.delete_user(uid)
                else
                    next
            "D":                                ' delete all users
                if ( _usercnt )
                    ser.pos_xy(PROMPT_X, PROMPT_Y)
                    ser.strln(@"delete all users")
                    reader.delete_all_users()
                else
                    next
            "l", "L":                           ' set print comparison level
                ser.pos_xy(PROMPT_X, PROMPT_Y)
                tmp := prompt(@"Comparison level? (0..9)> ")
                if ( lookdown(tmp: 0..9) )
                    reader.comparison_level(tmp)
                    _cmplvl := tmp
            "m":                                ' check match against uid
                if ( _usercnt )
                    ser.pos_xy(PROMPT_X, PROMPT_Y)
                    ser.printf(@"Check fingerprint against stored uid# (1..%d) > ", _usercnt)
                    uid := ser.getdec()
                    if ( (uid < 1) or (uid > _usercnt) )
                        next                    ' invalid uid
                    ser.dec(uid)
                    ser.newline()
                    tmp := reader.print_matches_user(uid)
                    ser.str(lookupz(||(tmp): @"Not a match", @"Match" ))
                    ser.clear_line()
                    ser.newline()
                    press_any_key()
            "M":                                ' find a match to any uid
                if ( _usercnt )
                    ser.pos_xy(PROMPT_X, PROMPT_Y)
                    ser.str(@"Ready to match print to a user: ")
                    if ( tmp := reader.print_match() )
                        ser.printf(@"Matches user #%d", tmp)
                    else
                        ser.str(@"Unrecognized")
                    ser.newline()
                    press_any_key()
            "p", "P":                           ' toggle duplicate add policy
                _add_pol ^= 1
                reader.add_policy(_add_pol)
            "q", "Q":                           ' quit
                ser.str(@"Halting")
                quit
            "u", "U":                           ' list users and privileges
                if ( _usercnt )
                    repeat tmp from 1 to _usercnt
                        priv := reader.user_priv(tmp)
                        ser.printf(@"Privilege for uid %d: %d\n", tmp, priv)
                    press_any_key()
            other:

    repeat


PRI press_any_key()
' Show a message on the terminal and wait for a keypress
    ser.str(@"Press any key to return")
    repeat
    until ser.getchar()


PRI prompt(ptr_str): dec
' display a prompt and wait for a decimal number input
    ser.str(ptr_str)
    return ser.getdec()


PRI show_help()

    ser.pos_xy(0, 6)
    ser.strln(@"Help:")
    ser.strln(@"a, A: Add a fingerprint to the database")
    ser.strln(@"l, L: Change comparison level")
    ser.strln(@"p, P: Change fingerprint add policy")
    if ( _usercnt )
        ser.strln(@"d: Delete a specific user from the database")
        ser.strln(@"D: Delete all users from the database")
        ser.strln(@"u, U: List users with their privilege levels")
        ser.strln(@"m: Check fingerprint for match against specific user")
        ser.strln(@"M: Check fingerprint for match against any user")
    ser.strln(@"q, Q: Quit")


PRI show_settings()

    ser.pos_xy(0, 3)
    ser.str(@"Total user count: ")
    ser.dec(_usercnt := reader.total_user_count())

    ser.pos_xy(50, 3)
    reader.comparison_level(_cmplvl)
    ser.str(@"Comparison level: ")
    ser.dec(reader.comparison_level())

    ser.pos_xy(50, 4)
    reader.add_policy(_add_pol)
    ser.str(@"Duplicate print add policy: ")
    _add_pol := reader.add_policy()
    ser.str(lookupz(_add_pol: @"Allow", @"Prohibit") )


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear
    ser.strln(@"Serial terminal started")

    reader.start()
    ser.strln(@"Fingerprint reader started")


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

