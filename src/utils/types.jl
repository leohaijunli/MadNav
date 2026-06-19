"""
MagV{T2 <: AbstractFloat}

Vector magnetometer measurement struct.

|**Field**|**Type**|**Description**
|:--|:--|:--
|`x`|Vector{`T2`}| x-direction magnetic field [nT]
|`y`|Vector{`T2`}| y-direction magnetic field [nT]
|`z`|Vector{`T2`}| z-direction magnetic field [nT]
|`t`|Vector{`T2`}| total magnetic field [nT]
"""
struct MagV{T2 <: AbstractFloat}
x :: Vector{T2}
y :: Vector{T2}
z :: Vector{T2}
t :: Vector{T2}
end # struct MagV
"""
Path{T1 <: Signed, T2 <: AbstractFloat} <: Path{T1, T2}

Abstract type `Path` for a flight path.
"""
abstract type Path{T1 <: Signed, T2 <: AbstractFloat} end
"""
Traj{T1 <: Signed, T2 <: AbstractFloat}

Trajectory struct, i.e., GPS or other truth flight data. Subtype of `Path`.

|**Field**|**Type**|**Description**
|:--|:--|:--
|`N`  |`T1`         | number of samples (instances)
|`dt` |`T2`         | measurement time step [s]
|`tt` |Vector{`T2`} | time [s]
|`lat`|Vector{`T2`} | latitude  [rad]
|`lon`|Vector{`T2`} | longitude [rad]
|`alt`|Vector{`T2`} | altitude  [m]
|`vn` |Vector{`T2`} | north velocity [m/s]
|`ve` |Vector{`T2`} | east  velocity [m/s]
|`vd` |Vector{`T2`} | down  velocity [m/s]
|`fn` |Vector{`T2`} | north specific force [m/s]
|`fe` |Vector{`T2`} | east  specific force [m/s]
|`fd` |Vector{`T2`} | down  specific force [m/s]
|`Cnb`|Array{`T2,3`}| `3` x `3` x `N` direction cosine matrix (body to navigation) [-]
"""
struct Traj{T1 <: Signed, T2 <: AbstractFloat} <: Path{T1, T2}
N   :: T1
dt  :: T2
tt  :: Vector{T2}
lat :: Vector{T2}
lon :: Vector{T2}
alt :: Vector{T2}
vn  :: Vector{T2}
ve  :: Vector{T2}
vd  :: Vector{T2}
fn  :: Vector{T2}
fe  :: Vector{T2}
fd  :: Vector{T2}
Cnb :: Array{T2,3}
end # struct Traj

"""
INS{T1 <: Signed, T2 <: AbstractFloat} <: Path{T1, T2}

Inertial navigation system (INS) struct. Subtype of `Path`.

|**Field**|**Type**|**Description**
|:--|:--|:--
|`N`  |`T1`         | number of samples (instances)
|`dt` |`T2`         | measurement time step [s]
|`tt` |Vector{`T2`} | time [s]
|`lat`|Vector{`T2`} | latitude  [rad]
|`lon`|Vector{`T2`} | longitude [rad]
|`alt`|Vector{`T2`} | altitude  [m]
|`vn` |Vector{`T2`} | north velocity [m/s]
|`ve` |Vector{`T2`} | east  velocity [m/s]
|`vd` |Vector{`T2`} | down  velocity [m/s]
|`fn` |Vector{`T2`} | north specific force [m/s]
|`fe` |Vector{`T2`} | east  specific force [m/s]
|`fd` |Vector{`T2`} | down  specific force [m/s]
|`Cnb`|Array{`T2,3`}| `3` x `3` x `N` direction cosine matrix (body to navigation) [-]
|`P`  |Array{`T2,3`}| `17` x `17` x `N` covariance matrix, only relevant for simulated data, otherwise zeros [-]
"""
struct INS{T1 <: Signed, T2 <: AbstractFloat} <: Path{T1, T2}
N   :: T1
dt  :: T2
tt  :: Vector{T2}
lat :: Vector{T2}
lon :: Vector{T2}
alt :: Vector{T2}
vn  :: Vector{T2}
ve  :: Vector{T2}
vd  :: Vector{T2}
fn  :: Vector{T2}
fe  :: Vector{T2}
fd  :: Vector{T2}
Cnb :: Array{T2,3}
P   :: Array{T2,3}
end # struct INS


