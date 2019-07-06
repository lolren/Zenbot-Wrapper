#!/bin/bash


trade_type=simulate
#can be simulate or live

simulate_file=simulate/pricelist
#location of simulation file


sim_coin1=1
#if we simulate, we start with this number of coin 1

sim_coin2=0
#if we simulate, we start with this number of coin 2

market_fee=0.1
#trading fee on binance


getassetsvariable=1

strategy=buy_low_sell_high_strategy
# this can be either buy_low_sell_high_strategy. In the future, i hope to add more strategys

############################################################variables################
# add last action to menu, add info about panic selling value....
#secondlast -second last price
#getliveprice - function to get the live price

#####################################################################################
#timer function we require those timigs
 
#1m, 2m, 3m, 5m, 10m, 15m, 30m, 1h, 5h, 10h, 24h

#######################################################################################

#high - the highest price of the coin
#low - the lowest price of the coin
#failsafe=panic sell
coin=BTCUSDT
#change here if you want a different coin
#coin - the selected pair of coins
##############################################################################
buypercent=0.3
#buy percentage
##############################################################################
sellpercent=0.3
#sell percentage
#############################################################################
failsafebuypercent=10
failsafesellpercent=10 ######will have to delete it in the future
#After 1 failsafe triggered, the default buy and sell values will change to this fallback values
#############################################################################
stoploss=true
#if true, this will not sell bellow the last buy price, other options: "false" to disable it
##############################################################################################
minimumprofitpercent=0.4
#this is the minimum profit the bot will sell for if more than 0. to disable. set this to 0
##############################################################################################
failsafe=0


#this  is the failsafe of the bot. It will sell everything once the bot is reachis a loss of the set % , after it buys. to disable, set it to 0

readingerrorpercent=2 # this is the maximum allowed percent between readings.ex. if a reading is smaller or bigger than a average reading! happened in the testing!!!

################################################################################################
#change this if you want a different update time for binance price readings 
binanceupdateseconds=3
######################################################################################################################################################################################################
rdg=10
#change this to change the number of readings required for smooting. This is required because the price is fluctuating a lot. So the bot takes this number of reagings,
# cut the spiketop number from the top, the spikebottom number from the bottom, and creates an average of the remaining midddle numbers
#example : if the prices are 1,2,3,4,5,6,7,8,9,10 ( this is rdg number), spike bottom will remove 1 and 2, spiketop will remove 9 and 10 and the bot makes an average of this
#ALSO IMPORTANT: THIS NUMBER MUST BE BIGGER THAN spikebottom + spiketop+1
#numbers of spikes reading to cut from the top. this cannot be more than rdg 
spiketop=3
#numbers of spikes reading to cut from the bottom. this cannot be more than rdg  
spikebottom=3
#######################################################################################################################################################################################################
buysellretryseconds=240
#this is the time that the bot is trying to retry a buy or sell in seconds
#################################################################################################################################################################################################
sellbuyretry=10
#this is the number of retry the bot is trying to place a buy or sell order...................
######################################################################################################################################################################################################
order_type=taker
#this is the order type of the bot. it can be taker or maker..... ( taker means the price is market price, on maker, the bot sets the price
#taker is market price, on maker we set the price.....................................
####################
####################################################################################################################################################################################
zenbotpath="/home/lolren/zenbot"
#this is the path to zenbot. currently this bot requires zenbot as a buy and sell backend. WARNING , DO NOT CHANGE THIS UNLESS YOU KNOW WHAT YOU ARE DOING !!!!!!
###########################################################################################################################################################################################################
tradelog="/home/lolren/bot//logs/tradelog.txt"
# default log tradelog path
#######################################################################################END OF CONFIG FILES!!!!!!!!!!!#######################################################################################
default_email=lor3n4you200@gmail.com

send_mail=no # this will send or not send a email on each transaction!
#the trade bot sends an email from a gmail account
####### if you want to set your own gmail account sender, change the value from :  /home/zenbot/.msmtprc and /home/zenbot/.msmtprc
### if you don`t care about it, just modify the above mail and use your email.
start_price_as_last_buy_price=true
#########################################################################

##################################multicoin...not enabled currently####################################

###########################################################WARNING###########################################################
######################################################BOT VARIABLES##########################################################
######################################################DO NOT CHANGE!!!!!!!!##################################################
oldbuypercent=$buypercent
oldsellpercent=$sellpercent
paniccounter=0
buyretrycount=0
sellretrycount=0
sellcheckswitch=0
buycheckswitch=0
sellswitch=0 #this should be deprecated 
buyswitch=0  #this should be deprecated 
panicnr=0
ramdirectory=/mnt/lpmbot
#lastbuyprice=N/A #because of this and the stoploss option, script cannot beging with a sale.
lastbuypriceswitch=1 # this will set the bot with the first read price as the buy price
lastsellprice=N/A
manualkeypressswitch=1
firsruntimer=0 

runtimecounter=0 # this is the runtime counter that adds 1 at every minute of script run! ( for now, just when multicoin is enabled, but that will change in the future) 
cut="#" # this ensures you don`t see all the unavailable multicoin options 


#######

gainpercentswich=1
####################################these switches change to 1 after the time in their name ===

#################hack to simulate the assets understanding. this will be changed soon
#############################################################################bot start, nothing to change beyond this point###########################################################################
#############################multicoin start colours######################

#######################################variables##################################################################
#sold=1
#bought=0
readingsnr=0
tradesnr=0
getassets=1
##############################################end of hack
#clear the pricelist and sorted files  at first run from previous sessions
getassetsvariable=1 ####this is the variable that change the bot from getting the assets again
path=`pwd` ######get the path of the script required for the bot to come back after it`s calling zenbot


############################################################keypres#######################
#############################################################################################


####################################Functions#########################################


