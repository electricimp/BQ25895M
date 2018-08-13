# BQ25895M #
The [BQ25895M](http://www.ti.com/lit/ds/symlink/bq25895m.pdf) is switch mode battery charge management and system power path management device for single cell Li-Ion and Li-polymer batteries. It supports high input voltage fast charging and communicates over an I2C serial interface.

## Class Usage ##

### Constructor: BQ25895M(*i2cBus [,i2cAddress]*) ###
The class’ constructor takes one required parameter (a configured imp I&sup2;C bus) and an optional parameter (the I&sup2;C address of the BQ25895M. The I&sup2;C address must be the address of your chip or an I&sup2;C error will be thrown.
#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *i2cBus* | i2c bus object | Yes | The imp i2c bus that the BQ25895M is wired to. The i2c bus must be preconfigured. The library will not configure the bus. |
| *i2cAddress* | integer | No | The i2c address of the BQ25895M. Default value is `0x6A` |
#### Return Value ####

None.
#### Example ####
```squirrel
local i2c = hardware.i2cKL
i2c.configure(CLOCK_SPEED_400_KHZ);
batteryCharger <- BQ25895M(i2c);
```
  
## Class Methods ##

### setDefaults( ) ###

Initializes the battery charger with default settings.

#### Return Value ####

None.

#### Example ####

```squirrel
// Initializes charger with default settings
batteryCharger.initCharger();
```

### enableCharging() ###

Enables the device to automatically perform a charging cycle when a battery is connected and an input source is available.
#### Parameters ####

None.

#### Return Value ####

None.

#### Example ####

```squirrel
// Enables charging
batteryCharger.enableCharging();
```

### disableCharging() ###

Disables charging capabilities from the device. The device will not charge until enableCharging() is called again.

#### Parameters ####

None.

#### Return Value ####

None.

#### Example ####

```squirrel
// Disables charging
batteryCharger.disableCharging();
```
### setChargeCurrent(*milliAmps*) ###

This method sets the fast charge current limit.

The default fast charge current limit is 2048mA.
#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *currentLimit* | Integer | Yes | The desired fast charge current limit in milli Amps (0 - 5056mA)

#### Return Value ####

None.

#### Example ####

```squirrel
// Sets the fast charge current limit to 5056mA
batteryCharger.setCurrentLimit(5056);
```
### setChargeVoltage(*milliVolts*) ###

This method sets the desired battery voltage that the device should charge to.

The default charge voltage is 4352 mV.
#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *chargeVoltage* | Integer | Yes | The desired charge voltage in milli Volts (3840 - 4608mV)|

#### Return Value ####

None.

#### Example ####

```squirrel
// Sets the charge voltage to 4200mV
batteryCharger.setChargeVoltage(4200);
```



### getChargeVoltage() ###

Returns the target battery charge voltage

#### Parameters ####

None.

#### Return Value ####

Integer — The voltage in milli volts.

#### Example ####

```squirrel

local voltage = batteryCharger.getChargeVoltage();
server.log("Voltage: " + voltage + "mV");
```

### getBatteryVoltage() ###

Returns the current battery voltage based on the internal ADC conversion.

#### Parameters ####

None.

#### Return Value ####

Integer — The battery voltage in milli volts.

#### Example ####

```squirrel
local voltage = batteryCharger.getBatteryVoltage();
server.log("Voltage: " + voltage + "mV");
```
### getVBUSVoltage() ###

Returns the VBUS voltage based on the ADC conversion, this is the input voltage

#### Parameters ####

None.

#### Return Value ####

Integer — The battery voltage in milli volts.

#### Example ####

```squirrel
local voltage = batteryCharger.getVBUSVoltage();
server.log("Voltage: " + voltage + "mV");
```
### getSystemVoltage() ###

Returns the system voltage based on the ADC conversion, this the output voltage which can be used to power other chips in your application

#### Parameters ####

None.

#### Return Value ####

Integer — The battery voltage in milli volts.

#### Example ####

```squirrel
local voltage = batteryCharger.getSystemVoltage();
server.log("Voltage: " + voltage + "mV");
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

Integer — Not Charging = 0,  Pre-charge = 1, Fast Charging = 2, Charge Termination Good = 3
```squirrel
enum BQ25895M_CHARGING_STATUS{
    NOT_CHARGING = 0x00, // 0
    PRE_CHARGE = 0x08, // 1
    FAST_CHARGING = 0x10, // 2
    CHARGE_TERMINATION_DONE = 0x18 // 3
}
```
#### Example ####

```squirrel
local status = charger. getChargingStatus();  
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
| *Watchdog Fault* | Bool | `true` if watchdog timer has expired|
| *Boost Fault* | Bool | `true` if VBUS overloaded in OTG, VBUS OVP, or battery is too low  |
| *Chrg Fault* | Enum | *enumerated type |
| *Batt Fault* | Bool| `true` if VBAT > VBATOVP |
| *NTC Fault* | Enum | *enumerated type |

*CHRG_FAULT has an enumerated type to match its output.
```squirrel
enum BQ25895M_CHARGING_FAULT{
    NORMAL, // 0
    INPUT_FAULT, // 1
    THERMAL_SHUTDOWN, // 2
    CHARGE_SAFETY_TIMER_EXPIRATION // 3
}
```
*NTC_FAULT has an enumerated type to match its output.
```squirrel
enum BQ25895M_NTC_FAULT{
    NORMAL, // 0
    TS_COLD, // 1
    TS_HOT // 2
}
```

#### Example ####

```squirrel
local chargingStatus = batteryCharger.getChargerFaults();
```
### reset() ###

Restores the devices default settings
#### Parameters ####

None.

#### Return Value ####

None.

#### Example ####

```squirrel
batteryCharger.setDefaults();
```