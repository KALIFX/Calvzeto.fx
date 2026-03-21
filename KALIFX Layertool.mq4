//+------------------------------------------------------------------+
//|                        KALIFX Layertool.mq4                      |
//|                                                                  |
//+------------------------------------------------------------------+
#property strict
#property copyright   "COPYRIGHT 2025, KALIFX"
#property link        "kalifxlab.com"
#property description "Kali Layers Toolbox"
#property version     "1.2"
// ===== Inputs ===== 

input int      InpNumPendingOrders = 5;     // Number of pending orders
input double   InpLots             = 0.10;  // Lot size per order
input int      InpExpirationMin    = 120;   // Pending order expiry (minutes)
input double   BE_GroupDistance    = 800;    // Max points to group trades for BE
input double   BE_Trigger          = 1000;    // Profit (points) to trigger BE
input double   BE_Offset           = 200;     // Offset (points) when moving to BE
input int      InpSlippage         = 3;     // Max slippage (points)
//--- Inputs for zone line offset
input int ZoneOffsetPips = 100;      // Offset distance in pips
input int      InpMagic            = 20250813; // EA magic number
  

// --- Button names
#define BTN_ORDER_TYPE "btnOrderType"
#define BTN_DRAW_ZONE  "btnDrawZone"
#define BTN_START      "btnStart"
#define BTN_SL         "btnSL"
#define BTN_TP         "btnTP"
#define BTN_SET        "btnSetSLTP"
#define BTN_CLOSE_ALL  "btnCloseAll"
#define BTN_DEL_PEND   "btnDeletePending"
#define BTN_BE         "btnBE"
#define PANEL_BG       "panelBackground"
#define BTN_TOGGLE_PANEL "btnTogglePanel"
#define ZONE_DIST_LABEL "zone_distance_label"
#define PANEL_TITLE    "panelTitle"

// --- Line names
#define ZONE_TOP       "zone_top"
#define ZONE_BOTTOM    "zone_bottom"
#define SL_LINE        "sl_line"
#define TP_LINE        "tp_line"

// ===== UI Layout =====
#define BTN_W   164
#define BTN_H   26
#define PAD     8
#define ORGX    18
#define ORGY    40

// ===== Theme (flat / modern) =====
#define CLR_PANEL_BG      C'22,26,33'
#define CLR_PANEL_BORDER  C'40,46,56'
#define CLR_TEXT_PRIMARY  C'237,242,247'
#define CLR_ACCENT_BLUE   C'33,150,243'
#define CLR_ACCENT_GREEN  C'46,204,113'
#define CLR_ACCENT_ORANGE C'245,166,35'
#define CLR_ACCENT_RED    C'231,76,60'
#define CLR_ACCENT_RED_D  C'192,57,43'
#define CLR_ACCENT_TEAL   C'0,188,212'
#define CLR_ACCENT_AMBER  C'255,193,7'
#define CLR_ACCENT_GRAY   C'96,106,122'

// ===== State =====
enum EOrderTypeIdx { OT_BUY_STOP=0, OT_SELL_STOP=1, OT_BUY_LIMIT=2, OT_SELL_LIMIT=3 };
int    gOrderTypeIdx = OT_BUY_STOP;
int gPanelOrigX[];
double lastTop = 0, lastBottom = 0;


bool   gZoneVisible   = false;
bool gPanelVisible = true;
bool   gSLVisible     = false;
bool   gTPVisible     = false;
bool gPanelHidden = false; // Tracks panel visibility


bool   gUseSLTPForNew = false;
double gDefaultSL     = 0.0;
double gDefaultTP     = 0.0;

bool   gBEEnabled     = false;

