// MIT License
//
// Copyright 2018 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

//Registers Addresses
const BQ25895M_REG00 = 0x00;
const BQ25895M_REG01 = 0x01;
const BQ25895M_REG02 = 0x02;
const BQ25895M_REG03 = 0x03;
const BQ25895M_REG04 = 0x04;
const BQ25895M_REG05 = 0x05;
const BQ25895M_REG06 = 0x06;
const BQ25895M_REG07 = 0x07;
const BQ25895M_REG08 = 0x08;
const BQ25895M_REG09 = 0x09;
const BQ25895M_REG0A = 0x0A;
const BQ25895M_REG0B = 0x0B;
const BQ25895M_REG0C = 0x0C;
const BQ25895M_REG0D = 0x0D;
const BQ25895M_REG0E = 0x0E;
const BQ25895M_REG0F = 0x0F;
const BQ25895M_REG10 = 0x10;
const BQ25895M_REG11 = 0x11;
const BQ25895M_REG12 = 0x12;
const BQ25895M_REG13 = 0x13;
const BQ25895M_REG14 = 0x14;

// For getChargeStatus() output
enum BQ25895M_CHARGING_STATUS{
    NOT_CHARGING = 0x00, // 0
    PRE_CHARGE = 0x08, // 1
    FAST_CHARGING = 0x10, // 2
    CHARGE_TERMINATION_DONE = 0x18 // 3
}

// For CHGR_FAULT in getChargingFaults output
enum BQ25895M_CHARGING_FAULT{
    NORMAL, // 0
    INPUT_FAULT, // 1
    THERMAL_SHUTDOWN, // 2
    CHARGE_SAFETY_TIMER_EXPIRATION // 3
}

// For NTC_FAULT in getChargingFaults output
enum BQ25895M_NTC_FAULT{
    NORMAL, // 0
    TS_COLD, // 1
    TS_HOT // 2
}

class BQ25895M {

    static VERSION = "1.0.0";

    // I2C information
    _i2c = null;
    _addr = null;

    constructor(i2c, addr=0xD4){

        _i2c = i2c;
        _addr = addr;

    }

    //PUBLIC METHODS

    // Initialize battery charger configuration registers
    function setDefaults(){

        _setReg(BQ25895M_REG02, 0xf3); // Enable ADC
        _setReg(BQ25895M_REG03, 0x3a); // Enable charger and set defaults
        _setReg(BQ25895M_REG07, 0x8d); // Set defaults

    }

    // Set the enable charging bit, charging will happen automatically
    function enableCharging(){

        local rd = _getReg(BQ25895M_REG03);
        rd = rd | (1 << 4); // set CHG_CONFIG bit

        _setReg(BQ25895M_REG03, rd);

    }

    // Clear the enable charging bit, device will not charge until enableCharging() is called again
    function disableCharging(){

        local rd = _getReg(BQ25895M_REG03);
        rd = rd & ~(1 << 4); // clear CHG_CONFIG bits

        _setReg(BQ25895M_REG03, rd);

    }

    // Set target battery voltage
    function setChargeVoltage(vreg){

        // Check that input is within accepted range
        if (vreg < 3840) vreg = 3840; // minimum charge voltage from device datasheet
        else if (vreg > 4608) vreg = 4608; // maximum charge voltage from device datasheet

        local rd = _getReg(BQ25895M_REG06);
        rd = rd & ~(0xFC); // clear current limit bits
        rd = rd | (0xFC & (((vreg - 3840) / 16).tointeger()) << 2); // 3840mV is the default offset, 16mV is the resolution

        _setReg(BQ25895M_REG06, rd);

    }

    // Set fast charge current
    function setChargeCurrent(ichg){

        // Check that input is within accepted range
        if (ichg < 0){ // charge current must be greater than 0
            ichg = 0;
        } else if (ichg > 5056){ // max charge current from device datasheet
            sichg = 5056;
        }

        local rd = _getReg(BQ25895M_REG04);
        rd = rd & ~(0x7F); // clear current limit bits
        rd = rd | (0x7F & ichg / 64); // 64mA is the resolution

        _setReg(BQ25895M_REG04, rd);

    }