#############################################################rootcheck#######################################################
#this function checks for root, create a mount directory and a mounts a ramdisk. this is necesary because the number of writes the bot makes
rootcheck () {
if [ "$EUID" -ne 0 ]
  then 
  echo "Please run as root. As user, I will make create and update files on hdd, but i rather do it on ram!"
  sleep 5
  root=0
  else
  root=1
if [ -d $ramdirectory ]
then
    echo "Directory already exists"
	if mountpoint -q $ramdirectory ; then
    echo "It's mounted."
else
    echo "It's not mounted1."
	mount -t tmpfs -o size=500m tmpfs $ramdirectory
	echo $ramdirectory
fi
else
    mkdir $ramdirectory
	if mountpoint -q $ramdirectory ; then

    echo "It's mounted."
else
    echo "It's not mounted."
	mount -t tmpfs -o size=500m tmpfs $ramdirectory
	echo creating ramdisk
fi
fi  
  echo I am root
fi

 if [ "$root" = "1" ] ; then
buysellcheck=/mnt/lpmbot/buysellcheck
pricelist=/mnt/lpmbot/pricelist
sorted=/mnt/lpmbot/sorted
assetlist=/mnt/lpmbot/assetlist
allpricesfile=/mnt/lpmbot/allpricesfile
truncate -s 0 $sorted
truncate -s 0 $pricelist
truncate -s 0 $assetlist
truncate -s 0 $allpricesfile
truncate -s 0 $buysellcheck

date -s "$(wget -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
echo all files will be mounted in temp directory

if  [ "$trade_type" = "live" ] ; then 
loop 
else 
simulate_loop
fi  

else 
buysellcheck=buysellcheck
pricelist=pricelist
sorted=sorted
assetlist=assetlist
allpricesfile=allpricesfile
truncate -s 0 $pricelist
truncate -s 0 $sorted
truncate -s 0 $assetlist
truncate -s 0 $allpricesfile
truncate -s 0 $buysellcheck
#############################multicoin options############################################################

##################################################END OF MULTICOIN OPTIONS##############################################
echo all files will be in local directory
sleep 2
if  [ "$trade_type" = "live" ] ; then 
loop 
else 
simulate_loop
fi 

fi

}

coinselect () {

############this function will get the 2 coins from the exchange name given as a variable ($1). For example it will split up ETHUSDT  to : coin1=ETH, coin2=USDT

#there are for main market on binance ( BNB, ETH, USDT and BTC) 
if [[ $(echo $1 |tail -c 5) = "USDT" ]] ; then 
coin2main=USDT
coin1main=`echo $1 | sed "s/USDT.*//"`

else
coin2main=`echo $1 | tail -c 4 | cut -d ' ' -f4`
coin1main=`echo $1 | sed "s/$coin2main.*//"`

fi 


}

coinmarketcap () {
#this function is getting the prices from coinmarketcap, in order to know the ammount of coin it has.......
# usage : call coinmarketcap ETH for example 

 python coinmarketcap/coinmarketcapbridge.py  | grep -E -o ".{0,0}$1'.{0,175}" |  grep -E -o ".{0,0}price.{0,15}"  | sed 's/[^0-9.]//g'


 
 }

 findassetvalue () {
 
 ##########first, we need to get the type of the coins we own...
                         
 ### the variable of the exchange coins are :
 # $coin1main and $coin2main
#####################################if getassets variable  is 1, the variable coin 
                                  

                                                                                                                               if [ "trade_type" = "live" ] ; then  

                                if [ "$getassets"="1" ] ; then 
								
 if [ "$coin1main" != "BCC" ] ; then pricecoin1=$(coinmarketcap $coin1main)
 else 
 pricecoin1=$(coinmarketcap BCH)
fi                                 
								pricecoin2=$(coinmarketcap $coin2main)
                                 echo the price of coin1 is $pricecoin1
                                 echo the price of coin2 is $pricecoin2
                                 
                                   #############################
 #now, we will see what asset will have more , so we know if we buy first or sell first
#our asset variables are :
#$coin1mainfreeassets
#$coin1mainlockedassets
#$coin1mainfreeassets
#$coin1mainlockedassets
#the calculator function is echo " x + y " | bc -l

#total assets
                                #echo 1 $coin2mainfreeassets 2 $coin2mainlockedassets  3 $pricecoin2   
   
                                coin1value=`echo " ( $coin1mainfreeassets + $coin1mainlockedassets) * $pricecoin1 " | bc -l | sed 's/^\./0./'`
								#echo $coin1mainfreeassets , 1 $coin1mainlockedassets, 2 $pricecoin1 3
								
                                coin2value=`echo " ( $coin2mainfreeassets + $coin2mainlockedassets) * $pricecoin2 " | bc -l`
                                echo total value of coin1 $coin1main  is $coin1value USD 
                                echo total value of coin2  $coin2main  is $coin2value USD 
								getassets=0
	

if [ "$coin1value" = "0" ] && [ "$coin2value" = "0" ] ; 
then



echo You have no money in, the Bot will exit 
sleep 5
exit 1

fi 
                                                                                                              
          if [ "$tradesnr" = "0" ] ;
		                             then 
           

                                      if (( $(echo "$coin1value > $coin2value" | bc -l) )); then 
                                        echo  $coin1value este valuare coin 1
                                        echo  $coin2value este valuare coin 2
                                                          if [ "$readingsnr" = "0" ] ; then 
                                                             echo first action will be sell
                                                             sold=0
                                                             bought=1
                                                             fi
                                      else
                                                                      if [ "$readingsnr" = "0" ] ; then 
                                                                         echo first action will be buy
                                                                         sold=1
 			                                                             bought=0
                                                                      fi 
                                      fi 
                                                                         fi 


   
        fi 
                                                                                                                                      else 
																																	                 if [ "$tradesnr" = "0" ] ; #this will assume that first action will be sale!
		                                                                                                                              then 
																					                                                 echo first action will be sell
                                                                                                                                     sold=0
                                                                                                                                     bought=1
																												                                     fi
																											 
																											                            fi 
																					
																					
																					
																					
   }




