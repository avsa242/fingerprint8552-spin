{
----------------------------------------------------------------------------------------------------
    Filename:       core.con.fingerprint-8552.spin
    Description:    Fingerprint-8552-specific constants
    Author:         Jesse Burt
    Started:        May 18, 2020
    Updated:        Oct 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

' UART configuration
    UART_MODE       = %0000
    UART_MAX_BPS    = 19_200

    SOM             = $F5
    EOM             = $F5

' Structure of 8 byte command
    IDX_SOM         = 0
    IDX_CMD         = 1
    IDX_P1          = 2
    IDX_P2          = 3
    IDX_P3          = 4
    IDX_0           = 5
    IDX_CHK         = 6
    IDX_EOM         = 7

' Structure of 8 byte response (as above, but with these differences)
    IDX_Q1          = 2
    IDX_Q2          = 3
    IDX_Q3          = 4

' Structure of >8 byte command (as above, but with these differences)
    IDX_LENMSB      = 2
    IDX_LENLSB      = 3
    IDX_0M          = 4
    IDX_0L          = 5

' Checksum start and end
    CKSUM_START     = 1
    CKSUM_END       = 5

' Status bytes
    ACK_SUCCESS     = $00
    ACK_FAIL        = $01
    ACK_FULL        = $04
    ACK_NOUSER      = $05
    ACK_USER_EXIST  = $06
    ACK_FIN_EXIST   = $07
    ACK_TIMEOUT     = $08

' Command set
    ADD_FNGPRT_01   = $01
    ADD_FNGPRT_02   = $02
    ADD_FNGPRT_03   = $03
        UIDMSB      = 0     '
        UIDLSB      = 1     ' $01-$FFF
        PRIVILEGE   = 2     ' 1, 2, 3

    DEL_USER        = $04
'       UIDMSB      = 0
'       UIDLSB      = 1

    DEL_ALL_USERS   = $05

    RD_NR_USERS     = $09

    RD_USER_PRIV    = $0A
'       UIDMSB      = 0
'       UIDLSB      = 1

    COMPARE1TO1     = $0B
'       UIDMSB      = 0
'       UIDLSB      = 1

    COMPARE1TON     = $0C

    RD_IMAGES       = $23

    RD_DSP_VER      = $26

    CMP_LEVEL       = $28
    CMP_LEVEL_R     = $01
'       0           = 0
        NEWLEVEL    = 1
        RW_CMPLEV   = 2

    RD_UID_PRIVS    = $2B

    DORMANT         = $2C

    FNGPRT_ADDMODE  = $2D
'       0           = 0
        RPT         = 1
        RW_ADD      = 2
        ADDMODE_W   = 0
        ADDMODE_R   = 1

    CAPTURE_TIMEOUT = $2E
'       0           = 0
        TIMEOUT     = 1
        RW_TIMEOUT  = 2


PUB null()
' This is not a top-level object


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

