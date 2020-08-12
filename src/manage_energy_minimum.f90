!
! Copyright (C) 2013-2015 Andrea Dal Corso
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!------------------------------------------------------
SUBROUTINE manage_energy_minimum(nwork)
!------------------------------------------------------
!
!  This routine coordinates the work to find the minimum
!  of the total energy as a function of the crystal
!  parameters.
!

USE kinds,            ONLY : DP
USE thermo_mod,       ONLY : celldm_geo, omega_geo, central_geo, density, &
                             energy_geo
USE control_mur,      ONLY : vmin, b0, b01, emin, lmurn
USE equilibrium_conf, ONLY : celldm0, omega0, tau0, at0, tau0_crys
USE initial_conf,     ONLY : ibrav_save, tau_save_crys
USE control_xrdp,     ONLY : lxrdp

USE ions_base,        ONLY : nat, tau
USE cell_base,        ONLY : at, bg, omega, cell_base_init

USE io_global,        ONLY : meta_ionode_id
USE mp_images,        ONLY : nproc_image
USE mp_world,         ONLY : world_comm
USE mp,               ONLY : mp_sum, mp_bcast

IMPLICIT NONE
INTEGER, INTENT(IN) :: nwork

REAL(DP)            :: rd_ht(3,3), zero
LOGICAL             :: trd_ht
CHARACTER(LEN=10)   :: cell_units
!
!  First collect the total energies
!
CALL mp_sum(energy_geo, world_comm)
energy_geo=energy_geo / nproc_image

IF (lmurn) THEN
   CALL do_ev()
   CALL write_mur(vmin,b0,b01,emin)
   CALL plot_mur()
   CALL compute_celldm_geo(vmin, celldm0, &
                   celldm_geo(1,central_geo), omega_geo(central_geo))
ELSE
   CALL write_gnuplot_energy(nwork)
   CALL quadratic_fit()
   CALL write_quadratic()
   CALL plot_multi_energy()
   CALL write_e_omega()
   CALL plot_mur()
ENDIF
CALL mp_bcast(celldm0, meta_ionode_id, world_comm)
CALL mp_bcast(emin, meta_ionode_id, world_comm)
CALL write_minimum_energy_data()
trd_ht=.FALSE.
rd_ht=0.0_DP
zero=0.0_DP
cell_units='alat'
CALL cell_base_init ( ibrav_save, celldm0, zero, zero, zero, zero, &
                                      zero, zero, trd_ht, rd_ht, cell_units )
CALL set_fft_mesh()
omega0=omega
at0(:,:)=at(:,:)
!
!   strain the initial tau uniformly to the new at and set the equilibrium tau
!   to the strained tau
!
CALL adjust_tau(tau_save_crys, tau, at)
tau0=tau
!
!  bring the strained tau in crystal coordinates
!
tau0_crys=tau
CALL cryst_to_cart(nat, tau0_crys, bg, -1)
!
!  recompute the density at the minimum volume
!
     CALL compute_density(omega,density)
!
!  compute the xrdp at the minimum volume if required by the user
!
     IF (lxrdp) CALL manage_xrdp(' ')

RETURN
END SUBROUTINE manage_energy_minimum
