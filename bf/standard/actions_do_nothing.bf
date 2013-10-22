# do_nothing.bf
# Useful for testing the system as a whole. May take some time.
# GBB 03/2013   <grb@skogoglandskap.no>


# Clean build directory? (Do not do this if you are re-using prebuilt source tiles!)

	WORK_CLEAN=NO

# Clean output directory? (Be careful!)

	OUTPUT_CLEAN=NO

# Generate source raster tiles from postgis geometry?
# If you need to specialise the raster in some way, you can use "OPTIONAL_RASTER_FLAGS"

	RASTERIZE=NO

	OPTIONAL_RASTER_FLAGS=""

# Merge source tiles into large source raster maps? (Not needed if you are only making a result raster)

	SOURCE_MERGE=NO

# Add overviews to individual source raster maps? (use only if SOURCE_MERGE == YES)
# (recommend if you will view the raster in QGIS etc)

	SOURCE_OVERVIEW=NO

# Convert source raster maps into ESRI geometry shapefile? (use this only if you need geometry)

	SOURCE_POLYGONIZE=NO

# Apply rules to source rasters (applies each rule in turn; merges rule layers at the end; produces tiles).

	RULES_APPLY=NO

# Merge output tiles into an output raster map? (helpful for qgis)

	RESULT_MERGE=NO

# Add overviews to output raster map? (recommended if you will view the raster in QGis etc)

	RESULT_OVERVIEW=NO

# Convert output raster map into ESRI geometry shapefile? (use this only if you need geometry)
	
	RESULT_POLYGONIZE=NO 

# Describe the output (produces a JSON file in output dir and prints to output)

	DESCRIBE=NO

# Import output raster map into PostGIS Raster? 

	POSTGIS_RASTER_IMPORT=NO

# Import ESRI shapefile into PostGIS as geometry?

	POSTGIS_GEOMETRY_IMPORT=NO

# Delete the working files and final output files.
# This will delete the files mentioned above. 

	DELETE=NO
