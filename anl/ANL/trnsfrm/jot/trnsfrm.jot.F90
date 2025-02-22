! -*-F90-*-
!
!     MRI.COM(気象研究所統合海洋モデル)stmdlp.F90
!       Copyright 2001-2003 Oceanographic Research Dept.,MRI-JMA
!
!=================================================================
!                                                                 
!     trnsfrm: 一般直交座標<−>地理座標 変換ルーチン群
!                       （一次分数変換対応）
!                                                                 
!     
!                                                                 
!=================================================================
!
!  trnsfrm : 
!    subroutine set_abc
!    subroutine mp2lp
!    subroutine rot_mp2lp
!    subroutine lp2mp
!    function   length_on_sphere
!                      を含む
!
module oc_mod_trnsfrm
!====================================================
!
! 一般直交座標<−>地理座標 変換ルーチン群
!                    （Joukowski変換対応）
!
!====================================================
  implicit none
  real(8), parameter, private :: pi=3.141592653589793d0  ! 円周率
  real(8), parameter, private :: radian=180.d0/pi
  real(8), parameter, private :: radian_r=1.d0/radian
  real(8), parameter, private :: radius = 6375.d5    
  complex(8), private, save :: ac
  real(8), private, save :: rcjot, rsjot  
  real(8), private, save :: nplat, nplon, splat, splon
  !
contains
!====================================================
!
!  Joukowski変換のパラメータac,rcjot,rsjotを決める
!
!====================================================
  subroutine set_abc ( nplat0, nplon0, splat0, splon0 )
    !
    real(8),intent(in) :: nplat0, nplon0, splat0, splon0
    real(8) :: p_jot, q_jot
    !
    nplat = nplat0
    nplon = nplon0
    splat = splat0
    splon = splon0
    ! 
    p_jot=NPLAT*radian_r ! つぶす緯度円の北極からの角度
    p_jot=tan(0.5*p_jot)  ! 複素平面上での基準半径
    ac=cmplx(p_jot*p_jot, 0.d0)
    !
    q_jot=NPLON*radian_r ! 南北軸での回転
    rcjot=cos(q_jot)
    rsjot=sin(q_jot)
    !
  end subroutine set_abc
!====================================================
!
!  λ,φ(μ,Ψ)
!
!====================================================
  subroutine mp2lp(lambda, phi, mu, psi0 )
    !
    real(8), intent(out)  :: lambda, phi
    real(8), intent(in)   :: mu, psi0
    !
    real(8)     :: psi
    real(8)     :: tmp1,tmp2
    complex(8) :: z,zeta
    !!!!!complex(16) :: z,zeta   ! old code
    !
    !
    psi=0.5d0*pi-psi0
    !
    zeta=cmplx(cos(mu),sin(mu))
    zeta=zeta*tan(0.5d0*psi)
    !
    z=cmplx(rcjot, rsjot)
    z=z*(zeta+ac/zeta)
    !
    tmp1=abs(z)              ! |z|
    phi=2.d0*atan(tmp1)
    !
    tmp1=real(z, 8)
    tmp2=imag(z)
    !                      zの偏角
    if(tmp1 > 0.d0) then
      lambda=atan(tmp2/tmp1)
    else if(tmp1 == 0.d0) then
      if(tmp2 < 0.d0) then
        lambda=-0.5d0*pi
      else
        lambda=0.5d0*pi
      end if
    else
      if(tmp2 < 0.d0) then
        lambda=atan(tmp2/tmp1)-pi
      else
        lambda=atan(tmp2/tmp1)+pi
      end if
    end if
    !
    phi=0.5d0*pi-phi
    !
  end subroutine mp2lp
