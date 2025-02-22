!-*-F90-*-
!hs2mocip.F90
!====================================================
!
! Make Meridional Overturning Streamfunction
!     Potential Density - Latitude
!
!====================================================
program meridional_transport_ip
  !
  use oc_mod_param, only : &
  &   imut, jmut, km,      &
  &   imx, jmx,            &
  &   ksgm, dz,            &
  &   pi, radian, radian_r, &
  &   slat0, slon0,        &
  &   nplat, nplon,        &
  &   splat, splon,        &
  &   ro,    cp
#ifndef OGCM_VARIABLE
  use oc_mod_param, only : &
  &   dxtdgc, dytdgc
#endif /* ! OGCM_VARIABLE */
  !
  use oc_mod_trnsfrm, only  : &
  &   set_abc, mp2lp,         &
  &   length_on_sphere
  !
  use oc_structure, only  : &
  &   read_topo,            & !--------
  &   dep,                  &
  &   ho4, exnn ,           &
  &   aexl, atexl,          &
#ifdef OGCM_BBL
  &   ho4bbl, exnnbbl,      &
  &   aexlbbl, atexlbbl,    &
#endif /* OGCM_BBL */
  &   dzu,                  &
  &   thcksgm, thcksgmr,    &
  &   read_scale,           & !--------
  &   a_tl  , a_tr  ,       &
  &   a_bl  , a_br  ,       &
  &   dx_tl , dx_tr ,       &
  &   dx_bl , dx_br ,       &
  &   dy_tl , dy_tr ,       &
  &   dy_bl , dy_br ,       &
  &   set_hgrids,            & !--------
  &   dxtdeg, dytdeg,       &
  &   dxudeg, dyudeg,       &
  &   slat, slon,           &
  &   alatt, alatu,         &
  &   alont, alonu
  !
  !
  use oc_mod_density, only : &
  &   dens
  !
  !----------------------------------------------
  !
  implicit none
  !
  !
  real(8), parameter    :: dlatg =   1.0d0
  real(8), parameter    :: slatg  = real(slat0, 8)
  integer(4), parameter :: jmgeo = 75 + 1 -slat0
  !
  ! 海面フラックス積算用緯度区切り
  !
  ! 海洋モデル地形
  !
  integer(4) :: ibas(imut, jmut)      ! basin区分, UV-Grid
  !
  !             0:LAND, 1:ATL, 2:PAC, 3:IND, 4:MED, 9:SO
  !
  integer(4) :: mask_glb(imut, jmut) ! 全球海洋      1 or -1
  integer(4) :: mask_atl(imut, jmut) ! 大西洋+地中海 1 or -1
  integer(4) :: mask_pac(imut, jmut) ! 太平洋        1 or -1
  integer(4) :: mask_ind(imut, jmut)
  real(8)    :: ibm(imut, jmut)      ! 積算で使用する海盆マスク(1 or 0)
  real(8)    :: asfc_t(imut, jmut)   ! 海面T格子面積
  real(8)    :: mu_u, psiu, lambdau, phiu
  !
  real(8)    :: u(imut, jmut, km)
  real(8)    :: v(imut, jmut, km)
  real(8)    :: t(imut, jmut, km)
  real(8)    :: s(imut, jmut, km)
  real(8)    :: rho(imut, jmut, km) ! [g/cm^3] => rho-1000 [kg/m^3]
  real(8)    :: ssh(imut, jmut)
  !
  real(8)    :: refpress
  real(8)    :: pressure(km)
  !
  real(8)    :: rho_sep(4) ! (1) surface, (2) upper thermocline (3) lower thermocline (4) bottom
  real(8)    :: rho_int(3) ! (1) seasonal thermocline (2) main thermocline (3) deep layer
  integer(4) :: rl_sep(4)
  integer(4) :: RLMAX
  real(8),allocatable :: rholev(:)
  real(8),allocatable :: rholev_half(:)
  real(8),parameter :: dr_eps = 1.0d-6
  !
  ! k=1    :                   rholatbnd >= rholev(1)
  ! k=RLMAX: rholev(RLMAX-1) > rholatbnd 
  !
  real(8),allocatable    :: sv(:,:)
  real(4),allocatable    :: mask_sea(:,:)
  !
  ! k=1       : bottom
  ! k=RLMAX+1 : sea surface
  !
  real(4),allocatable    :: strmf_g(:,:)  ! Global
  real(4),allocatable    :: strmf_a(:,:)  ! Atlantic
  real(4),allocatable    :: strmf_p(:,:)  ! Pacific
  real(4),allocatable    :: strmf_i(:,:)  ! Indian
  !
  real(8) :: phi_std_degree ! この緯度に沿って地球を一周
  !
  !real(4), parameter :: undefgd = -9.99e33
  real(4)    :: d3_r4(imut,jmut,km)
  real(4)    :: d2_r4(imut,jmut)
  !
  ! 入出力ファイル
  !
  character(len=256)    :: flin_u
  character(len=256)    :: flin_v
  character(len=256)    :: flin_t
  character(len=256)    :: flin_s
  character(len=256)    :: flinssh
  character(len=256)    :: flout, flout2
  character(len=256)    :: fltopo
  character(len=256)    :: flsclf
  character(len=256)    :: flibas
