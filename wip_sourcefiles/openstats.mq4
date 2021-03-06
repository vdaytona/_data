#property copyright "blablabla"
#property link      "https://www.reddit.com/r/algoshitting"
#property version   "1.001"
//
input int    h_value      = 70,
             h1_val       = 10,
             k3_val, 
             trade_dur    =  5,
             sigma_calc   =  7,     // +1
             seq_limit    =  4;     //4/7
          
input double order_volume =  0.01,
             k1_val       =  0.01,
             k2_val       =  0.5,   //andel
             sigma_th     =  0.5,
             bear_threshold =0.05;
              
input bool   toggle_candles = true, //brytere i if-op
             toggle_doji_marubozu = true,
             toggle_sstar   = true,
             toggle_hman    = true; 
                
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
   
   if(Bars > h_value + 1) { 
     if(OrdersTotal() == 0) { 
        if((isSStar(k2_val, threshold, sigma_calc, sigma_max) ||
           isHangman(k2_val, threshold, sigma_calc, sigma_max)) &&
           isDowntrend(HH, LL) &&
           sequenceCheckShort(seq_limit, sigma_max, sigma_calc)) 
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

bool sequenceCheckShort (int sequence_limit1,
                         double sigma_max1,
                         double sigma_calc1)
{
   int sequence_ctr;
   if(iClose(Symbol(), 0, 2) - iOpen(Symbol(), 0, 2) > 0) {
      for(int i = sigma_calc1; i > 1; i--) {
         if(iOpen(Symbol(), 0, i+1) <= iOpen(Symbol(), 0, i) && 
           (iClose(Symbol(), 0, i) - iOpen(Symbol(), 0, i) < sigma_max1)) {
               sequence_ctr++;
         }
      }
   }
   if(sequence_ctr > sequence_limit1)  //4/7
      return true;
   else return false;
}

bool isHangman (double k2_val1, 
                double Threshold1,
                double sigma_calc1,
                double sigma_max1)
{ 
   if((iOpen(Symbol(),0,1) == iHigh(Symbol(),0,1)) && 
       iOpen(Symbol(),0,1) > iClose(Symbol(),0,1)  &&
    (((iHigh(Symbol(),0,1) - iClose(Symbol(),0,1)) / 
      (iHigh(Symbol(),0,1)  -  iLow(Symbol(),0,1))) <= k2_val1)) 
      return true;
}

bool isSStar (double k2_val1, 
              double Threshold1,
              double sigma_calc1,
              double sigma_max1)
{
   if((iClose(Symbol(),0,1) == iLow(Symbol(),0,1)) && 
       iOpen(Symbol(),0,1) > iClose(Symbol(),0,1)  &&
    (((iOpen(Symbol(),0,1) - iClose(Symbol(),0,1)) / 
      (iHigh(Symbol(),0,1)  -  iLow(Symbol(),0,1))) <= k2_val1)) 
      return true;
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


/*
bool conditionCheckLong (double k2_val1, 
                         double Threshold1,
                         double sigma_calc1,
                         double sigma_max1)
{  
   if(iOpen(Symbol(), 0, sigma_calc1) <= iClose(Symbol(),0,sigma_calc1) && 
     (iOpen(Symbol(), 0, sigma_calc1) - iOpen(Symbol(), 0, 1)) > 0) {
                       
      if((iOpen(Symbol(),0,1) == iHigh(Symbol(),0,1)) && 
          iOpen(Symbol(),0,1) < iClose(Symbol(),0,1)  &&
       (((iHigh(Symbol(),0,1) -  iOpen(Symbol(),0,1)) / 
         (iHigh(Symbol(),0,1)  -  iLow(Symbol(),0,1))) <= k2_val1)) 
         return true;
         else return false;
   }
   else return false;
}
*/
//kan sequence_check kalles inn i annen ekstern bool func?
//set conditionCheckLong on hold, fix order error + conditions conflicts

//v5.5
   /*while(OrdersTotal() == 1) {
      if(OrderCloseTime >= OrderOpenTime()+trade_dur*60) { //feilen
         OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
         if(OrderType() == OP_SELL)
            OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), slippage, clrRed);
         else OrderDelete(OrderTicket());
      }
   }*/

/* 
   while(OrdersTotal() == 1) {
      if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) 
         Print("FUCK THIS SHIT");
      if(!OrderClose(ticket, order_volume, OrderClosePrice(), 0, clrWhite))
               Print("crazy shit wtf");*/
   //v5
      /*if((TimeCurrent() - OrderOpenTime() >= trade_dur*60) && 
          OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
         Print("oh shit waddup");
         if(OrderSymbol() == Symbol() &&  
            OrderType() == OP_SELL ) { 
            if(!OrderClose(ticket, order_volume, OrderClosePrice(), 0, clrWhite))
               Print("crazy shit wtf");
         }
      }
   }
}
   //v4
   /*
   for(int i = OrdersTotal()-1; i >= 1; i--) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol() != Symbol()) 
            RefreshRates();
      }
   }
      if((TimeCurrent() - OrderOpenTime() >= trade_dur*60) && OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
      
         if(OrderSymbol() == Symbol() &&  
            OrderType() == OP_SELL )) 
         { 
            (OrderClose(ticket, order_volume, OrderClosePrice(), 0, clrWhite));
            //if (!OrderClose(ticket, order_volume, OrderClosePrice(), 0, clrWhite))
              // Print("Order Close failed, order number: ", ticket, " Error: ", GetLastError() ); 
         }
      }
   //}
   */

   //v3
   /*
   for(int i = OrdersTotal()-1; i >= 1; i--) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol() != Symbol()) 
            RefreshRates();
      }
   }
      if((TimeCurrent() - OrderOpenTime() >= trade_dur*60)) {
         if(OrderSymbol() == Symbol() &&        // <-- does the Order's Symbol match the Symbol our EA is working on ?     
            OrderType() == OP_SELL )) 
         { 
            (OrderClose(ticket, order_volume, OrderClosePrice(), 0, clrWhite));
            //if (!OrderClose(ticket, order_volume, OrderClosePrice(), 0, clrWhite))
              // Print("Order Close failed, order number: ", ticket, " Error: ", GetLastError() ); 
         }
      }
   //}
   */