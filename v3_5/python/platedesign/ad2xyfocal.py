import numpy as np
import platedesign.observatory as obs
import astropy.coordinates as coordinates
import astropy.time as time
import astropy.units as units

from astropy.utils.iers import IERS_A, IERS_A_URL
from astropy.utils.data import download_file
iers_a_file = download_file(IERS_A_URL, cache=True)  
iers_a = IERS_A.open(iers_a_file)                     
from astropy.utils import iers
iers.IERS.iers_table = iers.IERS_A.open(download_file(iers.IERS_A_URL, 
                                                      cache=True))

def altaz2theta(alt, az, altcen, azcen):

    deg2rad= np.pi/180.
    xx= -np.sin(az*deg2rad) * np.sin(((90.)-alt)*deg2rad)
    yy= -np.cos(az*deg2rad) * np.sin(((90.)-alt)*deg2rad)
    zz= np.cos(((90.)-alt)*deg2rad)
    xi= -xx*np.cos(azcen*deg2rad) + yy*np.sin(azcen*deg2rad)
    yi= -yy*np.cos(azcen*deg2rad) - xx*np.sin(azcen*deg2rad)
    zi= zz
    xl= xi
    yl= yi*np.sin((90.-altcen)*deg2rad) + zi*np.cos((90.-altcen)*deg2rad)
    zl= zi*np.sin((90.-altcen)*deg2rad) - yi*np.cos((90.-altcen)*deg2rad)

    theta=np.arcsin(np.sqrt(xl**2+zl**2))/deg2rad
    posang=np.arctan2(-xl, zl)/deg2rad
    
    return (theta, posang)

def ad2theta(ra=None, dec=None, wavelength=None, 
             guide_wavelength=5500., 
             racen=None, deccen=None, observatory=None, lst=None, 
             epoch=None):
    """Convert RA/Dec of target to apparent angle from plate center
    """

    # Find a time within a day of desired epoch, but at desired LST.
    # This yields a time of observation which should have the right
    # LST to within a fraction of a second, which is very much good
    # enough.
    timeobs= time.Time(epoch, format='jyear')
    timeobs.delta_ut1_utc = timeobs.get_delta_ut1_utc(iers_a)         
    sidereal_default= timeobs.sidereal_time('mean', longitude= 284.)
    dlst= (lst-sidereal_default.degree)/360.*0.9972685
    timeobs= time.Time(timeobs.jd+dlst, format='jd')
    timeobs.delta_ut1_utc = timeobs.get_delta_ut1_utc(iers_a)         

    # Convert ra/decs to list of alt/az coordinates
    coords = coordinates.SkyCoord(ra, dec, unit="deg")
    altaz=[]
    for coord, wave in zip(coords, wavelength):
        altaz_frame= coordinates.AltAz(obstime=timeobs, 
                                       obswl=(wave/10000.)*units.micron, 
                                       location=observatory.location, 
                                       pressure=observatory.pressure(), 
                                       temperature=observatory.temperature, 
                                       relative_humidity=
                                       observatory.relative_humidity)
        altaz.append(coord.transform_to(frame=altaz_frame))

    # Same for plate center
    coord_cen = coordinates.SkyCoord(racen, deccen, unit="deg")
    altaz_frame_cen= coordinates.AltAz(obstime=timeobs, 
                                       obswl=(guide_wavelength/10000.)*units.micron, 
                                       location=observatory.location, 
                                       pressure=observatory.pressure(), 
                                       temperature=observatory.temperature, 
                                       relative_humidity=
                                       observatory.relative_humidity)
    altaz_cen=coord_cen.transform_to(frame=altaz_frame)

    # Same for fiducial reference point
    coord_fid = coordinates.SkyCoord(racen, deccen+1.5, unit="deg")
    altaz_frame_fid= coordinates.AltAz(obstime=timeobs, 
                                       obswl=(guide_wavelength/10000.)*units.micron, 
                                       location=observatory.location, 
                                       pressure=observatory.pressure(), 
                                       temperature=observatory.temperature, 
                                       relative_humidity=
                                       observatory.relative_humidity)
    altaz_fid=coord_fid.transform_to(frame=altaz_frame)

    alt= np.array([x.alt.degree for x in altaz])
    az= np.array([x.az.degree for x in altaz])
    alt_cen= np.float64(altaz_cen.alt.degree)
    az_cen= np.float64(altaz_cen.az.degree)
    alt_fid= np.float64(altaz_fid.alt.degree)
    az_fid= np.float64(altaz_fid.az.degree)
    (theta, posang)= altaz2theta(alt, az, alt_cen, az_cen)
    (theta_fid, posang_fid)= altaz2theta(alt_fid, az_fid, alt_cen, az_cen)
    posang= posang-posang_fid
    
    return (theta, posang)
