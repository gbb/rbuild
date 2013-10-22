rbuild 
=====

What is rbuild?
----

The basic idea is to provide a tool that can:

- generate rasters from source geometry, add overviews
- optionally perform raster transformations using gdalcalc
- optionally convert the resulting raster into polygons, add overviews, add to a database etc.
- be used very easily and extremely quickly (vs. standard GDAL/PostGIS)

Rbuild and ruleparser
----

Rbuild has a companion project called 'ruleparser'. Ruleparser is a way to do certain types of GIS programming using a simple 
Excel spreadsheet. Ruleparser depends on rbuild as part of its build process. However, rbuild users don't need to use 
ruleparser. Check out http://github.com/gbb/ruleparser if you're curious.

Purpose and uses
---

This presentation at FOSS4G 2013 (Nottingham) explains what rbuild is, 
and why it's useful. Basically: it's a fast way to process 
geometry/raster data, and it offers a unique approach for GIS 
configuration and 'performance trick' management.

http://elogeo.nottingham.ac.uk/xmlui/handle/url/254

Quick setup
----

./checksetup.sh       tells you if you have the necessary software installed.
./rbuild -h           provides a description of the program's parameters and behaviour

To get started, please take a look at: 

   http://github.com/gbb/rbuild_demo

This is a complete example project which walks you through 4 different uses of rbuild.
                   

Dependencies
----

The program makes use of the following software: please make sure you have it installed.
Version numbers are indicated below.

Generating geometry based rasters:

GDAL (1.10.0) : gdal_rasterize, gdal_merge.py, gdaladdo
Gnu Parallel (20130222 or later)

Generating new calculated rasters:

python (2.7.3 or later. 3.x series is untested)
numpy  (1.7.1 or later)
gbb_gdal_calc (available on github)

Adding to database:

Postgis with postgis raster (2.0 or later, installed in the system, and installed on a database).
Postgresql (9.0 or later, 9.2 or later is ideal)

Polygonization: 

Dan's GDAL scripts / GDAL. I've found Dan's implementation of gdal_trace_outline to be considerably faster and more 
predictable (in terms of runtime) than gdal_polygonize.sh. It also seems more to offer more flexibility.


How to use the program:
-----

0. Type ./checksetup.sh to ensure you have the correct software installed.
1. Install any needed dependencies (necessary software that rbuild uses).
2. Decide which geometry databases you're going to use.
3. Set up a buildfile to do what you want (look in bf/ for examples)
4. Run rbuild (./rbuild -h for help)

It's a really good idea to look at this: https://github.com/gbb/rbuild_demo

1. Installing  dependencies
-----

Dependencies: GDAL (current), Gnu Parallel, Perl, Gnu Date, PostGIS (for DB insertion), 'Dan's GDAL scripts'.

*Important note for MacOS users!* 

GNU Date is not the same as 'date' in macos -> use Macports: 'port install coreutils'.
You may need to manually add GNU Parallel:  http://ftp.gnu.org/gnu/parallel/   or use MacPorts.


2. Setting up a buildfile
----

Buildfiles come in several formats. The two main types are 'buildfiles that run buildfiles', e.g. project buildfiles, and configuration buildfiles 
(such as those in bf/standard). You can copy default.bf or any of the files in bf/standard and edit them to suit your needs.

Rbuild will follow the instructions in the buildfile and run the appropriate stages using program/build_functions.sh


3. Setting up geometry

You can use 'psql' and SQL commands to convert the geometry to the target coordinate system. This is a good idea. You will 
probably render this geometry more than once. It's important to ensure it's indexed in the target coordinate system since 
rbuild exploits spatial indices for a huge speed boost.

See Appendix 1 for more information.


4. Finally, use BASH:
----

Step 3. Go into the the rbuild directory. 

  # cd rbuild

Step 4. Check the buildfile refers to the correct vector layers that you want to work with, the correct resolution and coverage.  
e.g.
  # cp bf/default.bf bf/projects/my_project.bf
  # nano bf/projects/my_project.bf

Step 5. Build!
#    ./rbuild -f bf/projects/my_project.bf -n "my_example"      <--- call it whatever you like, e.g. testrun, april15, ... 

The output will be placed in the folder output/my_example/final  , in this example. 


Appendix 1.
 ======

Please pre-transform your geometry into the target SRID before rendering it with this program.

Here's how, using psql:

  $ select data1, data2, ST_Transform(geom,25833) as geom into mytable_25833 from mytable;
  $ create index my_table_25833_index on mytable_25833 using gist(geom);


Q. Why doesn't rbuild do the reprojection automatically? 
----

- Because I don't want to fill your database with temporary data.
- Because probably you will be re-using this geometry more than once; it makes sense to do the slow transform only once.


Q. Why does the program not automatically transform the source geometry on the fly into the target SRID? 
-----

- The run time of the program becomes highly unpredictable; projections take different times; you may have several source geometry tables in different SRIDS.

- Even with st_transform short-cutting the projection process (e.g. if you have source SRID 25833 and destination 25833) you have a 50% performance penalty.

- If you project the geometry into the bounding box SRID on the fly, your runtime becomes horrific. You basically transform the whole map 400 times and throw away the spatial indices.

- If you project the bounding box into the source SRID, the code is more complex (you have to detect/use the right SRID) and your bounding box shape changes depending on scale, and depending on the source SRID.
The result is that you cannot be certain about what will be burned in a given bounding box area, and there would be a small risk of missing geometry.

- Slow, complex and unpredictable is bad.


Notes
-----

A. What's going on? Where the heck do I start?

http://github.com/gbb/rbuild_demo

B. Any rules for database/column/build names?

It's a bad idea to call your build name something with a hyphen - if you're adding the data to postgresql later, the 
hyphen will cause problems. Use _ instead of -. Similarly, try to keep data column names short in case you want to make a 
shapefile.

C. I'm getting the error "ERROR:  column not found in geometry_columns table"

Don't worry about this. This is because the software attempts to drop any existing tables with the given name, before adding the new table. 
This is normal output for that use of raster2pgsql and shp2pgsql.

D. How do I tidy up all the tables I've made by running tests?

Copy/paste this, optionally with 'CASCADE'

# // select 'drop table rbuild_rasts.' || tablename || ' cascade;' from pg_tables where schemaname='rbuild_rasts'

E. The last piece of debug output is sometimes missing in debug mode. 

Take a look in $WORK_DIR/output if this happens. I'll try to add a patch soon to fix this behaviour.
