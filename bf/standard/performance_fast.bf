# performance_fast.bf
# Optimised settings for rbuild.
# GBB 03/2013   <grb@skogoglandskap.no>


# N.b. when setting values, don't put a space before '='. e.g. "This=good". "This = bad".
# Otherwise, you will get errors about 'command not found'
# N.b. needs norsk i18n.

# For more information about options see:
# http://www.gdal.org/gdal_rasterize.html
# http://www.gdal.org/frmt_gtiff.html
# http://www.gdal.org/gdal_datamodel.html - available datatypes 

# Maximum memory to use for caching per process for GDAL. <40MB is very bad. >500MB mostly pointless.
GDAL_CACHEMAX=200

# Maximum number of threads to run with Gnu Parallel. 8-12 is fast. 1-2 is polite. >16 pointless.
MAX_THREADS=12

# Compression settings
# These were chosen through testing to be very fast yet effective for this map type.
# Note that less compression is used for the intermediate stages, to improve computation speed.

# Compressor: DEFLATE, LZW, or PACKBITS
WORKING_COMPRESSOR=DEFLATE
FINAL_COMPRESSOR=DEFLATE

# Predictor: simple, difference, or floating point (1,2,3). Used for LZW, DEFLATE.
# 'difference' is best in theory, but 'simple' is best in practice for rasters burned from geometry.
# in terms of speed *and* filesize of output. (IMHO, gbb) 
WORKING_PREDICTOR=1
FINAL_PREDICTOR=1

# ZLEVEL: How much effort to use on compresssion. 1 = minimum. 9 = maximum. 
WORKING_ZLEVEL=1
FINAL_ZLEVEL=1

# Tiled or scanline storage? (Tiling is almost always best, and necessary if using QGIS.)
TILED=YES

# Use the 'BIGTIFF' standard? (IF_SAFER uses it automatically if it will be useful).
BIGTIFF=IF_SAFER

# Datatype for output from gdal_rasterize.
RENDER_TYPE=Byte

# Datatype for output from gdal_calc (rules stage)
RESULT_TYPE=Byte

# Render all pixels touched by polygons/lines, or only those whose center point is inside the bounds?
#### This option has unusual consequences and the setting requires some thought ####
# ALL_TOUCHED has a significant effect on the data that is output at low-medium resolutions (e.g. >10m)
# It has a fairly small effect at high resolutions (<2m). It has an effect on speed. 
# Interesting problem: what if a pixel is touched by several pieces of geometry?
# Example of a tricky case; areas with many small polygons scattered around, with gaps. 
# All touched will pick them all up; but may over-represent the area they cover. 
# ALL_TOUCHED="YES" will help small items show up in low resolution rasters. "NO" is the GDAL default.
ALL_TOUCHED="NO"


###
# TODO: Should map resolution be here, as a speed matter? or in maps? Overview -> in standard_output.
###


# Can the raster have empty areas with no data? 
# GBB: Disabled and removed the feature SPARSE_OK=TRUE (04/2013). 
# GBB: SPARSE is only valuable if you're not using compression. 
# GBB: It is not generally compatible with tiff viewing programs.
# GBB: Also, it seems it may be causing bugs with gdalcalc, qgis, Preview, Finder.

