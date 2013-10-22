#!/bin/bash

# rbuild.sh
# A workflow/build system to build various raster-related outputs. 
# GBB 07/2013   <grb@skogoglandskap.no>

RBUILD_VERSION="2.0"

# The purpose of this system is to set up all environment variables
# and most of the configuration strings that are used by various GDAL programs.
# Then, to run whichever tasks are specified in the build file. 
# It build tiles in parallel across regions of norway and joins up the  
# pieces afterwards. 

# The key problems this script is intended to overcome are:
# 1. There are several stages involved in building the final raster map from geometry.
# 2. There are a huge number of parameters to set. These need to be managed better than 
# simply having giant command line calls. It's also helpful to manage them in groups.
# 3. Some standard programs don't work as well as they should.
# e.g. gdal_merge.py (Python) is *much* faster than gdalwarp (C++)
# e.g. Dan's GDAL tools has a better polygonizer with smoothing than gdal_polygonize.py
# e.g. gdal_rasterize / calc don't work well on large complex maps. 

# You must provide this program with build files that specify the options to be used.
# You can split the options into groups within different build files.
# The program will check that all necessary options are present before beginning.
# It is also possible to override some features with command line options.

# Parameter groups: these are imported from build files and can be overridden at the command line.
# See program/misc_functions.sh

# Example usage:
# ./rbuild
# ./rbuild -h
# ./rbuild -f bf/test.bf
# ./rbuild -f bf/test.bf -f bf/default/smallfile.bf -p NO -n "New_name_test_without_polygonize"
# See 'bf/default.bf' for more information. A 'bf' file tells rbuild how to build the map. 

# Enable 'stop on error' mode in bash
set -e

BUILD_PARAM=(WORK_CLEAN  OUTPUT_CLEAN RASTERIZE SOURCE_MERGE SOURCE_OVERVIEW SOURCE_POLYGONIZE RULES_APPLY
	     RESULT_MERGE RESULT_OVERVIEW RESULT_POLYGONIZE DESCRIBE POSTGIS_RASTER_IMPORT POSTGIS_GEOMETRY_IMPORT DELETE)

# Note: DESCRIBE comes before IMPORT because the output of DESCRIBE is used for IMPORT.

DIR_PARAM=(BUILD_NAME)

COMPRESS_PARAM=(WORKING_COMPRESSOR FINAL_COMPRESSOR WORKING_PREDICTOR FINAL_PREDICTOR 
       WORKING_ZLEVEL FINAL_ZLEVEL TILED BIGTIFF RENDER_TYPE RESULT_TYPE)

GENERAL_PARAM=(MAX_THREADS NODATA RESULT_NODATA GDAL_CACHEMAX OPTIONAL_RASTER_FLAGS 
      POLYGONIZE_FLAGS GDAL_OVERVIEWS PGR_OVERVIEWS OVERVIEW_SETTINGS RULE_FORMULA OUTPUT_AS_TILES
      POLYGONIZE_SUFFIX BUILD_DESCRIPTION RULE_METADATA)

MAP_PARAM=(SRID XMIN XMAX YMIN YMAX MAP_X_TILES MAP_Y_TILES XM YM BURN_TABLES GEOMETRY_COLUMN)

OUTPUT_PARAM=(STORAGE_DIR OPTIONAL_OUTPUT_DB_HOST OUTPUT_DB_DBNAME OUTPUT_DB_USERNAME OUTPUT_GEOMETRY_SCHEMA OUTPUT_RASTER_SCHEMA)

# N.B. MAP_PARAM: It is assumed that all maps are to be projected within the same raster coordinate system/extent.

# Join all the parameters into a giant array to be checked later.
PARAMS=(${BUILD_PARAM[@]} ${DIR_PARAM[@]} ${GENERAL_PARAM[@]} ${MAP_PARAM[@]} ${COMPRESS_PARAM[@]} ${OUTPUT_PARAM[@]})

# Import program configuration settings.
. rbuild_settings.sh

# Import build functions and generic functions
. program/misc_functions.sh
. program/build_functions.sh


function main {

	# Import default buildfile settings.
	setup_defaults;

  # Get command line options, if any, and use them to overwrite some parameters.
	setup_parameters $@;

	calculate_configuration_strings; # these strings convert the parameters into command lines for GDAL (etc.)

  setup_output_directories;

  workflow;

}

function workflow {
# This function is guided by the 'BUILD_PARAM' array. Presently it does not check that
# the build actions the user has chosen are a sensible series of steps. 
# It also doesn't check that the target function has actually been defined, either. Be careful!

# Iterate through the BUILD_PARAM array, checking for values set to yes and calling those functions in order.
# Requires functions to be defined named according to the fields in the BUILD_PARAM array.
for RUN_STAGE in ${BUILD_PARAM[@]}; do 
  debug_echo "Stage $RUN_STAGE = ${!RUN_STAGE}"
  if [[ "${!RUN_STAGE}" == "YES" ]] ; then 
    if [[ $VERBOSE -gt 0 ]]; then echo "Starting $RUN_STAGE"; fi
    $RUN_STAGE 
    debug_echo "Ending $RUN_STAGE"
    fi
done

echo "Output files have been placed in $OUTPUT_DIR."

}



function setup_defaults {

	. $BUILDFILE_DIR/default.bf

}

main $@




# TODO: internationalise outputs into norwegian depending on locale setting.

