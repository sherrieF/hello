#/bin/csh

  set OUT=/lustre/f2/dev/esrl/Sherrie.Fredrick/NCL/stats/process_1999/process_2003.out
  source /ncrc/home1/Sherrie.Fredrick/load_modules.csh
  echo "we are in the script" >> $OUT
  set analdate=(`awk '{print $1}' "/lustre/f2/dev/esrl/Sherrie.Fredrick/NCL/stats/process_1999/analdate"`)
  echo $analdate  >> $OUT

  set rdate=(`awk '{print $3}' "/lustre/f2/scratch/esrl/Oar.Esrl.Nggps_psd/1999stream/analdate.csh"`)
  set current_run_date = `echo $rdate | cut -c1-10`
  echo $current_run_date >> $OUT
  


  if($analdate > $current_run_date) then
     echo "analdate is greater than the current run date"
     exit
  endif
 
#Parse the analysis date
set thedate  =  `echo  $analdate  |  cut -c1-10`
set yr    =  `echo  $analdate  |  cut -c1-4`
set cmo   =  `echo  $analdate  |  cut -c5-6`
set dd    =  `echo  $analdate  |  cut -c7-8`

 
echo ${yr}  ${cmo}
set monthnames=("jan" "feb" "march" "april" "may" "june" "july" "august" "sept" "oct" "nov" "dec")
set charone = `echo  $analdate  |  cut -c5`
set chartwo = `echo  $analdate  |  cut -c6`

if( $charone == "0") then
     set imo=${chartwo}
     set longmo=$monthnames[$chartwo]
else
     set imo=$cmo
     set longmo=$monthnames[$imo]
endif


set yrmo=$yr$cmo
echo ${yrmo} ${longmo}

set lastdayofmonth = ` cal  $imo $yr | tr -s " " "\n"|tail -1`
echo "last day of the month "${lastdayofmonth}


set syear=1999

#copy ensmean history file for calculating analysis increment standard deviations
cd /lustre/f2/dev/esrl/Sherrie.Fredrick/verif/1999_start/ensmean
mkdir ${longmo}${yr}
cd /lustre/f2/dev/esrl/Sherrie.Fredrick/verif/1999_start/ensmean/${longmo}${yr}
cp /lustre/f2/scratch/esrl/Oar.Esrl.Nggps_psd/1999stream/$analdate/ensmean/fv3_historyp_latlon.nc .
mv fv3_historyp_latlon.nc ${analdate}_fv3_ensmean.nc
set sixhour=${yr}${cmo}${dd}06
echo ${sixhour}
cp /lustre/f2/scratch/esrl/Oar.Esrl.Nggps_psd/1999stream/${sixhour}/ensmean/fv3_historyp_latlon.nc .
mv fv3_historyp_latlon.nc   ${sixhour}_fv3_ensmean.nc


#bfg files
mkdir /lustre/f2/dev/esrl/Sherrie.Fredrick/verif/1999_start/bfg/${longmo}${yr} 
cd /lustre/f2/dev/esrl/Sherrie.Fredrick/verif/1999_start/bfg/${longmo}${yr}
cp /lustre/f2/scratch/esrl/Oar.Esrl.Nggps_psd/1999stream/${analdate}/bfg*_control2 .


#set up directories where model files and analysis files are .
setenv TMPDIR /lustre/f2/dev/esrl/Sherrie.Fredrick/NCL/stats  

#see if we have the control2 and the cfsr directories.  Sometime one
#is there but the other directory is not.  We need both for MET
set verif_dir="/lustre/f2/dev/esrl/Sherrie.Fredrick/verif/"$syear"_start/"
#set reanalysis_dir=${verif_dir}/reanalysis/${longmo}${yr}/${analdate}
#set cfsr_dir=${verif_dir}/cfsr/${longmo}${yr}/${analdate}


set longfcst_dir="/lustre/f2/scratch/esrl/Oar.Esrl.Nggps_psd/1999stream/${analdate}"
cd  ${longfcst_dir}
pwd
if( -d longfcst) then
    echo "we have the directory yea"
    cd longfcst
    pwd
    if( -d control2) then
        echo "We have the reanalysis control2 directory" 
        cd ${verif_dir}
        mkdir reanalysis
        cd ${verif_dir}/reanalysis
        mkdir ${longmo}${yr}
        cd ${verif_dir}/reanalysis/${longmo}${yr}
        mkdir ${analdate} 
        cd ${verif_dir}/reanalysis/${longmo}${yr}/${analdate}
        mkdir met_dir  model_dir 
        set reanalysis_dir=${verif_dir}/reanalysis/${longmo}${yr}/${analdate}        
    else 
        echo "we do not have the control2 directory"
        goto increment 
    endif
    cd ${longfcst_dir}/longfcst
    if( -d cfsr) then
        echo "We have the cfsr directory"
        cd ${verif_dir}
        mkdir cfsr
        cd ${verif_dir}/cfsr
        mkdir ${longmo}${yr}
        cd ${verif_dir}/cfsr/${longmo}${yr}
        mkdir ${analdate}
        cd ${verif_dir}/cfsr/${longmo}${yr}/${analdate}
        mkdir met_dir  model_dir
        set cfsr_dir=${verif_dir}/cfsr/${longmo}${yr}/${analdate}
    else
        echo "we do not have the cfsr directory"
