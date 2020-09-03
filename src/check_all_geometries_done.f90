!
! Copyright (C) 2017 Andrea Dal Corso
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------
SUBROUTINE check_all_geometries_done(all_geometry_done)
!----------------------------------------------------------
!
!  This routine checks that the dynamical matrices of all 
!  geometries are on file. 
!  If this is the case, it verifies that all the harmonic
!  thermodynamic properties are on file or recomputes them if
!  they are not. It is called before starting any anharmonic 
!  calculation.
!

USE thermo_mod, ONLY : tot_ngeo, no_ph
USE control_elastic_constants, ONLY : start_geometry_qha, last_geometry_qha, &
                       ngeom
USE output, ONLY : fildyn

IMPLICIT NONE

LOGICAL, INTENT(OUT) :: all_geometry_done

INTEGER :: igeom, igeom_qha, iwork, work_base
LOGICAL  :: check_dyn_file_exists

all_geometry_done=.TRUE.
work_base=tot_ngeo/ngeom
DO igeom_qha=start_geometry_qha, last_geometry_qha
   DO iwork=1,work_base
      igeom=(igeom_qha-1)*work_base+iwork
      IF (no_ph(igeom)) CYCLE
      CALL set_fildyn_name(igeom)
      IF (all_geometry_done) all_geometry_done=all_geometry_done.AND. &
           check_dyn_file_exists(fildyn)
      IF (.NOT.all_geometry_done) RETURN
   ENDDO
ENDDO
!
!  When start_geometry and last_geometry are used and we arrive here the
!  dynamical matrices for the missing geometries are on file and
!  we read the thermal properties of the geometries not computed in this run
!
CALL check_thermo_all_geo()

RETURN
END SUBROUTINE check_all_geometries_done

