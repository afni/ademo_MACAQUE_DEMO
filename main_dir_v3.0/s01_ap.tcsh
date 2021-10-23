#!/bin/tcsh

# Single subject processing: 4 EPIs

# The main program run here, afni_proc.py, will generate a full processing
# script for a set of EPI dsets, including:
#   - motion correction
#   - EPI-anatomical alignment
#   - nonlinear warping to template space (here, using @animal_warper output)
#   - concatenate all warps correctly to minimize regridding smoothing
#   - stats modeling
#   - automatically generate several QC review scripts and a full HTML report
#   - ... and more
# This program with both create a processing script and execute it, as
# written here.
# ------------------------------------------------------------------------

set here   = $PWD
set topdir = .                            # current directory

set subj   = "sub-000"                    # just to have, in this case
set idir   = ${topdir}/${subj}            # input dir with all dsets/stims
set aw_dir = ${topdir}/${subj}.warped     # output dir for anat warp

# the template + atlas data; more follower datasets could be input
set refdir    = ./NMT_v2.0_sym/NMT_v2.0_sym_05mm   
set refvol    = ${refdir}/NMT_v2.0_sym_05mm_SS.nii.gz
set refvol_ab = NMT2
set refatl    = ${refdir}/CHARM_in_NMT_v2.0_sym_05mm.nii.gz
set refatl_ab = CHARM
set refseg    = ${refdir}/NMT_v2.0_sym_05mm_segmentation.nii.gz
set refseg_ab = SEG
set refmask   = ${refdir}/NMT_v2.0_sym_05mm_brainmask.nii.gz 
set refmask_ab = MASK
set ianat_ab   = ${subj}_anat

# -----------------------------------------------------------------

# NOTES
#
# + This script processes 4 out of 15 EPI dsets in the sub-000/
#   directory, choosing a subset just for speed reasons.  The other
#   "s11*.tcsh" script can be run to process all 15.
#
# + Adding the option '-html_review_style pythonic' would produce a
#   slightly prettier, more full QC HTML output at the end; to use it,
#   you must have Python on your computer, and the matplotlib module.
#   (An example of the QC HTML produced with this option is included
#   in this demo.)
#
# + The "typical" anat-EPI cost function is "lpc+zz", which is useful
#   for aligning data with different tissue contrasts.  Here, 'lpa+zz'
#   is used, because the tissue contrasts are actually similar (CSF is
#   not bright in either), due to the use of MION (monocrystalline
#   iron oxide nanoparticle-- see note below for more about this).
#   This might have to be adjusted in other acquisitions.
#
# + The option "-align_epi_strip_method None" is used, because the EPI
#   brightness is fairly inhomogeneous, with a bright skull in the
#   posterior, so automasking did not work well; leaving the skull on
#   the EPI did not appear to affect alignment negatively.
#
# + The HRF entered with "-regress_basis .." is MIONN()-- you can read
#   more about this shape in 3dDeconvolve's help; it is related to
#   MION(), which stands for 'monocrystalline iron oxide nanoparticle
#   (see Leite et al (2002)), but has a flipped sign so that
#   activation produces a *positive* beta.
#
# + While this proc script removes the first 4 TRs from each dataset,
#   we note that the stim onset times in the stim* files have already
#   been adjusted for this (basically, adjusting them by 4*TR s).
#   There are scripty ways this could also be done.
#
# + The censor motion and outliers values have been chosen by our
#   colleague for this dset; they could certainly be adjusted in other
#   cases, depending on the acquisition, research question, etc.
#
# + Here, we do not run 3dClustSim on results to get smoothness
#   parameters and attach those to the stats dset, but that could be
#   done by changing the argument of '-regress_run_clustsim ..' to
#   'yes'.
# 
# + The "pythonic" form of HTML review is now run.  It assumes the
#   user has Python with matplotlib installed.
#
# + One could set the environment variable OMP_NUM_THREADS in the
#   script before running the afni_proc.py command, which would speed
#   up some intermediate steps in the script.  The value to set it to
#   depends on the number of CPUs (or threads) on your computer; as an
#   exmample one could set it (using tcsh syntax for this script) to
#   be:
#      setenv OMP_NUM_THREADS 4
#   or more, if possible.
#
# -----------------------------------------------------------------

afni_proc.py                                                              \
    -subj_id                 ${subj}                                      \
    -script                  ${topdir}/proc.$subj -scr_overwrite          \
    -out_dir                 ${topdir}/${subj}.results                    \
    -blocks tshift align tlrc volreg blur mask scale regress              \
    -dsets                                                                \
        ${idir}/epi-r09-sub-000.nii.gz                                    \
        ${idir}/epi-r10-sub-000.nii.gz                                    \
        ${idir}/epi-r11-sub-000.nii.gz                                    \
        ${idir}/epi-r12-sub-000.nii.gz                                    \
    -copy_anat               ${aw_dir}/${ianat_ab}_ns.nii.gz              \
    -anat_has_skull          no                                           \
    -radial_correlate_blocks tcat volreg                                  \
    -radial_correlate_opts   -sphere_rad 14                               \
    -tcat_remove_first_trs   4                                            \
    -volreg_align_to         MIN_OUTLIER                                  \
    -volreg_align_e2a                                                     \
    -volreg_tlrc_warp                                                     \
    -align_opts_aea          -cost lpa+zz -giant_move                     \
    -align_epi_strip_method  None                                         \
    -tlrc_base               ${refvol}                                    \
    -tlrc_NL_warp                                                         \
    -tlrc_NL_warped_dsets                                                 \
        ${aw_dir}/${ianat_ab}_warp2std_nsu.nii.gz                         \
        ${aw_dir}/${ianat_ab}_composite_linear_to_template.1D             \
        ${aw_dir}/${ianat_ab}_shft_WARP.nii.gz                            \
    -blur_size               2.0                                          \
    -regress_local_times                                                  \
    -regress_stim_times                                                   \
        ${idir}/stim_face.1D                                              \
        ${idir}/stim_obj.1D                                               \
        ${idir}/stim_scram_face.1D                                        \
        ${idir}/stim_scram_obj.1D                                         \
    -regress_stim_labels     FACE  OBJ  SFACE  SOBJ                       \
    -regress_opts_3dD                                                     \
        -num_glt 5                                                        \
        -gltsym 'SYM: +FACE -SFACE'            -glt_label 1 +F-SF         \
        -gltsym 'SYM: +OBJ  -SOBJ'             -glt_label 2 +O-SO         \
        -gltsym 'SYM: +FACE -SFACE +OBJ -SOBJ' -glt_label 3 +INTACT-SCRAM \
        -gltsym 'SYM: +FACE -OBJ'              -glt_label 4 +F-O          \
        -gltsym 'SYM: +.5*FACE +.5*OBJ'        -glt_label 5 +.5FO         \
    -regress_basis            'MIONN(36)'                                 \
    -regress_censor_motion    0.2                                         \
    -regress_censor_outliers  0.02                                        \
    -regress_motion_per_run                                               \
    -regress_est_blur_errts                                               \
    -regress_est_blur_epits                                               \
    -regress_run_clustsim     no                                          \
    -html_review_style        pythonic                                    \
    -execute


exit 0






