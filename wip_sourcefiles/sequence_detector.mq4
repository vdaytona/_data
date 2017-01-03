#property copyright "blablabla"
#property link      "https://www.reddit.com/r/algoshitting"
#property version   "1.001"
//
input int    h_value      = 70,
             trade_dur    =  5,
             sigma_calc   =  7,     // +1
             seq_limit    =  4;     //4/7
          
input double order_volume =  0.01,
             k1_val       =  0.01,
             k2_val       =  0.5,   //andel
             sigma_th     =  0.5;
             //sigma_th1    =  0.4,
             //bear_threshold =0.05;
              
input bool   toggle_candles       = true, //brytere i if-op
             toggle_doji_marubozu = true,
             toggle_sstar         = true,
             toggle_hman          = true; 
                
int OnInit() { return(INIT_SUCCEEDED); }
//
void OnDeinit(const int reason) { }
//
void OnTick()
{
   double LL = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, h_value));
   double HH = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, h_value));
   double threshold = k1_val * (HH-LL);
   double sigma_max = HH-LL * sigma_th;
   int ticket, slippage; //slippage optimalt 0
   
 //double order_volume = AccountBalance()/20000;
   
   if(Bars > h_value + 1) { 
     if(OrdersTotal() == 0) { 
        if(//(isSStar() ||
           //isHangman() &&
           //isDowntrend(HH, LL) &&
           //sequenceCheckShort(sigma_max) 
           probablyTZ()) 
        {  
            ticket = OrderSend(Symbol(), OP_SELL, order_volume, Bid, 0,0,0);
          //ticket = OrderSend(Symbol(), OP_BUY, order_volume, Ask, 0,0,0);
            Print(ticket);
            return;
        }
      }
   }
   
   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--) { 
      if (OrderSelect(pos, SELECT_BY_POS) /*&&
          OrderMagicNumber() == Magic.Number*/ &&
          OrderSymbol()      == Symbol() )
      {  
         int duration = TimeCurrent() - OrderOpenTime();
         if (duration >= trade_dur * 60)
            if(!OrderClose( OrderTicket(), OrderLots(), OrderClosePrice(), slippage))
               Print("Order close error. -", GetLastError());
      }
   }
} 
//+------------------------------------------------------------------+

bool sequenceCheckShort (float sigmax)
{
   int sequence_ctr;
   if(iClose(Symbol(), 0, 2) - iOpen(Symbol(), 0, 2) > 0) {
      for(int i = sigma_calc; i > 1; i--) {
         if(iOpen(Symbol(), 0, i+1) <= iOpen(Symbol(), 0, i) && 
           (iClose(Symbol(), 0, i) - iOpen(Symbol(), 0, i) < sigmax)) {
               sequence_ctr++;
         }
         if(iOpen(Symbol(), 0, i+1) - iClose(Symbol(), 0, i+1) > sigmax && 
            iOpen(Symbol(), 0, i+1) > iClose(Symbol(), 0, i+1))
            return false;
      }
   }
   if(sequence_ctr > seq_limit)  //4/7
      return true;
   else return false;
}

bool isHangman ()
{ 
   if((iOpen(Symbol(),0,1) == iHigh(Symbol(),0,1)) && 
       iOpen(Symbol(),0,1) > iClose(Symbol(),0,1)  &&
    (((iHigh(Symbol(),0,1) - iClose(Symbol(),0,1)) / 
      (iHigh(Symbol(),0,1)  -  iLow(Symbol(),0,1))) <= k2_val)) 
      return true;
   else return false;
}

bool isSStar ()
{
   if((iClose(Symbol(),0,1) == iLow(Symbol(),0,1)) && 
       iOpen(Symbol(),0,1) > iClose(Symbol(),0,1)  &&
    (((iOpen(Symbol(),0,1) - iClose(Symbol(),0,1)) / 
      (iHigh(Symbol(),0,1)  -  iLow(Symbol(),0,1))) <= k2_val)) 
      return true;
   else return false;
}             

bool isDowntrend (float HH1, 
                  float LL1
                  /*int h_value*/)
{
   if(iHighest(Symbol(), 0, MODE_HIGH, h_value) < iLowest(Symbol(), 0, MODE_LOW, h_value)) //&&
      //iClose(Symbol(), 0, 1) < (HH1 - bear_threshold*(HH1-LL1)))
      return true;
   else return false;
   //legg til en ikke-ranging test
   //simpel regresjon av n punkter H eller L med små h-verdier
}

bool probablyTZ()
{
   if((iHighest(Symbol(), 0, MODE_HIGH, h_value) == 1) &&
       (iClose(Symbol(), 0, 1) > iClose(Symbol(), 0, 2)))
      return true;
}