//+------------------------------------------------------------------+
//|                                         RR TRADE ASSISTANT       |
//|                                     Copyright 2025, Kalifx       |
//|                                      https://kalifxlab.com       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, kalifx"
#property link      "https://kalifxlab.com"
#property version   "1.01"
#property description "RR Trade Assistant"
#property description "Smart order management panel,"
#property description "Visual Risk-Reward Tool with draggable chart blocks"
#property description "Risk-Based Lot Calculation (Risk % or Fixed Lot)"
#property description "Market & Pending Orders (Buy/Sell/Limit/Stop)"
#property description "Calculated trades. Consistent profits."

#include <Trade/Trade.mqh> //--- Include the Trade library for trading operations

input double RR_TOOL_SCALE_PERCENT = 75.0; //--- Scale the RR tool size (100 = default)
input int RR_TOOL_FONT_SIZE = 8; //--- Font size for RR tool blocks
input double PANEL_SCALE_PERCENT = 100.0; // Scale the whole control panel size (100 = default)

// Control panel object names
#define PANEL_BG       "PANEL_BG" //--- Define constant for panel background object name
#define RR_EDIT        "RR_EDIT" //--- Define constant for RR ratio edit field object name
#define PRICE_LABEL    "PRICE_LABEL" //--- Define constant for price label object name
#define SL_LABEL       "SL_LABEL" //--- Define constant for stop-loss label object name
#define TP_LABEL       "TP_LABEL" //--- Define constant for take-profit label object name
#define BUY_STOP_BTN   "BUY_STOP_BTN" //--- Define constant for buy stop button object name
#define SELL_STOP_BTN  "SELL_STOP_BTN" //--- Define constant for sell stop button object name
#define BUY_LIMIT_BTN  "BUY_LIMIT_BTN" //--- Define constant for buy limit button object name
#define SELL_LIMIT_BTN "SELL_LIMIT_BTN" //--- Define constant for sell limit button object name
#define PLACE_ORDER_BTN "PLACE_ORDER_BTN" //--- Define constant for place order button object name
#define CANCEL_BTN     "CANCEL_BTN" //--- Define constant for cancel button object name
#define CLOSE_BTN      "CLOSE_BTN" //--- Define constant for close button object name
#define MINIMIZE_BTN   "MINIMIZE_BTN" //--- Minimize/Maximize toggle button
#define BUY_BTN        "BUY_BTN" //--- Market buy button
#define SELL_BTN       "SELL_BTN" //--- Market sell button
#define RISK_EDIT      "RISK_EDIT" //--- Risk percent edit field
#define ENTRY_EDIT     "ENTRY_EDIT" //--- Entry price edit field
#define SL_EDIT_FIELD  "SL_EDIT_FIELD" //--- SL price edit field
#define TP_EDIT_FIELD  "TP_EDIT_FIELD" //--- TP price edit field
#define RISK_VALUE_EDIT "RISK_VALUE_EDIT" //--- Risk/Lot value edit field

#define REC1 "REC1" //--- Define constant for rectangle 1 (TP) object name
#define REC2 "REC2" //--- Define constant for rectangle 2 object name
#define REC3 "REC3" //--- Define constant for rectangle 3 (Entry) object name
#define REC4 "REC4" //--- Define constant for rectangle 4 object name
#define REC5 "REC5" //--- Define constant for rectangle 5 (SL) object name

#define TP_HL "TP_HL" //--- Define constant for take-profit horizontal line object name
#define SL_HL "SL_HL" //--- Define constant for stop-loss horizontal line object name
#define PR_HL "PR_HL" //--- Define constant for price (entry) horizontal line object name

double Get_Price_d(string name) { return ObjectGetDouble(0, name, OBJPROP_PRICE); } //--- Function to get price as double for an object
string Get_Price_s(string name) { return DoubleToString(ObjectGetDouble(0, name, OBJPROP_PRICE), _Digits); } //--- Function to get price as string with proper digits
string update_Text(string name, string val) { return (string)ObjectSetString(0, name, OBJPROP_TEXT, val); } //--- Function to update text of an object

datetime EXPIRY_DATE = D'2028.02.01 00:00';  // trial expiry

int
   xd1, yd1, xs1, ys1, //--- Variables for rectangle 1 position and size
   xd2, yd2, xs2, ys2, //--- Variables for rectangle 2 position and size
   xd3, yd3, xs3, ys3, //--- Variables for rectangle 3 position and size
   xd4, yd4, xs4, ys4, //--- Variables for rectangle 4 position and size
   xd5, yd5, xs5, ys5; //--- Variables for rectangle 5 position and size

// Control panel variables
bool tool_visible = false; //--- Flag to track if trading tool is visible
string selected_order_type = ""; //--- Variable to store selected order type
double lot_size = 0.01; //--- Default lot size for trades
double rr_ratio = 2.0; //--- Default RR ratio for display
bool use_risk_percent = true; //--- Toggle between risk% and fixed lot mode
double risk_value = 1.0; //--- Risk percent or lot value based on mode
const double DEFAULT_RISK_PERCENT = 1.0;
const double DEFAULT_FIXED_LOT = 0.01;
const double DEFAULT_MARKET_SL_OFFSET_PCT = 0.35;
const double DEFAULT_MARKET_TP_OFFSET_PCT = 0.70;
const int MIN_LEVEL_GAP_PX = 8; //--- Minimum visual gap between TP/SL and Entry blocks
CTrade obj_Trade; //--- Trade object for executing trading operations
int panel_x = 10, panel_y = 30; //--- Panel position coordinates
bool is_tool_dragging = false; //--- True while user drags RR tool blocks
bool panel_minimized = false; //--- Control panel collapsed state

void SyncComputedRR();
void SyncPanelInputsFromLines();
double ReadPriceInput(string name);
void UpdateRiskModeButtonText();
double GetLotByMode(double entry_price, double sl_price);
double GetMoneyByPriceDistance(double from_price, double to_price, double lot);
double NormalizeLotSize(double lot);
void createControlPanel();
void showTool();
void showPanel();
void placeOrder();
bool createButton(string objName, string text, int xD, int yD, int xS, int yS,
                  color clrTxt, color clrBG, int fontsize = 12,
                  color clrBorder = clrNONE, bool isBack = false, string font = "Calibri");
bool createHL(string objName, datetime time1, double price1, color clr);
void deleteObjects();
void deletePanel();
void SetPanelMinimized(bool minimized);
string BuildSLText();
string BuildOrderTypeText();
string BuildTPText();
double GetPct(double reference_price, double target_price);
int GetScaledPx(int base_px);
int GetScaledFontSize(int base_size);
bool IsMarketOrderMode();
void ShiftRRToolY(int delta_y);
void SyncMarketEntryWithLine();
void SyncMarketSLTPLinesWithRRTool();
int GetPanelScaledPx(int base_px);
int GetPanelScaledFontSize(int base_size);

int GetScaledPx(int base_px) {
   double scale = RR_TOOL_SCALE_PERCENT;
   if(scale <= 0)
      scale = 100.0;
   return (int)MathMax(1.0, MathRound(base_px * scale / 100.0));
}

int GetScaledFontSize(int base_size) {
   if(RR_TOOL_FONT_SIZE > 0)
      return RR_TOOL_FONT_SIZE;
   return MathMax(1, base_size);
}

int GetPanelScaledPx(int base_px) {
   double scale = PANEL_SCALE_PERCENT;
   if(scale <= 0)
      scale = 100.0;
   return (int)MathMax(1.0, MathRound(base_px * scale / 100.0));
}

int GetPanelScaledFontSize(int base_size) {
   return MathMax(1, GetPanelScaledPx(base_size));
}

bool IsMarketOrderMode() {
   return (selected_order_type == "BUY" || selected_order_type == "SELL");
}

void ShiftRRToolY(int delta_y) {
   if(delta_y == 0)
      return;

   string recs[5] = {REC1, REC2, REC3, REC4, REC5};
   for(int i = 0; i < 5; i++) {
      int y = (int)ObjectGetInteger(0, recs[i], OBJPROP_YDISTANCE);
      ObjectSetInteger(0, recs[i], OBJPROP_YDISTANCE, y + delta_y);
   }
}

void SyncMarketEntryWithLine() {
   if(!tool_visible || !IsMarketOrderMode() || is_tool_dragging)
      return;

   double mkt_entry = (selected_order_type == "BUY") ? SymbolInfoDouble(Symbol(), SYMBOL_ASK) : SymbolInfoDouble(Symbol(), SYMBOL_BID);
   if(mkt_entry <= 0)
      return;

   ObjectSetDouble(0, PR_HL, OBJPROP_PRICE, mkt_entry);

   int x_ref = (int)ObjectGetInteger(0, REC3, OBJPROP_XDISTANCE) + (int)ObjectGetInteger(0, REC3, OBJPROP_XSIZE) / 2;
   int y_target = 0;
   int x_target = x_ref;
   if(!ChartTimePriceToXY(0, 0, TimeCurrent(), mkt_entry, x_target, y_target))
      return;

   int y_current = (int)ObjectGetInteger(0, REC3, OBJPROP_YDISTANCE) + (int)ObjectGetInteger(0, REC3, OBJPROP_YSIZE);
   ShiftRRToolY(y_target - y_current);
}

