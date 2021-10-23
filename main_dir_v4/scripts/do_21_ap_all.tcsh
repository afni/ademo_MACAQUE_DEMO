#!/bin/tcsh

# AP: run afni_proc.py to process the FMRI time series (ALL EPIs)

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
set dir_ap_all     = ${dir_inroot}/data_21_ap_all

# subject directories
set sdir_basic     = ${dir_basic}/${subj}/${ses}
set sdir_anat      = ${sdir_basic}/anat
set sdir_epi       = ${sdir_basic}/func
set sdir_aw        = ${dir_aw}/${subj}/${ses}

set sdir_ap        = ${dir_ap}/${subj}/${ses}
set sdir_ap_all    = ${dir_ap_all}/${subj}/${ses}

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
set sdir_this_ap  = ${sdir_ap_all}                   # pick AP dir (and cmd)

set dsets_epi    = ( ${sdir_epi}/epi-*-${subj}.nii.gz )

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
# + This afni_proc.py command is set to run with the fancier
#   "pythonic" for of HTML QC file output.
#
# + See do_20*.tcsh for other general/relevant NOTES for this processing.
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
