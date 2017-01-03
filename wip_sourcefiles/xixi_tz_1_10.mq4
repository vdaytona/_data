//+------------------------------------------------------------------+
//|                                                      xixi_tz.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
// Fixed: 
// * Zones are cut at weekend bars 
// * drawing weired vertical lines
// * repeat dumping error messages
// New features:
// * bars limit 
// * on/off stats
//+------------------------------------------------------------------+

#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

#property indicator_buffers 3
//---- plot Line

//--- indicator parameters
input int   bars_limit = 1000; 
input bool  uneven_tz = false; 
input bool  show_stats = true; 
input bool  do_alert = false; 
input bool  show_remain_ptz_bars_num = false; 
input color remain_ptz_bars_num_color = clrAqua; 
input int   h_value = 10;
input color tz_left_clr = clrYellow;
input color tz_right_clr = clrRed; 
input color ptz_clr = clrTan;   // potential transient zone color 
input int   stats_pos_x = 10;
input int   stats_pos_y = 15; 
input color stats_color = clrWhite; 


//--- global variables 
int total_tz, total_ptz, total_htz, total_mtz, total_ltz, total_bars;


//--- indicator buffers
//--- TZ buffer: 0 - not a TZ, 1 - confirmed TZ, 2 - potential TZ 
double HTZBuffer[];
double LTZBuffer[];
double MTZBuffer[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,HTZBuffer);
   SetIndexBuffer(1,LTZBuffer);
   SetIndexBuffer(2,MTZBuffer);
   
   SetIndexEmptyValue(0,0.0);
   SetIndexEmptyValue(1,0.0);
   SetIndexEmptyValue(2,0.0);
   
//--- drawing style
   SetIndexStyle(0,DRAW_NONE);
   SetIndexStyle(1,DRAW_NONE);
   SetIndexStyle(2,DRAW_NONE);
//---
   
   total_tz = 0;
   total_ptz = 0;
   total_htz = 0;
   total_mtz = 0;
   total_ltz = 0; 
   
   return(INIT_SUCCEEDED);
  }
 
void OnDeinit(const int reason)
{
   DeleteZones();
}    
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
//--- Get the number of bars available for the current symbol and chart period

//--- counting from 0 to rates_total
   ArraySetAsSeries(HTZBuffer,false);
   ArraySetAsSeries(LTZBuffer,false);
   ArraySetAsSeries(MTZBuffer,false);
   
   ArraySetAsSeries(time,false);
   ArraySetAsSeries(open,false);
   ArraySetAsSeries(high,false);
   ArraySetAsSeries(low,false);
   ArraySetAsSeries(close,false);
   
//--- first calculation or number of bars was changed
   if(prev_calculated==0) {
      DeleteZones();
      ArrayInitialize(HTZBuffer,0);
      ArrayInitialize(LTZBuffer,0);
      ArrayInitialize(MTZBuffer,0);
   }
//--- calculation   
   CalculateBuff(rates_total, prev_calculated, time, open, high, low, close);

//--- return value of prev_calculated for next call
   return(rates_total);
  }

  
void CalculateBuff(int rates_total,int prev_calculated,const datetime& time[],const double &open[],const double &high[],const double &low[],const double &close[]) 
  {
      int i,limit;
      
//--- first calculation or number of bars was changed
   if(prev_calculated==0)
     {
      if (bars_limit == 0) {
         limit=prev_calculated + h_value; 
         total_bars = rates_total; 
      }
      else 
         limit = rates_total-1 - bars_limit; 
         total_bars = bars_limit; 
     }
   else {
      limit=prev_calculated+1;
      total_bars = total_bars + rates_total-prev_calculated; 
   }
//--- main loop
   // draw TZ   
   for(i=limit; i<rates_total-h_value-2 && !IsStopped(); i++) {
      DrawTZ(i,rates_total,time,open,high,low,close,h_value,h_value);   
   }
   
   // draw PTZ   
   for(i=rates_total-h_value-2; i<rates_total-1 && !IsStopped(); i++) {
      DrawTZ(i,rates_total,time,open,high,low,close,h_value,h_value,true); 
   }        
   
   // draw Statistics
   if (show_stats)
      DrawStats(total_bars);
//---
  }
  
