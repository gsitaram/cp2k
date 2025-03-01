!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright 2000-2021 CP2K developers group <https://cp2k.org>                                   !
!                                                                                                  !
!   SPDX-License-Identifier: GPL-2.0-or-later                                                      !
!--------------------------------------------------------------------------------------------------!

! **************************************************************************************************
!> \brief Types needed for MP2 calculations
!> \par History
!>       2011.05 created [Mauro Del Ben]
!> \author MDB
! **************************************************************************************************
MODULE mp2_types
   USE cp_eri_mme_interface,            ONLY: cp_eri_mme_finalize,&
                                              cp_eri_mme_param
   USE cp_fm_types,                     ONLY: cp_fm_p_type
   USE cp_para_types,                   ONLY: cp_para_env_type
   USE dbcsr_api,                       ONLY: dbcsr_p_type,&
                                              dbcsr_type
   USE hfx_types,                       ONLY: hfx_release,&
                                              hfx_type,&
                                              pair_list_element_type
   USE input_constants,                 ONLY: do_eri_mme,&
                                              mp2_method_direct,&
                                              mp2_method_gpw,&
                                              mp2_method_none,&
                                              mp2_ri_optimize_basis,&
                                              ri_mp2_laplace,&
                                              ri_mp2_method_gpw,&
                                              ri_rpa_method_gpw
   USE kinds,                           ONLY: dp
   USE libint_2c_3c,                    ONLY: libint_potential_type
   USE machine,                         ONLY: m_walltime
   USE message_passing,                 ONLY: mp_sum
   USE qs_force_types,                  ONLY: qs_force_type
   USE qs_p_env_types,                  ONLY: qs_p_env_type
#include "./base/base_uses.f90"

   IMPLICIT NONE

   PRIVATE

   CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'mp2_types'

   PUBLIC :: mp2_type, &
             integ_mat_buffer_type, &
             integ_mat_buffer_type_2D, &
             mp2_method_none, &
             mp2_method_direct, &
             mp2_method_gpw, &
             mp2_ri_optimize_basis, &
             ri_mp2_method_gpw, &
             ri_rpa_method_gpw, &
             ri_mp2_laplace, &
             init_TShPSC_lmax

   PUBLIC :: mp2_env_create, mp2_env_release, mp2_biel_type, &
             pair_list_type_mp2, &
             one_dim_int_array, &
             two_dim_int_array, &
             one_dim_real_array, &
             two_dim_real_array, &
             three_dim_real_array, &
             dgemm_counter_type, &
             dgemm_counter_init, &
             dgemm_counter_start, &
             dgemm_counter_stop, &
             dgemm_counter_write

   INTEGER, SAVE                                         :: init_TShPSC_lmax = -1

