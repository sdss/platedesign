pro check_adr

readcol, comment='#', getenv('PLATEDESIGN_DIR')+ $
         '/data/sdss/holtzman-adr.txt', zd, off4000, off4968, off5013, $
         off5102, off5400, off5700, off8000

offrel=off5013+off5400

trualt=90.-zd
off5013[*]=0.
off4000=off4000-off5400
off4968=off4968-off5400
off5013=off5013-off5400
off5102=off5102-off5400
off5700=off5700-off5400
off8000=off8000-off5400
off5400[*]=0.

mytrualt= findgen(80.)+10.
         
lambda=4000.
off=off4000

height=2788.
temperature=5.
airtemp_k=temperature+273.155  ; C to Kelvin
pressure= 1013.25 * exp(-height/(29.3*airtemp_k))
adr= adr(mytrualt, pressure=pressure, temperature=temperature, lambda=lambda)
cadr= adr(mytrualt, pressure=pressure, temperature=temperature, lambda=5400.)
adr=adr-cadr

height=0.
temperature=5.
airtemp_k=temperature+273.155  ; C to Kelvin
pressure= 1013.25 * exp(-height/(29.3*airtemp_k))
sladr= adr(mytrualt, pressure=pressure, temperature=temperature, lambda=lambda)
slcadr= adr(mytrualt, pressure=pressure, temperature=temperature, lambda=5400.)
sladr=sladr-slcadr

splot, mytrualt, adr
soplot, mytrualt, sladr, color='red'
soplot, trualt, off, psym=4, color='yellow'

end
