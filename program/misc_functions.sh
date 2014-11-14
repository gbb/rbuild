# misc_functions.sh
# Miscellaneous helper functions for workflow.
# GBB 03/2013   <grb@skogoglandskap.no>



function checkpoint {
    debug_echo "checkpoint"
}


function debug_echo {

  # If we're in a very verbose mode, echo all arguments to stdout.
	if [[ $VERBOSE -gt 1 ]] ; then
		echo $@
	fi

}

function setup_output_directories {

  # Top-level directory to be used when building rasters / polygons.
  WORK_DIR=$STORAGE_DIR/render/$BUILD_NAME  
  mkdir -p $WORK_DIR   

  # Directory to be used to store final output (with datestamp).
  OUTPUT_DIR=$STORAGE_DIR/final/$BUILD_NAME
  mkdir -p $OUTPUT_DIR

  # Logfile for errors/messages.
  # TODO: obsolete?
  LOG=$WORK_DIR/logfile


}

function setup_parameters {
# Assumes that default build file is already imported. Allows user to import more buildfiles.
# Allows user to override build file parameters manually.
# don't forget ;; after each parameter.
debug_echo "now running: setup_parameters"

if [[ "$1" == "" ]]; then
  print_help
  exit
fi

while getopts hva:b:c:d:e:f:j:m:n:o:p:q:r:s:t:w: opt; do
  debug_echo "-$opt was supplied."
  case $opt in
    a)
      WORK_CLEAN=$OPTARG;
      OUTPUT_CLEAN=$OPTARG;
      ;;
    b)  
      RASTERIZE=$OPTARG;
      ;;
    c)
      RULES_APPLY=$OPTARG;
      ;;
    d)
      RESULT_MERGE=$OPTARG;
      ;;
    e)
      RESULT_OVERVIEW=$OPTARG;
      ;;
    f)
      if [[ ! -f $OPTARG ]]; then 
        echo "Build file $OPTARG does not exist."
        exit
      else
      	# import the build file into the scripting environment.
        . $OPTARG
        debug_echo "Importing $OPTARG"
	  fi
      ;;
    j)
      DESCRIBE=$OPTARG;
      ;; 
    m)
      SOURCE_MERGE=$OPTARG;
      ;; 
    n)
      BUILD_NAME=$OPTARG;
      ;;  
    o) 
      SOURCE_OVERVIEW=$OPTARG;
      ;;
    p)
      SOURCE_POLYGONIZE=$OPTARG;
      ;;
    q)
      RESULT_POLYGONIZE=$OPTARG;
      ;;
    r)
      POSTGIS_RASTER_IMPORT=$OPTARG;
      ;;
    s)
      POSTGIS_GEOMETRY_IMPORT=$OPTARG;
      ;;
    t)
      MAX_THREADS=$OPTARG;
      ;;
    w)
      DELETE=$OPTARG;
      ;;
    v)
      VERBOSE=2;
      # This should enable logging + also 'time' logging for each step (& also whole thing?). 
      ;;
    h)
      print_help
      exit
      ;;
    \?)
      echo "Invalid option specified: -$OPTARG" >&2
      exit
      ;;
      # TODO: internationalise this for norwegian. use MSG tags and pick up locale from env.
  esac
done

# NOTE: rem that 'merging source patches to single map' can happen at end. ditto polyg.

# load the default build file. This is a file called 'default.bf' in the rbuild directory.

debug_echo 'Command line flags parsed.'
print_params;
check_params;

START_DATETIME=$(date +"%c")
START_TIME=$(date +"%s")

}


function print_params {
  # Print out parameters and settings, if in debug/verbose mode.
  for PARAM in "${PARAMS[@]}"; do
    debug_echo "$PARAM = ${!PARAM}"
  done
}

function check_params {
  # check that all *required* parameters are non-empty.
  for PARAM in "${PARAMS[@]}"; do

  # If the parameter is not set and is not optional, warn.
  if [[ -z "${!PARAM}" ]] && [[ $PARAM != OPTIONAL* ]]; then
    echo "$PARAM has no value. You need to set $PARAM."
    exit 1
  fi
  done
}