#ifdef OGCM_VARIABLE
  character(len=256)    :: file_vgrid ! 可変格子定義ファイル
#endif /* OGCM_VARIABLE */
  !
  namelist /nml_mocip/ refpress, rho_sep, rho_int,           &
    &               flin_u, flin_v, flin_t, flin_s, flinssh, &
    &               flout, flout2, fltopo, flsclf, flibas
#ifdef OGCM_VARIABLE
  namelist /inflg/ file_vgrid
#endif /* OGCM_VARIABLE */
  !
  integer(4) :: ios          !  入出力エラーチェック用
  integer(4), parameter :: mttmp   = 79
  integer(4), parameter :: mtin_u  = 80
  integer(4), parameter :: mtin_v  = 81
  integer(4), parameter :: mtin_t  = 82
  integer(4), parameter :: mtin_s  = 83
  integer(4), parameter :: mtinssh = 84
  integer(4), parameter :: mtout   = 85
  integer(4), parameter :: mtout2  = 86
  !
  integer(4) :: lrec_out, lrec_out2
  !
  integer(4) :: irecw, irecw2
  integer(4) :: i, j, k, m, jj
  integer(4) :: jg
  character(80) :: fmt_ibas
  !
  !==============================================
  !
  ! 入力パラメタ規定値
  !
  flin_u = 'hs_u.d'
  flin_v = 'hs_v.d'
  flin_t = 'hs_t.d'
  flin_s = 'hs_s.d'
  flinssh= 'hs_ssh.d'
  flout  = 'mrdip.d'
  flout2 = 'transip.d'
  fltopo = 'topo.d'
  flsclf = 'scale_factor.d'
  flibas = 'basin_map.txt'
  !
  ! 標準入力から読み込み
  !
  read(unit=5, nml=nml_mocip)
  print *,'ref. pressure :', refpress, ' [bar]'
  print *,'flin_u  :', trim(flin_u)
  print *,'flin_v  :', trim(flin_v)
  print *,'flin_t  :', trim(flin_t)
  print *,'flin_s  :', trim(flin_s)
  print *,'flinssh :', trim(flinssh)
  print *,'flout    :', trim(flout)
  print *,'flout2   :', trim(flout2)
  print *,'fltopo   :', trim(fltopo)
  print *,'flsclf   :', trim(flsclf)
  print *,'flibas   :', trim(flibas)
#ifdef OGCM_VARIABLE
  read(unit=5, nml=inflg) ! file_vgrid
#endif /* OGCM_VARIABLE */
  !
  pressure(1:km) = refpress ! [bar]
  !
  !----------------------------------------------

  rl_sep(1) = 1
  do m = 2, 4
    rl_sep(m) = rl_sep(m-1) + int(-(rho_sep(m)-rho_sep(m-1)) / rho_int(m-1) + dr_eps)
  end do

  write(6,*) ' density separated at '
  write(6,'(4f10.4)') (rho_sep(m),m=1,4)
  write(6,'(4i10)') (rl_sep(m),m=1,4)
  write(6,*) ' with interval '
  write(6,'(3f10.4)') (rho_int(m),m=1,3)

  rlmax = rl_sep(4)
  write(6,*) ' RLMAX = ', RLMAX

  lrec_out  = jmgeo * (RLMAX+1) * 4
  lrec_out2 = jmgeo * RLMAX * 4
  allocate(rholev(0:RLMAX))
  allocate(rholev_half(1:RLMAX))
  allocate(sv(1:jmgeo,1:RLMAX))
  allocate(mask_sea(1:jmgeo,1:RLMAX))

  allocate(strmf_g(1:jmgeo,1:RLMAX+1))  ! Global
  allocate(strmf_a(1:jmgeo,1:RLMAX+1))  ! Atlantic
  allocate(strmf_p(1:jmgeo,1:RLMAX+1))  ! Pacific
  allocate(strmf_i(1:jmgeo,1:RLMAX+1))  ! Indian

  rholev(0) = rho_sep(1) + rho_int(1)
  rholev(1) = rho_sep(1)

  do m = 2, 4
    do k = rl_sep(m-1) + 1,  rl_sep(m)
      rholev(k) = rholev(k-1) - rho_int(m-1)
    end do
  end do

  do k = 1, rlmax
    rholev_half(k) = 0.5d0 * (rholev(k-1) + rholev(k))
  end do

  write(*,*) '------'
  write(*,'(a, i4, a, f8.3)') 'ZDEF ', RLMAX+1, ' LEVELS ', rholev(0)
  write(*,'(7f8.3)') (rholev(k),k=1,rlmax)
  write(*,*) '------'

  write(*,*) '------'
  write(*,'(a, i4, a)') 'ZDEF ', RLMAX, ' LEVELS '
  write(*,'(7f8.3)') (rholev_half(k),k=1,rlmax)
  write(*,*) '------'

  !----------------------------------------------
  ! 海洋モデル格子情報等の準備
  !
  ! 座標変換のパラメータを決める
  call set_abc ( nplat, nplon, splat, splon )
  !
  ! モデル水平格子情報定義
  !
  call read_topo(fltopo)
  !
  call read_scale(flsclf)
  !