getallprices () {

                                           python binance/binancebridge.py prices > $allpricesfile
}

getliveprice () {
#filter the live price from the binance API response from the allpricesfile . to get a specific pair of coin call getliveprice $coin 
                                           
										   
										   
										   cat $allpricesfile | grep -E -o ".{0,0}$1.{0,17}" |  sed 's/.*u//' | sed 's:^.\(.*\).$:\1:' | sed 's/[^0-9.]//g'
}
#####################################################################get highest value function###################################################################################################
gethigh () {
#this gets highest price from the pricelist
                                           awk -F ":" '{print|"sort -n"}' $pricelist | sed  '/^$/d'  | tail -1
}
#####################################################################get lowest value function###################################################################################################
getlow () {
#this is the function to get the lowest number from pricelist
                                          awk -F ":" '{print|"sort -n"}' $pricelist |sed  '/^$/d' | sed -n '1p'
}
################################################################################################last price function###################################################################################################
lastprices () {
#this function get`s the last prices. for example if i want next to last price i give the variable 2 (e.g lastprices 2) should give me last but 1 price and so on
                                          tail -$1 $pricelist | head -1
}
#######################################################################price function###################################################################################################
finalprice () {
                                      tail -n $rdg $pricelist | sort > $sorted        #put the last readings in a file called sorted
                                      readingsnr=`wc -l $sorted | awk '{print $1;}'` # command to find out how many lines there are in file
             
			 if [ "$readingsnr" = "$rdg" ] 
	          
			 then
    
	 #now let sort the sorted file list and do an average	
	 #set to 2 and spiketop is also set cu 3, middle file  wil contain the values 4 till 8
	 #marker2
	                                   averageprice=`head -n -$spikebottom $sorted | tail -n +$((spiketop+1)) | awk '{ s += $1 } END { printf("%.7f\n", s/NR) }'`
									    errorfix2=`echo "scale=3; 100 * ($liveprice - $averageprice) / $averageprice " | bc | sed -e 's/^-\./-0./' -e 's/^\./0./' | tr --delete -`
                                                  if (( $(echo "$errorfix2 > $readingerrorpercent" | bc -l) )); then #this wont allow any panic sell if the difference between averageprice and liveprice is to big
												  averageprice=$liveprice
												 
												  fi
									   
                                       lowpercentage=`echo "scale=3; 100 * ($averageprice - $low) / $low" | bc | sed -e 's/^-\./-0./' -e 's/^\./0./'`
 #percentage formula is "echo "scale=2; 100 * ($y - $x) / $x" | bc | sed -e 's/^-\./-0./' -e 's/^\./0./' "
	                                   highpercentage=`echo "scale=3; 100 * ($averageprice - $high) / $high" | bc | sed -e 's/^-\./-0./' -e 's/^\./0./' | tr --delete - `
                                       lowtohighpercentage=`echo "scale=3; 100 * ($low - $high) / $high" | bc | sed -e 's/^-\./-0./' -e 's/^\./0./' | tr --delete - `                                  
									   #echo ""
									   #echo "$(tput setaf 1)Average price: $(tput setab 7)$averageprice$(tput sgr 0)"
									   #echo the average price is : $averageprice  
	                                
                                           
			 else
                                       
									  return 1
	                                   
	                                  
    
             fi
              }
##################################################################assets function######################################################################################################
assets () {
#this is the part to find the assets own . it will display free and locked assets, at the moment, just for the selected coins

           if [ $getassetsvariable = "1" ] ; 
			 
	       then

           truncate -s 0 $assetlist #deletes previous values in the assetlist file
           python binance/binancebridge.py balances > $assetlist #get all our assets from binance and put them in assetlist file
           coin1mainlenght=`echo -n $coin1main | wc -c`  #find the lenght of coin1main 
           coin2mainlenght=`echo -n $coin2main | wc -c`  #find the lenght of coin1main

		
			                                     if [ $coin1mainlenght = "3" ]; then
			

                                                 coin1mainfreeassets=`cat $assetlist | egrep -o "'$coin1main.{49}" | egrep -o ".{10}$"  | sed 's/[^0-9.]//g'  | sed -n 2,4p`
	                                             coin1mainlockedassets=` cat $assetlist | egrep -o "'$coin1main.{49}" |  sed 's/,.*//'  | sed 's/[^0-9.]//g' | sed -n 2,4p`
	                                                                           else
                               
                   							     coin1mainfreeassets=`cat $assetlist | egrep -o "'$coin1main.{50}" | egrep -o ".{11}$"`
								                 coin1mainlockedassets=` cat $assetlist | egrep -o "'$coin1main.{50}" |  sed 's/,.*//'  | sed 's/[^0-9.]//g'`
                                                fi

								
								
                                                                if [ $coin2mainlenght = "3" ]; then
                               
							                                    coin2mainfreeassets=`cat $assetlist | egrep -o "'$coin2main.{49}" | egrep -o ".{10}$"  | sed 's/[^0-9.]//g'`
							                                    coin2mainlockedassets=`cat $assetlist | egrep -o "'$coin2main.{49}" | sed 's/,.*//'  | sed 's/[^0-9.]//g' `
                              
	                                                                                          else
	                                             coin2mainfreeassets=`cat $assetlist | egrep -o "'$coin2main.{50}" | egrep -o ".{11}$" | sed 's/[^0-9.]//g'`
	                                             coin2mainlockedassets=`cat $assetlist | egrep -o "'$coin2main.{50}" | sed 's/,.*//'  | sed 's/[^0-9.]//g '`
	
	
                                                                                              fi
																							  
                                          if [ "trade_type" = "live" ] ; then           
		  #############this runs only after a transaction or at startup!!!!!!!!!!!!!!!!!!!!!!!!
	       display #this is the display function, which is the main menu of the bot 
	       findassetvalue  #######this is the function that gets the price from coinmarketcap to compare the assets value
           getassetsvariable=0 # this turns off the get asset command. if you want to get assets, put this to 1
													                     else
																		 echo This is a simulation 
																		 simulator_calculator
																		 display
																		 findassetvalue
																		 
																		 fi

            else
                                                                                                                      if [ "trade_type" = "live" ] ; then                               
         									                                                                          #this gets called all the time!!!!!!!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!
										                                                                              getallprices #this command get`s all prices into 1 file
									                                                                                  liveprice=$(getliveprice $coin) # this command get`s the live price from the live price function after the bot get assets from binance account
                                                                                                                      finalprice
                                                                                                                      echo $liveprice >> $pricelist
                                                                                                                      high=$(gethigh) 
                                                                                                                      low=$(getlow)
										                                                                              display 
										                                                                              profit
                                                                                                                       if [ "$readingsnr" = "$rdg" ] ; then 
                                                                                                                        $strategy # this should be the strategy
																									                   fi # this should be the strategy
																													                                   else 
																																					   liveprice=$sim_price
																																					   finalprice
																																					   echo $liveprice >> $pricelist
																																					   high=$(gethigh) 
                                                                                                                                                       low=$(getlow)
																																					   display
																																					   profit
																																					   if [ "$readingsnr" = "$rdg" ] ; then 
                                                                                                                                                       $strategy # this should be the strategy
																																					   fi
																																					   simulator_calculator
																																					   
																																					  # echo This is a simulation!!!
																																					   fi
								
          
     		  fi

}