function calculate_configuration_strings {
# Calculate strings of command line parameters to be used by GDAL and related programs.
debug_echo "calculate_configuration_strings"

GENERAL_COMPRESS_FLAGS="-co 'TILED=$TILED' -co 'BIGTIFF=$BIGTIFF' "    # was \". check

WORKING_SOURCE_COMPRESS_FLAGS=$GENERAL_COMPRESS_FLAGS" -co 'COMPRESS=$WORKING_COMPRESSOR' -co 'PREDICTOR=$WORKING_PREDICTOR' -co 'ZLEVEL=$WORKING_ZLEVEL' -ot $RENDER_TYPE "
WORKING_RESULT_COMPRESS_FLAGS=$GENERAL_COMPRESS_FLAGS" -co 'COMPRESS=$WORKING_COMPRESSOR' -co 'PREDICTOR=$WORKING_PREDICTOR' -co 'ZLEVEL=$WORKING_ZLEVEL' -ot $RESULT_TYPE "

# because gdalcalc uses --co instead of -co and -type instead of -ot. Why???
GDALCALC_COMPRESS_FLAGS="--co 'TILED=$TILED' --co 'BIGTIFF=$BIGTIFF' \
 --co 'COMPRESS=$WORKING_COMPRESSOR' --co 'PREDICTOR=$WORKING_PREDICTOR' --co 'ZLEVEL=$WORKING_ZLEVEL' --type $RESULT_TYPE "

FINAL_SOURCE_COMPRESS_FLAGS=$GENERAL_COMPRESS_FLAGS" -co 'COMPRESS=$FINAL_COMPRESSOR' -co 'PREDICTOR=$FINAL_PREDICTOR' -co 'ZLEVEL=$FINAL_ZLEVEL'  -ot $RENDER_TYPE "
FINAL_RESULT_COMPRESS_FLAGS=$GENERAL_COMPRESS_FLAGS" -co 'COMPRESS=$FINAL_COMPRESSOR' -co 'PREDICTOR=$FINAL_PREDICTOR' -co 'ZLEVEL=$FINAL_ZLEVEL'  -ot $RESULT_TYPE "

OVERVIEW_FLAGS="$OVERVIEW_SETTINGS $OVERVIEW_LEVELS"

GENERAL_RASTER_FLAGS="-tr $XM $YM -a_nodata $NODATA -a_srs 'EPSG:$SRID' --config GDAL_CACHEMAX $GDAL_CACHEMAX $WORKING_SOURCE_COMPRESS_FLAGS $OPTIONAL_RASTER_FLAGS"
# n.b. GDAL/OGR supports simple EPSG format. dans gdal tools does not. and postgis uses srid without EPSG clause.
#n.b. gdal_cachemax does not use an = sign and uses --config; it's a gdal option not a driver option. 
#n.b. add any options that are specified in the buildfile.

# Verbose/quiet modes, for gdaladdo, gdal_merge, gdal_rasterize
# Gdal_rasterize doesn't have a 'v' mode and its progress meter makes a mess of parallel's output. Hence, -q below.
if [[ $VERBOSE -gt 1 ]]; then 
  FINAL_SOURCE_COMPRESS_FLAGS=$FINAL_SOURCE_COMPRESS_FLAGS" -v ";
  FINAL_RESULT_COMPRESS_FLAGS=$FINAL_RESULT_COMPRESS_FLAGS" -v ";
  GENERAL_RASTER_FLAGS=$GENERAL_RASTER_FLAGS" -q "; 
else
  FINAL_SOURCE_COMPRESS_FLAGS=$FINAL_SOURCE_COMPRESS_FLAGS" -q ";
  FINAL_RESULT_COMPRESS_FLAGS=$FINAL_RESULT_COMPRESS_FLAGS" -q ";
  GENERAL_RASTER_FLAGS=$GENERAL_RASTER_FLAGS" -q "; 
fi

# All touched mode for GDAL rasterizing. See the buildfiles for explanation of how -at works.
if [[ $ALL_TOUCHED == "YES" ]]; then GENERAL_RASTER_FLAGS=$GENERAL_RASTER_FLAGS" -at "; fi

# Debug output to allow checking that flags are set right.
debug_echo "Source compress flags:"
debug_echo $WORKING_SOURCE_COMPRESS_FLAGS
debug_echo $FINAL_SOURCE_COMPRESS_FLAGS
debug_echo "Result compress flags:"
debug_echo $WORKING_RESULT_COMPRESS_FLAGS
debug_echo $FINAL_RESULT_COMPRESS_FLAGS
debug_echo "GDALCALC flags"
debug_echo $GDALCALC_COMPRESS_FLAGS
debug_echo "General raster flags:"
debug_echo $GENERAL_RASTER_FLAGS

}



