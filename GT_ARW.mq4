//+------------------------------------------------------------------+
//|                                                       GT_ARW.mq4 |
//|                                                  FX Tiger @ 2022 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

/*
GMMA traders examines swing polarity and momentum on the price chart.

2   Positive polarity with increasing momentum
1   Positive polarity with flat or decreasing momentum
0   Flat
-1  Negative polarity with flat or decreasing momentum
-2  Negative polarity with increasing momentum

*/

#property copyright "FX Tiger @ 2022"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//---- indicator settings
#property indicator_chart_window
#property indicator_buffers 11
#property indicator_color1 clrLime 
#property indicator_color2 clrDeepPink
#property indicator_color3 clrLime
#property indicator_color4 clrDodgerBlue
#property indicator_color5 clrDeepPink
#property indicator_color6 clrLime        // Arrow up strong
#property indicator_color7 clrGreen       // Arrow up
#property indicator_color8 clrDimGray     // Arrow sideways
#property indicator_color9 clrMaroon      // Arrow down
#property indicator_color10 clrRed        // Arrow down strong

#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
#property indicator_width8  1
#property indicator_width9  1
#property indicator_width10 1

#property indicator_style1 STYLE_SOLID
#property indicator_style2 STYLE_SOLID
#property indicator_style3 STYLE_DOT
#property indicator_style4 STYLE_DOT
#property indicator_style5 STYLE_DOT

//---- input parameters
input int history = 10000;
input bool arrows = true;

//---- indicator buffers
double ExtEMA_4[];
double ExtEMA_8[];
double ExtEMA_12[];
double ExtEMA_16[];
double ExtEMA_20[];

double ExtArrowUpStrong[];
double ExtArrowUp[];
double ExtArrowSideways[];
double ExtArrowDown[];
double ExtArrowDownStrong[];

//--- Signal buffer
double Signal_buffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorDigits(Digits);
   //---- first positions skipped when drawing
   SetIndexDrawBegin(0,34);
   SetIndexDrawBegin(1,34);
   SetIndexDrawBegin(2,34);
   SetIndexDrawBegin(3,34);
   SetIndexDrawBegin(4,34);
   SetIndexDrawBegin(5,34);
   SetIndexDrawBegin(6,34);
   SetIndexDrawBegin(7,34);
   SetIndexDrawBegin(8,34);
   SetIndexDrawBegin(9,34);
   //---- indicator buffers mapping
   SetIndexBuffer(0,ExtEMA_4);
   SetIndexBuffer(1,ExtEMA_8);
   SetIndexBuffer(2,ExtEMA_12);
   SetIndexBuffer(3,ExtEMA_16);
   SetIndexBuffer(4,ExtEMA_20);
   SetIndexBuffer(5,ExtArrowUpStrong);
   SetIndexBuffer(6,ExtArrowUp);
   SetIndexBuffer(7,ExtArrowSideways);
   SetIndexBuffer(8,ExtArrowDown);
   SetIndexBuffer(9,ExtArrowDownStrong);
   SetIndexBuffer(10,Signal_buffer);
//---- 0 value will not be displayed
   SetIndexEmptyValue(0,0);
   SetIndexEmptyValue(1,0);
   SetIndexEmptyValue(2,0);
   SetIndexEmptyValue(3,0);
   SetIndexEmptyValue(4,0);
   SetIndexEmptyValue(5,0);
   SetIndexEmptyValue(6,0);
   SetIndexEmptyValue(7,0);   
   SetIndexEmptyValue(8,0);   
   SetIndexEmptyValue(9,0);   
   SetIndexEmptyValue(10,0);   
//---- drawing settings
   SetIndexStyle(0,DRAW_NONE);
   SetIndexStyle(1,DRAW_NONE);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexStyle(3,DRAW_LINE);
   SetIndexStyle(4,DRAW_LINE);
   SetIndexStyle(5,DRAW_ARROW);
   SetIndexStyle(6,DRAW_ARROW);
   SetIndexStyle(7,DRAW_ARROW);
   SetIndexStyle(8,DRAW_ARROW);
   SetIndexStyle(9,DRAW_ARROW);
   SetIndexStyle(10,DRAW_NONE);
//---- index labels
   SetIndexLabel(0,"EMA 4");
   SetIndexLabel(1,"EMA 8");
   SetIndexLabel(2,"EMA 12");
   SetIndexLabel(3,"EMA 16");
   SetIndexLabel(4,"EMA 20");
   SetIndexLabel(5,"Arrow Up Strong");
   SetIndexLabel(6,"Arrow Up");
   SetIndexLabel(7,"Arrow Sideways");
   SetIndexLabel(8,"Arrow Down");
   SetIndexLabel(9,"Arrow Down Strong");
//---- arrow styles   
   SetIndexArrow(5, 225);                    
   SetIndexArrow(6, 228);   
   SetIndexArrow(7, 224);   
   SetIndexArrow(8, 230);   
   SetIndexArrow(9, 226);   
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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

//--- Counting total bars to be calculated
   int limit=rates_total-prev_calculated;
   if (limit > rates_total-3) limit = rates_total-3;        // First 3 bars should not be counted
   if (limit > history) limit = history;                    // If there are too many bars, then calculate for specified amount
   if(prev_calculated>0) limit++;                           // Calculate new values for every tick

   //Print("rates_total ", rates_total, " Bars ", Bars, " prev_calculated ", prev_calculated, " Limit ", limit);