void SyncMarketSLTPLinesWithRRTool() {
   if(!tool_visible || is_tool_dragging)
      return;

   double tp_price = Get_Price_d(TP_HL);
   double pr_price = Get_Price_d(PR_HL);
   double sl_price = Get_Price_d(SL_HL);
   if(tp_price <= 0 || pr_price <= 0 || sl_price <= 0)
      return;

   int xd_r1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XDISTANCE);
   int xd_r3 = (int)ObjectGetInteger(0, REC3, OBJPROP_XDISTANCE);
   int xd_r5 = (int)ObjectGetInteger(0, REC5, OBJPROP_XDISTANCE);
   int xs_r1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XSIZE);
   int xs_r3 = (int)ObjectGetInteger(0, REC3, OBJPROP_XSIZE);
   int xs_r5 = (int)ObjectGetInteger(0, REC5, OBJPROP_XSIZE);
   int ys_r1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YSIZE);
   int ys_r3 = (int)ObjectGetInteger(0, REC3, OBJPROP_YSIZE);
   int ys_r5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YSIZE);

   int x_tp = xd_r1 + xs_r1 / 2;
   int x_pr = xd_r3 + xs_r3 / 2;
   int x_sl = xd_r5 + xs_r5 / 2;
   int y_tp = 0, y_pr = 0, y_sl = 0;

   if(!ChartTimePriceToXY(0, 0, TimeCurrent(), tp_price, x_tp, y_tp))
      return;
   if(!ChartTimePriceToXY(0, 0, TimeCurrent(), pr_price, x_pr, y_pr))
      return;
   if(!ChartTimePriceToXY(0, 0, TimeCurrent(), sl_price, x_sl, y_sl))
      return;

   ObjectSetInteger(0, REC1, OBJPROP_YDISTANCE, y_tp - ys_r1);
   ObjectSetInteger(0, REC3, OBJPROP_YDISTANCE, y_pr - ys_r3);
   ObjectSetInteger(0, REC5, OBJPROP_YDISTANCE, y_sl - ys_r5);

   int yd_r1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YDISTANCE);
   int yd_r3 = (int)ObjectGetInteger(0, REC3, OBJPROP_YDISTANCE);
   int yd_r5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YDISTANCE);

   if(selected_order_type == "BUY_STOP" || selected_order_type == "BUY_LIMIT" || selected_order_type == "BUY") {
      ObjectSetInteger(0, REC2, OBJPROP_YDISTANCE, yd_r1 + ys_r1);
      ObjectSetInteger(0, REC2, OBJPROP_YSIZE, MathMax(1, yd_r3 - (yd_r1 + ys_r1)));
      ObjectSetInteger(0, REC4, OBJPROP_YDISTANCE, yd_r3 + ys_r3);
      ObjectSetInteger(0, REC4, OBJPROP_YSIZE, MathMax(1, yd_r5 - (yd_r3 + ys_r3)));
   }
   else {
      ObjectSetInteger(0, REC2, OBJPROP_YDISTANCE, yd_r5 + ys_r5);
      ObjectSetInteger(0, REC2, OBJPROP_YSIZE, MathMax(1, yd_r3 - (yd_r5 + ys_r5)));
      ObjectSetInteger(0, REC4, OBJPROP_YDISTANCE, yd_r3 + ys_r3);
      ObjectSetInteger(0, REC4, OBJPROP_YSIZE, MathMax(1, yd_r1 - (yd_r3 + ys_r3)));
   }
}

void SetPanelMinimized(bool minimized) {
   panel_minimized = minimized;

   // Always keep frame controls visible
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BACK, false);
   ObjectSetInteger(0, CLOSE_BTN, OBJPROP_BACK, false);
   ObjectSetInteger(0, MINIMIZE_BTN, OBJPROP_BACK, false);

   // ✅ USE SCALED VALUES
   int full_h = GetPanelScaledPx(300);
   int mini_h = GetPanelScaledPx(38);

   ObjectSetInteger(0, PANEL_BG, OBJPROP_YSIZE, panel_minimized ? mini_h : full_h);

   update_Text(MINIMIZE_BTN, panel_minimized ? CharToString(241) : CharToString(240));

   long panel_tf = panel_minimized ? OBJ_NO_PERIODS : OBJ_ALL_PERIODS;

   ObjectSetInteger(0, RISK_EDIT, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, BUY_BTN, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, SELL_BTN, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, BUY_STOP_BTN, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, SELL_STOP_BTN, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, BUY_LIMIT_BTN, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, SELL_LIMIT_BTN, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, PLACE_ORDER_BTN, OBJPROP_TIMEFRAMES, panel_tf);
   ObjectSetInteger(0, CANCEL_BTN, OBJPROP_TIMEFRAMES, panel_tf);

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(TimeCurrent() > EXPIRY_DATE)
   {
      Alert("version expired. Please contact the developer.");
      return(INIT_FAILED);
   }

   //--- turn OFF chart elements
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false);
   ChartSetInteger(0, CHART_SHOW_VOLUMES, false);

   //--- chart colors
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrWhite);
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrBlack);

   //--- bars
   ChartSetInteger(0, CHART_COLOR_CHART_UP,   (color)0x9AA626);
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, (color)0x1E53EF);

   //--- candles
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, (color)0x9AA626);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, (color)0x4646DC);

   //--- create panel
   createControlPanel();

   //--- timer
   EventSetMillisecondTimer(60);

   ChartRedraw(0);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   EventKillTimer();
   deleteObjects(); //--- Delete tool objects
   deletePanel(); //--- Delete control panel objects
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   string risk_val_text = ObjectGetString(0, RISK_VALUE_EDIT, OBJPROP_TEXT);
   double new_risk_val = StringToDouble(risk_val_text);
   if(new_risk_val > 0) {
      risk_value = new_risk_val;
      if(!use_risk_percent)
         lot_size = risk_value;
   }

   if(tool_visible) {
      SyncMarketEntryWithLine();
      SyncMarketSLTPLinesWithRRTool();
      SyncComputedRR();
      SyncPanelInputsFromLines();
      if(IsMarketOrderMode())
         update_Text(REC3, BuildOrderTypeText());
   }
}

void OnTimer() {
   if(!tool_visible) return;

   SyncMarketEntryWithLine();
   SyncMarketSLTPLinesWithRRTool();
   SyncComputedRR();
   SyncPanelInputsFromLines();
   update_Text(REC1, BuildTPText());
   update_Text(REC3, BuildOrderTypeText());
   update_Text(REC5, BuildSLText());
   ChartRedraw(0);
}

double GetPct(double reference_price, double target_price) {
   if(reference_price <= 0) return 0;
   return MathAbs((reference_price - target_price) / reference_price) * 100.0;
}

double GetMoneyByPriceDistance(double from_price, double to_price, double lot) {
   double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   if(tick_size <= 0 || tick_value <= 0 || lot <= 0) return 0;
   return MathAbs(from_price - to_price) / tick_size * tick_value * lot;
}

double NormalizeLotSize(double lot) {
   double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   if(min_lot <= 0) min_lot = DEFAULT_FIXED_LOT;
   if(max_lot <= 0) max_lot = min_lot;
   if(step <= 0) step = min_lot;

   lot = MathMax(min_lot, MathMin(max_lot, lot));
   double steps = MathFloor((lot - min_lot) / step + 0.5);
   lot = min_lot + steps * step;
   lot = MathMax(min_lot, MathMin(max_lot, lot));

   int step_digits = 0;
   double tmp = step;
   while(step_digits < 8 && MathRound(tmp) != tmp) {
      tmp *= 10.0;
      step_digits++;
   }
   return NormalizeDouble(lot, step_digits);
}

double GetLotByMode(double entry_price, double sl_price) {
   if(!use_risk_percent)
      return NormalizeLotSize(risk_value > 0 ? risk_value : DEFAULT_FIXED_LOT);

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_money = balance * (risk_value / 100.0);
   double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double sl_dist = MathAbs(entry_price - sl_price);
   if(risk_money > 0 && tick_size > 0 && tick_value > 0 && sl_dist > 0)
      return NormalizeLotSize(risk_money / ((sl_dist / tick_size) * tick_value));

   return 0;
}

string BuildSLText() {
   string ccy = AccountInfoString(ACCOUNT_CURRENCY);
   return "SL : " + Get_Price_s(SL_HL) + " | " + DoubleToString(GetMoneyByPriceDistance(Get_Price_d(PR_HL), Get_Price_d(SL_HL), GetLotByMode(Get_Price_d(PR_HL), Get_Price_d(SL_HL))), 2) + " " + ccy + " | " + DoubleToString(GetPct(Get_Price_d(PR_HL), Get_Price_d(SL_HL)), 2) + "%";
}

