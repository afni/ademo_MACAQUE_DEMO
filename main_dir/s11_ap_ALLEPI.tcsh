#!/bin/tcsh

# Single subject processing: all EPIs

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
set topdir = $here

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

# ------------------------------------------------------------------------

# NOTES
#
# + This afni_proc.py command is set to run with the fancier
# "pythonic" for of HTML QC file output.
#
# + See s00*.tcsh for other general/relevant NOTES for this processing.
#
# -----------------------------------------------------------------

afni_proc.py                                                              \
    -subj_id                 ${subj}                                      \
    -script                  ${topdir}/proc.${subj}_full -scr_overwrite   \
    -out_dir                 ${topdir}/${subj}_full.results               \
    -blocks tshift align tlrc volreg blur mask scale regress              \
    -dsets                   ${idir}/epi*                                 \
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






