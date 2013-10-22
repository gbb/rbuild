# output_standard.bf
# Where to store intermediate and final files, tables.
# This script should be run after the script configuring BUILD_NAME.
# GBB 07/2013   <grb@skogoglandskap.no>

# Details for filesystem storage

# Raster/geometry storage directory (optional; generated data can be placed anywhere)
STORAGE_DIR=$RBUILD_HOME/output

# Directory containing buildfiles.
  # Configured in rbuild_settings.sh

	
# Details for database storage of output. Make sure db exists and has permissions set correctly.

OPTIONAL_OUTPUT_DB_HOST=''
OUTPUT_DB_DBNAME=''
OUTPUT_DB_USERNAME=$USER

#OUTPUT_DB_PASSWORD=''
#Use direct connection, type by hand, or use a ~/.pgpass file for password.

# Schema for geometry output. Build name will be appended. Check schema exists and has correct permissions!
OUTPUT_GEOMETRY_SCHEMA="rbuild_geoms"

# Schema for raster output. Build name will be appended. Check schema exists and has correct permissions!
OUTPUT_RASTER_SCHEMA="rbuild_rasts"

# You may wish to run this on the schema.
# GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA xyz TO username;  (change existing table)
# ALTER DEFAULT PRIVILEGES IN SCHEMA xyz GRANT ALL ON TABLES TO username; (change future tables)