string BuildOrderTypeText() {
   return selected_order_type + " : " + Get_Price_s(PR_HL) + " | RR " + DoubleToString(rr_ratio, 2);
}

string BuildTPText() {
   string ccy = AccountInfoString(ACCOUNT_CURRENCY);
   return "TP : " + Get_Price_s(TP_HL) + " | " + DoubleToString(GetMoneyByPriceDistance(Get_Price_d(PR_HL), Get_Price_d(TP_HL), GetLotByMode(Get_Price_d(PR_HL), Get_Price_d(SL_HL))), 2) + " " + ccy + " | " + DoubleToString(GetPct(Get_Price_d(PR_HL), Get_Price_d(TP_HL)), 2) + "%";
}

double ReadPriceInput(string name) {
   return NormalizeDouble(StringToDouble(ObjectGetString(0, name, OBJPROP_TEXT)), _Digits);
}

void UpdateRiskModeButtonText() {
   update_Text(RISK_EDIT, use_risk_percent ? "Risk %" : "Lot Size");
}

void SyncComputedRR() {
   double entry = Get_Price_d(PR_HL);
   double sl = Get_Price_d(SL_HL);
   double tp = Get_Price_d(TP_HL);
   double risk = MathAbs(entry - sl);
   double reward = MathAbs(tp - entry);
   if(risk > 0)
      rr_ratio = reward / risk;
}

void SyncPanelInputsFromLines() {
   double entry = Get_Price_d(PR_HL);
   double sl = Get_Price_d(SL_HL);
   double tp = Get_Price_d(TP_HL);

   ObjectSetString(0, ENTRY_EDIT, OBJPROP_TEXT, Get_Price_s(PR_HL));
   ObjectSetString(0, SL_EDIT_FIELD, OBJPROP_TEXT, DoubleToString(MathAbs((entry - sl) / _Point), 0));
   ObjectSetString(0, TP_EDIT_FIELD, OBJPROP_TEXT, DoubleToString(MathAbs((tp - entry) / _Point), 0));

   // keep user input in RISK_VALUE_EDIT unchanged during sync
}

//+------------------------------------------------------------------+
//| Chart event handler                                              |
//+------------------------------------------------------------------+
int prevMouseState = 0; //--- Variable to track previous mouse state

int mlbDownX1 = 0, mlbDownY1 = 0, mlbDownXD_R1 = 0, mlbDownYD_R1 = 0; //--- Variables for mouse down coordinates for REC1
int mlbDownX2 = 0, mlbDownY2 = 0, mlbDownXD_R2 = 0, mlbDownYD_R2 = 0; //--- Variables for mouse down coordinates for REC2
int mlbDownX3 = 0, mlbDownY3 = 0, mlbDownXD_R3 = 0, mlbDownYD_R3 = 0; //--- Variables for mouse down coordinates for REC3
int mlbDownX4 = 0, mlbDownY4 = 0, mlbDownXD_R4 = 0, mlbDownYD_R4 = 0; //--- Variables for mouse down coordinates for REC4
int mlbDownX5 = 0, mlbDownY5 = 0, mlbDownXD_R5 = 0, mlbDownYD_R5 = 0; //--- Variables for mouse down coordinates for REC5

bool movingState_R1 = false; //--- Flag for REC1 movement state
bool movingState_R3 = false; //--- Flag for REC3 movement state
bool movingState_R5 = false; //--- Flag for REC5 movement state

