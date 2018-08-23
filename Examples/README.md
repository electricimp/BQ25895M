# Setting Up The BQ25895M For Your Battery #


## Important Battery Parameters ##

In order to set up the BQ25895M properly there are two important parameters that you need know for your specific battery: the charging voltage and the charging current. 

## Finding Charging Parameters ##

In this example we will be looking at this [3.7V 2000mAh]( https://www.adafruit.com/product/2011?gclid=EAIaIQobChMIh7uL6pP83AIVS0sNCh1NNQUsEAQYAiABEgKFA_D_BwE) battery from Adafruit. This battery is labelled 3.7V but this is the nominal voltage and not the voltage required for charging. The label also shows its capacity to be 2000mAh but provides no specific charging current. This is not enough information to determine our charging parameters so we must look for more information in the battery's [datasheet](https://cdn-shop.adafruit.com/datasheets/LiIon2000mAh37V.pdf).

In Section 3, Form 1 there is a table describing the battery's rated performance characteristics. Looking at the fourth row of the table, we can see the charging voltage is 4.2V. Row six shows the quick charge current is 1CA. The C represents the battery capacity. Row 1 shows that the capacity is 2000mAh. This means that the quick charge current = 1 * 2000 mA = 2000mA.

It is very important to find the correct values for these two parameters as exceeding them can damage your battery.

## Example ##

```squirrel
#require "BQ25895M.device.lib.nut:1.0.0"

// Choose an impC001 I2C bus and confiure it
local i2c = hardware.i2cKL;
i2c.configure(CLOCK_SPEED_400_KHZ);

// Instantiate a BQ25895M object
batteryCharger <- BQ25895M(i2c);

// Configure the charger to charge at 4.2V to a maximum of 2000mA
batteryCharger.enableCharger(4.2, 2000); 
```
