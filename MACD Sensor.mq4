//+------------------------------------------------------------------+
//|                                                 MACD Sensor V1.0 |
//|                                         Copyright © 2023 FXTiger |
//|                                            trader10946@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2023 FXTiger"

/*
The MACD Sensor indicator is designed to identify the prevailing trend's phases by analyzing a few key features of the self MACD indicator.
These features include the momentum's direction, the MACD main line's direction, the momentum's change, and the momentum's acceleration.
The indicator returns a value ranging from -3 to 3 based on the trend's strength and direction and then displays these values using the osma histogram's color.
*/

#property  indicator_separate_window
#property  indicator_buffers 7
#property  indicator_color1  LimeGreen       // Strong uptrend
#property  indicator_color2  DarkGreen       // Weak uptrend
#property  indicator_color3  Red             // Strong downtrend
#property  indicator_color4  Maroon          // Weak downtrend
#property  indicator_color5  DarkSlateGray   // No trend
#property  indicator_color6  Aqua            // MACD main line
#property  indicator_color7  Magenta         // MACD signal line

#property  indicator_width1  5
#property  indicator_width2  5
#property  indicator_width3  5
#property  indicator_width4  5
#property  indicator_width5  5
#property  indicator_width6  1
#property  indicator_width7  1

extern int FastEMA = 8;
extern int SlowEMA = 17;
extern int SignalSMA = 9;

double ACCM = 0.00001;                // Minimum acceleration level of the momentum
double ACCD = 0.00001;                // Minimum acceleration level of the direction

int history = 10000;

double   ind_UpStrong[];
double   ind_UpWeak[];
double   ind_DownStrong[];
double   ind_DownWeak[];
double   ind_NoTrend[];
double   ind_main[];
double   ind_signal[];
double   ind_osma[];

//--- Signal buffer
double signal_buffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   IndicatorBuffers(9);

   SetIndexStyle(0,DRAW_HISTOGRAM);       // Strong uptrend
   SetIndexStyle(1,DRAW_HISTOGRAM);       // Weak uptrend
   SetIndexStyle(2,DRAW_HISTOGRAM);       // Strong downtrend
   SetIndexStyle(3,DRAW_HISTOGRAM);       // Weak downtrend
   SetIndexStyle(4,DRAW_HISTOGRAM);       // No trend
   SetIndexStyle(5,DRAW_LINE);            // MACD main line
   SetIndexStyle(6,DRAW_LINE, STYLE_DOT); // MACD signal line
   
   IndicatorDigits(Digits+2);
   
   SetIndexDrawBegin(0,34);
   SetIndexDrawBegin(1,34);
   SetIndexDrawBegin(2,34);
   SetIndexDrawBegin(3,34);
   SetIndexDrawBegin(4,34);
   SetIndexDrawBegin(5,34);
   SetIndexDrawBegin(6,34);

   SetIndexBuffer(0,ind_UpStrong);
   SetIndexBuffer(1,ind_UpWeak);
   SetIndexBuffer(2,ind_DownStrong);
   SetIndexBuffer(3,ind_DownWeak); 
   SetIndexBuffer(4,ind_NoTrend); 
   SetIndexBuffer(5,ind_main);
   SetIndexBuffer(6,ind_signal);
   SetIndexBuffer(7,ind_osma);
   SetIndexBuffer(8,signal_buffer);

   IndicatorShortName("MACD Sensor ("+FastEMA+","+SlowEMA+","+SignalSMA+")");

   return(0);
  }