//+------------------------------------------------------------------+
//| Expert onchart event function                                    |
//+------------------------------------------------------------------+
void OnChartEvent(
   const int id, //--- Event ID
   const long& lparam, //--- Long parameter (e.g., x-coordinate for mouse)
   const double& dparam, //--- Double parameter (e.g., y-coordinate for mouse)
   const string& sparam //--- String parameter (e.g., object name)
) {
   if(id == CHARTEVENT_CHART_CHANGE && tool_visible) {
      SyncMarketEntryWithLine();
      SyncMarketSLTPLinesWithRRTool();
      SyncComputedRR();
      SyncPanelInputsFromLines();
      update_Text(REC1, BuildTPText());
      update_Text(REC3, BuildOrderTypeText());
      update_Text(REC5, BuildSLText());
      ChartRedraw(0);
      return;
   }

   if(id == CHARTEVENT_OBJECT_CLICK) { //--- Handle object click events
      // Handle order type buttons
      if(sparam == BUY_STOP_BTN) { //--- Check if Buy Stop button clicked
         selected_order_type = "BUY_STOP"; //--- Set order type to Buy Stop
         showTool(); //--- Show trading tool
         update_Text(PLACE_ORDER_BTN, "Send"); //--- Update place order button text
      }
      else if(sparam == SELL_STOP_BTN) { //--- Check if Sell Stop button clicked
         selected_order_type = "SELL_STOP"; //--- Set order type to Sell Stop
         showTool(); //--- Show trading tool
         update_Text(PLACE_ORDER_BTN, "Send"); //--- Update place order button text
      }
      else if(sparam == BUY_LIMIT_BTN) { //--- Check if Buy Limit button clicked
         selected_order_type = "BUY_LIMIT"; //--- Set order type to Buy Limit
         showTool(); //--- Show trading tool
         update_Text(PLACE_ORDER_BTN, "Send"); //--- Update place order button text
      }
      else if(sparam == SELL_LIMIT_BTN) { //--- Check if Sell Limit button clicked
         selected_order_type = "SELL_LIMIT"; //--- Set order type to Sell Limit
         showTool(); //--- Show trading tool
         update_Text(PLACE_ORDER_BTN, "Send"); //--- Update place order button text
      }
      else if(sparam == BUY_BTN) { //--- Check if Buy button clicked
         selected_order_type = "BUY";
         showTool();
         update_Text(PLACE_ORDER_BTN, "Send");
      }
      else if(sparam == SELL_BTN) { //--- Check if Sell button clicked
         selected_order_type = "SELL";
         showTool();
         update_Text(PLACE_ORDER_BTN, "Send");
      }
      else if(sparam == RISK_EDIT) {
         use_risk_percent = !use_risk_percent;
         risk_value = (use_risk_percent ? DEFAULT_RISK_PERCENT : DEFAULT_FIXED_LOT);
         ObjectSetString(0, RISK_VALUE_EDIT, OBJPROP_TEXT, DoubleToString(risk_value, 2));
         if(!use_risk_percent)
            lot_size = risk_value;
         UpdateRiskModeButtonText();
         if(tool_visible) {
            update_Text(REC1, BuildTPText());
            update_Text(REC3, BuildOrderTypeText());
            update_Text(REC5, BuildSLText());
         }
      }
      else if(sparam == PLACE_ORDER_BTN) { //--- Check if Send button clicked
         placeOrder(); //--- Execute order placement
         deleteObjects(); //--- Delete tool objects
         showPanel(); //--- Show control panel
      }
      else if(sparam == CANCEL_BTN) { //--- Check if Cancel button clicked
         deleteObjects(); //--- Delete tool objects
         showPanel(); //--- Show control panel
      }
      else if(sparam == MINIMIZE_BTN) {
         SetPanelMinimized(!panel_minimized);
      }
      else if(sparam == CLOSE_BTN) { //--- Check if Close button clicked
         deleteObjects(); //--- Delete tool objects
         deletePanel(); //--- Delete control panel
         ExpertRemove(); //--- Unload EA (triggers deinitialization)
         return;
      }
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false); //--- Reset button state
      ChartRedraw(0); //--- Redraw chart
   }

   if(id == CHARTEVENT_MOUSE_MOVE && tool_visible) { //--- Handle mouse move events when tool is visible
      int MouseD_X = (int)lparam; //--- Get mouse x-coordinate
      int MouseD_Y = (int)dparam; //--- Get mouse y-coordinate
      int MouseState = (int)sparam; //--- Get mouse state

      int XD_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XDISTANCE); //--- Get REC1 x-distance
      int YD_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YDISTANCE); //--- Get REC1 y-distance
      int XS_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XSIZE); //--- Get REC1 x-size
      int YS_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YSIZE); //--- Get REC1 y-size

      int XD_R2 = (int)ObjectGetInteger(0, REC2, OBJPROP_XDISTANCE); //--- Get REC2 x-distance
      int YD_R2 = (int)ObjectGetInteger(0, REC2, OBJPROP_YDISTANCE); //--- Get REC2 y-distance
      int XS_R2 = (int)ObjectGetInteger(0, REC2, OBJPROP_XSIZE); //--- Get REC2 x-size
      int YS_R2 = (int)ObjectGetInteger(0, REC2, OBJPROP_YSIZE); //--- Get REC2 y-size

      int XD_R3 = (int)ObjectGetInteger(0, REC3, OBJPROP_XDISTANCE); //--- Get REC3 x-distance
      int YD_R3 = (int)ObjectGetInteger(0, REC3, OBJPROP_YDISTANCE); //--- Get REC3 y-distance
      int XS_R3 = (int)ObjectGetInteger(0, REC3, OBJPROP_XSIZE); //--- Get REC3 x-size
      int YS_R3 = (int)ObjectGetInteger(0, REC3, OBJPROP_YSIZE); //--- Get REC3 y-size

      int XD_R4 = (int)ObjectGetInteger(0, REC4, OBJPROP_XDISTANCE); //--- Get REC4 x-distance
      int YD_R4 = (int)ObjectGetInteger(0, REC4, OBJPROP_YDISTANCE); //--- Get REC4 y-distance
      int XS_R4 = (int)ObjectGetInteger(0, REC4, OBJPROP_XSIZE); //--- Get REC4 x-size
      int YS_R4 = (int)ObjectGetInteger(0, REC4, OBJPROP_YSIZE); //--- Get REC4 y-size

      int XD_R5 = (int)ObjectGetInteger(0, REC5, OBJPROP_XDISTANCE); //--- Get REC5 x-distance
      int YD_R5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YDISTANCE); //--- Get REC5 y-distance
      int XS_R5 = (int)ObjectGetInteger(0, REC5, OBJPROP_XSIZE); //--- Get REC5 x-size
      int YS_R5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YSIZE); //--- Get REC5 y-size

      if(prevMouseState == 0 && MouseState == 1) { //--- Check for mouse button down
         mlbDownX1 = MouseD_X; //--- Store mouse x-coordinate for REC1
         mlbDownY1 = MouseD_Y; //--- Store mouse y-coordinate for REC1
         mlbDownXD_R1 = XD_R1; //--- Store REC1 x-distance
         mlbDownYD_R1 = YD_R1; //--- Store REC1 y-distance

         mlbDownX2 = MouseD_X; //--- Store mouse x-coordinate for REC2
         mlbDownY2 = MouseD_Y; //--- Store mouse y-coordinate for REC2
         mlbDownXD_R2 = XD_R2; //--- Store REC2 x-distance
         mlbDownYD_R2 = YD_R2; //--- Store REC2 y-distance

         mlbDownX3 = MouseD_X; //--- Store mouse x-coordinate for REC3
         mlbDownY3 = MouseD_Y; //--- Store mouse y-coordinate for REC3
         mlbDownXD_R3 = XD_R3; //--- Store REC3 x-distance
         mlbDownYD_R3 = YD_R3; //--- Store REC3 y-distance

         mlbDownX4 = MouseD_X; //--- Store mouse x-coordinate for REC4
         mlbDownY4 = MouseD_Y; //--- Store mouse y-coordinate for REC4
         mlbDownXD_R4 = XD_R4; //--- Store REC4 x-distance
         mlbDownYD_R4 = YD_R4; //--- Store REC4 y-distance

         mlbDownX5 = MouseD_X; //--- Store mouse x-coordinate for REC5
         mlbDownY5 = MouseD_Y; //--- Store mouse y-coordinate for REC5
         mlbDownXD_R5 = XD_R5; //--- Store REC5 x-distance
         mlbDownYD_R5 = YD_R5; //--- Store REC5 y-distance

         if(MouseD_X >= XD_R1 && MouseD_X <= XD_R1 + XS_R1 && //--- Check if mouse is within REC1 bounds
            MouseD_Y >= YD_R1 && MouseD_Y <= YD_R1 + YS_R1) {
            movingState_R1 = true; //--- Enable REC1 movement
         }
         if(MouseD_X >= XD_R3 && MouseD_X <= XD_R3 + XS_R3 && //--- Check if mouse is within REC3 bounds
            MouseD_Y >= YD_R3 && MouseD_Y <= YD_R3 + YS_R3) {
            movingState_R3 = true; //--- Enable REC3 movement
         }
         if(MouseD_X >= XD_R5 && MouseD_X <= XD_R5 + XS_R5 && //--- Check if mouse is within REC5 bounds
            MouseD_Y >= YD_R5 && MouseD_Y <= YD_R5 + YS_R5) {
            movingState_R5 = true; //--- Enable REC5 movement
         }

         if(movingState_R1 || movingState_R3 || movingState_R5)
            is_tool_dragging = true;
      }
      if(movingState_R1) { //--- Handle REC1 (TP) movement
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false); //--- Disable chart scrolling
         bool canMove = false; //--- Flag to check if movement is valid
         int proposedY_R1 = mlbDownYD_R1 + MouseD_Y - mlbDownY1;
         if(selected_order_type == "BUY_STOP" || selected_order_type == "BUY_LIMIT" || selected_order_type == "BUY") { //--- Check for buy orders
            if(proposedY_R1 + YS_R1 <= YD_R3 - GetScaledPx(MIN_LEVEL_GAP_PX)) { //--- Keep TP above entry with minimum gap
               canMove = true; //--- Allow movement
               ObjectSetInteger(0, REC1, OBJPROP_YDISTANCE, proposedY_R1); //--- Update REC1 y-position
               ObjectSetInteger(0, REC2, OBJPROP_YDISTANCE, proposedY_R1 + YS_R1); //--- Update REC2 y-position
               ObjectSetInteger(0, REC2, OBJPROP_YSIZE, MathMax(1, YD_R3 - (proposedY_R1 + YS_R1))); //--- Update REC2 y-size
            }
         }
         else { //--- Handle sell orders
            if(proposedY_R1 >= YD_R3 + YS_R3 + GetScaledPx(MIN_LEVEL_GAP_PX)) { //--- Keep TP below entry with minimum gap
               canMove = true; //--- Allow movement
               ObjectSetInteger(0, REC1, OBJPROP_YDISTANCE, proposedY_R1); //--- Update REC1 y-position
               ObjectSetInteger(0, REC4, OBJPROP_YDISTANCE, YD_R3 + YS_R3); //--- Update REC4 y-position
               ObjectSetInteger(0, REC4, OBJPROP_YSIZE, MathMax(1, proposedY_R1 - (YD_R3 + YS_R3))); //--- Update REC4 y-size
            }
         }

         if(canMove) { //--- If movement is valid
            datetime dt_TP = 0; //--- Variable for TP time
            double price_TP = 0; //--- Variable for TP price
            int window = 0; //--- Chart window
            int cur_xd_r1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XDISTANCE);
            int cur_yd_r1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YDISTANCE);
            int cur_ys_r1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YSIZE);

            ChartXYToTimePrice(0, cur_xd_r1, cur_yd_r1 + cur_ys_r1, window, dt_TP, price_TP); //--- Convert chart coordinates to time and price
            ObjectSetInteger(0, TP_HL, OBJPROP_TIME, dt_TP); //--- Update TP horizontal line time
            ObjectSetDouble(0, TP_HL, OBJPROP_PRICE, price_TP); //--- Update TP horizontal line price


            update_Text(REC1, BuildTPText()); //--- Update REC1 text
            SyncComputedRR();
            SyncPanelInputsFromLines();
         }

         ChartRedraw(0); //--- Redraw chart
      }

      if(movingState_R5) { //--- Handle REC5 (SL) movement
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false); //--- Disable chart scrolling
         bool canMove = false; //--- Flag to check if movement is valid
         int proposedY_R5 = mlbDownYD_R5 + MouseD_Y - mlbDownY5;
         if(selected_order_type == "BUY_STOP" || selected_order_type == "BUY_LIMIT" || selected_order_type == "BUY") { //--- Check for buy orders
            if(proposedY_R5 >= YD_R3 + YS_R3 + GetScaledPx(MIN_LEVEL_GAP_PX)) { //--- Keep SL below entry with minimum gap
               canMove = true; //--- Allow movement
               ObjectSetInteger(0, REC5, OBJPROP_YDISTANCE, proposedY_R5); //--- Update REC5 y-position
               ObjectSetInteger(0, REC4, OBJPROP_YDISTANCE, YD_R3 + YS_R3); //--- Update REC4 y-position
               ObjectSetInteger(0, REC4, OBJPROP_YSIZE, MathMax(1, proposedY_R5 - (YD_R3 + YS_R3))); //--- Update REC4 y-size
            }
         }
         else { //--- Handle sell orders
            if(proposedY_R5 + YS_R5 <= YD_R3 - GetScaledPx(MIN_LEVEL_GAP_PX)) { //--- Keep SL above entry with minimum gap
               canMove = true; //--- Allow movement
               ObjectSetInteger(0, REC5, OBJPROP_YDISTANCE, proposedY_R5); //--- Update REC5 y-position
               ObjectSetInteger(0, REC2, OBJPROP_YDISTANCE, proposedY_R5 + YS_R5); //--- Update REC2 y-position
               ObjectSetInteger(0, REC2, OBJPROP_YSIZE, MathMax(1, YD_R3 - (proposedY_R5 + YS_R5))); //--- Update REC2 y-size
            }
         }

         if(canMove) { //--- If movement is valid
            datetime dt_SL = 0; //--- Variable for SL time
            double price_SL = 0; //--- Variable for SL price
            int window = 0; //--- Chart window
            int cur_xd_r5 = (int)ObjectGetInteger(0, REC5, OBJPROP_XDISTANCE);
            int cur_yd_r5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YDISTANCE);
            int cur_ys_r5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YSIZE);

            ChartXYToTimePrice(0, cur_xd_r5, cur_yd_r5 + cur_ys_r5, window, dt_SL, price_SL); //--- Convert chart coordinates to time and price
            ObjectSetInteger(0, SL_HL, OBJPROP_TIME, dt_SL); //--- Update SL horizontal line time
            ObjectSetDouble(0, SL_HL, OBJPROP_PRICE, price_SL); //--- Update SL horizontal line price


            update_Text(REC5, BuildSLText()); //--- Update REC5 text
            SyncComputedRR();
            SyncPanelInputsFromLines();
         }

         ChartRedraw(0); //--- Redraw chart
      }

      if(movingState_R3) { //--- Handle REC3 (Entry) movement
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false); //--- Disable chart scrolling
         ObjectSetInteger(0, REC3, OBJPROP_XDISTANCE, mlbDownXD_R3 + MouseD_X - mlbDownX3); //--- Update REC3 x-position
         ObjectSetInteger(0, REC3, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y - mlbDownY3); //--- Update REC3 y-position

         ObjectSetInteger(0, REC1, OBJPROP_XDISTANCE, mlbDownXD_R1 + MouseD_X - mlbDownX1); //--- Update REC1 x-position
         ObjectSetInteger(0, REC1, OBJPROP_YDISTANCE, mlbDownYD_R1 + MouseD_Y - mlbDownY1); //--- Update REC1 y-position

         ObjectSetInteger(0, REC2, OBJPROP_XDISTANCE, mlbDownXD_R2 + MouseD_X - mlbDownX2); //--- Update REC2 x-position
         ObjectSetInteger(0, REC2, OBJPROP_YDISTANCE, mlbDownYD_R2 + MouseD_Y - mlbDownY2); //--- Update REC2 y-position

         ObjectSetInteger(0, REC4, OBJPROP_XDISTANCE, mlbDownXD_R4 + MouseD_X - mlbDownX4); //--- Update REC4 x-position
         ObjectSetInteger(0, REC4, OBJPROP_YDISTANCE, mlbDownYD_R4 + MouseD_Y - mlbDownY4); //--- Update REC4 y-position

         ObjectSetInteger(0, REC5, OBJPROP_XDISTANCE, mlbDownXD_R5 + MouseD_X - mlbDownX5); //--- Update REC5 x-position
         ObjectSetInteger(0, REC5, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y - mlbDownY5); //--- Update REC5 y-position

         datetime dt_PRC = 0, dt_SL1 = 0, dt_TP1 = 0; //--- Variables for time
         double price_PRC = 0, price_SL1 = 0, price_TP1 = 0; //--- Variables for price
         int window = 0; //--- Chart window
         int cur_xd_r3 = (int)ObjectGetInteger(0, REC3, OBJPROP_XDISTANCE);
         int cur_yd_r3 = (int)ObjectGetInteger(0, REC3, OBJPROP_YDISTANCE);
         int cur_ys_r3 = (int)ObjectGetInteger(0, REC3, OBJPROP_YSIZE);
         int cur_xd_r5 = (int)ObjectGetInteger(0, REC5, OBJPROP_XDISTANCE);
         int cur_yd_r5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YDISTANCE);
         int cur_ys_r5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YSIZE);
         int cur_xd_r1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XDISTANCE);
         int cur_yd_r1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YDISTANCE);
         int cur_ys_r1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YSIZE);

         ChartXYToTimePrice(0, cur_xd_r3, cur_yd_r3 + cur_ys_r3, window, dt_PRC, price_PRC); //--- Convert REC3 coordinates to time and price
         ChartXYToTimePrice(0, cur_xd_r5, cur_yd_r5 + cur_ys_r5, window, dt_SL1, price_SL1); //--- Convert REC5 coordinates to time and price
         ChartXYToTimePrice(0, cur_xd_r1, cur_yd_r1 + cur_ys_r1, window, dt_TP1, price_TP1); //--- Convert REC1 coordinates to time and price

         ObjectSetInteger(0, PR_HL, OBJPROP_TIME, dt_PRC); //--- Update entry horizontal line time
         ObjectSetDouble(0, PR_HL, OBJPROP_PRICE, price_PRC); //--- Update entry horizontal line price

         ObjectSetInteger(0, TP_HL, OBJPROP_TIME, dt_TP1); //--- Update TP horizontal line time
         ObjectSetDouble(0, TP_HL, OBJPROP_PRICE, price_TP1); //--- Update TP horizontal line price

         ObjectSetInteger(0, SL_HL, OBJPROP_TIME, dt_SL1); //--- Update SL horizontal line time
         ObjectSetDouble(0, SL_HL, OBJPROP_PRICE, price_SL1); //--- Update SL horizontal line price


         update_Text(REC1, BuildTPText()); //--- Update REC1 text
         update_Text(REC3, BuildOrderTypeText()); //--- Update REC3 text
         update_Text(REC5, BuildSLText()); //--- Update REC5 text
         SyncComputedRR();
         SyncPanelInputsFromLines();

         ChartRedraw(0); //--- Redraw chart
      }

      if(MouseState == 0) { //--- Check if mouse button is released
         movingState_R1 = false; //--- Disable REC1 movement
         movingState_R3 = false; //--- Disable REC3 movement
         movingState_R5 = false; //--- Disable REC5 movement
         is_tool_dragging = false;
         ChartSetInteger(0, CHART_MOUSE_SCROLL, true); //--- Enable chart scrolling
      }
      prevMouseState = MouseState; //--- Update previous mouse state
   }
}
//+------------------------------------------------------------------+
//| Create control panel                                             |
//+------------------------------------------------------------------+
void createControlPanel() {
   ObjectCreate(0, PANEL_BG, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_XDISTANCE, panel_x);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_YDISTANCE, panel_y);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_XSIZE, GetPanelScaledPx(286));
   ObjectSetInteger(0, PANEL_BG, OBJPROP_YSIZE, GetPanelScaledPx(290));
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BGCOLOR, C'048,048,052');
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BORDER_COLOR, C'095,095,105');
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BACK, false);

   createButton(MINIMIZE_BTN, CharToString(240), panel_x + GetPanelScaledPx(212), panel_y + GetPanelScaledPx(6), GetPanelScaledPx(30), GetPanelScaledPx(24), clrWhite, C'048,048,052', GetPanelScaledFontSize(14), C'048,048,052', false, "Wingdings");
   createButton(CLOSE_BTN, CharToString(251), panel_x + GetPanelScaledPx(246), panel_y + GetPanelScaledPx(6), GetPanelScaledPx(30), GetPanelScaledPx(24), clrWhite, C'048,048,052', GetPanelScaledFontSize(14), C'048,048,052', false, "Wingdings");

   createButton(RISK_EDIT, "Risk %", panel_x + GetPanelScaledPx(10), panel_y + GetPanelScaledPx(42), GetPanelScaledPx(86), GetPanelScaledPx(32), clrWhite, C'060,060,066', GetPanelScaledFontSize(10), C'085,085,095', false, "Segoe UI");

   ObjectCreate(0, RISK_VALUE_EDIT, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_XDISTANCE, panel_x + GetPanelScaledPx(100));
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_YDISTANCE, panel_y + GetPanelScaledPx(42));
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_XSIZE, GetPanelScaledPx(40));
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_YSIZE, GetPanelScaledPx(32));
   ObjectSetString(0, RISK_VALUE_EDIT, OBJPROP_TEXT, DoubleToString(DEFAULT_RISK_PERCENT, 2));
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_COLOR, C'210,210,215');
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_BGCOLOR, C'030,030,033');
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_BORDER_COLOR, C'085,085,095');
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetString(0, RISK_VALUE_EDIT, OBJPROP_FONT, "Segoe UI");
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_FONTSIZE, GetPanelScaledFontSize(10));

   ObjectCreate(0, ENTRY_EDIT, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_XDISTANCE, panel_x + GetPanelScaledPx(146));
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_YDISTANCE, panel_y + GetPanelScaledPx(42));
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_XSIZE, GetPanelScaledPx(130));
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_YSIZE, GetPanelScaledPx(32));
   ObjectSetString(0, ENTRY_EDIT, OBJPROP_TEXT, "Entry");
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_COLOR, C'155,155,165');
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_BGCOLOR, C'030,030,033');
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_BORDER_COLOR, C'085,085,095');
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetString(0, ENTRY_EDIT, OBJPROP_FONT, "Segoe UI");
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_FONTSIZE, GetPanelScaledFontSize(11));

   ObjectCreate(0, SL_EDIT_FIELD, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_XDISTANCE, panel_x + GetPanelScaledPx(10));
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_YDISTANCE, panel_y + GetPanelScaledPx(80));
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_XSIZE, GetPanelScaledPx(130));
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_YSIZE, GetPanelScaledPx(32));
   ObjectSetString(0, SL_EDIT_FIELD, OBJPROP_TEXT, "SL points");
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_COLOR, C'155,155,165');
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_BGCOLOR, C'030,030,033');
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_BORDER_COLOR, C'085,085,095');
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetString(0, SL_EDIT_FIELD, OBJPROP_FONT, "Segoe UI");
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_FONTSIZE, GetPanelScaledFontSize(11));

   ObjectCreate(0, TP_EDIT_FIELD, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_XDISTANCE, panel_x + GetPanelScaledPx(146));
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_YDISTANCE, panel_y + GetPanelScaledPx(80));
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_XSIZE, GetPanelScaledPx(130));
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_YSIZE, GetPanelScaledPx(32));
   ObjectSetString(0, TP_EDIT_FIELD, OBJPROP_TEXT, "TP points");
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_COLOR, C'155,155,165');
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_BGCOLOR, C'030,030,033');
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_BORDER_COLOR, C'085,085,095');
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetString(0, TP_EDIT_FIELD, OBJPROP_FONT, "Segoe UI");
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_FONTSIZE, GetPanelScaledFontSize(11));

   createButton(BUY_BTN, "Buy", panel_x + GetPanelScaledPx(10), panel_y + GetPanelScaledPx(124), GetPanelScaledPx(102), GetPanelScaledPx(32), clrWhite, C'025,095,065', GetPanelScaledFontSize(12), C'070,150,110', false, "Segoe UI");
   createButton(SELL_BTN, "Sell", panel_x + GetPanelScaledPx(174), panel_y + GetPanelScaledPx(124), GetPanelScaledPx(102), GetPanelScaledPx(32), clrWhite, C'130,040,045', GetPanelScaledFontSize(12), C'185,085,090', false, "Segoe UI");

   createButton(SELL_STOP_BTN, "Sell Stop", panel_x + GetPanelScaledPx(10), panel_y + GetPanelScaledPx(164), GetPanelScaledPx(130), GetPanelScaledPx(34), clrWhite, C'060,060,066', GetPanelScaledFontSize(12), C'095,095,105', false, "Segoe UI");
   createButton(BUY_STOP_BTN, "Buy Stop", panel_x + GetPanelScaledPx(146), panel_y + GetPanelScaledPx(164), GetPanelScaledPx(130), GetPanelScaledPx(34), clrWhite, C'060,060,066', GetPanelScaledFontSize(12), C'095,095,105', false, "Segoe UI");
   createButton(SELL_LIMIT_BTN, "Sell Limit", panel_x + GetPanelScaledPx(10), panel_y + GetPanelScaledPx(204), GetPanelScaledPx(130), GetPanelScaledPx(34), clrWhite, C'060,060,066', GetPanelScaledFontSize(12), C'095,095,105', false, "Segoe UI");
   createButton(BUY_LIMIT_BTN, "Buy Limit", panel_x + GetPanelScaledPx(146), panel_y + GetPanelScaledPx(204), GetPanelScaledPx(130), GetPanelScaledPx(34), clrWhite, C'060,060,066', GetPanelScaledFontSize(12), C'095,095,105', false, "Segoe UI");

   createButton(CANCEL_BTN, "Cancel", panel_x + GetPanelScaledPx(10), panel_y + GetPanelScaledPx(250), GetPanelScaledPx(130), GetPanelScaledPx(34), clrWhite, C'060,060,066', GetPanelScaledFontSize(12), C'095,095,105', false, "Segoe UI");
   createButton(PLACE_ORDER_BTN, "Send", panel_x + GetPanelScaledPx(146), panel_y + GetPanelScaledPx(250), GetPanelScaledPx(130), GetPanelScaledPx(34), clrWhite, C'020,110,165', GetPanelScaledFontSize(12), C'070,160,210', false, "Segoe UI");

   UpdateRiskModeButtonText();
   SetPanelMinimized(false);
}
//+------------------------------------------------------------------+
//| Show main tool                                                   |
//+------------------------------------------------------------------+
void showTool() {
   // Hide panel
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BACK, false); //--- Hide panel background
   ObjectSetInteger(0, RISK_EDIT, OBJPROP_BACK, false);
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_BACK, false);
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_BACK, false);
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_BACK, false);
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_BACK, false);
   ObjectSetInteger(0, BUY_BTN, OBJPROP_BACK, false);
   ObjectSetInteger(0, SELL_BTN, OBJPROP_BACK, false);
   ObjectSetInteger(0, BUY_STOP_BTN, OBJPROP_BACK, false); //--- Hide Buy Stop button
   ObjectSetInteger(0, SELL_STOP_BTN, OBJPROP_BACK, false); //--- Hide Sell Stop button
   ObjectSetInteger(0, BUY_LIMIT_BTN, OBJPROP_BACK, false); //--- Hide Buy Limit button
   ObjectSetInteger(0, SELL_LIMIT_BTN, OBJPROP_BACK, false); //--- Hide Sell Limit button
   ObjectSetInteger(0, PLACE_ORDER_BTN, OBJPROP_BACK, false); //--- Hide Place Order button
   ObjectSetInteger(0, CANCEL_BTN, OBJPROP_BACK, false); //--- Hide Cancel button
   ObjectSetInteger(0, MINIMIZE_BTN, OBJPROP_BACK, false); //--- Hide Minimize button
   ObjectSetInteger(0, CLOSE_BTN, OBJPROP_BACK, false); //--- Hide Close button

   // Create main tool 150 pixels from the right edge
   int chart_width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS); //--- Get chart width
   int tool_width = GetScaledPx(300); //--- Risk-reward tool width
   int tool_x = chart_width - tool_width - 10; //--- Calculate tool x-position

   if(selected_order_type == "BUY_STOP" || selected_order_type == "BUY_LIMIT" || selected_order_type == "BUY") { //--- Check for buy orders
      // Buy orders: TP at top, entry in middle, SL at bottom
      createButton(REC1, "", tool_x, GetScaledPx(20), tool_width, GetScaledPx(30), clrWhite, clrGreen, GetScaledFontSize(10), clrBlack, false, "Arial Black"); //--- Create TP rectangle

      xd1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XDISTANCE); //--- Get REC1 x-distance
      yd1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YDISTANCE); //--- Get REC1 y-distance
      xs1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XSIZE); //--- Get REC1 x-size
      ys1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YSIZE); //--- Get REC1 y-size

      xd2 = xd1; //--- Set REC2 x-distance
      yd2 = yd1 + ys1; //--- Set REC2 y-distance
      xs2 = xs1; //--- Set REC2 x-size
      ys2 = GetScaledPx(100); //--- Set REC2 y-size

      xd3 = xd2; //--- Set REC3 x-distance
      yd3 = yd2 + ys2; //--- Set REC3 y-distance
      xs3 = xs2; //--- Set REC3 x-size
      ys3 = GetScaledPx(30); //--- Set REC3 y-size

      xd4 = xd3; //--- Set REC4 x-distance
      yd4 = yd3 + ys3; //--- Set REC4 y-distance
      xs4 = xs3; //--- Set REC4 x-size
      ys4 = GetScaledPx(100); //--- Set REC4 y-size

      xd5 = xd4; //--- Set REC5 x-distance
      yd5 = yd4 + ys4; //--- Set REC5 y-distance
      xs5 = xs4; //--- Set REC5 x-size
      ys5 = GetScaledPx(30); //--- Set REC5 y-size
   }
   else { //--- Handle sell orders
      // Sell orders: SL at top, entry in middle, TP at bottom
      createButton(REC5, "", tool_x, GetScaledPx(20), tool_width, GetScaledPx(30), clrWhite, clrRed, GetScaledFontSize(10), clrBlack, false, "Arial Black"); //--- Create SL rectangle

      xd5 = (int)ObjectGetInteger(0, REC5, OBJPROP_XDISTANCE); //--- Get REC5 x-distance
      yd5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YDISTANCE); //--- Get REC5 y-distance
      xs5 = (int)ObjectGetInteger(0, REC5, OBJPROP_XSIZE); //--- Get REC5 x-size
      ys5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YSIZE); //--- Get REC5 y-size

      xd2 = xd5; //--- Set REC2 x-distance
      yd2 = yd5 + ys5; //--- Set REC2 y-distance
      xs2 = xs5; //--- Set REC2 x-size
      ys2 = GetScaledPx(100); //--- Set REC2 y-size

      xd3 = xd2; //--- Set REC3 x-distance
      yd3 = yd2 + ys2; //--- Set REC3 y-distance
      xs3 = xs2; //--- Set REC3 x-size
      ys3 = GetScaledPx(30); //--- Set REC3 y-size

      xd4 = xd3; //--- Set REC4 x-distance
      yd4 = yd3 + ys3; //--- Set REC4 y-distance
      xs4 = xs3; //--- Set REC4 x-size
      ys4 = GetScaledPx(100); //--- Set REC4 y-size

      xd1 = xd4; //--- Set REC1 x-distance
      yd1 = yd4 + ys4; //--- Set REC1 y-distance
      xs1 = xs4; //--- Set REC1 x-size
      ys1 = GetScaledPx(30); //--- Set REC1 y-size
   }

   datetime dt_tp = 0, dt_sl = 0, dt_prc = 0; //--- Variables for time
   double price_tp = 0, price_sl = 0, price_prc = 0; //--- Variables for price
   int window = 0; //--- Chart window

   ChartXYToTimePrice(0, xd1, yd1 + ys1, window, dt_tp, price_tp); //--- Convert REC1 coordinates to time and price
   ChartXYToTimePrice(0, xd3, yd3 + ys3, window, dt_prc, price_prc); //--- Convert REC3 coordinates to time and price
   ChartXYToTimePrice(0, xd5, yd5 + ys5, window, dt_sl, price_sl); //--- Convert REC5 coordinates to time and price

   createHL(TP_HL, dt_tp, price_tp, clrTeal); //--- Create TP horizontal line
   createHL(PR_HL, dt_prc, price_prc, clrBlue); //--- Create entry horizontal line
   createHL(SL_HL, dt_sl, price_sl, clrRed); //--- Create SL horizontal line

   if(selected_order_type == "BUY" || selected_order_type == "SELL") {
      double mkt_entry = (selected_order_type == "BUY") ? SymbolInfoDouble(Symbol(), SYMBOL_ASK) : SymbolInfoDouble(Symbol(), SYMBOL_BID);
      if(mkt_entry > 0) {
         double sl_offset = mkt_entry * (DEFAULT_MARKET_SL_OFFSET_PCT / 100.0);
         double tp_offset = mkt_entry * (DEFAULT_MARKET_TP_OFFSET_PCT / 100.0);
         if(sl_offset <= 0) sl_offset = 100 * _Point;
         if(tp_offset <= 0) tp_offset = 200 * _Point;

         ObjectSetDouble(0, PR_HL, OBJPROP_PRICE, mkt_entry);
         if(selected_order_type == "BUY") {
            ObjectSetDouble(0, SL_HL, OBJPROP_PRICE, mkt_entry - sl_offset);
            ObjectSetDouble(0, TP_HL, OBJPROP_PRICE, mkt_entry + tp_offset);
         } else {
            ObjectSetDouble(0, SL_HL, OBJPROP_PRICE, mkt_entry + sl_offset);
            ObjectSetDouble(0, TP_HL, OBJPROP_PRICE, mkt_entry - tp_offset);
         }
      }
   }

   if(selected_order_type == "BUY_STOP" || selected_order_type == "BUY_LIMIT" || selected_order_type == "BUY") { //--- Check for buy orders
      createButton(REC2, "", xd2, yd2, xs2, ys2, clrWhite, clrHoneydew, GetScaledFontSize(10), clrBlack, true); //--- Create REC2
      createButton(REC3, "", xd3, yd3, xs3, ys3, clrBlack, clrLightGray, GetScaledFontSize(10), clrBlack, false, "Arial Black"); //--- Create REC3
      createButton(REC4, "", xd4, yd4, xs4, ys4, clrWhite, clrLinen, GetScaledFontSize(10), clrBlack, true); //--- Create REC4
      createButton(REC5, "", xd5, yd5, xs5, ys5, clrWhite, clrRed, GetScaledFontSize(10), clrBlack, false, "Arial Black"); //--- Create REC5
   }
   else { //--- Handle sell orders
      createButton(REC2, "", xd2, yd2, xs2, ys2, clrWhite, clrLinen, GetScaledFontSize(10), clrBlack, true); //--- Create REC2
      createButton(REC3, "", xd3, yd3, xs3, ys3, clrBlack, clrLightGray, GetScaledFontSize(10), clrBlack, false, "Arial Black"); //--- Create REC3
      createButton(REC4, "", xd4, yd4, xs4, ys4, clrWhite, clrHoneydew, GetScaledFontSize(10), clrBlack, true); //--- Create REC4
      createButton(REC1, "", xd1, yd1, xs1, ys1, clrWhite, clrGreen, GetScaledFontSize(10), clrBlack, false, "Arial Black"); //--- Create REC1
   }


   update_Text(REC1, BuildTPText()); //--- Update REC1 text
   update_Text(REC3, BuildOrderTypeText()); //--- Update REC3 text
   update_Text(REC5, BuildSLText()); //--- Update REC5 text
   SyncComputedRR();
   SyncPanelInputsFromLines();

   tool_visible = true; //--- Set tool visibility flag
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true); //--- Enable mouse move events
   ChartRedraw(0); //--- Redraw chart
}

