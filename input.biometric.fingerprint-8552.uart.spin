{
    --------------------------------------------
    Filename: input.biometric.fingerprint-8552.uart.spin
    Author: Jesse Burt
    Description: Driver for Waveshare UART fingerprint reader SKU#8552
    Copyright (c) 2020
    Started May 18, 2020
    Updated May 18, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON


VAR

    byte    _response[8]
    byte    _BL, _RST

OBJ

    uart    : "com.serial"
    core    : "core.con.fingerprint-8552"
    io      : "io"
    time    : "time"

PUB Null
''This is not a top-level object

PUB Start(UART_RX, UART_TX, UART_BPS, BL, RST): okay

    if lookdown(UART_RX: 0..31) and lookdown(UART_TX: 0..31)    ' BL, RST optional
        if okay := uart.StartRXTX(UART_RX, UART_TX, core#UART_MODE, UART_BPS)
            time.MSleep (1)                                     ' Device startup time
            _BL := BL
            _RST := RST

            return okay
    return FALSE                                                ' If we got here, something went wrong

PUB Stop

PUB Defaults
' Set factory defaults

PUB AddPolicy(policy) | tmp
' Set fingerprint add user policy
'   Valid values:
'       0: Allow the same fingerprint to add a new user
'       1: Prohibit adding the same fingerprint
'   Any other value polls the device and returns the current setting
    tmp := $00
    readReg(core#FNGPRT_ADDMODE, 1, @tmp)
    case policy
        0, 1:
            writeReg(core#FNGPRT_ADDMODE, 1, @policy)
        OTHER:
            return tmp

PUB AddPrint(uid, priv) | tmp, user, idx
' Add a fingerprint to the database
'   Valid values:
'       uid (User ID): $001..$FFF
'       priv (User-privilege): 1, 2, 3 (meaning is user defined)
    ifnot lookdown(uid: $001..$FFF) or lookdown(priv: 1, 2, 3)
        return $FFFF

    user.byte[0] := uid.byte[1]
    user.byte[1] := uid.byte[0]
    user.byte[2] := priv

    repeat idx from 0 to 2
        writeReg(core#ADD_FNGPRT_01 + idx, 3, @user)        ' Acquire 3 fingerprints
        tmp := _response[core#IDX_Q3]
        if tmp <> core#ACK_SUCCESS                          ' If the module doesn't return SUCCESS,
            return tmp                                      '   quit and return the response

PUB DeleteAllUsers
' Delete all users in database
    writeReg(core#DEL_ALL_USERS, 0, 0)

PUB DeviceID
' Read device identification

PUB Reset
' Reset the device
    if lookdown(_RST: 0..31)
        io.High(_RST)
        io.Output(_RST)

        io.Low(_RST)
        time.MSleep(500)
        io.High(_RST)

PUB Response(ptr_resp)
' Read response from fingerprint reader
    bytemove(ptr_resp, @_response, 8)
    bytefill(@_response, 0, 8)

PUB Status
' Return status of last command
    return _response[core#IDX_Q3]

PRI GenChecksum(ptr_data, nr_bytes) | tmp
' Generature checksum of nr_bytes from ptr_data
    result := $00
    repeat tmp from 1 to nr_bytes
        result ^= byte[ptr_data][tmp]

PRI readResp(nr_bytes, ptr_resp) | tmp

    repeat tmp from 0 to nr_bytes-1
        byte[ptr_resp][tmp] := uart.CharIn

PRI readReg(reg, nr_bytes, buff_addr) | tmp, cmd_packet[2]
' Read nr_bytes from register 'reg' to address 'buff_addr'
    cmd_packet.byte[core#IDX_SOM] := core#SOM
    case reg
        core#FNGPRT_ADDMODE:
            cmd_packet.byte[core#IDX_CMD] := reg
            cmd_packet.byte[core#IDX_P1] := $00
            cmd_packet.byte[core#IDX_P2] := $00
            cmd_packet.byte[core#IDX_P3] := core#ADDMODE_R
            cmd_packet.byte[core#IDX_0] := $00
            cmd_packet.byte[core#IDX_CHK] := GenChecksum(@cmd_packet, 5)
            cmd_packet.byte[core#IDX_EOM] := core#EOM

            repeat tmp from core#IDX_SOM to core#IDX_EOM
                uart.Char(cmd_packet.byte[tmp])

            readResp(8, @_response)
            byte[buff_addr][0] := _response[core#IDX_Q2]
            return _response[core#IDX_Q2]

        OTHER:
            return FALSE

PRI writeReg(reg, nr_bytes, buff_addr) | tmp, cmd_packet[2]
' Write nr_bytes to register 'reg' stored at buff_addr
    cmd_packet.byte[core#IDX_SOM] := core#SOM
    case reg
        core#DEL_ALL_USERS, core#DORMANT:
            cmd_packet.byte[core#IDX_CMD] := reg
            cmd_packet.byte[core#IDX_P1] := $00
            cmd_packet.byte[core#IDX_P2] := $00
            cmd_packet.byte[core#IDX_P3] := $00
            cmd_packet.byte[core#IDX_0] := $00
            cmd_packet.byte[core#IDX_CHK] := GenChecksum(@cmd_packet, 5)
            cmd_packet.byte[core#IDX_EOM] := core#EOM

            repeat tmp from core#IDX_SOM to core#IDX_EOM
                uart.Char(cmd_packet.byte[tmp])

        core#ADD_FNGPRT_01..core#ADD_FNGPRT_03:
            cmd_packet.byte[core#IDX_CMD] := reg
            cmd_packet.byte[core#IDX_P1] := byte[buff_addr][0]
            cmd_packet.byte[core#IDX_P2] := byte[buff_addr][1]
            cmd_packet.byte[core#IDX_P3] := byte[buff_addr][2]
            cmd_packet.byte[core#IDX_0] := $00
            cmd_packet.byte[core#IDX_CHK] := GenChecksum(@cmd_packet, 5)
            cmd_packet.byte[core#IDX_EOM] := core#EOM

            repeat tmp from core#IDX_SOM to core#IDX_EOM
                uart.Char(cmd_packet.byte[tmp])

        core#FNGPRT_ADDMODE:
            cmd_packet.byte[core#IDX_CMD] := reg
            cmd_packet.byte[core#IDX_P1] := $00
            cmd_packet.byte[core#IDX_P2] := byte[buff_addr][0]
            cmd_packet.byte[core#IDX_P3] := core#ADDMODE_W
            cmd_packet.byte[core#IDX_0] := $00
            cmd_packet.byte[core#IDX_CHK] := GenChecksum(@cmd_packet, 5)
            cmd_packet.byte[core#IDX_EOM] := core#EOM

            repeat tmp from core#IDX_SOM to core#IDX_EOM
                uart.Char(cmd_packet.byte[tmp])

            readResp(8, @_response)
            return _response[core#IDX_Q2]

        OTHER:
            return FALSE

    repeat tmp from 0 to 7
        _response[tmp] := uart.CharIn

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