simulator_calculator () {

#echo $sim_buy  $sim_sale
# this is the calculator for the simulator! it will calculate the loss or wins in a simulated trade only!
#for the moment it will assume only that we start with sell operation!!

if [ "$trade_type" = "simulate" ]  ; then 
  	                                                                                                                if [ "$tradesnr" = "0" ] ; #this will assume that first action will be sale!
		                                                                                                                              then 
	                                                                                            
	                                                                                                            coin1mainfreeassets=$sim_coin1
	                                                                                                            coin2mainfreeassets=$sim_coin2  
                        
                                                                                                                                      fi 
																												
if [ "$sim_sale" = "1" ] ; then 
echo do the simulation calculations for a selling operation

coin1afterfee=`echo "scale=10; $coin1mainfreeassets  -  ( $coin1mainfreeassets / 100 * $market_fee)" | bc | sed 's/^\./0./'`
coin2mainfreeassets=`echo "scale=10; $coin1afterfee * $averageprice " | bc | sed 's/^\./0./'`
coin1mainfreeassets=0
sim_sale=0	
fi
																												
																												
																												
																												
if  [ "$sim_buy" = "1" ] ; then

coin2afterfee=`echo "scale=10; $coin2mainfreeassets  -  ( $coin2mainfreeassets / 100 * $market_fee)" | bc | sed 's/^\./0./'`
coin1mainfreeassets=`echo "scale=10; $coin2afterfee / $averageprice " | bc | sed 's/^\./0./'`

echo do the simulation calculations for a buying operation 

coin2mainfreeassets=0

sim_buy=0																												
																								
fi







																										




fi
 getassetsvariable=0
}