//+------------------------------------------------------------------+
//| Show control panel                                               |
//+------------------------------------------------------------------+
void showPanel() {
   // Show panel
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BACK, false); //--- Show panel background
   ObjectSetInteger(0, RISK_EDIT, OBJPROP_BACK, false);
   ObjectSetInteger(0, RISK_VALUE_EDIT, OBJPROP_BACK, false);
   ObjectSetInteger(0, ENTRY_EDIT, OBJPROP_BACK, false);
   ObjectSetInteger(0, SL_EDIT_FIELD, OBJPROP_BACK, false);
   ObjectSetInteger(0, TP_EDIT_FIELD, OBJPROP_BACK, false);
   ObjectSetInteger(0, BUY_BTN, OBJPROP_BACK, false);
   ObjectSetInteger(0, SELL_BTN, OBJPROP_BACK, false);
   ObjectSetInteger(0, BUY_STOP_BTN, OBJPROP_BACK, false); //--- Show Buy Stop button
   ObjectSetInteger(0, SELL_STOP_BTN, OBJPROP_BACK, false); //--- Show Sell Stop button
   ObjectSetInteger(0, BUY_LIMIT_BTN, OBJPROP_BACK, false); //--- Show Buy Limit button
   ObjectSetInteger(0, SELL_LIMIT_BTN, OBJPROP_BACK, false); //--- Show Sell Limit button
   ObjectSetInteger(0, PLACE_ORDER_BTN, OBJPROP_BACK, false); //--- Show Place Order button
   ObjectSetInteger(0, CANCEL_BTN, OBJPROP_BACK, false); //--- Show Cancel button
   ObjectSetInteger(0, MINIMIZE_BTN, OBJPROP_BACK, false); //--- Show Minimize button
   ObjectSetInteger(0, CLOSE_BTN, OBJPROP_BACK, false); //--- Show Close button

   // Reset panel state
   update_Text(PLACE_ORDER_BTN, "Send"); //--- Reset Send button text
   ObjectSetString(0, ENTRY_EDIT, OBJPROP_TEXT, "Entry");
   ObjectSetString(0, SL_EDIT_FIELD, OBJPROP_TEXT, "SL points");
   ObjectSetString(0, TP_EDIT_FIELD, OBJPROP_TEXT, "TP points");
   SetPanelMinimized(false);
   selected_order_type = ""; //--- Clear selected order type
   tool_visible = false; //--- Hide tool
   is_tool_dragging = false;
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false); //--- Disable mouse move events
   ChartRedraw(0); //--- Redraw chart
}

