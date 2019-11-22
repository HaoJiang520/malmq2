*! version 1.0
* Kerry Du (kerrydu@xmu.edu.cn)
* 22 Nov 2019
capture program drop malmq2
program define malmq2,rclass
    version 16
	
local subcmd `0'
*******************************************************************************
/////////This section is from  Yong-bae Ji and Choonjoo Lee's DEA.ado//////////
    // get and check invarnames
    gettoken word 0 : 0, parse("=,")
    while ~("`word'" == ":" | "`word'" == "=") {
        if "`word'" == "," | "`word'" == "" {
                error 198
        }
        local invars `invars' `word'
        gettoken word 0 : 0, parse("=,")
    }
    unab invars : `invars'
*********************************************************************************	
	
    local num: word count `invars'
    syntax varlist [if] [in], id(varname) time(varname) [VRS ort(string) ///
	                           GLOBAL SEQuential WINdow(numlist intege max=1 >=1) ///
							   save(string) maxiter(numlist integer >0 max=1) tol(numlist max=1 >0)]
	preserve
	marksample touse 
    local opvars `varlist'
	
	
	
	local techtype "contemporaneous"
   

   if "`global'"!=""{
	   if "`sequential'"!=""{
	   
		   disp as error "global and sequential cannot be specified together."
		   error 498	   
	   
	   }
	   
	   if "`window'"!=""{
	   
		   disp as error "global and window() cannot be specified together."
		   error 498	   
	   
	   }	   
	   
	   local techtype "global"
	
	}	
	
   

   if "`sequential'"!=""{
 
	   if "`window'"!=""{
	   
		   disp as error "sequential and window() cannot be specified together."
		   error 498	   
	   
	   }	   
	   
	   local techtype "sequential"
	
	}	
		
 
	   if "`window'"!=""{
	   
	       local techtype "window"   
	   
	   }	   
	   
	if "`maxiter'"==""{
		local maxiter=-1
	}
	if "`tol'"==""{
		local tol=-1
	}	
	
	keep `invars' `opvars' `id' `time' `touse'
	qui gen Row=_n
	label var Row "Row # in the original dataset"
   
    tempvar period dmu
	
	qui egen `period'=group(`time')
	qui egen `dmu'=group(`id')	

	
    qui su  `period'
    local tmax=r(max)

    tempvar flag temp DD D21 D12
    
    qui gen `DD'=.
    qui gen `D21'=.
    qui gen `D12'=.
	
    qui gen `flag'=0
	
  sort `period' `dmu'
	
  if `"`techtype'"'=="contemporaneous"{
  
	    qui{
        forv t=1/`tmax'{
            qui replace `flag'= (`period'==`t')
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp') `vrs' ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            qui replace `DD'=`temp' if `period'==`t'
            qui drop `temp'
        }    
        local tt=`tmax'-1
        forv t=1/`tt'{
            qui replace `flag'=(`period'==`t'+1) 
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp') `vrs' ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            qui replace `D21'=`temp' if `period'==`t'
            qui drop `temp'
        }  

        forv t=2/`tmax'{
            qui replace `flag'=(`period'==`t'-1)
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp') `vrs' ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            qui replace `D12'=`temp' if `period'==`t'
            qui drop `temp'
        }       

    }
  
  
  }
  
  
    if `"`techtype'"'=="sequential"{
  
	  
        forv t=1/`tmax'{
            qui replace `flag'=(`period'<=`t')
            shepdf if `period'==`t' & `touse', rflag(`flag') gen(`temp') `vrs' ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            qui replace `DD'=`temp' if `period'==`t'
            qui replace `flag'=0
            qui drop `temp'
        }    
        local tt=`tmax'-1
        forv t=1/`tt'{
            qui replace `flag'=(`period'<=`t'+1) 
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp') `vrs' ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            qui replace `D21'=`temp' if `period'==`t'
            qui drop `temp'
        }  

        forv t=2/`tmax'{
            qui replace `flag'= (`period'<=`t'-1) 
            shepdf if `period'==`t' & `touse', rflag(`flag') gen(`temp') `vrs' ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            qui replace `D12'=`temp' if `period'==`t'
            qui drop `temp'
        }       

    
  
  
  }
  
  
  
     if `"`techtype'"'=="window"{
		local band=(`window'-1)/2
	 
        forv t=1/`tmax'{
            qui replace `flag'=(`period'<=`t'+`band' & `period'>=`t'-`band') 
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp') `vrs' ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            qui replace `DD'=`temp' if `period'==`t'
            qui cap drop `temp'
        }    
        local tt=`tmax'-1
        forv t=1/`tt'{
            qui replace `flag'= (`period'<=`t'+1+`band' &  `period'>=`t'-`band'+1)
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp') `vrs' ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            qui replace `D21'=`temp' if `period'==`t'
            qui cap drop `temp'
        }  

        forv t=2/`tmax'{
            qui replace `flag'=(`period'<=`t'-1+`band' & `period'>=`t'-1-`band') 
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp') `vrs' ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            qui replace `D12'=`temp' if `period'==`t'
            qui cap drop `temp'
        }       

    
  
  
  }
 

 	
 
	if `"`techtype'"'=="global"{

	    qui replace `flag'=1
		shepdf  if `touse', rflag(`flag') gen(`temp') `vrs' ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
        
		qui cap bys `dmu' (`period'): gen Pdwise=`time'[_n-1]+"~"+`time' if _n>1
		qui cap bys `dmu' (`period'): gen Pdwise=string(`time'[_n-1])+"~"+string(`time') if _n>1
        qui bys `dmu' (`period'): gen TFPCH=`temp'/`temp'[_n-1]	
		label var TFPCH "Total factor productivity change"
		cap drop `temp'		
		
		sort `period' `dmu'
		forv t=1/`tmax'{
			qui replace `flag'=(`period'==`t')
			shepdf  if `touse' & `period'==`t', rflag(`flag') gen(`temp') `vrs' ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
			qui replace `DD'=`temp' if `period'==`t'
			qui cap drop `temp'
		}
		
		qui bys `dmu' (`period'): gen TECH=`DD'/`DD'[_n-1]	
		qui bys `dmu' (`period'): gen BPC=TFPCH/TECH			
	
		label var TECH  "Technical efficiency change"	
		label var BPC "Best practice gap change"
		local resvars TFPCH TECH  BPC
		/*
		if "`vrs'"!=""{
			qui replace `flag'=1
			shepdf  if `touse', rflag(`flag') gen(`temp')  ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')	
			qui by `dmu' (`period'): replace `DD'=`temp'/`temp'[_n-1]
			qui gen SECH=`DD'/TFPCH
			qui replace TFPCH=`DD'
			label var SECH "Scale efficiency change"
			local resvars TFPCH TECH  BPC SECH
		}
		*/
		
		
	}
	else{
		qui {
			sort `dmu' `period'
			cap bys `dmu' (`period'): gen Pdwise=`time'[_n-1]+"~"+`time' if _n>1
			cap bys `dmu' (`period'): gen Pdwise=string(`time'[_n-1])+"~"+string(`time') if _n>1
			bys `dmu' (`period'): gen TECH=`DD'/`DD'[_n-1]
			bys `dmu' (`period'): gen TECCH=sqrt(`D12'/`DD'*`DD'[_n-1]/`D21'[_n-1])
			gen TFPCH= TECH*TECCH
			local resvars TFPCH TECH TECCH
		    label var TFPCH "Total factor productivity change"
		    label var TECH  "Technical efficiency change"	
		    label var TECCH "Techological change"				
		}	
	
	}
	
	
	if "`vrs'"!=""{
	  tempvar DD
	  malmq2_1 `subcmd' tfp(`DD')
	  qui gen SECH=`DD'/TFPCH
	  qui replace TFPCH=`DD'
	  label var SECH "Scale efficiecny change"
	  local resvars `resvars' SECH
	
	}
	
	
	
	
	label var Pdwise "Period wise"
	

	    format `resvars' %9.4f
		order Row `id' `time' Pdwise  `resvars' 
		keep  Row `id' `time' Pdwise  `resvars' `touse'
	
		disp _n(2) " Malmquist Productivity Index Results:"
		disp "    (Row: Row # in the original data; Pdwise: periodwise)"

		list Row `id' `time' Pdwise  `resvars' if !missing(Pdwise) & `touse', sep(0) 
		di "Note: missing value indicates infeasible problem."

	if `"`saving'"'!=""{
	  save `saving'
	  gettoken filenames saving:saving, parse(",")
	  local filenames `filenames'.dta
	  disp _n `"Estimated Results are saved in `filenames'."'
	}	
	

   return local file `filenames'
   restore



end  


capture program drop malmq2_1
program define malmq2_1
    version 16
*******************************************************************************
/////////This section is from  Yong-bae Ji and Choonjoo Lee's DEA.ado//////////
    // get and check invarnames
    gettoken word 0 : 0, parse("=,")
    while ~("`word'" == ":" | "`word'" == "=") {
        if "`word'" == "," | "`word'" == "" {
                error 198
        }
        local invars `invars' `word'
        gettoken word 0 : 0, parse("=,")
    }
    unab invars : `invars'
*********************************************************************************	
	
    local num: word count `invars'
    syntax varlist [if] [in], id(varname) time(varname) tfp(string) [VRS ort(string) ///
	                           GLOBAL SEQuential WINdow(numlist intege max=1 >=1) ///
							   save(string) maxiter(numlist integer >0 max=1) tol(numlist max=1 >0)]
	
	marksample touse 
    local opvars `varlist'
	
	
	
	local techtype "contemporaneous"
   

   if "`global'"!=""{
	   if "`sequential'"!=""{
	   
		   disp as error "global and sequential cannot be specified together."
		   error 498	   
	   
	   }
	   
	   if "`window'"!=""{
	   
		   disp as error "global and window() cannot be specified together."
		   error 498	   
	   
	   }	   
	   
	   local techtype "global"
	
	}	
	
   

   if "`sequential'"!=""{
 
	   if "`window'"!=""{
	   
		   disp as error "sequential and window() cannot be specified together."
		   error 498	   
	   
	   }	   
	   
	   local techtype "sequential"
	
	}	
		
 
	   if "`window'"!=""{
	   
	       local techtype "window"   
	   
	   }	   
	   
	if "`maxiter'"==""{
		local maxiter=-1
	}
	if "`tol'"==""{
		local tol=-1
	}	
	
	
    tempvar period dmu
	
	qui egen `period'=group(`time')
	qui egen `dmu'=group(`id')	

	
    qui su  `period'
    local tmax=r(max)

    tempvar flag temp DD D21 D12
    
    qui gen `DD'=.
    qui gen `D21'=.
    qui gen `D12'=.
	
    qui gen `flag'=0
	
  sort `period' `dmu'
	
  if `"`techtype'"'=="contemporaneous"{
  
	    qui{
        forv t=1/`tmax'{
            replace `flag'= (`period'==`t')
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp')  ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            replace `DD'=`temp' if `period'==`t'
            drop `temp'
        }    
        local tt=`tmax'-1
        forv t=1/`tt'{
            replace `flag'=(`period'==`t'+1) 
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp')  ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            replace `D21'=`temp' if `period'==`t'
            drop `temp'
        }  

        forv t=2/`tmax'{
            replace `flag'=(`period'==`t'-1)
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp')  ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            replace `D12'=`temp' if `period'==`t'
            drop `temp'
        }       

    }
  
  
  }
  
  
    if `"`techtype'"'=="sequential"{
  
	    qui {
        forv t=1/`tmax'{
            replace `flag'=(`period'<=`t')
            shepdf if `period'==`t' & `touse', rflag(`flag') gen(`temp')  ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            replace `DD'=`temp' if `period'==`t'
            replace `flag'=0
            drop `temp'
        }    
        local tt=`tmax'-1
        forv t=1/`tt'{
            replace `flag'=(`period'<=`t'+1) 
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp')  ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            replace `D21'=`temp' if `period'==`t'
            drop `temp'
        }  

        forv t=2/`tmax'{
            replace `flag'= (`period'<=`t'-1) 
            shepdf if `period'==`t' & `touse', rflag(`flag') gen(`temp')  ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            replace `D12'=`temp' if `period'==`t'
            drop `temp'
        }       

    }
  
  
  }
  
  
  
     if `"`techtype'"'=="window"{
		local band=(`window'-1)/2
	    qui{
        forv t=1/`tmax'{
            replace `flag'=(`period'<=`t'+`band' & `period'>=`t'-`band') 
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp')  ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            replace `DD'=`temp' if `period'==`t'
            drop `temp'
        }    
        local tt=`tmax'-1
        forv t=1/`tt'{
            replace `flag'= (`period'<=`t'+1+`band' &  `period'>=`t'-`band'+1)
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp')  ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            replace `D21'=`temp' if `period'==`t'
            drop `temp'
        }  

        forv t=2/`tmax'{
            replace `flag'=(`period'<=`t'-1+`band' & `period'>=`t'-1-`band') 
            shepdf  if `period'==`t' & `touse', rflag(`flag') gen(`temp')  ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
            replace `D12'=`temp' if `period'==`t'
            drop `temp'
        }       

    }
  
  
  }
 

 	
 
	if `"`techtype'"'=="global"{

	    qui replace `flag'=1
		shepdf  if `touse', rflag(`flag') gen(`temp')  ort(`ort') in(`invars') op(`opvars') maxiter(`maxiter') tol(`tol')
        qui bys `dmu' (`period'): gen `tfp'=`temp'/`temp'[_n-1]	
		
		
	}
	else{
		qui {
			bys `dmu' (`period'): gen `tfp'=sqrt(`D12'/`DD'[_n-1]*`DD'/`D21'[_n-1])				
		}	
	
	}
	




end 



capture program drop shepdf
program define shepdf
    version 16

    syntax [if] [in], gen(string) INvars(varlist) OPvars(varlist) [rflag(varname) ort(string) VRS maxiter(numlist) tol(numlist)]
        marksample touse 
		markout `touse' `invars' `opvars' 
		
		tempvar touse2
		mark `touse2' if `rflag'
		markout `touse2' `invars' `opvars'
		//qui gen `touse2'=`rflag'	
        qui gen `gen'=.

		local comvars: list invars & opvars 
		if !(`"`comvars'"'==""){
			disp as error "`comvars' should not be specified as input and output simultaneously."
			error 498
		}		
		
        local data `invars' `opvars'
        local num: word count `invars'		
		
*******************************************************************************
/////////This section is from  Yong-bae Ji and Choonjoo Lee's DEA.ado//////////		
		// default orientation - Input Oriented
		if ("`ort'" == "") local ort = "IN"
		else {
			local ort = upper("`ort'")
			if ("`ort'" == "I" | "`ort'" == "IN" | "`ort'" == "INPUT") {
				local ort = "IN"
			}
			else if ("`ort'" == "O" | "`ort'" == "OUT" | "`ort'" == "OUTPUT") {
				local ort = "OUT"
			}
			else {
				di as err "option ort allows for case-insensitive " _c
				di as err "(i|in|input|o|out|output) or nothing."
				exit 198
			}
		}
		
*******************************************************************************		
		if "`vrs'"!=""{
			local rts=1
		}
		else{
			local rts=0
		
		}
		
		
		if "`ort'" =="OUT"{
			mata: sdf_o("`data'","`touse'", "`touse2'",`num',`rts',"`gen'",`maxiter',`tol')
			qui replace `gen'=1/`gen'
		  }
		else{
			mata: sdf_i("`data'","`touse'", "`touse2'",`num',`rts',"`gen'",`maxiter',`tol')
		 }
		 

end 





cap mata mata drop sdf_o()
mata:
    void function sdf_o(string scalar d, ///
                        string scalar touse, ///
						string scalar rflag, ///
						real scalar k,   ///
						real scalar scale, ///
						string scalar g, ///
						real scalar  maxiter, ///
						real scalar  tol)
    { 

          data=st_data(.,d,touse)
          data=data'
          dataref=st_data(.,d,rflag)
          dataref=dataref'
          M=rows(data)
          Xref=dataref[1..k,.]
          Yref=dataref[k+1..M,.]
          X=data[1..k,.]
          Y=data[k+1..M,.]
          N=cols(dataref)
  
          class LinearProgram scalar q
          q = LinearProgram()
		  
			if(maxiter!=-1){
			  q.setMaxiter(maxiter)
			}
			if (tol!=-1){
			  q.setTol(tol)
			}			  
		  
          c = (1, J(1,N,0))
          lowerbd =., J(1,N,0)
          upperbd = J(1,N+1,.)
		  if(scale==1){
            Aec= (0, J(1,N,1))
            q.setEquality(Aec, 1)
		   }
		  
          theta=J(cols(data),1,.)
  
          for(j=1;j<=cols(data);j++){
              A1 = (J(k,1,0),Xref)
              b1 = (X[.,j])
              A2 = (Y[.,j],-Yref)
              b2=J(M-k,1,0)
              Aie=A1 \ A2
              bie=b1 \ b2
              q.setCoefficients(c)
              q.setInequality(Aie, bie)
              q.setBounds(lowerbd, upperbd)
              theta[j]=q.optimize()		  
         }

          st_view(gen=.,.,g,touse)
          gen[.,.]=theta
    
    }

end


cap mata mata drop sdf_i()
mata:
void function sdf_i(string scalar d, ///
                    string scalar touse, ///
					string scalar rflag, ///
					real scalar k, ///
					real scalar scale, ///
					string scalar g, ///
					real scalar  maxiter, ///
				    real scalar  tol)
    { 

          data=st_data(.,d,touse)
          data=data'
          dataref=st_data(.,d,rflag)
          dataref=dataref'
          M=rows(data)
          Xref=dataref[1..k,.]
          Yref=dataref[k+1..M,.]
          X=data[1..k,.]
          Y=data[k+1..M,.]
          N=cols(dataref)
  
          class LinearProgram scalar q
          q = LinearProgram()
		  q.setMaxOrMin("min")
			if(maxiter!=-1){
			  q.setMaxiter(maxiter)
			}
			if (tol!=-1){
			  q.setTol(tol)
			}			  
          c = (1, J(1,N,0))
          lowerbd =., J(1,N,0)
          upperbd = J(1,N+1,.)		  
		  if(scale==1){
            Aec= (0, J(1,N,1))
            q.setEquality(Aec, 1)
		   }  
          theta=J(cols(data),1,.)
  
          for(j=1;j<=cols(data);j++){
              A1 = (-X[.,j],Xref)
              b1 = J(k,1,0)
              A2 = (J(M-k,1,0),-Yref)
              b2=  -Y[.,j]
              Aie=A1 \ A2
              bie=b1 \ b2
              q.setCoefficients(c)
              q.setInequality(Aie, bie)
              q.setBounds(lowerbd, upperbd)
              theta[j]=q.optimize()		  
         }

          st_view(gen=.,.,g,touse)
          gen[.,.]=theta
    
    }

end









