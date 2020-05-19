# fingerprint-8552-spin 
-----------------------

This is a P8X32A/Propeller driver for the Waveshare fingerprint reader, SKU# 8552

## Salient Features

* UART connection at 19.2kbps
* Set duplicate print add policy
* Add fingerprint to database, with privilege level
* Delete specific user or all users
* Match fingerprint against specific existing user ID, or entire database (return matching uid)
* Return count of total users in database
* Return privilege level of user ID

## Requirements

* P1/SPIN1: 1 extra core/cog for the PASM UART engine

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)

## Limitations

* Very early in development - may malfunction, or outright fail to build

## TODO

- [ ] TBD