!====================================================
!
!  ベクトルの回転cosθ,sinθ(μ,Ψ)
!
!====================================================
  subroutine rot_mp2lp(rot_cos,rot_sin,lambda0, phi0, mu0, psi0)
    !
    real(8), intent(out)  :: rot_cos, rot_sin
    real(8), intent(in)   :: lambda0, phi0
    real(8), intent(in)   :: mu0, psi0
    !
    real(8)     :: psi, phi
    real(8)     :: tmp1, tmp2
    complex(8)  :: ctmp0, ctmp, z, zeta
    !
    psi=0.5d0*pi-psi0
    !
    tmp1=tan(0.5d0*psi)*cos(mu0)
    tmp2=tan(0.5d0*psi)*sin(mu0)
    zeta=cmplx(tmp1,tmp2)  !  mu0, psi から zeta
    !
    phi=0.5d0*pi-phi0
    tmp1=dtan(0.5d0*phi)*dcos(lambda0)
    tmp2=dtan(0.5d0*phi)*dsin(lambda0)
    z=cmplx(tmp1,tmp2)  !  lambda0, phi から z
    !
    ctmp0=cmplx(rcjot, rsjot)
    ctmp=ctmp0*(1.d0 -ac/zeta/zeta) ! dz/dzeta(zeta0)
    !
    ctmp=z/zeta/ctmp
    !
    rot_cos=real(ctmp, 8)
    rot_sin=imag(ctmp)
    tmp1=sqrt(rot_cos*rot_cos+rot_sin*rot_sin)
    rot_cos=rot_cos/tmp1
    rot_sin=rot_sin/tmp1
    !
  end subroutine rot_mp2lp
!====================================================
!
!  μ,Ψ(λ,φ)
!
!====================================================
  subroutine lp2mp(mu, psi, lambda, phi0)
    !
    real(8), intent(out)    :: mu, psi
    real(8), intent(in)     :: lambda, phi0
    !
    real(8)    :: phi
    real(8)    :: tmp1,tmp2
    complex(8) :: ctmp1, z, zeta0, zetap, zetam
    !
    phi=0.5d0*pi-phi0
    !
    tmp1=tan(0.5d0*phi)*cos(lambda)
    tmp2=tan(0.5d0*phi)*sin(lambda)
    z=cmplx(tmp1,tmp2)  !  lambda,phi から z
    !
    zeta0=cmplx(rcjot, -rsjot)
    zeta0=0.5d0*z*zeta0
    !
    ctmp1=zeta0*zeta0-ac
    ctmp1=sqrt(ctmp1)
    zetap=zeta0+ctmp1    !  ζ
    zetam=zeta0-ctmp1    !  ζ
    !
    tmp1=max(abs(zetap),abs(zetam))  ! |ζ|
    psi=2.d0*atan(tmp1)
    !
    if(abs(zetap) >= abs(zetam)) then
      tmp1=real(zetap)
      tmp2=aimag(zetap)
    else
      tmp1=real(zetam)
      tmp2=imag(zetam)
    end if
    !                     zの偏角
    if(tmp1 > 0.d0) then
      mu=atan(tmp2/tmp1)
    else if(tmp1 == 0.d0) then
      if(tmp2 < 0.d0) then
        mu=-0.5d0*pi
      else
        mu=0.5d0*pi
      end if
    else
      if(tmp2 < 0.d0) then
        mu=atan(tmp2/tmp1)-pi
      else
        mu=atan(tmp2/tmp1)+pi
      end if
    end if
    !
    psi=0.5d0*pi-psi
    !
  end subroutine lp2mp
!====================================================
!
! (λ1,φ1)−(λ2,φ2)間の大円距離:pi/2以内
!
!====================================================
  real(8) function length_on_sphere(lambda1, phi1, lambda2, phi2)
    !
    real(8), intent(in)  :: lambda1, phi1, lambda2, phi2
    !
    real(8)    :: xx, yy, zz
    real(8)    :: ww, theta
    !
    !
    xx = dcos(phi1)*dcos(lambda1)-dcos(phi2)*dcos(lambda2)
    yy = dcos(phi1)*dsin(lambda1)-dcos(phi2)*dsin(lambda2)
    zz = dsin(phi1)-dsin(phi2)
    ww = dsqrt(xx*xx + yy*yy + zz*zz)
    !
    theta=dasin(0.5d0*ww)
    length_on_sphere=2.d0*radius*theta
    !
  end function length_on_sphere
!=================================================================
end module oc_mod_trnsfrm
