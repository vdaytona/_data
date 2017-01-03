#property copyright "blablabla"
#property link      "https://www.reddit.com/r/algoshitting"
#property version   "1.01"
//
input int    h1_value     = 24,
             h2_value     = 5, 
             trade_dur    =  5,
             //n_avg      = 10,
             //n_periods  = 3,
             h_williamsS  = 55,
             h_williamsL  = 15,
             //h_momentum   = 10,
             //momentum_diff= 1,
             //momentum_max = 3,
             h_rsi        = 10,
             rsi_shift    = 1,
             williams_thresholdS = -2,
             williams_thresholdL = -86;
             
          
input double order_volume =  0.01,
             //kShort       =  0.45,
             //kLong        =  0.45,
             //corr_threshold = 0.66,
             broker_payout = 0.75,
             stake         = 100.0;

input bool testmode = true;

int put_winctr, put_lossctr, tick_events, temp_tick, 
    lossctr_old, winctr_old, drawctr_old, put_drawctr, n_trades;
double temprate, payout; 
//datetime temptime;
              
int OnInit() { 
   
   return(INIT_SUCCEEDED); 
}
//
void OnDeinit(const int reason) { 
   //testing log append, husk å bytt filnavn for hver backtest.
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
}

void OnTick()
{
   double HH_1 = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, h1_value));
   double LL_1 = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, h1_value));
   double HH_2 = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, h2_value));
   double LL_2 = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, h2_value));
   int ticket, slippage;
   lossctr_old = put_lossctr;
   winctr_old = put_winctr;
   
   if(Bars > h1_value + h2_value + 1) { 
     if(OrdersTotal() == 0) { 
        if( probablyTZ(0) && 
            isTrending(HH_1, LL_1, 0) && //&&
            williams(0) //&&
            //RSI(0)
           // momentumTest(0)
            ) 
         {  
            ticket = OrderSend(Symbol(), OP_SELL, order_volume, Bid, 0,0,0);
            if(ticket > 0) temprate = Bid;
            n_trades ++;
          //ticket = OrderSend(Symbol(), OP_BUY, order_volume, Ask, 0,0,0);
            return;
         }
       /*
         else if( probablyTZ(1) && 
             isTrending(HH_1, LL_1, 1) &&
             williams(1) ) 
         {  
          //ticket = OrderSend(Symbol(), OP_SELL, order_volume, Bid, 0,0,0);
            ticket = OrderSend(Symbol(), OP_BUY, order_volume, Ask, 0,0,0);
            //if(ticket > 0) temprate = Bid;
            return;
         }
         */
      }
      
   }
   
   
   
   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--) { 
      if (OrderSelect(pos, SELECT_BY_POS) /*&&
          OrderMagicNumber() == Magic.Number*/ &&
          OrderSymbol()      == Symbol() )
      {  
         int duration = TimeCurrent() - OrderOpenTime();
         if (duration >= trade_dur * 60) {
            if(!OrderClose( OrderTicket(), OrderLots(), OrderClosePrice(), slippage))
               Print("Order close error. -", GetLastError());
            if(temprate < OrderClosePrice()) put_lossctr++;
            else if(temprate == OrderClosePrice()) put_drawctr++;
            else put_winctr++;
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
bool RSI (int mode) 
{
   switch(mode) {
      case 0: 
         if(iRSI(Symbol(), 0, h_rsi, PRICE_HIGH, rsi_shift)) 
            return true;
         break;
      case 1:
         if(iRSI(Symbol(), 0, h_rsi, PRICE_LOW, rsi_shift)) 
            return true;
         break;
      default:
         Print("Invalid mode.");
         break;
   }
}
/*
bool momentumTest (int mode)
{
   switch(mode) {
      case 0:
         if(iMomentum(Symbol(), 0, h_momentum, PRICE_OPEN, 0) < 100) {
            int momentum_min;
            for(int i; i <= h_momentum; i++) {
               if(iClose(Symbol(), 0, i) < iClose(Symbol(), 0, i+1))
                  momentum_min++;
            }
         }
      case 1:
         if(iMomentum(Symbol(), 0, h_momentum, PRICE_OPEN, 0) > 100) {
            momentum_min = 0;
            for(i = 0; i <= h_momentum; i++) {
               if(iClose(Symbol(), 0, i) > iClose(Symbol(), 0, i+1))
                  momentum_min++;
            }
         }
      if(momentum_min >= momentum_max - momentum_diff)
         return true;
      else return false;
   }
}*/

/*
bool breakoutShort(float HH1, float LL1) 
{
   if((iClose(Symbol(), 0, 1) - iOpen(Symbol(), 0, 1)) > (HH1-LL1)*kShort)
      return true;
}
bool breakoutLong(float HH1, float LL1) 
{
   if(iClose(Symbol(), 0, 1) < iClose(Symbol(), 0, 2) - (HH1-LL1)*kLong)
      return true;
}
*/
/*
bool williamsShort () 
{
   if(iWPR(Symbol(), 0, h_williamsS, 1) > williams_thresholdS)
      return true;
   else return false;
}

bool williamsLong () 
{
   if(iWPR(Symbol(), 0, h_williamsL, 1) < williams_thresholdL)
      return true;
   else return false;
}
*/
/*
bool extremal_regression (
                          double HH_11, 
                          double LL_11,
                          double HH_21,
                          double LL_21)
{  
   
   double HH1_arr[], LL1_arr[],
          HH2_arr[], LL2_arr[];
          
   ArraySetAsSeries(HH1_arr[]);
   ArraySetAsSeries(HH2_arr[]);
   ArraySetAsSeries(LL1_arr[]);
   ArraySetAsSeries(LL2_arr[]);
          
   for(int x; x<(h1_value + h2_value)*n_periods; x++) {
      if(iHighest(Symbol(), 0, MODE_HIGH, h))
   }
   for(int i; i<=n_periods; i++){
      while(i == 1) HH1_arr[i] = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, i*h1_value);
      if(iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value) > HH1_arr[i+1];
   }
   
   double HH3 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h2_value*3));
   double HH2 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h2_value*2));
   double HH1 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h2_value));
   
   if(HH3 > HH2 && HH2 > HH1) return true;
   /*
   if( (HH1 > HH2 && HH2 > HH3) &&
       (HH1 != HH2 && HH2 != HH3) ) {
      if( ((HH2-HH3)/
        (iHighest(Symbol(), 0, MODE_HIGH, h1_value*2) -
         iHighest(Symbol(), 0, MODE_HIGH, h1_value*3))) /
         ((HH1-HH2)/
        (iHighest(Symbol(), 0, MODE_HIGH, h1_value*1) -
         iHighest(Symbol(), 0, MODE_HIGH, h1_value*2))) < corr_threshold ) {
         return true;
         }
      else return false;
   }
   
}
*/
 /* if(iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value)) > iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*2)) &&
      iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*2))> iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*3) {
      
      if((((iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*2)) - 
          iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*3)))  /
         (iHighest(Symbol(), 0, MODE_HIGH, h1_value*2) -
          iHighest(Symbol(), 0, MODE_HIGH, h1_value*3))) /
          
         ((iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value)) - 
          iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*2))) /
         (iHighest(Symbol(), 0, MODE_HIGH, h1_value) -
          iHighest(Symbol(), 0, MODE_HIGH, h1_value*2)))) < corr_threshold1) {
         return true;
      }
      else return false;
         //usikker på om dette funker best long eller short...
   }*/
