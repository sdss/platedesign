import astropy.coordinates as coordinates
import astropy.units as units
import numpy as np

apo_latitude= 32.7797556 # deg
apo_longitude= 254.1797222 # deg
apo_height= 2788. # meters

lco_latitude= -29.0146 # deg
lco_longitude= 289.3074 # deg
lco_height= 2380. # meters

class observatory(object):
    def __init__(self, name=None):
        if(name == 'APO'):
            lat= apo_latitude*units.deg
            lon= apo_longitude*units.deg
            height= apo_height*units.m
            self.temperature= 5.*units.deg_C
        if(name == 'LCO'):
            lat= lco_latitude*units.deg
            lon= lco_longitude*units.deg
            height= lco_height*units.m
            self.temperature= 12.*units.deg_C

        self.relative_humidity= 0.5
        self.location= coordinates.EarthLocation(lon, lat, height)

    def pressure(self):
        pressure= units.Quantity(1.01325 * 
                                 np.exp(-self.location.height.value/
                                         (29.3*(self.temperature.value+273.))), 
                                 unit='bar')
        return pressure