#############################################deprecated sell command. will be replaced in the future###############################################################
#} 
sellcheck () {
if [ $sellcheckswitch = "1"  ] ; then
                                              echo setting up time and date before sell 
											  date -s "$(wget -qSO- --max-redirect=0 google.co.uk 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
											  truncate -s 0 $buysellcheck
                                              cd $zenbotpath
											  echo "try to sell for $buysellretryseconds with order typer : $order_type at $liveprice"
											  echo " " >> $tradelog
											  date >> $tradelog
											  echo try to sell  for $buysellretryseconds seconds with order maker at $liveprice >> $tradelog 
											   echo "-------------------------------------------------------------------" >> $tradelog
											                              if [ "$trade_type" = "live"	] ; then  
											  timeout $buysellretryseconds node zenbot sell  binance.$coin1main-$coin2main  --order_type $order_type 2>&1  | tee $buysellcheck 
                                                                           fi
																		   
											echo Zenbot has sold  on Binance Liveprice : $liveprice, Averageprice : $averageprice, Lastbuyprice: $lastbuyprice >> $tradelog
										    
											if [ "$trade_type" = "live" ] && [ "send_mail" = "yes"] ;
		                                                then 
											echo Subject: Zenbot has sold > mail.txt
                                            echo " " >> mail.txt  
                                            echo Liveprice - $liveprice  >> mail.txt 
                                            echo  Averageprice - $averageprice  >> mail.txt 
                                            echo Lastbuyprice - $lastbuyprice  >> mail.txt 
                                            ssmtp loren.bufanu@gmail.com < mail.txt
											                
													    fi 
														if [ "$trade_type" = "simulate" ] ; then 
														sim_sale=1
														fi
##########################################################################################################################################################################################################################
                                              cd $path
											  gainpercent=""
											  cat $buysellcheck | grep 'completed' &> /dev/null
if [ $? == 0 ] || [ "$trade_type" = "simulate"  ]; then ########## this happens only if trade is completed succesfully
                                            

   											  cat $buysellcheck | sed -n -e '/sell/,$p' >> $tradelog
											  cat $buysellcheck | sed -n -e '/sell/,$p'
											  echo sell has completed succesfully
											  lastsellprice=$liveprice
											  sellcheckswitch=0
											  aplay sounds/sold.wav
											  sold=1
								              bought=0
											  tradesnr=`expr $tradesnr + 1`
											  highpercentage=0
											  truncate -s 0 $pricelist
											  truncate -s 0 $sorted
											  if [ "$trade_type" = "live" ] ;  then  
											  getassetsvariable=1
											  fi
											  lowpercentage=0
											 oldlastbuyprice=$lastbuyprice
											  lastbuyprice=0
											  truncate -s 0 $buysellcheck
											  sellretrycount=0

											 
											  
			   else 
		
                                       	    sellretrycount=`expr $sellretrycount + 1`	  
											echo the sell failed
											echo try again with maker price
											truncate -s 0 $buysellcheck
                                            cd $zenbotpath
										    echo "RETRY to buy for $buysellretryseconds seconds  with order type taker at $liveprice"
									        echo " " >> $tradelog
											date >> $tradelog
                                            echo "===========================================================================" >> $tradelog
											echo "Retry to sell for $buysellretryseconds seconds with order taker at $liveprice" >> $tradelog 
                                           if [ "$trade_type" = "live"	] ; then 
										   timeout $buysellretryseconds node zenbot sell binance.$coin1main-$coin2main  --order_type taker 2>&1  | tee $buysellcheck  
										   fi
										   	if [ "$trade_type" = "simulate" ] ; then 
														sim_sale=1
														fi
											echo Subject: Zenbot has sold > mail.txt
                                            echo " " >> mail.txt  
                                            echo Liveprice - $liveprice  >> mail.txt 
                                            echo  Averageprice - $averageprice  >> mail.txt 
                                            echo Lastbuyprice - $lastbuyprice  >> mail.txt 
                                            ssmtp loren.bufanu@gmail.com < mail.txt
											echo Zenbot has sold on Binance Liveprice : $liveprice, Averageprice : $averageprice, Lastbuyprice: $lastbuyprice >> $tradelog
											cd $path
											cat $buysellcheck | grep 'completed' &> /dev/null
                                           if [ $? == 0 ]; then ########## this happens only if trade is completed succesfully
                  
				                              echo Retry completed succesfully
				                              cat $buysellcheck | sed -n -e '/sell/,$p' >> $tradelog
											  echo sell has completed succesfully
											  lastsellprice=$liveprice
											  sellcheckswitch=0
											  aplay sounds/sold.wav
											  sold=1
								              bought=0
											  tradesnr=`expr $tradesnr + 1`
											  highpercentage=0
											  truncate -s 0 $pricelist
											  truncate -s 0 $sorted
											  if [ "$trade_type" = "live" ] ;  then 
											  getassetsvariable=1
											  fi
											  lowpercentage=0
											  oldlastbuyprice=$lastbuyprice
											  lastbuyprice=0
											  truncate -s 0 $buysellcheck
											  sellretrycount=0
				else
				
				if grep -q enough "$buysellcheck"; then
                 echo 
                 echo Zenbot does not have enough assets to complete the command 
				 echo sell  has completed succesfully
											    lastsellprice=$liveprice
											  sellcheckswitch=0
											  aplay sounds/sold.wav
											  sold=1
								              bought=0
											  tradesnr=`expr $tradesnr + 1`
											  highpercentage=0
											  truncate -s 0 $pricelist
											  truncate -s 0 $sorted
											  if [ "$trade_type" = "live" ] ;  then 
											  getassetsvariable=1
											  	if ["$trade_type" != "live" ] ; then 
														sim_sale=1
														fi
											  fi 
											  lowpercentage=0
											  oldlastbuyprice=$lastbuyprice
											  lastbuyprice=0
											  truncate -s 0 $buysellcheck
											  sellretrycount=0
				 
				 
				 
				 
				 
				 else 
				  
				  
	      sellretrycount=`expr $sellretrycount + 1`	  
		  
		  echo sell retry failed $sellretrycount times 
		  
		  if [ "$sellretrycount" -ge "$sellbuyretry" ] ; then  
		                                                      echo we failed to many times to try and sell the coins 
															  echo insert action here
															  aplay sounds/gameover.wav
															  ###################################################
															  
                                                              else 
                                                              echo going back and try to sell the coins. we failed $sellretrycount times
                                                             															 
															  sellcheck
															  
                                                              fi	
                              fi															  
											
											fi
											fi 									  
											  
											fi 
                                    
									
									
									
									
											  
											
					



}			   
			   
