Release notes
=====


rbuild 1.0
----

Initial version

rbuild 1.1
----

Now uses simpleselect for faster calculations (approx 3-4x faster).
Default buildfile base directory has changed. Please use e.g. bf/default/file1.bf.
Default setting for verbose output is now '0'.
Buildfile directory now structured into default, standard, project, test, personal
RELEASE_NOTES.md added

rbuild 1.2
----

Restructured the buildfile system.
Note: the default behaviour of ./rbuild has changed. default.bf now prints out help information rather than running default.bf.

rbuild 1.3
----

now removes user/password from the JSON
embeds JSON into database objects (raster, geometry)
some fixes to test cases
has a 'passthrough' calculation to allow 'source rasters' to be added to postgis raster with JSON

rbuild 2.0
----

Further restructuring of build system to separate local builds into a distinct project.