#ifdef OGCM_VARIABLE
  call set_hgrids(file_vgrid)
#else /* OGCM_VARIABLE */
  call set_hgrids
#endif /* OGCM_VARIABLE */
  !
  !----------------------------------------------
  !
  !  basinインデックス読み込み
  !
  write(fmt_ibas,"(a,i4,a)") "(i6,",imut,"i1)"
  open(mttmp, file=flibas, form="formatted")  
  do j = jmut, 1, -1
    read(mttmp, fmt=fmt_ibas,iostat=ios) jj,(ibas(i,j), i=1, imut)
    if(ios /= 0) write(*, *) 'reading error in file:', flibas
    if ( jj /= j ) then
      print *,' error in ',trim(flibas)
      stop 999
    endif
  end do
  close(mttmp)
  !
  mask_glb(1:imut, 1:jmut) = -1
  mask_atl(1:imut, 1:jmut) = -1
  mask_pac(1:imut, 1:jmut) = -1
  mask_ind(1:imut, 1:jmut) = -1
  !
  do j= 1, jmut
    do i = 1, imut
      m = ibas(i, j)
      if(m > 0) then
        mask_glb(i, j) = 1           ! Ocean: 1, Land: -1
        !if(m == 1 .or. m == 4) mask_atl(i, j) = 1 ! Atlantic or Mediterranean
        if(m == 1)             mask_atl(i, j) = 1 ! Atlantic or Mediterranean
        if(m == 2)             mask_pac(i, j) = 1 ! Pacific
        if(m == 3)             mask_ind(i, j) = 1 ! Indian
      end if
    end do
  end do
  !
  !  Pacific side half of the Arctic Sea is excluded from ATL
  !
  do j= 1, jmut
    do i = 1, imut
      mu_u = alonu(i)*radian_r
      psiu = alatu(j)*radian_r
      call mp2lp(lambdau, phiu, mu_u, psiu)
      if(phiu > 60.d0*radian_r .and. cos(lambdau) < 0.d0) mask_atl(i, j) = -1
    end do
  end do
  !
  !==============================================
  !
  ! 入出力ファイルオープン
  !
  open (mtin_u, file=flin_u, form='unformatted', &
    &  access='direct', recl=4*imut*jmut*km)
  !
  open (mtin_v, file=flin_v, form='unformatted', &
    &  access='direct', recl=4*imut*jmut*km)
  !
  open (mtin_t, file=flin_t, form='unformatted', &
    &  access='direct', recl=4*imut*jmut*km)
  !
  open (mtin_s, file=flin_s, form='unformatted', &
    &  access='direct', recl=4*imut*jmut*km)
  !
  open (mtinssh, file=flinssh, form='unformatted', &
    &  access='direct', recl=4*imut*jmut)
  !
  open (mtout, file=flout, form='unformatted',&
    &  access='direct', recl=lrec_out )
  irecw=1
  !
  open (mtout2, file=flout2, form='unformatted',&
    &  access='direct', recl=lrec_out2 )
  irecw2=1
  !
  !-------------------------
  !
  ! U
  !
  read (mtin_u, rec=1) d3_r4
  u(:,:,:) = aexl(:,:,:)*real(d3_r4(:,:,:),8)
  !
  u(1:2,         1:jmut, 1:km)=u(imut-3:imut-2, 1:jmut, 1:km)
  u(imut-1:imut, 1:jmut, 1:km)=u(3:4,           1:jmut, 1:km)
  !
  ! V
  !
  read (mtin_v, rec=1) d3_r4
  v(:,:,:) = aexl(:,:,:)*real(d3_r4(:,:,:),8)
  !
  v(1:2,         1:jmut, 1:km)=v(imut-3:imut-2, 1:jmut, 1:km)
  v(imut-1:imut, 1:jmut, 1:km)=v(3:4,           1:jmut, 1:km)
  !-------------------------
  !
  ! T
  !
  read (mtin_t, rec=1) d3_r4
  t(:,:,:) = atexl(:,:,:)*real(d3_r4(:,:,:),8)
  !
  t(1:2,         1:jmut, 1:km)=t(imut-3:imut-2, 1:jmut, 1:km)
  t(imut-1:imut, 1:jmut, 1:km)=t(3:4,           1:jmut, 1:km)
  !
  ! S
  !
  read (mtin_s, rec=1) d3_r4
  s(:,:,:) = atexl(:,:,:)*real(d3_r4(:,:,:),8)
  !
  s(1:2,         1:jmut, 1:km)=s(imut-3:imut-2, 1:jmut, 1:km)
  s(imut-1:imut, 1:jmut, 1:km)=s(3:4,           1:jmut, 1:km)
  !-------------------------
  !
  !  SSH
  !
  read (mtinssh, rec=1) d2_r4
  ssh(:,:) = atexl(:,:,1)*real(d2_r4(:,:),8)
  !
  ssh(1:2,         1:jmut)=ssh(imut-3:imut-2, 1:jmut)
  ssh(imut-1:imut, 1:jmut)=ssh(3:4,           1:jmut)
  !
  !  Sigma
  !
  call dens(imut, jmut, km, t, s, pressure, rho)
  rho(1:imut, 1:jmut, 1:km) = atexl(1:imut, 1:jmut, 1:km) * rho(1:imut, 1:jmut, 1:km) * 1.d3
  !
  !--------------------
  !  Global
  !--------------------
  print *, '       Global '
  !
  do j = 1, jmut
    do i= 1, imut
      ibm(i, j) = 0.5d0 + 0.5d0*real(mask_glb(i, j), 8)
    end do
  end do
  !
  mask_sea(1:jmgeo,1:RLMAX) = 0.0
  sv(1:jmgeo, 1:RLMAX)=0.d0
  !
  do jg=1, jmgeo
    phi_std_degree = slatg + dlatg*(jg-1)
    call around_the_world_ip(jg, phi_std_degree)
  end do
  !
  do k = RLMAX-1, 2, -1
    do j = 1, jmgeo
      mask_sea(j,k) = max(mask_sea(j,k+1), mask_sea(j,k))
    end do
  end do
  !
  strmf_g(1:jmgeo, 1)=0.0
  do k=2, RLMAX+1
    do j=1, jmgeo
      strmf_g(j,k)=strmf_g(j,k-1)-real(sv(j,k-1), 4)*1.e-12
      !    unit : cm3/s => Sv ( 10^6 m3/s )
    end do
  end do
  !
  write ( mtout2, rec=irecw2 )  real(sv(1:jmgeo, 1:RLMAX),4)
  irecw2=irecw2+1

  !--------------------
  !  Atlantic
  !--------------------
  print *, '       Atlantic '
  !
  do j = 1, jmut
    do i= 1, imut
      ibm(i, j) = 0.5d0 + 0.5d0*real(mask_atl(i, j), 8)
    end do
  end do
  !
  mask_sea(1:jmgeo,1:RLMAX) = 0.0
  sv(1:jmgeo, 1:RLMAX)=0.d0
  !
  do jg=1, jmgeo
    !
    phi_std_degree = slatg + dlatg*(jg-1)
    call around_the_world_ip(jg, phi_std_degree)
    !
  end do
  !
  do k = RLMAX-1, 2, -1
    do j = 1, jmgeo
      mask_sea(j,k) = max(mask_sea(j,k+1), mask_sea(j,k))
    end do
  end do
  !
  strmf_a(1:jmgeo, 1)=0.0
  do k=2, RLMAX+1
    do j=1, jmgeo
      strmf_a(j,k)=strmf_a(j,k-1)-real(sv(j,k-1), 4)*1.e-12
      !    unit : cm3/s => Sv ( 10^6 m3/s )
    end do
  end do

  write ( mtout2, rec=irecw2 )  real(sv(1:jmgeo, 1:RLMAX),4)
  irecw2=irecw2+1

  !--------------------
  !  Pacific
  !--------------------
  print *, '       Pacific '
  !
  do j = 1, jmut
    do i= 1, imut
      ibm(i, j) = 0.5d0 + 0.5d0*real(mask_pac(i, j), 8)
    end do
  end do
  !
  mask_sea(1:jmgeo,1:RLMAX) = 0.0
  sv(1:jmgeo, 1:RLMAX)=0.d0
  !
  do jg=1, jmgeo
    !
    phi_std_degree = slatg + dlatg*(jg-1)
    call around_the_world_ip(jg, phi_std_degree)
    !
  end do
  !
  do k = RLMAX-1, 2, -1
    do j = 1, jmgeo
      mask_sea(j,k) = max(mask_sea(j,k+1), mask_sea(j,k))
    end do
  end do
  !
  strmf_p(1:jmgeo, 1)=0.0
  do k=2, RLMAX+1
    do j=1, jmgeo
      strmf_p(j,k)=strmf_p(j,k-1)-real(sv(j,k-1), 4)*1.e-12
      !    unit : cm3/s => Sv ( 10^6 m3/s )
    end do
  end do
  !
  write ( mtout2, rec=irecw2 )  real(sv(1:jmgeo, 1:RLMAX),4)
  irecw2=irecw2+1

  !--------------------
  !  Indian
  !--------------------
  print *, '       Indian '
  !
  do j = 1, jmut
    do i= 1, imut
      ibm(i, j) = 0.5d0 + 0.5d0*real(mask_ind(i, j), 8)
    end do
  end do
  !
  mask_sea(1:jmgeo,1:RLMAX) = 0.0
  sv(1:jmgeo, 1:RLMAX)=0.d0
  !
  do jg=1, jmgeo
    !
    phi_std_degree = slatg + dlatg*(jg-1)
    call around_the_world_ip(jg, phi_std_degree)
    !
  end do
  !
  do k = RLMAX-1, 2, -1
    do j = 1, jmgeo
      mask_sea(j,k) = max(mask_sea(j,k+1), mask_sea(j,k))
    end do
  end do
  !
  strmf_i(1:jmgeo, 1)=0.0
  do k=2, RLMAX+1
    do j=1, jmgeo
      strmf_i(j,k)=strmf_i(j,k-1)-real(sv(j,k-1), 4)*1.e-12
      !    unit : cm3/s => Sv ( 10^6 m3/s )
    end do
  end do
  !
  write ( mtout2, rec=irecw2 ) real(sv(1:jmgeo, 1:RLMAX),4)
  irecw2=irecw2+1

  !--------------------------------------------
  write ( mtout, rec=irecw )  strmf_g(1:jmgeo, 1:RLMAX+1)
  irecw=irecw+1
  !
  write ( mtout, rec=irecw )  strmf_a(1:jmgeo, 1:RLMAX+1)
  irecw=irecw+1
  !
  write ( mtout, rec=irecw )  strmf_p(1:jmgeo, 1:RLMAX+1)
  irecw=irecw+1
  !
  write ( mtout, rec=irecw )  strmf_i(1:jmgeo, 1:RLMAX+1) + strmf_p(1:jmgeo, 1:RLMAX+1)
  irecw=irecw+1
  !
  close ( mtin_u )
  close ( mtin_v )
  close ( mtin_t )
  close ( mtin_s )
  close ( mtinssh)
  close ( mtout )
  close ( mtout2 )
  !
