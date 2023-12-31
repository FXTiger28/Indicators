//+------------------------------------------------------------------+
//|                        	                 Heikin Ashi RSI Arrow |
//|                                         Copyright © 2023 FXTiger |
//|                                            trader10946@gmail.com |
//+------------------------------------------------------------------+

// This indicator calculates Relative Strength Index of the Heikin Ashi candlesticks

#property copyright "Copyright © 2023 FXTiger"

#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 10
#property indicator_level2 38
#property indicator_level3 50
#property indicator_level4 62
#property indicator_level5 90
#property indicator_buffers 12
#property indicator_width1  2
#property indicator_color1 clrAqua
#property indicator_levelcolor clrAqua

//--- Arrows
#property indicator_color6 Lime            // Arrow up strong
#property indicator_color7 Green           // Arrow up
#property indicator_color8 DodgerBlue      // Arrow sideways
#property indicator_color9 Maroon          // Arrow down
#property indicator_color10 Red            // Arrow down strong

#property indicator_width6  3
#property indicator_width7  3
#property indicator_width8  3
#property indicator_width9  3
#property indicator_width10 3

extern int RSIPeriod = 5;

// Heikin Ashi buffers
double OpenBuffer[];
double CloseBuffer[];

// RSI buffers
double PosBuffer[];
double NegBuffer[];
double RSIBuffer[];

// Arrow buffers
double ArrowUpStrong[];
double ArrowUp[];
double ArrowSideways[];
double ArrowDown[];
double ArrowDownStrong[];

// Cycle
double cycle[];