//+------------------------------------------------------------------+
//| Init / Deinit                                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   // Read saved hidden state
   if(GlobalVariableCheck("PanelHidden"))
      gPanelHidden = (GlobalVariableGet("PanelHidden") == 1);

   // Always create panel
   CreatePanel();

   // Apply hidden state
   if(gPanelHidden) HidePanel();
   
   EventSetTimer(1); // Update every 1 seconds

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();

   // List of your panel objects
   string panelObjects[] =
   {
      "btnBE",
      "btnCloseAll",
      "btnDeletePending",
      "btnDrawZone",
      "btnOrderType",
      "btnSL",
      "btnSetSLTP",
      "btnStart",
      "btnTP",
      "btnTogglePanel",
      "panelBackground",
      "panelTitle",
      "zone_distance_label"
   };

   int deleted = 0;

   for(int i = 0; i < ArraySize(panelObjects); i++)
   {
      if(ObjectFind(0, panelObjects[i]) >= 0)
      {
         if(ObjectDelete(0, panelObjects[i]))
            deleted++;
      }
   }

   ChartRedraw(0);
   PrintFormat("Deinit(%d): deleted %d panel objects", reason, deleted);
}




void OnTick()
{
    ApplyBreakEven();

}

void OnTimer()
{
    double top = ObjectGetDouble(0, ZONE_TOP, OBJPROP_PRICE);
    double bottom = ObjectGetDouble(0, ZONE_BOTTOM, OBJPROP_PRICE);

    if(top != lastTop || bottom != lastBottom)
    {
        lastTop = top;
        lastBottom = bottom;
        UpdateZoneDistanceLabel();
    }
}

//+------------------------------------------------------------------+
//| Panel Creation                                                   |
//+------------------------------------------------------------------+
void CreatePanel()
{
    const int rows   = 7; // total rows including SET SL/TP
    const int titleH = 22;
    const int totalH = titleH + (BTN_H + PAD) * rows + PAD + 8;

    // Flat panel background
    CreateRectLabelRounded(PANEL_BG, ORGX - 12, ORGY - 14, BTN_W + 24, totalH, CLR_PANEL_BG, CLR_PANEL_BORDER);
    CreatePanelTitle(PANEL_TITLE, "KALI LAYERS TOOLBOX", ORGX, ORGY - 8, BTN_W, titleH);

    int y = ORGY + titleH;

    // Main buttons
    CreateModernButton(BTN_ORDER_TYPE, OrderTypeLabel(), ORGX, y, BTN_W, BTN_H, CLR_ACCENT_BLUE); y += BTN_H + PAD;
    CreateModernButton(BTN_DRAW_ZONE , "Draw Zone"     , ORGX, y, BTN_W, BTN_H, CLR_ACCENT_GREEN); y += BTN_H + PAD;
    CreateModernButton(BTN_START     , "Start"         , ORGX, y, BTN_W, BTN_H, CLR_ACCENT_ORANGE); y += BTN_H + PAD;

    // SL and TP side-by-side
    CreateModernButton(BTN_SL, "SL", ORGX, y, BTN_W/2 - 3, BTN_H, CLR_ACCENT_RED);
    CreateModernButton(BTN_TP, "TP", ORGX + BTN_W/2 + 3, y, BTN_W/2 - 3, BTN_H, CLR_ACCENT_TEAL);
    y += BTN_H + PAD;

    // SET SL/TP button immediately below SL/TP
    CreateModernButton(BTN_SET, "Set SL/TP", ORGX, y, BTN_W, BTN_H, CLR_ACCENT_BLUE);
    y += BTN_H + PAD;

    // Remaining buttons
    CreateModernButton(BTN_CLOSE_ALL, "Close All", ORGX, y, BTN_W, BTN_H, CLR_ACCENT_RED); y += BTN_H + PAD;
    CreateModernButton(BTN_DEL_PEND, "Del Pending", ORGX, y, BTN_W, BTN_H, CLR_ACCENT_RED_D); y += BTN_H + PAD;
    CreateModernButton(BTN_BE, "BE OFF", ORGX, y, BTN_W, BTN_H, CLR_ACCENT_AMBER); y += BTN_H + PAD;

    // Toggle button (manual positioning)
    int toggleX = ORGX + BTN_W + 14;
    int toggleY = ORGY - 8;
    CreateModernButton(BTN_TOGGLE_PANEL, "-", toggleX, toggleY, 18, titleH, CLR_ACCENT_GRAY);

    // Store original X positions
    string panelObjects[] = {PANEL_BG, PANEL_TITLE, BTN_ORDER_TYPE, BTN_DRAW_ZONE, BTN_START,
                             BTN_SL, BTN_TP, BTN_SET, BTN_CLOSE_ALL, BTN_DEL_PEND, BTN_BE};

    ArrayResize(gPanelOrigX, ArraySize(panelObjects));
    for(int i = 0; i < ArraySize(panelObjects); i++)
    {
        if(ObjectFind(0, panelObjects[i]) >= 0)
            gPanelOrigX[i] = ObjectGetInteger(0, panelObjects[i], OBJPROP_XDISTANCE);
    }
}

