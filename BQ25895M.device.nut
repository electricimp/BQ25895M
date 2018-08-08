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
enum chargingStatus{
    not_charging, // 0
    pre_charge, // 1
    fast_charging, // 2
    charge_termination_done // 3
}

// For CHGR_FAULT in getChargingFaults output
enum chargingFault{
    normal, // 0
    input_fault, // 1
    thermal_shutdown, // 2
    charge_safety_timer_expiration // 3
}

// For NTC_FAULT in getChargingFaults output
enum ntcFault{
   normal, // 0
   ts_cold, // 1
   ts_hot // 2
}

class BQ25895M {
    
    static VERSION = "1.0.0";
    
    // I2C information
    _i2c = null;
    _addr = null;

    constructor(i2c, addr=0x6a<<1){
        
        _i2c = i2c;
        _addr = addr;
        
    }
    
    //PUBLIC METHODS
    
    // Initialize battery charger configuration registers 
    function initCharger(){
        
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
        rd = rd & ~(1<<4); // clear CHG_CONFIG bits
        
        _setReg(BQ25895M_REG03, rd);
        
    } 
    
    // Set target battery voltage
    function setChargeVoltage(VREG){ 
        
        // Check that input is within accepted range
        if (VREG < 3.840) VREG = 3.840;
        else if (VREG > 4.608) VREG = 4.608;
        
        local rd = _getReg(BQ25895M_REG06);
        rd = rd & ~(0xFC); // clear current limit bits
        rd = rd | (0xFC & ((((VREG*1000) - 3840)/16).tointeger()) << 2);
        
        _setReg(BQ25895M_REG06, rd);
        
    }

    // Set fast charge current
    function setChargeCurrent(ICHG){
        
        // Check that input is within accepted range
        if (ICHG < 0) ICHG = 0;
        else if (ICHG > 5056) ICHG = 5056;
        
        local rd = _getReg(BQ25895M_REG04);
        rd = rd & ~(0x7F); // clear current limit bits
        rd = rd | (0x7F & ICHG/64); // set ILIM
    
        _setReg(BQ25895M_REG04, rd);
        
    }
    
    // Returns the target battery voltage
    function getChargeVoltage(){
        
        local rd = _getReg(BQ25895M_REG06);
        local ChrgVlim = ((rd>>2)*16)+3840;

        return ChrgVlim;
        
    }
    
    // Returns the battery voltage based on the ADC conversion
    function getBatteryVoltage(){
        
        _convStart(); // Kick ADC
        
        local rd = _getReg(BQ25895M_REG0E);
        local BATV =(2304+(20*(rd&0x7f)));
        
        return BATV;
        
    }
     
    // Returns the VBUS voltage based on the ADC conversion, this is the input voltage
    function getVBUSVoltage(){ 
        
        _convStart(); // Kick ADC

        local rd = _getReg(BQ25895M_REG11);
        local VBUSV = (2600+(100*(rd&0x7f)))
        
        return VBUSV; 
    }
    
    // Returns the system voltage based on the ADC conversion
    function getSystemVoltage(){
    
        _convStart(); // Kick ADC
    
        local rd = _getReg(BQ25895M_REG0F);
        local SYSV = (2304+(20*(rd&0x7f)));
        
        return SYSV;
        
    }

    // Returns the measured charge current based on the ADC conversion
    function getChargingCurrent(){
        
        _convStart(); // Kick ADC
        
        local rd = _getReg(BQ25895M_REG12);
        local ICHGR = (50*(rd&0x7f))
        
        return ICHGR;  
    }
    
    // Returns the charging status: Not Charging, Pre-charge, Fast Charging, Charge Termination Good
    function getChargingStatus(){
        
        local chargingStatus;
        
        local rd = _getReg(BQ25895M_REG0B)
        rd = rd & 0x18; 
        
        local mode = "";
        
        switch(rd) {
            case 0x00:
                mode = 0; // Not charging
                break;
            case 0x08:
                mode = 1; // Pre charge
                break;
            case 0x10:
                mode = 2; // Fast charging
                break;
            case 0x18:
                mode = 3; // Charge termination done
                break;
        }
        
        return mode;
        
    }
    
    // Returns the possible charger faults in an array: WATCHDOG_FAULT, BOOST_FAULT, CHRG_FAULT, BAT_FAULT, NTC_FAULT
    function getChargerFaults(){
        
        local chargerFaults = {"WATCHDOG_FAULT" : 0, "BOOST_FAULT" : 0, "CHRG_FAULT" : 0, "BAT_FAULT" : 0, "NTC_FAULT" : 0};
        
        local rd = _getReg(BQ25895M_REG0C);

        chargerFaults.WATCHDOG_FAULT <- rd >> 7;
        chargerFaults.BOOST_FAULT <- rd >> 6;
        
        local CHRG_FAULT = rd & 0x30;
        local chargeFaultReason = 0;
        
         switch(CHRG_FAULT){
            case 0x00:
                chargeFaultReason = 0; // Normal
                break; 
            case 0x10:
                chargeFaultReason = 1; // Input Fault
                break;
            case 0x20:
                chargeFaultReason = 2; // Thermal Shutdown
                break;
            case 0x30:
                chargeFaultReason = 3; // Charge Safety Timer Explanation
                break;
        }
        
        chargerFaults.CHRG_FAULT <- chargeFaultReason;
        chargerFaults.BAT_FAULT <- rd >> 3;
        
        local NTC_FAULT = rd & 0x07;
        local ntcFaultReason = 0;
        
        switch(NTC_FAULT){
            case 0x00:
                ntcFaultReason = 0; // Normal
                break;
            case 0x01:
                ntcFaultReason = 1; // TS Cold
                break;
            case 0x02:
                ntcFaultReason = 2; // TS Hot
                break;
        }
        
        chargerFaults.NTC_FAULT <- ntcFaultReason;
         
        return chargerFaults;
        
    }
    
    // Restore default device settings
    function setDefaults(){
          
        _setRegBit(BQ25895M_REG14, 7, 1); // Set reset bit
        imp.sleep(1);
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