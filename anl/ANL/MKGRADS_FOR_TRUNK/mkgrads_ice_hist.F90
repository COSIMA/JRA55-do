! -*-F90-*-
!=========================================================================
program mkgrads_ice_hist
  !-----------------------------------------------------------------------
  !  Make GrADS data from OGCM output
  !-----------------------------------------------------------------------

  use basin_param
  use grid_common

  implicit none

  real(4) :: dat (imut,jmut,6)
  real(4) :: dat2(imut,jmut)

  integer(4) :: iy, is
  integer(4) :: i, j, k, n, nt, irec, nst, ned, inum
  integer(4) :: NKAI, MONTH, IDAY, IHOUR, IMIN
  integer(4), parameter :: mtin = 77, mtout = 88

  character(len=256) :: file_in, file_out, cnum

  !---------------------------------------------------------------------

  call getarg (1, file_in )
  call getarg (2, file_out)
  call getarg (3, cnum )

  read(cnum, '(I10)') inum
  write(*,*) 'reading ', inum ,' data'

  open(mtin, file=file_in,form='unformatted')
  write(*,*) 'reading from ... ', trim(file_in)

  open(mtout, file=file_out,form='unformatted',access='direct',recl=4*imut*jmut)
  write(*,*) 'output to ... ', trim(file_out)
  irec = 0

  !------------------------------------------------------------------------

  read (mtin,end=999) NKAI,MONTH,IDAY,IHOUR,IMIN
  write(*,*) NKAI,MONTH,IDAY,IHOUR,IMIN

  read (mtin,end=999) dat(1:imut,1:jmut,1:6)

  do k = 1, 6
    do j = 1, jmut
      do i = 1, imut
        dat2(i,j) = dat(i,j,k)
      end do
    end do
    irec = irec + 1
    write (mtout,rec=irec) dat2
  end do

  close ( mtout )

999 continue

  close ( mtin )

end program mkgrads_ice_hist
