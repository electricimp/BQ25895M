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

// Default watchdog reset time in seconds
const WATCHDOG_RESET_TIME = 30;

// For getChargeStatus() output
enum BQ25895M_CHARGING_STATUS{
    NOT_CHARGING            = 0x00, // 0
    PRE_CHARGE              = 0x08, // 1
    FAST_CHARGING           = 0x10, // 2
    CHARGE_TERMINATION_DONE = 0x18  // 3
}

// For CHGR_FAULT in getChargingFaults output
enum BQ25895M_CHARGING_FAULT{
    NORMAL,                        // 0
    INPUT_FAULT,                   // 1
    THERMAL_SHUTDOWN,              // 2
    CHARGE_SAFETY_TIMER_EXPIRATION // 3
}

// For NTC_FAULT in getChargingFaults output
enum BQ25895M_NTC_FAULT{
    NORMAL,  // 0
    TS_COLD, // 1
    TS_HOT   // 2
}

class BQ25895M {

    static VERSION = "1.0.0";

    // I2C information
    _i2c = null;
    _addr = null;

    // Watchdog kicker
    _watchdogtimer = null;

    constructor(i2c, addr=0xD4){

        _i2c = i2c;
        _addr = addr;

    }

    //PUBLIC METHODS

    // Initialize battery charger with standard configuration
    function enable(voltage, current, settings = null) {

        // Note: 0x3A is the register default
        // Enable charger and min system voltage
        _setReg(BQ25895M_REG03, 0x3a);

        // Note: Register default is 4.352V, need to
        // start watchdog to keep any other setting
        _setChargeVoltage(voltage);

        // Note: Register default is 2048mA, need to
        // start watchdog to keep any other setting
        _setChargeCurrent(current);

        if (!settings) {
            settings = {};
        }

        if (("setChargeCurrentOptimizer" in settings) && settings["setChargeCurrentOptimizer"]) {
            _setRegBit(BQ25895M_REG09, 7, 1); // enable charge current optimizer
        } else {
            _setRegBit(BQ25895M_REG09, 7, 0); // disable charge current optimizer
        }

        // Make sure settings don't revert to chip defaults
        _kickWatchdog();
    }

    // Clear the enable charging bit, device will not charge until enableCharging() is called again
    function disable() {

        local rd = _getReg(BQ25895M_REG03);
        rd = rd & ~(1 << 4); // clear CHG_CONFIG bits

        _setReg(BQ25895M_REG03, rd);

        // Start kicking watchdog, since default is
        // to enable charging
        _kickWatchdog();

    }

    // Returns the target battery voltage
    function getChargeVoltage() {

        local rd = _getReg(BQ25895M_REG06);
        local chrgVlim = ((rd >> 2) * 16) + 3840; // 16mV is the resolution, 3840mV must be added as the offset

        // Convert mV to Volts
        return chrgVlim / 1000.0;

    }

    // Returns the battery voltage based on the ADC conversion
    function getBatteryVoltage() {

        _convStart(); // Kick ADC

        local rd = _getReg(BQ25895M_REG0E);
        local battV = (2304 + (20 * (rd & 0x7f))); // 2304mV must be added as the offset, 20mV is the resolution

        // Convert mV to Volts
        return battV / 1000.0;

    }

    // Returns the VBUS voltage based on the ADC conversion, this is the input voltage
    function getVBUSVoltage() {

        _convStart(); // Kick ADC

        local rd = _getReg(BQ25895M_REG11);
        local vBusV = (2600 + (100 * (rd & 0x7f))) // 2600mV must be added as the offset, 100mV is the resolution

        // Convert mV to Volts
        return vBusV / 1000.0;

    }

    // Returns the system voltage based on the ADC conversion
    function getSystemVoltage() {

        _convStart(); // Kick ADC

        local rd = _getReg(BQ25895M_REG0F);
        local sysV = (2304 + (20 * (rd & 0x7f))); // 2304mV must be added as the offset, 20mV is the resolution

        // Convert mV to Volts
        return sysV;

    }

    // Returns the measured charge current based on the ADC conversion
    function getChargingCurrent() {

        _convStart(); // Kick ADC

        local rd = _getReg(BQ25895M_REG12);
        local iChgr = (50 * (rd & 0x7f)); // 50mA is the resolution

        return iChgr;

    }

    // Returns the charging status: Not Charging, Pre-charge, Fast Charging, Charge Termination Good
    function getChargingStatus() {
        local chargingStatus;

        local rd = _getReg(BQ25895M_REG0B)
        rd = rd & 0x18;

        return rd;

    }

    // Returns the possible charger faults in an array: watchdogFault, boostFault, chrgFault, battFault, ntcFault
    function getChargerFaults() {

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
    function reset() {

        // Stop the watchdog timer, since we are resetting to defaults
        if (_watchdogtimer != null) imp.cancelwakeup(_watchdogtimer);

        // Set reset bit
        _setRegBit(BQ25895M_REG14, 7, 1);
        imp.sleep(0.01);
        // Clear reset bit
        _setRegBit(BQ25895M_REG14, 7, 0);

    }

    //-------------------- PRIVATE METHODS --------------------//

    // Set target battery voltage
    function _setChargeVoltage(vreg) {

        // Convert to mV
        vreg *= 1000;

        // Check that input is within accepted range
        if (vreg < 3840) {
            // minimum charge voltage from device datasheet
            vreg = 3840;
        } else if (vreg > 4608) {
            // maximum charge voltage from device datasheet
            vreg = 4608;
        }

        local rd = _getReg(BQ25895M_REG06);
        rd = rd & ~(0xFC); // clear current limit bits
        rd = rd | (0xFC & (((vreg - 3840) / 16).tointeger()) << 2); // 3840mV is the default offset, 16mV is the resolution

        _setReg(BQ25895M_REG06, rd);

    }

    // Set fast charge current
    function _setChargeCurrent(ichg) {

        // Check that input is within accepted range
        if (ichg < 0) { // charge current must be greater than 0
            ichg = 0;
        } else if (ichg > 5056) { // max charge current from device datasheet
            sichg = 5056;
        }

        local rd = _getReg(BQ25895M_REG04);
        rd = rd & ~(0x7F); // clear current limit bits
        rd = rd | (0x7F & ichg / 64); // 64mA is the resolution

        _setReg(BQ25895M_REG04, rd);

    }

    function _kickWatchdog() {

        _setRegBit(BQ25895M_REG03, 6, 1); // Kick watchdog

        if (_watchdogtimer != null) imp.cancelwakeup(_watchdogtimer);
        _watchdogtimer = imp.wakeup(WATCHDOG_RESET_TIME, _kickWatchdog.bindenv(this));

    }

    function _convStart() {

        // call before ADC conversion
        _setRegBit(BQ25895M_REG02, 7, 1);

    }

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

}