"""
    XYZ{T1 <: Signed, T2 <: AbstractFloat}

Abstract type `XYZ` for flight data. Simplest subtype is `XYZ0`.
"""
abstract type XYZ{T1 <: Signed, T2 <: AbstractFloat} end

"""
    XYZ0{T1 <: Signed, T2 <: AbstractFloat} <: XYZ{T1, T2}

Subtype of `XYZ` containing the minimum dataset required for MagNav.

|**Field**|**Type**|**Description**
|:--|:--|:--
|`info`    |String         | dataset information
|`traj`    |Traj{`T1`,`T2`}| trajectory struct
|`ins`     |INS{`T1`,`T2`} | inertial navigation system struct
|`flux_a`  |MagV{`T2`}     | Flux A vector magnetometer measurement struct
|`flight`  |Vector{`T2`}   | flight number(s)
|`line`    |Vector{`T2`}   | line number(s), i.e., segments within `flight`
|`year`    |Vector{`T2`}   | year
|`doy`     |Vector{`T2`}   | day of year
|`diurnal` |Vector{`T2`}   | measured diurnal, i.e., temporal variations or space weather effects [nT]
|`igrf`    |Vector{`T2`}   | International Geomagnetic Reference Field (IGRF), i.e., core field [nT]
|`mag_1_c` |Vector{`T2`}   | Mag 1 compensated (clean) scalar magnetometer measurements [nT]
|`mag_1_uc`|Vector{`T2`}   | Mag 1 uncompensated (corrupted) scalar magnetometer measurements [nT]
"""
struct XYZ0{T1 <: Signed, T2 <: AbstractFloat} <: XYZ{T1, T2}
    info     :: String
    traj     :: Traj{T1,T2}
    ins      :: INS{T1,T2}
    flux_a   :: MagV{T2}
    flight   :: Vector{T2}
    line     :: Vector{T2}
    year     :: Vector{T2}
    doy      :: Vector{T2}
    diurnal  :: Vector{T2}
    igrf     :: Vector{T2}
    mag_1_c  :: Vector{T2}
    mag_1_uc :: Vector{T2}
end # struct XYZ0

"""
    XYZ1{T1 <: Signed, T2 <: AbstractFloat} <: XYZ{T1, T2}

Subtype of `XYZ` containing a flexible dataset for future use. NaNs may be
used in place of any unused fields (e.g., `aux_3`) when creating struct.

|**Field**|**Type**|**Description**
|:--|:--|:--
|`info`    |String         | dataset information
|`traj`    |Traj{`T1`,`T2`}| trajectory struct
|`ins`     |INS{`T1`,`T2`} | inertial navigation system struct
|`flux_a`  |MagV{`T2`}     | Flux A vector magnetometer measurement struct
|`flux_b`  |MagV{`T2`}     | Flux B vector magnetometer measurement struct
|`flight`  |Vector{`T2`}   | flight number(s)
|`line`    |Vector{`T2`}   | line number(s), i.e., segments within `flight`
|`year`    |Vector{`T2`}   | year
|`doy`     |Vector{`T2`}   | day of year
|`diurnal` |Vector{`T2`}   | measured diurnal, i.e., temporal variations or space weather effects [nT]
|`igrf`    |Vector{`T2`}   | International Geomagnetic Reference Field (IGRF), i.e., core field [nT]
|`mag_1_c` |Vector{`T2`}   | Mag 1 compensated (clean) scalar magnetometer measurements [nT]
|`mag_2_c` |Vector{`T2`}   | Mag 2 compensated (clean) scalar magnetometer measurements [nT]
|`mag_3_c` |Vector{`T2`}   | Mag 3 compensated (clean) scalar magnetometer measurements [nT]
|`mag_1_uc`|Vector{`T2`}   | Mag 1 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`mag_2_uc`|Vector{`T2`}   | Mag 2 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`mag_3_uc`|Vector{`T2`}   | Mag 3 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`aux_1`   |Vector{`T2`}   | flexible-use auxiliary data 1
|`aux_2`   |Vector{`T2`}   | flexible-use auxiliary data 2
|`aux_3`   |Vector{`T2`}   | flexible-use auxiliary data 3
"""
struct XYZ1{T1 <: Signed, T2 <: AbstractFloat} <: XYZ{T1, T2}
    info     :: String
    traj     :: Traj{T1,T2}
    ins      :: INS{T1,T2}
    flux_a   :: MagV{T2}
    flux_b   :: MagV{T2}
    flight   :: Vector{T2}
    line     :: Vector{T2}
    year     :: Vector{T2}
    doy      :: Vector{T2}
    diurnal  :: Vector{T2}
    igrf     :: Vector{T2}
    mag_1_c  :: Vector{T2}
    mag_2_c  :: Vector{T2}
    mag_3_c  :: Vector{T2}
    mag_1_uc :: Vector{T2}
    mag_2_uc :: Vector{T2}
    mag_3_uc :: Vector{T2}
    aux_1    :: Vector{T2}
    aux_2    :: Vector{T2}
    aux_3    :: Vector{T2}
