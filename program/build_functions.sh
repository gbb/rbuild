# build_functions.sh
# Each function performs one stage of the build process.
# GBB 03/2013   <grb@skogoglandskap.no>

#Constants

BURN_TABLE_WIDTH=7

function WORK_CLEAN {
  # depends on setup_output_directories
  mkdir -p $WORK_DIR

  # Check working directory is clean. May not be needed now that we generate new dir each time.
  # the "" test is to prevent wiping your root partition if someone modifies this code and runs as root

  if [[ "$WORK_DIR" != "" ]]; then 
    rm -rf $WORK_DIR/*
  fi
  touch $LOG  # TODO: may be obsolete.


}

function OUTPUT_CLEAN {
  # depends on setup_output_directories
  mkdir -p $OUTPUT_DIR

  # Check working directory is clean. May not be needed now that we generate new dir each time.
  if [[ "$OUTPUT_DIR" != "" ]]; then 
    rm -rf $OUTPUT_DIR/*
  fi

  if [[ "$OUTPUT_AS_TILES" == "YES" ]] ; then
    mkdir $OUTPUT_DIR/shapefile_tiles
  fi
}

function RASTERIZE {
  # Generates a list of tasks to be run by Gnu Parallel
  # Each task represents rendering one tile of each map. 
  # TODO: maybe add 'host' for people rendering over the network. 

  # Make sure no tasks/tiles file left over from previous aborted runs. 
  rm -f $WORK_DIR/tasks $WORK_DIR/tiles

  # When generating tile list, only generate it once. 
  FIRST_RUN=YES;

  # For each table/field listed in the BURN_TABLES array
  # Name   database name   table name    SQL field to burn    username    password.

  for (( i=0; i< ${#BURN_TABLES[@]}; i=i+BURN_TABLE_WIDTH )) ; do 

    # Generate configuration strings and burn the raster into tiles. 

  	SOURCE_ID=${BURN_TABLES[$i]} 
  	HOST_NAME=${BURN_TABLES[$((i+1))]}
  	DB_NAME=${BURN_TABLES[$((i+2))]} 
  	TABLE_NAME=${BURN_TABLES[$((i+3))]} 
  	BURN_FIELD=${BURN_TABLES[$((i+4))]} 
  	DB_USER=${BURN_TABLES[$((i+5))]} 
  	DB_PASS=${BURN_TABLES[$((i+6))]} 

    # N.B. Not specifying host = unix sockets to localhost in unix, tcp to localhost in windows. 
    # N.B. Connect using unix sockets is about 33% faster than connecting via TCP/IP (pg core developer). 
    # The "tables" parameter is needed to prevent the pg driver from scanning the entire database for tables each time. 
    # More info here: http://www.gdal.org/ogr/drv_pg_advanced.html
    # http://www.gdal.org/ogr/drv_pg.html
    # This is important here because there are many DB connections. Don't want to do 400+ scans of all tables.
    # Setup OGR/GDAL SQL Driver parameters and SQL query to use.

    PGLINE="PG:\"host='$HOST_NAME' dbname='$DB_NAME' user='$DB_USER' password='$DB_PASS' tables='$TABLE_NAME'\""   

	# Iterate over a grid of tiles covering the map. XJUMP/YJUMP are the width/height of each tile in meters. 

	XJUMP=(XMAX-XMIN)/MAP_X_TILES
	YJUMP=(YMAX-YMIN)/MAP_Y_TILES

	for (( x1 = XMIN; x1 < XMAX; x1=x1+XJUMP)); do
	  for (( y1 = YMIN; y1 < YMAX; y1=y1+YJUMP)); do

	    x2=$((x1+XJUMP)); 
	    y2=$((y1+YJUMP));

	    BOUNDING_BOX="ST_GeometryFromText('POLYGON(($x1 $y1,$x1 $y2,$x2 $y2, $x2 $y1, $x1 $y1))',$SRID)"

	    # Pick out a part of the map which intersects or is contained by the bounding box x1,y1 to x2,y2. (&& is overlap)
	    # doing a detailed intersection (st_intersects) is unnecessary. test only the bounding box of geometry. 50% speed gain! 
            # It makes sense to pretransform the geometry so that st_transform doesn't need to do any work here.
 	    # Also, more importantly - on-the-fly st_transform would not have a spatial index in the target coordinate system.
            # A spatial index is essential for lightning fast bounding-box matches that let us quickly retrieve only what we need.

	    SQL="-sql \"select $BURN_FIELD,$GEOMETRY_COLUMN from $TABLE_NAME where st_transform($GEOMETRY_COLUMN,$SRID) && $BOUNDING_BOX \""   

            # n.b. we have to use \" here since sql can contain ' characters           

	    # This line produces e.g. "20mx20m-cells-10x10-tiling-280000-7190000-TILE.tif"
	    TILE_NAME=$XM"mx"$YM"m-cells"-$MAP_X_TILES"x"$MAP_Y_TILES-"tiling"-$x1-$y1-TILE.tif
	    
	    # Generate output file name to be produced.
	    OUTPUT_FILE=$WORK_DIR/SRC-$SOURCE_ID-$TABLE_NAME-$BURN_FIELD-$TILE_NAME

	    # When generating the first raster map, create a list of all the tiles that exist for each map. 
	    if [[ $FIRST_RUN == YES ]]; then echo $TILE_NAME >> $WORK_DIR/tiles; fi

  	    # Extent, field to burn, flags for raster burning, postgres connection, sql to run.
            # NOTE: '-init 255' is a workaround for a bug in GDAL (#5115)
	    GDAL_OPTS="-te $x1 $y1 $x2 $y2 -a $BURN_FIELD -init $NODATA $GENERAL_RASTER_FLAGS $PGLINE $SQL" 

 	    # TODO
	    # Now output this as a task to be run in parallel  
	    TASK="gdal_rasterize $GDAL_OPTS $OUTPUT_FILE"

        echo $TASK >> $WORK_DIR/tasks 
      done # end for loop over x
    done # end for loop over y

    # set this after first iteration to avoid re-generating tile set. 
    FIRST_RUN=NO;

  done # end for loop over BURN_TABLES.

  # Run the tasks in parallel using GNU Parallel.
  run_tasks;         # optionally:  --joblog $WORKING_DIR/joblog
 
}


function SOURCE_MERGE {

  rm -f $WORK_DIR/tasks

  # NOTE: -n = empty area values in AR5/DMK/etc (0). 
  # UPDATE (Jun 13, gbb): the 0s are a gdal bug. use -init to gdal_rast to prevent.
  # NOTE: -a_nodata empty areas in raster output (255 is normal e.g. in qgis)

  for (( i=0; i< ${#BURN_TABLES[@]}; i=i+BURN_TABLE_WIDTH )) ; do  

    SOURCE_ID=${BURN_TABLES[i]};

    echo "gdal_merge.py $FINAL_SOURCE_COMPRESS_FLAGS -n $NODATA -a_nodata $NODATA "\
    "-o $OUTPUT_DIR/$SOURCE_ID.tif $WORK_DIR/SRC-$SOURCE_ID*" >> $WORK_DIR/tasks

  done # end for loop

  run_tasks;

}

function SOURCE_OVERVIEW {

  rm -f $WORK_DIR/tasks

  for (( i=0; i< ${#BURN_TABLES[@]}; i=i+BURN_TABLE_WIDTH )) ; do  

    SOURCE_ID=${BURN_TABLES[$i]} 
    
    if [[ $VERBOSE -lt 2 ]] ; then QUIET=" -q" ; else QUIET=""; fi
    echo "gdaladdo $QUIET $OUTPUT_DIR/$SOURCE_ID.tif $OVERVIEW_SETTINGS $GDAL_OVERVIEWS " >> $WORK_DIR/tasks

  done

  run_tasks;

}

function SOURCE_POLYGONIZE {
 
  # N.B. Using "Dan's GDAL tools" rather than standard GDAL. Standard GDAL is extremely slow on large rasters; no smoothing.
  # TODO: adapt to include tiling code.
  # (May be worth changing back though after fixing gdal_polygonize.py)

  rm -f $WORK_DIR/tasks

  for (( i=0; i< ${#BURN_TABLES[@]}; i=i+BURN_TABLE_WIDTH )) ; do  

    SOURCE_ID=${BURN_TABLES[$i]} 
    echo "gdal_trace_outline $OUTPUT_DIR/$SOURCE_ID.tif -s_srs \'+init=epsg:$SRID\' $POLYGONIZE_FLAGS $OUTPUT_DIR/$SOURCE_ID.$POLYGONIZE_SUFFIX" >> $WORK_DIR/tasks

  done

  run_tasks;


}

function RULES_APPLY {

  # Presently this function is hard-wired. 
  # To be replaced by Python code to translate spreadsheet into python/numpy calculations.

  rm -f $WORK_DIR/tasks
  rm -f $WORK_DIR/MERGED_RULES* $WORK_DIR/RULE-*

  # these rules are written in the scary numpy syntax. Numpy is fast but tricky to write.
  # explanation: e.g. "if (if clause), target value (2521), otherwise, NODATA 65535"
  # for complex ifs, use multiplication e.g. (C>0)*(C<128)*...
  # quoting matters here; some of these characters will be parsed by bash otherwise.

  debug_echo $RULE_FORMULA

  # for each tile
    # for each rule
      # generate a rule-tile; we'll merge the rule-tiles together later.

  for TILE in `cat $WORK_DIR/tiles`; do  

    # GDAL calc syntax needs letters to describe each file.

    GDALCALC_INPUT=" "
    BURN_TABLE_INDEX=0

    for letter in {A..Z}; do

      # if index is less than the number of items in the table
      if [[ $BURN_TABLE_INDEX -lt ${#BURN_TABLES[@]} ]]; then 

        # generate another gdalcalc source parameter and increment the index
        FILENAME="$WORK_DIR/SRC-${BURN_TABLES[BURN_TABLE_INDEX]}-*$TILE"
        GDALCALC_INPUT+="-$letter $FILENAME "
        BURN_TABLE_INDEX=$((BURN_TABLE_INDEX+BURN_TABLE_WIDTH))

      fi      

    done

    RULE_OUTPUT_TILE="$WORK_DIR/MERGED_RULES-$TILE"

    if [[ $VERBOSE -lt 2 ]] ; then QUIET=" --quiet" ; else QUIET=""; fi

    # Use GBB's version of gdalcalc with flexibility for nodata. 

    # this needs fixed. not A, B, C. Use BURN TABLES. 
    echo "program/gbb_gdal_calc.py $GDALCALC_INPUT --outfile $RULE_OUTPUT_TILE --calc='$RULE_FORMULA' $GDALCALC_COMPRESS_FLAGS --NoDataValue=$RESULT_NODATA --overwrite --ManualNoData $QUIET" >> $WORK_DIR/tasks

    # we want to batch rules together, rather than do '1 rule for each tile in turn'.
    # that way we can hold the src data in the filesystem cache.

  done; # end for

  run_tasks;

}

function RESULT_MERGE {

  # prevent gdal_merge from merging with old output.
  rm -f $OUTPUT_DIR/$BUILD_NAME.tif

  echo "gdal_merge.py $FINAL_RESULT_COMPRESS_FLAGS -a_nodata $RESULT_NODATA -o $OUTPUT_DIR/$BUILD_NAME.tif $WORK_DIR/MERGED_RULES-*" >> $WORK_DIR/tasks
  run_tasks

  # eval is needed here to parse the quote marks inside the parameters.
  # REMOVE TODO how about restricting to single quotes? and not using eval.

}

function RESULT_OVERVIEW {

  if [[ $VERBOSE -lt 2 ]] ; then QUIET=" -q" ; else QUIET=""; fi
  gdaladdo $QUIET $OUTPUT_DIR/$BUILD_NAME.tif $OVERVIEW_SETTINGS $GDAL_OVERVIEWS 

}

function RESULT_POLYGONIZE {

 if [[ "$RESULT_TYPE" == "Byte" ]] ; then

    if [[ "$OUTPUT_AS_TILES" == "NO" ]] ; then
      echo gdal_trace_outline $OUTPUT_DIR/$BUILD_NAME.tif -s_srs \'+init=epsg:$SRID\' $POLYGONIZE_FLAGS $OUTPUT_DIR/$BUILD_NAME.$POLYGONIZE_SUFFIX  >> $WORK_DIR/tasks
      run_tasks
    else
      for i in $(ls $WORK_DIR/MERGED_RULES*.tif); do 
        echo gdal_trace_outline $i -s_srs \'+init=epsg:$SRID\' $POLYGONIZE_FLAGS $i.SHAPE.$POLYGONIZE_SUFFIX  >> $WORK_DIR/tasks
      done
      run_tasks
      mv $WORK_DIR/*SHAPE* $OUTPUT_DIR/shapefile_tiles
    fi
  else
    echo "Warning: Polygonizing with gdal_trace_outline only works on byte values. Did not polygonize."
    #was this fixed in latest dan tools aug 2013? no. seems broken. 
  fi

  # TODO: abstract out 'shapefile_tiles' and '.tif'
}

function DESCRIBE {

  # make JSON object describing output.
  
  # Describe conditions for generating output

  JSON_FILE=$OUTPUT_DIR/$BUILD_NAME.json 
  JSON="{" 
  JSON+='"rbuild_version" : "'$RBUILD_VERSION'", \n'

  # Describe geometry files
  # Syntax is tricky here to produce quote marks " correctly in JSON when the burn tables have quotes inside.
  # Also, the 'burn tables' variable is an array, which we want to remove passwords and usernames from.
  for PARAM in "${PARAMS[@]}"; do

    VARIABLE="\"$PARAM\""
    VALUE=""

    if [[ $PARAM == "BURN_TABLES" ]]; then
      BURN_TABLE_ITEMS=${#BURN_TABLES[@]}
      POSITION=0
      # if its a burn table, print out all objects
      VALUE+="[ "
      for BURN_VALUE in "${BURN_TABLES[@]}"; do

        if [[ "$((POSITION%BURN_TABLE_WIDTH))" -ge "$((BURN_TABLE_WIDTH-2))" ]] ; then

          VALUE+=' "---"'  #don't print username/password 

          # last item, no comma
          if [[ "$POSITION" -lt "$((BURN_TABLE_ITEMS-1))" ]]; then
            VALUE+=", "
          fi

        else  

          VALUE+=" \"$BURN_VALUE\", "
          # add commas between values in array

        fi 

      POSITION=$((POSITION+1))  # TODO: refactor this into the for loop above.

      done
      VALUE+=" ]"

    else

      # print out ordinary value
      VALUE="\""$( echo ${!PARAM} | sed -e 's/"/\\"/g' )"\""

    fi

    JSON+="$VARIABLE : $VALUE, \n"

  done

  END_DATETIME=$(date +"%c")
  END_TIME=$(date +"%s")

  # refactor this into a json-print call
  JSON+="\"start_time\": \"$START_DATETIME\",\n" 
  JSON+="\"end_time\": \"$END_DATETIME\",\n" 
  JSON+="\"seconds_taken\": \"$(($END_TIME-START_TIME))\",\n" 
  JSON+="\"build_machine\": \"$HOSTNAME\",\n"
  JSON+="\"build_username\": \"$USER\"\n"
  JSON+="}\n" 

  echo -e $JSON >> $JSON_FILE

  if [[ $VERBOSE -eq 2 ]] ; then
    echo -e $JSON 
  fi

  # TODO: Describe metadata in more detail
  # TODO: Describe source files in more detail
  # TODO: Describe raster files in more detail
  # TODO: Describe geometry files in more detail
 
}

function DELETE {
  debug_echo "Deleting final and working directory for: $BUILD_NAME"
  rm -rf $WORK_DIR
  rm -rf $OUTPUT_DIR
  debug_echo "Done."
}


function POSTGIS_RASTER_IMPORT {

  # two approaches possible here: 
  # take the gdal_calc tiles, import them directly (not the merge) (faster, risk of tile sizes not lining up)
  # import from the merged tiff (simpler)

  # 100x100 pixels is generally a good size for postgis raster tiles. 
  # Good postgis performance, matches well with web tiles, not too many rows, and fits neatly with larger tile/map sizes (/100).

  # unhelpfully, postgis raster uses a completely different overview system to gdal. http://lists.osgeo.org/pipermail/postgis-devel/2010-December/010827.html
  # TODO: save output dev/nulled below to a file or variable and debug_echo it.  

  if [[ "$OUTPUT_AS_TILES" = "NO" ]] ; then
    # add final merged raster from the output directory
    raster2pgsql -I -s "$SRID" -d -t 100x100 -M -C -r -Y "$OUTPUT_DIR/$BUILD_NAME.tif" "$OUTPUT_RASTER_SCHEMA.$BUILD_NAME" 2>> $WORK_DIR/output | psql -h "$OPTIONAL_OUTPUT_DB_HOST" -d "$OUTPUT_DB_DBNAME" -U "$OUTPUT_DB_USERNAME" >> $WORK_DIR/output 2>&1
  else   
    # add raster output tiles from the working directory. note, no quotes around the wildcard below, deliberately.
    raster2pgsql -I -s "$SRID" -d -t 100x100 -M -C -r -Y $WORK_DIR/MERGED_RULES*.tif "$OUTPUT_RASTER_SCHEMA.$BUILD_NAME" 2>> $WORK_DIR/output | psql -h "$OPTIONAL_OUTPUT_DB_HOST" -d "$OUTPUT_DB_DBNAME" -U "$OUTPUT_DB_USERNAME" >> $WORK_DIR/output 2>&1
  fi 

  # -l $PGR_OVERVIEWS disabled until working version of raster2pgsql overviews released (next version). 
  # -I - generate a spatial index.
  # -s - specify an SRIDa
  # -d - drop any preexisting raster table with the same name
  # -t - select tile size in postgis raster. large files will be re-tiled automatically.
  # -M - run 'VACUUM ANALYZE' on table after adding raster data.
  # -C - set standard constraints on raster. this is importnat for speed. 
  # -r - set the regular blocking constraint. 
  # -Y - use 'COPY' rather than insert. Should be much faster.
  # needs: -l matching overview levels above. 

  JSON_SQL_ESCAPE_QUOTE=$(echo -e $JSON | sed "s/'/''/g")
  echo -e "COMMENT ON TABLE $OUTPUT_RASTER_SCHEMA.$BUILD_NAME IS '$JSON_SQL_ESCAPE_QUOTE';" 2>> $WORK_DIR/output | psql -h "$OPTIONAL_OUTPUT_DB_HOST" -d "$OUTPUT_DB_DBNAME" -U "$OUTPUT_DB_USERNAME"  >> $WORK_DIR/output 2>&1

  debug_program_output

  # n.b. this works even if $JSON is undefined, since it defaults to "". 

  # TODO -> embed json in a comment
  # TODO -> add source rasters too - in case the person is only generating those. 
  # POSSIBLY add a 'add source raster' flag. 
  # possibly generalise this function; call it n times from source rasters and 1 time for final raster.

}

function POSTGIS_GEOMETRY_IMPORT {

  # with shp2pgsql, options must come before filename, or they get ignored.
  # This assumes we have a shapefile here from previous stages.
  
  # There is a question here of what columns/values are imported/created. 
  # Probably best to make it 'rbuild output class values' for consistency with raster.
  # Password should be set up in ~/.pgpass , or specified manually, or not needed (e.g. direct connection)

  # Note that this command works for either tiled polygon sets or large polygons. 

  if [[ "$OUTPUT_AS_TILES" = "NO" ]] ; then
    # add final big shapefile from the output directory
    shp2pgsql -I -S -D -d -s "$SRID" "$OUTPUT_DIR/$BUILD_NAME.$POLYGONIZE_SUFFIX" "$OUTPUT_GEOMETRY_SCHEMA.$BUILD_NAME" 2>> $WORK_DIR/output | psql -h "$OPTIONAL_OUTPUT_DB_HOST" -d "$OUTPUT_DB_DBNAME" -U "$OUTPUT_DB_USERNAME" >> $WORK_DIR/output 2>&1 
  else   
    # add small tile shapefiles generated earlier. prep table then add. unlike raster2pgsql, shp2pgsql can only add one shape at a time. 
    FIRST_FILE=$(ls $OUTPUT_DIR/shapefile_tiles/*.$POLYGONIZE_SUFFIX | head -1)
    shp2pgsql -p -I -S -D -s "$SRID" $FIRST_FILE "$OUTPUT_GEOMETRY_SCHEMA.$BUILD_NAME" 2>> $WORK_DIR/output | psql -h "$OPTIONAL_OUTPUT_DB_HOST" -d "$OUTPUT_DB_DBNAME" -U "$OUTPUT_DB_USERNAME"  >> $WORK_DIR/output 2>&1
    for i in $(ls $OUTPUT_DIR/shapefile_tiles/*.$POLYGONIZE_SUFFIX); do
      shp2pgsql -a  -S -D -s "$SRID" $i "$OUTPUT_GEOMETRY_SCHEMA.$BUILD_NAME" 2>> $WORK_DIR/output | psql -h "$OPTIONAL_OUTPUT_DB_HOST" -d "$OUTPUT_DB_DBNAME" -U "$OUTPUT_DB_USERNAME" >> $WORK_DIR/output 2>&1
    done
  fi 

  # -I - generate a spatial index
  # -S - simple geometries not multigeometries
  # -s - specify srid formally
  # -D - dump format. faster than -I. occasionally has problems (so does -I)
  # -d - drop table if it already exists
  # -p - prepare table. (can't 'add' and 'append' data in the same position)
  # NOTE: cannot use -I if using -a, because the index already exists
  # also, ogr2ogr can be used as an alternative.

  JSON_SQL_ESCAPE_QUOTE=$(echo $JSON | sed "s/'/''/g")
  echo -e "COMMENT ON TABLE $OUTPUT_GEOMETRY_SCHEMA.$BUILD_NAME IS '$JSON_SQL_ESCAPE_QUOTE';" | psql -h "$OPTIONAL_OUTPUT_DB_HOST" -d "$OUTPUT_DB_DBNAME" -U "$OUTPUT_DB_USERNAME"  >> $WORK_DIR/output 2>&1

  debug_program_output

  # TODO
  # would the shp2pgsql call benefit from parallel -j 2? e.g. 1 converting to .sql, 1 adding .sql? 
  # possibly generalise this function; call it n times from source rasters and 1 time for final raster.

}