buycheck () {

####################################################################################################################################################

											   
                                              
                                               
                                              
											  
####################################################################################################################################################





if [ $buycheckswitch = "1"  ] ; then
                                              echo setting up time and date before buy
											  date -s "$(wget -qSO- --max-redirect=0 google.co.uk 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
											  truncate -s 0 $buysellcheck
                                              cd $zenbotpath
											  echo executing Zenbot
											  if [ "$trade_type" = "live"	] ; then 
											  timeout $buysellretryseconds node zenbot buy binance.$coin1main-$coin2main  --order_type $order_type 2>&1  | tee $buysellcheck 
											  fi
											            if [ "$trade_type" = "live" ] && [ "send_mail" = "yes"] ;
		                                                then 
											echo Subject: Zenbot has bought > mail.txt
                                            echo " " >> mail.txt  
                                            echo Liveprice - $liveprice  >> mail.txt 
                                            echo  Averageprice - $averageprice  >> mail.txt 
                                            echo Lastbuyprice - $lastbuyprice  >> mail.txt 
                                            ssmtp loren.bufanu@gmail.com < mail.txt
											             fi
														 	if [ "$trade_type" = "simulate" ] ; then 
														sim_buy=1
														fi
										    echo " " >> $tradelog
											  date >> $tradelog
											  echo Zenbot has Bought on Binance Liveprice : $liveprice, Averageprice : $averageprice, Lastbuyprice: $lastbuyprice >> $tradelog
											  echo "try to buy  for $buysellretryseconds with order typer : $order_type at $liveprice"
                                              echo "-------------------------------------------------------------------" >> $tradelog
											  echo "try to buy   for $buysellretryseconds with order maker at $liveprice" >> $tradelog 
											  cd $path
											  highestgainpercent=0 # reseting highest gain percent
											  cat $buysellcheck | grep 'completed' &> /dev/null

##########################################################################################################################################################################################################################
                                             
if [ $? == 0 ] || [ "$trade_type" = "simulate" ]; then ########## this happens only if trade is completed succesfully
                                            

   											  cat $buysellcheck | sed -n -e '/buy/,$p' >> $tradelog
											  cat $buysellcheck | sed -n -e '/buy/,$p'
											  echo buy  has completed succesfully
											  lastbuyprice=$liveprice
                                              aplay sounds/bought.wav
											  bought=1
									          sold=0
											  highpercentage=0
											  lowpercentage=0
											  tradesnr=`expr $tradesnr + 1`
											  date=`date`
											  truncate -s 0 $pricelist
										      truncate -s 0 $sorted
											  if [ "$trade_type" = "live" ] ;  then 
											  getassetsvariable=1
											  fi
											  truncate -s 0 $buysellcheck
											  buycheckswitch=0

											  

											 
											  
			   else 
		
                                       	    buyretrycount=`expr $buyretrycount + 1`	  
											echo the buy failed
											echo try again with taker  price
#######################################################################################################################################################################################################											
											truncate -s 0 $buysellcheck
                                            cd $zenbotpath
										    echo "RETRY to buy for $buysellretryseconds with order type taker at $liveprice"
											echo "" >> $tradelog
                                            echo "===========================================================================" >> $tradelog
											echo "Retry to buy for $buysellretryseconds with order taker at $liveprice" >> $tradelog 
                                           if [ "$trade_type" = "live"	] ; then 
										   timeout $buysellretryseconds node zenbot buy binance.$coin1main-$coin2main  --order_type taker 2>&1  | tee $buysellcheck 
										   fi
										                    if [ "$trade_type" = "live" ] && [ "send_mail" = "yes"] ;
		                                                   then 
											echo Subject: Zenbot has bought > mail.txt
                                            echo " " >> mail.txt  
                                            echo Liveprice - $liveprice  >> mail.txt 
                                            echo  Averageprice - $averageprice  >> mail.txt 
                                            echo Lastbuyprice - $lastbuyprice  >> mail.txt 
                                            ssmtp loren.bufanu@gmail.com < mail.txt
											               fi 
														    	if [ "$trade_type" = "simulate" ] ; then 
														sim_buy=1
														fi
										    echo " " >> $tradelog
											date >> $tradelog
											echo Zenbot has Bought on Binance Liveprice : $liveprice, Averageprice : $averageprice, Lastbuyprice: $lastbuyprice >> $tradelog
											cd $path
											cat $buysellcheck | grep 'completed' &> /dev/null
if [ $? == 0 ] || [ "$trade_type" = "simulate"  ]; then ########## this happens only if trade is completed succesfully
                  
				                              echo Retry completed succesfully
				                              cat $buysellcheck | sed -n -e '/buy/,$p' >> $tradelog
											  echo buy  has completed succesfully
											  lastbuyprice=$liveprice
                                              aplay sounds/bought.wav
											  bought=1
									          sold=0
											  highpercentage=0
											  lowpercentage=0
											  tradesnr=`expr $tradesnr + 1`
											  date=`date`
											  truncate -s 0 $pricelist
										      truncate -s 0 $sorted
											  if [ "$trade_type" = "live" ] ;  then 
											  getassetsvariable=1
											  fi
											  truncate -s 0 $buysellcheck
											  buycheckswitch =0
				else
				
				if grep -q enough "$buysellcheck"; then
                 echo 
                 echo Zenbot does not have enough assets to complete the command 
				 echo buy  has completed succesfully
											  lastbuyprice=$liveprice
                                              aplay sounds/bought.wav
											  bought=1
									          sold=0
											  highpercentage=0
											  lowpercentage=0
											  tradesnr=`expr $tradesnr + 1`
											  date=`date`
				                              truncate -s 0 $pricelist
										      truncate -s 0 $sorted
											  if [ "$trade_type" = "live" ] ;  then 
											  getassetsvariable=1
											  fi
											  truncate -s 0 $buysellcheck
											  buycheckswitch=0
				 
				 
				 
				 
				 
				 else 
              
                 


				  
				  
	      buyretrycount=`expr $buyretrycount + 1`	  
		  
		  echo buy retry failed $sellretrycount times 
		  
		  if [ "$buyretrycount" -ge "$sellbuyretry" ] ; then  
		                                                      echo we failed to many times to try and sell the coins 
															  echo insert action here
															  aplay sounds/gameover.wav
															  buycheck
															  ###################################################
															  
                                                              else 
                                                              echo going back and try to buy the coins. we failed $buyretrycount times
															  buycheck
															  
                                                              fi		  
											fi
											fi
											fi 									  
											  
											fi 



}
	

	######################################################STRATEGYS########################################################################################################################	
			   
			   

buy_low_sell_high_strategy () 
{

#this is the strategy which means ,buy low, sell high


#this will be the implemented strategy
#note : add a function when it buy`s after lowpercentage recovers a bit, maybe in a perioud of time
#                                                                   important variables : 
#                                                                                          $low - this is the lowest price so far
#                                                                                          $averageprice - the average price is 
#                                                                                          $high - the highest price
#                                                                                          $lowpercentage % - average reading compared to lowest value in percentage
#                                                                                          $highpercentage   -average reading compared to highest value in percentage 
#                                                                                          $buypercent - buy value variable set by the user
#                                                                                          $sellpercent
#                                                                                          $getassetsvariable - if this is 1, it will retrieve assets from binance 
#                                                                                          $lastbuyprice - the last price the bot bought
#                                                                                          $lastsellprice - the last price the bot sold at
#                                                                                          $allowsell - switch from the profit on  function (1 or 0)
#																						   $allowsellminprofitswitch - switch from the minimum profit percent function (1 or 0)

                                                                                                       if (( $(echo "$lowpercentage >= $buypercent" | bc -l) )); then
                                                                                                       buy  
											                                                           fi
     
	                                                                if (( $(echo "$highpercentage >= $sellpercent" | bc -l) ));  then 
                                                                    sale 
	                                                                fi                                                                   
		                                                       

}



