# N.b. when setting values, don't put a space before '='. e.g. "This=good". "This = bad".
# Otherwise, you will get errors about 'command not found'

# List of geometry tables to burn.
# Hostname can be left empty ('') (in fact, performance will improve up to 50% if it is; unix sockets >> TCP/IP)
# Source raster ID    hostname    database name     table name      SQL field to burn      username      password.

#BURN_TABLES=(
#A '' dbname1 table1 burnField1 username1 password1 
#B '' dbname2 table2 burnField2 username2 password2
#C '' dbname3 table3 burnField3 username3 password3
#)

# By default, pick up the current username from the unix environment (e.g. geoadm).
# Please ensure that source tables are pre-transformed to the target SRID!
# e.g. see README, appendix 1.

# Geometry column in PostGIS
GEOMETRY_COLUMN="geom"

# Map settings
# SRID below is the target SRID for the raster. Please make sure your source maps are in the coordinate system.
# e.g. see README, appendix 1.
SRID=
NODATA=

# Nodata value for merged rasters; 0 is good for QGis, 255 or 65535 depending on datatype otherwise. 
RESULT_NODATA=

# Coverages / projection
XMIN=
XMAX=
YMIN=
YMAX=

# Scale of raster: meters per pixel, in x and y axis.
XM=10
YM=10

# How should the map be split into tiles for parallelising? 
# Quadratic effect: too many = slow (overhead); too few = slow (GDAL rasterize/calc problems). 
# Also, the numbers of tiles need to divide exactly into the map width/height to avoid artefacts.
# 100 or 400 tiles are good numbers for national scale maps. 
# Generally, multiples of 2,4,5,10 are OK.
MAP_X_TILES=10
MAP_Y_TILES=10



