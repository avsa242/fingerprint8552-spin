# fingerprint-8552-spin 
-----------------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver for the Waveshare fingerprint reader, SKU# 8552 (Parallax #29126)

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* UART connection at 19.2kbps
* Set duplicate print add policy
* Set fingerprint comparison level/strictness
* Add fingerprint to database, with privilege level
* Delete specific user or all users
* Match fingerprint against specific existing user ID, or entire database (return matching uid)
* Return count of total users in database
* Return privilege level of user ID

## Requirements

P1/SPIN1:
* spin-standard-library
* P1/SPIN1: 1 extra core/cog for the PASM UART engine

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.2.5-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Doesn't read fingerprint images/eigenvalues
* Driver will start successfully even if communication with the reader hasn't actually been established (no DeviceID(), or similar verification yet)

## TODO

- [x] Port to SPIN2
- [ ] Add method to read user list
- [ ] Add method to read DSP version
- [ ] Add method to read fingerprint images
- [ ] Add method to read fingerprint eigenvalues
- [x] Add simple demo app
