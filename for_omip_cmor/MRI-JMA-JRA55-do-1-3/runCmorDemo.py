import cmor,json,os
import cdms2 as cdm
import cdtime as cdt
import numpy as np
from calendar import isleap
#cdm.setAutoBounds('on') # Caution, this attempts to automatically set coordinate bounds - please check outputs using this option
#import pdb ; # Debug statement - import if enabling debugging below

# Notes
# PJD  5 Feb 2018   - Started
# PJD 21 Feb 2018   - Updated for CMOR3.3.1
# PJD 24 Feb 2018   - Updated paths for demo dir
# PJD  7 Mar 2018   - Updated pr to prra
# PJD  8 Mar 2018   - Correct prra 'positive'; Added ficeberg2d placeholder
# PJD  5 Apr 2018   - Update for latest variable list
#                   TODO: Fix missing_value assignment problem
#                     ---> Is this going to be fixed by setting missing_value to 1e20 for the inputFile?
#                          This has been done for JRA55-do-v1.3.1

#%% Create input decks for all variables - 'fileList' will need to be amended to include all files 1958-2018
inputDict = {}
inputDict['A3hr'] = {}
key = 'rain'
inputDict['A3hr'][key] = {}
inputDict['A3hr'][key]['fileList'] = [
        'testFiles/rain.2017.14Jan2018.nc', # All these 'fileList' entries will require updating to include all files to be processed
        'testFiles/rain.2018.14Jan2018.nc'
        ]
inputDict['A3hr'][key]['inputVarName'] = 'prrn'
inputDict['A3hr'][key]['outputVarName'] = 'prra' ; # Was pr
inputDict['A3hr'][key]['outputUnits'] = 'kg m-2 s-1'
inputDict['A3hr'][key]['positive'] = ''
key = 'snow'
inputDict['A3hr'][key] = {}
inputDict['A3hr'][key]['fileList'] = [
        'testFiles/snow.1978.18Oct2017.nc'
        ]
inputDict['A3hr'][key]['inputVarName'] = 'prsn'
inputDict['A3hr'][key]['outputVarName'] = 'prsn'
inputDict['A3hr'][key]['outputUnits'] = 'kg m-2 s-1'
inputDict['A3hr'][key]['positive'] = ''
key = 'rlds'
inputDict['A3hr'][key] = {}
inputDict['A3hr'][key]['fileList'] = [
        'testFiles/rlds.1996.18Oct2017.nc'
        ]
inputDict['A3hr'][key]['inputVarName'] = 'rlds'
inputDict['A3hr'][key]['outputVarName'] = 'rlds'
inputDict['A3hr'][key]['outputUnits'] = 'W m-2'
inputDict['A3hr'][key]['positive'] = 'down'
key = 'rsds'
inputDict['A3hr'][key] = {}
inputDict['A3hr'][key]['fileList'] = [
        'testFiles/rsds.1965.18Oct2017.nc'
        ]
inputDict['A3hr'][key]['inputVarName'] = 'rsds'
inputDict['A3hr'][key]['outputVarName'] = 'rsds'
inputDict['A3hr'][key]['outputUnits'] = 'W m-2'
inputDict['A3hr'][key]['positive'] = 'down'
inputDict['A3hrPt'] = {}
key = 'q_10'
inputDict['A3hrPt'][key] = {}
inputDict['A3hrPt'][key]['fileList'] = [
        'testFiles/q_10.1958.18Oct2017.nc'
        ]
inputDict['A3hrPt'][key]['inputVarName'] = 'huss_10m'
inputDict['A3hrPt'][key]['outputVarName'] = 'huss'
inputDict['A3hrPt'][key]['outputUnits'] = '1.0'
inputDict['A3hrPt'][key]['positive'] = ''
key = 'slp'
inputDict['A3hrPt'][key] = {}
inputDict['A3hrPt'][key]['fileList'] = [
        'testFiles/slp.2008.18Aug2017.nc'
        ]