#        goto increment
    endif
else
     echo "longfcst directory does not exist" >> $OUT
     goto increment
endif
echo "we are now here before running MET"  >> $OUT
echo ${reanalysis_dir}  ${cfsr_dir} 

set erai_dir="/lustre/f2/dev/esrl/Sherrie.Fredrick/era_interim/$syear/"
set clim_dir="/lustre/f2/dev/esrl/Sherrie.Fredrick/climate/"

cp ${longfcst_dir}/longfcst/control2/fv3_historyp_latlon.nc  ${reanalysis_dir}/model_dir
set fsize=`stat -c %s ${reanalysis_dir}/model_dir/fv3_historyp_latlon.nc`
if($fsize < 500000000) then
     echo "Bad reanalysis file for "${analdate} >> $OUT
     exit
endif

cp ${longfcst_dir}/longfcst/cfsr/fv3_historyp_latlon.nc  ${cfsr_dir}/model_dir
set fsize=`stat -c %s ${cfsr_dir}/model_dir/fv3_historyp_latlon.nc`
if($fsize < 500000000) then
     echo "Bad cfsr file for "${analdate} >> $OUT
     exit
endif


#Now add the metadata to the files so MET can read them
ncl /lustre/f2/dev/esrl/Sherrie.Fredrick/NCL/stats/process_1999/add_metadata.ncl   anal_date=${analdate}   syear=$syear  'init="reanalysis"'
ncl /lustre/f2/dev/esrl/Sherrie.Fredrick/NCL/stats/process_1999/add_metadata.ncl  anal_date=${analdate}  syear=$syear  'init="cfsr"'
echo "running add_metadata passed" >> $OUT


#now we can run MET
module use /usw/ldtn/modulefiles
module load met/7.0
setenv LD_LIBRARY_PATH /ncrc/usw/met/7.0/external_libs/lib:$LD_LIBRARY_PATH
set metdir="/lustre/f2/dev/esrl/Sherrie.Fredrick/MET/"
foreach hr( 000 006  024 048 072 096 120 )
        set anal_day=$dd
        set anal_mo=$imo
        set sufix="00"     
        @ anal_day= $anal_day + 0
   
        if($hr == "006") then 
           set sufix="06" 
        else if ($hr == "024") then
           @ anal_day= $anal_day + 1
        else if ($hr == "048") then
            @ anal_day= $anal_day + 2
        else if ($hr == "072") then
            @ anal_day= $anal_day + 3
        else if ($hr == "096") then
            @ anal_day= $anal_day + 4
        else if ($hr == "120") then
            @ anal_day= $anal_day + 5
        endif
       
 
        if($anal_day > ${lastdayofmonth}) then
           @ anal_day  =  $anal_day  - ${lastdayofmonth}
           @ anal_mo   = $anal_mo + 1
           if ($anal_mo > 12) then
             set anal_mo=1
             set yr=2003
           endif
        endif

         echo $anal_mo $anal_day
         if(($anal_mo < 10)  && ($anal_day < 10)) then
              set erai_name="erai_"${yr}0${anal_mo}0${anal_day}${sufix}".grib"
              set clim_name="cmean_1d.1959"0${anal_mo}0${anal_day}
         else if (($anal_mo < 10)  && ($anal_day >= 10)) then
              set erai_name="erai_"${yr}0${anal_mo}${anal_day}${sufix}".grib"
              set clim_name="cmean_1d.1959"0${anal_mo}${anal_day}
         else if (($anal_mo >= 10)  && ($anal_day < 10)) then
              set erai_name="erai_"${yr}${anal_mo}0${anal_day}${sufix}".grib"
              set clim_name="cmean_1d.1959"${anal_mo}0${anal_day}
         else 
              set erai_name="erai_"${yr}${anal_mo}${anal_day}${sufix}".grib"
              set clim_name="cmean_1d.1959"${anal_mo}${anal_day}
         endif
       echo $erai_name  $clim_name
      
