# Setting up the BQ25895M for your battery #


## Important battery parameters ##

In order to properly set up the BQ25895M there are two important parameters that you should know about your specific battery, the charging voltage and the charging current. 

## Finding charging parameters ##
In this example we will be looking at this [3.7V 2000mAh]( https://www.adafruit.com/product/2011?gclid=EAIaIQobChMIh7uL6pP83AIVS0sNCh1NNQUsEAQYAiABEgKFA_D_BwE) battery from adafruit.com. This battery is labelled with 3.7V but this is the nominal voltage and not the voltage required for charging. The label also shows its capacity of 2000mAh but no specific charging current. This is not enough information to determine our charging parameters so we must look for more information in the [datasheet](https://cdn-shop.adafruit.com/datasheets/LiIon2000mAh37V.pdf) for the battery.

In section 3, Form 1 is a table describing the battery rated performance characteristics. Looking at row 4 we can see the charging voltage is 4.2V. Row 6 shows the quick charge current is 1CA. The C represents the battery capacity. Row 1 shows that the capacity is 2000mAh. This means that the quick charge current = 1 * 2000 mA =  2000mA.

It is very important to find the correct values for these two parameters as exceeding them can cause damage to your battery.

## Example ##

  
```squirrel
#require "BQ25895M.device.lib.nut:1.0.0"

local i2c = hardware.i2cKL
i2c.configure(CLOCK_SPEED_400_KHZ);
batteryCharger <- BQ25895M(i2c);

configureCharger(4.2, 2000); //configures the charger to charge at 4.2V at a maximum of 2000mA
```
