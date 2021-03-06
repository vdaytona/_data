#property copyright "saturday"
#property link      "https://www.reddit.com/r/algoshitting"
#property version   "1.0"
//
input datatype

//global variables

int OnInit() { 
   //init sequence
   return(INIT_SUCCEEDED); 
}
//
void OnDeinit(const int reason) { 
   //testing log append, husk å bytt filnavn for hver backtest.
   /*
   string terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);  
   string subfolder="Research";
   int filehandle = FileOpen(subfolder+"\\cd_USDJPY_.csv",FILE_READ|FILE_WRITE|FILE_CSV);
   if(filehandle!=INVALID_HANDLE) {
      FileSeek(filehandle,0,SEEK_END); 
      FileWrite(filehandle, param );
      FileFlush(filehandle);
      FileClose(filehandle);
   }
   */
}

void OnTick()
{
   calculate_current_orders(0); //temporarily only short orders
   open_check( ); 
   close_check( );
   
   if(testmode && c_delta != c_delta_old) {
         
         string terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);  
         string subfolder="Research";
         int filehandle = FileOpen(subfolder+"\\filename.csv",FILE_READ|FILE_WRITE|FILE_CSV);
         if(filehandle != INVALID_HANDLE) {
            FileSeek(filehandle, 0, SEEK_END); 
            FileWrite(filehandle, c_delta);
            FileFlush(filehandle);
            FileClose(filehandle);
         }
         int filehandle_time = FileOpen(subfolder+"\\filename_2.csv",FILE_READ|FILE_WRITE|FILE_CSV);
         if(filehandle_time != INVALID_HANDLE) {
            FileSeek(filehandle_time, 0, SEEK_END); 
            FileWrite(filehandle_time, TimeCurrent());
            FileFlush(filehandle_time);
            FileClose(filehandle_time);
         }   
   }
   c_delta_old = c_delta;
}
   
void open_check (double diffEURUSDATR)
{
   int ticket;
   if(OrdersTotal() == 0) {
      if() { 
        ticket = OrderSend(Symbol(), OP_SELL, order_volume, Bid, 0,0,0);
       //ticket = OrderSend(Symbol(), OP_BUY, order_volume, Ask, 0,0,0);
       return;
      }
   }
}
int calculate_current_orders(string symbol)
{
   int long_ctr, short_ctr;
//---
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
      {
         if(OrderType()==OP_BUY)  long_ctr++; //evt.
         if(OrderType()==OP_SELL) short_ctr++;//evt.
      }
   }
//--- return orders volume (?)
   if(long_ctr>0) return(long_ctr);
   else return(-short_ctr);
}
void close_check (double EJ_synth)
{
   if(Volume[0] > 1) return;

   if(/*close_condition*/) {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
         }
  /* for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      */
     
      //--- check order type 
      
      /*
      if(OrderType()==OP_BUY)
      {
         if(Open[1]>ma && Close[1]<ma)
         {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
         }
         break;
      }
      */
     /*
      if(OrderType() == OP_SELL )
      {
         
         if((iClose(0, 0, 1) <= EJ_synth) || (OrderOpenPrice()-Ask >= pip_tp)) {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
         }
         break;
      }
      */
   }

/*
         if(error_cond)
         {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
         }
         */
/*  
double LotsOptimized()
{
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calculate number of losses orders without a break
   if(DecreaseFactor>0)
   {
      for(int i=orders-1;i>=0;i--)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
         {
            Print("Error in history!");
            break;
         }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
      }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
   }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
}
*/