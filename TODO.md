#add JSON to db code.

#abstract some fixed constants (shapefile_tiles, .tif)

#question of whether source rasters can also be added to the db. (probably should be able to)
#n.b. polys are not an issue here. source is already poly. 
#have worked around this for now by providing calc_passthrough.bf

# possibly write a script to do the transform/index on source geometry automatically.

# use comment on and see notes on extracting descriptions.

# possibly have 'pre-rbuild' and 'post-rbuild' scripts optionally - e.g. to allow rule values to be transformed. 

# rem to drop table in qgis etc before adding with shp2pgsql. add error output?

# check dependencies more carefully. at each stage, check the stage has what it needs? deps = other progs. and versions. check all vars needed are present. 

# if ever using this via the web - beware of sql injection attacks on the rbuild stages that extract data via sql (rasterize, import to postgis)

# Should really do something tidier with program output in non-verbose mode. It's hard because set -e will abort as soon as there is a failure. 
# So how do you print out the last piece of output in that situation?

# add demos of 'passthrough' and other program aspects.

# possibly:
# write a wrapper (rbuild, rbuild_main) to catch failure of rbuild and report on it (e.g. cat $WORK_DIR/output?)
# call build_functions as independent programs?

# add tiling code to the polygonize function for sources? (really, should this even be a feature?)

# gdal_trace_outline is an extra dependency ; maybe use gdal_polygonize or provide it as an option
# also; I think trace_outline produces the column 'value' whereas polygonize produces 'dn'

# in the polygonize function, require that all-map raster has been built if 
# working without tiles.
# OR
# write code to always work with tiles, then merge tiled shps optionally.
# check settings in the poly building action files

# possibly offer a gdal_polygonize alternative to dan's scripts, even though gdal_polygonize is slower.
