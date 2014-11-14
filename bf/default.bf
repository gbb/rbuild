# default.bf
# (Sensible/helpful) default settings for rbuild map building.
# GBB 03/2013   <grb@skogoglandskap.no>

# Default buildfile (default.bf)
# If you use this buildfile, you don't need to specify any other buildfiles unless
# You want to overwrite some settings.

# Name of this build (used for working directory, outputs)
# It's best to override this at the command line or set in your own build file.
BUILD_NAME='no_name_chosen'

# Build description (this is output to JSON along with other information)
BUILD_DESCRIPTION='No description provided by user.'

# First rule of defaults: they should be sensible and helpful for typical use,
# and should not cause problems. Hence, 'actions_do_nothing'.

. $BUILDFILE_DIR/standard/output_default.bf
. $BUILDFILE_DIR/standard/actions_do_nothing.bf
. $BUILDFILE_DIR/standard/performance_medium.bf
. $BUILDFILE_DIR/standard/map_example_10x10.bf
. $BUILDFILE_DIR/standard/overviews_standard.bf
. $BUILDFILE_DIR/standard/polygonize_standard.bf
. $BUILDFILE_DIR/standard/calc_passthrough.bf

# Various alternative buildfiles are provided:

# Grouped settings:  default.bf, test.bf
# Special groups of settings: see e.g. standard/performance_fast.bf
# Compression/parallelism: performance_{fast, fastest, polite, medium, smallfile}.bf
# Maps:  map_norway_{100x100,20x20,10x10,5x5,2x2}.bf, map_map_test_{20x20,10x10,5x5,2x2}.bf
# Outputs/actions:  actions_{do_everything, do_nothing, source_and_result_rasters, result_raster,
#                            result_raster_and_poly, result_raster_to_db, result_raster_and_poly_to_db}.bf
# Overviews: standard/overviews_standard.bf, standard/overviews_all.bf

# If you want custom settings, copy this file and modify it. 
# default.bf settings are always included automatically. 
