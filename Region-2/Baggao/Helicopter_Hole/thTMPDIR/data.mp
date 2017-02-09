Scale:=15.00;
MagDecl:=-2.74;
GridConv:=0.31;
BaseScale:=5.00;
color HelpSymbolColor;
HelpSymbolColor := (0.8, 0.8, 0.8);
background:=(1.00000,1.00000,1.00000);
verbatimtex \input th_enc.tex etex;
%% therion source code
%%
%% therion.mp
%%
%% This file defines low-level MetaPost macros and variables required
%% for generation of map symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: therion.mp,v $
%% $Revision: 1.3 $
%%
%% Copyright (C) 2000-2003 Martin Budaj
%%
%% Some macros are adapted from MPATTERN package of P. Bolek
%%
%% Some macros are used from MetaFun package of H. Hagen
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

%    This file defines low level macros used for map signatures in Therion.
%    Before loading this file set `Scale' variable to numeric value
%    representing denominator of the scale ratio. Internal variable 
%    `prologues' is set to 1 by this file. This module loads also 
%    symbol libraries.


tracingstats:=1;
prologues:=0;

if known Background: background:=Background fi;
%TrueScale:=Scale;

% @VARIABLE
% symbol_scale --
%
% <I>internal numeric</I>; in map symbol definitions used for scaling
% in <A HREF="#T">T</A> transformation; recommended
% values are 1 or 2.

%newinternal symbol_scale;
%symbol_scale := 1;

% @VARIABLE
% fill_only --
%
% <I>boolean</I>, used in <A HREF="#thdraw">thdraw</A> and
% <A HREF="#thpattfill">thpattfill</A> commands. When set to false, it has 
% no effect, when it is true, it supresses all drawing 
% commands with exception of <I>thpermanentfill</I>, so that only filled 
% areas are drawn

boolean fill_only, horiz_labels, transparency;
fill_only := false;
horiz_labels:=true;
transparency:=false;

string ATTR__id, ATTR__survey, ATTR__scrap, NorthDir;
boolean ATTR__scrap_centerline;
picture ATTR__text;
numeric ATTR__height;
boolean ATTR__elevation;
ATTR__scrap_centerline := false;
ATTR__height:=0;
ATTR__elevation:=false;

boolean ATTR__shotflag_splay;
ATTR__shotflag_splay:=false;
boolean ATTR__shotflag_duplicate;
ATTR__shotflag_duplicate:=false;
boolean ATTR__shotflag_approx;
ATTR__shotflag_approx:=false;
boolean ATTR__stationflag_splay;
ATTR__stationflag_splay:=false;


color label_fill_color, label_fill_color_tmp;
label_fill_color := (1.0, 1.0, 1.0);
def push_label_fill_color(expr r,g,b) =
  label_fill_color_tmp := label_fill_color;
  label_fill_color := (r,g,b);
enddef;
def pop_label_fill_color =
  label_fill_color := label_fill_color_tmp;
enddef;
def process_filledlabel(expr cent, rot) =
  begingroup;
    interim bboxmargin:=2.0bp;
    q:=((bbox lab) smoothed 2) rotatedaround (cent, rot);
    fill q withcolor label_fill_color;
    draw lab rotatedaround (cent, rot);
    write_circ_bbox(q);  % without corners smoothing it was enough to use
                         % write_bbox(q);
  endgroup;
enddef;




numeric area_border_errors;
area_border_errors = 0;

% @VARIABLE
% last_write --
%
% <I>numeric</I>; charcode of last figure which contained 
% <A HREF="#write_bbox">write_bbox</A> macro; this value is used by
% <A HREF="#close_file">close_file</A> macro. Initially set to -1.

numeric last_write;
last_write = -1;

% @VARIABLE
% strut_string --
%
% <I>string</I> containing combination of the "highest" and "lowest" character
% in used font; it's used by <A HREF="">free_text</A> macro.

%string strut_string;
%strut_string = "(È";

% @VARIABLE
% file_name --
%
% <I>string</I>, name of file, where <I>write_bbox</I> macro writes
% text clipping path

% @VARIABLE
% s ch --
%
% <I>string</I>, temporary string/char variables

string s, ch, file_name, bg_name, clip_name, lang, diff_pos, diff_neg,
     current_scrap, current_src;

% @VARIABLE
% u v w --
%
% <I>internal numeric variables</I> used as basic length units for drawing;
% they are set by <A HREF="#initialize">initialize</A> macro.
% <UL> <LI><I>u</I> -- normal unit decreasing with increasing scale
%      <LI><I>v</I> -- like <I>u</I>, but can increase drammaticaly
%            when some limit is encountered (to get effects like logarithmic
%            scale)
%      <LI><I>w</I> -- nearly constant at all scales
% </UL>

% @VARIABLE
% legend_scale --
%
% <I>numeric</I>, length of the longer side of signatures' legend box

newinternal legend_scale, u,v,w;

% @VARIABLE
% lab Lab --
%
% <I>picture</I>, in which are saved typeset labels

picture lab, Lab;

% @VARIABLE
% T --
%
% <I>transformation</I>, defines transformation function for transforming 
% every argument of <A HREF="#thdraw>thdraw</A> and <A HREF="#thfill>thfill</A>
% macros

transform T;

% @VARIABLE
% p,q --
%
% <I>path</I>, for saving temporary paths

path p,q;

% @MACRO
% initialize --
%
% initializes basic length units <A HREF="#u">(u,v,w)</A> and pens used 
% in map symbols according to scale. Five circular pens are defined:
% <UL><LI>PenA -- thick; for outlines
%    <LI>PenB, PenC -- thinner; for pits, symbols etc.
%    <LI>PenD -- thinnest; for fine details
%    <LI>PenX -- extra thick; not recommended for use
% </UL>

def fonts_setup (expr t,s,m,l,h) =
  write "\def\updown#1#2{\vbox{" &
        "\offinterlineskip" &
        "\setbox100=\hbox{#1}" &
        "\setbox101=\hbox{#2}" &
        "\ifnum\wd100>\wd101\hsize=\wd100\else\hsize=\wd101\fi" &
        "\centerline{\box100}\vskip4pt" &
        "\centerline{\box101}}}" &
        "\def\thlabel{\thnormalsize}" &
        "\def\thremark{\thsmallsize\si}" &
        "\def\thcomment{\thsmallsize}" &
        "\def\thentrance{\thsmallsize}" &
        "\def\thaltitude{\thsmallsize}" &
        "\def\thstationname{\thsmallsize}" &
        "\def\thdate{\thsmallsize}" &
        "\def\thheight{\thsmallsize}" &
        "\def\thheightpos{+\ignorespaces}" &
        "\def\thheightneg{-\ignorespaces}" &
        "\def\thframed{\thsmallsize}" &
        "\def\thwallaltitude{\thtinysize}"
  to "mptexpre.tex";
  write "\def\thtinysize{\size[" & decimal max(optical_zoom*t,0) & "]}" & 
        "\def\thsmallsize{\size[" & decimal max(optical_zoom*s,0) & "]}" & 
        "\def\thnormalsize{\size[" & decimal max(optical_zoom*m,0) & "]}" & 
        "\def\thlargesize{\size[" & decimal max(optical_zoom*l,0) & "]}" & 
        "\def\thhugesize{\size[" & decimal max(optical_zoom*h,0) & "]}" 
  to "mptexpre.tex";
  write EOF to "mptexpre.tex";
enddef;

def initialize (expr sc) =

  if unknown BaseScale: BaseScale = sc; fi;
  optical_zoom := BaseScale/sc;

    if BaseScale <= 1:                   % 1:100
        u:=14bp; v:=14bp; w:=12bp;
        fonts_setup(8,10,12,16,24);
    elseif BaseScale <= 2:               % 1:200
        u:=12bp; v:=12bp; w:=12bp;
        fonts_setup(7,8,10,14,20);
    elseif BaseScale <= 5:               % 1:500
        u:=10bp; v:=10bp; w:=12bp;
        fonts_setup(6,7,8,10,14);
    else:
        u:=7bp; v:=14bp; w:=10bp;
        fonts_setup(5,6,7,8,10);
    fi;
    
    u := optical_zoom * u;
    v := optical_zoom * v;
    w := optical_zoom * w;

    defaultscale := 0.8 * optical_zoom;

    def PenA = pencircle scaled (u/10) enddef;
    def PenB = pencircle scaled (0.7*u/10) enddef;
    def PenC = pencircle scaled (0.5*u/10) enddef;
    def PenD = pencircle scaled (0.35*u/10) enddef;
    def PenX = pencircle scaled (1.2*u/10) enddef;
    
    legend_scale := 3.14*u;
enddef;

% macro is expanded, we have to know all dimensions and pens before reading
% mpattern macros

initialize(Scale);

vardef thTEX primary s =
  write "verbatimtex \input th_enc.tex etex" to "mptextmp.mp";
  write "btex \mainfont "&s&" etex" to "mptextmp.mp";
  write EOF to "mptextmp.mp";
  scantokens "input mptextmp"
enddef;

% @MACRO
% inscale --
%
% zooms objects to scale specified in legend_scale variable (used in legend
% typesetting)

def inscale = 
    xscaled legend_scale yscaled (0.618*legend_scale)
enddef;

% @MACRO
% draw_legend_box --
%
% draws a legend bounding box and resets drawoptions() options 

def draw_legend_box =
    clip currentpicture to unitsquare inscale;
    drawoptions();
    pickup PenB;
    draw unitsquare inscale;
enddef;

def clean_legend_box =
  unfill unitsquare inscale;
enddef;

def legend_point (expr name) =
%  if substring (2,9) of name = "station":
%    scantokens(name)((0.5,0.5) inscale);
%  else:
    scantokens(name)((0.5,0.5) inscale,0,1,(0,0));
%  fi;
  draw_legend_box;
enddef;

def legend_line (expr name) =
  scantokens(name)((((-0.3,.5)..(.3,.7)..(.5,.3)..{dir 80}(1.3,.9)) inscale) 
                randomized 3mm);
  draw_legend_box;
enddef;

% legend_label
% legend_area
% legend_random

% @MACRO
% roundone --
%
% rounds <I>numeric value</I> to one decimal point

vardef roundone(expr n) =
%    round(10*n)/10
  n
enddef;

% @MACRO
% process_label --
%
% draws a label saved in <I>lab</I> picture variable and calls 
% <A HREF="#write_bbox">write_bbox</A> macro.


def process_label (expr cent, rot) =
  begingroup;
    interim bboxmargin:=0.8bp;
    q:=((bbox lab) smoothed 2) rotatedaround (cent, rot);
    draw lab rotatedaround (cent, rot);
    write_circ_bbox(q);  % without corners smoothing it was enough to use
                         % write_bbox(q);
  endgroup;
enddef;

% @MACRO
% process_uplabel --
%
% draws a label into semicircular box and writes clipping path to a file

def process_uplabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    q:=bbox lab;
  endgroup;
    alef:=.8-.02*(xpart lrcorner q - xpart llcorner q);
%    show alef;
    q:=alef[llcorner q,ulcorner q]{up} .. {down}alef[lrcorner q, urcorner q] --
        lrcorner q -- llcorner q -- cycle;
    draw lab;
    draw q;
    q:=reverse q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_downlabel --
%
% draws a label into down oriented semicircular box and writes
% clipping path to a file

def process_downlabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    q:=bbox lab;
  endgroup;
    alef:=1-(.8-.02*(xpart lrcorner q - xpart llcorner q));
    q:=alef[llcorner q,ulcorner q]{down} .. 
        {up}alef[lrcorner q, urcorner q] --
        urcorner q -- ulcorner q -- cycle;
    draw lab;
    draw q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_updownlabel --
%
% draws a label splitted into down and up oriented semicircular boxes and 
% writes clipping path to a file

def process_updownlabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    p:=bbox lab;
  endgroup;
    leftside:=xpart llcorner p;
    rightside:=xpart lrcorner p;
    draw (xpart llcorner p,.5[ypart llcorner p,ypart ulcorner p]) -- 
         (xpart lrcorner p,.5[ypart llcorner p,ypart ulcorner p]);
    alef:=1.05-.02*(xpart lrcorner p - xpart llcorner p);
%    alef:=.8-.02*(rightside-leftside);
    p:=alef[(leftside, ypart llcorner p),(leftside, ypart ulcorner p)]{up} .. 
       {down}alef[(rightside, ypart lrcorner p), (rightside, ypart urcorner p)]
        -- alef[(rightside, ypart urcorner p), (rightside, ypart lrcorner p)]{down}
        .. {up}alef[(leftside, ypart ulcorner p),(leftside, ypart llcorner p)]
        -- cycle;
%    p:=alef[llcorner p,ulcorner p]{up} .. {down}alef[lrcorner p, urcorner p] --
%        aleff[llcorner p,ulcorner p]{down} .. 
%        {up}aleff[lrcorner p, urcorner p] -- cycle;
    draw lab;
    draw p;
    p:=reverse p;
    write_circ_bbox(p);
enddef;

def process_updownlabel_OLD =
    p:=bbox lab;
    q:=bbox Lab;
    leftside:=min(xpart llcorner p, xpart ulcorner q);
    rightside:=max(xpart lrcorner p, xpart urcorner q);
    draw .5[(leftside, ypart llcorner p),(leftside, ypart ulcorner q)] -- 
         .5[(rightside,ypart lrcorner p),(rightside,ypart urcorner q)];
    alef:=.8-.02*(rightside-leftside);
    q:=alef[(leftside, ypart llcorner p),(leftside, ypart ulcorner p)]{up} .. 
       {down}alef[(rightside, ypart lrcorner p), (rightside, ypart urcorner p)]
        -- alef[(rightside, ypart urcorner q), (rightside, ypart lrcorner q)]{down}
        .. {up}alef[(leftside, ypart ulcorner q),(leftside, ypart llcorner q)]
        -- cycle;
    draw lab;
    draw Lab;
    draw q;
    q:=reverse q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_boxedlabel --
%
% draws a label into circular box and writes
% clipping path to a file

def process_boxedlabel =
    q:=bbox lab;
    draw lab;
    draw q;
    write_bbox(q);
enddef;

% @MACRO
% process_circledlabel --
%
% draws a label into circular box and writes
% clipping path to a file

def process_circledlabel =
  begingroup;
    interim bboxmargin := 0.4 bp;
    q:=bbox lab;
  endgroup;
    q:=point 0 of q .. point 1 of q .. point 2 of q .. point 3 of q .. cycle;
    draw lab;
    draw q;
    write_circ_bbox(q);
enddef;


% @MACRO
% write_bbox --
%
% Arguments:
%   <I>path</I> variable -- rectangular bounding box of a label;
%   assumptions: path is cyclic, counterclockwise oriented, with four points,
%   composed from linear segments;
%   see general <A HREF="#write_circ_bbox">write_circ_bbox</A> macro
% Results:
%   one file per figure which uses labels with a clipping path in pseudo-pdf 
%   format

def write_bbox (expr q) =
    file_name := jobname & "." & decimal(charcode) & "bbox";
    for i:=4 downto 0:
        s  :=  decimal(roundone(xpart point i of q)) & " " 
             & decimal(roundone(ypart point i of q)) 
             & if i=4: " m " else: " l" fi;
        write s to file_name;
    endfor;
    last_write := charcode;
enddef;

% @MACRO
% write_circ_bbox --
%
% Arguments:
%   <I>path</I> variable, only assumption is that <I>path</I> is cyclic
%   and counterclockwise oriented.
% Results:
%   one file per figure which uses labels with a clipping path in pseudo-pdf 
%   format

def write_circ_bbox expr q =
    file_name := jobname & "." & decimal(charcode) & "bbox";
    tmp:=length q;
    s :=  decimal(roundone(xpart point tmp of q)) & " " 
             & decimal(roundone(ypart point tmp of q)) & " m";
    write s to file_name;
    for i:=tmp downto 1:
        s :=  decimal(roundone(xpart precontrol i of q)) & " " 
             & decimal(roundone(ypart precontrol i of q)) & " "
             & decimal(roundone(xpart postcontrol i-1 of q)) & " " 
             & decimal(roundone(ypart postcontrol i-1 of q)) & " "
             & decimal(roundone(xpart point i-1 of q)) & " " 
             & decimal(roundone(ypart point i-1 of q)) & " c";
        write s to file_name;
    endfor;
    last_write := charcode;
enddef;

% @MACRO
% close_file --
%
% closes file with a clipping path; it's invoked by <I>endchar</I> macro

def close_file =
    if last_write=charcode:
        write EOF to jobname & "." & decimal(charcode) & "bbox";
    fi;
enddef;

% endchar should run close_file macro

extra_endfig := "close_file;";

% @MACRO
% thdraw --
%
% like plain MetaPost's <I>draw</I>, but draws a <I>path</I> transformed
% (rotated, scaled, shifted) to scrap's coordinates according T variable.
% (If <I>fill_only=false</I>)

def thdrawoptions(text t) =
  def _thop_ = t enddef
enddef;
thdrawoptions();

def thdraw expr p = 
  if not fill_only:
    addto currentpicture 
    if picture p: 
      also (p transformed T)
    else:
      doublepath (p transformed T) withpen currentpen 
    fi  
    _thop_  _op_
  else:
    addto currentpicture also nullpicture
  fi
enddef;

% @MACRO
% thfill --
%
% fills a <I>path</I> transformed
% (rotated, scaled, shifted) to scrap's coordinates according T variable.
% Filled areas are clipped (like most 
% other lines and points) with a clipping path around text labels.


def thfill expr c = 
    addto currentpicture contour (c transformed T) _thop_ _op_ 
enddef;

def thfilldraw expr c =
  if not fill_only:
    addto currentpicture contour (c transformed T) withpen currentpen _thop_ _op_ 
  else:
    addto currentpicture contour (c transformed T) _thop_ _op_ 
  fi
enddef;

def thunfill expr c = 
    thfill c withcolor background 
enddef;

def thundraw expr p = 
    thdraw p withcolor background 
enddef;

def thunfilldraw expr c = 
    thfilldraw c withcolor background 
enddef;

def thclean expr c =
  if transparency:
    thfill c withtransparentcolor tr_bg
  else:
    thunfill c
  fi;
enddef;

def thPatternFill (expr Path, Pattern) =
  T:=identity;
  thclean Path;
  thfill Path withpattern Pattern;
enddef;

%def thLegendPatternFill (expr Path, Pattern) =
%  T:=identity;
%  thfill Path withpattern Pattern;
%enddef;

% for drawarrow:

def _finarr text t =
  thdraw _apth t;
  thfilldraw arrowhead _apth  t
enddef;

% @MACRO
% thpermanentfill --
%
% Fills specified area with a solid color; this area is not affected by 
% text clipping path

%def thpermanentfill expr c = 
%    addto currentpicture contour (c transformed T) _thop_ _op_
%enddef;

let thpermanentfill = thfill;


primarydef p aligned al=
  p shifted (xpart al * xpart U, ypart al * ypart U)
enddef;

% macros for drawing scraps in upper and lower levels; filled lower scraps 
% require special treatment (MetaPost doesn't support non-continuous paths).
% We can't use one file for both, while PDF XObject has to be explicitely 
% filled or stroked. Second macro writes also pseudo-pdf code of a clipping 
% path for given scrap

boolean drawnext;
drawnext:=true;

def draw_upscrap (expr isout)(text t) =
  path q;
  for i=t:
    if (numeric i):
      if (i=1): drawnext:=true; else: drawnext:=false; fi;
    else:
      if drawnext: draw i withpen PenD; fi;
      if not known q: q:=i; else: q:=q -- i; fi;
    fi;
  endfor;
  if not cycle q: q:=q -- cycle; fi;
  if turningnumber q = 0: 
      thwarning("scrap outline intersects itself"); 
  fi;
  if isout=1:
    if turningnumber q > 0: q := reverse q; fi;
  else:
    if turningnumber q < 0: q := reverse q; fi;
  fi;
  addto bgfill contour q;
enddef;

% following macro writes noncontinuous PostScript path directly to EPS file
% (filled background and clipping path)

picture bgfill;
bgfill:=nullpicture;

def draw_downscrap =
  bg_name := jobname & "." & decimal(charcode) & "bg";
  clip_name := jobname & "." & decimal(charcode) & "clip";
  write "%!PS" to bg_name;
  write "%%BoundingBox: " & 
     decimal floor xpart llcorner bgfill & " " &
     decimal floor ypart llcorner bgfill & " " &
     decimal ceiling xpart urcorner bgfill & " " &
     decimal ceiling ypart urcorner bgfill 
     to bg_name;
  write "%%Page: 1 1" to bg_name;
  write "newpath" to bg_name;
  for qq within bgfill:
    q := pathpart qq;
    tmp:=length q;
    s := decimal(roundone(xpart point tmp of q)) & " " 
             & decimal(roundone(ypart point tmp of q)) & " m";
    write s & "oveto" to bg_name;
    write s to clip_name;
    for i:=tmp downto 1:
        s :=  decimal(roundone(xpart precontrol i of q)) & " " 
             & decimal(roundone(ypart precontrol i of q)) & " "
             & decimal(roundone(xpart postcontrol i-1 of q)) & " " 
             & decimal(roundone(ypart postcontrol i-1 of q)) & " "
             & decimal(roundone(xpart point i-1 of q)) & " " 
             & decimal(roundone(ypart point i-1 of q)) & " c";
        write s & "urveto" to bg_name;
        write s to clip_name;
    endfor;
  endfor;
  write "closepath fill" to bg_name;
  write "showpage" to bg_name;
  write "%%EOF" to bg_name;
  write EOF to bg_name;
  write EOF to clip_name;
  bgfill:=nullpicture;
enddef;



vardef buildcycle(text ll) =
  save ta_, tb_, k_, i_, pp_; path pp_[];
  k_=0;
  for q=ll: pp_[incr k_]=q; endfor
  i_=k_;
  for i=1 upto k_:
    (ta_[i], length pp_[i_]-tb_[i_]) =
      pp_[i] intersectiontimes reverse pp_[i_];
    if ta_[i]<0:
      message("[Error: area borders "& area_border[i] &" and "& 
         area_border[i_] &" don't intersect in scrap " & current_scrap &
         " (file " & current_src & ")]");
      area_border_errors := area_border_errors + 1;
    fi
    i_ := i;
  endfor
  for i=1 upto k_: subpath (ta_[i],tb_[i]) of pp_[i] .. endfor
    cycle
enddef;

vardef unitvector primary z = 
  if (z<>(0,0)):
    z/abs z 
  else:
    hide(thwarning("strange path"))
    (0,epsilon)
  fi
enddef;

def thwarning (expr m) = 
  message("[Warning: " & m & " in scrap " & current_scrap & "]");
enddef;

def check_area_borders = 
  if area_border_errors > 0:
  fi;
enddef;

%%%%%%%%%%%% Map symbols management %%%%%%%%%%%%%%%%%%%

def mapsymbol (expr name, set, warning) = 
  string s, stype, lname, ID;
  stype = substring (0,1) of name;
  lname = name & "_" & set;
  ID := "ID_" & lname;
  if (known scantokens ID):
    if stype = "a":
      s = "def " & name & " = scantokens(" & ditto & lname & ditto & ") enddef;";
    else:
      s = "let " & name & " = " & lname & ";";
    fi;
    scantokens s;
  elseif warning:  
    message("[Warning: undefined symbol `" & lname & "']");
  fi;
enddef;

%def hidesymbol (expr name) =
%  string s, stype;
%  stype = substring (0,1) of name;
%  if stype = "a":
%    s = "def " & name & " = scantokens(" & ditto & "a_empty" & ditto & ") enddef;";
%  else:
%    s = "vardef " & name & "@# (text t) = enddef;";
%  fi;
%  scantokens s;
%  write name to "missed.dat";
%enddef;

def initsymbol (expr name) =
  s := "ID_" & name & " = 1";
  scantokens s;
enddef;

%%%

% comment out groups in order to use 'save ATTR_*' appropriately

def beginfig(expr c) =
%  begingroup
  charcode:=c;
  clearxy; clearit; clearpen;
  pickup defaultpen;
  drawoptions();
  scantokens extra_beginfig;
  
  save smartll, smartur; 
  pair smartll[], smartur[]; 
  smart_count := 0;
enddef;

def endfig =
  scantokens extra_endfig;
  shipit;
%  endgroup
enddef;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% P. Bolek's MPATTERN package adapted and simplified for Therion
% (with the same user interface except of patterncolor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

string Pname_, PXYsteps_;
string Pmatrix_;

numeric Pnum_; Pnum_=0;

def PmakeBB_=
   PBBox_ := "[" & decimal Plft_ & " " & decimal Plow_ & " "
   & decimal Prt_ & " " & decimal Pup_ & "]";
enddef;

def Psteps_=
   PXYsteps_ := decimal
     if unknown PXStep_: (Prt_-Plft_) else: PXStep_ fi 
   & ":" & decimal
     if unknown PYStep_: (Pup_-Plow_) else: PYStep_ fi;
enddef;
   
vardef Pfindbounds_=
   Plow_ = ypart (llcorner currentpicture);
   Plft_ = xpart (llcorner currentpicture);
   Pup_ = ypart (urcorner currentpicture);
   Prt_ = xpart (urcorner currentpicture);
   PmakeBB_;
enddef;

def PmakePattern_(expr name)=
  write decimal (Pnum_*epsilon) & ":"
    & jobname & "." & decimal charcode & ":"
    & PBBox_ & ":"
    & PXYsteps_ & ":"
    & Pmatrix_ 
  to "patterns.dat"
enddef;

% User interface macros

vardef patternbbox(expr a)(text b)=
   save Pi_, Pz_;
   numeric Pi_, Pz_[];
   if pair a:
      Plft_:=min(xpart(a),xpart(b)); Plow_:=min(ypart(a),ypart(b));
      Prt_:=max(xpart(a),xpart(b));  Pup_:=max(ypart(a),ypart(b));
   else:
      Pi_=1;
      for t=b:
	 Pz_[Pi_]=t;
	 Pi_:=Pi_+1;
      endfor;
      Plft_:=min(a,Pz_2);   Plow_:=min(Pz_1,Pz_3);
      Prt_:=max(a,Pz_2); Pup_:=max(Pz_1,Pz_3);
   fi;
   PmakeBB_;
enddef;

def beginpattern(suffix name)=
  numeric PXStep_, PYStep_;
  numeric Plow_, Plft_, Pup_, Prt_;
  string PBBox_;
  Pmatrix_:="[1 0 0 1 0 0]";
  Pname_:=str name;
  Pnum_:=Pnum_+1;
  beginfig(Pnum_+4000);
enddef;

def endpattern=
  if unknown PBBox_:
     Pfindbounds_;
  fi;
  endfig;
  Psteps_;
  PmakePattern_(Pname_);
  scantokens(Pname_ & "=Pnum_;");
enddef;

picture pattpict;
color patterncolor_;
patterncolor_ := black;

primarydef p withpattern s=
  if known s:

    hide(pattpict := image(draw (0,0)--(10,10));
      for i within pattpict:
        patterncolor_ := (redpart i, greenpart i, bluepart i);
      endfor;)

    p withcolor (epsilon, 10*epsilon, s*epsilon)
    if known mpversion:
      if scantokens(mpversion)>=1.000: 
        withprescript(decimal redpart   patterncolor_ & " " &
                      decimal greenpart patterncolor_ & " " &
                      decimal bluepart  patterncolor_ & " THsetpatterncolor")
      fi;
    fi;
  else:
    p withcolor (1,0,0);
    message("Warning: undefined pattern ignored");
  fi;  
enddef;
   
def patterntransform expr t=
   Pmatrix_ := "[" & decimal xxpart t
              & " " & decimal yxpart t
              & " " & decimal xypart t
              & " " & decimal yypart t
              & " " & decimal xpart t
              & " " & decimal ypart t & "]";
enddef;

def patternxstep expr t=
   PXStep_ = t;
enddef;

def patternystep expr t=
   PYStep_ = t;
enddef;

def patternstep text t=
   if pair t:
      PXStep_ = xpart t;
      PYStep_ = ypart t;
   else:
      (PXStep_,PYStep_)=t;
   fi;
enddef;

def patterncolor expr t=
  message("Warning: patterncolor not supported in Therion");
enddef;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of pattern macros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% transparent rgb colors

numeric RGBnum; RGBnum=0;
string RGBname;

def def_transparent_rgb (suffix name)(expr r, g, b) =
  RGBnum := RGBnum+1;
  RGBname := str name;
  write decimal (RGBnum*epsilon) & ":"
    & decimal r & " "
    & decimal g & " "
    & decimal b 
  to "rgbcolors.dat";
  scantokens(RGBname & ":=RGBnum;");
enddef;

primarydef p withtransparentcolor s=
   p withcolor (epsilon, 12*epsilon, s*epsilon);
enddef;

def_transparent_rgb(tr_white, 1, 1, 1);
def_transparent_rgb(tr_blue, 0, 0, 1);
def_transparent_rgb(tr_black, 0, 0, 0);
def_transparent_rgb(tr_bg, 
               redpart background, greenpart background, bluepart background);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some useful macros from H. Hagen's MetaFun package
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

vardef paired (expr d) =
  if pair d : d else : (d,d) fi
enddef ;

primarydef p randomshifted s = 
  begingroup ; save ss ; pair ss ; ss := paired(s) ; 
  p shifted (-.5xpart ss + uniformdeviate xpart ss,
             -.5ypart ss + uniformdeviate ypart ss) 
  endgroup 
enddef ; 

primarydef p randomized s =
  (if path p : 
    for i=0 upto length(p)-1 :
      ((point       i    of p) randomshifted s) .. controls 
      ((postcontrol i    of p) randomshifted s) and 
      ((precontrol (i+1) of p) randomshifted s) .. 
    endfor 
    if cycle p : 
      cycle 
    else :
      ((point length(p) of p) randomshifted s) 
    fi
  elseif pair p :
    p randomshifted s  
  elseif color p :
    if color s : 
      (uniformdeviate redpart   s * redpart   p,
       uniformdeviate greenpart s * greenpart p,
       uniformdeviate bluepart  s * bluepart  p)  
    elseif pair s : 
      ((xpart s + uniformdeviate (ypart s - xpart s)) * p)  
    else :  
      (uniformdeviate s * p)  
    fi 
  else :
    p + uniformdeviate s  
  fi)  
enddef ; 

primarydef p llmoved d =
  ((llcorner p) shifted (-xpart paired(d),-ypart paired(d)))
enddef ;

primarydef p lrmoved d =
  ((lrcorner p) shifted (+xpart paired(d),-ypart paired(d)))
enddef ;

primarydef p urmoved d =
  ((urcorner p) shifted (+xpart paired(d),+ypart paired(d)))
enddef ;

primarydef p ulmoved d =
  ((ulcorner p) shifted (-xpart paired(d),+ypart paired(d)))
enddef ;

primarydef p smoothed d =
  (p llmoved (-xpart paired(d),0) -- p lrmoved (-xpart paired(d),0) {right} .. 
   p lrmoved (0,-ypart paired(d)) -- p urmoved (0,-ypart paired(d)) {up}    .. 
   p urmoved (-xpart paired(d),0) -- p ulmoved (-xpart paired(d),0) {left}  ..
   p ulmoved (0,-ypart paired(d)) -- p llmoved (0,-ypart paired(d)) {down}  .. cycle) 
enddef ;

vardef punked primary p = 
  (point 0 of p for i=1 upto length(p)-1 : -- point i of p endfor 
   if cycle p : -- cycle else : -- point length(p) of p fi)  
enddef ;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of MetaFun macros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% we input map symbol definitions




%%%%% INPUT thPoint %%%%%


%% therion source code
%%
%% This file defines macros for point map symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thPoint.mp,v $
%% $Revision: 1.8 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

pair U;

def p_stalactite_UIS(expr pos,theta,sc,al) =
    U:=(.15u, .4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
    thdraw (0,.15u) -- (.15u,.4u);
enddef;

def p_stalagmite_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
    thdraw (0,-.15u) -- (.15u,-.4u);
enddef;

def p_pillar_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.15u)--(0,-.15u);
    thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
    thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
enddef;

def p_curtain_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    thdraw (0,.15u)--(0,0){dir 180}..(-.12u,-.11u)..{dir 0}(0,-.22u)--(0,-.4u);
enddef;

def p_helictite_UIS(expr pos,theta,sc,al) =
    U:=(.2u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.4u)--(0,-.4u);
    p := (-.2u,.4u)---(-.2u,.1u){down}..{dir -10}(-.1u,0.02u)---origin;
    thdraw p;
    thdraw p reflectedabout (origin,(0,u)) reflectedabout (origin,(u,0));
enddef;

def p_sodastraw_UIS(expr pos,theta,sc,al) =
    U:=(.5u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u)--(.5u,.2u);
    pickup PenD;
    thdraw (-.4u,.2u)--(-.4u,0);
    thdraw (-.12u,.2u)--(-.12u,-.25u);
    thdraw (.02u,.2u)--(.02u,-.1u);
    thdraw (.23u,.2u)--(.23u,-.19u);
    thdraw (.35u,.2u)--(.35u,-.15u);
enddef;

def p_crystal_UIS (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := ((-.35*u,0)--(.35*u,0));
    thdraw p;
    thdraw p rotated (60);
    thdraw p rotated (120);
enddef;

def p_flowstone_UIS (expr pos,theta,sc,al)=
    U:=(.45u,.1u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := ((-.15*u,0)--(.15*u,0));
    thdraw p shifted (.3u,-.1u);
    thdraw p shifted (-.3u,-.1u);
    thdraw p shifted (0,.1u);
enddef;

def p_moonmilk_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.2u){up}..{dir -60}(-.18u,-.105u){dir 80}..
        {dir-80}(.18u,-.105u){dir 60}..{down}(.5u,-.2u);
enddef;

def p_wallcalcite_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.2u,-.2u)--(0,.1u)--(.2u,-.2u);
enddef;

def p_popcorn_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.2u)--(.5u,-.2u);
    pickup PenD;
    thdraw (-.3u,-.2u)--(-.3u,.1u);
    thdraw (0,-.2u)--(0,.1u);
    thdraw (.3u,-.2u)--(.3u,.1u);
    thfill fullcircle scaled .2u shifted (-.3u,.1u);
    thfill fullcircle scaled .2u shifted (0,.1u);
    thfill fullcircle scaled .2u shifted (.3u,.1u);
enddef;

def p_disk_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.2u,-.3u)--origin--(.2u,-.3u);
    p:=fullcircle scaled .3u shifted (0,.15u);
    thclean p;
    thdraw p;
enddef;

def p_gypsum_NSS (expr pos,theta,sc,al)=
    U:=(.25u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.25u,0)--(.25u,0);
    thdraw (0,-.25u)--(0,.25u);
enddef;

def p_aragonite_NSS (expr pos,theta,sc,al)=
    U:=(.3u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u)--(0,.3u);
    thdraw (0,-.1u){dir 40}..{dir 5}(.3u,.08u);
    thdraw (0,-.1u){dir 140}..{dir 175}(-.3u,.08u);
    thdraw (0,.2u){dir 30}..{dir 5}(.25u,.3u);
    thdraw (0,.2u){dir 150}..{dir 175}(-.25u,.3u);
enddef;


def p_cavepearl_SKBB (expr pos,theta,sc,al)=
    U:=(.25u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=fullcircle scaled .25u shifted (0,.16u);
    thdraw p;
    thdraw p rotated 120;
    thdraw p rotated 240;
enddef;

def p_gypsumflower_NSS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
%    thdraw (.2u,0){left}..(0,.2u)..(.25u,.35u)..(.5u,0)..
%        (.1u,-.3u)..{dir 125}(-.5u,.2u);
    thdraw (.18u,0){left}..(0,.15u)..(.2u,.3u)..(.4u,0)..
        (.15u,-.28u)..{dir 120}(-.4u,.15u);
enddef;

def p_rimstonepool_ASF (expr pos,theta,sc,al)=
    U:=(.4u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := (-.4u,.2u){dir -70}..{dir 70}(.4u,.2u);
    thfill buildcycle(p,((.5u,.1u)--(-.5u,.1u)));
    thdraw p;
enddef;

def p_rimstonedam_ASF (expr pos,theta,sc,al)=
    U:=(.4u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,.2u){dir -70}..{dir 70}(.4u,.2u);
enddef;

def p_anastomosis_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.4u,-.2u)--(-.3u,-.3u)--(0,.3u)--(.1u,.2u);
    thdraw p;
    thdraw p shifted (.3u,0);
enddef;

def p_karren_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.3u){dir -85}..{dir 85}(-.32u,-.3u)..(-.28u,.3u){dir 85}..
        {dir -85}(-.12u,.3u)..(-.08u,-.3u){dir-85}..{dir 85}(.08u,-.3u)..
        {dir85}(.12u,.3u)..(.28u,.3u){dir -85}..(.32u,-.3u){dir -85}..
        {dir 85}(.5u,-.3u);
enddef;

def p_scallop_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u){dir 125}..{dir 105}(-.2u,.1u){up}..
        {down}(.2u,.1u){dir -105}...{dir -125}(0,-.4u);
enddef;

def p_flute_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u)--(.5u,.2u);
    thdraw (-.3u,.2u){dir -70}..{dir 70}(.3u,.2u);
enddef;

def p_raft_NSS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u){dir -80}..(-.3u,-.2u)..origin..(.3u,.2u)..
        {dir -80}(.5u,-.2u);
enddef;

def p_raftcone_NSS (expr pos,theta,sc,al)=
    U:=(.3u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.4u)--(0,.4u)--(.3u,-.4u);
enddef;

def p_spring_SKBB (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,.2u){down}..(0,-.2u)..{up}(.3u,.2u);
enddef;

def p_sink_SKBB (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,-.2u){up}..(0,.2u)..{down}(.3u,-.2u);
enddef;

def p_narrowend_UIS (expr pos,theta,sc,al)=
    U:=(.1u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.1u,-.4u)--(-.1u,.4u);
    thdraw (.1u,-.4u)--(.1u,.4u);
enddef;

def p_lowend_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.1u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,-.1u)--(.4u,-.1u);
    thdraw (-.4u,.1u)--(.4u,.1u);
enddef;

def p_lowend_NSS (expr pos,theta,sc,al)=
    U:=(.4u,0);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,0)--(.4u,0);
enddef;

def p_flowstonechoke_NSS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.4u,-.4u){right}..{dir120}(-.2u,-.2u){dir -20}..{up}(0,0);
    thdraw p;
    thdraw p shifted (0,.2u);
    thdraw p reflectedabout (origin,down);
    thdraw p reflectedabout (origin,down) shifted (0,.2u);
enddef;

def p_breakdownchoke_NSS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.1u)--(-.15u,.05u)--(-.48u,.2u)--cycle;
    thdraw (-.2u,-.2u)--(.15u,-.18u)--(-.08u,.14u)--cycle;
    thdraw (.1u,0)--(.4u,-.1u)--(.5u,.2u)--(.1u,.2u)--cycle;
enddef;

def p_bedrock_ASF (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,0)--(.5u,0);
    thdraw (-.3u,0)--(-.3u,.2u);
    thdraw (.3u,0)--(.3u,-.2u);
enddef;

def p_sand_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenB;
    thdraw (0,.2u);
    thdraw (0,.2u) rotated 120;
    thdraw (0,.2u) rotated 240;
enddef;

def p_clay_SKBB (expr pos,theta,sc,al) =
    U:=(.3u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,0){up}..origin{down}..{up}(0.3u,0);
enddef;

def p_pebbles_UIS (expr pos,theta,sc,al)=
    U:=(.45u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75);
    thdraw p rotated 20 shifted (0,.25u);
    thdraw p rotated -37 shifted (.25u,-.25u);
    thdraw p rotated -62 shifted (-.25u,-.25u);
enddef;

def p_debris_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.4u)--(0,-.22u)--(-.4u,-.1u)--cycle;
    thdraw (.2u,-.4u)--(.4u,-.1u)--(.1u,-.1u)--cycle;
    thdraw (-.1u,0)--(.2u,.3u)--(-.2u,.3u)--cycle;
enddef;

def p_blocks_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.5u)--(.3u,-.4u)--(-.17u,.2u)--cycle;
    thdraw (.25u,-.25u)--(.5u,-.15u)--(.3u,.5u)--(-.1u,.5u)--cycle;
    thdraw (-.27u,0)--(-.1u,.3u)--(-.5u,.35u)--cycle;
    pickup PenD;
    thdraw (-.5u,-.5u)--(-.1u,-.2u)--(-.17u,.2u);
    thdraw (-.1u,-.2u)--(.3u,-.4u);
    thdraw (.25u,-.25u)--(.3u,0)--(.2u,.2u)--(-.1u,.5u);
    thdraw (.3u,.5u)--(.2u,.2u);
    thdraw (.5u,-.15u)--(.3u,0);
enddef;

def p_water_UIS (expr pos,theta,sc,al)=
    U:=(.425u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenD;
    p:=fullcircle xscaled (.85u) yscaled (.6u);
    thfill p withpattern pattern_water_UIS;
    thdraw p;
enddef;

def p_ice_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := (0,.05u)--(0,.35u);
    thdraw p;
    thdraw p shifted (-.25u,-.3u);
    thdraw p shifted (.25u,-.3u);
    p := (-0.15u,.2u)--(0.15u,.2u);
    thdraw p;
    thdraw p shifted (-.25u,-.3u);
    thdraw p shifted (.25u,-.3u);
enddef;

def p_snow_SKBB (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := origin--(0,.25*u);
    q := ((0,.35u)--(0,0.25u)--(0.1u,0.25u)) rotatedaround ((0,0.25u),45);
    thdraw p;
    thdraw p rotated (60);
    thdraw p rotated (120);
    thdraw p rotated (180);
    thdraw p rotated (240);
    thdraw p rotated (300);
    thdraw q;
    thdraw q rotated (60);
    thdraw q rotated (120);
    thdraw q rotated (180);
    thdraw q rotated (240);
    thdraw q rotated (300);
enddef;


def p_archeomaterial_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := fullcircle scaled .8u; 
    thdraw (-.5u,-.5u)--origin cutbefore p;
    thdraw (-.5u,.5u)--origin cutbefore p;
    thdraw origin--(.4u,0);
    thdraw p;
enddef;

def p_paleomaterial_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.4u,-.2u)..(-.2u,-.08u)---(-.1u,.05u)---(0,.2u)..(-.03u,.4u)..
        (.2u,.3u)..(.35u,.25u)..(.2u,.2u)---origin---(-.1u,-.17u)..
        (-.08u,-.25u){dir -120}..(-.3u,-.23u)
        ..cycle;
enddef;

def p_guano_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,.2u){dir 40}..{down}(0,-.35u){up}..{dir-40}(.4u,.2u);
enddef;

def p_vegetabledebris_ASF (expr pos,theta,sc,al)=
    U:=(.38u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.3u)--(0,.3u);
    thdraw (0,-.3u)--(.3u,.3u);
    thdraw (-.25u,.13u)--(.38u,.13u);
    thdraw (-.38u,-.13u)--(.25u,-.13u);
enddef;

def p_root_ASF (expr pos,theta,sc,al)=
    U:=(.1u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.1u,-.5u)--(-.1u,.5u);
    p:=(-.1u,-.3u)--(.1u,-.5u);
    thdraw p;
    thdraw p shifted (0,.2u);
    thdraw p shifted (0,.4u);
enddef;

def p_entrance_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.2u,-.5u)--(0,.5u)--(.2u,-.5u)--cycle;
enddef;

def p_waterflow_paleo_UIS (expr pos,theta,sc,al)=
    U:=(.2u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-u)--(0,u);
    thdraw halfcircle scaled .4u shifted (0,-.4u);
    p:=(-.15u,.6u)--(0,u)--(.15u,.6u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_gradient_UIS (expr pos,theta,sc,al)=
    U:=(.15u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-u)--(0,u);
    p:=(-.15u,.6u)--(0,u)--(.15u,.6u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_gradient_BCRA (expr pos,theta,sc,al)=
    U:=(.25u,0.7u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.25u,-0.7u)--(0,.7u)--(.25u,-.7u)--cycle;
enddef;

% by Philip Schuchardt
def p_gradient_NSS (expr pos,theta,sc,al) =
  U:=(.7u, .6u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;

  thdraw (-.3u, -.5u) -- (-.7u, -.2u);
  thdraw (-.2u, -.4u) -- (-.4u, .3u);
  thdraw (0u, -.3u) -- (0u, .6u);
  thdraw (.3u, -.5u) -- (.7u, -.2u);
  thdraw (.2u, -.4u) -- (.4u, .3u);
enddef;

def p_waterflow_permanent_UIS (expr pos,theta,sc,al)=
    U:=(.15u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(0,.5u){down}..(.12u,.3u)..(-.15u,.15u)..(.13u,0)..
        (-.08u,-.2u)..{down}(0,-.5u);
    p:=p rotated 180;
    thdraw p;
    thdrawoptions();
    oldahlength:=ahlength; ahlength:=2.5pt*optical_zoom;
    thdraw arrowhead p;
    thfill arrowhead p;
    ahlength:=oldahlength;
enddef;

def p_waterflow_intermittent_UIS (expr pos,theta,sc,al)=
  thdrawoptions(dashed evenly scaled (.5 * optical_zoom));
  p_waterflow_permanent_UIS (pos,theta,sc,al);
  thdrawoptions();
enddef;

def p_airdraught_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
	p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
	thdraw p;
	thdraw p reflectedabout (origin,(0,u));
	for i:=1 upto round(3+2*mlog(sc)/mlog 2):
	  thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
	endfor;
enddef;

def p_airdraught_winter_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
  p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
  thdraw p;
  thdraw p reflectedabout (origin,(0,u));
  for i:=1 upto round(3+2*mlog(sc)/mlog 2):
    thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
  endfor;
  thclean fullcircle scaled 0.6u shifted (0,0.05u);
  thdraw (-0.1732u,-0.05u) -- (0.1732u,0.15u);
  thdraw (0.1732u,-0.05u) -- (-0.1732u,0.15u);
  thdraw (0,-0.15u) -- (0,0.25u);
enddef;

def p_airdraught_summer_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
  p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
  thdraw p;
  thdraw p reflectedabout (origin,(0,u));
  for i:=1 upto round(3+2*mlog(sc)/mlog 2):
    thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
  endfor;
  thclean fullcircle scaled 0.6u shifted (0,0.05u);
  thdraw (-0.1732u,-0.05u) -- (0.1732u,0.15u);
  thdraw (0.1732u,-0.05u) -- (-0.1732u,0.15u);
  thdraw (0,-0.15u) -- (0,0.25u);
  thclean fullcircle scaled 0.3u shifted (0,0.05u);
  thdraw fullcircle scaled 0.2u shifted (0,0.05u);
enddef;


def p_station_fixed_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    pair z;
    z:=(0,.2u);
    thclean z -- (z rotated 120) -- (z rotated 240) -- cycle;
    thdraw z -- (z rotated 120) -- (z rotated 240) -- cycle;
    thdraw origin;
enddef;

def p_station_painted_SKBB (expr pos)=
    T:=identity shifted pos;
    pickup PenC;
    thclean fullcircle scaled 0.25u;
    thdraw fullcircle scaled 0.25u;
enddef;

def p_station_natural_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    thclean fullcircle scaled .3u;
    thdraw fullcircle scaled .3u;
    thdraw origin;
enddef;

def p_station_temporary_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    p:=(-.2u,0)--(.2u,0);
    thdraw p;
    thdraw p rotated 90;
    thclean fullcircle scaled .16u;
    pickup PenC;
    thdraw origin;
enddef;

let p_station_temporary_SKBB = p_station_painted_SKBB;

def p_steps_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.3u,.3u)--(-.3u,.1u)--(-.1u,.1u)--(-.1u,-.1u)--
           (.1u,-.1u)--(.1u,-.3u)--(.3u,-.3u);
enddef;

def p_fixedladder_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.15u,-.4u)--(-.15u,.4u);
    thdraw (.15u,-.4u)--(.15u,.4u);
    thdraw (-.15u,0)--(.15u,0);
    thdraw (-.15u,.2u)--(.15u,.2u);
    thdraw (-.15u,-.2u)--(.15u,-.2u);
enddef;

def p_ropeladder_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (.1u,-.4u)..(.2u,-.2u)..(.1u,.2u)..(.2u,.4u);
    thdraw (-.2u,-.4u)..(-.1u,-.2u)..(-.2u,.2u)..(-.1u,.4u);
    thdraw (-.2u,.2u)--(.1u,.2u);
    thdraw (-.15u,0)--(.15u,0);
    thdraw (-.1u,-.2u)--(.2u,-.2u);
enddef;

def p_bridge_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.3u,.2u)--(-.2u,.1u)--(.2u,.1u)--(.3u,.2u);
    thdraw (-.3u,-.2u)--(-.2u,-.1u)--(.2u,-.1u)--(.3u,-.2u);
enddef;

def p_noequipment_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    thfill (0,-.1u)--(-.05u,.3u)--(.05u,.3u)--cycle;
    thdraw (0,-.2u) withpen PenX;
enddef;

def p_anchor_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    thdraw fullcircle scaled .2u shifted (0.2u,0) withpen PenC;
    begingroup;
      interim linecap:=butt;
      thdraw (-.3u,0)--(.1u,0) withpen PenA;
    endgroup;
    thdraw (.1u,-.4u)--(.1u,.4u) withpen PenD;
enddef;

def p_traverse_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.25u,.05u)..(0,-.08u)..(.25u,.05u);
    pickup pencircle scaled .18u;
    thdraw (-.25u,.05u);
    thdraw (.25u,.05u);
enddef;

def p_rope_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.2u,.2u)..origin..(.1u,.1u)--(.1u,-.4u);
    pickup pencircle scaled .18u;
    thdraw (-.2u,.2u);
    thdraw (.1u,.1u);
enddef;

def p_camp_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .5u);
    T:=identity aligned al shifted pos;
    pickup PenC;
    thdraw (-.4u,-.4u)--(0,.5u)--(.4u,-.4u)--cycle;
    pickup PenD;
    thdraw (0,-.4u)--(0,.5u);
enddef;


def p_dig_UIS (expr pos,r,s,al) = 
    U:=(.4u, .5u);
    T:=identity aligned al shifted pos;
    thfill ((-.075u,-.5u){down} .. {up}(0.075u, -.5u) -- (0.075u, .15u) -- (0.3u, 0.15u) -- (0.3u, 0.5u) --
    (-.3u, .5u) -- (-.3u, .15u) -- (-.075u, .15u) -- cycle) rotated 45;
enddef;

def p_continuation_UIS(expr pos,theta,sc,al) =
  U:=(.15u,.3u);
  T:=identity aligned al shifted pos;
  pickup PenC;
  thdraw (-.1u,.2u){up}..{down}(.1u,.2u)..{down}(0,-.05u);
  pickup PenX;
  thdraw (0,-.2u);
enddef;

def p_station_SKBB(expr pos,mark,txt)(text flags) =
  T:=identity shifted pos;

  if mark=4: p_station_fixed(pos)
  elseif mark=3: p_station_natural(pos)
  elseif mark=2: p_station_painted(pos)
  elseif mark=1: p_station_temporary(pos)
  fi;
  
  path path_cave;
  path_cave = (-.3u,-.25u) -- (-.2u,-.25u){dir 135} .. (0, .25u) .. {dir 225}(.2u,-.25u) -- (.3u,-.25u);
  for i=flags:
    pickup PenX;
    if i="entrance":
%      thfill fullcircle scaled 1 cm withtransparentcolor tr_blue;
      thdraw path_cave;
%      p_label.urt(txt,pos+(0.4u,0),0,0);
      if not numeric txt:
        p_smartlabel(txt,pos);
      fi;
    elseif i="sink":
      thdraw path_cave cutbefore ((-u,0)--(u,0)) cutafter ((-u,0)--(u,0));
      pickup PenA;
      thdraw (0,-.45u) -- (0,.05u) withcolor blue;
      thdraw (-.15u,-.02u) -- (0,.05u) -- (.15u,-.02u) withcolor blue;
    elseif i="spring":
      thdraw path_cave cutbefore ((-u,0)--(u,0)) cutafter ((-u,0)--(u,0));
      pickup PenA;
      thdraw (0,-.45u) -- (0,.05u) withcolor blue;
      thdraw (-.15u,-.38u) -- (0,-.45u) -- (.15u,-.38u) withcolor blue;
    elseif i="doline":
      thdraw (-.5u,.05u){down}..(0,-0.6u)..{up}(.5u,.05u);
    elseif i="dig":
      thdraw (-.5u,.25u) -- (-.35u,.25u)--(-.23u,-.25u)--(.23u,-.25u)--(.35u,.25u)--(.5u,.25u);
    elseif substring(0,11) of i = "air-draught":
      pickup PenB;
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u));
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u)) shifted (.11u,0);
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u)) shifted (-.11u,0);
    elseif i="continuation":
      if picture(txt):
        picture ATTR__text;
        ATTR__text := txt;
      fi;
      begingroup;
        save T; transform T;
        p_continuation(pos+(0,.25u),0,1,(0,1));
      endgroup;
      if picture(txt):
        save ATTR__text;
      fi;
    elseif i="arch":
      thdraw (-.5u,-.25u)--(-.5u,.25u)--(.5u,.25u)--(.5u,-.25u)..(0,.2u)..cycle;
      thfill (-.5u,-.25u)--(-.5u,.25u)--(.5u,.25u)--(.5u,-.25u)..(0,.2u)..cycle;
    elseif i="overhang":
      thdraw (.2u,-.25u)--(-.2u,-.25u){up}..{right}(.2u,.25u);
    fi;
  endfor;
%  thdraw (0,0) withpen PenX withcolor red;
enddef;

def p_debug (expr col, pen, pos)=
    T:=identity shifted pos;
    thdraw origin withpen pencircle 
      scaled if pen=0: 2pt 
                 else: 4pt fi 
      withcolor if col=-2: (1,.85,0)
           elseif col=-1: black 
           elseif col=0: red 
           else: blue fi;
enddef;


def p_u(expr pos,theta,sc,al) =
  T:=identity shifted pos;
  thdraw origin withpen pencircle scaled 4pt withcolor red;
enddef;

def p_handrail_SKBB(expr pos,theta,sc,al) =
    tmph := 1 / Scale * 72 / 2.54;  % 1 m height
    U:=(.1u, tmph);
    pickup PenC;
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thdraw (0,0) -- (0,tmph);
    thdraw (0,tmph) withpen pencircle scaled .25u;    
enddef;

def p_viaferrata_SKBB(expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.15u,.15u)--(-.15u,.1u)--(.15u,.1u)--(.15u,.15u);
    thdraw (-.15u,-.05u)--(-.15u,-.1u)--(.15u,-.1u)--(.15u,-.05u);
enddef;

def p_stalagmites_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
        thdraw (0,-.15u) -- (.15u,-.4u);
    endfor;
enddef;

def p_stalactites_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
        thdraw (0,.15u) -- (.15u,.4u);
    endfor;
enddef;

def p_gradient_SKBB (expr pos,theta,sc,al)=
    U:=(.3u,.6u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.6u)--(-.3u,.6u);
    thdraw (0,-.6u)--(0,-0.2u);
    thdraw (.3u,-.6u)--(.3u,.6u);
enddef;

def p_pillars_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,.15u)--(0,-.15u);
        thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
        thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    endfor;
enddef;





%%%%% ENDINPUT thPoint %%%%%





%%%%% INPUT thLine %%%%%


%% therion source code
%%
%% This file defines macros for line symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thLine.mp,v $
%% $Revision: 1.4 $
%%
%% Copyright (C) 2000 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

% some definitions

% adjust step according to the length of the path; return at least two steps

vardef adjust_step (expr len, s) =
  if s <= len/2: len / (floor(len / s))
  else: len/2 fi
enddef;

def mark_(expr p,t,l) =
  thdraw (point t of p) --
          ((point t of p) + l * unitvector(thdir(p,t) rotated 90));
enddef;

vardef thdir (expr p,t) =    % 1 * epsilon caused problems in scales < 1:1000
                             % n * epsilon is enough for scale 1:(n*1000)
  if arclength(p)=0:
    hide(thwarning("unable to determine direction on zero-length path"))
    (0,1)
  else:
%  ((direction t-100*epsilon of p) + (direction t+100*epsilon of p)) / 2
   postcontrol (t+1000*epsilon) of p - precontrol (t-1000*epsilon) of p
%  direction t of p
  fi
enddef;

% walls:

def l_wall_bedrock_UIS (expr P) = 
  T:=identity;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_sand_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.1u);
  pickup PenB;  
  forever:
    t := arctime cas of P;
    thdraw ((point t of P) + (uniformdeviate 1) * .4u 
            * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenA;  
  thdraw P;
enddef;

def l_wall_pebbles_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .35u);
  pickup PenC;
  q:=superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/20) rotated (angle(thdir(P,t)) + (normaldeviate*40)) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_wall_clay_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .5u);
  pickup PenC;
  q := (-0.15u,0){up}..{down}origin..{up}(0.15u,0);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  pickup PenA;  
  thdraw P;
enddef;

def l_wall_debris_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .4u);
  pickup PenC;
%  q := ((-.1u,-.15u)--(.2,.03u)--(-.2u,.15u)--cycle) scaled 1.5;
  q := ((-.2u,-.1u)--(.2u,-.1u)--(0,.2u)--cycle) scaled 1.1;
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/10) rotated uniformdeviate (360) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_wall_blocks_SKBB (expr P) = 
%  pickup PenD;
%  draw P withcolor red;

  T:=identity;
  cas := 0;
  dlzka := arclength P;
if dlzka > 0:
  mojkrok:=adjust_step(dlzka, 1.5u);
  pickup PenA;
  forever:
    t1 := arctime (cas + mojkrok*1/10) of P;
    t2 := arctime (cas + mojkrok*9/10) of P;
    q := ((point t1 of P) + .4u * unitvector(thdir(P,t1) rotated -90)) --
         (subpath (t1,t2) of P) --
         ((point t2 of P) + .4u * unitvector(thdir(P,t2) rotated -90));
    thdraw q randomized (u/6);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
fi;
enddef;

def l_wall_ice_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .5u);
  pickup PenC;
  p := (-.1u,0)--(.1u,0);
  q := (0,-.1u)--(0,.1u);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw p shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    thdraw q shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  pickup PenA;  
  thdraw P;
enddef;

def l_wall_underlying_UIS (expr P) = 
  T:=identity;
  pickup PenA;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_wall_unsurveyed_SKBB (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P;
enddef;

def l_wall_presumed_UIS (expr P) = 
  T:=identity;
  pickup PenA;
  thdraw P dashed evenly scaled (2*optical_zoom);
enddef;

% other line symbols

def l_pit_UIS (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.25u);
  pickup PenD;  
  forever:
    t := arctime cas of P;
    mark_ (P,t,0.2u);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenC;  
  thdraw P;
enddef;

let l_floorstep_UIS = l_pit_UIS;

def l_overhang_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.3u);
  pickup PenC;
  t1:=0;
  forever:
    t := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok) of P;
    thfill (subpath (t1,t2) of P) -- 
      ((point t of P) + .3u * unitvector(thdir(P,t) rotated 90)) -- 
      cycle;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
    t1:=t2;
  endfor;
  thdraw P;
enddef;


def l_chimney_UIS (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_ceilingstep_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);
  pickup PenC;
  forever:
    t1 := arctime (cas + mojkrok*1/5) of P;
    t  := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok*4/5) of P;
    thdraw (subpath (t1,t2) of P);
    mark_ (P,t,0.2u);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_ceilingmeander_SKBB (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);
  pickup PenC;
  forever:
    t  := arctime (cas + mojkrok/2) of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.1u * Pv) --
          (Pp + 0.2u * Pv);
    thdraw (Pp + 0.2u * Pv + 0.2u * Pd) --
          (Pp + 0.2u * Pv - 0.2u * Pd);
    thdraw (Pp - 0.1u * Pv) --
          (Pp - 0.2u * Pv);
    thdraw (Pp - 0.2u * Pv + 0.2u * Pd) --
          (Pp - 0.2u * Pv - 0.2u * Pd);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;


%Bruce Mutton 2012.06.16 uses general code for l_ceilingmeander_SKBB defined in therion source code by Martin Budaj 5.3.9
% but ticks on outside (rock) side of lines 
def l_ceilingmeander_UIS (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  T:=identity;
  cas := 0;                           % cursor to step along path
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);  % symbol length nudged to be multiple of path length
  pickup PenC;
  forever:
    t  := arctime (cas + mojkrok/2) of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.2u * Pv) --
          (Pp + 0.3u * Pv);              % add 0.1u to each moves ticks outside
    thdraw (Pp + 0.2u * Pv + 0.2u * Pd) --
          (Pp + 0.2u * Pv - 0.2u * Pd);  
    thdraw (Pp - 0.2u * Pv) --
          (Pp - 0.3u * Pv);              % subtract 0.1u to each moves ticks outside
    thdraw (Pp - 0.2u * Pv + 0.2u * Pd) --
          (Pp - 0.2u * Pv - 0.2u * Pd); 
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3);  % for rounding errors
  endfor;
enddef;

let l_ceilingmeander_NZSS = l_ceilingmeander_UIS;

%Bruce Mutton 2012.06.16 uses general code for l_ceilingstep_SKBB defined in therion source code by Martin Budaj 5.3.9
% but ticks on righthand (rock) side of line 
def l_ceilingstep_UIS (expr P) =
  T:=identity;
  cas := 0;                            % cursor to step along path
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);   % symbol length nudged to be multiple of path length
  pickup PenC;
  forever:
    t1 := arctime (cas + mojkrok*1/5) of P;
    t  := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok*4/5) of P;
    thdraw (subpath (t1,t2) of P);
    mark_ (P,t,-0.2u);                  % change sign to -0.2u
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

let l_ceilingstep_NZSS = l_ceilingstep_UIS;

%Bruce Mutton 2012.06.10 uses general code for l_pit_UIS defined in therion source code by Martin Budaj 5.3.9
% dots on righthand (rock) side of line spaced 0.2u, 0.2u same as floor-step ticks
def l_chimney_NZSS (expr P) = 
	T:=identity;
	cas := 0;                            % cursor to step along path
	dlzka := arclength P;
	mojkrok:=adjust_step(dlzka, 0.25u);  % symbol length nudged to be multiple of path length
	q:= (0.20u,-0.20u) -- (0.21u,-0.21u);         % dot

	pickup PenC;  %2nd thinnest pen
	forever:
	  t := arctime cas of P;
	thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % draw dots
	cas := cas + mojkrok;
	  exitif cas > dlzka + (mojkrok / 3); % for rounding errors
	endfor;
	pickup PenB;   %2nd thickest pen
	thdraw P;      %continuous line
enddef;

%Bruce Mutton 2010.06.20 uses general code and adjust_step defined in therion source code by Martin Budaj
%for Therion 5.3.8
def l_wall_presumed_NZSS (expr P) =
	T:=identity;
	cas := 0;                                 % cursor to step along path
	dlzka := arclength P;
	mojkrok:=adjust_step(dlzka, 1.5u);        % symbol length nudged to be multiple of path length
	q  := (-0.2u,-0.4u)--(0,0)--(0.2u,-0.4u); % define v shape 
	forever:
	  t1 := arctime (cas + mojkrok*1/5) of P;
	  t  := arctime (cas + mojkrok/2) of P;
	  t2 := arctime (cas + mojkrok*4/5) of P;
		pickup PenA;                          % thick
	thdraw (subpath (t1,t2) of P);          % dash
	  pickup PenC;                          % thin
	  thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % v shape

	  cas := cas + mojkrok;
	  exitif cas > dlzka - (2*mojkrok/3);     % for rounding errors
	endfor;
enddef;

def l_floormeander_SKBB (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  pair PPp;
  pair PPd;
  pair PPv;

  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.25u);
  pickup PenC;
  forever:
    t := arctime cas of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.1u * Pv) --
          (Pp + 0.2u * Pv);
    thdraw (Pp - 0.1u * Pv) --
          (Pp - 0.2u * Pv);
    if cas > 0:
      thdraw (PPp + 0.2u * PPv) --
          (Pp + 0.2u * Pv);
      thdraw (PPp - 0.2u * PPv) --
          (Pp - 0.2u * Pv);
    fi;
    PPp := Pp;
    PPd := Pd;
    PPv := Pv;
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
enddef;    

boolean alw_perpendicular;

def l_slope_SKBB (expr P,S)(text Q) = 
%show Q;
  T:=identity;
  numeric dirs[];
  numeric lengths[];
  for i=Q:
    dirs[redpart i]:=greenpart i;
    lengths[redpart i]:=bluepart i;
  endfor;  


  li:=length(P); % last

  alw_perpendicular:=true;

  for i=0 upto li:
    if unknown dirs[i]: dirs[i]:=-1; 
    else: 
      if dirs[i]>-1:
        dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360; 
        alw_perpendicular:=false;
      fi;
    fi;
    if unknown lengths[i]: lengths[i]:=-1; fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    d:=dirs[i];
    if d=-1:
      if (i=0) or (i=li):
        dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
	pi:=i;
      else:
        if ni<=i:
	  for j=i upto li:
            ni:=j;
	    exitif dirs[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	dirs[i]:=w[dirs[pi],dirs[ni]];
%        if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%          dirs[i]:=w[dirs[ni],dirs[pi]];
%	  message("*******");
%        fi;
     fi;
    else:
      pi:=i;
    fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    l:=lengths[i];
    if l=-1:
      if (i=0) or (i=li):
        lengths[i] := 1cm; % should never happen!
	thwarning("slope width at the end point not specified");
	pi:=i;
      else:
        if ni<=i:
	  for j=i+1 upto li:
            ni:=j;
	    exitif lengths[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	lengths[i]:=w[lengths[pi],lengths[ni]];
	pi:=i;
      fi;
    else:
      pi:=i;
    fi;
  endfor;

% for i=0 upto li: show lengths[i]; endfor;

  T:=identity;
  boolean par;
  offset:=0;
  dlzka := (arclength P);
  if dlzka>3u: 
    offset := 0.3u;
  elseif dlzka>u:
    offset := 0.1u;
  fi;
  dlzka:=dlzka-2offset;
  cas := offset;
  mojkrok:=adjust_step(dlzka,1.4u) / 2;
  pickup PenD;
  par := false; 
  forever:
    t := arctime cas of P;
    if t mod 1>0:  % not a key point
      w := (arclength(subpath(floor t,t) of P) / 
            arclength(subpath(floor t,ceiling t) of P));
      if alw_perpendicular:
        a := 90;
      else:
        a := w[dirs[floor t],dirs[ceiling t]];
      fi;
      l := w[lengths[floor t],lengths[ceiling t]];
    else:
      if alw_perpendicular:
        a := 90;
      else:
        a:= dirs[t];
      fi; 
      l:=lengths[t];
    fi;
    
    a := a + angle(thdir(P,t));
    
    thdraw (point t of P) -- 
      ((point t of P) + if par: 0.333 * fi l * unitvector(dir(a)));
    cas := cas + mojkrok;
    par := not par;
    exitif cas > dlzka + offset + 0.1mm;  % for rounding errors
  endfor;
  if S = 1: pickup PenC; draw P fi;
%pickup pencircle scaled 3pt;
%for i=0 upto li: draw point i of P; endfor;
enddef;


def l_slope_BCRA (expr P,S)(text Q) = 
%show Q;
  T:=identity;
  numeric dirs[];
  numeric lengths[];
  for i=Q:
    dirs[redpart i]:=greenpart i;
    lengths[redpart i]:=bluepart i;
  endfor;  


  li:=length(P); % last

  alw_perpendicular:=true;

  for i=0 upto li:
    if unknown dirs[i]: dirs[i]:=-1; 
    else: 
      if dirs[i]>-1:
        dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360; 
        alw_perpendicular:=false;
      fi;
    fi;
    if unknown lengths[i]: lengths[i]:=-1; fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    d:=dirs[i];
    if d=-1:
      if (i=0) or (i=li):
        dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
	pi:=i;
      else:
        if ni<=i:
	  for j=i upto li:
            ni:=j;
	    exitif dirs[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	dirs[i]:=w[dirs[pi],dirs[ni]];
%        if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%          dirs[i]:=w[dirs[ni],dirs[pi]];
%	  message("*******");
%        fi;
     fi;
    else:
      pi:=i;
    fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    l:=lengths[i];
    if l=-1:
      if (i=0) or (i=li):
        lengths[i] := 1cm; % should never happen!
	thwarning("slope width at the end point not specified");
	pi:=i;
      else:
        if ni<=i:
	  for j=i+1 upto li:
            ni:=j;
	    exitif lengths[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	lengths[i]:=w[lengths[pi],lengths[ni]];
	pi:=i;
      fi;
    else:
      pi:=i;
    fi;
  endfor;

% for i=0 upto li: show lengths[i]; endfor;

  T:=identity;
  boolean par;
  offset:=0;
  dlzka := (arclength P);
  if dlzka>3u: 
    offset := 0.3u;
  elseif dlzka>u:
    offset := 0.1u;
  fi;
  dlzka:=dlzka-2offset;
  cas := offset;
  mojkrok:=adjust_step(dlzka,1.4u) / 2;
  pickup PenD;
  par := false; 
  forever:
    t := arctime cas of P;
    if t mod 1>0:  % not a key point
      w := (arclength(subpath(floor t,t) of P) / 
            arclength(subpath(floor t,ceiling t) of P));
      if alw_perpendicular:
        a := 90;
      else:
        a := w[dirs[floor t],dirs[ceiling t]];
      fi;
      l := w[lengths[floor t],lengths[ceiling t]];
    else:
      if alw_perpendicular:
        a := 90;
      else:
        a:= dirs[t];
      fi; 
      l:=lengths[t];
    fi;
    
    a := a + angle(thdir(P,t));
    
    if par:
      thfill (point t of P) + mojkrok/2.5 * unitvector(dir(a+90))-- 
        ((point t of P) + l * unitvector(dir(a))) --
        (point t of P) + mojkrok/2.5 * unitvector(dir(a-90)) -- cycle;
    fi;
    cas := cas + mojkrok;
    par := not par;
    exitif cas > dlzka + offset + 0.1mm;  % for rounding errors
  endfor;
enddef;


def l_contour_UIS(expr P)(text txt) =
  T:=identity;
  pickup PenD;
  thdraw P;
  for pnt=txt:
    if pnt=-2:
      mark_(P,arctime(arclength(P)/2) of P, 0.2u);
    elseif pnt>=0:
      mark_(P,pnt,0.2*u);
    fi;
    exitif pnt<0;
  endfor;
enddef;

def l_contour_SKBB(expr P)(text txt) =
  T:=identity;
  pickup PenD;
  thdraw P;
  for pnt=txt:
    if (pnt=-2) or (pnt=-1):
      mark_(P,arctime(arclength(P)/2) of P, 0.2u);
    elseif pnt>=0:
      mark_(P,pnt,0.2*u);
    fi;
    exitif pnt<0;
  endfor;
enddef;

def l_rockborder_UIS (expr P) = 
  T:=identity;
  pickup PenC;
  if cycle P: thclean P fi;
  thdraw P;
enddef;

def l_rockedge_UIS (expr P) = 
  T:=identity;
  pickup PenD;
  thdraw P;
enddef;

def l_border_visible_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path;
enddef;

def l_border_temporary_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path dashed evenly scaled optical_zoom;
enddef;

def l_flowstone_UIS (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .7u);
  if (cycle P) and (dlzka < 3.5u):   % make at least 5 curls on a cyclic path
    mojkrok := dlzka/5;
  fi;
  pickup PenC;  
  t1:=0;
  forever:
    t2 := arctime (cas + mojkrok) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 60)} ..
           {dir (angle(thdir(P,t2)) - 60)}(point t2 of P);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
    t1:=t2;
  endfor;
enddef;


def l_moonmilk_UIS (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .3u);
  pickup PenC;  
  t1:=0;
  forever:
    t2 := arctime (cas + mojkrok) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 80)} ..
           {dir (angle(thdir(P,t2)) - 80)}(point t2 of P);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
    t1:=t2;
  endfor;
enddef;


def l_survey_surface_SKBB (expr P) =
  T:=identity;
  thdrawoptions(dashed withdots scaled (0.2 * optical_zoom) withpen PenC);
  thdraw P;
  thdrawoptions();
enddef;

def l_survey_cave_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  if ATTR__scrap_centerline:
    thdraw P;
  else:
    PolygonLine:=.8u;
    pair zz[];
    for t = 0 upto length P - 1:
      zz1 := point t of P;
      zz2 := point t+1 of P;
      if length (zz2-zz1) > 2*PolygonLine:
        thdraw zz1 -- zz1 + PolygonLine * unitvector(zz2 - zz1);
        thdraw zz2 -- zz2 + PolygonLine * unitvector(zz1 - zz2);
      else:
        thdraw zz1 -- zz2;
      fi;
    endfor;
  fi;
enddef;

def l_survey_cave_UIS (expr P) =
  T:=identity;
  pair zz[];
  pickup PenC;
  for t = 0 upto length P - 1:
    zz1 := point t of P;
    zz2 := point t+1 of P;
    draw zz1 -- zz2;
  endfor;
enddef;

def l_waterflow_permanent_UIS (expr Path) =
  path ppp;
  T:=identity;
  cas := 0;
  dlzka := arclength Path;
  mojkrok:=adjust_step(dlzka, 0.5u);
    pickup PenD;  
    vardef azim = 50 + 15*normaldeviate enddef;
    az1 := azim;
    sgn := 1;
    ppp := point 0 of Path;
    forever:
        t1 := arctime cas of Path;
        t2 := arctime (cas+mojkrok) of Path;
        if cas+1.1*mojkrok > dlzka:
            az2 := 0;
        else:
            az2 := azim;
        fi;
        d1 := angle(thdir(Path,t1)) + sgn * az1;
        d2 := angle(thdir(Path,t2)) - sgn * az2;
        ppp := ppp & (point t1 of Path){dir d1} .. {dir d2}(point t2 of Path);
        az1 := az2;
        sgn := -1 * sgn;
        cas := cas + mojkrok;
        exitif cas > dlzka + mojkrok/3;     % for rounding errors
    endfor;
%    drawarrow ppp;
    thdraw ppp;
    thdrawoptions();
    oldahlength:=ahlength;
    ahlength:=ahlength*optical_zoom;
    thdraw arrowhead ppp;
    thfill arrowhead ppp;
    ahlength:=oldahlength;
enddef;

def l_waterflow_intermittent_SKBB (expr Path) =
  thdrawoptions(dashed evenly scaled optical_zoom);
  l_waterflow_permanent_UIS (Path);
  thdrawoptions();
enddef;

def l_waterflow_conjectural_SKBB (expr Path) =
  thdrawoptions(dashed withdots scaled (0.5 * optical_zoom) withpen PenB);
  l_waterflow_permanent_UIS (Path);
  thdrawoptions();
enddef;

def l_invisible (expr P) = 
enddef;

def l_undefined (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P withcolor red;
  thwarning("undefined line symbol used");
enddef;

% Q = 0 -- no arrows
%     1 -- end
%     2 -- begin
%     3 -- both

def l_arrow_SKBB (expr P, Q) =
  T:=identity;
  pickup PenC;
  thdraw P;
  p := (-.1u,-.25u)--(0,0)--(.1u,-.25u);
  if odd Q:
    draw p rotated (angle(thdir(P,0))+90) shifted (point 0 of P);
  fi;
  if Q>1:
    draw p rotated (angle(thdir(P,length P))-90) 
         shifted (point infinity of P);
  fi;
enddef;

def l_mapconnection_SKBB (expr P) =
  thdrawoptions(dashed withdots scaled (0.5 * optical_zoom) withpen PenB);
  l_arrow_SKBB(P,3);
  thdrawoptions();
enddef;


def l_section_SKBB (expr P)(text txt) =
  T:=identity;
  path Q; Q = punked P;
  pickup PenC;
  for t = 0 upto length P - 1:
    pair zz[];
    zz1 := point t of P;
    zz2 := point t+1 of P;
    zz3 := postcontrol t of P;
    zz4 := precontrol t+1 of P;
    if (length(zz3-1/3[zz1,zz2]) > 0.1pt) or
       (length(zz4-2/3[zz1,zz2]) > 0.1pt):
      zz5 = whatever[zz1,zz2];
      (zz3-zz5) = whatever * (zz1-zz2) rotated 90;
      draw zz1--zz5;
      zz6 = whatever[zz1,zz2];
      (zz4-zz6) = whatever * (zz1-zz2) rotated 90;
      draw zz2--zz6;
    else:
      draw zz1--zz2;
    fi;
  endfor;
  for pnt=txt:
    if pnt=-1:
    else:
      T:=identity rotated angle(thdir(Q,pnt)) shifted (point pnt of Q);
      pickup PenC;
      thdraw (0,0)--(0,.8u);
      thdraw (-.1u,.55u)--(0,.8u)--(.1u,.55u);
    fi;
    exitif pnt=-1;
  endfor;
enddef;

let l_border_invisible = l_invisible;
let l_wall_invisible = l_invisible;

def l_debug (expr col, pen, P) =
  T:=identity;
  pickup if pen=0: PenD else: PenB fi;
  thdraw P 
    withcolor if col=-2: (1,.85,0)
          elseif col=-1: black 
           elseif col=0: red 
                   else: blue fi;
enddef;


def l_u (expr P) =
  T:=identity;
  pickup PenA;
  thdraw P withcolor red;
enddef;


def l_gradient_UIS (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P;
  p:=(-.15u,-.4u)--(0,0)--(.15u,-.4u)--cycle;
  thfill (p rotated (angle(thdir(P,length P))-90) 
         shifted (point infinity of P));
  thdraw (p rotated (angle(thdir(P,length P))-90) 
         shifted (point infinity of P));
enddef;

def l_gradient_BCRA (expr P) =
  T:=identity;
  pickup PenC;
  for t = 0 upto length P - 1:
    pair zz[];
    zz1 := point t of P;
    zz2 := point t+1 of P;
    zz3 := unitvector(zz2 - zz1);
    thfill zz1 + u/3 * zz3 + .25u * (zz3 rotated 90) --
           zz2 - u/3 * zz3 --
	   zz1 + u/3 * zz3 + .25u * (zz3 rotated -90) -- cycle;
  endfor;
enddef;


def l_rope_SKBB (expr P,exact) =
  T:=identity;
  pickup PenC;
  if exact:
    draw P;
  else:
    d:=0.5u;
    for i:=0 upto (length P - 2):
      x1 := xpart point i of P;
      y1 := ypart point i of P;
      x2 := xpart point i+1 of P;
      y2 := ypart point i+1 of P;
    
      dx1:=x1; dy1:=y1; x1:=0; y1:=0; x2:=x2-dx1; y2:=y2-dy1;
      if y2 > y1:
        y3 := y1 - d;
        x3 := x1 + (x2-x1)*sqrt(d)/(sqrt(d)+sqrt(y2-y1+d));
      else:
        y3 := y2 - d;
        x3 := x1 + (x2-x1)*sqrt(y1-y2+d)/(sqrt(d)+sqrt(y1-y2+d));
      fi;
      numeric a,b,c;
      a*x1/10*x1 + b/10*x1 + c/10 = y1/10;
      a*x2/10*x2 + b/10*x2 + c/10 = y2/10;
      a*x3/10*x3 + b/10*x3 + c/10 = y3/10;
      draw (x1+dx1,y1+dy1)
      for t = x1 step (x2-x1)/20 until x2+10*epsilon:
        -- (t+dx1,a*t*t+b*t+c+dy1)
      endfor;
    endfor;
    pair x;
    x = point (length P)-1 of P + whatewer * down;
    x = point (length P) of P + whatever * right;
    draw point (length P)-1 of P -- x;
%    thdraw point length P of P withpen pencircle scaled 0.3u withcolor red;
  fi;
  for i:=0 upto length P if not exact: -1 fi:
    thdraw point i of P withpen pencircle scaled 0.3u;
  endfor;
enddef;

def l_border_presumed_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path dashed evenly scaled (0.25 * optical_zoom);
enddef;

def l_steps_SKBB (expr P) =
 if known ATTR_c: c := scantokens ATTR_c; else: c := 2; fi;
 if ATTR__elevation:
   if (c < 2):
     thwarning("Invalid stairs definition (c<2)");
     pickup PenA;
     draw P withcolor red;
   else:
     path PP;
     if (ypart point 0 of P) < (ypart point length P of P):
       PP := P;
     else:
       PP := reverse P;
     fi;
     path p;     
     for j:=0 upto ((length PP) - 1):
       p := (point j of PP) -- (point (j + 1) of PP);
       c := ceiling(abs((ypart point 0 of p) - (ypart point length p of p)) / (0.2 / Scale * 72 / 2.54));  % 20 cm height
       if (c < 2): c:=2 fi;
       pair cp;
       cp = point length p of p - point 0 of p;
       dx := (xpart cp) / c;
       dy := (ypart cp) / c;
       cp := point 0 of p;
       for i:= 0 upto c - 1:
         l_border_visible(cp -- cp + (0,dy) -- cp + (dx,dy));
         cp := cp + (dx, dy);
       endfor;
       %draw P;
     endfor;
   fi;
 else:
   if known ATTR_l: l := scantokens ATTR_l; else: l := (length(P)-2)/2; fi;
   if ((length(P) < 4) or (c < 2)) or ((odd length P) and (not known ATTR_l)):
     thwarning("Invalid stairs definition" if c<2: &" (c<2)" fi);
     pickup PenA;
     draw P withcolor red;
   else:
     path p, q;
     p = subpath (1, 1+l) of P;
     q = reverse subpath (l+2, length(P)) of P;
     lp := arclength(p);
     lq := arclength(q);
     for i=1 upto c:
       l_border_visible(point(arctime ((i-1)/(c-1)*lp) of p) of p -- point(arctime ((i-1)/(c-1)*lq) of q) of q);
     endfor;
     l_border_visible(p);
     l_border_visible(q);
     drawoptions(withcolor 0.3*white);
     %p_label(decimal c, point 0.5 of P, 0, 6);
     drawoptions();
   fi;
 fi;
enddef;

def l_handrail_SKBB (expr P) = 
    if ATTR__elevation:
      T:=identity;
      cas := 0;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, 1u);
      pickup PenD;  
      pair tmppoint;
      tmph := 1 / Scale * 72 / 2.54;  % 1 m height
      tmppoint:=(point 0 of P) +(0,tmph);
      forever:
        t := arctime cas of P;
        draw point t of P -- (point t of P)+(0,tmph) withpen PenD;
        if cas > 0:
          draw tmppoint -- (point t of P)+(0,tmph) withpen PenC;
          tmppoint := (point t of P)+(0,tmph);
        fi;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
    else:
      T:=identity;
      cas := 0;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, u);
      pickup PenD;  
      forever:
        t := arctime cas of P;
        thdraw point t of P withpen pencircle scaled .25u;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
      pickup PenC;  
      thdraw P;
    fi;
enddef;

def l_fixedladder_SKBB (expr P) = 
  pickup PenD;
  draw P withcolor red;
enddef;

def l_ropeladder_SKBB (expr P) = 
  pickup PenD;
  draw P withcolor red;
enddef;

def l_viaferrata_SKBB (expr P) = 
  pickup PenD;
  draw P withcolor red;
enddef;




%%%%% ENDINPUT thLine %%%%%





%%%%% INPUT thArea %%%%%


%% therion source code
%%
%% This file defines tiling patterns
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thPatterns.mp,v $
%% $Revision: 1.6 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

if unknown a_water_UIS: else: endinput fi;

% patterns

beginpattern(pattern_water_UIS);
    draw origin--10up withpen pensquare scaled (0.02u);
    patternxstep(.18u);
    patterntransform(identity rotated 45);
endpattern;

beginpattern(pattern_sump_UIS);
    draw origin--(0,.25u) withpen pensquare scaled (0.02u);
    draw origin--(.25u,0) withpen pensquare scaled (0.02u);
    patterntransform(identity rotated 45);
endpattern;

beginpattern(pattern_sand_UIS);
    pickup PenC;
    draw (0.2u,.3u);
    draw (0.35u,.7u);
    draw (0.6u,.5u);
    draw (0.8u,.1u);    
endpattern;

beginpattern(pattern_debris_SKBB);
    pickup PenC;
    p:=(-.15u,0)--(.15u,0);
    draw p rotated -40 shifted (.2u,.3u);
    draw p rotated 70 shifted (.9u,1.5u);
    draw p rotated 20 shifted (1.5u,.8u);
%    draw p rotated 95 shifted (.9u,.8u);
endpattern;


beginpattern(pattern_moonmilk_SKBB);
    pickup PenC;
    p:=(-.5u,0){down} .. {up}(-.1666u,0){down}..
        {up}(.1666u,0){down} .. {up}(.5u,0);
    draw p;
    draw p shifted (0.5u,0.3u);
    patternxstep(1.0u);
    patternystep(0.6u);
endpattern;


beginpattern(pattern_flowstone_ASF);
    pickup PenC;
    p:=(-.35u,0){dir -60} .. {dir 60}(0.35u,0);
    draw p;
    draw p shifted (0.35u,0.4u);
    patternxstep(u);
    patternystep(0.8u);
endpattern;


beginpattern(pattern_empty);
  patternbbox(0,0,10,10);
  patternstep(10,10);
endpattern;

% symbols

def a_water_UIS (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_water_UIS;
enddef;

def a_sump_UIS (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_sump_UIS;
enddef;


def a_flowstone_ASF (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_flowstone_ASF;
enddef;


def a_moonmilk_SKBB (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_moonmilk_SKBB;
enddef;



def a_sand_UIS (expr p) =
  T:=identity;
%  thclean p;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1u until xpart urcorner q:
      for j = ypart llcorner q step 1u until ypart urcorner q:
        draw origin shifted ((i,j) randomized 0.7u) withpen PenC;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_debris_UIS (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_debris_SKBB;
enddef;


def a_bedrock_SKBB (expr Path) =
  T:=identity;
  thclean Path;
enddef;


% used to export centerline LRUD envelope for maps created from surveys

def a_dimensions_SKBB (expr Path) =
  T:=identity;
  thclean Path;
enddef;


def a_debris_SKBB (expr p) =
  T:=identity;
%  thclean p;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1u until xpart urcorner q:
      for j = ypart llcorner q step 1u until ypart urcorner q:
        draw ((-.2u,0)--(.2u,0)) 
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.6u) withpen PenC;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_clay_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        qq := ((-.25u,0){up}..origin{down}..{up}(0.25u,0)) randomized (u/15)
             shifted ((i,j) randomized 1.3u);
	if xpart (p intersectiontimes qq) < 0:
	  thdraw qq;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_ice_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic, tmp_ice; 
  pair z;
  tmp_ice := image (
    draw (-.2u,0)--(.2u,0);
    draw (0,-.2u)--(0,.2u);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        z := ((i,j) randomized 1.3u);
	if xpart (p intersectiontimes ((bbox tmp_ice) shifted z)) < 0:
	  draw tmp_ice shifted z;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_snow_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  path q; q = bbox P;
  picture tmp_pic, tmp_sn; 
  pair z;
  tmp_sn := image(
    pickup PenC;
    p := origin--(0,.2*u);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240); draw p rotated (300);
    p := ((0,.3u)--(0,0.2u)--(0.1u,0.2u)) rotatedaround ((0,0.2u),45);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240);
    draw p rotated (300);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        z:=((i,j) randomized 1.3u);
	if xpart (P intersectiontimes ((bbox tmp_sn) shifted z)) < 0:
          draw tmp_sn shifted z;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to P;
  drawoptions();
  draw tmp_pic;
enddef;

def a_blocks_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic; 
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart llcorner q)/100);
  tmp_pic := image(
    for i = xpart llcorner q step 2uu until xpart urcorner q:
      for j = ypart llcorner q step 2uu until ypart urcorner q:
        qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle) 
	     randomized (uu/2))
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 1.6uu);
	if xpart (p intersectiontimes qq) < 0:
	  thclean qq;
	  thdraw qq;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_blocks_SKBB_ (expr p,o,s_beg,s_end,d_beg,d_end) =
  T:=identity;
  orient = 90-o;
  pickup PenC;
  path q[], qq; q1 = bbox p;
  draw q1; draw p;
  q2 = llcorner q1 .. lrcorner q1 .. urcorner q1 .. ulcorner q1 .. cycle;
  draw q2;
  pair zz[];
  radius := .5*length(llcorner q1 - urcorner q1);
  zz1 := .5[llcorner q1,urcorner q1];
  zz2 := zz1 - dir(orient)*radius;
  zz3 = zz1 rotatedaround (zz2,90);
  draw zz1 withpen pencircle scaled 2mm;
  draw zz2 withpen pencircle scaled 2mm;
  draw zz3 withpen pencircle scaled 2mm;
  picture tmp_pic; 
  tmp_pic := image(
    j := 0;
    forever:
      i := 0;
      forever:
        qq := punked (((-.5,-.5)--(.5,-.5)--(.5,.5)--(-.5,.5)--cycle) 
             scaled (0.7(5u-(j/(2*radius))[u*s_beg,u*s_end]))
	     randomized (u/2))
             rotated uniformdeviate(360) 
             shifted (((zz3 + (i,j)) rotatedaround (zz3,-o)) randomized 1.6u);
        draw ((zz3 + (i,j)) rotatedaround (zz3,-o)) withpen pencircle scaled 1mm withcolor red;
	if xpart (p intersectiontimes qq) < 0:
	  thclean qq;
	  thdraw qq;
	fi;
        i := i + (j/(2*radius))[u*d_beg,u*d_end];
        exitif i > 2*radius;
      endfor;  
      j := j + (j/(2*radius))[u*d_beg,u*d_end];
      exitif j > 2*radius;
    endfor;
  );
%  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_pebbles_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        qq := (superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75))
%             randomized (u/25)
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.8u);
	if xpart (p intersectiontimes qq) < 0:
	  thdraw qq;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_water_SKBB (expr Path) =
  T:=identity;
  thfill Path;
enddef;

let a_sump_SKBB = a_water_SKBB;

def a_u (expr p) =
    T:=identity;
    thfill p withcolor red;
enddef;




%%%%% ENDINPUT thArea %%%%%





%%%%% INPUT thText %%%%%


%% therion source code
%%
%% This file defines macros for labels
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thText.mp,v $
%% $Revision: 1.6 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

labeloffset:=0bp;

def l_label(expr txt,path) =
  picture pict,pic;
  pair pos;
  numeric dx[],dy[],ptime;
  string ss,ch;

  pic := thelabel(txt,(0,0));
  strl := xpart(lrcorner pic - llcorner pic);
  pathl := arclength (path);
  dx0 := xpart(llcorner pic);
%  dy0 := ypart(llcorner pic);

  if strl>pathl:
    txtzoom := pathl / strl;
    thwarning("text scaled down to fit the path");
  else:
    txtzoom := 1;
  fi;
  zoom := pathl / strl;

  for p within pic:
    if textual p:                                
      ss := textpart p;
      dx1 := xpart p;
      dy1 := ypart p;
      dx2 := dx1;

      if xxpart p / yypart p <> 1: message("Error: distorted text!") fi;
      txtscale := txtzoom * xxpart p;

      l := length(ss);
      ptime := 0;
      for i=0 upto (l - 1):
        ch := substring(i,i+1) of ss;
        pict := ch infont fontpart p scaled txtscale;
        charwidth := xpart (lrcorner pict - llcorner pict) / txtzoom;
        dy2 := ypart lrcorner pict / txtzoom;
        ptime := (dx2 - dx0 + 0.5*charwidth) * zoom;
        t := arctime ptime of (path);
        pos := point t of path + 
          (dy1+dy2)*txtzoom*unitvector((direction t of path) rotated 90);
        begingroup
%          interim labeloffset:=0bp;
          lab:=thelabel.top(pict,pos);
          process_label(pos,angle direction t of path);
        endgroup;
        dx2 := dx2 + charwidth;
      endfor;

    else: message("Strange component of line label!");
    fi;
  endfor;
  % draw path;
enddef;

vardef p_label@#(expr txt,pos,rot,mode) =
  if (mode=1) or (mode=7): interim labeloffset:=(u/8) fi;
  lab:=thelabel@#(txt, pos);
  if mode>1: pickup PenD fi;
  if mode=1:
    pickup pencircle scaled (u/6);
    drawdot(pos);
    process_label(pos,0);
  elseif mode=2: process_uplabel;       
  elseif mode=3: process_downlabel;
  elseif mode=4: process_updownlabel;
  elseif mode=5: process_circledlabel;
  elseif mode=6: process_boxedlabel;
  elseif mode=7: process_label(pos,rot);  % station name
  elseif mode=8: process_filledlabel(pos, rot);
  else: process_label(pos,rot); fi;
enddef;


% at beginfig: save smartll[], smartur[]; pair smartll[], smartur[]; smart_count=0;
numeric smart_count, smart_D;
boolean smart_quit, smart_inner_quit;

def p_smartlabel (expr txt, pos) =
  begingroup;
  interim bboxmargin:=0.2pt;
  lab:=thelabel.rt(txt,pos+(0.4u,0));
  q:=bbox lab;
  smart_D := 0;
  forever:
    smart_quit := true;
    smart_inner_quit := false;
    for i=1 upto smart_count:
      if smart_overlap(((point 0 of q) shifted (0,smart_D)), 
                       ((point 2 of q) shifted (0,smart_D)),
                       smartll[i], smartur[i]) = 1:
        smart_quit := false;
        smart_D := smart_D - 3pt;
        smart_inner_quit := true;
      fi;
      exitif smart_inner_quit;
    endfor;
    exitif smart_quit;
  endfor;
  smart_U := 0;
  forever:
    smart_quit := true;
    smart_inner_quit := false;
    for i=1 upto smart_count:
      if smart_overlap(((point 0 of q) shifted (0,smart_U)), 
                       ((point 2 of q) shifted (0,smart_U)),
                       smartll[i], smartur[i]) = 1:
        smart_quit := false;
        smart_U := smart_U + 3pt;
        smart_inner_quit := true;
      fi;
      exitif smart_inner_quit;
    endfor;
    exitif smart_quit;
  endfor;
  if (smart_U < -smart_D): smart_D := smart_U; fi;
  draw lab shifted (0,smart_D);
  if (abs(smart_D)>3pt):
    pickup PenB;
    draw pos{left}..{right}(pos shifted (.4u, smart_D)) dashed withdots scaled 0.2;
    pickup PenA;
    drawdot pos;
  fi;
  smart_count := smart_count + 1;
  smartll[smart_count] := point 0 of (q shifted (0,smart_D));
  smartur[smart_count] := point 2 of (q shifted (0,smart_D));
  endgroup;
enddef;

def smart_overlap (expr llA, urA, llB, urB) =
  if ((xpart llA < xpart urB) and (xpart urA > xpart llB)) and
     ((ypart llA < ypart urB) and (ypart urA > ypart llB)):
    1
  else:
    0 
  fi
enddef;




def p_wallaltitude (expr pprev,pos,pnext,txt) =
  rot:=angle(unitvector(pnext-pos)+unitvector(pos-pprev)) - 90;
  pickup PenD;
  pair zz;
%  zz:=(pos + 3*unitvector(dir rot));
  zz:=(pos + (u/4)*unitvector(dir rot));
  draw (pos)--zz;
  begingroup 
%    interim labeloffset:=2pt;
    interim labeloffset:=(u/12);
    if horiz_labels:
      rot:=rot mod 360;
      if rot<=22.5: lab:=thelabel.rt(txt, zz);
      elseif rot<=67.5: lab:=thelabel.urt(txt, zz);
      elseif rot<=112.5: lab:=thelabel.top(txt, zz);
      elseif rot<=157.5: lab:=thelabel.ulft(txt, zz);
      elseif rot<=202.5: lab:=thelabel.lft(txt, zz);
      elseif rot<=247.5: lab:=thelabel.llft(txt, zz);
      elseif rot<=292.5: lab:=thelabel.bot(txt, zz);
      elseif rot<=337.5: lab:=thelabel.lrt(txt, zz);
      else: lab:=thelabel.rt(txt, zz);
      fi;
    else:
      if (abs rot>90) and (abs rot <=270):
        rot:=rot-180;
        lab:=thelabel.lft(txt, pos);
      else:
        lab:=thelabel.rt(txt, pos);
      fi;
    fi;
    process_label(pos, if horiz_labels: 0 else: rot fi);
  endgroup;
enddef;




%%%%% ENDINPUT thText %%%%%





%%%%% INPUT thSpecial %%%%%


%% therion source code
%%
%% This file defines macros for special symbols
%%
%% $Date: $
%% $RCSfile: $
%% $Revision: $
%%
%% Copyright (C) 2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

def s_northarrow_SKBB_old (expr rot) = 
  T:=identity;
  picture tmp_pic;
  tmp_pic = image (
    begingroup
      interim defaultscale:=3;
      label(if (lang="sk") or (lang="cz"): "S" else: "N" fi, origin);
    endgroup;
    drawarrow (0,-1cm)--(0,1cm);
  );
  draw tmp_pic rotatedaround(origin, -rot);
enddef;

def s_northarrow_SKBB (expr rot) =
  T:=identity scaled 0.7 rotated -rot;
  thdraw (-.5cm,-1cm)--(0,1.5cm)--(.5cm,-1cm)--(0,-.5cm)--cycle;
  thfill (-.5cm,-1cm)--(0,1.5cm)--(0,-.5cm)--cycle;
enddef;

def s_scalebar_SKBB (expr l, units, txt) = 
  begingroup
    interim warningcheck:=0;
    tmpl:=l / Scale * cm * units / 2;
  endgroup;
  pickup PenC;
  draw (-tmpl,0)--(tmpl,0);
  draw (-tmpl,0)--(-tmpl,2bp);
  draw (tmpl,0)--(tmpl,2bp);
  begingroup
    interim labeloffset:=2bp;
    label.top(thTEX(decimal (l) & "\thinspace" & txt),origin);
  endgroup
enddef;

def s_scalebar_SM (expr l, units, txt) = 
  begingroup
    interim warningcheck:=0;
    tmpl:=l / Scale * cm * units / 2;
  endgroup;
  pickup PenC;
  draw (-tmpl,0)--(tmpl,0);
  draw (-tmpl,0)--(-tmpl,2bp);
  draw (tmpl,0)--(tmpl,2bp);
  draw (0,0)--(0,2bp);
  begingroup
    interim labeloffset:=3.5bp;
    label.top(thTEX(decimal (0)),(-tmpl,0));
    label.top(thTEX(decimal (l/2)),origin);
    label.top(thTEX(decimal (l) & "\thinspace" & txt),(tmpl,0));
  endgroup
enddef;


def s_hgrid_SM (expr xpos, ypos, xsize, ysize) =
  pickup PenD;
  draw (
    if xpos < 0: 0 else: -5mm fi, 0
  ) -- (
    if xpos > 0: 0 else: 5mm fi, 0
  );
  draw (
    0, if ypos < 0: 0 else: -5mm fi
  ) -- (
    0, if ypos > 0: 0 else: 5mm fi
  );
enddef;


def s_vgrid_SM (expr xpos, ypos, xsize, ysize) =
  pickup PenD;
  draw (
    if xpos < 0: 0 else: -xsize/2 fi, 0
  ) -- (
    if xpos > 0: 0 else: xsize/2 fi, 0
  ) dashed evenly;
enddef;




%%%%% ENDINPUT thSpecial %%%%%





%%%%% INPUT uAUT %%%%%


% Austrian Symbol Set, author Georg Pacher

% color (for Austrian symbol-set)

color col_water_bg;
col_water_bg :=(226/255,244/255,253/255);

%%%%%%%%%%%%%%%%%%%%%%%


%% areas

% returns true if pair point lies within path q. 
% outside_point is any pair outside of path q (needed for reference).
vardef pointinside(expr pt,q,outside_point)=
  T:=identity;
  path test;
  test:= outside_point--pt;
  %thdraw test;
  boolean isinside;
  isinside:=false;
  numintersections:=recgetnumintersections(test,q,0);
  if (numintersections <0):
    isinside:=true;
  elseif odd(numintersections):
     isinside:=true;
  else:
     isinside:=false;
  fi;
  isinside
enddef;

% get number of intersection between paths p (length 1!) and q
% recnum is needed for limitation of recursions. 
% If the number of allowed recursions is reached, a negativ number of intersections is returned
vardef recgetnumintersections(expr p,q,recnum)=
  
  pair inter;
  save preinter;
  save postinter;
  save numintersections;
  path preinter, postinter;
  inter:=p intersectiontimes q;
  %show recnum;
  if recnum >25:
    numintersections:=-100;
  else:  
    if xpart(inter)>0 :
     %show (xpart inter);
    % split p into two paths and call yourself again
    
    preinter:=subpath (0,xpart(inter)-2eps) of p;
    
    postinter:=subpath (xpart(inter)+2eps,1) of p;
    
    numintersections:= recgetnumintersections(preinter,q,recnum+1)
                     + recgetnumintersections(postinter,q,recnum+1)
                     + 1;
    else:
      numintersections:=0;
    fi;
  fi;
  numintersections
  
enddef;

beginpattern(pattern_water_AUT);
    draw origin--10up withpen pensquare scaled (0.02u);
    patternxstep(.18u);
    patterntransform(identity rotated 90);
endpattern;

beginpattern(pattern_sump_AUT);
    draw origin--(0,.25u) withpen pensquare scaled (0.02u);
    draw origin--(.25u,0) withpen pensquare scaled (0.02u);
endpattern;

beginpattern(pattern_sand_AUT);
    pickup PenC;
    p:= origin -- (0.01u,0.01u);
    for i=0.0u step 0.2u until 2.4u:
        for j=0.0u step 0.2u until 2.4u:
          draw p rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.09u);
        endfor;
    endfor;
    if BaseScale<=2.5:
      my_step:=2.4u;
    else:
      my_step:=2.6u;
    fi;
    patternstep(my_step,my_step);       
endpattern;

beginpattern(pattern_pebbles_AUT);
    pickup PenC;
    path qq;
    for i=0.0u step 0.3u until 5.1u:
        for j=0.0u step 0.3u until 5.1u:
          qq := (superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75))
             randomized (u/45)
             scaled (uniformdeviate(0.4)+.55)
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.15u);
           draw qq;
        endfor;
    endfor;
    patternstep(5.1u,5.1u);
endpattern;

beginpattern(pattern_ice_AUT);
    pickup PenC;
    p:=(-.15u,.0u) -- (0.15u,.0u);
    draw p;
    draw p shifted (0.25u,.0u) rotated (90);
    draw p shifted (0.45u,0.25u);
    draw p shifted (0.0u,0.45u) rotated (90);
    patternxstep(.9u);
    patternystep(0.5u);
endpattern;

def a_water_AUT (expr Path) =
  T:=identity;
  thclean Path;
  pickup PenC;
  thfill Path withcolor col_water_bg;
  thfill Path withpattern pattern_water_AUT;
  thdraw Path;
enddef;

def a_sump_AUT (expr Path) =
  T:=identity;
  thclean Path;
  pickup PenC;
  thfill Path withcolor col_water_bg;
  thfill Path withpattern pattern_sump_AUT;
  thdraw Path;
enddef;

def a_sand_AUT (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_sand_AUT ;
enddef;

let a_clay_AUT = a_sand_AUT;


def a_pebbles_AUT (expr p) =
  T:=identity;
  thfill p withpattern pattern_pebbles_AUT;
enddef;



def a_debris_AUT (expr p) =
  T:=identity;
  
  symbol_distance:=1.0;
  scale_factor:= 0.3;
  pickup PenC;
  path q, qq; q = bbox p;
  pair outside;
  outside:= ulcorner q + up;
  picture tmp_pic; 
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
  tmp_pic := image(
     for i = xpart llcorner q step symbol_distance*uu until xpart urcorner q:
        for j = ypart llcorner q step symbol_distance*uu until ypart urcorner q:
           qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(1.05uu,0.01uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle) 
           randomized (uu/2))
           scaled (uniformdeviate(0.4)+scale_factor )
           rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.5uu);
           if xpart (p intersectiontimes qq) < 0:
             if pointinside((i,j),p,outside):
               thclean qq;
               thdraw qq;
             fi;
           else:
             qq:= qq scaled (uniformdeviate(.2)+.5 )
             if xpart (p intersectiontimes qq) < 0:
               if pointinside((i,j),p,outside):
                 thclean qq;
                 thdraw qq;
               fi;
             fi;
           fi;
        endfor;  
     endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;  

def a_ice_AUT (expr p) =
  T:=identity;
  thclean p;
  thfill p withpattern pattern_ice_AUT;
  pickup PenC;
  thdraw p;
enddef;

def a_snow_AUT (expr P) =
  T:=identity;
  pickup PenC;
  path q; q = bbox P;
  picture tmp_pic, tmp_sn; 
  pair z;
  tmp_sn := image(
    pickup PenC;
    p := origin--(0,.2*u);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240); draw p rotated (300);
    p := ((0,.3u)--(0,0.2u)--(0.1u,0.2u)) rotatedaround ((0,0.2u),45);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240);
    draw p rotated (300);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.0u until xpart urcorner q:
      for j = ypart llcorner q step 1.0u until ypart urcorner q:
        z:=((i,j) randomized 0.5u);
	if xpart (P intersectiontimes ((bbox tmp_sn) shifted z)) < 0:
          draw tmp_sn shifted z;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to P;
  draw tmp_pic;
  thdraw P;
enddef;

def a_blocks_AUT (expr p) =
   T:=identity;
  symbol_distance:=1.6;
  scale_factor:= 0.8;
  pickup PenC;
  path q, qq; q = bbox p;
  pair outside;
  outside:= ulcorner q + up;
  picture tmp_pic; 
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
  tmp_pic := image(
     for i = xpart llcorner q step symbol_distance*uu until xpart urcorner q:
        for j = ypart llcorner q step symbol_distance*uu until ypart urcorner q:
           qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(1.05uu,0.01uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle) 
           randomized (uu/2))
           scaled (uniformdeviate(0.7)+scale_factor )
           rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.75uu);
           if xpart (p intersectiontimes qq) < 0:
             if pointinside((i,j),p,outside):
               thclean qq;
               thdraw qq;
             fi;
           else:
             qq:= qq scaled (uniformdeviate(.2)+.5 )
             if xpart (p intersectiontimes qq) < 0:
               if pointinside((i,j),p,outside):
                 thclean qq;
                 thdraw qq;
               fi;
             fi;
           fi;
        endfor;  
     endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;  


%% lines

def l_wall_pit_AUT (expr P) = 
    T:=identity;
    % draw outer path
    pickup PenA;
    thdraw P;

    laenge:= arclength P;

    pair inner[],innerdir[], inter;
    pair test;
    
    samplingdistance:=max(0.15u,laenge/1500);
 
    path testcircle;
    % testcircle, used to test, whether the path makes a 'v'-like bend, 
    % where normal sampling and offsetting gives poor results for the parallel line
    % size of testcircle= size PenA/2 + 2* (distance between outer and inner line)
    % + PenC (inner line)
    testcircle := halfcircle scaled (.5*u/10+2*.125u+.5*u/10) shifted (0,.5*u/10);
    cur:=samplingdistance/2;
    count:=0;
    forever:
      t:= arctime cur of P;
      inter:=P intersectiontimes (testcircle rotated (angle thdir(P,t)) shifted (point t of P));
      
      %thdraw testcircle rotated (angle thdir(P,t)) shifted (point t of P) withpen (pencircle scaled 0.01u) ;
      if (xpart inter) >=0:
        % we are at a 'sharp bend', so set next point to intersectionpoint
        cur:=cur+samplingdistance;
        t := max( xpart inter, arctime cur of P);
        %thdraw point t of P withcolor 0.7*green;
        forever:
          t:= arctime cur of P;
          inter:=P intersectiontimes (testcircle rotated (angle thdir(P,t)) shifted (point t of P));
          exitif (xpart inter <0);
          cur := cur + samplingdistance;
          exitif (cur >=laenge); 
        endfor;
        if (cur <laenge):
          inner[count]:=(point t of P + .125u*unitvector(thdir(P,t) rotated 90) );
          innerdir[count]:=unitvector(thdir(P,t));
          count := count+1;
        fi;
      else:
        inner[count]:= (point t of P + .125u*unitvector(thdir(P,t) rotated 90) );
        innerdir[count]:=unitvector(thdir(P,t));
        %thdraw inner[count] withpen PenD withcolor 0.5*red;
        count:=count +1;
        cur:= cur+ samplingdistance;
      fi;
      exitif (cur >=laenge);
    endfor;
    if count>2:
      % draw inner path
      pickup PenC;
      path innerpath;
      innerpath =
      for i=0 upto count-2:
        inner[i]{(innerdir[i])} ..
      endfor
      if cycle P: cycle;
      else:  inner[count-1];
      fi;
      thdraw innerpath;
        
    % draw the triangles

    path draw_triangle;
    pair l_triangle;
       
    laenge:= arclength innerpath;
    symsize:= adjust_step(laenge,0.5u);
    triangle_width:=symsize/2;
    cur:=(symsize/2);
    t := arctime (cur) of innerpath;
    t1:= arctime (cur-triangle_width/2) of innerpath;
    t2:= arctime (cur+triangle_width/2) of innerpath;         
    l_triangle := (point t of innerpath);
    if ATTR__height >= 10: thfill else: thdraw fi (subpath (t1,t2) of innerpath) -- 
           ((point t of innerpath) + symsize/2 * unitvector(thdir(innerpath,t) rotated 90))
           --  cycle;

    for cur=(symsize/2) step symsize until laenge:
      t := arctime (cur) of innerpath;
      test := (point t of innerpath);
      my_dist := length(test-l_triangle);
      if (abs(my_dist-symsize) < 0.05u) or (my_dist>symsize):
         t1:= arctime (cur-triangle_width/2) of innerpath;
         t2:= arctime (cur+triangle_width/2) of innerpath;         
	 draw_triangle:=(subpath (t1,t2) of innerpath) -- 
                        ((point t of innerpath) + symsize/2 * unitvector(thdir(innerpath,t) rotated 90))
                         --  cycle;
	 if xpart (draw_triangle intersectiontimes P) < 0:
	    if ATTR__height >= 10: 
	      thfill draw_triangle;
	    else:
	      thclean draw_triangle;
	      thdraw draw_triangle;
	    fi;
	    l_triangle:= test;
	 fi;
      fi;
    endfor;
    
    fi;
enddef;


def l_wall_sand_AUT (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.1u);
  pickup PenC;  
  forever:
    t := arctime cas of P;
    thdraw (((0.01u,0.01u)--origin) rotated uniformdeviate(360) shifted ((point t of P) + (uniformdeviate 1) * .4u 
            * unitvector(thdir(P,t) rotated -90)));
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenC;  
  thdraw P;

enddef;

def l_wall_pebbles_AUT (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .18u);
  pickup PenC;
  q:=superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/45) rotated (angle(thdir(P,t)) + (normaldeviate*40)) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;


let l_wall_clay_AUT = l_wall_sand_AUT;


def l_wall_debris_AUT (expr P) = 
  T:=identity;
  pickup PenC;
  laenge := arclength P;
  path block;
  path old_block;
  
  cur := 0;
  t:= arctime cur of P;
  % draw first block
  old_block := (((-.0u,-.0u)--(.25u,-.15u)--(.45u,0.01u)--(.2u,.25u)--(.05u,.15u)--cycle));
  block_width := (xpart urcorner old_block - xpart ulcorner old_block);
  old_block:=old_block rotated angle(thdir(P,0)) shifted point t of P;
  thclean old_block;
  thdraw old_block;
   
  cur := cur + 0.9*block_width;
  t:= arctime cur of P;
	% proceed with path
    forever:
	  % generate random block
        block := punked (((-.25u,-.25u)--(0.25.u,-.25u)--(0.50u,0.01u)--(0.25u,.25u)--(-.25u,.25u)--cycle) 
          randomized (u/4))
          scaled (uniformdeviate(0.3)+.4)
          rotated uniformdeviate(360);
	  % check width of block
        block_width := (xpart urcorner block - xpart ulcorner block);
        exitif cur > (laenge- 2.5*block_width/2);
        % find next position where the block fits in without intersecting the previous one
	  forever:           
	    exitif xpart ( (block rotated angle(-direction t of P) shifted point t of P) intersectiontimes old_block) < 0;
            cur:=cur+0.01u;
            t:= arctime cur of P;
            exitif cur > (laenge- 2.5*block_width/2);
          endfor;
        exitif cur > (laenge- 2.5*block_width/2);

        old_block:= block rotated angle(-direction t of P) shifted point t of P;
        thclean old_block;
        thdraw old_block;
        cur := cur + block_width/2;
        t:= arctime cur of P;
    endfor;
	t:= arctime laenge-eps of P;

	% generate last block
      block := (((-.0u,-.0u)--(.25u,-.15u)--(.45u,0.01u)--(.2u,.25u)--(.1u,.15u)--cycle));
     block_width := (xpart urcorner block - xpart ulcorner block);
     
	% scale last block to fit in the remaining gap
     scale_factor:=1.5*(laenge-cur)/block_width;
     forever:
           exitif scale_factor < 0;  % bruces stab at preventing endless loop at large scales
           exitif xpart ( (block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P)) intersectiontimes old_block) < 0;
           scale_factor:=scale_factor-0.01;
     endfor;
     if scale_factor > 0:
       thclean block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P);
       thdraw block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P);
     fi;
enddef;


def l_wall_blocks_AUT (expr P) = 

  T:=identity;
  pickup PenC;
  laenge := arclength P;

  path block;
  path old_block;
  
  cur := 0;
  t:= arctime cur of P;
  
  % draw first block
  old_block := ( (.7u,-.35u)--(.85u,0.01u)--(.4u,.5u)--(.1u,.3u)--(-.0u,-.0u) );
  block_width := (xpart urcorner old_block - xpart ulcorner old_block);
  old_block:=old_block rotated angle( thdir(P,0) ) shifted point t of P;
  thclean (old_block--cycle);
  thdraw old_block;
  
  
  cur := cur + block_width/2;
  t:= arctime cur of P;
  forever:
    % generate random block
    block := punked ( ( (.8u,-.35u)--(.85u,0.01u)--(.6u,.4u)--(.1u,.1u)--(-.0u,-.3u) )
          randomized (0.3u) )
           scaled (uniformdeviate(0.3)+.65)
          rotated (uniformdeviate(45)-15);
    % check width of block
    block_width := (xpart urcorner block - xpart ulcorner block);
    
    exitif cur > (laenge- 3.5*block_width/2);
    % find next position where the block fits in without intersecting the previous one
    forever:    
      exitif xpart ( ((block--cycle) rotated angle(direction t of P) shifted point t of P) intersectiontimes old_block) < 0;
      cur:=cur+0.01u;
      t:= arctime cur of P;
      exitif cur > (laenge- 3.5*block_width/2);
    endfor;
    exitif cur > (laenge- 3.5*block_width/2);
    
    old_block:= block rotated angle(direction t of P) shifted point t of P;
    thclean (old_block--cycle);
    thdraw old_block;
    
    
    cur := cur + block_width/2;
    t:= arctime cur of P;
  endfor;
  
    % generate last block
    t:= arctime laenge-eps of P;
    block := (( (-.15u,-.35u)--(.0u,.0u)--(-.45u,.5u)--(-.75u,.3u)--(-.85u,-.0u)) );
    block_width := (xpart urcorner block - xpart ulcorner block);
    % scale last block to fit in the remaining gap
    scale_factor:=(laenge-cur)/block_width;
    forever:
	  exitif scale_factor < 0;
      exitif xpart ( ( (block) rotated angle (direction t of P) scaled scale_factor shifted (point t of P) ) intersectiontimes old_block) < 0;
      scale_factor:=scale_factor-0.001;
    endfor;
    if scale_factor > 0:
      thclean (block--cycle) rotated angle (direction t of P) scaled scale_factor shifted (point t of P);
      thdraw (block) rotated angle (direction t of P) scaled scale_factor shifted (point t of P);
    fi;
enddef;



def l_wall_ice_AUT (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .6u);
  pickup PenC;
  p := (-.15u,0)--(.15u,0);
  q := p rotated 90 shifted (.25u,.0u);
  picture symbol,test_symbol;
  symbol:= image (
             thdraw p;
             thdraw q;
             );
  path bound,old_bound,test_bound;
  begingroup;
    interim bboxmargin:=0;
    bound := bbox (symbol);
  endgroup;
  t := arctime (cas + mojkrok/2) of P;
  thdraw symbol rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
  old_bound:=bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));

  forever:
    t := arctime (cas + mojkrok/2) of P;
    test_bound:= bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    if xpart ((old_bound) intersectiontimes (test_bound))<0:
      if xpart (P intersectiontimes (test_bound))<0:
        thdraw symbol rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
        old_bound:=bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
      fi;
    fi;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  thdraw P;
enddef;


def l_wall_underlying_AUT (expr P) = 
  T:=identity;
  pickup PenA;
  laenge:= arclength P;
  t1 := arctime (0.5u) of P;
  t2 := arctime (laenge-.5u) of P;
  thdraw (subpath (t1,t2) of P) dashed evenly scaled optical_zoom;
enddef;


def l_wall_overlying_AUT (expr P) = 
  T:=identity;
  laenge:= arclength P;
  t1 := arctime (0.25u) of P;
  t2 := arctime (laenge-.25u) of P;
  t3 :=arctime (laenge) of P;
  pickup pensquare scaled (3.5*u/10);
  thdraw (subpath (t1,t2) of P) withcolor background;
    pickup PenA;
  thdraw subpath(0,t1) of P; 
  thdraw subpath(t2,t3) of P;
  thdraw (subpath (t1,t2) of P) dashed dashpattern(on 2bp off 2bp on .5bp off 2bp on 2bp) scaled optical_zoom;
enddef;

def l_wall_moonmilk_AUT (expr P) = 
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.8u);
  circle_width:=symsize/2;
  cur:=(symsize-circle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t2 := arctime (cur + circle_width) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P);
    cur := cur + symsize;
    exitif cur > laenge + (symsize / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_flowstone_AUT (expr P) = 
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.8u);
  circle_width:=symsize/2;
  cur:=(symsize-circle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t2 := arctime (cur + circle_width) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P);
    thfill (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P) --
           (point t1 of P)--cycle;
    cur := cur + symsize;
    exitif cur > laenge + (symsize / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_pit_AUT (expr P) =
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.5u);
  triangle_width:=symsize/2;
  cur:=(symsize-triangle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t  := arctime (cur + triangle_width/2) of P;
    t2 := arctime (cur + triangle_width) of P;
    if ATTR__height >= 10:
      thfill (subpath (t1,t2) of P) -- 
        ((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) -- 
        cycle;
    else:
      thclean (subpath (t1,t2) of P) -- 
        ((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) -- 
        cycle;
      thdraw (point t2 of P) --((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) -- 
        (point t1 of P);
    fi;
    cur := cur + symsize;
    exitif cur > laenge - (1*symsize/3); % for rounding errors
    t1:=arctime (cur) of P;
  endfor;
  thdraw P;
enddef;


let l_overhang_AUT = l_pit_AUT;

let l_floorstep_AUT = l_floorstep_UIS;

let l_contour_AUT =l_contour_SKBB;

def l_flowstone_AUT (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_survey_cave_AUT (expr P) =
  T:=identity;
  pair zz[];
  pickup PenD;
  thdraw P;
enddef;

%% points

def p_stalactite_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u, .4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
      thdraw (0,.15u) -- (.15u,.4u);
    else:
      U:=(.175u, .175u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thclean fullcircle scaled 0.35u;
      thdraw fullcircle scaled 0.35u;
    fi;
enddef;

let p_icestalactite_AUT = p_stalactite_AUT;

def p_stalagmite_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u,.4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
      thdraw (0,-.15u) -- (.15u,-.4u);
    else:
      U:=(.15u,.15u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thfill fullcircle scaled 0.3u;
    fi;
enddef;

let p_icestalagmite_AUT = p_stalagmite_AUT;

def p_pillar_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u,.4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,.15u)--(0,-.15u);
      thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
      thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    else:
      U:=(.225u,.225u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thclean fullcircle scaled 0.45u;
      thdraw fullcircle scaled 0.45u;
      thfill fullcircle scaled 0.3u;
    fi;
enddef;

let p_icepillar_AUT = p_pillar_AUT;

def p_crystal_AUT (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
   
    pickup PenC;
    p := ((-.35*u,0)--(.35*u,0));
    thdraw p;
    thdraw p rotated (45);
    thdraw p rotated (90);
    thdraw p rotated (135);
    
    thdrawoptions();

enddef;

def p_spring_AUT (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,.1u)..(0,-.1u)..(.3u,.1u);
enddef;


def p_sink_AUT (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,-.1u)..(0,.1u)..(.3u,-.1u);
enddef;

def p_breakdownchoke_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity rotated -theta aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thclean (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.21u,.305u)--(.0u,-.305u)--(.21u,.305u);
enddef;

def p_sand_AUT (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:= origin -- (0.01u,0.01u);
    for i=-0.1u step 0.2u until .15u:
        for j=-0.1u step 0.2u until .15u:
          thdraw p rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.09u);
        endfor;
    endfor;
    thdrawoptions();
enddef;

let p_clay_AUT  = p_sand_AUT;

def p_pebbles_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    path qq;
    for i=-0.15u step 0.3u until .2u:
        for j=-0.15u step 0.3u until .2u:
          qq := (superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75))
             randomized (u/45)
             scaled (uniformdeviate(0.4)+.55)
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.15u);
           thdraw qq;
        endfor;
    endfor;
enddef;

def p_debris_AUT (expr pos,theta,sc,al)=
    U:=(.5u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    path block,q;
    block :=  ((-.15u,-.15u)--(.15u,-.15u)--(.3u,0.01u)--(.15u,.15u)--(-.15u,.15u)--cycle) ;
    
    q:= (punked (block randomized (0.15u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.3)+0.3) shifted (0.0u,0.15u);
    thclean q; thdraw q;
    
    q:= (punked (block randomized (0.15u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.5)+0.7) shifted (-0.15u,-0.15u);
    thclean q; thdraw q;

    q:=  (punked (block randomized (0.15u))) rotated uniformdeviate(360) shifted (0.15u,-0.15u);
    thclean q; thdraw q;
    
enddef;

def p_blocks_AUT (expr pos,theta,sc,al)=
    U:=(u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;

    path block,q;
    block :=  ((-.25u,-.25u)--(.25u,-.25u)--(.5u,0.01u)--(.25u,.25u)--(-.25u,.25u)--cycle) ;
    
    q:= (punked (block randomized (0.3u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.3)+0.3) shifted (0.0u,0.25u);
    thclean q; thdraw q;
    
    q:= (punked (block randomized (0.3u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.5)+0.7) shifted (-0.25u,-0.25u);
    thclean q; thdraw q;

    q:=  (punked (block randomized (0.3u))) rotated uniformdeviate(360) shifted (0.25u,-0.25u);
    thclean q; thdraw q;
    
enddef;

def p_water_AUT (expr pos,theta,sc,al)=
    U:=(.425u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenD;
    p:=fullcircle xscaled (.85u) yscaled (.6u);
    thfill p withcolor col_water_bg;
    thfill p withpattern pattern_water_AUT;
    thdraw p;
enddef;

def p_ice_AUT (expr pos,theta,sc,al)=
    U:=(.6u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.15u,.0u) -- (0.15u,.0u);
    thdraw p rotated 90;
    thdraw p shifted (0.45u,.0u);
    thdraw p shifted (-0.45u,.0u);
    
    thdraw p rotated 90 shifted (-0.45u,0.25u);
    thdraw p shifted (0u,0.25u);
    thdraw p rotated 90 shifted (0.45u,.25u);
enddef;

def p_entrance_AUT (expr pos,theta,sc,al)=
    U:=(.3u,.75u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    path slice;
    for i= -0.5 step 0.01 until 0.5:
      slice:= (-.3u*(0.5-i),1.5*i*u)--(0,.75u)--(.3u*(0.5-i),1.5i*u)--cycle;
      thfill slice withcolor (min(0.95,0.5-1.75i),min(0.95,.5-1.75i),min(0.95,.5-1.75i));
    endfor;
    thdraw ((-.3u,-0.75u)--(0,.75u)--(.3u,-0.75u)--cycle);
enddef;
    
def p_gradient_AUT (expr pos,theta,sc,al)=
    U:=(.15u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-0.5u)--(0,0.5u);
    p:=(-.15u,.3u)--(0,0.7u)--(.15u,.3u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_airdraught_AUT (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,.5u)--(0,-0.8u);
	p:=(-.2u,.2u)--(0,.55u)--(.2u,.2u)--cycle;
	thfill p;
	for i:=1 upto round(3+2*mlog(sc)/mlog 2):
	  thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
	  thdraw (0,-(1-0.2i)*u)--(-.2u,-(1-0.2(i-1))*u);
	endfor;
enddef;

def p_station_temporary_AUT (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    thclean fullcircle scaled 0.15u;
    thdraw fullcircle scaled 0.15u;
enddef;

let p_station_painted_AUT = p_station_temporary_AUT ;
let p_station_fixed_AUT = p_station_temporary_AUT ;

def p_claychoke_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity rotated -theta aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thclean (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.15u,.3u)--(-.15u,-.25u)--(.15u,-.25u);
enddef;

def p_claytree_AUT (expr pos,theta,sc,al)=
    U:=(.55u,.6u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:= (-.15u,.15u)--(.0u,.6u)--(.15u,.15u);
    thdraw p ;
    thdraw p shifted (-.4u,-.3u);
    thdraw p shifted (.4u,-.2u) ;
enddef;




%%%%% ENDINPUT uAUT %%%%%






%%%%% INPUT thTrans %%%%%


% default translations

let p_station_fixed = p_station_fixed_ASF;
let p_station_painted = p_station_painted_SKBB;
let p_station_natural = p_station_natural_ASF;              
let p_station_temporary = p_station_temporary_ASF;

let p_waterflow_paleo = p_waterflow_paleo_UIS;
let p_waterflow_permanent = p_waterflow_permanent_UIS;
let p_waterflow_intermittent = p_waterflow_intermittent_UIS;

let p_stalactite = p_stalactite_UIS;
let p_stalagmite = p_stalagmite_UIS;
let p_pillar = p_pillar_UIS;
let p_icestalactite = p_icestalactite_AUT;
let p_icestalagmite = p_icestalagmite_AUT;
let p_icepillar = p_icepillar_AUT;
let p_curtain = p_curtain_UIS;
let p_helictite = p_helictite_UIS;
let p_sodastraw = p_sodastraw_UIS;
let p_crystal = p_crystal_UIS;
let p_flowstone = p_flowstone_UIS;
let p_moonmilk = p_moonmilk_UIS;
let p_wallcalcite = p_wallcalcite_UIS;
let p_popcorn = p_popcorn_UIS;
let p_disk = p_disk_UIS;
let p_gypsum = p_gypsum_NSS;
let p_aragonite = p_aragonite_NSS;
let p_cavepearl = p_cavepearl_SKBB;
let p_gypsumflower = p_gypsumflower_NSS;
let p_rimstonepool = p_rimstonepool_ASF;
let p_rimstonedam = p_rimstonedam_ASF;
let p_anastomosis = p_anastomosis_UIS;
let p_karren = p_karren_UIS;
let p_scallop = p_scallop_UIS;
let p_flute = p_flute_UIS;
let p_raft = p_raft_NSS;
let p_raftcone = p_raftcone_NSS;
let p_spring = p_spring_SKBB;
let p_sink = p_sink_SKBB;
let p_narrowend = p_narrowend_UIS;
let p_lowend = p_lowend_UIS;
let p_flowstonechoke = p_flowstonechoke_NSS;
let p_breakdownchoke = p_breakdownchoke_NSS;
let p_claychoke = p_claychoke_AUT;
let p_claytree = p_claytree_AUT;
let p_bedrock = p_bedrock_ASF;
let p_clay = p_clay_SKBB;                        
let p_sand = p_sand_UIS;
let p_pebbles = p_pebbles_UIS;
let p_debris = p_debris_UIS;
let p_blocks = p_blocks_UIS;
let p_water = p_water_UIS;
let p_ice = p_ice_UIS;
let p_snow = p_snow_SKBB;
let p_archeomaterial = p_archeomaterial_UIS;
let p_paleomaterial = p_paleomaterial_UIS;
let p_guano = p_guano_UIS;
let p_vegetabledebris = p_vegetabledebris_ASF;
let p_root = p_root_ASF;
let p_entrance = p_entrance_UIS;
let p_gradient = p_gradient_UIS;
let p_rope = p_rope_SKBB;          
let p_fixedladder = p_fixedladder_SKBB;   
let p_ropeladder = p_ropeladder_SKBB;    
let p_steps = p_steps_SKBB;         
let p_bridge = p_bridge_SKBB;        
let p_traverse = p_traverse_SKBB;
let p_anchor = p_anchor_SKBB;
let p_camp = p_camp_SKBB;
let p_dig = p_dig_UIS;
let p_noequipment = p_noequipment_SKBB;
let p_sectionarrow = p_sectionarrow_SKBB;
let p_continuation = p_continuation_UIS;
let p_airdraught = p_airdraught_UIS;
let p_airdraught_winter = p_airdraught_winter_UIS;
let p_airdraught_summer = p_airdraught_summer_UIS;
let p_station = p_station_SKBB;
let p_handrail = p_handrail_SKBB;
let p_viaferrata = p_viaferrata_SKBB;
let p_stalactites = p_stalactites_UIS;
let p_stalagmites = p_stalagmites_UIS;
let p_pillars = p_pillars_UIS;

let l_wall_bedrock = l_wall_bedrock_UIS;
let l_wall_sand = l_wall_sand_SKBB;
let l_wall_clay = l_wall_clay_SKBB;
let l_wall_pebbles = l_wall_pebbles_SKBB;
let l_wall_debris = l_wall_debris_SKBB;
let l_wall_blocks = l_wall_blocks_SKBB;
let l_wall_ice = l_wall_ice_SKBB;
let l_wall_underlying = l_wall_underlying_UIS;
let l_wall_unsurveyed = l_wall_unsurveyed_SKBB;
let l_wall_presumed = l_wall_presumed_UIS;
%let l_wall_invisible = l_wall_invisible;
let l_wall_pit = l_wall_pit_AUT;
let l_wall_overlying = l_wall_overlying_AUT;
let l_wall_flowstone = l_wall_flowstone_AUT;
let l_wall_moonmilk = l_wall_moonmilk_AUT;

let l_waterflow_permanent = l_waterflow_permanent_UIS;
let l_waterflow_intermittent = l_waterflow_intermittent_SKBB;
let l_waterflow_conjectural = l_waterflow_conjectural_SKBB;

let l_border_visible = l_border_visible_SKBB;
let l_border_temporary = l_border_temporary_SKBB;
let l_border_presumed = l_border_presumed_SKBB;
%let l_border_invisible = l_border_invisible;

let l_floorstep = l_floorstep_UIS;
let l_pit = l_pit_UIS;
let l_ceilingstep = l_ceilingstep_SKBB;
let l_chimney = l_chimney_UIS;
let l_overhang = l_overhang_SKBB;
let l_slope = l_slope_SKBB;
let l_ceilingmeander = l_ceilingmeander_SKBB;
let l_floormeander = l_floormeander_SKBB;
let l_contour = l_contour_SKBB;
let l_rockborder = l_rockborder_UIS;
let l_rockedge = l_rockedge_UIS;
let l_flowstone = l_flowstone_UIS;
let l_moonmilk = l_moonmilk_UIS;
let l_section = l_section_SKBB;
let l_survey_cave = l_survey_cave_SKBB;
let l_survey_surface = l_survey_surface_SKBB;
let l_arrow = l_arrow_SKBB;
let l_gradient = l_gradient_UIS;
let l_mapconnection = l_mapconnection_SKBB;
let l_handrail = l_handrail_SKBB;
let l_steps = l_steps_SKBB;
let l_fixedladder = l_fixedladder_SKBB;
let l_ropeladder = l_ropeladder_SKBB;
let l_rope = l_rope_SKBB;
let l_viaferrata = l_viaferrata_SKBB;

let a_water = a_water_UIS;
let a_sump = a_sump_UIS;
let a_sand = a_sand_UIS;
let a_debris = a_debris_SKBB;
let a_blocks = a_blocks_SKBB;
let a_snow = a_snow_SKBB;
let a_ice = a_ice_SKBB;
let a_pebbles = a_pebbles_SKBB;
let a_clay = a_clay_SKBB;
let a_bedrock = a_bedrock_SKBB;
let a_flowstone = a_flowstone_ASF;
let a_moonmilk = a_moonmilk_SKBB;
let a_dimensions = a_dimensions_SKBB;

let s_northarrow = s_northarrow_SKBB;
let s_scalebar = s_scalebar_SKBB;
let s_hgrid = s_hgrid_SM;
let s_vgrid = s_vgrid_SM;



%%%%% ENDINPUT thTrans %%%%%



nonstopmode;
initsymbol("s_hgrid_SM");
initsymbol("s_northarrow_SKBB");
initsymbol("s_scalebar_SKBB");
initsymbol("s_scalebar_SM");
initsymbol("s_vgrid_SM");
initsymbol("p_airdraught_AUT");
initsymbol("p_airdraught_UIS");
initsymbol("p_airdraught_summer_UIS");
initsymbol("p_airdraught_winter_UIS");
initsymbol("p_anastomosis_UIS");
initsymbol("p_anchor_SKBB");
initsymbol("p_aragonite_NSS");
initsymbol("p_archeomaterial_UIS");
initsymbol("p_bedrock_ASF");
initsymbol("p_blocks_AUT");
initsymbol("p_blocks_UIS");
initsymbol("p_breakdownchoke_AUT");
initsymbol("p_breakdownchoke_NSS");
initsymbol("p_bridge_SKBB");
initsymbol("p_camp_SKBB");
initsymbol("p_cavepearl_SKBB");
initsymbol("p_clay_AUT");
initsymbol("p_clay_SKBB");
initsymbol("p_claychoke_AUT");
initsymbol("p_claytree_AUT");
initsymbol("p_continuation_UIS");
initsymbol("p_crystal_AUT");
initsymbol("p_crystal_UIS");
initsymbol("p_curtain_UIS");
initsymbol("p_debris_AUT");
initsymbol("p_debris_UIS");
initsymbol("p_dig_UIS");
initsymbol("p_disk_UIS");
initsymbol("p_entrance_AUT");
initsymbol("p_entrance_UIS");
initsymbol("p_fixedladder_SKBB");
initsymbol("p_flowstone_UIS");
initsymbol("p_flowstonechoke_NSS");
initsymbol("p_flute_UIS");
initsymbol("p_gradient_AUT");
initsymbol("p_gradient_BCRA");
initsymbol("p_gradient_NSS");
initsymbol("p_gradient_SKBB");
initsymbol("p_gradient_UIS");
initsymbol("p_guano_UIS");
initsymbol("p_gypsum_NSS");
initsymbol("p_gypsumflower_NSS");
initsymbol("p_handrail_SKBB");
initsymbol("p_helictite_UIS");
initsymbol("p_ice_AUT");
initsymbol("p_ice_UIS");
initsymbol("p_icepillar_AUT");
initsymbol("p_icestalactite_AUT");
initsymbol("p_icestalagmite_AUT");
initsymbol("p_karren_UIS");
initsymbol("p_lowend_NSS");
initsymbol("p_lowend_UIS");
initsymbol("p_moonmilk_UIS");
initsymbol("p_narrowend_UIS");
initsymbol("p_noequipment_SKBB");
initsymbol("p_paleomaterial_UIS");
initsymbol("p_pebbles_AUT");
initsymbol("p_pebbles_UIS");
initsymbol("p_pillar_AUT");
initsymbol("p_pillar_UIS");
initsymbol("p_pillars_UIS");
initsymbol("p_popcorn_UIS");
initsymbol("p_raft_NSS");
initsymbol("p_raftcone_NSS");
initsymbol("p_rimstonedam_ASF");
initsymbol("p_rimstonepool_ASF");
initsymbol("p_root_ASF");
initsymbol("p_rope_SKBB");
initsymbol("p_ropeladder_SKBB");
initsymbol("p_sand_AUT");
initsymbol("p_sand_UIS");
initsymbol("p_scallop_UIS");
initsymbol("p_sink_AUT");
initsymbol("p_sink_SKBB");
initsymbol("p_snow_SKBB");
initsymbol("p_sodastraw_UIS");
initsymbol("p_spring_AUT");
initsymbol("p_spring_SKBB");
initsymbol("p_stalactite_AUT");
initsymbol("p_stalactite_UIS");
initsymbol("p_stalactites_UIS");
initsymbol("p_stalagmite_AUT");
initsymbol("p_stalagmite_UIS");
initsymbol("p_stalagmites_UIS");
initsymbol("p_station_SKBB");
initsymbol("p_station_fixed_ASF");
initsymbol("p_station_fixed_AUT");
initsymbol("p_station_natural_ASF");
initsymbol("p_station_painted_AUT");
initsymbol("p_station_painted_SKBB");
initsymbol("p_station_temporary_ASF");
initsymbol("p_station_temporary_AUT");
initsymbol("p_station_temporary_SKBB");
initsymbol("p_steps_SKBB");
initsymbol("p_traverse_SKBB");
initsymbol("p_vegetabledebris_ASF");
initsymbol("p_viaferrata_SKBB");
initsymbol("p_wallcalcite_UIS");
initsymbol("p_water_AUT");
initsymbol("p_water_UIS");
initsymbol("p_waterflow_intermittent_UIS");
initsymbol("p_waterflow_paleo_UIS");
initsymbol("p_waterflow_permanent_UIS");
initsymbol("l_arrow_SKBB");
initsymbol("l_border_presumed_SKBB");
initsymbol("l_border_temporary_SKBB");
initsymbol("l_border_visible_SKBB");
initsymbol("l_ceilingmeander_NZSS");
initsymbol("l_ceilingmeander_SKBB");
initsymbol("l_ceilingmeander_UIS");
initsymbol("l_ceilingstep_NZSS");
initsymbol("l_ceilingstep_SKBB");
initsymbol("l_ceilingstep_UIS");
initsymbol("l_chimney_NZSS");
initsymbol("l_chimney_UIS");
initsymbol("l_contour_AUT");
initsymbol("l_contour_SKBB");
initsymbol("l_contour_UIS");
initsymbol("l_fixedladder_SKBB");
initsymbol("l_floormeander_SKBB");
initsymbol("l_floorstep_AUT");
initsymbol("l_floorstep_UIS");
initsymbol("l_flowstone_AUT");
initsymbol("l_flowstone_UIS");
initsymbol("l_gradient_BCRA");
initsymbol("l_gradient_UIS");
initsymbol("l_handrail_SKBB");
initsymbol("l_mapconnection_SKBB");
initsymbol("l_moonmilk_UIS");
initsymbol("l_overhang_AUT");
initsymbol("l_overhang_SKBB");
initsymbol("l_pit_AUT");
initsymbol("l_pit_UIS");
initsymbol("l_rockborder_UIS");
initsymbol("l_rockedge_UIS");
initsymbol("l_rope_SKBB");
initsymbol("l_ropeladder_SKBB");
initsymbol("l_section_SKBB");
initsymbol("l_slope_BCRA");
initsymbol("l_slope_SKBB");
initsymbol("l_steps_SKBB");
initsymbol("l_survey_cave_AUT");
initsymbol("l_survey_cave_SKBB");
initsymbol("l_survey_cave_UIS");
initsymbol("l_survey_surface_SKBB");
initsymbol("l_viaferrata_SKBB");
initsymbol("l_wall_bedrock_UIS");
initsymbol("l_wall_blocks_AUT");
initsymbol("l_wall_blocks_SKBB");
initsymbol("l_wall_clay_AUT");
initsymbol("l_wall_clay_SKBB");
initsymbol("l_wall_debris_AUT");
initsymbol("l_wall_debris_SKBB");
initsymbol("l_wall_flowstone_AUT");
initsymbol("l_wall_ice_AUT");
initsymbol("l_wall_ice_SKBB");
initsymbol("l_wall_moonmilk_AUT");
initsymbol("l_wall_overlying_AUT");
initsymbol("l_wall_pebbles_AUT");
initsymbol("l_wall_pebbles_SKBB");
initsymbol("l_wall_pit_AUT");
initsymbol("l_wall_presumed_NZSS");
initsymbol("l_wall_presumed_UIS");
initsymbol("l_wall_sand_AUT");
initsymbol("l_wall_sand_SKBB");
initsymbol("l_wall_underlying_AUT");
initsymbol("l_wall_underlying_UIS");
initsymbol("l_wall_unsurveyed_SKBB");
initsymbol("l_waterflow_conjectural_SKBB");
initsymbol("l_waterflow_intermittent_SKBB");
initsymbol("l_waterflow_permanent_UIS");
initsymbol("a_bedrock_SKBB");
initsymbol("a_blocks_AUT");
initsymbol("a_blocks_SKBB");
initsymbol("a_clay_AUT");
initsymbol("a_clay_SKBB");
initsymbol("a_debris_AUT");
initsymbol("a_debris_SKBB");
initsymbol("a_debris_UIS");
initsymbol("a_dimensions_SKBB");
initsymbol("a_flowstone_ASF");
initsymbol("a_ice_AUT");
initsymbol("a_ice_SKBB");
initsymbol("a_moonmilk_SKBB");
initsymbol("a_pebbles_AUT");
initsymbol("a_pebbles_SKBB");
initsymbol("a_sand_AUT");
initsymbol("a_sand_UIS");
initsymbol("a_snow_AUT");
initsymbol("a_snow_SKBB");
initsymbol("a_sump_AUT");
initsymbol("a_sump_SKBB");
initsymbol("a_sump_UIS");
initsymbol("a_water_AUT");
initsymbol("a_water_SKBB");
initsymbol("a_water_UIS");

lang:="en";
ATTR__elevation:=false;

% user defined symbols defaults
% end of user defined symbols

defaultfont:="cmss10";
NorthDir:="true";
def a_water (expr p) =
T:=identity;
thfill p withcolor (0.1, 0.2, 0.8);
enddef;
def l_survey_cave (expr p) =
draw p withpen PenD withcolor (0.6, 0.6, 0.6);
enddef;
def s_northarrow (expr rot) =
T:=identity scaled 0.7 rotated -rot;
thdraw (-1cm,-1cm)--(0,5cm)--(1cm,-1cm)--(0,0cm)--cycle;
thfill (-1cm,-1cm)--(0,5cm)--(0,0cm)--cycle;
enddef;
fonts_setup(6,8,30,54,80);
transparency:=true;
background:=(1.00000,1.00000,1.00000);
def_transparent_rgb(tr_bg, 1.00000, 1.00000, 1.00000);
current_scrap := "Beauty_Above_Pitch_3_Sec_2@C4HelicopterHole";
ATTR__scrap := "Beauty_Above_Pitch_3_Sec_2";
beginfig(1);
ATTR__survey := "C4HelicopterHole";
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [948]";
string area_border[];
area_border[1] := "l166-76892-77516";
area_border[2] := "l512-82932-78112";
area_border[3] := "l511-82028-78160";
drawoptions();
a_blocks(buildcycle(((26.63,279.70)
 .. controls (25.98,279.10) and (24.77,278.10) .. (23.00,276.59)
 .. controls (21.23,275.09) and (20.28,274.57) .. (18.47,274.22)
 .. controls (16.66,273.87) and (13.92,269.93) .. (12.54,268.34)
 .. controls (11.15,266.75) and (6.84,269.19) .. (4.59,270.26)
 .. controls (2.34,271.34) and (-1.95,270.61) .. (-3.60,271.03)
 .. controls (-5.25,271.45) and (-8.90,271.51) .. (-10.99,270.96)
 .. controls (-13.09,270.40) and (-15.06,266.58) .. (-17.30,264.78)
 .. controls (-19.55,262.97) and (-20.62,263.60) .. (-22.83,263.52)
 .. controls (-25.04,263.44) and (-26.33,262.05) .. (-28.28,260.16)
 .. controls (-30.23,258.27) and (-35.59,257.50) .. (-37.31,257.16)
 .. controls (-39.03,256.81) and (-44.10,256.34) .. (-46.20,255.88)
 .. controls (-48.30,255.42) and (-52.97,254.57) .. (-55.78,255.05)
 .. controls (-58.58,255.52) and (-59.58,256.54) .. (-64.76,259.13)
 .. controls (-69.95,261.73) and (-73.64,260.25) .. (-75.45,259.90)
 .. controls (-77.27,259.54) and (-82.27,252.21) .. (-85.82,249.16)
 .. controls (-89.08,246.35) and (-93.51,246.58) .. (-95.75,247.46)
 .. controls (-97.99,248.34) and (-98.46,247.94) .. (-99.30,247.43)
 .. controls (-100.15,246.92) and (-105.65,247.58) .. (-108.43,247.58)
 .. controls (-111.21,247.57) and (-113.29,249.32) .. (-115.42,249.72)
 .. controls (-117.54,250.13) and (-121.44,246.44) .. (-123.50,245.11)
 .. controls (-125.57,243.79) and (-125.27,243.42) .. (-125.64,243.02)
 .. controls (-126.01,242.63) and (-128.88,242.43) .. (-129.43,241.93)
 .. controls (-129.99,241.43) and (-131.41,240.71) .. (-132.17,240.68)
 .. controls (-132.94,240.65) and (-133.75,239.28) .. (-138.76,239.68)
 .. controls (-143.77,240.08) and (-140.62,237.98) .. (-141.27,237.29)
 .. controls (-141.91,236.59) and (-140.85,233.75) .. (-140.85,233.75)
),
((-10.59,254.16)
 .. controls (-10.59,254.16) and (-9.23,253.92) .. (-7.32,254.09)
 .. controls (-5.40,254.25) and (-5.35,252.91) .. (-2.24,254.37)
 .. controls (0.88,255.82) and (3.45,256.59) .. (5.32,257.81)
 .. controls (7.20,259.03) and (8.94,258.80) .. (9.85,260.18)
 .. controls (10.76,261.55) and (11.07,260.99) .. (11.67,262.83)
 .. controls (12.28,264.68) and (12.03,263.62) .. (12.73,265.66)
 .. controls (13.42,267.70) and (12.52,271.41) .. (12.52,271.41)
),
((-18.10,265.52)
 .. controls (-16.01,263.57) and (-15.05,263.61) .. (-13.82,261.44)
 .. controls (-12.59,259.28) and (-12.38,258.80) .. (-12.05,257.38)
 .. controls (-11.71,255.95) and (-11.71,256.04) .. (-10.59,254.16)
 .. controls (-9.46,252.28) and (-8.30,252.04) .. (-8.12,249.64)
 .. controls (-7.94,247.25) and (-7.15,246.60) .. (-7.87,245.23)
 .. controls (-8.59,243.86) and (-9.06,240.96) .. (-10.27,239.96)
 .. controls (-11.49,238.95) and (-12.04,238.26) .. (-13.54,237.24)
 .. controls (-15.05,236.23) and (-16.27,235.61) .. (-16.81,234.53)
 .. controls (-17.35,233.46) and (-17.74,233.54) .. (-17.98,232.28)
 .. controls (-18.23,231.03) and (-17.77,228.83) .. (-17.77,228.83)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [940]";
string area_border[];
area_border[1] := "l511-82028-78160";
area_border[2] := "l165-77436-76312";
area_border[3] := "l474-81252-77188";
area_border[4] := "l472-81464-77896";
area_border[5] := "l166-76892-77516";
drawoptions();
a_sand(buildcycle(((-18.10,265.52)
 .. controls (-16.01,263.57) and (-15.05,263.61) .. (-13.82,261.44)
 .. controls (-12.59,259.28) and (-12.38,258.80) .. (-12.05,257.38)
 .. controls (-11.71,255.95) and (-11.71,256.04) .. (-10.59,254.16)
 .. controls (-9.46,252.28) and (-8.30,252.04) .. (-8.12,249.64)
 .. controls (-7.94,247.25) and (-7.15,246.60) .. (-7.87,245.23)
 .. controls (-8.59,243.86) and (-9.06,240.96) .. (-10.27,239.96)
 .. controls (-11.49,238.95) and (-12.04,238.26) .. (-13.54,237.24)
 .. controls (-15.05,236.23) and (-16.27,235.61) .. (-16.81,234.53)
 .. controls (-17.35,233.46) and (-17.74,233.54) .. (-17.98,232.28)
 .. controls (-18.23,231.03) and (-17.77,228.83) .. (-17.77,228.83)
),
((-126.70,210.85)
 .. controls (-126.70,210.85) and (-124.00,210.65) .. (-122.30,211.19)
 .. controls (-120.59,211.74) and (-117.49,213.67) .. (-116.82,213.60)
 .. controls (-116.14,213.52) and (-115.65,213.16) .. (-116.56,211.78)
 .. controls (-117.47,210.41) and (-117.99,206.16) .. (-118.83,205.37)
 .. controls (-119.66,204.57) and (-120.63,202.14) .. (-120.33,201.67)
 .. controls (-120.02,201.20) and (-119.25,200.94) .. (-117.43,201.19)
 .. controls (-115.62,201.45) and (-114.26,201.21) .. (-112.64,201.27)
 .. controls (-111.01,201.32) and (-106.63,199.66) .. (-104.17,200.70)
 .. controls (-101.71,201.75) and (-99.49,201.35) .. (-96.62,204.52)
 .. controls (-93.76,207.69) and (-90.22,210.88) .. (-88.39,210.85)
 .. controls (-86.56,210.82) and (-84.74,210.98) .. (-82.32,210.39)
 .. controls (-79.89,209.81) and (-71.28,210.79) .. (-69.39,209.03)
 .. controls (-67.50,207.28) and (-66.62,206.93) .. (-67.86,203.81)
 .. controls (-69.09,200.69) and (-69.72,196.73) .. (-67.72,194.59)
 .. controls (-65.72,192.45) and (-66.10,192.25) .. (-63.82,193.10)
 .. controls (-61.55,193.95) and (-58.78,197.12) .. (-57.76,198.02)
 .. controls (-56.73,198.92) and (-50.59,204.33) .. (-49.23,209.28)
 .. controls (-47.87,214.23) and (-45.40,212.30) .. (-45.87,217.18)
 .. controls (-46.33,222.06) and (-47.31,225.39) .. (-44.85,226.34)
 .. controls (-42.39,227.29) and (-41.00,228.68) .. (-38.02,228.41)
 .. controls (-35.03,228.13) and (-36.04,226.94) .. (-33.35,226.94)
 .. controls (-30.67,226.94) and (-31.23,229.41) .. (-29.38,228.61)
 .. controls (-27.53,227.81) and (-26.28,225.27) .. (-24.30,226.20)
 .. controls (-22.32,227.13) and (-18.62,231.40) .. (-16.33,231.67)
 .. controls (-14.03,231.94) and (-14.38,230.97) .. (-11.86,230.39)
 .. controls (-9.34,229.81) and (0.17,227.17) .. (2.68,226.98)
 .. controls (5.18,226.78) and (10.00,223.88) .. (10.98,223.24)
 .. controls (11.96,222.60) and (16.74,220.57) .. (18.08,217.92)
 .. controls (19.42,215.28) and (19.90,212.61) .. (19.03,210.18)
 .. controls (18.15,207.74) and (18.05,205.24) .. (16.91,204.91)
 .. controls (15.77,204.58) and (15.72,206.02) .. (15.83,202.95)
 .. controls (15.94,199.88) and (16.02,194.70) .. (16.02,194.70)
 .. controls (16.02,194.70) and (16.92,196.65) .. (17.40,196.47)
 .. controls (17.89,196.30) and (18.43,194.69) .. (19.02,194.13)
 .. controls (19.62,193.57) and (20.60,193.13) .. (19.49,191.84)
 .. controls (18.38,190.55) and (17.81,187.65) .. (18.32,186.80)
 .. controls (18.83,185.96) and (20.24,181.49) .. (19.33,180.11)
 .. controls (18.42,178.73) and (14.55,176.86) .. (13.65,172.41)
 .. controls (12.76,167.96) and (14.02,162.34) .. (14.37,160.72)
 .. controls (14.71,159.10) and (17.65,155.77) .. (16.94,153.42)
),
((-31.60,247.84)
 .. controls (-30.16,245.21) and (-29.33,243.51) .. (-29.38,242.25)
 .. controls (-29.43,241.00) and (-29.48,239.66) .. (-30.00,238.01)
 .. controls (-30.52,236.35) and (-30.85,235.00) .. (-30.91,233.84)
 .. controls (-30.96,232.69) and (-31.39,231.23) .. (-31.36,230.37)
 .. controls (-31.33,229.50) and (-31.38,225.47) .. (-31.38,225.47)
),
((-21.34,264.73)
 .. controls (-20.89,262.92) and (-20.26,261.31) .. (-20.78,259.95)
 .. controls (-21.31,258.58) and (-21.34,256.76) .. (-23.12,255.35)
 .. controls (-24.89,253.94) and (-27.33,252.13) .. (-27.97,251.24)
 .. controls (-28.61,250.35) and (-29.96,247.71) .. (-30.61,247.01)
 .. controls (-31.25,246.32) and (-32.36,245.13) .. (-33.01,244.34)
 .. controls (-33.65,243.54) and (-36.29,242.10) .. (-36.29,242.10)
 -- (-39.05,241.33)
),
((26.63,279.70)
 .. controls (25.98,279.10) and (24.77,278.10) .. (23.00,276.59)
 .. controls (21.23,275.09) and (20.28,274.57) .. (18.47,274.22)
 .. controls (16.66,273.87) and (13.92,269.93) .. (12.54,268.34)
 .. controls (11.15,266.75) and (6.84,269.19) .. (4.59,270.26)
 .. controls (2.34,271.34) and (-1.95,270.61) .. (-3.60,271.03)
 .. controls (-5.25,271.45) and (-8.90,271.51) .. (-10.99,270.96)
 .. controls (-13.09,270.40) and (-15.06,266.58) .. (-17.30,264.78)
 .. controls (-19.55,262.97) and (-20.62,263.60) .. (-22.83,263.52)
 .. controls (-25.04,263.44) and (-26.33,262.05) .. (-28.28,260.16)
 .. controls (-30.23,258.27) and (-35.59,257.50) .. (-37.31,257.16)
 .. controls (-39.03,256.81) and (-44.10,256.34) .. (-46.20,255.88)
 .. controls (-48.30,255.42) and (-52.97,254.57) .. (-55.78,255.05)
 .. controls (-58.58,255.52) and (-59.58,256.54) .. (-64.76,259.13)
 .. controls (-69.95,261.73) and (-73.64,260.25) .. (-75.45,259.90)
 .. controls (-77.27,259.54) and (-82.27,252.21) .. (-85.82,249.16)
 .. controls (-89.08,246.35) and (-93.51,246.58) .. (-95.75,247.46)
 .. controls (-97.99,248.34) and (-98.46,247.94) .. (-99.30,247.43)
 .. controls (-100.15,246.92) and (-105.65,247.58) .. (-108.43,247.58)
 .. controls (-111.21,247.57) and (-113.29,249.32) .. (-115.42,249.72)
 .. controls (-117.54,250.13) and (-121.44,246.44) .. (-123.50,245.11)
 .. controls (-125.57,243.79) and (-125.27,243.42) .. (-125.64,243.02)
 .. controls (-126.01,242.63) and (-128.88,242.43) .. (-129.43,241.93)
 .. controls (-129.99,241.43) and (-131.41,240.71) .. (-132.17,240.68)
 .. controls (-132.94,240.65) and (-133.75,239.28) .. (-138.76,239.68)
 .. controls (-143.77,240.08) and (-140.62,237.98) .. (-141.27,237.29)
 .. controls (-141.91,236.59) and (-140.85,233.75) .. (-140.85,233.75)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [885]";
string area_border[];
area_border[1] := "l518-83180-77204";
area_border[2] := "l160-84024-77676";
area_border[3] := "l517-84068-79112";
area_border[4] := "l515-83772-79120";
area_border[5] := "l166-76892-77516";
area_border[6] := "l512-82932-78112";
area_border[7] := "l511-82028-78160";
area_border[8] := "l165-77436-76312";
drawoptions();
a_water(buildcycle(((2.34,225.62)
 .. controls (2.58,227.07) and (2.31,229.36) .. (2.25,230.90)
 .. controls (2.20,232.43) and (0.85,232.58) .. (2.73,233.70)
 .. controls (4.61,234.83) and (4.90,234.74) .. (7.26,235.88)
 .. controls (9.62,237.02) and (8.67,236.89) .. (12.29,237.60)
 .. controls (15.91,238.30) and (17.41,236.72) .. (18.58,236.29)
 .. controls (19.75,235.85) and (20.66,234.54) .. (22.29,234.59)
 .. controls (23.92,234.65) and (24.50,234.67) .. (26.23,234.45)
 .. controls (27.97,234.22) and (29.15,233.59) .. (29.84,233.04)
 .. controls (30.53,232.49) and (31.33,231.65) .. (32.02,231.10)
 .. controls (32.71,230.55) and (34.76,229.76) .. (34.76,229.76)
),
((32.47,277.70)
 .. controls (32.41,273.86) and (31.89,272.21) .. (33.30,270.43)
 .. controls (34.71,268.66) and (35.94,266.49) .. (35.74,264.08)
 .. controls (35.54,261.68) and (35.07,258.59) .. (35.34,256.39)
 .. controls (35.61,254.19) and (35.47,247.46) .. (35.06,245.62)
 .. controls (34.64,243.78) and (32.81,233.15) .. (32.77,231.51)
 .. controls (32.74,229.88) and (32.51,222.86) .. (32.70,220.27)
 .. controls (32.88,217.68) and (34.12,212.73) .. (34.17,211.29)
 .. controls (34.22,209.85) and (34.18,205.62) .. (34.31,204.76)
 .. controls (34.43,203.90) and (35.46,204.71) .. (36.04,201.85)
 .. controls (36.63,198.99) and (34.94,194.99) .. (35.92,194.44)
 .. controls (36.90,193.90) and (37.97,190.96) .. (38.25,188.38)
 .. controls (38.54,185.79) and (39.39,178.14) .. (39.07,176.30)
 .. controls (38.75,174.46) and (37.90,171.36) .. (38.82,169.76)
 .. controls (39.74,168.16) and (39.65,167.96) .. (39.35,165.55)
 .. controls (39.06,163.14) and (38.91,161.98) .. (39.75,160.00)
 .. controls (40.59,158.01) and (42.01,155.85) .. (41.89,153.93)
 .. controls (41.76,152.01) and (42.71,152.42) .. (44.43,150.08)
 .. controls (46.14,147.74) and (43.61,143.33) .. (41.63,139.71)
 .. controls (39.64,136.08) and (38.86,130.96) .. (38.46,128.74)
 .. controls (38.06,126.51) and (36.21,121.84) .. (36.41,118.77)
 .. controls (36.61,115.70) and (37.13,112.07) .. (37.21,109.67)
 .. controls (37.30,107.28) and (35.97,104.25) .. (36.16,101.66)
 .. controls (36.35,99.08) and (34.90,99.41) .. (36.62,96.97)
 .. controls (38.34,94.54) and (39.88,89.02) .. (39.23,85.83)
 .. controls (38.58,82.64) and (38.19,77.43) .. (33.00,74.94)
 .. controls (27.80,72.45) and (28.31,71.79) .. (26.85,66.84)
 .. controls (25.40,61.88) and (26.01,57.97) .. (26.07,56.33)
 .. controls (26.13,54.70) and (25.53,47.28) .. (26.17,45.48)
 .. controls (26.81,43.68) and (27.76,41.12) .. (30.58,42.85)
 .. controls (33.40,44.59) and (38.25,46.01) .. (39.88,46.07)
 .. controls (41.52,46.13) and (42.11,45.47) .. (42.51,45.10)
 .. controls (42.91,44.73) and (43.11,44.55) .. (44.38,46.71)
 .. controls (45.64,48.87) and (44.79,45.86) .. (45.86,45.42)
 .. controls (46.94,44.97) and (47.88,45.49) .. (46.27,41.97)
 .. controls (44.67,38.46) and (41.26,34.40) .. (41.36,31.52)
 .. controls (41.47,28.64) and (40.13,23.12) .. (39.86,22.53)
),
((32.47,277.70)
 .. controls (33.06,279.84) and (33.36,279.56) .. (34.24,281.70)
 .. controls (35.13,283.85) and (36.30,286.10) .. (36.74,287.17)
 .. controls (37.18,288.25) and (38.81,290.99) .. (39.58,293.62)
 .. controls (40.35,296.24) and (39.97,296.22) .. (39.99,298.34)
 .. controls (40.01,300.45) and (41.20,301.94) .. (41.92,303.50)
 .. controls (42.63,305.06) and (43.24,306.72) .. (43.69,307.60)
 .. controls (44.14,308.48) and (44.50,308.97) .. (45.69,310.65)
 .. controls (46.88,312.32) and (47.72,312.93) .. (48.25,314.29)
 .. controls (48.78,315.66) and (50.54,322.64) .. (50.54,322.64)
),
((50.54,322.64)
 .. controls (50.54,322.64) and (48.50,320.64) .. (47.46,320.22)
 .. controls (46.42,319.80) and (46.27,318.74) .. (45.07,317.25)
 .. controls (43.88,315.77) and (43.52,314.99) .. (42.25,313.02)
 .. controls (40.97,311.05) and (41.27,310.68) .. (40.61,307.77)
 .. controls (39.95,304.87) and (37.99,303.26) .. (35.96,300.98)
 .. controls (33.92,298.70) and (34.91,297.96) .. (34.39,296.41)
 .. controls (33.87,294.85) and (33.23,293.96) .. (31.21,291.30)
 .. controls (29.19,288.63) and (30.03,289.43) .. (29.62,287.49)
 .. controls (29.21,285.56) and (28.65,284.96) .. (28.30,284.08)
 .. controls (27.95,283.21) and (26.81,280.09) .. (26.63,279.70)
),
((26.63,279.70)
 .. controls (25.98,279.10) and (24.77,278.10) .. (23.00,276.59)
 .. controls (21.23,275.09) and (20.28,274.57) .. (18.47,274.22)
 .. controls (16.66,273.87) and (13.92,269.93) .. (12.54,268.34)
 .. controls (11.15,266.75) and (6.84,269.19) .. (4.59,270.26)
 .. controls (2.34,271.34) and (-1.95,270.61) .. (-3.60,271.03)
 .. controls (-5.25,271.45) and (-8.90,271.51) .. (-10.99,270.96)
 .. controls (-13.09,270.40) and (-15.06,266.58) .. (-17.30,264.78)
 .. controls (-19.55,262.97) and (-20.62,263.60) .. (-22.83,263.52)
 .. controls (-25.04,263.44) and (-26.33,262.05) .. (-28.28,260.16)
 .. controls (-30.23,258.27) and (-35.59,257.50) .. (-37.31,257.16)
 .. controls (-39.03,256.81) and (-44.10,256.34) .. (-46.20,255.88)
 .. controls (-48.30,255.42) and (-52.97,254.57) .. (-55.78,255.05)
 .. controls (-58.58,255.52) and (-59.58,256.54) .. (-64.76,259.13)
 .. controls (-69.95,261.73) and (-73.64,260.25) .. (-75.45,259.90)
 .. controls (-77.27,259.54) and (-82.27,252.21) .. (-85.82,249.16)
 .. controls (-89.08,246.35) and (-93.51,246.58) .. (-95.75,247.46)
 .. controls (-97.99,248.34) and (-98.46,247.94) .. (-99.30,247.43)
 .. controls (-100.15,246.92) and (-105.65,247.58) .. (-108.43,247.58)
 .. controls (-111.21,247.57) and (-113.29,249.32) .. (-115.42,249.72)
 .. controls (-117.54,250.13) and (-121.44,246.44) .. (-123.50,245.11)
 .. controls (-125.57,243.79) and (-125.27,243.42) .. (-125.64,243.02)
 .. controls (-126.01,242.63) and (-128.88,242.43) .. (-129.43,241.93)
 .. controls (-129.99,241.43) and (-131.41,240.71) .. (-132.17,240.68)
 .. controls (-132.94,240.65) and (-133.75,239.28) .. (-138.76,239.68)
 .. controls (-143.77,240.08) and (-140.62,237.98) .. (-141.27,237.29)
 .. controls (-141.91,236.59) and (-140.85,233.75) .. (-140.85,233.75)
),
((-10.59,254.16)
 .. controls (-10.59,254.16) and (-9.23,253.92) .. (-7.32,254.09)
 .. controls (-5.40,254.25) and (-5.35,252.91) .. (-2.24,254.37)
 .. controls (0.88,255.82) and (3.45,256.59) .. (5.32,257.81)
 .. controls (7.20,259.03) and (8.94,258.80) .. (9.85,260.18)
 .. controls (10.76,261.55) and (11.07,260.99) .. (11.67,262.83)
 .. controls (12.28,264.68) and (12.03,263.62) .. (12.73,265.66)
 .. controls (13.42,267.70) and (12.52,271.41) .. (12.52,271.41)
),
((-18.10,265.52)
 .. controls (-16.01,263.57) and (-15.05,263.61) .. (-13.82,261.44)
 .. controls (-12.59,259.28) and (-12.38,258.80) .. (-12.05,257.38)
 .. controls (-11.71,255.95) and (-11.71,256.04) .. (-10.59,254.16)
 .. controls (-9.46,252.28) and (-8.30,252.04) .. (-8.12,249.64)
 .. controls (-7.94,247.25) and (-7.15,246.60) .. (-7.87,245.23)
 .. controls (-8.59,243.86) and (-9.06,240.96) .. (-10.27,239.96)
 .. controls (-11.49,238.95) and (-12.04,238.26) .. (-13.54,237.24)
 .. controls (-15.05,236.23) and (-16.27,235.61) .. (-16.81,234.53)
 .. controls (-17.35,233.46) and (-17.74,233.54) .. (-17.98,232.28)
 .. controls (-18.23,231.03) and (-17.77,228.83) .. (-17.77,228.83)
),
((-126.70,210.85)
 .. controls (-126.70,210.85) and (-124.00,210.65) .. (-122.30,211.19)
 .. controls (-120.59,211.74) and (-117.49,213.67) .. (-116.82,213.60)
 .. controls (-116.14,213.52) and (-115.65,213.16) .. (-116.56,211.78)
 .. controls (-117.47,210.41) and (-117.99,206.16) .. (-118.83,205.37)
 .. controls (-119.66,204.57) and (-120.63,202.14) .. (-120.33,201.67)
 .. controls (-120.02,201.20) and (-119.25,200.94) .. (-117.43,201.19)
 .. controls (-115.62,201.45) and (-114.26,201.21) .. (-112.64,201.27)
 .. controls (-111.01,201.32) and (-106.63,199.66) .. (-104.17,200.70)
 .. controls (-101.71,201.75) and (-99.49,201.35) .. (-96.62,204.52)
 .. controls (-93.76,207.69) and (-90.22,210.88) .. (-88.39,210.85)
 .. controls (-86.56,210.82) and (-84.74,210.98) .. (-82.32,210.39)
 .. controls (-79.89,209.81) and (-71.28,210.79) .. (-69.39,209.03)
 .. controls (-67.50,207.28) and (-66.62,206.93) .. (-67.86,203.81)
 .. controls (-69.09,200.69) and (-69.72,196.73) .. (-67.72,194.59)
 .. controls (-65.72,192.45) and (-66.10,192.25) .. (-63.82,193.10)
 .. controls (-61.55,193.95) and (-58.78,197.12) .. (-57.76,198.02)
 .. controls (-56.73,198.92) and (-50.59,204.33) .. (-49.23,209.28)
 .. controls (-47.87,214.23) and (-45.40,212.30) .. (-45.87,217.18)
 .. controls (-46.33,222.06) and (-47.31,225.39) .. (-44.85,226.34)
 .. controls (-42.39,227.29) and (-41.00,228.68) .. (-38.02,228.41)
 .. controls (-35.03,228.13) and (-36.04,226.94) .. (-33.35,226.94)
 .. controls (-30.67,226.94) and (-31.23,229.41) .. (-29.38,228.61)
 .. controls (-27.53,227.81) and (-26.28,225.27) .. (-24.30,226.20)
 .. controls (-22.32,227.13) and (-18.62,231.40) .. (-16.33,231.67)
 .. controls (-14.03,231.94) and (-14.38,230.97) .. (-11.86,230.39)
 .. controls (-9.34,229.81) and (0.17,227.17) .. (2.68,226.98)
 .. controls (5.18,226.78) and (10.00,223.88) .. (10.98,223.24)
 .. controls (11.96,222.60) and (16.74,220.57) .. (18.08,217.92)
 .. controls (19.42,215.28) and (19.90,212.61) .. (19.03,210.18)
 .. controls (18.15,207.74) and (18.05,205.24) .. (16.91,204.91)
 .. controls (15.77,204.58) and (15.72,206.02) .. (15.83,202.95)
 .. controls (15.94,199.88) and (16.02,194.70) .. (16.02,194.70)
 .. controls (16.02,194.70) and (16.92,196.65) .. (17.40,196.47)
 .. controls (17.89,196.30) and (18.43,194.69) .. (19.02,194.13)
 .. controls (19.62,193.57) and (20.60,193.13) .. (19.49,191.84)
 .. controls (18.38,190.55) and (17.81,187.65) .. (18.32,186.80)
 .. controls (18.83,185.96) and (20.24,181.49) .. (19.33,180.11)
 .. controls (18.42,178.73) and (14.55,176.86) .. (13.65,172.41)
 .. controls (12.76,167.96) and (14.02,162.34) .. (14.37,160.72)
 .. controls (14.71,159.10) and (17.65,155.77) .. (16.94,153.42)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [868]";
string area_border[];
area_border[1] := "l522-83824-73780";
area_border[2] := "l160-84024-77676";
area_border[3] := "l518-83180-77204";
area_border[4] := "l165-77436-76312";
drawoptions();
a_flowstone(buildcycle(((14.70,156.70)
 .. controls (19.42,156.39) and (20.42,155.37) .. (22.84,154.78)
 .. controls (25.26,154.20) and (24.81,153.51) .. (28.22,154.59)
 .. controls (31.64,155.68) and (32.00,156.26) .. (33.93,156.24)
 .. controls (35.85,156.21) and (37.40,155.69) .. (37.98,155.62)
 .. controls (38.56,155.54) and (43.41,156.86) .. (43.41,156.86)
),
((32.47,277.70)
 .. controls (32.41,273.86) and (31.89,272.21) .. (33.30,270.43)
 .. controls (34.71,268.66) and (35.94,266.49) .. (35.74,264.08)
 .. controls (35.54,261.68) and (35.07,258.59) .. (35.34,256.39)
 .. controls (35.61,254.19) and (35.47,247.46) .. (35.06,245.62)
 .. controls (34.64,243.78) and (32.81,233.15) .. (32.77,231.51)
 .. controls (32.74,229.88) and (32.51,222.86) .. (32.70,220.27)
 .. controls (32.88,217.68) and (34.12,212.73) .. (34.17,211.29)
 .. controls (34.22,209.85) and (34.18,205.62) .. (34.31,204.76)
 .. controls (34.43,203.90) and (35.46,204.71) .. (36.04,201.85)
 .. controls (36.63,198.99) and (34.94,194.99) .. (35.92,194.44)
 .. controls (36.90,193.90) and (37.97,190.96) .. (38.25,188.38)
 .. controls (38.54,185.79) and (39.39,178.14) .. (39.07,176.30)
 .. controls (38.75,174.46) and (37.90,171.36) .. (38.82,169.76)
 .. controls (39.74,168.16) and (39.65,167.96) .. (39.35,165.55)
 .. controls (39.06,163.14) and (38.91,161.98) .. (39.75,160.00)
 .. controls (40.59,158.01) and (42.01,155.85) .. (41.89,153.93)
 .. controls (41.76,152.01) and (42.71,152.42) .. (44.43,150.08)
 .. controls (46.14,147.74) and (43.61,143.33) .. (41.63,139.71)
 .. controls (39.64,136.08) and (38.86,130.96) .. (38.46,128.74)
 .. controls (38.06,126.51) and (36.21,121.84) .. (36.41,118.77)
 .. controls (36.61,115.70) and (37.13,112.07) .. (37.21,109.67)
 .. controls (37.30,107.28) and (35.97,104.25) .. (36.16,101.66)
 .. controls (36.35,99.08) and (34.90,99.41) .. (36.62,96.97)
 .. controls (38.34,94.54) and (39.88,89.02) .. (39.23,85.83)
 .. controls (38.58,82.64) and (38.19,77.43) .. (33.00,74.94)
 .. controls (27.80,72.45) and (28.31,71.79) .. (26.85,66.84)
 .. controls (25.40,61.88) and (26.01,57.97) .. (26.07,56.33)
 .. controls (26.13,54.70) and (25.53,47.28) .. (26.17,45.48)
 .. controls (26.81,43.68) and (27.76,41.12) .. (30.58,42.85)
 .. controls (33.40,44.59) and (38.25,46.01) .. (39.88,46.07)
 .. controls (41.52,46.13) and (42.11,45.47) .. (42.51,45.10)
 .. controls (42.91,44.73) and (43.11,44.55) .. (44.38,46.71)
 .. controls (45.64,48.87) and (44.79,45.86) .. (45.86,45.42)
 .. controls (46.94,44.97) and (47.88,45.49) .. (46.27,41.97)
 .. controls (44.67,38.46) and (41.26,34.40) .. (41.36,31.52)
 .. controls (41.47,28.64) and (40.13,23.12) .. (39.86,22.53)
),
((2.34,225.62)
 .. controls (2.58,227.07) and (2.31,229.36) .. (2.25,230.90)
 .. controls (2.20,232.43) and (0.85,232.58) .. (2.73,233.70)
 .. controls (4.61,234.83) and (4.90,234.74) .. (7.26,235.88)
 .. controls (9.62,237.02) and (8.67,236.89) .. (12.29,237.60)
 .. controls (15.91,238.30) and (17.41,236.72) .. (18.58,236.29)
 .. controls (19.75,235.85) and (20.66,234.54) .. (22.29,234.59)
 .. controls (23.92,234.65) and (24.50,234.67) .. (26.23,234.45)
 .. controls (27.97,234.22) and (29.15,233.59) .. (29.84,233.04)
 .. controls (30.53,232.49) and (31.33,231.65) .. (32.02,231.10)
 .. controls (32.71,230.55) and (34.76,229.76) .. (34.76,229.76)
),
((-126.70,210.85)
 .. controls (-126.70,210.85) and (-124.00,210.65) .. (-122.30,211.19)
 .. controls (-120.59,211.74) and (-117.49,213.67) .. (-116.82,213.60)
 .. controls (-116.14,213.52) and (-115.65,213.16) .. (-116.56,211.78)
 .. controls (-117.47,210.41) and (-117.99,206.16) .. (-118.83,205.37)
 .. controls (-119.66,204.57) and (-120.63,202.14) .. (-120.33,201.67)
 .. controls (-120.02,201.20) and (-119.25,200.94) .. (-117.43,201.19)
 .. controls (-115.62,201.45) and (-114.26,201.21) .. (-112.64,201.27)
 .. controls (-111.01,201.32) and (-106.63,199.66) .. (-104.17,200.70)
 .. controls (-101.71,201.75) and (-99.49,201.35) .. (-96.62,204.52)
 .. controls (-93.76,207.69) and (-90.22,210.88) .. (-88.39,210.85)
 .. controls (-86.56,210.82) and (-84.74,210.98) .. (-82.32,210.39)
 .. controls (-79.89,209.81) and (-71.28,210.79) .. (-69.39,209.03)
 .. controls (-67.50,207.28) and (-66.62,206.93) .. (-67.86,203.81)
 .. controls (-69.09,200.69) and (-69.72,196.73) .. (-67.72,194.59)
 .. controls (-65.72,192.45) and (-66.10,192.25) .. (-63.82,193.10)
 .. controls (-61.55,193.95) and (-58.78,197.12) .. (-57.76,198.02)
 .. controls (-56.73,198.92) and (-50.59,204.33) .. (-49.23,209.28)
 .. controls (-47.87,214.23) and (-45.40,212.30) .. (-45.87,217.18)
 .. controls (-46.33,222.06) and (-47.31,225.39) .. (-44.85,226.34)
 .. controls (-42.39,227.29) and (-41.00,228.68) .. (-38.02,228.41)
 .. controls (-35.03,228.13) and (-36.04,226.94) .. (-33.35,226.94)
 .. controls (-30.67,226.94) and (-31.23,229.41) .. (-29.38,228.61)
 .. controls (-27.53,227.81) and (-26.28,225.27) .. (-24.30,226.20)
 .. controls (-22.32,227.13) and (-18.62,231.40) .. (-16.33,231.67)
 .. controls (-14.03,231.94) and (-14.38,230.97) .. (-11.86,230.39)
 .. controls (-9.34,229.81) and (0.17,227.17) .. (2.68,226.98)
 .. controls (5.18,226.78) and (10.00,223.88) .. (10.98,223.24)
 .. controls (11.96,222.60) and (16.74,220.57) .. (18.08,217.92)
 .. controls (19.42,215.28) and (19.90,212.61) .. (19.03,210.18)
 .. controls (18.15,207.74) and (18.05,205.24) .. (16.91,204.91)
 .. controls (15.77,204.58) and (15.72,206.02) .. (15.83,202.95)
 .. controls (15.94,199.88) and (16.02,194.70) .. (16.02,194.70)
 .. controls (16.02,194.70) and (16.92,196.65) .. (17.40,196.47)
 .. controls (17.89,196.30) and (18.43,194.69) .. (19.02,194.13)
 .. controls (19.62,193.57) and (20.60,193.13) .. (19.49,191.84)
 .. controls (18.38,190.55) and (17.81,187.65) .. (18.32,186.80)
 .. controls (18.83,185.96) and (20.24,181.49) .. (19.33,180.11)
 .. controls (18.42,178.73) and (14.55,176.86) .. (13.65,172.41)
 .. controls (12.76,167.96) and (14.02,162.34) .. (14.37,160.72)
 .. controls (14.71,159.10) and (17.65,155.77) .. (16.94,153.42)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [835]";
string area_border[];
area_border[1] := "l522-83824-73780";
area_border[2] := "l160-84024-77676";
area_border[3] := "l526-84068-73320";
drawoptions();
a_blocks(buildcycle(((14.70,156.70)
 .. controls (19.42,156.39) and (20.42,155.37) .. (22.84,154.78)
 .. controls (25.26,154.20) and (24.81,153.51) .. (28.22,154.59)
 .. controls (31.64,155.68) and (32.00,156.26) .. (33.93,156.24)
 .. controls (35.85,156.21) and (37.40,155.69) .. (37.98,155.62)
 .. controls (38.56,155.54) and (43.41,156.86) .. (43.41,156.86)
),
((32.47,277.70)
 .. controls (32.41,273.86) and (31.89,272.21) .. (33.30,270.43)
 .. controls (34.71,268.66) and (35.94,266.49) .. (35.74,264.08)
 .. controls (35.54,261.68) and (35.07,258.59) .. (35.34,256.39)
 .. controls (35.61,254.19) and (35.47,247.46) .. (35.06,245.62)
 .. controls (34.64,243.78) and (32.81,233.15) .. (32.77,231.51)
 .. controls (32.74,229.88) and (32.51,222.86) .. (32.70,220.27)
 .. controls (32.88,217.68) and (34.12,212.73) .. (34.17,211.29)
 .. controls (34.22,209.85) and (34.18,205.62) .. (34.31,204.76)
 .. controls (34.43,203.90) and (35.46,204.71) .. (36.04,201.85)
 .. controls (36.63,198.99) and (34.94,194.99) .. (35.92,194.44)
 .. controls (36.90,193.90) and (37.97,190.96) .. (38.25,188.38)
 .. controls (38.54,185.79) and (39.39,178.14) .. (39.07,176.30)
 .. controls (38.75,174.46) and (37.90,171.36) .. (38.82,169.76)
 .. controls (39.74,168.16) and (39.65,167.96) .. (39.35,165.55)
 .. controls (39.06,163.14) and (38.91,161.98) .. (39.75,160.00)
 .. controls (40.59,158.01) and (42.01,155.85) .. (41.89,153.93)
 .. controls (41.76,152.01) and (42.71,152.42) .. (44.43,150.08)
 .. controls (46.14,147.74) and (43.61,143.33) .. (41.63,139.71)
 .. controls (39.64,136.08) and (38.86,130.96) .. (38.46,128.74)
 .. controls (38.06,126.51) and (36.21,121.84) .. (36.41,118.77)
 .. controls (36.61,115.70) and (37.13,112.07) .. (37.21,109.67)
 .. controls (37.30,107.28) and (35.97,104.25) .. (36.16,101.66)
 .. controls (36.35,99.08) and (34.90,99.41) .. (36.62,96.97)
 .. controls (38.34,94.54) and (39.88,89.02) .. (39.23,85.83)
 .. controls (38.58,82.64) and (38.19,77.43) .. (33.00,74.94)
 .. controls (27.80,72.45) and (28.31,71.79) .. (26.85,66.84)
 .. controls (25.40,61.88) and (26.01,57.97) .. (26.07,56.33)
 .. controls (26.13,54.70) and (25.53,47.28) .. (26.17,45.48)
 .. controls (26.81,43.68) and (27.76,41.12) .. (30.58,42.85)
 .. controls (33.40,44.59) and (38.25,46.01) .. (39.88,46.07)
 .. controls (41.52,46.13) and (42.11,45.47) .. (42.51,45.10)
 .. controls (42.91,44.73) and (43.11,44.55) .. (44.38,46.71)
 .. controls (45.64,48.87) and (44.79,45.86) .. (45.86,45.42)
 .. controls (46.94,44.97) and (47.88,45.49) .. (46.27,41.97)
 .. controls (44.67,38.46) and (41.26,34.40) .. (41.36,31.52)
 .. controls (41.47,28.64) and (40.13,23.12) .. (39.86,22.53)
),
((26.10,154.90)
 .. controls (25.52,152.48) and (24.03,151.27) .. (24.87,149.19)
 .. controls (25.71,147.11) and (27.41,142.47) .. (28.89,141.27)
 .. controls (30.38,140.08) and (31.34,137.42) .. (34.00,138.19)
 .. controls (36.66,138.95) and (39.19,140.68) .. (40.79,141.79)
 .. controls (42.38,142.90) and (43.12,143.51) .. (44.07,144.02)
 .. controls (45.01,144.53) and (47.17,148.55) .. (47.17,148.55)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [783]";
string area_border[];
area_border[1] := "l534-83324-70712";
area_border[2] := "l164-82800-70404";
area_border[3] := "l120-83388-73344";
area_border[4] := "l528-83268-73568";
area_border[5] := "l165-77436-76312";
area_border[6] := "l522-83824-73780";
area_border[7] := "l526-84068-73320";
area_border[8] := "l160-84024-77676";
area_border[9] := "l532-83760-71320";
area_border[10] := "l531-83492-70664";
area_border[11] := "l534-83324-70712";
drawoptions();
a_water(buildcycle(((12.76,81.90)
 .. controls (15.80,83.06) and (14.24,83.59) .. (16.75,83.20)
 .. controls (19.26,82.81) and (19.38,82.23) .. (21.78,82.22)
 .. controls (24.18,82.21) and (25.23,82.35) .. (25.81,82.37)
 .. controls (26.38,82.39) and (28.31,82.36) .. (28.31,82.36)
),
((24.45,144.76)
 .. controls (23.84,140.23) and (22.28,132.87) .. (21.39,130.82)
 .. controls (20.50,128.77) and (18.19,123.50) .. (19.39,122.01)
 .. controls (20.60,120.51) and (24.73,120.37) .. (24.29,116.42)
 .. controls (23.86,112.46) and (18.82,108.34) .. (18.66,104.78)
 .. controls (18.50,101.22) and (18.06,92.08) .. (17.28,89.94)
 .. controls (16.49,87.80) and (14.13,83.97) .. (14.12,81.56)
 .. controls (14.11,79.16) and (13.61,74.53) .. (12.27,74.20)
 .. controls (10.94,73.86) and (10.80,66.94) .. (10.57,65.20)
 .. controls (10.35,63.46) and (9.95,58.45) .. (10.04,55.86)
 .. controls (10.13,53.27) and (8.42,49.94) .. (9.52,48.92)
 .. controls (10.61,47.90) and (11.58,47.55) .. (11.58,47.55)
),
((17.99,142.71)
 .. controls (18.92,143.70) and (19.55,144.78) .. (19.91,145.37)
 .. controls (20.28,145.96) and (20.74,146.55) .. (21.31,146.76)
 .. controls (21.87,146.97) and (22.36,146.70) .. (22.85,146.53)
 .. controls (23.34,146.35) and (24.45,144.76) .. (24.45,144.76)
),
((15.73,154.81)
 .. controls (18.02,152.79) and (19.05,153.40) .. (20.38,151.24)
 .. controls (21.70,149.08) and (21.49,149.74) .. (22.22,147.95)
 .. controls (22.96,146.15) and (23.10,144.81) .. (23.10,144.81)
),
((-126.70,210.85)
 .. controls (-126.70,210.85) and (-124.00,210.65) .. (-122.30,211.19)
 .. controls (-120.59,211.74) and (-117.49,213.67) .. (-116.82,213.60)
 .. controls (-116.14,213.52) and (-115.65,213.16) .. (-116.56,211.78)
 .. controls (-117.47,210.41) and (-117.99,206.16) .. (-118.83,205.37)
 .. controls (-119.66,204.57) and (-120.63,202.14) .. (-120.33,201.67)
 .. controls (-120.02,201.20) and (-119.25,200.94) .. (-117.43,201.19)
 .. controls (-115.62,201.45) and (-114.26,201.21) .. (-112.64,201.27)
 .. controls (-111.01,201.32) and (-106.63,199.66) .. (-104.17,200.70)
 .. controls (-101.71,201.75) and (-99.49,201.35) .. (-96.62,204.52)
 .. controls (-93.76,207.69) and (-90.22,210.88) .. (-88.39,210.85)
 .. controls (-86.56,210.82) and (-84.74,210.98) .. (-82.32,210.39)
 .. controls (-79.89,209.81) and (-71.28,210.79) .. (-69.39,209.03)
 .. controls (-67.50,207.28) and (-66.62,206.93) .. (-67.86,203.81)
 .. controls (-69.09,200.69) and (-69.72,196.73) .. (-67.72,194.59)
 .. controls (-65.72,192.45) and (-66.10,192.25) .. (-63.82,193.10)
 .. controls (-61.55,193.95) and (-58.78,197.12) .. (-57.76,198.02)
 .. controls (-56.73,198.92) and (-50.59,204.33) .. (-49.23,209.28)
 .. controls (-47.87,214.23) and (-45.40,212.30) .. (-45.87,217.18)
 .. controls (-46.33,222.06) and (-47.31,225.39) .. (-44.85,226.34)
 .. controls (-42.39,227.29) and (-41.00,228.68) .. (-38.02,228.41)
 .. controls (-35.03,228.13) and (-36.04,226.94) .. (-33.35,226.94)
 .. controls (-30.67,226.94) and (-31.23,229.41) .. (-29.38,228.61)
 .. controls (-27.53,227.81) and (-26.28,225.27) .. (-24.30,226.20)
 .. controls (-22.32,227.13) and (-18.62,231.40) .. (-16.33,231.67)
 .. controls (-14.03,231.94) and (-14.38,230.97) .. (-11.86,230.39)
 .. controls (-9.34,229.81) and (0.17,227.17) .. (2.68,226.98)
 .. controls (5.18,226.78) and (10.00,223.88) .. (10.98,223.24)
 .. controls (11.96,222.60) and (16.74,220.57) .. (18.08,217.92)
 .. controls (19.42,215.28) and (19.90,212.61) .. (19.03,210.18)
 .. controls (18.15,207.74) and (18.05,205.24) .. (16.91,204.91)
 .. controls (15.77,204.58) and (15.72,206.02) .. (15.83,202.95)
 .. controls (15.94,199.88) and (16.02,194.70) .. (16.02,194.70)
 .. controls (16.02,194.70) and (16.92,196.65) .. (17.40,196.47)
 .. controls (17.89,196.30) and (18.43,194.69) .. (19.02,194.13)
 .. controls (19.62,193.57) and (20.60,193.13) .. (19.49,191.84)
 .. controls (18.38,190.55) and (17.81,187.65) .. (18.32,186.80)
 .. controls (18.83,185.96) and (20.24,181.49) .. (19.33,180.11)
 .. controls (18.42,178.73) and (14.55,176.86) .. (13.65,172.41)
 .. controls (12.76,167.96) and (14.02,162.34) .. (14.37,160.72)
 .. controls (14.71,159.10) and (17.65,155.77) .. (16.94,153.42)
),
((14.70,156.70)
 .. controls (19.42,156.39) and (20.42,155.37) .. (22.84,154.78)
 .. controls (25.26,154.20) and (24.81,153.51) .. (28.22,154.59)
 .. controls (31.64,155.68) and (32.00,156.26) .. (33.93,156.24)
 .. controls (35.85,156.21) and (37.40,155.69) .. (37.98,155.62)
 .. controls (38.56,155.54) and (43.41,156.86) .. (43.41,156.86)
),
((26.10,154.90)
 .. controls (25.52,152.48) and (24.03,151.27) .. (24.87,149.19)
 .. controls (25.71,147.11) and (27.41,142.47) .. (28.89,141.27)
 .. controls (30.38,140.08) and (31.34,137.42) .. (34.00,138.19)
 .. controls (36.66,138.95) and (39.19,140.68) .. (40.79,141.79)
 .. controls (42.38,142.90) and (43.12,143.51) .. (44.07,144.02)
 .. controls (45.01,144.53) and (47.17,148.55) .. (47.17,148.55)
),
((32.47,277.70)
 .. controls (32.41,273.86) and (31.89,272.21) .. (33.30,270.43)
 .. controls (34.71,268.66) and (35.94,266.49) .. (35.74,264.08)
 .. controls (35.54,261.68) and (35.07,258.59) .. (35.34,256.39)
 .. controls (35.61,254.19) and (35.47,247.46) .. (35.06,245.62)
 .. controls (34.64,243.78) and (32.81,233.15) .. (32.77,231.51)
 .. controls (32.74,229.88) and (32.51,222.86) .. (32.70,220.27)
 .. controls (32.88,217.68) and (34.12,212.73) .. (34.17,211.29)
 .. controls (34.22,209.85) and (34.18,205.62) .. (34.31,204.76)
 .. controls (34.43,203.90) and (35.46,204.71) .. (36.04,201.85)
 .. controls (36.63,198.99) and (34.94,194.99) .. (35.92,194.44)
 .. controls (36.90,193.90) and (37.97,190.96) .. (38.25,188.38)
 .. controls (38.54,185.79) and (39.39,178.14) .. (39.07,176.30)
 .. controls (38.75,174.46) and (37.90,171.36) .. (38.82,169.76)
 .. controls (39.74,168.16) and (39.65,167.96) .. (39.35,165.55)
 .. controls (39.06,163.14) and (38.91,161.98) .. (39.75,160.00)
 .. controls (40.59,158.01) and (42.01,155.85) .. (41.89,153.93)
 .. controls (41.76,152.01) and (42.71,152.42) .. (44.43,150.08)
 .. controls (46.14,147.74) and (43.61,143.33) .. (41.63,139.71)
 .. controls (39.64,136.08) and (38.86,130.96) .. (38.46,128.74)
 .. controls (38.06,126.51) and (36.21,121.84) .. (36.41,118.77)
 .. controls (36.61,115.70) and (37.13,112.07) .. (37.21,109.67)
 .. controls (37.30,107.28) and (35.97,104.25) .. (36.16,101.66)
 .. controls (36.35,99.08) and (34.90,99.41) .. (36.62,96.97)
 .. controls (38.34,94.54) and (39.88,89.02) .. (39.23,85.83)
 .. controls (38.58,82.64) and (38.19,77.43) .. (33.00,74.94)
 .. controls (27.80,72.45) and (28.31,71.79) .. (26.85,66.84)
 .. controls (25.40,61.88) and (26.01,57.97) .. (26.07,56.33)
 .. controls (26.13,54.70) and (25.53,47.28) .. (26.17,45.48)
 .. controls (26.81,43.68) and (27.76,41.12) .. (30.58,42.85)
 .. controls (33.40,44.59) and (38.25,46.01) .. (39.88,46.07)
 .. controls (41.52,46.13) and (42.11,45.47) .. (42.51,45.10)
 .. controls (42.91,44.73) and (43.11,44.55) .. (44.38,46.71)
 .. controls (45.64,48.87) and (44.79,45.86) .. (45.86,45.42)
 .. controls (46.94,44.97) and (47.88,45.49) .. (46.27,41.97)
 .. controls (44.67,38.46) and (41.26,34.40) .. (41.36,31.52)
 .. controls (41.47,28.64) and (40.13,23.12) .. (39.86,22.53)
),
((33.35,91.57)
 .. controls (32.94,92.42) and (33.28,93.59) .. (33.62,94.75)
 .. controls (33.96,95.92) and (34.05,96.31) .. (34.31,96.99)
 .. controls (34.57,97.67) and (36.82,99.29) .. (36.82,99.29)
),
((33.35,91.57)
 .. controls (32.79,91.27) and (31.48,90.26) .. (30.66,88.88)
 .. controls (29.85,87.51) and (28.94,86.04) .. (28.78,85.17)
 .. controls (28.62,84.30) and (28.28,83.13) .. (28.31,82.36)
 .. controls (28.33,81.60) and (29.14,80.47) .. (29.14,80.47)
 .. controls (29.14,80.47) and (30.75,81.20) .. (31.11,81.98)
 .. controls (31.46,82.77) and (31.90,83.84) .. (32.16,84.71)
 .. controls (32.42,85.59) and (33.03,87.14) .. (33.08,88.39)
 .. controls (33.13,89.65) and (33.92,91.88) .. cycle
),
((12.76,81.90)
 .. controls (15.80,83.06) and (14.24,83.59) .. (16.75,83.20)
 .. controls (19.26,82.81) and (19.38,82.23) .. (21.78,82.22)
 .. controls (24.18,82.21) and (25.23,82.35) .. (25.81,82.37)
 .. controls (26.38,82.39) and (28.31,82.36) .. (28.31,82.36)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [744]";
string area_border[];
area_border[1] := "l500-83008-66276";
area_border[2] := "l539-83604-67400";
area_border[3] := "l262-83352-66564";
area_border[4] := "l162-83716-67936";
drawoptions();
a_water(buildcycle(((29.23,-8.01)
 .. controls (29.23,-8.01) and (28.60,-9.09) .. (28.22,-9.30)
 .. controls (27.84,-9.50) and (27.10,-10.20) .. (26.35,-10.80)
 .. controls (25.61,-11.40) and (25.34,-11.89) .. (24.59,-12.50)
 .. controls (23.84,-13.10) and (23.67,-13.78) .. (22.65,-14.58)
 .. controls (21.62,-15.39) and (21.26,-16.17) .. (20.82,-17.14)
 .. controls (20.37,-18.12) and (20.33,-19.56) .. (20.26,-20.52)
 .. controls (20.20,-21.49) and (20.74,-23.19) .. (20.87,-24.05)
 .. controls (21.00,-24.91) and (21.14,-26.16) .. (21.15,-26.64)
 .. controls (21.17,-27.12) and (21.95,-27.91) .. (24.95,-28.04)
 .. controls (26.20,-28.09) and (26.10,-28.00) .. (27.47,-28.62)
 .. controls (28.83,-29.24) and (28.16,-29.17) .. (31.59,-31.26)
),
((27.45,-14.70)
 .. controls (27.45,-14.70) and (27.93,-11.99) .. (27.82,-11.42)
 .. controls (27.70,-10.85) and (28.30,-8.72) .. (29.23,-8.01)
 .. controls (30.17,-7.31) and (30.61,-6.23) .. (30.96,-5.17)
 .. controls (31.30,-4.10) and (31.07,-3.05) .. (31.04,-2.09)
 .. controls (31.01,-1.13) and (31.57,-0.82) .. (32.11,0.16)
 .. controls (32.65,1.14) and (33.40,1.74) .. (33.85,2.62)
 .. controls (34.30,3.50) and (35.33,4.21) .. (35.33,4.21)
),
((34.37,-25.59)
 .. controls (33.76,-24.65) and (32.27,-23.17) .. (32.21,-21.63)
 .. controls (32.16,-20.10) and (31.38,-19.84) .. (30.77,-19.00)
 .. controls (30.17,-18.15) and (29.59,-18.08) .. (29.09,-17.62)
 .. controls (28.60,-17.15) and (27.97,-15.74) .. (27.45,-14.70)
),
((117.93,-212.20)
 .. controls (117.26,-212.23) and (118.57,-205.28) .. (118.43,-203.76)
 .. controls (118.28,-202.23) and (120.98,-191.29) .. (121.25,-188.30)
 .. controls (121.53,-185.31) and (123.81,-173.61) .. (124.69,-171.37)
 .. controls (125.57,-169.13) and (124.21,-155.05) .. (124.04,-152.85)
 .. controls (123.86,-150.64) and (121.89,-146.49) .. (121.33,-144.30)
 .. controls (120.77,-142.11) and (120.44,-135.49) .. (119.68,-133.11)
 .. controls (118.92,-130.74) and (120.19,-117.91) .. (121.09,-113.56)
 .. controls (121.99,-109.20) and (119.40,-98.34) .. (118.73,-95.77)
 .. controls (118.06,-93.20) and (116.49,-87.11) .. (112.85,-79.27)
 .. controls (109.21,-71.42) and (94.29,-67.92) .. (92.58,-68.46)
 .. controls (90.87,-69.01) and (72.09,-62.38) .. (69.67,-61.89)
 .. controls (67.25,-61.40) and (56.58,-55.83) .. (53.36,-54.21)
 .. controls (50.13,-52.60) and (49.70,-54.15) .. (48.84,-54.08)
 .. controls (47.97,-54.02) and (39.31,-58.84) .. (35.51,-60.13)
 .. controls (31.72,-61.42) and (31.27,-59.70) .. (30.25,-57.91)
 .. controls (29.22,-56.12) and (26.41,-50.07) .. (27.19,-47.93)
 .. controls (27.98,-45.79) and (28.89,-41.73) .. (28.71,-36.45)
 .. controls (28.52,-31.18) and (34.49,-20.98) .. (35.73,-18.05)
 .. controls (36.98,-15.13) and (38.31,-12.10) .. (38.25,-10.38)
 .. controls (38.19,-8.65) and (38.21,-6.63) .. (38.86,-5.94)
 .. controls (39.51,-5.24) and (40.22,-3.58) .. (39.94,-1.19)
 .. controls (39.66,1.20) and (40.50,2.09) .. (40.84,3.16)
 .. controls (41.19,4.23) and (41.72,8.29) .. (40.97,10.28)
 .. controls (40.23,12.27) and (37.93,12.09) .. (36.76,12.43)
 .. controls (35.60,12.77) and (36.42,14.15) .. (36.37,15.39)
 .. controls (36.33,16.64) and (37.32,18.31) .. (37.32,18.31)
 .. controls (37.32,18.31) and (38.13,19.88) .. (38.97,20.48)
 .. controls (39.82,21.09) and (39.86,22.53) .. (39.86,22.53)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [697]";
string area_border[];
area_border[1] := "l506-84980-63964";
area_border[2] := "l163-82880-68940";
area_border[3] := "l541-83408-67348";
area_border[4] := "l539-83604-67400";
area_border[5] := "l500-83008-66276";
area_border[6] := "l162-83716-67936";
area_border[7] := "l504-83088-64864";
area_border[8] := "l162-83716-67936";
drawoptions();
a_flowstone(buildcycle(((28.55,-96.41)
 .. controls (36.27,-94.79) and (38.26,-96.54) .. (40.70,-97.61)
 .. controls (43.14,-98.67) and (45.43,-100.90) .. (46.57,-103.16)
 .. controls (47.70,-105.43) and (50.42,-108.79) .. (51.41,-109.61)
 .. controls (52.40,-110.44) and (54.63,-113.63) .. (55.41,-114.18)
 .. controls (56.20,-114.73) and (62.66,-118.14) .. (64.23,-118.95)
 .. controls (65.79,-119.76) and (74.24,-119.65) .. (75.96,-119.20)
 .. controls (77.67,-118.76) and (82.65,-118.39) .. (82.08,-115.82)
 .. controls (81.51,-113.24) and (80.82,-107.41) .. (79.40,-105.44)
 .. controls (77.99,-103.48) and (75.52,-101.64) .. (74.41,-100.24)
 .. controls (73.31,-98.84) and (70.47,-94.91) .. (70.30,-92.80)
 .. controls (70.13,-90.69) and (69.41,-89.37) .. (69.46,-85.53)
 .. controls (69.52,-81.69) and (69.32,-78.71) .. (70.95,-76.16)
 .. controls (72.59,-73.60) and (73.01,-71.95) .. (74.47,-69.88)
 .. controls (75.94,-67.81) and (77.87,-65.44) .. (77.89,-63.32)
),
((12.55,47.49)
 .. controls (14.89,46.52) and (15.34,47.30) .. (14.67,44.59)
 .. controls (14.00,41.87) and (15.31,40.10) .. (15.97,37.81)
 .. controls (16.63,35.53) and (19.87,28.25) .. (20.24,25.86)
 .. controls (20.61,23.47) and (21.69,20.25) .. (21.08,18.69)
 .. controls (20.46,17.13) and (22.87,16.93) .. (23.71,14.94)
 .. controls (24.55,12.95) and (26.99,11.79) .. (27.04,10.45)
 .. controls (27.09,9.11) and (23.41,1.67) .. (22.85,1.27)
 .. controls (22.29,0.86) and (19.74,-8.35) .. (19.25,-10.86)
 .. controls (18.76,-13.38) and (14.15,-29.57) .. (13.99,-30.54)
 .. controls (13.84,-31.50) and (13.57,-37.56) .. (14.19,-41.58)
 .. controls (14.81,-45.59) and (13.90,-49.75) .. (12.46,-52.40)
 .. controls (11.02,-55.05) and (6.94,-61.83) .. (6.04,-63.49)
 .. controls (5.14,-65.16) and (4.37,-67.78) .. (5.02,-69.88)
 .. controls (5.67,-71.97) and (10.55,-74.00) .. (11.34,-74.55)
 .. controls (12.13,-75.10) and (18.21,-78.43) .. (19.49,-79.45)
 .. controls (20.78,-80.46) and (26.66,-83.90) .. (28.27,-88.54)
 .. controls (29.88,-93.19) and (31.31,-95.64) .. (30.45,-103.84)
 .. controls (29.59,-112.03) and (31.84,-115.79) .. (31.17,-118.51)
 .. controls (30.50,-121.22) and (29.35,-132.02) .. (29.14,-134.24)
 .. controls (28.93,-136.45) and (25.11,-145.62) .. (21.65,-148.54)
 .. controls (18.20,-151.45) and (15.23,-157.81) .. (15.17,-158.87)
),
((32.11,0.16)
 .. controls (32.11,0.16) and (30.95,0.50) .. (30.06,1.05)
 .. controls (29.18,1.59) and (28.10,2.32) .. (27.61,2.50)
 .. controls (27.12,2.67) and (26.54,2.94) .. (25.95,3.21)
 .. controls (25.37,3.47) and (23.15,3.78) .. (23.15,3.78)
),
((27.45,-14.70)
 .. controls (27.45,-14.70) and (27.93,-11.99) .. (27.82,-11.42)
 .. controls (27.70,-10.85) and (28.30,-8.72) .. (29.23,-8.01)
 .. controls (30.17,-7.31) and (30.61,-6.23) .. (30.96,-5.17)
 .. controls (31.30,-4.10) and (31.07,-3.05) .. (31.04,-2.09)
 .. controls (31.01,-1.13) and (31.57,-0.82) .. (32.11,0.16)
 .. controls (32.65,1.14) and (33.40,1.74) .. (33.85,2.62)
 .. controls (34.30,3.50) and (35.33,4.21) .. (35.33,4.21)
),
((29.23,-8.01)
 .. controls (29.23,-8.01) and (28.60,-9.09) .. (28.22,-9.30)
 .. controls (27.84,-9.50) and (27.10,-10.20) .. (26.35,-10.80)
 .. controls (25.61,-11.40) and (25.34,-11.89) .. (24.59,-12.50)
 .. controls (23.84,-13.10) and (23.67,-13.78) .. (22.65,-14.58)
 .. controls (21.62,-15.39) and (21.26,-16.17) .. (20.82,-17.14)
 .. controls (20.37,-18.12) and (20.33,-19.56) .. (20.26,-20.52)
 .. controls (20.20,-21.49) and (20.74,-23.19) .. (20.87,-24.05)
 .. controls (21.00,-24.91) and (21.14,-26.16) .. (21.15,-26.64)
 .. controls (21.17,-27.12) and (21.95,-27.91) .. (24.95,-28.04)
 .. controls (26.20,-28.09) and (26.10,-28.00) .. (27.47,-28.62)
 .. controls (28.83,-29.24) and (28.16,-29.17) .. (31.59,-31.26)
),
((117.93,-212.20)
 .. controls (117.26,-212.23) and (118.57,-205.28) .. (118.43,-203.76)
 .. controls (118.28,-202.23) and (120.98,-191.29) .. (121.25,-188.30)
 .. controls (121.53,-185.31) and (123.81,-173.61) .. (124.69,-171.37)
 .. controls (125.57,-169.13) and (124.21,-155.05) .. (124.04,-152.85)
 .. controls (123.86,-150.64) and (121.89,-146.49) .. (121.33,-144.30)
 .. controls (120.77,-142.11) and (120.44,-135.49) .. (119.68,-133.11)
 .. controls (118.92,-130.74) and (120.19,-117.91) .. (121.09,-113.56)
 .. controls (121.99,-109.20) and (119.40,-98.34) .. (118.73,-95.77)
 .. controls (118.06,-93.20) and (116.49,-87.11) .. (112.85,-79.27)
 .. controls (109.21,-71.42) and (94.29,-67.92) .. (92.58,-68.46)
 .. controls (90.87,-69.01) and (72.09,-62.38) .. (69.67,-61.89)
 .. controls (67.25,-61.40) and (56.58,-55.83) .. (53.36,-54.21)
 .. controls (50.13,-52.60) and (49.70,-54.15) .. (48.84,-54.08)
 .. controls (47.97,-54.02) and (39.31,-58.84) .. (35.51,-60.13)
 .. controls (31.72,-61.42) and (31.27,-59.70) .. (30.25,-57.91)
 .. controls (29.22,-56.12) and (26.41,-50.07) .. (27.19,-47.93)
 .. controls (27.98,-45.79) and (28.89,-41.73) .. (28.71,-36.45)
 .. controls (28.52,-31.18) and (34.49,-20.98) .. (35.73,-18.05)
 .. controls (36.98,-15.13) and (38.31,-12.10) .. (38.25,-10.38)
 .. controls (38.19,-8.65) and (38.21,-6.63) .. (38.86,-5.94)
 .. controls (39.51,-5.24) and (40.22,-3.58) .. (39.94,-1.19)
 .. controls (39.66,1.20) and (40.50,2.09) .. (40.84,3.16)
 .. controls (41.19,4.23) and (41.72,8.29) .. (40.97,10.28)
 .. controls (40.23,12.27) and (37.93,12.09) .. (36.76,12.43)
 .. controls (35.60,12.77) and (36.42,14.15) .. (36.37,15.39)
 .. controls (36.33,16.64) and (37.32,18.31) .. (37.32,18.31)
 .. controls (37.32,18.31) and (38.13,19.88) .. (38.97,20.48)
 .. controls (39.82,21.09) and (39.86,22.53) .. (39.86,22.53)
),
((29.54,-51.79)
 .. controls (29.54,-51.79) and (27.67,-53.20) .. (27.11,-53.60)
 .. controls (26.55,-54.01) and (26.11,-55.08) .. (25.19,-56.17)
 .. controls (24.26,-57.26) and (24.18,-57.65) .. (24.11,-58.42)
 .. controls (24.05,-59.19) and (24.37,-60.04) .. (24.77,-60.61)
 .. controls (25.18,-61.17) and (25.52,-62.60) .. (25.76,-63.94)
 .. controls (26.00,-65.28) and (26.89,-66.01) .. (27.89,-67.04)
 .. controls (28.88,-68.06) and (28.98,-68.06) .. (29.97,-68.79)
 .. controls (30.95,-69.52) and (31.64,-70.08) .. (32.41,-70.05)
 .. controls (33.18,-70.02) and (33.45,-69.63) .. (34.31,-69.31)
 .. controls (35.16,-68.99) and (34.27,-68.25) .. (34.61,-67.09)
 .. controls (34.95,-65.92) and (34.62,-64.68) .. (34.47,-63.05)
 .. controls (34.31,-61.42) and (34.78,-61.21) .. (34.23,-59.31)
),
((117.93,-212.20)
 .. controls (117.26,-212.23) and (118.57,-205.28) .. (118.43,-203.76)
 .. controls (118.28,-202.23) and (120.98,-191.29) .. (121.25,-188.30)
 .. controls (121.53,-185.31) and (123.81,-173.61) .. (124.69,-171.37)
 .. controls (125.57,-169.13) and (124.21,-155.05) .. (124.04,-152.85)
 .. controls (123.86,-150.64) and (121.89,-146.49) .. (121.33,-144.30)
 .. controls (120.77,-142.11) and (120.44,-135.49) .. (119.68,-133.11)
 .. controls (118.92,-130.74) and (120.19,-117.91) .. (121.09,-113.56)
 .. controls (121.99,-109.20) and (119.40,-98.34) .. (118.73,-95.77)
 .. controls (118.06,-93.20) and (116.49,-87.11) .. (112.85,-79.27)
 .. controls (109.21,-71.42) and (94.29,-67.92) .. (92.58,-68.46)
 .. controls (90.87,-69.01) and (72.09,-62.38) .. (69.67,-61.89)
 .. controls (67.25,-61.40) and (56.58,-55.83) .. (53.36,-54.21)
 .. controls (50.13,-52.60) and (49.70,-54.15) .. (48.84,-54.08)
 .. controls (47.97,-54.02) and (39.31,-58.84) .. (35.51,-60.13)
 .. controls (31.72,-61.42) and (31.27,-59.70) .. (30.25,-57.91)
 .. controls (29.22,-56.12) and (26.41,-50.07) .. (27.19,-47.93)
 .. controls (27.98,-45.79) and (28.89,-41.73) .. (28.71,-36.45)
 .. controls (28.52,-31.18) and (34.49,-20.98) .. (35.73,-18.05)
 .. controls (36.98,-15.13) and (38.31,-12.10) .. (38.25,-10.38)
 .. controls (38.19,-8.65) and (38.21,-6.63) .. (38.86,-5.94)
 .. controls (39.51,-5.24) and (40.22,-3.58) .. (39.94,-1.19)
 .. controls (39.66,1.20) and (40.50,2.09) .. (40.84,3.16)
 .. controls (41.19,4.23) and (41.72,8.29) .. (40.97,10.28)
 .. controls (40.23,12.27) and (37.93,12.09) .. (36.76,12.43)
 .. controls (35.60,12.77) and (36.42,14.15) .. (36.37,15.39)
 .. controls (36.33,16.64) and (37.32,18.31) .. (37.32,18.31)
 .. controls (37.32,18.31) and (38.13,19.88) .. (38.97,20.48)
 .. controls (39.82,21.09) and (39.86,22.53) .. (39.86,22.53)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [580]";
string area_border[];
area_border[1] := "l508-83380-54796";
area_border[2] := "l247-83728-54364";
area_border[3] := "l538-82456-56576";
area_border[4] := "l247-83728-54364";
area_border[5] := "l165-81792-58292";
area_border[6] := "l247-83728-54364";
area_border[7] := "l539-82472-60132";
area_border[8] := "l247-83728-54364";
area_border[9] := "l163-82880-68940";
drawoptions();
a_blocks(buildcycle(((33.27,-308.37)
 .. controls (33.27,-308.37) and (38.92,-301.31) .. (40.07,-299.15)
 .. controls (41.22,-296.98) and (41.31,-294.77) .. (41.58,-292.26)
 .. controls (41.85,-289.75) and (40.18,-286.84) .. (39.02,-284.39)
 .. controls (37.85,-281.94) and (37.01,-280.44) .. (34.92,-278.80)
 .. controls (32.83,-277.17) and (32.50,-274.21) .. (32.23,-272.60)
 .. controls (31.96,-270.98) and (29.25,-268.52) .. (28.20,-266.55)
 .. controls (27.14,-264.59) and (25.95,-261.68) .. (25.14,-260.85)
 .. controls (24.33,-260.03) and (22.88,-253.86) .. (22.71,-252.33)
 .. controls (22.54,-250.80) and (23.55,-247.78) .. (24.21,-245.44)
 .. controls (24.88,-243.10) and (27.92,-240.26) .. (28.92,-238.97)
 .. controls (29.92,-237.67) and (32.32,-233.00) .. (33.95,-228.37)
 .. controls (35.59,-223.70) and (35.73,-224.58) .. (37.16,-222.56)
 .. controls (38.60,-220.55) and (39.93,-218.74) .. (42.25,-217.48)
 .. controls (44.56,-216.22) and (46.05,-214.24) .. (46.89,-213.25)
 .. controls (47.73,-212.25) and (49.20,-207.29) .. (49.53,-205.74)
 .. controls (49.87,-204.19) and (49.84,-198.04) .. (49.96,-195.93)
 .. controls (50.08,-193.81) and (50.24,-190.15) .. (50.53,-187.55)
 .. controls (50.83,-184.94) and (51.80,-182.70) .. (52.34,-181.43)
 .. controls (52.87,-180.16) and (54.36,-176.26) .. (54.62,-175.49)
 .. controls (54.89,-174.71) and (58.13,-168.74) .. (59.65,-165.42)
 .. controls (61.16,-162.10) and (61.20,-160.46) .. (61.61,-158.62)
 .. controls (62.02,-156.78) and (61.16,-154.13) .. (61.36,-151.81)
 .. controls (61.57,-149.50) and (61.30,-147.20) .. (60.16,-144.94)
 .. controls (59.02,-142.67) and (57.74,-141.86) .. (56.93,-140.44)
 .. controls (56.11,-139.03) and (55.12,-138.20) .. (53.55,-137.20)
 .. controls (51.97,-136.20) and (48.97,-135.35) .. (47.41,-134.92)
 .. controls (45.86,-134.50) and (42.07,-133.19) .. (40.04,-132.88)
 .. controls (38.01,-132.57) and (37.69,-131.72) .. (34.41,-131.16)
 .. controls (31.12,-130.61) and (30.51,-129.58) .. (27.11,-128.64)
),
((15.17,-158.87)
 .. controls (15.17,-158.87) and (11.94,-160.04) .. (10.20,-162.90)
 .. controls (8.45,-165.78) and (8.20,-166.34) .. (6.75,-169.29)
 .. controls (5.28,-172.28) and (3.92,-174.31) .. (3.78,-176.14)
 .. controls (3.64,-177.98) and (2.56,-182.24) .. (3.08,-185.05)
 .. controls (3.88,-189.36) and (5.63,-189.78) .. (5.06,-193.67)
 .. controls (4.61,-196.76) and (1.56,-203.01) .. (1.01,-204.01)
 .. controls (0.46,-205.00) and (-0.38,-205.81) .. (-3.02,-207.57)
 .. controls (-5.65,-209.32) and (-8.15,-212.53) .. (-8.53,-215.65)
 .. controls (-8.90,-218.77) and (-8.74,-220.70) .. (-7.40,-223.56)
 .. controls (-6.05,-226.41) and (-4.48,-230.03) .. (-3.30,-230.86)
 .. controls (-2.12,-231.68) and (-0.07,-232.95) .. (1.20,-233.58)
 .. controls (2.47,-234.21) and (2.94,-234.09) .. (2.99,-235.15)
 .. controls (3.03,-236.21) and (4.15,-237.91) .. (4.08,-238.59)
 .. controls (4.02,-239.26) and (2.85,-251.92) .. (4.48,-256.08)
 .. controls (6.11,-260.23) and (7.94,-266.57) .. (8.86,-267.68)
 .. controls (9.77,-268.79) and (11.81,-273.29) .. (11.96,-274.62)
 .. controls (12.12,-275.96) and (15.19,-282.24) .. (16.99,-283.89)
 .. controls (18.79,-285.54) and (21.03,-290.53) .. (24.96,-292.48)
 .. controls (28.89,-294.43) and (29.02,-295.10) .. (29.33,-295.56)
 .. controls (29.64,-296.03) and (34.59,-307.84) .. (36.91,-310.05)
 .. controls (39.22,-312.25) and (38.13,-313.74) .. (38.53,-314.01)
 .. controls (38.93,-314.28) and (42.98,-312.47) .. (44.95,-311.23)
 .. controls (46.91,-309.99) and (48.69,-308.86) .. (50.86,-310.10)
 .. controls (53.04,-311.35) and (55.01,-312.41) .. (55.38,-314.32)
 .. controls (55.76,-316.22) and (57.15,-319.42) .. (57.15,-319.42)
 .. controls (57.15,-319.42) and (58.60,-317.44) .. (61.58,-317.49)
 .. controls (64.57,-317.55) and (67.40,-316.46) .. (67.61,-316.83)
 .. controls (67.82,-317.21) and (68.96,-321.19) .. (68.96,-321.19)
 .. controls (68.96,-321.19) and (72.65,-321.98) .. (74.10,-320.18)
 .. controls (75.56,-318.39) and (76.58,-315.46) .. (76.78,-313.43)
 .. controls (76.98,-311.40) and (76.05,-305.87) .. (77.17,-305.05)
 .. controls (78.28,-304.23) and (84.09,-298.86) .. (84.81,-297.87)
 .. controls (85.53,-296.87) and (88.98,-292.48) .. (89.92,-292.15)
 .. controls (90.87,-291.82) and (95.09,-289.70) .. (95.44,-288.82)
 .. controls (95.78,-287.94) and (100.22,-282.06) .. (100.92,-280.68)
 .. controls (101.63,-279.30) and (105.48,-273.26) .. (106.14,-273.04)
 .. controls (106.80,-272.82) and (105.83,-278.72) .. (105.48,-279.60)
 .. controls (105.14,-280.49) and (105.29,-283.75) .. (107.23,-282.12)
 .. controls (109.18,-280.49) and (110.16,-278.81) .. (111.43,-277.21)
 .. controls (112.70,-275.62) and (118.91,-272.73) .. (120.45,-272.85)
 .. controls (121.99,-272.98) and (129.02,-275.35) .. (130.93,-272.86)
 .. controls (132.83,-270.38) and (136.38,-266.10) .. (136.49,-264.27)
 .. controls (136.60,-262.45) and (137.58,-256.38) .. (137.58,-256.38)
),
((24.89,-295.27)
 .. controls (24.89,-295.27) and (25.98,-293.78) .. (26.58,-292.22)
 .. controls (27.19,-290.66) and (26.99,-290.47) .. (26.81,-288.65)
 .. controls (26.63,-286.84) and (26.79,-286.06) .. (26.75,-285.10)
 .. controls (26.71,-284.15) and (26.30,-283.68) .. (26.71,-282.03)
 .. controls (27.11,-280.39) and (26.73,-278.29) .. (26.46,-276.49)
 .. controls (26.18,-274.68) and (24.98,-273.68) .. (24.83,-272.34)
 .. controls (24.67,-271.01) and (23.87,-270.47) .. (22.64,-268.71)
 .. controls (21.40,-266.95) and (19.93,-264.34) .. (19.09,-262.84)
 .. controls (18.25,-261.35) and (17.75,-260.89) .. (16.82,-259.59)
 .. controls (15.90,-258.29) and (15.51,-258.21) .. (14.78,-256.90)
 .. controls (14.04,-255.59) and (13.52,-254.75) .. (12.92,-254.10)
 .. controls (12.31,-253.45) and (11.84,-251.46) .. (11.30,-250.13)
 .. controls (10.76,-248.81) and (9.32,-246.75) .. (8.62,-246.01)
 .. controls (7.91,-245.27) and (7.60,-244.71) .. (6.89,-243.77)
 .. controls (6.18,-242.84) and (6.01,-243.23) .. (1.09,-242.56)
),
((15.17,-158.87)
 .. controls (15.17,-158.87) and (11.94,-160.04) .. (10.20,-162.90)
 .. controls (8.45,-165.78) and (8.20,-166.34) .. (6.75,-169.29)
 .. controls (5.28,-172.28) and (3.92,-174.31) .. (3.78,-176.14)
 .. controls (3.64,-177.98) and (2.56,-182.24) .. (3.08,-185.05)
 .. controls (3.88,-189.36) and (5.63,-189.78) .. (5.06,-193.67)
 .. controls (4.61,-196.76) and (1.56,-203.01) .. (1.01,-204.01)
 .. controls (0.46,-205.00) and (-0.38,-205.81) .. (-3.02,-207.57)
 .. controls (-5.65,-209.32) and (-8.15,-212.53) .. (-8.53,-215.65)
 .. controls (-8.90,-218.77) and (-8.74,-220.70) .. (-7.40,-223.56)
 .. controls (-6.05,-226.41) and (-4.48,-230.03) .. (-3.30,-230.86)
 .. controls (-2.12,-231.68) and (-0.07,-232.95) .. (1.20,-233.58)
 .. controls (2.47,-234.21) and (2.94,-234.09) .. (2.99,-235.15)
 .. controls (3.03,-236.21) and (4.15,-237.91) .. (4.08,-238.59)
 .. controls (4.02,-239.26) and (2.85,-251.92) .. (4.48,-256.08)
 .. controls (6.11,-260.23) and (7.94,-266.57) .. (8.86,-267.68)
 .. controls (9.77,-268.79) and (11.81,-273.29) .. (11.96,-274.62)
 .. controls (12.12,-275.96) and (15.19,-282.24) .. (16.99,-283.89)
 .. controls (18.79,-285.54) and (21.03,-290.53) .. (24.96,-292.48)
 .. controls (28.89,-294.43) and (29.02,-295.10) .. (29.33,-295.56)
 .. controls (29.64,-296.03) and (34.59,-307.84) .. (36.91,-310.05)
 .. controls (39.22,-312.25) and (38.13,-313.74) .. (38.53,-314.01)
 .. controls (38.93,-314.28) and (42.98,-312.47) .. (44.95,-311.23)
 .. controls (46.91,-309.99) and (48.69,-308.86) .. (50.86,-310.10)
 .. controls (53.04,-311.35) and (55.01,-312.41) .. (55.38,-314.32)
 .. controls (55.76,-316.22) and (57.15,-319.42) .. (57.15,-319.42)
 .. controls (57.15,-319.42) and (58.60,-317.44) .. (61.58,-317.49)
 .. controls (64.57,-317.55) and (67.40,-316.46) .. (67.61,-316.83)
 .. controls (67.82,-317.21) and (68.96,-321.19) .. (68.96,-321.19)
 .. controls (68.96,-321.19) and (72.65,-321.98) .. (74.10,-320.18)
 .. controls (75.56,-318.39) and (76.58,-315.46) .. (76.78,-313.43)
 .. controls (76.98,-311.40) and (76.05,-305.87) .. (77.17,-305.05)
 .. controls (78.28,-304.23) and (84.09,-298.86) .. (84.81,-297.87)
 .. controls (85.53,-296.87) and (88.98,-292.48) .. (89.92,-292.15)
 .. controls (90.87,-291.82) and (95.09,-289.70) .. (95.44,-288.82)
 .. controls (95.78,-287.94) and (100.22,-282.06) .. (100.92,-280.68)
 .. controls (101.63,-279.30) and (105.48,-273.26) .. (106.14,-273.04)
 .. controls (106.80,-272.82) and (105.83,-278.72) .. (105.48,-279.60)
 .. controls (105.14,-280.49) and (105.29,-283.75) .. (107.23,-282.12)
 .. controls (109.18,-280.49) and (110.16,-278.81) .. (111.43,-277.21)
 .. controls (112.70,-275.62) and (118.91,-272.73) .. (120.45,-272.85)
 .. controls (121.99,-272.98) and (129.02,-275.35) .. (130.93,-272.86)
 .. controls (132.83,-270.38) and (136.38,-266.10) .. (136.49,-264.27)
 .. controls (136.60,-262.45) and (137.58,-256.38) .. (137.58,-256.38)
),
((1.77,-234.67)
 .. controls (1.73,-233.75) and (0.51,-228.04) .. (0.04,-226.85)
 .. controls (-0.43,-225.66) and (-1.10,-221.61) .. (-1.83,-219.85)
 .. controls (-2.56,-218.08) and (-1.27,-214.83) .. (-0.93,-213.45)
 .. controls (-0.58,-212.08) and (0.13,-208.51) .. (0.19,-207.15)
 .. controls (0.25,-205.78) and (-0.16,-203.47) .. (-0.16,-203.47)
),
((15.17,-158.87)
 .. controls (15.17,-158.87) and (11.94,-160.04) .. (10.20,-162.90)
 .. controls (8.45,-165.78) and (8.20,-166.34) .. (6.75,-169.29)
 .. controls (5.28,-172.28) and (3.92,-174.31) .. (3.78,-176.14)
 .. controls (3.64,-177.98) and (2.56,-182.24) .. (3.08,-185.05)
 .. controls (3.88,-189.36) and (5.63,-189.78) .. (5.06,-193.67)
 .. controls (4.61,-196.76) and (1.56,-203.01) .. (1.01,-204.01)
 .. controls (0.46,-205.00) and (-0.38,-205.81) .. (-3.02,-207.57)
 .. controls (-5.65,-209.32) and (-8.15,-212.53) .. (-8.53,-215.65)
 .. controls (-8.90,-218.77) and (-8.74,-220.70) .. (-7.40,-223.56)
 .. controls (-6.05,-226.41) and (-4.48,-230.03) .. (-3.30,-230.86)
 .. controls (-2.12,-231.68) and (-0.07,-232.95) .. (1.20,-233.58)
 .. controls (2.47,-234.21) and (2.94,-234.09) .. (2.99,-235.15)
 .. controls (3.03,-236.21) and (4.15,-237.91) .. (4.08,-238.59)
 .. controls (4.02,-239.26) and (2.85,-251.92) .. (4.48,-256.08)
 .. controls (6.11,-260.23) and (7.94,-266.57) .. (8.86,-267.68)
 .. controls (9.77,-268.79) and (11.81,-273.29) .. (11.96,-274.62)
 .. controls (12.12,-275.96) and (15.19,-282.24) .. (16.99,-283.89)
 .. controls (18.79,-285.54) and (21.03,-290.53) .. (24.96,-292.48)
 .. controls (28.89,-294.43) and (29.02,-295.10) .. (29.33,-295.56)
 .. controls (29.64,-296.03) and (34.59,-307.84) .. (36.91,-310.05)
 .. controls (39.22,-312.25) and (38.13,-313.74) .. (38.53,-314.01)
 .. controls (38.93,-314.28) and (42.98,-312.47) .. (44.95,-311.23)
 .. controls (46.91,-309.99) and (48.69,-308.86) .. (50.86,-310.10)
 .. controls (53.04,-311.35) and (55.01,-312.41) .. (55.38,-314.32)
 .. controls (55.76,-316.22) and (57.15,-319.42) .. (57.15,-319.42)
 .. controls (57.15,-319.42) and (58.60,-317.44) .. (61.58,-317.49)
 .. controls (64.57,-317.55) and (67.40,-316.46) .. (67.61,-316.83)
 .. controls (67.82,-317.21) and (68.96,-321.19) .. (68.96,-321.19)
 .. controls (68.96,-321.19) and (72.65,-321.98) .. (74.10,-320.18)
 .. controls (75.56,-318.39) and (76.58,-315.46) .. (76.78,-313.43)
 .. controls (76.98,-311.40) and (76.05,-305.87) .. (77.17,-305.05)
 .. controls (78.28,-304.23) and (84.09,-298.86) .. (84.81,-297.87)
 .. controls (85.53,-296.87) and (88.98,-292.48) .. (89.92,-292.15)
 .. controls (90.87,-291.82) and (95.09,-289.70) .. (95.44,-288.82)
 .. controls (95.78,-287.94) and (100.22,-282.06) .. (100.92,-280.68)
 .. controls (101.63,-279.30) and (105.48,-273.26) .. (106.14,-273.04)
 .. controls (106.80,-272.82) and (105.83,-278.72) .. (105.48,-279.60)
 .. controls (105.14,-280.49) and (105.29,-283.75) .. (107.23,-282.12)
 .. controls (109.18,-280.49) and (110.16,-278.81) .. (111.43,-277.21)
 .. controls (112.70,-275.62) and (118.91,-272.73) .. (120.45,-272.85)
 .. controls (121.99,-272.98) and (129.02,-275.35) .. (130.93,-272.86)
 .. controls (132.83,-270.38) and (136.38,-266.10) .. (136.49,-264.27)
 .. controls (136.60,-262.45) and (137.58,-256.38) .. (137.58,-256.38)
),
((2.57,-190.58)
 .. controls (3.42,-190.06) and (3.23,-190.16) .. (4.08,-189.65)
 .. controls (4.93,-189.13) and (5.42,-189.40) .. (6.86,-189.05)
 .. controls (8.30,-188.70) and (9.14,-187.90) .. (10.54,-186.39)
 .. controls (11.95,-184.89) and (11.19,-185.50) .. (12.67,-183.32)
 .. controls (14.15,-181.14) and (13.76,-180.96) .. (13.70,-178.94)
 .. controls (13.63,-176.92) and (13.43,-176.73) .. (13.02,-175.69)
 .. controls (12.60,-174.65) and (12.84,-173.10) .. (13.47,-171.63)
 .. controls (14.09,-170.16) and (14.53,-168.61) .. (14.32,-168.04)
 .. controls (14.10,-167.47) and (14.78,-164.65) .. (14.20,-161.40)
 .. controls (13.61,-158.16) and (13.30,-160.47) .. (11.86,-157.55)
),
((15.17,-158.87)
 .. controls (15.17,-158.87) and (11.94,-160.04) .. (10.20,-162.90)
 .. controls (8.45,-165.78) and (8.20,-166.34) .. (6.75,-169.29)
 .. controls (5.28,-172.28) and (3.92,-174.31) .. (3.78,-176.14)
 .. controls (3.64,-177.98) and (2.56,-182.24) .. (3.08,-185.05)
 .. controls (3.88,-189.36) and (5.63,-189.78) .. (5.06,-193.67)
 .. controls (4.61,-196.76) and (1.56,-203.01) .. (1.01,-204.01)
 .. controls (0.46,-205.00) and (-0.38,-205.81) .. (-3.02,-207.57)
 .. controls (-5.65,-209.32) and (-8.15,-212.53) .. (-8.53,-215.65)
 .. controls (-8.90,-218.77) and (-8.74,-220.70) .. (-7.40,-223.56)
 .. controls (-6.05,-226.41) and (-4.48,-230.03) .. (-3.30,-230.86)
 .. controls (-2.12,-231.68) and (-0.07,-232.95) .. (1.20,-233.58)
 .. controls (2.47,-234.21) and (2.94,-234.09) .. (2.99,-235.15)
 .. controls (3.03,-236.21) and (4.15,-237.91) .. (4.08,-238.59)
 .. controls (4.02,-239.26) and (2.85,-251.92) .. (4.48,-256.08)
 .. controls (6.11,-260.23) and (7.94,-266.57) .. (8.86,-267.68)
 .. controls (9.77,-268.79) and (11.81,-273.29) .. (11.96,-274.62)
 .. controls (12.12,-275.96) and (15.19,-282.24) .. (16.99,-283.89)
 .. controls (18.79,-285.54) and (21.03,-290.53) .. (24.96,-292.48)
 .. controls (28.89,-294.43) and (29.02,-295.10) .. (29.33,-295.56)
 .. controls (29.64,-296.03) and (34.59,-307.84) .. (36.91,-310.05)
 .. controls (39.22,-312.25) and (38.13,-313.74) .. (38.53,-314.01)
 .. controls (38.93,-314.28) and (42.98,-312.47) .. (44.95,-311.23)
 .. controls (46.91,-309.99) and (48.69,-308.86) .. (50.86,-310.10)
 .. controls (53.04,-311.35) and (55.01,-312.41) .. (55.38,-314.32)
 .. controls (55.76,-316.22) and (57.15,-319.42) .. (57.15,-319.42)
 .. controls (57.15,-319.42) and (58.60,-317.44) .. (61.58,-317.49)
 .. controls (64.57,-317.55) and (67.40,-316.46) .. (67.61,-316.83)
 .. controls (67.82,-317.21) and (68.96,-321.19) .. (68.96,-321.19)
 .. controls (68.96,-321.19) and (72.65,-321.98) .. (74.10,-320.18)
 .. controls (75.56,-318.39) and (76.58,-315.46) .. (76.78,-313.43)
 .. controls (76.98,-311.40) and (76.05,-305.87) .. (77.17,-305.05)
 .. controls (78.28,-304.23) and (84.09,-298.86) .. (84.81,-297.87)
 .. controls (85.53,-296.87) and (88.98,-292.48) .. (89.92,-292.15)
 .. controls (90.87,-291.82) and (95.09,-289.70) .. (95.44,-288.82)
 .. controls (95.78,-287.94) and (100.22,-282.06) .. (100.92,-280.68)
 .. controls (101.63,-279.30) and (105.48,-273.26) .. (106.14,-273.04)
 .. controls (106.80,-272.82) and (105.83,-278.72) .. (105.48,-279.60)
 .. controls (105.14,-280.49) and (105.29,-283.75) .. (107.23,-282.12)
 .. controls (109.18,-280.49) and (110.16,-278.81) .. (111.43,-277.21)
 .. controls (112.70,-275.62) and (118.91,-272.73) .. (120.45,-272.85)
 .. controls (121.99,-272.98) and (129.02,-275.35) .. (130.93,-272.86)
 .. controls (132.83,-270.38) and (136.38,-266.10) .. (136.49,-264.27)
 .. controls (136.60,-262.45) and (137.58,-256.38) .. (137.58,-256.38)
),
((12.55,47.49)
 .. controls (14.89,46.52) and (15.34,47.30) .. (14.67,44.59)
 .. controls (14.00,41.87) and (15.31,40.10) .. (15.97,37.81)
 .. controls (16.63,35.53) and (19.87,28.25) .. (20.24,25.86)
 .. controls (20.61,23.47) and (21.69,20.25) .. (21.08,18.69)
 .. controls (20.46,17.13) and (22.87,16.93) .. (23.71,14.94)
 .. controls (24.55,12.95) and (26.99,11.79) .. (27.04,10.45)
 .. controls (27.09,9.11) and (23.41,1.67) .. (22.85,1.27)
 .. controls (22.29,0.86) and (19.74,-8.35) .. (19.25,-10.86)
 .. controls (18.76,-13.38) and (14.15,-29.57) .. (13.99,-30.54)
 .. controls (13.84,-31.50) and (13.57,-37.56) .. (14.19,-41.58)
 .. controls (14.81,-45.59) and (13.90,-49.75) .. (12.46,-52.40)
 .. controls (11.02,-55.05) and (6.94,-61.83) .. (6.04,-63.49)
 .. controls (5.14,-65.16) and (4.37,-67.78) .. (5.02,-69.88)
 .. controls (5.67,-71.97) and (10.55,-74.00) .. (11.34,-74.55)
 .. controls (12.13,-75.10) and (18.21,-78.43) .. (19.49,-79.45)
 .. controls (20.78,-80.46) and (26.66,-83.90) .. (28.27,-88.54)
 .. controls (29.88,-93.19) and (31.31,-95.64) .. (30.45,-103.84)
 .. controls (29.59,-112.03) and (31.84,-115.79) .. (31.17,-118.51)
 .. controls (30.50,-121.22) and (29.35,-132.02) .. (29.14,-134.24)
 .. controls (28.93,-136.45) and (25.11,-145.62) .. (21.65,-148.54)
 .. controls (18.20,-151.45) and (15.23,-157.81) .. (15.17,-158.87)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [571]";
string area_border[];
area_border[1] := "l524-86688-57872";
area_border[2] := "l247-83728-54364";
area_border[3] := "l508-83380-54796";
area_border[4] := "l163-82880-68940";
area_border[5] := "l506-84980-63964";
area_border[6] := "l162-83716-67936";
drawoptions();
a_blocks(buildcycle(((117.93,-212.20)
 .. controls (117.79,-217.27) and (118.00,-214.40) .. (118.26,-216.68)
 .. controls (118.51,-218.95) and (118.91,-218.94) .. (119.03,-220.64)
 .. controls (119.18,-222.82) and (119.56,-222.71) .. (119.19,-223.11)
 .. controls (118.82,-223.50) and (119.74,-223.64) .. (120.69,-225.98)
 .. controls (121.61,-228.21) and (122.42,-226.00) .. (122.29,-228.75)
 .. controls (122.22,-230.23) and (123.35,-229.27) .. (123.30,-230.97)
 .. controls (123.24,-232.66) and (124.00,-232.44) .. (124.61,-233.55)
 .. controls (126.33,-236.68) and (123.82,-232.92) .. (125.63,-235.86)
 .. controls (127.45,-238.81) and (126.26,-237.53) .. (127.74,-238.79)
 .. controls (129.23,-240.06) and (128.27,-240.28) .. (129.47,-241.66)
 .. controls (130.57,-242.91) and (130.29,-249.62) .. (130.95,-249.86)
 .. controls (132.59,-250.48) and (134.05,-252.60) .. (136.07,-257.11)
 .. controls (136.75,-258.61) and (141.72,-258.51) .. (142.32,-261.16)
 .. controls (142.92,-263.82) and (143.65,-263.12) .. (143.89,-264.17)
),
((15.17,-158.87)
 .. controls (15.17,-158.87) and (11.94,-160.04) .. (10.20,-162.90)
 .. controls (8.45,-165.78) and (8.20,-166.34) .. (6.75,-169.29)
 .. controls (5.28,-172.28) and (3.92,-174.31) .. (3.78,-176.14)
 .. controls (3.64,-177.98) and (2.56,-182.24) .. (3.08,-185.05)
 .. controls (3.88,-189.36) and (5.63,-189.78) .. (5.06,-193.67)
 .. controls (4.61,-196.76) and (1.56,-203.01) .. (1.01,-204.01)
 .. controls (0.46,-205.00) and (-0.38,-205.81) .. (-3.02,-207.57)
 .. controls (-5.65,-209.32) and (-8.15,-212.53) .. (-8.53,-215.65)
 .. controls (-8.90,-218.77) and (-8.74,-220.70) .. (-7.40,-223.56)
 .. controls (-6.05,-226.41) and (-4.48,-230.03) .. (-3.30,-230.86)
 .. controls (-2.12,-231.68) and (-0.07,-232.95) .. (1.20,-233.58)
 .. controls (2.47,-234.21) and (2.94,-234.09) .. (2.99,-235.15)
 .. controls (3.03,-236.21) and (4.15,-237.91) .. (4.08,-238.59)
 .. controls (4.02,-239.26) and (2.85,-251.92) .. (4.48,-256.08)
 .. controls (6.11,-260.23) and (7.94,-266.57) .. (8.86,-267.68)
 .. controls (9.77,-268.79) and (11.81,-273.29) .. (11.96,-274.62)
 .. controls (12.12,-275.96) and (15.19,-282.24) .. (16.99,-283.89)
 .. controls (18.79,-285.54) and (21.03,-290.53) .. (24.96,-292.48)
 .. controls (28.89,-294.43) and (29.02,-295.10) .. (29.33,-295.56)
 .. controls (29.64,-296.03) and (34.59,-307.84) .. (36.91,-310.05)
 .. controls (39.22,-312.25) and (38.13,-313.74) .. (38.53,-314.01)
 .. controls (38.93,-314.28) and (42.98,-312.47) .. (44.95,-311.23)
 .. controls (46.91,-309.99) and (48.69,-308.86) .. (50.86,-310.10)
 .. controls (53.04,-311.35) and (55.01,-312.41) .. (55.38,-314.32)
 .. controls (55.76,-316.22) and (57.15,-319.42) .. (57.15,-319.42)
 .. controls (57.15,-319.42) and (58.60,-317.44) .. (61.58,-317.49)
 .. controls (64.57,-317.55) and (67.40,-316.46) .. (67.61,-316.83)
 .. controls (67.82,-317.21) and (68.96,-321.19) .. (68.96,-321.19)
 .. controls (68.96,-321.19) and (72.65,-321.98) .. (74.10,-320.18)
 .. controls (75.56,-318.39) and (76.58,-315.46) .. (76.78,-313.43)
 .. controls (76.98,-311.40) and (76.05,-305.87) .. (77.17,-305.05)
 .. controls (78.28,-304.23) and (84.09,-298.86) .. (84.81,-297.87)
 .. controls (85.53,-296.87) and (88.98,-292.48) .. (89.92,-292.15)
 .. controls (90.87,-291.82) and (95.09,-289.70) .. (95.44,-288.82)
 .. controls (95.78,-287.94) and (100.22,-282.06) .. (100.92,-280.68)
 .. controls (101.63,-279.30) and (105.48,-273.26) .. (106.14,-273.04)
 .. controls (106.80,-272.82) and (105.83,-278.72) .. (105.48,-279.60)
 .. controls (105.14,-280.49) and (105.29,-283.75) .. (107.23,-282.12)
 .. controls (109.18,-280.49) and (110.16,-278.81) .. (111.43,-277.21)
 .. controls (112.70,-275.62) and (118.91,-272.73) .. (120.45,-272.85)
 .. controls (121.99,-272.98) and (129.02,-275.35) .. (130.93,-272.86)
 .. controls (132.83,-270.38) and (136.38,-266.10) .. (136.49,-264.27)
 .. controls (136.60,-262.45) and (137.58,-256.38) .. (137.58,-256.38)
),
((33.27,-308.37)
 .. controls (33.27,-308.37) and (38.92,-301.31) .. (40.07,-299.15)
 .. controls (41.22,-296.98) and (41.31,-294.77) .. (41.58,-292.26)
 .. controls (41.85,-289.75) and (40.18,-286.84) .. (39.02,-284.39)
 .. controls (37.85,-281.94) and (37.01,-280.44) .. (34.92,-278.80)
 .. controls (32.83,-277.17) and (32.50,-274.21) .. (32.23,-272.60)
 .. controls (31.96,-270.98) and (29.25,-268.52) .. (28.20,-266.55)
 .. controls (27.14,-264.59) and (25.95,-261.68) .. (25.14,-260.85)
 .. controls (24.33,-260.03) and (22.88,-253.86) .. (22.71,-252.33)
 .. controls (22.54,-250.80) and (23.55,-247.78) .. (24.21,-245.44)
 .. controls (24.88,-243.10) and (27.92,-240.26) .. (28.92,-238.97)
 .. controls (29.92,-237.67) and (32.32,-233.00) .. (33.95,-228.37)
 .. controls (35.59,-223.70) and (35.73,-224.58) .. (37.16,-222.56)
 .. controls (38.60,-220.55) and (39.93,-218.74) .. (42.25,-217.48)
 .. controls (44.56,-216.22) and (46.05,-214.24) .. (46.89,-213.25)
 .. controls (47.73,-212.25) and (49.20,-207.29) .. (49.53,-205.74)
 .. controls (49.87,-204.19) and (49.84,-198.04) .. (49.96,-195.93)
 .. controls (50.08,-193.81) and (50.24,-190.15) .. (50.53,-187.55)
 .. controls (50.83,-184.94) and (51.80,-182.70) .. (52.34,-181.43)
 .. controls (52.87,-180.16) and (54.36,-176.26) .. (54.62,-175.49)
 .. controls (54.89,-174.71) and (58.13,-168.74) .. (59.65,-165.42)
 .. controls (61.16,-162.10) and (61.20,-160.46) .. (61.61,-158.62)
 .. controls (62.02,-156.78) and (61.16,-154.13) .. (61.36,-151.81)
 .. controls (61.57,-149.50) and (61.30,-147.20) .. (60.16,-144.94)
 .. controls (59.02,-142.67) and (57.74,-141.86) .. (56.93,-140.44)
 .. controls (56.11,-139.03) and (55.12,-138.20) .. (53.55,-137.20)
 .. controls (51.97,-136.20) and (48.97,-135.35) .. (47.41,-134.92)
 .. controls (45.86,-134.50) and (42.07,-133.19) .. (40.04,-132.88)
 .. controls (38.01,-132.57) and (37.69,-131.72) .. (34.41,-131.16)
 .. controls (31.12,-130.61) and (30.51,-129.58) .. (27.11,-128.64)
),
((12.55,47.49)
 .. controls (14.89,46.52) and (15.34,47.30) .. (14.67,44.59)
 .. controls (14.00,41.87) and (15.31,40.10) .. (15.97,37.81)
 .. controls (16.63,35.53) and (19.87,28.25) .. (20.24,25.86)
 .. controls (20.61,23.47) and (21.69,20.25) .. (21.08,18.69)
 .. controls (20.46,17.13) and (22.87,16.93) .. (23.71,14.94)
 .. controls (24.55,12.95) and (26.99,11.79) .. (27.04,10.45)
 .. controls (27.09,9.11) and (23.41,1.67) .. (22.85,1.27)
 .. controls (22.29,0.86) and (19.74,-8.35) .. (19.25,-10.86)
 .. controls (18.76,-13.38) and (14.15,-29.57) .. (13.99,-30.54)
 .. controls (13.84,-31.50) and (13.57,-37.56) .. (14.19,-41.58)
 .. controls (14.81,-45.59) and (13.90,-49.75) .. (12.46,-52.40)
 .. controls (11.02,-55.05) and (6.94,-61.83) .. (6.04,-63.49)
 .. controls (5.14,-65.16) and (4.37,-67.78) .. (5.02,-69.88)
 .. controls (5.67,-71.97) and (10.55,-74.00) .. (11.34,-74.55)
 .. controls (12.13,-75.10) and (18.21,-78.43) .. (19.49,-79.45)
 .. controls (20.78,-80.46) and (26.66,-83.90) .. (28.27,-88.54)
 .. controls (29.88,-93.19) and (31.31,-95.64) .. (30.45,-103.84)
 .. controls (29.59,-112.03) and (31.84,-115.79) .. (31.17,-118.51)
 .. controls (30.50,-121.22) and (29.35,-132.02) .. (29.14,-134.24)
 .. controls (28.93,-136.45) and (25.11,-145.62) .. (21.65,-148.54)
 .. controls (18.20,-151.45) and (15.23,-157.81) .. (15.17,-158.87)
),
((28.55,-96.41)
 .. controls (36.27,-94.79) and (38.26,-96.54) .. (40.70,-97.61)
 .. controls (43.14,-98.67) and (45.43,-100.90) .. (46.57,-103.16)
 .. controls (47.70,-105.43) and (50.42,-108.79) .. (51.41,-109.61)
 .. controls (52.40,-110.44) and (54.63,-113.63) .. (55.41,-114.18)
 .. controls (56.20,-114.73) and (62.66,-118.14) .. (64.23,-118.95)
 .. controls (65.79,-119.76) and (74.24,-119.65) .. (75.96,-119.20)
 .. controls (77.67,-118.76) and (82.65,-118.39) .. (82.08,-115.82)
 .. controls (81.51,-113.24) and (80.82,-107.41) .. (79.40,-105.44)
 .. controls (77.99,-103.48) and (75.52,-101.64) .. (74.41,-100.24)
 .. controls (73.31,-98.84) and (70.47,-94.91) .. (70.30,-92.80)
 .. controls (70.13,-90.69) and (69.41,-89.37) .. (69.46,-85.53)
 .. controls (69.52,-81.69) and (69.32,-78.71) .. (70.95,-76.16)
 .. controls (72.59,-73.60) and (73.01,-71.95) .. (74.47,-69.88)
 .. controls (75.94,-67.81) and (77.87,-65.44) .. (77.89,-63.32)
),
((117.93,-212.20)
 .. controls (117.26,-212.23) and (118.57,-205.28) .. (118.43,-203.76)
 .. controls (118.28,-202.23) and (120.98,-191.29) .. (121.25,-188.30)
 .. controls (121.53,-185.31) and (123.81,-173.61) .. (124.69,-171.37)
 .. controls (125.57,-169.13) and (124.21,-155.05) .. (124.04,-152.85)
 .. controls (123.86,-150.64) and (121.89,-146.49) .. (121.33,-144.30)
 .. controls (120.77,-142.11) and (120.44,-135.49) .. (119.68,-133.11)
 .. controls (118.92,-130.74) and (120.19,-117.91) .. (121.09,-113.56)
 .. controls (121.99,-109.20) and (119.40,-98.34) .. (118.73,-95.77)
 .. controls (118.06,-93.20) and (116.49,-87.11) .. (112.85,-79.27)
 .. controls (109.21,-71.42) and (94.29,-67.92) .. (92.58,-68.46)
 .. controls (90.87,-69.01) and (72.09,-62.38) .. (69.67,-61.89)
 .. controls (67.25,-61.40) and (56.58,-55.83) .. (53.36,-54.21)
 .. controls (50.13,-52.60) and (49.70,-54.15) .. (48.84,-54.08)
 .. controls (47.97,-54.02) and (39.31,-58.84) .. (35.51,-60.13)
 .. controls (31.72,-61.42) and (31.27,-59.70) .. (30.25,-57.91)
 .. controls (29.22,-56.12) and (26.41,-50.07) .. (27.19,-47.93)
 .. controls (27.98,-45.79) and (28.89,-41.73) .. (28.71,-36.45)
 .. controls (28.52,-31.18) and (34.49,-20.98) .. (35.73,-18.05)
 .. controls (36.98,-15.13) and (38.31,-12.10) .. (38.25,-10.38)
 .. controls (38.19,-8.65) and (38.21,-6.63) .. (38.86,-5.94)
 .. controls (39.51,-5.24) and (40.22,-3.58) .. (39.94,-1.19)
 .. controls (39.66,1.20) and (40.50,2.09) .. (40.84,3.16)
 .. controls (41.19,4.23) and (41.72,8.29) .. (40.97,10.28)
 .. controls (40.23,12.27) and (37.93,12.09) .. (36.76,12.43)
 .. controls (35.60,12.77) and (36.42,14.15) .. (36.37,15.39)
 .. controls (36.33,16.64) and (37.32,18.31) .. (37.32,18.31)
 .. controls (37.32,18.31) and (38.13,19.88) .. (38.97,20.48)
 .. controls (39.82,21.09) and (39.86,22.53) .. (39.86,22.53)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [527]";
string area_border[];
area_border[1] := "l504-83088-64864";
area_border[2] := "l162-83716-67936";
drawoptions();
a_water(buildcycle(((29.54,-51.79)
 .. controls (29.54,-51.79) and (27.67,-53.20) .. (27.11,-53.60)
 .. controls (26.55,-54.01) and (26.11,-55.08) .. (25.19,-56.17)
 .. controls (24.26,-57.26) and (24.18,-57.65) .. (24.11,-58.42)
 .. controls (24.05,-59.19) and (24.37,-60.04) .. (24.77,-60.61)
 .. controls (25.18,-61.17) and (25.52,-62.60) .. (25.76,-63.94)
 .. controls (26.00,-65.28) and (26.89,-66.01) .. (27.89,-67.04)
 .. controls (28.88,-68.06) and (28.98,-68.06) .. (29.97,-68.79)
 .. controls (30.95,-69.52) and (31.64,-70.08) .. (32.41,-70.05)
 .. controls (33.18,-70.02) and (33.45,-69.63) .. (34.31,-69.31)
 .. controls (35.16,-68.99) and (34.27,-68.25) .. (34.61,-67.09)
 .. controls (34.95,-65.92) and (34.62,-64.68) .. (34.47,-63.05)
 .. controls (34.31,-61.42) and (34.78,-61.21) .. (34.23,-59.31)
),
((117.93,-212.20)
 .. controls (117.26,-212.23) and (118.57,-205.28) .. (118.43,-203.76)
 .. controls (118.28,-202.23) and (120.98,-191.29) .. (121.25,-188.30)
 .. controls (121.53,-185.31) and (123.81,-173.61) .. (124.69,-171.37)
 .. controls (125.57,-169.13) and (124.21,-155.05) .. (124.04,-152.85)
 .. controls (123.86,-150.64) and (121.89,-146.49) .. (121.33,-144.30)
 .. controls (120.77,-142.11) and (120.44,-135.49) .. (119.68,-133.11)
 .. controls (118.92,-130.74) and (120.19,-117.91) .. (121.09,-113.56)
 .. controls (121.99,-109.20) and (119.40,-98.34) .. (118.73,-95.77)
 .. controls (118.06,-93.20) and (116.49,-87.11) .. (112.85,-79.27)
 .. controls (109.21,-71.42) and (94.29,-67.92) .. (92.58,-68.46)
 .. controls (90.87,-69.01) and (72.09,-62.38) .. (69.67,-61.89)
 .. controls (67.25,-61.40) and (56.58,-55.83) .. (53.36,-54.21)
 .. controls (50.13,-52.60) and (49.70,-54.15) .. (48.84,-54.08)
 .. controls (47.97,-54.02) and (39.31,-58.84) .. (35.51,-60.13)
 .. controls (31.72,-61.42) and (31.27,-59.70) .. (30.25,-57.91)
 .. controls (29.22,-56.12) and (26.41,-50.07) .. (27.19,-47.93)
 .. controls (27.98,-45.79) and (28.89,-41.73) .. (28.71,-36.45)
 .. controls (28.52,-31.18) and (34.49,-20.98) .. (35.73,-18.05)
 .. controls (36.98,-15.13) and (38.31,-12.10) .. (38.25,-10.38)
 .. controls (38.19,-8.65) and (38.21,-6.63) .. (38.86,-5.94)
 .. controls (39.51,-5.24) and (40.22,-3.58) .. (39.94,-1.19)
 .. controls (39.66,1.20) and (40.50,2.09) .. (40.84,3.16)
 .. controls (41.19,4.23) and (41.72,8.29) .. (40.97,10.28)
 .. controls (40.23,12.27) and (37.93,12.09) .. (36.76,12.43)
 .. controls (35.60,12.77) and (36.42,14.15) .. (36.37,15.39)
 .. controls (36.33,16.64) and (37.32,18.31) .. (37.32,18.31)
 .. controls (37.32,18.31) and (38.13,19.88) .. (38.97,20.48)
 .. controls (39.82,21.09) and (39.86,22.53) .. (39.86,22.53)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [471]";
string area_border[];
area_border[1] := "l542-82768-69228";
area_border[2] := "l548-82752-69256";
area_border[3] := "l543-82720-69220";
area_border[4] := "l164-82800-70404";
area_border[5] := "l534-83324-70712";
area_border[6] := "l531-83492-70664";
area_border[7] := "l533-83532-70592";
area_border[8] := "l160-84024-77676";
area_border[9] := "l550-83676-68284";
area_border[10] := "l163-82880-68940";
drawoptions();
a_water(buildcycle(((12.76,44.13)
 -- (12.61,45.86)
 -- (12.55,47.49)
),
((9.49,47.00)
 .. controls (11.03,46.96) and (14.02,46.58) .. (14.02,46.58)
),
((11.39,44.85)
 .. controls (11.39,44.85) and (11.52,46.68) .. (11.58,47.55)
),
((24.45,144.76)
 .. controls (23.84,140.23) and (22.28,132.87) .. (21.39,130.82)
 .. controls (20.50,128.77) and (18.19,123.50) .. (19.39,122.01)
 .. controls (20.60,120.51) and (24.73,120.37) .. (24.29,116.42)
 .. controls (23.86,112.46) and (18.82,108.34) .. (18.66,104.78)
 .. controls (18.50,101.22) and (18.06,92.08) .. (17.28,89.94)
 .. controls (16.49,87.80) and (14.13,83.97) .. (14.12,81.56)
 .. controls (14.11,79.16) and (13.61,74.53) .. (12.27,74.20)
 .. controls (10.94,73.86) and (10.80,66.94) .. (10.57,65.20)
 .. controls (10.35,63.46) and (9.95,58.45) .. (10.04,55.86)
 .. controls (10.13,53.27) and (8.42,49.94) .. (9.52,48.92)
 .. controls (10.61,47.90) and (11.58,47.55) .. (11.58,47.55)
),
((12.76,81.90)
 .. controls (15.80,83.06) and (14.24,83.59) .. (16.75,83.20)
 .. controls (19.26,82.81) and (19.38,82.23) .. (21.78,82.22)
 .. controls (24.18,82.21) and (25.23,82.35) .. (25.81,82.37)
 .. controls (26.38,82.39) and (28.31,82.36) .. (28.31,82.36)
),
((33.35,91.57)
 .. controls (32.79,91.27) and (31.48,90.26) .. (30.66,88.88)
 .. controls (29.85,87.51) and (28.94,86.04) .. (28.78,85.17)
 .. controls (28.62,84.30) and (28.28,83.13) .. (28.31,82.36)
 .. controls (28.33,81.60) and (29.14,80.47) .. (29.14,80.47)
 .. controls (29.14,80.47) and (30.75,81.20) .. (31.11,81.98)
 .. controls (31.46,82.77) and (31.90,83.84) .. (32.16,84.71)
 .. controls (32.42,85.59) and (33.03,87.14) .. (33.08,88.39)
 .. controls (33.13,89.65) and (33.92,91.88) .. cycle
),
((31.82,72.98)
 .. controls (31.51,73.54) and (31.29,74.30) .. (30.76,75.73)
 .. controls (30.23,77.15) and (30.44,76.68) .. (30.29,78.02)
 .. controls (30.15,79.36) and (29.14,80.47) .. (29.14,80.47)
),
((32.47,277.70)
 .. controls (32.41,273.86) and (31.89,272.21) .. (33.30,270.43)
 .. controls (34.71,268.66) and (35.94,266.49) .. (35.74,264.08)
 .. controls (35.54,261.68) and (35.07,258.59) .. (35.34,256.39)
 .. controls (35.61,254.19) and (35.47,247.46) .. (35.06,245.62)
 .. controls (34.64,243.78) and (32.81,233.15) .. (32.77,231.51)
 .. controls (32.74,229.88) and (32.51,222.86) .. (32.70,220.27)
 .. controls (32.88,217.68) and (34.12,212.73) .. (34.17,211.29)
 .. controls (34.22,209.85) and (34.18,205.62) .. (34.31,204.76)
 .. controls (34.43,203.90) and (35.46,204.71) .. (36.04,201.85)
 .. controls (36.63,198.99) and (34.94,194.99) .. (35.92,194.44)
 .. controls (36.90,193.90) and (37.97,190.96) .. (38.25,188.38)
 .. controls (38.54,185.79) and (39.39,178.14) .. (39.07,176.30)
 .. controls (38.75,174.46) and (37.90,171.36) .. (38.82,169.76)
 .. controls (39.74,168.16) and (39.65,167.96) .. (39.35,165.55)
 .. controls (39.06,163.14) and (38.91,161.98) .. (39.75,160.00)
 .. controls (40.59,158.01) and (42.01,155.85) .. (41.89,153.93)
 .. controls (41.76,152.01) and (42.71,152.42) .. (44.43,150.08)
 .. controls (46.14,147.74) and (43.61,143.33) .. (41.63,139.71)
 .. controls (39.64,136.08) and (38.86,130.96) .. (38.46,128.74)
 .. controls (38.06,126.51) and (36.21,121.84) .. (36.41,118.77)
 .. controls (36.61,115.70) and (37.13,112.07) .. (37.21,109.67)
 .. controls (37.30,107.28) and (35.97,104.25) .. (36.16,101.66)
 .. controls (36.35,99.08) and (34.90,99.41) .. (36.62,96.97)
 .. controls (38.34,94.54) and (39.88,89.02) .. (39.23,85.83)
 .. controls (38.58,82.64) and (38.19,77.43) .. (33.00,74.94)
 .. controls (27.80,72.45) and (28.31,71.79) .. (26.85,66.84)
 .. controls (25.40,61.88) and (26.01,57.97) .. (26.07,56.33)
 .. controls (26.13,54.70) and (25.53,47.28) .. (26.17,45.48)
 .. controls (26.81,43.68) and (27.76,41.12) .. (30.58,42.85)
 .. controls (33.40,44.59) and (38.25,46.01) .. (39.88,46.07)
 .. controls (41.52,46.13) and (42.11,45.47) .. (42.51,45.10)
 .. controls (42.91,44.73) and (43.11,44.55) .. (44.38,46.71)
 .. controls (45.64,48.87) and (44.79,45.86) .. (45.86,45.42)
 .. controls (46.94,44.97) and (47.88,45.49) .. (46.27,41.97)
 .. controls (44.67,38.46) and (41.26,34.40) .. (41.36,31.52)
 .. controls (41.47,28.64) and (40.13,23.12) .. (39.86,22.53)
),
((16.03,22.73)
 -- (45.83,24.86)
),
((12.55,47.49)
 .. controls (14.89,46.52) and (15.34,47.30) .. (14.67,44.59)
 .. controls (14.00,41.87) and (15.31,40.10) .. (15.97,37.81)
 .. controls (16.63,35.53) and (19.87,28.25) .. (20.24,25.86)
 .. controls (20.61,23.47) and (21.69,20.25) .. (21.08,18.69)
 .. controls (20.46,17.13) and (22.87,16.93) .. (23.71,14.94)
 .. controls (24.55,12.95) and (26.99,11.79) .. (27.04,10.45)
 .. controls (27.09,9.11) and (23.41,1.67) .. (22.85,1.27)
 .. controls (22.29,0.86) and (19.74,-8.35) .. (19.25,-10.86)
 .. controls (18.76,-13.38) and (14.15,-29.57) .. (13.99,-30.54)
 .. controls (13.84,-31.50) and (13.57,-37.56) .. (14.19,-41.58)
 .. controls (14.81,-45.59) and (13.90,-49.75) .. (12.46,-52.40)
 .. controls (11.02,-55.05) and (6.94,-61.83) .. (6.04,-63.49)
 .. controls (5.14,-65.16) and (4.37,-67.78) .. (5.02,-69.88)
 .. controls (5.67,-71.97) and (10.55,-74.00) .. (11.34,-74.55)
 .. controls (12.13,-75.10) and (18.21,-78.43) .. (19.49,-79.45)
 .. controls (20.78,-80.46) and (26.66,-83.90) .. (28.27,-88.54)
 .. controls (29.88,-93.19) and (31.31,-95.64) .. (30.45,-103.84)
 .. controls (29.59,-112.03) and (31.84,-115.79) .. (31.17,-118.51)
 .. controls (30.50,-121.22) and (29.35,-132.02) .. (29.14,-134.24)
 .. controls (28.93,-136.45) and (25.11,-145.62) .. (21.65,-148.54)
 .. controls (18.20,-151.45) and (15.23,-157.81) .. (15.17,-158.87)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [461]";
string area_border[];
area_border[1] := "l550-83676-68284";
area_border[2] := "l160-84024-77676";
area_border[3] := "l162-83716-67936";
area_border[4] := "l538-83724-67728";
area_border[5] := "l539-83604-67400";
area_border[6] := "l541-83408-67348";
area_border[7] := "l163-82880-68940";
drawoptions();
a_water(buildcycle(((16.03,22.73)
 -- (45.83,24.86)
),
((32.47,277.70)
 .. controls (32.41,273.86) and (31.89,272.21) .. (33.30,270.43)
 .. controls (34.71,268.66) and (35.94,266.49) .. (35.74,264.08)
 .. controls (35.54,261.68) and (35.07,258.59) .. (35.34,256.39)
 .. controls (35.61,254.19) and (35.47,247.46) .. (35.06,245.62)
 .. controls (34.64,243.78) and (32.81,233.15) .. (32.77,231.51)
 .. controls (32.74,229.88) and (32.51,222.86) .. (32.70,220.27)
 .. controls (32.88,217.68) and (34.12,212.73) .. (34.17,211.29)
 .. controls (34.22,209.85) and (34.18,205.62) .. (34.31,204.76)
 .. controls (34.43,203.90) and (35.46,204.71) .. (36.04,201.85)
 .. controls (36.63,198.99) and (34.94,194.99) .. (35.92,194.44)
 .. controls (36.90,193.90) and (37.97,190.96) .. (38.25,188.38)
 .. controls (38.54,185.79) and (39.39,178.14) .. (39.07,176.30)
 .. controls (38.75,174.46) and (37.90,171.36) .. (38.82,169.76)
 .. controls (39.74,168.16) and (39.65,167.96) .. (39.35,165.55)
 .. controls (39.06,163.14) and (38.91,161.98) .. (39.75,160.00)
 .. controls (40.59,158.01) and (42.01,155.85) .. (41.89,153.93)
 .. controls (41.76,152.01) and (42.71,152.42) .. (44.43,150.08)
 .. controls (46.14,147.74) and (43.61,143.33) .. (41.63,139.71)
 .. controls (39.64,136.08) and (38.86,130.96) .. (38.46,128.74)
 .. controls (38.06,126.51) and (36.21,121.84) .. (36.41,118.77)
 .. controls (36.61,115.70) and (37.13,112.07) .. (37.21,109.67)
 .. controls (37.30,107.28) and (35.97,104.25) .. (36.16,101.66)
 .. controls (36.35,99.08) and (34.90,99.41) .. (36.62,96.97)
 .. controls (38.34,94.54) and (39.88,89.02) .. (39.23,85.83)
 .. controls (38.58,82.64) and (38.19,77.43) .. (33.00,74.94)
 .. controls (27.80,72.45) and (28.31,71.79) .. (26.85,66.84)
 .. controls (25.40,61.88) and (26.01,57.97) .. (26.07,56.33)
 .. controls (26.13,54.70) and (25.53,47.28) .. (26.17,45.48)
 .. controls (26.81,43.68) and (27.76,41.12) .. (30.58,42.85)
 .. controls (33.40,44.59) and (38.25,46.01) .. (39.88,46.07)
 .. controls (41.52,46.13) and (42.11,45.47) .. (42.51,45.10)
 .. controls (42.91,44.73) and (43.11,44.55) .. (44.38,46.71)
 .. controls (45.64,48.87) and (44.79,45.86) .. (45.86,45.42)
 .. controls (46.94,44.97) and (47.88,45.49) .. (46.27,41.97)
 .. controls (44.67,38.46) and (41.26,34.40) .. (41.36,31.52)
 .. controls (41.47,28.64) and (40.13,23.12) .. (39.86,22.53)
),
((117.93,-212.20)
 .. controls (117.26,-212.23) and (118.57,-205.28) .. (118.43,-203.76)
 .. controls (118.28,-202.23) and (120.98,-191.29) .. (121.25,-188.30)
 .. controls (121.53,-185.31) and (123.81,-173.61) .. (124.69,-171.37)
 .. controls (125.57,-169.13) and (124.21,-155.05) .. (124.04,-152.85)
 .. controls (123.86,-150.64) and (121.89,-146.49) .. (121.33,-144.30)
 .. controls (120.77,-142.11) and (120.44,-135.49) .. (119.68,-133.11)
 .. controls (118.92,-130.74) and (120.19,-117.91) .. (121.09,-113.56)
 .. controls (121.99,-109.20) and (119.40,-98.34) .. (118.73,-95.77)
 .. controls (118.06,-93.20) and (116.49,-87.11) .. (112.85,-79.27)
 .. controls (109.21,-71.42) and (94.29,-67.92) .. (92.58,-68.46)
 .. controls (90.87,-69.01) and (72.09,-62.38) .. (69.67,-61.89)
 .. controls (67.25,-61.40) and (56.58,-55.83) .. (53.36,-54.21)
 .. controls (50.13,-52.60) and (49.70,-54.15) .. (48.84,-54.08)
 .. controls (47.97,-54.02) and (39.31,-58.84) .. (35.51,-60.13)
 .. controls (31.72,-61.42) and (31.27,-59.70) .. (30.25,-57.91)
 .. controls (29.22,-56.12) and (26.41,-50.07) .. (27.19,-47.93)
 .. controls (27.98,-45.79) and (28.89,-41.73) .. (28.71,-36.45)
 .. controls (28.52,-31.18) and (34.49,-20.98) .. (35.73,-18.05)
 .. controls (36.98,-15.13) and (38.31,-12.10) .. (38.25,-10.38)
 .. controls (38.19,-8.65) and (38.21,-6.63) .. (38.86,-5.94)
 .. controls (39.51,-5.24) and (40.22,-3.58) .. (39.94,-1.19)
 .. controls (39.66,1.20) and (40.50,2.09) .. (40.84,3.16)
 .. controls (41.19,4.23) and (41.72,8.29) .. (40.97,10.28)
 .. controls (40.23,12.27) and (37.93,12.09) .. (36.76,12.43)
 .. controls (35.60,12.77) and (36.42,14.15) .. (36.37,15.39)
 .. controls (36.33,16.64) and (37.32,18.31) .. (37.32,18.31)
 .. controls (37.32,18.31) and (38.13,19.88) .. (38.97,20.48)
 .. controls (39.82,21.09) and (39.86,22.53) .. (39.86,22.53)
),
((35.33,4.21)
 .. controls (36.17,5.01) and (36.06,8.08) .. (36.31,9.15)
 .. controls (36.56,10.21) and (37.70,13.23) .. (37.87,13.82)
),
((27.45,-14.70)
 .. controls (27.45,-14.70) and (27.93,-11.99) .. (27.82,-11.42)
 .. controls (27.70,-10.85) and (28.30,-8.72) .. (29.23,-8.01)
 .. controls (30.17,-7.31) and (30.61,-6.23) .. (30.96,-5.17)
 .. controls (31.30,-4.10) and (31.07,-3.05) .. (31.04,-2.09)
 .. controls (31.01,-1.13) and (31.57,-0.82) .. (32.11,0.16)
 .. controls (32.65,1.14) and (33.40,1.74) .. (33.85,2.62)
 .. controls (34.30,3.50) and (35.33,4.21) .. (35.33,4.21)
),
((32.11,0.16)
 .. controls (32.11,0.16) and (30.95,0.50) .. (30.06,1.05)
 .. controls (29.18,1.59) and (28.10,2.32) .. (27.61,2.50)
 .. controls (27.12,2.67) and (26.54,2.94) .. (25.95,3.21)
 .. controls (25.37,3.47) and (23.15,3.78) .. (23.15,3.78)
),
((12.55,47.49)
 .. controls (14.89,46.52) and (15.34,47.30) .. (14.67,44.59)
 .. controls (14.00,41.87) and (15.31,40.10) .. (15.97,37.81)
 .. controls (16.63,35.53) and (19.87,28.25) .. (20.24,25.86)
 .. controls (20.61,23.47) and (21.69,20.25) .. (21.08,18.69)
 .. controls (20.46,17.13) and (22.87,16.93) .. (23.71,14.94)
 .. controls (24.55,12.95) and (26.99,11.79) .. (27.04,10.45)
 .. controls (27.09,9.11) and (23.41,1.67) .. (22.85,1.27)
 .. controls (22.29,0.86) and (19.74,-8.35) .. (19.25,-10.86)
 .. controls (18.76,-13.38) and (14.15,-29.57) .. (13.99,-30.54)
 .. controls (13.84,-31.50) and (13.57,-37.56) .. (14.19,-41.58)
 .. controls (14.81,-45.59) and (13.90,-49.75) .. (12.46,-52.40)
 .. controls (11.02,-55.05) and (6.94,-61.83) .. (6.04,-63.49)
 .. controls (5.14,-65.16) and (4.37,-67.78) .. (5.02,-69.88)
 .. controls (5.67,-71.97) and (10.55,-74.00) .. (11.34,-74.55)
 .. controls (12.13,-75.10) and (18.21,-78.43) .. (19.49,-79.45)
 .. controls (20.78,-80.46) and (26.66,-83.90) .. (28.27,-88.54)
 .. controls (29.88,-93.19) and (31.31,-95.64) .. (30.45,-103.84)
 .. controls (29.59,-112.03) and (31.84,-115.79) .. (31.17,-118.51)
 .. controls (30.50,-121.22) and (29.35,-132.02) .. (29.14,-134.24)
 .. controls (28.93,-136.45) and (25.11,-145.62) .. (21.65,-148.54)
 .. controls (18.20,-151.45) and (15.23,-157.81) .. (15.17,-158.87)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [374]";
string area_border[];
area_border[1] := "l262-83352-66564";
area_border[2] := "l162-83716-67936";
area_border[3] := "l500-83008-66276";
area_border[4] := "l539-83604-67400";
drawoptions();
a_water(buildcycle(((34.37,-25.59)
 .. controls (33.76,-24.65) and (32.27,-23.17) .. (32.21,-21.63)
 .. controls (32.16,-20.10) and (31.38,-19.84) .. (30.77,-19.00)
 .. controls (30.17,-18.15) and (29.59,-18.08) .. (29.09,-17.62)
 .. controls (28.60,-17.15) and (27.97,-15.74) .. (27.45,-14.70)
),
((117.93,-212.20)
 .. controls (117.26,-212.23) and (118.57,-205.28) .. (118.43,-203.76)
 .. controls (118.28,-202.23) and (120.98,-191.29) .. (121.25,-188.30)
 .. controls (121.53,-185.31) and (123.81,-173.61) .. (124.69,-171.37)
 .. controls (125.57,-169.13) and (124.21,-155.05) .. (124.04,-152.85)
 .. controls (123.86,-150.64) and (121.89,-146.49) .. (121.33,-144.30)
 .. controls (120.77,-142.11) and (120.44,-135.49) .. (119.68,-133.11)
 .. controls (118.92,-130.74) and (120.19,-117.91) .. (121.09,-113.56)
 .. controls (121.99,-109.20) and (119.40,-98.34) .. (118.73,-95.77)
 .. controls (118.06,-93.20) and (116.49,-87.11) .. (112.85,-79.27)
 .. controls (109.21,-71.42) and (94.29,-67.92) .. (92.58,-68.46)
 .. controls (90.87,-69.01) and (72.09,-62.38) .. (69.67,-61.89)
 .. controls (67.25,-61.40) and (56.58,-55.83) .. (53.36,-54.21)
 .. controls (50.13,-52.60) and (49.70,-54.15) .. (48.84,-54.08)
 .. controls (47.97,-54.02) and (39.31,-58.84) .. (35.51,-60.13)
 .. controls (31.72,-61.42) and (31.27,-59.70) .. (30.25,-57.91)
 .. controls (29.22,-56.12) and (26.41,-50.07) .. (27.19,-47.93)
 .. controls (27.98,-45.79) and (28.89,-41.73) .. (28.71,-36.45)
 .. controls (28.52,-31.18) and (34.49,-20.98) .. (35.73,-18.05)
 .. controls (36.98,-15.13) and (38.31,-12.10) .. (38.25,-10.38)
 .. controls (38.19,-8.65) and (38.21,-6.63) .. (38.86,-5.94)
 .. controls (39.51,-5.24) and (40.22,-3.58) .. (39.94,-1.19)
 .. controls (39.66,1.20) and (40.50,2.09) .. (40.84,3.16)
 .. controls (41.19,4.23) and (41.72,8.29) .. (40.97,10.28)
 .. controls (40.23,12.27) and (37.93,12.09) .. (36.76,12.43)
 .. controls (35.60,12.77) and (36.42,14.15) .. (36.37,15.39)
 .. controls (36.33,16.64) and (37.32,18.31) .. (37.32,18.31)
 .. controls (37.32,18.31) and (38.13,19.88) .. (38.97,20.48)
 .. controls (39.82,21.09) and (39.86,22.53) .. (39.86,22.53)
),
((29.23,-8.01)
 .. controls (29.23,-8.01) and (28.60,-9.09) .. (28.22,-9.30)
 .. controls (27.84,-9.50) and (27.10,-10.20) .. (26.35,-10.80)
 .. controls (25.61,-11.40) and (25.34,-11.89) .. (24.59,-12.50)
 .. controls (23.84,-13.10) and (23.67,-13.78) .. (22.65,-14.58)
 .. controls (21.62,-15.39) and (21.26,-16.17) .. (20.82,-17.14)
 .. controls (20.37,-18.12) and (20.33,-19.56) .. (20.26,-20.52)
 .. controls (20.20,-21.49) and (20.74,-23.19) .. (20.87,-24.05)
 .. controls (21.00,-24.91) and (21.14,-26.16) .. (21.15,-26.64)
 .. controls (21.17,-27.12) and (21.95,-27.91) .. (24.95,-28.04)
 .. controls (26.20,-28.09) and (26.10,-28.00) .. (27.47,-28.62)
 .. controls (28.83,-29.24) and (28.16,-29.17) .. (31.59,-31.26)
),
((27.45,-14.70)
 .. controls (27.45,-14.70) and (27.93,-11.99) .. (27.82,-11.42)
 .. controls (27.70,-10.85) and (28.30,-8.72) .. (29.23,-8.01)
 .. controls (30.17,-7.31) and (30.61,-6.23) .. (30.96,-5.17)
 .. controls (31.30,-4.10) and (31.07,-3.05) .. (31.04,-2.09)
 .. controls (31.01,-1.13) and (31.57,-0.82) .. (32.11,0.16)
 .. controls (32.65,1.14) and (33.40,1.74) .. (33.85,2.62)
 .. controls (34.30,3.50) and (35.33,4.21) .. (35.33,4.21)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [302]";
string area_border[];
area_border[1] := "l482-79788-76700";
area_border[2] := "l165-77436-76312";
drawoptions();
a_blocks(buildcycle(((-43.84,214.18)
 .. controls (-43.84,214.18) and (-47.00,216.66) .. (-48.08,217.39)
 .. controls (-49.16,218.12) and (-49.43,217.53) .. (-52.68,217.03)
 .. controls (-55.92,216.53) and (-57.16,218.89) .. (-59.72,220.52)
 .. controls (-62.27,222.16) and (-64.80,223.03) .. (-67.59,223.03)
 .. controls (-70.37,223.02) and (-70.09,223.13) .. (-72.96,222.93)
 .. controls (-75.84,222.73) and (-78.40,224.36) .. (-83.15,225.73)
 .. controls (-87.91,227.09) and (-86.52,225.90) .. (-89.53,224.06)
 .. controls (-92.54,222.22) and (-93.18,221.24) .. (-95.19,220.88)
 .. controls (-97.19,220.53) and (-101.20,220.00) .. (-103.78,219.53)
 .. controls (-106.36,219.05) and (-108.70,217.34) .. (-109.72,216.34)
 .. controls (-110.74,215.35) and (-115.84,213.25) .. (-118.10,212.02)
),
((-126.70,210.85)
 .. controls (-126.70,210.85) and (-124.00,210.65) .. (-122.30,211.19)
 .. controls (-120.59,211.74) and (-117.49,213.67) .. (-116.82,213.60)
 .. controls (-116.14,213.52) and (-115.65,213.16) .. (-116.56,211.78)
 .. controls (-117.47,210.41) and (-117.99,206.16) .. (-118.83,205.37)
 .. controls (-119.66,204.57) and (-120.63,202.14) .. (-120.33,201.67)
 .. controls (-120.02,201.20) and (-119.25,200.94) .. (-117.43,201.19)
 .. controls (-115.62,201.45) and (-114.26,201.21) .. (-112.64,201.27)
 .. controls (-111.01,201.32) and (-106.63,199.66) .. (-104.17,200.70)
 .. controls (-101.71,201.75) and (-99.49,201.35) .. (-96.62,204.52)
 .. controls (-93.76,207.69) and (-90.22,210.88) .. (-88.39,210.85)
 .. controls (-86.56,210.82) and (-84.74,210.98) .. (-82.32,210.39)
 .. controls (-79.89,209.81) and (-71.28,210.79) .. (-69.39,209.03)
 .. controls (-67.50,207.28) and (-66.62,206.93) .. (-67.86,203.81)
 .. controls (-69.09,200.69) and (-69.72,196.73) .. (-67.72,194.59)
 .. controls (-65.72,192.45) and (-66.10,192.25) .. (-63.82,193.10)
 .. controls (-61.55,193.95) and (-58.78,197.12) .. (-57.76,198.02)
 .. controls (-56.73,198.92) and (-50.59,204.33) .. (-49.23,209.28)
 .. controls (-47.87,214.23) and (-45.40,212.30) .. (-45.87,217.18)
 .. controls (-46.33,222.06) and (-47.31,225.39) .. (-44.85,226.34)
 .. controls (-42.39,227.29) and (-41.00,228.68) .. (-38.02,228.41)
 .. controls (-35.03,228.13) and (-36.04,226.94) .. (-33.35,226.94)
 .. controls (-30.67,226.94) and (-31.23,229.41) .. (-29.38,228.61)
 .. controls (-27.53,227.81) and (-26.28,225.27) .. (-24.30,226.20)
 .. controls (-22.32,227.13) and (-18.62,231.40) .. (-16.33,231.67)
 .. controls (-14.03,231.94) and (-14.38,230.97) .. (-11.86,230.39)
 .. controls (-9.34,229.81) and (0.17,227.17) .. (2.68,226.98)
 .. controls (5.18,226.78) and (10.00,223.88) .. (10.98,223.24)
 .. controls (11.96,222.60) and (16.74,220.57) .. (18.08,217.92)
 .. controls (19.42,215.28) and (19.90,212.61) .. (19.03,210.18)
 .. controls (18.15,207.74) and (18.05,205.24) .. (16.91,204.91)
 .. controls (15.77,204.58) and (15.72,206.02) .. (15.83,202.95)
 .. controls (15.94,199.88) and (16.02,194.70) .. (16.02,194.70)
 .. controls (16.02,194.70) and (16.92,196.65) .. (17.40,196.47)
 .. controls (17.89,196.30) and (18.43,194.69) .. (19.02,194.13)
 .. controls (19.62,193.57) and (20.60,193.13) .. (19.49,191.84)
 .. controls (18.38,190.55) and (17.81,187.65) .. (18.32,186.80)
 .. controls (18.83,185.96) and (20.24,181.49) .. (19.33,180.11)
 .. controls (18.42,178.73) and (14.55,176.86) .. (13.65,172.41)
 .. controls (12.76,167.96) and (14.02,162.34) .. (14.37,160.72)
 .. controls (14.71,159.10) and (17.65,155.77) .. (16.94,153.42)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [136]";
string area_border[];
area_border[1] := "l539-82472-60132";
area_border[2] := "l247-83728-54364";
drawoptions();
a_sand(buildcycle(((2.57,-190.58)
 .. controls (3.42,-190.06) and (3.23,-190.16) .. (4.08,-189.65)
 .. controls (4.93,-189.13) and (5.42,-189.40) .. (6.86,-189.05)
 .. controls (8.30,-188.70) and (9.14,-187.90) .. (10.54,-186.39)
 .. controls (11.95,-184.89) and (11.19,-185.50) .. (12.67,-183.32)
 .. controls (14.15,-181.14) and (13.76,-180.96) .. (13.70,-178.94)
 .. controls (13.63,-176.92) and (13.43,-176.73) .. (13.02,-175.69)
 .. controls (12.60,-174.65) and (12.84,-173.10) .. (13.47,-171.63)
 .. controls (14.09,-170.16) and (14.53,-168.61) .. (14.32,-168.04)
 .. controls (14.10,-167.47) and (14.78,-164.65) .. (14.20,-161.40)
 .. controls (13.61,-158.16) and (13.30,-160.47) .. (11.86,-157.55)
),
((15.17,-158.87)
 .. controls (15.17,-158.87) and (11.94,-160.04) .. (10.20,-162.90)
 .. controls (8.45,-165.78) and (8.20,-166.34) .. (6.75,-169.29)
 .. controls (5.28,-172.28) and (3.92,-174.31) .. (3.78,-176.14)
 .. controls (3.64,-177.98) and (2.56,-182.24) .. (3.08,-185.05)
 .. controls (3.88,-189.36) and (5.63,-189.78) .. (5.06,-193.67)
 .. controls (4.61,-196.76) and (1.56,-203.01) .. (1.01,-204.01)
 .. controls (0.46,-205.00) and (-0.38,-205.81) .. (-3.02,-207.57)
 .. controls (-5.65,-209.32) and (-8.15,-212.53) .. (-8.53,-215.65)
 .. controls (-8.90,-218.77) and (-8.74,-220.70) .. (-7.40,-223.56)
 .. controls (-6.05,-226.41) and (-4.48,-230.03) .. (-3.30,-230.86)
 .. controls (-2.12,-231.68) and (-0.07,-232.95) .. (1.20,-233.58)
 .. controls (2.47,-234.21) and (2.94,-234.09) .. (2.99,-235.15)
 .. controls (3.03,-236.21) and (4.15,-237.91) .. (4.08,-238.59)
 .. controls (4.02,-239.26) and (2.85,-251.92) .. (4.48,-256.08)
 .. controls (6.11,-260.23) and (7.94,-266.57) .. (8.86,-267.68)
 .. controls (9.77,-268.79) and (11.81,-273.29) .. (11.96,-274.62)
 .. controls (12.12,-275.96) and (15.19,-282.24) .. (16.99,-283.89)
 .. controls (18.79,-285.54) and (21.03,-290.53) .. (24.96,-292.48)
 .. controls (28.89,-294.43) and (29.02,-295.10) .. (29.33,-295.56)
 .. controls (29.64,-296.03) and (34.59,-307.84) .. (36.91,-310.05)
 .. controls (39.22,-312.25) and (38.13,-313.74) .. (38.53,-314.01)
 .. controls (38.93,-314.28) and (42.98,-312.47) .. (44.95,-311.23)
 .. controls (46.91,-309.99) and (48.69,-308.86) .. (50.86,-310.10)
 .. controls (53.04,-311.35) and (55.01,-312.41) .. (55.38,-314.32)
 .. controls (55.76,-316.22) and (57.15,-319.42) .. (57.15,-319.42)
 .. controls (57.15,-319.42) and (58.60,-317.44) .. (61.58,-317.49)
 .. controls (64.57,-317.55) and (67.40,-316.46) .. (67.61,-316.83)
 .. controls (67.82,-317.21) and (68.96,-321.19) .. (68.96,-321.19)
 .. controls (68.96,-321.19) and (72.65,-321.98) .. (74.10,-320.18)
 .. controls (75.56,-318.39) and (76.58,-315.46) .. (76.78,-313.43)
 .. controls (76.98,-311.40) and (76.05,-305.87) .. (77.17,-305.05)
 .. controls (78.28,-304.23) and (84.09,-298.86) .. (84.81,-297.87)
 .. controls (85.53,-296.87) and (88.98,-292.48) .. (89.92,-292.15)
 .. controls (90.87,-291.82) and (95.09,-289.70) .. (95.44,-288.82)
 .. controls (95.78,-287.94) and (100.22,-282.06) .. (100.92,-280.68)
 .. controls (101.63,-279.30) and (105.48,-273.26) .. (106.14,-273.04)
 .. controls (106.80,-272.82) and (105.83,-278.72) .. (105.48,-279.60)
 .. controls (105.14,-280.49) and (105.29,-283.75) .. (107.23,-282.12)
 .. controls (109.18,-280.49) and (110.16,-278.81) .. (111.43,-277.21)
 .. controls (112.70,-275.62) and (118.91,-272.73) .. (120.45,-272.85)
 .. controls (121.99,-272.98) and (129.02,-275.35) .. (130.93,-272.86)
 .. controls (132.83,-270.38) and (136.38,-266.10) .. (136.49,-264.27)
 .. controls (136.60,-262.45) and (137.58,-256.38) .. (137.58,-256.38)
)));
current_src := "C4HelicopterHole_Beauty_Above_Pitch_3_Sec_2.th2 [131]";
string area_border[];
area_border[1] := "l538-82456-56576";
area_border[2] := "l247-83728-54364";
drawoptions();
a_sand(buildcycle(((24.89,-295.27)
 .. controls (24.89,-295.27) and (25.98,-293.78) .. (26.58,-292.22)
 .. controls (27.19,-290.66) and (26.99,-290.47) .. (26.81,-288.65)
 .. controls (26.63,-286.84) and (26.79,-286.06) .. (26.75,-285.10)
 .. controls (26.71,-284.15) and (26.30,-283.68) .. (26.71,-282.03)
 .. controls (27.11,-280.39) and (26.73,-278.29) .. (26.46,-276.49)
 .. controls (26.18,-274.68) and (24.98,-273.68) .. (24.83,-272.34)
 .. controls (24.67,-271.01) and (23.87,-270.47) .. (22.64,-268.71)
 .. controls (21.40,-266.95) and (19.93,-264.34) .. (19.09,-262.84)
 .. controls (18.25,-261.35) and (17.75,-260.89) .. (16.82,-259.59)
 .. controls (15.90,-258.29) and (15.51,-258.21) .. (14.78,-256.90)
 .. controls (14.04,-255.59) and (13.52,-254.75) .. (12.92,-254.10)
 .. controls (12.31,-253.45) and (11.84,-251.46) .. (11.30,-250.13)
 .. controls (10.76,-248.81) and (9.32,-246.75) .. (8.62,-246.01)
 .. controls (7.91,-245.27) and (7.60,-244.71) .. (6.89,-243.77)
 .. controls (6.18,-242.84) and (6.01,-243.23) .. (1.09,-242.56)
),
((15.17,-158.87)
 .. controls (15.17,-158.87) and (11.94,-160.04) .. (10.20,-162.90)
 .. controls (8.45,-165.78) and (8.20,-166.34) .. (6.75,-169.29)
 .. controls (5.28,-172.28) and (3.92,-174.31) .. (3.78,-176.14)
 .. controls (3.64,-177.98) and (2.56,-182.24) .. (3.08,-185.05)
 .. controls (3.88,-189.36) and (5.63,-189.78) .. (5.06,-193.67)
 .. controls (4.61,-196.76) and (1.56,-203.01) .. (1.01,-204.01)
 .. controls (0.46,-205.00) and (-0.38,-205.81) .. (-3.02,-207.57)
 .. controls (-5.65,-209.32) and (-8.15,-212.53) .. (-8.53,-215.65)
 .. controls (-8.90,-218.77) and (-8.74,-220.70) .. (-7.40,-223.56)
 .. controls (-6.05,-226.41) and (-4.48,-230.03) .. (-3.30,-230.86)
 .. controls (-2.12,-231.68) and (-0.07,-232.95) .. (1.20,-233.58)
 .. controls (2.47,-234.21) and (2.94,-234.09) .. (2.99,-235.15)
 .. controls (3.03,-236.21) and (4.15,-237.91) .. (4.08,-238.59)
 .. controls (4.02,-239.26) and (2.85,-251.92) .. (4.48,-256.08)
 .. controls (6.11,-260.23) and (7.94,-266.57) .. (8.86,-267.68)
 .. controls (9.77,-268.79) and (11.81,-273.29) .. (11.96,-274.62)
 .. controls (12.12,-275.96) and (15.19,-282.24) .. (16.99,-283.89)
 .. controls (18.79,-285.54) and (21.03,-290.53) .. (24.96,-292.48)
 .. controls (28.89,-294.43) and (29.02,-295.10) .. (29.33,-295.56)
 .. controls (29.64,-296.03) and (34.59,-307.84) .. (36.91,-310.05)
 .. controls (39.22,-312.25) and (38.13,-313.74) .. (38.53,-314.01)
 .. controls (38.93,-314.28) and (42.98,-312.47) .. (44.95,-311.23)
 .. controls (46.91,-309.99) and (48.69,-308.86) .. (50.86,-310.10)
 .. controls (53.04,-311.35) and (55.01,-312.41) .. (55.38,-314.32)
 .. controls (55.76,-316.22) and (57.15,-319.42) .. (57.15,-319.42)
 .. controls (57.15,-319.42) and (58.60,-317.44) .. (61.58,-317.49)
 .. controls (64.57,-317.55) and (67.40,-316.46) .. (67.61,-316.83)
 .. controls (67.82,-317.21) and (68.96,-321.19) .. (68.96,-321.19)
 .. controls (68.96,-321.19) and (72.65,-321.98) .. (74.10,-320.18)
 .. controls (75.56,-318.39) and (76.58,-315.46) .. (76.78,-313.43)
 .. controls (76.98,-311.40) and (76.05,-305.87) .. (77.17,-305.05)
 .. controls (78.28,-304.23) and (84.09,-298.86) .. (84.81,-297.87)
 .. controls (85.53,-296.87) and (88.98,-292.48) .. (89.92,-292.15)
 .. controls (90.87,-291.82) and (95.09,-289.70) .. (95.44,-288.82)
 .. controls (95.78,-287.94) and (100.22,-282.06) .. (100.92,-280.68)
 .. controls (101.63,-279.30) and (105.48,-273.26) .. (106.14,-273.04)
 .. controls (106.80,-272.82) and (105.83,-278.72) .. (105.48,-279.60)
 .. controls (105.14,-280.49) and (105.29,-283.75) .. (107.23,-282.12)
 .. controls (109.18,-280.49) and (110.16,-278.81) .. (111.43,-277.21)
 .. controls (112.70,-275.62) and (118.91,-272.73) .. (120.45,-272.85)
 .. controls (121.99,-272.98) and (129.02,-275.35) .. (130.93,-272.86)
 .. controls (132.83,-270.38) and (136.38,-266.10) .. (136.49,-264.27)
 .. controls (136.60,-262.45) and (137.58,-256.38) .. (137.58,-256.38)
)));
ATTR__height := -1;
drawoptions();
l_flowstone(((-48.33,232.36)
 .. controls (-48.33,232.36) and (-48.48,231.11) .. (-48.40,229.09)
 .. controls (-48.33,227.08) and (-49.17,226.38) .. (-48.16,225.07)
 .. controls (-47.16,223.76) and (-45.57,222.18) .. (-45.27,221.91)
));
ATTR__id := "l472-81464-77896";
ATTR__height := -1;
drawoptions();
l_flowstone(((-21.34,264.73)
 .. controls (-20.89,262.92) and (-20.26,261.31) .. (-20.78,259.95)
 .. controls (-21.31,258.58) and (-21.34,256.76) .. (-23.12,255.35)
 .. controls (-24.89,253.94) and (-27.33,252.13) .. (-27.97,251.24)
 .. controls (-28.61,250.35) and (-29.96,247.71) .. (-30.61,247.01)
 .. controls (-31.25,246.32) and (-32.36,245.13) .. (-33.01,244.34)
 .. controls (-33.65,243.54) and (-36.29,242.10) .. (-36.29,242.10)
 -- (-39.05,241.33)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((-40.98,247.13)
 .. controls (-43.07,246.48) and (-44.17,245.00) .. (-45.10,244.19)
 .. controls (-46.03,243.39) and (-48.25,240.81) .. (-48.58,239.55)
 .. controls (-48.92,238.29) and (-49.41,235.88) .. (-49.30,235.30)
 .. controls (-49.18,234.73) and (-48.33,232.36) .. (-48.33,232.36)
 .. controls (-48.33,232.36) and (-44.97,243.14) .. (-46.81,243.56)
 .. controls (-48.64,243.97) and (-49.78,243.65) .. (-51.75,244.82)
 .. controls (-53.71,246.00) and (-54.32,246.74) .. (-56.55,247.43)
 .. controls (-58.79,248.11) and (-58.68,247.73) .. (-60.23,248.16)
 .. controls (-61.79,248.58) and (-64.34,250.22) .. (-66.04,249.29)
 .. controls (-67.73,248.36) and (-69.14,247.54) .. (-69.88,246.55)
 .. controls (-70.61,245.57) and (-71.34,244.68) .. (-71.31,243.72)
 .. controls (-71.27,242.76) and (-70.91,240.66) .. (-70.88,239.99)
 .. controls (-70.86,239.32) and (-70.41,237.51) .. (-69.92,237.24)
 .. controls (-69.43,236.97) and (-67.86,236.17) .. (-67.21,236.86)
 .. controls (-66.57,237.55) and (-66.12,238.62) .. (-65.41,239.99)
 .. controls (-64.69,241.36) and (-66.78,243.30) .. (-63.55,241.69)
 .. controls (-60.32,240.08) and (-59.54,239.92) .. (-58.17,239.01)
 .. controls (-56.79,238.10) and (-55.82,237.85) .. (-55.19,236.24)
 .. controls (-54.55,234.63) and (-54.41,233.39) .. (-53.42,232.37)
 .. controls (-52.42,231.35) and (-51.43,230.42) .. (-50.75,230.35)
 .. controls (-50.08,230.28) and (-49.12,230.32) .. (-49.12,230.32)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-55.38,238.92)
 .. controls (-55.02,239.61) and (-55.04,240.19) .. (-54.18,241.84)
 .. controls (-53.31,243.49) and (-52.18,243.37) .. (-51.14,243.88)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-63.98,242.93)
 .. controls (-63.98,242.93) and (-63.74,244.18) .. (-63.48,245.06)
 .. controls (-63.23,245.93) and (-62.57,246.34) .. (-61.54,247.15)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-65.55,241.24)
 .. controls (-65.55,241.24) and (-66.81,241.57) .. (-67.50,242.03)
 .. controls (-68.19,242.48) and (-68.99,243.42) .. (-70.21,245.10)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-78.75,255.36)
 .. controls (-77.54,253.87) and (-77.78,252.51) .. (-78.14,251.92)
 .. controls (-78.50,251.33) and (-79.42,250.05) .. (-79.76,248.99)
 .. controls (-80.11,247.92) and (-79.87,246.49) .. (-80.04,245.91)
 .. controls (-80.21,245.32) and (-81.69,243.83) .. (-82.35,243.42)
 .. controls (-83.01,243.02) and (-83.93,241.93) .. (-83.90,241.16)
 .. controls (-83.87,240.40) and (-83.52,238.59) .. (-83.60,238.10)
 .. controls (-83.68,237.62) and (-84.91,234.41) .. (-84.99,233.92)
 .. controls (-85.07,233.44) and (-84.89,231.24) .. (-84.39,230.78)
 .. controls (-83.90,230.31) and (-82.23,229.41) .. (-81.83,228.95)
 .. controls (-81.43,228.48) and (-78.81,227.90) .. (-78.54,228.20)
 .. controls (-78.26,228.50) and (-76.14,230.98) .. (-76.66,232.11)
 .. controls (-77.18,233.25) and (-77.53,234.87) .. (-76.71,236.14)
 .. controls (-75.89,237.42) and (-75.25,238.50) .. (-74.53,239.86)
 .. controls (-73.81,241.23) and (-72.69,242.13) .. (-72.65,243.48)
 .. controls (-72.60,244.82) and (-73.09,245.00) .. (-72.66,246.45)
 .. controls (-72.23,247.91) and (-71.58,248.51) .. (-71.60,249.09)
 .. controls (-71.62,249.66) and (-71.74,250.23) .. (-72.07,251.28)
 .. controls (-72.39,252.32) and (-73.08,252.68) .. (-72.55,253.95)
 .. controls (-72.02,255.22) and (-71.15,255.15) .. (-71.49,256.49)
 .. controls (-71.82,257.82) and (-73.05,259.79) .. (-73.05,259.79)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-72.58,249.63)
 .. controls (-73.14,249.13) and (-75.26,249.43) .. (-75.66,249.61)
 .. controls (-76.05,249.79) and (-77.03,250.43) .. (-77.43,250.99)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-73.59,242.97)
 .. controls (-74.63,242.64) and (-74.71,242.06) .. (-75.89,242.69)
 .. controls (-77.06,243.32) and (-77.64,243.40) .. (-78.04,243.77)
 .. controls (-78.44,244.14) and (-79.23,244.88) .. (-79.23,244.88)
 -- (-79.54,245.44)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-77.90,234.47)
 .. controls (-79.65,235.17) and (-81.02,235.70) .. (-81.62,236.35)
 .. controls (-82.22,237.00) and (-83.60,238.10) .. (-83.60,238.10)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-76.27,234.62)
 .. controls (-76.84,231.72) and (-76.77,229.80) .. (-75.56,228.31)
 .. controls (-74.35,226.82) and (-74.53,226.43) .. (-73.37,226.18)
 .. controls (-72.21,225.93) and (-70.07,225.34) .. (-69.61,225.83)
 .. controls (-69.15,226.33) and (-67.86,227.82) .. (-67.70,228.88)
 .. controls (-67.55,229.94) and (-67.47,230.52) .. (-67.62,232.05)
 .. controls (-67.77,233.58) and (-67.67,233.30) .. (-68.28,234.33)
 .. controls (-68.89,235.36) and (-69.51,236.49) .. (-69.51,236.49)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-115.51,230.72)
 .. controls (-113.88,230.97) and (-110.80,230.60) .. (-108.42,231.07)
 .. controls (-106.03,231.54) and (-105.46,231.75) .. (-104.02,231.71)
 .. controls (-102.58,231.66) and (-100.20,232.32) .. (-97.93,233.17)
 .. controls (-95.65,234.02) and (-91.48,235.42) .. (-90.90,235.34)
 .. controls (-90.32,235.27) and (-88.90,235.99) .. (-87.67,233.83)
 .. controls (-86.44,231.66) and (-83.99,230.22) .. (-86.34,228.88)
 .. controls (-88.70,227.55) and (-87.25,227.41) .. (-91.14,226.11)
 .. controls (-95.04,224.82) and (-93.96,224.29) .. (-97.11,223.79)
 .. controls (-100.26,223.30) and (-100.57,223.86) .. (-103.33,223.00)
 .. controls (-106.08,222.13) and (-108.71,220.60) .. (-109.94,219.98)
 .. controls (-111.17,219.36) and (-111.92,218.86) .. (-114.77,218.18)
 .. controls (-117.63,217.50) and (-120.46,216.15) .. (-122.07,215.71)
 .. controls (-123.69,215.27) and (-127.02,214.58) .. (-127.02,214.58)
 .. controls (-127.02,214.58) and (-129.45,215.45) .. (-129.49,216.41)
 .. controls (-129.52,217.37) and (-129.08,221.13) .. (-129.08,221.13)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-108.02,230.60)
 .. controls (-107.03,229.78) and (-106.15,229.62) .. (-105.25,228.59)
 .. controls (-104.35,227.57) and (-103.35,226.55) .. (-103.04,225.89)
 .. controls (-102.73,225.23) and (-102.70,224.17) .. (-102.70,224.17)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-98.93,231.70)
 .. controls (-97.17,230.80) and (-96.89,231.00) .. (-96.27,229.97)
 .. controls (-95.66,228.93) and (-95.08,228.86) .. (-94.95,227.90)
 .. controls (-94.82,226.95) and (-94.21,225.91) .. (-94.21,225.91)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-121.46,225.43)
 .. controls (-119.78,224.24) and (-119.31,224.45) .. (-118.60,223.23)
 .. controls (-117.88,222.00) and (-117.47,221.25) .. (-117.45,220.58)
 .. controls (-117.42,219.91) and (-117.09,218.67) .. (-117.09,218.67)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-33.01,244.34)
 .. controls (-32.89,243.57) and (-32.72,241.66) .. (-33.08,240.87)
 .. controls (-33.44,240.09) and (-34.72,238.51) .. (-34.97,237.35)
 .. controls (-35.22,236.19) and (-35.32,236.28) .. (-35.71,233.96)
 .. controls (-36.11,231.64) and (-35.06,231.77) .. (-36.07,230.49)
 .. controls (-37.08,229.21) and (-38.55,227.33) .. (-38.55,227.33)
));
ATTR__id := "l474-81252-77188";
ATTR__height := -1;
drawoptions();
l_flowstone(((-31.60,247.84)
 .. controls (-30.16,245.21) and (-29.33,243.51) .. (-29.38,242.25)
 .. controls (-29.43,241.00) and (-29.48,239.66) .. (-30.00,238.01)
 .. controls (-30.52,236.35) and (-30.85,235.00) .. (-30.91,233.84)
 .. controls (-30.96,232.69) and (-31.39,231.23) .. (-31.36,230.37)
 .. controls (-31.33,229.50) and (-31.38,225.47) .. (-31.38,225.47)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((-27.21,243.39)
 -- (-22.74,244.51)
 -- (-21.31,250.32)
 -- (-24.71,251.55)
 -- (-27.19,248.19)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-24.71,251.55)
 -- (-24.69,248.09)
 -- (-21.31,250.32)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-24.69,248.09)
 -- (-27.21,243.39)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-20.71,252.55)
 -- (-17.95,250.54)
 -- (-14.44,254.41)
 -- (-16.83,256.72)
 -- (-19.27,255.20)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-16.83,256.72)
 -- (-17.75,252.85)
 -- (-14.44,254.41)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-17.75,252.85)
 -- (-20.71,252.55)
));
ATTR__id := "l518-83180-77204";
ATTR__height := -1;
drawoptions();
l_floorstep(((2.34,225.62)
 .. controls (2.58,227.07) and (2.31,229.36) .. (2.25,230.90)
 .. controls (2.20,232.43) and (0.85,232.58) .. (2.73,233.70)
 .. controls (4.61,234.83) and (4.90,234.74) .. (7.26,235.88)
 .. controls (9.62,237.02) and (8.67,236.89) .. (12.29,237.60)
 .. controls (15.91,238.30) and (17.41,236.72) .. (18.58,236.29)
 .. controls (19.75,235.85) and (20.66,234.54) .. (22.29,234.59)
 .. controls (23.92,234.65) and (24.50,234.67) .. (26.23,234.45)
 .. controls (27.97,234.22) and (29.15,233.59) .. (29.84,233.04)
 .. controls (30.53,232.49) and (31.33,231.65) .. (32.02,231.10)
 .. controls (32.71,230.55) and (34.76,229.76) .. (34.76,229.76)
));
ATTR__id := "l522-83824-73780";
ATTR__height := -1;
drawoptions();
l_border_visible(((14.70,156.70)
 .. controls (19.42,156.39) and (20.42,155.37) .. (22.84,154.78)
 .. controls (25.26,154.20) and (24.81,153.51) .. (28.22,154.59)
 .. controls (31.64,155.68) and (32.00,156.26) .. (33.93,156.24)
 .. controls (35.85,156.21) and (37.40,155.69) .. (37.98,155.62)
 .. controls (38.56,155.54) and (43.41,156.86) .. (43.41,156.86)
));
ATTR__id := "l532-83760-71320";
ATTR__height := -1;
drawoptions();
l_pit(((33.35,91.57)
 .. controls (32.94,92.42) and (33.28,93.59) .. (33.62,94.75)
 .. controls (33.96,95.92) and (34.05,96.31) .. (34.31,96.99)
 .. controls (34.57,97.67) and (36.82,99.29) .. (36.82,99.29)
));
ATTR__id := "l534-83324-70712";
ATTR__height := -1;
drawoptions();
l_border_visible(((12.76,81.90)
 .. controls (15.80,83.06) and (14.24,83.59) .. (16.75,83.20)
 .. controls (19.26,82.81) and (19.38,82.23) .. (21.78,82.22)
 .. controls (24.18,82.21) and (25.23,82.35) .. (25.81,82.37)
 .. controls (26.38,82.39) and (28.31,82.36) .. (28.31,82.36)
));
ATTR__id := "l538-83724-67728";
ATTR__height := -1;
drawoptions();
l_pit(((35.33,4.21)
 .. controls (36.17,5.01) and (36.06,8.08) .. (36.31,9.15)
 .. controls (36.56,10.21) and (37.70,13.23) .. (37.87,13.82)
));
ATTR__id := "l541-83408-67348";
ATTR__height := -1;
drawoptions();
l_pit(((32.11,0.16)
 .. controls (32.11,0.16) and (30.95,0.50) .. (30.06,1.05)
 .. controls (29.18,1.59) and (28.10,2.32) .. (27.61,2.50)
 .. controls (27.12,2.67) and (26.54,2.94) .. (25.95,3.21)
 .. controls (25.37,3.47) and (23.15,3.78) .. (23.15,3.78)
));
ATTR__id := "l500-83008-66276";
ATTR__height := -1;
drawoptions();
l_floorstep(((29.23,-8.01)
 .. controls (29.23,-8.01) and (28.60,-9.09) .. (28.22,-9.30)
 .. controls (27.84,-9.50) and (27.10,-10.20) .. (26.35,-10.80)
 .. controls (25.61,-11.40) and (25.34,-11.89) .. (24.59,-12.50)
 .. controls (23.84,-13.10) and (23.67,-13.78) .. (22.65,-14.58)
 .. controls (21.62,-15.39) and (21.26,-16.17) .. (20.82,-17.14)
 .. controls (20.37,-18.12) and (20.33,-19.56) .. (20.26,-20.52)
 .. controls (20.20,-21.49) and (20.74,-23.19) .. (20.87,-24.05)
 .. controls (21.00,-24.91) and (21.14,-26.16) .. (21.15,-26.64)
 .. controls (21.17,-27.12) and (21.95,-27.91) .. (24.95,-28.04)
 .. controls (26.20,-28.09) and (26.10,-28.00) .. (27.47,-28.62)
 .. controls (28.83,-29.24) and (28.16,-29.17) .. (31.59,-31.26)
));
ATTR__id := "l504-83088-64864";
ATTR__height := -1;
drawoptions();
l_floorstep(((29.54,-51.79)
 .. controls (29.54,-51.79) and (27.67,-53.20) .. (27.11,-53.60)
 .. controls (26.55,-54.01) and (26.11,-55.08) .. (25.19,-56.17)
 .. controls (24.26,-57.26) and (24.18,-57.65) .. (24.11,-58.42)
 .. controls (24.05,-59.19) and (24.37,-60.04) .. (24.77,-60.61)
 .. controls (25.18,-61.17) and (25.52,-62.60) .. (25.76,-63.94)
 .. controls (26.00,-65.28) and (26.89,-66.01) .. (27.89,-67.04)
 .. controls (28.88,-68.06) and (28.98,-68.06) .. (29.97,-68.79)
 .. controls (30.95,-69.52) and (31.64,-70.08) .. (32.41,-70.05)
 .. controls (33.18,-70.02) and (33.45,-69.63) .. (34.31,-69.31)
 .. controls (35.16,-68.99) and (34.27,-68.25) .. (34.61,-67.09)
 .. controls (34.95,-65.92) and (34.62,-64.68) .. (34.47,-63.05)
 .. controls (34.31,-61.42) and (34.78,-61.21) .. (34.23,-59.31)
));
ATTR__id := "l506-84980-63964";
ATTR__height := -1;
drawoptions();
l_border_visible(((28.55,-96.41)
 .. controls (36.27,-94.79) and (38.26,-96.54) .. (40.70,-97.61)
 .. controls (43.14,-98.67) and (45.43,-100.90) .. (46.57,-103.16)
 .. controls (47.70,-105.43) and (50.42,-108.79) .. (51.41,-109.61)
 .. controls (52.40,-110.44) and (54.63,-113.63) .. (55.41,-114.18)
 .. controls (56.20,-114.73) and (62.66,-118.14) .. (64.23,-118.95)
 .. controls (65.79,-119.76) and (74.24,-119.65) .. (75.96,-119.20)
 .. controls (77.67,-118.76) and (82.65,-118.39) .. (82.08,-115.82)
 .. controls (81.51,-113.24) and (80.82,-107.41) .. (79.40,-105.44)
 .. controls (77.99,-103.48) and (75.52,-101.64) .. (74.41,-100.24)
 .. controls (73.31,-98.84) and (70.47,-94.91) .. (70.30,-92.80)
 .. controls (70.13,-90.69) and (69.41,-89.37) .. (69.46,-85.53)
 .. controls (69.52,-81.69) and (69.32,-78.71) .. (70.95,-76.16)
 .. controls (72.59,-73.60) and (73.01,-71.95) .. (74.47,-69.88)
 .. controls (75.94,-67.81) and (77.87,-65.44) .. (77.89,-63.32)
));
ATTR__id := "l508-83380-54796";
ATTR__height := -1;
drawoptions();
l_pit(((33.27,-308.37)
 .. controls (33.27,-308.37) and (38.92,-301.31) .. (40.07,-299.15)
 .. controls (41.22,-296.98) and (41.31,-294.77) .. (41.58,-292.26)
 .. controls (41.85,-289.75) and (40.18,-286.84) .. (39.02,-284.39)
 .. controls (37.85,-281.94) and (37.01,-280.44) .. (34.92,-278.80)
 .. controls (32.83,-277.17) and (32.50,-274.21) .. (32.23,-272.60)
 .. controls (31.96,-270.98) and (29.25,-268.52) .. (28.20,-266.55)
 .. controls (27.14,-264.59) and (25.95,-261.68) .. (25.14,-260.85)
 .. controls (24.33,-260.03) and (22.88,-253.86) .. (22.71,-252.33)
 .. controls (22.54,-250.80) and (23.55,-247.78) .. (24.21,-245.44)
 .. controls (24.88,-243.10) and (27.92,-240.26) .. (28.92,-238.97)
 .. controls (29.92,-237.67) and (32.32,-233.00) .. (33.95,-228.37)
 .. controls (35.59,-223.70) and (35.73,-224.58) .. (37.16,-222.56)
 .. controls (38.60,-220.55) and (39.93,-218.74) .. (42.25,-217.48)
 .. controls (44.56,-216.22) and (46.05,-214.24) .. (46.89,-213.25)
 .. controls (47.73,-212.25) and (49.20,-207.29) .. (49.53,-205.74)
 .. controls (49.87,-204.19) and (49.84,-198.04) .. (49.96,-195.93)
 .. controls (50.08,-193.81) and (50.24,-190.15) .. (50.53,-187.55)
 .. controls (50.83,-184.94) and (51.80,-182.70) .. (52.34,-181.43)
 .. controls (52.87,-180.16) and (54.36,-176.26) .. (54.62,-175.49)
 .. controls (54.89,-174.71) and (58.13,-168.74) .. (59.65,-165.42)
 .. controls (61.16,-162.10) and (61.20,-160.46) .. (61.61,-158.62)
 .. controls (62.02,-156.78) and (61.16,-154.13) .. (61.36,-151.81)
 .. controls (61.57,-149.50) and (61.30,-147.20) .. (60.16,-144.94)
 .. controls (59.02,-142.67) and (57.74,-141.86) .. (56.93,-140.44)
 .. controls (56.11,-139.03) and (55.12,-138.20) .. (53.55,-137.20)
 .. controls (51.97,-136.20) and (48.97,-135.35) .. (47.41,-134.92)
 .. controls (45.86,-134.50) and (42.07,-133.19) .. (40.04,-132.88)
 .. controls (38.01,-132.57) and (37.69,-131.72) .. (34.41,-131.16)
 .. controls (31.12,-130.61) and (30.51,-129.58) .. (27.11,-128.64)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_pit(((110.45,-181.58)
 .. controls (111.12,-178.77) and (112.01,-176.72) .. (111.92,-174.13)
 .. controls (111.83,-171.54) and (112.25,-169.80) .. (113.16,-168.42)
 .. controls (114.07,-167.04) and (115.16,-165.18) .. (115.89,-164.09)
 .. controls (116.62,-163.01) and (118.75,-160.82) .. (120.24,-159.52)
 .. controls (121.73,-158.21) and (125.40,-156.16) .. (125.87,-155.76)
));
ATTR__id := "l548-82752-69256";
ATTR__height := -1;
drawoptions();
l_border_visible(((9.49,47.00)
 .. controls (11.03,46.96) and (14.02,46.58) .. (14.02,46.58)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((18.12,79.98)
 -- (18.92,76.26)
 -- (22.26,76.96)
 -- (24.07,80.10)
 -- (19.59,81.57)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((22.26,76.96)
 -- (20.56,78.82)
 -- (24.07,80.10)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((20.56,78.82)
 -- (18.12,79.98)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((24.61,78.29)
 -- (25.05,74.27)
 -- (29.52,75.39)
 -- (27.86,78.70)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((25.05,74.27)
 -- (26.61,76.15)
 -- (29.52,75.39)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((26.61,76.15)
 -- (24.61,78.29)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((13.68,72.52)
 -- (15.76,67.88)
 -- (22.67,68.23)
 -- (24.93,72.25)
 -- (17.56,74.20)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((22.67,68.23)
 -- (21.44,70.30)
 -- (24.93,72.25)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((21.44,70.30)
 -- (13.68,72.52)
));
ATTR__id := "l262-83352-66564";
ATTR__height := -1;
drawoptions();
l_pit(((34.37,-25.59)
 .. controls (33.76,-24.65) and (32.27,-23.17) .. (32.21,-21.63)
 .. controls (32.16,-20.10) and (31.38,-19.84) .. (30.77,-19.00)
 .. controls (30.17,-18.15) and (29.59,-18.08) .. (29.09,-17.62)
 .. controls (28.60,-17.15) and (27.97,-15.74) .. (27.45,-14.70)
));
ATTR__id := "l533-83532-70592";
ATTR__height := -1;
drawoptions();
l_pit(((31.82,72.98)
 .. controls (31.51,73.54) and (31.29,74.30) .. (30.76,75.73)
 .. controls (30.23,77.15) and (30.44,76.68) .. (30.29,78.02)
 .. controls (30.15,79.36) and (29.14,80.47) .. (29.14,80.47)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockedge(((-102.97,239.81)
 -- (-103.60,236.14)
 -- (-99.89,234.35)
 -- (-96.43,236.87)
 -- (-99.10,241.87)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-99.89,234.35)
 .. controls (-99.80,234.64) and (-100.59,237.88) .. (-100.59,237.88)
 -- (-96.43,236.87)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-100.59,237.88)
 -- (-102.97,239.81)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-95.04,243.65)
 -- (-93.90,241.48)
 -- (-90.96,239.76)
 -- (-88.16,242.16)
 -- (-91.70,244.24)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-90.96,239.76)
 .. controls (-91.18,240.61) and (-91.70,241.75) .. (-91.70,241.75)
 -- (-88.16,242.16)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-91.70,241.75)
 .. controls (-92.19,241.92) and (-95.04,243.65) .. (-95.04,243.65)
));
ATTR__id := "l528-83268-73568";
ATTR__height := -1;
drawoptions();
l_ceilingstep(((15.73,154.81)
 .. controls (18.02,152.79) and (19.05,153.40) .. (20.38,151.24)
 .. controls (21.70,149.08) and (21.49,149.74) .. (22.22,147.95)
 .. controls (22.96,146.15) and (23.10,144.81) .. (23.10,144.81)
));
ATTR__id := "l530-82228-59348";
ATTR__height := -1;
drawoptions();
l_ceilingstep(((12.98,-156.64)
 .. controls (14.50,-158.89) and (14.25,-157.07) .. (15.01,-159.93)
 .. controls (15.78,-162.79) and (15.82,-164.04) .. (15.79,-165.96)
 .. controls (15.76,-167.89) and (17.03,-171.49) .. (17.44,-172.34)
 .. controls (17.85,-173.19) and (18.08,-174.34) .. (17.96,-176.56)
 .. controls (17.84,-178.78) and (17.85,-179.26) .. (16.67,-181.42)
 .. controls (15.48,-183.59) and (14.74,-184.58) .. (13.99,-185.38)
 .. controls (13.24,-186.19) and (9.95,-189.21) .. (9.58,-189.81)
 .. controls (9.21,-190.40) and (7.60,-191.44) .. (6.76,-192.34)
 .. controls (5.92,-193.25) and (2.14,-196.11) .. (2.14,-196.11)
));
ATTR__id := "l527-81868-57988";
ATTR__height := -1;
drawoptions();
l_ceilingstep(((0.69,-202.57)
 .. controls (0.69,-202.57) and (0.96,-205.37) .. (0.97,-205.95)
 .. controls (0.99,-206.53) and (0.56,-208.49) .. (0.51,-210.14)
 .. controls (0.46,-211.79) and (0.33,-210.73) .. (-0.69,-215.04)
 .. controls (-1.70,-219.36) and (-1.10,-217.20) .. (-1.03,-219.23)
 .. controls (-0.97,-221.27) and (-0.14,-223.08) .. (0.19,-224.33)
 .. controls (0.52,-225.57) and (0.57,-227.02) .. (1.02,-228.94)
 .. controls (1.48,-230.86) and (2.25,-231.03) .. (2.48,-236.91)
));
ATTR__id := "l528-83004-55588";
ATTR__height := -1;
drawoptions();
l_ceilingstep(((2.40,-239.52)
 .. controls (2.40,-239.52) and (6.91,-239.73) .. (7.48,-239.80)
 .. controls (8.06,-239.87) and (11.03,-242.06) .. (11.03,-242.06)
 .. controls (11.03,-242.06) and (13.79,-245.99) .. (14.28,-246.36)
 .. controls (14.78,-246.72) and (15.92,-250.71) .. (16.27,-251.94)
 .. controls (16.61,-253.17) and (17.82,-256.38) .. (18.94,-257.77)
 .. controls (20.06,-259.16) and (22.58,-263.46) .. (23.18,-264.00)
 .. controls (23.78,-264.55) and (25.91,-268.95) .. (26.53,-269.78)
 .. controls (27.15,-270.62) and (28.07,-273.93) .. (28.52,-275.34)
 .. controls (28.97,-276.76) and (29.40,-280.00) .. (29.64,-280.95)
 .. controls (29.87,-281.90) and (30.21,-285.05) .. (30.29,-286.97)
 .. controls (30.38,-288.89) and (30.16,-290.44) .. (30.40,-291.67)
 .. controls (30.65,-292.91) and (30.34,-294.47) .. (28.38,-297.91)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((106.27,-268.17) -- (123.40,-220.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((106.27,-268.17) -- (68.03,-283.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((68.03,-283.76) -- (68.03,-283.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((68.03,-283.76) -- (106.27,-268.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((68.03,-283.76) -- (35.02,-249.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((35.02,-249.94) -- (68.03,-283.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((57.39,-259.29) -- (70.97,-212.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((57.39,-259.29) -- (68.03,-283.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((70.97,-212.61) -- (77.06,-187.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((70.97,-212.61) -- (57.39,-259.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((77.06,-187.80) -- (97.56,-181.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((77.06,-187.80) -- (70.97,-212.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((97.56,-181.42) -- (94.67,-155.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((97.56,-181.42) -- (77.06,-187.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((94.67,-155.62) -- (90.57,-109.27)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((94.67,-155.62) -- (97.56,-181.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((90.57,-109.27) -- (49.96,-107.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((90.57,-109.27) -- (94.67,-155.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((49.96,-107.22) -- (42.25,-86.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((49.96,-107.22) -- (90.57,-109.27)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((42.25,-86.47) -- (15.85,-75.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((42.25,-86.47) -- (49.96,-107.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.85,-75.29) -- (15.16,-52.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.85,-75.29) -- (42.25,-86.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.16,-52.22) -- (19.89,-32.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.16,-52.22) -- (15.85,-75.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((19.89,-32.18) -- (21.77,-0.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((19.89,-32.18) -- (15.16,-52.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((21.77,-0.76) -- (36.67,17.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((21.77,-0.76) -- (19.89,-32.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((36.67,17.31) -- (15.10,47.20)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((36.67,17.31) -- (21.77,-0.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.10,47.20) -- (15.42,73.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.10,47.20) -- (36.67,17.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.42,73.07) -- (36.24,113.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.42,73.07) -- (15.10,47.20)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((36.24,113.02) -- (30.65,144.87)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((36.24,113.02) -- (15.42,73.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((30.65,144.87) -- (27.82,167.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((30.65,144.87) -- (36.24,113.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((27.82,167.10) -- (23.79,189.49)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((27.82,167.10) -- (30.65,144.87)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((23.79,189.49) -- (32.13,220.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((23.79,189.49) -- (27.82,167.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.13,220.36) -- (-15.40,262.91)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((32.13,220.36) -- (23.79,189.49)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-15.40,262.91) -- (-32.78,230.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-15.40,262.91) -- (32.13,220.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-32.78,230.05) -- (-54.18,241.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-32.78,230.05) -- (-15.40,262.91)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-54.18,241.84) -- (-56.99,241.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-54.18,241.84) -- (-32.78,230.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-56.99,241.52) -- (-59.98,224.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-56.99,241.52) -- (-54.18,241.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-59.98,224.21) -- (-92.36,229.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-59.98,224.21) -- (-56.99,241.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-92.36,229.77) -- (-111.24,220.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-92.36,229.77) -- (-59.98,224.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-111.24,220.18) -- (-113.26,229.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-111.24,220.18) -- (-92.36,229.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-113.26,229.92) -- (-148.54,222.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-113.26,229.92) -- (-111.24,220.18)));
endfig;
beginfig(2);
draw_upscrap(1)(1,((32.47,277.70)
 .. controls (32.41,273.86) and (31.89,272.21) .. (33.30,270.43)
 .. controls (34.71,268.66) and (35.94,266.49) .. (35.74,264.08)
 .. controls (35.54,261.68) and (35.07,258.59) .. (35.34,256.39)
 .. controls (35.61,254.19) and (35.47,247.46) .. (35.06,245.62)
 .. controls (34.64,243.78) and (32.81,233.15) .. (32.77,231.51)
 .. controls (32.74,229.88) and (32.51,222.86) .. (32.70,220.27)
 .. controls (32.88,217.68) and (34.12,212.73) .. (34.17,211.29)
 .. controls (34.22,209.85) and (34.18,205.62) .. (34.31,204.76)
 .. controls (34.43,203.90) and (35.46,204.71) .. (36.04,201.85)
 .. controls (36.63,198.99) and (34.94,194.99) .. (35.92,194.44)
 .. controls (36.90,193.90) and (37.97,190.96) .. (38.25,188.38)
 .. controls (38.54,185.79) and (39.39,178.14) .. (39.07,176.30)
 .. controls (38.75,174.46) and (37.90,171.36) .. (38.82,169.76)
 .. controls (39.74,168.16) and (39.65,167.96) .. (39.35,165.55)
 .. controls (39.06,163.14) and (38.91,161.98) .. (39.75,160.00)
 .. controls (40.59,158.01) and (42.01,155.85) .. (41.89,153.93)
 .. controls (41.76,152.01) and (42.71,152.42) .. (44.43,150.08)
 .. controls (46.14,147.74) and (43.61,143.33) .. (41.63,139.71)
 .. controls (39.64,136.08) and (38.86,130.96) .. (38.46,128.74)
 .. controls (38.06,126.51) and (36.21,121.84) .. (36.41,118.77)
 .. controls (36.61,115.70) and (37.13,112.07) .. (37.21,109.67)
 .. controls (37.30,107.28) and (35.97,104.25) .. (36.16,101.66)
 .. controls (36.35,99.08) and (34.90,99.41) .. (36.62,96.97)
 .. controls (38.34,94.54) and (39.88,89.02) .. (39.23,85.83)
 .. controls (38.58,82.64) and (38.19,77.43) .. (33.00,74.94)
 .. controls (27.80,72.45) and (28.31,71.79) .. (26.85,66.84)
 .. controls (25.40,61.88) and (26.01,57.97) .. (26.07,56.33)
 .. controls (26.13,54.70) and (25.53,47.28) .. (26.17,45.48)
 .. controls (26.81,43.68) and (27.76,41.12) .. (30.58,42.85)
 .. controls (33.40,44.59) and (38.25,46.01) .. (39.88,46.07)
 .. controls (41.52,46.13) and (42.11,45.47) .. (42.51,45.10)
 .. controls (42.91,44.73) and (43.11,44.55) .. (44.38,46.71)
 .. controls (45.64,48.87) and (44.79,45.86) .. (45.86,45.42)
 .. controls (46.94,44.97) and (47.88,45.49) .. (46.27,41.97)
 .. controls (44.67,38.46) and (41.26,34.40) .. (41.36,31.52)
 .. controls (41.47,28.64) and (40.13,23.12) .. (39.86,22.53)
),
1,reverse ((117.93,-212.20)
 .. controls (117.26,-212.23) and (118.57,-205.28) .. (118.43,-203.76)
 .. controls (118.28,-202.23) and (120.98,-191.29) .. (121.25,-188.30)
 .. controls (121.53,-185.31) and (123.81,-173.61) .. (124.69,-171.37)
 .. controls (125.57,-169.13) and (124.21,-155.05) .. (124.04,-152.85)
 .. controls (123.86,-150.64) and (121.89,-146.49) .. (121.33,-144.30)
 .. controls (120.77,-142.11) and (120.44,-135.49) .. (119.68,-133.11)
 .. controls (118.92,-130.74) and (120.19,-117.91) .. (121.09,-113.56)
 .. controls (121.99,-109.20) and (119.40,-98.34) .. (118.73,-95.77)
 .. controls (118.06,-93.20) and (116.49,-87.11) .. (112.85,-79.27)
 .. controls (109.21,-71.42) and (94.29,-67.92) .. (92.58,-68.46)
 .. controls (90.87,-69.01) and (72.09,-62.38) .. (69.67,-61.89)
 .. controls (67.25,-61.40) and (56.58,-55.83) .. (53.36,-54.21)
 .. controls (50.13,-52.60) and (49.70,-54.15) .. (48.84,-54.08)
 .. controls (47.97,-54.02) and (39.31,-58.84) .. (35.51,-60.13)
 .. controls (31.72,-61.42) and (31.27,-59.70) .. (30.25,-57.91)
 .. controls (29.22,-56.12) and (26.41,-50.07) .. (27.19,-47.93)
 .. controls (27.98,-45.79) and (28.89,-41.73) .. (28.71,-36.45)
 .. controls (28.52,-31.18) and (34.49,-20.98) .. (35.73,-18.05)
 .. controls (36.98,-15.13) and (38.31,-12.10) .. (38.25,-10.38)
 .. controls (38.19,-8.65) and (38.21,-6.63) .. (38.86,-5.94)
 .. controls (39.51,-5.24) and (40.22,-3.58) .. (39.94,-1.19)
 .. controls (39.66,1.20) and (40.50,2.09) .. (40.84,3.16)
 .. controls (41.19,4.23) and (41.72,8.29) .. (40.97,10.28)
 .. controls (40.23,12.27) and (37.93,12.09) .. (36.76,12.43)
 .. controls (35.60,12.77) and (36.42,14.15) .. (36.37,15.39)
 .. controls (36.33,16.64) and (37.32,18.31) .. (37.32,18.31)
 .. controls (37.32,18.31) and (38.13,19.88) .. (38.97,20.48)
 .. controls (39.82,21.09) and (39.86,22.53) .. (39.86,22.53)
),
1,reverse ((15.17,-158.87)
 .. controls (15.17,-158.87) and (11.94,-160.04) .. (10.20,-162.90)
 .. controls (8.45,-165.78) and (8.20,-166.34) .. (6.75,-169.29)
 .. controls (5.28,-172.28) and (3.92,-174.31) .. (3.78,-176.14)
 .. controls (3.64,-177.98) and (2.56,-182.24) .. (3.08,-185.05)
 .. controls (3.88,-189.36) and (5.63,-189.78) .. (5.06,-193.67)
 .. controls (4.61,-196.76) and (1.56,-203.01) .. (1.01,-204.01)
 .. controls (0.46,-205.00) and (-0.38,-205.81) .. (-3.02,-207.57)
 .. controls (-5.65,-209.32) and (-8.15,-212.53) .. (-8.53,-215.65)
 .. controls (-8.90,-218.77) and (-8.74,-220.70) .. (-7.40,-223.56)
 .. controls (-6.05,-226.41) and (-4.48,-230.03) .. (-3.30,-230.86)
 .. controls (-2.12,-231.68) and (-0.07,-232.95) .. (1.20,-233.58)
 .. controls (2.47,-234.21) and (2.94,-234.09) .. (2.99,-235.15)
 .. controls (3.03,-236.21) and (4.15,-237.91) .. (4.08,-238.59)
 .. controls (4.02,-239.26) and (2.85,-251.92) .. (4.48,-256.08)
 .. controls (6.11,-260.23) and (7.94,-266.57) .. (8.86,-267.68)
 .. controls (9.77,-268.79) and (11.81,-273.29) .. (11.96,-274.62)
 .. controls (12.12,-275.96) and (15.19,-282.24) .. (16.99,-283.89)
 .. controls (18.79,-285.54) and (21.03,-290.53) .. (24.96,-292.48)
 .. controls (28.89,-294.43) and (29.02,-295.10) .. (29.33,-295.56)
 .. controls (29.64,-296.03) and (34.59,-307.84) .. (36.91,-310.05)
 .. controls (39.22,-312.25) and (38.13,-313.74) .. (38.53,-314.01)
 .. controls (38.93,-314.28) and (42.98,-312.47) .. (44.95,-311.23)
 .. controls (46.91,-309.99) and (48.69,-308.86) .. (50.86,-310.10)
 .. controls (53.04,-311.35) and (55.01,-312.41) .. (55.38,-314.32)
 .. controls (55.76,-316.22) and (57.15,-319.42) .. (57.15,-319.42)
 .. controls (57.15,-319.42) and (58.60,-317.44) .. (61.58,-317.49)
 .. controls (64.57,-317.55) and (67.40,-316.46) .. (67.61,-316.83)
 .. controls (67.82,-317.21) and (68.96,-321.19) .. (68.96,-321.19)
 .. controls (68.96,-321.19) and (72.65,-321.98) .. (74.10,-320.18)
 .. controls (75.56,-318.39) and (76.58,-315.46) .. (76.78,-313.43)
 .. controls (76.98,-311.40) and (76.05,-305.87) .. (77.17,-305.05)
 .. controls (78.28,-304.23) and (84.09,-298.86) .. (84.81,-297.87)
 .. controls (85.53,-296.87) and (88.98,-292.48) .. (89.92,-292.15)
 .. controls (90.87,-291.82) and (95.09,-289.70) .. (95.44,-288.82)
 .. controls (95.78,-287.94) and (100.22,-282.06) .. (100.92,-280.68)
 .. controls (101.63,-279.30) and (105.48,-273.26) .. (106.14,-273.04)
 .. controls (106.80,-272.82) and (105.83,-278.72) .. (105.48,-279.60)
 .. controls (105.14,-280.49) and (105.29,-283.75) .. (107.23,-282.12)
 .. controls (109.18,-280.49) and (110.16,-278.81) .. (111.43,-277.21)
 .. controls (112.70,-275.62) and (118.91,-272.73) .. (120.45,-272.85)
 .. controls (121.99,-272.98) and (129.02,-275.35) .. (130.93,-272.86)
 .. controls (132.83,-270.38) and (136.38,-266.10) .. (136.49,-264.27)
 .. controls (136.60,-262.45) and (137.58,-256.38) .. (137.58,-256.38)
),
1,reverse ((12.55,47.49)
 .. controls (14.89,46.52) and (15.34,47.30) .. (14.67,44.59)
 .. controls (14.00,41.87) and (15.31,40.10) .. (15.97,37.81)
 .. controls (16.63,35.53) and (19.87,28.25) .. (20.24,25.86)
 .. controls (20.61,23.47) and (21.69,20.25) .. (21.08,18.69)
 .. controls (20.46,17.13) and (22.87,16.93) .. (23.71,14.94)
 .. controls (24.55,12.95) and (26.99,11.79) .. (27.04,10.45)
 .. controls (27.09,9.11) and (23.41,1.67) .. (22.85,1.27)
 .. controls (22.29,0.86) and (19.74,-8.35) .. (19.25,-10.86)
 .. controls (18.76,-13.38) and (14.15,-29.57) .. (13.99,-30.54)
 .. controls (13.84,-31.50) and (13.57,-37.56) .. (14.19,-41.58)
 .. controls (14.81,-45.59) and (13.90,-49.75) .. (12.46,-52.40)
 .. controls (11.02,-55.05) and (6.94,-61.83) .. (6.04,-63.49)
 .. controls (5.14,-65.16) and (4.37,-67.78) .. (5.02,-69.88)
 .. controls (5.67,-71.97) and (10.55,-74.00) .. (11.34,-74.55)
 .. controls (12.13,-75.10) and (18.21,-78.43) .. (19.49,-79.45)
 .. controls (20.78,-80.46) and (26.66,-83.90) .. (28.27,-88.54)
 .. controls (29.88,-93.19) and (31.31,-95.64) .. (30.45,-103.84)
 .. controls (29.59,-112.03) and (31.84,-115.79) .. (31.17,-118.51)
 .. controls (30.50,-121.22) and (29.35,-132.02) .. (29.14,-134.24)
 .. controls (28.93,-136.45) and (25.11,-145.62) .. (21.65,-148.54)
 .. controls (18.20,-151.45) and (15.23,-157.81) .. (15.17,-158.87)
),
1,reverse ((12.76,44.13)
 -- (12.61,45.86)
 -- (12.55,47.49)
),
1,reverse ((12.91,42.70)
 -- (12.88,43.47)
),
1,reverse ((11.44,43.51)
 -- (11.37,42.93)
),
1,((11.39,44.85)
 .. controls (11.39,44.85) and (11.52,46.68) .. (11.58,47.55)
),
1,reverse ((24.45,144.76)
 .. controls (23.84,140.23) and (22.28,132.87) .. (21.39,130.82)
 .. controls (20.50,128.77) and (18.19,123.50) .. (19.39,122.01)
 .. controls (20.60,120.51) and (24.73,120.37) .. (24.29,116.42)
 .. controls (23.86,112.46) and (18.82,108.34) .. (18.66,104.78)
 .. controls (18.50,101.22) and (18.06,92.08) .. (17.28,89.94)
 .. controls (16.49,87.80) and (14.13,83.97) .. (14.12,81.56)
 .. controls (14.11,79.16) and (13.61,74.53) .. (12.27,74.20)
 .. controls (10.94,73.86) and (10.80,66.94) .. (10.57,65.20)
 .. controls (10.35,63.46) and (9.95,58.45) .. (10.04,55.86)
 .. controls (10.13,53.27) and (8.42,49.94) .. (9.52,48.92)
 .. controls (10.61,47.90) and (11.58,47.55) .. (11.58,47.55)
),
1,reverse ((17.99,142.71)
 .. controls (18.92,143.70) and (19.55,144.78) .. (19.91,145.37)
 .. controls (20.28,145.96) and (20.74,146.55) .. (21.31,146.76)
 .. controls (21.87,146.97) and (22.36,146.70) .. (22.85,146.53)
 .. controls (23.34,146.35) and (24.45,144.76) .. (24.45,144.76)
),
1,reverse ((16.94,153.42)
 .. controls (16.48,152.83) and (15.65,151.93) .. (15.19,151.34)
 .. controls (14.73,150.75) and (13.70,149.94) .. (13.70,149.94)
),
1,reverse ((-126.70,210.85)
 .. controls (-126.70,210.85) and (-124.00,210.65) .. (-122.30,211.19)
 .. controls (-120.59,211.74) and (-117.49,213.67) .. (-116.82,213.60)
 .. controls (-116.14,213.52) and (-115.65,213.16) .. (-116.56,211.78)
 .. controls (-117.47,210.41) and (-117.99,206.16) .. (-118.83,205.37)
 .. controls (-119.66,204.57) and (-120.63,202.14) .. (-120.33,201.67)
 .. controls (-120.02,201.20) and (-119.25,200.94) .. (-117.43,201.19)
 .. controls (-115.62,201.45) and (-114.26,201.21) .. (-112.64,201.27)
 .. controls (-111.01,201.32) and (-106.63,199.66) .. (-104.17,200.70)
 .. controls (-101.71,201.75) and (-99.49,201.35) .. (-96.62,204.52)
 .. controls (-93.76,207.69) and (-90.22,210.88) .. (-88.39,210.85)
 .. controls (-86.56,210.82) and (-84.74,210.98) .. (-82.32,210.39)
 .. controls (-79.89,209.81) and (-71.28,210.79) .. (-69.39,209.03)
 .. controls (-67.50,207.28) and (-66.62,206.93) .. (-67.86,203.81)
 .. controls (-69.09,200.69) and (-69.72,196.73) .. (-67.72,194.59)
 .. controls (-65.72,192.45) and (-66.10,192.25) .. (-63.82,193.10)
 .. controls (-61.55,193.95) and (-58.78,197.12) .. (-57.76,198.02)
 .. controls (-56.73,198.92) and (-50.59,204.33) .. (-49.23,209.28)
 .. controls (-47.87,214.23) and (-45.40,212.30) .. (-45.87,217.18)
 .. controls (-46.33,222.06) and (-47.31,225.39) .. (-44.85,226.34)
 .. controls (-42.39,227.29) and (-41.00,228.68) .. (-38.02,228.41)
 .. controls (-35.03,228.13) and (-36.04,226.94) .. (-33.35,226.94)
 .. controls (-30.67,226.94) and (-31.23,229.41) .. (-29.38,228.61)
 .. controls (-27.53,227.81) and (-26.28,225.27) .. (-24.30,226.20)
 .. controls (-22.32,227.13) and (-18.62,231.40) .. (-16.33,231.67)
 .. controls (-14.03,231.94) and (-14.38,230.97) .. (-11.86,230.39)
 .. controls (-9.34,229.81) and (0.17,227.17) .. (2.68,226.98)
 .. controls (5.18,226.78) and (10.00,223.88) .. (10.98,223.24)
 .. controls (11.96,222.60) and (16.74,220.57) .. (18.08,217.92)
 .. controls (19.42,215.28) and (19.90,212.61) .. (19.03,210.18)
 .. controls (18.15,207.74) and (18.05,205.24) .. (16.91,204.91)
 .. controls (15.77,204.58) and (15.72,206.02) .. (15.83,202.95)
 .. controls (15.94,199.88) and (16.02,194.70) .. (16.02,194.70)
 .. controls (16.02,194.70) and (16.92,196.65) .. (17.40,196.47)
 .. controls (17.89,196.30) and (18.43,194.69) .. (19.02,194.13)
 .. controls (19.62,193.57) and (20.60,193.13) .. (19.49,191.84)
 .. controls (18.38,190.55) and (17.81,187.65) .. (18.32,186.80)
 .. controls (18.83,185.96) and (20.24,181.49) .. (19.33,180.11)
 .. controls (18.42,178.73) and (14.55,176.86) .. (13.65,172.41)
 .. controls (12.76,167.96) and (14.02,162.34) .. (14.37,160.72)
 .. controls (14.71,159.10) and (17.65,155.77) .. (16.94,153.42)
),
1,reverse ((26.63,279.70)
 .. controls (25.98,279.10) and (24.77,278.10) .. (23.00,276.59)
 .. controls (21.23,275.09) and (20.28,274.57) .. (18.47,274.22)
 .. controls (16.66,273.87) and (13.92,269.93) .. (12.54,268.34)
 .. controls (11.15,266.75) and (6.84,269.19) .. (4.59,270.26)
 .. controls (2.34,271.34) and (-1.95,270.61) .. (-3.60,271.03)
 .. controls (-5.25,271.45) and (-8.90,271.51) .. (-10.99,270.96)
 .. controls (-13.09,270.40) and (-15.06,266.58) .. (-17.30,264.78)
 .. controls (-19.55,262.97) and (-20.62,263.60) .. (-22.83,263.52)
 .. controls (-25.04,263.44) and (-26.33,262.05) .. (-28.28,260.16)
 .. controls (-30.23,258.27) and (-35.59,257.50) .. (-37.31,257.16)
 .. controls (-39.03,256.81) and (-44.10,256.34) .. (-46.20,255.88)
 .. controls (-48.30,255.42) and (-52.97,254.57) .. (-55.78,255.05)
 .. controls (-58.58,255.52) and (-59.58,256.54) .. (-64.76,259.13)
 .. controls (-69.95,261.73) and (-73.64,260.25) .. (-75.45,259.90)
 .. controls (-77.27,259.54) and (-82.27,252.21) .. (-85.82,249.16)
 .. controls (-89.08,246.35) and (-93.51,246.58) .. (-95.75,247.46)
 .. controls (-97.99,248.34) and (-98.46,247.94) .. (-99.30,247.43)
 .. controls (-100.15,246.92) and (-105.65,247.58) .. (-108.43,247.58)
 .. controls (-111.21,247.57) and (-113.29,249.32) .. (-115.42,249.72)
 .. controls (-117.54,250.13) and (-121.44,246.44) .. (-123.50,245.11)
 .. controls (-125.57,243.79) and (-125.27,243.42) .. (-125.64,243.02)
 .. controls (-126.01,242.63) and (-128.88,242.43) .. (-129.43,241.93)
 .. controls (-129.99,241.43) and (-131.41,240.71) .. (-132.17,240.68)
 .. controls (-132.94,240.65) and (-133.75,239.28) .. (-138.76,239.68)
 .. controls (-143.77,240.08) and (-140.62,237.98) .. (-141.27,237.29)
 .. controls (-141.91,236.59) and (-140.85,233.75) .. (-140.85,233.75)
),
1,reverse ((50.54,322.64)
 .. controls (50.54,322.64) and (48.50,320.64) .. (47.46,320.22)
 .. controls (46.42,319.80) and (46.27,318.74) .. (45.07,317.25)
 .. controls (43.88,315.77) and (43.52,314.99) .. (42.25,313.02)
 .. controls (40.97,311.05) and (41.27,310.68) .. (40.61,307.77)
 .. controls (39.95,304.87) and (37.99,303.26) .. (35.96,300.98)
 .. controls (33.92,298.70) and (34.91,297.96) .. (34.39,296.41)
 .. controls (33.87,294.85) and (33.23,293.96) .. (31.21,291.30)
 .. controls (29.19,288.63) and (30.03,289.43) .. (29.62,287.49)
 .. controls (29.21,285.56) and (28.65,284.96) .. (28.30,284.08)
 .. controls (27.95,283.21) and (26.81,280.09) .. (26.63,279.70)
),
1,reverse ((32.47,277.70)
 .. controls (33.06,279.84) and (33.36,279.56) .. (34.24,281.70)
 .. controls (35.13,283.85) and (36.30,286.10) .. (36.74,287.17)
 .. controls (37.18,288.25) and (38.81,290.99) .. (39.58,293.62)
 .. controls (40.35,296.24) and (39.97,296.22) .. (39.99,298.34)
 .. controls (40.01,300.45) and (41.20,301.94) .. (41.92,303.50)
 .. controls (42.63,305.06) and (43.24,306.72) .. (43.69,307.60)
 .. controls (44.14,308.48) and (44.50,308.97) .. (45.69,310.65)
 .. controls (46.88,312.32) and (47.72,312.93) .. (48.25,314.29)
 .. controls (48.78,315.66) and (50.54,322.64) .. (50.54,322.64)
));
draw_upscrap(1)(1,((27.45,-14.70)
 .. controls (27.45,-14.70) and (27.93,-11.99) .. (27.82,-11.42)
 .. controls (27.70,-10.85) and (28.30,-8.72) .. (29.23,-8.01)
 .. controls (30.17,-7.31) and (30.61,-6.23) .. (30.96,-5.17)
 .. controls (31.30,-4.10) and (31.07,-3.05) .. (31.04,-2.09)
 .. controls (31.01,-1.13) and (31.57,-0.82) .. (32.11,0.16)
 .. controls (32.65,1.14) and (33.40,1.74) .. (33.85,2.62)
 .. controls (34.30,3.50) and (35.33,4.21) .. (35.33,4.21)
));
draw_upscrap(1)(1,((12.87,41.06)
 -- cycle
));
draw_upscrap(1)(1,((11.40,41.97)
 -- cycle
));
draw_upscrap(1)(1,((33.35,91.57)
 .. controls (32.79,91.27) and (31.48,90.26) .. (30.66,88.88)
 .. controls (29.85,87.51) and (28.94,86.04) .. (28.78,85.17)
 .. controls (28.62,84.30) and (28.28,83.13) .. (28.31,82.36)
 .. controls (28.33,81.60) and (29.14,80.47) .. (29.14,80.47)
 .. controls (29.14,80.47) and (30.75,81.20) .. (31.11,81.98)
 .. controls (31.46,82.77) and (31.90,83.84) .. (32.16,84.71)
 .. controls (32.42,85.59) and (33.03,87.14) .. (33.08,88.39)
 .. controls (33.13,89.65) and (33.92,91.88) .. cycle
));
draw_downscrap;
endfig;
beginfig(3);
ATTR__id := "l166-76892-77516";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((26.63,279.70)
 .. controls (25.98,279.10) and (24.77,278.10) .. (23.00,276.59)
 .. controls (21.23,275.09) and (20.28,274.57) .. (18.47,274.22)
 .. controls (16.66,273.87) and (13.92,269.93) .. (12.54,268.34)
 .. controls (11.15,266.75) and (6.84,269.19) .. (4.59,270.26)
 .. controls (2.34,271.34) and (-1.95,270.61) .. (-3.60,271.03)
 .. controls (-5.25,271.45) and (-8.90,271.51) .. (-10.99,270.96)
 .. controls (-13.09,270.40) and (-15.06,266.58) .. (-17.30,264.78)
 .. controls (-19.55,262.97) and (-20.62,263.60) .. (-22.83,263.52)
 .. controls (-25.04,263.44) and (-26.33,262.05) .. (-28.28,260.16)
 .. controls (-30.23,258.27) and (-35.59,257.50) .. (-37.31,257.16)
 .. controls (-39.03,256.81) and (-44.10,256.34) .. (-46.20,255.88)
 .. controls (-48.30,255.42) and (-52.97,254.57) .. (-55.78,255.05)
 .. controls (-58.58,255.52) and (-59.58,256.54) .. (-64.76,259.13)
 .. controls (-69.95,261.73) and (-73.64,260.25) .. (-75.45,259.90)
 .. controls (-77.27,259.54) and (-82.27,252.21) .. (-85.82,249.16)
 .. controls (-89.08,246.35) and (-93.51,246.58) .. (-95.75,247.46)
 .. controls (-97.99,248.34) and (-98.46,247.94) .. (-99.30,247.43)
 .. controls (-100.15,246.92) and (-105.65,247.58) .. (-108.43,247.58)
 .. controls (-111.21,247.57) and (-113.29,249.32) .. (-115.42,249.72)
 .. controls (-117.54,250.13) and (-121.44,246.44) .. (-123.50,245.11)
 .. controls (-125.57,243.79) and (-125.27,243.42) .. (-125.64,243.02)
 .. controls (-126.01,242.63) and (-128.88,242.43) .. (-129.43,241.93)
 .. controls (-129.99,241.43) and (-131.41,240.71) .. (-132.17,240.68)
 .. controls (-132.94,240.65) and (-133.75,239.28) .. (-138.76,239.68)
 .. controls (-143.77,240.08) and (-140.62,237.98) .. (-141.27,237.29)
 .. controls (-141.91,236.59) and (-140.85,233.75) .. (-140.85,233.75)
));
ATTR__id := "l165-77436-76312";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-126.70,210.85)
 .. controls (-126.70,210.85) and (-124.00,210.65) .. (-122.30,211.19)
 .. controls (-120.59,211.74) and (-117.49,213.67) .. (-116.82,213.60)
 .. controls (-116.14,213.52) and (-115.65,213.16) .. (-116.56,211.78)
 .. controls (-117.47,210.41) and (-117.99,206.16) .. (-118.83,205.37)
 .. controls (-119.66,204.57) and (-120.63,202.14) .. (-120.33,201.67)
 .. controls (-120.02,201.20) and (-119.25,200.94) .. (-117.43,201.19)
 .. controls (-115.62,201.45) and (-114.26,201.21) .. (-112.64,201.27)
 .. controls (-111.01,201.32) and (-106.63,199.66) .. (-104.17,200.70)
 .. controls (-101.71,201.75) and (-99.49,201.35) .. (-96.62,204.52)
 .. controls (-93.76,207.69) and (-90.22,210.88) .. (-88.39,210.85)
 .. controls (-86.56,210.82) and (-84.74,210.98) .. (-82.32,210.39)
 .. controls (-79.89,209.81) and (-71.28,210.79) .. (-69.39,209.03)
 .. controls (-67.50,207.28) and (-66.62,206.93) .. (-67.86,203.81)
 .. controls (-69.09,200.69) and (-69.72,196.73) .. (-67.72,194.59)
 .. controls (-65.72,192.45) and (-66.10,192.25) .. (-63.82,193.10)
 .. controls (-61.55,193.95) and (-58.78,197.12) .. (-57.76,198.02)
 .. controls (-56.73,198.92) and (-50.59,204.33) .. (-49.23,209.28)
 .. controls (-47.87,214.23) and (-45.40,212.30) .. (-45.87,217.18)
 .. controls (-46.33,222.06) and (-47.31,225.39) .. (-44.85,226.34)
 .. controls (-42.39,227.29) and (-41.00,228.68) .. (-38.02,228.41)
 .. controls (-35.03,228.13) and (-36.04,226.94) .. (-33.35,226.94)
 .. controls (-30.67,226.94) and (-31.23,229.41) .. (-29.38,228.61)
 .. controls (-27.53,227.81) and (-26.28,225.27) .. (-24.30,226.20)
 .. controls (-22.32,227.13) and (-18.62,231.40) .. (-16.33,231.67)
 .. controls (-14.03,231.94) and (-14.38,230.97) .. (-11.86,230.39)
 .. controls (-9.34,229.81) and (0.17,227.17) .. (2.68,226.98)
 .. controls (5.18,226.78) and (10.00,223.88) .. (10.98,223.24)
 .. controls (11.96,222.60) and (16.74,220.57) .. (18.08,217.92)
 .. controls (19.42,215.28) and (19.90,212.61) .. (19.03,210.18)
 .. controls (18.15,207.74) and (18.05,205.24) .. (16.91,204.91)
 .. controls (15.77,204.58) and (15.72,206.02) .. (15.83,202.95)
 .. controls (15.94,199.88) and (16.02,194.70) .. (16.02,194.70)
 .. controls (16.02,194.70) and (16.92,196.65) .. (17.40,196.47)
 .. controls (17.89,196.30) and (18.43,194.69) .. (19.02,194.13)
 .. controls (19.62,193.57) and (20.60,193.13) .. (19.49,191.84)
 .. controls (18.38,190.55) and (17.81,187.65) .. (18.32,186.80)
 .. controls (18.83,185.96) and (20.24,181.49) .. (19.33,180.11)
 .. controls (18.42,178.73) and (14.55,176.86) .. (13.65,172.41)
 .. controls (12.76,167.96) and (14.02,162.34) .. (14.37,160.72)
 .. controls (14.71,159.10) and (17.65,155.77) .. (16.94,153.42)
));
ATTR__id := "";
drawoptions();
p_gradient((-37.35,236.88),260.7,1.00,(0,0));
ATTR__id := "l515-83772-79120";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((50.54,322.64)
 .. controls (50.54,322.64) and (48.50,320.64) .. (47.46,320.22)
 .. controls (46.42,319.80) and (46.27,318.74) .. (45.07,317.25)
 .. controls (43.88,315.77) and (43.52,314.99) .. (42.25,313.02)
 .. controls (40.97,311.05) and (41.27,310.68) .. (40.61,307.77)
 .. controls (39.95,304.87) and (37.99,303.26) .. (35.96,300.98)
 .. controls (33.92,298.70) and (34.91,297.96) .. (34.39,296.41)
 .. controls (33.87,294.85) and (33.23,293.96) .. (31.21,291.30)
 .. controls (29.19,288.63) and (30.03,289.43) .. (29.62,287.49)
 .. controls (29.21,285.56) and (28.65,284.96) .. (28.30,284.08)
 .. controls (27.95,283.21) and (26.81,280.09) .. (26.63,279.70)
));
ATTR__id := "l517-84068-79112";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((32.47,277.70)
 .. controls (33.06,279.84) and (33.36,279.56) .. (34.24,281.70)
 .. controls (35.13,283.85) and (36.30,286.10) .. (36.74,287.17)
 .. controls (37.18,288.25) and (38.81,290.99) .. (39.58,293.62)
 .. controls (40.35,296.24) and (39.97,296.22) .. (39.99,298.34)
 .. controls (40.01,300.45) and (41.20,301.94) .. (41.92,303.50)
 .. controls (42.63,305.06) and (43.24,306.72) .. (43.69,307.60)
 .. controls (44.14,308.48) and (44.50,308.97) .. (45.69,310.65)
 .. controls (46.88,312.32) and (47.72,312.93) .. (48.25,314.29)
 .. controls (48.78,315.66) and (50.54,322.64) .. (50.54,322.64)
));
ATTR__id := "l120-83388-73344";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((17.99,142.71)
 .. controls (18.92,143.70) and (19.55,144.78) .. (19.91,145.37)
 .. controls (20.28,145.96) and (20.74,146.55) .. (21.31,146.76)
 .. controls (21.87,146.97) and (22.36,146.70) .. (22.85,146.53)
 .. controls (23.34,146.35) and (24.45,144.76) .. (24.45,144.76)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((16.94,153.42)
 .. controls (16.48,152.83) and (15.65,151.93) .. (15.19,151.34)
 .. controls (14.73,150.75) and (13.70,149.94) .. (13.70,149.94)
));
ATTR__id := "l531-83492-70664";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((33.35,91.57)
 .. controls (32.79,91.27) and (31.48,90.26) .. (30.66,88.88)
 .. controls (29.85,87.51) and (28.94,86.04) .. (28.78,85.17)
 .. controls (28.62,84.30) and (28.28,83.13) .. (28.31,82.36)
 .. controls (28.33,81.60) and (29.14,80.47) .. (29.14,80.47)
 .. controls (29.14,80.47) and (30.75,81.20) .. (31.11,81.98)
 .. controls (31.46,82.77) and (31.90,83.84) .. (32.16,84.71)
 .. controls (32.42,85.59) and (33.03,87.14) .. (33.08,88.39)
 .. controls (33.13,89.65) and (33.92,91.88) .. cycle
));
ATTR__id := "";
drawoptions();
p_gradient((37.23,-159.79),332.8,1.00,(0,0));
drawoptions();
p_gradient((41.76,-149.06),332.8,1.00,(0,0));
drawoptions();
p_gradient((112.48,-125.01),93.0,1.00,(0,0));
drawoptions();
p_gradient((111.57,-110.44),80.1,1.00,(0,0));
drawoptions();
p_gradient((115.17,-143.94),96.4,1.00,(0,0));
drawoptions();
p_stalagmites((76.82,-73.64),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((83.83,-76.27),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((81.13,-70.61),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((88.53,-73.41),0.0,1.00,(0,0));
drawoptions();
p_gradient((116.07,-185.60),87.0,1.00,(0,0));
drawoptions();
p_gradient((113.81,-197.78),87.0,1.00,(0,0));
drawoptions();
p_gradient((112.24,-205.32),90.5,1.00,(0,0));
drawoptions();
p_gradient((115.86,-216.67),178.0,1.00,(0,0));
drawoptions();
p_gradient((112.11,-209.93),112.5,1.00,(0,0));
ATTR__id := "l542-82768-69228";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((12.76,44.13)
 -- (12.61,45.86)
 -- (12.55,47.49)
));
ATTR__id := "l543-82720-69220";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.39,44.85)
 .. controls (11.39,44.85) and (11.52,46.68) .. (11.58,47.55)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.44,43.51)
 -- (11.37,42.93)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.40,41.97)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((12.91,42.70)
 -- (12.88,43.47)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((12.87,41.06)
 -- cycle
));
ATTR__id := "l539-83604-67400";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((27.45,-14.70)
 .. controls (27.45,-14.70) and (27.93,-11.99) .. (27.82,-11.42)
 .. controls (27.70,-10.85) and (28.30,-8.72) .. (29.23,-8.01)
 .. controls (30.17,-7.31) and (30.61,-6.23) .. (30.96,-5.17)
 .. controls (31.30,-4.10) and (31.07,-3.05) .. (31.04,-2.09)
 .. controls (31.01,-1.13) and (31.57,-0.82) .. (32.11,0.16)
 .. controls (32.65,1.14) and (33.40,1.74) .. (33.85,2.62)
 .. controls (34.30,3.50) and (35.33,4.21) .. (35.33,4.21)
));
ATTR__id := "l164-82800-70404";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((24.45,144.76)
 .. controls (23.84,140.23) and (22.28,132.87) .. (21.39,130.82)
 .. controls (20.50,128.77) and (18.19,123.50) .. (19.39,122.01)
 .. controls (20.60,120.51) and (24.73,120.37) .. (24.29,116.42)
 .. controls (23.86,112.46) and (18.82,108.34) .. (18.66,104.78)
 .. controls (18.50,101.22) and (18.06,92.08) .. (17.28,89.94)
 .. controls (16.49,87.80) and (14.13,83.97) .. (14.12,81.56)
 .. controls (14.11,79.16) and (13.61,74.53) .. (12.27,74.20)
 .. controls (10.94,73.86) and (10.80,66.94) .. (10.57,65.20)
 .. controls (10.35,63.46) and (9.95,58.45) .. (10.04,55.86)
 .. controls (10.13,53.27) and (8.42,49.94) .. (9.52,48.92)
 .. controls (10.61,47.90) and (11.58,47.55) .. (11.58,47.55)
));
ATTR__id := "l163-82880-68940";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((12.55,47.49)
 .. controls (14.89,46.52) and (15.34,47.30) .. (14.67,44.59)
 .. controls (14.00,41.87) and (15.31,40.10) .. (15.97,37.81)
 .. controls (16.63,35.53) and (19.87,28.25) .. (20.24,25.86)
 .. controls (20.61,23.47) and (21.69,20.25) .. (21.08,18.69)
 .. controls (20.46,17.13) and (22.87,16.93) .. (23.71,14.94)
 .. controls (24.55,12.95) and (26.99,11.79) .. (27.04,10.45)
 .. controls (27.09,9.11) and (23.41,1.67) .. (22.85,1.27)
 .. controls (22.29,0.86) and (19.74,-8.35) .. (19.25,-10.86)
 .. controls (18.76,-13.38) and (14.15,-29.57) .. (13.99,-30.54)
 .. controls (13.84,-31.50) and (13.57,-37.56) .. (14.19,-41.58)
 .. controls (14.81,-45.59) and (13.90,-49.75) .. (12.46,-52.40)
 .. controls (11.02,-55.05) and (6.94,-61.83) .. (6.04,-63.49)
 .. controls (5.14,-65.16) and (4.37,-67.78) .. (5.02,-69.88)
 .. controls (5.67,-71.97) and (10.55,-74.00) .. (11.34,-74.55)
 .. controls (12.13,-75.10) and (18.21,-78.43) .. (19.49,-79.45)
 .. controls (20.78,-80.46) and (26.66,-83.90) .. (28.27,-88.54)
 .. controls (29.88,-93.19) and (31.31,-95.64) .. (30.45,-103.84)
 .. controls (29.59,-112.03) and (31.84,-115.79) .. (31.17,-118.51)
 .. controls (30.50,-121.22) and (29.35,-132.02) .. (29.14,-134.24)
 .. controls (28.93,-136.45) and (25.11,-145.62) .. (21.65,-148.54)
 .. controls (18.20,-151.45) and (15.23,-157.81) .. (15.17,-158.87)
));
ATTR__id := "l162-83716-67936";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((117.93,-212.20)
 .. controls (117.26,-212.23) and (118.57,-205.28) .. (118.43,-203.76)
 .. controls (118.28,-202.23) and (120.98,-191.29) .. (121.25,-188.30)
 .. controls (121.53,-185.31) and (123.81,-173.61) .. (124.69,-171.37)
 .. controls (125.57,-169.13) and (124.21,-155.05) .. (124.04,-152.85)
 .. controls (123.86,-150.64) and (121.89,-146.49) .. (121.33,-144.30)
 .. controls (120.77,-142.11) and (120.44,-135.49) .. (119.68,-133.11)
 .. controls (118.92,-130.74) and (120.19,-117.91) .. (121.09,-113.56)
 .. controls (121.99,-109.20) and (119.40,-98.34) .. (118.73,-95.77)
 .. controls (118.06,-93.20) and (116.49,-87.11) .. (112.85,-79.27)
 .. controls (109.21,-71.42) and (94.29,-67.92) .. (92.58,-68.46)
 .. controls (90.87,-69.01) and (72.09,-62.38) .. (69.67,-61.89)
 .. controls (67.25,-61.40) and (56.58,-55.83) .. (53.36,-54.21)
 .. controls (50.13,-52.60) and (49.70,-54.15) .. (48.84,-54.08)
 .. controls (47.97,-54.02) and (39.31,-58.84) .. (35.51,-60.13)
 .. controls (31.72,-61.42) and (31.27,-59.70) .. (30.25,-57.91)
 .. controls (29.22,-56.12) and (26.41,-50.07) .. (27.19,-47.93)
 .. controls (27.98,-45.79) and (28.89,-41.73) .. (28.71,-36.45)
 .. controls (28.52,-31.18) and (34.49,-20.98) .. (35.73,-18.05)
 .. controls (36.98,-15.13) and (38.31,-12.10) .. (38.25,-10.38)
 .. controls (38.19,-8.65) and (38.21,-6.63) .. (38.86,-5.94)
 .. controls (39.51,-5.24) and (40.22,-3.58) .. (39.94,-1.19)
 .. controls (39.66,1.20) and (40.50,2.09) .. (40.84,3.16)
 .. controls (41.19,4.23) and (41.72,8.29) .. (40.97,10.28)
 .. controls (40.23,12.27) and (37.93,12.09) .. (36.76,12.43)
 .. controls (35.60,12.77) and (36.42,14.15) .. (36.37,15.39)
 .. controls (36.33,16.64) and (37.32,18.31) .. (37.32,18.31)
 .. controls (37.32,18.31) and (38.13,19.88) .. (38.97,20.48)
 .. controls (39.82,21.09) and (39.86,22.53) .. (39.86,22.53)
));
ATTR__id := "l247-83728-54364";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((15.17,-158.87)
 .. controls (15.17,-158.87) and (11.94,-160.04) .. (10.20,-162.90)
 .. controls (8.45,-165.78) and (8.20,-166.34) .. (6.75,-169.29)
 .. controls (5.28,-172.28) and (3.92,-174.31) .. (3.78,-176.14)
 .. controls (3.64,-177.98) and (2.56,-182.24) .. (3.08,-185.05)
 .. controls (3.88,-189.36) and (5.63,-189.78) .. (5.06,-193.67)
 .. controls (4.61,-196.76) and (1.56,-203.01) .. (1.01,-204.01)
 .. controls (0.46,-205.00) and (-0.38,-205.81) .. (-3.02,-207.57)
 .. controls (-5.65,-209.32) and (-8.15,-212.53) .. (-8.53,-215.65)
 .. controls (-8.90,-218.77) and (-8.74,-220.70) .. (-7.40,-223.56)
 .. controls (-6.05,-226.41) and (-4.48,-230.03) .. (-3.30,-230.86)
 .. controls (-2.12,-231.68) and (-0.07,-232.95) .. (1.20,-233.58)
 .. controls (2.47,-234.21) and (2.94,-234.09) .. (2.99,-235.15)
 .. controls (3.03,-236.21) and (4.15,-237.91) .. (4.08,-238.59)
 .. controls (4.02,-239.26) and (2.85,-251.92) .. (4.48,-256.08)
 .. controls (6.11,-260.23) and (7.94,-266.57) .. (8.86,-267.68)
 .. controls (9.77,-268.79) and (11.81,-273.29) .. (11.96,-274.62)
 .. controls (12.12,-275.96) and (15.19,-282.24) .. (16.99,-283.89)
 .. controls (18.79,-285.54) and (21.03,-290.53) .. (24.96,-292.48)
 .. controls (28.89,-294.43) and (29.02,-295.10) .. (29.33,-295.56)
 .. controls (29.64,-296.03) and (34.59,-307.84) .. (36.91,-310.05)
 .. controls (39.22,-312.25) and (38.13,-313.74) .. (38.53,-314.01)
 .. controls (38.93,-314.28) and (42.98,-312.47) .. (44.95,-311.23)
 .. controls (46.91,-309.99) and (48.69,-308.86) .. (50.86,-310.10)
 .. controls (53.04,-311.35) and (55.01,-312.41) .. (55.38,-314.32)
 .. controls (55.76,-316.22) and (57.15,-319.42) .. (57.15,-319.42)
 .. controls (57.15,-319.42) and (58.60,-317.44) .. (61.58,-317.49)
 .. controls (64.57,-317.55) and (67.40,-316.46) .. (67.61,-316.83)
 .. controls (67.82,-317.21) and (68.96,-321.19) .. (68.96,-321.19)
 .. controls (68.96,-321.19) and (72.65,-321.98) .. (74.10,-320.18)
 .. controls (75.56,-318.39) and (76.58,-315.46) .. (76.78,-313.43)
 .. controls (76.98,-311.40) and (76.05,-305.87) .. (77.17,-305.05)
 .. controls (78.28,-304.23) and (84.09,-298.86) .. (84.81,-297.87)
 .. controls (85.53,-296.87) and (88.98,-292.48) .. (89.92,-292.15)
 .. controls (90.87,-291.82) and (95.09,-289.70) .. (95.44,-288.82)
 .. controls (95.78,-287.94) and (100.22,-282.06) .. (100.92,-280.68)
 .. controls (101.63,-279.30) and (105.48,-273.26) .. (106.14,-273.04)
 .. controls (106.80,-272.82) and (105.83,-278.72) .. (105.48,-279.60)
 .. controls (105.14,-280.49) and (105.29,-283.75) .. (107.23,-282.12)
 .. controls (109.18,-280.49) and (110.16,-278.81) .. (111.43,-277.21)
 .. controls (112.70,-275.62) and (118.91,-272.73) .. (120.45,-272.85)
 .. controls (121.99,-272.98) and (129.02,-275.35) .. (130.93,-272.86)
 .. controls (132.83,-270.38) and (136.38,-266.10) .. (136.49,-264.27)
 .. controls (136.60,-262.45) and (137.58,-256.38) .. (137.58,-256.38)
));
ATTR__id := "";
drawoptions();
p_stalagmites((7.37,-254.23),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((9.17,-262.02),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((14.10,-273.00),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((19.10,-281.69),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((-4.94,-213.86),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((-5.86,-221.07),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((11.71,-164.77),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((7.64,-173.30),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((5.61,-182.54),0.0,1.00,(0,0));
ATTR__id := "l160-84024-77676";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((32.47,277.70)
 .. controls (32.41,273.86) and (31.89,272.21) .. (33.30,270.43)
 .. controls (34.71,268.66) and (35.94,266.49) .. (35.74,264.08)
 .. controls (35.54,261.68) and (35.07,258.59) .. (35.34,256.39)
 .. controls (35.61,254.19) and (35.47,247.46) .. (35.06,245.62)
 .. controls (34.64,243.78) and (32.81,233.15) .. (32.77,231.51)
 .. controls (32.74,229.88) and (32.51,222.86) .. (32.70,220.27)
 .. controls (32.88,217.68) and (34.12,212.73) .. (34.17,211.29)
 .. controls (34.22,209.85) and (34.18,205.62) .. (34.31,204.76)
 .. controls (34.43,203.90) and (35.46,204.71) .. (36.04,201.85)
 .. controls (36.63,198.99) and (34.94,194.99) .. (35.92,194.44)
 .. controls (36.90,193.90) and (37.97,190.96) .. (38.25,188.38)
 .. controls (38.54,185.79) and (39.39,178.14) .. (39.07,176.30)
 .. controls (38.75,174.46) and (37.90,171.36) .. (38.82,169.76)
 .. controls (39.74,168.16) and (39.65,167.96) .. (39.35,165.55)
 .. controls (39.06,163.14) and (38.91,161.98) .. (39.75,160.00)
 .. controls (40.59,158.01) and (42.01,155.85) .. (41.89,153.93)
 .. controls (41.76,152.01) and (42.71,152.42) .. (44.43,150.08)
 .. controls (46.14,147.74) and (43.61,143.33) .. (41.63,139.71)
 .. controls (39.64,136.08) and (38.86,130.96) .. (38.46,128.74)
 .. controls (38.06,126.51) and (36.21,121.84) .. (36.41,118.77)
 .. controls (36.61,115.70) and (37.13,112.07) .. (37.21,109.67)
 .. controls (37.30,107.28) and (35.97,104.25) .. (36.16,101.66)
 .. controls (36.35,99.08) and (34.90,99.41) .. (36.62,96.97)
 .. controls (38.34,94.54) and (39.88,89.02) .. (39.23,85.83)
 .. controls (38.58,82.64) and (38.19,77.43) .. (33.00,74.94)
 .. controls (27.80,72.45) and (28.31,71.79) .. (26.85,66.84)
 .. controls (25.40,61.88) and (26.01,57.97) .. (26.07,56.33)
 .. controls (26.13,54.70) and (25.53,47.28) .. (26.17,45.48)
 .. controls (26.81,43.68) and (27.76,41.12) .. (30.58,42.85)
 .. controls (33.40,44.59) and (38.25,46.01) .. (39.88,46.07)
 .. controls (41.52,46.13) and (42.11,45.47) .. (42.51,45.10)
 .. controls (42.91,44.73) and (43.11,44.55) .. (44.38,46.71)
 .. controls (45.64,48.87) and (44.79,45.86) .. (45.86,45.42)
 .. controls (46.94,44.97) and (47.88,45.49) .. (46.27,41.97)
 .. controls (44.67,38.46) and (41.26,34.40) .. (41.36,31.52)
 .. controls (41.47,28.64) and (40.13,23.12) .. (39.86,22.53)
));
ATTR__stationflag_splay := false;
ATTR__id := "";
drawoptions();
p_station((-113.26,229.92),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-111.24,220.18),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-92.36,229.77),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-59.98,224.21),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-56.99,241.52),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-54.18,241.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-32.78,230.05),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-15.40,262.91),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((32.13,220.36),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((23.79,189.49),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((27.82,167.10),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((30.65,144.87),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((36.24,113.02),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((15.42,73.07),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((15.10,47.20),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((36.67,17.31),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((21.77,-0.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((19.89,-32.18),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((15.16,-52.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((15.85,-75.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((42.25,-86.47),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((49.96,-107.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((90.57,-109.27),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((94.67,-155.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((97.56,-181.42),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((77.06,-187.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((70.97,-212.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((57.39,-259.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((35.02,-249.94),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((68.03,-283.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((106.27,-268.17),1,0,"");
endfig;
beginfig(4);
s_northarrow(0);
endfig;
beginfig(5);
s_scalebar(100, 1, "\thfb\char109 \mainfont{}");
endfig;
Scale:=5.00;
initialize(Scale);
background:=(1.00000,1.00000,1.00000);
transparency:=false;
end;
