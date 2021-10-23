#!/bin/tcsh

# AP: run afni_proc.py to process the FMRI time series (ALL EPIs)

# This script runs a corresponding do_*.tcsh script, for a given
# subj+ses pair.  It could be adapted to loop over many subj+ses values.

# To execute:  
#     tcsh RUN_SCRIPT_NAME

# --------------------------------------------------------------------------

# specify script to execute
set cmd           = 21_ap_all

# labels
set subj          = sub-000
set ses           = ses-01

# upper directories
set dir_inroot    = ..
set dir_log       = ${dir_inroot}/logs

# --------------------------------------------------------------------------

# make directory for storing text files to log the processing
\mkdir -p ${dir_log}

# --------------------------------------------------------------------------

# run command script (verbosely and stop at any failure); log terminal text.

tcsh -xef do_${cmd}.tcsh  ${subj} ${ses}                           \
    |& tee ${dir_log}/log_${cmd}_${subj}_${ses}.txt
