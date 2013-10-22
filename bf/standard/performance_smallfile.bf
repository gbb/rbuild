# smallfile.bf
# Optimised settings for rbuild.
# GBB 03/2013   <grb@skogoglandskap.no>

# Import performance_fast.bf, to be modified.  
. $BUILDFILE_DIR/standard/performance_fast.bf

# Adjust compression in final stage merge to generate as small a file as possible. 
  FINAL_ZLEVEL=9

# To further compress files: try to produce rules that suit output in byte format.
