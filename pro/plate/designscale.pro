;+
; NAME:
;   designscale
; PURPOSE:
;   Return information about the approximate plate scale
; CALLING SEQUENCE:
;   designscale, plateid, altscale=, azscale=
; INPUTS:
;   plateid - which plate
; OUTPUTS:
;   approxscale - approximate plate scale used (mm/deg)
; COMMENTS:
;   Takes all holes > 120 arcsec away from center, and 
;     determines rfocal (mm) / theta (deg)
; REVISION HISTORY:
;   25-Aug-2009  MRB, NYU
;-
pro designscale, plateid, altscale=altscale, azscale=azscale, pa=pa, $
                 lambda_eff=lambda_eff

common com_designscale, plans

if n_elements(lat) EQ 0 then lat = 32.7797556D

if(n_elements(lambda_eff) eq 0) then $
  lambda_eff= (design_blank()).lambda_eff

if(n_tags(plans) eq 0) then begin
    plateplans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
    plans= yanny_readone(platePlans_file)
endif

iplate=where(plans.plateid eq plateid, nplate)
plan=plans[iplate]

;; read in the definition
definitiondir=getenv('PLATELIST_DIR')+'/definitions/'+ $
              string(f='(i4.4)', (plan.designid/100L))+'XX'
definitionfile=definitiondir+'/'+ $
               'plateDefinition-'+ $
               string(f='(i6.6)', plan.designid)+'.par'
dum= yanny_readone(definitionfile, hdr=hdr)
definition= lines2struct(hdr)

;; Read in the plate defaults file
;; (reset any tags that are overwritten by plateDefinition)
defaultdir= getenv('PLATEDESIGN_DIR')+'/defaults'
defaultfile= defaultdir+'/plateDefault-'+ $
             definition.platetype+'-'+ $
             definition.platedesignversion+'.par'
dum= yanny_readone(defaultfile, hdr=hdr)
default= lines2struct(hdr)
defaultnames=tag_names(default)
definitionnames=tag_names(definition)
for i=0L, n_tags(default)-1L do begin
    for j=0L, n_tags(definition)-1L do begin
        if(defaultnames[i] eq definitionnames[j]) then $
          default.(i)= definition.(j)
    endfor
endfor

npointings= long(default.npointings)
pa= dblarr(npointings)
altscale= dblarr(npointings)
azscale= dblarr(npointings)
offset=0L
nrandom=10000L
tilerad=1.49
doff=0.01
for pointing= 1L, npointings do begin

    ;; LST for this pointing
    plate_center, definition, default, pointing, offset, $
                  racen=racen, deccen=deccen
    lst=plan.ha[pointing-1]+racen

    ;; distribute points randomly in RA/Dec
    random_ra= racen+2.*tilerad*(randomu(seed, nrandom)-0.5)/ $
               cos(!DPI/180.*deccen)
    random_dec= deccen+2.*tilerad*(randomu(seed, nrandom)-0.5)
    spherematch, racen, deccen, random_ra, random_dec, tilerad, $
                 m1, m2, max=0
    if(m2[0] eq -1) then $
      message, 'Inconsistency in distributing randoms!'
    random_ra=random_ra[m2]
    random_dec=random_dec[m2]
    
    ;; calculate X's and Y's
    random_lambda= replicate(lambda_eff, n_elements(random_ra))
    plate_ad2xy, definition, default, pointing, 0, $
                 random_ra, random_dec, random_lambda, $
                 airtemp=plan.temp, lst=lst, xf=xf, yf=yf
    
    ;; calculate parallactic angle
    hadec2altaz, plan.ha[pointing-1L], deccen, lat, altcen, azcen
    hadec2altaz, plan.ha[pointing-1L], deccen+doff, lat, altoff, azoff
    daltoff=(altoff-altcen)/doff
    dazoff=(azoff-azcen)/doff*cos(!DPI/180.*altcen)
    parad= atan(dazoff, daltoff)
    pa[pointing-1]= 180.D/!DPI*parad

    ;; calculate dalt
    random_ha= lst-random_ra
    dalt= replicate(doff, n_elements(random_ra))
    daz= replicate(0., n_elements(random_ra))
    hadec2altaz, random_ha, random_dec, lat, random_alt, random_az
    altaz2hadec, random_alt+dalt, random_az+daz/cos(random_alt*!DPI/180.), $
                 lat, off_ha, off_dec
    off_ra= lst-off_ha
    
    plate_ad2xy, definition, default, pointing, 0, $
                 off_ra, off_dec, random_lambda, $
                 airtemp=plan.temp, lst=lst, xf=off_xf, yf=off_yf
    
    daltmm= (xf-off_xf)*sin(parad) + (yf-off_yf)*cos(parad)
    altscale[pointing-1]= median(abs(daltmm/ dalt))

    ;; calculate daz
    random_ha= lst-random_ra
    dalt= replicate(0., n_elements(random_ra))
    daz= replicate(doff, n_elements(random_ra))
    hadec2altaz, random_ha, random_dec, lat, random_alt, random_az
    altaz2hadec, random_alt+dalt, random_az+daz/cos(random_alt*!DPI/180.), $
                 lat, off_ha, off_dec
    off_ra= lst-off_ha
    
    plate_ad2xy, definition, default, pointing, 0, $
                 off_ra, off_dec, random_lambda, $
                 airtemp=plan.temp, lst=lst, xf=off_xf, yf=off_yf
    
    dazmm = (xf-off_xf)*cos(parad) - (yf-off_yf)*sin(parad)
    azscale[pointing-1]= median(abs(dazmm/ daz))

endfor

end
;------------------------------------------------------------------------------