contains
!====================================================
!
!  指定緯度で世界一周
!
!====================================================
subroutine around_the_world_ip(jg, phi_std_degree)
  !
  integer(4), intent(IN) :: jg
  real(8),    intent(IN) :: phi_std_degree
  !
  !
  real(8) :: rholatbnd(km)  ! density at uv-star points
  !
#ifdef OGCM_BBL
  integer(4), parameter :: kmax = km-1
#else /* OGCM_BBL */
  integer(4), parameter :: kmax = km
#endif /* OGCM_BBL */
  !
  integer(4) :: i00, j00, ic, jc, jend
  !
  real(8)    :: phi_std
  real(8)    :: mu0,  mu2
  real(8)    :: psi0, psi1, psi2
  !
  real(8)    :: lambda00,  lambda20,  lambda01,  lambda02
  real(8)    :: phi00, phi20, phi01, phi02
  !
  real(8)    :: sqphi00, sqphi20, sqphi01, sqphi02
  real(8)    :: sqphimin
  real(8)    :: ustar(km), vstar(km)
  real(8)    :: hl1, hl2
  !
  real(8)    :: u_done(imut, jmut)
  !
  integer(4) :: j, k, m
  !
  phi_std = phi_std_degree*radian_r
  !
  u_done(1:imut, 1:jmut) = 0.d0
  !
  u_done(1:2,    1:jmut) = 1.d0
  u_done(imut,   1:jmut) = 1.d0
  u_done(1:imut, 1)      = 1.d0
  u_done(1:imut, jmut-2:jmut)   = 1.d0
  !
  i00=4
  mu0 = alont(i00)*radian_r
  sqphimin=pi*pi
  do j = 3, jmut-1
    ! TSレンジで探索
    psi0 = alatt(j)*radian_r
    call mp2lp(lambda00, phi00, mu0, psi0)
    sqphi00 = (phi00-phi_std)*(phi00-phi_std)
    if(sqphi00 < sqphimin) then
      sqphimin = sqphi00
      j00 = j
    end if
  end do
  !
  i00=i00-1  !  UV格子
  j00=j00-1
  !
  u_done(i00, j00)  = 1.d0
  u_done(i00, j00+1)= 1.d0
  !
  mu0  = alonu(i00)*radian_r
  !mu2  = alonu(i00+1)*radian_r ! mu2 is not used here
  psi0 = alatu(j00)*radian_r
  psi2 = alatu(j00+1)*radian_r
  !
  call mp2lp(lambda00, phi00, mu0, psi0)
  call mp2lp(lambda02, phi02, mu0, psi2)
  !
  sqphi00 = (phi00-phi_std)*(phi00-phi_std)
  sqphi02 = (phi02-phi_std)*(phi02-phi_std)
  !
  if (sqphi00 > sqphi02) then
    j00 = j00+1
    psi0     = psi2
    lambda00 = lambda02
    phi00    = phi02
  end if
  !
  !print *,' start point = ',i00,j00,lambda00*radian,phi00*radian
  !
  ic = i00+1
  jc = j00
  !
  u_done(ic, jc)=1.d0
  !
  !
  ! ustar, vstar
  !
  !                i,j
  !       i-1,j uv--V*--uv i,j
  !              |      |
  !       i-1,j U*  TS  U* i,j
  !              |      |
  !     i-1,j-1 uv--V*--uv i,j-1
  !                i,j-1
  !
  ustar(1:km)  = 0.d0
  vstar(1:km)  = 0.d0
  rholatbnd(1:km) = 0.d0
  !
  hl1 = max(dy_bl(ic, jc)+dy_tl(ic, jc), 1.d0)
  hl1 = 1.d0/hl1
  do k = 1, ksgm
    hl2 = dx_tr(i00,j00)*dzu(i00,j00,k)*v(i00,j00,k)*ibm(i00,j00) &
      &  +dx_tl(ic ,jc )*dzu(ic ,jc ,k)*v(ic ,jc ,k)*ibm(ic ,jc )
    vstar(k) = hl2*(thcksgm+hl1*(dy_bl(ic, jc)*ssh(i00+1, j00)+dy_tl(ic, jc)*ssh(i00+1, j00+1)))*thcksgmr
    rholatbnd(k)=hl1*(dy_bl(ic, jc)*rho(i00+1, j00, k)+dy_tl(ic, jc)*rho(i00+1, j00+1, k))
  end do
  do k = ksgm+1, kmax
    vstar(k) = dx_tr(i00,j00)*dzu(i00,j00,k)*v(i00,j00,k)*ibm(i00,j00) &
      &       +dx_tl(ic ,jc )*dzu(ic ,jc ,k)*v(ic ,jc ,k)*ibm(ic ,jc )
    rholatbnd(k)=hl1*(dy_bl(ic, jc)*rho(i00+1, j00, k)+dy_tl(ic, jc)*rho(i00+1, j00+1, k))
  end do
