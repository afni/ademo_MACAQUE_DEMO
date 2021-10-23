#!/bin/tcsh

# AP: run afni_proc.py to process the FMRI time series

# Process a single subj+ses pair.  Run this script in
# MACAQUE_DEMO/scripts/, via the corresponding run_*tcsh script.

# ---------------------------------------------------------------------------
# top level definitions (constant across demo)
# ---------------------------------------------------------------------------
 
# labels
set subj           = $1
set ses            = $2

# upper directories
set dir_inroot     = ${PWD:h}                        # one dir above scripts/
set dir_log        = ${dir_inroot}/logs
set dir_ref        = ${dir_inroot}/NMT_v2.1_sym/NMT_v2.1_sym_05mm

set dir_basic      = ${dir_inroot}/data_00_basic
set dir_aw         = ${dir_inroot}/data_13_aw

set dir_ap         = ${dir_inroot}/data_20_ap

# subject directories
set sdir_basic     = ${dir_basic}/${subj}/${ses}
set sdir_anat      = ${sdir_basic}/anat
set sdir_epi       = ${sdir_basic}/func
set sdir_aw        = ${dir_aw}/${subj}/${ses}

set sdir_ap        = ${dir_ap}/${subj}/${ses}

# --------------------------------------------------------------------------
# data and control variables
# --------------------------------------------------------------------------

# dataset inputs, with abbreviations for each 
set anat_orig    = ${sdir_anat}/anat-${subj}.nii.gz
set anat_orig_ab = ${subj}_anat

set ref_base     = ${dir_ref}/NMT_v2.1_sym_05mm_SS.nii.gz
set ref_base_ab  = NMT2

set ref_atl      = ( ${dir_ref}/CHARM_in_NMT_v2.1_sym_05mm.nii.gz     \
                     ${dir_ref}/D99_atlas_in_NMT_v2.1_sym_05mm.nii.gz )
set ref_atl_ab   = ( CHARM D99 )

set ref_seg      = ${dir_ref}/NMT_v2.1_sym_05mm_segmentation.nii.gz
set ref_seg_ab   = SEG

set ref_mask     = ${dir_ref}/NMT_v2.1_sym_05mm_brainmask.nii.gz 
set ref_mask_ab  = MASK

# AP files
set sdir_this_ap  = ${sdir_ap}                    # pick AP dir (and cmd)

set dsets_epi    = ( ${sdir_epi}/epi-r09-${subj}.nii.gz \
                     ${sdir_epi}/epi-r10-${subj}.nii.gz \
                     ${sdir_epi}/epi-r11-${subj}.nii.gz \
                     ${sdir_epi}/epi-r12-${subj}.nii.gz )

set anat_cp      = ${sdir_aw}/${anat_orig_ab}_ns.nii.gz

set dsets_NL_warp = ( ${sdir_aw}/${anat_orig_ab}_warp2std_nsu.nii.gz           \
                    ${sdir_aw}/${anat_orig_ab}_composite_linear_to_template.1D \
                    ${sdir_aw}/${anat_orig_ab}_shft_WARP.nii.gz                )

set stim_files   = ( ${sdir_epi}/stim_face.1D          \
                     ${sdir_epi}/stim_obj.1D           \
                     ${sdir_epi}/stim_scram_face.1D    \
                     ${sdir_epi}/stim_scram_obj.1D     )

set stim_labs    = ( FACE  OBJ  SFACE  SOBJ )

# control variables

set nt_rm        = 4
set blur_size    = 2.0
set final_dxyz   = 1.5      # can test against inputs
set cen_motion   = 0.2
set cen_outliers = 0.02

# check available N_threads and report what is being used
# + consider using up to 16 threads (alignment programs are parallelized)
# + N_threads may be set elsewhere; to set here, uncomment the following line:
### setenv OMP_NUM_THREADS 16

set nthr_avail = `afni_system_check.py -check_all | \
                      grep "number of CPUs:" | awk '{print $4}'`
set nthr_using = `afni_check_omp`

echo "++ INFO: Using ${nthr_avail} of available ${nthr_using} threads"

setenv AFNI_COMPRESSOR GZIP

# ---------------------------------------------------------------------------
# run programs
# ---------------------------------------------------------------------------

set ap_cmd = ${sdir_this_ap}/ap.cmd.${subj}

\mkdir -p ${sdir_this_ap}

# write AP command to file
cat <<EOF >! ${ap_cmd}
# -----------------------------------------------------------------
# NOTES
#
# + This script processes 4 out of 15 EPI dsets in the sub-000/
#   directory, choosing a subset just for speed reasons.  The other
#   "s11*.tcsh" script can be run to process all 15.

#   - Because the full data has 15 runs, the stimulus timing files
#     have 15 rows; when you run this AP command, you see see the
#     following warning, because we are only using 4 rows:
#       ** warnings for local stim_times format of file ./sub-000/stim_face.1D
#          - 15 rows does not match 4 runs
#     But this is OK---we can understand why this happens here in this
#     example setup, and it doesn't represent a problem in this case.
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
     -subj_id                  ${subj}                                    \
    -blocks tshift align tlrc volreg blur mask scale regress              \
    -dsets                   ${dsets_epi}                                 \
    -copy_anat               ${anat_cp}                                   \
    -anat_has_skull          no                                           \
    -radial_correlate_blocks tcat volreg                                  \
    -radial_correlate_opts   -sphere_rad 14                               \
    -tcat_remove_first_trs   ${nt_rm}                                     \
    -volreg_align_to         MIN_OUTLIER                                  \
    -volreg_align_e2a                                                     \
    -volreg_tlrc_warp                                                     \
    -volreg_warp_dxyz        ${final_dxyz}                                \
    -volreg_compute_tsnr     yes                                          \
    -align_opts_aea          -cost "lpa+ZZ" -giant_move                   \
    -align_epi_strip_method  None                                         \
    -tlrc_base               ${ref_base}                                  \
    -tlrc_NL_warp                                                         \
    -tlrc_NL_warped_dsets    ${dsets_NL_warp}                             \
    -blur_size               ${blur_size}                                 \
    -regress_local_times                                                  \
    -regress_stim_times      ${stim_files}                                \
    -regress_stim_labels     ${stim_labs}                                 \
    -regress_opts_3dD                                                     \
        -num_glt 5                                                        \
        -gltsym 'SYM: +FACE -SFACE'            -glt_label 1 +F-SF         \
        -gltsym 'SYM: +OBJ  -SOBJ'             -glt_label 2 +O-SO         \
        -gltsym 'SYM: +FACE -SFACE +OBJ -SOBJ' -glt_label 3 +INTACT-SCRAM \
        -gltsym 'SYM: +FACE -OBJ'              -glt_label 4 +F-O          \
        -gltsym 'SYM: +.5*FACE +.5*OBJ'        -glt_label 5 +.5FO         \
    -regress_basis            'MIONN(36)'                                 \
    -regress_censor_motion    ${cen_motion}                               \
    -regress_censor_outliers  ${cen_outliers}                             \
    -regress_motion_per_run                                               \
    -regress_est_blur_errts                                               \
    -regress_est_blur_epits                                               \
    -regress_run_clustsim     no                                          \
    -html_review_style        pythonic 

EOF

cd ${sdir_this_ap}

# execute AP command to make processing script
tcsh -xef ${ap_cmd} |& tee output.ap.cmd.${subj}

# execute the proc script, saving text info
time tcsh -xef proc.${subj} |& tee output.proc.${subj}

echo "++ FINISHED AP"

exit 0
