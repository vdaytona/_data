#property copyright " "
#property link      "github.com/saturdayquant"
#property version   "1.00"

input int save_mod = 60,
          k_val    = 1440;

//http://www.myfxbook.com/forex-market/correlation
input string other_symbol = "EURAUD"; 

string SUBFOLDER = "Research/";
int filehandle;
float map_val, last_mapped = iClose(Symbol(), 0, 1); //attempt at eliminating zero division at first loop

//review usefulness of map_vals, -- find faster alternative.
float map_vals[10];

//+------------------------------------------------------------------+
int OnInit() {
    string FILENAME = "\\" + TimeToStr(TimeCurrent(), TIME_DATE) + ".csv";
    filehandle = FileOpen(SUBFOLDER + FILENAME, FILE_READ|FILE_WRITE|FILE_CSV); 
    return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason) {
    FileClose(filehandle);
}
//+------------------------------------------------------------------+
void OnTick() {
    if(TimeCurrent() % save_mod == 0) {
        string dt_str = TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS);
        string this_close = iClose(Symbol(), 0, 0);
        string other_close = iClose(other_symbol, 0, 0);
        
        float other_high = float(iHigh(other_symbol, 0, iHighest(other_symbol, 0, MODE_HIGH, k_val)));
        float other_low = float(iLow(other_symbol, 0, iLowest(other_symbol, 0, MODE_LOW, k_val)));
        
        Print("oH ",other_high);
        Print("oL ",other_low);
        
        float rangemap = float(iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, k_val)) - iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, k_val)))/
                         (other_high - other_low);
    
        //map to abs later
        //or no(?) negative vals only occur with zero divides, which should not happen. In case they do, investigate further.
        //zero division scenario: mt4 "intercepts" weekend quotes, assigning 0 to high and low simultaneously.
        map_val = iClose(other_symbol, 0, 0)*rangemap;
        
        
        
        //eliminate look-ahead bias by setting a baseline corresponding to real quote value.
        if()
        
        last_high = other_high;
        last_low = other_low;
        
        if(filehandle != INVALID_HANDLE) {
            FileSeek(filehandle, 0, SEEK_END); 
            FileWrite(filehandle, this_close, other_close, map_val);
            FileFlush(filehandle);
        }
    }
}