#ifdef OGCM_BBL
  k=max(exnn(i00,j00), exnn(ic,jc))
  vstar(k+1) = dx_tr(i00,j00)*dzu(i00,j00,km)*v(i00,j00,km)*ibm(i00,j00) &
    &         +dx_tl(ic ,jc )*dzu(ic ,jc ,km)*v(ic ,jc ,km)*ibm(ic ,jc )
  rholatbnd(k)=hl1*(dy_bl(ic, jc)*rho(i00+1, j00, km)+dy_tl(ic, jc)*rho(i00+1, j00+1, km))
#endif /* OGCM_BBL */
  do k = km, 1, -1
    if(rholatbnd(k) >= rholev(1)) then
      sv(jg,1)=sv(jg,1) +vstar(k)
      mask_sea(jg,1) = 1.0
    end if
  end do
  !
  do k = km, 1, -1
    do m = 2, RLMAX-1
      if(rholatbnd(k) >= rholev(m) .and. rholatbnd(k) < rholev(m-1)) then
        sv(jg,m)=sv(jg,m) +vstar(k)
        mask_sea(j,m) = 1.0
        exit
      end if
    end do
  end do
  !
  do k = km, 1, -1
    if(rholatbnd(k) < rholev(RLMAX-1)) then
      sv(jg,RLMAX)=sv(jg,RLMAX) +vstar(k)
      mask_sea(j,RLMAX) = 1.0
    end if
  end do
  !
  !---------------------------------
  !
  jend = j00  !  terminater
  !
  !
  LOOP_AROUND_THE_WORLD : do while (ic < imut)
    i00 = ic
    j00 = jc
    !
    mu0  = alonu(i00)*radian_r
    mu2  = alonu(i00+1)*radian_r
    psi0 = alatu(j00)*radian_r
    psi1 = alatu(j00-1)*radian_r
    psi2 = alatu(j00+1)*radian_r
    !
    call mp2lp(lambda00, phi00, mu0, psi0)
    call mp2lp(lambda20, phi20, mu2, psi0)
    call mp2lp(lambda02, phi02, mu0, psi2)
    call mp2lp(lambda01, phi01, mu0, psi1)
    !
    sqphi20 = (phi20-phi_std)*(phi20-phi_std) +u_done(i00+1,j00  )
    sqphi02 = (phi02-phi_std)*(phi02-phi_std) +u_done(i00,  j00+1)
    sqphi01 = (phi01-phi_std)*(phi01-phi_std) +u_done(i00  ,j00-1)
    !
    !
    if(min(sqphi20, sqphi02, sqphi01) > 1.d0) then
      exit LOOP_AROUND_THE_WORLD
    end if
    !
    if(min(sqphi02, sqphi01) >= sqphi20) then
      ic = i00+1
      jc = j00
      !
      vstar(1:km)  = 0.d0
      rholatbnd(1:km) = 0.d0
      !
      hl1 = max(dy_bl(ic, jc)+dy_tl(ic, jc), 1.d0)
      hl1 = 1.d0/hl1
      do k = 1, ksgm
        hl2 = dx_tr(i00,j00)*dzu(i00,j00,k)*v(i00,j00,k)*ibm(i00,j00) &
          &  +dx_tl(ic ,jc )*dzu(ic ,jc ,k)*v(ic ,jc ,k)*ibm(ic ,jc )
        vstar(k) = hl2*(thcksgm+hl1*(dy_bl(ic, jc)*ssh(i00+1, j00)+dy_tl(ic, jc)*ssh(i00+1, j00+1)))*thcksgmr
        rholatbnd(k)=hl1*(dy_bl(ic, jc)*rho(i00+1, j00, k)+dy_tl(ic, jc)*rho(i00+1, j00+1, k))
      end do
      do k = ksgm+1, kmax
        vstar(k) = dx_tr(i00, j00)*dzu(i00, j00, k)*v(i00, j00, k)*ibm(i00,j00) &
          &       +dx_tl(ic , jc )*dzu(ic , jc , k)*v(ic , jc , k)*ibm(ic ,jc )
        rholatbnd(k)=hl1*(dy_bl(ic, jc)*rho(i00+1, j00, k)+dy_tl(ic, jc)*rho(i00+1, j00+1, k))
      end do