! TYPE definitions

   TYPE one_dim_int_array
      INTEGER, DIMENSION(:), ALLOCATABLE    :: array
   END TYPE

   TYPE two_dim_int_array
      INTEGER, DIMENSION(:, :), ALLOCATABLE :: array
   END TYPE

   TYPE one_dim_real_array
      REAL(KIND=dp), DIMENSION(:), ALLOCATABLE :: array
   END TYPE

   TYPE two_dim_real_array
      REAL(KIND=dp), DIMENSION(:, :), ALLOCATABLE :: array
   END TYPE

   TYPE three_dim_real_array
      REAL(KIND=dp), DIMENSION(:, :, :), ALLOCATABLE :: array
   END TYPE

   TYPE mp2_biel_type
      INTEGER, DIMENSION(:, :), ALLOCATABLE :: index_table
   END TYPE mp2_biel_type

   TYPE mp2_laplace_type
      INTEGER       :: n_quadrature
      INTEGER       :: integ_group_size
      LOGICAL       :: mo_sos
      REAL(dp)      :: threshold
   END TYPE

   TYPE mp2_direct_type
      LOGICAL  :: big_send
   END TYPE

   TYPE mp2_gpw_type
      REAL(KIND=dp)            :: eps_grid, eps_filter, eps_pgf_orb_S
      INTEGER                  :: print_level
      REAL(KIND=dp)            :: cutoff
      REAL(KIND=dp)            :: relative_cutoff
      INTEGER                  :: size_lattice_sum
   END TYPE mp2_gpw_type

   TYPE ri_mp2_type
      INTEGER                  :: block_size
      REAL(dp)                 :: eps_canonical
      LOGICAL                  :: free_hfx_buffer
   END TYPE

   TYPE ri_rpa_type
      INTEGER                  :: rpa_num_quad_points
      INTEGER                  :: rpa_integ_group_size
      INTEGER                  :: mm_style
      TYPE(hfx_type), DIMENSION(:, :), POINTER &
         :: x_data
      LOGICAL                  :: minimax_quad
      LOGICAL                  :: do_ri_g0w0
      LOGICAL                  :: do_admm
      LOGICAL                  :: do_ri_axk
      LOGICAL                  :: do_rse
      TYPE(dbcsr_type), POINTER             :: mo_coeff_o, &
                                               mo_coeff_v
      REAL(KIND=dp)            :: ener_axk
      REAL(KIND=dp)            :: rse_corr_diag
      REAL(KIND=dp)            :: rse_corr
      REAL(KIND=dp)            :: scale_rpa
   END TYPE

   TYPE ri_rpa_im_time_type
      INTEGER                  :: cut_memory
      LOGICAL                  :: memory_info
      REAL(KIND=dp)            :: eps_filter, cutoff, &
                                  exp_kpoints, eps_filter_factor, eps_compress
      INTEGER                  :: group_size_P, group_size_3c
      INTEGER, DIMENSION(:), POINTER     :: kp_grid
      LOGICAL                  :: do_im_time_kpoints
      INTEGER                  :: min_bsize, min_bsize_mo
   END TYPE

   TYPE ri_g0w0_type
      INTEGER                  :: corr_mos_occ
      INTEGER                  :: corr_mos_virt
      INTEGER                  :: corr_mos_occ_beta
      INTEGER                  :: corr_mos_virt_beta
      INTEGER                  :: num_poles
      INTEGER                  :: nparam_pade
      INTEGER                  :: analytic_continuation
      REAL(KIND=dp)            :: omega_max_fit
      INTEGER                  :: crossing_search
      REAL(KIND=dp)            :: fermi_level_offset
      INTEGER                  :: iter_evGW, iter_sc_GW0
      REAL(KIND=dp)            :: eps_iter
      LOGICAL                  :: do_ri_Sigma_x, &
                                  do_periodic, &
                                  print_self_energy
      REAL(KIND=dp), ALLOCATABLE, DIMENSION(:, :, :) :: vec_Sigma_x_minus_vxc_gw
      INTEGER, DIMENSION(:), POINTER    :: kp_grid
      INTEGER                  :: num_kp_grids
      REAL(KIND=dp)            :: eps_kpoint
      LOGICAL                  :: do_mo_coeff_gamma, do_average_deg_levels
      REAL(KIND=dp)            :: eps_eigenval
      LOGICAL                  :: do_extra_kpoints, do_aux_bas_gw
      REAL(KIND=dp)            :: frac_aux_mos
      INTEGER                  :: num_omega_points
      LOGICAL                  :: do_bse
      INTEGER                  :: num_z_vectors, max_iter_bse
      REAL(KIND=dp)            :: eps_min_trans
      LOGICAL                  :: do_ic_model, print_ic_values
      REAL(KIND=dp)            :: eps_dist
      TYPE(one_dim_real_array), DIMENSION(2) :: ic_corr_list
      INTEGER :: print_exx
      LOGICAL :: do_gamma_only_sigma
      LOGICAL :: update_xc_energy
   END TYPE

   TYPE ri_basis_opt
      REAL(KIND=dp)            :: DI_rel
      REAL(KIND=dp)            :: DRI
      REAL(KIND=dp)            :: eps_step
      INTEGER                  :: max_num_iter
      INTEGER                  :: basis_quality
      INTEGER, DIMENSION(:), ALLOCATABLE :: RI_nset_per_l
   END TYPE

   TYPE grad_util
      TYPE(two_dim_real_array), DIMENSION(2) :: P_ij, P_ab, Gamma_PQ, Gamma_PQ_2
      TYPE(three_dim_real_array), DIMENSION(2) :: Gamma_P_ia
      REAL(KIND=dp), DIMENSION(:, :), ALLOCATABLE :: operator_half, PQ_half
      TYPE(dbcsr_p_type), DIMENSION(:, :), ALLOCATABLE :: G_P_ia
      TYPE(dbcsr_p_type), DIMENSION(:), ALLOCATABLE :: mo_coeff_o, mo_coeff_v
      TYPE(cp_fm_p_type), ALLOCATABLE, DIMENSION(:) :: P_mo, W_mo, L_jb
      REAL(KIND=dp) :: cphf_eps_conv
      INTEGER :: cphf_max_num_iter
      TYPE(qs_p_env_type), POINTER :: p_env => NULL()
      TYPE(qs_force_type), DIMENSION(:), POINTER :: mp2_force
      REAL(KIND=dp), DIMENSION(3, 3) :: mp2_virial
   END TYPE

   TYPE mp2_type
      INTEGER                  :: method
      TYPE(mp2_laplace_type)   :: ri_laplace
      TYPE(mp2_direct_type)    :: direct_canonical
      TYPE(libint_potential_type) :: potential_parameter
      TYPE(mp2_gpw_type)       :: mp2_gpw
      TYPE(ri_mp2_type)        :: ri_mp2
      TYPE(ri_rpa_type)        :: ri_rpa
      TYPE(ri_rpa_im_time_type) &
         :: ri_rpa_im_time
      TYPE(ri_g0w0_type)       :: ri_g0w0
      TYPE(ri_basis_opt)       :: ri_opt_param
      TYPE(grad_util)          :: ri_grad
      REAL(dp) :: mp2_memory
      REAL(dp) :: scale_S
      REAL(dp) :: scale_T
      INTEGER  :: mp2_num_proc
      INTEGER  :: block_size_row
      INTEGER  :: block_size_col
      LOGICAL  :: calc_PQ_cond_num
      LOGICAL  :: hf_fail
      LOGICAL  :: p_screen
      LOGICAL  :: not_last_hfx
      LOGICAL  :: do_im_time
      INTEGER  :: eri_method
      TYPE(cp_eri_mme_param), POINTER  :: eri_mme_param
      INTEGER, DIMENSION(:), POINTER  :: eri_blksize => NULL()
      LOGICAL  :: do_svd
      REAL(KIND=dp) :: eps_range
      TYPE(libint_potential_type) :: ri_metric
   END TYPE

   TYPE integ_mat_buffer_type
      REAL(KIND=dp), DIMENSION(:), ALLOCATABLE  :: msg
      INTEGER, DIMENSION(:), ALLOCATABLE  :: sizes
      INTEGER, DIMENSION(:, :), ALLOCATABLE  :: indx
      INTEGER :: proc
      INTEGER :: msg_req
   END TYPE

   TYPE integ_mat_buffer_type_2D
      REAL(KIND=dp), DIMENSION(:, :), ALLOCATABLE  :: msg
      INTEGER :: proc
      INTEGER :: msg_req
   END TYPE

   TYPE pair_list_type_mp2
      TYPE(pair_list_element_type), DIMENSION(:), ALLOCATABLE :: elements
      INTEGER :: n_element
   END TYPE pair_list_type_mp2

   TYPE dgemm_counter_type
      PRIVATE
      REAL(KIND=dp) :: flop_rate, t_start
      INTEGER :: num_dgemm_call
   END TYPE

