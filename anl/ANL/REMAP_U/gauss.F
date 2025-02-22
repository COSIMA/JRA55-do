# 1 "gauss.F"
!
!** COPIED FROM 'A0568.NEW.FORT(GAUSS)' ON 1989.10.1
      SUBROUTINE GAUSS(A,W,K)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
C  A; COSINE OF COLATITUDE
C  W; GAUSSIAN WEIGHT
C  K; ORDER OF LEGENDRE FUNCTIONS
C
CMM   IMPLICIT REAL*8(A-H,O-Z)
C
      DIMENSION A(K),W(K)
C
      ESP=1.D-14
      C=(1.D0-(2.D0/3.14159265358979D0)**2)*0.25D0
      FK=K
      KK=K/2
      CALL BSSLZ1(A,KK)
      DO 30 IS=1,KK
      XZ=COS(A(IS)/SQRT((FK+0.5D0)**2+C))
      ITER=0
   10 PKM2=1.D0
      PKM1=XZ
      ITER=ITER+1
      IF(ITER.GT.10) GO TO 70
      DO 20 N=2,K
      FN=N
      PK=((2.D0*FN-1.D0)*XZ*PKM1-(FN-1.D0)*PKM2)/FN
      PKM2=PKM1
   20 PKM1=PK
      PKM1=PKM2
      PKMRK=(FK*(PKM1-XZ*PK))/(1.D0-XZ**2)
      SP=PK/PKMRK
      XZ=XZ-SP
      AVSP=ABS(SP)
      IF(AVSP.GT.ESP) GO TO 10
      A(IS)=XZ
      W(IS)=(2.D0*(1.D0-XZ**2))/(FK*PKM1)**2
   30 CONTINUE
      IF(K.EQ.KK*2) GO TO 50
      A(KK+1)=0.D0
      PK=2.D0/FK**2
      DO 40 N=2,K,2
      FN=N
   40 PK=PK*FN**2/(FN-1.D0)**2
      W(KK+1)=PK
   50 CONTINUE
      DO 60 N=1,KK
      L=K+1-N
      A(L)=-A(N)
   60 W(L)=W(N)
      RETURN
!  70 WRITE(6,6000)
!6000 FORMAT(//5X,14HERROR IN GAUAW//)
   70 WRITE(6,*)
      WRITE(6,*)
      WRITE(6,*) '     ERROR IN GAUAW'
      WRITE(6,*)
      WRITE(6,*)
C
      STOP
      END
      SUBROUTINE BSSLZ1(BES,N)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
CMM   IMPLICIT REAL*8(A-H,O-Z)
      DIMENSION BES(N)
      DIMENSION BZ(50)
C
      DATA PI/3.14159265358979D0/
      DATA BZ         / 2.4048255577D0, 5.5200781103D0,
     *  8.6537279129D0,11.7915344391D0,14.9309177086D0,18.0710639679D0,
     * 21.2116366299D0,24.3524715308D0,27.4934791320D0,30.6346064684D0,
     * 33.7758202136D0,36.9170983537D0,40.0584257646D0,43.1997917132D0,
     * 46.3411883717D0,49.4826098974D0,52.6240518411D0,55.7655107550D0,
     * 58.9069839261D0,62.0484691902D0,65.1899648002D0,68.3314693299D0,
     * 71.4729816036D0,74.6145006437D0,77.7560256304D0,80.8975558711D0,
     * 84.0390907769D0,87.1806298436D0,90.3221726372D0,93.4637187819D0,
     * 96.6052679510D0,99.7468198587D0,102.888374254D0,106.029930916D0,
     * 109.171489649D0,112.313050280D0,115.454612653D0,118.596176630D0,
     * 121.737742088D0,124.879308913D0,128.020877005D0,131.162446275D0,
     * 134.304016638D0,137.445588020D0,140.587160352D0,143.728733573D0,
     * 146.870307625D0,150.011882457D0,153.153458019D0,156.295034268D0/
      NN=N
      IF(N.LE.50) GO TO 12
      BES(50)=BZ(50)
      DO 5 J=51,N
    5 BES(J)=BES(J-1)+PI
      NN=49
   12 DO 15 J=1,NN
   15 BES(J)=BZ(J)
      RETURN
      END