    // Returns the target battery voltage
    function getChargeVoltage(){

        local rd = _getReg(BQ25895M_REG06);
        local chrgVlim = ((rd >> 2) * 16) + 3840; // 16mV is the resolution, 3840mV must be added as the offset

        return chrgVlim;

    }

    // Returns the battery voltage based on the ADC conversion
    function getBatteryVoltage(){

        _convStart(); // Kick ADC

        local rd = _getReg(BQ25895M_REG0E);
        local battV =(2304 + (20 * (rd & 0x7f))); // 2304mV must be added as the offset, 20mV is the resolution

        return battV;

    }

    // Returns the VBUS voltage based on the ADC conversion, this is the input voltage
    function getVBUSVoltage(){

        _convStart(); // Kick ADC

        local rd = _getReg(BQ25895M_REG11);
        local vBusV = (2600 + (100 * (rd & 0x7f))) // 2600mV must be added as the offset, 100mV is the resolution

        return vBusV;
    }

    // Returns the system voltage based on the ADC conversion
    function getSystemVoltage(){

        _convStart(); // Kick ADC

        local rd = _getReg(BQ25895M_REG0F);
        local sysV = (2304 + (20 * (rd & 0x7f))); // 2304mV must be added as the offset, 20mV is the resolution

        return sysV;

    }

    // Returns the measured charge current based on the ADC conversion
    function getChargingCurrent(){

        _convStart(); // Kick ADC

        local rd = _getReg(BQ25895M_REG12);
        local iChgr = (50 * (rd & 0x7f)); // 50mA is the resolution

        return iChgr;
    }

    // Returns the measured temperature of the NTC under the battery
    function getBatteryTemperature(){

        _convStart();

        local rd = _getReg(BQ25895M_REG10);

        if (typeof points == "boolean") {
            _pointsPerRead = 10.0;
            _highSide = points;
        } else {
            _pointsPerRead = points * 1.0;
            _highSide = highSide;
        }

        _beta = b * 1.0;
        _t0 = t0 * 1.0;


        local tspct = ((rd + 21) / 100) * 5;

        return tspct;

    }
    // Returns the charging status: Not Charging, Pre-charge, Fast Charging, Charge Termination Good
    function getChargingStatus(){
        local chargingStatus;

        local rd = _getReg(BQ25895M_REG0B)
        rd = rd & 0x18;

        return rd;
    }

    // Returns the possible charger faults in an array: watchdogFault, boostFault, chrgFault, battFault, ntcFault
    function getChargerFaults(){

        local chargerFaults = {"watchdogFault" : 0, "boostFault" : 0, "chrgFault" : 0, "battFault" : 0, "ntcFault" : 0};

        local rd = _getReg(BQ25895M_REG0C);

        chargerFaults.watchdogFault <- rd >> 7;
        chargerFaults.boostFault <- rd >> 6;
        chargerFaults.chrgFault <- rd & 0x30; // normal, input fault, thermal shutdown, charge safety timer expiration
        chargerFaults.battFault <- rd >> 3;
        chargerFaults.ntcFault <- rd & 0x07; // normal, TS cold, TS hot

        return chargerFaults;

    }

    // Restore default device settings
    function reset(){

        _setRegBit(BQ25895M_REG14, 7, 1); // Set reset bit
        _setRegBit(BQ25895M_REG14, 7, 0); // Clear reset bit

    }

    //-------------------- PRIVATE METHODS --------------------//

    function _getReg(reg) {

        local result = _i2c.read(_addr, reg.tochar(), 1);
        if (result == null) {
            throw "I2C read error: " + _i2c.readerror();
        }
        return result[0];

    }

    function _setReg(reg, val) {

        local result = _i2c.write(_addr, format("%c%c", reg, (val & 0xff)));
        if (result) {
            throw "I2C write error: " + result;
        }
        return result;

    }

    function _setRegBit(reg, bit, state) {

        local val = _getReg(reg);
        if (state == 0) {
            val = val & ~(0x01 << bit);
        } else {
            val = val | (0x01 << bit);
        }
        return _setReg(reg, val);

    }

    function _convStart(){ // call before ADC conversion

        _setRegBit(BQ25895M_REG03, 7, 1);

    }
}