buy () {
#this is the function that will buy. i`ve made it easy to simplify the strategy! 
                                                                           if [ "$sold" = "1" ] ; then
                                                                           echo we should buy here,calling zenbot
																		   buyswitch=1
																	       buycheckswitch=1
																		   buycheck
																		   fi
}


sale () {
#this is the function that will sale. i`ve made it easy to simplify the strategy! 
                                                                           if [ "$bought" = "1" ] && [ "$allowsell" = "1" ] && [ "$allowsellminprofitswitch" = "1" ] ;  then 
   																		   echo we should sell here, calling zenbot
																		   sellswitch=1
																		   sellcheckswitch=1
																		   sellcheck
																		   fi

}


############################################################################################END OF STRATEGYS##########################################################################################################
profit () {



if [ "$lastbuypriceswitch"  = "1" ] && [ "$bought" = "1" ]  ; then 
lastbuyprice=`awk 'NR==1 {print; exit}' $pricelist`   ### this sets the lastbuyprice as the first price read 
echo the last buy price is $lastbuyprice and i am here 
lastbuypriceswitch=0
 fi


#this is the function that is handling stop loss and minimumprofitpercent
#depending on the variables, it will allow or not to sell 
#variables to control this function:
#stoploss-can be true or false
#minimumprofitpercent- can be a number in %. it will be the number between the buy price and the price the bot can sell at 

                                                                                                 if [ "$stoploss" = "true" ] && [ "$bought" = "1" ] && [ "$readingsnr" = "$rdg" ] ;  then 
                                 #  if (( $(awk 'BEGIN {print ("'$averageprice'" > "'$lastbuyprice'")}') ));
								   if (( $(echo "$averageprice > $lastbuyprice" | bc -l) ));  
                                   then
						           allowsell=1 #this is a allow sell switch
																	  
                                                                      
                                    else
                                    allowsell=0
									fi
																	                            else
																                                allowsell=1
																		                        #this allows a sell if stoploss is false and bought is 1
																		                        fi
																	 

 
 
 #this allows the first trade to be sell, regarding stoploss option
 if [ "$bought" = "1" ] && [ "$readingsnr" = "$rdg" ] ; then
 #echo i shoould not see this
 gainpercent=`echo "scale=3; 100 * ($averageprice - $lastbuyprice) / $lastbuyprice" | bc | sed -e 's/^-\./-0./' -e 's/^\./0./' `

 
 fi
 

 
                                                                                    if [ "$minimumprofitpercent" != "0" ] && [ "$bought" = "1" ] &&  [ "$readingsnr" = "$rdg" ]  ; then 
																				
                                              if (( $(echo "$averageprice >= $lastbuyprice" | bc -l) ));  
                                         # if (( $(awk 'BEGIN {print ("'$averageprice'" >= "'$lastbuyprice'")}') )); 
										  then
                                          #echo selling price is bigger than buy price, i am at this condition
										  if (( $(echo "$gainpercent >= $minimumprofitpercent" | bc -l) ));  then 
           #if (( $(awk 'BEGIN {print ("'$gainpercent'" >= "'$minimumprofitpercent'")}') )); then 
	
	       #echo minimumprofitpercent meets the requirement
	       allowsellminprofitswitch=1
           else
           allowsellminprofitswitch=0	
	       fi 
     				                        fi
					                                                                 else
                                                                                     allowsellminprofitswitch=1
					                                                                  fi
																					  
																					  
																					  
#maximum gain percent

 if [ "$bought" = "1" ] && [ "$readingsnr" = "$rdg" ] ; then
  if (( $(echo "$gainpercent > 0" | bc -l) )); 	then
 #echo i shoould not see this
 #highestgainpercent
                                                                            if [ "$gainpercentswich" = "1" ]   ; then 
																 if (( $(echo "$gainpercent > 0" | bc -l) )); 	then
                                                                  highestgainpercent=$gainpercent   
                                                                   gainpercentswich=0                                                                  
																  fi 
                                                                     fi         
																  
														                                                                          if (( $(echo "$gainpercent > $highestgainpercent" | bc -l) )); 	then
														                                                                          gainpercentswich=1
														                                                                            fi
																  
		#echo 	$highestgainpercent		is the maximum profit i could have made.											  
 fi    
                    fi                                                        
																					  
#########################################################################################FAILSAFE##################################################
#####this function ignores everything and sells all assets if liveprice drops x% bellow the buyprice
#####this must be changed, if does not working on first buy

 

																												 
																												 
																										
																												
if [ "$bought" = "1" ] && [ "$readingsnr" = "$rdg" ]  && [ "$failsafe" != "0" ] ; then 



loosepercent=`echo "scale=3; 100 * ($averageprice - $lastbuyprice) / $lastbuyprice " | bc | sed -e 's/^-\./-0./' -e 's/^\./0./' | tr --delete -`


if (( $(echo "$lastbuyprice > $averageprice" | bc -l) )); then
                                                   #this next line will fix any incorrect reading of the bot average price , because the bot sometimes does not read correctly the average price 
												   #marker
												   
												   errorfix=`echo "scale=3; 100 * ($liveprice - $averageprice) / $averageprice " | bc | sed -e 's/^-\./-0./' -e 's/^\./0./' | tr --delete -`
                                                  if (( $(echo "$errorfix < $readingerrorpercent" | bc -l) )); then #this wont allow any panic sell if the difference between averageprice and liveprice is to big
																
																              if (( $(echo "$loosepercent >= $failsafe" | bc -l) )); then
																			  echo $loosepercent is the loosepercent and $failsafe is the failsafe
																			  echo failsafe activating, selling everything, maybe a fall is coming, disable profitloss and minimumprofitpercent2?
																			  allowsell=1
																			  allowsellminprofitswitch=1																		
                                                                              sellcheckswitch=1
                                                                              sellcheck																			  
																			  panicnr=`expr $panicnr + 1`
																			  paniccounter=1
																			  aplay sounds/panic.wav
																			  oldbuypercent=$buypercent
																			  oldsellpercent=$sellpercent
																			  buypercent=$failsafebuypercent
																			  sellpercent=$failsafesellpercent
																			  echo "I've panic, because i've bought at $oldlastbuyprice the coin dropped until $liveprice, meaning a $loosepercent drop" >> $tradelog
																			  echo " loosepercent is :$loosepercent, current price is : $liveprice, smooth average price is : $averageprice, last buy price is $lastbuyprice,  failsafe is : $failsafe " >> $tradelog
										     if [ "$trade_type" = "live" ] && [ "send_mail" = "yes"] ;
		                                                                     then 
											                                echo Subject: Zenbot panic! > mail.txt
                                            echo " " >> mail.txt  
											echo " Prices are going down!" >> mail.txt 
                                            echo Liveprice - $liveprice  >> mail.txt 
                                            echo  Averageprice - $averageprice  >> mail.txt 
                                            echo Lastbuyprice - $lastbuyprice  >> mail.txt 
                                            ssmtp loren.bufanu@gmail.com < mail.txt
											 fi 
																			  
																			  
																			  fi
fi

					                                fi
																	


		fi
		
		
		if [ "$paniccounter" = "1" ] && [ "$bought" = "1" ] ;
                                                   then 
												   
												   buypercent=$oldbuypercent
												   sellpercent=$oldsellpercent
												   paniccounter=0
												   echo reseting buy and sell percent to default values
												   fi
												   
                                                       												   

###################################################################################failsafe function if we have no buy price==================================================================
		

			}