void DrawTZ(int i, 
            int rates_total, 
            const datetime& time[],
            const double &open[],
            const double &high[],
            const double &low[],
            const double &close[],
            const int h_left, 
            const int h_right, 
            const bool redraw=false) 
{
   int j; 
   double max_left=0.0, max_right=0.0, min_left=999999999.0, min_right=999999999.0; 
   string rec_name_left,rec_name_right;
   datetime t_left, t_right; 
   color left_clr, right_clr; 
   bool out_of_h_range = (i+h_right < rates_total-1);
   int old_htz_state = HTZBuffer[i], old_ltz_state = LTZBuffer[i], old_mtz_state = MTZBuffer[i];
   string remain_ptz_bars = IntegerToString(i+h_right+2 - rates_total);
   string ptz_bars_name; 
   

   if (redraw == true) {
      ObjectDelete(StringConcatenate("TZ_H_left_", i)); 
      ObjectDelete(StringConcatenate("TZ_H_right_", i)); 
      ObjectDelete(StringConcatenate("TZ_L_left_", i)); 
      ObjectDelete(StringConcatenate("TZ_L_right_", i)); 
      ObjectDelete(StringConcatenate("TZ_M_left_", i)); 
      ObjectDelete(StringConcatenate("TZ_M_right_", i));   
      ObjectDelete(StringConcatenate("TZ_H_PTZ_bars_", i));   
      ObjectDelete(StringConcatenate("TZ_L_PTZ_bars_", i));   
      ObjectDelete(StringConcatenate("TZ_M_PTZ_bars_", i));   
      //HTZBuffer[i] = 0;
      //MTZBuffer[i] = 0; 
      //LTZBuffer[i] = 0;                     
   }
   if (out_of_h_range) {// out of repaint range 
      left_clr = tz_left_clr; 
      right_clr = tz_right_clr; 
   }
   else {
      left_clr = ptz_clr; 
      right_clr = ptz_clr; 
   }
      
   t_left = GetTime(i,-h_left,rates_total,time); 
   t_right = GetTime(i,h_right,rates_total,time); 
   
   for (j=MathMax(0,i-h_left); j<=i-1; j++) {
      min_left = MathMin(min_left, low[j]); 
      max_left = MathMax(max_left, high[j]); 
   }
   for (j=i+1; j<=MathMin(rates_total-1,i+h_right); j++) {
      min_right = MathMin(min_right, low[j]); 
      max_right = MathMax(max_right, high[j]); 
   }
   
   if (high[i] > max_left && high[i] > max_right) {  // top TZ
      rec_name_left = StringConcatenate("TZ_H_left_", i);
      rec_name_right = StringConcatenate("TZ_H_right_", i);
      ptz_bars_name = StringConcatenate("TZ_H_PTZ_bars_", i); 
      if (uneven_tz) {
         RectangleCreate(0, rec_name_left, 0, t_left, high[i], time[i-1], max_left,left_clr,0,1,true); 
         RectangleCreate(0, rec_name_right, 0, time[i+1], high[i], t_right, max_right,right_clr,0,1,true); 
      }
      else {
         RectangleCreate(0, rec_name_left, 0, t_left, high[i], time[i], MathMax(max_left,max_right),left_clr,0,1,true); 
         RectangleCreate(0, rec_name_right, 0, time[i], high[i], t_right, MathMax(max_left,max_right),right_clr,0,1,true); 
      }
      if (out_of_h_range) { // zones confirmed
         HTZBuffer[i] = 1;
      }
      else {
         HTZBuffer[i] = 2;
         if (show_remain_ptz_bars_num)
            TextCreate(0, ptz_bars_name, 0, t_right, MathMax(max_left,max_right), remain_ptz_bars, "Arial", 10, remain_ptz_bars_num_color);          
      }
   }
   else {
      HTZBuffer[i] = 0; 
   }
   
   if (low[i] < min_left && low[i] < min_right) {  // bottom TZ
      rec_name_left = StringConcatenate("TZ_L_left_", i);
      rec_name_right = StringConcatenate("TZ_L_right_", i);
      ptz_bars_name = StringConcatenate("TZ_L_PTZ_bars_", i); 
      if (uneven_tz) {
         RectangleCreate(0, rec_name_left, 0, t_left, low[i], time[i-1], min_left,left_clr,0,1,true); 
         RectangleCreate(0, rec_name_right, 0, time[i+1], low[i], t_right, min_right,right_clr,0,1,true); 
      }
      else {
         RectangleCreate(0, rec_name_left, 0, t_left, low[i], time[i], MathMin(min_left,min_right),left_clr,0,1,true); 
         RectangleCreate(0, rec_name_right, 0, time[i], low[i], t_right, MathMin(min_left,min_right),right_clr,0,1,true);       
      }
      if (out_of_h_range) { // zones confirmed
         LTZBuffer[i] = 1;
      }
      else {
         LTZBuffer[i] = 2;
         if (show_remain_ptz_bars_num)
            TextCreate(0, ptz_bars_name, 0, t_right, MathMin(min_left,min_right), remain_ptz_bars, "Arial", 10, remain_ptz_bars_num_color); 
      }
   }
   else {
      LTZBuffer[i] = 0; 
   }
   
   if (max_left < min_right) {  // mid TZ
      rec_name_left = StringConcatenate("TZ_M_left_", i);
      rec_name_right = StringConcatenate("TZ_M_right_", i);
      ptz_bars_name = StringConcatenate("TZ_M_PTZ_bars_", i); 
      if (uneven_tz) {
         RectangleCreate(0, rec_name_left, 0, t_left, min_right, time[i-1], max_left,left_clr,0,1,true); 
         RectangleCreate(0, rec_name_right, 0, time[i+1], min_right, t_right, max_left,right_clr,0,1,true); 
      }
      else {
         RectangleCreate(0, rec_name_left, 0, t_left, min_right, time[i], max_left,left_clr,0,1,true); 
         RectangleCreate(0, rec_name_right, 0, time[i], min_right, t_right, max_left,right_clr,0,1,true); 
      }
      if (out_of_h_range) { // zones confirmed
         MTZBuffer[i] = 1;
      }
      else {
         MTZBuffer[i] = 2;
         if (show_remain_ptz_bars_num)
         TextCreate(0, ptz_bars_name, 0, t_right, min_right, remain_ptz_bars, "Arial", 10, remain_ptz_bars_num_color); 
      }
   }
   else if (min_left > max_right) {  // mid TZ
      rec_name_left = StringConcatenate("TZ_M_left_", i);
      rec_name_right = StringConcatenate("TZ_M_right_", i);
      ptz_bars_name = StringConcatenate("TZ_M_PTZ_bars_", i); 
      if (uneven_tz) {
         RectangleCreate(0, rec_name_left, 0, t_left, min_left, time[i-1], max_right,left_clr,0,1,true); 
         RectangleCreate(0, rec_name_right, 0, time[i+1], min_left, t_right, max_right,right_clr,0,1,true); 
      }
      else {
         RectangleCreate(0, rec_name_left, 0, t_left, min_left, time[i], max_right,left_clr,0,1,true); 
         RectangleCreate(0, rec_name_right, 0, time[i], min_left, t_right, max_right,right_clr,0,1,true);       
      }
      if (out_of_h_range) { // zones confirmed
         MTZBuffer[i] = 1; 
      }
      else {
         MTZBuffer[i] = 2;
         if (show_remain_ptz_bars_num)
            TextCreate(0, ptz_bars_name, 0, t_right, min_left, remain_ptz_bars, "Arial", 10, remain_ptz_bars_num_color); 
      }
   }
   else { // not TZ 
      MTZBuffer[i] = 0;
   }
            
   // update statistics
   UpdateZoneStats(old_htz_state,HTZBuffer[i],total_htz,total_tz,total_ptz);
   UpdateZoneStats(old_ltz_state,LTZBuffer[i],total_ltz,total_tz,total_ptz);
   UpdateZoneStats(old_mtz_state,MTZBuffer[i],total_mtz,total_tz,total_ptz);   
}

