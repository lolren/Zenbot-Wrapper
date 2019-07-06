#this is a bridge between binance api and lpmbot. please write binance API details in here
#https://github.com/toshima/binance this is the link to the binance api i`m using
import binance
import sys 
binance.set("API", "SECRET")
# api first and then secret

if sys.argv[ 1 ] == ("prices"):
    print(binance.prices())
elif sys.argv[ 1 ] == ("balances"):
     
   print(binance.balances())
else:
    print ("Please write a valid argument")
	
	
	



