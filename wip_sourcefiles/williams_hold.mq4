#property copyright "blablabla"
#property link      "https://www.forexmemery.com"
#property version   "1.0"
//
input int    h1_value     = 24,
             h_williamsS  = 10,
             h_williamsL  = 10,
             //trade_dur    =  5,
             williams_thresholdS = -2,
             williams_thresholdL = -86;
          
input double order_volume  = 0.01,
             broker_payout = 0.75,
             stake         = 100.0,
             order_stoploss= 1000.0, 
             order_tp      = 1000.0;

input bool testmode = false;

int put_winctr, put_lossctr, temp_tick, 
    lossctr_old, winctr_old, drawctr_old, put_drawctr;
double temprate, payout;
//datetime temptime;
              
int OnInit() { 
   
   return(INIT_SUCCEEDED); 
}
//
void OnDeinit(const int reason) { 
   //testing log append, husk å bytt filnavn for hver backtest.
   /*
   if(put_winctr + put_lossctr > 0) {
      double winrate = double(put_winctr)/((double)put_winctr+(double)put_lossctr);
   }
   else winrate = 0.0;
   string terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);  
   string subfolder="Research";
   int filehandle = FileOpen(subfolder+"\\long_seq_so_0711.csv",FILE_READ|FILE_WRITE|FILE_CSV);
   if(filehandle!=INVALID_HANDLE) {
      FileSeek(filehandle,0,SEEK_END); 
      FileWrite(filehandle, winrate );
      FileFlush(filehandle);
      FileClose(filehandle);
   }
   
   Print("wins: ", put_winctr);
   Print("losses: ", put_lossctr);
   Print("draws: ", put_drawctr);
   */
}

void OnTick()
{
   double HH_1 = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, h1_value));
   double LL_1 = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, h1_value));
   int ticket, order_slippage, mode;
   lossctr_old = put_lossctr;
   winctr_old = put_winctr;
   double order_tp_, order_stoploss_;
   
   if(Bars > h_williamsL + h_williamsS + 1) { 
     if(OrdersTotal() == 0) { 
        if( /*williams(0)*/newLow(LL_1) ) 
         {  
            order_tp_ = Bid - order_tp;
            order_stoploss_ = Bid + order_stoploss;
            ticket = OrderSend(Symbol(), OP_SELL, order_volume, Bid, 0, 0, 0);
            //ticket = OrderSend(Symbol(), OP_SELL, order_volume, Bid, order_slippage, Bid + order_stoploss, Bid - order_tp);
            //if(ticket > 0) temprate = Bid;
            //n_trades ++;
          //ticket = OrderSend(Symbol(), OP_BUY, order_volume, Ask, 0,0,0);
            mode = 1;
            
            return;
         }
         /*
         else if( williams(1) ) 
         {  
          //ticket = OrderSend(Symbol(), OP_SELL, order_volume, Bid, 0,0,0);
            ticket = OrderSend(Symbol(), OP_BUY, order_volume, Ask, order_slippage, Ask - order_stoploss, Ask + order_tp);
            //if(ticket > 0) temprate = Bid;
            mode = 0;
            return;
         }
         */
      }
      
   }
      
   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--) { 
      if (OrderSelect(pos, SELECT_BY_POS) &&
          OrderSymbol()      == Symbol() )
      {  
         //int duration = TimeCurrent() - OrderOpenTime();
         if ( /*williams(mode) || */(Bid <= order_tp_ || Bid >= order_stoploss_) ) {
            if(!OrderClose( OrderTicket(), OrderLots(), OrderClosePrice(), order_slippage))
               Print("Order close error. -", GetLastError());
            //
            if(temprate < OrderClosePrice()) put_lossctr++;
            else if(temprate == OrderClosePrice()) put_drawctr++;
            else put_winctr++;
            //
         }
      }
   }
   if(testmode) {
      if(winctr_old < put_winctr || lossctr_old < put_lossctr || drawctr_old < put_drawctr) {
         payout += 0;
         if(winctr_old != put_winctr) {
            payout += broker_payout*stake;
         }
         else if(lossctr_old != put_lossctr) {
            payout -= stake;
         }
         
         string terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);  
         string subfolder="Research";
         int filehandle = FileOpen(subfolder+"\\log0711_8_fæffæmode.csv",FILE_READ|FILE_WRITE|FILE_CSV);
         if(filehandle != INVALID_HANDLE) {
            FileSeek(filehandle, 0, SEEK_END); 
            FileWrite(filehandle, payout);
            FileFlush(filehandle);
            FileClose(filehandle);
         }   
      }
   }
   
   lossctr_old = put_lossctr;
   winctr_old = put_winctr;
   drawctr_old = put_drawctr;
}

/*
bool probablyTZ (int mode)
{
   switch(mode) {
      case 0:
         if((iHighest(Symbol(), 0, MODE_HIGH, h1_value) == 1) &&
            (iClose(Symbol(), 0, 1) > iClose(Symbol(), 0, 2)))
            return true;
         break;
      case 1:
         if((iLowest(Symbol(), 0, MODE_LOW, h2_value) == 1) &&
            (iClose(Symbol(), 0, 1) < iClose(Symbol(), 0, 2)))
            return true;
      break;
      default:
         Print("Invalid mode");
         break;
   }
}   

bool isTrending (float HH1, 
                 float LL1,
                 int mode)
{
   switch(mode) {
      case 0:
         if(iHighest(Symbol(), 0, MODE_HIGH, h1_value) < iLowest(Symbol(), 0, MODE_LOW, h1_value)) //&&
         //iClose(Symbol(), 0, 1) < (HH1 - bear_threshold*(HH1-LL1)))
            return true;
         else return false;
       break;
       case 1:
         if(iHighest(Symbol(), 0, MODE_HIGH, h2_value) > iLowest(Symbol(), 0, MODE_LOW, h2_value)) //&&
         //iClose(Symbol(), 0, 1) < (HH1 - bear_threshold*(HH1-LL1)))
            return true;
         else return false;
       break;
       default:
         Print("Invalid mode.");
         break;     
   }
}
*/
     
bool williams (int mode)
{
   switch(mode) {
      case 0:
         if(iWPR(Symbol(), 0, h_williamsS, 1) > williams_thresholdS)
            return true;
         else return false;
         break;
      case 1:
         if(iWPR(Symbol(), 0, h_williamsL, 1) < williams_thresholdL)
            return true;
         else return false;
         break;
   }
}

bool newLow (double LL) 
{   
   if(LL >= iClose(Symbol(), 0, 1)) return true;
}