//+------------------------------------------------------------------+
//| Place order based on selected type                               |
//+------------------------------------------------------------------+
void placeOrder() {
   double price = Get_Price_d(PR_HL); //--- Get entry price
   double sl = Get_Price_d(SL_HL); //--- Get stop-loss price
   double tp = Get_Price_d(TP_HL); //--- Get take-profit price

   double manual_entry = ReadPriceInput(ENTRY_EDIT);
   double sl_points = StringToDouble(ObjectGetString(0, SL_EDIT_FIELD, OBJPROP_TEXT));
   double tp_points = StringToDouble(ObjectGetString(0, TP_EDIT_FIELD, OBJPROP_TEXT));

   bool is_buy_side = (selected_order_type == "BUY_STOP" || selected_order_type == "BUY_LIMIT" || selected_order_type == "BUY");
   if(selected_order_type == "BUY" || selected_order_type == "SELL") {
      double mkt_entry = is_buy_side ? SymbolInfoDouble(Symbol(), SYMBOL_ASK) : SymbolInfoDouble(Symbol(), SYMBOL_BID);
      if(mkt_entry > 0) price = mkt_entry;
   } else if(manual_entry > 0) {
      price = manual_entry;
   }

   if(sl_points > 0) sl = is_buy_side ? price - sl_points * _Point : price + sl_points * _Point;
   if(tp_points > 0) tp = is_buy_side ? price + tp_points * _Point : price - tp_points * _Point;

   lot_size = GetLotByMode(price, sl);

   string symbol = Symbol(); //--- Get current symbol
   datetime expiration = TimeCurrent() + 3600 * 24; //--- Set 24-hour order expiration

   // Validate lot size
   if(lot_size <= 0) { //--- Check if lot size is valid
      Print("Invalid lot size: ", lot_size); //--- Print error message
      return; //--- Exit function
   }

   // Validate prices
   if(price <= 0 || sl <= 0 || tp <= 0) { //--- Check if prices are valid
      Print("Invalid prices: Entry=", price, ", SL=", sl, ", TP=", tp, " (all must be positive)"); //--- Print error message
      return; //--- Exit function
   }

   // Validate price relationships based on order type
   if(selected_order_type == "BUY_STOP" || selected_order_type == "BUY_LIMIT" || selected_order_type == "BUY") { //--- Check for buy orders
      if(sl >= price) { //--- Check if SL is below entry
         Print("Invalid SL for ", selected_order_type, ": SL=", sl, " must be below Entry=", price); //--- Print error message
         return; //--- Exit function
      }
      if(tp <= price) { //--- Check if TP is above entry
         Print("Invalid TP for ", selected_order_type, ": TP=", tp, " must be above Entry=", price); //--- Print error message
         return; //--- Exit function
      }
   }
   else if(selected_order_type == "SELL_STOP" || selected_order_type == "SELL_LIMIT" || selected_order_type == "SELL") { //--- Check for sell orders
      if(sl <= price) { //--- Check if SL is above entry
         Print("Invalid SL for ", selected_order_type, ": SL=", sl, " must be above Entry=", price); //--- Print error message
         return; //--- Exit function
      }
      if(tp >= price) { //--- Check if TP is below entry
         Print("Invalid TP for ", selected_order_type, ": TP=", tp, " must be below Entry=", price); // AMPK--- Print error message
         return; //--- Exit function
      }
   }
   else { //--- Handle invalid order type
      Print("Invalid order type: ", selected_order_type); //--- Print error message
      return; //--- Exit function
   }

   // Place the order
   if(selected_order_type == "BUY_STOP") { //--- Handle Buy Stop order
      if(!obj_Trade.BuyStop(lot_size, price, symbol, sl, tp, ORDER_TIME_DAY, expiration)) { //--- Attempt to place Buy Stop order
         Print("Buy Stop failed: Entry=", price, ", SL=", sl, ", TP=", tp, ", Error=", GetLastError()); //--- Print error message
      }
      else { //--- Order placed successfully
         Print("Buy Stop placed: Entry=", price, ", SL=", sl, ", TP=", tp); //--- Print success message
      }
   }
   else if(selected_order_type == "SELL_STOP") { //--- Handle Sell Stop order
      if(!obj_Trade.SellStop(lot_size, price, symbol, sl, tp, ORDER_TIME_DAY, expiration)) { //--- Attempt to place Sell Stop order
         Print("Sell Stop failed: Entry=", price, ", SL=", sl, ", TP=", tp, ", Error=", GetLastError()); //--- Print error message
      }
      else { //--- Order placed successfully
         Print("Sell Stop placed: Entry=", price, ", SL=", sl, ", TP=", tp); //--- Print success message
      }
   }
   else if(selected_order_type == "BUY_LIMIT") { //--- Handle Buy Limit order
      if(!obj_Trade.BuyLimit(lot_size, price, symbol, sl, tp, ORDER_TIME_DAY, expiration)) { //--- Attempt to place Buy Limit order
         Print("Buy Limit failed: Entry=", price, ", SL=", sl, ", TP=", tp, ", Error=", GetLastError()); //--- Print error message
      }
      else { //--- Order placed successfully
         Print("Buy Limit placed: Entry=", price, ", SL=", sl, ", TP=", tp); //--- Print success message
      }
   }
   else if(selected_order_type == "SELL_LIMIT") { //--- Handle Sell Limit order
      if(!obj_Trade.SellLimit(lot_size, price, symbol, sl, tp, ORDER_TIME_DAY, expiration)) { //--- Attempt to place Sell Limit order
         Print("Sell Limit failed: Entry=", price, ", SL=", sl, ", TP=", tp, ", Error=", GetLastError()); //--- Print error message
      }
      else { //--- Order placed successfully
         Print("Sell Limit placed: Entry=", price, ", SL=", sl, ", TP=", tp); //--- Print success message
      }
   }
   else if(selected_order_type == "BUY") {
      if(!obj_Trade.Buy(lot_size, symbol, 0.0, sl, tp, "GUI Send Buy")) {
         Print("Buy failed: SL=", sl, ", TP=", tp, ", Error=", GetLastError());
      } else {
         Print("Buy sent: SL=", sl, ", TP=", tp);
      }
   }
   else if(selected_order_type == "SELL") {
      if(!obj_Trade.Sell(lot_size, symbol, 0.0, sl, tp, "GUI Send Sell")) {
         Print("Sell failed: SL=", sl, ", TP=", tp, ", Error=", GetLastError());
      } else {
         Print("Sell sent: SL=", sl, ", TP=", tp);
      }
   }
}

