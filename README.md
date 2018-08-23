
# BQ25895M #

The [BQ25895M](http://www.ti.com/lit/ds/symlink/bq25895m.pdf) is switch mode battery charge management and system power path management device for single cell Li-Ion and Li-polymer batteries. It supports high input voltage fast charging and communicates over an I2C serial interface.

**To add this library to your project, add the following to the top of your device code:**

`#require "BQ25895M.device.lib.nut:1.0.0"`

## Class Usage ##

### Constructor: BQ25895M(*i2cBus [,i2cAddress]*) ###
The class’ constructor takes one required parameter (a configured imp I&sup2;C bus) and an optional parameter (the I&sup2;C address of the BQ25895M. The I&sup2;C address must be the address of your chip or an I&sup2;C error will be thrown.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *i2cBus* | i2c bus object | Yes | The imp i2c bus that the BQ25895M is wired to. The i2c bus must be preconfigured. The library will not configure the bus. |
| *i2cAddress* | integer | No | The i2c address of the BQ25895M. Default value is `0xD4` |

#### Return Value ####

None.

#### Example ####

```squirrel
local i2c = hardware.i2cKL
i2c.configure(CLOCK_SPEED_400_KHZ);
batteryCharger <- BQ25895M(i2c);
```
  
## Class Methods ##

### enable(*[,chargeVoltage][, currentLimit][,settings]*) ###

Enables and configures the battery charger with settings to perform a charging cycle when a battery is connected and an input source is available. If no parameters are passed in the *chargeVoltage* will be set to 4.2V and the *currentLimit* will be set to 1000mA. It is recommended that this function is called immediately after the constructor on cold boots. 

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *chargeVoltage* | Float | No | The desired charge voltage in Volts (3.84 - 4.608V). Defaults to 4.2V if no parameter is passed in. |
| *currentLimit* | Integer | No | The desired fast charge current limit in milliAmps (0 - 5056mA). Defaults to 1000mA if no parameter is passed in. |
| *settings* | Table | No | The table entries will enable additional settings available within the charger|

##### Settings Table #####

| Charging Fault | Value | Description |
| --- | --- | --- |
| *chargeCurrentOptimizer* | *1* |  Identify maximum power point without overload the input source


#### Return Value ####

None.

#### Example ####

```squirrel
// Configure battery charger with charge voltage of 4.2V and current limit of 1000mA
batteryCharger.enable(4.2, 1000);
```

### disable() ###

Disables charging capabilities from the device. The device will not charge until enableCharging() is called again.

#### Parameters ####

None.

#### Return Value ####

None.

#### Example ####

```squirrel
// Disables charging
batteryCharger.disable();
```

### getChargeVoltage() ###

Returns the target battery charge voltage.

#### Parameters ####

None.

#### Return Value ####

Float — The voltage in volts.

#### Example ####

```squirrel
local voltage = batteryCharger.getChargeVoltage();
server.log("Voltage: " + voltage + "V");
```

### getBatteryVoltage() ###

Returns the current battery voltage based on the internal ADC conversion.

#### Parameters ####

None.

#### Return Value ####

Float — The battery voltage in volts.

#### Example ####

```squirrel
local voltage = batteryCharger.getBatteryVoltage();
server.log("Voltage: " + voltage + "V");
```
### getVBUSVoltage() ###

Returns the VBUS voltage based on the ADC conversion, this is the input voltage

#### Parameters ####

None.

#### Return Value ####

Float — The battery voltage in volts.

#### Example ####

```squirrel
local voltage = batteryCharger.getVBUSVoltage();
server.log("Voltage: " + voltage + "V");
```
### getSystemVoltage() ###

Returns the system voltage based on the ADC conversion, this the output voltage which can be used to power other chips in your application. In most applications the system voltage is the impC001 VMOD supply.

#### Parameters ####

None.

#### Return Value ####

Float — The battery voltage in volts.

#### Example ####

```squirrel
local voltage = batteryCharger.getSystemVoltage();
server.log("Voltage: " + voltage + "V");
```
### getChargingCurrent() ###

Returns the measured current going to the battery 

#### Parameters ####

None.

#### Return Value ####

Integer — The charging current in milli Amps.

#### Example ####

```squirrel
local current = batteryCharger.getChargingCurrent();
server.log("Current: " + current + "mA");
```
### getChargingStatus() ###

 Returns the charging status

#### Parameters ####

None.

#### Return Value ####

Integer — see table below for supported values.

| Charging Status Constant| Value | 
| --- | --- | 
| *BQ25895M_CHARGING_STATUS.NOT_CHARGING* | 0x00 | 
| *BQ25895M_CHARGING_STATUS.PRE_CHARGE* | 0x08| 
| *BQ25895M_CHARGING_STATUS.FAST_CHARGE* | 0x10|
| *BQ25895M_CHARGING_STATUS.CHARGE_TERMINATION_DONE* | 0x18| 
 
#### Example ####

```squirrel
local status = charger.getChargingStatus();  
switch(status) {  
	case BQ25895M_CHARGING_STATUS.NOT_CHARGING :  
		// Do something  
		break;  
	case BQ25895M_CHARGING_STATUS.PRE_CHARGE :  
		// Do something  
		break;  
	case BQ25895M_CHARGING_STATUS.FAST_CHARGING :  
		// Do something  
		break;  
	case BQ25895M_CHARGING_STATUS.CHARGE_TERMINATION_DONE :  
		// Do something  
		break;  
}
```

### getChargerFaults() ###

Returns the possible charger faults

#### Parameters ####

None.

#### Return Value ####

Table &mdash; the possible charger faults

| Fault | Type | Description |
| --- | --- | --- |
| *watchdogFault* | Bool | `true` if watchdog timer has expired|
| *boostFault* | Bool | `true` if VBUS overloaded in OTG, VBUS OVP, or battery is too low  |
| *chrgFault* | Integer | See table *Charging Fault* below for possible values. |
| *battFault* | Bool| `true` if VBAT > VBATOVP |
| *ntcFault* | Integer | See *NTC Fault* table below for possible values. |

##### Charging Fault #####

| Charging Fault | Value 
| --- | --- |
| *BQ25895M_CHARGING_FAULT.NORMAL* | 0x00 | 
| *BQ25895M_CHARGING_FAULT.INPUT_FAULT* | 0x01|
| *BQ25895M_CHARGING_FAULT.THERMAL_SHUTDOWN* | 0x02|
| *BQ25895M_CHARGING_FAULT.CHARGE_SAFETY_TIMER_EXPIRATION* | 0x03| 

##### NTC Fault #####

| NTC Fault| Value | 
| --- | --- | 
| *BQ25895M_NTC_FAULT.NORMAL* | 0x00 | 
| *BQ25895M_NTC_FAULT.TS_COLD* | 0x01| 
| *BQ25895M_NTC_FAULT.TS_HOT* | 0x02| 

#### Example ####

```squirrel
local faults = batteryCharger.getChargerFaults();
server.log("Watchdog Fault =  " + faults.watchdogFault);
server.log("Boost Fault =  " + faults.boostFault);

switch(faults.chrgFault) {  
	case BQ25895M_CHARGING_FAULT.NORMAL:  
		// Do something  
		break;  
	case BQ25895M_CHARGING_FAULT.INPUT_FAULT:  
		// Do something  
		break;  
	case BQ25895M_CHARGING_FAULT.THERMAL_SHUTDOWN:  
		// Do something  
		break;  
	case BQ25895M_CHARGING_FAULT.CHARGE_SAFETY_TIMER_EXPIRATION:  
		// Do something  
		break;  
}

server.log("Battery Fault =  " + faults.battFault);

switch(faults.ntcFault) {  
	case BQ25895M_NTC_FAULT.NORMAL:  
		// Do something  
		break;  
	case BQ25895M_NTC_FAULT.TS_COLD:  
		// Do something  
		break;  
	case BQ25895M_NTC_FAULT.TS_HOT:  
		// Do something  
		break;  


```

### reset() ###

Software reset which clears all register settings. NOTE: This will reset the charge voltage and current to the register default of  4.352V and 2048A.

#### Parameters ####

None.

#### Return Value ####

None.

#### Example ####

```squirrel
// Clears all register settings restoring to device defaults
batteryCharger.reset();
```

## License ##

The BQ25895M library is licensed under the [MIT License](LICENSE).
