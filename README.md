
# BQ25895M #

The [BQ25895M](http://www.ti.com/lit/ds/symlink/bq25895m.pdf) is switch-mode battery charge and system power path management device for single-cell Li-Ion and Li-polymer batteries. It supports high input voltage fast charging and communicates over an I&sup2;C interface.

**To add this library to your project, add** `#require "BQ25895M.device.lib.nut:1.0.0"` **to the top of your device code.**

## Class Usage ##

### Constructor: BQ25895M(*i2cBus [,i2cAddress]*) ###

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *i2cBus* | imp i2c bus object | Yes | The imp I&sup2;C bus that the BQ25895M is connected to. The I&sup2;C bus **must** be preconfigured &mdash; the library will not configure the bus |
| *i2cAddress* | Integer | No | The BQ25895M's I&sup2;C address. Default: `0xD4` |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
#require "BQ25895M.device.lib.nut:1.0.0"

// Alias and configure an impC001 I2C bus
local i2c = hardware.i2cKL;
i2c.configure(CLOCK_SPEED_400_KHZ);

// Instantiate a BQ25895M object
batteryCharger <- BQ25895M(i2c);
```

## Class Methods ##

### enable(*chargeVoltage, currentLimit[,settings]*) ###

This method configures and enables the battery charger with settings to perform a charging cycle when a battery is connected and an input source is available. It is recommended that this function is called immediately after the constructor on cold boots.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *chargeVoltage* | Float | Yes | The desired charge voltage in V (3.84 - 4.608V).|
| *currentLimit* | Integer | Yes | The desired fast charge current limit in mA (0 - 5056mA).|
| *settings* | Table | No | A table of additional settings *(see below)* |

##### Settings Table Options #####

| Table Key | Value | Description |
| --- | --- | --- |
| *setChargeCurrentOptimizer* | *true* | Identify maximum power point without overload the input source |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Configure battery charger with charge voltage of 4.2V and current limit of 1000mA
batteryCharger.enable(4.2, 1000);
```

### disable() ###

This method disables the device's charging capabilities. The battery will not charge until *enableCharging()* is called.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Disables charging
batteryCharger.disable();

```

### getChargeVoltage() ###

This method gets the connected battery's current charge voltage.

#### Return Value ####

Float &mdash; The charge voltage in V.

#### Example ####

```squirrel
local voltage = batteryCharger.getChargeVoltage();
server.log("Voltage (charge): " + voltage + "V");
```

### getBatteryVoltage() ###

This method gets the current battery voltage based on internal ADC conversion.

#### Return Value ####

Float &mdash; The battery voltage in V.

#### Example ####

```squirrel
local voltage = batteryCharger.getBatteryVoltage();
server.log("Voltage (ADC): " + voltage + "V");
```

### getVBUSVoltage() ###

This method gets the V<sub>BUS</sub> voltage based on ADC conversion. This is the input voltage.

#### Return Value ####

Float &mdash; The V<sub>BUS</sub>  voltage in V.

#### Example ####

```squirrel
local voltage = batteryCharger.getVBUSVoltage();
server.log("Voltage (VBAT): " + voltage + "V");
```

### getSystemVoltage() ###

This method gets the system voltage based on the ADC conversion. This the output voltage which can be used to drive other chips in your application. In most impC001-based applications, the system voltage is the impC001 V<sub>MOD</sub> supply.

#### Return Value ####

Float &mdash; The system voltage in V.

#### Example ####

```squirrel
local voltage = batteryCharger.getSystemVoltage();
server.log("Voltage (system): " + voltage + "V");
```

### getChargingCurrent() ###

This method gets the measured current going to the battery.

#### Return Value ####

Integer &mdash; The charging current in mA.

#### Example ####

```squirrel
local current = batteryCharger.getChargingCurrent();
server.log("Current (charging): " + current + "mA");
```

### getChargingStatus() ###

This method reports the battery charging status.

#### Return Value ####

Integer &mdash; A charging status constant *(see below)*

| Charging Status Constant| Value |
| --- | --- |
| *BQ25895M_CHARGING_STATUS.NOT_CHARGING* | 0x00 |
| *BQ25895M_CHARGING_STATUS.PRE_CHARGE* | 0x08|
| *BQ25895M_CHARGING_STATUS.FAST_CHARGE* | 0x10|
| *BQ25895M_CHARGING_STATUS.CHARGE_TERMINATION_DONE* | 0x18 |

#### Example ####

```squirrel
local status = charger.getChargingStatus();
switch(status) {
  case BQ25895M_CHARGING_STATUS.NOT_CHARGING:
    // Do something
    break;
  case BQ25895M_CHARGING_STATUS.PRE_CHARGE:
    // Do something
    break;
  case BQ25895M_CHARGING_STATUS.FAST_CHARGING:
    // Do something
    break;
  case BQ25895M_CHARGING_STATUS.CHARGE_TERMINATION_DONE:
    // Do something
    break;
}
```

### getChargerFaults() ###

This method reports possible charger faults.

#### Return Value ####

Table &mdash; A charger fault report *(see below)*

| Key/Fault | Type | Description |
| --- | --- | --- |
| *watchdogFault* | Bool | `true` if watchdog timer has expired, otherwise `false` |
| *boostFault* | Bool | `true` if V<sub>MBUS</sub> overloaded in OTG, V<sub>BUS</sub> OVP, or battery is too low, otherwise `false` |
| *chrgFault* | Integer | A charging fault. See table *Charging Faults*, below, for possible values |
| *battFault* | Bool| `true` if V<sub>BAT</sub> > V<sub>BATOVP</sub>, otherwise `false` |
| *ntcFault* | Integer | An NTC fault. See table *NTC Faults*, below, for possible values |

#### Charging Faults ####

| Charging Fault Constant | Value |
| --- | --- |
| *BQ25895M_CHARGING_FAULT.NORMAL* | 0x00 |
| *BQ25895M_CHARGING_FAULT.INPUT_FAULT* | 0x01 |
| *BQ25895M_CHARGING_FAULT.THERMAL_SHUTDOWN* | 0x02 |
| *BQ25895M_CHARGING_FAULT.CHARGE_SAFETY_TIMER_EXPIRATION* | 0x03 |

#### NTC Fault ####

| NTC Fault Constant | Value |
| --- | --- |
| *BQ25895M_NTC_FAULT.NORMAL* | 0x00 |
| *BQ25895M_NTC_FAULT.TS_COLD* | 0x01 |
| *BQ25895M_NTC_FAULT.TS_HOT* | 0x02 |

#### Example ####

```squirrel
local faults = batteryCharger.getChargerFaults();
server.log("Fault Report");
if (faults.watchdogFault) server.log("Watchdog Timer Fault reported");
if (faults.boostFault) server.log("Boost Fault reported");

switch(faults.chrgFault) {
  case BQ25895M_CHARGING_FAULT.NORMAL:
    server.log("Charging OK");
    break;
  case BQ25895M_CHARGING_FAULT.INPUT_FAULT:
    server.log("Charging NOT OK - Input Fault reported");
    break;
  case BQ25895M_CHARGING_FAULT.THERMAL_SHUTDOWN:
    server.log("Charging NOT OK - Thermal Shutdown reported");
    break;
  case BQ25895M_CHARGING_FAULT.CHARGE_SAFETY_TIMER_EXPIRATION:
    server.log("Charging NOT OK - Safety Timer expired");
    break;
}

if (faults.battFault) server.log("VBAT too high");

switch(faults.ntcFault) {
  case BQ25895M_NTC_FAULT.NORMAL:
    server.log("NTC OK");
    break;
  case BQ25895M_NTC_FAULT.TS_COLD:
    server.log("NTC NOT OK - TS Cold");
    break;
  case BQ25895M_NTC_FAULT.TS_HOT:
    server.log("NTC NOT OK - TS Hot");
    break;
```

### reset() ###

This method provides a software reset which clears all of the BQ25895M's register settings.

**Note** This will reset the charge voltage and current to the register defaults of 4.352V and 2048mA.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Reset the BQ25895M
batteryCharger.reset();
```

## License ##

This library is licensed under the [MIT License](LICENSE).
