C
      SUBROUTINE COHBEAM_INI(ID,E0,EP,ELIM,ZCOLLIM,COLDIAM,IERR)
C
C---   Photoproduction by the coherent Brem. beam
C---   ID - histogram with the dN/dE*sigma(E), 
C              where dN/dE - coh. Brem., sigma(E) - total photoprod. on protons 
C      E0 - e- energy
C      EP - coherent peak energy
C      ELIM - energy limits
C      ZCOLLIM - distance to the collimator (cm)
C      COLDIAM - collimator diameter (m)
C
      IMPLICIT NONE
      INTEGER ID,IERR
      REAL E0,EP,ELIM(2),ZCOLLIM,COLDIAM
C
      INCLUDE 'bg_ctrl.inc'
CC
      REAL DNIDX,DNCDX,GPXSECT,GETXSEC
      EXTERNAL DNIDX,DNCDX,GPXSECT,GETXSEC

      INTEGER i,nb,ibrem
      REAL emn,emx,flx,xsec,dx,de,e,xstot,xlum,ecurr,targth,frate,vv
     +    ,fflux
C
      IERR=1
C
      ibrem=1
      IF(ELIM(2).LT.ELIM(1)*1.006) ibrem=0
C
C---   Initialize the coherent Bremsstrahlung 
C
      targth=30.                ! target thickness
      ecurr=350.E-9             ! beam current on a 50um crystal - the real "high luminosity" setting
      xlum=ecurr/1.6E-19*targth*0.071*0.602 ! auxil. luminosity factor:  beam electrons/s * target thickness in 1/b 
C
      IF(ibrem.NE.0) THEN
         CALL COBREMS(E0,EP,EEMIT,RADT,ZCOLLIM/100.,COLDIAM,0) ! collimator distance in m
      ENDIF
C
      IF(NHBEA.LT.1) THEN
         WRITE(6,1000) NHBEA
 1000    FORMAT('  *** Initialization error cohbeam_ini: NHBEA=',I6)
         GO TO 999
      ENDIF

      emn=ELIM(1)
      emx=ELIM(2)
      de=(emx-emn)/NHBEA
      dx=de/E0
      nb=NHBEA
C
      CALL HBOOK1(ID   ,'Beam flux dn/dE*sigma(E)' ,nb,emn,emx,0.)
      CALL HBOOK1(ID+10,'Total cross section in mb',nb,emn,emx,0.)
      CALL HBOOK1(ID+11,'Beam flux dn/dE'          ,nb,emn,emx,0.)
C
      fflux=0.
      frate=0.
      DO i=1,nb
         e=ELIM(1)+(i-0.5)*de
         IF(ISIMUL.EQ.0) THEN
            xstot=GPXSECT(e)*1.E-3   ! x-sec in b  BG
         ELSE
            xstot=GETXSEC(e)         ! x-sec in b - exclusive reaction
         ENDIF
         IF(ibrem.NE.0) THEN
            flx=(DNIDX(e/E0)+DNCDX(e/E0))*dx/de  ! dN/dx - photon rate per one incident electron
            fflux=fflux+flx*de
            vv=xstot*flx*xlum
            frate=frate+vv*de
            CALL HF1(ID+11,e,flx)
         ELSE
            vv=1.
         ENDIF
         CALL HF1(ID   ,e,vv)
         CALL HF1(ID+10,e,xstot)
      ENDDO
C      CALL HPRINT(ID)
C
      RATESEC=0.
      IF(ibrem.NE.0) THEN
         RATESEC=frate
         WRITE(6,FMT='(//10X,''Rates:'')')
         WRITE(6,1003) ecurr*1.E9,emn,emx,fflux*ecurr/1.6e-19
 1003    FORMAT(10X,'Beam: ',F8.2,' nA e-, gamma in ',2F6.2,' GeV '
     +         ,'  flux ',E11.3,' Hz') 
         WRITE(6,1005) targth
 1005    FORMAT(10X,'Target: ',F8.2,' cm LH2')
         WRITE(6,1010) frate
 1010    FORMAT(10X,'Interaction rate: ',E12.3,' Hz')
      ENDIF 
C
      CALL HCOPY(ID,ID+1,'    ')  ! a copy of the final histogram to be used for HRNDM1
C
      IERR=0
 999  RETURN
      END
