; Procedure to undefine an IDL variable.
; It's completely obvious now, isn't it?? Stupid IDL.
;
; http://www.dfanning.com/tips/variable_undefine.html
;
PRO UNDEFINE, var
	if (keyword_set(var) eq 1) then $
		tempvar = SIZE(TEMPORARY(var))
END
      