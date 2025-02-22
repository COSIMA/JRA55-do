! -*-F90-*-
!==================================================================
program read_netcdf_output_relative_humidity
  !----------------------------------------------------------------
  ! Information:
  !   Create direct access file (GrADS) of
  !     the NOCS surface data
  !----------------------------------------------------------------

  implicit none

  include '/usr/local/netcdf/include/netcdf.inc'

  integer(4), parameter :: imut = 360, jmut = 180
  integer(4), parameter :: mtot1 = 91, mtot2 = 92

  real(4) :: dat4(imut,jmut)
  real(8) :: dat8(imut,jmut)

  real(8) :: qair(imut,jmut)
  real(8) :: tair(imut,jmut)
  real(8) :: slp (imut,jmut)
  real(8) :: rlh (imut,jmut)
!  real(8) :: roa (imut,jmut)

  integer(4) :: idmon(12)

  character(128) :: flot1, flot2

  integer(4) :: i, j, k, l, m, n

  integer(4) :: nmocount
  integer(4) :: ireco1, ireco2
  integer(4) :: nyear

  real(4),parameter :: undef_nocs = -9999.e0
  real(4),parameter :: undef_mxe = -9.99e33

  real(8), parameter :: tab = 273.15d0
  real(8), parameter :: q0 = 0.98d0
  real(8), parameter :: q1 = 640380.d0
  real(8), parameter :: q2 = -5107.4d0
  real(8), parameter :: rgas = 287.04d0
  real(8), parameter :: rhoa = 1.22d0

  real(8) :: rhoqsat, qsat

  ! for netCDF

  integer(4), parameter :: nvars = 3, nfiles = 3
  integer(4) :: var(nvars), sta(nvars)
  integer(4) :: start(3), range(3)
  character(128) :: flnin(nfiles)
  integer(4) :: ifiles(nfiles)

  !--------------------------------------------------------------------
  ! general settings

  idmon(1:12) = (/ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 /)

  !---------------------------------------------------------------------
  ! main year
  !

  start(1:3) = (/ 1, 1, 1 /)
  range(1:3) = (/ 360, 180, 1 /)

  nmocount = 0

  do nyear = 1973, 2006

    !--------------------------------------------------------------------
    ! open netcdf file

    write(flnin(1),'(1a,i4.4,1a)') &
         & '/worke/htsujino/NOCS/orgdata/nocs_v2_0_qair_',nyear,'.nc'
    write(flnin(2),'(1a,i4.4,1a)') &
         & '/worke/htsujino/NOCS/orgdata/nocs_v2_0_at_',nyear,'.nc'
    write(flnin(3),'(1a,i4.4,1a)') &
         & '/worke/htsujino/NOCS/orgdata/nocs_v2_0_slp_',nyear,'.nc'

    do n = 1, nfiles
      sta(n) = nf_open(flnin(n),nf_nowrite,ifiles(n)) 
      if (sta(n) /= 0) then
        write(6,*) 'nf_open error for file number ',n
        stop
      end if
    end do

    sta(1) = nf_inq_varid(ifiles(1),'qair',var(1))
    sta(2) = nf_inq_varid(ifiles(2),'at'  ,var(2))
    sta(3) = nf_inq_varid(ifiles(3),'slp' ,var(3))

    do n = 1, nvars
      if (sta(n) /= 0) then
        write(6,*) 'nf_inq_varid error for variable ',n, var(n)
        stop
      end if
    end do

    nmocount = 0

    do m = 1, 12

      nmocount = nmocount + 1

      start(3) = nmocount

      sta(1) = nf_get_vara_real(ifiles(1),var(1),start,range,dat4)
      do j = 1, jmut
        do i = 1, imut
          if (i > 180) then
            qair(i-180,j) = real(dat4(i,j),8)
          else
            qair(i+180,j) = real(dat4(i,j),8)
          end if
        end do
      end do
      do j = 1, jmut
        do i = 1, imut
          if (qair(i,j) == real(undef_nocs,8)) then
            qair(i,j) = real(undef_mxe,8)
          end if
        end do
      end do

      sta(2) = nf_get_vara_real(ifiles(2),var(2),start,range,dat4)
      do j = 1, jmut
        do i = 1, imut
          if (i > 180) then
            tair(i-180,j) = real(dat4(i,j),8)
          else
            tair(i+180,j) = real(dat4(i,j),8)
          end if
        end do
      end do
      do j = 1, jmut
        do i = 1, imut
          if (tair(i,j) == real(undef_nocs,8)) then
            tair(i,j) = real(undef_mxe,8)
          end if
        end do
      end do

      sta(3) = nf_get_vara_real(ifiles(3),var(3),start,range,dat4)
      do j = 1, jmut
        do i = 1, imut
          if (i > 180) then
            slp(i-180,j) = real(dat4(i,j),4)
          else
            slp(i+180,j) = real(dat4(i,j),4)
          end if
        end do
      end do
      do j = 1, jmut
        do i = 1, imut
          if (slp(i,j) == real(undef_nocs,8)) then
            slp(i,j) = real(undef_mxe,8)
          end if
        end do
      end do

      do j = 1, jmut
        do i = 1, imut
          if ((tair(i,j) /= real(undef_mxe,8)) .and. (qair(i,j) /= real(undef_mxe,8))) then
            qsat = q0 * q1 * exp(q2 / (tair(i,j) + tab)) / rhoa 
            rlh(i,j) = qair(i,j) * 1.0d-3 * (1.0d0 - qsat) / (qsat * (1.0d0 - qair(i,j)*1.0d-3))
          else
            rlh(i,j) = real(undef_mxe,8)
          end if
        end do
      end do

      ! open output file

      write(flot1,'(1a,i4.4,i2.2)') '/worke/htsujino/NOCS/grads/rlh.',nyear,m
      open(mtot1,file=flot1,form='unformatted',access='direct',recl=4*imut*jmut)
      write(6,*) 'DATA written to ',trim(flot1)
      ireco1 = 0

      ireco1 = ireco1 + 1

      write(mtot1,rec=ireco1) real(rlh(1:imut,1:jmut),4)

      close(mtot1)

    end do
  end do

  do n = 1, nfiles
    write(6,*) ifiles(n)
    sta(n) = nf_close(ifiles(n))
    if (sta(n) /= 0) then
      write(6,*) 'nf_close error for file number ',n, ifiles(n), sta(n)
    end if
  end do

end program read_netcdf_output_relative_humidity