void HidePanel()
{
   string panelObjects[] = {PANEL_BG, PANEL_TITLE, BTN_ORDER_TYPE, BTN_DRAW_ZONE, BTN_START,
                            BTN_SL, BTN_TP, BTN_CLOSE_ALL, BTN_DEL_PEND, BTN_BE, BTN_SET, BTN_TOGGLE_PANEL};

   for(int i=0; i<ArraySize(panelObjects); i++)
      if(ObjectFind(0, panelObjects[i]) >= 0)
         ObjectSetInteger(0, panelObjects[i], OBJPROP_HIDDEN, true);
}
void ShowPanel()
{
   string panelObjects[] = {PANEL_BG, PANEL_TITLE, BTN_ORDER_TYPE, BTN_DRAW_ZONE, BTN_START,
                            BTN_SL, BTN_TP, BTN_CLOSE_ALL, BTN_DEL_PEND, BTN_BE, BTN_SET, BTN_TOGGLE_PANEL};

   for(int i=0; i<ArraySize(panelObjects); i++)
      if(ObjectFind(0, panelObjects[i]) >= 0)
         ObjectSetInteger(0, panelObjects[i], OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
//| Rounded rectangle background                                     |
//+------------------------------------------------------------------+
void CreateRectLabelRounded(string name, int x, int y, int w, int h, color bg, color border)
{
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,name,OBJPROP_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
}

void CreatePanelTitle(string name, string text, int x, int y, int width, int height)
{
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x + 2);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, CLR_TEXT_PRIMARY);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI");
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//+------------------------------------------------------------------+
//| Modern Button Creation                                           |
//+------------------------------------------------------------------+
void CreateModernButton(string name, string text, int x, int y, int width, int height, color clr)
{
   // Always delete first to ensure a clean state
   ObjectDelete(0, name);

   // Create new button
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_CORNER, 0);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_COLOR, CLR_TEXT_PRIMARY);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
   ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI");
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}


//+------------------------------------------------------------------+
//| Delete object safely                                             |
//+------------------------------------------------------------------+
void SafeDelete(string name)
{
   if(ObjectFind(0,name) >= 0) ObjectDelete(0,name);
}

//+------------------------------------------------------------------+
//| Order Type Label                                                 |
//+------------------------------------------------------------------+
string OrderTypeLabel()
{
   if(gOrderTypeIdx==OT_BUY_STOP)   return "Buy stop";
   if(gOrderTypeIdx==OT_SELL_STOP)  return "Sell stop";
   if(gOrderTypeIdx==OT_BUY_LIMIT)  return "Buy limit";
   return "Sell limit";
}