#ifdef OGCM_BBL
      k=max(exnn(i00, j00), exnn(ic, jc))
      vstar(k+1) = dx_tr(i00, j00)*dzu(i00, j00, km)*v(i00, j00, km)*ibm(i00, j00) &
        &         +dx_tl(ic , jc )*dzu(ic , jc , km)*v(ic , jc , km)*ibm(ic , jc )
      rholatbnd(k+1)=hl1*(dy_bl(ic, jc)*rho(i00+1, j00, km)+dy_tl(ic, jc)*rho(i00+1, j00+1, km))
#endif /* OGCM_BBL */
      do k = km, 1, -1
        if(rholatbnd(k) >= rholev(1)) then
          sv(jg,1)=sv(jg,1) +vstar(k)
          mask_sea(jg,1) = 1.0
        end if
      end do
      !
      do k = km, 1, -1
        do m = 2, RLMAX-1
          if(rholatbnd(k) >= rholev(m) .and. rholatbnd(k) < rholev(m-1)) then
            sv(jg,m)=sv(jg,m) +vstar(k)
            mask_sea(j,m) = 1.0
            exit
          end if
        end do
      end do
      !
      do k = km, 1, -1
        if(rholatbnd(k) < rholev(RLMAX-1)) then
          sv(jg,RLMAX)=sv(jg,RLMAX) +vstar(k)
          mask_sea(j,RLMAX) = 1.0
        end if
      end do
      !
    else if (min(sqphi20, sqphi01) >= sqphi02) then !------------------
      ic = i00
      jc = j00+1
      !
      ustar(1:km)  = 0.d0
      rholatbnd(1:km) = 0.d0
      !
      hl1 = 1.d0 /(dx_bl(ic, jc)+dx_br(ic, jc))
      do k = 1, ksgm
        hl2 = dy_tr(i00, j00)*dzu(i00, j00, k)*u(i00, j00, k)*ibm(i00,j00) &
          &  +dy_br(ic , jc )*dzu(ic , jc , k)*u(ic , jc , k)*ibm(ic ,jc )
        ustar(k) = hl2*(thcksgm+hl1*(dx_bl(ic, jc)*ssh(i00, j00+1)+dx_br(ic, jc)*ssh(i00+1, j00+1)))*thcksgmr
        rholatbnd(k) = hl1*(dx_bl(ic, jc)*rho(i00, j00+1, k)+dx_br(ic, jc)*rho(i00+1, j00+1, k))
      end do
      do k = ksgm+1, kmax
        ustar(k) = dy_tr(i00, j00)*dzu(i00, j00, k)*u(i00, j00, k)*ibm(i00,j00) &
          &       +dy_br(ic , jc )*dzu(ic , jc , k)*u(ic , jc , k)*ibm(ic ,jc )
        rholatbnd(k) = hl1*(dx_bl(ic, jc)*rho(i00, j00+1, k)+dx_br(ic, jc)*rho(i00+1, j00+1, k))
      end do