void UpdateZoneStats(int old_state, int new_state, int &stat, int &stat_confirm, int &stat_potential) 
{
   if (old_state == 0) {
      if (new_state == 1) { // confirmed
         stat++;
         stat_confirm++;
      }
      else if (new_state == 2) { // potential appear
         stat_potential++; 
         if (do_alert) {
            Alert(Symbol() + ": new potential TZ appears"); 
         }
      }
   }
   else if (old_state == 1) {
      // do nothing
   }
   else if (old_state == 2) {
      if (new_state == 0) // potential cleared
         stat_potential--;
      else if (new_state == 1) { // potential become confirmed
         stat_potential--;
         stat_confirm++; 
      }
   }
}

void DrawStats(int bars_total)
{
   int x=stats_pos_x,y=stats_pos_y,fontsize=10,rowsize=fontsize+2,colsize=100;
   int i=0;
   double tz_per = total_tz*100.0/bars_total;
   double htz_per = total_htz*100.0/bars_total;
   double mtz_per = total_mtz*100.0/bars_total;
   double ltz_per = total_ltz*100.0/bars_total;
   
   ObjectDelete("TZ_Stats_1");
   ObjectDelete("TZ_Stats_2");
   ObjectDelete("TZ_Stats_h");
   ObjectDelete("TZ_Stats_h_val");
   ObjectDelete("TZ_Stats_Bars");
   ObjectDelete("TZ_Stats_Bars_val");
   ObjectDelete("TZ_Stats_TZs");
   ObjectDelete("TZ_Stats_TZs_val");
   ObjectDelete("TZ_Stats_PTZs");
   ObjectDelete("TZ_Stats_PTZs_val");
   ObjectDelete("TZ_Stats_HTZs");
   ObjectDelete("TZ_Stats_HTZs_val");
   ObjectDelete("TZ_Stats_LTZs");
   ObjectDelete("TZ_Stats_LTZs_val");
   ObjectDelete("TZ_Stats_MTZs");
   ObjectDelete("TZ_Stats_MTZs_val");
   
   LabelCreate(0,"TZ_Stats_1",       0,x,        y+rowsize*(i++),          CORNER_LEFT_UPPER,"TZ Statistics","Arial",fontsize,stats_color); 
   LabelCreate(0,"TZ_Stats_2",       0,x,        y+rowsize*(i++),          CORNER_LEFT_UPPER,"-----------------------------------------------------","Arial",fontsize,stats_color); 
   
   LabelCreate(0,"TZ_Stats_h",       0,x,        y+rowsize*(i),          CORNER_LEFT_UPPER,"h","Arial",fontsize,stats_color); 
   LabelCreate(0,"TZ_Stats_h_val",   0,x+colsize,y+rowsize*(i++),          CORNER_LEFT_UPPER,"= " + h_value,"Arial",fontsize,stats_color); 
   LabelCreate(0,"TZ_Stats_Bars",    0,x,        y+rowsize*(i),  CORNER_LEFT_UPPER,"Bars","Arial",fontsize,stats_color); 
   LabelCreate(0,"TZ_Stats_Bars_val",0,x+colsize,y+rowsize*(i++),  CORNER_LEFT_UPPER,"= " + bars_total,"Arial",fontsize,stats_color); 
   LabelCreate(0,"TZ_Stats_TZs",     0,x,        y+rowsize*i,CORNER_LEFT_UPPER,"TZs","Arial",fontsize,stats_color); 
   LabelCreate(0,"TZ_Stats_TZs_val", 0,x+colsize,y+rowsize*(i++),CORNER_LEFT_UPPER,"= "+total_tz+" ("+DoubleToStr(tz_per,2)+"%)","Arial",fontsize,stats_color); 
   //LabelCreate(0,"TZ_Stats_PTZs",    0,x,        y+rowsize*i,CORNER_LEFT_UPPER,"PTZs","Arial",fontsize,clrWhite); 
   //LabelCreate(0,"TZ_Stats_PTZs_val",0,x+colsize,y+rowsize*(i++),CORNER_LEFT_UPPER,"= " + total_ptz,"Arial",fontsize,clrWhite); 
   LabelCreate(0,"TZ_Stats_HTZs",    0,x,        y+rowsize*i,CORNER_LEFT_UPPER,"Top TZ","Arial",fontsize,stats_color); 
   LabelCreate(0,"TZ_Stats_HTZs_val",0,x+colsize,y+rowsize*(i++),CORNER_LEFT_UPPER,"= "+total_htz+" ("+DoubleToStr(htz_per,2)+"%)","Arial",fontsize,stats_color); 
   LabelCreate(0,"TZ_Stats_MTZs",    0,x,        y+rowsize*i,CORNER_LEFT_UPPER,"Mid TZ","Arial",fontsize,stats_color); 
   LabelCreate(0,"TZ_Stats_MTZs_val",0,x+colsize,y+rowsize*(i++),CORNER_LEFT_UPPER,"= "+total_mtz+" ("+DoubleToStr(mtz_per,2)+"%)","Arial",fontsize,stats_color); 
   LabelCreate(0,"TZ_Stats_LTZs",    0,x,        y+rowsize*i,CORNER_LEFT_UPPER,"Bottom TZ","Arial",fontsize,stats_color); 
   LabelCreate(0,"TZ_Stats_LTZs_val",0,x+colsize,y+rowsize*(i++),CORNER_LEFT_UPPER,"= "+total_ltz+" ("+DoubleToStr(ltz_per,2)+"%)","Arial",fontsize,stats_color); 
}
  