#The climate name is not passed in as a variable to MET.  So we need to update the 
#grid_stat_config file for each hour so we get the correct climate data. 
       cd /lustre/f2/dev/esrl/Sherrie.Fredrick/NCL/stats/process_1999
       /usr/bin/m4 -D _SDATE_=${clim_name} grid_stat_config.tmp >! grid_stat_config

#Now we can run MET
      set outdir=${reanalysis_dir}/met_dir
      ${metdir}grid_stat ${reanalysis_dir}/model_dir/PGB.F${hr}.nc  ${erai_dir}${erai_name}  grid_stat_config  -outdir ${outdir} -v 1
      if($hr != "000") then
         set outdir=${cfsr_dir}/met_dir
         ${metdir}grid_stat ${cfsr_dir}/model_dir/PGB.F${hr}.nc  ${erai_dir}${erai_name}  grid_stat_config  -outdir ${outdir} -v 1
      endif
end

#We have run MET. Extract the information we want from the met output files.
cd  ${reanalysis_dir}/met_dir
foreach fl(grid_stat*_cnt.txt)
  echo ${fl} 
  ncl /lustre/f2/dev/esrl/Sherrie.Fredrick/NCL/stats/dump_metfile.ncl 'init="reanalysis"' cnt_file=\"${fl}\"   anal_date=$analdate  sim_iday=$dd
end 

cd ${cfsr_dir}/met_dir
foreach fl(grid_stat*_cnt.txt)
  ncl /lustre/f2/dev/esrl/Sherrie.Fredrick/NCL/stats/dump_metfile.ncl 'init="cfsr"' cnt_file=\"${fl}\"   anal_date=$analdate   sim_iday=$dd
end 


#The paris.nc file output from MET contain the 
#fields that were used for the MET stats.  We
#use these files to do our processing.
cd  ${verif_dir}reanalysis/${longmo}$yr/$analdate/met_dir
set count = 0
foreach fl(*.nc)
   echo $fl  $count
   if($count == 0) then
        mv  ${fl} "grid_stat_"$yr$cmo$dd"_000_pairs.nc"
   else if($count == 1) then
        mv  ${fl} "grid_stat_"$yr$cmo$dd"_006_pairs.nc"
   else if($count == 2) then
        mv ${fl} "grid_stat_"$yr$cmo$dd"_024_pairs.nc"
   else if($count == 3) then
        mv ${fl} "grid_stat_"$yr$cmo$dd"_048_pairs.nc"
   else if($count == 4) then
        mv ${fl} "grid_stat_"$yr$cmo$dd"_072_pairs.nc"
   else if($count == 5) then
        mv ${fl} "grid_stat_"$yr$cmo$dd"_096_pairs.nc"
   else if($count == 6) then
        mv ${fl} "grid_stat_"$yr$cmo$dd"_120_pairs.nc"
   endif
   
   @ count = $count + 1 
end 


here:
set count=1
cd  ${verif_dir}cfsr/${longmo}$yr/$analdate/met_dir
foreach fl(*.nc)
   echo $fl  $count
   if($count == 0) then
        mv  ${fl} "grid_stat_"$yr$cmo$dd"_000_pairs.nc"
   else if($count == 1) then
        mv  ${fl} "grid_stat_"$yr$cmo$dd"_006_pairs.nc"
   else if($count == 2) then
        mv ${fl} "grid_stat_"$yr$cmo$dd"_024_pairs.nc"
   else if($count == 3) then
        mv ${fl} "grid_stat_"$yr$cmo$dd"_048_pairs.nc"
   else if($count == 4) then
        mv ${fl} "grid_stat_"$yr$cmo$dd"_072_pairs.nc"
   else if($count == 5) then
        mv ${fl} "grid_stat_"$yr$cmo$dd"_096_pairs.nc"
   else if($count == 6) then
        mv ${fl} "grid_stat_"$yr$cmo$dd"_120_pairs.nc"
   endif

   @ count = $count + 1
end 
pwd
  
increment:
echo "updating the analdate" >> $OUT
cd /lustre/f2/dev/esrl/Sherrie.Fredrick/NCL/stats/process_1999
rm analdate
set newdate = `/ncrc/home1/Sherrie.Fredrick/bin/incdate.sh $analdate  24`
echo $newdate
echo ${newdate} >> analdate


#see if we are at the end of the month
if($dd == ${lastdayofmonth}) then
   echo "This is the last day of the month"
   exit
   cd /lustre/f2/dev/esrl/Sherrie.Fredrick/NCL/stats/process_1999
   ./run_stats.csh  $syear ${longmo}$yr  $imo   $yr 
endif
