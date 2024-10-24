{
----------------------------------------------------------------------------------------------------
    Filename:       input.biometric.fingerprint-8552.spin
    Description:    Driver for Waveshare UART fingerprint reader SKU#8552
    Author:         Jesse Burt
    Started:        May 18, 2020
    Updated:        Oct 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    { default I/O settings; these can be overridden in the parent object }
    RX_PIN      = 0
    TX_PIN      = 1
    BL_PIN      = 2
    RST_PIN     = 3


    ' Fingerprint add user policies
    ALLOW       = 0
    PROHIBIT    = 1


VAR

    byte _response[8]
    byte _BL, _RST


OBJ

    uart:   "com.serial"                        ' async serial I/O
    core:   "core.con.fingerprint-8552"         ' HW-specific constants
    time:   "time"                              ' timekeeping methods


PUB null()
' This is not a top-level object


PUB start(): status
' Start the driver using default I/O settings
    return startx(RX_PIN, TX_PIN, BL_PIN, RST_PIN)


PUB startx(UART_RX, UART_TX, BL, RESET_PIN): status
' Start the driver with custom I/O settings
'   UART_RX:    receive pin
'   UART_TX:    transmit pin
'   BL:         backlight pin (optional)
'   RESET_PIN:  reset pin (optional)
    if ( lookdown(UART_RX: 0..31) and lookdown(UART_TX: 0..31) )
        if ( status := uart.init(UART_RX, UART_TX, core.UART_MODE, core.UART_MAX_BPS) )
            time.msleep(1)
            _BL := BL
            _RST := RESET_PIN
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE


PUB stop()



PUB defaults
' Set factory defaults
    add_policy(PROHIBIT)
    comparison_level(5)


PUB add_policy(plc=-2): c
' Set fingerprint add user policy
'   Valid values:
'       0: Allow the same fingerprint to add a new user
'       1: Prohibit adding the same fingerprint
'   Any other value polls the device and returns the current setting
    command(core.FNGPRT_ADDMODE, $00, $00, core.ADDMODE_R)
    c := _response[core.IDX_Q2]

    case plc
        0, 1:
            command(core.FNGPRT_ADDMODE, $00, plc, core.ADDMODE_W)
            return _response[core.IDX_Q2]
        other:
            return c


PUB add_print(uid, priv): stat | idx
' Add a fingerprint to the database
'   Valid values:
'       uid (User ID): $001..$FFF
'       priv (User-privilege): 1, 2, 3 (meaning is user defined)
'   Any other value returns the error ACK_FAIL (1)
    ifnot ( lookdown(uid: $001..$FFF) or lookdown(priv: 1, 2, 3) )
        return core.ACK_FAIL

    repeat idx from 0 to 2                      ' Acquire 3 fingerprints
        command(core.ADD_FNGPRT_01 + idx, uid.byte[1], uid.byte[0], priv)
        stat := _response[core.IDX_Q3]
        if ( stat <> core.ACK_SUCCESS )         ' If the module doesn't return SUCCESS,
            return                              '   quit and return the response


PUB comparison_level(l=-2): c
' Set fingerprint comparison level
'   Valid values: 0..9 (0: Most lenient, 9: Most strict)
'   Any other value polls the device and returns the current setting
    command(core.CMP_LEVEL, $00, $00, core.CMP_LEVEL_R)
    c := _response[core.IDX_Q2]

    case l
        0..9:
            command(core.CMP_LEVEL, $00, l)
            return _response[core.IDX_Q3]
        other:
            return c


PUB delete_all_users()
' Delete all users in database
    command(core.DEL_ALL_USERS)


PUB delete_user(uid): s
' Delete a user from the databse
'   Valid values:
'       uid (User ID): $001..$FFF
'   Any other value returns the error ACK_FAIL (1)
    case uid
        $001..$FFF:
            command(core.DEL_USER, uid.byte[1], uid.byte[0])
            return _response[core.IDX_Q3]
        other:
            return core.ACK_FAIL


PUB print_match(): u
' Compare fingerprint against entire database
'   Returns:
'       Matching uid, if any
'       FALSE (0) otherwise
    command(core.COMPARE1TON)
    return ( _response[core.IDX_Q1] << 8 ) | _response[core.IDX_Q2]


PUB print_matches_user(uid): m
' Compare fingerprint against uid
'   Returns:
'       TRUE (-1) if fingerprint captured matches fingerprint recorded for uid
'       FALSE (0) otherwise
    command(core.COMPARE1TO1, uid.byte[1], uid.byte[0])
    return ( ( (_response[core.IDX_Q3]) ^ 1) == 1 )


PUB reset()
' Reset the device
    if ( lookdown(_RST: 0..31) )
        outa[_RST] := 1
        dira[_RST] := 1
        outa[_RST] := 0
        time.msleep(500)
        outa[_RST] := 1


PUB response(ptr_resp)
' Read last response
'   Returns: Address of response data
    bytemove(ptr_resp, @_response, 8)
    bytefill(@_response, 0, 8)                  ' clear out response after read


PUB status(): last_stat
' Return status of last command
    return _response[core.IDX_Q3]


PUB total_user_count(): total
' Returns: Count of total number of users in database
    command(core.RD_NR_USERS)
    total.byte[0] := _response[core.IDX_Q2]
    total.byte[1] := _response[core.IDX_Q1]


PUB user_priv(uid): priv
' Returns: User privilege of uid
    command(core.RD_USER_PRIV, uid.byte[1], uid.byte[0])
    return _response[core.IDX_Q3]


PRI command(cmd, p0=$00, p1=$00, p2=$00, p3=$00) | cmd_pkt[2], tmp
' Write command with (up to 4) parameters to fingerprint reader
    cmd_pkt.byte[core.IDX_SOM] :=   core.SOM
    cmd_pkt.byte[core.IDX_CMD] :=   cmd
    cmd_pkt.byte[core.IDX_P1] :=    p0
    cmd_pkt.byte[core.IDX_P2] :=    p1
    cmd_pkt.byte[core.IDX_P3] :=    p2
    cmd_pkt.byte[core.IDX_0] :=     p3
    cmd_pkt.byte[core.IDX_CHK] :=   genchecksum(@cmd_pkt, 5)
    cmd_pkt.byte[core.IDX_EOM] :=   core.EOM

    repeat tmp from core.IDX_SOM to core.IDX_EOM
        uart.putchar(cmd_pkt.byte[tmp])

    readresp(8, @_response)


PRI genchecksum(p_data, len): cksum | tmp
' Generate checksum of data
'   p_data: pointer to block of data
'   len:    length of data, in bytes
    cksum := 0

    repeat tmp from core.CKSUM_START to len
        cksum ^= byte[p_data][tmp]


PRI readresp(p_resp, len=1) | tmp
' Read response from fingerprint reader
    repeat tmp from 0 to len-1
        byte[p_resp][tmp] := uart.getchar()
    uart.flush()


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

