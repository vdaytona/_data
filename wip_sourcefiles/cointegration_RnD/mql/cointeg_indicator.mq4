#property copyright   "Saturday"
#property link        "www.github.com/saturdayquant"
#property description "Moving Ratio"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 clrRosyBrown
#property indicator_color2 clrRoyalBlue
#property indicator_minimum -1.1
#property indicator_maximum 1.1
#property indicator_level1 0.0
#property indicator_level2 1.0
#property indicator_levelstyle STYLE_DOT

//--- indicator parameters
input int period   = 200,   // Period
          ma_shift = 0,    // Shift
          max_bars = 1000;
          
input string other_symbol = "EURCAD";

//--- indicator buffer
double extLineBuffer[];
double extLineBuffer_2[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
{
    int draw_begin = period - 1;
    
    //--- indicator short name
    IndicatorShortName("SMR("+string(period)+")");
    IndicatorDigits(Digits);
   
    //--- check for input
    if(period <= 1)
        return(INIT_FAILED);
        
    //--- drawing settings
    SetIndexStyle(0, DRAW_LINE);
    SetIndexStyle(1, DRAW_LINE);
    SetIndexShift(0, ma_shift);
    SetIndexShift(1, ma_shift);
    SetIndexLabel(0, string(Symbol()));
    SetIndexLabel(1, other_symbol);
    SetIndexDrawBegin(0, draw_begin);
    SetIndexDrawBegin(1, draw_begin);
    
    //--- indicator buffers mapping
    SetIndexBuffer(0, extLineBuffer);
    SetIndexBuffer(1, extLineBuffer_2);
   
    //--- initialization done
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|  Moving Ratio                                               |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    //--- check for bars count
    if(rates_total < period - 1 || period < 2)
        return(0);
        
    //--- counting from 0 to rates_total
    ArraySetAsSeries(extLineBuffer, false);
    ArraySetAsSeries(extLineBuffer_2, false);
    ArraySetAsSeries(close, false);
    
    //--- first calculation or number of bars was changed
    if(prev_calculated == 0)
        ArrayInitialize(extLineBuffer, 0);
        ArrayInitialize(extLineBuffer_2, 1);
        
    //--- calculation
    calculateRA(rates_total, prev_calculated, close);
    //--- return value of prev_calculated for next call
    return(rates_total);
}

//+------------------------------------------------------------------+
void calculateRA(int rates_total,
                 int prev_calculated, 
                 const double &price[])
{
    int i=0, limit;
    //--- first calculation or number of bars was changed
    if(prev_calculated == 0) {
        limit = period;
        //--- calculate first visible value, useless with no recursion
        double firstValue = 0;
        for(i=0; i < limit; i++)
            firstValue += price[i];
        firstValue /= period;
        extLineBuffer[limit-1] = firstValue;
        //extLineBuffer_2[limit-1] = firstValue;
    }
    else
        limit = prev_calculated - 1;
     
    double other_close, this_high, other_high, this_low, other_low;
    
    //--- main loop
    for(i = limit; i < rates_total+max_bars && !IsStopped(); i++) {
    
        double this_close = iClose(Symbol(), 0, i);
        other_close = iClose(other_symbol, 0, i);
        //if(this_close == other_close) other_close = this_close + 0.0001; //?
        
        this_high = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, period, i));
        other_high = iHigh(other_symbol, 0, iHighest(other_symbol, 0, MODE_HIGH, period, i));
        
        this_low = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, period, i));
        other_low = iLow(other_symbol, 0, iLowest(other_symbol, 0, MODE_LOW, period, i));
        
        double ddd = (other_close - other_low)/(other_high - other_low);//*(this_high - this_low) + this_low;
        extLineBuffer[i] = MathAbs((this_close - this_low)/(this_high - this_low) - ddd);
        extLineBuffer_2[i] = (this_close - this_low)/(this_high - this_low) - ddd;
        //if(other_low == 0) other_low = 1;        
        //double this_ratio = (this_close - this_low)/(this_high - this_low);
        //double other_ratio = (other_close - other_low)/(other_high - other_low);    
    }
}
