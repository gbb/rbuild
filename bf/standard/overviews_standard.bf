# standard_overviews.bf
# Fast overview settings for normal use.
# GBB 03/2013   <grb@skogoglandskap.no>


# Overview levels to be built. 

	GDAL_OVERVIEWS="8 64 256"         # recommended overview levels for Qgis and all-norway maps.
					  # overview levels 1 2 and 4 can be very slow to compute.
				  	  # Use spaces, not commas, to separate the levels.

# disabled for now

        PGR_OVERVIEWS=1                                 # 8 = equivalent of "1 2 4 8 16 32 64 128 256" in gdaladdo
                                                        # unfortunately, raster2pgsql fails randomly if you ask
                                                        # for a zoom level that will produce small tiles
                                                        # nb. reported bugs in raster2pgsql overviews here: http://trac.osgeo.org/postgis/ticket/2359
                                                        # TODO: makes me wonder if overview levels should be a characteristic of maps

							# Unfortunately, in 2010 someone changed overviews in postgis
 				 	  		# in a way that is incompatible with GDALADDO and forces you
	  				  		# to generate every level, whether it will be useful or not.

# Overview quality: JPEG is sufficient for almost all overview (preview) purposes.
# Lossless is also available. 
# Specified in a single string because these options are rarely modified.

	OVERVIEW_SETTINGS="--config COMPRESS_OVERVIEW JPEG"