CONTAINS

! **************************************************************************************************
!> \brief ...
!> \param mp2_env ...
! **************************************************************************************************
   SUBROUTINE mp2_env_release(mp2_env)
      TYPE(mp2_type), POINTER                            :: mp2_env

      CHARACTER(LEN=*), PARAMETER                        :: routineN = 'mp2_env_release'

      INTEGER                                            :: handle

      CALL timeset(routineN, handle)

      CPASSERT(ASSOCIATED(mp2_env))

      ! release the HFX section for the EXX calculation
      IF (ASSOCIATED(mp2_env%ri_rpa%x_data)) THEN
         CALL hfx_release(mp2_env%ri_rpa%x_data)
      END IF

      IF (mp2_env%eri_method .EQ. do_eri_mme) CALL cp_eri_mme_finalize(mp2_env%eri_mme_param)
      IF (ASSOCIATED(mp2_env%eri_mme_param)) DEALLOCATE (mp2_env%eri_mme_param)

      DEALLOCATE (mp2_env)

      CALL timestop(handle)

   END SUBROUTINE mp2_env_release

! **************************************************************************************************
!> \brief ...
!> \param mp2_env ...
! **************************************************************************************************
   SUBROUTINE mp2_env_create(mp2_env)
      TYPE(mp2_type), POINTER                            :: mp2_env

      CHARACTER(LEN=*), PARAMETER                        :: routineN = 'mp2_env_create'

      INTEGER                                            :: handle

      CALL timeset(routineN, handle)

      CPASSERT(.NOT. ASSOCIATED(mp2_env))

      ALLOCATE (mp2_env)

      NULLIFY (mp2_env%ri_rpa%x_data)

      CALL timestop(handle)

   END SUBROUTINE mp2_env_create