//+------------------------------------------------------------------+
//| Chart Event Handling                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    // --- Handle object drag for instant zone distance update ---
    if(id == CHARTEVENT_OBJECT_DRAG)
    {
        if(sparam == ZONE_TOP || sparam == ZONE_BOTTOM)
        {
            UpdateZoneDistanceLabel(); // <-- this updates distance immediately
        }
    }

    // --- Handle clicks (your existing logic) ---
    if(id != CHARTEVENT_OBJECT_CLICK) return;

    if(sparam == BTN_ORDER_TYPE) 
    { 
        gOrderTypeIdx = (gOrderTypeIdx + 1) % 4; 
        ObjectSetString(0, BTN_ORDER_TYPE, OBJPROP_TEXT, OrderTypeLabel()); 
    }
    else if(sparam == BTN_DRAW_ZONE) ToggleZoneLines();
    else if(sparam == BTN_START) PlaceOrdersFromZone();
    else if(sparam == BTN_SL) ToggleSLLine();
    else if(sparam == BTN_TP) ToggleTPLine();
    else if(sparam == BTN_CLOSE_ALL) CloseAllEAOrders();
    else if(sparam == BTN_DEL_PEND) DeletePendingEAOrders();
    else if(sparam == BTN_BE) 
    { 
        gBEEnabled = !gBEEnabled; 
        ObjectSetString(0, BTN_BE, OBJPROP_TEXT, gBEEnabled ? "BE ON" : "BE OFF"); 
    }
       else if(sparam == BTN_SET)
   {
       ApplySLTPToExistingAndStore();          // apply SL/TP to existing orders
   
       // Reset the button so it appears unclicked and stops using old SL/TP
       gUseSLTPForNew = false;
       ObjectSetInteger(0, BTN_SET, OBJPROP_STATE, false);
       Print("SET SL/TP clicked and reset.");
   }

    else if(sparam == BTN_TOGGLE_PANEL)
    {
        gPanelVisible = !gPanelVisible;
        ObjectSetString(0, BTN_TOGGLE_PANEL, OBJPROP_TEXT, gPanelVisible ? "-" : "+");
    
        string panelObjects[] = {PANEL_BG, PANEL_TITLE, BTN_ORDER_TYPE, BTN_DRAW_ZONE, BTN_START,
                                 BTN_SL, BTN_TP, BTN_CLOSE_ALL, BTN_DEL_PEND, BTN_BE, BTN_SET};
    
        for(int i = 0; i < ArraySize(panelObjects); i++)
        {
            if(ObjectFind(0, panelObjects[i]) >= 0)
            {
                if(gPanelVisible)
                    ObjectSetInteger(0, panelObjects[i], OBJPROP_XDISTANCE, gPanelOrigX[i]);
                else
                    ObjectSetInteger(0, panelObjects[i], OBJPROP_XDISTANCE, gPanelOrigX[i] - 2000);
            }
        }
    }
}


//+------------------------------------------------------------------+
//| Toggle Zone Lines                                                |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Toggle Zone Lines                                                |
//+------------------------------------------------------------------+
void ToggleZoneLines()
{
   if(!gZoneVisible)
   {
      double mid    = (Bid + Ask) * 0.5;
      double offset = ZoneOffsetPips * _Point;

      double topPrice    = mid + offset;
      double bottomPrice = mid - offset;

      CreateHLine(ZONE_TOP, topPrice, clrLime, STYLE_DOT);
      CreateHLine(ZONE_BOTTOM, bottomPrice, clrLime, STYLE_DOT);
      gZoneVisible = true;
   }
   else
   {
      SafeDelete(ZONE_TOP);
      SafeDelete(ZONE_BOTTOM);
      gZoneVisible = false;
   }
}

//+------------------------------------------------------------------+
//| Create Horizontal Line                                           |
//+------------------------------------------------------------------+
void CreateHLine(string name, double price, color col, int style)
{
   if(ObjectFind(0,name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);

   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, true);   // ✅ auto-select for dragging
   ObjectSetInteger(0, name, OBJPROP_BACK, true);        // put lines behind panel/buttons
   //ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);       // remove or comment out

}



//+------------------------------------------------------------------+
//| Toggle SL / TP Lines                                             |
//+------------------------------------------------------------------+
void ToggleSLLine()
{
    if(!gSLVisible)
    {
        double mid = (Bid + Ask) * 0.5;
        double delta = 80 * _Point;
        CreateHLine(SL_LINE, mid - delta, clrTomato, STYLE_DOT);
        gSLVisible = true;
        CreateSetButtonIfNeeded();
    }
    else
    {
        SafeDelete(SL_LINE);
        gSLVisible = false;
        gDefaultSL = 0.0;
        CheckRemoveSetButton();
    }
}

