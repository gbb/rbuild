# fastest.bf
# Optimised settings for rbuild.
# GBB 03/2013   <grb@skogoglandskap.no>

# Note: these settings are only slightly faster than 'performance_fast.bf'
# The temporary files produced along the way are much bigger - up to 10x bigger.

# Import performance_fast.bf, to be modified.  
. $BUILDFILE_DIR/standard/performance_fast.bf

# Maximum number of threads to run with Gnu Parallel. 8-12 is fast. 1-2 is polite.
MAX_THREADS=16

# Compressor: DEFLATE, LZW, or PACKBITS
WORKING_COMPRESSOR=PACKBITS
FINAL_COMPRESSOR=DEFLATE