! **************************************************************************************************
!> \brief Initialize a dgemm_counter
!> \param dgemm_counter ...
! **************************************************************************************************
   ELEMENTAL SUBROUTINE dgemm_counter_init(dgemm_counter)
      TYPE(dgemm_counter_type), INTENT(OUT)              :: dgemm_counter

      CHARACTER(LEN=*), PARAMETER :: routineN = 'dgemm_counter_init'

      dgemm_counter%num_dgemm_call = 0
      dgemm_counter%flop_rate = 0.0

   END SUBROUTINE dgemm_counter_init

! **************************************************************************************************
!> \brief start timer of the counter
!> \param dgemm_counter ...
! **************************************************************************************************
   SUBROUTINE dgemm_counter_start(dgemm_counter)
      TYPE(dgemm_counter_type), INTENT(INOUT)            :: dgemm_counter

      CHARACTER(LEN=*), PARAMETER :: routineN = 'dgemm_counter_start'

      dgemm_counter%t_start = m_walltime()

   END SUBROUTINE dgemm_counter_start

! **************************************************************************************************
!> \brief stop timer of the counter and provide matrix sizes
!> \param dgemm_counter ...
!> \param size1 ...
!> \param size2 ...
!> \param size3 ...
! **************************************************************************************************
   SUBROUTINE dgemm_counter_stop(dgemm_counter, size1, size2, size3)
      TYPE(dgemm_counter_type), INTENT(INOUT)            :: dgemm_counter
      INTEGER, INTENT(IN)                                :: size1, size2, size3

      CHARACTER(LEN=*), PARAMETER :: routineN = 'dgemm_counter_stop'

      REAL(KIND=dp)                                      :: flop_rate, t_end

      t_end = m_walltime()
      flop_rate = 2.0_dp*REAL(size1, dp)*REAL(size2, dp)*REAL(size3, dp)/MAX(0.001_dp, t_end - dgemm_counter%t_start)
      dgemm_counter%flop_rate = dgemm_counter%flop_rate + flop_rate
      dgemm_counter%num_dgemm_call = dgemm_counter%num_dgemm_call + 1

   END SUBROUTINE dgemm_counter_stop

! **************************************************************************************************
!> \brief calculate and print flop rates
!> \param dgemm_counter ...
!> \param para_env ...
!> \param unit_nr ...
! **************************************************************************************************
   SUBROUTINE dgemm_counter_write(dgemm_counter, para_env, unit_nr)
      TYPE(dgemm_counter_type), INTENT(INOUT)            :: dgemm_counter
      TYPE(cp_para_env_type), INTENT(IN), POINTER        :: para_env
      INTEGER, INTENT(IN)                                :: unit_nr

      CHARACTER(LEN=*), PARAMETER :: routineN = 'dgemm_counter_write'

      dgemm_counter%flop_rate = dgemm_counter%flop_rate/REAL(MAX(dgemm_counter%num_dgemm_call, 1), dp)/1.0E9_dp
      CALL mp_sum(dgemm_counter%flop_rate, para_env%group)
      dgemm_counter%flop_rate = dgemm_counter%flop_rate/REAL(para_env%num_pe, dp)
      IF (unit_nr > 0) WRITE (UNIT=unit_nr, FMT="(T3,A,T66,F15.2)") &
         "PERFORMANCE| DGEMM flop rate (Gflops / MPI rank):", dgemm_counter%flop_rate

   END SUBROUTINE dgemm_counter_write

END MODULE mp2_types
