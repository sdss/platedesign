pro fix_kyle

name='plateInput_commiss_RA341.par'
oldname=name+'.old'

old=yanny_readone(oldname, hdr=hdr)

new0= create_struct(old[0], 'priority', 0L, 'sourcetype', 'STAR')
new= replicate(new0, n_elements(old))

struct_assign, old, new
new.priority=lindgen(n_elements(new))+1L
new.sourcetype='STAR'

yanny_write, name, ptr_new(new), hdr=hdr

end