inputDict['A3hrPt'][key]['inputVarName'] = 'psl'
inputDict['A3hrPt'][key]['outputVarName'] = 'psl'
inputDict['A3hrPt'][key]['outputUnits'] = 'Pa'
inputDict['A3hrPt'][key]['positive'] = ''
key = 't_10'
inputDict['A3hrPt'][key] = {}
inputDict['A3hrPt'][key]['fileList'] = [
        'testFiles/t_10.1987.18Oct2017.nc'
        ]
inputDict['A3hrPt'][key]['inputVarName'] = 'tas_10m'
inputDict['A3hrPt'][key]['outputVarName'] = 'tas'
inputDict['A3hrPt'][key]['outputUnits'] = 'K'
inputDict['A3hrPt'][key]['positive'] = ''
key = 'ts'
#inputDict['A3hrPt'][key] = {}
#inputDict['A3hrPt'][key]['fileList'] = [
#        ''
#        ]
#inputDict['A3hrPt'][key]['inputVarName'] = 'ts'
#inputDict['A3hrPt'][key]['outputVarName'] = 'ts'
#inputDict['A3hrPt'][key]['outputUnits'] = 'K'
#inputDict['A3hrPt'][key]['positive'] = ''
key = 'u_10'
inputDict['A3hrPt'][key] = {}
inputDict['A3hrPt'][key]['fileList'] = [
        'testFiles/u_10.1979.18Oct2017.nc'
        ]
inputDict['A3hrPt'][key]['inputVarName'] = 'uas_10m'
inputDict['A3hrPt'][key]['outputVarName'] = 'uas'
inputDict['A3hrPt'][key]['outputUnits'] = 'm s-1'
inputDict['A3hrPt'][key]['positive'] = ''
key = 'v_10'
inputDict['A3hrPt'][key] = {}
inputDict['A3hrPt'][key]['fileList'] = [
        'testFiles/v_10.1966.18Oct2017.nc'
        ]
inputDict['A3hrPt'][key]['inputVarName'] = 'vas_10m'
inputDict['A3hrPt'][key]['outputVarName'] = 'vas'
inputDict['A3hrPt'][key]['outputUnits'] = 'm s-1'
inputDict['A3hrPt'][key]['positive'] = ''
inputDict['LIyrC'] = {}
key = 'licalvf'
#inputDict['LIyrC'][key] = {}
#inputDict['LIyrC'][key]['fileList'] = [
#        ''
#        ]
#inputDict['LIyrC'][key]['inputVarName'] = 'licalvf'
#inputDict['LIyrC'][key]['outputVarName'] = 'licalvf'
#inputDict['LIyrC'][key]['outputUnits'] = 'kg m-2 s-1'
#inputDict['LIyrC'][key]['positive'] = ''
inputDict['Oday'] = {}
key = 'ficeberg2d'
#inputDict['Oday'][key] = {}
#inputDict['Oday'][key]['fileList'] = [
#        ''
#        ]
#inputDict['Oday'][key]['inputVarName'] = 'ficeberg'
#inputDict['Oday'][key]['outputVarName'] = 'ficeberg'
#inputDict['Oday'][key]['outputUnits'] = 'kg m-2 s-1'
#inputDict['Oday'][key]['positive'] = ''
key = 'runoff_all'
inputDict['Oday'][key] = {}
inputDict['Oday'][key]['fileList'] = [
        'testFiles/runoff_all.1962.15Dec2016.nc'
        ]
inputDict['Oday'][key]['inputVarName'] = 'friver'
inputDict['Oday'][key]['outputVarName'] = 'friver'
inputDict['Oday'][key]['outputUnits'] = 'kg m-2 s-1'
inputDict['Oday'][key]['positive'] = ''
key = 'tos'
#inputDict['Oday'][key] = {}
#inputDict['Oday'][key]['fileList'] = [
#        ''
#        ]
#inputDict['Oday'][key]['inputVarName'] = 'tos'
#inputDict['Oday'][key]['outputVarName'] = 'tos'
#inputDict['Oday'][key]['outputUnits'] = 'K'
#inputDict['Oday'][key]['positive'] = ''
inputDict['OmonC'] = {}
key = 's_u10a'
inputDict['OmonC'][key] = {}
inputDict['OmonC'][key]['fileList'] = [
        'testFiles/woa13_decav_s_0-10m.mon_01v2_filled.nc'
        ]
