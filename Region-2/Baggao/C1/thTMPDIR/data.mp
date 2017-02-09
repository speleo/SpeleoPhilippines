Scale:=2.00;
MagDecl:=0.00;
GridConv:=0.00;
color HelpSymbolColor;
HelpSymbolColor := (0.8, 0.8, 0.8);
background:=(0.80000,0.80000,0.80000);
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
ATTR__elevation:=true;

% user defined symbols defaults
% end of user defined symbols

defaultfont:="cmss10";
NorthDir:="true";
input "C:/Users/henry_bennett/Documents/GitHub/philippine-surveys-2015/bluewater-v7/code/_grid_x_hair_to_continuos_line.mp"
def s_scalebar (expr l, units, txt) =
begingroup
interim warningcheck:=0;
tmpl:=l / Scale * cm * units / 2;
tmpx:=l / Scale * cm * units / 5;
tmph:=25bp; % bar height
endgroup;
pickup PenC;
draw (-tmpl,0)--(tmpl,0)--(tmpl,-tmph)--(-tmpl,-tmph)--cycle;
p:=(0,0)--(tmpx,0)--(tmpx,-tmph)--(0,-tmph)--cycle;
for i:=-2.5 step 2 until 2:
fill p shifted (i * tmpx,0);
endfor;
begingroup
interim labeloffset:=3.5bp;
for i:=0 step (l/5) until (l-1):
tmpx:=tmpl * (i * 2 / l - 1);
label.top(thTEX(decimal (i)) scaled 3.6, (tmpx,0));
endfor;
label.top(thTEX(decimal (l) & "\thinspace" & txt) scaled 3.6,(tmpl,0));
endgroup;
enddef;
def a_water (expr p) =
T:=identity;
thfill p withcolor (0.1, 0.2, 0.8);
enddef;
def l_survey_cave (expr p) =
draw p withpen PenD withcolor (0.6, 0.6, 0.6);
enddef;
def s_northarrow (expr rot) =
begingroup
interim defaultscale:=1.5; % scale your north arrow here
T:=identity scaled defaultscale rotated -rot;
pickup pencircle scaled (0.08cm * defaultscale);
thdraw (-.4cm,-1.4cm)--(0,2.8cm)--(.4cm,-1.4cm)--cycle;
p:=fullcircle scaled 1.6cm;
thclean p; thdraw p;
p:=(0.95cm,0)--(0.65cm,0);
thdraw p; thdraw p xscaled -1;
pickup pencircle scaled (0.12cm * defaultscale);
p:=(0.28cm,0.42cm);
thdraw p--(p yscaled -1)--(p xscaled -1)--(p scaled -1);
endgroup;
enddef;
fonts_setup(6,8,30,54,80);



