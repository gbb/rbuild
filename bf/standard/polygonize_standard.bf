# standard_polygonize.bf
# Normal polygonization settings with douglas-peuker smoothing.
# GBB 03/2013   <grb@skogoglandskap.no>


# Standard flags

	POLYGONIZE_FLAGS="-classify -out-cs en -split-polys -dp-toler 0 -ogr-fmt 'ESRI Shapefile' -ogr-out "

	#### Important flags. 
	# -classify -> identify each area, not just a single polygon of all areas with data.
	# -out-cs en -> easting/northing output. long/lat & pixel index are also available.
	# -ndv: no data value. avoids a large nodata polygon.
	# -split-polys -> avoid complex polygons (multipolygons).
	# -dp-toler val -> Tolerance for polygon simplification (in pixels, default is 2.0). Setting to zero makes borders exact. 
	# -min-ring-area (pixel area), -erosion - used to remove small or thin areas.

	# -geo_srs included in build_functions call automatically, assigns output coordinate system. equivalent to a_srs in ogr.
	# -ogr-out (or similar)should be put at the end of the options.
	# Note that the nodata area will be output as a polygon too. This is an unavoidable effect of -classify.
	# It is also possible to generate polygons directly into postgresql via OGR.
        # Very good idea to use '' for ogr-fmt variable

	# ESRI Shapefile output

	POLYGONIZE_SUFFIX="shp"

        # Should polygons be tiled? (using the map raster tiling settings)
        # Beware! If you're working on a large map you may get some large
        # polygons that take ages to polygonise and can't be rendered in qgis

        OUTPUT_AS_TILES=YES

         
