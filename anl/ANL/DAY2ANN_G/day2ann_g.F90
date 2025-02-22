!-*-F90-*-
!day2ann_g.F90
!====================================================
!
!  Daily to Annual Generalized version
!
!====================================================
program day2ann_g
  !
  implicit none
  !
  integer(4) :: x_num, y_num, z_num, var_num
  !
  real(4), save  :: undef  =  0.0e0
  integer(4)     :: iyear
  !
  logical, save         :: l_leap
  !
  character(len=256)    :: fpathin
  character(len=256)    :: fpathout
  !
  namelist /nml_day2mon_g/ x_num, y_num, z_num, var_num, undef, &
    &                  iyear, l_leap, fpathin, fpathout
  !
  character(len=256)    :: flin
  character(len=256)    :: flout
  !
  integer(4), save :: daymonth(12)
  integer(4)       :: day_year
  integer(4)       :: nday, month, nvar
  integer(4)       :: k
  !
  real(4), allocatable :: datr4in(:, :, :, :)
  real(8), allocatable :: data_r8(:, :, :, :)
  real(4), allocatable :: datr4out(:, :, :, :)
  !
  integer(4), parameter :: mtin  = 81
  integer(4), parameter :: mtout = 83
  !
  !==========================================
  !
  read(unit=5, nml=nml_day2mon_g)
  print *,'x_num    :', x_num
  print *,'y_num    :', y_num
  print *,'z_num    :', z_num
  print *,'var_num  :', var_num
  print *,'UNDEF    :', undef
  print *,'year     :', iyear
  print *,'l_leap   :', l_leap
  print *,'fpath in :', trim(fpathin)
  print *,'fpath out:', trim(fpathout)
  !
  allocate (datr4in(1:x_num, 1:y_num, 1:z_num, 1:var_num))
  allocate (data_r8(1:x_num, 1:y_num, 1:z_num, 1:var_num))
  allocate (datr4out(1:x_num, 1:y_num, 1:z_num, 1:var_num))
  !
  data_r8(1:x_num, 1:y_num, 1:z_num, 1:var_num) = 0.0d0
  datr4out(1:x_num, 1:y_num, 1:z_num, 1:var_num) = 0.0e0
  !
  !-------------------------------------
  !
  daymonth( 1)=31
  daymonth( 2)=28
  daymonth( 3)=31
  daymonth( 4)=30
  daymonth( 5)=31
  daymonth( 6)=30
  daymonth( 7)=31
  daymonth( 8)=31
  daymonth( 9)=30
  daymonth(10)=31
  daymonth(11)=30
  daymonth(12)=31
  !
  if (l_leap) then
    if(mod(iyear,  4) == 0) daymonth(2) = 29
    if(mod(iyear,100) == 0) daymonth(2) = 28
    if(mod(iyear,400) == 0) daymonth(2) = 29
  end if
  !
  !-------------------------------------
  !
  day_year = 0

  do month = 1, 12
    day_year = day_year + daymonth(month)
    do nday = 1, daymonth(month)
      write(6,*) 'Year = ', iyear, ' Month = ', month, ' Day = ', nday

      write(flin, '(a, a, i4.4, i2.2, i2.2)' ) trim(fpathin), '.', iyear, month, nday
      write(*,'(a, a)') 'file in :', trim(flin)
      open(mtin, file=flin, form='unformatted', access='direct', recl=4*x_num*y_num*z_num*var_num)
      read (mtin, rec=1) datr4in(:,:,:,:)

      do nvar = 1, var_num
        do k = 1, z_num
          where(datr4in(1:x_num, 1:y_num, k, nvar) == undef)
            datr4in(1:x_num, 1:y_num, k, nvar) = 0.0e0
          end where
        end do
      end do

      data_r8(1:x_num, 1:y_num, 1:z_num, 1:var_num) = data_r8(1:x_num, 1:y_num, 1:z_num, 1:var_num) &
        &                                      + real(datr4in(1:x_num, 1:y_num, 1:z_num, 1:var_num), 8)
      close(mtin)

    end do
  end do

  data_r8(1:x_num, 1:y_num, 1:z_num, 1:var_num) = data_r8(1:x_num, 1:y_num, 1:z_num, 1:var_num)  &
       &                                            / real(day_year, 8)
  datr4out(1:x_num, 1:y_num, 1:z_num, 1:var_num) = real(data_r8(1:x_num, 1:y_num, 1:z_num, 1:var_num), 4)

  do nvar = 1, var_num
    do k = 1, z_num
      where(data_r8(1:x_num, 1:y_num, k, nvar) == 0.0d0)
        datr4out(1:x_num, 1:y_num, k, nvar) = undef
      end where
    end do
  end do
  !
  write(flout, '(a, a, i4.4)' ) trim(fpathout), '.', iyear
  write(*,'(a, a)') 'file out :', trim(flout)
  open(mtout, file=flout, form='unformatted', access='direct', recl=4*x_num*y_num*z_num*var_num)
  write(mtout, rec=1) datr4out(1:x_num, 1:y_num, 1:z_num, 1:var_num)
  close(mtout)
  !
!====================================================
end program day2ann_g