//+------------------------------------------------------------------+
//| Create a text label                                              |
//+------------------------------------------------------------------+
bool LabelCreate(const long              chart_ID=0,               // chart's ID
                 const string            name="Label",             // label name
                 const int               sub_window=0,             // subwindow index
                 const int               x=0,                      // X coordinate
                 const int               y=0,                      // Y coordinate
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                 const string            text="Label",             // text
                 const string            font="Arial",             // font
                 const int               font_size=10,             // font size
                 const color             clr=clrRed,               // color
                 const double            angle=0.0,                // text slope
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                 const bool              back=false,               // in the background
                 const bool              selection=false,          // highlight to move
                 const bool              hidden=true,              // hidden in the object list
                 const long              z_order=0)                // priority for mouse click
  {
//--- reset the error value
   ResetLastError();
//--- create a text label
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create text label! Error code = ",GetLastError());
      return(false);
     }
//--- set label coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
  
//+------------------------------------------------------------------+
//| Create rectangle by the given coordinates                        |
//+------------------------------------------------------------------+
bool RectangleCreate(const long            chart_ID=0,        // chart's ID
                     const string          name="Rectangle",  // rectangle name
                     const int             sub_window=0,      // subwindow index 
                     datetime              time1=0,           // first point time
                     double                price1=0,          // first point price
                     datetime              time2=0,           // second point time
                     double                price2=0,          // second point price
                     const color           clr=clrBlue,        // rectangle color
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // style of rectangle lines
                     const int             width=1,           // width of rectangle lines
                     const bool            fill=false,        // filling rectangle with color
                     const bool            back=true,        // in the background
                     const bool            selection=false,    // highlight to move
                     const bool            hidden=true,       // hidden in the object list
                     const long            z_order=0)         // priority for mouse click
  {
//--- set anchor points' coordinates if they are not set
   //ChangeRectangleEmptyPoints(time1,price1,time2,price2);
//--- reset the error value
   ResetLastError();
//--- create a rectangle by the given coordinates
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,time1,price1,time2,price2))
     {
      Print(__FUNCTION__,
            ": failed to create a rectangle! ", name, " Error code = ",GetLastError());
      return(false);
     }
