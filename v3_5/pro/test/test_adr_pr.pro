;+
; NAME:
;   test_adr_pr
; PURPOSE:
;   Testing ADR, F82 vs Peck & Reeder 1972
;-
;------------------------------------------------------------------------------
pro test_adr_pr

lambda= findgen(25000L)+2000.
trualt= replicate(15., n_elements(lambda))

adr_f= adr(trualt, lambda=lambda)
adr_pr= adr(trualt, /pr72, lambda=lambda)

splot, lambda, adr_f
soplot, lambda, adr_pr, color='red'

end