display () {
#this will be the main display function
printf "\033c"
                                                   if [ "$readingsnr" -lt "$rdg" ]; then   echo -ne "\n\n                                           \e[0m \e[0;32mPlease wait while the bot is taking \e[0m \e[1;31m$readingsnr/\e[0m \e[1;32m$rdg\e[0m \e[0;32m readings required for smoothing
							   \r"
							   fi
	echo Assets :
	
							   
							   
							   
							   
							   
							            echo -ne "\n                   
    \e[0m \e[1;34mcoin1                  \e[0m \e[1;36mcoin2              \e[0m \e[1;33mTotal Running Time:            \e[0m \e[0;35m Trades made:                \e[0m \e[1;31mLast buy price:         \e[0m \e[1;32mLast sell price:                            Panics sells:  
     \e[0m \e[1;34m$coin1main                     \e[0m \e[1;36m$coin2main                      \e[0m \e[1;33m$runtimecounter min                \e[0m \e[0;35m $tradesnr                       \e[0m \e[1;31m$lastbuyprice\e[1;37m                  \e[0m \e[1;32m$lastsellprice\e[1;37m                                        $panicnr Panics 
\e[0m \e[1;34mFree: $coin1mainfreeassets        \e[0m \e[1;36mFree:$coin2mainfreeassets
\e[0m \e[1;34mLocked: $coin1mainlockedassets     \e[0m \e[1;36m Locked:$coin2mainlockedassets
\e[0m \e[1;34m$coin1value USD       \e[0m \e[1;36m$coin2value USD        
														Prices:
	
	\e[1;31m Lowest price:    \e[0m \e[1;33mCurrent Price:   \e[1;32m Smooth Average Price:      \e[0m \e[0;31mHighest price 
         \e[1;31m$low       \e[0m \e[1;33m$liveprice         \e[1;32m$averageprice                  \e[0;31m$high 	
		                                   
	       \e[0m \e[1;33mSettings:                                                                  \e[0m \e[1;35mLow To Average%(buy at $buypercent%)     \e[0m \e[0;33mHigh to Average% (sell at $sellpercent%)       \e[0m \e[1;37mHighest to lowest percentage          Buy/Current Price (%)
		   
    \e[0m \e[0;37mBot update Seconds:        $binanceupdateseconds ***** \e[0m \e[1;37mSpike bottom lines removed:$spikebottom                                   \e[0m \e[1;35m $lowpercentage                          \e[0m \e[0;33m $highpercentage                               \e[0m \e[1;37m$lowtohighpercentage                            $gainpercent %
    \e[0m \e[1;35mBuy Percentage:            $buypercent ***** \e[0m \e[1;31mStop loss:                 $stoploss
    \e[0m \e[1;33mSell Percentage:           $sellpercent ***** \e[0m \e[1;32mMinimum profit sale:       $minimumprofitpercent %
    \e[0m \e[1;32mSmooth Readings:           $rdg ***** \e[0m \e[1;37mFailsafe sell % :          $failsafe %                                                  \e[0m \e[1;35m Manual Buy Key : B               \e[0m \e[0;33mManual Sell Key : S                
    \e[0m \e[1;33mSpike top line removed:    $spiketop 

                                                                                                                       \e[0m \e[0;37mTrade Type: \e[1;31m $trade_type \e[0m \e[0;37m
   \r"

	echo -ne " 	   \e[0m \e[1;37m"
}

function manualkeypress () {

# as the name states, this function handles the manual keypress function!

  read -t $binanceupdateseconds -rN 1  > /dev/null 2>&1
  if  [ "$REPLY" = "b" ] || [ "$REPLY" = "B" ] ; then 
               echo "B key was pressed! manually Buy! "
			   buyswitch=1
			   buycheckswitch=1
			   buycheck
fi	
 
 if  [ "$REPLY" = "s" ] || [ "$REPLY" = "S" ] ; then 
 echo "S key was pressed! manually Sell! "
    sellswitch=1
	sellcheckswitch=1
	sellcheck
 fi  
}




function simulate_loop () {
# this function will replace the loop function to simulate the prices of the coin!

while read -r line; do
    sim_price="$line"
echo $sim_price
#echo $sim_price is the sim price 
#manualkeypress

coinselect $coin
assets 



#echo this is the simulate function!
done < "$simulate_file"
display
}




####################################################################### LOOP #############################################################################################################################################
#this is the main loop for the bot
function loop () {

while :
do
manualkeypress
coinselect $coin
assets 

done
}
rootcheck