//+------------------------------------------------------------------+
//| Create button                                                    |
//+------------------------------------------------------------------+
bool createButton(string objName, string text, int xD, int yD, int xS, int yS,
                  color clrTxt, color clrBG, int fontsize = 12,
                  color clrBorder = clrNONE, bool isBack = false, string font = "Calibri") {
   ResetLastError(); //--- Reset last error code
   if(!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, 0)) { //--- Create button object
      Print(__FUNCTION__, ": Failed to create Btn: Error Code: ", GetLastError()); //--- Print error message
      return false; //--- Return failure
   }
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, xD); //--- Set button x-position
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, yD); //--- Set button y-position
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, xS); //--- Set button width
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, yS); //--- Set button height
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER); //--- Set button corner
   ObjectSetString(0, objName, OBJPROP_TEXT, text); //--- Set button text
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontsize); //--- Set font size
   ObjectSetString(0, objName, OBJPROP_FONT, font); //--- Set font
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrTxt); //--- Set text color
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrBG); //--- Set background color
   if(objName == REC1 || objName == REC2 || objName == REC3 || objName == REC4 || objName == REC5)
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrNONE);
   else
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrBorder);
   ObjectSetInteger(0, objName, OBJPROP_BACK, isBack); //--- Set background/foreground
   ObjectSetInteger(0, objName, OBJPROP_STATE, false); //--- Reset button state
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false); //--- Disable selection
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false); //--- Disable selected state

   ChartRedraw(0); //--- Redraw chart
   return true; //--- Return success
}

