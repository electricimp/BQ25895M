# BQ25895M #
The [BQ25895M](http://www.ti.com/lit/ds/symlink/bq25895m.pdf) is switch mode battery charge management and system power path management device for single cell Li-Ion and Li-polymer batteries. It supports high input voltage fast charging and communicates over an I2C serial interface.

## Class Usage ##

### Constructor: BQ25895M(*i2cBus, [i2cAddress]*) ###
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

### initCharger( ) ###

Initializes the battery charger with default settings. This method must be called before any other.

#### Return Value ####

None.

#### Example ####

```squirrel
batteryCharger.initCharger();
// Initializes charger with default settings
```

### enableCharging() ###

Enables the device to automatically perform a charging cycle when a battery is connected and an input source is available.
#### Parameters ####

None.

#### Return Value ####

None.

#### Example ####

```squirrel
batteryCharger.enableCharging();
// Enables charging
```

### disableCharging() ###

Disables charging capabilities from the device. The device will not charge until enableCharging() is called again.

#### Parameters ####

None.

#### Return Value ####

None.

#### Example ####

```squirrel
batteryCharger.disableCharging();
// Disables charging
```
### setChargeCurrent(*milliAmps*) ###

This method sets the fast charge current limit.

The default fast charge current limit is 2048mA.
#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *currentLimit* | Integer | Yes | The desired ce in milli Volts (3840 - 4608mV)|

#### Return Value ####

None.

#### Example ####

```squirrel
batteryCharger.setChargeVoltage(4200);
// Sets the charge voltage to 4200mV
```
### setChargeVoltage(*volts*) ###

This method sets the desired battery voltage that the device should charge to.

The default charge voltage is 4352 mV.
#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *chargeVoltage* | Integer | Yes | The desired fast charge current limit in milli Aolts (0 - 5056mA)|

#### Return Value ####

None.

#### Example ####

```squirrel
batteryCharger.setCurrentLimit(5056);
// Sets the fast charge current limit to 5056mA
```



### getChargeVoltage() ###

Returns the target battery charge voltage

#### Parameters ####

None.

#### Return Value ####

Integer — The voltage in milli volts.

#### Example ####

```squirrel
batteryCharger.getChargeVoltage;
// Sets the fast charge current limit to 5056mA