void ToggleTPLine()
{
    if(!gTPVisible)
    {
        double mid = (Bid + Ask) * 0.5;
        double delta = 80 * _Point;
        CreateHLine(TP_LINE, mid + delta, clrDeepSkyBlue, STYLE_DOT);
        gTPVisible = true;
        CreateSetButtonIfNeeded();
    }
    else
    {
        SafeDelete(TP_LINE);
        gTPVisible = false;
        gDefaultTP = 0.0;
        CheckRemoveSetButton();
    }
}

//+------------------------------------------------------------------+
//| Manage "Set SL/TP" button                                        |
//+------------------------------------------------------------------+
void CreateSetButtonIfNeeded()
{
    ObjectSetInteger(0, BTN_SET, OBJPROP_HIDDEN, false);
}

void CheckRemoveSetButton()
{
    if(ObjectFind(SL_LINE) < 0 && ObjectFind(TP_LINE) < 0)
    {
        ObjectSetInteger(0, BTN_SET, OBJPROP_HIDDEN, true);
        gUseSLTPForNew = false;
    }
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Apply SL/TP to existing orders and store for new ones (MQL4)     |
//+------------------------------------------------------------------+
void ApplySLTPToExistingAndStore()
{
    // Check if the SL/TP lines actually exist on the chart
    bool slExists = ObjectFind(SL_LINE) >= 0;
    bool tpExists = ObjectFind(TP_LINE) >= 0;

    if(!slExists && !tpExists)
    {
        Alert("No SL or TP line found.");
        return;
    }

    // Get current line prices if they exist
    double sl = slExists ? ObjectGetDouble(0, SL_LINE, OBJPROP_PRICE) : 0.0;
    double tp = tpExists ? ObjectGetDouble(0, TP_LINE, OBJPROP_PRICE) : 0.0;

    // Store for new trades
    if(slExists) gDefaultSL = NormalizeDouble(sl, Digits);
    if(tpExists) gDefaultTP = NormalizeDouble(tp, Digits);
    gUseSLTPForNew = true;

    // Update visibility flags for internal use
    gSLVisible = slExists;
    gTPVisible = tpExists;

    int modified = 0, failed = 0;

    // Loop through existing orders
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if(OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagic) continue;

        double currentSL = slExists ? sl : OrderStopLoss();
        double currentTP = tpExists ? tp : OrderTakeProfit();

        bool ok = OrderModify(OrderTicket(), OrderOpenPrice(), currentSL, currentTP, 0, clrNONE);

        if(ok) modified++; else failed++;
    }

    Print("SL/TP applied. Modified=", modified, " Failed=", failed);
}
//+------------------------------------------------------------------+
//| Place orders from zone                                           |
//+------------------------------------------------------------------+
void PlaceOrdersFromZone()
{
   if(ObjectFind(0,ZONE_TOP)<0 || ObjectFind(0,ZONE_BOTTOM)<0)
   {
      Alert("Zone lines not found. Click 'Draw Zone' first.");
      return;
   }

   double top = ObjectGetDouble(0, ZONE_TOP, OBJPROP_PRICE);
   double bot = ObjectGetDouble(0, ZONE_BOTTOM, OBJPROP_PRICE);
   if(top<bot){ double t=top; top=bot; bot=t; }

   int n = MathMax(1, InpNumPendingOrders);
   double step = (top - bot) / (n - 1);   // divide into (n-1) intervals
   if(step<=0){ Alert("Zone too small."); return; }

   datetime exp = (InpExpirationMin>0) ? TimeCurrent()+InpExpirationMin*60 : 0;

   int placed=0, skipped=0, failed=0;
   for(int i=0; i<n; i++)
   {
      double desired = NormalizeDouble(bot + step * i, _Digits);
      int type = MapOrderType(gOrderTypeIdx);
      double price = AdjustPriceForRules(type,desired);
      if(price==0.0){ skipped++; continue; }

      double sl=0,tp=0;
      if(gUseSLTPForNew)
      {
         sl = gSLVisible ? gDefaultSL : 0;
         tp = gTPVisible ? gDefaultTP : 0;
      }

      int ticket = OrderSend(Symbol(), type, InpLots, price, InpSlippage, sl, tp, "ZoneOrder", InpMagic, exp, clrNONE);
      if(ticket<0){ failed++; Print("OrderSend failed type=",type," price=",DoubleToString(price,_Digits)," err=",GetLastError()); }
      else placed++;
   }
   Print("Placed=",placed," Skipped=",skipped," Failed=",failed);
}