inputDict['OmonC'][key]['inputVarName'] = 's_u10a'
inputDict['OmonC'][key]['outputVarName'] = 'sos'
inputDict['OmonC'][key]['outputUnits'] = '0.001'
inputDict['OmonC'][key]['positive'] = ''
inputDict['OyrC'] = {}
key = 'uo'
#inputDict['OyrC'][key] = {}
#inputDict['OyrC'][key]['fileList'] = [
#        ''
#        ]
#inputDict['OyrC'][key]['inputVarName'] = 'uo'
#inputDict['OyrC'][key]['outputVarName'] = 'uo'
#inputDict['OyrC'][key]['outputUnits'] = 'm s-1'
#inputDict['OyrC'][key]['positive'] = ''
key = 'vo'
#inputDict['OyrC'][key] = {}
#inputDict['OyrC'][key]['fileList'] = [
#        ''
#        ]
#inputDict['OyrC'][key]['inputVarName'] = 'vo'
#inputDict['OyrC'][key]['outputVarName'] = 'vo'
#inputDict['OyrC'][key]['outputUnits'] = 'm s-1'
#inputDict['OyrC'][key]['positive'] = ''
inputDict['SI3hrPt'] = {}
key = 'siconca'
#inputDict['SI3hrPt'][key] = {}
#inputDict['SI3hrPt'][key]['fileList'] = [
#        ''
#        ]
#inputDict['SI3hrPt'][key]['inputVarName'] = 'siconca'
#inputDict['SI3hrPt'][key]['outputVarName'] = 'siconca'
#inputDict['SI3hrPt'][key]['outputUnits'] = '%'
#inputDict['SI3hrPt'][key]['positive'] = ''
inputDict['SIday'] = {}
key = 'siconco'
#inputDict['SIday'][key] = {}
#inputDict['SIday'][key]['fileList'] = [
#        ''
#        ]
#inputDict['SIday'][key]['inputVarName'] = 'siconco'
#inputDict['SIday'][key]['outputVarName'] = 'siconc'
#inputDict['SIday'][key]['outputUnits'] = '%'
#inputDict['SIday'][key]['positive'] = ''
# fixed in time
inputDict['Ofx'] = {}
key = 'areacello'
#inputDict['Ofx'][key] = {}
#inputDict['Ofx'][key]['fileList'] = [
#        'input_suppl/jra55_cell_area.10Apr2018.nc'
#        ]
#inputDict['Ofx'][key]['inputVarName'] = 'areacello'
#inputDict['Ofx'][key]['outputVarName'] = 'areacello'
#inputDict['Ofx'][key]['outputUnits'] = 'm2'
#inputDict['Ofx'][key]['positive'] = ''
key = 'sftof'
#inputDict['Ofx'][key] = {}
#inputDict['Ofx'][key]['fileList'] = [
#        'input_suppl/jra55_mask_sea.10Apr2018.nc'
#        ]
#inputDict['Ofx'][key]['inputVarName'] = 'sftof'
#inputDict['Ofx'][key]['outputVarName'] = 'sftof'
#inputDict['Ofx'][key]['outputUnits'] = '1'
#inputDict['Ofx'][key]['positive'] = ''
inputDict['LIfx'] = {}
key = 'areacellg'
#inputDict['LIfx'][key] = {}
#inputDict['LIfx'][key]['fileList'] = [
#        'input_suppl/runoff_cell_area.10Apr2018.nc'
#        ]
#inputDict['LIfx'][key]['inputVarName'] = 'areacellg'
#inputDict['LIfx'][key]['outputVarName'] = 'areacellg'
#inputDict['LIfx'][key]['outputUnits'] = 'm2'
#inputDict['LIfx'][key]['positive'] = ''