end # struct XYZ1

"""
    XYZ20{T1 <: Signed, T2 <: AbstractFloat} <: XYZ{T1, T2}

Subtype of `XYZ` for 2020 SGL datasets.

|**Field**|**Type**|**Description**
|:--|:--|:--
|`info`      |String         | dataset information
|`traj`      |Traj{`T1`,`T2`}| trajectory struct
|`ins`       |INS{`T1`,`T2`} | inertial navigation system struct
|`flux_a`    |MagV{`T2`}     | Flux A vector magnetometer measurement struct
|`flux_b`    |MagV{`T2`}     | Flux B vector magnetometer measurement struct
|`flux_c`    |MagV{`T2`}     | Flux C vector magnetometer measurement struct
|`flux_d`    |MagV{`T2`}     | Flux D vector magnetometer measurement struct
|`flight`    |Vector{`T2`}   | flight number(s)
|`line`      |Vector{`T2`}   | line number(s), i.e., segments within `flight`
|`year`      |Vector{`T2`}   | year
|`doy`       |Vector{`T2`}   | day of year
|`utm_x`     |Vector{`T2`}   | x-coordinate, WGS-84 UTM zone 18N [m]
|`utm_y`     |Vector{`T2`}   | y-coordinate, WGS-84 UTM zone 18N [m]
|`utm_z`     |Vector{`T2`}   | z-coordinate, GPS altitude above WGS-84 ellipsoid [m]
|`msl`       |Vector{`T2`}   | z-coordinate, GPS altitude above EGM2008 Geoid [m]
|`baro`      |Vector{`T2`}   | barometric altimeter [m]
|`diurnal`   |Vector{`T2`}   | measured diurnal, i.e., temporal variations or space weather effects [nT]
|`igrf`      |Vector{`T2`}   | International Geomagnetic Reference Field (IGRF), i.e., core field [nT]
|`mag_1_c`   |Vector{`T2`}   | Mag 1 compensated (clean) scalar magnetometer measurements [nT]
|`mag_1_lag` |Vector{`T2`}   | Mag 1 lag-corrected scalar magnetometer measurements [nT]
|`mag_1_dc`  |Vector{`T2`}   | Mag 1 diurnal-corrected scalar magnetometer measurements [nT]
|`mag_1_igrf`|Vector{`T2`}   | Mag 1 IGRF & diurnal-corrected scalar magnetometer measurements [nT]
|`mag_1_uc`  |Vector{`T2`}   | Mag 1 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`mag_2_uc`  |Vector{`T2`}   | Mag 2 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`mag_3_uc`  |Vector{`T2`}   | Mag 3 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`mag_4_uc`  |Vector{`T2`}   | Mag 4 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`mag_5_uc`  |Vector{`T2`}   | Mag 5 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`mag_6_uc`  |Vector{`T2`}   | Mag 6 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`ogs_mag`   |Vector{`T2`}   | OGS survey diurnal-corrected, levelled, magnetic field [nT]
|`ogs_alt`   |Vector{`T2`}   | OGS survey, GPS altitude (WGS-84) [m]
|`ins_wander`|Vector{`T2`}   | INS-computed wander angle (ccw from north) [rad]
|`ins_roll`  |Vector{`T2`}   | INS-computed aircraft roll [deg]
|`ins_pitch` |Vector{`T2`}   | INS-computed aircraft pitch [deg]
|`ins_yaw`   |Vector{`T2`}   | INS-computed aircraft yaw [deg]
|`roll_rate` |Vector{`T2`}   | avionics-computed roll rate [deg/s]
|`pitch_rate`|Vector{`T2`}   | avionics-computed pitch rate [deg/s]
|`yaw_rate`  |Vector{`T2`}   | avionics-computed yaw rate [deg/s]
|`ins_acc_x` |Vector{`T2`}   | INS x-acceleration [m/s^2]
|`ins_acc_y` |Vector{`T2`}   | INS y-acceleration [m/s^2]
|`ins_acc_z` |Vector{`T2`}   | INS z-acceleration [m/s^2]
|`lgtl_acc`  |Vector{`T2`}   | avionics-computed longitudinal (forward) acceleration [g]
|`ltrl_acc`  |Vector{`T2`}   | avionics-computed lateral (starboard) acceleration [g]
|`nrml_acc`  |Vector{`T2`}   | avionics-computed normal (vertical) acceleration [g]
|`pitot_p`   |Vector{`T2`}   | avionics-computed pitot pressure [kPa]
|`static_p`  |Vector{`T2`}   | avionics-computed static pressure [kPa]
|`total_p`   |Vector{`T2`}   | avionics-computed total pressure [kPa]
|`cur_com_1` |Vector{`T2`}   | current sensor: aircraft radio 1 [A]
|`cur_ac_hi` |Vector{`T2`}   | current sensor: air conditioner fan high [A]
|`cur_ac_lo` |Vector{`T2`}   | current sensor: air conditioner fan low [A]
|`cur_tank`  |Vector{`T2`}   | current sensor: cabin fuel pump [A]
|`cur_flap`  |Vector{`T2`}   | current sensor: flap motor [A]
|`cur_strb`  |Vector{`T2`}   | current sensor: strobe lights [A]
|`cur_srvo_o`|Vector{`T2`}   | current sensor: INS outer servo [A]
|`cur_srvo_m`|Vector{`T2`}   | current sensor: INS middle servo [A]
|`cur_srvo_i`|Vector{`T2`}   | current sensor: INS inner servo [A]
|`cur_heat`  |Vector{`T2`}   | current sensor: INS heater [A]
|`cur_acpwr` |Vector{`T2`}   | current sensor: aircraft power [A]
|`cur_outpwr`|Vector{`T2`}   | current sensor: system output power [A]
|`cur_bat_1` |Vector{`T2`}   | current sensor: battery 1 [A]
|`cur_bat_2` |Vector{`T2`}   | current sensor: battery 2 [A]
|`vol_acpwr` |Vector{`T2`}   | voltage sensor: aircraft power [V]
|`vol_outpwr`|Vector{`T2`}   | voltage sensor: system output power [V]
|`vol_bat_1` |Vector{`T2`}   | voltage sensor: battery 1 [V]
|`vol_bat_2` |Vector{`T2`}   | voltage sensor: battery 2 [V]
|`vol_res_p` |Vector{`T2`}   | voltage sensor: resolver board (+) [V]
|`vol_res_n` |Vector{`T2`}   | voltage sensor: resolver board (-) [V]
|`vol_back_p`|Vector{`T2`}   | voltage sensor: backplane (+) [V]
|`vol_back_n`|Vector{`T2`}   | voltage sensor: backplane (-) [V]
|`vol_gyro_1`|Vector{`T2`}   | voltage sensor: gyroscope 1 [V]
|`vol_gyro_2`|Vector{`T2`}   | voltage sensor: gyroscope 2 [V]
|`vol_acc_p` |Vector{`T2`}   | voltage sensor: INS accelerometers (+) [V]
|`vol_acc_n` |Vector{`T2`}   | voltage sensor: INS accelerometers (-) [V]
|`vol_block` |Vector{`T2`}   | voltage sensor: block [V]
|`vol_back`  |Vector{`T2`}   | voltage sensor: backplane [V]
|`vol_srvo`  |Vector{`T2`}   | voltage sensor: servos [V]
|`vol_cabt`  |Vector{`T2`}   | voltage sensor: cabinet [V]
|`vol_fan`   |Vector{`T2`}   | voltage sensor: cooling fan [V]
|`aux_1`     |Vector{`T2`}   | flexible-use auxiliary data 1
|`aux_2`     |Vector{`T2`}   | flexible-use auxiliary data 2
|`aux_3`     |Vector{`T2`}   | flexible-use auxiliary data 3
"""
struct XYZ20{T1 <: Signed, T2 <: AbstractFloat} <: XYZ{T1, T2}
    info       :: String
    traj       :: Traj{T1,T2}
    ins        :: INS{T1,T2}
    flux_a     :: MagV{T2}
    flux_b     :: MagV{T2}
    flux_c     :: MagV{T2}
    flux_d     :: MagV{T2}
    flight     :: Vector{T2}
    line       :: Vector{T2}
    year       :: Vector{T2}
    doy        :: Vector{T2}
    utm_x      :: Vector{T2}
    utm_y      :: Vector{T2}
    utm_z      :: Vector{T2}
    msl        :: Vector{T2}
    baro       :: Vector{T2}
    diurnal    :: Vector{T2}
    igrf       :: Vector{T2}
    mag_1_c    :: Vector{T2}
    mag_1_lag  :: Vector{T2}
    mag_1_dc   :: Vector{T2}
    mag_1_igrf :: Vector{T2}
    mag_1_uc   :: Vector{T2}
    mag_2_uc   :: Vector{T2}
    mag_3_uc   :: Vector{T2}
    mag_4_uc   :: Vector{T2}
    mag_5_uc   :: Vector{T2}
    mag_6_uc   :: Vector{T2}
    ogs_mag    :: Vector{T2}
    ogs_alt    :: Vector{T2}
    ins_wander :: Vector{T2}
    ins_roll   :: Vector{T2}
    ins_pitch  :: Vector{T2}
    ins_yaw    :: Vector{T2}
    roll_rate  :: Vector{T2}
    pitch_rate :: Vector{T2}
    yaw_rate   :: Vector{T2}
    ins_acc_x  :: Vector{T2}
    ins_acc_y  :: Vector{T2}
    ins_acc_z  :: Vector{T2}
    lgtl_acc   :: Vector{T2}
    ltrl_acc   :: Vector{T2}
    nrml_acc   :: Vector{T2}
    pitot_p    :: Vector{T2}
    static_p   :: Vector{T2}
    total_p    :: Vector{T2}
    cur_com_1  :: Vector{T2}
    cur_ac_hi  :: Vector{T2}
    cur_ac_lo  :: Vector{T2}
    cur_tank   :: Vector{T2}
    cur_flap   :: Vector{T2}
    cur_strb   :: Vector{T2}
    cur_srvo_o :: Vector{T2}
    cur_srvo_m :: Vector{T2}
    cur_srvo_i :: Vector{T2}
    cur_heat   :: Vector{T2}
    cur_acpwr  :: Vector{T2}
    cur_outpwr :: Vector{T2}
    cur_bat_1  :: Vector{T2}
    cur_bat_2  :: Vector{T2}
    vol_acpwr  :: Vector{T2}
    vol_outpwr :: Vector{T2}
    vol_bat_1  :: Vector{T2}
    vol_bat_2  :: Vector{T2}
    vol_res_p  :: Vector{T2}
    vol_res_n  :: Vector{T2}
    vol_back_p :: Vector{T2}
    vol_back_n :: Vector{T2}
    vol_gyro_1 :: Vector{T2}
    vol_gyro_2 :: Vector{T2}
    vol_acc_p  :: Vector{T2}
    vol_acc_n  :: Vector{T2}
    vol_block  :: Vector{T2}
    vol_back   :: Vector{T2}
    vol_srvo   :: Vector{T2}
    vol_cabt   :: Vector{T2}
    vol_fan    :: Vector{T2}
    aux_1      :: Vector{T2}
    aux_2      :: Vector{T2}
    aux_3      :: Vector{T2}
