#!/bin/tcsh

# The main program here, @animal_warper, will do the following:
# + align the anatomical dataset to the specified NMT template
# + preserve a copy of the warps for future use (in afni_proc.py!)
# + skull strip the anatomical
# + map the D99 atlas to the native anatomical space
# + computes surfaces of the atlas regions in native anatomical space
# + automatically generate images of intermediate/final steps (see QC subdir)
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

### could be set to specify CPU usage, if possible
# setenv OMP_NUM_THREADS 12

# -----------------------------------------------------------------

@animal_warper                                    \
    -echo                                         \
    -input            ${idir}/anat-sub-000.nii.gz \
    -input_abbrev     ${ianat_ab}                 \
    -base             ${refvol}                   \
    -base_abbrev      ${refvol_ab}                \
    -atlas_followers  ${refatl}                   \
    -atlas_abbrevs    ${refatl_ab}                \
    -seg_followers    ${refseg}                   \
    -seg_abbrevs      ${refseg_ab}                \
    -skullstrip       ${refmask}                  \
    -outdir ${aw_dir}                             \
    -ok_to_exist                                  \
    |& tee o.aw_${subj}.txt

echo "++ Done with aligning anatomical with template"

exit 0 