//+------------------------------------------------------------------+
//| Create horizontal line                                           |
//+------------------------------------------------------------------+
bool createHL(string objName, datetime time1, double price1, color clr) {
   ResetLastError(); //--- Reset last error code
   if(!ObjectCreate(0, objName, OBJ_HLINE, 0, time1, price1)) { //--- Create horizontal line
      Print(__FUNCTION__, ": Failed to create HL: Error Code: ", GetLastError()); //--- Print error message
      return false; //--- Return failure
   }
   ObjectSetInteger(0, objName, OBJPROP_TIME, time1); //--- Set line time
   ObjectSetDouble(0, objName, OBJPROP_PRICE, price1); //--- Set line price
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr); //--- Set line color
   ObjectSetInteger(0, objName, OBJPROP_BACK, true); //--- Set to foreground
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT); //--- Set line style

   ChartRedraw(0); //--- Redraw chart
   return true; //--- Return success
}

//+------------------------------------------------------------------+
//| Delete main tool objects                                         |
//+------------------------------------------------------------------+
void deleteObjects() {
   ObjectDelete(0, REC1); //--- Delete REC1 object
   ObjectDelete(0, REC2); //--- Delete REC2 object
   ObjectDelete(0, REC3); //--- Delete REC3 object
   ObjectDelete(0, REC4); //--- Delete REC4 object
   ObjectDelete(0, REC5); //--- Delete REC5 object
   ObjectDelete(0, TP_HL); //--- Delete TP horizontal line
   ObjectDelete(0, SL_HL); //--- Delete SL horizontal line
   ObjectDelete(0, PR_HL); //--- Delete entry horizontal line
   ChartRedraw(0); //--- Redraw chart
}

//+------------------------------------------------------------------+
//| Delete control panel objects                                     |
//+------------------------------------------------------------------+
void deletePanel() {
   ObjectDelete(0, PANEL_BG); //--- Delete panel background
   ObjectDelete(0, PRICE_LABEL); //--- Delete price label
   ObjectDelete(0, SL_LABEL); //--- Delete SL label
   ObjectDelete(0, TP_LABEL); //--- Delete TP label
   ObjectDelete(0, BUY_STOP_BTN); //--- Delete Buy Stop button
   ObjectDelete(0, SELL_STOP_BTN); //--- Delete Sell Stop button
   ObjectDelete(0, BUY_LIMIT_BTN); //--- Delete Buy Limit button
   ObjectDelete(0, SELL_LIMIT_BTN); //--- Delete Sell Limit button
   ObjectDelete(0, PLACE_ORDER_BTN); //--- Delete Place Order button
   ObjectDelete(0, CANCEL_BTN); //--- Delete Cancel button
   ObjectDelete(0, MINIMIZE_BTN); //--- Delete Minimize button
   ObjectDelete(0, CLOSE_BTN); //--- Delete Close button
   ObjectDelete(0, BUY_BTN);
   ObjectDelete(0, SELL_BTN);
   ObjectDelete(0, RISK_EDIT);
   ObjectDelete(0, RISK_VALUE_EDIT);
   ObjectDelete(0, ENTRY_EDIT);
   ObjectDelete(0, SL_EDIT_FIELD);
   ObjectDelete(0, TP_EDIT_FIELD);
   ChartRedraw(0); //--- Redraw chart
}