//--- set rectangle color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set the style of rectangle lines
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set width of the rectangle lines
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- enable (true) or disable (false) the mode of filling the rectangle
   ObjectSetInteger(chart_ID,name,OBJPROP_FILL,fill);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of highlighting the rectangle for moving
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
  
//+------------------------------------------------------------------+
//| Creating Text object                                             |
//+------------------------------------------------------------------+
bool TextCreate(const long              chart_ID=0,               // chart's ID
                const string            name="Text",              // object name
                const int               sub_window=0,             // subwindow index
                datetime                time=0,                   // anchor point time
                double                  price=0,                  // anchor point price
                const string            text="Text",              // the text itself
                const string            font="Arial",             // font
                const int               font_size=10,             // font size
                const color             clr=clrRed,               // color
                const double            angle=0.0,                // text slope
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                const bool              back=false,               // in the background
                const bool              selection=false,          // highlight to move
                const bool              hidden=true,              // hidden in the object list
                const long              z_order=0)                // priority for mouse click
  {
//--- set anchor point coordinates if they are not set
   //ChangeTextEmptyPoint(time,price);
//--- reset the error value
   ResetLastError();
//--- create Text object
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": failed to create \"Text\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the object by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }

datetime GetTime(int i,int distance,int rates_total,const datetime& time[])
{
   if (i+distance >= rates_total)
      return time[rates_total-1] + (distance + i - rates_total + 1)*PeriodSeconds(); 
   else if (i+distance < 0)
      return time[0];
   else 
      return time[i+distance];
}

void DeleteZones() {
   int obj_total=ObjectsTotal();
   string name;
   
   for(int i=obj_total;i>0;i--)
   {
      name = ObjectName(i);
      if (StringFind(name, "TZ_") >= 0) {
         ObjectDelete(name); 
      }     
   }
}