#%% Loop through entries and process file lists
for key in inputDict.keys():
    # User provided input
    cmorTable = ''.join(['Tables/input4MIPs_',key,'.json']) ; # Aday,Amon,Lmon,Omon,SImon,fx - Load target table, axis info (coordinates, grid*) and CVs
    cmorJson = json.load(open(cmorTable))
    inputJson = 'mriJRA55-do-input.json' ; # Update contents of this file to set your global_attributes
    newJson = json.load(open(inputJson))
    for var in inputDict[key].keys():
        outVar = inputDict[key][var]['outputVarName']
        # Update frequency based on variableand write output to CMOR input file
        newJson['frequency'] = cmorJson['variable_entry'][outVar]['frequency']
        json.dump(newJson,open('tmp.json','w'),ensure_ascii=True,encoding='utf-8',sort_keys=True)
        inputVarName = inputDict[key][var]['inputVarName']
        outputVarName = inputDict[key][var]['outputVarName']
        outputUnits = inputDict[key][var]['outputUnits']
        for count,filePath in enumerate(inputDict[key][var]['fileList']):
            print 'key,var:',key,var
            print 'filePath:',filePath
            print 'cmorTable:',cmorTable
            print 'inputVarName:',inputVarName
            print 'outputVarName:',outputVarName
            print 'outputUnits:',outputUnits
            # Open and read input netcdf file
            f = cdm.open(filePath)
            print 'Source data read start..'
            d = f(inputVarName) ; # Or use temporal subset for testing below
            #d = f(inputVarName,time=slice(0,5))
            print 'Source data read end..'
            # Reset missing value
            d.setMissing(1e20) ; # This should also set fill_value, and suppress CMOR variable history being written
            # Get axes
            lat = d.getLatitude()
            lon = d.getLongitude()
            if var in ['uo','vo']:
                lev = d.getLevel()
            time = d.getTime() ; # Assumes variable is named 'time', for the demo file this is named 'months'
            #time = d.getAxis(0) ; # Rather use a file dimension-based load

            #%% Initialize and run CMOR
            print 'Start CMORizing..'
            # For more information see https://cmor.llnl.gov/mydoc_cmor3_api/
            cmor.setup(inpath='./',netcdf_file_action=cmor.CMOR_REPLACE_4) #,logfile='cmorLog.txt')
            cmor.dataset_json('tmp.json')
            cmor.load_table(cmorTable)
            #cmor.set_cur_dataset_attribute('history',f.history) ; # Force input file attribute as history
            # Create axes based on variable
            if var in ['q_10','t_10']:
                # Reset height2m coordinate value to 10m
                heightAx = {'table_entry': 'height2m',
                            'units': 'm',
                            'coord_vals': cdm.createAxis([10.],id='height')
                            }
            elif var in ['u_10','v_10']:
                # Use height10m coordinate entry
                heightAx = {'table_entry': 'height10m',
                            'units': 'm',
                            'coord_vals': cdm.createAxis([10.],id='height')
                            }
            else:
                # Use height2m default value
                heightAx = {'table_entry': 'height2m',
                            'units': 'm',
                            'coord_vals': cdm.createAxis([2.],id='height')
                            }
            # Create time based on table
            if key == 'A3hrPt':
                timeAx = {'table_entry': 'time1',
                          'units': time.units
                         }
            elif key == 'SI3hrPt':
                timeAx = {'table_entry': 'time1',
                          'units': time.units
                         }
            elif key == 'OmonC':
                # Create climatological time axis for the WOA13 (1955-2012) temporal range
                times = [] ; times_bnds = []
                for count,months in enumerate(range(1,13)):
                    #print count,months
                    if months in [1,3,5,7,8,10,12]:
                        monthendday = 31
                        hrs = 12
                    elif months in [4,6,9,11]:
                        monthendday = 30
                        hrs = 0
                    elif isleap(int(1984)):
                        monthendday = 29
                        hrs = 12
                    else:
                        monthendday = 28
                        hrs = 0
                    times.append(cdt.componenttime(1984,months,np.int(monthendday/2.),hrs).torel('days since 1955-1-1').value)
                    # WOA13v2 extends from 1955 to 2012