//--- Signal buffer
double Signal_buff[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   string short_name = "Heikin-Ashi RSI ("+RSIPeriod+")";
   IndicatorShortName(short_name);

//---- indicator buffers mapping
   IndicatorBuffers(12);
   SetIndexBuffer(0,RSIBuffer);
   SetIndexBuffer(1,PosBuffer);
   SetIndexBuffer(2,NegBuffer);
   SetIndexBuffer(3,OpenBuffer);
   SetIndexBuffer(4,CloseBuffer);
   SetIndexBuffer(5,ArrowUpStrong);
   SetIndexBuffer(6,ArrowUp);
   SetIndexBuffer(7,ArrowSideways);
   SetIndexBuffer(8,ArrowDown);
   SetIndexBuffer(9,ArrowDownStrong);
   SetIndexBuffer(10,cycle);
   SetIndexBuffer(11,Signal_buff);

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
   
//---- drawing settings
   SetIndexStyle(0,DRAW_LINE, STYLE_SOLID);
   SetIndexStyle(5,DRAW_ARROW);
   SetIndexStyle(6,DRAW_ARROW);
   SetIndexStyle(7,DRAW_ARROW);
   SetIndexStyle(8,DRAW_ARROW);
   SetIndexStyle(9,DRAW_ARROW);
   
//---- arrow styles   
   SetIndexArrow(5, 108);                    
   SetIndexArrow(6, 108);   
   SetIndexArrow(7, 108);   
   SetIndexArrow(8, 108);   
   SetIndexArrow(9, 108);    
  
   // Clear all buffers
   for(int j = 0; j == Bars; j++)
   {
      OpenBuffer[j] = 0.0;
      CloseBuffer[j] = 0.0;
      PosBuffer[j] = 0.0;
      NegBuffer[j] = 0.0;
      RSIBuffer[j] = 0.0;
      cycle[j] = 0.0;
   }

   return(0);
}
//+------------------------------------------------------------------+
//| Heikin-Ashi Relative Index                                       |
//+------------------------------------------------------------------+
int start()
{
	// Check out how many bars need to be counted
   int counted_bars = IndicatorCounted();       		// Number of counted bars
   if (counted_bars < 0) return(-1);           			// Check for possible errors
   if (counted_bars > 0) counted_bars--;       			// Last counted bar will be recounted
   if (Bars <= 30) return(0);                         // Check if we have minimum amount bars available
   int pos = Bars - counted_bars - 1;                 // Index of the first uncounted Heineken Ashi bar
   int i = Bars - counted_bars - 1;             		// Index of the first uncounted RSI bar
   if (i > Bars - 20) i = Bars - 20;                  // First 20 bars are not counted
   int limit = i;

	//+------------------------------------------------------------------+
	//| Heikin Ashi Candlesticks				                              |
	//+------------------------------------------------------------------+

   while(pos >= 0)
	{
      OpenBuffer[pos] = (OpenBuffer[pos+1] + CloseBuffer[pos+1]) / 2;
      CloseBuffer[pos] = (Open[pos] + High[pos] + Low[pos] + Close[pos]) / 4;
		pos--;
	}

	//+------------------------------------------------------------------+
	//| Relative Strength Index				                              |
	//+------------------------------------------------------------------+

   while(i >= 0)                                  		// Loop for uncounted bars
   {
      double sumn = 0.0, sump = 0.0;
      double relation = CloseBuffer[i] - OpenBuffer[i];	// Relation between opening and closing prices
      
      bool posHA = CloseBuffer[i] > OpenBuffer[i];
      bool negHA = CloseBuffer[i] < OpenBuffer[i];
      bool prev_posHA = CloseBuffer[i+1] > OpenBuffer[i+1];
      bool prev_negHA = CloseBuffer[i+1] < OpenBuffer[i+1];

      bool posbar = (Close[i] > Open[i] && Close[i] > Close[i+1]) || (MathMin(Close[i], Open[i]) > MathMax(Close[i+1], Open[i+1]));
      bool negbar = (Close[i] < Open[i] && Close[i] < Close[i+1]) || (MathMax(Close[i], Open[i]) < MathMin(Close[i+1], Open[i+1]));
      
      cycle[i] = cycle[i+1];
      
      // Cycle
      if(cycle[i+1] == 1)
      {
         if(negHA && negbar)
         {
            if(prev_posHA)
            {
               if(CloseBuffer[i] < OpenBuffer[i+1])
                  cycle[i] = -1;
            }
            if(prev_negHA)
            {
               if(CloseBuffer[i] < CloseBuffer[i+1])
                  cycle[i] = -1;
            }
         }
      }
      else if(cycle[i+1] == -1)
      {
         if(posHA && posbar)
         {
            if(prev_negHA)
            {
               if(CloseBuffer[i] > OpenBuffer[i+1])
                  cycle[i] = 1;
            }
            if(prev_posHA)
            {
               if(CloseBuffer[i] > CloseBuffer[i+1])
                  cycle[i] = 1;
            }
         }
      }
      else
      {
         if(relation > 0)										// Bullish Heikin-Ashi candle
		      cycle[i] = 1;
         else														// Bearish Heikin-Ashi candle
            cycle[i] = -1; 
      }
      
      if(cycle[i] == 1)
      {
         if(posHA)										      // Bullish Heikin-Ashi candle
		      sump += relation;		
         else if(posbar)										// Bullish candle
		      sump += Close[i] - Open[i];		
      }
      else if(cycle[i] == -1)
      {
         if(negHA)										      // Bullish Heikin-Ashi candle
		      sumn -= relation;		
         else if(negbar)										// Bullish candle
		      sumn -= Close[i] - Open[i];		
      }

      PosBuffer[i] = (PosBuffer[i+1] * (RSIPeriod - 1) + sump) / RSIPeriod;
      NegBuffer[i] = (NegBuffer[i+1] * (RSIPeriod - 1) + sumn) / RSIPeriod;
      if(NegBuffer[i] == 0.0) RSIBuffer[i] = 100.0;
      else RSIBuffer[i] = 100.0 - 100.0 / (1 + PosBuffer[i] / NegBuffer[i]);
      i--;
   }
   
   for(i=0; i<limit; i++)   
   {
      //--- Calculate signal parameters
      double harsi_0 = RSIBuffer[i];
      double harsi_1 = RSIBuffer[i+1];
      
      bool positive = harsi_0 > 50;   
      bool negative = harsi_0 < 50;
      
      bool increase = harsi_0 >= harsi_1 && harsi_0 > 0;
      bool decrease = harsi_0 <= harsi_1 && harsi_0 < 100;
      
      bool top = harsi_0 == 100;
      bool bottom = harsi_0 == 0;
      
      //--- Set signal values             
      int signal = 0;
      
      /*
      if(cycle[i] == 1)
      {
         if(increase)
            signal = 2;
         else
            signal = 1;
      }
      else if(cycle[i] == -1)
      {
         if(decrease)
            signal = -2;
         else
            signal = -1;
      }
      */
      
           
      if(top)
      {
         signal = 2;
      }
      else if(bottom)
      {
         signal = -2;
      }         
      else if(positive)
      {
         if(cycle[i] == 1 && increase)
            signal = 2;
         else
            signal = 1;
      }
      else if(negative)
      {
         if(cycle[i] == -1 && decrease)
            signal = -2;
         else
            signal = -1;
      }
      
      
      Signal_buff[i] = signal;
         
      //--- Set correct arrow based on signal value
      
      double rangemin = 40;
      double rangemax = 60;
      
      if(signal >= 2)
      {
         ArrowUpStrong[i]     = rangemin;
         ArrowUp[i]           = 0;
         ArrowSideways[i]     = 0;
         ArrowDown[i]         = 0;
         ArrowDownStrong[i]   = 0;
      }
      else if(signal == 1)
      {
         ArrowUpStrong[i]     = 0;
         ArrowUp[i]           = rangemin;
         ArrowSideways[i]     = 0;
         ArrowDown[i]         = 0;
         ArrowDownStrong[i]   = 0;
      }
      else if(signal == 0)
      {
         ArrowUpStrong[i]     = 0;
         ArrowUp[i]           = 0;
         ArrowSideways[i]     = rangemin;
         ArrowDown[i]         = 0;
         ArrowDownStrong[i]   = 0;
      }
      else if(signal == -1)
      {
         ArrowUpStrong[i]     = 0;
         ArrowUp[i]           = 0;
         ArrowSideways[i]     = 0;
         ArrowDown[i]         = rangemax;
         ArrowDownStrong[i]   = 0;
      }
      else if(signal <= -2)
      {
         ArrowUpStrong[i]     = 0;
         ArrowUp[i]           = 0;
         ArrowSideways[i]     = 0;
         ArrowDown[i]         = 0;
         ArrowDownStrong[i]   = rangemax;
      }               
   }      
   return(0);
}
//+------------------------------------------------------------------+