#ifdef OGCM_BBL
      k=max(exnn(i00, j00), exnn(ic, jc))
      ustar(k+1) = dy_tr(i00, j00)*dzu(i00, j00, km)*u(i00, j00, km)*ibm(i00,j00) &
        &         +dy_br(ic , jc )*dzu(ic , jc , km)*u(ic , jc , km)*ibm(ic ,jc )
      rholatbnd(k+1) = hl1*(dx_bl(ic, jc)*rho(i00, j00+1, km)+dx_br(ic, jc)*rho(i00+1, j00+1, km))
#endif /* OGCM_BBL */
      do k = km, 1, -1
        if(rholatbnd(k) >= rholev(1)) then
          sv(jg,1)=sv(jg,1) -ustar(k)
          mask_sea(jg,1) = 1.0
        end if
      end do
      !
      do k = km, 1, -1
        do m = 2, RLMAX-1
          if(rholatbnd(k) >= rholev(m) .and. rholatbnd(k) < rholev(m-1)) then
            sv(jg,m)=sv(jg,m) -ustar(k)
            mask_sea(j,m) = 1.0
            exit
          end if
        end do
      end do
      !
      do k = km, 1, -1
        if(rholatbnd(k) < rholev(RLMAX-1)) then
          sv(jg,RLMAX)=sv(jg,RLMAX) -ustar(k)
          mask_sea(j,RLMAX) = 1.0
        end if
      end do
      !
    else !-------------------------------------------------------------
      ic = i00
      jc = j00-1
      !
      ustar(1:km)  = 0.d0
      rholatbnd(1:km) = 0.d0
      !
      hl1 = 1.d0 /(dx_bl(i00, j00)+dx_br(i00, j00))
      do k = 1, ksgm+1
        hl2 = dy_br(i00, j00)*dzu(i00, j00, k)*u(i00, j00, k)*ibm(i00,j00) &
          &  +dy_tr(ic , jc )*dzu(ic , jc , k)*u(ic , jc , k)*ibm(ic ,jc )
        ustar(k) = hl2*(thcksgm+hl1*(dx_bl(i00, j00)*ssh(i00, j00)+dx_br(i00, j00)*ssh(i00+1, j00)))*thcksgmr
        rholatbnd(k) = hl1*(dx_bl(i00, j00)*rho(i00, j00, k)+dx_br(i00, j00)*rho(i00+1, j00, k))
      end do
      do k = ksgm+1, kmax
        ustar(k) = dy_br(i00, j00)*dzu(i00, j00, k)*u(i00, j00, k)*ibm(i00,j00) &
          &       +dy_tr(ic , jc )*dzu(ic , jc , k)*u(ic , jc , k)*ibm(ic ,jc )
        rholatbnd(k) = hl1*(dx_bl(i00, j00)*rho(i00, j00, k)+dx_br(i00, j00)*rho(i00+1, j00, k))
      end do