//+------------------------------------------------------------------+
//| Adjust price respecting StopsLevel and side                      |
//+------------------------------------------------------------------+
double AdjustPriceForRules(int type,double desired)
{
   double minDist = MarketInfo(Symbol(),MODE_STOPLEVEL)*_Point;
   double ask=Ask,bid=Bid;

   if(type==OP_BUYSTOP){ if(desired<=ask+minDist) desired=ask+minDist; if(desired<=bid) return 0.0; }
   else if(type==OP_SELLSTOP){ if(desired>=bid-minDist) desired=bid-minDist; if(desired>=ask) return 0.0; }
   else if(type==OP_BUYLIMIT){ if(desired>=ask-minDist) desired=ask-minDist; if(desired>=ask) return 0.0; }
   else if(type==OP_SELLLIMIT){ if(desired<=bid+minDist) desired=bid+minDist; if(desired<=bid) return 0.0; }

   return NormalizeDouble(desired,_Digits);
}

int MapOrderType(int idx)
{
   if(idx==OT_BUY_STOP)   return OP_BUYSTOP;
   if(idx==OT_SELL_STOP)  return OP_SELLSTOP;
   if(idx==OT_BUY_LIMIT)  return OP_BUYLIMIT;
   return OP_SELLLIMIT;
}

//+------------------------------------------------------------------+
//| Close all EA orders                                              |
//+------------------------------------------------------------------+
void CloseAllEAOrders()
{
   int closed = 0;
   int failed = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagic) continue;

      int type = OrderType();
      bool ok = false;

      // Only close market orders, ignore pending
      if(type == OP_BUY)
         ok = OrderClose(OrderTicket(), OrderLots(), Bid, InpSlippage, clrRed);
      else if(type == OP_SELL)
         ok = OrderClose(OrderTicket(), OrderLots(), Ask, InpSlippage, clrRed);

      if(ok) closed++;
      else failed++;
   }

   //✅ Delete drawn lines / button
   SafeDelete(ZONE_TOP);
   SafeDelete(ZONE_BOTTOM);
   SafeDelete(SL_LINE);
   SafeDelete(TP_LINE);

   // You can still reset states if needed
   gZoneVisible = false; 
   gSLVisible = false; 
   gTPVisible = false;
   gUseSLTPForNew = false; 
   gDefaultSL = 0; 
   gDefaultTP = 0;

   Print("Closed market=", closed, " Failed=", failed);
}