#                    times_bnds.append([cdt.componenttime(1955,months,1,0,0,0).torel('days since 1955-1-1'),
#                                       cdt.componenttime(2012,months,monthendday,12,59,59).torel('days since 1955-1-1')])
                    if months < 12:
                        times_bnds.append([cdt.componenttime(1955,months,1,0,0,0).torel('days since 1955-1-1').value,
                                           cdt.componenttime(2012,months+1,1,0,0,0).torel('days since 1955-1-1').value])
                    else:
                        times_bnds.append([cdt.componenttime(1955,months,1,0,0,0).torel('days since 1955-1-1').value,
                                           cdt.componenttime(2013,1,1,0,0,0).torel('days since 1955-1-1').value])
                time = cdm.createAxis(times,np.array(times_bnds),id='time')
                time.units = 'days since 1955-01-01 0.0.0'
                timeAx = {'table_entry': 'time2',
                          'units': time.units,
                          'coord_vals': time
                         }
            elif key == 'OyrC':
                if var in ['uo','vo']:
                    # Create climatological time axis for the GlobCurrent (Nov1999-Oct2009) temporal range
                    times = [] ; times_bnds = []
                    times.append(cdt.componenttime(2004,10,31,12,0,0).torel('days since 1999-11-1').value)
                    times_bnds.append([cdt.componenttime(1999,11,1,0,0,0).torel('days since 1999-11-1').value,
                                       cdt.componenttime(2009,11,1,0,0,0).torel('days since 1999-11-1').value])
                    time = cdm.createAxis(times,np.array(times_bnds),id='time')
                    time.units = 'days since 1999-11-01 0.0.0'
                    print times[0]
                    print times_bnds[0]
                    print time
                    timeAx = {'table_entry': 'time2',
                              'units': time.units,
                              'coord_vals': time
                             }
            elif key == 'LIyrC':
                if var in ['licalvf']:
                    # Create climatological time axis for the Depoorter et al. (2013) (Jan2007-Dec2007) temporal range
                    times = [] ; times_bnds = []
                    times.append(cdt.componenttime(2007,7,2,12,0,0).torel('days since 2007-1-1').value)
                    times_bnds.append([cdt.componenttime(2007,1,1,0,0,0).torel('days since 2007-1-1').value,
                                       cdt.componenttime(2008,1,1,0,0,0).torel('days since 2007-1-1').value])
                    time = cdm.createAxis(times,np.array(times_bnds),id='time')
                    time.units = 'days since 2007-01-01 0.0.0'
                    print times[0]
                    print times_bnds[0]
                    print time
                    timeAx = {'table_entry': 'time2',
                              'units': time.units,
                              'coord_vals': time
                             }
            else:
                # Use default time entry
                timeAx = {'table_entry': 'time',
                          'units': time.units
                         }
            # Now set axes list based on variable
            if var in ['q_10','t_10','u_10','v_10']:
            # 4D variable - 4 axes
                axes    = [  timeAx,
                             heightAx,
                             {'table_entry': 'latitude',
                              'units': 'degrees_north',
                              'coord_vals': lat[:],
                              'cell_bounds': lat.getBounds()
                             },
                             {'table_entry': 'longitude',
                              'units': 'degrees_east',
                              'coord_vals': lon[:],
                              'cell_bounds': lon.getBounds()
                             },
                          ]
            elif var in ['uo','vo']:
            # 4D variable - 4 axes
                axes    = [  timeAx,
                             {'table_entry': 'depth_coord',
                              'units': 'm',
                              'coord_vals': lev[:],
                              'cell_bounds': lev.getBounds()
                             },
                             {'table_entry': 'latitude',
                              'units': 'degrees_north',
                              'coord_vals': lat[:],
                              'cell_bounds': lat.getBounds()
                             },
                             {'table_entry': 'longitude',
                              'units': 'degrees_east',
                              'coord_vals': lon[:],
                              'cell_bounds': lon.getBounds()
                             },
                          ]
            elif var in ['areacello','sftof','areacellg']:
            # 2D variable - 2 axes
                axes    = [  {'table_entry': 'latitude',
                              'units': 'degrees_north',
                              'coord_vals': lat[:],
                              'cell_bounds': lat.getBounds()
                             },
                             {'table_entry': 'longitude',
                              'units': 'degrees_east',
                              'coord_vals': lon[:],
                              'cell_bounds': lon.getBounds()
                             },
                          ]
            else:
            # 3D variable - 3 axes
                axes    = [  timeAx,
                             {'table_entry': 'latitude',
                              'units': 'degrees_north',
                              'coord_vals': lat[:],
                              'cell_bounds': lat.getBounds()
                             },
                             {'table_entry': 'longitude',
                              'units': 'degrees_east',
                              'coord_vals': lon[:],
                              'cell_bounds': lon.getBounds()
                             },
                          ]
            axisIds = list() ; # Create list of axes and build these for each variable from axis components above
            for axis in axes:
                axisId = cmor.axis(**axis)
                axisIds.append(axisId)

            # For use in debugging
            #print 'axes:',axes
            #print 'd.shape:',d.shape
            #print 'outputVarName:',outputVarName
            #print 'd.units:',d.units
            #print 'd.missing:',d.missing
            #pdb.set_trace() ; # Debug statement

            # Setup units and create variable to write using cmor - see https://cmor.llnl.gov/mydoc_cmor3_api/#cmor_set_variable_attribute
            d.units = outputUnits
            if inputDict[key][var]['positive'] == 'down':
                varid   = cmor.variable(outputVarName,d.units,axisIds,missing_value=d.missing,positive='down')
            else:
                varid   = cmor.variable(outputVarName,d.units,axisIds,missing_value=d.missing) ; # This is not trapping the correct missing_value
            values  = np.array(d[:],np.float32)

            # Append valid_min and valid_max to variable before writing - see https://cmor.llnl.gov/mydoc_cmor3_api/#cmor_set_variable_attribute
            #cmor.set_variable_attribute(varid,'valid_min','f',2.0)
            #cmor.set_variable_attribute(varid,'valid_max','f',3.0)

            # Prepare variable for writing, then write and close file - see https://cmor.llnl.gov/mydoc_cmor3_api/#cmor_set_variable_attribute
            cmor.set_deflate(varid,1,1,1) ; # shuffle=1,deflate=1,deflate_level=1 - Deflate options compress file data
            print 'Start CMOR write..'
            if key == 'OmonC':
                cmor.write(varid,values) ; # Write variable with time axis
            elif key == 'OyrC':  
                cmor.write(varid,values) ; # Write variable with time axis
            elif key == 'LIyrC':  
                cmor.write(varid,values) ; # Write variable with time axis
            elif key == 'Ofx':  
                cmor.write(varid,values) ; # Write variable without time axis
            elif key == 'LIfx':  
                cmor.write(varid,values) ; # Write variable without time axis
            else:
                cmor.write(varid,values,time_vals=time,time_bnds=time.getBounds()) ; # Write variable with time axis
            print 'End CMOR write..'
            # Alteratively write in append mode
            #for i in range(0,len(time),10):
            #    print i
            #    cmor.write(varid,values[i*10:(i+1)*10],time_vals=time[i*10:(i+1)*10],time_bnds=time.getBounds()[i*10:(i+1)*10]) ; # Write variable with time axis
            f.close()
            cmor.close()
        # Cleanup
        os.remove('tmp.json')