//+------------------------------------------------------------------+
//| MACD Sensor                                                      |
//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();       // Number of counted bars
   if (counted_bars < 0) return(-1);            // Check for possible errors
   if (counted_bars > 0) counted_bars--;        // Last counted bar will be recounted
   int limit = Bars-counted_bars;               // Index of the first uncounted
   if (limit > Bars-3) limit = Bars-3;          // First 3 bars should not be counted
   if (limit > history) limit = history;        // If there are too many bars, then calculate for specified amount
   
   //+----------------------------------------------------------------------------+
   //| Values of macd, signal and osma are counted in their own buffers           |
   //+----------------------------------------------------------------------------+
   
   for(int i=0; i<limit; i++) 
      ind_main[i]=iMACD(NULL,0,FastEMA,SlowEMA,SignalSMA,PRICE_CLOSE,MODE_MAIN,i);

   for(i=0; i<limit; i++)
      ind_signal[i]=iMACD(NULL,0,FastEMA,SlowEMA,SignalSMA,PRICE_CLOSE,MODE_SIGNAL,i);

   for(i=0; i<limit; i++)
      ind_osma[i]=iOsMA(NULL,0,FastEMA,SlowEMA,SignalSMA,PRICE_CLOSE,i);

   //+----------------------------------------------------------------------------+
   //| Setting right colors for the histogram bars depending prevailing trend     |
   //+----------------------------------------------------------------------------+

   for(i=limit-1; i>=0; i--)
   {
      double osma_0 = ind_osma[i];
      double osma_1 = ind_osma[i+1];
      double osma_2 = ind_osma[i+2];

      double main_0 = ind_main[i];
      double main_1 = ind_main[i+1];
      double main_2 = ind_main[i+2];
      
	   // Signal volume is between -3 to +3
      int signal = 0;	  // Reset
  	   if(main_0 > main_1+ACCD) signal++;   				                         // Main line is moving upwards
      if(osma_0 > ACCM+(osma_1+osma_2)/2) signal++;                 		       // Increasing momentum
      if(osma_0 > osma_1 && osma_0-osma_1 > osma_1-osma_2+ACCM) signal++;   	 // Positive acceleration of the momentum
      if(main_0 < main_1-ACCD) signal--;			                			      // Main line is moving downwards
      if(osma_0 < -ACCM+(osma_1+osma_2)/2) signal--;   		    	            // Decreasing momentum      
      if(osma_0 < osma_1 && osma_0-osma_1 < osma_1-osma_2-ACCM) signal--;     // Negative acceleration of the momentum
      if(osma_0 > 0 && signal < 1) signal = 1;
      if(osma_0 < 0 && signal > -1) signal = -1;

      switch(signal)
      {
         case 3: signal_buffer[i] = 2; break;
         case 2: signal_buffer[i] = 2; break;
         case 1: signal_buffer[i] = 1; break;
         case 0: signal_buffer[i] = 0; break;
         case -1: signal_buffer[i] = -1; break;
         case -2: signal_buffer[i] = -2; break;
         case -3: signal_buffer[i] = -2; break;
      }
            
      if(signal >= 2)                     // Strong uptrend
      {
         ind_UpStrong[i]   = osma_0;
         ind_UpWeak[i]     = 0.0;
         ind_DownStrong[i] = 0.0;
         ind_DownWeak[i]   = 0.0;
         ind_NoTrend[i]    = 0.0;
      }
      else if(signal > 0)                 // Moderate uptrend
      {            
         ind_UpStrong[i]   = 0.0;
         ind_UpWeak[i]     = osma_0;
         ind_DownStrong[i] = 0.0;
         ind_DownWeak[i]   = 0.0;
         ind_NoTrend[i]    = 0.0;
      }
      else if(signal <= -2)               // Strong downtrend
      {
         ind_UpStrong[i]   = 0.0;
         ind_UpWeak[i]     = 0.0;
         ind_DownStrong[i] = osma_0;
         ind_DownWeak[i]   = 0.0;
         ind_NoTrend[i]    = 0.0;
      }
      else if(signal < 0)                 // Moderate downtrend
      {
         ind_UpStrong[i]   = 0.0;
         ind_UpWeak[i]     = 0.0;
         ind_DownStrong[i] = 0.0;
         ind_DownWeak[i]   = osma_0;
         ind_NoTrend[i]    = 0.0;
      }
      else                                // No trend
      {
         ind_UpStrong[i]   = 0.0;
         ind_UpWeak[i]     = 0.0;
         ind_DownStrong[i] = 0.0;
         ind_DownWeak[i]   = 0.0;
         ind_NoTrend[i]    = osma_0;
      }         
   }
   return(0);
}

