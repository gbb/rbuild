#!/bin/bash

set -e

# check for dependencies

function dep_check {

DEPS=(
gdaladdo 
gdal_merge.py
gdaladdo
gdal_trace_outline
gdalinfo
psql
python
)

echo 'Checking for necessary software: '

for i in "${DEPS[@]}";  do 

  if ! (which $i >/dev/null) ; then
    echo -n 'FAILED!' $i ': SOFTWARE MISSING!' 
    please_install
  else
    echo -n 'OK! ' $i ' - found at: '
    echo $(which $i)
  fi

done; 


}

function check_gdal_version {

# GDAL is the most essential program so it is tested directly here:

GDAL_MAJOR_VERSION=$(gdalinfo --version | cut -f 2 -d ' '| cut -f 1 -d '.')
GDAL_MINOR_VERSION=$(gdalinfo --version | cut -f 2 -d ' '| cut -f 2 -d '.')

if [[ "$GDAL_MAJOR_VERSION" -gt 1 ]] || [[ "$GDAL_MINOR_VERSION" -gt 8 ]]; then
    # test for GDAL 2.0 or GDAL 1.9/1.10
    echo -n 'OK!  GDAL version looks OK. Version is: '
    gdalinfo --version
else
    echo -n 'FAILED! GDAL version out of date, please update? Version is: '
    gdalinfo --version
fi

}

function please_install {  

echo 'To use rbuild, please make sure you have installed the following:'
echo '' 
echo 'GDAL v1.9	or higher, (preferably 1.10), with Python/SWIG extensions'
echo 'Postgresql v9.0 or higher, (preferably 9.2+)'
echo 'PostGIS v2.0 or higher (preferably 2.1+) (if outputting raster to db)'
echo 'Gnu Parallel (preferably 022013 onwards)'
echo "Dan's GDAL scripts: https://github.com/gina-alaska/dans-gdal-scripts"
echo 'Python 2.7 or higher (untested with 3.0+)'
echo 'Numpy 1.7 or higher'
echo 'Also, please check that PostGIS 2.0 has been fully installed on '
echo 'the database you are using. It needs both system and db installation'
}



# psql: don't test a connect; user may not have configured DB yet


dep_check;
check_gdal_version;