#ifdef OGCM_BBL
      k=max(exnn(i00, j00), exnn(ic, jc))
      ustar(k+1) = dy_tr(i00, j00)*dzu(i00, j00, km)*u(i00, j00, km)*ibm(i00,j00) &
        &         +dy_br(ic , jc )*dzu(ic , jc , km)*u(ic , jc , km)*ibm(ic ,jc )
      rholatbnd(k+1) = hl1*(dx_bl(i00, j00)*rho(i00, j00, km)+dx_br(i00, j00)*rho(i00+1, j00, km))
#endif /* OGCM_BBL */
      do k = km, 1, -1
        if(rholatbnd(k) >= rholev(1)) then
          sv(jg,1)=sv(jg,1) +ustar(k)
          mask_sea(jg,1) = 1.0
        end if
      end do
      !
      do k = km, 1, -1
        do m = 2, RLMAX-1
          if(rholatbnd(k) >= rholev(m) .and. rholatbnd(k) < rholev(m-1)) then
            sv(jg,m)=sv(jg,m) +ustar(k)
            mask_sea(j,m) = 1.0
            exit
          end if
        end do
      end do
      !
      do k = km, 1, -1
        if(rholatbnd(k) < rholev(RLMAX-1)) then
          sv(jg,RLMAX)=sv(jg,RLMAX) +ustar(k)
          mask_sea(j,RLMAX) = 1.0
        end if
      end do
      !
    end if
    !
    u_done(ic, jc)=1.d0
    !
    if(ic == imut-1 .and. jc == jend) then
      exit LOOP_AROUND_THE_WORLD
    end if
  end do LOOP_AROUND_THE_WORLD
  !
end subroutine around_the_world_ip
!====================================================
end program meridional_transport_ip