end # struct XYZ20

"""
    XYZ21{T1 <: Signed, T2 <: AbstractFloat} <: XYZ{T1, T2}

Subtype of `XYZ` for 2021 SGL datasets.

|**Field**|**Type**|**Description**
|:--|:--|:--
|`info`      |String         | dataset information
|`traj`      |Traj{`T1`,`T2`}| trajectory struct
|`ins`       |INS{`T1`,`T2`} | inertial navigation system struct
|`flux_a`    |MagV{`T2`}     | Flux A vector magnetometer measurement struct
|`flux_b`    |MagV{`T2`}     | Flux B vector magnetometer measurement struct
|`flux_c`    |MagV{`T2`}     | Flux C vector magnetometer measurement struct
|`flux_d`    |MagV{`T2`}     | Flux D vector magnetometer measurement struct
|`flight`    |Vector{`T2`}   | flight number(s)
|`line`      |Vector{`T2`}   | line number(s), i.e., segments within `flight`
|`year`      |Vector{`T2`}   | year
|`doy`       |Vector{`T2`}   | day of year
|`utm_x`     |Vector{`T2`}   | x-coordinate, WGS-84 UTM zone 18N [m]
|`utm_y`     |Vector{`T2`}   | y-coordinate, WGS-84 UTM zone 18N [m]
|`utm_z`     |Vector{`T2`}   | z-coordinate, GPS altitude above WGS-84 ellipsoid [m]
|`msl`       |Vector{`T2`}   | z-coordinate, GPS altitude above EGM2008 Geoid [m]
|`baro`      |Vector{`T2`}   | barometric altimeter [m]
|`diurnal`   |Vector{`T2`}   | measured diurnal, i.e., temporal variations or space weather effects [nT]
|`igrf`      |Vector{`T2`}   | International Geomagnetic Reference Field (IGRF), i.e., core field [nT]
|`mag_1_c`   |Vector{`T2`}   | Mag 1 compensated (clean) scalar magnetometer measurements [nT]
|`mag_1_uc`  |Vector{`T2`}   | Mag 1 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`mag_2_uc`  |Vector{`T2`}   | Mag 2 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`mag_3_uc`  |Vector{`T2`}   | Mag 3 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`mag_4_uc`  |Vector{`T2`}   | Mag 4 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`mag_5_uc`  |Vector{`T2`}   | Mag 5 uncompensated (corrupted) scalar magnetometer measurements [nT]
|`cur_com_1` |Vector{`T2`}   | current sensor: aircraft radio 1 [A]
|`cur_ac_hi` |Vector{`T2`}   | current sensor: air conditioner fan high [A]
|`cur_ac_lo` |Vector{`T2`}   | current sensor: air conditioner fan low [A]
|`cur_tank`  |Vector{`T2`}   | current sensor: cabin fuel pump [A]
|`cur_flap`  |Vector{`T2`}   | current sensor: flap motor [A]
|`cur_strb`  |Vector{`T2`}   | current sensor: strobe lights [A]
|`vol_block` |Vector{`T2`}   | voltage sensor: block [V]
|`vol_back`  |Vector{`T2`}   | voltage sensor: backplane [V]
|`vol_cabt`  |Vector{`T2`}   | voltage sensor: cabinet [V]
|`vol_fan`   |Vector{`T2`}   | voltage sensor: cooling fan [V]
|`aux_1`     |Vector{`T2`}   | flexible-use auxiliary data 1
|`aux_2`     |Vector{`T2`}   | flexible-use auxiliary data 2
|`aux_3`     |Vector{`T2`}   | flexible-use auxiliary data 3
"""
struct XYZ21{T1 <: Signed, T2 <: AbstractFloat} <: XYZ{T1, T2}
    info       :: String
    traj       :: Traj{T1,T2}
    ins        :: INS{T1,T2}
    flux_a     :: MagV{T2}
    flux_b     :: MagV{T2}
    flux_c     :: MagV{T2}
    flux_d     :: MagV{T2}
    flight     :: Vector{T2}
    line       :: Vector{T2}
    year       :: Vector{T2}
    doy        :: Vector{T2}
    utm_x      :: Vector{T2}
    utm_y      :: Vector{T2}
    utm_z      :: Vector{T2}
    msl        :: Vector{T2}
    baro       :: Vector{T2}
    diurnal    :: Vector{T2}
    igrf       :: Vector{T2}
    mag_1_c    :: Vector{T2}
    mag_1_uc   :: Vector{T2}
    mag_2_uc   :: Vector{T2}
    mag_3_uc   :: Vector{T2}
    mag_4_uc   :: Vector{T2}
    mag_5_uc   :: Vector{T2}
    cur_com_1  :: Vector{T2}
    cur_ac_hi  :: Vector{T2}
    cur_ac_lo  :: Vector{T2}
    cur_tank   :: Vector{T2}
    cur_flap   :: Vector{T2}
    cur_strb   :: Vector{T2}
    vol_block  :: Vector{T2}
    vol_back   :: Vector{T2}
    vol_cabt   :: Vector{T2}
    vol_fan    :: Vector{T2}
    aux_1      :: Vector{T2}
    aux_2      :: Vector{T2}
    aux_3      :: Vector{T2}
end # struct XYZ21


"""
    sgl_fields(f::Union{String,Symbol} = "")

Data fields in SGL flight data collections, contains:
- `fields_sgl_2020.csv`
- `fields_sgl_2021.csv`
- `fields_sgl_160.csv`

**Arguments:**
- `f`: (optional) name of data file (`.csv` extension optional)

**Returns:**
- `p`: path of folder or `f` data file
"""
function sgl_fields(f = "")
    p = joinpath(artifact"sgl_fields","sgl_fields")
    d = "$f"
    !isempty(d) && (p = joinpath(p,add_extension(d,".csv")))
    return (p)
end # function sgl_fields