function run_tasks {

  # Debug mode
  if [[ $VERBOSE -gt 1 ]] ; then cat $WORK_DIR/tasks; fi

  # Run parallel to do a task list that has been built up.
  # N.B. parallel will handle "" quotes correctly around parameters; 'bash $WORK_DIR/tasks' doesn't seem to. 

  if [[ $VERBOSE -gt 1 ]] ; then 
    parallel -a $WORK_DIR/tasks -j $MAX_THREADS --progress -eta
  else
    parallel -a $WORK_DIR/tasks -j $MAX_THREADS 1>/dev/null 2>/dev/null
  fi


  # Clean up task list
  # Disable this line if you want to check the task list is being generated correctly. 
  rm -f $WORK_DIR/tasks

}

function print_help {

      echo
      echo "Help:"
      echo
      echo "-h       : help page."
      echo "-v       : verbose mode. Debugging output will be enabled."
      echo
      echo "These options can be used to temporarily override buildfile settings."
      echo
      echo "-a YES/NO: Force clean of build & output directory?"
      echo "-b YES/NO: generate source raster tiles from SQL geometry."
      echo "-c YES/NO: generate rule output tiles from source tiles."
      echo "-d YES/NO: merge rule output tiles into a large output raster map."
      echo "-e YES/NO: add overviews to the large output raster map."
      echo "-f FILE  : add a build file to the configuration (e.g. -f bf/default/polite.bf)."
      echo "         : note that 'default.bf' is always included. Use a relative path (bf/...)"
      echo "-j YES/NO: create JSON file describing output. Will be added to DB." 
      echo "-m YES/NO: combine source tiles into large source raster maps (optional)."
      echo "-n NAME  : the name for this build. This is used to name the working directory."
      echo "-o YES/NO: add overviews to the large source raster maps (optional, needs -m)."
      echo "-p YES/NO: polygonize source raster map (optional, use -m first)."
      echo "-q YES/NO: polygonise rules output map (optional, use -c first)."
      echo "-r YES/NO: import the output raster into postgis (optional, use -m first)"
      echo "-s YES/NO: import the output geometry into postgis (optional, use -q first)"
      echo "-t NUMBER: thread limit override. Specify maximum threads. e.g. 1-20."
      echo "-w YES   : wipe (delete) + remove working/final directories for this build."
      echo
      echo Example usage:
      echo './rbuild'
      echo './rbuild -h'
      echo './rbuild -f bf/test.bf'
      echo './rbuild -f bf/test.bf -f bf/default/smallfile.bf -p NO -n "New_name"'
      echo './rbuild -f bf/test.bf -f bf/default/do_nothing.bf -a YES -b YES -m YES -o YES
      echo '               - manually override which stages are run from the buildfile'
      echo ''
      echo 'See \'bf/default.bf\' for more information.''
      echo ''
      exit
}


function debug_program_output {

if [[ "$VERBOSE" -gt 1 ]]; then
  cat $WORK_DIR/output
  rm $WORK_DIR/output
fi

}
