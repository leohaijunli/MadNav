"""
    const num_mag_max = 6

Maximum number of scalar & vector magnetometers (each)
"""
const num_mag_max = 6

"""
    const e_earth = 0.0818191908426

First eccentricity of Earth [-]
"""
const e_earth = 0.0818191908426

"""
    const g_earth = 9.80665

Gravity of Earth [m/s^2]
"""
const g_earth = 9.80665

"""
    const r_earth = 6378137

WGS-84 radius of Earth [m]
"""
const r_earth = 6378137

"""
    const ω_earth = 7.2921151467e-5

Rotation rate of Earth [rad/s]
"""
const ω_earth = 7.2921151467e-5

"""
    const usgs

RBG file for the standard non-linear, pseudo-log, color scale used by the
USGS. Same as the color scale used for the "Bouguer gravity anomaly map."

Reference: https://mrdata.usgs.gov/magnetic/namag.png
"""
const usgs = joinpath(artifact"util_files","util_files","color_scale_usgs.csv")

"""
    const icon_circle

Point icon for optional use in path2kml(;points=true)
"""
const icon_circle = joinpath(artifact"util_files","util_files","icon_circle.dae")

"""
    const silent_debug::Bool

Internal flag. If true, no verbose print outs.
"""
const silent_debug = true


"""
    const emag2

Earth Magnetic Anomaly Grid with 2 arcminute resolution (EMAG2). Compiled
from satellite, marine, and airborne magnetic measurements. Reference:
https://www.ncei.noaa.gov/products/earth-magnetic-model-anomaly-grid-2
"""
const emag2 = joinpath(artifact"EMAG2","EMAG2.h5")

"""
    const emm720

Enhanced Magnetic Model (EMM). Compiled from satellite, marine, airborne,
and ground magnetic measurements. Expands the scalar crustal field up to
spherical harmonic degree and order 720, providing a vector of the magnetic
field with approximately 15 arcminute resolution. Underlying crustal field
model derived from Earth Magnetic Anomaly Grid with 2-arc-minute resolution
(EMAG2). Reference:
https://www.ncei.noaa.gov/products/enhanced-magnetic-model
"""
const emm720 = joinpath(artifact"EMM720_World","EMM720_World.h5")

"""
    const namad

North American Magnetic Anomaly Database (NAMAD). Compiled from marine and
airborne magnetic measurements by the U.S. Geological Survey (USGS),
Geological Survey of Canada (GSC), and Consejo de Recursos Minerales of
Mexico (CRM). Reference:
https://www.usgs.gov/maps/magnetic-anomaly-map-north-america
"""
const namad = joinpath(artifact"NAMAD_305","NAMAD_305.h5")

