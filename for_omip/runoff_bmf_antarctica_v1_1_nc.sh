#!/bin/sh

set -e

dataorg=/work116/htsujino/SURF_FLUX/forcing
datanew=/work116/htsujino/SURF_FLUX/forcing

flin="${dataorg}/jra55-do-v1_1-river/runoff_Antarctica_Depoorter_BMF.gd"
flout="${datanew}/OMIP_DATA/JRA55-do-v1.1/runoff_antarctica_basal_melt_clim.15Dec2016.nc"
flctl="${datanew}/OMIP_DATA/JRA55-do-v1.1/runoff_antarctica_basal_melt_clim.ctl"

##############################
# if mask is written to file, l_mask_out = .true.
# and flibas with valid size must exist

l_mask_out=.false.
flibas="dummy.txt"

# for GrADs xdfopen

time_start="jan1900"
time_intv="1yr"

./grd2nc_g_revised<<EOF
&nml_grd2nc_g
 file_in="${flin}",
 file_out="${flout}",
 tuw="u"
 l_append_ext=.false.,
 cext="no",
 l_one_data=.true.,
 l_mask_out=${l_mask_out},
 l_space_2d=.true.,
 l_x_even=.true.,
 l_y_even=.true.,
 num_vars=1,
 num_var_out=1,
 lon_first=0.125d0,delta_lon=0.25d0,nlons=1440,l_lon_model=.true.,lon_units="degrees_east",
 lat_first=-89.875d0,delta_lat=0.25d0,nlats=720,l_lat_model=.true.,lat_units="degrees_north",
 zlev=0.0d0,,,
 nlvls=1,
 l_lev_model=.false.,
 lvl_units="m",
 i_ref_year=1900,
 i_ref_month=1,
 i_ref_day=1,
 i_ref_hour=0,
 i_ref_minute=0,
 i_ref_second=0,
 first_data_relative_to_ref=0.5d0,
 ibyear=1900,
 ieyear=1900,
 intv_indx=3,
 nrecs_per_year=1,
 nrecs_out=1,
 l_leap=.true.,
 file_basin="${flibas}",
 file_ctl="${flctl}"
 time_start="${time_start}"
 time_intv="${time_intv}"
 l_put_global_attributes=.true.
/
&nml_vars
 nth_place_tmp=1,
 vname_tmp='friver'
 vunit_tmp='kg/m2/sec',
 vlongname_tmp='Water flux into sea water from rivers'
 vstandardname_tmp='water_flux_into_sea_water_from_rivers'
 rconv_tmp=1.0,
 rmin_tmp=-9.99e33,
 rmax_tmp=9.99e33,
 undef_in_tmp=-9.99e33,
 undef_out_tmp=-9.99e33,
/
&nml_global_attributes
  global_attributes%title="Runoff from Antarctica of JRA55-do"
  global_attributes%institution="JMA Meteorological Research Institute"
  global_attributes%version="v1.1"
  global_attributes%comment="Climatological annual mean basal melt water flux from Antarctica based on Depoorter et al. (2013) Nature."
  global_attributes%fill_value="Fill value is -9.99e33"
/
EOF
