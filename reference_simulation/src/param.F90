! -*-F90-*-
!
!======================================================================
!
!     basin_param: $BDj?t$N@_Dj(B
!
!     Basic Parameters of the Model
!
!     If the region to be analyzed is changed,
!       never forget to change parameter "slat".
!
!----------------------------------------------------------------------
!
module basin_param

  implicit none

  integer(4), parameter :: imut = 364, jmut = 368, km = 51
  integer(4), parameter :: ksgm = 5

  real(8), parameter :: PI =       3.141592653589793D0  ! $B1_<~N((B
  real(8), parameter :: RADIAN =   180.D0/PI
  real(8), parameter :: radian_r = 1.d0/radian
  real(8), parameter :: OMEGA =    PI/43082.D0   ! $BCO5e$N2sE>3QB.EY(B
  real(8), parameter :: RADIUS =   6375.D3       ! $BCO5e$NH>7B(B
  real(8), parameter :: RADIUR =   1.D0/RADIUS   ! $BCO5e$NH>7B$N5U?t(B
  real(8), parameter :: GRAV =     9.81D0        ! $B=ENO2CB.EY(B

  real(8), parameter :: ro   =     1.036d3       ! $B3$?e$NL)EY(B
  real(8), parameter :: cp   =     3.99d3       ! $B3$?e$NL)EY(B

  real(8), parameter :: SLAT0 = -78.D0  !  $B3$0h$NFnC<0^EY(B
  real(8), parameter :: SLON0 = 0.D0    !  $B3$0h$NElC<7PEY(B

  real(8), parameter :: NPLAT = 64.D0   ! $B%b%G%k$NKL6KE@$NCOM}:BI8$K$*$1$k0^EY(B
  real(8), parameter :: NPLON = 80.D0   ! $B%b%G%k$NKL6KE@$NCOM}:BI8$K$*$1$k7PEY(B
  real(8), parameter :: SPLAT = 64.D0   ! $B%b%G%k$NKL6KE@$NCOM}:BI8$K$*$1$k0^EY(B
  real(8), parameter :: SPLON = 260.D0  ! $B%b%G%k$NKL6KE@$NCOM}:BI8$K$*$1$k7PEY(B

  include 'dz.F90'

end module basin_param