//+------------------------------------------------------------------+
//| Apply BreakEven to grouped trades                                 |
//+------------------------------------------------------------------+
void ApplyBreakEven()
{
   if(!gBEEnabled) return; // Only if BE is ON

   int total = OrdersTotal();
   if(total < 1) return;

   // Collect all trades for this symbol and EA
   int tickets[];
   double opens[];
   double profits[];
   int types[];
   int count = 0;

   for(int i=0; i<total; i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=InpMagic) continue;

      ArrayResize(tickets,count+1);
      ArrayResize(opens,count+1);
      ArrayResize(profits,count+1);
      ArrayResize(types,count+1);

      tickets[count] = OrderTicket();
      opens[count]   = OrderOpenPrice();
      types[count]   = OrderType();
      profits[count] = (types[count]==OP_BUY) ? (Bid-OrderOpenPrice())/_Point : (OrderOpenPrice()-Ask)/_Point;
      count++;
   }

   if(count < 1) return;

   // Sort by price to group nearby trades
   for(int i=0;i<count-1;i++)
      for(int j=i+1;j<count;j++)
         if(opens[i]>opens[j])
         {
            double t1=opens[i], t2=profits[i]; int tp=types[i]; int ticket=tickets[i];
            opens[i]=opens[j]; profits[i]=profits[j]; types[i]=types[j]; tickets[i]=tickets[j];
            opens[j]=t1; profits[j]=t2; types[j]=tp; tickets[j]=ticket;
         }

   // Loop to check groups
   for(int i=0;i<count;i++)
   {
      double groupMin = opens[i];
      double groupMax = opens[i];
      int groupEnd = i;

      // Identify group trades within distance
      for(int j=i+1;j<count;j++)
      {
         if(MathAbs(opens[j]-opens[i])/_Point <= BE_GroupDistance)
         {
            groupMax = opens[j];
            groupEnd = j;
         }
         else break;
      }

      // Check if group profit meets BE_Trigger
      double minProfit = 1e9;
      double maxProfit = -1e9;
      for(int k=i;k<=groupEnd;k++)
      {
         if(profits[k]<minProfit) minProfit = profits[k];
         if(profits[k]>maxProfit) maxProfit = profits[k];
      }

      if(maxProfit >= BE_Trigger)
      {
         // Move SL of all trades in group to newest trade + offset
         double bePrice;
         int newest = groupEnd; // newest trade in group
         if(types[newest]==OP_BUY) bePrice = opens[newest] + BE_Offset*_Point;
         else bePrice = opens[newest] - BE_Offset*_Point;

         for(int k=i;k<=groupEnd;k++)
         {
            if(!OrderSelect(tickets[k], SELECT_BY_TICKET, MODE_TRADES)) continue;
            double sl = (types[k]==OP_BUY) ? MathMax(OrderStopLoss(), bePrice) : MathMin(OrderStopLoss(), bePrice);
            OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), 0, clrGold);
         }
      }

      i = groupEnd; // Skip to next group
   }
}
void DeletePendingEAOrders()
{
   int deleted = 0, failed = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagic) continue;

      int type = OrderType();
      if(type == OP_BUYSTOP || type == OP_SELLSTOP || type == OP_BUYLIMIT || type == OP_SELLLIMIT)
      {
         if(OrderDelete(OrderTicket()))
            deleted++;
         else
            failed++;
      }
   }

   Print("Pending orders deleted: ", deleted, "  Failed: ", failed);
}
void UpdateZoneDistanceLabel()
{
    if(!gZoneVisible) 
    {
        SafeDelete(ZONE_DIST_LABEL);
        return;
    }

    double top = ObjectGetDouble(0, ZONE_TOP, OBJPROP_PRICE);
    double bot = ObjectGetDouble(0, ZONE_BOTTOM, OBJPROP_PRICE);
    double dist = MathAbs(top - bot)/_Point; // distance in points
    double distPips = dist / ((Digits==3 || Digits==5)?10:1); // convert to pips

    string text = "Zone: " + DoubleToString(distPips,1) + " pips";

    int x = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0) - 150;
    int y = 20;

    if(ObjectFind(0, ZONE_DIST_LABEL)<0)
    {
        ObjectCreate(0, ZONE_DIST_LABEL, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, ZONE_DIST_LABEL, OBJPROP_CORNER, 0);
        ObjectSetInteger(0, ZONE_DIST_LABEL, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, ZONE_DIST_LABEL, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, ZONE_DIST_LABEL, OBJPROP_COLOR, clrYellow);
        ObjectSetInteger(0, ZONE_DIST_LABEL, OBJPROP_FONTSIZE, 12);
        ObjectSetInteger(0, ZONE_DIST_LABEL, OBJPROP_BGCOLOR, clrBlack);
        ObjectSetInteger(0, ZONE_DIST_LABEL, OBJPROP_BORDER_TYPE, BORDER_RAISED);
    }

    ObjectSetString(0, ZONE_DIST_LABEL, OBJPROP_TEXT, text);
}
