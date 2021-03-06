#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Global variables
//+------------------------------------------------------------------+
input int h_value = 20, //volatility bars amount
          h1_val = 10,
          k3_val, // --||--
          trade_dur = 5;
          
input double order_volume = 0.01,
             k1_val = 0.01,
             k2_val = 0.5, // (|||||----)
             sigma_max; //implementer h(?)
//init sequence
int OnInit()
{
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {}

void OnTick()
{
    double LL = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, h_value));
    double HH = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, h_value));
    double OpenPrice;
    double ClosePrice;
    double Threshold = k1_val*(HH-LL);
    int call_winctr,
        call_lossctr,
        put_winctr,
        put_lossctr;
    
    MqlTick mtick;
   
    if(Bars > h_value + 1) { // bars "rendered".
      if(OrdersTotal() == 0) { 
         if((iOpen(0,0,1) == iHigh(0,0,1)) && iLow(0,0,1)!=iHigh(0,0,1) &&
         /*
           (iOpen(0,0,0) <= (iHigh(0,0,0) + Threshold) || 
           (iHigh(0,0,0) - iOpen(0,0,0) <= Threshold))  && 
         */
           (((iHigh(0,0,1) - iClose(0,0,1))/(iHigh(0,0,1) - iLow(0,0,1))) <= k2_val )) //PUT
         {  
            OrderSend(Symbol(), OP_BUY, order_volume, Ask, 0,0,0 /*Bid+15*Point, Bid-15*Point*/); 
            OpenPrice = mtick.ask;
            return;  
         }
      }
   }
 //while !isOpen == true ??
   if(!OrderSelect(0, SELECT_BY_POS,MODE_TRADES))  //POTENTIAL CRASH CAUSE, finn måte å kjøre loopen på
      //continue;
   if(OrderSymbol() != Symbol())
      //continue;
   RefreshRates();
    //if((&& Symbol() == NULL 
    //&& ((OrderType() == OP_SELL) || (OrderType() == OP_BUY))) 
      if(TimeCurrent() - OrderOpenTime() >= trade_dur*60) {

      if(OrderType() == OP_SELL) {
         OrderClose(OrderTicket(),OrderLots(),Ask, 0,clrWhite);
         ClosePrice = mtick.ask;
         if(ClosePrice < OpenPrice) put_winctr++;
         else put_lossctr++;
      }
      
      if(OrderType() == OP_BUY) {
         OrderClose(OrderTicket(), OrderLots(), Bid, 0, clrWhite);
         ClosePrice = mtick.ask;
         if(ClosePrice > OpenPrice) call_winctr++;
         else call_lossctr++;
         }
        
   }
}
//+------------------------------------------------------------------+
/*
bool conditionCheckShort (double k2_val = 0.5, 
                          double Threshold)
{                     
   if((iOpen(0,0,0) <= (iHigh(0,0,0) + Threshold) && 
      (iHigh(0,0,0) - iOpen(0,0,0) <= Threshold) &&
    (((iHigh(0,0,0) - iClose(0,0,0))/(iHigh(0,0,0) - iLow(0,0,0))) <= k2_val))) 
    // insert σ check, sigma_max parameter ^
    {
      return true;
    }
}
*/

       /*(iOpen(Symbol(),0,1) <= (iHigh(0,0,1) + Threshold1) || 
         (iHigh(0,0,1) - iOpen(0,0,1) <= Threshold1)) &&*/
   //v0
   /*
   if(!OrderSelect(0, SELECT_BY_POS,MODE_TRADES))  //POTENTIAL CRASH CAUSE, finn måte å kjøre loopen på
      //continue;
   if(OrderSymbol() != Symbol())
      //continue;
   RefreshRates();
    //if((&& Symbol() == NULL 
    //&& ((OrderType() == OP_SELL) || (OrderType() == OP_BUY))) 
      if(TimeCurrent() - OrderOpenTime() >= trade_dur*60) {

      if(OrderType() == OP_SELL) {
         OrderClose(OrderTicket(),OrderLots(),Ask, 0,clrWhite);
      }
      
      if(OrderType() == OP_BUY) {
         OrderClose(OrderTicket(), OrderLots(), Bid, 0, clrWhite);
      }
        
   }
*/
   //*/
   //v1
      /*
      if(TimeCurrent() - OrderOpenTime() >= trade_dur*60) {
         if(OrderType() == OP_SELL) {
            ans = OrderClose(ticket, OrderLots(), Ask, 0, clrWhite); //normalize order volume, do not use normalizedouble(?)
          //if(ans == true) break;
          //ClosePrice = mtick.ask;
            if(ClosePrice < OpenPrice) put_winctr++;
            else put_lossctr++;
         }
       //else Alert("Wrong order type.");
         if(OrderType() == OP_BUY) {
            ans = OrderClose(ticket, OrderLots(), Bid, 0, clrWhite); 
          //if(ans == true) break;
          //ClosePrice = mtick.ask;
            if(ClosePrice > OpenPrice) call_winctr++;
            else call_lossctr++;
         }
      }*/