//---- main loop
   for(int i=0; i<limit; i++)
     {
      ExtEMA_4[i]=iMA(NULL,0,4,0,MODE_EMA,PRICE_CLOSE,i);
      ExtEMA_8[i]=iMA(NULL,0,8,0,MODE_EMA,PRICE_CLOSE,i);
      ExtEMA_12[i]=iMA(NULL,0,12,0,MODE_EMA,PRICE_CLOSE,i);
      ExtEMA_16[i]=iMA(NULL,0,16,0,MODE_EMA,PRICE_CLOSE,i);
      ExtEMA_20[i]=iMA(NULL,0,20,0,MODE_EMA,PRICE_CLOSE,i);
     }
     
   for(int i=0; i<limit; i++)
   {
      //******************************************
      // Calculate current and previous EMA values
      //******************************************
      
      double EMA12_0 = ExtEMA_12[i];
      double EMA12_1 = ExtEMA_12[i+1];

      double EMA16_0 = ExtEMA_16[i];
      double EMA16_1 = ExtEMA_16[i+1];

      double EMA20_0 = ExtEMA_20[i];
      double EMA20_1 = ExtEMA_20[i+1];
      

      //**************************
      // Conditions for signal 1
      //**************************

      //--- Lines are in an uptrend order
      bool uptrend   = EMA12_0 > EMA16_0 && EMA16_0 > EMA20_0; 
      bool downtrend = EMA12_0 < EMA16_0 && EMA16_0 < EMA20_0; 
      
      //--- Lines are separated
      // To be programmed later on
      
      //--- Lines are not moving horizontally for prolonged period
      // To be programmed later on
      
      //--- At least one line is increasing
      double ACCD = 0.00005;
      //bool increase = EMA12_0 > EMA12_1 + EMA12_1 * ACCD;
      //bool decrease = EMA12_0 < EMA12_1 - EMA12_1 * ACCD;
      bool increaseOne = EMA12_0 > EMA12_1 + EMA12_1 * ACCD || EMA16_0 > EMA16_1 + EMA16_1 * ACCD || EMA20_0 > EMA20_1 + EMA20_1 * ACCD;
      bool decreaseOne = EMA12_0 < EMA12_1 - EMA12_1 * ACCD || EMA16_0 < EMA16_1 - EMA16_1 * ACCD || EMA20_0 < EMA20_1 - EMA20_1 * ACCD;
      
      //--- None of the lines is decreasing
      
      //--- Price closes above EMA 20
      bool above = close[i] > EMA20_0;
      bool below = close[i] < EMA20_0;
            
      //--- Price is not moving in a narrow range
      
      //**************************
      // Conditions for signal 2
      //**************************

      //--- All lines are clearly moving upwards
      bool increaseAll = EMA12_0 > EMA12_1 + EMA12_1 * ACCD && EMA16_0 > EMA16_1 + EMA16_1 * ACCD && EMA20_0 > EMA20_1 + EMA20_1 * ACCD;
      bool decreaseAll = EMA12_0 < EMA12_1 - EMA12_1 * ACCD && EMA16_0 < EMA16_1 - EMA16_1 * ACCD && EMA20_0 < EMA20_1 - EMA20_1 * ACCD;
            
      //--- Lines are either separating from each others or staying far away from each others but lines are not getting close to each others
            
      //--- Price closes above fast EMA
      
      //--- Price closes higher than the previous candle or the second  previous candle
      
      //--- Bar is not laying above the lines


      //**************************
      // Set correct signal values
      //**************************
      int signal = 0;
               
      if(uptrend && increaseOne && above)
      {
         if(increaseAll)
            signal = 2;
         else
            signal = 1;
      }
      else if(downtrend && decreaseOne && below)
      {
         if(decreaseAll)
            signal = -2;
         else
            signal = -1;
      }
      Signal_buffer[i] = signal;
         
      if(arrows == true)
      {
         //--- Set correct arrow based on signal value
         
         double rangemin = EMA20_0 - iATR(NULL, 0, 20, i) / 2;
         double rangemax = EMA20_0 + iATR(NULL, 0, 20, i) / 2;
         
         //Print("Bar ", i, " Signal ", signal, " Point ", Point);
         
         if(signal == 2)
         {
            ExtArrowUpStrong[i]     = rangemin;
            ExtArrowUp[i]           = 0;
            ExtArrowSideways[i]     = 0;
            ExtArrowDown[i]         = 0;
            ExtArrowDownStrong[i]   = 0;
         }
         else if(signal == 1)
         {
            ExtArrowUpStrong[i]     = 0;
            ExtArrowUp[i]           = rangemin;
            ExtArrowSideways[i]     = 0;
            ExtArrowDown[i]         = 0;
            ExtArrowDownStrong[i]   = 0;
         }
         else if(signal == 0)
         {
            ExtArrowUpStrong[i]     = 0;
            ExtArrowUp[i]           = 0;
            ExtArrowSideways[i]     = rangemin;
            ExtArrowDown[i]         = 0;
            ExtArrowDownStrong[i]   = 0;
         }
         else if(signal == -1)
         {
            ExtArrowUpStrong[i]     = 0;
            ExtArrowUp[i]           = 0;
            ExtArrowSideways[i]     = 0;
            ExtArrowDown[i]         = rangemax;
            ExtArrowDownStrong[i]   = 0;
         }
         else if(signal == -2)
         {
            ExtArrowUpStrong[i]     = 0;
            ExtArrowUp[i]           = 0;
            ExtArrowSideways[i]     = 0;
            ExtArrowDown[i]         = 0;
            ExtArrowDownStrong[i]   = rangemax;
         }               
      }
   }
         
//---- done

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+