% BCRA symbol set.
mapsymbol("a_bedrock","BCRA",false);
mapsymbol("a_blocks","BCRA",false);
mapsymbol("a_clay","BCRA",false);
mapsymbol("a_debris","BCRA",false);
mapsymbol("a_dimensions","BCRA",false);
mapsymbol("a_flowstone","BCRA",false);
mapsymbol("a_ice","BCRA",false);
mapsymbol("a_moonmilk","BCRA",false);
mapsymbol("a_pebbles","BCRA",false);
mapsymbol("a_sand","BCRA",false);
mapsymbol("a_snow","BCRA",false);
mapsymbol("a_sump","BCRA",false);
mapsymbol("a_u","BCRA",false);
mapsymbol("a_water","BCRA",false);
mapsymbol("l_arrow","BCRA",false);
mapsymbol("l_border_invisible","BCRA",false);
mapsymbol("l_border_presumed","BCRA",false);
mapsymbol("l_border_temporary","BCRA",false);
mapsymbol("l_border_visible","BCRA",false);
mapsymbol("l_ceilingmeander","BCRA",false);
mapsymbol("l_ceilingstep","BCRA",false);
mapsymbol("l_chimney","BCRA",false);
mapsymbol("l_contour","BCRA",false);
mapsymbol("l_fixedladder","BCRA",false);
mapsymbol("l_floormeander","BCRA",false);
mapsymbol("l_floorstep","BCRA",false);
mapsymbol("l_flowstone","BCRA",false);
mapsymbol("l_gradient","BCRA",false);
mapsymbol("l_handrail","BCRA",false);
mapsymbol("l_mapconnection","BCRA",false);
mapsymbol("l_moonmilk","BCRA",false);
mapsymbol("l_overhang","BCRA",false);
mapsymbol("l_pit","BCRA",false);
mapsymbol("l_rockborder","BCRA",false);
mapsymbol("l_rockedge","BCRA",false);
mapsymbol("l_ropeladder","BCRA",false);
mapsymbol("l_section","BCRA",false);
mapsymbol("l_slope","BCRA",false);
mapsymbol("l_steps","BCRA",false);
mapsymbol("l_survey_cave","BCRA",false);
mapsymbol("l_survey_surface","BCRA",false);
mapsymbol("l_u","BCRA",false);
mapsymbol("l_viaferrata","BCRA",false);
mapsymbol("l_wall_bedrock","BCRA",false);
mapsymbol("l_wall_blocks","BCRA",false);
mapsymbol("l_wall_clay","BCRA",false);
mapsymbol("l_wall_debris","BCRA",false);
mapsymbol("l_wall_flowstone","BCRA",false);
mapsymbol("l_wall_ice","BCRA",false);
mapsymbol("l_wall_invisible","BCRA",false);
mapsymbol("l_wall_moonmilk","BCRA",false);
mapsymbol("l_wall_overlying","BCRA",false);
mapsymbol("l_wall_pebbles","BCRA",false);
mapsymbol("l_wall_pit","BCRA",false);
mapsymbol("l_wall_presumed","BCRA",false);
mapsymbol("l_wall_sand","BCRA",false);
mapsymbol("l_wall_underlying","BCRA",false);
mapsymbol("l_wall_unsurveyed","BCRA",false);
mapsymbol("l_waterflow_conjectural","BCRA",false);
mapsymbol("l_waterflow_intermittent","BCRA",false);
mapsymbol("l_waterflow_permanent","BCRA",false);
mapsymbol("p_airdraught","BCRA",false);
mapsymbol("p_airdraught_summer","BCRA",false);
mapsymbol("p_airdraught_winter","BCRA",false);
mapsymbol("p_anastomosis","BCRA",false);
mapsymbol("p_anchor","BCRA",false);
mapsymbol("p_aragonite","BCRA",false);
mapsymbol("p_archeomaterial","BCRA",false);
mapsymbol("p_bedrock","BCRA",false);
mapsymbol("p_blocks","BCRA",false);
mapsymbol("p_breakdownchoke","BCRA",false);
mapsymbol("p_bridge","BCRA",false);
mapsymbol("p_camp","BCRA",false);
mapsymbol("p_cavepearl","BCRA",false);
mapsymbol("p_clay","BCRA",false);
mapsymbol("p_claychoke","BCRA",false);
mapsymbol("p_claytree","BCRA",false);
mapsymbol("p_continuation","BCRA",false);
mapsymbol("p_crystal","BCRA",false);
mapsymbol("p_curtain","BCRA",false);
mapsymbol("p_debris","BCRA",false);
mapsymbol("p_dig","BCRA",false);
mapsymbol("p_disk","BCRA",false);
mapsymbol("p_entrance","BCRA",false);
mapsymbol("p_fixedladder","BCRA",false);
mapsymbol("p_flowstone","BCRA",false);
mapsymbol("p_flowstonechoke","BCRA",false);
mapsymbol("p_flute","BCRA",false);
mapsymbol("p_gradient","BCRA",false);
mapsymbol("p_guano","BCRA",false);
mapsymbol("p_gypsum","BCRA",false);
mapsymbol("p_gypsumflower","BCRA",false);
mapsymbol("p_handrail","BCRA",false);
mapsymbol("p_helictite","BCRA",false);
mapsymbol("p_ice","BCRA",false);
mapsymbol("p_icepillar","BCRA",false);
mapsymbol("p_icestalactite","BCRA",false);
mapsymbol("p_icestalagmite","BCRA",false);
mapsymbol("p_karren","BCRA",false);
mapsymbol("p_lowend","BCRA",false);
mapsymbol("p_moonmilk","BCRA",false);
mapsymbol("p_narrowend","BCRA",false);
mapsymbol("p_noequipment","BCRA",false);
mapsymbol("p_paleomaterial","BCRA",false);
mapsymbol("p_pebbles","BCRA",false);
mapsymbol("p_pillar","BCRA",false);
mapsymbol("p_pillars","BCRA",false);
mapsymbol("p_popcorn","BCRA",false);
mapsymbol("p_raft","BCRA",false);
mapsymbol("p_raftcone","BCRA",false);
mapsymbol("p_rimstonedam","BCRA",false);
mapsymbol("p_rimstonepool","BCRA",false);
mapsymbol("p_root","BCRA",false);
mapsymbol("p_rope","BCRA",false);
mapsymbol("p_ropeladder","BCRA",false);
mapsymbol("p_sand","BCRA",false);
mapsymbol("p_scallop","BCRA",false);
mapsymbol("p_sectionarrow","BCRA",false);
mapsymbol("p_sink","BCRA",false);
mapsymbol("p_snow","BCRA",false);
mapsymbol("p_sodastraw","BCRA",false);
mapsymbol("p_spring","BCRA",false);
mapsymbol("p_stalactite","BCRA",false);
mapsymbol("p_stalactites","BCRA",false);
mapsymbol("p_stalagmite","BCRA",false);
mapsymbol("p_stalagmites","BCRA",false);
mapsymbol("p_station","BCRA",false);
mapsymbol("p_station_fixed","BCRA",false);
mapsymbol("p_station_natural","BCRA",false);
mapsymbol("p_station_painted","BCRA",false);
mapsymbol("p_station_temporary","BCRA",false);
mapsymbol("p_steps","BCRA",false);
mapsymbol("p_traverse","BCRA",false);
mapsymbol("p_u","BCRA",false);
mapsymbol("p_vegetabledebris","BCRA",false);
mapsymbol("p_viaferrata","BCRA",false);
mapsymbol("p_wallcalcite","BCRA",false);
mapsymbol("p_water","BCRA",false);
mapsymbol("p_waterflow_intermittent","BCRA",false);
mapsymbol("p_waterflow_paleo","BCRA",false);
mapsymbol("p_waterflow_permanent","BCRA",false);
mapsymbol("s_hgrid","BCRA",false);
mapsymbol("s_northarrow","BCRA",false);
mapsymbol("s_scalebar","BCRA",false);
mapsymbol("s_vgrid","BCRA",false);
mapsymbol("l_slope","SKBB",true);
transparency:=true;
background:=(0.80000,0.80000,0.80000);
def_transparent_rgb(tr_bg, 0.80000, 0.80000, 0.80000);
current_scrap := "C1SE2@C1";
ATTR__scrap := "C1SE2";
beginfig(1);
draw_upscrap(1)(1,((594.60,27.03)
 .. controls (591.00,24.87) and (566.51,23.44) .. (543.46,25.61)
 .. controls (520.41,27.78) and (531.93,32.10) .. (495.20,29.95)
 .. controls (458.47,27.80) and (457.75,22.76) .. (439.02,24.92)
 .. controls (420.29,27.09) and (403.73,28.53) .. (387.89,29.26)
 .. controls (372.04,29.98) and (351.14,37.17) .. (343.22,38.61)
 .. controls (335.30,40.04) and (335.29,42.20) .. (325.94,35.00)
 .. controls (316.58,27.79) and (318.02,22.75) .. (298.57,18.40)
 .. controls (279.14,14.06) and (278.42,19.09) .. (264.02,16.20)
 .. controls (249.63,13.31) and (233.79,14.03) .. (226.59,12.60)
 .. controls (219.40,11.16) and (228.03,16.20) .. (207.16,16.93)
 .. controls (186.28,17.66) and (186.28,13.34) .. (174.76,16.94)
 .. controls (163.24,20.54) and (167.56,22.70) .. (153.88,25.58)
 .. controls (140.20,28.46) and (151.72,25.58) .. (127.96,31.34)
 .. controls (104.20,37.11) and (109.24,41.43) .. (86.92,45.03)
 .. controls (64.60,48.63) and (68.20,46.47) .. (54.52,43.59)
 .. controls (40.84,40.71) and (29.33,34.96) .. (29.33,34.96)
 .. controls (29.33,34.96) and (25.73,27.76) .. (21.41,22.72)
 .. controls (17.09,17.68) and (7.02,-0.32) .. (7.02,-0.32)
 -- (-9.90,-22.63)
),
1,reverse ((590.22,-132.18)
 .. controls (590.22,-132.18) and (534.41,-104.42) .. (529.73,-105.50)
 .. controls (525.04,-106.58) and (473.20,-69.82) .. (469.96,-70.90)
 .. controls (461.51,-73.71) and (452.69,-44.96) .. (400.84,-24.04)
 .. controls (397.76,-22.80) and (339.28,-22.60) .. (332.81,-23.68)
 .. controls (326.33,-24.77) and (316.61,-23.70) .. (306.53,-26.59)
 .. controls (296.45,-29.49) and (284.21,-32.02) .. (277.37,-30.23)
 .. controls (270.52,-28.43) and (270.52,-28.80) .. (262.96,-29.52)
 .. controls (255.40,-30.25) and (247.83,-32.04) .. (243.87,-34.20)
 .. controls (239.91,-36.36) and (233.07,-40.67) .. (226.59,-44.63)
 .. controls (220.10,-48.59) and (207.14,-56.14) .. (203.90,-57.22)
 .. controls (200.66,-58.30) and (197.42,-61.18) .. (193.46,-63.34)
 .. controls (189.50,-65.49) and (184.82,-64.41) .. (181.58,-63.69)
 .. controls (178.34,-62.97) and (168.63,-58.29) .. (166.11,-56.49)
 .. controls (163.59,-54.69) and (153.51,-51.10) .. (148.47,-48.94)
 .. controls (143.43,-46.78) and (112.11,-41.38) .. (112.11,-41.38)
 -- (93.40,-49.32)
));
draw_upscrap(1)(1,((-240.68,104.82)
 .. controls (-244.28,104.82) and (-247.16,105.54) .. (-251.48,105.54)
 .. controls (-255.80,105.54) and (-273.81,111.30) .. (-273.81,111.30)
 .. controls (-273.81,111.30) and (-280.29,118.50) .. (-286.77,119.94)
 .. controls (-293.25,121.38) and (-301.89,124.98) .. (-307.65,124.98)
 .. controls (-313.41,124.98) and (-332.13,132.18) .. (-345.09,125.70)
 .. controls (-358.05,119.22) and (-348.69,115.62) .. (-367.41,110.58)
 .. controls (-386.14,105.54) and (-394.06,102.66) .. (-407.02,99.78)
 .. controls (-419.98,96.90) and (-432.22,91.14) .. (-436.54,90.42)
 .. controls (-440.86,89.70) and (-432.22,94.02) .. (-445.90,90.42)
 .. controls (-459.58,86.82) and (-480.46,87.54) .. (-489.83,88.26)
 .. controls (-499.19,88.98) and (-520.79,88.26) .. (-525.11,85.38)
 .. controls (-529.43,82.50) and (-538.07,71.70) .. (-545.99,70.98)
 .. controls (-553.91,70.26) and (-574.79,62.34) .. (-574.79,62.34)
 -- (-594.60,59.47)
),
1,((-488.03,12.30)
 .. controls (-488.03,12.30) and (-475.43,18.42) .. (-473.99,22.02)
 .. controls (-472.55,25.62) and (-455.26,21.30) .. (-453.10,23.46)
 .. controls (-450.94,25.62) and (-458.50,18.06) .. (-430.06,26.34)
 .. controls (-401.62,34.62) and (-431.50,27.06) .. (-417.82,32.10)
 .. controls (-404.14,37.14) and (-411.34,27.06) .. (-401.98,34.26)
 .. controls (-392.62,41.46) and (-396.22,37.14) .. (-384.70,44.34)
 .. controls (-373.18,51.54) and (-377.50,54.42) .. (-367.41,55.86)
 .. controls (-357.33,57.30) and (-364.53,58.74) .. (-350.13,58.74)
 .. controls (-335.73,58.74) and (-333.57,60.18) .. (-324.93,63.06)
 .. controls (-316.29,65.94) and (-306.93,68.10) .. (-301.89,69.54)
 .. controls (-296.85,70.98) and (-293.25,73.86) .. (-288.21,77.46)
 .. controls (-283.17,81.06) and (-290.37,81.78) .. (-276.69,83.94)
 .. controls (-263.00,86.10) and (-263.00,88.26) .. (-257.96,86.10)
 .. controls (-252.92,83.94) and (-237.08,80.34) .. (-237.08,80.34)
));
draw_downscrap;
endfig;
beginfig(2);
ATTR__survey := "C1";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-488.03,12.30)
 .. controls (-488.03,12.30) and (-475.43,18.42) .. (-473.99,22.02)
 .. controls (-472.55,25.62) and (-455.26,21.30) .. (-453.10,23.46)
 .. controls (-450.94,25.62) and (-458.50,18.06) .. (-430.06,26.34)
 .. controls (-401.62,34.62) and (-431.50,27.06) .. (-417.82,32.10)
 .. controls (-404.14,37.14) and (-411.34,27.06) .. (-401.98,34.26)
 .. controls (-392.62,41.46) and (-396.22,37.14) .. (-384.70,44.34)
 .. controls (-373.18,51.54) and (-377.50,54.42) .. (-367.41,55.86)
 .. controls (-357.33,57.30) and (-364.53,58.74) .. (-350.13,58.74)
 .. controls (-335.73,58.74) and (-333.57,60.18) .. (-324.93,63.06)
 .. controls (-316.29,65.94) and (-306.93,68.10) .. (-301.89,69.54)
 .. controls (-296.85,70.98) and (-293.25,73.86) .. (-288.21,77.46)
 .. controls (-283.17,81.06) and (-290.37,81.78) .. (-276.69,83.94)
 .. controls (-263.00,86.10) and (-263.00,88.26) .. (-257.96,86.10)
 .. controls (-252.92,83.94) and (-237.08,80.34) .. (-237.08,80.34)
));
l_debug(0,1,((-488.07,12.32)
 .. controls (-488.07,12.32) and (-475.47,18.44) .. (-474.03,22.04)
 .. controls (-472.59,25.64) and (-455.30,21.32) .. (-453.14,23.48)
 .. controls (-450.98,25.64) and (-458.55,18.08) .. (-430.10,26.36)
 .. controls (-401.66,34.64) and (-431.54,27.08) .. (-417.86,32.12)
 .. controls (-404.18,37.16) and (-411.38,27.08) .. (-402.02,34.28)
 .. controls (-392.66,41.48) and (-396.26,37.16) .. (-384.74,44.36)
 .. controls (-373.22,51.56) and (-377.54,54.44) .. (-367.45,55.88)
 .. controls (-357.37,57.32) and (-364.57,58.76) .. (-350.17,58.76)
 .. controls (-335.77,58.76) and (-333.61,60.20) .. (-324.97,63.08)
 .. controls (-316.33,65.96) and (-306.97,68.12) .. (-301.93,69.56)
 .. controls (-296.89,71.00) and (-293.29,73.88) .. (-288.25,77.48)
 .. controls (-283.21,81.08) and (-290.41,81.80) .. (-276.72,83.96)
 .. controls (-263.04,86.12) and (-263.04,88.28) .. (-258.00,86.12)
 .. controls (-252.96,83.96) and (-237.12,80.36) .. (-237.12,80.36)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-240.68,104.82)
 .. controls (-244.28,104.82) and (-247.16,105.54) .. (-251.48,105.54)
 .. controls (-255.80,105.54) and (-273.81,111.30) .. (-273.81,111.30)
 .. controls (-273.81,111.30) and (-280.29,118.50) .. (-286.77,119.94)
 .. controls (-293.25,121.38) and (-301.89,124.98) .. (-307.65,124.98)
 .. controls (-313.41,124.98) and (-332.13,132.18) .. (-345.09,125.70)
 .. controls (-358.05,119.22) and (-348.69,115.62) .. (-367.41,110.58)
 .. controls (-386.14,105.54) and (-394.06,102.66) .. (-407.02,99.78)
 .. controls (-419.98,96.90) and (-432.22,91.14) .. (-436.54,90.42)
 .. controls (-440.86,89.70) and (-432.22,94.02) .. (-445.90,90.42)
 .. controls (-459.58,86.82) and (-480.46,87.54) .. (-489.83,88.26)
 .. controls (-499.19,88.98) and (-520.79,88.26) .. (-525.11,85.38)
 .. controls (-529.43,82.50) and (-538.07,71.70) .. (-545.99,70.98)
 .. controls (-553.91,70.26) and (-574.79,62.34) .. (-574.79,62.34)
 -- (-594.60,59.47)
));
l_debug(0,1,((-240.72,104.84)
 .. controls (-244.32,104.84) and (-247.20,105.56) .. (-251.52,105.56)
 .. controls (-255.84,105.56) and (-273.84,111.32) .. (-273.84,111.32)
 .. controls (-273.84,111.32) and (-280.32,118.52) .. (-286.80,119.96)
 .. controls (-293.28,121.40) and (-301.92,125.00) .. (-307.69,125.00)
 .. controls (-313.45,125.00) and (-332.17,132.21) .. (-345.13,125.73)
 .. controls (-358.09,119.25) and (-348.73,115.65) .. (-367.45,110.61)
 .. controls (-386.17,105.57) and (-394.09,102.69) .. (-407.06,99.81)
 .. controls (-420.02,96.93) and (-432.26,91.17) .. (-436.58,90.45)
 .. controls (-440.90,89.73) and (-432.26,94.05) .. (-445.94,90.45)
 .. controls (-459.62,86.85) and (-480.50,87.57) .. (-489.86,88.29)
 .. controls (-499.22,89.01) and (-520.83,88.29) .. (-525.15,85.41)
 .. controls (-529.47,82.53) and (-538.11,71.73) .. (-546.03,71.01)
 .. controls (-553.95,70.29) and (-574.83,62.37) .. (-574.83,62.37)
 -- (-594.63,59.50)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((590.22,-132.18)
 .. controls (590.22,-132.18) and (534.41,-104.42) .. (529.73,-105.50)
 .. controls (525.04,-106.58) and (473.20,-69.82) .. (469.96,-70.90)
 .. controls (461.51,-73.71) and (452.69,-44.96) .. (400.84,-24.04)
 .. controls (397.76,-22.80) and (339.28,-22.60) .. (332.81,-23.68)
 .. controls (326.33,-24.77) and (316.61,-23.70) .. (306.53,-26.59)
 .. controls (296.45,-29.49) and (284.21,-32.02) .. (277.37,-30.23)
 .. controls (270.52,-28.43) and (270.52,-28.80) .. (262.96,-29.52)
 .. controls (255.40,-30.25) and (247.83,-32.04) .. (243.87,-34.20)
 .. controls (239.91,-36.36) and (233.07,-40.67) .. (226.59,-44.63)
 .. controls (220.10,-48.59) and (207.14,-56.14) .. (203.90,-57.22)
 .. controls (200.66,-58.30) and (197.42,-61.18) .. (193.46,-63.34)
 .. controls (189.50,-65.49) and (184.82,-64.41) .. (181.58,-63.69)
 .. controls (178.34,-62.97) and (168.63,-58.29) .. (166.11,-56.49)
 .. controls (163.59,-54.69) and (153.51,-51.10) .. (148.47,-48.94)
 .. controls (143.43,-46.78) and (112.11,-41.38) .. (112.11,-41.38)
 -- (93.40,-49.32)
));
l_debug(0,1,((590.22,-132.11)
 .. controls (590.22,-132.11) and (534.42,-104.39) .. (529.74,-105.47)
 .. controls (525.05,-106.55) and (473.21,-69.82) .. (469.97,-70.90)
 .. controls (461.52,-73.72) and (452.69,-44.98) .. (400.85,-24.09)
 .. controls (397.77,-22.85) and (339.28,-22.65) .. (332.80,-23.73)
 .. controls (326.32,-24.81) and (316.60,-23.73) .. (306.52,-26.61)
 .. controls (296.44,-29.49) and (284.20,-32.01) .. (277.36,-30.21)
 .. controls (270.52,-28.41) and (270.52,-28.77) .. (262.96,-29.49)
 .. controls (255.40,-30.21) and (247.83,-32.00) .. (243.87,-34.16)
 .. controls (239.91,-36.32) and (233.07,-40.64) .. (226.59,-44.60)
 .. controls (220.11,-48.56) and (207.15,-56.12) .. (203.91,-57.20)
 .. controls (200.67,-58.28) and (197.43,-61.16) .. (193.47,-63.32)
 .. controls (189.51,-65.48) and (184.83,-64.40) .. (181.59,-63.68)
 .. controls (178.35,-62.96) and (168.63,-58.28) .. (166.11,-56.48)
 .. controls (163.59,-54.68) and (153.51,-51.08) .. (148.46,-48.92)
 .. controls (143.42,-46.76) and (112.10,-41.36) .. (112.10,-41.36)
 -- (93.38,-49.28)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((594.60,27.03)
 .. controls (591.00,24.87) and (566.51,23.44) .. (543.46,25.61)
 .. controls (520.41,27.78) and (531.93,32.10) .. (495.20,29.95)
 .. controls (458.47,27.80) and (457.75,22.76) .. (439.02,24.92)
 .. controls (420.29,27.09) and (403.73,28.53) .. (387.89,29.26)
 .. controls (372.04,29.98) and (351.14,37.17) .. (343.22,38.61)
 .. controls (335.30,40.04) and (335.29,42.20) .. (325.94,35.00)
 .. controls (316.58,27.79) and (318.02,22.75) .. (298.57,18.40)
 .. controls (279.14,14.06) and (278.42,19.09) .. (264.02,16.20)
 .. controls (249.63,13.31) and (233.79,14.03) .. (226.59,12.60)
 .. controls (219.40,11.16) and (228.03,16.20) .. (207.16,16.93)
 .. controls (186.28,17.66) and (186.28,13.34) .. (174.76,16.94)
 .. controls (163.24,20.54) and (167.56,22.70) .. (153.88,25.58)
 .. controls (140.20,28.46) and (151.72,25.58) .. (127.96,31.34)
 .. controls (104.20,37.11) and (109.24,41.43) .. (86.92,45.03)
 .. controls (64.60,48.63) and (68.20,46.47) .. (54.52,43.59)
 .. controls (40.84,40.71) and (29.33,34.96) .. (29.33,34.96)
 .. controls (29.33,34.96) and (25.73,27.76) .. (21.41,22.72)
 .. controls (17.09,17.68) and (7.02,-0.32) .. (7.02,-0.32)
 -- (-9.90,-22.63)
));
l_debug(0,1,((594.55,27.02)
 .. controls (590.95,24.86) and (566.47,23.42) .. (543.42,25.58)
 .. controls (520.38,27.74) and (531.90,32.06) .. (495.18,29.91)
 .. controls (458.46,27.75) and (457.74,22.71) .. (439.02,24.87)
 .. controls (420.29,27.03) and (403.73,28.47) .. (387.89,29.19)
 .. controls (372.05,29.91) and (351.17,37.11) .. (343.25,38.56)
 .. controls (335.33,40.00) and (335.33,42.16) .. (325.97,34.96)
 .. controls (316.60,27.76) and (318.04,22.72) .. (298.60,18.40)
 .. controls (279.16,14.08) and (278.44,19.12) .. (264.04,16.24)
 .. controls (249.64,13.36) and (233.80,14.08) .. (226.60,12.64)
 .. controls (219.39,11.20) and (228.04,16.24) .. (207.15,16.96)
 .. controls (186.27,17.68) and (186.27,13.36) .. (174.75,16.96)
 .. controls (163.23,20.56) and (167.55,22.72) .. (153.87,25.61)
 .. controls (140.19,28.49) and (151.71,25.61) .. (127.95,31.37)
 .. controls (104.19,37.13) and (109.23,41.45) .. (86.91,45.05)
 .. controls (64.58,48.65) and (68.18,46.49) .. (54.50,43.61)
 .. controls (40.82,40.73) and (29.30,34.97) .. (29.30,34.97)
 .. controls (29.30,34.97) and (25.70,27.77) .. (21.38,22.73)
 .. controls (17.06,17.69) and (6.98,-0.31) .. (6.98,-0.31)
 -- (-9.95,-22.63)
));
p_debug(-1,1,(97.00,-36.18));
p_debug(-1,1,(93.40,-49.32));
l_debug(-1,1,((97.00,-36.18) -- (93.40,-49.32)));
p_debug(-2,1,(97.00,-36.17));
p_debug(-2,1,(93.38,-49.28));
l_debug(-2,1,((97.00,-36.18) -- (97.00,-36.17) -- (93.38,-49.28) -- (93.40,-49.32)));
endfig;
beginfig(3);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \vbox{\halign{#\hfil\cr\thfb\char63 \cr\thfb \char99 \char111 \char110 \char116 \char105 \char110 \char117 \char101 \char100 \ \char98 \char117 \char116 \cr\thfb \char118 \char101 \char114 \char121 \ \char116 \char105 \char103 \char104 \char116 \cr}}\mainfont{} etex,(-215.48,106.25),0.0,0);
endfig;
current_scrap := "C1SE1@C1";
ATTR__scrap := "C1SE1";
beginfig(4);
current_src := "C1Ee.th2 [305]";
string area_border[];
area_border[1] := "l83-16348-760";
area_border[2] := "l93-19308-372";
drawoptions();
a_water(buildcycle(((926.35,-286.41)
 -- (876.22,-243.29)
),
((970.61,-221.41)
 .. controls (970.61,-221.41) and (967.32,-220.29) .. (966.38,-215.70)
 .. controls (965.44,-211.11) and (961.59,-209.36) .. (958.89,-203.75)
 .. controls (956.18,-198.13) and (946.10,-197.12) .. (939.45,-192.27)
 .. controls (933.61,-187.99) and (932.91,-186.36) .. (926.59,-186.70)
 .. controls (921.31,-186.98) and (920.39,-187.67) .. (916.03,-191.99)
 .. controls (911.65,-196.31) and (908.00,-201.33) .. (905.85,-204.23)
 .. controls (903.72,-207.11) and (891.99,-223.10) .. (888.63,-228.26)
 .. controls (885.38,-233.26) and (882.47,-238.23) .. (880.69,-241.66)
 .. controls (878.94,-245.01) and (867.83,-269.34) .. (868.26,-272.17)
 .. controls (868.69,-274.99) and (876.36,-278.15) .. (879.24,-278.62)
 .. controls (882.34,-279.12) and (882.29,-279.70) .. (892.39,-279.86)
 .. controls (904.82,-280.06) and (901.47,-281.26) .. (908.52,-280.51)
 .. controls (929.64,-278.28) and (926.79,-280.29) .. (931.11,-281.87)
 .. controls (935.43,-283.46) and (931.46,-282.97) .. (942.42,-285.49)
 .. controls (953.44,-288.03) and (956.90,-291.52) .. (964.11,-293.78)
 .. controls (971.27,-296.03) and (970.44,-294.31) .. (983.31,-294.56)
 .. controls (995.94,-294.80) and (993.06,-294.16) .. (1001.34,-295.24)
 .. controls (1009.62,-296.31) and (1016.46,-297.03) .. (1021.86,-298.83)
 .. controls (1027.25,-300.63) and (1029.06,-300.62) .. (1035.53,-302.06)
 .. controls (1042.01,-303.50) and (1061.79,-311.80) .. (1068.64,-312.15)
 .. controls (1075.49,-312.50) and (1081.59,-316.83) .. (1088.81,-315.00)
 .. controls (1096.02,-313.19) and (1089.53,-316.08) .. (1099.98,-313.18)
 .. controls (1110.42,-310.29) and (1102.50,-314.98) .. (1120.14,-313.17)
 .. controls (1137.78,-311.35) and (1148.58,-313.50) .. (1152.54,-314.22)
 .. controls (1156.50,-314.94) and (1166.22,-319.25) .. (1170.90,-319.61)
 .. controls (1175.58,-319.96) and (1179.04,-318.15) .. (1181.70,-320.68)
 .. controls (1188.90,-327.51) and (1189.98,-328.95) .. (1191.77,-333.28)
 .. controls (1193.57,-337.60) and (1194.29,-336.16) .. (1195.37,-340.84)
 .. controls (1196.44,-345.53) and (1193.56,-343.73) .. (1198.95,-349.14)
 .. controls (1204.34,-354.55) and (1203.98,-352.38) .. (1215.15,-353.81)
 .. controls (1226.31,-355.25) and (1231.35,-354.88) .. (1240.36,-353.79)
 .. controls (1249.36,-352.71) and (1257.29,-354.51) .. (1261.25,-354.87)
 .. controls (1265.21,-355.23) and (1286.45,-359.18) .. (1292.21,-359.54)
 .. controls (1297.97,-359.90) and (1328.19,-363.51) .. (1334.31,-362.43)
 .. controls (1340.42,-361.36) and (1347.59,-366.02) .. (1369.10,-364.35)
 .. controls (1390.51,-362.69) and (1402.58,-366.84) .. (1411.09,-365.90)
 .. controls (1419.58,-364.96) and (1423.82,-362.54) .. (1426.30,-360.44)
 .. controls (1428.78,-358.33) and (1435.81,-360.65) .. (1430.19,-355.85)
 .. controls (1424.57,-351.05) and (1420.68,-351.33) .. (1413.61,-349.76)
 .. controls (1406.53,-348.19) and (1402.98,-346.34) .. (1394.45,-343.36)
 .. controls (1385.91,-340.37) and (1381.27,-338.53) .. (1376.27,-335.26)
 .. controls (1371.26,-331.98) and (1379.84,-331.68) .. (1367.67,-328.01)
 .. controls (1355.49,-324.33) and (1346.88,-322.87) .. (1340.05,-319.26)
 .. controls (1333.22,-315.65) and (1332.14,-314.93) .. (1328.89,-309.54)
 .. controls (1325.64,-304.15) and (1323.45,-291.98) .. (1316.59,-286.61)
 .. controls (1309.73,-281.25) and (1308.31,-283.38) .. (1300.71,-275.54)
 .. controls (1293.12,-267.70) and (1299.58,-268.44) .. (1287.69,-263.08)
 .. controls (1275.80,-257.72) and (1270.76,-255.92) .. (1267.52,-253.43)
 .. controls (1264.27,-250.94) and (1258.49,-245.27) .. (1253.80,-242.07)
 .. controls (1249.12,-238.88) and (1245.88,-238.50) .. (1244.44,-237.09)
 .. controls (1242.99,-235.68) and (1241.91,-234.27) .. (1240.46,-232.51)
 .. controls (1232.59,-222.96) and (1235.05,-224.79) .. (1229.23,-212.99)
 .. controls (1223.46,-201.29) and (1222.00,-204.03) .. (1217.72,-184.02)
 .. controls (1213.54,-164.46) and (1212.62,-155.38) .. (1204.60,-147.41)
)));
current_src := "C1Ee.th2 [295]";
string area_border[];
area_border[1] := "l93-19308-372";
area_border[2] := "l66-19178-422";
drawoptions();
a_water(buildcycle(((970.61,-221.41)
 .. controls (970.61,-221.41) and (967.32,-220.29) .. (966.38,-215.70)
 .. controls (965.44,-211.11) and (961.59,-209.36) .. (958.89,-203.75)
 .. controls (956.18,-198.13) and (946.10,-197.12) .. (939.45,-192.27)
 .. controls (933.61,-187.99) and (932.91,-186.36) .. (926.59,-186.70)
 .. controls (921.31,-186.98) and (920.39,-187.67) .. (916.03,-191.99)
 .. controls (911.65,-196.31) and (908.00,-201.33) .. (905.85,-204.23)
 .. controls (903.72,-207.11) and (891.99,-223.10) .. (888.63,-228.26)
 .. controls (885.38,-233.26) and (882.47,-238.23) .. (880.69,-241.66)
 .. controls (878.94,-245.01) and (867.83,-269.34) .. (868.26,-272.17)
 .. controls (868.69,-274.99) and (876.36,-278.15) .. (879.24,-278.62)
 .. controls (882.34,-279.12) and (882.29,-279.70) .. (892.39,-279.86)
 .. controls (904.82,-280.06) and (901.47,-281.26) .. (908.52,-280.51)
 .. controls (929.64,-278.28) and (926.79,-280.29) .. (931.11,-281.87)
 .. controls (935.43,-283.46) and (931.46,-282.97) .. (942.42,-285.49)
 .. controls (953.44,-288.03) and (956.90,-291.52) .. (964.11,-293.78)
 .. controls (971.27,-296.03) and (970.44,-294.31) .. (983.31,-294.56)
 .. controls (995.94,-294.80) and (993.06,-294.16) .. (1001.34,-295.24)
 .. controls (1009.62,-296.31) and (1016.46,-297.03) .. (1021.86,-298.83)
 .. controls (1027.25,-300.63) and (1029.06,-300.62) .. (1035.53,-302.06)
 .. controls (1042.01,-303.50) and (1061.79,-311.80) .. (1068.64,-312.15)
 .. controls (1075.49,-312.50) and (1081.59,-316.83) .. (1088.81,-315.00)
 .. controls (1096.02,-313.19) and (1089.53,-316.08) .. (1099.98,-313.18)
 .. controls (1110.42,-310.29) and (1102.50,-314.98) .. (1120.14,-313.17)
 .. controls (1137.78,-311.35) and (1148.58,-313.50) .. (1152.54,-314.22)
 .. controls (1156.50,-314.94) and (1166.22,-319.25) .. (1170.90,-319.61)
 .. controls (1175.58,-319.96) and (1179.04,-318.15) .. (1181.70,-320.68)
 .. controls (1188.90,-327.51) and (1189.98,-328.95) .. (1191.77,-333.28)
 .. controls (1193.57,-337.60) and (1194.29,-336.16) .. (1195.37,-340.84)
 .. controls (1196.44,-345.53) and (1193.56,-343.73) .. (1198.95,-349.14)
 .. controls (1204.34,-354.55) and (1203.98,-352.38) .. (1215.15,-353.81)
 .. controls (1226.31,-355.25) and (1231.35,-354.88) .. (1240.36,-353.79)
 .. controls (1249.36,-352.71) and (1257.29,-354.51) .. (1261.25,-354.87)
 .. controls (1265.21,-355.23) and (1286.45,-359.18) .. (1292.21,-359.54)
 .. controls (1297.97,-359.90) and (1328.19,-363.51) .. (1334.31,-362.43)
 .. controls (1340.42,-361.36) and (1347.59,-366.02) .. (1369.10,-364.35)
 .. controls (1390.51,-362.69) and (1402.58,-366.84) .. (1411.09,-365.90)
 .. controls (1419.58,-364.96) and (1423.82,-362.54) .. (1426.30,-360.44)
 .. controls (1428.78,-358.33) and (1435.81,-360.65) .. (1430.19,-355.85)
 .. controls (1424.57,-351.05) and (1420.68,-351.33) .. (1413.61,-349.76)
 .. controls (1406.53,-348.19) and (1402.98,-346.34) .. (1394.45,-343.36)
 .. controls (1385.91,-340.37) and (1381.27,-338.53) .. (1376.27,-335.26)
 .. controls (1371.26,-331.98) and (1379.84,-331.68) .. (1367.67,-328.01)
 .. controls (1355.49,-324.33) and (1346.88,-322.87) .. (1340.05,-319.26)
 .. controls (1333.22,-315.65) and (1332.14,-314.93) .. (1328.89,-309.54)
 .. controls (1325.64,-304.15) and (1323.45,-291.98) .. (1316.59,-286.61)
 .. controls (1309.73,-281.25) and (1308.31,-283.38) .. (1300.71,-275.54)
 .. controls (1293.12,-267.70) and (1299.58,-268.44) .. (1287.69,-263.08)
 .. controls (1275.80,-257.72) and (1270.76,-255.92) .. (1267.52,-253.43)
 .. controls (1264.27,-250.94) and (1258.49,-245.27) .. (1253.80,-242.07)
 .. controls (1249.12,-238.88) and (1245.88,-238.50) .. (1244.44,-237.09)
 .. controls (1242.99,-235.68) and (1241.91,-234.27) .. (1240.46,-232.51)
 .. controls (1232.59,-222.96) and (1235.05,-224.79) .. (1229.23,-212.99)
 .. controls (1223.46,-201.29) and (1222.00,-204.03) .. (1217.72,-184.02)
 .. controls (1213.54,-164.46) and (1212.62,-155.38) .. (1204.60,-147.41)
),
((1249.00,-356.31)
 -- (1438.64,-357.50)
)));
current_src := "C1Ee.th2 [199]";
string area_border[];
area_border[1] := "l71-11988-2560";
drawoptions();
a_blocks(buildcycle(((362.08,17.68)
 .. controls (344.08,15.50) and (323.94,5.41) .. (324.66,-6.11)
 .. controls (325.39,-17.62) and (331.88,-33.45) .. (342.67,-39.92)
 .. controls (353.47,-46.39) and (344.85,-58.62) .. (400.97,-59.37)
 .. controls (457.13,-60.12) and (476.58,-73.08) .. (489.54,-69.47)
 .. controls (502.50,-65.86) and (516.90,-62.24) .. (527.69,-53.60)
 .. controls (538.49,-44.95) and (555.76,-31.26) .. (559.36,-26.94)
 .. controls (562.96,-22.63) and (570.89,-8.28) .. (570.89,-8.28)
 .. controls (570.89,-8.28) and (570.89,1.79) .. (552.89,6.83)
 .. controls (534.89,11.87) and (549.29,13.30) .. (515.45,18.35)
 .. controls (481.62,23.40) and (489.54,24.83) .. (455.71,27.01)
 .. controls (421.86,29.20) and (424.03,35.69) .. (400.25,29.21)
 .. controls (376.48,22.74) and (380.09,19.85) .. cycle
)));
current_src := "C1Ee.th2 [189]";
string area_border[];
area_border[1] := "l73-14060-976";
area_border[2] := "l6-14036-804";
drawoptions();
a_water(buildcycle(((830.51,-255.25)
 -- (686.84,-256.65)
),
((-164.57,14.03)
 .. controls (-164.57,14.03) and (-156.29,14.03) .. (-154.86,14.75)
 .. controls (-153.42,15.47) and (-139.38,14.75) .. (-127.14,16.19)
 .. controls (-114.90,17.63) and (-129.30,20.51) .. (-110.22,17.99)
 .. controls (-91.14,15.47) and (-94.38,14.75) .. (-80.34,13.67)
 .. controls (-66.30,12.59) and (-65.94,10.79) .. (-59.10,11.51)
 .. controls (-52.26,12.23) and (-59.10,14.39) .. (-45.78,12.23)
 .. controls (-32.46,10.07) and (-29.94,8.99) .. (-23.82,8.99)
 .. controls (-17.70,8.99) and (-6.18,6.11) .. (-1.50,7.55)
 .. controls (3.18,8.99) and (18.52,6.03) .. (28.02,6.84)
 .. controls (49.26,8.63) and (47.46,10.79) .. (58.98,8.63)
 .. controls (70.50,6.47) and (70.14,8.26) .. (81.29,4.30)
 .. controls (92.45,0.34) and (86.69,1.06) .. (100.01,-2.90)
 .. controls (113.33,-6.87) and (110.81,-7.23) .. (121.97,-6.51)
 .. controls (133.13,-5.79) and (127.37,-5.79) .. (138.89,-5.07)
 .. controls (150.41,-4.36) and (144.65,-6.87) .. (161.93,-6.16)
 .. controls (179.21,-5.45) and (174.89,-6.52) .. (183.53,-4.37)
 .. controls (192.17,-2.21) and (204.78,-1.86) .. (206.58,-1.50)
 .. controls (208.38,-1.14) and (223.50,-0.06) .. (230.70,-2.22)
 .. controls (237.91,-4.37) and (233.94,-2.22) .. (245.47,-6.17)
 .. controls (256.99,-10.12) and (259.87,-11.20) .. (267.80,-14.07)
 .. controls (275.72,-16.94) and (282.20,-20.90) .. (287.96,-21.61)
 .. controls (293.72,-22.33) and (296.96,-25.20) .. (304.16,-24.84)
 .. controls (311.36,-24.47) and (307.04,-24.11) .. (317.48,-23.03)
 .. controls (327.91,-21.94) and (323.59,-20.86) .. (335.83,-23.37)
 .. controls (348.07,-25.88) and (343.39,-23.72) .. (356.34,-28.03)
 .. controls (369.30,-32.34) and (369.66,-31.26) .. (380.45,-35.95)
 .. controls (391.25,-40.63) and (396.29,-44.60) .. (402.40,-44.24)
 .. controls (408.52,-43.89) and (395.93,-43.52) .. (412.84,-42.81)
 .. controls (429.76,-42.11) and (426.88,-40.67) .. (438.40,-43.56)
 .. controls (449.92,-46.45) and (454.97,-50.05) .. (463.97,-49.33)
 .. controls (472.97,-48.60) and (471.89,-48.60) .. (475.85,-48.24)
 .. controls (479.81,-47.87) and (480.53,-54.36) .. (482.70,-54.35)
 .. controls (484.86,-54.35) and (488.10,-56.87) .. (496.02,-59.02)
 .. controls (503.94,-61.17) and (505.02,-57.21) .. (509.34,-64.77)
 .. controls (513.67,-72.32) and (513.31,-69.80) .. (516.91,-74.84)
 .. controls (520.51,-79.87) and (520.87,-84.19) .. (526.27,-85.98)
 .. controls (531.66,-87.77) and (530.94,-88.85) .. (544.97,-91.00)
 .. controls (559.00,-93.16) and (558.64,-92.80) .. (564.03,-94.96)
 .. controls (569.43,-97.13) and (573.75,-93.89) .. (577.35,-100.73)
 .. controls (580.95,-107.58) and (582.03,-111.18) .. (585.62,-117.67)
 .. controls (589.22,-124.15) and (589.58,-126.68) .. (591.38,-129.20)
 .. controls (593.18,-131.73) and (595.34,-137.86) .. (603.99,-141.11)
 .. controls (612.63,-144.37) and (612.27,-140.77) .. (615.87,-145.81)
 .. controls (619.47,-150.85) and (619.47,-150.85) .. (622.00,-154.81)
 .. controls (624.52,-158.77) and (618.03,-154.81) .. (626.32,-166.33)
 .. controls (634.61,-177.84) and (631.73,-179.64) .. (640.37,-180.36)
 .. controls (649.01,-181.08) and (654.41,-179.28) .. (660.53,-178.92)
 .. controls (666.65,-178.56) and (659.45,-174.96) .. (670.25,-179.28)
 .. controls (681.05,-183.60) and (681.41,-182.88) .. (684.64,-186.85)
 .. controls (687.88,-190.81) and (682.48,-190.09) .. (691.84,-195.14)
 .. controls (701.21,-200.19) and (704.09,-200.91) .. (705.53,-201.99)
 .. controls (706.97,-203.08) and (712.01,-208.47) .. (711.29,-213.51)
 .. controls (710.57,-218.55) and (708.41,-214.95) .. (708.41,-226.83)
 .. controls (708.42,-238.71) and (707.70,-240.14) .. (710.94,-244.82)
 .. controls (714.18,-249.50) and (715.12,-251.41) .. (717.78,-254.53)
 .. controls (723.90,-261.73) and (724.62,-262.09) .. (724.63,-265.33)
 .. controls (724.63,-268.56) and (723.55,-267.48) .. (725.71,-271.80)
 .. controls (727.87,-276.12) and (729.31,-277.56) .. (732.55,-281.15)
 .. controls (735.79,-284.74) and (738.68,-290.85) .. (745.51,-289.41)
 .. controls (752.35,-287.98) and (756.31,-287.61) .. (760.27,-288.32)
 .. controls (764.23,-289.03) and (760.64,-291.55) .. (769.63,-287.22)
 .. controls (778.64,-282.89) and (779.00,-286.11) .. (783.32,-280.71)
 .. controls (787.64,-275.30) and (790.16,-274.20) .. (791.24,-268.45)
 .. controls (792.32,-262.70) and (790.88,-256.24) .. (790.16,-253.37)
)));
current_src := "C1Ee.th2 [151]";
string area_border[];
area_border[1] := "l77-10108-2728";
drawoptions();
a_blocks(buildcycle(((61.15,57.94)
 .. controls (51.79,57.95) and (22.99,60.83) .. (4.27,64.43)
 .. controls (-14.45,68.03) and (-26.70,62.27) .. (-33.90,62.99)
 .. controls (-41.10,63.71) and (-41.10,64.43) .. (-52.62,64.43)
 .. controls (-64.14,64.43) and (-69.90,62.27) .. (-90.06,57.23)
 .. controls (-110.22,52.19) and (-121.02,44.27) .. (-143.34,40.67)
 .. controls (-165.66,37.06) and (-177.18,47.86) .. (-212.46,49.30)
 .. controls (-247.73,50.74) and (-239.81,57.22) .. (-272.46,51.71)
 .. controls (-305.12,46.20) and (-323.33,65.87) .. (-339.17,67.31)
 .. controls (-355.02,68.75) and (-405.43,73.07) .. (-414.79,74.50)
 .. controls (-424.15,75.94) and (-433.51,81.69) .. (-458.71,89.60)
 .. controls (-483.90,97.52) and (-479.58,96.80) .. (-499.02,104.00)
 .. controls (-518.46,111.20) and (-529.98,111.92) .. (-540.78,107.60)
 .. controls (-551.58,103.28) and (-574.62,100.40) .. (-581.97,94.37)
 .. controls (-589.31,88.33) and (-605.59,59.37) .. (-601.99,46.41)
 .. controls (-598.39,33.44) and (-517.74,35.59) .. (-488.21,29.12)
 .. controls (-458.69,22.64) and (-455.09,21.21) .. (-433.49,19.06)
 .. controls (-411.89,16.91) and (-392.45,6.84) .. (-360.77,-6.84)
 .. controls (-329.09,-20.52) and (-275.09,-12.62) .. (-257.81,-5.42)
 .. controls (-240.53,1.78) and (-153.41,-11.17) .. (-150.53,-10.45)
 .. controls (-147.65,-9.73) and (-84.29,-9.73) .. (-56.21,-8.29)
 .. controls (-28.14,-6.85) and (-0.78,-16.20) .. (32.34,-17.64)
 .. controls (65.45,-19.09) and (154.03,-29.91) .. (165.54,-21.28)
 .. controls (177.06,-12.65) and (172.73,1.04) .. (169.13,14.72)
 .. controls (165.54,28.40) and (147.55,50.01) .. (134.59,51.45)
 .. controls (121.63,52.89) and (70.51,57.94) .. cycle
)));
current_src := "C1Ee.th2 [100]";
string area_border[];
area_border[1] := "l75-14278-2188";
area_border[2] := "l7-14382-2156";
drawoptions();
a_water(buildcycle(((857.10,-38.53)
 -- (784.76,-37.81)
),
((790.16,-253.37)
 .. controls (790.16,-253.37) and (790.88,-251.92) .. (789.07,-249.41)
 .. controls (787.27,-246.91) and (789.08,-243.65) .. (782.95,-240.08)
 .. controls (776.81,-236.51) and (776.10,-237.23) .. (769.61,-232.20)
 .. controls (763.13,-227.17) and (762.05,-224.65) .. (757.37,-221.05)
 .. controls (752.69,-217.46) and (753.05,-215.66) .. (746.21,-210.98)
 .. controls (739.37,-206.31) and (735.41,-203.07) .. (731.45,-199.83)
 .. controls (727.49,-196.60) and (725.33,-193.72) .. (718.50,-186.51)
 .. controls (711.66,-179.31) and (711.66,-183.27) .. (707.34,-174.26)
 .. controls (703.02,-165.24) and (701.58,-163.80) .. (699.42,-155.52)
 .. controls (697.26,-147.24) and (701.95,-146.51) .. (697.63,-138.59)
 .. controls (693.32,-130.68) and (695.49,-126.35) .. (685.75,-122.77)
 .. controls (676.02,-119.18) and (669.18,-117.74) .. (660.18,-111.26)
 .. controls (651.18,-104.78) and (657.30,-106.22) .. (646.50,-102.25)
 .. controls (635.70,-98.28) and (634.99,-98.63) .. (627.42,-95.02)
 .. controls (619.86,-91.40) and (613.02,-93.92) .. (610.86,-84.55)
 .. controls (608.70,-75.18) and (609.42,-73.02) .. (608.70,-68.34)
 .. controls (607.98,-63.65) and (608.35,-58.97) .. (605.82,-56.09)
 .. controls (603.30,-53.21) and (604.38,-52.85) .. (598.26,-51.41)
 .. controls (592.13,-49.97) and (584.21,-47.09) .. (580.60,-46.37)
 .. controls (577.00,-45.66) and (573.76,-44.94) .. (571.96,-43.50)
 .. controls (570.16,-42.06) and (563.32,-42.06) .. (564.76,-35.22)
 .. controls (566.20,-28.38) and (564.04,-28.02) .. (567.64,-23.71)
 .. controls (571.24,-19.40) and (565.84,-20.12) .. (573.77,-18.33)
 .. controls (581.69,-16.53) and (582.05,-14.38) .. (588.54,-16.54)
 .. controls (595.02,-18.70) and (606.19,-17.98) .. (613.75,-15.10)
 .. controls (621.31,-12.22) and (620.23,-14.02) .. (625.98,-11.50)
 .. controls (631.74,-8.98) and (626.34,-7.18) .. (637.14,-7.54)
 .. controls (647.94,-7.89) and (638.94,-8.25) .. (658.37,-10.04)
 .. controls (677.80,-11.83) and (675.28,-11.83) .. (683.56,-11.11)
 .. controls (691.84,-10.40) and (694.00,-8.96) .. (703.71,-7.53)
 .. controls (713.43,-6.11) and (714.51,-3.95) .. (722.79,-6.85)
 .. controls (731.07,-9.75) and (729.99,-10.11) .. (739.00,-13.72)
 .. controls (748.00,-17.34) and (753.41,-25.97) .. (753.41,-25.97)
 .. controls (753.41,-25.97) and (756.30,-28.13) .. (759.54,-28.12)
 .. controls (762.78,-28.12) and (768.55,-30.27) .. (774.67,-27.74)
 .. controls (780.78,-25.22) and (780.42,-24.86) .. (784.02,-23.77)
 .. controls (787.62,-22.69) and (788.70,-19.81) .. (792.66,-22.69)
 .. controls (796.62,-25.56) and (797.70,-24.48) .. (799.86,-29.52)
 .. controls (802.03,-34.56) and (802.75,-36.00) .. (804.20,-38.88)
 .. controls (805.65,-41.75) and (808.18,-43.91) .. (808.91,-45.71)
 .. controls (809.63,-47.51) and (808.20,-48.94) .. (809.30,-51.46)
 .. controls (810.40,-53.97) and (814.40,-58.64) .. (814.40,-58.64)
 .. controls (814.40,-58.64) and (815.50,-60.43) .. (817.66,-59.71)
 .. controls (819.81,-58.99) and (820.53,-58.99) .. (822.66,-55.77)
 .. controls (824.79,-52.53) and (825.49,-48.94) .. (825.47,-47.15)
 .. controls (825.46,-45.35) and (825.03,-42.89) .. (826.17,-41.76)
 .. controls (827.96,-39.96) and (830.84,-40.68) .. (830.84,-40.68)
 .. controls (830.84,-40.68) and (831.18,-37.80) .. (830.49,-43.56)
 .. controls (829.80,-49.30) and (828.02,-50.38) .. (831.27,-52.54)
 .. controls (834.53,-54.69) and (836.73,-59.00) .. (839.60,-58.28)
 .. controls (842.47,-57.57) and (847.52,-59.00) .. (848.92,-55.42)
 .. controls (850.33,-51.83) and (850.67,-51.83) .. (851.02,-47.88)
 .. controls (851.70,-40.33) and (853.50,-36.37) .. (853.50,-36.37)
 .. controls (853.50,-36.37) and (846.66,-35.29) .. (856.02,-36.37)
 .. controls (865.38,-37.45) and (863.59,-38.13) .. (867.90,-37.81)
 .. controls (882.66,-36.73) and (883.02,-37.09) .. (889.50,-36.00)
)));
ATTR__id := "l66-19178-422";
ATTR__height := -1;
drawoptions();
l_border_invisible(((1249.00,-356.31)
 -- (1438.64,-357.50)
));
l_debug(0,0,((1426.34,-353.84)
 -- (1603.20,-357.35)
));
ATTR__id := "l71-11988-2560";
ATTR__height := -1;
drawoptions();
l_border_invisible(((362.08,17.68)
 .. controls (344.08,15.50) and (323.94,5.41) .. (324.66,-6.11)
 .. controls (325.39,-17.62) and (331.88,-33.45) .. (342.67,-39.92)
 .. controls (353.47,-46.39) and (344.85,-58.62) .. (400.97,-59.37)
 .. controls (457.13,-60.12) and (476.58,-73.08) .. (489.54,-69.47)
 .. controls (502.50,-65.86) and (516.90,-62.24) .. (527.69,-53.60)
 .. controls (538.49,-44.95) and (555.76,-31.26) .. (559.36,-26.94)
 .. controls (562.96,-22.63) and (570.89,-8.28) .. (570.89,-8.28)
 .. controls (570.89,-8.28) and (570.89,1.79) .. (552.89,6.83)
 .. controls (534.89,11.87) and (549.29,13.30) .. (515.45,18.35)
 .. controls (481.62,23.40) and (489.54,24.83) .. (455.71,27.01)
 .. controls (421.86,29.20) and (424.03,35.69) .. (400.25,29.21)
 .. controls (376.48,22.74) and (380.09,19.85) .. cycle
));
l_debug(0,0,((313.67,15.10)
 .. controls (296.95,13.43) and (278.08,4.45) .. (278.53,-6.24)
 .. controls (278.99,-16.93) and (284.70,-31.73) .. (294.59,-37.94)
 .. controls (304.49,-44.14) and (296.25,-55.33) .. (348.29,-57.03)
 .. controls (400.34,-58.73) and (418.12,-71.10) .. (430.20,-68.00)
 .. controls (442.28,-64.90) and (455.69,-61.83) .. (465.86,-54.02)
 .. controls (476.03,-46.21) and (492.30,-33.85) .. (495.72,-29.91)
 .. controls (499.13,-25.97) and (506.74,-12.77) .. (506.74,-12.77)
 .. controls (506.74,-12.77) and (506.93,-3.43) .. (490.33,1.58)
 .. controls (473.74,6.58) and (487.12,7.65) .. (455.84,12.94)
 .. controls (424.57,18.24) and (431.93,19.43) .. (400.61,22.05)
 .. controls (369.28,24.68) and (371.40,30.64) .. (349.26,25.07)
 .. controls (327.11,19.50) and (330.40,16.77) .. cycle
));
ATTR__id := "l73-14060-976";
ATTR__height := -1;
drawoptions();
l_border_invisible(((830.51,-255.25)
 -- (686.84,-256.65)
));
l_debug(0,0,((742.43,-247.79)
 -- (609.62,-245.15)
));
ATTR__id := "l77-10108-2728";
ATTR__height := -1;
drawoptions();
l_border_invisible(((61.15,57.94)
 .. controls (51.79,57.95) and (22.99,60.83) .. (4.27,64.43)
 .. controls (-14.45,68.03) and (-26.70,62.27) .. (-33.90,62.99)
 .. controls (-41.10,63.71) and (-41.10,64.43) .. (-52.62,64.43)
 .. controls (-64.14,64.43) and (-69.90,62.27) .. (-90.06,57.23)
 .. controls (-110.22,52.19) and (-121.02,44.27) .. (-143.34,40.67)
 .. controls (-165.66,37.06) and (-177.18,47.86) .. (-212.46,49.30)
 .. controls (-247.73,50.74) and (-239.81,57.22) .. (-272.46,51.71)
 .. controls (-305.12,46.20) and (-323.33,65.87) .. (-339.17,67.31)
 .. controls (-355.02,68.75) and (-405.43,73.07) .. (-414.79,74.50)
 .. controls (-424.15,75.94) and (-433.51,81.69) .. (-458.71,89.60)
 .. controls (-483.90,97.52) and (-479.58,96.80) .. (-499.02,104.00)
 .. controls (-518.46,111.20) and (-529.98,111.92) .. (-540.78,107.60)
 .. controls (-551.58,103.28) and (-574.62,100.40) .. (-581.97,94.37)
 .. controls (-589.31,88.33) and (-605.59,59.37) .. (-601.99,46.41)
 .. controls (-598.39,33.44) and (-517.74,35.59) .. (-488.21,29.12)
 .. controls (-458.69,22.64) and (-455.09,21.21) .. (-433.49,19.06)
 .. controls (-411.89,16.91) and (-392.45,6.84) .. (-360.77,-6.84)
 .. controls (-329.09,-20.52) and (-275.09,-12.62) .. (-257.81,-5.42)
 .. controls (-240.53,1.78) and (-153.41,-11.17) .. (-150.53,-10.45)
 .. controls (-147.65,-9.73) and (-84.29,-9.73) .. (-56.21,-8.29)
 .. controls (-28.14,-6.85) and (-0.78,-16.20) .. (32.34,-17.64)
 .. controls (65.45,-19.09) and (154.03,-29.91) .. (165.54,-21.28)
 .. controls (177.06,-12.65) and (172.73,1.04) .. (169.13,14.72)
 .. controls (165.54,28.40) and (147.55,50.01) .. (134.59,51.45)
 .. controls (121.63,52.89) and (70.51,57.94) .. cycle
));
l_debug(0,0,((35.44,58.01)
 .. controls (26.77,58.18) and (0.13,61.38) .. (-17.16,65.06)
 .. controls (-34.45,68.74) and (-45.90,63.63) .. (-52.56,64.43)
 .. controls (-59.22,65.23) and (-59.21,65.90) .. (-69.89,66.11)
 .. controls (-80.56,66.32) and (-85.94,64.43) .. (-104.72,60.12)
 .. controls (-123.50,55.82) and (-133.66,48.68) .. (-154.41,45.75)
 .. controls (-175.17,42.83) and (-185.65,53.05) .. (-218.32,55.04)
 .. controls (-251.00,57.02) and (-243.54,62.88) .. (-273.91,58.37)
 .. controls (-304.27,53.86) and (-320.80,72.43) .. (-335.46,74.05)
 .. controls (-350.11,75.68) and (-396.75,80.61) .. (-405.40,82.12)
 .. controls (-414.05,83.62) and (-422.62,89.14) .. (-445.83,96.94)
 .. controls (-469.05,104.75) and (-465.05,104.00) .. (-482.94,111.03)
 .. controls (-500.83,118.06) and (-511.49,118.94) .. (-521.58,115.14)
 .. controls (-531.67,111.33) and (-553.08,109.08) .. (-560.00,103.62)
 .. controls (-566.92,98.16) and (-582.54,71.61) .. (-579.44,59.53)
 .. controls (-576.34,47.45) and (-501.55,47.97) .. (-474.31,41.42)
 .. controls (-447.06,34.87) and (-443.75,33.47) .. (-423.77,31.07)
 .. controls (-403.79,28.67) and (-385.96,18.97) .. (-356.84,5.71)
 .. controls (-327.73,-7.56) and (-277.53,-1.21) .. (-261.38,5.15)
 .. controls (-245.23,11.50) and (-164.71,-2.11) .. (-162.03,-1.50)
 .. controls (-159.35,-0.88) and (-100.62,-2.05) .. (-74.56,-1.23)
 .. controls (-48.51,-0.41) and (-23.32,-9.59) .. (7.36,-11.54)
 .. controls (38.03,-13.48) and (119.92,-25.12) .. (130.76,-17.32)
 .. controls (141.60,-9.53) and (137.84,3.23) .. (134.76,15.98)
 .. controls (131.67,28.73) and (115.39,49.08) .. (103.40,50.65)
 .. controls (91.41,52.23) and (44.12,57.84) .. cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((-931.04,198.39)
 .. controls (-929.60,191.19) and (-928.88,185.43) .. (-922.40,178.95)
 .. controls (-915.92,172.47) and (-917.36,171.03) .. (-908.00,167.44)
 .. controls (-898.63,163.84) and (-901.51,163.12) .. (-887.11,155.92)
 .. controls (-872.71,148.72) and (-863.35,141.52) .. (-855.43,142.24)
 .. controls (-847.51,142.96) and (-843.19,144.40) .. (-839.59,143.68)
));
l_debug(0,0,((-881.64,206.41)
 .. controls (-880.44,199.71) and (-879.88,194.36) .. (-873.99,188.23)
 .. controls (-868.10,182.10) and (-869.47,180.80) .. (-860.86,177.29)
 .. controls (-852.25,173.78) and (-854.93,173.16) .. (-841.71,166.22)
 .. controls (-828.50,159.29) and (-819.95,152.44) .. (-812.60,152.96)
 .. controls (-805.24,153.48) and (-801.21,154.74) .. (-797.89,154.00)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-887.83,257.46)
 .. controls (-887.83,257.46) and (-883.51,243.77) .. (-879.19,240.89)
 .. controls (-874.87,238.01) and (-874.15,236.57) .. (-862.63,231.53)
 .. controls (-851.10,226.50) and (-856.14,226.50) .. (-845.34,221.46)
 .. controls (-834.54,216.42) and (-832.38,214.98) .. (-820.14,207.78)
 .. controls (-807.89,200.57) and (-793.49,194.81) .. (-793.49,194.81)
));
l_debug(0,0,((-840.51,260.34)
 .. controls (-840.51,260.34) and (-836.76,247.58) .. (-832.81,244.83)
 .. controls (-828.86,242.08) and (-828.22,240.73) .. (-817.63,235.85)
 .. controls (-807.04,230.97) and (-811.72,231.06) .. (-801.80,226.19)
 .. controls (-791.88,221.32) and (-789.90,219.94) .. (-778.69,213.04)
 .. controls (-767.48,206.15) and (-754.24,200.54) .. (-754.24,200.54)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-818.65,304.28)
 .. controls (-814.33,294.19) and (-814.33,295.63) .. (-803.54,280.51)
 .. controls (-792.74,265.38) and (-788.43,252.42) .. (-782.67,248.82)
 .. controls (-776.91,245.21) and (-774.75,243.05) .. (-768.99,239.45)
 .. controls (-763.23,235.85) and (-756.75,232.25) .. (-756.75,232.25)
));
l_debug(0,0,((-775.58,302.45)
 .. controls (-771.76,293.03) and (-771.74,294.36) .. (-762.00,280.15)
 .. controls (-752.27,265.93) and (-748.50,253.84) .. (-743.23,250.40)
 .. controls (-737.96,246.95) and (-736.00,244.91) .. (-730.72,241.47)
 .. controls (-725.45,238.03) and (-719.51,234.57) .. (-719.51,234.57)
));
endfig;
beginfig(5);
draw_upscrap(1)(1,((393.84,102.29)
 .. controls (393.84,102.29) and (395.64,93.29) .. (378.36,90.40)
 .. controls (361.07,87.51) and (332.62,88.54) .. (323.25,86.73)
 .. controls (313.89,84.92) and (323.25,85.29) .. (298.40,86.35)
 .. controls (273.56,87.41) and (250.86,92.83) .. (243.66,93.92)
 .. controls (236.46,95.00) and (236.10,95.37) .. (230.70,96.09)
 .. controls (225.30,96.82) and (217.38,90.70) .. (206.22,94.31)
 .. controls (195.06,97.92) and (178.01,97.52) .. (166.38,104.57)
 .. controls (154.75,111.62) and (157.63,115.58) .. (142.50,120.26)
 .. controls (127.38,124.94) and (106.51,138.61) .. (99.67,141.48)
 .. controls (92.84,144.36) and (85.64,145.80) .. (73.41,146.52)
 .. controls (61.17,147.24) and (58.66,149.76) .. (46.06,147.60)
 .. controls (33.47,145.44) and (27.00,147.96) .. (16.92,144.00)
 .. controls (6.84,140.04) and (6.48,141.48) .. (2.88,138.60)
 .. controls (-0.72,135.72) and (-20.17,126.00) .. (-34.21,121.68)
 .. controls (-48.26,117.36) and (-55.46,115.92) .. (-66.98,114.48)
 .. controls (-78.51,113.04) and (-67.35,113.04) .. (-95.43,109.80)
 .. controls (-123.52,106.55) and (-114.16,105.11) .. (-131.44,105.11)
 .. controls (-148.72,105.11) and (-141.52,106.55) .. (-159.53,105.11)
 .. controls (-177.53,103.67) and (-167.09,103.31) .. (-185.81,102.58)
 .. controls (-204.53,101.86) and (-209.93,101.86) .. (-209.93,101.86)
 .. controls (-209.93,101.86) and (-222.17,101.86) .. (-236.57,102.94)
 .. controls (-250.97,104.02) and (-251.69,108.70) .. (-268.25,108.34)
 .. controls (-284.81,107.98) and (-288.41,106.18) .. (-302.81,109.07)
 .. controls (-317.21,111.95) and (-334.49,121.67) .. (-344.21,122.03)
 .. controls (-353.93,122.39) and (-352.85,125.64) .. (-366.17,124.91)
 .. controls (-379.50,124.19) and (-383.10,122.03) .. (-396.78,124.55)
 .. controls (-410.46,127.06) and (-412.62,127.42) .. (-420.90,130.30)
 .. controls (-429.18,133.18) and (-428.10,123.10) .. (-433.50,135.34)
 .. controls (-438.89,147.58) and (-438.87,176.38) .. (-449.29,194.74)
 .. controls (-459.71,213.10) and (-457.55,214.55) .. (-461.84,228.59)
 .. controls (-466.14,242.64) and (-467.18,255.96) .. (-474.37,262.80)
 .. controls (-481.56,269.65) and (-483.34,275.77) .. (-495.22,280.09)
 .. controls (-507.10,284.41) and (-505.65,287.65) .. (-517.55,285.49)
 .. controls (-529.44,283.33) and (-541.32,288.37) .. (-561.48,291.98)
 .. controls (-581.65,295.58) and (-579.84,297.74) .. (-594.97,298.82)
 .. controls (-610.09,299.91) and (-608.65,302.07) .. (-621.62,302.07)
 .. controls (-634.58,302.07) and (-637.47,299.55) .. (-651.51,302.08)
 .. controls (-665.56,304.60) and (-665.55,307.49) .. (-678.88,307.13)
 .. controls (-692.21,306.77) and (-706.63,302.45) .. (-716.34,313.62)
 .. controls (-726.04,324.79) and (-716.31,326.23) .. (-735.40,330.55)
 .. controls (-754.49,334.88) and (-764.93,339.92) .. (-773.21,339.57)
 .. controls (-781.50,339.21) and (-778.25,342.09) .. (-792.66,341.37)
 .. controls (-807.08,340.65) and (-829.78,337.77) .. (-834.10,339.93)
 .. controls (-838.42,342.10) and (-839.50,342.82) .. (-853.19,344.62)
 .. controls (-866.88,346.42) and (-873.00,347.14) .. (-873.00,347.14)
 .. controls (-873.00,347.14) and (-875.52,347.86) .. (-885.26,345.70)
 .. controls (-894.99,343.53) and (-892.82,344.61) .. (-906.52,341.37)
 .. controls (-920.21,338.13) and (-923.46,334.88) .. (-938.23,332.72)
 .. controls (-953.00,330.56) and (-954.80,329.48) .. (-961.65,328.03)
 .. controls (-968.49,326.59) and (-981.10,321.55) .. (-986.51,320.83)
 .. controls (-991.91,320.10) and (-992.63,317.58) .. (-996.23,320.46)
 .. controls (-999.84,323.34) and (-1001.28,321.54) .. (-1002.72,327.66)
 .. controls (-1004.16,333.78) and (-1004.88,336.30) .. (-1003.45,344.22)
 .. controls (-1002.01,352.15) and (-1000.21,361.87) .. (-998.76,363.67)
),
1,((-1438.64,366.84)
 .. controls (-1437.92,364.68) and (-1436.48,360.72) .. (-1435.40,359.64)
 .. controls (-1434.32,358.56) and (-1429.28,356.76) .. (-1425.32,354.24)
 .. controls (-1421.36,351.72) and (-1417.04,348.48) .. (-1413.80,345.24)
 .. controls (-1410.56,342.00) and (-1410.56,342.36) .. (-1408.40,339.48)
 .. controls (-1406.24,336.60) and (-1406.60,335.16) .. (-1402.64,334.44)
 .. controls (-1398.68,333.72) and (-1399.04,335.16) .. (-1392.56,331.20)
 .. controls (-1386.08,327.24) and (-1386.80,326.52) .. (-1383.56,326.16)
 .. controls (-1380.32,325.80) and (-1377.44,326.52) .. (-1374.56,326.52)
 .. controls (-1371.68,326.52) and (-1371.99,328.18) .. (-1369.16,325.80)
 .. controls (-1362.32,320.04) and (-1358.72,319.32) .. (-1354.76,320.04)
 .. controls (-1350.80,320.76) and (-1352.96,321.12) .. (-1345.76,321.12)
 .. controls (-1338.56,321.11) and (-1338.56,322.55) .. (-1335.68,321.11)
 .. controls (-1332.80,319.67) and (-1331.72,316.79) .. (-1324.88,314.27)
 .. controls (-1318.04,311.75) and (-1305.44,307.79) .. (-1301.48,306.35)
 .. controls (-1297.52,304.91) and (-1294.28,303.47) .. (-1291.04,300.23)
 .. controls (-1287.80,296.99) and (-1292.84,299.15) .. (-1285.28,295.55)
 .. controls (-1277.72,291.95) and (-1276.28,291.23) .. (-1271.96,290.15)
 .. controls (-1267.64,289.07) and (-1267.64,286.55) .. (-1261.16,287.27)
 .. controls (-1254.68,287.99) and (-1254.32,286.91) .. (-1248.92,288.71)
 .. controls (-1243.52,290.51) and (-1243.88,292.31) .. (-1239.92,291.23)
 .. controls (-1235.96,290.15) and (-1229.48,289.07) .. (-1223.72,288.71)
 .. controls (-1217.96,288.35) and (-1217.24,288.35) .. (-1215.80,287.99)
 .. controls (-1214.36,287.63) and (-1212.21,280.06) .. (-1210.05,278.26)
 .. controls (-1207.89,276.45) and (-1203.22,272.48) .. (-1199.98,272.48)
 .. controls (-1196.73,272.48) and (-1200.69,273.92) .. (-1194.21,271.75)
 .. controls (-1187.73,269.58) and (-1190.25,269.94) .. (-1184.49,268.14)
 .. controls (-1178.73,266.33) and (-1176.21,263.43) .. (-1170.80,263.79)
 .. controls (-1165.40,264.15) and (-1161.17,264.03) .. (-1158.91,262.35)
 .. controls (-1153.14,258.05) and (-1151.70,257.34) .. (-1148.46,256.99)
 .. controls (-1145.22,256.65) and (-1147.02,256.64) .. (-1143.06,256.66)
 .. controls (-1139.11,256.67) and (-1132.64,256.67) .. (-1132.64,256.67)
 .. controls (-1132.64,256.67) and (-1130.84,259.19) .. (-1130.84,254.87)
 .. controls (-1130.84,250.56) and (-1131.55,251.64) .. (-1130.47,248.40)
 .. controls (-1129.39,245.16) and (-1127.95,245.88) .. (-1127.59,239.04)
 .. controls (-1127.22,232.20) and (-1128.30,232.56) .. (-1127.94,229.32)
 .. controls (-1127.57,226.08) and (-1125.77,223.56) .. (-1125.77,216.36)
 .. controls (-1125.76,209.16) and (-1125.40,203.40) .. (-1126.83,198.72)
 .. controls (-1128.27,194.03) and (-1131.15,202.67) .. (-1128.63,190.79)
 .. controls (-1126.10,178.92) and (-1127.89,164.15) .. (-1127.17,160.92)
 .. controls (-1126.45,157.68) and (-1126.08,155.88) .. (-1126.08,151.56)
 .. controls (-1126.08,147.24) and (-1125.72,141.48) .. (-1126.07,138.96)
 .. controls (-1126.43,136.44) and (-1127.87,134.64) .. (-1125.71,132.84)
 .. controls (-1123.55,131.04) and (-1124.63,127.08) .. (-1117.43,129.61)
 .. controls (-1110.24,132.13) and (-1110.96,132.85) .. (-1103.77,134.30)
 .. controls (-1096.58,135.74) and (-1102.33,137.18) .. (-1090.46,136.10)
 .. controls (-1078.60,135.02) and (-1083.27,135.38) .. (-1074.64,134.30)
 .. controls (-1066.00,133.22) and (-1069.24,132.86) .. (-1056.29,132.86)
 .. controls (-1043.34,132.86) and (-1041.54,132.50) .. (-1031.82,132.50)
 .. controls (-1022.10,132.50) and (-1011.66,125.66) .. (-999.79,129.98)
 .. controls (-987.91,134.30) and (-983.95,139.34) .. (-974.95,139.34)
 .. controls (-965.95,139.35) and (-963.79,138.27) .. (-961.99,138.27)
 .. controls (-960.19,138.27) and (-961.27,136.11) .. (-952.99,135.39)
 .. controls (-944.71,134.67) and (-940.75,131.79) .. (-930.67,128.55)
 .. controls (-920.59,125.31) and (-920.23,126.39) .. (-913.75,122.79)
 .. controls (-907.27,119.20) and (-906.19,118.12) .. (-903.31,115.60)
 .. controls (-900.43,113.08) and (-900.43,111.64) .. (-894.67,109.48)
 .. controls (-888.91,107.32) and (-890.35,104.08) .. (-882.79,105.52)
 .. controls (-875.23,106.96) and (-879.55,109.84) .. (-869.47,108.04)
 .. controls (-859.39,106.24) and (-848.23,104.44) .. (-836.71,106.60)
 .. controls (-825.19,108.76) and (-832.03,111.64) .. (-817.63,109.84)
 .. controls (-803.23,108.04) and (-803.61,109.74) .. (-797.11,108.40)
),
1,((-797.11,108.40)
 .. controls (-797.11,108.40) and (-793.87,108.76) .. (-790.99,108.04)
 .. controls (-788.11,107.32) and (-789.91,108.76) .. (-785.23,106.96)
 .. controls (-780.55,105.16) and (-778.75,104.80) .. (-773.35,100.48)
 .. controls (-767.95,96.15) and (-768.67,96.87) .. (-765.79,93.99)
 .. controls (-762.91,91.11) and (-767.23,91.83) .. (-759.68,88.95)
 .. controls (-752.12,86.06) and (-755.00,88.95) .. (-749.60,85.34)
 .. controls (-744.20,81.74) and (-734.48,80.65) .. (-726.92,80.29)
 .. controls (-719.35,79.93) and (-718.27,79.20) .. (-713.23,79.56)
 .. controls (-708.19,79.92) and (-710.35,78.12) .. (-699.55,78.48)
 .. controls (-688.75,78.83) and (-689.47,77.75) .. (-678.31,77.75)
 .. controls (-667.15,77.75) and (-666.79,78.11) .. (-655.27,77.38)
 .. controls (-643.75,76.66) and (-646.63,78.10) .. (-640.51,76.66)
 .. controls (-634.39,75.22) and (-629.71,75.94) .. (-624.31,71.98)
 .. controls (-618.91,68.01) and (-622.15,69.45) .. (-615.31,66.21)
 .. controls (-608.47,62.97) and (-607.75,61.17) .. (-600.91,60.09)
 .. controls (-594.07,59.01) and (-594.79,58.29) .. (-588.31,59.72)
 .. controls (-581.83,61.16) and (-581.83,62.24) .. (-575.35,63.32)
 .. controls (-568.87,64.40) and (-568.51,66.20) .. (-561.31,65.12)
 .. controls (-554.10,64.04) and (-548.70,61.16) .. (-540.06,60.44)
 .. controls (-531.42,59.72) and (-533.22,59.72) .. (-524.22,59.00)
 .. controls (-515.22,58.28) and (-511.26,57.92) .. (-501.54,56.84)
 .. controls (-491.82,55.76) and (-496.86,54.32) .. (-483.90,54.32)
 .. controls (-470.94,54.32) and (-471.30,53.24) .. (-466.26,54.32)
 .. controls (-461.22,55.40) and (-457.62,50.37) .. (-451.14,50.37)
 .. controls (-444.66,50.37) and (-432.78,48.94) .. (-426.30,47.50)
 .. controls (-419.82,46.06) and (-420.54,48.58) .. (-410.10,44.99)
 .. controls (-399.66,41.39) and (-400.02,41.75) .. (-396.06,38.15)
 .. controls (-392.10,34.55) and (-393.54,35.27) .. (-389.94,31.67)
 .. controls (-386.34,28.07) and (-385.98,25.56) .. (-380.94,26.28)
 .. controls (-375.90,27.00) and (-375.54,26.64) .. (-370.14,27.71)
 .. controls (-364.74,28.79) and (-363.30,28.43) .. (-354.30,27.35)
 .. controls (-345.30,26.27) and (-341.70,26.27) .. (-337.74,25.19)
 .. controls (-333.78,24.11) and (-335.58,25.91) .. (-326.22,21.59)
 .. controls (-316.86,17.27) and (-321.18,15.11) .. (-310.38,14.74)
 .. controls (-299.58,14.38) and (-303.54,17.62) .. (-293.46,14.02)
 .. controls (-283.38,10.42) and (-285.90,9.34) .. (-275.10,7.90)
 .. controls (-264.29,6.46) and (-275.09,3.58) .. (-258.89,5.74)
 .. controls (-242.69,7.90) and (-233.67,7.76) .. (-229.01,8.26)
 .. controls (-215.69,9.70) and (-216.05,9.70) .. (-204.89,10.06)
 .. controls (-193.73,10.42) and (-191.57,8.26) .. (-179.33,10.78)
 .. controls (-167.09,13.31) and (-177.89,11.86) .. (-164.57,14.03)
),
1,((-164.57,14.03)
 .. controls (-164.57,14.03) and (-156.29,14.03) .. (-154.86,14.75)
 .. controls (-153.42,15.47) and (-139.38,14.75) .. (-127.14,16.19)
 .. controls (-114.90,17.63) and (-129.30,20.51) .. (-110.22,17.99)
 .. controls (-91.14,15.47) and (-94.38,14.75) .. (-80.34,13.67)
 .. controls (-66.30,12.59) and (-65.94,10.79) .. (-59.10,11.51)
 .. controls (-52.26,12.23) and (-59.10,14.39) .. (-45.78,12.23)
 .. controls (-32.46,10.07) and (-29.94,8.99) .. (-23.82,8.99)
 .. controls (-17.70,8.99) and (-6.18,6.11) .. (-1.50,7.55)
 .. controls (3.18,8.99) and (18.52,6.03) .. (28.02,6.84)
 .. controls (49.26,8.63) and (47.46,10.79) .. (58.98,8.63)
 .. controls (70.50,6.47) and (70.14,8.26) .. (81.29,4.30)
 .. controls (92.45,0.34) and (86.69,1.06) .. (100.01,-2.90)
 .. controls (113.33,-6.87) and (110.81,-7.23) .. (121.97,-6.51)
 .. controls (133.13,-5.79) and (127.37,-5.79) .. (138.89,-5.07)
 .. controls (150.41,-4.36) and (144.65,-6.87) .. (161.93,-6.16)
 .. controls (179.21,-5.45) and (174.89,-6.52) .. (183.53,-4.37)
 .. controls (192.17,-2.21) and (204.78,-1.86) .. (206.58,-1.50)
 .. controls (208.38,-1.14) and (223.50,-0.06) .. (230.70,-2.22)
 .. controls (237.91,-4.37) and (233.94,-2.22) .. (245.47,-6.17)
 .. controls (256.99,-10.12) and (259.87,-11.20) .. (267.80,-14.07)
 .. controls (275.72,-16.94) and (282.20,-20.90) .. (287.96,-21.61)
 .. controls (293.72,-22.33) and (296.96,-25.20) .. (304.16,-24.84)
 .. controls (311.36,-24.47) and (307.04,-24.11) .. (317.48,-23.03)
 .. controls (327.91,-21.94) and (323.59,-20.86) .. (335.83,-23.37)
 .. controls (348.07,-25.88) and (343.39,-23.72) .. (356.34,-28.03)
 .. controls (369.30,-32.34) and (369.66,-31.26) .. (380.45,-35.95)
 .. controls (391.25,-40.63) and (396.29,-44.60) .. (402.40,-44.24)
 .. controls (408.52,-43.89) and (395.93,-43.52) .. (412.84,-42.81)
 .. controls (429.76,-42.11) and (426.88,-40.67) .. (438.40,-43.56)
 .. controls (449.92,-46.45) and (454.97,-50.05) .. (463.97,-49.33)
 .. controls (472.97,-48.60) and (471.89,-48.60) .. (475.85,-48.24)
 .. controls (479.81,-47.87) and (480.53,-54.36) .. (482.70,-54.35)
 .. controls (484.86,-54.35) and (488.10,-56.87) .. (496.02,-59.02)
 .. controls (503.94,-61.17) and (505.02,-57.21) .. (509.34,-64.77)
 .. controls (513.67,-72.32) and (513.31,-69.80) .. (516.91,-74.84)
 .. controls (520.51,-79.87) and (520.87,-84.19) .. (526.27,-85.98)
 .. controls (531.66,-87.77) and (530.94,-88.85) .. (544.97,-91.00)
 .. controls (559.00,-93.16) and (558.64,-92.80) .. (564.03,-94.96)
 .. controls (569.43,-97.13) and (573.75,-93.89) .. (577.35,-100.73)
 .. controls (580.95,-107.58) and (582.03,-111.18) .. (585.62,-117.67)
 .. controls (589.22,-124.15) and (589.58,-126.68) .. (591.38,-129.20)
 .. controls (593.18,-131.73) and (595.34,-137.86) .. (603.99,-141.11)
 .. controls (612.63,-144.37) and (612.27,-140.77) .. (615.87,-145.81)
 .. controls (619.47,-150.85) and (619.47,-150.85) .. (622.00,-154.81)
 .. controls (624.52,-158.77) and (618.03,-154.81) .. (626.32,-166.33)
 .. controls (634.61,-177.84) and (631.73,-179.64) .. (640.37,-180.36)
 .. controls (649.01,-181.08) and (654.41,-179.28) .. (660.53,-178.92)
 .. controls (666.65,-178.56) and (659.45,-174.96) .. (670.25,-179.28)
 .. controls (681.05,-183.60) and (681.41,-182.88) .. (684.64,-186.85)
 .. controls (687.88,-190.81) and (682.48,-190.09) .. (691.84,-195.14)
 .. controls (701.21,-200.19) and (704.09,-200.91) .. (705.53,-201.99)
 .. controls (706.97,-203.08) and (712.01,-208.47) .. (711.29,-213.51)
 .. controls (710.57,-218.55) and (708.41,-214.95) .. (708.41,-226.83)
 .. controls (708.42,-238.71) and (707.70,-240.14) .. (710.94,-244.82)
 .. controls (714.18,-249.50) and (715.12,-251.41) .. (717.78,-254.53)
 .. controls (723.90,-261.73) and (724.62,-262.09) .. (724.63,-265.33)
 .. controls (724.63,-268.56) and (723.55,-267.48) .. (725.71,-271.80)
 .. controls (727.87,-276.12) and (729.31,-277.56) .. (732.55,-281.15)
 .. controls (735.79,-284.74) and (738.68,-290.85) .. (745.51,-289.41)
 .. controls (752.35,-287.98) and (756.31,-287.61) .. (760.27,-288.32)
 .. controls (764.23,-289.03) and (760.64,-291.55) .. (769.63,-287.22)
 .. controls (778.64,-282.89) and (779.00,-286.11) .. (783.32,-280.71)
 .. controls (787.64,-275.30) and (790.16,-274.20) .. (791.24,-268.45)
 .. controls (792.32,-262.70) and (790.88,-256.24) .. (790.16,-253.37)
),
1,((790.16,-253.37)
 .. controls (790.16,-253.37) and (790.88,-251.92) .. (789.07,-249.41)
 .. controls (787.27,-246.91) and (789.08,-243.65) .. (782.95,-240.08)
 .. controls (776.81,-236.51) and (776.10,-237.23) .. (769.61,-232.20)
 .. controls (763.13,-227.17) and (762.05,-224.65) .. (757.37,-221.05)
 .. controls (752.69,-217.46) and (753.05,-215.66) .. (746.21,-210.98)
 .. controls (739.37,-206.31) and (735.41,-203.07) .. (731.45,-199.83)
 .. controls (727.49,-196.60) and (725.33,-193.72) .. (718.50,-186.51)
 .. controls (711.66,-179.31) and (711.66,-183.27) .. (707.34,-174.26)
 .. controls (703.02,-165.24) and (701.58,-163.80) .. (699.42,-155.52)
 .. controls (697.26,-147.24) and (701.95,-146.51) .. (697.63,-138.59)
 .. controls (693.32,-130.68) and (695.49,-126.35) .. (685.75,-122.77)
 .. controls (676.02,-119.18) and (669.18,-117.74) .. (660.18,-111.26)
 .. controls (651.18,-104.78) and (657.30,-106.22) .. (646.50,-102.25)
 .. controls (635.70,-98.28) and (634.99,-98.63) .. (627.42,-95.02)
 .. controls (619.86,-91.40) and (613.02,-93.92) .. (610.86,-84.55)
 .. controls (608.70,-75.18) and (609.42,-73.02) .. (608.70,-68.34)
 .. controls (607.98,-63.65) and (608.35,-58.97) .. (605.82,-56.09)
 .. controls (603.30,-53.21) and (604.38,-52.85) .. (598.26,-51.41)
 .. controls (592.13,-49.97) and (584.21,-47.09) .. (580.60,-46.37)
 .. controls (577.00,-45.66) and (573.76,-44.94) .. (571.96,-43.50)
 .. controls (570.16,-42.06) and (563.32,-42.06) .. (564.76,-35.22)
 .. controls (566.20,-28.38) and (564.04,-28.02) .. (567.64,-23.71)
 .. controls (571.24,-19.40) and (565.84,-20.12) .. (573.77,-18.33)
 .. controls (581.69,-16.53) and (582.05,-14.38) .. (588.54,-16.54)
 .. controls (595.02,-18.70) and (606.19,-17.98) .. (613.75,-15.10)
 .. controls (621.31,-12.22) and (620.23,-14.02) .. (625.98,-11.50)
 .. controls (631.74,-8.98) and (626.34,-7.18) .. (637.14,-7.54)
 .. controls (647.94,-7.89) and (638.94,-8.25) .. (658.37,-10.04)
 .. controls (677.80,-11.83) and (675.28,-11.83) .. (683.56,-11.11)
 .. controls (691.84,-10.40) and (694.00,-8.96) .. (703.71,-7.53)
 .. controls (713.43,-6.11) and (714.51,-3.95) .. (722.79,-6.85)
 .. controls (731.07,-9.75) and (729.99,-10.11) .. (739.00,-13.72)
 .. controls (748.00,-17.34) and (753.41,-25.97) .. (753.41,-25.97)
 .. controls (753.41,-25.97) and (756.30,-28.13) .. (759.54,-28.12)
 .. controls (762.78,-28.12) and (768.55,-30.27) .. (774.67,-27.74)
 .. controls (780.78,-25.22) and (780.42,-24.86) .. (784.02,-23.77)
 .. controls (787.62,-22.69) and (788.70,-19.81) .. (792.66,-22.69)
 .. controls (796.62,-25.56) and (797.70,-24.48) .. (799.86,-29.52)
 .. controls (802.03,-34.56) and (802.75,-36.00) .. (804.20,-38.88)
 .. controls (805.65,-41.75) and (808.18,-43.91) .. (808.91,-45.71)
 .. controls (809.63,-47.51) and (808.20,-48.94) .. (809.30,-51.46)
 .. controls (810.40,-53.97) and (814.40,-58.64) .. (814.40,-58.64)
 .. controls (814.40,-58.64) and (815.50,-60.43) .. (817.66,-59.71)
 .. controls (819.81,-58.99) and (820.53,-58.99) .. (822.66,-55.77)
 .. controls (824.79,-52.53) and (825.49,-48.94) .. (825.47,-47.15)
 .. controls (825.46,-45.35) and (825.03,-42.89) .. (826.17,-41.76)
 .. controls (827.96,-39.96) and (830.84,-40.68) .. (830.84,-40.68)
 .. controls (830.84,-40.68) and (831.18,-37.80) .. (830.49,-43.56)
 .. controls (829.80,-49.30) and (828.02,-50.38) .. (831.27,-52.54)
 .. controls (834.53,-54.69) and (836.73,-59.00) .. (839.60,-58.28)
 .. controls (842.47,-57.57) and (847.52,-59.00) .. (848.92,-55.42)
 .. controls (850.33,-51.83) and (850.67,-51.83) .. (851.02,-47.88)
 .. controls (851.70,-40.33) and (853.50,-36.37) .. (853.50,-36.37)
 .. controls (853.50,-36.37) and (846.66,-35.29) .. (856.02,-36.37)
 .. controls (865.38,-37.45) and (863.59,-38.13) .. (867.90,-37.81)
 .. controls (882.66,-36.73) and (883.02,-37.09) .. (889.50,-36.00)
),
1,((889.50,-36.00)
 .. controls (889.50,-36.00) and (898.14,-34.92) .. (905.34,-35.64)
 .. controls (912.54,-36.35) and (922.62,-37.79) .. (925.13,-36.71)
 .. controls (927.65,-35.63) and (931.96,-31.67) .. (934.84,-31.67)
 .. controls (937.72,-31.67) and (938.08,-31.67) .. (943.12,-30.95)
 .. controls (948.16,-30.23) and (956.44,-34.56) .. (961.84,-33.84)
 .. controls (967.24,-33.12) and (985.26,-39.25) .. (991.74,-40.34)
 .. controls (998.22,-41.42) and (1002.55,-42.85) .. (1006.14,-42.49)
 .. controls (1009.74,-42.13) and (1011.18,-42.13) .. (1015.14,-44.28)
 .. controls (1019.10,-46.44) and (1019.10,-46.44) .. (1025.22,-48.60)
 .. controls (1031.34,-50.75) and (1044.67,-56.50) .. (1046.84,-57.94)
 .. controls (1049.01,-59.38) and (1052.99,-62.26) .. (1058.75,-64.41)
),
1,((1018.35,-105.07)
 -- (1018.46,-117.73)
 .. controls (1018.46,-117.73) and (1020.25,-119.30) .. (1015.21,-129.67)
 .. controls (1010.22,-139.93) and (1010.75,-139.46) .. (1004.95,-150.37)
 .. controls (999.16,-161.27) and (995.62,-164.84) .. (992.07,-172.31)
 .. controls (988.52,-179.77) and (988.67,-177.20) .. (987.78,-183.32)
 .. controls (986.89,-189.41) and (987.53,-191.76) .. (985.81,-194.72)
 .. controls (984.08,-197.67) and (982.60,-200.90) .. (979.82,-203.79)
 .. controls (977.03,-206.70) and (975.42,-211.97) .. (973.91,-215.20)
 .. controls (972.40,-218.44) and (970.61,-221.41) .. (970.61,-221.41)
),
1,((970.61,-221.41)
 .. controls (970.61,-221.41) and (967.32,-220.29) .. (966.38,-215.70)
 .. controls (965.44,-211.11) and (961.59,-209.36) .. (958.89,-203.75)
 .. controls (956.18,-198.13) and (946.10,-197.12) .. (939.45,-192.27)
 .. controls (933.61,-187.99) and (932.91,-186.36) .. (926.59,-186.70)
 .. controls (921.31,-186.98) and (920.39,-187.67) .. (916.03,-191.99)
 .. controls (911.65,-196.31) and (908.00,-201.33) .. (905.85,-204.23)
 .. controls (903.72,-207.11) and (891.99,-223.10) .. (888.63,-228.26)
 .. controls (885.38,-233.26) and (882.47,-238.23) .. (880.69,-241.66)
 .. controls (878.94,-245.01) and (867.83,-269.34) .. (868.26,-272.17)
 .. controls (868.69,-274.99) and (876.36,-278.15) .. (879.24,-278.62)
 .. controls (882.34,-279.12) and (882.29,-279.70) .. (892.39,-279.86)
 .. controls (904.82,-280.06) and (901.47,-281.26) .. (908.52,-280.51)
 .. controls (929.64,-278.28) and (926.79,-280.29) .. (931.11,-281.87)
 .. controls (935.43,-283.46) and (931.46,-282.97) .. (942.42,-285.49)
 .. controls (953.44,-288.03) and (956.90,-291.52) .. (964.11,-293.78)
 .. controls (971.27,-296.03) and (970.44,-294.31) .. (983.31,-294.56)
 .. controls (995.94,-294.80) and (993.06,-294.16) .. (1001.34,-295.24)
 .. controls (1009.62,-296.31) and (1016.46,-297.03) .. (1021.86,-298.83)
 .. controls (1027.25,-300.63) and (1029.06,-300.62) .. (1035.53,-302.06)
 .. controls (1042.01,-303.50) and (1061.79,-311.80) .. (1068.64,-312.15)
 .. controls (1075.49,-312.50) and (1081.59,-316.83) .. (1088.81,-315.00)
 .. controls (1096.02,-313.19) and (1089.53,-316.08) .. (1099.98,-313.18)
 .. controls (1110.42,-310.29) and (1102.50,-314.98) .. (1120.14,-313.17)
 .. controls (1137.78,-311.35) and (1148.58,-313.50) .. (1152.54,-314.22)
 .. controls (1156.50,-314.94) and (1166.22,-319.25) .. (1170.90,-319.61)
 .. controls (1175.58,-319.96) and (1179.04,-318.15) .. (1181.70,-320.68)
 .. controls (1188.90,-327.51) and (1189.98,-328.95) .. (1191.77,-333.28)
 .. controls (1193.57,-337.60) and (1194.29,-336.16) .. (1195.37,-340.84)
 .. controls (1196.44,-345.53) and (1193.56,-343.73) .. (1198.95,-349.14)
 .. controls (1204.34,-354.55) and (1203.98,-352.38) .. (1215.15,-353.81)
 .. controls (1226.31,-355.25) and (1231.35,-354.88) .. (1240.36,-353.79)
 .. controls (1249.36,-352.71) and (1257.29,-354.51) .. (1261.25,-354.87)
 .. controls (1265.21,-355.23) and (1286.45,-359.18) .. (1292.21,-359.54)
 .. controls (1297.97,-359.90) and (1328.19,-363.51) .. (1334.31,-362.43)
 .. controls (1340.42,-361.36) and (1347.59,-366.02) .. (1369.10,-364.35)
 .. controls (1390.51,-362.69) and (1402.58,-366.84) .. (1411.09,-365.90)
 .. controls (1419.58,-364.96) and (1423.82,-362.54) .. (1426.30,-360.44)
 .. controls (1428.78,-358.33) and (1435.81,-360.65) .. (1430.19,-355.85)
 .. controls (1424.57,-351.05) and (1420.68,-351.33) .. (1413.61,-349.76)
 .. controls (1406.53,-348.19) and (1402.98,-346.34) .. (1394.45,-343.36)
 .. controls (1385.91,-340.37) and (1381.27,-338.53) .. (1376.27,-335.26)
 .. controls (1371.26,-331.98) and (1379.84,-331.68) .. (1367.67,-328.01)
 .. controls (1355.49,-324.33) and (1346.88,-322.87) .. (1340.05,-319.26)
 .. controls (1333.22,-315.65) and (1332.14,-314.93) .. (1328.89,-309.54)
 .. controls (1325.64,-304.15) and (1323.45,-291.98) .. (1316.59,-286.61)
 .. controls (1309.73,-281.25) and (1308.31,-283.38) .. (1300.71,-275.54)
 .. controls (1293.12,-267.70) and (1299.58,-268.44) .. (1287.69,-263.08)
 .. controls (1275.80,-257.72) and (1270.76,-255.92) .. (1267.52,-253.43)
 .. controls (1264.27,-250.94) and (1258.49,-245.27) .. (1253.80,-242.07)
 .. controls (1249.12,-238.88) and (1245.88,-238.50) .. (1244.44,-237.09)
 .. controls (1242.99,-235.68) and (1241.91,-234.27) .. (1240.46,-232.51)
 .. controls (1232.59,-222.96) and (1235.05,-224.79) .. (1229.23,-212.99)
 .. controls (1223.46,-201.29) and (1222.00,-204.03) .. (1217.72,-184.02)
 .. controls (1213.54,-164.46) and (1212.62,-155.38) .. (1204.60,-147.41)
),
1,((1204.60,-147.41)
 .. controls (1196.67,-139.61) and (1197.36,-131.11) .. (1191.03,-130.85)
 .. controls (1184.71,-130.58) and (1183.02,-129.42) .. (1177.70,-130.34)
 .. controls (1172.39,-131.26) and (1173.89,-129.49) .. (1162.63,-130.76)
 .. controls (1151.38,-132.03) and (1134.48,-135.36) .. (1126.73,-133.93)
 .. controls (1119.13,-132.52) and (1110.86,-132.22) .. (1103.75,-134.08)
 .. controls (1096.71,-135.93) and (1098.68,-135.48) .. (1093.12,-136.87)
 .. controls (1087.64,-138.25) and (1069.79,-145.52) .. (1069.79,-145.52)
 .. controls (1069.79,-145.52) and (1068.01,-146.71) .. (1066.16,-147.88)
 .. controls (1061.19,-151.03) and (1057.59,-151.93) .. (1051.60,-158.30)
 .. controls (1047.37,-162.79) and (1049.01,-162.46) .. (1050.31,-161.81)
 .. controls (1053.00,-160.48) and (1051.62,-166.10) .. (1054.75,-160.26)
 .. controls (1057.81,-154.54) and (1057.63,-157.75) .. (1058.45,-152.57)
 .. controls (1060.00,-142.77) and (1059.11,-143.41) .. (1058.66,-137.57)
 .. controls (1058.29,-132.76) and (1057.06,-127.70) .. (1058.81,-124.90)
 .. controls (1060.65,-121.97) and (1069.71,-109.54) .. (1083.14,-100.50)
 .. controls (1087.28,-97.72) and (1118.58,-65.67) .. (1120.83,-62.01)
 .. controls (1122.99,-58.49) and (1118.88,-30.50) .. (1118.89,-29.15)
 .. controls (1118.89,-27.80) and (1107.57,-22.03) .. (1078.55,2.73)
 .. controls (1069.45,10.49) and (1025.75,19.09) .. (1020.61,19.93)
 .. controls (951.87,31.20) and (946.15,10.77) .. (936.86,16.88)
 .. controls (927.60,22.97) and (919.39,1.08) .. (884.84,8.99)
 .. controls (867.57,12.94) and (843.01,23.14) .. (838.81,26.27)
 .. controls (813.68,44.98) and (799.86,27.00) .. (787.62,32.75)
),
1,((787.62,32.75)
 .. controls (775.40,38.49) and (768.18,32.00) .. (727.17,41.39)
 .. controls (722.77,42.40) and (686.86,60.52) .. (684.33,59.44)
),
1,((684.33,59.44)
 .. controls (684.33,59.44) and (672.42,52.97) .. (663.06,52.25)
 .. controls (653.69,51.52) and (632.82,55.82) .. (623.46,57.97)
 .. controls (614.10,60.13) and (611.93,57.24) .. (594.66,65.88)
 .. controls (577.39,74.51) and (570.20,79.55) .. (560.88,87.48)
 .. controls (551.56,95.40) and (560.89,88.93) .. (536.51,104.05)
 .. controls (512.08,119.20) and (520.02,122.07) .. (501.25,122.80)
 .. controls (482.46,123.52) and (481.00,127.12) .. (460.79,127.12)
 .. controls (440.60,127.13) and (431.97,124.97) .. (419.02,119.21)
 .. controls (406.06,113.45) and (393.84,102.29) .. (393.84,102.29)
));
draw_upscrap(1)(0,((926.35,-286.41)
 -- (876.22,-243.29)
));
draw_upscrap(1)(0,((857.10,-38.53)
 -- (784.76,-37.81)
));
draw_upscrap(0)(1,((-805.74,148.00)
 .. controls (-812.94,147.28) and (-789.89,176.09) .. (-781.97,185.45)
 .. controls (-774.05,194.81) and (-768.29,199.85) .. (-751.72,211.36)
 .. controls (-735.15,222.88) and (-735.15,221.44) .. (-711.38,230.79)
 .. controls (-687.61,240.14) and (-665.28,240.13) .. (-645.12,235.08)
 .. controls (-624.96,230.03) and (-612.73,222.11) .. (-600.50,214.18)
 .. controls (-588.26,206.26) and (-594.74,209.14) .. (-590.43,200.50)
 .. controls (-586.11,191.85) and (-583.24,176.01) .. (-580.37,165.21)
 .. controls (-577.49,154.41) and (-589.74,136.41) .. (-598.38,131.37)
 .. controls (-607.02,126.33) and (-607.02,129.21) .. (-622.14,127.78)
 .. controls (-637.26,126.34) and (-642.29,131.38) .. (-671.81,133.55)
 .. controls (-701.33,135.72) and (-690.53,134.28) .. (-699.89,135.00)
 .. controls (-709.25,135.73) and (-746.69,147.27) .. (-765.42,147.28)
 .. controls (-784.14,147.29) and (-798.54,148.73) .. cycle
));
draw_downscrap;
endfig;
beginfig(6);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1018.35,-105.07)
 -- (1018.46,-117.73)
 .. controls (1018.46,-117.73) and (1020.25,-119.30) .. (1015.21,-129.67)
 .. controls (1010.22,-139.93) and (1010.75,-139.46) .. (1004.95,-150.37)
 .. controls (999.16,-161.27) and (995.62,-164.84) .. (992.07,-172.31)
 .. controls (988.52,-179.77) and (988.67,-177.20) .. (987.78,-183.32)
 .. controls (986.89,-189.41) and (987.53,-191.76) .. (985.81,-194.72)
 .. controls (984.08,-197.67) and (982.60,-200.90) .. (979.82,-203.79)
 .. controls (977.03,-206.70) and (975.42,-211.97) .. (973.91,-215.20)
 .. controls (972.40,-218.44) and (970.61,-221.41) .. (970.61,-221.41)
));
l_debug(0,1,((1072.85,-133.84)
 -- (1080.78,-138.00)
 .. controls (1080.78,-138.00) and (1082.79,-137.37) .. (1086.60,-147.13)
 .. controls (1090.42,-156.89) and (1090.43,-156.22) .. (1094.22,-166.98)
 .. controls (1098.01,-177.74) and (1098.26,-182.41) .. (1101.12,-189.48)
 .. controls (1103.98,-196.55) and (1102.35,-194.85) .. (1105.93,-199.26)
 .. controls (1109.52,-203.67) and (1111.50,-204.71) .. (1112.44,-207.73)
 .. controls (1113.38,-210.76) and (1114.66,-213.79) .. (1114.92,-217.46)
 .. controls (1115.18,-221.14) and (1117.76,-225.53) .. (1119.04,-228.56)
 .. controls (1120.31,-231.59) and (1121.26,-234.61) .. (1121.26,-234.61)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((889.50,-36.00)
 .. controls (889.50,-36.00) and (898.14,-34.92) .. (905.34,-35.64)
 .. controls (912.54,-36.35) and (922.62,-37.79) .. (925.13,-36.71)
 .. controls (927.65,-35.63) and (931.96,-31.67) .. (934.84,-31.67)
 .. controls (937.72,-31.67) and (938.08,-31.67) .. (943.12,-30.95)
 .. controls (948.16,-30.23) and (956.44,-34.56) .. (961.84,-33.84)
 .. controls (967.24,-33.12) and (985.26,-39.25) .. (991.74,-40.34)
 .. controls (998.22,-41.42) and (1002.55,-42.85) .. (1006.14,-42.49)
 .. controls (1009.74,-42.13) and (1011.18,-42.13) .. (1015.14,-44.28)
 .. controls (1019.10,-46.44) and (1019.10,-46.44) .. (1025.22,-48.60)
 .. controls (1031.34,-50.75) and (1044.67,-56.50) .. (1046.84,-57.94)
 .. controls (1049.01,-59.38) and (1052.99,-62.26) .. (1058.75,-64.41)
));
l_debug(0,1,((801.55,-44.33)
 .. controls (801.55,-44.33) and (809.58,-43.49) .. (816.24,-44.29)
 .. controls (822.90,-45.09) and (832.22,-46.61) .. (834.58,-45.65)
 .. controls (836.93,-44.70) and (841.01,-41.11) .. (843.68,-41.16)
 .. controls (846.35,-41.21) and (846.68,-41.22) .. (851.37,-40.64)
 .. controls (856.05,-40.07) and (863.65,-44.23) .. (868.67,-43.66)
 .. controls (873.68,-43.09) and (890.26,-49.09) .. (896.24,-50.21)
 .. controls (902.23,-51.33) and (906.21,-52.75) .. (909.55,-52.48)
 .. controls (912.89,-52.21) and (914.23,-52.24) .. (917.86,-54.31)
 .. controls (921.49,-56.39) and (921.49,-56.39) .. (927.12,-58.50)
 .. controls (932.76,-60.62) and (945.00,-66.20) .. (946.97,-67.58)
 .. controls (948.95,-68.95) and (952.57,-71.70) .. (957.87,-73.80)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1438.64,366.84)
 .. controls (-1437.92,364.68) and (-1436.48,360.72) .. (-1435.40,359.64)
 .. controls (-1434.32,358.56) and (-1429.28,356.76) .. (-1425.32,354.24)
 .. controls (-1421.36,351.72) and (-1417.04,348.48) .. (-1413.80,345.24)
 .. controls (-1410.56,342.00) and (-1410.56,342.36) .. (-1408.40,339.48)
 .. controls (-1406.24,336.60) and (-1406.60,335.16) .. (-1402.64,334.44)
 .. controls (-1398.68,333.72) and (-1399.04,335.16) .. (-1392.56,331.20)
 .. controls (-1386.08,327.24) and (-1386.80,326.52) .. (-1383.56,326.16)
 .. controls (-1380.32,325.80) and (-1377.44,326.52) .. (-1374.56,326.52)
 .. controls (-1371.68,326.52) and (-1371.99,328.18) .. (-1369.16,325.80)
 .. controls (-1362.32,320.04) and (-1358.72,319.32) .. (-1354.76,320.04)
 .. controls (-1350.80,320.76) and (-1352.96,321.12) .. (-1345.76,321.12)
 .. controls (-1338.56,321.11) and (-1338.56,322.55) .. (-1335.68,321.11)
 .. controls (-1332.80,319.67) and (-1331.72,316.79) .. (-1324.88,314.27)
 .. controls (-1318.04,311.75) and (-1305.44,307.79) .. (-1301.48,306.35)
 .. controls (-1297.52,304.91) and (-1294.28,303.47) .. (-1291.04,300.23)
 .. controls (-1287.80,296.99) and (-1292.84,299.15) .. (-1285.28,295.55)
 .. controls (-1277.72,291.95) and (-1276.28,291.23) .. (-1271.96,290.15)
 .. controls (-1267.64,289.07) and (-1267.64,286.55) .. (-1261.16,287.27)
 .. controls (-1254.68,287.99) and (-1254.32,286.91) .. (-1248.92,288.71)
 .. controls (-1243.52,290.51) and (-1243.88,292.31) .. (-1239.92,291.23)
 .. controls (-1235.96,290.15) and (-1229.48,289.07) .. (-1223.72,288.71)
 .. controls (-1217.96,288.35) and (-1217.24,288.35) .. (-1215.80,287.99)
 .. controls (-1214.36,287.63) and (-1212.21,280.06) .. (-1210.05,278.26)
 .. controls (-1207.89,276.45) and (-1203.22,272.48) .. (-1199.98,272.48)
 .. controls (-1196.73,272.48) and (-1200.69,273.92) .. (-1194.21,271.75)
 .. controls (-1187.73,269.58) and (-1190.25,269.94) .. (-1184.49,268.14)
 .. controls (-1178.73,266.33) and (-1176.21,263.43) .. (-1170.80,263.79)
 .. controls (-1165.40,264.15) and (-1161.17,264.03) .. (-1158.91,262.35)
 .. controls (-1153.14,258.05) and (-1151.70,257.34) .. (-1148.46,256.99)
 .. controls (-1145.22,256.65) and (-1147.02,256.64) .. (-1143.06,256.66)
 .. controls (-1139.11,256.67) and (-1132.64,256.67) .. (-1132.64,256.67)
 .. controls (-1132.64,256.67) and (-1130.84,259.19) .. (-1130.84,254.87)
 .. controls (-1130.84,250.56) and (-1131.55,251.64) .. (-1130.47,248.40)
 .. controls (-1129.39,245.16) and (-1127.95,245.88) .. (-1127.59,239.04)
 .. controls (-1127.22,232.20) and (-1128.30,232.56) .. (-1127.94,229.32)
 .. controls (-1127.57,226.08) and (-1125.77,223.56) .. (-1125.77,216.36)
 .. controls (-1125.76,209.16) and (-1125.40,203.40) .. (-1126.83,198.72)
 .. controls (-1128.27,194.03) and (-1131.15,202.67) .. (-1128.63,190.79)
 .. controls (-1126.10,178.92) and (-1127.89,164.15) .. (-1127.17,160.92)
 .. controls (-1126.45,157.68) and (-1126.08,155.88) .. (-1126.08,151.56)
 .. controls (-1126.08,147.24) and (-1125.72,141.48) .. (-1126.07,138.96)
 .. controls (-1126.43,136.44) and (-1127.87,134.64) .. (-1125.71,132.84)
 .. controls (-1123.55,131.04) and (-1124.63,127.08) .. (-1117.43,129.61)
 .. controls (-1110.24,132.13) and (-1110.96,132.85) .. (-1103.77,134.30)
 .. controls (-1096.58,135.74) and (-1102.33,137.18) .. (-1090.46,136.10)
 .. controls (-1078.60,135.02) and (-1083.27,135.38) .. (-1074.64,134.30)
 .. controls (-1066.00,133.22) and (-1069.24,132.86) .. (-1056.29,132.86)
 .. controls (-1043.34,132.86) and (-1041.54,132.50) .. (-1031.82,132.50)
 .. controls (-1022.10,132.50) and (-1011.66,125.66) .. (-999.79,129.98)
 .. controls (-987.91,134.30) and (-983.95,139.34) .. (-974.95,139.34)
 .. controls (-965.95,139.35) and (-963.79,138.27) .. (-961.99,138.27)
 .. controls (-960.19,138.27) and (-961.27,136.11) .. (-952.99,135.39)
 .. controls (-944.71,134.67) and (-940.75,131.79) .. (-930.67,128.55)
 .. controls (-920.59,125.31) and (-920.23,126.39) .. (-913.75,122.79)
 .. controls (-907.27,119.20) and (-906.19,118.12) .. (-903.31,115.60)
 .. controls (-900.43,113.08) and (-900.43,111.64) .. (-894.67,109.48)
 .. controls (-888.91,107.32) and (-890.35,104.08) .. (-882.79,105.52)
 .. controls (-875.23,106.96) and (-879.55,109.84) .. (-869.47,108.04)
 .. controls (-859.39,106.24) and (-848.23,104.44) .. (-836.71,106.60)
 .. controls (-825.19,108.76) and (-832.03,111.64) .. (-817.63,109.84)
 .. controls (-803.23,108.04) and (-803.61,109.74) .. (-797.11,108.40)
));
l_debug(0,1,((-1349.06,371.92)
 .. controls (-1348.43,369.90) and (-1347.17,366.21) .. (-1346.18,365.19)
 .. controls (-1345.20,364.16) and (-1340.56,362.40) .. (-1336.94,359.99)
 .. controls (-1333.32,357.59) and (-1329.37,354.50) .. (-1326.43,351.44)
 .. controls (-1323.48,348.38) and (-1323.48,348.71) .. (-1321.53,346.00)
 .. controls (-1319.58,343.29) and (-1319.94,341.96) .. (-1316.28,341.22)
 .. controls (-1312.62,340.48) and (-1312.93,341.83) .. (-1307.00,338.04)
 .. controls (-1301.06,334.25) and (-1301.74,333.59) .. (-1298.75,333.20)
 .. controls (-1295.75,332.80) and (-1293.07,333.42) .. (-1290.40,333.37)
 .. controls (-1287.73,333.31) and (-1287.99,334.86) .. (-1285.41,332.60)
 .. controls (-1279.17,327.13) and (-1275.85,326.40) .. (-1272.16,327.00)
 .. controls (-1268.48,327.59) and (-1270.48,327.96) .. (-1263.80,327.83)
 .. controls (-1257.13,327.70) and (-1257.10,329.03) .. (-1254.46,327.65)
 .. controls (-1251.82,326.26) and (-1250.87,323.57) .. (-1244.57,321.11)
 .. controls (-1238.28,318.64) and (-1226.67,314.74) .. (-1223.03,313.33)
 .. controls (-1219.39,311.93) and (-1216.41,310.53) .. (-1213.46,307.47)
 .. controls (-1210.52,304.41) and (-1215.15,306.50) .. (-1208.21,303.03)
 .. controls (-1201.27,299.55) and (-1199.95,298.86) .. (-1195.96,297.77)
 .. controls (-1191.98,296.69) and (-1192.03,294.36) .. (-1186.01,294.91)
 .. controls (-1179.99,295.45) and (-1179.67,294.45) .. (-1174.63,296.02)
 .. controls (-1169.60,297.58) and (-1169.90,299.26) .. (-1166.25,298.19)
 .. controls (-1162.59,297.11) and (-1156.61,295.99) .. (-1151.28,295.55)
 .. controls (-1145.94,295.11) and (-1145.28,295.10) .. (-1143.95,294.74)
 .. controls (-1142.62,294.38) and (-1140.76,287.33) .. (-1138.79,285.62)
 .. controls (-1136.82,283.91) and (-1132.55,280.16) .. (-1129.55,280.10)
 .. controls (-1126.55,280.04) and (-1130.19,281.45) .. (-1124.22,279.33)
 .. controls (-1118.26,277.20) and (-1120.59,277.58) .. (-1115.28,275.81)
 .. controls (-1109.97,274.03) and (-1107.69,271.32) .. (-1102.68,271.55)
 .. controls (-1097.67,271.79) and (-1093.75,271.60) .. (-1091.69,270.00)
 .. controls (-1086.43,265.89) and (-1085.11,265.20) .. (-1082.12,264.80)
 .. controls (-1079.12,264.41) and (-1080.79,264.44) .. (-1077.12,264.37)
 .. controls (-1073.45,264.30) and (-1067.44,264.18) .. (-1067.44,264.18)
 .. controls (-1067.44,264.18) and (-1065.72,266.48) .. (-1065.80,262.48)
 .. controls (-1065.88,258.47) and (-1066.53,259.49) .. (-1065.59,256.46)
 .. controls (-1064.65,253.44) and (-1063.30,254.08) .. (-1063.09,247.73)
 .. controls (-1062.88,241.39) and (-1063.88,241.74) .. (-1063.60,238.73)
 .. controls (-1063.33,235.72) and (-1061.71,233.35) .. (-1061.84,226.68)
 .. controls (-1061.97,220.00) and (-1061.75,214.66) .. (-1063.17,210.35)
 .. controls (-1064.59,206.03) and (-1067.10,214.10) .. (-1064.98,203.04)
 .. controls (-1062.86,191.98) and (-1064.80,178.33) .. (-1064.20,175.31)
 .. controls (-1063.59,172.30) and (-1063.29,170.62) .. (-1063.37,166.62)
 .. controls (-1063.45,162.61) and (-1063.22,157.27) .. (-1063.60,154.94)
 .. controls (-1063.98,152.61) and (-1065.35,150.97) .. (-1063.38,149.26)
 .. controls (-1061.41,147.55) and (-1062.48,143.90) .. (-1055.76,146.10)
 .. controls (-1049.04,148.31) and (-1049.70,148.99) .. (-1043.00,150.19)
 .. controls (-1036.30,151.39) and (-1041.61,152.83) .. (-1030.62,151.61)
 .. controls (-1019.62,150.39) and (-1023.96,150.81) .. (-1015.97,149.65)
 .. controls (-1007.98,148.49) and (-1010.99,148.22) .. (-998.97,147.98)
 .. controls (-986.96,147.74) and (-985.30,147.38) .. (-976.29,147.20)
 .. controls (-967.28,147.02) and (-957.73,140.49) .. (-946.64,144.27)
 .. controls (-935.55,148.06) and (-931.78,152.66) .. (-923.44,152.49)
 .. controls (-915.10,152.32) and (-913.11,151.28) .. (-911.45,151.25)
 .. controls (-909.78,151.22) and (-910.82,149.24) .. (-903.16,148.42)
 .. controls (-895.50,147.60) and (-891.88,144.85) .. (-882.59,141.66)
 .. controls (-873.31,138.48) and (-872.96,139.47) .. (-867.02,136.01)
 .. controls (-861.08,132.56) and (-860.09,131.54) .. (-857.47,129.15)
 .. controls (-854.85,126.76) and (-854.87,125.42) .. (-849.58,123.32)
 .. controls (-844.28,121.21) and (-845.67,118.23) .. (-838.64,119.43)
 .. controls (-831.60,120.62) and (-835.55,123.37) .. (-826.24,121.52)
 .. controls (-816.93,119.66) and (-806.62,117.79) .. (-795.90,119.58)
 .. controls (-785.18,121.37) and (-791.47,124.17) .. (-778.16,122.23)
 .. controls (-764.84,120.30) and (-765.16,121.88) .. (-759.16,120.52)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-797.11,108.40)
 .. controls (-797.11,108.40) and (-793.87,108.76) .. (-790.99,108.04)
 .. controls (-788.11,107.32) and (-789.91,108.76) .. (-785.23,106.96)
 .. controls (-780.55,105.16) and (-778.75,104.80) .. (-773.35,100.48)
 .. controls (-767.95,96.15) and (-768.67,96.87) .. (-765.79,93.99)
 .. controls (-762.91,91.11) and (-767.23,91.83) .. (-759.68,88.95)
 .. controls (-752.12,86.06) and (-755.00,88.95) .. (-749.60,85.34)
 .. controls (-744.20,81.74) and (-734.48,80.65) .. (-726.92,80.29)
 .. controls (-719.35,79.93) and (-718.27,79.20) .. (-713.23,79.56)
 .. controls (-708.19,79.92) and (-710.35,78.12) .. (-699.55,78.48)
 .. controls (-688.75,78.83) and (-689.47,77.75) .. (-678.31,77.75)
 .. controls (-667.15,77.75) and (-666.79,78.11) .. (-655.27,77.38)
 .. controls (-643.75,76.66) and (-646.63,78.10) .. (-640.51,76.66)
 .. controls (-634.39,75.22) and (-629.71,75.94) .. (-624.31,71.98)
 .. controls (-618.91,68.01) and (-622.15,69.45) .. (-615.31,66.21)
 .. controls (-608.47,62.97) and (-607.75,61.17) .. (-600.91,60.09)
 .. controls (-594.07,59.01) and (-594.79,58.29) .. (-588.31,59.72)
 .. controls (-581.83,61.16) and (-581.83,62.24) .. (-575.35,63.32)
 .. controls (-568.87,64.40) and (-568.51,66.20) .. (-561.31,65.12)
 .. controls (-554.10,64.04) and (-548.70,61.16) .. (-540.06,60.44)
 .. controls (-531.42,59.72) and (-533.22,59.72) .. (-524.22,59.00)
 .. controls (-515.22,58.28) and (-511.26,57.92) .. (-501.54,56.84)
 .. controls (-491.82,55.76) and (-496.86,54.32) .. (-483.90,54.32)
 .. controls (-470.94,54.32) and (-471.30,53.24) .. (-466.26,54.32)
 .. controls (-461.22,55.40) and (-457.62,50.37) .. (-451.14,50.37)
 .. controls (-444.66,50.37) and (-432.78,48.94) .. (-426.30,47.50)
 .. controls (-419.82,46.06) and (-420.54,48.58) .. (-410.10,44.99)
 .. controls (-399.66,41.39) and (-400.02,41.75) .. (-396.06,38.15)
 .. controls (-392.10,34.55) and (-393.54,35.27) .. (-389.94,31.67)
 .. controls (-386.34,28.07) and (-385.98,25.56) .. (-380.94,26.28)
 .. controls (-375.90,27.00) and (-375.54,26.64) .. (-370.14,27.71)
 .. controls (-364.74,28.79) and (-363.30,28.43) .. (-354.30,27.35)
 .. controls (-345.30,26.27) and (-341.70,26.27) .. (-337.74,25.19)
 .. controls (-333.78,24.11) and (-335.58,25.91) .. (-326.22,21.59)
 .. controls (-316.86,17.27) and (-321.18,15.11) .. (-310.38,14.74)
 .. controls (-299.58,14.38) and (-303.54,17.62) .. (-293.46,14.02)
 .. controls (-283.38,10.42) and (-285.90,9.34) .. (-275.10,7.90)
 .. controls (-264.29,6.46) and (-275.09,3.58) .. (-258.89,5.74)
 .. controls (-242.69,7.90) and (-233.67,7.76) .. (-229.01,8.26)
 .. controls (-215.69,9.70) and (-216.05,9.70) .. (-204.89,10.06)
 .. controls (-193.73,10.42) and (-191.57,8.26) .. (-179.33,10.78)
 .. controls (-167.09,13.31) and (-177.89,11.86) .. (-164.57,14.03)
));
l_debug(0,1,((-759.16,120.52)
 .. controls (-759.16,120.52) and (-756.15,120.79) .. (-753.50,120.07)
 .. controls (-750.84,119.35) and (-752.48,120.72) .. (-748.18,118.97)
 .. controls (-743.87,117.21) and (-742.21,116.85) .. (-737.28,112.74)
 .. controls (-732.36,108.64) and (-733.01,109.32) .. (-730.40,106.60)
 .. controls (-727.78,103.87) and (-731.77,104.62) .. (-724.82,101.81)
 .. controls (-717.86,99.00) and (-720.48,101.73) .. (-715.54,98.29)
 .. controls (-710.60,94.85) and (-701.61,93.67) .. (-694.61,93.20)
 .. controls (-687.61,92.73) and (-686.62,92.04) .. (-681.94,92.28)
 .. controls (-677.26,92.52) and (-679.30,90.89) .. (-669.28,91.03)
 .. controls (-659.26,91.16) and (-659.95,90.17) .. (-649.61,89.97)
 .. controls (-639.26,89.76) and (-638.92,90.09) .. (-628.26,89.21)
 .. controls (-617.59,88.33) and (-620.23,89.72) .. (-614.59,88.27)
 .. controls (-608.94,86.83) and (-604.59,87.41) .. (-599.66,83.64)
 .. controls (-594.72,79.87) and (-597.70,81.26) .. (-591.42,78.13)
 .. controls (-585.14,75.00) and (-584.51,73.32) .. (-578.19,72.19)
 .. controls (-571.87,71.07) and (-572.55,70.41) .. (-566.51,71.63)
 .. controls (-560.48,72.84) and (-560.46,73.85) .. (-554.43,74.73)
 .. controls (-548.41,75.61) and (-548.04,77.27) .. (-541.39,76.14)
 .. controls (-534.73,75.00) and (-529.78,72.23) .. (-521.78,71.41)
 .. controls (-513.79,70.58) and (-515.46,70.62) .. (-507.13,69.78)
 .. controls (-498.80,68.95) and (-495.13,68.54) .. (-486.14,67.36)
 .. controls (-477.15,66.18) and (-481.85,64.94) .. (-469.84,64.70)
 .. controls (-457.83,64.46) and (-458.18,63.47) .. (-453.49,64.38)
 .. controls (-448.80,65.29) and (-445.55,60.55) .. (-439.55,60.43)
 .. controls (-433.54,60.31) and (-422.55,58.76) .. (-416.57,57.30)
 .. controls (-410.59,55.85) and (-411.22,58.20) .. (-401.60,54.67)
 .. controls (-391.99,51.14) and (-392.32,51.48) .. (-388.72,48.07)
 .. controls (-385.11,44.66) and (-386.43,45.35) .. (-383.16,41.95)
 .. controls (-379.89,38.55) and (-379.60,36.20) .. (-374.92,36.78)
 .. controls (-370.23,37.35) and (-369.91,37.01) .. (-364.88,37.92)
 .. controls (-359.86,38.82) and (-358.53,38.46) .. (-350.21,37.29)
 .. controls (-341.88,36.12) and (-338.55,36.06) .. (-334.90,34.98)
 .. controls (-331.24,33.91) and (-332.88,35.61) .. (-324.28,31.43)
 .. controls (-315.69,27.26) and (-319.73,25.33) .. (-309.73,24.80)
 .. controls (-299.72,24.27) and (-303.33,27.35) .. (-294.06,23.82)
 .. controls (-284.78,20.30) and (-287.13,19.35) .. (-277.15,17.81)
 .. controls (-267.17,16.28) and (-277.23,13.81) .. (-262.17,15.51)
 .. controls (-247.12,17.22) and (-238.75,16.92) .. (-234.43,17.30)
 .. controls (-222.06,18.39) and (-222.39,18.40) .. (-212.04,18.52)
 .. controls (-201.69,18.65) and (-199.73,16.61) .. (-188.33,18.72)
 .. controls (-176.94,20.83) and (-186.98,19.70) .. (-174.59,21.45)
));
ATTR__id := "l6-14036-804";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-164.57,14.03)
 .. controls (-164.57,14.03) and (-156.29,14.03) .. (-154.86,14.75)
 .. controls (-153.42,15.47) and (-139.38,14.75) .. (-127.14,16.19)
 .. controls (-114.90,17.63) and (-129.30,20.51) .. (-110.22,17.99)
 .. controls (-91.14,15.47) and (-94.38,14.75) .. (-80.34,13.67)
 .. controls (-66.30,12.59) and (-65.94,10.79) .. (-59.10,11.51)
 .. controls (-52.26,12.23) and (-59.10,14.39) .. (-45.78,12.23)
 .. controls (-32.46,10.07) and (-29.94,8.99) .. (-23.82,8.99)
 .. controls (-17.70,8.99) and (-6.18,6.11) .. (-1.50,7.55)
 .. controls (3.18,8.99) and (18.52,6.03) .. (28.02,6.84)
 .. controls (49.26,8.63) and (47.46,10.79) .. (58.98,8.63)
 .. controls (70.50,6.47) and (70.14,8.26) .. (81.29,4.30)
 .. controls (92.45,0.34) and (86.69,1.06) .. (100.01,-2.90)
 .. controls (113.33,-6.87) and (110.81,-7.23) .. (121.97,-6.51)
 .. controls (133.13,-5.79) and (127.37,-5.79) .. (138.89,-5.07)
 .. controls (150.41,-4.36) and (144.65,-6.87) .. (161.93,-6.16)
 .. controls (179.21,-5.45) and (174.89,-6.52) .. (183.53,-4.37)
 .. controls (192.17,-2.21) and (204.78,-1.86) .. (206.58,-1.50)
 .. controls (208.38,-1.14) and (223.50,-0.06) .. (230.70,-2.22)
 .. controls (237.91,-4.37) and (233.94,-2.22) .. (245.47,-6.17)
 .. controls (256.99,-10.12) and (259.87,-11.20) .. (267.80,-14.07)
 .. controls (275.72,-16.94) and (282.20,-20.90) .. (287.96,-21.61)
 .. controls (293.72,-22.33) and (296.96,-25.20) .. (304.16,-24.84)
 .. controls (311.36,-24.47) and (307.04,-24.11) .. (317.48,-23.03)
 .. controls (327.91,-21.94) and (323.59,-20.86) .. (335.83,-23.37)
 .. controls (348.07,-25.88) and (343.39,-23.72) .. (356.34,-28.03)
 .. controls (369.30,-32.34) and (369.66,-31.26) .. (380.45,-35.95)
 .. controls (391.25,-40.63) and (396.29,-44.60) .. (402.40,-44.24)
 .. controls (408.52,-43.89) and (395.93,-43.52) .. (412.84,-42.81)
 .. controls (429.76,-42.11) and (426.88,-40.67) .. (438.40,-43.56)
 .. controls (449.92,-46.45) and (454.97,-50.05) .. (463.97,-49.33)
 .. controls (472.97,-48.60) and (471.89,-48.60) .. (475.85,-48.24)
 .. controls (479.81,-47.87) and (480.53,-54.36) .. (482.70,-54.35)
 .. controls (484.86,-54.35) and (488.10,-56.87) .. (496.02,-59.02)
 .. controls (503.94,-61.17) and (505.02,-57.21) .. (509.34,-64.77)
 .. controls (513.67,-72.32) and (513.31,-69.80) .. (516.91,-74.84)
 .. controls (520.51,-79.87) and (520.87,-84.19) .. (526.27,-85.98)
 .. controls (531.66,-87.77) and (530.94,-88.85) .. (544.97,-91.00)
 .. controls (559.00,-93.16) and (558.64,-92.80) .. (564.03,-94.96)
 .. controls (569.43,-97.13) and (573.75,-93.89) .. (577.35,-100.73)
 .. controls (580.95,-107.58) and (582.03,-111.18) .. (585.62,-117.67)
 .. controls (589.22,-124.15) and (589.58,-126.68) .. (591.38,-129.20)
 .. controls (593.18,-131.73) and (595.34,-137.86) .. (603.99,-141.11)
 .. controls (612.63,-144.37) and (612.27,-140.77) .. (615.87,-145.81)
 .. controls (619.47,-150.85) and (619.47,-150.85) .. (622.00,-154.81)
 .. controls (624.52,-158.77) and (618.03,-154.81) .. (626.32,-166.33)
 .. controls (634.61,-177.84) and (631.73,-179.64) .. (640.37,-180.36)
 .. controls (649.01,-181.08) and (654.41,-179.28) .. (660.53,-178.92)
 .. controls (666.65,-178.56) and (659.45,-174.96) .. (670.25,-179.28)
 .. controls (681.05,-183.60) and (681.41,-182.88) .. (684.64,-186.85)
 .. controls (687.88,-190.81) and (682.48,-190.09) .. (691.84,-195.14)
 .. controls (701.21,-200.19) and (704.09,-200.91) .. (705.53,-201.99)
 .. controls (706.97,-203.08) and (712.01,-208.47) .. (711.29,-213.51)
 .. controls (710.57,-218.55) and (708.41,-214.95) .. (708.41,-226.83)
 .. controls (708.42,-238.71) and (707.70,-240.14) .. (710.94,-244.82)
 .. controls (714.18,-249.50) and (715.12,-251.41) .. (717.78,-254.53)
 .. controls (723.90,-261.73) and (724.62,-262.09) .. (724.63,-265.33)
 .. controls (724.63,-268.56) and (723.55,-267.48) .. (725.71,-271.80)
 .. controls (727.87,-276.12) and (729.31,-277.56) .. (732.55,-281.15)
 .. controls (735.79,-284.74) and (738.68,-290.85) .. (745.51,-289.41)
 .. controls (752.35,-287.98) and (756.31,-287.61) .. (760.27,-288.32)
 .. controls (764.23,-289.03) and (760.64,-291.55) .. (769.63,-287.22)
 .. controls (778.64,-282.89) and (779.00,-286.11) .. (783.32,-280.71)
 .. controls (787.64,-275.30) and (790.16,-274.20) .. (791.24,-268.45)
 .. controls (792.32,-262.70) and (790.88,-256.24) .. (790.16,-253.37)
));
l_debug(0,1,((-174.59,21.45)
 .. controls (-174.59,21.45) and (-166.92,21.30) .. (-165.57,21.94)
 .. controls (-164.22,22.58) and (-151.22,21.66) .. (-139.85,22.77)
 .. controls (-128.48,23.88) and (-141.77,26.81) .. (-124.13,24.12)
 .. controls (-106.49,21.44) and (-109.51,20.83) .. (-96.51,19.57)
 .. controls (-83.52,18.31) and (-83.22,16.63) .. (-76.87,17.18)
 .. controls (-70.51,17.72) and (-76.81,19.84) .. (-64.51,17.60)
 .. controls (-52.20,15.35) and (-49.88,14.30) .. (-44.21,14.19)
 .. controls (-38.54,14.08) and (-27.91,11.20) .. (-23.55,12.44)
 .. controls (-19.18,13.69) and (-5.01,10.66) .. (3.80,11.23)
 .. controls (23.52,12.51) and (21.90,14.55) .. (32.53,12.33)
 .. controls (43.17,10.12) and (42.87,11.79) .. (53.14,7.92)
 .. controls (63.42,4.04) and (58.09,4.82) .. (70.36,0.90)
 .. controls (82.64,-3.02) and (80.30,-3.30) .. (90.65,-2.84)
 .. controls (101.01,-2.38) and (95.67,-2.27) .. (106.36,-1.82)
 .. controls (117.05,-1.36) and (111.67,-3.59) .. (127.70,-3.24)
 .. controls (143.73,-2.89) and (139.71,-3.82) .. (147.76,-1.97)
 .. controls (155.80,-0.13) and (167.49,-0.03) .. (169.16,0.27)
 .. controls (170.84,0.57) and (184.87,1.30) .. (191.51,-0.84)
 .. controls (198.14,-2.97) and (194.51,-0.90) .. (205.12,-4.78)
 .. controls (215.72,-8.66) and (218.37,-9.72) .. (225.66,-12.53)
 .. controls (232.95,-15.35) and (238.88,-19.14) .. (244.21,-19.91)
 .. controls (249.54,-20.68) and (252.49,-23.41) .. (259.17,-23.21)
 .. controls (265.85,-23.01) and (261.85,-22.60) .. (271.55,-21.79)
 .. controls (281.24,-20.98) and (277.26,-19.90) .. (288.56,-22.46)
 .. controls (299.86,-25.02) and (295.56,-22.93) .. (307.49,-27.18)
 .. controls (319.43,-31.42) and (319.78,-30.42) .. (329.70,-34.96)
 .. controls (339.63,-39.50) and (344.23,-43.26) .. (349.91,-43.04)
 .. controls (355.59,-42.82) and (343.91,-42.25) .. (359.61,-41.90)
 .. controls (375.31,-41.54) and (372.67,-40.15) .. (383.29,-43.04)
 .. controls (393.92,-45.92) and (398.52,-49.35) .. (406.88,-48.84)
 .. controls (415.23,-48.34) and (414.23,-48.32) .. (417.91,-48.06)
 .. controls (421.59,-47.80) and (422.13,-53.82) .. (424.14,-53.86)
 .. controls (426.14,-53.90) and (429.10,-56.30) .. (436.40,-58.44)
 .. controls (443.70,-60.59) and (444.77,-56.94) .. (448.64,-64.03)
 .. controls (452.50,-71.12) and (452.22,-68.77) .. (455.46,-73.51)
 .. controls (458.70,-78.25) and (458.96,-82.26) .. (463.93,-84.03)
 .. controls (468.90,-85.80) and (468.22,-86.78) .. (481.19,-89.04)
 .. controls (494.17,-91.30) and (493.84,-90.96) .. (498.80,-93.07)
 .. controls (503.77,-95.17) and (507.83,-92.24) .. (511.04,-98.65)
 .. controls (514.26,-105.06) and (515.19,-108.41) .. (518.41,-114.49)
 .. controls (521.63,-120.56) and (521.91,-122.90) .. (523.54,-125.27)
 .. controls (525.16,-127.64) and (527.05,-133.35) .. (535.00,-136.51)
 .. controls (542.95,-139.68) and (542.68,-136.33) .. (545.92,-141.07)
 .. controls (549.17,-145.81) and (549.17,-145.81) .. (551.43,-149.53)
 .. controls (553.69,-153.24) and (547.76,-149.45) .. (555.22,-160.28)
 .. controls (562.68,-171.11) and (559.98,-172.73) .. (567.98,-173.56)
 .. controls (575.97,-174.38) and (581.01,-172.81) .. (586.69,-172.59)
 .. controls (592.37,-172.37) and (585.76,-168.90) .. (595.69,-173.11)
 .. controls (605.63,-177.31) and (605.97,-176.65) .. (608.90,-180.38)
 .. controls (611.83,-184.11) and (606.84,-183.34) .. (615.42,-188.19)
 .. controls (624.01,-193.03) and (626.66,-193.75) .. (627.98,-194.78)
 .. controls (629.29,-195.80) and (633.87,-200.90) .. (633.11,-205.56)
 .. controls (632.35,-210.22) and (630.41,-206.84) .. (630.19,-217.86)
 .. controls (629.97,-228.87) and (629.28,-230.19) .. (632.20,-234.59)
 .. controls (635.11,-238.98) and (635.95,-240.77) .. (638.36,-243.72)
 .. controls (643.90,-250.51) and (644.56,-250.86) .. (644.50,-253.86)
 .. controls (644.44,-256.86) and (643.46,-255.84) .. (645.38,-259.89)
 .. controls (647.30,-263.93) and (648.61,-265.29) .. (651.55,-268.69)
 .. controls (654.49,-272.08) and (657.04,-277.81) .. (663.41,-276.60)
 .. controls (669.78,-275.39) and (673.45,-275.13) .. (677.11,-275.87)
 .. controls (680.77,-276.61) and (677.39,-278.88) .. (685.81,-275.04)
 .. controls (694.23,-271.20) and (694.50,-274.21) .. (698.61,-269.29)
 .. controls (702.71,-264.36) and (705.07,-263.41) .. (706.17,-258.09)
 .. controls (707.28,-252.77) and (706.07,-246.74) .. (705.45,-244.05)
));
ATTR__id := "l7-14382-2156";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((790.16,-253.37)
 .. controls (790.16,-253.37) and (790.88,-251.92) .. (789.07,-249.41)
 .. controls (787.27,-246.91) and (789.08,-243.65) .. (782.95,-240.08)
 .. controls (776.81,-236.51) and (776.10,-237.23) .. (769.61,-232.20)
 .. controls (763.13,-227.17) and (762.05,-224.65) .. (757.37,-221.05)
 .. controls (752.69,-217.46) and (753.05,-215.66) .. (746.21,-210.98)
 .. controls (739.37,-206.31) and (735.41,-203.07) .. (731.45,-199.83)
 .. controls (727.49,-196.60) and (725.33,-193.72) .. (718.50,-186.51)
 .. controls (711.66,-179.31) and (711.66,-183.27) .. (707.34,-174.26)
 .. controls (703.02,-165.24) and (701.58,-163.80) .. (699.42,-155.52)
 .. controls (697.26,-147.24) and (701.95,-146.51) .. (697.63,-138.59)
 .. controls (693.32,-130.68) and (695.49,-126.35) .. (685.75,-122.77)
 .. controls (676.02,-119.18) and (669.18,-117.74) .. (660.18,-111.26)
 .. controls (651.18,-104.78) and (657.30,-106.22) .. (646.50,-102.25)
 .. controls (635.70,-98.28) and (634.99,-98.63) .. (627.42,-95.02)
 .. controls (619.86,-91.40) and (613.02,-93.92) .. (610.86,-84.55)
 .. controls (608.70,-75.18) and (609.42,-73.02) .. (608.70,-68.34)
 .. controls (607.98,-63.65) and (608.35,-58.97) .. (605.82,-56.09)
 .. controls (603.30,-53.21) and (604.38,-52.85) .. (598.26,-51.41)
 .. controls (592.13,-49.97) and (584.21,-47.09) .. (580.60,-46.37)
 .. controls (577.00,-45.66) and (573.76,-44.94) .. (571.96,-43.50)
 .. controls (570.16,-42.06) and (563.32,-42.06) .. (564.76,-35.22)
 .. controls (566.20,-28.38) and (564.04,-28.02) .. (567.64,-23.71)
 .. controls (571.24,-19.40) and (565.84,-20.12) .. (573.77,-18.33)
 .. controls (581.69,-16.53) and (582.05,-14.38) .. (588.54,-16.54)
 .. controls (595.02,-18.70) and (606.19,-17.98) .. (613.75,-15.10)
 .. controls (621.31,-12.22) and (620.23,-14.02) .. (625.98,-11.50)
 .. controls (631.74,-8.98) and (626.34,-7.18) .. (637.14,-7.54)
 .. controls (647.94,-7.89) and (638.94,-8.25) .. (658.37,-10.04)
 .. controls (677.80,-11.83) and (675.28,-11.83) .. (683.56,-11.11)
 .. controls (691.84,-10.40) and (694.00,-8.96) .. (703.71,-7.53)
 .. controls (713.43,-6.11) and (714.51,-3.95) .. (722.79,-6.85)
 .. controls (731.07,-9.75) and (729.99,-10.11) .. (739.00,-13.72)
 .. controls (748.00,-17.34) and (753.41,-25.97) .. (753.41,-25.97)
 .. controls (753.41,-25.97) and (756.30,-28.13) .. (759.54,-28.12)
 .. controls (762.78,-28.12) and (768.55,-30.27) .. (774.67,-27.74)
 .. controls (780.78,-25.22) and (780.42,-24.86) .. (784.02,-23.77)
 .. controls (787.62,-22.69) and (788.70,-19.81) .. (792.66,-22.69)
 .. controls (796.62,-25.56) and (797.70,-24.48) .. (799.86,-29.52)
 .. controls (802.03,-34.56) and (802.75,-36.00) .. (804.20,-38.88)
 .. controls (805.65,-41.75) and (808.18,-43.91) .. (808.91,-45.71)
 .. controls (809.63,-47.51) and (808.20,-48.94) .. (809.30,-51.46)
 .. controls (810.40,-53.97) and (814.40,-58.64) .. (814.40,-58.64)
 .. controls (814.40,-58.64) and (815.50,-60.43) .. (817.66,-59.71)
 .. controls (819.81,-58.99) and (820.53,-58.99) .. (822.66,-55.77)
 .. controls (824.79,-52.53) and (825.49,-48.94) .. (825.47,-47.15)
 .. controls (825.46,-45.35) and (825.03,-42.89) .. (826.17,-41.76)
 .. controls (827.96,-39.96) and (830.84,-40.68) .. (830.84,-40.68)
 .. controls (830.84,-40.68) and (831.18,-37.80) .. (830.49,-43.56)
 .. controls (829.80,-49.30) and (828.02,-50.38) .. (831.27,-52.54)
 .. controls (834.53,-54.69) and (836.73,-59.00) .. (839.60,-58.28)
 .. controls (842.47,-57.57) and (847.52,-59.00) .. (848.92,-55.42)
 .. controls (850.33,-51.83) and (850.67,-51.83) .. (851.02,-47.88)
 .. controls (851.70,-40.33) and (853.50,-36.37) .. (853.50,-36.37)
 .. controls (853.50,-36.37) and (846.66,-35.29) .. (856.02,-36.37)
 .. controls (865.38,-37.45) and (863.59,-38.13) .. (867.90,-37.81)
 .. controls (882.66,-36.73) and (883.02,-37.09) .. (889.50,-36.00)
));
l_debug(0,1,((705.45,-244.05)
 .. controls (705.45,-244.05) and (706.14,-242.73) .. (704.52,-240.36)
 .. controls (702.90,-237.99) and (704.63,-235.02) .. (699.02,-231.57)
 .. controls (693.42,-228.12) and (692.73,-228.78) .. (686.82,-223.99)
 .. controls (680.91,-219.20) and (679.95,-216.84) .. (675.68,-213.42)
 .. controls (671.41,-209.99) and (671.78,-208.33) .. (665.52,-203.87)
 .. controls (659.27,-199.40) and (655.66,-196.33) .. (652.05,-193.25)
 .. controls (648.43,-190.18) and (646.49,-187.47) .. (640.28,-180.67)
 .. controls (634.07,-173.87) and (634.00,-177.54) .. (630.16,-169.12)
 .. controls (626.32,-160.69) and (625.01,-159.33) .. (623.16,-151.62)
 .. controls (621.31,-143.90) and (625.66,-143.32) .. (621.80,-135.90)
 .. controls (617.95,-128.48) and (620.03,-124.52) .. (611.08,-121.00)
 .. controls (602.14,-117.48) and (595.83,-116.02) .. (587.60,-109.85)
 .. controls (579.38,-103.68) and (585.03,-105.13) .. (575.09,-101.26)
 .. controls (565.15,-97.39) and (564.48,-97.71) .. (557.53,-94.23)
 .. controls (550.59,-90.76) and (544.21,-92.97) .. (542.38,-84.25)
 .. controls (540.55,-75.53) and (541.25,-73.54) .. (540.67,-69.19)
 .. controls (540.09,-64.84) and (540.51,-60.51) .. (538.23,-57.79)
 .. controls (535.95,-55.08) and (536.95,-54.77) .. (531.31,-53.32)
 .. controls (525.66,-51.87) and (518.37,-49.06) .. (515.05,-48.32)
 .. controls (511.72,-47.59) and (508.73,-46.86) .. (507.09,-45.49)
 .. controls (505.45,-44.12) and (499.11,-44.00) .. (500.57,-37.69)
 .. controls (502.03,-31.37) and (500.04,-31.00) .. (503.45,-27.06)
 .. controls (506.87,-23.12) and (501.85,-23.69) .. (509.22,-22.17)
 .. controls (516.60,-20.64) and (516.97,-18.65) .. (522.94,-20.77)
 .. controls (528.91,-22.89) and (539.26,-22.43) .. (546.32,-19.90)
 .. controls (553.39,-17.37) and (552.35,-19.02) .. (557.74,-16.79)
 .. controls (563.12,-14.56) and (558.15,-12.79) .. (568.15,-13.32)
 .. controls (578.16,-13.85) and (569.81,-14.02) .. (587.80,-16.05)
 .. controls (605.78,-18.08) and (603.45,-18.03) .. (611.13,-17.51)
 .. controls (618.82,-17.00) and (620.85,-15.70) .. (629.89,-14.55)
 .. controls (638.92,-13.39) and (639.97,-11.41) .. (647.59,-14.23)
 .. controls (655.21,-17.05) and (654.20,-17.37) .. (662.48,-20.87)
 .. controls (670.75,-24.37) and (675.60,-32.48) .. (675.60,-32.48)
 .. controls (675.60,-32.48) and (678.23,-34.54) .. (681.23,-34.60)
 .. controls (684.24,-34.65) and (689.54,-36.76) .. (695.26,-34.54)
 .. controls (700.97,-32.32) and (700.65,-31.98) .. (704.00,-31.04)
 .. controls (707.36,-30.11) and (708.42,-27.46) .. (712.03,-30.20)
 .. controls (715.65,-32.94) and (716.67,-31.96) .. (718.58,-36.67)
 .. controls (720.49,-41.38) and (721.13,-42.73) .. (722.41,-45.43)
 .. controls (723.69,-48.12) and (725.99,-50.17) .. (726.63,-51.85)
 .. controls (727.26,-53.54) and (725.90,-54.84) .. (726.85,-57.20)
 .. controls (727.81,-59.56) and (731.39,-63.97) .. (731.39,-63.97)
 .. controls (731.39,-63.97) and (732.36,-65.65) .. (734.38,-65.03)
 .. controls (736.39,-64.40) and (737.06,-64.41) .. (739.12,-61.45)
 .. controls (741.18,-58.49) and (741.92,-55.16) .. (741.95,-53.49)
 .. controls (741.98,-51.82) and (741.64,-49.53) .. (742.72,-48.50)
 .. controls (744.42,-46.87) and (747.07,-47.59) .. (747.07,-47.59)
 .. controls (747.07,-47.59) and (747.46,-44.92) .. (746.69,-50.25)
 .. controls (745.91,-55.58) and (744.23,-56.54) .. (747.19,-58.60)
 .. controls (750.15,-60.67) and (752.07,-64.71) .. (754.76,-64.10)
 .. controls (757.44,-63.48) and (762.09,-64.91) .. (763.49,-61.60)
 .. controls (764.89,-58.29) and (765.21,-58.29) .. (765.63,-54.63)
 .. controls (766.43,-47.64) and (768.18,-44.00) .. (768.18,-44.00)
 .. controls (768.18,-44.00) and (761.86,-42.87) .. (770.51,-44.05)
 .. controls (779.17,-45.22) and (777.50,-45.81) .. (781.50,-45.60)
 .. controls (795.20,-44.87) and (795.53,-45.21) .. (801.55,-44.33)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((787.62,32.75)
 .. controls (775.40,38.49) and (768.18,32.00) .. (727.17,41.39)
 .. controls (722.77,42.40) and (686.86,60.52) .. (684.33,59.44)
));
l_debug(0,1,((708.38,21.28)
 .. controls (697.14,26.85) and (690.35,20.97) .. (652.48,30.40)
 .. controls (648.42,31.41) and (615.46,48.83) .. (613.10,47.88)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1204.60,-147.41)
 .. controls (1196.67,-139.61) and (1197.36,-131.11) .. (1191.03,-130.85)
 .. controls (1184.71,-130.58) and (1183.02,-129.42) .. (1177.70,-130.34)
 .. controls (1172.39,-131.26) and (1173.89,-129.49) .. (1162.63,-130.76)
 .. controls (1151.38,-132.03) and (1134.48,-135.36) .. (1126.73,-133.93)
 .. controls (1119.13,-132.52) and (1110.86,-132.22) .. (1103.75,-134.08)
 .. controls (1096.71,-135.93) and (1098.68,-135.48) .. (1093.12,-136.87)
 .. controls (1087.64,-138.25) and (1069.79,-145.52) .. (1069.79,-145.52)
 .. controls (1069.79,-145.52) and (1068.01,-146.71) .. (1066.16,-147.88)
 .. controls (1061.19,-151.03) and (1057.59,-151.93) .. (1051.60,-158.30)
 .. controls (1047.37,-162.79) and (1049.01,-162.46) .. (1050.31,-161.81)
 .. controls (1053.00,-160.48) and (1051.62,-166.10) .. (1054.75,-160.26)
 .. controls (1057.81,-154.54) and (1057.63,-157.75) .. (1058.45,-152.57)
 .. controls (1060.00,-142.77) and (1059.11,-143.41) .. (1058.66,-137.57)
 .. controls (1058.29,-132.76) and (1057.06,-127.70) .. (1058.81,-124.90)
 .. controls (1060.65,-121.97) and (1069.71,-109.54) .. (1083.14,-100.50)
 .. controls (1087.28,-97.72) and (1118.58,-65.67) .. (1120.83,-62.01)
 .. controls (1122.99,-58.49) and (1118.88,-30.50) .. (1118.89,-29.15)
 .. controls (1118.89,-27.80) and (1107.57,-22.03) .. (1078.55,2.73)
 .. controls (1069.45,10.49) and (1025.75,19.09) .. (1020.61,19.93)
 .. controls (951.87,31.20) and (946.15,10.77) .. (936.86,16.88)
 .. controls (927.60,22.97) and (919.39,1.08) .. (884.84,8.99)
 .. controls (867.57,12.94) and (843.01,23.14) .. (838.81,26.27)
 .. controls (813.68,44.98) and (799.86,27.00) .. (787.62,32.75)
));
l_debug(0,1,((1388.93,-153.13)
 .. controls (1381.42,-144.64) and (1381.94,-135.30) .. (1375.94,-134.85)
 .. controls (1369.94,-134.39) and (1368.30,-133.03) .. (1363.28,-133.93)
 .. controls (1358.25,-134.83) and (1359.63,-132.85) .. (1348.92,-133.98)
 .. controls (1338.22,-135.10) and (1322.13,-138.45) .. (1314.49,-136.30)
 .. controls (1306.86,-134.14) and (1298.53,-132.98) .. (1291.49,-134.51)
 .. controls (1284.45,-136.04) and (1286.46,-135.74) .. (1280.77,-136.63)
 .. controls (1275.07,-137.52) and (1255.61,-142.47) .. (1255.61,-142.47)
 .. controls (1255.61,-142.47) and (1253.76,-143.61) .. (1251.57,-144.40)
 .. controls (1245.57,-146.57) and (1243.46,-149.24) .. (1228.47,-147.94)
 .. controls (1213.47,-146.64) and (1223.41,-150.51) .. (1214.52,-144.33)
 .. controls (1205.63,-138.14) and (1201.85,-143.41) .. (1197.34,-135.31)
 .. controls (1192.82,-127.21) and (1191.45,-130.99) .. (1182.85,-125.01)
 .. controls (1169.02,-115.38) and (1170.01,-116.07) .. (1166.49,-108.66)
 .. controls (1162.96,-101.24) and (1157.80,-92.13) .. (1152.29,-83.67)
 .. controls (1146.79,-75.22) and (1114.70,-60.23) .. (1099.63,-45.91)
 .. controls (1095.94,-42.40) and (1053.98,-24.97) .. (1052.04,-21.59)
 .. controls (1050.11,-18.22) and (1011.56,-9.11) .. (1011.60,-7.44)
 .. controls (1011.63,-5.77) and (996.09,-15.14) .. (970.32,-1.28)
 .. controls (962.09,3.16) and (926.83,5.60) .. (922.40,6.35)
 .. controls (859.85,16.94) and (854.80,-1.99) .. (846.24,3.86)
 .. controls (837.68,9.70) and (829.93,-10.51) .. (798.04,-2.53)
 .. controls (782.11,1.46) and (759.49,11.36) .. (755.65,14.34)
 .. controls (732.63,32.15) and (719.62,15.72) .. (708.38,21.28)
));
ATTR__id := "l93-19308-372";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((970.61,-221.41)
 .. controls (970.61,-221.41) and (967.32,-220.29) .. (966.38,-215.70)
 .. controls (965.44,-211.11) and (961.59,-209.36) .. (958.89,-203.75)
 .. controls (956.18,-198.13) and (946.10,-197.12) .. (939.45,-192.27)
 .. controls (933.61,-187.99) and (932.91,-186.36) .. (926.59,-186.70)
 .. controls (921.31,-186.98) and (920.39,-187.67) .. (916.03,-191.99)
 .. controls (911.65,-196.31) and (908.00,-201.33) .. (905.85,-204.23)
 .. controls (903.72,-207.11) and (891.99,-223.10) .. (888.63,-228.26)
 .. controls (885.38,-233.26) and (882.47,-238.23) .. (880.69,-241.66)
 .. controls (878.94,-245.01) and (867.83,-269.34) .. (868.26,-272.17)
 .. controls (868.69,-274.99) and (876.36,-278.15) .. (879.24,-278.62)
 .. controls (882.34,-279.12) and (882.29,-279.70) .. (892.39,-279.86)
 .. controls (904.82,-280.06) and (901.47,-281.26) .. (908.52,-280.51)
 .. controls (929.64,-278.28) and (926.79,-280.29) .. (931.11,-281.87)
 .. controls (935.43,-283.46) and (931.46,-282.97) .. (942.42,-285.49)
 .. controls (953.44,-288.03) and (956.90,-291.52) .. (964.11,-293.78)
 .. controls (971.27,-296.03) and (970.44,-294.31) .. (983.31,-294.56)
 .. controls (995.94,-294.80) and (993.06,-294.16) .. (1001.34,-295.24)
 .. controls (1009.62,-296.31) and (1016.46,-297.03) .. (1021.86,-298.83)
 .. controls (1027.25,-300.63) and (1029.06,-300.62) .. (1035.53,-302.06)
 .. controls (1042.01,-303.50) and (1061.79,-311.80) .. (1068.64,-312.15)
 .. controls (1075.49,-312.50) and (1081.59,-316.83) .. (1088.81,-315.00)
 .. controls (1096.02,-313.19) and (1089.53,-316.08) .. (1099.98,-313.18)
 .. controls (1110.42,-310.29) and (1102.50,-314.98) .. (1120.14,-313.17)
 .. controls (1137.78,-311.35) and (1148.58,-313.50) .. (1152.54,-314.22)
 .. controls (1156.50,-314.94) and (1166.22,-319.25) .. (1170.90,-319.61)
 .. controls (1175.58,-319.96) and (1179.04,-318.15) .. (1181.70,-320.68)
 .. controls (1188.90,-327.51) and (1189.98,-328.95) .. (1191.77,-333.28)
 .. controls (1193.57,-337.60) and (1194.29,-336.16) .. (1195.37,-340.84)
 .. controls (1196.44,-345.53) and (1193.56,-343.73) .. (1198.95,-349.14)
 .. controls (1204.34,-354.55) and (1203.98,-352.38) .. (1215.15,-353.81)
 .. controls (1226.31,-355.25) and (1231.35,-354.88) .. (1240.36,-353.79)
 .. controls (1249.36,-352.71) and (1257.29,-354.51) .. (1261.25,-354.87)
 .. controls (1265.21,-355.23) and (1286.45,-359.18) .. (1292.21,-359.54)
 .. controls (1297.97,-359.90) and (1328.19,-363.51) .. (1334.31,-362.43)
 .. controls (1340.42,-361.36) and (1347.59,-366.02) .. (1369.10,-364.35)
 .. controls (1390.51,-362.69) and (1402.58,-366.84) .. (1411.09,-365.90)
 .. controls (1419.58,-364.96) and (1423.82,-362.54) .. (1426.30,-360.44)
 .. controls (1428.78,-358.33) and (1435.81,-360.65) .. (1430.19,-355.85)
 .. controls (1424.57,-351.05) and (1420.68,-351.33) .. (1413.61,-349.76)
 .. controls (1406.53,-348.19) and (1402.98,-346.34) .. (1394.45,-343.36)
 .. controls (1385.91,-340.37) and (1381.27,-338.53) .. (1376.27,-335.26)
 .. controls (1371.26,-331.98) and (1379.84,-331.68) .. (1367.67,-328.01)
 .. controls (1355.49,-324.33) and (1346.88,-322.87) .. (1340.05,-319.26)
 .. controls (1333.22,-315.65) and (1332.14,-314.93) .. (1328.89,-309.54)
 .. controls (1325.64,-304.15) and (1323.45,-291.98) .. (1316.59,-286.61)
 .. controls (1309.73,-281.25) and (1308.31,-283.38) .. (1300.71,-275.54)
 .. controls (1293.12,-267.70) and (1299.58,-268.44) .. (1287.69,-263.08)
 .. controls (1275.80,-257.72) and (1270.76,-255.92) .. (1267.52,-253.43)
 .. controls (1264.27,-250.94) and (1258.49,-245.27) .. (1253.80,-242.07)
 .. controls (1249.12,-238.88) and (1245.88,-238.50) .. (1244.44,-237.09)
 .. controls (1242.99,-235.68) and (1241.91,-234.27) .. (1240.46,-232.51)
 .. controls (1232.59,-222.96) and (1235.05,-224.79) .. (1229.23,-212.99)
 .. controls (1223.46,-201.29) and (1222.00,-204.03) .. (1217.72,-184.02)
 .. controls (1213.54,-164.46) and (1212.62,-155.38) .. (1204.60,-147.41)
));
l_debug(0,1,((1121.26,-234.61)
 .. controls (1121.26,-234.61) and (1118.56,-235.90) .. (1114.93,-233.49)
 .. controls (1111.31,-231.08) and (1107.95,-232.01) .. (1102.65,-229.91)
 .. controls (1097.35,-227.80) and (1090.60,-231.67) .. (1082.91,-232.18)
 .. controls (1075.22,-232.70) and (1073.56,-232.67) .. (1067.48,-235.88)
 .. controls (1061.41,-239.10) and (1060.73,-239.76) .. (1059.32,-243.40)
 .. controls (1057.91,-247.04) and (1058.18,-250.39) .. (1058.14,-252.39)
 .. controls (1058.10,-254.39) and (1055.53,-266.36) .. (1054.45,-270.34)
 .. controls (1053.37,-274.33) and (1052.29,-278.31) .. (1051.90,-280.97)
 .. controls (1051.51,-283.64) and (1047.08,-304.91) .. (1050.40,-305.98)
 .. controls (1053.72,-307.05) and (1068.81,-303.68) .. (1073.17,-302.43)
 .. controls (1077.54,-301.18) and (1077.59,-301.48) .. (1089.96,-297.42)
 .. controls (1103.40,-293.01) and (1100.23,-295.14) .. (1107.42,-292.43)
 .. controls (1127.60,-284.81) and (1125.55,-287.11) .. (1130.23,-287.20)
 .. controls (1134.90,-287.30) and (1130.88,-287.88) .. (1142.25,-287.11)
 .. controls (1153.61,-286.33) and (1157.91,-288.42) .. (1164.22,-290.21)
 .. controls (1170.52,-292.01) and (1169.54,-290.99) .. (1181.22,-291.55)
 .. controls (1192.89,-292.12) and (1190.23,-291.40) .. (1197.89,-292.55)
 .. controls (1205.54,-293.71) and (1211.87,-294.50) .. (1216.84,-296.27)
 .. controls (1221.81,-298.03) and (1223.48,-298.07) .. (1229.46,-299.52)
 .. controls (1235.44,-300.98) and (1253.64,-309.02) .. (1259.98,-309.47)
 .. controls (1266.31,-309.93) and (1271.90,-314.05) .. (1278.61,-312.52)
 .. controls (1285.32,-310.98) and (1279.26,-313.53) .. (1288.99,-311.05)
 .. controls (1298.72,-308.57) and (1291.29,-312.77) .. (1307.68,-311.42)
 .. controls (1324.06,-310.08) and (1334.03,-312.28) .. (1337.69,-313.02)
 .. controls (1341.35,-313.76) and (1350.28,-317.94) .. (1354.61,-318.36)
 .. controls (1358.94,-318.78) and (1362.18,-317.17) .. (1364.60,-319.56)
 .. controls (1371.15,-326.04) and (1372.12,-327.39) .. (1373.71,-331.43)
 .. controls (1375.30,-335.47) and (1375.99,-334.14) .. (1376.91,-338.50)
 .. controls (1377.82,-342.86) and (1375.19,-341.14) .. (1380.09,-346.24)
 .. controls (1385.00,-351.35) and (1384.71,-349.34) .. (1395.02,-350.88)
 .. controls (1405.34,-352.42) and (1410.02,-352.18) .. (1418.38,-351.34)
 .. controls (1426.74,-350.51) and (1434.05,-352.32) .. (1437.72,-352.73)
 .. controls (1441.38,-353.14) and (1461.00,-357.20) .. (1466.33,-357.64)
 .. controls (1471.66,-358.08) and (1499.63,-361.97) .. (1505.32,-361.08)
 .. controls (1511.01,-360.19) and (1517.60,-364.66) .. (1537.65,-363.39)
 .. controls (1557.71,-362.12) and (1568.98,-366.02) .. (1577.01,-365.18)
 .. controls (1585.04,-364.33) and (1589.09,-362.08) .. (1591.47,-360.12)
 .. controls (1593.84,-358.17) and (1600.47,-360.30) .. (1595.22,-355.86)
 .. controls (1589.97,-351.41) and (1586.29,-351.67) .. (1579.64,-350.21)
 .. controls (1573.00,-348.74) and (1569.69,-347.00) .. (1561.74,-344.17)
 .. controls (1553.78,-341.35) and (1549.48,-339.59) .. (1544.86,-336.50)
 .. controls (1540.25,-333.40) and (1548.27,-333.22) .. (1536.99,-329.66)
 .. controls (1525.71,-326.10) and (1517.73,-324.61) .. (1511.45,-321.14)
 .. controls (1505.18,-317.68) and (1504.19,-316.99) .. (1501.29,-311.93)
 .. controls (1498.38,-306.86) and (1496.61,-295.48) .. (1490.36,-290.35)
 .. controls (1484.12,-285.22) and (1482.75,-287.19) .. (1475.89,-279.71)
 .. controls (1469.03,-272.23) and (1475.02,-273.02) .. (1464.11,-267.79)
 .. controls (1453.19,-262.57) and (1448.55,-260.81) .. (1445.60,-258.41)
 .. controls (1442.64,-256.02) and (1437.41,-250.57) .. (1433.13,-247.48)
 .. controls (1428.85,-244.39) and (1425.85,-244.00) .. (1424.55,-242.64)
 .. controls (1423.24,-241.28) and (1422.26,-239.92) .. (1420.96,-238.23)
 .. controls (1413.87,-228.99) and (1416.10,-230.79) .. (1410.99,-219.33)
 .. controls (1405.87,-207.88) and (1404.49,-210.53) .. (1400.87,-190.76)
 .. controls (1397.26,-170.99) and (1396.44,-161.63) .. (1388.93,-153.13)
));
ATTR__id := "l83-16348-760";
ATTR__height := -1;
drawoptions();
l_wall_invisible(((926.35,-286.41)
 -- (876.22,-243.29)
));
l_debug(0,1,((1126.79,-292.14)
 -- (1034.72,-288.98)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((684.33,59.44)
 .. controls (684.33,59.44) and (672.42,52.97) .. (663.06,52.25)
 .. controls (653.69,51.52) and (632.82,55.82) .. (623.46,57.97)
 .. controls (614.10,60.13) and (611.93,57.24) .. (594.66,65.88)
 .. controls (577.39,74.51) and (570.20,79.55) .. (560.88,87.48)
 .. controls (551.56,95.40) and (560.89,88.93) .. (536.51,104.05)
 .. controls (512.08,119.20) and (520.02,122.07) .. (501.25,122.80)
 .. controls (482.46,123.52) and (481.00,127.12) .. (460.79,127.12)
 .. controls (440.60,127.13) and (431.97,124.97) .. (419.02,119.21)
 .. controls (406.06,113.45) and (393.84,102.29) .. (393.84,102.29)
));
l_debug(0,1,((613.10,47.88)
 .. controls (613.10,47.88) and (601.97,42.09) .. (593.28,41.59)
 .. controls (584.59,41.10) and (565.32,45.49) .. (556.68,47.66)
 .. controls (548.04,49.84) and (545.99,47.21) .. (530.13,55.53)
 .. controls (514.27,63.86) and (507.69,68.66) .. (499.16,76.18)
 .. controls (490.63,83.69) and (499.19,77.51) .. (476.77,91.98)
 .. controls (454.36,106.44) and (461.75,108.97) .. (444.41,109.98)
 .. controls (427.08,110.99) and (425.81,114.36) .. (407.12,114.73)
 .. controls (388.43,115.10) and (380.38,113.25) .. (368.27,108.15)
 .. controls (356.15,103.05) and (344.60,92.93) .. (344.60,92.93)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((393.84,102.29)
 .. controls (393.84,102.29) and (395.64,93.29) .. (378.36,90.40)
 .. controls (361.07,87.51) and (332.62,88.54) .. (323.25,86.73)
 .. controls (313.89,84.92) and (323.25,85.29) .. (298.40,86.35)
 .. controls (273.56,87.41) and (250.86,92.83) .. (243.66,93.92)
 .. controls (236.46,95.00) and (236.10,95.37) .. (230.70,96.09)
 .. controls (225.30,96.82) and (217.38,90.70) .. (206.22,94.31)
 .. controls (195.06,97.92) and (178.01,97.52) .. (166.38,104.57)
 .. controls (154.75,111.62) and (157.63,115.58) .. (142.50,120.26)
 .. controls (127.38,124.94) and (106.51,138.61) .. (99.67,141.48)
 .. controls (92.84,144.36) and (85.64,145.80) .. (73.41,146.52)
 .. controls (61.17,147.24) and (58.66,149.76) .. (46.06,147.60)
 .. controls (33.47,145.44) and (27.00,147.96) .. (16.92,144.00)
 .. controls (6.84,140.04) and (6.48,141.48) .. (2.88,138.60)
 .. controls (-0.72,135.72) and (-20.17,126.00) .. (-34.21,121.68)
 .. controls (-48.26,117.36) and (-55.46,115.92) .. (-66.98,114.48)
 .. controls (-78.51,113.04) and (-67.35,113.04) .. (-95.43,109.80)
 .. controls (-123.52,106.55) and (-114.16,105.11) .. (-131.44,105.11)
 .. controls (-148.72,105.11) and (-141.52,106.55) .. (-159.53,105.11)
 .. controls (-177.53,103.67) and (-167.09,103.31) .. (-185.81,102.58)
 .. controls (-204.53,101.86) and (-209.93,101.86) .. (-209.93,101.86)
 .. controls (-209.93,101.86) and (-222.17,101.86) .. (-236.57,102.94)
 .. controls (-250.97,104.02) and (-251.69,108.70) .. (-268.25,108.34)
 .. controls (-284.81,107.98) and (-288.41,106.18) .. (-302.81,109.07)
 .. controls (-317.21,111.95) and (-334.49,121.67) .. (-344.21,122.03)
 .. controls (-353.93,122.39) and (-352.85,125.64) .. (-366.17,124.91)
 .. controls (-379.50,124.19) and (-383.10,122.03) .. (-396.78,124.55)
 .. controls (-410.46,127.06) and (-412.62,127.42) .. (-420.90,130.30)
 .. controls (-429.18,133.18) and (-428.10,123.10) .. (-433.50,135.34)
 .. controls (-438.89,147.58) and (-438.87,176.38) .. (-449.29,194.74)
 .. controls (-459.71,213.10) and (-457.55,214.55) .. (-461.84,228.59)
 .. controls (-466.14,242.64) and (-467.18,255.96) .. (-474.37,262.80)
 .. controls (-481.56,269.65) and (-483.34,275.77) .. (-495.22,280.09)
 .. controls (-507.10,284.41) and (-505.65,287.65) .. (-517.55,285.49)
 .. controls (-529.44,283.33) and (-541.32,288.37) .. (-561.48,291.98)
 .. controls (-581.65,295.58) and (-579.84,297.74) .. (-594.97,298.82)
 .. controls (-610.09,299.91) and (-608.65,302.07) .. (-621.62,302.07)
 .. controls (-634.58,302.07) and (-637.47,299.55) .. (-651.51,302.08)
 .. controls (-665.56,304.60) and (-665.55,307.49) .. (-678.88,307.13)
 .. controls (-692.21,306.77) and (-706.63,302.45) .. (-716.34,313.62)
 .. controls (-726.04,324.79) and (-716.31,326.23) .. (-735.40,330.55)
 .. controls (-754.49,334.88) and (-764.93,339.92) .. (-773.21,339.57)
 .. controls (-781.50,339.21) and (-778.25,342.09) .. (-792.66,341.37)
 .. controls (-807.08,340.65) and (-829.78,337.77) .. (-834.10,339.93)
 .. controls (-838.42,342.10) and (-839.50,342.82) .. (-853.19,344.62)
 .. controls (-866.88,346.42) and (-873.00,347.14) .. (-873.00,347.14)
 .. controls (-873.00,347.14) and (-875.52,347.86) .. (-885.26,345.70)
 .. controls (-894.99,343.53) and (-892.82,344.61) .. (-906.52,341.37)
 .. controls (-920.21,338.13) and (-923.46,334.88) .. (-938.23,332.72)
 .. controls (-953.00,330.56) and (-954.80,329.48) .. (-961.65,328.03)
 .. controls (-968.49,326.59) and (-981.10,321.55) .. (-986.51,320.83)
 .. controls (-991.91,320.10) and (-992.63,317.58) .. (-996.23,320.46)
 .. controls (-999.84,323.34) and (-1001.28,321.54) .. (-1002.72,327.66)
 .. controls (-1004.16,333.78) and (-1004.88,336.30) .. (-1003.45,344.22)
 .. controls (-1002.01,352.15) and (-1000.21,361.87) .. (-998.76,363.67)
));
l_debug(0,1,((344.60,92.93)
 .. controls (344.60,92.93) and (346.10,84.56) .. (330.03,82.21)
 .. controls (313.96,79.85) and (287.61,81.38) .. (278.91,79.88)
 .. controls (270.20,78.39) and (278.88,78.55) .. (255.87,80.01)
 .. controls (232.87,81.46) and (211.95,86.89) .. (205.29,88.02)
 .. controls (198.64,89.15) and (198.31,89.49) .. (193.32,90.26)
 .. controls (188.33,91.03) and (180.87,85.50) .. (170.59,89.04)
 .. controls (160.31,92.59) and (144.49,92.52) .. (133.84,99.26)
 .. controls (123.19,106.01) and (125.93,109.63) .. (112.01,114.24)
 .. controls (98.08,118.86) and (78.97,131.92) .. (72.69,134.72)
 .. controls (66.40,137.51) and (59.75,138.98) .. (48.42,139.87)
 .. controls (37.09,140.77) and (34.80,143.15) .. (23.08,141.38)
 .. controls (11.36,139.61) and (5.40,142.06) .. (-4.02,138.58)
 .. controls (-13.43,135.09) and (-13.74,136.43) .. (-17.13,133.83)
 .. controls (-20.52,131.23) and (-38.72,122.58) .. (-51.81,118.83)
 .. controls (-64.91,115.08) and (-71.61,113.88) .. (-82.31,112.76)
 .. controls (-93.02,111.64) and (-82.67,111.43) .. (-108.76,108.94)
 .. controls (-134.85,106.46) and (-126.20,104.95) .. (-142.22,105.27)
 .. controls (-158.23,105.59) and (-151.53,106.79) .. (-168.24,105.78)
 .. controls (-184.96,104.78) and (-175.29,104.26) .. (-192.65,103.93)
 .. controls (-210.02,103.61) and (-215.02,103.71) .. (-215.02,103.71)
 .. controls (-215.02,103.71) and (-226.37,103.93) .. (-239.70,105.20)
 .. controls (-253.02,106.47) and (-253.60,110.82) .. (-268.96,110.79)
 .. controls (-284.32,110.76) and (-287.69,109.16) .. (-300.98,112.09)
 .. controls (-314.28,115.03) and (-330.12,124.35) .. (-339.12,124.87)
 .. controls (-348.12,125.38) and (-347.06,128.36) .. (-359.42,127.94)
 .. controls (-371.78,127.52) and (-375.16,125.58) .. (-387.79,128.17)
 .. controls (-400.43,130.76) and (-402.42,131.13) .. (-410.05,133.95)
 .. controls (-417.67,136.77) and (-416.85,127.41) .. (-421.63,138.86)
 .. controls (-426.41,150.30) and (-425.88,177.00) .. (-435.22,194.21)
 .. controls (-444.56,211.42) and (-442.53,212.71) .. (-446.28,225.81)
 .. controls (-450.02,238.90) and (-450.78,251.27) .. (-457.33,257.74)
 .. controls (-463.88,264.21) and (-465.43,269.92) .. (-476.36,274.14)
 .. controls (-487.30,278.37) and (-485.90,281.34) .. (-496.95,279.56)
 .. controls (-508.01,277.77) and (-518.93,282.67) .. (-537.55,286.37)
 .. controls (-556.17,290.08) and (-554.46,292.05) .. (-568.45,293.33)
 .. controls (-582.45,294.61) and (-581.08,296.58) .. (-593.09,296.82)
 .. controls (-605.10,297.06) and (-607.82,294.78) .. (-620.79,297.37)
 .. controls (-633.75,299.97) and (-633.70,302.64) .. (-646.05,302.55)
 .. controls (-658.41,302.46) and (-671.83,298.72) .. (-680.64,309.24)
 .. controls (-689.44,319.77) and (-680.41,320.92) .. (-698.01,325.28)
 .. controls (-715.62,329.63) and (-725.20,334.50) .. (-732.89,334.32)
 .. controls (-740.57,334.14) and (-737.51,336.74) .. (-750.87,336.34)
 .. controls (-764.23,335.94) and (-785.31,333.69) .. (-789.27,335.77)
 .. controls (-793.24,337.85) and (-794.23,338.54) .. (-806.87,340.46)
 .. controls (-819.52,342.38) and (-825.18,343.16) .. (-825.18,343.16)
 .. controls (-825.18,343.16) and (-827.50,343.87) .. (-836.55,342.05)
 .. controls (-845.60,340.23) and (-843.58,341.19) .. (-856.32,338.44)
 .. controls (-869.06,335.68) and (-872.12,332.74) .. (-885.85,331.01)
 .. controls (-899.57,329.28) and (-901.25,328.31) .. (-907.62,327.10)
 .. controls (-913.99,325.89) and (-925.76,321.45) .. (-930.78,320.89)
 .. controls (-935.80,320.32) and (-936.51,318.00) .. (-939.80,320.73)
 .. controls (-943.08,323.47) and (-944.45,321.82) .. (-945.67,327.52)
 .. controls (-946.89,333.22) and (-947.51,335.57) .. (-946.03,342.89)
 .. controls (-944.55,350.20) and (-942.70,359.18) .. (-941.34,360.82)
));
ATTR__id := "l75-14278-2188";
ATTR__height := -1;
drawoptions();
l_wall_invisible(((857.10,-38.53)
 -- (784.76,-37.81)
));
l_debug(0,1,((771.47,-46.07)
 -- (704.41,-44.07)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-805.74,148.00)
 .. controls (-812.94,147.28) and (-789.89,176.09) .. (-781.97,185.45)
 .. controls (-774.05,194.81) and (-768.29,199.85) .. (-751.72,211.36)
 .. controls (-735.15,222.88) and (-735.15,221.44) .. (-711.38,230.79)
 .. controls (-687.61,240.14) and (-665.28,240.13) .. (-645.12,235.08)
 .. controls (-624.96,230.03) and (-612.73,222.11) .. (-600.50,214.18)
 .. controls (-588.26,206.26) and (-594.74,209.14) .. (-590.43,200.50)
 .. controls (-586.11,191.85) and (-583.24,176.01) .. (-580.37,165.21)
 .. controls (-577.49,154.41) and (-589.74,136.41) .. (-598.38,131.37)
 .. controls (-607.02,126.33) and (-607.02,129.21) .. (-622.14,127.78)
 .. controls (-637.26,126.34) and (-642.29,131.38) .. (-671.81,133.55)
 .. controls (-701.33,135.72) and (-690.53,134.28) .. (-699.89,135.00)
 .. controls (-709.25,135.73) and (-746.69,147.27) .. (-765.42,147.28)
 .. controls (-784.14,147.29) and (-798.54,148.73) .. cycle
));
l_debug(0,1,((-766.44,157.39)
 .. controls (-773.13,156.85) and (-751.24,183.12) .. (-743.73,191.65)
 .. controls (-736.22,200.18) and (-730.78,204.75) .. (-715.22,215.12)
 .. controls (-699.66,225.50) and (-699.69,224.16) .. (-677.49,232.40)
 .. controls (-655.29,240.64) and (-634.61,240.23) .. (-616.01,235.19)
 .. controls (-597.42,230.14) and (-586.22,222.58) .. (-575.02,215.01)
 .. controls (-563.82,207.44) and (-569.77,210.23) .. (-565.92,202.14)
 .. controls (-562.08,194.06) and (-559.70,179.32) .. (-557.23,169.26)
 .. controls (-554.76,159.19) and (-566.44,142.73) .. (-574.54,138.22)
 .. controls (-582.64,133.71) and (-582.59,136.38) .. (-596.63,135.32)
 .. controls (-610.67,134.26) and (-615.25,139.03) .. (-642.57,141.57)
 .. controls (-669.90,144.12) and (-659.91,142.59) .. (-668.57,143.42)
 .. controls (-677.24,144.26) and (-711.73,155.63) .. (-729.08,155.98)
 .. controls (-746.43,156.32) and (-759.76,157.92) .. cycle
));
p_debug(-1,1,(1051.60,-158.30));
p_debug(-1,1,(1054.75,-160.26));
l_debug(-1,1,((1051.60,-158.30) -- (1054.75,-160.26)));
p_debug(-2,1,(1228.47,-147.94));
p_debug(-2,1,(1197.34,-135.31));
l_debug(-2,1,((1051.60,-158.30) -- (1228.47,-147.94) -- (1197.34,-135.31) -- (1054.75,-160.26)));
endfig;
beginfig(7);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char115 \char117 \char109 \char112 \ \char50 \mainfont{} etex,(855.73,-296.30),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char115 \char117 \char109 \char112 \ \char51 \mainfont{} etex,(1429.16,-328.98),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char112 \char105 \char116 \char99 \char104 \ \char45 \char49 \char51 \char109 \mainfont{} etex,(1061.67,-130.26),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char115 \char117 \char109 \char112 \ \char49 \mainfont{} etex,(705.67,-317.45),0.0,0);
endfig;
beginfig(8);
s_northarrow(0);
endfig;
beginfig(9);
s_scalebar(50, 1, "\thfb\char109 \mainfont{}");
endfig;
background:=(0.80000,0.80000,0.80000);
transparency:=false;
beginfig(10);
s_vgrid(-1, -1, 708.66142, 708.66142);
endfig;
beginfig(11);
s_vgrid(0, -1, 708.66142, 708.66142);
endfig;
beginfig(12);
s_vgrid(1, -1, 708.66142, 708.66142);
endfig;
beginfig(13);
s_vgrid(-1, 0, 708.66142, 708.66142);
endfig;
beginfig(14);
s_vgrid(0, 0, 708.66142, 708.66142);
endfig;
beginfig(15);
s_vgrid(1, 0, 708.66142, 708.66142);
endfig;
beginfig(16);
s_vgrid(-1, 1, 708.66142, 708.66142);
endfig;
beginfig(17);
s_vgrid(0, 1, 708.66142, 708.66142);
endfig;
beginfig(18);
s_vgrid(1, 1, 708.66142, 708.66142);
endfig;
end;
